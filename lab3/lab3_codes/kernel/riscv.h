// kernel/riscv.h
#ifndef __ASSEMBLER__

// Machine Status Register, mstatus
static inline uint64 r_mstatus() {
  uint64 x;
  asm volatile("csrr %0, mstatus" : "=r" (x) );
  return x;
}
static inline void w_mstatus(uint64 x) {
  asm volatile("csrw mstatus, %0" : : "r" (x));
}

// M Exception Program Counter, mepc
static inline void w_mepc(uint64 x) {
  asm volatile("csrw mepc, %0" : : "r" (x));
}

// Machine Exception Delegation, medeleg
static inline void w_medeleg(uint64 x) {
  asm volatile("csrw medeleg, %0" : : "r" (x));
}

// Machine Interrupt Delegation, mideleg
static inline void w_mideleg(uint64 x) {
  asm volatile("csrw mideleg, %0" : : "r" (x));
}

// Physical Memory Protection Address, pmpaddr0
static inline void w_pmpaddr0(uint64 x) {
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
}

// Physical Memory Protection Configuration, pmpcfg0
static inline void w_pmpcfg0(uint64 x) {
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
}

// Supervisor Address Translation and Protection, satp
static inline void w_satp(uint64 x) {
  asm volatile("csrw satp, %0" : : "r" (x));
}

// Flush TLB
static inline void sfence_vma() {
  asm volatile("sfence.vma zero, zero");
}

#endif // __ASSEMBLER__

#define PGSIZE 4096 // bytes per page
#define PGSHIFT 12  // bits of offset within a page

#define PGROUNDUP(sz)  (((sz)+PGSIZE-1) & ~(PGSIZE-1))
#define PGROUNDDOWN(a) (((a)) & ~(PGSIZE-1))

#define PTE_V (1L << 0) // valid
#define PTE_R (1L << 1) // Read
#define PTE_W (1L << 2) // Write
#define PTE_X (1L << 3) // Execute
#define PTE_U (1L << 4) // user can access

#define PA2PTE(pa) ((((uint64)pa) >> 12) << 10)
#define PTE2PA(pte) (((pte) >> 10) << 12)
#define PTE_FLAGS(pte) ((pte) & 0x3FF)

#define PXMASK          0x1FF // 9 bits
#define PXSHIFT(level)  (PGSHIFT+(9*(level)))
#define PX(level, va) ((((uint64) (va)) >> PXSHIFT(level)) & PXMASK)

#define SATP_SV39 (8L << 60)
#define MAKE_SATP(pagetable) (SATP_SV39 | (((uint64)pagetable) >> 12))
