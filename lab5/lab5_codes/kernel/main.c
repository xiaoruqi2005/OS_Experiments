/* kernel/main.c - 实验5主程序（加入进程树 kill 演示，修复Killer等待方式）*/

#include "defs.h"
#include "mm.h"
#include "riscv.h"
#include "trap.h"
#include "proc.h"

// ==================== 共享缓冲区（生产者-消费者测试）====================
#define BUFFER_SIZE 5
static int buffer[BUFFER_SIZE];
static int count = 0;      // 缓冲区中的项目数
static int produced = 0;   // 已生产的总数
static int consumed = 0;   // 已消费的总数

// 用于演示“进程树 kill”的各个PID
static int tree_parent_pid      = -1;
static int tree_child1_pid      = -1;
static int tree_child2_pid      = -1;
static int tree_grandchild_pid  = -1;

// ==================== 工具函数：在内核里设置父子关系 ====================
// 由于我们现在用的是内核线程，没有真正的 fork，这里在 main 里手动建立父子关系
static void set_parent(int child_pid, int parent_pid)
{
    struct proc *p;
    struct proc *parent = 0;
    struct proc *child  = 0;

    for (p = proc; p < &proc[NPROC]; p++) {
        if (p->pid == parent_pid) {
            parent = p;
        }
        if (p->pid == child_pid) {
            child = p;
        }
    }

    if (parent && child) {
        child->parent = parent;
        printf("[main] Set parent of PID %d (%s) to PID %d (%s)\n",
               child->pid, child->name, parent->pid, parent->name);
    } else {
        printf("[main] WARNING: failed to set parent (child=%d parent=%d)\n",
               child_pid, parent_pid);
    }
}

// ==================== 简单测试线程 ====================

// 线程1：打印数字
void thread1(void)
{
    for(int i = 0; i < 5; i++) {
        printf("[Thread1] Count: %d\n", i);
        yield();  // 主动让出CPU
    }
    printf("[Thread1] Finished!\n");
    exit_proc(0);
}

// 线程2：打印字母
void thread2(void)
{
    char letters[] = "ABCDE";
    for(int i = 0; i < 5; i++) {
        printf("[Thread2] Letter: %c\n", letters[i]);
        yield();
    }
    printf("[Thread2] Finished!\n");
    exit_proc(0);
}

// 线程3：计算密集型
void thread3(void)
{
    for(int i = 0; i < 3; i++) {
        volatile int sum = 0;
        for(volatile int j = 0; j < 1000000; j++) {
            sum += j;
        }
        printf("[Thread3] Iteration %d completed\n", i);
        yield();
    }
    printf("[Thread3] Finished!\n");
    exit_proc(0);
}

// ==================== 同步机制测试：生产者-消费者 ====================

// 生产者线程
void producer_thread(void)
{
    printf("[Producer] Started\n");
    
    for(int i = 0; i < 10; i++) {
        // 等待缓冲区有空间
        while(count >= BUFFER_SIZE) {
            printf("[Producer] Buffer full (count=%d), sleeping...\n", count);
            sleep(&count);  // 在count通道上睡眠
        }
        
        // 生产一个项目
        buffer[count] = i;
        count++;
        produced++;
        printf("[Producer] Produced item %d (buffer count=%d)\n", i, count);
        
        // 唤醒可能在等待的消费者
        wakeup(&count);
        
        // 模拟生产耗时
        for(volatile int j = 0; j < 100000; j++);
        yield();
    }
    
    printf("[Producer] Finished! Total produced: %d\n", produced);
    exit_proc(0);
}

// 消费者线程
void consumer_thread(void)
{
    printf("[Consumer] Started\n");
    
    for(int i = 0; i < 10; i++) {
        // 等待缓冲区有数据
        while(count <= 0) {
            printf("[Consumer] Buffer empty (count=%d), sleeping...\n", count);
            sleep(&count);  // 在count通道上睡眠
        }
        
        // 消费一个项目
        count--;
        int item = buffer[count];
        consumed++;
        printf("[Consumer] Consumed item %d (buffer count=%d)\n", item, count);
        
        // 唤醒可能在等待的生产者
        wakeup(&count);
        
        // 模拟消费耗时
        for(volatile int j = 0; j < 150000; j++);
        yield();
    }
    
    printf("[Consumer] Finished! Total consumed: %d\n", consumed);
    exit_proc(0);
}

// ==================== 调度器观察用线程 ====================

// 长时间运行的后台线程（保持原来的背景输出）
void background_thread(void)
{
    printf("[Background] Started\n");
    
    for(int i = 0; i < 20; i++) {
        printf("[Background] Tick %d\n", i);
        
        // 每5次打印进程信息
        if(i % 5 == 0) {
            proc_info();
        }
        
        yield();
    }
    
    printf("[Background] Finished!\n");
    exit_proc(0);
}

// ==================== 进程树演示：父/子/孙线程 ====================

void tree_parent_thread(void)
{
    printf("[PT-Parent] Started (PID %d)\n", myproc()->pid);
    
    for (int i = 0; i < 50; i++) {
        printf("[PT-Parent] Tick %d\n", i);
        yield();
    }

    // 如果没被kill，会走到这里并正常退出
    printf("[PT-Parent] Finished normally\n");
    exit_proc(0);
}

void tree_child1_thread(void)
{
    printf("[PT-Child1] Started (PID %d, parent PID %d)\n",
           myproc()->pid,
           myproc()->parent ? myproc()->parent->pid : -1);
    
    for (int i = 0; i < 50; i++) {
        printf("[PT-Child1] Tick %d\n", i);
        yield();
    }

    printf("[PT-Child1] Finished normally\n");
    exit_proc(0);
}

void tree_child2_thread(void)
{
    printf("[PT-Child2] Started (PID %d, parent PID %d)\n",
           myproc()->pid,
           myproc()->parent ? myproc()->parent->pid : -1);
    
    for (int i = 0; i < 50; i++) {
        printf("[PT-Child2] Tick %d\n", i);
        yield();
    }

    printf("[PT-Child2] Finished normally\n");
    exit_proc(0);
}

void tree_grandchild_thread(void)
{
    printf("[PT-Grandchild] Started (PID %d, parent PID %d)\n",
           myproc()->pid,
           myproc()->parent ? myproc()->parent->pid : -1);
    
    for (int i = 0; i < 50; i++) {
        printf("[PT-Grandchild] Tick %d\n", i);
        yield();
    }

    printf("[PT-Grandchild] Finished normally\n");
    exit_proc(0);
}

// ==================== 杀手线程：演示 kill_proc 对整棵进程树的效果 ====================

void tree_killer_thread(void)
{
    printf("[PT-Killer] Started\n");
    
    // 不要用 delay_ms 忙等，否则会把CPU一直占住、调度器拿不到机会
    // 这里用多次 yield 的方式“等一会儿”，让父/子/孙都跑一段时间
    for (int i = 0; i < 30; i++) {
        printf("[PT-Killer] waiting... (%d)\n", i);
        yield();
    }
    
    if (tree_parent_pid > 0) {
        printf("[PT-Killer] Now killing parent PID %d (and all its children)\n",
               tree_parent_pid);
        int r = kill_proc(tree_parent_pid);
        if (r == 0) {
            printf("[PT-Killer] kill_proc(%d) succeeded\n", tree_parent_pid);
        } else {
            printf("[PT-Killer] kill_proc(%d) FAILED (not found)\n", tree_parent_pid);
        }
    } else {
        printf("[PT-Killer] No valid tree_parent_pid to kill\n");
    }
    
    printf("[PT-Killer] Finished\n");
    exit_proc(0);
}

// ==================== 主函数 ====================
void main(void) {
    // ========== 初始化控制台 ==========
    consoleinit();
    clear_screen();
    
    printf("=== RISC-V OS Lab 5: Process Management ===\n");
    printf("Student Implementation - Full Feature Version (with kill tree demo)\n\n");
    
    // ========== 阶段1：系统初始化 ==========
    printf("=== Phase 1: System Initialization ===\n");
    
    // 内存管理
    pmm_init();
    kvminit();
    kvminithart();
    
    // 中断和时钟
    trap_init();
    timer_init();
    
    // 进程系统
    proc_init();
    
    printf("System initialization completed!\n");
    
    // ========== 阶段2：基本线程测试 ==========
    printf("\n=== Phase 2: Basic Thread Tests ===\n");
    create_kthread(thread1, "Thread-1");
    create_kthread(thread2, "Thread-2");
    create_kthread(thread3, "Thread-3");
    
    // ========== 阶段3：同步机制测试 ==========
    printf("\n=== Phase 3: Synchronization Test (Producer-Consumer) ===\n");
    printf("Creating producer and consumer threads...\n");
    create_kthread(producer_thread, "Producer");
    create_kthread(consumer_thread, "Consumer");
    
    // ========== 阶段4：调度器观察 ==========
    printf("\n=== Phase 4: Scheduler Observation ===\n");
    create_kthread(background_thread, "Background");
    
    // ========== 阶段5：进程树 kill 演示 ==========
    //在指定进程和所有子进程上打 killed 标记，并把他们从 sleep 中唤醒；
    //真正的退出发生在这些进程下一次进入调度点（yield() / sleep() 返回）时，由进程自己调用 exit_proc(-1) 干净退出。
    // 不直接粗暴干掉，而是标记 + 让它自己安全退出
    //被 kill_proc() 标记后置为 1，但不会马上退出，而是等到进程自己在合适的点检查这个标志，然后调用 exit_proc(-1)。
    //从效果上，因为有：Timer 中断（每 100ms）+ 抢占；Round-Robin 调度；
//所以被 kill 的进程 最多再跑一个极短的时间片，就会在 yield() 里检测到 killed，然后 exit_proc(-1),从用户视角几乎是“立即”杀死
    printf("\n=== Phase 5: Kill Tree Demo (Parent + Children + Grandchild) ===\n");
    
    tree_parent_pid     = create_kthread(tree_parent_thread,     "PT-Parent");
    tree_child1_pid     = create_kthread(tree_child1_thread,     "PT-Child1");
    tree_child2_pid     = create_kthread(tree_child2_thread,     "PT-Child2");
    tree_grandchild_pid = create_kthread(tree_grandchild_thread, "PT-Grandchild");
    
    printf("[main] Tree PIDs: parent=%d, child1=%d, child2=%d, grandchild=%d\n",
           tree_parent_pid, tree_child1_pid, tree_child2_pid, tree_grandchild_pid);
    
    // 手动设置父子关系：
    // PT-Parent
    //  ├── PT-Child1
    //  │     └── PT-Grandchild
    //  └── PT-Child2
    set_parent(tree_child1_pid,     tree_parent_pid);
    set_parent(tree_child2_pid,     tree_parent_pid);
    set_parent(tree_grandchild_pid, tree_child1_pid);
    
    // 创建杀手线程：过一会儿 kill 整棵树
    create_kthread(tree_killer_thread, "PT-Killer");
    
    // ========== 启动调度器 ==========
    printf("\n=== Starting Scheduler ===\n");
    printf("Initial process table:\n");
    proc_info();
    
    printf("Entering scheduler...\n");
    printf("Press Ctrl+A then X to exit QEMU\n\n");
    
    scheduler();  // 永不返回
}
