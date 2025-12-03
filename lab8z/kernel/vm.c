// kernel/vm.c
#include "riscv.h"
#include "defs.h"
#include "virtio.h"

pagetable_t kernel_pagetable;

// 外部符号，由链接脚本定义
extern char etext[]; 

// 遍历页表，找到指定虚拟地址对应的PTE。
static pte_t *walk(pagetable_t pagetable, uint64 va, int alloc) {
    if (va >= (1L << 39)) {
        return 0; // 虚拟地址过大
    }
    
    for (int level = 2; level > 0; level--) {
        pte_t *pte = &pagetable[VPN(va, level)];
        if (*pte & PTE_V) {
            pagetable = (pagetable_t)PTE2PA(*pte);
        } else {
            if (!alloc || (pagetable = (pagetable_t)kalloc()) == 0) {
                return 0; // 分配失败
            }
            memset(pagetable, 0, PGSIZE);
            *pte = PA2PTE(pagetable) | PTE_V;
        }
    }
    return &pagetable[VPN(va, 0)];
}

// 创建内核页表
int mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm) {
    uint64 a, last;
    pte_t *pte;

    a = PGROUNDDOWN(va);
    last = PGROUNDDOWN(va + size - 1);

    for (;;) {
        if ((pte = walk(pagetable, a, 1)) == 0) {
            return -1;
        }
        if (*pte & PTE_V) {
            printf("mappages: remap is not supported\n");
            return -1;
        }
        *pte = PA2PTE(pa) | perm | PTE_V;
        if (a == last) {
            break;
        }
        a += PGSIZE;
        pa += PGSIZE;
    }
    return 0;
}

// 创建一个空的页表
pagetable_t create_pagetable(void) {
    pagetable_t pt = (pagetable_t)kalloc();
    if (pt == 0) return 0;
    memset(pt, 0, PGSIZE);
    return pt;
}

// 查找 PTE
pte_t *walk_lookup(pagetable_t pt, uint64 va) {
    return walk(pt, va, 0);
}

// 映射单个页
int map_page(pagetable_t pt, uint64 va, uint64 pa, int perm) {
    return mappages(pt, va, PGSIZE, pa, perm);
}


// COW 缺页处理函数
int cow_alloc(pagetable_t pagetable, uint64 va) {
    uint64 pa;
    pte_t *pte;
    uint flags;

    if (va >= (1L << 39)) return -1;

    va = PGROUNDDOWN(va);
    pte = walk_lookup(pagetable, va);
    if (pte == 0) return -1;
    if ((*pte & PTE_V) == 0) return -1;
    
    // 检查是否是 COW 页 (必须是只读，且设置了 COW 标志)
    if ((*pte & PTE_COW) == 0 || (*pte & PTE_W)) {
        return -1; 
    }

    pa = PTE2PA(*pte);

    // 分配新物理页
    char *mem = kalloc();
    if (mem == 0) {
        printf("cow_alloc: kalloc failed\n");
        return -1;
    }

    // 复制旧页内容到新页
    memmove(mem, (char*)pa, PGSIZE);

    // 修改 PTE：指向新页，设置 Write，清除 COW
    flags = PTE_FLAGS(*pte);
    flags |= PTE_W;
    flags &= ~PTE_COW;
    
    *pte = PA2PTE(mem) | flags;

    // 减少旧物理页的引用计数
    kfree((void*)pa);

    return 0;
}

// COW 版复制内存，只复制页表项，并设置 COW 标志
int uvmcopy(pagetable_t old, pagetable_t new, uint64 sz) {
    pte_t *pte;
    uint64 pa, i;
    uint flags;

    for (i = 0; i < sz; i += PGSIZE) {
        if ((pte = walk_lookup(old, i)) == 0)
            continue; // 跳过未映射的页
        if ((*pte & PTE_V) == 0)
            continue; 
        
        // 跳过不可读的页 (如 guard page)
        if (!(*pte & PTE_R))
            continue;

        pa = PTE2PA(*pte);
        flags = PTE_FLAGS(*pte);

        // 如果页是可写的，则取消写权限，并设置 COW 标志
        if (flags & PTE_W) {
            flags &= ~PTE_W;
            flags |= PTE_COW;
            // 更新父进程的页表 (将其设为只读+COW)
            *pte = PA2PTE(pa) | flags; 
        }

        // 将相同的物理页映射到子进程
        if (map_page(new, i, pa, flags) != 0) {
            panic("uvmcopy: map_page failed");
        }

        // 增加物理页的引用计数
        kref_inc((void*)pa);
    }
    // 刷新 TLB，因为我们在父进程中移除了 PTE_W
    sfence_vma();
    return 0;
}

// 释放用户内存映射
void uvmunmap(pagetable_t pt, uint64 va, uint64 npages, int do_free) {
    uint64 a;
    pte_t *pte;

    for (a = va; a < va + npages * PGSIZE; a += PGSIZE) {
        if ((pte = walk_lookup(pt, a)) == 0) continue; 
        if ((*pte & PTE_V) == 0) continue;
        
        uint64 pa = PTE2PA(*pte);
        if (do_free) {
            kfree((void*)pa); // kfree 会自动处理引用计数
        }
        *pte = 0;
    }
    sfence_vma();
}

void kvminit(void) {
    extern char etext[]; 
    
    kernel_pagetable = (pagetable_t)kalloc();
    memset(kernel_pagetable, 0, PGSIZE);

    // 映射 UART 设备
    if (mappages(kernel_pagetable, 0x10000000, PGSIZE, 0x10000000, PTE_R | PTE_W) < 0)
        panic("kvminit: uart map failed");

    // 映射 VirtIO 磁盘 MMIO
    if (mappages(kernel_pagetable, VIRTIO0, PGSIZE, VIRTIO0, PTE_R | PTE_W) < 0)
        panic("kvminit: virtio map failed");

    // 映射内核代码段 (R-X)
    if (mappages(kernel_pagetable, 0x80200000, (uint64)etext - 0x80200000, 0x80200000, PTE_R | PTE_X) < 0)
        panic("kvminit: text map failed");

    // 映射内核数据段和剩余物理内存 (RW-)
    if (mappages(kernel_pagetable, (uint64)etext, 0x88000000 - (uint64)etext, (uint64)etext, PTE_R | PTE_W) < 0)
        panic("kvminit: data map failed");
    
    printf("kvminit: kernel page table created.\n");
}

void kvminithart(void) {
    w_satp(MAKE_SATP(kernel_pagetable));
    sfence_vma();
    printf("kvminithart: virtual memory enabled.\n");
}
