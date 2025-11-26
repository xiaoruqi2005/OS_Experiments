# RISC-V OS Boot Assembly
.section .text.start
.globl _entry

_entry:
    # 设置栈指针
    li sp, 0x80010000
    
    # 输出启动标记
    li t0, 0x10000000    # UART基地址
    li t1, 'S'           # 启动标记
    sb t1, 0(t0)
    
    # 清零BSS段
    la t0, bss_start
    la t1, bss_end
    
clear_bss:
    bge t0, t1, call_start
    sb zero, 0(t0)
    addi t0, t0, 1
    j clear_bss

call_start:
    # 输出准备标记
    li t0, 0x10000000
    li t1, 'P'
    sb t1, 0(t0)
    
    # 跳转到start()在M模式初始化
    # start()会设置好中断委托，然后通过mret切换到S模式调用main()
    call start
    
    # 无限循环（不应该到达这里）
infinite_loop:
    j infinite_loop

# 栈空间定义
.section .bss
.align 12
stack_bottom:
.skip 8192  # 增加到8KB
stack_top: