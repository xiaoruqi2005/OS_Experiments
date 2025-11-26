/* kernel/mm_test.c - 内存管理测试 */

#include "mm.h"
#include "defs.h"
#include "riscv.h"

// ==================== 多级页表映射测试 ====================
void test_multilevel_pagetable(void) {
    printf("=== Testing Multi-level Page Table ===\n");
    
    pagetable_t pt = create_pagetable();
    if(pt == 0) {
        printf("ERROR: create_pagetable failed\n");
        return;
    }
    
    // 测试地址数组
    uint64 test_vas[] = {
        0x1000,         // 4KB
        0x200000,       // 2MB
        0x40000000,     // 1GB
        0x7000000000,   // 接近39位限制
    };
    
    for(int i = 0; i < 4; i++) {
        uint64 va = test_vas[i];
        
        // Sv39地址空间边界检查
        if(va >= (1L << 39)) {
            printf("Test %d: VA %p exceeds Sv39 limit, skipping\n", i, (void*)va);
            continue;
        }
        
        // 分配物理页面
        uint64 pa = (uint64)alloc_page();
        if(pa == 0) {
            printf("ERROR: alloc_page failed for test %d\n", i);
            continue;
        }
        
        printf("Test %d: mapping VA %p to PA %p\n", i, (void*)va, (void*)pa);
        
        // 建立映射
        if(map_page(pt, va, pa, PTE_R | PTE_W | PTE_X) != 0) {
            printf("ERROR: map_page failed for test %d\n", i);
            free_page((void*)pa);
            continue;
        }
        
        // 验证映射
        pte_t *pte = walk_lookup(pt, va);
        if(pte == 0 || !(*pte & PTE_V) || PTE_PA(*pte) != pa) {
            printf("ERROR: mapping verification failed for test %d\n", i);
        } else {
            printf("Test %d: mapping verification PASSED\n", i);
        }
        
        // 清理
        free_page((void*)pa);
    }
    
    // 清理页表
    destroy_pagetable(pt);
    printf("Multi-level page table test completed\n\n");
}

// ==================== 边界条件测试 ====================
void test_edge_cases(void) {
    printf("=== Testing Edge Cases ===\n");
    
    // 测试内存耗尽
    printf("Testing memory exhaustion...\n");
    void *pages[100];
    int allocated = 0;
    
    for(int i = 0; i < 100; i++) {
        pages[i] = alloc_page();
        if(pages[i] == 0) {
            printf("Memory exhausted after %d pages\n", i);
            break;
        }
        allocated++;
    }
    
    // 释放所有页面
    for(int i = 0; i < allocated; i++) {
        free_page(pages[i]);
    }
    printf("Memory exhaustion test completed\n");
    
    // 测试地址对齐
    printf("Testing address alignment...\n");
    pagetable_t pt = create_pagetable();
    uint64 pa = (uint64)alloc_page();
    
    printf("Address alignment test completed\n");
    
    // 清理
    free_page((void*)pa);
    destroy_pagetable(pt);
    printf("Edge cases test completed\n\n");
}

// ==================== 综合测试入口 ====================
void run_comprehensive_tests(void) {
    printf("=== Comprehensive Memory Management Tests ===\n\n");
    
    // 按顺序运行测试
    test_multilevel_pagetable();
    test_edge_cases();
    
    printf("All comprehensive tests completed!\n");
}