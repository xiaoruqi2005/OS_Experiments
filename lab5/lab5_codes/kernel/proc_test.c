/* kernel/proc_test.c - 进程测试 */

#include "types.h"
#include "defs.h"
#include "riscv.h"
#include "proc.h"
// ==================== 测试任务 ====================

// 简单的计数任务
static void simple_task_1(void) {
    printf("[Task1] Started (PID %d)\n", myproc()->pid);
    
    for(int i = 0; i < 5; i++) {
        printf("[Task1] Count: %d\n", i);
        
        // 简单延时
        for(volatile int j = 0; j < 10000000; j++);
        
        // 主动让出CPU
        yield();
    }
    
    printf("[Task1] Finished\n");
}

static void simple_task_2(void) {
    printf("[Task2] Started (PID %d)\n", myproc()->pid);
    
    for(int i = 0; i < 5; i++) {
        printf("[Task2] Iteration: %d\n", i);
        
        for(volatile int j = 0; j < 10000000; j++);
        
        yield();
    }
    
    printf("[Task2] Finished\n");
}

static void simple_task_3(void) {
    printf("[Task3] Started (PID %d)\n", myproc()->pid);
    
    for(int i = 0; i < 5; i++) {
        printf("[Task3] Step: %d\n", i);
        
        for(volatile int j = 0; j < 10000000; j++);
        
        yield();
    }
    
    printf("[Task3] Finished\n");
}

// CPU密集型任务
static void cpu_intensive_task(void) {
    printf("[CPU-Task] Started (PID %d)\n", myproc()->pid);
    
    uint64 count = 0;
    uint64 start_time = get_ticks();
    
    // 运行约1秒
    while(get_ticks() - start_time < 10) {  // 10 ticks = 1秒
        count++;
        
        // 每隔一段时间打印一次
        if(count % 1000000 == 0) {
            printf("[CPU-Task PID %d] Count: %lu\n", 
                   myproc()->pid, count);
        }
    }
    
    printf("[CPU-Task PID %d] Finished with count=%lu\n", 
           myproc()->pid, count);
}

// 生产者-消费者测试
#define BUFFER_SIZE 10
static int buffer[BUFFER_SIZE];
static int buffer_count = 0;
static void *buffer_not_empty = (void*)1;
static void *buffer_not_full = (void*)2;

static void producer_task(void) {
    printf("[Producer] Started (PID %d)\n", myproc()->pid);
    
    for(int i = 0; i < 20; i++) {
        // 等待缓冲区不满
        while(buffer_count >= BUFFER_SIZE) {
            printf("[Producer] Buffer full, sleeping...\n");
            sleep(buffer_not_full, 0);
        }
        
        // 生产数据
        buffer[buffer_count++] = i;
        printf("[Producer] Produced: %d (buffer_count=%d)\n", 
               i, buffer_count);
        
        // 唤醒消费者
        wakeup(buffer_not_empty);
        
        // 延时
        for(volatile int j = 0; j < 5000000; j++);
        yield();
    }
    
    printf("[Producer] Finished\n");
}

static void consumer_task(void) {
    printf("[Consumer] Started (PID %d)\n", myproc()->pid);
    
    for(int i = 0; i < 20; i++) {
        // 等待缓冲区不空
        while(buffer_count <= 0) {
            printf("[Consumer] Buffer empty, sleeping...\n");
            sleep(buffer_not_empty, 0);
        }
        
        // 消费数据
        int item = buffer[--buffer_count];
        printf("[Consumer] Consumed: %d (buffer_count=%d)\n", 
               item, buffer_count);
        
        // 唤醒生产者
        wakeup(buffer_not_full);
        
        // 延时
        for(volatile int j = 0; j < 8000000; j++);
        yield();
    }
    
    printf("[Consumer] Finished\n");
}

// ==================== 测试函数 ====================

// 测试1：基本的进程创建
void test_process_creation(void) {
    printf("\n");
    printf("========================================\n");
    printf("=== Test 1: Process Creation ===\n");
    printf("========================================\n");
    
    // 创建3个简单任务
    int pid1 = kthread_create(simple_task_1, "task1");
    int pid2 = kthread_create(simple_task_2, "task2");
    int pid3 = kthread_create(simple_task_3, "task3");
    
    printf("Created 3 tasks: PID %d, %d, %d\n", pid1, pid2, pid3);
    
    // 打印进程表
    print_proc_table();
    
    // 等待所有子进程完成
    printf("Waiting for tasks to complete...\n");
    wait(0);
    wait(0);
    wait(0);
    
    printf("=== Test 1 Complete ===\n\n");
}

// 测试2：调度器测试
void test_scheduler(void) {
    printf("\n");
    printf("========================================\n");
    printf("=== Test 2: Scheduler ===\n");
    printf("========================================\n");
    
    printf("Creating 3 CPU-intensive tasks...\n");
    
    uint64 start_time = get_ticks();
    
    kthread_create(cpu_intensive_task, "cpu1");
    kthread_create(cpu_intensive_task, "cpu2");
    kthread_create(cpu_intensive_task, "cpu3");
    
    // 等待完成
    wait(0);
    wait(0);
    wait(0);
    
    uint64 end_time = get_ticks();
    
    printf("Scheduler test completed in %lu ticks\n", 
           end_time - start_time);
    
    print_proc_table();
    
    printf("=== Test 2 Complete ===\n\n");
}

// 测试3：同步机制
void test_synchronization(void) {
    printf("\n");
    printf("========================================\n");
    printf("=== Test 3: Synchronization ===\n");
    printf("========================================\n");
    
    printf("Testing producer-consumer pattern...\n");
    
    // 初始化缓冲区
    buffer_count = 0;
    
    // 创建生产者和消费者
    kthread_create(producer_task, "producer");
    kthread_create(consumer_task, "consumer");
    
    // 等待完成
    wait(0);
    wait(0);
    
    printf("=== Test 3 Complete ===\n\n");
}

// 主测试入口
void run_process_tests(void) {
    printf("\n");
    printf("========================================\n");
    printf("=== Process Management Test Suite ===\n");
    printf("========================================\n");
    
    // 测试1：进程创建
    test_process_creation();
    
    // 打印统计
    print_proc_stats();
    
    // 测试2：调度器
    test_scheduler();
    
    // 打印统计
    print_proc_stats();
    
    // 测试3：同步机制
    test_synchronization();
    
    // 最终统计
    printf("\n=== Final Statistics ===\n");
    print_proc_stats();
    print_proc_table();
    
    printf("\n");
    printf("========================================\n");
    printf("=== All Process Tests Complete! ===\n");
    printf("========================================\n\n");
}