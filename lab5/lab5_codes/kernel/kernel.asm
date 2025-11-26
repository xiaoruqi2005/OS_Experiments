
kernel/kernel.elf:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
.section .text.entry
.globl _entry

_entry:
    # 设置栈指针
    li sp, 0x80010000
    80000000:	00008137          	lui	sp,0x8
    80000004:	2105                	addw	sp,sp,1 # 8001 <_entry-0x7fff7fff>
    80000006:	0142                	sll	sp,sp,0x10
    
    # 输出启动标记
    li t0, 0x10000000    # UART基地址
    80000008:	100002b7          	lui	t0,0x10000
    li t1, 'S'           # 启动标记
    8000000c:	05300313          	li	t1,83
    sb t1, 0(t0)
    80000010:	00628023          	sb	t1,0(t0) # 10000000 <_entry-0x70000000>
    
    # 清零BSS段
    la t0, bss_start
    80000014:	00006297          	auipc	t0,0x6
    80000018:	fec28293          	add	t0,t0,-20 # 80006000 <panicked>
    la t1, bss_end
    8000001c:	0000c317          	auipc	t1,0xc
    80000020:	ff430313          	add	t1,t1,-12 # 8000c010 <bss_end>

0000000080000024 <clear_bss>:
    
clear_bss:
    bge t0, t1, call_start
    80000024:	0062d663          	bge	t0,t1,80000030 <call_start>
    sb zero, 0(t0)
    80000028:	00028023          	sb	zero,0(t0)
    addi t0, t0, 1
    8000002c:	0285                	add	t0,t0,1
    j clear_bss
    8000002e:	bfdd                	j	80000024 <clear_bss>

0000000080000030 <call_start>:

call_start:
    # 输出准备标记
    li t0, 0x10000000
    80000030:	100002b7          	lui	t0,0x10000
    li t1, 'P'
    80000034:	05000313          	li	t1,80
    sb t1, 0(t0)
    80000038:	00628023          	sb	t1,0(t0) # 10000000 <_entry-0x70000000>
    
    # 跳转到start()在M模式初始化
    # start()会设置好中断委托，然后通过mret切换到S模式调用main()
    call start
    8000003c:	00000097          	auipc	ra,0x0
    80000040:	268080e7          	jalr	616(ra) # 800002a4 <start>

0000000080000044 <infinite_loop>:
    
    # 无限循环（不应该到达这里）
infinite_loop:
    j infinite_loop
    80000044:	a001                	j	80000044 <infinite_loop>

0000000080000046 <r_mhartid>:
    // 通过mret切换到S模式，跳转到main
    asm volatile("mret");
    80000046:	1101                	add	sp,sp,-32
    80000048:	ec22                	sd	s0,24(sp)
    8000004a:	1000                	add	s0,sp,32
    8000004c:	f14027f3          	csrr	a5,mhartid
    80000050:	fef43423          	sd	a5,-24(s0)
    80000054:	fe843783          	ld	a5,-24(s0)
    80000058:	853e                	mv	a0,a5
    8000005a:	6462                	ld	s0,24(sp)
    8000005c:	6105                	add	sp,sp,32
    8000005e:	8082                	ret

0000000080000060 <r_mstatus>:
    80000060:	1101                	add	sp,sp,-32
    80000062:	ec22                	sd	s0,24(sp)
    80000064:	1000                	add	s0,sp,32
    80000066:	300027f3          	csrr	a5,mstatus
    8000006a:	fef43423          	sd	a5,-24(s0)
    8000006e:	fe843783          	ld	a5,-24(s0)
    80000072:	853e                	mv	a0,a5
    80000074:	6462                	ld	s0,24(sp)
    80000076:	6105                	add	sp,sp,32
    80000078:	8082                	ret

000000008000007a <w_mstatus>:
    8000007a:	1101                	add	sp,sp,-32
    8000007c:	ec22                	sd	s0,24(sp)
    8000007e:	1000                	add	s0,sp,32
    80000080:	fea43423          	sd	a0,-24(s0)
    80000084:	fe843783          	ld	a5,-24(s0)
    80000088:	30079073          	csrw	mstatus,a5
    8000008c:	0001                	nop
    8000008e:	6462                	ld	s0,24(sp)
    80000090:	6105                	add	sp,sp,32
    80000092:	8082                	ret

0000000080000094 <r_sie>:
    80000094:	1101                	add	sp,sp,-32
    80000096:	ec22                	sd	s0,24(sp)
    80000098:	1000                	add	s0,sp,32
    8000009a:	104027f3          	csrr	a5,sie
    8000009e:	fef43423          	sd	a5,-24(s0)
    800000a2:	fe843783          	ld	a5,-24(s0)
    800000a6:	853e                	mv	a0,a5
    800000a8:	6462                	ld	s0,24(sp)
    800000aa:	6105                	add	sp,sp,32
    800000ac:	8082                	ret

00000000800000ae <w_sie>:
    800000ae:	1101                	add	sp,sp,-32
    800000b0:	ec22                	sd	s0,24(sp)
    800000b2:	1000                	add	s0,sp,32
    800000b4:	fea43423          	sd	a0,-24(s0)
    800000b8:	fe843783          	ld	a5,-24(s0)
    800000bc:	10479073          	csrw	sie,a5
    800000c0:	0001                	nop
    800000c2:	6462                	ld	s0,24(sp)
    800000c4:	6105                	add	sp,sp,32
    800000c6:	8082                	ret

00000000800000c8 <w_mepc>:
    800000c8:	1101                	add	sp,sp,-32
    800000ca:	ec22                	sd	s0,24(sp)
    800000cc:	1000                	add	s0,sp,32
    800000ce:	fea43423          	sd	a0,-24(s0)
    800000d2:	fe843783          	ld	a5,-24(s0)
    800000d6:	34179073          	csrw	mepc,a5
    800000da:	0001                	nop
    800000dc:	6462                	ld	s0,24(sp)
    800000de:	6105                	add	sp,sp,32
    800000e0:	8082                	ret

00000000800000e2 <w_medeleg>:
    800000e2:	1101                	add	sp,sp,-32
    800000e4:	ec22                	sd	s0,24(sp)
    800000e6:	1000                	add	s0,sp,32
    800000e8:	fea43423          	sd	a0,-24(s0)
    800000ec:	fe843783          	ld	a5,-24(s0)
    800000f0:	30279073          	csrw	medeleg,a5
    800000f4:	0001                	nop
    800000f6:	6462                	ld	s0,24(sp)
    800000f8:	6105                	add	sp,sp,32
    800000fa:	8082                	ret

00000000800000fc <w_mideleg>:
    800000fc:	1101                	add	sp,sp,-32
    800000fe:	ec22                	sd	s0,24(sp)
    80000100:	1000                	add	s0,sp,32
    80000102:	fea43423          	sd	a0,-24(s0)
    80000106:	fe843783          	ld	a5,-24(s0)
    8000010a:	30379073          	csrw	mideleg,a5
    8000010e:	0001                	nop
    80000110:	6462                	ld	s0,24(sp)
    80000112:	6105                	add	sp,sp,32
    80000114:	8082                	ret

0000000080000116 <w_mie>:
    80000116:	1101                	add	sp,sp,-32
    80000118:	ec22                	sd	s0,24(sp)
    8000011a:	1000                	add	s0,sp,32
    8000011c:	fea43423          	sd	a0,-24(s0)
    80000120:	fe843783          	ld	a5,-24(s0)
    80000124:	30479073          	csrw	mie,a5
    80000128:	0001                	nop
    8000012a:	6462                	ld	s0,24(sp)
    8000012c:	6105                	add	sp,sp,32
    8000012e:	8082                	ret

0000000080000130 <r_mie>:
    80000130:	1101                	add	sp,sp,-32
    80000132:	ec22                	sd	s0,24(sp)
    80000134:	1000                	add	s0,sp,32
    80000136:	304027f3          	csrr	a5,mie
    8000013a:	fef43423          	sd	a5,-24(s0)
    8000013e:	fe843783          	ld	a5,-24(s0)
    80000142:	853e                	mv	a0,a5
    80000144:	6462                	ld	s0,24(sp)
    80000146:	6105                	add	sp,sp,32
    80000148:	8082                	ret

000000008000014a <w_mtvec>:
    8000014a:	1101                	add	sp,sp,-32
    8000014c:	ec22                	sd	s0,24(sp)
    8000014e:	1000                	add	s0,sp,32
    80000150:	fea43423          	sd	a0,-24(s0)
    80000154:	fe843783          	ld	a5,-24(s0)
    80000158:	30579073          	csrw	mtvec,a5
    8000015c:	0001                	nop
    8000015e:	6462                	ld	s0,24(sp)
    80000160:	6105                	add	sp,sp,32
    80000162:	8082                	ret

0000000080000164 <w_mscratch>:
    80000164:	1101                	add	sp,sp,-32
    80000166:	ec22                	sd	s0,24(sp)
    80000168:	1000                	add	s0,sp,32
    8000016a:	fea43423          	sd	a0,-24(s0)
    8000016e:	fe843783          	ld	a5,-24(s0)
    80000172:	34079073          	csrw	mscratch,a5
    80000176:	0001                	nop
    80000178:	6462                	ld	s0,24(sp)
    8000017a:	6105                	add	sp,sp,32
    8000017c:	8082                	ret

000000008000017e <w_pmpaddr0>:
    8000017e:	1101                	add	sp,sp,-32
    80000180:	ec22                	sd	s0,24(sp)
    80000182:	1000                	add	s0,sp,32
    80000184:	fea43423          	sd	a0,-24(s0)
    80000188:	fe843783          	ld	a5,-24(s0)
    8000018c:	3b079073          	csrw	pmpaddr0,a5
    80000190:	0001                	nop
    80000192:	6462                	ld	s0,24(sp)
    80000194:	6105                	add	sp,sp,32
    80000196:	8082                	ret

0000000080000198 <w_pmpcfg0>:
    80000198:	1101                	add	sp,sp,-32
    8000019a:	ec22                	sd	s0,24(sp)
    8000019c:	1000                	add	s0,sp,32
    8000019e:	fea43423          	sd	a0,-24(s0)
    800001a2:	fe843783          	ld	a5,-24(s0)
    800001a6:	3a079073          	csrw	pmpcfg0,a5
    800001aa:	0001                	nop
    800001ac:	6462                	ld	s0,24(sp)
    800001ae:	6105                	add	sp,sp,32
    800001b0:	8082                	ret

00000000800001b2 <r_time>:
    800001b2:	1101                	add	sp,sp,-32
    800001b4:	ec22                	sd	s0,24(sp)
    800001b6:	1000                	add	s0,sp,32
    800001b8:	c01027f3          	rdtime	a5
    800001bc:	fef43423          	sd	a5,-24(s0)
    800001c0:	fe843783          	ld	a5,-24(s0)
    800001c4:	853e                	mv	a0,a5
    800001c6:	6462                	ld	s0,24(sp)
    800001c8:	6105                	add	sp,sp,32
    800001ca:	8082                	ret

00000000800001cc <w_tp>:
    800001cc:	1101                	add	sp,sp,-32
    800001ce:	ec22                	sd	s0,24(sp)
    800001d0:	1000                	add	s0,sp,32
    800001d2:	fea43423          	sd	a0,-24(s0)
    800001d6:	fe843783          	ld	a5,-24(s0)
    800001da:	823e                	mv	tp,a5
    800001dc:	0001                	nop
    800001de:	6462                	ld	s0,24(sp)
    800001e0:	6105                	add	sp,sp,32
    800001e2:	8082                	ret

00000000800001e4 <timerinit>:
void timerinit(void) {
    800001e4:	7179                	add	sp,sp,-48
    800001e6:	f406                	sd	ra,40(sp)
    800001e8:	f022                	sd	s0,32(sp)
    800001ea:	1800                	add	s0,sp,48
    int id = r_mhartid();
    800001ec:	00000097          	auipc	ra,0x0
    800001f0:	e5a080e7          	jalr	-422(ra) # 80000046 <r_mhartid>
    800001f4:	87aa                	mv	a5,a0
    800001f6:	fef42623          	sw	a5,-20(s0)
    uint64 interval = 1000000;  // 100ms at 10MHz
    800001fa:	000f47b7          	lui	a5,0xf4
    800001fe:	24078793          	add	a5,a5,576 # f4240 <_entry-0x7ff0bdc0>
    80000202:	fef43023          	sd	a5,-32(s0)
    timer_scratch[0] = interval;
    80000206:	00009797          	auipc	a5,0x9
    8000020a:	dfa78793          	add	a5,a5,-518 # 80009000 <timer_scratch>
    8000020e:	fe043703          	ld	a4,-32(s0)
    80000212:	e398                	sd	a4,0(a5)
    timer_scratch[1] = CLINT_MTIMECMP(id);
    80000214:	fec42783          	lw	a5,-20(s0)
    80000218:	0037979b          	sllw	a5,a5,0x3
    8000021c:	2781                	sext.w	a5,a5
    8000021e:	873e                	mv	a4,a5
    80000220:	020047b7          	lui	a5,0x2004
    80000224:	97ba                	add	a5,a5,a4
    80000226:	873e                	mv	a4,a5
    80000228:	00009797          	auipc	a5,0x9
    8000022c:	dd878793          	add	a5,a5,-552 # 80009000 <timer_scratch>
    80000230:	e798                	sd	a4,8(a5)
    w_mscratch((uint64)timer_scratch);
    80000232:	00009797          	auipc	a5,0x9
    80000236:	dce78793          	add	a5,a5,-562 # 80009000 <timer_scratch>
    8000023a:	853e                	mv	a0,a5
    8000023c:	00000097          	auipc	ra,0x0
    80000240:	f28080e7          	jalr	-216(ra) # 80000164 <w_mscratch>
    w_mtvec((uint64)timervec);
    80000244:	00002797          	auipc	a5,0x2
    80000248:	49c78793          	add	a5,a5,1180 # 800026e0 <timervec>
    8000024c:	853e                	mv	a0,a5
    8000024e:	00000097          	auipc	ra,0x0
    80000252:	efc080e7          	jalr	-260(ra) # 8000014a <w_mtvec>
    w_mie(r_mie() | MIE_MTIE);
    80000256:	00000097          	auipc	ra,0x0
    8000025a:	eda080e7          	jalr	-294(ra) # 80000130 <r_mie>
    8000025e:	87aa                	mv	a5,a0
    80000260:	0807e793          	or	a5,a5,128
    80000264:	853e                	mv	a0,a5
    80000266:	00000097          	auipc	ra,0x0
    8000026a:	eb0080e7          	jalr	-336(ra) # 80000116 <w_mie>
    uint64 now = r_time();
    8000026e:	00000097          	auipc	ra,0x0
    80000272:	f44080e7          	jalr	-188(ra) # 800001b2 <r_time>
    80000276:	fca43c23          	sd	a0,-40(s0)
    *(uint64*)CLINT_MTIMECMP(id) = now + interval;
    8000027a:	fec42783          	lw	a5,-20(s0)
    8000027e:	0037979b          	sllw	a5,a5,0x3
    80000282:	2781                	sext.w	a5,a5
    80000284:	873e                	mv	a4,a5
    80000286:	020047b7          	lui	a5,0x2004
    8000028a:	97ba                	add	a5,a5,a4
    8000028c:	86be                	mv	a3,a5
    8000028e:	fd843703          	ld	a4,-40(s0)
    80000292:	fe043783          	ld	a5,-32(s0)
    80000296:	97ba                	add	a5,a5,a4
    80000298:	e29c                	sd	a5,0(a3)
}
    8000029a:	0001                	nop
    8000029c:	70a2                	ld	ra,40(sp)
    8000029e:	7402                	ld	s0,32(sp)
    800002a0:	6145                	add	sp,sp,48
    800002a2:	8082                	ret

00000000800002a4 <start>:
void start(void) {
    800002a4:	1101                	add	sp,sp,-32
    800002a6:	ec06                	sd	ra,24(sp)
    800002a8:	e822                	sd	s0,16(sp)
    800002aa:	1000                	add	s0,sp,32
    w_mepc((uint64)main);
    800002ac:	00000797          	auipc	a5,0x0
    800002b0:	1ce78793          	add	a5,a5,462 # 8000047a <main>
    800002b4:	853e                	mv	a0,a5
    800002b6:	00000097          	auipc	ra,0x0
    800002ba:	e12080e7          	jalr	-494(ra) # 800000c8 <w_mepc>
    uint64 x = r_mstatus();
    800002be:	00000097          	auipc	ra,0x0
    800002c2:	da2080e7          	jalr	-606(ra) # 80000060 <r_mstatus>
    800002c6:	fea43423          	sd	a0,-24(s0)
    x &= ~MSTATUS_MPP_MASK;
    800002ca:	fe843703          	ld	a4,-24(s0)
    800002ce:	77f9                	lui	a5,0xffffe
    800002d0:	7ff78793          	add	a5,a5,2047 # ffffffffffffe7ff <bss_end+0xffffffff7fff27ef>
    800002d4:	8ff9                	and	a5,a5,a4
    800002d6:	fef43423          	sd	a5,-24(s0)
    x |= MSTATUS_MPP_S;
    800002da:	fe843703          	ld	a4,-24(s0)
    800002de:	6785                	lui	a5,0x1
    800002e0:	80078793          	add	a5,a5,-2048 # 800 <_entry-0x7ffff800>
    800002e4:	8fd9                	or	a5,a5,a4
    800002e6:	fef43423          	sd	a5,-24(s0)
    x |= MSTATUS_MPIE;
    800002ea:	fe843783          	ld	a5,-24(s0)
    800002ee:	0807e793          	or	a5,a5,128
    800002f2:	fef43423          	sd	a5,-24(s0)
    w_mstatus(x);
    800002f6:	fe843503          	ld	a0,-24(s0)
    800002fa:	00000097          	auipc	ra,0x0
    800002fe:	d80080e7          	jalr	-640(ra) # 8000007a <w_mstatus>
    w_medeleg(0xffff);
    80000302:	67c1                	lui	a5,0x10
    80000304:	fff78513          	add	a0,a5,-1 # ffff <_entry-0x7fff0001>
    80000308:	00000097          	auipc	ra,0x0
    8000030c:	dda080e7          	jalr	-550(ra) # 800000e2 <w_medeleg>
    w_mideleg(0xffff);
    80000310:	67c1                	lui	a5,0x10
    80000312:	fff78513          	add	a0,a5,-1 # ffff <_entry-0x7fff0001>
    80000316:	00000097          	auipc	ra,0x0
    8000031a:	de6080e7          	jalr	-538(ra) # 800000fc <w_mideleg>
    w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    8000031e:	00000097          	auipc	ra,0x0
    80000322:	d76080e7          	jalr	-650(ra) # 80000094 <r_sie>
    80000326:	87aa                	mv	a5,a0
    80000328:	2227e793          	or	a5,a5,546
    8000032c:	853e                	mv	a0,a5
    8000032e:	00000097          	auipc	ra,0x0
    80000332:	d80080e7          	jalr	-640(ra) # 800000ae <w_sie>
    w_pmpaddr0(0x3fffffffffffffull);
    80000336:	57fd                	li	a5,-1
    80000338:	00a7d513          	srl	a0,a5,0xa
    8000033c:	00000097          	auipc	ra,0x0
    80000340:	e42080e7          	jalr	-446(ra) # 8000017e <w_pmpaddr0>
    w_pmpcfg0(0xf);
    80000344:	453d                	li	a0,15
    80000346:	00000097          	auipc	ra,0x0
    8000034a:	e52080e7          	jalr	-430(ra) # 80000198 <w_pmpcfg0>
    timerinit();
    8000034e:	00000097          	auipc	ra,0x0
    80000352:	e96080e7          	jalr	-362(ra) # 800001e4 <timerinit>
    int id = r_mhartid();
    80000356:	00000097          	auipc	ra,0x0
    8000035a:	cf0080e7          	jalr	-784(ra) # 80000046 <r_mhartid>
    8000035e:	87aa                	mv	a5,a0
    80000360:	fef42223          	sw	a5,-28(s0)
    w_tp(id);
    80000364:	fe442783          	lw	a5,-28(s0)
    80000368:	853e                	mv	a0,a5
    8000036a:	00000097          	auipc	ra,0x0
    8000036e:	e62080e7          	jalr	-414(ra) # 800001cc <w_tp>
    asm volatile("mret");
    80000372:	30200073          	mret
    80000376:	0001                	nop
    80000378:	60e2                	ld	ra,24(sp)
    8000037a:	6442                	ld	s0,16(sp)
    8000037c:	6105                	add	sp,sp,32
    8000037e:	8082                	ret

0000000080000380 <r_satp>:
    printf("Virtual memory enabled! New satp: %p\n", (void*)r_satp());
    
    // ==================== Phase 3: 中断系统 ====================
    printf("\n=== Phase 3: Interrupt System ===\n");
    trap_init();
    
    80000380:	1101                	add	sp,sp,-32
    80000382:	ec22                	sd	s0,24(sp)
    80000384:	1000                	add	s0,sp,32
    // ==================== Phase 4: 时钟系统 ====================
    printf("\n=== Phase 4: Timer System ===\n");
    80000386:	180027f3          	csrr	a5,satp
    8000038a:	fef43423          	sd	a5,-24(s0)
    timer_init();
    8000038e:	fe843783          	ld	a5,-24(s0)
    
    80000392:	853e                	mv	a0,a5
    80000394:	6462                	ld	s0,24(sp)
    80000396:	6105                	add	sp,sp,32
    80000398:	8082                	ret

000000008000039a <r_tp>:
    8000039a:	1101                	add	sp,sp,-32
    8000039c:	ec22                	sd	s0,24(sp)
    8000039e:	1000                	add	s0,sp,32
    800003a0:	8792                	mv	a5,tp
    800003a2:	fef43423          	sd	a5,-24(s0)
    800003a6:	fe843783          	ld	a5,-24(s0)
    800003aa:	853e                	mv	a0,a5
    800003ac:	6462                	ld	s0,24(sp)
    800003ae:	6105                	add	sp,sp,32
    800003b0:	8082                	ret

00000000800003b2 <init_process>:
void init_process(void) {
    800003b2:	1141                	add	sp,sp,-16
    800003b4:	e406                	sd	ra,8(sp)
    800003b6:	e022                	sd	s0,0(sp)
    800003b8:	0800                	add	s0,sp,16
    printf("\n");
    800003ba:	00004517          	auipc	a0,0x4
    800003be:	c4650513          	add	a0,a0,-954 # 80004000 <etext>
    800003c2:	00000097          	auipc	ra,0x0
    800003c6:	764080e7          	jalr	1892(ra) # 80000b26 <printf>
    printf("========================================\n");
    800003ca:	00004517          	auipc	a0,0x4
    800003ce:	c3e50513          	add	a0,a0,-962 # 80004008 <etext+0x8>
    800003d2:	00000097          	auipc	ra,0x0
    800003d6:	754080e7          	jalr	1876(ra) # 80000b26 <printf>
    printf("=== Init Process Started ===\n");
    800003da:	00004517          	auipc	a0,0x4
    800003de:	c5e50513          	add	a0,a0,-930 # 80004038 <etext+0x38>
    800003e2:	00000097          	auipc	ra,0x0
    800003e6:	744080e7          	jalr	1860(ra) # 80000b26 <printf>
    printf("========================================\n");
    800003ea:	00004517          	auipc	a0,0x4
    800003ee:	c1e50513          	add	a0,a0,-994 # 80004008 <etext+0x8>
    800003f2:	00000097          	auipc	ra,0x0
    800003f6:	734080e7          	jalr	1844(ra) # 80000b26 <printf>
    printf("PID: %d\n", myproc()->pid);
    800003fa:	00002097          	auipc	ra,0x2
    800003fe:	55a080e7          	jalr	1370(ra) # 80002954 <myproc>
    80000402:	87aa                	mv	a5,a0
    80000404:	43dc                	lw	a5,4(a5)
    80000406:	85be                	mv	a1,a5
    80000408:	00004517          	auipc	a0,0x4
    8000040c:	c5050513          	add	a0,a0,-944 # 80004058 <etext+0x58>
    80000410:	00000097          	auipc	ra,0x0
    80000414:	716080e7          	jalr	1814(ra) # 80000b26 <printf>
    printf("This is the first user process!\n");
    80000418:	00004517          	auipc	a0,0x4
    8000041c:	c5050513          	add	a0,a0,-944 # 80004068 <etext+0x68>
    80000420:	00000097          	auipc	ra,0x0
    80000424:	706080e7          	jalr	1798(ra) # 80000b26 <printf>
    printf("\n");
    80000428:	00004517          	auipc	a0,0x4
    8000042c:	bd850513          	add	a0,a0,-1064 # 80004000 <etext>
    80000430:	00000097          	auipc	ra,0x0
    80000434:	6f6080e7          	jalr	1782(ra) # 80000b26 <printf>
    printf("Starting process tests...\n");
    80000438:	00004517          	auipc	a0,0x4
    8000043c:	c5850513          	add	a0,a0,-936 # 80004090 <etext+0x90>
    80000440:	00000097          	auipc	ra,0x0
    80000444:	6e6080e7          	jalr	1766(ra) # 80000b26 <printf>
    run_process_tests();
    80000448:	00003097          	auipc	ra,0x3
    8000044c:	7ce080e7          	jalr	1998(ra) # 80003c16 <run_process_tests>
    printf("\n=== Init Process Finished ===\n");
    80000450:	00004517          	auipc	a0,0x4
    80000454:	c6050513          	add	a0,a0,-928 # 800040b0 <etext+0xb0>
    80000458:	00000097          	auipc	ra,0x0
    8000045c:	6ce080e7          	jalr	1742(ra) # 80000b26 <printf>
    printf("All tests completed!\n\n");
    80000460:	00004517          	auipc	a0,0x4
    80000464:	c7050513          	add	a0,a0,-912 # 800040d0 <etext+0xd0>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6be080e7          	jalr	1726(ra) # 80000b26 <printf>
}
    80000470:	0001                	nop
    80000472:	60a2                	ld	ra,8(sp)
    80000474:	6402                	ld	s0,0(sp)
    80000476:	0141                	add	sp,sp,16
    80000478:	8082                	ret

000000008000047a <main>:
void main(void) {
    8000047a:	1101                	add	sp,sp,-32
    8000047c:	ec06                	sd	ra,24(sp)
    8000047e:	e822                	sd	s0,16(sp)
    80000480:	1000                	add	s0,sp,32
    printf("\n");
    80000482:	00004517          	auipc	a0,0x4
    80000486:	b7e50513          	add	a0,a0,-1154 # 80004000 <etext>
    8000048a:	00000097          	auipc	ra,0x0
    8000048e:	69c080e7          	jalr	1692(ra) # 80000b26 <printf>
    printf("SP\n");
    80000492:	00004517          	auipc	a0,0x4
    80000496:	c5650513          	add	a0,a0,-938 # 800040e8 <etext+0xe8>
    8000049a:	00000097          	auipc	ra,0x0
    8000049e:	68c080e7          	jalr	1676(ra) # 80000b26 <printf>
    printf("=== RISC-V OS Lab 5: Process Management ===\n");
    800004a2:	00004517          	auipc	a0,0x4
    800004a6:	c4e50513          	add	a0,a0,-946 # 800040f0 <etext+0xf0>
    800004aa:	00000097          	auipc	ra,0x0
    800004ae:	67c080e7          	jalr	1660(ra) # 80000b26 <printf>
    printf("\nSystem Information:\n");
    800004b2:	00004517          	auipc	a0,0x4
    800004b6:	c6e50513          	add	a0,a0,-914 # 80004120 <etext+0x120>
    800004ba:	00000097          	auipc	ra,0x0
    800004be:	66c080e7          	jalr	1644(ra) # 80000b26 <printf>
    printf("  Hart ID:  %d\n", (int)r_tp());
    800004c2:	00000097          	auipc	ra,0x0
    800004c6:	ed8080e7          	jalr	-296(ra) # 8000039a <r_tp>
    800004ca:	87aa                	mv	a5,a0
    800004cc:	2781                	sext.w	a5,a5
    800004ce:	85be                	mv	a1,a5
    800004d0:	00004517          	auipc	a0,0x4
    800004d4:	c6850513          	add	a0,a0,-920 # 80004138 <etext+0x138>
    800004d8:	00000097          	auipc	ra,0x0
    800004dc:	64e080e7          	jalr	1614(ra) # 80000b26 <printf>
    printf("  KERNBASE: %p\n", (void*)0x80000000L);
    800004e0:	4785                	li	a5,1
    800004e2:	01f79593          	sll	a1,a5,0x1f
    800004e6:	00004517          	auipc	a0,0x4
    800004ea:	c6250513          	add	a0,a0,-926 # 80004148 <etext+0x148>
    800004ee:	00000097          	auipc	ra,0x0
    800004f2:	638080e7          	jalr	1592(ra) # 80000b26 <printf>
    printf("  PHYSTOP:  %p\n", (void*)0x88000000L);
    800004f6:	47c5                	li	a5,17
    800004f8:	01b79593          	sll	a1,a5,0x1b
    800004fc:	00004517          	auipc	a0,0x4
    80000500:	c5c50513          	add	a0,a0,-932 # 80004158 <etext+0x158>
    80000504:	00000097          	auipc	ra,0x0
    80000508:	622080e7          	jalr	1570(ra) # 80000b26 <printf>
    printf("\nKernel symbols:\n");
    8000050c:	00004517          	auipc	a0,0x4
    80000510:	c5c50513          	add	a0,a0,-932 # 80004168 <etext+0x168>
    80000514:	00000097          	auipc	ra,0x0
    80000518:	612080e7          	jalr	1554(ra) # 80000b26 <printf>
    printf("  etext: %p\n", etext);
    8000051c:	00004597          	auipc	a1,0x4
    80000520:	ae458593          	add	a1,a1,-1308 # 80004000 <etext>
    80000524:	00004517          	auipc	a0,0x4
    80000528:	c5c50513          	add	a0,a0,-932 # 80004180 <etext+0x180>
    8000052c:	00000097          	auipc	ra,0x0
    80000530:	5fa080e7          	jalr	1530(ra) # 80000b26 <printf>
    printf("  edata: %p\n", edata);
    80000534:	00005597          	auipc	a1,0x5
    80000538:	64c58593          	add	a1,a1,1612 # 80005b80 <edata>
    8000053c:	00004517          	auipc	a0,0x4
    80000540:	c5450513          	add	a0,a0,-940 # 80004190 <etext+0x190>
    80000544:	00000097          	auipc	ra,0x0
    80000548:	5e2080e7          	jalr	1506(ra) # 80000b26 <printf>
    printf("  end:   %p\n", end);
    8000054c:	0000c597          	auipc	a1,0xc
    80000550:	ac458593          	add	a1,a1,-1340 # 8000c010 <bss_end>
    80000554:	00004517          	auipc	a0,0x4
    80000558:	c4c50513          	add	a0,a0,-948 # 800041a0 <etext+0x1a0>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	5ca080e7          	jalr	1482(ra) # 80000b26 <printf>
    printf("\n=== Phase 1: Physical Memory Management ===\n");
    80000564:	00004517          	auipc	a0,0x4
    80000568:	c4c50513          	add	a0,a0,-948 # 800041b0 <etext+0x1b0>
    8000056c:	00000097          	auipc	ra,0x0
    80000570:	5ba080e7          	jalr	1466(ra) # 80000b26 <printf>
    kinit();
    80000574:	00001097          	auipc	ra,0x1
    80000578:	9e2080e7          	jalr	-1566(ra) # 80000f56 <kinit>
    print_mem_info();
    8000057c:	00001097          	auipc	ra,0x1
    80000580:	c38080e7          	jalr	-968(ra) # 800011b4 <print_mem_info>
    printf("\n=== Phase 2: Virtual Memory Activation ===\n");
    80000584:	00004517          	auipc	a0,0x4
    80000588:	c5c50513          	add	a0,a0,-932 # 800041e0 <etext+0x1e0>
    8000058c:	00000097          	auipc	ra,0x0
    80000590:	59a080e7          	jalr	1434(ra) # 80000b26 <printf>
    printf("Current satp: %p\n", (void*)r_satp());
    80000594:	00000097          	auipc	ra,0x0
    80000598:	dec080e7          	jalr	-532(ra) # 80000380 <r_satp>
    8000059c:	87aa                	mv	a5,a0
    8000059e:	85be                	mv	a1,a5
    800005a0:	00004517          	auipc	a0,0x4
    800005a4:	c7050513          	add	a0,a0,-912 # 80004210 <etext+0x210>
    800005a8:	00000097          	auipc	ra,0x0
    800005ac:	57e080e7          	jalr	1406(ra) # 80000b26 <printf>
    kvminit();
    800005b0:	00001097          	auipc	ra,0x1
    800005b4:	10c080e7          	jalr	268(ra) # 800016bc <kvminit>
    kvminithart();
    800005b8:	00001097          	auipc	ra,0x1
    800005bc:	238080e7          	jalr	568(ra) # 800017f0 <kvminithart>
    printf("Virtual memory enabled! New satp: %p\n", (void*)r_satp());
    800005c0:	00000097          	auipc	ra,0x0
    800005c4:	dc0080e7          	jalr	-576(ra) # 80000380 <r_satp>
    800005c8:	87aa                	mv	a5,a0
    800005ca:	85be                	mv	a1,a5
    800005cc:	00004517          	auipc	a0,0x4
    800005d0:	c5c50513          	add	a0,a0,-932 # 80004228 <etext+0x228>
    800005d4:	00000097          	auipc	ra,0x0
    800005d8:	552080e7          	jalr	1362(ra) # 80000b26 <printf>
    printf("\n=== Phase 3: Interrupt System ===\n");
    800005dc:	00004517          	auipc	a0,0x4
    800005e0:	c7450513          	add	a0,a0,-908 # 80004250 <etext+0x250>
    800005e4:	00000097          	auipc	ra,0x0
    800005e8:	542080e7          	jalr	1346(ra) # 80000b26 <printf>
    trap_init();
    800005ec:	00001097          	auipc	ra,0x1
    800005f0:	52c080e7          	jalr	1324(ra) # 80001b18 <trap_init>
    printf("\n=== Phase 4: Timer System ===\n");
    800005f4:	00004517          	auipc	a0,0x4
    800005f8:	c8450513          	add	a0,a0,-892 # 80004278 <etext+0x278>
    800005fc:	00000097          	auipc	ra,0x0
    80000600:	52a080e7          	jalr	1322(ra) # 80000b26 <printf>
    timer_init();
    80000604:	00002097          	auipc	ra,0x2
    80000608:	18c080e7          	jalr	396(ra) # 80002790 <timer_init>
    printf("\n=== Phase 5: Process System ===\n");
    8000060c:	00004517          	auipc	a0,0x4
    80000610:	c8c50513          	add	a0,a0,-884 # 80004298 <etext+0x298>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	512080e7          	jalr	1298(ra) # 80000b26 <printf>
    procinit();
    8000061c:	00002097          	auipc	ra,0x2
    80000620:	396080e7          	jalr	918(ra) # 800029b2 <procinit>
    printf("\n=== Phase 6: Creating Init Process ===\n");
    80000624:	00004517          	auipc	a0,0x4
    80000628:	c9c50513          	add	a0,a0,-868 # 800042c0 <etext+0x2c0>
    8000062c:	00000097          	auipc	ra,0x0
    80000630:	4fa080e7          	jalr	1274(ra) # 80000b26 <printf>
    int init_pid = kthread_create(init_process, "init");
    80000634:	00004597          	auipc	a1,0x4
    80000638:	cbc58593          	add	a1,a1,-836 # 800042f0 <etext+0x2f0>
    8000063c:	00000517          	auipc	a0,0x0
    80000640:	d7650513          	add	a0,a0,-650 # 800003b2 <init_process>
    80000644:	00002097          	auipc	ra,0x2
    80000648:	574080e7          	jalr	1396(ra) # 80002bb8 <kthread_create>
    8000064c:	87aa                	mv	a5,a0
    8000064e:	fef42223          	sw	a5,-28(s0)
    if(init_pid < 0) {
    80000652:	fe442783          	lw	a5,-28(s0)
    80000656:	2781                	sext.w	a5,a5
    80000658:	0007da63          	bgez	a5,8000066c <main+0x1f2>
        panic("failed to create init process");
    8000065c:	00004517          	auipc	a0,0x4
    80000660:	c9c50513          	add	a0,a0,-868 # 800042f8 <etext+0x2f8>
    80000664:	00000097          	auipc	ra,0x0
    80000668:	7bc080e7          	jalr	1980(ra) # 80000e20 <panic>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000066c:	00009797          	auipc	a5,0x9
    80000670:	aec78793          	add	a5,a5,-1300 # 80009158 <proc>
    80000674:	fef43423          	sd	a5,-24(s0)
    80000678:	a03d                	j	800006a6 <main+0x22c>
        if(p->pid == init_pid) {
    8000067a:	fe843783          	ld	a5,-24(s0)
    8000067e:	43d8                	lw	a4,4(a5)
    80000680:	fe442783          	lw	a5,-28(s0)
    80000684:	2781                	sext.w	a5,a5
    80000686:	00e79a63          	bne	a5,a4,8000069a <main+0x220>
            initproc = p;
    8000068a:	00006797          	auipc	a5,0x6
    8000068e:	98678793          	add	a5,a5,-1658 # 80006010 <initproc>
    80000692:	fe843703          	ld	a4,-24(s0)
    80000696:	e398                	sd	a4,0(a5)
            break;
    80000698:	a839                	j	800006b6 <main+0x23c>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000069a:	fe843783          	ld	a5,-24(s0)
    8000069e:	0b878793          	add	a5,a5,184
    800006a2:	fef43423          	sd	a5,-24(s0)
    800006a6:	fe843703          	ld	a4,-24(s0)
    800006aa:	0000c797          	auipc	a5,0xc
    800006ae:	8ae78793          	add	a5,a5,-1874 # 8000bf58 <cpu>
    800006b2:	fcf764e3          	bltu	a4,a5,8000067a <main+0x200>
    printf("Init process created with PID %d\n", init_pid);
    800006b6:	fe442783          	lw	a5,-28(s0)
    800006ba:	85be                	mv	a1,a5
    800006bc:	00004517          	auipc	a0,0x4
    800006c0:	c5c50513          	add	a0,a0,-932 # 80004318 <etext+0x318>
    800006c4:	00000097          	auipc	ra,0x0
    800006c8:	462080e7          	jalr	1122(ra) # 80000b26 <printf>
    printf("\n=== System Ready ===\n");
    800006cc:	00004517          	auipc	a0,0x4
    800006d0:	c7450513          	add	a0,a0,-908 # 80004340 <etext+0x340>
    800006d4:	00000097          	auipc	ra,0x0
    800006d8:	452080e7          	jalr	1106(ra) # 80000b26 <printf>
    printf("All subsystems initialized successfully!\n");
    800006dc:	00004517          	auipc	a0,0x4
    800006e0:	c7c50513          	add	a0,a0,-900 # 80004358 <etext+0x358>
    800006e4:	00000097          	auipc	ra,0x0
    800006e8:	442080e7          	jalr	1090(ra) # 80000b26 <printf>
    printf("- Physical memory manager\n");
    800006ec:	00004517          	auipc	a0,0x4
    800006f0:	c9c50513          	add	a0,a0,-868 # 80004388 <etext+0x388>
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	432080e7          	jalr	1074(ra) # 80000b26 <printf>
    printf("- Virtual memory (Sv39)\n");
    800006fc:	00004517          	auipc	a0,0x4
    80000700:	cac50513          	add	a0,a0,-852 # 800043a8 <etext+0x3a8>
    80000704:	00000097          	auipc	ra,0x0
    80000708:	422080e7          	jalr	1058(ra) # 80000b26 <printf>
    printf("- Interrupt handling\n");
    8000070c:	00004517          	auipc	a0,0x4
    80000710:	cbc50513          	add	a0,a0,-836 # 800043c8 <etext+0x3c8>
    80000714:	00000097          	auipc	ra,0x0
    80000718:	412080e7          	jalr	1042(ra) # 80000b26 <printf>
    printf("- Timer interrupts (100ms)\n");
    8000071c:	00004517          	auipc	a0,0x4
    80000720:	cc450513          	add	a0,a0,-828 # 800043e0 <etext+0x3e0>
    80000724:	00000097          	auipc	ra,0x0
    80000728:	402080e7          	jalr	1026(ra) # 80000b26 <printf>
    printf("- Process management\n");
    8000072c:	00004517          	auipc	a0,0x4
    80000730:	cd450513          	add	a0,a0,-812 # 80004400 <etext+0x400>
    80000734:	00000097          	auipc	ra,0x0
    80000738:	3f2080e7          	jalr	1010(ra) # 80000b26 <printf>
    printf("\n========================================\n");
    8000073c:	00004517          	auipc	a0,0x4
    80000740:	cdc50513          	add	a0,a0,-804 # 80004418 <etext+0x418>
    80000744:	00000097          	auipc	ra,0x0
    80000748:	3e2080e7          	jalr	994(ra) # 80000b26 <printf>
    printf("Starting scheduler...\n");
    8000074c:	00004517          	auipc	a0,0x4
    80000750:	cfc50513          	add	a0,a0,-772 # 80004448 <etext+0x448>
    80000754:	00000097          	auipc	ra,0x0
    80000758:	3d2080e7          	jalr	978(ra) # 80000b26 <printf>
    printf("The system will now run processes.\n");
    8000075c:	00004517          	auipc	a0,0x4
    80000760:	d0450513          	add	a0,a0,-764 # 80004460 <etext+0x460>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	3c2080e7          	jalr	962(ra) # 80000b26 <printf>
    printf("You should see multiple tasks running.\n");
    8000076c:	00004517          	auipc	a0,0x4
    80000770:	d1c50513          	add	a0,a0,-740 # 80004488 <etext+0x488>
    80000774:	00000097          	auipc	ra,0x0
    80000778:	3b2080e7          	jalr	946(ra) # 80000b26 <printf>
    printf("========================================\n\n");
    8000077c:	00004517          	auipc	a0,0x4
    80000780:	d3450513          	add	a0,a0,-716 # 800044b0 <etext+0x4b0>
    80000784:	00000097          	auipc	ra,0x0
    80000788:	3a2080e7          	jalr	930(ra) # 80000b26 <printf>
    scheduler();  // ← 这个函数永不返回！
    8000078c:	00003097          	auipc	ra,0x3
    80000790:	8b8080e7          	jalr	-1864(ra) # 80003044 <scheduler>

0000000080000794 <read_reg>:

// 全局变量
volatile int panicked = 0;

// 读UART寄存器
static inline uint8 read_reg(int reg) {
    80000794:	1101                	add	sp,sp,-32
    80000796:	ec22                	sd	s0,24(sp)
    80000798:	1000                	add	s0,sp,32
    8000079a:	87aa                	mv	a5,a0
    8000079c:	fef42623          	sw	a5,-20(s0)
    return *(volatile uint8*)(UART0 + reg);
    800007a0:	fec42703          	lw	a4,-20(s0)
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	97ba                	add	a5,a5,a4
    800007aa:	0007c783          	lbu	a5,0(a5) # 10000000 <_entry-0x70000000>
    800007ae:	0ff7f793          	zext.b	a5,a5
}
    800007b2:	853e                	mv	a0,a5
    800007b4:	6462                	ld	s0,24(sp)
    800007b6:	6105                	add	sp,sp,32
    800007b8:	8082                	ret

00000000800007ba <write_reg>:

// 写UART寄存器
static inline void write_reg(int reg, uint8 val) {
    800007ba:	1101                	add	sp,sp,-32
    800007bc:	ec22                	sd	s0,24(sp)
    800007be:	1000                	add	s0,sp,32
    800007c0:	87aa                	mv	a5,a0
    800007c2:	872e                	mv	a4,a1
    800007c4:	fef42623          	sw	a5,-20(s0)
    800007c8:	87ba                	mv	a5,a4
    800007ca:	fef405a3          	sb	a5,-21(s0)
    *(volatile uint8*)(UART0 + reg) = val;
    800007ce:	fec42703          	lw	a4,-20(s0)
    800007d2:	100007b7          	lui	a5,0x10000
    800007d6:	97ba                	add	a5,a5,a4
    800007d8:	873e                	mv	a4,a5
    800007da:	feb44783          	lbu	a5,-21(s0)
    800007de:	00f70023          	sb	a5,0(a4)
}
    800007e2:	0001                	nop
    800007e4:	6462                	ld	s0,24(sp)
    800007e6:	6105                	add	sp,sp,32
    800007e8:	8082                	ret

00000000800007ea <uart_init>:

// 初始化UART
void uart_init(void) {
    800007ea:	1141                	add	sp,sp,-16
    800007ec:	e406                	sd	ra,8(sp)
    800007ee:	e022                	sd	s0,0(sp)
    800007f0:	0800                	add	s0,sp,16
    // 禁用中断
    write_reg(IER, 0x00);
    800007f2:	4581                	li	a1,0
    800007f4:	4505                	li	a0,1
    800007f6:	00000097          	auipc	ra,0x0
    800007fa:	fc4080e7          	jalr	-60(ra) # 800007ba <write_reg>
    
    // 设置波特率（115200）
    write_reg(LCR, 0x80);  // 启用DLAB
    800007fe:	08000593          	li	a1,128
    80000802:	450d                	li	a0,3
    80000804:	00000097          	auipc	ra,0x0
    80000808:	fb6080e7          	jalr	-74(ra) # 800007ba <write_reg>
    write_reg(0, 0x03);    // divisor低字节
    8000080c:	458d                	li	a1,3
    8000080e:	4501                	li	a0,0
    80000810:	00000097          	auipc	ra,0x0
    80000814:	faa080e7          	jalr	-86(ra) # 800007ba <write_reg>
    write_reg(1, 0x00);    // divisor高字节
    80000818:	4581                	li	a1,0
    8000081a:	4505                	li	a0,1
    8000081c:	00000097          	auipc	ra,0x0
    80000820:	f9e080e7          	jalr	-98(ra) # 800007ba <write_reg>
    
    // 8位数据，无校验，1停止位
    write_reg(LCR, 0x03);
    80000824:	458d                	li	a1,3
    80000826:	450d                	li	a0,3
    80000828:	00000097          	auipc	ra,0x0
    8000082c:	f92080e7          	jalr	-110(ra) # 800007ba <write_reg>
    
    // 启用FIFO
    write_reg(FCR, 0x07);
    80000830:	459d                	li	a1,7
    80000832:	4509                	li	a0,2
    80000834:	00000097          	auipc	ra,0x0
    80000838:	f86080e7          	jalr	-122(ra) # 800007ba <write_reg>
    
    // 启用接收中断
    write_reg(IER, 0x01);
    8000083c:	4585                	li	a1,1
    8000083e:	4505                	li	a0,1
    80000840:	00000097          	auipc	ra,0x0
    80000844:	f7a080e7          	jalr	-134(ra) # 800007ba <write_reg>
}
    80000848:	0001                	nop
    8000084a:	60a2                	ld	ra,8(sp)
    8000084c:	6402                	ld	s0,0(sp)
    8000084e:	0141                	add	sp,sp,16
    80000850:	8082                	ret

0000000080000852 <uart_putc>:

// 发送一个字符
void uart_putc(int c) {
    80000852:	1101                	add	sp,sp,-32
    80000854:	ec06                	sd	ra,24(sp)
    80000856:	e822                	sd	s0,16(sp)
    80000858:	1000                	add	s0,sp,32
    8000085a:	87aa                	mv	a5,a0
    8000085c:	fef42623          	sw	a5,-20(s0)
    // 如果系统panic，使用同步模式
    if(panicked) {
    80000860:	00005797          	auipc	a5,0x5
    80000864:	7a078793          	add	a5,a5,1952 # 80006000 <panicked>
    80000868:	439c                	lw	a5,0(a5)
    8000086a:	2781                	sext.w	a5,a5
    8000086c:	c399                	beqz	a5,80000872 <uart_putc+0x20>
        for(;;);
    8000086e:	0001                	nop
    80000870:	bffd                	j	8000086e <uart_putc+0x1c>
    }
    
    // 等待发送器空闲
    while((read_reg(LSR) & LSR_TX_IDLE) == 0);
    80000872:	0001                	nop
    80000874:	4515                	li	a0,5
    80000876:	00000097          	auipc	ra,0x0
    8000087a:	f1e080e7          	jalr	-226(ra) # 80000794 <read_reg>
    8000087e:	87aa                	mv	a5,a0
    80000880:	2781                	sext.w	a5,a5
    80000882:	0207f793          	and	a5,a5,32
    80000886:	2781                	sext.w	a5,a5
    80000888:	d7f5                	beqz	a5,80000874 <uart_putc+0x22>
    
    // 发送字符
    write_reg(THR, c);
    8000088a:	fec42783          	lw	a5,-20(s0)
    8000088e:	0ff7f793          	zext.b	a5,a5
    80000892:	85be                	mv	a1,a5
    80000894:	4501                	li	a0,0
    80000896:	00000097          	auipc	ra,0x0
    8000089a:	f24080e7          	jalr	-220(ra) # 800007ba <write_reg>
}
    8000089e:	0001                	nop
    800008a0:	60e2                	ld	ra,24(sp)
    800008a2:	6442                	ld	s0,16(sp)
    800008a4:	6105                	add	sp,sp,32
    800008a6:	8082                	ret

00000000800008a8 <uart_getc>:

// 接收一个字符（非阻塞）
int uart_getc(void) {
    800008a8:	1141                	add	sp,sp,-16
    800008aa:	e406                	sd	ra,8(sp)
    800008ac:	e022                	sd	s0,0(sp)
    800008ae:	0800                	add	s0,sp,16
    if(read_reg(LSR) & LSR_RX_READY) {
    800008b0:	4515                	li	a0,5
    800008b2:	00000097          	auipc	ra,0x0
    800008b6:	ee2080e7          	jalr	-286(ra) # 80000794 <read_reg>
    800008ba:	87aa                	mv	a5,a0
    800008bc:	2781                	sext.w	a5,a5
    800008be:	8b85                	and	a5,a5,1
    800008c0:	2781                	sext.w	a5,a5
    800008c2:	cb89                	beqz	a5,800008d4 <uart_getc+0x2c>
        return read_reg(RHR);
    800008c4:	4501                	li	a0,0
    800008c6:	00000097          	auipc	ra,0x0
    800008ca:	ece080e7          	jalr	-306(ra) # 80000794 <read_reg>
    800008ce:	87aa                	mv	a5,a0
    800008d0:	2781                	sext.w	a5,a5
    800008d2:	a011                	j	800008d6 <uart_getc+0x2e>
    }
    return -1;
    800008d4:	57fd                	li	a5,-1
    800008d6:	853e                	mv	a0,a5
    800008d8:	60a2                	ld	ra,8(sp)
    800008da:	6402                	ld	s0,0(sp)
    800008dc:	0141                	add	sp,sp,16
    800008de:	8082                	ret

00000000800008e0 <console_putc>:

#include "types.h"
#include "defs.h"

// 控制台输出一个字符
void console_putc(int c) {
    800008e0:	1101                	add	sp,sp,-32
    800008e2:	ec06                	sd	ra,24(sp)
    800008e4:	e822                	sd	s0,16(sp)
    800008e6:	1000                	add	s0,sp,32
    800008e8:	87aa                	mv	a5,a0
    800008ea:	fef42623          	sw	a5,-20(s0)
    // 处理退格
    if(c == '\b') {
    800008ee:	fec42783          	lw	a5,-20(s0)
    800008f2:	0007871b          	sext.w	a4,a5
    800008f6:	47a1                	li	a5,8
    800008f8:	02f71363          	bne	a4,a5,8000091e <console_putc+0x3e>
        uart_putc('\b');   // 光标后退一位
    800008fc:	4521                	li	a0,8
    800008fe:	00000097          	auipc	ra,0x0
    80000902:	f54080e7          	jalr	-172(ra) # 80000852 <uart_putc>
        uart_putc(' ');    // 覆盖字符
    80000906:	02000513          	li	a0,32
    8000090a:	00000097          	auipc	ra,0x0
    8000090e:	f48080e7          	jalr	-184(ra) # 80000852 <uart_putc>
        uart_putc('\b');   // 再次后退
    80000912:	4521                	li	a0,8
    80000914:	00000097          	auipc	ra,0x0
    80000918:	f3e080e7          	jalr	-194(ra) # 80000852 <uart_putc>
    } else {
        uart_putc(c);
    }
}
    8000091c:	a801                	j	8000092c <console_putc+0x4c>
        uart_putc(c);
    8000091e:	fec42783          	lw	a5,-20(s0)
    80000922:	853e                	mv	a0,a5
    80000924:	00000097          	auipc	ra,0x0
    80000928:	f2e080e7          	jalr	-210(ra) # 80000852 <uart_putc>
}
    8000092c:	0001                	nop
    8000092e:	60e2                	ld	ra,24(sp)
    80000930:	6442                	ld	s0,16(sp)
    80000932:	6105                	add	sp,sp,32
    80000934:	8082                	ret

0000000080000936 <console_init>:

// 初始化控制台
void console_init(void) {
    80000936:	1141                	add	sp,sp,-16
    80000938:	e406                	sd	ra,8(sp)
    8000093a:	e022                	sd	s0,0(sp)
    8000093c:	0800                	add	s0,sp,16
    // 初始化UART硬件
    uart_init();
    8000093e:	00000097          	auipc	ra,0x0
    80000942:	eac080e7          	jalr	-340(ra) # 800007ea <uart_init>
    
    // 控制台初始化完成
    80000946:	0001                	nop
    80000948:	60a2                	ld	ra,8(sp)
    8000094a:	6402                	ld	s0,0(sp)
    8000094c:	0141                	add	sp,sp,16
    8000094e:	8082                	ret

0000000080000950 <r_sstatus>:
}

// ==================== panic 实现 ====================

void panic(char *s) {
    printf("\n!!! PANIC !!!\n");
    80000950:	1101                	add	sp,sp,-32
    80000952:	ec22                	sd	s0,24(sp)
    80000954:	1000                	add	s0,sp,32
    printf("%s\n", s);
    printf("System halted.\n");
    80000956:	100027f3          	csrr	a5,sstatus
    8000095a:	fef43423          	sd	a5,-24(s0)
    
    8000095e:	fe843783          	ld	a5,-24(s0)
    // 关闭中断并永久停止
    80000962:	853e                	mv	a0,a5
    80000964:	6462                	ld	s0,24(sp)
    80000966:	6105                	add	sp,sp,32
    80000968:	8082                	ret

000000008000096a <w_sstatus>:
    intr_off();
    
    8000096a:	1101                	add	sp,sp,-32
    8000096c:	ec22                	sd	s0,24(sp)
    8000096e:	1000                	add	s0,sp,32
    80000970:	fea43423          	sd	a0,-24(s0)
    for(;;) {
    80000974:	fe843783          	ld	a5,-24(s0)
    80000978:	10079073          	csrw	sstatus,a5
        asm volatile("wfi");  // 等待中断（永远等待）
    8000097c:	0001                	nop
    8000097e:	6462                	ld	s0,24(sp)
    80000980:	6105                	add	sp,sp,32
    80000982:	8082                	ret

0000000080000984 <intr_off>:
    80000984:	1141                	add	sp,sp,-16
    80000986:	e406                	sd	ra,8(sp)
    80000988:	e022                	sd	s0,0(sp)
    8000098a:	0800                	add	s0,sp,16
    8000098c:	00000097          	auipc	ra,0x0
    80000990:	fc4080e7          	jalr	-60(ra) # 80000950 <r_sstatus>
    80000994:	87aa                	mv	a5,a0
    80000996:	9bf5                	and	a5,a5,-3
    80000998:	853e                	mv	a0,a5
    8000099a:	00000097          	auipc	ra,0x0
    8000099e:	fd0080e7          	jalr	-48(ra) # 8000096a <w_sstatus>
    800009a2:	0001                	nop
    800009a4:	60a2                	ld	ra,8(sp)
    800009a6:	6402                	ld	s0,0(sp)
    800009a8:	0141                	add	sp,sp,16
    800009aa:	8082                	ret

00000000800009ac <printint>:
static void printint(int xx, int base, int sign) {
    800009ac:	7139                	add	sp,sp,-64
    800009ae:	fc06                	sd	ra,56(sp)
    800009b0:	f822                	sd	s0,48(sp)
    800009b2:	0080                	add	s0,sp,64
    800009b4:	87aa                	mv	a5,a0
    800009b6:	86ae                	mv	a3,a1
    800009b8:	8732                	mv	a4,a2
    800009ba:	fcf42623          	sw	a5,-52(s0)
    800009be:	87b6                	mv	a5,a3
    800009c0:	fcf42423          	sw	a5,-56(s0)
    800009c4:	87ba                	mv	a5,a4
    800009c6:	fcf42223          	sw	a5,-60(s0)
    if(sign && (sign = xx < 0))
    800009ca:	fc442783          	lw	a5,-60(s0)
    800009ce:	2781                	sext.w	a5,a5
    800009d0:	c78d                	beqz	a5,800009fa <printint+0x4e>
    800009d2:	fcc42783          	lw	a5,-52(s0)
    800009d6:	01f7d79b          	srlw	a5,a5,0x1f
    800009da:	0ff7f793          	zext.b	a5,a5
    800009de:	fcf42223          	sw	a5,-60(s0)
    800009e2:	fc442783          	lw	a5,-60(s0)
    800009e6:	2781                	sext.w	a5,a5
    800009e8:	cb89                	beqz	a5,800009fa <printint+0x4e>
        x = -xx;
    800009ea:	fcc42783          	lw	a5,-52(s0)
    800009ee:	40f007bb          	negw	a5,a5
    800009f2:	2781                	sext.w	a5,a5
    800009f4:	fef42423          	sw	a5,-24(s0)
    800009f8:	a029                	j	80000a02 <printint+0x56>
        x = xx;
    800009fa:	fcc42783          	lw	a5,-52(s0)
    800009fe:	fef42423          	sw	a5,-24(s0)
    i = 0;
    80000a02:	fe042623          	sw	zero,-20(s0)
        buf[i++] = digits[x % base];
    80000a06:	fc842783          	lw	a5,-56(s0)
    80000a0a:	fe842703          	lw	a4,-24(s0)
    80000a0e:	02f777bb          	remuw	a5,a4,a5
    80000a12:	0007861b          	sext.w	a2,a5
    80000a16:	fec42783          	lw	a5,-20(s0)
    80000a1a:	0017871b          	addw	a4,a5,1
    80000a1e:	fee42623          	sw	a4,-20(s0)
    80000a22:	00005697          	auipc	a3,0x5
    80000a26:	13e68693          	add	a3,a3,318 # 80005b60 <digits>
    80000a2a:	02061713          	sll	a4,a2,0x20
    80000a2e:	9301                	srl	a4,a4,0x20
    80000a30:	9736                	add	a4,a4,a3
    80000a32:	00074703          	lbu	a4,0(a4)
    80000a36:	17c1                	add	a5,a5,-16
    80000a38:	97a2                	add	a5,a5,s0
    80000a3a:	fee78423          	sb	a4,-24(a5)
    } while((x /= base) != 0);
    80000a3e:	fc842783          	lw	a5,-56(s0)
    80000a42:	fe842703          	lw	a4,-24(s0)
    80000a46:	02f757bb          	divuw	a5,a4,a5
    80000a4a:	fef42423          	sw	a5,-24(s0)
    80000a4e:	fe842783          	lw	a5,-24(s0)
    80000a52:	2781                	sext.w	a5,a5
    80000a54:	fbcd                	bnez	a5,80000a06 <printint+0x5a>
    if(sign)
    80000a56:	fc442783          	lw	a5,-60(s0)
    80000a5a:	2781                	sext.w	a5,a5
    80000a5c:	cb95                	beqz	a5,80000a90 <printint+0xe4>
        buf[i++] = '-';
    80000a5e:	fec42783          	lw	a5,-20(s0)
    80000a62:	0017871b          	addw	a4,a5,1
    80000a66:	fee42623          	sw	a4,-20(s0)
    80000a6a:	17c1                	add	a5,a5,-16
    80000a6c:	97a2                	add	a5,a5,s0
    80000a6e:	02d00713          	li	a4,45
    80000a72:	fee78423          	sb	a4,-24(a5)
    while(--i >= 0)
    80000a76:	a829                	j	80000a90 <printint+0xe4>
        console_putc(buf[i]);
    80000a78:	fec42783          	lw	a5,-20(s0)
    80000a7c:	17c1                	add	a5,a5,-16
    80000a7e:	97a2                	add	a5,a5,s0
    80000a80:	fe87c783          	lbu	a5,-24(a5)
    80000a84:	2781                	sext.w	a5,a5
    80000a86:	853e                	mv	a0,a5
    80000a88:	00000097          	auipc	ra,0x0
    80000a8c:	e58080e7          	jalr	-424(ra) # 800008e0 <console_putc>
    while(--i >= 0)
    80000a90:	fec42783          	lw	a5,-20(s0)
    80000a94:	37fd                	addw	a5,a5,-1
    80000a96:	fef42623          	sw	a5,-20(s0)
    80000a9a:	fec42783          	lw	a5,-20(s0)
    80000a9e:	2781                	sext.w	a5,a5
    80000aa0:	fc07dce3          	bgez	a5,80000a78 <printint+0xcc>
}
    80000aa4:	0001                	nop
    80000aa6:	0001                	nop
    80000aa8:	70e2                	ld	ra,56(sp)
    80000aaa:	7442                	ld	s0,48(sp)
    80000aac:	6121                	add	sp,sp,64
    80000aae:	8082                	ret

0000000080000ab0 <printptr>:
static void printptr(uint64 x) {
    80000ab0:	7179                	add	sp,sp,-48
    80000ab2:	f406                	sd	ra,40(sp)
    80000ab4:	f022                	sd	s0,32(sp)
    80000ab6:	1800                	add	s0,sp,48
    80000ab8:	fca43c23          	sd	a0,-40(s0)
    console_putc('0');
    80000abc:	03000513          	li	a0,48
    80000ac0:	00000097          	auipc	ra,0x0
    80000ac4:	e20080e7          	jalr	-480(ra) # 800008e0 <console_putc>
    console_putc('x');
    80000ac8:	07800513          	li	a0,120
    80000acc:	00000097          	auipc	ra,0x0
    80000ad0:	e14080e7          	jalr	-492(ra) # 800008e0 <console_putc>
    for(i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    80000ad4:	fe042623          	sw	zero,-20(s0)
    80000ad8:	a81d                	j	80000b0e <printptr+0x5e>
        console_putc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000ada:	fd843783          	ld	a5,-40(s0)
    80000ade:	93f1                	srl	a5,a5,0x3c
    80000ae0:	00005717          	auipc	a4,0x5
    80000ae4:	08070713          	add	a4,a4,128 # 80005b60 <digits>
    80000ae8:	97ba                	add	a5,a5,a4
    80000aea:	0007c783          	lbu	a5,0(a5)
    80000aee:	2781                	sext.w	a5,a5
    80000af0:	853e                	mv	a0,a5
    80000af2:	00000097          	auipc	ra,0x0
    80000af6:	dee080e7          	jalr	-530(ra) # 800008e0 <console_putc>
    for(i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    80000afa:	fec42783          	lw	a5,-20(s0)
    80000afe:	2785                	addw	a5,a5,1
    80000b00:	fef42623          	sw	a5,-20(s0)
    80000b04:	fd843783          	ld	a5,-40(s0)
    80000b08:	0792                	sll	a5,a5,0x4
    80000b0a:	fcf43c23          	sd	a5,-40(s0)
    80000b0e:	fec42783          	lw	a5,-20(s0)
    80000b12:	873e                	mv	a4,a5
    80000b14:	47bd                	li	a5,15
    80000b16:	fce7f2e3          	bgeu	a5,a4,80000ada <printptr+0x2a>
}
    80000b1a:	0001                	nop
    80000b1c:	0001                	nop
    80000b1e:	70a2                	ld	ra,40(sp)
    80000b20:	7402                	ld	s0,32(sp)
    80000b22:	6145                	add	sp,sp,48
    80000b24:	8082                	ret

0000000080000b26 <printf>:
void printf(char *fmt, ...) {
    80000b26:	7119                	add	sp,sp,-128
    80000b28:	fc06                	sd	ra,56(sp)
    80000b2a:	f822                	sd	s0,48(sp)
    80000b2c:	0080                	add	s0,sp,64
    80000b2e:	fca43423          	sd	a0,-56(s0)
    80000b32:	e40c                	sd	a1,8(s0)
    80000b34:	e810                	sd	a2,16(s0)
    80000b36:	ec14                	sd	a3,24(s0)
    80000b38:	f018                	sd	a4,32(s0)
    80000b3a:	f41c                	sd	a5,40(s0)
    80000b3c:	03043823          	sd	a6,48(s0)
    80000b40:	03143c23          	sd	a7,56(s0)
    __builtin_va_start(ap, fmt);
    80000b44:	04040793          	add	a5,s0,64
    80000b48:	fcf43023          	sd	a5,-64(s0)
    80000b4c:	fc043783          	ld	a5,-64(s0)
    80000b50:	fc878793          	add	a5,a5,-56
    80000b54:	fcf43c23          	sd	a5,-40(s0)
    if(fmt == 0) {
    80000b58:	fc843783          	ld	a5,-56(s0)
    80000b5c:	eb89                	bnez	a5,80000b6e <printf+0x48>
        panic("null fmt");
    80000b5e:	00004517          	auipc	a0,0x4
    80000b62:	98250513          	add	a0,a0,-1662 # 800044e0 <etext+0x4e0>
    80000b66:	00000097          	auipc	ra,0x0
    80000b6a:	2ba080e7          	jalr	698(ra) # 80000e20 <panic>
    for(int i = 0; (c = fmt[i] & 0xff) != 0; i++) {
    80000b6e:	fe042223          	sw	zero,-28(s0)
    80000b72:	a451                	j	80000df6 <printf+0x2d0>
        if(c != '%') {
    80000b74:	fe042783          	lw	a5,-32(s0)
    80000b78:	0007871b          	sext.w	a4,a5
    80000b7c:	02500793          	li	a5,37
    80000b80:	00f70a63          	beq	a4,a5,80000b94 <printf+0x6e>
            console_putc(c);
    80000b84:	fe042783          	lw	a5,-32(s0)
    80000b88:	853e                	mv	a0,a5
    80000b8a:	00000097          	auipc	ra,0x0
    80000b8e:	d56080e7          	jalr	-682(ra) # 800008e0 <console_putc>
            continue;
    80000b92:	aca9                	j	80000dec <printf+0x2c6>
        c = fmt[++i] & 0xff;
    80000b94:	fe442783          	lw	a5,-28(s0)
    80000b98:	2785                	addw	a5,a5,1
    80000b9a:	fef42223          	sw	a5,-28(s0)
    80000b9e:	fe442783          	lw	a5,-28(s0)
    80000ba2:	fc843703          	ld	a4,-56(s0)
    80000ba6:	97ba                	add	a5,a5,a4
    80000ba8:	0007c783          	lbu	a5,0(a5)
    80000bac:	fef42023          	sw	a5,-32(s0)
        if(c == 0)
    80000bb0:	fe042783          	lw	a5,-32(s0)
    80000bb4:	2781                	sext.w	a5,a5
    80000bb6:	24078f63          	beqz	a5,80000e14 <printf+0x2ee>
        switch(c) {
    80000bba:	fe042783          	lw	a5,-32(s0)
    80000bbe:	0007871b          	sext.w	a4,a5
    80000bc2:	02500793          	li	a5,37
    80000bc6:	1ef70d63          	beq	a4,a5,80000dc0 <printf+0x29a>
    80000bca:	fe042783          	lw	a5,-32(s0)
    80000bce:	0007871b          	sext.w	a4,a5
    80000bd2:	02500793          	li	a5,37
    80000bd6:	1ef74c63          	blt	a4,a5,80000dce <printf+0x2a8>
    80000bda:	fe042783          	lw	a5,-32(s0)
    80000bde:	0007871b          	sext.w	a4,a5
    80000be2:	07800793          	li	a5,120
    80000be6:	1ee7c463          	blt	a5,a4,80000dce <printf+0x2a8>
    80000bea:	fe042783          	lw	a5,-32(s0)
    80000bee:	0007871b          	sext.w	a4,a5
    80000bf2:	06300793          	li	a5,99
    80000bf6:	1cf74c63          	blt	a4,a5,80000dce <printf+0x2a8>
    80000bfa:	fe042783          	lw	a5,-32(s0)
    80000bfe:	f9d7869b          	addw	a3,a5,-99
    80000c02:	0006871b          	sext.w	a4,a3
    80000c06:	47d5                	li	a5,21
    80000c08:	1ce7e363          	bltu	a5,a4,80000dce <printf+0x2a8>
    80000c0c:	02069793          	sll	a5,a3,0x20
    80000c10:	9381                	srl	a5,a5,0x20
    80000c12:	00279713          	sll	a4,a5,0x2
    80000c16:	00004797          	auipc	a5,0x4
    80000c1a:	8e278793          	add	a5,a5,-1822 # 800044f8 <etext+0x4f8>
    80000c1e:	97ba                	add	a5,a5,a4
    80000c20:	439c                	lw	a5,0(a5)
    80000c22:	0007871b          	sext.w	a4,a5
    80000c26:	00004797          	auipc	a5,0x4
    80000c2a:	8d278793          	add	a5,a5,-1838 # 800044f8 <etext+0x4f8>
    80000c2e:	97ba                	add	a5,a5,a4
    80000c30:	8782                	jr	a5
                printint(__builtin_va_arg(ap, int), 10, 1);
    80000c32:	fd843783          	ld	a5,-40(s0)
    80000c36:	00878713          	add	a4,a5,8
    80000c3a:	fce43c23          	sd	a4,-40(s0)
    80000c3e:	439c                	lw	a5,0(a5)
    80000c40:	4605                	li	a2,1
    80000c42:	45a9                	li	a1,10
    80000c44:	853e                	mv	a0,a5
    80000c46:	00000097          	auipc	ra,0x0
    80000c4a:	d66080e7          	jalr	-666(ra) # 800009ac <printint>
                break;
    80000c4e:	aa79                	j	80000dec <printf+0x2c6>
                c = fmt[++i] & 0xff;
    80000c50:	fe442783          	lw	a5,-28(s0)
    80000c54:	2785                	addw	a5,a5,1
    80000c56:	fef42223          	sw	a5,-28(s0)
    80000c5a:	fe442783          	lw	a5,-28(s0)
    80000c5e:	fc843703          	ld	a4,-56(s0)
    80000c62:	97ba                	add	a5,a5,a4
    80000c64:	0007c783          	lbu	a5,0(a5)
    80000c68:	fef42023          	sw	a5,-32(s0)
                if(c == 'd') {
    80000c6c:	fe042783          	lw	a5,-32(s0)
    80000c70:	0007871b          	sext.w	a4,a5
    80000c74:	06400793          	li	a5,100
    80000c78:	02f71263          	bne	a4,a5,80000c9c <printf+0x176>
                    printint(__builtin_va_arg(ap, long), 10, 1);
    80000c7c:	fd843783          	ld	a5,-40(s0)
    80000c80:	00878713          	add	a4,a5,8
    80000c84:	fce43c23          	sd	a4,-40(s0)
    80000c88:	639c                	ld	a5,0(a5)
    80000c8a:	2781                	sext.w	a5,a5
    80000c8c:	4605                	li	a2,1
    80000c8e:	45a9                	li	a1,10
    80000c90:	853e                	mv	a0,a5
    80000c92:	00000097          	auipc	ra,0x0
    80000c96:	d1a080e7          	jalr	-742(ra) # 800009ac <printint>
                break;
    80000c9a:	aa81                	j	80000dea <printf+0x2c4>
                } else if(c == 'u') {
    80000c9c:	fe042783          	lw	a5,-32(s0)
    80000ca0:	0007871b          	sext.w	a4,a5
    80000ca4:	07500793          	li	a5,117
    80000ca8:	02f71263          	bne	a4,a5,80000ccc <printf+0x1a6>
                    printint(__builtin_va_arg(ap, unsigned long), 10, 0);
    80000cac:	fd843783          	ld	a5,-40(s0)
    80000cb0:	00878713          	add	a4,a5,8
    80000cb4:	fce43c23          	sd	a4,-40(s0)
    80000cb8:	639c                	ld	a5,0(a5)
    80000cba:	2781                	sext.w	a5,a5
    80000cbc:	4601                	li	a2,0
    80000cbe:	45a9                	li	a1,10
    80000cc0:	853e                	mv	a0,a5
    80000cc2:	00000097          	auipc	ra,0x0
    80000cc6:	cea080e7          	jalr	-790(ra) # 800009ac <printint>
                break;
    80000cca:	a205                	j	80000dea <printf+0x2c4>
                } else if(c == 'x') {
    80000ccc:	fe042783          	lw	a5,-32(s0)
    80000cd0:	0007871b          	sext.w	a4,a5
    80000cd4:	07800793          	li	a5,120
    80000cd8:	10f71963          	bne	a4,a5,80000dea <printf+0x2c4>
                    printint(__builtin_va_arg(ap, unsigned long), 16, 0);
    80000cdc:	fd843783          	ld	a5,-40(s0)
    80000ce0:	00878713          	add	a4,a5,8
    80000ce4:	fce43c23          	sd	a4,-40(s0)
    80000ce8:	639c                	ld	a5,0(a5)
    80000cea:	2781                	sext.w	a5,a5
    80000cec:	4601                	li	a2,0
    80000cee:	45c1                	li	a1,16
    80000cf0:	853e                	mv	a0,a5
    80000cf2:	00000097          	auipc	ra,0x0
    80000cf6:	cba080e7          	jalr	-838(ra) # 800009ac <printint>
                break;
    80000cfa:	a8c5                	j	80000dea <printf+0x2c4>
                printint(__builtin_va_arg(ap, unsigned int), 10, 0);
    80000cfc:	fd843783          	ld	a5,-40(s0)
    80000d00:	00878713          	add	a4,a5,8
    80000d04:	fce43c23          	sd	a4,-40(s0)
    80000d08:	439c                	lw	a5,0(a5)
    80000d0a:	2781                	sext.w	a5,a5
    80000d0c:	4601                	li	a2,0
    80000d0e:	45a9                	li	a1,10
    80000d10:	853e                	mv	a0,a5
    80000d12:	00000097          	auipc	ra,0x0
    80000d16:	c9a080e7          	jalr	-870(ra) # 800009ac <printint>
                break;
    80000d1a:	a8c9                	j	80000dec <printf+0x2c6>
                printint(__builtin_va_arg(ap, unsigned int), 16, 0);
    80000d1c:	fd843783          	ld	a5,-40(s0)
    80000d20:	00878713          	add	a4,a5,8
    80000d24:	fce43c23          	sd	a4,-40(s0)
    80000d28:	439c                	lw	a5,0(a5)
    80000d2a:	2781                	sext.w	a5,a5
    80000d2c:	4601                	li	a2,0
    80000d2e:	45c1                	li	a1,16
    80000d30:	853e                	mv	a0,a5
    80000d32:	00000097          	auipc	ra,0x0
    80000d36:	c7a080e7          	jalr	-902(ra) # 800009ac <printint>
                break;
    80000d3a:	a84d                	j	80000dec <printf+0x2c6>
                printptr(__builtin_va_arg(ap, uint64));
    80000d3c:	fd843783          	ld	a5,-40(s0)
    80000d40:	00878713          	add	a4,a5,8
    80000d44:	fce43c23          	sd	a4,-40(s0)
    80000d48:	639c                	ld	a5,0(a5)
    80000d4a:	853e                	mv	a0,a5
    80000d4c:	00000097          	auipc	ra,0x0
    80000d50:	d64080e7          	jalr	-668(ra) # 80000ab0 <printptr>
                break;
    80000d54:	a861                	j	80000dec <printf+0x2c6>
                console_putc(__builtin_va_arg(ap, int));
    80000d56:	fd843783          	ld	a5,-40(s0)
    80000d5a:	00878713          	add	a4,a5,8
    80000d5e:	fce43c23          	sd	a4,-40(s0)
    80000d62:	439c                	lw	a5,0(a5)
    80000d64:	853e                	mv	a0,a5
    80000d66:	00000097          	auipc	ra,0x0
    80000d6a:	b7a080e7          	jalr	-1158(ra) # 800008e0 <console_putc>
                break;
    80000d6e:	a8bd                	j	80000dec <printf+0x2c6>
                if((s = __builtin_va_arg(ap, char*)) == 0)
    80000d70:	fd843783          	ld	a5,-40(s0)
    80000d74:	00878713          	add	a4,a5,8
    80000d78:	fce43c23          	sd	a4,-40(s0)
    80000d7c:	639c                	ld	a5,0(a5)
    80000d7e:	fef43423          	sd	a5,-24(s0)
    80000d82:	fe843783          	ld	a5,-24(s0)
    80000d86:	e79d                	bnez	a5,80000db4 <printf+0x28e>
                    s = "(null)";
    80000d88:	00003797          	auipc	a5,0x3
    80000d8c:	76878793          	add	a5,a5,1896 # 800044f0 <etext+0x4f0>
    80000d90:	fef43423          	sd	a5,-24(s0)
                for(; *s; s++)
    80000d94:	a005                	j	80000db4 <printf+0x28e>
                    console_putc(*s);
    80000d96:	fe843783          	ld	a5,-24(s0)
    80000d9a:	0007c783          	lbu	a5,0(a5)
    80000d9e:	2781                	sext.w	a5,a5
    80000da0:	853e                	mv	a0,a5
    80000da2:	00000097          	auipc	ra,0x0
    80000da6:	b3e080e7          	jalr	-1218(ra) # 800008e0 <console_putc>
                for(; *s; s++)
    80000daa:	fe843783          	ld	a5,-24(s0)
    80000dae:	0785                	add	a5,a5,1
    80000db0:	fef43423          	sd	a5,-24(s0)
    80000db4:	fe843783          	ld	a5,-24(s0)
    80000db8:	0007c783          	lbu	a5,0(a5)
    80000dbc:	ffe9                	bnez	a5,80000d96 <printf+0x270>
                break;
    80000dbe:	a03d                	j	80000dec <printf+0x2c6>
                console_putc('%');
    80000dc0:	02500513          	li	a0,37
    80000dc4:	00000097          	auipc	ra,0x0
    80000dc8:	b1c080e7          	jalr	-1252(ra) # 800008e0 <console_putc>
                break;
    80000dcc:	a005                	j	80000dec <printf+0x2c6>
                console_putc('%');
    80000dce:	02500513          	li	a0,37
    80000dd2:	00000097          	auipc	ra,0x0
    80000dd6:	b0e080e7          	jalr	-1266(ra) # 800008e0 <console_putc>
                console_putc(c);
    80000dda:	fe042783          	lw	a5,-32(s0)
    80000dde:	853e                	mv	a0,a5
    80000de0:	00000097          	auipc	ra,0x0
    80000de4:	b00080e7          	jalr	-1280(ra) # 800008e0 <console_putc>
                break;
    80000de8:	a011                	j	80000dec <printf+0x2c6>
                break;
    80000dea:	0001                	nop
    for(int i = 0; (c = fmt[i] & 0xff) != 0; i++) {
    80000dec:	fe442783          	lw	a5,-28(s0)
    80000df0:	2785                	addw	a5,a5,1
    80000df2:	fef42223          	sw	a5,-28(s0)
    80000df6:	fe442783          	lw	a5,-28(s0)
    80000dfa:	fc843703          	ld	a4,-56(s0)
    80000dfe:	97ba                	add	a5,a5,a4
    80000e00:	0007c783          	lbu	a5,0(a5)
    80000e04:	fef42023          	sw	a5,-32(s0)
    80000e08:	fe042783          	lw	a5,-32(s0)
    80000e0c:	2781                	sext.w	a5,a5
    80000e0e:	d60793e3          	bnez	a5,80000b74 <printf+0x4e>
}
    80000e12:	a011                	j	80000e16 <printf+0x2f0>
            break;
    80000e14:	0001                	nop
}
    80000e16:	0001                	nop
    80000e18:	70e2                	ld	ra,56(sp)
    80000e1a:	7442                	ld	s0,48(sp)
    80000e1c:	6109                	add	sp,sp,128
    80000e1e:	8082                	ret

0000000080000e20 <panic>:
void panic(char *s) {
    80000e20:	1101                	add	sp,sp,-32
    80000e22:	ec06                	sd	ra,24(sp)
    80000e24:	e822                	sd	s0,16(sp)
    80000e26:	1000                	add	s0,sp,32
    80000e28:	fea43423          	sd	a0,-24(s0)
    printf("\n!!! PANIC !!!\n");
    80000e2c:	00003517          	auipc	a0,0x3
    80000e30:	72450513          	add	a0,a0,1828 # 80004550 <etext+0x550>
    80000e34:	00000097          	auipc	ra,0x0
    80000e38:	cf2080e7          	jalr	-782(ra) # 80000b26 <printf>
    printf("%s\n", s);
    80000e3c:	fe843583          	ld	a1,-24(s0)
    80000e40:	00003517          	auipc	a0,0x3
    80000e44:	72050513          	add	a0,a0,1824 # 80004560 <etext+0x560>
    80000e48:	00000097          	auipc	ra,0x0
    80000e4c:	cde080e7          	jalr	-802(ra) # 80000b26 <printf>
    printf("System halted.\n");
    80000e50:	00003517          	auipc	a0,0x3
    80000e54:	71850513          	add	a0,a0,1816 # 80004568 <etext+0x568>
    80000e58:	00000097          	auipc	ra,0x0
    80000e5c:	cce080e7          	jalr	-818(ra) # 80000b26 <printf>
    intr_off();
    80000e60:	00000097          	auipc	ra,0x0
    80000e64:	b24080e7          	jalr	-1244(ra) # 80000984 <intr_off>
        asm volatile("wfi");  // 等待中断（永远等待）
    80000e68:	10500073          	wfi
    80000e6c:	bff5                	j	80000e68 <panic+0x48>

0000000080000e6e <screen_clear>:

#include "types.h"
#include "defs.h"

// 清屏
void screen_clear(void) {
    80000e6e:	1141                	add	sp,sp,-16
    80000e70:	e406                	sd	ra,8(sp)
    80000e72:	e022                	sd	s0,0(sp)
    80000e74:	0800                	add	s0,sp,16
    // 使用ANSI转义序列清屏
    console_putc('\033');  // ESC
    80000e76:	456d                	li	a0,27
    80000e78:	00000097          	auipc	ra,0x0
    80000e7c:	a68080e7          	jalr	-1432(ra) # 800008e0 <console_putc>
    console_putc('[');
    80000e80:	05b00513          	li	a0,91
    80000e84:	00000097          	auipc	ra,0x0
    80000e88:	a5c080e7          	jalr	-1444(ra) # 800008e0 <console_putc>
    console_putc('2');
    80000e8c:	03200513          	li	a0,50
    80000e90:	00000097          	auipc	ra,0x0
    80000e94:	a50080e7          	jalr	-1456(ra) # 800008e0 <console_putc>
    console_putc('J');
    80000e98:	04a00513          	li	a0,74
    80000e9c:	00000097          	auipc	ra,0x0
    80000ea0:	a44080e7          	jalr	-1468(ra) # 800008e0 <console_putc>
    
    // 移动光标到左上角
    console_putc('\033');  // ESC
    80000ea4:	456d                	li	a0,27
    80000ea6:	00000097          	auipc	ra,0x0
    80000eaa:	a3a080e7          	jalr	-1478(ra) # 800008e0 <console_putc>
    console_putc('[');
    80000eae:	05b00513          	li	a0,91
    80000eb2:	00000097          	auipc	ra,0x0
    80000eb6:	a2e080e7          	jalr	-1490(ra) # 800008e0 <console_putc>
    console_putc('H');
    80000eba:	04800513          	li	a0,72
    80000ebe:	00000097          	auipc	ra,0x0
    80000ec2:	a22080e7          	jalr	-1502(ra) # 800008e0 <console_putc>
}
    80000ec6:	0001                	nop
    80000ec8:	60a2                	ld	ra,8(sp)
    80000eca:	6402                	ld	s0,0(sp)
    80000ecc:	0141                	add	sp,sp,16
    80000ece:	8082                	ret

0000000080000ed0 <screen_putc>:

// 输出字符到屏幕
void screen_putc(int c) {
    80000ed0:	1101                	add	sp,sp,-32
    80000ed2:	ec06                	sd	ra,24(sp)
    80000ed4:	e822                	sd	s0,16(sp)
    80000ed6:	1000                	add	s0,sp,32
    80000ed8:	87aa                	mv	a5,a0
    80000eda:	fef42623          	sw	a5,-20(s0)
    console_putc(c);
    80000ede:	fec42783          	lw	a5,-20(s0)
    80000ee2:	853e                	mv	a0,a5
    80000ee4:	00000097          	auipc	ra,0x0
    80000ee8:	9fc080e7          	jalr	-1540(ra) # 800008e0 <console_putc>
    80000eec:	0001                	nop
    80000eee:	60e2                	ld	ra,24(sp)
    80000ef0:	6442                	ld	s0,16(sp)
    80000ef2:	6105                	add	sp,sp,32
    80000ef4:	8082                	ret

0000000080000ef6 <memset>:
} kmem;

// ==================== 工具函数 ====================

// 简单的memset实现
void* memset(void *dst, int c, uint n) {
    80000ef6:	7179                	add	sp,sp,-48
    80000ef8:	f422                	sd	s0,40(sp)
    80000efa:	1800                	add	s0,sp,48
    80000efc:	fca43c23          	sd	a0,-40(s0)
    80000f00:	87ae                	mv	a5,a1
    80000f02:	8732                	mv	a4,a2
    80000f04:	fcf42a23          	sw	a5,-44(s0)
    80000f08:	87ba                	mv	a5,a4
    80000f0a:	fcf42823          	sw	a5,-48(s0)
    char *cdst = (char*)dst;
    80000f0e:	fd843783          	ld	a5,-40(s0)
    80000f12:	fef43023          	sd	a5,-32(s0)
    int i;
    for(i = 0; i < n; i++) {
    80000f16:	fe042623          	sw	zero,-20(s0)
    80000f1a:	a00d                	j	80000f3c <memset+0x46>
        cdst[i] = c;
    80000f1c:	fec42783          	lw	a5,-20(s0)
    80000f20:	fe043703          	ld	a4,-32(s0)
    80000f24:	97ba                	add	a5,a5,a4
    80000f26:	fd442703          	lw	a4,-44(s0)
    80000f2a:	0ff77713          	zext.b	a4,a4
    80000f2e:	00e78023          	sb	a4,0(a5)
    for(i = 0; i < n; i++) {
    80000f32:	fec42783          	lw	a5,-20(s0)
    80000f36:	2785                	addw	a5,a5,1
    80000f38:	fef42623          	sw	a5,-20(s0)
    80000f3c:	fec42703          	lw	a4,-20(s0)
    80000f40:	fd042783          	lw	a5,-48(s0)
    80000f44:	2781                	sext.w	a5,a5
    80000f46:	fcf76be3          	bltu	a4,a5,80000f1c <memset+0x26>
    }
    return dst;
    80000f4a:	fd843783          	ld	a5,-40(s0)
}
    80000f4e:	853e                	mv	a0,a5
    80000f50:	7422                	ld	s0,40(sp)
    80000f52:	6145                	add	sp,sp,48
    80000f54:	8082                	ret

0000000080000f56 <kinit>:

// ==================== 初始化物理内存分配器 ====================

void kinit(void) {
    80000f56:	7179                	add	sp,sp,-48
    80000f58:	f406                	sd	ra,40(sp)
    80000f5a:	f022                	sd	s0,32(sp)
    80000f5c:	1800                	add	s0,sp,48
    // 确定可分配内存范围
    char *mem_start = (char*)PGROUNDUP((uint64)end);
    80000f5e:	0000b717          	auipc	a4,0xb
    80000f62:	0b270713          	add	a4,a4,178 # 8000c010 <bss_end>
    80000f66:	6785                	lui	a5,0x1
    80000f68:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    80000f6a:	973e                	add	a4,a4,a5
    80000f6c:	77fd                	lui	a5,0xfffff
    80000f6e:	8ff9                	and	a5,a5,a4
    80000f70:	fef43023          	sd	a5,-32(s0)
    char *mem_end = (char*)PHYSTOP;
    80000f74:	47c5                	li	a5,17
    80000f76:	07ee                	sll	a5,a5,0x1b
    80000f78:	fcf43c23          	sd	a5,-40(s0)
    
    // 初始化管理器状态
    kmem.freelist = 0;
    80000f7c:	00008797          	auipc	a5,0x8
    80000f80:	0ac78793          	add	a5,a5,172 # 80009028 <kmem>
    80000f84:	0007b023          	sd	zero,0(a5)
    kmem.total_pages = 0;
    80000f88:	00008797          	auipc	a5,0x8
    80000f8c:	0a078793          	add	a5,a5,160 # 80009028 <kmem>
    80000f90:	0007b423          	sd	zero,8(a5)
    kmem.free_pages = 0;
    80000f94:	00008797          	auipc	a5,0x8
    80000f98:	09478793          	add	a5,a5,148 # 80009028 <kmem>
    80000f9c:	0007b823          	sd	zero,16(a5)
    
    printf("PMM: Initializing memory from %p to %p\n", mem_start, mem_end);
    80000fa0:	fd843603          	ld	a2,-40(s0)
    80000fa4:	fe043583          	ld	a1,-32(s0)
    80000fa8:	00003517          	auipc	a0,0x3
    80000fac:	5d050513          	add	a0,a0,1488 # 80004578 <etext+0x578>
    80000fb0:	00000097          	auipc	ra,0x0
    80000fb4:	b76080e7          	jalr	-1162(ra) # 80000b26 <printf>
    
    // 构建空闲页面链表
    char *p;
    for(p = mem_start; p + PGSIZE <= mem_end; p += PGSIZE) {
    80000fb8:	fe043783          	ld	a5,-32(s0)
    80000fbc:	fef43423          	sd	a5,-24(s0)
    80000fc0:	a089                	j	80001002 <kinit+0xac>
        memset(p, 0, PGSIZE);
    80000fc2:	6605                	lui	a2,0x1
    80000fc4:	4581                	li	a1,0
    80000fc6:	fe843503          	ld	a0,-24(s0)
    80000fca:	00000097          	auipc	ra,0x0
    80000fce:	f2c080e7          	jalr	-212(ra) # 80000ef6 <memset>
        free_page(p);
    80000fd2:	fe843503          	ld	a0,-24(s0)
    80000fd6:	00000097          	auipc	ra,0x0
    80000fda:	0ee080e7          	jalr	238(ra) # 800010c4 <free_page>
        kmem.total_pages++;
    80000fde:	00008797          	auipc	a5,0x8
    80000fe2:	04a78793          	add	a5,a5,74 # 80009028 <kmem>
    80000fe6:	679c                	ld	a5,8(a5)
    80000fe8:	00178713          	add	a4,a5,1
    80000fec:	00008797          	auipc	a5,0x8
    80000ff0:	03c78793          	add	a5,a5,60 # 80009028 <kmem>
    80000ff4:	e798                	sd	a4,8(a5)
    for(p = mem_start; p + PGSIZE <= mem_end; p += PGSIZE) {
    80000ff6:	fe843703          	ld	a4,-24(s0)
    80000ffa:	6785                	lui	a5,0x1
    80000ffc:	97ba                	add	a5,a5,a4
    80000ffe:	fef43423          	sd	a5,-24(s0)
    80001002:	fe843703          	ld	a4,-24(s0)
    80001006:	6785                	lui	a5,0x1
    80001008:	97ba                	add	a5,a5,a4
    8000100a:	fd843703          	ld	a4,-40(s0)
    8000100e:	faf77ae3          	bgeu	a4,a5,80000fc2 <kinit+0x6c>
    }
    
    printf("PMM: Initialized %d pages (%d KB)\n", 
           (int)kmem.total_pages, (int)(kmem.total_pages * PGSIZE) / 1024);
    80001012:	00008797          	auipc	a5,0x8
    80001016:	01678793          	add	a5,a5,22 # 80009028 <kmem>
    8000101a:	679c                	ld	a5,8(a5)
    printf("PMM: Initialized %d pages (%d KB)\n", 
    8000101c:	0007869b          	sext.w	a3,a5
           (int)kmem.total_pages, (int)(kmem.total_pages * PGSIZE) / 1024);
    80001020:	00008797          	auipc	a5,0x8
    80001024:	00878793          	add	a5,a5,8 # 80009028 <kmem>
    80001028:	679c                	ld	a5,8(a5)
    8000102a:	2781                	sext.w	a5,a5
    8000102c:	00c7979b          	sllw	a5,a5,0xc
    80001030:	2781                	sext.w	a5,a5
    80001032:	2781                	sext.w	a5,a5
    printf("PMM: Initialized %d pages (%d KB)\n", 
    80001034:	41f7d71b          	sraw	a4,a5,0x1f
    80001038:	0167571b          	srlw	a4,a4,0x16
    8000103c:	9fb9                	addw	a5,a5,a4
    8000103e:	40a7d79b          	sraw	a5,a5,0xa
    80001042:	2781                	sext.w	a5,a5
    80001044:	863e                	mv	a2,a5
    80001046:	85b6                	mv	a1,a3
    80001048:	00003517          	auipc	a0,0x3
    8000104c:	55850513          	add	a0,a0,1368 # 800045a0 <etext+0x5a0>
    80001050:	00000097          	auipc	ra,0x0
    80001054:	ad6080e7          	jalr	-1322(ra) # 80000b26 <printf>
}
    80001058:	0001                	nop
    8000105a:	70a2                	ld	ra,40(sp)
    8000105c:	7402                	ld	s0,32(sp)
    8000105e:	6145                	add	sp,sp,48
    80001060:	8082                	ret

0000000080001062 <alloc_page>:

// ==================== 分配一个物理页面 ====================

void* alloc_page(void) {
    80001062:	1101                	add	sp,sp,-32
    80001064:	ec06                	sd	ra,24(sp)
    80001066:	e822                	sd	s0,16(sp)
    80001068:	1000                	add	s0,sp,32
    struct run *r;
    
    r = kmem.freelist;
    8000106a:	00008797          	auipc	a5,0x8
    8000106e:	fbe78793          	add	a5,a5,-66 # 80009028 <kmem>
    80001072:	639c                	ld	a5,0(a5)
    80001074:	fef43423          	sd	a5,-24(s0)
    if(r) {
    80001078:	fe843783          	ld	a5,-24(s0)
    8000107c:	cf8d                	beqz	a5,800010b6 <alloc_page+0x54>
        kmem.freelist = r->next;
    8000107e:	fe843783          	ld	a5,-24(s0)
    80001082:	6398                	ld	a4,0(a5)
    80001084:	00008797          	auipc	a5,0x8
    80001088:	fa478793          	add	a5,a5,-92 # 80009028 <kmem>
    8000108c:	e398                	sd	a4,0(a5)
        kmem.free_pages--;
    8000108e:	00008797          	auipc	a5,0x8
    80001092:	f9a78793          	add	a5,a5,-102 # 80009028 <kmem>
    80001096:	6b9c                	ld	a5,16(a5)
    80001098:	fff78713          	add	a4,a5,-1
    8000109c:	00008797          	auipc	a5,0x8
    800010a0:	f8c78793          	add	a5,a5,-116 # 80009028 <kmem>
    800010a4:	eb98                	sd	a4,16(a5)
        
        // 清零分配的页面
        memset((char*)r, 0, PGSIZE);
    800010a6:	6605                	lui	a2,0x1
    800010a8:	4581                	li	a1,0
    800010aa:	fe843503          	ld	a0,-24(s0)
    800010ae:	00000097          	auipc	ra,0x0
    800010b2:	e48080e7          	jalr	-440(ra) # 80000ef6 <memset>
    }
    
    return (void*)r;
    800010b6:	fe843783          	ld	a5,-24(s0)
}
    800010ba:	853e                	mv	a0,a5
    800010bc:	60e2                	ld	ra,24(sp)
    800010be:	6442                	ld	s0,16(sp)
    800010c0:	6105                	add	sp,sp,32
    800010c2:	8082                	ret

00000000800010c4 <free_page>:

// ==================== 释放一个物理页面 ====================

void free_page(void* pa) {
    800010c4:	7179                	add	sp,sp,-48
    800010c6:	f406                	sd	ra,40(sp)
    800010c8:	f022                	sd	s0,32(sp)
    800010ca:	1800                	add	s0,sp,48
    800010cc:	fca43c23          	sd	a0,-40(s0)
    struct run *r;
    
    // 地址有效性检查
    if(((uint64)pa % PGSIZE) != 0)
    800010d0:	fd843703          	ld	a4,-40(s0)
    800010d4:	6785                	lui	a5,0x1
    800010d6:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    800010d8:	8ff9                	and	a5,a5,a4
    800010da:	cb89                	beqz	a5,800010ec <free_page+0x28>
        panic("free_page: not page aligned");
    800010dc:	00003517          	auipc	a0,0x3
    800010e0:	4ec50513          	add	a0,a0,1260 # 800045c8 <etext+0x5c8>
    800010e4:	00000097          	auipc	ra,0x0
    800010e8:	d3c080e7          	jalr	-708(ra) # 80000e20 <panic>
    
    if((char*)pa < end || (uint64)pa >= PHYSTOP)
    800010ec:	fd843703          	ld	a4,-40(s0)
    800010f0:	0000b797          	auipc	a5,0xb
    800010f4:	f2078793          	add	a5,a5,-224 # 8000c010 <bss_end>
    800010f8:	00f76863          	bltu	a4,a5,80001108 <free_page+0x44>
    800010fc:	fd843703          	ld	a4,-40(s0)
    80001100:	47c5                	li	a5,17
    80001102:	07ee                	sll	a5,a5,0x1b
    80001104:	00f76a63          	bltu	a4,a5,80001118 <free_page+0x54>
        panic("free_page: invalid address");
    80001108:	00003517          	auipc	a0,0x3
    8000110c:	4e050513          	add	a0,a0,1248 # 800045e8 <etext+0x5e8>
    80001110:	00000097          	auipc	ra,0x0
    80001114:	d10080e7          	jalr	-752(ra) # 80000e20 <panic>

    // 检查double free
    uint32 *magic_ptr = (uint32*)pa;
    80001118:	fd843783          	ld	a5,-40(s0)
    8000111c:	fef43423          	sd	a5,-24(s0)
    if(*magic_ptr == FREE_MAGIC) {
    80001120:	fe843783          	ld	a5,-24(s0)
    80001124:	439c                	lw	a5,0(a5)
    80001126:	873e                	mv	a4,a5
    80001128:	deadc7b7          	lui	a5,0xdeadc
    8000112c:	eef78793          	add	a5,a5,-273 # ffffffffdeadbeef <bss_end+0xffffffff5eacfedf>
    80001130:	00f71a63          	bne	a4,a5,80001144 <free_page+0x80>
        panic("free_page: double free detected");
    80001134:	00003517          	auipc	a0,0x3
    80001138:	4d450513          	add	a0,a0,1236 # 80004608 <etext+0x608>
    8000113c:	00000097          	auipc	ra,0x0
    80001140:	ce4080e7          	jalr	-796(ra) # 80000e20 <panic>
    }
    
    // 填充魔数
    *magic_ptr = FREE_MAGIC;
    80001144:	fe843783          	ld	a5,-24(s0)
    80001148:	deadc737          	lui	a4,0xdeadc
    8000114c:	eef70713          	add	a4,a4,-273 # ffffffffdeadbeef <bss_end+0xffffffff5eacfedf>
    80001150:	c398                	sw	a4,0(a5)
    
    // 其余部分填1
    memset((char*)pa + 4, 1, PGSIZE - 4);
    80001152:	fd843783          	ld	a5,-40(s0)
    80001156:	00478713          	add	a4,a5,4
    8000115a:	6785                	lui	a5,0x1
    8000115c:	ffc78613          	add	a2,a5,-4 # ffc <_entry-0x7ffff004>
    80001160:	4585                	li	a1,1
    80001162:	853a                	mv	a0,a4
    80001164:	00000097          	auipc	ra,0x0
    80001168:	d92080e7          	jalr	-622(ra) # 80000ef6 <memset>
    
    // 插入空闲链表头部
    r = (struct run*)pa;
    8000116c:	fd843783          	ld	a5,-40(s0)
    80001170:	fef43023          	sd	a5,-32(s0)
    r->next = kmem.freelist;
    80001174:	00008797          	auipc	a5,0x8
    80001178:	eb478793          	add	a5,a5,-332 # 80009028 <kmem>
    8000117c:	6398                	ld	a4,0(a5)
    8000117e:	fe043783          	ld	a5,-32(s0)
    80001182:	e398                	sd	a4,0(a5)
    kmem.freelist = r;
    80001184:	00008797          	auipc	a5,0x8
    80001188:	ea478793          	add	a5,a5,-348 # 80009028 <kmem>
    8000118c:	fe043703          	ld	a4,-32(s0)
    80001190:	e398                	sd	a4,0(a5)
    kmem.free_pages++;
    80001192:	00008797          	auipc	a5,0x8
    80001196:	e9678793          	add	a5,a5,-362 # 80009028 <kmem>
    8000119a:	6b9c                	ld	a5,16(a5)
    8000119c:	00178713          	add	a4,a5,1
    800011a0:	00008797          	auipc	a5,0x8
    800011a4:	e8878793          	add	a5,a5,-376 # 80009028 <kmem>
    800011a8:	eb98                	sd	a4,16(a5)
}
    800011aa:	0001                	nop
    800011ac:	70a2                	ld	ra,40(sp)
    800011ae:	7402                	ld	s0,32(sp)
    800011b0:	6145                	add	sp,sp,48
    800011b2:	8082                	ret

00000000800011b4 <print_mem_info>:

// ==================== 内存使用信息统计 ====================

void print_mem_info(void) {
    800011b4:	1141                	add	sp,sp,-16
    800011b6:	e406                	sd	ra,8(sp)
    800011b8:	e022                	sd	s0,0(sp)
    800011ba:	0800                	add	s0,sp,16
    printf("Memory Info:\n");
    800011bc:	00003517          	auipc	a0,0x3
    800011c0:	46c50513          	add	a0,a0,1132 # 80004628 <etext+0x628>
    800011c4:	00000097          	auipc	ra,0x0
    800011c8:	962080e7          	jalr	-1694(ra) # 80000b26 <printf>
    printf("  Total pages: %d (%d KB)\n", 
           (int)kmem.total_pages, (int)(kmem.total_pages * PGSIZE) / 1024);
    800011cc:	00008797          	auipc	a5,0x8
    800011d0:	e5c78793          	add	a5,a5,-420 # 80009028 <kmem>
    800011d4:	679c                	ld	a5,8(a5)
    printf("  Total pages: %d (%d KB)\n", 
    800011d6:	0007869b          	sext.w	a3,a5
           (int)kmem.total_pages, (int)(kmem.total_pages * PGSIZE) / 1024);
    800011da:	00008797          	auipc	a5,0x8
    800011de:	e4e78793          	add	a5,a5,-434 # 80009028 <kmem>
    800011e2:	679c                	ld	a5,8(a5)
    800011e4:	2781                	sext.w	a5,a5
    800011e6:	00c7979b          	sllw	a5,a5,0xc
    800011ea:	2781                	sext.w	a5,a5
    800011ec:	2781                	sext.w	a5,a5
    printf("  Total pages: %d (%d KB)\n", 
    800011ee:	41f7d71b          	sraw	a4,a5,0x1f
    800011f2:	0167571b          	srlw	a4,a4,0x16
    800011f6:	9fb9                	addw	a5,a5,a4
    800011f8:	40a7d79b          	sraw	a5,a5,0xa
    800011fc:	2781                	sext.w	a5,a5
    800011fe:	863e                	mv	a2,a5
    80001200:	85b6                	mv	a1,a3
    80001202:	00003517          	auipc	a0,0x3
    80001206:	43650513          	add	a0,a0,1078 # 80004638 <etext+0x638>
    8000120a:	00000097          	auipc	ra,0x0
    8000120e:	91c080e7          	jalr	-1764(ra) # 80000b26 <printf>
    printf("  Free pages:  %d (%d KB)\n", 
           (int)kmem.free_pages, (int)(kmem.free_pages * PGSIZE) / 1024);
    80001212:	00008797          	auipc	a5,0x8
    80001216:	e1678793          	add	a5,a5,-490 # 80009028 <kmem>
    8000121a:	6b9c                	ld	a5,16(a5)
    printf("  Free pages:  %d (%d KB)\n", 
    8000121c:	0007869b          	sext.w	a3,a5
           (int)kmem.free_pages, (int)(kmem.free_pages * PGSIZE) / 1024);
    80001220:	00008797          	auipc	a5,0x8
    80001224:	e0878793          	add	a5,a5,-504 # 80009028 <kmem>
    80001228:	6b9c                	ld	a5,16(a5)
    8000122a:	2781                	sext.w	a5,a5
    8000122c:	00c7979b          	sllw	a5,a5,0xc
    80001230:	2781                	sext.w	a5,a5
    80001232:	2781                	sext.w	a5,a5
    printf("  Free pages:  %d (%d KB)\n", 
    80001234:	41f7d71b          	sraw	a4,a5,0x1f
    80001238:	0167571b          	srlw	a4,a4,0x16
    8000123c:	9fb9                	addw	a5,a5,a4
    8000123e:	40a7d79b          	sraw	a5,a5,0xa
    80001242:	2781                	sext.w	a5,a5
    80001244:	863e                	mv	a2,a5
    80001246:	85b6                	mv	a1,a3
    80001248:	00003517          	auipc	a0,0x3
    8000124c:	41050513          	add	a0,a0,1040 # 80004658 <etext+0x658>
    80001250:	00000097          	auipc	ra,0x0
    80001254:	8d6080e7          	jalr	-1834(ra) # 80000b26 <printf>
    printf("  Used pages:  %d (%d KB)\n", 
           (int)(kmem.total_pages - kmem.free_pages), 
    80001258:	00008797          	auipc	a5,0x8
    8000125c:	dd078793          	add	a5,a5,-560 # 80009028 <kmem>
    80001260:	679c                	ld	a5,8(a5)
    80001262:	0007871b          	sext.w	a4,a5
    80001266:	00008797          	auipc	a5,0x8
    8000126a:	dc278793          	add	a5,a5,-574 # 80009028 <kmem>
    8000126e:	6b9c                	ld	a5,16(a5)
    80001270:	2781                	sext.w	a5,a5
    80001272:	40f707bb          	subw	a5,a4,a5
    80001276:	2781                	sext.w	a5,a5
    printf("  Used pages:  %d (%d KB)\n", 
    80001278:	0007869b          	sext.w	a3,a5
           (int)((kmem.total_pages - kmem.free_pages) * PGSIZE) / 1024);
    8000127c:	00008797          	auipc	a5,0x8
    80001280:	dac78793          	add	a5,a5,-596 # 80009028 <kmem>
    80001284:	6798                	ld	a4,8(a5)
    80001286:	00008797          	auipc	a5,0x8
    8000128a:	da278793          	add	a5,a5,-606 # 80009028 <kmem>
    8000128e:	6b9c                	ld	a5,16(a5)
    80001290:	40f707b3          	sub	a5,a4,a5
    80001294:	2781                	sext.w	a5,a5
    80001296:	00c7979b          	sllw	a5,a5,0xc
    8000129a:	2781                	sext.w	a5,a5
    8000129c:	2781                	sext.w	a5,a5
    printf("  Used pages:  %d (%d KB)\n", 
    8000129e:	41f7d71b          	sraw	a4,a5,0x1f
    800012a2:	0167571b          	srlw	a4,a4,0x16
    800012a6:	9fb9                	addw	a5,a5,a4
    800012a8:	40a7d79b          	sraw	a5,a5,0xa
    800012ac:	2781                	sext.w	a5,a5
    800012ae:	863e                	mv	a2,a5
    800012b0:	85b6                	mv	a1,a3
    800012b2:	00003517          	auipc	a0,0x3
    800012b6:	3c650513          	add	a0,a0,966 # 80004678 <etext+0x678>
    800012ba:	00000097          	auipc	ra,0x0
    800012be:	86c080e7          	jalr	-1940(ra) # 80000b26 <printf>
    800012c2:	0001                	nop
    800012c4:	60a2                	ld	ra,8(sp)
    800012c6:	6402                	ld	s0,0(sp)
    800012c8:	0141                	add	sp,sp,16
    800012ca:	8082                	ret

00000000800012cc <w_satp>:
    
    // 从第2级开始遍历（Sv39三级页表：2->1->0）
    for(int level = 2; level > 0; level--) {
        pte_t *pte = &pagetable[PX(level, va)];
        
        if(*pte & PTE_V) {
    800012cc:	1101                	add	sp,sp,-32
    800012ce:	ec22                	sd	s0,24(sp)
    800012d0:	1000                	add	s0,sp,32
    800012d2:	fea43423          	sd	a0,-24(s0)
            pagetable = (pagetable_t)PTE2PA(*pte);
    800012d6:	fe843783          	ld	a5,-24(s0)
    800012da:	18079073          	csrw	satp,a5
        } else {
    800012de:	0001                	nop
    800012e0:	6462                	ld	s0,24(sp)
    800012e2:	6105                	add	sp,sp,32
    800012e4:	8082                	ret

00000000800012e6 <sfence_vma>:
            return 0;  // 页表项无效
        }
    }
    800012e6:	1141                	add	sp,sp,-16
    800012e8:	e422                	sd	s0,8(sp)
    800012ea:	0800                	add	s0,sp,16
    
    800012ec:	12000073          	sfence.vma
    // 返回最后一级的PTE指针
    800012f0:	0001                	nop
    800012f2:	6422                	ld	s0,8(sp)
    800012f4:	0141                	add	sp,sp,16
    800012f6:	8082                	ret

00000000800012f8 <create_pagetable>:
pagetable_t create_pagetable(void) {
    800012f8:	1101                	add	sp,sp,-32
    800012fa:	ec06                	sd	ra,24(sp)
    800012fc:	e822                	sd	s0,16(sp)
    800012fe:	1000                	add	s0,sp,32
    pagetable_t pagetable = (pagetable_t)alloc_page();
    80001300:	00000097          	auipc	ra,0x0
    80001304:	d62080e7          	jalr	-670(ra) # 80001062 <alloc_page>
    80001308:	fea43423          	sd	a0,-24(s0)
    if(pagetable == 0) {
    8000130c:	fe843783          	ld	a5,-24(s0)
    80001310:	e399                	bnez	a5,80001316 <create_pagetable+0x1e>
        return 0;
    80001312:	4781                	li	a5,0
    80001314:	a019                	j	8000131a <create_pagetable+0x22>
    return pagetable;
    80001316:	fe843783          	ld	a5,-24(s0)
}
    8000131a:	853e                	mv	a0,a5
    8000131c:	60e2                	ld	ra,24(sp)
    8000131e:	6442                	ld	s0,16(sp)
    80001320:	6105                	add	sp,sp,32
    80001322:	8082                	ret

0000000080001324 <freewalk>:
static void freewalk(pagetable_t pagetable) {
    80001324:	7139                	add	sp,sp,-64
    80001326:	fc06                	sd	ra,56(sp)
    80001328:	f822                	sd	s0,48(sp)
    8000132a:	0080                	add	s0,sp,64
    8000132c:	fca43423          	sd	a0,-56(s0)
    for(int i = 0; i < 512; i++) {
    80001330:	fe042623          	sw	zero,-20(s0)
    80001334:	a8a1                	j	8000138c <freewalk+0x68>
        pte_t pte = pagetable[i];
    80001336:	fec42783          	lw	a5,-20(s0)
    8000133a:	078e                	sll	a5,a5,0x3
    8000133c:	fc843703          	ld	a4,-56(s0)
    80001340:	97ba                	add	a5,a5,a4
    80001342:	639c                	ld	a5,0(a5)
    80001344:	fef43023          	sd	a5,-32(s0)
        if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0) {
    80001348:	fe043783          	ld	a5,-32(s0)
    8000134c:	8b85                	and	a5,a5,1
    8000134e:	cb95                	beqz	a5,80001382 <freewalk+0x5e>
    80001350:	fe043783          	ld	a5,-32(s0)
    80001354:	8bb9                	and	a5,a5,14
    80001356:	e795                	bnez	a5,80001382 <freewalk+0x5e>
            uint64 child = PTE2PA(pte);  // 修正：使用PTE2PA
    80001358:	fe043783          	ld	a5,-32(s0)
    8000135c:	83a9                	srl	a5,a5,0xa
    8000135e:	07b2                	sll	a5,a5,0xc
    80001360:	fcf43c23          	sd	a5,-40(s0)
            freewalk((pagetable_t)child);
    80001364:	fd843783          	ld	a5,-40(s0)
    80001368:	853e                	mv	a0,a5
    8000136a:	00000097          	auipc	ra,0x0
    8000136e:	fba080e7          	jalr	-70(ra) # 80001324 <freewalk>
            pagetable[i] = 0;
    80001372:	fec42783          	lw	a5,-20(s0)
    80001376:	078e                	sll	a5,a5,0x3
    80001378:	fc843703          	ld	a4,-56(s0)
    8000137c:	97ba                	add	a5,a5,a4
    8000137e:	0007b023          	sd	zero,0(a5)
    for(int i = 0; i < 512; i++) {
    80001382:	fec42783          	lw	a5,-20(s0)
    80001386:	2785                	addw	a5,a5,1
    80001388:	fef42623          	sw	a5,-20(s0)
    8000138c:	fec42783          	lw	a5,-20(s0)
    80001390:	0007871b          	sext.w	a4,a5
    80001394:	1ff00793          	li	a5,511
    80001398:	f8e7dfe3          	bge	a5,a4,80001336 <freewalk+0x12>
    free_page((void*)pagetable);
    8000139c:	fc843503          	ld	a0,-56(s0)
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	d24080e7          	jalr	-732(ra) # 800010c4 <free_page>
}
    800013a8:	0001                	nop
    800013aa:	70e2                	ld	ra,56(sp)
    800013ac:	7442                	ld	s0,48(sp)
    800013ae:	6121                	add	sp,sp,64
    800013b0:	8082                	ret

00000000800013b2 <destroy_pagetable>:
void destroy_pagetable(pagetable_t pagetable) {
    800013b2:	1101                	add	sp,sp,-32
    800013b4:	ec06                	sd	ra,24(sp)
    800013b6:	e822                	sd	s0,16(sp)
    800013b8:	1000                	add	s0,sp,32
    800013ba:	fea43423          	sd	a0,-24(s0)
    if(pagetable == 0) {
    800013be:	fe843783          	ld	a5,-24(s0)
    800013c2:	cb81                	beqz	a5,800013d2 <destroy_pagetable+0x20>
    freewalk(pagetable);
    800013c4:	fe843503          	ld	a0,-24(s0)
    800013c8:	00000097          	auipc	ra,0x0
    800013cc:	f5c080e7          	jalr	-164(ra) # 80001324 <freewalk>
    800013d0:	a011                	j	800013d4 <destroy_pagetable+0x22>
        return;
    800013d2:	0001                	nop
}
    800013d4:	60e2                	ld	ra,24(sp)
    800013d6:	6442                	ld	s0,16(sp)
    800013d8:	6105                	add	sp,sp,32
    800013da:	8082                	ret

00000000800013dc <walk_lookup>:
pte_t* walk_lookup(pagetable_t pagetable, uint64 va) {
    800013dc:	7179                	add	sp,sp,-48
    800013de:	f406                	sd	ra,40(sp)
    800013e0:	f022                	sd	s0,32(sp)
    800013e2:	1800                	add	s0,sp,48
    800013e4:	fca43c23          	sd	a0,-40(s0)
    800013e8:	fcb43823          	sd	a1,-48(s0)
    if(va >= MAXVA) {
    800013ec:	fd043703          	ld	a4,-48(s0)
    800013f0:	57fd                	li	a5,-1
    800013f2:	83e9                	srl	a5,a5,0x1a
    800013f4:	00e7fa63          	bgeu	a5,a4,80001408 <walk_lookup+0x2c>
        panic("walk_lookup: va too large");
    800013f8:	00003517          	auipc	a0,0x3
    800013fc:	2a050513          	add	a0,a0,672 # 80004698 <etext+0x698>
    80001400:	00000097          	auipc	ra,0x0
    80001404:	a20080e7          	jalr	-1504(ra) # 80000e20 <panic>
    for(int level = 2; level > 0; level--) {
    80001408:	4789                	li	a5,2
    8000140a:	fef42623          	sw	a5,-20(s0)
    8000140e:	a8a1                	j	80001466 <walk_lookup+0x8a>
        pte_t *pte = &pagetable[PX(level, va)];
    80001410:	fec42783          	lw	a5,-20(s0)
    80001414:	873e                	mv	a4,a5
    80001416:	87ba                	mv	a5,a4
    80001418:	0037979b          	sllw	a5,a5,0x3
    8000141c:	9fb9                	addw	a5,a5,a4
    8000141e:	2781                	sext.w	a5,a5
    80001420:	27b1                	addw	a5,a5,12
    80001422:	2781                	sext.w	a5,a5
    80001424:	873e                	mv	a4,a5
    80001426:	fd043783          	ld	a5,-48(s0)
    8000142a:	00e7d7b3          	srl	a5,a5,a4
    8000142e:	1ff7f793          	and	a5,a5,511
    80001432:	078e                	sll	a5,a5,0x3
    80001434:	fd843703          	ld	a4,-40(s0)
    80001438:	97ba                	add	a5,a5,a4
    8000143a:	fef43023          	sd	a5,-32(s0)
        if(*pte & PTE_V) {
    8000143e:	fe043783          	ld	a5,-32(s0)
    80001442:	639c                	ld	a5,0(a5)
    80001444:	8b85                	and	a5,a5,1
    80001446:	cb89                	beqz	a5,80001458 <walk_lookup+0x7c>
            pagetable = (pagetable_t)PTE2PA(*pte);
    80001448:	fe043783          	ld	a5,-32(s0)
    8000144c:	639c                	ld	a5,0(a5)
    8000144e:	83a9                	srl	a5,a5,0xa
    80001450:	07b2                	sll	a5,a5,0xc
    80001452:	fcf43c23          	sd	a5,-40(s0)
    80001456:	a019                	j	8000145c <walk_lookup+0x80>
            return 0;  // 页表项无效
    80001458:	4781                	li	a5,0
    8000145a:	a025                	j	80001482 <walk_lookup+0xa6>
    for(int level = 2; level > 0; level--) {
    8000145c:	fec42783          	lw	a5,-20(s0)
    80001460:	37fd                	addw	a5,a5,-1
    80001462:	fef42623          	sw	a5,-20(s0)
    80001466:	fec42783          	lw	a5,-20(s0)
    8000146a:	2781                	sext.w	a5,a5
    8000146c:	faf042e3          	bgtz	a5,80001410 <walk_lookup+0x34>
    return &pagetable[PX(0, va)];
    80001470:	fd043783          	ld	a5,-48(s0)
    80001474:	83b1                	srl	a5,a5,0xc
    80001476:	1ff7f793          	and	a5,a5,511
    8000147a:	078e                	sll	a5,a5,0x3
    8000147c:	fd843703          	ld	a4,-40(s0)
    80001480:	97ba                	add	a5,a5,a4
}
    80001482:	853e                	mv	a0,a5
    80001484:	70a2                	ld	ra,40(sp)
    80001486:	7402                	ld	s0,32(sp)
    80001488:	6145                	add	sp,sp,48
    8000148a:	8082                	ret

000000008000148c <walk_create>:

// 查找或创建虚拟地址对应的PTE
pte_t* walk_create(pagetable_t pagetable, uint64 va) {
    8000148c:	7179                	add	sp,sp,-48
    8000148e:	f406                	sd	ra,40(sp)
    80001490:	f022                	sd	s0,32(sp)
    80001492:	1800                	add	s0,sp,48
    80001494:	fca43c23          	sd	a0,-40(s0)
    80001498:	fcb43823          	sd	a1,-48(s0)
    if(va >= MAXVA) {
    8000149c:	fd043703          	ld	a4,-48(s0)
    800014a0:	57fd                	li	a5,-1
    800014a2:	83e9                	srl	a5,a5,0x1a
    800014a4:	00e7fa63          	bgeu	a5,a4,800014b8 <walk_create+0x2c>
        panic("walk_create: va too large");
    800014a8:	00003517          	auipc	a0,0x3
    800014ac:	21050513          	add	a0,a0,528 # 800046b8 <etext+0x6b8>
    800014b0:	00000097          	auipc	ra,0x0
    800014b4:	970080e7          	jalr	-1680(ra) # 80000e20 <panic>
    }
    
    // 从第2级开始遍历
    for(int level = 2; level > 0; level--) {
    800014b8:	4789                	li	a5,2
    800014ba:	fef42623          	sw	a5,-20(s0)
    800014be:	a8b5                	j	8000153a <walk_create+0xae>
        pte_t *pte = &pagetable[PX(level, va)];
    800014c0:	fec42783          	lw	a5,-20(s0)
    800014c4:	873e                	mv	a4,a5
    800014c6:	87ba                	mv	a5,a4
    800014c8:	0037979b          	sllw	a5,a5,0x3
    800014cc:	9fb9                	addw	a5,a5,a4
    800014ce:	2781                	sext.w	a5,a5
    800014d0:	27b1                	addw	a5,a5,12
    800014d2:	2781                	sext.w	a5,a5
    800014d4:	873e                	mv	a4,a5
    800014d6:	fd043783          	ld	a5,-48(s0)
    800014da:	00e7d7b3          	srl	a5,a5,a4
    800014de:	1ff7f793          	and	a5,a5,511
    800014e2:	078e                	sll	a5,a5,0x3
    800014e4:	fd843703          	ld	a4,-40(s0)
    800014e8:	97ba                	add	a5,a5,a4
    800014ea:	fef43023          	sd	a5,-32(s0)
        
        if(*pte & PTE_V) {
    800014ee:	fe043783          	ld	a5,-32(s0)
    800014f2:	639c                	ld	a5,0(a5)
    800014f4:	8b85                	and	a5,a5,1
    800014f6:	cb89                	beqz	a5,80001508 <walk_create+0x7c>
            pagetable = (pagetable_t)PTE2PA(*pte);
    800014f8:	fe043783          	ld	a5,-32(s0)
    800014fc:	639c                	ld	a5,0(a5)
    800014fe:	83a9                	srl	a5,a5,0xa
    80001500:	07b2                	sll	a5,a5,0xc
    80001502:	fcf43c23          	sd	a5,-40(s0)
    80001506:	a02d                	j	80001530 <walk_create+0xa4>
        } else {
            // 需要创建新的页表
            pagetable = create_pagetable();
    80001508:	00000097          	auipc	ra,0x0
    8000150c:	df0080e7          	jalr	-528(ra) # 800012f8 <create_pagetable>
    80001510:	fca43c23          	sd	a0,-40(s0)
            if(pagetable == 0) {
    80001514:	fd843783          	ld	a5,-40(s0)
    80001518:	e399                	bnez	a5,8000151e <walk_create+0x92>
                return 0;
    8000151a:	4781                	li	a5,0
    8000151c:	a82d                	j	80001556 <walk_create+0xca>
            }
            *pte = PA2PTE(pagetable) | PTE_V;
    8000151e:	fd843783          	ld	a5,-40(s0)
    80001522:	83b1                	srl	a5,a5,0xc
    80001524:	07aa                	sll	a5,a5,0xa
    80001526:	0017e713          	or	a4,a5,1
    8000152a:	fe043783          	ld	a5,-32(s0)
    8000152e:	e398                	sd	a4,0(a5)
    for(int level = 2; level > 0; level--) {
    80001530:	fec42783          	lw	a5,-20(s0)
    80001534:	37fd                	addw	a5,a5,-1
    80001536:	fef42623          	sw	a5,-20(s0)
    8000153a:	fec42783          	lw	a5,-20(s0)
    8000153e:	2781                	sext.w	a5,a5
    80001540:	f8f040e3          	bgtz	a5,800014c0 <walk_create+0x34>
        }
    }
    
    // 返回最后一级的PTE指针
    return &pagetable[PX(0, va)];
    80001544:	fd043783          	ld	a5,-48(s0)
    80001548:	83b1                	srl	a5,a5,0xc
    8000154a:	1ff7f793          	and	a5,a5,511
    8000154e:	078e                	sll	a5,a5,0x3
    80001550:	fd843703          	ld	a4,-40(s0)
    80001554:	97ba                	add	a5,a5,a4
}
    80001556:	853e                	mv	a0,a5
    80001558:	70a2                	ld	ra,40(sp)
    8000155a:	7402                	ld	s0,32(sp)
    8000155c:	6145                	add	sp,sp,48
    8000155e:	8082                	ret

0000000080001560 <map_page>:

// ==================== 页表映射 ====================

// 映射单个页面
int map_page(pagetable_t pagetable, uint64 va, uint64 pa, int perm) {
    80001560:	7139                	add	sp,sp,-64
    80001562:	fc06                	sd	ra,56(sp)
    80001564:	f822                	sd	s0,48(sp)
    80001566:	0080                	add	s0,sp,64
    80001568:	fca43c23          	sd	a0,-40(s0)
    8000156c:	fcb43823          	sd	a1,-48(s0)
    80001570:	fcc43423          	sd	a2,-56(s0)
    80001574:	87b6                	mv	a5,a3
    80001576:	fcf42223          	sw	a5,-60(s0)
    pte_t *pte;
    
    if((va % PGSIZE) != 0) {
    8000157a:	fd043703          	ld	a4,-48(s0)
    8000157e:	6785                	lui	a5,0x1
    80001580:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001582:	8ff9                	and	a5,a5,a4
    80001584:	cb89                	beqz	a5,80001596 <map_page+0x36>
        panic("map_page: va not aligned");
    80001586:	00003517          	auipc	a0,0x3
    8000158a:	15250513          	add	a0,a0,338 # 800046d8 <etext+0x6d8>
    8000158e:	00000097          	auipc	ra,0x0
    80001592:	892080e7          	jalr	-1902(ra) # 80000e20 <panic>
    }
    
    if((pa % PGSIZE) != 0) {
    80001596:	fc843703          	ld	a4,-56(s0)
    8000159a:	6785                	lui	a5,0x1
    8000159c:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000159e:	8ff9                	and	a5,a5,a4
    800015a0:	cb89                	beqz	a5,800015b2 <map_page+0x52>
        panic("map_page: pa not aligned");
    800015a2:	00003517          	auipc	a0,0x3
    800015a6:	15650513          	add	a0,a0,342 # 800046f8 <etext+0x6f8>
    800015aa:	00000097          	auipc	ra,0x0
    800015ae:	876080e7          	jalr	-1930(ra) # 80000e20 <panic>
    }
    
    // 获取或创建PTE
    pte = walk_create(pagetable, va);
    800015b2:	fd043583          	ld	a1,-48(s0)
    800015b6:	fd843503          	ld	a0,-40(s0)
    800015ba:	00000097          	auipc	ra,0x0
    800015be:	ed2080e7          	jalr	-302(ra) # 8000148c <walk_create>
    800015c2:	fea43423          	sd	a0,-24(s0)
    if(pte == 0) {
    800015c6:	fe843783          	ld	a5,-24(s0)
    800015ca:	e399                	bnez	a5,800015d0 <map_page+0x70>
        return -1;
    800015cc:	57fd                	li	a5,-1
    800015ce:	a825                	j	80001606 <map_page+0xa6>
    }
    
    // 检查是否已映射
    if(*pte & PTE_V) {
    800015d0:	fe843783          	ld	a5,-24(s0)
    800015d4:	639c                	ld	a5,0(a5)
    800015d6:	8b85                	and	a5,a5,1
    800015d8:	cb89                	beqz	a5,800015ea <map_page+0x8a>
        panic("map_page: remap");
    800015da:	00003517          	auipc	a0,0x3
    800015de:	13e50513          	add	a0,a0,318 # 80004718 <etext+0x718>
    800015e2:	00000097          	auipc	ra,0x0
    800015e6:	83e080e7          	jalr	-1986(ra) # 80000e20 <panic>
    }
    
    // 设置PTE
    *pte = PA2PTE(pa) | perm | PTE_V;
    800015ea:	fc843783          	ld	a5,-56(s0)
    800015ee:	83b1                	srl	a5,a5,0xc
    800015f0:	00a79713          	sll	a4,a5,0xa
    800015f4:	fc442783          	lw	a5,-60(s0)
    800015f8:	8fd9                	or	a5,a5,a4
    800015fa:	0017e713          	or	a4,a5,1
    800015fe:	fe843783          	ld	a5,-24(s0)
    80001602:	e398                	sd	a4,0(a5)
    
    return 0;
    80001604:	4781                	li	a5,0
}
    80001606:	853e                	mv	a0,a5
    80001608:	70e2                	ld	ra,56(sp)
    8000160a:	7442                	ld	s0,48(sp)
    8000160c:	6121                	add	sp,sp,64
    8000160e:	8082                	ret

0000000080001610 <map_region>:

// 映射一段内存区域
// 映射一段内存区域
int map_region(pagetable_t pagetable, uint64 va, uint64 pa, uint64 size, int perm) {
    80001610:	715d                	add	sp,sp,-80
    80001612:	e486                	sd	ra,72(sp)
    80001614:	e0a2                	sd	s0,64(sp)
    80001616:	0880                	add	s0,sp,80
    80001618:	fca43c23          	sd	a0,-40(s0)
    8000161c:	fcb43823          	sd	a1,-48(s0)
    80001620:	fcc43423          	sd	a2,-56(s0)
    80001624:	fcd43023          	sd	a3,-64(s0)
    80001628:	87ba                	mv	a5,a4
    8000162a:	faf42e23          	sw	a5,-68(s0)
    uint64 a, last;
    
    if(size == 0) {
    8000162e:	fc043783          	ld	a5,-64(s0)
    80001632:	eb89                	bnez	a5,80001644 <map_region+0x34>
        panic("map_region: size is zero");
    80001634:	00003517          	auipc	a0,0x3
    80001638:	0f450513          	add	a0,a0,244 # 80004728 <etext+0x728>
    8000163c:	fffff097          	auipc	ra,0xfffff
    80001640:	7e4080e7          	jalr	2020(ra) # 80000e20 <panic>
    }
    
    a = PGROUNDDOWN(va);
    80001644:	fd043703          	ld	a4,-48(s0)
    80001648:	77fd                	lui	a5,0xfffff
    8000164a:	8ff9                	and	a5,a5,a4
    8000164c:	fef43423          	sd	a5,-24(s0)
    last = PGROUNDDOWN(va + size - 1);
    80001650:	fd043703          	ld	a4,-48(s0)
    80001654:	fc043783          	ld	a5,-64(s0)
    80001658:	97ba                	add	a5,a5,a4
    8000165a:	fff78713          	add	a4,a5,-1 # ffffffffffffefff <bss_end+0xffffffff7fff2fef>
    8000165e:	77fd                	lui	a5,0xfffff
    80001660:	8ff9                	and	a5,a5,a4
    80001662:	fef43023          	sd	a5,-32(s0)
    
    for(;;) {
        if(map_page(pagetable, a, pa, perm) != 0) {
    80001666:	fbc42783          	lw	a5,-68(s0)
    8000166a:	86be                	mv	a3,a5
    8000166c:	fc843603          	ld	a2,-56(s0)
    80001670:	fe843583          	ld	a1,-24(s0)
    80001674:	fd843503          	ld	a0,-40(s0)
    80001678:	00000097          	auipc	ra,0x0
    8000167c:	ee8080e7          	jalr	-280(ra) # 80001560 <map_page>
    80001680:	87aa                	mv	a5,a0
    80001682:	c399                	beqz	a5,80001688 <map_region+0x78>
            return -1;
    80001684:	57fd                	li	a5,-1
    80001686:	a035                	j	800016b2 <map_region+0xa2>
        }
        
        if(a == last) {
    80001688:	fe843703          	ld	a4,-24(s0)
    8000168c:	fe043783          	ld	a5,-32(s0)
    80001690:	00f70f63          	beq	a4,a5,800016ae <map_region+0x9e>
            break;
        }
        
        a += PGSIZE;
    80001694:	fe843703          	ld	a4,-24(s0)
    80001698:	6785                	lui	a5,0x1
    8000169a:	97ba                	add	a5,a5,a4
    8000169c:	fef43423          	sd	a5,-24(s0)
        pa += PGSIZE;
    800016a0:	fc843703          	ld	a4,-56(s0)
    800016a4:	6785                	lui	a5,0x1
    800016a6:	97ba                	add	a5,a5,a4
    800016a8:	fcf43423          	sd	a5,-56(s0)
        if(map_page(pagetable, a, pa, perm) != 0) {
    800016ac:	bf6d                	j	80001666 <map_region+0x56>
            break;
    800016ae:	0001                	nop
    }
    
    return 0;
    800016b0:	4781                	li	a5,0
}
    800016b2:	853e                	mv	a0,a5
    800016b4:	60a6                	ld	ra,72(sp)
    800016b6:	6406                	ld	s0,64(sp)
    800016b8:	6161                	add	sp,sp,80
    800016ba:	8082                	ret

00000000800016bc <kvminit>:

// ==================== 内核页表初始化 ====================

void kvminit(void) {
    800016bc:	1141                	add	sp,sp,-16
    800016be:	e406                	sd	ra,8(sp)
    800016c0:	e022                	sd	s0,0(sp)
    800016c2:	0800                	add	s0,sp,16
    printf("Setting up kernel page table...\n");
    800016c4:	00003517          	auipc	a0,0x3
    800016c8:	08450513          	add	a0,a0,132 # 80004748 <etext+0x748>
    800016cc:	fffff097          	auipc	ra,0xfffff
    800016d0:	45a080e7          	jalr	1114(ra) # 80000b26 <printf>
    printf("This will take 30-60 seconds, please wait...\n");
    800016d4:	00003517          	auipc	a0,0x3
    800016d8:	09c50513          	add	a0,a0,156 # 80004770 <etext+0x770>
    800016dc:	fffff097          	auipc	ra,0xfffff
    800016e0:	44a080e7          	jalr	1098(ra) # 80000b26 <printf>
    
    // 创建内核页表
    kernel_pagetable = create_pagetable();
    800016e4:	00000097          	auipc	ra,0x0
    800016e8:	c14080e7          	jalr	-1004(ra) # 800012f8 <create_pagetable>
    800016ec:	872a                	mv	a4,a0
    800016ee:	00005797          	auipc	a5,0x5
    800016f2:	91a78793          	add	a5,a5,-1766 # 80006008 <kernel_pagetable>
    800016f6:	e398                	sd	a4,0(a5)
    if(kernel_pagetable == 0) {
    800016f8:	00005797          	auipc	a5,0x5
    800016fc:	91078793          	add	a5,a5,-1776 # 80006008 <kernel_pagetable>
    80001700:	639c                	ld	a5,0(a5)
    80001702:	eb89                	bnez	a5,80001714 <kvminit+0x58>
        panic("kvminit: failed to create page table");
    80001704:	00003517          	auipc	a0,0x3
    80001708:	09c50513          	add	a0,a0,156 # 800047a0 <etext+0x7a0>
    8000170c:	fffff097          	auipc	ra,0xfffff
    80001710:	714080e7          	jalr	1812(ra) # 80000e20 <panic>
    // 映射整个物理内存：从 KERNBASE 到 PHYSTOP
    // 使用恒等映射：虚拟地址 = 物理地址
    // 代码段：RX，数据段：RW
    
    // 1. 映射内核代码段（RX）
    if(map_region(kernel_pagetable, KERNBASE, KERNBASE,
    80001714:	00005797          	auipc	a5,0x5
    80001718:	8f478793          	add	a5,a5,-1804 # 80006008 <kernel_pagetable>
    8000171c:	6388                	ld	a0,0(a5)
                  (uint64)etext - KERNBASE, PTE_R | PTE_X) != 0)
    8000171e:	00003717          	auipc	a4,0x3
    80001722:	8e270713          	add	a4,a4,-1822 # 80004000 <etext>
    if(map_region(kernel_pagetable, KERNBASE, KERNBASE,
    80001726:	800007b7          	lui	a5,0x80000
    8000172a:	97ba                	add	a5,a5,a4
    8000172c:	4729                	li	a4,10
    8000172e:	86be                	mv	a3,a5
    80001730:	4785                	li	a5,1
    80001732:	01f79613          	sll	a2,a5,0x1f
    80001736:	4785                	li	a5,1
    80001738:	01f79593          	sll	a1,a5,0x1f
    8000173c:	00000097          	auipc	ra,0x0
    80001740:	ed4080e7          	jalr	-300(ra) # 80001610 <map_region>
    80001744:	87aa                	mv	a5,a0
    80001746:	cb89                	beqz	a5,80001758 <kvminit+0x9c>
        panic("text mapping failed");
    80001748:	00003517          	auipc	a0,0x3
    8000174c:	08050513          	add	a0,a0,128 # 800047c8 <etext+0x7c8>
    80001750:	fffff097          	auipc	ra,0xfffff
    80001754:	6d0080e7          	jalr	1744(ra) # 80000e20 <panic>
    
    // 2. 映射其余物理内存（RW）
    if(map_region(kernel_pagetable, (uint64)etext, (uint64)etext,
    80001758:	00005797          	auipc	a5,0x5
    8000175c:	8b078793          	add	a5,a5,-1872 # 80006008 <kernel_pagetable>
    80001760:	6388                	ld	a0,0(a5)
    80001762:	00003597          	auipc	a1,0x3
    80001766:	89e58593          	add	a1,a1,-1890 # 80004000 <etext>
    8000176a:	00003617          	auipc	a2,0x3
    8000176e:	89660613          	add	a2,a2,-1898 # 80004000 <etext>
                  PHYSTOP - (uint64)etext, PTE_R | PTE_W) != 0)
    80001772:	00003797          	auipc	a5,0x3
    80001776:	88e78793          	add	a5,a5,-1906 # 80004000 <etext>
    if(map_region(kernel_pagetable, (uint64)etext, (uint64)etext,
    8000177a:	4745                	li	a4,17
    8000177c:	076e                	sll	a4,a4,0x1b
    8000177e:	40f707b3          	sub	a5,a4,a5
    80001782:	4719                	li	a4,6
    80001784:	86be                	mv	a3,a5
    80001786:	00000097          	auipc	ra,0x0
    8000178a:	e8a080e7          	jalr	-374(ra) # 80001610 <map_region>
    8000178e:	87aa                	mv	a5,a0
    80001790:	cb89                	beqz	a5,800017a2 <kvminit+0xe6>
        panic("data mapping failed");
    80001792:	00003517          	auipc	a0,0x3
    80001796:	04e50513          	add	a0,a0,78 # 800047e0 <etext+0x7e0>
    8000179a:	fffff097          	auipc	ra,0xfffff
    8000179e:	686080e7          	jalr	1670(ra) # 80000e20 <panic>
    
    // 3. 映射UART
    if(map_region(kernel_pagetable, UART0, UART0, PGSIZE, PTE_R | PTE_W) != 0)
    800017a2:	00005797          	auipc	a5,0x5
    800017a6:	86678793          	add	a5,a5,-1946 # 80006008 <kernel_pagetable>
    800017aa:	639c                	ld	a5,0(a5)
    800017ac:	4719                	li	a4,6
    800017ae:	6685                	lui	a3,0x1
    800017b0:	10000637          	lui	a2,0x10000
    800017b4:	100005b7          	lui	a1,0x10000
    800017b8:	853e                	mv	a0,a5
    800017ba:	00000097          	auipc	ra,0x0
    800017be:	e56080e7          	jalr	-426(ra) # 80001610 <map_region>
    800017c2:	87aa                	mv	a5,a0
    800017c4:	cb89                	beqz	a5,800017d6 <kvminit+0x11a>
        panic("uart mapping failed");
    800017c6:	00003517          	auipc	a0,0x3
    800017ca:	03250513          	add	a0,a0,50 # 800047f8 <etext+0x7f8>
    800017ce:	fffff097          	auipc	ra,0xfffff
    800017d2:	652080e7          	jalr	1618(ra) # 80000e20 <panic>
    
    printf("Kernel page table setup complete!\n");
    800017d6:	00003517          	auipc	a0,0x3
    800017da:	03a50513          	add	a0,a0,58 # 80004810 <etext+0x810>
    800017de:	fffff097          	auipc	ra,0xfffff
    800017e2:	348080e7          	jalr	840(ra) # 80000b26 <printf>
}
    800017e6:	0001                	nop
    800017e8:	60a2                	ld	ra,8(sp)
    800017ea:	6402                	ld	s0,0(sp)
    800017ec:	0141                	add	sp,sp,16
    800017ee:	8082                	ret

00000000800017f0 <kvminithart>:

// 启用虚拟内存
void kvminithart(void) {
    800017f0:	1141                	add	sp,sp,-16
    800017f2:	e406                	sd	ra,8(sp)
    800017f4:	e022                	sd	s0,0(sp)
    800017f6:	0800                	add	s0,sp,16
    // 写入satp寄存器，启用Sv39分页
    w_satp(MAKE_SATP(kernel_pagetable));
    800017f8:	00005797          	auipc	a5,0x5
    800017fc:	81078793          	add	a5,a5,-2032 # 80006008 <kernel_pagetable>
    80001800:	639c                	ld	a5,0(a5)
    80001802:	00c7d713          	srl	a4,a5,0xc
    80001806:	57fd                	li	a5,-1
    80001808:	17fe                	sll	a5,a5,0x3f
    8000180a:	8fd9                	or	a5,a5,a4
    8000180c:	853e                	mv	a0,a5
    8000180e:	00000097          	auipc	ra,0x0
    80001812:	abe080e7          	jalr	-1346(ra) # 800012cc <w_satp>
    
    // 刷新TLB
    sfence_vma();
    80001816:	00000097          	auipc	ra,0x0
    8000181a:	ad0080e7          	jalr	-1328(ra) # 800012e6 <sfence_vma>
    
    printf("Virtual memory enabled!\n");
    8000181e:	00003517          	auipc	a0,0x3
    80001822:	01a50513          	add	a0,a0,26 # 80004838 <etext+0x838>
    80001826:	fffff097          	auipc	ra,0xfffff
    8000182a:	300080e7          	jalr	768(ra) # 80000b26 <printf>
}
    8000182e:	0001                	nop
    80001830:	60a2                	ld	ra,8(sp)
    80001832:	6402                	ld	s0,0(sp)
    80001834:	0141                	add	sp,sp,16
    80001836:	8082                	ret

0000000080001838 <dump_pagetable>:

// ==================== 调试工具 ====================

// 打印页表内容（递归）
void dump_pagetable(pagetable_t pagetable, int level) {
    80001838:	7179                	add	sp,sp,-48
    8000183a:	f406                	sd	ra,40(sp)
    8000183c:	f022                	sd	s0,32(sp)
    8000183e:	1800                	add	s0,sp,48
    80001840:	fca43c23          	sd	a0,-40(s0)
    80001844:	87ae                	mv	a5,a1
    80001846:	fcf42a23          	sw	a5,-44(s0)
    // 打印当前级别的所有有效PTE
    for(int i = 0; i < 512; i++) {
    8000184a:	fe042623          	sw	zero,-20(s0)
    8000184e:	a8d1                	j	80001922 <dump_pagetable+0xea>
        pte_t pte = pagetable[i];
    80001850:	fec42783          	lw	a5,-20(s0)
    80001854:	078e                	sll	a5,a5,0x3
    80001856:	fd843703          	ld	a4,-40(s0)
    8000185a:	97ba                	add	a5,a5,a4
    8000185c:	639c                	ld	a5,0(a5)
    8000185e:	fef43023          	sd	a5,-32(s0)
        
        if(pte & PTE_V) {
    80001862:	fe043783          	ld	a5,-32(s0)
    80001866:	8b85                	and	a5,a5,1
    80001868:	cbc5                	beqz	a5,80001918 <dump_pagetable+0xe0>
            // 打印缩进
            for(int j = 0; j < level; j++) {
    8000186a:	fe042423          	sw	zero,-24(s0)
    8000186e:	a831                	j	8000188a <dump_pagetable+0x52>
                printf("  ");
    80001870:	00003517          	auipc	a0,0x3
    80001874:	fe850513          	add	a0,a0,-24 # 80004858 <etext+0x858>
    80001878:	fffff097          	auipc	ra,0xfffff
    8000187c:	2ae080e7          	jalr	686(ra) # 80000b26 <printf>
            for(int j = 0; j < level; j++) {
    80001880:	fe842783          	lw	a5,-24(s0)
    80001884:	2785                	addw	a5,a5,1
    80001886:	fef42423          	sw	a5,-24(s0)
    8000188a:	fe842783          	lw	a5,-24(s0)
    8000188e:	873e                	mv	a4,a5
    80001890:	fd442783          	lw	a5,-44(s0)
    80001894:	2701                	sext.w	a4,a4
    80001896:	2781                	sext.w	a5,a5
    80001898:	fcf74ce3          	blt	a4,a5,80001870 <dump_pagetable+0x38>
            }
            
            printf("[%d] pte %p", i, (void*)pte);
    8000189c:	fe043703          	ld	a4,-32(s0)
    800018a0:	fec42783          	lw	a5,-20(s0)
    800018a4:	863a                	mv	a2,a4
    800018a6:	85be                	mv	a1,a5
    800018a8:	00003517          	auipc	a0,0x3
    800018ac:	fb850513          	add	a0,a0,-72 # 80004860 <etext+0x860>
    800018b0:	fffff097          	auipc	ra,0xfffff
    800018b4:	276080e7          	jalr	630(ra) # 80000b26 <printf>
            
            if((pte & (PTE_R|PTE_W|PTE_X)) == 0) {
    800018b8:	fe043783          	ld	a5,-32(s0)
    800018bc:	8bb9                	and	a5,a5,14
    800018be:	e3a1                	bnez	a5,800018fe <dump_pagetable+0xc6>
                // 这是一个指向下一级页表的指针
                printf(" -> next level\n");
    800018c0:	00003517          	auipc	a0,0x3
    800018c4:	fb050513          	add	a0,a0,-80 # 80004870 <etext+0x870>
    800018c8:	fffff097          	auipc	ra,0xfffff
    800018cc:	25e080e7          	jalr	606(ra) # 80000b26 <printf>
                if(level < 2) {
    800018d0:	fd442783          	lw	a5,-44(s0)
    800018d4:	0007871b          	sext.w	a4,a5
    800018d8:	4785                	li	a5,1
    800018da:	02e7cf63          	blt	a5,a4,80001918 <dump_pagetable+0xe0>
                    dump_pagetable((pagetable_t)PTE2PA(pte), level + 1);
    800018de:	fe043783          	ld	a5,-32(s0)
    800018e2:	83a9                	srl	a5,a5,0xa
    800018e4:	07b2                	sll	a5,a5,0xc
    800018e6:	873e                	mv	a4,a5
    800018e8:	fd442783          	lw	a5,-44(s0)
    800018ec:	2785                	addw	a5,a5,1
    800018ee:	2781                	sext.w	a5,a5
    800018f0:	85be                	mv	a1,a5
    800018f2:	853a                	mv	a0,a4
    800018f4:	00000097          	auipc	ra,0x0
    800018f8:	f44080e7          	jalr	-188(ra) # 80001838 <dump_pagetable>
    800018fc:	a831                	j	80001918 <dump_pagetable+0xe0>
                }
            } else {
                // 这是一个叶子PTE
                printf(" -> PA %p\n", (void*)PTE2PA(pte));
    800018fe:	fe043783          	ld	a5,-32(s0)
    80001902:	83a9                	srl	a5,a5,0xa
    80001904:	07b2                	sll	a5,a5,0xc
    80001906:	85be                	mv	a1,a5
    80001908:	00003517          	auipc	a0,0x3
    8000190c:	f7850513          	add	a0,a0,-136 # 80004880 <etext+0x880>
    80001910:	fffff097          	auipc	ra,0xfffff
    80001914:	216080e7          	jalr	534(ra) # 80000b26 <printf>
    for(int i = 0; i < 512; i++) {
    80001918:	fec42783          	lw	a5,-20(s0)
    8000191c:	2785                	addw	a5,a5,1
    8000191e:	fef42623          	sw	a5,-20(s0)
    80001922:	fec42783          	lw	a5,-20(s0)
    80001926:	0007871b          	sext.w	a4,a5
    8000192a:	1ff00793          	li	a5,511
    8000192e:	f2e7d1e3          	bge	a5,a4,80001850 <dump_pagetable+0x18>
            }
        }
    }
}
    80001932:	0001                	nop
    80001934:	0001                	nop
    80001936:	70a2                	ld	ra,40(sp)
    80001938:	7402                	ld	s0,32(sp)
    8000193a:	6145                	add	sp,sp,48
    8000193c:	8082                	ret

000000008000193e <check_page_permission>:

// 检查页面权限
void check_page_permission(uint64 addr, int access_type) {
    8000193e:	7179                	add	sp,sp,-48
    80001940:	f406                	sd	ra,40(sp)
    80001942:	f022                	sd	s0,32(sp)
    80001944:	1800                	add	s0,sp,48
    80001946:	fca43c23          	sd	a0,-40(s0)
    8000194a:	87ae                	mv	a5,a1
    8000194c:	fcf42a23          	sw	a5,-44(s0)
    pte_t *pte = walk_lookup(kernel_pagetable, addr);
    80001950:	00004797          	auipc	a5,0x4
    80001954:	6b878793          	add	a5,a5,1720 # 80006008 <kernel_pagetable>
    80001958:	639c                	ld	a5,0(a5)
    8000195a:	fd843583          	ld	a1,-40(s0)
    8000195e:	853e                	mv	a0,a5
    80001960:	00000097          	auipc	ra,0x0
    80001964:	a7c080e7          	jalr	-1412(ra) # 800013dc <walk_lookup>
    80001968:	fea43423          	sd	a0,-24(s0)
    
    if(pte == 0 || !(*pte & PTE_V)) {
    8000196c:	fe843783          	ld	a5,-24(s0)
    80001970:	c791                	beqz	a5,8000197c <check_page_permission+0x3e>
    80001972:	fe843783          	ld	a5,-24(s0)
    80001976:	639c                	ld	a5,0(a5)
    80001978:	8b85                	and	a5,a5,1
    8000197a:	ef89                	bnez	a5,80001994 <check_page_permission+0x56>
        printf("Address %p: Not mapped\n", (void*)addr);
    8000197c:	fd843783          	ld	a5,-40(s0)
    80001980:	85be                	mv	a1,a5
    80001982:	00003517          	auipc	a0,0x3
    80001986:	f0e50513          	add	a0,a0,-242 # 80004890 <etext+0x890>
    8000198a:	fffff097          	auipc	ra,0xfffff
    8000198e:	19c080e7          	jalr	412(ra) # 80000b26 <printf>
        return;
    80001992:	a851                	j	80001a26 <check_page_permission+0xe8>
    }
    
    printf("Address %p: ", (void*)addr);
    80001994:	fd843783          	ld	a5,-40(s0)
    80001998:	85be                	mv	a1,a5
    8000199a:	00003517          	auipc	a0,0x3
    8000199e:	f0e50513          	add	a0,a0,-242 # 800048a8 <etext+0x8a8>
    800019a2:	fffff097          	auipc	ra,0xfffff
    800019a6:	184080e7          	jalr	388(ra) # 80000b26 <printf>
    
    if((access_type & ACCESS_READ) && !(*pte & PTE_R)) {
    800019aa:	fd442783          	lw	a5,-44(s0)
    800019ae:	8b85                	and	a5,a5,1
    800019b0:	2781                	sext.w	a5,a5
    800019b2:	cf91                	beqz	a5,800019ce <check_page_permission+0x90>
    800019b4:	fe843783          	ld	a5,-24(s0)
    800019b8:	639c                	ld	a5,0(a5)
    800019ba:	8b89                	and	a5,a5,2
    800019bc:	eb89                	bnez	a5,800019ce <check_page_permission+0x90>
        printf("Read permission denied ");
    800019be:	00003517          	auipc	a0,0x3
    800019c2:	efa50513          	add	a0,a0,-262 # 800048b8 <etext+0x8b8>
    800019c6:	fffff097          	auipc	ra,0xfffff
    800019ca:	160080e7          	jalr	352(ra) # 80000b26 <printf>
    }
    
    if((access_type & ACCESS_WRITE) && !(*pte & PTE_W)) {
    800019ce:	fd442783          	lw	a5,-44(s0)
    800019d2:	8b89                	and	a5,a5,2
    800019d4:	2781                	sext.w	a5,a5
    800019d6:	cf91                	beqz	a5,800019f2 <check_page_permission+0xb4>
    800019d8:	fe843783          	ld	a5,-24(s0)
    800019dc:	639c                	ld	a5,0(a5)
    800019de:	8b91                	and	a5,a5,4
    800019e0:	eb89                	bnez	a5,800019f2 <check_page_permission+0xb4>
        printf("Write permission denied ");
    800019e2:	00003517          	auipc	a0,0x3
    800019e6:	eee50513          	add	a0,a0,-274 # 800048d0 <etext+0x8d0>
    800019ea:	fffff097          	auipc	ra,0xfffff
    800019ee:	13c080e7          	jalr	316(ra) # 80000b26 <printf>
    }
    
    if((access_type & ACCESS_EXEC) && !(*pte & PTE_X)) {
    800019f2:	fd442783          	lw	a5,-44(s0)
    800019f6:	8b91                	and	a5,a5,4
    800019f8:	2781                	sext.w	a5,a5
    800019fa:	cf91                	beqz	a5,80001a16 <check_page_permission+0xd8>
    800019fc:	fe843783          	ld	a5,-24(s0)
    80001a00:	639c                	ld	a5,0(a5)
    80001a02:	8ba1                	and	a5,a5,8
    80001a04:	eb89                	bnez	a5,80001a16 <check_page_permission+0xd8>
        printf("Execute permission denied ");
    80001a06:	00003517          	auipc	a0,0x3
    80001a0a:	eea50513          	add	a0,a0,-278 # 800048f0 <etext+0x8f0>
    80001a0e:	fffff097          	auipc	ra,0xfffff
    80001a12:	118080e7          	jalr	280(ra) # 80000b26 <printf>
    }
    
    printf("\n");
    80001a16:	00003517          	auipc	a0,0x3
    80001a1a:	efa50513          	add	a0,a0,-262 # 80004910 <etext+0x910>
    80001a1e:	fffff097          	auipc	ra,0xfffff
    80001a22:	108080e7          	jalr	264(ra) # 80000b26 <printf>
    80001a26:	70a2                	ld	ra,40(sp)
    80001a28:	7402                	ld	s0,32(sp)
    80001a2a:	6145                	add	sp,sp,48
    80001a2c:	8082                	ret

0000000080001a2e <r_sstatus>:
    
    return 0;
}
// ==================== 系统调用处理 ====================
void handle_syscall(struct trapframe *tf) {
    printf("\n=== System Call ===\n");
    80001a2e:	1101                	add	sp,sp,-32
    80001a30:	ec22                	sd	s0,24(sp)
    80001a32:	1000                	add	s0,sp,32
    printf("syscall number: %d (in a7)\n", (int)tf->a7);
    printf("arguments: a0=%p, a1=%p\n", (void*)tf->a0, (void*)tf->a1);
    80001a34:	100027f3          	csrr	a5,sstatus
    80001a38:	fef43423          	sd	a5,-24(s0)
    printf("called from: %p\n", (void*)tf->sepc);
    80001a3c:	fe843783          	ld	a5,-24(s0)
    
    80001a40:	853e                	mv	a0,a5
    80001a42:	6462                	ld	s0,24(sp)
    80001a44:	6105                	add	sp,sp,32
    80001a46:	8082                	ret

0000000080001a48 <w_sstatus>:
    // 跳过 ecall 指令（4字节）
    tf->sepc += 4;
    80001a48:	1101                	add	sp,sp,-32
    80001a4a:	ec22                	sd	s0,24(sp)
    80001a4c:	1000                	add	s0,sp,32
    80001a4e:	fea43423          	sd	a0,-24(s0)
    
    80001a52:	fe843783          	ld	a5,-24(s0)
    80001a56:	10079073          	csrw	sstatus,a5
    printf("System call handled, returning to %p\n", (void*)tf->sepc);
    80001a5a:	0001                	nop
    80001a5c:	6462                	ld	s0,24(sp)
    80001a5e:	6105                	add	sp,sp,32
    80001a60:	8082                	ret

0000000080001a62 <r_sie>:
}

    80001a62:	1101                	add	sp,sp,-32
    80001a64:	ec22                	sd	s0,24(sp)
    80001a66:	1000                	add	s0,sp,32
// ==================== 指令页故障处理 ====================
void handle_instruction_page_fault(struct trapframe *tf) {
    80001a68:	104027f3          	csrr	a5,sie
    80001a6c:	fef43423          	sd	a5,-24(s0)
    uint64 fault_addr = r_stval();  // 故障地址
    80001a70:	fe843783          	ld	a5,-24(s0)
    
    80001a74:	853e                	mv	a0,a5
    80001a76:	6462                	ld	s0,24(sp)
    80001a78:	6105                	add	sp,sp,32
    80001a7a:	8082                	ret

0000000080001a7c <w_sie>:
    printf("\n=== Instruction Page Fault ===\n");
    printf("Fault address: %p\n", (void*)fault_addr);
    80001a7c:	1101                	add	sp,sp,-32
    80001a7e:	ec22                	sd	s0,24(sp)
    80001a80:	1000                	add	s0,sp,32
    80001a82:	fea43423          	sd	a0,-24(s0)
    printf("PC: %p\n", (void*)tf->sepc);
    80001a86:	fe843783          	ld	a5,-24(s0)
    80001a8a:	10479073          	csrw	sie,a5
    
    80001a8e:	0001                	nop
    80001a90:	6462                	ld	s0,24(sp)
    80001a92:	6105                	add	sp,sp,32
    80001a94:	8082                	ret

0000000080001a96 <r_sip>:
    // 简单处理：如果是内核地址，panic
    if(fault_addr >= KERNBASE) {
    80001a96:	1101                	add	sp,sp,-32
    80001a98:	ec22                	sd	s0,24(sp)
    80001a9a:	1000                	add	s0,sp,32
        panic("Instruction page fault in kernel space");
    }
    80001a9c:	144027f3          	csrr	a5,sip
    80001aa0:	fef43423          	sd	a5,-24(s0)
    
    80001aa4:	fe843783          	ld	a5,-24(s0)
    // 这里可以实现按需分页等功能
    80001aa8:	853e                	mv	a0,a5
    80001aaa:	6462                	ld	s0,24(sp)
    80001aac:	6105                	add	sp,sp,32
    80001aae:	8082                	ret

0000000080001ab0 <w_sip>:
    printf("TODO: Implement demand paging for instruction fault\n");
    panic("Instruction page fault not handled");
    80001ab0:	1101                	add	sp,sp,-32
    80001ab2:	ec22                	sd	s0,24(sp)
    80001ab4:	1000                	add	s0,sp,32
    80001ab6:	fea43423          	sd	a0,-24(s0)
}
    80001aba:	fe843783          	ld	a5,-24(s0)
    80001abe:	14479073          	csrw	sip,a5

    80001ac2:	0001                	nop
    80001ac4:	6462                	ld	s0,24(sp)
    80001ac6:	6105                	add	sp,sp,32
    80001ac8:	8082                	ret

0000000080001aca <r_scause>:
// ==================== 加载页故障处理 ====================
void handle_load_page_fault(struct trapframe *tf) {
    80001aca:	1101                	add	sp,sp,-32
    80001acc:	ec22                	sd	s0,24(sp)
    80001ace:	1000                	add	s0,sp,32
    uint64 fault_addr = r_stval();  // 故障地址
    
    80001ad0:	142027f3          	csrr	a5,scause
    80001ad4:	fef43423          	sd	a5,-24(s0)
    printf("\n=== Load Page Fault ===\n");
    80001ad8:	fe843783          	ld	a5,-24(s0)
    printf("Fault address: %p\n", (void*)fault_addr);
    80001adc:	853e                	mv	a0,a5
    80001ade:	6462                	ld	s0,24(sp)
    80001ae0:	6105                	add	sp,sp,32
    80001ae2:	8082                	ret

0000000080001ae4 <r_stval>:

// ==================== 存储页故障处理 ====================
void handle_store_page_fault(struct trapframe *tf) {
    uint64 fault_addr = r_stval();  // 故障地址
    
    printf("\n=== Store Page Fault ===\n");
    80001ae4:	1101                	add	sp,sp,-32
    80001ae6:	ec22                	sd	s0,24(sp)
    80001ae8:	1000                	add	s0,sp,32
    printf("Fault address: %p\n", (void*)fault_addr);
    printf("PC: %p\n", (void*)tf->sepc);
    80001aea:	143027f3          	csrr	a5,stval
    80001aee:	fef43423          	sd	a5,-24(s0)
    printf("Tried to write to unmapped or read-only address\n");
    80001af2:	fe843783          	ld	a5,-24(s0)
    
    80001af6:	853e                	mv	a0,a5
    80001af8:	6462                	ld	s0,24(sp)
    80001afa:	6105                	add	sp,sp,32
    80001afc:	8082                	ret

0000000080001afe <w_stvec>:
        printf("Attempted to write to read-only kernel text segment!\n");
    }
    
    panic("Store page fault");
}

    80001afe:	1101                	add	sp,sp,-32
    80001b00:	ec22                	sd	s0,24(sp)
    80001b02:	1000                	add	s0,sp,32
    80001b04:	fea43423          	sd	a0,-24(s0)
// ==================== 统一异常处理入口 ====================
    80001b08:	fe843783          	ld	a5,-24(s0)
    80001b0c:	10579073          	csrw	stvec,a5
void handle_exception(struct trapframe *tf) {
    80001b10:	0001                	nop
    80001b12:	6462                	ld	s0,24(sp)
    80001b14:	6105                	add	sp,sp,32
    80001b16:	8082                	ret

0000000080001b18 <trap_init>:
{
    80001b18:	1101                	add	sp,sp,-32
    80001b1a:	ec06                	sd	ra,24(sp)
    80001b1c:	e822                	sd	s0,16(sp)
    80001b1e:	1000                	add	s0,sp,32
    printf("Initializing trap system...\n");
    80001b20:	00003517          	auipc	a0,0x3
    80001b24:	df850513          	add	a0,a0,-520 # 80004918 <etext+0x918>
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	ffe080e7          	jalr	-2(ra) # 80000b26 <printf>
    for(int i = 0; i < 16; i++) {
    80001b30:	fe042623          	sw	zero,-20(s0)
    80001b34:	a815                	j	80001b68 <trap_init+0x50>
        interrupt_handlers[i] = 0;
    80001b36:	00007717          	auipc	a4,0x7
    80001b3a:	59270713          	add	a4,a4,1426 # 800090c8 <interrupt_handlers>
    80001b3e:	fec42783          	lw	a5,-20(s0)
    80001b42:	078e                	sll	a5,a5,0x3
    80001b44:	97ba                	add	a5,a5,a4
    80001b46:	0007b023          	sd	zero,0(a5)
        interrupt_counts[i] = 0;
    80001b4a:	00007717          	auipc	a4,0x7
    80001b4e:	4f670713          	add	a4,a4,1270 # 80009040 <interrupt_counts>
    80001b52:	fec42783          	lw	a5,-20(s0)
    80001b56:	078e                	sll	a5,a5,0x3
    80001b58:	97ba                	add	a5,a5,a4
    80001b5a:	0007b023          	sd	zero,0(a5)
    for(int i = 0; i < 16; i++) {
    80001b5e:	fec42783          	lw	a5,-20(s0)
    80001b62:	2785                	addw	a5,a5,1
    80001b64:	fef42623          	sw	a5,-20(s0)
    80001b68:	fec42783          	lw	a5,-20(s0)
    80001b6c:	0007871b          	sext.w	a4,a5
    80001b70:	47bd                	li	a5,15
    80001b72:	fce7d2e3          	bge	a5,a4,80001b36 <trap_init+0x1e>
    w_stvec((uint64)kernelvec);
    80001b76:	00001797          	auipc	a5,0x1
    80001b7a:	aba78793          	add	a5,a5,-1350 # 80002630 <kernelvec>
    80001b7e:	853e                	mv	a0,a5
    80001b80:	00000097          	auipc	ra,0x0
    80001b84:	f7e080e7          	jalr	-130(ra) # 80001afe <w_stvec>
    printf("Set stvec to %p\n", (void*)kernelvec);
    80001b88:	00001597          	auipc	a1,0x1
    80001b8c:	aa858593          	add	a1,a1,-1368 # 80002630 <kernelvec>
    80001b90:	00003517          	auipc	a0,0x3
    80001b94:	da850513          	add	a0,a0,-600 # 80004938 <etext+0x938>
    80001b98:	fffff097          	auipc	ra,0xfffff
    80001b9c:	f8e080e7          	jalr	-114(ra) # 80000b26 <printf>
    w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    80001ba0:	00000097          	auipc	ra,0x0
    80001ba4:	ec2080e7          	jalr	-318(ra) # 80001a62 <r_sie>
    80001ba8:	87aa                	mv	a5,a0
    80001baa:	2227e793          	or	a5,a5,546
    80001bae:	853e                	mv	a0,a5
    80001bb0:	00000097          	auipc	ra,0x0
    80001bb4:	ecc080e7          	jalr	-308(ra) # 80001a7c <w_sie>
    w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001bb8:	00000097          	auipc	ra,0x0
    80001bbc:	e76080e7          	jalr	-394(ra) # 80001a2e <r_sstatus>
    80001bc0:	87aa                	mv	a5,a0
    80001bc2:	0027e793          	or	a5,a5,2
    80001bc6:	853e                	mv	a0,a5
    80001bc8:	00000097          	auipc	ra,0x0
    80001bcc:	e80080e7          	jalr	-384(ra) # 80001a48 <w_sstatus>
    printf("Trap system initialized\n");
    80001bd0:	00003517          	auipc	a0,0x3
    80001bd4:	d8050513          	add	a0,a0,-640 # 80004950 <etext+0x950>
    80001bd8:	fffff097          	auipc	ra,0xfffff
    80001bdc:	f4e080e7          	jalr	-178(ra) # 80000b26 <printf>
}
    80001be0:	0001                	nop
    80001be2:	60e2                	ld	ra,24(sp)
    80001be4:	6442                	ld	s0,16(sp)
    80001be6:	6105                	add	sp,sp,32
    80001be8:	8082                	ret

0000000080001bea <register_interrupt>:
{
    80001bea:	1101                	add	sp,sp,-32
    80001bec:	ec06                	sd	ra,24(sp)
    80001bee:	e822                	sd	s0,16(sp)
    80001bf0:	1000                	add	s0,sp,32
    80001bf2:	87aa                	mv	a5,a0
    80001bf4:	feb43023          	sd	a1,-32(s0)
    80001bf8:	fef42623          	sw	a5,-20(s0)
    if(irq < 0 || irq >= 16) {
    80001bfc:	fec42783          	lw	a5,-20(s0)
    80001c00:	2781                	sext.w	a5,a5
    80001c02:	0007c963          	bltz	a5,80001c14 <register_interrupt+0x2a>
    80001c06:	fec42783          	lw	a5,-20(s0)
    80001c0a:	0007871b          	sext.w	a4,a5
    80001c0e:	47bd                	li	a5,15
    80001c10:	00e7de63          	bge	a5,a4,80001c2c <register_interrupt+0x42>
        printf("register_interrupt: invalid IRQ %d\n", irq);
    80001c14:	fec42783          	lw	a5,-20(s0)
    80001c18:	85be                	mv	a1,a5
    80001c1a:	00003517          	auipc	a0,0x3
    80001c1e:	d5650513          	add	a0,a0,-682 # 80004970 <etext+0x970>
    80001c22:	fffff097          	auipc	ra,0xfffff
    80001c26:	f04080e7          	jalr	-252(ra) # 80000b26 <printf>
        return;
    80001c2a:	a03d                	j	80001c58 <register_interrupt+0x6e>
    interrupt_handlers[irq] = handler;
    80001c2c:	00007717          	auipc	a4,0x7
    80001c30:	49c70713          	add	a4,a4,1180 # 800090c8 <interrupt_handlers>
    80001c34:	fec42783          	lw	a5,-20(s0)
    80001c38:	078e                	sll	a5,a5,0x3
    80001c3a:	97ba                	add	a5,a5,a4
    80001c3c:	fe043703          	ld	a4,-32(s0)
    80001c40:	e398                	sd	a4,0(a5)
    printf("Registered handler for IRQ %d\n", irq);
    80001c42:	fec42783          	lw	a5,-20(s0)
    80001c46:	85be                	mv	a1,a5
    80001c48:	00003517          	auipc	a0,0x3
    80001c4c:	d5050513          	add	a0,a0,-688 # 80004998 <etext+0x998>
    80001c50:	fffff097          	auipc	ra,0xfffff
    80001c54:	ed6080e7          	jalr	-298(ra) # 80000b26 <printf>
}
    80001c58:	60e2                	ld	ra,24(sp)
    80001c5a:	6442                	ld	s0,16(sp)
    80001c5c:	6105                	add	sp,sp,32
    80001c5e:	8082                	ret

0000000080001c60 <devintr>:
{
    80001c60:	1101                	add	sp,sp,-32
    80001c62:	ec06                	sd	ra,24(sp)
    80001c64:	e822                	sd	s0,16(sp)
    80001c66:	1000                	add	s0,sp,32
    uint64 scause = r_scause();
    80001c68:	00000097          	auipc	ra,0x0
    80001c6c:	e62080e7          	jalr	-414(ra) # 80001aca <r_scause>
    80001c70:	fea43423          	sd	a0,-24(s0)
    if((scause & 0x8000000000000000L) == 0) {
    80001c74:	fe843783          	ld	a5,-24(s0)
    80001c78:	0007c463          	bltz	a5,80001c80 <devintr+0x20>
        return 0;
    80001c7c:	4781                	li	a5,0
    80001c7e:	a8e5                	j	80001d76 <devintr+0x116>
    scause = scause & 0xff;
    80001c80:	fe843783          	ld	a5,-24(s0)
    80001c84:	0ff7f793          	zext.b	a5,a5
    80001c88:	fef43423          	sd	a5,-24(s0)
    if(scause == IRQ_S_TIMER) {
    80001c8c:	fe843703          	ld	a4,-24(s0)
    80001c90:	4795                	li	a5,5
    80001c92:	02f71c63          	bne	a4,a5,80001cca <devintr+0x6a>
        interrupt_counts[IRQ_S_TIMER]++;
    80001c96:	00007797          	auipc	a5,0x7
    80001c9a:	3aa78793          	add	a5,a5,938 # 80009040 <interrupt_counts>
    80001c9e:	779c                	ld	a5,40(a5)
    80001ca0:	00178713          	add	a4,a5,1
    80001ca4:	00007797          	auipc	a5,0x7
    80001ca8:	39c78793          	add	a5,a5,924 # 80009040 <interrupt_counts>
    80001cac:	f798                	sd	a4,40(a5)
        if(interrupt_handlers[IRQ_S_TIMER]) {
    80001cae:	00007797          	auipc	a5,0x7
    80001cb2:	41a78793          	add	a5,a5,1050 # 800090c8 <interrupt_handlers>
    80001cb6:	779c                	ld	a5,40(a5)
    80001cb8:	c799                	beqz	a5,80001cc6 <devintr+0x66>
            interrupt_handlers[IRQ_S_TIMER]();
    80001cba:	00007797          	auipc	a5,0x7
    80001cbe:	40e78793          	add	a5,a5,1038 # 800090c8 <interrupt_handlers>
    80001cc2:	779c                	ld	a5,40(a5)
    80001cc4:	9782                	jalr	a5
        return 1;
    80001cc6:	4785                	li	a5,1
    80001cc8:	a07d                	j	80001d76 <devintr+0x116>
    } else if(scause == IRQ_S_SOFT) {
    80001cca:	fe843703          	ld	a4,-24(s0)
    80001cce:	4785                	li	a5,1
    80001cd0:	06f71363          	bne	a4,a5,80001d36 <devintr+0xd6>
        interrupt_counts[IRQ_S_SOFT]++;
    80001cd4:	00007797          	auipc	a5,0x7
    80001cd8:	36c78793          	add	a5,a5,876 # 80009040 <interrupt_counts>
    80001cdc:	679c                	ld	a5,8(a5)
    80001cde:	00178713          	add	a4,a5,1
    80001ce2:	00007797          	auipc	a5,0x7
    80001ce6:	35e78793          	add	a5,a5,862 # 80009040 <interrupt_counts>
    80001cea:	e798                	sd	a4,8(a5)
        w_sip(r_sip() & ~2);
    80001cec:	00000097          	auipc	ra,0x0
    80001cf0:	daa080e7          	jalr	-598(ra) # 80001a96 <r_sip>
    80001cf4:	87aa                	mv	a5,a0
    80001cf6:	9bf5                	and	a5,a5,-3
    80001cf8:	853e                	mv	a0,a5
    80001cfa:	00000097          	auipc	ra,0x0
    80001cfe:	db6080e7          	jalr	-586(ra) # 80001ab0 <w_sip>
        if(interrupt_handlers[IRQ_S_TIMER]) {
    80001d02:	00007797          	auipc	a5,0x7
    80001d06:	3c678793          	add	a5,a5,966 # 800090c8 <interrupt_handlers>
    80001d0a:	779c                	ld	a5,40(a5)
    80001d0c:	c39d                	beqz	a5,80001d32 <devintr+0xd2>
            interrupt_handlers[IRQ_S_TIMER]();
    80001d0e:	00007797          	auipc	a5,0x7
    80001d12:	3ba78793          	add	a5,a5,954 # 800090c8 <interrupt_handlers>
    80001d16:	779c                	ld	a5,40(a5)
    80001d18:	9782                	jalr	a5
            interrupt_counts[IRQ_S_TIMER]++;  // 也统计为时钟中断
    80001d1a:	00007797          	auipc	a5,0x7
    80001d1e:	32678793          	add	a5,a5,806 # 80009040 <interrupt_counts>
    80001d22:	779c                	ld	a5,40(a5)
    80001d24:	00178713          	add	a4,a5,1
    80001d28:	00007797          	auipc	a5,0x7
    80001d2c:	31878793          	add	a5,a5,792 # 80009040 <interrupt_counts>
    80001d30:	f798                	sd	a4,40(a5)
        return 1;
    80001d32:	4785                	li	a5,1
    80001d34:	a089                	j	80001d76 <devintr+0x116>
    } else if(scause == IRQ_S_EXT) {
    80001d36:	fe843703          	ld	a4,-24(s0)
    80001d3a:	47a5                	li	a5,9
    80001d3c:	02f71c63          	bne	a4,a5,80001d74 <devintr+0x114>
        interrupt_counts[IRQ_S_EXT]++;
    80001d40:	00007797          	auipc	a5,0x7
    80001d44:	30078793          	add	a5,a5,768 # 80009040 <interrupt_counts>
    80001d48:	67bc                	ld	a5,72(a5)
    80001d4a:	00178713          	add	a4,a5,1
    80001d4e:	00007797          	auipc	a5,0x7
    80001d52:	2f278793          	add	a5,a5,754 # 80009040 <interrupt_counts>
    80001d56:	e7b8                	sd	a4,72(a5)
        if(interrupt_handlers[IRQ_S_EXT]) {
    80001d58:	00007797          	auipc	a5,0x7
    80001d5c:	37078793          	add	a5,a5,880 # 800090c8 <interrupt_handlers>
    80001d60:	67bc                	ld	a5,72(a5)
    80001d62:	c799                	beqz	a5,80001d70 <devintr+0x110>
            interrupt_handlers[IRQ_S_EXT]();
    80001d64:	00007797          	auipc	a5,0x7
    80001d68:	36478793          	add	a5,a5,868 # 800090c8 <interrupt_handlers>
    80001d6c:	67bc                	ld	a5,72(a5)
    80001d6e:	9782                	jalr	a5
        return 1;
    80001d70:	4785                	li	a5,1
    80001d72:	a011                	j	80001d76 <devintr+0x116>
    return 0;
    80001d74:	4781                	li	a5,0
}
    80001d76:	853e                	mv	a0,a5
    80001d78:	60e2                	ld	ra,24(sp)
    80001d7a:	6442                	ld	s0,16(sp)
    80001d7c:	6105                	add	sp,sp,32
    80001d7e:	8082                	ret

0000000080001d80 <handle_syscall>:
void handle_syscall(struct trapframe *tf) {
    80001d80:	1101                	add	sp,sp,-32
    80001d82:	ec06                	sd	ra,24(sp)
    80001d84:	e822                	sd	s0,16(sp)
    80001d86:	1000                	add	s0,sp,32
    80001d88:	fea43423          	sd	a0,-24(s0)
    printf("\n=== System Call ===\n");
    80001d8c:	00003517          	auipc	a0,0x3
    80001d90:	c2c50513          	add	a0,a0,-980 # 800049b8 <etext+0x9b8>
    80001d94:	fffff097          	auipc	ra,0xfffff
    80001d98:	d92080e7          	jalr	-622(ra) # 80000b26 <printf>
    printf("syscall number: %d (in a7)\n", (int)tf->a7);
    80001d9c:	fe843783          	ld	a5,-24(s0)
    80001da0:	63dc                	ld	a5,128(a5)
    80001da2:	2781                	sext.w	a5,a5
    80001da4:	85be                	mv	a1,a5
    80001da6:	00003517          	auipc	a0,0x3
    80001daa:	c2a50513          	add	a0,a0,-982 # 800049d0 <etext+0x9d0>
    80001dae:	fffff097          	auipc	ra,0xfffff
    80001db2:	d78080e7          	jalr	-648(ra) # 80000b26 <printf>
    printf("arguments: a0=%p, a1=%p\n", (void*)tf->a0, (void*)tf->a1);
    80001db6:	fe843783          	ld	a5,-24(s0)
    80001dba:	67bc                	ld	a5,72(a5)
    80001dbc:	873e                	mv	a4,a5
    80001dbe:	fe843783          	ld	a5,-24(s0)
    80001dc2:	6bbc                	ld	a5,80(a5)
    80001dc4:	863e                	mv	a2,a5
    80001dc6:	85ba                	mv	a1,a4
    80001dc8:	00003517          	auipc	a0,0x3
    80001dcc:	c2850513          	add	a0,a0,-984 # 800049f0 <etext+0x9f0>
    80001dd0:	fffff097          	auipc	ra,0xfffff
    80001dd4:	d56080e7          	jalr	-682(ra) # 80000b26 <printf>
    printf("called from: %p\n", (void*)tf->sepc);
    80001dd8:	fe843783          	ld	a5,-24(s0)
    80001ddc:	7ffc                	ld	a5,248(a5)
    80001dde:	85be                	mv	a1,a5
    80001de0:	00003517          	auipc	a0,0x3
    80001de4:	c3050513          	add	a0,a0,-976 # 80004a10 <etext+0xa10>
    80001de8:	fffff097          	auipc	ra,0xfffff
    80001dec:	d3e080e7          	jalr	-706(ra) # 80000b26 <printf>
    tf->sepc += 4;
    80001df0:	fe843783          	ld	a5,-24(s0)
    80001df4:	7ffc                	ld	a5,248(a5)
    80001df6:	00478713          	add	a4,a5,4
    80001dfa:	fe843783          	ld	a5,-24(s0)
    80001dfe:	fff8                	sd	a4,248(a5)
    printf("System call handled, returning to %p\n", (void*)tf->sepc);
    80001e00:	fe843783          	ld	a5,-24(s0)
    80001e04:	7ffc                	ld	a5,248(a5)
    80001e06:	85be                	mv	a1,a5
    80001e08:	00003517          	auipc	a0,0x3
    80001e0c:	c2050513          	add	a0,a0,-992 # 80004a28 <etext+0xa28>
    80001e10:	fffff097          	auipc	ra,0xfffff
    80001e14:	d16080e7          	jalr	-746(ra) # 80000b26 <printf>
}
    80001e18:	0001                	nop
    80001e1a:	60e2                	ld	ra,24(sp)
    80001e1c:	6442                	ld	s0,16(sp)
    80001e1e:	6105                	add	sp,sp,32
    80001e20:	8082                	ret

0000000080001e22 <handle_instruction_page_fault>:
void handle_instruction_page_fault(struct trapframe *tf) {
    80001e22:	7179                	add	sp,sp,-48
    80001e24:	f406                	sd	ra,40(sp)
    80001e26:	f022                	sd	s0,32(sp)
    80001e28:	1800                	add	s0,sp,48
    80001e2a:	fca43c23          	sd	a0,-40(s0)
    uint64 fault_addr = r_stval();  // 故障地址
    80001e2e:	00000097          	auipc	ra,0x0
    80001e32:	cb6080e7          	jalr	-842(ra) # 80001ae4 <r_stval>
    80001e36:	fea43423          	sd	a0,-24(s0)
    printf("\n=== Instruction Page Fault ===\n");
    80001e3a:	00003517          	auipc	a0,0x3
    80001e3e:	c1650513          	add	a0,a0,-1002 # 80004a50 <etext+0xa50>
    80001e42:	fffff097          	auipc	ra,0xfffff
    80001e46:	ce4080e7          	jalr	-796(ra) # 80000b26 <printf>
    printf("Fault address: %p\n", (void*)fault_addr);
    80001e4a:	fe843783          	ld	a5,-24(s0)
    80001e4e:	85be                	mv	a1,a5
    80001e50:	00003517          	auipc	a0,0x3
    80001e54:	c2850513          	add	a0,a0,-984 # 80004a78 <etext+0xa78>
    80001e58:	fffff097          	auipc	ra,0xfffff
    80001e5c:	cce080e7          	jalr	-818(ra) # 80000b26 <printf>
    printf("PC: %p\n", (void*)tf->sepc);
    80001e60:	fd843783          	ld	a5,-40(s0)
    80001e64:	7ffc                	ld	a5,248(a5)
    80001e66:	85be                	mv	a1,a5
    80001e68:	00003517          	auipc	a0,0x3
    80001e6c:	c2850513          	add	a0,a0,-984 # 80004a90 <etext+0xa90>
    80001e70:	fffff097          	auipc	ra,0xfffff
    80001e74:	cb6080e7          	jalr	-842(ra) # 80000b26 <printf>
    if(fault_addr >= KERNBASE) {
    80001e78:	fe843703          	ld	a4,-24(s0)
    80001e7c:	800007b7          	lui	a5,0x80000
    80001e80:	fff7c793          	not	a5,a5
    80001e84:	00e7fa63          	bgeu	a5,a4,80001e98 <handle_instruction_page_fault+0x76>
        panic("Instruction page fault in kernel space");
    80001e88:	00003517          	auipc	a0,0x3
    80001e8c:	c1050513          	add	a0,a0,-1008 # 80004a98 <etext+0xa98>
    80001e90:	fffff097          	auipc	ra,0xfffff
    80001e94:	f90080e7          	jalr	-112(ra) # 80000e20 <panic>
    printf("TODO: Implement demand paging for instruction fault\n");
    80001e98:	00003517          	auipc	a0,0x3
    80001e9c:	c2850513          	add	a0,a0,-984 # 80004ac0 <etext+0xac0>
    80001ea0:	fffff097          	auipc	ra,0xfffff
    80001ea4:	c86080e7          	jalr	-890(ra) # 80000b26 <printf>
    panic("Instruction page fault not handled");
    80001ea8:	00003517          	auipc	a0,0x3
    80001eac:	c5050513          	add	a0,a0,-944 # 80004af8 <etext+0xaf8>
    80001eb0:	fffff097          	auipc	ra,0xfffff
    80001eb4:	f70080e7          	jalr	-144(ra) # 80000e20 <panic>

0000000080001eb8 <handle_load_page_fault>:
void handle_load_page_fault(struct trapframe *tf) {
    80001eb8:	7179                	add	sp,sp,-48
    80001eba:	f406                	sd	ra,40(sp)
    80001ebc:	f022                	sd	s0,32(sp)
    80001ebe:	1800                	add	s0,sp,48
    80001ec0:	fca43c23          	sd	a0,-40(s0)
    uint64 fault_addr = r_stval();  // 故障地址
    80001ec4:	00000097          	auipc	ra,0x0
    80001ec8:	c20080e7          	jalr	-992(ra) # 80001ae4 <r_stval>
    80001ecc:	fea43423          	sd	a0,-24(s0)
    printf("\n=== Load Page Fault ===\n");
    80001ed0:	00003517          	auipc	a0,0x3
    80001ed4:	c5050513          	add	a0,a0,-944 # 80004b20 <etext+0xb20>
    80001ed8:	fffff097          	auipc	ra,0xfffff
    80001edc:	c4e080e7          	jalr	-946(ra) # 80000b26 <printf>
    printf("Fault address: %p\n", (void*)fault_addr);
    80001ee0:	fe843783          	ld	a5,-24(s0)
    80001ee4:	85be                	mv	a1,a5
    80001ee6:	00003517          	auipc	a0,0x3
    80001eea:	b9250513          	add	a0,a0,-1134 # 80004a78 <etext+0xa78>
    80001eee:	fffff097          	auipc	ra,0xfffff
    80001ef2:	c38080e7          	jalr	-968(ra) # 80000b26 <printf>
    printf("PC: %p\n", (void*)tf->sepc);
    80001ef6:	fd843783          	ld	a5,-40(s0)
    80001efa:	7ffc                	ld	a5,248(a5)
    80001efc:	85be                	mv	a1,a5
    80001efe:	00003517          	auipc	a0,0x3
    80001f02:	b9250513          	add	a0,a0,-1134 # 80004a90 <etext+0xa90>
    80001f06:	fffff097          	auipc	ra,0xfffff
    80001f0a:	c20080e7          	jalr	-992(ra) # 80000b26 <printf>
    printf("Tried to read from unmapped address\n");
    80001f0e:	00003517          	auipc	a0,0x3
    80001f12:	c3250513          	add	a0,a0,-974 # 80004b40 <etext+0xb40>
    80001f16:	fffff097          	auipc	ra,0xfffff
    80001f1a:	c10080e7          	jalr	-1008(ra) # 80000b26 <printf>
    panic("Load page fault");
    80001f1e:	00003517          	auipc	a0,0x3
    80001f22:	c4a50513          	add	a0,a0,-950 # 80004b68 <etext+0xb68>
    80001f26:	fffff097          	auipc	ra,0xfffff
    80001f2a:	efa080e7          	jalr	-262(ra) # 80000e20 <panic>

0000000080001f2e <handle_store_page_fault>:
void handle_store_page_fault(struct trapframe *tf) {
    80001f2e:	7179                	add	sp,sp,-48
    80001f30:	f406                	sd	ra,40(sp)
    80001f32:	f022                	sd	s0,32(sp)
    80001f34:	1800                	add	s0,sp,48
    80001f36:	fca43c23          	sd	a0,-40(s0)
    uint64 fault_addr = r_stval();  // 故障地址
    80001f3a:	00000097          	auipc	ra,0x0
    80001f3e:	baa080e7          	jalr	-1110(ra) # 80001ae4 <r_stval>
    80001f42:	fea43423          	sd	a0,-24(s0)
    printf("\n=== Store Page Fault ===\n");
    80001f46:	00003517          	auipc	a0,0x3
    80001f4a:	c3250513          	add	a0,a0,-974 # 80004b78 <etext+0xb78>
    80001f4e:	fffff097          	auipc	ra,0xfffff
    80001f52:	bd8080e7          	jalr	-1064(ra) # 80000b26 <printf>
    printf("Fault address: %p\n", (void*)fault_addr);
    80001f56:	fe843783          	ld	a5,-24(s0)
    80001f5a:	85be                	mv	a1,a5
    80001f5c:	00003517          	auipc	a0,0x3
    80001f60:	b1c50513          	add	a0,a0,-1252 # 80004a78 <etext+0xa78>
    80001f64:	fffff097          	auipc	ra,0xfffff
    80001f68:	bc2080e7          	jalr	-1086(ra) # 80000b26 <printf>
    printf("PC: %p\n", (void*)tf->sepc);
    80001f6c:	fd843783          	ld	a5,-40(s0)
    80001f70:	7ffc                	ld	a5,248(a5)
    80001f72:	85be                	mv	a1,a5
    80001f74:	00003517          	auipc	a0,0x3
    80001f78:	b1c50513          	add	a0,a0,-1252 # 80004a90 <etext+0xa90>
    80001f7c:	fffff097          	auipc	ra,0xfffff
    80001f80:	baa080e7          	jalr	-1110(ra) # 80000b26 <printf>
    printf("Tried to write to unmapped or read-only address\n");
    80001f84:	00003517          	auipc	a0,0x3
    80001f88:	c1450513          	add	a0,a0,-1004 # 80004b98 <etext+0xb98>
    80001f8c:	fffff097          	auipc	ra,0xfffff
    80001f90:	b9a080e7          	jalr	-1126(ra) # 80000b26 <printf>
    if(fault_addr >= KERNBASE && fault_addr < (uint64)etext) {
    80001f94:	fe843703          	ld	a4,-24(s0)
    80001f98:	800007b7          	lui	a5,0x80000
    80001f9c:	fff7c793          	not	a5,a5
    80001fa0:	02e7f263          	bgeu	a5,a4,80001fc4 <handle_store_page_fault+0x96>
    80001fa4:	00002797          	auipc	a5,0x2
    80001fa8:	05c78793          	add	a5,a5,92 # 80004000 <etext>
    80001fac:	fe843703          	ld	a4,-24(s0)
    80001fb0:	00f77a63          	bgeu	a4,a5,80001fc4 <handle_store_page_fault+0x96>
        printf("Attempted to write to read-only kernel text segment!\n");
    80001fb4:	00003517          	auipc	a0,0x3
    80001fb8:	c1c50513          	add	a0,a0,-996 # 80004bd0 <etext+0xbd0>
    80001fbc:	fffff097          	auipc	ra,0xfffff
    80001fc0:	b6a080e7          	jalr	-1174(ra) # 80000b26 <printf>
    panic("Store page fault");
    80001fc4:	00003517          	auipc	a0,0x3
    80001fc8:	c4450513          	add	a0,a0,-956 # 80004c08 <etext+0xc08>
    80001fcc:	fffff097          	auipc	ra,0xfffff
    80001fd0:	e54080e7          	jalr	-428(ra) # 80000e20 <panic>

0000000080001fd4 <handle_exception>:
void handle_exception(struct trapframe *tf) {
    80001fd4:	7139                	add	sp,sp,-64
    80001fd6:	fc06                	sd	ra,56(sp)
    80001fd8:	f822                	sd	s0,48(sp)
    80001fda:	f426                	sd	s1,40(sp)
    80001fdc:	0080                	add	s0,sp,64
    80001fde:	fca43423          	sd	a0,-56(s0)
    uint64 cause = r_scause();
    80001fe2:	00000097          	auipc	ra,0x0
    80001fe6:	ae8080e7          	jalr	-1304(ra) # 80001aca <r_scause>
    80001fea:	fca43c23          	sd	a0,-40(s0)
    
    printf("\n[Exception Handler] cause=%d (%s)\n", 
    80001fee:	fd843783          	ld	a5,-40(s0)
    80001ff2:	0007849b          	sext.w	s1,a5
    80001ff6:	fd843503          	ld	a0,-40(s0)
    80001ffa:	00000097          	auipc	ra,0x0
    80001ffe:	2f0080e7          	jalr	752(ra) # 800022ea <trap_cause_name>
    80002002:	87aa                	mv	a5,a0
    80002004:	863e                	mv	a2,a5
    80002006:	85a6                	mv	a1,s1
    80002008:	00003517          	auipc	a0,0x3
    8000200c:	c1850513          	add	a0,a0,-1000 # 80004c20 <etext+0xc20>
    80002010:	fffff097          	auipc	ra,0xfffff
    80002014:	b16080e7          	jalr	-1258(ra) # 80000b26 <printf>
           (int)cause, trap_cause_name(cause));
    
    switch(cause) {
    80002018:	fd843703          	ld	a4,-40(s0)
    8000201c:	47bd                	li	a5,15
    8000201e:	1ae7ed63          	bltu	a5,a4,800021d8 <handle_exception+0x204>
    80002022:	fd843783          	ld	a5,-40(s0)
    80002026:	00279713          	sll	a4,a5,0x2
    8000202a:	00003797          	auipc	a5,0x3
    8000202e:	dc278793          	add	a5,a5,-574 # 80004dec <etext+0xdec>
    80002032:	97ba                	add	a5,a5,a4
    80002034:	439c                	lw	a5,0(a5)
    80002036:	0007871b          	sext.w	a4,a5
    8000203a:	00003797          	auipc	a5,0x3
    8000203e:	db278793          	add	a5,a5,-590 # 80004dec <etext+0xdec>
    80002042:	97ba                	add	a5,a5,a4
    80002044:	8782                	jr	a5
        case CAUSE_USER_ECALL:           // 8: 用户模式系统调用
        case CAUSE_SUPERVISOR_ECALL:     // 9: 监督模式系统调用
            handle_syscall(tf);
    80002046:	fc843503          	ld	a0,-56(s0)
    8000204a:	00000097          	auipc	ra,0x0
    8000204e:	d36080e7          	jalr	-714(ra) # 80001d80 <handle_syscall>
            break;
    80002052:	aacd                	j	80002244 <handle_exception+0x270>
            
        case CAUSE_FETCH_PAGE_FAULT:     // 12: 指令页故障
            handle_instruction_page_fault(tf);
    80002054:	fc843503          	ld	a0,-56(s0)
    80002058:	00000097          	auipc	ra,0x0
    8000205c:	dca080e7          	jalr	-566(ra) # 80001e22 <handle_instruction_page_fault>
            break;
    80002060:	a2d5                	j	80002244 <handle_exception+0x270>
            
        case CAUSE_LOAD_PAGE_FAULT:      // 13: 加载页故障
            handle_load_page_fault(tf);
    80002062:	fc843503          	ld	a0,-56(s0)
    80002066:	00000097          	auipc	ra,0x0
    8000206a:	e52080e7          	jalr	-430(ra) # 80001eb8 <handle_load_page_fault>
            break;
    8000206e:	aad9                	j	80002244 <handle_exception+0x270>
            
        case CAUSE_STORE_PAGE_FAULT:     // 15: 存储页故障
            handle_store_page_fault(tf);
    80002070:	fc843503          	ld	a0,-56(s0)
    80002074:	00000097          	auipc	ra,0x0
    80002078:	eba080e7          	jalr	-326(ra) # 80001f2e <handle_store_page_fault>
            break;
    8000207c:	a2e1                	j	80002244 <handle_exception+0x270>
            
        case CAUSE_ILLEGAL_INSTRUCTION:  // 2: 非法指令
            printf("\n=== Illegal Instruction ===\n");
    8000207e:	00003517          	auipc	a0,0x3
    80002082:	bca50513          	add	a0,a0,-1078 # 80004c48 <etext+0xc48>
    80002086:	fffff097          	auipc	ra,0xfffff
    8000208a:	aa0080e7          	jalr	-1376(ra) # 80000b26 <printf>
            printf("PC: %p\n", (void*)tf->sepc);
    8000208e:	fc843783          	ld	a5,-56(s0)
    80002092:	7ffc                	ld	a5,248(a5)
    80002094:	85be                	mv	a1,a5
    80002096:	00003517          	auipc	a0,0x3
    8000209a:	9fa50513          	add	a0,a0,-1542 # 80004a90 <etext+0xa90>
    8000209e:	fffff097          	auipc	ra,0xfffff
    800020a2:	a88080e7          	jalr	-1400(ra) # 80000b26 <printf>
            printf("Instruction value: %p\n", (void*)r_stval());
    800020a6:	00000097          	auipc	ra,0x0
    800020aa:	a3e080e7          	jalr	-1474(ra) # 80001ae4 <r_stval>
    800020ae:	87aa                	mv	a5,a0
    800020b0:	85be                	mv	a1,a5
    800020b2:	00003517          	auipc	a0,0x3
    800020b6:	bb650513          	add	a0,a0,-1098 # 80004c68 <etext+0xc68>
    800020ba:	fffff097          	auipc	ra,0xfffff
    800020be:	a6c080e7          	jalr	-1428(ra) # 80000b26 <printf>
            panic("Illegal instruction");
    800020c2:	00003517          	auipc	a0,0x3
    800020c6:	bbe50513          	add	a0,a0,-1090 # 80004c80 <etext+0xc80>
    800020ca:	fffff097          	auipc	ra,0xfffff
    800020ce:	d56080e7          	jalr	-682(ra) # 80000e20 <panic>
            break;
            
        case CAUSE_BREAKPOINT:           // 3: 断点
            printf("\n=== Breakpoint ===\n");
    800020d2:	00003517          	auipc	a0,0x3
    800020d6:	bc650513          	add	a0,a0,-1082 # 80004c98 <etext+0xc98>
    800020da:	fffff097          	auipc	ra,0xfffff
    800020de:	a4c080e7          	jalr	-1460(ra) # 80000b26 <printf>
            printf("PC: %p\n", (void*)tf->sepc);
    800020e2:	fc843783          	ld	a5,-56(s0)
    800020e6:	7ffc                	ld	a5,248(a5)
    800020e8:	85be                	mv	a1,a5
    800020ea:	00003517          	auipc	a0,0x3
    800020ee:	9a650513          	add	a0,a0,-1626 # 80004a90 <etext+0xa90>
    800020f2:	fffff097          	auipc	ra,0xfffff
    800020f6:	a34080e7          	jalr	-1484(ra) # 80000b26 <printf>
            // 跳过 ebreak 指令（2字节压缩指令）
            tf->sepc += 2;
    800020fa:	fc843783          	ld	a5,-56(s0)
    800020fe:	7ffc                	ld	a5,248(a5)
    80002100:	00278713          	add	a4,a5,2
    80002104:	fc843783          	ld	a5,-56(s0)
    80002108:	fff8                	sd	a4,248(a5)
            printf("Breakpoint handled, continuing from %p\n", (void*)tf->sepc);
    8000210a:	fc843783          	ld	a5,-56(s0)
    8000210e:	7ffc                	ld	a5,248(a5)
    80002110:	85be                	mv	a1,a5
    80002112:	00003517          	auipc	a0,0x3
    80002116:	b9e50513          	add	a0,a0,-1122 # 80004cb0 <etext+0xcb0>
    8000211a:	fffff097          	auipc	ra,0xfffff
    8000211e:	a0c080e7          	jalr	-1524(ra) # 80000b26 <printf>
            break;
    80002122:	a20d                	j	80002244 <handle_exception+0x270>
            
        case CAUSE_MISALIGNED_FETCH:     // 0: 指令地址未对齐
            printf("\n=== Misaligned Instruction Fetch ===\n");
    80002124:	00003517          	auipc	a0,0x3
    80002128:	bb450513          	add	a0,a0,-1100 # 80004cd8 <etext+0xcd8>
    8000212c:	fffff097          	auipc	ra,0xfffff
    80002130:	9fa080e7          	jalr	-1542(ra) # 80000b26 <printf>
            printf("Address: %p\n", (void*)r_stval());
    80002134:	00000097          	auipc	ra,0x0
    80002138:	9b0080e7          	jalr	-1616(ra) # 80001ae4 <r_stval>
    8000213c:	87aa                	mv	a5,a0
    8000213e:	85be                	mv	a1,a5
    80002140:	00003517          	auipc	a0,0x3
    80002144:	bc050513          	add	a0,a0,-1088 # 80004d00 <etext+0xd00>
    80002148:	fffff097          	auipc	ra,0xfffff
    8000214c:	9de080e7          	jalr	-1570(ra) # 80000b26 <printf>
            panic("Misaligned instruction fetch");
    80002150:	00003517          	auipc	a0,0x3
    80002154:	bc050513          	add	a0,a0,-1088 # 80004d10 <etext+0xd10>
    80002158:	fffff097          	auipc	ra,0xfffff
    8000215c:	cc8080e7          	jalr	-824(ra) # 80000e20 <panic>
            break;
            
        case CAUSE_MISALIGNED_LOAD:      // 4: 加载地址未对齐
            printf("\n=== Misaligned Load ===\n");
    80002160:	00003517          	auipc	a0,0x3
    80002164:	bd050513          	add	a0,a0,-1072 # 80004d30 <etext+0xd30>
    80002168:	fffff097          	auipc	ra,0xfffff
    8000216c:	9be080e7          	jalr	-1602(ra) # 80000b26 <printf>
            printf("Address: %p\n", (void*)r_stval());
    80002170:	00000097          	auipc	ra,0x0
    80002174:	974080e7          	jalr	-1676(ra) # 80001ae4 <r_stval>
    80002178:	87aa                	mv	a5,a0
    8000217a:	85be                	mv	a1,a5
    8000217c:	00003517          	auipc	a0,0x3
    80002180:	b8450513          	add	a0,a0,-1148 # 80004d00 <etext+0xd00>
    80002184:	fffff097          	auipc	ra,0xfffff
    80002188:	9a2080e7          	jalr	-1630(ra) # 80000b26 <printf>
            panic("Misaligned load");
    8000218c:	00003517          	auipc	a0,0x3
    80002190:	bc450513          	add	a0,a0,-1084 # 80004d50 <etext+0xd50>
    80002194:	fffff097          	auipc	ra,0xfffff
    80002198:	c8c080e7          	jalr	-884(ra) # 80000e20 <panic>
            break;
            
        case CAUSE_MISALIGNED_STORE:     // 6: 存储地址未对齐
            printf("\n=== Misaligned Store ===\n");
    8000219c:	00003517          	auipc	a0,0x3
    800021a0:	bc450513          	add	a0,a0,-1084 # 80004d60 <etext+0xd60>
    800021a4:	fffff097          	auipc	ra,0xfffff
    800021a8:	982080e7          	jalr	-1662(ra) # 80000b26 <printf>
            printf("Address: %p\n", (void*)r_stval());
    800021ac:	00000097          	auipc	ra,0x0
    800021b0:	938080e7          	jalr	-1736(ra) # 80001ae4 <r_stval>
    800021b4:	87aa                	mv	a5,a0
    800021b6:	85be                	mv	a1,a5
    800021b8:	00003517          	auipc	a0,0x3
    800021bc:	b4850513          	add	a0,a0,-1208 # 80004d00 <etext+0xd00>
    800021c0:	fffff097          	auipc	ra,0xfffff
    800021c4:	966080e7          	jalr	-1690(ra) # 80000b26 <printf>
            panic("Misaligned store");
    800021c8:	00003517          	auipc	a0,0x3
    800021cc:	bb850513          	add	a0,a0,-1096 # 80004d80 <etext+0xd80>
    800021d0:	fffff097          	auipc	ra,0xfffff
    800021d4:	c50080e7          	jalr	-944(ra) # 80000e20 <panic>
            break;
            
        default:
            printf("\n=== Unknown Exception ===\n");
    800021d8:	00003517          	auipc	a0,0x3
    800021dc:	bc050513          	add	a0,a0,-1088 # 80004d98 <etext+0xd98>
    800021e0:	fffff097          	auipc	ra,0xfffff
    800021e4:	946080e7          	jalr	-1722(ra) # 80000b26 <printf>
            printf("cause: %d\n", (int)cause);
    800021e8:	fd843783          	ld	a5,-40(s0)
    800021ec:	2781                	sext.w	a5,a5
    800021ee:	85be                	mv	a1,a5
    800021f0:	00003517          	auipc	a0,0x3
    800021f4:	bc850513          	add	a0,a0,-1080 # 80004db8 <etext+0xdb8>
    800021f8:	fffff097          	auipc	ra,0xfffff
    800021fc:	92e080e7          	jalr	-1746(ra) # 80000b26 <printf>
            printf("PC: %p\n", (void*)tf->sepc);
    80002200:	fc843783          	ld	a5,-56(s0)
    80002204:	7ffc                	ld	a5,248(a5)
    80002206:	85be                	mv	a1,a5
    80002208:	00003517          	auipc	a0,0x3
    8000220c:	88850513          	add	a0,a0,-1912 # 80004a90 <etext+0xa90>
    80002210:	fffff097          	auipc	ra,0xfffff
    80002214:	916080e7          	jalr	-1770(ra) # 80000b26 <printf>
            printf("stval: %p\n", (void*)r_stval());
    80002218:	00000097          	auipc	ra,0x0
    8000221c:	8cc080e7          	jalr	-1844(ra) # 80001ae4 <r_stval>
    80002220:	87aa                	mv	a5,a0
    80002222:	85be                	mv	a1,a5
    80002224:	00003517          	auipc	a0,0x3
    80002228:	ba450513          	add	a0,a0,-1116 # 80004dc8 <etext+0xdc8>
    8000222c:	fffff097          	auipc	ra,0xfffff
    80002230:	8fa080e7          	jalr	-1798(ra) # 80000b26 <printf>
            panic("Unknown exception");
    80002234:	00003517          	auipc	a0,0x3
    80002238:	ba450513          	add	a0,a0,-1116 # 80004dd8 <etext+0xdd8>
    8000223c:	fffff097          	auipc	ra,0xfffff
    80002240:	be4080e7          	jalr	-1052(ra) # 80000e20 <panic>
    }
}
    80002244:	0001                	nop
    80002246:	70e2                	ld	ra,56(sp)
    80002248:	7442                	ld	s0,48(sp)
    8000224a:	74a2                	ld	s1,40(sp)
    8000224c:	6121                	add	sp,sp,64
    8000224e:	8082                	ret

0000000080002250 <kerneltrap>:
// ==================== 内核态中断/异常处理入口 ====================
// 从kernelvec.S调用，此时trapframe已保存在内核栈上
// 修改 kerneltrap 函数签名
void kerneltrap(struct trapframe *tf)  // ← 添加参数
{
    80002250:	7179                	add	sp,sp,-48
    80002252:	f406                	sd	ra,40(sp)
    80002254:	f022                	sd	s0,32(sp)
    80002256:	1800                	add	s0,sp,48
    80002258:	fca43c23          	sd	a0,-40(s0)
    uint64 sstatus = r_sstatus();
    8000225c:	fffff097          	auipc	ra,0xfffff
    80002260:	7d2080e7          	jalr	2002(ra) # 80001a2e <r_sstatus>
    80002264:	fea43423          	sd	a0,-24(s0)
    
    // 安全检查
    if((sstatus & SSTATUS_SPP) == 0) {
    80002268:	fe843783          	ld	a5,-24(s0)
    8000226c:	1007f793          	and	a5,a5,256
    80002270:	eb89                	bnez	a5,80002282 <kerneltrap+0x32>
        panic("kerneltrap: not from supervisor mode");
    80002272:	00003517          	auipc	a0,0x3
    80002276:	bbe50513          	add	a0,a0,-1090 # 80004e30 <etext+0xe30>
    8000227a:	fffff097          	auipc	ra,0xfffff
    8000227e:	ba6080e7          	jalr	-1114(ra) # 80000e20 <panic>
    }
    
    if(sstatus & SSTATUS_SIE) {
    80002282:	fe843783          	ld	a5,-24(s0)
    80002286:	8b89                	and	a5,a5,2
    80002288:	cb89                	beqz	a5,8000229a <kerneltrap+0x4a>
        panic("kerneltrap: interrupts enabled");
    8000228a:	00003517          	auipc	a0,0x3
    8000228e:	bce50513          	add	a0,a0,-1074 # 80004e58 <etext+0xe58>
    80002292:	fffff097          	auipc	ra,0xfffff
    80002296:	b8e080e7          	jalr	-1138(ra) # 80000e20 <panic>
    }
    
    // 处理设备中断
    int is_device_interrupt = devintr();
    8000229a:	00000097          	auipc	ra,0x0
    8000229e:	9c6080e7          	jalr	-1594(ra) # 80001c60 <devintr>
    800022a2:	87aa                	mv	a5,a0
    800022a4:	fef42223          	sw	a5,-28(s0)
    
    if(!is_device_interrupt) {
    800022a8:	fe442783          	lw	a5,-28(s0)
    800022ac:	2781                	sext.w	a5,a5
    800022ae:	e39d                	bnez	a5,800022d4 <kerneltrap+0x84>
        // 异常处理
        exception_count++;
    800022b0:	00007797          	auipc	a5,0x7
    800022b4:	e1078793          	add	a5,a5,-496 # 800090c0 <exception_count>
    800022b8:	639c                	ld	a5,0(a5)
    800022ba:	00178713          	add	a4,a5,1
    800022be:	00007797          	auipc	a5,0x7
    800022c2:	e0278793          	add	a5,a5,-510 # 800090c0 <exception_count>
    800022c6:	e398                	sd	a4,0(a5)
        
        // 直接使用传入的 trapframe 指针（地址正确！）
        handle_exception(tf);
    800022c8:	fd843503          	ld	a0,-40(s0)
    800022cc:	00000097          	auipc	ra,0x0
    800022d0:	d08080e7          	jalr	-760(ra) # 80001fd4 <handle_exception>
        
        // 不需要写回sepc，kernelvec会自动从栈上恢复
    }
    
    w_sstatus(sstatus);
    800022d4:	fe843503          	ld	a0,-24(s0)
    800022d8:	fffff097          	auipc	ra,0xfffff
    800022dc:	770080e7          	jalr	1904(ra) # 80001a48 <w_sstatus>
}
    800022e0:	0001                	nop
    800022e2:	70a2                	ld	ra,40(sp)
    800022e4:	7402                	ld	s0,32(sp)
    800022e6:	6145                	add	sp,sp,48
    800022e8:	8082                	ret

00000000800022ea <trap_cause_name>:
// ==================== 辅助函数：获取异常/中断原因名称 ====================
const char* trap_cause_name(uint64 cause)
{
    800022ea:	1101                	add	sp,sp,-32
    800022ec:	ec22                	sd	s0,24(sp)
    800022ee:	1000                	add	s0,sp,32
    800022f0:	fea43423          	sd	a0,-24(s0)
    // 检查是中断还是异常
    if(cause & 0x8000000000000000L) {
    800022f4:	fe843783          	ld	a5,-24(s0)
    800022f8:	0807d263          	bgez	a5,8000237c <trap_cause_name+0x92>
        // 中断
        cause = cause & 0xff;
    800022fc:	fe843783          	ld	a5,-24(s0)
    80002300:	0ff7f793          	zext.b	a5,a5
    80002304:	fef43423          	sd	a5,-24(s0)
        switch(cause) {
    80002308:	fe843703          	ld	a4,-24(s0)
    8000230c:	47ad                	li	a5,11
    8000230e:	06e7e263          	bltu	a5,a4,80002372 <trap_cause_name+0x88>
    80002312:	fe843783          	ld	a5,-24(s0)
    80002316:	00279713          	sll	a4,a5,0x2
    8000231a:	00003797          	auipc	a5,0x3
    8000231e:	d5e78793          	add	a5,a5,-674 # 80005078 <etext+0x1078>
    80002322:	97ba                	add	a5,a5,a4
    80002324:	439c                	lw	a5,0(a5)
    80002326:	0007871b          	sext.w	a4,a5
    8000232a:	00003797          	auipc	a5,0x3
    8000232e:	d4e78793          	add	a5,a5,-690 # 80005078 <etext+0x1078>
    80002332:	97ba                	add	a5,a5,a4
    80002334:	8782                	jr	a5
            case IRQ_S_SOFT: return "Supervisor software interrupt";
    80002336:	00003797          	auipc	a5,0x3
    8000233a:	b4278793          	add	a5,a5,-1214 # 80004e78 <etext+0xe78>
    8000233e:	a201                	j	8000243e <trap_cause_name+0x154>
            case IRQ_M_SOFT: return "Machine software interrupt";
    80002340:	00003797          	auipc	a5,0x3
    80002344:	b5878793          	add	a5,a5,-1192 # 80004e98 <etext+0xe98>
    80002348:	a8dd                	j	8000243e <trap_cause_name+0x154>
            case IRQ_S_TIMER: return "Supervisor timer interrupt";
    8000234a:	00003797          	auipc	a5,0x3
    8000234e:	b6e78793          	add	a5,a5,-1170 # 80004eb8 <etext+0xeb8>
    80002352:	a0f5                	j	8000243e <trap_cause_name+0x154>
            case IRQ_M_TIMER: return "Machine timer interrupt";
    80002354:	00003797          	auipc	a5,0x3
    80002358:	b8478793          	add	a5,a5,-1148 # 80004ed8 <etext+0xed8>
    8000235c:	a0cd                	j	8000243e <trap_cause_name+0x154>
            case IRQ_S_EXT: return "Supervisor external interrupt";
    8000235e:	00003797          	auipc	a5,0x3
    80002362:	b9278793          	add	a5,a5,-1134 # 80004ef0 <etext+0xef0>
    80002366:	a8e1                	j	8000243e <trap_cause_name+0x154>
            case IRQ_M_EXT: return "Machine external interrupt";
    80002368:	00003797          	auipc	a5,0x3
    8000236c:	ba878793          	add	a5,a5,-1112 # 80004f10 <etext+0xf10>
    80002370:	a0f9                	j	8000243e <trap_cause_name+0x154>
            default: return "Unknown interrupt";
    80002372:	00003797          	auipc	a5,0x3
    80002376:	bbe78793          	add	a5,a5,-1090 # 80004f30 <etext+0xf30>
    8000237a:	a0d1                	j	8000243e <trap_cause_name+0x154>
        }
    } else {
        // 异常
        switch(cause) {
    8000237c:	fe843703          	ld	a4,-24(s0)
    80002380:	47bd                	li	a5,15
    80002382:	0ae7ea63          	bltu	a5,a4,80002436 <trap_cause_name+0x14c>
    80002386:	fe843783          	ld	a5,-24(s0)
    8000238a:	00279713          	sll	a4,a5,0x2
    8000238e:	00003797          	auipc	a5,0x3
    80002392:	d1a78793          	add	a5,a5,-742 # 800050a8 <etext+0x10a8>
    80002396:	97ba                	add	a5,a5,a4
    80002398:	439c                	lw	a5,0(a5)
    8000239a:	0007871b          	sext.w	a4,a5
    8000239e:	00003797          	auipc	a5,0x3
    800023a2:	d0a78793          	add	a5,a5,-758 # 800050a8 <etext+0x10a8>
    800023a6:	97ba                	add	a5,a5,a4
    800023a8:	8782                	jr	a5
            case CAUSE_MISALIGNED_FETCH: return "Instruction address misaligned";
    800023aa:	00003797          	auipc	a5,0x3
    800023ae:	b9e78793          	add	a5,a5,-1122 # 80004f48 <etext+0xf48>
    800023b2:	a071                	j	8000243e <trap_cause_name+0x154>
            case CAUSE_FETCH_ACCESS: return "Instruction access fault";
    800023b4:	00003797          	auipc	a5,0x3
    800023b8:	bb478793          	add	a5,a5,-1100 # 80004f68 <etext+0xf68>
    800023bc:	a049                	j	8000243e <trap_cause_name+0x154>
            case CAUSE_ILLEGAL_INSTRUCTION: return "Illegal instruction";
    800023be:	00003797          	auipc	a5,0x3
    800023c2:	8c278793          	add	a5,a5,-1854 # 80004c80 <etext+0xc80>
    800023c6:	a8a5                	j	8000243e <trap_cause_name+0x154>
            case CAUSE_BREAKPOINT: return "Breakpoint";
    800023c8:	00003797          	auipc	a5,0x3
    800023cc:	bc078793          	add	a5,a5,-1088 # 80004f88 <etext+0xf88>
    800023d0:	a0bd                	j	8000243e <trap_cause_name+0x154>
            case CAUSE_MISALIGNED_LOAD: return "Load address misaligned";
    800023d2:	00003797          	auipc	a5,0x3
    800023d6:	bc678793          	add	a5,a5,-1082 # 80004f98 <etext+0xf98>
    800023da:	a095                	j	8000243e <trap_cause_name+0x154>
            case CAUSE_LOAD_ACCESS: return "Load access fault";
    800023dc:	00003797          	auipc	a5,0x3
    800023e0:	bd478793          	add	a5,a5,-1068 # 80004fb0 <etext+0xfb0>
    800023e4:	a8a9                	j	8000243e <trap_cause_name+0x154>
            case CAUSE_MISALIGNED_STORE: return "Store address misaligned";
    800023e6:	00003797          	auipc	a5,0x3
    800023ea:	be278793          	add	a5,a5,-1054 # 80004fc8 <etext+0xfc8>
    800023ee:	a881                	j	8000243e <trap_cause_name+0x154>
            case CAUSE_STORE_ACCESS: return "Store access fault";
    800023f0:	00003797          	auipc	a5,0x3
    800023f4:	bf878793          	add	a5,a5,-1032 # 80004fe8 <etext+0xfe8>
    800023f8:	a099                	j	8000243e <trap_cause_name+0x154>
            case CAUSE_USER_ECALL: return "Environment call from U-mode";
    800023fa:	00003797          	auipc	a5,0x3
    800023fe:	c0678793          	add	a5,a5,-1018 # 80005000 <etext+0x1000>
    80002402:	a835                	j	8000243e <trap_cause_name+0x154>
            case CAUSE_SUPERVISOR_ECALL: return "Environment call from S-mode";
    80002404:	00003797          	auipc	a5,0x3
    80002408:	c1c78793          	add	a5,a5,-996 # 80005020 <etext+0x1020>
    8000240c:	a80d                	j	8000243e <trap_cause_name+0x154>
            case CAUSE_MACHINE_ECALL: return "Environment call from M-mode";
    8000240e:	00003797          	auipc	a5,0x3
    80002412:	c3278793          	add	a5,a5,-974 # 80005040 <etext+0x1040>
    80002416:	a025                	j	8000243e <trap_cause_name+0x154>
            case CAUSE_FETCH_PAGE_FAULT: return "Instruction page fault";
    80002418:	00003797          	auipc	a5,0x3
    8000241c:	c4878793          	add	a5,a5,-952 # 80005060 <etext+0x1060>
    80002420:	a839                	j	8000243e <trap_cause_name+0x154>
            case CAUSE_LOAD_PAGE_FAULT: return "Load page fault";
    80002422:	00002797          	auipc	a5,0x2
    80002426:	74678793          	add	a5,a5,1862 # 80004b68 <etext+0xb68>
    8000242a:	a811                	j	8000243e <trap_cause_name+0x154>
            case CAUSE_STORE_PAGE_FAULT: return "Store page fault";
    8000242c:	00002797          	auipc	a5,0x2
    80002430:	7dc78793          	add	a5,a5,2012 # 80004c08 <etext+0xc08>
    80002434:	a029                	j	8000243e <trap_cause_name+0x154>
            default: return "Unknown exception";
    80002436:	00003797          	auipc	a5,0x3
    8000243a:	9a278793          	add	a5,a5,-1630 # 80004dd8 <etext+0xdd8>
        }
    }
}
    8000243e:	853e                	mv	a0,a5
    80002440:	6462                	ld	s0,24(sp)
    80002442:	6105                	add	sp,sp,32
    80002444:	8082                	ret

0000000080002446 <dump_trapframe>:

// ==================== 打印trapframe内容（调试用） ====================
void dump_trapframe(struct trapframe *tf)
{
    80002446:	1101                	add	sp,sp,-32
    80002448:	ec06                	sd	ra,24(sp)
    8000244a:	e822                	sd	s0,16(sp)
    8000244c:	1000                	add	s0,sp,32
    8000244e:	fea43423          	sd	a0,-24(s0)
    printf("=== Trapframe Dump ===\n");
    80002452:	00003517          	auipc	a0,0x3
    80002456:	c9650513          	add	a0,a0,-874 # 800050e8 <etext+0x10e8>
    8000245a:	ffffe097          	auipc	ra,0xffffe
    8000245e:	6cc080e7          	jalr	1740(ra) # 80000b26 <printf>
    printf("ra:  %p  sp:  %p  gp:  %p  tp:  %p\n",
           (void*)tf->ra, (void*)tf->sp, (void*)tf->gp, (void*)tf->tp);
    80002462:	fe843783          	ld	a5,-24(s0)
    80002466:	639c                	ld	a5,0(a5)
    printf("ra:  %p  sp:  %p  gp:  %p  tp:  %p\n",
    80002468:	85be                	mv	a1,a5
           (void*)tf->ra, (void*)tf->sp, (void*)tf->gp, (void*)tf->tp);
    8000246a:	fe843783          	ld	a5,-24(s0)
    8000246e:	679c                	ld	a5,8(a5)
    printf("ra:  %p  sp:  %p  gp:  %p  tp:  %p\n",
    80002470:	863e                	mv	a2,a5
           (void*)tf->ra, (void*)tf->sp, (void*)tf->gp, (void*)tf->tp);
    80002472:	fe843783          	ld	a5,-24(s0)
    80002476:	6b9c                	ld	a5,16(a5)
    printf("ra:  %p  sp:  %p  gp:  %p  tp:  %p\n",
    80002478:	86be                	mv	a3,a5
           (void*)tf->ra, (void*)tf->sp, (void*)tf->gp, (void*)tf->tp);
    8000247a:	fe843783          	ld	a5,-24(s0)
    8000247e:	6f9c                	ld	a5,24(a5)
    printf("ra:  %p  sp:  %p  gp:  %p  tp:  %p\n",
    80002480:	873e                	mv	a4,a5
    80002482:	00003517          	auipc	a0,0x3
    80002486:	c7e50513          	add	a0,a0,-898 # 80005100 <etext+0x1100>
    8000248a:	ffffe097          	auipc	ra,0xffffe
    8000248e:	69c080e7          	jalr	1692(ra) # 80000b26 <printf>
    printf("t0:  %p  t1:  %p  t2:  %p\n",
           (void*)tf->t0, (void*)tf->t1, (void*)tf->t2);
    80002492:	fe843783          	ld	a5,-24(s0)
    80002496:	739c                	ld	a5,32(a5)
    printf("t0:  %p  t1:  %p  t2:  %p\n",
    80002498:	873e                	mv	a4,a5
           (void*)tf->t0, (void*)tf->t1, (void*)tf->t2);
    8000249a:	fe843783          	ld	a5,-24(s0)
    8000249e:	779c                	ld	a5,40(a5)
    printf("t0:  %p  t1:  %p  t2:  %p\n",
    800024a0:	863e                	mv	a2,a5
           (void*)tf->t0, (void*)tf->t1, (void*)tf->t2);
    800024a2:	fe843783          	ld	a5,-24(s0)
    800024a6:	7b9c                	ld	a5,48(a5)
    printf("t0:  %p  t1:  %p  t2:  %p\n",
    800024a8:	86be                	mv	a3,a5
    800024aa:	85ba                	mv	a1,a4
    800024ac:	00003517          	auipc	a0,0x3
    800024b0:	c7c50513          	add	a0,a0,-900 # 80005128 <etext+0x1128>
    800024b4:	ffffe097          	auipc	ra,0xffffe
    800024b8:	672080e7          	jalr	1650(ra) # 80000b26 <printf>
    printf("s0:  %p  s1:  %p\n",
           (void*)tf->s0, (void*)tf->s1);
    800024bc:	fe843783          	ld	a5,-24(s0)
    800024c0:	7f9c                	ld	a5,56(a5)
    printf("s0:  %p  s1:  %p\n",
    800024c2:	873e                	mv	a4,a5
           (void*)tf->s0, (void*)tf->s1);
    800024c4:	fe843783          	ld	a5,-24(s0)
    800024c8:	63bc                	ld	a5,64(a5)
    printf("s0:  %p  s1:  %p\n",
    800024ca:	863e                	mv	a2,a5
    800024cc:	85ba                	mv	a1,a4
    800024ce:	00003517          	auipc	a0,0x3
    800024d2:	c7a50513          	add	a0,a0,-902 # 80005148 <etext+0x1148>
    800024d6:	ffffe097          	auipc	ra,0xffffe
    800024da:	650080e7          	jalr	1616(ra) # 80000b26 <printf>
    printf("a0:  %p  a1:  %p  a2:  %p  a3:  %p\n",
           (void*)tf->a0, (void*)tf->a1, (void*)tf->a2, (void*)tf->a3);
    800024de:	fe843783          	ld	a5,-24(s0)
    800024e2:	67bc                	ld	a5,72(a5)
    printf("a0:  %p  a1:  %p  a2:  %p  a3:  %p\n",
    800024e4:	85be                	mv	a1,a5
           (void*)tf->a0, (void*)tf->a1, (void*)tf->a2, (void*)tf->a3);
    800024e6:	fe843783          	ld	a5,-24(s0)
    800024ea:	6bbc                	ld	a5,80(a5)
    printf("a0:  %p  a1:  %p  a2:  %p  a3:  %p\n",
    800024ec:	863e                	mv	a2,a5
           (void*)tf->a0, (void*)tf->a1, (void*)tf->a2, (void*)tf->a3);
    800024ee:	fe843783          	ld	a5,-24(s0)
    800024f2:	6fbc                	ld	a5,88(a5)
    printf("a0:  %p  a1:  %p  a2:  %p  a3:  %p\n",
    800024f4:	86be                	mv	a3,a5
           (void*)tf->a0, (void*)tf->a1, (void*)tf->a2, (void*)tf->a3);
    800024f6:	fe843783          	ld	a5,-24(s0)
    800024fa:	73bc                	ld	a5,96(a5)
    printf("a0:  %p  a1:  %p  a2:  %p  a3:  %p\n",
    800024fc:	873e                	mv	a4,a5
    800024fe:	00003517          	auipc	a0,0x3
    80002502:	c6250513          	add	a0,a0,-926 # 80005160 <etext+0x1160>
    80002506:	ffffe097          	auipc	ra,0xffffe
    8000250a:	620080e7          	jalr	1568(ra) # 80000b26 <printf>
    printf("a4:  %p  a5:  %p  a6:  %p  a7:  %p\n",
           (void*)tf->a4, (void*)tf->a5, (void*)tf->a6, (void*)tf->a7);
    8000250e:	fe843783          	ld	a5,-24(s0)
    80002512:	77bc                	ld	a5,104(a5)
    printf("a4:  %p  a5:  %p  a6:  %p  a7:  %p\n",
    80002514:	85be                	mv	a1,a5
           (void*)tf->a4, (void*)tf->a5, (void*)tf->a6, (void*)tf->a7);
    80002516:	fe843783          	ld	a5,-24(s0)
    8000251a:	7bbc                	ld	a5,112(a5)
    printf("a4:  %p  a5:  %p  a6:  %p  a7:  %p\n",
    8000251c:	863e                	mv	a2,a5
           (void*)tf->a4, (void*)tf->a5, (void*)tf->a6, (void*)tf->a7);
    8000251e:	fe843783          	ld	a5,-24(s0)
    80002522:	7fbc                	ld	a5,120(a5)
    printf("a4:  %p  a5:  %p  a6:  %p  a7:  %p\n",
    80002524:	86be                	mv	a3,a5
           (void*)tf->a4, (void*)tf->a5, (void*)tf->a6, (void*)tf->a7);
    80002526:	fe843783          	ld	a5,-24(s0)
    8000252a:	63dc                	ld	a5,128(a5)
    printf("a4:  %p  a5:  %p  a6:  %p  a7:  %p\n",
    8000252c:	873e                	mv	a4,a5
    8000252e:	00003517          	auipc	a0,0x3
    80002532:	c5a50513          	add	a0,a0,-934 # 80005188 <etext+0x1188>
    80002536:	ffffe097          	auipc	ra,0xffffe
    8000253a:	5f0080e7          	jalr	1520(ra) # 80000b26 <printf>
    printf("sepc: %p  sstatus: %p\n",
           (void*)tf->sepc, (void*)tf->sstatus);
    8000253e:	fe843783          	ld	a5,-24(s0)
    80002542:	7ffc                	ld	a5,248(a5)
    printf("sepc: %p  sstatus: %p\n",
    80002544:	873e                	mv	a4,a5
           (void*)tf->sepc, (void*)tf->sstatus);
    80002546:	fe843783          	ld	a5,-24(s0)
    8000254a:	1007b783          	ld	a5,256(a5)
    printf("sepc: %p  sstatus: %p\n",
    8000254e:	863e                	mv	a2,a5
    80002550:	85ba                	mv	a1,a4
    80002552:	00003517          	auipc	a0,0x3
    80002556:	c5e50513          	add	a0,a0,-930 # 800051b0 <etext+0x11b0>
    8000255a:	ffffe097          	auipc	ra,0xffffe
    8000255e:	5cc080e7          	jalr	1484(ra) # 80000b26 <printf>
    printf("===================\n");
    80002562:	00003517          	auipc	a0,0x3
    80002566:	c6650513          	add	a0,a0,-922 # 800051c8 <etext+0x11c8>
    8000256a:	ffffe097          	auipc	ra,0xffffe
    8000256e:	5bc080e7          	jalr	1468(ra) # 80000b26 <printf>
}
    80002572:	0001                	nop
    80002574:	60e2                	ld	ra,24(sp)
    80002576:	6442                	ld	s0,16(sp)
    80002578:	6105                	add	sp,sp,32
    8000257a:	8082                	ret

000000008000257c <print_trap_stats>:

// ==================== 中断统计信息 ====================
void print_trap_stats(void)
{
    8000257c:	1141                	add	sp,sp,-16
    8000257e:	e406                	sd	ra,8(sp)
    80002580:	e022                	sd	s0,0(sp)
    80002582:	0800                	add	s0,sp,16
    printf("\n=== Trap Statistics ===\n");
    80002584:	00003517          	auipc	a0,0x3
    80002588:	c5c50513          	add	a0,a0,-932 # 800051e0 <etext+0x11e0>
    8000258c:	ffffe097          	auipc	ra,0xffffe
    80002590:	59a080e7          	jalr	1434(ra) # 80000b26 <printf>
    printf("Timer interrupts:    %d\n", (int)interrupt_counts[IRQ_S_TIMER]);
    80002594:	00007797          	auipc	a5,0x7
    80002598:	aac78793          	add	a5,a5,-1364 # 80009040 <interrupt_counts>
    8000259c:	779c                	ld	a5,40(a5)
    8000259e:	2781                	sext.w	a5,a5
    800025a0:	85be                	mv	a1,a5
    800025a2:	00003517          	auipc	a0,0x3
    800025a6:	c5e50513          	add	a0,a0,-930 # 80005200 <etext+0x1200>
    800025aa:	ffffe097          	auipc	ra,0xffffe
    800025ae:	57c080e7          	jalr	1404(ra) # 80000b26 <printf>
    printf("Software interrupts: %d\n", (int)interrupt_counts[IRQ_S_SOFT]);
    800025b2:	00007797          	auipc	a5,0x7
    800025b6:	a8e78793          	add	a5,a5,-1394 # 80009040 <interrupt_counts>
    800025ba:	679c                	ld	a5,8(a5)
    800025bc:	2781                	sext.w	a5,a5
    800025be:	85be                	mv	a1,a5
    800025c0:	00003517          	auipc	a0,0x3
    800025c4:	c6050513          	add	a0,a0,-928 # 80005220 <etext+0x1220>
    800025c8:	ffffe097          	auipc	ra,0xffffe
    800025cc:	55e080e7          	jalr	1374(ra) # 80000b26 <printf>
    printf("External interrupts: %d\n", (int)interrupt_counts[IRQ_S_EXT]);
    800025d0:	00007797          	auipc	a5,0x7
    800025d4:	a7078793          	add	a5,a5,-1424 # 80009040 <interrupt_counts>
    800025d8:	67bc                	ld	a5,72(a5)
    800025da:	2781                	sext.w	a5,a5
    800025dc:	85be                	mv	a1,a5
    800025de:	00003517          	auipc	a0,0x3
    800025e2:	c6250513          	add	a0,a0,-926 # 80005240 <etext+0x1240>
    800025e6:	ffffe097          	auipc	ra,0xffffe
    800025ea:	540080e7          	jalr	1344(ra) # 80000b26 <printf>
    printf("Exceptions:          %d\n", (int)exception_count);
    800025ee:	00007797          	auipc	a5,0x7
    800025f2:	ad278793          	add	a5,a5,-1326 # 800090c0 <exception_count>
    800025f6:	639c                	ld	a5,0(a5)
    800025f8:	2781                	sext.w	a5,a5
    800025fa:	85be                	mv	a1,a5
    800025fc:	00003517          	auipc	a0,0x3
    80002600:	c6450513          	add	a0,a0,-924 # 80005260 <etext+0x1260>
    80002604:	ffffe097          	auipc	ra,0xffffe
    80002608:	522080e7          	jalr	1314(ra) # 80000b26 <printf>
    printf("====================\n");
    8000260c:	00003517          	auipc	a0,0x3
    80002610:	c7450513          	add	a0,a0,-908 # 80005280 <etext+0x1280>
    80002614:	ffffe097          	auipc	ra,0xffffe
    80002618:	512080e7          	jalr	1298(ra) # 80000b26 <printf>
    8000261c:	0001                	nop
    8000261e:	60a2                	ld	ra,8(sp)
    80002620:	6402                	ld	s0,0(sp)
    80002622:	0141                	add	sp,sp,16
    80002624:	8082                	ret
	...

0000000080002630 <kernelvec>:
.globl kernelvec

.align 4
kernelvec:
    # ========== 分配栈空间 ==========
    addi sp, sp, -264
    80002630:	ef810113          	add	sp,sp,-264

    # ========== 保存所有寄存器（除sp）==========
    sd ra, 0(sp)
    80002634:	e006                	sd	ra,0(sp)
    sd gp, 16(sp)
    80002636:	e80e                	sd	gp,16(sp)
    sd tp, 24(sp)
    80002638:	ec12                	sd	tp,24(sp)
    sd t0, 32(sp)
    8000263a:	f016                	sd	t0,32(sp)
    sd t1, 40(sp)
    8000263c:	f41a                	sd	t1,40(sp)
    sd t2, 48(sp)
    8000263e:	f81e                	sd	t2,48(sp)
    sd s0, 56(sp)
    80002640:	fc22                	sd	s0,56(sp)
    sd s1, 64(sp)
    80002642:	e0a6                	sd	s1,64(sp)
    sd a0, 72(sp)
    80002644:	e4aa                	sd	a0,72(sp)
    sd a1, 80(sp)
    80002646:	e8ae                	sd	a1,80(sp)
    sd a2, 88(sp)
    80002648:	ecb2                	sd	a2,88(sp)
    sd a3, 96(sp)
    8000264a:	f0b6                	sd	a3,96(sp)
    sd a4, 104(sp)
    8000264c:	f4ba                	sd	a4,104(sp)
    sd a5, 112(sp)
    8000264e:	f8be                	sd	a5,112(sp)
    sd a6, 120(sp)
    80002650:	fcc2                	sd	a6,120(sp)
    sd a7, 128(sp)
    80002652:	e146                	sd	a7,128(sp)
    sd s2, 136(sp)
    80002654:	e54a                	sd	s2,136(sp)
    sd s3, 144(sp)
    80002656:	e94e                	sd	s3,144(sp)
    sd s4, 152(sp)
    80002658:	ed52                	sd	s4,152(sp)
    sd s5, 160(sp)
    8000265a:	f156                	sd	s5,160(sp)
    sd s6, 168(sp)
    8000265c:	f55a                	sd	s6,168(sp)
    sd s7, 176(sp)
    8000265e:	f95e                	sd	s7,176(sp)
    sd s8, 184(sp)
    80002660:	fd62                	sd	s8,184(sp)
    sd s9, 192(sp)
    80002662:	e1e6                	sd	s9,192(sp)
    sd s10, 200(sp)
    80002664:	e5ea                	sd	s10,200(sp)
    sd s11, 208(sp)
    80002666:	e9ee                	sd	s11,208(sp)
    sd t3, 216(sp)
    80002668:	edf2                	sd	t3,216(sp)
    sd t4, 224(sp)
    8000266a:	f1f6                	sd	t4,224(sp)
    sd t5, 232(sp)
    8000266c:	f5fa                	sd	t5,232(sp)
    sd t6, 240(sp)
    8000266e:	f9fe                	sd	t6,240(sp)

    # ========== 保存 sepc 和 sstatus ==========
    csrr t0, sepc
    80002670:	141022f3          	csrr	t0,sepc
    sd t0, 248(sp)
    80002674:	fd96                	sd	t0,248(sp)
    
    csrr t1, sstatus
    80002676:	10002373          	csrr	t1,sstatus
    sd t1, 256(sp)
    8000267a:	e21a                	sd	t1,256(sp)

    # ========== 保存原始 sp ==========
    addi t0, sp, 264
    8000267c:	10810293          	add	t0,sp,264
    sd t0, 8(sp)
    80002680:	e416                	sd	t0,8(sp)

    # ========== 关键：把 trapframe 地址作为参数传递 ==========
    # a0 = trapframe 地址（C函数的第一个参数）
    mv a0, sp
    80002682:	850a                	mv	a0,sp
    
    call kerneltrap
    80002684:	00000097          	auipc	ra,0x0
    80002688:	bcc080e7          	jalr	-1076(ra) # 80002250 <kerneltrap>

    # ========== 恢复 sepc 和 sstatus ==========
    ld t0, 248(sp)
    8000268c:	72ee                	ld	t0,248(sp)
    csrw sepc, t0
    8000268e:	14129073          	csrw	sepc,t0
    
    ld t1, 256(sp)
    80002692:	6312                	ld	t1,256(sp)
    csrw sstatus, t1
    80002694:	10031073          	csrw	sstatus,t1

    # ========== 恢复所有寄存器 ==========
    ld ra, 0(sp)
    80002698:	6082                	ld	ra,0(sp)
    ld gp, 16(sp)
    8000269a:	61c2                	ld	gp,16(sp)
    ld tp, 24(sp)
    8000269c:	6262                	ld	tp,24(sp)
    ld t0, 32(sp)
    8000269e:	7282                	ld	t0,32(sp)
    ld t1, 40(sp)
    800026a0:	7322                	ld	t1,40(sp)
    ld t2, 48(sp)
    800026a2:	73c2                	ld	t2,48(sp)
    ld s0, 56(sp)
    800026a4:	7462                	ld	s0,56(sp)
    ld s1, 64(sp)
    800026a6:	6486                	ld	s1,64(sp)
    ld a0, 72(sp)
    800026a8:	6526                	ld	a0,72(sp)
    ld a1, 80(sp)
    800026aa:	65c6                	ld	a1,80(sp)
    ld a2, 88(sp)
    800026ac:	6666                	ld	a2,88(sp)
    ld a3, 96(sp)
    800026ae:	7686                	ld	a3,96(sp)
    ld a4, 104(sp)
    800026b0:	7726                	ld	a4,104(sp)
    ld a5, 112(sp)
    800026b2:	77c6                	ld	a5,112(sp)
    ld a6, 120(sp)
    800026b4:	7866                	ld	a6,120(sp)
    ld a7, 128(sp)
    800026b6:	688a                	ld	a7,128(sp)
    ld s2, 136(sp)
    800026b8:	692a                	ld	s2,136(sp)
    ld s3, 144(sp)
    800026ba:	69ca                	ld	s3,144(sp)
    ld s4, 152(sp)
    800026bc:	6a6a                	ld	s4,152(sp)
    ld s5, 160(sp)
    800026be:	7a8a                	ld	s5,160(sp)
    ld s6, 168(sp)
    800026c0:	7b2a                	ld	s6,168(sp)
    ld s7, 176(sp)
    800026c2:	7bca                	ld	s7,176(sp)
    ld s8, 184(sp)
    800026c4:	7c6a                	ld	s8,184(sp)
    ld s9, 192(sp)
    800026c6:	6c8e                	ld	s9,192(sp)
    ld s10, 200(sp)
    800026c8:	6d2e                	ld	s10,200(sp)
    ld s11, 208(sp)
    800026ca:	6dce                	ld	s11,208(sp)
    ld t3, 216(sp)
    800026cc:	6e6e                	ld	t3,216(sp)
    ld t4, 224(sp)
    800026ce:	7e8e                	ld	t4,224(sp)
    ld t5, 232(sp)
    800026d0:	7f2e                	ld	t5,232(sp)
    ld t6, 240(sp)
    800026d2:	7fce                	ld	t6,240(sp)

    # ========== 恢复 sp 并返回 ==========
    addi sp, sp, 264
    800026d4:	10810113          	add	sp,sp,264
    800026d8:	10200073          	sret
    800026dc:	00000013          	nop

00000000800026e0 <timervec>:

.globl timervec
.align 4
timervec:
    # 交换 a0 和 mscratch
    csrrw a0, mscratch, a0
    800026e0:	34051573          	csrrw	a0,mscratch,a0
    # 现在 a0 指向 timer_scratch 结构
    
    # 保存寄存器
    sd a1, 24(a0)
    800026e4:	ed0c                	sd	a1,24(a0)
    sd a2, 32(a0)
    800026e6:	f110                	sd	a2,32(a0)
    sd a3, 40(a0)
    800026e8:	f514                	sd	a3,40(a0)
    
    # 读取当前 mtime
    li a1, 0x200bff8
    800026ea:	0200c5b7          	lui	a1,0x200c
    800026ee:	35e1                	addw	a1,a1,-8 # 200bff8 <_entry-0x7dff4008>
    ld a2, 0(a1)
    800026f0:	6190                	ld	a2,0(a1)
    
    # 加上时钟间隔
    ld a3, 0(a0)        # 读取 interval
    800026f2:	6114                	ld	a3,0(a0)
    add a2, a2, a3      # next_time = mtime + interval
    800026f4:	9636                	add	a2,a2,a3
    sd a2, 8(a0)        # 保存 next_time
    800026f6:	e510                	sd	a2,8(a0)
    
    # 设置 mtimecmp
    li a1, 0x2004000
    800026f8:	020045b7          	lui	a1,0x2004
    sd a2, 0(a1)
    800026fc:	e190                	sd	a2,0(a1)
    
    # 触发 S 模式软件中断
    li a1, 2
    800026fe:	4589                	li	a1,2
    csrw sip, a1
    80002700:	14459073          	csrw	sip,a1
    
    # 恢复寄存器
    ld a3, 40(a0)
    80002704:	7514                	ld	a3,40(a0)
    ld a2, 32(a0)
    80002706:	7110                	ld	a2,32(a0)
    ld a1, 24(a0)
    80002708:	6d0c                	ld	a1,24(a0)
    
    # 恢复 a0
    csrrw a0, mscratch, a0
    8000270a:	34051573          	csrrw	a0,mscratch,a0
    
    8000270e:	30200073          	mret
    80002712:	0001                	nop
    80002714:	00000013          	nop
    80002718:	00000013          	nop
    8000271c:	00000013          	nop

0000000080002720 <timer_handler>:

// 时钟中断间隔（CPU时钟周期）
static uint64 timer_interval;

// 时钟中断处理函数
static void timer_handler(void) {
    80002720:	1101                	add	sp,sp,-32
    80002722:	ec06                	sd	ra,24(sp)
    80002724:	e822                	sd	s0,16(sp)
    80002726:	1000                	add	s0,sp,32
    ticks++;
    80002728:	00007797          	auipc	a5,0x7
    8000272c:	a2078793          	add	a5,a5,-1504 # 80009148 <ticks>
    80002730:	639c                	ld	a5,0(a5)
    80002732:	00178713          	add	a4,a5,1
    80002736:	00007797          	auipc	a5,0x7
    8000273a:	a1278793          	add	a5,a5,-1518 # 80009148 <ticks>
    8000273e:	e398                	sd	a4,0(a5)
    
    // 每秒输出一次系统运行时间
    if(ticks % 10 == 0) {
    80002740:	00007797          	auipc	a5,0x7
    80002744:	a0878793          	add	a5,a5,-1528 # 80009148 <ticks>
    80002748:	6398                	ld	a4,0(a5)
    8000274a:	47a9                	li	a5,10
    8000274c:	02f777b3          	remu	a5,a4,a5
    80002750:	e79d                	bnez	a5,8000277e <timer_handler+0x5e>
        uint64 seconds = ticks / 10;
    80002752:	00007797          	auipc	a5,0x7
    80002756:	9f678793          	add	a5,a5,-1546 # 80009148 <ticks>
    8000275a:	6398                	ld	a4,0(a5)
    8000275c:	47a9                	li	a5,10
    8000275e:	02f757b3          	divu	a5,a4,a5
    80002762:	fef43423          	sd	a5,-24(s0)
        printf("[Timer] System uptime: %d seconds\n", (int)seconds);
    80002766:	fe843783          	ld	a5,-24(s0)
    8000276a:	2781                	sext.w	a5,a5
    8000276c:	85be                	mv	a1,a5
    8000276e:	00003517          	auipc	a0,0x3
    80002772:	b2a50513          	add	a0,a0,-1238 # 80005298 <etext+0x1298>
    80002776:	ffffe097          	auipc	ra,0xffffe
    8000277a:	3b0080e7          	jalr	944(ra) # 80000b26 <printf>
    }
    
    // ========== 关键：触发进程调度 ==========
    timer_tick();  // 在proc.c中实现，检查是否需要调度
    8000277e:	00001097          	auipc	ra,0x1
    80002782:	996080e7          	jalr	-1642(ra) # 80003114 <timer_tick>
}
    80002786:	0001                	nop
    80002788:	60e2                	ld	ra,24(sp)
    8000278a:	6442                	ld	s0,16(sp)
    8000278c:	6105                	add	sp,sp,32
    8000278e:	8082                	ret

0000000080002790 <timer_init>:

// 初始化时钟系统
void timer_init(void) {
    80002790:	1141                	add	sp,sp,-16
    80002792:	e406                	sd	ra,8(sp)
    80002794:	e022                	sd	s0,0(sp)
    80002796:	0800                	add	s0,sp,16
    printf("Initializing timer system...\n");
    80002798:	00003517          	auipc	a0,0x3
    8000279c:	b2850513          	add	a0,a0,-1240 # 800052c0 <etext+0x12c0>
    800027a0:	ffffe097          	auipc	ra,0xffffe
    800027a4:	386080e7          	jalr	902(ra) # 80000b26 <printf>
    
    // 计算时钟间隔
    timer_interval = TIMER_FREQ / 1000 * TIMER_INTERVAL_MS;
    800027a8:	00007797          	auipc	a5,0x7
    800027ac:	9a878793          	add	a5,a5,-1624 # 80009150 <timer_interval>
    800027b0:	000f4737          	lui	a4,0xf4
    800027b4:	24070713          	add	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    800027b8:	e398                	sd	a4,0(a5)
    
    printf("Timer frequency: %d Hz\n", TIMER_FREQ);
    800027ba:	009897b7          	lui	a5,0x989
    800027be:	68078593          	add	a1,a5,1664 # 989680 <_entry-0x7f676980>
    800027c2:	00003517          	auipc	a0,0x3
    800027c6:	b1e50513          	add	a0,a0,-1250 # 800052e0 <etext+0x12e0>
    800027ca:	ffffe097          	auipc	ra,0xffffe
    800027ce:	35c080e7          	jalr	860(ra) # 80000b26 <printf>
    printf("Interrupt interval: %d ms\n", TIMER_INTERVAL_MS);
    800027d2:	06400593          	li	a1,100
    800027d6:	00003517          	auipc	a0,0x3
    800027da:	b2250513          	add	a0,a0,-1246 # 800052f8 <etext+0x12f8>
    800027de:	ffffe097          	auipc	ra,0xffffe
    800027e2:	348080e7          	jalr	840(ra) # 80000b26 <printf>
    printf("Interval in cycles: %lu\n", timer_interval);
    800027e6:	00007797          	auipc	a5,0x7
    800027ea:	96a78793          	add	a5,a5,-1686 # 80009150 <timer_interval>
    800027ee:	639c                	ld	a5,0(a5)
    800027f0:	85be                	mv	a1,a5
    800027f2:	00003517          	auipc	a0,0x3
    800027f6:	b2650513          	add	a0,a0,-1242 # 80005318 <etext+0x1318>
    800027fa:	ffffe097          	auipc	ra,0xffffe
    800027fe:	32c080e7          	jalr	812(ra) # 80000b26 <printf>
    
    // 注册时钟中断处理函数
    register_interrupt(IRQ_S_TIMER, timer_handler);
    80002802:	00000597          	auipc	a1,0x0
    80002806:	f1e58593          	add	a1,a1,-226 # 80002720 <timer_handler>
    8000280a:	4515                	li	a0,5
    8000280c:	fffff097          	auipc	ra,0xfffff
    80002810:	3de080e7          	jalr	990(ra) # 80001bea <register_interrupt>
    
    printf("Registered timer interrupt handler\n");
    80002814:	00003517          	auipc	a0,0x3
    80002818:	b2450513          	add	a0,a0,-1244 # 80005338 <etext+0x1338>
    8000281c:	ffffe097          	auipc	ra,0xffffe
    80002820:	30a080e7          	jalr	778(ra) # 80000b26 <printf>
    
    printf("Timer system initialized\n");
    80002824:	00003517          	auipc	a0,0x3
    80002828:	b3c50513          	add	a0,a0,-1220 # 80005360 <etext+0x1360>
    8000282c:	ffffe097          	auipc	ra,0xffffe
    80002830:	2fa080e7          	jalr	762(ra) # 80000b26 <printf>
}
    80002834:	0001                	nop
    80002836:	60a2                	ld	ra,8(sp)
    80002838:	6402                	ld	s0,0(sp)
    8000283a:	0141                	add	sp,sp,16
    8000283c:	8082                	ret

000000008000283e <get_ticks>:

// 获取系统滴答数
uint64 get_ticks(void) {
    8000283e:	1141                	add	sp,sp,-16
    80002840:	e422                	sd	s0,8(sp)
    80002842:	0800                	add	s0,sp,16
    return ticks;
    80002844:	00007797          	auipc	a5,0x7
    80002848:	90478793          	add	a5,a5,-1788 # 80009148 <ticks>
    8000284c:	639c                	ld	a5,0(a5)
}
    8000284e:	853e                	mv	a0,a5
    80002850:	6422                	ld	s0,8(sp)
    80002852:	0141                	add	sp,sp,16
    80002854:	8082                	ret

0000000080002856 <get_uptime_seconds>:

// 获取系统运行时间（秒）
uint64 get_uptime_seconds(void) {
    80002856:	1141                	add	sp,sp,-16
    80002858:	e422                	sd	s0,8(sp)
    8000285a:	0800                	add	s0,sp,16
    return ticks / 10;  // 每10个tick = 1秒
    8000285c:	00007797          	auipc	a5,0x7
    80002860:	8ec78793          	add	a5,a5,-1812 # 80009148 <ticks>
    80002864:	6398                	ld	a4,0(a5)
    80002866:	47a9                	li	a5,10
    80002868:	02f757b3          	divu	a5,a4,a5
    8000286c:	853e                	mv	a0,a5
    8000286e:	6422                	ld	s0,8(sp)
    80002870:	0141                	add	sp,sp,16
    80002872:	8082                	ret

0000000080002874 <r_sstatus>:
    }
    
    p->pid = 0;
    p->parent = 0;
    p->name[0] = 0;
    p->chan = 0;
    80002874:	1101                	add	sp,sp,-32
    80002876:	ec22                	sd	s0,24(sp)
    80002878:	1000                	add	s0,sp,32
    p->killed = 0;
    p->xstate = 0;
    8000287a:	100027f3          	csrr	a5,sstatus
    8000287e:	fef43423          	sd	a5,-24(s0)
    p->state = UNUSED;
    80002882:	fe843783          	ld	a5,-24(s0)
}
    80002886:	853e                	mv	a0,a5
    80002888:	6462                	ld	s0,24(sp)
    8000288a:	6105                	add	sp,sp,32
    8000288c:	8082                	ret

000000008000288e <w_sstatus>:

// ==================== 进程创建 ====================
    8000288e:	1101                	add	sp,sp,-32
    80002890:	ec22                	sd	s0,24(sp)
    80002892:	1000                	add	s0,sp,32
    80002894:	fea43423          	sd	a0,-24(s0)

    80002898:	fe843783          	ld	a5,-24(s0)
    8000289c:	10079073          	csrw	sstatus,a5
// 创建内核线程
    800028a0:	0001                	nop
    800028a2:	6462                	ld	s0,24(sp)
    800028a4:	6105                	add	sp,sp,32
    800028a6:	8082                	ret

00000000800028a8 <intr_on>:
        if(p->pid == pid) {
            p->killed = 1;
            
            // 如果进程在睡眠，唤醒它
            if(p->state == SLEEPING) {
                p->state = RUNNABLE;
    800028a8:	1141                	add	sp,sp,-16
    800028aa:	e406                	sd	ra,8(sp)
    800028ac:	e022                	sd	s0,0(sp)
    800028ae:	0800                	add	s0,sp,16
            }
    800028b0:	00000097          	auipc	ra,0x0
    800028b4:	fc4080e7          	jalr	-60(ra) # 80002874 <r_sstatus>
    800028b8:	87aa                	mv	a5,a0
    800028ba:	0027e793          	or	a5,a5,2
    800028be:	853e                	mv	a0,a5
    800028c0:	00000097          	auipc	ra,0x0
    800028c4:	fce080e7          	jalr	-50(ra) # 8000288e <w_sstatus>
            
    800028c8:	0001                	nop
    800028ca:	60a2                	ld	ra,8(sp)
    800028cc:	6402                	ld	s0,0(sp)
    800028ce:	0141                	add	sp,sp,16
    800028d0:	8082                	ret

00000000800028d2 <safestrcpy>:
void safestrcpy(char *s, const char *t, int n) {
    800028d2:	7179                	add	sp,sp,-48
    800028d4:	f422                	sd	s0,40(sp)
    800028d6:	1800                	add	s0,sp,48
    800028d8:	fea43423          	sd	a0,-24(s0)
    800028dc:	feb43023          	sd	a1,-32(s0)
    800028e0:	87b2                	mv	a5,a2
    800028e2:	fcf42e23          	sw	a5,-36(s0)
    if(n <= 0)
    800028e6:	fdc42783          	lw	a5,-36(s0)
    800028ea:	2781                	sext.w	a5,a5
    800028ec:	04f05563          	blez	a5,80002936 <safestrcpy+0x64>
    while(--n > 0 && (*s++ = *t++) != 0)
    800028f0:	0001                	nop
    800028f2:	fdc42783          	lw	a5,-36(s0)
    800028f6:	37fd                	addw	a5,a5,-1
    800028f8:	fcf42e23          	sw	a5,-36(s0)
    800028fc:	fdc42783          	lw	a5,-36(s0)
    80002900:	2781                	sext.w	a5,a5
    80002902:	02f05563          	blez	a5,8000292c <safestrcpy+0x5a>
    80002906:	fe043703          	ld	a4,-32(s0)
    8000290a:	00170793          	add	a5,a4,1
    8000290e:	fef43023          	sd	a5,-32(s0)
    80002912:	fe843783          	ld	a5,-24(s0)
    80002916:	00178693          	add	a3,a5,1
    8000291a:	fed43423          	sd	a3,-24(s0)
    8000291e:	00074703          	lbu	a4,0(a4)
    80002922:	00e78023          	sb	a4,0(a5)
    80002926:	0007c783          	lbu	a5,0(a5)
    8000292a:	f7e1                	bnez	a5,800028f2 <safestrcpy+0x20>
    *s = 0;
    8000292c:	fe843783          	ld	a5,-24(s0)
    80002930:	00078023          	sb	zero,0(a5)
    80002934:	a011                	j	80002938 <safestrcpy+0x66>
        return;
    80002936:	0001                	nop
}
    80002938:	7422                	ld	s0,40(sp)
    8000293a:	6145                	add	sp,sp,48
    8000293c:	8082                	ret

000000008000293e <mycpu>:
struct cpu* mycpu(void) {
    8000293e:	1141                	add	sp,sp,-16
    80002940:	e422                	sd	s0,8(sp)
    80002942:	0800                	add	s0,sp,16
    return &cpu;
    80002944:	00009797          	auipc	a5,0x9
    80002948:	61478793          	add	a5,a5,1556 # 8000bf58 <cpu>
}
    8000294c:	853e                	mv	a0,a5
    8000294e:	6422                	ld	s0,8(sp)
    80002950:	0141                	add	sp,sp,16
    80002952:	8082                	ret

0000000080002954 <myproc>:
struct proc* myproc(void) {
    80002954:	1101                	add	sp,sp,-32
    80002956:	ec06                	sd	ra,24(sp)
    80002958:	e822                	sd	s0,16(sp)
    8000295a:	1000                	add	s0,sp,32
    struct cpu *c = mycpu();
    8000295c:	00000097          	auipc	ra,0x0
    80002960:	fe2080e7          	jalr	-30(ra) # 8000293e <mycpu>
    80002964:	fea43423          	sd	a0,-24(s0)
    return c->proc;
    80002968:	fe843783          	ld	a5,-24(s0)
    8000296c:	639c                	ld	a5,0(a5)
}
    8000296e:	853e                	mv	a0,a5
    80002970:	60e2                	ld	ra,24(sp)
    80002972:	6442                	ld	s0,16(sp)
    80002974:	6105                	add	sp,sp,32
    80002976:	8082                	ret

0000000080002978 <allocpid>:
static int allocpid(void) {
    80002978:	1101                	add	sp,sp,-32
    8000297a:	ec22                	sd	s0,24(sp)
    8000297c:	1000                	add	s0,sp,32
    int pid = nextpid;
    8000297e:	00003797          	auipc	a5,0x3
    80002982:	1c278793          	add	a5,a5,450 # 80005b40 <nextpid>
    80002986:	439c                	lw	a5,0(a5)
    80002988:	fef42623          	sw	a5,-20(s0)
    nextpid++;
    8000298c:	00003797          	auipc	a5,0x3
    80002990:	1b478793          	add	a5,a5,436 # 80005b40 <nextpid>
    80002994:	439c                	lw	a5,0(a5)
    80002996:	2785                	addw	a5,a5,1
    80002998:	0007871b          	sext.w	a4,a5
    8000299c:	00003797          	auipc	a5,0x3
    800029a0:	1a478793          	add	a5,a5,420 # 80005b40 <nextpid>
    800029a4:	c398                	sw	a4,0(a5)
    return pid;
    800029a6:	fec42783          	lw	a5,-20(s0)
}
    800029aa:	853e                	mv	a0,a5
    800029ac:	6462                	ld	s0,24(sp)
    800029ae:	6105                	add	sp,sp,32
    800029b0:	8082                	ret

00000000800029b2 <procinit>:
void procinit(void) {
    800029b2:	1101                	add	sp,sp,-32
    800029b4:	ec06                	sd	ra,24(sp)
    800029b6:	e822                	sd	s0,16(sp)
    800029b8:	1000                	add	s0,sp,32
    printf("Initializing process subsystem...\n");
    800029ba:	00003517          	auipc	a0,0x3
    800029be:	9c650513          	add	a0,a0,-1594 # 80005380 <etext+0x1380>
    800029c2:	ffffe097          	auipc	ra,0xffffe
    800029c6:	164080e7          	jalr	356(ra) # 80000b26 <printf>
    for(p = proc; p < &proc[NPROC]; p++) {
    800029ca:	00006797          	auipc	a5,0x6
    800029ce:	78e78793          	add	a5,a5,1934 # 80009158 <proc>
    800029d2:	fef43423          	sd	a5,-24(s0)
    800029d6:	a899                	j	80002a2c <procinit+0x7a>
        p->state = UNUSED;
    800029d8:	fe843783          	ld	a5,-24(s0)
    800029dc:	0007a023          	sw	zero,0(a5)
        p->pid = 0;
    800029e0:	fe843783          	ld	a5,-24(s0)
    800029e4:	0007a223          	sw	zero,4(a5)
        p->parent = 0;
    800029e8:	fe843783          	ld	a5,-24(s0)
    800029ec:	0007b423          	sd	zero,8(a5)
        p->chan = 0;
    800029f0:	fe843783          	ld	a5,-24(s0)
    800029f4:	0807b423          	sd	zero,136(a5)
        p->killed = 0;
    800029f8:	fe843783          	ld	a5,-24(s0)
    800029fc:	0807a823          	sw	zero,144(a5)
        p->xstate = 0;
    80002a00:	fe843783          	ld	a5,-24(s0)
    80002a04:	0807aa23          	sw	zero,148(a5)
        p->kstack = 0;
    80002a08:	fe843783          	ld	a5,-24(s0)
    80002a0c:	0807b023          	sd	zero,128(a5)
        p->runtime = 0;
    80002a10:	fe843783          	ld	a5,-24(s0)
    80002a14:	0807bc23          	sd	zero,152(a5)
        p->start_time = 0;
    80002a18:	fe843783          	ld	a5,-24(s0)
    80002a1c:	0a07b023          	sd	zero,160(a5)
    for(p = proc; p < &proc[NPROC]; p++) {
    80002a20:	fe843783          	ld	a5,-24(s0)
    80002a24:	0b878793          	add	a5,a5,184
    80002a28:	fef43423          	sd	a5,-24(s0)
    80002a2c:	fe843703          	ld	a4,-24(s0)
    80002a30:	00009797          	auipc	a5,0x9
    80002a34:	52878793          	add	a5,a5,1320 # 8000bf58 <cpu>
    80002a38:	faf760e3          	bltu	a4,a5,800029d8 <procinit+0x26>
    cpu.proc = 0;
    80002a3c:	00009797          	auipc	a5,0x9
    80002a40:	51c78793          	add	a5,a5,1308 # 8000bf58 <cpu>
    80002a44:	0007b023          	sd	zero,0(a5)
    cpu.noff = 0;
    80002a48:	00009797          	auipc	a5,0x9
    80002a4c:	51078793          	add	a5,a5,1296 # 8000bf58 <cpu>
    80002a50:	0607ac23          	sw	zero,120(a5)
    cpu.intena = 0;
    80002a54:	00009797          	auipc	a5,0x9
    80002a58:	50478793          	add	a5,a5,1284 # 8000bf58 <cpu>
    80002a5c:	0607ae23          	sw	zero,124(a5)
    printf("Process subsystem initialized\n");
    80002a60:	00003517          	auipc	a0,0x3
    80002a64:	94850513          	add	a0,a0,-1720 # 800053a8 <etext+0x13a8>
    80002a68:	ffffe097          	auipc	ra,0xffffe
    80002a6c:	0be080e7          	jalr	190(ra) # 80000b26 <printf>
    printf("Maximum processes: %d\n", NPROC);
    80002a70:	04000593          	li	a1,64
    80002a74:	00003517          	auipc	a0,0x3
    80002a78:	95450513          	add	a0,a0,-1708 # 800053c8 <etext+0x13c8>
    80002a7c:	ffffe097          	auipc	ra,0xffffe
    80002a80:	0aa080e7          	jalr	170(ra) # 80000b26 <printf>
}
    80002a84:	0001                	nop
    80002a86:	60e2                	ld	ra,24(sp)
    80002a88:	6442                	ld	s0,16(sp)
    80002a8a:	6105                	add	sp,sp,32
    80002a8c:	8082                	ret

0000000080002a8e <allocproc>:
static struct proc* allocproc(void) {
    80002a8e:	1101                	add	sp,sp,-32
    80002a90:	ec06                	sd	ra,24(sp)
    80002a92:	e822                	sd	s0,16(sp)
    80002a94:	1000                	add	s0,sp,32
    for(p = proc; p < &proc[NPROC]; p++) {
    80002a96:	00006797          	auipc	a5,0x6
    80002a9a:	6c278793          	add	a5,a5,1730 # 80009158 <proc>
    80002a9e:	fef43423          	sd	a5,-24(s0)
    80002aa2:	a819                	j	80002ab8 <allocproc+0x2a>
        if(p->state == UNUSED) {
    80002aa4:	fe843783          	ld	a5,-24(s0)
    80002aa8:	439c                	lw	a5,0(a5)
    80002aaa:	c38d                	beqz	a5,80002acc <allocproc+0x3e>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002aac:	fe843783          	ld	a5,-24(s0)
    80002ab0:	0b878793          	add	a5,a5,184
    80002ab4:	fef43423          	sd	a5,-24(s0)
    80002ab8:	fe843703          	ld	a4,-24(s0)
    80002abc:	00009797          	auipc	a5,0x9
    80002ac0:	49c78793          	add	a5,a5,1180 # 8000bf58 <cpu>
    80002ac4:	fef760e3          	bltu	a4,a5,80002aa4 <allocproc+0x16>
    return 0;  // 进程表已满
    80002ac8:	4781                	li	a5,0
    80002aca:	a88d                	j	80002b3c <allocproc+0xae>
            goto found;
    80002acc:	0001                	nop
    p->pid = allocpid();
    80002ace:	00000097          	auipc	ra,0x0
    80002ad2:	eaa080e7          	jalr	-342(ra) # 80002978 <allocpid>
    80002ad6:	87aa                	mv	a5,a0
    80002ad8:	873e                	mv	a4,a5
    80002ada:	fe843783          	ld	a5,-24(s0)
    80002ade:	c3d8                	sw	a4,4(a5)
    p->state = USED;
    80002ae0:	fe843783          	ld	a5,-24(s0)
    80002ae4:	4705                	li	a4,1
    80002ae6:	c398                	sw	a4,0(a5)
    p->kstack = (uint64)alloc_page();
    80002ae8:	ffffe097          	auipc	ra,0xffffe
    80002aec:	57a080e7          	jalr	1402(ra) # 80001062 <alloc_page>
    80002af0:	87aa                	mv	a5,a0
    80002af2:	873e                	mv	a4,a5
    80002af4:	fe843783          	ld	a5,-24(s0)
    80002af8:	e3d8                	sd	a4,128(a5)
    if(p->kstack == 0) {
    80002afa:	fe843783          	ld	a5,-24(s0)
    80002afe:	63dc                	ld	a5,128(a5)
    80002b00:	e799                	bnez	a5,80002b0e <allocproc+0x80>
        p->state = UNUSED;
    80002b02:	fe843783          	ld	a5,-24(s0)
    80002b06:	0007a023          	sw	zero,0(a5)
        return 0;
    80002b0a:	4781                	li	a5,0
    80002b0c:	a805                	j	80002b3c <allocproc+0xae>
    p->kstack += KSTACK_SIZE;
    80002b0e:	fe843783          	ld	a5,-24(s0)
    80002b12:	63d8                	ld	a4,128(a5)
    80002b14:	6785                	lui	a5,0x1
    80002b16:	973e                	add	a4,a4,a5
    80002b18:	fe843783          	ld	a5,-24(s0)
    80002b1c:	e3d8                	sd	a4,128(a5)
    p->context.ra = (uint64)forkret;
    80002b1e:	00000717          	auipc	a4,0x0
    80002b22:	3d870713          	add	a4,a4,984 # 80002ef6 <forkret>
    80002b26:	fe843783          	ld	a5,-24(s0)
    80002b2a:	eb98                	sd	a4,16(a5)
    p->context.sp = p->kstack;
    80002b2c:	fe843783          	ld	a5,-24(s0)
    80002b30:	63d8                	ld	a4,128(a5)
    80002b32:	fe843783          	ld	a5,-24(s0)
    80002b36:	ef98                	sd	a4,24(a5)
    return p;
    80002b38:	fe843783          	ld	a5,-24(s0)
}
    80002b3c:	853e                	mv	a0,a5
    80002b3e:	60e2                	ld	ra,24(sp)
    80002b40:	6442                	ld	s0,16(sp)
    80002b42:	6105                	add	sp,sp,32
    80002b44:	8082                	ret

0000000080002b46 <freeproc>:
static void freeproc(struct proc *p) {
    80002b46:	1101                	add	sp,sp,-32
    80002b48:	ec06                	sd	ra,24(sp)
    80002b4a:	e822                	sd	s0,16(sp)
    80002b4c:	1000                	add	s0,sp,32
    80002b4e:	fea43423          	sd	a0,-24(s0)
    if(p->kstack) {
    80002b52:	fe843783          	ld	a5,-24(s0)
    80002b56:	63dc                	ld	a5,128(a5)
    80002b58:	cf99                	beqz	a5,80002b76 <freeproc+0x30>
        free_page((void*)(p->kstack - KSTACK_SIZE));
    80002b5a:	fe843783          	ld	a5,-24(s0)
    80002b5e:	63d8                	ld	a4,128(a5)
    80002b60:	77fd                	lui	a5,0xfffff
    80002b62:	97ba                	add	a5,a5,a4
    80002b64:	853e                	mv	a0,a5
    80002b66:	ffffe097          	auipc	ra,0xffffe
    80002b6a:	55e080e7          	jalr	1374(ra) # 800010c4 <free_page>
        p->kstack = 0;
    80002b6e:	fe843783          	ld	a5,-24(s0)
    80002b72:	0807b023          	sd	zero,128(a5) # fffffffffffff080 <bss_end+0xffffffff7fff3070>
    p->pid = 0;
    80002b76:	fe843783          	ld	a5,-24(s0)
    80002b7a:	0007a223          	sw	zero,4(a5)
    p->parent = 0;
    80002b7e:	fe843783          	ld	a5,-24(s0)
    80002b82:	0007b423          	sd	zero,8(a5)
    p->name[0] = 0;
    80002b86:	fe843783          	ld	a5,-24(s0)
    80002b8a:	0a078423          	sb	zero,168(a5)
    p->chan = 0;
    80002b8e:	fe843783          	ld	a5,-24(s0)
    80002b92:	0807b423          	sd	zero,136(a5)
    p->killed = 0;
    80002b96:	fe843783          	ld	a5,-24(s0)
    80002b9a:	0807a823          	sw	zero,144(a5)
    p->xstate = 0;
    80002b9e:	fe843783          	ld	a5,-24(s0)
    80002ba2:	0807aa23          	sw	zero,148(a5)
    p->state = UNUSED;
    80002ba6:	fe843783          	ld	a5,-24(s0)
    80002baa:	0007a023          	sw	zero,0(a5)
}
    80002bae:	0001                	nop
    80002bb0:	60e2                	ld	ra,24(sp)
    80002bb2:	6442                	ld	s0,16(sp)
    80002bb4:	6105                	add	sp,sp,32
    80002bb6:	8082                	ret

0000000080002bb8 <kthread_create>:
int kthread_create(void (*fn)(void), char *name) {
    80002bb8:	7179                	add	sp,sp,-48
    80002bba:	f406                	sd	ra,40(sp)
    80002bbc:	f022                	sd	s0,32(sp)
    80002bbe:	1800                	add	s0,sp,48
    80002bc0:	fca43c23          	sd	a0,-40(s0)
    80002bc4:	fcb43823          	sd	a1,-48(s0)
    p = allocproc();
    80002bc8:	00000097          	auipc	ra,0x0
    80002bcc:	ec6080e7          	jalr	-314(ra) # 80002a8e <allocproc>
    80002bd0:	fea43423          	sd	a0,-24(s0)
    if(p == 0) {
    80002bd4:	fe843783          	ld	a5,-24(s0)
    80002bd8:	e399                	bnez	a5,80002bde <kthread_create+0x26>
        return -1;
    80002bda:	57fd                	li	a5,-1
    80002bdc:	a0a5                	j	80002c44 <kthread_create+0x8c>
    safestrcpy(p->name, name, sizeof(p->name));
    80002bde:	fe843783          	ld	a5,-24(s0)
    80002be2:	0a878793          	add	a5,a5,168
    80002be6:	4641                	li	a2,16
    80002be8:	fd043583          	ld	a1,-48(s0)
    80002bec:	853e                	mv	a0,a5
    80002bee:	00000097          	auipc	ra,0x0
    80002bf2:	ce4080e7          	jalr	-796(ra) # 800028d2 <safestrcpy>
    p->context.ra = (uint64)forkret;
    80002bf6:	00000717          	auipc	a4,0x0
    80002bfa:	30070713          	add	a4,a4,768 # 80002ef6 <forkret>
    80002bfe:	fe843783          	ld	a5,-24(s0)
    80002c02:	eb98                	sd	a4,16(a5)
    p->context.sp = p->kstack;
    80002c04:	fe843783          	ld	a5,-24(s0)
    80002c08:	63d8                	ld	a4,128(a5)
    80002c0a:	fe843783          	ld	a5,-24(s0)
    80002c0e:	ef98                	sd	a4,24(a5)
    p->context.s0 = (uint64)fn;
    80002c10:	fd843703          	ld	a4,-40(s0)
    80002c14:	fe843783          	ld	a5,-24(s0)
    80002c18:	f398                	sd	a4,32(a5)
    p->state = RUNNABLE;
    80002c1a:	fe843783          	ld	a5,-24(s0)
    80002c1e:	470d                	li	a4,3
    80002c20:	c398                	sw	a4,0(a5)
    printf("Created kernel thread '%s' with PID %d\n", name, p->pid);
    80002c22:	fe843783          	ld	a5,-24(s0)
    80002c26:	43dc                	lw	a5,4(a5)
    80002c28:	863e                	mv	a2,a5
    80002c2a:	fd043583          	ld	a1,-48(s0)
    80002c2e:	00002517          	auipc	a0,0x2
    80002c32:	7b250513          	add	a0,a0,1970 # 800053e0 <etext+0x13e0>
    80002c36:	ffffe097          	auipc	ra,0xffffe
    80002c3a:	ef0080e7          	jalr	-272(ra) # 80000b26 <printf>
    return p->pid;
    80002c3e:	fe843783          	ld	a5,-24(s0)
    80002c42:	43dc                	lw	a5,4(a5)
}
    80002c44:	853e                	mv	a0,a5
    80002c46:	70a2                	ld	ra,40(sp)
    80002c48:	7402                	ld	s0,32(sp)
    80002c4a:	6145                	add	sp,sp,48
    80002c4c:	8082                	ret

0000000080002c4e <exit>:
void exit(int status) {
    80002c4e:	7179                	add	sp,sp,-48
    80002c50:	f406                	sd	ra,40(sp)
    80002c52:	f022                	sd	s0,32(sp)
    80002c54:	1800                	add	s0,sp,48
    80002c56:	87aa                	mv	a5,a0
    80002c58:	fcf42e23          	sw	a5,-36(s0)
    struct proc *p = myproc();
    80002c5c:	00000097          	auipc	ra,0x0
    80002c60:	cf8080e7          	jalr	-776(ra) # 80002954 <myproc>
    80002c64:	fea43023          	sd	a0,-32(s0)
    if(p == initproc) {
    80002c68:	00003797          	auipc	a5,0x3
    80002c6c:	3a878793          	add	a5,a5,936 # 80006010 <initproc>
    80002c70:	639c                	ld	a5,0(a5)
    80002c72:	fe043703          	ld	a4,-32(s0)
    80002c76:	00f71a63          	bne	a4,a5,80002c8a <exit+0x3c>
        panic("init exiting");
    80002c7a:	00002517          	auipc	a0,0x2
    80002c7e:	78e50513          	add	a0,a0,1934 # 80005408 <etext+0x1408>
    80002c82:	ffffe097          	auipc	ra,0xffffe
    80002c86:	19e080e7          	jalr	414(ra) # 80000e20 <panic>
    printf("Process %d (%s) exiting with status %d\n", 
    80002c8a:	fe043783          	ld	a5,-32(s0)
    80002c8e:	43d8                	lw	a4,4(a5)
           p->pid, p->name, status);
    80002c90:	fe043783          	ld	a5,-32(s0)
    80002c94:	0a878793          	add	a5,a5,168
    printf("Process %d (%s) exiting with status %d\n", 
    80002c98:	fdc42683          	lw	a3,-36(s0)
    80002c9c:	863e                	mv	a2,a5
    80002c9e:	85ba                	mv	a1,a4
    80002ca0:	00002517          	auipc	a0,0x2
    80002ca4:	77850513          	add	a0,a0,1912 # 80005418 <etext+0x1418>
    80002ca8:	ffffe097          	auipc	ra,0xffffe
    80002cac:	e7e080e7          	jalr	-386(ra) # 80000b26 <printf>
    p->xstate = status;
    80002cb0:	fe043783          	ld	a5,-32(s0)
    80002cb4:	fdc42703          	lw	a4,-36(s0)
    80002cb8:	08e7aa23          	sw	a4,148(a5)
    for(np = proc; np < &proc[NPROC]; np++) {
    80002cbc:	00006797          	auipc	a5,0x6
    80002cc0:	49c78793          	add	a5,a5,1180 # 80009158 <proc>
    80002cc4:	fef43423          	sd	a5,-24(s0)
    80002cc8:	a081                	j	80002d08 <exit+0xba>
        if(np->parent == p) {
    80002cca:	fe843783          	ld	a5,-24(s0)
    80002cce:	679c                	ld	a5,8(a5)
    80002cd0:	fe043703          	ld	a4,-32(s0)
    80002cd4:	02f71463          	bne	a4,a5,80002cfc <exit+0xae>
            np->parent = initproc;
    80002cd8:	00003797          	auipc	a5,0x3
    80002cdc:	33878793          	add	a5,a5,824 # 80006010 <initproc>
    80002ce0:	6398                	ld	a4,0(a5)
    80002ce2:	fe843783          	ld	a5,-24(s0)
    80002ce6:	e798                	sd	a4,8(a5)
            wakeup(initproc);
    80002ce8:	00003797          	auipc	a5,0x3
    80002cec:	32878793          	add	a5,a5,808 # 80006010 <initproc>
    80002cf0:	639c                	ld	a5,0(a5)
    80002cf2:	853e                	mv	a0,a5
    80002cf4:	00000097          	auipc	ra,0x0
    80002cf8:	2d8080e7          	jalr	728(ra) # 80002fcc <wakeup>
    for(np = proc; np < &proc[NPROC]; np++) {
    80002cfc:	fe843783          	ld	a5,-24(s0)
    80002d00:	0b878793          	add	a5,a5,184
    80002d04:	fef43423          	sd	a5,-24(s0)
    80002d08:	fe843703          	ld	a4,-24(s0)
    80002d0c:	00009797          	auipc	a5,0x9
    80002d10:	24c78793          	add	a5,a5,588 # 8000bf58 <cpu>
    80002d14:	faf76be3          	bltu	a4,a5,80002cca <exit+0x7c>
    wakeup(p->parent);
    80002d18:	fe043783          	ld	a5,-32(s0)
    80002d1c:	679c                	ld	a5,8(a5)
    80002d1e:	853e                	mv	a0,a5
    80002d20:	00000097          	auipc	ra,0x0
    80002d24:	2ac080e7          	jalr	684(ra) # 80002fcc <wakeup>
    p->state = ZOMBIE;
    80002d28:	fe043783          	ld	a5,-32(s0)
    80002d2c:	4715                	li	a4,5
    80002d2e:	c398                	sw	a4,0(a5)
    sched();
    80002d30:	00000097          	auipc	ra,0x0
    80002d34:	182080e7          	jalr	386(ra) # 80002eb2 <sched>
    panic("zombie exit");
    80002d38:	00002517          	auipc	a0,0x2
    80002d3c:	70850513          	add	a0,a0,1800 # 80005440 <etext+0x1440>
    80002d40:	ffffe097          	auipc	ra,0xffffe
    80002d44:	0e0080e7          	jalr	224(ra) # 80000e20 <panic>

0000000080002d48 <wait>:
int wait(int *status) {
    80002d48:	7139                	add	sp,sp,-64
    80002d4a:	fc06                	sd	ra,56(sp)
    80002d4c:	f822                	sd	s0,48(sp)
    80002d4e:	0080                	add	s0,sp,64
    80002d50:	fca43423          	sd	a0,-56(s0)
    struct proc *p = myproc();
    80002d54:	00000097          	auipc	ra,0x0
    80002d58:	c00080e7          	jalr	-1024(ra) # 80002954 <myproc>
    80002d5c:	fca43c23          	sd	a0,-40(s0)
        havekids = 0;
    80002d60:	fe042223          	sw	zero,-28(s0)
        for(np = proc; np < &proc[NPROC]; np++) {
    80002d64:	00006797          	auipc	a5,0x6
    80002d68:	3f478793          	add	a5,a5,1012 # 80009158 <proc>
    80002d6c:	fef43423          	sd	a5,-24(s0)
    80002d70:	a085                	j	80002dd0 <wait+0x88>
            if(np->parent == p) {
    80002d72:	fe843783          	ld	a5,-24(s0)
    80002d76:	679c                	ld	a5,8(a5)
    80002d78:	fd843703          	ld	a4,-40(s0)
    80002d7c:	04f71463          	bne	a4,a5,80002dc4 <wait+0x7c>
                havekids = 1;
    80002d80:	4785                	li	a5,1
    80002d82:	fef42223          	sw	a5,-28(s0)
                if(np->state == ZOMBIE) {
    80002d86:	fe843783          	ld	a5,-24(s0)
    80002d8a:	439c                	lw	a5,0(a5)
    80002d8c:	873e                	mv	a4,a5
    80002d8e:	4795                	li	a5,5
    80002d90:	02f71a63          	bne	a4,a5,80002dc4 <wait+0x7c>
                    pid = np->pid;
    80002d94:	fe843783          	ld	a5,-24(s0)
    80002d98:	43dc                	lw	a5,4(a5)
    80002d9a:	fcf42a23          	sw	a5,-44(s0)
                    if(status != 0) {
    80002d9e:	fc843783          	ld	a5,-56(s0)
    80002da2:	cb81                	beqz	a5,80002db2 <wait+0x6a>
                        *status = np->xstate;
    80002da4:	fe843783          	ld	a5,-24(s0)
    80002da8:	0947a703          	lw	a4,148(a5)
    80002dac:	fc843783          	ld	a5,-56(s0)
    80002db0:	c398                	sw	a4,0(a5)
                    freeproc(np);
    80002db2:	fe843503          	ld	a0,-24(s0)
    80002db6:	00000097          	auipc	ra,0x0
    80002dba:	d90080e7          	jalr	-624(ra) # 80002b46 <freeproc>
                    return pid;
    80002dbe:	fd442783          	lw	a5,-44(s0)
    80002dc2:	a091                	j	80002e06 <wait+0xbe>
        for(np = proc; np < &proc[NPROC]; np++) {
    80002dc4:	fe843783          	ld	a5,-24(s0)
    80002dc8:	0b878793          	add	a5,a5,184
    80002dcc:	fef43423          	sd	a5,-24(s0)
    80002dd0:	fe843703          	ld	a4,-24(s0)
    80002dd4:	00009797          	auipc	a5,0x9
    80002dd8:	18478793          	add	a5,a5,388 # 8000bf58 <cpu>
    80002ddc:	f8f76be3          	bltu	a4,a5,80002d72 <wait+0x2a>
        if(!havekids || p->killed) {
    80002de0:	fe442783          	lw	a5,-28(s0)
    80002de4:	2781                	sext.w	a5,a5
    80002de6:	c791                	beqz	a5,80002df2 <wait+0xaa>
    80002de8:	fd843783          	ld	a5,-40(s0)
    80002dec:	0907a783          	lw	a5,144(a5)
    80002df0:	c399                	beqz	a5,80002df6 <wait+0xae>
            return -1;
    80002df2:	57fd                	li	a5,-1
    80002df4:	a809                	j	80002e06 <wait+0xbe>
        sleep(p, 0);
    80002df6:	4581                	li	a1,0
    80002df8:	fd843503          	ld	a0,-40(s0)
    80002dfc:	00000097          	auipc	ra,0x0
    80002e00:	170080e7          	jalr	368(ra) # 80002f6c <sleep>
        havekids = 0;
    80002e04:	bfb1                	j	80002d60 <wait+0x18>
}
    80002e06:	853e                	mv	a0,a5
    80002e08:	70e2                	ld	ra,56(sp)
    80002e0a:	7442                	ld	s0,48(sp)
    80002e0c:	6121                	add	sp,sp,64
    80002e0e:	8082                	ret

0000000080002e10 <kill>:
int kill(int pid) {
    80002e10:	7179                	add	sp,sp,-48
    80002e12:	f422                	sd	s0,40(sp)
    80002e14:	1800                	add	s0,sp,48
    80002e16:	87aa                	mv	a5,a0
    80002e18:	fcf42e23          	sw	a5,-36(s0)
    for(p = proc; p < &proc[NPROC]; p++) {
    80002e1c:	00006797          	auipc	a5,0x6
    80002e20:	33c78793          	add	a5,a5,828 # 80009158 <proc>
    80002e24:	fef43423          	sd	a5,-24(s0)
    80002e28:	a089                	j	80002e6a <kill+0x5a>
        if(p->pid == pid) {
    80002e2a:	fe843783          	ld	a5,-24(s0)
    80002e2e:	43d8                	lw	a4,4(a5)
    80002e30:	fdc42783          	lw	a5,-36(s0)
    80002e34:	2781                	sext.w	a5,a5
    80002e36:	02e79463          	bne	a5,a4,80002e5e <kill+0x4e>
            p->killed = 1;
    80002e3a:	fe843783          	ld	a5,-24(s0)
    80002e3e:	4705                	li	a4,1
    80002e40:	08e7a823          	sw	a4,144(a5)
            if(p->state == SLEEPING) {
    80002e44:	fe843783          	ld	a5,-24(s0)
    80002e48:	439c                	lw	a5,0(a5)
    80002e4a:	873e                	mv	a4,a5
    80002e4c:	4789                	li	a5,2
    80002e4e:	00f71663          	bne	a4,a5,80002e5a <kill+0x4a>
                p->state = RUNNABLE;
    80002e52:	fe843783          	ld	a5,-24(s0)
    80002e56:	470d                	li	a4,3
    80002e58:	c398                	sw	a4,0(a5)
            return 0;
    80002e5a:	4781                	li	a5,0
    80002e5c:	a005                	j	80002e7c <kill+0x6c>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002e5e:	fe843783          	ld	a5,-24(s0)
    80002e62:	0b878793          	add	a5,a5,184
    80002e66:	fef43423          	sd	a5,-24(s0)
    80002e6a:	fe843703          	ld	a4,-24(s0)
    80002e6e:	00009797          	auipc	a5,0x9
    80002e72:	0ea78793          	add	a5,a5,234 # 8000bf58 <cpu>
    80002e76:	faf76ae3          	bltu	a4,a5,80002e2a <kill+0x1a>
        }
    }
    
    return -1;
    80002e7a:	57fd                	li	a5,-1
}
    80002e7c:	853e                	mv	a0,a5
    80002e7e:	7422                	ld	s0,40(sp)
    80002e80:	6145                	add	sp,sp,48
    80002e82:	8082                	ret

0000000080002e84 <yield>:

// ==================== 调度相关 ====================

// 让出CPU（主动调度）
void yield(void) {
    80002e84:	1101                	add	sp,sp,-32
    80002e86:	ec06                	sd	ra,24(sp)
    80002e88:	e822                	sd	s0,16(sp)
    80002e8a:	1000                	add	s0,sp,32
    struct proc *p = myproc();
    80002e8c:	00000097          	auipc	ra,0x0
    80002e90:	ac8080e7          	jalr	-1336(ra) # 80002954 <myproc>
    80002e94:	fea43423          	sd	a0,-24(s0)
    p->state = RUNNABLE;
    80002e98:	fe843783          	ld	a5,-24(s0)
    80002e9c:	470d                	li	a4,3
    80002e9e:	c398                	sw	a4,0(a5)
    sched();
    80002ea0:	00000097          	auipc	ra,0x0
    80002ea4:	012080e7          	jalr	18(ra) # 80002eb2 <sched>
}
    80002ea8:	0001                	nop
    80002eaa:	60e2                	ld	ra,24(sp)
    80002eac:	6442                	ld	s0,16(sp)
    80002eae:	6105                	add	sp,sp,32
    80002eb0:	8082                	ret

0000000080002eb2 <sched>:

// 切换到调度器
// 必须持有进程锁，并且已经修改了进程状态
void sched(void) {
    80002eb2:	1101                	add	sp,sp,-32
    80002eb4:	ec06                	sd	ra,24(sp)
    80002eb6:	e822                	sd	s0,16(sp)
    80002eb8:	1000                	add	s0,sp,32
    struct proc *p = myproc();
    80002eba:	00000097          	auipc	ra,0x0
    80002ebe:	a9a080e7          	jalr	-1382(ra) # 80002954 <myproc>
    80002ec2:	fea43423          	sd	a0,-24(s0)
    struct cpu *c = mycpu();
    80002ec6:	00000097          	auipc	ra,0x0
    80002eca:	a78080e7          	jalr	-1416(ra) # 8000293e <mycpu>
    80002ece:	fea43023          	sd	a0,-32(s0)
    
    // 切换到调度器的上下文
    swtch(&p->context, &c->context);
    80002ed2:	fe843783          	ld	a5,-24(s0)
    80002ed6:	01078713          	add	a4,a5,16
    80002eda:	fe043783          	ld	a5,-32(s0)
    80002ede:	07a1                	add	a5,a5,8
    80002ee0:	85be                	mv	a1,a5
    80002ee2:	853a                	mv	a0,a4
    80002ee4:	00000097          	auipc	ra,0x0
    80002ee8:	4dc080e7          	jalr	1244(ra) # 800033c0 <swtch>
}
    80002eec:	0001                	nop
    80002eee:	60e2                	ld	ra,24(sp)
    80002ef0:	6442                	ld	s0,16(sp)
    80002ef2:	6105                	add	sp,sp,32
    80002ef4:	8082                	ret

0000000080002ef6 <forkret>:

// 新进程第一次运行时的入口
void forkret(void) {
    80002ef6:	1101                	add	sp,sp,-32
    80002ef8:	ec06                	sd	ra,24(sp)
    80002efa:	e822                	sd	s0,16(sp)
    80002efc:	1000                	add	s0,sp,32
    static int first = 1;
    
    if(first) {
    80002efe:	00003797          	auipc	a5,0x3
    80002f02:	c4678793          	add	a5,a5,-954 # 80005b44 <first.1>
    80002f06:	439c                	lw	a5,0(a5)
    80002f08:	cf99                	beqz	a5,80002f26 <forkret+0x30>
        first = 0;
    80002f0a:	00003797          	auipc	a5,0x3
    80002f0e:	c3a78793          	add	a5,a5,-966 # 80005b44 <first.1>
    80002f12:	0007a023          	sw	zero,0(a5)
        printf("\n[forkret] First process starting...\n");
    80002f16:	00002517          	auipc	a0,0x2
    80002f1a:	53a50513          	add	a0,a0,1338 # 80005450 <etext+0x1450>
    80002f1e:	ffffe097          	auipc	ra,0xffffe
    80002f22:	c08080e7          	jalr	-1016(ra) # 80000b26 <printf>
    }
    
    // 从context.s0取出进程函数指针
    struct proc *p = myproc();
    80002f26:	00000097          	auipc	ra,0x0
    80002f2a:	a2e080e7          	jalr	-1490(ra) # 80002954 <myproc>
    80002f2e:	fea43423          	sd	a0,-24(s0)
    void (*fn)(void) = (void (*)(void))p->context.s0;
    80002f32:	fe843783          	ld	a5,-24(s0)
    80002f36:	739c                	ld	a5,32(a5)
    80002f38:	fef43023          	sd	a5,-32(s0)
    
    if(fn == 0) {
    80002f3c:	fe043783          	ld	a5,-32(s0)
    80002f40:	eb89                	bnez	a5,80002f52 <forkret+0x5c>
        panic("forkret: null function pointer");
    80002f42:	00002517          	auipc	a0,0x2
    80002f46:	53650513          	add	a0,a0,1334 # 80005478 <etext+0x1478>
    80002f4a:	ffffe097          	auipc	ra,0xffffe
    80002f4e:	ed6080e7          	jalr	-298(ra) # 80000e20 <panic>
    }
    
    // 调用进程函数
    fn();
    80002f52:	fe043783          	ld	a5,-32(s0)
    80002f56:	9782                	jalr	a5
    
    // 进程函数返回后，退出
    exit(0);
    80002f58:	4501                	li	a0,0
    80002f5a:	00000097          	auipc	ra,0x0
    80002f5e:	cf4080e7          	jalr	-780(ra) # 80002c4e <exit>
}
    80002f62:	0001                	nop
    80002f64:	60e2                	ld	ra,24(sp)
    80002f66:	6442                	ld	s0,16(sp)
    80002f68:	6105                	add	sp,sp,32
    80002f6a:	8082                	ret

0000000080002f6c <sleep>:

// ==================== Sleep/Wakeup 机制 ====================

// 在通道chan上睡眠
void sleep(void *chan, int dummy) {
    80002f6c:	7179                	add	sp,sp,-48
    80002f6e:	f406                	sd	ra,40(sp)
    80002f70:	f022                	sd	s0,32(sp)
    80002f72:	1800                	add	s0,sp,48
    80002f74:	fca43c23          	sd	a0,-40(s0)
    80002f78:	87ae                	mv	a5,a1
    80002f7a:	fcf42a23          	sw	a5,-44(s0)
    struct proc *p = myproc();
    80002f7e:	00000097          	auipc	ra,0x0
    80002f82:	9d6080e7          	jalr	-1578(ra) # 80002954 <myproc>
    80002f86:	fea43423          	sd	a0,-24(s0)
    
    if(p == 0) {
    80002f8a:	fe843783          	ld	a5,-24(s0)
    80002f8e:	eb89                	bnez	a5,80002fa0 <sleep+0x34>
        panic("sleep: no process");
    80002f90:	00002517          	auipc	a0,0x2
    80002f94:	50850513          	add	a0,a0,1288 # 80005498 <etext+0x1498>
    80002f98:	ffffe097          	auipc	ra,0xffffe
    80002f9c:	e88080e7          	jalr	-376(ra) # 80000e20 <panic>
    }
    
    // 必须修改状态后再调度
    p->chan = chan;
    80002fa0:	fe843783          	ld	a5,-24(s0)
    80002fa4:	fd843703          	ld	a4,-40(s0)
    80002fa8:	e7d8                	sd	a4,136(a5)
    p->state = SLEEPING;
    80002faa:	fe843783          	ld	a5,-24(s0)
    80002fae:	4709                	li	a4,2
    80002fb0:	c398                	sw	a4,0(a5)
    
    sched();
    80002fb2:	00000097          	auipc	ra,0x0
    80002fb6:	f00080e7          	jalr	-256(ra) # 80002eb2 <sched>
    
    // 被唤醒后清除通道
    p->chan = 0;
    80002fba:	fe843783          	ld	a5,-24(s0)
    80002fbe:	0807b423          	sd	zero,136(a5)
}
    80002fc2:	0001                	nop
    80002fc4:	70a2                	ld	ra,40(sp)
    80002fc6:	7402                	ld	s0,32(sp)
    80002fc8:	6145                	add	sp,sp,48
    80002fca:	8082                	ret

0000000080002fcc <wakeup>:

// 唤醒在通道chan上睡眠的所有进程
void wakeup(void *chan) {
    80002fcc:	7179                	add	sp,sp,-48
    80002fce:	f406                	sd	ra,40(sp)
    80002fd0:	f022                	sd	s0,32(sp)
    80002fd2:	1800                	add	s0,sp,48
    80002fd4:	fca43c23          	sd	a0,-40(s0)
    struct proc *p;
    
    for(p = proc; p < &proc[NPROC]; p++) {
    80002fd8:	00006797          	auipc	a5,0x6
    80002fdc:	18078793          	add	a5,a5,384 # 80009158 <proc>
    80002fe0:	fef43423          	sd	a5,-24(s0)
    80002fe4:	a091                	j	80003028 <wakeup+0x5c>
        if(p != myproc() && p->state == SLEEPING && p->chan == chan) {
    80002fe6:	00000097          	auipc	ra,0x0
    80002fea:	96e080e7          	jalr	-1682(ra) # 80002954 <myproc>
    80002fee:	872a                	mv	a4,a0
    80002ff0:	fe843783          	ld	a5,-24(s0)
    80002ff4:	02e78463          	beq	a5,a4,8000301c <wakeup+0x50>
    80002ff8:	fe843783          	ld	a5,-24(s0)
    80002ffc:	439c                	lw	a5,0(a5)
    80002ffe:	873e                	mv	a4,a5
    80003000:	4789                	li	a5,2
    80003002:	00f71d63          	bne	a4,a5,8000301c <wakeup+0x50>
    80003006:	fe843783          	ld	a5,-24(s0)
    8000300a:	67dc                	ld	a5,136(a5)
    8000300c:	fd843703          	ld	a4,-40(s0)
    80003010:	00f71663          	bne	a4,a5,8000301c <wakeup+0x50>
            p->state = RUNNABLE;
    80003014:	fe843783          	ld	a5,-24(s0)
    80003018:	470d                	li	a4,3
    8000301a:	c398                	sw	a4,0(a5)
    for(p = proc; p < &proc[NPROC]; p++) {
    8000301c:	fe843783          	ld	a5,-24(s0)
    80003020:	0b878793          	add	a5,a5,184
    80003024:	fef43423          	sd	a5,-24(s0)
    80003028:	fe843703          	ld	a4,-24(s0)
    8000302c:	00009797          	auipc	a5,0x9
    80003030:	f2c78793          	add	a5,a5,-212 # 8000bf58 <cpu>
    80003034:	faf769e3          	bltu	a4,a5,80002fe6 <wakeup+0x1a>
        }
    }
}
    80003038:	0001                	nop
    8000303a:	0001                	nop
    8000303c:	70a2                	ld	ra,40(sp)
    8000303e:	7402                	ld	s0,32(sp)
    80003040:	6145                	add	sp,sp,48
    80003042:	8082                	ret

0000000080003044 <scheduler>:

// ==================== 调度器 ====================

// 调度器主循环
// 永远不返回，在各个进程之间切换
void scheduler(void) {
    80003044:	7179                	add	sp,sp,-48
    80003046:	f406                	sd	ra,40(sp)
    80003048:	f022                	sd	s0,32(sp)
    8000304a:	1800                	add	s0,sp,48
    struct proc *p;
    struct cpu *c = mycpu();
    8000304c:	00000097          	auipc	ra,0x0
    80003050:	8f2080e7          	jalr	-1806(ra) # 8000293e <mycpu>
    80003054:	fea43023          	sd	a0,-32(s0)
    
    printf("\n=== Scheduler started ===\n");
    80003058:	00002517          	auipc	a0,0x2
    8000305c:	45850513          	add	a0,a0,1112 # 800054b0 <etext+0x14b0>
    80003060:	ffffe097          	auipc	ra,0xffffe
    80003064:	ac6080e7          	jalr	-1338(ra) # 80000b26 <printf>
    
    c->proc = 0;
    80003068:	fe043783          	ld	a5,-32(s0)
    8000306c:	0007b023          	sd	zero,0(a5)
    
    for(;;) {
        // 开启中断，允许设备中断
        intr_on();
    80003070:	00000097          	auipc	ra,0x0
    80003074:	838080e7          	jalr	-1992(ra) # 800028a8 <intr_on>
        
        // 遍历进程表，寻找RUNNABLE进程
        for(p = proc; p < &proc[NPROC]; p++) {
    80003078:	00006797          	auipc	a5,0x6
    8000307c:	0e078793          	add	a5,a5,224 # 80009158 <proc>
    80003080:	fef43423          	sd	a5,-24(s0)
    80003084:	a8ad                	j	800030fe <scheduler+0xba>
            if(p->state == RUNNABLE) {
    80003086:	fe843783          	ld	a5,-24(s0)
    8000308a:	439c                	lw	a5,0(a5)
    8000308c:	873e                	mv	a4,a5
    8000308e:	478d                	li	a5,3
    80003090:	06f71163          	bne	a4,a5,800030f2 <scheduler+0xae>
                // 找到可运行进程
                p->state = RUNNING;
    80003094:	fe843783          	ld	a5,-24(s0)
    80003098:	4711                	li	a4,4
    8000309a:	c398                	sw	a4,0(a5)
                c->proc = p;
    8000309c:	fe043783          	ld	a5,-32(s0)
    800030a0:	fe843703          	ld	a4,-24(s0)
    800030a4:	e398                	sd	a4,0(a5)
                
                // 记录开始运行时间
                uint64 start_tick = get_ticks();
    800030a6:	fffff097          	auipc	ra,0xfffff
    800030aa:	798080e7          	jalr	1944(ra) # 8000283e <get_ticks>
    800030ae:	fca43c23          	sd	a0,-40(s0)
                
                // 切换到进程的上下文
                swtch(&c->context, &p->context);
    800030b2:	fe043783          	ld	a5,-32(s0)
    800030b6:	00878713          	add	a4,a5,8
    800030ba:	fe843783          	ld	a5,-24(s0)
    800030be:	07c1                	add	a5,a5,16
    800030c0:	85be                	mv	a1,a5
    800030c2:	853a                	mv	a0,a4
    800030c4:	00000097          	auipc	ra,0x0
    800030c8:	2fc080e7          	jalr	764(ra) # 800033c0 <swtch>
                
                // 进程切换回来后，更新运行时间
                p->runtime += (get_ticks() - start_tick);
    800030cc:	fffff097          	auipc	ra,0xfffff
    800030d0:	772080e7          	jalr	1906(ra) # 8000283e <get_ticks>
    800030d4:	872a                	mv	a4,a0
    800030d6:	fd843783          	ld	a5,-40(s0)
    800030da:	8f1d                	sub	a4,a4,a5
    800030dc:	fe843783          	ld	a5,-24(s0)
    800030e0:	6fdc                	ld	a5,152(a5)
    800030e2:	973e                	add	a4,a4,a5
    800030e4:	fe843783          	ld	a5,-24(s0)
    800030e8:	efd8                	sd	a4,152(a5)
                
                // 此时进程已经让出CPU或退出
                c->proc = 0;
    800030ea:	fe043783          	ld	a5,-32(s0)
    800030ee:	0007b023          	sd	zero,0(a5)
        for(p = proc; p < &proc[NPROC]; p++) {
    800030f2:	fe843783          	ld	a5,-24(s0)
    800030f6:	0b878793          	add	a5,a5,184
    800030fa:	fef43423          	sd	a5,-24(s0)
    800030fe:	fe843703          	ld	a4,-24(s0)
    80003102:	00009797          	auipc	a5,0x9
    80003106:	e5678793          	add	a5,a5,-426 # 8000bf58 <cpu>
    8000310a:	f6f76ee3          	bltu	a4,a5,80003086 <scheduler+0x42>
            }
        }
        
        // 简单的idle循环
        // 实际系统中可以用WFI指令省电
        asm volatile("wfi");  // 等待中断
    8000310e:	10500073          	wfi
        intr_on();
    80003112:	bfb9                	j	80003070 <scheduler+0x2c>

0000000080003114 <timer_tick>:
}

// ==================== 时钟中断触发的调度 ====================

// 在时钟中断中调用，检查是否需要调度
void timer_tick(void) {
    80003114:	1101                	add	sp,sp,-32
    80003116:	ec06                	sd	ra,24(sp)
    80003118:	e822                	sd	s0,16(sp)
    8000311a:	1000                	add	s0,sp,32
    struct proc *p = myproc();
    8000311c:	00000097          	auipc	ra,0x0
    80003120:	838080e7          	jalr	-1992(ra) # 80002954 <myproc>
    80003124:	fea43423          	sd	a0,-24(s0)
    
    if(p != 0 && p->state == RUNNING) {
    80003128:	fe843783          	ld	a5,-24(s0)
    8000312c:	cba9                	beqz	a5,8000317e <timer_tick+0x6a>
    8000312e:	fe843783          	ld	a5,-24(s0)
    80003132:	439c                	lw	a5,0(a5)
    80003134:	873e                	mv	a4,a5
    80003136:	4791                	li	a5,4
    80003138:	04f71363          	bne	a4,a5,8000317e <timer_tick+0x6a>
        // 简单的时间片轮转：每100个tick调度一次
        static int ticks_count = 0;
        ticks_count++;
    8000313c:	00009797          	auipc	a5,0x9
    80003140:	e9c78793          	add	a5,a5,-356 # 8000bfd8 <ticks_count.0>
    80003144:	439c                	lw	a5,0(a5)
    80003146:	2785                	addw	a5,a5,1
    80003148:	0007871b          	sext.w	a4,a5
    8000314c:	00009797          	auipc	a5,0x9
    80003150:	e8c78793          	add	a5,a5,-372 # 8000bfd8 <ticks_count.0>
    80003154:	c398                	sw	a4,0(a5)
        
        if(ticks_count >= 100) {
    80003156:	00009797          	auipc	a5,0x9
    8000315a:	e8278793          	add	a5,a5,-382 # 8000bfd8 <ticks_count.0>
    8000315e:	439c                	lw	a5,0(a5)
    80003160:	873e                	mv	a4,a5
    80003162:	06300793          	li	a5,99
    80003166:	00e7dc63          	bge	a5,a4,8000317e <timer_tick+0x6a>
            ticks_count = 0;
    8000316a:	00009797          	auipc	a5,0x9
    8000316e:	e6e78793          	add	a5,a5,-402 # 8000bfd8 <ticks_count.0>
    80003172:	0007a023          	sw	zero,0(a5)
            yield();  // 主动让出CPU
    80003176:	00000097          	auipc	ra,0x0
    8000317a:	d0e080e7          	jalr	-754(ra) # 80002e84 <yield>
        }
    }
}
    8000317e:	0001                	nop
    80003180:	60e2                	ld	ra,24(sp)
    80003182:	6442                	ld	s0,16(sp)
    80003184:	6105                	add	sp,sp,32
    80003186:	8082                	ret

0000000080003188 <print_proc_table>:

// ==================== 调试和监控 ====================

// 打印进程表
// 打印进程表
void print_proc_table(void) {
    80003188:	1101                	add	sp,sp,-32
    8000318a:	ec06                	sd	ra,24(sp)
    8000318c:	e822                	sd	s0,16(sp)
    8000318e:	1000                	add	s0,sp,32
    struct proc *p;
    
    printf("\n=== Process Table ===\n");
    80003190:	00002517          	auipc	a0,0x2
    80003194:	34050513          	add	a0,a0,832 # 800054d0 <etext+0x14d0>
    80003198:	ffffe097          	auipc	ra,0xffffe
    8000319c:	98e080e7          	jalr	-1650(ra) # 80000b26 <printf>
    printf("PID  State  Name\n");
    800031a0:	00002517          	auipc	a0,0x2
    800031a4:	34850513          	add	a0,a0,840 # 800054e8 <etext+0x14e8>
    800031a8:	ffffe097          	auipc	ra,0xffffe
    800031ac:	97e080e7          	jalr	-1666(ra) # 80000b26 <printf>
    printf("---  -----  ----\n");
    800031b0:	00002517          	auipc	a0,0x2
    800031b4:	35050513          	add	a0,a0,848 # 80005500 <etext+0x1500>
    800031b8:	ffffe097          	auipc	ra,0xffffe
    800031bc:	96e080e7          	jalr	-1682(ra) # 80000b26 <printf>
    
    for(p = proc; p < &proc[NPROC]; p++) {
    800031c0:	00006797          	auipc	a5,0x6
    800031c4:	f9878793          	add	a5,a5,-104 # 80009158 <proc>
    800031c8:	fef43423          	sd	a5,-24(s0)
    800031cc:	a879                	j	8000326a <print_proc_table+0xe2>
        if(p->state != UNUSED) {
    800031ce:	fe843783          	ld	a5,-24(s0)
    800031d2:	439c                	lw	a5,0(a5)
    800031d4:	c7c9                	beqz	a5,8000325e <print_proc_table+0xd6>
            // 简化输出，避免复杂的字符串操作
            printf("%d  ", p->pid);
    800031d6:	fe843783          	ld	a5,-24(s0)
    800031da:	43dc                	lw	a5,4(a5)
    800031dc:	85be                	mv	a1,a5
    800031de:	00002517          	auipc	a0,0x2
    800031e2:	33a50513          	add	a0,a0,826 # 80005518 <etext+0x1518>
    800031e6:	ffffe097          	auipc	ra,0xffffe
    800031ea:	940080e7          	jalr	-1728(ra) # 80000b26 <printf>
            
            // 直接用数字表示状态
            printf("%d  ", p->state);
    800031ee:	fe843783          	ld	a5,-24(s0)
    800031f2:	439c                	lw	a5,0(a5)
    800031f4:	85be                	mv	a1,a5
    800031f6:	00002517          	auipc	a0,0x2
    800031fa:	32250513          	add	a0,a0,802 # 80005518 <etext+0x1518>
    800031fe:	ffffe097          	auipc	ra,0xffffe
    80003202:	928080e7          	jalr	-1752(ra) # 80000b26 <printf>
            
            // 逐字符打印名字（更安全）
            for(int i = 0; i < 16 && p->name[i] != 0; i++) {
    80003206:	fe042223          	sw	zero,-28(s0)
    8000320a:	a01d                	j	80003230 <print_proc_table+0xa8>
                console_putc(p->name[i]);
    8000320c:	fe843703          	ld	a4,-24(s0)
    80003210:	fe442783          	lw	a5,-28(s0)
    80003214:	97ba                	add	a5,a5,a4
    80003216:	0a87c783          	lbu	a5,168(a5)
    8000321a:	2781                	sext.w	a5,a5
    8000321c:	853e                	mv	a0,a5
    8000321e:	ffffd097          	auipc	ra,0xffffd
    80003222:	6c2080e7          	jalr	1730(ra) # 800008e0 <console_putc>
            for(int i = 0; i < 16 && p->name[i] != 0; i++) {
    80003226:	fe442783          	lw	a5,-28(s0)
    8000322a:	2785                	addw	a5,a5,1
    8000322c:	fef42223          	sw	a5,-28(s0)
    80003230:	fe442783          	lw	a5,-28(s0)
    80003234:	0007871b          	sext.w	a4,a5
    80003238:	47bd                	li	a5,15
    8000323a:	00e7ca63          	blt	a5,a4,8000324e <print_proc_table+0xc6>
    8000323e:	fe843703          	ld	a4,-24(s0)
    80003242:	fe442783          	lw	a5,-28(s0)
    80003246:	97ba                	add	a5,a5,a4
    80003248:	0a87c783          	lbu	a5,168(a5)
    8000324c:	f3e1                	bnez	a5,8000320c <print_proc_table+0x84>
            }
            
            printf("\n");
    8000324e:	00002517          	auipc	a0,0x2
    80003252:	2d250513          	add	a0,a0,722 # 80005520 <etext+0x1520>
    80003256:	ffffe097          	auipc	ra,0xffffe
    8000325a:	8d0080e7          	jalr	-1840(ra) # 80000b26 <printf>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000325e:	fe843783          	ld	a5,-24(s0)
    80003262:	0b878793          	add	a5,a5,184
    80003266:	fef43423          	sd	a5,-24(s0)
    8000326a:	fe843703          	ld	a4,-24(s0)
    8000326e:	00009797          	auipc	a5,0x9
    80003272:	cea78793          	add	a5,a5,-790 # 8000bf58 <cpu>
    80003276:	f4f76ce3          	bltu	a4,a5,800031ce <print_proc_table+0x46>
        }
    }
    
    printf("==================\n\n");
    8000327a:	00002517          	auipc	a0,0x2
    8000327e:	2ae50513          	add	a0,a0,686 # 80005528 <etext+0x1528>
    80003282:	ffffe097          	auipc	ra,0xffffe
    80003286:	8a4080e7          	jalr	-1884(ra) # 80000b26 <printf>
}
    8000328a:	0001                	nop
    8000328c:	60e2                	ld	ra,24(sp)
    8000328e:	6442                	ld	s0,16(sp)
    80003290:	6105                	add	sp,sp,32
    80003292:	8082                	ret

0000000080003294 <print_proc_stats>:

// 统计进程数量
void print_proc_stats(void) {
    80003294:	7179                	add	sp,sp,-48
    80003296:	f406                	sd	ra,40(sp)
    80003298:	f022                	sd	s0,32(sp)
    8000329a:	1800                	add	s0,sp,48
    int count[6] = {0};  // UNUSED, USED, SLEEPING, RUNNABLE, RUNNING, ZOMBIE
    8000329c:	fc043823          	sd	zero,-48(s0)
    800032a0:	fc043c23          	sd	zero,-40(s0)
    800032a4:	fe043023          	sd	zero,-32(s0)
    struct proc *p;
    
    for(p = proc; p < &proc[NPROC]; p++) {
    800032a8:	00006797          	auipc	a5,0x6
    800032ac:	eb078793          	add	a5,a5,-336 # 80009158 <proc>
    800032b0:	fef43423          	sd	a5,-24(s0)
    800032b4:	a82d                	j	800032ee <print_proc_stats+0x5a>
        count[p->state]++;
    800032b6:	fe843783          	ld	a5,-24(s0)
    800032ba:	4394                	lw	a3,0(a5)
    800032bc:	02069793          	sll	a5,a3,0x20
    800032c0:	9381                	srl	a5,a5,0x20
    800032c2:	078a                	sll	a5,a5,0x2
    800032c4:	17c1                	add	a5,a5,-16
    800032c6:	97a2                	add	a5,a5,s0
    800032c8:	fe07a783          	lw	a5,-32(a5)
    800032cc:	2785                	addw	a5,a5,1
    800032ce:	0007871b          	sext.w	a4,a5
    800032d2:	02069793          	sll	a5,a3,0x20
    800032d6:	9381                	srl	a5,a5,0x20
    800032d8:	078a                	sll	a5,a5,0x2
    800032da:	17c1                	add	a5,a5,-16
    800032dc:	97a2                	add	a5,a5,s0
    800032de:	fee7a023          	sw	a4,-32(a5)
    for(p = proc; p < &proc[NPROC]; p++) {
    800032e2:	fe843783          	ld	a5,-24(s0)
    800032e6:	0b878793          	add	a5,a5,184
    800032ea:	fef43423          	sd	a5,-24(s0)
    800032ee:	fe843703          	ld	a4,-24(s0)
    800032f2:	00009797          	auipc	a5,0x9
    800032f6:	c6678793          	add	a5,a5,-922 # 8000bf58 <cpu>
    800032fa:	faf76ee3          	bltu	a4,a5,800032b6 <print_proc_stats+0x22>
    }
    
    printf("\n=== Process Statistics ===\n");
    800032fe:	00002517          	auipc	a0,0x2
    80003302:	24250513          	add	a0,a0,578 # 80005540 <etext+0x1540>
    80003306:	ffffe097          	auipc	ra,0xffffe
    8000330a:	820080e7          	jalr	-2016(ra) # 80000b26 <printf>
    printf("Total processes: %d\n", NPROC);
    8000330e:	04000593          	li	a1,64
    80003312:	00002517          	auipc	a0,0x2
    80003316:	24e50513          	add	a0,a0,590 # 80005560 <etext+0x1560>
    8000331a:	ffffe097          	auipc	ra,0xffffe
    8000331e:	80c080e7          	jalr	-2036(ra) # 80000b26 <printf>
    printf("UNUSED:   %d\n", count[UNUSED]);
    80003322:	fd042783          	lw	a5,-48(s0)
    80003326:	85be                	mv	a1,a5
    80003328:	00002517          	auipc	a0,0x2
    8000332c:	25050513          	add	a0,a0,592 # 80005578 <etext+0x1578>
    80003330:	ffffd097          	auipc	ra,0xffffd
    80003334:	7f6080e7          	jalr	2038(ra) # 80000b26 <printf>
    printf("USED:     %d\n", count[USED]);
    80003338:	fd442783          	lw	a5,-44(s0)
    8000333c:	85be                	mv	a1,a5
    8000333e:	00002517          	auipc	a0,0x2
    80003342:	24a50513          	add	a0,a0,586 # 80005588 <etext+0x1588>
    80003346:	ffffd097          	auipc	ra,0xffffd
    8000334a:	7e0080e7          	jalr	2016(ra) # 80000b26 <printf>
    printf("SLEEPING: %d\n", count[SLEEPING]);
    8000334e:	fd842783          	lw	a5,-40(s0)
    80003352:	85be                	mv	a1,a5
    80003354:	00002517          	auipc	a0,0x2
    80003358:	24450513          	add	a0,a0,580 # 80005598 <etext+0x1598>
    8000335c:	ffffd097          	auipc	ra,0xffffd
    80003360:	7ca080e7          	jalr	1994(ra) # 80000b26 <printf>
    printf("RUNNABLE: %d\n", count[RUNNABLE]);
    80003364:	fdc42783          	lw	a5,-36(s0)
    80003368:	85be                	mv	a1,a5
    8000336a:	00002517          	auipc	a0,0x2
    8000336e:	23e50513          	add	a0,a0,574 # 800055a8 <etext+0x15a8>
    80003372:	ffffd097          	auipc	ra,0xffffd
    80003376:	7b4080e7          	jalr	1972(ra) # 80000b26 <printf>
    printf("RUNNING:  %d\n", count[RUNNING]);
    8000337a:	fe042783          	lw	a5,-32(s0)
    8000337e:	85be                	mv	a1,a5
    80003380:	00002517          	auipc	a0,0x2
    80003384:	23850513          	add	a0,a0,568 # 800055b8 <etext+0x15b8>
    80003388:	ffffd097          	auipc	ra,0xffffd
    8000338c:	79e080e7          	jalr	1950(ra) # 80000b26 <printf>
    printf("ZOMBIE:   %d\n", count[ZOMBIE]);
    80003390:	fe442783          	lw	a5,-28(s0)
    80003394:	85be                	mv	a1,a5
    80003396:	00002517          	auipc	a0,0x2
    8000339a:	23250513          	add	a0,a0,562 # 800055c8 <etext+0x15c8>
    8000339e:	ffffd097          	auipc	ra,0xffffd
    800033a2:	788080e7          	jalr	1928(ra) # 80000b26 <printf>
    printf("=========================\n\n");
    800033a6:	00002517          	auipc	a0,0x2
    800033aa:	23250513          	add	a0,a0,562 # 800055d8 <etext+0x15d8>
    800033ae:	ffffd097          	auipc	ra,0xffffd
    800033b2:	778080e7          	jalr	1912(ra) # 80000b26 <printf>
    800033b6:	0001                	nop
    800033b8:	70a2                	ld	ra,40(sp)
    800033ba:	7402                	ld	s0,32(sp)
    800033bc:	6145                	add	sp,sp,48
    800033be:	8082                	ret

00000000800033c0 <swtch>:
swtch:
    # ========== 保存旧上下文 ==========
    # a0 = old context
    
    # 保存返回地址
    sd ra, 0(a0)
    800033c0:	00153023          	sd	ra,0(a0)
    
    # 保存栈指针
    sd sp, 8(a0)
    800033c4:	00253423          	sd	sp,8(a0)
    
    # 保存被调用者保存的寄存器 (s0-s11)
    sd s0, 16(a0)
    800033c8:	e900                	sd	s0,16(a0)
    sd s1, 24(a0)
    800033ca:	ed04                	sd	s1,24(a0)
    sd s2, 32(a0)
    800033cc:	03253023          	sd	s2,32(a0)
    sd s3, 40(a0)
    800033d0:	03353423          	sd	s3,40(a0)
    sd s4, 48(a0)
    800033d4:	03453823          	sd	s4,48(a0)
    sd s5, 56(a0)
    800033d8:	03553c23          	sd	s5,56(a0)
    sd s6, 64(a0)
    800033dc:	05653023          	sd	s6,64(a0)
    sd s7, 72(a0)
    800033e0:	05753423          	sd	s7,72(a0)
    sd s8, 80(a0)
    800033e4:	05853823          	sd	s8,80(a0)
    sd s9, 88(a0)
    800033e8:	05953c23          	sd	s9,88(a0)
    sd s10, 96(a0)
    800033ec:	07a53023          	sd	s10,96(a0)
    sd s11, 104(a0)
    800033f0:	07b53423          	sd	s11,104(a0)
    
    # ========== 恢复新上下文 ==========
    # a1 = new context
    
    # 恢复被调用者保存的寄存器
    ld s0, 16(a1)
    800033f4:	6980                	ld	s0,16(a1)
    ld s1, 24(a1)
    800033f6:	6d84                	ld	s1,24(a1)
    ld s2, 32(a1)
    800033f8:	0205b903          	ld	s2,32(a1)
    ld s3, 40(a1)
    800033fc:	0285b983          	ld	s3,40(a1)
    ld s4, 48(a1)
    80003400:	0305ba03          	ld	s4,48(a1)
    ld s5, 56(a1)
    80003404:	0385ba83          	ld	s5,56(a1)
    ld s6, 64(a1)
    80003408:	0405bb03          	ld	s6,64(a1)
    ld s7, 72(a1)
    8000340c:	0485bb83          	ld	s7,72(a1)
    ld s8, 80(a1)
    80003410:	0505bc03          	ld	s8,80(a1)
    ld s9, 88(a1)
    80003414:	0585bc83          	ld	s9,88(a1)
    ld s10, 96(a1)
    80003418:	0605bd03          	ld	s10,96(a1)
    ld s11, 104(a1)
    8000341c:	0685bd83          	ld	s11,104(a1)
    
    # 恢复栈指针
    ld sp, 8(a1)
    80003420:	0085b103          	ld	sp,8(a1)
    
    # 恢复返回地址
    ld ra, 0(a1)
    80003424:	0005b083          	ld	ra,0(a1)
    
    # 返回到新上下文的ra指向的地址
    80003428:	8082                	ret
    8000342a:	0001                	nop
    8000342c:	00000013          	nop

0000000080003430 <simple_task_1>:
#include "riscv.h"
#include "proc.h"
// ==================== 测试任务 ====================

// 简单的计数任务
static void simple_task_1(void) {
    80003430:	1101                	add	sp,sp,-32
    80003432:	ec06                	sd	ra,24(sp)
    80003434:	e822                	sd	s0,16(sp)
    80003436:	1000                	add	s0,sp,32
    printf("[Task1] Started (PID %d)\n", myproc()->pid);
    80003438:	fffff097          	auipc	ra,0xfffff
    8000343c:	51c080e7          	jalr	1308(ra) # 80002954 <myproc>
    80003440:	87aa                	mv	a5,a0
    80003442:	43dc                	lw	a5,4(a5)
    80003444:	85be                	mv	a1,a5
    80003446:	00002517          	auipc	a0,0x2
    8000344a:	1b250513          	add	a0,a0,434 # 800055f8 <etext+0x15f8>
    8000344e:	ffffd097          	auipc	ra,0xffffd
    80003452:	6d8080e7          	jalr	1752(ra) # 80000b26 <printf>
    
    for(int i = 0; i < 5; i++) {
    80003456:	fe042623          	sw	zero,-20(s0)
    8000345a:	a889                	j	800034ac <simple_task_1+0x7c>
        printf("[Task1] Count: %d\n", i);
    8000345c:	fec42783          	lw	a5,-20(s0)
    80003460:	85be                	mv	a1,a5
    80003462:	00002517          	auipc	a0,0x2
    80003466:	1b650513          	add	a0,a0,438 # 80005618 <etext+0x1618>
    8000346a:	ffffd097          	auipc	ra,0xffffd
    8000346e:	6bc080e7          	jalr	1724(ra) # 80000b26 <printf>
        
        // 简单延时
        for(volatile int j = 0; j < 10000000; j++);
    80003472:	fe042423          	sw	zero,-24(s0)
    80003476:	a801                	j	80003486 <simple_task_1+0x56>
    80003478:	fe842783          	lw	a5,-24(s0)
    8000347c:	2781                	sext.w	a5,a5
    8000347e:	2785                	addw	a5,a5,1
    80003480:	2781                	sext.w	a5,a5
    80003482:	fef42423          	sw	a5,-24(s0)
    80003486:	fe842783          	lw	a5,-24(s0)
    8000348a:	2781                	sext.w	a5,a5
    8000348c:	873e                	mv	a4,a5
    8000348e:	009897b7          	lui	a5,0x989
    80003492:	67f78793          	add	a5,a5,1663 # 98967f <_entry-0x7f676981>
    80003496:	fee7d1e3          	bge	a5,a4,80003478 <simple_task_1+0x48>
        
        // 主动让出CPU
        yield();
    8000349a:	00000097          	auipc	ra,0x0
    8000349e:	9ea080e7          	jalr	-1558(ra) # 80002e84 <yield>
    for(int i = 0; i < 5; i++) {
    800034a2:	fec42783          	lw	a5,-20(s0)
    800034a6:	2785                	addw	a5,a5,1
    800034a8:	fef42623          	sw	a5,-20(s0)
    800034ac:	fec42783          	lw	a5,-20(s0)
    800034b0:	0007871b          	sext.w	a4,a5
    800034b4:	4791                	li	a5,4
    800034b6:	fae7d3e3          	bge	a5,a4,8000345c <simple_task_1+0x2c>
    }
    
    printf("[Task1] Finished\n");
    800034ba:	00002517          	auipc	a0,0x2
    800034be:	17650513          	add	a0,a0,374 # 80005630 <etext+0x1630>
    800034c2:	ffffd097          	auipc	ra,0xffffd
    800034c6:	664080e7          	jalr	1636(ra) # 80000b26 <printf>
}
    800034ca:	0001                	nop
    800034cc:	60e2                	ld	ra,24(sp)
    800034ce:	6442                	ld	s0,16(sp)
    800034d0:	6105                	add	sp,sp,32
    800034d2:	8082                	ret

00000000800034d4 <simple_task_2>:

static void simple_task_2(void) {
    800034d4:	1101                	add	sp,sp,-32
    800034d6:	ec06                	sd	ra,24(sp)
    800034d8:	e822                	sd	s0,16(sp)
    800034da:	1000                	add	s0,sp,32
    printf("[Task2] Started (PID %d)\n", myproc()->pid);
    800034dc:	fffff097          	auipc	ra,0xfffff
    800034e0:	478080e7          	jalr	1144(ra) # 80002954 <myproc>
    800034e4:	87aa                	mv	a5,a0
    800034e6:	43dc                	lw	a5,4(a5)
    800034e8:	85be                	mv	a1,a5
    800034ea:	00002517          	auipc	a0,0x2
    800034ee:	15e50513          	add	a0,a0,350 # 80005648 <etext+0x1648>
    800034f2:	ffffd097          	auipc	ra,0xffffd
    800034f6:	634080e7          	jalr	1588(ra) # 80000b26 <printf>
    
    for(int i = 0; i < 5; i++) {
    800034fa:	fe042623          	sw	zero,-20(s0)
    800034fe:	a889                	j	80003550 <simple_task_2+0x7c>
        printf("[Task2] Iteration: %d\n", i);
    80003500:	fec42783          	lw	a5,-20(s0)
    80003504:	85be                	mv	a1,a5
    80003506:	00002517          	auipc	a0,0x2
    8000350a:	16250513          	add	a0,a0,354 # 80005668 <etext+0x1668>
    8000350e:	ffffd097          	auipc	ra,0xffffd
    80003512:	618080e7          	jalr	1560(ra) # 80000b26 <printf>
        
        for(volatile int j = 0; j < 10000000; j++);
    80003516:	fe042423          	sw	zero,-24(s0)
    8000351a:	a801                	j	8000352a <simple_task_2+0x56>
    8000351c:	fe842783          	lw	a5,-24(s0)
    80003520:	2781                	sext.w	a5,a5
    80003522:	2785                	addw	a5,a5,1
    80003524:	2781                	sext.w	a5,a5
    80003526:	fef42423          	sw	a5,-24(s0)
    8000352a:	fe842783          	lw	a5,-24(s0)
    8000352e:	2781                	sext.w	a5,a5
    80003530:	873e                	mv	a4,a5
    80003532:	009897b7          	lui	a5,0x989
    80003536:	67f78793          	add	a5,a5,1663 # 98967f <_entry-0x7f676981>
    8000353a:	fee7d1e3          	bge	a5,a4,8000351c <simple_task_2+0x48>
        
        yield();
    8000353e:	00000097          	auipc	ra,0x0
    80003542:	946080e7          	jalr	-1722(ra) # 80002e84 <yield>
    for(int i = 0; i < 5; i++) {
    80003546:	fec42783          	lw	a5,-20(s0)
    8000354a:	2785                	addw	a5,a5,1
    8000354c:	fef42623          	sw	a5,-20(s0)
    80003550:	fec42783          	lw	a5,-20(s0)
    80003554:	0007871b          	sext.w	a4,a5
    80003558:	4791                	li	a5,4
    8000355a:	fae7d3e3          	bge	a5,a4,80003500 <simple_task_2+0x2c>
    }
    
    printf("[Task2] Finished\n");
    8000355e:	00002517          	auipc	a0,0x2
    80003562:	12250513          	add	a0,a0,290 # 80005680 <etext+0x1680>
    80003566:	ffffd097          	auipc	ra,0xffffd
    8000356a:	5c0080e7          	jalr	1472(ra) # 80000b26 <printf>
}
    8000356e:	0001                	nop
    80003570:	60e2                	ld	ra,24(sp)
    80003572:	6442                	ld	s0,16(sp)
    80003574:	6105                	add	sp,sp,32
    80003576:	8082                	ret

0000000080003578 <simple_task_3>:

static void simple_task_3(void) {
    80003578:	1101                	add	sp,sp,-32
    8000357a:	ec06                	sd	ra,24(sp)
    8000357c:	e822                	sd	s0,16(sp)
    8000357e:	1000                	add	s0,sp,32
    printf("[Task3] Started (PID %d)\n", myproc()->pid);
    80003580:	fffff097          	auipc	ra,0xfffff
    80003584:	3d4080e7          	jalr	980(ra) # 80002954 <myproc>
    80003588:	87aa                	mv	a5,a0
    8000358a:	43dc                	lw	a5,4(a5)
    8000358c:	85be                	mv	a1,a5
    8000358e:	00002517          	auipc	a0,0x2
    80003592:	10a50513          	add	a0,a0,266 # 80005698 <etext+0x1698>
    80003596:	ffffd097          	auipc	ra,0xffffd
    8000359a:	590080e7          	jalr	1424(ra) # 80000b26 <printf>
    
    for(int i = 0; i < 5; i++) {
    8000359e:	fe042623          	sw	zero,-20(s0)
    800035a2:	a889                	j	800035f4 <simple_task_3+0x7c>
        printf("[Task3] Step: %d\n", i);
    800035a4:	fec42783          	lw	a5,-20(s0)
    800035a8:	85be                	mv	a1,a5
    800035aa:	00002517          	auipc	a0,0x2
    800035ae:	10e50513          	add	a0,a0,270 # 800056b8 <etext+0x16b8>
    800035b2:	ffffd097          	auipc	ra,0xffffd
    800035b6:	574080e7          	jalr	1396(ra) # 80000b26 <printf>
        
        for(volatile int j = 0; j < 10000000; j++);
    800035ba:	fe042423          	sw	zero,-24(s0)
    800035be:	a801                	j	800035ce <simple_task_3+0x56>
    800035c0:	fe842783          	lw	a5,-24(s0)
    800035c4:	2781                	sext.w	a5,a5
    800035c6:	2785                	addw	a5,a5,1
    800035c8:	2781                	sext.w	a5,a5
    800035ca:	fef42423          	sw	a5,-24(s0)
    800035ce:	fe842783          	lw	a5,-24(s0)
    800035d2:	2781                	sext.w	a5,a5
    800035d4:	873e                	mv	a4,a5
    800035d6:	009897b7          	lui	a5,0x989
    800035da:	67f78793          	add	a5,a5,1663 # 98967f <_entry-0x7f676981>
    800035de:	fee7d1e3          	bge	a5,a4,800035c0 <simple_task_3+0x48>
        
        yield();
    800035e2:	00000097          	auipc	ra,0x0
    800035e6:	8a2080e7          	jalr	-1886(ra) # 80002e84 <yield>
    for(int i = 0; i < 5; i++) {
    800035ea:	fec42783          	lw	a5,-20(s0)
    800035ee:	2785                	addw	a5,a5,1
    800035f0:	fef42623          	sw	a5,-20(s0)
    800035f4:	fec42783          	lw	a5,-20(s0)
    800035f8:	0007871b          	sext.w	a4,a5
    800035fc:	4791                	li	a5,4
    800035fe:	fae7d3e3          	bge	a5,a4,800035a4 <simple_task_3+0x2c>
    }
    
    printf("[Task3] Finished\n");
    80003602:	00002517          	auipc	a0,0x2
    80003606:	0ce50513          	add	a0,a0,206 # 800056d0 <etext+0x16d0>
    8000360a:	ffffd097          	auipc	ra,0xffffd
    8000360e:	51c080e7          	jalr	1308(ra) # 80000b26 <printf>
}
    80003612:	0001                	nop
    80003614:	60e2                	ld	ra,24(sp)
    80003616:	6442                	ld	s0,16(sp)
    80003618:	6105                	add	sp,sp,32
    8000361a:	8082                	ret

000000008000361c <cpu_intensive_task>:

// CPU密集型任务
static void cpu_intensive_task(void) {
    8000361c:	1101                	add	sp,sp,-32
    8000361e:	ec06                	sd	ra,24(sp)
    80003620:	e822                	sd	s0,16(sp)
    80003622:	1000                	add	s0,sp,32
    printf("[CPU-Task] Started (PID %d)\n", myproc()->pid);
    80003624:	fffff097          	auipc	ra,0xfffff
    80003628:	330080e7          	jalr	816(ra) # 80002954 <myproc>
    8000362c:	87aa                	mv	a5,a0
    8000362e:	43dc                	lw	a5,4(a5)
    80003630:	85be                	mv	a1,a5
    80003632:	00002517          	auipc	a0,0x2
    80003636:	0b650513          	add	a0,a0,182 # 800056e8 <etext+0x16e8>
    8000363a:	ffffd097          	auipc	ra,0xffffd
    8000363e:	4ec080e7          	jalr	1260(ra) # 80000b26 <printf>
    
    uint64 count = 0;
    80003642:	fe043423          	sd	zero,-24(s0)
    uint64 start_time = get_ticks();
    80003646:	fffff097          	auipc	ra,0xfffff
    8000364a:	1f8080e7          	jalr	504(ra) # 8000283e <get_ticks>
    8000364e:	fea43023          	sd	a0,-32(s0)
    
    // 运行约1秒
    while(get_ticks() - start_time < 10) {  // 10 ticks = 1秒
    80003652:	a081                	j	80003692 <cpu_intensive_task+0x76>
        count++;
    80003654:	fe843783          	ld	a5,-24(s0)
    80003658:	0785                	add	a5,a5,1
    8000365a:	fef43423          	sd	a5,-24(s0)
        
        // 每隔一段时间打印一次
        if(count % 1000000 == 0) {
    8000365e:	fe843703          	ld	a4,-24(s0)
    80003662:	000f47b7          	lui	a5,0xf4
    80003666:	24078793          	add	a5,a5,576 # f4240 <_entry-0x7ff0bdc0>
    8000366a:	02f777b3          	remu	a5,a4,a5
    8000366e:	e395                	bnez	a5,80003692 <cpu_intensive_task+0x76>
            printf("[CPU-Task PID %d] Count: %lu\n", 
                   myproc()->pid, count);
    80003670:	fffff097          	auipc	ra,0xfffff
    80003674:	2e4080e7          	jalr	740(ra) # 80002954 <myproc>
    80003678:	87aa                	mv	a5,a0
            printf("[CPU-Task PID %d] Count: %lu\n", 
    8000367a:	43dc                	lw	a5,4(a5)
    8000367c:	fe843603          	ld	a2,-24(s0)
    80003680:	85be                	mv	a1,a5
    80003682:	00002517          	auipc	a0,0x2
    80003686:	08650513          	add	a0,a0,134 # 80005708 <etext+0x1708>
    8000368a:	ffffd097          	auipc	ra,0xffffd
    8000368e:	49c080e7          	jalr	1180(ra) # 80000b26 <printf>
    while(get_ticks() - start_time < 10) {  // 10 ticks = 1秒
    80003692:	fffff097          	auipc	ra,0xfffff
    80003696:	1ac080e7          	jalr	428(ra) # 8000283e <get_ticks>
    8000369a:	872a                	mv	a4,a0
    8000369c:	fe043783          	ld	a5,-32(s0)
    800036a0:	8f1d                	sub	a4,a4,a5
    800036a2:	47a5                	li	a5,9
    800036a4:	fae7f8e3          	bgeu	a5,a4,80003654 <cpu_intensive_task+0x38>
        }
    }
    
    printf("[CPU-Task PID %d] Finished with count=%lu\n", 
           myproc()->pid, count);
    800036a8:	fffff097          	auipc	ra,0xfffff
    800036ac:	2ac080e7          	jalr	684(ra) # 80002954 <myproc>
    800036b0:	87aa                	mv	a5,a0
    printf("[CPU-Task PID %d] Finished with count=%lu\n", 
    800036b2:	43dc                	lw	a5,4(a5)
    800036b4:	fe843603          	ld	a2,-24(s0)
    800036b8:	85be                	mv	a1,a5
    800036ba:	00002517          	auipc	a0,0x2
    800036be:	06e50513          	add	a0,a0,110 # 80005728 <etext+0x1728>
    800036c2:	ffffd097          	auipc	ra,0xffffd
    800036c6:	464080e7          	jalr	1124(ra) # 80000b26 <printf>
}
    800036ca:	0001                	nop
    800036cc:	60e2                	ld	ra,24(sp)
    800036ce:	6442                	ld	s0,16(sp)
    800036d0:	6105                	add	sp,sp,32
    800036d2:	8082                	ret

00000000800036d4 <producer_task>:
static int buffer[BUFFER_SIZE];
static int buffer_count = 0;
static void *buffer_not_empty = (void*)1;
static void *buffer_not_full = (void*)2;

static void producer_task(void) {
    800036d4:	1101                	add	sp,sp,-32
    800036d6:	ec06                	sd	ra,24(sp)
    800036d8:	e822                	sd	s0,16(sp)
    800036da:	1000                	add	s0,sp,32
    printf("[Producer] Started (PID %d)\n", myproc()->pid);
    800036dc:	fffff097          	auipc	ra,0xfffff
    800036e0:	278080e7          	jalr	632(ra) # 80002954 <myproc>
    800036e4:	87aa                	mv	a5,a0
    800036e6:	43dc                	lw	a5,4(a5)
    800036e8:	85be                	mv	a1,a5
    800036ea:	00002517          	auipc	a0,0x2
    800036ee:	06e50513          	add	a0,a0,110 # 80005758 <etext+0x1758>
    800036f2:	ffffd097          	auipc	ra,0xffffd
    800036f6:	434080e7          	jalr	1076(ra) # 80000b26 <printf>
    
    for(int i = 0; i < 20; i++) {
    800036fa:	fe042623          	sw	zero,-20(s0)
    800036fe:	a8e1                	j	800037d6 <producer_task+0x102>
        // 等待缓冲区不满
        while(buffer_count >= BUFFER_SIZE) {
            printf("[Producer] Buffer full, sleeping...\n");
    80003700:	00002517          	auipc	a0,0x2
    80003704:	07850513          	add	a0,a0,120 # 80005778 <etext+0x1778>
    80003708:	ffffd097          	auipc	ra,0xffffd
    8000370c:	41e080e7          	jalr	1054(ra) # 80000b26 <printf>
            sleep(buffer_not_full, 0);
    80003710:	00002797          	auipc	a5,0x2
    80003714:	44078793          	add	a5,a5,1088 # 80005b50 <buffer_not_full>
    80003718:	639c                	ld	a5,0(a5)
    8000371a:	4581                	li	a1,0
    8000371c:	853e                	mv	a0,a5
    8000371e:	00000097          	auipc	ra,0x0
    80003722:	84e080e7          	jalr	-1970(ra) # 80002f6c <sleep>
        while(buffer_count >= BUFFER_SIZE) {
    80003726:	00009797          	auipc	a5,0x9
    8000372a:	8e278793          	add	a5,a5,-1822 # 8000c008 <buffer_count>
    8000372e:	439c                	lw	a5,0(a5)
    80003730:	873e                	mv	a4,a5
    80003732:	47a5                	li	a5,9
    80003734:	fce7c6e3          	blt	a5,a4,80003700 <producer_task+0x2c>
        }
        
        // 生产数据
        buffer[buffer_count++] = i;
    80003738:	00009797          	auipc	a5,0x9
    8000373c:	8d078793          	add	a5,a5,-1840 # 8000c008 <buffer_count>
    80003740:	439c                	lw	a5,0(a5)
    80003742:	0017871b          	addw	a4,a5,1
    80003746:	0007069b          	sext.w	a3,a4
    8000374a:	00009717          	auipc	a4,0x9
    8000374e:	8be70713          	add	a4,a4,-1858 # 8000c008 <buffer_count>
    80003752:	c314                	sw	a3,0(a4)
    80003754:	00009717          	auipc	a4,0x9
    80003758:	88c70713          	add	a4,a4,-1908 # 8000bfe0 <buffer>
    8000375c:	078a                	sll	a5,a5,0x2
    8000375e:	97ba                	add	a5,a5,a4
    80003760:	fec42703          	lw	a4,-20(s0)
    80003764:	c398                	sw	a4,0(a5)
        printf("[Producer] Produced: %d (buffer_count=%d)\n", 
    80003766:	00009797          	auipc	a5,0x9
    8000376a:	8a278793          	add	a5,a5,-1886 # 8000c008 <buffer_count>
    8000376e:	4398                	lw	a4,0(a5)
    80003770:	fec42783          	lw	a5,-20(s0)
    80003774:	863a                	mv	a2,a4
    80003776:	85be                	mv	a1,a5
    80003778:	00002517          	auipc	a0,0x2
    8000377c:	02850513          	add	a0,a0,40 # 800057a0 <etext+0x17a0>
    80003780:	ffffd097          	auipc	ra,0xffffd
    80003784:	3a6080e7          	jalr	934(ra) # 80000b26 <printf>
               i, buffer_count);
        
        // 唤醒消费者
        wakeup(buffer_not_empty);
    80003788:	00002797          	auipc	a5,0x2
    8000378c:	3c078793          	add	a5,a5,960 # 80005b48 <buffer_not_empty>
    80003790:	639c                	ld	a5,0(a5)
    80003792:	853e                	mv	a0,a5
    80003794:	00000097          	auipc	ra,0x0
    80003798:	838080e7          	jalr	-1992(ra) # 80002fcc <wakeup>
        
        // 延时
        for(volatile int j = 0; j < 5000000; j++);
    8000379c:	fe042423          	sw	zero,-24(s0)
    800037a0:	a801                	j	800037b0 <producer_task+0xdc>
    800037a2:	fe842783          	lw	a5,-24(s0)
    800037a6:	2781                	sext.w	a5,a5
    800037a8:	2785                	addw	a5,a5,1
    800037aa:	2781                	sext.w	a5,a5
    800037ac:	fef42423          	sw	a5,-24(s0)
    800037b0:	fe842783          	lw	a5,-24(s0)
    800037b4:	2781                	sext.w	a5,a5
    800037b6:	873e                	mv	a4,a5
    800037b8:	004c57b7          	lui	a5,0x4c5
    800037bc:	b3f78793          	add	a5,a5,-1217 # 4c4b3f <_entry-0x7fb3b4c1>
    800037c0:	fee7d1e3          	bge	a5,a4,800037a2 <producer_task+0xce>
        yield();
    800037c4:	fffff097          	auipc	ra,0xfffff
    800037c8:	6c0080e7          	jalr	1728(ra) # 80002e84 <yield>
    for(int i = 0; i < 20; i++) {
    800037cc:	fec42783          	lw	a5,-20(s0)
    800037d0:	2785                	addw	a5,a5,1
    800037d2:	fef42623          	sw	a5,-20(s0)
    800037d6:	fec42783          	lw	a5,-20(s0)
    800037da:	0007871b          	sext.w	a4,a5
    800037de:	47cd                	li	a5,19
    800037e0:	f4e7d3e3          	bge	a5,a4,80003726 <producer_task+0x52>
    }
    
    printf("[Producer] Finished\n");
    800037e4:	00002517          	auipc	a0,0x2
    800037e8:	fec50513          	add	a0,a0,-20 # 800057d0 <etext+0x17d0>
    800037ec:	ffffd097          	auipc	ra,0xffffd
    800037f0:	33a080e7          	jalr	826(ra) # 80000b26 <printf>
}
    800037f4:	0001                	nop
    800037f6:	60e2                	ld	ra,24(sp)
    800037f8:	6442                	ld	s0,16(sp)
    800037fa:	6105                	add	sp,sp,32
    800037fc:	8082                	ret

00000000800037fe <consumer_task>:

static void consumer_task(void) {
    800037fe:	1101                	add	sp,sp,-32
    80003800:	ec06                	sd	ra,24(sp)
    80003802:	e822                	sd	s0,16(sp)
    80003804:	1000                	add	s0,sp,32
    printf("[Consumer] Started (PID %d)\n", myproc()->pid);
    80003806:	fffff097          	auipc	ra,0xfffff
    8000380a:	14e080e7          	jalr	334(ra) # 80002954 <myproc>
    8000380e:	87aa                	mv	a5,a0
    80003810:	43dc                	lw	a5,4(a5)
    80003812:	85be                	mv	a1,a5
    80003814:	00002517          	auipc	a0,0x2
    80003818:	fd450513          	add	a0,a0,-44 # 800057e8 <etext+0x17e8>
    8000381c:	ffffd097          	auipc	ra,0xffffd
    80003820:	30a080e7          	jalr	778(ra) # 80000b26 <printf>
    
    for(int i = 0; i < 20; i++) {
    80003824:	fe042623          	sw	zero,-20(s0)
    80003828:	a8f1                	j	80003904 <consumer_task+0x106>
        // 等待缓冲区不空
        while(buffer_count <= 0) {
            printf("[Consumer] Buffer empty, sleeping...\n");
    8000382a:	00002517          	auipc	a0,0x2
    8000382e:	fde50513          	add	a0,a0,-34 # 80005808 <etext+0x1808>
    80003832:	ffffd097          	auipc	ra,0xffffd
    80003836:	2f4080e7          	jalr	756(ra) # 80000b26 <printf>
            sleep(buffer_not_empty, 0);
    8000383a:	00002797          	auipc	a5,0x2
    8000383e:	30e78793          	add	a5,a5,782 # 80005b48 <buffer_not_empty>
    80003842:	639c                	ld	a5,0(a5)
    80003844:	4581                	li	a1,0
    80003846:	853e                	mv	a0,a5
    80003848:	fffff097          	auipc	ra,0xfffff
    8000384c:	724080e7          	jalr	1828(ra) # 80002f6c <sleep>
        while(buffer_count <= 0) {
    80003850:	00008797          	auipc	a5,0x8
    80003854:	7b878793          	add	a5,a5,1976 # 8000c008 <buffer_count>
    80003858:	439c                	lw	a5,0(a5)
    8000385a:	fcf058e3          	blez	a5,8000382a <consumer_task+0x2c>
        }
        
        // 消费数据
        int item = buffer[--buffer_count];
    8000385e:	00008797          	auipc	a5,0x8
    80003862:	7aa78793          	add	a5,a5,1962 # 8000c008 <buffer_count>
    80003866:	439c                	lw	a5,0(a5)
    80003868:	37fd                	addw	a5,a5,-1
    8000386a:	0007871b          	sext.w	a4,a5
    8000386e:	00008797          	auipc	a5,0x8
    80003872:	79a78793          	add	a5,a5,1946 # 8000c008 <buffer_count>
    80003876:	c398                	sw	a4,0(a5)
    80003878:	00008797          	auipc	a5,0x8
    8000387c:	79078793          	add	a5,a5,1936 # 8000c008 <buffer_count>
    80003880:	439c                	lw	a5,0(a5)
    80003882:	00008717          	auipc	a4,0x8
    80003886:	75e70713          	add	a4,a4,1886 # 8000bfe0 <buffer>
    8000388a:	078a                	sll	a5,a5,0x2
    8000388c:	97ba                	add	a5,a5,a4
    8000388e:	439c                	lw	a5,0(a5)
    80003890:	fef42423          	sw	a5,-24(s0)
        printf("[Consumer] Consumed: %d (buffer_count=%d)\n", 
    80003894:	00008797          	auipc	a5,0x8
    80003898:	77478793          	add	a5,a5,1908 # 8000c008 <buffer_count>
    8000389c:	4398                	lw	a4,0(a5)
    8000389e:	fe842783          	lw	a5,-24(s0)
    800038a2:	863a                	mv	a2,a4
    800038a4:	85be                	mv	a1,a5
    800038a6:	00002517          	auipc	a0,0x2
    800038aa:	f8a50513          	add	a0,a0,-118 # 80005830 <etext+0x1830>
    800038ae:	ffffd097          	auipc	ra,0xffffd
    800038b2:	278080e7          	jalr	632(ra) # 80000b26 <printf>
               item, buffer_count);
        
        // 唤醒生产者
        wakeup(buffer_not_full);
    800038b6:	00002797          	auipc	a5,0x2
    800038ba:	29a78793          	add	a5,a5,666 # 80005b50 <buffer_not_full>
    800038be:	639c                	ld	a5,0(a5)
    800038c0:	853e                	mv	a0,a5
    800038c2:	fffff097          	auipc	ra,0xfffff
    800038c6:	70a080e7          	jalr	1802(ra) # 80002fcc <wakeup>
        
        // 延时
        for(volatile int j = 0; j < 8000000; j++);
    800038ca:	fe042223          	sw	zero,-28(s0)
    800038ce:	a801                	j	800038de <consumer_task+0xe0>
    800038d0:	fe442783          	lw	a5,-28(s0)
    800038d4:	2781                	sext.w	a5,a5
    800038d6:	2785                	addw	a5,a5,1
    800038d8:	2781                	sext.w	a5,a5
    800038da:	fef42223          	sw	a5,-28(s0)
    800038de:	fe442783          	lw	a5,-28(s0)
    800038e2:	2781                	sext.w	a5,a5
    800038e4:	873e                	mv	a4,a5
    800038e6:	007a17b7          	lui	a5,0x7a1
    800038ea:	1ff78793          	add	a5,a5,511 # 7a11ff <_entry-0x7f85ee01>
    800038ee:	fee7d1e3          	bge	a5,a4,800038d0 <consumer_task+0xd2>
        yield();
    800038f2:	fffff097          	auipc	ra,0xfffff
    800038f6:	592080e7          	jalr	1426(ra) # 80002e84 <yield>
    for(int i = 0; i < 20; i++) {
    800038fa:	fec42783          	lw	a5,-20(s0)
    800038fe:	2785                	addw	a5,a5,1
    80003900:	fef42623          	sw	a5,-20(s0)
    80003904:	fec42783          	lw	a5,-20(s0)
    80003908:	0007871b          	sext.w	a4,a5
    8000390c:	47cd                	li	a5,19
    8000390e:	f4e7d1e3          	bge	a5,a4,80003850 <consumer_task+0x52>
    }
    
    printf("[Consumer] Finished\n");
    80003912:	00002517          	auipc	a0,0x2
    80003916:	f4e50513          	add	a0,a0,-178 # 80005860 <etext+0x1860>
    8000391a:	ffffd097          	auipc	ra,0xffffd
    8000391e:	20c080e7          	jalr	524(ra) # 80000b26 <printf>
}
    80003922:	0001                	nop
    80003924:	60e2                	ld	ra,24(sp)
    80003926:	6442                	ld	s0,16(sp)
    80003928:	6105                	add	sp,sp,32
    8000392a:	8082                	ret

000000008000392c <test_process_creation>:

// ==================== 测试函数 ====================

// 测试1：基本的进程创建
void test_process_creation(void) {
    8000392c:	1101                	add	sp,sp,-32
    8000392e:	ec06                	sd	ra,24(sp)
    80003930:	e822                	sd	s0,16(sp)
    80003932:	1000                	add	s0,sp,32
    printf("\n");
    80003934:	00002517          	auipc	a0,0x2
    80003938:	f4450513          	add	a0,a0,-188 # 80005878 <etext+0x1878>
    8000393c:	ffffd097          	auipc	ra,0xffffd
    80003940:	1ea080e7          	jalr	490(ra) # 80000b26 <printf>
    printf("========================================\n");
    80003944:	00002517          	auipc	a0,0x2
    80003948:	f3c50513          	add	a0,a0,-196 # 80005880 <etext+0x1880>
    8000394c:	ffffd097          	auipc	ra,0xffffd
    80003950:	1da080e7          	jalr	474(ra) # 80000b26 <printf>
    printf("=== Test 1: Process Creation ===\n");
    80003954:	00002517          	auipc	a0,0x2
    80003958:	f5c50513          	add	a0,a0,-164 # 800058b0 <etext+0x18b0>
    8000395c:	ffffd097          	auipc	ra,0xffffd
    80003960:	1ca080e7          	jalr	458(ra) # 80000b26 <printf>
    printf("========================================\n");
    80003964:	00002517          	auipc	a0,0x2
    80003968:	f1c50513          	add	a0,a0,-228 # 80005880 <etext+0x1880>
    8000396c:	ffffd097          	auipc	ra,0xffffd
    80003970:	1ba080e7          	jalr	442(ra) # 80000b26 <printf>
    
    // 创建3个简单任务
    int pid1 = kthread_create(simple_task_1, "task1");
    80003974:	00002597          	auipc	a1,0x2
    80003978:	f6458593          	add	a1,a1,-156 # 800058d8 <etext+0x18d8>
    8000397c:	00000517          	auipc	a0,0x0
    80003980:	ab450513          	add	a0,a0,-1356 # 80003430 <simple_task_1>
    80003984:	fffff097          	auipc	ra,0xfffff
    80003988:	234080e7          	jalr	564(ra) # 80002bb8 <kthread_create>
    8000398c:	87aa                	mv	a5,a0
    8000398e:	fef42623          	sw	a5,-20(s0)
    int pid2 = kthread_create(simple_task_2, "task2");
    80003992:	00002597          	auipc	a1,0x2
    80003996:	f4e58593          	add	a1,a1,-178 # 800058e0 <etext+0x18e0>
    8000399a:	00000517          	auipc	a0,0x0
    8000399e:	b3a50513          	add	a0,a0,-1222 # 800034d4 <simple_task_2>
    800039a2:	fffff097          	auipc	ra,0xfffff
    800039a6:	216080e7          	jalr	534(ra) # 80002bb8 <kthread_create>
    800039aa:	87aa                	mv	a5,a0
    800039ac:	fef42423          	sw	a5,-24(s0)
    int pid3 = kthread_create(simple_task_3, "task3");
    800039b0:	00002597          	auipc	a1,0x2
    800039b4:	f3858593          	add	a1,a1,-200 # 800058e8 <etext+0x18e8>
    800039b8:	00000517          	auipc	a0,0x0
    800039bc:	bc050513          	add	a0,a0,-1088 # 80003578 <simple_task_3>
    800039c0:	fffff097          	auipc	ra,0xfffff
    800039c4:	1f8080e7          	jalr	504(ra) # 80002bb8 <kthread_create>
    800039c8:	87aa                	mv	a5,a0
    800039ca:	fef42223          	sw	a5,-28(s0)
    
    printf("Created 3 tasks: PID %d, %d, %d\n", pid1, pid2, pid3);
    800039ce:	fe442683          	lw	a3,-28(s0)
    800039d2:	fe842703          	lw	a4,-24(s0)
    800039d6:	fec42783          	lw	a5,-20(s0)
    800039da:	863a                	mv	a2,a4
    800039dc:	85be                	mv	a1,a5
    800039de:	00002517          	auipc	a0,0x2
    800039e2:	f1250513          	add	a0,a0,-238 # 800058f0 <etext+0x18f0>
    800039e6:	ffffd097          	auipc	ra,0xffffd
    800039ea:	140080e7          	jalr	320(ra) # 80000b26 <printf>
    
    // 打印进程表
    print_proc_table();
    800039ee:	fffff097          	auipc	ra,0xfffff
    800039f2:	79a080e7          	jalr	1946(ra) # 80003188 <print_proc_table>
    
    // 等待所有子进程完成
    printf("Waiting for tasks to complete...\n");
    800039f6:	00002517          	auipc	a0,0x2
    800039fa:	f2250513          	add	a0,a0,-222 # 80005918 <etext+0x1918>
    800039fe:	ffffd097          	auipc	ra,0xffffd
    80003a02:	128080e7          	jalr	296(ra) # 80000b26 <printf>
    wait(0);
    80003a06:	4501                	li	a0,0
    80003a08:	fffff097          	auipc	ra,0xfffff
    80003a0c:	340080e7          	jalr	832(ra) # 80002d48 <wait>
    wait(0);
    80003a10:	4501                	li	a0,0
    80003a12:	fffff097          	auipc	ra,0xfffff
    80003a16:	336080e7          	jalr	822(ra) # 80002d48 <wait>
    wait(0);
    80003a1a:	4501                	li	a0,0
    80003a1c:	fffff097          	auipc	ra,0xfffff
    80003a20:	32c080e7          	jalr	812(ra) # 80002d48 <wait>
    
    printf("=== Test 1 Complete ===\n\n");
    80003a24:	00002517          	auipc	a0,0x2
    80003a28:	f1c50513          	add	a0,a0,-228 # 80005940 <etext+0x1940>
    80003a2c:	ffffd097          	auipc	ra,0xffffd
    80003a30:	0fa080e7          	jalr	250(ra) # 80000b26 <printf>
}
    80003a34:	0001                	nop
    80003a36:	60e2                	ld	ra,24(sp)
    80003a38:	6442                	ld	s0,16(sp)
    80003a3a:	6105                	add	sp,sp,32
    80003a3c:	8082                	ret

0000000080003a3e <test_scheduler>:

// 测试2：调度器测试
void test_scheduler(void) {
    80003a3e:	1101                	add	sp,sp,-32
    80003a40:	ec06                	sd	ra,24(sp)
    80003a42:	e822                	sd	s0,16(sp)
    80003a44:	1000                	add	s0,sp,32
    printf("\n");
    80003a46:	00002517          	auipc	a0,0x2
    80003a4a:	e3250513          	add	a0,a0,-462 # 80005878 <etext+0x1878>
    80003a4e:	ffffd097          	auipc	ra,0xffffd
    80003a52:	0d8080e7          	jalr	216(ra) # 80000b26 <printf>
    printf("========================================\n");
    80003a56:	00002517          	auipc	a0,0x2
    80003a5a:	e2a50513          	add	a0,a0,-470 # 80005880 <etext+0x1880>
    80003a5e:	ffffd097          	auipc	ra,0xffffd
    80003a62:	0c8080e7          	jalr	200(ra) # 80000b26 <printf>
    printf("=== Test 2: Scheduler ===\n");
    80003a66:	00002517          	auipc	a0,0x2
    80003a6a:	efa50513          	add	a0,a0,-262 # 80005960 <etext+0x1960>
    80003a6e:	ffffd097          	auipc	ra,0xffffd
    80003a72:	0b8080e7          	jalr	184(ra) # 80000b26 <printf>
    printf("========================================\n");
    80003a76:	00002517          	auipc	a0,0x2
    80003a7a:	e0a50513          	add	a0,a0,-502 # 80005880 <etext+0x1880>
    80003a7e:	ffffd097          	auipc	ra,0xffffd
    80003a82:	0a8080e7          	jalr	168(ra) # 80000b26 <printf>
    
    printf("Creating 3 CPU-intensive tasks...\n");
    80003a86:	00002517          	auipc	a0,0x2
    80003a8a:	efa50513          	add	a0,a0,-262 # 80005980 <etext+0x1980>
    80003a8e:	ffffd097          	auipc	ra,0xffffd
    80003a92:	098080e7          	jalr	152(ra) # 80000b26 <printf>
    
    uint64 start_time = get_ticks();
    80003a96:	fffff097          	auipc	ra,0xfffff
    80003a9a:	da8080e7          	jalr	-600(ra) # 8000283e <get_ticks>
    80003a9e:	fea43423          	sd	a0,-24(s0)
    
    kthread_create(cpu_intensive_task, "cpu1");
    80003aa2:	00002597          	auipc	a1,0x2
    80003aa6:	f0658593          	add	a1,a1,-250 # 800059a8 <etext+0x19a8>
    80003aaa:	00000517          	auipc	a0,0x0
    80003aae:	b7250513          	add	a0,a0,-1166 # 8000361c <cpu_intensive_task>
    80003ab2:	fffff097          	auipc	ra,0xfffff
    80003ab6:	106080e7          	jalr	262(ra) # 80002bb8 <kthread_create>
    kthread_create(cpu_intensive_task, "cpu2");
    80003aba:	00002597          	auipc	a1,0x2
    80003abe:	ef658593          	add	a1,a1,-266 # 800059b0 <etext+0x19b0>
    80003ac2:	00000517          	auipc	a0,0x0
    80003ac6:	b5a50513          	add	a0,a0,-1190 # 8000361c <cpu_intensive_task>
    80003aca:	fffff097          	auipc	ra,0xfffff
    80003ace:	0ee080e7          	jalr	238(ra) # 80002bb8 <kthread_create>
    kthread_create(cpu_intensive_task, "cpu3");
    80003ad2:	00002597          	auipc	a1,0x2
    80003ad6:	ee658593          	add	a1,a1,-282 # 800059b8 <etext+0x19b8>
    80003ada:	00000517          	auipc	a0,0x0
    80003ade:	b4250513          	add	a0,a0,-1214 # 8000361c <cpu_intensive_task>
    80003ae2:	fffff097          	auipc	ra,0xfffff
    80003ae6:	0d6080e7          	jalr	214(ra) # 80002bb8 <kthread_create>
    
    // 等待完成
    wait(0);
    80003aea:	4501                	li	a0,0
    80003aec:	fffff097          	auipc	ra,0xfffff
    80003af0:	25c080e7          	jalr	604(ra) # 80002d48 <wait>
    wait(0);
    80003af4:	4501                	li	a0,0
    80003af6:	fffff097          	auipc	ra,0xfffff
    80003afa:	252080e7          	jalr	594(ra) # 80002d48 <wait>
    wait(0);
    80003afe:	4501                	li	a0,0
    80003b00:	fffff097          	auipc	ra,0xfffff
    80003b04:	248080e7          	jalr	584(ra) # 80002d48 <wait>
    
    uint64 end_time = get_ticks();
    80003b08:	fffff097          	auipc	ra,0xfffff
    80003b0c:	d36080e7          	jalr	-714(ra) # 8000283e <get_ticks>
    80003b10:	fea43023          	sd	a0,-32(s0)
    
    printf("Scheduler test completed in %lu ticks\n", 
    80003b14:	fe043703          	ld	a4,-32(s0)
    80003b18:	fe843783          	ld	a5,-24(s0)
    80003b1c:	40f707b3          	sub	a5,a4,a5
    80003b20:	85be                	mv	a1,a5
    80003b22:	00002517          	auipc	a0,0x2
    80003b26:	e9e50513          	add	a0,a0,-354 # 800059c0 <etext+0x19c0>
    80003b2a:	ffffd097          	auipc	ra,0xffffd
    80003b2e:	ffc080e7          	jalr	-4(ra) # 80000b26 <printf>
           end_time - start_time);
    
    print_proc_table();
    80003b32:	fffff097          	auipc	ra,0xfffff
    80003b36:	656080e7          	jalr	1622(ra) # 80003188 <print_proc_table>
    
    printf("=== Test 2 Complete ===\n\n");
    80003b3a:	00002517          	auipc	a0,0x2
    80003b3e:	eae50513          	add	a0,a0,-338 # 800059e8 <etext+0x19e8>
    80003b42:	ffffd097          	auipc	ra,0xffffd
    80003b46:	fe4080e7          	jalr	-28(ra) # 80000b26 <printf>
}
    80003b4a:	0001                	nop
    80003b4c:	60e2                	ld	ra,24(sp)
    80003b4e:	6442                	ld	s0,16(sp)
    80003b50:	6105                	add	sp,sp,32
    80003b52:	8082                	ret

0000000080003b54 <test_synchronization>:

// 测试3：同步机制
void test_synchronization(void) {
    80003b54:	1141                	add	sp,sp,-16
    80003b56:	e406                	sd	ra,8(sp)
    80003b58:	e022                	sd	s0,0(sp)
    80003b5a:	0800                	add	s0,sp,16
    printf("\n");
    80003b5c:	00002517          	auipc	a0,0x2
    80003b60:	d1c50513          	add	a0,a0,-740 # 80005878 <etext+0x1878>
    80003b64:	ffffd097          	auipc	ra,0xffffd
    80003b68:	fc2080e7          	jalr	-62(ra) # 80000b26 <printf>
    printf("========================================\n");
    80003b6c:	00002517          	auipc	a0,0x2
    80003b70:	d1450513          	add	a0,a0,-748 # 80005880 <etext+0x1880>
    80003b74:	ffffd097          	auipc	ra,0xffffd
    80003b78:	fb2080e7          	jalr	-78(ra) # 80000b26 <printf>
    printf("=== Test 3: Synchronization ===\n");
    80003b7c:	00002517          	auipc	a0,0x2
    80003b80:	e8c50513          	add	a0,a0,-372 # 80005a08 <etext+0x1a08>
    80003b84:	ffffd097          	auipc	ra,0xffffd
    80003b88:	fa2080e7          	jalr	-94(ra) # 80000b26 <printf>
    printf("========================================\n");
    80003b8c:	00002517          	auipc	a0,0x2
    80003b90:	cf450513          	add	a0,a0,-780 # 80005880 <etext+0x1880>
    80003b94:	ffffd097          	auipc	ra,0xffffd
    80003b98:	f92080e7          	jalr	-110(ra) # 80000b26 <printf>
    
    printf("Testing producer-consumer pattern...\n");
    80003b9c:	00002517          	auipc	a0,0x2
    80003ba0:	e9450513          	add	a0,a0,-364 # 80005a30 <etext+0x1a30>
    80003ba4:	ffffd097          	auipc	ra,0xffffd
    80003ba8:	f82080e7          	jalr	-126(ra) # 80000b26 <printf>
    
    // 初始化缓冲区
    buffer_count = 0;
    80003bac:	00008797          	auipc	a5,0x8
    80003bb0:	45c78793          	add	a5,a5,1116 # 8000c008 <buffer_count>
    80003bb4:	0007a023          	sw	zero,0(a5)
    
    // 创建生产者和消费者
    kthread_create(producer_task, "producer");
    80003bb8:	00002597          	auipc	a1,0x2
    80003bbc:	ea058593          	add	a1,a1,-352 # 80005a58 <etext+0x1a58>
    80003bc0:	00000517          	auipc	a0,0x0
    80003bc4:	b1450513          	add	a0,a0,-1260 # 800036d4 <producer_task>
    80003bc8:	fffff097          	auipc	ra,0xfffff
    80003bcc:	ff0080e7          	jalr	-16(ra) # 80002bb8 <kthread_create>
    kthread_create(consumer_task, "consumer");
    80003bd0:	00002597          	auipc	a1,0x2
    80003bd4:	e9858593          	add	a1,a1,-360 # 80005a68 <etext+0x1a68>
    80003bd8:	00000517          	auipc	a0,0x0
    80003bdc:	c2650513          	add	a0,a0,-986 # 800037fe <consumer_task>
    80003be0:	fffff097          	auipc	ra,0xfffff
    80003be4:	fd8080e7          	jalr	-40(ra) # 80002bb8 <kthread_create>
    
    // 等待完成
    wait(0);
    80003be8:	4501                	li	a0,0
    80003bea:	fffff097          	auipc	ra,0xfffff
    80003bee:	15e080e7          	jalr	350(ra) # 80002d48 <wait>
    wait(0);
    80003bf2:	4501                	li	a0,0
    80003bf4:	fffff097          	auipc	ra,0xfffff
    80003bf8:	154080e7          	jalr	340(ra) # 80002d48 <wait>
    
    printf("=== Test 3 Complete ===\n\n");
    80003bfc:	00002517          	auipc	a0,0x2
    80003c00:	e7c50513          	add	a0,a0,-388 # 80005a78 <etext+0x1a78>
    80003c04:	ffffd097          	auipc	ra,0xffffd
    80003c08:	f22080e7          	jalr	-222(ra) # 80000b26 <printf>
}
    80003c0c:	0001                	nop
    80003c0e:	60a2                	ld	ra,8(sp)
    80003c10:	6402                	ld	s0,0(sp)
    80003c12:	0141                	add	sp,sp,16
    80003c14:	8082                	ret

0000000080003c16 <run_process_tests>:

// 主测试入口
void run_process_tests(void) {
    80003c16:	1141                	add	sp,sp,-16
    80003c18:	e406                	sd	ra,8(sp)
    80003c1a:	e022                	sd	s0,0(sp)
    80003c1c:	0800                	add	s0,sp,16
    printf("\n");
    80003c1e:	00002517          	auipc	a0,0x2
    80003c22:	c5a50513          	add	a0,a0,-934 # 80005878 <etext+0x1878>
    80003c26:	ffffd097          	auipc	ra,0xffffd
    80003c2a:	f00080e7          	jalr	-256(ra) # 80000b26 <printf>
    printf("========================================\n");
    80003c2e:	00002517          	auipc	a0,0x2
    80003c32:	c5250513          	add	a0,a0,-942 # 80005880 <etext+0x1880>
    80003c36:	ffffd097          	auipc	ra,0xffffd
    80003c3a:	ef0080e7          	jalr	-272(ra) # 80000b26 <printf>
    printf("=== Process Management Test Suite ===\n");
    80003c3e:	00002517          	auipc	a0,0x2
    80003c42:	e5a50513          	add	a0,a0,-422 # 80005a98 <etext+0x1a98>
    80003c46:	ffffd097          	auipc	ra,0xffffd
    80003c4a:	ee0080e7          	jalr	-288(ra) # 80000b26 <printf>
    printf("========================================\n");
    80003c4e:	00002517          	auipc	a0,0x2
    80003c52:	c3250513          	add	a0,a0,-974 # 80005880 <etext+0x1880>
    80003c56:	ffffd097          	auipc	ra,0xffffd
    80003c5a:	ed0080e7          	jalr	-304(ra) # 80000b26 <printf>
    
    // 测试1：进程创建
    test_process_creation();
    80003c5e:	00000097          	auipc	ra,0x0
    80003c62:	cce080e7          	jalr	-818(ra) # 8000392c <test_process_creation>
    
    // 打印统计
    print_proc_stats();
    80003c66:	fffff097          	auipc	ra,0xfffff
    80003c6a:	62e080e7          	jalr	1582(ra) # 80003294 <print_proc_stats>
    
    // 测试2：调度器
    test_scheduler();
    80003c6e:	00000097          	auipc	ra,0x0
    80003c72:	dd0080e7          	jalr	-560(ra) # 80003a3e <test_scheduler>
    
    // 打印统计
    print_proc_stats();
    80003c76:	fffff097          	auipc	ra,0xfffff
    80003c7a:	61e080e7          	jalr	1566(ra) # 80003294 <print_proc_stats>
    
    // 测试3：同步机制
    test_synchronization();
    80003c7e:	00000097          	auipc	ra,0x0
    80003c82:	ed6080e7          	jalr	-298(ra) # 80003b54 <test_synchronization>
    
    // 最终统计
    printf("\n=== Final Statistics ===\n");
    80003c86:	00002517          	auipc	a0,0x2
    80003c8a:	e3a50513          	add	a0,a0,-454 # 80005ac0 <etext+0x1ac0>
    80003c8e:	ffffd097          	auipc	ra,0xffffd
    80003c92:	e98080e7          	jalr	-360(ra) # 80000b26 <printf>
    print_proc_stats();
    80003c96:	fffff097          	auipc	ra,0xfffff
    80003c9a:	5fe080e7          	jalr	1534(ra) # 80003294 <print_proc_stats>
    print_proc_table();
    80003c9e:	fffff097          	auipc	ra,0xfffff
    80003ca2:	4ea080e7          	jalr	1258(ra) # 80003188 <print_proc_table>
    
    printf("\n");
    80003ca6:	00002517          	auipc	a0,0x2
    80003caa:	bd250513          	add	a0,a0,-1070 # 80005878 <etext+0x1878>
    80003cae:	ffffd097          	auipc	ra,0xffffd
    80003cb2:	e78080e7          	jalr	-392(ra) # 80000b26 <printf>
    printf("========================================\n");
    80003cb6:	00002517          	auipc	a0,0x2
    80003cba:	bca50513          	add	a0,a0,-1078 # 80005880 <etext+0x1880>
    80003cbe:	ffffd097          	auipc	ra,0xffffd
    80003cc2:	e68080e7          	jalr	-408(ra) # 80000b26 <printf>
    printf("=== All Process Tests Complete! ===\n");
    80003cc6:	00002517          	auipc	a0,0x2
    80003cca:	e1a50513          	add	a0,a0,-486 # 80005ae0 <etext+0x1ae0>
    80003cce:	ffffd097          	auipc	ra,0xffffd
    80003cd2:	e58080e7          	jalr	-424(ra) # 80000b26 <printf>
    printf("========================================\n\n");
    80003cd6:	00002517          	auipc	a0,0x2
    80003cda:	e3250513          	add	a0,a0,-462 # 80005b08 <etext+0x1b08>
    80003cde:	ffffd097          	auipc	ra,0xffffd
    80003ce2:	e48080e7          	jalr	-440(ra) # 80000b26 <printf>
    80003ce6:	0001                	nop
    80003ce8:	60a2                	ld	ra,8(sp)
    80003cea:	6402                	ld	s0,0(sp)
    80003cec:	0141                	add	sp,sp,16
    80003cee:	8082                	ret
	...
