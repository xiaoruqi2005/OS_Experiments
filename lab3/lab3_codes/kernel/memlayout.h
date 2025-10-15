// kernel/memlayout.h
#define KERNBASE 0x80000000L
#define PHYSTOP (KERNBASE + 128*1024*1024) // QEMU默认提供128MB内存
#define UART0 0x10000000L
