/* kernel/timer.c - 时钟管理 */

#include "types.h"
#include "defs.h"
#include "riscv.h"
#include "trap.h"
#include "printf.h"
#include "proc.h"  // ← 添加这一行
// ==================== CLINT 寄存器地址（QEMU virt 平台）====================
#define CLINT_MTIME     0x200BFF8L   // mtime 寄存器地址
#define CLINT_MTIMECMP  0x2004000L   // mtimecmp 寄存器地址（hart 0）

// 时钟配置
#define TIMER_FREQ 10000000     // QEMU时钟频率：10MHz
#define TIMER_INTERVAL_MS 100   // 时钟中断间隔：100ms
#define TICKS_PER_SEC (1000 / TIMER_INTERVAL_MS)  // 每秒tick数

// 计算时钟间隔（时钟周期数）
static uint64 timer_interval = (TIMER_FREQ * TIMER_INTERVAL_MS) / 1000;

// 系统运行时间（单位：tick）
static volatile uint64 ticks = 0;

// 每个hart的时钟数据区（用于M模式timervec）
struct timer_scratch {
    uint64 interval;       // [0] 时钟间隔
    uint64 next_time;      // [8] 下次中断时间
    uint64 saved_a0;       // [16] 保存的寄存器
    uint64 saved_a1;       // [24]
    uint64 saved_a2;       // [32]
    uint64 saved_a3;       // [40]
};

__attribute__ ((aligned (16))) static struct timer_scratch timer_scratch0;

// ==================== 读取 mtime ====================
static inline uint64 read_mtime(void) {
    return *(volatile uint64*)CLINT_MTIME;
}

// ==================== 写入 mtimecmp ====================
static inline void write_mtimecmp(uint64 value) {
    *(volatile uint64*)CLINT_MTIMECMP = value;
}

// ==================== 初始化时钟（每个hart调用） ====================
void timer_init_hart(void)
{
    // 初始化时钟数据区
    timer_scratch0.interval = timer_interval;
    timer_scratch0.next_time = 0;
    
    // 将数据区地址存入mscratch
    w_mscratch((uint64)&timer_scratch0);
    
    // 直接设置第一次时钟中断
    uint64 mtime = read_mtime();
    write_mtimecmp(mtime + timer_interval);
}

// ==================== 时钟中断处理函数 ====================
void timer_interrupt(void)
{
    ticks++;
    
    if(ticks % TICKS_PER_SEC == 0) {
        printf("[Timer] System uptime: %d seconds\n", (int)(ticks / TICKS_PER_SEC));
    }
    
    // 获取当前进程
    extern struct proc* myproc(void);
    extern void yield(void);
    
    struct proc *p = myproc();
    if(p != 0) {
        // 累加运行时间（每个tick都累加）
        p->run_time++;
        
        // 每10个tick抢占一次
        if(ticks % 10 == 0) {
            yield();
        }
    }
}

// ==================== 获取系统运行时间 ====================
uint64 get_ticks(void)
{
    return ticks;
}

uint64 get_uptime_seconds(void)
{
    return ticks / TICKS_PER_SEC;
}

// ==================== 简单的忙等待延时 ====================
void delay_ms(uint64 ms)
{
    uint64 start = ticks;
    uint64 target_ticks = (ms * TICKS_PER_SEC) / 1000;
    
    while((ticks - start) < target_ticks) {
        asm volatile("nop");
    }
}

// ==================== 初始化时钟系统 ====================
void timer_init(void)
{
    printf("Initializing timer system...\n");
    printf("Timer frequency: %d Hz\n", (int)TIMER_FREQ);
    printf("Interrupt interval: %d ms\n", (int)TIMER_INTERVAL_MS);
    
    // 注册时钟中断处理函数
    register_interrupt(IRQ_S_TIMER, timer_interrupt);
    
    printf("Timer system initialized\n");
}