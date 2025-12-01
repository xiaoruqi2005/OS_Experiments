#ifndef SYSCALL_H
#define SYSCALL_H

// ==================== 系统调用号,系统调用种类 ====================
// 进程管理
#define SYS_fork    1
#define SYS_exit    2
#define SYS_wait    3
#define SYS_getpid  4
#define SYS_kill    5

// 文件操作
#define SYS_read    6
#define SYS_write   22

// 内存管理
#define SYS_sbrk    23

// --- 新增部分 ---
#define SYS_exec    7
#define SYS_fstat   8
#define SYS_chdir   9
#define SYS_dup    10
#define SYS_sleep  13
#define SYS_uptime 14
#define SYS_open   15
#define SYS_mknod  17
#define SYS_unlink 18
#define SYS_link   19
#define SYS_mkdir  20
#define SYS_close  21

// ==================== 系统调用函数声明 ====================
// 这些函数在 kernel/sysproc.c 中实现
int sys_fork(void);
int sys_exit(void);
int sys_wait(void);
int sys_getpid(void);
int sys_kill(void);
int sys_read(void);
int sys_write(void);
int sys_sbrk(void);

#endif
