/* kernel/trap.c - 中断和异常处理
 *
 * 这是操作系统响应硬件事件的核心模块
 * 负责：
 *   - 区分中断和异常
 *   - 分发到具体的处理函数
 *   - 处理时钟中断、外部中断、页故障等
 */

#include "types.h"
#include "defs.h"
#include "riscv.h"
#include "trap.h"
#include "printf.h"
// ==================== 内存布局常量 ====================
#define KERNBASE 0x80000000L        // 内核起始地址
#define PHYSTOP  0x88000000L        // 物理内存结束地址（128MB）

// 外部符号声明（来自链接脚本）
extern char etext[];
extern char edata[];
extern char end[];

// ==================== 中断统计 ====================
static uint64 interrupt_counts[16] = {0};  // 记录各类中断次数
static uint64 exception_count = 0;         // 记录异常总数

// 中断处理函数表 - 支持动态注册中断处理函数
static interrupt_handler_t interrupt_handlers[16]= {0};
// ==================== 初始化中断系统 ====================
void trap_init(void)
{
    printf("Initializing trap system...\n");
    
    // 清空中断处理函数表
    for(int i = 0; i < 16; i++) {
        interrupt_handlers[i] = 0;
        interrupt_counts[i] = 0;
    }
    
    // 设置S模式中断向量基址
    // MODE=0 (Direct): 所有中断都跳转到同一个地址
    // stvec必须4字节对齐(最低2位为00表示Direct模式)
    w_stvec((uint64)kernelvec);
    
    printf("Set stvec to %p\n", (void*)kernelvec);
    
    // 启用S模式中断
    // SIE: Supervisor Interrupt Enable
    // - SEIE: 外部中断使能
    // - STIE: 时钟中断使能  
    // - SSIE: 软件中断使能
    w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    
    // 全局中断使能：设置sstatus.SIE位
    w_sstatus(r_sstatus() | SSTATUS_SIE);
    
    printf("Trap system initialized\n");
}

// ==================== 注册中断处理函数 ====================
void register_interrupt(int irq, interrupt_handler_t handler)
{
    if(irq < 0 || irq >= 16) {
        printf("register_interrupt: invalid IRQ %d\n", irq);
        return;
    }
    
    interrupt_handlers[irq] = handler;
    printf("Registered handler for IRQ %d\n", irq);
}

// ==================== 设备中断处理 ====================
// 检查并处理设备中断
// 返回值：1=处理了中断，0=没有中断待处理
static int devintr(void)
{
    uint64 scause = r_scause();
    
    if((scause & 0x8000000000000000L) == 0) {
        return 0;
    }
    
    scause = scause & 0xff;
    
    if(scause == IRQ_S_TIMER) {
        // 时钟中断处理
        interrupt_counts[IRQ_S_TIMER]++;
        
        if(interrupt_handlers[IRQ_S_TIMER]) {
            interrupt_handlers[IRQ_S_TIMER]();
        }
        
        return 1;
        
    } else if(scause == IRQ_S_SOFT) {
        // 软件中断处理（来自 M 模式的时钟注入）
        interrupt_counts[IRQ_S_SOFT]++;
        
        // 清除软件中断标志
        w_sip(r_sip() & ~2);
        
        // 这实际上是时钟中断，调用时钟处理函数
        if(interrupt_handlers[IRQ_S_TIMER]) {
            interrupt_handlers[IRQ_S_TIMER]();
            interrupt_counts[IRQ_S_TIMER]++;  // 也统计为时钟中断
        }
        
        return 1;
        
    } else if(scause == IRQ_S_EXT) {
        // 外部中断处理
        interrupt_counts[IRQ_S_EXT]++;
        
        if(interrupt_handlers[IRQ_S_EXT]) {
            interrupt_handlers[IRQ_S_EXT]();
        }
        
        return 1;
    }
    
    return 0;
}
// ==================== 系统调用处理 ====================
void handle_syscall(struct trapframe *tf) {
    printf("\n=== System Call ===\n");
    printf("syscall number: %d (in a7)\n", (int)tf->a7);
    printf("arguments: a0=%p, a1=%p\n", (void*)tf->a0, (void*)tf->a1);
    printf("called from: %p\n", (void*)tf->sepc);
    
    // 跳过 ecall 指令（4字节）
    tf->sepc += 4;
    
    printf("System call handled, returning to %p\n", (void*)tf->sepc);
}

// ==================== 指令页故障处理 ====================
void handle_instruction_page_fault(struct trapframe *tf) {
    uint64 fault_addr = r_stval();  // 故障地址
    
    printf("\n=== Instruction Page Fault ===\n");
    printf("Fault address: %p\n", (void*)fault_addr);
    printf("PC: %p\n", (void*)tf->sepc);
    
    // 简单处理：如果是内核地址，panic
    if(fault_addr >= KERNBASE) {
        panic("Instruction page fault in kernel space");
    }
    
    // 这里可以实现按需分页等功能
    printf("TODO: Implement demand paging for instruction fault\n");
    panic("Instruction page fault not handled");
}

// ==================== 加载页故障处理 ====================
void handle_load_page_fault(struct trapframe *tf) {
    uint64 fault_addr = r_stval();  // 故障地址
    
    printf("\n=== Load Page Fault ===\n");
    printf("Fault address: %p\n", (void*)fault_addr);
    printf("PC: %p\n", (void*)tf->sepc);
    printf("Tried to read from unmapped address\n");
    
    // 简单处理：panic
    panic("Load page fault");
}

// ==================== 存储页故障处理 ====================
void handle_store_page_fault(struct trapframe *tf) {
    uint64 fault_addr = r_stval();  // 故障地址
    
    printf("\n=== Store Page Fault ===\n");
    printf("Fault address: %p\n", (void*)fault_addr);
    printf("PC: %p\n", (void*)tf->sepc);
    printf("Tried to write to unmapped or read-only address\n");
    
    // 检查是否写入只读代码段
    if(fault_addr >= KERNBASE && fault_addr < (uint64)etext) {
        printf("Attempted to write to read-only kernel text segment!\n");
    }
    
    panic("Store page fault");
}

// ==================== 统一异常处理入口 ====================
void handle_exception(struct trapframe *tf) {
    uint64 cause = r_scause();
    
    printf("\n[Exception Handler] cause=%d (%s)\n", 
           (int)cause, trap_cause_name(cause));
    
    switch(cause) {
        case CAUSE_USER_ECALL:           // 8: 用户模式系统调用
        case CAUSE_SUPERVISOR_ECALL:     // 9: 监督模式系统调用
            handle_syscall(tf);
            break;
            
        case CAUSE_FETCH_PAGE_FAULT:     // 12: 指令页故障
            handle_instruction_page_fault(tf);
            break;
            
        case CAUSE_LOAD_PAGE_FAULT:      // 13: 加载页故障
            handle_load_page_fault(tf);
            break;
            
        case CAUSE_STORE_PAGE_FAULT:     // 15: 存储页故障
            handle_store_page_fault(tf);
            break;
            
        case CAUSE_ILLEGAL_INSTRUCTION:  // 2: 非法指令
            printf("\n=== Illegal Instruction ===\n");
            printf("PC: %p\n", (void*)tf->sepc);
            printf("Instruction value: %p\n", (void*)r_stval());
            panic("Illegal instruction");
            break;
            
        case CAUSE_BREAKPOINT:           // 3: 断点
            printf("\n=== Breakpoint ===\n");
            printf("PC: %p\n", (void*)tf->sepc);
            // 跳过 ebreak 指令（2字节压缩指令）
            tf->sepc += 2;
            printf("Breakpoint handled, continuing from %p\n", (void*)tf->sepc);
            break;
            
        case CAUSE_MISALIGNED_FETCH:     // 0: 指令地址未对齐
            printf("\n=== Misaligned Instruction Fetch ===\n");
            printf("Address: %p\n", (void*)r_stval());
            panic("Misaligned instruction fetch");
            break;
            
        case CAUSE_MISALIGNED_LOAD:      // 4: 加载地址未对齐
            printf("\n=== Misaligned Load ===\n");
            printf("Address: %p\n", (void*)r_stval());
            panic("Misaligned load");
            break;
            
        case CAUSE_MISALIGNED_STORE:     // 6: 存储地址未对齐
            printf("\n=== Misaligned Store ===\n");
            printf("Address: %p\n", (void*)r_stval());
            panic("Misaligned store");
            break;
            
        default:
            printf("\n=== Unknown Exception ===\n");
            printf("cause: %d\n", (int)cause);
            printf("PC: %p\n", (void*)tf->sepc);
            printf("stval: %p\n", (void*)r_stval());
            panic("Unknown exception");
    }
}
// ==================== 内核态中断/异常处理入口 ====================
// 从kernelvec.S调用，此时trapframe已保存在内核栈上
// 修改 kerneltrap 函数签名
void kerneltrap(struct trapframe *tf)  // ← 添加参数
{
    uint64 sstatus = r_sstatus();
    
    // 安全检查
    if((sstatus & SSTATUS_SPP) == 0) {
        panic("kerneltrap: not from supervisor mode");
    }
    
    if(sstatus & SSTATUS_SIE) {
        panic("kerneltrap: interrupts enabled");
    }
    
    // 处理设备中断
    int is_device_interrupt = devintr();
    
    if(!is_device_interrupt) {
        // 异常处理
        exception_count++;
        
        // 直接使用传入的 trapframe 指针（地址正确！）
        handle_exception(tf);
        
        // 不需要写回sepc，kernelvec会自动从栈上恢复
    }
    
    w_sstatus(sstatus);
}
// ==================== 辅助函数：获取异常/中断原因名称 ====================
const char* trap_cause_name(uint64 cause)
{
    // 检查是中断还是异常
    if(cause & 0x8000000000000000L) {
        // 中断
        cause = cause & 0xff;
        switch(cause) {
            case IRQ_S_SOFT: return "Supervisor software interrupt";
            case IRQ_M_SOFT: return "Machine software interrupt";
            case IRQ_S_TIMER: return "Supervisor timer interrupt";
            case IRQ_M_TIMER: return "Machine timer interrupt";
            case IRQ_S_EXT: return "Supervisor external interrupt";
            case IRQ_M_EXT: return "Machine external interrupt";
            default: return "Unknown interrupt";
        }
    } else {
        // 异常
        switch(cause) {
            case CAUSE_MISALIGNED_FETCH: return "Instruction address misaligned";
            case CAUSE_FETCH_ACCESS: return "Instruction access fault";
            case CAUSE_ILLEGAL_INSTRUCTION: return "Illegal instruction";
            case CAUSE_BREAKPOINT: return "Breakpoint";
            case CAUSE_MISALIGNED_LOAD: return "Load address misaligned";
            case CAUSE_LOAD_ACCESS: return "Load access fault";
            case CAUSE_MISALIGNED_STORE: return "Store address misaligned";
            case CAUSE_STORE_ACCESS: return "Store access fault";
            case CAUSE_USER_ECALL: return "Environment call from U-mode";
            case CAUSE_SUPERVISOR_ECALL: return "Environment call from S-mode";
            case CAUSE_MACHINE_ECALL: return "Environment call from M-mode";
            case CAUSE_FETCH_PAGE_FAULT: return "Instruction page fault";
            case CAUSE_LOAD_PAGE_FAULT: return "Load page fault";
            case CAUSE_STORE_PAGE_FAULT: return "Store page fault";
            default: return "Unknown exception";
        }
    }
}

// ==================== 打印trapframe内容（调试用） ====================
void dump_trapframe(struct trapframe *tf)
{
    printf("=== Trapframe Dump ===\n");
    printf("ra:  %p  sp:  %p  gp:  %p  tp:  %p\n",
           (void*)tf->ra, (void*)tf->sp, (void*)tf->gp, (void*)tf->tp);
    printf("t0:  %p  t1:  %p  t2:  %p\n",
           (void*)tf->t0, (void*)tf->t1, (void*)tf->t2);
    printf("s0:  %p  s1:  %p\n",
           (void*)tf->s0, (void*)tf->s1);
    printf("a0:  %p  a1:  %p  a2:  %p  a3:  %p\n",
           (void*)tf->a0, (void*)tf->a1, (void*)tf->a2, (void*)tf->a3);
    printf("a4:  %p  a5:  %p  a6:  %p  a7:  %p\n",
           (void*)tf->a4, (void*)tf->a5, (void*)tf->a6, (void*)tf->a7);
    printf("sepc: %p  sstatus: %p\n",
           (void*)tf->sepc, (void*)tf->sstatus);
    printf("===================\n");
}

// ==================== 中断统计信息 ====================
void print_trap_stats(void)
{
    printf("\n=== Trap Statistics ===\n");
    printf("Timer interrupts:    %d\n", (int)interrupt_counts[IRQ_S_TIMER]);
    printf("Software interrupts: %d\n", (int)interrupt_counts[IRQ_S_SOFT]);
    printf("External interrupts: %d\n", (int)interrupt_counts[IRQ_S_EXT]);
    printf("Exceptions:          %d\n", (int)exception_count);
    printf("====================\n");
}