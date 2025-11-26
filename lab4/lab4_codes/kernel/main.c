#include "defs.h"
#include "mm.h"
#include "riscv.h"
#include "trap.h"

void test_permissions(void) {
    printf("\n=== Testing Page Permissions ===\n");
    
    // 测试代码段
    uint64 code_addr = 0x80001000;
    printf("Testing code segment at %p:\n", (void*)code_addr);
    
    if(check_page_permission(code_addr, ACCESS_READ))
        printf("  Read: ALLOWED\n");
    else
        printf("  Read: DENIED\n");
        
    if(check_page_permission(code_addr, ACCESS_WRITE))
        printf("  Write: ALLOWED\n");
    else
        printf("  Write: DENIED\n");
        
    if(check_page_permission(code_addr, ACCESS_EXEC))
        printf("  Execute: ALLOWED\n");
    else
        printf("  Execute: DENIED\n");
}

void main(void) {
    // 初始化控制台系统
    consoleinit();
    
    clear_screen();
    printf("=== RISC-V OS Lab 4: Interrupts & Timer ===\n");
    printf("System Information:\n");
    printf("  Hart ID:  %d\n", (int)r_tp());
    printf("  KERNBASE: %p\n", (void*)KERNBASE);
    printf("  PHYSTOP:  %p\n", (void*)PHYSTOP);
    
    printf("\nKernel symbols:\n");
    printf("  etext: %p\n", etext);
    printf("  edata: %p\n", edata);
    printf("  end:   %p\n", end);
    
    // ========== Phase 1: 物理内存管理 ==========
    printf("\n=== Phase 1: Physical Memory Management ===\n");
    pmm_init();
    
    // ========== Phase 2: 虚拟内存 ==========
    printf("\n=== Phase 2: Virtual Memory Activation ===\n");
    printf("Current satp: %p\n", (void*)r_satp());
    kvminit();
    kvminithart();
    printf("Virtual memory enabled! New satp: %p\n", (void*)r_satp());
    
    // ========== Phase 3: 中断系统 ==========
    printf("\n=== Phase 3: Interrupt System ===\n");
    trap_init();
//设置 S 模式 trap 向量为 kernelvec
//开启 S 模式中断：
//软件中断 SSIE
//时钟中断 STIE
//外部中断 SEIE
//让 CPU 能够接收所有 supervisor 中断
//中断总控框架已经搭建完毕，S-mode 已经能够接收任何中断。
    // ========== Phase 4: 时钟系统 ==========
    printf("\n=== Phase 4: Timer System ===\n");
    timer_init();
    // 在 timer_init() 之后添加：
//时钟中断已成功注册，可被调度执行
   
    printf("\n=== System Ready ===\n");
    printf("All subsystems initialized successfully!\n");
    printf("- Physical memory manager\n");
    printf("- Virtual memory (Sv39)\n");
    printf("- Interrupt handling\n");
    printf("- Timer interrupts\n");
    printf("\nWaiting for timer interrupts...\n");
    printf("(Timer interrupt every 100ms)\n");
    
    // ========== 等待中断测试 ==========
    // 等待并观察时钟中断
    //timer_interrupt() 被硬件真正触发后打印出来的
    //每 1 秒出现一次 “[Timer] System uptime…” 。
//这证明中断链路（M → S）完全正确，中断处理函数确实被执行。
    int last_second = -1;
    for(int i = 0; i < 100; i++) {  // 改为1000次循环，运行更久
        uint64 current_second = get_uptime_seconds();
        
        if(current_second != last_second) {
            last_second = current_second;
            printf("Main: Second %d - ticks=%d\n", 
                (int)current_second, (int)get_ticks());
        }
        // 10秒后退出循环
        if(current_second >= 10) {
            break;
        }
        // 延长延时
        for(volatile int j = 0; j < 50000000; j++);  // 增加延时
    }
    printf("\n=== Phase 5: Exception Handling ===\n");
    test_exception_handling();

    // 显示统计信息
    print_trap_stats();
    pmm_info();
    
    printf("\n=== Lab 4 Complete! ===\n");
    printf("Successfully implemented:\n");
    printf("  - Machine mode initialization\n");
    printf("  - Interrupt delegation (M->S)\n");
    printf("  - Trap handling framework\n");
    printf("  - Timer interrupts\n");
    printf("  - Context save/restore\n");
    printf("\nSystem running with interrupts!\n");
    printf("Press Ctrl+A then X to exit QEMU\n");
    
    // 系统空闲循环
    while(1) {
        asm volatile("wfi"); // 等待中断
    }
}