#ifndef __DEFS_H__
#define __DEFS_H__

#include "riscv.h"
#include "param.h"
#include "proc.h"
#include "buf.h"
#include "fs.h"
#include "file.h"
#include "stat.h"

// --- Project 5 核心新增 ---
// kalloc.c
void kinit();
void *kalloc(void);
void kfree(void *);
void kref_inc(void *pa); // 引用计数增加
void kref_dec(void *pa); // 引用计数减少
int  kref_get(void *pa); // 获取引用计数

// vm.c
void kvminit(void);
void kvminithart(void);
pagetable_t create_pagetable(void);
int map_page(pagetable_t pt, uint64 va, uint64 pa, int perm);
pte_t *walk_lookup(pagetable_t pt, uint64 va);
int uvmcopy(pagetable_t old, pagetable_t new, uint64 sz); // COW 版复制
void uvmunmap(pagetable_t pt, uint64 va, uint64 npages, int do_free);
int cow_alloc(pagetable_t pagetable, uint64 va); // COW 缺页处理

// --- 基础 IO 与系统调用 ---

// uart.c
void uart_putc(char c);
void uart_puts(const char *s);

// console.c
void cons_putc(char c);
int consolewrite(int user_src, uint64 src, int n);
int consoleread(int user_dst, uint64 dst, int n);

// printf.c
void printf(const char *fmt, ...);
void panic(const char *msg);
void clear_screen();

// trap.c
void trap_init(void);
void clock_init(void);
uint64 get_time(void);
void fork_ret(); 

// string.c
int memcmp(const void*, const void*, uint);
void *memset(void*, int, uint);
void *memmove(void*, const void*, uint);
void *memcpy(void*, const void*, uint);
int strncmp(const char*, const char*, uint);
char *strncpy(char*, const char*, int);
int strlen(const char*);
char *safestrcpy(char*, const char*, int);

// proc.c
int fork(void);
void exit(int);
int wait(int*);
void sleep(void*, struct spinlock*);
void wakeup(void*);
void yield(void);
int create_process(void (*entry)(void));
void procinit(void);
void scheduler(void) __attribute__((noreturn));
struct proc* myproc(void);
struct cpu* mycpu(void);
void wait_process(int*);

// swtch.S
void swtch(struct context *old, struct context *new); 

// syscall.c 
void syscall(void);
int argint(int n, int *ip);
int argaddr(int n, uint64 *ip);
int argstr(int n, char *buf, int max);

// sysproc.c
int sys_exit(void);
int sys_fork(void);
int sys_wait(void);
int sys_kill(void);
int sys_getpid(void);
int sys_dup(void);
int sys_chdir(void);
int sys_mkdir(void);
int sys_mknod(void);
int sys_link(void);
int sys_unlink(void);
int sys_fstat(void);

// sysfile.c
int sys_read(void);
int sys_write(void);
int sys_open(void);
int sys_close(void);

// spinlock.c
void spinlock_init(struct spinlock *lk, char *name);
void acquire(struct spinlock *lk);
void release(struct spinlock *lk);
void push_off(void);
void pop_off(void);

// sleeplock.c
void initsleeplock(struct sleeplock *lk, char *name);
void acquiresleep(struct sleeplock *lk);
void releasesleep(struct sleeplock *lk);
int holdingsleep(struct sleeplock *lk);

// bio.c
void binit(void);
struct buf *bread(uint, uint);
void brelse(struct buf *);
void bwrite(struct buf *);
void bpin(struct buf *);
void bunpin(struct buf *);
uint64 get_buffer_cache_hits(void);
uint64 get_buffer_cache_misses(void);

// fs.c
void iinit(void);
struct inode *ialloc(uint dev, short type);
struct inode *iget(uint dev, uint inum);
void iupdate(struct inode *);
struct inode *idup(struct inode *);
void ilock(struct inode *);
void iunlock(struct inode *);
void iput(struct inode *);
void iunlockput(struct inode *);
int readi(struct inode *, int, uint64, uint, uint);
int writei(struct inode *, int, uint64, uint, uint);
void itrunc(struct inode *);
int stati(struct inode *, struct stat *);
int namecmp(const char *, const char *);
struct inode *dirlookup(struct inode *, char *, uint *);
int dirlink(struct inode *, char *, uint);
struct inode *namei(char *);
struct inode *nameiparent(char *, char *);
void get_superblock(struct superblock *);
void dump_inode_usage(void);

// log.c
void initlog(int dev, struct superblock *sb);
void begin_op(void);
void end_op(void);
void log_write(struct buf *);

// file.c
void fileinit(void);
struct file *filealloc(void);
struct file *filedup(struct file *);
void fileclose(struct file *);
int filestat(struct file *, uint64);
int fileread(struct file *, uint64, int);
int filewrite(struct file *, uint64, int);

// virtio_disk.c
void virtio_disk_init(void);
void virtio_disk_rw(struct buf *, int);
void virtio_disk_intr(void);
uint64 get_disk_read_count(void);
uint64 get_disk_write_count(void);

// test.c
void run_cow_tests(void);
void run_lab6_tests(void);
void run_lab7_tests(void);

#endif // __DEFS_H__
