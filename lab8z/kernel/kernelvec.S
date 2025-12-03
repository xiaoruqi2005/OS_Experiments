# kernel/kernelvec.S

.section .text
.global kernelvec
.align 4

kernelvec:
    # 在内核栈上开辟空间保存寄存器
    addi sp, sp, -256
    sd ra, 0(sp)
    sd sp, 8(sp)
    sd gp, 16(sp)
    sd tp, 24(sp)
    sd t0, 32(sp)
    sd t1, 40(sp)
    sd t2, 48(sp)
    sd s0, 56(sp)
    sd s1, 64(sp)
    sd a0, 72(sp)
    sd a1, 80(sp)
    sd a2, 88(sp)
    sd a3, 96(sp)
    sd a4, 104(sp)
    sd a5, 112(sp)
    sd a6, 120(sp)
    sd a7, 128(sp)
    sd s2, 136(sp)
    sd s3, 144(sp)
    sd s4, 152(sp)
    sd s5, 160(sp)
    sd s6, 168(sp)
    sd s7, 176(sp)
    sd s8, 184(sp)
    sd s9, 192(sp)
    sd s10, 200(sp)
    sd s11, 208(sp)
    sd t3, 216(sp)
    sd t4, 224(sp)
    sd t5, 232(sp)
    sd t6, 240(sp)

    # 调用 C 语言的陷阱处理函数，将栈指针作为参数传递
    mv a0, sp
    call kerneltrap

    # 恢复寄存器
    ld ra, 0(sp)
    ld gp, 16(sp)
    ld tp, 24(sp)
    ld t0, 32(sp)
    ld t1, 40(sp)
    ld t2, 48(sp)
    ld s0, 56(sp)
    ld s1, 64(sp)
    ld a0, 72(sp)
    ld a1, 80(sp)
    ld a2, 88(sp)
    ld a3, 96(sp)
    ld a4, 104(sp)
    ld a5, 112(sp)
    ld a6, 120(sp)
    ld a7, 128(sp)
    ld s2, 136(sp)
    ld s3, 144(sp)
    ld s4, 152(sp)
    ld s5, 160(sp)
    ld s6, 168(sp)
    ld s7, 176(sp)
    ld s8, 184(sp)
    ld s9, 192(sp)
    ld s10, 200(sp)
    ld s11, 208(sp)
    ld t3, 216(sp)
    ld t4, 224(sp)
    ld t5, 232(sp)
    ld t6, 240(sp)
    addi sp, sp, 256

    # 返回中断点
    sret

.global restore_trapframe
restore_trapframe:
    # a0: 指向 trapframe 的指针
    mv t6, a0
    
    # 恢复 sstatus (确保 SPP=0/1 正确)
    # 这里我们简化，假设总是返回 User (SPP=0) 或 Kernel thread (SPP=1)
    # 对于 main_task (S-mode)，我们需要 sstatus.SPP=1
    # 但由于 main_task 是通过 swtch -> proc_entry 启动的，不走 restore_trapframe
    # 只有 fork 的子进程返回用户态才走这里。
    
    csrr t0, sstatus
    li t1, 0x100 
    csrc sstatus, t1 # 清除 SPP (User Mode return)
    # 如果是内核线程通过 fork_ret 返回，需要在 C 代码中处理 sstatus
    
    ld t5, 24(t6)   # epc
    csrw sepc, t5
    
    ld ra, 40(t6)
    ld sp, 48(t6)
    ld gp, 56(t6)
    ld tp, 64(t6)
    ld t0, 72(t6)
    ld t1, 80(t6)
    ld t2, 88(t6)
    ld s0, 96(t6)
    ld s1, 104(t6)
    ld a0, 112(t6)
    ld a1, 120(t6)
    ld a2, 128(t6)
    ld a3, 136(t6)
    ld a4, 144(t6)
    ld a5, 152(t6)
    ld a6, 160(t6)
    ld a7, 168(t6)
    ld s2, 176(t6)
    ld s3, 184(t6)
    ld s4, 192(t6)
    ld s5, 200(t6)
    ld s6, 208(t6)
    ld s7, 216(t6)
    ld s8, 224(t6)
    ld s9, 232(t6)
    ld s10, 240(t6)
    ld s11, 248(t6)
    ld t3, 256(t6)
    ld t4, 264(t6)
    ld t5, 272(t6)
    ld t6, 280(t6)
    
    sret
