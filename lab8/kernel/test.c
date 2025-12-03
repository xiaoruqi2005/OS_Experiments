// kernel/test.c
#include "riscv.h"
#include "defs.h"
#include "syscall.h"
#include "proc.h"
#include "fs.h"
#include "file.h"
#include "fcntl.h"
#include "stat.h"

#define NULL ((void*)0)

extern struct proc proc[NPROC];
extern uint64 get_time(void);

void assert(int condition) {
    if (!condition) {
        printf("ASSERTION FAILED!\n");
        while(1);
    }
}

// 内核睡眠
void kernel_sleep(int ticks) {
    uint64 target_ticks = get_ticks() + ticks;
    while (get_ticks() < target_ticks) {
        acquire(&myproc()->lock);
        // 修正: 解决 'tick_counter' undeclared 错误
        // 我们调用新函数来获取正确的睡眠通道
        sleep(get_ticks_channel(), &myproc()->lock);
        release(&myproc()->lock);
    }
}

void clean_process(){
    kernel_sleep(50);
    force_clean_zombies();
}
static struct proc* find_current_process_hard() {
    struct proc *p = myproc();
    if (p && p->state == RUNNING) return p;
    for(int i = 0; i < NPROC; i++) {
        if (proc[i].state == RUNNING) return &proc[i];
    }
    return NULL;
}

static int do_syscall(int num, uint64 a0, uint64 a1, uint64 a2) {
    struct proc *p = find_current_process_hard();
    if (p == NULL) { printf("\n[FATAL] No RUNNING process!\n"); while(1); }

    register long t_a7 asm("a7") = num;
    register long t_a0 asm("a0") = a0;
    register long t_a1 asm("a1") = a1;
    register long t_a2 asm("a2") = a2;

    asm volatile(".4byte 0x00100073" 
                 : "+r"(t_a0) 
                 : "r"(t_a1), "r"(t_a2), "r"(t_a7) 
                 : "memory");

    return t_a0;
}

int stub_getpid(void) { return do_syscall(SYS_getpid, 0, 0, 0); }
int stub_fork(void)   { return do_syscall(SYS_fork, 0, 0, 0); }
int stub_wait(int *s) { return do_syscall(SYS_wait, (uint64)s, 0, 0); }
void stub_exit(int s) { do_syscall(SYS_exit, s, 0, 0); }
int stub_write(int fd, char *p, int n) { return do_syscall(SYS_write, fd, (uint64)p, n); }
int stub_read(int fd, void *p, int n) { return do_syscall(SYS_read, fd, (uint64)p, n); }
int stub_open(const char *path, int mode) { return do_syscall(SYS_open, (uint64)path, mode, 0); }
int stub_close(int fd) { return do_syscall(SYS_close, fd, 0, 0); }
int stub_unlink(const char *path) { return do_syscall(SYS_unlink, (uint64)path, 0, 0); }
int stub_mkdir(const char *path) { return do_syscall(SYS_mkdir, (uint64)path, 0, 0); }
int stub_chdir(const char *path) { return do_syscall(SYS_chdir, (uint64)path, 0, 0); }
int stub_dup(int fd) { return do_syscall(SYS_dup, fd, 0, 0); }
int stub_link(const char *old, const char *newp) { return do_syscall(SYS_link, (uint64)old, (uint64)newp, 0); }
int stub_mknod(const char *path, int major, int minor) { return do_syscall(SYS_mknod, (uint64)path, major, minor); }
int stub_fstat(int fd, struct stat *st) { return do_syscall(SYS_fstat, fd, (uint64)st, 0); }

static void build_name(char *buf, const char *prefix, int idx) {
    int i = 0;
    while (prefix[i]) {
        buf[i] = prefix[i];
        i++;
    }
    char digits[16];
    int n = 0;
    if (idx == 0) {
        digits[n++] = '0';
    } else {
        while (idx > 0 && n < (int)sizeof(digits)) {
            digits[n++] = '0' + (idx % 10);
            idx /= 10;
        }
    }
    while (n > 0) {
        buf[i++] = digits[--n];
    }
    buf[i] = '\0';
}

// ===== Lab4 测试 =====

void test_timer_interrupt(void) {
    printf("\n=== Test 4.1: Timer Interrupt ===\n");
    
    uint64 start_time = get_time();
    uint64 start_count = get_interrupt_count();
    
    printf("Start time: %d, Start interrupt count: %d\n", start_time, start_count);
    printf("Waiting for 5 interrupts...\n");
    
    uint64 target_count = start_count + 5;
    while (get_interrupt_count() < target_count) {
        asm volatile("wfi"); // 等待中断
    }
    
    uint64 end_time = get_time();
    uint64 end_count = get_interrupt_count();
    
    printf("End time: %d, End interrupt count: %d\n", end_time, end_count);
    printf("Timer test completed: %d interrupts in %d cycles\n",
           end_count - start_count, end_time - start_time);
}

void test_exception_handling(void) {
    printf("\n=== Test 4.2: Exception Handling ===\n");
    
    // 1. 测试非法指令异常 (Illegal Instruction)
    // .word 0xFFFFFFFF 必定是 4 字节且非法的
    printf("1. Triggering Illegal Instruction exception...\n");
    asm volatile(".word 0xFFFFFFFF");
    printf("   -> Recovered from Illegal Instruction!\n");

    // 2. 测试加载页故障 (Load Page Fault)
    // 虽然 lw x0, 0(x0) 看起来没意义，但它会触发读取 0 地址的异常
    printf("2. Triggering Load Page Fault...\n");
    asm volatile("lw x0, 0(x0)"); 
    printf("   -> Recovered from Load Page Fault!\n");

    // 3. 测试存储页故障 (Store Page Fault)
    // 同样手动写汇编 sw (Store Word)，将 x0 的值写入地址 0(x0)
    // 这对应机器码 0x00002023，是一个标准的 4 字节指令
    printf("3. Triggering Store Page Fault...\n");
    asm volatile("sw x0, 0(x0)");
    printf("   -> Recovered from Store Page Fault!\n");

    printf("Exception tests completed successfully.\n");
}

void test_interrupt_overhead(void) {
    printf("\n=== Test 4.3: Interrupt Overhead ===\n");
    
    // 修正: 解决 "unused variable" 错误
    uint64 start_count = get_interrupt_count();
    uint64 start_time = get_time();
    
    volatile uint64 sum = 0;
    for (int i = 0; i < 1000000; i++) {
        sum += i;
    }
    
    uint64 end_time = get_time();
    uint64 end_count = get_interrupt_count();
    
    // 修正: 使用这些变量，防止编译器报错
    printf("  Test calculation (sum=%d)\n", sum);
    printf("  Elapsed cycles: %d\n", end_time - start_time);
    printf("  Interrupts during test: %d\n", end_count - start_count);
    printf("Interrupt overhead measurement complete\n");
}

// ===== Lab 5 测试 =====


// 辅助任务 1: 简单任务
void simple_task(void) {
    printf("PID %d: simple_task running...\n", myproc()->pid);
    exit(0);
}

// 辅助任务 2: CPU 密集型任务
void cpu_intensive_task(void) {
    printf("PID %d: cpu_intensive_task running...\n", myproc()->pid);
    volatile uint64 i;
    for (i = 0; i < 200000000L; i++);
    printf("PID %d: cpu_intensive_task finished.\n", myproc()->pid);
    exit(0);
}

// --- 同步测试辅助 ---
static struct spinlock buffer_lock;
static int buffer[10];
static int count = 0;
static int done = 0;

void shared_buffer_init(void) {
    spinlock_init(&buffer_lock, "buffer_lock");
    count = 0;
    done = 0;
}

// 辅助任务 3: 生产者
void producer_task(void) {
    printf("PID %d: producer_task running...\n", myproc()->pid);
    for (int i = 0; i < 20; i++) {
        acquire(&buffer_lock);
        while (count == 10) {
            sleep(&count, &buffer_lock);
        }
        buffer[count++] = i;
        printf("Producer: produced %d (count=%d)\n", i, count);
        wakeup(&count);
        release(&buffer_lock);
    }
    acquire(&buffer_lock);
    done++;
    wakeup(&count);
    release(&buffer_lock);
    printf("Producer finished.\n");
    exit(0);
}

// 辅助任务 4: 消费者
void consumer_task(void) {
    printf("PID %d: consumer_task running...\n", myproc()->pid);
    while (1) {
        acquire(&buffer_lock);
        while (count == 0) {
            if (done) {
                release(&buffer_lock);
                goto end;
            }
            sleep(&count, &buffer_lock);
        }
        int data = buffer[--count];
        printf("Consumer: consumed %d (count=%d)\n", data, count);
        wakeup(&count);
        release(&buffer_lock);
    }
end:
    printf("Consumer finished.\n");
    exit(0);
}

// --- Lab 5 测试入口 ---

// 测试 5.1: 进程创建
void test_process_creation(void) {
    printf("\n=== Test 5.1: Process Creation ===\n");

    printf("Testing basic process creation...\n");
    int pid = create_process(simple_task);//创建一个进程
    assert(pid > 0);
    printf("Created process %d\n", pid);



    // 获取当前进程数量
    int existing_procs = 0;
    for (int i = 0; i < NPROC; i++) {
        if (proc[i].state != UNUSED) {
            existing_procs++;
            printf("Existing process: PID=%d, state=%d, name=", 
                   proc[i].pid, proc[i].state);
            
            // 安全打印名字
            int has_name = 0;
            for (int j = 0; j < sizeof(proc[i].name); j++) {
                if (proc[i].name[j] == '\0') break;
                cons_putc(proc[i].name[j]);
                has_name = 1;
            }
            if (!has_name) {
                printf("(unnamed)");
            }
            printf("\n");
        }
    }
    
    // 计算可以创建的进程数
    int available_slots = NPROC - existing_procs;
    printf("Available process slots: %d\n", available_slots);

    printf("\nTesting process table limit (NPROC=%d)...\n", NPROC);
    
    
    int count = 0;
    for (int i = 0; i < NPROC + 5; i++) {
        pid = create_process(simple_task);
        if (pid > 0) {
            count++; // 只增加计数
        } else {
            break;
        }
    }

    printf("Created %d processes (expected max %d)\n", count, available_slots);
    assert(count == available_slots);
    
     // 清理
    printf("Cleaning processes...\n");
    clean_process();
    printf("Process creation test passed\n");
}

// 测试 8: 调度器
void test_scheduler(void) {
    printf("\n=== Test 5.2: Scheduler ===\n");
    printf("Creating 3 CPU intensive tasks...\n");
    for (int i = 0; i < 3; i++) {
        create_process(cpu_intensive_task);
    }
    
    printf("Observing scheduler behavior (sleeping 1000 ticks)...\n");
    uint64 start_time = get_ticks();
    kernel_sleep(1000);
    uint64 end_time = get_ticks();
    
    printf("Scheduler test completed (slept %d ticks)\n", end_time - start_time);
    
    clean_process();
}

// 测试 9: 同步机制
void test_synchronization(void) {

    printf("\n=== Test 5.3: Synchronization (Producer-Consumer) ===\n");
    shared_buffer_init();
    
    create_process(producer_task);
    create_process(consumer_task);
      
    clean_process();
    
    printf("Synchronization test completed\n");
}


// ===== Lab 6 测试 =====


void test_basic_syscalls(void) {
    printf("\n=== Test 6.1: Basic System Calls ===\n");
    
    int pid = stub_getpid();
    printf("Current PID (via syscall): %d\n", pid);
    assert(pid > 0);

    printf("Testing fork()...\n");
    int child_pid = stub_fork();
    
    if (child_pid == 0) {
        printf("  [Child] Hello from child! PID=%d\n", stub_getpid());
        stub_exit(42);
    } else if (child_pid > 0) {
        printf("  [Parent] Forked child PID=%d\n", child_pid);
        int status = 0;
        int waited_pid = stub_wait(&status);
        printf("  [Parent] Child %d exited with status %d\n", waited_pid, status);
        assert(waited_pid == child_pid);
        assert(status == 42);
    } else {
        printf("Fork failed!\n");
    }
    printf("Basic system calls test passed\n");
}

void test_parameter_passing(void) {
    printf("\n=== Test 6.2: Parameter Passing ===\n");
    char *msg = "  [Syscall Write] Hello World via write()!\n";
    int len = 0;
    while(msg[len]) len++;
    int n = stub_write(1, msg, len);
    printf("  Write returned: %d (expected %d)\n", n, len);
    assert(n == len);
    printf("Parameter passing test passed\n");
}

void test_security(void) {
    printf("\n=== Test 6.3: Security Test ===\n");
    char *invalid_ptr = (char*)0x0; 
    printf("  Writing to invalid pointer %p...\n", invalid_ptr);
    
    int result = stub_write(1, invalid_ptr, 10);
    printf("  Result: %d (Expected: -1)\n", result);
    
    assert(result == -1);
    printf("Security test passed: Invalid pointer correctly rejected\n");
}

void test_syscall_performance(void) {
    printf("\n=== Test 6.4: Syscall Performance ===\n");
    
    uint64 start_time = get_time();
    int count = 10000;

    printf("  Running %d getpid() calls...\n", count);
    for (int i = 0; i < count; i++) {
        stub_getpid(); 
    }

    uint64 end_time = get_time();
    uint64 duration = end_time - start_time;
    
    printf("  %d getpid() calls took %lu cycles\n", count, duration);
    if (count > 0) printf("  Average cycles per syscall: %lu\n", duration / count);
    printf("Performance test passed\n");
}

// === Lab 7 测试 ===
void test_filesystem_integrity(void) {
    printf("\n=== Test 7.1: Integrity ===\n");
    char buffer[] = "Hello, filesystem!";
    char read_buffer[64];

    printf("  1. Opening file for write...\n");
    int fd = stub_open("testfile", O_CREATE | O_RDWR);
    if (fd < 0) {
        printf("  FAIL: Open failed, fd=%d\n", fd);
        assert(0);
    }
    printf("  Open success, fd=%d\n", fd);

    printf("  2. Writing data...\n");
    int written = stub_write(fd, buffer, strlen(buffer));
    if (written != strlen(buffer)) {
        printf("  FAIL: Write failed, written=%d, expected=%d\n", written, strlen(buffer));
        assert(0);
    }
    printf("  Write success\n");
    
    stub_close(fd);

    printf("  3. Re-opening for read...\n");
    fd = stub_open("testfile", O_RDONLY);
    if (fd < 0) {
        printf("  FAIL: Re-open failed, fd=%d\n", fd);
        assert(0);
    }
    printf("  Re-open success, fd=%d\n", fd);

    printf("  4. Reading data...\n");
    // 清空缓冲区，防止读取到垃圾数据
    for(int k=0; k<64; k++) read_buffer[k] = 0;
    
    int bytes = stub_read(fd, read_buffer, sizeof(read_buffer) - 1);
    if (bytes != strlen(buffer)) {
        printf("  FAIL: Read count mismatch, bytes=%d, expected=%d\n", bytes, strlen(buffer));
        assert(0);
    }
    read_buffer[bytes] = '\0';
    printf("  Read bytes: %d, Content: '%s'\n", bytes, read_buffer);

    if (strncmp(buffer, read_buffer, bytes) != 0) {
        printf("  FAIL: Content mismatch!\n");
        printf("  Expected: '%s'\n", buffer);
        printf("  Actual:   '%s'\n", read_buffer);
        assert(0);
    }
    
    stub_close(fd);
    
    printf("  5. Unlinking...\n");
    if (stub_unlink("testfile") != 0) {
        printf("  FAIL: Unlink failed\n");
        assert(0);
    }
    
    printf("Filesystem integrity test passed\n");
}

void test_concurrent_access(void) {
    printf("\n=== Test 7.2: Concurrent Access ===\n");
    const int workers = 4;
    const int iterations = 100;
    for (int i = 0; i < workers; i++) {
        int pid = stub_fork();
        if (pid == 0) {
            char filename[32];
            build_name(filename, "test_", i);
            for (int j = 0; j < iterations; j++) {
                int fd = stub_open(filename, O_CREATE | O_RDWR);
                if (fd >= 0) {
                    stub_write(fd, (char*)&j, sizeof(j));
                    stub_close(fd);
                    stub_unlink(filename);
                }
            }
            stub_exit(0);
        }
    }
    for (int i = 0; i < workers; i++) {
        int status = 0;
        stub_wait(&status);
    }
    printf("Concurrent access test completed\n");
}

void test_crash_recovery(void) {
    printf("\n=== Test 7.3: Crash Recovery (Simulated) ===\n");
    char data[BSIZE];
    for (int i = 0; i < BSIZE; i++) {
        data[i] = (char)(i & 0xff);
    }

    int fd = stub_open("crashfile", O_CREATE | O_RDWR);
    assert(fd >= 0);
    assert(stub_write(fd, data, sizeof(data)) == sizeof(data));
    stub_close(fd);

    // 模拟重启：重新初始化日志并恢复
    initlog(ROOTDEV, &sb);

    fd = stub_open("crashfile", O_RDONLY);
    assert(fd >= 0);
    char verify[BSIZE];
    int bytes = stub_read(fd, verify, sizeof(verify));
    assert(bytes == sizeof(verify));
    assert(memcmp(data, verify, sizeof(data)) == 0);
    stub_close(fd);
    stub_unlink("crashfile");
    printf("Crash recovery simulation passed\n");
}

void test_filesystem_performance(void) {
    printf("\n=== Test 7.4: Performance ===\n");
    uint64 start = get_time();
    const int small_files = 200;
    char filename[32];
    for (int i = 0; i < small_files; i++) {
        build_name(filename, "small_", i);
        int fd = stub_open(filename, O_CREATE | O_RDWR);
        if (fd >= 0) {
            stub_write(fd, "test", 4);
            stub_close(fd);
        }
    }
    uint64 small_time = get_time() - start;

    start = get_time();
    int fd = stub_open("large_file", O_CREATE | O_RDWR | O_TRUNC);
    assert(fd >= 0);
    char buffer[4096];
    for (int i = 0; i < (1024); i++) {
        stub_write(fd, buffer, sizeof(buffer));
    }
    stub_close(fd);
    uint64 large_time = get_time() - start;

    printf("Small files (%d x 4B): %lu cycles\n", small_files, small_time);
    printf("Large file (4MB): %lu cycles\n", large_time);

    for (int i = 0; i < small_files; i++) {
        build_name(filename, "small_", i);
        stub_unlink(filename);
    }
    stub_unlink("large_file");
}

void debug_filesystem_state(void) {
    struct superblock info;
    get_superblock(&info);
    printf("\n=== Filesystem Debug Info ===\n");
    printf("Total blocks: %d\n", info.size);
    printf("Data blocks: %d\n", info.nblocks);
    printf("Free blocks: %d\n", count_free_blocks());
    printf("Free inodes: %d\n", count_free_inodes());
    printf("Buffer cache hits: %lu\n", get_buffer_cache_hits());
    printf("Buffer cache misses: %lu\n", get_buffer_cache_misses());
}

void debug_inode_usage(void) {
    dump_inode_usage();
}

void debug_disk_io(void) {
    printf("=== Disk I/O Statistics ===\n");
    printf("Disk reads: %lu\n", get_disk_read_count());
    printf("Disk writes: %lu\n", get_disk_write_count());
}




// 运行 Lab4 测试
void run_lab4_tests(void) {
    printf("\n===== Starting Lab4 Tests =====\n");
    test_timer_interrupt();
    test_exception_handling();
    test_interrupt_overhead();
    printf("\n===== All Lab4 Tests Passed! =====\n");
}

// 运行 Lab5 测试
void run_lab5_tests(void) {
    printf("\n===== Starting Lab5 Tests =====\n");
    
    test_process_creation();
    test_scheduler();
    test_synchronization();
    
    printf("\n===== All Lab5 Tests Passed! =====\n");
}

//  运行 Lab6 测试
void run_lab6_tests(void) {
    printf("\n===== Starting Lab6 Tests =====\n");
    // 尝试打开一个文件作为 stdout，如果尚未打开
    int fd = stub_open("console", O_CREATE | O_RDWR); 
    if (fd == 0) {
        stub_dup(fd); // fd 1
        stub_dup(fd); // fd 2
    }
    test_basic_syscalls();
    test_parameter_passing();
    test_security();
    test_syscall_performance();
    printf("\n===== All Lab6 Tests Passed! =====\n");
}

// === COW 功能验证测试 ===
void test_cow_correctness(void) {
    printf("\n=== Test: COW Correctness Verification ===\n");

    struct proc *p = myproc();
    if (p->pagetable == 0) {
        // 如果当前进程没有用户页表(比如纯内核线程)，我们需要临时创建一个
        // 注意：这只是为了测试 uvmcopy 逻辑，不会真正切换 satp 去运行它
        p->pagetable = create_pagetable();
    }

    // 1. 手动分配一个物理页作为"用户内存"
    char *pa = kalloc();
    if (pa == 0) panic("kalloc failed");
    memset(pa, 'A', PGSIZE); // 写入初始数据
    uint64 va = 0x1000;      // 假设虚拟地址

    // 2. 映射到父进程页表 (可写权限)
    if (mappages(p->pagetable, va, PGSIZE, (uint64)pa, PTE_W | PTE_R | PTE_U) < 0)
        panic("mappages failed");
    
    // 伪造进程大小，让 uvmcopy 知道要复制这个页
    uint64 old_sz = p->sz;
    p->sz = va + PGSIZE; 

    printf("1. Setup: Mapped VA %p -> PA %p (Ref: %d, Writable)\n", 
           va, pa, get_ref_count((uint64)pa));

    // 记录 Fork 前的空闲内存
    uint64 free_before = get_free_mem();

    // 3. 执行 Fork (模拟)
    // 这里我们直接调用 fork()，它内部会调用 uvmcopy
    int pid = stub_fork();

    if (pid < 0) panic("fork failed");

    if (pid == 0) {
        // === 子进程 ===
        struct proc *cp = myproc();
        
        // 4. 检查内存消耗
        uint64 free_child = get_free_mem();
        printf("   [Child] Free mem consumed: %d bytes (Expect small)\n", free_before - free_child);

        // 5. 检查子进程 PTE 状态
        pte_t *pte = walk_lookup(cp->pagetable, va);
        uint64 child_pa = PTE2PA(*pte);
        uint64 flags = PTE_FLAGS(*pte);

        printf("   [Child] VA %p maps to PA %p\n", va, child_pa);

        // 验证：物理页是否相同？
        if (child_pa != (uint64)pa) 
            printf("   FAIL: Physical page NOT shared!\n");
        else 
            printf("   PASS: Physical page shared.\n");

        // 验证：是否只读且标记了 COW？
        if ((flags & PTE_W) == 0 && (flags & PTE_C)) 
            printf("   PASS: PTE is Read-Only and marked COW.\n");
        else 
            printf("   FAIL: PTE flags incorrect (W=%d, C=%d)\n", !!(flags&PTE_W), !!(flags&PTE_C));

        // 验证：引用计数是否为 2？
        int ref = get_ref_count(child_pa);
        if (ref == 2) 
            printf("   PASS: Ref count is 2.\n");
        else 
            printf("   FAIL: Ref count is %d (Expect 2)\n", ref);

        // 6. 模拟写操作 (触发 COW)
        printf("2. Action: Triggering COW (simulated write fault)...\n");
        
        // 手动调用 cow_alloc，模拟 kerneltrap 的行为
        // 因为我们可能无法在内核态直接触发用户态缺页异常，这里直接测逻辑
        if (cow_alloc(cp->pagetable, va) < 0) {
            printf("   FAIL: cow_alloc returned error\n");
        } else {
            // 7. 再次检查状态
            pte = walk_lookup(cp->pagetable, va);
            uint64 new_pa = PTE2PA(*pte);
            flags = PTE_FLAGS(*pte);
            
            printf("   [Child] After Write: VA %p -> PA %p\n", va, new_pa);

            if (new_pa == (uint64)pa) 
                printf("   FAIL: Still pointing to old page!\n");
            else 
                printf("   PASS: Pointing to NEW page.\n");

            if ((flags & PTE_W) && !(flags & PTE_C)) 
                printf("   PASS: PTE is Writable and COW cleared.\n");
            else 
                printf("   FAIL: Flags incorrect (W=%d, C=%d)\n", !!(flags&PTE_W), !!(flags&PTE_C));
            
            if (get_ref_count((uint64)pa) == 1) 
                printf("   PASS: Old page ref count dropped to 1.\n");
            else 
                printf("   FAIL: Old page ref count is %d\n", get_ref_count((uint64)pa));
                
            if (get_ref_count(new_pa) == 1) 
                printf("   PASS: New page ref count is 1.\n");
        }

        stub_exit(0);
    } else {
        // === 父进程 ===
        int status;
        stub_wait(&status);
        printf("3. Parent: Child exited.\n");
        
        // 检查父进程 PTE 状态 (应该保持只读 COW，直到父进程自己也写)
        pte_t *pte = walk_lookup(p->pagetable, va);
        uint64 flags = PTE_FLAGS(*pte);
        if ((flags & PTE_W) == 0 && (flags & PTE_C))
            printf("   PASS: Parent PTE remains Read-Only/COW.\n");
        else
            printf("   FAIL: Parent PTE changed unexpectedly.\n");

        // 清理测试用的页
        uvmunmap(p->pagetable, va, 1, 1); // Unmap and free
        p->sz = old_sz; // 恢复大小
        printf("=== COW Test Complete ===\n");
    }
}


//  运行 Lab7 测试
void run_lab7_tests(void) {
    printf("\n===== Starting Lab6 Tests =====\n");
    test_filesystem_integrity();
    test_concurrent_access();
    test_crash_recovery();
    test_filesystem_performance();
    // debug_filesystem_state();
    // debug_inode_usage();
    // debug_disk_io();
    printf("===== All Lab7 Tests Passed! =====\n");
}

