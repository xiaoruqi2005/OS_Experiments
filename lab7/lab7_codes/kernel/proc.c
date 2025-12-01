/* kernel/proc.c - 进程管理与调度（调试版）*/

#include "types.h"
#include "defs.h"
#include "proc.h"
#include "mm.h"
#include "riscv.h"
#include "trap.h"

// ==================== 全局数据结构 ====================
struct proc proc[NPROC];
struct cpu cpus[1];

static int nextpid = 1;

static char state_names[7][16] = {
    "UNUSED",
    "USED",
    "RUNNABLE",
    "RUNNING",
    "SLEEPING",
    "ZOMBIE",
    "UNKNOWN"
};

static uint64 total_switches = 0;

// ==================== forkret - 第一次返回用户态 ====================
void forkret(void)
{
    // ⭐ 调试：先测试是否能执行到这里
    // 使用最原始的方式：直接写UART
    volatile char *uart = (volatile char*)0x10000000;
    uart[0] = 'F';  // F = Forkret
    uart[0] = 'O';
    uart[0] = 'R';
    uart[0] = 'K';
    uart[0] = '\n';
    
    printf("[forkret] Called! PID=%d\n", myproc()->pid);
    
    // 测试：先不调用 usertrapret，看能否执行到这里
    printf("[forkret] About to call usertrapret\n");
    
    usertrapret();
    
    printf("[forkret] ERROR: Should not reach here!\n");
    for(;;);
}

// ==================== 初始化进程系统 ====================
void procinit(void)
{
    printf("Initializing process system...\n");
    printf("NPROC = %d\n", NPROC);
    
    // ⭐ 使用 memset 代替循环，快得多
    memset(proc, 0, sizeof(proc));
    
    // 显式设置所有进程为 UNUSED
    for(int i = 0; i < NPROC; i++) {
        proc[i].state = UNUSED;
    }
    
    // 初始化 CPU
    cpus[0].proc = 0;
    cpus[0].noff = 0;
    cpus[0].intena = 0;
    
    total_switches = 0;
    
    printf("Process system initialized (max %d processes)\n", NPROC);
}

// ==================== 获取当前CPU ====================
struct cpu* mycpu(void)
{
    return &cpus[0];
}

// ==================== 获取当前进程 ====================
struct proc* myproc(void)
{
    push_off();
    struct cpu *c = mycpu();
    struct proc *p = c->proc;
    pop_off();
    return p;
}

// ==================== 分配进程结构 ====================
struct proc* alloc_proc(void)
{
    struct proc *p;
    
    for(p = proc; p < &proc[NPROC]; p++) {
        if(p->state == UNUSED) {
            goto found;
        }
    }
    return 0;
    
found:
    p->pid = nextpid++;
    p->state = USED;
    
    p->kstack = (uint64)alloc_page();
    if(p->kstack == 0) {
        p->state = UNUSED;
        return 0;
    }
    
    p->trapframe = (struct trapframe*)alloc_page();
    if(p->trapframe == 0) {
        free_page((void*)p->kstack);
        p->kstack = 0;
        p->state = UNUSED;
        return 0;
    }
    memset(p->trapframe, 0, sizeof(struct trapframe));
    
    memset(&p->context, 0, sizeof(p->context));
    p->parent = 0;
    p->xstate = 0;
    p->killed = 0;
    p->chan = 0;
    p->run_time = 0;
    p->create_time = get_ticks();
    p->pagetable = 0;
    
    return p;
}

// ==================== 释放进程资源 ====================
void free_proc(struct proc *p)
{
    if(p->kstack) {
        free_page((void*)p->kstack);
        p->kstack = 0;
    }
    
    if(p->trapframe) {
        free_page((void*)p->trapframe);
        p->trapframe = 0;
    }
    
    p->pid = 0;
    p->parent = 0;
    p->name[0] = 0;
    p->killed = 0;
    p->xstate = 0;
    p->state = UNUSED;
}

// ==================== 创建内核线程 ====================
int kthread_create(void (*fn)(void), char *name)
{
    struct proc *p = alloc_proc();
    if(p == 0) {
        return -1;
    }
    
    int i;
    for(i = 0; name[i] && i < 15; i++) {
        p->name[i] = name[i];
    }
    p->name[i] = 0;
    
    memset(&p->context, 0, sizeof(p->context));
    p->context.ra = (uint64)fn;
    p->context.sp = p->kstack + KSTACK_SIZE;
    
    p->state = RUNNABLE;
    
    printf("Created kernel thread: PID=%d, name=%s\n", p->pid, p->name);
    
    return p->pid;
}

// ==================== 中断控制 ====================
void push_off(void)
{
    int old = r_sstatus() & SSTATUS_SIE;
    w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    
    struct cpu *c = &cpus[0];
    if(c->noff == 0) {
        c->intena = old;
    }
    c->noff += 1;
}

void pop_off(void)
{
    struct cpu *c = &cpus[0];
    
    if((r_sstatus() & SSTATUS_SIE) != 0) {
        panic("pop_off: interruptible");
    }
    if(c->noff < 1) {
        panic("pop_off");
    }
    
    c->noff -= 1;
    if(c->noff == 0 && c->intena) {
        w_sstatus(r_sstatus() | SSTATUS_SIE);
    }
}

// ==================== 主动放弃CPU ====================
void yield(void)
{
    struct proc *p = myproc();
    if(p == 0) return;
    
    w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    
    p->state = RUNNABLE;
    sched();
}

// ==================== 切换到调度器 ====================
void sched(void)
{
    struct proc *p = myproc();
    struct cpu *c = mycpu();
    
    int intena = c->intena;
    total_switches++;
    swtch(&p->context, &c->context);
    c->intena = intena;
}

// ==================== 调度器主循环（带调试）====================
void scheduler(void)
{
    struct proc *p;
    struct cpu *c = mycpu();
    
    printf("Scheduler started\n");
    
    // ⭐ 调试：先检查是否有 RUNNABLE 进程
    printf("[DEBUG] Checking for runnable processes...\n");
    int count = 0;
    for(p = proc; p < &proc[NPROC]; p++) {
        if(p->state != UNUSED) {
            printf("[DEBUG] Process %d: state=%d (%s)\n", 
                   p->pid, p->state, state_names[p->state]);
            count++;
        }
    }
    printf("[DEBUG] Total %d processes\n", count);
    
    c->proc = 0;
    
    int loop_count = 0;
    for(;;) {
        // ⭐ 调试：记录循环次数
        loop_count++;
        if(loop_count <= 5) {
            printf("[DEBUG] Scheduler loop #%d\n", loop_count);
        }
        
        w_sstatus(r_sstatus() | SSTATUS_SIE);
        
        int has_runnable = 0;
        for(p = proc; p < &proc[NPROC]; p++) {
            if(p->state == RUNNABLE || p->state == RUNNING || p->state == SLEEPING) {
                has_runnable = 1;
                break;
            }
        }
        
        if(!has_runnable) {
            printf("\n=== All Processes Completed ===\n");
            for(;;) {
                w_sstatus(r_sstatus() | SSTATUS_SIE);
                asm volatile("wfi");
            }
        }
        
        for(p = proc; p < &proc[NPROC]; p++) {
            if(p->state != RUNNABLE) {
                continue;
            }
            
            // ⭐ 找到 RUNNABLE 进程
            if(loop_count <= 3) {
                printf("[DEBUG] Found RUNNABLE process: PID=%d, name=%s\n", 
                       p->pid, p->name);
                printf("[DEBUG] context.ra=%p, context.sp=%p\n",
                       (void*)p->context.ra, (void*)p->context.sp);
            }
            
            w_sstatus(r_sstatus() & ~SSTATUS_SIE);
            
            p->state = RUNNING;
            c->proc = p;
            
            if(loop_count <= 3) {
                printf("[DEBUG] About to call swtch...\n");
            }
            
            swtch(&c->context, &p->context);
            
            if(loop_count <= 3) {
                printf("[DEBUG] Returned from swtch\n");
            }
            
            c->proc = 0;
        }
    }
}

// ==================== 睡眠等待 ====================
void sleep(void *chan)
{
    struct proc *p = myproc();
    if(p == 0) {
        panic("sleep: no process");
    }
    
    w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    
    p->chan = chan;
    p->state = SLEEPING;
    
    sched();
    
    p->chan = 0;
}

// ==================== 唤醒等待进程 ====================
void wakeup(void *chan)
{
    struct proc *p;
    
    for(p = proc; p < &proc[NPROC]; p++) {
        if(p->state == SLEEPING && p->chan == chan) {
            p->state = RUNNABLE;
        }
    }
}

// ==================== 进程退出 ====================
void exit_proc(int status)
{
    struct proc *p = myproc();
    if(p == 0) {
        panic("exit: no process");
    }
    
    printf("Process %d (%s) exiting with status %d\n", 
           p->pid, p->name, status);
    
    w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    
    p->xstate = status;
    p->state = ZOMBIE;
    
    if(p->parent) {
        wakeup(p->parent);
    }
    
    sched();
    panic("zombie exit");
}

// ==================== 等待子进程 ====================
int wait_proc(int *status)
{
    struct proc *np;
    int havekids, pid;
    struct proc *p = myproc();
    
    for(;;) {
        havekids = 0;
        for(np = proc; np < &proc[NPROC]; np++) {
            if(np->parent == p) {
                havekids = 1;
                if(np->state == ZOMBIE) {
                    pid = np->pid;
                    if(status != 0) {
                        *status = np->xstate;
                    }
                    free_proc(np);
                    return pid;
                }
            }
        }
        
        if(!havekids) {
            return -1;
        }
        
        sleep(p);
    }
}

// ==================== 创建第一个用户进程 ====================
extern uint8 initcode[];
extern uint32 initcode_size;

int userinit(void)
{
    struct proc *p;
    
    p = alloc_proc();
    if(p == 0)
        panic("userinit: no proc");
    
    for(int i = 0; "initcode"[i]; i++)
        p->name[i] = "initcode"[i];
    
    p->pagetable = proc_pagetable(p);
    if(p->pagetable == 0) {
        free_proc(p);
        panic("userinit: proc_pagetable");
    }
    
    // 分配代码页
    void *code_page = alloc_page();
    if(code_page == 0) {
        proc_freepagetable(p->pagetable, 0);
        free_proc(p);
        panic("userinit: alloc code page");
    }
    
    printf("[DEBUG] code_page phys addr: %p\n", code_page);
    printf("[DEBUG] initcode_size: %d bytes\n", initcode_size);
    
    memset(code_page, 0, PGSIZE);
    memcpy(code_page, initcode, initcode_size);
    
    // ⭐ 打印代码内容
    printf("[DEBUG] First 32 bytes of initcode:\n");
    for(int i = 0; i < 32 && i < initcode_size; i++) {
        printf("%02x ", ((uint8*)code_page)[i]);
        if((i+1) % 16 == 0) printf("\n");
    }
    if(initcode_size % 16 != 0) printf("\n");
    
    // 映射代码页
    printf("[DEBUG] Mapping code page: va=0x0, pa=%p, perm=RWXU\n", code_page);
    if(map_page(p->pagetable, 0, (uint64)code_page, 
                PTE_R | PTE_W | PTE_X | PTE_U) != 0) {
        free_page(code_page);
        proc_freepagetable(p->pagetable, 0);
        free_proc(p);
        panic("userinit: map code page");
    }
    
    // ⭐ 验证映射
    pte_t *pte = walk_lookup(p->pagetable, 0);
    if(pte == 0 || (*pte & PTE_V) == 0) {
        panic("userinit: code page not mapped!");
    }
    printf("[DEBUG] Code page PTE: %p (flags: %s%s%s%s%s)\n",
           (void*)*pte,
           (*pte & PTE_V) ? "V" : "-",
           (*pte & PTE_R) ? "R" : "-",
           (*pte & PTE_W) ? "W" : "-",
           (*pte & PTE_X) ? "X" : "-",
           (*pte & PTE_U) ? "U" : "-");
    
    // 分配栈页
    void *stack_page = alloc_page();
    if(stack_page == 0) {
        proc_freepagetable(p->pagetable, PGSIZE);
        free_proc(p);
        panic("userinit: alloc stack page");
    }
    memset(stack_page, 0, PGSIZE);
    
    if(map_page(p->pagetable, USTACK, (uint64)stack_page,
                PTE_R | PTE_W | PTE_U) != 0) {
        free_page(stack_page);
        proc_freepagetable(p->pagetable, PGSIZE);
        free_proc(p);
        panic("userinit: map stack page");
    }
    
    // 设置 trapframe
    memset(p->trapframe, 0, sizeof(struct trapframe));
    p->trapframe->sepc = 0;
    p->trapframe->sp = USTACKTOP;
    
    printf("[DEBUG] trapframe->sepc = %p\n", (void*)p->trapframe->sepc);
    printf("[DEBUG] trapframe->sp = %p\n", (void*)p->trapframe->sp);
    
    p->trapframe->sstatus = r_sstatus();
    p->trapframe->sstatus &= ~SSTATUS_SPP;
    p->trapframe->sstatus |= SSTATUS_SPIE;
    
    extern pagetable_t kernel_pagetable;
    p->trapframe->kernel_satp = MAKE_SATP(kernel_pagetable);
    p->trapframe->kernel_sp = p->kstack + KSTACK_SIZE;
    p->trapframe->kernel_trap = (uint64)usertrap;
    
    p->context.ra = (uint64)forkret;
    p->context.sp = p->kstack + KSTACK_SIZE;
    
    p->state = RUNNABLE;
    
    printf("Created first user process: PID=%d\n", p->pid);
    
    return p->pid;
}

// ==================== 辅助函数 ====================
void proc_info(void) { /* ... */ }
void proc_stats(void) { /* ... */ }
const char* state_name(enum procstate s)
{
    if(s >= 0 && s <= 5) {
        return state_names[s];
    }
    return state_names[6];
}