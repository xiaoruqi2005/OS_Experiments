// printf.c - 新增：完整的printf实现
#include "printf.h"
#include "uart.h"

// 数字字符表（支持16进制）
static char digits[] = "0123456789abcdef";

// 数字转换函数 - 支持十进制和十六进制
void print_number(int num, int base, int sign) {
    char buf[16];  // 缓冲区：32位整数最多11位（包括符号和结束符）
    int i = 0;
    unsigned int unum;
    int neg = 0;

    // 处理负数边界情况（特别是INT_MIN）
    if (sign && num < 0) {
        neg = 1;
        unum = (unsigned int)(-num);  // 转为无符号数处理，避免溢出
    } else {
        unum = (unsigned int)num;
    }

    // 特殊情况：数字为0
    if (unum == 0) {
        buf[i++] = '0';
    } else {
        // 数字转字符串（逆序存储）
        while (unum > 0) {
            buf[i++] = digits[unum % base];
            unum /= base;
        }
    }

    // 添加负号
    if (neg) {
        buf[i++] = '-';
    }

    // 逆序输出（因为转换时是逆序存储的）
    while (--i >= 0) {
        uart_putc(buf[i]);
    }
}

// 主格式化函数
int printf(const char *fmt, ...) {
    va_list ap;
    int i;
    
    va_start(ap, fmt);

    for (i = 0; fmt[i] != '\0'; i++) {
        // 普通字符直接输出
        if (fmt[i] != '%') {
            uart_putc(fmt[i]);
            continue;
        }

        // 遇到 '%'，解析格式符
        i++; // 跳过 '%'
        
        if (fmt[i] == '\0') {
            // 字符串以%结束，直接退出
            break;
        }
        
        // 处理格式符
        switch (fmt[i]) {
            case 'd': // 十进制有符号整数
                print_number(va_arg(ap, int), 10, 1);
                break;
                
            case 'u': // 十进制无符号整数
                print_number(va_arg(ap, int), 10, 0);
                break;
                
            case 'x': // 十六进制
                print_number(va_arg(ap, int), 16, 0);
                break;
                
            case 's': // 字符串
                {
                    char *s = va_arg(ap, char*);
                    if (s == 0) {
                        uart_puts("(null)");
                    } else {
                        uart_puts(s);
                    }
                }
                break;
                
            case 'c': // 字符
                uart_putc((char)va_arg(ap, int));
                break;
                
            case '%': // 百分号本身
                uart_putc('%');
                break;
                
            default: // 未知格式符
                uart_putc('%');
                uart_putc(fmt[i]);
                break;
        }
    }

    va_end(ap);
    return 0; // 返回输出的字符数（简化版返回0）
}

// 带颜色的printf
int printf_color(color_t color, const char *fmt, ...) {
    // 设置颜色
    printf("\033[3%dm", color);
    
    // 输出内容
    va_list ap;
    va_start(ap, fmt);
    
    for (int i = 0; fmt[i] != '\0'; i++) {
        if (fmt[i] != '%') {
            uart_putc(fmt[i]);
            continue;
        }

        i++;
        if (fmt[i] == '\0') break;
        
        switch (fmt[i]) {
            case 'd':
                print_number(va_arg(ap, int), 10, 1);
                break;
            case 'u':
                print_number(va_arg(ap, int), 10, 0);
                break;
            case 'x':
                print_number(va_arg(ap, int), 16, 0);
                break;
            case 's':
                {
                    char *s = va_arg(ap, char*);
                    if (s == 0) uart_puts("(null)");
                    else uart_puts(s);
                }
                break;
            case 'c':
                uart_putc((char)va_arg(ap, int));
                break;
            case '%':
                uart_putc('%');
                break;
            default:
                uart_putc('%');
                uart_putc(fmt[i]);
                break;
        }
    }
    
    va_end(ap);
    
    // 重置颜色
    printf("\033[0m");
    return 0;
}

// 清屏功能（使用ANSI转义序列）
void clear_screen(void) {
    uart_puts("\033[2J");    // 清屏
    uart_puts("\033[H");     // 光标回到左上角
}

// 清除当前行
void clear_line(void) {
    uart_puts("\033[2K");    // 清除整行
    uart_puts("\033[0G");    // 光标回到行首
}

// 光标定位
void goto_xy(int x, int y) {
    printf("\033[%d;%dH", y + 1, x + 1);
}

// 等待用户按回车,(专用于测试方便)
void wait_for_enter(int x) {
    if(x){
    printf_color(COLOR_YELLOW, "\n按回车键继续...");
    }
    
    // 清空输入缓冲区
    while (uart_has_input()) {
        uart_getc();
    }
    
    // 等待回车
    while (1) {
        if (uart_has_input()) {
            char c = uart_getc();
            if (c == '\r' || c == '\n') {
                uart_putc('\n');
                break;
            }
        }
    }
}
