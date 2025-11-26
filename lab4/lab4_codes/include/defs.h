#ifndef DEFS_H
#define DEFS_H

#include "types.h"

/* 可变参数支持 */
typedef __builtin_va_list va_list;
#define va_start(ap, last) __builtin_va_start(ap, last)
#define va_arg(ap, type) __builtin_va_arg(ap, type)
#define va_end(ap) __builtin_va_end(ap)
/* main.c - 主函数 */
void main(void);    // ← 添加这一行
/* uart.c - 硬件抽象层 */
void uartinit(void);        // 初始化UART硬件
void uartputc_sync(int c);  // 同步发送一个字符
int  uartgetc(void);        // 读取一个字符

/* console.c - 控制台抽象层 */
void consoleinit(void);    // 初始化控制台系统
void consputc(int c);      // 控制台字符输出（处理特殊字符）

/* printf.c - 格式化输出层 */
int  printf(char *fmt, ...);// 主printf函数
void panic(char *s);         // 系统崩溃处理
void printfinit(void);       // printf系统初始化

/* screen.c - 屏幕控制 */
void clear_screen(void);//清屏
void set_cursor(int x, int y);// 设置光标位置
/* trap.c - 中断处理 */
void trap_init(void);
void print_trap_stats(void);

/* timer.c - 时钟管理 */
void timer_init(void);
void timer_init_hart(void);
void timer_interrupt(void);
uint64 get_ticks(void);
uint64 get_uptime_seconds(void);
void delay_ms(uint64 ms);

/* start.c - M模式初始化 */
void start(void);
void sbi_set_timer(uint64 stime_value);
void sbi_shutdown(void);
/* trap.c - 中断处理 */
void trap_init(void);
void print_trap_stats(void);

/* exception_test.c - 异常测试 */
void test_exception_handling(void);  // ← 添加这一行
#endif