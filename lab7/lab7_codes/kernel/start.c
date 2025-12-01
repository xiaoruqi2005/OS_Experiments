/* kernel/start.c - 简化版本 */

#include "types.h"
#include "defs.h"
#include "riscv.h"
#include "trap.h"

// 机器模式时钟中断向量
extern void timervec();

// 每个hart一个临时栈
__attribute__ ((aligned (16))) char m_stack0[4096];

void start()
{
    // 设置mstatus的MPP字段为Supervisor模式
    unsigned long x = r_mstatus();
    x &= ~MSTATUS_MPP_MASK;
    x |= MSTATUS_MPP_S;
    w_mstatus(x);

    // 设置mepc为main函数地址
    w_mepc((uint64)main);

    // 禁用S模式分页
    w_satp(0);

    // 配置中断委托
    w_medeleg(0xffff);
    w_mideleg((1 << IRQ_S_SOFT) | (1 << IRQ_S_TIMER) | (1 << IRQ_S_EXT));

    // 启用S模式中断
    w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);

    // 配置PMP
    w_pmpaddr0(0x3fffffffffffffull);
    w_pmpcfg0(0xf);

    // 配置M模式时钟中断
    timer_init_hart();

    // 设置M模式中断向量
    w_mtvec((uint64)timervec);

    // 启用M模式中断
    w_mstatus(r_mstatus() | MSTATUS_MIE);
    w_mie(r_mie() | MIE_MTIE);

    // 设置hart ID
    int id = r_mhartid();
    w_tp(id);

    // 切换到S模式
    asm volatile("mret");
}