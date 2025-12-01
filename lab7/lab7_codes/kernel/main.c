/* kernel/main.c - 系统主程序*/

#include "types.h"
#include "defs.h"
#include "riscv.h"
#include "proc.h"
#include "syscall.h"

extern char etext[];
extern char edata[];
extern char end[];
extern struct proc proc[];
extern struct proc *initproc;

// ==================== 系统主函数 ====================
void main()
{
    if(cpuid() == 0) {
        consoleinit();
        printfinit();
        printf("\n=== xv6 kernel is booting (Lab 7) ===\n");

        kinit();         // 物理内存
        kvminit();       // 内核页表
        kvminithart();   // 开启分页
        
        procinit();      // 进程表
        trap_init();     // 中断向量
        
        // --- 实验7 必须添加的初始化 ---
        printf("Initializing FS subsystems...\n");
        plicinit();      // 1. PLIC 控制器
        plicinithart();  // 2. 开启 PLIC 外部中断
        binit();         // 3. 块缓存 (Buffer Cache)
        iinit();         // 4. Inode 缓存
        fileinit();      // 5. 文件表
        virtio_disk_init(); // 6. 磁盘驱动
        // ------------------------------

        // 初始化时钟（放在最后，防止还没准备好就来中断）
        timer_init();    

        // 创建第一个用户进程
        // 这个进程通常是 /init，它会启动 sh，你可以在 sh 中运行验收测试
        userinit();      
        
        __sync_synchronize();
        // started = 1; 
    } else {
        // 如果是多核，从核也需要初始化
        // while(started == 0);
        // __sync_synchronize();
        // kvminithart();
        // trap_init();
        // plicinithart(); // 必须：从核也要开启外部中断
        // timer_init();
    }

    printf("Scheduler starting...\n");
    scheduler();
}
