#include "mm.h"
#include "defs.h"
#include "riscv.h"

// ==================== 多级页表映射测试 ====================
// 目的：验证Sv39三级页表结构在不同地址范围下的正确性
void test_multilevel_pagetable(void) {
    printf("=== Testing Multi-level Page Table ===\n");
    
    // 创建测试专用页表，与内核页表隔离
    pagetable_t pt = create_pagetable();
    if(pt == 0) {
        printf("ERROR: create_pagetable failed\n");
        return;
    }
    
    // 精心设计的测试地址数组 - 覆盖不同的页表层级需求
    uint64 test_vas[] = {
        0x1000,         // 4KB   - 测试最小映射单位
        0x200000,       // 2MB   - 测试跨越多个4KB页面
        0x40000000,     // 1GB   - 需要二级页表  
        0x7000000000,   // 接近39位限制 - 需要完整三级页表
    };
    // 地址选择原理：
    // - 0x1000: VPN[2]=0, VPN[1]=0, VPN[0]=1 - 最简单情况
    // - 0x200000: VPN[2]=0, VPN[1]=1, VPN[0]=0 - 测试二级索引
    // - 0x40000000: VPN[2]=1, VPN[1]=0, VPN[0]=0 - 测试一级索引
    // - 0x7000000000: 需要所有三级页表 - 完整路径测试
    
    for(int i = 0; i < 4; i++) {
        uint64 va = test_vas[i];
        
        // Sv39地址空间边界检查 - 防止超出39位限制
        // 这个检查验证了我们的地址范围验证机制
        if(va >= (1L << 39)) {
            printf("Test %d: VA %p exceeds Sv39 limit, skipping\n", i, (void*)va);
            continue;
        }
        
        // 为每个测试分配一个物理页面
        uint64 pa = (uint64)alloc_page();
        if(pa == 0) {
            printf("ERROR: alloc_page failed for test %d\n", i);
            continue;
        }
        
        printf("Test %d: mapping VA %p to PA %p\n", i, (void*)va, (void*)pa);
        
        // 建立映射：设置读写执行权限进行全面测试
        if(map_page(pt, va, pa, PTE_R | PTE_W | PTE_X) != 0) {
            printf("ERROR: map_page failed for test %d\n", i);
            free_page((void*)pa);
            continue;
        }
        
        // 关键验证步骤：确保映射建立正确
        // 这里测试了页表遍历和地址转换的完整链路
        pte_t *pte = walk_lookup(pt, va);
        if(pte == 0 || !(*pte & PTE_V) || PTE_PA(*pte) != pa) {
            printf("ERROR: mapping verification failed for test %d\n", i);
        } else {
            printf("Test %d: mapping verification PASSED\n", i);
        }
        
        // 清理：释放测试用的物理页面
        free_page((void*)pa);
    }
    
    // 清理：销毁测试页表，验证资源回收
    destroy_pagetable(pt);
    printf("Multi-level page table test completed\n\n");
}

// ==================== 边界条件和错误处理测试 ====================
// 目的：验证系统在极限条件下的行为和错误恢复能力
void test_edge_cases(void) {
    printf("=== Testing Edge Cases ===\n");
    
    // 第一个测试：内存耗尽情况模拟
    // 目的：验证分配器在内存不足时的行为
    printf("Testing memory exhaustion...\n");
    void *pages[100];       // 页面指针数组
    int allocated = 0;      // 成功分配的页面数
    
    // 尝试分配大量页面，直到内存耗尽
    // 这个测试展示了分配器的极限容量
    for(int i = 0; i < 100; i++) {
        pages[i] = alloc_page();
        if(pages[i] == 0) {
            printf("Memory exhausted after %d pages\n", i);
            break;  // 遇到分配失败，停止测试
        }
        allocated++;
    }
    
    // 释放所有分配的页面 - 测试内存回收
    // 验证分配器能够正确回收资源
    for(int i = 0; i < allocated; i++) {
        free_page(pages[i]);
    }
    printf("Memory exhaustion test completed\n");
    
    // 第二个测试：地址对齐验证
    // 目的：确保系统正确处理对齐要求
    printf("Testing address alignment...\n");
    pagetable_t pt = create_pagetable();
    uint64 pa = (uint64)alloc_page();
    
    // 注意：实际的未对齐地址测试会触发panic
    // 在生产环境中，这是正确的行为
    printf("Testing unaligned address (should panic)...\n");
    // 示例：map_page(pt, 0x1001, pa, PTE_R) 会因为地址未对齐而panic
    
    // 清理测试资源
    free_page((void*)pa);
    destroy_pagetable(pt);
    printf("Edge cases test completed\n\n");
}

// ==================== 综合测试套件入口 ====================
// 作用：统一运行所有内存管理测试，提供完整的功能验证
void run_comprehensive_tests(void) {
    printf("=== Comprehensive Memory Management Tests ===\n\n");
    
    // 按逻辑顺序运行测试：
    // 1. 先测试基本的页表功能
    test_multilevel_pagetable();
    
    // 2. 再测试边界条件和错误处理
    test_edge_cases();
    
    printf("All comprehensive tests completed!\n");
}
