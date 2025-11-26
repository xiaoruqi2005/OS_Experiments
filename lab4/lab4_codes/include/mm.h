#ifndef MM_H
#define MM_H

#include "types.h"

// ==================== 页面管理基础常量 ====================
// 页面大小和相关宏
// RISC-V标准页面大小为4KB，这是MMU硬件固定的最小内存管理单位
#define PGSIZE 4096                     // 4KB页面大小
#define PGSHIFT 12                      // log2(PGSIZE) = log2(4096) = 12，用于位运算优化

// 页面对齐宏 - 关键的地址对齐操作
// PGROUNDUP: 向上对齐到页边界 (例: 5000 -> 8192)
// 原理: 加上(PGSIZE-1)确保向上取整，然后用掩码清除低12位
#define PGROUNDUP(sz) (((sz)+PGSIZE-1) & ~(PGSIZE-1))
// PGROUNDDOWN: 向下对齐到页边界 (例: 5000 -> 4096)  
// 原理: 直接用掩码清除低12位，实现向下对齐
#define PGROUNDDOWN(a) (((a)) & ~(PGSIZE-1))

// ==================== 物理内存布局定义 ====================
// 这些地址定义了QEMU RISC-V virt平台的内存映射
#define KERNBASE 0x80000000             // 内核起始地址 - RISC-V约定的内核加载位置
#define PHYSTOP  0x88000000             // 物理内存结束地址(128MB) - 本实验的内存限制

// ==================== RISC-V Sv39页表相关定义 ====================
// SATP寄存器配置 - 用于启用和配置虚拟内存
// SATP格式: MODE[63:60] | ASID[59:44] | PPN[43:0]
#define SATP_SV39 (8L << 60)            // MODE=8表示Sv39模式(39位虚拟地址)
// 构造SATP寄存器值：模式位 | 页表物理页号
#define MAKE_SATP(pagetable) (SATP_SV39 | (((uint64)pagetable) >> 12))

// ==================== 虚拟地址分解宏 ====================
// Sv39地址结构: VPN[2](9位) | VPN[1](9位) | VPN[0](9位) | offset(12位)
//              bits[38:30]   bits[29:21]   bits[20:12]   bits[11:0]

// 9位掩码，用于提取页表索引 (2^9 = 512，每个页表有512个条目)
#define PXMASK 0x1FF                    // 0x1FF = 511 = 0b111111111 (9位全1)

// 计算各级页表索引的位移量
// level=0: PGSHIFT + 9*0 = 12 (VPN[0]起始位置)
// level=1: PGSHIFT + 9*1 = 21 (VPN[1]起始位置)  
// level=2: PGSHIFT + 9*2 = 30 (VPN[2]起始位置)
#define PXSHIFT(level) (PGSHIFT+(9*(level)))

// 从虚拟地址提取指定级别的9位页表索引
// 例: 对于va=0x123456789, level=2
// PX(2, va) = (0x123456789 >> 30) & 0x1FF = 提取VPN[2]
#define PX(level, va) ((((uint64) (va)) >> PXSHIFT(level)) & PXMASK)

// ==================== 页表项(PTE)标志位定义 ====================
// RISC-V页表项格式: PPN[43:10] | RSW[9:8] | D[7] | A[6] | G[5] | U[4] | X[3] | W[2] | R[1] | V[0]
/*PTE 页表项,是页表中的一个64位条目，包含：
PTE格式：[物理页号44位][保留10位][标志位10位]
标志位：D A G U X W R V
       │ │ │ │ │ │ │ └─ Valid(有效)
       │ │ │ │ │ │ └─── Read(可读)
       │ │ │ │ │ └───── Write(可写)
       │ │ │ │ └─────── Execute(可执行)
       │ │ │ └───────── User(用户态访问)
       └─┴─┴─────────── 其他标志位*/
#define PTE_V (1L << 0)     // 有效位 - 0:无效页表项, 1:有效页表项
#define PTE_R (1L << 1)     // 可读 - 允许读取访问
#define PTE_W (1L << 2)     // 可写 - 允许写入访问
#define PTE_X (1L << 3)     // 可执行 - 允许指令执行
#define PTE_U (1L << 4)     // 用户态可访问 - 0:仅内核态, 1:用户态也可访问

// ==================== 页表项地址转换宏 ====================
// 页表项中物理地址的提取和设置
// PTE格式中bits[53:10]存储物理页号(PPN)

// 从PTE提取物理地址: 右移10位去除标志位，左移12位得到字节地址
// 例: PTE=0x87fff001 -> (0x87fff001>>10)<<12 = 0x87fff000
#define PTE_PA(pte) (((pte) >> 10) << 12)

// 将物理地址转换为PTE格式: 右移12位得到页号，左移10位到正确位置
// 例: PA=0x87fff000 -> (0x87fff000>>12)<<10 = 0x21fffc00
#define PA2PTE(pa) ((((uint64)pa) >> 12) << 10)

// ==================== 数据类型定义 ====================
typedef uint64 pte_t;          // 页表项类型 - 64位无符号整数
typedef uint64* pagetable_t;    // 页表指针类型 - 指向64位整数数组

// ==================== 物理内存分配器接口 ====================
void pmm_init(void);                    // 初始化物理内存管理器
void* alloc_page(void);                 // 分配一个物理页 - O(1)时间复杂度
void free_page(void* page);             // 释放一个物理页 - O(1)时间复杂度  
void pmm_info(void);                    // 打印内存使用信息 - 调试用

// ==================== 页表管理接口 ====================
pagetable_t create_pagetable(void);     // 创建新页表 - 分配并清零一个页面
void destroy_pagetable(pagetable_t pt); // 销毁页表 - 递归释放所有子页表
int map_page(pagetable_t pt, uint64 va, uint64 pa, int perm); // 映射单个页面
pte_t* walk_create(pagetable_t pt, uint64 va); // 页表遍历(创建模式) - 创建缺失的中间页表
pte_t* walk_lookup(pagetable_t pt, uint64 va); // 页表遍历(查找模式) - 只查找不创建
void dump_pagetable(pagetable_t pt, int level); // 调试用页表打印

// ==================== 内核虚拟内存管理 ====================
void kvminit(void);                     // 初始化内核页表 - 建立恒等映射
void kvminithart(void);                 // 激活内核页表 - 设置satp寄存器并刷新TLB
int map_region(pagetable_t pt, uint64 va, uint64 pa, uint64 size, int perm); // 批量映射内存区域

// ==================== 工具函数 ====================
void* memset(void *dst, int c, uint n); // 内存填充函数 - 简化版标准库函数

// ==================== 外部符号(来自链接脚本) ====================
extern char etext[];    // 代码段结束位置 - 由链接脚本kernel.ld定义
extern char edata[];    // 数据段结束位置 - 分离代码和数据的边界
extern char end[];      // 内核结束位置 - 确定可用内存起始位置

// ==================== 全局变量声明 ====================
extern pagetable_t kernel_pagetable;    // 内核根页表 - 存储内核虚拟内存映射

// ==================== 测试函数声明 ====================
void run_comprehensive_tests(void);     // 运行完整的内存管理测试套件
void test_multilevel_pagetable(void);   // 测试多级页表映射功能
void test_edge_cases(void);             // 测试边界条件和错误处理

// 检查地址访问权限
int check_page_permission(uint64 addr, int access_type);

// 访问类型定义
#define ACCESS_READ  1
#define ACCESS_WRITE 2
#define ACCESS_EXEC  4

#endif