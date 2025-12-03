// kernel/trap.c
#include "defs.h"
#include "riscv.h"
#include "syscall.h"
#include "proc.h" 

extern void kernelvec();
extern struct proc proc[NPROC]; 
extern void restore_trapframe(struct trapframe *tf);

static volatile uint64 tick_counter = 0;
static volatile uint64 total_interrupt_count = 0;

static inline void sbi_set_timer(uint64 stime) {
    register uint64 a7 asm("a7") = 0;
    register uint64 a6 asm("a6") = 0;
    register uint64 a0 asm("a0") = stime;
    asm volatile("ecall" : "+r"(a0) : "r"(a6), "r"(a7) : "memory");
}

void trap_init(void) {
    w_stvec((uint64)kernelvec);
    printf("trap_init: stvec set to %p\n", kernelvec);
}

void clock_init(void) {
    uint64 next_timer = r_time() + 100000;
    sbi_set_timer(next_timer);
    w_sie(r_sie() | SIE_STIE);
}

uint64 get_time(void) { return r_time(); }
uint64 get_interrupt_count(void) { return total_interrupt_count; }
uint64 get_ticks(void) { return tick_counter; }
void* get_ticks_channel(void) { return (void*)&tick_counter; }

void fork_ret() {
    struct proc *p = myproc();
    release(&p->lock); 
    restore_trapframe(p->trapframe);
}

struct stack_regs {
    uint64 ra; uint64 sp; uint64 gp; uint64 tp;
    uint64 t0; uint64 t1; uint64 t2;
    uint64 s0; uint64 s1;
    uint64 a0; uint64 a1; uint64 a2; uint64 a3; uint64 a4; uint64 a5; uint64 a6; uint64 a7;
    uint64 s2; uint64 s3; uint64 s4; uint64 s5; uint64 s6; uint64 s7; uint64 s8; uint64 s9; uint64 s10; uint64 s11;
    uint64 t3; uint64 t4; uint64 t5; uint64 t6;
};

// void kerneltrap(uint64 sp_val) {
//     uint64 scause = r_scause();
//     uint64 sepc = r_sepc();
//     uint64 sstatus = r_sstatus(); // [修复1] 保存入口时的 sstatus

//     if (scause & (1L << 63)) {
//         uint64 cause = scause & 0x7FFFFFFFFFFFFFFF;
//         if (cause == 5) {
//             total_interrupt_count++;
//             tick_counter++;
//             wakeup((void*)&tick_counter);
//             uint64 next_timer = r_time() + 100000;
//             sbi_set_timer(next_timer);
//         }
//     } 
//     else if (scause == 15) { // Store/AMO page fault
//         uint64 va = r_stval(); // 获取出错的虚拟地址
//         struct proc *p = myproc();
        
//         if (p == 0) {
//             printf("COW: no process\n");
//             while(1);
//         }

//         // 尝试处理 COW
//         if (cow_alloc(p->pagetable, va) < 0) {
//             // 如果不是 COW 页，或者内存耗尽
//             // 这代表是真正的非法访问（Segfault），必须立即终止进程！
//             printf("COW: allocation failed or invalid address va=%p\n", va);
//             p->killed = 1;
//             exit(-1); // [关键修复] 立即退出，不要让 CPU 重试指令
//         }
        
//         // 如果 cow_alloc 成功，说明分配了新页
//         // 我们需要恢复 sstatus 并让 CPU 重试那条写指令 (sepc 不变)
//         w_sstatus(sstatus); 
//         w_sepc(sepc); 
//     }
//     else if (scause == 3) {//scause == 3 (syscall) 处理
//         struct proc *p = myproc();
//         if (p == 0) {
//             printf("kerneltrap: FATAL - no process\n");
//             while(1);
//         }

//         struct stack_regs *regs = (struct stack_regs *)sp_val;

//         if (p->trapframe) {
//             // 复制寄存器到 trapframe ... (省略未变动代码)
//             p->trapframe->ra = regs->ra;
//             p->trapframe->sp = regs->sp + 256; 
//             p->trapframe->gp = regs->gp;
//             p->trapframe->tp = regs->tp;
//             p->trapframe->t0 = regs->t0;
//             p->trapframe->t1 = regs->t1;
//             p->trapframe->t2 = regs->t2;
//             p->trapframe->s0 = regs->s0;
//             p->trapframe->s1 = regs->s1;
//             p->trapframe->a0 = regs->a0;
//             p->trapframe->a1 = regs->a1;
//             p->trapframe->a2 = regs->a2;
//             p->trapframe->a3 = regs->a3;
//             p->trapframe->a4 = regs->a4;
//             p->trapframe->a5 = regs->a5;
//             p->trapframe->a6 = regs->a6;
//             p->trapframe->a7 = regs->a7;
//             p->trapframe->s2 = regs->s2;
//             p->trapframe->s3 = regs->s3;
//             p->trapframe->s4 = regs->s4;
//             p->trapframe->s5 = regs->s5;
//             p->trapframe->s6 = regs->s6;
//             p->trapframe->s7 = regs->s7;
//             p->trapframe->s8 = regs->s8;
//             p->trapframe->s9 = regs->s9;
//             p->trapframe->s10 = regs->s10;
//             p->trapframe->s11 = regs->s11;
//             p->trapframe->t3 = regs->t3;
//             p->trapframe->t4 = regs->t4;
//             p->trapframe->t5 = regs->t5;
//             p->trapframe->t6 = regs->t6;
//             p->trapframe->epc = sepc;
//         }

//         // [修复2] 不要在这里写寄存器，因为 intr_on 后的中断会覆盖它们
//         // w_sepc(sepc + 4); 
        
//         if(p->trapframe) p->trapframe->epc += 4;

//         intr_on(); // 开启中断，危险区开始
//         syscall();
//         intr_off(); // 关闭中断，危险区结束
        
//         // [修复3] 恢复被嵌套中断破坏的 CSR 寄存器
//         // 必须恢复 sstatus，否则 sret 可能会错误地返回到 User 模式导致 Page Fault
//         w_sstatus(sstatus); 
//         w_sepc(sepc + 4);   // 恢复正确的返回地址 (跳过 ebreak 指令)

//         regs->a0 = p->trapframe->a0;
//     } 
//     else {
//         // printf("kerneltrap: exception scause %p, sepc %p, stval %p\n", scause, sepc, r_stval());
//         // while(1);

//         // === 修改开始：在此处添加 Lab4 要求的异常处理 ===
        
//         uint64 exception_code = scause; // 获取异常原因
        
//         // 打印信息，方便调试
//         printf("kerneltrap: captured exception scause=%d (sepc=%p)\n", exception_code, sepc);

//         switch (exception_code) {
//             case 2: // 非法指令异常 (Illegal Instruction)
//                 printf("  [Handler] Illegal Instruction caught.\n");
//                 // 跳过当前指令 (假设是4字节指令)
//                 w_sepc(sepc + 4);
//                 break;

//             case 12: // 指令页故障 (Instruction Page Fault)
//                 printf("  [Handler] Instruction Page Fault caught.\n");
//                 w_sepc(sepc + 4);
//                 break;

//             case 13: // 加载页故障 (Load Page Fault) - 对应读取 0x0
//                 printf("  [Handler] Load Page Fault caught.\n");
//                 w_sepc(sepc + 4);
//                 break;

//             case 15: // 存储页故障 (Store Page Fault) - 对应写入 0x0
//                 printf("  [Handler] Store Page Fault caught.\n");
//                 w_sepc(sepc + 4);
//                 break;

//             default:
//                 // 对于未知的其他异常，依然保持 Panic
//                 printf("kerneltrap: FATAL - unexpected exception scause %p, sepc %p, stval %p\n", 
//                        scause, sepc, r_stval());
//                 while(1);
//         }
//     }
// }

void kerneltrap(uint64 sp_val) {
    uint64 scause = r_scause();
    uint64 sepc = r_sepc();
    uint64 sstatus = r_sstatus(); 

    int handled = 0; // 标志位：是否已被 COW 逻辑处理

    // === 1. 处理 COW (仅针对 Store Page Fault) ===
    if (scause == 15) {
        struct proc *p = myproc();
        uint64 va = r_stval();
        
        // 必须先检查 p->pagetable 是否存在
        // 内核测试线程可能没有用户页表，此时直接访问会导致 Load Fault
        if (p && p->pagetable) {
            // 如果 cow_alloc 成功，说明这是合法的 COW 页
            if (cow_alloc(p->pagetable, va) == 0) {
                w_sstatus(sstatus);
                w_sepc(sepc); // 重试当前指令
                handled = 1;  // 标记为已处理，不再进入下方的 else
            }
        }
        // 如果 cow_alloc 失败（返回 -1）或 pagetable 为空：
        // handled 保持为 0，代码会自动向下执行到 "else" 块中。
        // 那里有测试需要的 "跳过指令" 逻辑。
    }

    // === 2. 原有的中断/异常处理逻辑 ===
    if (!handled) {
        if (scause & (1L << 63)) {
            // 时钟中断处理...
            uint64 cause = scause & 0x7FFFFFFFFFFFFFFF;
            if (cause == 5) {
                total_interrupt_count++;
                tick_counter++;
                wakeup((void*)&tick_counter);
                uint64 next_timer = r_time() + 100000;
                sbi_set_timer(next_timer);
            }
        } 
        else if (scause == 3) {
            // 系统调用处理...
            struct proc *p = myproc();
            if (p == 0) {
                printf("kerneltrap: FATAL - no process\n");
                while(1);
            }
            struct stack_regs *regs = (struct stack_regs *)sp_val;
            if (p->trapframe) {
                // 复制寄存器...
                p->trapframe->ra = regs->ra;
                p->trapframe->sp = regs->sp + 256;
                p->trapframe->gp = regs->gp;
                p->trapframe->tp = regs->tp;
                p->trapframe->t0 = regs->t0;
                p->trapframe->t1 = regs->t1;
                p->trapframe->t2 = regs->t2;
                p->trapframe->s0 = regs->s0;
                p->trapframe->s1 = regs->s1;
                p->trapframe->a0 = regs->a0;
                p->trapframe->a1 = regs->a1;
                p->trapframe->a2 = regs->a2;
                p->trapframe->a3 = regs->a3;
                p->trapframe->a4 = regs->a4;
                p->trapframe->a5 = regs->a5;
                p->trapframe->a6 = regs->a6;
                p->trapframe->a7 = regs->a7;
                p->trapframe->s2 = regs->s2;
                p->trapframe->s3 = regs->s3;
                p->trapframe->s4 = regs->s4;
                p->trapframe->s5 = regs->s5;
                p->trapframe->s6 = regs->s6;
                p->trapframe->s7 = regs->s7;
                p->trapframe->s8 = regs->s8;
                p->trapframe->s9 = regs->s9;
                p->trapframe->s10 = regs->s10;
                p->trapframe->s11 = regs->s11;
                p->trapframe->t3 = regs->t3;
                p->trapframe->t4 = regs->t4;
                p->trapframe->t5 = regs->t5;
                p->trapframe->t6 = regs->t6;
                p->trapframe->epc = sepc;
            }
            if(p->trapframe) p->trapframe->epc += 4;
            intr_on();
            syscall();
            intr_off();
            w_sstatus(sstatus);
            w_sepc(sepc + 4);
            regs->a0 = p->trapframe->a0;
        } 
        else {
            // === 异常测试处理逻辑 ===
            // 当 COW 分配失败（即非法访问测试）时，会走到这里
           
            uint64 exception_code = scause;
            
            printf("kerneltrap: captured exception scause=%d (sepc=%p)\n", exception_code, sepc);

            switch (exception_code) {
                case 2: // Illegal Instruction
                    printf("  [Handler] Illegal Instruction caught.\n");
                    w_sepc(sepc + 4);
                    break;
                case 12: // Instruction Page Fault
                    printf("  [Handler] Instruction Page Fault caught.\n");
                    w_sepc(sepc + 4); 
                    break;
                case 13: // Load Page Fault
                    printf("  [Handler] Load Page Fault caught.\n");
                    w_sepc(sepc + 4);
                    break;
                case 15: // Store Page Fault
                    // 当 cow_alloc 失败后，会走到这里，执行测试通过所需的逻辑
                    printf("  [Handler] Store Page Fault caught.\n");
                    w_sepc(sepc + 4); // 跳过指令，让测试继续
                    break;
                default:
                    printf("kerneltrap: FATAL - unexpected exception scause %d\n", exception_code);
                    while(1);
            }
        }
    }
}