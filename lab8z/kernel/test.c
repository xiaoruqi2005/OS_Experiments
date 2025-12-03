// kernel/test.c
#include "riscv.h"
#include "defs.h"
#include "syscall.h"
#include "proc.h"
#include "fs.h"
#include "file.h"
#include "fcntl.h"
#include "stat.h"

#define NULL ((void*)0)

void assert(int condition) {
    if (!condition) {
        printf("ASSERTION FAILED!\n");
        while(1);
    }
}

// 模拟 User 内存操作的测试
void test_cow_fork(void) {
    printf("\n=== Project 5: COW Fork Test ===\n");

    // 1. 手动分配一个物理页，写入数据
    char *pa = kalloc();
    memset(pa, 0, PGSIZE);
    safestrcpy(pa, "PARENT DATA", 16);
    int initial_ref = kref_get(pa);
    printf("Allocated PA %p, Ref Count: %d\n", pa, initial_ref);

    // 2. 创建父页表
    pagetable_t parent_pt = create_pagetable();
    uint64 va = 0x1000;
    // 映射为可写
    map_page(parent_pt, va, (uint64)pa, PTE_R | PTE_W | PTE_U);
    
    printf("Mapped VA %p to PA %p in Parent PT\n", va, pa);

    // 3. 模拟 Fork (uvmcopy)
    printf("Forking (uvmcopy)...\n");
    pagetable_t child_pt = create_pagetable();
    uvmcopy(parent_pt, child_pt, va + PGSIZE); 

    // 4. 验证 COW 状态
    pte_t *pte_p = walk_lookup(parent_pt, va);
    pte_t *pte_c = walk_lookup(child_pt, va);

    int ref_after_fork = kref_get(pa);
    printf("Ref Count after fork: %d (Expected 2)\n", ref_after_fork);
    
    if (ref_after_fork != 2) panic("COW Test Fail: Ref count incorrect");
    if (*pte_p & PTE_W) panic("COW Test Fail: Parent still writable");
    if (*pte_c & PTE_W) panic("COW Test Fail: Child still writable");
    if (!(*pte_p & PTE_COW)) panic("COW Test Fail: Parent COW bit not set");
    if (!(*pte_c & PTE_COW)) panic("COW Test Fail: Child COW bit not set");

    printf("COW flags set correctly. Write permission removed.\n");

    // 5. 模拟写操作触发 Page Fault (Child Write)
    printf("Simulating Child Write to VA %p (Triggering Page Fault)...\n", va);
    
    // 手动调用 cow_alloc 模拟 trap handler 的行为
    if (cow_alloc(child_pt, va) < 0) panic("COW Allocation Failed");

    // 6. 验证写后状态
    pte_c = walk_lookup(child_pt, va);
    uint64 pa_child_new = PTE2PA(*pte_c);
    
    printf("Child New PA: %p\n", (void*)pa_child_new);
    
    if (pa_child_new == (uint64)pa) panic("COW Test Fail: Child still points to old PA");
    if (!(*pte_c & PTE_W)) panic("COW Test Fail: Child page not writable after fault");
    if (*pte_c & PTE_COW) panic("COW Test Fail: Child COW bit still set");

    int ref_after_write = kref_get(pa);
    printf("Old PA Ref Count: %d (Expected 1)\n", ref_after_write);
    if (ref_after_write != 1) panic("COW Test Fail: Old PA ref count did not decrease");

    // 验证数据独立性
    char *child_mem = (char*)pa_child_new;
    child_mem[0] = 'C'; // Modify child data
    
    if (pa[0] == 'C') panic("COW Test Fail: Parent data modified!");
    
    printf("Data independence verified. Parent: '%s', Child: '%s'\n", pa, child_mem);

    // 清理
    kfree(pa); // Free Parent (旧页，引用计数降为 0)
    kfree((void*)pa_child_new); // Free Child (新页，引用计数降为 0)
    
    printf("=== COW Fork Test Passed ===\n");
}

void run_cow_tests(void) {
    test_cow_fork();
}

// 存根
void run_lab6_tests(void) {}
void run_lab7_tests(void) {}
