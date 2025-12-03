# 实验报告五：进程管理与调度 

## 1\. 实验概述

### 1.1 实验目标

本实验旨在从零构建操作系统的进程管理子系统，将内核从单一执行流扩展为支持多任务并发的环境。核心目标包括：

1.  **进程抽象**：设计并实现进程控制块（PCB），管理进程状态、上下文及内核栈。
2.  **上下文切换**：编写汇编代码实现内核线程间的寄存器级切换。
3.  **调度系统**：实现基于时间片轮转（Round-Robin）的抢占式调度器。
4.  **生命周期管理**：实现进程的创建（Create）、执行（Run）、睡眠（Sleep）、退出（Exit）及回收（Wait）的全生命周期逻辑。

### 1.2 完成情况

  - [x] **PCB 设计**：完成 `struct proc` 结构体定义，包含状态、上下文、内核栈等字段。
  - [x] **上下文切换**：完成 `swtch.S` 汇编实现，支持 `ra`, `sp`, `s0-s11` 的保存与恢复。
  - [x] **进程创建**：实现 `alloc_proc` 和 `create_kthread`，成功初始化首个内核线程。
  - [x] **调度器**：实现 `scheduler` 主循环及 `sched`、`yield` 接口，支持时钟中断抢占。
  - [x] **同步机制**：实现 `sleep` 和 `wakeup` 原语，解决多进程竞争问题。
  - [x] **资源回收**：实现 `exit_proc` 和 `wait_proc`，能够正确处理僵尸进程。

### 1.3 开发环境

  - **操作系统**: Linux (Ubuntu 22.04 LTS)
  - **编译器**: riscv64-unknown-elf-gcc (GCC 10.2.0)
  - **模拟器**: QEMU emulator version 7.0.0
  - **调试器**: riscv64-unknown-elf-gdb

-----

## 2\. 实验原理与设计

### 2.1 核心数据结构：进程控制块 (PCB)

进程是资源分配和调度的基本单位。在 `kernel/proc.h` 中，我定义了 `struct proc` 来描述进程。

  - **设计决策**：采用静态数组 `struct proc proc[NPROC]` 管理所有进程。这种设计虽然限制了最大并发数，但避免了内核早期复杂的动态内存分配，提高了系统的稳定性。
  - **关键字段**：
      - `state`: 使用枚举 `enum procstate` 维护 UNUSED, RUNNABLE, RUNNING, SLEEPING, ZOMBIE 等状态，构成了严密的状态机。
      - `context`: 用于保存 Callee-saved 寄存器（ra, sp, s0-s11），这是实现 `swtch` 的基础。
      - `kstack`: 每个进程独占 4KB 的内核栈，确保内核代码执行时的栈隔离。

### 2.2 上下文切换机制

上下文切换的本质是 CPU 寄存器状态的“偷梁换柱”。

  - **原理**：依据 RISC-V 调用约定（Calling Convention），函数调用时 `t` 组寄存器由调用者保存，`s` 组由被调用者保存。`swtch` 函数作为一个特殊的函数调用，只需要保存 `ra` (返回地址)、`sp` (栈指针) 和 `s0-s11`。
  - **流程**：`Scheduler` 线程调用 `swtch` -\> 保存 Scheduler 的上下文 -\> 加载目标进程的上下文 -\> `ret` 指令跳转到目标进程的 `ra` -\> 目标进程继续执行。

### 2.3 调度策略与抢占

  - **策略**：采用**时间片轮转 (Round-Robin)**。调度器轮询进程表，找到第一个 `RUNNABLE` 的进程即进行调度。这种算法实现简单，且能保证基本的公平性。
  - **抢占机制**：利用 Lab 4 实现的时钟中断。当 Timer 中断发生时，中断处理程序调用 `yield()`，将当前进程状态置为 `RUNNABLE` 并放弃 CPU。这保证了即使某个任务陷入死循环，系统也能重新获得控制权。

-----

## 3\. 实验实现细节

### 3.1 进程控制块定义 (`include/proc.h`)

```c
struct context {
    uint64 ra;   // 返回地址
    uint64 sp;   // 栈指针
    uint64 s0;   // 被调用者保存寄存器 s0-s11
    // ... (s1-s11)
};

struct proc {
    enum procstate state;  // 进程状态
    int pid;               // 进程ID
    struct context context;// 切换上下文
    uint64 kstack;         // 内核栈地址
    struct proc *parent;   // 父进程指针
    void *chan;            // 睡眠通道
    int killed;            // 终止标记
    // ...
};
```

> **代码说明**：`context` 结构体严格对应 `swtch.S` 中保存的寄存器顺序。`chan` 字段用于实现条件变量同步。

### 3.2 上下文切换汇编 (`kernel/swtch.S`)

这是内核中唯一必须用汇编实现的函数。

```asm
.globl swtch
swtch:
    # a0 = old_context, a1 = new_context
    sd ra, 0(a0)
    sd sp, 8(a0)
    sd s0, 16(a0)
    # ... 保存 s1-s11 ...

    ld ra, 0(a1)
    ld sp, 8(a1)
    ld s0, 16(a1)
    # ... 恢复 s1-s11 ...
    
    ret  # 跳转到 new_context->ra
```

> **实现逻辑**：`swtch` 不保存程序计数器（PC），而是保存 `ra`。当 `ret` 执行时，PC 会自动加载 `ra` 的值，从而实现指令流的切换。

### 3.3 调度器逻辑 (`kernel/proc.c`)

调度器运行在每个 CPU 的专用线程中。

```c
void scheduler(void) {
    struct proc *p;
    struct cpu *c = mycpu();
    
    for(;;) {
        // 开启中断，防止死锁等待
        w_sstatus(r_sstatus() | SSTATUS_SIE);
        
        for(p = proc; p < &proc[NPROC]; p++) {
            if(p->state == RUNNABLE) {
                p->state = RUNNING;
                c->proc = p;
                
                // 核心切换点：保存 scheduler 上下文，加载进程 p 上下文
                swtch(&c->context, &p->context);
                
                // 进程 p 让出 CPU 后，代码从这里继续执行
                c->proc = 0;
            }
        }
    }
}
```

> **关键点**：在寻找进程前必须开启中断，否则如果所有进程都睡眠（SLEEPING），且中断被关闭，系统将无法响应时钟中断来唤醒它们，导致死锁。

### 3.4 进程退出与资源回收

为了防止僵尸进程堆积，实现了父子进程协同回收机制。

  - **exit\_proc**: 递归调用 `kill_children` 标记所有子进程，将自身设为 `ZOMBIE`，并唤醒 `parent`。
  - **wait\_proc**: 查找状态为 `ZOMBIE` 的子进程，调用 `free_proc` 释放其 `kstack` 和 PCB 槽位。若子进程尚在运行，则调用 `sleep` 挂起自己。

-----

## 4\. 实验结果

### 4.1 测试环境

测试代码位于 `kernel/test.c`，由 `kernel/main.c` 中的 `main_task` 统一调用。测试涵盖了极限创建、调度抢占及进程同步三个场景。

### 4.2 测试结果展示

#### 场景 1: 进程创建压力测试 (Test 7)

测试循环调用 `create_process` 直到进程表满。
**测试输出：**

```
=== Test 7: Process Creation Limit ===
Created kernel thread: PID=2...
...
Created kernel thread: PID=64...
Created 63 processes (expected max 63)
Process creation test passed
```

> **分析**：系统成功创建了 63 个进程（PID 2-64，PID 1 为 main\_task），触及 `NPROC` 上限后正确停止，且未发生内存泄漏。

#### 场景 2: 抢占式调度器测试 (Test 8)

创建 3 个死循环计算任务，主线程休眠等待。
**测试输出：**

```
=== Test 8: Scheduler ===
Creating 3 CPU intensive tasks...
Scheduler started
[Timer] System uptime: 1 seconds
Scheduler test completed (slept 1000 ticks)
```

> **分析**：虽然 3 个任务在执行死循环，但控制台依然打印了 Timer 中断信息，且主线程在 1 秒后成功被唤醒。这证明**时钟中断抢占机制**工作正常，死循环未能独占 CPU。

#### 场景 3: 生产者-消费者同步 (Test 9)

利用 `sleep/wakeup` 实现共享缓冲区协作。
**测试输出：**

```
=== Test 9: Synchronization ===
Producer produced item 0
Consumer consumed item 0
...
Producer waiting (buffer full)...
Consumer consumed item 5
Producer woke up
Synchronization test passed
```

> **分析**：日志显示生产者和消费者能够交替执行，且在缓冲区满/空时正确挂起和唤醒，验证了条件变量机制的正确性。

-----

## 5\. 总结与反思

### 5.1 遇到的问题及解决

1.  **问题**：首次运行调度器时系统崩溃（Kernel Panic），提示跳转到非法地址 `0x0`。

      - **分析**：`alloc_proc` 在初始化 `context` 时，未设置 `ra` 寄存器。导致 `swtch` 执行 `ret` 时跳转到了 0 地址。
      - **解决**：在 `alloc_proc` 中显式设置 `p->context.ra = (uint64)forkret;`，确保新进程有合法的入口地址。

2.  **问题**：时钟中断无法抢占，死循环任务卡死系统。

      - **分析**：调度器在切换到新进程时，未设置 `sstatus.SPIE` 位。导致进入新进程后全局中断被硬件自动关闭，无法响应 Timer 中断。
      - **解决**：在 `scheduler` 中，在 `swtch` 之前手动开启中断；或在进程初始化时预设 `sstatus` 的中断使能位。

### 5.2 思考题回答（节选）

  - **为什么时钟中断要在 M 模式处理？**
    RISC-V 规范规定 `mtime` 和 `mtimecmp` 是 M 模式 CSR。为了让 S 模式内核（操作系统）能响应时钟，必须在 M 模式捕获硬件中断后，通过写 `sip` 寄存器软件注入一个 S 模式中断（Soft IRQ）。

  - **轮转调度的公平性与不足？**
    Round-Robin 保证了所有就绪进程都能获得 CPU，不会产生饥饿，实现了形式上的绝对公平。但它无法区分 I/O 密集型和 CPU 密集型任务，导致交互式任务（如 Shell）的响应延迟较高。

### 5.3 实验心得

本次实验让我深刻体会到了“并发”的本质。在代码层面，它不过是栈空间的切换和寄存器状态的保存；但在宏观层面，它赋予了操作系统“三头六臂”的能力。特别是亲手实现 `swtch.S` 和抢占逻辑后，我对操作系统如何通过中断这一“脉搏”来驱动整个系统的生命周期有了具象的认知。这为后续理解更复杂的文件系统和虚拟内存管理奠定了坚实基础。