# kernel/entry.S

.section .text.entry
.global _start
.global __bss_start
.global __bss_end

_start:
    # --- DEBUG START: 裸机 UART 输出 ---
    # UART Base Address: 0x10000000
    li t0, 0x10000000 
    
    # UART LSR (Line Status Register) Offset: 5
    # UART THR (Transmit Holding Register) Offset: 0

uart_wait:
    # 检查 LSR 寄存器的 THRE (Transmit Holding Register Empty) 位 (第 5 位)
    lb t1, 5(t0) # t1 = *LSR
    li t2, 0x20  # 0x20 = 1 << 5
    and t1, t1, t2
    beqz t1, uart_wait # 如果 THRE 为 0, 继续等待
    
    # 输出 'A'
    li t1, 'A'
    sb t1, 0(t0) # *THR = 'A'
    # --- DEBUG END ---

    # 设置栈指针 (sp)。
    la sp, stack_top

    # 清零 BSS 段 
    la a0, __bss_start
    la a1, __bss_end

clear_bss_loop:
    bge a0, a1, clear_bss_done
    sd zero, 0(a0)
    addi a0, a0, 8
    j clear_bss_loop

clear_bss_done:
    # --- DEBUG START: BSS 清零完成 ---
    # 输出 'B'
    li t1, 'B'
    sb t1, 0(t0) 
    # --- DEBUG END ---

    # 调用C语言的主函数 kmain
    call kmain

halt:
    j halt

.section .bss
.align 16
stack_bottom:
.skip 4096
stack_top:
