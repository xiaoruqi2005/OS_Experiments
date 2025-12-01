#ifndef DEFS_H
#define DEFS_H

#include "types.h"

/* ==================== 类型定义 ==================== */
// 页表类型（避免循环依赖）
typedef uint64* pagetable_t;

/* ==================== 前向声明 ==================== */
struct trapframe;
struct proc;

/* ==================== 可变参数支持 ==================== */
typedef __builtin_va_list va_list;
#define va_start(ap, last) __builtin_va_start(ap, last)
#define va_arg(ap, type) __builtin_va_arg(ap, type)
#define va_end(ap) __builtin_va_end(ap)

/* ==================== main.c ==================== */
void main(void);

/* ==================== uart.c ==================== */
void uartinit(void);
void uartputc_sync(int c);
int  uartgetc(void);

/* ==================== console.c ==================== */
void consoleinit(void);
void consputc(int c);

/* ==================== printf.c ==================== */
int  printf(char *fmt, ...);
void panic(char *s);
void printfinit(void);

/* ==================== screen.c ==================== */
void clear_screen(void);
void set_cursor(int x, int y);

/* ==================== kalloc.c ==================== */
void pmm_init(void);
void* alloc_page(void);
void free_page(void* pa);
void pmm_info(void);

/* ==================== vm.c ==================== */
void kvminit(void);
void kvminithart(void);
pagetable_t create_pagetable(void);
void destroy_pagetable(pagetable_t pagetable);
int map_page(pagetable_t pagetable, uint64 va, uint64 pa, int perm);
pagetable_t proc_pagetable(struct proc *p);
void proc_freepagetable(pagetable_t pagetable, uint64 size);

/* ⭐ 新增：用户空间拷贝函数（供 syscall 使用） */
int copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len);
int copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len);

/* ==================== trap.c ==================== */
void trap_init(void);
void print_trap_stats(void);
void kerneltrap(struct trapframe *tf);
void usertrap(void);
void usertrapret(void);
void kernelvec(void);

/* ==================== trampoline.S ==================== */
// 这些是汇编符号，用于地址计算，不是函数
extern char trampoline[];
extern char uservec[];
extern char userret[];

/* ==================== timer.c ==================== */
void timer_init(void);
void timer_init_hart(void);
void timer_interrupt(void);
uint64 get_ticks(void);
uint64 get_uptime_seconds(void);
void delay_ms(uint64 ms);

/* ==================== start.c ==================== */
void start(void);
void sbi_set_timer(uint64 stime_value);
void sbi_shutdown(void);

/* ==================== proc.c ==================== */
void procinit(void);
int kthread_create(void (*fn)(void), char *name);
int userinit(void);
void scheduler(void) __attribute__((noreturn));
void yield(void);
void proc_info(void);
void proc_stats(void);
struct proc* myproc(void);
void exit_proc(int status);
int wait_proc(int *status);
void sleep(void *chan);
void wakeup(void *chan);
void push_off(void);
void pop_off(void);

/* ==================== syscall.c ==================== */
void syscall(struct trapframe *tf);
int argint(int n, int *ip);
int argaddr(int n, uint64 *ip);
int argstr(int n, char *buf, int max);

/* ==================== kalloc.c - 工具函数 ==================== */
void* memset(void *dst, int c, uint n);
void* memcpy(void *dst, const void *src, uint n);



// ------------------ 新增文件系统相关声明 ------------------

struct buf;
struct context;
struct file;
struct inode;
struct pipe;
struct proc;
struct spinlock;
struct sleeplock;
struct stat;
struct superblock;

// bio.c (Buffer Cache)
void            binit(void);
struct buf* bread(uint, uint);
void            brelse(struct buf*);
void            bwrite(struct buf*);
void            bpin(struct buf*);
void            bunpin(struct buf*);

// fs.c (File System)
void            fsinit(int);
int             dirlink(struct inode*, char*, uint);
struct inode* dirlookup(struct inode*, char*, uint*);
struct inode* ialloc(uint, short);
struct inode* idup(struct inode*);
void            iinit();
void            ilock(struct inode*);
void            iput(struct inode*);
void            iunlock(struct inode*);
void            iunlockput(struct inode*);
void            iupdate(struct inode*);
int             namecmp(const char*, const char*);
struct inode* namei(char*);
struct inode* nameiparent(char*, char*);
int             readi(struct inode*, int, uint64, uint, uint);
void            stati(struct inode*, struct stat*);
int             writei(struct inode*, int, uint64, uint, uint);
void            itrunc(struct inode*);

// file.c (File Descriptor Layer)
struct file* filealloc(void);
void            fileclose(struct file*);
struct file* filedup(struct file*);
void            fileinit(void);
int             fileread(struct file*, uint64, int n);
int             filestat(struct file*, uint64 addr);
int             filewrite(struct file*, uint64, int n);

// log.c (Crash Safety)
void            initlog(int, struct superblock*);
void            log_write(struct buf*);
void            begin_op(void);
void            end_op(void);

// pipe.c (Pipes)
int             pipealloc(struct file**, struct file**);
void            pipeclose(struct pipe*, int);
int             piperead(struct pipe*, uint64, int);
int             pipewrite(struct pipe*, uint64, int);

// virtio_disk.c (Disk Driver)
void            virtio_disk_init(void);
void            virtio_disk_rw(struct buf *, int);
void            virtio_disk_intr(void);

// plic.c (Interrupt Controller)
// 如果 lab6 已经有了可以忽略，通常文件系统需要它来处理磁盘中断
void            plicinit(void);
void            plicinithart(void);
int             plic_claim(void);
void            plic_complete(int);

// sleeplock.c (Sleeping Locks - used by FS)
void            acquiresleep(struct sleeplock*);
void            releasesleep(struct sleeplock*);
int             holdingsleep(struct sleeplock*);
void            initsleeplock(struct sleeplock*, char*);

// exec.c (Exec is updated to support FS)
int             exec(char*, char**);

// string.c
int             memcmp(const void*, const void*, uint);
void* memmove(void*, const void*, uint);
void* memset(void*, int, uint);
char* safestrcpy(char*, const char*, int);
int             strlen(const char*);
int             strncmp(const char*, const char*, uint);
char* strncpy(char*, const char*, int);
void* memcpy(void*, const void*, uint);
#endif
