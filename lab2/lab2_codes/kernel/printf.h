// printf.h 
#ifndef _PRINTF_H_
#define _PRINTF_H_

#include <stdarg.h>

// 颜色定义
typedef enum {
    COLOR_BLACK = 0,
    COLOR_RED,
    COLOR_GREEN,
    COLOR_YELLOW,
    COLOR_BLUE,
    COLOR_MAGENTA,
    COLOR_CYAN,
    COLOR_WHITE,
    COLOR_RESET = 9
} color_t;

// 基础输出函数
void uart_putc(char c);
void uart_puts(const char *s);
int printf(const char *fmt, ...);

// 清屏功能
void clear_screen(void);
// 内部辅助函数
void print_number(int num, int base, int sign);

// 增强功能
void clear_line(void);
void goto_xy(int x, int y);
int printf_color(color_t color, const char *fmt, ...);

// 测试控制函数,方便展示测试用例
void wait_for_enter(int x);

#endif


