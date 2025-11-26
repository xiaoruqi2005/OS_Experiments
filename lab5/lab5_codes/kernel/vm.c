/* kernel/vm.c - 虚拟内存管理 */

#include "mm.h"
#include "defs.h"
#include "riscv.h"

// 全局内核页表指针
pagetable_t kernel_pagetable;

// 创建页表
pagetable_t create_pagetable(void) {
    pagetable_t pagetable = (pagetable_t)alloc_page();
    if(pagetable == 0)
        return 0;
    return pagetable;
}

// 递归释放页表
static void freewalk(pagetable_t pagetable) {
    for(int i = 0; i < 512; i++) {
        pte_t pte = pagetable[i];
        if(pte & PTE_V) {
            if((pte & (PTE_R|PTE_W|PTE_X)) == 0) {
                uint64 child = PTE_PA(pte);
                freewalk((pagetable_t)child);
                pagetable[i] = 0;
            }
        }
    }
    free_page((void*)pagetable);
}

// 销毁页表
void destroy_pagetable(pagetable_t pagetable) {
    if(pagetable == 0)
        return;
    freewalk(pagetable);
}

// 页表遍历 - 查找模式
pte_t* walk_lookup(pagetable_t pagetable, uint64 va) {
    if(va >= (1L << 39))
        panic("walk_lookup: va too large");
    
    for(int level = 2; level > 0; level--) {
        pte_t *pte = &pagetable[PX(level, va)];
        if(*pte & PTE_V) {
            pagetable = (pagetable_t)PTE_PA(*pte);
        } else {
            return 0;
        }
    }
    return &pagetable[PX(0, va)];
}

// 页表遍历 - 创建模式
pte_t* walk_create(pagetable_t pagetable, uint64 va) {
    if(va >= (1L << 39))
        panic("walk_create: va too large");
    
    for(int level = 2; level > 0; level--) {
        pte_t *pte = &pagetable[PX(level, va)];
        if(*pte & PTE_V) {
            pagetable = (pagetable_t)PTE_PA(*pte);
        } else {
            pagetable = (pagetable_t)alloc_page();
            if(pagetable == 0)
                return 0;
            *pte = PA2PTE(pagetable) | PTE_V;
        }
    }
    return &pagetable[PX(0, va)];
}

// 映射单个页面
int map_page(pagetable_t pagetable, uint64 va, uint64 pa, int perm) {
    if(va % PGSIZE != 0)
        panic("map_page: va not page aligned");
    if(pa % PGSIZE != 0)
        panic("map_page: pa not page aligned");
    
    pte_t *pte = walk_create(pagetable, va);
    if(pte == 0)
        return -1;
    
    if(*pte & PTE_V)
        panic("map_page: page already mapped");
    
    *pte = PA2PTE(pa) | perm | PTE_V;
    return 0;
}

// 映射内存区域
int map_region(pagetable_t pagetable, uint64 va, uint64 pa, uint64 size, int perm) {
    uint64 a, last;
    
    if(size == 0)
        return 0;
    
    a = PGROUNDDOWN(va);
    last = PGROUNDDOWN(va + size - 1);
    
    for(;;) {
        if(map_page(pagetable, a, pa, perm) != 0)
            return -1;
        if(a == last)
            break;
        a += PGSIZE;
        pa += PGSIZE;
    }
    return 0;
}

// 初始化内核页表
void kvminit(void) {
    kernel_pagetable = create_pagetable();
    if(kernel_pagetable == 0)
        panic("kvminit: create_pagetable failed");
    
    printf("Setting up kernel page table...\n");
    
    // 映射内核代码段
    printf("Mapping kernel text: %p - %p\n", (void*)KERNBASE, etext);
    if(map_region(kernel_pagetable, KERNBASE, KERNBASE, 
                  (uint64)etext - KERNBASE, PTE_R | PTE_X) != 0)
        panic("kvminit: map kernel text failed");
    
    // 映射内核数据段
    printf("Mapping kernel data: %p - %p\n", etext, (void*)PHYSTOP);
    if(map_region(kernel_pagetable, (uint64)etext, (uint64)etext,
                  PHYSTOP - (uint64)etext, PTE_R | PTE_W) != 0)
        panic("kvminit: map kernel data failed");
    
    // 映射UART设备
    printf("Mapping UART: %p\n", (void*)UART0);
    if(map_region(kernel_pagetable, UART0, UART0, PGSIZE, PTE_R | PTE_W) != 0)
        panic("kvminit: map UART failed");
    
    printf("Kernel page table setup complete\n");
}

// 激活内核页表
void kvminithart(void) {
    w_satp(MAKE_SATP(kernel_pagetable));
    sfence_vma();
    printf("Virtual memory enabled!\n");
}

// 调试用：打印页表
void dump_pagetable(pagetable_t pagetable, int level) {
    if(level > 2) return;
    
    printf("Page table at level %d:\n", level);
    int count = 0;
    for(int i = 0; i < 512; i++) {
        pte_t pte = pagetable[i];
        if(pte & PTE_V) {
            printf("  [%d]: %p", i, (void*)pte);
            if(pte & PTE_R) printf(" R");
            if(pte & PTE_W) printf(" W");
            if(pte & PTE_X) printf(" X");
            printf(" -> PA %p\n", (void*)PTE_PA(pte));
            count++;
            if(count > 10) {
                printf("  ... (more entries)\n");
                break;
            }
        }
    }
}

// 权限检查
int check_page_permission(uint64 addr, int access_type) {
    pte_t *pte = walk_lookup(kernel_pagetable, addr);
    
    if(pte == 0 || !(*pte & PTE_V)) {
        printf("Permission check: Address %p not mapped\n", (void*)addr);
        return 0;
    }
    
    if((access_type & ACCESS_READ) && !(*pte & PTE_R)) {
        printf("Permission check: No read permission for %p\n", (void*)addr);
        return 0;
    }
    
    if((access_type & ACCESS_WRITE) && !(*pte & PTE_W)) {
        printf("Permission check: No write permission for %p\n", (void*)addr);
        return 0;
    }
    
    if((access_type & ACCESS_EXEC) && !(*pte & PTE_X)) {
        printf("Permission check: No execute permission for %p\n", (void*)addr);
        return 0;
    }
    
    return 1;
}