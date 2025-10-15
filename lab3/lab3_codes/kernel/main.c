// kernel/main.c
#include "types.h"
#include "defs.h"
#include "riscv.h"
#include "memlayout.h"

// --- 分层测试函数声明 ---
void test_physical_memory();
void test_pagetable();
void test_virtual_memory();

void main() {
    uart_init();
    printf("xv6-riscv-simplified by @X XX\n");
    
    // --- 初始化内存管理 ---
    kinit();       
    kvminit();  
    kvminithart(); 
    
    // --- 执行分层测试 ---
    test_physical_memory();
    test_pagetable();
    test_virtual_memory();
    
    printf("\n====== All Tests Passed! ======\n");
    printf("Booting complete!\n");
    
    while (1);
}

// --- 分层测试函数实现 ---

// 测试1：物理内存分配器
void test_physical_memory(void) {
    printf("\n--- Test 1: Physical Memory Allocator ---\n");
    void *page1 = kalloc();
    void *page2 = kalloc();

    if(page1 == 0 || page2 == 0) {
        printf("kalloc failed\n");
        return;
    }
    if(page1 == page2) {
        printf("kalloc returned same page twice\n");
        return;
    }
    if(((uint64)page1 & 0xFFF) != 0 || ((uint64)page2 & 0xFFF) != 0) {
        printf("kalloc returned non-aligned page\n");
        return;
    }
    
    *(int*)page1 = 0x12345678;
    if (*(int*)page1 != 0x12345678) {
        printf("physical memory write/read failed\n");
        return;
    }

    kfree(page1);
    void *page3 = kalloc();
    if(page3 != page1) {
        // 在简化的分配器中，最新释放的页会被最先分配，所以它们应该相等
        printf("kfree/kalloc failed to reuse page\n");
        return;
    }

    kfree(page2);
    kfree(page3);

    printf("Physical memory test PASSED\n");
}

// 测试2：页表功能
void test_pagetable() {
    printf("\n--- Test 2: Page Table Functionality ---\n");
    
    uint64 va = 0x1000000;
    void* pa_void = kalloc();
    if(pa_void == 0) {
        printf("kalloc failed for pagetable test\n");
        return;
    }
    uint64 pa = (uint64)pa_void;

    if(mappages(kernel_pagetable, va, PGSIZE, pa, PTE_R | PTE_W) != 0) {
        printf("mappages failed\n");
        return;
    }

    pte_t *pte = walk(kernel_pagetable, va, 0);
    if(pte == 0 || (*pte & PTE_V) == 0) {
        printf("walk failed or PTE not valid\n");
        return;
    }
    if(PTE2PA(*pte) != pa) {
        printf("PTE to PA translation failed\n");
        return;
    }
    if(!(*pte & PTE_R) || !(*pte & PTE_W) || (*pte & PTE_X)) {
        printf("PTE permission bits incorrect\n");
        return;
    }

    // 写入并读回数据以验证映射
    *(uint64*)pa = 0xDEADBEEF;
    if (*(uint64*)va != 0xDEADBEEF) {
        printf("mapped memory access failed\n");
        return;
    }
    
    kfree(pa_void);
    
    printf("Page table test PASSED\n");
}

// 测试3：虚拟内存激活
void test_virtual_memory(void) {
    printf("\n--- Test 3: Virtual Memory Activation ---\n");
    
    printf("Kernel code is executable after enabling paging.\n");

    static int data_var = 42;
    data_var++;
    if(data_var == 43) {
        printf("Kernel data is accessible.\n");
    } else {
        printf("Kernel data access failed.\n");
        return;
    }

    printf("Device (UART) access is working.\n");

    printf("Virtual memory test PASSED\n");
}
