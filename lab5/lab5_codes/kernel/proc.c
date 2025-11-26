/* kernel/proc.c - 进程管理与调度（支持kill与子进程处理）*/

#include "types.h"
#include "defs.h"
#include "proc.h"
#include "mm.h"
#include "riscv.h"

// ==================== 全局数据结构 ====================
struct proc proc[NPROC];
struct cpu cpus[1];

static int nextpid = 1;

// ==================== 状态名称字符串数组 ====================
static char state_names[7][16] = {
    "UNUSED",
    "USED",
    "RUNNABLE",
    "RUNNING",
    "SLEEPING",
    "ZOMBIE",
    "UNKNOWN"
};

// ==================== 统计信息 ====================
static uint64 total_switches = 0;  // 总上下文切换次数

// 内部辅助函数：递归标记并唤醒子进程（用于kill/exit）
// internal helper: recursively mark and wake children of a process
static void kill_children(struct proc *parent);

// ==================== 初始化进程系统 ====================
void proc_init(void)
{
    printf("Initializing process system...\n");
    
    for(int i = 0; i < NPROC; i++) {
        proc[i].state = UNUSED;
        proc[i].pid = 0;
        proc[i].kstack = 0;
        proc[i].parent = 0;
        proc[i].name[0] = 0;
        proc[i].killed = 0;
        proc[i].pagetable = 0;
        proc[i].chan = 0;
        proc[i].xstate = 0;
        proc[i].run_time = 0;
        proc[i].create_time = 0;
    }
    
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
//分配 PCB、分配内核栈、初始化进程结构
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
    
    memset(&p->context, 0, sizeof(p->context));
    p->parent = 0;        // 当前版本：kernel thread，没有自动父进程
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
    
    p->pid = 0;
    p->parent = 0;
    p->name[0] = 0;
    p->killed = 0;
    p->xstate = 0;
    p->chan = 0;
    p->run_time = 0;
    p->create_time = 0;
    p->pagetable = 0;
    p->state = UNUSED;
}

// ==================== 创建内核线程 ====================
//调用 alloc_proc() 得到一个 PCB,设置入口函数、设置初始栈、将进程变为 RUNNABLE，让调度器能够运行它
int create_kthread(void (*fn)(void), char *name)
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

// ==================== 触发调度：主动放弃CPU ====================
void yield(void)
{
    struct proc *p = myproc();
    if(p == 0) return;

    // ★ 若当前进程已被kill标记，直接退出（不会返回）
    if(p->killed) {
        exit_proc(-1);
    }
    
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
    total_switches++;  // 统计切换次数
    swtch(&p->context, &c->context);
    c->intena = intena;
}

// ==================== 调度器主循环 ====================
//轮转调度） + 抢占式调度(Timer 中断会强制触发进程让出 CPU)
//每隔 100ms（设置的定时器间隔）中断自动发生,内核中断处理程序会要求当前进程 yield()
//yield() 会切回 scheduler

//硬件计时器在 M 模式触发中断，由 timervec.S 转换成 S 模式的软件中断，内核的 trap 系统捕获中断，
//最终调用 timer_interrupt() 进行计时并输出 uptime。所以我们看到的每秒打印，都是中断自动驱动，而不是 main 手动循环打印的。
void scheduler(void)
{
    struct proc *p;
    struct cpu *c = mycpu();
    
    printf("Scheduler started\n");
    
    c->proc = 0;
    
    for(;;) {
        // 开启中断
        w_sstatus(r_sstatus() | SSTATUS_SIE);
        
        // 检查是否所有进程都结束
        int has_runnable = 0;
        for(p = proc; p < &proc[NPROC]; p++) {
            if(p->state == RUNNABLE || p->state == RUNNING || p->state == SLEEPING) {
                has_runnable = 1;
                break;
            }
        }
        
        if(!has_runnable) {
            printf("\n=== All Processes Completed ===\n");
            printf("Total context switches: %d\n", (int)total_switches);
            printf("System will continue running (timer interrupts active)\n");
            printf("Press Ctrl+A then X to exit QEMU\n");
            
            // 继续运行，等待中断
            for(;;) {
                w_sstatus(r_sstatus() | SSTATUS_SIE);
                asm volatile("wfi");  // 等待中断
            }
        }
        
        // 遍历进程表
        for(p = proc; p < &proc[NPROC]; p++) {
            if(p->state != RUNNABLE) {
                continue;
            }
            
            // 切换前关闭中断
            w_sstatus(r_sstatus() & ~SSTATUS_SIE);
            
            p->state = RUNNING;
            c->proc = p;
            
            swtch(&c->context, &p->context);
            
            c->proc = 0;
        }
    }
}

// ==================== 睡眠等待（支持通道）====================
void sleep(void *chan)
{
    struct proc *p = myproc();
    if(p == 0) {
        panic("sleep: no process");
    }
    
    // 关闭中断，保证原子性
    w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    
    p->chan = chan;
    p->state = SLEEPING;
    
    sched();  // 切换到调度器
    
    // 被唤醒后继续执行
    p->chan = 0;

    // ★ 如果在睡眠期间被kill，醒来后立刻退出
    if(p->killed) {
        exit_proc(-1);
    }
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

// ==================== 递归标记并唤醒子进程 ====================
// 当父进程被exit/kill时，调用该函数递归处理整棵子树
static void kill_children(struct proc *parent)
{
    struct proc *p;
    
    for(p = proc; p < &proc[NPROC]; p++) {
        if(p->parent == parent && p->state != UNUSED && p->state != ZOMBIE) {
            p->killed = 1;
            // 如果子进程在睡眠，唤醒它，让它有机会检查 killed 并退出
            if(p->state == SLEEPING) {
                p->state = RUNNABLE;
            }
            // 递归处理孙子/曾孙
            kill_children(p);
        }
    }
}

// ==================== 按PID杀死进程（递归杀死子进程树）====================
int kill_proc(int pid)
{
    struct proc *p;
    int found = -1;

    push_off();  // 关闭中断，防止与调度器竞争

    for(p = proc; p < &proc[NPROC]; p++) {
        if(p->pid == pid && p->state != UNUSED) {
            // 标记本进程
            p->killed = 1;
            if(p->state == SLEEPING) {
                p->state = RUNNABLE;  // 唤醒以便尽快退出
            }

            // 递归标记所有子进程
            kill_children(p);

            found = 0;
            break;
        }
    }

    pop_off();

    return found;   // 0=成功，-1=未找到
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
    
    // 关闭中断，保证对子进程和自身状态修改的原子性
    w_sstatus(r_sstatus() & ~SSTATUS_SIE);

    // ★ 先处理所有子进程：递归标记并唤醒，让它们也能尽快退出
    kill_children(p);
    
    p->xstate = status;
    p->state = ZOMBIE;
    
    // 唤醒父进程（如果父进程在wait_proc里睡眠）
    if(p->parent) {
        wakeup(p->parent);
    }
    
    sched();
    panic("zombie exit");
}

// ==================== 等待子进程退出 ====================
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

// ==================== 打印进程信息（修复版）====================
void proc_info(void)
{
    struct proc *p;
    int count = 0;
    
    printf("\n=== Process Table ===\n");
    printf("PID  STATE      NAME            RUNTIME\n");
    printf("---  ---------  --------------  -------\n");
    
    for(p = proc; p < &proc[NPROC]; p++) {
        if(p->state != UNUSED) {
            // 打印 PID（3列宽）
            if(p->pid < 10) {
                printf("%d    ", p->pid);
            } else if(p->pid < 100) {
                printf("%d   ", p->pid);
            } else {
                printf("%d  ", p->pid);
            }
            
            // 打印状态名（11列宽）
            const char *sname = state_name(p->state);
            printf("%s", sname);
            int slen = 0;
            while(sname[slen]) slen++;
            for(int i = slen; i < 11; i++) printf(" ");
            
            // 打印进程名（16列宽）
            printf("%s", p->name);
            int nlen = 0;
            while(p->name[nlen]) nlen++;
            for(int i = nlen; i < 16; i++) printf(" ");
            
            // 打印运行时间
            printf("%d\n", (int)p->run_time);
            
            count++;
        }
    }
    
    printf("Total: %d processes, Switches: %d\n", count, (int)total_switches);
    printf("====================\n\n");
}

// ==================== 获取统计信息 ====================
void proc_stats(void)
{
    printf("\n=== Process Statistics ===\n");
    printf("Total context switches: %d\n", (int)total_switches);
    printf("Active processes: ");
    
    int active = 0;
    for(struct proc *p = proc; p < &proc[NPROC]; p++) {
        if(p->state != UNUSED && p->state != ZOMBIE) {
            active++;
        }
    }
    printf("%d\n", active);
    printf("========================\n\n");
}

// ==================== 状态名称 ====================
const char* state_name(enum procstate s)
{
    if(s >= 0 && s <= 5) {
        return state_names[s];
    }
    return state_names[6];
}
