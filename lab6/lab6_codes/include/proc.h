#ifndef PROC_H
#define PROC_H
// 用户内存布局
#include "types.h"
#include "mm.h"
#define USTACK 0x4000        // 用户栈起始地址
#define TRAMPOLINE 0x3ffffff000  // trampoline页地址（最高页）

// ==================== 前向声明 ====================
struct trapframe;  // ← 添加前向声明

// ==================== 进程状态定义 ====================
enum procstate {
    UNUSED,     // 0: 未使用
    USED,       // 1: 已分配但未初始化
    RUNNABLE,   // 2: 就绪
    RUNNING,    // 3: 运行中
    SLEEPING,   // 4: 睡眠
    ZOMBIE      // 5: 僵尸
};

// ==================== 进程上下文 ====================
struct context {
    uint64 ra;   // 返回地址
    uint64 sp;   // 栈指针
    uint64 s0;   // 被调用者保存寄存器
    uint64 s1;
    uint64 s2;
    uint64 s3;
    uint64 s4;
    uint64 s5;
    uint64 s6;
    uint64 s7;
    uint64 s8;
    uint64 s9;
    uint64 s10;
    uint64 s11;
};

// ==================== 进程控制块 ====================
#define NPROC 64              // 最大进程数
#define KSTACK_SIZE 4096      // 内核栈大小

struct proc {
    // 进程标识和状态
    int pid;
    enum procstate state;
    char name[16];
    
    // 调度相关
    struct context context;
    uint64 kstack;
    
    // ⭐ 新增：系统调用支持
    struct trapframe *trapframe;  // ← 添加这一行
    
    // 时间统计
    uint64 run_time;
    uint64 create_time;
    
    // 父子关系
    struct proc *parent;
    int xstate;
    
    // 同步相关
    void *chan;
    int killed;
    
    // 内存管理
    pagetable_t pagetable;
};

// ==================== CPU状态 ====================
struct cpu {
    struct proc *proc;
    struct context context;
    int noff;
    int intena;
};

// ==================== 全局变量 ====================
extern struct proc proc[NPROC];
extern struct cpu cpus[1];

// ==================== 函数声明 ====================

// 初始化
void procinit(void);

// 进程管理
struct proc* alloc_proc(void);
void free_proc(struct proc *p);
int kthread_create(void (*fn)(void), char *name);
void exit_proc(int status);
int wait_proc(int *status);

// 调度
void scheduler(void) __attribute__((noreturn));
void sched(void);
void yield(void);
void swtch(struct context *old, struct context *new);

// 同步原语
void sleep(void *chan);
void wakeup(void *chan);

// 辅助函数
struct proc* myproc(void);
struct cpu* mycpu(void);
void proc_info(void);
void proc_stats(void);
const char* state_name(enum procstate s);

// 中断控制
void push_off(void);
void pop_off(void);

#endif