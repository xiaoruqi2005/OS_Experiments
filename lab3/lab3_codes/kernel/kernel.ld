/* kernel.ld */
OUTPUT_ARCH("riscv")
ENTRY(_entry)

SECTIONS {
    . = 0x80000000;

    /* Read-only and executable section */
    .text : {
        *(.text .text.*)
        . = ALIGN(0x1000);
        PROVIDE(etext = .); /* Marks the end of the text section */
    }

    /* Read-only data section */
    .rodata : {
        . = ALIGN(16);
        *(.rodata .rodata.*)
    }

    /* Read-write data section */
    .data : {
        . = ALIGN(16);
        *(.data .data.*)
    }

    /* BSS section for uninitialized data */
    .bss : {
        . = ALIGN(16);
        *(.bss .bss.*)
        *(.sbss .sbss.*)
    }

    /* Define 'end' symbol at the very end of the kernel image */
    PROVIDE(_end = .);
}
