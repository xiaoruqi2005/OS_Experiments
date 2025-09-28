// kernel/uart.c
#include "uart.h"

// UART寄存器基地址（QEMU virt机器的默认地址）
#define UART_BASE 0x10000000

// 寄存器偏移量
#define UART_RHR 0    // 接收保持寄存器（读）
#define UART_THR 0    // 发送保持寄存器（写）
#define UART_IER 1    // 中断使能寄存器
#define UART_FCR 2    // FIFO控制寄存器
#define UART_LCR 3    // 线路控制寄存器
#define UART_LSR 5    // 线路状态寄存器

// 寄存器访问宏
#define REG(r) (*(volatile unsigned char *)(UART_BASE + r))

// LSR寄存器位定义
#define LSR_RX_READY (1 << 0)   // 接收数据就绪
#define LSR_TX_READY (1 << 5)   // 发送保持寄存器空

void uart_init(void) {
    // 禁用中断
    REG(UART_IER) = 0x00;
    
    // 设置线路控制：8位数据，无奇偶校验，1位停止位
    REG(UART_LCR) = 0x03;
    
    // 启用FIFO，清空FIFO
    REG(UART_FCR) = 0x01;
}

void uart_putc(char c) {
    // 等待发送缓冲区为空
    while ((REG(UART_LSR) & LSR_TX_READY) == 0);
    
    // 发送字符
    REG(UART_THR) = c;
    
    // 如果发送的是换行符，额外发送回车符（\r）
    if (c == '\n') {
        uart_putc('\r');
    }
}

void uart_puts(const char *s) {
    while (*s) {
        uart_putc(*s++);
    }
}

char uart_getc(void) {
    // 等待直到有数据可读
    while ((REG(UART_LSR) & LSR_RX_READY) == 0);
    
    // 读取字符
    return REG(UART_RHR);
}

int uart_has_input(void) {
    // 检查是否有数据可读
    return (REG(UART_LSR) & LSR_RX_READY) != 0;
}


