// kernel/proc.c
#include "defs.h"
#include "riscv.h" 

extern pagetable_t kernel_pagetable;
extern char etext[]; 

struct proc proc[NPROC];
struct cpu cpus[1]; 
struct proc *initproc;
static int nextpid = 1;

extern void fork_ret(void);
extern int mappages(pagetable_t, uint64, uint64, uint64, int); 

struct cpu* mycpu(void) { return &cpus[0]; }
struct proc* myproc(void) { 
    push_off(); 
    struct proc *p = cpus[0].proc; 
    pop_off(); 
    return p; 
}

// 映射内核到用户页表
static int uvm_kmap(pagetable_t pt) {
    if (mappages(pt, 0x80200000, (uint64)etext - 0x80200000, 0x80200000, PTE_R | PTE_X) < 0) return -1;
    if (mappages(pt, (uint64)etext, 0x88000000 - (uint64)etext, (uint64)etext, PTE_R | PTE_W) < 0) return -1;
    if (mappages(pt, 0x10000000, PGSIZE, 0x10000000, PTE_R | PTE_W) < 0) return -1;
    if (mappages(pt, 0x10001000, PGSIZE, 0x10001000, PTE_R | PTE_W) < 0) return -1;
    return 0;
}

static void freeproc(struct proc *p) {
    if (p->trapframe) kfree((void*)p->trapframe);
    p->trapframe = 0;
    if (p->kstack) kfree((void*)p->kstack);
    p->kstack = 0;
    if(p->pagetable) uvmunmap(p->pagetable, 0, 0x40000 / PGSIZE, 1);
    p->pagetable = 0;
    p->pid = 0;
    p->parent = 0;
    p->name[0] = 0;
    p->chan = 0;
    p->killed = 0;
    p->xstate = 0;
    for (int i = 0; i < NOFILE; i++) {
        if (p->ofile[i]) {
            fileclose(p->ofile[i]);
            p->ofile[i] = 0;
        }
    }
    if (p->cwd) {
        iput(p->cwd);
        p->cwd = 0;
    }
    p->state = UNUSED;
}

void proc_entry(void) {
    // --- DEBUG CHECK ---
    struct proc *p = myproc();
    if (p == 0) {
        printf("FATAL: proc_entry running with no process context!\n");
        while(1);
    }
    // -------------------
    
    release(&p->lock);
    if (p->entry) p->entry();
    exit(0);
}

static struct proc* allocproc(void) {
    struct proc *p;
    for(p = proc; p < &proc[NPROC]; p++) {
        acquire(&p->lock);
        if(p->state == UNUSED) {
            goto found;
        } else {
            release(&p->lock);
        }
    }
    return 0;

found:
    p->pid = nextpid++;
    p->state = USED;

    if((p->trapframe = (struct trapframe *)kalloc()) == 0){
        freeproc(p);
        release(&p->lock);
        return 0;
    }
    memset(p->trapframe, 0, PGSIZE);

    if((p->pagetable = create_pagetable()) == 0) {
        freeproc(p);
        release(&p->lock);
        return 0;
    }
    
    if (uvm_kmap(p->pagetable) < 0) {
        printf("allocproc: uvm_kmap failed\n"); // Add print
        freeproc(p);
        release(&p->lock);
        return 0;
    }

    if((p->kstack = (uint64)kalloc()) == 0){
        freeproc(p);
        release(&p->lock);
        return 0;
    }
    memset((void*)p->kstack, 0, PGSIZE);

    p->context.sp = p->kstack + PGSIZE;
    p->context.ra = (uint64)proc_entry;
    
    for (int i = 0; i < NOFILE; i++) {
        p->ofile[i] = 0;
    }
    p->cwd = 0;

    return p;
}

void procinit(void) {
    for (int i = 0; i < NPROC; i++) {
        spinlock_init(&proc[i].lock, "proc");
        proc[i].state = UNUSED;
    }
    printf("procinit: complete\n");
}

int create_process(void (*entry)(void)) {
    struct proc *p = allocproc();
    if (p == 0) return -1;
    
    char *mem = kalloc();
    if(!mem) { 
        freeproc(p); 
        release(&p->lock); 
        return -1; 
    }
    map_page(p->pagetable, 0, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U); 
    
    p->entry = entry;
    p->parent = 0; 
    p->trapframe->epc = 0; 
    p->trapframe->sp = PGSIZE; 
    
    if (p->cwd == 0) p->cwd = iget(ROOTDEV, ROOTINO);
    
    p->state = RUNNABLE;
    release(&p->lock);
    return p->pid;
}

int fork(void) {
    int i, pid;
    struct proc *np;
    struct proc *p = myproc();

    if ((np = allocproc()) == 0) return -1;

    if(uvmcopy(p->pagetable, np->pagetable, 0x40000) < 0) {
        freeproc(np);
        release(&np->lock);
        return -1;
    }

    *(np->trapframe) = *(p->trapframe);
    np->trapframe->a0 = 0; 
    np->context.ra = (uint64)fork_ret;

    for (i = 0; i < NOFILE; i++)
        if (p->ofile[i]) np->ofile[i] = filedup(p->ofile[i]);
    
    if (p->cwd) np->cwd = idup(p->cwd);
    safestrcpy(np->name, p->name, sizeof(p->name));
    
    pid = np->pid;
    np->parent = p;
    
    np->state = RUNNABLE;
    release(&np->lock);
    return pid;
}

void scheduler(void) {
    struct cpu *c = mycpu();
    c->proc = 0;
    
    w_satp(MAKE_SATP(kernel_pagetable)); 

    printf("scheduler: starting on cpu 0\n");
    while(1) {
        intr_on();
        for (struct proc *p = proc; p < &proc[NPROC]; p++) {
            acquire(&p->lock);
            if (p->state == RUNNABLE) {
                p->state = RUNNING;
                c->proc = p; 
                
                w_satp(MAKE_SATP(p->pagetable)); 
                sfence_vma();
                
                swtch(&c->context, &p->context);
                
                w_satp(MAKE_SATP(kernel_pagetable)); 
                sfence_vma();
                c->proc = 0; 
            }
            release(&p->lock);
        }
    }
}

void sched(void) {
    int intena = mycpu()->intena;
    swtch(&myproc()->context, &mycpu()->context);
    mycpu()->intena = intena;
}

void yield(void) {
    struct proc *p = myproc();
    acquire(&p->lock);
    p->state = RUNNABLE;
    sched();
    release(&p->lock);
}

void exit(int status) {
    struct proc *p = myproc();
    for (int fd = 0; fd < NOFILE; fd++) {
        if (p->ofile[fd]) {
            fileclose(p->ofile[fd]);
            p->ofile[fd] = 0;
        }
    }
    if (p->cwd) {
        iput(p->cwd);
        p->cwd = 0;
    }
    acquire(&p->lock);
    p->state = ZOMBIE;
    p->xstate = status;
    if (p->parent) wakeup(p->parent);
    sched();
    while(1);
}

int wait(int *status) {
    struct proc *p = myproc();
    int havekids, pid;
    acquire(&p->lock);
    while(1) {
        havekids = 0;
        for (struct proc *cp = proc; cp < &proc[NPROC]; cp++) {
            if (cp->parent == p) {
                acquire(&cp->lock);
                if (cp->state == ZOMBIE) {
                    pid = cp->pid;
                    if (status) *status = cp->xstate;
                    freeproc(cp);
                    release(&cp->lock);
                    release(&p->lock);
                    return pid;
                }
                release(&cp->lock);
                havekids = 1;
            }
        }
        if (!havekids || p->killed) {
            release(&p->lock);
            return -1;
        }
        sleep(p, &p->lock);
    }
}

void wait_process(int *status) { wait(status); }

void sleep(void *chan, struct spinlock *lk) {
    struct proc *p = myproc();
    if (lk != &p->lock) { acquire(&p->lock); release(lk); }
    p->chan = chan;
    p->state = SLEEPING;
    sched();
    p->chan = 0;
    if (lk != &p->lock) { release(&p->lock); acquire(lk); }
}

void wakeup(void *chan) {
    for (struct proc *p = proc; p < &proc[NPROC]; p++) {
        if (p != myproc()) {
            acquire(&p->lock);
            if (p->state == SLEEPING && p->chan == chan) {
                p->state = RUNNABLE;
            }
            release(&p->lock);
        }
    }
}
