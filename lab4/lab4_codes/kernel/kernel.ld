ENTRY(_start)

SECTIONS
{
    . = 0x80000000;
    
    .text : {
        *(.text.start)
        *(.text)
        . = ALIGN(0x1000);
        etext = .;
        PROVIDE(etext = .);
    }
    
    .rodata : {
        *(.rodata)
        . = ALIGN(0x1000);
    }
    
    .data : {
        *(.data)
        . = ALIGN(0x1000);
        edata = .;
        PROVIDE(edata = .);
    }
    
    .bss : {
        bss_start = .;
        *(.bss)
        bss_end = .;
        . = ALIGN(0x1000);
        end = .;
        PROVIDE(end = .);
    }
}