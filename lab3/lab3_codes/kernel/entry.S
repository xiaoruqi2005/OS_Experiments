# kernel/entry.S
.section .text
.global _entry
_entry:
    # 设置栈指针（在_end后分配4KB空间）
    la sp, stack0
    li a0, 4096
    add sp, sp, a0
    
    # 跳转到C入口函数
    call start

spin:
    j spin
