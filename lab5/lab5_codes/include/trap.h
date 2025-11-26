#ifndef TRAP_H
#define TRAP_H

#include "types.h"

// ==================== 中断/异常原因代码 (scause寄存器值) ====================
// RISC-V异常类型定义 - 来自特权级规范表4.2
// 当bit[63]=0时，是异常(同步)；bit[63]=1时，是中断(异步)

// 异常原因 (同步事件 - scause bit[63]=0)
#define CAUSE_MISALIGNED_FETCH    0   // 指令地址未对齐
#define CAUSE_FETCH_ACCESS        1   // 指令访问故障
#define CAUSE_ILLEGAL_INSTRUCTION 2   // 非法指令
#define CAUSE_BREAKPOINT          3   // 断点
#define CAUSE_MISALIGNED_LOAD     4   // 加载地址未对齐
#define CAUSE_LOAD_ACCESS         5   // 加载访问故障
#define CAUSE_MISALIGNED_STORE    6   // 存储地址未对齐
#define CAUSE_STORE_ACCESS        7   // 存储访问故障
#define CAUSE_USER_ECALL          8   // 用户模式环境调用
#define CAUSE_SUPERVISOR_ECALL    9   // 监督模式环境调用
#define CAUSE_MACHINE_ECALL       11  // 机器模式环境调用
#define CAUSE_FETCH_PAGE_FAULT    12  // 指令页故障
#define CAUSE_LOAD_PAGE_FAULT     13  // 加载页故障
#define CAUSE_STORE_PAGE_FAULT    15  // 存储页故障

// 中断原因 (异步事件 - scause bit[63]=1)
// 实际值 = 0x8000000000000000 | 中断码
#define IRQ_S_SOFT    1   // 监督模式软件中断
#define IRQ_M_SOFT    3   // 机器模式软件中断
#define IRQ_S_TIMER   5   // 监督模式时钟中断
#define IRQ_M_TIMER   7   // 机器模式时钟中断
#define IRQ_S_EXT     9   // 监督模式外部中断
#define IRQ_M_EXT     11  // 机器模式外部中断

// ==================== 中断处理器函数类型 ====================
typedef void (*interrupt_handler_t)(void);

// ==================== Trapframe结构 - 保存中断/异常时的CPU状态 ====================
// 这个结构体在中断发生时保存所有寄存器，在中断返回时恢复
// 布局必须与kernelvec.S中的保存/恢复顺序完全一致
struct trapframe {
    /*   0 */ uint64 ra;
    /*   8 */ uint64 sp;
    /*  16 */ uint64 gp;
    /*  24 */ uint64 tp;
    /*  32 */ uint64 t0;
    /*  40 */ uint64 t1;
    /*  48 */ uint64 t2;
    /*  56 */ uint64 s0;
    /*  64 */ uint64 s1;
    /*  72 */ uint64 a0;
    /*  80 */ uint64 a1;
    /*  88 */ uint64 a2;
    /*  96 */ uint64 a3;
    /* 104 */ uint64 a4;
    /* 112 */ uint64 a5;
    /* 120 */ uint64 a6;
    /* 128 */ uint64 a7;
    /* 136 */ uint64 s2;
    /* 144 */ uint64 s3;
    /* 152 */ uint64 s4;
    /* 160 */ uint64 s5;
    /* 168 */ uint64 s6;
    /* 176 */ uint64 s7;
    /* 184 */ uint64 s8;
    /* 192 */ uint64 s9;
    /* 200 */ uint64 s10;
    /* 208 */ uint64 s11;
    /* 216 */ uint64 t3;
    /* 224 */ uint64 t4;
    /* 232 */ uint64 t5;
    /* 240 */ uint64 t6;
    /* 248 */ uint64 sepc;
    /* 256 */ uint64 sstatus;
};
// 总大小: 264字节 (33个64位寄存器)

// ==================== 核心接口函数 ====================
void trap_init(void);                              // 初始化中断系统
void register_interrupt(int irq, interrupt_handler_t handler); // 注册中断处理函数
void kerneltrap(struct trapframe *tf);                           // 内核态中断处理入口(在trap.c中实现)
void kernelvec(void);                              // 中断向量(在kernelvec.S中实现)

// ==================== 辅助函数 ====================
void dump_trapframe(struct trapframe *tf);         // 打印trapframe内容(调试用)
const char* trap_cause_name(uint64 cause);         // 获取异常/中断原因的名称
// ==================== 异常处理函数 ====================
void handle_exception(struct trapframe *tf);
void handle_syscall(struct trapframe *tf);
void handle_instruction_page_fault(struct trapframe *tf);
void handle_load_page_fault(struct trapframe *tf);
void handle_store_page_fault(struct trapframe *tf);

// ==================== 测试函数 ====================
void test_exception_handling(void);
#endif