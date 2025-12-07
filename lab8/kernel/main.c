// kernel/main.c
#include "defs.h"
#include "riscv.h"

void main_task(void) {
    printf("===== main_task Started (PID %d) =====\n", myproc()->pid);
    
    // 将需要I/O同步的初始化移到进程中执行
    binit();
    fileinit();
    
    printf("DEBUG: Device Inits Done\n"); // binit/fileinit 不做 I/O，但放在这里保持结构
    
    virtio_disk_init(); // 可能会有 I/O
    printf("DEBUG: VirtIO Init Done\n");

    iinit();
    printf("DEBUG: FS Init Done\n");
    
    extern struct superblock sb;
    initlog(ROOTDEV, &sb);
    printf("DEBUG: Log Init Done\n");

    printf("===== Test: Copy-on-Write Fork System =====\n");
    test_cow_fork();
    while (1);
}


void kmain(void) {
    clear_screen();
    printf("===== Kernel Booting =====\n");
    
    // 只需要内存和进程/中断的基础初始化
    kinit();
    kvminit();
    kvminithart();
    procinit();
    trap_init();
    clock_init();
    
    // I/O 驱动自身的初始化 (不进行实际 I/O)
    // 即使这里不调用，virtio_disk_init() 也会在 main_task 里被调用
    
    if (create_process(main_task) < 0) {
        printf("kmain: failed to create main_task\n");
        while(1);
    }

    scheduler();
}
