# kernel/entry.S
.section .text
.global _entry
_entry:
    # 设置栈指针（在_end后分配4KB空间）
    la sp, _end
    li t0, 4096
    add sp, sp, t0
    
    # 跳转到C入口函数
    call main

spin:
    j spin
