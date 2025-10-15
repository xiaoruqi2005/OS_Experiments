// kernel/kalloc.c
#include "types.h"
#include "memlayout.h"
#include "riscv.h"
#include "defs.h"

extern char _end[]; // 由链接脚本kernel.ld定义

struct run {
  struct run *next;
};

struct {
  struct run *freelist;
} kmem;

void kinit() {
  char *p = (char*)PGROUNDUP((uint64)_end);
  for(; p + PGSIZE <= (char*)PHYSTOP; p += PGSIZE) {
    kfree(p);
  }
}

void kfree(void *pa) {
  struct run *r;
  memset(pa, 1, PGSIZE);
  r = (struct run*)pa;
  r->next = kmem.freelist;
  kmem.freelist = r;
}

void* kalloc(void) {
  struct run *r;
  r = kmem.freelist;
  if(r)
    kmem.freelist = r->next;
  
  if(r)
    memset((char*)r, 5, PGSIZE);
  return (void*)r;
}
