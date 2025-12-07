
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
    80200048:	38f000ef          	jal	80200bd6 <kmain>

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
    8020080a:	b7e080e7          	jalr	-1154(ra) # 80201384 <mycpu>
    8020080e:	5d3c                	lw	a5,120(a0)
    80200810:	cf89                	beqz	a5,8020082a <push_off+0x3c>
        mycpu()->intena = old;
    }
    mycpu()->ncli += 1;
    80200812:	00001097          	auipc	ra,0x1
    80200816:	b72080e7          	jalr	-1166(ra) # 80201384 <mycpu>
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
    8020082e:	b5a080e7          	jalr	-1190(ra) # 80201384 <mycpu>
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
    80200878:	b10080e7          	jalr	-1264(ra) # 80201384 <mycpu>
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
    80200892:	af6080e7          	jalr	-1290(ra) # 80201384 <mycpu>
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
    802008d4:	ab4080e7          	jalr	-1356(ra) # 80201384 <mycpu>
    802008d8:	5d3c                	lw	a5,120(a0)
    802008da:	37fd                	addw	a5,a5,-1
    802008dc:	dd3c                	sw	a5,120(a0)
    if (mycpu()->ncli < 0) {
    802008de:	00001097          	auipc	ra,0x1
    802008e2:	aa6080e7          	jalr	-1370(ra) # 80201384 <mycpu>
    802008e6:	5d3c                	lw	a5,120(a0)
    802008e8:	0007cc63          	bltz	a5,80200900 <pop_off+0x52>
        printf("pop_off: ncli < 0\n");
        while(1);
    }
    if (mycpu()->ncli == 0 && mycpu()->intena) {
    802008ec:	00001097          	auipc	ra,0x1
    802008f0:	a98080e7          	jalr	-1384(ra) # 80201384 <mycpu>
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
    80200916:	a72080e7          	jalr	-1422(ra) # 80201384 <mycpu>
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
    80200b34:	868080e7          	jalr	-1944(ra) # 80201398 <myproc>
    80200b38:	4d4c                	lw	a1,28(a0)
    80200b3a:	00005517          	auipc	a0,0x5
    80200b3e:	68650513          	add	a0,a0,1670 # 802061c0 <_etext+0x1c0>
    80200b42:	fffff097          	auipc	ra,0xfffff
    80200b46:	612080e7          	jalr	1554(ra) # 80200154 <printf>
    
    // 将需要I/O同步的初始化移到进程中执行
    binit();
    80200b4a:	00001097          	auipc	ra,0x1
    80200b4e:	31c080e7          	jalr	796(ra) # 80201e66 <binit>
    fileinit();
    80200b52:	00003097          	auipc	ra,0x3
    80200b56:	dde080e7          	jalr	-546(ra) # 80203930 <fileinit>
    
    printf("DEBUG: Device Inits Done\n"); // binit/fileinit 不做 I/O，但放在这里保持结构
    80200b5a:	00005517          	auipc	a0,0x5
    80200b5e:	68e50513          	add	a0,a0,1678 # 802061e8 <_etext+0x1e8>
    80200b62:	fffff097          	auipc	ra,0xfffff
    80200b66:	5f2080e7          	jalr	1522(ra) # 80200154 <printf>
    
    virtio_disk_init(); // 可能会有 I/O
    80200b6a:	00004097          	auipc	ra,0x4
    80200b6e:	e5e080e7          	jalr	-418(ra) # 802049c8 <virtio_disk_init>
    printf("DEBUG: VirtIO Init Done\n");
    80200b72:	00005517          	auipc	a0,0x5
    80200b76:	69650513          	add	a0,a0,1686 # 80206208 <_etext+0x208>
    80200b7a:	fffff097          	auipc	ra,0xfffff
    80200b7e:	5da080e7          	jalr	1498(ra) # 80200154 <printf>

    iinit();
    80200b82:	00002097          	auipc	ra,0x2
    80200b86:	94c080e7          	jalr	-1716(ra) # 802024ce <iinit>
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
    80200ba8:	920080e7          	jalr	-1760(ra) # 802034c4 <initlog>
    printf("DEBUG: Log Init Done\n");
    80200bac:	00005517          	auipc	a0,0x5
    80200bb0:	69450513          	add	a0,a0,1684 # 80206240 <_etext+0x240>
    80200bb4:	fffff097          	auipc	ra,0xfffff
    80200bb8:	5a0080e7          	jalr	1440(ra) # 80200154 <printf>

    printf("===== Test: Copy-on-Write Fork System =====\n");
    80200bbc:	00005517          	auipc	a0,0x5
    80200bc0:	69c50513          	add	a0,a0,1692 # 80206258 <_etext+0x258>
    80200bc4:	fffff097          	auipc	ra,0xfffff
    80200bc8:	590080e7          	jalr	1424(ra) # 80200154 <printf>
    test_cow_fork();
    80200bcc:	00004097          	auipc	ra,0x4
    80200bd0:	350080e7          	jalr	848(ra) # 80204f1c <test_cow_fork>
    while (1);
    80200bd4:	a001                	j	80200bd4 <main_task+0xac>

0000000080200bd6 <kmain>:
}


void kmain(void) {
    80200bd6:	1141                	add	sp,sp,-16
    80200bd8:	e406                	sd	ra,8(sp)
    80200bda:	e022                	sd	s0,0(sp)
    80200bdc:	0800                	add	s0,sp,16
    clear_screen();
    80200bde:	fffff097          	auipc	ra,0xfffff
    80200be2:	7c8080e7          	jalr	1992(ra) # 802003a6 <clear_screen>
    printf("===== Kernel Booting =====\n");
    80200be6:	00005517          	auipc	a0,0x5
    80200bea:	6a250513          	add	a0,a0,1698 # 80206288 <_etext+0x288>
    80200bee:	fffff097          	auipc	ra,0xfffff
    80200bf2:	566080e7          	jalr	1382(ra) # 80200154 <printf>
    
    // 只需要内存和进程/中断的基础初始化
    kinit();
    80200bf6:	00000097          	auipc	ra,0x0
    80200bfa:	966080e7          	jalr	-1690(ra) # 8020055c <kinit>
    kvminit();
    80200bfe:	00000097          	auipc	ra,0x0
    80200c02:	3d8080e7          	jalr	984(ra) # 80200fd6 <kvminit>
    kvminithart();
    80200c06:	00000097          	auipc	ra,0x0
    80200c0a:	4e2080e7          	jalr	1250(ra) # 802010e8 <kvminithart>
    procinit();
    80200c0e:	00000097          	auipc	ra,0x0
    80200c12:	7b8080e7          	jalr	1976(ra) # 802013c6 <procinit>
    trap_init();
    80200c16:	00001097          	auipc	ra,0x1
    80200c1a:	dba080e7          	jalr	-582(ra) # 802019d0 <trap_init>
    clock_init();
    80200c1e:	00001097          	auipc	ra,0x1
    80200c22:	dca080e7          	jalr	-566(ra) # 802019e8 <clock_init>
    
    // I/O 驱动自身的初始化 (不进行实际 I/O)
    // 即使这里不调用，virtio_disk_init() 也会在 main_task 里被调用
    
    if (create_process(main_task) < 0) {
    80200c26:	00000517          	auipc	a0,0x0
    80200c2a:	f0250513          	add	a0,a0,-254 # 80200b28 <main_task>
    80200c2e:	00000097          	auipc	ra,0x0
    80200c32:	7f4080e7          	jalr	2036(ra) # 80201422 <create_process>
    80200c36:	00054663          	bltz	a0,80200c42 <kmain+0x6c>
        printf("kmain: failed to create main_task\n");
        while(1);
    }

    scheduler();
    80200c3a:	00001097          	auipc	ra,0x1
    80200c3e:	994080e7          	jalr	-1644(ra) # 802015ce <scheduler>
        printf("kmain: failed to create main_task\n");
    80200c42:	00005517          	auipc	a0,0x5
    80200c46:	66650513          	add	a0,a0,1638 # 802062a8 <_etext+0x2a8>
    80200c4a:	fffff097          	auipc	ra,0xfffff
    80200c4e:	50a080e7          	jalr	1290(ra) # 80200154 <printf>
        while(1);
    80200c52:	a001                	j	80200c52 <kmain+0x7c>

0000000080200c54 <walk>:
// 外部符号，由链接脚本定义
extern char etext[]; 

// 遍历页表，找到指定虚拟地址对应的PTE。
static pte_t *walk(pagetable_t pagetable, uint64 va, int alloc) {
    if (va >= (1L << 39)) {
    80200c54:	57fd                	li	a5,-1
    80200c56:	83e5                	srl	a5,a5,0x19
    80200c58:	08b7e963          	bltu	a5,a1,80200cea <walk+0x96>
static pte_t *walk(pagetable_t pagetable, uint64 va, int alloc) {
    80200c5c:	7139                	add	sp,sp,-64
    80200c5e:	fc06                	sd	ra,56(sp)
    80200c60:	f822                	sd	s0,48(sp)
    80200c62:	f426                	sd	s1,40(sp)
    80200c64:	f04a                	sd	s2,32(sp)
    80200c66:	ec4e                	sd	s3,24(sp)
    80200c68:	e852                	sd	s4,16(sp)
    80200c6a:	e456                	sd	s5,8(sp)
    80200c6c:	e05a                	sd	s6,0(sp)
    80200c6e:	0080                	add	s0,sp,64
    80200c70:	84aa                	mv	s1,a0
    80200c72:	89ae                	mv	s3,a1
    80200c74:	8ab2                	mv	s5,a2
    80200c76:	4a79                	li	s4,30
        return 0; // 虚拟地址过大
    }
    
    for (int level = 2; level > 0; level--) {
    80200c78:	4b31                	li	s6,12
    80200c7a:	a80d                	j	80200cac <walk+0x58>
        pte_t *pte = &pagetable[VPN(va, level)];
        if (*pte & PTE_V) {
            pagetable = (pagetable_t)PTE2PA(*pte);
        } else {
            if (!alloc || (pagetable = (pagetable_t)kalloc()) == 0) {
    80200c7c:	060a8963          	beqz	s5,80200cee <walk+0x9a>
    80200c80:	00000097          	auipc	ra,0x0
    80200c84:	9b4080e7          	jalr	-1612(ra) # 80200634 <kalloc>
    80200c88:	84aa                	mv	s1,a0
    80200c8a:	c531                	beqz	a0,80200cd6 <walk+0x82>
                return 0; // 分配失败
            }
            memset(pagetable, 0, PGSIZE);
    80200c8c:	6605                	lui	a2,0x1
    80200c8e:	4581                	li	a1,0
    80200c90:	00000097          	auipc	ra,0x0
    80200c94:	d12080e7          	jalr	-750(ra) # 802009a2 <memset>
            *pte = PA2PTE(pagetable) | PTE_V;
    80200c98:	00c4d793          	srl	a5,s1,0xc
    80200c9c:	07aa                	sll	a5,a5,0xa
    80200c9e:	0017e793          	or	a5,a5,1
    80200ca2:	00f93023          	sd	a5,0(s2)
    for (int level = 2; level > 0; level--) {
    80200ca6:	3a5d                	addw	s4,s4,-9
    80200ca8:	036a0063          	beq	s4,s6,80200cc8 <walk+0x74>
        pte_t *pte = &pagetable[VPN(va, level)];
    80200cac:	0149d933          	srl	s2,s3,s4
    80200cb0:	1ff97913          	and	s2,s2,511
    80200cb4:	090e                	sll	s2,s2,0x3
    80200cb6:	9926                	add	s2,s2,s1
        if (*pte & PTE_V) {
    80200cb8:	00093483          	ld	s1,0(s2)
    80200cbc:	0014f793          	and	a5,s1,1
    80200cc0:	dfd5                	beqz	a5,80200c7c <walk+0x28>
            pagetable = (pagetable_t)PTE2PA(*pte);
    80200cc2:	80a9                	srl	s1,s1,0xa
    80200cc4:	04b2                	sll	s1,s1,0xc
    80200cc6:	b7c5                	j	80200ca6 <walk+0x52>
        }
    }
    return &pagetable[VPN(va, 0)];
    80200cc8:	00c9d993          	srl	s3,s3,0xc
    80200ccc:	1ff9f993          	and	s3,s3,511
    80200cd0:	098e                	sll	s3,s3,0x3
    80200cd2:	01348533          	add	a0,s1,s3
}
    80200cd6:	70e2                	ld	ra,56(sp)
    80200cd8:	7442                	ld	s0,48(sp)
    80200cda:	74a2                	ld	s1,40(sp)
    80200cdc:	7902                	ld	s2,32(sp)
    80200cde:	69e2                	ld	s3,24(sp)
    80200ce0:	6a42                	ld	s4,16(sp)
    80200ce2:	6aa2                	ld	s5,8(sp)
    80200ce4:	6b02                	ld	s6,0(sp)
    80200ce6:	6121                	add	sp,sp,64
    80200ce8:	8082                	ret
        return 0; // 虚拟地址过大
    80200cea:	4501                	li	a0,0
}
    80200cec:	8082                	ret
                return 0; // 分配失败
    80200cee:	4501                	li	a0,0
    80200cf0:	b7dd                	j	80200cd6 <walk+0x82>

0000000080200cf2 <mappages>:

// 创建内核页表
int mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm) {
    80200cf2:	715d                	add	sp,sp,-80
    80200cf4:	e486                	sd	ra,72(sp)
    80200cf6:	e0a2                	sd	s0,64(sp)
    80200cf8:	fc26                	sd	s1,56(sp)
    80200cfa:	f84a                	sd	s2,48(sp)
    80200cfc:	f44e                	sd	s3,40(sp)
    80200cfe:	f052                	sd	s4,32(sp)
    80200d00:	ec56                	sd	s5,24(sp)
    80200d02:	e85a                	sd	s6,16(sp)
    80200d04:	e45e                	sd	s7,8(sp)
    80200d06:	0880                	add	s0,sp,80
    80200d08:	8aaa                	mv	s5,a0
    80200d0a:	8b3a                	mv	s6,a4
    uint64 a, last;
    pte_t *pte;

    a = PGROUNDDOWN(va);
    80200d0c:	777d                	lui	a4,0xfffff
    80200d0e:	00e5f7b3          	and	a5,a1,a4
    last = PGROUNDDOWN(va + size - 1);
    80200d12:	fff60993          	add	s3,a2,-1 # fff <_start-0x801ff001>
    80200d16:	99ae                	add	s3,s3,a1
    80200d18:	00e9f9b3          	and	s3,s3,a4
    a = PGROUNDDOWN(va);
    80200d1c:	893e                	mv	s2,a5
    80200d1e:	40f68a33          	sub	s4,a3,a5
        }
        *pte = PA2PTE(pa) | perm | PTE_V;
        if (a == last) {
            break;
        }
        a += PGSIZE;
    80200d22:	6b85                	lui	s7,0x1
    80200d24:	a821                	j	80200d3c <mappages+0x4a>
            printf("mappages: remap is not supported\n");
    80200d26:	00005517          	auipc	a0,0x5
    80200d2a:	5aa50513          	add	a0,a0,1450 # 802062d0 <_etext+0x2d0>
    80200d2e:	fffff097          	auipc	ra,0xfffff
    80200d32:	426080e7          	jalr	1062(ra) # 80200154 <printf>
            return -1;
    80200d36:	557d                	li	a0,-1
    80200d38:	a81d                	j	80200d6e <mappages+0x7c>
        a += PGSIZE;
    80200d3a:	995e                	add	s2,s2,s7
    for (;;) {
    80200d3c:	012a04b3          	add	s1,s4,s2
        if ((pte = walk(pagetable, a, 1)) == 0) {
    80200d40:	4605                	li	a2,1
    80200d42:	85ca                	mv	a1,s2
    80200d44:	8556                	mv	a0,s5
    80200d46:	00000097          	auipc	ra,0x0
    80200d4a:	f0e080e7          	jalr	-242(ra) # 80200c54 <walk>
    80200d4e:	cd19                	beqz	a0,80200d6c <mappages+0x7a>
        if (*pte & PTE_V) {
    80200d50:	611c                	ld	a5,0(a0)
    80200d52:	8b85                	and	a5,a5,1
    80200d54:	fbe9                	bnez	a5,80200d26 <mappages+0x34>
        *pte = PA2PTE(pa) | perm | PTE_V;
    80200d56:	80b1                	srl	s1,s1,0xc
    80200d58:	04aa                	sll	s1,s1,0xa
    80200d5a:	0164e4b3          	or	s1,s1,s6
    80200d5e:	0014e493          	or	s1,s1,1
    80200d62:	e104                	sd	s1,0(a0)
        if (a == last) {
    80200d64:	fd391be3          	bne	s2,s3,80200d3a <mappages+0x48>
        pa += PGSIZE;
    }
    return 0;
    80200d68:	4501                	li	a0,0
    80200d6a:	a011                	j	80200d6e <mappages+0x7c>
            return -1;
    80200d6c:	557d                	li	a0,-1
}
    80200d6e:	60a6                	ld	ra,72(sp)
    80200d70:	6406                	ld	s0,64(sp)
    80200d72:	74e2                	ld	s1,56(sp)
    80200d74:	7942                	ld	s2,48(sp)
    80200d76:	79a2                	ld	s3,40(sp)
    80200d78:	7a02                	ld	s4,32(sp)
    80200d7a:	6ae2                	ld	s5,24(sp)
    80200d7c:	6b42                	ld	s6,16(sp)
    80200d7e:	6ba2                	ld	s7,8(sp)
    80200d80:	6161                	add	sp,sp,80
    80200d82:	8082                	ret

0000000080200d84 <create_pagetable>:

// 创建一个空的页表
pagetable_t create_pagetable(void) {
    80200d84:	1101                	add	sp,sp,-32
    80200d86:	ec06                	sd	ra,24(sp)
    80200d88:	e822                	sd	s0,16(sp)
    80200d8a:	e426                	sd	s1,8(sp)
    80200d8c:	1000                	add	s0,sp,32
    pagetable_t pt = (pagetable_t)kalloc();
    80200d8e:	00000097          	auipc	ra,0x0
    80200d92:	8a6080e7          	jalr	-1882(ra) # 80200634 <kalloc>
    80200d96:	84aa                	mv	s1,a0
    if (pt == 0) return 0;
    80200d98:	c519                	beqz	a0,80200da6 <create_pagetable+0x22>
    memset(pt, 0, PGSIZE);
    80200d9a:	6605                	lui	a2,0x1
    80200d9c:	4581                	li	a1,0
    80200d9e:	00000097          	auipc	ra,0x0
    80200da2:	c04080e7          	jalr	-1020(ra) # 802009a2 <memset>
    return pt;
}
    80200da6:	8526                	mv	a0,s1
    80200da8:	60e2                	ld	ra,24(sp)
    80200daa:	6442                	ld	s0,16(sp)
    80200dac:	64a2                	ld	s1,8(sp)
    80200dae:	6105                	add	sp,sp,32
    80200db0:	8082                	ret

0000000080200db2 <walk_lookup>:

// 查找 PTE
pte_t *walk_lookup(pagetable_t pt, uint64 va) {
    80200db2:	1141                	add	sp,sp,-16
    80200db4:	e406                	sd	ra,8(sp)
    80200db6:	e022                	sd	s0,0(sp)
    80200db8:	0800                	add	s0,sp,16
    return walk(pt, va, 0);
    80200dba:	4601                	li	a2,0
    80200dbc:	00000097          	auipc	ra,0x0
    80200dc0:	e98080e7          	jalr	-360(ra) # 80200c54 <walk>
}
    80200dc4:	60a2                	ld	ra,8(sp)
    80200dc6:	6402                	ld	s0,0(sp)
    80200dc8:	0141                	add	sp,sp,16
    80200dca:	8082                	ret

0000000080200dcc <map_page>:

// 映射单个页
int map_page(pagetable_t pt, uint64 va, uint64 pa, int perm) {
    80200dcc:	1141                	add	sp,sp,-16
    80200dce:	e406                	sd	ra,8(sp)
    80200dd0:	e022                	sd	s0,0(sp)
    80200dd2:	0800                	add	s0,sp,16
    80200dd4:	8736                	mv	a4,a3
    return mappages(pt, va, PGSIZE, pa, perm);
    80200dd6:	86b2                	mv	a3,a2
    80200dd8:	6605                	lui	a2,0x1
    80200dda:	00000097          	auipc	ra,0x0
    80200dde:	f18080e7          	jalr	-232(ra) # 80200cf2 <mappages>
}
    80200de2:	60a2                	ld	ra,8(sp)
    80200de4:	6402                	ld	s0,0(sp)
    80200de6:	0141                	add	sp,sp,16
    80200de8:	8082                	ret

0000000080200dea <cow_alloc>:
int cow_alloc(pagetable_t pagetable, uint64 va) {
    uint64 pa;
    pte_t *pte;
    uint flags;

    if (va >= (1L << 39)) return -1;
    80200dea:	57fd                	li	a5,-1
    80200dec:	83e5                	srl	a5,a5,0x19
    80200dee:	08b7ec63          	bltu	a5,a1,80200e86 <cow_alloc+0x9c>
int cow_alloc(pagetable_t pagetable, uint64 va) {
    80200df2:	7179                	add	sp,sp,-48
    80200df4:	f406                	sd	ra,40(sp)
    80200df6:	f022                	sd	s0,32(sp)
    80200df8:	ec26                	sd	s1,24(sp)
    80200dfa:	e84a                	sd	s2,16(sp)
    80200dfc:	e44e                	sd	s3,8(sp)
    80200dfe:	1800                	add	s0,sp,48

    va = PGROUNDDOWN(va);
    pte = walk_lookup(pagetable, va);
    80200e00:	77fd                	lui	a5,0xfffff
    80200e02:	8dfd                	and	a1,a1,a5
    80200e04:	00000097          	auipc	ra,0x0
    80200e08:	fae080e7          	jalr	-82(ra) # 80200db2 <walk_lookup>
    80200e0c:	89aa                	mv	s3,a0
    if (pte == 0) return -1;
    80200e0e:	cd35                	beqz	a0,80200e8a <cow_alloc+0xa0>
    if ((*pte & PTE_V) == 0) return -1;
    80200e10:	610c                	ld	a1,0(a0)
    80200e12:	0015f793          	and	a5,a1,1
    80200e16:	cfa5                	beqz	a5,80200e8e <cow_alloc+0xa4>
    
    // 检查是否是 COW 页 (必须是只读，且设置了 COW 标志)
    if ((*pte & PTE_COW) == 0 || (*pte & PTE_W)) {
    80200e18:	1045f793          	and	a5,a1,260
    80200e1c:	10000713          	li	a4,256
    80200e20:	06e79963          	bne	a5,a4,80200e92 <cow_alloc+0xa8>
        return -1; 
    }

    pa = PTE2PA(*pte);
    80200e24:	81a9                	srl	a1,a1,0xa
    80200e26:	00c59913          	sll	s2,a1,0xc

    // 分配新物理页
    char *mem = kalloc();
    80200e2a:	00000097          	auipc	ra,0x0
    80200e2e:	80a080e7          	jalr	-2038(ra) # 80200634 <kalloc>
    80200e32:	84aa                	mv	s1,a0
    if (mem == 0) {
    80200e34:	cd1d                	beqz	a0,80200e72 <cow_alloc+0x88>
        printf("cow_alloc: kalloc failed\n");
        return -1;
    }

    // 复制旧页内容到新页
    memmove(mem, (char*)pa, PGSIZE);
    80200e36:	6605                	lui	a2,0x1
    80200e38:	85ca                	mv	a1,s2
    80200e3a:	00000097          	auipc	ra,0x0
    80200e3e:	b8a080e7          	jalr	-1142(ra) # 802009c4 <memmove>

    // 修改 PTE：指向新页，设置 Write，清除 COW
    flags = PTE_FLAGS(*pte);
    80200e42:	0009b783          	ld	a5,0(s3)
    flags |= PTE_W;
    flags &= ~PTE_COW;
    80200e46:	2ff7f793          	and	a5,a5,767
    
    *pte = PA2PTE(mem) | flags;
    80200e4a:	0047e793          	or	a5,a5,4
    80200e4e:	80b1                	srl	s1,s1,0xc
    80200e50:	04aa                	sll	s1,s1,0xa
    80200e52:	8fc5                	or	a5,a5,s1
    80200e54:	00f9b023          	sd	a5,0(s3)

    // 减少旧物理页的引用计数
    kfree((void*)pa);
    80200e58:	854a                	mv	a0,s2
    80200e5a:	fffff097          	auipc	ra,0xfffff
    80200e5e:	5e4080e7          	jalr	1508(ra) # 8020043e <kfree>

    return 0;
    80200e62:	4501                	li	a0,0
}
    80200e64:	70a2                	ld	ra,40(sp)
    80200e66:	7402                	ld	s0,32(sp)
    80200e68:	64e2                	ld	s1,24(sp)
    80200e6a:	6942                	ld	s2,16(sp)
    80200e6c:	69a2                	ld	s3,8(sp)
    80200e6e:	6145                	add	sp,sp,48
    80200e70:	8082                	ret
        printf("cow_alloc: kalloc failed\n");
    80200e72:	00005517          	auipc	a0,0x5
    80200e76:	48650513          	add	a0,a0,1158 # 802062f8 <_etext+0x2f8>
    80200e7a:	fffff097          	auipc	ra,0xfffff
    80200e7e:	2da080e7          	jalr	730(ra) # 80200154 <printf>
        return -1;
    80200e82:	557d                	li	a0,-1
    80200e84:	b7c5                	j	80200e64 <cow_alloc+0x7a>
    if (va >= (1L << 39)) return -1;
    80200e86:	557d                	li	a0,-1
}
    80200e88:	8082                	ret
    if (pte == 0) return -1;
    80200e8a:	557d                	li	a0,-1
    80200e8c:	bfe1                	j	80200e64 <cow_alloc+0x7a>
    if ((*pte & PTE_V) == 0) return -1;
    80200e8e:	557d                	li	a0,-1
    80200e90:	bfd1                	j	80200e64 <cow_alloc+0x7a>
        return -1; 
    80200e92:	557d                	li	a0,-1
    80200e94:	bfc1                	j	80200e64 <cow_alloc+0x7a>

0000000080200e96 <uvmcopy>:
int uvmcopy(pagetable_t old, pagetable_t new, uint64 sz) {
    pte_t *pte;
    uint64 pa, i;
    uint flags;

    for (i = 0; i < sz; i += PGSIZE) {
    80200e96:	c269                	beqz	a2,80200f58 <uvmcopy+0xc2>
int uvmcopy(pagetable_t old, pagetable_t new, uint64 sz) {
    80200e98:	711d                	add	sp,sp,-96
    80200e9a:	ec86                	sd	ra,88(sp)
    80200e9c:	e8a2                	sd	s0,80(sp)
    80200e9e:	e4a6                	sd	s1,72(sp)
    80200ea0:	e0ca                	sd	s2,64(sp)
    80200ea2:	fc4e                	sd	s3,56(sp)
    80200ea4:	f852                	sd	s4,48(sp)
    80200ea6:	f456                	sd	s5,40(sp)
    80200ea8:	f05a                	sd	s6,32(sp)
    80200eaa:	ec5e                	sd	s7,24(sp)
    80200eac:	e862                	sd	s8,16(sp)
    80200eae:	e466                	sd	s9,8(sp)
    80200eb0:	1080                	add	s0,sp,96
    80200eb2:	89aa                	mv	s3,a0
    80200eb4:	8b2e                	mv	s6,a1
    80200eb6:	8932                	mv	s2,a2
    for (i = 0; i < sz; i += PGSIZE) {
    80200eb8:	4481                	li	s1,0
            continue; // 跳过未映射的页
        if ((*pte & PTE_V) == 0)
            continue; 
        
        // 跳过不可读的页 (如 guard page)
        if (!(*pte & PTE_R))
    80200eba:	4a8d                	li	s5,3
            *pte = PA2PTE(pa) | flags; 
        }

        // 将相同的物理页映射到子进程
        if (map_page(new, i, pa, flags) != 0) {
            panic("uvmcopy: map_page failed");
    80200ebc:	00005c17          	auipc	s8,0x5
    80200ec0:	45cc0c13          	add	s8,s8,1116 # 80206318 <_etext+0x318>
            *pte = PA2PTE(pa) | flags; 
    80200ec4:	7bfd                	lui	s7,0xfffff
    80200ec6:	002bdb93          	srl	s7,s7,0x2
    for (i = 0; i < sz; i += PGSIZE) {
    80200eca:	6a05                	lui	s4,0x1
    80200ecc:	a80d                	j	80200efe <uvmcopy+0x68>
            flags &= ~PTE_W;
    80200ece:	3fb6f713          	and	a4,a3,1019
            flags |= PTE_COW;
    80200ed2:	10076693          	or	a3,a4,256
            *pte = PA2PTE(pa) | flags; 
    80200ed6:	0177f7b3          	and	a5,a5,s7
    80200eda:	8fd5                	or	a5,a5,a3
    80200edc:	e11c                	sd	a5,0(a0)
        if (map_page(new, i, pa, flags) != 0) {
    80200ede:	8666                	mv	a2,s9
    80200ee0:	85a6                	mv	a1,s1
    80200ee2:	855a                	mv	a0,s6
    80200ee4:	00000097          	auipc	ra,0x0
    80200ee8:	ee8080e7          	jalr	-280(ra) # 80200dcc <map_page>
    80200eec:	e121                	bnez	a0,80200f2c <uvmcopy+0x96>
        }

        // 增加物理页的引用计数
        kref_inc((void*)pa);
    80200eee:	8566                	mv	a0,s9
    80200ef0:	00000097          	auipc	ra,0x0
    80200ef4:	804080e7          	jalr	-2044(ra) # 802006f4 <kref_inc>
    for (i = 0; i < sz; i += PGSIZE) {
    80200ef8:	94d2                	add	s1,s1,s4
    80200efa:	0324ff63          	bgeu	s1,s2,80200f38 <uvmcopy+0xa2>
        if ((pte = walk_lookup(old, i)) == 0)
    80200efe:	85a6                	mv	a1,s1
    80200f00:	854e                	mv	a0,s3
    80200f02:	00000097          	auipc	ra,0x0
    80200f06:	eb0080e7          	jalr	-336(ra) # 80200db2 <walk_lookup>
    80200f0a:	d57d                	beqz	a0,80200ef8 <uvmcopy+0x62>
        if ((*pte & PTE_V) == 0)
    80200f0c:	611c                	ld	a5,0(a0)
        if (!(*pte & PTE_R))
    80200f0e:	0037f713          	and	a4,a5,3
    80200f12:	ff5713e3          	bne	a4,s5,80200ef8 <uvmcopy+0x62>
        pa = PTE2PA(*pte);
    80200f16:	00a7dc93          	srl	s9,a5,0xa
    80200f1a:	0cb2                	sll	s9,s9,0xc
        flags = PTE_FLAGS(*pte);
    80200f1c:	0007869b          	sext.w	a3,a5
        if (flags & PTE_W) {
    80200f20:	0047f713          	and	a4,a5,4
    80200f24:	f74d                	bnez	a4,80200ece <uvmcopy+0x38>
        flags = PTE_FLAGS(*pte);
    80200f26:	3ff6f693          	and	a3,a3,1023
    80200f2a:	bf55                	j	80200ede <uvmcopy+0x48>
            panic("uvmcopy: map_page failed");
    80200f2c:	8562                	mv	a0,s8
    80200f2e:	fffff097          	auipc	ra,0xfffff
    80200f32:	4a6080e7          	jalr	1190(ra) # 802003d4 <panic>
    80200f36:	bf65                	j	80200eee <uvmcopy+0x58>
static inline uint64 r_sepc() { uint64 x; asm volatile("csrr %0, sepc" : "=r" (x)); return x; }
static inline void w_sepc(uint64 x) { asm volatile("csrw sepc, %0" : : "r" (x)); }
static inline uint64 r_stval() { uint64 x; asm volatile("csrr %0, stval" : "=r" (x) ); return x; }
static inline uint64 r_satp() { uint64 x; asm volatile("csrr %0, satp" : "=r" (x)); return x; }
static inline void w_satp(uint64 x) { asm volatile("csrw satp, %0" : : "r" (x)); }
static inline void sfence_vma() { asm volatile("sfence.vma zero, zero"); }
    80200f38:	12000073          	sfence.vma
    }
    // 刷新 TLB，因为我们在父进程中移除了 PTE_W
    sfence_vma();
    return 0;
}
    80200f3c:	4501                	li	a0,0
    80200f3e:	60e6                	ld	ra,88(sp)
    80200f40:	6446                	ld	s0,80(sp)
    80200f42:	64a6                	ld	s1,72(sp)
    80200f44:	6906                	ld	s2,64(sp)
    80200f46:	79e2                	ld	s3,56(sp)
    80200f48:	7a42                	ld	s4,48(sp)
    80200f4a:	7aa2                	ld	s5,40(sp)
    80200f4c:	7b02                	ld	s6,32(sp)
    80200f4e:	6be2                	ld	s7,24(sp)
    80200f50:	6c42                	ld	s8,16(sp)
    80200f52:	6ca2                	ld	s9,8(sp)
    80200f54:	6125                	add	sp,sp,96
    80200f56:	8082                	ret
    80200f58:	12000073          	sfence.vma
    80200f5c:	4501                	li	a0,0
    80200f5e:	8082                	ret

0000000080200f60 <uvmunmap>:

// 释放用户内存映射
void uvmunmap(pagetable_t pt, uint64 va, uint64 npages, int do_free) {
    80200f60:	7139                	add	sp,sp,-64
    80200f62:	fc06                	sd	ra,56(sp)
    80200f64:	f822                	sd	s0,48(sp)
    80200f66:	f426                	sd	s1,40(sp)
    80200f68:	f04a                	sd	s2,32(sp)
    80200f6a:	ec4e                	sd	s3,24(sp)
    80200f6c:	e852                	sd	s4,16(sp)
    80200f6e:	e456                	sd	s5,8(sp)
    80200f70:	e05a                	sd	s6,0(sp)
    80200f72:	0080                	add	s0,sp,64
    uint64 a;
    pte_t *pte;

    for (a = va; a < va + npages * PGSIZE; a += PGSIZE) {
    80200f74:	0632                	sll	a2,a2,0xc
    80200f76:	00b609b3          	add	s3,a2,a1
    80200f7a:	0535f263          	bgeu	a1,s3,80200fbe <uvmunmap+0x5e>
    80200f7e:	8a2a                	mv	s4,a0
    80200f80:	892e                	mv	s2,a1
    80200f82:	8ab6                	mv	s5,a3
    80200f84:	6b05                	lui	s6,0x1
    80200f86:	a031                	j	80200f92 <uvmunmap+0x32>
        
        uint64 pa = PTE2PA(*pte);
        if (do_free) {
            kfree((void*)pa); // kfree 会自动处理引用计数
        }
        *pte = 0;
    80200f88:	0004b023          	sd	zero,0(s1)
    for (a = va; a < va + npages * PGSIZE; a += PGSIZE) {
    80200f8c:	995a                	add	s2,s2,s6
    80200f8e:	03397863          	bgeu	s2,s3,80200fbe <uvmunmap+0x5e>
        if ((pte = walk_lookup(pt, a)) == 0) continue; 
    80200f92:	85ca                	mv	a1,s2
    80200f94:	8552                	mv	a0,s4
    80200f96:	00000097          	auipc	ra,0x0
    80200f9a:	e1c080e7          	jalr	-484(ra) # 80200db2 <walk_lookup>
    80200f9e:	84aa                	mv	s1,a0
    80200fa0:	d575                	beqz	a0,80200f8c <uvmunmap+0x2c>
        if ((*pte & PTE_V) == 0) continue;
    80200fa2:	611c                	ld	a5,0(a0)
    80200fa4:	0017f713          	and	a4,a5,1
    80200fa8:	d375                	beqz	a4,80200f8c <uvmunmap+0x2c>
        if (do_free) {
    80200faa:	fc0a8fe3          	beqz	s5,80200f88 <uvmunmap+0x28>
        uint64 pa = PTE2PA(*pte);
    80200fae:	83a9                	srl	a5,a5,0xa
            kfree((void*)pa); // kfree 会自动处理引用计数
    80200fb0:	00c79513          	sll	a0,a5,0xc
    80200fb4:	fffff097          	auipc	ra,0xfffff
    80200fb8:	48a080e7          	jalr	1162(ra) # 8020043e <kfree>
    80200fbc:	b7f1                	j	80200f88 <uvmunmap+0x28>
    80200fbe:	12000073          	sfence.vma
    }
    sfence_vma();
}
    80200fc2:	70e2                	ld	ra,56(sp)
    80200fc4:	7442                	ld	s0,48(sp)
    80200fc6:	74a2                	ld	s1,40(sp)
    80200fc8:	7902                	ld	s2,32(sp)
    80200fca:	69e2                	ld	s3,24(sp)
    80200fcc:	6a42                	ld	s4,16(sp)
    80200fce:	6aa2                	ld	s5,8(sp)
    80200fd0:	6b02                	ld	s6,0(sp)
    80200fd2:	6121                	add	sp,sp,64
    80200fd4:	8082                	ret

0000000080200fd6 <kvminit>:

void kvminit(void) {
    80200fd6:	1101                	add	sp,sp,-32
    80200fd8:	ec06                	sd	ra,24(sp)
    80200fda:	e822                	sd	s0,16(sp)
    80200fdc:	e426                	sd	s1,8(sp)
    80200fde:	1000                	add	s0,sp,32
    extern char etext[]; 
    
    kernel_pagetable = (pagetable_t)kalloc();
    80200fe0:	fffff097          	auipc	ra,0xfffff
    80200fe4:	654080e7          	jalr	1620(ra) # 80200634 <kalloc>
    80200fe8:	0000f497          	auipc	s1,0xf
    80200fec:	01848493          	add	s1,s1,24 # 80210000 <kernel_pagetable>
    80200ff0:	e088                	sd	a0,0(s1)
    memset(kernel_pagetable, 0, PGSIZE);
    80200ff2:	6605                	lui	a2,0x1
    80200ff4:	4581                	li	a1,0
    80200ff6:	00000097          	auipc	ra,0x0
    80200ffa:	9ac080e7          	jalr	-1620(ra) # 802009a2 <memset>

    // 映射 UART 设备
    if (mappages(kernel_pagetable, 0x10000000, PGSIZE, 0x10000000, PTE_R | PTE_W) < 0)
    80200ffe:	4719                	li	a4,6
    80201000:	100006b7          	lui	a3,0x10000
    80201004:	6605                	lui	a2,0x1
    80201006:	100005b7          	lui	a1,0x10000
    8020100a:	6088                	ld	a0,0(s1)
    8020100c:	00000097          	auipc	ra,0x0
    80201010:	ce6080e7          	jalr	-794(ra) # 80200cf2 <mappages>
    80201014:	08054663          	bltz	a0,802010a0 <kvminit+0xca>
        panic("kvminit: uart map failed");

    // 映射 VirtIO 磁盘 MMIO
    if (mappages(kernel_pagetable, VIRTIO0, PGSIZE, VIRTIO0, PTE_R | PTE_W) < 0)
    80201018:	4719                	li	a4,6
    8020101a:	100016b7          	lui	a3,0x10001
    8020101e:	6605                	lui	a2,0x1
    80201020:	100015b7          	lui	a1,0x10001
    80201024:	0000f517          	auipc	a0,0xf
    80201028:	fdc53503          	ld	a0,-36(a0) # 80210000 <kernel_pagetable>
    8020102c:	00000097          	auipc	ra,0x0
    80201030:	cc6080e7          	jalr	-826(ra) # 80200cf2 <mappages>
    80201034:	06054f63          	bltz	a0,802010b2 <kvminit+0xdc>
        panic("kvminit: virtio map failed");

    // 映射内核代码段 (R-X)
    if (mappages(kernel_pagetable, 0x80200000, (uint64)etext - 0x80200000, 0x80200000, PTE_R | PTE_X) < 0)
    80201038:	00005497          	auipc	s1,0x5
    8020103c:	fc848493          	add	s1,s1,-56 # 80206000 <_etext>
    80201040:	4729                	li	a4,10
    80201042:	40100693          	li	a3,1025
    80201046:	06d6                	sll	a3,a3,0x15
    80201048:	bff00613          	li	a2,-1025
    8020104c:	0656                	sll	a2,a2,0x15
    8020104e:	9626                	add	a2,a2,s1
    80201050:	85b6                	mv	a1,a3
    80201052:	0000f517          	auipc	a0,0xf
    80201056:	fae53503          	ld	a0,-82(a0) # 80210000 <kernel_pagetable>
    8020105a:	00000097          	auipc	ra,0x0
    8020105e:	c98080e7          	jalr	-872(ra) # 80200cf2 <mappages>
    80201062:	06054163          	bltz	a0,802010c4 <kvminit+0xee>
        panic("kvminit: text map failed");

    // 映射内核数据段和剩余物理内存 (RW-)
    if (mappages(kernel_pagetable, (uint64)etext, 0x88000000 - (uint64)etext, (uint64)etext, PTE_R | PTE_W) < 0)
    80201066:	4719                	li	a4,6
    80201068:	86a6                	mv	a3,s1
    8020106a:	4645                	li	a2,17
    8020106c:	066e                	sll	a2,a2,0x1b
    8020106e:	8e05                	sub	a2,a2,s1
    80201070:	85a6                	mv	a1,s1
    80201072:	0000f517          	auipc	a0,0xf
    80201076:	f8e53503          	ld	a0,-114(a0) # 80210000 <kernel_pagetable>
    8020107a:	00000097          	auipc	ra,0x0
    8020107e:	c78080e7          	jalr	-904(ra) # 80200cf2 <mappages>
    80201082:	04054a63          	bltz	a0,802010d6 <kvminit+0x100>
        panic("kvminit: data map failed");
    
    printf("kvminit: kernel page table created.\n");
    80201086:	00005517          	auipc	a0,0x5
    8020108a:	33250513          	add	a0,a0,818 # 802063b8 <_etext+0x3b8>
    8020108e:	fffff097          	auipc	ra,0xfffff
    80201092:	0c6080e7          	jalr	198(ra) # 80200154 <printf>
}
    80201096:	60e2                	ld	ra,24(sp)
    80201098:	6442                	ld	s0,16(sp)
    8020109a:	64a2                	ld	s1,8(sp)
    8020109c:	6105                	add	sp,sp,32
    8020109e:	8082                	ret
        panic("kvminit: uart map failed");
    802010a0:	00005517          	auipc	a0,0x5
    802010a4:	29850513          	add	a0,a0,664 # 80206338 <_etext+0x338>
    802010a8:	fffff097          	auipc	ra,0xfffff
    802010ac:	32c080e7          	jalr	812(ra) # 802003d4 <panic>
    802010b0:	b7a5                	j	80201018 <kvminit+0x42>
        panic("kvminit: virtio map failed");
    802010b2:	00005517          	auipc	a0,0x5
    802010b6:	2a650513          	add	a0,a0,678 # 80206358 <_etext+0x358>
    802010ba:	fffff097          	auipc	ra,0xfffff
    802010be:	31a080e7          	jalr	794(ra) # 802003d4 <panic>
    802010c2:	bf9d                	j	80201038 <kvminit+0x62>
        panic("kvminit: text map failed");
    802010c4:	00005517          	auipc	a0,0x5
    802010c8:	2b450513          	add	a0,a0,692 # 80206378 <_etext+0x378>
    802010cc:	fffff097          	auipc	ra,0xfffff
    802010d0:	308080e7          	jalr	776(ra) # 802003d4 <panic>
    802010d4:	bf49                	j	80201066 <kvminit+0x90>
        panic("kvminit: data map failed");
    802010d6:	00005517          	auipc	a0,0x5
    802010da:	2c250513          	add	a0,a0,706 # 80206398 <_etext+0x398>
    802010de:	fffff097          	auipc	ra,0xfffff
    802010e2:	2f6080e7          	jalr	758(ra) # 802003d4 <panic>
    802010e6:	b745                	j	80201086 <kvminit+0xb0>

00000000802010e8 <kvminithart>:

void kvminithart(void) {
    802010e8:	1141                	add	sp,sp,-16
    802010ea:	e406                	sd	ra,8(sp)
    802010ec:	e022                	sd	s0,0(sp)
    802010ee:	0800                	add	s0,sp,16
    w_satp(MAKE_SATP(kernel_pagetable));
    802010f0:	0000f797          	auipc	a5,0xf
    802010f4:	f107b783          	ld	a5,-240(a5) # 80210000 <kernel_pagetable>
    802010f8:	83b1                	srl	a5,a5,0xc
    802010fa:	577d                	li	a4,-1
    802010fc:	177e                	sll	a4,a4,0x3f
    802010fe:	8fd9                	or	a5,a5,a4
static inline void w_satp(uint64 x) { asm volatile("csrw satp, %0" : : "r" (x)); }
    80201100:	18079073          	csrw	satp,a5
static inline void sfence_vma() { asm volatile("sfence.vma zero, zero"); }
    80201104:	12000073          	sfence.vma
    sfence_vma();
    printf("kvminithart: virtual memory enabled.\n");
    80201108:	00005517          	auipc	a0,0x5
    8020110c:	2d850513          	add	a0,a0,728 # 802063e0 <_etext+0x3e0>
    80201110:	fffff097          	auipc	ra,0xfffff
    80201114:	044080e7          	jalr	68(ra) # 80200154 <printf>
}
    80201118:	60a2                	ld	ra,8(sp)
    8020111a:	6402                	ld	s0,0(sp)
    8020111c:	0141                	add	sp,sp,16
    8020111e:	8082                	ret

0000000080201120 <freeproc>:
    if (mappages(pt, 0x10000000, PGSIZE, 0x10000000, PTE_R | PTE_W) < 0) return -1;
    if (mappages(pt, 0x10001000, PGSIZE, 0x10001000, PTE_R | PTE_W) < 0) return -1;
    return 0;
}

static void freeproc(struct proc *p) {
    80201120:	7179                	add	sp,sp,-48
    80201122:	f406                	sd	ra,40(sp)
    80201124:	f022                	sd	s0,32(sp)
    80201126:	ec26                	sd	s1,24(sp)
    80201128:	e84a                	sd	s2,16(sp)
    8020112a:	e44e                	sd	s3,8(sp)
    8020112c:	1800                	add	s0,sp,48
    8020112e:	892a                	mv	s2,a0
    if (p->trapframe) kfree((void*)p->trapframe);
    80201130:	6128                	ld	a0,64(a0)
    80201132:	c509                	beqz	a0,8020113c <freeproc+0x1c>
    80201134:	fffff097          	auipc	ra,0xfffff
    80201138:	30a080e7          	jalr	778(ra) # 8020043e <kfree>
    p->trapframe = 0;
    8020113c:	04093023          	sd	zero,64(s2)
    if (p->kstack) kfree((void*)p->kstack);
    80201140:	03893503          	ld	a0,56(s2)
    80201144:	e129                	bnez	a0,80201186 <freeproc+0x66>
    p->kstack = 0;
    80201146:	02093c23          	sd	zero,56(s2)
    if(p->pagetable) uvmunmap(p->pagetable, 0, 0x40000 / PGSIZE, 1);
    8020114a:	04893503          	ld	a0,72(s2)
    8020114e:	c909                	beqz	a0,80201160 <freeproc+0x40>
    80201150:	4685                	li	a3,1
    80201152:	04000613          	li	a2,64
    80201156:	4581                	li	a1,0
    80201158:	00000097          	auipc	ra,0x0
    8020115c:	e08080e7          	jalr	-504(ra) # 80200f60 <uvmunmap>
    p->pagetable = 0;
    80201160:	04093423          	sd	zero,72(s2)
    p->pid = 0;
    80201164:	00092e23          	sw	zero,28(s2)
    p->parent = 0;
    80201168:	02093023          	sd	zero,32(s2)
    p->name[0] = 0;
    8020116c:	0c090423          	sb	zero,200(s2)
    p->chan = 0;
    80201170:	02093423          	sd	zero,40(s2)
    p->killed = 0;
    80201174:	02092823          	sw	zero,48(s2)
    p->xstate = 0;
    80201178:	02092a23          	sw	zero,52(s2)
    for (int i = 0; i < NOFILE; i++) {
    8020117c:	0d890493          	add	s1,s2,216
    80201180:	15890993          	add	s3,s2,344
    80201184:	a809                	j	80201196 <freeproc+0x76>
    if (p->kstack) kfree((void*)p->kstack);
    80201186:	fffff097          	auipc	ra,0xfffff
    8020118a:	2b8080e7          	jalr	696(ra) # 8020043e <kfree>
    8020118e:	bf65                	j	80201146 <freeproc+0x26>
    for (int i = 0; i < NOFILE; i++) {
    80201190:	04a1                	add	s1,s1,8
    80201192:	01348b63          	beq	s1,s3,802011a8 <freeproc+0x88>
        if (p->ofile[i]) {
    80201196:	6088                	ld	a0,0(s1)
    80201198:	dd65                	beqz	a0,80201190 <freeproc+0x70>
            fileclose(p->ofile[i]);
    8020119a:	00003097          	auipc	ra,0x3
    8020119e:	89a080e7          	jalr	-1894(ra) # 80203a34 <fileclose>
            p->ofile[i] = 0;
    802011a2:	0004b023          	sd	zero,0(s1)
    802011a6:	b7ed                	j	80201190 <freeproc+0x70>
        }
    }
    if (p->cwd) {
    802011a8:	15893503          	ld	a0,344(s2)
    802011ac:	c519                	beqz	a0,802011ba <freeproc+0x9a>
        iput(p->cwd);
    802011ae:	00002097          	auipc	ra,0x2
    802011b2:	9a8080e7          	jalr	-1624(ra) # 80202b56 <iput>
        p->cwd = 0;
    802011b6:	14093c23          	sd	zero,344(s2)
    }
    p->state = UNUSED;
    802011ba:	00092c23          	sw	zero,24(s2)
}
    802011be:	70a2                	ld	ra,40(sp)
    802011c0:	7402                	ld	s0,32(sp)
    802011c2:	64e2                	ld	s1,24(sp)
    802011c4:	6942                	ld	s2,16(sp)
    802011c6:	69a2                	ld	s3,8(sp)
    802011c8:	6145                	add	sp,sp,48
    802011ca:	8082                	ret

00000000802011cc <allocproc>:
    release(&p->lock);
    if (p->entry) p->entry();
    exit(0);
}

static struct proc* allocproc(void) {
    802011cc:	7179                	add	sp,sp,-48
    802011ce:	f406                	sd	ra,40(sp)
    802011d0:	f022                	sd	s0,32(sp)
    802011d2:	ec26                	sd	s1,24(sp)
    802011d4:	e84a                	sd	s2,16(sp)
    802011d6:	e44e                	sd	s3,8(sp)
    802011d8:	1800                	add	s0,sp,48
    struct proc *p;
    for(p = proc; p < &proc[NPROC]; p++) {
    802011da:	00028497          	auipc	s1,0x28
    802011de:	ec648493          	add	s1,s1,-314 # 802290a0 <proc>
    802011e2:	0002d917          	auipc	s2,0x2d
    802011e6:	6be90913          	add	s2,s2,1726 # 8022e8a0 <bcache>
        acquire(&p->lock);
    802011ea:	8526                	mv	a0,s1
    802011ec:	fffff097          	auipc	ra,0xfffff
    802011f0:	64e080e7          	jalr	1614(ra) # 8020083a <acquire>
        if(p->state == UNUSED) {
    802011f4:	4c9c                	lw	a5,24(s1)
    802011f6:	cf81                	beqz	a5,8020120e <allocproc+0x42>
            goto found;
        } else {
            release(&p->lock);
    802011f8:	8526                	mv	a0,s1
    802011fa:	fffff097          	auipc	ra,0xfffff
    802011fe:	732080e7          	jalr	1842(ra) # 8020092c <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80201202:	16048493          	add	s1,s1,352
    80201206:	ff2492e3          	bne	s1,s2,802011ea <allocproc+0x1e>
        }
    }
    return 0;
    8020120a:	4481                	li	s1,0
    8020120c:	a8e5                	j	80201304 <allocproc+0x138>

found:
    p->pid = nextpid++;
    8020120e:	00006717          	auipc	a4,0x6
    80201212:	c7270713          	add	a4,a4,-910 # 80206e80 <nextpid>
    80201216:	431c                	lw	a5,0(a4)
    80201218:	0017869b          	addw	a3,a5,1
    8020121c:	c314                	sw	a3,0(a4)
    8020121e:	ccdc                	sw	a5,28(s1)
    p->state = USED;
    80201220:	4785                	li	a5,1
    80201222:	cc9c                	sw	a5,24(s1)

    if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80201224:	fffff097          	auipc	ra,0xfffff
    80201228:	410080e7          	jalr	1040(ra) # 80200634 <kalloc>
    8020122c:	892a                	mv	s2,a0
    8020122e:	e0a8                	sd	a0,64(s1)
    80201230:	c175                	beqz	a0,80201314 <allocproc+0x148>
        freeproc(p);
        release(&p->lock);
        return 0;
    }
    memset(p->trapframe, 0, PGSIZE);
    80201232:	6605                	lui	a2,0x1
    80201234:	4581                	li	a1,0
    80201236:	fffff097          	auipc	ra,0xfffff
    8020123a:	76c080e7          	jalr	1900(ra) # 802009a2 <memset>

    if((p->pagetable = create_pagetable()) == 0) {
    8020123e:	00000097          	auipc	ra,0x0
    80201242:	b46080e7          	jalr	-1210(ra) # 80200d84 <create_pagetable>
    80201246:	892a                	mv	s2,a0
    80201248:	e4a8                	sd	a0,72(s1)
    8020124a:	c16d                	beqz	a0,8020132c <allocproc+0x160>
    if (mappages(pt, 0x80200000, (uint64)etext - 0x80200000, 0x80200000, PTE_R | PTE_X) < 0) return -1;
    8020124c:	00005997          	auipc	s3,0x5
    80201250:	db498993          	add	s3,s3,-588 # 80206000 <_etext>
    80201254:	4729                	li	a4,10
    80201256:	40100693          	li	a3,1025
    8020125a:	06d6                	sll	a3,a3,0x15
    8020125c:	bff00613          	li	a2,-1025
    80201260:	0656                	sll	a2,a2,0x15
    80201262:	964e                	add	a2,a2,s3
    80201264:	85b6                	mv	a1,a3
    80201266:	00000097          	auipc	ra,0x0
    8020126a:	a8c080e7          	jalr	-1396(ra) # 80200cf2 <mappages>
    8020126e:	0c054b63          	bltz	a0,80201344 <allocproc+0x178>
    if (mappages(pt, (uint64)etext, 0x88000000 - (uint64)etext, (uint64)etext, PTE_R | PTE_W) < 0) return -1;
    80201272:	4719                	li	a4,6
    80201274:	86ce                	mv	a3,s3
    80201276:	4645                	li	a2,17
    80201278:	066e                	sll	a2,a2,0x1b
    8020127a:	41360633          	sub	a2,a2,s3
    8020127e:	85ce                	mv	a1,s3
    80201280:	854a                	mv	a0,s2
    80201282:	00000097          	auipc	ra,0x0
    80201286:	a70080e7          	jalr	-1424(ra) # 80200cf2 <mappages>
    8020128a:	0a054d63          	bltz	a0,80201344 <allocproc+0x178>
    if (mappages(pt, 0x10000000, PGSIZE, 0x10000000, PTE_R | PTE_W) < 0) return -1;
    8020128e:	4719                	li	a4,6
    80201290:	100006b7          	lui	a3,0x10000
    80201294:	6605                	lui	a2,0x1
    80201296:	100005b7          	lui	a1,0x10000
    8020129a:	854a                	mv	a0,s2
    8020129c:	00000097          	auipc	ra,0x0
    802012a0:	a56080e7          	jalr	-1450(ra) # 80200cf2 <mappages>
    802012a4:	0a054063          	bltz	a0,80201344 <allocproc+0x178>
    if (mappages(pt, 0x10001000, PGSIZE, 0x10001000, PTE_R | PTE_W) < 0) return -1;
    802012a8:	4719                	li	a4,6
    802012aa:	100016b7          	lui	a3,0x10001
    802012ae:	6605                	lui	a2,0x1
    802012b0:	100015b7          	lui	a1,0x10001
    802012b4:	854a                	mv	a0,s2
    802012b6:	00000097          	auipc	ra,0x0
    802012ba:	a3c080e7          	jalr	-1476(ra) # 80200cf2 <mappages>
        freeproc(p);
        release(&p->lock);
        return 0;
    }
    
    if (uvm_kmap(p->pagetable) < 0) {
    802012be:	08054363          	bltz	a0,80201344 <allocproc+0x178>
        freeproc(p);
        release(&p->lock);
        return 0;
    }

    if((p->kstack = (uint64)kalloc()) == 0){
    802012c2:	fffff097          	auipc	ra,0xfffff
    802012c6:	372080e7          	jalr	882(ra) # 80200634 <kalloc>
    802012ca:	892a                	mv	s2,a0
    802012cc:	fc88                	sd	a0,56(s1)
    802012ce:	cd59                	beqz	a0,8020136c <allocproc+0x1a0>
        freeproc(p);
        release(&p->lock);
        return 0;
    }
    memset((void*)p->kstack, 0, PGSIZE);
    802012d0:	6605                	lui	a2,0x1
    802012d2:	4581                	li	a1,0
    802012d4:	fffff097          	auipc	ra,0xfffff
    802012d8:	6ce080e7          	jalr	1742(ra) # 802009a2 <memset>

    p->context.sp = p->kstack + PGSIZE;
    802012dc:	7c9c                	ld	a5,56(s1)
    802012de:	6705                	lui	a4,0x1
    802012e0:	97ba                	add	a5,a5,a4
    802012e2:	ecbc                	sd	a5,88(s1)
    p->context.ra = (uint64)proc_entry;
    802012e4:	00000797          	auipc	a5,0x0
    802012e8:	6ac78793          	add	a5,a5,1708 # 80201990 <proc_entry>
    802012ec:	e8bc                	sd	a5,80(s1)
    
    for (int i = 0; i < NOFILE; i++) {
    802012ee:	0d848793          	add	a5,s1,216
    802012f2:	15848713          	add	a4,s1,344
        p->ofile[i] = 0;
    802012f6:	0007b023          	sd	zero,0(a5)
    for (int i = 0; i < NOFILE; i++) {
    802012fa:	07a1                	add	a5,a5,8
    802012fc:	fee79de3          	bne	a5,a4,802012f6 <allocproc+0x12a>
    }
    p->cwd = 0;
    80201300:	1404bc23          	sd	zero,344(s1)

    return p;
}
    80201304:	8526                	mv	a0,s1
    80201306:	70a2                	ld	ra,40(sp)
    80201308:	7402                	ld	s0,32(sp)
    8020130a:	64e2                	ld	s1,24(sp)
    8020130c:	6942                	ld	s2,16(sp)
    8020130e:	69a2                	ld	s3,8(sp)
    80201310:	6145                	add	sp,sp,48
    80201312:	8082                	ret
        freeproc(p);
    80201314:	8526                	mv	a0,s1
    80201316:	00000097          	auipc	ra,0x0
    8020131a:	e0a080e7          	jalr	-502(ra) # 80201120 <freeproc>
        release(&p->lock);
    8020131e:	8526                	mv	a0,s1
    80201320:	fffff097          	auipc	ra,0xfffff
    80201324:	60c080e7          	jalr	1548(ra) # 8020092c <release>
        return 0;
    80201328:	84ca                	mv	s1,s2
    8020132a:	bfe9                	j	80201304 <allocproc+0x138>
        freeproc(p);
    8020132c:	8526                	mv	a0,s1
    8020132e:	00000097          	auipc	ra,0x0
    80201332:	df2080e7          	jalr	-526(ra) # 80201120 <freeproc>
        release(&p->lock);
    80201336:	8526                	mv	a0,s1
    80201338:	fffff097          	auipc	ra,0xfffff
    8020133c:	5f4080e7          	jalr	1524(ra) # 8020092c <release>
        return 0;
    80201340:	84ca                	mv	s1,s2
    80201342:	b7c9                	j	80201304 <allocproc+0x138>
        printf("allocproc: uvm_kmap failed\n"); // Add print
    80201344:	00005517          	auipc	a0,0x5
    80201348:	0c450513          	add	a0,a0,196 # 80206408 <_etext+0x408>
    8020134c:	fffff097          	auipc	ra,0xfffff
    80201350:	e08080e7          	jalr	-504(ra) # 80200154 <printf>
        freeproc(p);
    80201354:	8526                	mv	a0,s1
    80201356:	00000097          	auipc	ra,0x0
    8020135a:	dca080e7          	jalr	-566(ra) # 80201120 <freeproc>
        release(&p->lock);
    8020135e:	8526                	mv	a0,s1
    80201360:	fffff097          	auipc	ra,0xfffff
    80201364:	5cc080e7          	jalr	1484(ra) # 8020092c <release>
        return 0;
    80201368:	4481                	li	s1,0
    8020136a:	bf69                	j	80201304 <allocproc+0x138>
        freeproc(p);
    8020136c:	8526                	mv	a0,s1
    8020136e:	00000097          	auipc	ra,0x0
    80201372:	db2080e7          	jalr	-590(ra) # 80201120 <freeproc>
        release(&p->lock);
    80201376:	8526                	mv	a0,s1
    80201378:	fffff097          	auipc	ra,0xfffff
    8020137c:	5b4080e7          	jalr	1460(ra) # 8020092c <release>
        return 0;
    80201380:	84ca                	mv	s1,s2
    80201382:	b749                	j	80201304 <allocproc+0x138>

0000000080201384 <mycpu>:
struct cpu* mycpu(void) { return &cpus[0]; }
    80201384:	1141                	add	sp,sp,-16
    80201386:	e422                	sd	s0,8(sp)
    80201388:	0800                	add	s0,sp,16
    8020138a:	00028517          	auipc	a0,0x28
    8020138e:	c9650513          	add	a0,a0,-874 # 80229020 <cpus>
    80201392:	6422                	ld	s0,8(sp)
    80201394:	0141                	add	sp,sp,16
    80201396:	8082                	ret

0000000080201398 <myproc>:
struct proc* myproc(void) { 
    80201398:	1101                	add	sp,sp,-32
    8020139a:	ec06                	sd	ra,24(sp)
    8020139c:	e822                	sd	s0,16(sp)
    8020139e:	e426                	sd	s1,8(sp)
    802013a0:	1000                	add	s0,sp,32
    push_off(); 
    802013a2:	fffff097          	auipc	ra,0xfffff
    802013a6:	44c080e7          	jalr	1100(ra) # 802007ee <push_off>
    struct proc *p = cpus[0].proc; 
    802013aa:	00028497          	auipc	s1,0x28
    802013ae:	c764b483          	ld	s1,-906(s1) # 80229020 <cpus>
    pop_off(); 
    802013b2:	fffff097          	auipc	ra,0xfffff
    802013b6:	4fc080e7          	jalr	1276(ra) # 802008ae <pop_off>
}
    802013ba:	8526                	mv	a0,s1
    802013bc:	60e2                	ld	ra,24(sp)
    802013be:	6442                	ld	s0,16(sp)
    802013c0:	64a2                	ld	s1,8(sp)
    802013c2:	6105                	add	sp,sp,32
    802013c4:	8082                	ret

00000000802013c6 <procinit>:

void procinit(void) {
    802013c6:	7179                	add	sp,sp,-48
    802013c8:	f406                	sd	ra,40(sp)
    802013ca:	f022                	sd	s0,32(sp)
    802013cc:	ec26                	sd	s1,24(sp)
    802013ce:	e84a                	sd	s2,16(sp)
    802013d0:	e44e                	sd	s3,8(sp)
    802013d2:	1800                	add	s0,sp,48
    for (int i = 0; i < NPROC; i++) {
    802013d4:	00028497          	auipc	s1,0x28
    802013d8:	ccc48493          	add	s1,s1,-820 # 802290a0 <proc>
    802013dc:	0002d997          	auipc	s3,0x2d
    802013e0:	4c498993          	add	s3,s3,1220 # 8022e8a0 <bcache>
        spinlock_init(&proc[i].lock, "proc");
    802013e4:	00005917          	auipc	s2,0x5
    802013e8:	04490913          	add	s2,s2,68 # 80206428 <_etext+0x428>
    802013ec:	85ca                	mv	a1,s2
    802013ee:	8526                	mv	a0,s1
    802013f0:	fffff097          	auipc	ra,0xfffff
    802013f4:	3e8080e7          	jalr	1000(ra) # 802007d8 <spinlock_init>
        proc[i].state = UNUSED;
    802013f8:	0004ac23          	sw	zero,24(s1)
    for (int i = 0; i < NPROC; i++) {
    802013fc:	16048493          	add	s1,s1,352
    80201400:	ff3496e3          	bne	s1,s3,802013ec <procinit+0x26>
    }
    printf("procinit: complete\n");
    80201404:	00005517          	auipc	a0,0x5
    80201408:	02c50513          	add	a0,a0,44 # 80206430 <_etext+0x430>
    8020140c:	fffff097          	auipc	ra,0xfffff
    80201410:	d48080e7          	jalr	-696(ra) # 80200154 <printf>
}
    80201414:	70a2                	ld	ra,40(sp)
    80201416:	7402                	ld	s0,32(sp)
    80201418:	64e2                	ld	s1,24(sp)
    8020141a:	6942                	ld	s2,16(sp)
    8020141c:	69a2                	ld	s3,8(sp)
    8020141e:	6145                	add	sp,sp,48
    80201420:	8082                	ret

0000000080201422 <create_process>:

int create_process(void (*entry)(void)) {
    80201422:	1101                	add	sp,sp,-32
    80201424:	ec06                	sd	ra,24(sp)
    80201426:	e822                	sd	s0,16(sp)
    80201428:	e426                	sd	s1,8(sp)
    8020142a:	e04a                	sd	s2,0(sp)
    8020142c:	1000                	add	s0,sp,32
    8020142e:	892a                	mv	s2,a0
    struct proc *p = allocproc();
    80201430:	00000097          	auipc	ra,0x0
    80201434:	d9c080e7          	jalr	-612(ra) # 802011cc <allocproc>
    if (p == 0) return -1;
    80201438:	cd3d                	beqz	a0,802014b6 <create_process+0x94>
    8020143a:	84aa                	mv	s1,a0
    
    char *mem = kalloc();
    8020143c:	fffff097          	auipc	ra,0xfffff
    80201440:	1f8080e7          	jalr	504(ra) # 80200634 <kalloc>
    80201444:	862a                	mv	a2,a0
    if(!mem) { 
    80201446:	c139                	beqz	a0,8020148c <create_process+0x6a>
        freeproc(p); 
        release(&p->lock); 
        return -1; 
    }
    map_page(p->pagetable, 0, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U); 
    80201448:	46f9                	li	a3,30
    8020144a:	4581                	li	a1,0
    8020144c:	64a8                	ld	a0,72(s1)
    8020144e:	00000097          	auipc	ra,0x0
    80201452:	97e080e7          	jalr	-1666(ra) # 80200dcc <map_page>
    
    p->entry = entry;
    80201456:	0d24b023          	sd	s2,192(s1)
    p->parent = 0; 
    8020145a:	0204b023          	sd	zero,32(s1)
    p->trapframe->epc = 0; 
    8020145e:	60bc                	ld	a5,64(s1)
    80201460:	0007bc23          	sd	zero,24(a5)
    p->trapframe->sp = PGSIZE; 
    80201464:	60bc                	ld	a5,64(s1)
    80201466:	6705                	lui	a4,0x1
    80201468:	fb98                	sd	a4,48(a5)
    
    if (p->cwd == 0) p->cwd = iget(ROOTDEV, ROOTINO);
    8020146a:	1584b783          	ld	a5,344(s1)
    8020146e:	cb9d                	beqz	a5,802014a4 <create_process+0x82>
    
    p->state = RUNNABLE;
    80201470:	478d                	li	a5,3
    80201472:	cc9c                	sw	a5,24(s1)
    release(&p->lock);
    80201474:	8526                	mv	a0,s1
    80201476:	fffff097          	auipc	ra,0xfffff
    8020147a:	4b6080e7          	jalr	1206(ra) # 8020092c <release>
    return p->pid;
    8020147e:	4cc8                	lw	a0,28(s1)
}
    80201480:	60e2                	ld	ra,24(sp)
    80201482:	6442                	ld	s0,16(sp)
    80201484:	64a2                	ld	s1,8(sp)
    80201486:	6902                	ld	s2,0(sp)
    80201488:	6105                	add	sp,sp,32
    8020148a:	8082                	ret
        freeproc(p); 
    8020148c:	8526                	mv	a0,s1
    8020148e:	00000097          	auipc	ra,0x0
    80201492:	c92080e7          	jalr	-878(ra) # 80201120 <freeproc>
        release(&p->lock); 
    80201496:	8526                	mv	a0,s1
    80201498:	fffff097          	auipc	ra,0xfffff
    8020149c:	494080e7          	jalr	1172(ra) # 8020092c <release>
        return -1; 
    802014a0:	557d                	li	a0,-1
    802014a2:	bff9                	j	80201480 <create_process+0x5e>
    if (p->cwd == 0) p->cwd = iget(ROOTDEV, ROOTINO);
    802014a4:	4585                	li	a1,1
    802014a6:	4505                	li	a0,1
    802014a8:	00001097          	auipc	ra,0x1
    802014ac:	2ac080e7          	jalr	684(ra) # 80202754 <iget>
    802014b0:	14a4bc23          	sd	a0,344(s1)
    802014b4:	bf75                	j	80201470 <create_process+0x4e>
    if (p == 0) return -1;
    802014b6:	557d                	li	a0,-1
    802014b8:	b7e1                	j	80201480 <create_process+0x5e>

00000000802014ba <fork>:

int fork(void) {
    802014ba:	7139                	add	sp,sp,-64
    802014bc:	fc06                	sd	ra,56(sp)
    802014be:	f822                	sd	s0,48(sp)
    802014c0:	f426                	sd	s1,40(sp)
    802014c2:	f04a                	sd	s2,32(sp)
    802014c4:	ec4e                	sd	s3,24(sp)
    802014c6:	e852                	sd	s4,16(sp)
    802014c8:	e456                	sd	s5,8(sp)
    802014ca:	0080                	add	s0,sp,64
    int i, pid;
    struct proc *np;
    struct proc *p = myproc();
    802014cc:	00000097          	auipc	ra,0x0
    802014d0:	ecc080e7          	jalr	-308(ra) # 80201398 <myproc>
    802014d4:	8aaa                	mv	s5,a0

    if ((np = allocproc()) == 0) return -1;
    802014d6:	00000097          	auipc	ra,0x0
    802014da:	cf6080e7          	jalr	-778(ra) # 802011cc <allocproc>
    802014de:	c575                	beqz	a0,802015ca <fork+0x110>
    802014e0:	8a2a                	mv	s4,a0

    if(uvmcopy(p->pagetable, np->pagetable, 0x40000) < 0) {
    802014e2:	00040637          	lui	a2,0x40
    802014e6:	652c                	ld	a1,72(a0)
    802014e8:	048ab503          	ld	a0,72(s5) # 1048 <_start-0x801fefb8>
    802014ec:	00000097          	auipc	ra,0x0
    802014f0:	9aa080e7          	jalr	-1622(ra) # 80200e96 <uvmcopy>
    802014f4:	04054a63          	bltz	a0,80201548 <fork+0x8e>
        freeproc(np);
        release(&np->lock);
        return -1;
    }

    *(np->trapframe) = *(p->trapframe);
    802014f8:	040ab683          	ld	a3,64(s5)
    802014fc:	87b6                	mv	a5,a3
    802014fe:	040a3703          	ld	a4,64(s4) # 1040 <_start-0x801fefc0>
    80201502:	12068693          	add	a3,a3,288 # 10001120 <_start-0x701feee0>
    80201506:	0007b803          	ld	a6,0(a5)
    8020150a:	6788                	ld	a0,8(a5)
    8020150c:	6b8c                	ld	a1,16(a5)
    8020150e:	6f90                	ld	a2,24(a5)
    80201510:	01073023          	sd	a6,0(a4) # 1000 <_start-0x801ff000>
    80201514:	e708                	sd	a0,8(a4)
    80201516:	eb0c                	sd	a1,16(a4)
    80201518:	ef10                	sd	a2,24(a4)
    8020151a:	02078793          	add	a5,a5,32
    8020151e:	02070713          	add	a4,a4,32
    80201522:	fed792e3          	bne	a5,a3,80201506 <fork+0x4c>
    np->trapframe->a0 = 0; 
    80201526:	040a3783          	ld	a5,64(s4)
    8020152a:	0607b823          	sd	zero,112(a5)
    np->context.ra = (uint64)fork_ret;
    8020152e:	00000797          	auipc	a5,0x0
    80201532:	4f678793          	add	a5,a5,1270 # 80201a24 <fork_ret>
    80201536:	04fa3823          	sd	a5,80(s4)

    for (i = 0; i < NOFILE; i++)
    8020153a:	0d8a8493          	add	s1,s5,216
    8020153e:	0d8a0913          	add	s2,s4,216
    80201542:	158a8993          	add	s3,s5,344
    80201546:	a00d                	j	80201568 <fork+0xae>
        freeproc(np);
    80201548:	8552                	mv	a0,s4
    8020154a:	00000097          	auipc	ra,0x0
    8020154e:	bd6080e7          	jalr	-1066(ra) # 80201120 <freeproc>
        release(&np->lock);
    80201552:	8552                	mv	a0,s4
    80201554:	fffff097          	auipc	ra,0xfffff
    80201558:	3d8080e7          	jalr	984(ra) # 8020092c <release>
        return -1;
    8020155c:	54fd                	li	s1,-1
    8020155e:	a8a1                	j	802015b6 <fork+0xfc>
    for (i = 0; i < NOFILE; i++)
    80201560:	04a1                	add	s1,s1,8
    80201562:	0921                	add	s2,s2,8
    80201564:	01348b63          	beq	s1,s3,8020157a <fork+0xc0>
        if (p->ofile[i]) np->ofile[i] = filedup(p->ofile[i]);
    80201568:	6088                	ld	a0,0(s1)
    8020156a:	d97d                	beqz	a0,80201560 <fork+0xa6>
    8020156c:	00002097          	auipc	ra,0x2
    80201570:	472080e7          	jalr	1138(ra) # 802039de <filedup>
    80201574:	00a93023          	sd	a0,0(s2)
    80201578:	b7e5                	j	80201560 <fork+0xa6>
    
    if (p->cwd) np->cwd = idup(p->cwd);
    8020157a:	158ab503          	ld	a0,344(s5)
    8020157e:	c519                	beqz	a0,8020158c <fork+0xd2>
    80201580:	00001097          	auipc	ra,0x1
    80201584:	358080e7          	jalr	856(ra) # 802028d8 <idup>
    80201588:	14aa3c23          	sd	a0,344(s4)
    safestrcpy(np->name, p->name, sizeof(p->name));
    8020158c:	4641                	li	a2,16
    8020158e:	0c8a8593          	add	a1,s5,200
    80201592:	0c8a0513          	add	a0,s4,200
    80201596:	fffff097          	auipc	ra,0xfffff
    8020159a:	556080e7          	jalr	1366(ra) # 80200aec <safestrcpy>
    
    pid = np->pid;
    8020159e:	01ca2483          	lw	s1,28(s4)
    np->parent = p;
    802015a2:	035a3023          	sd	s5,32(s4)
    
    np->state = RUNNABLE;
    802015a6:	478d                	li	a5,3
    802015a8:	00fa2c23          	sw	a5,24(s4)
    release(&np->lock);
    802015ac:	8552                	mv	a0,s4
    802015ae:	fffff097          	auipc	ra,0xfffff
    802015b2:	37e080e7          	jalr	894(ra) # 8020092c <release>
    return pid;
}
    802015b6:	8526                	mv	a0,s1
    802015b8:	70e2                	ld	ra,56(sp)
    802015ba:	7442                	ld	s0,48(sp)
    802015bc:	74a2                	ld	s1,40(sp)
    802015be:	7902                	ld	s2,32(sp)
    802015c0:	69e2                	ld	s3,24(sp)
    802015c2:	6a42                	ld	s4,16(sp)
    802015c4:	6aa2                	ld	s5,8(sp)
    802015c6:	6121                	add	sp,sp,64
    802015c8:	8082                	ret
    if ((np = allocproc()) == 0) return -1;
    802015ca:	54fd                	li	s1,-1
    802015cc:	b7ed                	j	802015b6 <fork+0xfc>

00000000802015ce <scheduler>:

void scheduler(void) {
    802015ce:	715d                	add	sp,sp,-80
    802015d0:	e486                	sd	ra,72(sp)
    802015d2:	e0a2                	sd	s0,64(sp)
    802015d4:	fc26                	sd	s1,56(sp)
    802015d6:	f84a                	sd	s2,48(sp)
    802015d8:	f44e                	sd	s3,40(sp)
    802015da:	f052                	sd	s4,32(sp)
    802015dc:	ec56                	sd	s5,24(sp)
    802015de:	e85a                	sd	s6,16(sp)
    802015e0:	e45e                	sd	s7,8(sp)
    802015e2:	e062                	sd	s8,0(sp)
    802015e4:	0880                	add	s0,sp,80
    struct cpu *c = mycpu();
    c->proc = 0;
    802015e6:	00028797          	auipc	a5,0x28
    802015ea:	a207bd23          	sd	zero,-1478(a5) # 80229020 <cpus>
    
    w_satp(MAKE_SATP(kernel_pagetable)); 
    802015ee:	0000f797          	auipc	a5,0xf
    802015f2:	a127b783          	ld	a5,-1518(a5) # 80210000 <kernel_pagetable>
    802015f6:	83b1                	srl	a5,a5,0xc
    802015f8:	577d                	li	a4,-1
    802015fa:	177e                	sll	a4,a4,0x3f
    802015fc:	8fd9                	or	a5,a5,a4
static inline void w_satp(uint64 x) { asm volatile("csrw satp, %0" : : "r" (x)); }
    802015fe:	18079073          	csrw	satp,a5

    printf("scheduler: starting on cpu 0\n");
    80201602:	00005517          	auipc	a0,0x5
    80201606:	e4650513          	add	a0,a0,-442 # 80206448 <_etext+0x448>
    8020160a:	fffff097          	auipc	ra,0xfffff
    8020160e:	b4a080e7          	jalr	-1206(ra) # 80200154 <printf>
        intr_on();
        for (struct proc *p = proc; p < &proc[NPROC]; p++) {
            acquire(&p->lock);
            if (p->state == RUNNABLE) {
                p->state = RUNNING;
                c->proc = p; 
    80201612:	00028a97          	auipc	s5,0x28
    80201616:	a0ea8a93          	add	s5,s5,-1522 # 80229020 <cpus>
                
                w_satp(MAKE_SATP(p->pagetable)); 
    8020161a:	5a7d                	li	s4,-1
    8020161c:	1a7e                	sll	s4,s4,0x3f
                sfence_vma();
                
                swtch(&c->context, &p->context);
    8020161e:	00028c17          	auipc	s8,0x28
    80201622:	a0ac0c13          	add	s8,s8,-1526 # 80229028 <cpus+0x8>
                
                w_satp(MAKE_SATP(kernel_pagetable)); 
    80201626:	0000fb97          	auipc	s7,0xf
    8020162a:	9dab8b93          	add	s7,s7,-1574 # 80210000 <kernel_pagetable>
static inline uint64 r_sstatus() { uint64 x; asm volatile("csrr %0, sstatus" : "=r" (x)); return x; }
    8020162e:	100027f3          	csrr	a5,sstatus
    80201632:	0027e793          	or	a5,a5,2
static inline void w_sstatus(uint64 x) { asm volatile("csrw sstatus, %0" : : "r" (x)); }
    80201636:	10079073          	csrw	sstatus,a5
        for (struct proc *p = proc; p < &proc[NPROC]; p++) {
    8020163a:	00028497          	auipc	s1,0x28
    8020163e:	a6648493          	add	s1,s1,-1434 # 802290a0 <proc>
            if (p->state == RUNNABLE) {
    80201642:	498d                	li	s3,3
                p->state = RUNNING;
    80201644:	4b11                	li	s6,4
        for (struct proc *p = proc; p < &proc[NPROC]; p++) {
    80201646:	0002d917          	auipc	s2,0x2d
    8020164a:	25a90913          	add	s2,s2,602 # 8022e8a0 <bcache>
    8020164e:	a811                	j	80201662 <scheduler+0x94>
                sfence_vma();
                c->proc = 0; 
            }
            release(&p->lock);
    80201650:	8526                	mv	a0,s1
    80201652:	fffff097          	auipc	ra,0xfffff
    80201656:	2da080e7          	jalr	730(ra) # 8020092c <release>
        for (struct proc *p = proc; p < &proc[NPROC]; p++) {
    8020165a:	16048493          	add	s1,s1,352
    8020165e:	fd2488e3          	beq	s1,s2,8020162e <scheduler+0x60>
            acquire(&p->lock);
    80201662:	8526                	mv	a0,s1
    80201664:	fffff097          	auipc	ra,0xfffff
    80201668:	1d6080e7          	jalr	470(ra) # 8020083a <acquire>
            if (p->state == RUNNABLE) {
    8020166c:	4c9c                	lw	a5,24(s1)
    8020166e:	ff3791e3          	bne	a5,s3,80201650 <scheduler+0x82>
                p->state = RUNNING;
    80201672:	0164ac23          	sw	s6,24(s1)
                c->proc = p; 
    80201676:	009ab023          	sd	s1,0(s5)
                w_satp(MAKE_SATP(p->pagetable)); 
    8020167a:	64bc                	ld	a5,72(s1)
    8020167c:	83b1                	srl	a5,a5,0xc
    8020167e:	0147e7b3          	or	a5,a5,s4
static inline void w_satp(uint64 x) { asm volatile("csrw satp, %0" : : "r" (x)); }
    80201682:	18079073          	csrw	satp,a5
static inline void sfence_vma() { asm volatile("sfence.vma zero, zero"); }
    80201686:	12000073          	sfence.vma
                swtch(&c->context, &p->context);
    8020168a:	05048593          	add	a1,s1,80
    8020168e:	8562                	mv	a0,s8
    80201690:	00003097          	auipc	ra,0x3
    80201694:	2ce080e7          	jalr	718(ra) # 8020495e <swtch>
                w_satp(MAKE_SATP(kernel_pagetable)); 
    80201698:	000bb783          	ld	a5,0(s7)
    8020169c:	83b1                	srl	a5,a5,0xc
    8020169e:	0147e7b3          	or	a5,a5,s4
static inline void w_satp(uint64 x) { asm volatile("csrw satp, %0" : : "r" (x)); }
    802016a2:	18079073          	csrw	satp,a5
static inline void sfence_vma() { asm volatile("sfence.vma zero, zero"); }
    802016a6:	12000073          	sfence.vma
                c->proc = 0; 
    802016aa:	000ab023          	sd	zero,0(s5)
    802016ae:	b74d                	j	80201650 <scheduler+0x82>

00000000802016b0 <sched>:
        }
    }
}

void sched(void) {
    802016b0:	1101                	add	sp,sp,-32
    802016b2:	ec06                	sd	ra,24(sp)
    802016b4:	e822                	sd	s0,16(sp)
    802016b6:	e426                	sd	s1,8(sp)
    802016b8:	e04a                	sd	s2,0(sp)
    802016ba:	1000                	add	s0,sp,32
    int intena = mycpu()->intena;
    802016bc:	00028497          	auipc	s1,0x28
    802016c0:	96448493          	add	s1,s1,-1692 # 80229020 <cpus>
    802016c4:	07c4a903          	lw	s2,124(s1)
    swtch(&myproc()->context, &mycpu()->context);
    802016c8:	00000097          	auipc	ra,0x0
    802016cc:	cd0080e7          	jalr	-816(ra) # 80201398 <myproc>
    802016d0:	00028597          	auipc	a1,0x28
    802016d4:	95858593          	add	a1,a1,-1704 # 80229028 <cpus+0x8>
    802016d8:	05050513          	add	a0,a0,80
    802016dc:	00003097          	auipc	ra,0x3
    802016e0:	282080e7          	jalr	642(ra) # 8020495e <swtch>
    mycpu()->intena = intena;
    802016e4:	0724ae23          	sw	s2,124(s1)
}
    802016e8:	60e2                	ld	ra,24(sp)
    802016ea:	6442                	ld	s0,16(sp)
    802016ec:	64a2                	ld	s1,8(sp)
    802016ee:	6902                	ld	s2,0(sp)
    802016f0:	6105                	add	sp,sp,32
    802016f2:	8082                	ret

00000000802016f4 <yield>:

void yield(void) {
    802016f4:	1101                	add	sp,sp,-32
    802016f6:	ec06                	sd	ra,24(sp)
    802016f8:	e822                	sd	s0,16(sp)
    802016fa:	e426                	sd	s1,8(sp)
    802016fc:	1000                	add	s0,sp,32
    struct proc *p = myproc();
    802016fe:	00000097          	auipc	ra,0x0
    80201702:	c9a080e7          	jalr	-870(ra) # 80201398 <myproc>
    80201706:	84aa                	mv	s1,a0
    acquire(&p->lock);
    80201708:	fffff097          	auipc	ra,0xfffff
    8020170c:	132080e7          	jalr	306(ra) # 8020083a <acquire>
    p->state = RUNNABLE;
    80201710:	478d                	li	a5,3
    80201712:	cc9c                	sw	a5,24(s1)
    sched();
    80201714:	00000097          	auipc	ra,0x0
    80201718:	f9c080e7          	jalr	-100(ra) # 802016b0 <sched>
    release(&p->lock);
    8020171c:	8526                	mv	a0,s1
    8020171e:	fffff097          	auipc	ra,0xfffff
    80201722:	20e080e7          	jalr	526(ra) # 8020092c <release>
}
    80201726:	60e2                	ld	ra,24(sp)
    80201728:	6442                	ld	s0,16(sp)
    8020172a:	64a2                	ld	s1,8(sp)
    8020172c:	6105                	add	sp,sp,32
    8020172e:	8082                	ret

0000000080201730 <sleep>:
    }
}

void wait_process(int *status) { wait(status); }

void sleep(void *chan, struct spinlock *lk) {
    80201730:	7179                	add	sp,sp,-48
    80201732:	f406                	sd	ra,40(sp)
    80201734:	f022                	sd	s0,32(sp)
    80201736:	ec26                	sd	s1,24(sp)
    80201738:	e84a                	sd	s2,16(sp)
    8020173a:	e44e                	sd	s3,8(sp)
    8020173c:	1800                	add	s0,sp,48
    8020173e:	89aa                	mv	s3,a0
    80201740:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80201742:	00000097          	auipc	ra,0x0
    80201746:	c56080e7          	jalr	-938(ra) # 80201398 <myproc>
    8020174a:	84aa                	mv	s1,a0
    if (lk != &p->lock) { acquire(&p->lock); release(lk); }
    8020174c:	05250663          	beq	a0,s2,80201798 <sleep+0x68>
    80201750:	fffff097          	auipc	ra,0xfffff
    80201754:	0ea080e7          	jalr	234(ra) # 8020083a <acquire>
    80201758:	854a                	mv	a0,s2
    8020175a:	fffff097          	auipc	ra,0xfffff
    8020175e:	1d2080e7          	jalr	466(ra) # 8020092c <release>
    p->chan = chan;
    80201762:	0334b423          	sd	s3,40(s1)
    p->state = SLEEPING;
    80201766:	4789                	li	a5,2
    80201768:	cc9c                	sw	a5,24(s1)
    sched();
    8020176a:	00000097          	auipc	ra,0x0
    8020176e:	f46080e7          	jalr	-186(ra) # 802016b0 <sched>
    p->chan = 0;
    80201772:	0204b423          	sd	zero,40(s1)
    if (lk != &p->lock) { release(&p->lock); acquire(lk); }
    80201776:	8526                	mv	a0,s1
    80201778:	fffff097          	auipc	ra,0xfffff
    8020177c:	1b4080e7          	jalr	436(ra) # 8020092c <release>
    80201780:	854a                	mv	a0,s2
    80201782:	fffff097          	auipc	ra,0xfffff
    80201786:	0b8080e7          	jalr	184(ra) # 8020083a <acquire>
}
    8020178a:	70a2                	ld	ra,40(sp)
    8020178c:	7402                	ld	s0,32(sp)
    8020178e:	64e2                	ld	s1,24(sp)
    80201790:	6942                	ld	s2,16(sp)
    80201792:	69a2                	ld	s3,8(sp)
    80201794:	6145                	add	sp,sp,48
    80201796:	8082                	ret
    p->chan = chan;
    80201798:	03353423          	sd	s3,40(a0)
    p->state = SLEEPING;
    8020179c:	4789                	li	a5,2
    8020179e:	cd1c                	sw	a5,24(a0)
    sched();
    802017a0:	00000097          	auipc	ra,0x0
    802017a4:	f10080e7          	jalr	-240(ra) # 802016b0 <sched>
    p->chan = 0;
    802017a8:	0204b423          	sd	zero,40(s1)
    if (lk != &p->lock) { release(&p->lock); acquire(lk); }
    802017ac:	bff9                	j	8020178a <sleep+0x5a>

00000000802017ae <wait>:
int wait(int *status) {
    802017ae:	715d                	add	sp,sp,-80
    802017b0:	e486                	sd	ra,72(sp)
    802017b2:	e0a2                	sd	s0,64(sp)
    802017b4:	fc26                	sd	s1,56(sp)
    802017b6:	f84a                	sd	s2,48(sp)
    802017b8:	f44e                	sd	s3,40(sp)
    802017ba:	f052                	sd	s4,32(sp)
    802017bc:	ec56                	sd	s5,24(sp)
    802017be:	e85a                	sd	s6,16(sp)
    802017c0:	e45e                	sd	s7,8(sp)
    802017c2:	0880                	add	s0,sp,80
    802017c4:	8b2a                	mv	s6,a0
    struct proc *p = myproc();
    802017c6:	00000097          	auipc	ra,0x0
    802017ca:	bd2080e7          	jalr	-1070(ra) # 80201398 <myproc>
    802017ce:	892a                	mv	s2,a0
    acquire(&p->lock);
    802017d0:	fffff097          	auipc	ra,0xfffff
    802017d4:	06a080e7          	jalr	106(ra) # 8020083a <acquire>
        havekids = 0;
    802017d8:	4b81                	li	s7,0
                if (cp->state == ZOMBIE) {
    802017da:	4a15                	li	s4,5
                havekids = 1;
    802017dc:	4a85                	li	s5,1
        for (struct proc *cp = proc; cp < &proc[NPROC]; cp++) {
    802017de:	0002d997          	auipc	s3,0x2d
    802017e2:	0c298993          	add	s3,s3,194 # 8022e8a0 <bcache>
    802017e6:	a059                	j	8020186c <wait+0xbe>
                    pid = cp->pid;
    802017e8:	01c4a983          	lw	s3,28(s1)
                    if (status) *status = cp->xstate;
    802017ec:	000b0563          	beqz	s6,802017f6 <wait+0x48>
    802017f0:	58dc                	lw	a5,52(s1)
    802017f2:	00fb2023          	sw	a5,0(s6) # 1000 <_start-0x801ff000>
                    freeproc(cp);
    802017f6:	8526                	mv	a0,s1
    802017f8:	00000097          	auipc	ra,0x0
    802017fc:	928080e7          	jalr	-1752(ra) # 80201120 <freeproc>
                    release(&cp->lock);
    80201800:	8526                	mv	a0,s1
    80201802:	fffff097          	auipc	ra,0xfffff
    80201806:	12a080e7          	jalr	298(ra) # 8020092c <release>
                    release(&p->lock);
    8020180a:	854a                	mv	a0,s2
    8020180c:	fffff097          	auipc	ra,0xfffff
    80201810:	120080e7          	jalr	288(ra) # 8020092c <release>
}
    80201814:	854e                	mv	a0,s3
    80201816:	60a6                	ld	ra,72(sp)
    80201818:	6406                	ld	s0,64(sp)
    8020181a:	74e2                	ld	s1,56(sp)
    8020181c:	7942                	ld	s2,48(sp)
    8020181e:	79a2                	ld	s3,40(sp)
    80201820:	7a02                	ld	s4,32(sp)
    80201822:	6ae2                	ld	s5,24(sp)
    80201824:	6b42                	ld	s6,16(sp)
    80201826:	6ba2                	ld	s7,8(sp)
    80201828:	6161                	add	sp,sp,80
    8020182a:	8082                	ret
        for (struct proc *cp = proc; cp < &proc[NPROC]; cp++) {
    8020182c:	16048493          	add	s1,s1,352
    80201830:	03348463          	beq	s1,s3,80201858 <wait+0xaa>
            if (cp->parent == p) {
    80201834:	709c                	ld	a5,32(s1)
    80201836:	ff279be3          	bne	a5,s2,8020182c <wait+0x7e>
                acquire(&cp->lock);
    8020183a:	8526                	mv	a0,s1
    8020183c:	fffff097          	auipc	ra,0xfffff
    80201840:	ffe080e7          	jalr	-2(ra) # 8020083a <acquire>
                if (cp->state == ZOMBIE) {
    80201844:	4c9c                	lw	a5,24(s1)
    80201846:	fb4781e3          	beq	a5,s4,802017e8 <wait+0x3a>
                release(&cp->lock);
    8020184a:	8526                	mv	a0,s1
    8020184c:	fffff097          	auipc	ra,0xfffff
    80201850:	0e0080e7          	jalr	224(ra) # 8020092c <release>
                havekids = 1;
    80201854:	8756                	mv	a4,s5
    80201856:	bfd9                	j	8020182c <wait+0x7e>
        if (!havekids || p->killed) {
    80201858:	c305                	beqz	a4,80201878 <wait+0xca>
    8020185a:	03092783          	lw	a5,48(s2)
    8020185e:	ef89                	bnez	a5,80201878 <wait+0xca>
        sleep(p, &p->lock);
    80201860:	85ca                	mv	a1,s2
    80201862:	854a                	mv	a0,s2
    80201864:	00000097          	auipc	ra,0x0
    80201868:	ecc080e7          	jalr	-308(ra) # 80201730 <sleep>
        for (struct proc *cp = proc; cp < &proc[NPROC]; cp++) {
    8020186c:	00028497          	auipc	s1,0x28
    80201870:	83448493          	add	s1,s1,-1996 # 802290a0 <proc>
        havekids = 0;
    80201874:	875e                	mv	a4,s7
    80201876:	bf7d                	j	80201834 <wait+0x86>
            release(&p->lock);
    80201878:	854a                	mv	a0,s2
    8020187a:	fffff097          	auipc	ra,0xfffff
    8020187e:	0b2080e7          	jalr	178(ra) # 8020092c <release>
            return -1;
    80201882:	59fd                	li	s3,-1
    80201884:	bf41                	j	80201814 <wait+0x66>

0000000080201886 <wait_process>:
void wait_process(int *status) { wait(status); }
    80201886:	1141                	add	sp,sp,-16
    80201888:	e406                	sd	ra,8(sp)
    8020188a:	e022                	sd	s0,0(sp)
    8020188c:	0800                	add	s0,sp,16
    8020188e:	00000097          	auipc	ra,0x0
    80201892:	f20080e7          	jalr	-224(ra) # 802017ae <wait>
    80201896:	60a2                	ld	ra,8(sp)
    80201898:	6402                	ld	s0,0(sp)
    8020189a:	0141                	add	sp,sp,16
    8020189c:	8082                	ret

000000008020189e <wakeup>:

void wakeup(void *chan) {
    8020189e:	7139                	add	sp,sp,-64
    802018a0:	fc06                	sd	ra,56(sp)
    802018a2:	f822                	sd	s0,48(sp)
    802018a4:	f426                	sd	s1,40(sp)
    802018a6:	f04a                	sd	s2,32(sp)
    802018a8:	ec4e                	sd	s3,24(sp)
    802018aa:	e852                	sd	s4,16(sp)
    802018ac:	e456                	sd	s5,8(sp)
    802018ae:	0080                	add	s0,sp,64
    802018b0:	8a2a                	mv	s4,a0
    for (struct proc *p = proc; p < &proc[NPROC]; p++) {
    802018b2:	00027497          	auipc	s1,0x27
    802018b6:	7ee48493          	add	s1,s1,2030 # 802290a0 <proc>
        if (p != myproc()) {
            acquire(&p->lock);
            if (p->state == SLEEPING && p->chan == chan) {
    802018ba:	4989                	li	s3,2
                p->state = RUNNABLE;
    802018bc:	4a8d                	li	s5,3
    for (struct proc *p = proc; p < &proc[NPROC]; p++) {
    802018be:	0002d917          	auipc	s2,0x2d
    802018c2:	fe290913          	add	s2,s2,-30 # 8022e8a0 <bcache>
    802018c6:	a811                	j	802018da <wakeup+0x3c>
            }
            release(&p->lock);
    802018c8:	8526                	mv	a0,s1
    802018ca:	fffff097          	auipc	ra,0xfffff
    802018ce:	062080e7          	jalr	98(ra) # 8020092c <release>
    for (struct proc *p = proc; p < &proc[NPROC]; p++) {
    802018d2:	16048493          	add	s1,s1,352
    802018d6:	03248663          	beq	s1,s2,80201902 <wakeup+0x64>
        if (p != myproc()) {
    802018da:	00000097          	auipc	ra,0x0
    802018de:	abe080e7          	jalr	-1346(ra) # 80201398 <myproc>
    802018e2:	fea488e3          	beq	s1,a0,802018d2 <wakeup+0x34>
            acquire(&p->lock);
    802018e6:	8526                	mv	a0,s1
    802018e8:	fffff097          	auipc	ra,0xfffff
    802018ec:	f52080e7          	jalr	-174(ra) # 8020083a <acquire>
            if (p->state == SLEEPING && p->chan == chan) {
    802018f0:	4c9c                	lw	a5,24(s1)
    802018f2:	fd379be3          	bne	a5,s3,802018c8 <wakeup+0x2a>
    802018f6:	749c                	ld	a5,40(s1)
    802018f8:	fd4798e3          	bne	a5,s4,802018c8 <wakeup+0x2a>
                p->state = RUNNABLE;
    802018fc:	0154ac23          	sw	s5,24(s1)
    80201900:	b7e1                	j	802018c8 <wakeup+0x2a>
        }
    }
}
    80201902:	70e2                	ld	ra,56(sp)
    80201904:	7442                	ld	s0,48(sp)
    80201906:	74a2                	ld	s1,40(sp)
    80201908:	7902                	ld	s2,32(sp)
    8020190a:	69e2                	ld	s3,24(sp)
    8020190c:	6a42                	ld	s4,16(sp)
    8020190e:	6aa2                	ld	s5,8(sp)
    80201910:	6121                	add	sp,sp,64
    80201912:	8082                	ret

0000000080201914 <exit>:
void exit(int status) {
    80201914:	7179                	add	sp,sp,-48
    80201916:	f406                	sd	ra,40(sp)
    80201918:	f022                	sd	s0,32(sp)
    8020191a:	ec26                	sd	s1,24(sp)
    8020191c:	e84a                	sd	s2,16(sp)
    8020191e:	e44e                	sd	s3,8(sp)
    80201920:	e052                	sd	s4,0(sp)
    80201922:	1800                	add	s0,sp,48
    80201924:	8a2a                	mv	s4,a0
    struct proc *p = myproc();
    80201926:	00000097          	auipc	ra,0x0
    8020192a:	a72080e7          	jalr	-1422(ra) # 80201398 <myproc>
    8020192e:	89aa                	mv	s3,a0
    for (int fd = 0; fd < NOFILE; fd++) {
    80201930:	0d850493          	add	s1,a0,216
    80201934:	15850913          	add	s2,a0,344
    80201938:	a021                	j	80201940 <exit+0x2c>
    8020193a:	04a1                	add	s1,s1,8
    8020193c:	01248b63          	beq	s1,s2,80201952 <exit+0x3e>
        if (p->ofile[fd]) {
    80201940:	6088                	ld	a0,0(s1)
    80201942:	dd65                	beqz	a0,8020193a <exit+0x26>
            fileclose(p->ofile[fd]);
    80201944:	00002097          	auipc	ra,0x2
    80201948:	0f0080e7          	jalr	240(ra) # 80203a34 <fileclose>
            p->ofile[fd] = 0;
    8020194c:	0004b023          	sd	zero,0(s1)
    80201950:	b7ed                	j	8020193a <exit+0x26>
    if (p->cwd) {
    80201952:	1589b503          	ld	a0,344(s3)
    80201956:	c519                	beqz	a0,80201964 <exit+0x50>
        iput(p->cwd);
    80201958:	00001097          	auipc	ra,0x1
    8020195c:	1fe080e7          	jalr	510(ra) # 80202b56 <iput>
        p->cwd = 0;
    80201960:	1409bc23          	sd	zero,344(s3)
    acquire(&p->lock);
    80201964:	854e                	mv	a0,s3
    80201966:	fffff097          	auipc	ra,0xfffff
    8020196a:	ed4080e7          	jalr	-300(ra) # 8020083a <acquire>
    p->state = ZOMBIE;
    8020196e:	4795                	li	a5,5
    80201970:	00f9ac23          	sw	a5,24(s3)
    p->xstate = status;
    80201974:	0349aa23          	sw	s4,52(s3)
    if (p->parent) wakeup(p->parent);
    80201978:	0209b503          	ld	a0,32(s3)
    8020197c:	c509                	beqz	a0,80201986 <exit+0x72>
    8020197e:	00000097          	auipc	ra,0x0
    80201982:	f20080e7          	jalr	-224(ra) # 8020189e <wakeup>
    sched();
    80201986:	00000097          	auipc	ra,0x0
    8020198a:	d2a080e7          	jalr	-726(ra) # 802016b0 <sched>
    while(1);
    8020198e:	a001                	j	8020198e <exit+0x7a>

0000000080201990 <proc_entry>:
void proc_entry(void) {
    80201990:	1101                	add	sp,sp,-32
    80201992:	ec06                	sd	ra,24(sp)
    80201994:	e822                	sd	s0,16(sp)
    80201996:	e426                	sd	s1,8(sp)
    80201998:	1000                	add	s0,sp,32
    struct proc *p = myproc();
    8020199a:	00000097          	auipc	ra,0x0
    8020199e:	9fe080e7          	jalr	-1538(ra) # 80201398 <myproc>
    if (p == 0) {
    802019a2:	cd11                	beqz	a0,802019be <proc_entry+0x2e>
    802019a4:	84aa                	mv	s1,a0
    release(&p->lock);
    802019a6:	fffff097          	auipc	ra,0xfffff
    802019aa:	f86080e7          	jalr	-122(ra) # 8020092c <release>
    if (p->entry) p->entry();
    802019ae:	60fc                	ld	a5,192(s1)
    802019b0:	c391                	beqz	a5,802019b4 <proc_entry+0x24>
    802019b2:	9782                	jalr	a5
    exit(0);
    802019b4:	4501                	li	a0,0
    802019b6:	00000097          	auipc	ra,0x0
    802019ba:	f5e080e7          	jalr	-162(ra) # 80201914 <exit>
        printf("FATAL: proc_entry running with no process context!\n");
    802019be:	00005517          	auipc	a0,0x5
    802019c2:	aaa50513          	add	a0,a0,-1366 # 80206468 <_etext+0x468>
    802019c6:	ffffe097          	auipc	ra,0xffffe
    802019ca:	78e080e7          	jalr	1934(ra) # 80200154 <printf>
        while(1);
    802019ce:	a001                	j	802019ce <proc_entry+0x3e>

00000000802019d0 <trap_init>:
    register uint64 a6 asm("a6") = 0;
    register uint64 a0 asm("a0") = stime;
    asm volatile("ecall" : "+r"(a0) : "r"(a6), "r"(a7) : "memory");
}

void trap_init(void) {
    802019d0:	1141                	add	sp,sp,-16
    802019d2:	e422                	sd	s0,8(sp)
    802019d4:	0800                	add	s0,sp,16
static inline void w_stvec(uint64 x) { asm volatile("csrw stvec, %0" : : "r" (x)); }
    802019d6:	00003797          	auipc	a5,0x3
    802019da:	e6a78793          	add	a5,a5,-406 # 80204840 <kernelvec>
    802019de:	10579073          	csrw	stvec,a5
    w_stvec((uint64)kernelvec);
}
    802019e2:	6422                	ld	s0,8(sp)
    802019e4:	0141                	add	sp,sp,16
    802019e6:	8082                	ret

00000000802019e8 <clock_init>:

void clock_init(void) {
    802019e8:	1141                	add	sp,sp,-16
    802019ea:	e422                	sd	s0,8(sp)
    802019ec:	0800                	add	s0,sp,16
static inline uint64 r_time() { uint64 x; asm volatile("csrr %0, time" : "=r" (x)); return x; }
    802019ee:	c0102573          	rdtime	a0
    register uint64 a7 asm("a7") = 0;
    802019f2:	4881                	li	a7,0
    register uint64 a6 asm("a6") = 0;
    802019f4:	4801                	li	a6,0
    register uint64 a0 asm("a0") = stime;
    802019f6:	67e1                	lui	a5,0x18
    802019f8:	6a078793          	add	a5,a5,1696 # 186a0 <_start-0x801e7960>
    802019fc:	953e                	add	a0,a0,a5
    asm volatile("ecall" : "+r"(a0) : "r"(a6), "r"(a7) : "memory");
    802019fe:	00000073          	ecall
static inline uint64 r_sie() { uint64 x; asm volatile("csrr %0, sie" : "=r" (x)); return x; }
    80201a02:	104027f3          	csrr	a5,sie
    uint64 next_timer = r_time() + 100000;
    sbi_set_timer(next_timer);
    w_sie(r_sie() | SIE_STIE);
    80201a06:	0207e793          	or	a5,a5,32
static inline void w_sie(uint64 x) { asm volatile("csrw sie, %0" : : "r" (x)); }
    80201a0a:	10479073          	csrw	sie,a5
}
    80201a0e:	6422                	ld	s0,8(sp)
    80201a10:	0141                	add	sp,sp,16
    80201a12:	8082                	ret

0000000080201a14 <get_time>:

uint64 get_time(void) { return r_time(); }
    80201a14:	1141                	add	sp,sp,-16
    80201a16:	e422                	sd	s0,8(sp)
    80201a18:	0800                	add	s0,sp,16
static inline uint64 r_time() { uint64 x; asm volatile("csrr %0, time" : "=r" (x)); return x; }
    80201a1a:	c0102573          	rdtime	a0
    80201a1e:	6422                	ld	s0,8(sp)
    80201a20:	0141                	add	sp,sp,16
    80201a22:	8082                	ret

0000000080201a24 <fork_ret>:

void fork_ret() {
    80201a24:	1101                	add	sp,sp,-32
    80201a26:	ec06                	sd	ra,24(sp)
    80201a28:	e822                	sd	s0,16(sp)
    80201a2a:	e426                	sd	s1,8(sp)
    80201a2c:	1000                	add	s0,sp,32
    struct proc *p = myproc();
    80201a2e:	00000097          	auipc	ra,0x0
    80201a32:	96a080e7          	jalr	-1686(ra) # 80201398 <myproc>
    80201a36:	84aa                	mv	s1,a0
    release(&p->lock); 
    80201a38:	fffff097          	auipc	ra,0xfffff
    80201a3c:	ef4080e7          	jalr	-268(ra) # 8020092c <release>
    restore_trapframe(p->trapframe);
    80201a40:	60a8                	ld	a0,64(s1)
    80201a42:	00003097          	auipc	ra,0x3
    80201a46:	e86080e7          	jalr	-378(ra) # 802048c8 <restore_trapframe>
}
    80201a4a:	60e2                	ld	ra,24(sp)
    80201a4c:	6442                	ld	s0,16(sp)
    80201a4e:	64a2                	ld	s1,8(sp)
    80201a50:	6105                	add	sp,sp,32
    80201a52:	8082                	ret

0000000080201a54 <kerneltrap>:

void kerneltrap(uint64 sp_val) {
    80201a54:	7139                	add	sp,sp,-64
    80201a56:	fc06                	sd	ra,56(sp)
    80201a58:	f822                	sd	s0,48(sp)
    80201a5a:	f426                	sd	s1,40(sp)
    80201a5c:	f04a                	sd	s2,32(sp)
    80201a5e:	ec4e                	sd	s3,24(sp)
    80201a60:	e852                	sd	s4,16(sp)
    80201a62:	e456                	sd	s5,8(sp)
    80201a64:	0080                	add	s0,sp,64
static inline uint64 r_scause() { uint64 x; asm volatile("csrr %0, scause" : "=r" (x)); return x; }
    80201a66:	14202973          	csrr	s2,scause
static inline uint64 r_sepc() { uint64 x; asm volatile("csrr %0, sepc" : "=r" (x)); return x; }
    80201a6a:	141029f3          	csrr	s3,sepc
static inline uint64 r_sstatus() { uint64 x; asm volatile("csrr %0, sstatus" : "=r" (x)); return x; }
    80201a6e:	10002af3          	csrr	s5,sstatus
static inline uint64 r_stval() { uint64 x; asm volatile("csrr %0, stval" : "=r" (x) ); return x; }
    80201a72:	14302a73          	csrr	s4,stval
    uint64 scause = r_scause();
    uint64 sepc = r_sepc();
    uint64 sstatus = r_sstatus();
    uint64 stval = r_stval();

    struct proc *p = myproc();
    80201a76:	00000097          	auipc	ra,0x0
    80201a7a:	922080e7          	jalr	-1758(ra) # 80201398 <myproc>
    80201a7e:	84aa                	mv	s1,a0
    
    // 防御性检查：确保 p 和 p->trapframe 有效
    if (p != 0 && p->trapframe != 0) {
    80201a80:	10050063          	beqz	a0,80201b80 <kerneltrap+0x12c>
    80201a84:	613c                	ld	a5,64(a0)
    80201a86:	12078763          	beqz	a5,80201bb4 <kerneltrap+0x160>
        p->trapframe->epc = sepc;
    80201a8a:	0137bc23          	sd	s3,24(a5)
    }

    if (scause == 8) { // System Call
    80201a8e:	47a1                	li	a5,8
    80201a90:	02f90863          	beq	s2,a5,80201ac0 <kerneltrap+0x6c>
        if(p && p->trapframe) p->trapframe->epc += 4;
        intr_on();
        syscall();
        intr_off();
    } 
    else if (scause == 15) { // Store/AMO Page Fault (COW)
    80201a94:	47bd                	li	a5,15
    80201a96:	06f90463          	beq	s2,a5,80201afe <kerneltrap+0xaa>
            printf("kerneltrap: Fatal Page Fault at %p without process context\n", stval);
            printf("scause=%p sepc=%p\n", scause, sepc);
            while(1);
        }
    }
    else if ((scause & 0x8000000000000000L) && (scause & 0xff) == 5) { // Timer
    80201a9a:	00095763          	bgez	s2,80201aa8 <kerneltrap+0x54>
    80201a9e:	0ff97793          	zext.b	a5,s2
    80201aa2:	4715                	li	a4,5
    80201aa4:	08e78563          	beq	a5,a4,80201b2e <kerneltrap+0xda>
        uint64 next_timer = r_time() + 100000;
        sbi_set_timer(next_timer);
        if (p != 0 && p->state == RUNNING) yield();
    }
    else {
        printf("kerneltrap: unhandled exception scause %p, sepc %p, stval %p\n", scause, sepc, stval);
    80201aa8:	86d2                	mv	a3,s4
    80201aaa:	864e                	mv	a2,s3
    80201aac:	85ca                	mv	a1,s2
    80201aae:	00005517          	auipc	a0,0x5
    80201ab2:	a8250513          	add	a0,a0,-1406 # 80206530 <_etext+0x530>
    80201ab6:	ffffe097          	auipc	ra,0xffffe
    80201aba:	69e080e7          	jalr	1694(ra) # 80200154 <printf>
        // 如果是 p->trapframe 为空导致的故障，这里会打印出来
        while(1);
    80201abe:	a001                	j	80201abe <kerneltrap+0x6a>
        if(p && p->trapframe) p->trapframe->epc += 4;
    80201ac0:	613c                	ld	a5,64(a0)
    80201ac2:	c781                	beqz	a5,80201aca <kerneltrap+0x76>
    80201ac4:	6f98                	ld	a4,24(a5)
    80201ac6:	0711                	add	a4,a4,4
    80201ac8:	ef98                	sd	a4,24(a5)
static inline uint64 r_sstatus() { uint64 x; asm volatile("csrr %0, sstatus" : "=r" (x)); return x; }
    80201aca:	100027f3          	csrr	a5,sstatus
    80201ace:	0027e793          	or	a5,a5,2
static inline void w_sstatus(uint64 x) { asm volatile("csrw sstatus, %0" : : "r" (x)); }
    80201ad2:	10079073          	csrw	sstatus,a5
        syscall();
    80201ad6:	00000097          	auipc	ra,0x0
    80201ada:	25a080e7          	jalr	602(ra) # 80201d30 <syscall>
static inline uint64 r_sstatus() { uint64 x; asm volatile("csrr %0, sstatus" : "=r" (x)); return x; }
    80201ade:	100027f3          	csrr	a5,sstatus
    w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80201ae2:	9bf5                	and	a5,a5,-3
static inline void w_sstatus(uint64 x) { asm volatile("csrw sstatus, %0" : : "r" (x)); }
    80201ae4:	10079073          	csrw	sstatus,a5
    }

    if (p && p->killed) {
    80201ae8:	c4bd                	beqz	s1,80201b56 <kerneltrap+0x102>
    80201aea:	589c                	lw	a5,48(s1)
    80201aec:	e3d1                	bnez	a5,80201b70 <kerneltrap+0x11c>
    80201aee:	100a9073          	csrw	sstatus,s5
        exit(-1);
    }
    
    w_sstatus(sstatus);
    if (p && p->trapframe) w_sepc(p->trapframe->epc);
    80201af2:	60bc                	ld	a5,64(s1)
    80201af4:	c3bd                	beqz	a5,80201b5a <kerneltrap+0x106>
static inline void w_sepc(uint64 x) { asm volatile("csrw sepc, %0" : : "r" (x)); }
    80201af6:	6f9c                	ld	a5,24(a5)
    80201af8:	14179073          	csrw	sepc,a5
    80201afc:	a08d                	j	80201b5e <kerneltrap+0x10a>
        if (p != 0 && p->pagetable != 0) {
    80201afe:	64a8                	ld	a0,72(s1)
    80201b00:	c551                	beqz	a0,80201b8c <kerneltrap+0x138>
            if (cow_alloc(p->pagetable, stval) == 0) {
    80201b02:	85d2                	mv	a1,s4
    80201b04:	fffff097          	auipc	ra,0xfffff
    80201b08:	2e6080e7          	jalr	742(ra) # 80200dea <cow_alloc>
    80201b0c:	dd79                	beqz	a0,80201aea <kerneltrap+0x96>
                printf("kerneltrap: cow_alloc failed for va %p, killing pid %d\n", stval, p->pid);
    80201b0e:	4cd0                	lw	a2,28(s1)
    80201b10:	85d2                	mv	a1,s4
    80201b12:	00005517          	auipc	a0,0x5
    80201b16:	98e50513          	add	a0,a0,-1650 # 802064a0 <_etext+0x4a0>
    80201b1a:	ffffe097          	auipc	ra,0xffffe
    80201b1e:	63a080e7          	jalr	1594(ra) # 80200154 <printf>
                if(p) exit(-1);
    80201b22:	557d                	li	a0,-1
    80201b24:	00000097          	auipc	ra,0x0
    80201b28:	df0080e7          	jalr	-528(ra) # 80201914 <exit>
    if (p && p->killed) {
    80201b2c:	bf7d                	j	80201aea <kerneltrap+0x96>
static inline uint64 r_time() { uint64 x; asm volatile("csrr %0, time" : "=r" (x)); return x; }
    80201b2e:	c0102573          	rdtime	a0
    register uint64 a7 asm("a7") = 0;
    80201b32:	4881                	li	a7,0
    register uint64 a6 asm("a6") = 0;
    80201b34:	4801                	li	a6,0
    register uint64 a0 asm("a0") = stime;
    80201b36:	67e1                	lui	a5,0x18
    80201b38:	6a078793          	add	a5,a5,1696 # 186a0 <_start-0x801e7960>
    80201b3c:	953e                	add	a0,a0,a5
    asm volatile("ecall" : "+r"(a0) : "r"(a6), "r"(a7) : "memory");
    80201b3e:	00000073          	ecall
        if (p != 0 && p->state == RUNNING) yield();
    80201b42:	c891                	beqz	s1,80201b56 <kerneltrap+0x102>
    80201b44:	4c98                	lw	a4,24(s1)
    80201b46:	4791                	li	a5,4
    80201b48:	faf711e3          	bne	a4,a5,80201aea <kerneltrap+0x96>
    80201b4c:	00000097          	auipc	ra,0x0
    80201b50:	ba8080e7          	jalr	-1112(ra) # 802016f4 <yield>
    if (p && p->killed) {
    80201b54:	bf59                	j	80201aea <kerneltrap+0x96>
static inline void w_sstatus(uint64 x) { asm volatile("csrw sstatus, %0" : : "r" (x)); }
    80201b56:	100a9073          	csrw	sstatus,s5
static inline void w_sepc(uint64 x) { asm volatile("csrw sepc, %0" : : "r" (x)); }
    80201b5a:	14199073          	csrw	sepc,s3
    else w_sepc(sepc); // 回退到使用局部 sepc，如果 p 无效
}
    80201b5e:	70e2                	ld	ra,56(sp)
    80201b60:	7442                	ld	s0,48(sp)
    80201b62:	74a2                	ld	s1,40(sp)
    80201b64:	7902                	ld	s2,32(sp)
    80201b66:	69e2                	ld	s3,24(sp)
    80201b68:	6a42                	ld	s4,16(sp)
    80201b6a:	6aa2                	ld	s5,8(sp)
    80201b6c:	6121                	add	sp,sp,64
    80201b6e:	8082                	ret
        exit(-1);
    80201b70:	557d                	li	a0,-1
    80201b72:	00000097          	auipc	ra,0x0
    80201b76:	da2080e7          	jalr	-606(ra) # 80201914 <exit>
static inline void w_sstatus(uint64 x) { asm volatile("csrw sstatus, %0" : : "r" (x)); }
    80201b7a:	100a9073          	csrw	sstatus,s5
    if (p && p->trapframe) w_sepc(p->trapframe->epc);
    80201b7e:	bf95                	j	80201af2 <kerneltrap+0x9e>
    if (scause == 8) { // System Call
    80201b80:	47a1                	li	a5,8
    80201b82:	f4f904e3          	beq	s2,a5,80201aca <kerneltrap+0x76>
    else if (scause == 15) { // Store/AMO Page Fault (COW)
    80201b86:	47bd                	li	a5,15
    80201b88:	f0f919e3          	bne	s2,a5,80201a9a <kerneltrap+0x46>
            printf("kerneltrap: Fatal Page Fault at %p without process context\n", stval);
    80201b8c:	85d2                	mv	a1,s4
    80201b8e:	00005517          	auipc	a0,0x5
    80201b92:	94a50513          	add	a0,a0,-1718 # 802064d8 <_etext+0x4d8>
    80201b96:	ffffe097          	auipc	ra,0xffffe
    80201b9a:	5be080e7          	jalr	1470(ra) # 80200154 <printf>
            printf("scause=%p sepc=%p\n", scause, sepc);
    80201b9e:	864e                	mv	a2,s3
    80201ba0:	45bd                	li	a1,15
    80201ba2:	00005517          	auipc	a0,0x5
    80201ba6:	97650513          	add	a0,a0,-1674 # 80206518 <_etext+0x518>
    80201baa:	ffffe097          	auipc	ra,0xffffe
    80201bae:	5aa080e7          	jalr	1450(ra) # 80200154 <printf>
            while(1);
    80201bb2:	a001                	j	80201bb2 <kerneltrap+0x15e>
    if (scause == 8) { // System Call
    80201bb4:	47a1                	li	a5,8
    80201bb6:	ecf91fe3          	bne	s2,a5,80201a94 <kerneltrap+0x40>
    80201bba:	bf01                	j	80201aca <kerneltrap+0x76>

0000000080201bbc <argint>:
    [SYS_mknod]   sys_mknod,
    [SYS_chdir]   sys_chdir,
    [SYS_fstat]   sys_fstat,
};

int argint(int n, int *ip) {
    80201bbc:	1101                	add	sp,sp,-32
    80201bbe:	ec06                	sd	ra,24(sp)
    80201bc0:	e822                	sd	s0,16(sp)
    80201bc2:	e426                	sd	s1,8(sp)
    80201bc4:	e04a                	sd	s2,0(sp)
    80201bc6:	1000                	add	s0,sp,32
    80201bc8:	84aa                	mv	s1,a0
    80201bca:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80201bcc:	fffff097          	auipc	ra,0xfffff
    80201bd0:	7cc080e7          	jalr	1996(ra) # 80201398 <myproc>
    if (p == 0 || p->trapframe == 0) return -1;
    80201bd4:	c13d                	beqz	a0,80201c3a <argint+0x7e>
    80201bd6:	6134                	ld	a3,64(a0)
    80201bd8:	c2bd                	beqz	a3,80201c3e <argint+0x82>
    switch(n) {
    80201bda:	4795                	li	a5,5
    80201bdc:	0697e363          	bltu	a5,s1,80201c42 <argint+0x86>
    80201be0:	00249793          	sll	a5,s1,0x2
    80201be4:	00005717          	auipc	a4,0x5
    80201be8:	98c70713          	add	a4,a4,-1652 # 80206570 <_etext+0x570>
    80201bec:	97ba                	add	a5,a5,a4
    80201bee:	439c                	lw	a5,0(a5)
    80201bf0:	97ba                	add	a5,a5,a4
    80201bf2:	8782                	jr	a5
        case 0: *ip = p->trapframe->a0; break;
    80201bf4:	7abc                	ld	a5,112(a3)
    80201bf6:	00f92023          	sw	a5,0(s2)
        case 3: *ip = p->trapframe->a3; break;
        case 4: *ip = p->trapframe->a4; break;
        case 5: *ip = p->trapframe->a5; break;
        default: return -1;
    }
    return 0;
    80201bfa:	8526                	mv	a0,s1
}
    80201bfc:	60e2                	ld	ra,24(sp)
    80201bfe:	6442                	ld	s0,16(sp)
    80201c00:	64a2                	ld	s1,8(sp)
    80201c02:	6902                	ld	s2,0(sp)
    80201c04:	6105                	add	sp,sp,32
    80201c06:	8082                	ret
        case 1: *ip = p->trapframe->a1; break;
    80201c08:	7ebc                	ld	a5,120(a3)
    80201c0a:	00f92023          	sw	a5,0(s2)
    return 0;
    80201c0e:	4501                	li	a0,0
        case 1: *ip = p->trapframe->a1; break;
    80201c10:	b7f5                	j	80201bfc <argint+0x40>
        case 2: *ip = p->trapframe->a2; break;
    80201c12:	62dc                	ld	a5,128(a3)
    80201c14:	00f92023          	sw	a5,0(s2)
    return 0;
    80201c18:	4501                	li	a0,0
        case 2: *ip = p->trapframe->a2; break;
    80201c1a:	b7cd                	j	80201bfc <argint+0x40>
        case 3: *ip = p->trapframe->a3; break;
    80201c1c:	66dc                	ld	a5,136(a3)
    80201c1e:	00f92023          	sw	a5,0(s2)
    return 0;
    80201c22:	4501                	li	a0,0
        case 3: *ip = p->trapframe->a3; break;
    80201c24:	bfe1                	j	80201bfc <argint+0x40>
        case 4: *ip = p->trapframe->a4; break;
    80201c26:	6adc                	ld	a5,144(a3)
    80201c28:	00f92023          	sw	a5,0(s2)
    return 0;
    80201c2c:	4501                	li	a0,0
        case 4: *ip = p->trapframe->a4; break;
    80201c2e:	b7f9                	j	80201bfc <argint+0x40>
        case 5: *ip = p->trapframe->a5; break;
    80201c30:	6edc                	ld	a5,152(a3)
    80201c32:	00f92023          	sw	a5,0(s2)
    return 0;
    80201c36:	4501                	li	a0,0
        case 5: *ip = p->trapframe->a5; break;
    80201c38:	b7d1                	j	80201bfc <argint+0x40>
    if (p == 0 || p->trapframe == 0) return -1;
    80201c3a:	557d                	li	a0,-1
    80201c3c:	b7c1                	j	80201bfc <argint+0x40>
    80201c3e:	557d                	li	a0,-1
    80201c40:	bf75                	j	80201bfc <argint+0x40>
    switch(n) {
    80201c42:	557d                	li	a0,-1
    80201c44:	bf65                	j	80201bfc <argint+0x40>

0000000080201c46 <argaddr>:

int argaddr(int n, uint64 *ip) {
    80201c46:	1101                	add	sp,sp,-32
    80201c48:	ec06                	sd	ra,24(sp)
    80201c4a:	e822                	sd	s0,16(sp)
    80201c4c:	e426                	sd	s1,8(sp)
    80201c4e:	e04a                	sd	s2,0(sp)
    80201c50:	1000                	add	s0,sp,32
    80201c52:	84aa                	mv	s1,a0
    80201c54:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80201c56:	fffff097          	auipc	ra,0xfffff
    80201c5a:	742080e7          	jalr	1858(ra) # 80201398 <myproc>
    if (p == 0 || p->trapframe == 0) return -1;
    80201c5e:	c13d                	beqz	a0,80201cc4 <argaddr+0x7e>
    80201c60:	6134                	ld	a3,64(a0)
    80201c62:	c2bd                	beqz	a3,80201cc8 <argaddr+0x82>
    switch(n) {
    80201c64:	4795                	li	a5,5
    80201c66:	0697e363          	bltu	a5,s1,80201ccc <argaddr+0x86>
    80201c6a:	00249793          	sll	a5,s1,0x2
    80201c6e:	00005717          	auipc	a4,0x5
    80201c72:	91a70713          	add	a4,a4,-1766 # 80206588 <_etext+0x588>
    80201c76:	97ba                	add	a5,a5,a4
    80201c78:	439c                	lw	a5,0(a5)
    80201c7a:	97ba                	add	a5,a5,a4
    80201c7c:	8782                	jr	a5
        case 0: *ip = p->trapframe->a0; break;
    80201c7e:	7abc                	ld	a5,112(a3)
    80201c80:	00f93023          	sd	a5,0(s2)
        case 3: *ip = p->trapframe->a3; break;
        case 4: *ip = p->trapframe->a4; break;
        case 5: *ip = p->trapframe->a5; break;
        default: return -1;
    }
    return 0;
    80201c84:	8526                	mv	a0,s1
}
    80201c86:	60e2                	ld	ra,24(sp)
    80201c88:	6442                	ld	s0,16(sp)
    80201c8a:	64a2                	ld	s1,8(sp)
    80201c8c:	6902                	ld	s2,0(sp)
    80201c8e:	6105                	add	sp,sp,32
    80201c90:	8082                	ret
        case 1: *ip = p->trapframe->a1; break;
    80201c92:	7ebc                	ld	a5,120(a3)
    80201c94:	00f93023          	sd	a5,0(s2)
    return 0;
    80201c98:	4501                	li	a0,0
        case 1: *ip = p->trapframe->a1; break;
    80201c9a:	b7f5                	j	80201c86 <argaddr+0x40>
        case 2: *ip = p->trapframe->a2; break;
    80201c9c:	62dc                	ld	a5,128(a3)
    80201c9e:	00f93023          	sd	a5,0(s2)
    return 0;
    80201ca2:	4501                	li	a0,0
        case 2: *ip = p->trapframe->a2; break;
    80201ca4:	b7cd                	j	80201c86 <argaddr+0x40>
        case 3: *ip = p->trapframe->a3; break;
    80201ca6:	66dc                	ld	a5,136(a3)
    80201ca8:	00f93023          	sd	a5,0(s2)
    return 0;
    80201cac:	4501                	li	a0,0
        case 3: *ip = p->trapframe->a3; break;
    80201cae:	bfe1                	j	80201c86 <argaddr+0x40>
        case 4: *ip = p->trapframe->a4; break;
    80201cb0:	6adc                	ld	a5,144(a3)
    80201cb2:	00f93023          	sd	a5,0(s2)
    return 0;
    80201cb6:	4501                	li	a0,0
        case 4: *ip = p->trapframe->a4; break;
    80201cb8:	b7f9                	j	80201c86 <argaddr+0x40>
        case 5: *ip = p->trapframe->a5; break;
    80201cba:	6edc                	ld	a5,152(a3)
    80201cbc:	00f93023          	sd	a5,0(s2)
    return 0;
    80201cc0:	4501                	li	a0,0
        case 5: *ip = p->trapframe->a5; break;
    80201cc2:	b7d1                	j	80201c86 <argaddr+0x40>
    if (p == 0 || p->trapframe == 0) return -1;
    80201cc4:	557d                	li	a0,-1
    80201cc6:	b7c1                	j	80201c86 <argaddr+0x40>
    80201cc8:	557d                	li	a0,-1
    80201cca:	bf75                	j	80201c86 <argaddr+0x40>
    switch(n) {
    80201ccc:	557d                	li	a0,-1
    80201cce:	bf65                	j	80201c86 <argaddr+0x40>

0000000080201cd0 <argstr>:
//从用户态传递的第n个参数中，解析出字符串（用户态地址），并将其拷贝到内核的buf中，最多拷贝max字节。
int argstr(int n, char *buf, int max) {
    80201cd0:	7179                	add	sp,sp,-48
    80201cd2:	f406                	sd	ra,40(sp)
    80201cd4:	f022                	sd	s0,32(sp)
    80201cd6:	ec26                	sd	s1,24(sp)
    80201cd8:	e84a                	sd	s2,16(sp)
    80201cda:	1800                	add	s0,sp,48
    80201cdc:	84ae                	mv	s1,a1
    80201cde:	8932                	mv	s2,a2
    uint64 addr;
    if(argaddr(n, &addr) < 0) return -1;
    80201ce0:	fd840593          	add	a1,s0,-40
    80201ce4:	00000097          	auipc	ra,0x0
    80201ce8:	f62080e7          	jalr	-158(ra) # 80201c46 <argaddr>
    80201cec:	04054063          	bltz	a0,80201d2c <argstr+0x5c>
    char *src = (char*)addr;
    80201cf0:	fd843683          	ld	a3,-40(s0)
    for(int i = 0; i < max; i++){
    80201cf4:	03205063          	blez	s2,80201d14 <argstr+0x44>
    80201cf8:	85ca                	mv	a1,s2
    80201cfa:	4501                	li	a0,0
        buf[i] = src[i];
    80201cfc:	00a687b3          	add	a5,a3,a0
    80201d00:	0007c783          	lbu	a5,0(a5)
    80201d04:	00a48733          	add	a4,s1,a0
    80201d08:	00f70023          	sb	a5,0(a4)
        if(src[i] == 0) return i;
    80201d0c:	cf91                	beqz	a5,80201d28 <argstr+0x58>
    for(int i = 0; i < max; i++){
    80201d0e:	0505                	add	a0,a0,1
    80201d10:	feb516e3          	bne	a0,a1,80201cfc <argstr+0x2c>
    }
    buf[max-1] = 0;
    80201d14:	94ca                	add	s1,s1,s2
    80201d16:	fe048fa3          	sb	zero,-1(s1)
    return -1;
    80201d1a:	557d                	li	a0,-1
}
    80201d1c:	70a2                	ld	ra,40(sp)
    80201d1e:	7402                	ld	s0,32(sp)
    80201d20:	64e2                	ld	s1,24(sp)
    80201d22:	6942                	ld	s2,16(sp)
    80201d24:	6145                	add	sp,sp,48
    80201d26:	8082                	ret
    80201d28:	2501                	sext.w	a0,a0
    80201d2a:	bfcd                	j	80201d1c <argstr+0x4c>
    if(argaddr(n, &addr) < 0) return -1;
    80201d2c:	557d                	li	a0,-1
    80201d2e:	b7fd                	j	80201d1c <argstr+0x4c>

0000000080201d30 <syscall>:
//用户态执行ecall指令陷入内核,调用该函数，完成系统调用的分发和执行。
void syscall(void) {
    80201d30:	1101                	add	sp,sp,-32
    80201d32:	ec06                	sd	ra,24(sp)
    80201d34:	e822                	sd	s0,16(sp)
    80201d36:	e426                	sd	s1,8(sp)
    80201d38:	1000                	add	s0,sp,32
    int num;
    struct proc *p = myproc();
    80201d3a:	fffff097          	auipc	ra,0xfffff
    80201d3e:	65e080e7          	jalr	1630(ra) # 80201398 <myproc>
    // 检查进程和陷阱帧是否有效
    if (p == 0 || p->trapframe == 0) {
    80201d42:	c905                	beqz	a0,80201d72 <syscall+0x42>
    80201d44:	84aa                	mv	s1,a0
    80201d46:	613c                	ld	a5,64(a0)
    80201d48:	c78d                	beqz	a5,80201d72 <syscall+0x42>
        // panic("syscall");
        while(1);
    }
    // 从trapframe的a7寄存器中获取系统调用号
    num = p->trapframe->a7;
    80201d4a:	77dc                	ld	a5,168(a5)
    80201d4c:	0007869b          	sext.w	a3,a5

    if(num > 0 && num < sizeof(syscalls)/sizeof(syscalls[0]) && syscalls[num]) {
    80201d50:	37fd                	addw	a5,a5,-1
    80201d52:	4779                	li	a4,30
    80201d54:	02f76063          	bltu	a4,a5,80201d74 <syscall+0x44>
    80201d58:	00369713          	sll	a4,a3,0x3
    80201d5c:	00005797          	auipc	a5,0x5
    80201d60:	84478793          	add	a5,a5,-1980 # 802065a0 <syscalls>
    80201d64:	97ba                	add	a5,a5,a4
    80201d66:	639c                	ld	a5,0(a5)
    80201d68:	c791                	beqz	a5,80201d74 <syscall+0x44>
        p->trapframe->a0 = syscalls[num]();
    80201d6a:	9782                	jalr	a5
    80201d6c:	60bc                	ld	a5,64(s1)
    80201d6e:	fba8                	sd	a0,112(a5)
    80201d70:	a005                	j	80201d90 <syscall+0x60>
        while(1);
    80201d72:	a001                	j	80201d72 <syscall+0x42>
    } else {
        printf("pid %d %s: unknown sys call %d\n", p->pid, p->name, num);
    80201d74:	0c848613          	add	a2,s1,200
    80201d78:	4ccc                	lw	a1,28(s1)
    80201d7a:	00005517          	auipc	a0,0x5
    80201d7e:	92650513          	add	a0,a0,-1754 # 802066a0 <syscalls+0x100>
    80201d82:	ffffe097          	auipc	ra,0xffffe
    80201d86:	3d2080e7          	jalr	978(ra) # 80200154 <printf>
        p->trapframe->a0 = -1;
    80201d8a:	60bc                	ld	a5,64(s1)
    80201d8c:	577d                	li	a4,-1
    80201d8e:	fbb8                	sd	a4,112(a5)
    }
    80201d90:	60e2                	ld	ra,24(sp)
    80201d92:	6442                	ld	s0,16(sp)
    80201d94:	64a2                	ld	s1,8(sp)
    80201d96:	6105                	add	sp,sp,32
    80201d98:	8082                	ret

0000000080201d9a <sys_getpid>:
// kernel/sysproc.c
#include "defs.h"

int sys_getpid(void) {
    80201d9a:	1141                	add	sp,sp,-16
    80201d9c:	e406                	sd	ra,8(sp)
    80201d9e:	e022                	sd	s0,0(sp)
    80201da0:	0800                	add	s0,sp,16
    // [关键] 性能测试绝对不能包含 printf
    return myproc()->pid;
    80201da2:	fffff097          	auipc	ra,0xfffff
    80201da6:	5f6080e7          	jalr	1526(ra) # 80201398 <myproc>
}
    80201daa:	4d48                	lw	a0,28(a0)
    80201dac:	60a2                	ld	ra,8(sp)
    80201dae:	6402                	ld	s0,0(sp)
    80201db0:	0141                	add	sp,sp,16
    80201db2:	8082                	ret

0000000080201db4 <sys_exit>:

int sys_exit(void) {
    80201db4:	1101                	add	sp,sp,-32
    80201db6:	ec06                	sd	ra,24(sp)
    80201db8:	e822                	sd	s0,16(sp)
    80201dba:	1000                	add	s0,sp,32
    int n;
    if(argint(0, &n) < 0)
    80201dbc:	fec40593          	add	a1,s0,-20
    80201dc0:	4501                	li	a0,0
    80201dc2:	00000097          	auipc	ra,0x0
    80201dc6:	dfa080e7          	jalr	-518(ra) # 80201bbc <argint>
    80201dca:	00054d63          	bltz	a0,80201de4 <sys_exit+0x30>
        return -1;
    exit(n);
    80201dce:	fec42503          	lw	a0,-20(s0)
    80201dd2:	00000097          	auipc	ra,0x0
    80201dd6:	b42080e7          	jalr	-1214(ra) # 80201914 <exit>
    return 0; 
    80201dda:	4501                	li	a0,0
}
    80201ddc:	60e2                	ld	ra,24(sp)
    80201dde:	6442                	ld	s0,16(sp)
    80201de0:	6105                	add	sp,sp,32
    80201de2:	8082                	ret
        return -1;
    80201de4:	557d                	li	a0,-1
    80201de6:	bfdd                	j	80201ddc <sys_exit+0x28>

0000000080201de8 <sys_fork>:

int sys_fork(void) {
    80201de8:	1141                	add	sp,sp,-16
    80201dea:	e406                	sd	ra,8(sp)
    80201dec:	e022                	sd	s0,0(sp)
    80201dee:	0800                	add	s0,sp,16
    return fork();
    80201df0:	fffff097          	auipc	ra,0xfffff
    80201df4:	6ca080e7          	jalr	1738(ra) # 802014ba <fork>
}
    80201df8:	60a2                	ld	ra,8(sp)
    80201dfa:	6402                	ld	s0,0(sp)
    80201dfc:	0141                	add	sp,sp,16
    80201dfe:	8082                	ret

0000000080201e00 <sys_wait>:

int sys_wait(void) {
    80201e00:	1101                	add	sp,sp,-32
    80201e02:	ec06                	sd	ra,24(sp)
    80201e04:	e822                	sd	s0,16(sp)
    80201e06:	1000                	add	s0,sp,32
    uint64 p;
    if(argaddr(0, &p) < 0)
    80201e08:	fe840593          	add	a1,s0,-24
    80201e0c:	4501                	li	a0,0
    80201e0e:	00000097          	auipc	ra,0x0
    80201e12:	e38080e7          	jalr	-456(ra) # 80201c46 <argaddr>
    80201e16:	00054c63          	bltz	a0,80201e2e <sys_wait+0x2e>
        return -1;
    return wait((int*)p);
    80201e1a:	fe843503          	ld	a0,-24(s0)
    80201e1e:	00000097          	auipc	ra,0x0
    80201e22:	990080e7          	jalr	-1648(ra) # 802017ae <wait>
}
    80201e26:	60e2                	ld	ra,24(sp)
    80201e28:	6442                	ld	s0,16(sp)
    80201e2a:	6105                	add	sp,sp,32
    80201e2c:	8082                	ret
        return -1;
    80201e2e:	557d                	li	a0,-1
    80201e30:	bfdd                	j	80201e26 <sys_wait+0x26>

0000000080201e32 <sys_kill>:

int sys_kill(void) {
    80201e32:	1101                	add	sp,sp,-32
    80201e34:	ec06                	sd	ra,24(sp)
    80201e36:	e822                	sd	s0,16(sp)
    80201e38:	1000                	add	s0,sp,32
    int pid;
    if(argint(0, &pid) < 0)
    80201e3a:	fec40593          	add	a1,s0,-20
    80201e3e:	4501                	li	a0,0
    80201e40:	00000097          	auipc	ra,0x0
    80201e44:	d7c080e7          	jalr	-644(ra) # 80201bbc <argint>
    80201e48:	00054a63          	bltz	a0,80201e5c <sys_kill+0x2a>
        return -1;
    printf("sys_kill not implemented\n");
    80201e4c:	00005517          	auipc	a0,0x5
    80201e50:	87450513          	add	a0,a0,-1932 # 802066c0 <syscalls+0x120>
    80201e54:	ffffe097          	auipc	ra,0xffffe
    80201e58:	300080e7          	jalr	768(ra) # 80200154 <printf>
    return -1; 
    80201e5c:	557d                	li	a0,-1
    80201e5e:	60e2                	ld	ra,24(sp)
    80201e60:	6442                	ld	s0,16(sp)
    80201e62:	6105                	add	sp,sp,32
    80201e64:	8082                	ret

0000000080201e66 <binit>:
    struct spinlock lock;
    struct buf buf[NBUF];
    struct buf head;
} bcache;

void binit(void) {
    80201e66:	7179                	add	sp,sp,-48
    80201e68:	f406                	sd	ra,40(sp)
    80201e6a:	f022                	sd	s0,32(sp)
    80201e6c:	ec26                	sd	s1,24(sp)
    80201e6e:	e84a                	sd	s2,16(sp)
    80201e70:	e44e                	sd	s3,8(sp)
    80201e72:	e052                	sd	s4,0(sp)
    80201e74:	1800                	add	s0,sp,48
    struct buf *b;

    spinlock_init(&bcache.lock, "bcache");
    80201e76:	00005597          	auipc	a1,0x5
    80201e7a:	86a58593          	add	a1,a1,-1942 # 802066e0 <syscalls+0x140>
    80201e7e:	0002d517          	auipc	a0,0x2d
    80201e82:	a2250513          	add	a0,a0,-1502 # 8022e8a0 <bcache>
    80201e86:	fffff097          	auipc	ra,0xfffff
    80201e8a:	952080e7          	jalr	-1710(ra) # 802007d8 <spinlock_init>
    bcache.head.prev = &bcache.head;
    80201e8e:	00035797          	auipc	a5,0x35
    80201e92:	a1278793          	add	a5,a5,-1518 # 802368a0 <bcache+0x8000>
    80201e96:	00035717          	auipc	a4,0x35
    80201e9a:	c7270713          	add	a4,a4,-910 # 80236b08 <bcache+0x8268>
    80201e9e:	2ae7b823          	sd	a4,688(a5)
    bcache.head.next = &bcache.head;
    80201ea2:	2ae7bc23          	sd	a4,696(a5)

    for (b = bcache.buf; b < bcache.buf + NBUF; b++) {
    80201ea6:	0002d497          	auipc	s1,0x2d
    80201eaa:	a1248493          	add	s1,s1,-1518 # 8022e8b8 <bcache+0x18>
        b->next = bcache.head.next;
    80201eae:	893e                	mv	s2,a5
        b->prev = &bcache.head;
    80201eb0:	89ba                	mv	s3,a4
        bcache.head.next->prev = b;
        bcache.head.next = b;
        initsleeplock(&b->lock, "buffer");
    80201eb2:	00005a17          	auipc	s4,0x5
    80201eb6:	836a0a13          	add	s4,s4,-1994 # 802066e8 <syscalls+0x148>
        b->next = bcache.head.next;
    80201eba:	2b893783          	ld	a5,696(s2)
    80201ebe:	e8bc                	sd	a5,80(s1)
        b->prev = &bcache.head;
    80201ec0:	0534b423          	sd	s3,72(s1)
        bcache.head.next->prev = b;
    80201ec4:	2b893783          	ld	a5,696(s2)
    80201ec8:	e7a4                	sd	s1,72(a5)
        bcache.head.next = b;
    80201eca:	2a993c23          	sd	s1,696(s2)
        initsleeplock(&b->lock, "buffer");
    80201ece:	85d2                	mv	a1,s4
    80201ed0:	01048513          	add	a0,s1,16
    80201ed4:	00002097          	auipc	ra,0x2
    80201ed8:	93e080e7          	jalr	-1730(ra) # 80203812 <initsleeplock>
    for (b = bcache.buf; b < bcache.buf + NBUF; b++) {
    80201edc:	45848493          	add	s1,s1,1112
    80201ee0:	fd349de3          	bne	s1,s3,80201eba <binit+0x54>
    }
}
    80201ee4:	70a2                	ld	ra,40(sp)
    80201ee6:	7402                	ld	s0,32(sp)
    80201ee8:	64e2                	ld	s1,24(sp)
    80201eea:	6942                	ld	s2,16(sp)
    80201eec:	69a2                	ld	s3,8(sp)
    80201eee:	6a02                	ld	s4,0(sp)
    80201ef0:	6145                	add	sp,sp,48
    80201ef2:	8082                	ret

0000000080201ef4 <bread>:

    panic("bget: no buffers");
    return 0;
}

struct buf *bread(uint dev, uint blockno) {
    80201ef4:	7179                	add	sp,sp,-48
    80201ef6:	f406                	sd	ra,40(sp)
    80201ef8:	f022                	sd	s0,32(sp)
    80201efa:	ec26                	sd	s1,24(sp)
    80201efc:	e84a                	sd	s2,16(sp)
    80201efe:	e44e                	sd	s3,8(sp)
    80201f00:	1800                	add	s0,sp,48
    80201f02:	892a                	mv	s2,a0
    80201f04:	89ae                	mv	s3,a1
    acquire(&bcache.lock);
    80201f06:	0002d517          	auipc	a0,0x2d
    80201f0a:	99a50513          	add	a0,a0,-1638 # 8022e8a0 <bcache>
    80201f0e:	fffff097          	auipc	ra,0xfffff
    80201f12:	92c080e7          	jalr	-1748(ra) # 8020083a <acquire>
    for (b = bcache.head.next; b != &bcache.head; b = b->next) {
    80201f16:	00035497          	auipc	s1,0x35
    80201f1a:	c424b483          	ld	s1,-958(s1) # 80236b58 <bcache+0x82b8>
    80201f1e:	00035797          	auipc	a5,0x35
    80201f22:	bea78793          	add	a5,a5,-1046 # 80236b08 <bcache+0x8268>
    80201f26:	04f48663          	beq	s1,a5,80201f72 <bread+0x7e>
    80201f2a:	873e                	mv	a4,a5
    80201f2c:	a021                	j	80201f34 <bread+0x40>
    80201f2e:	68a4                	ld	s1,80(s1)
    80201f30:	04e48163          	beq	s1,a4,80201f72 <bread+0x7e>
        if (b->dev == dev && b->blockno == blockno) {
    80201f34:	449c                	lw	a5,8(s1)
    80201f36:	ff279ce3          	bne	a5,s2,80201f2e <bread+0x3a>
    80201f3a:	44dc                	lw	a5,12(s1)
    80201f3c:	ff3799e3          	bne	a5,s3,80201f2e <bread+0x3a>
            b->refcnt++;
    80201f40:	40bc                	lw	a5,64(s1)
    80201f42:	2785                	addw	a5,a5,1
    80201f44:	c0bc                	sw	a5,64(s1)
            cache_hits++;
    80201f46:	0000e717          	auipc	a4,0xe
    80201f4a:	0da70713          	add	a4,a4,218 # 80210020 <cache_hits>
    80201f4e:	631c                	ld	a5,0(a4)
    80201f50:	0785                	add	a5,a5,1
    80201f52:	e31c                	sd	a5,0(a4)
            release(&bcache.lock);
    80201f54:	0002d517          	auipc	a0,0x2d
    80201f58:	94c50513          	add	a0,a0,-1716 # 8022e8a0 <bcache>
    80201f5c:	fffff097          	auipc	ra,0xfffff
    80201f60:	9d0080e7          	jalr	-1584(ra) # 8020092c <release>
            acquiresleep(&b->lock);
    80201f64:	01048513          	add	a0,s1,16
    80201f68:	00002097          	auipc	ra,0x2
    80201f6c:	8e4080e7          	jalr	-1820(ra) # 8020384c <acquiresleep>
            return b;
    80201f70:	a815                	j	80201fa4 <bread+0xb0>
    for (b = bcache.head.prev; b != &bcache.head; b = b->prev) {
    80201f72:	00035497          	auipc	s1,0x35
    80201f76:	bde4b483          	ld	s1,-1058(s1) # 80236b50 <bcache+0x82b0>
    80201f7a:	00035797          	auipc	a5,0x35
    80201f7e:	b8e78793          	add	a5,a5,-1138 # 80236b08 <bcache+0x8268>
    80201f82:	00f48863          	beq	s1,a5,80201f92 <bread+0x9e>
    80201f86:	873e                	mv	a4,a5
        if (b->refcnt == 0) {
    80201f88:	40bc                	lw	a5,64(s1)
    80201f8a:	c79d                	beqz	a5,80201fb8 <bread+0xc4>
    for (b = bcache.head.prev; b != &bcache.head; b = b->prev) {
    80201f8c:	64a4                	ld	s1,72(s1)
    80201f8e:	fee49de3          	bne	s1,a4,80201f88 <bread+0x94>
    panic("bget: no buffers");
    80201f92:	00004517          	auipc	a0,0x4
    80201f96:	75e50513          	add	a0,a0,1886 # 802066f0 <syscalls+0x150>
    80201f9a:	ffffe097          	auipc	ra,0xffffe
    80201f9e:	43a080e7          	jalr	1082(ra) # 802003d4 <panic>
    return 0;
    80201fa2:	4481                	li	s1,0
    struct buf *b = bget(dev, blockno);
    if (!b->valid) {
    80201fa4:	409c                	lw	a5,0(s1)
    80201fa6:	c7b9                	beqz	a5,80201ff4 <bread+0x100>
        virtio_disk_rw(b, 0);
        b->valid = 1;
    }
    return b;
}
    80201fa8:	8526                	mv	a0,s1
    80201faa:	70a2                	ld	ra,40(sp)
    80201fac:	7402                	ld	s0,32(sp)
    80201fae:	64e2                	ld	s1,24(sp)
    80201fb0:	6942                	ld	s2,16(sp)
    80201fb2:	69a2                	ld	s3,8(sp)
    80201fb4:	6145                	add	sp,sp,48
    80201fb6:	8082                	ret
            b->dev = dev;
    80201fb8:	0124a423          	sw	s2,8(s1)
            b->blockno = blockno;
    80201fbc:	0134a623          	sw	s3,12(s1)
            b->valid = 0;
    80201fc0:	0004a023          	sw	zero,0(s1)
            b->refcnt = 1;
    80201fc4:	4785                	li	a5,1
    80201fc6:	c0bc                	sw	a5,64(s1)
            cache_misses++;
    80201fc8:	0000e717          	auipc	a4,0xe
    80201fcc:	05070713          	add	a4,a4,80 # 80210018 <cache_misses>
    80201fd0:	631c                	ld	a5,0(a4)
    80201fd2:	0785                	add	a5,a5,1
    80201fd4:	e31c                	sd	a5,0(a4)
            release(&bcache.lock);
    80201fd6:	0002d517          	auipc	a0,0x2d
    80201fda:	8ca50513          	add	a0,a0,-1846 # 8022e8a0 <bcache>
    80201fde:	fffff097          	auipc	ra,0xfffff
    80201fe2:	94e080e7          	jalr	-1714(ra) # 8020092c <release>
            acquiresleep(&b->lock);
    80201fe6:	01048513          	add	a0,s1,16
    80201fea:	00002097          	auipc	ra,0x2
    80201fee:	862080e7          	jalr	-1950(ra) # 8020384c <acquiresleep>
            return b;
    80201ff2:	bf4d                	j	80201fa4 <bread+0xb0>
        virtio_disk_rw(b, 0);
    80201ff4:	4581                	li	a1,0
    80201ff6:	8526                	mv	a0,s1
    80201ff8:	00003097          	auipc	ra,0x3
    80201ffc:	c0e080e7          	jalr	-1010(ra) # 80204c06 <virtio_disk_rw>
        b->valid = 1;
    80202000:	4785                	li	a5,1
    80202002:	c09c                	sw	a5,0(s1)
    return b;
    80202004:	b755                	j	80201fa8 <bread+0xb4>

0000000080202006 <bwrite>:

void bwrite(struct buf *b) {
    80202006:	1101                	add	sp,sp,-32
    80202008:	ec06                	sd	ra,24(sp)
    8020200a:	e822                	sd	s0,16(sp)
    8020200c:	e426                	sd	s1,8(sp)
    8020200e:	1000                	add	s0,sp,32
    80202010:	84aa                	mv	s1,a0
    if (!holdingsleep(&b->lock)) {
    80202012:	0541                	add	a0,a0,16
    80202014:	00002097          	auipc	ra,0x2
    80202018:	8d0080e7          	jalr	-1840(ra) # 802038e4 <holdingsleep>
    8020201c:	cd01                	beqz	a0,80202034 <bwrite+0x2e>
        panic("bwrite");
    }
    virtio_disk_rw(b, 1);
    8020201e:	4585                	li	a1,1
    80202020:	8526                	mv	a0,s1
    80202022:	00003097          	auipc	ra,0x3
    80202026:	be4080e7          	jalr	-1052(ra) # 80204c06 <virtio_disk_rw>
}
    8020202a:	60e2                	ld	ra,24(sp)
    8020202c:	6442                	ld	s0,16(sp)
    8020202e:	64a2                	ld	s1,8(sp)
    80202030:	6105                	add	sp,sp,32
    80202032:	8082                	ret
        panic("bwrite");
    80202034:	00004517          	auipc	a0,0x4
    80202038:	6d450513          	add	a0,a0,1748 # 80206708 <syscalls+0x168>
    8020203c:	ffffe097          	auipc	ra,0xffffe
    80202040:	398080e7          	jalr	920(ra) # 802003d4 <panic>
    80202044:	bfe9                	j	8020201e <bwrite+0x18>

0000000080202046 <brelse>:

void brelse(struct buf *b) {
    80202046:	1101                	add	sp,sp,-32
    80202048:	ec06                	sd	ra,24(sp)
    8020204a:	e822                	sd	s0,16(sp)
    8020204c:	e426                	sd	s1,8(sp)
    8020204e:	e04a                	sd	s2,0(sp)
    80202050:	1000                	add	s0,sp,32
    80202052:	84aa                	mv	s1,a0
    if (!holdingsleep(&b->lock)) {
    80202054:	01050913          	add	s2,a0,16
    80202058:	854a                	mv	a0,s2
    8020205a:	00002097          	auipc	ra,0x2
    8020205e:	88a080e7          	jalr	-1910(ra) # 802038e4 <holdingsleep>
    80202062:	c925                	beqz	a0,802020d2 <brelse+0x8c>
        panic("brelse");
    }

    releasesleep(&b->lock);
    80202064:	854a                	mv	a0,s2
    80202066:	00002097          	auipc	ra,0x2
    8020206a:	83a080e7          	jalr	-1990(ra) # 802038a0 <releasesleep>

    acquire(&bcache.lock);
    8020206e:	0002d517          	auipc	a0,0x2d
    80202072:	83250513          	add	a0,a0,-1998 # 8022e8a0 <bcache>
    80202076:	ffffe097          	auipc	ra,0xffffe
    8020207a:	7c4080e7          	jalr	1988(ra) # 8020083a <acquire>
    b->refcnt--;
    8020207e:	40bc                	lw	a5,64(s1)
    80202080:	37fd                	addw	a5,a5,-1
    80202082:	0007871b          	sext.w	a4,a5
    80202086:	c0bc                	sw	a5,64(s1)
    if (b->refcnt == 0) {
    80202088:	e71d                	bnez	a4,802020b6 <brelse+0x70>
        b->next->prev = b->prev;
    8020208a:	68b8                	ld	a4,80(s1)
    8020208c:	64bc                	ld	a5,72(s1)
    8020208e:	e73c                	sd	a5,72(a4)
        b->prev->next = b->next;
    80202090:	68b8                	ld	a4,80(s1)
    80202092:	ebb8                	sd	a4,80(a5)
        b->next = bcache.head.next;
    80202094:	00035797          	auipc	a5,0x35
    80202098:	80c78793          	add	a5,a5,-2036 # 802368a0 <bcache+0x8000>
    8020209c:	2b87b703          	ld	a4,696(a5)
    802020a0:	e8b8                	sd	a4,80(s1)
        b->prev = &bcache.head;
    802020a2:	00035717          	auipc	a4,0x35
    802020a6:	a6670713          	add	a4,a4,-1434 # 80236b08 <bcache+0x8268>
    802020aa:	e4b8                	sd	a4,72(s1)
        bcache.head.next->prev = b;
    802020ac:	2b87b703          	ld	a4,696(a5)
    802020b0:	e724                	sd	s1,72(a4)
        bcache.head.next = b;
    802020b2:	2a97bc23          	sd	s1,696(a5)
    }
    release(&bcache.lock);
    802020b6:	0002c517          	auipc	a0,0x2c
    802020ba:	7ea50513          	add	a0,a0,2026 # 8022e8a0 <bcache>
    802020be:	fffff097          	auipc	ra,0xfffff
    802020c2:	86e080e7          	jalr	-1938(ra) # 8020092c <release>
}
    802020c6:	60e2                	ld	ra,24(sp)
    802020c8:	6442                	ld	s0,16(sp)
    802020ca:	64a2                	ld	s1,8(sp)
    802020cc:	6902                	ld	s2,0(sp)
    802020ce:	6105                	add	sp,sp,32
    802020d0:	8082                	ret
        panic("brelse");
    802020d2:	00004517          	auipc	a0,0x4
    802020d6:	63e50513          	add	a0,a0,1598 # 80206710 <syscalls+0x170>
    802020da:	ffffe097          	auipc	ra,0xffffe
    802020de:	2fa080e7          	jalr	762(ra) # 802003d4 <panic>
    802020e2:	b749                	j	80202064 <brelse+0x1e>

00000000802020e4 <bpin>:

void bpin(struct buf *b) {
    802020e4:	1101                	add	sp,sp,-32
    802020e6:	ec06                	sd	ra,24(sp)
    802020e8:	e822                	sd	s0,16(sp)
    802020ea:	e426                	sd	s1,8(sp)
    802020ec:	1000                	add	s0,sp,32
    802020ee:	84aa                	mv	s1,a0
    acquire(&bcache.lock);
    802020f0:	0002c517          	auipc	a0,0x2c
    802020f4:	7b050513          	add	a0,a0,1968 # 8022e8a0 <bcache>
    802020f8:	ffffe097          	auipc	ra,0xffffe
    802020fc:	742080e7          	jalr	1858(ra) # 8020083a <acquire>
    b->refcnt++;
    80202100:	40bc                	lw	a5,64(s1)
    80202102:	2785                	addw	a5,a5,1
    80202104:	c0bc                	sw	a5,64(s1)
    release(&bcache.lock);
    80202106:	0002c517          	auipc	a0,0x2c
    8020210a:	79a50513          	add	a0,a0,1946 # 8022e8a0 <bcache>
    8020210e:	fffff097          	auipc	ra,0xfffff
    80202112:	81e080e7          	jalr	-2018(ra) # 8020092c <release>
}
    80202116:	60e2                	ld	ra,24(sp)
    80202118:	6442                	ld	s0,16(sp)
    8020211a:	64a2                	ld	s1,8(sp)
    8020211c:	6105                	add	sp,sp,32
    8020211e:	8082                	ret

0000000080202120 <bunpin>:

void bunpin(struct buf *b) {
    80202120:	1101                	add	sp,sp,-32
    80202122:	ec06                	sd	ra,24(sp)
    80202124:	e822                	sd	s0,16(sp)
    80202126:	e426                	sd	s1,8(sp)
    80202128:	1000                	add	s0,sp,32
    8020212a:	84aa                	mv	s1,a0
    acquire(&bcache.lock);
    8020212c:	0002c517          	auipc	a0,0x2c
    80202130:	77450513          	add	a0,a0,1908 # 8022e8a0 <bcache>
    80202134:	ffffe097          	auipc	ra,0xffffe
    80202138:	706080e7          	jalr	1798(ra) # 8020083a <acquire>
    b->refcnt--;
    8020213c:	40bc                	lw	a5,64(s1)
    8020213e:	37fd                	addw	a5,a5,-1
    80202140:	c0bc                	sw	a5,64(s1)
    release(&bcache.lock);
    80202142:	0002c517          	auipc	a0,0x2c
    80202146:	75e50513          	add	a0,a0,1886 # 8022e8a0 <bcache>
    8020214a:	ffffe097          	auipc	ra,0xffffe
    8020214e:	7e2080e7          	jalr	2018(ra) # 8020092c <release>
}
    80202152:	60e2                	ld	ra,24(sp)
    80202154:	6442                	ld	s0,16(sp)
    80202156:	64a2                	ld	s1,8(sp)
    80202158:	6105                	add	sp,sp,32
    8020215a:	8082                	ret

000000008020215c <get_buffer_cache_hits>:

uint64 get_buffer_cache_hits(void) {
    8020215c:	1141                	add	sp,sp,-16
    8020215e:	e422                	sd	s0,8(sp)
    80202160:	0800                	add	s0,sp,16
    return cache_hits;
}
    80202162:	0000e517          	auipc	a0,0xe
    80202166:	ebe53503          	ld	a0,-322(a0) # 80210020 <cache_hits>
    8020216a:	6422                	ld	s0,8(sp)
    8020216c:	0141                	add	sp,sp,16
    8020216e:	8082                	ret

0000000080202170 <get_buffer_cache_misses>:

uint64 get_buffer_cache_misses(void) {
    80202170:	1141                	add	sp,sp,-16
    80202172:	e422                	sd	s0,8(sp)
    80202174:	0800                	add	s0,sp,16
    return cache_misses;
}
    80202176:	0000e517          	auipc	a0,0xe
    8020217a:	ea253503          	ld	a0,-350(a0) # 80210018 <cache_misses>
    8020217e:	6422                	ld	s0,8(sp)
    80202180:	0141                	add	sp,sp,16
    80202182:	8082                	ret

0000000080202184 <bitmap_set>:
    }
    release(&icache.lock);
}

// 仅供 fs_format 使用的辅助函数，格式化时无并发，可直接 bwrite
static void bitmap_set(int dev, uint blockno) {
    80202184:	1101                	add	sp,sp,-32
    80202186:	ec06                	sd	ra,24(sp)
    80202188:	e822                	sd	s0,16(sp)
    8020218a:	e426                	sd	s1,8(sp)
    8020218c:	e04a                	sd	s2,0(sp)
    8020218e:	1000                	add	s0,sp,32
    80202190:	84ae                	mv	s1,a1
    struct buf *bp = bread(dev, BBLOCK(blockno, sb));
    80202192:	00d5d59b          	srlw	a1,a1,0xd
    80202196:	00035797          	auipc	a5,0x35
    8020219a:	de67a783          	lw	a5,-538(a5) # 80236f7c <sb+0x1c>
    8020219e:	9dbd                	addw	a1,a1,a5
    802021a0:	00000097          	auipc	ra,0x0
    802021a4:	d54080e7          	jalr	-684(ra) # 80201ef4 <bread>
    802021a8:	892a                	mv	s2,a0
    uint bi = blockno % BPB;
    802021aa:	03349793          	sll	a5,s1,0x33
    bp->data[bi / 8] |= 1 << (bi % 8);
    802021ae:	93d9                	srl	a5,a5,0x36
    802021b0:	97aa                	add	a5,a5,a0
    802021b2:	889d                	and	s1,s1,7
    802021b4:	4685                	li	a3,1
    802021b6:	009696bb          	sllw	a3,a3,s1
    802021ba:	0587c703          	lbu	a4,88(a5)
    802021be:	8f55                	or	a4,a4,a3
    802021c0:	04e78c23          	sb	a4,88(a5)
    bwrite(bp);
    802021c4:	00000097          	auipc	ra,0x0
    802021c8:	e42080e7          	jalr	-446(ra) # 80202006 <bwrite>
    brelse(bp);
    802021cc:	854a                	mv	a0,s2
    802021ce:	00000097          	auipc	ra,0x0
    802021d2:	e78080e7          	jalr	-392(ra) # 80202046 <brelse>
}
    802021d6:	60e2                	ld	ra,24(sp)
    802021d8:	6442                	ld	s0,16(sp)
    802021da:	64a2                	ld	s1,8(sp)
    802021dc:	6902                	ld	s2,0(sp)
    802021de:	6105                	add	sp,sp,32
    802021e0:	8082                	ret

00000000802021e2 <readsb>:
static void readsb(int dev, struct superblock *sb) {
    802021e2:	1101                	add	sp,sp,-32
    802021e4:	ec06                	sd	ra,24(sp)
    802021e6:	e822                	sd	s0,16(sp)
    802021e8:	e426                	sd	s1,8(sp)
    802021ea:	e04a                	sd	s2,0(sp)
    802021ec:	1000                	add	s0,sp,32
    802021ee:	892e                	mv	s2,a1
    struct buf *bp = bread(dev, 1);
    802021f0:	4585                	li	a1,1
    802021f2:	00000097          	auipc	ra,0x0
    802021f6:	d02080e7          	jalr	-766(ra) # 80201ef4 <bread>
    802021fa:	84aa                	mv	s1,a0
    memmove(sb, bp->data, sizeof(*sb));
    802021fc:	02000613          	li	a2,32
    80202200:	05850593          	add	a1,a0,88
    80202204:	854a                	mv	a0,s2
    80202206:	ffffe097          	auipc	ra,0xffffe
    8020220a:	7be080e7          	jalr	1982(ra) # 802009c4 <memmove>
    brelse(bp);
    8020220e:	8526                	mv	a0,s1
    80202210:	00000097          	auipc	ra,0x0
    80202214:	e36080e7          	jalr	-458(ra) # 80202046 <brelse>
}
    80202218:	60e2                	ld	ra,24(sp)
    8020221a:	6442                	ld	s0,16(sp)
    8020221c:	64a2                	ld	s1,8(sp)
    8020221e:	6902                	ld	s2,0(sp)
    80202220:	6105                	add	sp,sp,32
    80202222:	8082                	ret

0000000080202224 <bfree>:
static void bfree(int dev, uint b) {
    80202224:	7179                	add	sp,sp,-48
    80202226:	f406                	sd	ra,40(sp)
    80202228:	f022                	sd	s0,32(sp)
    8020222a:	ec26                	sd	s1,24(sp)
    8020222c:	e84a                	sd	s2,16(sp)
    8020222e:	e44e                	sd	s3,8(sp)
    80202230:	e052                	sd	s4,0(sp)
    80202232:	1800                	add	s0,sp,48
    80202234:	84ae                	mv	s1,a1
    struct buf *bp = bread(dev, BBLOCK(b, sb));
    80202236:	00d5d59b          	srlw	a1,a1,0xd
    8020223a:	00035797          	auipc	a5,0x35
    8020223e:	d427a783          	lw	a5,-702(a5) # 80236f7c <sb+0x1c>
    80202242:	9dbd                	addw	a1,a1,a5
    80202244:	00000097          	auipc	ra,0x0
    80202248:	cb0080e7          	jalr	-848(ra) # 80201ef4 <bread>
    8020224c:	892a                	mv	s2,a0
    int m = 1 << (bi % 8);
    8020224e:	0074f793          	and	a5,s1,7
    80202252:	4a05                	li	s4,1
    80202254:	00fa1a3b          	sllw	s4,s4,a5
    uint bi = b % BPB;
    80202258:	14ce                	sll	s1,s1,0x33
    if ((bp->data[bi / 8] & m) == 0) {
    8020225a:	0364d993          	srl	s3,s1,0x36
    8020225e:	013504b3          	add	s1,a0,s3
    80202262:	0584c783          	lbu	a5,88(s1)
    80202266:	00fa77b3          	and	a5,s4,a5
    8020226a:	cf9d                	beqz	a5,802022a8 <bfree+0x84>
    bp->data[bi / 8] &= ~m;
    8020226c:	02099793          	sll	a5,s3,0x20
    80202270:	9381                	srl	a5,a5,0x20
    80202272:	97ca                	add	a5,a5,s2
    80202274:	fffa4a13          	not	s4,s4
    80202278:	0587c703          	lbu	a4,88(a5)
    8020227c:	01477733          	and	a4,a4,s4
    80202280:	04e78c23          	sb	a4,88(a5)
    log_write(bp); // [恢复] 使用 log_write
    80202284:	854a                	mv	a0,s2
    80202286:	00001097          	auipc	ra,0x1
    8020228a:	49c080e7          	jalr	1180(ra) # 80203722 <log_write>
    brelse(bp);
    8020228e:	854a                	mv	a0,s2
    80202290:	00000097          	auipc	ra,0x0
    80202294:	db6080e7          	jalr	-586(ra) # 80202046 <brelse>
}
    80202298:	70a2                	ld	ra,40(sp)
    8020229a:	7402                	ld	s0,32(sp)
    8020229c:	64e2                	ld	s1,24(sp)
    8020229e:	6942                	ld	s2,16(sp)
    802022a0:	69a2                	ld	s3,8(sp)
    802022a2:	6a02                	ld	s4,0(sp)
    802022a4:	6145                	add	sp,sp,48
    802022a6:	8082                	ret
        panic("bfree: freeing free block");
    802022a8:	00004517          	auipc	a0,0x4
    802022ac:	47050513          	add	a0,a0,1136 # 80206718 <syscalls+0x178>
    802022b0:	ffffe097          	auipc	ra,0xffffe
    802022b4:	124080e7          	jalr	292(ra) # 802003d4 <panic>
    802022b8:	bf55                	j	8020226c <bfree+0x48>

00000000802022ba <balloc>:
static uint balloc(uint dev) {
    802022ba:	711d                	add	sp,sp,-96
    802022bc:	ec86                	sd	ra,88(sp)
    802022be:	e8a2                	sd	s0,80(sp)
    802022c0:	e4a6                	sd	s1,72(sp)
    802022c2:	e0ca                	sd	s2,64(sp)
    802022c4:	fc4e                	sd	s3,56(sp)
    802022c6:	f852                	sd	s4,48(sp)
    802022c8:	f456                	sd	s5,40(sp)
    802022ca:	f05a                	sd	s6,32(sp)
    802022cc:	ec5e                	sd	s7,24(sp)
    802022ce:	e862                	sd	s8,16(sp)
    802022d0:	e466                	sd	s9,8(sp)
    802022d2:	e06a                	sd	s10,0(sp)
    802022d4:	1080                	add	s0,sp,96
    return sb.bmapstart + ((sb.nblocks + BPB - 1) / BPB);
    802022d6:	00035797          	auipc	a5,0x35
    802022da:	c8a78793          	add	a5,a5,-886 # 80236f60 <sb>
    802022de:	4798                	lw	a4,8(a5)
    802022e0:	6909                	lui	s2,0x2
    802022e2:	397d                	addw	s2,s2,-1 # 1fff <_start-0x801fe001>
    802022e4:	00e9093b          	addw	s2,s2,a4
    802022e8:	00d9591b          	srlw	s2,s2,0xd
    802022ec:	4fd8                	lw	a4,28(a5)
    802022ee:	00e9093b          	addw	s2,s2,a4
    for (b = 0; b < sb.size; b += BPB) {
    802022f2:	43dc                	lw	a5,4(a5)
    802022f4:	c7f5                	beqz	a5,802023e0 <balloc+0x126>
    802022f6:	8c2a                	mv	s8,a0
    802022f8:	4b01                	li	s6,0
        bp = bread(dev, BBLOCK(b, sb));
    802022fa:	00035b97          	auipc	s7,0x35
    802022fe:	c66b8b93          	add	s7,s7,-922 # 80236f60 <sb>
        for (uint bi = 0; bi < BPB && b + bi < sb.size; bi++) {
    80202302:	4c81                	li	s9,0
            int m = 1 << (bi % 8);
    80202304:	4a85                	li	s5,1
        for (uint bi = 0; bi < BPB && b + bi < sb.size; bi++) {
    80202306:	6a09                	lui	s4,0x2
    for (b = 0; b < sb.size; b += BPB) {
    80202308:	6d09                	lui	s10,0x2
    8020230a:	a85d                	j	802023c0 <balloc+0x106>
        for (uint bi = 0; bi < BPB && b + bi < sb.size; bi++) {
    8020230c:	2785                	addw	a5,a5,1
    8020230e:	2485                	addw	s1,s1,1
    80202310:	09478d63          	beq	a5,s4,802023aa <balloc+0xf0>
    80202314:	08b4fb63          	bgeu	s1,a1,802023aa <balloc+0xf0>
            if (blockno < start)
    80202318:	ff24eae3          	bltu	s1,s2,8020230c <balloc+0x52>
            int m = 1 << (bi % 8);
    8020231c:	0077f713          	and	a4,a5,7
    80202320:	00ea973b          	sllw	a4,s5,a4
            if ((bp->data[bi / 8] & m) == 0) {
    80202324:	0037d51b          	srlw	a0,a5,0x3
    80202328:	0037d69b          	srlw	a3,a5,0x3
    8020232c:	96ce                	add	a3,a3,s3
    8020232e:	0586c683          	lbu	a3,88(a3)
    80202332:	00d77633          	and	a2,a4,a3
    80202336:	fa79                	bnez	a2,8020230c <balloc+0x52>
                bp->data[bi / 8] |= m;
    80202338:	1502                	sll	a0,a0,0x20
    8020233a:	9101                	srl	a0,a0,0x20
    8020233c:	954e                	add	a0,a0,s3
    8020233e:	8ed9                	or	a3,a3,a4
    80202340:	04d50c23          	sb	a3,88(a0)
                log_write(bp); // [恢复] 使用 log_write
    80202344:	854e                	mv	a0,s3
    80202346:	00001097          	auipc	ra,0x1
    8020234a:	3dc080e7          	jalr	988(ra) # 80203722 <log_write>
                brelse(bp);
    8020234e:	854e                	mv	a0,s3
    80202350:	00000097          	auipc	ra,0x0
    80202354:	cf6080e7          	jalr	-778(ra) # 80202046 <brelse>
    struct buf *bp = bread(dev, bno);
    80202358:	85a6                	mv	a1,s1
    8020235a:	8562                	mv	a0,s8
    8020235c:	00000097          	auipc	ra,0x0
    80202360:	b98080e7          	jalr	-1128(ra) # 80201ef4 <bread>
    80202364:	892a                	mv	s2,a0
    memset(bp->data, 0, BSIZE);
    80202366:	40000613          	li	a2,1024
    8020236a:	4581                	li	a1,0
    8020236c:	05850513          	add	a0,a0,88
    80202370:	ffffe097          	auipc	ra,0xffffe
    80202374:	632080e7          	jalr	1586(ra) # 802009a2 <memset>
    log_write(bp); // [恢复] 使用 log_write 保证事务原子性
    80202378:	854a                	mv	a0,s2
    8020237a:	00001097          	auipc	ra,0x1
    8020237e:	3a8080e7          	jalr	936(ra) # 80203722 <log_write>
    brelse(bp);
    80202382:	854a                	mv	a0,s2
    80202384:	00000097          	auipc	ra,0x0
    80202388:	cc2080e7          	jalr	-830(ra) # 80202046 <brelse>
}
    8020238c:	8526                	mv	a0,s1
    8020238e:	60e6                	ld	ra,88(sp)
    80202390:	6446                	ld	s0,80(sp)
    80202392:	64a6                	ld	s1,72(sp)
    80202394:	6906                	ld	s2,64(sp)
    80202396:	79e2                	ld	s3,56(sp)
    80202398:	7a42                	ld	s4,48(sp)
    8020239a:	7aa2                	ld	s5,40(sp)
    8020239c:	7b02                	ld	s6,32(sp)
    8020239e:	6be2                	ld	s7,24(sp)
    802023a0:	6c42                	ld	s8,16(sp)
    802023a2:	6ca2                	ld	s9,8(sp)
    802023a4:	6d02                	ld	s10,0(sp)
    802023a6:	6125                	add	sp,sp,96
    802023a8:	8082                	ret
        brelse(bp);
    802023aa:	854e                	mv	a0,s3
    802023ac:	00000097          	auipc	ra,0x0
    802023b0:	c9a080e7          	jalr	-870(ra) # 80202046 <brelse>
    for (b = 0; b < sb.size; b += BPB) {
    802023b4:	016d0b3b          	addw	s6,s10,s6
    802023b8:	004ba783          	lw	a5,4(s7)
    802023bc:	02fb7263          	bgeu	s6,a5,802023e0 <balloc+0x126>
        bp = bread(dev, BBLOCK(b, sb));
    802023c0:	00db559b          	srlw	a1,s6,0xd
    802023c4:	01cba783          	lw	a5,28(s7)
    802023c8:	9dbd                	addw	a1,a1,a5
    802023ca:	8562                	mv	a0,s8
    802023cc:	00000097          	auipc	ra,0x0
    802023d0:	b28080e7          	jalr	-1240(ra) # 80201ef4 <bread>
    802023d4:	89aa                	mv	s3,a0
        for (uint bi = 0; bi < BPB && b + bi < sb.size; bi++) {
    802023d6:	004ba583          	lw	a1,4(s7)
    802023da:	84da                	mv	s1,s6
    802023dc:	87e6                	mv	a5,s9
    802023de:	bf1d                	j	80202314 <balloc+0x5a>
    panic("balloc: out of blocks");
    802023e0:	00004517          	auipc	a0,0x4
    802023e4:	35850513          	add	a0,a0,856 # 80206738 <syscalls+0x198>
    802023e8:	ffffe097          	auipc	ra,0xffffe
    802023ec:	fec080e7          	jalr	-20(ra) # 802003d4 <panic>
    return 0;
    802023f0:	4481                	li	s1,0
    802023f2:	bf69                	j	8020238c <balloc+0xd2>

00000000802023f4 <bmap>:
static uint bmap(struct inode *ip, uint bn) {
    802023f4:	7179                	add	sp,sp,-48
    802023f6:	f406                	sd	ra,40(sp)
    802023f8:	f022                	sd	s0,32(sp)
    802023fa:	ec26                	sd	s1,24(sp)
    802023fc:	e84a                	sd	s2,16(sp)
    802023fe:	e44e                	sd	s3,8(sp)
    80202400:	e052                	sd	s4,0(sp)
    80202402:	1800                	add	s0,sp,48
    80202404:	892a                	mv	s2,a0
    if (bn < NDIRECT) {
    80202406:	47ad                	li	a5,11
    80202408:	04b7fe63          	bgeu	a5,a1,80202464 <bmap+0x70>
    bn -= NDIRECT;
    8020240c:	ff45849b          	addw	s1,a1,-12
    80202410:	0004871b          	sext.w	a4,s1
    if (bn < NINDIRECT) {
    80202414:	0ff00793          	li	a5,255
    80202418:	0ae7e163          	bltu	a5,a4,802024ba <bmap+0xc6>
        if ((addr = ip->addrs[NDIRECT]) == 0)
    8020241c:	08052583          	lw	a1,128(a0)
    80202420:	c5b5                	beqz	a1,8020248c <bmap+0x98>
        bp = bread(ip->dev, addr);
    80202422:	00092503          	lw	a0,0(s2)
    80202426:	00000097          	auipc	ra,0x0
    8020242a:	ace080e7          	jalr	-1330(ra) # 80201ef4 <bread>
    8020242e:	8a2a                	mv	s4,a0
        uint *a = (uint*)bp->data;
    80202430:	05850793          	add	a5,a0,88
        if (a[bn] == 0) {
    80202434:	02049713          	sll	a4,s1,0x20
    80202438:	01e75593          	srl	a1,a4,0x1e
    8020243c:	00b784b3          	add	s1,a5,a1
    80202440:	409c                	lw	a5,0(s1)
    80202442:	cfb9                	beqz	a5,802024a0 <bmap+0xac>
        uint r = a[bn];
    80202444:	0004a983          	lw	s3,0(s1)
        brelse(bp);
    80202448:	8552                	mv	a0,s4
    8020244a:	00000097          	auipc	ra,0x0
    8020244e:	bfc080e7          	jalr	-1028(ra) # 80202046 <brelse>
}
    80202452:	854e                	mv	a0,s3
    80202454:	70a2                	ld	ra,40(sp)
    80202456:	7402                	ld	s0,32(sp)
    80202458:	64e2                	ld	s1,24(sp)
    8020245a:	6942                	ld	s2,16(sp)
    8020245c:	69a2                	ld	s3,8(sp)
    8020245e:	6a02                	ld	s4,0(sp)
    80202460:	6145                	add	sp,sp,48
    80202462:	8082                	ret
        if ((addr = ip->addrs[bn]) == 0)
    80202464:	02059793          	sll	a5,a1,0x20
    80202468:	01e7d593          	srl	a1,a5,0x1e
    8020246c:	00b504b3          	add	s1,a0,a1
    80202470:	0504a983          	lw	s3,80(s1)
    80202474:	fc099fe3          	bnez	s3,80202452 <bmap+0x5e>
            ip->addrs[bn] = addr = balloc(ip->dev);
    80202478:	4108                	lw	a0,0(a0)
    8020247a:	00000097          	auipc	ra,0x0
    8020247e:	e40080e7          	jalr	-448(ra) # 802022ba <balloc>
    80202482:	0005099b          	sext.w	s3,a0
    80202486:	0534a823          	sw	s3,80(s1)
    8020248a:	b7e1                	j	80202452 <bmap+0x5e>
            ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8020248c:	4108                	lw	a0,0(a0)
    8020248e:	00000097          	auipc	ra,0x0
    80202492:	e2c080e7          	jalr	-468(ra) # 802022ba <balloc>
    80202496:	0005059b          	sext.w	a1,a0
    8020249a:	08b92023          	sw	a1,128(s2)
    8020249e:	b751                	j	80202422 <bmap+0x2e>
            a[bn] = balloc(ip->dev);
    802024a0:	00092503          	lw	a0,0(s2)
    802024a4:	00000097          	auipc	ra,0x0
    802024a8:	e16080e7          	jalr	-490(ra) # 802022ba <balloc>
    802024ac:	c088                	sw	a0,0(s1)
            log_write(bp); // [恢复] 使用 log_write
    802024ae:	8552                	mv	a0,s4
    802024b0:	00001097          	auipc	ra,0x1
    802024b4:	272080e7          	jalr	626(ra) # 80203722 <log_write>
    802024b8:	b771                	j	80202444 <bmap+0x50>
    panic("bmap");
    802024ba:	00004517          	auipc	a0,0x4
    802024be:	29650513          	add	a0,a0,662 # 80206750 <syscalls+0x1b0>
    802024c2:	ffffe097          	auipc	ra,0xffffe
    802024c6:	f12080e7          	jalr	-238(ra) # 802003d4 <panic>
    return 0;
    802024ca:	4981                	li	s3,0
    802024cc:	b759                	j	80202452 <bmap+0x5e>

00000000802024ce <iinit>:
void iinit(void) {
    802024ce:	7139                	add	sp,sp,-64
    802024d0:	fc06                	sd	ra,56(sp)
    802024d2:	f822                	sd	s0,48(sp)
    802024d4:	f426                	sd	s1,40(sp)
    802024d6:	f04a                	sd	s2,32(sp)
    802024d8:	ec4e                	sd	s3,24(sp)
    802024da:	e852                	sd	s4,16(sp)
    802024dc:	e456                	sd	s5,8(sp)
    802024de:	0080                	add	s0,sp,64
    readsb(ROOTDEV, &sb);
    802024e0:	00035497          	auipc	s1,0x35
    802024e4:	a8048493          	add	s1,s1,-1408 # 80236f60 <sb>
    802024e8:	85a6                	mv	a1,s1
    802024ea:	4505                	li	a0,1
    802024ec:	00000097          	auipc	ra,0x0
    802024f0:	cf6080e7          	jalr	-778(ra) # 802021e2 <readsb>
    if (sb.magic != FSMAGIC) {
    802024f4:	4098                	lw	a4,0(s1)
    802024f6:	102037b7          	lui	a5,0x10203
    802024fa:	04078793          	add	a5,a5,64 # 10203040 <_start-0x6fffcfc0>
    802024fe:	06f71f63          	bne	a4,a5,8020257c <iinit+0xae>
    spinlock_init(&icache.lock, "icache");
    80202502:	00004597          	auipc	a1,0x4
    80202506:	28658593          	add	a1,a1,646 # 80206788 <syscalls+0x1e8>
    8020250a:	00035517          	auipc	a0,0x35
    8020250e:	a7650513          	add	a0,a0,-1418 # 80236f80 <icache>
    80202512:	ffffe097          	auipc	ra,0xffffe
    80202516:	2c6080e7          	jalr	710(ra) # 802007d8 <spinlock_init>
    for (int i = 0; i < NINODE; i++) {
    8020251a:	00035497          	auipc	s1,0x35
    8020251e:	a8e48493          	add	s1,s1,-1394 # 80236fa8 <icache+0x28>
    80202522:	0003f997          	auipc	s3,0x3f
    80202526:	9e698993          	add	s3,s3,-1562 # 80240f08 <log+0x10>
        initsleeplock(&icache.inode[i].lock, "inode");
    8020252a:	00004917          	auipc	s2,0x4
    8020252e:	26690913          	add	s2,s2,614 # 80206790 <syscalls+0x1f0>
        icache.inode[i].ref = 0;
    80202532:	fe04ac23          	sw	zero,-8(s1)
        initsleeplock(&icache.inode[i].lock, "inode");
    80202536:	85ca                	mv	a1,s2
    80202538:	8526                	mv	a0,s1
    8020253a:	00001097          	auipc	ra,0x1
    8020253e:	2d8080e7          	jalr	728(ra) # 80203812 <initsleeplock>
    for (int i = 0; i < NINODE; i++) {
    80202542:	08848493          	add	s1,s1,136
    80202546:	ff3496e3          	bne	s1,s3,80202532 <iinit+0x64>
    printf("fs: size=%d nblocks=%d ninodes=%d nlog=%d\n", sb.size, sb.nblocks, sb.ninodes, sb.nlog);
    8020254a:	00035797          	auipc	a5,0x35
    8020254e:	a1678793          	add	a5,a5,-1514 # 80236f60 <sb>
    80202552:	4b98                	lw	a4,16(a5)
    80202554:	47d4                	lw	a3,12(a5)
    80202556:	4790                	lw	a2,8(a5)
    80202558:	43cc                	lw	a1,4(a5)
    8020255a:	00004517          	auipc	a0,0x4
    8020255e:	23e50513          	add	a0,a0,574 # 80206798 <syscalls+0x1f8>
    80202562:	ffffe097          	auipc	ra,0xffffe
    80202566:	bf2080e7          	jalr	-1038(ra) # 80200154 <printf>
}
    8020256a:	70e2                	ld	ra,56(sp)
    8020256c:	7442                	ld	s0,48(sp)
    8020256e:	74a2                	ld	s1,40(sp)
    80202570:	7902                	ld	s2,32(sp)
    80202572:	69e2                	ld	s3,24(sp)
    80202574:	6a42                	ld	s4,16(sp)
    80202576:	6aa2                	ld	s5,8(sp)
    80202578:	6121                	add	sp,sp,64
    8020257a:	8082                	ret

static void fs_format(int dev) {
    printf("Formatting filesystem...\n");
    8020257c:	00004517          	auipc	a0,0x4
    80202580:	1dc50513          	add	a0,a0,476 # 80206758 <syscalls+0x1b8>
    80202584:	ffffe097          	auipc	ra,0xffffe
    80202588:	bd0080e7          	jalr	-1072(ra) # 80200154 <printf>
    memset(&sb, 0, sizeof(sb));
    8020258c:	02000613          	li	a2,32
    80202590:	4581                	li	a1,0
    80202592:	8526                	mv	a0,s1
    80202594:	ffffe097          	auipc	ra,0xffffe
    80202598:	40e080e7          	jalr	1038(ra) # 802009a2 <memset>
    sb.magic = FSMAGIC;
    8020259c:	102037b7          	lui	a5,0x10203
    802025a0:	04078793          	add	a5,a5,64 # 10203040 <_start-0x6fffcfc0>
    802025a4:	c09c                	sw	a5,0(s1)
    sb.size = FSSIZE;
    802025a6:	6785                	lui	a5,0x1
    802025a8:	c0dc                	sw	a5,4(s1)
    sb.ninodes = NINODE;
    802025aa:	12c00713          	li	a4,300
    802025ae:	c4d8                	sw	a4,12(s1)
    sb.nlog = LOGSIZE;
    802025b0:	4779                	li	a4,30
    802025b2:	c898                	sw	a4,16(s1)
    sb.logstart = 2;
    802025b4:	4709                	li	a4,2
    802025b6:	c8d8                	sw	a4,20(s1)
    sb.inodestart = sb.logstart + sb.nlog;
    802025b8:	02000713          	li	a4,32
    802025bc:	cc98                	sw	a4,24(s1)
    int inodeblocks = (sb.ninodes + IPB - 1) / IPB;
    sb.bmapstart = sb.inodestart + inodeblocks;
    802025be:	03300713          	li	a4,51
    802025c2:	ccd8                	sw	a4,28(s1)
    uint bitmapblocks = 1; // temporary
    sb.nblocks = sb.size - (sb.bmapstart + bitmapblocks);
    802025c4:	fcc78793          	add	a5,a5,-52 # fcc <_start-0x801ff034>
    802025c8:	c49c                	sw	a5,8(s1)
    bitmapblocks = (sb.nblocks + BPB - 1) / BPB;
    sb.nblocks = sb.size - (sb.bmapstart + bitmapblocks);

    for (uint b = 0; b < sb.size; b++) {
    802025ca:	4901                	li	s2,0
    802025cc:	89a6                	mv	s3,s1
        struct buf *bp = bread(dev, b);
    802025ce:	85ca                	mv	a1,s2
    802025d0:	4505                	li	a0,1
    802025d2:	00000097          	auipc	ra,0x0
    802025d6:	922080e7          	jalr	-1758(ra) # 80201ef4 <bread>
    802025da:	84aa                	mv	s1,a0
        memset(bp->data, 0, BSIZE);
    802025dc:	40000613          	li	a2,1024
    802025e0:	4581                	li	a1,0
    802025e2:	05850513          	add	a0,a0,88
    802025e6:	ffffe097          	auipc	ra,0xffffe
    802025ea:	3bc080e7          	jalr	956(ra) # 802009a2 <memset>
        bwrite(bp);
    802025ee:	8526                	mv	a0,s1
    802025f0:	00000097          	auipc	ra,0x0
    802025f4:	a16080e7          	jalr	-1514(ra) # 80202006 <bwrite>
        brelse(bp);
    802025f8:	8526                	mv	a0,s1
    802025fa:	00000097          	auipc	ra,0x0
    802025fe:	a4c080e7          	jalr	-1460(ra) # 80202046 <brelse>
    for (uint b = 0; b < sb.size; b++) {
    80202602:	2905                	addw	s2,s2,1
    80202604:	0049a783          	lw	a5,4(s3)
    80202608:	fcf963e3          	bltu	s2,a5,802025ce <iinit+0x100>
    }

    struct buf *bp = bread(dev, 1);
    8020260c:	4585                	li	a1,1
    8020260e:	4505                	li	a0,1
    80202610:	00000097          	auipc	ra,0x0
    80202614:	8e4080e7          	jalr	-1820(ra) # 80201ef4 <bread>
    80202618:	84aa                	mv	s1,a0
    memmove(bp->data, &sb, sizeof(sb));
    8020261a:	00035917          	auipc	s2,0x35
    8020261e:	94690913          	add	s2,s2,-1722 # 80236f60 <sb>
    80202622:	02000613          	li	a2,32
    80202626:	85ca                	mv	a1,s2
    80202628:	05850513          	add	a0,a0,88
    8020262c:	ffffe097          	auipc	ra,0xffffe
    80202630:	398080e7          	jalr	920(ra) # 802009c4 <memmove>
    bwrite(bp);
    80202634:	8526                	mv	a0,s1
    80202636:	00000097          	auipc	ra,0x0
    8020263a:	9d0080e7          	jalr	-1584(ra) # 80202006 <bwrite>
    brelse(bp);
    8020263e:	8526                	mv	a0,s1
    80202640:	00000097          	auipc	ra,0x0
    80202644:	a06080e7          	jalr	-1530(ra) # 80202046 <brelse>
    return sb.bmapstart + ((sb.nblocks + BPB - 1) / BPB);
    80202648:	00892783          	lw	a5,8(s2)
    8020264c:	6989                	lui	s3,0x2
    8020264e:	39fd                	addw	s3,s3,-1 # 1fff <_start-0x801fe001>
    80202650:	00f989bb          	addw	s3,s3,a5
    80202654:	00d9d99b          	srlw	s3,s3,0xd
    80202658:	01c92783          	lw	a5,28(s2)
    8020265c:	00f989bb          	addw	s3,s3,a5
    80202660:	0009891b          	sext.w	s2,s3

    uint start = data_start_block();
    for (uint b = 0; b < start; b++)
    80202664:	00090c63          	beqz	s2,8020267c <iinit+0x1ae>
    80202668:	4481                	li	s1,0
        bitmap_set(dev, b);
    8020266a:	85a6                	mv	a1,s1
    8020266c:	4505                	li	a0,1
    8020266e:	00000097          	auipc	ra,0x0
    80202672:	b16080e7          	jalr	-1258(ra) # 80202184 <bitmap_set>
    for (uint b = 0; b < start; b++)
    80202676:	2485                	addw	s1,s1,1
    80202678:	fe9919e3          	bne	s2,s1,8020266a <iinit+0x19c>

    uint root_block = start;
    bitmap_set(dev, root_block);
    8020267c:	85ca                	mv	a1,s2
    8020267e:	4505                	li	a0,1
    80202680:	00000097          	auipc	ra,0x0
    80202684:	b04080e7          	jalr	-1276(ra) # 80202184 <bitmap_set>

    struct buf *ib = bread(dev, IBLOCK(ROOTINO, sb));
    80202688:	00035a97          	auipc	s5,0x35
    8020268c:	8d8a8a93          	add	s5,s5,-1832 # 80236f60 <sb>
    80202690:	018aa583          	lw	a1,24(s5)
    80202694:	4505                	li	a0,1
    80202696:	00000097          	auipc	ra,0x0
    8020269a:	85e080e7          	jalr	-1954(ra) # 80201ef4 <bread>
    8020269e:	84aa                	mv	s1,a0
    struct dinode *dip = (struct dinode*)ib->data + ROOTINO % IPB;
    memset(dip, 0, sizeof(*dip));
    802026a0:	04000613          	li	a2,64
    802026a4:	4581                	li	a1,0
    802026a6:	09850513          	add	a0,a0,152
    802026aa:	ffffe097          	auipc	ra,0xffffe
    802026ae:	2f8080e7          	jalr	760(ra) # 802009a2 <memset>
    dip->type = T_DIR;
    802026b2:	4a05                	li	s4,1
    802026b4:	09449c23          	sh	s4,152(s1)
    dip->nlink = 2;
    802026b8:	4789                	li	a5,2
    802026ba:	08f49f23          	sh	a5,158(s1)
    dip->size = sizeof(struct dirent) * 2;
    802026be:	02000793          	li	a5,32
    802026c2:	0af4a023          	sw	a5,160(s1)
    dip->addrs[0] = root_block;
    802026c6:	0b34a223          	sw	s3,164(s1)
    bwrite(ib);
    802026ca:	8526                	mv	a0,s1
    802026cc:	00000097          	auipc	ra,0x0
    802026d0:	93a080e7          	jalr	-1734(ra) # 80202006 <bwrite>
    brelse(ib);
    802026d4:	8526                	mv	a0,s1
    802026d6:	00000097          	auipc	ra,0x0
    802026da:	970080e7          	jalr	-1680(ra) # 80202046 <brelse>

    struct buf *db = bread(dev, root_block);
    802026de:	85ca                	mv	a1,s2
    802026e0:	4505                	li	a0,1
    802026e2:	00000097          	auipc	ra,0x0
    802026e6:	812080e7          	jalr	-2030(ra) # 80201ef4 <bread>
    802026ea:	84aa                	mv	s1,a0
    struct dirent *de = (struct dirent*)db->data;
    memset(de, 0, BSIZE);
    802026ec:	40000613          	li	a2,1024
    802026f0:	4581                	li	a1,0
    802026f2:	05850513          	add	a0,a0,88
    802026f6:	ffffe097          	auipc	ra,0xffffe
    802026fa:	2ac080e7          	jalr	684(ra) # 802009a2 <memset>
    de[0].inum = ROOTINO;
    802026fe:	05449c23          	sh	s4,88(s1)
    safestrcpy(de[0].name, ".", DIRSIZ);
    80202702:	4639                	li	a2,14
    80202704:	00004597          	auipc	a1,0x4
    80202708:	07458593          	add	a1,a1,116 # 80206778 <syscalls+0x1d8>
    8020270c:	05a48513          	add	a0,s1,90
    80202710:	ffffe097          	auipc	ra,0xffffe
    80202714:	3dc080e7          	jalr	988(ra) # 80200aec <safestrcpy>
    de[1].inum = ROOTINO;
    80202718:	07449423          	sh	s4,104(s1)
    safestrcpy(de[1].name, "..", DIRSIZ);
    8020271c:	4639                	li	a2,14
    8020271e:	00004597          	auipc	a1,0x4
    80202722:	06258593          	add	a1,a1,98 # 80206780 <syscalls+0x1e0>
    80202726:	06a48513          	add	a0,s1,106
    8020272a:	ffffe097          	auipc	ra,0xffffe
    8020272e:	3c2080e7          	jalr	962(ra) # 80200aec <safestrcpy>
    bwrite(db);
    80202732:	8526                	mv	a0,s1
    80202734:	00000097          	auipc	ra,0x0
    80202738:	8d2080e7          	jalr	-1838(ra) # 80202006 <bwrite>
    brelse(db);
    8020273c:	8526                	mv	a0,s1
    8020273e:	00000097          	auipc	ra,0x0
    80202742:	908080e7          	jalr	-1784(ra) # 80202046 <brelse>
        readsb(ROOTDEV, &sb);
    80202746:	85d6                	mv	a1,s5
    80202748:	4505                	li	a0,1
    8020274a:	00000097          	auipc	ra,0x0
    8020274e:	a98080e7          	jalr	-1384(ra) # 802021e2 <readsb>
    80202752:	bb45                	j	80202502 <iinit+0x34>

0000000080202754 <iget>:
struct inode *iget(uint dev, uint inum) {
    80202754:	7179                	add	sp,sp,-48
    80202756:	f406                	sd	ra,40(sp)
    80202758:	f022                	sd	s0,32(sp)
    8020275a:	ec26                	sd	s1,24(sp)
    8020275c:	e84a                	sd	s2,16(sp)
    8020275e:	e44e                	sd	s3,8(sp)
    80202760:	e052                	sd	s4,0(sp)
    80202762:	1800                	add	s0,sp,48
    80202764:	89aa                	mv	s3,a0
    80202766:	8a2e                	mv	s4,a1
    acquire(&icache.lock);
    80202768:	00035517          	auipc	a0,0x35
    8020276c:	81850513          	add	a0,a0,-2024 # 80236f80 <icache>
    80202770:	ffffe097          	auipc	ra,0xffffe
    80202774:	0ca080e7          	jalr	202(ra) # 8020083a <acquire>
    struct inode *ip, *empty = 0;
    80202778:	4901                	li	s2,0
    for (ip = icache.inode; ip < &icache.inode[NINODE]; ip++) {
    8020277a:	00035497          	auipc	s1,0x35
    8020277e:	81e48493          	add	s1,s1,-2018 # 80236f98 <icache+0x18>
    80202782:	0003e697          	auipc	a3,0x3e
    80202786:	77668693          	add	a3,a3,1910 # 80240ef8 <log>
    8020278a:	a039                	j	80202798 <iget+0x44>
        if (empty == 0 && ip->ref == 0)
    8020278c:	04090263          	beqz	s2,802027d0 <iget+0x7c>
    for (ip = icache.inode; ip < &icache.inode[NINODE]; ip++) {
    80202790:	08848493          	add	s1,s1,136
    80202794:	04d48163          	beq	s1,a3,802027d6 <iget+0x82>
        if (ip->ref > 0 && ip->dev == dev && ip->inum == inum) {
    80202798:	449c                	lw	a5,8(s1)
    8020279a:	fef059e3          	blez	a5,8020278c <iget+0x38>
    8020279e:	4098                	lw	a4,0(s1)
    802027a0:	ff3716e3          	bne	a4,s3,8020278c <iget+0x38>
    802027a4:	40d8                	lw	a4,4(s1)
    802027a6:	ff4713e3          	bne	a4,s4,8020278c <iget+0x38>
            ip->ref++;
    802027aa:	2785                	addw	a5,a5,1
    802027ac:	c49c                	sw	a5,8(s1)
            release(&icache.lock);
    802027ae:	00034517          	auipc	a0,0x34
    802027b2:	7d250513          	add	a0,a0,2002 # 80236f80 <icache>
    802027b6:	ffffe097          	auipc	ra,0xffffe
    802027ba:	176080e7          	jalr	374(ra) # 8020092c <release>
}
    802027be:	8526                	mv	a0,s1
    802027c0:	70a2                	ld	ra,40(sp)
    802027c2:	7402                	ld	s0,32(sp)
    802027c4:	64e2                	ld	s1,24(sp)
    802027c6:	6942                	ld	s2,16(sp)
    802027c8:	69a2                	ld	s3,8(sp)
    802027ca:	6a02                	ld	s4,0(sp)
    802027cc:	6145                	add	sp,sp,48
    802027ce:	8082                	ret
        if (empty == 0 && ip->ref == 0)
    802027d0:	f3e1                	bnez	a5,80202790 <iget+0x3c>
    802027d2:	8926                	mv	s2,s1
    802027d4:	bf75                	j	80202790 <iget+0x3c>
    if (empty == 0)
    802027d6:	02090563          	beqz	s2,80202800 <iget+0xac>
    ip->dev = dev;
    802027da:	01392023          	sw	s3,0(s2)
    ip->inum = inum;
    802027de:	01492223          	sw	s4,4(s2)
    ip->ref = 1;
    802027e2:	4785                	li	a5,1
    802027e4:	00f92423          	sw	a5,8(s2)
    ip->valid = 0;
    802027e8:	04092023          	sw	zero,64(s2)
    release(&icache.lock);
    802027ec:	00034517          	auipc	a0,0x34
    802027f0:	79450513          	add	a0,a0,1940 # 80236f80 <icache>
    802027f4:	ffffe097          	auipc	ra,0xffffe
    802027f8:	138080e7          	jalr	312(ra) # 8020092c <release>
    return ip;
    802027fc:	84ca                	mv	s1,s2
    802027fe:	b7c1                	j	802027be <iget+0x6a>
        panic("iget: no inodes");
    80202800:	00004517          	auipc	a0,0x4
    80202804:	fc850513          	add	a0,a0,-56 # 802067c8 <syscalls+0x228>
    80202808:	ffffe097          	auipc	ra,0xffffe
    8020280c:	bcc080e7          	jalr	-1076(ra) # 802003d4 <panic>
    80202810:	b7e9                	j	802027da <iget+0x86>

0000000080202812 <ialloc>:
struct inode *ialloc(uint dev, short type) {
    80202812:	7139                	add	sp,sp,-64
    80202814:	fc06                	sd	ra,56(sp)
    80202816:	f822                	sd	s0,48(sp)
    80202818:	f426                	sd	s1,40(sp)
    8020281a:	f04a                	sd	s2,32(sp)
    8020281c:	ec4e                	sd	s3,24(sp)
    8020281e:	e852                	sd	s4,16(sp)
    80202820:	e456                	sd	s5,8(sp)
    80202822:	e05a                	sd	s6,0(sp)
    80202824:	0080                	add	s0,sp,64
    for (uint inum = 1; inum < sb.ninodes; inum++) {
    80202826:	00034717          	auipc	a4,0x34
    8020282a:	74672703          	lw	a4,1862(a4) # 80236f6c <sb+0xc>
    8020282e:	4785                	li	a5,1
    80202830:	04e7f663          	bgeu	a5,a4,8020287c <ialloc+0x6a>
    80202834:	8aaa                	mv	s5,a0
    80202836:	8b2e                	mv	s6,a1
    80202838:	4905                	li	s2,1
        struct buf *bp = bread(dev, IBLOCK(inum, sb));
    8020283a:	00034a17          	auipc	s4,0x34
    8020283e:	726a0a13          	add	s4,s4,1830 # 80236f60 <sb>
    80202842:	0049559b          	srlw	a1,s2,0x4
    80202846:	018a2783          	lw	a5,24(s4)
    8020284a:	9dbd                	addw	a1,a1,a5
    8020284c:	8556                	mv	a0,s5
    8020284e:	fffff097          	auipc	ra,0xfffff
    80202852:	6a6080e7          	jalr	1702(ra) # 80201ef4 <bread>
    80202856:	84aa                	mv	s1,a0
        struct dinode *dip = (struct dinode*)bp->data + inum % IPB;
    80202858:	05850993          	add	s3,a0,88
    8020285c:	00f97793          	and	a5,s2,15
    80202860:	079a                	sll	a5,a5,0x6
    80202862:	99be                	add	s3,s3,a5
        if (dip->type == 0) {
    80202864:	00099783          	lh	a5,0(s3)
    80202868:	cf8d                	beqz	a5,802028a2 <ialloc+0x90>
        brelse(bp);
    8020286a:	fffff097          	auipc	ra,0xfffff
    8020286e:	7dc080e7          	jalr	2012(ra) # 80202046 <brelse>
    for (uint inum = 1; inum < sb.ninodes; inum++) {
    80202872:	2905                	addw	s2,s2,1
    80202874:	00ca2783          	lw	a5,12(s4)
    80202878:	fcf965e3          	bltu	s2,a5,80202842 <ialloc+0x30>
    panic("ialloc");
    8020287c:	00004517          	auipc	a0,0x4
    80202880:	0bc50513          	add	a0,a0,188 # 80206938 <syscalls+0x398>
    80202884:	ffffe097          	auipc	ra,0xffffe
    80202888:	b50080e7          	jalr	-1200(ra) # 802003d4 <panic>
    return 0;
    8020288c:	4501                	li	a0,0
}
    8020288e:	70e2                	ld	ra,56(sp)
    80202890:	7442                	ld	s0,48(sp)
    80202892:	74a2                	ld	s1,40(sp)
    80202894:	7902                	ld	s2,32(sp)
    80202896:	69e2                	ld	s3,24(sp)
    80202898:	6a42                	ld	s4,16(sp)
    8020289a:	6aa2                	ld	s5,8(sp)
    8020289c:	6b02                	ld	s6,0(sp)
    8020289e:	6121                	add	sp,sp,64
    802028a0:	8082                	ret
            memset(dip, 0, sizeof(*dip));
    802028a2:	04000613          	li	a2,64
    802028a6:	4581                	li	a1,0
    802028a8:	854e                	mv	a0,s3
    802028aa:	ffffe097          	auipc	ra,0xffffe
    802028ae:	0f8080e7          	jalr	248(ra) # 802009a2 <memset>
            dip->type = type;
    802028b2:	01699023          	sh	s6,0(s3)
            log_write(bp); // [恢复] 使用 log_write
    802028b6:	8526                	mv	a0,s1
    802028b8:	00001097          	auipc	ra,0x1
    802028bc:	e6a080e7          	jalr	-406(ra) # 80203722 <log_write>
            brelse(bp);
    802028c0:	8526                	mv	a0,s1
    802028c2:	fffff097          	auipc	ra,0xfffff
    802028c6:	784080e7          	jalr	1924(ra) # 80202046 <brelse>
            return iget(dev, inum);
    802028ca:	85ca                	mv	a1,s2
    802028cc:	8556                	mv	a0,s5
    802028ce:	00000097          	auipc	ra,0x0
    802028d2:	e86080e7          	jalr	-378(ra) # 80202754 <iget>
    802028d6:	bf65                	j	8020288e <ialloc+0x7c>

00000000802028d8 <idup>:
struct inode *idup(struct inode *ip) {
    802028d8:	1101                	add	sp,sp,-32
    802028da:	ec06                	sd	ra,24(sp)
    802028dc:	e822                	sd	s0,16(sp)
    802028de:	e426                	sd	s1,8(sp)
    802028e0:	1000                	add	s0,sp,32
    802028e2:	84aa                	mv	s1,a0
    acquire(&icache.lock);
    802028e4:	00034517          	auipc	a0,0x34
    802028e8:	69c50513          	add	a0,a0,1692 # 80236f80 <icache>
    802028ec:	ffffe097          	auipc	ra,0xffffe
    802028f0:	f4e080e7          	jalr	-178(ra) # 8020083a <acquire>
    ip->ref++;
    802028f4:	449c                	lw	a5,8(s1)
    802028f6:	2785                	addw	a5,a5,1
    802028f8:	c49c                	sw	a5,8(s1)
    release(&icache.lock);
    802028fa:	00034517          	auipc	a0,0x34
    802028fe:	68650513          	add	a0,a0,1670 # 80236f80 <icache>
    80202902:	ffffe097          	auipc	ra,0xffffe
    80202906:	02a080e7          	jalr	42(ra) # 8020092c <release>
}
    8020290a:	8526                	mv	a0,s1
    8020290c:	60e2                	ld	ra,24(sp)
    8020290e:	6442                	ld	s0,16(sp)
    80202910:	64a2                	ld	s1,8(sp)
    80202912:	6105                	add	sp,sp,32
    80202914:	8082                	ret

0000000080202916 <ilock>:
void ilock(struct inode *ip) {
    80202916:	1101                	add	sp,sp,-32
    80202918:	ec06                	sd	ra,24(sp)
    8020291a:	e822                	sd	s0,16(sp)
    8020291c:	e426                	sd	s1,8(sp)
    8020291e:	e04a                	sd	s2,0(sp)
    80202920:	1000                	add	s0,sp,32
    80202922:	84aa                	mv	s1,a0
    if (ip == 0 || ip->ref < 1)
    80202924:	c501                	beqz	a0,8020292c <ilock+0x16>
    80202926:	451c                	lw	a5,8(a0)
    80202928:	00f04a63          	bgtz	a5,8020293c <ilock+0x26>
        panic("ilock");
    8020292c:	00004517          	auipc	a0,0x4
    80202930:	eac50513          	add	a0,a0,-340 # 802067d8 <syscalls+0x238>
    80202934:	ffffe097          	auipc	ra,0xffffe
    80202938:	aa0080e7          	jalr	-1376(ra) # 802003d4 <panic>
    acquiresleep(&ip->lock);
    8020293c:	01048513          	add	a0,s1,16
    80202940:	00001097          	auipc	ra,0x1
    80202944:	f0c080e7          	jalr	-244(ra) # 8020384c <acquiresleep>
    if (ip->valid == 0) {
    80202948:	40bc                	lw	a5,64(s1)
    8020294a:	c799                	beqz	a5,80202958 <ilock+0x42>
}
    8020294c:	60e2                	ld	ra,24(sp)
    8020294e:	6442                	ld	s0,16(sp)
    80202950:	64a2                	ld	s1,8(sp)
    80202952:	6902                	ld	s2,0(sp)
    80202954:	6105                	add	sp,sp,32
    80202956:	8082                	ret
        struct buf *bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80202958:	40dc                	lw	a5,4(s1)
    8020295a:	0047d79b          	srlw	a5,a5,0x4
    8020295e:	00034597          	auipc	a1,0x34
    80202962:	61a5a583          	lw	a1,1562(a1) # 80236f78 <sb+0x18>
    80202966:	9dbd                	addw	a1,a1,a5
    80202968:	4088                	lw	a0,0(s1)
    8020296a:	fffff097          	auipc	ra,0xfffff
    8020296e:	58a080e7          	jalr	1418(ra) # 80201ef4 <bread>
    80202972:	892a                	mv	s2,a0
        struct dinode *dip = (struct dinode*)bp->data + ip->inum % IPB;
    80202974:	05850593          	add	a1,a0,88
    80202978:	40dc                	lw	a5,4(s1)
    8020297a:	8bbd                	and	a5,a5,15
    8020297c:	079a                	sll	a5,a5,0x6
    8020297e:	95be                	add	a1,a1,a5
        ip->type = dip->type;
    80202980:	00059783          	lh	a5,0(a1)
    80202984:	04f49223          	sh	a5,68(s1)
        ip->major = dip->major;
    80202988:	00259783          	lh	a5,2(a1)
    8020298c:	04f49323          	sh	a5,70(s1)
        ip->minor = dip->minor;
    80202990:	00459783          	lh	a5,4(a1)
    80202994:	04f49423          	sh	a5,72(s1)
        ip->nlink = dip->nlink;
    80202998:	00659783          	lh	a5,6(a1)
    8020299c:	04f49523          	sh	a5,74(s1)
        ip->size = dip->size;
    802029a0:	459c                	lw	a5,8(a1)
    802029a2:	c4fc                	sw	a5,76(s1)
        memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    802029a4:	03400613          	li	a2,52
    802029a8:	05b1                	add	a1,a1,12
    802029aa:	05048513          	add	a0,s1,80
    802029ae:	ffffe097          	auipc	ra,0xffffe
    802029b2:	016080e7          	jalr	22(ra) # 802009c4 <memmove>
        ip->valid = 1;
    802029b6:	4785                	li	a5,1
    802029b8:	c0bc                	sw	a5,64(s1)
        brelse(bp);
    802029ba:	854a                	mv	a0,s2
    802029bc:	fffff097          	auipc	ra,0xfffff
    802029c0:	68a080e7          	jalr	1674(ra) # 80202046 <brelse>
        if (ip->type == 0)
    802029c4:	04449783          	lh	a5,68(s1)
    802029c8:	f3d1                	bnez	a5,8020294c <ilock+0x36>
            panic("ilock: no type");
    802029ca:	00004517          	auipc	a0,0x4
    802029ce:	e1650513          	add	a0,a0,-490 # 802067e0 <syscalls+0x240>
    802029d2:	ffffe097          	auipc	ra,0xffffe
    802029d6:	a02080e7          	jalr	-1534(ra) # 802003d4 <panic>
}
    802029da:	bf8d                	j	8020294c <ilock+0x36>

00000000802029dc <iunlock>:
void iunlock(struct inode *ip) {
    802029dc:	1101                	add	sp,sp,-32
    802029de:	ec06                	sd	ra,24(sp)
    802029e0:	e822                	sd	s0,16(sp)
    802029e2:	e426                	sd	s1,8(sp)
    802029e4:	1000                	add	s0,sp,32
    802029e6:	84aa                	mv	s1,a0
    if (ip == 0 || !holdingsleep(&ip->lock))
    802029e8:	c519                	beqz	a0,802029f6 <iunlock+0x1a>
    802029ea:	0541                	add	a0,a0,16
    802029ec:	00001097          	auipc	ra,0x1
    802029f0:	ef8080e7          	jalr	-264(ra) # 802038e4 <holdingsleep>
    802029f4:	e909                	bnez	a0,80202a06 <iunlock+0x2a>
        panic("iunlock");
    802029f6:	00004517          	auipc	a0,0x4
    802029fa:	dfa50513          	add	a0,a0,-518 # 802067f0 <syscalls+0x250>
    802029fe:	ffffe097          	auipc	ra,0xffffe
    80202a02:	9d6080e7          	jalr	-1578(ra) # 802003d4 <panic>
    releasesleep(&ip->lock);
    80202a06:	01048513          	add	a0,s1,16
    80202a0a:	00001097          	auipc	ra,0x1
    80202a0e:	e96080e7          	jalr	-362(ra) # 802038a0 <releasesleep>
}
    80202a12:	60e2                	ld	ra,24(sp)
    80202a14:	6442                	ld	s0,16(sp)
    80202a16:	64a2                	ld	s1,8(sp)
    80202a18:	6105                	add	sp,sp,32
    80202a1a:	8082                	ret

0000000080202a1c <iupdate>:
void iupdate(struct inode *ip) {
    80202a1c:	1101                	add	sp,sp,-32
    80202a1e:	ec06                	sd	ra,24(sp)
    80202a20:	e822                	sd	s0,16(sp)
    80202a22:	e426                	sd	s1,8(sp)
    80202a24:	e04a                	sd	s2,0(sp)
    80202a26:	1000                	add	s0,sp,32
    80202a28:	84aa                	mv	s1,a0
    struct buf *bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80202a2a:	415c                	lw	a5,4(a0)
    80202a2c:	0047d79b          	srlw	a5,a5,0x4
    80202a30:	00034597          	auipc	a1,0x34
    80202a34:	5485a583          	lw	a1,1352(a1) # 80236f78 <sb+0x18>
    80202a38:	9dbd                	addw	a1,a1,a5
    80202a3a:	4108                	lw	a0,0(a0)
    80202a3c:	fffff097          	auipc	ra,0xfffff
    80202a40:	4b8080e7          	jalr	1208(ra) # 80201ef4 <bread>
    80202a44:	892a                	mv	s2,a0
    struct dinode *dip = (struct dinode*)bp->data + ip->inum % IPB;
    80202a46:	05850793          	add	a5,a0,88
    80202a4a:	40d8                	lw	a4,4(s1)
    80202a4c:	8b3d                	and	a4,a4,15
    80202a4e:	071a                	sll	a4,a4,0x6
    80202a50:	97ba                	add	a5,a5,a4
    dip->type = ip->type;
    80202a52:	04449703          	lh	a4,68(s1)
    80202a56:	00e79023          	sh	a4,0(a5)
    dip->major = ip->major;
    80202a5a:	04649703          	lh	a4,70(s1)
    80202a5e:	00e79123          	sh	a4,2(a5)
    dip->minor = ip->minor;
    80202a62:	04849703          	lh	a4,72(s1)
    80202a66:	00e79223          	sh	a4,4(a5)
    dip->nlink = ip->nlink;
    80202a6a:	04a49703          	lh	a4,74(s1)
    80202a6e:	00e79323          	sh	a4,6(a5)
    dip->size = ip->size;
    80202a72:	44f8                	lw	a4,76(s1)
    80202a74:	c798                	sw	a4,8(a5)
    memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80202a76:	03400613          	li	a2,52
    80202a7a:	05048593          	add	a1,s1,80
    80202a7e:	00c78513          	add	a0,a5,12
    80202a82:	ffffe097          	auipc	ra,0xffffe
    80202a86:	f42080e7          	jalr	-190(ra) # 802009c4 <memmove>
    log_write(bp); // [恢复] 使用 log_write
    80202a8a:	854a                	mv	a0,s2
    80202a8c:	00001097          	auipc	ra,0x1
    80202a90:	c96080e7          	jalr	-874(ra) # 80203722 <log_write>
    brelse(bp);
    80202a94:	854a                	mv	a0,s2
    80202a96:	fffff097          	auipc	ra,0xfffff
    80202a9a:	5b0080e7          	jalr	1456(ra) # 80202046 <brelse>
}
    80202a9e:	60e2                	ld	ra,24(sp)
    80202aa0:	6442                	ld	s0,16(sp)
    80202aa2:	64a2                	ld	s1,8(sp)
    80202aa4:	6902                	ld	s2,0(sp)
    80202aa6:	6105                	add	sp,sp,32
    80202aa8:	8082                	ret

0000000080202aaa <itrunc>:
void itrunc(struct inode *ip) {
    80202aaa:	7179                	add	sp,sp,-48
    80202aac:	f406                	sd	ra,40(sp)
    80202aae:	f022                	sd	s0,32(sp)
    80202ab0:	ec26                	sd	s1,24(sp)
    80202ab2:	e84a                	sd	s2,16(sp)
    80202ab4:	e44e                	sd	s3,8(sp)
    80202ab6:	e052                	sd	s4,0(sp)
    80202ab8:	1800                	add	s0,sp,48
    80202aba:	89aa                	mv	s3,a0
    for (int i = 0; i < NDIRECT; i++) {
    80202abc:	05050493          	add	s1,a0,80
    80202ac0:	08050913          	add	s2,a0,128
    80202ac4:	a021                	j	80202acc <itrunc+0x22>
    80202ac6:	0491                	add	s1,s1,4
    80202ac8:	01248d63          	beq	s1,s2,80202ae2 <itrunc+0x38>
        if (ip->addrs[i]) {
    80202acc:	408c                	lw	a1,0(s1)
    80202ace:	dde5                	beqz	a1,80202ac6 <itrunc+0x1c>
            bfree(ip->dev, ip->addrs[i]);
    80202ad0:	0009a503          	lw	a0,0(s3)
    80202ad4:	fffff097          	auipc	ra,0xfffff
    80202ad8:	750080e7          	jalr	1872(ra) # 80202224 <bfree>
            ip->addrs[i] = 0;
    80202adc:	0004a023          	sw	zero,0(s1)
    80202ae0:	b7dd                	j	80202ac6 <itrunc+0x1c>
    if (ip->addrs[NDIRECT]) {
    80202ae2:	0809a583          	lw	a1,128(s3)
    80202ae6:	e185                	bnez	a1,80202b06 <itrunc+0x5c>
    ip->size = 0;
    80202ae8:	0409a623          	sw	zero,76(s3)
    iupdate(ip);
    80202aec:	854e                	mv	a0,s3
    80202aee:	00000097          	auipc	ra,0x0
    80202af2:	f2e080e7          	jalr	-210(ra) # 80202a1c <iupdate>
}
    80202af6:	70a2                	ld	ra,40(sp)
    80202af8:	7402                	ld	s0,32(sp)
    80202afa:	64e2                	ld	s1,24(sp)
    80202afc:	6942                	ld	s2,16(sp)
    80202afe:	69a2                	ld	s3,8(sp)
    80202b00:	6a02                	ld	s4,0(sp)
    80202b02:	6145                	add	sp,sp,48
    80202b04:	8082                	ret
        struct buf *bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80202b06:	0009a503          	lw	a0,0(s3)
    80202b0a:	fffff097          	auipc	ra,0xfffff
    80202b0e:	3ea080e7          	jalr	1002(ra) # 80201ef4 <bread>
    80202b12:	8a2a                	mv	s4,a0
        for (int j = 0; j < NINDIRECT; j++) {
    80202b14:	05850493          	add	s1,a0,88
    80202b18:	45850913          	add	s2,a0,1112
    80202b1c:	a021                	j	80202b24 <itrunc+0x7a>
    80202b1e:	0491                	add	s1,s1,4
    80202b20:	01248b63          	beq	s1,s2,80202b36 <itrunc+0x8c>
            if (a[j])
    80202b24:	408c                	lw	a1,0(s1)
    80202b26:	dde5                	beqz	a1,80202b1e <itrunc+0x74>
                bfree(ip->dev, a[j]);
    80202b28:	0009a503          	lw	a0,0(s3)
    80202b2c:	fffff097          	auipc	ra,0xfffff
    80202b30:	6f8080e7          	jalr	1784(ra) # 80202224 <bfree>
    80202b34:	b7ed                	j	80202b1e <itrunc+0x74>
        brelse(bp);
    80202b36:	8552                	mv	a0,s4
    80202b38:	fffff097          	auipc	ra,0xfffff
    80202b3c:	50e080e7          	jalr	1294(ra) # 80202046 <brelse>
        bfree(ip->dev, ip->addrs[NDIRECT]);
    80202b40:	0809a583          	lw	a1,128(s3)
    80202b44:	0009a503          	lw	a0,0(s3)
    80202b48:	fffff097          	auipc	ra,0xfffff
    80202b4c:	6dc080e7          	jalr	1756(ra) # 80202224 <bfree>
        ip->addrs[NDIRECT] = 0;
    80202b50:	0809a023          	sw	zero,128(s3)
    80202b54:	bf51                	j	80202ae8 <itrunc+0x3e>

0000000080202b56 <iput>:
void iput(struct inode *ip) {
    80202b56:	1101                	add	sp,sp,-32
    80202b58:	ec06                	sd	ra,24(sp)
    80202b5a:	e822                	sd	s0,16(sp)
    80202b5c:	e426                	sd	s1,8(sp)
    80202b5e:	e04a                	sd	s2,0(sp)
    80202b60:	1000                	add	s0,sp,32
    80202b62:	84aa                	mv	s1,a0
    acquiresleep(&ip->lock);
    80202b64:	01050913          	add	s2,a0,16
    80202b68:	854a                	mv	a0,s2
    80202b6a:	00001097          	auipc	ra,0x1
    80202b6e:	ce2080e7          	jalr	-798(ra) # 8020384c <acquiresleep>
    if (ip->valid && ip->nlink == 0 && ip->ref == 1) {
    80202b72:	40bc                	lw	a5,64(s1)
    80202b74:	cb81                	beqz	a5,80202b84 <iput+0x2e>
    80202b76:	04a49783          	lh	a5,74(s1)
    80202b7a:	e789                	bnez	a5,80202b84 <iput+0x2e>
    80202b7c:	4498                	lw	a4,8(s1)
    80202b7e:	4785                	li	a5,1
    80202b80:	04f70063          	beq	a4,a5,80202bc0 <iput+0x6a>
    releasesleep(&ip->lock);
    80202b84:	854a                	mv	a0,s2
    80202b86:	00001097          	auipc	ra,0x1
    80202b8a:	d1a080e7          	jalr	-742(ra) # 802038a0 <releasesleep>
    acquire(&icache.lock);
    80202b8e:	00034517          	auipc	a0,0x34
    80202b92:	3f250513          	add	a0,a0,1010 # 80236f80 <icache>
    80202b96:	ffffe097          	auipc	ra,0xffffe
    80202b9a:	ca4080e7          	jalr	-860(ra) # 8020083a <acquire>
    ip->ref--;
    80202b9e:	449c                	lw	a5,8(s1)
    80202ba0:	37fd                	addw	a5,a5,-1
    80202ba2:	c49c                	sw	a5,8(s1)
    release(&icache.lock);
    80202ba4:	00034517          	auipc	a0,0x34
    80202ba8:	3dc50513          	add	a0,a0,988 # 80236f80 <icache>
    80202bac:	ffffe097          	auipc	ra,0xffffe
    80202bb0:	d80080e7          	jalr	-640(ra) # 8020092c <release>
}
    80202bb4:	60e2                	ld	ra,24(sp)
    80202bb6:	6442                	ld	s0,16(sp)
    80202bb8:	64a2                	ld	s1,8(sp)
    80202bba:	6902                	ld	s2,0(sp)
    80202bbc:	6105                	add	sp,sp,32
    80202bbe:	8082                	ret
        itrunc(ip);
    80202bc0:	8526                	mv	a0,s1
    80202bc2:	00000097          	auipc	ra,0x0
    80202bc6:	ee8080e7          	jalr	-280(ra) # 80202aaa <itrunc>
        ip->type = 0;
    80202bca:	04049223          	sh	zero,68(s1)
        iupdate(ip);
    80202bce:	8526                	mv	a0,s1
    80202bd0:	00000097          	auipc	ra,0x0
    80202bd4:	e4c080e7          	jalr	-436(ra) # 80202a1c <iupdate>
        ip->valid = 0;
    80202bd8:	0404a023          	sw	zero,64(s1)
    80202bdc:	b765                	j	80202b84 <iput+0x2e>

0000000080202bde <iunlockput>:
void iunlockput(struct inode *ip) {
    80202bde:	1101                	add	sp,sp,-32
    80202be0:	ec06                	sd	ra,24(sp)
    80202be2:	e822                	sd	s0,16(sp)
    80202be4:	e426                	sd	s1,8(sp)
    80202be6:	1000                	add	s0,sp,32
    80202be8:	84aa                	mv	s1,a0
    iunlock(ip);
    80202bea:	00000097          	auipc	ra,0x0
    80202bee:	df2080e7          	jalr	-526(ra) # 802029dc <iunlock>
    iput(ip);
    80202bf2:	8526                	mv	a0,s1
    80202bf4:	00000097          	auipc	ra,0x0
    80202bf8:	f62080e7          	jalr	-158(ra) # 80202b56 <iput>
}
    80202bfc:	60e2                	ld	ra,24(sp)
    80202bfe:	6442                	ld	s0,16(sp)
    80202c00:	64a2                	ld	s1,8(sp)
    80202c02:	6105                	add	sp,sp,32
    80202c04:	8082                	ret

0000000080202c06 <stati>:
int stati(struct inode *ip, struct stat *st) {
    80202c06:	1141                	add	sp,sp,-16
    80202c08:	e422                	sd	s0,8(sp)
    80202c0a:	0800                	add	s0,sp,16
    st->dev = ip->dev;
    80202c0c:	411c                	lw	a5,0(a0)
    80202c0e:	c1dc                	sw	a5,4(a1)
    st->ino = ip->inum;
    80202c10:	415c                	lw	a5,4(a0)
    80202c12:	c59c                	sw	a5,8(a1)
    st->type = ip->type;
    80202c14:	04451783          	lh	a5,68(a0)
    80202c18:	00f59023          	sh	a5,0(a1)
    st->nlink = ip->nlink;
    80202c1c:	04a51783          	lh	a5,74(a0)
    80202c20:	00f59623          	sh	a5,12(a1)
    st->size = ip->size;
    80202c24:	04c56783          	lwu	a5,76(a0)
    80202c28:	e99c                	sd	a5,16(a1)
}
    80202c2a:	4501                	li	a0,0
    80202c2c:	6422                	ld	s0,8(sp)
    80202c2e:	0141                	add	sp,sp,16
    80202c30:	8082                	ret

0000000080202c32 <readi>:
int readi(struct inode *ip, int user, uint64 dst, uint off, uint n) {
    80202c32:	715d                	add	sp,sp,-80
    80202c34:	e486                	sd	ra,72(sp)
    80202c36:	e0a2                	sd	s0,64(sp)
    80202c38:	fc26                	sd	s1,56(sp)
    80202c3a:	f84a                	sd	s2,48(sp)
    80202c3c:	f44e                	sd	s3,40(sp)
    80202c3e:	f052                	sd	s4,32(sp)
    80202c40:	ec56                	sd	s5,24(sp)
    80202c42:	e85a                	sd	s6,16(sp)
    80202c44:	e45e                	sd	s7,8(sp)
    80202c46:	e062                	sd	s8,0(sp)
    80202c48:	0880                	add	s0,sp,80
    80202c4a:	8baa                	mv	s7,a0
    80202c4c:	8ab2                	mv	s5,a2
    80202c4e:	8936                	mv	s2,a3
    80202c50:	8b3a                	mv	s6,a4
    if (user)
    80202c52:	e585                	bnez	a1,80202c7a <readi+0x48>
    if (off > ip->size || off + n < off)
    80202c54:	04cba783          	lw	a5,76(s7)
        return 0;
    80202c58:	4501                	li	a0,0
    if (off > ip->size || off + n < off)
    80202c5a:	0b27e163          	bltu	a5,s2,80202cfc <readi+0xca>
    80202c5e:	0169073b          	addw	a4,s2,s6
    80202c62:	09276d63          	bltu	a4,s2,80202cfc <readi+0xca>
    if (off + n > ip->size)
    80202c66:	00e7f463          	bgeu	a5,a4,80202c6e <readi+0x3c>
        n = ip->size - off;
    80202c6a:	41278b3b          	subw	s6,a5,s2
    for (tot = 0; tot < n; tot += m, off += m, dst += m) {
    80202c6e:	080b0563          	beqz	s6,80202cf8 <readi+0xc6>
    80202c72:	4a01                	li	s4,0
        m = MIN(n - tot, BSIZE - off % BSIZE);
    80202c74:	40000c13          	li	s8,1024
    80202c78:	a091                	j	80202cbc <readi+0x8a>
        panic("readi user");
    80202c7a:	00004517          	auipc	a0,0x4
    80202c7e:	b7e50513          	add	a0,a0,-1154 # 802067f8 <syscalls+0x258>
    80202c82:	ffffd097          	auipc	ra,0xffffd
    80202c86:	752080e7          	jalr	1874(ra) # 802003d4 <panic>
    80202c8a:	b7e9                	j	80202c54 <readi+0x22>
        memmove((void*)dst, bp->data + off % BSIZE, m);
    80202c8c:	05898593          	add	a1,s3,88
    80202c90:	0004861b          	sext.w	a2,s1
    80202c94:	95ba                	add	a1,a1,a4
    80202c96:	8556                	mv	a0,s5
    80202c98:	ffffe097          	auipc	ra,0xffffe
    80202c9c:	d2c080e7          	jalr	-724(ra) # 802009c4 <memmove>
        brelse(bp);
    80202ca0:	854e                	mv	a0,s3
    80202ca2:	fffff097          	auipc	ra,0xfffff
    80202ca6:	3a4080e7          	jalr	932(ra) # 80202046 <brelse>
    for (tot = 0; tot < n; tot += m, off += m, dst += m) {
    80202caa:	01448a3b          	addw	s4,s1,s4
    80202cae:	0124893b          	addw	s2,s1,s2
    80202cb2:	1482                	sll	s1,s1,0x20
    80202cb4:	9081                	srl	s1,s1,0x20
    80202cb6:	9aa6                	add	s5,s5,s1
    80202cb8:	056a7063          	bgeu	s4,s6,80202cf8 <readi+0xc6>
        uint addr = bmap(ip, off / BSIZE);
    80202cbc:	00a9559b          	srlw	a1,s2,0xa
    80202cc0:	855e                	mv	a0,s7
    80202cc2:	fffff097          	auipc	ra,0xfffff
    80202cc6:	732080e7          	jalr	1842(ra) # 802023f4 <bmap>
        bp = bread(ip->dev, addr);
    80202cca:	0005059b          	sext.w	a1,a0
    80202cce:	000ba503          	lw	a0,0(s7)
    80202cd2:	fffff097          	auipc	ra,0xfffff
    80202cd6:	222080e7          	jalr	546(ra) # 80201ef4 <bread>
    80202cda:	89aa                	mv	s3,a0
        m = MIN(n - tot, BSIZE - off % BSIZE);
    80202cdc:	3ff97713          	and	a4,s2,1023
    80202ce0:	40ec07bb          	subw	a5,s8,a4
    80202ce4:	414b06bb          	subw	a3,s6,s4
    80202ce8:	84be                	mv	s1,a5
    80202cea:	2781                	sext.w	a5,a5
    80202cec:	0006861b          	sext.w	a2,a3
    80202cf0:	f8f67ee3          	bgeu	a2,a5,80202c8c <readi+0x5a>
    80202cf4:	84b6                	mv	s1,a3
    80202cf6:	bf59                	j	80202c8c <readi+0x5a>
    return n;
    80202cf8:	000b051b          	sext.w	a0,s6
}
    80202cfc:	60a6                	ld	ra,72(sp)
    80202cfe:	6406                	ld	s0,64(sp)
    80202d00:	74e2                	ld	s1,56(sp)
    80202d02:	7942                	ld	s2,48(sp)
    80202d04:	79a2                	ld	s3,40(sp)
    80202d06:	7a02                	ld	s4,32(sp)
    80202d08:	6ae2                	ld	s5,24(sp)
    80202d0a:	6b42                	ld	s6,16(sp)
    80202d0c:	6ba2                	ld	s7,8(sp)
    80202d0e:	6c02                	ld	s8,0(sp)
    80202d10:	6161                	add	sp,sp,80
    80202d12:	8082                	ret

0000000080202d14 <writei>:
int writei(struct inode *ip, int user, uint64 src, uint off, uint n) {
    80202d14:	7159                	add	sp,sp,-112
    80202d16:	f486                	sd	ra,104(sp)
    80202d18:	f0a2                	sd	s0,96(sp)
    80202d1a:	eca6                	sd	s1,88(sp)
    80202d1c:	e8ca                	sd	s2,80(sp)
    80202d1e:	e4ce                	sd	s3,72(sp)
    80202d20:	e0d2                	sd	s4,64(sp)
    80202d22:	fc56                	sd	s5,56(sp)
    80202d24:	f85a                	sd	s6,48(sp)
    80202d26:	f45e                	sd	s7,40(sp)
    80202d28:	f062                	sd	s8,32(sp)
    80202d2a:	ec66                	sd	s9,24(sp)
    80202d2c:	e86a                	sd	s10,16(sp)
    80202d2e:	e46e                	sd	s11,8(sp)
    80202d30:	1880                	add	s0,sp,112
    80202d32:	8aaa                	mv	s5,a0
    80202d34:	8bb2                	mv	s7,a2
    80202d36:	8b36                	mv	s6,a3
    80202d38:	8a3a                	mv	s4,a4
    if (user)
    80202d3a:	e58d                	bnez	a1,80202d64 <writei+0x50>
    if (off > ip->size || off + n < off)
    80202d3c:	04caa783          	lw	a5,76(s5)
    80202d40:	0f67e263          	bltu	a5,s6,80202e24 <writei+0x110>
    80202d44:	014b0d3b          	addw	s10,s6,s4
    80202d48:	000d0c9b          	sext.w	s9,s10
    80202d4c:	0d6cee63          	bltu	s9,s6,80202e28 <writei+0x114>
    if (off + n > MAXFILE * BSIZE)
    80202d50:	000437b7          	lui	a5,0x43
    80202d54:	0d97ec63          	bltu	a5,s9,80202e2c <writei+0x118>
    while (tot < n) {
    80202d58:	0a0a0063          	beqz	s4,80202df8 <writei+0xe4>
    uint tot = 0;
    80202d5c:	4481                	li	s1,0
        uint m = MIN(n - tot, BSIZE - (off + tot) % BSIZE);
    80202d5e:	40000c13          	li	s8,1024
    80202d62:	a0a9                	j	80202dac <writei+0x98>
        panic("writei user");
    80202d64:	00004517          	auipc	a0,0x4
    80202d68:	aa450513          	add	a0,a0,-1372 # 80206808 <syscalls+0x268>
    80202d6c:	ffffd097          	auipc	ra,0xffffd
    80202d70:	668080e7          	jalr	1640(ra) # 802003d4 <panic>
    80202d74:	b7e1                	j	80202d3c <writei+0x28>
        memmove(bp->data + (off + tot) % BSIZE, (void*)(src + tot), m);
    80202d76:	02049593          	sll	a1,s1,0x20
    80202d7a:	9181                	srl	a1,a1,0x20
    80202d7c:	05890513          	add	a0,s2,88
    80202d80:	000d861b          	sext.w	a2,s11
    80202d84:	95de                	add	a1,a1,s7
    80202d86:	954e                	add	a0,a0,s3
    80202d88:	ffffe097          	auipc	ra,0xffffe
    80202d8c:	c3c080e7          	jalr	-964(ra) # 802009c4 <memmove>
        log_write(bp); // [恢复] 使用 log_write
    80202d90:	854a                	mv	a0,s2
    80202d92:	00001097          	auipc	ra,0x1
    80202d96:	990080e7          	jalr	-1648(ra) # 80203722 <log_write>
        brelse(bp);
    80202d9a:	854a                	mv	a0,s2
    80202d9c:	fffff097          	auipc	ra,0xfffff
    80202da0:	2aa080e7          	jalr	682(ra) # 80202046 <brelse>
        tot += m;
    80202da4:	009d84bb          	addw	s1,s11,s1
    while (tot < n) {
    80202da8:	0544f263          	bgeu	s1,s4,80202dec <writei+0xd8>
        uint addr = bmap(ip, (off + tot) / BSIZE);
    80202dac:	009b09bb          	addw	s3,s6,s1
    80202db0:	00a9d59b          	srlw	a1,s3,0xa
    80202db4:	8556                	mv	a0,s5
    80202db6:	fffff097          	auipc	ra,0xfffff
    80202dba:	63e080e7          	jalr	1598(ra) # 802023f4 <bmap>
        struct buf *bp = bread(ip->dev, addr);
    80202dbe:	0005059b          	sext.w	a1,a0
    80202dc2:	000aa503          	lw	a0,0(s5)
    80202dc6:	fffff097          	auipc	ra,0xfffff
    80202dca:	12e080e7          	jalr	302(ra) # 80201ef4 <bread>
    80202dce:	892a                	mv	s2,a0
        uint m = MIN(n - tot, BSIZE - (off + tot) % BSIZE);
    80202dd0:	3ff9f993          	and	s3,s3,1023
    80202dd4:	413c07bb          	subw	a5,s8,s3
    80202dd8:	409a073b          	subw	a4,s4,s1
    80202ddc:	8dbe                	mv	s11,a5
    80202dde:	2781                	sext.w	a5,a5
    80202de0:	0007069b          	sext.w	a3,a4
    80202de4:	f8f6f9e3          	bgeu	a3,a5,80202d76 <writei+0x62>
    80202de8:	8dba                	mv	s11,a4
    80202dea:	b771                	j	80202d76 <writei+0x62>
    if (off + n > ip->size)
    80202dec:	04caa783          	lw	a5,76(s5)
    80202df0:	0197f463          	bgeu	a5,s9,80202df8 <writei+0xe4>
        ip->size = off + n;
    80202df4:	05aaa623          	sw	s10,76(s5)
    iupdate(ip);
    80202df8:	8556                	mv	a0,s5
    80202dfa:	00000097          	auipc	ra,0x0
    80202dfe:	c22080e7          	jalr	-990(ra) # 80202a1c <iupdate>
    return n;
    80202e02:	000a051b          	sext.w	a0,s4
}
    80202e06:	70a6                	ld	ra,104(sp)
    80202e08:	7406                	ld	s0,96(sp)
    80202e0a:	64e6                	ld	s1,88(sp)
    80202e0c:	6946                	ld	s2,80(sp)
    80202e0e:	69a6                	ld	s3,72(sp)
    80202e10:	6a06                	ld	s4,64(sp)
    80202e12:	7ae2                	ld	s5,56(sp)
    80202e14:	7b42                	ld	s6,48(sp)
    80202e16:	7ba2                	ld	s7,40(sp)
    80202e18:	7c02                	ld	s8,32(sp)
    80202e1a:	6ce2                	ld	s9,24(sp)
    80202e1c:	6d42                	ld	s10,16(sp)
    80202e1e:	6da2                	ld	s11,8(sp)
    80202e20:	6165                	add	sp,sp,112
    80202e22:	8082                	ret
        return -1;
    80202e24:	557d                	li	a0,-1
    80202e26:	b7c5                	j	80202e06 <writei+0xf2>
    80202e28:	557d                	li	a0,-1
    80202e2a:	bff1                	j	80202e06 <writei+0xf2>
        return -1;
    80202e2c:	557d                	li	a0,-1
    80202e2e:	bfe1                	j	80202e06 <writei+0xf2>

0000000080202e30 <namecmp>:
int namecmp(const char *s, const char *t) {
    80202e30:	1141                	add	sp,sp,-16
    80202e32:	e406                	sd	ra,8(sp)
    80202e34:	e022                	sd	s0,0(sp)
    80202e36:	0800                	add	s0,sp,16
    return strncmp(s, t, DIRSIZ);
    80202e38:	4639                	li	a2,14
    80202e3a:	ffffe097          	auipc	ra,0xffffe
    80202e3e:	c06080e7          	jalr	-1018(ra) # 80200a40 <strncmp>
}
    80202e42:	60a2                	ld	ra,8(sp)
    80202e44:	6402                	ld	s0,0(sp)
    80202e46:	0141                	add	sp,sp,16
    80202e48:	8082                	ret

0000000080202e4a <dirlookup>:
struct inode *dirlookup(struct inode *dp, char *name, uint *poff) {
    80202e4a:	715d                	add	sp,sp,-80
    80202e4c:	e486                	sd	ra,72(sp)
    80202e4e:	e0a2                	sd	s0,64(sp)
    80202e50:	fc26                	sd	s1,56(sp)
    80202e52:	f84a                	sd	s2,48(sp)
    80202e54:	f44e                	sd	s3,40(sp)
    80202e56:	f052                	sd	s4,32(sp)
    80202e58:	ec56                	sd	s5,24(sp)
    80202e5a:	0880                	add	s0,sp,80
    80202e5c:	892a                	mv	s2,a0
    80202e5e:	89ae                	mv	s3,a1
    80202e60:	8ab2                	mv	s5,a2
    if (dp->type != T_DIR)
    80202e62:	04451703          	lh	a4,68(a0)
    80202e66:	4785                	li	a5,1
    80202e68:	00f71b63          	bne	a4,a5,80202e7e <dirlookup+0x34>
    for (uint off = 0; off < dp->size; off += sizeof(de)) {
    80202e6c:	04c92783          	lw	a5,76(s2)
    80202e70:	cbd1                	beqz	a5,80202f04 <dirlookup+0xba>
    80202e72:	4481                	li	s1,0
            panic("dirlookup read");
    80202e74:	00004a17          	auipc	s4,0x4
    80202e78:	9b4a0a13          	add	s4,s4,-1612 # 80206828 <syscalls+0x288>
    80202e7c:	a02d                	j	80202ea6 <dirlookup+0x5c>
        panic("dirlookup");
    80202e7e:	00004517          	auipc	a0,0x4
    80202e82:	99a50513          	add	a0,a0,-1638 # 80206818 <syscalls+0x278>
    80202e86:	ffffd097          	auipc	ra,0xffffd
    80202e8a:	54e080e7          	jalr	1358(ra) # 802003d4 <panic>
    80202e8e:	bff9                	j	80202e6c <dirlookup+0x22>
            panic("dirlookup read");
    80202e90:	8552                	mv	a0,s4
    80202e92:	ffffd097          	auipc	ra,0xffffd
    80202e96:	542080e7          	jalr	1346(ra) # 802003d4 <panic>
    80202e9a:	a01d                	j	80202ec0 <dirlookup+0x76>
    for (uint off = 0; off < dp->size; off += sizeof(de)) {
    80202e9c:	24c1                	addw	s1,s1,16
    80202e9e:	04c92783          	lw	a5,76(s2)
    80202ea2:	04f4f763          	bgeu	s1,a5,80202ef0 <dirlookup+0xa6>
        if (readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80202ea6:	4741                	li	a4,16
    80202ea8:	86a6                	mv	a3,s1
    80202eaa:	fb040613          	add	a2,s0,-80
    80202eae:	4581                	li	a1,0
    80202eb0:	854a                	mv	a0,s2
    80202eb2:	00000097          	auipc	ra,0x0
    80202eb6:	d80080e7          	jalr	-640(ra) # 80202c32 <readi>
    80202eba:	47c1                	li	a5,16
    80202ebc:	fcf51ae3          	bne	a0,a5,80202e90 <dirlookup+0x46>
        if (de.inum == 0)
    80202ec0:	fb045783          	lhu	a5,-80(s0)
    80202ec4:	dfe1                	beqz	a5,80202e9c <dirlookup+0x52>
        if (namecmp(name, de.name) == 0) {
    80202ec6:	fb240593          	add	a1,s0,-78
    80202eca:	854e                	mv	a0,s3
    80202ecc:	00000097          	auipc	ra,0x0
    80202ed0:	f64080e7          	jalr	-156(ra) # 80202e30 <namecmp>
    80202ed4:	f561                	bnez	a0,80202e9c <dirlookup+0x52>
            if (poff)
    80202ed6:	000a8463          	beqz	s5,80202ede <dirlookup+0x94>
                *poff = off;
    80202eda:	009aa023          	sw	s1,0(s5)
            return iget(dp->dev, de.inum);
    80202ede:	fb045583          	lhu	a1,-80(s0)
    80202ee2:	00092503          	lw	a0,0(s2)
    80202ee6:	00000097          	auipc	ra,0x0
    80202eea:	86e080e7          	jalr	-1938(ra) # 80202754 <iget>
    80202eee:	a011                	j	80202ef2 <dirlookup+0xa8>
    return 0;
    80202ef0:	4501                	li	a0,0
}
    80202ef2:	60a6                	ld	ra,72(sp)
    80202ef4:	6406                	ld	s0,64(sp)
    80202ef6:	74e2                	ld	s1,56(sp)
    80202ef8:	7942                	ld	s2,48(sp)
    80202efa:	79a2                	ld	s3,40(sp)
    80202efc:	7a02                	ld	s4,32(sp)
    80202efe:	6ae2                	ld	s5,24(sp)
    80202f00:	6161                	add	sp,sp,80
    80202f02:	8082                	ret
    return 0;
    80202f04:	4501                	li	a0,0
    80202f06:	b7f5                	j	80202ef2 <dirlookup+0xa8>

0000000080202f08 <dirlink>:
int dirlink(struct inode *dp, char *name, uint inum) {
    80202f08:	715d                	add	sp,sp,-80
    80202f0a:	e486                	sd	ra,72(sp)
    80202f0c:	e0a2                	sd	s0,64(sp)
    80202f0e:	fc26                	sd	s1,56(sp)
    80202f10:	f84a                	sd	s2,48(sp)
    80202f12:	f44e                	sd	s3,40(sp)
    80202f14:	f052                	sd	s4,32(sp)
    80202f16:	ec56                	sd	s5,24(sp)
    80202f18:	0880                	add	s0,sp,80
    80202f1a:	892a                	mv	s2,a0
    80202f1c:	8a2e                	mv	s4,a1
    80202f1e:	8ab2                	mv	s5,a2
    if (dirlookup(dp, name, 0) != 0)
    80202f20:	4601                	li	a2,0
    80202f22:	00000097          	auipc	ra,0x0
    80202f26:	f28080e7          	jalr	-216(ra) # 80202e4a <dirlookup>
    80202f2a:	e14d                	bnez	a0,80202fcc <dirlink+0xc4>
    for (off = 0; off < dp->size; off += sizeof(de)) {
    80202f2c:	04c92483          	lw	s1,76(s2)
    80202f30:	c0b1                	beqz	s1,80202f74 <dirlink+0x6c>
    80202f32:	4481                	li	s1,0
            panic("dirlink read");
    80202f34:	00004997          	auipc	s3,0x4
    80202f38:	90498993          	add	s3,s3,-1788 # 80206838 <syscalls+0x298>
    80202f3c:	a809                	j	80202f4e <dirlink+0x46>
        if (de.inum == 0)
    80202f3e:	fb045783          	lhu	a5,-80(s0)
    80202f42:	cb8d                	beqz	a5,80202f74 <dirlink+0x6c>
    for (off = 0; off < dp->size; off += sizeof(de)) {
    80202f44:	24c1                	addw	s1,s1,16
    80202f46:	04c92783          	lw	a5,76(s2)
    80202f4a:	02f4f563          	bgeu	s1,a5,80202f74 <dirlink+0x6c>
        if (readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80202f4e:	4741                	li	a4,16
    80202f50:	86a6                	mv	a3,s1
    80202f52:	fb040613          	add	a2,s0,-80
    80202f56:	4581                	li	a1,0
    80202f58:	854a                	mv	a0,s2
    80202f5a:	00000097          	auipc	ra,0x0
    80202f5e:	cd8080e7          	jalr	-808(ra) # 80202c32 <readi>
    80202f62:	47c1                	li	a5,16
    80202f64:	fcf50de3          	beq	a0,a5,80202f3e <dirlink+0x36>
            panic("dirlink read");
    80202f68:	854e                	mv	a0,s3
    80202f6a:	ffffd097          	auipc	ra,0xffffd
    80202f6e:	46a080e7          	jalr	1130(ra) # 802003d4 <panic>
    80202f72:	b7f1                	j	80202f3e <dirlink+0x36>
    de.inum = inum;
    80202f74:	fb541823          	sh	s5,-80(s0)
    safestrcpy(de.name, name, DIRSIZ);
    80202f78:	4639                	li	a2,14
    80202f7a:	85d2                	mv	a1,s4
    80202f7c:	fb240513          	add	a0,s0,-78
    80202f80:	ffffe097          	auipc	ra,0xffffe
    80202f84:	b6c080e7          	jalr	-1172(ra) # 80200aec <safestrcpy>
    if (writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80202f88:	4741                	li	a4,16
    80202f8a:	86a6                	mv	a3,s1
    80202f8c:	fb040613          	add	a2,s0,-80
    80202f90:	4581                	li	a1,0
    80202f92:	854a                	mv	a0,s2
    80202f94:	00000097          	auipc	ra,0x0
    80202f98:	d80080e7          	jalr	-640(ra) # 80202d14 <writei>
    80202f9c:	872a                	mv	a4,a0
    80202f9e:	47c1                	li	a5,16
    return 0;
    80202fa0:	4501                	li	a0,0
    if (writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80202fa2:	00f71b63          	bne	a4,a5,80202fb8 <dirlink+0xb0>
}
    80202fa6:	60a6                	ld	ra,72(sp)
    80202fa8:	6406                	ld	s0,64(sp)
    80202faa:	74e2                	ld	s1,56(sp)
    80202fac:	7942                	ld	s2,48(sp)
    80202fae:	79a2                	ld	s3,40(sp)
    80202fb0:	7a02                	ld	s4,32(sp)
    80202fb2:	6ae2                	ld	s5,24(sp)
    80202fb4:	6161                	add	sp,sp,80
    80202fb6:	8082                	ret
        panic("dirlink");
    80202fb8:	00004517          	auipc	a0,0x4
    80202fbc:	9a050513          	add	a0,a0,-1632 # 80206958 <syscalls+0x3b8>
    80202fc0:	ffffd097          	auipc	ra,0xffffd
    80202fc4:	414080e7          	jalr	1044(ra) # 802003d4 <panic>
    return 0;
    80202fc8:	4501                	li	a0,0
    80202fca:	bff1                	j	80202fa6 <dirlink+0x9e>
        return -1;
    80202fcc:	557d                	li	a0,-1
    80202fce:	bfe1                	j	80202fa6 <dirlink+0x9e>

0000000080202fd0 <namex>:
struct inode *namex(char *path, int nameiparent, char *name) {
    80202fd0:	711d                	add	sp,sp,-96
    80202fd2:	ec86                	sd	ra,88(sp)
    80202fd4:	e8a2                	sd	s0,80(sp)
    80202fd6:	e4a6                	sd	s1,72(sp)
    80202fd8:	e0ca                	sd	s2,64(sp)
    80202fda:	fc4e                	sd	s3,56(sp)
    80202fdc:	f852                	sd	s4,48(sp)
    80202fde:	f456                	sd	s5,40(sp)
    80202fe0:	f05a                	sd	s6,32(sp)
    80202fe2:	ec5e                	sd	s7,24(sp)
    80202fe4:	e862                	sd	s8,16(sp)
    80202fe6:	e466                	sd	s9,8(sp)
    80202fe8:	1080                	add	s0,sp,96
    80202fea:	84aa                	mv	s1,a0
    80202fec:	8b2e                	mv	s6,a1
    80202fee:	8ab2                	mv	s5,a2
    if (*path == '/')
    80202ff0:	00054703          	lbu	a4,0(a0)
    80202ff4:	02f00793          	li	a5,47
    80202ff8:	02f70263          	beq	a4,a5,8020301c <namex+0x4c>
        ip = idup(myproc()->cwd);
    80202ffc:	ffffe097          	auipc	ra,0xffffe
    80203000:	39c080e7          	jalr	924(ra) # 80201398 <myproc>
    80203004:	15853503          	ld	a0,344(a0)
    80203008:	00000097          	auipc	ra,0x0
    8020300c:	8d0080e7          	jalr	-1840(ra) # 802028d8 <idup>
    80203010:	8a2a                	mv	s4,a0
    while (*path == '/')
    80203012:	02f00913          	li	s2,47
    if (len >= DIRSIZ)
    80203016:	4c35                	li	s8,13
        if (ip->type != T_DIR) {
    80203018:	4b85                	li	s7,1
    8020301a:	a875                	j	802030d6 <namex+0x106>
        ip = iget(ROOTDEV, ROOTINO);
    8020301c:	4585                	li	a1,1
    8020301e:	4505                	li	a0,1
    80203020:	fffff097          	auipc	ra,0xfffff
    80203024:	734080e7          	jalr	1844(ra) # 80202754 <iget>
    80203028:	8a2a                	mv	s4,a0
    8020302a:	b7e5                	j	80203012 <namex+0x42>
            iunlockput(ip);
    8020302c:	8552                	mv	a0,s4
    8020302e:	00000097          	auipc	ra,0x0
    80203032:	bb0080e7          	jalr	-1104(ra) # 80202bde <iunlockput>
            return 0;
    80203036:	4a01                	li	s4,0
}
    80203038:	8552                	mv	a0,s4
    8020303a:	60e6                	ld	ra,88(sp)
    8020303c:	6446                	ld	s0,80(sp)
    8020303e:	64a6                	ld	s1,72(sp)
    80203040:	6906                	ld	s2,64(sp)
    80203042:	79e2                	ld	s3,56(sp)
    80203044:	7a42                	ld	s4,48(sp)
    80203046:	7aa2                	ld	s5,40(sp)
    80203048:	7b02                	ld	s6,32(sp)
    8020304a:	6be2                	ld	s7,24(sp)
    8020304c:	6c42                	ld	s8,16(sp)
    8020304e:	6ca2                	ld	s9,8(sp)
    80203050:	6125                	add	sp,sp,96
    80203052:	8082                	ret
            iunlock(ip);
    80203054:	8552                	mv	a0,s4
    80203056:	00000097          	auipc	ra,0x0
    8020305a:	986080e7          	jalr	-1658(ra) # 802029dc <iunlock>
            return ip;
    8020305e:	bfe9                	j	80203038 <namex+0x68>
            iunlockput(ip);
    80203060:	8552                	mv	a0,s4
    80203062:	00000097          	auipc	ra,0x0
    80203066:	b7c080e7          	jalr	-1156(ra) # 80202bde <iunlockput>
            return 0;
    8020306a:	8a4e                	mv	s4,s3
    8020306c:	b7f1                	j	80203038 <namex+0x68>
    int len = path - s;
    8020306e:	40998633          	sub	a2,s3,s1
    80203072:	00060c9b          	sext.w	s9,a2
    if (len >= DIRSIZ)
    80203076:	099c5863          	bge	s8,s9,80203106 <namex+0x136>
        memmove(name, s, DIRSIZ);
    8020307a:	4639                	li	a2,14
    8020307c:	85a6                	mv	a1,s1
    8020307e:	8556                	mv	a0,s5
    80203080:	ffffe097          	auipc	ra,0xffffe
    80203084:	944080e7          	jalr	-1724(ra) # 802009c4 <memmove>
    80203088:	84ce                	mv	s1,s3
    while (*path == '/')
    8020308a:	0004c783          	lbu	a5,0(s1)
    8020308e:	01279763          	bne	a5,s2,8020309c <namex+0xcc>
        path++;
    80203092:	0485                	add	s1,s1,1
    while (*path == '/')
    80203094:	0004c783          	lbu	a5,0(s1)
    80203098:	ff278de3          	beq	a5,s2,80203092 <namex+0xc2>
        ilock(ip);
    8020309c:	8552                	mv	a0,s4
    8020309e:	00000097          	auipc	ra,0x0
    802030a2:	878080e7          	jalr	-1928(ra) # 80202916 <ilock>
        if (ip->type != T_DIR) {
    802030a6:	044a1783          	lh	a5,68(s4)
    802030aa:	f97791e3          	bne	a5,s7,8020302c <namex+0x5c>
        if (nameiparent && *path == '\0') {
    802030ae:	000b0563          	beqz	s6,802030b8 <namex+0xe8>
    802030b2:	0004c783          	lbu	a5,0(s1)
    802030b6:	dfd9                	beqz	a5,80203054 <namex+0x84>
        if ((next = dirlookup(ip, name, 0)) == 0) {
    802030b8:	4601                	li	a2,0
    802030ba:	85d6                	mv	a1,s5
    802030bc:	8552                	mv	a0,s4
    802030be:	00000097          	auipc	ra,0x0
    802030c2:	d8c080e7          	jalr	-628(ra) # 80202e4a <dirlookup>
    802030c6:	89aa                	mv	s3,a0
    802030c8:	dd41                	beqz	a0,80203060 <namex+0x90>
        iunlockput(ip);
    802030ca:	8552                	mv	a0,s4
    802030cc:	00000097          	auipc	ra,0x0
    802030d0:	b12080e7          	jalr	-1262(ra) # 80202bde <iunlockput>
        ip = next;
    802030d4:	8a4e                	mv	s4,s3
    while (*path == '/')
    802030d6:	0004c783          	lbu	a5,0(s1)
    802030da:	01279763          	bne	a5,s2,802030e8 <namex+0x118>
        path++;
    802030de:	0485                	add	s1,s1,1
    while (*path == '/')
    802030e0:	0004c783          	lbu	a5,0(s1)
    802030e4:	ff278de3          	beq	a5,s2,802030de <namex+0x10e>
    if (*path == 0)
    802030e8:	cb9d                	beqz	a5,8020311e <namex+0x14e>
    while (*path != '/' && *path != 0)
    802030ea:	0004c783          	lbu	a5,0(s1)
    802030ee:	89a6                	mv	s3,s1
    int len = path - s;
    802030f0:	4c81                	li	s9,0
    802030f2:	4601                	li	a2,0
    while (*path != '/' && *path != 0)
    802030f4:	01278963          	beq	a5,s2,80203106 <namex+0x136>
    802030f8:	dbbd                	beqz	a5,8020306e <namex+0x9e>
        path++;
    802030fa:	0985                	add	s3,s3,1
    while (*path != '/' && *path != 0)
    802030fc:	0009c783          	lbu	a5,0(s3)
    80203100:	ff279ce3          	bne	a5,s2,802030f8 <namex+0x128>
    80203104:	b7ad                	j	8020306e <namex+0x9e>
        memmove(name, s, len);
    80203106:	2601                	sext.w	a2,a2
    80203108:	85a6                	mv	a1,s1
    8020310a:	8556                	mv	a0,s5
    8020310c:	ffffe097          	auipc	ra,0xffffe
    80203110:	8b8080e7          	jalr	-1864(ra) # 802009c4 <memmove>
        name[len] = 0;
    80203114:	9cd6                	add	s9,s9,s5
    80203116:	000c8023          	sb	zero,0(s9)
    8020311a:	84ce                	mv	s1,s3
    8020311c:	b7bd                	j	8020308a <namex+0xba>
    if (nameiparent) {
    8020311e:	f00b0de3          	beqz	s6,80203038 <namex+0x68>
        iput(ip);
    80203122:	8552                	mv	a0,s4
    80203124:	00000097          	auipc	ra,0x0
    80203128:	a32080e7          	jalr	-1486(ra) # 80202b56 <iput>
        return 0;
    8020312c:	4a01                	li	s4,0
    8020312e:	b729                	j	80203038 <namex+0x68>

0000000080203130 <namei>:
struct inode *namei(char *path) {
    80203130:	1101                	add	sp,sp,-32
    80203132:	ec06                	sd	ra,24(sp)
    80203134:	e822                	sd	s0,16(sp)
    80203136:	1000                	add	s0,sp,32
    return namex(path, 0, name);
    80203138:	fe040613          	add	a2,s0,-32
    8020313c:	4581                	li	a1,0
    8020313e:	00000097          	auipc	ra,0x0
    80203142:	e92080e7          	jalr	-366(ra) # 80202fd0 <namex>
}
    80203146:	60e2                	ld	ra,24(sp)
    80203148:	6442                	ld	s0,16(sp)
    8020314a:	6105                	add	sp,sp,32
    8020314c:	8082                	ret

000000008020314e <nameiparent>:
struct inode *nameiparent(char *path, char *name) {
    8020314e:	1141                	add	sp,sp,-16
    80203150:	e406                	sd	ra,8(sp)
    80203152:	e022                	sd	s0,0(sp)
    80203154:	0800                	add	s0,sp,16
    80203156:	862e                	mv	a2,a1
    return namex(path, 1, name);
    80203158:	4585                	li	a1,1
    8020315a:	00000097          	auipc	ra,0x0
    8020315e:	e76080e7          	jalr	-394(ra) # 80202fd0 <namex>
}
    80203162:	60a2                	ld	ra,8(sp)
    80203164:	6402                	ld	s0,0(sp)
    80203166:	0141                	add	sp,sp,16
    80203168:	8082                	ret

000000008020316a <count_free_blocks>:
int count_free_blocks(void) {
    8020316a:	715d                	add	sp,sp,-80
    8020316c:	e486                	sd	ra,72(sp)
    8020316e:	e0a2                	sd	s0,64(sp)
    80203170:	fc26                	sd	s1,56(sp)
    80203172:	f84a                	sd	s2,48(sp)
    80203174:	f44e                	sd	s3,40(sp)
    80203176:	f052                	sd	s4,32(sp)
    80203178:	ec56                	sd	s5,24(sp)
    8020317a:	e85a                	sd	s6,16(sp)
    8020317c:	e45e                	sd	s7,8(sp)
    8020317e:	e062                	sd	s8,0(sp)
    80203180:	0880                	add	s0,sp,80
    return sb.bmapstart + ((sb.nblocks + BPB - 1) / BPB);
    80203182:	00034797          	auipc	a5,0x34
    80203186:	dde78793          	add	a5,a5,-546 # 80236f60 <sb>
    8020318a:	4798                	lw	a4,8(a5)
    8020318c:	6489                	lui	s1,0x2
    8020318e:	34fd                	addw	s1,s1,-1 # 1fff <_start-0x801fe001>
    80203190:	9cb9                	addw	s1,s1,a4
    80203192:	00d4d49b          	srlw	s1,s1,0xd
    80203196:	4fd8                	lw	a4,28(a5)
    80203198:	9cb9                	addw	s1,s1,a4
    for (uint b = 0; b < sb.size; b += BPB) {
    8020319a:	43dc                	lw	a5,4(a5)
    8020319c:	cbb5                	beqz	a5,80203210 <count_free_blocks+0xa6>
    8020319e:	4a81                	li	s5,0
    int free = 0;
    802031a0:	4981                	li	s3,0
        struct buf *bp = bread(ROOTDEV, BBLOCK(b, sb));
    802031a2:	00034b17          	auipc	s6,0x34
    802031a6:	dbeb0b13          	add	s6,s6,-578 # 80236f60 <sb>
        for (uint bi = 0; bi < BPB && b + bi < sb.size; bi++) {
    802031aa:	4c01                	li	s8,0
            int m = 1 << (bi % 8);
    802031ac:	4a05                	li	s4,1
        for (uint bi = 0; bi < BPB && b + bi < sb.size; bi++) {
    802031ae:	6909                	lui	s2,0x2
    for (uint b = 0; b < sb.size; b += BPB) {
    802031b0:	6b89                	lui	s7,0x2
    802031b2:	a081                	j	802031f2 <count_free_blocks+0x88>
        for (uint bi = 0; bi < BPB && b + bi < sb.size; bi++) {
    802031b4:	2785                	addw	a5,a5,1
    802031b6:	2705                	addw	a4,a4,1
    802031b8:	03278363          	beq	a5,s2,802031de <count_free_blocks+0x74>
    802031bc:	02b77163          	bgeu	a4,a1,802031de <count_free_blocks+0x74>
            if (b + bi < start)
    802031c0:	fe976ae3          	bltu	a4,s1,802031b4 <count_free_blocks+0x4a>
            if ((bp->data[bi / 8] & m) == 0)
    802031c4:	0037d69b          	srlw	a3,a5,0x3
    802031c8:	96aa                	add	a3,a3,a0
            int m = 1 << (bi % 8);
    802031ca:	0077f613          	and	a2,a5,7
    802031ce:	00ca163b          	sllw	a2,s4,a2
            if ((bp->data[bi / 8] & m) == 0)
    802031d2:	0586c683          	lbu	a3,88(a3)
    802031d6:	8ef1                	and	a3,a3,a2
    802031d8:	fef1                	bnez	a3,802031b4 <count_free_blocks+0x4a>
                free++;
    802031da:	2985                	addw	s3,s3,1
    802031dc:	bfe1                	j	802031b4 <count_free_blocks+0x4a>
        brelse(bp);
    802031de:	fffff097          	auipc	ra,0xfffff
    802031e2:	e68080e7          	jalr	-408(ra) # 80202046 <brelse>
    for (uint b = 0; b < sb.size; b += BPB) {
    802031e6:	015b8abb          	addw	s5,s7,s5
    802031ea:	004b2783          	lw	a5,4(s6)
    802031ee:	02faf263          	bgeu	s5,a5,80203212 <count_free_blocks+0xa8>
        struct buf *bp = bread(ROOTDEV, BBLOCK(b, sb));
    802031f2:	00dad59b          	srlw	a1,s5,0xd
    802031f6:	01cb2783          	lw	a5,28(s6)
    802031fa:	9dbd                	addw	a1,a1,a5
    802031fc:	4505                	li	a0,1
    802031fe:	fffff097          	auipc	ra,0xfffff
    80203202:	cf6080e7          	jalr	-778(ra) # 80201ef4 <bread>
        for (uint bi = 0; bi < BPB && b + bi < sb.size; bi++) {
    80203206:	004b2583          	lw	a1,4(s6)
    8020320a:	8756                	mv	a4,s5
    8020320c:	87e2                	mv	a5,s8
    8020320e:	b77d                	j	802031bc <count_free_blocks+0x52>
    int free = 0;
    80203210:	4981                	li	s3,0
}
    80203212:	854e                	mv	a0,s3
    80203214:	60a6                	ld	ra,72(sp)
    80203216:	6406                	ld	s0,64(sp)
    80203218:	74e2                	ld	s1,56(sp)
    8020321a:	7942                	ld	s2,48(sp)
    8020321c:	79a2                	ld	s3,40(sp)
    8020321e:	7a02                	ld	s4,32(sp)
    80203220:	6ae2                	ld	s5,24(sp)
    80203222:	6b42                	ld	s6,16(sp)
    80203224:	6ba2                	ld	s7,8(sp)
    80203226:	6c02                	ld	s8,0(sp)
    80203228:	6161                	add	sp,sp,80
    8020322a:	8082                	ret

000000008020322c <count_free_inodes>:
int count_free_inodes(void) {
    8020322c:	7179                	add	sp,sp,-48
    8020322e:	f406                	sd	ra,40(sp)
    80203230:	f022                	sd	s0,32(sp)
    80203232:	ec26                	sd	s1,24(sp)
    80203234:	e84a                	sd	s2,16(sp)
    80203236:	e44e                	sd	s3,8(sp)
    80203238:	1800                	add	s0,sp,48
    for (uint inum = 1; inum < sb.ninodes; inum++) {
    8020323a:	00034717          	auipc	a4,0x34
    8020323e:	d3272703          	lw	a4,-718(a4) # 80236f6c <sb+0xc>
    80203242:	4785                	li	a5,1
    80203244:	04e7f563          	bgeu	a5,a4,8020328e <count_free_inodes+0x62>
    80203248:	4485                	li	s1,1
    int free = 0;
    8020324a:	4981                	li	s3,0
        struct buf *bp = bread(ROOTDEV, IBLOCK(inum, sb));
    8020324c:	00034917          	auipc	s2,0x34
    80203250:	d1490913          	add	s2,s2,-748 # 80236f60 <sb>
    80203254:	a811                	j	80203268 <count_free_inodes+0x3c>
        brelse(bp);
    80203256:	fffff097          	auipc	ra,0xfffff
    8020325a:	df0080e7          	jalr	-528(ra) # 80202046 <brelse>
    for (uint inum = 1; inum < sb.ninodes; inum++) {
    8020325e:	2485                	addw	s1,s1,1
    80203260:	00c92783          	lw	a5,12(s2)
    80203264:	02f4f663          	bgeu	s1,a5,80203290 <count_free_inodes+0x64>
        struct buf *bp = bread(ROOTDEV, IBLOCK(inum, sb));
    80203268:	0044d59b          	srlw	a1,s1,0x4
    8020326c:	01892783          	lw	a5,24(s2)
    80203270:	9dbd                	addw	a1,a1,a5
    80203272:	4505                	li	a0,1
    80203274:	fffff097          	auipc	ra,0xfffff
    80203278:	c80080e7          	jalr	-896(ra) # 80201ef4 <bread>
        struct dinode *dip = (struct dinode*)bp->data + inum % IPB;
    8020327c:	00f4f793          	and	a5,s1,15
        if (dip->type == 0)
    80203280:	079a                	sll	a5,a5,0x6
    80203282:	97aa                	add	a5,a5,a0
    80203284:	05879783          	lh	a5,88(a5)
    80203288:	f7f9                	bnez	a5,80203256 <count_free_inodes+0x2a>
            free++;
    8020328a:	2985                	addw	s3,s3,1
    8020328c:	b7e9                	j	80203256 <count_free_inodes+0x2a>
    int free = 0;
    8020328e:	4981                	li	s3,0
}
    80203290:	854e                	mv	a0,s3
    80203292:	70a2                	ld	ra,40(sp)
    80203294:	7402                	ld	s0,32(sp)
    80203296:	64e2                	ld	s1,24(sp)
    80203298:	6942                	ld	s2,16(sp)
    8020329a:	69a2                	ld	s3,8(sp)
    8020329c:	6145                	add	sp,sp,48
    8020329e:	8082                	ret

00000000802032a0 <get_superblock>:
void get_superblock(struct superblock *dst) {
    802032a0:	1141                	add	sp,sp,-16
    802032a2:	e422                	sd	s0,8(sp)
    802032a4:	0800                	add	s0,sp,16
    *dst = sb;
    802032a6:	00034797          	auipc	a5,0x34
    802032aa:	cba78793          	add	a5,a5,-838 # 80236f60 <sb>
    802032ae:	0007a303          	lw	t1,0(a5)
    802032b2:	0047a883          	lw	a7,4(a5)
    802032b6:	0087a803          	lw	a6,8(a5)
    802032ba:	47cc                	lw	a1,12(a5)
    802032bc:	4b90                	lw	a2,16(a5)
    802032be:	4bd4                	lw	a3,20(a5)
    802032c0:	4f98                	lw	a4,24(a5)
    802032c2:	4fdc                	lw	a5,28(a5)
    802032c4:	00652023          	sw	t1,0(a0)
    802032c8:	01152223          	sw	a7,4(a0)
    802032cc:	01052423          	sw	a6,8(a0)
    802032d0:	c54c                	sw	a1,12(a0)
    802032d2:	c910                	sw	a2,16(a0)
    802032d4:	c954                	sw	a3,20(a0)
    802032d6:	cd18                	sw	a4,24(a0)
    802032d8:	cd5c                	sw	a5,28(a0)
}
    802032da:	6422                	ld	s0,8(sp)
    802032dc:	0141                	add	sp,sp,16
    802032de:	8082                	ret

00000000802032e0 <dump_inode_usage>:
void dump_inode_usage(void) {
    802032e0:	7179                	add	sp,sp,-48
    802032e2:	f406                	sd	ra,40(sp)
    802032e4:	f022                	sd	s0,32(sp)
    802032e6:	ec26                	sd	s1,24(sp)
    802032e8:	e84a                	sd	s2,16(sp)
    802032ea:	e44e                	sd	s3,8(sp)
    802032ec:	1800                	add	s0,sp,48
    acquire(&icache.lock);
    802032ee:	00034517          	auipc	a0,0x34
    802032f2:	c9250513          	add	a0,a0,-878 # 80236f80 <icache>
    802032f6:	ffffd097          	auipc	ra,0xffffd
    802032fa:	544080e7          	jalr	1348(ra) # 8020083a <acquire>
    printf("=== Inode Usage ===\n");
    802032fe:	00003517          	auipc	a0,0x3
    80203302:	54a50513          	add	a0,a0,1354 # 80206848 <syscalls+0x2a8>
    80203306:	ffffd097          	auipc	ra,0xffffd
    8020330a:	e4e080e7          	jalr	-434(ra) # 80200154 <printf>
    for (int i = 0; i < NINODE; i++) {
    8020330e:	00034497          	auipc	s1,0x34
    80203312:	c8e48493          	add	s1,s1,-882 # 80236f9c <icache+0x1c>
    80203316:	0003e917          	auipc	s2,0x3e
    8020331a:	be690913          	add	s2,s2,-1050 # 80240efc <log+0x4>
            printf("inum=%d ref=%d type=%d size=%d\n", ip->inum, ip->ref, ip->type, ip->size);
    8020331e:	00003997          	auipc	s3,0x3
    80203322:	54298993          	add	s3,s3,1346 # 80206860 <syscalls+0x2c0>
    80203326:	a029                	j	80203330 <dump_inode_usage+0x50>
    for (int i = 0; i < NINODE; i++) {
    80203328:	08848493          	add	s1,s1,136
    8020332c:	01248f63          	beq	s1,s2,8020334a <dump_inode_usage+0x6a>
        if (ip->ref > 0)
    80203330:	40d0                	lw	a2,4(s1)
    80203332:	fec05be3          	blez	a2,80203328 <dump_inode_usage+0x48>
            printf("inum=%d ref=%d type=%d size=%d\n", ip->inum, ip->ref, ip->type, ip->size);
    80203336:	44b8                	lw	a4,72(s1)
    80203338:	04049683          	lh	a3,64(s1)
    8020333c:	408c                	lw	a1,0(s1)
    8020333e:	854e                	mv	a0,s3
    80203340:	ffffd097          	auipc	ra,0xffffd
    80203344:	e14080e7          	jalr	-492(ra) # 80200154 <printf>
    80203348:	b7c5                	j	80203328 <dump_inode_usage+0x48>
    release(&icache.lock);
    8020334a:	00034517          	auipc	a0,0x34
    8020334e:	c3650513          	add	a0,a0,-970 # 80236f80 <icache>
    80203352:	ffffd097          	auipc	ra,0xffffd
    80203356:	5da080e7          	jalr	1498(ra) # 8020092c <release>
}
    8020335a:	70a2                	ld	ra,40(sp)
    8020335c:	7402                	ld	s0,32(sp)
    8020335e:	64e2                	ld	s1,24(sp)
    80203360:	6942                	ld	s2,16(sp)
    80203362:	69a2                	ld	s3,8(sp)
    80203364:	6145                	add	sp,sp,48
    80203366:	8082                	ret

0000000080203368 <write_head>:
    struct logheader *hb = (struct logheader*)(buf->data);
    log.lh = *hb;
    brelse(buf);
}

static void write_head(void) {
    80203368:	1101                	add	sp,sp,-32
    8020336a:	ec06                	sd	ra,24(sp)
    8020336c:	e822                	sd	s0,16(sp)
    8020336e:	e426                	sd	s1,8(sp)
    80203370:	1000                	add	s0,sp,32
    struct buf *buf = bread(log.dev, log.start);
    80203372:	0003e797          	auipc	a5,0x3e
    80203376:	b8678793          	add	a5,a5,-1146 # 80240ef8 <log>
    8020337a:	4f8c                	lw	a1,24(a5)
    8020337c:	5788                	lw	a0,40(a5)
    8020337e:	fffff097          	auipc	ra,0xfffff
    80203382:	b76080e7          	jalr	-1162(ra) # 80201ef4 <bread>
    80203386:	84aa                	mv	s1,a0
    struct logheader *hb = (struct logheader*)(buf->data);
    *hb = log.lh;
    80203388:	07c00613          	li	a2,124
    8020338c:	0003e597          	auipc	a1,0x3e
    80203390:	b9858593          	add	a1,a1,-1128 # 80240f24 <log+0x2c>
    80203394:	05850513          	add	a0,a0,88
    80203398:	ffffd097          	auipc	ra,0xffffd
    8020339c:	690080e7          	jalr	1680(ra) # 80200a28 <memcpy>
    bwrite(buf);
    802033a0:	8526                	mv	a0,s1
    802033a2:	fffff097          	auipc	ra,0xfffff
    802033a6:	c64080e7          	jalr	-924(ra) # 80202006 <bwrite>
    brelse(buf);
    802033aa:	8526                	mv	a0,s1
    802033ac:	fffff097          	auipc	ra,0xfffff
    802033b0:	c9a080e7          	jalr	-870(ra) # 80202046 <brelse>
}
    802033b4:	60e2                	ld	ra,24(sp)
    802033b6:	6442                	ld	s0,16(sp)
    802033b8:	64a2                	ld	s1,8(sp)
    802033ba:	6105                	add	sp,sp,32
    802033bc:	8082                	ret

00000000802033be <install_trans>:
static void install_trans(int recovering) {
    802033be:	7139                	add	sp,sp,-64
    802033c0:	fc06                	sd	ra,56(sp)
    802033c2:	f822                	sd	s0,48(sp)
    802033c4:	f426                	sd	s1,40(sp)
    802033c6:	f04a                	sd	s2,32(sp)
    802033c8:	ec4e                	sd	s3,24(sp)
    802033ca:	e852                	sd	s4,16(sp)
    802033cc:	e456                	sd	s5,8(sp)
    802033ce:	e05a                	sd	s6,0(sp)
    802033d0:	0080                	add	s0,sp,64
    802033d2:	8b2a                	mv	s6,a0
    for (int tail = 0; tail < log.lh.n; tail++) {
    802033d4:	0003e797          	auipc	a5,0x3e
    802033d8:	b507a783          	lw	a5,-1200(a5) # 80240f24 <log+0x2c>
    802033dc:	08f05463          	blez	a5,80203464 <install_trans+0xa6>
    802033e0:	0003ea97          	auipc	s5,0x3e
    802033e4:	b48a8a93          	add	s5,s5,-1208 # 80240f28 <log+0x30>
    802033e8:	4a01                	li	s4,0
        struct buf *lbuf = bread(log.dev, log.start + tail + 1);
    802033ea:	0003e997          	auipc	s3,0x3e
    802033ee:	b0e98993          	add	s3,s3,-1266 # 80240ef8 <log>
    802033f2:	0189a583          	lw	a1,24(s3)
    802033f6:	014585bb          	addw	a1,a1,s4
    802033fa:	2585                	addw	a1,a1,1
    802033fc:	0289a503          	lw	a0,40(s3)
    80203400:	fffff097          	auipc	ra,0xfffff
    80203404:	af4080e7          	jalr	-1292(ra) # 80201ef4 <bread>
    80203408:	892a                	mv	s2,a0
        struct buf *dbuf = bread(log.dev, log.lh.block[tail]);
    8020340a:	000aa583          	lw	a1,0(s5)
    8020340e:	0289a503          	lw	a0,40(s3)
    80203412:	fffff097          	auipc	ra,0xfffff
    80203416:	ae2080e7          	jalr	-1310(ra) # 80201ef4 <bread>
    8020341a:	84aa                	mv	s1,a0
        memmove(dbuf->data, lbuf->data, BSIZE);
    8020341c:	40000613          	li	a2,1024
    80203420:	05890593          	add	a1,s2,88
    80203424:	05850513          	add	a0,a0,88
    80203428:	ffffd097          	auipc	ra,0xffffd
    8020342c:	59c080e7          	jalr	1436(ra) # 802009c4 <memmove>
        bwrite(dbuf);
    80203430:	8526                	mv	a0,s1
    80203432:	fffff097          	auipc	ra,0xfffff
    80203436:	bd4080e7          	jalr	-1068(ra) # 80202006 <bwrite>
        bunpin(dbuf);
    8020343a:	8526                	mv	a0,s1
    8020343c:	fffff097          	auipc	ra,0xfffff
    80203440:	ce4080e7          	jalr	-796(ra) # 80202120 <bunpin>
        brelse(lbuf);
    80203444:	854a                	mv	a0,s2
    80203446:	fffff097          	auipc	ra,0xfffff
    8020344a:	c00080e7          	jalr	-1024(ra) # 80202046 <brelse>
        brelse(dbuf);
    8020344e:	8526                	mv	a0,s1
    80203450:	fffff097          	auipc	ra,0xfffff
    80203454:	bf6080e7          	jalr	-1034(ra) # 80202046 <brelse>
    for (int tail = 0; tail < log.lh.n; tail++) {
    80203458:	2a05                	addw	s4,s4,1
    8020345a:	0a91                	add	s5,s5,4
    8020345c:	02c9a783          	lw	a5,44(s3)
    80203460:	f8fa49e3          	blt	s4,a5,802033f2 <install_trans+0x34>
    if (!recovering) {
    80203464:	000b0c63          	beqz	s6,8020347c <install_trans+0xbe>
}
    80203468:	70e2                	ld	ra,56(sp)
    8020346a:	7442                	ld	s0,48(sp)
    8020346c:	74a2                	ld	s1,40(sp)
    8020346e:	7902                	ld	s2,32(sp)
    80203470:	69e2                	ld	s3,24(sp)
    80203472:	6a42                	ld	s4,16(sp)
    80203474:	6aa2                	ld	s5,8(sp)
    80203476:	6b02                	ld	s6,0(sp)
    80203478:	6121                	add	sp,sp,64
    8020347a:	8082                	ret
        log.lh.n = 0;
    8020347c:	0003e797          	auipc	a5,0x3e
    80203480:	a7c78793          	add	a5,a5,-1412 # 80240ef8 <log>
    80203484:	0207a623          	sw	zero,44(a5)
        struct buf *buf = bread(log.dev, log.start);
    80203488:	4f8c                	lw	a1,24(a5)
    8020348a:	5788                	lw	a0,40(a5)
    8020348c:	fffff097          	auipc	ra,0xfffff
    80203490:	a68080e7          	jalr	-1432(ra) # 80201ef4 <bread>
    80203494:	84aa                	mv	s1,a0
        *hb = log.lh;
    80203496:	07c00613          	li	a2,124
    8020349a:	0003e597          	auipc	a1,0x3e
    8020349e:	a8a58593          	add	a1,a1,-1398 # 80240f24 <log+0x2c>
    802034a2:	05850513          	add	a0,a0,88
    802034a6:	ffffd097          	auipc	ra,0xffffd
    802034aa:	582080e7          	jalr	1410(ra) # 80200a28 <memcpy>
        bwrite(buf);
    802034ae:	8526                	mv	a0,s1
    802034b0:	fffff097          	auipc	ra,0xfffff
    802034b4:	b56080e7          	jalr	-1194(ra) # 80202006 <bwrite>
        brelse(buf);
    802034b8:	8526                	mv	a0,s1
    802034ba:	fffff097          	auipc	ra,0xfffff
    802034be:	b8c080e7          	jalr	-1140(ra) # 80202046 <brelse>
}
    802034c2:	b75d                	j	80203468 <install_trans+0xaa>

00000000802034c4 <initlog>:

void initlog(int dev, struct superblock *sb) {
    802034c4:	7179                	add	sp,sp,-48
    802034c6:	f406                	sd	ra,40(sp)
    802034c8:	f022                	sd	s0,32(sp)
    802034ca:	ec26                	sd	s1,24(sp)
    802034cc:	e84a                	sd	s2,16(sp)
    802034ce:	e44e                	sd	s3,8(sp)
    802034d0:	1800                	add	s0,sp,48
    802034d2:	892a                	mv	s2,a0
    802034d4:	89ae                	mv	s3,a1
    if (sizeof(struct logheader) >= BSIZE) {
        panic("initlog: too big");
    }
    spinlock_init(&log.lock, "log");
    802034d6:	0003e497          	auipc	s1,0x3e
    802034da:	a2248493          	add	s1,s1,-1502 # 80240ef8 <log>
    802034de:	00003597          	auipc	a1,0x3
    802034e2:	3a258593          	add	a1,a1,930 # 80206880 <syscalls+0x2e0>
    802034e6:	8526                	mv	a0,s1
    802034e8:	ffffd097          	auipc	ra,0xffffd
    802034ec:	2f0080e7          	jalr	752(ra) # 802007d8 <spinlock_init>
    log.start = sb->logstart;
    802034f0:	0149a583          	lw	a1,20(s3)
    802034f4:	cc8c                	sw	a1,24(s1)
    log.size = sb->nlog;
    802034f6:	0109a783          	lw	a5,16(s3)
    802034fa:	ccdc                	sw	a5,28(s1)
    log.dev = dev;
    802034fc:	0324a423          	sw	s2,40(s1)
    struct buf *buf = bread(log.dev, log.start);
    80203500:	854a                	mv	a0,s2
    80203502:	fffff097          	auipc	ra,0xfffff
    80203506:	9f2080e7          	jalr	-1550(ra) # 80201ef4 <bread>
    8020350a:	892a                	mv	s2,a0
    log.lh = *hb;
    8020350c:	07c00613          	li	a2,124
    80203510:	05850593          	add	a1,a0,88
    80203514:	0003e517          	auipc	a0,0x3e
    80203518:	a1050513          	add	a0,a0,-1520 # 80240f24 <log+0x2c>
    8020351c:	ffffd097          	auipc	ra,0xffffd
    80203520:	50c080e7          	jalr	1292(ra) # 80200a28 <memcpy>
    brelse(buf);
    80203524:	854a                	mv	a0,s2
    80203526:	fffff097          	auipc	ra,0xfffff
    8020352a:	b20080e7          	jalr	-1248(ra) # 80202046 <brelse>
    read_head();
    install_trans(1);
    8020352e:	4505                	li	a0,1
    80203530:	00000097          	auipc	ra,0x0
    80203534:	e8e080e7          	jalr	-370(ra) # 802033be <install_trans>
    log.lh.n = 0;
    80203538:	0204a623          	sw	zero,44(s1)
    write_head();
    8020353c:	00000097          	auipc	ra,0x0
    80203540:	e2c080e7          	jalr	-468(ra) # 80203368 <write_head>
}
    80203544:	70a2                	ld	ra,40(sp)
    80203546:	7402                	ld	s0,32(sp)
    80203548:	64e2                	ld	s1,24(sp)
    8020354a:	6942                	ld	s2,16(sp)
    8020354c:	69a2                	ld	s3,8(sp)
    8020354e:	6145                	add	sp,sp,48
    80203550:	8082                	ret

0000000080203552 <begin_op>:

void begin_op(void) {
    80203552:	1101                	add	sp,sp,-32
    80203554:	ec06                	sd	ra,24(sp)
    80203556:	e822                	sd	s0,16(sp)
    80203558:	e426                	sd	s1,8(sp)
    8020355a:	e04a                	sd	s2,0(sp)
    8020355c:	1000                	add	s0,sp,32
    acquire(&log.lock);
    8020355e:	0003e517          	auipc	a0,0x3e
    80203562:	99a50513          	add	a0,a0,-1638 # 80240ef8 <log>
    80203566:	ffffd097          	auipc	ra,0xffffd
    8020356a:	2d4080e7          	jalr	724(ra) # 8020083a <acquire>
    while (1) {
        if (log.committing) {
    8020356e:	0003e497          	auipc	s1,0x3e
    80203572:	98a48493          	add	s1,s1,-1654 # 80240ef8 <log>
            sleep(&log, &log.lock);
        } else if (log.lh.n + (log.outstanding + 1) * MAXOPBLOCKS > LOGSIZE) {
    80203576:	4979                	li	s2,30
    80203578:	a039                	j	80203586 <begin_op+0x34>
            sleep(&log, &log.lock);
    8020357a:	85a6                	mv	a1,s1
    8020357c:	8526                	mv	a0,s1
    8020357e:	ffffe097          	auipc	ra,0xffffe
    80203582:	1b2080e7          	jalr	434(ra) # 80201730 <sleep>
        if (log.committing) {
    80203586:	50dc                	lw	a5,36(s1)
    80203588:	fbed                	bnez	a5,8020357a <begin_op+0x28>
        } else if (log.lh.n + (log.outstanding + 1) * MAXOPBLOCKS > LOGSIZE) {
    8020358a:	5098                	lw	a4,32(s1)
    8020358c:	2705                	addw	a4,a4,1
    8020358e:	0027179b          	sllw	a5,a4,0x2
    80203592:	9fb9                	addw	a5,a5,a4
    80203594:	0017979b          	sllw	a5,a5,0x1
    80203598:	54d4                	lw	a3,44(s1)
    8020359a:	9fb5                	addw	a5,a5,a3
    8020359c:	00f95963          	bge	s2,a5,802035ae <begin_op+0x5c>
            sleep(&log, &log.lock);
    802035a0:	85a6                	mv	a1,s1
    802035a2:	8526                	mv	a0,s1
    802035a4:	ffffe097          	auipc	ra,0xffffe
    802035a8:	18c080e7          	jalr	396(ra) # 80201730 <sleep>
    802035ac:	bfe9                	j	80203586 <begin_op+0x34>
        } else {
            log.outstanding += 1;
    802035ae:	0003e517          	auipc	a0,0x3e
    802035b2:	94a50513          	add	a0,a0,-1718 # 80240ef8 <log>
    802035b6:	d118                	sw	a4,32(a0)
            release(&log.lock);
    802035b8:	ffffd097          	auipc	ra,0xffffd
    802035bc:	374080e7          	jalr	884(ra) # 8020092c <release>
            break;
        }
    }
}
    802035c0:	60e2                	ld	ra,24(sp)
    802035c2:	6442                	ld	s0,16(sp)
    802035c4:	64a2                	ld	s1,8(sp)
    802035c6:	6902                	ld	s2,0(sp)
    802035c8:	6105                	add	sp,sp,32
    802035ca:	8082                	ret

00000000802035cc <end_op>:

void end_op(void) {
    802035cc:	7139                	add	sp,sp,-64
    802035ce:	fc06                	sd	ra,56(sp)
    802035d0:	f822                	sd	s0,48(sp)
    802035d2:	f426                	sd	s1,40(sp)
    802035d4:	f04a                	sd	s2,32(sp)
    802035d6:	ec4e                	sd	s3,24(sp)
    802035d8:	e852                	sd	s4,16(sp)
    802035da:	e456                	sd	s5,8(sp)
    802035dc:	0080                	add	s0,sp,64
    int do_commit = 0;

    acquire(&log.lock);
    802035de:	0003e497          	auipc	s1,0x3e
    802035e2:	91a48493          	add	s1,s1,-1766 # 80240ef8 <log>
    802035e6:	8526                	mv	a0,s1
    802035e8:	ffffd097          	auipc	ra,0xffffd
    802035ec:	252080e7          	jalr	594(ra) # 8020083a <acquire>
    log.outstanding--;
    802035f0:	509c                	lw	a5,32(s1)
    802035f2:	37fd                	addw	a5,a5,-1
    802035f4:	d09c                	sw	a5,32(s1)
    if (log.committing) {
    802035f6:	50dc                	lw	a5,36(s1)
    802035f8:	e3bd                	bnez	a5,8020365e <end_op+0x92>
        panic("log.committing");
    }
    if (log.outstanding == 0) {
    802035fa:	0003e917          	auipc	s2,0x3e
    802035fe:	91e92903          	lw	s2,-1762(s2) # 80240f18 <log+0x20>
    80203602:	06091763          	bnez	s2,80203670 <end_op+0xa4>
        do_commit = 1;
        log.committing = 1;
    80203606:	0003e497          	auipc	s1,0x3e
    8020360a:	8f248493          	add	s1,s1,-1806 # 80240ef8 <log>
    8020360e:	4785                	li	a5,1
    80203610:	d0dc                	sw	a5,36(s1)
    } else {
        wakeup(&log);
    }
    release(&log.lock);
    80203612:	8526                	mv	a0,s1
    80203614:	ffffd097          	auipc	ra,0xffffd
    80203618:	318080e7          	jalr	792(ra) # 8020092c <release>

    if (do_commit) {
        if (log.lh.n > 0) {
    8020361c:	54dc                	lw	a5,44(s1)
    8020361e:	06f04863          	bgtz	a5,8020368e <end_op+0xc2>
            write_log();
            install_trans(0);
            log.lh.n = 0;
            write_head();
        }
        acquire(&log.lock);
    80203622:	0003e497          	auipc	s1,0x3e
    80203626:	8d648493          	add	s1,s1,-1834 # 80240ef8 <log>
    8020362a:	8526                	mv	a0,s1
    8020362c:	ffffd097          	auipc	ra,0xffffd
    80203630:	20e080e7          	jalr	526(ra) # 8020083a <acquire>
        log.committing = 0;
    80203634:	0204a223          	sw	zero,36(s1)
        wakeup(&log);
    80203638:	8526                	mv	a0,s1
    8020363a:	ffffe097          	auipc	ra,0xffffe
    8020363e:	264080e7          	jalr	612(ra) # 8020189e <wakeup>
        release(&log.lock);
    80203642:	8526                	mv	a0,s1
    80203644:	ffffd097          	auipc	ra,0xffffd
    80203648:	2e8080e7          	jalr	744(ra) # 8020092c <release>
    }
}
    8020364c:	70e2                	ld	ra,56(sp)
    8020364e:	7442                	ld	s0,48(sp)
    80203650:	74a2                	ld	s1,40(sp)
    80203652:	7902                	ld	s2,32(sp)
    80203654:	69e2                	ld	s3,24(sp)
    80203656:	6a42                	ld	s4,16(sp)
    80203658:	6aa2                	ld	s5,8(sp)
    8020365a:	6121                	add	sp,sp,64
    8020365c:	8082                	ret
        panic("log.committing");
    8020365e:	00003517          	auipc	a0,0x3
    80203662:	22a50513          	add	a0,a0,554 # 80206888 <syscalls+0x2e8>
    80203666:	ffffd097          	auipc	ra,0xffffd
    8020366a:	d6e080e7          	jalr	-658(ra) # 802003d4 <panic>
    8020366e:	b771                	j	802035fa <end_op+0x2e>
        wakeup(&log);
    80203670:	0003e497          	auipc	s1,0x3e
    80203674:	88848493          	add	s1,s1,-1912 # 80240ef8 <log>
    80203678:	8526                	mv	a0,s1
    8020367a:	ffffe097          	auipc	ra,0xffffe
    8020367e:	224080e7          	jalr	548(ra) # 8020189e <wakeup>
    release(&log.lock);
    80203682:	8526                	mv	a0,s1
    80203684:	ffffd097          	auipc	ra,0xffffd
    80203688:	2a8080e7          	jalr	680(ra) # 8020092c <release>
    if (do_commit) {
    8020368c:	b7c1                	j	8020364c <end_op+0x80>

static void write_log(void) {
    for (int tail = 0; tail < log.lh.n; tail++) {
    8020368e:	0003ea97          	auipc	s5,0x3e
    80203692:	89aa8a93          	add	s5,s5,-1894 # 80240f28 <log+0x30>
        struct buf *to = bread(log.dev, log.start + tail + 1);
    80203696:	0003ea17          	auipc	s4,0x3e
    8020369a:	862a0a13          	add	s4,s4,-1950 # 80240ef8 <log>
    8020369e:	018a2583          	lw	a1,24(s4)
    802036a2:	012585bb          	addw	a1,a1,s2
    802036a6:	2585                	addw	a1,a1,1
    802036a8:	028a2503          	lw	a0,40(s4)
    802036ac:	fffff097          	auipc	ra,0xfffff
    802036b0:	848080e7          	jalr	-1976(ra) # 80201ef4 <bread>
    802036b4:	84aa                	mv	s1,a0
        struct buf *from = bread(log.dev, log.lh.block[tail]);
    802036b6:	000aa583          	lw	a1,0(s5)
    802036ba:	028a2503          	lw	a0,40(s4)
    802036be:	fffff097          	auipc	ra,0xfffff
    802036c2:	836080e7          	jalr	-1994(ra) # 80201ef4 <bread>
    802036c6:	89aa                	mv	s3,a0
        memmove(to->data, from->data, BSIZE);
    802036c8:	40000613          	li	a2,1024
    802036cc:	05850593          	add	a1,a0,88
    802036d0:	05848513          	add	a0,s1,88
    802036d4:	ffffd097          	auipc	ra,0xffffd
    802036d8:	2f0080e7          	jalr	752(ra) # 802009c4 <memmove>
        bwrite(to);
    802036dc:	8526                	mv	a0,s1
    802036de:	fffff097          	auipc	ra,0xfffff
    802036e2:	928080e7          	jalr	-1752(ra) # 80202006 <bwrite>
        brelse(from);
    802036e6:	854e                	mv	a0,s3
    802036e8:	fffff097          	auipc	ra,0xfffff
    802036ec:	95e080e7          	jalr	-1698(ra) # 80202046 <brelse>
        brelse(to);
    802036f0:	8526                	mv	a0,s1
    802036f2:	fffff097          	auipc	ra,0xfffff
    802036f6:	954080e7          	jalr	-1708(ra) # 80202046 <brelse>
    for (int tail = 0; tail < log.lh.n; tail++) {
    802036fa:	2905                	addw	s2,s2,1
    802036fc:	0a91                	add	s5,s5,4
    802036fe:	02ca2783          	lw	a5,44(s4)
    80203702:	f8f94ee3          	blt	s2,a5,8020369e <end_op+0xd2>
            install_trans(0);
    80203706:	4501                	li	a0,0
    80203708:	00000097          	auipc	ra,0x0
    8020370c:	cb6080e7          	jalr	-842(ra) # 802033be <install_trans>
            log.lh.n = 0;
    80203710:	0003e797          	auipc	a5,0x3e
    80203714:	8007aa23          	sw	zero,-2028(a5) # 80240f24 <log+0x2c>
            write_head();
    80203718:	00000097          	auipc	ra,0x0
    8020371c:	c50080e7          	jalr	-944(ra) # 80203368 <write_head>
    80203720:	b709                	j	80203622 <end_op+0x56>

0000000080203722 <log_write>:
    }
}

void log_write(struct buf *b) {
    80203722:	1101                	add	sp,sp,-32
    80203724:	ec06                	sd	ra,24(sp)
    80203726:	e822                	sd	s0,16(sp)
    80203728:	e426                	sd	s1,8(sp)
    8020372a:	e04a                	sd	s2,0(sp)
    8020372c:	1000                	add	s0,sp,32
    8020372e:	84aa                	mv	s1,a0
    if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1) {
    80203730:	0003d797          	auipc	a5,0x3d
    80203734:	7f47a783          	lw	a5,2036(a5) # 80240f24 <log+0x2c>
    80203738:	4775                	li	a4,29
    8020373a:	00f74963          	blt	a4,a5,8020374c <log_write+0x2a>
    8020373e:	0003d717          	auipc	a4,0x3d
    80203742:	7d672703          	lw	a4,2006(a4) # 80240f14 <log+0x1c>
    80203746:	377d                	addw	a4,a4,-1
    80203748:	00e7ca63          	blt	a5,a4,8020375c <log_write+0x3a>
        panic("log_write: too big");
    8020374c:	00003517          	auipc	a0,0x3
    80203750:	14c50513          	add	a0,a0,332 # 80206898 <syscalls+0x2f8>
    80203754:	ffffd097          	auipc	ra,0xffffd
    80203758:	c80080e7          	jalr	-896(ra) # 802003d4 <panic>
    }
    if (log.outstanding < 1) {
    8020375c:	0003d797          	auipc	a5,0x3d
    80203760:	7bc7a783          	lw	a5,1980(a5) # 80240f18 <log+0x20>
    80203764:	06f05163          	blez	a5,802037c6 <log_write+0xa4>
        panic("log_write outside trans");
    }

    acquire(&log.lock);
    80203768:	0003d917          	auipc	s2,0x3d
    8020376c:	79090913          	add	s2,s2,1936 # 80240ef8 <log>
    80203770:	854a                	mv	a0,s2
    80203772:	ffffd097          	auipc	ra,0xffffd
    80203776:	0c8080e7          	jalr	200(ra) # 8020083a <acquire>
    int i;
    for (i = 0; i < log.lh.n; i++) {
    8020377a:	02c92603          	lw	a2,44(s2)
    8020377e:	04c05d63          	blez	a2,802037d8 <log_write+0xb6>
        if (log.lh.block[i] == b->blockno) {
    80203782:	44cc                	lw	a1,12(s1)
    80203784:	0003d717          	auipc	a4,0x3d
    80203788:	7a470713          	add	a4,a4,1956 # 80240f28 <log+0x30>
    for (i = 0; i < log.lh.n; i++) {
    8020378c:	4781                	li	a5,0
        if (log.lh.block[i] == b->blockno) {
    8020378e:	4314                	lw	a3,0(a4)
    80203790:	04b68563          	beq	a3,a1,802037da <log_write+0xb8>
    for (i = 0; i < log.lh.n; i++) {
    80203794:	2785                	addw	a5,a5,1
    80203796:	0711                	add	a4,a4,4
    80203798:	fec79be3          	bne	a5,a2,8020378e <log_write+0x6c>
            break;
        }
    }
    log.lh.block[i] = b->blockno;
    8020379c:	00860713          	add	a4,a2,8 # 40008 <_start-0x801bfff8>
    802037a0:	070a                	sll	a4,a4,0x2
    802037a2:	0003d797          	auipc	a5,0x3d
    802037a6:	75678793          	add	a5,a5,1878 # 80240ef8 <log>
    802037aa:	97ba                	add	a5,a5,a4
    802037ac:	44d8                	lw	a4,12(s1)
    802037ae:	cb98                	sw	a4,16(a5)
    if (i == log.lh.n) {
        log.lh.n++;
    802037b0:	2605                	addw	a2,a2,1
    802037b2:	0003d797          	auipc	a5,0x3d
    802037b6:	76c7a923          	sw	a2,1906(a5) # 80240f24 <log+0x2c>
        bpin(b);
    802037ba:	8526                	mv	a0,s1
    802037bc:	fffff097          	auipc	ra,0xfffff
    802037c0:	928080e7          	jalr	-1752(ra) # 802020e4 <bpin>
    802037c4:	a03d                	j	802037f2 <log_write+0xd0>
        panic("log_write outside trans");
    802037c6:	00003517          	auipc	a0,0x3
    802037ca:	0ea50513          	add	a0,a0,234 # 802068b0 <syscalls+0x310>
    802037ce:	ffffd097          	auipc	ra,0xffffd
    802037d2:	c06080e7          	jalr	-1018(ra) # 802003d4 <panic>
    802037d6:	bf49                	j	80203768 <log_write+0x46>
    for (i = 0; i < log.lh.n; i++) {
    802037d8:	4781                	li	a5,0
    log.lh.block[i] = b->blockno;
    802037da:	00878693          	add	a3,a5,8
    802037de:	068a                	sll	a3,a3,0x2
    802037e0:	0003d717          	auipc	a4,0x3d
    802037e4:	71870713          	add	a4,a4,1816 # 80240ef8 <log>
    802037e8:	9736                	add	a4,a4,a3
    802037ea:	44d4                	lw	a3,12(s1)
    802037ec:	cb14                	sw	a3,16(a4)
    if (i == log.lh.n) {
    802037ee:	02f60063          	beq	a2,a5,8020380e <log_write+0xec>
    }
    release(&log.lock);
    802037f2:	0003d517          	auipc	a0,0x3d
    802037f6:	70650513          	add	a0,a0,1798 # 80240ef8 <log>
    802037fa:	ffffd097          	auipc	ra,0xffffd
    802037fe:	132080e7          	jalr	306(ra) # 8020092c <release>
}
    80203802:	60e2                	ld	ra,24(sp)
    80203804:	6442                	ld	s0,16(sp)
    80203806:	64a2                	ld	s1,8(sp)
    80203808:	6902                	ld	s2,0(sp)
    8020380a:	6105                	add	sp,sp,32
    8020380c:	8082                	ret
    8020380e:	863e                	mv	a2,a5
    80203810:	b745                	j	802037b0 <log_write+0x8e>

0000000080203812 <initsleeplock>:
#include "defs.h"
#include "sleeplock.h"

void initsleeplock(struct sleeplock *lk, char *name) {
    80203812:	1101                	add	sp,sp,-32
    80203814:	ec06                	sd	ra,24(sp)
    80203816:	e822                	sd	s0,16(sp)
    80203818:	e426                	sd	s1,8(sp)
    8020381a:	e04a                	sd	s2,0(sp)
    8020381c:	1000                	add	s0,sp,32
    8020381e:	84aa                	mv	s1,a0
    80203820:	892e                	mv	s2,a1
    spinlock_init(&lk->lk, "sleeplock");
    80203822:	00003597          	auipc	a1,0x3
    80203826:	0a658593          	add	a1,a1,166 # 802068c8 <syscalls+0x328>
    8020382a:	0521                	add	a0,a0,8
    8020382c:	ffffd097          	auipc	ra,0xffffd
    80203830:	fac080e7          	jalr	-84(ra) # 802007d8 <spinlock_init>
    lk->name = name;
    80203834:	0324b023          	sd	s2,32(s1)
    lk->locked = 0;
    80203838:	0004a023          	sw	zero,0(s1)
    lk->owner = 0;
    8020383c:	0204b423          	sd	zero,40(s1)
}
    80203840:	60e2                	ld	ra,24(sp)
    80203842:	6442                	ld	s0,16(sp)
    80203844:	64a2                	ld	s1,8(sp)
    80203846:	6902                	ld	s2,0(sp)
    80203848:	6105                	add	sp,sp,32
    8020384a:	8082                	ret

000000008020384c <acquiresleep>:

void acquiresleep(struct sleeplock *lk) {
    8020384c:	1101                	add	sp,sp,-32
    8020384e:	ec06                	sd	ra,24(sp)
    80203850:	e822                	sd	s0,16(sp)
    80203852:	e426                	sd	s1,8(sp)
    80203854:	e04a                	sd	s2,0(sp)
    80203856:	1000                	add	s0,sp,32
    80203858:	84aa                	mv	s1,a0
    acquire(&lk->lk);
    8020385a:	00850913          	add	s2,a0,8
    8020385e:	854a                	mv	a0,s2
    80203860:	ffffd097          	auipc	ra,0xffffd
    80203864:	fda080e7          	jalr	-38(ra) # 8020083a <acquire>
    while (lk->locked) {
    80203868:	409c                	lw	a5,0(s1)
    8020386a:	cb89                	beqz	a5,8020387c <acquiresleep+0x30>
        sleep(lk, &lk->lk);
    8020386c:	85ca                	mv	a1,s2
    8020386e:	8526                	mv	a0,s1
    80203870:	ffffe097          	auipc	ra,0xffffe
    80203874:	ec0080e7          	jalr	-320(ra) # 80201730 <sleep>
    while (lk->locked) {
    80203878:	409c                	lw	a5,0(s1)
    8020387a:	fbed                	bnez	a5,8020386c <acquiresleep+0x20>
    }
    lk->locked = 1;
    8020387c:	4785                	li	a5,1
    8020387e:	c09c                	sw	a5,0(s1)
    lk->owner = myproc();
    80203880:	ffffe097          	auipc	ra,0xffffe
    80203884:	b18080e7          	jalr	-1256(ra) # 80201398 <myproc>
    80203888:	f488                	sd	a0,40(s1)
    release(&lk->lk);
    8020388a:	854a                	mv	a0,s2
    8020388c:	ffffd097          	auipc	ra,0xffffd
    80203890:	0a0080e7          	jalr	160(ra) # 8020092c <release>
}
    80203894:	60e2                	ld	ra,24(sp)
    80203896:	6442                	ld	s0,16(sp)
    80203898:	64a2                	ld	s1,8(sp)
    8020389a:	6902                	ld	s2,0(sp)
    8020389c:	6105                	add	sp,sp,32
    8020389e:	8082                	ret

00000000802038a0 <releasesleep>:

void releasesleep(struct sleeplock *lk) {
    802038a0:	1101                	add	sp,sp,-32
    802038a2:	ec06                	sd	ra,24(sp)
    802038a4:	e822                	sd	s0,16(sp)
    802038a6:	e426                	sd	s1,8(sp)
    802038a8:	e04a                	sd	s2,0(sp)
    802038aa:	1000                	add	s0,sp,32
    802038ac:	84aa                	mv	s1,a0
    acquire(&lk->lk);
    802038ae:	00850913          	add	s2,a0,8
    802038b2:	854a                	mv	a0,s2
    802038b4:	ffffd097          	auipc	ra,0xffffd
    802038b8:	f86080e7          	jalr	-122(ra) # 8020083a <acquire>
    lk->locked = 0;
    802038bc:	0004a023          	sw	zero,0(s1)
    lk->owner = 0;
    802038c0:	0204b423          	sd	zero,40(s1)
    wakeup(lk);
    802038c4:	8526                	mv	a0,s1
    802038c6:	ffffe097          	auipc	ra,0xffffe
    802038ca:	fd8080e7          	jalr	-40(ra) # 8020189e <wakeup>
    release(&lk->lk);
    802038ce:	854a                	mv	a0,s2
    802038d0:	ffffd097          	auipc	ra,0xffffd
    802038d4:	05c080e7          	jalr	92(ra) # 8020092c <release>
}
    802038d8:	60e2                	ld	ra,24(sp)
    802038da:	6442                	ld	s0,16(sp)
    802038dc:	64a2                	ld	s1,8(sp)
    802038de:	6902                	ld	s2,0(sp)
    802038e0:	6105                	add	sp,sp,32
    802038e2:	8082                	ret

00000000802038e4 <holdingsleep>:

int holdingsleep(struct sleeplock *lk) {
    802038e4:	1101                	add	sp,sp,-32
    802038e6:	ec06                	sd	ra,24(sp)
    802038e8:	e822                	sd	s0,16(sp)
    802038ea:	e426                	sd	s1,8(sp)
    802038ec:	e04a                	sd	s2,0(sp)
    802038ee:	1000                	add	s0,sp,32
    802038f0:	84aa                	mv	s1,a0
    int r;

    acquire(&lk->lk);
    802038f2:	00850913          	add	s2,a0,8
    802038f6:	854a                	mv	a0,s2
    802038f8:	ffffd097          	auipc	ra,0xffffd
    802038fc:	f42080e7          	jalr	-190(ra) # 8020083a <acquire>
    r = lk->locked && lk->owner == myproc();
    80203900:	409c                	lw	a5,0(s1)
    80203902:	ef91                	bnez	a5,8020391e <holdingsleep+0x3a>
    80203904:	4481                	li	s1,0
    release(&lk->lk);
    80203906:	854a                	mv	a0,s2
    80203908:	ffffd097          	auipc	ra,0xffffd
    8020390c:	024080e7          	jalr	36(ra) # 8020092c <release>
    return r;
}
    80203910:	8526                	mv	a0,s1
    80203912:	60e2                	ld	ra,24(sp)
    80203914:	6442                	ld	s0,16(sp)
    80203916:	64a2                	ld	s1,8(sp)
    80203918:	6902                	ld	s2,0(sp)
    8020391a:	6105                	add	sp,sp,32
    8020391c:	8082                	ret
    r = lk->locked && lk->owner == myproc();
    8020391e:	7484                	ld	s1,40(s1)
    80203920:	ffffe097          	auipc	ra,0xffffe
    80203924:	a78080e7          	jalr	-1416(ra) # 80201398 <myproc>
    80203928:	8c89                	sub	s1,s1,a0
    8020392a:	0014b493          	seqz	s1,s1
    8020392e:	bfe1                	j	80203906 <holdingsleep+0x22>

0000000080203930 <fileinit>:
struct {
    struct spinlock lock;
    struct file file[NFILE];
} ftable;

void fileinit(void) {
    80203930:	1141                	add	sp,sp,-16
    80203932:	e406                	sd	ra,8(sp)
    80203934:	e022                	sd	s0,0(sp)
    80203936:	0800                	add	s0,sp,16
    spinlock_init(&ftable.lock, "ftable");
    80203938:	00003597          	auipc	a1,0x3
    8020393c:	fa058593          	add	a1,a1,-96 # 802068d8 <syscalls+0x338>
    80203940:	0003d517          	auipc	a0,0x3d
    80203944:	70050513          	add	a0,a0,1792 # 80241040 <ftable>
    80203948:	ffffd097          	auipc	ra,0xffffd
    8020394c:	e90080e7          	jalr	-368(ra) # 802007d8 <spinlock_init>
    devsw[CONSOLE].write = consolewrite;
    80203950:	0003d797          	auipc	a5,0x3d
    80203954:	65078793          	add	a5,a5,1616 # 80240fa0 <devsw>
    80203958:	ffffc717          	auipc	a4,0xffffc
    8020395c:	70e70713          	add	a4,a4,1806 # 80200066 <consolewrite>
    80203960:	ef98                	sd	a4,24(a5)
    devsw[CONSOLE].read = consoleread;
    80203962:	ffffc717          	auipc	a4,0xffffc
    80203966:	74070713          	add	a4,a4,1856 # 802000a2 <consoleread>
    8020396a:	eb98                	sd	a4,16(a5)
}
    8020396c:	60a2                	ld	ra,8(sp)
    8020396e:	6402                	ld	s0,0(sp)
    80203970:	0141                	add	sp,sp,16
    80203972:	8082                	ret

0000000080203974 <filealloc>:

struct file *filealloc(void) {
    80203974:	1101                	add	sp,sp,-32
    80203976:	ec06                	sd	ra,24(sp)
    80203978:	e822                	sd	s0,16(sp)
    8020397a:	e426                	sd	s1,8(sp)
    8020397c:	1000                	add	s0,sp,32
    acquire(&ftable.lock);
    8020397e:	0003d517          	auipc	a0,0x3d
    80203982:	6c250513          	add	a0,a0,1730 # 80241040 <ftable>
    80203986:	ffffd097          	auipc	ra,0xffffd
    8020398a:	eb4080e7          	jalr	-332(ra) # 8020083a <acquire>
    for (struct file *f = ftable.file; f < ftable.file + NFILE; f++) {
    8020398e:	0003d497          	auipc	s1,0x3d
    80203992:	6ca48493          	add	s1,s1,1738 # 80241058 <ftable+0x18>
    80203996:	0003e717          	auipc	a4,0x3e
    8020399a:	34270713          	add	a4,a4,834 # 80241cd8 <disk>
        if (f->ref == 0) {
    8020399e:	40dc                	lw	a5,4(s1)
    802039a0:	cf99                	beqz	a5,802039be <filealloc+0x4a>
    for (struct file *f = ftable.file; f < ftable.file + NFILE; f++) {
    802039a2:	02048493          	add	s1,s1,32
    802039a6:	fee49ce3          	bne	s1,a4,8020399e <filealloc+0x2a>
            f->ref = 1;
            release(&ftable.lock);
            return f;
        }
    }
    release(&ftable.lock);
    802039aa:	0003d517          	auipc	a0,0x3d
    802039ae:	69650513          	add	a0,a0,1686 # 80241040 <ftable>
    802039b2:	ffffd097          	auipc	ra,0xffffd
    802039b6:	f7a080e7          	jalr	-134(ra) # 8020092c <release>
    return 0;
    802039ba:	4481                	li	s1,0
    802039bc:	a819                	j	802039d2 <filealloc+0x5e>
            f->ref = 1;
    802039be:	4785                	li	a5,1
    802039c0:	c0dc                	sw	a5,4(s1)
            release(&ftable.lock);
    802039c2:	0003d517          	auipc	a0,0x3d
    802039c6:	67e50513          	add	a0,a0,1662 # 80241040 <ftable>
    802039ca:	ffffd097          	auipc	ra,0xffffd
    802039ce:	f62080e7          	jalr	-158(ra) # 8020092c <release>
}
    802039d2:	8526                	mv	a0,s1
    802039d4:	60e2                	ld	ra,24(sp)
    802039d6:	6442                	ld	s0,16(sp)
    802039d8:	64a2                	ld	s1,8(sp)
    802039da:	6105                	add	sp,sp,32
    802039dc:	8082                	ret

00000000802039de <filedup>:

struct file *filedup(struct file *f) {
    802039de:	1101                	add	sp,sp,-32
    802039e0:	ec06                	sd	ra,24(sp)
    802039e2:	e822                	sd	s0,16(sp)
    802039e4:	e426                	sd	s1,8(sp)
    802039e6:	1000                	add	s0,sp,32
    802039e8:	84aa                	mv	s1,a0
    acquire(&ftable.lock);
    802039ea:	0003d517          	auipc	a0,0x3d
    802039ee:	65650513          	add	a0,a0,1622 # 80241040 <ftable>
    802039f2:	ffffd097          	auipc	ra,0xffffd
    802039f6:	e48080e7          	jalr	-440(ra) # 8020083a <acquire>
    if (f->ref < 1) {
    802039fa:	40dc                	lw	a5,4(s1)
    802039fc:	02f05363          	blez	a5,80203a22 <filedup+0x44>
        panic("filedup");
    }
    f->ref++;
    80203a00:	40dc                	lw	a5,4(s1)
    80203a02:	2785                	addw	a5,a5,1
    80203a04:	c0dc                	sw	a5,4(s1)
    release(&ftable.lock);
    80203a06:	0003d517          	auipc	a0,0x3d
    80203a0a:	63a50513          	add	a0,a0,1594 # 80241040 <ftable>
    80203a0e:	ffffd097          	auipc	ra,0xffffd
    80203a12:	f1e080e7          	jalr	-226(ra) # 8020092c <release>
    return f;
}
    80203a16:	8526                	mv	a0,s1
    80203a18:	60e2                	ld	ra,24(sp)
    80203a1a:	6442                	ld	s0,16(sp)
    80203a1c:	64a2                	ld	s1,8(sp)
    80203a1e:	6105                	add	sp,sp,32
    80203a20:	8082                	ret
        panic("filedup");
    80203a22:	00003517          	auipc	a0,0x3
    80203a26:	ebe50513          	add	a0,a0,-322 # 802068e0 <syscalls+0x340>
    80203a2a:	ffffd097          	auipc	ra,0xffffd
    80203a2e:	9aa080e7          	jalr	-1622(ra) # 802003d4 <panic>
    80203a32:	b7f9                	j	80203a00 <filedup+0x22>

0000000080203a34 <fileclose>:

void fileclose(struct file *f) {
    80203a34:	7179                	add	sp,sp,-48
    80203a36:	f406                	sd	ra,40(sp)
    80203a38:	f022                	sd	s0,32(sp)
    80203a3a:	ec26                	sd	s1,24(sp)
    80203a3c:	e84a                	sd	s2,16(sp)
    80203a3e:	e44e                	sd	s3,8(sp)
    80203a40:	1800                	add	s0,sp,48
    80203a42:	84aa                	mv	s1,a0
    acquire(&ftable.lock);
    80203a44:	0003d517          	auipc	a0,0x3d
    80203a48:	5fc50513          	add	a0,a0,1532 # 80241040 <ftable>
    80203a4c:	ffffd097          	auipc	ra,0xffffd
    80203a50:	dee080e7          	jalr	-530(ra) # 8020083a <acquire>
    if (f->ref < 1) {
    80203a54:	40dc                	lw	a5,4(s1)
    80203a56:	04f05b63          	blez	a5,80203aac <fileclose+0x78>
        panic("fileclose");
    }
    f->ref--;
    80203a5a:	40dc                	lw	a5,4(s1)
    80203a5c:	37fd                	addw	a5,a5,-1
    80203a5e:	0007871b          	sext.w	a4,a5
    80203a62:	c0dc                	sw	a5,4(s1)
    if (f->ref > 0) {
    80203a64:	04e04d63          	bgtz	a4,80203abe <fileclose+0x8a>
        release(&ftable.lock);
        return;
    }
    int type = f->type;
    80203a68:	0004a903          	lw	s2,0(s1)
    struct inode *ip = f->ip;
    80203a6c:	0104b983          	ld	s3,16(s1)
    release(&ftable.lock);
    80203a70:	0003d517          	auipc	a0,0x3d
    80203a74:	5d050513          	add	a0,a0,1488 # 80241040 <ftable>
    80203a78:	ffffd097          	auipc	ra,0xffffd
    80203a7c:	eb4080e7          	jalr	-332(ra) # 8020092c <release>

    if (type == FD_INODE) {
    80203a80:	4785                	li	a5,1
    80203a82:	04f90763          	beq	s2,a5,80203ad0 <fileclose+0x9c>
        begin_op();
        iput(ip);
        end_op();
    }

    f->type = FD_NONE;
    80203a86:	0004a023          	sw	zero,0(s1)
    f->readable = 0;
    80203a8a:	00048423          	sb	zero,8(s1)
    f->writable = 0;
    80203a8e:	000484a3          	sb	zero,9(s1)
    f->ip = 0;
    80203a92:	0004b823          	sd	zero,16(s1)
    f->off = 0;
    80203a96:	0004ac23          	sw	zero,24(s1)
    f->major = 0;
    80203a9a:	00049e23          	sh	zero,28(s1)
}
    80203a9e:	70a2                	ld	ra,40(sp)
    80203aa0:	7402                	ld	s0,32(sp)
    80203aa2:	64e2                	ld	s1,24(sp)
    80203aa4:	6942                	ld	s2,16(sp)
    80203aa6:	69a2                	ld	s3,8(sp)
    80203aa8:	6145                	add	sp,sp,48
    80203aaa:	8082                	ret
        panic("fileclose");
    80203aac:	00003517          	auipc	a0,0x3
    80203ab0:	e3c50513          	add	a0,a0,-452 # 802068e8 <syscalls+0x348>
    80203ab4:	ffffd097          	auipc	ra,0xffffd
    80203ab8:	920080e7          	jalr	-1760(ra) # 802003d4 <panic>
    80203abc:	bf79                	j	80203a5a <fileclose+0x26>
        release(&ftable.lock);
    80203abe:	0003d517          	auipc	a0,0x3d
    80203ac2:	58250513          	add	a0,a0,1410 # 80241040 <ftable>
    80203ac6:	ffffd097          	auipc	ra,0xffffd
    80203aca:	e66080e7          	jalr	-410(ra) # 8020092c <release>
        return;
    80203ace:	bfc1                	j	80203a9e <fileclose+0x6a>
        begin_op();
    80203ad0:	00000097          	auipc	ra,0x0
    80203ad4:	a82080e7          	jalr	-1406(ra) # 80203552 <begin_op>
        iput(ip);
    80203ad8:	854e                	mv	a0,s3
    80203ada:	fffff097          	auipc	ra,0xfffff
    80203ade:	07c080e7          	jalr	124(ra) # 80202b56 <iput>
        end_op();
    80203ae2:	00000097          	auipc	ra,0x0
    80203ae6:	aea080e7          	jalr	-1302(ra) # 802035cc <end_op>
    80203aea:	bf71                	j	80203a86 <fileclose+0x52>

0000000080203aec <filestat>:

int filestat(struct file *f, uint64 addr) {
    if (f->type != FD_INODE) {
    80203aec:	4118                	lw	a4,0(a0)
    80203aee:	4785                	li	a5,1
    80203af0:	04f71163          	bne	a4,a5,80203b32 <filestat+0x46>
int filestat(struct file *f, uint64 addr) {
    80203af4:	1101                	add	sp,sp,-32
    80203af6:	ec06                	sd	ra,24(sp)
    80203af8:	e822                	sd	s0,16(sp)
    80203afa:	e426                	sd	s1,8(sp)
    80203afc:	e04a                	sd	s2,0(sp)
    80203afe:	1000                	add	s0,sp,32
    80203b00:	84aa                	mv	s1,a0
    80203b02:	892e                	mv	s2,a1
        return -1;
    }
    struct stat *st = (struct stat*)addr;
    ilock(f->ip);
    80203b04:	6908                	ld	a0,16(a0)
    80203b06:	fffff097          	auipc	ra,0xfffff
    80203b0a:	e10080e7          	jalr	-496(ra) # 80202916 <ilock>
    stati(f->ip, st);
    80203b0e:	85ca                	mv	a1,s2
    80203b10:	6888                	ld	a0,16(s1)
    80203b12:	fffff097          	auipc	ra,0xfffff
    80203b16:	0f4080e7          	jalr	244(ra) # 80202c06 <stati>
    iunlock(f->ip);
    80203b1a:	6888                	ld	a0,16(s1)
    80203b1c:	fffff097          	auipc	ra,0xfffff
    80203b20:	ec0080e7          	jalr	-320(ra) # 802029dc <iunlock>
    return 0;
    80203b24:	4501                	li	a0,0
}
    80203b26:	60e2                	ld	ra,24(sp)
    80203b28:	6442                	ld	s0,16(sp)
    80203b2a:	64a2                	ld	s1,8(sp)
    80203b2c:	6902                	ld	s2,0(sp)
    80203b2e:	6105                	add	sp,sp,32
    80203b30:	8082                	ret
        return -1;
    80203b32:	557d                	li	a0,-1
}
    80203b34:	8082                	ret

0000000080203b36 <fileread>:

int fileread(struct file *f, uint64 addr, int n) {
    80203b36:	7179                	add	sp,sp,-48
    80203b38:	f406                	sd	ra,40(sp)
    80203b3a:	f022                	sd	s0,32(sp)
    80203b3c:	ec26                	sd	s1,24(sp)
    80203b3e:	e84a                	sd	s2,16(sp)
    80203b40:	e44e                	sd	s3,8(sp)
    80203b42:	1800                	add	s0,sp,48
    if (!f->readable) {
    80203b44:	00854783          	lbu	a5,8(a0)
    80203b48:	c3c1                	beqz	a5,80203bc8 <fileread+0x92>
    80203b4a:	84aa                	mv	s1,a0
    80203b4c:	892e                	mv	s2,a1
    80203b4e:	89b2                	mv	s3,a2
        return -1;
    }
    if (f->type == FD_INODE) {
    80203b50:	411c                	lw	a5,0(a0)
    80203b52:	4705                	li	a4,1
    80203b54:	04e78063          	beq	a5,a4,80203b94 <fileread+0x5e>
        if (r > 0) {
            f->off += r;
        }
        iunlock(f->ip);
        return r;
    } else if (f->type == FD_DEVICE) {
    80203b58:	4709                	li	a4,2
    80203b5a:	06e79963          	bne	a5,a4,80203bcc <fileread+0x96>
        if (f->major < 0 || f->major >= NDEV || !devsw[f->major].read) {
    80203b5e:	01c51783          	lh	a5,28(a0)
    80203b62:	03079693          	sll	a3,a5,0x30
    80203b66:	92c1                	srl	a3,a3,0x30
    80203b68:	4725                	li	a4,9
    80203b6a:	06d76363          	bltu	a4,a3,80203bd0 <fileread+0x9a>
    80203b6e:	0792                	sll	a5,a5,0x4
    80203b70:	0003d697          	auipc	a3,0x3d
    80203b74:	43068693          	add	a3,a3,1072 # 80240fa0 <devsw>
    80203b78:	97b6                	add	a5,a5,a3
    80203b7a:	639c                	ld	a5,0(a5)
    80203b7c:	cfa1                	beqz	a5,80203bd4 <fileread+0x9e>
            return -1;
        }
        return devsw[f->major].read(1, addr, n);
    80203b7e:	4505                	li	a0,1
    80203b80:	9782                	jalr	a5
    80203b82:	892a                	mv	s2,a0
    }
    return -1;
}
    80203b84:	854a                	mv	a0,s2
    80203b86:	70a2                	ld	ra,40(sp)
    80203b88:	7402                	ld	s0,32(sp)
    80203b8a:	64e2                	ld	s1,24(sp)
    80203b8c:	6942                	ld	s2,16(sp)
    80203b8e:	69a2                	ld	s3,8(sp)
    80203b90:	6145                	add	sp,sp,48
    80203b92:	8082                	ret
        ilock(f->ip);
    80203b94:	6908                	ld	a0,16(a0)
    80203b96:	fffff097          	auipc	ra,0xfffff
    80203b9a:	d80080e7          	jalr	-640(ra) # 80202916 <ilock>
        int r = readi(f->ip, 0, addr, f->off, n);
    80203b9e:	874e                	mv	a4,s3
    80203ba0:	4c94                	lw	a3,24(s1)
    80203ba2:	864a                	mv	a2,s2
    80203ba4:	4581                	li	a1,0
    80203ba6:	6888                	ld	a0,16(s1)
    80203ba8:	fffff097          	auipc	ra,0xfffff
    80203bac:	08a080e7          	jalr	138(ra) # 80202c32 <readi>
    80203bb0:	892a                	mv	s2,a0
        if (r > 0) {
    80203bb2:	00a05563          	blez	a0,80203bbc <fileread+0x86>
            f->off += r;
    80203bb6:	4c9c                	lw	a5,24(s1)
    80203bb8:	9fa9                	addw	a5,a5,a0
    80203bba:	cc9c                	sw	a5,24(s1)
        iunlock(f->ip);
    80203bbc:	6888                	ld	a0,16(s1)
    80203bbe:	fffff097          	auipc	ra,0xfffff
    80203bc2:	e1e080e7          	jalr	-482(ra) # 802029dc <iunlock>
        return r;
    80203bc6:	bf7d                	j	80203b84 <fileread+0x4e>
        return -1;
    80203bc8:	597d                	li	s2,-1
    80203bca:	bf6d                	j	80203b84 <fileread+0x4e>
    return -1;
    80203bcc:	597d                	li	s2,-1
    80203bce:	bf5d                	j	80203b84 <fileread+0x4e>
            return -1;
    80203bd0:	597d                	li	s2,-1
    80203bd2:	bf4d                	j	80203b84 <fileread+0x4e>
    80203bd4:	597d                	li	s2,-1
    80203bd6:	b77d                	j	80203b84 <fileread+0x4e>

0000000080203bd8 <filewrite>:

int filewrite(struct file *f, uint64 addr, int n) {
    if (!f->writable) {
    80203bd8:	00954783          	lbu	a5,9(a0)
    80203bdc:	12078563          	beqz	a5,80203d06 <filewrite+0x12e>
int filewrite(struct file *f, uint64 addr, int n) {
    80203be0:	711d                	add	sp,sp,-96
    80203be2:	ec86                	sd	ra,88(sp)
    80203be4:	e8a2                	sd	s0,80(sp)
    80203be6:	e4a6                	sd	s1,72(sp)
    80203be8:	e0ca                	sd	s2,64(sp)
    80203bea:	fc4e                	sd	s3,56(sp)
    80203bec:	f852                	sd	s4,48(sp)
    80203bee:	f456                	sd	s5,40(sp)
    80203bf0:	f05a                	sd	s6,32(sp)
    80203bf2:	ec5e                	sd	s7,24(sp)
    80203bf4:	e862                	sd	s8,16(sp)
    80203bf6:	e466                	sd	s9,8(sp)
    80203bf8:	1080                	add	s0,sp,96
    80203bfa:	892a                	mv	s2,a0
    80203bfc:	8b2e                	mv	s6,a1
    80203bfe:	8a32                	mv	s4,a2
        return -1;
    }
    if (f->type == FD_DEVICE) {
    80203c00:	411c                	lw	a5,0(a0)
    80203c02:	4709                	li	a4,2
    80203c04:	02e78363          	beq	a5,a4,80203c2a <filewrite+0x52>
        if (f->major < 0 || f->major >= NDEV || !devsw[f->major].write) {
            return -1;
        }
        return devsw[f->major].write(1, addr, n);
    }
    if (f->type != FD_INODE) {
    80203c08:	4705                	li	a4,1
    80203c0a:	10e79463          	bne	a5,a4,80203d12 <filewrite+0x13a>
        return -1;
    }

    int max = ((MAXOPBLOCKS - 1 - 1 - 2) / 2) * BSIZE;
    int i = 0;
    while (i < n) {
    80203c0e:	0ec05a63          	blez	a2,80203d02 <filewrite+0x12a>
    int i = 0;
    80203c12:	4981                	li	s3,0
        int n1 = n - i;
        if (n1 > max) {
    80203c14:	6b85                	lui	s7,0x1
    80203c16:	c00b8b93          	add	s7,s7,-1024 # c00 <_start-0x801ff400>
    80203c1a:	6c05                	lui	s8,0x1
    80203c1c:	c00c0c1b          	addw	s8,s8,-1024 # c00 <_start-0x801ff400>
        end_op();
        if (r < 0) {
            break;
        }
        if (r != n1) {
            panic("short filewrite");
    80203c20:	00003c97          	auipc	s9,0x3
    80203c24:	cd8c8c93          	add	s9,s9,-808 # 802068f8 <syscalls+0x358>
    80203c28:	a0a5                	j	80203c90 <filewrite+0xb8>
        if (f->major < 0 || f->major >= NDEV || !devsw[f->major].write) {
    80203c2a:	01c51783          	lh	a5,28(a0)
    80203c2e:	03079693          	sll	a3,a5,0x30
    80203c32:	92c1                	srl	a3,a3,0x30
    80203c34:	4725                	li	a4,9
    80203c36:	0cd76a63          	bltu	a4,a3,80203d0a <filewrite+0x132>
    80203c3a:	0792                	sll	a5,a5,0x4
    80203c3c:	0003d717          	auipc	a4,0x3d
    80203c40:	36470713          	add	a4,a4,868 # 80240fa0 <devsw>
    80203c44:	97ba                	add	a5,a5,a4
    80203c46:	679c                	ld	a5,8(a5)
    80203c48:	c3f9                	beqz	a5,80203d0e <filewrite+0x136>
        return devsw[f->major].write(1, addr, n);
    80203c4a:	4505                	li	a0,1
    80203c4c:	9782                	jalr	a5
    80203c4e:	a005                	j	80203c6e <filewrite+0x96>
        iunlock(f->ip);
    80203c50:	01093503          	ld	a0,16(s2)
    80203c54:	fffff097          	auipc	ra,0xfffff
    80203c58:	d88080e7          	jalr	-632(ra) # 802029dc <iunlock>
        end_op();
    80203c5c:	00000097          	auipc	ra,0x0
    80203c60:	970080e7          	jalr	-1680(ra) # 802035cc <end_op>
        if (r < 0) {
    80203c64:	0804d763          	bgez	s1,80203cf2 <filewrite+0x11a>
        }
        i += r;
    }
    return i == n ? n : -1;
    80203c68:	0b3a1763          	bne	s4,s3,80203d16 <filewrite+0x13e>
    80203c6c:	8552                	mv	a0,s4
}
    80203c6e:	60e6                	ld	ra,88(sp)
    80203c70:	6446                	ld	s0,80(sp)
    80203c72:	64a6                	ld	s1,72(sp)
    80203c74:	6906                	ld	s2,64(sp)
    80203c76:	79e2                	ld	s3,56(sp)
    80203c78:	7a42                	ld	s4,48(sp)
    80203c7a:	7aa2                	ld	s5,40(sp)
    80203c7c:	7b02                	ld	s6,32(sp)
    80203c7e:	6be2                	ld	s7,24(sp)
    80203c80:	6c42                	ld	s8,16(sp)
    80203c82:	6ca2                	ld	s9,8(sp)
    80203c84:	6125                	add	sp,sp,96
    80203c86:	8082                	ret
        i += r;
    80203c88:	013489bb          	addw	s3,s1,s3
    while (i < n) {
    80203c8c:	fd49dee3          	bge	s3,s4,80203c68 <filewrite+0x90>
        int n1 = n - i;
    80203c90:	413a04bb          	subw	s1,s4,s3
        if (n1 > max) {
    80203c94:	0004879b          	sext.w	a5,s1
    80203c98:	00fbd363          	bge	s7,a5,80203c9e <filewrite+0xc6>
    80203c9c:	84e2                	mv	s1,s8
    80203c9e:	00048a9b          	sext.w	s5,s1
        begin_op();
    80203ca2:	00000097          	auipc	ra,0x0
    80203ca6:	8b0080e7          	jalr	-1872(ra) # 80203552 <begin_op>
        ilock(f->ip);
    80203caa:	01093503          	ld	a0,16(s2)
    80203cae:	fffff097          	auipc	ra,0xfffff
    80203cb2:	c68080e7          	jalr	-920(ra) # 80202916 <ilock>
        int r = writei(f->ip, 0, addr + i, f->off, n1);
    80203cb6:	8756                	mv	a4,s5
    80203cb8:	01892683          	lw	a3,24(s2)
    80203cbc:	01698633          	add	a2,s3,s6
    80203cc0:	4581                	li	a1,0
    80203cc2:	01093503          	ld	a0,16(s2)
    80203cc6:	fffff097          	auipc	ra,0xfffff
    80203cca:	04e080e7          	jalr	78(ra) # 80202d14 <writei>
    80203cce:	84aa                	mv	s1,a0
        if (r > 0) {
    80203cd0:	f8a050e3          	blez	a0,80203c50 <filewrite+0x78>
            f->off += r;
    80203cd4:	01892783          	lw	a5,24(s2)
    80203cd8:	9fa9                	addw	a5,a5,a0
    80203cda:	00f92c23          	sw	a5,24(s2)
        iunlock(f->ip);
    80203cde:	01093503          	ld	a0,16(s2)
    80203ce2:	fffff097          	auipc	ra,0xfffff
    80203ce6:	cfa080e7          	jalr	-774(ra) # 802029dc <iunlock>
        end_op();
    80203cea:	00000097          	auipc	ra,0x0
    80203cee:	8e2080e7          	jalr	-1822(ra) # 802035cc <end_op>
        if (r != n1) {
    80203cf2:	f89a8be3          	beq	s5,s1,80203c88 <filewrite+0xb0>
            panic("short filewrite");
    80203cf6:	8566                	mv	a0,s9
    80203cf8:	ffffc097          	auipc	ra,0xffffc
    80203cfc:	6dc080e7          	jalr	1756(ra) # 802003d4 <panic>
    80203d00:	b761                	j	80203c88 <filewrite+0xb0>
    int i = 0;
    80203d02:	4981                	li	s3,0
    80203d04:	b795                	j	80203c68 <filewrite+0x90>
        return -1;
    80203d06:	557d                	li	a0,-1
}
    80203d08:	8082                	ret
            return -1;
    80203d0a:	557d                	li	a0,-1
    80203d0c:	b78d                	j	80203c6e <filewrite+0x96>
    80203d0e:	557d                	li	a0,-1
    80203d10:	bfb9                	j	80203c6e <filewrite+0x96>
        return -1;
    80203d12:	557d                	li	a0,-1
    80203d14:	bfa9                	j	80203c6e <filewrite+0x96>
    return i == n ? n : -1;
    80203d16:	557d                	li	a0,-1
    80203d18:	bf99                	j	80203c6e <filewrite+0x96>

0000000080203d1a <argfd>:
    iunlockput(dp);

    return ip;
}

static int argfd(int n, int *pfd, struct file **pf) {
    80203d1a:	7179                	add	sp,sp,-48
    80203d1c:	f406                	sd	ra,40(sp)
    80203d1e:	f022                	sd	s0,32(sp)
    80203d20:	ec26                	sd	s1,24(sp)
    80203d22:	e84a                	sd	s2,16(sp)
    80203d24:	1800                	add	s0,sp,48
    80203d26:	892e                	mv	s2,a1
    80203d28:	84b2                	mv	s1,a2
    int fd;
    struct file *f;
    if (argint(n, &fd) < 0)
    80203d2a:	fdc40593          	add	a1,s0,-36
    80203d2e:	ffffe097          	auipc	ra,0xffffe
    80203d32:	e8e080e7          	jalr	-370(ra) # 80201bbc <argint>
    80203d36:	04054063          	bltz	a0,80203d76 <argfd+0x5c>
        return -1;
    if (fd < 0 || fd >= NOFILE || (f = myproc()->ofile[fd]) == 0)
    80203d3a:	fdc42703          	lw	a4,-36(s0)
    80203d3e:	47bd                	li	a5,15
    80203d40:	02e7ed63          	bltu	a5,a4,80203d7a <argfd+0x60>
    80203d44:	ffffd097          	auipc	ra,0xffffd
    80203d48:	654080e7          	jalr	1620(ra) # 80201398 <myproc>
    80203d4c:	fdc42703          	lw	a4,-36(s0)
    80203d50:	01a70793          	add	a5,a4,26
    80203d54:	078e                	sll	a5,a5,0x3
    80203d56:	953e                	add	a0,a0,a5
    80203d58:	651c                	ld	a5,8(a0)
    80203d5a:	c395                	beqz	a5,80203d7e <argfd+0x64>
        return -1;
    if (pfd)
    80203d5c:	00090463          	beqz	s2,80203d64 <argfd+0x4a>
        *pfd = fd;
    80203d60:	00e92023          	sw	a4,0(s2)
    if (pf)
        *pf = f;
    return 0;
    80203d64:	4501                	li	a0,0
    if (pf)
    80203d66:	c091                	beqz	s1,80203d6a <argfd+0x50>
        *pf = f;
    80203d68:	e09c                	sd	a5,0(s1)
}
    80203d6a:	70a2                	ld	ra,40(sp)
    80203d6c:	7402                	ld	s0,32(sp)
    80203d6e:	64e2                	ld	s1,24(sp)
    80203d70:	6942                	ld	s2,16(sp)
    80203d72:	6145                	add	sp,sp,48
    80203d74:	8082                	ret
        return -1;
    80203d76:	557d                	li	a0,-1
    80203d78:	bfcd                	j	80203d6a <argfd+0x50>
        return -1;
    80203d7a:	557d                	li	a0,-1
    80203d7c:	b7fd                	j	80203d6a <argfd+0x50>
    80203d7e:	557d                	li	a0,-1
    80203d80:	b7ed                	j	80203d6a <argfd+0x50>

0000000080203d82 <fdalloc>:

static int fdalloc(struct file *f) {
    80203d82:	1101                	add	sp,sp,-32
    80203d84:	ec06                	sd	ra,24(sp)
    80203d86:	e822                	sd	s0,16(sp)
    80203d88:	e426                	sd	s1,8(sp)
    80203d8a:	1000                	add	s0,sp,32
    80203d8c:	84aa                	mv	s1,a0
    struct proc *p = myproc();
    80203d8e:	ffffd097          	auipc	ra,0xffffd
    80203d92:	60a080e7          	jalr	1546(ra) # 80201398 <myproc>
    80203d96:	862a                	mv	a2,a0
    for (int fd = 0; fd < NOFILE; fd++) {
    80203d98:	0d850793          	add	a5,a0,216
    80203d9c:	4501                	li	a0,0
    80203d9e:	46c1                	li	a3,16
        if (p->ofile[fd] == 0) {
    80203da0:	6398                	ld	a4,0(a5)
    80203da2:	cb19                	beqz	a4,80203db8 <fdalloc+0x36>
    for (int fd = 0; fd < NOFILE; fd++) {
    80203da4:	2505                	addw	a0,a0,1
    80203da6:	07a1                	add	a5,a5,8
    80203da8:	fed51ce3          	bne	a0,a3,80203da0 <fdalloc+0x1e>
            p->ofile[fd] = f;
            return fd;
        }
    }
    return -1;
    80203dac:	557d                	li	a0,-1
}
    80203dae:	60e2                	ld	ra,24(sp)
    80203db0:	6442                	ld	s0,16(sp)
    80203db2:	64a2                	ld	s1,8(sp)
    80203db4:	6105                	add	sp,sp,32
    80203db6:	8082                	ret
            p->ofile[fd] = f;
    80203db8:	01a50793          	add	a5,a0,26
    80203dbc:	078e                	sll	a5,a5,0x3
    80203dbe:	963e                	add	a2,a2,a5
    80203dc0:	e604                	sd	s1,8(a2)
            return fd;
    80203dc2:	b7f5                	j	80203dae <fdalloc+0x2c>

0000000080203dc4 <validate_addr>:
    if (len < 0) return 0;
    80203dc4:	0405c963          	bltz	a1,80203e16 <validate_addr+0x52>
static int validate_addr(uint64 va, int len) {
    80203dc8:	7179                	add	sp,sp,-48
    80203dca:	f406                	sd	ra,40(sp)
    80203dcc:	f022                	sd	s0,32(sp)
    80203dce:	ec26                	sd	s1,24(sp)
    80203dd0:	e84a                	sd	s2,16(sp)
    80203dd2:	e44e                	sd	s3,8(sp)
    80203dd4:	e052                	sd	s4,0(sp)
    80203dd6:	1800                	add	s0,sp,48
    80203dd8:	84aa                	mv	s1,a0
    uint64 end = va + len;
    80203dda:	00a58933          	add	s2,a1,a0
    if (end < start) return 0;
    80203dde:	4501                	li	a0,0
    80203de0:	04996063          	bltu	s2,s1,80203e20 <validate_addr+0x5c>
    for (uint64 a = PGROUNDDOWN(start); a < end; a += PGSIZE) {
    80203de4:	77fd                	lui	a5,0xfffff
    80203de6:	8cfd                	and	s1,s1,a5
    80203de8:	0324f963          	bgeu	s1,s2,80203e1a <validate_addr+0x56>
        pte_t *pte = walk_lookup(kernel_pagetable, a);
    80203dec:	0000c997          	auipc	s3,0xc
    80203df0:	21498993          	add	s3,s3,532 # 80210000 <kernel_pagetable>
    for (uint64 a = PGROUNDDOWN(start); a < end; a += PGSIZE) {
    80203df4:	6a05                	lui	s4,0x1
        pte_t *pte = walk_lookup(kernel_pagetable, a);
    80203df6:	85a6                	mv	a1,s1
    80203df8:	0009b503          	ld	a0,0(s3)
    80203dfc:	ffffd097          	auipc	ra,0xffffd
    80203e00:	fb6080e7          	jalr	-74(ra) # 80200db2 <walk_lookup>
        if (pte == 0 || (*pte & PTE_V) == 0) {
    80203e04:	cd09                	beqz	a0,80203e1e <validate_addr+0x5a>
    80203e06:	611c                	ld	a5,0(a0)
    80203e08:	8b85                	and	a5,a5,1
    80203e0a:	c39d                	beqz	a5,80203e30 <validate_addr+0x6c>
    for (uint64 a = PGROUNDDOWN(start); a < end; a += PGSIZE) {
    80203e0c:	94d2                	add	s1,s1,s4
    80203e0e:	ff24e4e3          	bltu	s1,s2,80203df6 <validate_addr+0x32>
    return 1;
    80203e12:	4505                	li	a0,1
    80203e14:	a031                	j	80203e20 <validate_addr+0x5c>
    if (len < 0) return 0;
    80203e16:	4501                	li	a0,0
}
    80203e18:	8082                	ret
    return 1;
    80203e1a:	4505                	li	a0,1
    80203e1c:	a011                	j	80203e20 <validate_addr+0x5c>
            return 0;
    80203e1e:	4501                	li	a0,0
}
    80203e20:	70a2                	ld	ra,40(sp)
    80203e22:	7402                	ld	s0,32(sp)
    80203e24:	64e2                	ld	s1,24(sp)
    80203e26:	6942                	ld	s2,16(sp)
    80203e28:	69a2                	ld	s3,8(sp)
    80203e2a:	6a02                	ld	s4,0(sp)
    80203e2c:	6145                	add	sp,sp,48
    80203e2e:	8082                	ret
            return 0;
    80203e30:	4501                	li	a0,0
    80203e32:	b7fd                	j	80203e20 <validate_addr+0x5c>

0000000080203e34 <create>:
static struct inode *create(char *path, short type, short major, short minor) {
    80203e34:	715d                	add	sp,sp,-80
    80203e36:	e486                	sd	ra,72(sp)
    80203e38:	e0a2                	sd	s0,64(sp)
    80203e3a:	fc26                	sd	s1,56(sp)
    80203e3c:	f84a                	sd	s2,48(sp)
    80203e3e:	f44e                	sd	s3,40(sp)
    80203e40:	f052                	sd	s4,32(sp)
    80203e42:	ec56                	sd	s5,24(sp)
    80203e44:	0880                	add	s0,sp,80
    80203e46:	84aa                	mv	s1,a0
    80203e48:	8a2e                	mv	s4,a1
    80203e4a:	89b2                	mv	s3,a2
    80203e4c:	8936                	mv	s2,a3
    if ((dp = nameiparent(path, name)) == 0) {
    80203e4e:	fb040593          	add	a1,s0,-80
    80203e52:	fffff097          	auipc	ra,0xfffff
    80203e56:	2fc080e7          	jalr	764(ra) # 8020314e <nameiparent>
    80203e5a:	8aaa                	mv	s5,a0
    80203e5c:	c125                	beqz	a0,80203ebc <create+0x88>
    ilock(dp);
    80203e5e:	fffff097          	auipc	ra,0xfffff
    80203e62:	ab8080e7          	jalr	-1352(ra) # 80202916 <ilock>
    if ((ip = dirlookup(dp, name, 0)) != 0) {
    80203e66:	4601                	li	a2,0
    80203e68:	fb040593          	add	a1,s0,-80
    80203e6c:	8556                	mv	a0,s5
    80203e6e:	fffff097          	auipc	ra,0xfffff
    80203e72:	fdc080e7          	jalr	-36(ra) # 80202e4a <dirlookup>
    80203e76:	84aa                	mv	s1,a0
    80203e78:	cd29                	beqz	a0,80203ed2 <create+0x9e>
        iunlockput(dp);
    80203e7a:	8556                	mv	a0,s5
    80203e7c:	fffff097          	auipc	ra,0xfffff
    80203e80:	d62080e7          	jalr	-670(ra) # 80202bde <iunlockput>
        ilock(ip);
    80203e84:	8526                	mv	a0,s1
    80203e86:	fffff097          	auipc	ra,0xfffff
    80203e8a:	a90080e7          	jalr	-1392(ra) # 80202916 <ilock>
        if (type == T_FILE && ip->type == T_FILE)
    80203e8e:	4789                	li	a5,2
    80203e90:	00fa1663          	bne	s4,a5,80203e9c <create+0x68>
    80203e94:	04449703          	lh	a4,68(s1)
    80203e98:	00f70863          	beq	a4,a5,80203ea8 <create+0x74>
        iunlockput(ip);
    80203e9c:	8526                	mv	a0,s1
    80203e9e:	fffff097          	auipc	ra,0xfffff
    80203ea2:	d40080e7          	jalr	-704(ra) # 80202bde <iunlockput>
        return 0;
    80203ea6:	4481                	li	s1,0
}
    80203ea8:	8526                	mv	a0,s1
    80203eaa:	60a6                	ld	ra,72(sp)
    80203eac:	6406                	ld	s0,64(sp)
    80203eae:	74e2                	ld	s1,56(sp)
    80203eb0:	7942                	ld	s2,48(sp)
    80203eb2:	79a2                	ld	s3,40(sp)
    80203eb4:	7a02                	ld	s4,32(sp)
    80203eb6:	6ae2                	ld	s5,24(sp)
    80203eb8:	6161                	add	sp,sp,80
    80203eba:	8082                	ret
        printf("create: nameiparent failed for %s\n", path); // DEBUG
    80203ebc:	85a6                	mv	a1,s1
    80203ebe:	00003517          	auipc	a0,0x3
    80203ec2:	a4a50513          	add	a0,a0,-1462 # 80206908 <syscalls+0x368>
    80203ec6:	ffffc097          	auipc	ra,0xffffc
    80203eca:	28e080e7          	jalr	654(ra) # 80200154 <printf>
        return 0;
    80203ece:	84d6                	mv	s1,s5
    80203ed0:	bfe1                	j	80203ea8 <create+0x74>
    if ((ip = ialloc(dp->dev, type)) == 0)
    80203ed2:	85d2                	mv	a1,s4
    80203ed4:	000aa503          	lw	a0,0(s5)
    80203ed8:	fffff097          	auipc	ra,0xfffff
    80203edc:	93a080e7          	jalr	-1734(ra) # 80202812 <ialloc>
    80203ee0:	84aa                	mv	s1,a0
    80203ee2:	c521                	beqz	a0,80203f2a <create+0xf6>
    ilock(ip);
    80203ee4:	8526                	mv	a0,s1
    80203ee6:	fffff097          	auipc	ra,0xfffff
    80203eea:	a30080e7          	jalr	-1488(ra) # 80202916 <ilock>
    ip->major = major;
    80203eee:	05349323          	sh	s3,70(s1)
    ip->minor = minor;
    80203ef2:	05249423          	sh	s2,72(s1)
    ip->nlink = 1;
    80203ef6:	4905                	li	s2,1
    80203ef8:	05249523          	sh	s2,74(s1)
    iupdate(ip);
    80203efc:	8526                	mv	a0,s1
    80203efe:	fffff097          	auipc	ra,0xfffff
    80203f02:	b1e080e7          	jalr	-1250(ra) # 80202a1c <iupdate>
    if (type == T_DIR) {
    80203f06:	032a0b63          	beq	s4,s2,80203f3c <create+0x108>
    if (dirlink(dp, name, ip->inum) < 0)
    80203f0a:	40d0                	lw	a2,4(s1)
    80203f0c:	fb040593          	add	a1,s0,-80
    80203f10:	8556                	mv	a0,s5
    80203f12:	fffff097          	auipc	ra,0xfffff
    80203f16:	ff6080e7          	jalr	-10(ra) # 80202f08 <dirlink>
    80203f1a:	06054d63          	bltz	a0,80203f94 <create+0x160>
    iunlockput(dp);
    80203f1e:	8556                	mv	a0,s5
    80203f20:	fffff097          	auipc	ra,0xfffff
    80203f24:	cbe080e7          	jalr	-834(ra) # 80202bde <iunlockput>
    return ip;
    80203f28:	b741                	j	80203ea8 <create+0x74>
        panic("create: ialloc");
    80203f2a:	00003517          	auipc	a0,0x3
    80203f2e:	a0650513          	add	a0,a0,-1530 # 80206930 <syscalls+0x390>
    80203f32:	ffffc097          	auipc	ra,0xffffc
    80203f36:	4a2080e7          	jalr	1186(ra) # 802003d4 <panic>
    80203f3a:	b76d                	j	80203ee4 <create+0xb0>
        dp->nlink++;  
    80203f3c:	04aad783          	lhu	a5,74(s5)
    80203f40:	2785                	addw	a5,a5,1 # fffffffffffff001 <__bss_end+0xffffffff7fdbd1e1>
    80203f42:	04fa9523          	sh	a5,74(s5)
        iupdate(dp);
    80203f46:	8556                	mv	a0,s5
    80203f48:	fffff097          	auipc	ra,0xfffff
    80203f4c:	ad4080e7          	jalr	-1324(ra) # 80202a1c <iupdate>
        if (dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80203f50:	40d0                	lw	a2,4(s1)
    80203f52:	00003597          	auipc	a1,0x3
    80203f56:	82658593          	add	a1,a1,-2010 # 80206778 <syscalls+0x1d8>
    80203f5a:	8526                	mv	a0,s1
    80203f5c:	fffff097          	auipc	ra,0xfffff
    80203f60:	fac080e7          	jalr	-84(ra) # 80202f08 <dirlink>
    80203f64:	00054f63          	bltz	a0,80203f82 <create+0x14e>
    80203f68:	004aa603          	lw	a2,4(s5)
    80203f6c:	00003597          	auipc	a1,0x3
    80203f70:	81458593          	add	a1,a1,-2028 # 80206780 <syscalls+0x1e0>
    80203f74:	8526                	mv	a0,s1
    80203f76:	fffff097          	auipc	ra,0xfffff
    80203f7a:	f92080e7          	jalr	-110(ra) # 80202f08 <dirlink>
    80203f7e:	f80556e3          	bgez	a0,80203f0a <create+0xd6>
            panic("create dots");
    80203f82:	00003517          	auipc	a0,0x3
    80203f86:	9be50513          	add	a0,a0,-1602 # 80206940 <syscalls+0x3a0>
    80203f8a:	ffffc097          	auipc	ra,0xffffc
    80203f8e:	44a080e7          	jalr	1098(ra) # 802003d4 <panic>
    80203f92:	bfa5                	j	80203f0a <create+0xd6>
        panic("create: dirlink");
    80203f94:	00003517          	auipc	a0,0x3
    80203f98:	9bc50513          	add	a0,a0,-1604 # 80206950 <syscalls+0x3b0>
    80203f9c:	ffffc097          	auipc	ra,0xffffc
    80203fa0:	438080e7          	jalr	1080(ra) # 802003d4 <panic>
    80203fa4:	bfad                	j	80203f1e <create+0xea>

0000000080203fa6 <sys_dup>:

int sys_dup(void) {
    80203fa6:	7179                	add	sp,sp,-48
    80203fa8:	f406                	sd	ra,40(sp)
    80203faa:	f022                	sd	s0,32(sp)
    80203fac:	ec26                	sd	s1,24(sp)
    80203fae:	e84a                	sd	s2,16(sp)
    80203fb0:	1800                	add	s0,sp,48
    struct file *f;
    if (argfd(0, 0, &f) < 0)
    80203fb2:	fd840613          	add	a2,s0,-40
    80203fb6:	4581                	li	a1,0
    80203fb8:	4501                	li	a0,0
    80203fba:	00000097          	auipc	ra,0x0
    80203fbe:	d60080e7          	jalr	-672(ra) # 80203d1a <argfd>
    80203fc2:	02054863          	bltz	a0,80203ff2 <sys_dup+0x4c>
        return -1;
    int fd = fdalloc(f);
    80203fc6:	fd843903          	ld	s2,-40(s0)
    80203fca:	854a                	mv	a0,s2
    80203fcc:	00000097          	auipc	ra,0x0
    80203fd0:	db6080e7          	jalr	-586(ra) # 80203d82 <fdalloc>
    80203fd4:	84aa                	mv	s1,a0
    if (fd < 0)
    80203fd6:	02054063          	bltz	a0,80203ff6 <sys_dup+0x50>
        return -1;
    filedup(f);
    80203fda:	854a                	mv	a0,s2
    80203fdc:	00000097          	auipc	ra,0x0
    80203fe0:	a02080e7          	jalr	-1534(ra) # 802039de <filedup>
    return fd;
}
    80203fe4:	8526                	mv	a0,s1
    80203fe6:	70a2                	ld	ra,40(sp)
    80203fe8:	7402                	ld	s0,32(sp)
    80203fea:	64e2                	ld	s1,24(sp)
    80203fec:	6942                	ld	s2,16(sp)
    80203fee:	6145                	add	sp,sp,48
    80203ff0:	8082                	ret
        return -1;
    80203ff2:	54fd                	li	s1,-1
    80203ff4:	bfc5                	j	80203fe4 <sys_dup+0x3e>
        return -1;
    80203ff6:	54fd                	li	s1,-1
    80203ff8:	b7f5                	j	80203fe4 <sys_dup+0x3e>

0000000080203ffa <sys_read>:

int sys_read(void) {
    80203ffa:	7179                	add	sp,sp,-48
    80203ffc:	f406                	sd	ra,40(sp)
    80203ffe:	f022                	sd	s0,32(sp)
    80204000:	1800                	add	s0,sp,48
    struct file *f;
    uint64 p;
    int n;
    if (argfd(0, 0, &f) < 0 || argaddr(1, &p) < 0 || argint(2, &n) < 0)
    80204002:	fe840613          	add	a2,s0,-24
    80204006:	4581                	li	a1,0
    80204008:	4501                	li	a0,0
    8020400a:	00000097          	auipc	ra,0x0
    8020400e:	d10080e7          	jalr	-752(ra) # 80203d1a <argfd>
    80204012:	04054263          	bltz	a0,80204056 <sys_read+0x5c>
    80204016:	fe040593          	add	a1,s0,-32
    8020401a:	4505                	li	a0,1
    8020401c:	ffffe097          	auipc	ra,0xffffe
    80204020:	c2a080e7          	jalr	-982(ra) # 80201c46 <argaddr>
    80204024:	02054b63          	bltz	a0,8020405a <sys_read+0x60>
    80204028:	fdc40593          	add	a1,s0,-36
    8020402c:	4509                	li	a0,2
    8020402e:	ffffe097          	auipc	ra,0xffffe
    80204032:	b8e080e7          	jalr	-1138(ra) # 80201bbc <argint>
    80204036:	02054463          	bltz	a0,8020405e <sys_read+0x64>
        return -1;
    return fileread(f, p, n);
    8020403a:	fdc42603          	lw	a2,-36(s0)
    8020403e:	fe043583          	ld	a1,-32(s0)
    80204042:	fe843503          	ld	a0,-24(s0)
    80204046:	00000097          	auipc	ra,0x0
    8020404a:	af0080e7          	jalr	-1296(ra) # 80203b36 <fileread>
}
    8020404e:	70a2                	ld	ra,40(sp)
    80204050:	7402                	ld	s0,32(sp)
    80204052:	6145                	add	sp,sp,48
    80204054:	8082                	ret
        return -1;
    80204056:	557d                	li	a0,-1
    80204058:	bfdd                	j	8020404e <sys_read+0x54>
    8020405a:	557d                	li	a0,-1
    8020405c:	bfcd                	j	8020404e <sys_read+0x54>
    8020405e:	557d                	li	a0,-1
    80204060:	b7fd                	j	8020404e <sys_read+0x54>

0000000080204062 <sys_write>:

int sys_write(void) {
    80204062:	7139                	add	sp,sp,-64
    80204064:	fc06                	sd	ra,56(sp)
    80204066:	f822                	sd	s0,48(sp)
    80204068:	f426                	sd	s1,40(sp)
    8020406a:	f04a                	sd	s2,32(sp)
    8020406c:	0080                	add	s0,sp,64
    struct file *f;
    uint64 p;
    int n;
    int fd;

    if (argint(0, &fd) < 0) return -1;
    8020406e:	fc840593          	add	a1,s0,-56
    80204072:	4501                	li	a0,0
    80204074:	ffffe097          	auipc	ra,0xffffe
    80204078:	b48080e7          	jalr	-1208(ra) # 80201bbc <argint>
    8020407c:	0e054a63          	bltz	a0,80204170 <sys_write+0x10e>

    if ((fd == 1 || fd == 2) && myproc()->ofile[fd] == 0) {
    80204080:	fc842783          	lw	a5,-56(s0)
    80204084:	37fd                	addw	a5,a5,-1
    80204086:	4705                	li	a4,1
    80204088:	06f77763          	bgeu	a4,a5,802040f6 <sys_write+0x94>
            cons_putc(s[i]);
        }
        return n;
    }

    if (argfd(0, 0, &f) < 0 || argaddr(1, &p) < 0 || argint(2, &n) < 0)
    8020408c:	fd840613          	add	a2,s0,-40
    80204090:	4581                	li	a1,0
    80204092:	4501                	li	a0,0
    80204094:	00000097          	auipc	ra,0x0
    80204098:	c86080e7          	jalr	-890(ra) # 80203d1a <argfd>
    8020409c:	0e054263          	bltz	a0,80204180 <sys_write+0x11e>
    802040a0:	fd040593          	add	a1,s0,-48
    802040a4:	4505                	li	a0,1
    802040a6:	ffffe097          	auipc	ra,0xffffe
    802040aa:	ba0080e7          	jalr	-1120(ra) # 80201c46 <argaddr>
    802040ae:	0c054b63          	bltz	a0,80204184 <sys_write+0x122>
    802040b2:	fcc40593          	add	a1,s0,-52
    802040b6:	4509                	li	a0,2
    802040b8:	ffffe097          	auipc	ra,0xffffe
    802040bc:	b04080e7          	jalr	-1276(ra) # 80201bbc <argint>
    802040c0:	0c054463          	bltz	a0,80204188 <sys_write+0x126>
        return -1;
    
    if (!validate_addr(p, n)) {
    802040c4:	fcc42583          	lw	a1,-52(s0)
    802040c8:	fd043503          	ld	a0,-48(s0)
    802040cc:	00000097          	auipc	ra,0x0
    802040d0:	cf8080e7          	jalr	-776(ra) # 80203dc4 <validate_addr>
    802040d4:	cd45                	beqz	a0,8020418c <sys_write+0x12a>
        return -1;
    }

    return filewrite(f, p, n);
    802040d6:	fcc42603          	lw	a2,-52(s0)
    802040da:	fd043583          	ld	a1,-48(s0)
    802040de:	fd843503          	ld	a0,-40(s0)
    802040e2:	00000097          	auipc	ra,0x0
    802040e6:	af6080e7          	jalr	-1290(ra) # 80203bd8 <filewrite>
}
    802040ea:	70e2                	ld	ra,56(sp)
    802040ec:	7442                	ld	s0,48(sp)
    802040ee:	74a2                	ld	s1,40(sp)
    802040f0:	7902                	ld	s2,32(sp)
    802040f2:	6121                	add	sp,sp,64
    802040f4:	8082                	ret
    if ((fd == 1 || fd == 2) && myproc()->ofile[fd] == 0) {
    802040f6:	ffffd097          	auipc	ra,0xffffd
    802040fa:	2a2080e7          	jalr	674(ra) # 80201398 <myproc>
    802040fe:	fc842783          	lw	a5,-56(s0)
    80204102:	07e9                	add	a5,a5,26
    80204104:	078e                	sll	a5,a5,0x3
    80204106:	953e                	add	a0,a0,a5
    80204108:	651c                	ld	a5,8(a0)
    8020410a:	f3c9                	bnez	a5,8020408c <sys_write+0x2a>
        if (argaddr(1, &p) < 0 || argint(2, &n) < 0) return -1;
    8020410c:	fd040593          	add	a1,s0,-48
    80204110:	4505                	li	a0,1
    80204112:	ffffe097          	auipc	ra,0xffffe
    80204116:	b34080e7          	jalr	-1228(ra) # 80201c46 <argaddr>
    8020411a:	04054d63          	bltz	a0,80204174 <sys_write+0x112>
    8020411e:	fcc40593          	add	a1,s0,-52
    80204122:	4509                	li	a0,2
    80204124:	ffffe097          	auipc	ra,0xffffe
    80204128:	a98080e7          	jalr	-1384(ra) # 80201bbc <argint>
    8020412c:	04054663          	bltz	a0,80204178 <sys_write+0x116>
        if (!validate_addr(p, n)) return -1;
    80204130:	fcc42583          	lw	a1,-52(s0)
    80204134:	fd043503          	ld	a0,-48(s0)
    80204138:	00000097          	auipc	ra,0x0
    8020413c:	c8c080e7          	jalr	-884(ra) # 80203dc4 <validate_addr>
    80204140:	cd15                	beqz	a0,8020417c <sys_write+0x11a>
        char *s = (char*)p;
    80204142:	fd043903          	ld	s2,-48(s0)
        for(int i = 0; i < n; i++) {
    80204146:	fcc42503          	lw	a0,-52(s0)
    8020414a:	faa050e3          	blez	a0,802040ea <sys_write+0x88>
    8020414e:	4481                	li	s1,0
            cons_putc(s[i]);
    80204150:	009907b3          	add	a5,s2,s1
    80204154:	0007c503          	lbu	a0,0(a5)
    80204158:	ffffc097          	auipc	ra,0xffffc
    8020415c:	ef6080e7          	jalr	-266(ra) # 8020004e <cons_putc>
        for(int i = 0; i < n; i++) {
    80204160:	fcc42503          	lw	a0,-52(s0)
    80204164:	0485                	add	s1,s1,1
    80204166:	0004879b          	sext.w	a5,s1
    8020416a:	fea7c3e3          	blt	a5,a0,80204150 <sys_write+0xee>
    8020416e:	bfb5                	j	802040ea <sys_write+0x88>
    if (argint(0, &fd) < 0) return -1;
    80204170:	557d                	li	a0,-1
    80204172:	bfa5                	j	802040ea <sys_write+0x88>
        if (argaddr(1, &p) < 0 || argint(2, &n) < 0) return -1;
    80204174:	557d                	li	a0,-1
    80204176:	bf95                	j	802040ea <sys_write+0x88>
    80204178:	557d                	li	a0,-1
    8020417a:	bf85                	j	802040ea <sys_write+0x88>
        if (!validate_addr(p, n)) return -1;
    8020417c:	557d                	li	a0,-1
    8020417e:	b7b5                	j	802040ea <sys_write+0x88>
        return -1;
    80204180:	557d                	li	a0,-1
    80204182:	b7a5                	j	802040ea <sys_write+0x88>
    80204184:	557d                	li	a0,-1
    80204186:	b795                	j	802040ea <sys_write+0x88>
    80204188:	557d                	li	a0,-1
    8020418a:	b785                	j	802040ea <sys_write+0x88>
        return -1;
    8020418c:	557d                	li	a0,-1
    8020418e:	bfb1                	j	802040ea <sys_write+0x88>

0000000080204190 <sys_close>:

int sys_close(void) {
    80204190:	1101                	add	sp,sp,-32
    80204192:	ec06                	sd	ra,24(sp)
    80204194:	e822                	sd	s0,16(sp)
    80204196:	1000                	add	s0,sp,32
    int fd;
    struct file *f;
    if (argfd(0, &fd, &f) < 0)
    80204198:	fe040613          	add	a2,s0,-32
    8020419c:	fec40593          	add	a1,s0,-20
    802041a0:	4501                	li	a0,0
    802041a2:	00000097          	auipc	ra,0x0
    802041a6:	b78080e7          	jalr	-1160(ra) # 80203d1a <argfd>
    802041aa:	02054863          	bltz	a0,802041da <sys_close+0x4a>
        return -1;
    myproc()->ofile[fd] = 0;
    802041ae:	ffffd097          	auipc	ra,0xffffd
    802041b2:	1ea080e7          	jalr	490(ra) # 80201398 <myproc>
    802041b6:	fec42783          	lw	a5,-20(s0)
    802041ba:	07e9                	add	a5,a5,26
    802041bc:	078e                	sll	a5,a5,0x3
    802041be:	953e                	add	a0,a0,a5
    802041c0:	00053423          	sd	zero,8(a0)
    fileclose(f);
    802041c4:	fe043503          	ld	a0,-32(s0)
    802041c8:	00000097          	auipc	ra,0x0
    802041cc:	86c080e7          	jalr	-1940(ra) # 80203a34 <fileclose>
    return 0;
    802041d0:	4501                	li	a0,0
}
    802041d2:	60e2                	ld	ra,24(sp)
    802041d4:	6442                	ld	s0,16(sp)
    802041d6:	6105                	add	sp,sp,32
    802041d8:	8082                	ret
        return -1;
    802041da:	557d                	li	a0,-1
    802041dc:	bfdd                	j	802041d2 <sys_close+0x42>

00000000802041de <sys_fstat>:

int sys_fstat(void) {
    802041de:	1101                	add	sp,sp,-32
    802041e0:	ec06                	sd	ra,24(sp)
    802041e2:	e822                	sd	s0,16(sp)
    802041e4:	1000                	add	s0,sp,32
    struct file *f;
    uint64 addr;
    if (argfd(0, 0, &f) < 0 || argaddr(1, &addr) < 0)
    802041e6:	fe840613          	add	a2,s0,-24
    802041ea:	4581                	li	a1,0
    802041ec:	4501                	li	a0,0
    802041ee:	00000097          	auipc	ra,0x0
    802041f2:	b2c080e7          	jalr	-1236(ra) # 80203d1a <argfd>
    802041f6:	02054763          	bltz	a0,80204224 <sys_fstat+0x46>
    802041fa:	fe040593          	add	a1,s0,-32
    802041fe:	4505                	li	a0,1
    80204200:	ffffe097          	auipc	ra,0xffffe
    80204204:	a46080e7          	jalr	-1466(ra) # 80201c46 <argaddr>
    80204208:	02054063          	bltz	a0,80204228 <sys_fstat+0x4a>
        return -1;
    return filestat(f, addr);
    8020420c:	fe043583          	ld	a1,-32(s0)
    80204210:	fe843503          	ld	a0,-24(s0)
    80204214:	00000097          	auipc	ra,0x0
    80204218:	8d8080e7          	jalr	-1832(ra) # 80203aec <filestat>
}
    8020421c:	60e2                	ld	ra,24(sp)
    8020421e:	6442                	ld	s0,16(sp)
    80204220:	6105                	add	sp,sp,32
    80204222:	8082                	ret
        return -1;
    80204224:	557d                	li	a0,-1
    80204226:	bfdd                	j	8020421c <sys_fstat+0x3e>
    80204228:	557d                	li	a0,-1
    8020422a:	bfcd                	j	8020421c <sys_fstat+0x3e>

000000008020422c <sys_link>:

int sys_link(void) {
    8020422c:	7169                	add	sp,sp,-304
    8020422e:	f606                	sd	ra,296(sp)
    80204230:	f222                	sd	s0,288(sp)
    80204232:	ee26                	sd	s1,280(sp)
    80204234:	ea4a                	sd	s2,272(sp)
    80204236:	1a00                	add	s0,sp,304
    char name[DIRSIZ], new[MAXPATH], old[MAXPATH];
    struct inode *dp, *ip;

    if (argstr(0, old, sizeof(old)) < 0 || argstr(1, new, sizeof(new)) < 0)
    80204238:	08000613          	li	a2,128
    8020423c:	ed040593          	add	a1,s0,-304
    80204240:	4501                	li	a0,0
    80204242:	ffffe097          	auipc	ra,0xffffe
    80204246:	a8e080e7          	jalr	-1394(ra) # 80201cd0 <argstr>
    8020424a:	12054363          	bltz	a0,80204370 <sys_link+0x144>
    8020424e:	08000613          	li	a2,128
    80204252:	f5040593          	add	a1,s0,-176
    80204256:	4505                	li	a0,1
    80204258:	ffffe097          	auipc	ra,0xffffe
    8020425c:	a78080e7          	jalr	-1416(ra) # 80201cd0 <argstr>
    80204260:	10054a63          	bltz	a0,80204374 <sys_link+0x148>
        return -1;

    begin_op();
    80204264:	fffff097          	auipc	ra,0xfffff
    80204268:	2ee080e7          	jalr	750(ra) # 80203552 <begin_op>
    if ((ip = namei(old)) == 0) {
    8020426c:	ed040513          	add	a0,s0,-304
    80204270:	fffff097          	auipc	ra,0xfffff
    80204274:	ec0080e7          	jalr	-320(ra) # 80203130 <namei>
    80204278:	84aa                	mv	s1,a0
    8020427a:	c959                	beqz	a0,80204310 <sys_link+0xe4>
        end_op();
        return -1;
    }
    ilock(ip);
    8020427c:	ffffe097          	auipc	ra,0xffffe
    80204280:	69a080e7          	jalr	1690(ra) # 80202916 <ilock>
    if (ip->type == T_DIR) {
    80204284:	04449703          	lh	a4,68(s1)
    80204288:	4785                	li	a5,1
    8020428a:	08f70963          	beq	a4,a5,8020431c <sys_link+0xf0>
        iunlockput(ip);
        end_op();
        return -1;
    }

    ip->nlink++;
    8020428e:	04a4d783          	lhu	a5,74(s1)
    80204292:	2785                	addw	a5,a5,1
    80204294:	04f49523          	sh	a5,74(s1)
    iupdate(ip);
    80204298:	8526                	mv	a0,s1
    8020429a:	ffffe097          	auipc	ra,0xffffe
    8020429e:	782080e7          	jalr	1922(ra) # 80202a1c <iupdate>
    iunlock(ip);
    802042a2:	8526                	mv	a0,s1
    802042a4:	ffffe097          	auipc	ra,0xffffe
    802042a8:	738080e7          	jalr	1848(ra) # 802029dc <iunlock>

    if ((dp = nameiparent(new, name)) == 0)
    802042ac:	fd040593          	add	a1,s0,-48
    802042b0:	f5040513          	add	a0,s0,-176
    802042b4:	fffff097          	auipc	ra,0xfffff
    802042b8:	e9a080e7          	jalr	-358(ra) # 8020314e <nameiparent>
    802042bc:	892a                	mv	s2,a0
    802042be:	cd3d                	beqz	a0,8020433c <sys_link+0x110>
        goto bad;
    ilock(dp);
    802042c0:	ffffe097          	auipc	ra,0xffffe
    802042c4:	656080e7          	jalr	1622(ra) # 80202916 <ilock>
    if (dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0) {
    802042c8:	00092703          	lw	a4,0(s2)
    802042cc:	409c                	lw	a5,0(s1)
    802042ce:	06f71263          	bne	a4,a5,80204332 <sys_link+0x106>
    802042d2:	40d0                	lw	a2,4(s1)
    802042d4:	fd040593          	add	a1,s0,-48
    802042d8:	854a                	mv	a0,s2
    802042da:	fffff097          	auipc	ra,0xfffff
    802042de:	c2e080e7          	jalr	-978(ra) # 80202f08 <dirlink>
    802042e2:	04054863          	bltz	a0,80204332 <sys_link+0x106>
        iunlockput(dp);
        goto bad;
    }
    iunlockput(dp);
    802042e6:	854a                	mv	a0,s2
    802042e8:	fffff097          	auipc	ra,0xfffff
    802042ec:	8f6080e7          	jalr	-1802(ra) # 80202bde <iunlockput>
    iput(ip);
    802042f0:	8526                	mv	a0,s1
    802042f2:	fffff097          	auipc	ra,0xfffff
    802042f6:	864080e7          	jalr	-1948(ra) # 80202b56 <iput>
    end_op();
    802042fa:	fffff097          	auipc	ra,0xfffff
    802042fe:	2d2080e7          	jalr	722(ra) # 802035cc <end_op>
    return 0;
    80204302:	4501                	li	a0,0
    ip->nlink--;
    iupdate(ip);
    iunlockput(ip);
    end_op();
    return -1;
}
    80204304:	70b2                	ld	ra,296(sp)
    80204306:	7412                	ld	s0,288(sp)
    80204308:	64f2                	ld	s1,280(sp)
    8020430a:	6952                	ld	s2,272(sp)
    8020430c:	6155                	add	sp,sp,304
    8020430e:	8082                	ret
        end_op();
    80204310:	fffff097          	auipc	ra,0xfffff
    80204314:	2bc080e7          	jalr	700(ra) # 802035cc <end_op>
        return -1;
    80204318:	557d                	li	a0,-1
    8020431a:	b7ed                	j	80204304 <sys_link+0xd8>
        iunlockput(ip);
    8020431c:	8526                	mv	a0,s1
    8020431e:	fffff097          	auipc	ra,0xfffff
    80204322:	8c0080e7          	jalr	-1856(ra) # 80202bde <iunlockput>
        end_op();
    80204326:	fffff097          	auipc	ra,0xfffff
    8020432a:	2a6080e7          	jalr	678(ra) # 802035cc <end_op>
        return -1;
    8020432e:	557d                	li	a0,-1
    80204330:	bfd1                	j	80204304 <sys_link+0xd8>
        iunlockput(dp);
    80204332:	854a                	mv	a0,s2
    80204334:	fffff097          	auipc	ra,0xfffff
    80204338:	8aa080e7          	jalr	-1878(ra) # 80202bde <iunlockput>
    ilock(ip);
    8020433c:	8526                	mv	a0,s1
    8020433e:	ffffe097          	auipc	ra,0xffffe
    80204342:	5d8080e7          	jalr	1496(ra) # 80202916 <ilock>
    ip->nlink--;
    80204346:	04a4d783          	lhu	a5,74(s1)
    8020434a:	37fd                	addw	a5,a5,-1
    8020434c:	04f49523          	sh	a5,74(s1)
    iupdate(ip);
    80204350:	8526                	mv	a0,s1
    80204352:	ffffe097          	auipc	ra,0xffffe
    80204356:	6ca080e7          	jalr	1738(ra) # 80202a1c <iupdate>
    iunlockput(ip);
    8020435a:	8526                	mv	a0,s1
    8020435c:	fffff097          	auipc	ra,0xfffff
    80204360:	882080e7          	jalr	-1918(ra) # 80202bde <iunlockput>
    end_op();
    80204364:	fffff097          	auipc	ra,0xfffff
    80204368:	268080e7          	jalr	616(ra) # 802035cc <end_op>
    return -1;
    8020436c:	557d                	li	a0,-1
    8020436e:	bf59                	j	80204304 <sys_link+0xd8>
        return -1;
    80204370:	557d                	li	a0,-1
    80204372:	bf49                	j	80204304 <sys_link+0xd8>
    80204374:	557d                	li	a0,-1
    80204376:	b779                	j	80204304 <sys_link+0xd8>

0000000080204378 <sys_unlink>:

int sys_unlink(void) {
    80204378:	7155                	add	sp,sp,-208
    8020437a:	e586                	sd	ra,200(sp)
    8020437c:	e1a2                	sd	s0,192(sp)
    8020437e:	fd26                	sd	s1,184(sp)
    80204380:	f94a                	sd	s2,176(sp)
    80204382:	0980                	add	s0,sp,208
    struct inode *ip, *dp;
    struct dirent de;
    char name[DIRSIZ], path[MAXPATH];
    uint off;

    if (argstr(0, path, sizeof(path)) < 0)
    80204384:	08000613          	li	a2,128
    80204388:	f4040593          	add	a1,s0,-192
    8020438c:	4501                	li	a0,0
    8020438e:	ffffe097          	auipc	ra,0xffffe
    80204392:	942080e7          	jalr	-1726(ra) # 80201cd0 <argstr>
    80204396:	16054463          	bltz	a0,802044fe <sys_unlink+0x186>
        return -1;

    begin_op();
    8020439a:	fffff097          	auipc	ra,0xfffff
    8020439e:	1b8080e7          	jalr	440(ra) # 80203552 <begin_op>
    if ((dp = nameiparent(path, name)) == 0) {
    802043a2:	fc040593          	add	a1,s0,-64
    802043a6:	f4040513          	add	a0,s0,-192
    802043aa:	fffff097          	auipc	ra,0xfffff
    802043ae:	da4080e7          	jalr	-604(ra) # 8020314e <nameiparent>
    802043b2:	892a                	mv	s2,a0
    802043b4:	c175                	beqz	a0,80204498 <sys_unlink+0x120>
        end_op();
        return -1;
    }
    ilock(dp);
    802043b6:	ffffe097          	auipc	ra,0xffffe
    802043ba:	560080e7          	jalr	1376(ra) # 80202916 <ilock>

    if (namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    802043be:	00002597          	auipc	a1,0x2
    802043c2:	3ba58593          	add	a1,a1,954 # 80206778 <syscalls+0x1d8>
    802043c6:	fc040513          	add	a0,s0,-64
    802043ca:	fffff097          	auipc	ra,0xfffff
    802043ce:	a66080e7          	jalr	-1434(ra) # 80202e30 <namecmp>
    802043d2:	c57d                	beqz	a0,802044c0 <sys_unlink+0x148>
    802043d4:	00002597          	auipc	a1,0x2
    802043d8:	3ac58593          	add	a1,a1,940 # 80206780 <syscalls+0x1e0>
    802043dc:	fc040513          	add	a0,s0,-64
    802043e0:	fffff097          	auipc	ra,0xfffff
    802043e4:	a50080e7          	jalr	-1456(ra) # 80202e30 <namecmp>
    802043e8:	cd61                	beqz	a0,802044c0 <sys_unlink+0x148>
        goto bad;

    if ((ip = dirlookup(dp, name, &off)) == 0)
    802043ea:	f3c40613          	add	a2,s0,-196
    802043ee:	fc040593          	add	a1,s0,-64
    802043f2:	854a                	mv	a0,s2
    802043f4:	fffff097          	auipc	ra,0xfffff
    802043f8:	a56080e7          	jalr	-1450(ra) # 80202e4a <dirlookup>
    802043fc:	84aa                	mv	s1,a0
    802043fe:	c169                	beqz	a0,802044c0 <sys_unlink+0x148>
        goto bad;
    ilock(ip);
    80204400:	ffffe097          	auipc	ra,0xffffe
    80204404:	516080e7          	jalr	1302(ra) # 80202916 <ilock>

    if (ip->nlink < 1)
    80204408:	04a49783          	lh	a5,74(s1)
    8020440c:	08f05c63          	blez	a5,802044a4 <sys_unlink+0x12c>
        panic("unlink: nlink < 1");
    if (ip->type == T_DIR && ip->size > 2 * sizeof(de)) {
    80204410:	04449703          	lh	a4,68(s1)
    80204414:	4785                	li	a5,1
    80204416:	00f71763          	bne	a4,a5,80204424 <sys_unlink+0xac>
    8020441a:	44f8                	lw	a4,76(s1)
    8020441c:	02000793          	li	a5,32
    80204420:	08e7eb63          	bltu	a5,a4,802044b6 <sys_unlink+0x13e>
        iunlockput(ip);
        goto bad;
    }

    memset(&de, 0, sizeof(de));
    80204424:	4641                	li	a2,16
    80204426:	4581                	li	a1,0
    80204428:	fd040513          	add	a0,s0,-48
    8020442c:	ffffc097          	auipc	ra,0xffffc
    80204430:	576080e7          	jalr	1398(ra) # 802009a2 <memset>
    if (writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80204434:	4741                	li	a4,16
    80204436:	f3c42683          	lw	a3,-196(s0)
    8020443a:	fd040613          	add	a2,s0,-48
    8020443e:	4581                	li	a1,0
    80204440:	854a                	mv	a0,s2
    80204442:	fffff097          	auipc	ra,0xfffff
    80204446:	8d2080e7          	jalr	-1838(ra) # 80202d14 <writei>
    8020444a:	47c1                	li	a5,16
    8020444c:	08f51563          	bne	a0,a5,802044d6 <sys_unlink+0x15e>
        panic("unlink: write");
    if (ip->type == T_DIR) {
    80204450:	04449703          	lh	a4,68(s1)
    80204454:	4785                	li	a5,1
    80204456:	08f70963          	beq	a4,a5,802044e8 <sys_unlink+0x170>
        dp->nlink--;
        iupdate(dp);
    }
    iunlockput(dp);
    8020445a:	854a                	mv	a0,s2
    8020445c:	ffffe097          	auipc	ra,0xffffe
    80204460:	782080e7          	jalr	1922(ra) # 80202bde <iunlockput>

    ip->nlink--;
    80204464:	04a4d783          	lhu	a5,74(s1)
    80204468:	37fd                	addw	a5,a5,-1
    8020446a:	04f49523          	sh	a5,74(s1)
    iupdate(ip);
    8020446e:	8526                	mv	a0,s1
    80204470:	ffffe097          	auipc	ra,0xffffe
    80204474:	5ac080e7          	jalr	1452(ra) # 80202a1c <iupdate>
    iunlockput(ip);
    80204478:	8526                	mv	a0,s1
    8020447a:	ffffe097          	auipc	ra,0xffffe
    8020447e:	764080e7          	jalr	1892(ra) # 80202bde <iunlockput>

    end_op();
    80204482:	fffff097          	auipc	ra,0xfffff
    80204486:	14a080e7          	jalr	330(ra) # 802035cc <end_op>
    return 0;
    8020448a:	4501                	li	a0,0

bad:
    iunlockput(dp);
    end_op();
    return -1;
}
    8020448c:	60ae                	ld	ra,200(sp)
    8020448e:	640e                	ld	s0,192(sp)
    80204490:	74ea                	ld	s1,184(sp)
    80204492:	794a                	ld	s2,176(sp)
    80204494:	6169                	add	sp,sp,208
    80204496:	8082                	ret
        end_op();
    80204498:	fffff097          	auipc	ra,0xfffff
    8020449c:	134080e7          	jalr	308(ra) # 802035cc <end_op>
        return -1;
    802044a0:	557d                	li	a0,-1
    802044a2:	b7ed                	j	8020448c <sys_unlink+0x114>
        panic("unlink: nlink < 1");
    802044a4:	00002517          	auipc	a0,0x2
    802044a8:	4bc50513          	add	a0,a0,1212 # 80206960 <syscalls+0x3c0>
    802044ac:	ffffc097          	auipc	ra,0xffffc
    802044b0:	f28080e7          	jalr	-216(ra) # 802003d4 <panic>
    802044b4:	bfb1                	j	80204410 <sys_unlink+0x98>
        iunlockput(ip);
    802044b6:	8526                	mv	a0,s1
    802044b8:	ffffe097          	auipc	ra,0xffffe
    802044bc:	726080e7          	jalr	1830(ra) # 80202bde <iunlockput>
    iunlockput(dp);
    802044c0:	854a                	mv	a0,s2
    802044c2:	ffffe097          	auipc	ra,0xffffe
    802044c6:	71c080e7          	jalr	1820(ra) # 80202bde <iunlockput>
    end_op();
    802044ca:	fffff097          	auipc	ra,0xfffff
    802044ce:	102080e7          	jalr	258(ra) # 802035cc <end_op>
    return -1;
    802044d2:	557d                	li	a0,-1
    802044d4:	bf65                	j	8020448c <sys_unlink+0x114>
        panic("unlink: write");
    802044d6:	00002517          	auipc	a0,0x2
    802044da:	4a250513          	add	a0,a0,1186 # 80206978 <syscalls+0x3d8>
    802044de:	ffffc097          	auipc	ra,0xffffc
    802044e2:	ef6080e7          	jalr	-266(ra) # 802003d4 <panic>
    802044e6:	b7ad                	j	80204450 <sys_unlink+0xd8>
        dp->nlink--;
    802044e8:	04a95783          	lhu	a5,74(s2)
    802044ec:	37fd                	addw	a5,a5,-1
    802044ee:	04f91523          	sh	a5,74(s2)
        iupdate(dp);
    802044f2:	854a                	mv	a0,s2
    802044f4:	ffffe097          	auipc	ra,0xffffe
    802044f8:	528080e7          	jalr	1320(ra) # 80202a1c <iupdate>
    802044fc:	bfb9                	j	8020445a <sys_unlink+0xe2>
        return -1;
    802044fe:	557d                	li	a0,-1
    80204500:	b771                	j	8020448c <sys_unlink+0x114>

0000000080204502 <sys_open>:

int sys_open(void) {
    80204502:	7131                	add	sp,sp,-192
    80204504:	fd06                	sd	ra,184(sp)
    80204506:	f922                	sd	s0,176(sp)
    80204508:	f526                	sd	s1,168(sp)
    8020450a:	f14a                	sd	s2,160(sp)
    8020450c:	ed4e                	sd	s3,152(sp)
    8020450e:	0180                	add	s0,sp,192
    char path[MAXPATH];
    int omode;
    struct file *f;
    struct inode *ip;

    if (argstr(0, path, sizeof(path)) < 0 || argint(1, &omode) < 0)
    80204510:	08000613          	li	a2,128
    80204514:	f5040593          	add	a1,s0,-176
    80204518:	4501                	li	a0,0
    8020451a:	ffffd097          	auipc	ra,0xffffd
    8020451e:	7b6080e7          	jalr	1974(ra) # 80201cd0 <argstr>
    80204522:	16054563          	bltz	a0,8020468c <sys_open+0x18a>
    80204526:	f4c40593          	add	a1,s0,-180
    8020452a:	4505                	li	a0,1
    8020452c:	ffffd097          	auipc	ra,0xffffd
    80204530:	690080e7          	jalr	1680(ra) # 80201bbc <argint>
    80204534:	14054e63          	bltz	a0,80204690 <sys_open+0x18e>
        return -1;

    begin_op();
    80204538:	fffff097          	auipc	ra,0xfffff
    8020453c:	01a080e7          	jalr	26(ra) # 80203552 <begin_op>

    if (omode & O_CREATE) {
    80204540:	f4c42783          	lw	a5,-180(s0)
    80204544:	2007f793          	and	a5,a5,512
    80204548:	c7cd                	beqz	a5,802045f2 <sys_open+0xf0>
        ip = create(path, T_FILE, 0, 0);
    8020454a:	4681                	li	a3,0
    8020454c:	4601                	li	a2,0
    8020454e:	4589                	li	a1,2
    80204550:	f5040513          	add	a0,s0,-176
    80204554:	00000097          	auipc	ra,0x0
    80204558:	8e0080e7          	jalr	-1824(ra) # 80203e34 <create>
    8020455c:	89aa                	mv	s3,a0
        if (ip == 0) {
    8020455e:	c935                	beqz	a0,802045d2 <sys_open+0xd0>
            end_op();
            return -1;
        }
    }

    if ((f = filealloc()) == 0) {
    80204560:	fffff097          	auipc	ra,0xfffff
    80204564:	414080e7          	jalr	1044(ra) # 80203974 <filealloc>
    80204568:	84aa                	mv	s1,a0
    8020456a:	c969                	beqz	a0,8020463c <sys_open+0x13a>
        iunlockput(ip);
        end_op();
        return -1;
    }
    int fd = fdalloc(f);
    8020456c:	00000097          	auipc	ra,0x0
    80204570:	816080e7          	jalr	-2026(ra) # 80203d82 <fdalloc>
    80204574:	892a                	mv	s2,a0
    if (fd < 0) {
    80204576:	0c054e63          	bltz	a0,80204652 <sys_open+0x150>
        fileclose(f);
        iunlockput(ip);
        end_op();
        return -1;
    }
    if (ip->type == T_DEV) {
    8020457a:	04499703          	lh	a4,68(s3)
    8020457e:	478d                	li	a5,3
    80204580:	0ef70963          	beq	a4,a5,80204672 <sys_open+0x170>
        f->type = FD_DEVICE;
        f->major = ip->major;
    } else {
        f->type = FD_INODE;
    80204584:	4785                	li	a5,1
    80204586:	c09c                	sw	a5,0(s1)
    }
    f->off = 0;
    80204588:	0004ac23          	sw	zero,24(s1)
    f->readable = !(omode & O_WRONLY);
    8020458c:	f4c42783          	lw	a5,-180(s0)
    80204590:	0017c713          	xor	a4,a5,1
    80204594:	8b05                	and	a4,a4,1
    80204596:	00e48423          	sb	a4,8(s1)
    f->writable = (omode & (O_WRONLY | O_RDWR)) != 0;
    8020459a:	0037f713          	and	a4,a5,3
    8020459e:	00e03733          	snez	a4,a4
    802045a2:	00e484a3          	sb	a4,9(s1)
    f->ip = ip;
    802045a6:	0134b823          	sd	s3,16(s1)
    if (omode & O_TRUNC) {
    802045aa:	4007f793          	and	a5,a5,1024
    802045ae:	ebe9                	bnez	a5,80204680 <sys_open+0x17e>
        itrunc(ip);
    }
    iunlock(ip);
    802045b0:	854e                	mv	a0,s3
    802045b2:	ffffe097          	auipc	ra,0xffffe
    802045b6:	42a080e7          	jalr	1066(ra) # 802029dc <iunlock>
    end_op();
    802045ba:	fffff097          	auipc	ra,0xfffff
    802045be:	012080e7          	jalr	18(ra) # 802035cc <end_op>
    return fd;
}
    802045c2:	854a                	mv	a0,s2
    802045c4:	70ea                	ld	ra,184(sp)
    802045c6:	744a                	ld	s0,176(sp)
    802045c8:	74aa                	ld	s1,168(sp)
    802045ca:	790a                	ld	s2,160(sp)
    802045cc:	69ea                	ld	s3,152(sp)
    802045ce:	6129                	add	sp,sp,192
    802045d0:	8082                	ret
            printf("sys_open: create failed for %s\n", path); // DEBUG
    802045d2:	f5040593          	add	a1,s0,-176
    802045d6:	00002517          	auipc	a0,0x2
    802045da:	3b250513          	add	a0,a0,946 # 80206988 <syscalls+0x3e8>
    802045de:	ffffc097          	auipc	ra,0xffffc
    802045e2:	b76080e7          	jalr	-1162(ra) # 80200154 <printf>
            end_op();
    802045e6:	fffff097          	auipc	ra,0xfffff
    802045ea:	fe6080e7          	jalr	-26(ra) # 802035cc <end_op>
            return -1;
    802045ee:	597d                	li	s2,-1
    802045f0:	bfc9                	j	802045c2 <sys_open+0xc0>
        if ((ip = namei(path)) == 0) {
    802045f2:	f5040513          	add	a0,s0,-176
    802045f6:	fffff097          	auipc	ra,0xfffff
    802045fa:	b3a080e7          	jalr	-1222(ra) # 80203130 <namei>
    802045fe:	89aa                	mv	s3,a0
    80204600:	c905                	beqz	a0,80204630 <sys_open+0x12e>
        ilock(ip);
    80204602:	ffffe097          	auipc	ra,0xffffe
    80204606:	314080e7          	jalr	788(ra) # 80202916 <ilock>
        if (ip->type == T_DIR && omode != O_RDONLY) {
    8020460a:	04499703          	lh	a4,68(s3)
    8020460e:	4785                	li	a5,1
    80204610:	f4f718e3          	bne	a4,a5,80204560 <sys_open+0x5e>
    80204614:	f4c42783          	lw	a5,-180(s0)
    80204618:	d7a1                	beqz	a5,80204560 <sys_open+0x5e>
            iunlockput(ip);
    8020461a:	854e                	mv	a0,s3
    8020461c:	ffffe097          	auipc	ra,0xffffe
    80204620:	5c2080e7          	jalr	1474(ra) # 80202bde <iunlockput>
            end_op();
    80204624:	fffff097          	auipc	ra,0xfffff
    80204628:	fa8080e7          	jalr	-88(ra) # 802035cc <end_op>
            return -1;
    8020462c:	597d                	li	s2,-1
    8020462e:	bf51                	j	802045c2 <sys_open+0xc0>
            end_op();
    80204630:	fffff097          	auipc	ra,0xfffff
    80204634:	f9c080e7          	jalr	-100(ra) # 802035cc <end_op>
            return -1;
    80204638:	597d                	li	s2,-1
    8020463a:	b761                	j	802045c2 <sys_open+0xc0>
        iunlockput(ip);
    8020463c:	854e                	mv	a0,s3
    8020463e:	ffffe097          	auipc	ra,0xffffe
    80204642:	5a0080e7          	jalr	1440(ra) # 80202bde <iunlockput>
        end_op();
    80204646:	fffff097          	auipc	ra,0xfffff
    8020464a:	f86080e7          	jalr	-122(ra) # 802035cc <end_op>
        return -1;
    8020464e:	597d                	li	s2,-1
    80204650:	bf8d                	j	802045c2 <sys_open+0xc0>
        fileclose(f);
    80204652:	8526                	mv	a0,s1
    80204654:	fffff097          	auipc	ra,0xfffff
    80204658:	3e0080e7          	jalr	992(ra) # 80203a34 <fileclose>
        iunlockput(ip);
    8020465c:	854e                	mv	a0,s3
    8020465e:	ffffe097          	auipc	ra,0xffffe
    80204662:	580080e7          	jalr	1408(ra) # 80202bde <iunlockput>
        end_op();
    80204666:	fffff097          	auipc	ra,0xfffff
    8020466a:	f66080e7          	jalr	-154(ra) # 802035cc <end_op>
        return -1;
    8020466e:	597d                	li	s2,-1
    80204670:	bf89                	j	802045c2 <sys_open+0xc0>
        f->type = FD_DEVICE;
    80204672:	4789                	li	a5,2
    80204674:	c09c                	sw	a5,0(s1)
        f->major = ip->major;
    80204676:	04699783          	lh	a5,70(s3)
    8020467a:	00f49e23          	sh	a5,28(s1)
    8020467e:	b729                	j	80204588 <sys_open+0x86>
        itrunc(ip);
    80204680:	854e                	mv	a0,s3
    80204682:	ffffe097          	auipc	ra,0xffffe
    80204686:	428080e7          	jalr	1064(ra) # 80202aaa <itrunc>
    8020468a:	b71d                	j	802045b0 <sys_open+0xae>
        return -1;
    8020468c:	597d                	li	s2,-1
    8020468e:	bf15                	j	802045c2 <sys_open+0xc0>
    80204690:	597d                	li	s2,-1
    80204692:	bf05                	j	802045c2 <sys_open+0xc0>

0000000080204694 <sys_mkdir>:

int sys_mkdir(void) {
    80204694:	7175                	add	sp,sp,-144
    80204696:	e506                	sd	ra,136(sp)
    80204698:	e122                	sd	s0,128(sp)
    8020469a:	0900                	add	s0,sp,144
    char path[MAXPATH];
    if (argstr(0, path, sizeof(path)) < 0)
    8020469c:	08000613          	li	a2,128
    802046a0:	f7040593          	add	a1,s0,-144
    802046a4:	4501                	li	a0,0
    802046a6:	ffffd097          	auipc	ra,0xffffd
    802046aa:	62a080e7          	jalr	1578(ra) # 80201cd0 <argstr>
    802046ae:	04054363          	bltz	a0,802046f4 <sys_mkdir+0x60>
        return -1;
    begin_op();
    802046b2:	fffff097          	auipc	ra,0xfffff
    802046b6:	ea0080e7          	jalr	-352(ra) # 80203552 <begin_op>
    struct inode *ip = create(path, T_DIR, 0, 0);
    802046ba:	4681                	li	a3,0
    802046bc:	4601                	li	a2,0
    802046be:	4585                	li	a1,1
    802046c0:	f7040513          	add	a0,s0,-144
    802046c4:	fffff097          	auipc	ra,0xfffff
    802046c8:	770080e7          	jalr	1904(ra) # 80203e34 <create>
    if (ip == 0) {
    802046cc:	cd11                	beqz	a0,802046e8 <sys_mkdir+0x54>
        end_op();
        return -1;
    }
    iunlockput(ip);
    802046ce:	ffffe097          	auipc	ra,0xffffe
    802046d2:	510080e7          	jalr	1296(ra) # 80202bde <iunlockput>
    end_op();
    802046d6:	fffff097          	auipc	ra,0xfffff
    802046da:	ef6080e7          	jalr	-266(ra) # 802035cc <end_op>
    return 0;
    802046de:	4501                	li	a0,0
}
    802046e0:	60aa                	ld	ra,136(sp)
    802046e2:	640a                	ld	s0,128(sp)
    802046e4:	6149                	add	sp,sp,144
    802046e6:	8082                	ret
        end_op();
    802046e8:	fffff097          	auipc	ra,0xfffff
    802046ec:	ee4080e7          	jalr	-284(ra) # 802035cc <end_op>
        return -1;
    802046f0:	557d                	li	a0,-1
    802046f2:	b7fd                	j	802046e0 <sys_mkdir+0x4c>
        return -1;
    802046f4:	557d                	li	a0,-1
    802046f6:	b7ed                	j	802046e0 <sys_mkdir+0x4c>

00000000802046f8 <sys_mknod>:

int sys_mknod(void) {
    802046f8:	7135                	add	sp,sp,-160
    802046fa:	ed06                	sd	ra,152(sp)
    802046fc:	e922                	sd	s0,144(sp)
    802046fe:	1100                	add	s0,sp,160
    char path[MAXPATH];
    int major, minor;
    if (argstr(0, path, sizeof(path)) < 0 || argint(1, &major) < 0 || argint(2, &minor) < 0)
    80204700:	08000613          	li	a2,128
    80204704:	f7040593          	add	a1,s0,-144
    80204708:	4501                	li	a0,0
    8020470a:	ffffd097          	auipc	ra,0xffffd
    8020470e:	5c6080e7          	jalr	1478(ra) # 80201cd0 <argstr>
    80204712:	06054763          	bltz	a0,80204780 <sys_mknod+0x88>
    80204716:	f6c40593          	add	a1,s0,-148
    8020471a:	4505                	li	a0,1
    8020471c:	ffffd097          	auipc	ra,0xffffd
    80204720:	4a0080e7          	jalr	1184(ra) # 80201bbc <argint>
    80204724:	06054063          	bltz	a0,80204784 <sys_mknod+0x8c>
    80204728:	f6840593          	add	a1,s0,-152
    8020472c:	4509                	li	a0,2
    8020472e:	ffffd097          	auipc	ra,0xffffd
    80204732:	48e080e7          	jalr	1166(ra) # 80201bbc <argint>
    80204736:	04054963          	bltz	a0,80204788 <sys_mknod+0x90>
        return -1;
    begin_op();
    8020473a:	fffff097          	auipc	ra,0xfffff
    8020473e:	e18080e7          	jalr	-488(ra) # 80203552 <begin_op>
    struct inode *ip = create(path, T_DEV, major, minor);
    80204742:	f6841683          	lh	a3,-152(s0)
    80204746:	f6c41603          	lh	a2,-148(s0)
    8020474a:	458d                	li	a1,3
    8020474c:	f7040513          	add	a0,s0,-144
    80204750:	fffff097          	auipc	ra,0xfffff
    80204754:	6e4080e7          	jalr	1764(ra) # 80203e34 <create>
    if (ip == 0) {
    80204758:	cd11                	beqz	a0,80204774 <sys_mknod+0x7c>
        end_op();
        return -1;
    }
    iunlockput(ip);
    8020475a:	ffffe097          	auipc	ra,0xffffe
    8020475e:	484080e7          	jalr	1156(ra) # 80202bde <iunlockput>
    end_op();
    80204762:	fffff097          	auipc	ra,0xfffff
    80204766:	e6a080e7          	jalr	-406(ra) # 802035cc <end_op>
    return 0;
    8020476a:	4501                	li	a0,0
}
    8020476c:	60ea                	ld	ra,152(sp)
    8020476e:	644a                	ld	s0,144(sp)
    80204770:	610d                	add	sp,sp,160
    80204772:	8082                	ret
        end_op();
    80204774:	fffff097          	auipc	ra,0xfffff
    80204778:	e58080e7          	jalr	-424(ra) # 802035cc <end_op>
        return -1;
    8020477c:	557d                	li	a0,-1
    8020477e:	b7fd                	j	8020476c <sys_mknod+0x74>
        return -1;
    80204780:	557d                	li	a0,-1
    80204782:	b7ed                	j	8020476c <sys_mknod+0x74>
    80204784:	557d                	li	a0,-1
    80204786:	b7dd                	j	8020476c <sys_mknod+0x74>
    80204788:	557d                	li	a0,-1
    8020478a:	b7cd                	j	8020476c <sys_mknod+0x74>

000000008020478c <sys_chdir>:

int sys_chdir(void) {
    8020478c:	7135                	add	sp,sp,-160
    8020478e:	ed06                	sd	ra,152(sp)
    80204790:	e922                	sd	s0,144(sp)
    80204792:	e526                	sd	s1,136(sp)
    80204794:	e14a                	sd	s2,128(sp)
    80204796:	1100                	add	s0,sp,160
    char path[MAXPATH];
    struct inode *ip;
    if (argstr(0, path, sizeof(path)) < 0)
    80204798:	08000613          	li	a2,128
    8020479c:	f6040593          	add	a1,s0,-160
    802047a0:	4501                	li	a0,0
    802047a2:	ffffd097          	auipc	ra,0xffffd
    802047a6:	52e080e7          	jalr	1326(ra) # 80201cd0 <argstr>
    802047aa:	08054563          	bltz	a0,80204834 <sys_chdir+0xa8>
        return -1;
    begin_op();
    802047ae:	fffff097          	auipc	ra,0xfffff
    802047b2:	da4080e7          	jalr	-604(ra) # 80203552 <begin_op>
    if ((ip = namei(path)) == 0) {
    802047b6:	f6040513          	add	a0,s0,-160
    802047ba:	fffff097          	auipc	ra,0xfffff
    802047be:	976080e7          	jalr	-1674(ra) # 80203130 <namei>
    802047c2:	84aa                	mv	s1,a0
    802047c4:	c539                	beqz	a0,80204812 <sys_chdir+0x86>
        end_op();
        return -1;
    }
    ilock(ip);
    802047c6:	ffffe097          	auipc	ra,0xffffe
    802047ca:	150080e7          	jalr	336(ra) # 80202916 <ilock>
    if (ip->type != T_DIR) {
    802047ce:	04449703          	lh	a4,68(s1)
    802047d2:	4785                	li	a5,1
    802047d4:	04f71563          	bne	a4,a5,8020481e <sys_chdir+0x92>
        iunlockput(ip);
        end_op();
        return -1;
    }
    iunlock(ip);
    802047d8:	8526                	mv	a0,s1
    802047da:	ffffe097          	auipc	ra,0xffffe
    802047de:	202080e7          	jalr	514(ra) # 802029dc <iunlock>
    struct proc *p = myproc();
    802047e2:	ffffd097          	auipc	ra,0xffffd
    802047e6:	bb6080e7          	jalr	-1098(ra) # 80201398 <myproc>
    802047ea:	892a                	mv	s2,a0
    iput(p->cwd);
    802047ec:	15853503          	ld	a0,344(a0)
    802047f0:	ffffe097          	auipc	ra,0xffffe
    802047f4:	366080e7          	jalr	870(ra) # 80202b56 <iput>
    p->cwd = ip;
    802047f8:	14993c23          	sd	s1,344(s2)
    end_op();
    802047fc:	fffff097          	auipc	ra,0xfffff
    80204800:	dd0080e7          	jalr	-560(ra) # 802035cc <end_op>
    return 0;
    80204804:	4501                	li	a0,0
    80204806:	60ea                	ld	ra,152(sp)
    80204808:	644a                	ld	s0,144(sp)
    8020480a:	64aa                	ld	s1,136(sp)
    8020480c:	690a                	ld	s2,128(sp)
    8020480e:	610d                	add	sp,sp,160
    80204810:	8082                	ret
        end_op();
    80204812:	fffff097          	auipc	ra,0xfffff
    80204816:	dba080e7          	jalr	-582(ra) # 802035cc <end_op>
        return -1;
    8020481a:	557d                	li	a0,-1
    8020481c:	b7ed                	j	80204806 <sys_chdir+0x7a>
        iunlockput(ip);
    8020481e:	8526                	mv	a0,s1
    80204820:	ffffe097          	auipc	ra,0xffffe
    80204824:	3be080e7          	jalr	958(ra) # 80202bde <iunlockput>
        end_op();
    80204828:	fffff097          	auipc	ra,0xfffff
    8020482c:	da4080e7          	jalr	-604(ra) # 802035cc <end_op>
        return -1;
    80204830:	557d                	li	a0,-1
    80204832:	bfd1                	j	80204806 <sys_chdir+0x7a>
        return -1;
    80204834:	557d                	li	a0,-1
    80204836:	bfc1                	j	80204806 <sys_chdir+0x7a>
	...

0000000080204840 <kernelvec>:
    80204840:	7111                	add	sp,sp,-256
    80204842:	e006                	sd	ra,0(sp)
    80204844:	e40a                	sd	sp,8(sp)
    80204846:	e80e                	sd	gp,16(sp)
    80204848:	ec12                	sd	tp,24(sp)
    8020484a:	f016                	sd	t0,32(sp)
    8020484c:	f41a                	sd	t1,40(sp)
    8020484e:	f81e                	sd	t2,48(sp)
    80204850:	fc22                	sd	s0,56(sp)
    80204852:	e0a6                	sd	s1,64(sp)
    80204854:	e4aa                	sd	a0,72(sp)
    80204856:	e8ae                	sd	a1,80(sp)
    80204858:	ecb2                	sd	a2,88(sp)
    8020485a:	f0b6                	sd	a3,96(sp)
    8020485c:	f4ba                	sd	a4,104(sp)
    8020485e:	f8be                	sd	a5,112(sp)
    80204860:	fcc2                	sd	a6,120(sp)
    80204862:	e146                	sd	a7,128(sp)
    80204864:	e54a                	sd	s2,136(sp)
    80204866:	e94e                	sd	s3,144(sp)
    80204868:	ed52                	sd	s4,152(sp)
    8020486a:	f156                	sd	s5,160(sp)
    8020486c:	f55a                	sd	s6,168(sp)
    8020486e:	f95e                	sd	s7,176(sp)
    80204870:	fd62                	sd	s8,184(sp)
    80204872:	e1e6                	sd	s9,192(sp)
    80204874:	e5ea                	sd	s10,200(sp)
    80204876:	e9ee                	sd	s11,208(sp)
    80204878:	edf2                	sd	t3,216(sp)
    8020487a:	f1f6                	sd	t4,224(sp)
    8020487c:	f5fa                	sd	t5,232(sp)
    8020487e:	f9fe                	sd	t6,240(sp)
    80204880:	850a                	mv	a0,sp
    80204882:	9d2fd0ef          	jal	80201a54 <kerneltrap>
    80204886:	6082                	ld	ra,0(sp)
    80204888:	61c2                	ld	gp,16(sp)
    8020488a:	6262                	ld	tp,24(sp)
    8020488c:	7282                	ld	t0,32(sp)
    8020488e:	7322                	ld	t1,40(sp)
    80204890:	73c2                	ld	t2,48(sp)
    80204892:	7462                	ld	s0,56(sp)
    80204894:	6486                	ld	s1,64(sp)
    80204896:	6526                	ld	a0,72(sp)
    80204898:	65c6                	ld	a1,80(sp)
    8020489a:	6666                	ld	a2,88(sp)
    8020489c:	7686                	ld	a3,96(sp)
    8020489e:	7726                	ld	a4,104(sp)
    802048a0:	77c6                	ld	a5,112(sp)
    802048a2:	7866                	ld	a6,120(sp)
    802048a4:	688a                	ld	a7,128(sp)
    802048a6:	692a                	ld	s2,136(sp)
    802048a8:	69ca                	ld	s3,144(sp)
    802048aa:	6a6a                	ld	s4,152(sp)
    802048ac:	7a8a                	ld	s5,160(sp)
    802048ae:	7b2a                	ld	s6,168(sp)
    802048b0:	7bca                	ld	s7,176(sp)
    802048b2:	7c6a                	ld	s8,184(sp)
    802048b4:	6c8e                	ld	s9,192(sp)
    802048b6:	6d2e                	ld	s10,200(sp)
    802048b8:	6dce                	ld	s11,208(sp)
    802048ba:	6e6e                	ld	t3,216(sp)
    802048bc:	7e8e                	ld	t4,224(sp)
    802048be:	7f2e                	ld	t5,232(sp)
    802048c0:	7fce                	ld	t6,240(sp)
    802048c2:	6111                	add	sp,sp,256
    802048c4:	10200073          	sret

00000000802048c8 <restore_trapframe>:
    802048c8:	8faa                	mv	t6,a0
    802048ca:	100022f3          	csrr	t0,sstatus
    802048ce:	10000313          	li	t1,256
    802048d2:	10033073          	csrc	sstatus,t1
    802048d6:	018fbf03          	ld	t5,24(t6)
    802048da:	141f1073          	csrw	sepc,t5
    802048de:	028fb083          	ld	ra,40(t6)
    802048e2:	030fb103          	ld	sp,48(t6)
    802048e6:	038fb183          	ld	gp,56(t6)
    802048ea:	040fb203          	ld	tp,64(t6)
    802048ee:	048fb283          	ld	t0,72(t6)
    802048f2:	050fb303          	ld	t1,80(t6)
    802048f6:	058fb383          	ld	t2,88(t6)
    802048fa:	060fb403          	ld	s0,96(t6)
    802048fe:	068fb483          	ld	s1,104(t6)
    80204902:	070fb503          	ld	a0,112(t6)
    80204906:	078fb583          	ld	a1,120(t6)
    8020490a:	080fb603          	ld	a2,128(t6)
    8020490e:	088fb683          	ld	a3,136(t6)
    80204912:	090fb703          	ld	a4,144(t6)
    80204916:	098fb783          	ld	a5,152(t6)
    8020491a:	0a0fb803          	ld	a6,160(t6)
    8020491e:	0a8fb883          	ld	a7,168(t6)
    80204922:	0b0fb903          	ld	s2,176(t6)
    80204926:	0b8fb983          	ld	s3,184(t6)
    8020492a:	0c0fba03          	ld	s4,192(t6)
    8020492e:	0c8fba83          	ld	s5,200(t6)
    80204932:	0d0fbb03          	ld	s6,208(t6)
    80204936:	0d8fbb83          	ld	s7,216(t6)
    8020493a:	0e0fbc03          	ld	s8,224(t6)
    8020493e:	0e8fbc83          	ld	s9,232(t6)
    80204942:	0f0fbd03          	ld	s10,240(t6)
    80204946:	0f8fbd83          	ld	s11,248(t6)
    8020494a:	100fbe03          	ld	t3,256(t6)
    8020494e:	108fbe83          	ld	t4,264(t6)
    80204952:	110fbf03          	ld	t5,272(t6)
    80204956:	118fbf83          	ld	t6,280(t6)
    8020495a:	10200073          	sret

000000008020495e <swtch>:
    8020495e:	00153023          	sd	ra,0(a0)
    80204962:	00253423          	sd	sp,8(a0)
    80204966:	e900                	sd	s0,16(a0)
    80204968:	ed04                	sd	s1,24(a0)
    8020496a:	03253023          	sd	s2,32(a0)
    8020496e:	03353423          	sd	s3,40(a0)
    80204972:	03453823          	sd	s4,48(a0)
    80204976:	03553c23          	sd	s5,56(a0)
    8020497a:	05653023          	sd	s6,64(a0)
    8020497e:	05753423          	sd	s7,72(a0)
    80204982:	05853823          	sd	s8,80(a0)
    80204986:	05953c23          	sd	s9,88(a0)
    8020498a:	07a53023          	sd	s10,96(a0)
    8020498e:	07b53423          	sd	s11,104(a0)
    80204992:	0005b083          	ld	ra,0(a1)
    80204996:	0085b103          	ld	sp,8(a1)
    8020499a:	6980                	ld	s0,16(a1)
    8020499c:	6d84                	ld	s1,24(a1)
    8020499e:	0205b903          	ld	s2,32(a1)
    802049a2:	0285b983          	ld	s3,40(a1)
    802049a6:	0305ba03          	ld	s4,48(a1)
    802049aa:	0385ba83          	ld	s5,56(a1)
    802049ae:	0405bb03          	ld	s6,64(a1)
    802049b2:	0485bb83          	ld	s7,72(a1)
    802049b6:	0505bc03          	ld	s8,80(a1)
    802049ba:	0585bc83          	ld	s9,88(a1)
    802049be:	0605bd03          	ld	s10,96(a1)
    802049c2:	0685bd83          	ld	s11,104(a1)
    802049c6:	8082                	ret

00000000802049c8 <virtio_disk_init>:
        if (!(flag & 1)) break;
        i = next;
    }
}

void virtio_disk_init(void) {
    802049c8:	7179                	add	sp,sp,-48
    802049ca:	f406                	sd	ra,40(sp)
    802049cc:	f022                	sd	s0,32(sp)
    802049ce:	ec26                	sd	s1,24(sp)
    802049d0:	e84a                	sd	s2,16(sp)
    802049d2:	e44e                	sd	s3,8(sp)
    802049d4:	1800                	add	s0,sp,48
    uint32 status = 0;

    spinlock_init(&disk.lock, "virtio_disk");
    802049d6:	00002597          	auipc	a1,0x2
    802049da:	fd258593          	add	a1,a1,-46 # 802069a8 <syscalls+0x408>
    802049de:	0003d517          	auipc	a0,0x3d
    802049e2:	42a50513          	add	a0,a0,1066 # 80241e08 <disk+0x130>
    802049e6:	ffffc097          	auipc	ra,0xffffc
    802049ea:	df2080e7          	jalr	-526(ra) # 802007d8 <spinlock_init>
    return *mmio_reg(off);
    802049ee:	100017b7          	lui	a5,0x10001
    802049f2:	0007a903          	lw	s2,0(a5) # 10001000 <_start-0x701ff000>
    802049f6:	2901                	sext.w	s2,s2
    802049f8:	43c4                	lw	s1,4(a5)
    802049fa:	2481                	sext.w	s1,s1
    802049fc:	0087a983          	lw	s3,8(a5)
    80204a00:	2981                	sext.w	s3,s3
    80204a02:	47d8                	lw	a4,12(a5)
    uint32 magic = r32(VIRTIO_MMIO_MAGIC_VALUE);
    uint32 version = r32(VIRTIO_MMIO_VERSION);
    uint32 device_id = r32(VIRTIO_MMIO_DEVICE_ID);
    uint32 vendor_id = r32(VIRTIO_MMIO_VENDOR_ID);

    printf("virtio: magic=0x%x version=0x%x device=0x%x vendor=0x%x\n", magic, version, device_id, vendor_id);
    80204a04:	86ce                	mv	a3,s3
    80204a06:	8626                	mv	a2,s1
    80204a08:	85ca                	mv	a1,s2
    80204a0a:	00002517          	auipc	a0,0x2
    80204a0e:	fae50513          	add	a0,a0,-82 # 802069b8 <syscalls+0x418>
    80204a12:	ffffb097          	auipc	ra,0xffffb
    80204a16:	742080e7          	jalr	1858(ra) # 80200154 <printf>

    if (magic != 0x74726976 || device_id != 2) {
    80204a1a:	747277b7          	lui	a5,0x74727
    80204a1e:	97678793          	add	a5,a5,-1674 # 74726976 <_start-0xbad968a>
    80204a22:	00f91563          	bne	s2,a5,80204a2c <virtio_disk_init+0x64>
    80204a26:	4789                	li	a5,2
    80204a28:	00f98a63          	beq	s3,a5,80204a3c <virtio_disk_init+0x74>
        panic("virtio_disk_init: cannot find virtio disk");
    80204a2c:	00002517          	auipc	a0,0x2
    80204a30:	fcc50513          	add	a0,a0,-52 # 802069f8 <syscalls+0x458>
    80204a34:	ffffc097          	auipc	ra,0xffffc
    80204a38:	9a0080e7          	jalr	-1632(ra) # 802003d4 <panic>
    *mmio_reg(off) = val;
    80204a3c:	100017b7          	lui	a5,0x10001
    80204a40:	0607a823          	sw	zero,112(a5) # 10001070 <_start-0x701fef90>
    80204a44:	4605                	li	a2,1
    80204a46:	dbb0                	sw	a2,112(a5)
    80204a48:	470d                	li	a4,3
    80204a4a:	dbb8                	sw	a4,112(a5)
    return *mmio_reg(off);
    80204a4c:	4b98                	lw	a4,16(a5)
    w32(VIRTIO_MMIO_STATUS, status);

    // 4. Negotiate features
    uint32 features = r32(VIRTIO_MMIO_DEVICE_FEATURES);
    features &= ~(1 << 28); // No indirect descriptors
    features &= ~(1 << 24); // No event idx
    80204a4e:	ef0006b7          	lui	a3,0xef000
    80204a52:	16fd                	add	a3,a3,-1 # ffffffffeeffffff <__bss_end+0xffffffff6edbe1df>
    80204a54:	8f75                	and	a4,a4,a3
    *mmio_reg(off) = val;
    80204a56:	d398                	sw	a4,32(a5)
    status |= 2;
    80204a58:	478d                	li	a5,3
    w32(VIRTIO_MMIO_DRIVER_FEATURES, features);

    // 5. Set FEATURES_OK (Only for Version 2, but harmless in v1 usually, skip for safety if v1)
    // Legacy doesn't strictly require this step check, but we set status.
    if (version >= 2) {
    80204a5a:	00967a63          	bgeu	a2,s1,80204a6e <virtio_disk_init+0xa6>
    *mmio_reg(off) = val;
    80204a5e:	100017b7          	lui	a5,0x10001
    80204a62:	471d                	li	a4,7
    80204a64:	dbb8                	sw	a4,112(a5)
    return *mmio_reg(off);
    80204a66:	5bb8                	lw	a4,112(a5)
        status |= 4;
        w32(VIRTIO_MMIO_STATUS, status);
        if (!(r32(VIRTIO_MMIO_STATUS) & 4))
    80204a68:	8b11                	and	a4,a4,4
        status |= 4;
    80204a6a:	479d                	li	a5,7
        if (!(r32(VIRTIO_MMIO_STATUS) & 4))
    80204a6c:	c755                	beqz	a4,80204b18 <virtio_disk_init+0x150>
            panic("virtio_disk_init: features");
    }

    // 6. Set DRIVER_OK status bit
    status |= 8;
    80204a6e:	0087e793          	or	a5,a5,8
    *mmio_reg(off) = val;
    80204a72:	10001737          	lui	a4,0x10001
    80204a76:	db3c                	sw	a5,112(a4)
    80204a78:	02072823          	sw	zero,48(a4) # 10001030 <_start-0x701fefd0>
    return *mmio_reg(off);
    80204a7c:	5b5c                	lw	a5,52(a4)
    80204a7e:	2781                	sext.w	a5,a5
    w32(VIRTIO_MMIO_STATUS, status);

    // 7. Config queue 0
    w32(VIRTIO_MMIO_QUEUE_SEL, 0);
    uint32 max = r32(VIRTIO_MMIO_QUEUE_NUM_MAX);
    if (max == 0) panic("virtio_disk_init: no queue 0");
    80204a80:	c7d5                	beqz	a5,80204b2c <virtio_disk_init+0x164>
    if (max < NUM) panic("virtio_disk_init: queue too short");
    80204a82:	471d                	li	a4,7
    80204a84:	0af77c63          	bgeu	a4,a5,80204b3c <virtio_disk_init+0x174>
    *mmio_reg(off) = val;
    80204a88:	100017b7          	lui	a5,0x10001
    80204a8c:	4721                	li	a4,8
    80204a8e:	df98                	sw	a4,56(a5)
    80204a90:	6705                	lui	a4,0x1
    80204a92:	d798                	sw	a4,40(a5)
    // containing Desc, Avail, and Used rings. 
    // QEMU calculates offsets based on Page Size (4096).
    
    w32(VIRTIO_MMIO_GUEST_PAGE_SIZE, 4096); // Set page size to 4096

    disk.pages = kalloc(); // Allocate 4096 bytes
    80204a94:	ffffc097          	auipc	ra,0xffffc
    80204a98:	ba0080e7          	jalr	-1120(ra) # 80200634 <kalloc>
    80204a9c:	0003d797          	auipc	a5,0x3d
    80204aa0:	22a7be23          	sd	a0,572(a5) # 80241cd8 <disk>
    if (!disk.pages) panic("virtio_disk_init: kalloc");
    80204aa4:	c54d                	beqz	a0,80204b4e <virtio_disk_init+0x186>
    memset(disk.pages, 0, PGSIZE);
    80204aa6:	0003d497          	auipc	s1,0x3d
    80204aaa:	23248493          	add	s1,s1,562 # 80241cd8 <disk>
    80204aae:	6605                	lui	a2,0x1
    80204ab0:	4581                	li	a1,0
    80204ab2:	6088                	ld	a0,0(s1)
    80204ab4:	ffffc097          	auipc	ra,0xffffc
    80204ab8:	eee080e7          	jalr	-274(ra) # 802009a2 <memset>
    *mmio_reg(off) = val;
    80204abc:	10001737          	lui	a4,0x10001
    80204ac0:	6785                	lui	a5,0x1
    80204ac2:	df5c                	sw	a5,60(a4)
    // If we set PFN, QEMU expects physical address.
    
    // Let's try xv6-riscv standard way:
    // It assumes VIRTIO_MMIO_QUEUE_PFN points to the page.
    
    w32(VIRTIO_MMIO_QUEUE_PFN, (uint64)disk.pages >> 12);
    80204ac4:	609c                	ld	a5,0(s1)
    80204ac6:	83b1                	srl	a5,a5,0xc
    80204ac8:	2781                	sext.w	a5,a5
    *mmio_reg(off) = val;
    80204aca:	c33c                	sw	a5,64(a4)

    // Setup pointers manually for our software use
    disk.desc = (struct virtq_desc *)(disk.pages);
    80204acc:	609c                	ld	a5,0(s1)
    80204ace:	e49c                	sd	a5,8(s1)
    disk.avail = (struct virtq_avail *)(disk.pages + NUM * sizeof(struct virtq_desc));
    80204ad0:	08078793          	add	a5,a5,128 # 1080 <_start-0x801fef80>
    80204ad4:	e89c                	sd	a5,16(s1)
    *mmio_reg(off) = val;
    80204ad6:	08000793          	li	a5,128
    80204ada:	df5c                	sw	a5,60(a4)
    // Avail: 128. Size 6+16=22. End=150.
    // Used: RoundUp(150, 128) = 256.
    // So Used ring starts at offset 256.
    // Total size = 256 + 6 + 8*8 = 326 bytes. Fits in 4096.
    
    disk.used = (struct virtq_used *) (disk.pages + 256);
    80204adc:	609c                	ld	a5,0(s1)
    80204ade:	10078793          	add	a5,a5,256
    80204ae2:	ec9c                	sd	a5,24(s1)

    for (int i = 0; i < NUM; i++) {
        disk.free[i] = 1;
    80204ae4:	4785                	li	a5,1
    80204ae6:	02f48023          	sb	a5,32(s1)
    80204aea:	02f480a3          	sb	a5,33(s1)
    80204aee:	02f48123          	sb	a5,34(s1)
    80204af2:	02f481a3          	sb	a5,35(s1)
    80204af6:	02f48223          	sb	a5,36(s1)
    80204afa:	02f482a3          	sb	a5,37(s1)
    80204afe:	02f48323          	sb	a5,38(s1)
    80204b02:	02f483a3          	sb	a5,39(s1)
    }
    disk.used_idx = 0;
    80204b06:	02049423          	sh	zero,40(s1)
}
    80204b0a:	70a2                	ld	ra,40(sp)
    80204b0c:	7402                	ld	s0,32(sp)
    80204b0e:	64e2                	ld	s1,24(sp)
    80204b10:	6942                	ld	s2,16(sp)
    80204b12:	69a2                	ld	s3,8(sp)
    80204b14:	6145                	add	sp,sp,48
    80204b16:	8082                	ret
            panic("virtio_disk_init: features");
    80204b18:	00002517          	auipc	a0,0x2
    80204b1c:	f1050513          	add	a0,a0,-240 # 80206a28 <syscalls+0x488>
    80204b20:	ffffc097          	auipc	ra,0xffffc
    80204b24:	8b4080e7          	jalr	-1868(ra) # 802003d4 <panic>
        status |= 4;
    80204b28:	479d                	li	a5,7
    80204b2a:	b791                	j	80204a6e <virtio_disk_init+0xa6>
    if (max == 0) panic("virtio_disk_init: no queue 0");
    80204b2c:	00002517          	auipc	a0,0x2
    80204b30:	f1c50513          	add	a0,a0,-228 # 80206a48 <syscalls+0x4a8>
    80204b34:	ffffc097          	auipc	ra,0xffffc
    80204b38:	8a0080e7          	jalr	-1888(ra) # 802003d4 <panic>
    if (max < NUM) panic("virtio_disk_init: queue too short");
    80204b3c:	00002517          	auipc	a0,0x2
    80204b40:	f2c50513          	add	a0,a0,-212 # 80206a68 <syscalls+0x4c8>
    80204b44:	ffffc097          	auipc	ra,0xffffc
    80204b48:	890080e7          	jalr	-1904(ra) # 802003d4 <panic>
    80204b4c:	bf35                	j	80204a88 <virtio_disk_init+0xc0>
    if (!disk.pages) panic("virtio_disk_init: kalloc");
    80204b4e:	00002517          	auipc	a0,0x2
    80204b52:	f4250513          	add	a0,a0,-190 # 80206a90 <syscalls+0x4f0>
    80204b56:	ffffc097          	auipc	ra,0xffffc
    80204b5a:	87e080e7          	jalr	-1922(ra) # 802003d4 <panic>
    80204b5e:	b7a1                	j	80204aa6 <virtio_disk_init+0xde>

0000000080204b60 <virtio_disk_intr>:
    free_chain(idx[0]);

    release(&disk.lock);
}

void virtio_disk_intr(void) {
    80204b60:	1101                	add	sp,sp,-32
    80204b62:	ec06                	sd	ra,24(sp)
    80204b64:	e822                	sd	s0,16(sp)
    80204b66:	e426                	sd	s1,8(sp)
    80204b68:	e04a                	sd	s2,0(sp)
    80204b6a:	1000                	add	s0,sp,32
    acquire(&disk.lock);
    80204b6c:	0003d497          	auipc	s1,0x3d
    80204b70:	16c48493          	add	s1,s1,364 # 80241cd8 <disk>
    80204b74:	0003d517          	auipc	a0,0x3d
    80204b78:	29450513          	add	a0,a0,660 # 80241e08 <disk+0x130>
    80204b7c:	ffffc097          	auipc	ra,0xffffc
    80204b80:	cbe080e7          	jalr	-834(ra) # 8020083a <acquire>
    __sync_synchronize();
    80204b84:	0ff0000f          	fence

    uint16 used_idx_dev = *(volatile uint16*)&disk.used->idx;
    80204b88:	6c9c                	ld	a5,24(s1)
    80204b8a:	0027d783          	lhu	a5,2(a5)

    while (disk.used_idx != used_idx_dev) {
    80204b8e:	0284d703          	lhu	a4,40(s1)
    80204b92:	04f70c63          	beq	a4,a5,80204bea <virtio_disk_intr+0x8a>
    80204b96:	03079613          	sll	a2,a5,0x30
    80204b9a:	9241                	srl	a2,a2,0x30
        __sync_synchronize();
        int id = disk.used->ring[disk.used_idx % NUM].id;
        disk.used_idx++;
        __sync_synchronize();

        if (id >= NUM) continue;
    80204b9c:	491d                	li	s2,7
    80204b9e:	a029                	j	80204ba8 <virtio_disk_intr+0x48>
    while (disk.used_idx != used_idx_dev) {
    80204ba0:	0284d783          	lhu	a5,40(s1)
    80204ba4:	04c78363          	beq	a5,a2,80204bea <virtio_disk_intr+0x8a>
        __sync_synchronize();
    80204ba8:	0ff0000f          	fence
        int id = disk.used->ring[disk.used_idx % NUM].id;
    80204bac:	0284d703          	lhu	a4,40(s1)
    80204bb0:	6c9c                	ld	a5,24(s1)
    80204bb2:	00777693          	and	a3,a4,7
    80204bb6:	068e                	sll	a3,a3,0x3
    80204bb8:	97b6                	add	a5,a5,a3
    80204bba:	43dc                	lw	a5,4(a5)
        disk.used_idx++;
    80204bbc:	2705                	addw	a4,a4,1 # 10001001 <_start-0x701fefff>
    80204bbe:	02e49423          	sh	a4,40(s1)
        __sync_synchronize();
    80204bc2:	0ff0000f          	fence
        if (id >= NUM) continue;
    80204bc6:	fcf94de3          	blt	s2,a5,80204ba0 <virtio_disk_intr+0x40>
        struct buf *b = disk.info[id].b;
    80204bca:	0796                	sll	a5,a5,0x5
    80204bcc:	97a6                	add	a5,a5,s1
    80204bce:	7b88                	ld	a0,48(a5)
        if (b == 0) continue;
    80204bd0:	d961                	beqz	a0,80204ba0 <virtio_disk_intr+0x40>

        b->disk = 0;
    80204bd2:	00052223          	sw	zero,4(a0)
        wakeup(b);
    80204bd6:	ffffd097          	auipc	ra,0xffffd
    80204bda:	cc8080e7          	jalr	-824(ra) # 8020189e <wakeup>
        
        used_idx_dev = *(volatile uint16*)&disk.used->idx;
    80204bde:	6c9c                	ld	a5,24(s1)
    80204be0:	0027d603          	lhu	a2,2(a5)
    80204be4:	1642                	sll	a2,a2,0x30
    80204be6:	9241                	srl	a2,a2,0x30
    80204be8:	bf65                	j	80204ba0 <virtio_disk_intr+0x40>
    }
    release(&disk.lock);
    80204bea:	0003d517          	auipc	a0,0x3d
    80204bee:	21e50513          	add	a0,a0,542 # 80241e08 <disk+0x130>
    80204bf2:	ffffc097          	auipc	ra,0xffffc
    80204bf6:	d3a080e7          	jalr	-710(ra) # 8020092c <release>
}
    80204bfa:	60e2                	ld	ra,24(sp)
    80204bfc:	6442                	ld	s0,16(sp)
    80204bfe:	64a2                	ld	s1,8(sp)
    80204c00:	6902                	ld	s2,0(sp)
    80204c02:	6105                	add	sp,sp,32
    80204c04:	8082                	ret

0000000080204c06 <virtio_disk_rw>:
void virtio_disk_rw(struct buf *b, int write) {
    80204c06:	711d                	add	sp,sp,-96
    80204c08:	ec86                	sd	ra,88(sp)
    80204c0a:	e8a2                	sd	s0,80(sp)
    80204c0c:	e4a6                	sd	s1,72(sp)
    80204c0e:	e0ca                	sd	s2,64(sp)
    80204c10:	fc4e                	sd	s3,56(sp)
    80204c12:	f852                	sd	s4,48(sp)
    80204c14:	f456                	sd	s5,40(sp)
    80204c16:	f05a                	sd	s6,32(sp)
    80204c18:	ec5e                	sd	s7,24(sp)
    80204c1a:	e862                	sd	s8,16(sp)
    80204c1c:	1080                	add	s0,sp,96
    80204c1e:	892a                	mv	s2,a0
    80204c20:	84ae                	mv	s1,a1
    acquire(&disk.lock);
    80204c22:	0003d517          	auipc	a0,0x3d
    80204c26:	1e650513          	add	a0,a0,486 # 80241e08 <disk+0x130>
    80204c2a:	ffffc097          	auipc	ra,0xffffc
    80204c2e:	c10080e7          	jalr	-1008(ra) # 8020083a <acquire>
    for (int i = 0; i < 3; i++) {
    80204c32:	fa040513          	add	a0,s0,-96
    80204c36:	fac40593          	add	a1,s0,-84
    for (int i = 0; i < NUM; i++) {
    80204c3a:	4801                	li	a6,0
    80204c3c:	4621                	li	a2,8
            disk.free[i] = 0;
    80204c3e:	0003d897          	auipc	a7,0x3d
    80204c42:	09a88893          	add	a7,a7,154 # 80241cd8 <disk>
    80204c46:	a039                	j	80204c54 <virtio_disk_rw+0x4e>
    80204c48:	00f88733          	add	a4,a7,a5
    80204c4c:	02070023          	sb	zero,32(a4)
        while ((idx[i] = alloc_desc()) < 0) { }
    80204c50:	0007df63          	bgez	a5,80204c6e <virtio_disk_rw+0x68>
    for (int i = 0; i < NUM; i++) {
    80204c54:	0003d717          	auipc	a4,0x3d
    80204c58:	08470713          	add	a4,a4,132 # 80241cd8 <disk>
    80204c5c:	87c2                	mv	a5,a6
        if (disk.free[i]) {
    80204c5e:	02074683          	lbu	a3,32(a4)
    80204c62:	f2fd                	bnez	a3,80204c48 <virtio_disk_rw+0x42>
    for (int i = 0; i < NUM; i++) {
    80204c64:	2785                	addw	a5,a5,1
    80204c66:	0705                	add	a4,a4,1
    80204c68:	fec79be3          	bne	a5,a2,80204c5e <virtio_disk_rw+0x58>
    80204c6c:	b7e5                	j	80204c54 <virtio_disk_rw+0x4e>
    80204c6e:	c11c                	sw	a5,0(a0)
    for (int i = 0; i < 3; i++) {
    80204c70:	0511                	add	a0,a0,4
    80204c72:	feb511e3          	bne	a0,a1,80204c54 <virtio_disk_rw+0x4e>
    struct virtio_blk_req *cmd = &disk.info[idx[0]].cmd;
    80204c76:	fa042a83          	lw	s5,-96(s0)
    80204c7a:	002a8993          	add	s3,s5,2
    80204c7e:	0996                	sll	s3,s3,0x5
    80204c80:	0003da17          	auipc	s4,0x3d
    80204c84:	058a0a13          	add	s4,s4,88 # 80241cd8 <disk>
    80204c88:	013a0b33          	add	s6,s4,s3
    memset(cmd, 0, sizeof(*cmd));
    80204c8c:	4641                	li	a2,16
    80204c8e:	4581                	li	a1,0
    80204c90:	855a                	mv	a0,s6
    80204c92:	ffffc097          	auipc	ra,0xffffc
    80204c96:	d10080e7          	jalr	-752(ra) # 802009a2 <memset>
    cmd->type = write ? 1 : 0;
    80204c9a:	009037b3          	snez	a5,s1
    80204c9e:	00fb2023          	sw	a5,0(s6)
    cmd->reserved = 0;
    80204ca2:	000b2223          	sw	zero,4(s6)
    cmd->sector = (uint64)b->blockno * (BSIZE / 512);
    80204ca6:	00c96783          	lwu	a5,12(s2)
    80204caa:	0786                	sll	a5,a5,0x1
    80204cac:	00fb3423          	sd	a5,8(s6)
    disk.desc[idx[0]].addr = (uint64)cmd;
    80204cb0:	004a9793          	sll	a5,s5,0x4
    80204cb4:	008a3703          	ld	a4,8(s4)
    80204cb8:	973e                	add	a4,a4,a5
    80204cba:	01673023          	sd	s6,0(a4)
    disk.desc[idx[0]].len = sizeof(*cmd);
    80204cbe:	008a3703          	ld	a4,8(s4)
    80204cc2:	973e                	add	a4,a4,a5
    80204cc4:	46c1                	li	a3,16
    80204cc6:	c714                	sw	a3,8(a4)
    disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80204cc8:	008a3703          	ld	a4,8(s4)
    80204ccc:	973e                	add	a4,a4,a5
    80204cce:	4685                	li	a3,1
    80204cd0:	00d71623          	sh	a3,12(a4)
    disk.desc[idx[0]].next = idx[1];
    80204cd4:	fa442703          	lw	a4,-92(s0)
    80204cd8:	008a3683          	ld	a3,8(s4)
    80204cdc:	97b6                	add	a5,a5,a3
    80204cde:	00e79723          	sh	a4,14(a5)
    disk.desc[idx[1]].addr = (uint64)b->data;
    80204ce2:	0712                	sll	a4,a4,0x4
    80204ce4:	008a3783          	ld	a5,8(s4)
    80204ce8:	97ba                	add	a5,a5,a4
    80204cea:	05890693          	add	a3,s2,88
    80204cee:	e394                	sd	a3,0(a5)
    disk.desc[idx[1]].len = BSIZE;
    80204cf0:	008a3783          	ld	a5,8(s4)
    80204cf4:	97ba                	add	a5,a5,a4
    80204cf6:	40000693          	li	a3,1024
    80204cfa:	c794                	sw	a3,8(a5)
    if (write) disk.desc[idx[1]].flags = 0; 
    80204cfc:	14048063          	beqz	s1,80204e3c <virtio_disk_rw+0x236>
    80204d00:	0003d797          	auipc	a5,0x3d
    80204d04:	fe07b783          	ld	a5,-32(a5) # 80241ce0 <disk+0x8>
    80204d08:	97ba                	add	a5,a5,a4
    80204d0a:	00079623          	sh	zero,12(a5)
    disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80204d0e:	0003d797          	auipc	a5,0x3d
    80204d12:	fca78793          	add	a5,a5,-54 # 80241cd8 <disk>
    80204d16:	6794                	ld	a3,8(a5)
    80204d18:	96ba                	add	a3,a3,a4
    80204d1a:	00c6d603          	lhu	a2,12(a3)
    80204d1e:	00166613          	or	a2,a2,1
    80204d22:	00c69623          	sh	a2,12(a3)
    disk.desc[idx[1]].next = idx[2];
    80204d26:	fa842683          	lw	a3,-88(s0)
    80204d2a:	6790                	ld	a2,8(a5)
    80204d2c:	9732                	add	a4,a4,a2
    80204d2e:	00d71723          	sh	a3,14(a4)
    disk.info[idx[0]].status = 0xff;
    80204d32:	005a9613          	sll	a2,s5,0x5
    80204d36:	963e                	add	a2,a2,a5
    80204d38:	577d                	li	a4,-1
    80204d3a:	02e60c23          	sb	a4,56(a2) # 1038 <_start-0x801fefc8>
    disk.desc[idx[2]].addr = (uint64)&disk.info[idx[0]].status;
    80204d3e:	00469713          	sll	a4,a3,0x4
    80204d42:	678c                	ld	a1,8(a5)
    80204d44:	95ba                	add	a1,a1,a4
    80204d46:	ff898693          	add	a3,s3,-8
    80204d4a:	96be                	add	a3,a3,a5
    80204d4c:	e194                	sd	a3,0(a1)
    disk.desc[idx[2]].len = 1;
    80204d4e:	6794                	ld	a3,8(a5)
    80204d50:	96ba                	add	a3,a3,a4
    80204d52:	4585                	li	a1,1
    80204d54:	c68c                	sw	a1,8(a3)
    disk.desc[idx[2]].flags = VRING_DESC_F_WRITE;
    80204d56:	6794                	ld	a3,8(a5)
    80204d58:	96ba                	add	a3,a3,a4
    80204d5a:	4509                	li	a0,2
    80204d5c:	00a69623          	sh	a0,12(a3)
    disk.desc[idx[2]].next = 0;
    80204d60:	6794                	ld	a3,8(a5)
    80204d62:	9736                	add	a4,a4,a3
    80204d64:	00071723          	sh	zero,14(a4)
    b->disk = 1;
    80204d68:	00b92223          	sw	a1,4(s2)
    disk.info[idx[0]].b = b;
    80204d6c:	03263823          	sd	s2,48(a2)
    disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80204d70:	6b94                	ld	a3,16(a5)
    80204d72:	0026d703          	lhu	a4,2(a3)
    80204d76:	8b1d                	and	a4,a4,7
    80204d78:	0706                	sll	a4,a4,0x1
    80204d7a:	96ba                	add	a3,a3,a4
    80204d7c:	01569223          	sh	s5,4(a3)
    __sync_synchronize();
    80204d80:	0ff0000f          	fence
    disk.avail->idx++;
    80204d84:	6b98                	ld	a4,16(a5)
    80204d86:	00275783          	lhu	a5,2(a4)
    80204d8a:	2785                	addw	a5,a5,1
    80204d8c:	00f71123          	sh	a5,2(a4)
    __sync_synchronize();
    80204d90:	0ff0000f          	fence
    *mmio_reg(off) = val;
    80204d94:	100017b7          	lui	a5,0x10001
    80204d98:	0407a823          	sw	zero,80(a5) # 10001050 <_start-0x701fefb0>
    if (write) disk_writes++;
    80204d9c:	c8cd                	beqz	s1,80204e4e <virtio_disk_rw+0x248>
    80204d9e:	0000b717          	auipc	a4,0xb
    80204da2:	28a70713          	add	a4,a4,650 # 80210028 <disk_writes>
    80204da6:	631c                	ld	a5,0(a4)
    80204da8:	0785                	add	a5,a5,1
    80204daa:	e31c                	sd	a5,0(a4)
    while (*(volatile char*)&disk.info[idx[0]].status == 0xff) {
    80204dac:	fa042a83          	lw	s5,-96(s0)
    80204db0:	005a9713          	sll	a4,s5,0x5
    80204db4:	0003d797          	auipc	a5,0x3d
    80204db8:	f2478793          	add	a5,a5,-220 # 80241cd8 <disk>
    80204dbc:	97ba                	add	a5,a5,a4
    80204dbe:	0387c783          	lbu	a5,56(a5)
    80204dc2:	0ff7f793          	zext.b	a5,a5
    80204dc6:	0ff00713          	li	a4,255
    80204dca:	04e79363          	bne	a5,a4,80204e10 <virtio_disk_rw+0x20a>
        release(&disk.lock);
    80204dce:	0003d497          	auipc	s1,0x3d
    80204dd2:	03a48493          	add	s1,s1,58 # 80241e08 <disk+0x130>
    while (*(volatile char*)&disk.info[idx[0]].status == 0xff) {
    80204dd6:	005a9793          	sll	a5,s5,0x5
    80204dda:	0003d997          	auipc	s3,0x3d
    80204dde:	efe98993          	add	s3,s3,-258 # 80241cd8 <disk>
    80204de2:	99be                	add	s3,s3,a5
    80204de4:	0ff00a13          	li	s4,255
        release(&disk.lock);
    80204de8:	8526                	mv	a0,s1
    80204dea:	ffffc097          	auipc	ra,0xffffc
    80204dee:	b42080e7          	jalr	-1214(ra) # 8020092c <release>
        virtio_disk_intr(); 
    80204df2:	00000097          	auipc	ra,0x0
    80204df6:	d6e080e7          	jalr	-658(ra) # 80204b60 <virtio_disk_intr>
        acquire(&disk.lock);
    80204dfa:	8526                	mv	a0,s1
    80204dfc:	ffffc097          	auipc	ra,0xffffc
    80204e00:	a3e080e7          	jalr	-1474(ra) # 8020083a <acquire>
    while (*(volatile char*)&disk.info[idx[0]].status == 0xff) {
    80204e04:	0389c783          	lbu	a5,56(s3)
    80204e08:	0ff7f793          	zext.b	a5,a5
    80204e0c:	fd478ee3          	beq	a5,s4,80204de8 <virtio_disk_rw+0x1e2>
    disk.info[idx[0]].b = 0;
    80204e10:	005a9713          	sll	a4,s5,0x5
    80204e14:	0003d797          	auipc	a5,0x3d
    80204e18:	ec478793          	add	a5,a5,-316 # 80241cd8 <disk>
    80204e1c:	97ba                	add	a5,a5,a4
    80204e1e:	0207b823          	sd	zero,48(a5)
    b->disk = 0;
    80204e22:	00092223          	sw	zero,4(s2)
        int flag = disk.desc[i].flags;
    80204e26:	0003d497          	auipc	s1,0x3d
    80204e2a:	eb248493          	add	s1,s1,-334 # 80241cd8 <disk>
    if (i >= NUM) panic("free_desc");
    80204e2e:	4b9d                	li	s7,7
    80204e30:	00002c17          	auipc	s8,0x2
    80204e34:	c80c0c13          	add	s8,s8,-896 # 80206ab0 <syscalls+0x510>
    disk.free[i] = 1;
    80204e38:	4b05                	li	s6,1
    80204e3a:	a889                	j	80204e8c <virtio_disk_rw+0x286>
    else disk.desc[idx[1]].flags = VRING_DESC_F_WRITE;
    80204e3c:	0003d797          	auipc	a5,0x3d
    80204e40:	ea47b783          	ld	a5,-348(a5) # 80241ce0 <disk+0x8>
    80204e44:	97ba                	add	a5,a5,a4
    80204e46:	4689                	li	a3,2
    80204e48:	00d79623          	sh	a3,12(a5)
    80204e4c:	b5c9                	j	80204d0e <virtio_disk_rw+0x108>
    else disk_reads++;
    80204e4e:	0000b717          	auipc	a4,0xb
    80204e52:	1e270713          	add	a4,a4,482 # 80210030 <disk_reads>
    80204e56:	631c                	ld	a5,0(a4)
    80204e58:	0785                	add	a5,a5,1
    80204e5a:	e31c                	sd	a5,0(a4)
    80204e5c:	bf81                	j	80204dac <virtio_disk_rw+0x1a6>
    disk.desc[i].addr = 0;
    80204e5e:	649c                	ld	a5,8(s1)
    80204e60:	97ca                	add	a5,a5,s2
    80204e62:	0007b023          	sd	zero,0(a5)
    disk.desc[i].len = 0;
    80204e66:	649c                	ld	a5,8(s1)
    80204e68:	97ca                	add	a5,a5,s2
    80204e6a:	0007a423          	sw	zero,8(a5)
    disk.desc[i].flags = 0;
    80204e6e:	649c                	ld	a5,8(s1)
    80204e70:	97ca                	add	a5,a5,s2
    80204e72:	00079623          	sh	zero,12(a5)
    disk.desc[i].next = 0;
    80204e76:	649c                	ld	a5,8(s1)
    80204e78:	97ca                	add	a5,a5,s2
    80204e7a:	00079723          	sh	zero,14(a5)
    disk.free[i] = 1;
    80204e7e:	99a6                	add	s3,s3,s1
    80204e80:	03698023          	sb	s6,32(s3)
        if (!(flag & 1)) break;
    80204e84:	001a7a13          	and	s4,s4,1
    80204e88:	020a0363          	beqz	s4,80204eae <virtio_disk_rw+0x2a8>
        int flag = disk.desc[i].flags;
    80204e8c:	004a9913          	sll	s2,s5,0x4
    80204e90:	649c                	ld	a5,8(s1)
    80204e92:	97ca                	add	a5,a5,s2
    80204e94:	00c7da03          	lhu	s4,12(a5)
        int next = disk.desc[i].next;
    80204e98:	89d6                	mv	s3,s5
    80204e9a:	00e7da83          	lhu	s5,14(a5)
    if (i >= NUM) panic("free_desc");
    80204e9e:	fd3bd0e3          	bge	s7,s3,80204e5e <virtio_disk_rw+0x258>
    80204ea2:	8562                	mv	a0,s8
    80204ea4:	ffffb097          	auipc	ra,0xffffb
    80204ea8:	530080e7          	jalr	1328(ra) # 802003d4 <panic>
    80204eac:	bf4d                	j	80204e5e <virtio_disk_rw+0x258>
    release(&disk.lock);
    80204eae:	0003d517          	auipc	a0,0x3d
    80204eb2:	f5a50513          	add	a0,a0,-166 # 80241e08 <disk+0x130>
    80204eb6:	ffffc097          	auipc	ra,0xffffc
    80204eba:	a76080e7          	jalr	-1418(ra) # 8020092c <release>
}
    80204ebe:	60e6                	ld	ra,88(sp)
    80204ec0:	6446                	ld	s0,80(sp)
    80204ec2:	64a6                	ld	s1,72(sp)
    80204ec4:	6906                	ld	s2,64(sp)
    80204ec6:	79e2                	ld	s3,56(sp)
    80204ec8:	7a42                	ld	s4,48(sp)
    80204eca:	7aa2                	ld	s5,40(sp)
    80204ecc:	7b02                	ld	s6,32(sp)
    80204ece:	6be2                	ld	s7,24(sp)
    80204ed0:	6c42                	ld	s8,16(sp)
    80204ed2:	6125                	add	sp,sp,96
    80204ed4:	8082                	ret

0000000080204ed6 <get_disk_read_count>:

uint64 get_disk_read_count(void) { return disk_reads; }
    80204ed6:	1141                	add	sp,sp,-16
    80204ed8:	e422                	sd	s0,8(sp)
    80204eda:	0800                	add	s0,sp,16
    80204edc:	0000b517          	auipc	a0,0xb
    80204ee0:	15453503          	ld	a0,340(a0) # 80210030 <disk_reads>
    80204ee4:	6422                	ld	s0,8(sp)
    80204ee6:	0141                	add	sp,sp,16
    80204ee8:	8082                	ret

0000000080204eea <get_disk_write_count>:
uint64 get_disk_write_count(void) { return disk_writes; }
    80204eea:	1141                	add	sp,sp,-16
    80204eec:	e422                	sd	s0,8(sp)
    80204eee:	0800                	add	s0,sp,16
    80204ef0:	0000b517          	auipc	a0,0xb
    80204ef4:	13853503          	ld	a0,312(a0) # 80210028 <disk_writes>
    80204ef8:	6422                	ld	s0,8(sp)
    80204efa:	0141                	add	sp,sp,16
    80204efc:	8082                	ret

0000000080204efe <assert>:
#include "stat.h"

#define NULL ((void*)0)

void assert(int condition) {
    if (!condition) {
    80204efe:	c111                	beqz	a0,80204f02 <assert+0x4>
    80204f00:	8082                	ret
void assert(int condition) {
    80204f02:	1141                	add	sp,sp,-16
    80204f04:	e406                	sd	ra,8(sp)
    80204f06:	e022                	sd	s0,0(sp)
    80204f08:	0800                	add	s0,sp,16
        printf("ASSERTION FAILED!\n");
    80204f0a:	00002517          	auipc	a0,0x2
    80204f0e:	bb650513          	add	a0,a0,-1098 # 80206ac0 <syscalls+0x520>
    80204f12:	ffffb097          	auipc	ra,0xffffb
    80204f16:	242080e7          	jalr	578(ra) # 80200154 <printf>
        while(1);
    80204f1a:	a001                	j	80204f1a <assert+0x1c>

0000000080204f1c <test_cow_fork>:
    }
}

// 模拟 User 内存操作的测试
void test_cow_fork(void) {
    80204f1c:	7139                	add	sp,sp,-64
    80204f1e:	fc06                	sd	ra,56(sp)
    80204f20:	f822                	sd	s0,48(sp)
    80204f22:	f426                	sd	s1,40(sp)
    80204f24:	f04a                	sd	s2,32(sp)
    80204f26:	ec4e                	sd	s3,24(sp)
    80204f28:	e852                	sd	s4,16(sp)
    80204f2a:	e456                	sd	s5,8(sp)
    80204f2c:	e05a                	sd	s6,0(sp)
    80204f2e:	0080                	add	s0,sp,64
    printf("\n=== Project 5: COW Fork Test ===\n");
    80204f30:	00002517          	auipc	a0,0x2
    80204f34:	ba850513          	add	a0,a0,-1112 # 80206ad8 <syscalls+0x538>
    80204f38:	ffffb097          	auipc	ra,0xffffb
    80204f3c:	21c080e7          	jalr	540(ra) # 80200154 <printf>

    // 1. 手动分配一个物理页，写入数据
    char *pa = kalloc();
    80204f40:	ffffb097          	auipc	ra,0xffffb
    80204f44:	6f4080e7          	jalr	1780(ra) # 80200634 <kalloc>
    80204f48:	84aa                	mv	s1,a0
    memset(pa, 0, PGSIZE);
    80204f4a:	6605                	lui	a2,0x1
    80204f4c:	4581                	li	a1,0
    80204f4e:	ffffc097          	auipc	ra,0xffffc
    80204f52:	a54080e7          	jalr	-1452(ra) # 802009a2 <memset>
    safestrcpy(pa, "PARENT DATA", 16);
    80204f56:	4641                	li	a2,16
    80204f58:	00002597          	auipc	a1,0x2
    80204f5c:	ba858593          	add	a1,a1,-1112 # 80206b00 <syscalls+0x560>
    80204f60:	8526                	mv	a0,s1
    80204f62:	ffffc097          	auipc	ra,0xffffc
    80204f66:	b8a080e7          	jalr	-1142(ra) # 80200aec <safestrcpy>
    int initial_ref = kref_get(pa);
    80204f6a:	8526                	mv	a0,s1
    80204f6c:	ffffc097          	auipc	ra,0xffffc
    80204f70:	800080e7          	jalr	-2048(ra) # 8020076c <kref_get>
    80204f74:	862a                	mv	a2,a0
    printf("Allocated PA %p, Ref Count: %d\n", pa, initial_ref);
    80204f76:	85a6                	mv	a1,s1
    80204f78:	00002517          	auipc	a0,0x2
    80204f7c:	b9850513          	add	a0,a0,-1128 # 80206b10 <syscalls+0x570>
    80204f80:	ffffb097          	auipc	ra,0xffffb
    80204f84:	1d4080e7          	jalr	468(ra) # 80200154 <printf>

    // 2. 创建父页表
    pagetable_t parent_pt = create_pagetable();
    80204f88:	ffffc097          	auipc	ra,0xffffc
    80204f8c:	dfc080e7          	jalr	-516(ra) # 80200d84 <create_pagetable>
    80204f90:	892a                	mv	s2,a0
    uint64 va = 0x1000;
    // 映射为可写
    map_page(parent_pt, va, (uint64)pa, PTE_R | PTE_W | PTE_U);
    80204f92:	8a26                	mv	s4,s1
    80204f94:	46d9                	li	a3,22
    80204f96:	8626                	mv	a2,s1
    80204f98:	6585                	lui	a1,0x1
    80204f9a:	ffffc097          	auipc	ra,0xffffc
    80204f9e:	e32080e7          	jalr	-462(ra) # 80200dcc <map_page>
    
    printf("Mapped VA %p to PA %p in Parent PT\n", va, pa);
    80204fa2:	8626                	mv	a2,s1
    80204fa4:	6585                	lui	a1,0x1
    80204fa6:	00002517          	auipc	a0,0x2
    80204faa:	b8a50513          	add	a0,a0,-1142 # 80206b30 <syscalls+0x590>
    80204fae:	ffffb097          	auipc	ra,0xffffb
    80204fb2:	1a6080e7          	jalr	422(ra) # 80200154 <printf>

    // 3. 模拟 Fork (uvmcopy)
    printf("Forking (uvmcopy)...\n");
    80204fb6:	00002517          	auipc	a0,0x2
    80204fba:	ba250513          	add	a0,a0,-1118 # 80206b58 <syscalls+0x5b8>
    80204fbe:	ffffb097          	auipc	ra,0xffffb
    80204fc2:	196080e7          	jalr	406(ra) # 80200154 <printf>
    pagetable_t child_pt = create_pagetable();
    80204fc6:	ffffc097          	auipc	ra,0xffffc
    80204fca:	dbe080e7          	jalr	-578(ra) # 80200d84 <create_pagetable>
    80204fce:	8aaa                	mv	s5,a0
    uvmcopy(parent_pt, child_pt, va + PGSIZE); 
    80204fd0:	6609                	lui	a2,0x2
    80204fd2:	85aa                	mv	a1,a0
    80204fd4:	854a                	mv	a0,s2
    80204fd6:	ffffc097          	auipc	ra,0xffffc
    80204fda:	ec0080e7          	jalr	-320(ra) # 80200e96 <uvmcopy>

    // 4. 验证 COW 状态
    pte_t *pte_p = walk_lookup(parent_pt, va);
    80204fde:	6585                	lui	a1,0x1
    80204fe0:	854a                	mv	a0,s2
    80204fe2:	ffffc097          	auipc	ra,0xffffc
    80204fe6:	dd0080e7          	jalr	-560(ra) # 80200db2 <walk_lookup>
    80204fea:	892a                	mv	s2,a0
    pte_t *pte_c = walk_lookup(child_pt, va);
    80204fec:	6585                	lui	a1,0x1
    80204fee:	8556                	mv	a0,s5
    80204ff0:	ffffc097          	auipc	ra,0xffffc
    80204ff4:	dc2080e7          	jalr	-574(ra) # 80200db2 <walk_lookup>
    80204ff8:	8b2a                	mv	s6,a0

    int ref_after_fork = kref_get(pa);
    80204ffa:	8526                	mv	a0,s1
    80204ffc:	ffffb097          	auipc	ra,0xffffb
    80205000:	770080e7          	jalr	1904(ra) # 8020076c <kref_get>
    80205004:	89aa                	mv	s3,a0
    printf("Ref Count after fork: %d (Expected 2)\n", ref_after_fork);
    80205006:	85aa                	mv	a1,a0
    80205008:	00002517          	auipc	a0,0x2
    8020500c:	b6850513          	add	a0,a0,-1176 # 80206b70 <syscalls+0x5d0>
    80205010:	ffffb097          	auipc	ra,0xffffb
    80205014:	144080e7          	jalr	324(ra) # 80200154 <printf>
    
    if (ref_after_fork != 2) panic("COW Test Fail: Ref count incorrect");
    80205018:	4789                	li	a5,2
    8020501a:	12f99363          	bne	s3,a5,80205140 <test_cow_fork+0x224>
    if (*pte_p & PTE_W) panic("COW Test Fail: Parent still writable");
    8020501e:	00093783          	ld	a5,0(s2)
    80205022:	8b91                	and	a5,a5,4
    80205024:	12079763          	bnez	a5,80205152 <test_cow_fork+0x236>
    if (*pte_c & PTE_W) panic("COW Test Fail: Child still writable");
    80205028:	000b3783          	ld	a5,0(s6)
    8020502c:	8b91                	and	a5,a5,4
    8020502e:	12079b63          	bnez	a5,80205164 <test_cow_fork+0x248>
    if (!(*pte_p & PTE_COW)) panic("COW Test Fail: Parent COW bit not set");
    80205032:	00093783          	ld	a5,0(s2)
    80205036:	1007f793          	and	a5,a5,256
    8020503a:	12078e63          	beqz	a5,80205176 <test_cow_fork+0x25a>
    if (!(*pte_c & PTE_COW)) panic("COW Test Fail: Child COW bit not set");
    8020503e:	000b3783          	ld	a5,0(s6)
    80205042:	1007f793          	and	a5,a5,256
    80205046:	14078163          	beqz	a5,80205188 <test_cow_fork+0x26c>

    printf("COW flags set correctly. Write permission removed.\n");
    8020504a:	00002517          	auipc	a0,0x2
    8020504e:	c1650513          	add	a0,a0,-1002 # 80206c60 <syscalls+0x6c0>
    80205052:	ffffb097          	auipc	ra,0xffffb
    80205056:	102080e7          	jalr	258(ra) # 80200154 <printf>

    // 5. 模拟写操作触发 Page Fault (Child Write)
    printf("Simulating Child Write to VA %p (Triggering Page Fault)...\n", va);
    8020505a:	6585                	lui	a1,0x1
    8020505c:	00002517          	auipc	a0,0x2
    80205060:	c3c50513          	add	a0,a0,-964 # 80206c98 <syscalls+0x6f8>
    80205064:	ffffb097          	auipc	ra,0xffffb
    80205068:	0f0080e7          	jalr	240(ra) # 80200154 <printf>
    
    // 手动调用 cow_alloc 模拟 trap handler 的行为
    if (cow_alloc(child_pt, va) < 0) panic("COW Allocation Failed");
    8020506c:	6585                	lui	a1,0x1
    8020506e:	8556                	mv	a0,s5
    80205070:	ffffc097          	auipc	ra,0xffffc
    80205074:	d7a080e7          	jalr	-646(ra) # 80200dea <cow_alloc>
    80205078:	12054163          	bltz	a0,8020519a <test_cow_fork+0x27e>

    // 6. 验证写后状态
    pte_c = walk_lookup(child_pt, va);
    8020507c:	6585                	lui	a1,0x1
    8020507e:	8556                	mv	a0,s5
    80205080:	ffffc097          	auipc	ra,0xffffc
    80205084:	d32080e7          	jalr	-718(ra) # 80200db2 <walk_lookup>
    80205088:	89aa                	mv	s3,a0
    uint64 pa_child_new = PTE2PA(*pte_c);
    8020508a:	00053903          	ld	s2,0(a0)
    8020508e:	00a95913          	srl	s2,s2,0xa
    80205092:	0932                	sll	s2,s2,0xc
    
    printf("Child New PA: %p\n", (void*)pa_child_new);
    80205094:	85ca                	mv	a1,s2
    80205096:	00002517          	auipc	a0,0x2
    8020509a:	c5a50513          	add	a0,a0,-934 # 80206cf0 <syscalls+0x750>
    8020509e:	ffffb097          	auipc	ra,0xffffb
    802050a2:	0b6080e7          	jalr	182(ra) # 80200154 <printf>
    
    if (pa_child_new == (uint64)pa) panic("COW Test Fail: Child still points to old PA");
    802050a6:	112a0363          	beq	s4,s2,802051ac <test_cow_fork+0x290>
    if (!(*pte_c & PTE_W)) panic("COW Test Fail: Child page not writable after fault");
    802050aa:	0009b783          	ld	a5,0(s3)
    802050ae:	8b91                	and	a5,a5,4
    802050b0:	10078763          	beqz	a5,802051be <test_cow_fork+0x2a2>
    if (*pte_c & PTE_COW) panic("COW Test Fail: Child COW bit still set");
    802050b4:	0009b783          	ld	a5,0(s3)
    802050b8:	1007f793          	and	a5,a5,256
    802050bc:	10079a63          	bnez	a5,802051d0 <test_cow_fork+0x2b4>

    int ref_after_write = kref_get(pa);
    802050c0:	8526                	mv	a0,s1
    802050c2:	ffffb097          	auipc	ra,0xffffb
    802050c6:	6aa080e7          	jalr	1706(ra) # 8020076c <kref_get>
    802050ca:	89aa                	mv	s3,a0
    printf("Old PA Ref Count: %d (Expected 1)\n", ref_after_write);
    802050cc:	85aa                	mv	a1,a0
    802050ce:	00002517          	auipc	a0,0x2
    802050d2:	cca50513          	add	a0,a0,-822 # 80206d98 <syscalls+0x7f8>
    802050d6:	ffffb097          	auipc	ra,0xffffb
    802050da:	07e080e7          	jalr	126(ra) # 80200154 <printf>
    if (ref_after_write != 1) panic("COW Test Fail: Old PA ref count did not decrease");
    802050de:	4785                	li	a5,1
    802050e0:	10f99163          	bne	s3,a5,802051e2 <test_cow_fork+0x2c6>

    // 验证数据独立性
    char *child_mem = (char*)pa_child_new;
    child_mem[0] = 'C'; // Modify child data
    802050e4:	04300793          	li	a5,67
    802050e8:	00f90023          	sb	a5,0(s2)
    
    if (pa[0] == 'C') panic("COW Test Fail: Parent data modified!");
    802050ec:	0004c703          	lbu	a4,0(s1)
    802050f0:	10f70263          	beq	a4,a5,802051f4 <test_cow_fork+0x2d8>
    
    printf("Data independence verified. Parent: '%s', Child: '%s'\n", pa, child_mem);
    802050f4:	864a                	mv	a2,s2
    802050f6:	85a6                	mv	a1,s1
    802050f8:	00002517          	auipc	a0,0x2
    802050fc:	d2850513          	add	a0,a0,-728 # 80206e20 <syscalls+0x880>
    80205100:	ffffb097          	auipc	ra,0xffffb
    80205104:	054080e7          	jalr	84(ra) # 80200154 <printf>

    // 清理
    kfree(pa); // Free Parent (旧页，引用计数降为 0)
    80205108:	8526                	mv	a0,s1
    8020510a:	ffffb097          	auipc	ra,0xffffb
    8020510e:	334080e7          	jalr	820(ra) # 8020043e <kfree>
    kfree((void*)pa_child_new); // Free Child (新页，引用计数降为 0)
    80205112:	854a                	mv	a0,s2
    80205114:	ffffb097          	auipc	ra,0xffffb
    80205118:	32a080e7          	jalr	810(ra) # 8020043e <kfree>
    
    printf("=== COW Fork Test Passed ===\n");
    8020511c:	00002517          	auipc	a0,0x2
    80205120:	d3c50513          	add	a0,a0,-708 # 80206e58 <syscalls+0x8b8>
    80205124:	ffffb097          	auipc	ra,0xffffb
    80205128:	030080e7          	jalr	48(ra) # 80200154 <printf>
}
    8020512c:	70e2                	ld	ra,56(sp)
    8020512e:	7442                	ld	s0,48(sp)
    80205130:	74a2                	ld	s1,40(sp)
    80205132:	7902                	ld	s2,32(sp)
    80205134:	69e2                	ld	s3,24(sp)
    80205136:	6a42                	ld	s4,16(sp)
    80205138:	6aa2                	ld	s5,8(sp)
    8020513a:	6b02                	ld	s6,0(sp)
    8020513c:	6121                	add	sp,sp,64
    8020513e:	8082                	ret
    if (ref_after_fork != 2) panic("COW Test Fail: Ref count incorrect");
    80205140:	00002517          	auipc	a0,0x2
    80205144:	a5850513          	add	a0,a0,-1448 # 80206b98 <syscalls+0x5f8>
    80205148:	ffffb097          	auipc	ra,0xffffb
    8020514c:	28c080e7          	jalr	652(ra) # 802003d4 <panic>
    80205150:	b5f9                	j	8020501e <test_cow_fork+0x102>
    if (*pte_p & PTE_W) panic("COW Test Fail: Parent still writable");
    80205152:	00002517          	auipc	a0,0x2
    80205156:	a6e50513          	add	a0,a0,-1426 # 80206bc0 <syscalls+0x620>
    8020515a:	ffffb097          	auipc	ra,0xffffb
    8020515e:	27a080e7          	jalr	634(ra) # 802003d4 <panic>
    80205162:	b5d9                	j	80205028 <test_cow_fork+0x10c>
    if (*pte_c & PTE_W) panic("COW Test Fail: Child still writable");
    80205164:	00002517          	auipc	a0,0x2
    80205168:	a8450513          	add	a0,a0,-1404 # 80206be8 <syscalls+0x648>
    8020516c:	ffffb097          	auipc	ra,0xffffb
    80205170:	268080e7          	jalr	616(ra) # 802003d4 <panic>
    80205174:	bd7d                	j	80205032 <test_cow_fork+0x116>
    if (!(*pte_p & PTE_COW)) panic("COW Test Fail: Parent COW bit not set");
    80205176:	00002517          	auipc	a0,0x2
    8020517a:	a9a50513          	add	a0,a0,-1382 # 80206c10 <syscalls+0x670>
    8020517e:	ffffb097          	auipc	ra,0xffffb
    80205182:	256080e7          	jalr	598(ra) # 802003d4 <panic>
    80205186:	bd65                	j	8020503e <test_cow_fork+0x122>
    if (!(*pte_c & PTE_COW)) panic("COW Test Fail: Child COW bit not set");
    80205188:	00002517          	auipc	a0,0x2
    8020518c:	ab050513          	add	a0,a0,-1360 # 80206c38 <syscalls+0x698>
    80205190:	ffffb097          	auipc	ra,0xffffb
    80205194:	244080e7          	jalr	580(ra) # 802003d4 <panic>
    80205198:	bd4d                	j	8020504a <test_cow_fork+0x12e>
    if (cow_alloc(child_pt, va) < 0) panic("COW Allocation Failed");
    8020519a:	00002517          	auipc	a0,0x2
    8020519e:	b3e50513          	add	a0,a0,-1218 # 80206cd8 <syscalls+0x738>
    802051a2:	ffffb097          	auipc	ra,0xffffb
    802051a6:	232080e7          	jalr	562(ra) # 802003d4 <panic>
    802051aa:	bdc9                	j	8020507c <test_cow_fork+0x160>
    if (pa_child_new == (uint64)pa) panic("COW Test Fail: Child still points to old PA");
    802051ac:	00002517          	auipc	a0,0x2
    802051b0:	b5c50513          	add	a0,a0,-1188 # 80206d08 <syscalls+0x768>
    802051b4:	ffffb097          	auipc	ra,0xffffb
    802051b8:	220080e7          	jalr	544(ra) # 802003d4 <panic>
    802051bc:	b5fd                	j	802050aa <test_cow_fork+0x18e>
    if (!(*pte_c & PTE_W)) panic("COW Test Fail: Child page not writable after fault");
    802051be:	00002517          	auipc	a0,0x2
    802051c2:	b7a50513          	add	a0,a0,-1158 # 80206d38 <syscalls+0x798>
    802051c6:	ffffb097          	auipc	ra,0xffffb
    802051ca:	20e080e7          	jalr	526(ra) # 802003d4 <panic>
    802051ce:	b5dd                	j	802050b4 <test_cow_fork+0x198>
    if (*pte_c & PTE_COW) panic("COW Test Fail: Child COW bit still set");
    802051d0:	00002517          	auipc	a0,0x2
    802051d4:	ba050513          	add	a0,a0,-1120 # 80206d70 <syscalls+0x7d0>
    802051d8:	ffffb097          	auipc	ra,0xffffb
    802051dc:	1fc080e7          	jalr	508(ra) # 802003d4 <panic>
    802051e0:	b5c5                	j	802050c0 <test_cow_fork+0x1a4>
    if (ref_after_write != 1) panic("COW Test Fail: Old PA ref count did not decrease");
    802051e2:	00002517          	auipc	a0,0x2
    802051e6:	bde50513          	add	a0,a0,-1058 # 80206dc0 <syscalls+0x820>
    802051ea:	ffffb097          	auipc	ra,0xffffb
    802051ee:	1ea080e7          	jalr	490(ra) # 802003d4 <panic>
    802051f2:	bdcd                	j	802050e4 <test_cow_fork+0x1c8>
    if (pa[0] == 'C') panic("COW Test Fail: Parent data modified!");
    802051f4:	00002517          	auipc	a0,0x2
    802051f8:	c0450513          	add	a0,a0,-1020 # 80206df8 <syscalls+0x858>
    802051fc:	ffffb097          	auipc	ra,0xffffb
    80205200:	1d8080e7          	jalr	472(ra) # 802003d4 <panic>
    80205204:	bdc5                	j	802050f4 <test_cow_fork+0x1d8>
	...
