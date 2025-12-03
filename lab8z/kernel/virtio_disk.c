#include "defs.h"
#include "param.h"
#include "buf.h"
#include "fs.h"
#include "virtio.h"

#define NUM 8 // 环的大小

struct virtio_blk_req {
    uint32 type;
    uint32 reserved;
    uint64 sector;
};

struct disk {
    // 物理页，用于存放 desc, avail, used 环
    // 为了 Legacy 模式，我们需要这三个结构在物理内存中符合特定的对齐和布局
    // 简单起见，我们分配两个连续的页（或者一页足够大）
    // xv6 标准做法是让 kalloc 分配 4096 字节，足够存放 NUM=8 的所有结构
    char *pages; 
    
    struct virtq_desc *desc;
    struct virtq_avail *avail;
    struct virtq_used *used;
    
    char free[NUM];     // 跟踪空闲描述符
    uint16 used_idx;    // 我们上次检查到的已用索引

    struct {
        struct buf *b;
        char status;
        struct virtio_blk_req cmd;
    } info[NUM];
    
    struct spinlock lock;
} disk;

static uint64 disk_reads = 0;
static uint64 disk_writes = 0;

static inline volatile uint32 *mmio_reg(int off) {
    return (volatile uint32 *)((uint64)VIRTIO0 + off);
}

static inline uint32 r32(int off) {
    return *mmio_reg(off);
}

static inline void w32(int off, uint32 val) {
    *mmio_reg(off) = val;
}

static int alloc_desc(void) {
    for (int i = 0; i < NUM; i++) {
        if (disk.free[i]) {
            disk.free[i] = 0;
            return i;
        }
    }
    return -1;
}

static void free_desc(int i) {
    if (i >= NUM) panic("free_desc");
    disk.desc[i].addr = 0;
    disk.desc[i].len = 0;
    disk.desc[i].flags = 0;
    disk.desc[i].next = 0;
    disk.free[i] = 1;
}

static void free_chain(int i) {
    while (1) {
        int flag = disk.desc[i].flags;
        int next = disk.desc[i].next;
        free_desc(i);
        if (!(flag & 1)) break;
        i = next;
    }
}

void virtio_disk_init(void) {
    uint32 status = 0;

    spinlock_init(&disk.lock, "virtio_disk");

    uint32 magic = r32(VIRTIO_MMIO_MAGIC_VALUE);
    uint32 version = r32(VIRTIO_MMIO_VERSION);
    uint32 device_id = r32(VIRTIO_MMIO_DEVICE_ID);
    uint32 vendor_id = r32(VIRTIO_MMIO_VENDOR_ID);

    printf("virtio: magic=0x%x version=0x%x device=0x%x vendor=0x%x\n", magic, version, device_id, vendor_id);

    if (magic != 0x74726976 || device_id != 2) {
        panic("virtio_disk_init: cannot find virtio disk");
    }

    // 1. Reset device
    w32(VIRTIO_MMIO_STATUS, 0);

    // 2. Set ACKNOWLEDGE status bit
    status |= 1; 
    w32(VIRTIO_MMIO_STATUS, status);

    // 3. Set DRIVER status bit
    status |= 2;
    w32(VIRTIO_MMIO_STATUS, status);

    // 4. Negotiate features
    uint32 features = r32(VIRTIO_MMIO_DEVICE_FEATURES);
    features &= ~(1 << 28); // No indirect descriptors
    features &= ~(1 << 24); // No event idx
    w32(VIRTIO_MMIO_DRIVER_FEATURES, features);

    // 5. Set FEATURES_OK (Only for Version 2, but harmless in v1 usually, skip for safety if v1)
    // Legacy doesn't strictly require this step check, but we set status.
    if (version >= 2) {
        status |= 4;
        w32(VIRTIO_MMIO_STATUS, status);
        if (!(r32(VIRTIO_MMIO_STATUS) & 4))
            panic("virtio_disk_init: features");
    }

    // 6. Set DRIVER_OK status bit
    status |= 8;
    w32(VIRTIO_MMIO_STATUS, status);

    // 7. Config queue 0
    w32(VIRTIO_MMIO_QUEUE_SEL, 0);
    uint32 max = r32(VIRTIO_MMIO_QUEUE_NUM_MAX);
    if (max == 0) panic("virtio_disk_init: no queue 0");
    if (max < NUM) panic("virtio_disk_init: queue too short");
    
    w32(VIRTIO_MMIO_QUEUE_NUM, NUM);

    // === Legacy Mode Setup ===
    // Legacy requires writing the Physical Page Number (PFN) of the memory region
    // containing Desc, Avail, and Used rings. 
    // QEMU calculates offsets based on Page Size (4096).
    
    w32(VIRTIO_MMIO_GUEST_PAGE_SIZE, 4096); // Set page size to 4096

    disk.pages = kalloc(); // Allocate 4096 bytes
    if (!disk.pages) panic("virtio_disk_init: kalloc");
    memset(disk.pages, 0, PGSIZE);

    // Layout inside the page:
    // Desc:  0  .. 128 (16 * 8)
    // Avail: 128 .. 134 + 2*8 + padding
    // Used:  4096 is standard alignment for Used ring in legacy?
    // Actually, legacy allows Q_ALIGN to be set. Default is often 4096.
    // Let's set Q_ALIGN to 4096 to put Used ring on the next page? 
    // No, standard xv6 uses one page and relies on the device being smart or alignment being smaller.
    
    // Let's follow standard xv6 approach:
    // Write PFN = addr >> 12.
    // The device expects:
    //   Desc  at addr
    //   Avail at addr + NUM*16
    //   Used  at (addr + NUM*16 + 6 + 2*NUM) rounded up to ALIGN (default 4096)
    
    // To fit in one page, we need to set ALIGN to something small.
    w32(VIRTIO_MMIO_QUEUE_ALIGN, 4096); 
    // With Align=4096, Used ring will be at offset 4096.
    // So we actually need TWO pages if we use default alignment.
    // Let's kalloc another page to be safe and ensure they are contiguous? 
    // kalloc doesn't guarantee contiguity.
    
    // Hack: Change alignment to 4 bytes so everything fits in one page?
    // QEMU legacy might support this. Let's try ALIGN=4096 but allocate 2 pages if needed.
    // Actually, kalloc allocates 4096.
    // If we set PFN, QEMU expects physical address.
    
    // Let's try xv6-riscv standard way:
    // It assumes VIRTIO_MMIO_QUEUE_PFN points to the page.
    
    w32(VIRTIO_MMIO_QUEUE_PFN, (uint64)disk.pages >> 12);

    // Setup pointers manually for our software use
    disk.desc = (struct virtq_desc *)(disk.pages);
    disk.avail = (struct virtq_avail *)(disk.pages + NUM * sizeof(struct virtq_desc));
    // Used ring is at offset 4096 because of ALIGN=4096.
    // This implies we actally need a second page at disk.pages + 4096.
    // BUT kalloc gives one page. This is dangerous.
    
    // **Fix:** Explicitly set ALIGN to something smaller, like 16 or 4096?
    // If we can't change ALIGN on QEMU side easily, we must provide memory where it expects.
    // Wait, the register is writeable.
    
    // Let's try setting ALIGN to 0x1000 (4096) and assume we need valid memory at offset 4096.
    // Since kalloc returns 4096, accessing disk.pages[4096] is ILLEGAL (Use After Free / Out of bounds).
    
    // **Safe Approach**: Set ALIGN to 4096, but allocate 2 pages.
    // But kalloc only gives 1. 
    // Let's try to set VIRTIO_MMIO_QUEUE_ALIGN to 64 bytes? 
    // Most drivers allow this.
    
    w32(VIRTIO_MMIO_QUEUE_ALIGN, 128); // Reduced alignment
    
    // Recalculate pointers based on Align=128
    // Desc: 0. Size 128.
    // Avail: 128. Size 6+16=22. End=150.
    // Used: RoundUp(150, 128) = 256.
    // So Used ring starts at offset 256.
    // Total size = 256 + 6 + 8*8 = 326 bytes. Fits in 4096.
    
    disk.used = (struct virtq_used *) (disk.pages + 256);

    for (int i = 0; i < NUM; i++) {
        disk.free[i] = 1;
    }
    disk.used_idx = 0;
}

void virtio_disk_rw(struct buf *b, int write) {
    int idx[3];
    acquire(&disk.lock);

    for (int i = 0; i < 3; i++) {
        while ((idx[i] = alloc_desc()) < 0) { }
    }

    // 1. CMD
    struct virtio_blk_req *cmd = &disk.info[idx[0]].cmd;
    memset(cmd, 0, sizeof(*cmd));
    cmd->type = write ? 1 : 0;
    cmd->reserved = 0;
    cmd->sector = (uint64)b->blockno * (BSIZE / 512);

    disk.desc[idx[0]].addr = (uint64)cmd;
    disk.desc[idx[0]].len = sizeof(*cmd);
    disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    disk.desc[idx[0]].next = idx[1];

    // 2. DATA
    disk.desc[idx[1]].addr = (uint64)b->data;
    disk.desc[idx[1]].len = BSIZE;
    if (write) disk.desc[idx[1]].flags = 0; 
    else disk.desc[idx[1]].flags = VRING_DESC_F_WRITE;
    disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    disk.desc[idx[1]].next = idx[2];

    // 3. STATUS
    disk.info[idx[0]].status = 0xff;
    disk.desc[idx[2]].addr = (uint64)&disk.info[idx[0]].status;
    disk.desc[idx[2]].len = 1;
    disk.desc[idx[2]].flags = VRING_DESC_F_WRITE;
    disk.desc[idx[2]].next = 0;

    b->disk = 1;
    disk.info[idx[0]].b = b;

    disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    __sync_synchronize();
    disk.avail->idx++;
    __sync_synchronize();
    w32(VIRTIO_MMIO_QUEUE_NOTIFY, 0);

    if (write) disk_writes++;
    else disk_reads++;

    // 轮询 Used Ring 更新
    while (*(volatile char*)&disk.info[idx[0]].status == 0xff) {
        release(&disk.lock);
        virtio_disk_intr(); 
        acquire(&disk.lock);
    }

    disk.info[idx[0]].b = 0;
    b->disk = 0;
    free_chain(idx[0]);

    release(&disk.lock);
}

void virtio_disk_intr(void) {
    acquire(&disk.lock);
    __sync_synchronize();

    uint16 used_idx_dev = *(volatile uint16*)&disk.used->idx;

    while (disk.used_idx != used_idx_dev) {
        __sync_synchronize();
        int id = disk.used->ring[disk.used_idx % NUM].id;
        disk.used_idx++;
        __sync_synchronize();

        if (id >= NUM) continue;
        struct buf *b = disk.info[id].b;
        if (b == 0) continue;

        b->disk = 0;
        wakeup(b);
        
        used_idx_dev = *(volatile uint16*)&disk.used->idx;
    }
    release(&disk.lock);
}

uint64 get_disk_read_count(void) { return disk_reads; }
uint64 get_disk_write_count(void) { return disk_writes; }
