// kernel/vm.c
#include "types.h"
#include "memlayout.h"
#include "riscv.h"
#include "defs.h"

pagetable_t kernel_pagetable;
extern char etext[];

pte_t* walk(pagetable_t pagetable, uint64 va, int alloc) {
  for(int level = 2; level > 0; level--) {
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pagetable_t)kalloc()) == 0)
        return 0;
      memset(pagetable, 0, PGSIZE);
      *pte = PA2PTE(pagetable) | PTE_V;
    }
  }
  return &pagetable[PX(0, va)];
}

int mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm) {
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
  last = PGROUNDDOWN(va + size - 1);
  for(;;){
    if((pte = walk(pagetable, a, 1)) == 0)
      return -1;
    if(*pte & PTE_V)
      printf("mappages: remap\n");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
}

void kvminit(void) {
  kernel_pagetable = (pagetable_t) kalloc();
  memset(kernel_pagetable, 0, PGSIZE);

  mappages(kernel_pagetable, UART0, PGSIZE, UART0, PTE_R | PTE_W);
  mappages(kernel_pagetable, KERNBASE, (uint64)etext-KERNBASE, KERNBASE, PTE_R | PTE_X);
  mappages(kernel_pagetable, (uint64)etext, PHYSTOP-(uint64)etext, (uint64)etext, PTE_R | PTE_W);
}

void kvminithart() {
  w_satp(MAKE_SATP(kernel_pagetable));
  sfence_vma();
}
