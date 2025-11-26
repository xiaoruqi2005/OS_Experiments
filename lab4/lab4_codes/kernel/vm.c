#include "mm.h"
#include "defs.h"
#include "riscv.h"
//虚拟内存映射器 (vm.c)作用：建立虚拟地址到物理地址的翻译表**
//三级页表结构，
//39位虚拟地址 = VPN[2] + VPN[1] + VPN[0] + offset
//                 9位    9位     9位     12位(页面大小 = 4KB = 4096字节 = 2^12字节)
//页表 = 数组[512个条目]
//每个条目 = "虚拟页号 -> 物理页号 + 权限"
// 全局内核页表指针 - 存储内核虚拟内存映射的根页表
pagetable_t kernel_pagetable;

// 创建一个新的页表
// 返回值：成功返回页表指针，失败返回0
// 设计要点：页表本身就是一个4KB的物理页面，包含512个64位页表项
pagetable_t create_pagetable(void) {
    // 分配一个物理页面作为页表存储空间
    // 关键理解：页表也存储在物理内存中，是普通的数据结构
    pagetable_t pagetable = (pagetable_t)alloc_page();
    if(pagetable == 0)
        return 0;
    
    // 页表已在alloc_page中清零
    // 重要：新页表所有PTE初始值为0，即所有页表项都无效(V位=0)
    return pagetable;
}

// 递归释放页表及其子页表
// 参数：pagetable - 要释放的页表根节点
// 设计要点：三级页表结构需要递归释放，避免内存泄漏
static void freewalk(pagetable_t pagetable) {
    // 遍历512个页表项 - 每个页表页面包含512个64位PTE
    // 计算依据：4KB页面 ÷ 8字节PTE = 512个条目，需要9位索引
    for(int i = 0; i < 512; i++) {
        pte_t pte = pagetable[i];
        if(pte & PTE_V) {  // 检查有效位，只处理有效的页表项
            // 关键判断：区分中间级页表项和叶子页表项
            // 中间级页表项：R/W/X位全为0，指向下一级页表
            // 叶子页表项：至少有一个R/W/X位为1，指向最终物理页面
            if((pte & (PTE_R|PTE_W|PTE_X)) == 0) {
                // 这是中间级页表项，需要递归释放子页表
                uint64 child = PTE_PA(pte);  // 提取子页表的物理地址
                freewalk((pagetable_t)child);  // 递归释放子页表
                pagetable[i] = 0;  // 清除页表项，避免悬挂指针
            }
            // 注意：叶子页表项指向的物理页面不在这里释放，由上层管理
        }
    }
    // 释放当前页表占用的物理页面
    free_page((void*)pagetable);
}

// 销毁页表 - 公共接口，包含空指针检查
void destroy_pagetable(pagetable_t pagetable) {
    if(pagetable == 0)
        return;
    freewalk(pagetable);
}

// 页表遍历 - 查找模式(不创建新页表)
// 参数：pagetable - 根页表，va - 虚拟地址
// 返回值：指向最终PTE的指针，如果路径不存在返回0
// 用途：查找现有映射，不修改页表结构
pte_t* walk_lookup(pagetable_t pagetable, uint64 va) {
    // Sv39地址空间限制检查：39位虚拟地址，最大512GB
    // 超出范围的地址是非法的，直接panic
    if(va >= (1L << 39))
        panic("walk_lookup: va too large");
    
    // 三级页表遍历：level 2→1→0，对应VPN[2]→VPN[1]→VPN[0]
    // 地址分解：bits[38:30] | bits[29:21] | bits[20:12] | bits[11:0]
    //          VPN[2]      | VPN[1]      | VPN[0]      | offset
    for(int level = 2; level > 0; level--) {
        // PX宏提取指定级别的9位索引：(va >> (12+9*level)) & 0x1FF
        pte_t *pte = &pagetable[PX(level, va)];
        if(*pte & PTE_V) {  // 页表项有效，继续遍历下一级
            // 提取子页表物理地址，转换为页表指针继续遍历
            pagetable = (pagetable_t)PTE_PA(*pte);
        } else {
            // 遇到无效页表项，查找失败
            // 查找模式不创建页表，直接返回失败
            return 0;
        }
    }
    // 返回最终级别(level=0)的页表项指针
    return &pagetable[PX(0, va)];
}

// 页表遍历 - 创建模式(必要时创建新页表)
// 与walk_lookup的区别：遇到无效页表项时会创建新的中间页表
// 用途：建立新的虚拟地址映射
pte_t* walk_create(pagetable_t pagetable, uint64 va) {
    // 相同的地址范围检查
    if(va >= (1L << 39))
        panic("walk_create: va too large");
    
    // 相同的三级遍历逻辑
    for(int level = 2; level > 0; level--) {
        pte_t *pte = &pagetable[PX(level, va)];
        if(*pte & PTE_V) {
            // 页表项有效，继续遍历
            pagetable = (pagetable_t)PTE_PA(*pte);
        } else {
            // 关键差异：创建缺失的中间页表
            // 需要创建新的页表来完成映射路径
            pagetable = (pagetable_t)alloc_page();
            if(pagetable == 0)
                return 0;  // 内存分配失败，映射失败
            // 设置新创建的页表项：物理地址+有效位
// 注意：中间级页表项不设置R/W/X位，只设置V位
//R/W/X全为0表示这是指向下级页表的指针
//只有叶子节点才设置R/W/X位表示最终的内存权限
            *pte = PA2PTE(pagetable) | PTE_V;
        }
    }
    return &pagetable[PX(0, va)];
}

// 映射单个页面 - 建立VA到PA的映射关系
// 参数：pagetable-页表，va-虚拟地址，pa-物理地址，perm-权限位
// 返回值：成功返回0，失败返回-1
int map_page(pagetable_t pagetable, uint64 va, uint64 pa, int perm) {
    // 地址对齐检查：虚拟地址和物理地址都必须页面对齐(4KB边界)
    // 原因：MMU按页面操作，页表项只存储页号，不存储页内偏移
    if(va % PGSIZE != 0)
        panic("map_page: va not page aligned");
    if(pa % PGSIZE != 0)
        panic("map_page: pa not page aligned");
    
    // 获取或创建到达目标虚拟地址的页表项
    pte_t *pte = walk_create(pagetable, va);
    if(pte == 0)
        return -1;  // 页表创建失败(通常是内存不足)
    
    // 检查重复映射：如果页表项已有效，说明该虚拟地址已被映射
    // 重复映射通常是程序错误，应该panic而不是静默覆盖
    if(*pte & PTE_V)
        panic("map_page: page already mapped");
    
    // 设置页表项：物理地址+权限位+有效位
    // PA2PTE：将物理地址转换为PTE格式(右移12位得到页号，左移10位到正确位置)
    // perm：包含R/W/X/U等权限位的组合
    // PTE_V：有效位，表示该映射有效
    *pte = PA2PTE(pa) | perm | PTE_V;
    return 0;
}

// 映射一个内存区域 - 批量建立连续的页面映射
// 参数：va,pa-起始地址，size-大小，perm-权限
// 用途：映射大块内存区域，如内核代码段、数据段等
int map_region(pagetable_t pagetable, uint64 va, uint64 pa, uint64 size, int perm) {
    uint64 a, last;
    
    if(size == 0)
        return 0;  // 零大小区域，直接成功
    
    // 地址对齐：确保映射从页边界开始和结束
    // PGROUNDDOWN：向下对齐到页边界，确保不遗漏任何页面
    a = PGROUNDDOWN(va);
    last = PGROUNDDOWN(va + size - 1);  // 最后一页的起始地址
    
    // 逐页建立映射，虚拟地址和物理地址同步递增
    // 这实现了恒等映射(identity mapping)：VA = PA
    for(;;) {
        if(map_page(pagetable, a, pa, perm) != 0)
            return -1;  // 某页映射失败，整个区域映射失败
        if(a == last)
            break;  // 映射完最后一页，结束
        a += PGSIZE;   // 移动到下一个虚拟页面
        pa += PGSIZE;  // 移动到下一个物理页面
    }
    return 0;
}

// 初始化内核页表 - 建立内核虚拟内存布局
// 作用：创建内核运行所需的虚拟地址映射
void kvminit(void) {
    // 创建内核根页表
    kernel_pagetable = create_pagetable();
    if(kernel_pagetable == 0)
        panic("kvminit: create_pagetable failed");
    
    printf("Setting up kernel page table...\n");
    
    // 映射内核代码段 (只读+可执行)
    // 权限设计：代码段只能读取和执行，不能写入，防止代码被意外修改
    // 地址范围：从KERNBASE到etext符号(链接脚本定义的代码段结束)
    printf("Mapping kernel text: %p - %p\n", (void*)KERNBASE, etext);
    if(map_region(kernel_pagetable, KERNBASE, KERNBASE, 
                  (uint64)etext - KERNBASE, PTE_R | PTE_X) != 0)
        panic("kvminit: map kernel text failed");
    
    // 映射内核数据段 (读写)
    // 权限设计：数据段需要读写权限，用于全局变量、堆栈等
    // 地址范围：从etext到PHYSTOP，包含数据段、BSS段、堆等
    printf("Mapping kernel data: %p - %p\n", etext, (void*)PHYSTOP);
    if(map_region(kernel_pagetable, (uint64)etext, (uint64)etext,
                  PHYSTOP - (uint64)etext, PTE_R | PTE_W) != 0)
        panic("kvminit: map kernel data failed");
    
    // 映射UART设备 (读写，非可执行)
    // 设备映射特点：
    // 1. 读写权限：需要访问设备寄存器
    // 2. 非可执行：防止意外执行设备内存内容
    // 3. 内核专用：没有PTE_U位，用户态无法访问
    printf("Mapping UART: %p\n", (void*)UART0);
    if(map_region(kernel_pagetable, UART0, UART0, PGSIZE, PTE_R | PTE_W) != 0)
        panic("kvminit: map UART failed");
    
    printf("Kernel page table setup complete\n");
}

// 激活内核页表 - 启用虚拟内存
// 作用：切换CPU从物理地址模式到虚拟地址模式
void kvminithart(void) {
    // 写入satp寄存器激活页表
    // MAKE_SATP：构造satp寄存器值，包含模式(Sv39)和根页表物理地址
    // satp格式：MODE[63:60] | ASID[59:44] | PPN[43:0]
    // MODE=8表示Sv39模式，PPN是根页表的物理页号
    w_satp(MAKE_SATP(kernel_pagetable));
    
    // 刷新TLB - 清除旧的地址翻译缓存
    // 原因：启用新页表后，旧的TLB条目无效，必须清除
    // sfence.vma：RISC-V指令，刷新所有TLB条目
    sfence_vma();
    
    printf("Virtual memory enabled!\n");
}

// 调试用：打印页表内容
// 参数：pagetable-要打印的页表，level-当前层级(用于递归)
// 用途：调试页表结构，查看映射关系
void dump_pagetable(pagetable_t pagetable, int level) {
    if(level > 2) return;  // 防止无限递归，Sv39最多3级
    
    printf("Page table at level %d:\n", level);
    int count = 0;
    // 遍历当前页表的所有512个条目
    for(int i = 0; i < 512; i++) {
        pte_t pte = pagetable[i];
        if(pte & PTE_V) {  // 只显示有效的页表项
            printf("  [%d]: %p", i, (void*)pte);  // 显示索引和完整PTE值
            // 解析并显示权限位
            if(pte & PTE_R) printf(" R");  // 可读
            if(pte & PTE_W) printf(" W");  // 可写
            if(pte & PTE_X) printf(" X");  // 可执行
            printf(" -> PA %p\n", (void*)PTE_PA(pte));  // 显示指向的物理地址
            count++;
            if(count > 10) {  // 限制输出数量，避免屏幕刷屏
                printf("  ... (more entries)\n");
                break;
            }
        }
    }
}

// 简单的软件权限检查
int check_page_permission(uint64 addr, int access_type) {
    // 查找页表项
    pte_t *pte = walk_lookup(kernel_pagetable, addr);
    
    if(pte == 0 || !(*pte & PTE_V)) {
        printf("Permission check: Address %p not mapped\n", (void*)addr);
        return 0;  // 地址未映射
    }
    
    // 检查权限
    if((access_type & ACCESS_READ) && !(*pte & PTE_R)) {
        printf("Permission check: No read permission for %p\n", (void*)addr);
        return 0;
    }
    
    if((access_type & ACCESS_WRITE) && !(*pte & PTE_W)) {
        printf("Permission check: No write permission for %p\n", (void*)addr);
        return 0;
    }
    
    if((access_type & ACCESS_EXEC) && !(*pte & PTE_X)) {
        printf("Permission check: No execute permission for %p\n", (void*)addr);
        return 0;
    }
    
    return 1;  // 权限检查通过
}