# user/initcode.S - 最简单版本

#define SYS_exit 2

.text
.globl _start
_start:
    li a0, 42
    li a7, SYS_exit
    ecall
    j _start