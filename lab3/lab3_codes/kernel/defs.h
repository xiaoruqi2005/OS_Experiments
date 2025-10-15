// kernel/defs.h

#include "types.h"

// main.c
void main();

// uart.c
void uart_init(void);
void uart_putc(char);
void uart_puts(char*);

// printf.c
int printf(const char *fmt, ...);

// kalloc.c
void kinit();
void* kalloc(void);
void kfree(void*);

// vm.c
void kvminit(void);
void kvminithart(void);
int mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm);
pte_t* walk(pagetable_t pagetable, uint64 va, int alloc);
extern pagetable_t kernel_pagetable; // Declare the global kernel_pagetable

// string.c
void *memset(void *dst, int c, uint n);
