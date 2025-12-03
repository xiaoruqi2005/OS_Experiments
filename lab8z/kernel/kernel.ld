/* kernel/kernel.ld */

OUTPUT_ARCH( "riscv" )
ENTRY( _start )

SECTIONS
{
  /*
   * QEMU 默认使用 OpenSBI，它会将内核跳转到 0x80200000 执行。
   */
  . = 0x80200000;

  .text : {
    *(.text .text.*)
    . = ALIGN(0x1000);
    _etext = .;         /* 定义代码段结束位置，供 vm.c 使用 */
    PROVIDE(etext = .); /* 兼容 C 语言的 extern char etext[] 声明 */
  }

  .rodata : {
    . = ALIGN(16);
    *(.srodata .srodata.*)
    . = ALIGN(16);
    *(.rodata .rodata.*)
  }

  .data : {
    . = ALIGN(16);
    *(.sdata .sdata.*)
    . = ALIGN(16);
    *(.data .data.*)
  }

  .bss : {
    . = ALIGN(16);
    __bss_start = .;    /* BSS 段开始，供 entry.S 清零使用 */
    *(.sbss .sbss.*)
    . = ALIGN(16);
    *(.bss .bss.*)
    __bss_end = .;      /* BSS 段结束 */
  }

  PROVIDE(end = .);     /* 定义物理内存分配的起始位置 (heap start) */
}
