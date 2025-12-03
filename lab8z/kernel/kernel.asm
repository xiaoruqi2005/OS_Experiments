
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080200000 <_start>:
    80200000:	100002b7          	lui	t0,0x10000

0000000080200004 <uart_wait>:
    80200004:	00528303          	lb	t1,5(t0) # 10000005 <_start-0x701ffffb>
    80200008:	02000393          	li	t2,32
    8020000c:	00737333          	and	t1,t1,t2
    80200010:	fe030ae3          	beqz	t1,80200004 <uart_wait>
    80200014:	04100313          	li	t1,65
    80200018:	00628023          	sb	t1,0(t0)
    8020001c:	00021117          	auipc	sp,0x21
    80200020:	fe410113          	add	sp,sp,-28 # 80221000 <kmem>
    80200024:	00010517          	auipc	a0,0x10
    80200028:	fdc50513          	add	a0,a0,-36 # 80210000 <kernel_pagetable>
    8020002c:	00042597          	auipc	a1,0x42
    80200030:	df458593          	add	a1,a1,-524 # 80241e20 <__bss_end>

0000000080200034 <clear_bss_loop>:
    80200034:	00b55663          	bge	a0,a1,80200040 <clear_bss_done>
    80200038:	00053023          	sd	zero,0(a0)
    8020003c:	0521                	add	a0,a0,8
    8020003e:	bfdd                	j	80200034 <clear_bss_loop>

0000000080200040 <clear_bss_done>:
    80200040:	04200313          	li	t1,66
    80200044:	00628023          	sb	t1,0(t0)
    80200048:	39f000ef          	jal	80200be6 <kmain>

000000008020004c <halt>:
    8020004c:	a001                	j	8020004c <halt>

000000008020004e <cons_putc>:
// kernel/console.c
#include "defs.h"

// 控制台输出一个字符
// 目前它只是简单地调用 UART 驱动
void cons_putc(char c) {
    8020004e:	1141                	add	sp,sp,-16
    80200050:	e406                	sd	ra,8(sp)
    80200052:	e022                	sd	s0,0(sp)
    80200054:	0800                	add	s0,sp,16
    uart_putc(c);
    80200056:	00000097          	auipc	ra,0x0
    8020005a:	39a080e7          	jalr	922(ra) # 802003f0 <uart_putc>
}
    8020005e:	60a2                	ld	ra,8(sp)
    80200060:	6402                	ld	s0,0(sp)
    80200062:	0141                	add	sp,sp,16
    80200064:	8082                	ret

0000000080200066 <consolewrite>:

int consolewrite(int user_src, uint64 src, int n) {
    80200066:	7179                	add	sp,sp,-48
    80200068:	f406                	sd	ra,40(sp)
    8020006a:	f022                	sd	s0,32(sp)
    8020006c:	ec26                	sd	s1,24(sp)
    8020006e:	e84a                	sd	s2,16(sp)
    80200070:	e44e                	sd	s3,8(sp)
    80200072:	1800                	add	s0,sp,48
    80200074:	89b2                	mv	s3,a2
    (void)user_src;
    char *p = (char*)src;
    for (int i = 0; i < n; i++) {
    80200076:	00c05e63          	blez	a2,80200092 <consolewrite+0x2c>
    8020007a:	84ae                	mv	s1,a1
    8020007c:	00b60933          	add	s2,a2,a1
    uart_putc(c);
    80200080:	0004c503          	lbu	a0,0(s1)
    80200084:	00000097          	auipc	ra,0x0
    80200088:	36c080e7          	jalr	876(ra) # 802003f0 <uart_putc>
    for (int i = 0; i < n; i++) {
    8020008c:	0485                	add	s1,s1,1
    8020008e:	ff2499e3          	bne	s1,s2,80200080 <consolewrite+0x1a>
        cons_putc(p[i]);
    }
    return n;
}
    80200092:	854e                	mv	a0,s3
    80200094:	70a2                	ld	ra,40(sp)
    80200096:	7402                	ld	s0,32(sp)
    80200098:	64e2                	ld	s1,24(sp)
    8020009a:	6942                	ld	s2,16(sp)
    8020009c:	69a2                	ld	s3,8(sp)
    8020009e:	6145                	add	sp,sp,48
    802000a0:	8082                	ret

00000000802000a2 <consoleread>:

int consoleread(int user_dst, uint64 dst, int n) {
    802000a2:	1141                	add	sp,sp,-16
    802000a4:	e422                	sd	s0,8(sp)
    802000a6:	0800                	add	s0,sp,16
    (void)user_dst;
    (void)dst;
    (void)n;
    return -1;
    802000a8:	557d                	li	a0,-1
    802000aa:	6422                	ld	s0,8(sp)
    802000ac:	0141                	add	sp,sp,16
    802000ae:	8082                	ret

00000000802000b0 <print_int>:
#include <stdarg.h>
#include "defs.h"
#include "riscv.h" // 引入 riscv.h 以使用 uint64 类型

// 静态辅助函数，用于打印不同进制的数字。
static void print_int(long long xx, int base, int sign) {
    802000b0:	711d                	add	sp,sp,-96
    802000b2:	ec86                	sd	ra,88(sp)
    802000b4:	e8a2                	sd	s0,80(sp)
    802000b6:	e4a6                	sd	s1,72(sp)
    802000b8:	e0ca                	sd	s2,64(sp)
    802000ba:	1080                	add	s0,sp,96
    802000bc:	84aa                	mv	s1,a0
    802000be:	892e                	mv	s2,a1
    char digits[] = "0123456789abcdef";
    802000c0:	00006797          	auipc	a5,0x6
    802000c4:	f4078793          	add	a5,a5,-192 # 80206000 <_etext>
    802000c8:	6398                	ld	a4,0(a5)
    802000ca:	fce43423          	sd	a4,-56(s0)
    802000ce:	6798                	ld	a4,8(a5)
    802000d0:	fce43823          	sd	a4,-48(s0)
    802000d4:	0107c783          	lbu	a5,16(a5)
    802000d8:	fcf40c23          	sb	a5,-40(s0)
    char buf[32];
    int i = 0;
    unsigned long long x;

    if (sign && xx < 0) {
    802000dc:	c219                	beqz	a2,802000e2 <print_int+0x32>
    802000de:	06054263          	bltz	a0,80200142 <print_int+0x92>
        cons_putc('-');
        x = -xx;
    } else {
        x = xx;
    802000e2:	8526                	mv	a0,s1
static void print_int(long long xx, int base, int sign) {
    802000e4:	fa840693          	add	a3,s0,-88
    802000e8:	4701                	li	a4,0
    }

    do {
        buf[i++] = digits[x % base];
    802000ea:	863a                	mv	a2,a4
    802000ec:	2705                	addw	a4,a4,1
    802000ee:	032577b3          	remu	a5,a0,s2
    802000f2:	1781                	add	a5,a5,-32
    802000f4:	97a2                	add	a5,a5,s0
    802000f6:	fe87c783          	lbu	a5,-24(a5)
    802000fa:	00f68023          	sb	a5,0(a3)
    } while ((x /= base) != 0);
    802000fe:	87aa                	mv	a5,a0
    80200100:	03255533          	divu	a0,a0,s2
    80200104:	0685                	add	a3,a3,1
    80200106:	ff27f2e3          	bgeu	a5,s2,802000ea <print_int+0x3a>

    while (--i >= 0) {
    8020010a:	02064663          	bltz	a2,80200136 <print_int+0x86>
    8020010e:	fa840793          	add	a5,s0,-88
    80200112:	00c784b3          	add	s1,a5,a2
    80200116:	fff78913          	add	s2,a5,-1
    8020011a:	9932                	add	s2,s2,a2
    8020011c:	1602                	sll	a2,a2,0x20
    8020011e:	9201                	srl	a2,a2,0x20
    80200120:	40c90933          	sub	s2,s2,a2
        cons_putc(buf[i]);
    80200124:	0004c503          	lbu	a0,0(s1)
    80200128:	00000097          	auipc	ra,0x0
    8020012c:	f26080e7          	jalr	-218(ra) # 8020004e <cons_putc>
    while (--i >= 0) {
    80200130:	14fd                	add	s1,s1,-1
    80200132:	ff2499e3          	bne	s1,s2,80200124 <print_int+0x74>
    }
}
    80200136:	60e6                	ld	ra,88(sp)
    80200138:	6446                	ld	s0,80(sp)
    8020013a:	64a6                	ld	s1,72(sp)
    8020013c:	6906                	ld	s2,64(sp)
    8020013e:	6125                	add	sp,sp,96
    80200140:	8082                	ret
        cons_putc('-');
    80200142:	02d00513          	li	a0,45
    80200146:	00000097          	auipc	ra,0x0
    8020014a:	f08080e7          	jalr	-248(ra) # 8020004e <cons_putc>
        x = -xx;
    8020014e:	40900533          	neg	a0,s1
    80200152:	bf49                	j	802000e4 <print_int+0x34>

0000000080200154 <printf>:
        cons_putc(buf[i]);
    }
}

// 内核的 printf 函数本体
void printf(const char *fmt, ...) {
    80200154:	7131                	add	sp,sp,-192
    80200156:	fc86                	sd	ra,120(sp)
    80200158:	f8a2                	sd	s0,112(sp)
    8020015a:	f4a6                	sd	s1,104(sp)
    8020015c:	f0ca                	sd	s2,96(sp)
    8020015e:	ecce                	sd	s3,88(sp)
    80200160:	e8d2                	sd	s4,80(sp)
    80200162:	e4d6                	sd	s5,72(sp)
    80200164:	e0da                	sd	s6,64(sp)
    80200166:	fc5e                	sd	s7,56(sp)
    80200168:	f862                	sd	s8,48(sp)
    8020016a:	f466                	sd	s9,40(sp)
    8020016c:	f06a                	sd	s10,32(sp)
    8020016e:	0100                	add	s0,sp,128
    80200170:	e40c                	sd	a1,8(s0)
    80200172:	e810                	sd	a2,16(s0)
    80200174:	ec14                	sd	a3,24(s0)
    80200176:	f018                	sd	a4,32(s0)
    80200178:	f41c                	sd	a5,40(s0)
    8020017a:	03043823          	sd	a6,48(s0)
    8020017e:	03143c23          	sd	a7,56(s0)
    va_list args;
    char *s;
    int c;

    if (fmt == 0) {
    80200182:	20050463          	beqz	a0,8020038a <printf+0x236>
    80200186:	84aa                	mv	s1,a0
        return;
    }

    va_start(args, fmt);
    80200188:	00840793          	add	a5,s0,8
    8020018c:	f8f43c23          	sd	a5,-104(s0)
    for (c = *fmt; c != '\0'; c = *++fmt) {
    80200190:	00054503          	lbu	a0,0(a0)
    80200194:	1e050b63          	beqz	a0,8020038a <printf+0x236>
        if (c != '%') {
    80200198:	02500993          	li	s3,37
        }

        c = *++fmt;
        if (c == '\0') break;

        switch (c) {
    8020019c:	4bd1                	li	s7,20
    8020019e:	00006c17          	auipc	s8,0x6
    802001a2:	e96c0c13          	add	s8,s8,-362 # 80206034 <_etext+0x34>
                }
                break;
            // [新增] 支持 %l 前缀 (如 %ld, %lu)
            case 'l':
                c = *++fmt; // 获取 'l' 后面的字符
                if (c == 'd') {
    802001a6:	06400c93          	li	s9,100
    802001aa:	f8840a13          	add	s4,s0,-120
    802001ae:	f9840b13          	add	s6,s0,-104
        buf[i] = "0123456789abcdef"[x % 16];
    802001b2:	00006a97          	auipc	s5,0x6
    802001b6:	e4ea8a93          	add	s5,s5,-434 # 80206000 <_etext>
    802001ba:	a821                	j	802001d2 <printf+0x7e>
            cons_putc(c);
    802001bc:	00000097          	auipc	ra,0x0
    802001c0:	e92080e7          	jalr	-366(ra) # 8020004e <cons_putc>
            continue;
    802001c4:	8926                	mv	s2,s1
    for (c = *fmt; c != '\0'; c = *++fmt) {
    802001c6:	00190493          	add	s1,s2,1
    802001ca:	00194503          	lbu	a0,1(s2)
    802001ce:	1a050e63          	beqz	a0,8020038a <printf+0x236>
        if (c != '%') {
    802001d2:	ff3515e3          	bne	a0,s3,802001bc <printf+0x68>
        c = *++fmt;
    802001d6:	00148913          	add	s2,s1,1
    802001da:	0014cd03          	lbu	s10,1(s1)
        if (c == '\0') break;
    802001de:	1a0d0663          	beqz	s10,8020038a <printf+0x236>
        switch (c) {
    802001e2:	193d0363          	beq	s10,s3,80200368 <printf+0x214>
    802001e6:	f9cd079b          	addw	a5,s10,-100
    802001ea:	0ff7f793          	zext.b	a5,a5
    802001ee:	18fbe363          	bltu	s7,a5,80200374 <printf+0x220>
    802001f2:	f9cd079b          	addw	a5,s10,-100
    802001f6:	0ff7f713          	zext.b	a4,a5
    802001fa:	16ebed63          	bltu	s7,a4,80200374 <printf+0x220>
    802001fe:	00271793          	sll	a5,a4,0x2
    80200202:	97e2                	add	a5,a5,s8
    80200204:	439c                	lw	a5,0(a5)
    80200206:	97e2                	add	a5,a5,s8
    80200208:	8782                	jr	a5
                print_int(va_arg(args, int), 10, 1);
    8020020a:	f9843783          	ld	a5,-104(s0)
    8020020e:	00878713          	add	a4,a5,8
    80200212:	f8e43c23          	sd	a4,-104(s0)
    80200216:	4605                	li	a2,1
    80200218:	45a9                	li	a1,10
    8020021a:	4388                	lw	a0,0(a5)
    8020021c:	00000097          	auipc	ra,0x0
    80200220:	e94080e7          	jalr	-364(ra) # 802000b0 <print_int>
                break;
    80200224:	b74d                	j	802001c6 <printf+0x72>
                print_int(va_arg(args, int), 16, 0);
    80200226:	f9843783          	ld	a5,-104(s0)
    8020022a:	00878713          	add	a4,a5,8
    8020022e:	f8e43c23          	sd	a4,-104(s0)
    80200232:	4601                	li	a2,0
    80200234:	45c1                	li	a1,16
    80200236:	4388                	lw	a0,0(a5)
    80200238:	00000097          	auipc	ra,0x0
    8020023c:	e78080e7          	jalr	-392(ra) # 802000b0 <print_int>
                break;
    80200240:	b759                	j	802001c6 <printf+0x72>
                print_ptr(va_arg(args, uint64));
    80200242:	f9843783          	ld	a5,-104(s0)
    80200246:	00878713          	add	a4,a5,8
    8020024a:	f8e43c23          	sd	a4,-104(s0)
    8020024e:	6384                	ld	s1,0(a5)
    cons_putc('0');
    80200250:	03000513          	li	a0,48
    80200254:	00000097          	auipc	ra,0x0
    80200258:	dfa080e7          	jalr	-518(ra) # 8020004e <cons_putc>
    cons_putc('x');
    8020025c:	07800513          	li	a0,120
    80200260:	00000097          	auipc	ra,0x0
    80200264:	dee080e7          	jalr	-530(ra) # 8020004e <cons_putc>
    80200268:	87d2                	mv	a5,s4
        buf[i] = "0123456789abcdef"[x % 16];
    8020026a:	00f4f713          	and	a4,s1,15
    8020026e:	9756                	add	a4,a4,s5
    80200270:	00074703          	lbu	a4,0(a4)
    80200274:	00e78023          	sb	a4,0(a5)
        x /= 16;
    80200278:	8091                	srl	s1,s1,0x4
    for (i = 0; i < 16; i++) {
    8020027a:	0785                	add	a5,a5,1
    8020027c:	ff6797e3          	bne	a5,s6,8020026a <printf+0x116>
    80200280:	f9740493          	add	s1,s0,-105
        cons_putc(buf[i]);
    80200284:	0004c503          	lbu	a0,0(s1)
    80200288:	00000097          	auipc	ra,0x0
    8020028c:	dc6080e7          	jalr	-570(ra) # 8020004e <cons_putc>
    for (i = 15; i >= 0; i--) {
    80200290:	87a6                	mv	a5,s1
    80200292:	14fd                	add	s1,s1,-1
    80200294:	fefa18e3          	bne	s4,a5,80200284 <printf+0x130>
    80200298:	b73d                	j	802001c6 <printf+0x72>
                s = va_arg(args, char *);
    8020029a:	f9843783          	ld	a5,-104(s0)
    8020029e:	00878713          	add	a4,a5,8
    802002a2:	f8e43c23          	sd	a4,-104(s0)
    802002a6:	6384                	ld	s1,0(a5)
                if (s == 0) {
    802002a8:	cc89                	beqz	s1,802002c2 <printf+0x16e>
                while (*s != '\0') {
    802002aa:	0004c503          	lbu	a0,0(s1)
    802002ae:	dd01                	beqz	a0,802001c6 <printf+0x72>
                    cons_putc(*s++);
    802002b0:	0485                	add	s1,s1,1
    802002b2:	00000097          	auipc	ra,0x0
    802002b6:	d9c080e7          	jalr	-612(ra) # 8020004e <cons_putc>
                while (*s != '\0') {
    802002ba:	0004c503          	lbu	a0,0(s1)
    802002be:	f96d                	bnez	a0,802002b0 <printf+0x15c>
    802002c0:	b719                	j	802001c6 <printf+0x72>
                    s = "(null)";
    802002c2:	00006497          	auipc	s1,0x6
    802002c6:	d5648493          	add	s1,s1,-682 # 80206018 <_etext+0x18>
                while (*s != '\0') {
    802002ca:	02800513          	li	a0,40
    802002ce:	b7cd                	j	802002b0 <printf+0x15c>
                c = *++fmt; // 获取 'l' 后面的字符
    802002d0:	00248913          	add	s2,s1,2
    802002d4:	0024c483          	lbu	s1,2(s1)
    802002d8:	0004879b          	sext.w	a5,s1
                if (c == 'd') {
    802002dc:	03978c63          	beq	a5,s9,80200314 <printf+0x1c0>
                    print_int(va_arg(args, long), 10, 1);
                } else if (c == 'u') {
    802002e0:	07500713          	li	a4,117
    802002e4:	04e78663          	beq	a5,a4,80200330 <printf+0x1dc>
                    print_int(va_arg(args, long), 10, 0); // 无符号十进制
                } else if (c == 'x') {
    802002e8:	07800713          	li	a4,120
    802002ec:	06e78063          	beq	a5,a4,8020034c <printf+0x1f8>
                    print_int(va_arg(args, long), 16, 0);
                } else {
                    // 如果是不支持的格式，回退一点
                    cons_putc('%');
    802002f0:	02500513          	li	a0,37
    802002f4:	00000097          	auipc	ra,0x0
    802002f8:	d5a080e7          	jalr	-678(ra) # 8020004e <cons_putc>
                    cons_putc('l');
    802002fc:	06c00513          	li	a0,108
    80200300:	00000097          	auipc	ra,0x0
    80200304:	d4e080e7          	jalr	-690(ra) # 8020004e <cons_putc>
                    cons_putc(c);
    80200308:	8526                	mv	a0,s1
    8020030a:	00000097          	auipc	ra,0x0
    8020030e:	d44080e7          	jalr	-700(ra) # 8020004e <cons_putc>
    80200312:	bd55                	j	802001c6 <printf+0x72>
                    print_int(va_arg(args, long), 10, 1);
    80200314:	f9843783          	ld	a5,-104(s0)
    80200318:	00878713          	add	a4,a5,8
    8020031c:	f8e43c23          	sd	a4,-104(s0)
    80200320:	4605                	li	a2,1
    80200322:	45a9                	li	a1,10
    80200324:	6388                	ld	a0,0(a5)
    80200326:	00000097          	auipc	ra,0x0
    8020032a:	d8a080e7          	jalr	-630(ra) # 802000b0 <print_int>
    8020032e:	bd61                	j	802001c6 <printf+0x72>
                    print_int(va_arg(args, long), 10, 0); // 无符号十进制
    80200330:	f9843783          	ld	a5,-104(s0)
    80200334:	00878713          	add	a4,a5,8
    80200338:	f8e43c23          	sd	a4,-104(s0)
    8020033c:	4601                	li	a2,0
    8020033e:	45a9                	li	a1,10
    80200340:	6388                	ld	a0,0(a5)
    80200342:	00000097          	auipc	ra,0x0
    80200346:	d6e080e7          	jalr	-658(ra) # 802000b0 <print_int>
    8020034a:	bdb5                	j	802001c6 <printf+0x72>
                    print_int(va_arg(args, long), 16, 0);
    8020034c:	f9843783          	ld	a5,-104(s0)
    80200350:	00878713          	add	a4,a5,8
    80200354:	f8e43c23          	sd	a4,-104(s0)
    80200358:	4601                	li	a2,0
    8020035a:	45c1                	li	a1,16
    8020035c:	6388                	ld	a0,0(a5)
    8020035e:	00000097          	auipc	ra,0x0
    80200362:	d52080e7          	jalr	-686(ra) # 802000b0 <print_int>
    80200366:	b585                	j	802001c6 <printf+0x72>
                }
                break;
            case '%':
                cons_putc('%');
    80200368:	854e                	mv	a0,s3
    8020036a:	00000097          	auipc	ra,0x0
    8020036e:	ce4080e7          	jalr	-796(ra) # 8020004e <cons_putc>
                break;
    80200372:	bd91                	j	802001c6 <printf+0x72>
            default:
                // 打印未知的格式符
                cons_putc('%');
    80200374:	854e                	mv	a0,s3
    80200376:	00000097          	auipc	ra,0x0
    8020037a:	cd8080e7          	jalr	-808(ra) # 8020004e <cons_putc>
                cons_putc(c);
    8020037e:	856a                	mv	a0,s10
    80200380:	00000097          	auipc	ra,0x0
    80200384:	cce080e7          	jalr	-818(ra) # 8020004e <cons_putc>
                break;
    80200388:	bd3d                	j	802001c6 <printf+0x72>
        }
    }
    va_end(args);
}
    8020038a:	70e6                	ld	ra,120(sp)
    8020038c:	7446                	ld	s0,112(sp)
    8020038e:	74a6                	ld	s1,104(sp)
    80200390:	7906                	ld	s2,96(sp)
    80200392:	69e6                	ld	s3,88(sp)
    80200394:	6a46                	ld	s4,80(sp)
    80200396:	6aa6                	ld	s5,72(sp)
    80200398:	6b06                	ld	s6,64(sp)
    8020039a:	7be2                	ld	s7,56(sp)
    8020039c:	7c42                	ld	s8,48(sp)
    8020039e:	7ca2                	ld	s9,40(sp)
    802003a0:	7d02                	ld	s10,32(sp)
    802003a2:	6129                	add	sp,sp,192
    802003a4:	8082                	ret

00000000802003a6 <clear_screen>:

// 清屏函数
void clear_screen() {
    802003a6:	1101                	add	sp,sp,-32
    802003a8:	ec06                	sd	ra,24(sp)
    802003aa:	e822                	sd	s0,16(sp)
    802003ac:	e426                	sd	s1,8(sp)
    802003ae:	1000                	add	s0,sp,32
    const char *seq = "\033[2J\033[H";
    802003b0:	00006497          	auipc	s1,0x6
    802003b4:	c7048493          	add	s1,s1,-912 # 80206020 <_etext+0x20>
    while (*seq) {
    802003b8:	456d                	li	a0,27
        cons_putc(*seq++);
    802003ba:	0485                	add	s1,s1,1
    802003bc:	00000097          	auipc	ra,0x0
    802003c0:	c92080e7          	jalr	-878(ra) # 8020004e <cons_putc>
    while (*seq) {
    802003c4:	0004c503          	lbu	a0,0(s1)
    802003c8:	f96d                	bnez	a0,802003ba <clear_screen+0x14>
    }
}
    802003ca:	60e2                	ld	ra,24(sp)
    802003cc:	6442                	ld	s0,16(sp)
    802003ce:	64a2                	ld	s1,8(sp)
    802003d0:	6105                	add	sp,sp,32
    802003d2:	8082                	ret

00000000802003d4 <panic>:

void panic(const char *msg) {
    802003d4:	1141                	add	sp,sp,-16
    802003d6:	e406                	sd	ra,8(sp)
    802003d8:	e022                	sd	s0,0(sp)
    802003da:	0800                	add	s0,sp,16
    802003dc:	85aa                	mv	a1,a0
    printf("\npanic: %s\n", msg);
    802003de:	00006517          	auipc	a0,0x6
    802003e2:	c4a50513          	add	a0,a0,-950 # 80206028 <_etext+0x28>
    802003e6:	00000097          	auipc	ra,0x0
    802003ea:	d6e080e7          	jalr	-658(ra) # 80200154 <printf>
    while (1) { }
    802003ee:	a001                	j	802003ee <panic+0x1a>

00000000802003f0 <uart_putc>:
#define LSR_THRE (1 << 5)

/*
 * 发送一个字符到串口
 */
void uart_putc(char c) {
    802003f0:	1141                	add	sp,sp,-16
    802003f2:	e422                	sd	s0,8(sp)
    802003f4:	0800                	add	s0,sp,16
    // 循环等待，直到 THR 寄存器为空
    while ((*LSR & LSR_THRE) == 0);
    802003f6:	10000737          	lui	a4,0x10000
    802003fa:	00574783          	lbu	a5,5(a4) # 10000005 <_start-0x701ffffb>
    802003fe:	0207f793          	and	a5,a5,32
    80200402:	dfe5                	beqz	a5,802003fa <uart_putc+0xa>
    // 向 THR 写入要发送的字符
    *THR = c;
    80200404:	100007b7          	lui	a5,0x10000
    80200408:	00a78023          	sb	a0,0(a5) # 10000000 <_start-0x70200000>
}
    8020040c:	6422                	ld	s0,8(sp)
    8020040e:	0141                	add	sp,sp,16
    80200410:	8082                	ret

0000000080200412 <uart_puts>:

/*
 * 发送一个以 '\0' 结尾的字符串到串口
 */
void uart_puts(const char *s) {
    80200412:	1101                	add	sp,sp,-32
    80200414:	ec06                	sd	ra,24(sp)
    80200416:	e822                	sd	s0,16(sp)
    80200418:	e426                	sd	s1,8(sp)
    8020041a:	1000                	add	s0,sp,32
    8020041c:	84aa                	mv	s1,a0
    while (*s) {
    8020041e:	00054503          	lbu	a0,0(a0)
    80200422:	c909                	beqz	a0,80200434 <uart_puts+0x22>
        uart_putc(*s++);
    80200424:	0485                	add	s1,s1,1
    80200426:	00000097          	auipc	ra,0x0
    8020042a:	fca080e7          	jalr	-54(ra) # 802003f0 <uart_putc>
    while (*s) {
    8020042e:	0004c503          	lbu	a0,0(s1)
    80200432:	f96d                	bnez	a0,80200424 <uart_puts+0x12>
    }
    80200434:	60e2                	ld	ra,24(sp)
    80200436:	6442                	ld	s0,16(sp)
    80200438:	64a2                	ld	s1,8(sp)
    8020043a:	6105                	add	sp,sp,32
    8020043c:	8082                	ret

000000008020043e <kfree>:
        kfree(p);
    }
    printf("kinit: physical memory allocator initialized (with COW support).\n");
}

void kfree(void *pa) {
    8020043e:	1101                	add	sp,sp,-32
    80200440:	ec06                	sd	ra,24(sp)
    80200442:	e822                	sd	s0,16(sp)
    80200444:	e426                	sd	s1,8(sp)
    80200446:	e04a                	sd	s2,0(sp)
    80200448:	1000                	add	s0,sp,32
    8020044a:	892a                	mv	s2,a0
    struct run *r;

    if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= 0x88000000)
    8020044c:	03451793          	sll	a5,a0,0x34
    80200450:	eb99                	bnez	a5,80200466 <kfree+0x28>
    80200452:	00042797          	auipc	a5,0x42
    80200456:	9ce78793          	add	a5,a5,-1586 # 80241e20 <__bss_end>
    8020045a:	00f56663          	bltu	a0,a5,80200466 <kfree+0x28>
    8020045e:	47c5                	li	a5,17
    80200460:	07ee                	sll	a5,a5,0x1b
    80200462:	00f56a63          	bltu	a0,a5,80200476 <kfree+0x38>
        panic("kfree: invalid pa");
    80200466:	00006517          	auipc	a0,0x6
    8020046a:	c2250513          	add	a0,a0,-990 # 80206088 <_etext+0x88>
    8020046e:	00000097          	auipc	ra,0x0
    80200472:	f66080e7          	jalr	-154(ra) # 802003d4 <panic>

    acquire(&kmem.lock);
    80200476:	00021517          	auipc	a0,0x21
    8020047a:	b8a50513          	add	a0,a0,-1142 # 80221000 <kmem>
    8020047e:	00000097          	auipc	ra,0x0
    80200482:	3bc080e7          	jalr	956(ra) # 8020083a <acquire>
    if (pa < 0x80000000 || pa >= 0x88000000)
    80200486:	800004b7          	lui	s1,0x80000
    8020048a:	94ca                	add	s1,s1,s2
    8020048c:	080007b7          	lui	a5,0x8000
    80200490:	08f4f363          	bgeu	s1,a5,80200516 <kfree+0xd8>
    return (pa - 0x80000000) / PGSIZE;
    80200494:	80b1                	srl	s1,s1,0xc
    80200496:	2481                	sext.w	s1,s1
    int idx = pa2idx((uint64)pa);
    
    if (kmem.ref[idx] <= 0) {
    80200498:	00021797          	auipc	a5,0x21
    8020049c:	b6878793          	add	a5,a5,-1176 # 80221000 <kmem>
    802004a0:	97a6                	add	a5,a5,s1
    802004a2:	0207c783          	lbu	a5,32(a5)
    802004a6:	c3c9                	beqz	a5,80200528 <kfree+0xea>
        release(&kmem.lock);
        panic("kfree: ref <= 0");
    }

    kmem.ref[idx]--;
    802004a8:	00021717          	auipc	a4,0x21
    802004ac:	b5870713          	add	a4,a4,-1192 # 80221000 <kmem>
    802004b0:	9726                	add	a4,a4,s1
    802004b2:	02074783          	lbu	a5,32(a4)
    802004b6:	37fd                	addw	a5,a5,-1
    802004b8:	0ff7f793          	zext.b	a5,a5
    802004bc:	02f70023          	sb	a5,32(a4)

    // 只有引用计数归零时才真正释放回链表
    if (kmem.ref[idx] > 0) {
    802004c0:	e7c9                	bnez	a5,8020054a <kfree+0x10c>
        release(&kmem.lock);
        return;
    }
    release(&kmem.lock);
    802004c2:	00021517          	auipc	a0,0x21
    802004c6:	b3e50513          	add	a0,a0,-1218 # 80221000 <kmem>
    802004ca:	00000097          	auipc	ra,0x0
    802004ce:	462080e7          	jalr	1122(ra) # 8020092c <release>

    // 真正释放：填充垃圾数据
    memset(pa, 1, PGSIZE);
    802004d2:	6605                	lui	a2,0x1
    802004d4:	4585                	li	a1,1
    802004d6:	854a                	mv	a0,s2
    802004d8:	00000097          	auipc	ra,0x0
    802004dc:	4ca080e7          	jalr	1226(ra) # 802009a2 <memset>

    r = (struct run*)pa;

    acquire(&kmem.lock);
    802004e0:	00021517          	auipc	a0,0x21
    802004e4:	b2050513          	add	a0,a0,-1248 # 80221000 <kmem>
    802004e8:	00000097          	auipc	ra,0x0
    802004ec:	352080e7          	jalr	850(ra) # 8020083a <acquire>
    r->next = kmem.freelist;
    802004f0:	00021517          	auipc	a0,0x21
    802004f4:	b1050513          	add	a0,a0,-1264 # 80221000 <kmem>
    802004f8:	6d1c                	ld	a5,24(a0)
    802004fa:	00f93023          	sd	a5,0(s2)
    kmem.freelist = r;
    802004fe:	01253c23          	sd	s2,24(a0)
    release(&kmem.lock);
    80200502:	00000097          	auipc	ra,0x0
    80200506:	42a080e7          	jalr	1066(ra) # 8020092c <release>
}
    8020050a:	60e2                	ld	ra,24(sp)
    8020050c:	6442                	ld	s0,16(sp)
    8020050e:	64a2                	ld	s1,8(sp)
    80200510:	6902                	ld	s2,0(sp)
    80200512:	6105                	add	sp,sp,32
    80200514:	8082                	ret
        panic("pa2idx: invalid pa");
    80200516:	00006517          	auipc	a0,0x6
    8020051a:	b8a50513          	add	a0,a0,-1142 # 802060a0 <_etext+0xa0>
    8020051e:	00000097          	auipc	ra,0x0
    80200522:	eb6080e7          	jalr	-330(ra) # 802003d4 <panic>
    80200526:	b7bd                	j	80200494 <kfree+0x56>
        release(&kmem.lock);
    80200528:	00021517          	auipc	a0,0x21
    8020052c:	ad850513          	add	a0,a0,-1320 # 80221000 <kmem>
    80200530:	00000097          	auipc	ra,0x0
    80200534:	3fc080e7          	jalr	1020(ra) # 8020092c <release>
        panic("kfree: ref <= 0");
    80200538:	00006517          	auipc	a0,0x6
    8020053c:	b8050513          	add	a0,a0,-1152 # 802060b8 <_etext+0xb8>
    80200540:	00000097          	auipc	ra,0x0
    80200544:	e94080e7          	jalr	-364(ra) # 802003d4 <panic>
    80200548:	b785                	j	802004a8 <kfree+0x6a>
        release(&kmem.lock);
    8020054a:	00021517          	auipc	a0,0x21
    8020054e:	ab650513          	add	a0,a0,-1354 # 80221000 <kmem>
    80200552:	00000097          	auipc	ra,0x0
    80200556:	3da080e7          	jalr	986(ra) # 8020092c <release>
        return;
    8020055a:	bf45                	j	8020050a <kfree+0xcc>

000000008020055c <kinit>:
void kinit() {
    8020055c:	715d                	add	sp,sp,-80
    8020055e:	e486                	sd	ra,72(sp)
    80200560:	e0a2                	sd	s0,64(sp)
    80200562:	fc26                	sd	s1,56(sp)
    80200564:	f84a                	sd	s2,48(sp)
    80200566:	f44e                	sd	s3,40(sp)
    80200568:	f052                	sd	s4,32(sp)
    8020056a:	ec56                	sd	s5,24(sp)
    8020056c:	e85a                	sd	s6,16(sp)
    8020056e:	e45e                	sd	s7,8(sp)
    80200570:	e062                	sd	s8,0(sp)
    80200572:	0880                	add	s0,sp,80
    spinlock_init(&kmem.lock, "kmem");
    80200574:	00006597          	auipc	a1,0x6
    80200578:	b5458593          	add	a1,a1,-1196 # 802060c8 <_etext+0xc8>
    8020057c:	00021517          	auipc	a0,0x21
    80200580:	a8450513          	add	a0,a0,-1404 # 80221000 <kmem>
    80200584:	00000097          	auipc	ra,0x0
    80200588:	254080e7          	jalr	596(ra) # 802007d8 <spinlock_init>
    memset(kmem.ref, 0, sizeof(kmem.ref));
    8020058c:	6621                	lui	a2,0x8
    8020058e:	4581                	li	a1,0
    80200590:	00021517          	auipc	a0,0x21
    80200594:	a9050513          	add	a0,a0,-1392 # 80221020 <kmem+0x20>
    80200598:	00000097          	auipc	ra,0x0
    8020059c:	40a080e7          	jalr	1034(ra) # 802009a2 <memset>
    p = (char*)PGROUNDUP((uint64)end);
    802005a0:	00043497          	auipc	s1,0x43
    802005a4:	87f48493          	add	s1,s1,-1921 # 80242e1f <__bss_end+0xfff>
    802005a8:	77fd                	lui	a5,0xfffff
    802005aa:	8cfd                	and	s1,s1,a5
    for(; p + PGSIZE <= (char*)0x88000000; p += PGSIZE) {
    802005ac:	6705                	lui	a4,0x1
    802005ae:	9726                	add	a4,a4,s1
    802005b0:	47c5                	li	a5,17
    802005b2:	07ee                	sll	a5,a5,0x1b
    802005b4:	04e7ec63          	bltu	a5,a4,8020060c <kinit+0xb0>
    802005b8:	800007b7          	lui	a5,0x80000
    802005bc:	94be                	add	s1,s1,a5
    802005be:	4a05                	li	s4,1
    802005c0:	01fa1b93          	sll	s7,s4,0x1f
    if (pa < 0x80000000 || pa >= 0x88000000)
    802005c4:	08000937          	lui	s2,0x8000
        panic("pa2idx: invalid pa");
    802005c8:	00006c17          	auipc	s8,0x6
    802005cc:	ad8c0c13          	add	s8,s8,-1320 # 802060a0 <_etext+0xa0>
        kmem.ref[pa2idx((uint64)p)] = 1; 
    802005d0:	00021b17          	auipc	s6,0x21
    802005d4:	a30b0b13          	add	s6,s6,-1488 # 80221000 <kmem>
    for(; p + PGSIZE <= (char*)0x88000000; p += PGSIZE) {
    802005d8:	6a85                	lui	s5,0x1
    802005da:	a839                	j	802005f8 <kinit+0x9c>
    return (pa - 0x80000000) / PGSIZE;
    802005dc:	00c4d793          	srl	a5,s1,0xc
        kmem.ref[pa2idx((uint64)p)] = 1; 
    802005e0:	2781                	sext.w	a5,a5
    802005e2:	97da                	add	a5,a5,s6
    802005e4:	03478023          	sb	s4,32(a5) # ffffffff80000020 <__bss_end+0xfffffffeffdbe200>
        kfree(p);
    802005e8:	854e                	mv	a0,s3
    802005ea:	00000097          	auipc	ra,0x0
    802005ee:	e54080e7          	jalr	-428(ra) # 8020043e <kfree>
    for(; p + PGSIZE <= (char*)0x88000000; p += PGSIZE) {
    802005f2:	94d6                	add	s1,s1,s5
    802005f4:	01248c63          	beq	s1,s2,8020060c <kinit+0xb0>
    802005f8:	017489b3          	add	s3,s1,s7
    if (pa < 0x80000000 || pa >= 0x88000000)
    802005fc:	ff24e0e3          	bltu	s1,s2,802005dc <kinit+0x80>
        panic("pa2idx: invalid pa");
    80200600:	8562                	mv	a0,s8
    80200602:	00000097          	auipc	ra,0x0
    80200606:	dd2080e7          	jalr	-558(ra) # 802003d4 <panic>
    8020060a:	bfc9                	j	802005dc <kinit+0x80>
    printf("kinit: physical memory allocator initialized (with COW support).\n");
    8020060c:	00006517          	auipc	a0,0x6
    80200610:	ac450513          	add	a0,a0,-1340 # 802060d0 <_etext+0xd0>
    80200614:	00000097          	auipc	ra,0x0
    80200618:	b40080e7          	jalr	-1216(ra) # 80200154 <printf>
}
    8020061c:	60a6                	ld	ra,72(sp)
    8020061e:	6406                	ld	s0,64(sp)
    80200620:	74e2                	ld	s1,56(sp)
    80200622:	7942                	ld	s2,48(sp)
    80200624:	79a2                	ld	s3,40(sp)
    80200626:	7a02                	ld	s4,32(sp)
    80200628:	6ae2                	ld	s5,24(sp)
    8020062a:	6b42                	ld	s6,16(sp)
    8020062c:	6ba2                	ld	s7,8(sp)
    8020062e:	6c02                	ld	s8,0(sp)
    80200630:	6161                	add	sp,sp,80
    80200632:	8082                	ret

0000000080200634 <kalloc>:

void *kalloc(void) {
    80200634:	1101                	add	sp,sp,-32
    80200636:	ec06                	sd	ra,24(sp)
    80200638:	e822                	sd	s0,16(sp)
    8020063a:	e426                	sd	s1,8(sp)
    8020063c:	e04a                	sd	s2,0(sp)
    8020063e:	1000                	add	s0,sp,32
    struct run *r;

    acquire(&kmem.lock);
    80200640:	00021517          	auipc	a0,0x21
    80200644:	9c050513          	add	a0,a0,-1600 # 80221000 <kmem>
    80200648:	00000097          	auipc	ra,0x0
    8020064c:	1f2080e7          	jalr	498(ra) # 8020083a <acquire>
    r = kmem.freelist;
    80200650:	00021917          	auipc	s2,0x21
    80200654:	9c893903          	ld	s2,-1592(s2) # 80221018 <kmem+0x18>
    if(r) {
    80200658:	08090563          	beqz	s2,802006e2 <kalloc+0xae>
        kmem.freelist = r->next;
    8020065c:	00093783          	ld	a5,0(s2)
    80200660:	00021717          	auipc	a4,0x21
    80200664:	9af73c23          	sd	a5,-1608(a4) # 80221018 <kmem+0x18>
    if (pa < 0x80000000 || pa >= 0x88000000)
    80200668:	800004b7          	lui	s1,0x80000
    8020066c:	94ca                	add	s1,s1,s2
    8020066e:	080007b7          	lui	a5,0x8000
    80200672:	04f4f663          	bgeu	s1,a5,802006be <kalloc+0x8a>
    return (pa - 0x80000000) / PGSIZE;
    80200676:	80b1                	srl	s1,s1,0xc
    80200678:	2481                	sext.w	s1,s1
        // 分配时，引用计数置 1
        int idx = pa2idx((uint64)r);
        if (kmem.ref[idx] != 0) {
    8020067a:	00021797          	auipc	a5,0x21
    8020067e:	98678793          	add	a5,a5,-1658 # 80221000 <kmem>
    80200682:	97a6                	add	a5,a5,s1
    80200684:	0207c783          	lbu	a5,32(a5)
    80200688:	e7a1                	bnez	a5,802006d0 <kalloc+0x9c>
            panic("kalloc: ref not 0");
        }
        kmem.ref[idx] = 1;
    8020068a:	00021517          	auipc	a0,0x21
    8020068e:	97650513          	add	a0,a0,-1674 # 80221000 <kmem>
    80200692:	94aa                	add	s1,s1,a0
    80200694:	4785                	li	a5,1
    80200696:	02f48023          	sb	a5,32(s1) # ffffffff80000020 <__bss_end+0xfffffffeffdbe200>
    }
    release(&kmem.lock);
    8020069a:	00000097          	auipc	ra,0x0
    8020069e:	292080e7          	jalr	658(ra) # 8020092c <release>

    if(r)
        memset((char*)r, 5, PGSIZE); // fill with junk
    802006a2:	6605                	lui	a2,0x1
    802006a4:	4595                	li	a1,5
    802006a6:	854a                	mv	a0,s2
    802006a8:	00000097          	auipc	ra,0x0
    802006ac:	2fa080e7          	jalr	762(ra) # 802009a2 <memset>
    return (void*)r;
}
    802006b0:	854a                	mv	a0,s2
    802006b2:	60e2                	ld	ra,24(sp)
    802006b4:	6442                	ld	s0,16(sp)
    802006b6:	64a2                	ld	s1,8(sp)
    802006b8:	6902                	ld	s2,0(sp)
    802006ba:	6105                	add	sp,sp,32
    802006bc:	8082                	ret
        panic("pa2idx: invalid pa");
    802006be:	00006517          	auipc	a0,0x6
    802006c2:	9e250513          	add	a0,a0,-1566 # 802060a0 <_etext+0xa0>
    802006c6:	00000097          	auipc	ra,0x0
    802006ca:	d0e080e7          	jalr	-754(ra) # 802003d4 <panic>
    802006ce:	b765                	j	80200676 <kalloc+0x42>
            panic("kalloc: ref not 0");
    802006d0:	00006517          	auipc	a0,0x6
    802006d4:	a4850513          	add	a0,a0,-1464 # 80206118 <_etext+0x118>
    802006d8:	00000097          	auipc	ra,0x0
    802006dc:	cfc080e7          	jalr	-772(ra) # 802003d4 <panic>
    802006e0:	b76d                	j	8020068a <kalloc+0x56>
    release(&kmem.lock);
    802006e2:	00021517          	auipc	a0,0x21
    802006e6:	91e50513          	add	a0,a0,-1762 # 80221000 <kmem>
    802006ea:	00000097          	auipc	ra,0x0
    802006ee:	242080e7          	jalr	578(ra) # 8020092c <release>
    if(r)
    802006f2:	bf7d                	j	802006b0 <kalloc+0x7c>

00000000802006f4 <kref_inc>:

// 增加引用计数 (用于 fork COW)
void kref_inc(void *pa) {
    802006f4:	1101                	add	sp,sp,-32
    802006f6:	ec06                	sd	ra,24(sp)
    802006f8:	e822                	sd	s0,16(sp)
    802006fa:	e426                	sd	s1,8(sp)
    802006fc:	1000                	add	s0,sp,32
    if ((uint64)pa < 0x80000000 || (uint64)pa >= 0x88000000) return;
    802006fe:	800007b7          	lui	a5,0x80000
    80200702:	00f504b3          	add	s1,a0,a5
    80200706:	080007b7          	lui	a5,0x8000
    8020070a:	00f4e763          	bltu	s1,a5,80200718 <kref_inc+0x24>
    acquire(&kmem.lock);
    int idx = pa2idx((uint64)pa);
    if (kmem.ref[idx] < 1) panic("kref_inc: ref < 1");
    kmem.ref[idx]++;
    release(&kmem.lock);
}
    8020070e:	60e2                	ld	ra,24(sp)
    80200710:	6442                	ld	s0,16(sp)
    80200712:	64a2                	ld	s1,8(sp)
    80200714:	6105                	add	sp,sp,32
    80200716:	8082                	ret
    acquire(&kmem.lock);
    80200718:	00021517          	auipc	a0,0x21
    8020071c:	8e850513          	add	a0,a0,-1816 # 80221000 <kmem>
    80200720:	00000097          	auipc	ra,0x0
    80200724:	11a080e7          	jalr	282(ra) # 8020083a <acquire>
    return (pa - 0x80000000) / PGSIZE;
    80200728:	80b1                	srl	s1,s1,0xc
    8020072a:	2481                	sext.w	s1,s1
    if (kmem.ref[idx] < 1) panic("kref_inc: ref < 1");
    8020072c:	00021797          	auipc	a5,0x21
    80200730:	8d478793          	add	a5,a5,-1836 # 80221000 <kmem>
    80200734:	97a6                	add	a5,a5,s1
    80200736:	0207c783          	lbu	a5,32(a5)
    8020073a:	c385                	beqz	a5,8020075a <kref_inc+0x66>
    kmem.ref[idx]++;
    8020073c:	00021517          	auipc	a0,0x21
    80200740:	8c450513          	add	a0,a0,-1852 # 80221000 <kmem>
    80200744:	94aa                	add	s1,s1,a0
    80200746:	0204c783          	lbu	a5,32(s1)
    8020074a:	2785                	addw	a5,a5,1
    8020074c:	02f48023          	sb	a5,32(s1)
    release(&kmem.lock);
    80200750:	00000097          	auipc	ra,0x0
    80200754:	1dc080e7          	jalr	476(ra) # 8020092c <release>
    80200758:	bf5d                	j	8020070e <kref_inc+0x1a>
    if (kmem.ref[idx] < 1) panic("kref_inc: ref < 1");
    8020075a:	00006517          	auipc	a0,0x6
    8020075e:	9d650513          	add	a0,a0,-1578 # 80206130 <_etext+0x130>
    80200762:	00000097          	auipc	ra,0x0
    80200766:	c72080e7          	jalr	-910(ra) # 802003d4 <panic>
    8020076a:	bfc9                	j	8020073c <kref_inc+0x48>

000000008020076c <kref_get>:

// 获取当前引用计数
int kref_get(void *pa) {
    8020076c:	1101                	add	sp,sp,-32
    8020076e:	ec06                	sd	ra,24(sp)
    80200770:	e822                	sd	s0,16(sp)
    80200772:	e426                	sd	s1,8(sp)
    80200774:	1000                	add	s0,sp,32
    if ((uint64)pa < 0x80000000 || (uint64)pa >= 0x88000000) return -1;
    80200776:	800007b7          	lui	a5,0x80000
    8020077a:	00f504b3          	add	s1,a0,a5
    8020077e:	080007b7          	lui	a5,0x8000
    80200782:	02f4fd63          	bgeu	s1,a5,802007bc <kref_get+0x50>
    acquire(&kmem.lock);
    80200786:	00021517          	auipc	a0,0x21
    8020078a:	87a50513          	add	a0,a0,-1926 # 80221000 <kmem>
    8020078e:	00000097          	auipc	ra,0x0
    80200792:	0ac080e7          	jalr	172(ra) # 8020083a <acquire>
    int c = kmem.ref[pa2idx((uint64)pa)];
    80200796:	00021517          	auipc	a0,0x21
    8020079a:	86a50513          	add	a0,a0,-1942 # 80221000 <kmem>
    return (pa - 0x80000000) / PGSIZE;
    8020079e:	80b1                	srl	s1,s1,0xc
    int c = kmem.ref[pa2idx((uint64)pa)];
    802007a0:	2481                	sext.w	s1,s1
    802007a2:	94aa                	add	s1,s1,a0
    802007a4:	0204c483          	lbu	s1,32(s1)
    release(&kmem.lock);
    802007a8:	00000097          	auipc	ra,0x0
    802007ac:	184080e7          	jalr	388(ra) # 8020092c <release>
    return c;
}
    802007b0:	8526                	mv	a0,s1
    802007b2:	60e2                	ld	ra,24(sp)
    802007b4:	6442                	ld	s0,16(sp)
    802007b6:	64a2                	ld	s1,8(sp)
    802007b8:	6105                	add	sp,sp,32
    802007ba:	8082                	ret
    if ((uint64)pa < 0x80000000 || (uint64)pa >= 0x88000000) return -1;
    802007bc:	54fd                	li	s1,-1
    802007be:	bfcd                	j	802007b0 <kref_get+0x44>

00000000802007c0 <kref_dec>:

void kref_dec(void *pa) {
    802007c0:	1141                	add	sp,sp,-16
    802007c2:	e406                	sd	ra,8(sp)
    802007c4:	e022                	sd	s0,0(sp)
    802007c6:	0800                	add	s0,sp,16
    kfree(pa);
    802007c8:	00000097          	auipc	ra,0x0
    802007cc:	c76080e7          	jalr	-906(ra) # 8020043e <kfree>
}
    802007d0:	60a2                	ld	ra,8(sp)
    802007d2:	6402                	ld	s0,0(sp)
    802007d4:	0141                	add	sp,sp,16
    802007d6:	8082                	ret

00000000802007d8 <spinlock_init>:
// kernel/spinlock.c
#include "defs.h"

void spinlock_init(struct spinlock *lk, char *name) {
    802007d8:	1141                	add	sp,sp,-16
    802007da:	e422                	sd	s0,8(sp)
    802007dc:	0800                	add	s0,sp,16
    lk->name = name;
    802007de:	e50c                	sd	a1,8(a0)
    lk->locked = 0;
    802007e0:	00053023          	sd	zero,0(a0)
    lk->cpu = 0;
    802007e4:	00053823          	sd	zero,16(a0)
}
    802007e8:	6422                	ld	s0,8(sp)
    802007ea:	0141                	add	sp,sp,16
    802007ec:	8082                	ret

00000000802007ee <push_off>:
}

// --- 中断状态保存 ---

// 记录 push_off/pop_off 的嵌套层数
void push_off(void) {
    802007ee:	1101                	add	sp,sp,-32
    802007f0:	ec06                	sd	ra,24(sp)
    802007f2:	e822                	sd	s0,16(sp)
    802007f4:	e426                	sd	s1,8(sp)
    802007f6:	1000                	add	s0,sp,32

//
// 用于读写 RISC-V 控制寄存器的内联汇编函数
//

static inline uint64 r_sstatus() { uint64 x; asm volatile("csrr %0, sstatus" : "=r" (x)); return x; }
    802007f8:	100024f3          	csrr	s1,sstatus
    802007fc:	100027f3          	csrr	a5,sstatus
void push_off(void);
void pop_off(void);

// 内联函数
static inline void intr_off() {
    w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80200800:	9bf5                	and	a5,a5,-3
static inline void w_sstatus(uint64 x) { asm volatile("csrw sstatus, %0" : : "r" (x)); }
    80200802:	10079073          	csrw	sstatus,a5
    int old = intr_get();
    intr_off();
    if (mycpu()->ncli == 0) {
    80200806:	00001097          	auipc	ra,0x1
    8020080a:	b8e080e7          	jalr	-1138(ra) # 80201394 <mycpu>
    8020080e:	5d3c                	lw	a5,120(a0)
    80200810:	cf89                	beqz	a5,8020082a <push_off+0x3c>
        mycpu()->intena = old;
    }
    mycpu()->ncli += 1;
    80200812:	00001097          	auipc	ra,0x1
    80200816:	b82080e7          	jalr	-1150(ra) # 80201394 <mycpu>
    8020081a:	5d3c                	lw	a5,120(a0)
    8020081c:	2785                	addw	a5,a5,1 # 8000001 <_start-0x781fffff>
    8020081e:	dd3c                	sw	a5,120(a0)
}
    80200820:	60e2                	ld	ra,24(sp)
    80200822:	6442                	ld	s0,16(sp)
    80200824:	64a2                	ld	s1,8(sp)
    80200826:	6105                	add	sp,sp,32
    80200828:	8082                	ret
        mycpu()->intena = old;
    8020082a:	00001097          	auipc	ra,0x1
    8020082e:	b6a080e7          	jalr	-1174(ra) # 80201394 <mycpu>
    w_sstatus(r_sstatus() | SSTATUS_SIE);
}

// 修正: 添加回缺失的 intr_get()
static inline int intr_get(void) {
    return (r_sstatus() & SSTATUS_SIE) ? 1 : 0;
    80200832:	8085                	srl	s1,s1,0x1
    80200834:	8885                	and	s1,s1,1
    80200836:	dd64                	sw	s1,124(a0)
    80200838:	bfe9                	j	80200812 <push_off+0x24>

000000008020083a <acquire>:
void acquire(struct spinlock *lk) {
    8020083a:	1101                	add	sp,sp,-32
    8020083c:	ec06                	sd	ra,24(sp)
    8020083e:	e822                	sd	s0,16(sp)
    80200840:	e426                	sd	s1,8(sp)
    80200842:	e04a                	sd	s2,0(sp)
    80200844:	1000                	add	s0,sp,32
    80200846:	84aa                	mv	s1,a0
    push_off(); // 屏蔽中断
    80200848:	00000097          	auipc	ra,0x0
    8020084c:	fa6080e7          	jalr	-90(ra) # 802007ee <push_off>
    if (lk->locked && lk->cpu == mycpu()) {
    80200850:	609c                	ld	a5,0(s1)
    80200852:	ef85                	bnez	a5,8020088a <acquire+0x50>
    while (__atomic_test_and_set(&lk->locked, __ATOMIC_ACQUIRE));
    80200854:	ffc4f713          	and	a4,s1,-4
    80200858:	0034f693          	and	a3,s1,3
    8020085c:	0036969b          	sllw	a3,a3,0x3
    80200860:	4605                	li	a2,1
    80200862:	00d6163b          	sllw	a2,a2,a3
    80200866:	44c727af          	amoor.w.aq	a5,a2,(a4)
    8020086a:	00d7d7bb          	srlw	a5,a5,a3
    8020086e:	0ff7f793          	zext.b	a5,a5
    80200872:	fbf5                	bnez	a5,80200866 <acquire+0x2c>
    lk->cpu = mycpu();
    80200874:	00001097          	auipc	ra,0x1
    80200878:	b20080e7          	jalr	-1248(ra) # 80201394 <mycpu>
    8020087c:	e888                	sd	a0,16(s1)
}
    8020087e:	60e2                	ld	ra,24(sp)
    80200880:	6442                	ld	s0,16(sp)
    80200882:	64a2                	ld	s1,8(sp)
    80200884:	6902                	ld	s2,0(sp)
    80200886:	6105                	add	sp,sp,32
    80200888:	8082                	ret
    if (lk->locked && lk->cpu == mycpu()) {
    8020088a:	0104b903          	ld	s2,16(s1)
    8020088e:	00001097          	auipc	ra,0x1
    80200892:	b06080e7          	jalr	-1274(ra) # 80201394 <mycpu>
    80200896:	faa91fe3          	bne	s2,a0,80200854 <acquire+0x1a>
        printf("acquire: re-acquire lock %s\n", lk->name);
    8020089a:	648c                	ld	a1,8(s1)
    8020089c:	00006517          	auipc	a0,0x6
    802008a0:	8ac50513          	add	a0,a0,-1876 # 80206148 <_etext+0x148>
    802008a4:	00000097          	auipc	ra,0x0
    802008a8:	8b0080e7          	jalr	-1872(ra) # 80200154 <printf>
        while(1);
    802008ac:	a001                	j	802008ac <acquire+0x72>

00000000802008ae <pop_off>:

void pop_off(void) {
    802008ae:	1141                	add	sp,sp,-16
    802008b0:	e406                	sd	ra,8(sp)
    802008b2:	e022                	sd	s0,0(sp)
    802008b4:	0800                	add	s0,sp,16
static inline uint64 r_sstatus() { uint64 x; asm volatile("csrr %0, sstatus" : "=r" (x)); return x; }
    802008b6:	100027f3          	csrr	a5,sstatus
    802008ba:	8b89                	and	a5,a5,2
    if (intr_get()) {
    802008bc:	cb91                	beqz	a5,802008d0 <pop_off+0x22>
        printf("pop_off: interrupts enabled\n");
    802008be:	00006517          	auipc	a0,0x6
    802008c2:	8aa50513          	add	a0,a0,-1878 # 80206168 <_etext+0x168>
    802008c6:	00000097          	auipc	ra,0x0
    802008ca:	88e080e7          	jalr	-1906(ra) # 80200154 <printf>
        while(1);
    802008ce:	a001                	j	802008ce <pop_off+0x20>
    }
    mycpu()->ncli -= 1;
    802008d0:	00001097          	auipc	ra,0x1
    802008d4:	ac4080e7          	jalr	-1340(ra) # 80201394 <mycpu>
    802008d8:	5d3c                	lw	a5,120(a0)
    802008da:	37fd                	addw	a5,a5,-1
    802008dc:	dd3c                	sw	a5,120(a0)
    if (mycpu()->ncli < 0) {
    802008de:	00001097          	auipc	ra,0x1
    802008e2:	ab6080e7          	jalr	-1354(ra) # 80201394 <mycpu>
    802008e6:	5d3c                	lw	a5,120(a0)
    802008e8:	0007cc63          	bltz	a5,80200900 <pop_off+0x52>
        printf("pop_off: ncli < 0\n");
        while(1);
    }
    if (mycpu()->ncli == 0 && mycpu()->intena) {
    802008ec:	00001097          	auipc	ra,0x1
    802008f0:	aa8080e7          	jalr	-1368(ra) # 80201394 <mycpu>
    802008f4:	5d3c                	lw	a5,120(a0)
    802008f6:	cf91                	beqz	a5,80200912 <pop_off+0x64>
        intr_on();
    }
    802008f8:	60a2                	ld	ra,8(sp)
    802008fa:	6402                	ld	s0,0(sp)
    802008fc:	0141                	add	sp,sp,16
    802008fe:	8082                	ret
        printf("pop_off: ncli < 0\n");
    80200900:	00006517          	auipc	a0,0x6
    80200904:	88850513          	add	a0,a0,-1912 # 80206188 <_etext+0x188>
    80200908:	00000097          	auipc	ra,0x0
    8020090c:	84c080e7          	jalr	-1972(ra) # 80200154 <printf>
        while(1);
    80200910:	a001                	j	80200910 <pop_off+0x62>
    if (mycpu()->ncli == 0 && mycpu()->intena) {
    80200912:	00001097          	auipc	ra,0x1
    80200916:	a82080e7          	jalr	-1406(ra) # 80201394 <mycpu>
    8020091a:	5d7c                	lw	a5,124(a0)
    8020091c:	dff1                	beqz	a5,802008f8 <pop_off+0x4a>
    8020091e:	100027f3          	csrr	a5,sstatus
    w_sstatus(r_sstatus() | SSTATUS_SIE);
    80200922:	0027e793          	or	a5,a5,2
static inline void w_sstatus(uint64 x) { asm volatile("csrw sstatus, %0" : : "r" (x)); }
    80200926:	10079073          	csrw	sstatus,a5
    8020092a:	b7f9                	j	802008f8 <pop_off+0x4a>

000000008020092c <release>:
void release(struct spinlock *lk) {
    8020092c:	1141                	add	sp,sp,-16
    8020092e:	e406                	sd	ra,8(sp)
    80200930:	e022                	sd	s0,0(sp)
    80200932:	0800                	add	s0,sp,16
    if (!lk->locked) {
    80200934:	611c                	ld	a5,0(a0)
    80200936:	eb99                	bnez	a5,8020094c <release+0x20>
        printf("release: lock %s not held\n", lk->name);
    80200938:	650c                	ld	a1,8(a0)
    8020093a:	00006517          	auipc	a0,0x6
    8020093e:	86650513          	add	a0,a0,-1946 # 802061a0 <_etext+0x1a0>
    80200942:	00000097          	auipc	ra,0x0
    80200946:	812080e7          	jalr	-2030(ra) # 80200154 <printf>
        while(1);
    8020094a:	a001                	j	8020094a <release+0x1e>
    lk->cpu = 0;
    8020094c:	00053823          	sd	zero,16(a0)
    __atomic_clear(&lk->locked, __ATOMIC_RELEASE);
    80200950:	0ff0000f          	fence
    80200954:	00050023          	sb	zero,0(a0)
    pop_off(); // 恢复之前的中断状态
    80200958:	00000097          	auipc	ra,0x0
    8020095c:	f56080e7          	jalr	-170(ra) # 802008ae <pop_off>
}
    80200960:	60a2                	ld	ra,8(sp)
    80200962:	6402                	ld	s0,0(sp)
    80200964:	0141                	add	sp,sp,16
    80200966:	8082                	ret

0000000080200968 <memcmp>:
#include "riscv.h"

int memcmp(const void *v1, const void *v2, uint n) {
    80200968:	1141                	add	sp,sp,-16
    8020096a:	e422                	sd	s0,8(sp)
    8020096c:	0800                	add	s0,sp,16
    const uchar *s1 = v1;
    const uchar *s2 = v2;
    while (n-- > 0) {
    8020096e:	ca05                	beqz	a2,8020099e <memcmp+0x36>
    80200970:	fff6069b          	addw	a3,a2,-1 # fff <_start-0x801ff001>
    80200974:	1682                	sll	a3,a3,0x20
    80200976:	9281                	srl	a3,a3,0x20
    80200978:	0685                	add	a3,a3,1
    8020097a:	96aa                	add	a3,a3,a0
        if (*s1 != *s2) {
    8020097c:	00054783          	lbu	a5,0(a0)
    80200980:	0005c703          	lbu	a4,0(a1)
    80200984:	00e79863          	bne	a5,a4,80200994 <memcmp+0x2c>
            return *s1 - *s2;
        }
        s1++;
    80200988:	0505                	add	a0,a0,1
        s2++;
    8020098a:	0585                	add	a1,a1,1
    while (n-- > 0) {
    8020098c:	fed518e3          	bne	a0,a3,8020097c <memcmp+0x14>
    }
    return 0;
    80200990:	4501                	li	a0,0
    80200992:	a019                	j	80200998 <memcmp+0x30>
            return *s1 - *s2;
    80200994:	40e7853b          	subw	a0,a5,a4
}
    80200998:	6422                	ld	s0,8(sp)
    8020099a:	0141                	add	sp,sp,16
    8020099c:	8082                	ret
    return 0;
    8020099e:	4501                	li	a0,0
    802009a0:	bfe5                	j	80200998 <memcmp+0x30>

00000000802009a2 <memset>:

void *memset(void *dst, int c, uint n) {
    802009a2:	1141                	add	sp,sp,-16
    802009a4:	e422                	sd	s0,8(sp)
    802009a6:	0800                	add	s0,sp,16
    char *d = dst;
    for (uint i = 0; i < n; i++) {
    802009a8:	ca19                	beqz	a2,802009be <memset+0x1c>
    802009aa:	87aa                	mv	a5,a0
    802009ac:	1602                	sll	a2,a2,0x20
    802009ae:	9201                	srl	a2,a2,0x20
    802009b0:	00a60733          	add	a4,a2,a0
        d[i] = c;
    802009b4:	00b78023          	sb	a1,0(a5)
    for (uint i = 0; i < n; i++) {
    802009b8:	0785                	add	a5,a5,1
    802009ba:	fee79de3          	bne	a5,a4,802009b4 <memset+0x12>
    }
    return dst;
}
    802009be:	6422                	ld	s0,8(sp)
    802009c0:	0141                	add	sp,sp,16
    802009c2:	8082                	ret

00000000802009c4 <memmove>:

void *memmove(void *dst, const void *src, uint n) {
    802009c4:	1141                	add	sp,sp,-16
    802009c6:	e422                	sd	s0,8(sp)
    802009c8:	0800                	add	s0,sp,16
    const char *s = src;
    char *d = dst;
    if (s < d && s + n > d) {
    802009ca:	02a5e563          	bltu	a1,a0,802009f4 <memmove+0x30>
        d += n;
        while (n-- > 0) {
            *--d = *--s;
        }
    } else {
        while (n-- > 0) {
    802009ce:	fff6069b          	addw	a3,a2,-1
    802009d2:	ce11                	beqz	a2,802009ee <memmove+0x2a>
    802009d4:	1682                	sll	a3,a3,0x20
    802009d6:	9281                	srl	a3,a3,0x20
    802009d8:	0685                	add	a3,a3,1
    802009da:	96ae                	add	a3,a3,a1
    802009dc:	87aa                	mv	a5,a0
            *d++ = *s++;
    802009de:	0585                	add	a1,a1,1
    802009e0:	0785                	add	a5,a5,1
    802009e2:	fff5c703          	lbu	a4,-1(a1)
    802009e6:	fee78fa3          	sb	a4,-1(a5)
        while (n-- > 0) {
    802009ea:	fed59ae3          	bne	a1,a3,802009de <memmove+0x1a>
        }
    }
    return dst;
}
    802009ee:	6422                	ld	s0,8(sp)
    802009f0:	0141                	add	sp,sp,16
    802009f2:	8082                	ret
    if (s < d && s + n > d) {
    802009f4:	02061713          	sll	a4,a2,0x20
    802009f8:	9301                	srl	a4,a4,0x20
    802009fa:	00e587b3          	add	a5,a1,a4
    802009fe:	fcf578e3          	bgeu	a0,a5,802009ce <memmove+0xa>
        d += n;
    80200a02:	972a                	add	a4,a4,a0
        while (n-- > 0) {
    80200a04:	fff6069b          	addw	a3,a2,-1
    80200a08:	d27d                	beqz	a2,802009ee <memmove+0x2a>
    80200a0a:	02069613          	sll	a2,a3,0x20
    80200a0e:	9201                	srl	a2,a2,0x20
    80200a10:	fff64613          	not	a2,a2
    80200a14:	963e                	add	a2,a2,a5
            *--d = *--s;
    80200a16:	17fd                	add	a5,a5,-1
    80200a18:	177d                	add	a4,a4,-1
    80200a1a:	0007c683          	lbu	a3,0(a5)
    80200a1e:	00d70023          	sb	a3,0(a4)
        while (n-- > 0) {
    80200a22:	fef61ae3          	bne	a2,a5,80200a16 <memmove+0x52>
    80200a26:	b7e1                	j	802009ee <memmove+0x2a>

0000000080200a28 <memcpy>:

void *memcpy(void *dst, const void *src, uint n) {
    80200a28:	1141                	add	sp,sp,-16
    80200a2a:	e406                	sd	ra,8(sp)
    80200a2c:	e022                	sd	s0,0(sp)
    80200a2e:	0800                	add	s0,sp,16
    return memmove(dst, src, n);
    80200a30:	00000097          	auipc	ra,0x0
    80200a34:	f94080e7          	jalr	-108(ra) # 802009c4 <memmove>
}
    80200a38:	60a2                	ld	ra,8(sp)
    80200a3a:	6402                	ld	s0,0(sp)
    80200a3c:	0141                	add	sp,sp,16
    80200a3e:	8082                	ret

0000000080200a40 <strncmp>:

int strncmp(const char *p, const char *q, uint n) {
    80200a40:	1141                	add	sp,sp,-16
    80200a42:	e422                	sd	s0,8(sp)
    80200a44:	0800                	add	s0,sp,16
    while (n > 0 && *p && *p == *q) {
    80200a46:	ce11                	beqz	a2,80200a62 <strncmp+0x22>
    80200a48:	00054783          	lbu	a5,0(a0)
    80200a4c:	cf89                	beqz	a5,80200a66 <strncmp+0x26>
    80200a4e:	0005c703          	lbu	a4,0(a1)
    80200a52:	00f71a63          	bne	a4,a5,80200a66 <strncmp+0x26>
        p++;
    80200a56:	0505                	add	a0,a0,1
        q++;
    80200a58:	0585                	add	a1,a1,1
        n--;
    80200a5a:	367d                	addw	a2,a2,-1
    while (n > 0 && *p && *p == *q) {
    80200a5c:	f675                	bnez	a2,80200a48 <strncmp+0x8>
    }
    if (n == 0) {
        return 0;
    80200a5e:	4501                	li	a0,0
    80200a60:	a809                	j	80200a72 <strncmp+0x32>
    80200a62:	4501                	li	a0,0
    80200a64:	a039                	j	80200a72 <strncmp+0x32>
    if (n == 0) {
    80200a66:	ca09                	beqz	a2,80200a78 <strncmp+0x38>
    }
    return (uchar)*p - (uchar)*q;
    80200a68:	00054503          	lbu	a0,0(a0)
    80200a6c:	0005c783          	lbu	a5,0(a1)
    80200a70:	9d1d                	subw	a0,a0,a5
}
    80200a72:	6422                	ld	s0,8(sp)
    80200a74:	0141                	add	sp,sp,16
    80200a76:	8082                	ret
        return 0;
    80200a78:	4501                	li	a0,0
    80200a7a:	bfe5                	j	80200a72 <strncmp+0x32>

0000000080200a7c <strncpy>:

char *strncpy(char *s, const char *t, int n) {
    80200a7c:	1141                	add	sp,sp,-16
    80200a7e:	e422                	sd	s0,8(sp)
    80200a80:	0800                	add	s0,sp,16
    int i;
    for (i = 0; i < n && t[i]; i++) {
    80200a82:	87aa                	mv	a5,a0
    80200a84:	4701                	li	a4,0
    80200a86:	02c05b63          	blez	a2,80200abc <strncpy+0x40>
    80200a8a:	0005c683          	lbu	a3,0(a1)
    80200a8e:	ca89                	beqz	a3,80200aa0 <strncpy+0x24>
        s[i] = t[i];
    80200a90:	00d78023          	sb	a3,0(a5)
    for (i = 0; i < n && t[i]; i++) {
    80200a94:	2705                	addw	a4,a4,1
    80200a96:	0585                	add	a1,a1,1
    80200a98:	0785                	add	a5,a5,1
    80200a9a:	fee618e3          	bne	a2,a4,80200a8a <strncpy+0xe>
    80200a9e:	a839                	j	80200abc <strncpy+0x40>
    }
    for (; i < n; i++) {
    80200aa0:	00c75e63          	bge	a4,a2,80200abc <strncpy+0x40>
    80200aa4:	00e507b3          	add	a5,a0,a4
    80200aa8:	9e19                	subw	a2,a2,a4
    80200aaa:	1602                	sll	a2,a2,0x20
    80200aac:	9201                	srl	a2,a2,0x20
    80200aae:	00c78733          	add	a4,a5,a2
        s[i] = 0;
    80200ab2:	00078023          	sb	zero,0(a5)
    for (; i < n; i++) {
    80200ab6:	0785                	add	a5,a5,1
    80200ab8:	fee79de3          	bne	a5,a4,80200ab2 <strncpy+0x36>
    }
    return s;
}
    80200abc:	6422                	ld	s0,8(sp)
    80200abe:	0141                	add	sp,sp,16
    80200ac0:	8082                	ret

0000000080200ac2 <strlen>:

int strlen(const char *s) {
    80200ac2:	1141                	add	sp,sp,-16
    80200ac4:	e422                	sd	s0,8(sp)
    80200ac6:	0800                	add	s0,sp,16
    int n = 0;
    while (s[n]) {
    80200ac8:	00054783          	lbu	a5,0(a0)
    80200acc:	cf91                	beqz	a5,80200ae8 <strlen+0x26>
    80200ace:	0505                	add	a0,a0,1
    80200ad0:	87aa                	mv	a5,a0
    80200ad2:	86be                	mv	a3,a5
    80200ad4:	0785                	add	a5,a5,1
    80200ad6:	fff7c703          	lbu	a4,-1(a5)
    80200ada:	ff65                	bnez	a4,80200ad2 <strlen+0x10>
        n++;
    80200adc:	40a6853b          	subw	a0,a3,a0
    80200ae0:	2505                	addw	a0,a0,1
    }
    return n;
}
    80200ae2:	6422                	ld	s0,8(sp)
    80200ae4:	0141                	add	sp,sp,16
    80200ae6:	8082                	ret
    int n = 0;
    80200ae8:	4501                	li	a0,0
    80200aea:	bfe5                	j	80200ae2 <strlen+0x20>

0000000080200aec <safestrcpy>:

char *safestrcpy(char *s, const char *t, int n) {
    80200aec:	1141                	add	sp,sp,-16
    80200aee:	e422                	sd	s0,8(sp)
    80200af0:	0800                	add	s0,sp,16
    if (n <= 0) {
    80200af2:	02c05663          	blez	a2,80200b1e <safestrcpy+0x32>
        return s;
    }
    int i;
    for (i = 0; i < n - 1 && t[i]; i++) {
    80200af6:	4785                	li	a5,1
    80200af8:	02c7d663          	bge	a5,a2,80200b24 <safestrcpy+0x38>
    80200afc:	86aa                	mv	a3,a0
    80200afe:	367d                	addw	a2,a2,-1
    80200b00:	4781                	li	a5,0
    80200b02:	0005c703          	lbu	a4,0(a1)
    80200b06:	cb09                	beqz	a4,80200b18 <safestrcpy+0x2c>
        s[i] = t[i];
    80200b08:	00e68023          	sb	a4,0(a3)
    for (i = 0; i < n - 1 && t[i]; i++) {
    80200b0c:	2785                	addw	a5,a5,1
    80200b0e:	0585                	add	a1,a1,1
    80200b10:	0685                	add	a3,a3,1
    80200b12:	fec798e3          	bne	a5,a2,80200b02 <safestrcpy+0x16>
    80200b16:	87b2                	mv	a5,a2
    }
    s[i] = 0;
    80200b18:	97aa                	add	a5,a5,a0
    80200b1a:	00078023          	sb	zero,0(a5)
    return s;
}
    80200b1e:	6422                	ld	s0,8(sp)
    80200b20:	0141                	add	sp,sp,16
    80200b22:	8082                	ret
    for (i = 0; i < n - 1 && t[i]; i++) {
    80200b24:	4781                	li	a5,0
    80200b26:	bfcd                	j	80200b18 <safestrcpy+0x2c>

0000000080200b28 <main_task>:
// kernel/main.c
#include "defs.h"
#include "riscv.h"

void main_task(void) {
    80200b28:	1141                	add	sp,sp,-16
    80200b2a:	e406                	sd	ra,8(sp)
    80200b2c:	e022                	sd	s0,0(sp)
    80200b2e:	0800                	add	s0,sp,16
    printf("===== main_task Started (PID %d) =====\n", myproc()->pid);
    80200b30:	00001097          	auipc	ra,0x1
    80200b34:	878080e7          	jalr	-1928(ra) # 802013a8 <myproc>
    80200b38:	4d4c                	lw	a1,28(a0)
    80200b3a:	00005517          	auipc	a0,0x5
    80200b3e:	68650513          	add	a0,a0,1670 # 802061c0 <_etext+0x1c0>
    80200b42:	fffff097          	auipc	ra,0xfffff
    80200b46:	612080e7          	jalr	1554(ra) # 80200154 <printf>
    
    // 将需要I/O同步的初始化移到进程中执行
    binit();
    80200b4a:	00001097          	auipc	ra,0x1
    80200b4e:	32c080e7          	jalr	812(ra) # 80201e76 <binit>
    fileinit();
    80200b52:	00003097          	auipc	ra,0x3
    80200b56:	dee080e7          	jalr	-530(ra) # 80203940 <fileinit>
    
    printf("DEBUG: Device Inits Done\n"); // binit/fileinit 不做 I/O，但放在这里保持结构
    80200b5a:	00005517          	auipc	a0,0x5
    80200b5e:	68e50513          	add	a0,a0,1678 # 802061e8 <_etext+0x1e8>
    80200b62:	fffff097          	auipc	ra,0xfffff
    80200b66:	5f2080e7          	jalr	1522(ra) # 80200154 <printf>
    
    virtio_disk_init(); // 可能会有 I/O
    80200b6a:	00004097          	auipc	ra,0x4
    80200b6e:	e6e080e7          	jalr	-402(ra) # 802049d8 <virtio_disk_init>
    printf("DEBUG: VirtIO Init Done\n");
    80200b72:	00005517          	auipc	a0,0x5
    80200b76:	69650513          	add	a0,a0,1686 # 80206208 <_etext+0x208>
    80200b7a:	fffff097          	auipc	ra,0xfffff
    80200b7e:	5da080e7          	jalr	1498(ra) # 80200154 <printf>

    iinit();
    80200b82:	00002097          	auipc	ra,0x2
    80200b86:	95c080e7          	jalr	-1700(ra) # 802024de <iinit>
    printf("DEBUG: FS Init Done\n");
    80200b8a:	00005517          	auipc	a0,0x5
    80200b8e:	69e50513          	add	a0,a0,1694 # 80206228 <_etext+0x228>
    80200b92:	fffff097          	auipc	ra,0xfffff
    80200b96:	5c2080e7          	jalr	1474(ra) # 80200154 <printf>
    
    extern struct superblock sb;
    initlog(ROOTDEV, &sb);
    80200b9a:	00036597          	auipc	a1,0x36
    80200b9e:	3c658593          	add	a1,a1,966 # 80236f60 <sb>
    80200ba2:	4505                	li	a0,1
    80200ba4:	00003097          	auipc	ra,0x3
    80200ba8:	930080e7          	jalr	-1744(ra) # 802034d4 <initlog>
    printf("DEBUG: Log Init Done\n");
    80200bac:	00005517          	auipc	a0,0x5
    80200bb0:	69450513          	add	a0,a0,1684 # 80206240 <_etext+0x240>
    80200bb4:	fffff097          	auipc	ra,0xfffff
    80200bb8:	5a0080e7          	jalr	1440(ra) # 80200154 <printf>

    printf("===== Project 5: Copy-on-Write Fork System =====\n");
    80200bbc:	00005517          	auipc	a0,0x5
    80200bc0:	69c50513          	add	a0,a0,1692 # 80206258 <_etext+0x258>
    80200bc4:	fffff097          	auipc	ra,0xfffff
    80200bc8:	590080e7          	jalr	1424(ra) # 80200154 <printf>
    run_cow_tests();
    80200bcc:	00004097          	auipc	ra,0x4
    80200bd0:	64a080e7          	jalr	1610(ra) # 80205216 <run_cow_tests>
    printf("\nPress Ctrl-A then X to quit QEMU.\n");
    80200bd4:	00005517          	auipc	a0,0x5
    80200bd8:	6bc50513          	add	a0,a0,1724 # 80206290 <_etext+0x290>
    80200bdc:	fffff097          	auipc	ra,0xfffff
    80200be0:	578080e7          	jalr	1400(ra) # 80200154 <printf>
    while (1);
    80200be4:	a001                	j	80200be4 <main_task+0xbc>

0000000080200be6 <kmain>:
}


void kmain(void) {
    80200be6:	1141                	add	sp,sp,-16
    80200be8:	e406                	sd	ra,8(sp)
    80200bea:	e022                	sd	s0,0(sp)
    80200bec:	0800                	add	s0,sp,16
    clear_screen();
    80200bee:	fffff097          	auipc	ra,0xfffff
    80200bf2:	7b8080e7          	jalr	1976(ra) # 802003a6 <clear_screen>
    printf("===== Kernel Booting =====\n");
    80200bf6:	00005517          	auipc	a0,0x5
    80200bfa:	6c250513          	add	a0,a0,1730 # 802062b8 <_etext+0x2b8>
    80200bfe:	fffff097          	auipc	ra,0xfffff
    80200c02:	556080e7          	jalr	1366(ra) # 80200154 <printf>
    
    // 只需要内存和进程/中断的基础初始化
    kinit();
    80200c06:	00000097          	auipc	ra,0x0
    80200c0a:	956080e7          	jalr	-1706(ra) # 8020055c <kinit>
    kvminit();
    80200c0e:	00000097          	auipc	ra,0x0
    80200c12:	3d8080e7          	jalr	984(ra) # 80200fe6 <kvminit>
    kvminithart();
    80200c16:	00000097          	auipc	ra,0x0
    80200c1a:	4e2080e7          	jalr	1250(ra) # 802010f8 <kvminithart>
    procinit();
    80200c1e:	00000097          	auipc	ra,0x0
    80200c22:	7b8080e7          	jalr	1976(ra) # 802013d6 <procinit>
    trap_init();
    80200c26:	00001097          	auipc	ra,0x1
    80200c2a:	dba080e7          	jalr	-582(ra) # 802019e0 <trap_init>
    clock_init();
    80200c2e:	00001097          	auipc	ra,0x1
    80200c32:	dca080e7          	jalr	-566(ra) # 802019f8 <clock_init>
    
    // I/O 驱动自身的初始化 (不进行实际 I/O)
    // 即使这里不调用，virtio_disk_init() 也会在 main_task 里被调用
    
    if (create_process(main_task) < 0) {
    80200c36:	00000517          	auipc	a0,0x0
    80200c3a:	ef250513          	add	a0,a0,-270 # 80200b28 <main_task>
    80200c3e:	00000097          	auipc	ra,0x0
    80200c42:	7f4080e7          	jalr	2036(ra) # 80201432 <create_process>
    80200c46:	00054663          	bltz	a0,80200c52 <kmain+0x6c>
        printf("kmain: failed to create main_task\n");
        while(1);
    }
    
    // 启动调度器，将 CPU 控制权交给 main_task，main_task 将完成剩下的初始化
    scheduler();
    80200c4a:	00001097          	auipc	ra,0x1
    80200c4e:	994080e7          	jalr	-1644(ra) # 802015de <scheduler>
        printf("kmain: failed to create main_task\n");
    80200c52:	00005517          	auipc	a0,0x5
    80200c56:	68650513          	add	a0,a0,1670 # 802062d8 <_etext+0x2d8>
    80200c5a:	fffff097          	auipc	ra,0xfffff
    80200c5e:	4fa080e7          	jalr	1274(ra) # 80200154 <printf>
        while(1);
    80200c62:	a001                	j	80200c62 <kmain+0x7c>

0000000080200c64 <walk>:
// 外部符号，由链接脚本定义
extern char etext[]; 

// 遍历页表，找到指定虚拟地址对应的PTE。
static pte_t *walk(pagetable_t pagetable, uint64 va, int alloc) {
    if (va >= (1L << 39)) {
    80200c64:	57fd                	li	a5,-1
    80200c66:	83e5                	srl	a5,a5,0x19
    80200c68:	08b7e963          	bltu	a5,a1,80200cfa <walk+0x96>
static pte_t *walk(pagetable_t pagetable, uint64 va, int alloc) {
    80200c6c:	7139                	add	sp,sp,-64
    80200c6e:	fc06                	sd	ra,56(sp)
    80200c70:	f822                	sd	s0,48(sp)
    80200c72:	f426                	sd	s1,40(sp)
    80200c74:	f04a                	sd	s2,32(sp)
    80200c76:	ec4e                	sd	s3,24(sp)
    80200c78:	e852                	sd	s4,16(sp)
    80200c7a:	e456                	sd	s5,8(sp)
    80200c7c:	e05a                	sd	s6,0(sp)
    80200c7e:	0080                	add	s0,sp,64
    80200c80:	84aa                	mv	s1,a0
    80200c82:	89ae                	mv	s3,a1
    80200c84:	8ab2                	mv	s5,a2
    80200c86:	4a79                	li	s4,30
        return 0; // 虚拟地址过大
    }
    
    for (int level = 2; level > 0; level--) {
    80200c88:	4b31                	li	s6,12
    80200c8a:	a80d                	j	80200cbc <walk+0x58>
        pte_t *pte = &pagetable[VPN(va, level)];
        if (*pte & PTE_V) {
            pagetable = (pagetable_t)PTE2PA(*pte);
        } else {
            if (!alloc || (pagetable = (pagetable_t)kalloc()) == 0) {
    80200c8c:	060a8963          	beqz	s5,80200cfe <walk+0x9a>
    80200c90:	00000097          	auipc	ra,0x0
    80200c94:	9a4080e7          	jalr	-1628(ra) # 80200634 <kalloc>
    80200c98:	84aa                	mv	s1,a0
    80200c9a:	c531                	beqz	a0,80200ce6 <walk+0x82>
                return 0; // 分配失败
            }
            memset(pagetable, 0, PGSIZE);
    80200c9c:	6605                	lui	a2,0x1
    80200c9e:	4581                	li	a1,0
    80200ca0:	00000097          	auipc	ra,0x0
    80200ca4:	d02080e7          	jalr	-766(ra) # 802009a2 <memset>
            *pte = PA2PTE(pagetable) | PTE_V;
    80200ca8:	00c4d793          	srl	a5,s1,0xc
    80200cac:	07aa                	sll	a5,a5,0xa
    80200cae:	0017e793          	or	a5,a5,1
    80200cb2:	00f93023          	sd	a5,0(s2)
    for (int level = 2; level > 0; level--) {
    80200cb6:	3a5d                	addw	s4,s4,-9
    80200cb8:	036a0063          	beq	s4,s6,80200cd8 <walk+0x74>
        pte_t *pte = &pagetable[VPN(va, level)];
    80200cbc:	0149d933          	srl	s2,s3,s4
    80200cc0:	1ff97913          	and	s2,s2,511
    80200cc4:	090e                	sll	s2,s2,0x3
    80200cc6:	9926                	add	s2,s2,s1
        if (*pte & PTE_V) {
    80200cc8:	00093483          	ld	s1,0(s2)
    80200ccc:	0014f793          	and	a5,s1,1
    80200cd0:	dfd5                	beqz	a5,80200c8c <walk+0x28>
            pagetable = (pagetable_t)PTE2PA(*pte);
    80200cd2:	80a9                	srl	s1,s1,0xa
    80200cd4:	04b2                	sll	s1,s1,0xc
    80200cd6:	b7c5                	j	80200cb6 <walk+0x52>
        }
    }
    return &pagetable[VPN(va, 0)];
    80200cd8:	00c9d993          	srl	s3,s3,0xc
    80200cdc:	1ff9f993          	and	s3,s3,511
    80200ce0:	098e                	sll	s3,s3,0x3
    80200ce2:	01348533          	add	a0,s1,s3
}
    80200ce6:	70e2                	ld	ra,56(sp)
    80200ce8:	7442                	ld	s0,48(sp)
    80200cea:	74a2                	ld	s1,40(sp)
    80200cec:	7902                	ld	s2,32(sp)
    80200cee:	69e2                	ld	s3,24(sp)
    80200cf0:	6a42                	ld	s4,16(sp)
    80200cf2:	6aa2                	ld	s5,8(sp)
    80200cf4:	6b02                	ld	s6,0(sp)
    80200cf6:	6121                	add	sp,sp,64
    80200cf8:	8082                	ret
        return 0; // 虚拟地址过大
    80200cfa:	4501                	li	a0,0
}
    80200cfc:	8082                	ret
                return 0; // 分配失败
    80200cfe:	4501                	li	a0,0
    80200d00:	b7dd                	j	80200ce6 <walk+0x82>

0000000080200d02 <mappages>:

// 创建内核页表
int mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm) {
    80200d02:	715d                	add	sp,sp,-80
    80200d04:	e486                	sd	ra,72(sp)
    80200d06:	e0a2                	sd	s0,64(sp)
    80200d08:	fc26                	sd	s1,56(sp)
    80200d0a:	f84a                	sd	s2,48(sp)
    80200d0c:	f44e                	sd	s3,40(sp)
    80200d0e:	f052                	sd	s4,32(sp)
    80200d10:	ec56                	sd	s5,24(sp)
    80200d12:	e85a                	sd	s6,16(sp)
    80200d14:	e45e                	sd	s7,8(sp)
    80200d16:	0880                	add	s0,sp,80
    80200d18:	8aaa                	mv	s5,a0
    80200d1a:	8b3a                	mv	s6,a4
    uint64 a, last;
    pte_t *pte;

    a = PGROUNDDOWN(va);
    80200d1c:	777d                	lui	a4,0xfffff
    80200d1e:	00e5f7b3          	and	a5,a1,a4
    last = PGROUNDDOWN(va + size - 1);
    80200d22:	fff60993          	add	s3,a2,-1 # fff <_start-0x801ff001>
    80200d26:	99ae                	add	s3,s3,a1
    80200d28:	00e9f9b3          	and	s3,s3,a4
    a = PGROUNDDOWN(va);
    80200d2c:	893e                	mv	s2,a5
    80200d2e:	40f68a33          	sub	s4,a3,a5
        }
        *pte = PA2PTE(pa) | perm | PTE_V;
        if (a == last) {
            break;
        }
        a += PGSIZE;
    80200d32:	6b85                	lui	s7,0x1
    80200d34:	a821                	j	80200d4c <mappages+0x4a>
            printf("mappages: remap is not supported\n");
    80200d36:	00005517          	auipc	a0,0x5
    80200d3a:	5ca50513          	add	a0,a0,1482 # 80206300 <_etext+0x300>
    80200d3e:	fffff097          	auipc	ra,0xfffff
    80200d42:	416080e7          	jalr	1046(ra) # 80200154 <printf>
            return -1;
    80200d46:	557d                	li	a0,-1
    80200d48:	a81d                	j	80200d7e <mappages+0x7c>
        a += PGSIZE;
    80200d4a:	995e                	add	s2,s2,s7
    for (;;) {
    80200d4c:	012a04b3          	add	s1,s4,s2
        if ((pte = walk(pagetable, a, 1)) == 0) {
    80200d50:	4605                	li	a2,1
    80200d52:	85ca                	mv	a1,s2
    80200d54:	8556                	mv	a0,s5
    80200d56:	00000097          	auipc	ra,0x0
    80200d5a:	f0e080e7          	jalr	-242(ra) # 80200c64 <walk>
    80200d5e:	cd19                	beqz	a0,80200d7c <mappages+0x7a>
        if (*pte & PTE_V) {
    80200d60:	611c                	ld	a5,0(a0)
    80200d62:	8b85                	and	a5,a5,1
    80200d64:	fbe9                	bnez	a5,80200d36 <mappages+0x34>
        *pte = PA2PTE(pa) | perm | PTE_V;
    80200d66:	80b1                	srl	s1,s1,0xc
    80200d68:	04aa                	sll	s1,s1,0xa
    80200d6a:	0164e4b3          	or	s1,s1,s6
    80200d6e:	0014e493          	or	s1,s1,1
    80200d72:	e104                	sd	s1,0(a0)
        if (a == last) {
    80200d74:	fd391be3          	bne	s2,s3,80200d4a <mappages+0x48>
        pa += PGSIZE;
    }
    return 0;
    80200d78:	4501                	li	a0,0
    80200d7a:	a011                	j	80200d7e <mappages+0x7c>
            return -1;
    80200d7c:	557d                	li	a0,-1
}
    80200d7e:	60a6                	ld	ra,72(sp)
    80200d80:	6406                	ld	s0,64(sp)
    80200d82:	74e2                	ld	s1,56(sp)
    80200d84:	7942                	ld	s2,48(sp)
    80200d86:	79a2                	ld	s3,40(sp)
    80200d88:	7a02                	ld	s4,32(sp)
    80200d8a:	6ae2                	ld	s5,24(sp)
    80200d8c:	6b42                	ld	s6,16(sp)
    80200d8e:	6ba2                	ld	s7,8(sp)
    80200d90:	6161                	add	sp,sp,80
    80200d92:	8082                	ret

0000000080200d94 <create_pagetable>:

// 创建一个空的页表
pagetable_t create_pagetable(void) {
    80200d94:	1101                	add	sp,sp,-32
    80200d96:	ec06                	sd	ra,24(sp)
    80200d98:	e822                	sd	s0,16(sp)
    80200d9a:	e426                	sd	s1,8(sp)
    80200d9c:	1000                	add	s0,sp,32
    pagetable_t pt = (pagetable_t)kalloc();
    80200d9e:	00000097          	auipc	ra,0x0
    80200da2:	896080e7          	jalr	-1898(ra) # 80200634 <kalloc>
    80200da6:	84aa                	mv	s1,a0
    if (pt == 0) return 0;
    80200da8:	c519                	beqz	a0,80200db6 <create_pagetable+0x22>
    memset(pt, 0, PGSIZE);
    80200daa:	6605                	lui	a2,0x1
    80200dac:	4581                	li	a1,0
    80200dae:	00000097          	auipc	ra,0x0
    80200db2:	bf4080e7          	jalr	-1036(ra) # 802009a2 <memset>
    return pt;
}
    80200db6:	8526                	mv	a0,s1
    80200db8:	60e2                	ld	ra,24(sp)
    80200dba:	6442                	ld	s0,16(sp)
    80200dbc:	64a2                	ld	s1,8(sp)
    80200dbe:	6105                	add	sp,sp,32
    80200dc0:	8082                	ret

0000000080200dc2 <walk_lookup>:

// 查找 PTE
pte_t *walk_lookup(pagetable_t pt, uint64 va) {
    80200dc2:	1141                	add	sp,sp,-16
    80200dc4:	e406                	sd	ra,8(sp)
    80200dc6:	e022                	sd	s0,0(sp)
    80200dc8:	0800                	add	s0,sp,16
    return walk(pt, va, 0);
    80200dca:	4601                	li	a2,0
    80200dcc:	00000097          	auipc	ra,0x0
    80200dd0:	e98080e7          	jalr	-360(ra) # 80200c64 <walk>
}
    80200dd4:	60a2                	ld	ra,8(sp)
    80200dd6:	6402                	ld	s0,0(sp)
    80200dd8:	0141                	add	sp,sp,16
    80200dda:	8082                	ret

0000000080200ddc <map_page>:

// 映射单个页
int map_page(pagetable_t pt, uint64 va, uint64 pa, int perm) {
    80200ddc:	1141                	add	sp,sp,-16
    80200dde:	e406                	sd	ra,8(sp)
    80200de0:	e022                	sd	s0,0(sp)
    80200de2:	0800                	add	s0,sp,16
    80200de4:	8736                	mv	a4,a3
    return mappages(pt, va, PGSIZE, pa, perm);
    80200de6:	86b2                	mv	a3,a2
    80200de8:	6605                	lui	a2,0x1
    80200dea:	00000097          	auipc	ra,0x0
    80200dee:	f18080e7          	jalr	-232(ra) # 80200d02 <mappages>
}
    80200df2:	60a2                	ld	ra,8(sp)
    80200df4:	6402                	ld	s0,0(sp)
    80200df6:	0141                	add	sp,sp,16
    80200df8:	8082                	ret

0000000080200dfa <cow_alloc>:
int cow_alloc(pagetable_t pagetable, uint64 va) {
    uint64 pa;
    pte_t *pte;
    uint flags;

    if (va >= (1L << 39)) return -1;
    80200dfa:	57fd                	li	a5,-1
    80200dfc:	83e5                	srl	a5,a5,0x19
    80200dfe:	08b7ec63          	bltu	a5,a1,80200e96 <cow_alloc+0x9c>
int cow_alloc(pagetable_t pagetable, uint64 va) {
    80200e02:	7179                	add	sp,sp,-48
    80200e04:	f406                	sd	ra,40(sp)
    80200e06:	f022                	sd	s0,32(sp)
    80200e08:	ec26                	sd	s1,24(sp)
    80200e0a:	e84a                	sd	s2,16(sp)
    80200e0c:	e44e                	sd	s3,8(sp)
    80200e0e:	1800                	add	s0,sp,48

    va = PGROUNDDOWN(va);
    pte = walk_lookup(pagetable, va);
    80200e10:	77fd                	lui	a5,0xfffff
    80200e12:	8dfd                	and	a1,a1,a5
    80200e14:	00000097          	auipc	ra,0x0
    80200e18:	fae080e7          	jalr	-82(ra) # 80200dc2 <walk_lookup>
    80200e1c:	89aa                	mv	s3,a0
    if (pte == 0) return -1;
    80200e1e:	cd35                	beqz	a0,80200e9a <cow_alloc+0xa0>
    if ((*pte & PTE_V) == 0) return -1;
    80200e20:	610c                	ld	a1,0(a0)
    80200e22:	0015f793          	and	a5,a1,1
    80200e26:	cfa5                	beqz	a5,80200e9e <cow_alloc+0xa4>
    
    // 检查是否是 COW 页 (必须是只读，且设置了 COW 标志)
    if ((*pte & PTE_COW) == 0 || (*pte & PTE_W)) {
    80200e28:	1045f793          	and	a5,a1,260
    80200e2c:	10000713          	li	a4,256
    80200e30:	06e79963          	bne	a5,a4,80200ea2 <cow_alloc+0xa8>
        return -1; 
    }

    pa = PTE2PA(*pte);
    80200e34:	81a9                	srl	a1,a1,0xa
    80200e36:	00c59913          	sll	s2,a1,0xc

    // 分配新物理页
    char *mem = kalloc();
    80200e3a:	fffff097          	auipc	ra,0xfffff
    80200e3e:	7fa080e7          	jalr	2042(ra) # 80200634 <kalloc>
    80200e42:	84aa                	mv	s1,a0
    if (mem == 0) {
    80200e44:	cd1d                	beqz	a0,80200e82 <cow_alloc+0x88>
        printf("cow_alloc: kalloc failed\n");
        return -1;
    }

    // 复制旧页内容到新页
    memmove(mem, (char*)pa, PGSIZE);
    80200e46:	6605                	lui	a2,0x1
    80200e48:	85ca                	mv	a1,s2
    80200e4a:	00000097          	auipc	ra,0x0
    80200e4e:	b7a080e7          	jalr	-1158(ra) # 802009c4 <memmove>

    // 修改 PTE：指向新页，设置 Write，清除 COW
    flags = PTE_FLAGS(*pte);
    80200e52:	0009b783          	ld	a5,0(s3)
    flags |= PTE_W;
    flags &= ~PTE_COW;
    80200e56:	2ff7f793          	and	a5,a5,767
    
    *pte = PA2PTE(mem) | flags;
    80200e5a:	0047e793          	or	a5,a5,4
    80200e5e:	80b1                	srl	s1,s1,0xc
    80200e60:	04aa                	sll	s1,s1,0xa
    80200e62:	8fc5                	or	a5,a5,s1
    80200e64:	00f9b023          	sd	a5,0(s3)

    // 减少旧物理页的引用计数
    kfree((void*)pa);
    80200e68:	854a                	mv	a0,s2
    80200e6a:	fffff097          	auipc	ra,0xfffff
    80200e6e:	5d4080e7          	jalr	1492(ra) # 8020043e <kfree>

    return 0;
    80200e72:	4501                	li	a0,0
}
    80200e74:	70a2                	ld	ra,40(sp)
    80200e76:	7402                	ld	s0,32(sp)
    80200e78:	64e2                	ld	s1,24(sp)
    80200e7a:	6942                	ld	s2,16(sp)
    80200e7c:	69a2                	ld	s3,8(sp)
    80200e7e:	6145                	add	sp,sp,48
    80200e80:	8082                	ret
        printf("cow_alloc: kalloc failed\n");
    80200e82:	00005517          	auipc	a0,0x5
    80200e86:	4a650513          	add	a0,a0,1190 # 80206328 <_etext+0x328>
    80200e8a:	fffff097          	auipc	ra,0xfffff
    80200e8e:	2ca080e7          	jalr	714(ra) # 80200154 <printf>
        return -1;
    80200e92:	557d                	li	a0,-1
    80200e94:	b7c5                	j	80200e74 <cow_alloc+0x7a>
    if (va >= (1L << 39)) return -1;
    80200e96:	557d                	li	a0,-1
}
    80200e98:	8082                	ret
    if (pte == 0) return -1;
    80200e9a:	557d                	li	a0,-1
    80200e9c:	bfe1                	j	80200e74 <cow_alloc+0x7a>
    if ((*pte & PTE_V) == 0) return -1;
    80200e9e:	557d                	li	a0,-1
    80200ea0:	bfd1                	j	80200e74 <cow_alloc+0x7a>
        return -1; 
    80200ea2:	557d                	li	a0,-1
    80200ea4:	bfc1                	j	80200e74 <cow_alloc+0x7a>

0000000080200ea6 <uvmcopy>:
int uvmcopy(pagetable_t old, pagetable_t new, uint64 sz) {
    pte_t *pte;
    uint64 pa, i;
    uint flags;

    for (i = 0; i < sz; i += PGSIZE) {
    80200ea6:	c269                	beqz	a2,80200f68 <uvmcopy+0xc2>
int uvmcopy(pagetable_t old, pagetable_t new, uint64 sz) {
    80200ea8:	711d                	add	sp,sp,-96
    80200eaa:	ec86                	sd	ra,88(sp)
    80200eac:	e8a2                	sd	s0,80(sp)
    80200eae:	e4a6                	sd	s1,72(sp)
    80200eb0:	e0ca                	sd	s2,64(sp)
    80200eb2:	fc4e                	sd	s3,56(sp)
    80200eb4:	f852                	sd	s4,48(sp)
    80200eb6:	f456                	sd	s5,40(sp)
    80200eb8:	f05a                	sd	s6,32(sp)
    80200eba:	ec5e                	sd	s7,24(sp)
    80200ebc:	e862                	sd	s8,16(sp)
    80200ebe:	e466                	sd	s9,8(sp)
    80200ec0:	1080                	add	s0,sp,96
    80200ec2:	89aa                	mv	s3,a0
    80200ec4:	8b2e                	mv	s6,a1
    80200ec6:	8932                	mv	s2,a2
    for (i = 0; i < sz; i += PGSIZE) {
    80200ec8:	4481                	li	s1,0
            continue; // 跳过未映射的页
        if ((*pte & PTE_V) == 0)
            continue; 
        
        // 跳过不可读的页 (如 guard page)
        if (!(*pte & PTE_R))
    80200eca:	4a8d                	li	s5,3
            *pte = PA2PTE(pa) | flags; 
        }

        // 将相同的物理页映射到子进程
        if (map_page(new, i, pa, flags) != 0) {
            panic("uvmcopy: map_page failed");
    80200ecc:	00005c17          	auipc	s8,0x5
    80200ed0:	47cc0c13          	add	s8,s8,1148 # 80206348 <_etext+0x348>
            *pte = PA2PTE(pa) | flags; 
    80200ed4:	7bfd                	lui	s7,0xfffff
    80200ed6:	002bdb93          	srl	s7,s7,0x2
    for (i = 0; i < sz; i += PGSIZE) {
    80200eda:	6a05                	lui	s4,0x1
    80200edc:	a80d                	j	80200f0e <uvmcopy+0x68>
            flags &= ~PTE_W;
    80200ede:	3fb6f713          	and	a4,a3,1019
            flags |= PTE_COW;
    80200ee2:	10076693          	or	a3,a4,256
            *pte = PA2PTE(pa) | flags; 
    80200ee6:	0177f7b3          	and	a5,a5,s7
    80200eea:	8fd5                	or	a5,a5,a3
    80200eec:	e11c                	sd	a5,0(a0)
        if (map_page(new, i, pa, flags) != 0) {
    80200eee:	8666                	mv	a2,s9
    80200ef0:	85a6                	mv	a1,s1
    80200ef2:	855a                	mv	a0,s6
    80200ef4:	00000097          	auipc	ra,0x0
    80200ef8:	ee8080e7          	jalr	-280(ra) # 80200ddc <map_page>
    80200efc:	e121                	bnez	a0,80200f3c <uvmcopy+0x96>
        }

        // 增加物理页的引用计数
        kref_inc((void*)pa);
    80200efe:	8566                	mv	a0,s9
    80200f00:	fffff097          	auipc	ra,0xfffff
    80200f04:	7f4080e7          	jalr	2036(ra) # 802006f4 <kref_inc>
    for (i = 0; i < sz; i += PGSIZE) {
    80200f08:	94d2                	add	s1,s1,s4
    80200f0a:	0324ff63          	bgeu	s1,s2,80200f48 <uvmcopy+0xa2>
        if ((pte = walk_lookup(old, i)) == 0)
    80200f0e:	85a6                	mv	a1,s1
    80200f10:	854e                	mv	a0,s3
    80200f12:	00000097          	auipc	ra,0x0
    80200f16:	eb0080e7          	jalr	-336(ra) # 80200dc2 <walk_lookup>
    80200f1a:	d57d                	beqz	a0,80200f08 <uvmcopy+0x62>
        if ((*pte & PTE_V) == 0)
    80200f1c:	611c                	ld	a5,0(a0)
        if (!(*pte & PTE_R))
    80200f1e:	0037f713          	and	a4,a5,3
    80200f22:	ff5713e3          	bne	a4,s5,80200f08 <uvmcopy+0x62>
        pa = PTE2PA(*pte);
    80200f26:	00a7dc93          	srl	s9,a5,0xa
    80200f2a:	0cb2                	sll	s9,s9,0xc
        flags = PTE_FLAGS(*pte);
    80200f2c:	0007869b          	sext.w	a3,a5
        if (flags & PTE_W) {
    80200f30:	0047f713          	and	a4,a5,4
    80200f34:	f74d                	bnez	a4,80200ede <uvmcopy+0x38>
        flags = PTE_FLAGS(*pte);
    80200f36:	3ff6f693          	and	a3,a3,1023
    80200f3a:	bf55                	j	80200eee <uvmcopy+0x48>
            panic("uvmcopy: map_page failed");
    80200f3c:	8562                	mv	a0,s8
    80200f3e:	fffff097          	auipc	ra,0xfffff
    80200f42:	496080e7          	jalr	1174(ra) # 802003d4 <panic>
    80200f46:	bf65                	j	80200efe <uvmcopy+0x58>
static inline uint64 r_sepc() { uint64 x; asm volatile("csrr %0, sepc" : "=r" (x)); return x; }
static inline void w_sepc(uint64 x) { asm volatile("csrw sepc, %0" : : "r" (x)); }
static inline uint64 r_stval() { uint64 x; asm volatile("csrr %0, stval" : "=r" (x) ); return x; }
static inline uint64 r_satp() { uint64 x; asm volatile("csrr %0, satp" : "=r" (x)); return x; }
static inline void w_satp(uint64 x) { asm volatile("csrw satp, %0" : : "r" (x)); }
static inline void sfence_vma() { asm volatile("sfence.vma zero, zero"); }
    80200f48:	12000073          	sfence.vma
    }
    // 刷新 TLB，因为我们在父进程中移除了 PTE_W
    sfence_vma();
    return 0;
}
    80200f4c:	4501                	li	a0,0
    80200f4e:	60e6                	ld	ra,88(sp)
    80200f50:	6446                	ld	s0,80(sp)
    80200f52:	64a6                	ld	s1,72(sp)
    80200f54:	6906                	ld	s2,64(sp)
    80200f56:	79e2                	ld	s3,56(sp)
    80200f58:	7a42                	ld	s4,48(sp)
    80200f5a:	7aa2                	ld	s5,40(sp)
    80200f5c:	7b02                	ld	s6,32(sp)
    80200f5e:	6be2                	ld	s7,24(sp)
    80200f60:	6c42                	ld	s8,16(sp)
    80200f62:	6ca2                	ld	s9,8(sp)
    80200f64:	6125                	add	sp,sp,96
    80200f66:	8082                	ret
    80200f68:	12000073          	sfence.vma
    80200f6c:	4501                	li	a0,0
    80200f6e:	8082                	ret

0000000080200f70 <uvmunmap>:

// 释放用户内存映射
void uvmunmap(pagetable_t pt, uint64 va, uint64 npages, int do_free) {
    80200f70:	7139                	add	sp,sp,-64
    80200f72:	fc06                	sd	ra,56(sp)
    80200f74:	f822                	sd	s0,48(sp)
    80200f76:	f426                	sd	s1,40(sp)
    80200f78:	f04a                	sd	s2,32(sp)
    80200f7a:	ec4e                	sd	s3,24(sp)
    80200f7c:	e852                	sd	s4,16(sp)
    80200f7e:	e456                	sd	s5,8(sp)
    80200f80:	e05a                	sd	s6,0(sp)
    80200f82:	0080                	add	s0,sp,64
    uint64 a;
    pte_t *pte;

    for (a = va; a < va + npages * PGSIZE; a += PGSIZE) {
    80200f84:	0632                	sll	a2,a2,0xc
    80200f86:	00b609b3          	add	s3,a2,a1
    80200f8a:	0535f263          	bgeu	a1,s3,80200fce <uvmunmap+0x5e>
    80200f8e:	8a2a                	mv	s4,a0
    80200f90:	892e                	mv	s2,a1
    80200f92:	8ab6                	mv	s5,a3
    80200f94:	6b05                	lui	s6,0x1
    80200f96:	a031                	j	80200fa2 <uvmunmap+0x32>
        
        uint64 pa = PTE2PA(*pte);
        if (do_free) {
            kfree((void*)pa); // kfree 会自动处理引用计数
        }
        *pte = 0;
    80200f98:	0004b023          	sd	zero,0(s1)
    for (a = va; a < va + npages * PGSIZE; a += PGSIZE) {
    80200f9c:	995a                	add	s2,s2,s6
    80200f9e:	03397863          	bgeu	s2,s3,80200fce <uvmunmap+0x5e>
        if ((pte = walk_lookup(pt, a)) == 0) continue; 
    80200fa2:	85ca                	mv	a1,s2
    80200fa4:	8552                	mv	a0,s4
    80200fa6:	00000097          	auipc	ra,0x0
    80200faa:	e1c080e7          	jalr	-484(ra) # 80200dc2 <walk_lookup>
    80200fae:	84aa                	mv	s1,a0
    80200fb0:	d575                	beqz	a0,80200f9c <uvmunmap+0x2c>
        if ((*pte & PTE_V) == 0) continue;
    80200fb2:	611c                	ld	a5,0(a0)
    80200fb4:	0017f713          	and	a4,a5,1
    80200fb8:	d375                	beqz	a4,80200f9c <uvmunmap+0x2c>
        if (do_free) {
    80200fba:	fc0a8fe3          	beqz	s5,80200f98 <uvmunmap+0x28>
        uint64 pa = PTE2PA(*pte);
    80200fbe:	83a9                	srl	a5,a5,0xa
            kfree((void*)pa); // kfree 会自动处理引用计数
    80200fc0:	00c79513          	sll	a0,a5,0xc
    80200fc4:	fffff097          	auipc	ra,0xfffff
    80200fc8:	47a080e7          	jalr	1146(ra) # 8020043e <kfree>
    80200fcc:	b7f1                	j	80200f98 <uvmunmap+0x28>
    80200fce:	12000073          	sfence.vma
    }
    sfence_vma();
}
    80200fd2:	70e2                	ld	ra,56(sp)
    80200fd4:	7442                	ld	s0,48(sp)
    80200fd6:	74a2                	ld	s1,40(sp)
    80200fd8:	7902                	ld	s2,32(sp)
    80200fda:	69e2                	ld	s3,24(sp)
    80200fdc:	6a42                	ld	s4,16(sp)
    80200fde:	6aa2                	ld	s5,8(sp)
    80200fe0:	6b02                	ld	s6,0(sp)
    80200fe2:	6121                	add	sp,sp,64
    80200fe4:	8082                	ret

0000000080200fe6 <kvminit>:

void kvminit(void) {
    80200fe6:	1101                	add	sp,sp,-32
    80200fe8:	ec06                	sd	ra,24(sp)
    80200fea:	e822                	sd	s0,16(sp)
    80200fec:	e426                	sd	s1,8(sp)
    80200fee:	1000                	add	s0,sp,32
    extern char etext[]; 
    
    kernel_pagetable = (pagetable_t)kalloc();
    80200ff0:	fffff097          	auipc	ra,0xfffff
    80200ff4:	644080e7          	jalr	1604(ra) # 80200634 <kalloc>
    80200ff8:	0000f497          	auipc	s1,0xf
    80200ffc:	00848493          	add	s1,s1,8 # 80210000 <kernel_pagetable>
    80201000:	e088                	sd	a0,0(s1)
    memset(kernel_pagetable, 0, PGSIZE);
    80201002:	6605                	lui	a2,0x1
    80201004:	4581                	li	a1,0
    80201006:	00000097          	auipc	ra,0x0
    8020100a:	99c080e7          	jalr	-1636(ra) # 802009a2 <memset>

    // 映射 UART 设备
    if (mappages(kernel_pagetable, 0x10000000, PGSIZE, 0x10000000, PTE_R | PTE_W) < 0)
    8020100e:	4719                	li	a4,6
    80201010:	100006b7          	lui	a3,0x10000
    80201014:	6605                	lui	a2,0x1
    80201016:	100005b7          	lui	a1,0x10000
    8020101a:	6088                	ld	a0,0(s1)
    8020101c:	00000097          	auipc	ra,0x0
    80201020:	ce6080e7          	jalr	-794(ra) # 80200d02 <mappages>
    80201024:	08054663          	bltz	a0,802010b0 <kvminit+0xca>
        panic("kvminit: uart map failed");

    // 映射 VirtIO 磁盘 MMIO
    if (mappages(kernel_pagetable, VIRTIO0, PGSIZE, VIRTIO0, PTE_R | PTE_W) < 0)
    80201028:	4719                	li	a4,6
    8020102a:	100016b7          	lui	a3,0x10001
    8020102e:	6605                	lui	a2,0x1
    80201030:	100015b7          	lui	a1,0x10001
    80201034:	0000f517          	auipc	a0,0xf
    80201038:	fcc53503          	ld	a0,-52(a0) # 80210000 <kernel_pagetable>
    8020103c:	00000097          	auipc	ra,0x0
    80201040:	cc6080e7          	jalr	-826(ra) # 80200d02 <mappages>
    80201044:	06054f63          	bltz	a0,802010c2 <kvminit+0xdc>
        panic("kvminit: virtio map failed");

    // 映射内核代码段 (R-X)
    if (mappages(kernel_pagetable, 0x80200000, (uint64)etext - 0x80200000, 0x80200000, PTE_R | PTE_X) < 0)
    80201048:	00005497          	auipc	s1,0x5
    8020104c:	fb848493          	add	s1,s1,-72 # 80206000 <_etext>
    80201050:	4729                	li	a4,10
    80201052:	40100693          	li	a3,1025
    80201056:	06d6                	sll	a3,a3,0x15
    80201058:	bff00613          	li	a2,-1025
    8020105c:	0656                	sll	a2,a2,0x15
    8020105e:	9626                	add	a2,a2,s1
    80201060:	85b6                	mv	a1,a3
    80201062:	0000f517          	auipc	a0,0xf
    80201066:	f9e53503          	ld	a0,-98(a0) # 80210000 <kernel_pagetable>
    8020106a:	00000097          	auipc	ra,0x0
    8020106e:	c98080e7          	jalr	-872(ra) # 80200d02 <mappages>
    80201072:	06054163          	bltz	a0,802010d4 <kvminit+0xee>
        panic("kvminit: text map failed");

    // 映射内核数据段和剩余物理内存 (RW-)
    if (mappages(kernel_pagetable, (uint64)etext, 0x88000000 - (uint64)etext, (uint64)etext, PTE_R | PTE_W) < 0)
    80201076:	4719                	li	a4,6
    80201078:	86a6                	mv	a3,s1
    8020107a:	4645                	li	a2,17
    8020107c:	066e                	sll	a2,a2,0x1b
    8020107e:	8e05                	sub	a2,a2,s1
    80201080:	85a6                	mv	a1,s1
    80201082:	0000f517          	auipc	a0,0xf
    80201086:	f7e53503          	ld	a0,-130(a0) # 80210000 <kernel_pagetable>
    8020108a:	00000097          	auipc	ra,0x0
    8020108e:	c78080e7          	jalr	-904(ra) # 80200d02 <mappages>
    80201092:	04054a63          	bltz	a0,802010e6 <kvminit+0x100>
        panic("kvminit: data map failed");
    
    printf("kvminit: kernel page table created.\n");
    80201096:	00005517          	auipc	a0,0x5
    8020109a:	35250513          	add	a0,a0,850 # 802063e8 <_etext+0x3e8>
    8020109e:	fffff097          	auipc	ra,0xfffff
    802010a2:	0b6080e7          	jalr	182(ra) # 80200154 <printf>
}
    802010a6:	60e2                	ld	ra,24(sp)
    802010a8:	6442                	ld	s0,16(sp)
    802010aa:	64a2                	ld	s1,8(sp)
    802010ac:	6105                	add	sp,sp,32
    802010ae:	8082                	ret
        panic("kvminit: uart map failed");
    802010b0:	00005517          	auipc	a0,0x5
    802010b4:	2b850513          	add	a0,a0,696 # 80206368 <_etext+0x368>
    802010b8:	fffff097          	auipc	ra,0xfffff
    802010bc:	31c080e7          	jalr	796(ra) # 802003d4 <panic>
    802010c0:	b7a5                	j	80201028 <kvminit+0x42>
        panic("kvminit: virtio map failed");
    802010c2:	00005517          	auipc	a0,0x5
    802010c6:	2c650513          	add	a0,a0,710 # 80206388 <_etext+0x388>
    802010ca:	fffff097          	auipc	ra,0xfffff
    802010ce:	30a080e7          	jalr	778(ra) # 802003d4 <panic>
    802010d2:	bf9d                	j	80201048 <kvminit+0x62>
        panic("kvminit: text map failed");
    802010d4:	00005517          	auipc	a0,0x5
    802010d8:	2d450513          	add	a0,a0,724 # 802063a8 <_etext+0x3a8>
    802010dc:	fffff097          	auipc	ra,0xfffff
    802010e0:	2f8080e7          	jalr	760(ra) # 802003d4 <panic>
    802010e4:	bf49                	j	80201076 <kvminit+0x90>
        panic("kvminit: data map failed");
    802010e6:	00005517          	auipc	a0,0x5
    802010ea:	2e250513          	add	a0,a0,738 # 802063c8 <_etext+0x3c8>
    802010ee:	fffff097          	auipc	ra,0xfffff
    802010f2:	2e6080e7          	jalr	742(ra) # 802003d4 <panic>
    802010f6:	b745                	j	80201096 <kvminit+0xb0>

00000000802010f8 <kvminithart>:

void kvminithart(void) {
    802010f8:	1141                	add	sp,sp,-16
    802010fa:	e406                	sd	ra,8(sp)
    802010fc:	e022                	sd	s0,0(sp)
    802010fe:	0800                	add	s0,sp,16
    w_satp(MAKE_SATP(kernel_pagetable));
    80201100:	0000f797          	auipc	a5,0xf
    80201104:	f007b783          	ld	a5,-256(a5) # 80210000 <kernel_pagetable>
    80201108:	83b1                	srl	a5,a5,0xc
    8020110a:	577d                	li	a4,-1
    8020110c:	177e                	sll	a4,a4,0x3f
    8020110e:	8fd9                	or	a5,a5,a4
static inline void w_satp(uint64 x) { asm volatile("csrw satp, %0" : : "r" (x)); }
    80201110:	18079073          	csrw	satp,a5
static inline void sfence_vma() { asm volatile("sfence.vma zero, zero"); }
    80201114:	12000073          	sfence.vma
    sfence_vma();
    printf("kvminithart: virtual memory enabled.\n");
    80201118:	00005517          	auipc	a0,0x5
    8020111c:	2f850513          	add	a0,a0,760 # 80206410 <_etext+0x410>
    80201120:	fffff097          	auipc	ra,0xfffff
    80201124:	034080e7          	jalr	52(ra) # 80200154 <printf>
}
    80201128:	60a2                	ld	ra,8(sp)
    8020112a:	6402                	ld	s0,0(sp)
    8020112c:	0141                	add	sp,sp,16
    8020112e:	8082                	ret

0000000080201130 <freeproc>:
    if (mappages(pt, 0x10000000, PGSIZE, 0x10000000, PTE_R | PTE_W) < 0) return -1;
    if (mappages(pt, 0x10001000, PGSIZE, 0x10001000, PTE_R | PTE_W) < 0) return -1;
    return 0;
}

static void freeproc(struct proc *p) {
    80201130:	7179                	add	sp,sp,-48
    80201132:	f406                	sd	ra,40(sp)
    80201134:	f022                	sd	s0,32(sp)
    80201136:	ec26                	sd	s1,24(sp)
    80201138:	e84a                	sd	s2,16(sp)
    8020113a:	e44e                	sd	s3,8(sp)
    8020113c:	1800                	add	s0,sp,48
    8020113e:	892a                	mv	s2,a0
    if (p->trapframe) kfree((void*)p->trapframe);
    80201140:	6128                	ld	a0,64(a0)
    80201142:	c509                	beqz	a0,8020114c <freeproc+0x1c>
    80201144:	fffff097          	auipc	ra,0xfffff
    80201148:	2fa080e7          	jalr	762(ra) # 8020043e <kfree>
    p->trapframe = 0;
    8020114c:	04093023          	sd	zero,64(s2)
    if (p->kstack) kfree((void*)p->kstack);
    80201150:	03893503          	ld	a0,56(s2)
    80201154:	e129                	bnez	a0,80201196 <freeproc+0x66>
    p->kstack = 0;
    80201156:	02093c23          	sd	zero,56(s2)
    if(p->pagetable) uvmunmap(p->pagetable, 0, 0x40000 / PGSIZE, 1);
    8020115a:	04893503          	ld	a0,72(s2)
    8020115e:	c909                	beqz	a0,80201170 <freeproc+0x40>
    80201160:	4685                	li	a3,1
    80201162:	04000613          	li	a2,64
    80201166:	4581                	li	a1,0
    80201168:	00000097          	auipc	ra,0x0
    8020116c:	e08080e7          	jalr	-504(ra) # 80200f70 <uvmunmap>
    p->pagetable = 0;
    80201170:	04093423          	sd	zero,72(s2)
    p->pid = 0;
    80201174:	00092e23          	sw	zero,28(s2)
    p->parent = 0;
    80201178:	02093023          	sd	zero,32(s2)
    p->name[0] = 0;
    8020117c:	0c090423          	sb	zero,200(s2)
    p->chan = 0;
    80201180:	02093423          	sd	zero,40(s2)
    p->killed = 0;
    80201184:	02092823          	sw	zero,48(s2)
    p->xstate = 0;
    80201188:	02092a23          	sw	zero,52(s2)
    for (int i = 0; i < NOFILE; i++) {
    8020118c:	0d890493          	add	s1,s2,216
    80201190:	15890993          	add	s3,s2,344
    80201194:	a809                	j	802011a6 <freeproc+0x76>
    if (p->kstack) kfree((void*)p->kstack);
    80201196:	fffff097          	auipc	ra,0xfffff
    8020119a:	2a8080e7          	jalr	680(ra) # 8020043e <kfree>
    8020119e:	bf65                	j	80201156 <freeproc+0x26>
    for (int i = 0; i < NOFILE; i++) {
    802011a0:	04a1                	add	s1,s1,8
    802011a2:	01348b63          	beq	s1,s3,802011b8 <freeproc+0x88>
        if (p->ofile[i]) {
    802011a6:	6088                	ld	a0,0(s1)
    802011a8:	dd65                	beqz	a0,802011a0 <freeproc+0x70>
            fileclose(p->ofile[i]);
    802011aa:	00003097          	auipc	ra,0x3
    802011ae:	89a080e7          	jalr	-1894(ra) # 80203a44 <fileclose>
            p->ofile[i] = 0;
    802011b2:	0004b023          	sd	zero,0(s1)
    802011b6:	b7ed                	j	802011a0 <freeproc+0x70>
        }
    }
    if (p->cwd) {
    802011b8:	15893503          	ld	a0,344(s2)
    802011bc:	c519                	beqz	a0,802011ca <freeproc+0x9a>
        iput(p->cwd);
    802011be:	00002097          	auipc	ra,0x2
    802011c2:	9a8080e7          	jalr	-1624(ra) # 80202b66 <iput>
        p->cwd = 0;
    802011c6:	14093c23          	sd	zero,344(s2)
    }
    p->state = UNUSED;
    802011ca:	00092c23          	sw	zero,24(s2)
}
    802011ce:	70a2                	ld	ra,40(sp)
    802011d0:	7402                	ld	s0,32(sp)
    802011d2:	64e2                	ld	s1,24(sp)
    802011d4:	6942                	ld	s2,16(sp)
    802011d6:	69a2                	ld	s3,8(sp)
    802011d8:	6145                	add	sp,sp,48
    802011da:	8082                	ret

00000000802011dc <allocproc>:
    release(&p->lock);
    if (p->entry) p->entry();
    exit(0);
}

static struct proc* allocproc(void) {
    802011dc:	7179                	add	sp,sp,-48
    802011de:	f406                	sd	ra,40(sp)
    802011e0:	f022                	sd	s0,32(sp)
    802011e2:	ec26                	sd	s1,24(sp)
    802011e4:	e84a                	sd	s2,16(sp)
    802011e6:	e44e                	sd	s3,8(sp)
    802011e8:	1800                	add	s0,sp,48
    struct proc *p;
    for(p = proc; p < &proc[NPROC]; p++) {
    802011ea:	00028497          	auipc	s1,0x28
    802011ee:	eb648493          	add	s1,s1,-330 # 802290a0 <proc>
    802011f2:	0002d917          	auipc	s2,0x2d
    802011f6:	6ae90913          	add	s2,s2,1710 # 8022e8a0 <bcache>
        acquire(&p->lock);
    802011fa:	8526                	mv	a0,s1
    802011fc:	fffff097          	auipc	ra,0xfffff
    80201200:	63e080e7          	jalr	1598(ra) # 8020083a <acquire>
        if(p->state == UNUSED) {
    80201204:	4c9c                	lw	a5,24(s1)
    80201206:	cf81                	beqz	a5,8020121e <allocproc+0x42>
            goto found;
        } else {
            release(&p->lock);
    80201208:	8526                	mv	a0,s1
    8020120a:	fffff097          	auipc	ra,0xfffff
    8020120e:	722080e7          	jalr	1826(ra) # 8020092c <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80201212:	16048493          	add	s1,s1,352
    80201216:	ff2492e3          	bne	s1,s2,802011fa <allocproc+0x1e>
        }
    }
    return 0;
    8020121a:	4481                	li	s1,0
    8020121c:	a8e5                	j	80201314 <allocproc+0x138>

found:
    p->pid = nextpid++;
    8020121e:	00006717          	auipc	a4,0x6
    80201222:	c9270713          	add	a4,a4,-878 # 80206eb0 <nextpid>
    80201226:	431c                	lw	a5,0(a4)
    80201228:	0017869b          	addw	a3,a5,1
    8020122c:	c314                	sw	a3,0(a4)
    8020122e:	ccdc                	sw	a5,28(s1)
    p->state = USED;
    80201230:	4785                	li	a5,1
    80201232:	cc9c                	sw	a5,24(s1)

    if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80201234:	fffff097          	auipc	ra,0xfffff
    80201238:	400080e7          	jalr	1024(ra) # 80200634 <kalloc>
    8020123c:	892a                	mv	s2,a0
    8020123e:	e0a8                	sd	a0,64(s1)
    80201240:	c175                	beqz	a0,80201324 <allocproc+0x148>
        freeproc(p);
        release(&p->lock);
        return 0;
    }
    memset(p->trapframe, 0, PGSIZE);
    80201242:	6605                	lui	a2,0x1
    80201244:	4581                	li	a1,0
    80201246:	fffff097          	auipc	ra,0xfffff
    8020124a:	75c080e7          	jalr	1884(ra) # 802009a2 <memset>

    if((p->pagetable = create_pagetable()) == 0) {
    8020124e:	00000097          	auipc	ra,0x0
    80201252:	b46080e7          	jalr	-1210(ra) # 80200d94 <create_pagetable>
    80201256:	892a                	mv	s2,a0
    80201258:	e4a8                	sd	a0,72(s1)
    8020125a:	c16d                	beqz	a0,8020133c <allocproc+0x160>
    if (mappages(pt, 0x80200000, (uint64)etext - 0x80200000, 0x80200000, PTE_R | PTE_X) < 0) return -1;
    8020125c:	00005997          	auipc	s3,0x5
    80201260:	da498993          	add	s3,s3,-604 # 80206000 <_etext>
    80201264:	4729                	li	a4,10
    80201266:	40100693          	li	a3,1025
    8020126a:	06d6                	sll	a3,a3,0x15
    8020126c:	bff00613          	li	a2,-1025
    80201270:	0656                	sll	a2,a2,0x15
    80201272:	964e                	add	a2,a2,s3
    80201274:	85b6                	mv	a1,a3
    80201276:	00000097          	auipc	ra,0x0
    8020127a:	a8c080e7          	jalr	-1396(ra) # 80200d02 <mappages>
    8020127e:	0c054b63          	bltz	a0,80201354 <allocproc+0x178>
    if (mappages(pt, (uint64)etext, 0x88000000 - (uint64)etext, (uint64)etext, PTE_R | PTE_W) < 0) return -1;
    80201282:	4719                	li	a4,6
    80201284:	86ce                	mv	a3,s3
    80201286:	4645                	li	a2,17
    80201288:	066e                	sll	a2,a2,0x1b
    8020128a:	41360633          	sub	a2,a2,s3
    8020128e:	85ce                	mv	a1,s3
    80201290:	854a                	mv	a0,s2
    80201292:	00000097          	auipc	ra,0x0
    80201296:	a70080e7          	jalr	-1424(ra) # 80200d02 <mappages>
    8020129a:	0a054d63          	bltz	a0,80201354 <allocproc+0x178>
    if (mappages(pt, 0x10000000, PGSIZE, 0x10000000, PTE_R | PTE_W) < 0) return -1;
    8020129e:	4719                	li	a4,6
    802012a0:	100006b7          	lui	a3,0x10000
    802012a4:	6605                	lui	a2,0x1
    802012a6:	100005b7          	lui	a1,0x10000
    802012aa:	854a                	mv	a0,s2
    802012ac:	00000097          	auipc	ra,0x0
    802012b0:	a56080e7          	jalr	-1450(ra) # 80200d02 <mappages>
    802012b4:	0a054063          	bltz	a0,80201354 <allocproc+0x178>
    if (mappages(pt, 0x10001000, PGSIZE, 0x10001000, PTE_R | PTE_W) < 0) return -1;
    802012b8:	4719                	li	a4,6
    802012ba:	100016b7          	lui	a3,0x10001
    802012be:	6605                	lui	a2,0x1
    802012c0:	100015b7          	lui	a1,0x10001
    802012c4:	854a                	mv	a0,s2
    802012c6:	00000097          	auipc	ra,0x0
    802012ca:	a3c080e7          	jalr	-1476(ra) # 80200d02 <mappages>
        freeproc(p);
        release(&p->lock);
        return 0;
    }
    
    if (uvm_kmap(p->pagetable) < 0) {
    802012ce:	08054363          	bltz	a0,80201354 <allocproc+0x178>
        freeproc(p);
        release(&p->lock);
        return 0;
    }

    if((p->kstack = (uint64)kalloc()) == 0){
    802012d2:	fffff097          	auipc	ra,0xfffff
    802012d6:	362080e7          	jalr	866(ra) # 80200634 <kalloc>
    802012da:	892a                	mv	s2,a0
    802012dc:	fc88                	sd	a0,56(s1)
    802012de:	cd59                	beqz	a0,8020137c <allocproc+0x1a0>
        freeproc(p);
        release(&p->lock);
        return 0;
    }
    memset((void*)p->kstack, 0, PGSIZE);
    802012e0:	6605                	lui	a2,0x1
    802012e2:	4581                	li	a1,0
    802012e4:	fffff097          	auipc	ra,0xfffff
    802012e8:	6be080e7          	jalr	1726(ra) # 802009a2 <memset>

    p->context.sp = p->kstack + PGSIZE;
    802012ec:	7c9c                	ld	a5,56(s1)
    802012ee:	6705                	lui	a4,0x1
    802012f0:	97ba                	add	a5,a5,a4
    802012f2:	ecbc                	sd	a5,88(s1)
    p->context.ra = (uint64)proc_entry;
    802012f4:	00000797          	auipc	a5,0x0
    802012f8:	6ac78793          	add	a5,a5,1708 # 802019a0 <proc_entry>
    802012fc:	e8bc                	sd	a5,80(s1)
    
    for (int i = 0; i < NOFILE; i++) {
    802012fe:	0d848793          	add	a5,s1,216
    80201302:	15848713          	add	a4,s1,344
        p->ofile[i] = 0;
    80201306:	0007b023          	sd	zero,0(a5)
    for (int i = 0; i < NOFILE; i++) {
    8020130a:	07a1                	add	a5,a5,8
    8020130c:	fee79de3          	bne	a5,a4,80201306 <allocproc+0x12a>
    }
    p->cwd = 0;
    80201310:	1404bc23          	sd	zero,344(s1)

    return p;
}
    80201314:	8526                	mv	a0,s1
    80201316:	70a2                	ld	ra,40(sp)
    80201318:	7402                	ld	s0,32(sp)
    8020131a:	64e2                	ld	s1,24(sp)
    8020131c:	6942                	ld	s2,16(sp)
    8020131e:	69a2                	ld	s3,8(sp)
    80201320:	6145                	add	sp,sp,48
    80201322:	8082                	ret
        freeproc(p);
    80201324:	8526                	mv	a0,s1
    80201326:	00000097          	auipc	ra,0x0
    8020132a:	e0a080e7          	jalr	-502(ra) # 80201130 <freeproc>
        release(&p->lock);
    8020132e:	8526                	mv	a0,s1
    80201330:	fffff097          	auipc	ra,0xfffff
    80201334:	5fc080e7          	jalr	1532(ra) # 8020092c <release>
        return 0;
    80201338:	84ca                	mv	s1,s2
    8020133a:	bfe9                	j	80201314 <allocproc+0x138>
        freeproc(p);
    8020133c:	8526                	mv	a0,s1
    8020133e:	00000097          	auipc	ra,0x0
    80201342:	df2080e7          	jalr	-526(ra) # 80201130 <freeproc>
        release(&p->lock);
    80201346:	8526                	mv	a0,s1
    80201348:	fffff097          	auipc	ra,0xfffff
    8020134c:	5e4080e7          	jalr	1508(ra) # 8020092c <release>
        return 0;
    80201350:	84ca                	mv	s1,s2
    80201352:	b7c9                	j	80201314 <allocproc+0x138>
        printf("allocproc: uvm_kmap failed\n"); // Add print
    80201354:	00005517          	auipc	a0,0x5
    80201358:	0e450513          	add	a0,a0,228 # 80206438 <_etext+0x438>
    8020135c:	fffff097          	auipc	ra,0xfffff
    80201360:	df8080e7          	jalr	-520(ra) # 80200154 <printf>
        freeproc(p);
    80201364:	8526                	mv	a0,s1
    80201366:	00000097          	auipc	ra,0x0
    8020136a:	dca080e7          	jalr	-566(ra) # 80201130 <freeproc>
        release(&p->lock);
    8020136e:	8526                	mv	a0,s1
    80201370:	fffff097          	auipc	ra,0xfffff
    80201374:	5bc080e7          	jalr	1468(ra) # 8020092c <release>
        return 0;
    80201378:	4481                	li	s1,0
    8020137a:	bf69                	j	80201314 <allocproc+0x138>
        freeproc(p);
    8020137c:	8526                	mv	a0,s1
    8020137e:	00000097          	auipc	ra,0x0
    80201382:	db2080e7          	jalr	-590(ra) # 80201130 <freeproc>
        release(&p->lock);
    80201386:	8526                	mv	a0,s1
    80201388:	fffff097          	auipc	ra,0xfffff
    8020138c:	5a4080e7          	jalr	1444(ra) # 8020092c <release>
        return 0;
    80201390:	84ca                	mv	s1,s2
    80201392:	b749                	j	80201314 <allocproc+0x138>

0000000080201394 <mycpu>:
struct cpu* mycpu(void) { return &cpus[0]; }
    80201394:	1141                	add	sp,sp,-16
    80201396:	e422                	sd	s0,8(sp)
    80201398:	0800                	add	s0,sp,16
    8020139a:	00028517          	auipc	a0,0x28
    8020139e:	c8650513          	add	a0,a0,-890 # 80229020 <cpus>
    802013a2:	6422                	ld	s0,8(sp)
    802013a4:	0141                	add	sp,sp,16
    802013a6:	8082                	ret

00000000802013a8 <myproc>:
struct proc* myproc(void) { 
    802013a8:	1101                	add	sp,sp,-32
    802013aa:	ec06                	sd	ra,24(sp)
    802013ac:	e822                	sd	s0,16(sp)
    802013ae:	e426                	sd	s1,8(sp)
    802013b0:	1000                	add	s0,sp,32
    push_off(); 
    802013b2:	fffff097          	auipc	ra,0xfffff
    802013b6:	43c080e7          	jalr	1084(ra) # 802007ee <push_off>
    struct proc *p = cpus[0].proc; 
    802013ba:	00028497          	auipc	s1,0x28
    802013be:	c664b483          	ld	s1,-922(s1) # 80229020 <cpus>
    pop_off(); 
    802013c2:	fffff097          	auipc	ra,0xfffff
    802013c6:	4ec080e7          	jalr	1260(ra) # 802008ae <pop_off>
}
    802013ca:	8526                	mv	a0,s1
    802013cc:	60e2                	ld	ra,24(sp)
    802013ce:	6442                	ld	s0,16(sp)
    802013d0:	64a2                	ld	s1,8(sp)
    802013d2:	6105                	add	sp,sp,32
    802013d4:	8082                	ret

00000000802013d6 <procinit>:

void procinit(void) {
    802013d6:	7179                	add	sp,sp,-48
    802013d8:	f406                	sd	ra,40(sp)
    802013da:	f022                	sd	s0,32(sp)
    802013dc:	ec26                	sd	s1,24(sp)
    802013de:	e84a                	sd	s2,16(sp)
    802013e0:	e44e                	sd	s3,8(sp)
    802013e2:	1800                	add	s0,sp,48
    for (int i = 0; i < NPROC; i++) {
    802013e4:	00028497          	auipc	s1,0x28
    802013e8:	cbc48493          	add	s1,s1,-836 # 802290a0 <proc>
    802013ec:	0002d997          	auipc	s3,0x2d
    802013f0:	4b498993          	add	s3,s3,1204 # 8022e8a0 <bcache>
        spinlock_init(&proc[i].lock, "proc");
    802013f4:	00005917          	auipc	s2,0x5
    802013f8:	06490913          	add	s2,s2,100 # 80206458 <_etext+0x458>
    802013fc:	85ca                	mv	a1,s2
    802013fe:	8526                	mv	a0,s1
    80201400:	fffff097          	auipc	ra,0xfffff
    80201404:	3d8080e7          	jalr	984(ra) # 802007d8 <spinlock_init>
        proc[i].state = UNUSED;
    80201408:	0004ac23          	sw	zero,24(s1)
    for (int i = 0; i < NPROC; i++) {
    8020140c:	16048493          	add	s1,s1,352
    80201410:	ff3496e3          	bne	s1,s3,802013fc <procinit+0x26>
    }
    printf("procinit: complete\n");
    80201414:	00005517          	auipc	a0,0x5
    80201418:	04c50513          	add	a0,a0,76 # 80206460 <_etext+0x460>
    8020141c:	fffff097          	auipc	ra,0xfffff
    80201420:	d38080e7          	jalr	-712(ra) # 80200154 <printf>
}
    80201424:	70a2                	ld	ra,40(sp)
    80201426:	7402                	ld	s0,32(sp)
    80201428:	64e2                	ld	s1,24(sp)
    8020142a:	6942                	ld	s2,16(sp)
    8020142c:	69a2                	ld	s3,8(sp)
    8020142e:	6145                	add	sp,sp,48
    80201430:	8082                	ret

0000000080201432 <create_process>:

int create_process(void (*entry)(void)) {
    80201432:	1101                	add	sp,sp,-32
    80201434:	ec06                	sd	ra,24(sp)
    80201436:	e822                	sd	s0,16(sp)
    80201438:	e426                	sd	s1,8(sp)
    8020143a:	e04a                	sd	s2,0(sp)
    8020143c:	1000                	add	s0,sp,32
    8020143e:	892a                	mv	s2,a0
    struct proc *p = allocproc();
    80201440:	00000097          	auipc	ra,0x0
    80201444:	d9c080e7          	jalr	-612(ra) # 802011dc <allocproc>
    if (p == 0) return -1;
    80201448:	cd3d                	beqz	a0,802014c6 <create_process+0x94>
    8020144a:	84aa                	mv	s1,a0
    
    char *mem = kalloc();
    8020144c:	fffff097          	auipc	ra,0xfffff
    80201450:	1e8080e7          	jalr	488(ra) # 80200634 <kalloc>
    80201454:	862a                	mv	a2,a0
    if(!mem) { 
    80201456:	c139                	beqz	a0,8020149c <create_process+0x6a>
        freeproc(p); 
        release(&p->lock); 
        return -1; 
    }
    map_page(p->pagetable, 0, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U); 
    80201458:	46f9                	li	a3,30
    8020145a:	4581                	li	a1,0
    8020145c:	64a8                	ld	a0,72(s1)
    8020145e:	00000097          	auipc	ra,0x0
    80201462:	97e080e7          	jalr	-1666(ra) # 80200ddc <map_page>
    
    p->entry = entry;
    80201466:	0d24b023          	sd	s2,192(s1)
    p->parent = 0; 
    8020146a:	0204b023          	sd	zero,32(s1)
    p->trapframe->epc = 0; 
    8020146e:	60bc                	ld	a5,64(s1)
    80201470:	0007bc23          	sd	zero,24(a5)
    p->trapframe->sp = PGSIZE; 
    80201474:	60bc                	ld	a5,64(s1)
    80201476:	6705                	lui	a4,0x1
    80201478:	fb98                	sd	a4,48(a5)
    
    if (p->cwd == 0) p->cwd = iget(ROOTDEV, ROOTINO);
    8020147a:	1584b783          	ld	a5,344(s1)
    8020147e:	cb9d                	beqz	a5,802014b4 <create_process+0x82>
    
    p->state = RUNNABLE;
    80201480:	478d                	li	a5,3
    80201482:	cc9c                	sw	a5,24(s1)
    release(&p->lock);
    80201484:	8526                	mv	a0,s1
    80201486:	fffff097          	auipc	ra,0xfffff
    8020148a:	4a6080e7          	jalr	1190(ra) # 8020092c <release>
    return p->pid;
    8020148e:	4cc8                	lw	a0,28(s1)
}
    80201490:	60e2                	ld	ra,24(sp)
    80201492:	6442                	ld	s0,16(sp)
    80201494:	64a2                	ld	s1,8(sp)
    80201496:	6902                	ld	s2,0(sp)
    80201498:	6105                	add	sp,sp,32
    8020149a:	8082                	ret
        freeproc(p); 
    8020149c:	8526                	mv	a0,s1
    8020149e:	00000097          	auipc	ra,0x0
    802014a2:	c92080e7          	jalr	-878(ra) # 80201130 <freeproc>
        release(&p->lock); 
    802014a6:	8526                	mv	a0,s1
    802014a8:	fffff097          	auipc	ra,0xfffff
    802014ac:	484080e7          	jalr	1156(ra) # 8020092c <release>
        return -1; 
    802014b0:	557d                	li	a0,-1
    802014b2:	bff9                	j	80201490 <create_process+0x5e>
    if (p->cwd == 0) p->cwd = iget(ROOTDEV, ROOTINO);
    802014b4:	4585                	li	a1,1
    802014b6:	4505                	li	a0,1
    802014b8:	00001097          	auipc	ra,0x1
    802014bc:	2ac080e7          	jalr	684(ra) # 80202764 <iget>
    802014c0:	14a4bc23          	sd	a0,344(s1)
    802014c4:	bf75                	j	80201480 <create_process+0x4e>
    if (p == 0) return -1;
    802014c6:	557d                	li	a0,-1
    802014c8:	b7e1                	j	80201490 <create_process+0x5e>

00000000802014ca <fork>:

int fork(void) {
    802014ca:	7139                	add	sp,sp,-64
    802014cc:	fc06                	sd	ra,56(sp)
    802014ce:	f822                	sd	s0,48(sp)
    802014d0:	f426                	sd	s1,40(sp)
    802014d2:	f04a                	sd	s2,32(sp)
    802014d4:	ec4e                	sd	s3,24(sp)
    802014d6:	e852                	sd	s4,16(sp)
    802014d8:	e456                	sd	s5,8(sp)
    802014da:	0080                	add	s0,sp,64
    int i, pid;
    struct proc *np;
    struct proc *p = myproc();
    802014dc:	00000097          	auipc	ra,0x0
    802014e0:	ecc080e7          	jalr	-308(ra) # 802013a8 <myproc>
    802014e4:	8aaa                	mv	s5,a0

    if ((np = allocproc()) == 0) return -1;
    802014e6:	00000097          	auipc	ra,0x0
    802014ea:	cf6080e7          	jalr	-778(ra) # 802011dc <allocproc>
    802014ee:	c575                	beqz	a0,802015da <fork+0x110>
    802014f0:	8a2a                	mv	s4,a0

    if(uvmcopy(p->pagetable, np->pagetable, 0x40000) < 0) {
    802014f2:	00040637          	lui	a2,0x40
    802014f6:	652c                	ld	a1,72(a0)
    802014f8:	048ab503          	ld	a0,72(s5) # 1048 <_start-0x801fefb8>
    802014fc:	00000097          	auipc	ra,0x0
    80201500:	9aa080e7          	jalr	-1622(ra) # 80200ea6 <uvmcopy>
    80201504:	04054a63          	bltz	a0,80201558 <fork+0x8e>
        freeproc(np);
        release(&np->lock);
        return -1;
    }

    *(np->trapframe) = *(p->trapframe);
    80201508:	040ab683          	ld	a3,64(s5)
    8020150c:	87b6                	mv	a5,a3
    8020150e:	040a3703          	ld	a4,64(s4) # 1040 <_start-0x801fefc0>
    80201512:	12068693          	add	a3,a3,288 # 10001120 <_start-0x701feee0>
    80201516:	0007b803          	ld	a6,0(a5)
    8020151a:	6788                	ld	a0,8(a5)
    8020151c:	6b8c                	ld	a1,16(a5)
    8020151e:	6f90                	ld	a2,24(a5)
    80201520:	01073023          	sd	a6,0(a4) # 1000 <_start-0x801ff000>
    80201524:	e708                	sd	a0,8(a4)
    80201526:	eb0c                	sd	a1,16(a4)
    80201528:	ef10                	sd	a2,24(a4)
    8020152a:	02078793          	add	a5,a5,32
    8020152e:	02070713          	add	a4,a4,32
    80201532:	fed792e3          	bne	a5,a3,80201516 <fork+0x4c>
    np->trapframe->a0 = 0; 
    80201536:	040a3783          	ld	a5,64(s4)
    8020153a:	0607b823          	sd	zero,112(a5)
    np->context.ra = (uint64)fork_ret;
    8020153e:	00000797          	auipc	a5,0x0
    80201542:	4f678793          	add	a5,a5,1270 # 80201a34 <fork_ret>
    80201546:	04fa3823          	sd	a5,80(s4)

    for (i = 0; i < NOFILE; i++)
    8020154a:	0d8a8493          	add	s1,s5,216
    8020154e:	0d8a0913          	add	s2,s4,216
    80201552:	158a8993          	add	s3,s5,344
    80201556:	a00d                	j	80201578 <fork+0xae>
        freeproc(np);
    80201558:	8552                	mv	a0,s4
    8020155a:	00000097          	auipc	ra,0x0
    8020155e:	bd6080e7          	jalr	-1066(ra) # 80201130 <freeproc>
        release(&np->lock);
    80201562:	8552                	mv	a0,s4
    80201564:	fffff097          	auipc	ra,0xfffff
    80201568:	3c8080e7          	jalr	968(ra) # 8020092c <release>
        return -1;
    8020156c:	54fd                	li	s1,-1
    8020156e:	a8a1                	j	802015c6 <fork+0xfc>
    for (i = 0; i < NOFILE; i++)
    80201570:	04a1                	add	s1,s1,8
    80201572:	0921                	add	s2,s2,8
    80201574:	01348b63          	beq	s1,s3,8020158a <fork+0xc0>
        if (p->ofile[i]) np->ofile[i] = filedup(p->ofile[i]);
    80201578:	6088                	ld	a0,0(s1)
    8020157a:	d97d                	beqz	a0,80201570 <fork+0xa6>
    8020157c:	00002097          	auipc	ra,0x2
    80201580:	472080e7          	jalr	1138(ra) # 802039ee <filedup>
    80201584:	00a93023          	sd	a0,0(s2)
    80201588:	b7e5                	j	80201570 <fork+0xa6>
    
    if (p->cwd) np->cwd = idup(p->cwd);
    8020158a:	158ab503          	ld	a0,344(s5)
    8020158e:	c519                	beqz	a0,8020159c <fork+0xd2>
    80201590:	00001097          	auipc	ra,0x1
    80201594:	358080e7          	jalr	856(ra) # 802028e8 <idup>
    80201598:	14aa3c23          	sd	a0,344(s4)
    safestrcpy(np->name, p->name, sizeof(p->name));
    8020159c:	4641                	li	a2,16
    8020159e:	0c8a8593          	add	a1,s5,200
    802015a2:	0c8a0513          	add	a0,s4,200
    802015a6:	fffff097          	auipc	ra,0xfffff
    802015aa:	546080e7          	jalr	1350(ra) # 80200aec <safestrcpy>
    
    pid = np->pid;
    802015ae:	01ca2483          	lw	s1,28(s4)
    np->parent = p;
    802015b2:	035a3023          	sd	s5,32(s4)
    
    np->state = RUNNABLE;
    802015b6:	478d                	li	a5,3
    802015b8:	00fa2c23          	sw	a5,24(s4)
    release(&np->lock);
    802015bc:	8552                	mv	a0,s4
    802015be:	fffff097          	auipc	ra,0xfffff
    802015c2:	36e080e7          	jalr	878(ra) # 8020092c <release>
    return pid;
}
    802015c6:	8526                	mv	a0,s1
    802015c8:	70e2                	ld	ra,56(sp)
    802015ca:	7442                	ld	s0,48(sp)
    802015cc:	74a2                	ld	s1,40(sp)
    802015ce:	7902                	ld	s2,32(sp)
    802015d0:	69e2                	ld	s3,24(sp)
    802015d2:	6a42                	ld	s4,16(sp)
    802015d4:	6aa2                	ld	s5,8(sp)
    802015d6:	6121                	add	sp,sp,64
    802015d8:	8082                	ret
    if ((np = allocproc()) == 0) return -1;
    802015da:	54fd                	li	s1,-1
    802015dc:	b7ed                	j	802015c6 <fork+0xfc>

00000000802015de <scheduler>:

void scheduler(void) {
    802015de:	715d                	add	sp,sp,-80
    802015e0:	e486                	sd	ra,72(sp)
    802015e2:	e0a2                	sd	s0,64(sp)
    802015e4:	fc26                	sd	s1,56(sp)
    802015e6:	f84a                	sd	s2,48(sp)
    802015e8:	f44e                	sd	s3,40(sp)
    802015ea:	f052                	sd	s4,32(sp)
    802015ec:	ec56                	sd	s5,24(sp)
    802015ee:	e85a                	sd	s6,16(sp)
    802015f0:	e45e                	sd	s7,8(sp)
    802015f2:	e062                	sd	s8,0(sp)
    802015f4:	0880                	add	s0,sp,80
    struct cpu *c = mycpu();
    c->proc = 0;
    802015f6:	00028797          	auipc	a5,0x28
    802015fa:	a207b523          	sd	zero,-1494(a5) # 80229020 <cpus>
    
    w_satp(MAKE_SATP(kernel_pagetable)); 
    802015fe:	0000f797          	auipc	a5,0xf
    80201602:	a027b783          	ld	a5,-1534(a5) # 80210000 <kernel_pagetable>
    80201606:	83b1                	srl	a5,a5,0xc
    80201608:	577d                	li	a4,-1
    8020160a:	177e                	sll	a4,a4,0x3f
    8020160c:	8fd9                	or	a5,a5,a4
static inline void w_satp(uint64 x) { asm volatile("csrw satp, %0" : : "r" (x)); }
    8020160e:	18079073          	csrw	satp,a5

    printf("scheduler: starting on cpu 0\n");
    80201612:	00005517          	auipc	a0,0x5
    80201616:	e6650513          	add	a0,a0,-410 # 80206478 <_etext+0x478>
    8020161a:	fffff097          	auipc	ra,0xfffff
    8020161e:	b3a080e7          	jalr	-1222(ra) # 80200154 <printf>
        intr_on();
        for (struct proc *p = proc; p < &proc[NPROC]; p++) {
            acquire(&p->lock);
            if (p->state == RUNNABLE) {
                p->state = RUNNING;
                c->proc = p; 
    80201622:	00028a97          	auipc	s5,0x28
    80201626:	9fea8a93          	add	s5,s5,-1538 # 80229020 <cpus>
                
                w_satp(MAKE_SATP(p->pagetable)); 
    8020162a:	5a7d                	li	s4,-1
    8020162c:	1a7e                	sll	s4,s4,0x3f
                sfence_vma();
                
                swtch(&c->context, &p->context);
    8020162e:	00028c17          	auipc	s8,0x28
    80201632:	9fac0c13          	add	s8,s8,-1542 # 80229028 <cpus+0x8>
                
                w_satp(MAKE_SATP(kernel_pagetable)); 
    80201636:	0000fb97          	auipc	s7,0xf
    8020163a:	9cab8b93          	add	s7,s7,-1590 # 80210000 <kernel_pagetable>
static inline uint64 r_sstatus() { uint64 x; asm volatile("csrr %0, sstatus" : "=r" (x)); return x; }
    8020163e:	100027f3          	csrr	a5,sstatus
    80201642:	0027e793          	or	a5,a5,2
static inline void w_sstatus(uint64 x) { asm volatile("csrw sstatus, %0" : : "r" (x)); }
    80201646:	10079073          	csrw	sstatus,a5
        for (struct proc *p = proc; p < &proc[NPROC]; p++) {
    8020164a:	00028497          	auipc	s1,0x28
    8020164e:	a5648493          	add	s1,s1,-1450 # 802290a0 <proc>
            if (p->state == RUNNABLE) {
    80201652:	498d                	li	s3,3
                p->state = RUNNING;
    80201654:	4b11                	li	s6,4
        for (struct proc *p = proc; p < &proc[NPROC]; p++) {
    80201656:	0002d917          	auipc	s2,0x2d
    8020165a:	24a90913          	add	s2,s2,586 # 8022e8a0 <bcache>
    8020165e:	a811                	j	80201672 <scheduler+0x94>
                sfence_vma();
                c->proc = 0; 
            }
            release(&p->lock);
    80201660:	8526                	mv	a0,s1
    80201662:	fffff097          	auipc	ra,0xfffff
    80201666:	2ca080e7          	jalr	714(ra) # 8020092c <release>
        for (struct proc *p = proc; p < &proc[NPROC]; p++) {
    8020166a:	16048493          	add	s1,s1,352
    8020166e:	fd2488e3          	beq	s1,s2,8020163e <scheduler+0x60>
            acquire(&p->lock);
    80201672:	8526                	mv	a0,s1
    80201674:	fffff097          	auipc	ra,0xfffff
    80201678:	1c6080e7          	jalr	454(ra) # 8020083a <acquire>
            if (p->state == RUNNABLE) {
    8020167c:	4c9c                	lw	a5,24(s1)
    8020167e:	ff3791e3          	bne	a5,s3,80201660 <scheduler+0x82>
                p->state = RUNNING;
    80201682:	0164ac23          	sw	s6,24(s1)
                c->proc = p; 
    80201686:	009ab023          	sd	s1,0(s5)
                w_satp(MAKE_SATP(p->pagetable)); 
    8020168a:	64bc                	ld	a5,72(s1)
    8020168c:	83b1                	srl	a5,a5,0xc
    8020168e:	0147e7b3          	or	a5,a5,s4
static inline void w_satp(uint64 x) { asm volatile("csrw satp, %0" : : "r" (x)); }
    80201692:	18079073          	csrw	satp,a5
static inline void sfence_vma() { asm volatile("sfence.vma zero, zero"); }
    80201696:	12000073          	sfence.vma
                swtch(&c->context, &p->context);
    8020169a:	05048593          	add	a1,s1,80
    8020169e:	8562                	mv	a0,s8
    802016a0:	00003097          	auipc	ra,0x3
    802016a4:	2ce080e7          	jalr	718(ra) # 8020496e <swtch>
                w_satp(MAKE_SATP(kernel_pagetable)); 
    802016a8:	000bb783          	ld	a5,0(s7)
    802016ac:	83b1                	srl	a5,a5,0xc
    802016ae:	0147e7b3          	or	a5,a5,s4
static inline void w_satp(uint64 x) { asm volatile("csrw satp, %0" : : "r" (x)); }
    802016b2:	18079073          	csrw	satp,a5
static inline void sfence_vma() { asm volatile("sfence.vma zero, zero"); }
    802016b6:	12000073          	sfence.vma
                c->proc = 0; 
    802016ba:	000ab023          	sd	zero,0(s5)
    802016be:	b74d                	j	80201660 <scheduler+0x82>

00000000802016c0 <sched>:
        }
    }
}

void sched(void) {
    802016c0:	1101                	add	sp,sp,-32
    802016c2:	ec06                	sd	ra,24(sp)
    802016c4:	e822                	sd	s0,16(sp)
    802016c6:	e426                	sd	s1,8(sp)
    802016c8:	e04a                	sd	s2,0(sp)
    802016ca:	1000                	add	s0,sp,32
    int intena = mycpu()->intena;
    802016cc:	00028497          	auipc	s1,0x28
    802016d0:	95448493          	add	s1,s1,-1708 # 80229020 <cpus>
    802016d4:	07c4a903          	lw	s2,124(s1)
    swtch(&myproc()->context, &mycpu()->context);
    802016d8:	00000097          	auipc	ra,0x0
    802016dc:	cd0080e7          	jalr	-816(ra) # 802013a8 <myproc>
    802016e0:	00028597          	auipc	a1,0x28
    802016e4:	94858593          	add	a1,a1,-1720 # 80229028 <cpus+0x8>
    802016e8:	05050513          	add	a0,a0,80
    802016ec:	00003097          	auipc	ra,0x3
    802016f0:	282080e7          	jalr	642(ra) # 8020496e <swtch>
    mycpu()->intena = intena;
    802016f4:	0724ae23          	sw	s2,124(s1)
}
    802016f8:	60e2                	ld	ra,24(sp)
    802016fa:	6442                	ld	s0,16(sp)
    802016fc:	64a2                	ld	s1,8(sp)
    802016fe:	6902                	ld	s2,0(sp)
    80201700:	6105                	add	sp,sp,32
    80201702:	8082                	ret

0000000080201704 <yield>:

void yield(void) {
    80201704:	1101                	add	sp,sp,-32
    80201706:	ec06                	sd	ra,24(sp)
    80201708:	e822                	sd	s0,16(sp)
    8020170a:	e426                	sd	s1,8(sp)
    8020170c:	1000                	add	s0,sp,32
    struct proc *p = myproc();
    8020170e:	00000097          	auipc	ra,0x0
    80201712:	c9a080e7          	jalr	-870(ra) # 802013a8 <myproc>
    80201716:	84aa                	mv	s1,a0
    acquire(&p->lock);
    80201718:	fffff097          	auipc	ra,0xfffff
    8020171c:	122080e7          	jalr	290(ra) # 8020083a <acquire>
    p->state = RUNNABLE;
    80201720:	478d                	li	a5,3
    80201722:	cc9c                	sw	a5,24(s1)
    sched();
    80201724:	00000097          	auipc	ra,0x0
    80201728:	f9c080e7          	jalr	-100(ra) # 802016c0 <sched>
    release(&p->lock);
    8020172c:	8526                	mv	a0,s1
    8020172e:	fffff097          	auipc	ra,0xfffff
    80201732:	1fe080e7          	jalr	510(ra) # 8020092c <release>
}
    80201736:	60e2                	ld	ra,24(sp)
    80201738:	6442                	ld	s0,16(sp)
    8020173a:	64a2                	ld	s1,8(sp)
    8020173c:	6105                	add	sp,sp,32
    8020173e:	8082                	ret

0000000080201740 <sleep>:
    }
}

void wait_process(int *status) { wait(status); }

void sleep(void *chan, struct spinlock *lk) {
    80201740:	7179                	add	sp,sp,-48
    80201742:	f406                	sd	ra,40(sp)
    80201744:	f022                	sd	s0,32(sp)
    80201746:	ec26                	sd	s1,24(sp)
    80201748:	e84a                	sd	s2,16(sp)
    8020174a:	e44e                	sd	s3,8(sp)
    8020174c:	1800                	add	s0,sp,48
    8020174e:	89aa                	mv	s3,a0
    80201750:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80201752:	00000097          	auipc	ra,0x0
    80201756:	c56080e7          	jalr	-938(ra) # 802013a8 <myproc>
    8020175a:	84aa                	mv	s1,a0
    if (lk != &p->lock) { acquire(&p->lock); release(lk); }
    8020175c:	05250663          	beq	a0,s2,802017a8 <sleep+0x68>
    80201760:	fffff097          	auipc	ra,0xfffff
    80201764:	0da080e7          	jalr	218(ra) # 8020083a <acquire>
    80201768:	854a                	mv	a0,s2
    8020176a:	fffff097          	auipc	ra,0xfffff
    8020176e:	1c2080e7          	jalr	450(ra) # 8020092c <release>
    p->chan = chan;
    80201772:	0334b423          	sd	s3,40(s1)
    p->state = SLEEPING;
    80201776:	4789                	li	a5,2
    80201778:	cc9c                	sw	a5,24(s1)
    sched();
    8020177a:	00000097          	auipc	ra,0x0
    8020177e:	f46080e7          	jalr	-186(ra) # 802016c0 <sched>
    p->chan = 0;
    80201782:	0204b423          	sd	zero,40(s1)
    if (lk != &p->lock) { release(&p->lock); acquire(lk); }
    80201786:	8526                	mv	a0,s1
    80201788:	fffff097          	auipc	ra,0xfffff
    8020178c:	1a4080e7          	jalr	420(ra) # 8020092c <release>
    80201790:	854a                	mv	a0,s2
    80201792:	fffff097          	auipc	ra,0xfffff
    80201796:	0a8080e7          	jalr	168(ra) # 8020083a <acquire>
}
    8020179a:	70a2                	ld	ra,40(sp)
    8020179c:	7402                	ld	s0,32(sp)
    8020179e:	64e2                	ld	s1,24(sp)
    802017a0:	6942                	ld	s2,16(sp)
    802017a2:	69a2                	ld	s3,8(sp)
    802017a4:	6145                	add	sp,sp,48
    802017a6:	8082                	ret
    p->chan = chan;
    802017a8:	03353423          	sd	s3,40(a0)
    p->state = SLEEPING;
    802017ac:	4789                	li	a5,2
    802017ae:	cd1c                	sw	a5,24(a0)
    sched();
    802017b0:	00000097          	auipc	ra,0x0
    802017b4:	f10080e7          	jalr	-240(ra) # 802016c0 <sched>
    p->chan = 0;
    802017b8:	0204b423          	sd	zero,40(s1)
    if (lk != &p->lock) { release(&p->lock); acquire(lk); }
    802017bc:	bff9                	j	8020179a <sleep+0x5a>

00000000802017be <wait>:
int wait(int *status) {
    802017be:	715d                	add	sp,sp,-80
    802017c0:	e486                	sd	ra,72(sp)
    802017c2:	e0a2                	sd	s0,64(sp)
    802017c4:	fc26                	sd	s1,56(sp)
    802017c6:	f84a                	sd	s2,48(sp)
    802017c8:	f44e                	sd	s3,40(sp)
    802017ca:	f052                	sd	s4,32(sp)
    802017cc:	ec56                	sd	s5,24(sp)
    802017ce:	e85a                	sd	s6,16(sp)
    802017d0:	e45e                	sd	s7,8(sp)
    802017d2:	0880                	add	s0,sp,80
    802017d4:	8b2a                	mv	s6,a0
    struct proc *p = myproc();
    802017d6:	00000097          	auipc	ra,0x0
    802017da:	bd2080e7          	jalr	-1070(ra) # 802013a8 <myproc>
    802017de:	892a                	mv	s2,a0
    acquire(&p->lock);
    802017e0:	fffff097          	auipc	ra,0xfffff
    802017e4:	05a080e7          	jalr	90(ra) # 8020083a <acquire>
        havekids = 0;
    802017e8:	4b81                	li	s7,0
                if (cp->state == ZOMBIE) {
    802017ea:	4a15                	li	s4,5
                havekids = 1;
    802017ec:	4a85                	li	s5,1
        for (struct proc *cp = proc; cp < &proc[NPROC]; cp++) {
    802017ee:	0002d997          	auipc	s3,0x2d
    802017f2:	0b298993          	add	s3,s3,178 # 8022e8a0 <bcache>
    802017f6:	a059                	j	8020187c <wait+0xbe>
                    pid = cp->pid;
    802017f8:	01c4a983          	lw	s3,28(s1)
                    if (status) *status = cp->xstate;
    802017fc:	000b0563          	beqz	s6,80201806 <wait+0x48>
    80201800:	58dc                	lw	a5,52(s1)
    80201802:	00fb2023          	sw	a5,0(s6) # 1000 <_start-0x801ff000>
                    freeproc(cp);
    80201806:	8526                	mv	a0,s1
    80201808:	00000097          	auipc	ra,0x0
    8020180c:	928080e7          	jalr	-1752(ra) # 80201130 <freeproc>
                    release(&cp->lock);
    80201810:	8526                	mv	a0,s1
    80201812:	fffff097          	auipc	ra,0xfffff
    80201816:	11a080e7          	jalr	282(ra) # 8020092c <release>
                    release(&p->lock);
    8020181a:	854a                	mv	a0,s2
    8020181c:	fffff097          	auipc	ra,0xfffff
    80201820:	110080e7          	jalr	272(ra) # 8020092c <release>
}
    80201824:	854e                	mv	a0,s3
    80201826:	60a6                	ld	ra,72(sp)
    80201828:	6406                	ld	s0,64(sp)
    8020182a:	74e2                	ld	s1,56(sp)
    8020182c:	7942                	ld	s2,48(sp)
    8020182e:	79a2                	ld	s3,40(sp)
    80201830:	7a02                	ld	s4,32(sp)
    80201832:	6ae2                	ld	s5,24(sp)
    80201834:	6b42                	ld	s6,16(sp)
    80201836:	6ba2                	ld	s7,8(sp)
    80201838:	6161                	add	sp,sp,80
    8020183a:	8082                	ret
        for (struct proc *cp = proc; cp < &proc[NPROC]; cp++) {
    8020183c:	16048493          	add	s1,s1,352
    80201840:	03348463          	beq	s1,s3,80201868 <wait+0xaa>
            if (cp->parent == p) {
    80201844:	709c                	ld	a5,32(s1)
    80201846:	ff279be3          	bne	a5,s2,8020183c <wait+0x7e>
                acquire(&cp->lock);
    8020184a:	8526                	mv	a0,s1
    8020184c:	fffff097          	auipc	ra,0xfffff
    80201850:	fee080e7          	jalr	-18(ra) # 8020083a <acquire>
                if (cp->state == ZOMBIE) {
    80201854:	4c9c                	lw	a5,24(s1)
    80201856:	fb4781e3          	beq	a5,s4,802017f8 <wait+0x3a>
                release(&cp->lock);
    8020185a:	8526                	mv	a0,s1
    8020185c:	fffff097          	auipc	ra,0xfffff
    80201860:	0d0080e7          	jalr	208(ra) # 8020092c <release>
                havekids = 1;
    80201864:	8756                	mv	a4,s5
    80201866:	bfd9                	j	8020183c <wait+0x7e>
        if (!havekids || p->killed) {
    80201868:	c305                	beqz	a4,80201888 <wait+0xca>
    8020186a:	03092783          	lw	a5,48(s2)
    8020186e:	ef89                	bnez	a5,80201888 <wait+0xca>
        sleep(p, &p->lock);
    80201870:	85ca                	mv	a1,s2
    80201872:	854a                	mv	a0,s2
    80201874:	00000097          	auipc	ra,0x0
    80201878:	ecc080e7          	jalr	-308(ra) # 80201740 <sleep>
        for (struct proc *cp = proc; cp < &proc[NPROC]; cp++) {
    8020187c:	00028497          	auipc	s1,0x28
    80201880:	82448493          	add	s1,s1,-2012 # 802290a0 <proc>
        havekids = 0;
    80201884:	875e                	mv	a4,s7
    80201886:	bf7d                	j	80201844 <wait+0x86>
            release(&p->lock);
    80201888:	854a                	mv	a0,s2
    8020188a:	fffff097          	auipc	ra,0xfffff
    8020188e:	0a2080e7          	jalr	162(ra) # 8020092c <release>
            return -1;
    80201892:	59fd                	li	s3,-1
    80201894:	bf41                	j	80201824 <wait+0x66>

0000000080201896 <wait_process>:
void wait_process(int *status) { wait(status); }
    80201896:	1141                	add	sp,sp,-16
    80201898:	e406                	sd	ra,8(sp)
    8020189a:	e022                	sd	s0,0(sp)
    8020189c:	0800                	add	s0,sp,16
    8020189e:	00000097          	auipc	ra,0x0
    802018a2:	f20080e7          	jalr	-224(ra) # 802017be <wait>
    802018a6:	60a2                	ld	ra,8(sp)
    802018a8:	6402                	ld	s0,0(sp)
    802018aa:	0141                	add	sp,sp,16
    802018ac:	8082                	ret

00000000802018ae <wakeup>:

void wakeup(void *chan) {
    802018ae:	7139                	add	sp,sp,-64
    802018b0:	fc06                	sd	ra,56(sp)
    802018b2:	f822                	sd	s0,48(sp)
    802018b4:	f426                	sd	s1,40(sp)
    802018b6:	f04a                	sd	s2,32(sp)
    802018b8:	ec4e                	sd	s3,24(sp)
    802018ba:	e852                	sd	s4,16(sp)
    802018bc:	e456                	sd	s5,8(sp)
    802018be:	0080                	add	s0,sp,64
    802018c0:	8a2a                	mv	s4,a0
    for (struct proc *p = proc; p < &proc[NPROC]; p++) {
    802018c2:	00027497          	auipc	s1,0x27
    802018c6:	7de48493          	add	s1,s1,2014 # 802290a0 <proc>
        if (p != myproc()) {
            acquire(&p->lock);
            if (p->state == SLEEPING && p->chan == chan) {
    802018ca:	4989                	li	s3,2
                p->state = RUNNABLE;
    802018cc:	4a8d                	li	s5,3
    for (struct proc *p = proc; p < &proc[NPROC]; p++) {
    802018ce:	0002d917          	auipc	s2,0x2d
    802018d2:	fd290913          	add	s2,s2,-46 # 8022e8a0 <bcache>
    802018d6:	a811                	j	802018ea <wakeup+0x3c>
            }
            release(&p->lock);
    802018d8:	8526                	mv	a0,s1
    802018da:	fffff097          	auipc	ra,0xfffff
    802018de:	052080e7          	jalr	82(ra) # 8020092c <release>
    for (struct proc *p = proc; p < &proc[NPROC]; p++) {
    802018e2:	16048493          	add	s1,s1,352
    802018e6:	03248663          	beq	s1,s2,80201912 <wakeup+0x64>
        if (p != myproc()) {
    802018ea:	00000097          	auipc	ra,0x0
    802018ee:	abe080e7          	jalr	-1346(ra) # 802013a8 <myproc>
    802018f2:	fea488e3          	beq	s1,a0,802018e2 <wakeup+0x34>
            acquire(&p->lock);
    802018f6:	8526                	mv	a0,s1
    802018f8:	fffff097          	auipc	ra,0xfffff
    802018fc:	f42080e7          	jalr	-190(ra) # 8020083a <acquire>
            if (p->state == SLEEPING && p->chan == chan) {
    80201900:	4c9c                	lw	a5,24(s1)
    80201902:	fd379be3          	bne	a5,s3,802018d8 <wakeup+0x2a>
    80201906:	749c                	ld	a5,40(s1)
    80201908:	fd4798e3          	bne	a5,s4,802018d8 <wakeup+0x2a>
                p->state = RUNNABLE;
    8020190c:	0154ac23          	sw	s5,24(s1)
    80201910:	b7e1                	j	802018d8 <wakeup+0x2a>
        }
    }
}
    80201912:	70e2                	ld	ra,56(sp)
    80201914:	7442                	ld	s0,48(sp)
    80201916:	74a2                	ld	s1,40(sp)
    80201918:	7902                	ld	s2,32(sp)
    8020191a:	69e2                	ld	s3,24(sp)
    8020191c:	6a42                	ld	s4,16(sp)
    8020191e:	6aa2                	ld	s5,8(sp)
    80201920:	6121                	add	sp,sp,64
    80201922:	8082                	ret

0000000080201924 <exit>:
void exit(int status) {
    80201924:	7179                	add	sp,sp,-48
    80201926:	f406                	sd	ra,40(sp)
    80201928:	f022                	sd	s0,32(sp)
    8020192a:	ec26                	sd	s1,24(sp)
    8020192c:	e84a                	sd	s2,16(sp)
    8020192e:	e44e                	sd	s3,8(sp)
    80201930:	e052                	sd	s4,0(sp)
    80201932:	1800                	add	s0,sp,48
    80201934:	8a2a                	mv	s4,a0
    struct proc *p = myproc();
    80201936:	00000097          	auipc	ra,0x0
    8020193a:	a72080e7          	jalr	-1422(ra) # 802013a8 <myproc>
    8020193e:	89aa                	mv	s3,a0
    for (int fd = 0; fd < NOFILE; fd++) {
    80201940:	0d850493          	add	s1,a0,216
    80201944:	15850913          	add	s2,a0,344
    80201948:	a021                	j	80201950 <exit+0x2c>
    8020194a:	04a1                	add	s1,s1,8
    8020194c:	01248b63          	beq	s1,s2,80201962 <exit+0x3e>
        if (p->ofile[fd]) {
    80201950:	6088                	ld	a0,0(s1)
    80201952:	dd65                	beqz	a0,8020194a <exit+0x26>
            fileclose(p->ofile[fd]);
    80201954:	00002097          	auipc	ra,0x2
    80201958:	0f0080e7          	jalr	240(ra) # 80203a44 <fileclose>
            p->ofile[fd] = 0;
    8020195c:	0004b023          	sd	zero,0(s1)
    80201960:	b7ed                	j	8020194a <exit+0x26>
    if (p->cwd) {
    80201962:	1589b503          	ld	a0,344(s3)
    80201966:	c519                	beqz	a0,80201974 <exit+0x50>
        iput(p->cwd);
    80201968:	00001097          	auipc	ra,0x1
    8020196c:	1fe080e7          	jalr	510(ra) # 80202b66 <iput>
        p->cwd = 0;
    80201970:	1409bc23          	sd	zero,344(s3)
    acquire(&p->lock);
    80201974:	854e                	mv	a0,s3
    80201976:	fffff097          	auipc	ra,0xfffff
    8020197a:	ec4080e7          	jalr	-316(ra) # 8020083a <acquire>
    p->state = ZOMBIE;
    8020197e:	4795                	li	a5,5
    80201980:	00f9ac23          	sw	a5,24(s3)
    p->xstate = status;
    80201984:	0349aa23          	sw	s4,52(s3)
    if (p->parent) wakeup(p->parent);
    80201988:	0209b503          	ld	a0,32(s3)
    8020198c:	c509                	beqz	a0,80201996 <exit+0x72>
    8020198e:	00000097          	auipc	ra,0x0
    80201992:	f20080e7          	jalr	-224(ra) # 802018ae <wakeup>
    sched();
    80201996:	00000097          	auipc	ra,0x0
    8020199a:	d2a080e7          	jalr	-726(ra) # 802016c0 <sched>
    while(1);
    8020199e:	a001                	j	8020199e <exit+0x7a>

00000000802019a0 <proc_entry>:
void proc_entry(void) {
    802019a0:	1101                	add	sp,sp,-32
    802019a2:	ec06                	sd	ra,24(sp)
    802019a4:	e822                	sd	s0,16(sp)
    802019a6:	e426                	sd	s1,8(sp)
    802019a8:	1000                	add	s0,sp,32
    struct proc *p = myproc();
    802019aa:	00000097          	auipc	ra,0x0
    802019ae:	9fe080e7          	jalr	-1538(ra) # 802013a8 <myproc>
    if (p == 0) {
    802019b2:	cd11                	beqz	a0,802019ce <proc_entry+0x2e>
    802019b4:	84aa                	mv	s1,a0
    release(&p->lock);
    802019b6:	fffff097          	auipc	ra,0xfffff
    802019ba:	f76080e7          	jalr	-138(ra) # 8020092c <release>
    if (p->entry) p->entry();
    802019be:	60fc                	ld	a5,192(s1)
    802019c0:	c391                	beqz	a5,802019c4 <proc_entry+0x24>
    802019c2:	9782                	jalr	a5
    exit(0);
    802019c4:	4501                	li	a0,0
    802019c6:	00000097          	auipc	ra,0x0
    802019ca:	f5e080e7          	jalr	-162(ra) # 80201924 <exit>
        printf("FATAL: proc_entry running with no process context!\n");
    802019ce:	00005517          	auipc	a0,0x5
    802019d2:	aca50513          	add	a0,a0,-1334 # 80206498 <_etext+0x498>
    802019d6:	ffffe097          	auipc	ra,0xffffe
    802019da:	77e080e7          	jalr	1918(ra) # 80200154 <printf>
        while(1);
    802019de:	a001                	j	802019de <proc_entry+0x3e>

00000000802019e0 <trap_init>:
    register uint64 a6 asm("a6") = 0;
    register uint64 a0 asm("a0") = stime;
    asm volatile("ecall" : "+r"(a0) : "r"(a6), "r"(a7) : "memory");
}

void trap_init(void) {
    802019e0:	1141                	add	sp,sp,-16
    802019e2:	e422                	sd	s0,8(sp)
    802019e4:	0800                	add	s0,sp,16
static inline void w_stvec(uint64 x) { asm volatile("csrw stvec, %0" : : "r" (x)); }
    802019e6:	00003797          	auipc	a5,0x3
    802019ea:	e6a78793          	add	a5,a5,-406 # 80204850 <kernelvec>
    802019ee:	10579073          	csrw	stvec,a5
    w_stvec((uint64)kernelvec);
}
    802019f2:	6422                	ld	s0,8(sp)
    802019f4:	0141                	add	sp,sp,16
    802019f6:	8082                	ret

00000000802019f8 <clock_init>:

void clock_init(void) {
    802019f8:	1141                	add	sp,sp,-16
    802019fa:	e422                	sd	s0,8(sp)
    802019fc:	0800                	add	s0,sp,16
static inline uint64 r_time() { uint64 x; asm volatile("csrr %0, time" : "=r" (x)); return x; }
    802019fe:	c0102573          	rdtime	a0
    register uint64 a7 asm("a7") = 0;
    80201a02:	4881                	li	a7,0
    register uint64 a6 asm("a6") = 0;
    80201a04:	4801                	li	a6,0
    register uint64 a0 asm("a0") = stime;
    80201a06:	67e1                	lui	a5,0x18
    80201a08:	6a078793          	add	a5,a5,1696 # 186a0 <_start-0x801e7960>
    80201a0c:	953e                	add	a0,a0,a5
    asm volatile("ecall" : "+r"(a0) : "r"(a6), "r"(a7) : "memory");
    80201a0e:	00000073          	ecall
static inline uint64 r_sie() { uint64 x; asm volatile("csrr %0, sie" : "=r" (x)); return x; }
    80201a12:	104027f3          	csrr	a5,sie
    uint64 next_timer = r_time() + 100000;
    sbi_set_timer(next_timer);
    w_sie(r_sie() | SIE_STIE);
    80201a16:	0207e793          	or	a5,a5,32
static inline void w_sie(uint64 x) { asm volatile("csrw sie, %0" : : "r" (x)); }
    80201a1a:	10479073          	csrw	sie,a5
}
    80201a1e:	6422                	ld	s0,8(sp)
    80201a20:	0141                	add	sp,sp,16
    80201a22:	8082                	ret

0000000080201a24 <get_time>:

uint64 get_time(void) { return r_time(); }
    80201a24:	1141                	add	sp,sp,-16
    80201a26:	e422                	sd	s0,8(sp)
    80201a28:	0800                	add	s0,sp,16
static inline uint64 r_time() { uint64 x; asm volatile("csrr %0, time" : "=r" (x)); return x; }
    80201a2a:	c0102573          	rdtime	a0
    80201a2e:	6422                	ld	s0,8(sp)
    80201a30:	0141                	add	sp,sp,16
    80201a32:	8082                	ret

0000000080201a34 <fork_ret>:

void fork_ret() {
    80201a34:	1101                	add	sp,sp,-32
    80201a36:	ec06                	sd	ra,24(sp)
    80201a38:	e822                	sd	s0,16(sp)
    80201a3a:	e426                	sd	s1,8(sp)
    80201a3c:	1000                	add	s0,sp,32
    struct proc *p = myproc();
    80201a3e:	00000097          	auipc	ra,0x0
    80201a42:	96a080e7          	jalr	-1686(ra) # 802013a8 <myproc>
    80201a46:	84aa                	mv	s1,a0
    release(&p->lock); 
    80201a48:	fffff097          	auipc	ra,0xfffff
    80201a4c:	ee4080e7          	jalr	-284(ra) # 8020092c <release>
    restore_trapframe(p->trapframe);
    80201a50:	60a8                	ld	a0,64(s1)
    80201a52:	00003097          	auipc	ra,0x3
    80201a56:	e86080e7          	jalr	-378(ra) # 802048d8 <restore_trapframe>
}
    80201a5a:	60e2                	ld	ra,24(sp)
    80201a5c:	6442                	ld	s0,16(sp)
    80201a5e:	64a2                	ld	s1,8(sp)
    80201a60:	6105                	add	sp,sp,32
    80201a62:	8082                	ret

0000000080201a64 <kerneltrap>:

void kerneltrap(uint64 sp_val) {
    80201a64:	7139                	add	sp,sp,-64
    80201a66:	fc06                	sd	ra,56(sp)
    80201a68:	f822                	sd	s0,48(sp)
    80201a6a:	f426                	sd	s1,40(sp)
    80201a6c:	f04a                	sd	s2,32(sp)
    80201a6e:	ec4e                	sd	s3,24(sp)
    80201a70:	e852                	sd	s4,16(sp)
    80201a72:	e456                	sd	s5,8(sp)
    80201a74:	0080                	add	s0,sp,64
static inline uint64 r_scause() { uint64 x; asm volatile("csrr %0, scause" : "=r" (x)); return x; }
    80201a76:	14202973          	csrr	s2,scause
static inline uint64 r_sepc() { uint64 x; asm volatile("csrr %0, sepc" : "=r" (x)); return x; }
    80201a7a:	141029f3          	csrr	s3,sepc
static inline uint64 r_sstatus() { uint64 x; asm volatile("csrr %0, sstatus" : "=r" (x)); return x; }
    80201a7e:	10002af3          	csrr	s5,sstatus
static inline uint64 r_stval() { uint64 x; asm volatile("csrr %0, stval" : "=r" (x) ); return x; }
    80201a82:	14302a73          	csrr	s4,stval
    uint64 scause = r_scause();
    uint64 sepc = r_sepc();
    uint64 sstatus = r_sstatus();
    uint64 stval = r_stval();

    struct proc *p = myproc();
    80201a86:	00000097          	auipc	ra,0x0
    80201a8a:	922080e7          	jalr	-1758(ra) # 802013a8 <myproc>
    80201a8e:	84aa                	mv	s1,a0
    
    // 防御性检查：确保 p 和 p->trapframe 有效
    if (p != 0 && p->trapframe != 0) {
    80201a90:	10050063          	beqz	a0,80201b90 <kerneltrap+0x12c>
    80201a94:	613c                	ld	a5,64(a0)
    80201a96:	12078763          	beqz	a5,80201bc4 <kerneltrap+0x160>
        p->trapframe->epc = sepc;
    80201a9a:	0137bc23          	sd	s3,24(a5)
    }

    if (scause == 8) { // System Call
    80201a9e:	47a1                	li	a5,8
    80201aa0:	02f90863          	beq	s2,a5,80201ad0 <kerneltrap+0x6c>
        if(p && p->trapframe) p->trapframe->epc += 4;
        intr_on();
        syscall();
        intr_off();
    } 
    else if (scause == 15) { // Store/AMO Page Fault (COW)
    80201aa4:	47bd                	li	a5,15
    80201aa6:	06f90463          	beq	s2,a5,80201b0e <kerneltrap+0xaa>
            printf("kerneltrap: Fatal Page Fault at %p without process context\n", stval);
            printf("scause=%p sepc=%p\n", scause, sepc);
            while(1);
        }
    }
    else if ((scause & 0x8000000000000000L) && (scause & 0xff) == 5) { // Timer
    80201aaa:	00095763          	bgez	s2,80201ab8 <kerneltrap+0x54>
    80201aae:	0ff97793          	zext.b	a5,s2
    80201ab2:	4715                	li	a4,5
    80201ab4:	08e78563          	beq	a5,a4,80201b3e <kerneltrap+0xda>
        uint64 next_timer = r_time() + 100000;
        sbi_set_timer(next_timer);
        if (p != 0 && p->state == RUNNING) yield();
    }
    else {
        printf("kerneltrap: unhandled exception scause %p, sepc %p, stval %p\n", scause, sepc, stval);
    80201ab8:	86d2                	mv	a3,s4
    80201aba:	864e                	mv	a2,s3
    80201abc:	85ca                	mv	a1,s2
    80201abe:	00005517          	auipc	a0,0x5
    80201ac2:	aa250513          	add	a0,a0,-1374 # 80206560 <_etext+0x560>
    80201ac6:	ffffe097          	auipc	ra,0xffffe
    80201aca:	68e080e7          	jalr	1678(ra) # 80200154 <printf>
        // 如果是 p->trapframe 为空导致的故障，这里会打印出来
        while(1);
    80201ace:	a001                	j	80201ace <kerneltrap+0x6a>
        if(p && p->trapframe) p->trapframe->epc += 4;
    80201ad0:	613c                	ld	a5,64(a0)
    80201ad2:	c781                	beqz	a5,80201ada <kerneltrap+0x76>
    80201ad4:	6f98                	ld	a4,24(a5)
    80201ad6:	0711                	add	a4,a4,4
    80201ad8:	ef98                	sd	a4,24(a5)
static inline uint64 r_sstatus() { uint64 x; asm volatile("csrr %0, sstatus" : "=r" (x)); return x; }
    80201ada:	100027f3          	csrr	a5,sstatus
    80201ade:	0027e793          	or	a5,a5,2
static inline void w_sstatus(uint64 x) { asm volatile("csrw sstatus, %0" : : "r" (x)); }
    80201ae2:	10079073          	csrw	sstatus,a5
        syscall();
    80201ae6:	00000097          	auipc	ra,0x0
    80201aea:	25a080e7          	jalr	602(ra) # 80201d40 <syscall>
static inline uint64 r_sstatus() { uint64 x; asm volatile("csrr %0, sstatus" : "=r" (x)); return x; }
    80201aee:	100027f3          	csrr	a5,sstatus
    w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80201af2:	9bf5                	and	a5,a5,-3
static inline void w_sstatus(uint64 x) { asm volatile("csrw sstatus, %0" : : "r" (x)); }
    80201af4:	10079073          	csrw	sstatus,a5
    }

    if (p && p->killed) {
    80201af8:	c4bd                	beqz	s1,80201b66 <kerneltrap+0x102>
    80201afa:	589c                	lw	a5,48(s1)
    80201afc:	e3d1                	bnez	a5,80201b80 <kerneltrap+0x11c>
    80201afe:	100a9073          	csrw	sstatus,s5
        exit(-1);
    }
    
    w_sstatus(sstatus);
    if (p && p->trapframe) w_sepc(p->trapframe->epc);
    80201b02:	60bc                	ld	a5,64(s1)
    80201b04:	c3bd                	beqz	a5,80201b6a <kerneltrap+0x106>
static inline void w_sepc(uint64 x) { asm volatile("csrw sepc, %0" : : "r" (x)); }
    80201b06:	6f9c                	ld	a5,24(a5)
    80201b08:	14179073          	csrw	sepc,a5
    80201b0c:	a08d                	j	80201b6e <kerneltrap+0x10a>
        if (p != 0 && p->pagetable != 0) {
    80201b0e:	64a8                	ld	a0,72(s1)
    80201b10:	c551                	beqz	a0,80201b9c <kerneltrap+0x138>
            if (cow_alloc(p->pagetable, stval) == 0) {
    80201b12:	85d2                	mv	a1,s4
    80201b14:	fffff097          	auipc	ra,0xfffff
    80201b18:	2e6080e7          	jalr	742(ra) # 80200dfa <cow_alloc>
    80201b1c:	dd79                	beqz	a0,80201afa <kerneltrap+0x96>
                printf("kerneltrap: cow_alloc failed for va %p, killing pid %d\n", stval, p->pid);
    80201b1e:	4cd0                	lw	a2,28(s1)
    80201b20:	85d2                	mv	a1,s4
    80201b22:	00005517          	auipc	a0,0x5
    80201b26:	9ae50513          	add	a0,a0,-1618 # 802064d0 <_etext+0x4d0>
    80201b2a:	ffffe097          	auipc	ra,0xffffe
    80201b2e:	62a080e7          	jalr	1578(ra) # 80200154 <printf>
                if(p) exit(-1);
    80201b32:	557d                	li	a0,-1
    80201b34:	00000097          	auipc	ra,0x0
    80201b38:	df0080e7          	jalr	-528(ra) # 80201924 <exit>
    if (p && p->killed) {
    80201b3c:	bf7d                	j	80201afa <kerneltrap+0x96>
static inline uint64 r_time() { uint64 x; asm volatile("csrr %0, time" : "=r" (x)); return x; }
    80201b3e:	c0102573          	rdtime	a0
    register uint64 a7 asm("a7") = 0;
    80201b42:	4881                	li	a7,0
    register uint64 a6 asm("a6") = 0;
    80201b44:	4801                	li	a6,0
    register uint64 a0 asm("a0") = stime;
    80201b46:	67e1                	lui	a5,0x18
    80201b48:	6a078793          	add	a5,a5,1696 # 186a0 <_start-0x801e7960>
    80201b4c:	953e                	add	a0,a0,a5
    asm volatile("ecall" : "+r"(a0) : "r"(a6), "r"(a7) : "memory");
    80201b4e:	00000073          	ecall
        if (p != 0 && p->state == RUNNING) yield();
    80201b52:	c891                	beqz	s1,80201b66 <kerneltrap+0x102>
    80201b54:	4c98                	lw	a4,24(s1)
    80201b56:	4791                	li	a5,4
    80201b58:	faf711e3          	bne	a4,a5,80201afa <kerneltrap+0x96>
    80201b5c:	00000097          	auipc	ra,0x0
    80201b60:	ba8080e7          	jalr	-1112(ra) # 80201704 <yield>
    if (p && p->killed) {
    80201b64:	bf59                	j	80201afa <kerneltrap+0x96>
static inline void w_sstatus(uint64 x) { asm volatile("csrw sstatus, %0" : : "r" (x)); }
    80201b66:	100a9073          	csrw	sstatus,s5
static inline void w_sepc(uint64 x) { asm volatile("csrw sepc, %0" : : "r" (x)); }
    80201b6a:	14199073          	csrw	sepc,s3
    else w_sepc(sepc); // 回退到使用局部 sepc，如果 p 无效
}
    80201b6e:	70e2                	ld	ra,56(sp)
    80201b70:	7442                	ld	s0,48(sp)
    80201b72:	74a2                	ld	s1,40(sp)
    80201b74:	7902                	ld	s2,32(sp)
    80201b76:	69e2                	ld	s3,24(sp)
    80201b78:	6a42                	ld	s4,16(sp)
    80201b7a:	6aa2                	ld	s5,8(sp)
    80201b7c:	6121                	add	sp,sp,64
    80201b7e:	8082                	ret
        exit(-1);
    80201b80:	557d                	li	a0,-1
    80201b82:	00000097          	auipc	ra,0x0
    80201b86:	da2080e7          	jalr	-606(ra) # 80201924 <exit>
static inline void w_sstatus(uint64 x) { asm volatile("csrw sstatus, %0" : : "r" (x)); }
    80201b8a:	100a9073          	csrw	sstatus,s5
    if (p && p->trapframe) w_sepc(p->trapframe->epc);
    80201b8e:	bf95                	j	80201b02 <kerneltrap+0x9e>
    if (scause == 8) { // System Call
    80201b90:	47a1                	li	a5,8
    80201b92:	f4f904e3          	beq	s2,a5,80201ada <kerneltrap+0x76>
    else if (scause == 15) { // Store/AMO Page Fault (COW)
    80201b96:	47bd                	li	a5,15
    80201b98:	f0f919e3          	bne	s2,a5,80201aaa <kerneltrap+0x46>
            printf("kerneltrap: Fatal Page Fault at %p without process context\n", stval);
    80201b9c:	85d2                	mv	a1,s4
    80201b9e:	00005517          	auipc	a0,0x5
    80201ba2:	96a50513          	add	a0,a0,-1686 # 80206508 <_etext+0x508>
    80201ba6:	ffffe097          	auipc	ra,0xffffe
    80201baa:	5ae080e7          	jalr	1454(ra) # 80200154 <printf>
            printf("scause=%p sepc=%p\n", scause, sepc);
    80201bae:	864e                	mv	a2,s3
    80201bb0:	45bd                	li	a1,15
    80201bb2:	00005517          	auipc	a0,0x5
    80201bb6:	99650513          	add	a0,a0,-1642 # 80206548 <_etext+0x548>
    80201bba:	ffffe097          	auipc	ra,0xffffe
    80201bbe:	59a080e7          	jalr	1434(ra) # 80200154 <printf>
            while(1);
    80201bc2:	a001                	j	80201bc2 <kerneltrap+0x15e>
    if (scause == 8) { // System Call
    80201bc4:	47a1                	li	a5,8
    80201bc6:	ecf91fe3          	bne	s2,a5,80201aa4 <kerneltrap+0x40>
    80201bca:	bf01                	j	80201ada <kerneltrap+0x76>

0000000080201bcc <argint>:
    [SYS_mknod]   sys_mknod,
    [SYS_chdir]   sys_chdir,
    [SYS_fstat]   sys_fstat,
};

int argint(int n, int *ip) {
    80201bcc:	1101                	add	sp,sp,-32
    80201bce:	ec06                	sd	ra,24(sp)
    80201bd0:	e822                	sd	s0,16(sp)
    80201bd2:	e426                	sd	s1,8(sp)
    80201bd4:	e04a                	sd	s2,0(sp)
    80201bd6:	1000                	add	s0,sp,32
    80201bd8:	84aa                	mv	s1,a0
    80201bda:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80201bdc:	fffff097          	auipc	ra,0xfffff
    80201be0:	7cc080e7          	jalr	1996(ra) # 802013a8 <myproc>
    if (p == 0 || p->trapframe == 0) return -1;
    80201be4:	c13d                	beqz	a0,80201c4a <argint+0x7e>
    80201be6:	6134                	ld	a3,64(a0)
    80201be8:	c2bd                	beqz	a3,80201c4e <argint+0x82>
    switch(n) {
    80201bea:	4795                	li	a5,5
    80201bec:	0697e363          	bltu	a5,s1,80201c52 <argint+0x86>
    80201bf0:	00249793          	sll	a5,s1,0x2
    80201bf4:	00005717          	auipc	a4,0x5
    80201bf8:	9ac70713          	add	a4,a4,-1620 # 802065a0 <_etext+0x5a0>
    80201bfc:	97ba                	add	a5,a5,a4
    80201bfe:	439c                	lw	a5,0(a5)
    80201c00:	97ba                	add	a5,a5,a4
    80201c02:	8782                	jr	a5
        case 0: *ip = p->trapframe->a0; break;
    80201c04:	7abc                	ld	a5,112(a3)
    80201c06:	00f92023          	sw	a5,0(s2)
        case 3: *ip = p->trapframe->a3; break;
        case 4: *ip = p->trapframe->a4; break;
        case 5: *ip = p->trapframe->a5; break;
        default: return -1;
    }
    return 0;
    80201c0a:	8526                	mv	a0,s1
}
    80201c0c:	60e2                	ld	ra,24(sp)
    80201c0e:	6442                	ld	s0,16(sp)
    80201c10:	64a2                	ld	s1,8(sp)
    80201c12:	6902                	ld	s2,0(sp)
    80201c14:	6105                	add	sp,sp,32
    80201c16:	8082                	ret
        case 1: *ip = p->trapframe->a1; break;
    80201c18:	7ebc                	ld	a5,120(a3)
    80201c1a:	00f92023          	sw	a5,0(s2)
    return 0;
    80201c1e:	4501                	li	a0,0
        case 1: *ip = p->trapframe->a1; break;
    80201c20:	b7f5                	j	80201c0c <argint+0x40>
        case 2: *ip = p->trapframe->a2; break;
    80201c22:	62dc                	ld	a5,128(a3)
    80201c24:	00f92023          	sw	a5,0(s2)
    return 0;
    80201c28:	4501                	li	a0,0
        case 2: *ip = p->trapframe->a2; break;
    80201c2a:	b7cd                	j	80201c0c <argint+0x40>
        case 3: *ip = p->trapframe->a3; break;
    80201c2c:	66dc                	ld	a5,136(a3)
    80201c2e:	00f92023          	sw	a5,0(s2)
    return 0;
    80201c32:	4501                	li	a0,0
        case 3: *ip = p->trapframe->a3; break;
    80201c34:	bfe1                	j	80201c0c <argint+0x40>
        case 4: *ip = p->trapframe->a4; break;
    80201c36:	6adc                	ld	a5,144(a3)
    80201c38:	00f92023          	sw	a5,0(s2)
    return 0;
    80201c3c:	4501                	li	a0,0
        case 4: *ip = p->trapframe->a4; break;
    80201c3e:	b7f9                	j	80201c0c <argint+0x40>
        case 5: *ip = p->trapframe->a5; break;
    80201c40:	6edc                	ld	a5,152(a3)
    80201c42:	00f92023          	sw	a5,0(s2)
    return 0;
    80201c46:	4501                	li	a0,0
        case 5: *ip = p->trapframe->a5; break;
    80201c48:	b7d1                	j	80201c0c <argint+0x40>
    if (p == 0 || p->trapframe == 0) return -1;
    80201c4a:	557d                	li	a0,-1
    80201c4c:	b7c1                	j	80201c0c <argint+0x40>
    80201c4e:	557d                	li	a0,-1
    80201c50:	bf75                	j	80201c0c <argint+0x40>
    switch(n) {
    80201c52:	557d                	li	a0,-1
    80201c54:	bf65                	j	80201c0c <argint+0x40>

0000000080201c56 <argaddr>:

int argaddr(int n, uint64 *ip) {
    80201c56:	1101                	add	sp,sp,-32
    80201c58:	ec06                	sd	ra,24(sp)
    80201c5a:	e822                	sd	s0,16(sp)
    80201c5c:	e426                	sd	s1,8(sp)
    80201c5e:	e04a                	sd	s2,0(sp)
    80201c60:	1000                	add	s0,sp,32
    80201c62:	84aa                	mv	s1,a0
    80201c64:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80201c66:	fffff097          	auipc	ra,0xfffff
    80201c6a:	742080e7          	jalr	1858(ra) # 802013a8 <myproc>
    if (p == 0 || p->trapframe == 0) return -1;
    80201c6e:	c13d                	beqz	a0,80201cd4 <argaddr+0x7e>
    80201c70:	6134                	ld	a3,64(a0)
    80201c72:	c2bd                	beqz	a3,80201cd8 <argaddr+0x82>
    switch(n) {
    80201c74:	4795                	li	a5,5
    80201c76:	0697e363          	bltu	a5,s1,80201cdc <argaddr+0x86>
    80201c7a:	00249793          	sll	a5,s1,0x2
    80201c7e:	00005717          	auipc	a4,0x5
    80201c82:	93a70713          	add	a4,a4,-1734 # 802065b8 <_etext+0x5b8>
    80201c86:	97ba                	add	a5,a5,a4
    80201c88:	439c                	lw	a5,0(a5)
    80201c8a:	97ba                	add	a5,a5,a4
    80201c8c:	8782                	jr	a5
        case 0: *ip = p->trapframe->a0; break;
    80201c8e:	7abc                	ld	a5,112(a3)
    80201c90:	00f93023          	sd	a5,0(s2)
        case 3: *ip = p->trapframe->a3; break;
        case 4: *ip = p->trapframe->a4; break;
        case 5: *ip = p->trapframe->a5; break;
        default: return -1;
    }
    return 0;
    80201c94:	8526                	mv	a0,s1
}
    80201c96:	60e2                	ld	ra,24(sp)
    80201c98:	6442                	ld	s0,16(sp)
    80201c9a:	64a2                	ld	s1,8(sp)
    80201c9c:	6902                	ld	s2,0(sp)
    80201c9e:	6105                	add	sp,sp,32
    80201ca0:	8082                	ret
        case 1: *ip = p->trapframe->a1; break;
    80201ca2:	7ebc                	ld	a5,120(a3)
    80201ca4:	00f93023          	sd	a5,0(s2)
    return 0;
    80201ca8:	4501                	li	a0,0
        case 1: *ip = p->trapframe->a1; break;
    80201caa:	b7f5                	j	80201c96 <argaddr+0x40>
        case 2: *ip = p->trapframe->a2; break;
    80201cac:	62dc                	ld	a5,128(a3)
    80201cae:	00f93023          	sd	a5,0(s2)
    return 0;
    80201cb2:	4501                	li	a0,0
        case 2: *ip = p->trapframe->a2; break;
    80201cb4:	b7cd                	j	80201c96 <argaddr+0x40>
        case 3: *ip = p->trapframe->a3; break;
    80201cb6:	66dc                	ld	a5,136(a3)
    80201cb8:	00f93023          	sd	a5,0(s2)
    return 0;
    80201cbc:	4501                	li	a0,0
        case 3: *ip = p->trapframe->a3; break;
    80201cbe:	bfe1                	j	80201c96 <argaddr+0x40>
        case 4: *ip = p->trapframe->a4; break;
    80201cc0:	6adc                	ld	a5,144(a3)
    80201cc2:	00f93023          	sd	a5,0(s2)
    return 0;
    80201cc6:	4501                	li	a0,0
        case 4: *ip = p->trapframe->a4; break;
    80201cc8:	b7f9                	j	80201c96 <argaddr+0x40>
        case 5: *ip = p->trapframe->a5; break;
    80201cca:	6edc                	ld	a5,152(a3)
    80201ccc:	00f93023          	sd	a5,0(s2)
    return 0;
    80201cd0:	4501                	li	a0,0
        case 5: *ip = p->trapframe->a5; break;
    80201cd2:	b7d1                	j	80201c96 <argaddr+0x40>
    if (p == 0 || p->trapframe == 0) return -1;
    80201cd4:	557d                	li	a0,-1
    80201cd6:	b7c1                	j	80201c96 <argaddr+0x40>
    80201cd8:	557d                	li	a0,-1
    80201cda:	bf75                	j	80201c96 <argaddr+0x40>
    switch(n) {
    80201cdc:	557d                	li	a0,-1
    80201cde:	bf65                	j	80201c96 <argaddr+0x40>

0000000080201ce0 <argstr>:
//从用户态传递的第n个参数中，解析出字符串（用户态地址），并将其拷贝到内核的buf中，最多拷贝max字节。
int argstr(int n, char *buf, int max) {
    80201ce0:	7179                	add	sp,sp,-48
    80201ce2:	f406                	sd	ra,40(sp)
    80201ce4:	f022                	sd	s0,32(sp)
    80201ce6:	ec26                	sd	s1,24(sp)
    80201ce8:	e84a                	sd	s2,16(sp)
    80201cea:	1800                	add	s0,sp,48
    80201cec:	84ae                	mv	s1,a1
    80201cee:	8932                	mv	s2,a2
    uint64 addr;
    if(argaddr(n, &addr) < 0) return -1;
    80201cf0:	fd840593          	add	a1,s0,-40
    80201cf4:	00000097          	auipc	ra,0x0
    80201cf8:	f62080e7          	jalr	-158(ra) # 80201c56 <argaddr>
    80201cfc:	04054063          	bltz	a0,80201d3c <argstr+0x5c>
    char *src = (char*)addr;
    80201d00:	fd843683          	ld	a3,-40(s0)
    for(int i = 0; i < max; i++){
    80201d04:	03205063          	blez	s2,80201d24 <argstr+0x44>
    80201d08:	85ca                	mv	a1,s2
    80201d0a:	4501                	li	a0,0
        buf[i] = src[i];
    80201d0c:	00a687b3          	add	a5,a3,a0
    80201d10:	0007c783          	lbu	a5,0(a5)
    80201d14:	00a48733          	add	a4,s1,a0
    80201d18:	00f70023          	sb	a5,0(a4)
        if(src[i] == 0) return i;
    80201d1c:	cf91                	beqz	a5,80201d38 <argstr+0x58>
    for(int i = 0; i < max; i++){
    80201d1e:	0505                	add	a0,a0,1
    80201d20:	feb516e3          	bne	a0,a1,80201d0c <argstr+0x2c>
    }
    buf[max-1] = 0;
    80201d24:	94ca                	add	s1,s1,s2
    80201d26:	fe048fa3          	sb	zero,-1(s1)
    return -1;
    80201d2a:	557d                	li	a0,-1
}
    80201d2c:	70a2                	ld	ra,40(sp)
    80201d2e:	7402                	ld	s0,32(sp)
    80201d30:	64e2                	ld	s1,24(sp)
    80201d32:	6942                	ld	s2,16(sp)
    80201d34:	6145                	add	sp,sp,48
    80201d36:	8082                	ret
    80201d38:	2501                	sext.w	a0,a0
    80201d3a:	bfcd                	j	80201d2c <argstr+0x4c>
    if(argaddr(n, &addr) < 0) return -1;
    80201d3c:	557d                	li	a0,-1
    80201d3e:	b7fd                	j	80201d2c <argstr+0x4c>

0000000080201d40 <syscall>:
//用户态执行ecall指令陷入内核,调用该函数，完成系统调用的分发和执行。
void syscall(void) {
    80201d40:	1101                	add	sp,sp,-32
    80201d42:	ec06                	sd	ra,24(sp)
    80201d44:	e822                	sd	s0,16(sp)
    80201d46:	e426                	sd	s1,8(sp)
    80201d48:	1000                	add	s0,sp,32
    int num;
    struct proc *p = myproc();
    80201d4a:	fffff097          	auipc	ra,0xfffff
    80201d4e:	65e080e7          	jalr	1630(ra) # 802013a8 <myproc>
    // 检查进程和陷阱帧是否有效
    if (p == 0 || p->trapframe == 0) {
    80201d52:	c905                	beqz	a0,80201d82 <syscall+0x42>
    80201d54:	84aa                	mv	s1,a0
    80201d56:	613c                	ld	a5,64(a0)
    80201d58:	c78d                	beqz	a5,80201d82 <syscall+0x42>
        // panic("syscall");
        while(1);
    }
    // 从trapframe的a7寄存器中获取系统调用号
    num = p->trapframe->a7;
    80201d5a:	77dc                	ld	a5,168(a5)
    80201d5c:	0007869b          	sext.w	a3,a5

    if(num > 0 && num < sizeof(syscalls)/sizeof(syscalls[0]) && syscalls[num]) {
    80201d60:	37fd                	addw	a5,a5,-1
    80201d62:	4779                	li	a4,30
    80201d64:	02f76063          	bltu	a4,a5,80201d84 <syscall+0x44>
    80201d68:	00369713          	sll	a4,a3,0x3
    80201d6c:	00005797          	auipc	a5,0x5
    80201d70:	86478793          	add	a5,a5,-1948 # 802065d0 <syscalls>
    80201d74:	97ba                	add	a5,a5,a4
    80201d76:	639c                	ld	a5,0(a5)
    80201d78:	c791                	beqz	a5,80201d84 <syscall+0x44>
        p->trapframe->a0 = syscalls[num]();
    80201d7a:	9782                	jalr	a5
    80201d7c:	60bc                	ld	a5,64(s1)
    80201d7e:	fba8                	sd	a0,112(a5)
    80201d80:	a005                	j	80201da0 <syscall+0x60>
        while(1);
    80201d82:	a001                	j	80201d82 <syscall+0x42>
    } else {
        printf("pid %d %s: unknown sys call %d\n", p->pid, p->name, num);
    80201d84:	0c848613          	add	a2,s1,200
    80201d88:	4ccc                	lw	a1,28(s1)
    80201d8a:	00005517          	auipc	a0,0x5
    80201d8e:	94650513          	add	a0,a0,-1722 # 802066d0 <syscalls+0x100>
    80201d92:	ffffe097          	auipc	ra,0xffffe
    80201d96:	3c2080e7          	jalr	962(ra) # 80200154 <printf>
        p->trapframe->a0 = -1;
    80201d9a:	60bc                	ld	a5,64(s1)
    80201d9c:	577d                	li	a4,-1
    80201d9e:	fbb8                	sd	a4,112(a5)
    }
    80201da0:	60e2                	ld	ra,24(sp)
    80201da2:	6442                	ld	s0,16(sp)
    80201da4:	64a2                	ld	s1,8(sp)
    80201da6:	6105                	add	sp,sp,32
    80201da8:	8082                	ret

0000000080201daa <sys_getpid>:
// kernel/sysproc.c
#include "defs.h"

int sys_getpid(void) {
    80201daa:	1141                	add	sp,sp,-16
    80201dac:	e406                	sd	ra,8(sp)
    80201dae:	e022                	sd	s0,0(sp)
    80201db0:	0800                	add	s0,sp,16
    // [关键] 性能测试绝对不能包含 printf
    return myproc()->pid;
    80201db2:	fffff097          	auipc	ra,0xfffff
    80201db6:	5f6080e7          	jalr	1526(ra) # 802013a8 <myproc>
}
    80201dba:	4d48                	lw	a0,28(a0)
    80201dbc:	60a2                	ld	ra,8(sp)
    80201dbe:	6402                	ld	s0,0(sp)
    80201dc0:	0141                	add	sp,sp,16
    80201dc2:	8082                	ret

0000000080201dc4 <sys_exit>:

int sys_exit(void) {
    80201dc4:	1101                	add	sp,sp,-32
    80201dc6:	ec06                	sd	ra,24(sp)
    80201dc8:	e822                	sd	s0,16(sp)
    80201dca:	1000                	add	s0,sp,32
    int n;
    if(argint(0, &n) < 0)
    80201dcc:	fec40593          	add	a1,s0,-20
    80201dd0:	4501                	li	a0,0
    80201dd2:	00000097          	auipc	ra,0x0
    80201dd6:	dfa080e7          	jalr	-518(ra) # 80201bcc <argint>
    80201dda:	00054d63          	bltz	a0,80201df4 <sys_exit+0x30>
        return -1;
    exit(n);
    80201dde:	fec42503          	lw	a0,-20(s0)
    80201de2:	00000097          	auipc	ra,0x0
    80201de6:	b42080e7          	jalr	-1214(ra) # 80201924 <exit>
    return 0; 
    80201dea:	4501                	li	a0,0
}
    80201dec:	60e2                	ld	ra,24(sp)
    80201dee:	6442                	ld	s0,16(sp)
    80201df0:	6105                	add	sp,sp,32
    80201df2:	8082                	ret
        return -1;
    80201df4:	557d                	li	a0,-1
    80201df6:	bfdd                	j	80201dec <sys_exit+0x28>

0000000080201df8 <sys_fork>:

int sys_fork(void) {
    80201df8:	1141                	add	sp,sp,-16
    80201dfa:	e406                	sd	ra,8(sp)
    80201dfc:	e022                	sd	s0,0(sp)
    80201dfe:	0800                	add	s0,sp,16
    return fork();
    80201e00:	fffff097          	auipc	ra,0xfffff
    80201e04:	6ca080e7          	jalr	1738(ra) # 802014ca <fork>
}
    80201e08:	60a2                	ld	ra,8(sp)
    80201e0a:	6402                	ld	s0,0(sp)
    80201e0c:	0141                	add	sp,sp,16
    80201e0e:	8082                	ret

0000000080201e10 <sys_wait>:

int sys_wait(void) {
    80201e10:	1101                	add	sp,sp,-32
    80201e12:	ec06                	sd	ra,24(sp)
    80201e14:	e822                	sd	s0,16(sp)
    80201e16:	1000                	add	s0,sp,32
    uint64 p;
    if(argaddr(0, &p) < 0)
    80201e18:	fe840593          	add	a1,s0,-24
    80201e1c:	4501                	li	a0,0
    80201e1e:	00000097          	auipc	ra,0x0
    80201e22:	e38080e7          	jalr	-456(ra) # 80201c56 <argaddr>
    80201e26:	00054c63          	bltz	a0,80201e3e <sys_wait+0x2e>
        return -1;
    return wait((int*)p);
    80201e2a:	fe843503          	ld	a0,-24(s0)
    80201e2e:	00000097          	auipc	ra,0x0
    80201e32:	990080e7          	jalr	-1648(ra) # 802017be <wait>
}
    80201e36:	60e2                	ld	ra,24(sp)
    80201e38:	6442                	ld	s0,16(sp)
    80201e3a:	6105                	add	sp,sp,32
    80201e3c:	8082                	ret
        return -1;
    80201e3e:	557d                	li	a0,-1
    80201e40:	bfdd                	j	80201e36 <sys_wait+0x26>

0000000080201e42 <sys_kill>:

int sys_kill(void) {
    80201e42:	1101                	add	sp,sp,-32
    80201e44:	ec06                	sd	ra,24(sp)
    80201e46:	e822                	sd	s0,16(sp)
    80201e48:	1000                	add	s0,sp,32
    int pid;
    if(argint(0, &pid) < 0)
    80201e4a:	fec40593          	add	a1,s0,-20
    80201e4e:	4501                	li	a0,0
    80201e50:	00000097          	auipc	ra,0x0
    80201e54:	d7c080e7          	jalr	-644(ra) # 80201bcc <argint>
    80201e58:	00054a63          	bltz	a0,80201e6c <sys_kill+0x2a>
        return -1;
    printf("sys_kill not implemented\n");
    80201e5c:	00005517          	auipc	a0,0x5
    80201e60:	89450513          	add	a0,a0,-1900 # 802066f0 <syscalls+0x120>
    80201e64:	ffffe097          	auipc	ra,0xffffe
    80201e68:	2f0080e7          	jalr	752(ra) # 80200154 <printf>
    return -1; 
    80201e6c:	557d                	li	a0,-1
    80201e6e:	60e2                	ld	ra,24(sp)
    80201e70:	6442                	ld	s0,16(sp)
    80201e72:	6105                	add	sp,sp,32
    80201e74:	8082                	ret

0000000080201e76 <binit>:
    struct spinlock lock;
    struct buf buf[NBUF];
    struct buf head;
} bcache;

void binit(void) {
    80201e76:	7179                	add	sp,sp,-48
    80201e78:	f406                	sd	ra,40(sp)
    80201e7a:	f022                	sd	s0,32(sp)
    80201e7c:	ec26                	sd	s1,24(sp)
    80201e7e:	e84a                	sd	s2,16(sp)
    80201e80:	e44e                	sd	s3,8(sp)
    80201e82:	e052                	sd	s4,0(sp)
    80201e84:	1800                	add	s0,sp,48
    struct buf *b;

    spinlock_init(&bcache.lock, "bcache");
    80201e86:	00005597          	auipc	a1,0x5
    80201e8a:	88a58593          	add	a1,a1,-1910 # 80206710 <syscalls+0x140>
    80201e8e:	0002d517          	auipc	a0,0x2d
    80201e92:	a1250513          	add	a0,a0,-1518 # 8022e8a0 <bcache>
    80201e96:	fffff097          	auipc	ra,0xfffff
    80201e9a:	942080e7          	jalr	-1726(ra) # 802007d8 <spinlock_init>
    bcache.head.prev = &bcache.head;
    80201e9e:	00035797          	auipc	a5,0x35
    80201ea2:	a0278793          	add	a5,a5,-1534 # 802368a0 <bcache+0x8000>
    80201ea6:	00035717          	auipc	a4,0x35
    80201eaa:	c6270713          	add	a4,a4,-926 # 80236b08 <bcache+0x8268>
    80201eae:	2ae7b823          	sd	a4,688(a5)
    bcache.head.next = &bcache.head;
    80201eb2:	2ae7bc23          	sd	a4,696(a5)

    for (b = bcache.buf; b < bcache.buf + NBUF; b++) {
    80201eb6:	0002d497          	auipc	s1,0x2d
    80201eba:	a0248493          	add	s1,s1,-1534 # 8022e8b8 <bcache+0x18>
        b->next = bcache.head.next;
    80201ebe:	893e                	mv	s2,a5
        b->prev = &bcache.head;
    80201ec0:	89ba                	mv	s3,a4
        bcache.head.next->prev = b;
        bcache.head.next = b;
        initsleeplock(&b->lock, "buffer");
    80201ec2:	00005a17          	auipc	s4,0x5
    80201ec6:	856a0a13          	add	s4,s4,-1962 # 80206718 <syscalls+0x148>
        b->next = bcache.head.next;
    80201eca:	2b893783          	ld	a5,696(s2)
    80201ece:	e8bc                	sd	a5,80(s1)
        b->prev = &bcache.head;
    80201ed0:	0534b423          	sd	s3,72(s1)
        bcache.head.next->prev = b;
    80201ed4:	2b893783          	ld	a5,696(s2)
    80201ed8:	e7a4                	sd	s1,72(a5)
        bcache.head.next = b;
    80201eda:	2a993c23          	sd	s1,696(s2)
        initsleeplock(&b->lock, "buffer");
    80201ede:	85d2                	mv	a1,s4
    80201ee0:	01048513          	add	a0,s1,16
    80201ee4:	00002097          	auipc	ra,0x2
    80201ee8:	93e080e7          	jalr	-1730(ra) # 80203822 <initsleeplock>
    for (b = bcache.buf; b < bcache.buf + NBUF; b++) {
    80201eec:	45848493          	add	s1,s1,1112
    80201ef0:	fd349de3          	bne	s1,s3,80201eca <binit+0x54>
    }
}
    80201ef4:	70a2                	ld	ra,40(sp)
    80201ef6:	7402                	ld	s0,32(sp)
    80201ef8:	64e2                	ld	s1,24(sp)
    80201efa:	6942                	ld	s2,16(sp)
    80201efc:	69a2                	ld	s3,8(sp)
    80201efe:	6a02                	ld	s4,0(sp)
    80201f00:	6145                	add	sp,sp,48
    80201f02:	8082                	ret

0000000080201f04 <bread>:

    panic("bget: no buffers");
    return 0;
}

struct buf *bread(uint dev, uint blockno) {
    80201f04:	7179                	add	sp,sp,-48
    80201f06:	f406                	sd	ra,40(sp)
    80201f08:	f022                	sd	s0,32(sp)
    80201f0a:	ec26                	sd	s1,24(sp)
    80201f0c:	e84a                	sd	s2,16(sp)
    80201f0e:	e44e                	sd	s3,8(sp)
    80201f10:	1800                	add	s0,sp,48
    80201f12:	892a                	mv	s2,a0
    80201f14:	89ae                	mv	s3,a1
    acquire(&bcache.lock);
    80201f16:	0002d517          	auipc	a0,0x2d
    80201f1a:	98a50513          	add	a0,a0,-1654 # 8022e8a0 <bcache>
    80201f1e:	fffff097          	auipc	ra,0xfffff
    80201f22:	91c080e7          	jalr	-1764(ra) # 8020083a <acquire>
    for (b = bcache.head.next; b != &bcache.head; b = b->next) {
    80201f26:	00035497          	auipc	s1,0x35
    80201f2a:	c324b483          	ld	s1,-974(s1) # 80236b58 <bcache+0x82b8>
    80201f2e:	00035797          	auipc	a5,0x35
    80201f32:	bda78793          	add	a5,a5,-1062 # 80236b08 <bcache+0x8268>
    80201f36:	04f48663          	beq	s1,a5,80201f82 <bread+0x7e>
    80201f3a:	873e                	mv	a4,a5
    80201f3c:	a021                	j	80201f44 <bread+0x40>
    80201f3e:	68a4                	ld	s1,80(s1)
    80201f40:	04e48163          	beq	s1,a4,80201f82 <bread+0x7e>
        if (b->dev == dev && b->blockno == blockno) {
    80201f44:	449c                	lw	a5,8(s1)
    80201f46:	ff279ce3          	bne	a5,s2,80201f3e <bread+0x3a>
    80201f4a:	44dc                	lw	a5,12(s1)
    80201f4c:	ff3799e3          	bne	a5,s3,80201f3e <bread+0x3a>
            b->refcnt++;
    80201f50:	40bc                	lw	a5,64(s1)
    80201f52:	2785                	addw	a5,a5,1
    80201f54:	c0bc                	sw	a5,64(s1)
            cache_hits++;
    80201f56:	0000e717          	auipc	a4,0xe
    80201f5a:	0ca70713          	add	a4,a4,202 # 80210020 <cache_hits>
    80201f5e:	631c                	ld	a5,0(a4)
    80201f60:	0785                	add	a5,a5,1
    80201f62:	e31c                	sd	a5,0(a4)
            release(&bcache.lock);
    80201f64:	0002d517          	auipc	a0,0x2d
    80201f68:	93c50513          	add	a0,a0,-1732 # 8022e8a0 <bcache>
    80201f6c:	fffff097          	auipc	ra,0xfffff
    80201f70:	9c0080e7          	jalr	-1600(ra) # 8020092c <release>
            acquiresleep(&b->lock);
    80201f74:	01048513          	add	a0,s1,16
    80201f78:	00002097          	auipc	ra,0x2
    80201f7c:	8e4080e7          	jalr	-1820(ra) # 8020385c <acquiresleep>
            return b;
    80201f80:	a815                	j	80201fb4 <bread+0xb0>
    for (b = bcache.head.prev; b != &bcache.head; b = b->prev) {
    80201f82:	00035497          	auipc	s1,0x35
    80201f86:	bce4b483          	ld	s1,-1074(s1) # 80236b50 <bcache+0x82b0>
    80201f8a:	00035797          	auipc	a5,0x35
    80201f8e:	b7e78793          	add	a5,a5,-1154 # 80236b08 <bcache+0x8268>
    80201f92:	00f48863          	beq	s1,a5,80201fa2 <bread+0x9e>
    80201f96:	873e                	mv	a4,a5
        if (b->refcnt == 0) {
    80201f98:	40bc                	lw	a5,64(s1)
    80201f9a:	c79d                	beqz	a5,80201fc8 <bread+0xc4>
    for (b = bcache.head.prev; b != &bcache.head; b = b->prev) {
    80201f9c:	64a4                	ld	s1,72(s1)
    80201f9e:	fee49de3          	bne	s1,a4,80201f98 <bread+0x94>
    panic("bget: no buffers");
    80201fa2:	00004517          	auipc	a0,0x4
    80201fa6:	77e50513          	add	a0,a0,1918 # 80206720 <syscalls+0x150>
    80201faa:	ffffe097          	auipc	ra,0xffffe
    80201fae:	42a080e7          	jalr	1066(ra) # 802003d4 <panic>
    return 0;
    80201fb2:	4481                	li	s1,0
    struct buf *b = bget(dev, blockno);
    if (!b->valid) {
    80201fb4:	409c                	lw	a5,0(s1)
    80201fb6:	c7b9                	beqz	a5,80202004 <bread+0x100>
        virtio_disk_rw(b, 0);
        b->valid = 1;
    }
    return b;
}
    80201fb8:	8526                	mv	a0,s1
    80201fba:	70a2                	ld	ra,40(sp)
    80201fbc:	7402                	ld	s0,32(sp)
    80201fbe:	64e2                	ld	s1,24(sp)
    80201fc0:	6942                	ld	s2,16(sp)
    80201fc2:	69a2                	ld	s3,8(sp)
    80201fc4:	6145                	add	sp,sp,48
    80201fc6:	8082                	ret
            b->dev = dev;
    80201fc8:	0124a423          	sw	s2,8(s1)
            b->blockno = blockno;
    80201fcc:	0134a623          	sw	s3,12(s1)
            b->valid = 0;
    80201fd0:	0004a023          	sw	zero,0(s1)
            b->refcnt = 1;
    80201fd4:	4785                	li	a5,1
    80201fd6:	c0bc                	sw	a5,64(s1)
            cache_misses++;
    80201fd8:	0000e717          	auipc	a4,0xe
    80201fdc:	04070713          	add	a4,a4,64 # 80210018 <cache_misses>
    80201fe0:	631c                	ld	a5,0(a4)
    80201fe2:	0785                	add	a5,a5,1
    80201fe4:	e31c                	sd	a5,0(a4)
            release(&bcache.lock);
    80201fe6:	0002d517          	auipc	a0,0x2d
    80201fea:	8ba50513          	add	a0,a0,-1862 # 8022e8a0 <bcache>
    80201fee:	fffff097          	auipc	ra,0xfffff
    80201ff2:	93e080e7          	jalr	-1730(ra) # 8020092c <release>
            acquiresleep(&b->lock);
    80201ff6:	01048513          	add	a0,s1,16
    80201ffa:	00002097          	auipc	ra,0x2
    80201ffe:	862080e7          	jalr	-1950(ra) # 8020385c <acquiresleep>
            return b;
    80202002:	bf4d                	j	80201fb4 <bread+0xb0>
        virtio_disk_rw(b, 0);
    80202004:	4581                	li	a1,0
    80202006:	8526                	mv	a0,s1
    80202008:	00003097          	auipc	ra,0x3
    8020200c:	c0e080e7          	jalr	-1010(ra) # 80204c16 <virtio_disk_rw>
        b->valid = 1;
    80202010:	4785                	li	a5,1
    80202012:	c09c                	sw	a5,0(s1)
    return b;
    80202014:	b755                	j	80201fb8 <bread+0xb4>

0000000080202016 <bwrite>:

void bwrite(struct buf *b) {
    80202016:	1101                	add	sp,sp,-32
    80202018:	ec06                	sd	ra,24(sp)
    8020201a:	e822                	sd	s0,16(sp)
    8020201c:	e426                	sd	s1,8(sp)
    8020201e:	1000                	add	s0,sp,32
    80202020:	84aa                	mv	s1,a0
    if (!holdingsleep(&b->lock)) {
    80202022:	0541                	add	a0,a0,16
    80202024:	00002097          	auipc	ra,0x2
    80202028:	8d0080e7          	jalr	-1840(ra) # 802038f4 <holdingsleep>
    8020202c:	cd01                	beqz	a0,80202044 <bwrite+0x2e>
        panic("bwrite");
    }
    virtio_disk_rw(b, 1);
    8020202e:	4585                	li	a1,1
    80202030:	8526                	mv	a0,s1
    80202032:	00003097          	auipc	ra,0x3
    80202036:	be4080e7          	jalr	-1052(ra) # 80204c16 <virtio_disk_rw>
}
    8020203a:	60e2                	ld	ra,24(sp)
    8020203c:	6442                	ld	s0,16(sp)
    8020203e:	64a2                	ld	s1,8(sp)
    80202040:	6105                	add	sp,sp,32
    80202042:	8082                	ret
        panic("bwrite");
    80202044:	00004517          	auipc	a0,0x4
    80202048:	6f450513          	add	a0,a0,1780 # 80206738 <syscalls+0x168>
    8020204c:	ffffe097          	auipc	ra,0xffffe
    80202050:	388080e7          	jalr	904(ra) # 802003d4 <panic>
    80202054:	bfe9                	j	8020202e <bwrite+0x18>

0000000080202056 <brelse>:

void brelse(struct buf *b) {
    80202056:	1101                	add	sp,sp,-32
    80202058:	ec06                	sd	ra,24(sp)
    8020205a:	e822                	sd	s0,16(sp)
    8020205c:	e426                	sd	s1,8(sp)
    8020205e:	e04a                	sd	s2,0(sp)
    80202060:	1000                	add	s0,sp,32
    80202062:	84aa                	mv	s1,a0
    if (!holdingsleep(&b->lock)) {
    80202064:	01050913          	add	s2,a0,16
    80202068:	854a                	mv	a0,s2
    8020206a:	00002097          	auipc	ra,0x2
    8020206e:	88a080e7          	jalr	-1910(ra) # 802038f4 <holdingsleep>
    80202072:	c925                	beqz	a0,802020e2 <brelse+0x8c>
        panic("brelse");
    }

    releasesleep(&b->lock);
    80202074:	854a                	mv	a0,s2
    80202076:	00002097          	auipc	ra,0x2
    8020207a:	83a080e7          	jalr	-1990(ra) # 802038b0 <releasesleep>

    acquire(&bcache.lock);
    8020207e:	0002d517          	auipc	a0,0x2d
    80202082:	82250513          	add	a0,a0,-2014 # 8022e8a0 <bcache>
    80202086:	ffffe097          	auipc	ra,0xffffe
    8020208a:	7b4080e7          	jalr	1972(ra) # 8020083a <acquire>
    b->refcnt--;
    8020208e:	40bc                	lw	a5,64(s1)
    80202090:	37fd                	addw	a5,a5,-1
    80202092:	0007871b          	sext.w	a4,a5
    80202096:	c0bc                	sw	a5,64(s1)
    if (b->refcnt == 0) {
    80202098:	e71d                	bnez	a4,802020c6 <brelse+0x70>
        b->next->prev = b->prev;
    8020209a:	68b8                	ld	a4,80(s1)
    8020209c:	64bc                	ld	a5,72(s1)
    8020209e:	e73c                	sd	a5,72(a4)
        b->prev->next = b->next;
    802020a0:	68b8                	ld	a4,80(s1)
    802020a2:	ebb8                	sd	a4,80(a5)
        b->next = bcache.head.next;
    802020a4:	00034797          	auipc	a5,0x34
    802020a8:	7fc78793          	add	a5,a5,2044 # 802368a0 <bcache+0x8000>
    802020ac:	2b87b703          	ld	a4,696(a5)
    802020b0:	e8b8                	sd	a4,80(s1)
        b->prev = &bcache.head;
    802020b2:	00035717          	auipc	a4,0x35
    802020b6:	a5670713          	add	a4,a4,-1450 # 80236b08 <bcache+0x8268>
    802020ba:	e4b8                	sd	a4,72(s1)
        bcache.head.next->prev = b;
    802020bc:	2b87b703          	ld	a4,696(a5)
    802020c0:	e724                	sd	s1,72(a4)
        bcache.head.next = b;
    802020c2:	2a97bc23          	sd	s1,696(a5)
    }
    release(&bcache.lock);
    802020c6:	0002c517          	auipc	a0,0x2c
    802020ca:	7da50513          	add	a0,a0,2010 # 8022e8a0 <bcache>
    802020ce:	fffff097          	auipc	ra,0xfffff
    802020d2:	85e080e7          	jalr	-1954(ra) # 8020092c <release>
}
    802020d6:	60e2                	ld	ra,24(sp)
    802020d8:	6442                	ld	s0,16(sp)
    802020da:	64a2                	ld	s1,8(sp)
    802020dc:	6902                	ld	s2,0(sp)
    802020de:	6105                	add	sp,sp,32
    802020e0:	8082                	ret
        panic("brelse");
    802020e2:	00004517          	auipc	a0,0x4
    802020e6:	65e50513          	add	a0,a0,1630 # 80206740 <syscalls+0x170>
    802020ea:	ffffe097          	auipc	ra,0xffffe
    802020ee:	2ea080e7          	jalr	746(ra) # 802003d4 <panic>
    802020f2:	b749                	j	80202074 <brelse+0x1e>

00000000802020f4 <bpin>:

void bpin(struct buf *b) {
    802020f4:	1101                	add	sp,sp,-32
    802020f6:	ec06                	sd	ra,24(sp)
    802020f8:	e822                	sd	s0,16(sp)
    802020fa:	e426                	sd	s1,8(sp)
    802020fc:	1000                	add	s0,sp,32
    802020fe:	84aa                	mv	s1,a0
    acquire(&bcache.lock);
    80202100:	0002c517          	auipc	a0,0x2c
    80202104:	7a050513          	add	a0,a0,1952 # 8022e8a0 <bcache>
    80202108:	ffffe097          	auipc	ra,0xffffe
    8020210c:	732080e7          	jalr	1842(ra) # 8020083a <acquire>
    b->refcnt++;
    80202110:	40bc                	lw	a5,64(s1)
    80202112:	2785                	addw	a5,a5,1
    80202114:	c0bc                	sw	a5,64(s1)
    release(&bcache.lock);
    80202116:	0002c517          	auipc	a0,0x2c
    8020211a:	78a50513          	add	a0,a0,1930 # 8022e8a0 <bcache>
    8020211e:	fffff097          	auipc	ra,0xfffff
    80202122:	80e080e7          	jalr	-2034(ra) # 8020092c <release>
}
    80202126:	60e2                	ld	ra,24(sp)
    80202128:	6442                	ld	s0,16(sp)
    8020212a:	64a2                	ld	s1,8(sp)
    8020212c:	6105                	add	sp,sp,32
    8020212e:	8082                	ret

0000000080202130 <bunpin>:

void bunpin(struct buf *b) {
    80202130:	1101                	add	sp,sp,-32
    80202132:	ec06                	sd	ra,24(sp)
    80202134:	e822                	sd	s0,16(sp)
    80202136:	e426                	sd	s1,8(sp)
    80202138:	1000                	add	s0,sp,32
    8020213a:	84aa                	mv	s1,a0
    acquire(&bcache.lock);
    8020213c:	0002c517          	auipc	a0,0x2c
    80202140:	76450513          	add	a0,a0,1892 # 8022e8a0 <bcache>
    80202144:	ffffe097          	auipc	ra,0xffffe
    80202148:	6f6080e7          	jalr	1782(ra) # 8020083a <acquire>
    b->refcnt--;
    8020214c:	40bc                	lw	a5,64(s1)
    8020214e:	37fd                	addw	a5,a5,-1
    80202150:	c0bc                	sw	a5,64(s1)
    release(&bcache.lock);
    80202152:	0002c517          	auipc	a0,0x2c
    80202156:	74e50513          	add	a0,a0,1870 # 8022e8a0 <bcache>
    8020215a:	ffffe097          	auipc	ra,0xffffe
    8020215e:	7d2080e7          	jalr	2002(ra) # 8020092c <release>
}
    80202162:	60e2                	ld	ra,24(sp)
    80202164:	6442                	ld	s0,16(sp)
    80202166:	64a2                	ld	s1,8(sp)
    80202168:	6105                	add	sp,sp,32
    8020216a:	8082                	ret

000000008020216c <get_buffer_cache_hits>:

uint64 get_buffer_cache_hits(void) {
    8020216c:	1141                	add	sp,sp,-16
    8020216e:	e422                	sd	s0,8(sp)
    80202170:	0800                	add	s0,sp,16
    return cache_hits;
}
    80202172:	0000e517          	auipc	a0,0xe
    80202176:	eae53503          	ld	a0,-338(a0) # 80210020 <cache_hits>
    8020217a:	6422                	ld	s0,8(sp)
    8020217c:	0141                	add	sp,sp,16
    8020217e:	8082                	ret

0000000080202180 <get_buffer_cache_misses>:

uint64 get_buffer_cache_misses(void) {
    80202180:	1141                	add	sp,sp,-16
    80202182:	e422                	sd	s0,8(sp)
    80202184:	0800                	add	s0,sp,16
    return cache_misses;
}
    80202186:	0000e517          	auipc	a0,0xe
    8020218a:	e9253503          	ld	a0,-366(a0) # 80210018 <cache_misses>
    8020218e:	6422                	ld	s0,8(sp)
    80202190:	0141                	add	sp,sp,16
    80202192:	8082                	ret

0000000080202194 <bitmap_set>:
    }
    release(&icache.lock);
}

// 仅供 fs_format 使用的辅助函数，格式化时无并发，可直接 bwrite
static void bitmap_set(int dev, uint blockno) {
    80202194:	1101                	add	sp,sp,-32
    80202196:	ec06                	sd	ra,24(sp)
    80202198:	e822                	sd	s0,16(sp)
    8020219a:	e426                	sd	s1,8(sp)
    8020219c:	e04a                	sd	s2,0(sp)
    8020219e:	1000                	add	s0,sp,32
    802021a0:	84ae                	mv	s1,a1
    struct buf *bp = bread(dev, BBLOCK(blockno, sb));
    802021a2:	00d5d59b          	srlw	a1,a1,0xd
    802021a6:	00035797          	auipc	a5,0x35
    802021aa:	dd67a783          	lw	a5,-554(a5) # 80236f7c <sb+0x1c>
    802021ae:	9dbd                	addw	a1,a1,a5
    802021b0:	00000097          	auipc	ra,0x0
    802021b4:	d54080e7          	jalr	-684(ra) # 80201f04 <bread>
    802021b8:	892a                	mv	s2,a0
    uint bi = blockno % BPB;
    802021ba:	03349793          	sll	a5,s1,0x33
    bp->data[bi / 8] |= 1 << (bi % 8);
    802021be:	93d9                	srl	a5,a5,0x36
    802021c0:	97aa                	add	a5,a5,a0
    802021c2:	889d                	and	s1,s1,7
    802021c4:	4685                	li	a3,1
    802021c6:	009696bb          	sllw	a3,a3,s1
    802021ca:	0587c703          	lbu	a4,88(a5)
    802021ce:	8f55                	or	a4,a4,a3
    802021d0:	04e78c23          	sb	a4,88(a5)
    bwrite(bp);
    802021d4:	00000097          	auipc	ra,0x0
    802021d8:	e42080e7          	jalr	-446(ra) # 80202016 <bwrite>
    brelse(bp);
    802021dc:	854a                	mv	a0,s2
    802021de:	00000097          	auipc	ra,0x0
    802021e2:	e78080e7          	jalr	-392(ra) # 80202056 <brelse>
}
    802021e6:	60e2                	ld	ra,24(sp)
    802021e8:	6442                	ld	s0,16(sp)
    802021ea:	64a2                	ld	s1,8(sp)
    802021ec:	6902                	ld	s2,0(sp)
    802021ee:	6105                	add	sp,sp,32
    802021f0:	8082                	ret

00000000802021f2 <readsb>:
static void readsb(int dev, struct superblock *sb) {
    802021f2:	1101                	add	sp,sp,-32
    802021f4:	ec06                	sd	ra,24(sp)
    802021f6:	e822                	sd	s0,16(sp)
    802021f8:	e426                	sd	s1,8(sp)
    802021fa:	e04a                	sd	s2,0(sp)
    802021fc:	1000                	add	s0,sp,32
    802021fe:	892e                	mv	s2,a1
    struct buf *bp = bread(dev, 1);
    80202200:	4585                	li	a1,1
    80202202:	00000097          	auipc	ra,0x0
    80202206:	d02080e7          	jalr	-766(ra) # 80201f04 <bread>
    8020220a:	84aa                	mv	s1,a0
    memmove(sb, bp->data, sizeof(*sb));
    8020220c:	02000613          	li	a2,32
    80202210:	05850593          	add	a1,a0,88
    80202214:	854a                	mv	a0,s2
    80202216:	ffffe097          	auipc	ra,0xffffe
    8020221a:	7ae080e7          	jalr	1966(ra) # 802009c4 <memmove>
    brelse(bp);
    8020221e:	8526                	mv	a0,s1
    80202220:	00000097          	auipc	ra,0x0
    80202224:	e36080e7          	jalr	-458(ra) # 80202056 <brelse>
}
    80202228:	60e2                	ld	ra,24(sp)
    8020222a:	6442                	ld	s0,16(sp)
    8020222c:	64a2                	ld	s1,8(sp)
    8020222e:	6902                	ld	s2,0(sp)
    80202230:	6105                	add	sp,sp,32
    80202232:	8082                	ret

0000000080202234 <bfree>:
static void bfree(int dev, uint b) {
    80202234:	7179                	add	sp,sp,-48
    80202236:	f406                	sd	ra,40(sp)
    80202238:	f022                	sd	s0,32(sp)
    8020223a:	ec26                	sd	s1,24(sp)
    8020223c:	e84a                	sd	s2,16(sp)
    8020223e:	e44e                	sd	s3,8(sp)
    80202240:	e052                	sd	s4,0(sp)
    80202242:	1800                	add	s0,sp,48
    80202244:	84ae                	mv	s1,a1
    struct buf *bp = bread(dev, BBLOCK(b, sb));
    80202246:	00d5d59b          	srlw	a1,a1,0xd
    8020224a:	00035797          	auipc	a5,0x35
    8020224e:	d327a783          	lw	a5,-718(a5) # 80236f7c <sb+0x1c>
    80202252:	9dbd                	addw	a1,a1,a5
    80202254:	00000097          	auipc	ra,0x0
    80202258:	cb0080e7          	jalr	-848(ra) # 80201f04 <bread>
    8020225c:	892a                	mv	s2,a0
    int m = 1 << (bi % 8);
    8020225e:	0074f793          	and	a5,s1,7
    80202262:	4a05                	li	s4,1
    80202264:	00fa1a3b          	sllw	s4,s4,a5
    uint bi = b % BPB;
    80202268:	14ce                	sll	s1,s1,0x33
    if ((bp->data[bi / 8] & m) == 0) {
    8020226a:	0364d993          	srl	s3,s1,0x36
    8020226e:	013504b3          	add	s1,a0,s3
    80202272:	0584c783          	lbu	a5,88(s1)
    80202276:	00fa77b3          	and	a5,s4,a5
    8020227a:	cf9d                	beqz	a5,802022b8 <bfree+0x84>
    bp->data[bi / 8] &= ~m;
    8020227c:	02099793          	sll	a5,s3,0x20
    80202280:	9381                	srl	a5,a5,0x20
    80202282:	97ca                	add	a5,a5,s2
    80202284:	fffa4a13          	not	s4,s4
    80202288:	0587c703          	lbu	a4,88(a5)
    8020228c:	01477733          	and	a4,a4,s4
    80202290:	04e78c23          	sb	a4,88(a5)
    log_write(bp); // [恢复] 使用 log_write
    80202294:	854a                	mv	a0,s2
    80202296:	00001097          	auipc	ra,0x1
    8020229a:	49c080e7          	jalr	1180(ra) # 80203732 <log_write>
    brelse(bp);
    8020229e:	854a                	mv	a0,s2
    802022a0:	00000097          	auipc	ra,0x0
    802022a4:	db6080e7          	jalr	-586(ra) # 80202056 <brelse>
}
    802022a8:	70a2                	ld	ra,40(sp)
    802022aa:	7402                	ld	s0,32(sp)
    802022ac:	64e2                	ld	s1,24(sp)
    802022ae:	6942                	ld	s2,16(sp)
    802022b0:	69a2                	ld	s3,8(sp)
    802022b2:	6a02                	ld	s4,0(sp)
    802022b4:	6145                	add	sp,sp,48
    802022b6:	8082                	ret
        panic("bfree: freeing free block");
    802022b8:	00004517          	auipc	a0,0x4
    802022bc:	49050513          	add	a0,a0,1168 # 80206748 <syscalls+0x178>
    802022c0:	ffffe097          	auipc	ra,0xffffe
    802022c4:	114080e7          	jalr	276(ra) # 802003d4 <panic>
    802022c8:	bf55                	j	8020227c <bfree+0x48>

00000000802022ca <balloc>:
static uint balloc(uint dev) {
    802022ca:	711d                	add	sp,sp,-96
    802022cc:	ec86                	sd	ra,88(sp)
    802022ce:	e8a2                	sd	s0,80(sp)
    802022d0:	e4a6                	sd	s1,72(sp)
    802022d2:	e0ca                	sd	s2,64(sp)
    802022d4:	fc4e                	sd	s3,56(sp)
    802022d6:	f852                	sd	s4,48(sp)
    802022d8:	f456                	sd	s5,40(sp)
    802022da:	f05a                	sd	s6,32(sp)
    802022dc:	ec5e                	sd	s7,24(sp)
    802022de:	e862                	sd	s8,16(sp)
    802022e0:	e466                	sd	s9,8(sp)
    802022e2:	e06a                	sd	s10,0(sp)
    802022e4:	1080                	add	s0,sp,96
    return sb.bmapstart + ((sb.nblocks + BPB - 1) / BPB);
    802022e6:	00035797          	auipc	a5,0x35
    802022ea:	c7a78793          	add	a5,a5,-902 # 80236f60 <sb>
    802022ee:	4798                	lw	a4,8(a5)
    802022f0:	6909                	lui	s2,0x2
    802022f2:	397d                	addw	s2,s2,-1 # 1fff <_start-0x801fe001>
    802022f4:	00e9093b          	addw	s2,s2,a4
    802022f8:	00d9591b          	srlw	s2,s2,0xd
    802022fc:	4fd8                	lw	a4,28(a5)
    802022fe:	00e9093b          	addw	s2,s2,a4
    for (b = 0; b < sb.size; b += BPB) {
    80202302:	43dc                	lw	a5,4(a5)
    80202304:	c7f5                	beqz	a5,802023f0 <balloc+0x126>
    80202306:	8c2a                	mv	s8,a0
    80202308:	4b01                	li	s6,0
        bp = bread(dev, BBLOCK(b, sb));
    8020230a:	00035b97          	auipc	s7,0x35
    8020230e:	c56b8b93          	add	s7,s7,-938 # 80236f60 <sb>
        for (uint bi = 0; bi < BPB && b + bi < sb.size; bi++) {
    80202312:	4c81                	li	s9,0
            int m = 1 << (bi % 8);
    80202314:	4a85                	li	s5,1
        for (uint bi = 0; bi < BPB && b + bi < sb.size; bi++) {
    80202316:	6a09                	lui	s4,0x2
    for (b = 0; b < sb.size; b += BPB) {
    80202318:	6d09                	lui	s10,0x2
    8020231a:	a85d                	j	802023d0 <balloc+0x106>
        for (uint bi = 0; bi < BPB && b + bi < sb.size; bi++) {
    8020231c:	2785                	addw	a5,a5,1
    8020231e:	2485                	addw	s1,s1,1
    80202320:	09478d63          	beq	a5,s4,802023ba <balloc+0xf0>
    80202324:	08b4fb63          	bgeu	s1,a1,802023ba <balloc+0xf0>
            if (blockno < start)
    80202328:	ff24eae3          	bltu	s1,s2,8020231c <balloc+0x52>
            int m = 1 << (bi % 8);
    8020232c:	0077f713          	and	a4,a5,7
    80202330:	00ea973b          	sllw	a4,s5,a4
            if ((bp->data[bi / 8] & m) == 0) {
    80202334:	0037d51b          	srlw	a0,a5,0x3
    80202338:	0037d69b          	srlw	a3,a5,0x3
    8020233c:	96ce                	add	a3,a3,s3
    8020233e:	0586c683          	lbu	a3,88(a3)
    80202342:	00d77633          	and	a2,a4,a3
    80202346:	fa79                	bnez	a2,8020231c <balloc+0x52>
                bp->data[bi / 8] |= m;
    80202348:	1502                	sll	a0,a0,0x20
    8020234a:	9101                	srl	a0,a0,0x20
    8020234c:	954e                	add	a0,a0,s3
    8020234e:	8ed9                	or	a3,a3,a4
    80202350:	04d50c23          	sb	a3,88(a0)
                log_write(bp); // [恢复] 使用 log_write
    80202354:	854e                	mv	a0,s3
    80202356:	00001097          	auipc	ra,0x1
    8020235a:	3dc080e7          	jalr	988(ra) # 80203732 <log_write>
                brelse(bp);
    8020235e:	854e                	mv	a0,s3
    80202360:	00000097          	auipc	ra,0x0
    80202364:	cf6080e7          	jalr	-778(ra) # 80202056 <brelse>
    struct buf *bp = bread(dev, bno);
    80202368:	85a6                	mv	a1,s1
    8020236a:	8562                	mv	a0,s8
    8020236c:	00000097          	auipc	ra,0x0
    80202370:	b98080e7          	jalr	-1128(ra) # 80201f04 <bread>
    80202374:	892a                	mv	s2,a0
    memset(bp->data, 0, BSIZE);
    80202376:	40000613          	li	a2,1024
    8020237a:	4581                	li	a1,0
    8020237c:	05850513          	add	a0,a0,88
    80202380:	ffffe097          	auipc	ra,0xffffe
    80202384:	622080e7          	jalr	1570(ra) # 802009a2 <memset>
    log_write(bp); // [恢复] 使用 log_write 保证事务原子性
    80202388:	854a                	mv	a0,s2
    8020238a:	00001097          	auipc	ra,0x1
    8020238e:	3a8080e7          	jalr	936(ra) # 80203732 <log_write>
    brelse(bp);
    80202392:	854a                	mv	a0,s2
    80202394:	00000097          	auipc	ra,0x0
    80202398:	cc2080e7          	jalr	-830(ra) # 80202056 <brelse>
}
    8020239c:	8526                	mv	a0,s1
    8020239e:	60e6                	ld	ra,88(sp)
    802023a0:	6446                	ld	s0,80(sp)
    802023a2:	64a6                	ld	s1,72(sp)
    802023a4:	6906                	ld	s2,64(sp)
    802023a6:	79e2                	ld	s3,56(sp)
    802023a8:	7a42                	ld	s4,48(sp)
    802023aa:	7aa2                	ld	s5,40(sp)
    802023ac:	7b02                	ld	s6,32(sp)
    802023ae:	6be2                	ld	s7,24(sp)
    802023b0:	6c42                	ld	s8,16(sp)
    802023b2:	6ca2                	ld	s9,8(sp)
    802023b4:	6d02                	ld	s10,0(sp)
    802023b6:	6125                	add	sp,sp,96
    802023b8:	8082                	ret
        brelse(bp);
    802023ba:	854e                	mv	a0,s3
    802023bc:	00000097          	auipc	ra,0x0
    802023c0:	c9a080e7          	jalr	-870(ra) # 80202056 <brelse>
    for (b = 0; b < sb.size; b += BPB) {
    802023c4:	016d0b3b          	addw	s6,s10,s6
    802023c8:	004ba783          	lw	a5,4(s7)
    802023cc:	02fb7263          	bgeu	s6,a5,802023f0 <balloc+0x126>
        bp = bread(dev, BBLOCK(b, sb));
    802023d0:	00db559b          	srlw	a1,s6,0xd
    802023d4:	01cba783          	lw	a5,28(s7)
    802023d8:	9dbd                	addw	a1,a1,a5
    802023da:	8562                	mv	a0,s8
    802023dc:	00000097          	auipc	ra,0x0
    802023e0:	b28080e7          	jalr	-1240(ra) # 80201f04 <bread>
    802023e4:	89aa                	mv	s3,a0
        for (uint bi = 0; bi < BPB && b + bi < sb.size; bi++) {
    802023e6:	004ba583          	lw	a1,4(s7)
    802023ea:	84da                	mv	s1,s6
    802023ec:	87e6                	mv	a5,s9
    802023ee:	bf1d                	j	80202324 <balloc+0x5a>
    panic("balloc: out of blocks");
    802023f0:	00004517          	auipc	a0,0x4
    802023f4:	37850513          	add	a0,a0,888 # 80206768 <syscalls+0x198>
    802023f8:	ffffe097          	auipc	ra,0xffffe
    802023fc:	fdc080e7          	jalr	-36(ra) # 802003d4 <panic>
    return 0;
    80202400:	4481                	li	s1,0
    80202402:	bf69                	j	8020239c <balloc+0xd2>

0000000080202404 <bmap>:
static uint bmap(struct inode *ip, uint bn) {
    80202404:	7179                	add	sp,sp,-48
    80202406:	f406                	sd	ra,40(sp)
    80202408:	f022                	sd	s0,32(sp)
    8020240a:	ec26                	sd	s1,24(sp)
    8020240c:	e84a                	sd	s2,16(sp)
    8020240e:	e44e                	sd	s3,8(sp)
    80202410:	e052                	sd	s4,0(sp)
    80202412:	1800                	add	s0,sp,48
    80202414:	892a                	mv	s2,a0
    if (bn < NDIRECT) {
    80202416:	47ad                	li	a5,11
    80202418:	04b7fe63          	bgeu	a5,a1,80202474 <bmap+0x70>
    bn -= NDIRECT;
    8020241c:	ff45849b          	addw	s1,a1,-12
    80202420:	0004871b          	sext.w	a4,s1
    if (bn < NINDIRECT) {
    80202424:	0ff00793          	li	a5,255
    80202428:	0ae7e163          	bltu	a5,a4,802024ca <bmap+0xc6>
        if ((addr = ip->addrs[NDIRECT]) == 0)
    8020242c:	08052583          	lw	a1,128(a0)
    80202430:	c5b5                	beqz	a1,8020249c <bmap+0x98>
        bp = bread(ip->dev, addr);
    80202432:	00092503          	lw	a0,0(s2)
    80202436:	00000097          	auipc	ra,0x0
    8020243a:	ace080e7          	jalr	-1330(ra) # 80201f04 <bread>
    8020243e:	8a2a                	mv	s4,a0
        uint *a = (uint*)bp->data;
    80202440:	05850793          	add	a5,a0,88
        if (a[bn] == 0) {
    80202444:	02049713          	sll	a4,s1,0x20
    80202448:	01e75593          	srl	a1,a4,0x1e
    8020244c:	00b784b3          	add	s1,a5,a1
    80202450:	409c                	lw	a5,0(s1)
    80202452:	cfb9                	beqz	a5,802024b0 <bmap+0xac>
        uint r = a[bn];
    80202454:	0004a983          	lw	s3,0(s1)
        brelse(bp);
    80202458:	8552                	mv	a0,s4
    8020245a:	00000097          	auipc	ra,0x0
    8020245e:	bfc080e7          	jalr	-1028(ra) # 80202056 <brelse>
}
    80202462:	854e                	mv	a0,s3
    80202464:	70a2                	ld	ra,40(sp)
    80202466:	7402                	ld	s0,32(sp)
    80202468:	64e2                	ld	s1,24(sp)
    8020246a:	6942                	ld	s2,16(sp)
    8020246c:	69a2                	ld	s3,8(sp)
    8020246e:	6a02                	ld	s4,0(sp)
    80202470:	6145                	add	sp,sp,48
    80202472:	8082                	ret
        if ((addr = ip->addrs[bn]) == 0)
    80202474:	02059793          	sll	a5,a1,0x20
    80202478:	01e7d593          	srl	a1,a5,0x1e
    8020247c:	00b504b3          	add	s1,a0,a1
    80202480:	0504a983          	lw	s3,80(s1)
    80202484:	fc099fe3          	bnez	s3,80202462 <bmap+0x5e>
            ip->addrs[bn] = addr = balloc(ip->dev);
    80202488:	4108                	lw	a0,0(a0)
    8020248a:	00000097          	auipc	ra,0x0
    8020248e:	e40080e7          	jalr	-448(ra) # 802022ca <balloc>
    80202492:	0005099b          	sext.w	s3,a0
    80202496:	0534a823          	sw	s3,80(s1)
    8020249a:	b7e1                	j	80202462 <bmap+0x5e>
            ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8020249c:	4108                	lw	a0,0(a0)
    8020249e:	00000097          	auipc	ra,0x0
    802024a2:	e2c080e7          	jalr	-468(ra) # 802022ca <balloc>
    802024a6:	0005059b          	sext.w	a1,a0
    802024aa:	08b92023          	sw	a1,128(s2)
    802024ae:	b751                	j	80202432 <bmap+0x2e>
            a[bn] = balloc(ip->dev);
    802024b0:	00092503          	lw	a0,0(s2)
    802024b4:	00000097          	auipc	ra,0x0
    802024b8:	e16080e7          	jalr	-490(ra) # 802022ca <balloc>
    802024bc:	c088                	sw	a0,0(s1)
            log_write(bp); // [恢复] 使用 log_write
    802024be:	8552                	mv	a0,s4
    802024c0:	00001097          	auipc	ra,0x1
    802024c4:	272080e7          	jalr	626(ra) # 80203732 <log_write>
    802024c8:	b771                	j	80202454 <bmap+0x50>
    panic("bmap");
    802024ca:	00004517          	auipc	a0,0x4
    802024ce:	2b650513          	add	a0,a0,694 # 80206780 <syscalls+0x1b0>
    802024d2:	ffffe097          	auipc	ra,0xffffe
    802024d6:	f02080e7          	jalr	-254(ra) # 802003d4 <panic>
    return 0;
    802024da:	4981                	li	s3,0
    802024dc:	b759                	j	80202462 <bmap+0x5e>

00000000802024de <iinit>:
void iinit(void) {
    802024de:	7139                	add	sp,sp,-64
    802024e0:	fc06                	sd	ra,56(sp)
    802024e2:	f822                	sd	s0,48(sp)
    802024e4:	f426                	sd	s1,40(sp)
    802024e6:	f04a                	sd	s2,32(sp)
    802024e8:	ec4e                	sd	s3,24(sp)
    802024ea:	e852                	sd	s4,16(sp)
    802024ec:	e456                	sd	s5,8(sp)
    802024ee:	0080                	add	s0,sp,64
    readsb(ROOTDEV, &sb);
    802024f0:	00035497          	auipc	s1,0x35
    802024f4:	a7048493          	add	s1,s1,-1424 # 80236f60 <sb>
    802024f8:	85a6                	mv	a1,s1
    802024fa:	4505                	li	a0,1
    802024fc:	00000097          	auipc	ra,0x0
    80202500:	cf6080e7          	jalr	-778(ra) # 802021f2 <readsb>
    if (sb.magic != FSMAGIC) {
    80202504:	4098                	lw	a4,0(s1)
    80202506:	102037b7          	lui	a5,0x10203
    8020250a:	04078793          	add	a5,a5,64 # 10203040 <_start-0x6fffcfc0>
    8020250e:	06f71f63          	bne	a4,a5,8020258c <iinit+0xae>
    spinlock_init(&icache.lock, "icache");
    80202512:	00004597          	auipc	a1,0x4
    80202516:	2a658593          	add	a1,a1,678 # 802067b8 <syscalls+0x1e8>
    8020251a:	00035517          	auipc	a0,0x35
    8020251e:	a6650513          	add	a0,a0,-1434 # 80236f80 <icache>
    80202522:	ffffe097          	auipc	ra,0xffffe
    80202526:	2b6080e7          	jalr	694(ra) # 802007d8 <spinlock_init>
    for (int i = 0; i < NINODE; i++) {
    8020252a:	00035497          	auipc	s1,0x35
    8020252e:	a7e48493          	add	s1,s1,-1410 # 80236fa8 <icache+0x28>
    80202532:	0003f997          	auipc	s3,0x3f
    80202536:	9d698993          	add	s3,s3,-1578 # 80240f08 <log+0x10>
        initsleeplock(&icache.inode[i].lock, "inode");
    8020253a:	00004917          	auipc	s2,0x4
    8020253e:	28690913          	add	s2,s2,646 # 802067c0 <syscalls+0x1f0>
        icache.inode[i].ref = 0;
    80202542:	fe04ac23          	sw	zero,-8(s1)
        initsleeplock(&icache.inode[i].lock, "inode");
    80202546:	85ca                	mv	a1,s2
    80202548:	8526                	mv	a0,s1
    8020254a:	00001097          	auipc	ra,0x1
    8020254e:	2d8080e7          	jalr	728(ra) # 80203822 <initsleeplock>
    for (int i = 0; i < NINODE; i++) {
    80202552:	08848493          	add	s1,s1,136
    80202556:	ff3496e3          	bne	s1,s3,80202542 <iinit+0x64>
    printf("fs: size=%d nblocks=%d ninodes=%d nlog=%d\n", sb.size, sb.nblocks, sb.ninodes, sb.nlog);
    8020255a:	00035797          	auipc	a5,0x35
    8020255e:	a0678793          	add	a5,a5,-1530 # 80236f60 <sb>
    80202562:	4b98                	lw	a4,16(a5)
    80202564:	47d4                	lw	a3,12(a5)
    80202566:	4790                	lw	a2,8(a5)
    80202568:	43cc                	lw	a1,4(a5)
    8020256a:	00004517          	auipc	a0,0x4
    8020256e:	25e50513          	add	a0,a0,606 # 802067c8 <syscalls+0x1f8>
    80202572:	ffffe097          	auipc	ra,0xffffe
    80202576:	be2080e7          	jalr	-1054(ra) # 80200154 <printf>
}
    8020257a:	70e2                	ld	ra,56(sp)
    8020257c:	7442                	ld	s0,48(sp)
    8020257e:	74a2                	ld	s1,40(sp)
    80202580:	7902                	ld	s2,32(sp)
    80202582:	69e2                	ld	s3,24(sp)
    80202584:	6a42                	ld	s4,16(sp)
    80202586:	6aa2                	ld	s5,8(sp)
    80202588:	6121                	add	sp,sp,64
    8020258a:	8082                	ret

static void fs_format(int dev) {
    printf("Formatting filesystem...\n");
    8020258c:	00004517          	auipc	a0,0x4
    80202590:	1fc50513          	add	a0,a0,508 # 80206788 <syscalls+0x1b8>
    80202594:	ffffe097          	auipc	ra,0xffffe
    80202598:	bc0080e7          	jalr	-1088(ra) # 80200154 <printf>
    memset(&sb, 0, sizeof(sb));
    8020259c:	02000613          	li	a2,32
    802025a0:	4581                	li	a1,0
    802025a2:	8526                	mv	a0,s1
    802025a4:	ffffe097          	auipc	ra,0xffffe
    802025a8:	3fe080e7          	jalr	1022(ra) # 802009a2 <memset>
    sb.magic = FSMAGIC;
    802025ac:	102037b7          	lui	a5,0x10203
    802025b0:	04078793          	add	a5,a5,64 # 10203040 <_start-0x6fffcfc0>
    802025b4:	c09c                	sw	a5,0(s1)
    sb.size = FSSIZE;
    802025b6:	6785                	lui	a5,0x1
    802025b8:	c0dc                	sw	a5,4(s1)
    sb.ninodes = NINODE;
    802025ba:	12c00713          	li	a4,300
    802025be:	c4d8                	sw	a4,12(s1)
    sb.nlog = LOGSIZE;
    802025c0:	4779                	li	a4,30
    802025c2:	c898                	sw	a4,16(s1)
    sb.logstart = 2;
    802025c4:	4709                	li	a4,2
    802025c6:	c8d8                	sw	a4,20(s1)
    sb.inodestart = sb.logstart + sb.nlog;
    802025c8:	02000713          	li	a4,32
    802025cc:	cc98                	sw	a4,24(s1)
    int inodeblocks = (sb.ninodes + IPB - 1) / IPB;
    sb.bmapstart = sb.inodestart + inodeblocks;
    802025ce:	03300713          	li	a4,51
    802025d2:	ccd8                	sw	a4,28(s1)
    uint bitmapblocks = 1; // temporary
    sb.nblocks = sb.size - (sb.bmapstart + bitmapblocks);
    802025d4:	fcc78793          	add	a5,a5,-52 # fcc <_start-0x801ff034>
    802025d8:	c49c                	sw	a5,8(s1)
    bitmapblocks = (sb.nblocks + BPB - 1) / BPB;
    sb.nblocks = sb.size - (sb.bmapstart + bitmapblocks);

    for (uint b = 0; b < sb.size; b++) {
    802025da:	4901                	li	s2,0
    802025dc:	89a6                	mv	s3,s1
        struct buf *bp = bread(dev, b);
    802025de:	85ca                	mv	a1,s2
    802025e0:	4505                	li	a0,1
    802025e2:	00000097          	auipc	ra,0x0
    802025e6:	922080e7          	jalr	-1758(ra) # 80201f04 <bread>
    802025ea:	84aa                	mv	s1,a0
        memset(bp->data, 0, BSIZE);
    802025ec:	40000613          	li	a2,1024
    802025f0:	4581                	li	a1,0
    802025f2:	05850513          	add	a0,a0,88
    802025f6:	ffffe097          	auipc	ra,0xffffe
    802025fa:	3ac080e7          	jalr	940(ra) # 802009a2 <memset>
        bwrite(bp);
    802025fe:	8526                	mv	a0,s1
    80202600:	00000097          	auipc	ra,0x0
    80202604:	a16080e7          	jalr	-1514(ra) # 80202016 <bwrite>
        brelse(bp);
    80202608:	8526                	mv	a0,s1
    8020260a:	00000097          	auipc	ra,0x0
    8020260e:	a4c080e7          	jalr	-1460(ra) # 80202056 <brelse>
    for (uint b = 0; b < sb.size; b++) {
    80202612:	2905                	addw	s2,s2,1
    80202614:	0049a783          	lw	a5,4(s3)
    80202618:	fcf963e3          	bltu	s2,a5,802025de <iinit+0x100>
    }

    struct buf *bp = bread(dev, 1);
    8020261c:	4585                	li	a1,1
    8020261e:	4505                	li	a0,1
    80202620:	00000097          	auipc	ra,0x0
    80202624:	8e4080e7          	jalr	-1820(ra) # 80201f04 <bread>
    80202628:	84aa                	mv	s1,a0
    memmove(bp->data, &sb, sizeof(sb));
    8020262a:	00035917          	auipc	s2,0x35
    8020262e:	93690913          	add	s2,s2,-1738 # 80236f60 <sb>
    80202632:	02000613          	li	a2,32
    80202636:	85ca                	mv	a1,s2
    80202638:	05850513          	add	a0,a0,88
    8020263c:	ffffe097          	auipc	ra,0xffffe
    80202640:	388080e7          	jalr	904(ra) # 802009c4 <memmove>
    bwrite(bp);
    80202644:	8526                	mv	a0,s1
    80202646:	00000097          	auipc	ra,0x0
    8020264a:	9d0080e7          	jalr	-1584(ra) # 80202016 <bwrite>
    brelse(bp);
    8020264e:	8526                	mv	a0,s1
    80202650:	00000097          	auipc	ra,0x0
    80202654:	a06080e7          	jalr	-1530(ra) # 80202056 <brelse>
    return sb.bmapstart + ((sb.nblocks + BPB - 1) / BPB);
    80202658:	00892783          	lw	a5,8(s2)
    8020265c:	6989                	lui	s3,0x2
    8020265e:	39fd                	addw	s3,s3,-1 # 1fff <_start-0x801fe001>
    80202660:	00f989bb          	addw	s3,s3,a5
    80202664:	00d9d99b          	srlw	s3,s3,0xd
    80202668:	01c92783          	lw	a5,28(s2)
    8020266c:	00f989bb          	addw	s3,s3,a5
    80202670:	0009891b          	sext.w	s2,s3

    uint start = data_start_block();
    for (uint b = 0; b < start; b++)
    80202674:	00090c63          	beqz	s2,8020268c <iinit+0x1ae>
    80202678:	4481                	li	s1,0
        bitmap_set(dev, b);
    8020267a:	85a6                	mv	a1,s1
    8020267c:	4505                	li	a0,1
    8020267e:	00000097          	auipc	ra,0x0
    80202682:	b16080e7          	jalr	-1258(ra) # 80202194 <bitmap_set>
    for (uint b = 0; b < start; b++)
    80202686:	2485                	addw	s1,s1,1
    80202688:	fe9919e3          	bne	s2,s1,8020267a <iinit+0x19c>

    uint root_block = start;
    bitmap_set(dev, root_block);
    8020268c:	85ca                	mv	a1,s2
    8020268e:	4505                	li	a0,1
    80202690:	00000097          	auipc	ra,0x0
    80202694:	b04080e7          	jalr	-1276(ra) # 80202194 <bitmap_set>

    struct buf *ib = bread(dev, IBLOCK(ROOTINO, sb));
    80202698:	00035a97          	auipc	s5,0x35
    8020269c:	8c8a8a93          	add	s5,s5,-1848 # 80236f60 <sb>
    802026a0:	018aa583          	lw	a1,24(s5)
    802026a4:	4505                	li	a0,1
    802026a6:	00000097          	auipc	ra,0x0
    802026aa:	85e080e7          	jalr	-1954(ra) # 80201f04 <bread>
    802026ae:	84aa                	mv	s1,a0
    struct dinode *dip = (struct dinode*)ib->data + ROOTINO % IPB;
    memset(dip, 0, sizeof(*dip));
    802026b0:	04000613          	li	a2,64
    802026b4:	4581                	li	a1,0
    802026b6:	09850513          	add	a0,a0,152
    802026ba:	ffffe097          	auipc	ra,0xffffe
    802026be:	2e8080e7          	jalr	744(ra) # 802009a2 <memset>
    dip->type = T_DIR;
    802026c2:	4a05                	li	s4,1
    802026c4:	09449c23          	sh	s4,152(s1)
    dip->nlink = 2;
    802026c8:	4789                	li	a5,2
    802026ca:	08f49f23          	sh	a5,158(s1)
    dip->size = sizeof(struct dirent) * 2;
    802026ce:	02000793          	li	a5,32
    802026d2:	0af4a023          	sw	a5,160(s1)
    dip->addrs[0] = root_block;
    802026d6:	0b34a223          	sw	s3,164(s1)
    bwrite(ib);
    802026da:	8526                	mv	a0,s1
    802026dc:	00000097          	auipc	ra,0x0
    802026e0:	93a080e7          	jalr	-1734(ra) # 80202016 <bwrite>
    brelse(ib);
    802026e4:	8526                	mv	a0,s1
    802026e6:	00000097          	auipc	ra,0x0
    802026ea:	970080e7          	jalr	-1680(ra) # 80202056 <brelse>

    struct buf *db = bread(dev, root_block);
    802026ee:	85ca                	mv	a1,s2
    802026f0:	4505                	li	a0,1
    802026f2:	00000097          	auipc	ra,0x0
    802026f6:	812080e7          	jalr	-2030(ra) # 80201f04 <bread>
    802026fa:	84aa                	mv	s1,a0
    struct dirent *de = (struct dirent*)db->data;
    memset(de, 0, BSIZE);
    802026fc:	40000613          	li	a2,1024
    80202700:	4581                	li	a1,0
    80202702:	05850513          	add	a0,a0,88
    80202706:	ffffe097          	auipc	ra,0xffffe
    8020270a:	29c080e7          	jalr	668(ra) # 802009a2 <memset>
    de[0].inum = ROOTINO;
    8020270e:	05449c23          	sh	s4,88(s1)
    safestrcpy(de[0].name, ".", DIRSIZ);
    80202712:	4639                	li	a2,14
    80202714:	00004597          	auipc	a1,0x4
    80202718:	09458593          	add	a1,a1,148 # 802067a8 <syscalls+0x1d8>
    8020271c:	05a48513          	add	a0,s1,90
    80202720:	ffffe097          	auipc	ra,0xffffe
    80202724:	3cc080e7          	jalr	972(ra) # 80200aec <safestrcpy>
    de[1].inum = ROOTINO;
    80202728:	07449423          	sh	s4,104(s1)
    safestrcpy(de[1].name, "..", DIRSIZ);
    8020272c:	4639                	li	a2,14
    8020272e:	00004597          	auipc	a1,0x4
    80202732:	08258593          	add	a1,a1,130 # 802067b0 <syscalls+0x1e0>
    80202736:	06a48513          	add	a0,s1,106
    8020273a:	ffffe097          	auipc	ra,0xffffe
    8020273e:	3b2080e7          	jalr	946(ra) # 80200aec <safestrcpy>
    bwrite(db);
    80202742:	8526                	mv	a0,s1
    80202744:	00000097          	auipc	ra,0x0
    80202748:	8d2080e7          	jalr	-1838(ra) # 80202016 <bwrite>
    brelse(db);
    8020274c:	8526                	mv	a0,s1
    8020274e:	00000097          	auipc	ra,0x0
    80202752:	908080e7          	jalr	-1784(ra) # 80202056 <brelse>
        readsb(ROOTDEV, &sb);
    80202756:	85d6                	mv	a1,s5
    80202758:	4505                	li	a0,1
    8020275a:	00000097          	auipc	ra,0x0
    8020275e:	a98080e7          	jalr	-1384(ra) # 802021f2 <readsb>
    80202762:	bb45                	j	80202512 <iinit+0x34>

0000000080202764 <iget>:
struct inode *iget(uint dev, uint inum) {
    80202764:	7179                	add	sp,sp,-48
    80202766:	f406                	sd	ra,40(sp)
    80202768:	f022                	sd	s0,32(sp)
    8020276a:	ec26                	sd	s1,24(sp)
    8020276c:	e84a                	sd	s2,16(sp)
    8020276e:	e44e                	sd	s3,8(sp)
    80202770:	e052                	sd	s4,0(sp)
    80202772:	1800                	add	s0,sp,48
    80202774:	89aa                	mv	s3,a0
    80202776:	8a2e                	mv	s4,a1
    acquire(&icache.lock);
    80202778:	00035517          	auipc	a0,0x35
    8020277c:	80850513          	add	a0,a0,-2040 # 80236f80 <icache>
    80202780:	ffffe097          	auipc	ra,0xffffe
    80202784:	0ba080e7          	jalr	186(ra) # 8020083a <acquire>
    struct inode *ip, *empty = 0;
    80202788:	4901                	li	s2,0
    for (ip = icache.inode; ip < &icache.inode[NINODE]; ip++) {
    8020278a:	00035497          	auipc	s1,0x35
    8020278e:	80e48493          	add	s1,s1,-2034 # 80236f98 <icache+0x18>
    80202792:	0003e697          	auipc	a3,0x3e
    80202796:	76668693          	add	a3,a3,1894 # 80240ef8 <log>
    8020279a:	a039                	j	802027a8 <iget+0x44>
        if (empty == 0 && ip->ref == 0)
    8020279c:	04090263          	beqz	s2,802027e0 <iget+0x7c>
    for (ip = icache.inode; ip < &icache.inode[NINODE]; ip++) {
    802027a0:	08848493          	add	s1,s1,136
    802027a4:	04d48163          	beq	s1,a3,802027e6 <iget+0x82>
        if (ip->ref > 0 && ip->dev == dev && ip->inum == inum) {
    802027a8:	449c                	lw	a5,8(s1)
    802027aa:	fef059e3          	blez	a5,8020279c <iget+0x38>
    802027ae:	4098                	lw	a4,0(s1)
    802027b0:	ff3716e3          	bne	a4,s3,8020279c <iget+0x38>
    802027b4:	40d8                	lw	a4,4(s1)
    802027b6:	ff4713e3          	bne	a4,s4,8020279c <iget+0x38>
            ip->ref++;
    802027ba:	2785                	addw	a5,a5,1
    802027bc:	c49c                	sw	a5,8(s1)
            release(&icache.lock);
    802027be:	00034517          	auipc	a0,0x34
    802027c2:	7c250513          	add	a0,a0,1986 # 80236f80 <icache>
    802027c6:	ffffe097          	auipc	ra,0xffffe
    802027ca:	166080e7          	jalr	358(ra) # 8020092c <release>
}
    802027ce:	8526                	mv	a0,s1
    802027d0:	70a2                	ld	ra,40(sp)
    802027d2:	7402                	ld	s0,32(sp)
    802027d4:	64e2                	ld	s1,24(sp)
    802027d6:	6942                	ld	s2,16(sp)
    802027d8:	69a2                	ld	s3,8(sp)
    802027da:	6a02                	ld	s4,0(sp)
    802027dc:	6145                	add	sp,sp,48
    802027de:	8082                	ret
        if (empty == 0 && ip->ref == 0)
    802027e0:	f3e1                	bnez	a5,802027a0 <iget+0x3c>
    802027e2:	8926                	mv	s2,s1
    802027e4:	bf75                	j	802027a0 <iget+0x3c>
    if (empty == 0)
    802027e6:	02090563          	beqz	s2,80202810 <iget+0xac>
    ip->dev = dev;
    802027ea:	01392023          	sw	s3,0(s2)
    ip->inum = inum;
    802027ee:	01492223          	sw	s4,4(s2)
    ip->ref = 1;
    802027f2:	4785                	li	a5,1
    802027f4:	00f92423          	sw	a5,8(s2)
    ip->valid = 0;
    802027f8:	04092023          	sw	zero,64(s2)
    release(&icache.lock);
    802027fc:	00034517          	auipc	a0,0x34
    80202800:	78450513          	add	a0,a0,1924 # 80236f80 <icache>
    80202804:	ffffe097          	auipc	ra,0xffffe
    80202808:	128080e7          	jalr	296(ra) # 8020092c <release>
    return ip;
    8020280c:	84ca                	mv	s1,s2
    8020280e:	b7c1                	j	802027ce <iget+0x6a>
        panic("iget: no inodes");
    80202810:	00004517          	auipc	a0,0x4
    80202814:	fe850513          	add	a0,a0,-24 # 802067f8 <syscalls+0x228>
    80202818:	ffffe097          	auipc	ra,0xffffe
    8020281c:	bbc080e7          	jalr	-1092(ra) # 802003d4 <panic>
    80202820:	b7e9                	j	802027ea <iget+0x86>

0000000080202822 <ialloc>:
struct inode *ialloc(uint dev, short type) {
    80202822:	7139                	add	sp,sp,-64
    80202824:	fc06                	sd	ra,56(sp)
    80202826:	f822                	sd	s0,48(sp)
    80202828:	f426                	sd	s1,40(sp)
    8020282a:	f04a                	sd	s2,32(sp)
    8020282c:	ec4e                	sd	s3,24(sp)
    8020282e:	e852                	sd	s4,16(sp)
    80202830:	e456                	sd	s5,8(sp)
    80202832:	e05a                	sd	s6,0(sp)
    80202834:	0080                	add	s0,sp,64
    for (uint inum = 1; inum < sb.ninodes; inum++) {
    80202836:	00034717          	auipc	a4,0x34
    8020283a:	73672703          	lw	a4,1846(a4) # 80236f6c <sb+0xc>
    8020283e:	4785                	li	a5,1
    80202840:	04e7f663          	bgeu	a5,a4,8020288c <ialloc+0x6a>
    80202844:	8aaa                	mv	s5,a0
    80202846:	8b2e                	mv	s6,a1
    80202848:	4905                	li	s2,1
        struct buf *bp = bread(dev, IBLOCK(inum, sb));
    8020284a:	00034a17          	auipc	s4,0x34
    8020284e:	716a0a13          	add	s4,s4,1814 # 80236f60 <sb>
    80202852:	0049559b          	srlw	a1,s2,0x4
    80202856:	018a2783          	lw	a5,24(s4)
    8020285a:	9dbd                	addw	a1,a1,a5
    8020285c:	8556                	mv	a0,s5
    8020285e:	fffff097          	auipc	ra,0xfffff
    80202862:	6a6080e7          	jalr	1702(ra) # 80201f04 <bread>
    80202866:	84aa                	mv	s1,a0
        struct dinode *dip = (struct dinode*)bp->data + inum % IPB;
    80202868:	05850993          	add	s3,a0,88
    8020286c:	00f97793          	and	a5,s2,15
    80202870:	079a                	sll	a5,a5,0x6
    80202872:	99be                	add	s3,s3,a5
        if (dip->type == 0) {
    80202874:	00099783          	lh	a5,0(s3)
    80202878:	cf8d                	beqz	a5,802028b2 <ialloc+0x90>
        brelse(bp);
    8020287a:	fffff097          	auipc	ra,0xfffff
    8020287e:	7dc080e7          	jalr	2012(ra) # 80202056 <brelse>
    for (uint inum = 1; inum < sb.ninodes; inum++) {
    80202882:	2905                	addw	s2,s2,1
    80202884:	00ca2783          	lw	a5,12(s4)
    80202888:	fcf965e3          	bltu	s2,a5,80202852 <ialloc+0x30>
    panic("ialloc");
    8020288c:	00004517          	auipc	a0,0x4
    80202890:	0dc50513          	add	a0,a0,220 # 80206968 <syscalls+0x398>
    80202894:	ffffe097          	auipc	ra,0xffffe
    80202898:	b40080e7          	jalr	-1216(ra) # 802003d4 <panic>
    return 0;
    8020289c:	4501                	li	a0,0
}
    8020289e:	70e2                	ld	ra,56(sp)
    802028a0:	7442                	ld	s0,48(sp)
    802028a2:	74a2                	ld	s1,40(sp)
    802028a4:	7902                	ld	s2,32(sp)
    802028a6:	69e2                	ld	s3,24(sp)
    802028a8:	6a42                	ld	s4,16(sp)
    802028aa:	6aa2                	ld	s5,8(sp)
    802028ac:	6b02                	ld	s6,0(sp)
    802028ae:	6121                	add	sp,sp,64
    802028b0:	8082                	ret
            memset(dip, 0, sizeof(*dip));
    802028b2:	04000613          	li	a2,64
    802028b6:	4581                	li	a1,0
    802028b8:	854e                	mv	a0,s3
    802028ba:	ffffe097          	auipc	ra,0xffffe
    802028be:	0e8080e7          	jalr	232(ra) # 802009a2 <memset>
            dip->type = type;
    802028c2:	01699023          	sh	s6,0(s3)
            log_write(bp); // [恢复] 使用 log_write
    802028c6:	8526                	mv	a0,s1
    802028c8:	00001097          	auipc	ra,0x1
    802028cc:	e6a080e7          	jalr	-406(ra) # 80203732 <log_write>
            brelse(bp);
    802028d0:	8526                	mv	a0,s1
    802028d2:	fffff097          	auipc	ra,0xfffff
    802028d6:	784080e7          	jalr	1924(ra) # 80202056 <brelse>
            return iget(dev, inum);
    802028da:	85ca                	mv	a1,s2
    802028dc:	8556                	mv	a0,s5
    802028de:	00000097          	auipc	ra,0x0
    802028e2:	e86080e7          	jalr	-378(ra) # 80202764 <iget>
    802028e6:	bf65                	j	8020289e <ialloc+0x7c>

00000000802028e8 <idup>:
struct inode *idup(struct inode *ip) {
    802028e8:	1101                	add	sp,sp,-32
    802028ea:	ec06                	sd	ra,24(sp)
    802028ec:	e822                	sd	s0,16(sp)
    802028ee:	e426                	sd	s1,8(sp)
    802028f0:	1000                	add	s0,sp,32
    802028f2:	84aa                	mv	s1,a0
    acquire(&icache.lock);
    802028f4:	00034517          	auipc	a0,0x34
    802028f8:	68c50513          	add	a0,a0,1676 # 80236f80 <icache>
    802028fc:	ffffe097          	auipc	ra,0xffffe
    80202900:	f3e080e7          	jalr	-194(ra) # 8020083a <acquire>
    ip->ref++;
    80202904:	449c                	lw	a5,8(s1)
    80202906:	2785                	addw	a5,a5,1
    80202908:	c49c                	sw	a5,8(s1)
    release(&icache.lock);
    8020290a:	00034517          	auipc	a0,0x34
    8020290e:	67650513          	add	a0,a0,1654 # 80236f80 <icache>
    80202912:	ffffe097          	auipc	ra,0xffffe
    80202916:	01a080e7          	jalr	26(ra) # 8020092c <release>
}
    8020291a:	8526                	mv	a0,s1
    8020291c:	60e2                	ld	ra,24(sp)
    8020291e:	6442                	ld	s0,16(sp)
    80202920:	64a2                	ld	s1,8(sp)
    80202922:	6105                	add	sp,sp,32
    80202924:	8082                	ret

0000000080202926 <ilock>:
void ilock(struct inode *ip) {
    80202926:	1101                	add	sp,sp,-32
    80202928:	ec06                	sd	ra,24(sp)
    8020292a:	e822                	sd	s0,16(sp)
    8020292c:	e426                	sd	s1,8(sp)
    8020292e:	e04a                	sd	s2,0(sp)
    80202930:	1000                	add	s0,sp,32
    80202932:	84aa                	mv	s1,a0
    if (ip == 0 || ip->ref < 1)
    80202934:	c501                	beqz	a0,8020293c <ilock+0x16>
    80202936:	451c                	lw	a5,8(a0)
    80202938:	00f04a63          	bgtz	a5,8020294c <ilock+0x26>
        panic("ilock");
    8020293c:	00004517          	auipc	a0,0x4
    80202940:	ecc50513          	add	a0,a0,-308 # 80206808 <syscalls+0x238>
    80202944:	ffffe097          	auipc	ra,0xffffe
    80202948:	a90080e7          	jalr	-1392(ra) # 802003d4 <panic>
    acquiresleep(&ip->lock);
    8020294c:	01048513          	add	a0,s1,16
    80202950:	00001097          	auipc	ra,0x1
    80202954:	f0c080e7          	jalr	-244(ra) # 8020385c <acquiresleep>
    if (ip->valid == 0) {
    80202958:	40bc                	lw	a5,64(s1)
    8020295a:	c799                	beqz	a5,80202968 <ilock+0x42>
}
    8020295c:	60e2                	ld	ra,24(sp)
    8020295e:	6442                	ld	s0,16(sp)
    80202960:	64a2                	ld	s1,8(sp)
    80202962:	6902                	ld	s2,0(sp)
    80202964:	6105                	add	sp,sp,32
    80202966:	8082                	ret
        struct buf *bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80202968:	40dc                	lw	a5,4(s1)
    8020296a:	0047d79b          	srlw	a5,a5,0x4
    8020296e:	00034597          	auipc	a1,0x34
    80202972:	60a5a583          	lw	a1,1546(a1) # 80236f78 <sb+0x18>
    80202976:	9dbd                	addw	a1,a1,a5
    80202978:	4088                	lw	a0,0(s1)
    8020297a:	fffff097          	auipc	ra,0xfffff
    8020297e:	58a080e7          	jalr	1418(ra) # 80201f04 <bread>
    80202982:	892a                	mv	s2,a0
        struct dinode *dip = (struct dinode*)bp->data + ip->inum % IPB;
    80202984:	05850593          	add	a1,a0,88
    80202988:	40dc                	lw	a5,4(s1)
    8020298a:	8bbd                	and	a5,a5,15
    8020298c:	079a                	sll	a5,a5,0x6
    8020298e:	95be                	add	a1,a1,a5
        ip->type = dip->type;
    80202990:	00059783          	lh	a5,0(a1)
    80202994:	04f49223          	sh	a5,68(s1)
        ip->major = dip->major;
    80202998:	00259783          	lh	a5,2(a1)
    8020299c:	04f49323          	sh	a5,70(s1)
        ip->minor = dip->minor;
    802029a0:	00459783          	lh	a5,4(a1)
    802029a4:	04f49423          	sh	a5,72(s1)
        ip->nlink = dip->nlink;
    802029a8:	00659783          	lh	a5,6(a1)
    802029ac:	04f49523          	sh	a5,74(s1)
        ip->size = dip->size;
    802029b0:	459c                	lw	a5,8(a1)
    802029b2:	c4fc                	sw	a5,76(s1)
        memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    802029b4:	03400613          	li	a2,52
    802029b8:	05b1                	add	a1,a1,12
    802029ba:	05048513          	add	a0,s1,80
    802029be:	ffffe097          	auipc	ra,0xffffe
    802029c2:	006080e7          	jalr	6(ra) # 802009c4 <memmove>
        ip->valid = 1;
    802029c6:	4785                	li	a5,1
    802029c8:	c0bc                	sw	a5,64(s1)
        brelse(bp);
    802029ca:	854a                	mv	a0,s2
    802029cc:	fffff097          	auipc	ra,0xfffff
    802029d0:	68a080e7          	jalr	1674(ra) # 80202056 <brelse>
        if (ip->type == 0)
    802029d4:	04449783          	lh	a5,68(s1)
    802029d8:	f3d1                	bnez	a5,8020295c <ilock+0x36>
            panic("ilock: no type");
    802029da:	00004517          	auipc	a0,0x4
    802029de:	e3650513          	add	a0,a0,-458 # 80206810 <syscalls+0x240>
    802029e2:	ffffe097          	auipc	ra,0xffffe
    802029e6:	9f2080e7          	jalr	-1550(ra) # 802003d4 <panic>
}
    802029ea:	bf8d                	j	8020295c <ilock+0x36>

00000000802029ec <iunlock>:
void iunlock(struct inode *ip) {
    802029ec:	1101                	add	sp,sp,-32
    802029ee:	ec06                	sd	ra,24(sp)
    802029f0:	e822                	sd	s0,16(sp)
    802029f2:	e426                	sd	s1,8(sp)
    802029f4:	1000                	add	s0,sp,32
    802029f6:	84aa                	mv	s1,a0
    if (ip == 0 || !holdingsleep(&ip->lock))
    802029f8:	c519                	beqz	a0,80202a06 <iunlock+0x1a>
    802029fa:	0541                	add	a0,a0,16
    802029fc:	00001097          	auipc	ra,0x1
    80202a00:	ef8080e7          	jalr	-264(ra) # 802038f4 <holdingsleep>
    80202a04:	e909                	bnez	a0,80202a16 <iunlock+0x2a>
        panic("iunlock");
    80202a06:	00004517          	auipc	a0,0x4
    80202a0a:	e1a50513          	add	a0,a0,-486 # 80206820 <syscalls+0x250>
    80202a0e:	ffffe097          	auipc	ra,0xffffe
    80202a12:	9c6080e7          	jalr	-1594(ra) # 802003d4 <panic>
    releasesleep(&ip->lock);
    80202a16:	01048513          	add	a0,s1,16
    80202a1a:	00001097          	auipc	ra,0x1
    80202a1e:	e96080e7          	jalr	-362(ra) # 802038b0 <releasesleep>
}
    80202a22:	60e2                	ld	ra,24(sp)
    80202a24:	6442                	ld	s0,16(sp)
    80202a26:	64a2                	ld	s1,8(sp)
    80202a28:	6105                	add	sp,sp,32
    80202a2a:	8082                	ret

0000000080202a2c <iupdate>:
void iupdate(struct inode *ip) {
    80202a2c:	1101                	add	sp,sp,-32
    80202a2e:	ec06                	sd	ra,24(sp)
    80202a30:	e822                	sd	s0,16(sp)
    80202a32:	e426                	sd	s1,8(sp)
    80202a34:	e04a                	sd	s2,0(sp)
    80202a36:	1000                	add	s0,sp,32
    80202a38:	84aa                	mv	s1,a0
    struct buf *bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80202a3a:	415c                	lw	a5,4(a0)
    80202a3c:	0047d79b          	srlw	a5,a5,0x4
    80202a40:	00034597          	auipc	a1,0x34
    80202a44:	5385a583          	lw	a1,1336(a1) # 80236f78 <sb+0x18>
    80202a48:	9dbd                	addw	a1,a1,a5
    80202a4a:	4108                	lw	a0,0(a0)
    80202a4c:	fffff097          	auipc	ra,0xfffff
    80202a50:	4b8080e7          	jalr	1208(ra) # 80201f04 <bread>
    80202a54:	892a                	mv	s2,a0
    struct dinode *dip = (struct dinode*)bp->data + ip->inum % IPB;
    80202a56:	05850793          	add	a5,a0,88
    80202a5a:	40d8                	lw	a4,4(s1)
    80202a5c:	8b3d                	and	a4,a4,15
    80202a5e:	071a                	sll	a4,a4,0x6
    80202a60:	97ba                	add	a5,a5,a4
    dip->type = ip->type;
    80202a62:	04449703          	lh	a4,68(s1)
    80202a66:	00e79023          	sh	a4,0(a5)
    dip->major = ip->major;
    80202a6a:	04649703          	lh	a4,70(s1)
    80202a6e:	00e79123          	sh	a4,2(a5)
    dip->minor = ip->minor;
    80202a72:	04849703          	lh	a4,72(s1)
    80202a76:	00e79223          	sh	a4,4(a5)
    dip->nlink = ip->nlink;
    80202a7a:	04a49703          	lh	a4,74(s1)
    80202a7e:	00e79323          	sh	a4,6(a5)
    dip->size = ip->size;
    80202a82:	44f8                	lw	a4,76(s1)
    80202a84:	c798                	sw	a4,8(a5)
    memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80202a86:	03400613          	li	a2,52
    80202a8a:	05048593          	add	a1,s1,80
    80202a8e:	00c78513          	add	a0,a5,12
    80202a92:	ffffe097          	auipc	ra,0xffffe
    80202a96:	f32080e7          	jalr	-206(ra) # 802009c4 <memmove>
    log_write(bp); // [恢复] 使用 log_write
    80202a9a:	854a                	mv	a0,s2
    80202a9c:	00001097          	auipc	ra,0x1
    80202aa0:	c96080e7          	jalr	-874(ra) # 80203732 <log_write>
    brelse(bp);
    80202aa4:	854a                	mv	a0,s2
    80202aa6:	fffff097          	auipc	ra,0xfffff
    80202aaa:	5b0080e7          	jalr	1456(ra) # 80202056 <brelse>
}
    80202aae:	60e2                	ld	ra,24(sp)
    80202ab0:	6442                	ld	s0,16(sp)
    80202ab2:	64a2                	ld	s1,8(sp)
    80202ab4:	6902                	ld	s2,0(sp)
    80202ab6:	6105                	add	sp,sp,32
    80202ab8:	8082                	ret

0000000080202aba <itrunc>:
void itrunc(struct inode *ip) {
    80202aba:	7179                	add	sp,sp,-48
    80202abc:	f406                	sd	ra,40(sp)
    80202abe:	f022                	sd	s0,32(sp)
    80202ac0:	ec26                	sd	s1,24(sp)
    80202ac2:	e84a                	sd	s2,16(sp)
    80202ac4:	e44e                	sd	s3,8(sp)
    80202ac6:	e052                	sd	s4,0(sp)
    80202ac8:	1800                	add	s0,sp,48
    80202aca:	89aa                	mv	s3,a0
    for (int i = 0; i < NDIRECT; i++) {
    80202acc:	05050493          	add	s1,a0,80
    80202ad0:	08050913          	add	s2,a0,128
    80202ad4:	a021                	j	80202adc <itrunc+0x22>
    80202ad6:	0491                	add	s1,s1,4
    80202ad8:	01248d63          	beq	s1,s2,80202af2 <itrunc+0x38>
        if (ip->addrs[i]) {
    80202adc:	408c                	lw	a1,0(s1)
    80202ade:	dde5                	beqz	a1,80202ad6 <itrunc+0x1c>
            bfree(ip->dev, ip->addrs[i]);
    80202ae0:	0009a503          	lw	a0,0(s3)
    80202ae4:	fffff097          	auipc	ra,0xfffff
    80202ae8:	750080e7          	jalr	1872(ra) # 80202234 <bfree>
            ip->addrs[i] = 0;
    80202aec:	0004a023          	sw	zero,0(s1)
    80202af0:	b7dd                	j	80202ad6 <itrunc+0x1c>
    if (ip->addrs[NDIRECT]) {
    80202af2:	0809a583          	lw	a1,128(s3)
    80202af6:	e185                	bnez	a1,80202b16 <itrunc+0x5c>
    ip->size = 0;
    80202af8:	0409a623          	sw	zero,76(s3)
    iupdate(ip);
    80202afc:	854e                	mv	a0,s3
    80202afe:	00000097          	auipc	ra,0x0
    80202b02:	f2e080e7          	jalr	-210(ra) # 80202a2c <iupdate>
}
    80202b06:	70a2                	ld	ra,40(sp)
    80202b08:	7402                	ld	s0,32(sp)
    80202b0a:	64e2                	ld	s1,24(sp)
    80202b0c:	6942                	ld	s2,16(sp)
    80202b0e:	69a2                	ld	s3,8(sp)
    80202b10:	6a02                	ld	s4,0(sp)
    80202b12:	6145                	add	sp,sp,48
    80202b14:	8082                	ret
        struct buf *bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80202b16:	0009a503          	lw	a0,0(s3)
    80202b1a:	fffff097          	auipc	ra,0xfffff
    80202b1e:	3ea080e7          	jalr	1002(ra) # 80201f04 <bread>
    80202b22:	8a2a                	mv	s4,a0
        for (int j = 0; j < NINDIRECT; j++) {
    80202b24:	05850493          	add	s1,a0,88
    80202b28:	45850913          	add	s2,a0,1112
    80202b2c:	a021                	j	80202b34 <itrunc+0x7a>
    80202b2e:	0491                	add	s1,s1,4
    80202b30:	01248b63          	beq	s1,s2,80202b46 <itrunc+0x8c>
            if (a[j])
    80202b34:	408c                	lw	a1,0(s1)
    80202b36:	dde5                	beqz	a1,80202b2e <itrunc+0x74>
                bfree(ip->dev, a[j]);
    80202b38:	0009a503          	lw	a0,0(s3)
    80202b3c:	fffff097          	auipc	ra,0xfffff
    80202b40:	6f8080e7          	jalr	1784(ra) # 80202234 <bfree>
    80202b44:	b7ed                	j	80202b2e <itrunc+0x74>
        brelse(bp);
    80202b46:	8552                	mv	a0,s4
    80202b48:	fffff097          	auipc	ra,0xfffff
    80202b4c:	50e080e7          	jalr	1294(ra) # 80202056 <brelse>
        bfree(ip->dev, ip->addrs[NDIRECT]);
    80202b50:	0809a583          	lw	a1,128(s3)
    80202b54:	0009a503          	lw	a0,0(s3)
    80202b58:	fffff097          	auipc	ra,0xfffff
    80202b5c:	6dc080e7          	jalr	1756(ra) # 80202234 <bfree>
        ip->addrs[NDIRECT] = 0;
    80202b60:	0809a023          	sw	zero,128(s3)
    80202b64:	bf51                	j	80202af8 <itrunc+0x3e>

0000000080202b66 <iput>:
void iput(struct inode *ip) {
    80202b66:	1101                	add	sp,sp,-32
    80202b68:	ec06                	sd	ra,24(sp)
    80202b6a:	e822                	sd	s0,16(sp)
    80202b6c:	e426                	sd	s1,8(sp)
    80202b6e:	e04a                	sd	s2,0(sp)
    80202b70:	1000                	add	s0,sp,32
    80202b72:	84aa                	mv	s1,a0
    acquiresleep(&ip->lock);
    80202b74:	01050913          	add	s2,a0,16
    80202b78:	854a                	mv	a0,s2
    80202b7a:	00001097          	auipc	ra,0x1
    80202b7e:	ce2080e7          	jalr	-798(ra) # 8020385c <acquiresleep>
    if (ip->valid && ip->nlink == 0 && ip->ref == 1) {
    80202b82:	40bc                	lw	a5,64(s1)
    80202b84:	cb81                	beqz	a5,80202b94 <iput+0x2e>
    80202b86:	04a49783          	lh	a5,74(s1)
    80202b8a:	e789                	bnez	a5,80202b94 <iput+0x2e>
    80202b8c:	4498                	lw	a4,8(s1)
    80202b8e:	4785                	li	a5,1
    80202b90:	04f70063          	beq	a4,a5,80202bd0 <iput+0x6a>
    releasesleep(&ip->lock);
    80202b94:	854a                	mv	a0,s2
    80202b96:	00001097          	auipc	ra,0x1
    80202b9a:	d1a080e7          	jalr	-742(ra) # 802038b0 <releasesleep>
    acquire(&icache.lock);
    80202b9e:	00034517          	auipc	a0,0x34
    80202ba2:	3e250513          	add	a0,a0,994 # 80236f80 <icache>
    80202ba6:	ffffe097          	auipc	ra,0xffffe
    80202baa:	c94080e7          	jalr	-876(ra) # 8020083a <acquire>
    ip->ref--;
    80202bae:	449c                	lw	a5,8(s1)
    80202bb0:	37fd                	addw	a5,a5,-1
    80202bb2:	c49c                	sw	a5,8(s1)
    release(&icache.lock);
    80202bb4:	00034517          	auipc	a0,0x34
    80202bb8:	3cc50513          	add	a0,a0,972 # 80236f80 <icache>
    80202bbc:	ffffe097          	auipc	ra,0xffffe
    80202bc0:	d70080e7          	jalr	-656(ra) # 8020092c <release>
}
    80202bc4:	60e2                	ld	ra,24(sp)
    80202bc6:	6442                	ld	s0,16(sp)
    80202bc8:	64a2                	ld	s1,8(sp)
    80202bca:	6902                	ld	s2,0(sp)
    80202bcc:	6105                	add	sp,sp,32
    80202bce:	8082                	ret
        itrunc(ip);
    80202bd0:	8526                	mv	a0,s1
    80202bd2:	00000097          	auipc	ra,0x0
    80202bd6:	ee8080e7          	jalr	-280(ra) # 80202aba <itrunc>
        ip->type = 0;
    80202bda:	04049223          	sh	zero,68(s1)
        iupdate(ip);
    80202bde:	8526                	mv	a0,s1
    80202be0:	00000097          	auipc	ra,0x0
    80202be4:	e4c080e7          	jalr	-436(ra) # 80202a2c <iupdate>
        ip->valid = 0;
    80202be8:	0404a023          	sw	zero,64(s1)
    80202bec:	b765                	j	80202b94 <iput+0x2e>

0000000080202bee <iunlockput>:
void iunlockput(struct inode *ip) {
    80202bee:	1101                	add	sp,sp,-32
    80202bf0:	ec06                	sd	ra,24(sp)
    80202bf2:	e822                	sd	s0,16(sp)
    80202bf4:	e426                	sd	s1,8(sp)
    80202bf6:	1000                	add	s0,sp,32
    80202bf8:	84aa                	mv	s1,a0
    iunlock(ip);
    80202bfa:	00000097          	auipc	ra,0x0
    80202bfe:	df2080e7          	jalr	-526(ra) # 802029ec <iunlock>
    iput(ip);
    80202c02:	8526                	mv	a0,s1
    80202c04:	00000097          	auipc	ra,0x0
    80202c08:	f62080e7          	jalr	-158(ra) # 80202b66 <iput>
}
    80202c0c:	60e2                	ld	ra,24(sp)
    80202c0e:	6442                	ld	s0,16(sp)
    80202c10:	64a2                	ld	s1,8(sp)
    80202c12:	6105                	add	sp,sp,32
    80202c14:	8082                	ret

0000000080202c16 <stati>:
int stati(struct inode *ip, struct stat *st) {
    80202c16:	1141                	add	sp,sp,-16
    80202c18:	e422                	sd	s0,8(sp)
    80202c1a:	0800                	add	s0,sp,16
    st->dev = ip->dev;
    80202c1c:	411c                	lw	a5,0(a0)
    80202c1e:	c1dc                	sw	a5,4(a1)
    st->ino = ip->inum;
    80202c20:	415c                	lw	a5,4(a0)
    80202c22:	c59c                	sw	a5,8(a1)
    st->type = ip->type;
    80202c24:	04451783          	lh	a5,68(a0)
    80202c28:	00f59023          	sh	a5,0(a1)
    st->nlink = ip->nlink;
    80202c2c:	04a51783          	lh	a5,74(a0)
    80202c30:	00f59623          	sh	a5,12(a1)
    st->size = ip->size;
    80202c34:	04c56783          	lwu	a5,76(a0)
    80202c38:	e99c                	sd	a5,16(a1)
}
    80202c3a:	4501                	li	a0,0
    80202c3c:	6422                	ld	s0,8(sp)
    80202c3e:	0141                	add	sp,sp,16
    80202c40:	8082                	ret

0000000080202c42 <readi>:
int readi(struct inode *ip, int user, uint64 dst, uint off, uint n) {
    80202c42:	715d                	add	sp,sp,-80
    80202c44:	e486                	sd	ra,72(sp)
    80202c46:	e0a2                	sd	s0,64(sp)
    80202c48:	fc26                	sd	s1,56(sp)
    80202c4a:	f84a                	sd	s2,48(sp)
    80202c4c:	f44e                	sd	s3,40(sp)
    80202c4e:	f052                	sd	s4,32(sp)
    80202c50:	ec56                	sd	s5,24(sp)
    80202c52:	e85a                	sd	s6,16(sp)
    80202c54:	e45e                	sd	s7,8(sp)
    80202c56:	e062                	sd	s8,0(sp)
    80202c58:	0880                	add	s0,sp,80
    80202c5a:	8baa                	mv	s7,a0
    80202c5c:	8ab2                	mv	s5,a2
    80202c5e:	8936                	mv	s2,a3
    80202c60:	8b3a                	mv	s6,a4
    if (user)
    80202c62:	e585                	bnez	a1,80202c8a <readi+0x48>
    if (off > ip->size || off + n < off)
    80202c64:	04cba783          	lw	a5,76(s7)
        return 0;
    80202c68:	4501                	li	a0,0
    if (off > ip->size || off + n < off)
    80202c6a:	0b27e163          	bltu	a5,s2,80202d0c <readi+0xca>
    80202c6e:	0169073b          	addw	a4,s2,s6
    80202c72:	09276d63          	bltu	a4,s2,80202d0c <readi+0xca>
    if (off + n > ip->size)
    80202c76:	00e7f463          	bgeu	a5,a4,80202c7e <readi+0x3c>
        n = ip->size - off;
    80202c7a:	41278b3b          	subw	s6,a5,s2
    for (tot = 0; tot < n; tot += m, off += m, dst += m) {
    80202c7e:	080b0563          	beqz	s6,80202d08 <readi+0xc6>
    80202c82:	4a01                	li	s4,0
        m = MIN(n - tot, BSIZE - off % BSIZE);
    80202c84:	40000c13          	li	s8,1024
    80202c88:	a091                	j	80202ccc <readi+0x8a>
        panic("readi user");
    80202c8a:	00004517          	auipc	a0,0x4
    80202c8e:	b9e50513          	add	a0,a0,-1122 # 80206828 <syscalls+0x258>
    80202c92:	ffffd097          	auipc	ra,0xffffd
    80202c96:	742080e7          	jalr	1858(ra) # 802003d4 <panic>
    80202c9a:	b7e9                	j	80202c64 <readi+0x22>
        memmove((void*)dst, bp->data + off % BSIZE, m);
    80202c9c:	05898593          	add	a1,s3,88
    80202ca0:	0004861b          	sext.w	a2,s1
    80202ca4:	95ba                	add	a1,a1,a4
    80202ca6:	8556                	mv	a0,s5
    80202ca8:	ffffe097          	auipc	ra,0xffffe
    80202cac:	d1c080e7          	jalr	-740(ra) # 802009c4 <memmove>
        brelse(bp);
    80202cb0:	854e                	mv	a0,s3
    80202cb2:	fffff097          	auipc	ra,0xfffff
    80202cb6:	3a4080e7          	jalr	932(ra) # 80202056 <brelse>
    for (tot = 0; tot < n; tot += m, off += m, dst += m) {
    80202cba:	01448a3b          	addw	s4,s1,s4
    80202cbe:	0124893b          	addw	s2,s1,s2
    80202cc2:	1482                	sll	s1,s1,0x20
    80202cc4:	9081                	srl	s1,s1,0x20
    80202cc6:	9aa6                	add	s5,s5,s1
    80202cc8:	056a7063          	bgeu	s4,s6,80202d08 <readi+0xc6>
        uint addr = bmap(ip, off / BSIZE);
    80202ccc:	00a9559b          	srlw	a1,s2,0xa
    80202cd0:	855e                	mv	a0,s7
    80202cd2:	fffff097          	auipc	ra,0xfffff
    80202cd6:	732080e7          	jalr	1842(ra) # 80202404 <bmap>
        bp = bread(ip->dev, addr);
    80202cda:	0005059b          	sext.w	a1,a0
    80202cde:	000ba503          	lw	a0,0(s7)
    80202ce2:	fffff097          	auipc	ra,0xfffff
    80202ce6:	222080e7          	jalr	546(ra) # 80201f04 <bread>
    80202cea:	89aa                	mv	s3,a0
        m = MIN(n - tot, BSIZE - off % BSIZE);
    80202cec:	3ff97713          	and	a4,s2,1023
    80202cf0:	40ec07bb          	subw	a5,s8,a4
    80202cf4:	414b06bb          	subw	a3,s6,s4
    80202cf8:	84be                	mv	s1,a5
    80202cfa:	2781                	sext.w	a5,a5
    80202cfc:	0006861b          	sext.w	a2,a3
    80202d00:	f8f67ee3          	bgeu	a2,a5,80202c9c <readi+0x5a>
    80202d04:	84b6                	mv	s1,a3
    80202d06:	bf59                	j	80202c9c <readi+0x5a>
    return n;
    80202d08:	000b051b          	sext.w	a0,s6
}
    80202d0c:	60a6                	ld	ra,72(sp)
    80202d0e:	6406                	ld	s0,64(sp)
    80202d10:	74e2                	ld	s1,56(sp)
    80202d12:	7942                	ld	s2,48(sp)
    80202d14:	79a2                	ld	s3,40(sp)
    80202d16:	7a02                	ld	s4,32(sp)
    80202d18:	6ae2                	ld	s5,24(sp)
    80202d1a:	6b42                	ld	s6,16(sp)
    80202d1c:	6ba2                	ld	s7,8(sp)
    80202d1e:	6c02                	ld	s8,0(sp)
    80202d20:	6161                	add	sp,sp,80
    80202d22:	8082                	ret

0000000080202d24 <writei>:
int writei(struct inode *ip, int user, uint64 src, uint off, uint n) {
    80202d24:	7159                	add	sp,sp,-112
    80202d26:	f486                	sd	ra,104(sp)
    80202d28:	f0a2                	sd	s0,96(sp)
    80202d2a:	eca6                	sd	s1,88(sp)
    80202d2c:	e8ca                	sd	s2,80(sp)
    80202d2e:	e4ce                	sd	s3,72(sp)
    80202d30:	e0d2                	sd	s4,64(sp)
    80202d32:	fc56                	sd	s5,56(sp)
    80202d34:	f85a                	sd	s6,48(sp)
    80202d36:	f45e                	sd	s7,40(sp)
    80202d38:	f062                	sd	s8,32(sp)
    80202d3a:	ec66                	sd	s9,24(sp)
    80202d3c:	e86a                	sd	s10,16(sp)
    80202d3e:	e46e                	sd	s11,8(sp)
    80202d40:	1880                	add	s0,sp,112
    80202d42:	8aaa                	mv	s5,a0
    80202d44:	8bb2                	mv	s7,a2
    80202d46:	8b36                	mv	s6,a3
    80202d48:	8a3a                	mv	s4,a4
    if (user)
    80202d4a:	e58d                	bnez	a1,80202d74 <writei+0x50>
    if (off > ip->size || off + n < off)
    80202d4c:	04caa783          	lw	a5,76(s5)
    80202d50:	0f67e263          	bltu	a5,s6,80202e34 <writei+0x110>
    80202d54:	014b0d3b          	addw	s10,s6,s4
    80202d58:	000d0c9b          	sext.w	s9,s10
    80202d5c:	0d6cee63          	bltu	s9,s6,80202e38 <writei+0x114>
    if (off + n > MAXFILE * BSIZE)
    80202d60:	000437b7          	lui	a5,0x43
    80202d64:	0d97ec63          	bltu	a5,s9,80202e3c <writei+0x118>
    while (tot < n) {
    80202d68:	0a0a0063          	beqz	s4,80202e08 <writei+0xe4>
    uint tot = 0;
    80202d6c:	4481                	li	s1,0
        uint m = MIN(n - tot, BSIZE - (off + tot) % BSIZE);
    80202d6e:	40000c13          	li	s8,1024
    80202d72:	a0a9                	j	80202dbc <writei+0x98>
        panic("writei user");
    80202d74:	00004517          	auipc	a0,0x4
    80202d78:	ac450513          	add	a0,a0,-1340 # 80206838 <syscalls+0x268>
    80202d7c:	ffffd097          	auipc	ra,0xffffd
    80202d80:	658080e7          	jalr	1624(ra) # 802003d4 <panic>
    80202d84:	b7e1                	j	80202d4c <writei+0x28>
        memmove(bp->data + (off + tot) % BSIZE, (void*)(src + tot), m);
    80202d86:	02049593          	sll	a1,s1,0x20
    80202d8a:	9181                	srl	a1,a1,0x20
    80202d8c:	05890513          	add	a0,s2,88
    80202d90:	000d861b          	sext.w	a2,s11
    80202d94:	95de                	add	a1,a1,s7
    80202d96:	954e                	add	a0,a0,s3
    80202d98:	ffffe097          	auipc	ra,0xffffe
    80202d9c:	c2c080e7          	jalr	-980(ra) # 802009c4 <memmove>
        log_write(bp); // [恢复] 使用 log_write
    80202da0:	854a                	mv	a0,s2
    80202da2:	00001097          	auipc	ra,0x1
    80202da6:	990080e7          	jalr	-1648(ra) # 80203732 <log_write>
        brelse(bp);
    80202daa:	854a                	mv	a0,s2
    80202dac:	fffff097          	auipc	ra,0xfffff
    80202db0:	2aa080e7          	jalr	682(ra) # 80202056 <brelse>
        tot += m;
    80202db4:	009d84bb          	addw	s1,s11,s1
    while (tot < n) {
    80202db8:	0544f263          	bgeu	s1,s4,80202dfc <writei+0xd8>
        uint addr = bmap(ip, (off + tot) / BSIZE);
    80202dbc:	009b09bb          	addw	s3,s6,s1
    80202dc0:	00a9d59b          	srlw	a1,s3,0xa
    80202dc4:	8556                	mv	a0,s5
    80202dc6:	fffff097          	auipc	ra,0xfffff
    80202dca:	63e080e7          	jalr	1598(ra) # 80202404 <bmap>
        struct buf *bp = bread(ip->dev, addr);
    80202dce:	0005059b          	sext.w	a1,a0
    80202dd2:	000aa503          	lw	a0,0(s5)
    80202dd6:	fffff097          	auipc	ra,0xfffff
    80202dda:	12e080e7          	jalr	302(ra) # 80201f04 <bread>
    80202dde:	892a                	mv	s2,a0
        uint m = MIN(n - tot, BSIZE - (off + tot) % BSIZE);
    80202de0:	3ff9f993          	and	s3,s3,1023
    80202de4:	413c07bb          	subw	a5,s8,s3
    80202de8:	409a073b          	subw	a4,s4,s1
    80202dec:	8dbe                	mv	s11,a5
    80202dee:	2781                	sext.w	a5,a5
    80202df0:	0007069b          	sext.w	a3,a4
    80202df4:	f8f6f9e3          	bgeu	a3,a5,80202d86 <writei+0x62>
    80202df8:	8dba                	mv	s11,a4
    80202dfa:	b771                	j	80202d86 <writei+0x62>
    if (off + n > ip->size)
    80202dfc:	04caa783          	lw	a5,76(s5)
    80202e00:	0197f463          	bgeu	a5,s9,80202e08 <writei+0xe4>
        ip->size = off + n;
    80202e04:	05aaa623          	sw	s10,76(s5)
    iupdate(ip);
    80202e08:	8556                	mv	a0,s5
    80202e0a:	00000097          	auipc	ra,0x0
    80202e0e:	c22080e7          	jalr	-990(ra) # 80202a2c <iupdate>
    return n;
    80202e12:	000a051b          	sext.w	a0,s4
}
    80202e16:	70a6                	ld	ra,104(sp)
    80202e18:	7406                	ld	s0,96(sp)
    80202e1a:	64e6                	ld	s1,88(sp)
    80202e1c:	6946                	ld	s2,80(sp)
    80202e1e:	69a6                	ld	s3,72(sp)
    80202e20:	6a06                	ld	s4,64(sp)
    80202e22:	7ae2                	ld	s5,56(sp)
    80202e24:	7b42                	ld	s6,48(sp)
    80202e26:	7ba2                	ld	s7,40(sp)
    80202e28:	7c02                	ld	s8,32(sp)
    80202e2a:	6ce2                	ld	s9,24(sp)
    80202e2c:	6d42                	ld	s10,16(sp)
    80202e2e:	6da2                	ld	s11,8(sp)
    80202e30:	6165                	add	sp,sp,112
    80202e32:	8082                	ret
        return -1;
    80202e34:	557d                	li	a0,-1
    80202e36:	b7c5                	j	80202e16 <writei+0xf2>
    80202e38:	557d                	li	a0,-1
    80202e3a:	bff1                	j	80202e16 <writei+0xf2>
        return -1;
    80202e3c:	557d                	li	a0,-1
    80202e3e:	bfe1                	j	80202e16 <writei+0xf2>

0000000080202e40 <namecmp>:
int namecmp(const char *s, const char *t) {
    80202e40:	1141                	add	sp,sp,-16
    80202e42:	e406                	sd	ra,8(sp)
    80202e44:	e022                	sd	s0,0(sp)
    80202e46:	0800                	add	s0,sp,16
    return strncmp(s, t, DIRSIZ);
    80202e48:	4639                	li	a2,14
    80202e4a:	ffffe097          	auipc	ra,0xffffe
    80202e4e:	bf6080e7          	jalr	-1034(ra) # 80200a40 <strncmp>
}
    80202e52:	60a2                	ld	ra,8(sp)
    80202e54:	6402                	ld	s0,0(sp)
    80202e56:	0141                	add	sp,sp,16
    80202e58:	8082                	ret

0000000080202e5a <dirlookup>:
struct inode *dirlookup(struct inode *dp, char *name, uint *poff) {
    80202e5a:	715d                	add	sp,sp,-80
    80202e5c:	e486                	sd	ra,72(sp)
    80202e5e:	e0a2                	sd	s0,64(sp)
    80202e60:	fc26                	sd	s1,56(sp)
    80202e62:	f84a                	sd	s2,48(sp)
    80202e64:	f44e                	sd	s3,40(sp)
    80202e66:	f052                	sd	s4,32(sp)
    80202e68:	ec56                	sd	s5,24(sp)
    80202e6a:	0880                	add	s0,sp,80
    80202e6c:	892a                	mv	s2,a0
    80202e6e:	89ae                	mv	s3,a1
    80202e70:	8ab2                	mv	s5,a2
    if (dp->type != T_DIR)
    80202e72:	04451703          	lh	a4,68(a0)
    80202e76:	4785                	li	a5,1
    80202e78:	00f71b63          	bne	a4,a5,80202e8e <dirlookup+0x34>
    for (uint off = 0; off < dp->size; off += sizeof(de)) {
    80202e7c:	04c92783          	lw	a5,76(s2)
    80202e80:	cbd1                	beqz	a5,80202f14 <dirlookup+0xba>
    80202e82:	4481                	li	s1,0
            panic("dirlookup read");
    80202e84:	00004a17          	auipc	s4,0x4
    80202e88:	9d4a0a13          	add	s4,s4,-1580 # 80206858 <syscalls+0x288>
    80202e8c:	a02d                	j	80202eb6 <dirlookup+0x5c>
        panic("dirlookup");
    80202e8e:	00004517          	auipc	a0,0x4
    80202e92:	9ba50513          	add	a0,a0,-1606 # 80206848 <syscalls+0x278>
    80202e96:	ffffd097          	auipc	ra,0xffffd
    80202e9a:	53e080e7          	jalr	1342(ra) # 802003d4 <panic>
    80202e9e:	bff9                	j	80202e7c <dirlookup+0x22>
            panic("dirlookup read");
    80202ea0:	8552                	mv	a0,s4
    80202ea2:	ffffd097          	auipc	ra,0xffffd
    80202ea6:	532080e7          	jalr	1330(ra) # 802003d4 <panic>
    80202eaa:	a01d                	j	80202ed0 <dirlookup+0x76>
    for (uint off = 0; off < dp->size; off += sizeof(de)) {
    80202eac:	24c1                	addw	s1,s1,16
    80202eae:	04c92783          	lw	a5,76(s2)
    80202eb2:	04f4f763          	bgeu	s1,a5,80202f00 <dirlookup+0xa6>
        if (readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80202eb6:	4741                	li	a4,16
    80202eb8:	86a6                	mv	a3,s1
    80202eba:	fb040613          	add	a2,s0,-80
    80202ebe:	4581                	li	a1,0
    80202ec0:	854a                	mv	a0,s2
    80202ec2:	00000097          	auipc	ra,0x0
    80202ec6:	d80080e7          	jalr	-640(ra) # 80202c42 <readi>
    80202eca:	47c1                	li	a5,16
    80202ecc:	fcf51ae3          	bne	a0,a5,80202ea0 <dirlookup+0x46>
        if (de.inum == 0)
    80202ed0:	fb045783          	lhu	a5,-80(s0)
    80202ed4:	dfe1                	beqz	a5,80202eac <dirlookup+0x52>
        if (namecmp(name, de.name) == 0) {
    80202ed6:	fb240593          	add	a1,s0,-78
    80202eda:	854e                	mv	a0,s3
    80202edc:	00000097          	auipc	ra,0x0
    80202ee0:	f64080e7          	jalr	-156(ra) # 80202e40 <namecmp>
    80202ee4:	f561                	bnez	a0,80202eac <dirlookup+0x52>
            if (poff)
    80202ee6:	000a8463          	beqz	s5,80202eee <dirlookup+0x94>
                *poff = off;
    80202eea:	009aa023          	sw	s1,0(s5)
            return iget(dp->dev, de.inum);
    80202eee:	fb045583          	lhu	a1,-80(s0)
    80202ef2:	00092503          	lw	a0,0(s2)
    80202ef6:	00000097          	auipc	ra,0x0
    80202efa:	86e080e7          	jalr	-1938(ra) # 80202764 <iget>
    80202efe:	a011                	j	80202f02 <dirlookup+0xa8>
    return 0;
    80202f00:	4501                	li	a0,0
}
    80202f02:	60a6                	ld	ra,72(sp)
    80202f04:	6406                	ld	s0,64(sp)
    80202f06:	74e2                	ld	s1,56(sp)
    80202f08:	7942                	ld	s2,48(sp)
    80202f0a:	79a2                	ld	s3,40(sp)
    80202f0c:	7a02                	ld	s4,32(sp)
    80202f0e:	6ae2                	ld	s5,24(sp)
    80202f10:	6161                	add	sp,sp,80
    80202f12:	8082                	ret
    return 0;
    80202f14:	4501                	li	a0,0
    80202f16:	b7f5                	j	80202f02 <dirlookup+0xa8>

0000000080202f18 <dirlink>:
int dirlink(struct inode *dp, char *name, uint inum) {
    80202f18:	715d                	add	sp,sp,-80
    80202f1a:	e486                	sd	ra,72(sp)
    80202f1c:	e0a2                	sd	s0,64(sp)
    80202f1e:	fc26                	sd	s1,56(sp)
    80202f20:	f84a                	sd	s2,48(sp)
    80202f22:	f44e                	sd	s3,40(sp)
    80202f24:	f052                	sd	s4,32(sp)
    80202f26:	ec56                	sd	s5,24(sp)
    80202f28:	0880                	add	s0,sp,80
    80202f2a:	892a                	mv	s2,a0
    80202f2c:	8a2e                	mv	s4,a1
    80202f2e:	8ab2                	mv	s5,a2
    if (dirlookup(dp, name, 0) != 0)
    80202f30:	4601                	li	a2,0
    80202f32:	00000097          	auipc	ra,0x0
    80202f36:	f28080e7          	jalr	-216(ra) # 80202e5a <dirlookup>
    80202f3a:	e14d                	bnez	a0,80202fdc <dirlink+0xc4>
    for (off = 0; off < dp->size; off += sizeof(de)) {
    80202f3c:	04c92483          	lw	s1,76(s2)
    80202f40:	c0b1                	beqz	s1,80202f84 <dirlink+0x6c>
    80202f42:	4481                	li	s1,0
            panic("dirlink read");
    80202f44:	00004997          	auipc	s3,0x4
    80202f48:	92498993          	add	s3,s3,-1756 # 80206868 <syscalls+0x298>
    80202f4c:	a809                	j	80202f5e <dirlink+0x46>
        if (de.inum == 0)
    80202f4e:	fb045783          	lhu	a5,-80(s0)
    80202f52:	cb8d                	beqz	a5,80202f84 <dirlink+0x6c>
    for (off = 0; off < dp->size; off += sizeof(de)) {
    80202f54:	24c1                	addw	s1,s1,16
    80202f56:	04c92783          	lw	a5,76(s2)
    80202f5a:	02f4f563          	bgeu	s1,a5,80202f84 <dirlink+0x6c>
        if (readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80202f5e:	4741                	li	a4,16
    80202f60:	86a6                	mv	a3,s1
    80202f62:	fb040613          	add	a2,s0,-80
    80202f66:	4581                	li	a1,0
    80202f68:	854a                	mv	a0,s2
    80202f6a:	00000097          	auipc	ra,0x0
    80202f6e:	cd8080e7          	jalr	-808(ra) # 80202c42 <readi>
    80202f72:	47c1                	li	a5,16
    80202f74:	fcf50de3          	beq	a0,a5,80202f4e <dirlink+0x36>
            panic("dirlink read");
    80202f78:	854e                	mv	a0,s3
    80202f7a:	ffffd097          	auipc	ra,0xffffd
    80202f7e:	45a080e7          	jalr	1114(ra) # 802003d4 <panic>
    80202f82:	b7f1                	j	80202f4e <dirlink+0x36>
    de.inum = inum;
    80202f84:	fb541823          	sh	s5,-80(s0)
    safestrcpy(de.name, name, DIRSIZ);
    80202f88:	4639                	li	a2,14
    80202f8a:	85d2                	mv	a1,s4
    80202f8c:	fb240513          	add	a0,s0,-78
    80202f90:	ffffe097          	auipc	ra,0xffffe
    80202f94:	b5c080e7          	jalr	-1188(ra) # 80200aec <safestrcpy>
    if (writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80202f98:	4741                	li	a4,16
    80202f9a:	86a6                	mv	a3,s1
    80202f9c:	fb040613          	add	a2,s0,-80
    80202fa0:	4581                	li	a1,0
    80202fa2:	854a                	mv	a0,s2
    80202fa4:	00000097          	auipc	ra,0x0
    80202fa8:	d80080e7          	jalr	-640(ra) # 80202d24 <writei>
    80202fac:	872a                	mv	a4,a0
    80202fae:	47c1                	li	a5,16
    return 0;
    80202fb0:	4501                	li	a0,0
    if (writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80202fb2:	00f71b63          	bne	a4,a5,80202fc8 <dirlink+0xb0>
}
    80202fb6:	60a6                	ld	ra,72(sp)
    80202fb8:	6406                	ld	s0,64(sp)
    80202fba:	74e2                	ld	s1,56(sp)
    80202fbc:	7942                	ld	s2,48(sp)
    80202fbe:	79a2                	ld	s3,40(sp)
    80202fc0:	7a02                	ld	s4,32(sp)
    80202fc2:	6ae2                	ld	s5,24(sp)
    80202fc4:	6161                	add	sp,sp,80
    80202fc6:	8082                	ret
        panic("dirlink");
    80202fc8:	00004517          	auipc	a0,0x4
    80202fcc:	9c050513          	add	a0,a0,-1600 # 80206988 <syscalls+0x3b8>
    80202fd0:	ffffd097          	auipc	ra,0xffffd
    80202fd4:	404080e7          	jalr	1028(ra) # 802003d4 <panic>
    return 0;
    80202fd8:	4501                	li	a0,0
    80202fda:	bff1                	j	80202fb6 <dirlink+0x9e>
        return -1;
    80202fdc:	557d                	li	a0,-1
    80202fde:	bfe1                	j	80202fb6 <dirlink+0x9e>

0000000080202fe0 <namex>:
struct inode *namex(char *path, int nameiparent, char *name) {
    80202fe0:	711d                	add	sp,sp,-96
    80202fe2:	ec86                	sd	ra,88(sp)
    80202fe4:	e8a2                	sd	s0,80(sp)
    80202fe6:	e4a6                	sd	s1,72(sp)
    80202fe8:	e0ca                	sd	s2,64(sp)
    80202fea:	fc4e                	sd	s3,56(sp)
    80202fec:	f852                	sd	s4,48(sp)
    80202fee:	f456                	sd	s5,40(sp)
    80202ff0:	f05a                	sd	s6,32(sp)
    80202ff2:	ec5e                	sd	s7,24(sp)
    80202ff4:	e862                	sd	s8,16(sp)
    80202ff6:	e466                	sd	s9,8(sp)
    80202ff8:	1080                	add	s0,sp,96
    80202ffa:	84aa                	mv	s1,a0
    80202ffc:	8b2e                	mv	s6,a1
    80202ffe:	8ab2                	mv	s5,a2
    if (*path == '/')
    80203000:	00054703          	lbu	a4,0(a0)
    80203004:	02f00793          	li	a5,47
    80203008:	02f70263          	beq	a4,a5,8020302c <namex+0x4c>
        ip = idup(myproc()->cwd);
    8020300c:	ffffe097          	auipc	ra,0xffffe
    80203010:	39c080e7          	jalr	924(ra) # 802013a8 <myproc>
    80203014:	15853503          	ld	a0,344(a0)
    80203018:	00000097          	auipc	ra,0x0
    8020301c:	8d0080e7          	jalr	-1840(ra) # 802028e8 <idup>
    80203020:	8a2a                	mv	s4,a0
    while (*path == '/')
    80203022:	02f00913          	li	s2,47
    if (len >= DIRSIZ)
    80203026:	4c35                	li	s8,13
        if (ip->type != T_DIR) {
    80203028:	4b85                	li	s7,1
    8020302a:	a875                	j	802030e6 <namex+0x106>
        ip = iget(ROOTDEV, ROOTINO);
    8020302c:	4585                	li	a1,1
    8020302e:	4505                	li	a0,1
    80203030:	fffff097          	auipc	ra,0xfffff
    80203034:	734080e7          	jalr	1844(ra) # 80202764 <iget>
    80203038:	8a2a                	mv	s4,a0
    8020303a:	b7e5                	j	80203022 <namex+0x42>
            iunlockput(ip);
    8020303c:	8552                	mv	a0,s4
    8020303e:	00000097          	auipc	ra,0x0
    80203042:	bb0080e7          	jalr	-1104(ra) # 80202bee <iunlockput>
            return 0;
    80203046:	4a01                	li	s4,0
}
    80203048:	8552                	mv	a0,s4
    8020304a:	60e6                	ld	ra,88(sp)
    8020304c:	6446                	ld	s0,80(sp)
    8020304e:	64a6                	ld	s1,72(sp)
    80203050:	6906                	ld	s2,64(sp)
    80203052:	79e2                	ld	s3,56(sp)
    80203054:	7a42                	ld	s4,48(sp)
    80203056:	7aa2                	ld	s5,40(sp)
    80203058:	7b02                	ld	s6,32(sp)
    8020305a:	6be2                	ld	s7,24(sp)
    8020305c:	6c42                	ld	s8,16(sp)
    8020305e:	6ca2                	ld	s9,8(sp)
    80203060:	6125                	add	sp,sp,96
    80203062:	8082                	ret
            iunlock(ip);
    80203064:	8552                	mv	a0,s4
    80203066:	00000097          	auipc	ra,0x0
    8020306a:	986080e7          	jalr	-1658(ra) # 802029ec <iunlock>
            return ip;
    8020306e:	bfe9                	j	80203048 <namex+0x68>
            iunlockput(ip);
    80203070:	8552                	mv	a0,s4
    80203072:	00000097          	auipc	ra,0x0
    80203076:	b7c080e7          	jalr	-1156(ra) # 80202bee <iunlockput>
            return 0;
    8020307a:	8a4e                	mv	s4,s3
    8020307c:	b7f1                	j	80203048 <namex+0x68>
    int len = path - s;
    8020307e:	40998633          	sub	a2,s3,s1
    80203082:	00060c9b          	sext.w	s9,a2
    if (len >= DIRSIZ)
    80203086:	099c5863          	bge	s8,s9,80203116 <namex+0x136>
        memmove(name, s, DIRSIZ);
    8020308a:	4639                	li	a2,14
    8020308c:	85a6                	mv	a1,s1
    8020308e:	8556                	mv	a0,s5
    80203090:	ffffe097          	auipc	ra,0xffffe
    80203094:	934080e7          	jalr	-1740(ra) # 802009c4 <memmove>
    80203098:	84ce                	mv	s1,s3
    while (*path == '/')
    8020309a:	0004c783          	lbu	a5,0(s1)
    8020309e:	01279763          	bne	a5,s2,802030ac <namex+0xcc>
        path++;
    802030a2:	0485                	add	s1,s1,1
    while (*path == '/')
    802030a4:	0004c783          	lbu	a5,0(s1)
    802030a8:	ff278de3          	beq	a5,s2,802030a2 <namex+0xc2>
        ilock(ip);
    802030ac:	8552                	mv	a0,s4
    802030ae:	00000097          	auipc	ra,0x0
    802030b2:	878080e7          	jalr	-1928(ra) # 80202926 <ilock>
        if (ip->type != T_DIR) {
    802030b6:	044a1783          	lh	a5,68(s4)
    802030ba:	f97791e3          	bne	a5,s7,8020303c <namex+0x5c>
        if (nameiparent && *path == '\0') {
    802030be:	000b0563          	beqz	s6,802030c8 <namex+0xe8>
    802030c2:	0004c783          	lbu	a5,0(s1)
    802030c6:	dfd9                	beqz	a5,80203064 <namex+0x84>
        if ((next = dirlookup(ip, name, 0)) == 0) {
    802030c8:	4601                	li	a2,0
    802030ca:	85d6                	mv	a1,s5
    802030cc:	8552                	mv	a0,s4
    802030ce:	00000097          	auipc	ra,0x0
    802030d2:	d8c080e7          	jalr	-628(ra) # 80202e5a <dirlookup>
    802030d6:	89aa                	mv	s3,a0
    802030d8:	dd41                	beqz	a0,80203070 <namex+0x90>
        iunlockput(ip);
    802030da:	8552                	mv	a0,s4
    802030dc:	00000097          	auipc	ra,0x0
    802030e0:	b12080e7          	jalr	-1262(ra) # 80202bee <iunlockput>
        ip = next;
    802030e4:	8a4e                	mv	s4,s3
    while (*path == '/')
    802030e6:	0004c783          	lbu	a5,0(s1)
    802030ea:	01279763          	bne	a5,s2,802030f8 <namex+0x118>
        path++;
    802030ee:	0485                	add	s1,s1,1
    while (*path == '/')
    802030f0:	0004c783          	lbu	a5,0(s1)
    802030f4:	ff278de3          	beq	a5,s2,802030ee <namex+0x10e>
    if (*path == 0)
    802030f8:	cb9d                	beqz	a5,8020312e <namex+0x14e>
    while (*path != '/' && *path != 0)
    802030fa:	0004c783          	lbu	a5,0(s1)
    802030fe:	89a6                	mv	s3,s1
    int len = path - s;
    80203100:	4c81                	li	s9,0
    80203102:	4601                	li	a2,0
    while (*path != '/' && *path != 0)
    80203104:	01278963          	beq	a5,s2,80203116 <namex+0x136>
    80203108:	dbbd                	beqz	a5,8020307e <namex+0x9e>
        path++;
    8020310a:	0985                	add	s3,s3,1
    while (*path != '/' && *path != 0)
    8020310c:	0009c783          	lbu	a5,0(s3)
    80203110:	ff279ce3          	bne	a5,s2,80203108 <namex+0x128>
    80203114:	b7ad                	j	8020307e <namex+0x9e>
        memmove(name, s, len);
    80203116:	2601                	sext.w	a2,a2
    80203118:	85a6                	mv	a1,s1
    8020311a:	8556                	mv	a0,s5
    8020311c:	ffffe097          	auipc	ra,0xffffe
    80203120:	8a8080e7          	jalr	-1880(ra) # 802009c4 <memmove>
        name[len] = 0;
    80203124:	9cd6                	add	s9,s9,s5
    80203126:	000c8023          	sb	zero,0(s9)
    8020312a:	84ce                	mv	s1,s3
    8020312c:	b7bd                	j	8020309a <namex+0xba>
    if (nameiparent) {
    8020312e:	f00b0de3          	beqz	s6,80203048 <namex+0x68>
        iput(ip);
    80203132:	8552                	mv	a0,s4
    80203134:	00000097          	auipc	ra,0x0
    80203138:	a32080e7          	jalr	-1486(ra) # 80202b66 <iput>
        return 0;
    8020313c:	4a01                	li	s4,0
    8020313e:	b729                	j	80203048 <namex+0x68>

0000000080203140 <namei>:
struct inode *namei(char *path) {
    80203140:	1101                	add	sp,sp,-32
    80203142:	ec06                	sd	ra,24(sp)
    80203144:	e822                	sd	s0,16(sp)
    80203146:	1000                	add	s0,sp,32
    return namex(path, 0, name);
    80203148:	fe040613          	add	a2,s0,-32
    8020314c:	4581                	li	a1,0
    8020314e:	00000097          	auipc	ra,0x0
    80203152:	e92080e7          	jalr	-366(ra) # 80202fe0 <namex>
}
    80203156:	60e2                	ld	ra,24(sp)
    80203158:	6442                	ld	s0,16(sp)
    8020315a:	6105                	add	sp,sp,32
    8020315c:	8082                	ret

000000008020315e <nameiparent>:
struct inode *nameiparent(char *path, char *name) {
    8020315e:	1141                	add	sp,sp,-16
    80203160:	e406                	sd	ra,8(sp)
    80203162:	e022                	sd	s0,0(sp)
    80203164:	0800                	add	s0,sp,16
    80203166:	862e                	mv	a2,a1
    return namex(path, 1, name);
    80203168:	4585                	li	a1,1
    8020316a:	00000097          	auipc	ra,0x0
    8020316e:	e76080e7          	jalr	-394(ra) # 80202fe0 <namex>
}
    80203172:	60a2                	ld	ra,8(sp)
    80203174:	6402                	ld	s0,0(sp)
    80203176:	0141                	add	sp,sp,16
    80203178:	8082                	ret

000000008020317a <count_free_blocks>:
int count_free_blocks(void) {
    8020317a:	715d                	add	sp,sp,-80
    8020317c:	e486                	sd	ra,72(sp)
    8020317e:	e0a2                	sd	s0,64(sp)
    80203180:	fc26                	sd	s1,56(sp)
    80203182:	f84a                	sd	s2,48(sp)
    80203184:	f44e                	sd	s3,40(sp)
    80203186:	f052                	sd	s4,32(sp)
    80203188:	ec56                	sd	s5,24(sp)
    8020318a:	e85a                	sd	s6,16(sp)
    8020318c:	e45e                	sd	s7,8(sp)
    8020318e:	e062                	sd	s8,0(sp)
    80203190:	0880                	add	s0,sp,80
    return sb.bmapstart + ((sb.nblocks + BPB - 1) / BPB);
    80203192:	00034797          	auipc	a5,0x34
    80203196:	dce78793          	add	a5,a5,-562 # 80236f60 <sb>
    8020319a:	4798                	lw	a4,8(a5)
    8020319c:	6489                	lui	s1,0x2
    8020319e:	34fd                	addw	s1,s1,-1 # 1fff <_start-0x801fe001>
    802031a0:	9cb9                	addw	s1,s1,a4
    802031a2:	00d4d49b          	srlw	s1,s1,0xd
    802031a6:	4fd8                	lw	a4,28(a5)
    802031a8:	9cb9                	addw	s1,s1,a4
    for (uint b = 0; b < sb.size; b += BPB) {
    802031aa:	43dc                	lw	a5,4(a5)
    802031ac:	cbb5                	beqz	a5,80203220 <count_free_blocks+0xa6>
    802031ae:	4a81                	li	s5,0
    int free = 0;
    802031b0:	4981                	li	s3,0
        struct buf *bp = bread(ROOTDEV, BBLOCK(b, sb));
    802031b2:	00034b17          	auipc	s6,0x34
    802031b6:	daeb0b13          	add	s6,s6,-594 # 80236f60 <sb>
        for (uint bi = 0; bi < BPB && b + bi < sb.size; bi++) {
    802031ba:	4c01                	li	s8,0
            int m = 1 << (bi % 8);
    802031bc:	4a05                	li	s4,1
        for (uint bi = 0; bi < BPB && b + bi < sb.size; bi++) {
    802031be:	6909                	lui	s2,0x2
    for (uint b = 0; b < sb.size; b += BPB) {
    802031c0:	6b89                	lui	s7,0x2
    802031c2:	a081                	j	80203202 <count_free_blocks+0x88>
        for (uint bi = 0; bi < BPB && b + bi < sb.size; bi++) {
    802031c4:	2785                	addw	a5,a5,1
    802031c6:	2705                	addw	a4,a4,1
    802031c8:	03278363          	beq	a5,s2,802031ee <count_free_blocks+0x74>
    802031cc:	02b77163          	bgeu	a4,a1,802031ee <count_free_blocks+0x74>
            if (b + bi < start)
    802031d0:	fe976ae3          	bltu	a4,s1,802031c4 <count_free_blocks+0x4a>
            if ((bp->data[bi / 8] & m) == 0)
    802031d4:	0037d69b          	srlw	a3,a5,0x3
    802031d8:	96aa                	add	a3,a3,a0
            int m = 1 << (bi % 8);
    802031da:	0077f613          	and	a2,a5,7
    802031de:	00ca163b          	sllw	a2,s4,a2
            if ((bp->data[bi / 8] & m) == 0)
    802031e2:	0586c683          	lbu	a3,88(a3)
    802031e6:	8ef1                	and	a3,a3,a2
    802031e8:	fef1                	bnez	a3,802031c4 <count_free_blocks+0x4a>
                free++;
    802031ea:	2985                	addw	s3,s3,1
    802031ec:	bfe1                	j	802031c4 <count_free_blocks+0x4a>
        brelse(bp);
    802031ee:	fffff097          	auipc	ra,0xfffff
    802031f2:	e68080e7          	jalr	-408(ra) # 80202056 <brelse>
    for (uint b = 0; b < sb.size; b += BPB) {
    802031f6:	015b8abb          	addw	s5,s7,s5
    802031fa:	004b2783          	lw	a5,4(s6)
    802031fe:	02faf263          	bgeu	s5,a5,80203222 <count_free_blocks+0xa8>
        struct buf *bp = bread(ROOTDEV, BBLOCK(b, sb));
    80203202:	00dad59b          	srlw	a1,s5,0xd
    80203206:	01cb2783          	lw	a5,28(s6)
    8020320a:	9dbd                	addw	a1,a1,a5
    8020320c:	4505                	li	a0,1
    8020320e:	fffff097          	auipc	ra,0xfffff
    80203212:	cf6080e7          	jalr	-778(ra) # 80201f04 <bread>
        for (uint bi = 0; bi < BPB && b + bi < sb.size; bi++) {
    80203216:	004b2583          	lw	a1,4(s6)
    8020321a:	8756                	mv	a4,s5
    8020321c:	87e2                	mv	a5,s8
    8020321e:	b77d                	j	802031cc <count_free_blocks+0x52>
    int free = 0;
    80203220:	4981                	li	s3,0
}
    80203222:	854e                	mv	a0,s3
    80203224:	60a6                	ld	ra,72(sp)
    80203226:	6406                	ld	s0,64(sp)
    80203228:	74e2                	ld	s1,56(sp)
    8020322a:	7942                	ld	s2,48(sp)
    8020322c:	79a2                	ld	s3,40(sp)
    8020322e:	7a02                	ld	s4,32(sp)
    80203230:	6ae2                	ld	s5,24(sp)
    80203232:	6b42                	ld	s6,16(sp)
    80203234:	6ba2                	ld	s7,8(sp)
    80203236:	6c02                	ld	s8,0(sp)
    80203238:	6161                	add	sp,sp,80
    8020323a:	8082                	ret

000000008020323c <count_free_inodes>:
int count_free_inodes(void) {
    8020323c:	7179                	add	sp,sp,-48
    8020323e:	f406                	sd	ra,40(sp)
    80203240:	f022                	sd	s0,32(sp)
    80203242:	ec26                	sd	s1,24(sp)
    80203244:	e84a                	sd	s2,16(sp)
    80203246:	e44e                	sd	s3,8(sp)
    80203248:	1800                	add	s0,sp,48
    for (uint inum = 1; inum < sb.ninodes; inum++) {
    8020324a:	00034717          	auipc	a4,0x34
    8020324e:	d2272703          	lw	a4,-734(a4) # 80236f6c <sb+0xc>
    80203252:	4785                	li	a5,1
    80203254:	04e7f563          	bgeu	a5,a4,8020329e <count_free_inodes+0x62>
    80203258:	4485                	li	s1,1
    int free = 0;
    8020325a:	4981                	li	s3,0
        struct buf *bp = bread(ROOTDEV, IBLOCK(inum, sb));
    8020325c:	00034917          	auipc	s2,0x34
    80203260:	d0490913          	add	s2,s2,-764 # 80236f60 <sb>
    80203264:	a811                	j	80203278 <count_free_inodes+0x3c>
        brelse(bp);
    80203266:	fffff097          	auipc	ra,0xfffff
    8020326a:	df0080e7          	jalr	-528(ra) # 80202056 <brelse>
    for (uint inum = 1; inum < sb.ninodes; inum++) {
    8020326e:	2485                	addw	s1,s1,1
    80203270:	00c92783          	lw	a5,12(s2)
    80203274:	02f4f663          	bgeu	s1,a5,802032a0 <count_free_inodes+0x64>
        struct buf *bp = bread(ROOTDEV, IBLOCK(inum, sb));
    80203278:	0044d59b          	srlw	a1,s1,0x4
    8020327c:	01892783          	lw	a5,24(s2)
    80203280:	9dbd                	addw	a1,a1,a5
    80203282:	4505                	li	a0,1
    80203284:	fffff097          	auipc	ra,0xfffff
    80203288:	c80080e7          	jalr	-896(ra) # 80201f04 <bread>
        struct dinode *dip = (struct dinode*)bp->data + inum % IPB;
    8020328c:	00f4f793          	and	a5,s1,15
        if (dip->type == 0)
    80203290:	079a                	sll	a5,a5,0x6
    80203292:	97aa                	add	a5,a5,a0
    80203294:	05879783          	lh	a5,88(a5)
    80203298:	f7f9                	bnez	a5,80203266 <count_free_inodes+0x2a>
            free++;
    8020329a:	2985                	addw	s3,s3,1
    8020329c:	b7e9                	j	80203266 <count_free_inodes+0x2a>
    int free = 0;
    8020329e:	4981                	li	s3,0
}
    802032a0:	854e                	mv	a0,s3
    802032a2:	70a2                	ld	ra,40(sp)
    802032a4:	7402                	ld	s0,32(sp)
    802032a6:	64e2                	ld	s1,24(sp)
    802032a8:	6942                	ld	s2,16(sp)
    802032aa:	69a2                	ld	s3,8(sp)
    802032ac:	6145                	add	sp,sp,48
    802032ae:	8082                	ret

00000000802032b0 <get_superblock>:
void get_superblock(struct superblock *dst) {
    802032b0:	1141                	add	sp,sp,-16
    802032b2:	e422                	sd	s0,8(sp)
    802032b4:	0800                	add	s0,sp,16
    *dst = sb;
    802032b6:	00034797          	auipc	a5,0x34
    802032ba:	caa78793          	add	a5,a5,-854 # 80236f60 <sb>
    802032be:	0007a303          	lw	t1,0(a5)
    802032c2:	0047a883          	lw	a7,4(a5)
    802032c6:	0087a803          	lw	a6,8(a5)
    802032ca:	47cc                	lw	a1,12(a5)
    802032cc:	4b90                	lw	a2,16(a5)
    802032ce:	4bd4                	lw	a3,20(a5)
    802032d0:	4f98                	lw	a4,24(a5)
    802032d2:	4fdc                	lw	a5,28(a5)
    802032d4:	00652023          	sw	t1,0(a0)
    802032d8:	01152223          	sw	a7,4(a0)
    802032dc:	01052423          	sw	a6,8(a0)
    802032e0:	c54c                	sw	a1,12(a0)
    802032e2:	c910                	sw	a2,16(a0)
    802032e4:	c954                	sw	a3,20(a0)
    802032e6:	cd18                	sw	a4,24(a0)
    802032e8:	cd5c                	sw	a5,28(a0)
}
    802032ea:	6422                	ld	s0,8(sp)
    802032ec:	0141                	add	sp,sp,16
    802032ee:	8082                	ret

00000000802032f0 <dump_inode_usage>:
void dump_inode_usage(void) {
    802032f0:	7179                	add	sp,sp,-48
    802032f2:	f406                	sd	ra,40(sp)
    802032f4:	f022                	sd	s0,32(sp)
    802032f6:	ec26                	sd	s1,24(sp)
    802032f8:	e84a                	sd	s2,16(sp)
    802032fa:	e44e                	sd	s3,8(sp)
    802032fc:	1800                	add	s0,sp,48
    acquire(&icache.lock);
    802032fe:	00034517          	auipc	a0,0x34
    80203302:	c8250513          	add	a0,a0,-894 # 80236f80 <icache>
    80203306:	ffffd097          	auipc	ra,0xffffd
    8020330a:	534080e7          	jalr	1332(ra) # 8020083a <acquire>
    printf("=== Inode Usage ===\n");
    8020330e:	00003517          	auipc	a0,0x3
    80203312:	56a50513          	add	a0,a0,1386 # 80206878 <syscalls+0x2a8>
    80203316:	ffffd097          	auipc	ra,0xffffd
    8020331a:	e3e080e7          	jalr	-450(ra) # 80200154 <printf>
    for (int i = 0; i < NINODE; i++) {
    8020331e:	00034497          	auipc	s1,0x34
    80203322:	c7e48493          	add	s1,s1,-898 # 80236f9c <icache+0x1c>
    80203326:	0003e917          	auipc	s2,0x3e
    8020332a:	bd690913          	add	s2,s2,-1066 # 80240efc <log+0x4>
            printf("inum=%d ref=%d type=%d size=%d\n", ip->inum, ip->ref, ip->type, ip->size);
    8020332e:	00003997          	auipc	s3,0x3
    80203332:	56298993          	add	s3,s3,1378 # 80206890 <syscalls+0x2c0>
    80203336:	a029                	j	80203340 <dump_inode_usage+0x50>
    for (int i = 0; i < NINODE; i++) {
    80203338:	08848493          	add	s1,s1,136
    8020333c:	01248f63          	beq	s1,s2,8020335a <dump_inode_usage+0x6a>
        if (ip->ref > 0)
    80203340:	40d0                	lw	a2,4(s1)
    80203342:	fec05be3          	blez	a2,80203338 <dump_inode_usage+0x48>
            printf("inum=%d ref=%d type=%d size=%d\n", ip->inum, ip->ref, ip->type, ip->size);
    80203346:	44b8                	lw	a4,72(s1)
    80203348:	04049683          	lh	a3,64(s1)
    8020334c:	408c                	lw	a1,0(s1)
    8020334e:	854e                	mv	a0,s3
    80203350:	ffffd097          	auipc	ra,0xffffd
    80203354:	e04080e7          	jalr	-508(ra) # 80200154 <printf>
    80203358:	b7c5                	j	80203338 <dump_inode_usage+0x48>
    release(&icache.lock);
    8020335a:	00034517          	auipc	a0,0x34
    8020335e:	c2650513          	add	a0,a0,-986 # 80236f80 <icache>
    80203362:	ffffd097          	auipc	ra,0xffffd
    80203366:	5ca080e7          	jalr	1482(ra) # 8020092c <release>
}
    8020336a:	70a2                	ld	ra,40(sp)
    8020336c:	7402                	ld	s0,32(sp)
    8020336e:	64e2                	ld	s1,24(sp)
    80203370:	6942                	ld	s2,16(sp)
    80203372:	69a2                	ld	s3,8(sp)
    80203374:	6145                	add	sp,sp,48
    80203376:	8082                	ret

0000000080203378 <write_head>:
    struct logheader *hb = (struct logheader*)(buf->data);
    log.lh = *hb;
    brelse(buf);
}

static void write_head(void) {
    80203378:	1101                	add	sp,sp,-32
    8020337a:	ec06                	sd	ra,24(sp)
    8020337c:	e822                	sd	s0,16(sp)
    8020337e:	e426                	sd	s1,8(sp)
    80203380:	1000                	add	s0,sp,32
    struct buf *buf = bread(log.dev, log.start);
    80203382:	0003e797          	auipc	a5,0x3e
    80203386:	b7678793          	add	a5,a5,-1162 # 80240ef8 <log>
    8020338a:	4f8c                	lw	a1,24(a5)
    8020338c:	5788                	lw	a0,40(a5)
    8020338e:	fffff097          	auipc	ra,0xfffff
    80203392:	b76080e7          	jalr	-1162(ra) # 80201f04 <bread>
    80203396:	84aa                	mv	s1,a0
    struct logheader *hb = (struct logheader*)(buf->data);
    *hb = log.lh;
    80203398:	07c00613          	li	a2,124
    8020339c:	0003e597          	auipc	a1,0x3e
    802033a0:	b8858593          	add	a1,a1,-1144 # 80240f24 <log+0x2c>
    802033a4:	05850513          	add	a0,a0,88
    802033a8:	ffffd097          	auipc	ra,0xffffd
    802033ac:	680080e7          	jalr	1664(ra) # 80200a28 <memcpy>
    bwrite(buf);
    802033b0:	8526                	mv	a0,s1
    802033b2:	fffff097          	auipc	ra,0xfffff
    802033b6:	c64080e7          	jalr	-924(ra) # 80202016 <bwrite>
    brelse(buf);
    802033ba:	8526                	mv	a0,s1
    802033bc:	fffff097          	auipc	ra,0xfffff
    802033c0:	c9a080e7          	jalr	-870(ra) # 80202056 <brelse>
}
    802033c4:	60e2                	ld	ra,24(sp)
    802033c6:	6442                	ld	s0,16(sp)
    802033c8:	64a2                	ld	s1,8(sp)
    802033ca:	6105                	add	sp,sp,32
    802033cc:	8082                	ret

00000000802033ce <install_trans>:
static void install_trans(int recovering) {
    802033ce:	7139                	add	sp,sp,-64
    802033d0:	fc06                	sd	ra,56(sp)
    802033d2:	f822                	sd	s0,48(sp)
    802033d4:	f426                	sd	s1,40(sp)
    802033d6:	f04a                	sd	s2,32(sp)
    802033d8:	ec4e                	sd	s3,24(sp)
    802033da:	e852                	sd	s4,16(sp)
    802033dc:	e456                	sd	s5,8(sp)
    802033de:	e05a                	sd	s6,0(sp)
    802033e0:	0080                	add	s0,sp,64
    802033e2:	8b2a                	mv	s6,a0
    for (int tail = 0; tail < log.lh.n; tail++) {
    802033e4:	0003e797          	auipc	a5,0x3e
    802033e8:	b407a783          	lw	a5,-1216(a5) # 80240f24 <log+0x2c>
    802033ec:	08f05463          	blez	a5,80203474 <install_trans+0xa6>
    802033f0:	0003ea97          	auipc	s5,0x3e
    802033f4:	b38a8a93          	add	s5,s5,-1224 # 80240f28 <log+0x30>
    802033f8:	4a01                	li	s4,0
        struct buf *lbuf = bread(log.dev, log.start + tail + 1);
    802033fa:	0003e997          	auipc	s3,0x3e
    802033fe:	afe98993          	add	s3,s3,-1282 # 80240ef8 <log>
    80203402:	0189a583          	lw	a1,24(s3)
    80203406:	014585bb          	addw	a1,a1,s4
    8020340a:	2585                	addw	a1,a1,1
    8020340c:	0289a503          	lw	a0,40(s3)
    80203410:	fffff097          	auipc	ra,0xfffff
    80203414:	af4080e7          	jalr	-1292(ra) # 80201f04 <bread>
    80203418:	892a                	mv	s2,a0
        struct buf *dbuf = bread(log.dev, log.lh.block[tail]);
    8020341a:	000aa583          	lw	a1,0(s5)
    8020341e:	0289a503          	lw	a0,40(s3)
    80203422:	fffff097          	auipc	ra,0xfffff
    80203426:	ae2080e7          	jalr	-1310(ra) # 80201f04 <bread>
    8020342a:	84aa                	mv	s1,a0
        memmove(dbuf->data, lbuf->data, BSIZE);
    8020342c:	40000613          	li	a2,1024
    80203430:	05890593          	add	a1,s2,88
    80203434:	05850513          	add	a0,a0,88
    80203438:	ffffd097          	auipc	ra,0xffffd
    8020343c:	58c080e7          	jalr	1420(ra) # 802009c4 <memmove>
        bwrite(dbuf);
    80203440:	8526                	mv	a0,s1
    80203442:	fffff097          	auipc	ra,0xfffff
    80203446:	bd4080e7          	jalr	-1068(ra) # 80202016 <bwrite>
        bunpin(dbuf);
    8020344a:	8526                	mv	a0,s1
    8020344c:	fffff097          	auipc	ra,0xfffff
    80203450:	ce4080e7          	jalr	-796(ra) # 80202130 <bunpin>
        brelse(lbuf);
    80203454:	854a                	mv	a0,s2
    80203456:	fffff097          	auipc	ra,0xfffff
    8020345a:	c00080e7          	jalr	-1024(ra) # 80202056 <brelse>
        brelse(dbuf);
    8020345e:	8526                	mv	a0,s1
    80203460:	fffff097          	auipc	ra,0xfffff
    80203464:	bf6080e7          	jalr	-1034(ra) # 80202056 <brelse>
    for (int tail = 0; tail < log.lh.n; tail++) {
    80203468:	2a05                	addw	s4,s4,1
    8020346a:	0a91                	add	s5,s5,4
    8020346c:	02c9a783          	lw	a5,44(s3)
    80203470:	f8fa49e3          	blt	s4,a5,80203402 <install_trans+0x34>
    if (!recovering) {
    80203474:	000b0c63          	beqz	s6,8020348c <install_trans+0xbe>
}
    80203478:	70e2                	ld	ra,56(sp)
    8020347a:	7442                	ld	s0,48(sp)
    8020347c:	74a2                	ld	s1,40(sp)
    8020347e:	7902                	ld	s2,32(sp)
    80203480:	69e2                	ld	s3,24(sp)
    80203482:	6a42                	ld	s4,16(sp)
    80203484:	6aa2                	ld	s5,8(sp)
    80203486:	6b02                	ld	s6,0(sp)
    80203488:	6121                	add	sp,sp,64
    8020348a:	8082                	ret
        log.lh.n = 0;
    8020348c:	0003e797          	auipc	a5,0x3e
    80203490:	a6c78793          	add	a5,a5,-1428 # 80240ef8 <log>
    80203494:	0207a623          	sw	zero,44(a5)
        struct buf *buf = bread(log.dev, log.start);
    80203498:	4f8c                	lw	a1,24(a5)
    8020349a:	5788                	lw	a0,40(a5)
    8020349c:	fffff097          	auipc	ra,0xfffff
    802034a0:	a68080e7          	jalr	-1432(ra) # 80201f04 <bread>
    802034a4:	84aa                	mv	s1,a0
        *hb = log.lh;
    802034a6:	07c00613          	li	a2,124
    802034aa:	0003e597          	auipc	a1,0x3e
    802034ae:	a7a58593          	add	a1,a1,-1414 # 80240f24 <log+0x2c>
    802034b2:	05850513          	add	a0,a0,88
    802034b6:	ffffd097          	auipc	ra,0xffffd
    802034ba:	572080e7          	jalr	1394(ra) # 80200a28 <memcpy>
        bwrite(buf);
    802034be:	8526                	mv	a0,s1
    802034c0:	fffff097          	auipc	ra,0xfffff
    802034c4:	b56080e7          	jalr	-1194(ra) # 80202016 <bwrite>
        brelse(buf);
    802034c8:	8526                	mv	a0,s1
    802034ca:	fffff097          	auipc	ra,0xfffff
    802034ce:	b8c080e7          	jalr	-1140(ra) # 80202056 <brelse>
}
    802034d2:	b75d                	j	80203478 <install_trans+0xaa>

00000000802034d4 <initlog>:

void initlog(int dev, struct superblock *sb) {
    802034d4:	7179                	add	sp,sp,-48
    802034d6:	f406                	sd	ra,40(sp)
    802034d8:	f022                	sd	s0,32(sp)
    802034da:	ec26                	sd	s1,24(sp)
    802034dc:	e84a                	sd	s2,16(sp)
    802034de:	e44e                	sd	s3,8(sp)
    802034e0:	1800                	add	s0,sp,48
    802034e2:	892a                	mv	s2,a0
    802034e4:	89ae                	mv	s3,a1
    if (sizeof(struct logheader) >= BSIZE) {
        panic("initlog: too big");
    }
    spinlock_init(&log.lock, "log");
    802034e6:	0003e497          	auipc	s1,0x3e
    802034ea:	a1248493          	add	s1,s1,-1518 # 80240ef8 <log>
    802034ee:	00003597          	auipc	a1,0x3
    802034f2:	3c258593          	add	a1,a1,962 # 802068b0 <syscalls+0x2e0>
    802034f6:	8526                	mv	a0,s1
    802034f8:	ffffd097          	auipc	ra,0xffffd
    802034fc:	2e0080e7          	jalr	736(ra) # 802007d8 <spinlock_init>
    log.start = sb->logstart;
    80203500:	0149a583          	lw	a1,20(s3)
    80203504:	cc8c                	sw	a1,24(s1)
    log.size = sb->nlog;
    80203506:	0109a783          	lw	a5,16(s3)
    8020350a:	ccdc                	sw	a5,28(s1)
    log.dev = dev;
    8020350c:	0324a423          	sw	s2,40(s1)
    struct buf *buf = bread(log.dev, log.start);
    80203510:	854a                	mv	a0,s2
    80203512:	fffff097          	auipc	ra,0xfffff
    80203516:	9f2080e7          	jalr	-1550(ra) # 80201f04 <bread>
    8020351a:	892a                	mv	s2,a0
    log.lh = *hb;
    8020351c:	07c00613          	li	a2,124
    80203520:	05850593          	add	a1,a0,88
    80203524:	0003e517          	auipc	a0,0x3e
    80203528:	a0050513          	add	a0,a0,-1536 # 80240f24 <log+0x2c>
    8020352c:	ffffd097          	auipc	ra,0xffffd
    80203530:	4fc080e7          	jalr	1276(ra) # 80200a28 <memcpy>
    brelse(buf);
    80203534:	854a                	mv	a0,s2
    80203536:	fffff097          	auipc	ra,0xfffff
    8020353a:	b20080e7          	jalr	-1248(ra) # 80202056 <brelse>
    read_head();
    install_trans(1);
    8020353e:	4505                	li	a0,1
    80203540:	00000097          	auipc	ra,0x0
    80203544:	e8e080e7          	jalr	-370(ra) # 802033ce <install_trans>
    log.lh.n = 0;
    80203548:	0204a623          	sw	zero,44(s1)
    write_head();
    8020354c:	00000097          	auipc	ra,0x0
    80203550:	e2c080e7          	jalr	-468(ra) # 80203378 <write_head>
}
    80203554:	70a2                	ld	ra,40(sp)
    80203556:	7402                	ld	s0,32(sp)
    80203558:	64e2                	ld	s1,24(sp)
    8020355a:	6942                	ld	s2,16(sp)
    8020355c:	69a2                	ld	s3,8(sp)
    8020355e:	6145                	add	sp,sp,48
    80203560:	8082                	ret

0000000080203562 <begin_op>:

void begin_op(void) {
    80203562:	1101                	add	sp,sp,-32
    80203564:	ec06                	sd	ra,24(sp)
    80203566:	e822                	sd	s0,16(sp)
    80203568:	e426                	sd	s1,8(sp)
    8020356a:	e04a                	sd	s2,0(sp)
    8020356c:	1000                	add	s0,sp,32
    acquire(&log.lock);
    8020356e:	0003e517          	auipc	a0,0x3e
    80203572:	98a50513          	add	a0,a0,-1654 # 80240ef8 <log>
    80203576:	ffffd097          	auipc	ra,0xffffd
    8020357a:	2c4080e7          	jalr	708(ra) # 8020083a <acquire>
    while (1) {
        if (log.committing) {
    8020357e:	0003e497          	auipc	s1,0x3e
    80203582:	97a48493          	add	s1,s1,-1670 # 80240ef8 <log>
            sleep(&log, &log.lock);
        } else if (log.lh.n + (log.outstanding + 1) * MAXOPBLOCKS > LOGSIZE) {
    80203586:	4979                	li	s2,30
    80203588:	a039                	j	80203596 <begin_op+0x34>
            sleep(&log, &log.lock);
    8020358a:	85a6                	mv	a1,s1
    8020358c:	8526                	mv	a0,s1
    8020358e:	ffffe097          	auipc	ra,0xffffe
    80203592:	1b2080e7          	jalr	434(ra) # 80201740 <sleep>
        if (log.committing) {
    80203596:	50dc                	lw	a5,36(s1)
    80203598:	fbed                	bnez	a5,8020358a <begin_op+0x28>
        } else if (log.lh.n + (log.outstanding + 1) * MAXOPBLOCKS > LOGSIZE) {
    8020359a:	5098                	lw	a4,32(s1)
    8020359c:	2705                	addw	a4,a4,1
    8020359e:	0027179b          	sllw	a5,a4,0x2
    802035a2:	9fb9                	addw	a5,a5,a4
    802035a4:	0017979b          	sllw	a5,a5,0x1
    802035a8:	54d4                	lw	a3,44(s1)
    802035aa:	9fb5                	addw	a5,a5,a3
    802035ac:	00f95963          	bge	s2,a5,802035be <begin_op+0x5c>
            sleep(&log, &log.lock);
    802035b0:	85a6                	mv	a1,s1
    802035b2:	8526                	mv	a0,s1
    802035b4:	ffffe097          	auipc	ra,0xffffe
    802035b8:	18c080e7          	jalr	396(ra) # 80201740 <sleep>
    802035bc:	bfe9                	j	80203596 <begin_op+0x34>
        } else {
            log.outstanding += 1;
    802035be:	0003e517          	auipc	a0,0x3e
    802035c2:	93a50513          	add	a0,a0,-1734 # 80240ef8 <log>
    802035c6:	d118                	sw	a4,32(a0)
            release(&log.lock);
    802035c8:	ffffd097          	auipc	ra,0xffffd
    802035cc:	364080e7          	jalr	868(ra) # 8020092c <release>
            break;
        }
    }
}
    802035d0:	60e2                	ld	ra,24(sp)
    802035d2:	6442                	ld	s0,16(sp)
    802035d4:	64a2                	ld	s1,8(sp)
    802035d6:	6902                	ld	s2,0(sp)
    802035d8:	6105                	add	sp,sp,32
    802035da:	8082                	ret

00000000802035dc <end_op>:

void end_op(void) {
    802035dc:	7139                	add	sp,sp,-64
    802035de:	fc06                	sd	ra,56(sp)
    802035e0:	f822                	sd	s0,48(sp)
    802035e2:	f426                	sd	s1,40(sp)
    802035e4:	f04a                	sd	s2,32(sp)
    802035e6:	ec4e                	sd	s3,24(sp)
    802035e8:	e852                	sd	s4,16(sp)
    802035ea:	e456                	sd	s5,8(sp)
    802035ec:	0080                	add	s0,sp,64
    int do_commit = 0;

    acquire(&log.lock);
    802035ee:	0003e497          	auipc	s1,0x3e
    802035f2:	90a48493          	add	s1,s1,-1782 # 80240ef8 <log>
    802035f6:	8526                	mv	a0,s1
    802035f8:	ffffd097          	auipc	ra,0xffffd
    802035fc:	242080e7          	jalr	578(ra) # 8020083a <acquire>
    log.outstanding--;
    80203600:	509c                	lw	a5,32(s1)
    80203602:	37fd                	addw	a5,a5,-1
    80203604:	d09c                	sw	a5,32(s1)
    if (log.committing) {
    80203606:	50dc                	lw	a5,36(s1)
    80203608:	e3bd                	bnez	a5,8020366e <end_op+0x92>
        panic("log.committing");
    }
    if (log.outstanding == 0) {
    8020360a:	0003e917          	auipc	s2,0x3e
    8020360e:	90e92903          	lw	s2,-1778(s2) # 80240f18 <log+0x20>
    80203612:	06091763          	bnez	s2,80203680 <end_op+0xa4>
        do_commit = 1;
        log.committing = 1;
    80203616:	0003e497          	auipc	s1,0x3e
    8020361a:	8e248493          	add	s1,s1,-1822 # 80240ef8 <log>
    8020361e:	4785                	li	a5,1
    80203620:	d0dc                	sw	a5,36(s1)
    } else {
        wakeup(&log);
    }
    release(&log.lock);
    80203622:	8526                	mv	a0,s1
    80203624:	ffffd097          	auipc	ra,0xffffd
    80203628:	308080e7          	jalr	776(ra) # 8020092c <release>

    if (do_commit) {
        if (log.lh.n > 0) {
    8020362c:	54dc                	lw	a5,44(s1)
    8020362e:	06f04863          	bgtz	a5,8020369e <end_op+0xc2>
            write_log();
            install_trans(0);
            log.lh.n = 0;
            write_head();
        }
        acquire(&log.lock);
    80203632:	0003e497          	auipc	s1,0x3e
    80203636:	8c648493          	add	s1,s1,-1850 # 80240ef8 <log>
    8020363a:	8526                	mv	a0,s1
    8020363c:	ffffd097          	auipc	ra,0xffffd
    80203640:	1fe080e7          	jalr	510(ra) # 8020083a <acquire>
        log.committing = 0;
    80203644:	0204a223          	sw	zero,36(s1)
        wakeup(&log);
    80203648:	8526                	mv	a0,s1
    8020364a:	ffffe097          	auipc	ra,0xffffe
    8020364e:	264080e7          	jalr	612(ra) # 802018ae <wakeup>
        release(&log.lock);
    80203652:	8526                	mv	a0,s1
    80203654:	ffffd097          	auipc	ra,0xffffd
    80203658:	2d8080e7          	jalr	728(ra) # 8020092c <release>
    }
}
    8020365c:	70e2                	ld	ra,56(sp)
    8020365e:	7442                	ld	s0,48(sp)
    80203660:	74a2                	ld	s1,40(sp)
    80203662:	7902                	ld	s2,32(sp)
    80203664:	69e2                	ld	s3,24(sp)
    80203666:	6a42                	ld	s4,16(sp)
    80203668:	6aa2                	ld	s5,8(sp)
    8020366a:	6121                	add	sp,sp,64
    8020366c:	8082                	ret
        panic("log.committing");
    8020366e:	00003517          	auipc	a0,0x3
    80203672:	24a50513          	add	a0,a0,586 # 802068b8 <syscalls+0x2e8>
    80203676:	ffffd097          	auipc	ra,0xffffd
    8020367a:	d5e080e7          	jalr	-674(ra) # 802003d4 <panic>
    8020367e:	b771                	j	8020360a <end_op+0x2e>
        wakeup(&log);
    80203680:	0003e497          	auipc	s1,0x3e
    80203684:	87848493          	add	s1,s1,-1928 # 80240ef8 <log>
    80203688:	8526                	mv	a0,s1
    8020368a:	ffffe097          	auipc	ra,0xffffe
    8020368e:	224080e7          	jalr	548(ra) # 802018ae <wakeup>
    release(&log.lock);
    80203692:	8526                	mv	a0,s1
    80203694:	ffffd097          	auipc	ra,0xffffd
    80203698:	298080e7          	jalr	664(ra) # 8020092c <release>
    if (do_commit) {
    8020369c:	b7c1                	j	8020365c <end_op+0x80>

static void write_log(void) {
    for (int tail = 0; tail < log.lh.n; tail++) {
    8020369e:	0003ea97          	auipc	s5,0x3e
    802036a2:	88aa8a93          	add	s5,s5,-1910 # 80240f28 <log+0x30>
        struct buf *to = bread(log.dev, log.start + tail + 1);
    802036a6:	0003ea17          	auipc	s4,0x3e
    802036aa:	852a0a13          	add	s4,s4,-1966 # 80240ef8 <log>
    802036ae:	018a2583          	lw	a1,24(s4)
    802036b2:	012585bb          	addw	a1,a1,s2
    802036b6:	2585                	addw	a1,a1,1
    802036b8:	028a2503          	lw	a0,40(s4)
    802036bc:	fffff097          	auipc	ra,0xfffff
    802036c0:	848080e7          	jalr	-1976(ra) # 80201f04 <bread>
    802036c4:	84aa                	mv	s1,a0
        struct buf *from = bread(log.dev, log.lh.block[tail]);
    802036c6:	000aa583          	lw	a1,0(s5)
    802036ca:	028a2503          	lw	a0,40(s4)
    802036ce:	fffff097          	auipc	ra,0xfffff
    802036d2:	836080e7          	jalr	-1994(ra) # 80201f04 <bread>
    802036d6:	89aa                	mv	s3,a0
        memmove(to->data, from->data, BSIZE);
    802036d8:	40000613          	li	a2,1024
    802036dc:	05850593          	add	a1,a0,88
    802036e0:	05848513          	add	a0,s1,88
    802036e4:	ffffd097          	auipc	ra,0xffffd
    802036e8:	2e0080e7          	jalr	736(ra) # 802009c4 <memmove>
        bwrite(to);
    802036ec:	8526                	mv	a0,s1
    802036ee:	fffff097          	auipc	ra,0xfffff
    802036f2:	928080e7          	jalr	-1752(ra) # 80202016 <bwrite>
        brelse(from);
    802036f6:	854e                	mv	a0,s3
    802036f8:	fffff097          	auipc	ra,0xfffff
    802036fc:	95e080e7          	jalr	-1698(ra) # 80202056 <brelse>
        brelse(to);
    80203700:	8526                	mv	a0,s1
    80203702:	fffff097          	auipc	ra,0xfffff
    80203706:	954080e7          	jalr	-1708(ra) # 80202056 <brelse>
    for (int tail = 0; tail < log.lh.n; tail++) {
    8020370a:	2905                	addw	s2,s2,1
    8020370c:	0a91                	add	s5,s5,4
    8020370e:	02ca2783          	lw	a5,44(s4)
    80203712:	f8f94ee3          	blt	s2,a5,802036ae <end_op+0xd2>
            install_trans(0);
    80203716:	4501                	li	a0,0
    80203718:	00000097          	auipc	ra,0x0
    8020371c:	cb6080e7          	jalr	-842(ra) # 802033ce <install_trans>
            log.lh.n = 0;
    80203720:	0003e797          	auipc	a5,0x3e
    80203724:	8007a223          	sw	zero,-2044(a5) # 80240f24 <log+0x2c>
            write_head();
    80203728:	00000097          	auipc	ra,0x0
    8020372c:	c50080e7          	jalr	-944(ra) # 80203378 <write_head>
    80203730:	b709                	j	80203632 <end_op+0x56>

0000000080203732 <log_write>:
    }
}

void log_write(struct buf *b) {
    80203732:	1101                	add	sp,sp,-32
    80203734:	ec06                	sd	ra,24(sp)
    80203736:	e822                	sd	s0,16(sp)
    80203738:	e426                	sd	s1,8(sp)
    8020373a:	e04a                	sd	s2,0(sp)
    8020373c:	1000                	add	s0,sp,32
    8020373e:	84aa                	mv	s1,a0
    if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1) {
    80203740:	0003d797          	auipc	a5,0x3d
    80203744:	7e47a783          	lw	a5,2020(a5) # 80240f24 <log+0x2c>
    80203748:	4775                	li	a4,29
    8020374a:	00f74963          	blt	a4,a5,8020375c <log_write+0x2a>
    8020374e:	0003d717          	auipc	a4,0x3d
    80203752:	7c672703          	lw	a4,1990(a4) # 80240f14 <log+0x1c>
    80203756:	377d                	addw	a4,a4,-1
    80203758:	00e7ca63          	blt	a5,a4,8020376c <log_write+0x3a>
        panic("log_write: too big");
    8020375c:	00003517          	auipc	a0,0x3
    80203760:	16c50513          	add	a0,a0,364 # 802068c8 <syscalls+0x2f8>
    80203764:	ffffd097          	auipc	ra,0xffffd
    80203768:	c70080e7          	jalr	-912(ra) # 802003d4 <panic>
    }
    if (log.outstanding < 1) {
    8020376c:	0003d797          	auipc	a5,0x3d
    80203770:	7ac7a783          	lw	a5,1964(a5) # 80240f18 <log+0x20>
    80203774:	06f05163          	blez	a5,802037d6 <log_write+0xa4>
        panic("log_write outside trans");
    }

    acquire(&log.lock);
    80203778:	0003d917          	auipc	s2,0x3d
    8020377c:	78090913          	add	s2,s2,1920 # 80240ef8 <log>
    80203780:	854a                	mv	a0,s2
    80203782:	ffffd097          	auipc	ra,0xffffd
    80203786:	0b8080e7          	jalr	184(ra) # 8020083a <acquire>
    int i;
    for (i = 0; i < log.lh.n; i++) {
    8020378a:	02c92603          	lw	a2,44(s2)
    8020378e:	04c05d63          	blez	a2,802037e8 <log_write+0xb6>
        if (log.lh.block[i] == b->blockno) {
    80203792:	44cc                	lw	a1,12(s1)
    80203794:	0003d717          	auipc	a4,0x3d
    80203798:	79470713          	add	a4,a4,1940 # 80240f28 <log+0x30>
    for (i = 0; i < log.lh.n; i++) {
    8020379c:	4781                	li	a5,0
        if (log.lh.block[i] == b->blockno) {
    8020379e:	4314                	lw	a3,0(a4)
    802037a0:	04b68563          	beq	a3,a1,802037ea <log_write+0xb8>
    for (i = 0; i < log.lh.n; i++) {
    802037a4:	2785                	addw	a5,a5,1
    802037a6:	0711                	add	a4,a4,4
    802037a8:	fec79be3          	bne	a5,a2,8020379e <log_write+0x6c>
            break;
        }
    }
    log.lh.block[i] = b->blockno;
    802037ac:	00860713          	add	a4,a2,8 # 40008 <_start-0x801bfff8>
    802037b0:	070a                	sll	a4,a4,0x2
    802037b2:	0003d797          	auipc	a5,0x3d
    802037b6:	74678793          	add	a5,a5,1862 # 80240ef8 <log>
    802037ba:	97ba                	add	a5,a5,a4
    802037bc:	44d8                	lw	a4,12(s1)
    802037be:	cb98                	sw	a4,16(a5)
    if (i == log.lh.n) {
        log.lh.n++;
    802037c0:	2605                	addw	a2,a2,1
    802037c2:	0003d797          	auipc	a5,0x3d
    802037c6:	76c7a123          	sw	a2,1890(a5) # 80240f24 <log+0x2c>
        bpin(b);
    802037ca:	8526                	mv	a0,s1
    802037cc:	fffff097          	auipc	ra,0xfffff
    802037d0:	928080e7          	jalr	-1752(ra) # 802020f4 <bpin>
    802037d4:	a03d                	j	80203802 <log_write+0xd0>
        panic("log_write outside trans");
    802037d6:	00003517          	auipc	a0,0x3
    802037da:	10a50513          	add	a0,a0,266 # 802068e0 <syscalls+0x310>
    802037de:	ffffd097          	auipc	ra,0xffffd
    802037e2:	bf6080e7          	jalr	-1034(ra) # 802003d4 <panic>
    802037e6:	bf49                	j	80203778 <log_write+0x46>
    for (i = 0; i < log.lh.n; i++) {
    802037e8:	4781                	li	a5,0
    log.lh.block[i] = b->blockno;
    802037ea:	00878693          	add	a3,a5,8
    802037ee:	068a                	sll	a3,a3,0x2
    802037f0:	0003d717          	auipc	a4,0x3d
    802037f4:	70870713          	add	a4,a4,1800 # 80240ef8 <log>
    802037f8:	9736                	add	a4,a4,a3
    802037fa:	44d4                	lw	a3,12(s1)
    802037fc:	cb14                	sw	a3,16(a4)
    if (i == log.lh.n) {
    802037fe:	02f60063          	beq	a2,a5,8020381e <log_write+0xec>
    }
    release(&log.lock);
    80203802:	0003d517          	auipc	a0,0x3d
    80203806:	6f650513          	add	a0,a0,1782 # 80240ef8 <log>
    8020380a:	ffffd097          	auipc	ra,0xffffd
    8020380e:	122080e7          	jalr	290(ra) # 8020092c <release>
}
    80203812:	60e2                	ld	ra,24(sp)
    80203814:	6442                	ld	s0,16(sp)
    80203816:	64a2                	ld	s1,8(sp)
    80203818:	6902                	ld	s2,0(sp)
    8020381a:	6105                	add	sp,sp,32
    8020381c:	8082                	ret
    8020381e:	863e                	mv	a2,a5
    80203820:	b745                	j	802037c0 <log_write+0x8e>

0000000080203822 <initsleeplock>:
#include "defs.h"
#include "sleeplock.h"

void initsleeplock(struct sleeplock *lk, char *name) {
    80203822:	1101                	add	sp,sp,-32
    80203824:	ec06                	sd	ra,24(sp)
    80203826:	e822                	sd	s0,16(sp)
    80203828:	e426                	sd	s1,8(sp)
    8020382a:	e04a                	sd	s2,0(sp)
    8020382c:	1000                	add	s0,sp,32
    8020382e:	84aa                	mv	s1,a0
    80203830:	892e                	mv	s2,a1
    spinlock_init(&lk->lk, "sleeplock");
    80203832:	00003597          	auipc	a1,0x3
    80203836:	0c658593          	add	a1,a1,198 # 802068f8 <syscalls+0x328>
    8020383a:	0521                	add	a0,a0,8
    8020383c:	ffffd097          	auipc	ra,0xffffd
    80203840:	f9c080e7          	jalr	-100(ra) # 802007d8 <spinlock_init>
    lk->name = name;
    80203844:	0324b023          	sd	s2,32(s1)
    lk->locked = 0;
    80203848:	0004a023          	sw	zero,0(s1)
    lk->owner = 0;
    8020384c:	0204b423          	sd	zero,40(s1)
}
    80203850:	60e2                	ld	ra,24(sp)
    80203852:	6442                	ld	s0,16(sp)
    80203854:	64a2                	ld	s1,8(sp)
    80203856:	6902                	ld	s2,0(sp)
    80203858:	6105                	add	sp,sp,32
    8020385a:	8082                	ret

000000008020385c <acquiresleep>:

void acquiresleep(struct sleeplock *lk) {
    8020385c:	1101                	add	sp,sp,-32
    8020385e:	ec06                	sd	ra,24(sp)
    80203860:	e822                	sd	s0,16(sp)
    80203862:	e426                	sd	s1,8(sp)
    80203864:	e04a                	sd	s2,0(sp)
    80203866:	1000                	add	s0,sp,32
    80203868:	84aa                	mv	s1,a0
    acquire(&lk->lk);
    8020386a:	00850913          	add	s2,a0,8
    8020386e:	854a                	mv	a0,s2
    80203870:	ffffd097          	auipc	ra,0xffffd
    80203874:	fca080e7          	jalr	-54(ra) # 8020083a <acquire>
    while (lk->locked) {
    80203878:	409c                	lw	a5,0(s1)
    8020387a:	cb89                	beqz	a5,8020388c <acquiresleep+0x30>
        sleep(lk, &lk->lk);
    8020387c:	85ca                	mv	a1,s2
    8020387e:	8526                	mv	a0,s1
    80203880:	ffffe097          	auipc	ra,0xffffe
    80203884:	ec0080e7          	jalr	-320(ra) # 80201740 <sleep>
    while (lk->locked) {
    80203888:	409c                	lw	a5,0(s1)
    8020388a:	fbed                	bnez	a5,8020387c <acquiresleep+0x20>
    }
    lk->locked = 1;
    8020388c:	4785                	li	a5,1
    8020388e:	c09c                	sw	a5,0(s1)
    lk->owner = myproc();
    80203890:	ffffe097          	auipc	ra,0xffffe
    80203894:	b18080e7          	jalr	-1256(ra) # 802013a8 <myproc>
    80203898:	f488                	sd	a0,40(s1)
    release(&lk->lk);
    8020389a:	854a                	mv	a0,s2
    8020389c:	ffffd097          	auipc	ra,0xffffd
    802038a0:	090080e7          	jalr	144(ra) # 8020092c <release>
}
    802038a4:	60e2                	ld	ra,24(sp)
    802038a6:	6442                	ld	s0,16(sp)
    802038a8:	64a2                	ld	s1,8(sp)
    802038aa:	6902                	ld	s2,0(sp)
    802038ac:	6105                	add	sp,sp,32
    802038ae:	8082                	ret

00000000802038b0 <releasesleep>:

void releasesleep(struct sleeplock *lk) {
    802038b0:	1101                	add	sp,sp,-32
    802038b2:	ec06                	sd	ra,24(sp)
    802038b4:	e822                	sd	s0,16(sp)
    802038b6:	e426                	sd	s1,8(sp)
    802038b8:	e04a                	sd	s2,0(sp)
    802038ba:	1000                	add	s0,sp,32
    802038bc:	84aa                	mv	s1,a0
    acquire(&lk->lk);
    802038be:	00850913          	add	s2,a0,8
    802038c2:	854a                	mv	a0,s2
    802038c4:	ffffd097          	auipc	ra,0xffffd
    802038c8:	f76080e7          	jalr	-138(ra) # 8020083a <acquire>
    lk->locked = 0;
    802038cc:	0004a023          	sw	zero,0(s1)
    lk->owner = 0;
    802038d0:	0204b423          	sd	zero,40(s1)
    wakeup(lk);
    802038d4:	8526                	mv	a0,s1
    802038d6:	ffffe097          	auipc	ra,0xffffe
    802038da:	fd8080e7          	jalr	-40(ra) # 802018ae <wakeup>
    release(&lk->lk);
    802038de:	854a                	mv	a0,s2
    802038e0:	ffffd097          	auipc	ra,0xffffd
    802038e4:	04c080e7          	jalr	76(ra) # 8020092c <release>
}
    802038e8:	60e2                	ld	ra,24(sp)
    802038ea:	6442                	ld	s0,16(sp)
    802038ec:	64a2                	ld	s1,8(sp)
    802038ee:	6902                	ld	s2,0(sp)
    802038f0:	6105                	add	sp,sp,32
    802038f2:	8082                	ret

00000000802038f4 <holdingsleep>:

int holdingsleep(struct sleeplock *lk) {
    802038f4:	1101                	add	sp,sp,-32
    802038f6:	ec06                	sd	ra,24(sp)
    802038f8:	e822                	sd	s0,16(sp)
    802038fa:	e426                	sd	s1,8(sp)
    802038fc:	e04a                	sd	s2,0(sp)
    802038fe:	1000                	add	s0,sp,32
    80203900:	84aa                	mv	s1,a0
    int r;

    acquire(&lk->lk);
    80203902:	00850913          	add	s2,a0,8
    80203906:	854a                	mv	a0,s2
    80203908:	ffffd097          	auipc	ra,0xffffd
    8020390c:	f32080e7          	jalr	-206(ra) # 8020083a <acquire>
    r = lk->locked && lk->owner == myproc();
    80203910:	409c                	lw	a5,0(s1)
    80203912:	ef91                	bnez	a5,8020392e <holdingsleep+0x3a>
    80203914:	4481                	li	s1,0
    release(&lk->lk);
    80203916:	854a                	mv	a0,s2
    80203918:	ffffd097          	auipc	ra,0xffffd
    8020391c:	014080e7          	jalr	20(ra) # 8020092c <release>
    return r;
}
    80203920:	8526                	mv	a0,s1
    80203922:	60e2                	ld	ra,24(sp)
    80203924:	6442                	ld	s0,16(sp)
    80203926:	64a2                	ld	s1,8(sp)
    80203928:	6902                	ld	s2,0(sp)
    8020392a:	6105                	add	sp,sp,32
    8020392c:	8082                	ret
    r = lk->locked && lk->owner == myproc();
    8020392e:	7484                	ld	s1,40(s1)
    80203930:	ffffe097          	auipc	ra,0xffffe
    80203934:	a78080e7          	jalr	-1416(ra) # 802013a8 <myproc>
    80203938:	8c89                	sub	s1,s1,a0
    8020393a:	0014b493          	seqz	s1,s1
    8020393e:	bfe1                	j	80203916 <holdingsleep+0x22>

0000000080203940 <fileinit>:
struct {
    struct spinlock lock;
    struct file file[NFILE];
} ftable;

void fileinit(void) {
    80203940:	1141                	add	sp,sp,-16
    80203942:	e406                	sd	ra,8(sp)
    80203944:	e022                	sd	s0,0(sp)
    80203946:	0800                	add	s0,sp,16
    spinlock_init(&ftable.lock, "ftable");
    80203948:	00003597          	auipc	a1,0x3
    8020394c:	fc058593          	add	a1,a1,-64 # 80206908 <syscalls+0x338>
    80203950:	0003d517          	auipc	a0,0x3d
    80203954:	6f050513          	add	a0,a0,1776 # 80241040 <ftable>
    80203958:	ffffd097          	auipc	ra,0xffffd
    8020395c:	e80080e7          	jalr	-384(ra) # 802007d8 <spinlock_init>
    devsw[CONSOLE].write = consolewrite;
    80203960:	0003d797          	auipc	a5,0x3d
    80203964:	64078793          	add	a5,a5,1600 # 80240fa0 <devsw>
    80203968:	ffffc717          	auipc	a4,0xffffc
    8020396c:	6fe70713          	add	a4,a4,1790 # 80200066 <consolewrite>
    80203970:	ef98                	sd	a4,24(a5)
    devsw[CONSOLE].read = consoleread;
    80203972:	ffffc717          	auipc	a4,0xffffc
    80203976:	73070713          	add	a4,a4,1840 # 802000a2 <consoleread>
    8020397a:	eb98                	sd	a4,16(a5)
}
    8020397c:	60a2                	ld	ra,8(sp)
    8020397e:	6402                	ld	s0,0(sp)
    80203980:	0141                	add	sp,sp,16
    80203982:	8082                	ret

0000000080203984 <filealloc>:

struct file *filealloc(void) {
    80203984:	1101                	add	sp,sp,-32
    80203986:	ec06                	sd	ra,24(sp)
    80203988:	e822                	sd	s0,16(sp)
    8020398a:	e426                	sd	s1,8(sp)
    8020398c:	1000                	add	s0,sp,32
    acquire(&ftable.lock);
    8020398e:	0003d517          	auipc	a0,0x3d
    80203992:	6b250513          	add	a0,a0,1714 # 80241040 <ftable>
    80203996:	ffffd097          	auipc	ra,0xffffd
    8020399a:	ea4080e7          	jalr	-348(ra) # 8020083a <acquire>
    for (struct file *f = ftable.file; f < ftable.file + NFILE; f++) {
    8020399e:	0003d497          	auipc	s1,0x3d
    802039a2:	6ba48493          	add	s1,s1,1722 # 80241058 <ftable+0x18>
    802039a6:	0003e717          	auipc	a4,0x3e
    802039aa:	33270713          	add	a4,a4,818 # 80241cd8 <disk>
        if (f->ref == 0) {
    802039ae:	40dc                	lw	a5,4(s1)
    802039b0:	cf99                	beqz	a5,802039ce <filealloc+0x4a>
    for (struct file *f = ftable.file; f < ftable.file + NFILE; f++) {
    802039b2:	02048493          	add	s1,s1,32
    802039b6:	fee49ce3          	bne	s1,a4,802039ae <filealloc+0x2a>
            f->ref = 1;
            release(&ftable.lock);
            return f;
        }
    }
    release(&ftable.lock);
    802039ba:	0003d517          	auipc	a0,0x3d
    802039be:	68650513          	add	a0,a0,1670 # 80241040 <ftable>
    802039c2:	ffffd097          	auipc	ra,0xffffd
    802039c6:	f6a080e7          	jalr	-150(ra) # 8020092c <release>
    return 0;
    802039ca:	4481                	li	s1,0
    802039cc:	a819                	j	802039e2 <filealloc+0x5e>
            f->ref = 1;
    802039ce:	4785                	li	a5,1
    802039d0:	c0dc                	sw	a5,4(s1)
            release(&ftable.lock);
    802039d2:	0003d517          	auipc	a0,0x3d
    802039d6:	66e50513          	add	a0,a0,1646 # 80241040 <ftable>
    802039da:	ffffd097          	auipc	ra,0xffffd
    802039de:	f52080e7          	jalr	-174(ra) # 8020092c <release>
}
    802039e2:	8526                	mv	a0,s1
    802039e4:	60e2                	ld	ra,24(sp)
    802039e6:	6442                	ld	s0,16(sp)
    802039e8:	64a2                	ld	s1,8(sp)
    802039ea:	6105                	add	sp,sp,32
    802039ec:	8082                	ret

00000000802039ee <filedup>:

struct file *filedup(struct file *f) {
    802039ee:	1101                	add	sp,sp,-32
    802039f0:	ec06                	sd	ra,24(sp)
    802039f2:	e822                	sd	s0,16(sp)
    802039f4:	e426                	sd	s1,8(sp)
    802039f6:	1000                	add	s0,sp,32
    802039f8:	84aa                	mv	s1,a0
    acquire(&ftable.lock);
    802039fa:	0003d517          	auipc	a0,0x3d
    802039fe:	64650513          	add	a0,a0,1606 # 80241040 <ftable>
    80203a02:	ffffd097          	auipc	ra,0xffffd
    80203a06:	e38080e7          	jalr	-456(ra) # 8020083a <acquire>
    if (f->ref < 1) {
    80203a0a:	40dc                	lw	a5,4(s1)
    80203a0c:	02f05363          	blez	a5,80203a32 <filedup+0x44>
        panic("filedup");
    }
    f->ref++;
    80203a10:	40dc                	lw	a5,4(s1)
    80203a12:	2785                	addw	a5,a5,1
    80203a14:	c0dc                	sw	a5,4(s1)
    release(&ftable.lock);
    80203a16:	0003d517          	auipc	a0,0x3d
    80203a1a:	62a50513          	add	a0,a0,1578 # 80241040 <ftable>
    80203a1e:	ffffd097          	auipc	ra,0xffffd
    80203a22:	f0e080e7          	jalr	-242(ra) # 8020092c <release>
    return f;
}
    80203a26:	8526                	mv	a0,s1
    80203a28:	60e2                	ld	ra,24(sp)
    80203a2a:	6442                	ld	s0,16(sp)
    80203a2c:	64a2                	ld	s1,8(sp)
    80203a2e:	6105                	add	sp,sp,32
    80203a30:	8082                	ret
        panic("filedup");
    80203a32:	00003517          	auipc	a0,0x3
    80203a36:	ede50513          	add	a0,a0,-290 # 80206910 <syscalls+0x340>
    80203a3a:	ffffd097          	auipc	ra,0xffffd
    80203a3e:	99a080e7          	jalr	-1638(ra) # 802003d4 <panic>
    80203a42:	b7f9                	j	80203a10 <filedup+0x22>

0000000080203a44 <fileclose>:

void fileclose(struct file *f) {
    80203a44:	7179                	add	sp,sp,-48
    80203a46:	f406                	sd	ra,40(sp)
    80203a48:	f022                	sd	s0,32(sp)
    80203a4a:	ec26                	sd	s1,24(sp)
    80203a4c:	e84a                	sd	s2,16(sp)
    80203a4e:	e44e                	sd	s3,8(sp)
    80203a50:	1800                	add	s0,sp,48
    80203a52:	84aa                	mv	s1,a0
    acquire(&ftable.lock);
    80203a54:	0003d517          	auipc	a0,0x3d
    80203a58:	5ec50513          	add	a0,a0,1516 # 80241040 <ftable>
    80203a5c:	ffffd097          	auipc	ra,0xffffd
    80203a60:	dde080e7          	jalr	-546(ra) # 8020083a <acquire>
    if (f->ref < 1) {
    80203a64:	40dc                	lw	a5,4(s1)
    80203a66:	04f05b63          	blez	a5,80203abc <fileclose+0x78>
        panic("fileclose");
    }
    f->ref--;
    80203a6a:	40dc                	lw	a5,4(s1)
    80203a6c:	37fd                	addw	a5,a5,-1
    80203a6e:	0007871b          	sext.w	a4,a5
    80203a72:	c0dc                	sw	a5,4(s1)
    if (f->ref > 0) {
    80203a74:	04e04d63          	bgtz	a4,80203ace <fileclose+0x8a>
        release(&ftable.lock);
        return;
    }
    int type = f->type;
    80203a78:	0004a903          	lw	s2,0(s1)
    struct inode *ip = f->ip;
    80203a7c:	0104b983          	ld	s3,16(s1)
    release(&ftable.lock);
    80203a80:	0003d517          	auipc	a0,0x3d
    80203a84:	5c050513          	add	a0,a0,1472 # 80241040 <ftable>
    80203a88:	ffffd097          	auipc	ra,0xffffd
    80203a8c:	ea4080e7          	jalr	-348(ra) # 8020092c <release>

    if (type == FD_INODE) {
    80203a90:	4785                	li	a5,1
    80203a92:	04f90763          	beq	s2,a5,80203ae0 <fileclose+0x9c>
        begin_op();
        iput(ip);
        end_op();
    }

    f->type = FD_NONE;
    80203a96:	0004a023          	sw	zero,0(s1)
    f->readable = 0;
    80203a9a:	00048423          	sb	zero,8(s1)
    f->writable = 0;
    80203a9e:	000484a3          	sb	zero,9(s1)
    f->ip = 0;
    80203aa2:	0004b823          	sd	zero,16(s1)
    f->off = 0;
    80203aa6:	0004ac23          	sw	zero,24(s1)
    f->major = 0;
    80203aaa:	00049e23          	sh	zero,28(s1)
}
    80203aae:	70a2                	ld	ra,40(sp)
    80203ab0:	7402                	ld	s0,32(sp)
    80203ab2:	64e2                	ld	s1,24(sp)
    80203ab4:	6942                	ld	s2,16(sp)
    80203ab6:	69a2                	ld	s3,8(sp)
    80203ab8:	6145                	add	sp,sp,48
    80203aba:	8082                	ret
        panic("fileclose");
    80203abc:	00003517          	auipc	a0,0x3
    80203ac0:	e5c50513          	add	a0,a0,-420 # 80206918 <syscalls+0x348>
    80203ac4:	ffffd097          	auipc	ra,0xffffd
    80203ac8:	910080e7          	jalr	-1776(ra) # 802003d4 <panic>
    80203acc:	bf79                	j	80203a6a <fileclose+0x26>
        release(&ftable.lock);
    80203ace:	0003d517          	auipc	a0,0x3d
    80203ad2:	57250513          	add	a0,a0,1394 # 80241040 <ftable>
    80203ad6:	ffffd097          	auipc	ra,0xffffd
    80203ada:	e56080e7          	jalr	-426(ra) # 8020092c <release>
        return;
    80203ade:	bfc1                	j	80203aae <fileclose+0x6a>
        begin_op();
    80203ae0:	00000097          	auipc	ra,0x0
    80203ae4:	a82080e7          	jalr	-1406(ra) # 80203562 <begin_op>
        iput(ip);
    80203ae8:	854e                	mv	a0,s3
    80203aea:	fffff097          	auipc	ra,0xfffff
    80203aee:	07c080e7          	jalr	124(ra) # 80202b66 <iput>
        end_op();
    80203af2:	00000097          	auipc	ra,0x0
    80203af6:	aea080e7          	jalr	-1302(ra) # 802035dc <end_op>
    80203afa:	bf71                	j	80203a96 <fileclose+0x52>

0000000080203afc <filestat>:

int filestat(struct file *f, uint64 addr) {
    if (f->type != FD_INODE) {
    80203afc:	4118                	lw	a4,0(a0)
    80203afe:	4785                	li	a5,1
    80203b00:	04f71163          	bne	a4,a5,80203b42 <filestat+0x46>
int filestat(struct file *f, uint64 addr) {
    80203b04:	1101                	add	sp,sp,-32
    80203b06:	ec06                	sd	ra,24(sp)
    80203b08:	e822                	sd	s0,16(sp)
    80203b0a:	e426                	sd	s1,8(sp)
    80203b0c:	e04a                	sd	s2,0(sp)
    80203b0e:	1000                	add	s0,sp,32
    80203b10:	84aa                	mv	s1,a0
    80203b12:	892e                	mv	s2,a1
        return -1;
    }
    struct stat *st = (struct stat*)addr;
    ilock(f->ip);
    80203b14:	6908                	ld	a0,16(a0)
    80203b16:	fffff097          	auipc	ra,0xfffff
    80203b1a:	e10080e7          	jalr	-496(ra) # 80202926 <ilock>
    stati(f->ip, st);
    80203b1e:	85ca                	mv	a1,s2
    80203b20:	6888                	ld	a0,16(s1)
    80203b22:	fffff097          	auipc	ra,0xfffff
    80203b26:	0f4080e7          	jalr	244(ra) # 80202c16 <stati>
    iunlock(f->ip);
    80203b2a:	6888                	ld	a0,16(s1)
    80203b2c:	fffff097          	auipc	ra,0xfffff
    80203b30:	ec0080e7          	jalr	-320(ra) # 802029ec <iunlock>
    return 0;
    80203b34:	4501                	li	a0,0
}
    80203b36:	60e2                	ld	ra,24(sp)
    80203b38:	6442                	ld	s0,16(sp)
    80203b3a:	64a2                	ld	s1,8(sp)
    80203b3c:	6902                	ld	s2,0(sp)
    80203b3e:	6105                	add	sp,sp,32
    80203b40:	8082                	ret
        return -1;
    80203b42:	557d                	li	a0,-1
}
    80203b44:	8082                	ret

0000000080203b46 <fileread>:

int fileread(struct file *f, uint64 addr, int n) {
    80203b46:	7179                	add	sp,sp,-48
    80203b48:	f406                	sd	ra,40(sp)
    80203b4a:	f022                	sd	s0,32(sp)
    80203b4c:	ec26                	sd	s1,24(sp)
    80203b4e:	e84a                	sd	s2,16(sp)
    80203b50:	e44e                	sd	s3,8(sp)
    80203b52:	1800                	add	s0,sp,48
    if (!f->readable) {
    80203b54:	00854783          	lbu	a5,8(a0)
    80203b58:	c3c1                	beqz	a5,80203bd8 <fileread+0x92>
    80203b5a:	84aa                	mv	s1,a0
    80203b5c:	892e                	mv	s2,a1
    80203b5e:	89b2                	mv	s3,a2
        return -1;
    }
    if (f->type == FD_INODE) {
    80203b60:	411c                	lw	a5,0(a0)
    80203b62:	4705                	li	a4,1
    80203b64:	04e78063          	beq	a5,a4,80203ba4 <fileread+0x5e>
        if (r > 0) {
            f->off += r;
        }
        iunlock(f->ip);
        return r;
    } else if (f->type == FD_DEVICE) {
    80203b68:	4709                	li	a4,2
    80203b6a:	06e79963          	bne	a5,a4,80203bdc <fileread+0x96>
        if (f->major < 0 || f->major >= NDEV || !devsw[f->major].read) {
    80203b6e:	01c51783          	lh	a5,28(a0)
    80203b72:	03079693          	sll	a3,a5,0x30
    80203b76:	92c1                	srl	a3,a3,0x30
    80203b78:	4725                	li	a4,9
    80203b7a:	06d76363          	bltu	a4,a3,80203be0 <fileread+0x9a>
    80203b7e:	0792                	sll	a5,a5,0x4
    80203b80:	0003d697          	auipc	a3,0x3d
    80203b84:	42068693          	add	a3,a3,1056 # 80240fa0 <devsw>
    80203b88:	97b6                	add	a5,a5,a3
    80203b8a:	639c                	ld	a5,0(a5)
    80203b8c:	cfa1                	beqz	a5,80203be4 <fileread+0x9e>
            return -1;
        }
        return devsw[f->major].read(1, addr, n);
    80203b8e:	4505                	li	a0,1
    80203b90:	9782                	jalr	a5
    80203b92:	892a                	mv	s2,a0
    }
    return -1;
}
    80203b94:	854a                	mv	a0,s2
    80203b96:	70a2                	ld	ra,40(sp)
    80203b98:	7402                	ld	s0,32(sp)
    80203b9a:	64e2                	ld	s1,24(sp)
    80203b9c:	6942                	ld	s2,16(sp)
    80203b9e:	69a2                	ld	s3,8(sp)
    80203ba0:	6145                	add	sp,sp,48
    80203ba2:	8082                	ret
        ilock(f->ip);
    80203ba4:	6908                	ld	a0,16(a0)
    80203ba6:	fffff097          	auipc	ra,0xfffff
    80203baa:	d80080e7          	jalr	-640(ra) # 80202926 <ilock>
        int r = readi(f->ip, 0, addr, f->off, n);
    80203bae:	874e                	mv	a4,s3
    80203bb0:	4c94                	lw	a3,24(s1)
    80203bb2:	864a                	mv	a2,s2
    80203bb4:	4581                	li	a1,0
    80203bb6:	6888                	ld	a0,16(s1)
    80203bb8:	fffff097          	auipc	ra,0xfffff
    80203bbc:	08a080e7          	jalr	138(ra) # 80202c42 <readi>
    80203bc0:	892a                	mv	s2,a0
        if (r > 0) {
    80203bc2:	00a05563          	blez	a0,80203bcc <fileread+0x86>
            f->off += r;
    80203bc6:	4c9c                	lw	a5,24(s1)
    80203bc8:	9fa9                	addw	a5,a5,a0
    80203bca:	cc9c                	sw	a5,24(s1)
        iunlock(f->ip);
    80203bcc:	6888                	ld	a0,16(s1)
    80203bce:	fffff097          	auipc	ra,0xfffff
    80203bd2:	e1e080e7          	jalr	-482(ra) # 802029ec <iunlock>
        return r;
    80203bd6:	bf7d                	j	80203b94 <fileread+0x4e>
        return -1;
    80203bd8:	597d                	li	s2,-1
    80203bda:	bf6d                	j	80203b94 <fileread+0x4e>
    return -1;
    80203bdc:	597d                	li	s2,-1
    80203bde:	bf5d                	j	80203b94 <fileread+0x4e>
            return -1;
    80203be0:	597d                	li	s2,-1
    80203be2:	bf4d                	j	80203b94 <fileread+0x4e>
    80203be4:	597d                	li	s2,-1
    80203be6:	b77d                	j	80203b94 <fileread+0x4e>

0000000080203be8 <filewrite>:

int filewrite(struct file *f, uint64 addr, int n) {
    if (!f->writable) {
    80203be8:	00954783          	lbu	a5,9(a0)
    80203bec:	12078563          	beqz	a5,80203d16 <filewrite+0x12e>
int filewrite(struct file *f, uint64 addr, int n) {
    80203bf0:	711d                	add	sp,sp,-96
    80203bf2:	ec86                	sd	ra,88(sp)
    80203bf4:	e8a2                	sd	s0,80(sp)
    80203bf6:	e4a6                	sd	s1,72(sp)
    80203bf8:	e0ca                	sd	s2,64(sp)
    80203bfa:	fc4e                	sd	s3,56(sp)
    80203bfc:	f852                	sd	s4,48(sp)
    80203bfe:	f456                	sd	s5,40(sp)
    80203c00:	f05a                	sd	s6,32(sp)
    80203c02:	ec5e                	sd	s7,24(sp)
    80203c04:	e862                	sd	s8,16(sp)
    80203c06:	e466                	sd	s9,8(sp)
    80203c08:	1080                	add	s0,sp,96
    80203c0a:	892a                	mv	s2,a0
    80203c0c:	8b2e                	mv	s6,a1
    80203c0e:	8a32                	mv	s4,a2
        return -1;
    }
    if (f->type == FD_DEVICE) {
    80203c10:	411c                	lw	a5,0(a0)
    80203c12:	4709                	li	a4,2
    80203c14:	02e78363          	beq	a5,a4,80203c3a <filewrite+0x52>
        if (f->major < 0 || f->major >= NDEV || !devsw[f->major].write) {
            return -1;
        }
        return devsw[f->major].write(1, addr, n);
    }
    if (f->type != FD_INODE) {
    80203c18:	4705                	li	a4,1
    80203c1a:	10e79463          	bne	a5,a4,80203d22 <filewrite+0x13a>
        return -1;
    }

    int max = ((MAXOPBLOCKS - 1 - 1 - 2) / 2) * BSIZE;
    int i = 0;
    while (i < n) {
    80203c1e:	0ec05a63          	blez	a2,80203d12 <filewrite+0x12a>
    int i = 0;
    80203c22:	4981                	li	s3,0
        int n1 = n - i;
        if (n1 > max) {
    80203c24:	6b85                	lui	s7,0x1
    80203c26:	c00b8b93          	add	s7,s7,-1024 # c00 <_start-0x801ff400>
    80203c2a:	6c05                	lui	s8,0x1
    80203c2c:	c00c0c1b          	addw	s8,s8,-1024 # c00 <_start-0x801ff400>
        end_op();
        if (r < 0) {
            break;
        }
        if (r != n1) {
            panic("short filewrite");
    80203c30:	00003c97          	auipc	s9,0x3
    80203c34:	cf8c8c93          	add	s9,s9,-776 # 80206928 <syscalls+0x358>
    80203c38:	a0a5                	j	80203ca0 <filewrite+0xb8>
        if (f->major < 0 || f->major >= NDEV || !devsw[f->major].write) {
    80203c3a:	01c51783          	lh	a5,28(a0)
    80203c3e:	03079693          	sll	a3,a5,0x30
    80203c42:	92c1                	srl	a3,a3,0x30
    80203c44:	4725                	li	a4,9
    80203c46:	0cd76a63          	bltu	a4,a3,80203d1a <filewrite+0x132>
    80203c4a:	0792                	sll	a5,a5,0x4
    80203c4c:	0003d717          	auipc	a4,0x3d
    80203c50:	35470713          	add	a4,a4,852 # 80240fa0 <devsw>
    80203c54:	97ba                	add	a5,a5,a4
    80203c56:	679c                	ld	a5,8(a5)
    80203c58:	c3f9                	beqz	a5,80203d1e <filewrite+0x136>
        return devsw[f->major].write(1, addr, n);
    80203c5a:	4505                	li	a0,1
    80203c5c:	9782                	jalr	a5
    80203c5e:	a005                	j	80203c7e <filewrite+0x96>
        iunlock(f->ip);
    80203c60:	01093503          	ld	a0,16(s2)
    80203c64:	fffff097          	auipc	ra,0xfffff
    80203c68:	d88080e7          	jalr	-632(ra) # 802029ec <iunlock>
        end_op();
    80203c6c:	00000097          	auipc	ra,0x0
    80203c70:	970080e7          	jalr	-1680(ra) # 802035dc <end_op>
        if (r < 0) {
    80203c74:	0804d763          	bgez	s1,80203d02 <filewrite+0x11a>
        }
        i += r;
    }
    return i == n ? n : -1;
    80203c78:	0b3a1763          	bne	s4,s3,80203d26 <filewrite+0x13e>
    80203c7c:	8552                	mv	a0,s4
}
    80203c7e:	60e6                	ld	ra,88(sp)
    80203c80:	6446                	ld	s0,80(sp)
    80203c82:	64a6                	ld	s1,72(sp)
    80203c84:	6906                	ld	s2,64(sp)
    80203c86:	79e2                	ld	s3,56(sp)
    80203c88:	7a42                	ld	s4,48(sp)
    80203c8a:	7aa2                	ld	s5,40(sp)
    80203c8c:	7b02                	ld	s6,32(sp)
    80203c8e:	6be2                	ld	s7,24(sp)
    80203c90:	6c42                	ld	s8,16(sp)
    80203c92:	6ca2                	ld	s9,8(sp)
    80203c94:	6125                	add	sp,sp,96
    80203c96:	8082                	ret
        i += r;
    80203c98:	013489bb          	addw	s3,s1,s3
    while (i < n) {
    80203c9c:	fd49dee3          	bge	s3,s4,80203c78 <filewrite+0x90>
        int n1 = n - i;
    80203ca0:	413a04bb          	subw	s1,s4,s3
        if (n1 > max) {
    80203ca4:	0004879b          	sext.w	a5,s1
    80203ca8:	00fbd363          	bge	s7,a5,80203cae <filewrite+0xc6>
    80203cac:	84e2                	mv	s1,s8
    80203cae:	00048a9b          	sext.w	s5,s1
        begin_op();
    80203cb2:	00000097          	auipc	ra,0x0
    80203cb6:	8b0080e7          	jalr	-1872(ra) # 80203562 <begin_op>
        ilock(f->ip);
    80203cba:	01093503          	ld	a0,16(s2)
    80203cbe:	fffff097          	auipc	ra,0xfffff
    80203cc2:	c68080e7          	jalr	-920(ra) # 80202926 <ilock>
        int r = writei(f->ip, 0, addr + i, f->off, n1);
    80203cc6:	8756                	mv	a4,s5
    80203cc8:	01892683          	lw	a3,24(s2)
    80203ccc:	01698633          	add	a2,s3,s6
    80203cd0:	4581                	li	a1,0
    80203cd2:	01093503          	ld	a0,16(s2)
    80203cd6:	fffff097          	auipc	ra,0xfffff
    80203cda:	04e080e7          	jalr	78(ra) # 80202d24 <writei>
    80203cde:	84aa                	mv	s1,a0
        if (r > 0) {
    80203ce0:	f8a050e3          	blez	a0,80203c60 <filewrite+0x78>
            f->off += r;
    80203ce4:	01892783          	lw	a5,24(s2)
    80203ce8:	9fa9                	addw	a5,a5,a0
    80203cea:	00f92c23          	sw	a5,24(s2)
        iunlock(f->ip);
    80203cee:	01093503          	ld	a0,16(s2)
    80203cf2:	fffff097          	auipc	ra,0xfffff
    80203cf6:	cfa080e7          	jalr	-774(ra) # 802029ec <iunlock>
        end_op();
    80203cfa:	00000097          	auipc	ra,0x0
    80203cfe:	8e2080e7          	jalr	-1822(ra) # 802035dc <end_op>
        if (r != n1) {
    80203d02:	f89a8be3          	beq	s5,s1,80203c98 <filewrite+0xb0>
            panic("short filewrite");
    80203d06:	8566                	mv	a0,s9
    80203d08:	ffffc097          	auipc	ra,0xffffc
    80203d0c:	6cc080e7          	jalr	1740(ra) # 802003d4 <panic>
    80203d10:	b761                	j	80203c98 <filewrite+0xb0>
    int i = 0;
    80203d12:	4981                	li	s3,0
    80203d14:	b795                	j	80203c78 <filewrite+0x90>
        return -1;
    80203d16:	557d                	li	a0,-1
}
    80203d18:	8082                	ret
            return -1;
    80203d1a:	557d                	li	a0,-1
    80203d1c:	b78d                	j	80203c7e <filewrite+0x96>
    80203d1e:	557d                	li	a0,-1
    80203d20:	bfb9                	j	80203c7e <filewrite+0x96>
        return -1;
    80203d22:	557d                	li	a0,-1
    80203d24:	bfa9                	j	80203c7e <filewrite+0x96>
    return i == n ? n : -1;
    80203d26:	557d                	li	a0,-1
    80203d28:	bf99                	j	80203c7e <filewrite+0x96>

0000000080203d2a <argfd>:
    iunlockput(dp);

    return ip;
}

static int argfd(int n, int *pfd, struct file **pf) {
    80203d2a:	7179                	add	sp,sp,-48
    80203d2c:	f406                	sd	ra,40(sp)
    80203d2e:	f022                	sd	s0,32(sp)
    80203d30:	ec26                	sd	s1,24(sp)
    80203d32:	e84a                	sd	s2,16(sp)
    80203d34:	1800                	add	s0,sp,48
    80203d36:	892e                	mv	s2,a1
    80203d38:	84b2                	mv	s1,a2
    int fd;
    struct file *f;
    if (argint(n, &fd) < 0)
    80203d3a:	fdc40593          	add	a1,s0,-36
    80203d3e:	ffffe097          	auipc	ra,0xffffe
    80203d42:	e8e080e7          	jalr	-370(ra) # 80201bcc <argint>
    80203d46:	04054063          	bltz	a0,80203d86 <argfd+0x5c>
        return -1;
    if (fd < 0 || fd >= NOFILE || (f = myproc()->ofile[fd]) == 0)
    80203d4a:	fdc42703          	lw	a4,-36(s0)
    80203d4e:	47bd                	li	a5,15
    80203d50:	02e7ed63          	bltu	a5,a4,80203d8a <argfd+0x60>
    80203d54:	ffffd097          	auipc	ra,0xffffd
    80203d58:	654080e7          	jalr	1620(ra) # 802013a8 <myproc>
    80203d5c:	fdc42703          	lw	a4,-36(s0)
    80203d60:	01a70793          	add	a5,a4,26
    80203d64:	078e                	sll	a5,a5,0x3
    80203d66:	953e                	add	a0,a0,a5
    80203d68:	651c                	ld	a5,8(a0)
    80203d6a:	c395                	beqz	a5,80203d8e <argfd+0x64>
        return -1;
    if (pfd)
    80203d6c:	00090463          	beqz	s2,80203d74 <argfd+0x4a>
        *pfd = fd;
    80203d70:	00e92023          	sw	a4,0(s2)
    if (pf)
        *pf = f;
    return 0;
    80203d74:	4501                	li	a0,0
    if (pf)
    80203d76:	c091                	beqz	s1,80203d7a <argfd+0x50>
        *pf = f;
    80203d78:	e09c                	sd	a5,0(s1)
}
    80203d7a:	70a2                	ld	ra,40(sp)
    80203d7c:	7402                	ld	s0,32(sp)
    80203d7e:	64e2                	ld	s1,24(sp)
    80203d80:	6942                	ld	s2,16(sp)
    80203d82:	6145                	add	sp,sp,48
    80203d84:	8082                	ret
        return -1;
    80203d86:	557d                	li	a0,-1
    80203d88:	bfcd                	j	80203d7a <argfd+0x50>
        return -1;
    80203d8a:	557d                	li	a0,-1
    80203d8c:	b7fd                	j	80203d7a <argfd+0x50>
    80203d8e:	557d                	li	a0,-1
    80203d90:	b7ed                	j	80203d7a <argfd+0x50>

0000000080203d92 <fdalloc>:

static int fdalloc(struct file *f) {
    80203d92:	1101                	add	sp,sp,-32
    80203d94:	ec06                	sd	ra,24(sp)
    80203d96:	e822                	sd	s0,16(sp)
    80203d98:	e426                	sd	s1,8(sp)
    80203d9a:	1000                	add	s0,sp,32
    80203d9c:	84aa                	mv	s1,a0
    struct proc *p = myproc();
    80203d9e:	ffffd097          	auipc	ra,0xffffd
    80203da2:	60a080e7          	jalr	1546(ra) # 802013a8 <myproc>
    80203da6:	862a                	mv	a2,a0
    for (int fd = 0; fd < NOFILE; fd++) {
    80203da8:	0d850793          	add	a5,a0,216
    80203dac:	4501                	li	a0,0
    80203dae:	46c1                	li	a3,16
        if (p->ofile[fd] == 0) {
    80203db0:	6398                	ld	a4,0(a5)
    80203db2:	cb19                	beqz	a4,80203dc8 <fdalloc+0x36>
    for (int fd = 0; fd < NOFILE; fd++) {
    80203db4:	2505                	addw	a0,a0,1
    80203db6:	07a1                	add	a5,a5,8
    80203db8:	fed51ce3          	bne	a0,a3,80203db0 <fdalloc+0x1e>
            p->ofile[fd] = f;
            return fd;
        }
    }
    return -1;
    80203dbc:	557d                	li	a0,-1
}
    80203dbe:	60e2                	ld	ra,24(sp)
    80203dc0:	6442                	ld	s0,16(sp)
    80203dc2:	64a2                	ld	s1,8(sp)
    80203dc4:	6105                	add	sp,sp,32
    80203dc6:	8082                	ret
            p->ofile[fd] = f;
    80203dc8:	01a50793          	add	a5,a0,26
    80203dcc:	078e                	sll	a5,a5,0x3
    80203dce:	963e                	add	a2,a2,a5
    80203dd0:	e604                	sd	s1,8(a2)
            return fd;
    80203dd2:	b7f5                	j	80203dbe <fdalloc+0x2c>

0000000080203dd4 <validate_addr>:
    if (len < 0) return 0;
    80203dd4:	0405c963          	bltz	a1,80203e26 <validate_addr+0x52>
static int validate_addr(uint64 va, int len) {
    80203dd8:	7179                	add	sp,sp,-48
    80203dda:	f406                	sd	ra,40(sp)
    80203ddc:	f022                	sd	s0,32(sp)
    80203dde:	ec26                	sd	s1,24(sp)
    80203de0:	e84a                	sd	s2,16(sp)
    80203de2:	e44e                	sd	s3,8(sp)
    80203de4:	e052                	sd	s4,0(sp)
    80203de6:	1800                	add	s0,sp,48
    80203de8:	84aa                	mv	s1,a0
    uint64 end = va + len;
    80203dea:	00a58933          	add	s2,a1,a0
    if (end < start) return 0;
    80203dee:	4501                	li	a0,0
    80203df0:	04996063          	bltu	s2,s1,80203e30 <validate_addr+0x5c>
    for (uint64 a = PGROUNDDOWN(start); a < end; a += PGSIZE) {
    80203df4:	77fd                	lui	a5,0xfffff
    80203df6:	8cfd                	and	s1,s1,a5
    80203df8:	0324f963          	bgeu	s1,s2,80203e2a <validate_addr+0x56>
        pte_t *pte = walk_lookup(kernel_pagetable, a);
    80203dfc:	0000c997          	auipc	s3,0xc
    80203e00:	20498993          	add	s3,s3,516 # 80210000 <kernel_pagetable>
    for (uint64 a = PGROUNDDOWN(start); a < end; a += PGSIZE) {
    80203e04:	6a05                	lui	s4,0x1
        pte_t *pte = walk_lookup(kernel_pagetable, a);
    80203e06:	85a6                	mv	a1,s1
    80203e08:	0009b503          	ld	a0,0(s3)
    80203e0c:	ffffd097          	auipc	ra,0xffffd
    80203e10:	fb6080e7          	jalr	-74(ra) # 80200dc2 <walk_lookup>
        if (pte == 0 || (*pte & PTE_V) == 0) {
    80203e14:	cd09                	beqz	a0,80203e2e <validate_addr+0x5a>
    80203e16:	611c                	ld	a5,0(a0)
    80203e18:	8b85                	and	a5,a5,1
    80203e1a:	c39d                	beqz	a5,80203e40 <validate_addr+0x6c>
    for (uint64 a = PGROUNDDOWN(start); a < end; a += PGSIZE) {
    80203e1c:	94d2                	add	s1,s1,s4
    80203e1e:	ff24e4e3          	bltu	s1,s2,80203e06 <validate_addr+0x32>
    return 1;
    80203e22:	4505                	li	a0,1
    80203e24:	a031                	j	80203e30 <validate_addr+0x5c>
    if (len < 0) return 0;
    80203e26:	4501                	li	a0,0
}
    80203e28:	8082                	ret
    return 1;
    80203e2a:	4505                	li	a0,1
    80203e2c:	a011                	j	80203e30 <validate_addr+0x5c>
            return 0;
    80203e2e:	4501                	li	a0,0
}
    80203e30:	70a2                	ld	ra,40(sp)
    80203e32:	7402                	ld	s0,32(sp)
    80203e34:	64e2                	ld	s1,24(sp)
    80203e36:	6942                	ld	s2,16(sp)
    80203e38:	69a2                	ld	s3,8(sp)
    80203e3a:	6a02                	ld	s4,0(sp)
    80203e3c:	6145                	add	sp,sp,48
    80203e3e:	8082                	ret
            return 0;
    80203e40:	4501                	li	a0,0
    80203e42:	b7fd                	j	80203e30 <validate_addr+0x5c>

0000000080203e44 <create>:
static struct inode *create(char *path, short type, short major, short minor) {
    80203e44:	715d                	add	sp,sp,-80
    80203e46:	e486                	sd	ra,72(sp)
    80203e48:	e0a2                	sd	s0,64(sp)
    80203e4a:	fc26                	sd	s1,56(sp)
    80203e4c:	f84a                	sd	s2,48(sp)
    80203e4e:	f44e                	sd	s3,40(sp)
    80203e50:	f052                	sd	s4,32(sp)
    80203e52:	ec56                	sd	s5,24(sp)
    80203e54:	0880                	add	s0,sp,80
    80203e56:	84aa                	mv	s1,a0
    80203e58:	8a2e                	mv	s4,a1
    80203e5a:	89b2                	mv	s3,a2
    80203e5c:	8936                	mv	s2,a3
    if ((dp = nameiparent(path, name)) == 0) {
    80203e5e:	fb040593          	add	a1,s0,-80
    80203e62:	fffff097          	auipc	ra,0xfffff
    80203e66:	2fc080e7          	jalr	764(ra) # 8020315e <nameiparent>
    80203e6a:	8aaa                	mv	s5,a0
    80203e6c:	c125                	beqz	a0,80203ecc <create+0x88>
    ilock(dp);
    80203e6e:	fffff097          	auipc	ra,0xfffff
    80203e72:	ab8080e7          	jalr	-1352(ra) # 80202926 <ilock>
    if ((ip = dirlookup(dp, name, 0)) != 0) {
    80203e76:	4601                	li	a2,0
    80203e78:	fb040593          	add	a1,s0,-80
    80203e7c:	8556                	mv	a0,s5
    80203e7e:	fffff097          	auipc	ra,0xfffff
    80203e82:	fdc080e7          	jalr	-36(ra) # 80202e5a <dirlookup>
    80203e86:	84aa                	mv	s1,a0
    80203e88:	cd29                	beqz	a0,80203ee2 <create+0x9e>
        iunlockput(dp);
    80203e8a:	8556                	mv	a0,s5
    80203e8c:	fffff097          	auipc	ra,0xfffff
    80203e90:	d62080e7          	jalr	-670(ra) # 80202bee <iunlockput>
        ilock(ip);
    80203e94:	8526                	mv	a0,s1
    80203e96:	fffff097          	auipc	ra,0xfffff
    80203e9a:	a90080e7          	jalr	-1392(ra) # 80202926 <ilock>
        if (type == T_FILE && ip->type == T_FILE)
    80203e9e:	4789                	li	a5,2
    80203ea0:	00fa1663          	bne	s4,a5,80203eac <create+0x68>
    80203ea4:	04449703          	lh	a4,68(s1)
    80203ea8:	00f70863          	beq	a4,a5,80203eb8 <create+0x74>
        iunlockput(ip);
    80203eac:	8526                	mv	a0,s1
    80203eae:	fffff097          	auipc	ra,0xfffff
    80203eb2:	d40080e7          	jalr	-704(ra) # 80202bee <iunlockput>
        return 0;
    80203eb6:	4481                	li	s1,0
}
    80203eb8:	8526                	mv	a0,s1
    80203eba:	60a6                	ld	ra,72(sp)
    80203ebc:	6406                	ld	s0,64(sp)
    80203ebe:	74e2                	ld	s1,56(sp)
    80203ec0:	7942                	ld	s2,48(sp)
    80203ec2:	79a2                	ld	s3,40(sp)
    80203ec4:	7a02                	ld	s4,32(sp)
    80203ec6:	6ae2                	ld	s5,24(sp)
    80203ec8:	6161                	add	sp,sp,80
    80203eca:	8082                	ret
        printf("create: nameiparent failed for %s\n", path); // DEBUG
    80203ecc:	85a6                	mv	a1,s1
    80203ece:	00003517          	auipc	a0,0x3
    80203ed2:	a6a50513          	add	a0,a0,-1430 # 80206938 <syscalls+0x368>
    80203ed6:	ffffc097          	auipc	ra,0xffffc
    80203eda:	27e080e7          	jalr	638(ra) # 80200154 <printf>
        return 0;
    80203ede:	84d6                	mv	s1,s5
    80203ee0:	bfe1                	j	80203eb8 <create+0x74>
    if ((ip = ialloc(dp->dev, type)) == 0)
    80203ee2:	85d2                	mv	a1,s4
    80203ee4:	000aa503          	lw	a0,0(s5)
    80203ee8:	fffff097          	auipc	ra,0xfffff
    80203eec:	93a080e7          	jalr	-1734(ra) # 80202822 <ialloc>
    80203ef0:	84aa                	mv	s1,a0
    80203ef2:	c521                	beqz	a0,80203f3a <create+0xf6>
    ilock(ip);
    80203ef4:	8526                	mv	a0,s1
    80203ef6:	fffff097          	auipc	ra,0xfffff
    80203efa:	a30080e7          	jalr	-1488(ra) # 80202926 <ilock>
    ip->major = major;
    80203efe:	05349323          	sh	s3,70(s1)
    ip->minor = minor;
    80203f02:	05249423          	sh	s2,72(s1)
    ip->nlink = 1;
    80203f06:	4905                	li	s2,1
    80203f08:	05249523          	sh	s2,74(s1)
    iupdate(ip);
    80203f0c:	8526                	mv	a0,s1
    80203f0e:	fffff097          	auipc	ra,0xfffff
    80203f12:	b1e080e7          	jalr	-1250(ra) # 80202a2c <iupdate>
    if (type == T_DIR) {
    80203f16:	032a0b63          	beq	s4,s2,80203f4c <create+0x108>
    if (dirlink(dp, name, ip->inum) < 0)
    80203f1a:	40d0                	lw	a2,4(s1)
    80203f1c:	fb040593          	add	a1,s0,-80
    80203f20:	8556                	mv	a0,s5
    80203f22:	fffff097          	auipc	ra,0xfffff
    80203f26:	ff6080e7          	jalr	-10(ra) # 80202f18 <dirlink>
    80203f2a:	06054d63          	bltz	a0,80203fa4 <create+0x160>
    iunlockput(dp);
    80203f2e:	8556                	mv	a0,s5
    80203f30:	fffff097          	auipc	ra,0xfffff
    80203f34:	cbe080e7          	jalr	-834(ra) # 80202bee <iunlockput>
    return ip;
    80203f38:	b741                	j	80203eb8 <create+0x74>
        panic("create: ialloc");
    80203f3a:	00003517          	auipc	a0,0x3
    80203f3e:	a2650513          	add	a0,a0,-1498 # 80206960 <syscalls+0x390>
    80203f42:	ffffc097          	auipc	ra,0xffffc
    80203f46:	492080e7          	jalr	1170(ra) # 802003d4 <panic>
    80203f4a:	b76d                	j	80203ef4 <create+0xb0>
        dp->nlink++;  
    80203f4c:	04aad783          	lhu	a5,74(s5)
    80203f50:	2785                	addw	a5,a5,1 # fffffffffffff001 <__bss_end+0xffffffff7fdbd1e1>
    80203f52:	04fa9523          	sh	a5,74(s5)
        iupdate(dp);
    80203f56:	8556                	mv	a0,s5
    80203f58:	fffff097          	auipc	ra,0xfffff
    80203f5c:	ad4080e7          	jalr	-1324(ra) # 80202a2c <iupdate>
        if (dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80203f60:	40d0                	lw	a2,4(s1)
    80203f62:	00003597          	auipc	a1,0x3
    80203f66:	84658593          	add	a1,a1,-1978 # 802067a8 <syscalls+0x1d8>
    80203f6a:	8526                	mv	a0,s1
    80203f6c:	fffff097          	auipc	ra,0xfffff
    80203f70:	fac080e7          	jalr	-84(ra) # 80202f18 <dirlink>
    80203f74:	00054f63          	bltz	a0,80203f92 <create+0x14e>
    80203f78:	004aa603          	lw	a2,4(s5)
    80203f7c:	00003597          	auipc	a1,0x3
    80203f80:	83458593          	add	a1,a1,-1996 # 802067b0 <syscalls+0x1e0>
    80203f84:	8526                	mv	a0,s1
    80203f86:	fffff097          	auipc	ra,0xfffff
    80203f8a:	f92080e7          	jalr	-110(ra) # 80202f18 <dirlink>
    80203f8e:	f80556e3          	bgez	a0,80203f1a <create+0xd6>
            panic("create dots");
    80203f92:	00003517          	auipc	a0,0x3
    80203f96:	9de50513          	add	a0,a0,-1570 # 80206970 <syscalls+0x3a0>
    80203f9a:	ffffc097          	auipc	ra,0xffffc
    80203f9e:	43a080e7          	jalr	1082(ra) # 802003d4 <panic>
    80203fa2:	bfa5                	j	80203f1a <create+0xd6>
        panic("create: dirlink");
    80203fa4:	00003517          	auipc	a0,0x3
    80203fa8:	9dc50513          	add	a0,a0,-1572 # 80206980 <syscalls+0x3b0>
    80203fac:	ffffc097          	auipc	ra,0xffffc
    80203fb0:	428080e7          	jalr	1064(ra) # 802003d4 <panic>
    80203fb4:	bfad                	j	80203f2e <create+0xea>

0000000080203fb6 <sys_dup>:

int sys_dup(void) {
    80203fb6:	7179                	add	sp,sp,-48
    80203fb8:	f406                	sd	ra,40(sp)
    80203fba:	f022                	sd	s0,32(sp)
    80203fbc:	ec26                	sd	s1,24(sp)
    80203fbe:	e84a                	sd	s2,16(sp)
    80203fc0:	1800                	add	s0,sp,48
    struct file *f;
    if (argfd(0, 0, &f) < 0)
    80203fc2:	fd840613          	add	a2,s0,-40
    80203fc6:	4581                	li	a1,0
    80203fc8:	4501                	li	a0,0
    80203fca:	00000097          	auipc	ra,0x0
    80203fce:	d60080e7          	jalr	-672(ra) # 80203d2a <argfd>
    80203fd2:	02054863          	bltz	a0,80204002 <sys_dup+0x4c>
        return -1;
    int fd = fdalloc(f);
    80203fd6:	fd843903          	ld	s2,-40(s0)
    80203fda:	854a                	mv	a0,s2
    80203fdc:	00000097          	auipc	ra,0x0
    80203fe0:	db6080e7          	jalr	-586(ra) # 80203d92 <fdalloc>
    80203fe4:	84aa                	mv	s1,a0
    if (fd < 0)
    80203fe6:	02054063          	bltz	a0,80204006 <sys_dup+0x50>
        return -1;
    filedup(f);
    80203fea:	854a                	mv	a0,s2
    80203fec:	00000097          	auipc	ra,0x0
    80203ff0:	a02080e7          	jalr	-1534(ra) # 802039ee <filedup>
    return fd;
}
    80203ff4:	8526                	mv	a0,s1
    80203ff6:	70a2                	ld	ra,40(sp)
    80203ff8:	7402                	ld	s0,32(sp)
    80203ffa:	64e2                	ld	s1,24(sp)
    80203ffc:	6942                	ld	s2,16(sp)
    80203ffe:	6145                	add	sp,sp,48
    80204000:	8082                	ret
        return -1;
    80204002:	54fd                	li	s1,-1
    80204004:	bfc5                	j	80203ff4 <sys_dup+0x3e>
        return -1;
    80204006:	54fd                	li	s1,-1
    80204008:	b7f5                	j	80203ff4 <sys_dup+0x3e>

000000008020400a <sys_read>:

int sys_read(void) {
    8020400a:	7179                	add	sp,sp,-48
    8020400c:	f406                	sd	ra,40(sp)
    8020400e:	f022                	sd	s0,32(sp)
    80204010:	1800                	add	s0,sp,48
    struct file *f;
    uint64 p;
    int n;
    if (argfd(0, 0, &f) < 0 || argaddr(1, &p) < 0 || argint(2, &n) < 0)
    80204012:	fe840613          	add	a2,s0,-24
    80204016:	4581                	li	a1,0
    80204018:	4501                	li	a0,0
    8020401a:	00000097          	auipc	ra,0x0
    8020401e:	d10080e7          	jalr	-752(ra) # 80203d2a <argfd>
    80204022:	04054263          	bltz	a0,80204066 <sys_read+0x5c>
    80204026:	fe040593          	add	a1,s0,-32
    8020402a:	4505                	li	a0,1
    8020402c:	ffffe097          	auipc	ra,0xffffe
    80204030:	c2a080e7          	jalr	-982(ra) # 80201c56 <argaddr>
    80204034:	02054b63          	bltz	a0,8020406a <sys_read+0x60>
    80204038:	fdc40593          	add	a1,s0,-36
    8020403c:	4509                	li	a0,2
    8020403e:	ffffe097          	auipc	ra,0xffffe
    80204042:	b8e080e7          	jalr	-1138(ra) # 80201bcc <argint>
    80204046:	02054463          	bltz	a0,8020406e <sys_read+0x64>
        return -1;
    return fileread(f, p, n);
    8020404a:	fdc42603          	lw	a2,-36(s0)
    8020404e:	fe043583          	ld	a1,-32(s0)
    80204052:	fe843503          	ld	a0,-24(s0)
    80204056:	00000097          	auipc	ra,0x0
    8020405a:	af0080e7          	jalr	-1296(ra) # 80203b46 <fileread>
}
    8020405e:	70a2                	ld	ra,40(sp)
    80204060:	7402                	ld	s0,32(sp)
    80204062:	6145                	add	sp,sp,48
    80204064:	8082                	ret
        return -1;
    80204066:	557d                	li	a0,-1
    80204068:	bfdd                	j	8020405e <sys_read+0x54>
    8020406a:	557d                	li	a0,-1
    8020406c:	bfcd                	j	8020405e <sys_read+0x54>
    8020406e:	557d                	li	a0,-1
    80204070:	b7fd                	j	8020405e <sys_read+0x54>

0000000080204072 <sys_write>:

int sys_write(void) {
    80204072:	7139                	add	sp,sp,-64
    80204074:	fc06                	sd	ra,56(sp)
    80204076:	f822                	sd	s0,48(sp)
    80204078:	f426                	sd	s1,40(sp)
    8020407a:	f04a                	sd	s2,32(sp)
    8020407c:	0080                	add	s0,sp,64
    struct file *f;
    uint64 p;
    int n;
    int fd;

    if (argint(0, &fd) < 0) return -1;
    8020407e:	fc840593          	add	a1,s0,-56
    80204082:	4501                	li	a0,0
    80204084:	ffffe097          	auipc	ra,0xffffe
    80204088:	b48080e7          	jalr	-1208(ra) # 80201bcc <argint>
    8020408c:	0e054a63          	bltz	a0,80204180 <sys_write+0x10e>

    if ((fd == 1 || fd == 2) && myproc()->ofile[fd] == 0) {
    80204090:	fc842783          	lw	a5,-56(s0)
    80204094:	37fd                	addw	a5,a5,-1
    80204096:	4705                	li	a4,1
    80204098:	06f77763          	bgeu	a4,a5,80204106 <sys_write+0x94>
            cons_putc(s[i]);
        }
        return n;
    }

    if (argfd(0, 0, &f) < 0 || argaddr(1, &p) < 0 || argint(2, &n) < 0)
    8020409c:	fd840613          	add	a2,s0,-40
    802040a0:	4581                	li	a1,0
    802040a2:	4501                	li	a0,0
    802040a4:	00000097          	auipc	ra,0x0
    802040a8:	c86080e7          	jalr	-890(ra) # 80203d2a <argfd>
    802040ac:	0e054263          	bltz	a0,80204190 <sys_write+0x11e>
    802040b0:	fd040593          	add	a1,s0,-48
    802040b4:	4505                	li	a0,1
    802040b6:	ffffe097          	auipc	ra,0xffffe
    802040ba:	ba0080e7          	jalr	-1120(ra) # 80201c56 <argaddr>
    802040be:	0c054b63          	bltz	a0,80204194 <sys_write+0x122>
    802040c2:	fcc40593          	add	a1,s0,-52
    802040c6:	4509                	li	a0,2
    802040c8:	ffffe097          	auipc	ra,0xffffe
    802040cc:	b04080e7          	jalr	-1276(ra) # 80201bcc <argint>
    802040d0:	0c054463          	bltz	a0,80204198 <sys_write+0x126>
        return -1;
    
    if (!validate_addr(p, n)) {
    802040d4:	fcc42583          	lw	a1,-52(s0)
    802040d8:	fd043503          	ld	a0,-48(s0)
    802040dc:	00000097          	auipc	ra,0x0
    802040e0:	cf8080e7          	jalr	-776(ra) # 80203dd4 <validate_addr>
    802040e4:	cd45                	beqz	a0,8020419c <sys_write+0x12a>
        return -1;
    }

    return filewrite(f, p, n);
    802040e6:	fcc42603          	lw	a2,-52(s0)
    802040ea:	fd043583          	ld	a1,-48(s0)
    802040ee:	fd843503          	ld	a0,-40(s0)
    802040f2:	00000097          	auipc	ra,0x0
    802040f6:	af6080e7          	jalr	-1290(ra) # 80203be8 <filewrite>
}
    802040fa:	70e2                	ld	ra,56(sp)
    802040fc:	7442                	ld	s0,48(sp)
    802040fe:	74a2                	ld	s1,40(sp)
    80204100:	7902                	ld	s2,32(sp)
    80204102:	6121                	add	sp,sp,64
    80204104:	8082                	ret
    if ((fd == 1 || fd == 2) && myproc()->ofile[fd] == 0) {
    80204106:	ffffd097          	auipc	ra,0xffffd
    8020410a:	2a2080e7          	jalr	674(ra) # 802013a8 <myproc>
    8020410e:	fc842783          	lw	a5,-56(s0)
    80204112:	07e9                	add	a5,a5,26
    80204114:	078e                	sll	a5,a5,0x3
    80204116:	953e                	add	a0,a0,a5
    80204118:	651c                	ld	a5,8(a0)
    8020411a:	f3c9                	bnez	a5,8020409c <sys_write+0x2a>
        if (argaddr(1, &p) < 0 || argint(2, &n) < 0) return -1;
    8020411c:	fd040593          	add	a1,s0,-48
    80204120:	4505                	li	a0,1
    80204122:	ffffe097          	auipc	ra,0xffffe
    80204126:	b34080e7          	jalr	-1228(ra) # 80201c56 <argaddr>
    8020412a:	04054d63          	bltz	a0,80204184 <sys_write+0x112>
    8020412e:	fcc40593          	add	a1,s0,-52
    80204132:	4509                	li	a0,2
    80204134:	ffffe097          	auipc	ra,0xffffe
    80204138:	a98080e7          	jalr	-1384(ra) # 80201bcc <argint>
    8020413c:	04054663          	bltz	a0,80204188 <sys_write+0x116>
        if (!validate_addr(p, n)) return -1;
    80204140:	fcc42583          	lw	a1,-52(s0)
    80204144:	fd043503          	ld	a0,-48(s0)
    80204148:	00000097          	auipc	ra,0x0
    8020414c:	c8c080e7          	jalr	-884(ra) # 80203dd4 <validate_addr>
    80204150:	cd15                	beqz	a0,8020418c <sys_write+0x11a>
        char *s = (char*)p;
    80204152:	fd043903          	ld	s2,-48(s0)
        for(int i = 0; i < n; i++) {
    80204156:	fcc42503          	lw	a0,-52(s0)
    8020415a:	faa050e3          	blez	a0,802040fa <sys_write+0x88>
    8020415e:	4481                	li	s1,0
            cons_putc(s[i]);
    80204160:	009907b3          	add	a5,s2,s1
    80204164:	0007c503          	lbu	a0,0(a5)
    80204168:	ffffc097          	auipc	ra,0xffffc
    8020416c:	ee6080e7          	jalr	-282(ra) # 8020004e <cons_putc>
        for(int i = 0; i < n; i++) {
    80204170:	fcc42503          	lw	a0,-52(s0)
    80204174:	0485                	add	s1,s1,1
    80204176:	0004879b          	sext.w	a5,s1
    8020417a:	fea7c3e3          	blt	a5,a0,80204160 <sys_write+0xee>
    8020417e:	bfb5                	j	802040fa <sys_write+0x88>
    if (argint(0, &fd) < 0) return -1;
    80204180:	557d                	li	a0,-1
    80204182:	bfa5                	j	802040fa <sys_write+0x88>
        if (argaddr(1, &p) < 0 || argint(2, &n) < 0) return -1;
    80204184:	557d                	li	a0,-1
    80204186:	bf95                	j	802040fa <sys_write+0x88>
    80204188:	557d                	li	a0,-1
    8020418a:	bf85                	j	802040fa <sys_write+0x88>
        if (!validate_addr(p, n)) return -1;
    8020418c:	557d                	li	a0,-1
    8020418e:	b7b5                	j	802040fa <sys_write+0x88>
        return -1;
    80204190:	557d                	li	a0,-1
    80204192:	b7a5                	j	802040fa <sys_write+0x88>
    80204194:	557d                	li	a0,-1
    80204196:	b795                	j	802040fa <sys_write+0x88>
    80204198:	557d                	li	a0,-1
    8020419a:	b785                	j	802040fa <sys_write+0x88>
        return -1;
    8020419c:	557d                	li	a0,-1
    8020419e:	bfb1                	j	802040fa <sys_write+0x88>

00000000802041a0 <sys_close>:

int sys_close(void) {
    802041a0:	1101                	add	sp,sp,-32
    802041a2:	ec06                	sd	ra,24(sp)
    802041a4:	e822                	sd	s0,16(sp)
    802041a6:	1000                	add	s0,sp,32
    int fd;
    struct file *f;
    if (argfd(0, &fd, &f) < 0)
    802041a8:	fe040613          	add	a2,s0,-32
    802041ac:	fec40593          	add	a1,s0,-20
    802041b0:	4501                	li	a0,0
    802041b2:	00000097          	auipc	ra,0x0
    802041b6:	b78080e7          	jalr	-1160(ra) # 80203d2a <argfd>
    802041ba:	02054863          	bltz	a0,802041ea <sys_close+0x4a>
        return -1;
    myproc()->ofile[fd] = 0;
    802041be:	ffffd097          	auipc	ra,0xffffd
    802041c2:	1ea080e7          	jalr	490(ra) # 802013a8 <myproc>
    802041c6:	fec42783          	lw	a5,-20(s0)
    802041ca:	07e9                	add	a5,a5,26
    802041cc:	078e                	sll	a5,a5,0x3
    802041ce:	953e                	add	a0,a0,a5
    802041d0:	00053423          	sd	zero,8(a0)
    fileclose(f);
    802041d4:	fe043503          	ld	a0,-32(s0)
    802041d8:	00000097          	auipc	ra,0x0
    802041dc:	86c080e7          	jalr	-1940(ra) # 80203a44 <fileclose>
    return 0;
    802041e0:	4501                	li	a0,0
}
    802041e2:	60e2                	ld	ra,24(sp)
    802041e4:	6442                	ld	s0,16(sp)
    802041e6:	6105                	add	sp,sp,32
    802041e8:	8082                	ret
        return -1;
    802041ea:	557d                	li	a0,-1
    802041ec:	bfdd                	j	802041e2 <sys_close+0x42>

00000000802041ee <sys_fstat>:

int sys_fstat(void) {
    802041ee:	1101                	add	sp,sp,-32
    802041f0:	ec06                	sd	ra,24(sp)
    802041f2:	e822                	sd	s0,16(sp)
    802041f4:	1000                	add	s0,sp,32
    struct file *f;
    uint64 addr;
    if (argfd(0, 0, &f) < 0 || argaddr(1, &addr) < 0)
    802041f6:	fe840613          	add	a2,s0,-24
    802041fa:	4581                	li	a1,0
    802041fc:	4501                	li	a0,0
    802041fe:	00000097          	auipc	ra,0x0
    80204202:	b2c080e7          	jalr	-1236(ra) # 80203d2a <argfd>
    80204206:	02054763          	bltz	a0,80204234 <sys_fstat+0x46>
    8020420a:	fe040593          	add	a1,s0,-32
    8020420e:	4505                	li	a0,1
    80204210:	ffffe097          	auipc	ra,0xffffe
    80204214:	a46080e7          	jalr	-1466(ra) # 80201c56 <argaddr>
    80204218:	02054063          	bltz	a0,80204238 <sys_fstat+0x4a>
        return -1;
    return filestat(f, addr);
    8020421c:	fe043583          	ld	a1,-32(s0)
    80204220:	fe843503          	ld	a0,-24(s0)
    80204224:	00000097          	auipc	ra,0x0
    80204228:	8d8080e7          	jalr	-1832(ra) # 80203afc <filestat>
}
    8020422c:	60e2                	ld	ra,24(sp)
    8020422e:	6442                	ld	s0,16(sp)
    80204230:	6105                	add	sp,sp,32
    80204232:	8082                	ret
        return -1;
    80204234:	557d                	li	a0,-1
    80204236:	bfdd                	j	8020422c <sys_fstat+0x3e>
    80204238:	557d                	li	a0,-1
    8020423a:	bfcd                	j	8020422c <sys_fstat+0x3e>

000000008020423c <sys_link>:

int sys_link(void) {
    8020423c:	7169                	add	sp,sp,-304
    8020423e:	f606                	sd	ra,296(sp)
    80204240:	f222                	sd	s0,288(sp)
    80204242:	ee26                	sd	s1,280(sp)
    80204244:	ea4a                	sd	s2,272(sp)
    80204246:	1a00                	add	s0,sp,304
    char name[DIRSIZ], new[MAXPATH], old[MAXPATH];
    struct inode *dp, *ip;

    if (argstr(0, old, sizeof(old)) < 0 || argstr(1, new, sizeof(new)) < 0)
    80204248:	08000613          	li	a2,128
    8020424c:	ed040593          	add	a1,s0,-304
    80204250:	4501                	li	a0,0
    80204252:	ffffe097          	auipc	ra,0xffffe
    80204256:	a8e080e7          	jalr	-1394(ra) # 80201ce0 <argstr>
    8020425a:	12054363          	bltz	a0,80204380 <sys_link+0x144>
    8020425e:	08000613          	li	a2,128
    80204262:	f5040593          	add	a1,s0,-176
    80204266:	4505                	li	a0,1
    80204268:	ffffe097          	auipc	ra,0xffffe
    8020426c:	a78080e7          	jalr	-1416(ra) # 80201ce0 <argstr>
    80204270:	10054a63          	bltz	a0,80204384 <sys_link+0x148>
        return -1;

    begin_op();
    80204274:	fffff097          	auipc	ra,0xfffff
    80204278:	2ee080e7          	jalr	750(ra) # 80203562 <begin_op>
    if ((ip = namei(old)) == 0) {
    8020427c:	ed040513          	add	a0,s0,-304
    80204280:	fffff097          	auipc	ra,0xfffff
    80204284:	ec0080e7          	jalr	-320(ra) # 80203140 <namei>
    80204288:	84aa                	mv	s1,a0
    8020428a:	c959                	beqz	a0,80204320 <sys_link+0xe4>
        end_op();
        return -1;
    }
    ilock(ip);
    8020428c:	ffffe097          	auipc	ra,0xffffe
    80204290:	69a080e7          	jalr	1690(ra) # 80202926 <ilock>
    if (ip->type == T_DIR) {
    80204294:	04449703          	lh	a4,68(s1)
    80204298:	4785                	li	a5,1
    8020429a:	08f70963          	beq	a4,a5,8020432c <sys_link+0xf0>
        iunlockput(ip);
        end_op();
        return -1;
    }

    ip->nlink++;
    8020429e:	04a4d783          	lhu	a5,74(s1)
    802042a2:	2785                	addw	a5,a5,1
    802042a4:	04f49523          	sh	a5,74(s1)
    iupdate(ip);
    802042a8:	8526                	mv	a0,s1
    802042aa:	ffffe097          	auipc	ra,0xffffe
    802042ae:	782080e7          	jalr	1922(ra) # 80202a2c <iupdate>
    iunlock(ip);
    802042b2:	8526                	mv	a0,s1
    802042b4:	ffffe097          	auipc	ra,0xffffe
    802042b8:	738080e7          	jalr	1848(ra) # 802029ec <iunlock>

    if ((dp = nameiparent(new, name)) == 0)
    802042bc:	fd040593          	add	a1,s0,-48
    802042c0:	f5040513          	add	a0,s0,-176
    802042c4:	fffff097          	auipc	ra,0xfffff
    802042c8:	e9a080e7          	jalr	-358(ra) # 8020315e <nameiparent>
    802042cc:	892a                	mv	s2,a0
    802042ce:	cd3d                	beqz	a0,8020434c <sys_link+0x110>
        goto bad;
    ilock(dp);
    802042d0:	ffffe097          	auipc	ra,0xffffe
    802042d4:	656080e7          	jalr	1622(ra) # 80202926 <ilock>
    if (dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0) {
    802042d8:	00092703          	lw	a4,0(s2)
    802042dc:	409c                	lw	a5,0(s1)
    802042de:	06f71263          	bne	a4,a5,80204342 <sys_link+0x106>
    802042e2:	40d0                	lw	a2,4(s1)
    802042e4:	fd040593          	add	a1,s0,-48
    802042e8:	854a                	mv	a0,s2
    802042ea:	fffff097          	auipc	ra,0xfffff
    802042ee:	c2e080e7          	jalr	-978(ra) # 80202f18 <dirlink>
    802042f2:	04054863          	bltz	a0,80204342 <sys_link+0x106>
        iunlockput(dp);
        goto bad;
    }
    iunlockput(dp);
    802042f6:	854a                	mv	a0,s2
    802042f8:	fffff097          	auipc	ra,0xfffff
    802042fc:	8f6080e7          	jalr	-1802(ra) # 80202bee <iunlockput>
    iput(ip);
    80204300:	8526                	mv	a0,s1
    80204302:	fffff097          	auipc	ra,0xfffff
    80204306:	864080e7          	jalr	-1948(ra) # 80202b66 <iput>
    end_op();
    8020430a:	fffff097          	auipc	ra,0xfffff
    8020430e:	2d2080e7          	jalr	722(ra) # 802035dc <end_op>
    return 0;
    80204312:	4501                	li	a0,0
    ip->nlink--;
    iupdate(ip);
    iunlockput(ip);
    end_op();
    return -1;
}
    80204314:	70b2                	ld	ra,296(sp)
    80204316:	7412                	ld	s0,288(sp)
    80204318:	64f2                	ld	s1,280(sp)
    8020431a:	6952                	ld	s2,272(sp)
    8020431c:	6155                	add	sp,sp,304
    8020431e:	8082                	ret
        end_op();
    80204320:	fffff097          	auipc	ra,0xfffff
    80204324:	2bc080e7          	jalr	700(ra) # 802035dc <end_op>
        return -1;
    80204328:	557d                	li	a0,-1
    8020432a:	b7ed                	j	80204314 <sys_link+0xd8>
        iunlockput(ip);
    8020432c:	8526                	mv	a0,s1
    8020432e:	fffff097          	auipc	ra,0xfffff
    80204332:	8c0080e7          	jalr	-1856(ra) # 80202bee <iunlockput>
        end_op();
    80204336:	fffff097          	auipc	ra,0xfffff
    8020433a:	2a6080e7          	jalr	678(ra) # 802035dc <end_op>
        return -1;
    8020433e:	557d                	li	a0,-1
    80204340:	bfd1                	j	80204314 <sys_link+0xd8>
        iunlockput(dp);
    80204342:	854a                	mv	a0,s2
    80204344:	fffff097          	auipc	ra,0xfffff
    80204348:	8aa080e7          	jalr	-1878(ra) # 80202bee <iunlockput>
    ilock(ip);
    8020434c:	8526                	mv	a0,s1
    8020434e:	ffffe097          	auipc	ra,0xffffe
    80204352:	5d8080e7          	jalr	1496(ra) # 80202926 <ilock>
    ip->nlink--;
    80204356:	04a4d783          	lhu	a5,74(s1)
    8020435a:	37fd                	addw	a5,a5,-1
    8020435c:	04f49523          	sh	a5,74(s1)
    iupdate(ip);
    80204360:	8526                	mv	a0,s1
    80204362:	ffffe097          	auipc	ra,0xffffe
    80204366:	6ca080e7          	jalr	1738(ra) # 80202a2c <iupdate>
    iunlockput(ip);
    8020436a:	8526                	mv	a0,s1
    8020436c:	fffff097          	auipc	ra,0xfffff
    80204370:	882080e7          	jalr	-1918(ra) # 80202bee <iunlockput>
    end_op();
    80204374:	fffff097          	auipc	ra,0xfffff
    80204378:	268080e7          	jalr	616(ra) # 802035dc <end_op>
    return -1;
    8020437c:	557d                	li	a0,-1
    8020437e:	bf59                	j	80204314 <sys_link+0xd8>
        return -1;
    80204380:	557d                	li	a0,-1
    80204382:	bf49                	j	80204314 <sys_link+0xd8>
    80204384:	557d                	li	a0,-1
    80204386:	b779                	j	80204314 <sys_link+0xd8>

0000000080204388 <sys_unlink>:

int sys_unlink(void) {
    80204388:	7155                	add	sp,sp,-208
    8020438a:	e586                	sd	ra,200(sp)
    8020438c:	e1a2                	sd	s0,192(sp)
    8020438e:	fd26                	sd	s1,184(sp)
    80204390:	f94a                	sd	s2,176(sp)
    80204392:	0980                	add	s0,sp,208
    struct inode *ip, *dp;
    struct dirent de;
    char name[DIRSIZ], path[MAXPATH];
    uint off;

    if (argstr(0, path, sizeof(path)) < 0)
    80204394:	08000613          	li	a2,128
    80204398:	f4040593          	add	a1,s0,-192
    8020439c:	4501                	li	a0,0
    8020439e:	ffffe097          	auipc	ra,0xffffe
    802043a2:	942080e7          	jalr	-1726(ra) # 80201ce0 <argstr>
    802043a6:	16054463          	bltz	a0,8020450e <sys_unlink+0x186>
        return -1;

    begin_op();
    802043aa:	fffff097          	auipc	ra,0xfffff
    802043ae:	1b8080e7          	jalr	440(ra) # 80203562 <begin_op>
    if ((dp = nameiparent(path, name)) == 0) {
    802043b2:	fc040593          	add	a1,s0,-64
    802043b6:	f4040513          	add	a0,s0,-192
    802043ba:	fffff097          	auipc	ra,0xfffff
    802043be:	da4080e7          	jalr	-604(ra) # 8020315e <nameiparent>
    802043c2:	892a                	mv	s2,a0
    802043c4:	c175                	beqz	a0,802044a8 <sys_unlink+0x120>
        end_op();
        return -1;
    }
    ilock(dp);
    802043c6:	ffffe097          	auipc	ra,0xffffe
    802043ca:	560080e7          	jalr	1376(ra) # 80202926 <ilock>

    if (namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    802043ce:	00002597          	auipc	a1,0x2
    802043d2:	3da58593          	add	a1,a1,986 # 802067a8 <syscalls+0x1d8>
    802043d6:	fc040513          	add	a0,s0,-64
    802043da:	fffff097          	auipc	ra,0xfffff
    802043de:	a66080e7          	jalr	-1434(ra) # 80202e40 <namecmp>
    802043e2:	c57d                	beqz	a0,802044d0 <sys_unlink+0x148>
    802043e4:	00002597          	auipc	a1,0x2
    802043e8:	3cc58593          	add	a1,a1,972 # 802067b0 <syscalls+0x1e0>
    802043ec:	fc040513          	add	a0,s0,-64
    802043f0:	fffff097          	auipc	ra,0xfffff
    802043f4:	a50080e7          	jalr	-1456(ra) # 80202e40 <namecmp>
    802043f8:	cd61                	beqz	a0,802044d0 <sys_unlink+0x148>
        goto bad;

    if ((ip = dirlookup(dp, name, &off)) == 0)
    802043fa:	f3c40613          	add	a2,s0,-196
    802043fe:	fc040593          	add	a1,s0,-64
    80204402:	854a                	mv	a0,s2
    80204404:	fffff097          	auipc	ra,0xfffff
    80204408:	a56080e7          	jalr	-1450(ra) # 80202e5a <dirlookup>
    8020440c:	84aa                	mv	s1,a0
    8020440e:	c169                	beqz	a0,802044d0 <sys_unlink+0x148>
        goto bad;
    ilock(ip);
    80204410:	ffffe097          	auipc	ra,0xffffe
    80204414:	516080e7          	jalr	1302(ra) # 80202926 <ilock>

    if (ip->nlink < 1)
    80204418:	04a49783          	lh	a5,74(s1)
    8020441c:	08f05c63          	blez	a5,802044b4 <sys_unlink+0x12c>
        panic("unlink: nlink < 1");
    if (ip->type == T_DIR && ip->size > 2 * sizeof(de)) {
    80204420:	04449703          	lh	a4,68(s1)
    80204424:	4785                	li	a5,1
    80204426:	00f71763          	bne	a4,a5,80204434 <sys_unlink+0xac>
    8020442a:	44f8                	lw	a4,76(s1)
    8020442c:	02000793          	li	a5,32
    80204430:	08e7eb63          	bltu	a5,a4,802044c6 <sys_unlink+0x13e>
        iunlockput(ip);
        goto bad;
    }

    memset(&de, 0, sizeof(de));
    80204434:	4641                	li	a2,16
    80204436:	4581                	li	a1,0
    80204438:	fd040513          	add	a0,s0,-48
    8020443c:	ffffc097          	auipc	ra,0xffffc
    80204440:	566080e7          	jalr	1382(ra) # 802009a2 <memset>
    if (writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80204444:	4741                	li	a4,16
    80204446:	f3c42683          	lw	a3,-196(s0)
    8020444a:	fd040613          	add	a2,s0,-48
    8020444e:	4581                	li	a1,0
    80204450:	854a                	mv	a0,s2
    80204452:	fffff097          	auipc	ra,0xfffff
    80204456:	8d2080e7          	jalr	-1838(ra) # 80202d24 <writei>
    8020445a:	47c1                	li	a5,16
    8020445c:	08f51563          	bne	a0,a5,802044e6 <sys_unlink+0x15e>
        panic("unlink: write");
    if (ip->type == T_DIR) {
    80204460:	04449703          	lh	a4,68(s1)
    80204464:	4785                	li	a5,1
    80204466:	08f70963          	beq	a4,a5,802044f8 <sys_unlink+0x170>
        dp->nlink--;
        iupdate(dp);
    }
    iunlockput(dp);
    8020446a:	854a                	mv	a0,s2
    8020446c:	ffffe097          	auipc	ra,0xffffe
    80204470:	782080e7          	jalr	1922(ra) # 80202bee <iunlockput>

    ip->nlink--;
    80204474:	04a4d783          	lhu	a5,74(s1)
    80204478:	37fd                	addw	a5,a5,-1
    8020447a:	04f49523          	sh	a5,74(s1)
    iupdate(ip);
    8020447e:	8526                	mv	a0,s1
    80204480:	ffffe097          	auipc	ra,0xffffe
    80204484:	5ac080e7          	jalr	1452(ra) # 80202a2c <iupdate>
    iunlockput(ip);
    80204488:	8526                	mv	a0,s1
    8020448a:	ffffe097          	auipc	ra,0xffffe
    8020448e:	764080e7          	jalr	1892(ra) # 80202bee <iunlockput>

    end_op();
    80204492:	fffff097          	auipc	ra,0xfffff
    80204496:	14a080e7          	jalr	330(ra) # 802035dc <end_op>
    return 0;
    8020449a:	4501                	li	a0,0

bad:
    iunlockput(dp);
    end_op();
    return -1;
}
    8020449c:	60ae                	ld	ra,200(sp)
    8020449e:	640e                	ld	s0,192(sp)
    802044a0:	74ea                	ld	s1,184(sp)
    802044a2:	794a                	ld	s2,176(sp)
    802044a4:	6169                	add	sp,sp,208
    802044a6:	8082                	ret
        end_op();
    802044a8:	fffff097          	auipc	ra,0xfffff
    802044ac:	134080e7          	jalr	308(ra) # 802035dc <end_op>
        return -1;
    802044b0:	557d                	li	a0,-1
    802044b2:	b7ed                	j	8020449c <sys_unlink+0x114>
        panic("unlink: nlink < 1");
    802044b4:	00002517          	auipc	a0,0x2
    802044b8:	4dc50513          	add	a0,a0,1244 # 80206990 <syscalls+0x3c0>
    802044bc:	ffffc097          	auipc	ra,0xffffc
    802044c0:	f18080e7          	jalr	-232(ra) # 802003d4 <panic>
    802044c4:	bfb1                	j	80204420 <sys_unlink+0x98>
        iunlockput(ip);
    802044c6:	8526                	mv	a0,s1
    802044c8:	ffffe097          	auipc	ra,0xffffe
    802044cc:	726080e7          	jalr	1830(ra) # 80202bee <iunlockput>
    iunlockput(dp);
    802044d0:	854a                	mv	a0,s2
    802044d2:	ffffe097          	auipc	ra,0xffffe
    802044d6:	71c080e7          	jalr	1820(ra) # 80202bee <iunlockput>
    end_op();
    802044da:	fffff097          	auipc	ra,0xfffff
    802044de:	102080e7          	jalr	258(ra) # 802035dc <end_op>
    return -1;
    802044e2:	557d                	li	a0,-1
    802044e4:	bf65                	j	8020449c <sys_unlink+0x114>
        panic("unlink: write");
    802044e6:	00002517          	auipc	a0,0x2
    802044ea:	4c250513          	add	a0,a0,1218 # 802069a8 <syscalls+0x3d8>
    802044ee:	ffffc097          	auipc	ra,0xffffc
    802044f2:	ee6080e7          	jalr	-282(ra) # 802003d4 <panic>
    802044f6:	b7ad                	j	80204460 <sys_unlink+0xd8>
        dp->nlink--;
    802044f8:	04a95783          	lhu	a5,74(s2)
    802044fc:	37fd                	addw	a5,a5,-1
    802044fe:	04f91523          	sh	a5,74(s2)
        iupdate(dp);
    80204502:	854a                	mv	a0,s2
    80204504:	ffffe097          	auipc	ra,0xffffe
    80204508:	528080e7          	jalr	1320(ra) # 80202a2c <iupdate>
    8020450c:	bfb9                	j	8020446a <sys_unlink+0xe2>
        return -1;
    8020450e:	557d                	li	a0,-1
    80204510:	b771                	j	8020449c <sys_unlink+0x114>

0000000080204512 <sys_open>:

int sys_open(void) {
    80204512:	7131                	add	sp,sp,-192
    80204514:	fd06                	sd	ra,184(sp)
    80204516:	f922                	sd	s0,176(sp)
    80204518:	f526                	sd	s1,168(sp)
    8020451a:	f14a                	sd	s2,160(sp)
    8020451c:	ed4e                	sd	s3,152(sp)
    8020451e:	0180                	add	s0,sp,192
    char path[MAXPATH];
    int omode;
    struct file *f;
    struct inode *ip;

    if (argstr(0, path, sizeof(path)) < 0 || argint(1, &omode) < 0)
    80204520:	08000613          	li	a2,128
    80204524:	f5040593          	add	a1,s0,-176
    80204528:	4501                	li	a0,0
    8020452a:	ffffd097          	auipc	ra,0xffffd
    8020452e:	7b6080e7          	jalr	1974(ra) # 80201ce0 <argstr>
    80204532:	16054563          	bltz	a0,8020469c <sys_open+0x18a>
    80204536:	f4c40593          	add	a1,s0,-180
    8020453a:	4505                	li	a0,1
    8020453c:	ffffd097          	auipc	ra,0xffffd
    80204540:	690080e7          	jalr	1680(ra) # 80201bcc <argint>
    80204544:	14054e63          	bltz	a0,802046a0 <sys_open+0x18e>
        return -1;

    begin_op();
    80204548:	fffff097          	auipc	ra,0xfffff
    8020454c:	01a080e7          	jalr	26(ra) # 80203562 <begin_op>

    if (omode & O_CREATE) {
    80204550:	f4c42783          	lw	a5,-180(s0)
    80204554:	2007f793          	and	a5,a5,512
    80204558:	c7cd                	beqz	a5,80204602 <sys_open+0xf0>
        ip = create(path, T_FILE, 0, 0);
    8020455a:	4681                	li	a3,0
    8020455c:	4601                	li	a2,0
    8020455e:	4589                	li	a1,2
    80204560:	f5040513          	add	a0,s0,-176
    80204564:	00000097          	auipc	ra,0x0
    80204568:	8e0080e7          	jalr	-1824(ra) # 80203e44 <create>
    8020456c:	89aa                	mv	s3,a0
        if (ip == 0) {
    8020456e:	c935                	beqz	a0,802045e2 <sys_open+0xd0>
            end_op();
            return -1;
        }
    }

    if ((f = filealloc()) == 0) {
    80204570:	fffff097          	auipc	ra,0xfffff
    80204574:	414080e7          	jalr	1044(ra) # 80203984 <filealloc>
    80204578:	84aa                	mv	s1,a0
    8020457a:	c969                	beqz	a0,8020464c <sys_open+0x13a>
        iunlockput(ip);
        end_op();
        return -1;
    }
    int fd = fdalloc(f);
    8020457c:	00000097          	auipc	ra,0x0
    80204580:	816080e7          	jalr	-2026(ra) # 80203d92 <fdalloc>
    80204584:	892a                	mv	s2,a0
    if (fd < 0) {
    80204586:	0c054e63          	bltz	a0,80204662 <sys_open+0x150>
        fileclose(f);
        iunlockput(ip);
        end_op();
        return -1;
    }
    if (ip->type == T_DEV) {
    8020458a:	04499703          	lh	a4,68(s3)
    8020458e:	478d                	li	a5,3
    80204590:	0ef70963          	beq	a4,a5,80204682 <sys_open+0x170>
        f->type = FD_DEVICE;
        f->major = ip->major;
    } else {
        f->type = FD_INODE;
    80204594:	4785                	li	a5,1
    80204596:	c09c                	sw	a5,0(s1)
    }
    f->off = 0;
    80204598:	0004ac23          	sw	zero,24(s1)
    f->readable = !(omode & O_WRONLY);
    8020459c:	f4c42783          	lw	a5,-180(s0)
    802045a0:	0017c713          	xor	a4,a5,1
    802045a4:	8b05                	and	a4,a4,1
    802045a6:	00e48423          	sb	a4,8(s1)
    f->writable = (omode & (O_WRONLY | O_RDWR)) != 0;
    802045aa:	0037f713          	and	a4,a5,3
    802045ae:	00e03733          	snez	a4,a4
    802045b2:	00e484a3          	sb	a4,9(s1)
    f->ip = ip;
    802045b6:	0134b823          	sd	s3,16(s1)
    if (omode & O_TRUNC) {
    802045ba:	4007f793          	and	a5,a5,1024
    802045be:	ebe9                	bnez	a5,80204690 <sys_open+0x17e>
        itrunc(ip);
    }
    iunlock(ip);
    802045c0:	854e                	mv	a0,s3
    802045c2:	ffffe097          	auipc	ra,0xffffe
    802045c6:	42a080e7          	jalr	1066(ra) # 802029ec <iunlock>
    end_op();
    802045ca:	fffff097          	auipc	ra,0xfffff
    802045ce:	012080e7          	jalr	18(ra) # 802035dc <end_op>
    return fd;
}
    802045d2:	854a                	mv	a0,s2
    802045d4:	70ea                	ld	ra,184(sp)
    802045d6:	744a                	ld	s0,176(sp)
    802045d8:	74aa                	ld	s1,168(sp)
    802045da:	790a                	ld	s2,160(sp)
    802045dc:	69ea                	ld	s3,152(sp)
    802045de:	6129                	add	sp,sp,192
    802045e0:	8082                	ret
            printf("sys_open: create failed for %s\n", path); // DEBUG
    802045e2:	f5040593          	add	a1,s0,-176
    802045e6:	00002517          	auipc	a0,0x2
    802045ea:	3d250513          	add	a0,a0,978 # 802069b8 <syscalls+0x3e8>
    802045ee:	ffffc097          	auipc	ra,0xffffc
    802045f2:	b66080e7          	jalr	-1178(ra) # 80200154 <printf>
            end_op();
    802045f6:	fffff097          	auipc	ra,0xfffff
    802045fa:	fe6080e7          	jalr	-26(ra) # 802035dc <end_op>
            return -1;
    802045fe:	597d                	li	s2,-1
    80204600:	bfc9                	j	802045d2 <sys_open+0xc0>
        if ((ip = namei(path)) == 0) {
    80204602:	f5040513          	add	a0,s0,-176
    80204606:	fffff097          	auipc	ra,0xfffff
    8020460a:	b3a080e7          	jalr	-1222(ra) # 80203140 <namei>
    8020460e:	89aa                	mv	s3,a0
    80204610:	c905                	beqz	a0,80204640 <sys_open+0x12e>
        ilock(ip);
    80204612:	ffffe097          	auipc	ra,0xffffe
    80204616:	314080e7          	jalr	788(ra) # 80202926 <ilock>
        if (ip->type == T_DIR && omode != O_RDONLY) {
    8020461a:	04499703          	lh	a4,68(s3)
    8020461e:	4785                	li	a5,1
    80204620:	f4f718e3          	bne	a4,a5,80204570 <sys_open+0x5e>
    80204624:	f4c42783          	lw	a5,-180(s0)
    80204628:	d7a1                	beqz	a5,80204570 <sys_open+0x5e>
            iunlockput(ip);
    8020462a:	854e                	mv	a0,s3
    8020462c:	ffffe097          	auipc	ra,0xffffe
    80204630:	5c2080e7          	jalr	1474(ra) # 80202bee <iunlockput>
            end_op();
    80204634:	fffff097          	auipc	ra,0xfffff
    80204638:	fa8080e7          	jalr	-88(ra) # 802035dc <end_op>
            return -1;
    8020463c:	597d                	li	s2,-1
    8020463e:	bf51                	j	802045d2 <sys_open+0xc0>
            end_op();
    80204640:	fffff097          	auipc	ra,0xfffff
    80204644:	f9c080e7          	jalr	-100(ra) # 802035dc <end_op>
            return -1;
    80204648:	597d                	li	s2,-1
    8020464a:	b761                	j	802045d2 <sys_open+0xc0>
        iunlockput(ip);
    8020464c:	854e                	mv	a0,s3
    8020464e:	ffffe097          	auipc	ra,0xffffe
    80204652:	5a0080e7          	jalr	1440(ra) # 80202bee <iunlockput>
        end_op();
    80204656:	fffff097          	auipc	ra,0xfffff
    8020465a:	f86080e7          	jalr	-122(ra) # 802035dc <end_op>
        return -1;
    8020465e:	597d                	li	s2,-1
    80204660:	bf8d                	j	802045d2 <sys_open+0xc0>
        fileclose(f);
    80204662:	8526                	mv	a0,s1
    80204664:	fffff097          	auipc	ra,0xfffff
    80204668:	3e0080e7          	jalr	992(ra) # 80203a44 <fileclose>
        iunlockput(ip);
    8020466c:	854e                	mv	a0,s3
    8020466e:	ffffe097          	auipc	ra,0xffffe
    80204672:	580080e7          	jalr	1408(ra) # 80202bee <iunlockput>
        end_op();
    80204676:	fffff097          	auipc	ra,0xfffff
    8020467a:	f66080e7          	jalr	-154(ra) # 802035dc <end_op>
        return -1;
    8020467e:	597d                	li	s2,-1
    80204680:	bf89                	j	802045d2 <sys_open+0xc0>
        f->type = FD_DEVICE;
    80204682:	4789                	li	a5,2
    80204684:	c09c                	sw	a5,0(s1)
        f->major = ip->major;
    80204686:	04699783          	lh	a5,70(s3)
    8020468a:	00f49e23          	sh	a5,28(s1)
    8020468e:	b729                	j	80204598 <sys_open+0x86>
        itrunc(ip);
    80204690:	854e                	mv	a0,s3
    80204692:	ffffe097          	auipc	ra,0xffffe
    80204696:	428080e7          	jalr	1064(ra) # 80202aba <itrunc>
    8020469a:	b71d                	j	802045c0 <sys_open+0xae>
        return -1;
    8020469c:	597d                	li	s2,-1
    8020469e:	bf15                	j	802045d2 <sys_open+0xc0>
    802046a0:	597d                	li	s2,-1
    802046a2:	bf05                	j	802045d2 <sys_open+0xc0>

00000000802046a4 <sys_mkdir>:

int sys_mkdir(void) {
    802046a4:	7175                	add	sp,sp,-144
    802046a6:	e506                	sd	ra,136(sp)
    802046a8:	e122                	sd	s0,128(sp)
    802046aa:	0900                	add	s0,sp,144
    char path[MAXPATH];
    if (argstr(0, path, sizeof(path)) < 0)
    802046ac:	08000613          	li	a2,128
    802046b0:	f7040593          	add	a1,s0,-144
    802046b4:	4501                	li	a0,0
    802046b6:	ffffd097          	auipc	ra,0xffffd
    802046ba:	62a080e7          	jalr	1578(ra) # 80201ce0 <argstr>
    802046be:	04054363          	bltz	a0,80204704 <sys_mkdir+0x60>
        return -1;
    begin_op();
    802046c2:	fffff097          	auipc	ra,0xfffff
    802046c6:	ea0080e7          	jalr	-352(ra) # 80203562 <begin_op>
    struct inode *ip = create(path, T_DIR, 0, 0);
    802046ca:	4681                	li	a3,0
    802046cc:	4601                	li	a2,0
    802046ce:	4585                	li	a1,1
    802046d0:	f7040513          	add	a0,s0,-144
    802046d4:	fffff097          	auipc	ra,0xfffff
    802046d8:	770080e7          	jalr	1904(ra) # 80203e44 <create>
    if (ip == 0) {
    802046dc:	cd11                	beqz	a0,802046f8 <sys_mkdir+0x54>
        end_op();
        return -1;
    }
    iunlockput(ip);
    802046de:	ffffe097          	auipc	ra,0xffffe
    802046e2:	510080e7          	jalr	1296(ra) # 80202bee <iunlockput>
    end_op();
    802046e6:	fffff097          	auipc	ra,0xfffff
    802046ea:	ef6080e7          	jalr	-266(ra) # 802035dc <end_op>
    return 0;
    802046ee:	4501                	li	a0,0
}
    802046f0:	60aa                	ld	ra,136(sp)
    802046f2:	640a                	ld	s0,128(sp)
    802046f4:	6149                	add	sp,sp,144
    802046f6:	8082                	ret
        end_op();
    802046f8:	fffff097          	auipc	ra,0xfffff
    802046fc:	ee4080e7          	jalr	-284(ra) # 802035dc <end_op>
        return -1;
    80204700:	557d                	li	a0,-1
    80204702:	b7fd                	j	802046f0 <sys_mkdir+0x4c>
        return -1;
    80204704:	557d                	li	a0,-1
    80204706:	b7ed                	j	802046f0 <sys_mkdir+0x4c>

0000000080204708 <sys_mknod>:

int sys_mknod(void) {
    80204708:	7135                	add	sp,sp,-160
    8020470a:	ed06                	sd	ra,152(sp)
    8020470c:	e922                	sd	s0,144(sp)
    8020470e:	1100                	add	s0,sp,160
    char path[MAXPATH];
    int major, minor;
    if (argstr(0, path, sizeof(path)) < 0 || argint(1, &major) < 0 || argint(2, &minor) < 0)
    80204710:	08000613          	li	a2,128
    80204714:	f7040593          	add	a1,s0,-144
    80204718:	4501                	li	a0,0
    8020471a:	ffffd097          	auipc	ra,0xffffd
    8020471e:	5c6080e7          	jalr	1478(ra) # 80201ce0 <argstr>
    80204722:	06054763          	bltz	a0,80204790 <sys_mknod+0x88>
    80204726:	f6c40593          	add	a1,s0,-148
    8020472a:	4505                	li	a0,1
    8020472c:	ffffd097          	auipc	ra,0xffffd
    80204730:	4a0080e7          	jalr	1184(ra) # 80201bcc <argint>
    80204734:	06054063          	bltz	a0,80204794 <sys_mknod+0x8c>
    80204738:	f6840593          	add	a1,s0,-152
    8020473c:	4509                	li	a0,2
    8020473e:	ffffd097          	auipc	ra,0xffffd
    80204742:	48e080e7          	jalr	1166(ra) # 80201bcc <argint>
    80204746:	04054963          	bltz	a0,80204798 <sys_mknod+0x90>
        return -1;
    begin_op();
    8020474a:	fffff097          	auipc	ra,0xfffff
    8020474e:	e18080e7          	jalr	-488(ra) # 80203562 <begin_op>
    struct inode *ip = create(path, T_DEV, major, minor);
    80204752:	f6841683          	lh	a3,-152(s0)
    80204756:	f6c41603          	lh	a2,-148(s0)
    8020475a:	458d                	li	a1,3
    8020475c:	f7040513          	add	a0,s0,-144
    80204760:	fffff097          	auipc	ra,0xfffff
    80204764:	6e4080e7          	jalr	1764(ra) # 80203e44 <create>
    if (ip == 0) {
    80204768:	cd11                	beqz	a0,80204784 <sys_mknod+0x7c>
        end_op();
        return -1;
    }
    iunlockput(ip);
    8020476a:	ffffe097          	auipc	ra,0xffffe
    8020476e:	484080e7          	jalr	1156(ra) # 80202bee <iunlockput>
    end_op();
    80204772:	fffff097          	auipc	ra,0xfffff
    80204776:	e6a080e7          	jalr	-406(ra) # 802035dc <end_op>
    return 0;
    8020477a:	4501                	li	a0,0
}
    8020477c:	60ea                	ld	ra,152(sp)
    8020477e:	644a                	ld	s0,144(sp)
    80204780:	610d                	add	sp,sp,160
    80204782:	8082                	ret
        end_op();
    80204784:	fffff097          	auipc	ra,0xfffff
    80204788:	e58080e7          	jalr	-424(ra) # 802035dc <end_op>
        return -1;
    8020478c:	557d                	li	a0,-1
    8020478e:	b7fd                	j	8020477c <sys_mknod+0x74>
        return -1;
    80204790:	557d                	li	a0,-1
    80204792:	b7ed                	j	8020477c <sys_mknod+0x74>
    80204794:	557d                	li	a0,-1
    80204796:	b7dd                	j	8020477c <sys_mknod+0x74>
    80204798:	557d                	li	a0,-1
    8020479a:	b7cd                	j	8020477c <sys_mknod+0x74>

000000008020479c <sys_chdir>:

int sys_chdir(void) {
    8020479c:	7135                	add	sp,sp,-160
    8020479e:	ed06                	sd	ra,152(sp)
    802047a0:	e922                	sd	s0,144(sp)
    802047a2:	e526                	sd	s1,136(sp)
    802047a4:	e14a                	sd	s2,128(sp)
    802047a6:	1100                	add	s0,sp,160
    char path[MAXPATH];
    struct inode *ip;
    if (argstr(0, path, sizeof(path)) < 0)
    802047a8:	08000613          	li	a2,128
    802047ac:	f6040593          	add	a1,s0,-160
    802047b0:	4501                	li	a0,0
    802047b2:	ffffd097          	auipc	ra,0xffffd
    802047b6:	52e080e7          	jalr	1326(ra) # 80201ce0 <argstr>
    802047ba:	08054563          	bltz	a0,80204844 <sys_chdir+0xa8>
        return -1;
    begin_op();
    802047be:	fffff097          	auipc	ra,0xfffff
    802047c2:	da4080e7          	jalr	-604(ra) # 80203562 <begin_op>
    if ((ip = namei(path)) == 0) {
    802047c6:	f6040513          	add	a0,s0,-160
    802047ca:	fffff097          	auipc	ra,0xfffff
    802047ce:	976080e7          	jalr	-1674(ra) # 80203140 <namei>
    802047d2:	84aa                	mv	s1,a0
    802047d4:	c539                	beqz	a0,80204822 <sys_chdir+0x86>
        end_op();
        return -1;
    }
    ilock(ip);
    802047d6:	ffffe097          	auipc	ra,0xffffe
    802047da:	150080e7          	jalr	336(ra) # 80202926 <ilock>
    if (ip->type != T_DIR) {
    802047de:	04449703          	lh	a4,68(s1)
    802047e2:	4785                	li	a5,1
    802047e4:	04f71563          	bne	a4,a5,8020482e <sys_chdir+0x92>
        iunlockput(ip);
        end_op();
        return -1;
    }
    iunlock(ip);
    802047e8:	8526                	mv	a0,s1
    802047ea:	ffffe097          	auipc	ra,0xffffe
    802047ee:	202080e7          	jalr	514(ra) # 802029ec <iunlock>
    struct proc *p = myproc();
    802047f2:	ffffd097          	auipc	ra,0xffffd
    802047f6:	bb6080e7          	jalr	-1098(ra) # 802013a8 <myproc>
    802047fa:	892a                	mv	s2,a0
    iput(p->cwd);
    802047fc:	15853503          	ld	a0,344(a0)
    80204800:	ffffe097          	auipc	ra,0xffffe
    80204804:	366080e7          	jalr	870(ra) # 80202b66 <iput>
    p->cwd = ip;
    80204808:	14993c23          	sd	s1,344(s2)
    end_op();
    8020480c:	fffff097          	auipc	ra,0xfffff
    80204810:	dd0080e7          	jalr	-560(ra) # 802035dc <end_op>
    return 0;
    80204814:	4501                	li	a0,0
    80204816:	60ea                	ld	ra,152(sp)
    80204818:	644a                	ld	s0,144(sp)
    8020481a:	64aa                	ld	s1,136(sp)
    8020481c:	690a                	ld	s2,128(sp)
    8020481e:	610d                	add	sp,sp,160
    80204820:	8082                	ret
        end_op();
    80204822:	fffff097          	auipc	ra,0xfffff
    80204826:	dba080e7          	jalr	-582(ra) # 802035dc <end_op>
        return -1;
    8020482a:	557d                	li	a0,-1
    8020482c:	b7ed                	j	80204816 <sys_chdir+0x7a>
        iunlockput(ip);
    8020482e:	8526                	mv	a0,s1
    80204830:	ffffe097          	auipc	ra,0xffffe
    80204834:	3be080e7          	jalr	958(ra) # 80202bee <iunlockput>
        end_op();
    80204838:	fffff097          	auipc	ra,0xfffff
    8020483c:	da4080e7          	jalr	-604(ra) # 802035dc <end_op>
        return -1;
    80204840:	557d                	li	a0,-1
    80204842:	bfd1                	j	80204816 <sys_chdir+0x7a>
        return -1;
    80204844:	557d                	li	a0,-1
    80204846:	bfc1                	j	80204816 <sys_chdir+0x7a>
	...

0000000080204850 <kernelvec>:
    80204850:	7111                	add	sp,sp,-256
    80204852:	e006                	sd	ra,0(sp)
    80204854:	e40a                	sd	sp,8(sp)
    80204856:	e80e                	sd	gp,16(sp)
    80204858:	ec12                	sd	tp,24(sp)
    8020485a:	f016                	sd	t0,32(sp)
    8020485c:	f41a                	sd	t1,40(sp)
    8020485e:	f81e                	sd	t2,48(sp)
    80204860:	fc22                	sd	s0,56(sp)
    80204862:	e0a6                	sd	s1,64(sp)
    80204864:	e4aa                	sd	a0,72(sp)
    80204866:	e8ae                	sd	a1,80(sp)
    80204868:	ecb2                	sd	a2,88(sp)
    8020486a:	f0b6                	sd	a3,96(sp)
    8020486c:	f4ba                	sd	a4,104(sp)
    8020486e:	f8be                	sd	a5,112(sp)
    80204870:	fcc2                	sd	a6,120(sp)
    80204872:	e146                	sd	a7,128(sp)
    80204874:	e54a                	sd	s2,136(sp)
    80204876:	e94e                	sd	s3,144(sp)
    80204878:	ed52                	sd	s4,152(sp)
    8020487a:	f156                	sd	s5,160(sp)
    8020487c:	f55a                	sd	s6,168(sp)
    8020487e:	f95e                	sd	s7,176(sp)
    80204880:	fd62                	sd	s8,184(sp)
    80204882:	e1e6                	sd	s9,192(sp)
    80204884:	e5ea                	sd	s10,200(sp)
    80204886:	e9ee                	sd	s11,208(sp)
    80204888:	edf2                	sd	t3,216(sp)
    8020488a:	f1f6                	sd	t4,224(sp)
    8020488c:	f5fa                	sd	t5,232(sp)
    8020488e:	f9fe                	sd	t6,240(sp)
    80204890:	850a                	mv	a0,sp
    80204892:	9d2fd0ef          	jal	80201a64 <kerneltrap>
    80204896:	6082                	ld	ra,0(sp)
    80204898:	61c2                	ld	gp,16(sp)
    8020489a:	6262                	ld	tp,24(sp)
    8020489c:	7282                	ld	t0,32(sp)
    8020489e:	7322                	ld	t1,40(sp)
    802048a0:	73c2                	ld	t2,48(sp)
    802048a2:	7462                	ld	s0,56(sp)
    802048a4:	6486                	ld	s1,64(sp)
    802048a6:	6526                	ld	a0,72(sp)
    802048a8:	65c6                	ld	a1,80(sp)
    802048aa:	6666                	ld	a2,88(sp)
    802048ac:	7686                	ld	a3,96(sp)
    802048ae:	7726                	ld	a4,104(sp)
    802048b0:	77c6                	ld	a5,112(sp)
    802048b2:	7866                	ld	a6,120(sp)
    802048b4:	688a                	ld	a7,128(sp)
    802048b6:	692a                	ld	s2,136(sp)
    802048b8:	69ca                	ld	s3,144(sp)
    802048ba:	6a6a                	ld	s4,152(sp)
    802048bc:	7a8a                	ld	s5,160(sp)
    802048be:	7b2a                	ld	s6,168(sp)
    802048c0:	7bca                	ld	s7,176(sp)
    802048c2:	7c6a                	ld	s8,184(sp)
    802048c4:	6c8e                	ld	s9,192(sp)
    802048c6:	6d2e                	ld	s10,200(sp)
    802048c8:	6dce                	ld	s11,208(sp)
    802048ca:	6e6e                	ld	t3,216(sp)
    802048cc:	7e8e                	ld	t4,224(sp)
    802048ce:	7f2e                	ld	t5,232(sp)
    802048d0:	7fce                	ld	t6,240(sp)
    802048d2:	6111                	add	sp,sp,256
    802048d4:	10200073          	sret

00000000802048d8 <restore_trapframe>:
    802048d8:	8faa                	mv	t6,a0
    802048da:	100022f3          	csrr	t0,sstatus
    802048de:	10000313          	li	t1,256
    802048e2:	10033073          	csrc	sstatus,t1
    802048e6:	018fbf03          	ld	t5,24(t6)
    802048ea:	141f1073          	csrw	sepc,t5
    802048ee:	028fb083          	ld	ra,40(t6)
    802048f2:	030fb103          	ld	sp,48(t6)
    802048f6:	038fb183          	ld	gp,56(t6)
    802048fa:	040fb203          	ld	tp,64(t6)
    802048fe:	048fb283          	ld	t0,72(t6)
    80204902:	050fb303          	ld	t1,80(t6)
    80204906:	058fb383          	ld	t2,88(t6)
    8020490a:	060fb403          	ld	s0,96(t6)
    8020490e:	068fb483          	ld	s1,104(t6)
    80204912:	070fb503          	ld	a0,112(t6)
    80204916:	078fb583          	ld	a1,120(t6)
    8020491a:	080fb603          	ld	a2,128(t6)
    8020491e:	088fb683          	ld	a3,136(t6)
    80204922:	090fb703          	ld	a4,144(t6)
    80204926:	098fb783          	ld	a5,152(t6)
    8020492a:	0a0fb803          	ld	a6,160(t6)
    8020492e:	0a8fb883          	ld	a7,168(t6)
    80204932:	0b0fb903          	ld	s2,176(t6)
    80204936:	0b8fb983          	ld	s3,184(t6)
    8020493a:	0c0fba03          	ld	s4,192(t6)
    8020493e:	0c8fba83          	ld	s5,200(t6)
    80204942:	0d0fbb03          	ld	s6,208(t6)
    80204946:	0d8fbb83          	ld	s7,216(t6)
    8020494a:	0e0fbc03          	ld	s8,224(t6)
    8020494e:	0e8fbc83          	ld	s9,232(t6)
    80204952:	0f0fbd03          	ld	s10,240(t6)
    80204956:	0f8fbd83          	ld	s11,248(t6)
    8020495a:	100fbe03          	ld	t3,256(t6)
    8020495e:	108fbe83          	ld	t4,264(t6)
    80204962:	110fbf03          	ld	t5,272(t6)
    80204966:	118fbf83          	ld	t6,280(t6)
    8020496a:	10200073          	sret

000000008020496e <swtch>:
    8020496e:	00153023          	sd	ra,0(a0)
    80204972:	00253423          	sd	sp,8(a0)
    80204976:	e900                	sd	s0,16(a0)
    80204978:	ed04                	sd	s1,24(a0)
    8020497a:	03253023          	sd	s2,32(a0)
    8020497e:	03353423          	sd	s3,40(a0)
    80204982:	03453823          	sd	s4,48(a0)
    80204986:	03553c23          	sd	s5,56(a0)
    8020498a:	05653023          	sd	s6,64(a0)
    8020498e:	05753423          	sd	s7,72(a0)
    80204992:	05853823          	sd	s8,80(a0)
    80204996:	05953c23          	sd	s9,88(a0)
    8020499a:	07a53023          	sd	s10,96(a0)
    8020499e:	07b53423          	sd	s11,104(a0)
    802049a2:	0005b083          	ld	ra,0(a1)
    802049a6:	0085b103          	ld	sp,8(a1)
    802049aa:	6980                	ld	s0,16(a1)
    802049ac:	6d84                	ld	s1,24(a1)
    802049ae:	0205b903          	ld	s2,32(a1)
    802049b2:	0285b983          	ld	s3,40(a1)
    802049b6:	0305ba03          	ld	s4,48(a1)
    802049ba:	0385ba83          	ld	s5,56(a1)
    802049be:	0405bb03          	ld	s6,64(a1)
    802049c2:	0485bb83          	ld	s7,72(a1)
    802049c6:	0505bc03          	ld	s8,80(a1)
    802049ca:	0585bc83          	ld	s9,88(a1)
    802049ce:	0605bd03          	ld	s10,96(a1)
    802049d2:	0685bd83          	ld	s11,104(a1)
    802049d6:	8082                	ret

00000000802049d8 <virtio_disk_init>:
        if (!(flag & 1)) break;
        i = next;
    }
}

void virtio_disk_init(void) {
    802049d8:	7179                	add	sp,sp,-48
    802049da:	f406                	sd	ra,40(sp)
    802049dc:	f022                	sd	s0,32(sp)
    802049de:	ec26                	sd	s1,24(sp)
    802049e0:	e84a                	sd	s2,16(sp)
    802049e2:	e44e                	sd	s3,8(sp)
    802049e4:	1800                	add	s0,sp,48
    uint32 status = 0;

    spinlock_init(&disk.lock, "virtio_disk");
    802049e6:	00002597          	auipc	a1,0x2
    802049ea:	ff258593          	add	a1,a1,-14 # 802069d8 <syscalls+0x408>
    802049ee:	0003d517          	auipc	a0,0x3d
    802049f2:	41a50513          	add	a0,a0,1050 # 80241e08 <disk+0x130>
    802049f6:	ffffc097          	auipc	ra,0xffffc
    802049fa:	de2080e7          	jalr	-542(ra) # 802007d8 <spinlock_init>
    return *mmio_reg(off);
    802049fe:	100017b7          	lui	a5,0x10001
    80204a02:	0007a903          	lw	s2,0(a5) # 10001000 <_start-0x701ff000>
    80204a06:	2901                	sext.w	s2,s2
    80204a08:	43c4                	lw	s1,4(a5)
    80204a0a:	2481                	sext.w	s1,s1
    80204a0c:	0087a983          	lw	s3,8(a5)
    80204a10:	2981                	sext.w	s3,s3
    80204a12:	47d8                	lw	a4,12(a5)
    uint32 magic = r32(VIRTIO_MMIO_MAGIC_VALUE);
    uint32 version = r32(VIRTIO_MMIO_VERSION);
    uint32 device_id = r32(VIRTIO_MMIO_DEVICE_ID);
    uint32 vendor_id = r32(VIRTIO_MMIO_VENDOR_ID);

    printf("virtio: magic=0x%x version=0x%x device=0x%x vendor=0x%x\n", magic, version, device_id, vendor_id);
    80204a14:	86ce                	mv	a3,s3
    80204a16:	8626                	mv	a2,s1
    80204a18:	85ca                	mv	a1,s2
    80204a1a:	00002517          	auipc	a0,0x2
    80204a1e:	fce50513          	add	a0,a0,-50 # 802069e8 <syscalls+0x418>
    80204a22:	ffffb097          	auipc	ra,0xffffb
    80204a26:	732080e7          	jalr	1842(ra) # 80200154 <printf>

    if (magic != 0x74726976 || device_id != 2) {
    80204a2a:	747277b7          	lui	a5,0x74727
    80204a2e:	97678793          	add	a5,a5,-1674 # 74726976 <_start-0xbad968a>
    80204a32:	00f91563          	bne	s2,a5,80204a3c <virtio_disk_init+0x64>
    80204a36:	4789                	li	a5,2
    80204a38:	00f98a63          	beq	s3,a5,80204a4c <virtio_disk_init+0x74>
        panic("virtio_disk_init: cannot find virtio disk");
    80204a3c:	00002517          	auipc	a0,0x2
    80204a40:	fec50513          	add	a0,a0,-20 # 80206a28 <syscalls+0x458>
    80204a44:	ffffc097          	auipc	ra,0xffffc
    80204a48:	990080e7          	jalr	-1648(ra) # 802003d4 <panic>
    *mmio_reg(off) = val;
    80204a4c:	100017b7          	lui	a5,0x10001
    80204a50:	0607a823          	sw	zero,112(a5) # 10001070 <_start-0x701fef90>
    80204a54:	4605                	li	a2,1
    80204a56:	dbb0                	sw	a2,112(a5)
    80204a58:	470d                	li	a4,3
    80204a5a:	dbb8                	sw	a4,112(a5)
    return *mmio_reg(off);
    80204a5c:	4b98                	lw	a4,16(a5)
    w32(VIRTIO_MMIO_STATUS, status);

    // 4. Negotiate features
    uint32 features = r32(VIRTIO_MMIO_DEVICE_FEATURES);
    features &= ~(1 << 28); // No indirect descriptors
    features &= ~(1 << 24); // No event idx
    80204a5e:	ef0006b7          	lui	a3,0xef000
    80204a62:	16fd                	add	a3,a3,-1 # ffffffffeeffffff <__bss_end+0xffffffff6edbe1df>
    80204a64:	8f75                	and	a4,a4,a3
    *mmio_reg(off) = val;
    80204a66:	d398                	sw	a4,32(a5)
    status |= 2;
    80204a68:	478d                	li	a5,3
    w32(VIRTIO_MMIO_DRIVER_FEATURES, features);

    // 5. Set FEATURES_OK (Only for Version 2, but harmless in v1 usually, skip for safety if v1)
    // Legacy doesn't strictly require this step check, but we set status.
    if (version >= 2) {
    80204a6a:	00967a63          	bgeu	a2,s1,80204a7e <virtio_disk_init+0xa6>
    *mmio_reg(off) = val;
    80204a6e:	100017b7          	lui	a5,0x10001
    80204a72:	471d                	li	a4,7
    80204a74:	dbb8                	sw	a4,112(a5)
    return *mmio_reg(off);
    80204a76:	5bb8                	lw	a4,112(a5)
        status |= 4;
        w32(VIRTIO_MMIO_STATUS, status);
        if (!(r32(VIRTIO_MMIO_STATUS) & 4))
    80204a78:	8b11                	and	a4,a4,4
        status |= 4;
    80204a7a:	479d                	li	a5,7
        if (!(r32(VIRTIO_MMIO_STATUS) & 4))
    80204a7c:	c755                	beqz	a4,80204b28 <virtio_disk_init+0x150>
            panic("virtio_disk_init: features");
    }

    // 6. Set DRIVER_OK status bit
    status |= 8;
    80204a7e:	0087e793          	or	a5,a5,8
    *mmio_reg(off) = val;
    80204a82:	10001737          	lui	a4,0x10001
    80204a86:	db3c                	sw	a5,112(a4)
    80204a88:	02072823          	sw	zero,48(a4) # 10001030 <_start-0x701fefd0>
    return *mmio_reg(off);
    80204a8c:	5b5c                	lw	a5,52(a4)
    80204a8e:	2781                	sext.w	a5,a5
    w32(VIRTIO_MMIO_STATUS, status);

    // 7. Config queue 0
    w32(VIRTIO_MMIO_QUEUE_SEL, 0);
    uint32 max = r32(VIRTIO_MMIO_QUEUE_NUM_MAX);
    if (max == 0) panic("virtio_disk_init: no queue 0");
    80204a90:	c7d5                	beqz	a5,80204b3c <virtio_disk_init+0x164>
    if (max < NUM) panic("virtio_disk_init: queue too short");
    80204a92:	471d                	li	a4,7
    80204a94:	0af77c63          	bgeu	a4,a5,80204b4c <virtio_disk_init+0x174>
    *mmio_reg(off) = val;
    80204a98:	100017b7          	lui	a5,0x10001
    80204a9c:	4721                	li	a4,8
    80204a9e:	df98                	sw	a4,56(a5)
    80204aa0:	6705                	lui	a4,0x1
    80204aa2:	d798                	sw	a4,40(a5)
    // containing Desc, Avail, and Used rings. 
    // QEMU calculates offsets based on Page Size (4096).
    
    w32(VIRTIO_MMIO_GUEST_PAGE_SIZE, 4096); // Set page size to 4096

    disk.pages = kalloc(); // Allocate 4096 bytes
    80204aa4:	ffffc097          	auipc	ra,0xffffc
    80204aa8:	b90080e7          	jalr	-1136(ra) # 80200634 <kalloc>
    80204aac:	0003d797          	auipc	a5,0x3d
    80204ab0:	22a7b623          	sd	a0,556(a5) # 80241cd8 <disk>
    if (!disk.pages) panic("virtio_disk_init: kalloc");
    80204ab4:	c54d                	beqz	a0,80204b5e <virtio_disk_init+0x186>
    memset(disk.pages, 0, PGSIZE);
    80204ab6:	0003d497          	auipc	s1,0x3d
    80204aba:	22248493          	add	s1,s1,546 # 80241cd8 <disk>
    80204abe:	6605                	lui	a2,0x1
    80204ac0:	4581                	li	a1,0
    80204ac2:	6088                	ld	a0,0(s1)
    80204ac4:	ffffc097          	auipc	ra,0xffffc
    80204ac8:	ede080e7          	jalr	-290(ra) # 802009a2 <memset>
    *mmio_reg(off) = val;
    80204acc:	10001737          	lui	a4,0x10001
    80204ad0:	6785                	lui	a5,0x1
    80204ad2:	df5c                	sw	a5,60(a4)
    // If we set PFN, QEMU expects physical address.
    
    // Let's try xv6-riscv standard way:
    // It assumes VIRTIO_MMIO_QUEUE_PFN points to the page.
    
    w32(VIRTIO_MMIO_QUEUE_PFN, (uint64)disk.pages >> 12);
    80204ad4:	609c                	ld	a5,0(s1)
    80204ad6:	83b1                	srl	a5,a5,0xc
    80204ad8:	2781                	sext.w	a5,a5
    *mmio_reg(off) = val;
    80204ada:	c33c                	sw	a5,64(a4)

    // Setup pointers manually for our software use
    disk.desc = (struct virtq_desc *)(disk.pages);
    80204adc:	609c                	ld	a5,0(s1)
    80204ade:	e49c                	sd	a5,8(s1)
    disk.avail = (struct virtq_avail *)(disk.pages + NUM * sizeof(struct virtq_desc));
    80204ae0:	08078793          	add	a5,a5,128 # 1080 <_start-0x801fef80>
    80204ae4:	e89c                	sd	a5,16(s1)
    *mmio_reg(off) = val;
    80204ae6:	08000793          	li	a5,128
    80204aea:	df5c                	sw	a5,60(a4)
    // Avail: 128. Size 6+16=22. End=150.
    // Used: RoundUp(150, 128) = 256.
    // So Used ring starts at offset 256.
    // Total size = 256 + 6 + 8*8 = 326 bytes. Fits in 4096.
    
    disk.used = (struct virtq_used *) (disk.pages + 256);
    80204aec:	609c                	ld	a5,0(s1)
    80204aee:	10078793          	add	a5,a5,256
    80204af2:	ec9c                	sd	a5,24(s1)

    for (int i = 0; i < NUM; i++) {
        disk.free[i] = 1;
    80204af4:	4785                	li	a5,1
    80204af6:	02f48023          	sb	a5,32(s1)
    80204afa:	02f480a3          	sb	a5,33(s1)
    80204afe:	02f48123          	sb	a5,34(s1)
    80204b02:	02f481a3          	sb	a5,35(s1)
    80204b06:	02f48223          	sb	a5,36(s1)
    80204b0a:	02f482a3          	sb	a5,37(s1)
    80204b0e:	02f48323          	sb	a5,38(s1)
    80204b12:	02f483a3          	sb	a5,39(s1)
    }
    disk.used_idx = 0;
    80204b16:	02049423          	sh	zero,40(s1)
}
    80204b1a:	70a2                	ld	ra,40(sp)
    80204b1c:	7402                	ld	s0,32(sp)
    80204b1e:	64e2                	ld	s1,24(sp)
    80204b20:	6942                	ld	s2,16(sp)
    80204b22:	69a2                	ld	s3,8(sp)
    80204b24:	6145                	add	sp,sp,48
    80204b26:	8082                	ret
            panic("virtio_disk_init: features");
    80204b28:	00002517          	auipc	a0,0x2
    80204b2c:	f3050513          	add	a0,a0,-208 # 80206a58 <syscalls+0x488>
    80204b30:	ffffc097          	auipc	ra,0xffffc
    80204b34:	8a4080e7          	jalr	-1884(ra) # 802003d4 <panic>
        status |= 4;
    80204b38:	479d                	li	a5,7
    80204b3a:	b791                	j	80204a7e <virtio_disk_init+0xa6>
    if (max == 0) panic("virtio_disk_init: no queue 0");
    80204b3c:	00002517          	auipc	a0,0x2
    80204b40:	f3c50513          	add	a0,a0,-196 # 80206a78 <syscalls+0x4a8>
    80204b44:	ffffc097          	auipc	ra,0xffffc
    80204b48:	890080e7          	jalr	-1904(ra) # 802003d4 <panic>
    if (max < NUM) panic("virtio_disk_init: queue too short");
    80204b4c:	00002517          	auipc	a0,0x2
    80204b50:	f4c50513          	add	a0,a0,-180 # 80206a98 <syscalls+0x4c8>
    80204b54:	ffffc097          	auipc	ra,0xffffc
    80204b58:	880080e7          	jalr	-1920(ra) # 802003d4 <panic>
    80204b5c:	bf35                	j	80204a98 <virtio_disk_init+0xc0>
    if (!disk.pages) panic("virtio_disk_init: kalloc");
    80204b5e:	00002517          	auipc	a0,0x2
    80204b62:	f6250513          	add	a0,a0,-158 # 80206ac0 <syscalls+0x4f0>
    80204b66:	ffffc097          	auipc	ra,0xffffc
    80204b6a:	86e080e7          	jalr	-1938(ra) # 802003d4 <panic>
    80204b6e:	b7a1                	j	80204ab6 <virtio_disk_init+0xde>

0000000080204b70 <virtio_disk_intr>:
    free_chain(idx[0]);

    release(&disk.lock);
}

void virtio_disk_intr(void) {
    80204b70:	1101                	add	sp,sp,-32
    80204b72:	ec06                	sd	ra,24(sp)
    80204b74:	e822                	sd	s0,16(sp)
    80204b76:	e426                	sd	s1,8(sp)
    80204b78:	e04a                	sd	s2,0(sp)
    80204b7a:	1000                	add	s0,sp,32
    acquire(&disk.lock);
    80204b7c:	0003d497          	auipc	s1,0x3d
    80204b80:	15c48493          	add	s1,s1,348 # 80241cd8 <disk>
    80204b84:	0003d517          	auipc	a0,0x3d
    80204b88:	28450513          	add	a0,a0,644 # 80241e08 <disk+0x130>
    80204b8c:	ffffc097          	auipc	ra,0xffffc
    80204b90:	cae080e7          	jalr	-850(ra) # 8020083a <acquire>
    __sync_synchronize();
    80204b94:	0ff0000f          	fence

    uint16 used_idx_dev = *(volatile uint16*)&disk.used->idx;
    80204b98:	6c9c                	ld	a5,24(s1)
    80204b9a:	0027d783          	lhu	a5,2(a5)

    while (disk.used_idx != used_idx_dev) {
    80204b9e:	0284d703          	lhu	a4,40(s1)
    80204ba2:	04f70c63          	beq	a4,a5,80204bfa <virtio_disk_intr+0x8a>
    80204ba6:	03079613          	sll	a2,a5,0x30
    80204baa:	9241                	srl	a2,a2,0x30
        __sync_synchronize();
        int id = disk.used->ring[disk.used_idx % NUM].id;
        disk.used_idx++;
        __sync_synchronize();

        if (id >= NUM) continue;
    80204bac:	491d                	li	s2,7
    80204bae:	a029                	j	80204bb8 <virtio_disk_intr+0x48>
    while (disk.used_idx != used_idx_dev) {
    80204bb0:	0284d783          	lhu	a5,40(s1)
    80204bb4:	04c78363          	beq	a5,a2,80204bfa <virtio_disk_intr+0x8a>
        __sync_synchronize();
    80204bb8:	0ff0000f          	fence
        int id = disk.used->ring[disk.used_idx % NUM].id;
    80204bbc:	0284d703          	lhu	a4,40(s1)
    80204bc0:	6c9c                	ld	a5,24(s1)
    80204bc2:	00777693          	and	a3,a4,7
    80204bc6:	068e                	sll	a3,a3,0x3
    80204bc8:	97b6                	add	a5,a5,a3
    80204bca:	43dc                	lw	a5,4(a5)
        disk.used_idx++;
    80204bcc:	2705                	addw	a4,a4,1 # 10001001 <_start-0x701fefff>
    80204bce:	02e49423          	sh	a4,40(s1)
        __sync_synchronize();
    80204bd2:	0ff0000f          	fence
        if (id >= NUM) continue;
    80204bd6:	fcf94de3          	blt	s2,a5,80204bb0 <virtio_disk_intr+0x40>
        struct buf *b = disk.info[id].b;
    80204bda:	0796                	sll	a5,a5,0x5
    80204bdc:	97a6                	add	a5,a5,s1
    80204bde:	7b88                	ld	a0,48(a5)
        if (b == 0) continue;
    80204be0:	d961                	beqz	a0,80204bb0 <virtio_disk_intr+0x40>

        b->disk = 0;
    80204be2:	00052223          	sw	zero,4(a0)
        wakeup(b);
    80204be6:	ffffd097          	auipc	ra,0xffffd
    80204bea:	cc8080e7          	jalr	-824(ra) # 802018ae <wakeup>
        
        used_idx_dev = *(volatile uint16*)&disk.used->idx;
    80204bee:	6c9c                	ld	a5,24(s1)
    80204bf0:	0027d603          	lhu	a2,2(a5)
    80204bf4:	1642                	sll	a2,a2,0x30
    80204bf6:	9241                	srl	a2,a2,0x30
    80204bf8:	bf65                	j	80204bb0 <virtio_disk_intr+0x40>
    }
    release(&disk.lock);
    80204bfa:	0003d517          	auipc	a0,0x3d
    80204bfe:	20e50513          	add	a0,a0,526 # 80241e08 <disk+0x130>
    80204c02:	ffffc097          	auipc	ra,0xffffc
    80204c06:	d2a080e7          	jalr	-726(ra) # 8020092c <release>
}
    80204c0a:	60e2                	ld	ra,24(sp)
    80204c0c:	6442                	ld	s0,16(sp)
    80204c0e:	64a2                	ld	s1,8(sp)
    80204c10:	6902                	ld	s2,0(sp)
    80204c12:	6105                	add	sp,sp,32
    80204c14:	8082                	ret

0000000080204c16 <virtio_disk_rw>:
void virtio_disk_rw(struct buf *b, int write) {
    80204c16:	711d                	add	sp,sp,-96
    80204c18:	ec86                	sd	ra,88(sp)
    80204c1a:	e8a2                	sd	s0,80(sp)
    80204c1c:	e4a6                	sd	s1,72(sp)
    80204c1e:	e0ca                	sd	s2,64(sp)
    80204c20:	fc4e                	sd	s3,56(sp)
    80204c22:	f852                	sd	s4,48(sp)
    80204c24:	f456                	sd	s5,40(sp)
    80204c26:	f05a                	sd	s6,32(sp)
    80204c28:	ec5e                	sd	s7,24(sp)
    80204c2a:	e862                	sd	s8,16(sp)
    80204c2c:	1080                	add	s0,sp,96
    80204c2e:	892a                	mv	s2,a0
    80204c30:	84ae                	mv	s1,a1
    acquire(&disk.lock);
    80204c32:	0003d517          	auipc	a0,0x3d
    80204c36:	1d650513          	add	a0,a0,470 # 80241e08 <disk+0x130>
    80204c3a:	ffffc097          	auipc	ra,0xffffc
    80204c3e:	c00080e7          	jalr	-1024(ra) # 8020083a <acquire>
    for (int i = 0; i < 3; i++) {
    80204c42:	fa040513          	add	a0,s0,-96
    80204c46:	fac40593          	add	a1,s0,-84
    for (int i = 0; i < NUM; i++) {
    80204c4a:	4801                	li	a6,0
    80204c4c:	4621                	li	a2,8
            disk.free[i] = 0;
    80204c4e:	0003d897          	auipc	a7,0x3d
    80204c52:	08a88893          	add	a7,a7,138 # 80241cd8 <disk>
    80204c56:	a039                	j	80204c64 <virtio_disk_rw+0x4e>
    80204c58:	00f88733          	add	a4,a7,a5
    80204c5c:	02070023          	sb	zero,32(a4)
        while ((idx[i] = alloc_desc()) < 0) { }
    80204c60:	0007df63          	bgez	a5,80204c7e <virtio_disk_rw+0x68>
    for (int i = 0; i < NUM; i++) {
    80204c64:	0003d717          	auipc	a4,0x3d
    80204c68:	07470713          	add	a4,a4,116 # 80241cd8 <disk>
    80204c6c:	87c2                	mv	a5,a6
        if (disk.free[i]) {
    80204c6e:	02074683          	lbu	a3,32(a4)
    80204c72:	f2fd                	bnez	a3,80204c58 <virtio_disk_rw+0x42>
    for (int i = 0; i < NUM; i++) {
    80204c74:	2785                	addw	a5,a5,1
    80204c76:	0705                	add	a4,a4,1
    80204c78:	fec79be3          	bne	a5,a2,80204c6e <virtio_disk_rw+0x58>
    80204c7c:	b7e5                	j	80204c64 <virtio_disk_rw+0x4e>
    80204c7e:	c11c                	sw	a5,0(a0)
    for (int i = 0; i < 3; i++) {
    80204c80:	0511                	add	a0,a0,4
    80204c82:	feb511e3          	bne	a0,a1,80204c64 <virtio_disk_rw+0x4e>
    struct virtio_blk_req *cmd = &disk.info[idx[0]].cmd;
    80204c86:	fa042a83          	lw	s5,-96(s0)
    80204c8a:	002a8993          	add	s3,s5,2
    80204c8e:	0996                	sll	s3,s3,0x5
    80204c90:	0003da17          	auipc	s4,0x3d
    80204c94:	048a0a13          	add	s4,s4,72 # 80241cd8 <disk>
    80204c98:	013a0b33          	add	s6,s4,s3
    memset(cmd, 0, sizeof(*cmd));
    80204c9c:	4641                	li	a2,16
    80204c9e:	4581                	li	a1,0
    80204ca0:	855a                	mv	a0,s6
    80204ca2:	ffffc097          	auipc	ra,0xffffc
    80204ca6:	d00080e7          	jalr	-768(ra) # 802009a2 <memset>
    cmd->type = write ? 1 : 0;
    80204caa:	009037b3          	snez	a5,s1
    80204cae:	00fb2023          	sw	a5,0(s6)
    cmd->reserved = 0;
    80204cb2:	000b2223          	sw	zero,4(s6)
    cmd->sector = (uint64)b->blockno * (BSIZE / 512);
    80204cb6:	00c96783          	lwu	a5,12(s2)
    80204cba:	0786                	sll	a5,a5,0x1
    80204cbc:	00fb3423          	sd	a5,8(s6)
    disk.desc[idx[0]].addr = (uint64)cmd;
    80204cc0:	004a9793          	sll	a5,s5,0x4
    80204cc4:	008a3703          	ld	a4,8(s4)
    80204cc8:	973e                	add	a4,a4,a5
    80204cca:	01673023          	sd	s6,0(a4)
    disk.desc[idx[0]].len = sizeof(*cmd);
    80204cce:	008a3703          	ld	a4,8(s4)
    80204cd2:	973e                	add	a4,a4,a5
    80204cd4:	46c1                	li	a3,16
    80204cd6:	c714                	sw	a3,8(a4)
    disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80204cd8:	008a3703          	ld	a4,8(s4)
    80204cdc:	973e                	add	a4,a4,a5
    80204cde:	4685                	li	a3,1
    80204ce0:	00d71623          	sh	a3,12(a4)
    disk.desc[idx[0]].next = idx[1];
    80204ce4:	fa442703          	lw	a4,-92(s0)
    80204ce8:	008a3683          	ld	a3,8(s4)
    80204cec:	97b6                	add	a5,a5,a3
    80204cee:	00e79723          	sh	a4,14(a5)
    disk.desc[idx[1]].addr = (uint64)b->data;
    80204cf2:	0712                	sll	a4,a4,0x4
    80204cf4:	008a3783          	ld	a5,8(s4)
    80204cf8:	97ba                	add	a5,a5,a4
    80204cfa:	05890693          	add	a3,s2,88
    80204cfe:	e394                	sd	a3,0(a5)
    disk.desc[idx[1]].len = BSIZE;
    80204d00:	008a3783          	ld	a5,8(s4)
    80204d04:	97ba                	add	a5,a5,a4
    80204d06:	40000693          	li	a3,1024
    80204d0a:	c794                	sw	a3,8(a5)
    if (write) disk.desc[idx[1]].flags = 0; 
    80204d0c:	14048063          	beqz	s1,80204e4c <virtio_disk_rw+0x236>
    80204d10:	0003d797          	auipc	a5,0x3d
    80204d14:	fd07b783          	ld	a5,-48(a5) # 80241ce0 <disk+0x8>
    80204d18:	97ba                	add	a5,a5,a4
    80204d1a:	00079623          	sh	zero,12(a5)
    disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80204d1e:	0003d797          	auipc	a5,0x3d
    80204d22:	fba78793          	add	a5,a5,-70 # 80241cd8 <disk>
    80204d26:	6794                	ld	a3,8(a5)
    80204d28:	96ba                	add	a3,a3,a4
    80204d2a:	00c6d603          	lhu	a2,12(a3)
    80204d2e:	00166613          	or	a2,a2,1
    80204d32:	00c69623          	sh	a2,12(a3)
    disk.desc[idx[1]].next = idx[2];
    80204d36:	fa842683          	lw	a3,-88(s0)
    80204d3a:	6790                	ld	a2,8(a5)
    80204d3c:	9732                	add	a4,a4,a2
    80204d3e:	00d71723          	sh	a3,14(a4)
    disk.info[idx[0]].status = 0xff;
    80204d42:	005a9613          	sll	a2,s5,0x5
    80204d46:	963e                	add	a2,a2,a5
    80204d48:	577d                	li	a4,-1
    80204d4a:	02e60c23          	sb	a4,56(a2) # 1038 <_start-0x801fefc8>
    disk.desc[idx[2]].addr = (uint64)&disk.info[idx[0]].status;
    80204d4e:	00469713          	sll	a4,a3,0x4
    80204d52:	678c                	ld	a1,8(a5)
    80204d54:	95ba                	add	a1,a1,a4
    80204d56:	ff898693          	add	a3,s3,-8
    80204d5a:	96be                	add	a3,a3,a5
    80204d5c:	e194                	sd	a3,0(a1)
    disk.desc[idx[2]].len = 1;
    80204d5e:	6794                	ld	a3,8(a5)
    80204d60:	96ba                	add	a3,a3,a4
    80204d62:	4585                	li	a1,1
    80204d64:	c68c                	sw	a1,8(a3)
    disk.desc[idx[2]].flags = VRING_DESC_F_WRITE;
    80204d66:	6794                	ld	a3,8(a5)
    80204d68:	96ba                	add	a3,a3,a4
    80204d6a:	4509                	li	a0,2
    80204d6c:	00a69623          	sh	a0,12(a3)
    disk.desc[idx[2]].next = 0;
    80204d70:	6794                	ld	a3,8(a5)
    80204d72:	9736                	add	a4,a4,a3
    80204d74:	00071723          	sh	zero,14(a4)
    b->disk = 1;
    80204d78:	00b92223          	sw	a1,4(s2)
    disk.info[idx[0]].b = b;
    80204d7c:	03263823          	sd	s2,48(a2)
    disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80204d80:	6b94                	ld	a3,16(a5)
    80204d82:	0026d703          	lhu	a4,2(a3)
    80204d86:	8b1d                	and	a4,a4,7
    80204d88:	0706                	sll	a4,a4,0x1
    80204d8a:	96ba                	add	a3,a3,a4
    80204d8c:	01569223          	sh	s5,4(a3)
    __sync_synchronize();
    80204d90:	0ff0000f          	fence
    disk.avail->idx++;
    80204d94:	6b98                	ld	a4,16(a5)
    80204d96:	00275783          	lhu	a5,2(a4)
    80204d9a:	2785                	addw	a5,a5,1
    80204d9c:	00f71123          	sh	a5,2(a4)
    __sync_synchronize();
    80204da0:	0ff0000f          	fence
    *mmio_reg(off) = val;
    80204da4:	100017b7          	lui	a5,0x10001
    80204da8:	0407a823          	sw	zero,80(a5) # 10001050 <_start-0x701fefb0>
    if (write) disk_writes++;
    80204dac:	c8cd                	beqz	s1,80204e5e <virtio_disk_rw+0x248>
    80204dae:	0000b717          	auipc	a4,0xb
    80204db2:	27a70713          	add	a4,a4,634 # 80210028 <disk_writes>
    80204db6:	631c                	ld	a5,0(a4)
    80204db8:	0785                	add	a5,a5,1
    80204dba:	e31c                	sd	a5,0(a4)
    while (*(volatile char*)&disk.info[idx[0]].status == 0xff) {
    80204dbc:	fa042a83          	lw	s5,-96(s0)
    80204dc0:	005a9713          	sll	a4,s5,0x5
    80204dc4:	0003d797          	auipc	a5,0x3d
    80204dc8:	f1478793          	add	a5,a5,-236 # 80241cd8 <disk>
    80204dcc:	97ba                	add	a5,a5,a4
    80204dce:	0387c783          	lbu	a5,56(a5)
    80204dd2:	0ff7f793          	zext.b	a5,a5
    80204dd6:	0ff00713          	li	a4,255
    80204dda:	04e79363          	bne	a5,a4,80204e20 <virtio_disk_rw+0x20a>
        release(&disk.lock);
    80204dde:	0003d497          	auipc	s1,0x3d
    80204de2:	02a48493          	add	s1,s1,42 # 80241e08 <disk+0x130>
    while (*(volatile char*)&disk.info[idx[0]].status == 0xff) {
    80204de6:	005a9793          	sll	a5,s5,0x5
    80204dea:	0003d997          	auipc	s3,0x3d
    80204dee:	eee98993          	add	s3,s3,-274 # 80241cd8 <disk>
    80204df2:	99be                	add	s3,s3,a5
    80204df4:	0ff00a13          	li	s4,255
        release(&disk.lock);
    80204df8:	8526                	mv	a0,s1
    80204dfa:	ffffc097          	auipc	ra,0xffffc
    80204dfe:	b32080e7          	jalr	-1230(ra) # 8020092c <release>
        virtio_disk_intr(); 
    80204e02:	00000097          	auipc	ra,0x0
    80204e06:	d6e080e7          	jalr	-658(ra) # 80204b70 <virtio_disk_intr>
        acquire(&disk.lock);
    80204e0a:	8526                	mv	a0,s1
    80204e0c:	ffffc097          	auipc	ra,0xffffc
    80204e10:	a2e080e7          	jalr	-1490(ra) # 8020083a <acquire>
    while (*(volatile char*)&disk.info[idx[0]].status == 0xff) {
    80204e14:	0389c783          	lbu	a5,56(s3)
    80204e18:	0ff7f793          	zext.b	a5,a5
    80204e1c:	fd478ee3          	beq	a5,s4,80204df8 <virtio_disk_rw+0x1e2>
    disk.info[idx[0]].b = 0;
    80204e20:	005a9713          	sll	a4,s5,0x5
    80204e24:	0003d797          	auipc	a5,0x3d
    80204e28:	eb478793          	add	a5,a5,-332 # 80241cd8 <disk>
    80204e2c:	97ba                	add	a5,a5,a4
    80204e2e:	0207b823          	sd	zero,48(a5)
    b->disk = 0;
    80204e32:	00092223          	sw	zero,4(s2)
        int flag = disk.desc[i].flags;
    80204e36:	0003d497          	auipc	s1,0x3d
    80204e3a:	ea248493          	add	s1,s1,-350 # 80241cd8 <disk>
    if (i >= NUM) panic("free_desc");
    80204e3e:	4b9d                	li	s7,7
    80204e40:	00002c17          	auipc	s8,0x2
    80204e44:	ca0c0c13          	add	s8,s8,-864 # 80206ae0 <syscalls+0x510>
    disk.free[i] = 1;
    80204e48:	4b05                	li	s6,1
    80204e4a:	a889                	j	80204e9c <virtio_disk_rw+0x286>
    else disk.desc[idx[1]].flags = VRING_DESC_F_WRITE;
    80204e4c:	0003d797          	auipc	a5,0x3d
    80204e50:	e947b783          	ld	a5,-364(a5) # 80241ce0 <disk+0x8>
    80204e54:	97ba                	add	a5,a5,a4
    80204e56:	4689                	li	a3,2
    80204e58:	00d79623          	sh	a3,12(a5)
    80204e5c:	b5c9                	j	80204d1e <virtio_disk_rw+0x108>
    else disk_reads++;
    80204e5e:	0000b717          	auipc	a4,0xb
    80204e62:	1d270713          	add	a4,a4,466 # 80210030 <disk_reads>
    80204e66:	631c                	ld	a5,0(a4)
    80204e68:	0785                	add	a5,a5,1
    80204e6a:	e31c                	sd	a5,0(a4)
    80204e6c:	bf81                	j	80204dbc <virtio_disk_rw+0x1a6>
    disk.desc[i].addr = 0;
    80204e6e:	649c                	ld	a5,8(s1)
    80204e70:	97ca                	add	a5,a5,s2
    80204e72:	0007b023          	sd	zero,0(a5)
    disk.desc[i].len = 0;
    80204e76:	649c                	ld	a5,8(s1)
    80204e78:	97ca                	add	a5,a5,s2
    80204e7a:	0007a423          	sw	zero,8(a5)
    disk.desc[i].flags = 0;
    80204e7e:	649c                	ld	a5,8(s1)
    80204e80:	97ca                	add	a5,a5,s2
    80204e82:	00079623          	sh	zero,12(a5)
    disk.desc[i].next = 0;
    80204e86:	649c                	ld	a5,8(s1)
    80204e88:	97ca                	add	a5,a5,s2
    80204e8a:	00079723          	sh	zero,14(a5)
    disk.free[i] = 1;
    80204e8e:	99a6                	add	s3,s3,s1
    80204e90:	03698023          	sb	s6,32(s3)
        if (!(flag & 1)) break;
    80204e94:	001a7a13          	and	s4,s4,1
    80204e98:	020a0363          	beqz	s4,80204ebe <virtio_disk_rw+0x2a8>
        int flag = disk.desc[i].flags;
    80204e9c:	004a9913          	sll	s2,s5,0x4
    80204ea0:	649c                	ld	a5,8(s1)
    80204ea2:	97ca                	add	a5,a5,s2
    80204ea4:	00c7da03          	lhu	s4,12(a5)
        int next = disk.desc[i].next;
    80204ea8:	89d6                	mv	s3,s5
    80204eaa:	00e7da83          	lhu	s5,14(a5)
    if (i >= NUM) panic("free_desc");
    80204eae:	fd3bd0e3          	bge	s7,s3,80204e6e <virtio_disk_rw+0x258>
    80204eb2:	8562                	mv	a0,s8
    80204eb4:	ffffb097          	auipc	ra,0xffffb
    80204eb8:	520080e7          	jalr	1312(ra) # 802003d4 <panic>
    80204ebc:	bf4d                	j	80204e6e <virtio_disk_rw+0x258>
    release(&disk.lock);
    80204ebe:	0003d517          	auipc	a0,0x3d
    80204ec2:	f4a50513          	add	a0,a0,-182 # 80241e08 <disk+0x130>
    80204ec6:	ffffc097          	auipc	ra,0xffffc
    80204eca:	a66080e7          	jalr	-1434(ra) # 8020092c <release>
}
    80204ece:	60e6                	ld	ra,88(sp)
    80204ed0:	6446                	ld	s0,80(sp)
    80204ed2:	64a6                	ld	s1,72(sp)
    80204ed4:	6906                	ld	s2,64(sp)
    80204ed6:	79e2                	ld	s3,56(sp)
    80204ed8:	7a42                	ld	s4,48(sp)
    80204eda:	7aa2                	ld	s5,40(sp)
    80204edc:	7b02                	ld	s6,32(sp)
    80204ede:	6be2                	ld	s7,24(sp)
    80204ee0:	6c42                	ld	s8,16(sp)
    80204ee2:	6125                	add	sp,sp,96
    80204ee4:	8082                	ret

0000000080204ee6 <get_disk_read_count>:

uint64 get_disk_read_count(void) { return disk_reads; }
    80204ee6:	1141                	add	sp,sp,-16
    80204ee8:	e422                	sd	s0,8(sp)
    80204eea:	0800                	add	s0,sp,16
    80204eec:	0000b517          	auipc	a0,0xb
    80204ef0:	14453503          	ld	a0,324(a0) # 80210030 <disk_reads>
    80204ef4:	6422                	ld	s0,8(sp)
    80204ef6:	0141                	add	sp,sp,16
    80204ef8:	8082                	ret

0000000080204efa <get_disk_write_count>:
uint64 get_disk_write_count(void) { return disk_writes; }
    80204efa:	1141                	add	sp,sp,-16
    80204efc:	e422                	sd	s0,8(sp)
    80204efe:	0800                	add	s0,sp,16
    80204f00:	0000b517          	auipc	a0,0xb
    80204f04:	12853503          	ld	a0,296(a0) # 80210028 <disk_writes>
    80204f08:	6422                	ld	s0,8(sp)
    80204f0a:	0141                	add	sp,sp,16
    80204f0c:	8082                	ret

0000000080204f0e <assert>:
#include "stat.h"

#define NULL ((void*)0)

void assert(int condition) {
    if (!condition) {
    80204f0e:	c111                	beqz	a0,80204f12 <assert+0x4>
    80204f10:	8082                	ret
void assert(int condition) {
    80204f12:	1141                	add	sp,sp,-16
    80204f14:	e406                	sd	ra,8(sp)
    80204f16:	e022                	sd	s0,0(sp)
    80204f18:	0800                	add	s0,sp,16
        printf("ASSERTION FAILED!\n");
    80204f1a:	00002517          	auipc	a0,0x2
    80204f1e:	bd650513          	add	a0,a0,-1066 # 80206af0 <syscalls+0x520>
    80204f22:	ffffb097          	auipc	ra,0xffffb
    80204f26:	232080e7          	jalr	562(ra) # 80200154 <printf>
        while(1);
    80204f2a:	a001                	j	80204f2a <assert+0x1c>

0000000080204f2c <test_cow_fork>:
    }
}

// 模拟 User 内存操作的测试
void test_cow_fork(void) {
    80204f2c:	7139                	add	sp,sp,-64
    80204f2e:	fc06                	sd	ra,56(sp)
    80204f30:	f822                	sd	s0,48(sp)
    80204f32:	f426                	sd	s1,40(sp)
    80204f34:	f04a                	sd	s2,32(sp)
    80204f36:	ec4e                	sd	s3,24(sp)
    80204f38:	e852                	sd	s4,16(sp)
    80204f3a:	e456                	sd	s5,8(sp)
    80204f3c:	e05a                	sd	s6,0(sp)
    80204f3e:	0080                	add	s0,sp,64
    printf("\n=== Project 5: COW Fork Test ===\n");
    80204f40:	00002517          	auipc	a0,0x2
    80204f44:	bc850513          	add	a0,a0,-1080 # 80206b08 <syscalls+0x538>
    80204f48:	ffffb097          	auipc	ra,0xffffb
    80204f4c:	20c080e7          	jalr	524(ra) # 80200154 <printf>

    // 1. 手动分配一个物理页，写入数据
    char *pa = kalloc();
    80204f50:	ffffb097          	auipc	ra,0xffffb
    80204f54:	6e4080e7          	jalr	1764(ra) # 80200634 <kalloc>
    80204f58:	84aa                	mv	s1,a0
    memset(pa, 0, PGSIZE);
    80204f5a:	6605                	lui	a2,0x1
    80204f5c:	4581                	li	a1,0
    80204f5e:	ffffc097          	auipc	ra,0xffffc
    80204f62:	a44080e7          	jalr	-1468(ra) # 802009a2 <memset>
    safestrcpy(pa, "PARENT DATA", 16);
    80204f66:	4641                	li	a2,16
    80204f68:	00002597          	auipc	a1,0x2
    80204f6c:	bc858593          	add	a1,a1,-1080 # 80206b30 <syscalls+0x560>
    80204f70:	8526                	mv	a0,s1
    80204f72:	ffffc097          	auipc	ra,0xffffc
    80204f76:	b7a080e7          	jalr	-1158(ra) # 80200aec <safestrcpy>
    int initial_ref = kref_get(pa);
    80204f7a:	8526                	mv	a0,s1
    80204f7c:	ffffb097          	auipc	ra,0xffffb
    80204f80:	7f0080e7          	jalr	2032(ra) # 8020076c <kref_get>
    80204f84:	862a                	mv	a2,a0
    printf("Allocated PA %p, Ref Count: %d\n", pa, initial_ref);
    80204f86:	85a6                	mv	a1,s1
    80204f88:	00002517          	auipc	a0,0x2
    80204f8c:	bb850513          	add	a0,a0,-1096 # 80206b40 <syscalls+0x570>
    80204f90:	ffffb097          	auipc	ra,0xffffb
    80204f94:	1c4080e7          	jalr	452(ra) # 80200154 <printf>

    // 2. 创建父页表
    pagetable_t parent_pt = create_pagetable();
    80204f98:	ffffc097          	auipc	ra,0xffffc
    80204f9c:	dfc080e7          	jalr	-516(ra) # 80200d94 <create_pagetable>
    80204fa0:	892a                	mv	s2,a0
    uint64 va = 0x1000;
    // 映射为可写
    map_page(parent_pt, va, (uint64)pa, PTE_R | PTE_W | PTE_U);
    80204fa2:	8a26                	mv	s4,s1
    80204fa4:	46d9                	li	a3,22
    80204fa6:	8626                	mv	a2,s1
    80204fa8:	6585                	lui	a1,0x1
    80204faa:	ffffc097          	auipc	ra,0xffffc
    80204fae:	e32080e7          	jalr	-462(ra) # 80200ddc <map_page>
    
    printf("Mapped VA %p to PA %p in Parent PT\n", va, pa);
    80204fb2:	8626                	mv	a2,s1
    80204fb4:	6585                	lui	a1,0x1
    80204fb6:	00002517          	auipc	a0,0x2
    80204fba:	baa50513          	add	a0,a0,-1110 # 80206b60 <syscalls+0x590>
    80204fbe:	ffffb097          	auipc	ra,0xffffb
    80204fc2:	196080e7          	jalr	406(ra) # 80200154 <printf>

    // 3. 模拟 Fork (uvmcopy)
    printf("Forking (uvmcopy)...\n");
    80204fc6:	00002517          	auipc	a0,0x2
    80204fca:	bc250513          	add	a0,a0,-1086 # 80206b88 <syscalls+0x5b8>
    80204fce:	ffffb097          	auipc	ra,0xffffb
    80204fd2:	186080e7          	jalr	390(ra) # 80200154 <printf>
    pagetable_t child_pt = create_pagetable();
    80204fd6:	ffffc097          	auipc	ra,0xffffc
    80204fda:	dbe080e7          	jalr	-578(ra) # 80200d94 <create_pagetable>
    80204fde:	8aaa                	mv	s5,a0
    uvmcopy(parent_pt, child_pt, va + PGSIZE); 
    80204fe0:	6609                	lui	a2,0x2
    80204fe2:	85aa                	mv	a1,a0
    80204fe4:	854a                	mv	a0,s2
    80204fe6:	ffffc097          	auipc	ra,0xffffc
    80204fea:	ec0080e7          	jalr	-320(ra) # 80200ea6 <uvmcopy>

    // 4. 验证 COW 状态
    pte_t *pte_p = walk_lookup(parent_pt, va);
    80204fee:	6585                	lui	a1,0x1
    80204ff0:	854a                	mv	a0,s2
    80204ff2:	ffffc097          	auipc	ra,0xffffc
    80204ff6:	dd0080e7          	jalr	-560(ra) # 80200dc2 <walk_lookup>
    80204ffa:	892a                	mv	s2,a0
    pte_t *pte_c = walk_lookup(child_pt, va);
    80204ffc:	6585                	lui	a1,0x1
    80204ffe:	8556                	mv	a0,s5
    80205000:	ffffc097          	auipc	ra,0xffffc
    80205004:	dc2080e7          	jalr	-574(ra) # 80200dc2 <walk_lookup>
    80205008:	8b2a                	mv	s6,a0

    int ref_after_fork = kref_get(pa);
    8020500a:	8526                	mv	a0,s1
    8020500c:	ffffb097          	auipc	ra,0xffffb
    80205010:	760080e7          	jalr	1888(ra) # 8020076c <kref_get>
    80205014:	89aa                	mv	s3,a0
    printf("Ref Count after fork: %d (Expected 2)\n", ref_after_fork);
    80205016:	85aa                	mv	a1,a0
    80205018:	00002517          	auipc	a0,0x2
    8020501c:	b8850513          	add	a0,a0,-1144 # 80206ba0 <syscalls+0x5d0>
    80205020:	ffffb097          	auipc	ra,0xffffb
    80205024:	134080e7          	jalr	308(ra) # 80200154 <printf>
    
    if (ref_after_fork != 2) panic("COW Test Fail: Ref count incorrect");
    80205028:	4789                	li	a5,2
    8020502a:	12f99363          	bne	s3,a5,80205150 <test_cow_fork+0x224>
    if (*pte_p & PTE_W) panic("COW Test Fail: Parent still writable");
    8020502e:	00093783          	ld	a5,0(s2)
    80205032:	8b91                	and	a5,a5,4
    80205034:	12079763          	bnez	a5,80205162 <test_cow_fork+0x236>
    if (*pte_c & PTE_W) panic("COW Test Fail: Child still writable");
    80205038:	000b3783          	ld	a5,0(s6)
    8020503c:	8b91                	and	a5,a5,4
    8020503e:	12079b63          	bnez	a5,80205174 <test_cow_fork+0x248>
    if (!(*pte_p & PTE_COW)) panic("COW Test Fail: Parent COW bit not set");
    80205042:	00093783          	ld	a5,0(s2)
    80205046:	1007f793          	and	a5,a5,256
    8020504a:	12078e63          	beqz	a5,80205186 <test_cow_fork+0x25a>
    if (!(*pte_c & PTE_COW)) panic("COW Test Fail: Child COW bit not set");
    8020504e:	000b3783          	ld	a5,0(s6)
    80205052:	1007f793          	and	a5,a5,256
    80205056:	14078163          	beqz	a5,80205198 <test_cow_fork+0x26c>

    printf("COW flags set correctly. Write permission removed.\n");
    8020505a:	00002517          	auipc	a0,0x2
    8020505e:	c3650513          	add	a0,a0,-970 # 80206c90 <syscalls+0x6c0>
    80205062:	ffffb097          	auipc	ra,0xffffb
    80205066:	0f2080e7          	jalr	242(ra) # 80200154 <printf>

    // 5. 模拟写操作触发 Page Fault (Child Write)
    printf("Simulating Child Write to VA %p (Triggering Page Fault)...\n", va);
    8020506a:	6585                	lui	a1,0x1
    8020506c:	00002517          	auipc	a0,0x2
    80205070:	c5c50513          	add	a0,a0,-932 # 80206cc8 <syscalls+0x6f8>
    80205074:	ffffb097          	auipc	ra,0xffffb
    80205078:	0e0080e7          	jalr	224(ra) # 80200154 <printf>
    
    // 手动调用 cow_alloc 模拟 trap handler 的行为
    if (cow_alloc(child_pt, va) < 0) panic("COW Allocation Failed");
    8020507c:	6585                	lui	a1,0x1
    8020507e:	8556                	mv	a0,s5
    80205080:	ffffc097          	auipc	ra,0xffffc
    80205084:	d7a080e7          	jalr	-646(ra) # 80200dfa <cow_alloc>
    80205088:	12054163          	bltz	a0,802051aa <test_cow_fork+0x27e>

    // 6. 验证写后状态
    pte_c = walk_lookup(child_pt, va);
    8020508c:	6585                	lui	a1,0x1
    8020508e:	8556                	mv	a0,s5
    80205090:	ffffc097          	auipc	ra,0xffffc
    80205094:	d32080e7          	jalr	-718(ra) # 80200dc2 <walk_lookup>
    80205098:	89aa                	mv	s3,a0
    uint64 pa_child_new = PTE2PA(*pte_c);
    8020509a:	00053903          	ld	s2,0(a0)
    8020509e:	00a95913          	srl	s2,s2,0xa
    802050a2:	0932                	sll	s2,s2,0xc
    
    printf("Child New PA: %p\n", (void*)pa_child_new);
    802050a4:	85ca                	mv	a1,s2
    802050a6:	00002517          	auipc	a0,0x2
    802050aa:	c7a50513          	add	a0,a0,-902 # 80206d20 <syscalls+0x750>
    802050ae:	ffffb097          	auipc	ra,0xffffb
    802050b2:	0a6080e7          	jalr	166(ra) # 80200154 <printf>
    
    if (pa_child_new == (uint64)pa) panic("COW Test Fail: Child still points to old PA");
    802050b6:	112a0363          	beq	s4,s2,802051bc <test_cow_fork+0x290>
    if (!(*pte_c & PTE_W)) panic("COW Test Fail: Child page not writable after fault");
    802050ba:	0009b783          	ld	a5,0(s3)
    802050be:	8b91                	and	a5,a5,4
    802050c0:	10078763          	beqz	a5,802051ce <test_cow_fork+0x2a2>
    if (*pte_c & PTE_COW) panic("COW Test Fail: Child COW bit still set");
    802050c4:	0009b783          	ld	a5,0(s3)
    802050c8:	1007f793          	and	a5,a5,256
    802050cc:	10079a63          	bnez	a5,802051e0 <test_cow_fork+0x2b4>

    int ref_after_write = kref_get(pa);
    802050d0:	8526                	mv	a0,s1
    802050d2:	ffffb097          	auipc	ra,0xffffb
    802050d6:	69a080e7          	jalr	1690(ra) # 8020076c <kref_get>
    802050da:	89aa                	mv	s3,a0
    printf("Old PA Ref Count: %d (Expected 1)\n", ref_after_write);
    802050dc:	85aa                	mv	a1,a0
    802050de:	00002517          	auipc	a0,0x2
    802050e2:	cea50513          	add	a0,a0,-790 # 80206dc8 <syscalls+0x7f8>
    802050e6:	ffffb097          	auipc	ra,0xffffb
    802050ea:	06e080e7          	jalr	110(ra) # 80200154 <printf>
    if (ref_after_write != 1) panic("COW Test Fail: Old PA ref count did not decrease");
    802050ee:	4785                	li	a5,1
    802050f0:	10f99163          	bne	s3,a5,802051f2 <test_cow_fork+0x2c6>

    // 验证数据独立性
    char *child_mem = (char*)pa_child_new;
    child_mem[0] = 'C'; // Modify child data
    802050f4:	04300793          	li	a5,67
    802050f8:	00f90023          	sb	a5,0(s2)
    
    if (pa[0] == 'C') panic("COW Test Fail: Parent data modified!");
    802050fc:	0004c703          	lbu	a4,0(s1)
    80205100:	10f70263          	beq	a4,a5,80205204 <test_cow_fork+0x2d8>
    
    printf("Data independence verified. Parent: '%s', Child: '%s'\n", pa, child_mem);
    80205104:	864a                	mv	a2,s2
    80205106:	85a6                	mv	a1,s1
    80205108:	00002517          	auipc	a0,0x2
    8020510c:	d4850513          	add	a0,a0,-696 # 80206e50 <syscalls+0x880>
    80205110:	ffffb097          	auipc	ra,0xffffb
    80205114:	044080e7          	jalr	68(ra) # 80200154 <printf>

    // 清理
    kfree(pa); // Free Parent (旧页，引用计数降为 0)
    80205118:	8526                	mv	a0,s1
    8020511a:	ffffb097          	auipc	ra,0xffffb
    8020511e:	324080e7          	jalr	804(ra) # 8020043e <kfree>
    kfree((void*)pa_child_new); // Free Child (新页，引用计数降为 0)
    80205122:	854a                	mv	a0,s2
    80205124:	ffffb097          	auipc	ra,0xffffb
    80205128:	31a080e7          	jalr	794(ra) # 8020043e <kfree>
    
    printf("=== COW Fork Test Passed ===\n");
    8020512c:	00002517          	auipc	a0,0x2
    80205130:	d5c50513          	add	a0,a0,-676 # 80206e88 <syscalls+0x8b8>
    80205134:	ffffb097          	auipc	ra,0xffffb
    80205138:	020080e7          	jalr	32(ra) # 80200154 <printf>
}
    8020513c:	70e2                	ld	ra,56(sp)
    8020513e:	7442                	ld	s0,48(sp)
    80205140:	74a2                	ld	s1,40(sp)
    80205142:	7902                	ld	s2,32(sp)
    80205144:	69e2                	ld	s3,24(sp)
    80205146:	6a42                	ld	s4,16(sp)
    80205148:	6aa2                	ld	s5,8(sp)
    8020514a:	6b02                	ld	s6,0(sp)
    8020514c:	6121                	add	sp,sp,64
    8020514e:	8082                	ret
    if (ref_after_fork != 2) panic("COW Test Fail: Ref count incorrect");
    80205150:	00002517          	auipc	a0,0x2
    80205154:	a7850513          	add	a0,a0,-1416 # 80206bc8 <syscalls+0x5f8>
    80205158:	ffffb097          	auipc	ra,0xffffb
    8020515c:	27c080e7          	jalr	636(ra) # 802003d4 <panic>
    80205160:	b5f9                	j	8020502e <test_cow_fork+0x102>
    if (*pte_p & PTE_W) panic("COW Test Fail: Parent still writable");
    80205162:	00002517          	auipc	a0,0x2
    80205166:	a8e50513          	add	a0,a0,-1394 # 80206bf0 <syscalls+0x620>
    8020516a:	ffffb097          	auipc	ra,0xffffb
    8020516e:	26a080e7          	jalr	618(ra) # 802003d4 <panic>
    80205172:	b5d9                	j	80205038 <test_cow_fork+0x10c>
    if (*pte_c & PTE_W) panic("COW Test Fail: Child still writable");
    80205174:	00002517          	auipc	a0,0x2
    80205178:	aa450513          	add	a0,a0,-1372 # 80206c18 <syscalls+0x648>
    8020517c:	ffffb097          	auipc	ra,0xffffb
    80205180:	258080e7          	jalr	600(ra) # 802003d4 <panic>
    80205184:	bd7d                	j	80205042 <test_cow_fork+0x116>
    if (!(*pte_p & PTE_COW)) panic("COW Test Fail: Parent COW bit not set");
    80205186:	00002517          	auipc	a0,0x2
    8020518a:	aba50513          	add	a0,a0,-1350 # 80206c40 <syscalls+0x670>
    8020518e:	ffffb097          	auipc	ra,0xffffb
    80205192:	246080e7          	jalr	582(ra) # 802003d4 <panic>
    80205196:	bd65                	j	8020504e <test_cow_fork+0x122>
    if (!(*pte_c & PTE_COW)) panic("COW Test Fail: Child COW bit not set");
    80205198:	00002517          	auipc	a0,0x2
    8020519c:	ad050513          	add	a0,a0,-1328 # 80206c68 <syscalls+0x698>
    802051a0:	ffffb097          	auipc	ra,0xffffb
    802051a4:	234080e7          	jalr	564(ra) # 802003d4 <panic>
    802051a8:	bd4d                	j	8020505a <test_cow_fork+0x12e>
    if (cow_alloc(child_pt, va) < 0) panic("COW Allocation Failed");
    802051aa:	00002517          	auipc	a0,0x2
    802051ae:	b5e50513          	add	a0,a0,-1186 # 80206d08 <syscalls+0x738>
    802051b2:	ffffb097          	auipc	ra,0xffffb
    802051b6:	222080e7          	jalr	546(ra) # 802003d4 <panic>
    802051ba:	bdc9                	j	8020508c <test_cow_fork+0x160>
    if (pa_child_new == (uint64)pa) panic("COW Test Fail: Child still points to old PA");
    802051bc:	00002517          	auipc	a0,0x2
    802051c0:	b7c50513          	add	a0,a0,-1156 # 80206d38 <syscalls+0x768>
    802051c4:	ffffb097          	auipc	ra,0xffffb
    802051c8:	210080e7          	jalr	528(ra) # 802003d4 <panic>
    802051cc:	b5fd                	j	802050ba <test_cow_fork+0x18e>
    if (!(*pte_c & PTE_W)) panic("COW Test Fail: Child page not writable after fault");
    802051ce:	00002517          	auipc	a0,0x2
    802051d2:	b9a50513          	add	a0,a0,-1126 # 80206d68 <syscalls+0x798>
    802051d6:	ffffb097          	auipc	ra,0xffffb
    802051da:	1fe080e7          	jalr	510(ra) # 802003d4 <panic>
    802051de:	b5dd                	j	802050c4 <test_cow_fork+0x198>
    if (*pte_c & PTE_COW) panic("COW Test Fail: Child COW bit still set");
    802051e0:	00002517          	auipc	a0,0x2
    802051e4:	bc050513          	add	a0,a0,-1088 # 80206da0 <syscalls+0x7d0>
    802051e8:	ffffb097          	auipc	ra,0xffffb
    802051ec:	1ec080e7          	jalr	492(ra) # 802003d4 <panic>
    802051f0:	b5c5                	j	802050d0 <test_cow_fork+0x1a4>
    if (ref_after_write != 1) panic("COW Test Fail: Old PA ref count did not decrease");
    802051f2:	00002517          	auipc	a0,0x2
    802051f6:	bfe50513          	add	a0,a0,-1026 # 80206df0 <syscalls+0x820>
    802051fa:	ffffb097          	auipc	ra,0xffffb
    802051fe:	1da080e7          	jalr	474(ra) # 802003d4 <panic>
    80205202:	bdcd                	j	802050f4 <test_cow_fork+0x1c8>
    if (pa[0] == 'C') panic("COW Test Fail: Parent data modified!");
    80205204:	00002517          	auipc	a0,0x2
    80205208:	c2450513          	add	a0,a0,-988 # 80206e28 <syscalls+0x858>
    8020520c:	ffffb097          	auipc	ra,0xffffb
    80205210:	1c8080e7          	jalr	456(ra) # 802003d4 <panic>
    80205214:	bdc5                	j	80205104 <test_cow_fork+0x1d8>

0000000080205216 <run_cow_tests>:

void run_cow_tests(void) {
    80205216:	1141                	add	sp,sp,-16
    80205218:	e406                	sd	ra,8(sp)
    8020521a:	e022                	sd	s0,0(sp)
    8020521c:	0800                	add	s0,sp,16
    test_cow_fork();
    8020521e:	00000097          	auipc	ra,0x0
    80205222:	d0e080e7          	jalr	-754(ra) # 80204f2c <test_cow_fork>
}
    80205226:	60a2                	ld	ra,8(sp)
    80205228:	6402                	ld	s0,0(sp)
    8020522a:	0141                	add	sp,sp,16
    8020522c:	8082                	ret

000000008020522e <run_lab6_tests>:

// 存根
void run_lab6_tests(void) {}
    8020522e:	1141                	add	sp,sp,-16
    80205230:	e422                	sd	s0,8(sp)
    80205232:	0800                	add	s0,sp,16
    80205234:	6422                	ld	s0,8(sp)
    80205236:	0141                	add	sp,sp,16
    80205238:	8082                	ret

000000008020523a <run_lab7_tests>:
void run_lab7_tests(void) {}
    8020523a:	1141                	add	sp,sp,-16
    8020523c:	e422                	sd	s0,8(sp)
    8020523e:	0800                	add	s0,sp,16
    80205240:	6422                	ld	s0,8(sp)
    80205242:	0141                	add	sp,sp,16
    80205244:	8082                	ret
	...
