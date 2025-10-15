// kernel/uart.h
#ifndef _UART_H
#define _UART_H

// 初始化UART
void uart_init(void);

// 发送一个字符
void uart_putc(char c);

// 发送字符串
void uart_puts(const char *s);

// 接收一个字符（阻塞）
char uart_getc(void);

// 检查是否有字符可读
int uart_has_input(void);

#endif
