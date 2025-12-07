// kernel/trap.c
#include "defs.h"
#include "riscv.h"
#include "syscall.h"
#include "proc.h" 

extern void kernelvec();
extern void restore_trapframe(struct trapframe *tf); 

static volatile uint64 tick_counter = 0;

static inline void sbi_set_timer(uint64 stime) {
    register uint64 a7 asm("a7") = 0;
    register uint64 a6 asm("a6") = 0;
    register uint64 a0 asm("a0") = stime;
    asm volatile("ecall" : "+r"(a0) : "r"(a6), "r"(a7) : "memory");
}

void trap_init(void) {
    w_stvec((uint64)kernelvec);
}

void clock_init(void) {
    uint64 next_timer = r_time() + 100000;
    sbi_set_timer(next_timer);
    w_sie(r_sie() | SIE_STIE);
}

uint64 get_time(void) { return r_time(); }

void fork_ret() {
    struct proc *p = myproc();
    release(&p->lock); 
    restore_trapframe(p->trapframe);
}

void kerneltrap(uint64 sp_val) {
    uint64 scause = r_scause();
    uint64 sepc = r_sepc();
    uint64 sstatus = r_sstatus();
    uint64 stval = r_stval();

    struct proc *p = myproc();
    
    // 防御性检查：确保 p 和 p->trapframe 有效
    if (p != 0 && p->trapframe != 0) {
        p->trapframe->epc = sepc;
    }

    if (scause == 8) { // System Call
        if(p && p->trapframe) p->trapframe->epc += 4;
        intr_on();
        syscall();
        intr_off();
    } 
    else if (scause == 15) { // Store/AMO Page Fault (COW)
        if (p != 0 && p->pagetable != 0) {
            if (cow_alloc(p->pagetable, stval) == 0) {
                // COW handled
            } else {
                printf("kerneltrap: cow_alloc failed for va %p, killing pid %d\n", stval, p->pid);
                if(p) exit(-1);
            }
        } else {
            // 如果在没有进程上下文的情况下发生 Page Fault，这就是真正的 Panic
            printf("kerneltrap: Fatal Page Fault at %p without process context\n", stval);
            printf("scause=%p sepc=%p\n", scause, sepc);
            while(1);
        }
    }
    else if ((scause & 0x8000000000000000L) && (scause & 0xff) == 5) { // Timer
        uint64 next_timer = r_time() + 100000;
        sbi_set_timer(next_timer);
        if (p != 0 && p->state == RUNNING) yield();
    }
    else {
        printf("kerneltrap: unhandled exception scause %p, sepc %p, stval %p\n", scause, sepc, stval);
        // 如果是 p->trapframe 为空导致的故障，这里会打印出来
        while(1);
    }

    if (p && p->killed) {
        exit(-1);
    }
    
    w_sstatus(sstatus);
    if (p && p->trapframe) w_sepc(p->trapframe->epc);
    else w_sepc(sepc); // 回退到使用局部 sepc，如果 p 无效
}
