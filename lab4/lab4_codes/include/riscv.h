#ifndef RISCV_H
#define RISCV_H

#include "types.h"

// UART基地址
#define UART0 0x10000000L

// 读写satp寄存器的内联汇编函数
static inline uint64 r_satp() {
    uint64 x;
    asm volatile("csrr %0, satp" : "=r" (x));
    return x;
}

static inline void w_satp(uint64 x) {
    asm volatile("csrw satp, %0" : : "r" (x));
}

// sfence.vma指令 - 刷新TLB
static inline void sfence_vma() {
    asm volatile("sfence.vma zero, zero");
}

// 其他常用CSR寄存器
static inline uint64 r_mhartid() {
    uint64 x;
    asm volatile("csrr %0, mhartid" : "=r" (x));
    return x;
}

static inline uint64 r_mstatus() {
    uint64 x;
    asm volatile("csrr %0, mstatus" : "=r" (x));
    return x;
}

static inline void w_mstatus(uint64 x) {
    asm volatile("csrw mstatus, %0" : : "r" (x));
}

// 获取当前栈指针
static inline uint64 r_sp() {
    uint64 x;
    asm volatile("mv %0, sp" : "=r" (x));
    return x;
}
// ==================== 更多CSR寄存器操作 ====================

// mstatus寄存器
#define MSTATUS_MPP_MASK (3L << 11)
#define MSTATUS_MPP_M    (3L << 11)
#define MSTATUS_MPP_S    (1L << 11)
#define MSTATUS_MPP_U    (0L << 11)
#define MSTATUS_MIE      (1L << 3)

// sstatus寄存器  
#define SSTATUS_SPP (1L << 8)  // Previous mode (1=Supervisor, 0=User)
#define SSTATUS_SIE (1L << 1)  // Supervisor Interrupt Enable

// 中断使能寄存器 (sie/mie)
#define SIE_SEIE (1L << 9)  // 外部中断
#define SIE_STIE (1L << 5)  // 时钟中断
#define SIE_SSIE (1L << 1)  // 软件中断

#define MIE_MEIE (1L << 11)
#define MIE_MTIE (1L << 7)
#define MIE_MSIE (1L << 3)

static inline uint64 r_sstatus() {
    uint64 x;
    asm volatile("csrr %0, sstatus" : "=r" (x));
    return x;
}

static inline void w_sstatus(uint64 x) {
    asm volatile("csrw sstatus, %0" : : "r" (x));
}

static inline uint64 r_sie() {
    uint64 x;
    asm volatile("csrr %0, sie" : "=r" (x));
    return x;
}

static inline void w_sie(uint64 x) {
    asm volatile("csrw sie, %0" : : "r" (x));
}

static inline uint64 r_sip() {
    uint64 x;
    asm volatile("csrr %0, sip" : "=r" (x));
    return x;
}

static inline void w_sip(uint64 x) {
    asm volatile("csrw sip, %0" : : "r" (x));
}

static inline uint64 r_scause() {
    uint64 x;
    asm volatile("csrr %0, scause" : "=r" (x));
    return x;
}

static inline uint64 r_sepc() {
    uint64 x;
    asm volatile("csrr %0, sepc" : "=r" (x));
    return x;
}

static inline void w_sepc(uint64 x) {
    asm volatile("csrw sepc, %0" : : "r" (x));
}

static inline uint64 r_stval() {
    uint64 x;
    asm volatile("csrr %0, stval" : "=r" (x));
    return x;
}

static inline uint64 r_stvec() {
    uint64 x;
    asm volatile("csrr %0, stvec" : "=r" (x));
    return x;
}

static inline void w_stvec(uint64 x) {
    asm volatile("csrw stvec, %0" : : "r" (x));
}

// Machine模式寄存器
static inline void w_mepc(uint64 x) {
    asm volatile("csrw mepc, %0" : : "r" (x));
}

static inline void w_medeleg(uint64 x) {
    asm volatile("csrw medeleg, %0" : : "r" (x));
}

static inline void w_mideleg(uint64 x) {
    asm volatile("csrw mideleg, %0" : : "r" (x));
}

static inline void w_mie(uint64 x) {
    asm volatile("csrw mie, %0" : : "r" (x));
}

static inline uint64 r_mie() {
    uint64 x;
    asm volatile("csrr %0, mie" : "=r" (x));
    return x;
}

static inline void w_mtvec(uint64 x) {
    asm volatile("csrw mtvec, %0" : : "r" (x));
}

static inline void w_mscratch(uint64 x) {
    asm volatile("csrw mscratch, %0" : : "r" (x));
}

static inline void w_pmpaddr0(uint64 x) {
    asm volatile("csrw pmpaddr0, %0" : : "r" (x));
}

static inline void w_pmpcfg0(uint64 x) {
    asm volatile("csrw pmpcfg0, %0" : : "r" (x));
}

static inline uint64 r_time() {
    uint64 x;
    asm volatile("csrr %0, time" : "=r" (x));
    return x;
}

static inline void w_tp(uint64 x) {
    asm volatile("mv tp, %0" : : "r" (x));
}
static inline uint64 r_tp() {
    uint64 x;
    asm volatile("mv %0, tp" : "=r" (x));
    return x;
}
#endif