/* kernel/screen.c - 屏幕控制功能。避免复杂的printf调用 */

#include "types.h"
#include "defs.h"

/* 清屏函数 */
void clear_screen(void)
{
  /* 直接输出ANSI转义序列，避免复杂的printf格式化 */
   // 发送ANSI转义序列：ESC[2J ESC[H
  consputc('\033');  /* ESC */
  consputc('[');// 开始ANSI序列
  consputc('2');     // 清屏命令参数
  consputc('J');     /* 清除整个屏幕 */
  consputc('\033');  /* ESC */
  consputc('[');
  consputc('H');     /* 光标回到左上角 */
}

/* 数字输出辅助函数 */
static void print_number(int num)
{
  if(num >= 10) {
    print_number(num / 10);// 递归处理高位
  }
  consputc('0' + (num % 10));// 输出当前位
}
// print_number(123) 的执行过程：
// 1. 123 >= 10，调用 print_number(12)
// 2. 12 >= 10，调用 print_number(1)  
// 3. 1 < 10，输出 '1'
// 4. 返回步骤2，输出 '2'
// 5. 返回步骤1，输出 '3'
// 结果：输出 "123"

/* 光标定位函数 */
void set_cursor(int x, int y)
{
  // 发送ANSI序列：ESC[y;xH
  consputc('\033');  /* ESC */
  consputc('[');
  print_number(y);// 行号
  consputc(';');     // 分隔符
  print_number(x);   // 列号  
  consputc('H');     // 定位命令，移动光标
}
// ESC[n;mH - 将光标移动到第n行第m列
// 例如：ESC[5;10H 移动到第5行第10列