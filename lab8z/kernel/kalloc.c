// lab3/kernel/kalloc.c

#include "riscv.h"
#include "defs.h"

extern char end[];

struct run {
    struct run *next;
};

struct {
    struct spinlock lock;
    struct run *freelist;
    // Project 5: Reference Counter
    // 假设最大物理内存 128MB (0x88000000)
    uint8 ref[(0x88000000 - 0x80000000) / PGSIZE]; 
} kmem;

// 获取物理地址对应的引用计数数组索引
static inline int pa2idx(uint64 pa) {
    if (pa < 0x80000000 || pa >= 0x88000000)
        panic("pa2idx: invalid pa");
    return (pa - 0x80000000) / PGSIZE;
}

void kinit() {
    spinlock_init(&kmem.lock, "kmem");
    
    // 初始化引用计数为 0
    memset(kmem.ref, 0, sizeof(kmem.ref));
    
    // 释放内存
    char *p;
    p = (char*)PGROUNDUP((uint64)end);
    for(; p + PGSIZE <= (char*)0x88000000; p += PGSIZE) {
        // 在 kinit 阶段，手动将 ref 设为 1，kfree 减为 0 并放入 freelist
        kmem.ref[pa2idx((uint64)p)] = 1; 
        kfree(p);
    }
    printf("kinit: physical memory allocator initialized (with COW support).\n");
}

void kfree(void *pa) {
    struct run *r;

    if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= 0x88000000)
        panic("kfree: invalid pa");

    acquire(&kmem.lock);
    int idx = pa2idx((uint64)pa);
    
    if (kmem.ref[idx] <= 0) {
        release(&kmem.lock);
        panic("kfree: ref <= 0");
    }

    kmem.ref[idx]--;

    // 只有引用计数归零时才真正释放回链表
    if (kmem.ref[idx] > 0) {
        release(&kmem.lock);
        return;
    }
    release(&kmem.lock);

    // 真正释放：填充垃圾数据
    memset(pa, 1, PGSIZE);

    r = (struct run*)pa;

    acquire(&kmem.lock);
    r->next = kmem.freelist;
    kmem.freelist = r;
    release(&kmem.lock);
}

void *kalloc(void) {
    struct run *r;

    acquire(&kmem.lock);
    r = kmem.freelist;
    if(r) {
        kmem.freelist = r->next;
        // 分配时，引用计数置 1
        int idx = pa2idx((uint64)r);
        if (kmem.ref[idx] != 0) {
            panic("kalloc: ref not 0");
        }
        kmem.ref[idx] = 1;
    }
    release(&kmem.lock);

    if(r)
        memset((char*)r, 5, PGSIZE); // fill with junk
    return (void*)r;
}

// 增加引用计数 (用于 fork COW)
void kref_inc(void *pa) {
    if ((uint64)pa < 0x80000000 || (uint64)pa >= 0x88000000) return;
    acquire(&kmem.lock);
    int idx = pa2idx((uint64)pa);
    if (kmem.ref[idx] < 1) panic("kref_inc: ref < 1");
    kmem.ref[idx]++;
    release(&kmem.lock);
}

// 获取当前引用计数
int kref_get(void *pa) {
    if ((uint64)pa < 0x80000000 || (uint64)pa >= 0x88000000) return -1;
    acquire(&kmem.lock);
    int c = kmem.ref[pa2idx((uint64)pa)];
    release(&kmem.lock);
    return c;
}

void kref_dec(void *pa) {
    kfree(pa);
}
