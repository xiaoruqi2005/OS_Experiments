/* kernel/exception_test.c - 异常处理测试 */

#include "types.h"
#include "defs.h"
#include "riscv.h"
#include "trap.h"
#include "printf.h"

// ==================== 测试1：断点异常 ====================
static void test_breakpoint(void) {
    printf("\n--- Test 1: Breakpoint Exception ---\n");
    printf("About to trigger breakpoint...\n");
    
    asm volatile("ebreak");//展示异常类型：BREAKPOINT.展示了异常能够被捕获并恢复执行（sepc += 2）
    
    printf("Breakpoint handled successfully!\n");
}

// ==================== 测试2：系统调用异常 ====================
static void test_syscall(void) {
    printf("\n--- Test 2: System Call (ecall) ---\n");
    printf("About to make a syscall...\n");
    
    register uint64 a7 asm("a7") = 42;  // syscall number
    register uint64 a0 asm("a0") = 100; // argument 1
    register uint64 a1 asm("a1") = 200; // argument 2
    
    asm volatile(
        "ecall"
        : "+r"(a0)
        : "r"(a7), "r"(a1)
        : "memory"
    );
    
    printf("Syscall completed!\n");
}

// ==================== 危险测试（会导致panic）====================
// 取消注释 #if 0 和对应的 #endif 来启用单个测试

#if 0  // ← 改为 1 来启用加载页故障测试
// ==================== 测试3：加载页故障（将会panic）====================
static void test_load_page_fault(void) {
    printf("\n--- Test 3: Load Page Fault ---\n");
    printf("About to read from unmapped address...\n");
    printf("WARNING: This will cause a panic!\n");
    
    volatile uint64 *bad_addr = (uint64*)0x123456789000UL;
    volatile uint64 val = *bad_addr;
    (void)val;
    
    printf("This line should not print\n");
}
#endif

#if 0  // ← 改为 1 来启用存储页故障测试
// ==================== 测试4：存储页故障（将会panic）====================
static void test_store_page_fault(void) {
    printf("\n--- Test 4: Store Page Fault ---\n");
    printf("About to write to unmapped address...\n");
    printf("WARNING: This will cause a panic!\n");
    
    volatile uint64 *bad_addr = (uint64*)0x987654321000UL;
    *bad_addr = 0xdeadbeef;
    
    printf("This line should not print\n");
}
#endif

#if 0  // ← 改为 1 来启用写只读段测试
// ==================== 测试5：写入只读代码段（将会panic）====================
static void test_write_to_text(void) {
    printf("\n--- Test 5: Write to Read-Only Text Segment ---\n");
    printf("About to write to kernel code segment...\n");
    printf("WARNING: This will cause a panic!\n");
    
    volatile uint32 *code_addr = (uint32*)0x80001000;
    *code_addr = 0xdeadbeef;
    
    printf("This line should not print\n");
}
#endif

#if 0  // ← 改为 1 来启用非法指令测试
// ==================== 测试6：非法指令（将会panic）====================
static void test_illegal_instruction(void) {
    printf("\n--- Test 6: Illegal Instruction ---\n");
    printf("About to execute illegal instruction...\n");
    printf("WARNING: This will cause a panic!\n");
    
    asm volatile(".word 0xffffffff");
    
    printf("This line should not print\n");
}
#endif

#if 0  // ← 改为 1 来启用未对齐访问测试
// ==================== 测试7：地址未对齐访问（将会panic）====================
static void test_misaligned_load(void) {
    printf("\n--- Test 7: Misaligned Load ---\n");
    printf("About to do misaligned 64-bit load...\n");
    printf("WARNING: This will cause a panic!\n");
    
    char buffer[16];
    volatile uint64 *misaligned = (uint64*)(buffer + 1);
    volatile uint64 val = *misaligned;
    (void)val;
    
    printf("This line should not print\n");
}
#endif

// ==================== 主测试函数 ====================
void test_exception_handling(void) {
    printf("\n");
    printf("========================================\n");
    printf("=== Exception Handling Test Suite ===\n");
    printf("========================================\n");
    
    // 测试1：断点（不会panic）
    test_breakpoint();
    
    // 测试2：系统调用（不会panic）
    test_syscall();
    
    printf("\n=== Safe Tests Completed ===\n");
    printf("\nDangerous tests are disabled by default.\n");
    printf("To enable a test, edit exception_test.c and change\n");
    printf("the corresponding '#if 0' to '#if 1'\n\n");
    
    // 危险测试（会导致panic）
    // 在 exception_test.c 中修改 #if 0 为 #if 1 来启用
    
#if 0  // 改为 1 来启用
    test_load_page_fault();
#endif

#if 0  // 改为 1 来启用
    test_store_page_fault();
#endif

#if 0  // 改为 1 来启用
    test_write_to_text();
#endif

#if 0  // 改为 1 来启用
    test_illegal_instruction();
#endif

#if 0  // 改为 1 来启用
    test_misaligned_load();
#endif
    
    printf("=== Exception Tests Completed ===\n");
}