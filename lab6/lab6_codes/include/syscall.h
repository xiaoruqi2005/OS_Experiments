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
#define SYS_write   7

// 内存管理
#define SYS_sbrk    10

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