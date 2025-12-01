#ifndef MM_H
#define MM_H

#include "types.h"
// ==================== 前向声明 ====================
struct proc; 
// ==================== 页面管理基础常量 ====================
// RISC-V标准页面大小为4KB，这是MMU硬件固定的最小内存管理单位
#define PGSIZE 4096                     // 4KB页面大小
#define PGSHIFT 12                      // log2(PGSIZE) = 12，用于位运算优化

// 页面对齐宏 - 关键的地址对齐操作
// PGROUNDUP: 向上对齐到页边界 (例: 5000 -> 8192)
#define PGROUNDUP(sz)   (((sz) + PGSIZE - 1) & ~(PGSIZE - 1))
// PGROUNDDOWN: 向下对齐到页边界 (例: 5000 -> 4096)
#define PGROUNDDOWN(a)  (((a)) & ~(PGSIZE - 1))

// ==================== 物理内存布局定义 ====================
// QEMU RISC-V virt平台的内存映射
#define KERNBASE 0x80000000             // 内核起始地址 - RISC-V约定
#define PHYSTOP  0x88000000             // 物理内存结束(128MB) - 实验限制

// ==================== 设备地址映射 ====================
// QEMU virt 机器的设备地址布局
#define UART0       0x10000000          // UART0 串口设备
#define UART0_IRQ   10                  // UART0 中断号
#define VIRTIO0     0x10001000          // VirtIO 磁盘设备
#define CLINT       0x02000000          // Core Local Interruptor (时钟)
#define PLIC        0x0c000000          // Platform-Level Interrupt Controller

// ==================== 用户地址空间布局 ====================
#define USTACK      0x4000              // 用户栈起始地址（16KB）
#define USTACKTOP   (USTACK + PGSIZE)   // 用户栈顶
#define TRAMPOLINE  0x3ffffff000        // trampoline页（最高页-1页）
#define TRAPFRAME   (TRAMPOLINE - PGSIZE) // trapframe页（最高页-2页）

// ==================== RISC-V Sv39页表相关定义 ====================
// SATP寄存器配置 - 用于启用和配置虚拟内存
// SATP格式: MODE[63:60] | ASID[59:44] | PPN[43:0]
#define SATP_SV39 (8L << 60)            // MODE=8表示Sv39模式(39位虚拟地址)
// 构造SATP寄存器值：模式位 | 页表物理页号
#define MAKE_SATP(pagetable) (SATP_SV39 | (((uint64)pagetable) >> 12))

// ==================== 虚拟地址分解宏 ====================
// Sv39地址结构: VPN[2](9位) | VPN[1](9位) | VPN[0](9位) | offset(12位)
//              bits[38:30]   bits[29:21]   bits[20:12]   bits[11:0]

#define PXMASK 0x1FF                    // 9位掩码 (512个条目/页表)
#define PXSHIFT(level) (PGSHIFT + (9 * (level))) // 各级VPN的位移量
// 从虚拟地址提取指定级别的9位页表索引
#define PX(level, va) ((((uint64)(va)) >> PXSHIFT(level)) & PXMASK)

// ==================== 页表项(PTE)标志位定义 ====================
// RISC-V页表项格式: PPN[53:10] | RSW[9:8] | DAGUXWRV[7:0]
#define PTE_V (1L << 0)     // Valid - 有效位
#define PTE_R (1L << 1)     // Read - 可读
#define PTE_W (1L << 2)     // Write - 可写
#define PTE_X (1L << 3)     // Execute - 可执行
#define PTE_U (1L << 4)     // User - 用户态可访问
#define PTE_G (1L << 5)     // Global - 全局映射（TLB不刷新）
#define PTE_A (1L << 6)     // Accessed - 已访问
#define PTE_D (1L << 7)     // Dirty - 已修改

// ==================== 页表项地址转换宏 ====================
// PTE格式中bits[53:10]存储物理页号(PPN)

// 从PTE提取物理地址
#define PTE2PA(pte)     (((pte) >> 10) << 12)
#define PTE_PA(pte)     (((pte) >> 10) << 12)  // ← 这一行
// 将物理地址转换为PTE格式
#define PA2PTE(pa)      ((((uint64)(pa)) >> 12) << 10)
// 提取PTE标志位
#define PTE_FLAGS(pte)  ((pte) & 0x3FF)

// ==================== 访问类型定义 ====================
#define ACCESS_READ  1      // 读访问
#define ACCESS_WRITE 2      // 写访问
#define ACCESS_EXEC  4      // 执行访问

// ==================== 数据类型定义 ====================
typedef uint64 pte_t;           // 页表项类型 - 64位
typedef uint64* pagetable_t;    // 页表指针类型

// ==================== 外部符号(来自链接脚本) ====================
extern char etext[];    // 代码段结束位置
extern char edata[];    // 数据段结束位置
extern char end[];      // 内核结束位置

// ==================== 全局变量声明 ====================
extern pagetable_t kernel_pagetable;    // 内核根页表

// ==================== 物理内存分配器接口 ====================
void pmm_init(void);                    // 初始化物理内存管理器
void* alloc_page(void);                 // 分配一个物理页
void free_page(void* page);             // 释放一个物理页
void pmm_info(void);                    // 打印内存使用信息

// ==================== 页表管理接口 ====================
pagetable_t create_pagetable(void);     // 创建新页表
void destroy_pagetable(pagetable_t pt); // 销毁页表
int map_page(pagetable_t pt, uint64 va, uint64 pa, int perm); // 映射单页
int map_region(pagetable_t pt, uint64 va, uint64 pa, uint64 size, int perm); // 映射区域
pte_t* walk_create(pagetable_t pt, uint64 va); // 页表遍历(创建模式)
pte_t* walk_lookup(pagetable_t pt, uint64 va); // 页表遍历(查找模式)
void dump_pagetable(pagetable_t pt, int level); // 调试用页表打印

// ==================== 内核虚拟内存管理 ====================
void kvminit(void);                     // 初始化内核页表
void kvminithart(void);                 // 激活内核页表

// ==================== 用户虚拟内存管理 ====================
pagetable_t proc_pagetable(struct proc *p);     // 创建进程页表
void proc_freepagetable(pagetable_t pagetable, uint64 size); // 释放进程页表

// ==================== 工具函数 ====================
void* memset(void *dst, int c, uint n);         // 内存填充
void* memcpy(void *dst, const void *src, uint n); // 内存复制
void* memmove(void *dst, const void *src, uint n); // 内存移动
int memcmp(const void *v1, const void *v2, uint n); // 内存比较

// ==================== 测试函数 ====================
void run_comprehensive_tests(void);     // 运行完整测试套件
void test_multilevel_pagetable(void);   // 测试多级页表
void test_edge_cases(void);             // 测试边界条件
int check_page_permission(uint64 addr, int access_type); // 检查访问权限

#endif