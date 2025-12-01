#ifndef RISCV_H
#define RISCV_H

#include "types.h"

// ==================== sstatus 寄存器位定义 ====================
#define SSTATUS_SPP  (1L << 8)   // Previous mode (0=User, 1=Supervisor)
#define SSTATUS_SPIE (1L << 5)   // Supervisor Previous Interrupt Enable
#define SSTATUS_UPIE (1L << 4)   // User Previous Interrupt Enable
#define SSTATUS_SIE  (1L << 1)   // Supervisor Interrupt Enable
#define SSTATUS_UIE  (1L << 0)   // User Interrupt Enable

// ==================== sie 寄存器位定义 ====================
#define SIE_SEIE (1L << 9)  // Supervisor External Interrupt Enable
#define SIE_STIE (1L << 5)  // Supervisor Timer Interrupt Enable
#define SIE_SSIE (1L << 1)  // Supervisor Software Interrupt Enable

// ==================== mstatus 寄存器位定义 ====================
#define MSTATUS_MPP_MASK (3L << 11)
#define MSTATUS_MPP_M    (3L << 11)
#define MSTATUS_MPP_S    (1L << 11)
#define MSTATUS_MPP_U    (0L << 11)
#define MSTATUS_MIE      (1L << 3)

// ==================== mie 寄存器位定义 ====================
#define MIE_MEIE (1L << 11)  // Machine External Interrupt Enable
#define MIE_MTIE (1L << 7)   // Machine Timer Interrupt Enable
#define MIE_MSIE (1L << 3)   // Machine Software Interrupt Enable

// ==================== 页表相关 ====================
#define SATP_SV39 (8L << 60)
#define MAKE_SATP(pagetable) (SATP_SV39 | (((uint64)pagetable) >> 12))

// ==================== 页表项标志位 ====================
#define PTE_V (1L << 0)  // Valid
#define PTE_R (1L << 1)  // Readable
#define PTE_W (1L << 2)  // Writable
#define PTE_X (1L << 3)  // Executable
#define PTE_U (1L << 4)  // User accessible
#define PTE_G (1L << 5)  // Global
#define PTE_A (1L << 6)  // Accessed
#define PTE_D (1L << 7)  // Dirty

// ==================== 中断/异常原因码 ====================
#define IRQ_S_SOFT   1
#define IRQ_M_SOFT   3
#define IRQ_S_TIMER  5
#define IRQ_M_TIMER  7
#define IRQ_S_EXT    9
#define IRQ_M_EXT    11

// ==================== M 模式 CSR 寄存器读写 ====================

// 读 M 模式寄存器
#define r_mstatus()     ({ uint64 x; asm volatile("csrr %0, mstatus" : "=r"(x)); x; })
#define r_mhartid()     ({ uint64 x; asm volatile("csrr %0, mhartid" : "=r"(x)); x; })
#define r_mie()         ({ uint64 x; asm volatile("csrr %0, mie" : "=r"(x)); x; })
#define r_mip()         ({ uint64 x; asm volatile("csrr %0, mip" : "=r"(x)); x; })
#define r_mepc()        ({ uint64 x; asm volatile("csrr %0, mepc" : "=r"(x)); x; })
#define r_mcause()      ({ uint64 x; asm volatile("csrr %0, mcause" : "=r"(x)); x; })
#define r_mtval()       ({ uint64 x; asm volatile("csrr %0, mtval" : "=r"(x)); x; })
#define r_mtvec()       ({ uint64 x; asm volatile("csrr %0, mtvec" : "=r"(x)); x; })
#define r_mscratch()    ({ uint64 x; asm volatile("csrr %0, mscratch" : "=r"(x)); x; })

// 写 M 模式寄存器
#define w_mstatus(x)    asm volatile("csrw mstatus, %0" : : "r"(x))
#define w_mepc(x)       asm volatile("csrw mepc, %0" : : "r"(x))
#define w_mtvec(x)      asm volatile("csrw mtvec, %0" : : "r"(x))
#define w_medeleg(x)    asm volatile("csrw medeleg, %0" : : "r"(x))
#define w_mideleg(x)    asm volatile("csrw mideleg, %0" : : "r"(x))
#define w_mie(x)        asm volatile("csrw mie, %0" : : "r"(x))
#define w_mscratch(x)   asm volatile("csrw mscratch, %0" : : "r"(x))

// PMP (Physical Memory Protection) 寄存器
#define w_pmpcfg0(x)    asm volatile("csrw pmpcfg0, %0" : : "r"(x))
#define w_pmpaddr0(x)   asm volatile("csrw pmpaddr0, %0" : : "r"(x))

// ==================== S 模式 CSR 寄存器读写 ====================

// 读 S 模式寄存器
#define r_sstatus()     ({ uint64 x; asm volatile("csrr %0, sstatus" : "=r"(x)); x; })
#define r_sip()         ({ uint64 x; asm volatile("csrr %0, sip" : "=r"(x)); x; })
#define r_sie()         ({ uint64 x; asm volatile("csrr %0, sie" : "=r"(x)); x; })
#define r_scause()      ({ uint64 x; asm volatile("csrr %0, scause" : "=r"(x)); x; })
#define r_sepc()        ({ uint64 x; asm volatile("csrr %0, sepc" : "=r"(x)); x; })
#define r_stval()       ({ uint64 x; asm volatile("csrr %0, stval" : "=r"(x)); x; })
#define r_stvec()       ({ uint64 x; asm volatile("csrr %0, stvec" : "=r"(x)); x; })
#define r_satp()        ({ uint64 x; asm volatile("csrr %0, satp" : "=r"(x)); x; })
#define r_sscratch()    ({ uint64 x; asm volatile("csrr %0, sscratch" : "=r"(x)); x; })

// 写 S 模式寄存器
#define w_sstatus(x)    asm volatile("csrw sstatus, %0" : : "r"(x))
#define w_sip(x)        asm volatile("csrw sip, %0" : : "r"(x))
#define w_sie(x)        asm volatile("csrw sie, %0" : : "r"(x))
#define w_sepc(x)       asm volatile("csrw sepc, %0" : : "r"(x))
#define w_stvec(x)      asm volatile("csrw stvec, %0" : : "r"(x))
#define w_satp(x)       asm volatile("csrw satp, %0" : : "r"(x))
#define w_sscratch(x)   asm volatile("csrw sscratch, %0" : : "r"(x))

// ==================== 通用寄存器 ====================

// 读通用寄存器
#define r_tp()          ({ uint64 x; asm volatile("mv %0, tp" : "=r"(x)); x; })
#define r_sp()          ({ uint64 x; asm volatile("mv %0, sp" : "=r"(x)); x; })
#define r_ra()          ({ uint64 x; asm volatile("mv %0, ra" : "=r"(x)); x; })

// 写通用寄存器
#define w_tp(x)         asm volatile("mv tp, %0" : : "r"(x))

// ==================== 时间相关 ====================
#define r_time()        ({ uint64 x; asm volatile("csrr %0, time" : "=r"(x)); x; })

// ==================== 内存屏障 ====================
static inline void sfence_vma(void) {
    asm volatile("sfence.vma zero, zero");
}

static inline void fence_i(void) {
    asm volatile("fence.i");
}

// ==================== 等待中断 ====================
static inline void wfi(void) {
    asm volatile("wfi");
}

#endif