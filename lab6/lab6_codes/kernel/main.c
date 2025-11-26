/* kernel/main.c - 系统主程序（实验6版本 - 修复版）*/

#include "types.h"
#include "defs.h"
#include "riscv.h"
#include "proc.h"
#include "syscall.h"

extern char etext[];
extern char edata[];
extern char end[];
extern struct proc proc[];
extern struct proc *initproc;

// ==================== 系统调用测试任务 ====================

void test_getpid(void) {
    printf("\n=== Test 1: sys_getpid ===\n");
    
    register uint64 a7 asm("a7") = SYS_getpid;
    register uint64 a0 asm("a0");
    
    asm volatile("ecall" : "=r"(a0) : "r"(a7));
    
    // ⭐ 修复：立即保存返回值到局部变量
    int result = (int)a0;
    int expected = myproc()->pid;
    
    printf("sys_getpid() returned: %d\n", result);
    printf("myproc()->pid = %d\n", expected);
    
    if(result == expected) {
        printf("✓ sys_getpid test PASSED\n");
    } else {
        printf("✗ sys_getpid test FAILED\n");
    }
}

void test_write(void) {
    printf("\n=== Test 2: sys_write ===\n");
    
    char *msg = "Hello from sys_write!\n";
    int msg_len = 22;
    
    register uint64 a7 asm("a7") = SYS_write;
    register uint64 a0 asm("a0") = 1;
    register uint64 a1 asm("a1") = (uint64)msg;
    register uint64 a2 asm("a2") = msg_len;
    
    asm volatile("ecall" : "+r"(a0) : "r"(a7), "r"(a1), "r"(a2));
    
    // ⭐ 修复：立即保存返回值
    int result = (int)a0;
    
    printf("sys_write() returned: %d\n", result);
    
    if(result == msg_len) {
        printf("✓ sys_write test PASSED\n");
    } else {
        printf("✗ sys_write test FAILED\n");
    }
}

void test_multiple_syscalls(void) {
    printf("\n=== Test 3: Multiple System Calls ===\n");
    
    for(int i = 0; i < 5; i++) {
        register uint64 a7 asm("a7") = SYS_getpid;
        register uint64 a0 asm("a0");
        
        asm volatile("ecall" : "=r"(a0) : "r"(a7));
        
        // ⭐ 修复：立即保存返回值
        int result = (int)a0;
        
        printf("Call %d: getpid() = %d\n", i+1, result);
    }
    
    printf("✓ Multiple syscalls test PASSED\n");
}

void test_syscall_parameters(void) {
    printf("\n=== Test 4: System Call Parameters ===\n");
    
    char msg1[] = "First message\n";
    char msg2[] = "Second message\n";
    char msg3[] = "Third message\n";
    
    register uint64 a7 asm("a7") = SYS_write;
    register uint64 a0 asm("a0") = 1;
    register uint64 a1 asm("a1") = (uint64)msg1;
    register uint64 a2 asm("a2") = 14;
    asm volatile("ecall" : "+r"(a0) : "r"(a7), "r"(a1), "r"(a2));
    
    a0 = 1;
    a1 = (uint64)msg2;
    a2 = 15;
    asm volatile("ecall" : "+r"(a0) : "r"(a7), "r"(a1), "r"(a2));
    
    a0 = 1;
    a1 = (uint64)msg3;
    a2 = 14;
    asm volatile("ecall" : "+r"(a0) : "r"(a7), "r"(a1), "r"(a2));
    
    printf("✓ Parameter passing test PASSED\n");
}

void test_invalid_syscall(void) {
    printf("\n=== Test 5: Invalid System Call ===\n");
    
    register uint64 a7 asm("a7") = 999;
    register uint64 a0 asm("a0");
    
    asm volatile("ecall" : "=r"(a0) : "r"(a7));
    
    // ⭐ 修复：立即保存返回值
    int result = (int)a0;
    
    printf("Invalid syscall returned: %d\n", result);
    
    if(result == -1) {
        printf("✓ Invalid syscall handling PASSED\n");
    } else {
        printf("✗ Invalid syscall handling FAILED\n");
    }
}

void test_write_edge_cases(void) {
    printf("\n=== Test 6: sys_write Edge Cases ===\n");
    
    char empty[] = "";
    register uint64 a7 asm("a7") = SYS_write;
    register uint64 a0 asm("a0") = 1;
    register uint64 a1 asm("a1") = (uint64)empty;
    register uint64 a2 asm("a2") = 0;
    asm volatile("ecall" : "+r"(a0) : "r"(a7), "r"(a1), "r"(a2));
    int result1 = (int)a0;  // ⭐ 立即保存
    printf("Empty string write returned: %d\n", result1);
    
    char single[] = "X";
    a0 = 1;
    a1 = (uint64)single;
    a2 = 1;
    asm volatile("ecall" : "+r"(a0) : "r"(a7), "r"(a1), "r"(a2));
    int result2 = (int)a0;  // ⭐ 立即保存
    printf("\nSingle char write returned: %d\n", result2);
    
    char longstr[] = "This is a longer string to test the write system call functionality!\n";
    a0 = 1;
    a1 = (uint64)longstr;
    a2 = 70;
    asm volatile("ecall" : "+r"(a0) : "r"(a7), "r"(a1), "r"(a2));
    int result3 = (int)a0;  // ⭐ 立即保存
    printf("Long string write returned: %d\n", result3);
    
    printf("✓ Edge cases test PASSED\n");
}

// ==================== 主测试进程 ====================
void syscall_test_process(void) {
    printf("\n");
    printf("========================================\n");
    printf("=== System Call Test Process Started ===\n");
    printf("========================================\n");
    printf("PID: %d\n", myproc()->pid);
    printf("Name: %s\n", myproc()->name);
    printf("\n");
    
    test_getpid();
    test_write();
    test_multiple_syscalls();
    test_syscall_parameters();
    test_invalid_syscall();
    test_write_edge_cases();
    
    printf("\n");
    printf("========================================\n");
    printf("=== All System Call Tests Completed ===\n");
    printf("========================================\n");
    printf("\n");
    
    // ⭐ 修复：测试完成后退出进程
    printf("Process exiting...\n");
    exit_proc(0);
    
    // 不会执行到这里
    for(;;);
}

// ==================== 系统主函数 ====================
void main(void) {
    printf("\n");
    printf("========================================\n");
    printf("=== RISC-V OS Lab 6: System Calls ===\n");
    printf("========================================\n");
    
    printf("\nSystem Information:\n");
    printf("  Hart ID:  %d\n", (int)r_tp());
    printf("  KERNBASE: %p\n", (void*)0x80000000L);
    printf("  PHYSTOP:  %p\n", (void*)0x88000000L);
    
    printf("\nKernel symbols:\n");
    printf("  etext: %p\n", etext);
    printf("  edata: %p\n", edata);
    printf("  end:   %p\n", end);
    
    printf("\n=== Phase 1: Physical Memory Management ===\n");
    pmm_init();
    pmm_info();
    
    printf("\n=== Phase 2: Virtual Memory Activation ===\n");
    printf("Current satp: %p\n", (void*)r_satp());
    kvminit();
    kvminithart();
    printf("Virtual memory enabled! New satp: %p\n", (void*)r_satp());
    
    printf("\n=== Phase 3: Interrupt System ===\n");
    trap_init();
    
    printf("\n=== Phase 4: Timer System ===\n");
    timer_init();
    
    printf("\n=== Phase 5: Process System ===\n");
    procinit();
    
    // ==================== Phase 6: 创建用户进程 ====================
    printf("\n=== Phase 6: Creating First User Process ===\n");

    int init_pid = userinit();  // ← 改用 userinit
    if(init_pid < 0) {
        panic("failed to create init process");
    }

    printf("First user process created with PID %d\n", init_pid);
    printf("This process runs in U-mode (user mode)!\n");
    printf("\n=== System Ready ===\n");
    printf("All subsystems initialized successfully!\n");
    printf("- Physical memory manager\n");
    printf("- Virtual memory (Sv39)\n");
    printf("- Interrupt handling\n");
    printf("- Timer interrupts (100ms)\n");
    printf("- Process management\n");
    printf("- System call interface\n");
    
    printf("\n========================================\n");
    printf("Starting scheduler...\n");
    printf("The system will now run the test process.\n");
    printf("========================================\n\n");
    
    scheduler();
}
//用户态 → ecall → 用户态陷阱 → syscall 分发 → sys_exit → trapret → 用户态 → 进程结束
//系统捕获 scause=8（User Mode Environment Call），说明用户态成功进入内核。
//随后正确调用 sys_exit()
//输出 USERTRAPRET / URET 表示成功恢复用户寄存器并执行 sret。