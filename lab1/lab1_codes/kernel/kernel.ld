/* kernel.ld */
OUTPUT_ARCH("riscv")
ENTRY(_entry)

SECTIONS {
    . = 0x80000000;
    
    .text : {
        *(.text .text.*)
    }
    
    .rodata : {
        *(.rodata .rodata.*)
    }
    
    .data : {
        *(.data .data.*)
    }
    
    .bss : {
        _bss_start = .;
        *(.bss .bss.*)
        _end = .;
    }
}
