// kernel/start.c
#include "uart.h"

extern char _bss_start[], _end[];

void clear_bss(void) {
    for (char *p = _bss_start; p < _end; p++) {
        *p = 0;
    }
}

void start(void) {
    // 清零BSS段
    clear_bss();
    
    // 初始化串口
    uart_init();
    
    // 打印启动信息
    uart_puts("\n==================================\n");
    uart_puts("This is lab1!\n");
    uart_puts("Hello!\n");
    uart_puts("==================================\n\n");
    
    // 简单的回显测试
    uart_puts("Type something (echo test): ");
    
    // 主循环：回显用户输入
    while (1) {
        if (uart_has_input()) {
            char c = uart_getc();
            uart_putc(c); // 回显
            
            // 如果收到回车，换行
            if (c == '\r') {
                uart_putc('\n');
            }
        }
    }
}
