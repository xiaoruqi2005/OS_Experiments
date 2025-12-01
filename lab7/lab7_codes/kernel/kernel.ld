OUTPUT_ARCH(riscv)
ENTRY(_entry)

SECTIONS
{
  . = 0x80000000;

  /* 代码段 - 显式排除 trampsec */
  .text : {
    *(.text .text.*)
    . = ALIGN(0x1000);
  }

  PROVIDE(etext = .);

  /* 只读数据段 */
  .rodata : {
    . = ALIGN(16);
    *(.srodata .srodata.*)
    . = ALIGN(16);
    *(.rodata .rodata.*)
    . = ALIGN(0x1000);
  }

  /* 数据段 */
  .data : {
    *(.sdata .sdata.*)
    *(.data .data.*)
    . = ALIGN(0x1000);
  }

  PROVIDE(edata = .);

  /* BSS 段 */
  .bss : {
    PROVIDE(bss_start = .);
    *(.sbss .sbss.*)
    *(.bss .bss.*)
    *(COMMON)
    PROVIDE(bss_end = .);
  }

  . = ALIGN(0x1000);
  PROVIDE(end = .);

  /* ⭐ Trampoline - 强制页对齐，放在最后 */
  . = ALIGN(0x1000);
  .trampsec : AT(ADDR(.trampsec)) {
    *(.trampsec)
  }
  . = ALIGN(0x1000);

  /* 丢弃不需要的段 */
  /DISCARD/ : {
    *(.eh_frame)
    *(.note*)
    *(.comment)
  }
}