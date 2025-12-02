// kernel/main.c
#include "defs.h"
#include "riscv.h"

void main_task(void) {
    printf("\n===== Test_task Started (PID %d) =====\n", myproc()->pid);
    run_lab4_tests();
    run_lab5_tests();
    run_lab6_tests();
    run_lab7_tests();
    printf("\n===== All Labs Complete =====\n");
    while (1);
}

void kmain(void) {
    clear_screen();
    printf("\n===== Kernel Booting =====\n");
    kinit();
    kvminit();
    kvminithart();
    procinit();
    trap_init();
    clock_init();
    binit();
    fileinit();
    virtio_disk_init();
    iinit();
    initlog(ROOTDEV, &sb);
    
    if (create_process(main_task) < 0) {
        printf("kmain: failed to create main_task\n");
        while(1);
    }
    scheduler();
}