/* kernel/syscall.c - 系统调用分发和参数提取 */

#include "types.h"
#include "defs.h"
#include "proc.h"
#include "syscall.h"
#include "trap.h"

// ==================== 系统调用表 ====================
static int (*syscalls[])(void) = {
    [SYS_fork]    = sys_fork,
    [SYS_exit]    = sys_exit,
    [SYS_wait]    = sys_wait,
    [SYS_getpid]  = sys_getpid,
    [SYS_kill]    = sys_kill,
    [SYS_read]    = sys_read,
    [SYS_write]   = sys_write,
    [SYS_sbrk]    = sys_sbrk,
};

// 系统调用名称（调试用）
static char *syscall_names[] = {
    [SYS_fork]    = "fork",
    [SYS_exit]    = "exit",
    [SYS_wait]    = "wait",
    [SYS_getpid]  = "getpid",
    [SYS_kill]    = "kill",
    [SYS_read]    = "read",
    [SYS_write]   = "write",
    [SYS_sbrk]    = "sbrk",
};

// ==================== 参数提取函数 ====================

// 获取第n个整数参数
int argint(int n, int *ip)
{
    struct proc *p = myproc();
    if(p == 0 || p->trapframe == 0)
        return -1;
    
    if(n < 0 || n >= 6)
        return -1;
    
    switch(n) {
        case 0: *ip = p->trapframe->a0; break;
        case 1: *ip = p->trapframe->a1; break;
        case 2: *ip = p->trapframe->a2; break;
        case 3: *ip = p->trapframe->a3; break;
        case 4: *ip = p->trapframe->a4; break;
        case 5: *ip = p->trapframe->a5; break;
    }
    return 0;
}

// 获取第n个地址参数
int argaddr(int n, uint64 *ip)
{
    struct proc *p = myproc();
    if(p == 0 || p->trapframe == 0)
        return -1;
    
    if(n < 0 || n >= 6)
        return -1;
    
    switch(n) {
        case 0: *ip = p->trapframe->a0; break;
        case 1: *ip = p->trapframe->a1; break;
        case 2: *ip = p->trapframe->a2; break;
        case 3: *ip = p->trapframe->a3; break;
        case 4: *ip = p->trapframe->a4; break;
        case 5: *ip = p->trapframe->a5; break;
    }
    return 0;
}

// 获取第n个字符串参数（使用 copyin 从用户空间安全读取）
int argstr(int n, char *buf, int max)
{
    uint64 addr;
    if(argaddr(n, &addr) < 0)
        return -1;

    struct proc *p = myproc();
    if(p == 0 || p->pagetable == 0)
        return -1;

    int i = 0;
    while(i + 1 < max) {
        char c;
        // 每次从用户虚拟地址 addr + i 读一个字节到内核 c
        if(copyin(p->pagetable, &c, addr + i, 1) < 0)
            return -1;
        buf[i++] = c;
        if(c == 0) {
            return 0;   // 成功
        }
    }
    buf[i] = 0;
    return -1;          // 字符串太长
}

// ==================== 系统调用分发器 ====================
void syscall(struct trapframe *tf)
{
    struct proc *p = myproc();
    if(p == 0) {
        printf("syscall: no process\n");
        return;
    }
    
    int num = tf->a7;
    
    // 调试输出
    if(num > 0 && num < sizeof(syscall_names)/sizeof(syscall_names[0]) && syscall_names[num]) {
        printf("[syscall] PID %d: %s\n", p->pid, syscall_names[num]);
    }
    
    // 检查系统调用号有效性
    if(num > 0 && num < sizeof(syscalls)/sizeof(syscalls[0]) && syscalls[num]) {
        int ret = syscalls[num]();
        tf->a0 = ret;
    } else {
        printf("syscall: unknown syscall %d\n", num);
        tf->a0 = -1;
    }

    // ⭐ 不再在这里修改 sepc，由 usertrap() 负责 sepc += 4
}
