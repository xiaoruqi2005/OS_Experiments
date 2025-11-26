/* kernel/console.c - 控制台抽象层 */
// 这一层的职责：
// 1. 在printf和uart之间提供抽象
// 2. 字符预处理 - 特殊字符需要特殊处理。处理特殊字符（如退格）
// 3. 为将来扩展多种输出设备做准备
#include "types.h"
#include "defs.h"

#define BACKSPACE 0x100// 定义退格字符


// consputc()是一个适配器：
// - 上层(printf)期望简单的字符输出接口
// - 下层(uart)提供硬件特定的接口
// - console层负责适配和转换
void consputc(int c)
{
  if(c == BACKSPACE){
    // 退格处理：输出 退格-空格-退格 序列
     uartputc_sync('\b');   // 光标后退一位
     uartputc_sync(' ');    // 用空格覆盖字符  
     uartputc_sync('\b');   // 光标再后退一位
  } else {
    // 普通字符直接传递给硬件层
    uartputc_sync(c);
  }
}
/* 初始化函数 */
void consoleinit(void)
{
  uartinit();// 先初始化硬件层
  printfinit();    // 再初始化printf系统， printf系统依赖硬件工作
}
