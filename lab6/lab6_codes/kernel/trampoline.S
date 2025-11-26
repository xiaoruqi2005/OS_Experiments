# kernel/trampoline.S - 修正版 trampoline/uservec/userret

.section trampsec, "ax"
.globl trampoline
.globl uservec
.globl userret
.align 4

trampoline:
# ==================== 从用户态进入内核：uservec ====================
# 入口时：
#   satp = 用户页表
#   sepc = 触发异常/中断的用户 PC
#   sscratch = 内核事先写入的 TRAPFRAME 虚拟地址
#   sp = 用户栈指针
#
# 目标：
#   1. 用 TRAPFRAME 保存所有寄存器和 sepc/sstatus
#   2. 从 TRAPFRAME 读出 kernel_satp/kernel_sp/kernel_trap
#   3. 切换到内核页表 + 内核栈
#   4. 跳转到 usertrap()（内核 C 函数）

uservec:
    # 交换 sp 和 sscratch：
    #   sp      <- TRAPFRAME 虚拟地址
    #   sscratch<- 用户 sp
    csrrw sp, sscratch, sp

    # 保存通用寄存器到 TRAPFRAME（和 struct trapframe 完全一致）
    sd ra, 0(sp)
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

    # 保存「原用户 sp」到 trapframe.sp（偏移 8）
    csrr t0, sscratch
    sd t0, 8(sp)

    # 保存 sepc / sstatus 到 trapframe
    csrr t1, sepc
    sd t1, 248(sp)
    csrr t2, sstatus
    sd t2, 256(sp)

    # =====⭐ 关键：在切 satp 之前，从 TRAPFRAME 读出内核信息 =====
    # 264: kernel_satp
    # 272: kernel_sp
    # 280: kernel_trap
    ld t0, 264(sp)      # t0 = kernel_satp
    ld t1, 272(sp)      # t1 = kernel_sp
    ld t2, 280(sp)      # t2 = kernel_trap

    # 切换到内核页表
    csrw satp, t0
    sfence.vma zero, zero

    # 切换到内核栈，跳到 usertrap()
    mv sp, t1
    jr t2

# ==================== 返回用户态：userret ====================
# C 端调用方式：
#   ((void(*)(uint64, uint64))trampoline_userret)(TRAPFRAME, satp);
#
# 约定：
#   a0 = TRAPFRAME 虚拟地址
#   a1 = 用户页表对应的 satp

userret:
    # ⭐ 调试：在还使用内核页表时输出标记（此时 UART 已映射）
    li t0, 0x10000000
    li t1, 'U'
    sb t1, 0(t0)
    li t1, 'R'
    sb t1, 0(t0)
    li t1, 'E'
    sb t1, 0(t0)
    li t1, 'T'
    sb t1, 0(t0)
    li t1, '\n'
    sb t1, 0(t0)

    # 切换到用户页表
    csrw satp, a1
    sfence.vma zero, zero

    # ⭐ 切页表后不要再访问 UART（用户页表未映射 UART）

    # 设置 sscratch = TRAPFRAME 虚拟地址
    csrw sscratch, a0

    # 恢复 sepc 和 sstatus（从 trapframe）
    ld t0, 248(a0)
    csrw sepc, t0

    ld t0, 256(a0)
    csrw sstatus, t0

    # 恢复通用寄存器（除了 a0 最后再恢复）
    ld ra, 0(a0)
    ld sp, 8(a0)
    ld gp, 16(a0)
    ld tp, 24(a0)
    ld t0, 32(a0)
    ld t1, 40(a0)
    ld t2, 48(a0)
    ld s0, 56(a0)
    ld s1, 64(a0)
    ld a1, 80(a0)
    ld a2, 88(a0)
    ld a3, 96(a0)
    ld a4, 104(a0)
    ld a5, 112(a0)
    ld a6, 120(a0)
    ld a7, 128(a0)
    ld s2, 136(a0)
    ld s3, 144(a0)
    ld s4, 152(a0)
    ld s5, 160(a0)
    ld s6, 168(a0)
    ld s7, 176(a0)
    ld s8, 184(a0)
    ld s9, 192(a0)
    ld s10, 200(a0)
    ld s11, 208(a0)
    ld t3, 216(a0)
    ld t4, 224(a0)
    ld t5, 232(a0)
    ld t6, 240(a0)

    # 最后恢复 a0（系统调用返回值等）
    ld a0, 72(a0)

    # sret 回到用户态，PC=sepc，模式=U
    sret
