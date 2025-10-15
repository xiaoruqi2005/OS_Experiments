// kernel/start.c
#include "types.h"
#include "riscv.h"
#include "defs.h"

// entry.S 需要的启动栈
// __attribute__ ((aligned (16))) 确保栈地址是16字节对齐的
__attribute__ ((aligned (16))) char stack0[4096];

// M-mode下的启动函数
// entry.S 会跳转到这里
void start()
{
  // 设置 mstatus 寄存器，将之前的权限模式设置为 Supervisor
  // 这样，MRET 指令将会把权限级别切换到 S-mode
  unsigned long x = r_mstatus();
  x &= ~0x1800; // 清除 MSTATUS_MPP 字段 (bits 11, 12)
  x |= 0x800;   // 设置 MSTATUS_MPP 为 S-mode (Supervisor)
  w_mstatus(x);

  // 设置 mepc (Machine Exception Program Counter) 为 main 函数的地址
  // MRET 指令执行时，CPU会跳转到 mepc 指定的地址
  w_mepc((uint64)main);

  // 禁用分页。我们将在 S-mode 中由操作系统自己来启用和管理分页
  w_satp(0);

  // 将所有中断和异常委托给 S-mode 处理。
  // 这是让操作系统内核接管系统的关键一步。
  w_medeleg(0xffff);
  w_mideleg(0xffff);
  
  // 配置 PMP (Physical Memory Protection)，允许 S-mode 访问所有物理内存
  // 如果没有这一步，内核在访问 end 符号后的内存时会触发异常
  w_pmpaddr0(0x3fffffffffffffull); // 匹配所有地址
  w_pmpcfg0(0xf); // 授予读(R)、写(W)、执行(X)权限

  // 执行 mret 指令，切换到 Supervisor 模式并跳转到 main 函数
  asm volatile("mret");
}
