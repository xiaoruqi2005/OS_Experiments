/* kernel/sysproc.c - 系统调用实现（实验6版本）*/

#include "types.h"
#include "defs.h"
#include "proc.h"
#include "syscall.h"

// ==================== sys_getpid ====================
int sys_getpid(void)
{
    struct proc *p = myproc();
    if(p == 0)
        return -1;
    return p->pid;
}

// ==================== sys_fork ====================
int sys_fork(void)
{
    printf("sys_fork: not implemented yet\n");
    return -1;
}

// ==================== sys_exit ====================
int sys_exit(void)
{
    int status;
    if(argint(0, &status) < 0)
        return -1;
    
    exit_proc(status);
    return 0;  // 不会到达这里
}

// ==================== sys_wait ====================
int sys_wait(void)
{
    uint64 addr;
    if(argaddr(0, &addr) < 0)
        return -1;
    
    int *status = (int*)addr;    // 注意：这里只是传给 wait_proc，真正 copyout 由上层自己控制
    return wait_proc(status);
}

// ==================== sys_kill ====================
int sys_kill(void)
{
    int pid;
    if(argint(0, &pid) < 0)
        return -1;
    
    // 遍历进程表查找目标进程
    struct proc *p;
    for(p = proc; p < &proc[NPROC]; p++) {
        if(p->pid == pid) {
            p->killed = 1;
            // 如果进程在睡眠，唤醒它
            if(p->state == SLEEPING) {
                p->state = RUNNABLE;
            }
            return 0;
        }
    }
    return -1;  // 进程不存在
}

// ==================== sys_write ====================
// fd, buf, count
int sys_write(void)
{
    int fd;
    uint64 ubuf;   // 用户空间缓冲区虚拟地址
    int count;
    
    // 提取参数：fd, buf, count
    if(argint(0, &fd) < 0 || argaddr(1, &ubuf) < 0 || argint(2, &count) < 0)
        return -1;
    
    // 简化版：只支持 fd=1 (stdout)
    if(fd != 1) {
        printf("sys_write: only stdout (fd=1) supported\n");
        return -1;
    }
    
    // 检查 count 范围
    if(count < 0 || count > 1024) {
        return -1;
    }

    struct proc *p = myproc();
    if(p == 0 || p->pagetable == 0)
        return -1;

    char kbuf[1024];
    // 从用户空间拷贝 count 字节到内核缓冲区
    if(copyin(p->pagetable, kbuf, ubuf, count) < 0)
        return -1;
    
    // 逐字节输出
    for(int i = 0; i < count; i++) {
        consputc(kbuf[i]);
    }
    
    return count;
}

// ==================== sys_read ====================
// fd, buf, count
int sys_read(void)
{
    int fd;
    uint64 ubuf;
    int count;
    
    // 提取参数
    if(argint(0, &fd) < 0 || argaddr(1, &ubuf) < 0 || argint(2, &count) < 0)
        return -1;
    
    // 简化版：只支持 fd=0 (stdin)
    if(fd != 0) {
        printf("sys_read: only stdin (fd=0) supported\n");
        return -1;
    }

    if(count <= 0)
        return 0;
    
    // 读取一个字符
    int c = uartgetc();
    if(c < 0)
        return 0;  // 没有输入
    
    char ch = (char)c;

    struct proc *p = myproc();
    if(p == 0 || p->pagetable == 0)
        return -1;

    // 把 1 个字节从内核写回用户缓冲区
    if(copyout(p->pagetable, ubuf, &ch, 1) < 0)
        return -1;

    return 1;
}

// ==================== sys_sbrk ====================
int sys_sbrk(void)
{
    int n;
    if(argint(0, &n) < 0)
        return -1;
    
    printf("sys_sbrk: not implemented yet\n");
    return -1;
}
