// kernel/vm.c
#include "riscv.h"
#include "defs.h"
#include "virtio.h"

// 内核的根页表
pagetable_t kernel_pagetable;

// 外部符号，由链接脚本定义
extern char etext[]; // .text 段的结束地址
extern char end[];   // 内核的结束地址
extern void kref_inc(void*);
extern void kfree(void*); // 确保有 kfree 声明

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
            for (int i = 0; i < PGSIZE / sizeof(pte_t); i++) {
                pagetable[i] = 0;
            }
            *pte = PA2PTE(pagetable) | PTE_V;
        }
    }
    return &pagetable[VPN(va, 0)];
}

// ===== 新增: 用于测试的公开函数 =====

pagetable_t create_pagetable(void) {
    pagetable_t pt = (pagetable_t)kalloc();
    if (pt == 0) {
        return 0;
    }
    for (int i = 0; i < PGSIZE / sizeof(pte_t); i++) {
        pt[i] = 0;
    }
    return pt;
}

int map_page(pagetable_t pt, uint64 va, uint64 pa, int perm) {
    pte_t *pte = walk(pt, va, 1);
    if (pte == 0) {
        return -1;
    }
    if (*pte & PTE_V) {
        printf("map_page: remap is not supported\n");
        return -1;
    }
    *pte = PA2PTE(pa) | perm | PTE_V;
    return 0;
}

pte_t *walk_lookup(pagetable_t pt, uint64 va) {
    return walk(pt, va, 0);
}

// ===== 原有函数 =====

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

// 创建内核页表
void kvminit(void) {
    kernel_pagetable = (pagetable_t)kalloc();
    for (int i = 0; i < PGSIZE / sizeof(pte_t); i++) {
        kernel_pagetable[i] = 0;
    }

    // 映射 UART 设备
    if (mappages(kernel_pagetable, 0x10000000, PGSIZE, 0x10000000, PTE_R | PTE_W) < 0)
        panic("kvminit: uart map failed");

    // 映射 VirtIO 磁盘 MMIO (0x10001000)
    // === 修复: 添加错误检查 ===
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

// 激活内核页表
void kvminithart(void) {
    w_satp(MAKE_SATP(kernel_pagetable));
    sfence_vma();
    printf("kvminithart: virtual memory enabled.\n");
}

// int uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
// {
//   pte_t *pte;
//   uint64 pa, i;
//   uint flags;
//   char *mem;

//   for(i = 0; i < sz; i += PGSIZE){
//     if((pte = walk(old, i, 0)) == 0)
//       continue;   // page table entry hasn't been allocated
//     if((*pte & PTE_V) == 0)
//       continue;   // physical page hasn't been allocated
//     pa = PTE2PA(*pte);
//     flags = PTE_FLAGS(*pte);
//     if((mem = kalloc()) == 0)
//       goto err;
//     memmove(mem, (char*)pa, PGSIZE);
//     if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
//       kfree(mem);
//       goto err;
//     }
//   }
//   return 0;

//  err:
//   uvmunmap(new, 0, i / PGSIZE, 1);
//   return -1;
// }

int uvmcopy(pagetable_t old, pagetable_t new, uint64 sz) {
    pte_t *pte;
    uint64 pa, i;
    uint flags;

    for (i = 0; i < sz; i += PGSIZE) {
        if ((pte = walk_lookup(old, i)) == 0) 
            panic("uvmcopy: pte should exist");
        if ((*pte & PTE_V) == 0) 
            continue;// 如果页表项无效，说明该地址未分配，直接跳过而不是 Panic
            // panic("uvmcopy: page not present");

        pa = PTE2PA(*pte);
        flags = PTE_FLAGS(*pte); // 获取旧页面的标志位

        // [核心逻辑] 如果页面可写，则清除写权限并标记为 COW [cite: 95-99]
        if (flags & PTE_W) {
            flags &= ~PTE_W;
            flags |= PTE_C;
            // 更新父进程的 PTE
            *pte = PA2PTE(pa) | flags | PTE_V;
        }

        // [核心逻辑] 增加物理页引用计数 [cite: 105]
        kref_inc((void*)pa);

        // 将同一物理页映射到子进程，权限与父进程一致（只读+COW） [cite: 109]
        if (mappages(new, i, PGSIZE, pa, flags) != 0) {
            // 错误处理：实际应回滚，这里简化为 goto err
            return -1;
        }
    }
    // 修改了父进程页表权限，必须刷新 TLB
    sfence_vma(); 
    return 0;
}

// [新增] 移除映射并选择性释放物理内存
void uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free) {
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    if((pte = walk_lookup(pagetable, a)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    
    // 检查是否是叶子节点 (PTE_V 有效，且 R/W/X 至少有一个有效)
    // 简化处理：只要存在就认为是叶子
    
    uint64 pa = PTE2PA(*pte);

    if(do_free){
      // kfree 会处理引用计数，如果计数减为0则真正释放
      kfree((void*)pa);
    }
    *pte = 0; // 清除 PTE
  }
}

int cow_alloc(pagetable_t pagetable, uint64 va) {
    uint64 va_rounded = PGROUNDDOWN(va);
    pte_t *pte;

    if (va >= MAXVA) return -1; // 需定义 MAXVA，通常为 1L << 38

    pte = walk_lookup(pagetable, va_rounded);
    if (pte == 0 || (*pte & PTE_V) == 0 || !(*pte & PTE_C)) {
        return -1; // 非法访问或非 COW 页
    }

    uint64 pa = PTE2PA(*pte);
    uint64 flags = PTE_FLAGS(*pte);

    // 分配新页
    char *mem = kalloc();
    if (mem == 0) return -1;

    // 复制数据 [cite: 138]
    memmove(mem, (char*)pa, PGSIZE);

    // 修改 PTE：指向新页，恢复写权限，清除 COW 标志 [cite: 139]
    flags = (flags | PTE_W) & ~PTE_C;
    *pte = PA2PTE(mem) | flags | PTE_V;

    // 旧页引用计数减 1 [cite: 140]
    kfree((void*)pa);

    return 0;
}