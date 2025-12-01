# kernel/timervec.S - 机器模式时钟中断处理

.globl timervec
.align 4
timervec:
    # 交换 a0 和 mscratch
    csrrw a0, mscratch, a0
    # 现在 a0 指向 timer_scratch 结构
    
    # 保存寄存器
    sd a1, 24(a0)
    sd a2, 32(a0)
    sd a3, 40(a0)
    
    # 读取当前 mtime
    li a1, 0x200bff8
    ld a2, 0(a1)
    
    # 加上时钟间隔
    ld a3, 0(a0)        # 读取 interval
    add a2, a2, a3      # next_time = mtime + interval
    sd a2, 8(a0)        # 保存 next_time
    
    # 设置 mtimecmp
    li a1, 0x2004000
    sd a2, 0(a1)
    
    # 触发 S 模式软件中断
    li a1, 2
    csrw sip, a1
    
    # 恢复寄存器
    ld a3, 40(a0)
    ld a2, 32(a0)
    ld a1, 24(a0)
    
    # 恢复 a0
    csrrw a0, mscratch, a0
    
    mret