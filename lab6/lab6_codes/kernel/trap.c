/* kernel/trap.c - 中断和异常处理（实验6版本 - 支持用户态）*/

#include "types.h"
#include "defs.h"
#include "riscv.h"
#include "trap.h"
#include "printf.h"
#include "proc.h"

// ==================== 中断统计 ====================
static uint64 interrupt_counts[16] = {0};
static uint64 exception_count = 0;

static interrupt_handler_t interrupt_handlers[16] = {0};

// ==================== 初始化中断系统 ====================
void trap_init(void)
{
    printf("Initializing trap system...\n");
    
    for(int i = 0; i < 16; i++) {
        interrupt_handlers[i] = 0;
        interrupt_counts[i] = 0;
    }
    
    // 设置内核态陷阱向量
    w_stvec((uint64)kernelvec);
    
    printf("Set stvec to %p\n", (void*)kernelvec);
    
    // 使能中断
    w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
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
static int devintr(void)
{
    uint64 scause = r_scause();
    
    if((scause & 0x8000000000000000L) == 0) {
        return 0;  // 不是中断
    }
    
    scause = scause & 0xff;
    
    if(scause == IRQ_S_TIMER) {
        interrupt_counts[IRQ_S_TIMER]++;
        
        if(interrupt_handlers[IRQ_S_TIMER]) {
            interrupt_handlers[IRQ_S_TIMER]();
        }
        
        return 1;
        
    } else if(scause == IRQ_S_SOFT) {
        interrupt_counts[IRQ_S_SOFT]++;
        
        w_sip(r_sip() & ~2);
        
        if(interrupt_handlers[IRQ_S_TIMER]) {
            interrupt_handlers[IRQ_S_TIMER]();
            interrupt_counts[IRQ_S_TIMER]++;
        }
        
        return 1;
        
    } else if(scause == IRQ_S_EXT) {
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
    struct proc *p = myproc();
    if(p == 0) {
        panic("handle_syscall: no process");
    }
    
    // 将中断栈的 trapframe 复制到进程的 trapframe
    if(p->trapframe) {
        *p->trapframe = *tf;
    }
    
    // 调用系统调用分发器
    extern void syscall(struct trapframe *tf);
    syscall(p->trapframe);
    
    // 将修改后的 trapframe 复制回中断栈
    if(p->trapframe) {
        *tf = *p->trapframe;
    }
}

// ==================== 指令页故障处理 ====================
void handle_instruction_page_fault(struct trapframe *tf) {
    uint64 fault_addr = r_stval();
    
    printf("\n=== Instruction Page Fault ===\n");
    printf("Fault address: %p\n", (void*)fault_addr);
    printf("PC: %p\n", (void*)tf->sepc);
    
    if(fault_addr >= KERNBASE) {
        panic("Instruction page fault in kernel space");
    }
    
    printf("TODO: Implement demand paging for instruction fault\n");
    panic("Instruction page fault not handled");
}

// ==================== 加载页故障处理 ====================
void handle_load_page_fault(struct trapframe *tf) {
    uint64 fault_addr = r_stval();
    
    printf("\n=== Load Page Fault ===\n");
    printf("Fault address: %p\n", (void*)fault_addr);
    printf("PC: %p\n", (void*)tf->sepc);
    printf("Tried to read from unmapped address\n");
    
    panic("Load page fault");
}

// ==================== 存储页故障处理 ====================
void handle_store_page_fault(struct trapframe *tf) {
    uint64 fault_addr = r_stval();
    
    printf("\n=== Store Page Fault ===\n");
    printf("Fault address: %p\n", (void*)fault_addr);
    printf("PC: %p\n", (void*)tf->sepc);
    printf("Tried to write to unmapped or read-only address\n");
    
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
        case CAUSE_USER_ECALL:
        case CAUSE_SUPERVISOR_ECALL:
            handle_syscall(tf);
            break;
            
        case CAUSE_FETCH_PAGE_FAULT:
            handle_instruction_page_fault(tf);
            break;
            
        case CAUSE_LOAD_PAGE_FAULT:
            handle_load_page_fault(tf);
            break;
            
        case CAUSE_STORE_PAGE_FAULT:
            handle_store_page_fault(tf);
            break;
            
        case CAUSE_ILLEGAL_INSTRUCTION:
            printf("\n=== Illegal Instruction ===\n");
            printf("PC: %p\n", (void*)tf->sepc);
            printf("Instruction value: %p\n", (void*)r_stval());
            panic("Illegal instruction");
            break;
            
        case CAUSE_BREAKPOINT:
            printf("\n=== Breakpoint ===\n");
            printf("PC: %p\n", (void*)tf->sepc);
            tf->sepc += 2;
            printf("Breakpoint handled, continuing from %p\n", (void*)tf->sepc);
            break;
            
        case CAUSE_MISALIGNED_FETCH:
            printf("\n=== Misaligned Instruction Fetch ===\n");
            printf("Address: %p\n", (void*)r_stval());
            panic("Misaligned instruction fetch");
            break;
            
        case CAUSE_MISALIGNED_LOAD:
            printf("\n=== Misaligned Load ===\n");
            printf("Address: %p\n", (void*)r_stval());
            panic("Misaligned load");
            break;
            
        case CAUSE_MISALIGNED_STORE:
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
void kerneltrap(struct trapframe *tf)
{
    uint64 sstatus = r_sstatus();
    
    if((sstatus & SSTATUS_SPP) == 0) {
        panic("kerneltrap: not from supervisor mode");
    }
    
    if(sstatus & SSTATUS_SIE) {
        panic("kerneltrap: interrupts enabled");
    }
    
    int is_device_interrupt = devintr();
    
    if(!is_device_interrupt) {
        exception_count++;
        handle_exception(tf);
    }
    
    w_sstatus(sstatus);
}

// ==================== 用户态陷阱处理 ====================

// 处理来自用户态的陷阱
void usertrap(void)
{
    // ⭐ 第一时间输出，证明进入了 usertrap
    volatile char *uart = (volatile char*)0x10000000;
    uart[0] = '\n';
    uart[0] = 'U'; uart[0] = 'S'; uart[0] = 'E'; uart[0] = 'R';
    uart[0] = 'T'; uart[0] = 'R'; uart[0] = 'A'; uart[0] = 'P';
    uart[0] = '!'; uart[0] = '\n';
    
    struct proc *p = myproc();
    
    // 保存 sepc
    p->trapframe->sepc = r_sepc();
    
    uint64 cause = r_scause();
    
    uart[0] = 'C'; uart[0] = 'A'; uart[0] = 'U'; uart[0] = 'S'; 
    uart[0] = 'E'; uart[0] = '=';
    // 输出 cause 的十六进制
    uint64 val = cause;
    for(int i = 60; i >= 0; i -= 4) {
        int digit = (val >> i) & 0xf;
        uart[0] = digit < 10 ? '0' + digit : 'a' + digit - 10;
    }
    uart[0] = '\n';
    
    if(cause == 8) {  // 用户态 ecall
        uart[0] = 'E'; uart[0] = 'C'; uart[0] = 'A'; uart[0] = 'L'; 
        uart[0] = 'L'; uart[0] = '\n';
        
        p->trapframe->sepc += 4;
        
        // 调用系统调用处理
        syscall(p->trapframe);
        
        uart[0] = 'D'; uart[0] = 'O'; uart[0] = 'N'; uart[0] = 'E';
        uart[0] = '\n';
    } else {
        uart[0] = 'E'; uart[0] = 'R'; uart[0] = 'R'; uart[0] = '!';
        uart[0] = '\n';
        
        printf("[usertrap] Unexpected trap from PID %d\n", p->pid);
        printf("  scause: %p\n", (void*)cause);
        printf("  sepc:   %p\n", (void*)r_sepc());
        printf("  stval:  %p\n", (void*)r_stval());
        
        exit_proc(-1);
    }
    
    uart[0] = 'R'; uart[0] = 'E'; uart[0] = 'T'; uart[0] = '\n';
    usertrapret();
}

// 返回用户态
void usertrapret(void)
{
    // ⭐ 原始 UART 输出调试
    volatile char *uart = (volatile char*)0x10000000;
    uart[0] = 'U'; uart[0] = 'S'; uart[0] = 'E'; uart[0] = 'R';
    uart[0] = 'T'; uart[0] = 'R'; uart[0] = 'A'; uart[0] = 'P';
    uart[0] = 'R'; uart[0] = 'E'; uart[0] = 'T'; uart[0] = '\n';
    
    struct proc *p = myproc();
    
    uart[0] = '1'; uart[0] = '\n';
    
    w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    
    uart[0] = '2'; uart[0] = '\n';
    
    // ⭐ 不需要再声明，已经在 defs.h 中
    uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    w_stvec(trampoline_uservec);
    
    uart[0] = '3'; uart[0] = '\n';
    
    p->trapframe->kernel_satp = r_satp();
    p->trapframe->kernel_sp = p->kstack + KSTACK_SIZE;
    p->trapframe->kernel_trap = (uint64)usertrap;
    
    uart[0] = '4'; uart[0] = '\n';
    
    uint64 x = r_sstatus();
    x &= ~SSTATUS_SPP;
    x |= SSTATUS_SPIE;
    w_sstatus(x);
    
    uart[0] = '5'; uart[0] = '\n';
    
    w_sepc(p->trapframe->sepc);
    
    uart[0] = '6'; uart[0] = '\n';
    
    uint64 satp = MAKE_SATP(p->pagetable);
    
    uart[0] = '7'; uart[0] = '\n';
    
    // ⭐ 不需要再声明
    uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    
    uart[0] = '8'; uart[0] = '\n';
    
    ((void(*)(uint64,uint64))trampoline_userret)(TRAPFRAME, satp);
    
    uart[0] = 'X'; uart[0] = '\n';
}

// ==================== 辅助函数 ====================
const char* trap_cause_name(uint64 cause)
{
    if(cause & 0x8000000000000000L) {
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

void print_trap_stats(void)
{
    printf("\n=== Trap Statistics ===\n");
    printf("Timer interrupts:    %d\n", (int)interrupt_counts[IRQ_S_TIMER]);
    printf("Software interrupts: %d\n", (int)interrupt_counts[IRQ_S_SOFT]);
    printf("External interrupts: %d\n", (int)interrupt_counts[IRQ_S_EXT]);
    printf("Exceptions:          %d\n", (int)exception_count);
    printf("====================\n");
}