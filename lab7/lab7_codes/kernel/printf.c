/* kernel/printf.c - 格式化输出实现 */

#include "types.h"
#include "defs.h"

volatile int panicking = 0;// 系统是否处于panic状态，正在处理崩溃
volatile int panicked = 0;// 系统是否已经panic完成，崩溃处理完成

static char digits[] = "0123456789abcdef";// 数字字符映射表

static void printint(long long xx, int base, int sign)
{
  char buf[20];               // 缓冲区：足够存储64位数字
  int i;                      // 缓冲区索引
  unsigned long long x;       // 无符号版本的数字
// 关键：x是unsigned类型！
// -(-2147483648) 在unsigned中是安全的

  // 处理负数
  if(sign && (sign = (xx < 0)))
    x = -xx; // 转为正数处理
  else
    x = xx;

//  多位数：提取每一位数字
  i = 0;
  do {
    buf[i++] = digits[x % base]; // 取余数，得到最低位
        // 关键：使用digits数组将数字映射为字符
        // 例如：x=42, base=10
        // 第一次：42 % 10 = 2 → buf[0] = '2'
        // 第二次：4 % 10 = 4 → buf[1] = '4' 
  } while((x /= base) != 0);// 整除，处理下一位
// 用do while而不是while,确保x=0时也能输出'0'
// 添加负号

  if(sign)
    buf[i++] = '-';
// 逆序输出（因为是从低位到高位提取的）
  while(--i >= 0)
    consputc(buf[i]);
}




static void printptr(uint64 x)
{
  int i;
  
  // 第1步：先输出"0x"前缀，表示这是十六进制地址
  consputc('0');
  consputc('x');
  
  // 第2步：循环输出地址的每一位十六进制数字
  // sizeof(uint64) * 2 = 8 * 2 = 16位十六进制数字
  // 64位地址需要16个十六进制字符来表示
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4) {
    // 每次取出最高4位来输出
    // x >> (sizeof(uint64) * 8 - 4) 就是 x >> 60
    // 这样每次都取最高的4位（一个十六进制数字）
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    // 然后 x <<= 4，把下一组4位移到最高位
  }
}

/* printf() - 格式字符串解析 */
int printf(char *fmt, ...)
{
  va_list ap;                 // 可变参数列表
  int i, cx, c0, c1, c2;      // 字符和索引变量
  char *s;                    // 字符串指针

  va_start(ap, fmt);          // 初始化参数列表
// 主循环：逐字符解析格式字符串
  for(i = 0; (cx = fmt[i] & 0xff) != 0; i++){
    if(cx != '%'){
      // 普通字符直接输出
      consputc(cx);
      continue;
    }
    // 遇到%，开始解析格式符
    i++;
    c0 = fmt[i+0] & 0xff;   // 格式符的第一个字符
    c1 = c2 = 0;
    if(c0) c1 = fmt[i+1] & 0xff;  // 可能的第二个字符（如%ld中的d）
    if(c1) c2 = fmt[i+2] & 0xff;  // 可能的第三个字符（如%lld中的第二个d）

    // 格式符处理 - 支持xv6的所有主要格式。普通字符直接输出，遇到%进入格式处理状态
    if(c0 == 'd') { 
       // %d - 32位有符号整数   
      printint(va_arg(ap, int), 10, 1);
    } else if(c0 == 'l' && c1 == 'd'){
      // %ld - 64位有符号整数
      printint(va_arg(ap, uint64), 10, 1);
      i += 1;// 跳过额外的字符
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
      // %lld - 64位有符号整数（与%ld相同，但为兼容性）
      printint(va_arg(ap, uint64), 10, 1);
      i += 2;// 跳过额外的字符
    } else if(c0 == 'u'){
      // %u - 32位无符号整数
      printint(va_arg(ap, uint32), 10, 0);
    } else if(c0 == 'l' && c1 == 'u'){
      printint(va_arg(ap, uint64), 10, 0);
      i += 1;
    } else if(c0 == 'x'){// %x - 32位十六进制
      printint(va_arg(ap, uint32), 16, 0);
    } else if(c0 == 'l' && c1 == 'x'){
      printint(va_arg(ap, uint64), 16, 0);
      i += 1;
    } else if(c0 == 'p'){// %p - 指针地址
      printptr(va_arg(ap, uint64));
    } else if(c0 == 'c'){// %c - 单个字符
      consputc(va_arg(ap, uint));
    } else if(c0 == 's'){// %s - 字符串
      // 第1步：从参数列表中取出字符串指针
      if((s = va_arg(ap, char*)) == 0)// 检查是否为NULL
        s = "(null)";// 如果是NULL，替换成安全的字符串
      // 第2步：逐字符输出
      for(; *s; s++)
        consputc(*s);
    } else if(c0 == '%'){// %% - 输出字面的%
      consputc('%');
    } else if(c0 == 0){
      break;
    } else {// 未知格式符 - 原样输出便于调试
      consputc('%');
      consputc(c0);
    }
  }
  va_end(ap);// 清理参数列表

  return 0;
}

void panic(char *s)
{
  // 第1步：设置全局标志，告诉其他部分"系统要崩溃了"
  panicking = 1;
  
  // 第2步：输出崩溃信息，让程序员知道出了什么问题
  printf("panic: ");        // 固定前缀，表示这是系统崩溃
  printf("%s\n", s);        // 输出具体的错误信息
  
  // 第3步：标记崩溃处理完成
  // 这时其他部分看到这个标志就知道不要再输出了
  panicked = 1;
  
  // 第4步：进入无限循环，让系统停止运行
  for(;;)
    ;  // 空循环，CPU在这里永远转圈
}

void printfinit(void)
{
  /* 简化版本，不需要锁初始化 */
}
