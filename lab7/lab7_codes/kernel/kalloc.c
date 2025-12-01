#include "mm.h"
#include "printf.h"
#include "riscv.h"
#define FREE_MAGIC 0xDEADBEEF  // 魔数标记,不太可能随机出现的数值

// ==================== 物理内存分配器,管理真实的物理内存
// 管理方式：空闲页面链表
//页面1 -> 页面2 -> 页面3 -> ... -> NULL
// 空闲页面链表节点 - 利用空闲页面本身存储链表指针.空闲页面的内容无关紧要，可以被覆盖
//分配时清零整个页面，释放时在页面开头写入next指针
struct run {
    struct run *next;   // 指向下一个空闲页面，存储在页面的前8字节
};
// 1. 零存储开销：不需要额外的元数据结构
// 2. 就地管理：空闲页面的内容可以被覆盖，用来存储链表指针
// 3. 简单高效：单链表结构，O(1)分配和释放

// 内存管理器状态结构 - 全局唯一实例
struct {
    struct run *freelist;   // 空闲页面链表头指针 - LIFO栈结构
    uint64 total_pages;     // 系统总页面数 - 用于统计和调试
    uint64 free_pages;      // 当前空闲页面数 - 实时内存使用监控
} kmem;
/*初始化时：
遍历所有可用内存，每发现一个页面就调用free_page()
free_page()会增加free_pages计数器
同时增加total_pages计数器

运行时维护：
每次alloc_page()成功时：free_pages减1
每次free_page()时：free_pages加1
total_pages保持不变*/

// ==================== 工具函数实现 ====================
// 简单的memset实现 
// 用途：页面清零、安全擦除等
/*如果程序错误地访问已释放的页面，会读到全是1的数据
这种异常的数据模式很容易被发现，有助于调试
如果不填充，程序可能读到看似正常的旧数据，bug很难发现*/
void* memset(void *dst, int c, uint n) {
    char *cdst = (char*)dst;
    int i;
    // 逐字节填充，实现简单可靠
    for(i = 0; i < n; i++) {
        cdst[i] = c;
    }
    return dst;
}
void* memcpy(void *dst, const void *src, uint n) {
    char *cdst = (char*)dst;
    const char *csrc = (const char*)src;
    
    // 逐字节复制
    for(uint i = 0; i < n; i++) {
        cdst[i] = csrc[i];
    }
    
    return dst;
}
// ==================== 初始化物理内存分配器 ====================
void pmm_init(void) {
    // 第一步：确定可分配内存范围
    // 内存布局: [内核代码+数据] [可分配区域] [内存结束]
    //          ^end           ^mem_start    ^PHYSTOP
    char *mem_start = (char*)PGROUNDUP((uint64)end);  // 内核结束后的第一个页面边界
    char *mem_end = (char*)PHYSTOP;                   // 物理内存结束位置
    
    // 第二步：初始化管理器状态
    kmem.freelist = 0;      // 空链表
    kmem.total_pages = 0;   // 计数器清零
    kmem.free_pages = 0;
    
    printf("PMM: Initializing memory from %p to %p\n", mem_start, mem_end);
    
    // 第三步：构建空闲页面链表
    // 遍历所有可用页面，逐个加入空闲链表
    char *p;
    for(p = mem_start; p + PGSIZE <= mem_end; p += PGSIZE) {
        // 为什么要清零？确保页面内容干净，避免信息泄露
        memset(p, 0, PGSIZE);
        // 调用free_page将页面加入链表，复用释放逻辑
        free_page(p);
        kmem.total_pages++;   // 统计总页面数
    }
    
    printf("PMM: Initialized %d pages (%d KB)\n", 
           (int)kmem.total_pages, (int)(kmem.total_pages * PGSIZE) / 1024);
}

// ==================== 分配一个物理页面 ====================
// 算法特点：LIFO(后进先出)，最近释放的页面优先被分配
// 时间复杂度：O(1) - 仅涉及链表头操作
void* alloc_page(void) {
    struct run *r;
    
    // 从链表头取出一个空闲页面
    r = kmem.freelist;
    if(r) {
        // 更新链表头指向下一个空闲页面
        kmem.freelist = r->next;
        kmem.free_pages--;      // 更新空闲页面计数
        
        // 安全措施：清零分配的页面，防止信息泄露
        // 确保新分配的页面内容是干净的
        memset((char*)r, 0, PGSIZE);
    }
    // 如果r为NULL，表示内存耗尽，返回NULL
    
    return (void*)r;
}

// ==================== 释放一个物理页面 ====================  
// 算法特点：将页面插入链表头，实现LIFO释放
// 时间复杂度：O(1) - 仅涉及链表头操作
void free_page(void* pa) {
    struct run *r;
    
    // 第一步：地址有效性检查
    // 检查页面对齐：物理地址必须是4KB的整数倍
    if(((uint64)pa % PGSIZE) != 0)
        panic("free_page: not page aligned");
    
    // 检查地址范围：必须在可管理的内存范围内
    // 防止释放内核代码/数据区域或超出物理内存的地址
    if((char*)pa < end || (uint64)pa >= PHYSTOP)
        panic("free_page: invalid address");

     // 检查是否已经释放过.在释放的页面中放置一个特殊的标记，下次释放时检查这个标记。
    uint32 *magic_ptr = (uint32*)pa;
    if(*magic_ptr == FREE_MAGIC) {
        panic("free_page: double free detected");
    }
    
    // 填充魔数而不是全部填1
    *magic_ptr = FREE_MAGIC;
    // 第二步：安全擦除页面内容
    // 填充特殊值(1)有助于检测use-after-free错误
    // 如果程序试图使用已释放的页面，会读到异常的数据模式
    // 其余部分仍然填1
    memset((char*)pa + 4, 1, PGSIZE - 4);
    
    // 第三步：将页面插入空闲链表头部
    r = (struct run*)pa;        // 将页面地址转换为链表节点
    r->next = kmem.freelist;    // 新节点指向当前链表头
    kmem.freelist = r;          // 更新链表头为新节点
    kmem.free_pages++;          // 更新空闲页面计数
}

// ==================== 内存使用信息统计 ====================
// 用途：调试、监控、性能分析
void pmm_info(void) {
    printf("Memory Info:\n");
    printf("  Total pages: %d (%d KB)\n", 
           (int)kmem.total_pages, (int)(kmem.total_pages * PGSIZE) / 1024);
    printf("  Free pages:  %d (%d KB)\n", 
           (int)kmem.free_pages, (int)(kmem.free_pages * PGSIZE) / 1024);
    printf("  Used pages:  %d (%d KB)\n", 
           (int)(kmem.total_pages - kmem.free_pages), 
           (int)((kmem.total_pages - kmem.free_pages) * PGSIZE) / 1024);
}
