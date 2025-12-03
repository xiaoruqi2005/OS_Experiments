// lab3/kernel/kalloc.c

#include "riscv.h"
#include "defs.h"

//需要记录每个物理页被多少个进程共享，只有计数归零时才真正释放内存
#define PHYSTOP 0x88000000 // 根据 kinit 中的硬编码值
struct {
    struct spinlock lock;
    int count[PHYSTOP / PGSIZE];
} ref;

// --- 新增：增加引用计数函数 ---
void kref_inc(void *pa) {
    acquire(&ref.lock);
    int idx = (uint64)pa / PGSIZE;
    if (idx >= PHYSTOP / PGSIZE) panic("kref_inc bounds");
    ref.count[idx]++;
    release(&ref.lock);
}

// 外部定义的内核结束地址
extern char end[];

// 空闲物理页链表的头节点
struct run {
    struct run *next;
};
static struct run *freelist;

// // 初始化物理内存分配器
// void kinit() {
//     // 从内核末尾开始，直到物理内存顶部，将所有内存逐页释放
//     // end 符号由链接脚本提供，表示内核镜像的结束位置
//     // PHYSTOP 是 QEMU virt 机器的物理内存上限 (128MB)
//     freerange(end, (void*)0x88000000); 
//     printf("kinit: physical memory allocator initialized.\n");
// }

// --- 修改：kinit ---
void kinit() {
    spinlock_init(&ref.lock, "kalloc_ref"); // 初始化引用计数锁 [cite: 79]
    freerange(end, (void*)PHYSTOP);
    printf("kinit: physical memory allocator initialized.\n");
}

// 将一段物理内存 [pa_start, pa_end) 添加到空闲链表
void freerange(void *pa_start, void *pa_end) {
    char *p = (char*)PGROUNDUP((uint64)pa_start);
    for (; p + PGSIZE <= (char*)pa_end; p += PGSIZE) {
        // [新增] 在释放前，人为将引用计数设为 1
        // 这样 kfree 检查时会发现 count=1，将其减为0并放入空闲链表
        // 注意：此时是单核启动阶段，直接操作 ref 结构体是安全的，无需加锁
        ref.count[(uint64)p / PGSIZE] = 1;
        kfree(p);
    }
}


// --- 修改：kfree ---
void kfree(void *pa) {
    struct run *r;
    if (((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP) {
        printf("kfree: invalid physical address %p\n", pa);
        return;
    }

    // [新增] 递减引用计数 [cite: 85]
    acquire(&ref.lock);
    int idx = (uint64)pa / PGSIZE;
    if (ref.count[idx] <= 0) 
        panic("kfree ref");
    
    ref.count[idx]--;
    if (ref.count[idx] > 0) {
        release(&ref.lock);
        return; // 还有其他进程引用，暂不释放
    }
    release(&ref.lock);

    // 真正释放
    for (int i = 0; i < PGSIZE; i++) {
        *((char*)pa + i) = 1;
    }
    r = (struct run*)pa;
    r->next = freelist;
    freelist = r;
}



// --- 修改：kalloc ---
void *kalloc(void) {
    struct run *r = freelist;
    if (r) {
        freelist = r->next;
        
        // [新增] 初始化引用计数为 1 [cite: 80]
        acquire(&ref.lock);
        int idx = (uint64)r / PGSIZE;
        ref.count[idx] = 1;
        release(&ref.lock);

        // 将页内存清零
        for (int i = 0; i < PGSIZE; i++) {
            *((char*)r + i) = 0;
        }
    }
    return (void*)r;
}

// 获取当前空闲内存总大小 (字节)
uint64 get_free_mem(void) {
    struct run *r = freelist;
    uint64 count = 0;
    
    acquire(&ref.lock);
    while (r) {
        count++;
        r = r->next;
    }
    release(&ref.lock);
    
    return count * PGSIZE;
}

// 获取某个物理地址的引用计数
int get_ref_count(uint64 pa) {
    int count = -1;
    acquire(&ref.lock);
    int idx = pa / PGSIZE;
    if (idx < PHYSTOP / PGSIZE) {
        count = ref.count[idx];
    }
    release(&ref.lock);
    return count;
}