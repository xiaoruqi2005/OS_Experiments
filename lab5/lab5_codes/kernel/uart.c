/* kernel/uart.c - UART硬件驱动层 */
// 这一层的职责：直接与UART硬件打交道
// 为上层提供简单的字符输入输出接口

#include "types.h"
#include "defs.h"

/* UART寄存器定义 */
#define UART0 0x10000000L    // QEMU virt平台的UART基地址
// 寄存器访问宏
#define Reg(reg) ((volatile unsigned char *)(UART0 + (reg)))
#define ReadReg(reg) (*(Reg(reg)))
#define WriteReg(reg, v) (*(Reg(reg)) = (v))

/* 寄存器偏移 - 基于16550 UART标准 */
#define RHR 0    // Receive Holding Register - 读取接收到的数据
#define THR 0    // Transmit Holding Register - 发送数据（与RHR共享地址）
#define IER 1    // Interrupt Enable Register - 中断使能
#define FCR 2    // FIFO Control Register - FIFO控制
#define LCR 3    // Line Control Register - 线路控制
#define LSR 5    // Line Status Register - 线路状态
               

/* 位定义 */
#define IER_RX_ENABLE (1<<0)
#define IER_TX_ENABLE (1<<1)
#define FCR_FIFO_ENABLE (1<<0)
#define FCR_FIFO_CLEAR (3<<1)
#define LCR_EIGHT_BITS (3<<0)
#define LCR_BAUD_LATCH (1<<7)
#define LSR_RX_READY (1<<0)
#define LSR_TX_IDLE (1<<5)

/* 外部变量声明 */
extern volatile int panicking;
extern volatile int panicked;

void uartinit(void)
{
  // 1. 禁用所有中断（简化设计，使用轮询模式）
  WriteReg(IER, 0x00);
   // 2. 设置波特率为38400
  WriteReg(LCR, LCR_BAUD_LATCH);// 进入波特率设置模式
  WriteReg(0, 0x03);// 低字节
  WriteReg(1, 0x00);// 高字节
  // 3. 配置数据格式：8位数据，无校验位
  WriteReg(LCR, LCR_EIGHT_BITS);
  // 4. 启用并清空FIFO缓冲区
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
}

/* 同步字符输出 */
void uartputc_sync(int c)
{// 1. 检查系统是否panic
  if(panicked){
    for(;;)// 如果系统崩溃，停止输出
      ;
  }
 // 2. 等待发送寄存器空闲
 // 忙等待 - 轮询LSR寄存器的TX_IDLE位
// 这确保上一个字符发送完成后再发送新字符
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    ;
  // 3. 将字符写入发送寄存器
  WriteReg(THR, c);
  // 硬件会自动开始发送这个字符
}

int uartgetc(void)
{
  // 第1步：检查串口是否有数据可读
  // LSR_RX_READY 位表示"接收缓冲区有数据"
  if(ReadReg(LSR) & LSR_RX_READY) {
    
    // 第2步：如果有数据，从接收寄存器读取一个字符
    // RHR = Receive Holding Register (接收保持寄存器)
    return ReadReg(RHR);
    
  } else {
    
    // 第3步：如果没有数据，返回-1表示"没有数据"
    return -1;
  }
}
