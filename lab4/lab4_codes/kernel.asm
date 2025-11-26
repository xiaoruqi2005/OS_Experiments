
kernel/kernel.elf:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_start>:
.section .text.start
.globl _start

_start:
    # 设置栈指针
    li sp, 0x80010000
    80000000:	00008137          	lui	sp,0x8
    80000004:	2105                	addw	sp,sp,1 # 8001 <_start-0x7fff7fff>
    80000006:	0142                	sll	sp,sp,0x10
    
    # 输出启动标记
    li t0, 0x10000000    # UART基地址
    80000008:	100002b7          	lui	t0,0x10000
    li t1, 'S'           # 启动标记
    8000000c:	05300313          	li	t1,83
    sb t1, 0(t0)
    80000010:	00628023          	sb	t1,0(t0) # 10000000 <_start-0x70000000>
    
    # 清零BSS段
    la t0, bss_start
    80000014:	00007297          	auipc	t0,0x7
    80000018:	fec28293          	add	t0,t0,-20 # 80007000 <bss_start>
    la t1, bss_end
    8000001c:	0000a317          	auipc	t1,0xa
    80000020:	14430313          	add	t1,t1,324 # 8000a160 <bss_end>

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
    80000038:	00628023          	sb	t1,0(t0) # 10000000 <_start-0x70000000>
    
    # 跳转到start()在M模式初始化
    # start()会设置好中断委托，然后通过mret切换到S模式调用main()
    call start
    8000003c:	00000097          	auipc	ra,0x0
    80000040:	18e080e7          	jalr	398(ra) # 800001ca <start>

0000000080000044 <infinite_loop>:
    
    # 无限循环（不应该到达这里）
infinite_loop:
    j infinite_loop
    80000044:	a001                	j	80000044 <infinite_loop>

0000000080000046 <w_satp>:
// 每个hart一个临时栈
__attribute__ ((aligned (16))) char m_stack0[4096];

void start()
{
    // 设置mstatus的MPP字段为Supervisor模式
    80000046:	1101                	add	sp,sp,-32
    80000048:	ec22                	sd	s0,24(sp)
    8000004a:	1000                	add	s0,sp,32
    8000004c:	fea43423          	sd	a0,-24(s0)
    unsigned long x = r_mstatus();
    80000050:	fe843783          	ld	a5,-24(s0)
    80000054:	18079073          	csrw	satp,a5
    x &= ~MSTATUS_MPP_MASK;
    80000058:	0001                	nop
    8000005a:	6462                	ld	s0,24(sp)
    8000005c:	6105                	add	sp,sp,32
    8000005e:	8082                	ret

0000000080000060 <r_mhartid>:

    // 设置mepc为main函数地址
    w_mepc((uint64)main);

    // 禁用S模式分页
    w_satp(0);
    80000060:	1101                	add	sp,sp,-32
    80000062:	ec22                	sd	s0,24(sp)
    80000064:	1000                	add	s0,sp,32

    // 配置中断委托
    80000066:	f14027f3          	csrr	a5,mhartid
    8000006a:	fef43423          	sd	a5,-24(s0)
    w_medeleg(0xffff);
    8000006e:	fe843783          	ld	a5,-24(s0)
    w_mideleg((1 << IRQ_S_SOFT) | (1 << IRQ_S_TIMER) | (1 << IRQ_S_EXT));
    80000072:	853e                	mv	a0,a5
    80000074:	6462                	ld	s0,24(sp)
    80000076:	6105                	add	sp,sp,32
    80000078:	8082                	ret

000000008000007a <r_mstatus>:

    // 启用S模式中断
    8000007a:	1101                	add	sp,sp,-32
    8000007c:	ec22                	sd	s0,24(sp)
    8000007e:	1000                	add	s0,sp,32
    w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);

    80000080:	300027f3          	csrr	a5,mstatus
    80000084:	fef43423          	sd	a5,-24(s0)
    // 配置PMP
    80000088:	fe843783          	ld	a5,-24(s0)
    w_pmpaddr0(0x3fffffffffffffull);
    8000008c:	853e                	mv	a0,a5
    8000008e:	6462                	ld	s0,24(sp)
    80000090:	6105                	add	sp,sp,32
    80000092:	8082                	ret

0000000080000094 <w_mstatus>:
    w_pmpcfg0(0xf);

    80000094:	1101                	add	sp,sp,-32
    80000096:	ec22                	sd	s0,24(sp)
    80000098:	1000                	add	s0,sp,32
    8000009a:	fea43423          	sd	a0,-24(s0)
    // 配置M模式时钟中断
    8000009e:	fe843783          	ld	a5,-24(s0)
    800000a2:	30079073          	csrw	mstatus,a5
    timer_init_hart();
    800000a6:	0001                	nop
    800000a8:	6462                	ld	s0,24(sp)
    800000aa:	6105                	add	sp,sp,32
    800000ac:	8082                	ret

00000000800000ae <r_sie>:
    800000ae:	1101                	add	sp,sp,-32
    800000b0:	ec22                	sd	s0,24(sp)
    800000b2:	1000                	add	s0,sp,32
    800000b4:	104027f3          	csrr	a5,sie
    800000b8:	fef43423          	sd	a5,-24(s0)
    800000bc:	fe843783          	ld	a5,-24(s0)
    800000c0:	853e                	mv	a0,a5
    800000c2:	6462                	ld	s0,24(sp)
    800000c4:	6105                	add	sp,sp,32
    800000c6:	8082                	ret

00000000800000c8 <w_sie>:
    800000c8:	1101                	add	sp,sp,-32
    800000ca:	ec22                	sd	s0,24(sp)
    800000cc:	1000                	add	s0,sp,32
    800000ce:	fea43423          	sd	a0,-24(s0)
    800000d2:	fe843783          	ld	a5,-24(s0)
    800000d6:	10479073          	csrw	sie,a5
    800000da:	0001                	nop
    800000dc:	6462                	ld	s0,24(sp)
    800000de:	6105                	add	sp,sp,32
    800000e0:	8082                	ret

00000000800000e2 <w_mepc>:
    800000e2:	1101                	add	sp,sp,-32
    800000e4:	ec22                	sd	s0,24(sp)
    800000e6:	1000                	add	s0,sp,32
    800000e8:	fea43423          	sd	a0,-24(s0)
    800000ec:	fe843783          	ld	a5,-24(s0)
    800000f0:	34179073          	csrw	mepc,a5
    800000f4:	0001                	nop
    800000f6:	6462                	ld	s0,24(sp)
    800000f8:	6105                	add	sp,sp,32
    800000fa:	8082                	ret

00000000800000fc <w_medeleg>:
    800000fc:	1101                	add	sp,sp,-32
    800000fe:	ec22                	sd	s0,24(sp)
    80000100:	1000                	add	s0,sp,32
    80000102:	fea43423          	sd	a0,-24(s0)
    80000106:	fe843783          	ld	a5,-24(s0)
    8000010a:	30279073          	csrw	medeleg,a5
    8000010e:	0001                	nop
    80000110:	6462                	ld	s0,24(sp)
    80000112:	6105                	add	sp,sp,32
    80000114:	8082                	ret

0000000080000116 <w_mideleg>:
    80000116:	1101                	add	sp,sp,-32
    80000118:	ec22                	sd	s0,24(sp)
    8000011a:	1000                	add	s0,sp,32
    8000011c:	fea43423          	sd	a0,-24(s0)
    80000120:	fe843783          	ld	a5,-24(s0)
    80000124:	30379073          	csrw	mideleg,a5
    80000128:	0001                	nop
    8000012a:	6462                	ld	s0,24(sp)
    8000012c:	6105                	add	sp,sp,32
    8000012e:	8082                	ret

0000000080000130 <w_mie>:
    80000130:	1101                	add	sp,sp,-32
    80000132:	ec22                	sd	s0,24(sp)
    80000134:	1000                	add	s0,sp,32
    80000136:	fea43423          	sd	a0,-24(s0)
    8000013a:	fe843783          	ld	a5,-24(s0)
    8000013e:	30479073          	csrw	mie,a5
    80000142:	0001                	nop
    80000144:	6462                	ld	s0,24(sp)
    80000146:	6105                	add	sp,sp,32
    80000148:	8082                	ret

000000008000014a <r_mie>:
    8000014a:	1101                	add	sp,sp,-32
    8000014c:	ec22                	sd	s0,24(sp)
    8000014e:	1000                	add	s0,sp,32
    80000150:	304027f3          	csrr	a5,mie
    80000154:	fef43423          	sd	a5,-24(s0)
    80000158:	fe843783          	ld	a5,-24(s0)
    8000015c:	853e                	mv	a0,a5
    8000015e:	6462                	ld	s0,24(sp)
    80000160:	6105                	add	sp,sp,32
    80000162:	8082                	ret

0000000080000164 <w_mtvec>:
    80000164:	1101                	add	sp,sp,-32
    80000166:	ec22                	sd	s0,24(sp)
    80000168:	1000                	add	s0,sp,32
    8000016a:	fea43423          	sd	a0,-24(s0)
    8000016e:	fe843783          	ld	a5,-24(s0)
    80000172:	30579073          	csrw	mtvec,a5
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

00000000800001b2 <w_tp>:
    800001b2:	1101                	add	sp,sp,-32
    800001b4:	ec22                	sd	s0,24(sp)
    800001b6:	1000                	add	s0,sp,32
    800001b8:	fea43423          	sd	a0,-24(s0)
    800001bc:	fe843783          	ld	a5,-24(s0)
    800001c0:	823e                	mv	tp,a5
    800001c2:	0001                	nop
    800001c4:	6462                	ld	s0,24(sp)
    800001c6:	6105                	add	sp,sp,32
    800001c8:	8082                	ret

00000000800001ca <start>:
{
    800001ca:	1101                	add	sp,sp,-32
    800001cc:	ec06                	sd	ra,24(sp)
    800001ce:	e822                	sd	s0,16(sp)
    800001d0:	1000                	add	s0,sp,32
    unsigned long x = r_mstatus();
    800001d2:	00000097          	auipc	ra,0x0
    800001d6:	ea8080e7          	jalr	-344(ra) # 8000007a <r_mstatus>
    800001da:	fea43423          	sd	a0,-24(s0)
    x &= ~MSTATUS_MPP_MASK;
    800001de:	fe843703          	ld	a4,-24(s0)
    800001e2:	77f9                	lui	a5,0xffffe
    800001e4:	7ff78793          	add	a5,a5,2047 # ffffffffffffe7ff <kernel_pagetable+0xffffffff7fff37f7>
    800001e8:	8ff9                	and	a5,a5,a4
    800001ea:	fef43423          	sd	a5,-24(s0)
    x |= MSTATUS_MPP_S;
    800001ee:	fe843703          	ld	a4,-24(s0)
    800001f2:	6785                	lui	a5,0x1
    800001f4:	80078793          	add	a5,a5,-2048 # 800 <_start-0x7ffff800>
    800001f8:	8fd9                	or	a5,a5,a4
    800001fa:	fef43423          	sd	a5,-24(s0)
    w_mstatus(x);
    800001fe:	fe843503          	ld	a0,-24(s0)
    80000202:	00000097          	auipc	ra,0x0
    80000206:	e92080e7          	jalr	-366(ra) # 80000094 <w_mstatus>
    w_mepc((uint64)main);
    8000020a:	00000797          	auipc	a5,0x0
    8000020e:	1ec78793          	add	a5,a5,492 # 800003f6 <main>
    80000212:	853e                	mv	a0,a5
    80000214:	00000097          	auipc	ra,0x0
    80000218:	ece080e7          	jalr	-306(ra) # 800000e2 <w_mepc>
    w_satp(0);
    8000021c:	4501                	li	a0,0
    8000021e:	00000097          	auipc	ra,0x0
    80000222:	e28080e7          	jalr	-472(ra) # 80000046 <w_satp>
    w_medeleg(0xffff);
    80000226:	67c1                	lui	a5,0x10
    80000228:	fff78513          	add	a0,a5,-1 # ffff <_start-0x7fff0001>
    8000022c:	00000097          	auipc	ra,0x0
    80000230:	ed0080e7          	jalr	-304(ra) # 800000fc <w_medeleg>
    w_mideleg((1 << IRQ_S_SOFT) | (1 << IRQ_S_TIMER) | (1 << IRQ_S_EXT));
    80000234:	22200513          	li	a0,546
    80000238:	00000097          	auipc	ra,0x0
    8000023c:	ede080e7          	jalr	-290(ra) # 80000116 <w_mideleg>
    w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    80000240:	00000097          	auipc	ra,0x0
    80000244:	e6e080e7          	jalr	-402(ra) # 800000ae <r_sie>
    80000248:	87aa                	mv	a5,a0
    8000024a:	2227e793          	or	a5,a5,546
    8000024e:	853e                	mv	a0,a5
    80000250:	00000097          	auipc	ra,0x0
    80000254:	e78080e7          	jalr	-392(ra) # 800000c8 <w_sie>
    w_pmpaddr0(0x3fffffffffffffull);
    80000258:	57fd                	li	a5,-1
    8000025a:	00a7d513          	srl	a0,a5,0xa
    8000025e:	00000097          	auipc	ra,0x0
    80000262:	f20080e7          	jalr	-224(ra) # 8000017e <w_pmpaddr0>
    w_pmpcfg0(0xf);
    80000266:	453d                	li	a0,15
    80000268:	00000097          	auipc	ra,0x0
    8000026c:	f30080e7          	jalr	-208(ra) # 80000198 <w_pmpcfg0>
    timer_init_hart();
    80000270:	00003097          	auipc	ra,0x3
    80000274:	92c080e7          	jalr	-1748(ra) # 80002b9c <timer_init_hart>
    w_mtvec((uint64)timervec);
    80000278:	00003797          	auipc	a5,0x3
    8000027c:	89878793          	add	a5,a5,-1896 # 80002b10 <timervec>
    80000280:	853e                	mv	a0,a5
    80000282:	00000097          	auipc	ra,0x0
    80000286:	ee2080e7          	jalr	-286(ra) # 80000164 <w_mtvec>
    w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000028a:	00000097          	auipc	ra,0x0
    8000028e:	df0080e7          	jalr	-528(ra) # 8000007a <r_mstatus>
    80000292:	87aa                	mv	a5,a0
    80000294:	0087e793          	or	a5,a5,8
    80000298:	853e                	mv	a0,a5
    8000029a:	00000097          	auipc	ra,0x0
    8000029e:	dfa080e7          	jalr	-518(ra) # 80000094 <w_mstatus>
    w_mie(r_mie() | MIE_MTIE);
    800002a2:	00000097          	auipc	ra,0x0
    800002a6:	ea8080e7          	jalr	-344(ra) # 8000014a <r_mie>
    800002aa:	87aa                	mv	a5,a0
    800002ac:	0807e793          	or	a5,a5,128
    800002b0:	853e                	mv	a0,a5
    800002b2:	00000097          	auipc	ra,0x0
    800002b6:	e7e080e7          	jalr	-386(ra) # 80000130 <w_mie>
    int id = r_mhartid();
    800002ba:	00000097          	auipc	ra,0x0
    800002be:	da6080e7          	jalr	-602(ra) # 80000060 <r_mhartid>
    800002c2:	87aa                	mv	a5,a0
    800002c4:	fef42223          	sw	a5,-28(s0)
    w_tp(id);
    800002c8:	fe442783          	lw	a5,-28(s0)
    800002cc:	853e                	mv	a0,a5
    800002ce:	00000097          	auipc	ra,0x0
    800002d2:	ee4080e7          	jalr	-284(ra) # 800001b2 <w_tp>
    asm volatile("mret");
    800002d6:	30200073          	mret
    800002da:	0001                	nop
    800002dc:	60e2                	ld	ra,24(sp)
    800002de:	6442                	ld	s0,16(sp)
    800002e0:	6105                	add	sp,sp,32
    800002e2:	8082                	ret

00000000800002e4 <r_satp>:

void test_permissions(void) {
    printf("\n=== Testing Page Permissions ===\n");
    
    // 测试代码段
    uint64 code_addr = 0x80001000;
    800002e4:	1101                	add	sp,sp,-32
    800002e6:	ec22                	sd	s0,24(sp)
    800002e8:	1000                	add	s0,sp,32
    printf("Testing code segment at %p:\n", (void*)code_addr);
    
    800002ea:	180027f3          	csrr	a5,satp
    800002ee:	fef43423          	sd	a5,-24(s0)
    if(check_page_permission(code_addr, ACCESS_READ))
    800002f2:	fe843783          	ld	a5,-24(s0)
        printf("  Read: ALLOWED\n");
    800002f6:	853e                	mv	a0,a5
    800002f8:	6462                	ld	s0,24(sp)
    800002fa:	6105                	add	sp,sp,32
    800002fc:	8082                	ret

00000000800002fe <r_tp>:
    800002fe:	1101                	add	sp,sp,-32
    80000300:	ec22                	sd	s0,24(sp)
    80000302:	1000                	add	s0,sp,32
    80000304:	8792                	mv	a5,tp
    80000306:	fef43423          	sd	a5,-24(s0)
    8000030a:	fe843783          	ld	a5,-24(s0)
    8000030e:	853e                	mv	a0,a5
    80000310:	6462                	ld	s0,24(sp)
    80000312:	6105                	add	sp,sp,32
    80000314:	8082                	ret

0000000080000316 <test_permissions>:
void test_permissions(void) {
    80000316:	1101                	add	sp,sp,-32
    80000318:	ec06                	sd	ra,24(sp)
    8000031a:	e822                	sd	s0,16(sp)
    8000031c:	1000                	add	s0,sp,32
    printf("\n=== Testing Page Permissions ===\n");
    8000031e:	00003517          	auipc	a0,0x3
    80000322:	ce250513          	add	a0,a0,-798 # 80003000 <etext>
    80000326:	00000097          	auipc	ra,0x0
    8000032a:	6e6080e7          	jalr	1766(ra) # 80000a0c <printf>
    uint64 code_addr = 0x80001000;
    8000032e:	000807b7          	lui	a5,0x80
    80000332:	0785                	add	a5,a5,1 # 80001 <_start-0x7ff7ffff>
    80000334:	07b2                	sll	a5,a5,0xc
    80000336:	fef43423          	sd	a5,-24(s0)
    printf("Testing code segment at %p:\n", (void*)code_addr);
    8000033a:	fe843783          	ld	a5,-24(s0)
    8000033e:	85be                	mv	a1,a5
    80000340:	00003517          	auipc	a0,0x3
    80000344:	ce850513          	add	a0,a0,-792 # 80003028 <etext+0x28>
    80000348:	00000097          	auipc	ra,0x0
    8000034c:	6c4080e7          	jalr	1732(ra) # 80000a0c <printf>
    if(check_page_permission(code_addr, ACCESS_READ))
    80000350:	4585                	li	a1,1
    80000352:	fe843503          	ld	a0,-24(s0)
    80000356:	00001097          	auipc	ra,0x1
    8000035a:	67c080e7          	jalr	1660(ra) # 800019d2 <check_page_permission>
    8000035e:	87aa                	mv	a5,a0
    80000360:	cb91                	beqz	a5,80000374 <test_permissions+0x5e>
        printf("  Read: ALLOWED\n");
    80000362:	00003517          	auipc	a0,0x3
    80000366:	ce650513          	add	a0,a0,-794 # 80003048 <etext+0x48>
    8000036a:	00000097          	auipc	ra,0x0
    8000036e:	6a2080e7          	jalr	1698(ra) # 80000a0c <printf>
    80000372:	a809                	j	80000384 <test_permissions+0x6e>
        printf("  Read: DENIED\n");
    80000374:	00003517          	auipc	a0,0x3
    80000378:	cec50513          	add	a0,a0,-788 # 80003060 <etext+0x60>
    8000037c:	00000097          	auipc	ra,0x0
    80000380:	690080e7          	jalr	1680(ra) # 80000a0c <printf>
    if(check_page_permission(code_addr, ACCESS_WRITE))
    80000384:	4589                	li	a1,2
    80000386:	fe843503          	ld	a0,-24(s0)
    8000038a:	00001097          	auipc	ra,0x1
    8000038e:	648080e7          	jalr	1608(ra) # 800019d2 <check_page_permission>
    80000392:	87aa                	mv	a5,a0
    80000394:	cb91                	beqz	a5,800003a8 <test_permissions+0x92>
        printf("  Write: ALLOWED\n");
    80000396:	00003517          	auipc	a0,0x3
    8000039a:	cda50513          	add	a0,a0,-806 # 80003070 <etext+0x70>
    8000039e:	00000097          	auipc	ra,0x0
    800003a2:	66e080e7          	jalr	1646(ra) # 80000a0c <printf>
    800003a6:	a809                	j	800003b8 <test_permissions+0xa2>
        printf("  Write: DENIED\n");
    800003a8:	00003517          	auipc	a0,0x3
    800003ac:	ce050513          	add	a0,a0,-800 # 80003088 <etext+0x88>
    800003b0:	00000097          	auipc	ra,0x0
    800003b4:	65c080e7          	jalr	1628(ra) # 80000a0c <printf>
    if(check_page_permission(code_addr, ACCESS_EXEC))
    800003b8:	4591                	li	a1,4
    800003ba:	fe843503          	ld	a0,-24(s0)
    800003be:	00001097          	auipc	ra,0x1
    800003c2:	614080e7          	jalr	1556(ra) # 800019d2 <check_page_permission>
    800003c6:	87aa                	mv	a5,a0
    800003c8:	cb91                	beqz	a5,800003dc <test_permissions+0xc6>
        printf("  Execute: ALLOWED\n");
    800003ca:	00003517          	auipc	a0,0x3
    800003ce:	cd650513          	add	a0,a0,-810 # 800030a0 <etext+0xa0>
    800003d2:	00000097          	auipc	ra,0x0
    800003d6:	63a080e7          	jalr	1594(ra) # 80000a0c <printf>
}
    800003da:	a809                	j	800003ec <test_permissions+0xd6>
        printf("  Execute: DENIED\n");
    800003dc:	00003517          	auipc	a0,0x3
    800003e0:	cdc50513          	add	a0,a0,-804 # 800030b8 <etext+0xb8>
    800003e4:	00000097          	auipc	ra,0x0
    800003e8:	628080e7          	jalr	1576(ra) # 80000a0c <printf>
}
    800003ec:	0001                	nop
    800003ee:	60e2                	ld	ra,24(sp)
    800003f0:	6442                	ld	s0,16(sp)
    800003f2:	6105                	add	sp,sp,32
    800003f4:	8082                	ret

00000000800003f6 <main>:
void main(void) {
    800003f6:	7139                	add	sp,sp,-64
    800003f8:	fc06                	sd	ra,56(sp)
    800003fa:	f822                	sd	s0,48(sp)
    800003fc:	f426                	sd	s1,40(sp)
    800003fe:	0080                	add	s0,sp,64
    consoleinit();
    80000400:	00000097          	auipc	ra,0x0
    80000404:	484080e7          	jalr	1156(ra) # 80000884 <consoleinit>
    clear_screen();
    80000408:	00001097          	auipc	ra,0x1
    8000040c:	a04080e7          	jalr	-1532(ra) # 80000e0c <clear_screen>
    printf("=== RISC-V OS Lab 4: Interrupts & Timer ===\n");
    80000410:	00003517          	auipc	a0,0x3
    80000414:	cc050513          	add	a0,a0,-832 # 800030d0 <etext+0xd0>
    80000418:	00000097          	auipc	ra,0x0
    8000041c:	5f4080e7          	jalr	1524(ra) # 80000a0c <printf>
    printf("System Information:\n");
    80000420:	00003517          	auipc	a0,0x3
    80000424:	ce050513          	add	a0,a0,-800 # 80003100 <etext+0x100>
    80000428:	00000097          	auipc	ra,0x0
    8000042c:	5e4080e7          	jalr	1508(ra) # 80000a0c <printf>
    printf("  Hart ID:  %d\n", (int)r_tp());
    80000430:	00000097          	auipc	ra,0x0
    80000434:	ece080e7          	jalr	-306(ra) # 800002fe <r_tp>
    80000438:	87aa                	mv	a5,a0
    8000043a:	2781                	sext.w	a5,a5
    8000043c:	85be                	mv	a1,a5
    8000043e:	00003517          	auipc	a0,0x3
    80000442:	cda50513          	add	a0,a0,-806 # 80003118 <etext+0x118>
    80000446:	00000097          	auipc	ra,0x0
    8000044a:	5c6080e7          	jalr	1478(ra) # 80000a0c <printf>
    printf("  KERNBASE: %p\n", (void*)KERNBASE);
    8000044e:	4785                	li	a5,1
    80000450:	01f79593          	sll	a1,a5,0x1f
    80000454:	00003517          	auipc	a0,0x3
    80000458:	cd450513          	add	a0,a0,-812 # 80003128 <etext+0x128>
    8000045c:	00000097          	auipc	ra,0x0
    80000460:	5b0080e7          	jalr	1456(ra) # 80000a0c <printf>
    printf("  PHYSTOP:  %p\n", (void*)PHYSTOP);
    80000464:	47c5                	li	a5,17
    80000466:	01b79593          	sll	a1,a5,0x1b
    8000046a:	00003517          	auipc	a0,0x3
    8000046e:	cce50513          	add	a0,a0,-818 # 80003138 <etext+0x138>
    80000472:	00000097          	auipc	ra,0x0
    80000476:	59a080e7          	jalr	1434(ra) # 80000a0c <printf>
    printf("\nKernel symbols:\n");
    8000047a:	00003517          	auipc	a0,0x3
    8000047e:	cce50513          	add	a0,a0,-818 # 80003148 <etext+0x148>
    80000482:	00000097          	auipc	ra,0x0
    80000486:	58a080e7          	jalr	1418(ra) # 80000a0c <printf>
    printf("  etext: %p\n", etext);
    8000048a:	00003597          	auipc	a1,0x3
    8000048e:	b7658593          	add	a1,a1,-1162 # 80003000 <etext>
    80000492:	00003517          	auipc	a0,0x3
    80000496:	cce50513          	add	a0,a0,-818 # 80003160 <etext+0x160>
    8000049a:	00000097          	auipc	ra,0x0
    8000049e:	572080e7          	jalr	1394(ra) # 80000a0c <printf>
    printf("  edata: %p\n", edata);
    800004a2:	00006597          	auipc	a1,0x6
    800004a6:	b5e58593          	add	a1,a1,-1186 # 80006000 <timer_interval>
    800004aa:	00003517          	auipc	a0,0x3
    800004ae:	cc650513          	add	a0,a0,-826 # 80003170 <etext+0x170>
    800004b2:	00000097          	auipc	ra,0x0
    800004b6:	55a080e7          	jalr	1370(ra) # 80000a0c <printf>
    printf("  end:   %p\n", end);
    800004ba:	0000b597          	auipc	a1,0xb
    800004be:	b4658593          	add	a1,a1,-1210 # 8000b000 <panicking>
    800004c2:	00003517          	auipc	a0,0x3
    800004c6:	cbe50513          	add	a0,a0,-834 # 80003180 <etext+0x180>
    800004ca:	00000097          	auipc	ra,0x0
    800004ce:	542080e7          	jalr	1346(ra) # 80000a0c <printf>
    printf("\n=== Phase 1: Physical Memory Management ===\n");
    800004d2:	00003517          	auipc	a0,0x3
    800004d6:	cbe50513          	add	a0,a0,-834 # 80003190 <etext+0x190>
    800004da:	00000097          	auipc	ra,0x0
    800004de:	532080e7          	jalr	1330(ra) # 80000a0c <printf>
    pmm_init();
    800004e2:	00001097          	auipc	ra,0x1
    800004e6:	ab2080e7          	jalr	-1358(ra) # 80000f94 <pmm_init>
    printf("\n=== Phase 2: Virtual Memory Activation ===\n");
    800004ea:	00003517          	auipc	a0,0x3
    800004ee:	cd650513          	add	a0,a0,-810 # 800031c0 <etext+0x1c0>
    800004f2:	00000097          	auipc	ra,0x0
    800004f6:	51a080e7          	jalr	1306(ra) # 80000a0c <printf>
    printf("Current satp: %p\n", (void*)r_satp());
    800004fa:	00000097          	auipc	ra,0x0
    800004fe:	dea080e7          	jalr	-534(ra) # 800002e4 <r_satp>
    80000502:	87aa                	mv	a5,a0
    80000504:	85be                	mv	a1,a5
    80000506:	00003517          	auipc	a0,0x3
    8000050a:	cea50513          	add	a0,a0,-790 # 800031f0 <etext+0x1f0>
    8000050e:	00000097          	auipc	ra,0x0
    80000512:	4fe080e7          	jalr	1278(ra) # 80000a0c <printf>
    kvminit();
    80000516:	00001097          	auipc	ra,0x1
    8000051a:	1d8080e7          	jalr	472(ra) # 800016ee <kvminit>
    kvminithart();
    8000051e:	00001097          	auipc	ra,0x1
    80000522:	344080e7          	jalr	836(ra) # 80001862 <kvminithart>
    printf("Virtual memory enabled! New satp: %p\n", (void*)r_satp());
    80000526:	00000097          	auipc	ra,0x0
    8000052a:	dbe080e7          	jalr	-578(ra) # 800002e4 <r_satp>
    8000052e:	87aa                	mv	a5,a0
    80000530:	85be                	mv	a1,a5
    80000532:	00003517          	auipc	a0,0x3
    80000536:	cd650513          	add	a0,a0,-810 # 80003208 <etext+0x208>
    8000053a:	00000097          	auipc	ra,0x0
    8000053e:	4d2080e7          	jalr	1234(ra) # 80000a0c <printf>
    printf("\n=== Phase 3: Interrupt System ===\n");
    80000542:	00003517          	auipc	a0,0x3
    80000546:	cee50513          	add	a0,a0,-786 # 80003230 <etext+0x230>
    8000054a:	00000097          	auipc	ra,0x0
    8000054e:	4c2080e7          	jalr	1218(ra) # 80000a0c <printf>
    trap_init();
    80000552:	00002097          	auipc	ra,0x2
    80000556:	9cc080e7          	jalr	-1588(ra) # 80001f1e <trap_init>
    printf("\n=== Phase 4: Timer System ===\n");
    8000055a:	00003517          	auipc	a0,0x3
    8000055e:	cfe50513          	add	a0,a0,-770 # 80003258 <etext+0x258>
    80000562:	00000097          	auipc	ra,0x0
    80000566:	4aa080e7          	jalr	1194(ra) # 80000a0c <printf>
    timer_init();
    8000056a:	00002097          	auipc	ra,0x2
    8000056e:	78c080e7          	jalr	1932(ra) # 80002cf6 <timer_init>
    printf("\n=== System Ready ===\n");
    80000572:	00003517          	auipc	a0,0x3
    80000576:	d0650513          	add	a0,a0,-762 # 80003278 <etext+0x278>
    8000057a:	00000097          	auipc	ra,0x0
    8000057e:	492080e7          	jalr	1170(ra) # 80000a0c <printf>
    printf("All subsystems initialized successfully!\n");
    80000582:	00003517          	auipc	a0,0x3
    80000586:	d0e50513          	add	a0,a0,-754 # 80003290 <etext+0x290>
    8000058a:	00000097          	auipc	ra,0x0
    8000058e:	482080e7          	jalr	1154(ra) # 80000a0c <printf>
    printf("- Physical memory manager\n");
    80000592:	00003517          	auipc	a0,0x3
    80000596:	d2e50513          	add	a0,a0,-722 # 800032c0 <etext+0x2c0>
    8000059a:	00000097          	auipc	ra,0x0
    8000059e:	472080e7          	jalr	1138(ra) # 80000a0c <printf>
    printf("- Virtual memory (Sv39)\n");
    800005a2:	00003517          	auipc	a0,0x3
    800005a6:	d3e50513          	add	a0,a0,-706 # 800032e0 <etext+0x2e0>
    800005aa:	00000097          	auipc	ra,0x0
    800005ae:	462080e7          	jalr	1122(ra) # 80000a0c <printf>
    printf("- Interrupt handling\n");
    800005b2:	00003517          	auipc	a0,0x3
    800005b6:	d4e50513          	add	a0,a0,-690 # 80003300 <etext+0x300>
    800005ba:	00000097          	auipc	ra,0x0
    800005be:	452080e7          	jalr	1106(ra) # 80000a0c <printf>
    printf("- Timer interrupts\n");
    800005c2:	00003517          	auipc	a0,0x3
    800005c6:	d5650513          	add	a0,a0,-682 # 80003318 <etext+0x318>
    800005ca:	00000097          	auipc	ra,0x0
    800005ce:	442080e7          	jalr	1090(ra) # 80000a0c <printf>
    printf("\nWaiting for timer interrupts...\n");
    800005d2:	00003517          	auipc	a0,0x3
    800005d6:	d5e50513          	add	a0,a0,-674 # 80003330 <etext+0x330>
    800005da:	00000097          	auipc	ra,0x0
    800005de:	432080e7          	jalr	1074(ra) # 80000a0c <printf>
    printf("(Timer interrupt every 100ms)\n");
    800005e2:	00003517          	auipc	a0,0x3
    800005e6:	d7650513          	add	a0,a0,-650 # 80003358 <etext+0x358>
    800005ea:	00000097          	auipc	ra,0x0
    800005ee:	422080e7          	jalr	1058(ra) # 80000a0c <printf>
    int last_second = -1;
    800005f2:	57fd                	li	a5,-1
    800005f4:	fcf42e23          	sw	a5,-36(s0)
    for(int i = 0; i < 100; i++) {  // 改为1000次循环，运行更久
    800005f8:	fc042c23          	sw	zero,-40(s0)
    800005fc:	a059                	j	80000682 <main+0x28c>
        uint64 current_second = get_uptime_seconds();
    800005fe:	00002097          	auipc	ra,0x2
    80000602:	680080e7          	jalr	1664(ra) # 80002c7e <get_uptime_seconds>
    80000606:	fca43823          	sd	a0,-48(s0)
        if(current_second != last_second) {
    8000060a:	fdc42783          	lw	a5,-36(s0)
    8000060e:	fd043703          	ld	a4,-48(s0)
    80000612:	02f70a63          	beq	a4,a5,80000646 <main+0x250>
            last_second = current_second;
    80000616:	fd043783          	ld	a5,-48(s0)
    8000061a:	fcf42e23          	sw	a5,-36(s0)
            printf("Main: Second %d - ticks=%d\n", 
    8000061e:	fd043783          	ld	a5,-48(s0)
    80000622:	0007849b          	sext.w	s1,a5
                (int)current_second, (int)get_ticks());
    80000626:	00002097          	auipc	ra,0x2
    8000062a:	640080e7          	jalr	1600(ra) # 80002c66 <get_ticks>
    8000062e:	87aa                	mv	a5,a0
            printf("Main: Second %d - ticks=%d\n", 
    80000630:	2781                	sext.w	a5,a5
    80000632:	863e                	mv	a2,a5
    80000634:	85a6                	mv	a1,s1
    80000636:	00003517          	auipc	a0,0x3
    8000063a:	d4250513          	add	a0,a0,-702 # 80003378 <etext+0x378>
    8000063e:	00000097          	auipc	ra,0x0
    80000642:	3ce080e7          	jalr	974(ra) # 80000a0c <printf>
        if(current_second >= 10) {
    80000646:	fd043703          	ld	a4,-48(s0)
    8000064a:	47a5                	li	a5,9
    8000064c:	04e7e463          	bltu	a5,a4,80000694 <main+0x29e>
        for(volatile int j = 0; j < 50000000; j++);  // 增加延时
    80000650:	fc042623          	sw	zero,-52(s0)
    80000654:	a801                	j	80000664 <main+0x26e>
    80000656:	fcc42783          	lw	a5,-52(s0)
    8000065a:	2781                	sext.w	a5,a5
    8000065c:	2785                	addw	a5,a5,1
    8000065e:	2781                	sext.w	a5,a5
    80000660:	fcf42623          	sw	a5,-52(s0)
    80000664:	fcc42783          	lw	a5,-52(s0)
    80000668:	2781                	sext.w	a5,a5
    8000066a:	873e                	mv	a4,a5
    8000066c:	02faf7b7          	lui	a5,0x2faf
    80000670:	07f78793          	add	a5,a5,127 # 2faf07f <_start-0x7d050f81>
    80000674:	fee7d1e3          	bge	a5,a4,80000656 <main+0x260>
    for(int i = 0; i < 100; i++) {  // 改为1000次循环，运行更久
    80000678:	fd842783          	lw	a5,-40(s0)
    8000067c:	2785                	addw	a5,a5,1
    8000067e:	fcf42c23          	sw	a5,-40(s0)
    80000682:	fd842783          	lw	a5,-40(s0)
    80000686:	0007871b          	sext.w	a4,a5
    8000068a:	06300793          	li	a5,99
    8000068e:	f6e7d8e3          	bge	a5,a4,800005fe <main+0x208>
    80000692:	a011                	j	80000696 <main+0x2a0>
            break;
    80000694:	0001                	nop
    printf("\n=== Phase 5: Exception Handling ===\n");
    80000696:	00003517          	auipc	a0,0x3
    8000069a:	d0250513          	add	a0,a0,-766 # 80003398 <etext+0x398>
    8000069e:	00000097          	auipc	ra,0x0
    800006a2:	36e080e7          	jalr	878(ra) # 80000a0c <printf>
    test_exception_handling();
    800006a6:	00002097          	auipc	ra,0x2
    800006aa:	756080e7          	jalr	1878(ra) # 80002dfc <test_exception_handling>
    print_trap_stats();
    800006ae:	00002097          	auipc	ra,0x2
    800006b2:	2fc080e7          	jalr	764(ra) # 800029aa <print_trap_stats>
    pmm_info();
    800006b6:	00001097          	auipc	ra,0x1
    800006ba:	b3c080e7          	jalr	-1220(ra) # 800011f2 <pmm_info>
    printf("\n=== Lab 4 Complete! ===\n");
    800006be:	00003517          	auipc	a0,0x3
    800006c2:	d0250513          	add	a0,a0,-766 # 800033c0 <etext+0x3c0>
    800006c6:	00000097          	auipc	ra,0x0
    800006ca:	346080e7          	jalr	838(ra) # 80000a0c <printf>
    printf("Successfully implemented:\n");
    800006ce:	00003517          	auipc	a0,0x3
    800006d2:	d1250513          	add	a0,a0,-750 # 800033e0 <etext+0x3e0>
    800006d6:	00000097          	auipc	ra,0x0
    800006da:	336080e7          	jalr	822(ra) # 80000a0c <printf>
    printf("  - Machine mode initialization\n");
    800006de:	00003517          	auipc	a0,0x3
    800006e2:	d2250513          	add	a0,a0,-734 # 80003400 <etext+0x400>
    800006e6:	00000097          	auipc	ra,0x0
    800006ea:	326080e7          	jalr	806(ra) # 80000a0c <printf>
    printf("  - Interrupt delegation (M->S)\n");
    800006ee:	00003517          	auipc	a0,0x3
    800006f2:	d3a50513          	add	a0,a0,-710 # 80003428 <etext+0x428>
    800006f6:	00000097          	auipc	ra,0x0
    800006fa:	316080e7          	jalr	790(ra) # 80000a0c <printf>
    printf("  - Trap handling framework\n");
    800006fe:	00003517          	auipc	a0,0x3
    80000702:	d5250513          	add	a0,a0,-686 # 80003450 <etext+0x450>
    80000706:	00000097          	auipc	ra,0x0
    8000070a:	306080e7          	jalr	774(ra) # 80000a0c <printf>
    printf("  - Timer interrupts\n");
    8000070e:	00003517          	auipc	a0,0x3
    80000712:	d6250513          	add	a0,a0,-670 # 80003470 <etext+0x470>
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	2f6080e7          	jalr	758(ra) # 80000a0c <printf>
    printf("  - Context save/restore\n");
    8000071e:	00003517          	auipc	a0,0x3
    80000722:	d6a50513          	add	a0,a0,-662 # 80003488 <etext+0x488>
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	2e6080e7          	jalr	742(ra) # 80000a0c <printf>
    printf("\nSystem running with interrupts!\n");
    8000072e:	00003517          	auipc	a0,0x3
    80000732:	d7a50513          	add	a0,a0,-646 # 800034a8 <etext+0x4a8>
    80000736:	00000097          	auipc	ra,0x0
    8000073a:	2d6080e7          	jalr	726(ra) # 80000a0c <printf>
    printf("Press Ctrl+A then X to exit QEMU\n");
    8000073e:	00003517          	auipc	a0,0x3
    80000742:	d9250513          	add	a0,a0,-622 # 800034d0 <etext+0x4d0>
    80000746:	00000097          	auipc	ra,0x0
    8000074a:	2c6080e7          	jalr	710(ra) # 80000a0c <printf>
        asm volatile("wfi"); // 等待中断
    8000074e:	10500073          	wfi
    80000752:	bff5                	j	8000074e <main+0x358>

0000000080000754 <uartinit>:
/* 外部变量声明 */
extern volatile int panicking;
extern volatile int panicked;

void uartinit(void)
{
    80000754:	1141                	add	sp,sp,-16
    80000756:	e422                	sd	s0,8(sp)
    80000758:	0800                	add	s0,sp,16
  // 1. 禁用所有中断（简化设计，使用轮询模式）
  WriteReg(IER, 0x00);
    8000075a:	100007b7          	lui	a5,0x10000
    8000075e:	0785                	add	a5,a5,1 # 10000001 <_start-0x6fffffff>
    80000760:	00078023          	sb	zero,0(a5)
   // 2. 设置波特率为38400
  WriteReg(LCR, LCR_BAUD_LATCH);// 进入波特率设置模式
    80000764:	100007b7          	lui	a5,0x10000
    80000768:	078d                	add	a5,a5,3 # 10000003 <_start-0x6ffffffd>
    8000076a:	f8000713          	li	a4,-128
    8000076e:	00e78023          	sb	a4,0(a5)
  WriteReg(0, 0x03);// 低字节
    80000772:	100007b7          	lui	a5,0x10000
    80000776:	470d                	li	a4,3
    80000778:	00e78023          	sb	a4,0(a5) # 10000000 <_start-0x70000000>
  WriteReg(1, 0x00);// 高字节
    8000077c:	100007b7          	lui	a5,0x10000
    80000780:	0785                	add	a5,a5,1 # 10000001 <_start-0x6fffffff>
    80000782:	00078023          	sb	zero,0(a5)
  // 3. 配置数据格式：8位数据，无校验位
  WriteReg(LCR, LCR_EIGHT_BITS);
    80000786:	100007b7          	lui	a5,0x10000
    8000078a:	078d                	add	a5,a5,3 # 10000003 <_start-0x6ffffffd>
    8000078c:	470d                	li	a4,3
    8000078e:	00e78023          	sb	a4,0(a5)
  // 4. 启用并清空FIFO缓冲区
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000792:	100007b7          	lui	a5,0x10000
    80000796:	0789                	add	a5,a5,2 # 10000002 <_start-0x6ffffffe>
    80000798:	471d                	li	a4,7
    8000079a:	00e78023          	sb	a4,0(a5)
}
    8000079e:	0001                	nop
    800007a0:	6422                	ld	s0,8(sp)
    800007a2:	0141                	add	sp,sp,16
    800007a4:	8082                	ret

00000000800007a6 <uartputc_sync>:

/* 同步字符输出 */
void uartputc_sync(int c)
{// 1. 检查系统是否panic
    800007a6:	1101                	add	sp,sp,-32
    800007a8:	ec22                	sd	s0,24(sp)
    800007aa:	1000                	add	s0,sp,32
    800007ac:	87aa                	mv	a5,a0
    800007ae:	fef42623          	sw	a5,-20(s0)
  if(panicked){
    800007b2:	0000b797          	auipc	a5,0xb
    800007b6:	85278793          	add	a5,a5,-1966 # 8000b004 <panicked>
    800007ba:	439c                	lw	a5,0(a5)
    800007bc:	2781                	sext.w	a5,a5
    800007be:	c399                	beqz	a5,800007c4 <uartputc_sync+0x1e>
    for(;;)// 如果系统崩溃，停止输出
    800007c0:	0001                	nop
    800007c2:	bffd                	j	800007c0 <uartputc_sync+0x1a>
      ;
  }
 // 2. 等待发送寄存器空闲
 // 忙等待 - 轮询LSR寄存器的TX_IDLE位
// 这确保上一个字符发送完成后再发送新字符
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800007c4:	0001                	nop
    800007c6:	100007b7          	lui	a5,0x10000
    800007ca:	0795                	add	a5,a5,5 # 10000005 <_start-0x6ffffffb>
    800007cc:	0007c783          	lbu	a5,0(a5)
    800007d0:	0ff7f793          	zext.b	a5,a5
    800007d4:	2781                	sext.w	a5,a5
    800007d6:	0207f793          	and	a5,a5,32
    800007da:	2781                	sext.w	a5,a5
    800007dc:	d7ed                	beqz	a5,800007c6 <uartputc_sync+0x20>
    ;
  // 3. 将字符写入发送寄存器
  WriteReg(THR, c);
    800007de:	100007b7          	lui	a5,0x10000
    800007e2:	fec42703          	lw	a4,-20(s0)
    800007e6:	0ff77713          	zext.b	a4,a4
    800007ea:	00e78023          	sb	a4,0(a5) # 10000000 <_start-0x70000000>
  // 硬件会自动开始发送这个字符
}
    800007ee:	0001                	nop
    800007f0:	6462                	ld	s0,24(sp)
    800007f2:	6105                	add	sp,sp,32
    800007f4:	8082                	ret

00000000800007f6 <uartgetc>:

int uartgetc(void)
{
    800007f6:	1141                	add	sp,sp,-16
    800007f8:	e422                	sd	s0,8(sp)
    800007fa:	0800                	add	s0,sp,16
  // 第1步：检查串口是否有数据可读
  // LSR_RX_READY 位表示"接收缓冲区有数据"
  if(ReadReg(LSR) & LSR_RX_READY) {
    800007fc:	100007b7          	lui	a5,0x10000
    80000800:	0795                	add	a5,a5,5 # 10000005 <_start-0x6ffffffb>
    80000802:	0007c783          	lbu	a5,0(a5)
    80000806:	0ff7f793          	zext.b	a5,a5
    8000080a:	2781                	sext.w	a5,a5
    8000080c:	8b85                	and	a5,a5,1
    8000080e:	2781                	sext.w	a5,a5
    80000810:	cb89                	beqz	a5,80000822 <uartgetc+0x2c>
    
    // 第2步：如果有数据，从接收寄存器读取一个字符
    // RHR = Receive Holding Register (接收保持寄存器)
    return ReadReg(RHR);
    80000812:	100007b7          	lui	a5,0x10000
    80000816:	0007c783          	lbu	a5,0(a5) # 10000000 <_start-0x70000000>
    8000081a:	0ff7f793          	zext.b	a5,a5
    8000081e:	2781                	sext.w	a5,a5
    80000820:	a011                	j	80000824 <uartgetc+0x2e>
    
  } else {
    
    // 第3步：如果没有数据，返回-1表示"没有数据"
    return -1;
    80000822:	57fd                	li	a5,-1
  }
}
    80000824:	853e                	mv	a0,a5
    80000826:	6422                	ld	s0,8(sp)
    80000828:	0141                	add	sp,sp,16
    8000082a:	8082                	ret

000000008000082c <consputc>:
// consputc()是一个适配器：
// - 上层(printf)期望简单的字符输出接口
// - 下层(uart)提供硬件特定的接口
// - console层负责适配和转换
void consputc(int c)
{
    8000082c:	1101                	add	sp,sp,-32
    8000082e:	ec06                	sd	ra,24(sp)
    80000830:	e822                	sd	s0,16(sp)
    80000832:	1000                	add	s0,sp,32
    80000834:	87aa                	mv	a5,a0
    80000836:	fef42623          	sw	a5,-20(s0)
  if(c == BACKSPACE){
    8000083a:	fec42783          	lw	a5,-20(s0)
    8000083e:	0007871b          	sext.w	a4,a5
    80000842:	10000793          	li	a5,256
    80000846:	02f71363          	bne	a4,a5,8000086c <consputc+0x40>
    // 退格处理：输出 退格-空格-退格 序列
     uartputc_sync('\b');   // 光标后退一位
    8000084a:	4521                	li	a0,8
    8000084c:	00000097          	auipc	ra,0x0
    80000850:	f5a080e7          	jalr	-166(ra) # 800007a6 <uartputc_sync>
     uartputc_sync(' ');    // 用空格覆盖字符  
    80000854:	02000513          	li	a0,32
    80000858:	00000097          	auipc	ra,0x0
    8000085c:	f4e080e7          	jalr	-178(ra) # 800007a6 <uartputc_sync>
     uartputc_sync('\b');   // 光标再后退一位
    80000860:	4521                	li	a0,8
    80000862:	00000097          	auipc	ra,0x0
    80000866:	f44080e7          	jalr	-188(ra) # 800007a6 <uartputc_sync>
  } else {
    // 普通字符直接传递给硬件层
    uartputc_sync(c);
  }
}
    8000086a:	a801                	j	8000087a <consputc+0x4e>
    uartputc_sync(c);
    8000086c:	fec42783          	lw	a5,-20(s0)
    80000870:	853e                	mv	a0,a5
    80000872:	00000097          	auipc	ra,0x0
    80000876:	f34080e7          	jalr	-204(ra) # 800007a6 <uartputc_sync>
}
    8000087a:	0001                	nop
    8000087c:	60e2                	ld	ra,24(sp)
    8000087e:	6442                	ld	s0,16(sp)
    80000880:	6105                	add	sp,sp,32
    80000882:	8082                	ret

0000000080000884 <consoleinit>:
/* 初始化函数 */
void consoleinit(void)
{
    80000884:	1141                	add	sp,sp,-16
    80000886:	e406                	sd	ra,8(sp)
    80000888:	e022                	sd	s0,0(sp)
    8000088a:	0800                	add	s0,sp,16
  uartinit();// 先初始化硬件层
    8000088c:	00000097          	auipc	ra,0x0
    80000890:	ec8080e7          	jalr	-312(ra) # 80000754 <uartinit>
  printfinit();    // 再初始化printf系统， printf系统依赖硬件工作
    80000894:	00000097          	auipc	ra,0x0
    80000898:	56a080e7          	jalr	1386(ra) # 80000dfe <printfinit>
}
    8000089c:	0001                	nop
    8000089e:	60a2                	ld	ra,8(sp)
    800008a0:	6402                	ld	s0,0(sp)
    800008a2:	0141                	add	sp,sp,16
    800008a4:	8082                	ret

00000000800008a6 <printint>:
volatile int panicked = 0;// 系统是否已经panic完成，崩溃处理完成

static char digits[] = "0123456789abcdef";// 数字字符映射表

static void printint(long long xx, int base, int sign)
{
    800008a6:	715d                	add	sp,sp,-80
    800008a8:	e486                	sd	ra,72(sp)
    800008aa:	e0a2                	sd	s0,64(sp)
    800008ac:	0880                	add	s0,sp,80
    800008ae:	faa43c23          	sd	a0,-72(s0)
    800008b2:	87ae                	mv	a5,a1
    800008b4:	8732                	mv	a4,a2
    800008b6:	faf42a23          	sw	a5,-76(s0)
    800008ba:	87ba                	mv	a5,a4
    800008bc:	faf42823          	sw	a5,-80(s0)
  unsigned long long x;       // 无符号版本的数字
// 关键：x是unsigned类型！
// -(-2147483648) 在unsigned中是安全的

  // 处理负数
  if(sign && (sign = (xx < 0)))
    800008c0:	fb042783          	lw	a5,-80(s0)
    800008c4:	2781                	sext.w	a5,a5
    800008c6:	c39d                	beqz	a5,800008ec <printint+0x46>
    800008c8:	fb843783          	ld	a5,-72(s0)
    800008cc:	93fd                	srl	a5,a5,0x3f
    800008ce:	0ff7f793          	zext.b	a5,a5
    800008d2:	faf42823          	sw	a5,-80(s0)
    800008d6:	fb042783          	lw	a5,-80(s0)
    800008da:	2781                	sext.w	a5,a5
    800008dc:	cb81                	beqz	a5,800008ec <printint+0x46>
    x = -xx; // 转为正数处理
    800008de:	fb843783          	ld	a5,-72(s0)
    800008e2:	40f007b3          	neg	a5,a5
    800008e6:	fef43023          	sd	a5,-32(s0)
    800008ea:	a029                	j	800008f4 <printint+0x4e>
  else
    x = xx;
    800008ec:	fb843783          	ld	a5,-72(s0)
    800008f0:	fef43023          	sd	a5,-32(s0)

//  多位数：提取每一位数字
  i = 0;
    800008f4:	fe042623          	sw	zero,-20(s0)
  do {
    buf[i++] = digits[x % base]; // 取余数，得到最低位
    800008f8:	fb442783          	lw	a5,-76(s0)
    800008fc:	fe043703          	ld	a4,-32(s0)
    80000900:	02f77733          	remu	a4,a4,a5
    80000904:	fec42783          	lw	a5,-20(s0)
    80000908:	0017869b          	addw	a3,a5,1
    8000090c:	fed42623          	sw	a3,-20(s0)
    80000910:	00004697          	auipc	a3,0x4
    80000914:	6f068693          	add	a3,a3,1776 # 80005000 <digits>
    80000918:	9736                	add	a4,a4,a3
    8000091a:	00074703          	lbu	a4,0(a4)
    8000091e:	17c1                	add	a5,a5,-16
    80000920:	97a2                	add	a5,a5,s0
    80000922:	fce78c23          	sb	a4,-40(a5)
        // 关键：使用digits数组将数字映射为字符
        // 例如：x=42, base=10
        // 第一次：42 % 10 = 2 → buf[0] = '2'
        // 第二次：4 % 10 = 4 → buf[1] = '4' 
  } while((x /= base) != 0);// 整除，处理下一位
    80000926:	fb442783          	lw	a5,-76(s0)
    8000092a:	fe043703          	ld	a4,-32(s0)
    8000092e:	02f757b3          	divu	a5,a4,a5
    80000932:	fef43023          	sd	a5,-32(s0)
    80000936:	fe043783          	ld	a5,-32(s0)
    8000093a:	ffdd                	bnez	a5,800008f8 <printint+0x52>
// 用do while而不是while,确保x=0时也能输出'0'
// 添加负号

  if(sign)
    8000093c:	fb042783          	lw	a5,-80(s0)
    80000940:	2781                	sext.w	a5,a5
    80000942:	cb95                	beqz	a5,80000976 <printint+0xd0>
    buf[i++] = '-';
    80000944:	fec42783          	lw	a5,-20(s0)
    80000948:	0017871b          	addw	a4,a5,1
    8000094c:	fee42623          	sw	a4,-20(s0)
    80000950:	17c1                	add	a5,a5,-16
    80000952:	97a2                	add	a5,a5,s0
    80000954:	02d00713          	li	a4,45
    80000958:	fce78c23          	sb	a4,-40(a5)
// 逆序输出（因为是从低位到高位提取的）
  while(--i >= 0)
    8000095c:	a829                	j	80000976 <printint+0xd0>
    consputc(buf[i]);
    8000095e:	fec42783          	lw	a5,-20(s0)
    80000962:	17c1                	add	a5,a5,-16
    80000964:	97a2                	add	a5,a5,s0
    80000966:	fd87c783          	lbu	a5,-40(a5)
    8000096a:	2781                	sext.w	a5,a5
    8000096c:	853e                	mv	a0,a5
    8000096e:	00000097          	auipc	ra,0x0
    80000972:	ebe080e7          	jalr	-322(ra) # 8000082c <consputc>
  while(--i >= 0)
    80000976:	fec42783          	lw	a5,-20(s0)
    8000097a:	37fd                	addw	a5,a5,-1
    8000097c:	fef42623          	sw	a5,-20(s0)
    80000980:	fec42783          	lw	a5,-20(s0)
    80000984:	2781                	sext.w	a5,a5
    80000986:	fc07dce3          	bgez	a5,8000095e <printint+0xb8>
}
    8000098a:	0001                	nop
    8000098c:	0001                	nop
    8000098e:	60a6                	ld	ra,72(sp)
    80000990:	6406                	ld	s0,64(sp)
    80000992:	6161                	add	sp,sp,80
    80000994:	8082                	ret

0000000080000996 <printptr>:




static void printptr(uint64 x)
{
    80000996:	7179                	add	sp,sp,-48
    80000998:	f406                	sd	ra,40(sp)
    8000099a:	f022                	sd	s0,32(sp)
    8000099c:	1800                	add	s0,sp,48
    8000099e:	fca43c23          	sd	a0,-40(s0)
  int i;
  
  // 第1步：先输出"0x"前缀，表示这是十六进制地址
  consputc('0');
    800009a2:	03000513          	li	a0,48
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	e86080e7          	jalr	-378(ra) # 8000082c <consputc>
  consputc('x');
    800009ae:	07800513          	li	a0,120
    800009b2:	00000097          	auipc	ra,0x0
    800009b6:	e7a080e7          	jalr	-390(ra) # 8000082c <consputc>
  
  // 第2步：循环输出地址的每一位十六进制数字
  // sizeof(uint64) * 2 = 8 * 2 = 16位十六进制数字
  // 64位地址需要16个十六进制字符来表示
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4) {
    800009ba:	fe042623          	sw	zero,-20(s0)
    800009be:	a81d                	j	800009f4 <printptr+0x5e>
    // 每次取出最高4位来输出
    // x >> (sizeof(uint64) * 8 - 4) 就是 x >> 60
    // 这样每次都取最高的4位（一个十六进制数字）
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800009c0:	fd843783          	ld	a5,-40(s0)
    800009c4:	93f1                	srl	a5,a5,0x3c
    800009c6:	00004717          	auipc	a4,0x4
    800009ca:	63a70713          	add	a4,a4,1594 # 80005000 <digits>
    800009ce:	97ba                	add	a5,a5,a4
    800009d0:	0007c783          	lbu	a5,0(a5)
    800009d4:	2781                	sext.w	a5,a5
    800009d6:	853e                	mv	a0,a5
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	e54080e7          	jalr	-428(ra) # 8000082c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4) {
    800009e0:	fec42783          	lw	a5,-20(s0)
    800009e4:	2785                	addw	a5,a5,1
    800009e6:	fef42623          	sw	a5,-20(s0)
    800009ea:	fd843783          	ld	a5,-40(s0)
    800009ee:	0792                	sll	a5,a5,0x4
    800009f0:	fcf43c23          	sd	a5,-40(s0)
    800009f4:	fec42783          	lw	a5,-20(s0)
    800009f8:	873e                	mv	a4,a5
    800009fa:	47bd                	li	a5,15
    800009fc:	fce7f2e3          	bgeu	a5,a4,800009c0 <printptr+0x2a>
    // 然后 x <<= 4，把下一组4位移到最高位
  }
}
    80000a00:	0001                	nop
    80000a02:	0001                	nop
    80000a04:	70a2                	ld	ra,40(sp)
    80000a06:	7402                	ld	s0,32(sp)
    80000a08:	6145                	add	sp,sp,48
    80000a0a:	8082                	ret

0000000080000a0c <printf>:

/* printf() - 格式字符串解析 */
int printf(char *fmt, ...)
{
    80000a0c:	7175                	add	sp,sp,-144
    80000a0e:	e486                	sd	ra,72(sp)
    80000a10:	e0a2                	sd	s0,64(sp)
    80000a12:	0880                	add	s0,sp,80
    80000a14:	faa43c23          	sd	a0,-72(s0)
    80000a18:	e40c                	sd	a1,8(s0)
    80000a1a:	e810                	sd	a2,16(s0)
    80000a1c:	ec14                	sd	a3,24(s0)
    80000a1e:	f018                	sd	a4,32(s0)
    80000a20:	f41c                	sd	a5,40(s0)
    80000a22:	03043823          	sd	a6,48(s0)
    80000a26:	03143c23          	sd	a7,56(s0)
  va_list ap;                 // 可变参数列表
  int i, cx, c0, c1, c2;      // 字符和索引变量
  char *s;                    // 字符串指针

  va_start(ap, fmt);          // 初始化参数列表
    80000a2a:	04040793          	add	a5,s0,64
    80000a2e:	faf43823          	sd	a5,-80(s0)
    80000a32:	fb043783          	ld	a5,-80(s0)
    80000a36:	fc878793          	add	a5,a5,-56
    80000a3a:	fcf43423          	sd	a5,-56(s0)
// 主循环：逐字符解析格式字符串
  for(i = 0; (cx = fmt[i] & 0xff) != 0; i++){
    80000a3e:	fe042623          	sw	zero,-20(s0)
    80000a42:	a691                	j	80000d86 <printf+0x37a>
    if(cx != '%'){
    80000a44:	fd442783          	lw	a5,-44(s0)
    80000a48:	0007871b          	sext.w	a4,a5
    80000a4c:	02500793          	li	a5,37
    80000a50:	00f70a63          	beq	a4,a5,80000a64 <printf+0x58>
      // 普通字符直接输出
      consputc(cx);
    80000a54:	fd442783          	lw	a5,-44(s0)
    80000a58:	853e                	mv	a0,a5
    80000a5a:	00000097          	auipc	ra,0x0
    80000a5e:	dd2080e7          	jalr	-558(ra) # 8000082c <consputc>
      continue;
    80000a62:	ae29                	j	80000d7c <printf+0x370>
    }
    // 遇到%，开始解析格式符
    i++;
    80000a64:	fec42783          	lw	a5,-20(s0)
    80000a68:	2785                	addw	a5,a5,1
    80000a6a:	fef42623          	sw	a5,-20(s0)
    c0 = fmt[i+0] & 0xff;   // 格式符的第一个字符
    80000a6e:	fec42783          	lw	a5,-20(s0)
    80000a72:	fb843703          	ld	a4,-72(s0)
    80000a76:	97ba                	add	a5,a5,a4
    80000a78:	0007c783          	lbu	a5,0(a5)
    80000a7c:	fcf42823          	sw	a5,-48(s0)
    c1 = c2 = 0;
    80000a80:	fe042223          	sw	zero,-28(s0)
    80000a84:	fe442783          	lw	a5,-28(s0)
    80000a88:	fef42423          	sw	a5,-24(s0)
    if(c0) c1 = fmt[i+1] & 0xff;  // 可能的第二个字符（如%ld中的d）
    80000a8c:	fd042783          	lw	a5,-48(s0)
    80000a90:	2781                	sext.w	a5,a5
    80000a92:	cb99                	beqz	a5,80000aa8 <printf+0x9c>
    80000a94:	fec42783          	lw	a5,-20(s0)
    80000a98:	0785                	add	a5,a5,1
    80000a9a:	fb843703          	ld	a4,-72(s0)
    80000a9e:	97ba                	add	a5,a5,a4
    80000aa0:	0007c783          	lbu	a5,0(a5)
    80000aa4:	fef42423          	sw	a5,-24(s0)
    if(c1) c2 = fmt[i+2] & 0xff;  // 可能的第三个字符（如%lld中的第二个d）
    80000aa8:	fe842783          	lw	a5,-24(s0)
    80000aac:	2781                	sext.w	a5,a5
    80000aae:	cb99                	beqz	a5,80000ac4 <printf+0xb8>
    80000ab0:	fec42783          	lw	a5,-20(s0)
    80000ab4:	0789                	add	a5,a5,2
    80000ab6:	fb843703          	ld	a4,-72(s0)
    80000aba:	97ba                	add	a5,a5,a4
    80000abc:	0007c783          	lbu	a5,0(a5)
    80000ac0:	fef42223          	sw	a5,-28(s0)

    // 格式符处理 - 支持xv6的所有主要格式。普通字符直接输出，遇到%进入格式处理状态
    if(c0 == 'd') { 
    80000ac4:	fd042783          	lw	a5,-48(s0)
    80000ac8:	0007871b          	sext.w	a4,a5
    80000acc:	06400793          	li	a5,100
    80000ad0:	02f71163          	bne	a4,a5,80000af2 <printf+0xe6>
       // %d - 32位有符号整数   
      printint(va_arg(ap, int), 10, 1);
    80000ad4:	fc843783          	ld	a5,-56(s0)
    80000ad8:	00878713          	add	a4,a5,8
    80000adc:	fce43423          	sd	a4,-56(s0)
    80000ae0:	439c                	lw	a5,0(a5)
    80000ae2:	4605                	li	a2,1
    80000ae4:	45a9                	li	a1,10
    80000ae6:	853e                	mv	a0,a5
    80000ae8:	00000097          	auipc	ra,0x0
    80000aec:	dbe080e7          	jalr	-578(ra) # 800008a6 <printint>
    80000af0:	a471                	j	80000d7c <printf+0x370>
    } else if(c0 == 'l' && c1 == 'd'){
    80000af2:	fd042783          	lw	a5,-48(s0)
    80000af6:	0007871b          	sext.w	a4,a5
    80000afa:	06c00793          	li	a5,108
    80000afe:	02f71e63          	bne	a4,a5,80000b3a <printf+0x12e>
    80000b02:	fe842783          	lw	a5,-24(s0)
    80000b06:	0007871b          	sext.w	a4,a5
    80000b0a:	06400793          	li	a5,100
    80000b0e:	02f71663          	bne	a4,a5,80000b3a <printf+0x12e>
      // %ld - 64位有符号整数
      printint(va_arg(ap, uint64), 10, 1);
    80000b12:	fc843783          	ld	a5,-56(s0)
    80000b16:	00878713          	add	a4,a5,8
    80000b1a:	fce43423          	sd	a4,-56(s0)
    80000b1e:	639c                	ld	a5,0(a5)
    80000b20:	4605                	li	a2,1
    80000b22:	45a9                	li	a1,10
    80000b24:	853e                	mv	a0,a5
    80000b26:	00000097          	auipc	ra,0x0
    80000b2a:	d80080e7          	jalr	-640(ra) # 800008a6 <printint>
      i += 1;// 跳过额外的字符
    80000b2e:	fec42783          	lw	a5,-20(s0)
    80000b32:	2785                	addw	a5,a5,1
    80000b34:	fef42623          	sw	a5,-20(s0)
    80000b38:	a491                	j	80000d7c <printf+0x370>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
    80000b3a:	fd042783          	lw	a5,-48(s0)
    80000b3e:	0007871b          	sext.w	a4,a5
    80000b42:	06c00793          	li	a5,108
    80000b46:	04f71663          	bne	a4,a5,80000b92 <printf+0x186>
    80000b4a:	fe842783          	lw	a5,-24(s0)
    80000b4e:	0007871b          	sext.w	a4,a5
    80000b52:	06c00793          	li	a5,108
    80000b56:	02f71e63          	bne	a4,a5,80000b92 <printf+0x186>
    80000b5a:	fe442783          	lw	a5,-28(s0)
    80000b5e:	0007871b          	sext.w	a4,a5
    80000b62:	06400793          	li	a5,100
    80000b66:	02f71663          	bne	a4,a5,80000b92 <printf+0x186>
      // %lld - 64位有符号整数（与%ld相同，但为兼容性）
      printint(va_arg(ap, uint64), 10, 1);
    80000b6a:	fc843783          	ld	a5,-56(s0)
    80000b6e:	00878713          	add	a4,a5,8
    80000b72:	fce43423          	sd	a4,-56(s0)
    80000b76:	639c                	ld	a5,0(a5)
    80000b78:	4605                	li	a2,1
    80000b7a:	45a9                	li	a1,10
    80000b7c:	853e                	mv	a0,a5
    80000b7e:	00000097          	auipc	ra,0x0
    80000b82:	d28080e7          	jalr	-728(ra) # 800008a6 <printint>
      i += 2;// 跳过额外的字符
    80000b86:	fec42783          	lw	a5,-20(s0)
    80000b8a:	2789                	addw	a5,a5,2
    80000b8c:	fef42623          	sw	a5,-20(s0)
    80000b90:	a2f5                	j	80000d7c <printf+0x370>
    } else if(c0 == 'u'){
    80000b92:	fd042783          	lw	a5,-48(s0)
    80000b96:	0007871b          	sext.w	a4,a5
    80000b9a:	07500793          	li	a5,117
    80000b9e:	02f71363          	bne	a4,a5,80000bc4 <printf+0x1b8>
      // %u - 32位无符号整数
      printint(va_arg(ap, uint32), 10, 0);
    80000ba2:	fc843783          	ld	a5,-56(s0)
    80000ba6:	00878713          	add	a4,a5,8
    80000baa:	fce43423          	sd	a4,-56(s0)
    80000bae:	439c                	lw	a5,0(a5)
    80000bb0:	1782                	sll	a5,a5,0x20
    80000bb2:	9381                	srl	a5,a5,0x20
    80000bb4:	4601                	li	a2,0
    80000bb6:	45a9                	li	a1,10
    80000bb8:	853e                	mv	a0,a5
    80000bba:	00000097          	auipc	ra,0x0
    80000bbe:	cec080e7          	jalr	-788(ra) # 800008a6 <printint>
    80000bc2:	aa6d                	j	80000d7c <printf+0x370>
    } else if(c0 == 'l' && c1 == 'u'){
    80000bc4:	fd042783          	lw	a5,-48(s0)
    80000bc8:	0007871b          	sext.w	a4,a5
    80000bcc:	06c00793          	li	a5,108
    80000bd0:	02f71e63          	bne	a4,a5,80000c0c <printf+0x200>
    80000bd4:	fe842783          	lw	a5,-24(s0)
    80000bd8:	0007871b          	sext.w	a4,a5
    80000bdc:	07500793          	li	a5,117
    80000be0:	02f71663          	bne	a4,a5,80000c0c <printf+0x200>
      printint(va_arg(ap, uint64), 10, 0);
    80000be4:	fc843783          	ld	a5,-56(s0)
    80000be8:	00878713          	add	a4,a5,8
    80000bec:	fce43423          	sd	a4,-56(s0)
    80000bf0:	639c                	ld	a5,0(a5)
    80000bf2:	4601                	li	a2,0
    80000bf4:	45a9                	li	a1,10
    80000bf6:	853e                	mv	a0,a5
    80000bf8:	00000097          	auipc	ra,0x0
    80000bfc:	cae080e7          	jalr	-850(ra) # 800008a6 <printint>
      i += 1;
    80000c00:	fec42783          	lw	a5,-20(s0)
    80000c04:	2785                	addw	a5,a5,1
    80000c06:	fef42623          	sw	a5,-20(s0)
    80000c0a:	aa8d                	j	80000d7c <printf+0x370>
    } else if(c0 == 'x'){// %x - 32位十六进制
    80000c0c:	fd042783          	lw	a5,-48(s0)
    80000c10:	0007871b          	sext.w	a4,a5
    80000c14:	07800793          	li	a5,120
    80000c18:	02f71363          	bne	a4,a5,80000c3e <printf+0x232>
      printint(va_arg(ap, uint32), 16, 0);
    80000c1c:	fc843783          	ld	a5,-56(s0)
    80000c20:	00878713          	add	a4,a5,8
    80000c24:	fce43423          	sd	a4,-56(s0)
    80000c28:	439c                	lw	a5,0(a5)
    80000c2a:	1782                	sll	a5,a5,0x20
    80000c2c:	9381                	srl	a5,a5,0x20
    80000c2e:	4601                	li	a2,0
    80000c30:	45c1                	li	a1,16
    80000c32:	853e                	mv	a0,a5
    80000c34:	00000097          	auipc	ra,0x0
    80000c38:	c72080e7          	jalr	-910(ra) # 800008a6 <printint>
    80000c3c:	a281                	j	80000d7c <printf+0x370>
    } else if(c0 == 'l' && c1 == 'x'){
    80000c3e:	fd042783          	lw	a5,-48(s0)
    80000c42:	0007871b          	sext.w	a4,a5
    80000c46:	06c00793          	li	a5,108
    80000c4a:	02f71e63          	bne	a4,a5,80000c86 <printf+0x27a>
    80000c4e:	fe842783          	lw	a5,-24(s0)
    80000c52:	0007871b          	sext.w	a4,a5
    80000c56:	07800793          	li	a5,120
    80000c5a:	02f71663          	bne	a4,a5,80000c86 <printf+0x27a>
      printint(va_arg(ap, uint64), 16, 0);
    80000c5e:	fc843783          	ld	a5,-56(s0)
    80000c62:	00878713          	add	a4,a5,8
    80000c66:	fce43423          	sd	a4,-56(s0)
    80000c6a:	639c                	ld	a5,0(a5)
    80000c6c:	4601                	li	a2,0
    80000c6e:	45c1                	li	a1,16
    80000c70:	853e                	mv	a0,a5
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	c34080e7          	jalr	-972(ra) # 800008a6 <printint>
      i += 1;
    80000c7a:	fec42783          	lw	a5,-20(s0)
    80000c7e:	2785                	addw	a5,a5,1
    80000c80:	fef42623          	sw	a5,-20(s0)
    80000c84:	a8e5                	j	80000d7c <printf+0x370>
    } else if(c0 == 'p'){// %p - 指针地址
    80000c86:	fd042783          	lw	a5,-48(s0)
    80000c8a:	0007871b          	sext.w	a4,a5
    80000c8e:	07000793          	li	a5,112
    80000c92:	00f71f63          	bne	a4,a5,80000cb0 <printf+0x2a4>
      printptr(va_arg(ap, uint64));
    80000c96:	fc843783          	ld	a5,-56(s0)
    80000c9a:	00878713          	add	a4,a5,8
    80000c9e:	fce43423          	sd	a4,-56(s0)
    80000ca2:	639c                	ld	a5,0(a5)
    80000ca4:	853e                	mv	a0,a5
    80000ca6:	00000097          	auipc	ra,0x0
    80000caa:	cf0080e7          	jalr	-784(ra) # 80000996 <printptr>
    80000cae:	a0f9                	j	80000d7c <printf+0x370>
    } else if(c0 == 'c'){// %c - 单个字符
    80000cb0:	fd042783          	lw	a5,-48(s0)
    80000cb4:	0007871b          	sext.w	a4,a5
    80000cb8:	06300793          	li	a5,99
    80000cbc:	02f71063          	bne	a4,a5,80000cdc <printf+0x2d0>
      consputc(va_arg(ap, uint));
    80000cc0:	fc843783          	ld	a5,-56(s0)
    80000cc4:	00878713          	add	a4,a5,8
    80000cc8:	fce43423          	sd	a4,-56(s0)
    80000ccc:	439c                	lw	a5,0(a5)
    80000cce:	2781                	sext.w	a5,a5
    80000cd0:	853e                	mv	a0,a5
    80000cd2:	00000097          	auipc	ra,0x0
    80000cd6:	b5a080e7          	jalr	-1190(ra) # 8000082c <consputc>
    80000cda:	a04d                	j	80000d7c <printf+0x370>
    } else if(c0 == 's'){// %s - 字符串
    80000cdc:	fd042783          	lw	a5,-48(s0)
    80000ce0:	0007871b          	sext.w	a4,a5
    80000ce4:	07300793          	li	a5,115
    80000ce8:	04f71a63          	bne	a4,a5,80000d3c <printf+0x330>
      // 第1步：从参数列表中取出字符串指针
      if((s = va_arg(ap, char*)) == 0)// 检查是否为NULL
    80000cec:	fc843783          	ld	a5,-56(s0)
    80000cf0:	00878713          	add	a4,a5,8
    80000cf4:	fce43423          	sd	a4,-56(s0)
    80000cf8:	639c                	ld	a5,0(a5)
    80000cfa:	fcf43c23          	sd	a5,-40(s0)
    80000cfe:	fd843783          	ld	a5,-40(s0)
    80000d02:	e79d                	bnez	a5,80000d30 <printf+0x324>
        s = "(null)";// 如果是NULL，替换成安全的字符串
    80000d04:	00002797          	auipc	a5,0x2
    80000d08:	7f478793          	add	a5,a5,2036 # 800034f8 <etext+0x4f8>
    80000d0c:	fcf43c23          	sd	a5,-40(s0)
      // 第2步：逐字符输出
      for(; *s; s++)
    80000d10:	a005                	j	80000d30 <printf+0x324>
        consputc(*s);
    80000d12:	fd843783          	ld	a5,-40(s0)
    80000d16:	0007c783          	lbu	a5,0(a5)
    80000d1a:	2781                	sext.w	a5,a5
    80000d1c:	853e                	mv	a0,a5
    80000d1e:	00000097          	auipc	ra,0x0
    80000d22:	b0e080e7          	jalr	-1266(ra) # 8000082c <consputc>
      for(; *s; s++)
    80000d26:	fd843783          	ld	a5,-40(s0)
    80000d2a:	0785                	add	a5,a5,1
    80000d2c:	fcf43c23          	sd	a5,-40(s0)
    80000d30:	fd843783          	ld	a5,-40(s0)
    80000d34:	0007c783          	lbu	a5,0(a5)
    80000d38:	ffe9                	bnez	a5,80000d12 <printf+0x306>
    80000d3a:	a089                	j	80000d7c <printf+0x370>
    } else if(c0 == '%'){// %% - 输出字面的%
    80000d3c:	fd042783          	lw	a5,-48(s0)
    80000d40:	0007871b          	sext.w	a4,a5
    80000d44:	02500793          	li	a5,37
    80000d48:	00f71963          	bne	a4,a5,80000d5a <printf+0x34e>
      consputc('%');
    80000d4c:	02500513          	li	a0,37
    80000d50:	00000097          	auipc	ra,0x0
    80000d54:	adc080e7          	jalr	-1316(ra) # 8000082c <consputc>
    80000d58:	a015                	j	80000d7c <printf+0x370>
    } else if(c0 == 0){
    80000d5a:	fd042783          	lw	a5,-48(s0)
    80000d5e:	2781                	sext.w	a5,a5
    80000d60:	c3b1                	beqz	a5,80000da4 <printf+0x398>
      break;
    } else {// 未知格式符 - 原样输出便于调试
      consputc('%');
    80000d62:	02500513          	li	a0,37
    80000d66:	00000097          	auipc	ra,0x0
    80000d6a:	ac6080e7          	jalr	-1338(ra) # 8000082c <consputc>
      consputc(c0);
    80000d6e:	fd042783          	lw	a5,-48(s0)
    80000d72:	853e                	mv	a0,a5
    80000d74:	00000097          	auipc	ra,0x0
    80000d78:	ab8080e7          	jalr	-1352(ra) # 8000082c <consputc>
  for(i = 0; (cx = fmt[i] & 0xff) != 0; i++){
    80000d7c:	fec42783          	lw	a5,-20(s0)
    80000d80:	2785                	addw	a5,a5,1
    80000d82:	fef42623          	sw	a5,-20(s0)
    80000d86:	fec42783          	lw	a5,-20(s0)
    80000d8a:	fb843703          	ld	a4,-72(s0)
    80000d8e:	97ba                	add	a5,a5,a4
    80000d90:	0007c783          	lbu	a5,0(a5)
    80000d94:	fcf42a23          	sw	a5,-44(s0)
    80000d98:	fd442783          	lw	a5,-44(s0)
    80000d9c:	2781                	sext.w	a5,a5
    80000d9e:	ca0793e3          	bnez	a5,80000a44 <printf+0x38>
    80000da2:	a011                	j	80000da6 <printf+0x39a>
      break;
    80000da4:	0001                	nop
    }
  }
  va_end(ap);// 清理参数列表

  return 0;
    80000da6:	4781                	li	a5,0
}
    80000da8:	853e                	mv	a0,a5
    80000daa:	60a6                	ld	ra,72(sp)
    80000dac:	6406                	ld	s0,64(sp)
    80000dae:	6149                	add	sp,sp,144
    80000db0:	8082                	ret

0000000080000db2 <panic>:

void panic(char *s)
{
    80000db2:	1101                	add	sp,sp,-32
    80000db4:	ec06                	sd	ra,24(sp)
    80000db6:	e822                	sd	s0,16(sp)
    80000db8:	1000                	add	s0,sp,32
    80000dba:	fea43423          	sd	a0,-24(s0)
  // 第1步：设置全局标志，告诉其他部分"系统要崩溃了"
  panicking = 1;
    80000dbe:	0000a797          	auipc	a5,0xa
    80000dc2:	24278793          	add	a5,a5,578 # 8000b000 <panicking>
    80000dc6:	4705                	li	a4,1
    80000dc8:	c398                	sw	a4,0(a5)
  
  // 第2步：输出崩溃信息，让程序员知道出了什么问题
  printf("panic: ");        // 固定前缀，表示这是系统崩溃
    80000dca:	00002517          	auipc	a0,0x2
    80000dce:	73650513          	add	a0,a0,1846 # 80003500 <etext+0x500>
    80000dd2:	00000097          	auipc	ra,0x0
    80000dd6:	c3a080e7          	jalr	-966(ra) # 80000a0c <printf>
  printf("%s\n", s);        // 输出具体的错误信息
    80000dda:	fe843583          	ld	a1,-24(s0)
    80000dde:	00002517          	auipc	a0,0x2
    80000de2:	72a50513          	add	a0,a0,1834 # 80003508 <etext+0x508>
    80000de6:	00000097          	auipc	ra,0x0
    80000dea:	c26080e7          	jalr	-986(ra) # 80000a0c <printf>
  
  // 第3步：标记崩溃处理完成
  // 这时其他部分看到这个标志就知道不要再输出了
  panicked = 1;
    80000dee:	0000a797          	auipc	a5,0xa
    80000df2:	21678793          	add	a5,a5,534 # 8000b004 <panicked>
    80000df6:	4705                	li	a4,1
    80000df8:	c398                	sw	a4,0(a5)
  
  // 第4步：进入无限循环，让系统停止运行
  for(;;)
    80000dfa:	0001                	nop
    80000dfc:	bffd                	j	80000dfa <panic+0x48>

0000000080000dfe <printfinit>:
    ;  // 空循环，CPU在这里永远转圈
}

void printfinit(void)
{
    80000dfe:	1141                	add	sp,sp,-16
    80000e00:	e422                	sd	s0,8(sp)
    80000e02:	0800                	add	s0,sp,16
  /* 简化版本，不需要锁初始化 */
}
    80000e04:	0001                	nop
    80000e06:	6422                	ld	s0,8(sp)
    80000e08:	0141                	add	sp,sp,16
    80000e0a:	8082                	ret

0000000080000e0c <clear_screen>:
#include "types.h"
#include "defs.h"

/* 清屏函数 */
void clear_screen(void)
{
    80000e0c:	1141                	add	sp,sp,-16
    80000e0e:	e406                	sd	ra,8(sp)
    80000e10:	e022                	sd	s0,0(sp)
    80000e12:	0800                	add	s0,sp,16
  /* 直接输出ANSI转义序列，避免复杂的printf格式化 */
   // 发送ANSI转义序列：ESC[2J ESC[H
  consputc('\033');  /* ESC */
    80000e14:	456d                	li	a0,27
    80000e16:	00000097          	auipc	ra,0x0
    80000e1a:	a16080e7          	jalr	-1514(ra) # 8000082c <consputc>
  consputc('[');// 开始ANSI序列
    80000e1e:	05b00513          	li	a0,91
    80000e22:	00000097          	auipc	ra,0x0
    80000e26:	a0a080e7          	jalr	-1526(ra) # 8000082c <consputc>
  consputc('2');     // 清屏命令参数
    80000e2a:	03200513          	li	a0,50
    80000e2e:	00000097          	auipc	ra,0x0
    80000e32:	9fe080e7          	jalr	-1538(ra) # 8000082c <consputc>
  consputc('J');     /* 清除整个屏幕 */
    80000e36:	04a00513          	li	a0,74
    80000e3a:	00000097          	auipc	ra,0x0
    80000e3e:	9f2080e7          	jalr	-1550(ra) # 8000082c <consputc>
  consputc('\033');  /* ESC */
    80000e42:	456d                	li	a0,27
    80000e44:	00000097          	auipc	ra,0x0
    80000e48:	9e8080e7          	jalr	-1560(ra) # 8000082c <consputc>
  consputc('[');
    80000e4c:	05b00513          	li	a0,91
    80000e50:	00000097          	auipc	ra,0x0
    80000e54:	9dc080e7          	jalr	-1572(ra) # 8000082c <consputc>
  consputc('H');     /* 光标回到左上角 */
    80000e58:	04800513          	li	a0,72
    80000e5c:	00000097          	auipc	ra,0x0
    80000e60:	9d0080e7          	jalr	-1584(ra) # 8000082c <consputc>
}
    80000e64:	0001                	nop
    80000e66:	60a2                	ld	ra,8(sp)
    80000e68:	6402                	ld	s0,0(sp)
    80000e6a:	0141                	add	sp,sp,16
    80000e6c:	8082                	ret

0000000080000e6e <print_number>:

/* 数字输出辅助函数 */
static void print_number(int num)
{
    80000e6e:	1101                	add	sp,sp,-32
    80000e70:	ec06                	sd	ra,24(sp)
    80000e72:	e822                	sd	s0,16(sp)
    80000e74:	1000                	add	s0,sp,32
    80000e76:	87aa                	mv	a5,a0
    80000e78:	fef42623          	sw	a5,-20(s0)
  if(num >= 10) {
    80000e7c:	fec42783          	lw	a5,-20(s0)
    80000e80:	0007871b          	sext.w	a4,a5
    80000e84:	47a5                	li	a5,9
    80000e86:	00e7de63          	bge	a5,a4,80000ea2 <print_number+0x34>
    print_number(num / 10);// 递归处理高位
    80000e8a:	fec42783          	lw	a5,-20(s0)
    80000e8e:	873e                	mv	a4,a5
    80000e90:	47a9                	li	a5,10
    80000e92:	02f747bb          	divw	a5,a4,a5
    80000e96:	2781                	sext.w	a5,a5
    80000e98:	853e                	mv	a0,a5
    80000e9a:	00000097          	auipc	ra,0x0
    80000e9e:	fd4080e7          	jalr	-44(ra) # 80000e6e <print_number>
  }
  consputc('0' + (num % 10));// 输出当前位
    80000ea2:	fec42783          	lw	a5,-20(s0)
    80000ea6:	873e                	mv	a4,a5
    80000ea8:	47a9                	li	a5,10
    80000eaa:	02f767bb          	remw	a5,a4,a5
    80000eae:	2781                	sext.w	a5,a5
    80000eb0:	0307879b          	addw	a5,a5,48
    80000eb4:	2781                	sext.w	a5,a5
    80000eb6:	853e                	mv	a0,a5
    80000eb8:	00000097          	auipc	ra,0x0
    80000ebc:	974080e7          	jalr	-1676(ra) # 8000082c <consputc>
}
    80000ec0:	0001                	nop
    80000ec2:	60e2                	ld	ra,24(sp)
    80000ec4:	6442                	ld	s0,16(sp)
    80000ec6:	6105                	add	sp,sp,32
    80000ec8:	8082                	ret

0000000080000eca <set_cursor>:
// 5. 返回步骤1，输出 '3'
// 结果：输出 "123"

/* 光标定位函数 */
void set_cursor(int x, int y)
{
    80000eca:	1101                	add	sp,sp,-32
    80000ecc:	ec06                	sd	ra,24(sp)
    80000ece:	e822                	sd	s0,16(sp)
    80000ed0:	1000                	add	s0,sp,32
    80000ed2:	87aa                	mv	a5,a0
    80000ed4:	872e                	mv	a4,a1
    80000ed6:	fef42623          	sw	a5,-20(s0)
    80000eda:	87ba                	mv	a5,a4
    80000edc:	fef42423          	sw	a5,-24(s0)
  // 发送ANSI序列：ESC[y;xH
  consputc('\033');  /* ESC */
    80000ee0:	456d                	li	a0,27
    80000ee2:	00000097          	auipc	ra,0x0
    80000ee6:	94a080e7          	jalr	-1718(ra) # 8000082c <consputc>
  consputc('[');
    80000eea:	05b00513          	li	a0,91
    80000eee:	00000097          	auipc	ra,0x0
    80000ef2:	93e080e7          	jalr	-1730(ra) # 8000082c <consputc>
  print_number(y);// 行号
    80000ef6:	fe842783          	lw	a5,-24(s0)
    80000efa:	853e                	mv	a0,a5
    80000efc:	00000097          	auipc	ra,0x0
    80000f00:	f72080e7          	jalr	-142(ra) # 80000e6e <print_number>
  consputc(';');     // 分隔符
    80000f04:	03b00513          	li	a0,59
    80000f08:	00000097          	auipc	ra,0x0
    80000f0c:	924080e7          	jalr	-1756(ra) # 8000082c <consputc>
  print_number(x);   // 列号  
    80000f10:	fec42783          	lw	a5,-20(s0)
    80000f14:	853e                	mv	a0,a5
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	f58080e7          	jalr	-168(ra) # 80000e6e <print_number>
  consputc('H');     // 定位命令，移动光标
    80000f1e:	04800513          	li	a0,72
    80000f22:	00000097          	auipc	ra,0x0
    80000f26:	90a080e7          	jalr	-1782(ra) # 8000082c <consputc>
}
    80000f2a:	0001                	nop
    80000f2c:	60e2                	ld	ra,24(sp)
    80000f2e:	6442                	ld	s0,16(sp)
    80000f30:	6105                	add	sp,sp,32
    80000f32:	8082                	ret

0000000080000f34 <memset>:
// 简单的memset实现 
// 用途：页面清零、安全擦除等
/*如果程序错误地访问已释放的页面，会读到全是1的数据
这种异常的数据模式很容易被发现，有助于调试
如果不填充，程序可能读到看似正常的旧数据，bug很难发现*/
void* memset(void *dst, int c, uint n) {
    80000f34:	7179                	add	sp,sp,-48
    80000f36:	f422                	sd	s0,40(sp)
    80000f38:	1800                	add	s0,sp,48
    80000f3a:	fca43c23          	sd	a0,-40(s0)
    80000f3e:	87ae                	mv	a5,a1
    80000f40:	8732                	mv	a4,a2
    80000f42:	fcf42a23          	sw	a5,-44(s0)
    80000f46:	87ba                	mv	a5,a4
    80000f48:	fcf42823          	sw	a5,-48(s0)
    char *cdst = (char*)dst;
    80000f4c:	fd843783          	ld	a5,-40(s0)
    80000f50:	fef43023          	sd	a5,-32(s0)
    int i;
    // 逐字节填充，实现简单可靠
    for(i = 0; i < n; i++) {
    80000f54:	fe042623          	sw	zero,-20(s0)
    80000f58:	a00d                	j	80000f7a <memset+0x46>
        cdst[i] = c;
    80000f5a:	fec42783          	lw	a5,-20(s0)
    80000f5e:	fe043703          	ld	a4,-32(s0)
    80000f62:	97ba                	add	a5,a5,a4
    80000f64:	fd442703          	lw	a4,-44(s0)
    80000f68:	0ff77713          	zext.b	a4,a4
    80000f6c:	00e78023          	sb	a4,0(a5)
    for(i = 0; i < n; i++) {
    80000f70:	fec42783          	lw	a5,-20(s0)
    80000f74:	2785                	addw	a5,a5,1
    80000f76:	fef42623          	sw	a5,-20(s0)
    80000f7a:	fec42703          	lw	a4,-20(s0)
    80000f7e:	fd042783          	lw	a5,-48(s0)
    80000f82:	2781                	sext.w	a5,a5
    80000f84:	fcf76be3          	bltu	a4,a5,80000f5a <memset+0x26>
    }
    return dst;
    80000f88:	fd843783          	ld	a5,-40(s0)
}
    80000f8c:	853e                	mv	a0,a5
    80000f8e:	7422                	ld	s0,40(sp)
    80000f90:	6145                	add	sp,sp,48
    80000f92:	8082                	ret

0000000080000f94 <pmm_init>:

// ==================== 初始化物理内存分配器 ====================
void pmm_init(void) {
    80000f94:	7179                	add	sp,sp,-48
    80000f96:	f406                	sd	ra,40(sp)
    80000f98:	f022                	sd	s0,32(sp)
    80000f9a:	1800                	add	s0,sp,48
    // 第一步：确定可分配内存范围
    // 内存布局: [内核代码+数据] [可分配区域] [内存结束]
    //          ^end           ^mem_start    ^PHYSTOP
    char *mem_start = (char*)PGROUNDUP((uint64)end);  // 内核结束后的第一个页面边界
    80000f9c:	0000a717          	auipc	a4,0xa
    80000fa0:	06470713          	add	a4,a4,100 # 8000b000 <panicking>
    80000fa4:	6785                	lui	a5,0x1
    80000fa6:	17fd                	add	a5,a5,-1 # fff <_start-0x7ffff001>
    80000fa8:	973e                	add	a4,a4,a5
    80000faa:	77fd                	lui	a5,0xfffff
    80000fac:	8ff9                	and	a5,a5,a4
    80000fae:	fef43023          	sd	a5,-32(s0)
    char *mem_end = (char*)PHYSTOP;                   // 物理内存结束位置
    80000fb2:	47c5                	li	a5,17
    80000fb4:	07ee                	sll	a5,a5,0x1b
    80000fb6:	fcf43c23          	sd	a5,-40(s0)
    
    // 第二步：初始化管理器状态
    kmem.freelist = 0;      // 空链表
    80000fba:	00009797          	auipc	a5,0x9
    80000fbe:	04678793          	add	a5,a5,70 # 8000a000 <kmem>
    80000fc2:	0007b023          	sd	zero,0(a5)
    kmem.total_pages = 0;   // 计数器清零
    80000fc6:	00009797          	auipc	a5,0x9
    80000fca:	03a78793          	add	a5,a5,58 # 8000a000 <kmem>
    80000fce:	0007b423          	sd	zero,8(a5)
    kmem.free_pages = 0;
    80000fd2:	00009797          	auipc	a5,0x9
    80000fd6:	02e78793          	add	a5,a5,46 # 8000a000 <kmem>
    80000fda:	0007b823          	sd	zero,16(a5)
    
    printf("PMM: Initializing memory from %p to %p\n", mem_start, mem_end);
    80000fde:	fd843603          	ld	a2,-40(s0)
    80000fe2:	fe043583          	ld	a1,-32(s0)
    80000fe6:	00002517          	auipc	a0,0x2
    80000fea:	52a50513          	add	a0,a0,1322 # 80003510 <etext+0x510>
    80000fee:	00000097          	auipc	ra,0x0
    80000ff2:	a1e080e7          	jalr	-1506(ra) # 80000a0c <printf>
    
    // 第三步：构建空闲页面链表
    // 遍历所有可用页面，逐个加入空闲链表
    char *p;
    for(p = mem_start; p + PGSIZE <= mem_end; p += PGSIZE) {
    80000ff6:	fe043783          	ld	a5,-32(s0)
    80000ffa:	fef43423          	sd	a5,-24(s0)
    80000ffe:	a089                	j	80001040 <pmm_init+0xac>
        // 为什么要清零？确保页面内容干净，避免信息泄露
        memset(p, 0, PGSIZE);
    80001000:	6605                	lui	a2,0x1
    80001002:	4581                	li	a1,0
    80001004:	fe843503          	ld	a0,-24(s0)
    80001008:	00000097          	auipc	ra,0x0
    8000100c:	f2c080e7          	jalr	-212(ra) # 80000f34 <memset>
        // 调用free_page将页面加入链表，复用释放逻辑
        free_page(p);
    80001010:	fe843503          	ld	a0,-24(s0)
    80001014:	00000097          	auipc	ra,0x0
    80001018:	0ee080e7          	jalr	238(ra) # 80001102 <free_page>
        kmem.total_pages++;   // 统计总页面数
    8000101c:	00009797          	auipc	a5,0x9
    80001020:	fe478793          	add	a5,a5,-28 # 8000a000 <kmem>
    80001024:	679c                	ld	a5,8(a5)
    80001026:	00178713          	add	a4,a5,1
    8000102a:	00009797          	auipc	a5,0x9
    8000102e:	fd678793          	add	a5,a5,-42 # 8000a000 <kmem>
    80001032:	e798                	sd	a4,8(a5)
    for(p = mem_start; p + PGSIZE <= mem_end; p += PGSIZE) {
    80001034:	fe843703          	ld	a4,-24(s0)
    80001038:	6785                	lui	a5,0x1
    8000103a:	97ba                	add	a5,a5,a4
    8000103c:	fef43423          	sd	a5,-24(s0)
    80001040:	fe843703          	ld	a4,-24(s0)
    80001044:	6785                	lui	a5,0x1
    80001046:	97ba                	add	a5,a5,a4
    80001048:	fd843703          	ld	a4,-40(s0)
    8000104c:	faf77ae3          	bgeu	a4,a5,80001000 <pmm_init+0x6c>
    }
    
    printf("PMM: Initialized %d pages (%d KB)\n", 
           (int)kmem.total_pages, (int)(kmem.total_pages * PGSIZE) / 1024);
    80001050:	00009797          	auipc	a5,0x9
    80001054:	fb078793          	add	a5,a5,-80 # 8000a000 <kmem>
    80001058:	679c                	ld	a5,8(a5)
    printf("PMM: Initialized %d pages (%d KB)\n", 
    8000105a:	0007869b          	sext.w	a3,a5
           (int)kmem.total_pages, (int)(kmem.total_pages * PGSIZE) / 1024);
    8000105e:	00009797          	auipc	a5,0x9
    80001062:	fa278793          	add	a5,a5,-94 # 8000a000 <kmem>
    80001066:	679c                	ld	a5,8(a5)
    80001068:	2781                	sext.w	a5,a5
    8000106a:	00c7979b          	sllw	a5,a5,0xc
    8000106e:	2781                	sext.w	a5,a5
    80001070:	2781                	sext.w	a5,a5
    printf("PMM: Initialized %d pages (%d KB)\n", 
    80001072:	41f7d71b          	sraw	a4,a5,0x1f
    80001076:	0167571b          	srlw	a4,a4,0x16
    8000107a:	9fb9                	addw	a5,a5,a4
    8000107c:	40a7d79b          	sraw	a5,a5,0xa
    80001080:	2781                	sext.w	a5,a5
    80001082:	863e                	mv	a2,a5
    80001084:	85b6                	mv	a1,a3
    80001086:	00002517          	auipc	a0,0x2
    8000108a:	4b250513          	add	a0,a0,1202 # 80003538 <etext+0x538>
    8000108e:	00000097          	auipc	ra,0x0
    80001092:	97e080e7          	jalr	-1666(ra) # 80000a0c <printf>
}
    80001096:	0001                	nop
    80001098:	70a2                	ld	ra,40(sp)
    8000109a:	7402                	ld	s0,32(sp)
    8000109c:	6145                	add	sp,sp,48
    8000109e:	8082                	ret

00000000800010a0 <alloc_page>:

// ==================== 分配一个物理页面 ====================
// 算法特点：LIFO(后进先出)，最近释放的页面优先被分配
// 时间复杂度：O(1) - 仅涉及链表头操作
void* alloc_page(void) {
    800010a0:	1101                	add	sp,sp,-32
    800010a2:	ec06                	sd	ra,24(sp)
    800010a4:	e822                	sd	s0,16(sp)
    800010a6:	1000                	add	s0,sp,32
    struct run *r;
    
    // 从链表头取出一个空闲页面
    r = kmem.freelist;
    800010a8:	00009797          	auipc	a5,0x9
    800010ac:	f5878793          	add	a5,a5,-168 # 8000a000 <kmem>
    800010b0:	639c                	ld	a5,0(a5)
    800010b2:	fef43423          	sd	a5,-24(s0)
    if(r) {
    800010b6:	fe843783          	ld	a5,-24(s0)
    800010ba:	cf8d                	beqz	a5,800010f4 <alloc_page+0x54>
        // 更新链表头指向下一个空闲页面
        kmem.freelist = r->next;
    800010bc:	fe843783          	ld	a5,-24(s0)
    800010c0:	6398                	ld	a4,0(a5)
    800010c2:	00009797          	auipc	a5,0x9
    800010c6:	f3e78793          	add	a5,a5,-194 # 8000a000 <kmem>
    800010ca:	e398                	sd	a4,0(a5)
        kmem.free_pages--;      // 更新空闲页面计数
    800010cc:	00009797          	auipc	a5,0x9
    800010d0:	f3478793          	add	a5,a5,-204 # 8000a000 <kmem>
    800010d4:	6b9c                	ld	a5,16(a5)
    800010d6:	fff78713          	add	a4,a5,-1
    800010da:	00009797          	auipc	a5,0x9
    800010de:	f2678793          	add	a5,a5,-218 # 8000a000 <kmem>
    800010e2:	eb98                	sd	a4,16(a5)
        
        // 安全措施：清零分配的页面，防止信息泄露
        // 确保新分配的页面内容是干净的
        memset((char*)r, 0, PGSIZE);
    800010e4:	6605                	lui	a2,0x1
    800010e6:	4581                	li	a1,0
    800010e8:	fe843503          	ld	a0,-24(s0)
    800010ec:	00000097          	auipc	ra,0x0
    800010f0:	e48080e7          	jalr	-440(ra) # 80000f34 <memset>
    }
    // 如果r为NULL，表示内存耗尽，返回NULL
    
    return (void*)r;
    800010f4:	fe843783          	ld	a5,-24(s0)
}
    800010f8:	853e                	mv	a0,a5
    800010fa:	60e2                	ld	ra,24(sp)
    800010fc:	6442                	ld	s0,16(sp)
    800010fe:	6105                	add	sp,sp,32
    80001100:	8082                	ret

0000000080001102 <free_page>:

// ==================== 释放一个物理页面 ====================  
// 算法特点：将页面插入链表头，实现LIFO释放
// 时间复杂度：O(1) - 仅涉及链表头操作
void free_page(void* pa) {
    80001102:	7179                	add	sp,sp,-48
    80001104:	f406                	sd	ra,40(sp)
    80001106:	f022                	sd	s0,32(sp)
    80001108:	1800                	add	s0,sp,48
    8000110a:	fca43c23          	sd	a0,-40(s0)
    struct run *r;
    
    // 第一步：地址有效性检查
    // 检查页面对齐：物理地址必须是4KB的整数倍
    if(((uint64)pa % PGSIZE) != 0)
    8000110e:	fd843703          	ld	a4,-40(s0)
    80001112:	6785                	lui	a5,0x1
    80001114:	17fd                	add	a5,a5,-1 # fff <_start-0x7ffff001>
    80001116:	8ff9                	and	a5,a5,a4
    80001118:	cb89                	beqz	a5,8000112a <free_page+0x28>
        panic("free_page: not page aligned");
    8000111a:	00002517          	auipc	a0,0x2
    8000111e:	44650513          	add	a0,a0,1094 # 80003560 <etext+0x560>
    80001122:	00000097          	auipc	ra,0x0
    80001126:	c90080e7          	jalr	-880(ra) # 80000db2 <panic>
    
    // 检查地址范围：必须在可管理的内存范围内
    // 防止释放内核代码/数据区域或超出物理内存的地址
    if((char*)pa < end || (uint64)pa >= PHYSTOP)
    8000112a:	fd843703          	ld	a4,-40(s0)
    8000112e:	0000a797          	auipc	a5,0xa
    80001132:	ed278793          	add	a5,a5,-302 # 8000b000 <panicking>
    80001136:	00f76863          	bltu	a4,a5,80001146 <free_page+0x44>
    8000113a:	fd843703          	ld	a4,-40(s0)
    8000113e:	47c5                	li	a5,17
    80001140:	07ee                	sll	a5,a5,0x1b
    80001142:	00f76a63          	bltu	a4,a5,80001156 <free_page+0x54>
        panic("free_page: invalid address");
    80001146:	00002517          	auipc	a0,0x2
    8000114a:	43a50513          	add	a0,a0,1082 # 80003580 <etext+0x580>
    8000114e:	00000097          	auipc	ra,0x0
    80001152:	c64080e7          	jalr	-924(ra) # 80000db2 <panic>

     // 检查是否已经释放过.在释放的页面中放置一个特殊的标记，下次释放时检查这个标记。
    uint32 *magic_ptr = (uint32*)pa;
    80001156:	fd843783          	ld	a5,-40(s0)
    8000115a:	fef43423          	sd	a5,-24(s0)
    if(*magic_ptr == FREE_MAGIC) {
    8000115e:	fe843783          	ld	a5,-24(s0)
    80001162:	439c                	lw	a5,0(a5)
    80001164:	873e                	mv	a4,a5
    80001166:	deadc7b7          	lui	a5,0xdeadc
    8000116a:	eef78793          	add	a5,a5,-273 # ffffffffdeadbeef <kernel_pagetable+0xffffffff5ead0ee7>
    8000116e:	00f71a63          	bne	a4,a5,80001182 <free_page+0x80>
        panic("free_page: double free detected");
    80001172:	00002517          	auipc	a0,0x2
    80001176:	42e50513          	add	a0,a0,1070 # 800035a0 <etext+0x5a0>
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	c38080e7          	jalr	-968(ra) # 80000db2 <panic>
    }
    
    // 填充魔数而不是全部填1
    *magic_ptr = FREE_MAGIC;
    80001182:	fe843783          	ld	a5,-24(s0)
    80001186:	deadc737          	lui	a4,0xdeadc
    8000118a:	eef70713          	add	a4,a4,-273 # ffffffffdeadbeef <kernel_pagetable+0xffffffff5ead0ee7>
    8000118e:	c398                	sw	a4,0(a5)
    // 第二步：安全擦除页面内容
    // 填充特殊值(1)有助于检测use-after-free错误
    // 如果程序试图使用已释放的页面，会读到异常的数据模式
    // 其余部分仍然填1
    memset((char*)pa + 4, 1, PGSIZE - 4);
    80001190:	fd843783          	ld	a5,-40(s0)
    80001194:	00478713          	add	a4,a5,4
    80001198:	6785                	lui	a5,0x1
    8000119a:	ffc78613          	add	a2,a5,-4 # ffc <_start-0x7ffff004>
    8000119e:	4585                	li	a1,1
    800011a0:	853a                	mv	a0,a4
    800011a2:	00000097          	auipc	ra,0x0
    800011a6:	d92080e7          	jalr	-622(ra) # 80000f34 <memset>
    
    // 第三步：将页面插入空闲链表头部
    r = (struct run*)pa;        // 将页面地址转换为链表节点
    800011aa:	fd843783          	ld	a5,-40(s0)
    800011ae:	fef43023          	sd	a5,-32(s0)
    r->next = kmem.freelist;    // 新节点指向当前链表头
    800011b2:	00009797          	auipc	a5,0x9
    800011b6:	e4e78793          	add	a5,a5,-434 # 8000a000 <kmem>
    800011ba:	6398                	ld	a4,0(a5)
    800011bc:	fe043783          	ld	a5,-32(s0)
    800011c0:	e398                	sd	a4,0(a5)
    kmem.freelist = r;          // 更新链表头为新节点
    800011c2:	00009797          	auipc	a5,0x9
    800011c6:	e3e78793          	add	a5,a5,-450 # 8000a000 <kmem>
    800011ca:	fe043703          	ld	a4,-32(s0)
    800011ce:	e398                	sd	a4,0(a5)
    kmem.free_pages++;          // 更新空闲页面计数
    800011d0:	00009797          	auipc	a5,0x9
    800011d4:	e3078793          	add	a5,a5,-464 # 8000a000 <kmem>
    800011d8:	6b9c                	ld	a5,16(a5)
    800011da:	00178713          	add	a4,a5,1
    800011de:	00009797          	auipc	a5,0x9
    800011e2:	e2278793          	add	a5,a5,-478 # 8000a000 <kmem>
    800011e6:	eb98                	sd	a4,16(a5)
}
    800011e8:	0001                	nop
    800011ea:	70a2                	ld	ra,40(sp)
    800011ec:	7402                	ld	s0,32(sp)
    800011ee:	6145                	add	sp,sp,48
    800011f0:	8082                	ret

00000000800011f2 <pmm_info>:

// ==================== 内存使用信息统计 ====================
// 用途：调试、监控、性能分析
void pmm_info(void) {
    800011f2:	1141                	add	sp,sp,-16
    800011f4:	e406                	sd	ra,8(sp)
    800011f6:	e022                	sd	s0,0(sp)
    800011f8:	0800                	add	s0,sp,16
    printf("Memory Info:\n");
    800011fa:	00002517          	auipc	a0,0x2
    800011fe:	3c650513          	add	a0,a0,966 # 800035c0 <etext+0x5c0>
    80001202:	00000097          	auipc	ra,0x0
    80001206:	80a080e7          	jalr	-2038(ra) # 80000a0c <printf>
    printf("  Total pages: %d (%d KB)\n", 
           (int)kmem.total_pages, (int)(kmem.total_pages * PGSIZE) / 1024);
    8000120a:	00009797          	auipc	a5,0x9
    8000120e:	df678793          	add	a5,a5,-522 # 8000a000 <kmem>
    80001212:	679c                	ld	a5,8(a5)
    printf("  Total pages: %d (%d KB)\n", 
    80001214:	0007869b          	sext.w	a3,a5
           (int)kmem.total_pages, (int)(kmem.total_pages * PGSIZE) / 1024);
    80001218:	00009797          	auipc	a5,0x9
    8000121c:	de878793          	add	a5,a5,-536 # 8000a000 <kmem>
    80001220:	679c                	ld	a5,8(a5)
    80001222:	2781                	sext.w	a5,a5
    80001224:	00c7979b          	sllw	a5,a5,0xc
    80001228:	2781                	sext.w	a5,a5
    8000122a:	2781                	sext.w	a5,a5
    printf("  Total pages: %d (%d KB)\n", 
    8000122c:	41f7d71b          	sraw	a4,a5,0x1f
    80001230:	0167571b          	srlw	a4,a4,0x16
    80001234:	9fb9                	addw	a5,a5,a4
    80001236:	40a7d79b          	sraw	a5,a5,0xa
    8000123a:	2781                	sext.w	a5,a5
    8000123c:	863e                	mv	a2,a5
    8000123e:	85b6                	mv	a1,a3
    80001240:	00002517          	auipc	a0,0x2
    80001244:	39050513          	add	a0,a0,912 # 800035d0 <etext+0x5d0>
    80001248:	fffff097          	auipc	ra,0xfffff
    8000124c:	7c4080e7          	jalr	1988(ra) # 80000a0c <printf>
    printf("  Free pages:  %d (%d KB)\n", 
           (int)kmem.free_pages, (int)(kmem.free_pages * PGSIZE) / 1024);
    80001250:	00009797          	auipc	a5,0x9
    80001254:	db078793          	add	a5,a5,-592 # 8000a000 <kmem>
    80001258:	6b9c                	ld	a5,16(a5)
    printf("  Free pages:  %d (%d KB)\n", 
    8000125a:	0007869b          	sext.w	a3,a5
           (int)kmem.free_pages, (int)(kmem.free_pages * PGSIZE) / 1024);
    8000125e:	00009797          	auipc	a5,0x9
    80001262:	da278793          	add	a5,a5,-606 # 8000a000 <kmem>
    80001266:	6b9c                	ld	a5,16(a5)
    80001268:	2781                	sext.w	a5,a5
    8000126a:	00c7979b          	sllw	a5,a5,0xc
    8000126e:	2781                	sext.w	a5,a5
    80001270:	2781                	sext.w	a5,a5
    printf("  Free pages:  %d (%d KB)\n", 
    80001272:	41f7d71b          	sraw	a4,a5,0x1f
    80001276:	0167571b          	srlw	a4,a4,0x16
    8000127a:	9fb9                	addw	a5,a5,a4
    8000127c:	40a7d79b          	sraw	a5,a5,0xa
    80001280:	2781                	sext.w	a5,a5
    80001282:	863e                	mv	a2,a5
    80001284:	85b6                	mv	a1,a3
    80001286:	00002517          	auipc	a0,0x2
    8000128a:	36a50513          	add	a0,a0,874 # 800035f0 <etext+0x5f0>
    8000128e:	fffff097          	auipc	ra,0xfffff
    80001292:	77e080e7          	jalr	1918(ra) # 80000a0c <printf>
    printf("  Used pages:  %d (%d KB)\n", 
           (int)(kmem.total_pages - kmem.free_pages), 
    80001296:	00009797          	auipc	a5,0x9
    8000129a:	d6a78793          	add	a5,a5,-662 # 8000a000 <kmem>
    8000129e:	679c                	ld	a5,8(a5)
    800012a0:	0007871b          	sext.w	a4,a5
    800012a4:	00009797          	auipc	a5,0x9
    800012a8:	d5c78793          	add	a5,a5,-676 # 8000a000 <kmem>
    800012ac:	6b9c                	ld	a5,16(a5)
    800012ae:	2781                	sext.w	a5,a5
    800012b0:	40f707bb          	subw	a5,a4,a5
    800012b4:	2781                	sext.w	a5,a5
    printf("  Used pages:  %d (%d KB)\n", 
    800012b6:	0007869b          	sext.w	a3,a5
           (int)((kmem.total_pages - kmem.free_pages) * PGSIZE) / 1024);
    800012ba:	00009797          	auipc	a5,0x9
    800012be:	d4678793          	add	a5,a5,-698 # 8000a000 <kmem>
    800012c2:	6798                	ld	a4,8(a5)
    800012c4:	00009797          	auipc	a5,0x9
    800012c8:	d3c78793          	add	a5,a5,-708 # 8000a000 <kmem>
    800012cc:	6b9c                	ld	a5,16(a5)
    800012ce:	40f707b3          	sub	a5,a4,a5
    800012d2:	2781                	sext.w	a5,a5
    800012d4:	00c7979b          	sllw	a5,a5,0xc
    800012d8:	2781                	sext.w	a5,a5
    800012da:	2781                	sext.w	a5,a5
    printf("  Used pages:  %d (%d KB)\n", 
    800012dc:	41f7d71b          	sraw	a4,a5,0x1f
    800012e0:	0167571b          	srlw	a4,a4,0x16
    800012e4:	9fb9                	addw	a5,a5,a4
    800012e6:	40a7d79b          	sraw	a5,a5,0xa
    800012ea:	2781                	sext.w	a5,a5
    800012ec:	863e                	mv	a2,a5
    800012ee:	85b6                	mv	a1,a3
    800012f0:	00002517          	auipc	a0,0x2
    800012f4:	32050513          	add	a0,a0,800 # 80003610 <etext+0x610>
    800012f8:	fffff097          	auipc	ra,0xfffff
    800012fc:	714080e7          	jalr	1812(ra) # 80000a0c <printf>
}
    80001300:	0001                	nop
    80001302:	60a2                	ld	ra,8(sp)
    80001304:	6402                	ld	s0,0(sp)
    80001306:	0141                	add	sp,sp,16
    80001308:	8082                	ret

000000008000130a <w_satp>:
pagetable_t kernel_pagetable;

// 创建一个新的页表
// 返回值：成功返回页表指针，失败返回0
// 设计要点：页表本身就是一个4KB的物理页面，包含512个64位页表项
pagetable_t create_pagetable(void) {
    8000130a:	1101                	add	sp,sp,-32
    8000130c:	ec22                	sd	s0,24(sp)
    8000130e:	1000                	add	s0,sp,32
    80001310:	fea43423          	sd	a0,-24(s0)
    // 分配一个物理页面作为页表存储空间
    80001314:	fe843783          	ld	a5,-24(s0)
    80001318:	18079073          	csrw	satp,a5
    // 关键理解：页表也存储在物理内存中，是普通的数据结构
    8000131c:	0001                	nop
    8000131e:	6462                	ld	s0,24(sp)
    80001320:	6105                	add	sp,sp,32
    80001322:	8082                	ret

0000000080001324 <sfence_vma>:
    pagetable_t pagetable = (pagetable_t)alloc_page();
    if(pagetable == 0)
        return 0;
    80001324:	1141                	add	sp,sp,-16
    80001326:	e422                	sd	s0,8(sp)
    80001328:	0800                	add	s0,sp,16
    
    8000132a:	12000073          	sfence.vma
    // 页表已在alloc_page中清零
    8000132e:	0001                	nop
    80001330:	6422                	ld	s0,8(sp)
    80001332:	0141                	add	sp,sp,16
    80001334:	8082                	ret

0000000080001336 <create_pagetable>:
pagetable_t create_pagetable(void) {
    80001336:	1101                	add	sp,sp,-32
    80001338:	ec06                	sd	ra,24(sp)
    8000133a:	e822                	sd	s0,16(sp)
    8000133c:	1000                	add	s0,sp,32
    pagetable_t pagetable = (pagetable_t)alloc_page();
    8000133e:	00000097          	auipc	ra,0x0
    80001342:	d62080e7          	jalr	-670(ra) # 800010a0 <alloc_page>
    80001346:	fea43423          	sd	a0,-24(s0)
    if(pagetable == 0)
    8000134a:	fe843783          	ld	a5,-24(s0)
    8000134e:	e399                	bnez	a5,80001354 <create_pagetable+0x1e>
        return 0;
    80001350:	4781                	li	a5,0
    80001352:	a019                	j	80001358 <create_pagetable+0x22>
    // 重要：新页表所有PTE初始值为0，即所有页表项都无效(V位=0)
    return pagetable;
    80001354:	fe843783          	ld	a5,-24(s0)
}
    80001358:	853e                	mv	a0,a5
    8000135a:	60e2                	ld	ra,24(sp)
    8000135c:	6442                	ld	s0,16(sp)
    8000135e:	6105                	add	sp,sp,32
    80001360:	8082                	ret

0000000080001362 <freewalk>:

// 递归释放页表及其子页表
// 参数：pagetable - 要释放的页表根节点
// 设计要点：三级页表结构需要递归释放，避免内存泄漏
static void freewalk(pagetable_t pagetable) {
    80001362:	7139                	add	sp,sp,-64
    80001364:	fc06                	sd	ra,56(sp)
    80001366:	f822                	sd	s0,48(sp)
    80001368:	0080                	add	s0,sp,64
    8000136a:	fca43423          	sd	a0,-56(s0)
    // 遍历512个页表项 - 每个页表页面包含512个64位PTE
    // 计算依据：4KB页面 ÷ 8字节PTE = 512个条目，需要9位索引
    for(int i = 0; i < 512; i++) {
    8000136e:	fe042623          	sw	zero,-20(s0)
    80001372:	a8a1                	j	800013ca <freewalk+0x68>
        pte_t pte = pagetable[i];
    80001374:	fec42783          	lw	a5,-20(s0)
    80001378:	078e                	sll	a5,a5,0x3
    8000137a:	fc843703          	ld	a4,-56(s0)
    8000137e:	97ba                	add	a5,a5,a4
    80001380:	639c                	ld	a5,0(a5)
    80001382:	fef43023          	sd	a5,-32(s0)
        if(pte & PTE_V) {  // 检查有效位，只处理有效的页表项
    80001386:	fe043783          	ld	a5,-32(s0)
    8000138a:	8b85                	and	a5,a5,1
    8000138c:	cb95                	beqz	a5,800013c0 <freewalk+0x5e>
            // 关键判断：区分中间级页表项和叶子页表项
            // 中间级页表项：R/W/X位全为0，指向下一级页表
            // 叶子页表项：至少有一个R/W/X位为1，指向最终物理页面
            if((pte & (PTE_R|PTE_W|PTE_X)) == 0) {
    8000138e:	fe043783          	ld	a5,-32(s0)
    80001392:	8bb9                	and	a5,a5,14
    80001394:	e795                	bnez	a5,800013c0 <freewalk+0x5e>
                // 这是中间级页表项，需要递归释放子页表
                uint64 child = PTE_PA(pte);  // 提取子页表的物理地址
    80001396:	fe043783          	ld	a5,-32(s0)
    8000139a:	83a9                	srl	a5,a5,0xa
    8000139c:	07b2                	sll	a5,a5,0xc
    8000139e:	fcf43c23          	sd	a5,-40(s0)
                freewalk((pagetable_t)child);  // 递归释放子页表
    800013a2:	fd843783          	ld	a5,-40(s0)
    800013a6:	853e                	mv	a0,a5
    800013a8:	00000097          	auipc	ra,0x0
    800013ac:	fba080e7          	jalr	-70(ra) # 80001362 <freewalk>
                pagetable[i] = 0;  // 清除页表项，避免悬挂指针
    800013b0:	fec42783          	lw	a5,-20(s0)
    800013b4:	078e                	sll	a5,a5,0x3
    800013b6:	fc843703          	ld	a4,-56(s0)
    800013ba:	97ba                	add	a5,a5,a4
    800013bc:	0007b023          	sd	zero,0(a5)
    for(int i = 0; i < 512; i++) {
    800013c0:	fec42783          	lw	a5,-20(s0)
    800013c4:	2785                	addw	a5,a5,1
    800013c6:	fef42623          	sw	a5,-20(s0)
    800013ca:	fec42783          	lw	a5,-20(s0)
    800013ce:	0007871b          	sext.w	a4,a5
    800013d2:	1ff00793          	li	a5,511
    800013d6:	f8e7dfe3          	bge	a5,a4,80001374 <freewalk+0x12>
            }
            // 注意：叶子页表项指向的物理页面不在这里释放，由上层管理
        }
    }
    // 释放当前页表占用的物理页面
    free_page((void*)pagetable);
    800013da:	fc843503          	ld	a0,-56(s0)
    800013de:	00000097          	auipc	ra,0x0
    800013e2:	d24080e7          	jalr	-732(ra) # 80001102 <free_page>
}
    800013e6:	0001                	nop
    800013e8:	70e2                	ld	ra,56(sp)
    800013ea:	7442                	ld	s0,48(sp)
    800013ec:	6121                	add	sp,sp,64
    800013ee:	8082                	ret

00000000800013f0 <destroy_pagetable>:

// 销毁页表 - 公共接口，包含空指针检查
void destroy_pagetable(pagetable_t pagetable) {
    800013f0:	1101                	add	sp,sp,-32
    800013f2:	ec06                	sd	ra,24(sp)
    800013f4:	e822                	sd	s0,16(sp)
    800013f6:	1000                	add	s0,sp,32
    800013f8:	fea43423          	sd	a0,-24(s0)
    if(pagetable == 0)
    800013fc:	fe843783          	ld	a5,-24(s0)
    80001400:	cb81                	beqz	a5,80001410 <destroy_pagetable+0x20>
        return;
    freewalk(pagetable);
    80001402:	fe843503          	ld	a0,-24(s0)
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	f5c080e7          	jalr	-164(ra) # 80001362 <freewalk>
    8000140e:	a011                	j	80001412 <destroy_pagetable+0x22>
        return;
    80001410:	0001                	nop
}
    80001412:	60e2                	ld	ra,24(sp)
    80001414:	6442                	ld	s0,16(sp)
    80001416:	6105                	add	sp,sp,32
    80001418:	8082                	ret

000000008000141a <walk_lookup>:

// 页表遍历 - 查找模式(不创建新页表)
// 参数：pagetable - 根页表，va - 虚拟地址
// 返回值：指向最终PTE的指针，如果路径不存在返回0
// 用途：查找现有映射，不修改页表结构
pte_t* walk_lookup(pagetable_t pagetable, uint64 va) {
    8000141a:	7179                	add	sp,sp,-48
    8000141c:	f406                	sd	ra,40(sp)
    8000141e:	f022                	sd	s0,32(sp)
    80001420:	1800                	add	s0,sp,48
    80001422:	fca43c23          	sd	a0,-40(s0)
    80001426:	fcb43823          	sd	a1,-48(s0)
    // Sv39地址空间限制检查：39位虚拟地址，最大512GB
    // 超出范围的地址是非法的，直接panic
    if(va >= (1L << 39))
    8000142a:	fd043703          	ld	a4,-48(s0)
    8000142e:	57fd                	li	a5,-1
    80001430:	83e5                	srl	a5,a5,0x19
    80001432:	00e7fa63          	bgeu	a5,a4,80001446 <walk_lookup+0x2c>
        panic("walk_lookup: va too large");
    80001436:	00002517          	auipc	a0,0x2
    8000143a:	1fa50513          	add	a0,a0,506 # 80003630 <etext+0x630>
    8000143e:	00000097          	auipc	ra,0x0
    80001442:	974080e7          	jalr	-1676(ra) # 80000db2 <panic>
    
    // 三级页表遍历：level 2→1→0，对应VPN[2]→VPN[1]→VPN[0]
    // 地址分解：bits[38:30] | bits[29:21] | bits[20:12] | bits[11:0]
    //          VPN[2]      | VPN[1]      | VPN[0]      | offset
    for(int level = 2; level > 0; level--) {
    80001446:	4789                	li	a5,2
    80001448:	fef42623          	sw	a5,-20(s0)
    8000144c:	a8a1                	j	800014a4 <walk_lookup+0x8a>
        // PX宏提取指定级别的9位索引：(va >> (12+9*level)) & 0x1FF
        pte_t *pte = &pagetable[PX(level, va)];
    8000144e:	fec42783          	lw	a5,-20(s0)
    80001452:	873e                	mv	a4,a5
    80001454:	87ba                	mv	a5,a4
    80001456:	0037979b          	sllw	a5,a5,0x3
    8000145a:	9fb9                	addw	a5,a5,a4
    8000145c:	2781                	sext.w	a5,a5
    8000145e:	27b1                	addw	a5,a5,12
    80001460:	2781                	sext.w	a5,a5
    80001462:	873e                	mv	a4,a5
    80001464:	fd043783          	ld	a5,-48(s0)
    80001468:	00e7d7b3          	srl	a5,a5,a4
    8000146c:	1ff7f793          	and	a5,a5,511
    80001470:	078e                	sll	a5,a5,0x3
    80001472:	fd843703          	ld	a4,-40(s0)
    80001476:	97ba                	add	a5,a5,a4
    80001478:	fef43023          	sd	a5,-32(s0)
        if(*pte & PTE_V) {  // 页表项有效，继续遍历下一级
    8000147c:	fe043783          	ld	a5,-32(s0)
    80001480:	639c                	ld	a5,0(a5)
    80001482:	8b85                	and	a5,a5,1
    80001484:	cb89                	beqz	a5,80001496 <walk_lookup+0x7c>
            // 提取子页表物理地址，转换为页表指针继续遍历
            pagetable = (pagetable_t)PTE_PA(*pte);
    80001486:	fe043783          	ld	a5,-32(s0)
    8000148a:	639c                	ld	a5,0(a5)
    8000148c:	83a9                	srl	a5,a5,0xa
    8000148e:	07b2                	sll	a5,a5,0xc
    80001490:	fcf43c23          	sd	a5,-40(s0)
    80001494:	a019                	j	8000149a <walk_lookup+0x80>
        } else {
            // 遇到无效页表项，查找失败
            // 查找模式不创建页表，直接返回失败
            return 0;
    80001496:	4781                	li	a5,0
    80001498:	a025                	j	800014c0 <walk_lookup+0xa6>
    for(int level = 2; level > 0; level--) {
    8000149a:	fec42783          	lw	a5,-20(s0)
    8000149e:	37fd                	addw	a5,a5,-1
    800014a0:	fef42623          	sw	a5,-20(s0)
    800014a4:	fec42783          	lw	a5,-20(s0)
    800014a8:	2781                	sext.w	a5,a5
    800014aa:	faf042e3          	bgtz	a5,8000144e <walk_lookup+0x34>
        }
    }
    // 返回最终级别(level=0)的页表项指针
    return &pagetable[PX(0, va)];
    800014ae:	fd043783          	ld	a5,-48(s0)
    800014b2:	83b1                	srl	a5,a5,0xc
    800014b4:	1ff7f793          	and	a5,a5,511
    800014b8:	078e                	sll	a5,a5,0x3
    800014ba:	fd843703          	ld	a4,-40(s0)
    800014be:	97ba                	add	a5,a5,a4
}
    800014c0:	853e                	mv	a0,a5
    800014c2:	70a2                	ld	ra,40(sp)
    800014c4:	7402                	ld	s0,32(sp)
    800014c6:	6145                	add	sp,sp,48
    800014c8:	8082                	ret

00000000800014ca <walk_create>:

// 页表遍历 - 创建模式(必要时创建新页表)
// 与walk_lookup的区别：遇到无效页表项时会创建新的中间页表
// 用途：建立新的虚拟地址映射
pte_t* walk_create(pagetable_t pagetable, uint64 va) {
    800014ca:	7179                	add	sp,sp,-48
    800014cc:	f406                	sd	ra,40(sp)
    800014ce:	f022                	sd	s0,32(sp)
    800014d0:	1800                	add	s0,sp,48
    800014d2:	fca43c23          	sd	a0,-40(s0)
    800014d6:	fcb43823          	sd	a1,-48(s0)
    // 相同的地址范围检查
    if(va >= (1L << 39))
    800014da:	fd043703          	ld	a4,-48(s0)
    800014de:	57fd                	li	a5,-1
    800014e0:	83e5                	srl	a5,a5,0x19
    800014e2:	00e7fa63          	bgeu	a5,a4,800014f6 <walk_create+0x2c>
        panic("walk_create: va too large");
    800014e6:	00002517          	auipc	a0,0x2
    800014ea:	16a50513          	add	a0,a0,362 # 80003650 <etext+0x650>
    800014ee:	00000097          	auipc	ra,0x0
    800014f2:	8c4080e7          	jalr	-1852(ra) # 80000db2 <panic>
    
    // 相同的三级遍历逻辑
    for(int level = 2; level > 0; level--) {
    800014f6:	4789                	li	a5,2
    800014f8:	fef42623          	sw	a5,-20(s0)
    800014fc:	a8b5                	j	80001578 <walk_create+0xae>
        pte_t *pte = &pagetable[PX(level, va)];
    800014fe:	fec42783          	lw	a5,-20(s0)
    80001502:	873e                	mv	a4,a5
    80001504:	87ba                	mv	a5,a4
    80001506:	0037979b          	sllw	a5,a5,0x3
    8000150a:	9fb9                	addw	a5,a5,a4
    8000150c:	2781                	sext.w	a5,a5
    8000150e:	27b1                	addw	a5,a5,12
    80001510:	2781                	sext.w	a5,a5
    80001512:	873e                	mv	a4,a5
    80001514:	fd043783          	ld	a5,-48(s0)
    80001518:	00e7d7b3          	srl	a5,a5,a4
    8000151c:	1ff7f793          	and	a5,a5,511
    80001520:	078e                	sll	a5,a5,0x3
    80001522:	fd843703          	ld	a4,-40(s0)
    80001526:	97ba                	add	a5,a5,a4
    80001528:	fef43023          	sd	a5,-32(s0)
        if(*pte & PTE_V) {
    8000152c:	fe043783          	ld	a5,-32(s0)
    80001530:	639c                	ld	a5,0(a5)
    80001532:	8b85                	and	a5,a5,1
    80001534:	cb89                	beqz	a5,80001546 <walk_create+0x7c>
            // 页表项有效，继续遍历
            pagetable = (pagetable_t)PTE_PA(*pte);
    80001536:	fe043783          	ld	a5,-32(s0)
    8000153a:	639c                	ld	a5,0(a5)
    8000153c:	83a9                	srl	a5,a5,0xa
    8000153e:	07b2                	sll	a5,a5,0xc
    80001540:	fcf43c23          	sd	a5,-40(s0)
    80001544:	a02d                	j	8000156e <walk_create+0xa4>
        } else {
            // 关键差异：创建缺失的中间页表
            // 需要创建新的页表来完成映射路径
            pagetable = (pagetable_t)alloc_page();
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	b5a080e7          	jalr	-1190(ra) # 800010a0 <alloc_page>
    8000154e:	fca43c23          	sd	a0,-40(s0)
            if(pagetable == 0)
    80001552:	fd843783          	ld	a5,-40(s0)
    80001556:	e399                	bnez	a5,8000155c <walk_create+0x92>
                return 0;  // 内存分配失败，映射失败
    80001558:	4781                	li	a5,0
    8000155a:	a82d                	j	80001594 <walk_create+0xca>
            // 设置新创建的页表项：物理地址+有效位
// 注意：中间级页表项不设置R/W/X位，只设置V位
//R/W/X全为0表示这是指向下级页表的指针
//只有叶子节点才设置R/W/X位表示最终的内存权限
            *pte = PA2PTE(pagetable) | PTE_V;
    8000155c:	fd843783          	ld	a5,-40(s0)
    80001560:	83b1                	srl	a5,a5,0xc
    80001562:	07aa                	sll	a5,a5,0xa
    80001564:	0017e713          	or	a4,a5,1
    80001568:	fe043783          	ld	a5,-32(s0)
    8000156c:	e398                	sd	a4,0(a5)
    for(int level = 2; level > 0; level--) {
    8000156e:	fec42783          	lw	a5,-20(s0)
    80001572:	37fd                	addw	a5,a5,-1
    80001574:	fef42623          	sw	a5,-20(s0)
    80001578:	fec42783          	lw	a5,-20(s0)
    8000157c:	2781                	sext.w	a5,a5
    8000157e:	f8f040e3          	bgtz	a5,800014fe <walk_create+0x34>
        }
    }
    return &pagetable[PX(0, va)];
    80001582:	fd043783          	ld	a5,-48(s0)
    80001586:	83b1                	srl	a5,a5,0xc
    80001588:	1ff7f793          	and	a5,a5,511
    8000158c:	078e                	sll	a5,a5,0x3
    8000158e:	fd843703          	ld	a4,-40(s0)
    80001592:	97ba                	add	a5,a5,a4
}
    80001594:	853e                	mv	a0,a5
    80001596:	70a2                	ld	ra,40(sp)
    80001598:	7402                	ld	s0,32(sp)
    8000159a:	6145                	add	sp,sp,48
    8000159c:	8082                	ret

000000008000159e <map_page>:

// 映射单个页面 - 建立VA到PA的映射关系
// 参数：pagetable-页表，va-虚拟地址，pa-物理地址，perm-权限位
// 返回值：成功返回0，失败返回-1
int map_page(pagetable_t pagetable, uint64 va, uint64 pa, int perm) {
    8000159e:	7139                	add	sp,sp,-64
    800015a0:	fc06                	sd	ra,56(sp)
    800015a2:	f822                	sd	s0,48(sp)
    800015a4:	0080                	add	s0,sp,64
    800015a6:	fca43c23          	sd	a0,-40(s0)
    800015aa:	fcb43823          	sd	a1,-48(s0)
    800015ae:	fcc43423          	sd	a2,-56(s0)
    800015b2:	87b6                	mv	a5,a3
    800015b4:	fcf42223          	sw	a5,-60(s0)
    // 地址对齐检查：虚拟地址和物理地址都必须页面对齐(4KB边界)
    // 原因：MMU按页面操作，页表项只存储页号，不存储页内偏移
    if(va % PGSIZE != 0)
    800015b8:	fd043703          	ld	a4,-48(s0)
    800015bc:	6785                	lui	a5,0x1
    800015be:	17fd                	add	a5,a5,-1 # fff <_start-0x7ffff001>
    800015c0:	8ff9                	and	a5,a5,a4
    800015c2:	cb89                	beqz	a5,800015d4 <map_page+0x36>
        panic("map_page: va not page aligned");
    800015c4:	00002517          	auipc	a0,0x2
    800015c8:	0ac50513          	add	a0,a0,172 # 80003670 <etext+0x670>
    800015cc:	fffff097          	auipc	ra,0xfffff
    800015d0:	7e6080e7          	jalr	2022(ra) # 80000db2 <panic>
    if(pa % PGSIZE != 0)
    800015d4:	fc843703          	ld	a4,-56(s0)
    800015d8:	6785                	lui	a5,0x1
    800015da:	17fd                	add	a5,a5,-1 # fff <_start-0x7ffff001>
    800015dc:	8ff9                	and	a5,a5,a4
    800015de:	cb89                	beqz	a5,800015f0 <map_page+0x52>
        panic("map_page: pa not page aligned");
    800015e0:	00002517          	auipc	a0,0x2
    800015e4:	0b050513          	add	a0,a0,176 # 80003690 <etext+0x690>
    800015e8:	fffff097          	auipc	ra,0xfffff
    800015ec:	7ca080e7          	jalr	1994(ra) # 80000db2 <panic>
    
    // 获取或创建到达目标虚拟地址的页表项
    pte_t *pte = walk_create(pagetable, va);
    800015f0:	fd043583          	ld	a1,-48(s0)
    800015f4:	fd843503          	ld	a0,-40(s0)
    800015f8:	00000097          	auipc	ra,0x0
    800015fc:	ed2080e7          	jalr	-302(ra) # 800014ca <walk_create>
    80001600:	fea43423          	sd	a0,-24(s0)
    if(pte == 0)
    80001604:	fe843783          	ld	a5,-24(s0)
    80001608:	e399                	bnez	a5,8000160e <map_page+0x70>
        return -1;  // 页表创建失败(通常是内存不足)
    8000160a:	57fd                	li	a5,-1
    8000160c:	a825                	j	80001644 <map_page+0xa6>
    
    // 检查重复映射：如果页表项已有效，说明该虚拟地址已被映射
    // 重复映射通常是程序错误，应该panic而不是静默覆盖
    if(*pte & PTE_V)
    8000160e:	fe843783          	ld	a5,-24(s0)
    80001612:	639c                	ld	a5,0(a5)
    80001614:	8b85                	and	a5,a5,1
    80001616:	cb89                	beqz	a5,80001628 <map_page+0x8a>
        panic("map_page: page already mapped");
    80001618:	00002517          	auipc	a0,0x2
    8000161c:	09850513          	add	a0,a0,152 # 800036b0 <etext+0x6b0>
    80001620:	fffff097          	auipc	ra,0xfffff
    80001624:	792080e7          	jalr	1938(ra) # 80000db2 <panic>
    
    // 设置页表项：物理地址+权限位+有效位
    // PA2PTE：将物理地址转换为PTE格式(右移12位得到页号，左移10位到正确位置)
    // perm：包含R/W/X/U等权限位的组合
    // PTE_V：有效位，表示该映射有效
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001628:	fc843783          	ld	a5,-56(s0)
    8000162c:	83b1                	srl	a5,a5,0xc
    8000162e:	00a79713          	sll	a4,a5,0xa
    80001632:	fc442783          	lw	a5,-60(s0)
    80001636:	8fd9                	or	a5,a5,a4
    80001638:	0017e713          	or	a4,a5,1
    8000163c:	fe843783          	ld	a5,-24(s0)
    80001640:	e398                	sd	a4,0(a5)
    return 0;
    80001642:	4781                	li	a5,0
}
    80001644:	853e                	mv	a0,a5
    80001646:	70e2                	ld	ra,56(sp)
    80001648:	7442                	ld	s0,48(sp)
    8000164a:	6121                	add	sp,sp,64
    8000164c:	8082                	ret

000000008000164e <map_region>:

// 映射一个内存区域 - 批量建立连续的页面映射
// 参数：va,pa-起始地址，size-大小，perm-权限
// 用途：映射大块内存区域，如内核代码段、数据段等
int map_region(pagetable_t pagetable, uint64 va, uint64 pa, uint64 size, int perm) {
    8000164e:	715d                	add	sp,sp,-80
    80001650:	e486                	sd	ra,72(sp)
    80001652:	e0a2                	sd	s0,64(sp)
    80001654:	0880                	add	s0,sp,80
    80001656:	fca43c23          	sd	a0,-40(s0)
    8000165a:	fcb43823          	sd	a1,-48(s0)
    8000165e:	fcc43423          	sd	a2,-56(s0)
    80001662:	fcd43023          	sd	a3,-64(s0)
    80001666:	87ba                	mv	a5,a4
    80001668:	faf42e23          	sw	a5,-68(s0)
    uint64 a, last;
    
    if(size == 0)
    8000166c:	fc043783          	ld	a5,-64(s0)
    80001670:	e399                	bnez	a5,80001676 <map_region+0x28>
        return 0;  // 零大小区域，直接成功
    80001672:	4781                	li	a5,0
    80001674:	a885                	j	800016e4 <map_region+0x96>
    
    // 地址对齐：确保映射从页边界开始和结束
    // PGROUNDDOWN：向下对齐到页边界，确保不遗漏任何页面
    a = PGROUNDDOWN(va);
    80001676:	fd043703          	ld	a4,-48(s0)
    8000167a:	77fd                	lui	a5,0xfffff
    8000167c:	8ff9                	and	a5,a5,a4
    8000167e:	fef43423          	sd	a5,-24(s0)
    last = PGROUNDDOWN(va + size - 1);  // 最后一页的起始地址
    80001682:	fd043703          	ld	a4,-48(s0)
    80001686:	fc043783          	ld	a5,-64(s0)
    8000168a:	97ba                	add	a5,a5,a4
    8000168c:	fff78713          	add	a4,a5,-1 # ffffffffffffefff <kernel_pagetable+0xffffffff7fff3ff7>
    80001690:	77fd                	lui	a5,0xfffff
    80001692:	8ff9                	and	a5,a5,a4
    80001694:	fef43023          	sd	a5,-32(s0)
    
    // 逐页建立映射，虚拟地址和物理地址同步递增
    // 这实现了恒等映射(identity mapping)：VA = PA
    for(;;) {
        if(map_page(pagetable, a, pa, perm) != 0)
    80001698:	fbc42783          	lw	a5,-68(s0)
    8000169c:	86be                	mv	a3,a5
    8000169e:	fc843603          	ld	a2,-56(s0)
    800016a2:	fe843583          	ld	a1,-24(s0)
    800016a6:	fd843503          	ld	a0,-40(s0)
    800016aa:	00000097          	auipc	ra,0x0
    800016ae:	ef4080e7          	jalr	-268(ra) # 8000159e <map_page>
    800016b2:	87aa                	mv	a5,a0
    800016b4:	c399                	beqz	a5,800016ba <map_region+0x6c>
            return -1;  // 某页映射失败，整个区域映射失败
    800016b6:	57fd                	li	a5,-1
    800016b8:	a035                	j	800016e4 <map_region+0x96>
        if(a == last)
    800016ba:	fe843703          	ld	a4,-24(s0)
    800016be:	fe043783          	ld	a5,-32(s0)
    800016c2:	00f70f63          	beq	a4,a5,800016e0 <map_region+0x92>
            break;  // 映射完最后一页，结束
        a += PGSIZE;   // 移动到下一个虚拟页面
    800016c6:	fe843703          	ld	a4,-24(s0)
    800016ca:	6785                	lui	a5,0x1
    800016cc:	97ba                	add	a5,a5,a4
    800016ce:	fef43423          	sd	a5,-24(s0)
        pa += PGSIZE;  // 移动到下一个物理页面
    800016d2:	fc843703          	ld	a4,-56(s0)
    800016d6:	6785                	lui	a5,0x1
    800016d8:	97ba                	add	a5,a5,a4
    800016da:	fcf43423          	sd	a5,-56(s0)
        if(map_page(pagetable, a, pa, perm) != 0)
    800016de:	bf6d                	j	80001698 <map_region+0x4a>
            break;  // 映射完最后一页，结束
    800016e0:	0001                	nop
    }
    return 0;
    800016e2:	4781                	li	a5,0
}
    800016e4:	853e                	mv	a0,a5
    800016e6:	60a6                	ld	ra,72(sp)
    800016e8:	6406                	ld	s0,64(sp)
    800016ea:	6161                	add	sp,sp,80
    800016ec:	8082                	ret

00000000800016ee <kvminit>:

// 初始化内核页表 - 建立内核虚拟内存布局
// 作用：创建内核运行所需的虚拟地址映射
void kvminit(void) {
    800016ee:	1141                	add	sp,sp,-16
    800016f0:	e406                	sd	ra,8(sp)
    800016f2:	e022                	sd	s0,0(sp)
    800016f4:	0800                	add	s0,sp,16
    // 创建内核根页表
    kernel_pagetable = create_pagetable();
    800016f6:	00000097          	auipc	ra,0x0
    800016fa:	c40080e7          	jalr	-960(ra) # 80001336 <create_pagetable>
    800016fe:	872a                	mv	a4,a0
    80001700:	0000a797          	auipc	a5,0xa
    80001704:	90878793          	add	a5,a5,-1784 # 8000b008 <kernel_pagetable>
    80001708:	e398                	sd	a4,0(a5)
    if(kernel_pagetable == 0)
    8000170a:	0000a797          	auipc	a5,0xa
    8000170e:	8fe78793          	add	a5,a5,-1794 # 8000b008 <kernel_pagetable>
    80001712:	639c                	ld	a5,0(a5)
    80001714:	eb89                	bnez	a5,80001726 <kvminit+0x38>
        panic("kvminit: create_pagetable failed");
    80001716:	00002517          	auipc	a0,0x2
    8000171a:	fba50513          	add	a0,a0,-70 # 800036d0 <etext+0x6d0>
    8000171e:	fffff097          	auipc	ra,0xfffff
    80001722:	694080e7          	jalr	1684(ra) # 80000db2 <panic>
    
    printf("Setting up kernel page table...\n");
    80001726:	00002517          	auipc	a0,0x2
    8000172a:	fd250513          	add	a0,a0,-46 # 800036f8 <etext+0x6f8>
    8000172e:	fffff097          	auipc	ra,0xfffff
    80001732:	2de080e7          	jalr	734(ra) # 80000a0c <printf>
    
    // 映射内核代码段 (只读+可执行)
    // 权限设计：代码段只能读取和执行，不能写入，防止代码被意外修改
    // 地址范围：从KERNBASE到etext符号(链接脚本定义的代码段结束)
    printf("Mapping kernel text: %p - %p\n", (void*)KERNBASE, etext);
    80001736:	00002617          	auipc	a2,0x2
    8000173a:	8ca60613          	add	a2,a2,-1846 # 80003000 <etext>
    8000173e:	4785                	li	a5,1
    80001740:	01f79593          	sll	a1,a5,0x1f
    80001744:	00002517          	auipc	a0,0x2
    80001748:	fdc50513          	add	a0,a0,-36 # 80003720 <etext+0x720>
    8000174c:	fffff097          	auipc	ra,0xfffff
    80001750:	2c0080e7          	jalr	704(ra) # 80000a0c <printf>
    if(map_region(kernel_pagetable, KERNBASE, KERNBASE, 
    80001754:	0000a797          	auipc	a5,0xa
    80001758:	8b478793          	add	a5,a5,-1868 # 8000b008 <kernel_pagetable>
    8000175c:	6388                	ld	a0,0(a5)
                  (uint64)etext - KERNBASE, PTE_R | PTE_X) != 0)
    8000175e:	00002717          	auipc	a4,0x2
    80001762:	8a270713          	add	a4,a4,-1886 # 80003000 <etext>
    if(map_region(kernel_pagetable, KERNBASE, KERNBASE, 
    80001766:	800007b7          	lui	a5,0x80000
    8000176a:	97ba                	add	a5,a5,a4
    8000176c:	4729                	li	a4,10
    8000176e:	86be                	mv	a3,a5
    80001770:	4785                	li	a5,1
    80001772:	01f79613          	sll	a2,a5,0x1f
    80001776:	4785                	li	a5,1
    80001778:	01f79593          	sll	a1,a5,0x1f
    8000177c:	00000097          	auipc	ra,0x0
    80001780:	ed2080e7          	jalr	-302(ra) # 8000164e <map_region>
    80001784:	87aa                	mv	a5,a0
    80001786:	cb89                	beqz	a5,80001798 <kvminit+0xaa>
        panic("kvminit: map kernel text failed");
    80001788:	00002517          	auipc	a0,0x2
    8000178c:	fb850513          	add	a0,a0,-72 # 80003740 <etext+0x740>
    80001790:	fffff097          	auipc	ra,0xfffff
    80001794:	622080e7          	jalr	1570(ra) # 80000db2 <panic>
    
    // 映射内核数据段 (读写)
    // 权限设计：数据段需要读写权限，用于全局变量、堆栈等
    // 地址范围：从etext到PHYSTOP，包含数据段、BSS段、堆等
    printf("Mapping kernel data: %p - %p\n", etext, (void*)PHYSTOP);
    80001798:	47c5                	li	a5,17
    8000179a:	01b79613          	sll	a2,a5,0x1b
    8000179e:	00002597          	auipc	a1,0x2
    800017a2:	86258593          	add	a1,a1,-1950 # 80003000 <etext>
    800017a6:	00002517          	auipc	a0,0x2
    800017aa:	fba50513          	add	a0,a0,-70 # 80003760 <etext+0x760>
    800017ae:	fffff097          	auipc	ra,0xfffff
    800017b2:	25e080e7          	jalr	606(ra) # 80000a0c <printf>
    if(map_region(kernel_pagetable, (uint64)etext, (uint64)etext,
    800017b6:	0000a797          	auipc	a5,0xa
    800017ba:	85278793          	add	a5,a5,-1966 # 8000b008 <kernel_pagetable>
    800017be:	6388                	ld	a0,0(a5)
    800017c0:	00002597          	auipc	a1,0x2
    800017c4:	84058593          	add	a1,a1,-1984 # 80003000 <etext>
    800017c8:	00002617          	auipc	a2,0x2
    800017cc:	83860613          	add	a2,a2,-1992 # 80003000 <etext>
                  PHYSTOP - (uint64)etext, PTE_R | PTE_W) != 0)
    800017d0:	00002797          	auipc	a5,0x2
    800017d4:	83078793          	add	a5,a5,-2000 # 80003000 <etext>
    if(map_region(kernel_pagetable, (uint64)etext, (uint64)etext,
    800017d8:	4745                	li	a4,17
    800017da:	076e                	sll	a4,a4,0x1b
    800017dc:	40f707b3          	sub	a5,a4,a5
    800017e0:	4719                	li	a4,6
    800017e2:	86be                	mv	a3,a5
    800017e4:	00000097          	auipc	ra,0x0
    800017e8:	e6a080e7          	jalr	-406(ra) # 8000164e <map_region>
    800017ec:	87aa                	mv	a5,a0
    800017ee:	cb89                	beqz	a5,80001800 <kvminit+0x112>
        panic("kvminit: map kernel data failed");
    800017f0:	00002517          	auipc	a0,0x2
    800017f4:	f9050513          	add	a0,a0,-112 # 80003780 <etext+0x780>
    800017f8:	fffff097          	auipc	ra,0xfffff
    800017fc:	5ba080e7          	jalr	1466(ra) # 80000db2 <panic>
    // 映射UART设备 (读写，非可执行)
    // 设备映射特点：
    // 1. 读写权限：需要访问设备寄存器
    // 2. 非可执行：防止意外执行设备内存内容
    // 3. 内核专用：没有PTE_U位，用户态无法访问
    printf("Mapping UART: %p\n", (void*)UART0);
    80001800:	100005b7          	lui	a1,0x10000
    80001804:	00002517          	auipc	a0,0x2
    80001808:	f9c50513          	add	a0,a0,-100 # 800037a0 <etext+0x7a0>
    8000180c:	fffff097          	auipc	ra,0xfffff
    80001810:	200080e7          	jalr	512(ra) # 80000a0c <printf>
    if(map_region(kernel_pagetable, UART0, UART0, PGSIZE, PTE_R | PTE_W) != 0)
    80001814:	00009797          	auipc	a5,0x9
    80001818:	7f478793          	add	a5,a5,2036 # 8000b008 <kernel_pagetable>
    8000181c:	639c                	ld	a5,0(a5)
    8000181e:	4719                	li	a4,6
    80001820:	6685                	lui	a3,0x1
    80001822:	10000637          	lui	a2,0x10000
    80001826:	100005b7          	lui	a1,0x10000
    8000182a:	853e                	mv	a0,a5
    8000182c:	00000097          	auipc	ra,0x0
    80001830:	e22080e7          	jalr	-478(ra) # 8000164e <map_region>
    80001834:	87aa                	mv	a5,a0
    80001836:	cb89                	beqz	a5,80001848 <kvminit+0x15a>
        panic("kvminit: map UART failed");
    80001838:	00002517          	auipc	a0,0x2
    8000183c:	f8050513          	add	a0,a0,-128 # 800037b8 <etext+0x7b8>
    80001840:	fffff097          	auipc	ra,0xfffff
    80001844:	572080e7          	jalr	1394(ra) # 80000db2 <panic>
    
    printf("Kernel page table setup complete\n");
    80001848:	00002517          	auipc	a0,0x2
    8000184c:	f9050513          	add	a0,a0,-112 # 800037d8 <etext+0x7d8>
    80001850:	fffff097          	auipc	ra,0xfffff
    80001854:	1bc080e7          	jalr	444(ra) # 80000a0c <printf>
}
    80001858:	0001                	nop
    8000185a:	60a2                	ld	ra,8(sp)
    8000185c:	6402                	ld	s0,0(sp)
    8000185e:	0141                	add	sp,sp,16
    80001860:	8082                	ret

0000000080001862 <kvminithart>:

// 激活内核页表 - 启用虚拟内存
// 作用：切换CPU从物理地址模式到虚拟地址模式
void kvminithart(void) {
    80001862:	1141                	add	sp,sp,-16
    80001864:	e406                	sd	ra,8(sp)
    80001866:	e022                	sd	s0,0(sp)
    80001868:	0800                	add	s0,sp,16
    // 写入satp寄存器激活页表
    // MAKE_SATP：构造satp寄存器值，包含模式(Sv39)和根页表物理地址
    // satp格式：MODE[63:60] | ASID[59:44] | PPN[43:0]
    // MODE=8表示Sv39模式，PPN是根页表的物理页号
    w_satp(MAKE_SATP(kernel_pagetable));
    8000186a:	00009797          	auipc	a5,0x9
    8000186e:	79e78793          	add	a5,a5,1950 # 8000b008 <kernel_pagetable>
    80001872:	639c                	ld	a5,0(a5)
    80001874:	00c7d713          	srl	a4,a5,0xc
    80001878:	57fd                	li	a5,-1
    8000187a:	17fe                	sll	a5,a5,0x3f
    8000187c:	8fd9                	or	a5,a5,a4
    8000187e:	853e                	mv	a0,a5
    80001880:	00000097          	auipc	ra,0x0
    80001884:	a8a080e7          	jalr	-1398(ra) # 8000130a <w_satp>
    
    // 刷新TLB - 清除旧的地址翻译缓存
    // 原因：启用新页表后，旧的TLB条目无效，必须清除
    // sfence.vma：RISC-V指令，刷新所有TLB条目
    sfence_vma();
    80001888:	00000097          	auipc	ra,0x0
    8000188c:	a9c080e7          	jalr	-1380(ra) # 80001324 <sfence_vma>
    
    printf("Virtual memory enabled!\n");
    80001890:	00002517          	auipc	a0,0x2
    80001894:	f7050513          	add	a0,a0,-144 # 80003800 <etext+0x800>
    80001898:	fffff097          	auipc	ra,0xfffff
    8000189c:	174080e7          	jalr	372(ra) # 80000a0c <printf>
}
    800018a0:	0001                	nop
    800018a2:	60a2                	ld	ra,8(sp)
    800018a4:	6402                	ld	s0,0(sp)
    800018a6:	0141                	add	sp,sp,16
    800018a8:	8082                	ret

00000000800018aa <dump_pagetable>:

// 调试用：打印页表内容
// 参数：pagetable-要打印的页表，level-当前层级(用于递归)
// 用途：调试页表结构，查看映射关系
void dump_pagetable(pagetable_t pagetable, int level) {
    800018aa:	7179                	add	sp,sp,-48
    800018ac:	f406                	sd	ra,40(sp)
    800018ae:	f022                	sd	s0,32(sp)
    800018b0:	1800                	add	s0,sp,48
    800018b2:	fca43c23          	sd	a0,-40(s0)
    800018b6:	87ae                	mv	a5,a1
    800018b8:	fcf42a23          	sw	a5,-44(s0)
    if(level > 2) return;  // 防止无限递归，Sv39最多3级
    800018bc:	fd442783          	lw	a5,-44(s0)
    800018c0:	0007871b          	sext.w	a4,a5
    800018c4:	4789                	li	a5,2
    800018c6:	10e7c163          	blt	a5,a4,800019c8 <dump_pagetable+0x11e>
    
    printf("Page table at level %d:\n", level);
    800018ca:	fd442783          	lw	a5,-44(s0)
    800018ce:	85be                	mv	a1,a5
    800018d0:	00002517          	auipc	a0,0x2
    800018d4:	f5050513          	add	a0,a0,-176 # 80003820 <etext+0x820>
    800018d8:	fffff097          	auipc	ra,0xfffff
    800018dc:	134080e7          	jalr	308(ra) # 80000a0c <printf>
    int count = 0;
    800018e0:	fe042623          	sw	zero,-20(s0)
    // 遍历当前页表的所有512个条目
    for(int i = 0; i < 512; i++) {
    800018e4:	fe042423          	sw	zero,-24(s0)
    800018e8:	a0f9                	j	800019b6 <dump_pagetable+0x10c>
        pte_t pte = pagetable[i];
    800018ea:	fe842783          	lw	a5,-24(s0)
    800018ee:	078e                	sll	a5,a5,0x3
    800018f0:	fd843703          	ld	a4,-40(s0)
    800018f4:	97ba                	add	a5,a5,a4
    800018f6:	639c                	ld	a5,0(a5)
    800018f8:	fef43023          	sd	a5,-32(s0)
        if(pte & PTE_V) {  // 只显示有效的页表项
    800018fc:	fe043783          	ld	a5,-32(s0)
    80001900:	8b85                	and	a5,a5,1
    80001902:	c7cd                	beqz	a5,800019ac <dump_pagetable+0x102>
            printf("  [%d]: %p", i, (void*)pte);  // 显示索引和完整PTE值
    80001904:	fe043703          	ld	a4,-32(s0)
    80001908:	fe842783          	lw	a5,-24(s0)
    8000190c:	863a                	mv	a2,a4
    8000190e:	85be                	mv	a1,a5
    80001910:	00002517          	auipc	a0,0x2
    80001914:	f3050513          	add	a0,a0,-208 # 80003840 <etext+0x840>
    80001918:	fffff097          	auipc	ra,0xfffff
    8000191c:	0f4080e7          	jalr	244(ra) # 80000a0c <printf>
            // 解析并显示权限位
            if(pte & PTE_R) printf(" R");  // 可读
    80001920:	fe043783          	ld	a5,-32(s0)
    80001924:	8b89                	and	a5,a5,2
    80001926:	cb89                	beqz	a5,80001938 <dump_pagetable+0x8e>
    80001928:	00002517          	auipc	a0,0x2
    8000192c:	f2850513          	add	a0,a0,-216 # 80003850 <etext+0x850>
    80001930:	fffff097          	auipc	ra,0xfffff
    80001934:	0dc080e7          	jalr	220(ra) # 80000a0c <printf>
            if(pte & PTE_W) printf(" W");  // 可写
    80001938:	fe043783          	ld	a5,-32(s0)
    8000193c:	8b91                	and	a5,a5,4
    8000193e:	cb89                	beqz	a5,80001950 <dump_pagetable+0xa6>
    80001940:	00002517          	auipc	a0,0x2
    80001944:	f1850513          	add	a0,a0,-232 # 80003858 <etext+0x858>
    80001948:	fffff097          	auipc	ra,0xfffff
    8000194c:	0c4080e7          	jalr	196(ra) # 80000a0c <printf>
            if(pte & PTE_X) printf(" X");  // 可执行
    80001950:	fe043783          	ld	a5,-32(s0)
    80001954:	8ba1                	and	a5,a5,8
    80001956:	cb89                	beqz	a5,80001968 <dump_pagetable+0xbe>
    80001958:	00002517          	auipc	a0,0x2
    8000195c:	f0850513          	add	a0,a0,-248 # 80003860 <etext+0x860>
    80001960:	fffff097          	auipc	ra,0xfffff
    80001964:	0ac080e7          	jalr	172(ra) # 80000a0c <printf>
            printf(" -> PA %p\n", (void*)PTE_PA(pte));  // 显示指向的物理地址
    80001968:	fe043783          	ld	a5,-32(s0)
    8000196c:	83a9                	srl	a5,a5,0xa
    8000196e:	07b2                	sll	a5,a5,0xc
    80001970:	85be                	mv	a1,a5
    80001972:	00002517          	auipc	a0,0x2
    80001976:	ef650513          	add	a0,a0,-266 # 80003868 <etext+0x868>
    8000197a:	fffff097          	auipc	ra,0xfffff
    8000197e:	092080e7          	jalr	146(ra) # 80000a0c <printf>
            count++;
    80001982:	fec42783          	lw	a5,-20(s0)
    80001986:	2785                	addw	a5,a5,1
    80001988:	fef42623          	sw	a5,-20(s0)
            if(count > 10) {  // 限制输出数量，避免屏幕刷屏
    8000198c:	fec42783          	lw	a5,-20(s0)
    80001990:	0007871b          	sext.w	a4,a5
    80001994:	47a9                	li	a5,10
    80001996:	00e7db63          	bge	a5,a4,800019ac <dump_pagetable+0x102>
                printf("  ... (more entries)\n");
    8000199a:	00002517          	auipc	a0,0x2
    8000199e:	ede50513          	add	a0,a0,-290 # 80003878 <etext+0x878>
    800019a2:	fffff097          	auipc	ra,0xfffff
    800019a6:	06a080e7          	jalr	106(ra) # 80000a0c <printf>
                break;
    800019aa:	a005                	j	800019ca <dump_pagetable+0x120>
    for(int i = 0; i < 512; i++) {
    800019ac:	fe842783          	lw	a5,-24(s0)
    800019b0:	2785                	addw	a5,a5,1
    800019b2:	fef42423          	sw	a5,-24(s0)
    800019b6:	fe842783          	lw	a5,-24(s0)
    800019ba:	0007871b          	sext.w	a4,a5
    800019be:	1ff00793          	li	a5,511
    800019c2:	f2e7d4e3          	bge	a5,a4,800018ea <dump_pagetable+0x40>
    800019c6:	a011                	j	800019ca <dump_pagetable+0x120>
    if(level > 2) return;  // 防止无限递归，Sv39最多3级
    800019c8:	0001                	nop
            }
        }
    }
}
    800019ca:	70a2                	ld	ra,40(sp)
    800019cc:	7402                	ld	s0,32(sp)
    800019ce:	6145                	add	sp,sp,48
    800019d0:	8082                	ret

00000000800019d2 <check_page_permission>:

// 简单的软件权限检查
int check_page_permission(uint64 addr, int access_type) {
    800019d2:	7179                	add	sp,sp,-48
    800019d4:	f406                	sd	ra,40(sp)
    800019d6:	f022                	sd	s0,32(sp)
    800019d8:	1800                	add	s0,sp,48
    800019da:	fca43c23          	sd	a0,-40(s0)
    800019de:	87ae                	mv	a5,a1
    800019e0:	fcf42a23          	sw	a5,-44(s0)
    // 查找页表项
    pte_t *pte = walk_lookup(kernel_pagetable, addr);
    800019e4:	00009797          	auipc	a5,0x9
    800019e8:	62478793          	add	a5,a5,1572 # 8000b008 <kernel_pagetable>
    800019ec:	639c                	ld	a5,0(a5)
    800019ee:	fd843583          	ld	a1,-40(s0)
    800019f2:	853e                	mv	a0,a5
    800019f4:	00000097          	auipc	ra,0x0
    800019f8:	a26080e7          	jalr	-1498(ra) # 8000141a <walk_lookup>
    800019fc:	fea43423          	sd	a0,-24(s0)
    
    if(pte == 0 || !(*pte & PTE_V)) {
    80001a00:	fe843783          	ld	a5,-24(s0)
    80001a04:	c791                	beqz	a5,80001a10 <check_page_permission+0x3e>
    80001a06:	fe843783          	ld	a5,-24(s0)
    80001a0a:	639c                	ld	a5,0(a5)
    80001a0c:	8b85                	and	a5,a5,1
    80001a0e:	ef91                	bnez	a5,80001a2a <check_page_permission+0x58>
        printf("Permission check: Address %p not mapped\n", (void*)addr);
    80001a10:	fd843783          	ld	a5,-40(s0)
    80001a14:	85be                	mv	a1,a5
    80001a16:	00002517          	auipc	a0,0x2
    80001a1a:	e7a50513          	add	a0,a0,-390 # 80003890 <etext+0x890>
    80001a1e:	fffff097          	auipc	ra,0xfffff
    80001a22:	fee080e7          	jalr	-18(ra) # 80000a0c <printf>
        return 0;  // 地址未映射
    80001a26:	4781                	li	a5,0
    80001a28:	a079                	j	80001ab6 <check_page_permission+0xe4>
    }
    
    // 检查权限
    if((access_type & ACCESS_READ) && !(*pte & PTE_R)) {
    80001a2a:	fd442783          	lw	a5,-44(s0)
    80001a2e:	8b85                	and	a5,a5,1
    80001a30:	2781                	sext.w	a5,a5
    80001a32:	c39d                	beqz	a5,80001a58 <check_page_permission+0x86>
    80001a34:	fe843783          	ld	a5,-24(s0)
    80001a38:	639c                	ld	a5,0(a5)
    80001a3a:	8b89                	and	a5,a5,2
    80001a3c:	ef91                	bnez	a5,80001a58 <check_page_permission+0x86>
        printf("Permission check: No read permission for %p\n", (void*)addr);
    80001a3e:	fd843783          	ld	a5,-40(s0)
    80001a42:	85be                	mv	a1,a5
    80001a44:	00002517          	auipc	a0,0x2
    80001a48:	e7c50513          	add	a0,a0,-388 # 800038c0 <etext+0x8c0>
    80001a4c:	fffff097          	auipc	ra,0xfffff
    80001a50:	fc0080e7          	jalr	-64(ra) # 80000a0c <printf>
        return 0;
    80001a54:	4781                	li	a5,0
    80001a56:	a085                	j	80001ab6 <check_page_permission+0xe4>
    }
    
    if((access_type & ACCESS_WRITE) && !(*pte & PTE_W)) {
    80001a58:	fd442783          	lw	a5,-44(s0)
    80001a5c:	8b89                	and	a5,a5,2
    80001a5e:	2781                	sext.w	a5,a5
    80001a60:	c39d                	beqz	a5,80001a86 <check_page_permission+0xb4>
    80001a62:	fe843783          	ld	a5,-24(s0)
    80001a66:	639c                	ld	a5,0(a5)
    80001a68:	8b91                	and	a5,a5,4
    80001a6a:	ef91                	bnez	a5,80001a86 <check_page_permission+0xb4>
        printf("Permission check: No write permission for %p\n", (void*)addr);
    80001a6c:	fd843783          	ld	a5,-40(s0)
    80001a70:	85be                	mv	a1,a5
    80001a72:	00002517          	auipc	a0,0x2
    80001a76:	e7e50513          	add	a0,a0,-386 # 800038f0 <etext+0x8f0>
    80001a7a:	fffff097          	auipc	ra,0xfffff
    80001a7e:	f92080e7          	jalr	-110(ra) # 80000a0c <printf>
        return 0;
    80001a82:	4781                	li	a5,0
    80001a84:	a80d                	j	80001ab6 <check_page_permission+0xe4>
    }
    
    if((access_type & ACCESS_EXEC) && !(*pte & PTE_X)) {
    80001a86:	fd442783          	lw	a5,-44(s0)
    80001a8a:	8b91                	and	a5,a5,4
    80001a8c:	2781                	sext.w	a5,a5
    80001a8e:	c39d                	beqz	a5,80001ab4 <check_page_permission+0xe2>
    80001a90:	fe843783          	ld	a5,-24(s0)
    80001a94:	639c                	ld	a5,0(a5)
    80001a96:	8ba1                	and	a5,a5,8
    80001a98:	ef91                	bnez	a5,80001ab4 <check_page_permission+0xe2>
        printf("Permission check: No execute permission for %p\n", (void*)addr);
    80001a9a:	fd843783          	ld	a5,-40(s0)
    80001a9e:	85be                	mv	a1,a5
    80001aa0:	00002517          	auipc	a0,0x2
    80001aa4:	e8050513          	add	a0,a0,-384 # 80003920 <etext+0x920>
    80001aa8:	fffff097          	auipc	ra,0xfffff
    80001aac:	f64080e7          	jalr	-156(ra) # 80000a0c <printf>
        return 0;
    80001ab0:	4781                	li	a5,0
    80001ab2:	a011                	j	80001ab6 <check_page_permission+0xe4>
    }
    
    return 1;  // 权限检查通过
    80001ab4:	4785                	li	a5,1
    80001ab6:	853e                	mv	a0,a5
    80001ab8:	70a2                	ld	ra,40(sp)
    80001aba:	7402                	ld	s0,32(sp)
    80001abc:	6145                	add	sp,sp,48
    80001abe:	8082                	ret

0000000080001ac0 <test_multilevel_pagetable>:
#include "defs.h"
#include "riscv.h"

// ==================== 多级页表映射测试 ====================
// 目的：验证Sv39三级页表结构在不同地址范围下的正确性
void test_multilevel_pagetable(void) {
    80001ac0:	711d                	add	sp,sp,-96
    80001ac2:	ec86                	sd	ra,88(sp)
    80001ac4:	e8a2                	sd	s0,80(sp)
    80001ac6:	1080                	add	s0,sp,96
    printf("=== Testing Multi-level Page Table ===\n");
    80001ac8:	00002517          	auipc	a0,0x2
    80001acc:	e8850513          	add	a0,a0,-376 # 80003950 <etext+0x950>
    80001ad0:	fffff097          	auipc	ra,0xfffff
    80001ad4:	f3c080e7          	jalr	-196(ra) # 80000a0c <printf>
    
    // 创建测试专用页表，与内核页表隔离
    pagetable_t pt = create_pagetable();
    80001ad8:	00000097          	auipc	ra,0x0
    80001adc:	85e080e7          	jalr	-1954(ra) # 80001336 <create_pagetable>
    80001ae0:	fea43023          	sd	a0,-32(s0)
    if(pt == 0) {
    80001ae4:	fe043783          	ld	a5,-32(s0)
    80001ae8:	eb91                	bnez	a5,80001afc <test_multilevel_pagetable+0x3c>
        printf("ERROR: create_pagetable failed\n");
    80001aea:	00002517          	auipc	a0,0x2
    80001aee:	e8e50513          	add	a0,a0,-370 # 80003978 <etext+0x978>
    80001af2:	fffff097          	auipc	ra,0xfffff
    80001af6:	f1a080e7          	jalr	-230(ra) # 80000a0c <printf>
    80001afa:	aa59                	j	80001c90 <test_multilevel_pagetable+0x1d0>
        return;
    }
    
    // 精心设计的测试地址数组 - 覆盖不同的页表层级需求
    uint64 test_vas[] = {
    80001afc:	00002797          	auipc	a5,0x2
    80001b00:	fc478793          	add	a5,a5,-60 # 80003ac0 <etext+0xac0>
    80001b04:	6390                	ld	a2,0(a5)
    80001b06:	6794                	ld	a3,8(a5)
    80001b08:	6b98                	ld	a4,16(a5)
    80001b0a:	6f9c                	ld	a5,24(a5)
    80001b0c:	fac43423          	sd	a2,-88(s0)
    80001b10:	fad43823          	sd	a3,-80(s0)
    80001b14:	fae43c23          	sd	a4,-72(s0)
    80001b18:	fcf43023          	sd	a5,-64(s0)
    // - 0x1000: VPN[2]=0, VPN[1]=0, VPN[0]=1 - 最简单情况
    // - 0x200000: VPN[2]=0, VPN[1]=1, VPN[0]=0 - 测试二级索引
    // - 0x40000000: VPN[2]=1, VPN[1]=0, VPN[0]=0 - 测试一级索引
    // - 0x7000000000: 需要所有三级页表 - 完整路径测试
    
    for(int i = 0; i < 4; i++) {
    80001b1c:	fe042623          	sw	zero,-20(s0)
    80001b20:	a299                	j	80001c66 <test_multilevel_pagetable+0x1a6>
        uint64 va = test_vas[i];
    80001b22:	fec42783          	lw	a5,-20(s0)
    80001b26:	078e                	sll	a5,a5,0x3
    80001b28:	17c1                	add	a5,a5,-16
    80001b2a:	97a2                	add	a5,a5,s0
    80001b2c:	fb87b783          	ld	a5,-72(a5)
    80001b30:	fcf43c23          	sd	a5,-40(s0)
        
        // Sv39地址空间边界检查 - 防止超出39位限制
        // 这个检查验证了我们的地址范围验证机制
        if(va >= (1L << 39)) {
    80001b34:	fd843703          	ld	a4,-40(s0)
    80001b38:	57fd                	li	a5,-1
    80001b3a:	83e5                	srl	a5,a5,0x19
    80001b3c:	02e7f163          	bgeu	a5,a4,80001b5e <test_multilevel_pagetable+0x9e>
            printf("Test %d: VA %p exceeds Sv39 limit, skipping\n", i, (void*)va);
    80001b40:	fd843703          	ld	a4,-40(s0)
    80001b44:	fec42783          	lw	a5,-20(s0)
    80001b48:	863a                	mv	a2,a4
    80001b4a:	85be                	mv	a1,a5
    80001b4c:	00002517          	auipc	a0,0x2
    80001b50:	e4c50513          	add	a0,a0,-436 # 80003998 <etext+0x998>
    80001b54:	fffff097          	auipc	ra,0xfffff
    80001b58:	eb8080e7          	jalr	-328(ra) # 80000a0c <printf>
            continue;
    80001b5c:	a201                	j	80001c5c <test_multilevel_pagetable+0x19c>
        }
        
        // 为每个测试分配一个物理页面
        uint64 pa = (uint64)alloc_page();
    80001b5e:	fffff097          	auipc	ra,0xfffff
    80001b62:	542080e7          	jalr	1346(ra) # 800010a0 <alloc_page>
    80001b66:	87aa                	mv	a5,a0
    80001b68:	fcf43823          	sd	a5,-48(s0)
        if(pa == 0) {
    80001b6c:	fd043783          	ld	a5,-48(s0)
    80001b70:	ef89                	bnez	a5,80001b8a <test_multilevel_pagetable+0xca>
            printf("ERROR: alloc_page failed for test %d\n", i);
    80001b72:	fec42783          	lw	a5,-20(s0)
    80001b76:	85be                	mv	a1,a5
    80001b78:	00002517          	auipc	a0,0x2
    80001b7c:	e5050513          	add	a0,a0,-432 # 800039c8 <etext+0x9c8>
    80001b80:	fffff097          	auipc	ra,0xfffff
    80001b84:	e8c080e7          	jalr	-372(ra) # 80000a0c <printf>
            continue;
    80001b88:	a8d1                	j	80001c5c <test_multilevel_pagetable+0x19c>
        }
        
        printf("Test %d: mapping VA %p to PA %p\n", i, (void*)va, (void*)pa);
    80001b8a:	fd843703          	ld	a4,-40(s0)
    80001b8e:	fd043683          	ld	a3,-48(s0)
    80001b92:	fec42783          	lw	a5,-20(s0)
    80001b96:	863a                	mv	a2,a4
    80001b98:	85be                	mv	a1,a5
    80001b9a:	00002517          	auipc	a0,0x2
    80001b9e:	e5650513          	add	a0,a0,-426 # 800039f0 <etext+0x9f0>
    80001ba2:	fffff097          	auipc	ra,0xfffff
    80001ba6:	e6a080e7          	jalr	-406(ra) # 80000a0c <printf>
        
        // 建立映射：设置读写执行权限进行全面测试
        if(map_page(pt, va, pa, PTE_R | PTE_W | PTE_X) != 0) {
    80001baa:	46b9                	li	a3,14
    80001bac:	fd043603          	ld	a2,-48(s0)
    80001bb0:	fd843583          	ld	a1,-40(s0)
    80001bb4:	fe043503          	ld	a0,-32(s0)
    80001bb8:	00000097          	auipc	ra,0x0
    80001bbc:	9e6080e7          	jalr	-1562(ra) # 8000159e <map_page>
    80001bc0:	87aa                	mv	a5,a0
    80001bc2:	c785                	beqz	a5,80001bea <test_multilevel_pagetable+0x12a>
            printf("ERROR: map_page failed for test %d\n", i);
    80001bc4:	fec42783          	lw	a5,-20(s0)
    80001bc8:	85be                	mv	a1,a5
    80001bca:	00002517          	auipc	a0,0x2
    80001bce:	e4e50513          	add	a0,a0,-434 # 80003a18 <etext+0xa18>
    80001bd2:	fffff097          	auipc	ra,0xfffff
    80001bd6:	e3a080e7          	jalr	-454(ra) # 80000a0c <printf>
            free_page((void*)pa);
    80001bda:	fd043783          	ld	a5,-48(s0)
    80001bde:	853e                	mv	a0,a5
    80001be0:	fffff097          	auipc	ra,0xfffff
    80001be4:	522080e7          	jalr	1314(ra) # 80001102 <free_page>
            continue;
    80001be8:	a895                	j	80001c5c <test_multilevel_pagetable+0x19c>
        }
        
        // 关键验证步骤：确保映射建立正确
        // 这里测试了页表遍历和地址转换的完整链路
        pte_t *pte = walk_lookup(pt, va);
    80001bea:	fd843583          	ld	a1,-40(s0)
    80001bee:	fe043503          	ld	a0,-32(s0)
    80001bf2:	00000097          	auipc	ra,0x0
    80001bf6:	828080e7          	jalr	-2008(ra) # 8000141a <walk_lookup>
    80001bfa:	fca43423          	sd	a0,-56(s0)
        if(pte == 0 || !(*pte & PTE_V) || PTE_PA(*pte) != pa) {
    80001bfe:	fc843783          	ld	a5,-56(s0)
    80001c02:	cf99                	beqz	a5,80001c20 <test_multilevel_pagetable+0x160>
    80001c04:	fc843783          	ld	a5,-56(s0)
    80001c08:	639c                	ld	a5,0(a5)
    80001c0a:	8b85                	and	a5,a5,1
    80001c0c:	cb91                	beqz	a5,80001c20 <test_multilevel_pagetable+0x160>
    80001c0e:	fc843783          	ld	a5,-56(s0)
    80001c12:	639c                	ld	a5,0(a5)
    80001c14:	83a9                	srl	a5,a5,0xa
    80001c16:	07b2                	sll	a5,a5,0xc
    80001c18:	fd043703          	ld	a4,-48(s0)
    80001c1c:	00f70e63          	beq	a4,a5,80001c38 <test_multilevel_pagetable+0x178>
            printf("ERROR: mapping verification failed for test %d\n", i);
    80001c20:	fec42783          	lw	a5,-20(s0)
    80001c24:	85be                	mv	a1,a5
    80001c26:	00002517          	auipc	a0,0x2
    80001c2a:	e1a50513          	add	a0,a0,-486 # 80003a40 <etext+0xa40>
    80001c2e:	fffff097          	auipc	ra,0xfffff
    80001c32:	dde080e7          	jalr	-546(ra) # 80000a0c <printf>
    80001c36:	a821                	j	80001c4e <test_multilevel_pagetable+0x18e>
        } else {
            printf("Test %d: mapping verification PASSED\n", i);
    80001c38:	fec42783          	lw	a5,-20(s0)
    80001c3c:	85be                	mv	a1,a5
    80001c3e:	00002517          	auipc	a0,0x2
    80001c42:	e3250513          	add	a0,a0,-462 # 80003a70 <etext+0xa70>
    80001c46:	fffff097          	auipc	ra,0xfffff
    80001c4a:	dc6080e7          	jalr	-570(ra) # 80000a0c <printf>
        }
        
        // 清理：释放测试用的物理页面
        free_page((void*)pa);
    80001c4e:	fd043783          	ld	a5,-48(s0)
    80001c52:	853e                	mv	a0,a5
    80001c54:	fffff097          	auipc	ra,0xfffff
    80001c58:	4ae080e7          	jalr	1198(ra) # 80001102 <free_page>
    for(int i = 0; i < 4; i++) {
    80001c5c:	fec42783          	lw	a5,-20(s0)
    80001c60:	2785                	addw	a5,a5,1
    80001c62:	fef42623          	sw	a5,-20(s0)
    80001c66:	fec42783          	lw	a5,-20(s0)
    80001c6a:	0007871b          	sext.w	a4,a5
    80001c6e:	478d                	li	a5,3
    80001c70:	eae7d9e3          	bge	a5,a4,80001b22 <test_multilevel_pagetable+0x62>
    }
    
    // 清理：销毁测试页表，验证资源回收
    destroy_pagetable(pt);
    80001c74:	fe043503          	ld	a0,-32(s0)
    80001c78:	fffff097          	auipc	ra,0xfffff
    80001c7c:	778080e7          	jalr	1912(ra) # 800013f0 <destroy_pagetable>
    printf("Multi-level page table test completed\n\n");
    80001c80:	00002517          	auipc	a0,0x2
    80001c84:	e1850513          	add	a0,a0,-488 # 80003a98 <etext+0xa98>
    80001c88:	fffff097          	auipc	ra,0xfffff
    80001c8c:	d84080e7          	jalr	-636(ra) # 80000a0c <printf>
}
    80001c90:	60e6                	ld	ra,88(sp)
    80001c92:	6446                	ld	s0,80(sp)
    80001c94:	6125                	add	sp,sp,96
    80001c96:	8082                	ret

0000000080001c98 <test_edge_cases>:

// ==================== 边界条件和错误处理测试 ====================
// 目的：验证系统在极限条件下的行为和错误恢复能力
void test_edge_cases(void) {
    80001c98:	cb010113          	add	sp,sp,-848
    80001c9c:	34113423          	sd	ra,840(sp)
    80001ca0:	34813023          	sd	s0,832(sp)
    80001ca4:	0e80                	add	s0,sp,848
    printf("=== Testing Edge Cases ===\n");
    80001ca6:	00002517          	auipc	a0,0x2
    80001caa:	e3a50513          	add	a0,a0,-454 # 80003ae0 <etext+0xae0>
    80001cae:	fffff097          	auipc	ra,0xfffff
    80001cb2:	d5e080e7          	jalr	-674(ra) # 80000a0c <printf>
    
    // 第一个测试：内存耗尽情况模拟
    // 目的：验证分配器在内存不足时的行为
    printf("Testing memory exhaustion...\n");
    80001cb6:	00002517          	auipc	a0,0x2
    80001cba:	e4a50513          	add	a0,a0,-438 # 80003b00 <etext+0xb00>
    80001cbe:	fffff097          	auipc	ra,0xfffff
    80001cc2:	d4e080e7          	jalr	-690(ra) # 80000a0c <printf>
    void *pages[100];       // 页面指针数组
    int allocated = 0;      // 成功分配的页面数
    80001cc6:	fe042623          	sw	zero,-20(s0)
    
    // 尝试分配大量页面，直到内存耗尽
    // 这个测试展示了分配器的极限容量
    for(int i = 0; i < 100; i++) {
    80001cca:	fe042423          	sw	zero,-24(s0)
    80001cce:	a899                	j	80001d24 <test_edge_cases+0x8c>
        pages[i] = alloc_page();
    80001cd0:	fffff097          	auipc	ra,0xfffff
    80001cd4:	3d0080e7          	jalr	976(ra) # 800010a0 <alloc_page>
    80001cd8:	872a                	mv	a4,a0
    80001cda:	fe842783          	lw	a5,-24(s0)
    80001cde:	078e                	sll	a5,a5,0x3
    80001ce0:	17c1                	add	a5,a5,-16
    80001ce2:	97a2                	add	a5,a5,s0
    80001ce4:	cce7b023          	sd	a4,-832(a5)
        if(pages[i] == 0) {
    80001ce8:	fe842783          	lw	a5,-24(s0)
    80001cec:	078e                	sll	a5,a5,0x3
    80001cee:	17c1                	add	a5,a5,-16
    80001cf0:	97a2                	add	a5,a5,s0
    80001cf2:	cc07b783          	ld	a5,-832(a5)
    80001cf6:	ef89                	bnez	a5,80001d10 <test_edge_cases+0x78>
            printf("Memory exhausted after %d pages\n", i);
    80001cf8:	fe842783          	lw	a5,-24(s0)
    80001cfc:	85be                	mv	a1,a5
    80001cfe:	00002517          	auipc	a0,0x2
    80001d02:	e2250513          	add	a0,a0,-478 # 80003b20 <etext+0xb20>
    80001d06:	fffff097          	auipc	ra,0xfffff
    80001d0a:	d06080e7          	jalr	-762(ra) # 80000a0c <printf>
            break;  // 遇到分配失败，停止测试
    80001d0e:	a01d                	j	80001d34 <test_edge_cases+0x9c>
        }
        allocated++;
    80001d10:	fec42783          	lw	a5,-20(s0)
    80001d14:	2785                	addw	a5,a5,1
    80001d16:	fef42623          	sw	a5,-20(s0)
    for(int i = 0; i < 100; i++) {
    80001d1a:	fe842783          	lw	a5,-24(s0)
    80001d1e:	2785                	addw	a5,a5,1
    80001d20:	fef42423          	sw	a5,-24(s0)
    80001d24:	fe842783          	lw	a5,-24(s0)
    80001d28:	0007871b          	sext.w	a4,a5
    80001d2c:	06300793          	li	a5,99
    80001d30:	fae7d0e3          	bge	a5,a4,80001cd0 <test_edge_cases+0x38>
    }
    
    // 释放所有分配的页面 - 测试内存回收
    // 验证分配器能够正确回收资源
    for(int i = 0; i < allocated; i++) {
    80001d34:	fe042223          	sw	zero,-28(s0)
    80001d38:	a015                	j	80001d5c <test_edge_cases+0xc4>
        free_page(pages[i]);
    80001d3a:	fe442783          	lw	a5,-28(s0)
    80001d3e:	078e                	sll	a5,a5,0x3
    80001d40:	17c1                	add	a5,a5,-16
    80001d42:	97a2                	add	a5,a5,s0
    80001d44:	cc07b783          	ld	a5,-832(a5)
    80001d48:	853e                	mv	a0,a5
    80001d4a:	fffff097          	auipc	ra,0xfffff
    80001d4e:	3b8080e7          	jalr	952(ra) # 80001102 <free_page>
    for(int i = 0; i < allocated; i++) {
    80001d52:	fe442783          	lw	a5,-28(s0)
    80001d56:	2785                	addw	a5,a5,1
    80001d58:	fef42223          	sw	a5,-28(s0)
    80001d5c:	fe442783          	lw	a5,-28(s0)
    80001d60:	873e                	mv	a4,a5
    80001d62:	fec42783          	lw	a5,-20(s0)
    80001d66:	2701                	sext.w	a4,a4
    80001d68:	2781                	sext.w	a5,a5
    80001d6a:	fcf748e3          	blt	a4,a5,80001d3a <test_edge_cases+0xa2>
    }
    printf("Memory exhaustion test completed\n");
    80001d6e:	00002517          	auipc	a0,0x2
    80001d72:	dda50513          	add	a0,a0,-550 # 80003b48 <etext+0xb48>
    80001d76:	fffff097          	auipc	ra,0xfffff
    80001d7a:	c96080e7          	jalr	-874(ra) # 80000a0c <printf>
    
    // 第二个测试：地址对齐验证
    // 目的：确保系统正确处理对齐要求
    printf("Testing address alignment...\n");
    80001d7e:	00002517          	auipc	a0,0x2
    80001d82:	df250513          	add	a0,a0,-526 # 80003b70 <etext+0xb70>
    80001d86:	fffff097          	auipc	ra,0xfffff
    80001d8a:	c86080e7          	jalr	-890(ra) # 80000a0c <printf>
    pagetable_t pt = create_pagetable();
    80001d8e:	fffff097          	auipc	ra,0xfffff
    80001d92:	5a8080e7          	jalr	1448(ra) # 80001336 <create_pagetable>
    80001d96:	fca43c23          	sd	a0,-40(s0)
    uint64 pa = (uint64)alloc_page();
    80001d9a:	fffff097          	auipc	ra,0xfffff
    80001d9e:	306080e7          	jalr	774(ra) # 800010a0 <alloc_page>
    80001da2:	87aa                	mv	a5,a0
    80001da4:	fcf43823          	sd	a5,-48(s0)
    
    // 注意：实际的未对齐地址测试会触发panic
    // 在生产环境中，这是正确的行为
    printf("Testing unaligned address (should panic)...\n");
    80001da8:	00002517          	auipc	a0,0x2
    80001dac:	de850513          	add	a0,a0,-536 # 80003b90 <etext+0xb90>
    80001db0:	fffff097          	auipc	ra,0xfffff
    80001db4:	c5c080e7          	jalr	-932(ra) # 80000a0c <printf>
    // 示例：map_page(pt, 0x1001, pa, PTE_R) 会因为地址未对齐而panic
    
    // 清理测试资源
    free_page((void*)pa);
    80001db8:	fd043783          	ld	a5,-48(s0)
    80001dbc:	853e                	mv	a0,a5
    80001dbe:	fffff097          	auipc	ra,0xfffff
    80001dc2:	344080e7          	jalr	836(ra) # 80001102 <free_page>
    destroy_pagetable(pt);
    80001dc6:	fd843503          	ld	a0,-40(s0)
    80001dca:	fffff097          	auipc	ra,0xfffff
    80001dce:	626080e7          	jalr	1574(ra) # 800013f0 <destroy_pagetable>
    printf("Edge cases test completed\n\n");
    80001dd2:	00002517          	auipc	a0,0x2
    80001dd6:	dee50513          	add	a0,a0,-530 # 80003bc0 <etext+0xbc0>
    80001dda:	fffff097          	auipc	ra,0xfffff
    80001dde:	c32080e7          	jalr	-974(ra) # 80000a0c <printf>
}
    80001de2:	0001                	nop
    80001de4:	34813083          	ld	ra,840(sp)
    80001de8:	34013403          	ld	s0,832(sp)
    80001dec:	35010113          	add	sp,sp,848
    80001df0:	8082                	ret

0000000080001df2 <run_comprehensive_tests>:

// ==================== 综合测试套件入口 ====================
// 作用：统一运行所有内存管理测试，提供完整的功能验证
void run_comprehensive_tests(void) {
    80001df2:	1141                	add	sp,sp,-16
    80001df4:	e406                	sd	ra,8(sp)
    80001df6:	e022                	sd	s0,0(sp)
    80001df8:	0800                	add	s0,sp,16
    printf("=== Comprehensive Memory Management Tests ===\n\n");
    80001dfa:	00002517          	auipc	a0,0x2
    80001dfe:	de650513          	add	a0,a0,-538 # 80003be0 <etext+0xbe0>
    80001e02:	fffff097          	auipc	ra,0xfffff
    80001e06:	c0a080e7          	jalr	-1014(ra) # 80000a0c <printf>
    
    // 按逻辑顺序运行测试：
    // 1. 先测试基本的页表功能
    test_multilevel_pagetable();
    80001e0a:	00000097          	auipc	ra,0x0
    80001e0e:	cb6080e7          	jalr	-842(ra) # 80001ac0 <test_multilevel_pagetable>
    
    // 2. 再测试边界条件和错误处理
    test_edge_cases();
    80001e12:	00000097          	auipc	ra,0x0
    80001e16:	e86080e7          	jalr	-378(ra) # 80001c98 <test_edge_cases>
    
    printf("All comprehensive tests completed!\n");
    80001e1a:	00002517          	auipc	a0,0x2
    80001e1e:	df650513          	add	a0,a0,-522 # 80003c10 <etext+0xc10>
    80001e22:	fffff097          	auipc	ra,0xfffff
    80001e26:	bea080e7          	jalr	-1046(ra) # 80000a0c <printf>
}
    80001e2a:	0001                	nop
    80001e2c:	60a2                	ld	ra,8(sp)
    80001e2e:	6402                	ld	s0,0(sp)
    80001e30:	0141                	add	sp,sp,16
    80001e32:	8082                	ret

0000000080001e34 <r_sstatus>:
        printf("register_interrupt: invalid IRQ %d\n", irq);
        return;
    }
    
    interrupt_handlers[irq] = handler;
    printf("Registered handler for IRQ %d\n", irq);
    80001e34:	1101                	add	sp,sp,-32
    80001e36:	ec22                	sd	s0,24(sp)
    80001e38:	1000                	add	s0,sp,32
}

    80001e3a:	100027f3          	csrr	a5,sstatus
    80001e3e:	fef43423          	sd	a5,-24(s0)
// ==================== 设备中断处理 ====================
    80001e42:	fe843783          	ld	a5,-24(s0)
// 检查并处理设备中断
    80001e46:	853e                	mv	a0,a5
    80001e48:	6462                	ld	s0,24(sp)
    80001e4a:	6105                	add	sp,sp,32
    80001e4c:	8082                	ret

0000000080001e4e <w_sstatus>:
// 返回值：1=处理了中断，0=没有中断待处理
static int devintr(void)
    80001e4e:	1101                	add	sp,sp,-32
    80001e50:	ec22                	sd	s0,24(sp)
    80001e52:	1000                	add	s0,sp,32
    80001e54:	fea43423          	sd	a0,-24(s0)
{
    80001e58:	fe843783          	ld	a5,-24(s0)
    80001e5c:	10079073          	csrw	sstatus,a5
    uint64 scause = r_scause();
    80001e60:	0001                	nop
    80001e62:	6462                	ld	s0,24(sp)
    80001e64:	6105                	add	sp,sp,32
    80001e66:	8082                	ret

0000000080001e68 <r_sie>:
    
    if((scause & 0x8000000000000000L) == 0) {
    80001e68:	1101                	add	sp,sp,-32
    80001e6a:	ec22                	sd	s0,24(sp)
    80001e6c:	1000                	add	s0,sp,32
        return 0;
    }
    80001e6e:	104027f3          	csrr	a5,sie
    80001e72:	fef43423          	sd	a5,-24(s0)
    
    80001e76:	fe843783          	ld	a5,-24(s0)
    scause = scause & 0xff;
    80001e7a:	853e                	mv	a0,a5
    80001e7c:	6462                	ld	s0,24(sp)
    80001e7e:	6105                	add	sp,sp,32
    80001e80:	8082                	ret

0000000080001e82 <w_sie>:
    
    if(scause == IRQ_S_TIMER) {
    80001e82:	1101                	add	sp,sp,-32
    80001e84:	ec22                	sd	s0,24(sp)
    80001e86:	1000                	add	s0,sp,32
    80001e88:	fea43423          	sd	a0,-24(s0)
        // 时钟中断处理
    80001e8c:	fe843783          	ld	a5,-24(s0)
    80001e90:	10479073          	csrw	sie,a5
        interrupt_counts[IRQ_S_TIMER]++;
    80001e94:	0001                	nop
    80001e96:	6462                	ld	s0,24(sp)
    80001e98:	6105                	add	sp,sp,32
    80001e9a:	8082                	ret

0000000080001e9c <r_sip>:
        
        if(interrupt_handlers[IRQ_S_TIMER]) {
    80001e9c:	1101                	add	sp,sp,-32
    80001e9e:	ec22                	sd	s0,24(sp)
    80001ea0:	1000                	add	s0,sp,32
            interrupt_handlers[IRQ_S_TIMER]();
        }
    80001ea2:	144027f3          	csrr	a5,sip
    80001ea6:	fef43423          	sd	a5,-24(s0)
        
    80001eaa:	fe843783          	ld	a5,-24(s0)
        return 1;
    80001eae:	853e                	mv	a0,a5
    80001eb0:	6462                	ld	s0,24(sp)
    80001eb2:	6105                	add	sp,sp,32
    80001eb4:	8082                	ret

0000000080001eb6 <w_sip>:
        
    } else if(scause == IRQ_S_SOFT) {
    80001eb6:	1101                	add	sp,sp,-32
    80001eb8:	ec22                	sd	s0,24(sp)
    80001eba:	1000                	add	s0,sp,32
    80001ebc:	fea43423          	sd	a0,-24(s0)
        // 软件中断处理（来自 M 模式的时钟注入）
    80001ec0:	fe843783          	ld	a5,-24(s0)
    80001ec4:	14479073          	csrw	sip,a5
        interrupt_counts[IRQ_S_SOFT]++;
    80001ec8:	0001                	nop
    80001eca:	6462                	ld	s0,24(sp)
    80001ecc:	6105                	add	sp,sp,32
    80001ece:	8082                	ret

0000000080001ed0 <r_scause>:
        
        // 清除软件中断标志
    80001ed0:	1101                	add	sp,sp,-32
    80001ed2:	ec22                	sd	s0,24(sp)
    80001ed4:	1000                	add	s0,sp,32
        w_sip(r_sip() & ~2);
        
    80001ed6:	142027f3          	csrr	a5,scause
    80001eda:	fef43423          	sd	a5,-24(s0)
        // 这实际上是时钟中断，调用时钟处理函数
    80001ede:	fe843783          	ld	a5,-24(s0)
        if(interrupt_handlers[IRQ_S_TIMER]) {
    80001ee2:	853e                	mv	a0,a5
    80001ee4:	6462                	ld	s0,24(sp)
    80001ee6:	6105                	add	sp,sp,32
    80001ee8:	8082                	ret

0000000080001eea <r_stval>:
    } else if(scause == IRQ_S_EXT) {
        // 外部中断处理
        interrupt_counts[IRQ_S_EXT]++;
        
        if(interrupt_handlers[IRQ_S_EXT]) {
            interrupt_handlers[IRQ_S_EXT]();
    80001eea:	1101                	add	sp,sp,-32
    80001eec:	ec22                	sd	s0,24(sp)
    80001eee:	1000                	add	s0,sp,32
        }
        
    80001ef0:	143027f3          	csrr	a5,stval
    80001ef4:	fef43423          	sd	a5,-24(s0)
        return 1;
    80001ef8:	fe843783          	ld	a5,-24(s0)
    }
    80001efc:	853e                	mv	a0,a5
    80001efe:	6462                	ld	s0,24(sp)
    80001f00:	6105                	add	sp,sp,32
    80001f02:	8082                	ret

0000000080001f04 <w_stvec>:
}
// ==================== 系统调用处理 ====================
void handle_syscall(struct trapframe *tf) {
    printf("\n=== System Call ===\n");
    printf("syscall number: %d (in a7)\n", (int)tf->a7);
    printf("arguments: a0=%p, a1=%p\n", (void*)tf->a0, (void*)tf->a1);
    80001f04:	1101                	add	sp,sp,-32
    80001f06:	ec22                	sd	s0,24(sp)
    80001f08:	1000                	add	s0,sp,32
    80001f0a:	fea43423          	sd	a0,-24(s0)
    printf("called from: %p\n", (void*)tf->sepc);
    80001f0e:	fe843783          	ld	a5,-24(s0)
    80001f12:	10579073          	csrw	stvec,a5
    
    80001f16:	0001                	nop
    80001f18:	6462                	ld	s0,24(sp)
    80001f1a:	6105                	add	sp,sp,32
    80001f1c:	8082                	ret

0000000080001f1e <trap_init>:
{
    80001f1e:	1101                	add	sp,sp,-32
    80001f20:	ec06                	sd	ra,24(sp)
    80001f22:	e822                	sd	s0,16(sp)
    80001f24:	1000                	add	s0,sp,32
    printf("Initializing trap system...\n");
    80001f26:	00002517          	auipc	a0,0x2
    80001f2a:	d1250513          	add	a0,a0,-750 # 80003c38 <etext+0xc38>
    80001f2e:	fffff097          	auipc	ra,0xfffff
    80001f32:	ade080e7          	jalr	-1314(ra) # 80000a0c <printf>
    for(int i = 0; i < 16; i++) {
    80001f36:	fe042623          	sw	zero,-20(s0)
    80001f3a:	a815                	j	80001f6e <trap_init+0x50>
        interrupt_handlers[i] = 0;
    80001f3c:	00008717          	auipc	a4,0x8
    80001f40:	16470713          	add	a4,a4,356 # 8000a0a0 <interrupt_handlers>
    80001f44:	fec42783          	lw	a5,-20(s0)
    80001f48:	078e                	sll	a5,a5,0x3
    80001f4a:	97ba                	add	a5,a5,a4
    80001f4c:	0007b023          	sd	zero,0(a5)
        interrupt_counts[i] = 0;
    80001f50:	00008717          	auipc	a4,0x8
    80001f54:	0c870713          	add	a4,a4,200 # 8000a018 <interrupt_counts>
    80001f58:	fec42783          	lw	a5,-20(s0)
    80001f5c:	078e                	sll	a5,a5,0x3
    80001f5e:	97ba                	add	a5,a5,a4
    80001f60:	0007b023          	sd	zero,0(a5)
    for(int i = 0; i < 16; i++) {
    80001f64:	fec42783          	lw	a5,-20(s0)
    80001f68:	2785                	addw	a5,a5,1
    80001f6a:	fef42623          	sw	a5,-20(s0)
    80001f6e:	fec42783          	lw	a5,-20(s0)
    80001f72:	0007871b          	sext.w	a4,a5
    80001f76:	47bd                	li	a5,15
    80001f78:	fce7d2e3          	bge	a5,a4,80001f3c <trap_init+0x1e>
    w_stvec((uint64)kernelvec);
    80001f7c:	00001797          	auipc	a5,0x1
    80001f80:	ae478793          	add	a5,a5,-1308 # 80002a60 <kernelvec>
    80001f84:	853e                	mv	a0,a5
    80001f86:	00000097          	auipc	ra,0x0
    80001f8a:	f7e080e7          	jalr	-130(ra) # 80001f04 <w_stvec>
    printf("Set stvec to %p\n", (void*)kernelvec);
    80001f8e:	00001597          	auipc	a1,0x1
    80001f92:	ad258593          	add	a1,a1,-1326 # 80002a60 <kernelvec>
    80001f96:	00002517          	auipc	a0,0x2
    80001f9a:	cc250513          	add	a0,a0,-830 # 80003c58 <etext+0xc58>
    80001f9e:	fffff097          	auipc	ra,0xfffff
    80001fa2:	a6e080e7          	jalr	-1426(ra) # 80000a0c <printf>
    w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    80001fa6:	00000097          	auipc	ra,0x0
    80001faa:	ec2080e7          	jalr	-318(ra) # 80001e68 <r_sie>
    80001fae:	87aa                	mv	a5,a0
    80001fb0:	2227e793          	or	a5,a5,546
    80001fb4:	853e                	mv	a0,a5
    80001fb6:	00000097          	auipc	ra,0x0
    80001fba:	ecc080e7          	jalr	-308(ra) # 80001e82 <w_sie>
    w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fbe:	00000097          	auipc	ra,0x0
    80001fc2:	e76080e7          	jalr	-394(ra) # 80001e34 <r_sstatus>
    80001fc6:	87aa                	mv	a5,a0
    80001fc8:	0027e793          	or	a5,a5,2
    80001fcc:	853e                	mv	a0,a5
    80001fce:	00000097          	auipc	ra,0x0
    80001fd2:	e80080e7          	jalr	-384(ra) # 80001e4e <w_sstatus>
    printf("Trap system initialized\n");
    80001fd6:	00002517          	auipc	a0,0x2
    80001fda:	c9a50513          	add	a0,a0,-870 # 80003c70 <etext+0xc70>
    80001fde:	fffff097          	auipc	ra,0xfffff
    80001fe2:	a2e080e7          	jalr	-1490(ra) # 80000a0c <printf>
}
    80001fe6:	0001                	nop
    80001fe8:	60e2                	ld	ra,24(sp)
    80001fea:	6442                	ld	s0,16(sp)
    80001fec:	6105                	add	sp,sp,32
    80001fee:	8082                	ret

0000000080001ff0 <register_interrupt>:
{
    80001ff0:	1101                	add	sp,sp,-32
    80001ff2:	ec06                	sd	ra,24(sp)
    80001ff4:	e822                	sd	s0,16(sp)
    80001ff6:	1000                	add	s0,sp,32
    80001ff8:	87aa                	mv	a5,a0
    80001ffa:	feb43023          	sd	a1,-32(s0)
    80001ffe:	fef42623          	sw	a5,-20(s0)
    if(irq < 0 || irq >= 16) {
    80002002:	fec42783          	lw	a5,-20(s0)
    80002006:	2781                	sext.w	a5,a5
    80002008:	0007c963          	bltz	a5,8000201a <register_interrupt+0x2a>
    8000200c:	fec42783          	lw	a5,-20(s0)
    80002010:	0007871b          	sext.w	a4,a5
    80002014:	47bd                	li	a5,15
    80002016:	00e7de63          	bge	a5,a4,80002032 <register_interrupt+0x42>
        printf("register_interrupt: invalid IRQ %d\n", irq);
    8000201a:	fec42783          	lw	a5,-20(s0)
    8000201e:	85be                	mv	a1,a5
    80002020:	00002517          	auipc	a0,0x2
    80002024:	c7050513          	add	a0,a0,-912 # 80003c90 <etext+0xc90>
    80002028:	fffff097          	auipc	ra,0xfffff
    8000202c:	9e4080e7          	jalr	-1564(ra) # 80000a0c <printf>
        return;
    80002030:	a03d                	j	8000205e <register_interrupt+0x6e>
    interrupt_handlers[irq] = handler;
    80002032:	00008717          	auipc	a4,0x8
    80002036:	06e70713          	add	a4,a4,110 # 8000a0a0 <interrupt_handlers>
    8000203a:	fec42783          	lw	a5,-20(s0)
    8000203e:	078e                	sll	a5,a5,0x3
    80002040:	97ba                	add	a5,a5,a4
    80002042:	fe043703          	ld	a4,-32(s0)
    80002046:	e398                	sd	a4,0(a5)
    printf("Registered handler for IRQ %d\n", irq);
    80002048:	fec42783          	lw	a5,-20(s0)
    8000204c:	85be                	mv	a1,a5
    8000204e:	00002517          	auipc	a0,0x2
    80002052:	c6a50513          	add	a0,a0,-918 # 80003cb8 <etext+0xcb8>
    80002056:	fffff097          	auipc	ra,0xfffff
    8000205a:	9b6080e7          	jalr	-1610(ra) # 80000a0c <printf>
}
    8000205e:	60e2                	ld	ra,24(sp)
    80002060:	6442                	ld	s0,16(sp)
    80002062:	6105                	add	sp,sp,32
    80002064:	8082                	ret

0000000080002066 <devintr>:
{
    80002066:	1101                	add	sp,sp,-32
    80002068:	ec06                	sd	ra,24(sp)
    8000206a:	e822                	sd	s0,16(sp)
    8000206c:	1000                	add	s0,sp,32
    uint64 scause = r_scause();
    8000206e:	00000097          	auipc	ra,0x0
    80002072:	e62080e7          	jalr	-414(ra) # 80001ed0 <r_scause>
    80002076:	fea43423          	sd	a0,-24(s0)
    if((scause & 0x8000000000000000L) == 0) {
    8000207a:	fe843783          	ld	a5,-24(s0)
    8000207e:	0007c463          	bltz	a5,80002086 <devintr+0x20>
        return 0;
    80002082:	4781                	li	a5,0
    80002084:	a8e5                	j	8000217c <devintr+0x116>
    scause = scause & 0xff;
    80002086:	fe843783          	ld	a5,-24(s0)
    8000208a:	0ff7f793          	zext.b	a5,a5
    8000208e:	fef43423          	sd	a5,-24(s0)
    if(scause == IRQ_S_TIMER) {
    80002092:	fe843703          	ld	a4,-24(s0)
    80002096:	4795                	li	a5,5
    80002098:	02f71c63          	bne	a4,a5,800020d0 <devintr+0x6a>
        interrupt_counts[IRQ_S_TIMER]++;
    8000209c:	00008797          	auipc	a5,0x8
    800020a0:	f7c78793          	add	a5,a5,-132 # 8000a018 <interrupt_counts>
    800020a4:	779c                	ld	a5,40(a5)
    800020a6:	00178713          	add	a4,a5,1
    800020aa:	00008797          	auipc	a5,0x8
    800020ae:	f6e78793          	add	a5,a5,-146 # 8000a018 <interrupt_counts>
    800020b2:	f798                	sd	a4,40(a5)
        if(interrupt_handlers[IRQ_S_TIMER]) {
    800020b4:	00008797          	auipc	a5,0x8
    800020b8:	fec78793          	add	a5,a5,-20 # 8000a0a0 <interrupt_handlers>
    800020bc:	779c                	ld	a5,40(a5)
    800020be:	c799                	beqz	a5,800020cc <devintr+0x66>
            interrupt_handlers[IRQ_S_TIMER]();
    800020c0:	00008797          	auipc	a5,0x8
    800020c4:	fe078793          	add	a5,a5,-32 # 8000a0a0 <interrupt_handlers>
    800020c8:	779c                	ld	a5,40(a5)
    800020ca:	9782                	jalr	a5
        return 1;
    800020cc:	4785                	li	a5,1
    800020ce:	a07d                	j	8000217c <devintr+0x116>
    } else if(scause == IRQ_S_SOFT) {
    800020d0:	fe843703          	ld	a4,-24(s0)
    800020d4:	4785                	li	a5,1
    800020d6:	06f71363          	bne	a4,a5,8000213c <devintr+0xd6>
        interrupt_counts[IRQ_S_SOFT]++;
    800020da:	00008797          	auipc	a5,0x8
    800020de:	f3e78793          	add	a5,a5,-194 # 8000a018 <interrupt_counts>
    800020e2:	679c                	ld	a5,8(a5)
    800020e4:	00178713          	add	a4,a5,1
    800020e8:	00008797          	auipc	a5,0x8
    800020ec:	f3078793          	add	a5,a5,-208 # 8000a018 <interrupt_counts>
    800020f0:	e798                	sd	a4,8(a5)
        w_sip(r_sip() & ~2);
    800020f2:	00000097          	auipc	ra,0x0
    800020f6:	daa080e7          	jalr	-598(ra) # 80001e9c <r_sip>
    800020fa:	87aa                	mv	a5,a0
    800020fc:	9bf5                	and	a5,a5,-3
    800020fe:	853e                	mv	a0,a5
    80002100:	00000097          	auipc	ra,0x0
    80002104:	db6080e7          	jalr	-586(ra) # 80001eb6 <w_sip>
        if(interrupt_handlers[IRQ_S_TIMER]) {
    80002108:	00008797          	auipc	a5,0x8
    8000210c:	f9878793          	add	a5,a5,-104 # 8000a0a0 <interrupt_handlers>
    80002110:	779c                	ld	a5,40(a5)
    80002112:	c39d                	beqz	a5,80002138 <devintr+0xd2>
            interrupt_handlers[IRQ_S_TIMER]();
    80002114:	00008797          	auipc	a5,0x8
    80002118:	f8c78793          	add	a5,a5,-116 # 8000a0a0 <interrupt_handlers>
    8000211c:	779c                	ld	a5,40(a5)
    8000211e:	9782                	jalr	a5
            interrupt_counts[IRQ_S_TIMER]++;  // 也统计为时钟中断
    80002120:	00008797          	auipc	a5,0x8
    80002124:	ef878793          	add	a5,a5,-264 # 8000a018 <interrupt_counts>
    80002128:	779c                	ld	a5,40(a5)
    8000212a:	00178713          	add	a4,a5,1
    8000212e:	00008797          	auipc	a5,0x8
    80002132:	eea78793          	add	a5,a5,-278 # 8000a018 <interrupt_counts>
    80002136:	f798                	sd	a4,40(a5)
        return 1;
    80002138:	4785                	li	a5,1
    8000213a:	a089                	j	8000217c <devintr+0x116>
    } else if(scause == IRQ_S_EXT) {
    8000213c:	fe843703          	ld	a4,-24(s0)
    80002140:	47a5                	li	a5,9
    80002142:	02f71c63          	bne	a4,a5,8000217a <devintr+0x114>
        interrupt_counts[IRQ_S_EXT]++;
    80002146:	00008797          	auipc	a5,0x8
    8000214a:	ed278793          	add	a5,a5,-302 # 8000a018 <interrupt_counts>
    8000214e:	67bc                	ld	a5,72(a5)
    80002150:	00178713          	add	a4,a5,1
    80002154:	00008797          	auipc	a5,0x8
    80002158:	ec478793          	add	a5,a5,-316 # 8000a018 <interrupt_counts>
    8000215c:	e7b8                	sd	a4,72(a5)
        if(interrupt_handlers[IRQ_S_EXT]) {
    8000215e:	00008797          	auipc	a5,0x8
    80002162:	f4278793          	add	a5,a5,-190 # 8000a0a0 <interrupt_handlers>
    80002166:	67bc                	ld	a5,72(a5)
    80002168:	c799                	beqz	a5,80002176 <devintr+0x110>
            interrupt_handlers[IRQ_S_EXT]();
    8000216a:	00008797          	auipc	a5,0x8
    8000216e:	f3678793          	add	a5,a5,-202 # 8000a0a0 <interrupt_handlers>
    80002172:	67bc                	ld	a5,72(a5)
    80002174:	9782                	jalr	a5
        return 1;
    80002176:	4785                	li	a5,1
    80002178:	a011                	j	8000217c <devintr+0x116>
    return 0;
    8000217a:	4781                	li	a5,0
}
    8000217c:	853e                	mv	a0,a5
    8000217e:	60e2                	ld	ra,24(sp)
    80002180:	6442                	ld	s0,16(sp)
    80002182:	6105                	add	sp,sp,32
    80002184:	8082                	ret

0000000080002186 <handle_syscall>:
void handle_syscall(struct trapframe *tf) {
    80002186:	1101                	add	sp,sp,-32
    80002188:	ec06                	sd	ra,24(sp)
    8000218a:	e822                	sd	s0,16(sp)
    8000218c:	1000                	add	s0,sp,32
    8000218e:	fea43423          	sd	a0,-24(s0)
    printf("\n=== System Call ===\n");
    80002192:	00002517          	auipc	a0,0x2
    80002196:	b4650513          	add	a0,a0,-1210 # 80003cd8 <etext+0xcd8>
    8000219a:	fffff097          	auipc	ra,0xfffff
    8000219e:	872080e7          	jalr	-1934(ra) # 80000a0c <printf>
    printf("syscall number: %d (in a7)\n", (int)tf->a7);
    800021a2:	fe843783          	ld	a5,-24(s0)
    800021a6:	63dc                	ld	a5,128(a5)
    800021a8:	2781                	sext.w	a5,a5
    800021aa:	85be                	mv	a1,a5
    800021ac:	00002517          	auipc	a0,0x2
    800021b0:	b4450513          	add	a0,a0,-1212 # 80003cf0 <etext+0xcf0>
    800021b4:	fffff097          	auipc	ra,0xfffff
    800021b8:	858080e7          	jalr	-1960(ra) # 80000a0c <printf>
    printf("arguments: a0=%p, a1=%p\n", (void*)tf->a0, (void*)tf->a1);
    800021bc:	fe843783          	ld	a5,-24(s0)
    800021c0:	67bc                	ld	a5,72(a5)
    800021c2:	873e                	mv	a4,a5
    800021c4:	fe843783          	ld	a5,-24(s0)
    800021c8:	6bbc                	ld	a5,80(a5)
    800021ca:	863e                	mv	a2,a5
    800021cc:	85ba                	mv	a1,a4
    800021ce:	00002517          	auipc	a0,0x2
    800021d2:	b4250513          	add	a0,a0,-1214 # 80003d10 <etext+0xd10>
    800021d6:	fffff097          	auipc	ra,0xfffff
    800021da:	836080e7          	jalr	-1994(ra) # 80000a0c <printf>
    printf("called from: %p\n", (void*)tf->sepc);
    800021de:	fe843783          	ld	a5,-24(s0)
    800021e2:	7ffc                	ld	a5,248(a5)
    800021e4:	85be                	mv	a1,a5
    800021e6:	00002517          	auipc	a0,0x2
    800021ea:	b4a50513          	add	a0,a0,-1206 # 80003d30 <etext+0xd30>
    800021ee:	fffff097          	auipc	ra,0xfffff
    800021f2:	81e080e7          	jalr	-2018(ra) # 80000a0c <printf>
    // 跳过 ecall 指令（4字节）
    tf->sepc += 4;
    800021f6:	fe843783          	ld	a5,-24(s0)
    800021fa:	7ffc                	ld	a5,248(a5)
    800021fc:	00478713          	add	a4,a5,4
    80002200:	fe843783          	ld	a5,-24(s0)
    80002204:	fff8                	sd	a4,248(a5)
    
    printf("System call handled, returning to %p\n", (void*)tf->sepc);
    80002206:	fe843783          	ld	a5,-24(s0)
    8000220a:	7ffc                	ld	a5,248(a5)
    8000220c:	85be                	mv	a1,a5
    8000220e:	00002517          	auipc	a0,0x2
    80002212:	b3a50513          	add	a0,a0,-1222 # 80003d48 <etext+0xd48>
    80002216:	ffffe097          	auipc	ra,0xffffe
    8000221a:	7f6080e7          	jalr	2038(ra) # 80000a0c <printf>
}
    8000221e:	0001                	nop
    80002220:	60e2                	ld	ra,24(sp)
    80002222:	6442                	ld	s0,16(sp)
    80002224:	6105                	add	sp,sp,32
    80002226:	8082                	ret

0000000080002228 <handle_instruction_page_fault>:

// ==================== 指令页故障处理 ====================
void handle_instruction_page_fault(struct trapframe *tf) {
    80002228:	7179                	add	sp,sp,-48
    8000222a:	f406                	sd	ra,40(sp)
    8000222c:	f022                	sd	s0,32(sp)
    8000222e:	1800                	add	s0,sp,48
    80002230:	fca43c23          	sd	a0,-40(s0)
    uint64 fault_addr = r_stval();  // 故障地址
    80002234:	00000097          	auipc	ra,0x0
    80002238:	cb6080e7          	jalr	-842(ra) # 80001eea <r_stval>
    8000223c:	fea43423          	sd	a0,-24(s0)
    
    printf("\n=== Instruction Page Fault ===\n");
    80002240:	00002517          	auipc	a0,0x2
    80002244:	b3050513          	add	a0,a0,-1232 # 80003d70 <etext+0xd70>
    80002248:	ffffe097          	auipc	ra,0xffffe
    8000224c:	7c4080e7          	jalr	1988(ra) # 80000a0c <printf>
    printf("Fault address: %p\n", (void*)fault_addr);
    80002250:	fe843783          	ld	a5,-24(s0)
    80002254:	85be                	mv	a1,a5
    80002256:	00002517          	auipc	a0,0x2
    8000225a:	b4250513          	add	a0,a0,-1214 # 80003d98 <etext+0xd98>
    8000225e:	ffffe097          	auipc	ra,0xffffe
    80002262:	7ae080e7          	jalr	1966(ra) # 80000a0c <printf>
    printf("PC: %p\n", (void*)tf->sepc);
    80002266:	fd843783          	ld	a5,-40(s0)
    8000226a:	7ffc                	ld	a5,248(a5)
    8000226c:	85be                	mv	a1,a5
    8000226e:	00002517          	auipc	a0,0x2
    80002272:	b4250513          	add	a0,a0,-1214 # 80003db0 <etext+0xdb0>
    80002276:	ffffe097          	auipc	ra,0xffffe
    8000227a:	796080e7          	jalr	1942(ra) # 80000a0c <printf>
    
    // 简单处理：如果是内核地址，panic
    if(fault_addr >= KERNBASE) {
    8000227e:	fe843703          	ld	a4,-24(s0)
    80002282:	800007b7          	lui	a5,0x80000
    80002286:	fff7c793          	not	a5,a5
    8000228a:	00e7fa63          	bgeu	a5,a4,8000229e <handle_instruction_page_fault+0x76>
        panic("Instruction page fault in kernel space");
    8000228e:	00002517          	auipc	a0,0x2
    80002292:	b2a50513          	add	a0,a0,-1238 # 80003db8 <etext+0xdb8>
    80002296:	fffff097          	auipc	ra,0xfffff
    8000229a:	b1c080e7          	jalr	-1252(ra) # 80000db2 <panic>
    }
    
    // 这里可以实现按需分页等功能
    printf("TODO: Implement demand paging for instruction fault\n");
    8000229e:	00002517          	auipc	a0,0x2
    800022a2:	b4250513          	add	a0,a0,-1214 # 80003de0 <etext+0xde0>
    800022a6:	ffffe097          	auipc	ra,0xffffe
    800022aa:	766080e7          	jalr	1894(ra) # 80000a0c <printf>
    panic("Instruction page fault not handled");
    800022ae:	00002517          	auipc	a0,0x2
    800022b2:	b6a50513          	add	a0,a0,-1174 # 80003e18 <etext+0xe18>
    800022b6:	fffff097          	auipc	ra,0xfffff
    800022ba:	afc080e7          	jalr	-1284(ra) # 80000db2 <panic>
}
    800022be:	0001                	nop
    800022c0:	70a2                	ld	ra,40(sp)
    800022c2:	7402                	ld	s0,32(sp)
    800022c4:	6145                	add	sp,sp,48
    800022c6:	8082                	ret

00000000800022c8 <handle_load_page_fault>:

// ==================== 加载页故障处理 ====================
void handle_load_page_fault(struct trapframe *tf) {
    800022c8:	7179                	add	sp,sp,-48
    800022ca:	f406                	sd	ra,40(sp)
    800022cc:	f022                	sd	s0,32(sp)
    800022ce:	1800                	add	s0,sp,48
    800022d0:	fca43c23          	sd	a0,-40(s0)
    uint64 fault_addr = r_stval();  // 故障地址
    800022d4:	00000097          	auipc	ra,0x0
    800022d8:	c16080e7          	jalr	-1002(ra) # 80001eea <r_stval>
    800022dc:	fea43423          	sd	a0,-24(s0)
    
    printf("\n=== Load Page Fault ===\n");
    800022e0:	00002517          	auipc	a0,0x2
    800022e4:	b6050513          	add	a0,a0,-1184 # 80003e40 <etext+0xe40>
    800022e8:	ffffe097          	auipc	ra,0xffffe
    800022ec:	724080e7          	jalr	1828(ra) # 80000a0c <printf>
    printf("Fault address: %p\n", (void*)fault_addr);
    800022f0:	fe843783          	ld	a5,-24(s0)
    800022f4:	85be                	mv	a1,a5
    800022f6:	00002517          	auipc	a0,0x2
    800022fa:	aa250513          	add	a0,a0,-1374 # 80003d98 <etext+0xd98>
    800022fe:	ffffe097          	auipc	ra,0xffffe
    80002302:	70e080e7          	jalr	1806(ra) # 80000a0c <printf>
    printf("PC: %p\n", (void*)tf->sepc);
    80002306:	fd843783          	ld	a5,-40(s0)
    8000230a:	7ffc                	ld	a5,248(a5)
    8000230c:	85be                	mv	a1,a5
    8000230e:	00002517          	auipc	a0,0x2
    80002312:	aa250513          	add	a0,a0,-1374 # 80003db0 <etext+0xdb0>
    80002316:	ffffe097          	auipc	ra,0xffffe
    8000231a:	6f6080e7          	jalr	1782(ra) # 80000a0c <printf>
    printf("Tried to read from unmapped address\n");
    8000231e:	00002517          	auipc	a0,0x2
    80002322:	b4250513          	add	a0,a0,-1214 # 80003e60 <etext+0xe60>
    80002326:	ffffe097          	auipc	ra,0xffffe
    8000232a:	6e6080e7          	jalr	1766(ra) # 80000a0c <printf>
    
    // 简单处理：panic
    panic("Load page fault");
    8000232e:	00002517          	auipc	a0,0x2
    80002332:	b5a50513          	add	a0,a0,-1190 # 80003e88 <etext+0xe88>
    80002336:	fffff097          	auipc	ra,0xfffff
    8000233a:	a7c080e7          	jalr	-1412(ra) # 80000db2 <panic>
}
    8000233e:	0001                	nop
    80002340:	70a2                	ld	ra,40(sp)
    80002342:	7402                	ld	s0,32(sp)
    80002344:	6145                	add	sp,sp,48
    80002346:	8082                	ret

0000000080002348 <handle_store_page_fault>:

// ==================== 存储页故障处理 ====================
void handle_store_page_fault(struct trapframe *tf) {
    80002348:	7179                	add	sp,sp,-48
    8000234a:	f406                	sd	ra,40(sp)
    8000234c:	f022                	sd	s0,32(sp)
    8000234e:	1800                	add	s0,sp,48
    80002350:	fca43c23          	sd	a0,-40(s0)
    uint64 fault_addr = r_stval();  // 故障地址
    80002354:	00000097          	auipc	ra,0x0
    80002358:	b96080e7          	jalr	-1130(ra) # 80001eea <r_stval>
    8000235c:	fea43423          	sd	a0,-24(s0)
    
    printf("\n=== Store Page Fault ===\n");
    80002360:	00002517          	auipc	a0,0x2
    80002364:	b3850513          	add	a0,a0,-1224 # 80003e98 <etext+0xe98>
    80002368:	ffffe097          	auipc	ra,0xffffe
    8000236c:	6a4080e7          	jalr	1700(ra) # 80000a0c <printf>
    printf("Fault address: %p\n", (void*)fault_addr);
    80002370:	fe843783          	ld	a5,-24(s0)
    80002374:	85be                	mv	a1,a5
    80002376:	00002517          	auipc	a0,0x2
    8000237a:	a2250513          	add	a0,a0,-1502 # 80003d98 <etext+0xd98>
    8000237e:	ffffe097          	auipc	ra,0xffffe
    80002382:	68e080e7          	jalr	1678(ra) # 80000a0c <printf>
    printf("PC: %p\n", (void*)tf->sepc);
    80002386:	fd843783          	ld	a5,-40(s0)
    8000238a:	7ffc                	ld	a5,248(a5)
    8000238c:	85be                	mv	a1,a5
    8000238e:	00002517          	auipc	a0,0x2
    80002392:	a2250513          	add	a0,a0,-1502 # 80003db0 <etext+0xdb0>
    80002396:	ffffe097          	auipc	ra,0xffffe
    8000239a:	676080e7          	jalr	1654(ra) # 80000a0c <printf>
    printf("Tried to write to unmapped or read-only address\n");
    8000239e:	00002517          	auipc	a0,0x2
    800023a2:	b1a50513          	add	a0,a0,-1254 # 80003eb8 <etext+0xeb8>
    800023a6:	ffffe097          	auipc	ra,0xffffe
    800023aa:	666080e7          	jalr	1638(ra) # 80000a0c <printf>
    
    // 检查是否写入只读代码段
    if(fault_addr >= KERNBASE && fault_addr < (uint64)etext) {
    800023ae:	fe843703          	ld	a4,-24(s0)
    800023b2:	800007b7          	lui	a5,0x80000
    800023b6:	fff7c793          	not	a5,a5
    800023ba:	02e7f263          	bgeu	a5,a4,800023de <handle_store_page_fault+0x96>
    800023be:	00001797          	auipc	a5,0x1
    800023c2:	c4278793          	add	a5,a5,-958 # 80003000 <etext>
    800023c6:	fe843703          	ld	a4,-24(s0)
    800023ca:	00f77a63          	bgeu	a4,a5,800023de <handle_store_page_fault+0x96>
        printf("Attempted to write to read-only kernel text segment!\n");
    800023ce:	00002517          	auipc	a0,0x2
    800023d2:	b2250513          	add	a0,a0,-1246 # 80003ef0 <etext+0xef0>
    800023d6:	ffffe097          	auipc	ra,0xffffe
    800023da:	636080e7          	jalr	1590(ra) # 80000a0c <printf>
    }
    
    panic("Store page fault");
    800023de:	00002517          	auipc	a0,0x2
    800023e2:	b4a50513          	add	a0,a0,-1206 # 80003f28 <etext+0xf28>
    800023e6:	fffff097          	auipc	ra,0xfffff
    800023ea:	9cc080e7          	jalr	-1588(ra) # 80000db2 <panic>
}
    800023ee:	0001                	nop
    800023f0:	70a2                	ld	ra,40(sp)
    800023f2:	7402                	ld	s0,32(sp)
    800023f4:	6145                	add	sp,sp,48
    800023f6:	8082                	ret

00000000800023f8 <handle_exception>:

// ==================== 统一异常处理入口 ====================
void handle_exception(struct trapframe *tf) {
    800023f8:	7139                	add	sp,sp,-64
    800023fa:	fc06                	sd	ra,56(sp)
    800023fc:	f822                	sd	s0,48(sp)
    800023fe:	f426                	sd	s1,40(sp)
    80002400:	0080                	add	s0,sp,64
    80002402:	fca43423          	sd	a0,-56(s0)
    uint64 cause = r_scause();
    80002406:	00000097          	auipc	ra,0x0
    8000240a:	aca080e7          	jalr	-1334(ra) # 80001ed0 <r_scause>
    8000240e:	fca43c23          	sd	a0,-40(s0)
    
    printf("\n[Exception Handler] cause=%d (%s)\n", 
    80002412:	fd843783          	ld	a5,-40(s0)
    80002416:	0007849b          	sext.w	s1,a5
    8000241a:	fd843503          	ld	a0,-40(s0)
    8000241e:	00000097          	auipc	ra,0x0
    80002422:	2fa080e7          	jalr	762(ra) # 80002718 <trap_cause_name>
    80002426:	87aa                	mv	a5,a0
    80002428:	863e                	mv	a2,a5
    8000242a:	85a6                	mv	a1,s1
    8000242c:	00002517          	auipc	a0,0x2
    80002430:	b1450513          	add	a0,a0,-1260 # 80003f40 <etext+0xf40>
    80002434:	ffffe097          	auipc	ra,0xffffe
    80002438:	5d8080e7          	jalr	1496(ra) # 80000a0c <printf>
           (int)cause, trap_cause_name(cause));
    
    switch(cause) {
    8000243c:	fd843703          	ld	a4,-40(s0)
    80002440:	47bd                	li	a5,15
    80002442:	1ce7e163          	bltu	a5,a4,80002604 <handle_exception+0x20c>
    80002446:	fd843783          	ld	a5,-40(s0)
    8000244a:	00279713          	sll	a4,a5,0x2
    8000244e:	00002797          	auipc	a5,0x2
    80002452:	cbe78793          	add	a5,a5,-834 # 8000410c <etext+0x110c>
    80002456:	97ba                	add	a5,a5,a4
    80002458:	439c                	lw	a5,0(a5)
    8000245a:	0007871b          	sext.w	a4,a5
    8000245e:	00002797          	auipc	a5,0x2
    80002462:	cae78793          	add	a5,a5,-850 # 8000410c <etext+0x110c>
    80002466:	97ba                	add	a5,a5,a4
    80002468:	8782                	jr	a5
        case CAUSE_USER_ECALL:           // 8: 用户模式系统调用
        case CAUSE_SUPERVISOR_ECALL:     // 9: 监督模式系统调用
            handle_syscall(tf);
    8000246a:	fc843503          	ld	a0,-56(s0)
    8000246e:	00000097          	auipc	ra,0x0
    80002472:	d18080e7          	jalr	-744(ra) # 80002186 <handle_syscall>
            break;
    80002476:	aaf5                	j	80002672 <handle_exception+0x27a>
            
        case CAUSE_FETCH_PAGE_FAULT:     // 12: 指令页故障
            handle_instruction_page_fault(tf);
    80002478:	fc843503          	ld	a0,-56(s0)
    8000247c:	00000097          	auipc	ra,0x0
    80002480:	dac080e7          	jalr	-596(ra) # 80002228 <handle_instruction_page_fault>
            break;
    80002484:	a2fd                	j	80002672 <handle_exception+0x27a>
            
        case CAUSE_LOAD_PAGE_FAULT:      // 13: 加载页故障
            handle_load_page_fault(tf);
    80002486:	fc843503          	ld	a0,-56(s0)
    8000248a:	00000097          	auipc	ra,0x0
    8000248e:	e3e080e7          	jalr	-450(ra) # 800022c8 <handle_load_page_fault>
            break;
    80002492:	a2c5                	j	80002672 <handle_exception+0x27a>
            
        case CAUSE_STORE_PAGE_FAULT:     // 15: 存储页故障
            handle_store_page_fault(tf);
    80002494:	fc843503          	ld	a0,-56(s0)
    80002498:	00000097          	auipc	ra,0x0
    8000249c:	eb0080e7          	jalr	-336(ra) # 80002348 <handle_store_page_fault>
            break;
    800024a0:	aac9                	j	80002672 <handle_exception+0x27a>
            
        case CAUSE_ILLEGAL_INSTRUCTION:  // 2: 非法指令
            printf("\n=== Illegal Instruction ===\n");
    800024a2:	00002517          	auipc	a0,0x2
    800024a6:	ac650513          	add	a0,a0,-1338 # 80003f68 <etext+0xf68>
    800024aa:	ffffe097          	auipc	ra,0xffffe
    800024ae:	562080e7          	jalr	1378(ra) # 80000a0c <printf>
            printf("PC: %p\n", (void*)tf->sepc);
    800024b2:	fc843783          	ld	a5,-56(s0)
    800024b6:	7ffc                	ld	a5,248(a5)
    800024b8:	85be                	mv	a1,a5
    800024ba:	00002517          	auipc	a0,0x2
    800024be:	8f650513          	add	a0,a0,-1802 # 80003db0 <etext+0xdb0>
    800024c2:	ffffe097          	auipc	ra,0xffffe
    800024c6:	54a080e7          	jalr	1354(ra) # 80000a0c <printf>
            printf("Instruction value: %p\n", (void*)r_stval());
    800024ca:	00000097          	auipc	ra,0x0
    800024ce:	a20080e7          	jalr	-1504(ra) # 80001eea <r_stval>
    800024d2:	87aa                	mv	a5,a0
    800024d4:	85be                	mv	a1,a5
    800024d6:	00002517          	auipc	a0,0x2
    800024da:	ab250513          	add	a0,a0,-1358 # 80003f88 <etext+0xf88>
    800024de:	ffffe097          	auipc	ra,0xffffe
    800024e2:	52e080e7          	jalr	1326(ra) # 80000a0c <printf>
            panic("Illegal instruction");
    800024e6:	00002517          	auipc	a0,0x2
    800024ea:	aba50513          	add	a0,a0,-1350 # 80003fa0 <etext+0xfa0>
    800024ee:	fffff097          	auipc	ra,0xfffff
    800024f2:	8c4080e7          	jalr	-1852(ra) # 80000db2 <panic>
            break;
    800024f6:	aab5                	j	80002672 <handle_exception+0x27a>
            
        case CAUSE_BREAKPOINT:           // 3: 断点
            printf("\n=== Breakpoint ===\n");
    800024f8:	00002517          	auipc	a0,0x2
    800024fc:	ac050513          	add	a0,a0,-1344 # 80003fb8 <etext+0xfb8>
    80002500:	ffffe097          	auipc	ra,0xffffe
    80002504:	50c080e7          	jalr	1292(ra) # 80000a0c <printf>
            printf("PC: %p\n", (void*)tf->sepc);
    80002508:	fc843783          	ld	a5,-56(s0)
    8000250c:	7ffc                	ld	a5,248(a5)
    8000250e:	85be                	mv	a1,a5
    80002510:	00002517          	auipc	a0,0x2
    80002514:	8a050513          	add	a0,a0,-1888 # 80003db0 <etext+0xdb0>
    80002518:	ffffe097          	auipc	ra,0xffffe
    8000251c:	4f4080e7          	jalr	1268(ra) # 80000a0c <printf>
            // 跳过 ebreak 指令（2字节压缩指令）
            tf->sepc += 2;
    80002520:	fc843783          	ld	a5,-56(s0)
    80002524:	7ffc                	ld	a5,248(a5)
    80002526:	00278713          	add	a4,a5,2
    8000252a:	fc843783          	ld	a5,-56(s0)
    8000252e:	fff8                	sd	a4,248(a5)
            printf("Breakpoint handled, continuing from %p\n", (void*)tf->sepc);
    80002530:	fc843783          	ld	a5,-56(s0)
    80002534:	7ffc                	ld	a5,248(a5)
    80002536:	85be                	mv	a1,a5
    80002538:	00002517          	auipc	a0,0x2
    8000253c:	a9850513          	add	a0,a0,-1384 # 80003fd0 <etext+0xfd0>
    80002540:	ffffe097          	auipc	ra,0xffffe
    80002544:	4cc080e7          	jalr	1228(ra) # 80000a0c <printf>
            break;
    80002548:	a22d                	j	80002672 <handle_exception+0x27a>
            
        case CAUSE_MISALIGNED_FETCH:     // 0: 指令地址未对齐
            printf("\n=== Misaligned Instruction Fetch ===\n");
    8000254a:	00002517          	auipc	a0,0x2
    8000254e:	aae50513          	add	a0,a0,-1362 # 80003ff8 <etext+0xff8>
    80002552:	ffffe097          	auipc	ra,0xffffe
    80002556:	4ba080e7          	jalr	1210(ra) # 80000a0c <printf>
            printf("Address: %p\n", (void*)r_stval());
    8000255a:	00000097          	auipc	ra,0x0
    8000255e:	990080e7          	jalr	-1648(ra) # 80001eea <r_stval>
    80002562:	87aa                	mv	a5,a0
    80002564:	85be                	mv	a1,a5
    80002566:	00002517          	auipc	a0,0x2
    8000256a:	aba50513          	add	a0,a0,-1350 # 80004020 <etext+0x1020>
    8000256e:	ffffe097          	auipc	ra,0xffffe
    80002572:	49e080e7          	jalr	1182(ra) # 80000a0c <printf>
            panic("Misaligned instruction fetch");
    80002576:	00002517          	auipc	a0,0x2
    8000257a:	aba50513          	add	a0,a0,-1350 # 80004030 <etext+0x1030>
    8000257e:	fffff097          	auipc	ra,0xfffff
    80002582:	834080e7          	jalr	-1996(ra) # 80000db2 <panic>
            break;
    80002586:	a0f5                	j	80002672 <handle_exception+0x27a>
            
        case CAUSE_MISALIGNED_LOAD:      // 4: 加载地址未对齐
            printf("\n=== Misaligned Load ===\n");
    80002588:	00002517          	auipc	a0,0x2
    8000258c:	ac850513          	add	a0,a0,-1336 # 80004050 <etext+0x1050>
    80002590:	ffffe097          	auipc	ra,0xffffe
    80002594:	47c080e7          	jalr	1148(ra) # 80000a0c <printf>
            printf("Address: %p\n", (void*)r_stval());
    80002598:	00000097          	auipc	ra,0x0
    8000259c:	952080e7          	jalr	-1710(ra) # 80001eea <r_stval>
    800025a0:	87aa                	mv	a5,a0
    800025a2:	85be                	mv	a1,a5
    800025a4:	00002517          	auipc	a0,0x2
    800025a8:	a7c50513          	add	a0,a0,-1412 # 80004020 <etext+0x1020>
    800025ac:	ffffe097          	auipc	ra,0xffffe
    800025b0:	460080e7          	jalr	1120(ra) # 80000a0c <printf>
            panic("Misaligned load");
    800025b4:	00002517          	auipc	a0,0x2
    800025b8:	abc50513          	add	a0,a0,-1348 # 80004070 <etext+0x1070>
    800025bc:	ffffe097          	auipc	ra,0xffffe
    800025c0:	7f6080e7          	jalr	2038(ra) # 80000db2 <panic>
            break;
    800025c4:	a07d                	j	80002672 <handle_exception+0x27a>
            
        case CAUSE_MISALIGNED_STORE:     // 6: 存储地址未对齐
            printf("\n=== Misaligned Store ===\n");
    800025c6:	00002517          	auipc	a0,0x2
    800025ca:	aba50513          	add	a0,a0,-1350 # 80004080 <etext+0x1080>
    800025ce:	ffffe097          	auipc	ra,0xffffe
    800025d2:	43e080e7          	jalr	1086(ra) # 80000a0c <printf>
            printf("Address: %p\n", (void*)r_stval());
    800025d6:	00000097          	auipc	ra,0x0
    800025da:	914080e7          	jalr	-1772(ra) # 80001eea <r_stval>
    800025de:	87aa                	mv	a5,a0
    800025e0:	85be                	mv	a1,a5
    800025e2:	00002517          	auipc	a0,0x2
    800025e6:	a3e50513          	add	a0,a0,-1474 # 80004020 <etext+0x1020>
    800025ea:	ffffe097          	auipc	ra,0xffffe
    800025ee:	422080e7          	jalr	1058(ra) # 80000a0c <printf>
            panic("Misaligned store");
    800025f2:	00002517          	auipc	a0,0x2
    800025f6:	aae50513          	add	a0,a0,-1362 # 800040a0 <etext+0x10a0>
    800025fa:	ffffe097          	auipc	ra,0xffffe
    800025fe:	7b8080e7          	jalr	1976(ra) # 80000db2 <panic>
            break;
    80002602:	a885                	j	80002672 <handle_exception+0x27a>
            
        default:
            printf("\n=== Unknown Exception ===\n");
    80002604:	00002517          	auipc	a0,0x2
    80002608:	ab450513          	add	a0,a0,-1356 # 800040b8 <etext+0x10b8>
    8000260c:	ffffe097          	auipc	ra,0xffffe
    80002610:	400080e7          	jalr	1024(ra) # 80000a0c <printf>
            printf("cause: %d\n", (int)cause);
    80002614:	fd843783          	ld	a5,-40(s0)
    80002618:	2781                	sext.w	a5,a5
    8000261a:	85be                	mv	a1,a5
    8000261c:	00002517          	auipc	a0,0x2
    80002620:	abc50513          	add	a0,a0,-1348 # 800040d8 <etext+0x10d8>
    80002624:	ffffe097          	auipc	ra,0xffffe
    80002628:	3e8080e7          	jalr	1000(ra) # 80000a0c <printf>
            printf("PC: %p\n", (void*)tf->sepc);
    8000262c:	fc843783          	ld	a5,-56(s0)
    80002630:	7ffc                	ld	a5,248(a5)
    80002632:	85be                	mv	a1,a5
    80002634:	00001517          	auipc	a0,0x1
    80002638:	77c50513          	add	a0,a0,1916 # 80003db0 <etext+0xdb0>
    8000263c:	ffffe097          	auipc	ra,0xffffe
    80002640:	3d0080e7          	jalr	976(ra) # 80000a0c <printf>
            printf("stval: %p\n", (void*)r_stval());
    80002644:	00000097          	auipc	ra,0x0
    80002648:	8a6080e7          	jalr	-1882(ra) # 80001eea <r_stval>
    8000264c:	87aa                	mv	a5,a0
    8000264e:	85be                	mv	a1,a5
    80002650:	00002517          	auipc	a0,0x2
    80002654:	a9850513          	add	a0,a0,-1384 # 800040e8 <etext+0x10e8>
    80002658:	ffffe097          	auipc	ra,0xffffe
    8000265c:	3b4080e7          	jalr	948(ra) # 80000a0c <printf>
            panic("Unknown exception");
    80002660:	00002517          	auipc	a0,0x2
    80002664:	a9850513          	add	a0,a0,-1384 # 800040f8 <etext+0x10f8>
    80002668:	ffffe097          	auipc	ra,0xffffe
    8000266c:	74a080e7          	jalr	1866(ra) # 80000db2 <panic>
    }
}
    80002670:	0001                	nop
    80002672:	0001                	nop
    80002674:	70e2                	ld	ra,56(sp)
    80002676:	7442                	ld	s0,48(sp)
    80002678:	74a2                	ld	s1,40(sp)
    8000267a:	6121                	add	sp,sp,64
    8000267c:	8082                	ret

000000008000267e <kerneltrap>:
// ==================== 内核态中断/异常处理入口 ====================
// 从kernelvec.S调用，此时trapframe已保存在内核栈上
// 修改 kerneltrap 函数签名
void kerneltrap(struct trapframe *tf)  // ← 添加参数
{
    8000267e:	7179                	add	sp,sp,-48
    80002680:	f406                	sd	ra,40(sp)
    80002682:	f022                	sd	s0,32(sp)
    80002684:	1800                	add	s0,sp,48
    80002686:	fca43c23          	sd	a0,-40(s0)
    uint64 sstatus = r_sstatus();
    8000268a:	fffff097          	auipc	ra,0xfffff
    8000268e:	7aa080e7          	jalr	1962(ra) # 80001e34 <r_sstatus>
    80002692:	fea43423          	sd	a0,-24(s0)
    
    // 安全检查
    if((sstatus & SSTATUS_SPP) == 0) {
    80002696:	fe843783          	ld	a5,-24(s0)
    8000269a:	1007f793          	and	a5,a5,256
    8000269e:	eb89                	bnez	a5,800026b0 <kerneltrap+0x32>
        panic("kerneltrap: not from supervisor mode");
    800026a0:	00002517          	auipc	a0,0x2
    800026a4:	ab050513          	add	a0,a0,-1360 # 80004150 <etext+0x1150>
    800026a8:	ffffe097          	auipc	ra,0xffffe
    800026ac:	70a080e7          	jalr	1802(ra) # 80000db2 <panic>
    }
    
    if(sstatus & SSTATUS_SIE) {
    800026b0:	fe843783          	ld	a5,-24(s0)
    800026b4:	8b89                	and	a5,a5,2
    800026b6:	cb89                	beqz	a5,800026c8 <kerneltrap+0x4a>
        panic("kerneltrap: interrupts enabled");
    800026b8:	00002517          	auipc	a0,0x2
    800026bc:	ac050513          	add	a0,a0,-1344 # 80004178 <etext+0x1178>
    800026c0:	ffffe097          	auipc	ra,0xffffe
    800026c4:	6f2080e7          	jalr	1778(ra) # 80000db2 <panic>
    }
    
    // 处理设备中断
    int is_device_interrupt = devintr();
    800026c8:	00000097          	auipc	ra,0x0
    800026cc:	99e080e7          	jalr	-1634(ra) # 80002066 <devintr>
    800026d0:	87aa                	mv	a5,a0
    800026d2:	fef42223          	sw	a5,-28(s0)
    
    if(!is_device_interrupt) {
    800026d6:	fe442783          	lw	a5,-28(s0)
    800026da:	2781                	sext.w	a5,a5
    800026dc:	e39d                	bnez	a5,80002702 <kerneltrap+0x84>
        // 异常处理
        exception_count++;
    800026de:	00008797          	auipc	a5,0x8
    800026e2:	9ba78793          	add	a5,a5,-1606 # 8000a098 <exception_count>
    800026e6:	639c                	ld	a5,0(a5)
    800026e8:	00178713          	add	a4,a5,1
    800026ec:	00008797          	auipc	a5,0x8
    800026f0:	9ac78793          	add	a5,a5,-1620 # 8000a098 <exception_count>
    800026f4:	e398                	sd	a4,0(a5)
        
        // 直接使用传入的 trapframe 指针（地址正确！）
        handle_exception(tf);
    800026f6:	fd843503          	ld	a0,-40(s0)
    800026fa:	00000097          	auipc	ra,0x0
    800026fe:	cfe080e7          	jalr	-770(ra) # 800023f8 <handle_exception>
        
        // 不需要写回sepc，kernelvec会自动从栈上恢复
    }
    
    w_sstatus(sstatus);
    80002702:	fe843503          	ld	a0,-24(s0)
    80002706:	fffff097          	auipc	ra,0xfffff
    8000270a:	748080e7          	jalr	1864(ra) # 80001e4e <w_sstatus>
}
    8000270e:	0001                	nop
    80002710:	70a2                	ld	ra,40(sp)
    80002712:	7402                	ld	s0,32(sp)
    80002714:	6145                	add	sp,sp,48
    80002716:	8082                	ret

0000000080002718 <trap_cause_name>:
// ==================== 辅助函数：获取异常/中断原因名称 ====================
const char* trap_cause_name(uint64 cause)
{
    80002718:	1101                	add	sp,sp,-32
    8000271a:	ec22                	sd	s0,24(sp)
    8000271c:	1000                	add	s0,sp,32
    8000271e:	fea43423          	sd	a0,-24(s0)
    // 检查是中断还是异常
    if(cause & 0x8000000000000000L) {
    80002722:	fe843783          	ld	a5,-24(s0)
    80002726:	0807d263          	bgez	a5,800027aa <trap_cause_name+0x92>
        // 中断
        cause = cause & 0xff;
    8000272a:	fe843783          	ld	a5,-24(s0)
    8000272e:	0ff7f793          	zext.b	a5,a5
    80002732:	fef43423          	sd	a5,-24(s0)
        switch(cause) {
    80002736:	fe843703          	ld	a4,-24(s0)
    8000273a:	47ad                	li	a5,11
    8000273c:	06e7e263          	bltu	a5,a4,800027a0 <trap_cause_name+0x88>
    80002740:	fe843783          	ld	a5,-24(s0)
    80002744:	00279713          	sll	a4,a5,0x2
    80002748:	00002797          	auipc	a5,0x2
    8000274c:	c5078793          	add	a5,a5,-944 # 80004398 <etext+0x1398>
    80002750:	97ba                	add	a5,a5,a4
    80002752:	439c                	lw	a5,0(a5)
    80002754:	0007871b          	sext.w	a4,a5
    80002758:	00002797          	auipc	a5,0x2
    8000275c:	c4078793          	add	a5,a5,-960 # 80004398 <etext+0x1398>
    80002760:	97ba                	add	a5,a5,a4
    80002762:	8782                	jr	a5
            case IRQ_S_SOFT: return "Supervisor software interrupt";
    80002764:	00002797          	auipc	a5,0x2
    80002768:	a3478793          	add	a5,a5,-1484 # 80004198 <etext+0x1198>
    8000276c:	a201                	j	8000286c <trap_cause_name+0x154>
            case IRQ_M_SOFT: return "Machine software interrupt";
    8000276e:	00002797          	auipc	a5,0x2
    80002772:	a4a78793          	add	a5,a5,-1462 # 800041b8 <etext+0x11b8>
    80002776:	a8dd                	j	8000286c <trap_cause_name+0x154>
            case IRQ_S_TIMER: return "Supervisor timer interrupt";
    80002778:	00002797          	auipc	a5,0x2
    8000277c:	a6078793          	add	a5,a5,-1440 # 800041d8 <etext+0x11d8>
    80002780:	a0f5                	j	8000286c <trap_cause_name+0x154>
            case IRQ_M_TIMER: return "Machine timer interrupt";
    80002782:	00002797          	auipc	a5,0x2
    80002786:	a7678793          	add	a5,a5,-1418 # 800041f8 <etext+0x11f8>
    8000278a:	a0cd                	j	8000286c <trap_cause_name+0x154>
            case IRQ_S_EXT: return "Supervisor external interrupt";
    8000278c:	00002797          	auipc	a5,0x2
    80002790:	a8478793          	add	a5,a5,-1404 # 80004210 <etext+0x1210>
    80002794:	a8e1                	j	8000286c <trap_cause_name+0x154>
            case IRQ_M_EXT: return "Machine external interrupt";
    80002796:	00002797          	auipc	a5,0x2
    8000279a:	a9a78793          	add	a5,a5,-1382 # 80004230 <etext+0x1230>
    8000279e:	a0f9                	j	8000286c <trap_cause_name+0x154>
            default: return "Unknown interrupt";
    800027a0:	00002797          	auipc	a5,0x2
    800027a4:	ab078793          	add	a5,a5,-1360 # 80004250 <etext+0x1250>
    800027a8:	a0d1                	j	8000286c <trap_cause_name+0x154>
        }
    } else {
        // 异常
        switch(cause) {
    800027aa:	fe843703          	ld	a4,-24(s0)
    800027ae:	47bd                	li	a5,15
    800027b0:	0ae7ea63          	bltu	a5,a4,80002864 <trap_cause_name+0x14c>
    800027b4:	fe843783          	ld	a5,-24(s0)
    800027b8:	00279713          	sll	a4,a5,0x2
    800027bc:	00002797          	auipc	a5,0x2
    800027c0:	c0c78793          	add	a5,a5,-1012 # 800043c8 <etext+0x13c8>
    800027c4:	97ba                	add	a5,a5,a4
    800027c6:	439c                	lw	a5,0(a5)
    800027c8:	0007871b          	sext.w	a4,a5
    800027cc:	00002797          	auipc	a5,0x2
    800027d0:	bfc78793          	add	a5,a5,-1028 # 800043c8 <etext+0x13c8>
    800027d4:	97ba                	add	a5,a5,a4
    800027d6:	8782                	jr	a5
            case CAUSE_MISALIGNED_FETCH: return "Instruction address misaligned";
    800027d8:	00002797          	auipc	a5,0x2
    800027dc:	a9078793          	add	a5,a5,-1392 # 80004268 <etext+0x1268>
    800027e0:	a071                	j	8000286c <trap_cause_name+0x154>
            case CAUSE_FETCH_ACCESS: return "Instruction access fault";
    800027e2:	00002797          	auipc	a5,0x2
    800027e6:	aa678793          	add	a5,a5,-1370 # 80004288 <etext+0x1288>
    800027ea:	a049                	j	8000286c <trap_cause_name+0x154>
            case CAUSE_ILLEGAL_INSTRUCTION: return "Illegal instruction";
    800027ec:	00001797          	auipc	a5,0x1
    800027f0:	7b478793          	add	a5,a5,1972 # 80003fa0 <etext+0xfa0>
    800027f4:	a8a5                	j	8000286c <trap_cause_name+0x154>
            case CAUSE_BREAKPOINT: return "Breakpoint";
    800027f6:	00002797          	auipc	a5,0x2
    800027fa:	ab278793          	add	a5,a5,-1358 # 800042a8 <etext+0x12a8>
    800027fe:	a0bd                	j	8000286c <trap_cause_name+0x154>
            case CAUSE_MISALIGNED_LOAD: return "Load address misaligned";
    80002800:	00002797          	auipc	a5,0x2
    80002804:	ab878793          	add	a5,a5,-1352 # 800042b8 <etext+0x12b8>
    80002808:	a095                	j	8000286c <trap_cause_name+0x154>
            case CAUSE_LOAD_ACCESS: return "Load access fault";
    8000280a:	00002797          	auipc	a5,0x2
    8000280e:	ac678793          	add	a5,a5,-1338 # 800042d0 <etext+0x12d0>
    80002812:	a8a9                	j	8000286c <trap_cause_name+0x154>
            case CAUSE_MISALIGNED_STORE: return "Store address misaligned";
    80002814:	00002797          	auipc	a5,0x2
    80002818:	ad478793          	add	a5,a5,-1324 # 800042e8 <etext+0x12e8>
    8000281c:	a881                	j	8000286c <trap_cause_name+0x154>
            case CAUSE_STORE_ACCESS: return "Store access fault";
    8000281e:	00002797          	auipc	a5,0x2
    80002822:	aea78793          	add	a5,a5,-1302 # 80004308 <etext+0x1308>
    80002826:	a099                	j	8000286c <trap_cause_name+0x154>
            case CAUSE_USER_ECALL: return "Environment call from U-mode";
    80002828:	00002797          	auipc	a5,0x2
    8000282c:	af878793          	add	a5,a5,-1288 # 80004320 <etext+0x1320>
    80002830:	a835                	j	8000286c <trap_cause_name+0x154>
            case CAUSE_SUPERVISOR_ECALL: return "Environment call from S-mode";
    80002832:	00002797          	auipc	a5,0x2
    80002836:	b0e78793          	add	a5,a5,-1266 # 80004340 <etext+0x1340>
    8000283a:	a80d                	j	8000286c <trap_cause_name+0x154>
            case CAUSE_MACHINE_ECALL: return "Environment call from M-mode";
    8000283c:	00002797          	auipc	a5,0x2
    80002840:	b2478793          	add	a5,a5,-1244 # 80004360 <etext+0x1360>
    80002844:	a025                	j	8000286c <trap_cause_name+0x154>
            case CAUSE_FETCH_PAGE_FAULT: return "Instruction page fault";
    80002846:	00002797          	auipc	a5,0x2
    8000284a:	b3a78793          	add	a5,a5,-1222 # 80004380 <etext+0x1380>
    8000284e:	a839                	j	8000286c <trap_cause_name+0x154>
            case CAUSE_LOAD_PAGE_FAULT: return "Load page fault";
    80002850:	00001797          	auipc	a5,0x1
    80002854:	63878793          	add	a5,a5,1592 # 80003e88 <etext+0xe88>
    80002858:	a811                	j	8000286c <trap_cause_name+0x154>
            case CAUSE_STORE_PAGE_FAULT: return "Store page fault";
    8000285a:	00001797          	auipc	a5,0x1
    8000285e:	6ce78793          	add	a5,a5,1742 # 80003f28 <etext+0xf28>
    80002862:	a029                	j	8000286c <trap_cause_name+0x154>
            default: return "Unknown exception";
    80002864:	00002797          	auipc	a5,0x2
    80002868:	89478793          	add	a5,a5,-1900 # 800040f8 <etext+0x10f8>
        }
    }
}
    8000286c:	853e                	mv	a0,a5
    8000286e:	6462                	ld	s0,24(sp)
    80002870:	6105                	add	sp,sp,32
    80002872:	8082                	ret

0000000080002874 <dump_trapframe>:

// ==================== 打印trapframe内容（调试用） ====================
void dump_trapframe(struct trapframe *tf)
{
    80002874:	1101                	add	sp,sp,-32
    80002876:	ec06                	sd	ra,24(sp)
    80002878:	e822                	sd	s0,16(sp)
    8000287a:	1000                	add	s0,sp,32
    8000287c:	fea43423          	sd	a0,-24(s0)
    printf("=== Trapframe Dump ===\n");
    80002880:	00002517          	auipc	a0,0x2
    80002884:	b8850513          	add	a0,a0,-1144 # 80004408 <etext+0x1408>
    80002888:	ffffe097          	auipc	ra,0xffffe
    8000288c:	184080e7          	jalr	388(ra) # 80000a0c <printf>
    printf("ra:  %p  sp:  %p  gp:  %p  tp:  %p\n",
           (void*)tf->ra, (void*)tf->sp, (void*)tf->gp, (void*)tf->tp);
    80002890:	fe843783          	ld	a5,-24(s0)
    80002894:	639c                	ld	a5,0(a5)
    printf("ra:  %p  sp:  %p  gp:  %p  tp:  %p\n",
    80002896:	85be                	mv	a1,a5
           (void*)tf->ra, (void*)tf->sp, (void*)tf->gp, (void*)tf->tp);
    80002898:	fe843783          	ld	a5,-24(s0)
    8000289c:	679c                	ld	a5,8(a5)
    printf("ra:  %p  sp:  %p  gp:  %p  tp:  %p\n",
    8000289e:	863e                	mv	a2,a5
           (void*)tf->ra, (void*)tf->sp, (void*)tf->gp, (void*)tf->tp);
    800028a0:	fe843783          	ld	a5,-24(s0)
    800028a4:	6b9c                	ld	a5,16(a5)
    printf("ra:  %p  sp:  %p  gp:  %p  tp:  %p\n",
    800028a6:	86be                	mv	a3,a5
           (void*)tf->ra, (void*)tf->sp, (void*)tf->gp, (void*)tf->tp);
    800028a8:	fe843783          	ld	a5,-24(s0)
    800028ac:	6f9c                	ld	a5,24(a5)
    printf("ra:  %p  sp:  %p  gp:  %p  tp:  %p\n",
    800028ae:	873e                	mv	a4,a5
    800028b0:	00002517          	auipc	a0,0x2
    800028b4:	b7050513          	add	a0,a0,-1168 # 80004420 <etext+0x1420>
    800028b8:	ffffe097          	auipc	ra,0xffffe
    800028bc:	154080e7          	jalr	340(ra) # 80000a0c <printf>
    printf("t0:  %p  t1:  %p  t2:  %p\n",
           (void*)tf->t0, (void*)tf->t1, (void*)tf->t2);
    800028c0:	fe843783          	ld	a5,-24(s0)
    800028c4:	739c                	ld	a5,32(a5)
    printf("t0:  %p  t1:  %p  t2:  %p\n",
    800028c6:	873e                	mv	a4,a5
           (void*)tf->t0, (void*)tf->t1, (void*)tf->t2);
    800028c8:	fe843783          	ld	a5,-24(s0)
    800028cc:	779c                	ld	a5,40(a5)
    printf("t0:  %p  t1:  %p  t2:  %p\n",
    800028ce:	863e                	mv	a2,a5
           (void*)tf->t0, (void*)tf->t1, (void*)tf->t2);
    800028d0:	fe843783          	ld	a5,-24(s0)
    800028d4:	7b9c                	ld	a5,48(a5)
    printf("t0:  %p  t1:  %p  t2:  %p\n",
    800028d6:	86be                	mv	a3,a5
    800028d8:	85ba                	mv	a1,a4
    800028da:	00002517          	auipc	a0,0x2
    800028de:	b6e50513          	add	a0,a0,-1170 # 80004448 <etext+0x1448>
    800028e2:	ffffe097          	auipc	ra,0xffffe
    800028e6:	12a080e7          	jalr	298(ra) # 80000a0c <printf>
    printf("s0:  %p  s1:  %p\n",
           (void*)tf->s0, (void*)tf->s1);
    800028ea:	fe843783          	ld	a5,-24(s0)
    800028ee:	7f9c                	ld	a5,56(a5)
    printf("s0:  %p  s1:  %p\n",
    800028f0:	873e                	mv	a4,a5
           (void*)tf->s0, (void*)tf->s1);
    800028f2:	fe843783          	ld	a5,-24(s0)
    800028f6:	63bc                	ld	a5,64(a5)
    printf("s0:  %p  s1:  %p\n",
    800028f8:	863e                	mv	a2,a5
    800028fa:	85ba                	mv	a1,a4
    800028fc:	00002517          	auipc	a0,0x2
    80002900:	b6c50513          	add	a0,a0,-1172 # 80004468 <etext+0x1468>
    80002904:	ffffe097          	auipc	ra,0xffffe
    80002908:	108080e7          	jalr	264(ra) # 80000a0c <printf>
    printf("a0:  %p  a1:  %p  a2:  %p  a3:  %p\n",
           (void*)tf->a0, (void*)tf->a1, (void*)tf->a2, (void*)tf->a3);
    8000290c:	fe843783          	ld	a5,-24(s0)
    80002910:	67bc                	ld	a5,72(a5)
    printf("a0:  %p  a1:  %p  a2:  %p  a3:  %p\n",
    80002912:	85be                	mv	a1,a5
           (void*)tf->a0, (void*)tf->a1, (void*)tf->a2, (void*)tf->a3);
    80002914:	fe843783          	ld	a5,-24(s0)
    80002918:	6bbc                	ld	a5,80(a5)
    printf("a0:  %p  a1:  %p  a2:  %p  a3:  %p\n",
    8000291a:	863e                	mv	a2,a5
           (void*)tf->a0, (void*)tf->a1, (void*)tf->a2, (void*)tf->a3);
    8000291c:	fe843783          	ld	a5,-24(s0)
    80002920:	6fbc                	ld	a5,88(a5)
    printf("a0:  %p  a1:  %p  a2:  %p  a3:  %p\n",
    80002922:	86be                	mv	a3,a5
           (void*)tf->a0, (void*)tf->a1, (void*)tf->a2, (void*)tf->a3);
    80002924:	fe843783          	ld	a5,-24(s0)
    80002928:	73bc                	ld	a5,96(a5)
    printf("a0:  %p  a1:  %p  a2:  %p  a3:  %p\n",
    8000292a:	873e                	mv	a4,a5
    8000292c:	00002517          	auipc	a0,0x2
    80002930:	b5450513          	add	a0,a0,-1196 # 80004480 <etext+0x1480>
    80002934:	ffffe097          	auipc	ra,0xffffe
    80002938:	0d8080e7          	jalr	216(ra) # 80000a0c <printf>
    printf("a4:  %p  a5:  %p  a6:  %p  a7:  %p\n",
           (void*)tf->a4, (void*)tf->a5, (void*)tf->a6, (void*)tf->a7);
    8000293c:	fe843783          	ld	a5,-24(s0)
    80002940:	77bc                	ld	a5,104(a5)
    printf("a4:  %p  a5:  %p  a6:  %p  a7:  %p\n",
    80002942:	85be                	mv	a1,a5
           (void*)tf->a4, (void*)tf->a5, (void*)tf->a6, (void*)tf->a7);
    80002944:	fe843783          	ld	a5,-24(s0)
    80002948:	7bbc                	ld	a5,112(a5)
    printf("a4:  %p  a5:  %p  a6:  %p  a7:  %p\n",
    8000294a:	863e                	mv	a2,a5
           (void*)tf->a4, (void*)tf->a5, (void*)tf->a6, (void*)tf->a7);
    8000294c:	fe843783          	ld	a5,-24(s0)
    80002950:	7fbc                	ld	a5,120(a5)
    printf("a4:  %p  a5:  %p  a6:  %p  a7:  %p\n",
    80002952:	86be                	mv	a3,a5
           (void*)tf->a4, (void*)tf->a5, (void*)tf->a6, (void*)tf->a7);
    80002954:	fe843783          	ld	a5,-24(s0)
    80002958:	63dc                	ld	a5,128(a5)
    printf("a4:  %p  a5:  %p  a6:  %p  a7:  %p\n",
    8000295a:	873e                	mv	a4,a5
    8000295c:	00002517          	auipc	a0,0x2
    80002960:	b4c50513          	add	a0,a0,-1204 # 800044a8 <etext+0x14a8>
    80002964:	ffffe097          	auipc	ra,0xffffe
    80002968:	0a8080e7          	jalr	168(ra) # 80000a0c <printf>
    printf("sepc: %p  sstatus: %p\n",
           (void*)tf->sepc, (void*)tf->sstatus);
    8000296c:	fe843783          	ld	a5,-24(s0)
    80002970:	7ffc                	ld	a5,248(a5)
    printf("sepc: %p  sstatus: %p\n",
    80002972:	873e                	mv	a4,a5
           (void*)tf->sepc, (void*)tf->sstatus);
    80002974:	fe843783          	ld	a5,-24(s0)
    80002978:	1007b783          	ld	a5,256(a5)
    printf("sepc: %p  sstatus: %p\n",
    8000297c:	863e                	mv	a2,a5
    8000297e:	85ba                	mv	a1,a4
    80002980:	00002517          	auipc	a0,0x2
    80002984:	b5050513          	add	a0,a0,-1200 # 800044d0 <etext+0x14d0>
    80002988:	ffffe097          	auipc	ra,0xffffe
    8000298c:	084080e7          	jalr	132(ra) # 80000a0c <printf>
    printf("===================\n");
    80002990:	00002517          	auipc	a0,0x2
    80002994:	b5850513          	add	a0,a0,-1192 # 800044e8 <etext+0x14e8>
    80002998:	ffffe097          	auipc	ra,0xffffe
    8000299c:	074080e7          	jalr	116(ra) # 80000a0c <printf>
}
    800029a0:	0001                	nop
    800029a2:	60e2                	ld	ra,24(sp)
    800029a4:	6442                	ld	s0,16(sp)
    800029a6:	6105                	add	sp,sp,32
    800029a8:	8082                	ret

00000000800029aa <print_trap_stats>:

// ==================== 中断统计信息 ====================
void print_trap_stats(void)
{
    800029aa:	1141                	add	sp,sp,-16
    800029ac:	e406                	sd	ra,8(sp)
    800029ae:	e022                	sd	s0,0(sp)
    800029b0:	0800                	add	s0,sp,16
    printf("\n=== Trap Statistics ===\n");
    800029b2:	00002517          	auipc	a0,0x2
    800029b6:	b4e50513          	add	a0,a0,-1202 # 80004500 <etext+0x1500>
    800029ba:	ffffe097          	auipc	ra,0xffffe
    800029be:	052080e7          	jalr	82(ra) # 80000a0c <printf>
    printf("Timer interrupts:    %d\n", (int)interrupt_counts[IRQ_S_TIMER]);
    800029c2:	00007797          	auipc	a5,0x7
    800029c6:	65678793          	add	a5,a5,1622 # 8000a018 <interrupt_counts>
    800029ca:	779c                	ld	a5,40(a5)
    800029cc:	2781                	sext.w	a5,a5
    800029ce:	85be                	mv	a1,a5
    800029d0:	00002517          	auipc	a0,0x2
    800029d4:	b5050513          	add	a0,a0,-1200 # 80004520 <etext+0x1520>
    800029d8:	ffffe097          	auipc	ra,0xffffe
    800029dc:	034080e7          	jalr	52(ra) # 80000a0c <printf>
    printf("Software interrupts: %d\n", (int)interrupt_counts[IRQ_S_SOFT]);
    800029e0:	00007797          	auipc	a5,0x7
    800029e4:	63878793          	add	a5,a5,1592 # 8000a018 <interrupt_counts>
    800029e8:	679c                	ld	a5,8(a5)
    800029ea:	2781                	sext.w	a5,a5
    800029ec:	85be                	mv	a1,a5
    800029ee:	00002517          	auipc	a0,0x2
    800029f2:	b5250513          	add	a0,a0,-1198 # 80004540 <etext+0x1540>
    800029f6:	ffffe097          	auipc	ra,0xffffe
    800029fa:	016080e7          	jalr	22(ra) # 80000a0c <printf>
    printf("External interrupts: %d\n", (int)interrupt_counts[IRQ_S_EXT]);
    800029fe:	00007797          	auipc	a5,0x7
    80002a02:	61a78793          	add	a5,a5,1562 # 8000a018 <interrupt_counts>
    80002a06:	67bc                	ld	a5,72(a5)
    80002a08:	2781                	sext.w	a5,a5
    80002a0a:	85be                	mv	a1,a5
    80002a0c:	00002517          	auipc	a0,0x2
    80002a10:	b5450513          	add	a0,a0,-1196 # 80004560 <etext+0x1560>
    80002a14:	ffffe097          	auipc	ra,0xffffe
    80002a18:	ff8080e7          	jalr	-8(ra) # 80000a0c <printf>
    printf("Exceptions:          %d\n", (int)exception_count);
    80002a1c:	00007797          	auipc	a5,0x7
    80002a20:	67c78793          	add	a5,a5,1660 # 8000a098 <exception_count>
    80002a24:	639c                	ld	a5,0(a5)
    80002a26:	2781                	sext.w	a5,a5
    80002a28:	85be                	mv	a1,a5
    80002a2a:	00002517          	auipc	a0,0x2
    80002a2e:	b5650513          	add	a0,a0,-1194 # 80004580 <etext+0x1580>
    80002a32:	ffffe097          	auipc	ra,0xffffe
    80002a36:	fda080e7          	jalr	-38(ra) # 80000a0c <printf>
    printf("====================\n");
    80002a3a:	00002517          	auipc	a0,0x2
    80002a3e:	b6650513          	add	a0,a0,-1178 # 800045a0 <etext+0x15a0>
    80002a42:	ffffe097          	auipc	ra,0xffffe
    80002a46:	fca080e7          	jalr	-54(ra) # 80000a0c <printf>
    80002a4a:	0001                	nop
    80002a4c:	60a2                	ld	ra,8(sp)
    80002a4e:	6402                	ld	s0,0(sp)
    80002a50:	0141                	add	sp,sp,16
    80002a52:	8082                	ret
	...

0000000080002a60 <kernelvec>:
.globl kernelvec

.align 4
kernelvec:
    # ========== 分配栈空间 ==========
    addi sp, sp, -264
    80002a60:	ef810113          	add	sp,sp,-264

    # ========== 保存所有寄存器（除sp）==========
    sd ra, 0(sp)
    80002a64:	e006                	sd	ra,0(sp)
    sd gp, 16(sp)
    80002a66:	e80e                	sd	gp,16(sp)
    sd tp, 24(sp)
    80002a68:	ec12                	sd	tp,24(sp)
    sd t0, 32(sp)
    80002a6a:	f016                	sd	t0,32(sp)
    sd t1, 40(sp)
    80002a6c:	f41a                	sd	t1,40(sp)
    sd t2, 48(sp)
    80002a6e:	f81e                	sd	t2,48(sp)
    sd s0, 56(sp)
    80002a70:	fc22                	sd	s0,56(sp)
    sd s1, 64(sp)
    80002a72:	e0a6                	sd	s1,64(sp)
    sd a0, 72(sp)
    80002a74:	e4aa                	sd	a0,72(sp)
    sd a1, 80(sp)
    80002a76:	e8ae                	sd	a1,80(sp)
    sd a2, 88(sp)
    80002a78:	ecb2                	sd	a2,88(sp)
    sd a3, 96(sp)
    80002a7a:	f0b6                	sd	a3,96(sp)
    sd a4, 104(sp)
    80002a7c:	f4ba                	sd	a4,104(sp)
    sd a5, 112(sp)
    80002a7e:	f8be                	sd	a5,112(sp)
    sd a6, 120(sp)
    80002a80:	fcc2                	sd	a6,120(sp)
    sd a7, 128(sp)
    80002a82:	e146                	sd	a7,128(sp)
    sd s2, 136(sp)
    80002a84:	e54a                	sd	s2,136(sp)
    sd s3, 144(sp)
    80002a86:	e94e                	sd	s3,144(sp)
    sd s4, 152(sp)
    80002a88:	ed52                	sd	s4,152(sp)
    sd s5, 160(sp)
    80002a8a:	f156                	sd	s5,160(sp)
    sd s6, 168(sp)
    80002a8c:	f55a                	sd	s6,168(sp)
    sd s7, 176(sp)
    80002a8e:	f95e                	sd	s7,176(sp)
    sd s8, 184(sp)
    80002a90:	fd62                	sd	s8,184(sp)
    sd s9, 192(sp)
    80002a92:	e1e6                	sd	s9,192(sp)
    sd s10, 200(sp)
    80002a94:	e5ea                	sd	s10,200(sp)
    sd s11, 208(sp)
    80002a96:	e9ee                	sd	s11,208(sp)
    sd t3, 216(sp)
    80002a98:	edf2                	sd	t3,216(sp)
    sd t4, 224(sp)
    80002a9a:	f1f6                	sd	t4,224(sp)
    sd t5, 232(sp)
    80002a9c:	f5fa                	sd	t5,232(sp)
    sd t6, 240(sp)
    80002a9e:	f9fe                	sd	t6,240(sp)

    # ========== 保存 sepc 和 sstatus ==========
    csrr t0, sepc
    80002aa0:	141022f3          	csrr	t0,sepc
    sd t0, 248(sp)
    80002aa4:	fd96                	sd	t0,248(sp)
    
    csrr t1, sstatus
    80002aa6:	10002373          	csrr	t1,sstatus
    sd t1, 256(sp)
    80002aaa:	e21a                	sd	t1,256(sp)

    # ========== 保存原始 sp ==========
    addi t0, sp, 264
    80002aac:	10810293          	add	t0,sp,264
    sd t0, 8(sp)
    80002ab0:	e416                	sd	t0,8(sp)

    # ========== 关键：把 trapframe 地址作为参数传递 ==========
    # a0 = trapframe 地址（C函数的第一个参数）
    mv a0, sp
    80002ab2:	850a                	mv	a0,sp
    
    call kerneltrap
    80002ab4:	00000097          	auipc	ra,0x0
    80002ab8:	bca080e7          	jalr	-1078(ra) # 8000267e <kerneltrap>

    # ========== 恢复 sepc 和 sstatus ==========
    ld t0, 248(sp)
    80002abc:	72ee                	ld	t0,248(sp)
    csrw sepc, t0
    80002abe:	14129073          	csrw	sepc,t0
    
    ld t1, 256(sp)
    80002ac2:	6312                	ld	t1,256(sp)
    csrw sstatus, t1
    80002ac4:	10031073          	csrw	sstatus,t1

    # ========== 恢复所有寄存器 ==========
    ld ra, 0(sp)
    80002ac8:	6082                	ld	ra,0(sp)
    ld gp, 16(sp)
    80002aca:	61c2                	ld	gp,16(sp)
    ld tp, 24(sp)
    80002acc:	6262                	ld	tp,24(sp)
    ld t0, 32(sp)
    80002ace:	7282                	ld	t0,32(sp)
    ld t1, 40(sp)
    80002ad0:	7322                	ld	t1,40(sp)
    ld t2, 48(sp)
    80002ad2:	73c2                	ld	t2,48(sp)
    ld s0, 56(sp)
    80002ad4:	7462                	ld	s0,56(sp)
    ld s1, 64(sp)
    80002ad6:	6486                	ld	s1,64(sp)
    ld a0, 72(sp)
    80002ad8:	6526                	ld	a0,72(sp)
    ld a1, 80(sp)
    80002ada:	65c6                	ld	a1,80(sp)
    ld a2, 88(sp)
    80002adc:	6666                	ld	a2,88(sp)
    ld a3, 96(sp)
    80002ade:	7686                	ld	a3,96(sp)
    ld a4, 104(sp)
    80002ae0:	7726                	ld	a4,104(sp)
    ld a5, 112(sp)
    80002ae2:	77c6                	ld	a5,112(sp)
    ld a6, 120(sp)
    80002ae4:	7866                	ld	a6,120(sp)
    ld a7, 128(sp)
    80002ae6:	688a                	ld	a7,128(sp)
    ld s2, 136(sp)
    80002ae8:	692a                	ld	s2,136(sp)
    ld s3, 144(sp)
    80002aea:	69ca                	ld	s3,144(sp)
    ld s4, 152(sp)
    80002aec:	6a6a                	ld	s4,152(sp)
    ld s5, 160(sp)
    80002aee:	7a8a                	ld	s5,160(sp)
    ld s6, 168(sp)
    80002af0:	7b2a                	ld	s6,168(sp)
    ld s7, 176(sp)
    80002af2:	7bca                	ld	s7,176(sp)
    ld s8, 184(sp)
    80002af4:	7c6a                	ld	s8,184(sp)
    ld s9, 192(sp)
    80002af6:	6c8e                	ld	s9,192(sp)
    ld s10, 200(sp)
    80002af8:	6d2e                	ld	s10,200(sp)
    ld s11, 208(sp)
    80002afa:	6dce                	ld	s11,208(sp)
    ld t3, 216(sp)
    80002afc:	6e6e                	ld	t3,216(sp)
    ld t4, 224(sp)
    80002afe:	7e8e                	ld	t4,224(sp)
    ld t5, 232(sp)
    80002b00:	7f2e                	ld	t5,232(sp)
    ld t6, 240(sp)
    80002b02:	7fce                	ld	t6,240(sp)

    # ========== 恢复 sp 并返回 ==========
    addi sp, sp, 264
    80002b04:	10810113          	add	sp,sp,264
    80002b08:	10200073          	sret
    80002b0c:	00000013          	nop

0000000080002b10 <timervec>:

.globl timervec
.align 4
timervec:
    # 交换 a0 和 mscratch
    csrrw a0, mscratch, a0
    80002b10:	34051573          	csrrw	a0,mscratch,a0
    # 现在 a0 指向 timer_scratch 结构
    
    # 保存寄存器
    sd a1, 24(a0)
    80002b14:	ed0c                	sd	a1,24(a0)
    sd a2, 32(a0)
    80002b16:	f110                	sd	a2,32(a0)
    sd a3, 40(a0)
    80002b18:	f514                	sd	a3,40(a0)
    
    # 读取当前 mtime
    li a1, 0x200bff8
    80002b1a:	0200c5b7          	lui	a1,0x200c
    80002b1e:	35e1                	addw	a1,a1,-8 # 200bff8 <_start-0x7dff4008>
    ld a2, 0(a1)
    80002b20:	6190                	ld	a2,0(a1)
    
    # 加上时钟间隔
    ld a3, 0(a0)        # 读取 interval
    80002b22:	6114                	ld	a3,0(a0)
    add a2, a2, a3      # next_time = mtime + interval
    80002b24:	9636                	add	a2,a2,a3
    sd a2, 8(a0)        # 保存 next_time
    80002b26:	e510                	sd	a2,8(a0)
    
    # 设置 mtimecmp
    li a1, 0x2004000
    80002b28:	020045b7          	lui	a1,0x2004
    sd a2, 0(a1)
    80002b2c:	e190                	sd	a2,0(a1)
    
    # 触发 S 模式软件中断
    li a1, 2
    80002b2e:	4589                	li	a1,2
    csrw sip, a1
    80002b30:	14459073          	csrw	sip,a1
    
    # 恢复寄存器
    ld a3, 40(a0)
    80002b34:	7514                	ld	a3,40(a0)
    ld a2, 32(a0)
    80002b36:	7110                	ld	a2,32(a0)
    ld a1, 24(a0)
    80002b38:	6d0c                	ld	a1,24(a0)
    
    # 恢复 a0
    csrrw a0, mscratch, a0
    80002b3a:	34051573          	csrrw	a0,mscratch,a0
    
    80002b3e:	30200073          	mret
    80002b42:	0001                	nop
    80002b44:	00000013          	nop
    80002b48:	00000013          	nop
    80002b4c:	00000013          	nop

0000000080002b50 <w_mscratch>:
    80002b50:	1101                	add	sp,sp,-32
    80002b52:	ec22                	sd	s0,24(sp)
    80002b54:	1000                	add	s0,sp,32
    80002b56:	fea43423          	sd	a0,-24(s0)
    80002b5a:	fe843783          	ld	a5,-24(s0)
    80002b5e:	34079073          	csrw	mscratch,a5
    80002b62:	0001                	nop
    80002b64:	6462                	ld	s0,24(sp)
    80002b66:	6105                	add	sp,sp,32
    80002b68:	8082                	ret

0000000080002b6a <read_mtime>:
static inline uint64 read_mtime(void) {
    80002b6a:	1141                	add	sp,sp,-16
    80002b6c:	e422                	sd	s0,8(sp)
    80002b6e:	0800                	add	s0,sp,16
    return *(volatile uint64*)CLINT_MTIME;
    80002b70:	0200c7b7          	lui	a5,0x200c
    80002b74:	17e1                	add	a5,a5,-8 # 200bff8 <_start-0x7dff4008>
    80002b76:	639c                	ld	a5,0(a5)
}
    80002b78:	853e                	mv	a0,a5
    80002b7a:	6422                	ld	s0,8(sp)
    80002b7c:	0141                	add	sp,sp,16
    80002b7e:	8082                	ret

0000000080002b80 <write_mtimecmp>:
static inline void write_mtimecmp(uint64 value) {
    80002b80:	1101                	add	sp,sp,-32
    80002b82:	ec22                	sd	s0,24(sp)
    80002b84:	1000                	add	s0,sp,32
    80002b86:	fea43423          	sd	a0,-24(s0)
    *(volatile uint64*)CLINT_MTIMECMP = value;
    80002b8a:	020047b7          	lui	a5,0x2004
    80002b8e:	fe843703          	ld	a4,-24(s0)
    80002b92:	e398                	sd	a4,0(a5)
}
    80002b94:	0001                	nop
    80002b96:	6462                	ld	s0,24(sp)
    80002b98:	6105                	add	sp,sp,32
    80002b9a:	8082                	ret

0000000080002b9c <timer_init_hart>:
{
    80002b9c:	1101                	add	sp,sp,-32
    80002b9e:	ec06                	sd	ra,24(sp)
    80002ba0:	e822                	sd	s0,16(sp)
    80002ba2:	1000                	add	s0,sp,32
    timer_scratch0.interval = timer_interval;
    80002ba4:	00003797          	auipc	a5,0x3
    80002ba8:	45c78793          	add	a5,a5,1116 # 80006000 <timer_interval>
    80002bac:	6398                	ld	a4,0(a5)
    80002bae:	00007797          	auipc	a5,0x7
    80002bb2:	58278793          	add	a5,a5,1410 # 8000a130 <timer_scratch0>
    80002bb6:	e398                	sd	a4,0(a5)
    timer_scratch0.next_time = 0;
    80002bb8:	00007797          	auipc	a5,0x7
    80002bbc:	57878793          	add	a5,a5,1400 # 8000a130 <timer_scratch0>
    80002bc0:	0007b423          	sd	zero,8(a5)
    w_mscratch((uint64)&timer_scratch0);
    80002bc4:	00007797          	auipc	a5,0x7
    80002bc8:	56c78793          	add	a5,a5,1388 # 8000a130 <timer_scratch0>
    80002bcc:	853e                	mv	a0,a5
    80002bce:	00000097          	auipc	ra,0x0
    80002bd2:	f82080e7          	jalr	-126(ra) # 80002b50 <w_mscratch>
    uint64 mtime = read_mtime();
    80002bd6:	00000097          	auipc	ra,0x0
    80002bda:	f94080e7          	jalr	-108(ra) # 80002b6a <read_mtime>
    80002bde:	fea43423          	sd	a0,-24(s0)
    write_mtimecmp(mtime + timer_interval);
    80002be2:	00003797          	auipc	a5,0x3
    80002be6:	41e78793          	add	a5,a5,1054 # 80006000 <timer_interval>
    80002bea:	6398                	ld	a4,0(a5)
    80002bec:	fe843783          	ld	a5,-24(s0)
    80002bf0:	97ba                	add	a5,a5,a4
    80002bf2:	853e                	mv	a0,a5
    80002bf4:	00000097          	auipc	ra,0x0
    80002bf8:	f8c080e7          	jalr	-116(ra) # 80002b80 <write_mtimecmp>
}
    80002bfc:	0001                	nop
    80002bfe:	60e2                	ld	ra,24(sp)
    80002c00:	6442                	ld	s0,16(sp)
    80002c02:	6105                	add	sp,sp,32
    80002c04:	8082                	ret

0000000080002c06 <timer_interrupt>:
{
    80002c06:	1141                	add	sp,sp,-16
    80002c08:	e406                	sd	ra,8(sp)
    80002c0a:	e022                	sd	s0,0(sp)
    80002c0c:	0800                	add	s0,sp,16
    ticks++;
    80002c0e:	00007797          	auipc	a5,0x7
    80002c12:	51278793          	add	a5,a5,1298 # 8000a120 <ticks>
    80002c16:	639c                	ld	a5,0(a5)
    80002c18:	00178713          	add	a4,a5,1
    80002c1c:	00007797          	auipc	a5,0x7
    80002c20:	50478793          	add	a5,a5,1284 # 8000a120 <ticks>
    80002c24:	e398                	sd	a4,0(a5)
    if(ticks % TICKS_PER_SEC == 0) {
    80002c26:	00007797          	auipc	a5,0x7
    80002c2a:	4fa78793          	add	a5,a5,1274 # 8000a120 <ticks>
    80002c2e:	6398                	ld	a4,0(a5)
    80002c30:	47a9                	li	a5,10
    80002c32:	02f777b3          	remu	a5,a4,a5
    80002c36:	e39d                	bnez	a5,80002c5c <timer_interrupt+0x56>
        printf("[Timer] System uptime: %d seconds\n", (int)(ticks / TICKS_PER_SEC));
    80002c38:	00007797          	auipc	a5,0x7
    80002c3c:	4e878793          	add	a5,a5,1256 # 8000a120 <ticks>
    80002c40:	6398                	ld	a4,0(a5)
    80002c42:	47a9                	li	a5,10
    80002c44:	02f757b3          	divu	a5,a4,a5
    80002c48:	2781                	sext.w	a5,a5
    80002c4a:	85be                	mv	a1,a5
    80002c4c:	00002517          	auipc	a0,0x2
    80002c50:	96c50513          	add	a0,a0,-1684 # 800045b8 <etext+0x15b8>
    80002c54:	ffffe097          	auipc	ra,0xffffe
    80002c58:	db8080e7          	jalr	-584(ra) # 80000a0c <printf>
}
    80002c5c:	0001                	nop
    80002c5e:	60a2                	ld	ra,8(sp)
    80002c60:	6402                	ld	s0,0(sp)
    80002c62:	0141                	add	sp,sp,16
    80002c64:	8082                	ret

0000000080002c66 <get_ticks>:
{
    80002c66:	1141                	add	sp,sp,-16
    80002c68:	e422                	sd	s0,8(sp)
    80002c6a:	0800                	add	s0,sp,16
    return ticks;
    80002c6c:	00007797          	auipc	a5,0x7
    80002c70:	4b478793          	add	a5,a5,1204 # 8000a120 <ticks>
    80002c74:	639c                	ld	a5,0(a5)
}
    80002c76:	853e                	mv	a0,a5
    80002c78:	6422                	ld	s0,8(sp)
    80002c7a:	0141                	add	sp,sp,16
    80002c7c:	8082                	ret

0000000080002c7e <get_uptime_seconds>:
{
    80002c7e:	1141                	add	sp,sp,-16
    80002c80:	e422                	sd	s0,8(sp)
    80002c82:	0800                	add	s0,sp,16
    return ticks / TICKS_PER_SEC;
    80002c84:	00007797          	auipc	a5,0x7
    80002c88:	49c78793          	add	a5,a5,1180 # 8000a120 <ticks>
    80002c8c:	6398                	ld	a4,0(a5)
    80002c8e:	47a9                	li	a5,10
    80002c90:	02f757b3          	divu	a5,a4,a5
}
    80002c94:	853e                	mv	a0,a5
    80002c96:	6422                	ld	s0,8(sp)
    80002c98:	0141                	add	sp,sp,16
    80002c9a:	8082                	ret

0000000080002c9c <delay_ms>:
{
    80002c9c:	7179                	add	sp,sp,-48
    80002c9e:	f422                	sd	s0,40(sp)
    80002ca0:	1800                	add	s0,sp,48
    80002ca2:	fca43c23          	sd	a0,-40(s0)
    uint64 start = ticks;
    80002ca6:	00007797          	auipc	a5,0x7
    80002caa:	47a78793          	add	a5,a5,1146 # 8000a120 <ticks>
    80002cae:	639c                	ld	a5,0(a5)
    80002cb0:	fef43423          	sd	a5,-24(s0)
    uint64 target_ticks = (ms * TICKS_PER_SEC) / 1000;
    80002cb4:	fd843703          	ld	a4,-40(s0)
    80002cb8:	87ba                	mv	a5,a4
    80002cba:	078a                	sll	a5,a5,0x2
    80002cbc:	97ba                	add	a5,a5,a4
    80002cbe:	0786                	sll	a5,a5,0x1
    80002cc0:	873e                	mv	a4,a5
    80002cc2:	3e800793          	li	a5,1000
    80002cc6:	02f757b3          	divu	a5,a4,a5
    80002cca:	fef43023          	sd	a5,-32(s0)
    while((ticks - start) < target_ticks) {
    80002cce:	a011                	j	80002cd2 <delay_ms+0x36>
        asm volatile("nop");
    80002cd0:	0001                	nop
    while((ticks - start) < target_ticks) {
    80002cd2:	00007797          	auipc	a5,0x7
    80002cd6:	44e78793          	add	a5,a5,1102 # 8000a120 <ticks>
    80002cda:	6398                	ld	a4,0(a5)
    80002cdc:	fe843783          	ld	a5,-24(s0)
    80002ce0:	40f707b3          	sub	a5,a4,a5
    80002ce4:	fe043703          	ld	a4,-32(s0)
    80002ce8:	fee7e4e3          	bltu	a5,a4,80002cd0 <delay_ms+0x34>
}
    80002cec:	0001                	nop
    80002cee:	0001                	nop
    80002cf0:	7422                	ld	s0,40(sp)
    80002cf2:	6145                	add	sp,sp,48
    80002cf4:	8082                	ret

0000000080002cf6 <timer_init>:
{
    80002cf6:	1141                	add	sp,sp,-16
    80002cf8:	e406                	sd	ra,8(sp)
    80002cfa:	e022                	sd	s0,0(sp)
    80002cfc:	0800                	add	s0,sp,16
    printf("Initializing timer system...\n");
    80002cfe:	00002517          	auipc	a0,0x2
    80002d02:	8e250513          	add	a0,a0,-1822 # 800045e0 <etext+0x15e0>
    80002d06:	ffffe097          	auipc	ra,0xffffe
    80002d0a:	d06080e7          	jalr	-762(ra) # 80000a0c <printf>
    printf("Timer frequency: %d Hz\n", (int)TIMER_FREQ);
    80002d0e:	009897b7          	lui	a5,0x989
    80002d12:	68078593          	add	a1,a5,1664 # 989680 <_start-0x7f676980>
    80002d16:	00002517          	auipc	a0,0x2
    80002d1a:	8ea50513          	add	a0,a0,-1814 # 80004600 <etext+0x1600>
    80002d1e:	ffffe097          	auipc	ra,0xffffe
    80002d22:	cee080e7          	jalr	-786(ra) # 80000a0c <printf>
    printf("Interrupt interval: %d ms\n", (int)TIMER_INTERVAL_MS);
    80002d26:	06400593          	li	a1,100
    80002d2a:	00002517          	auipc	a0,0x2
    80002d2e:	8ee50513          	add	a0,a0,-1810 # 80004618 <etext+0x1618>
    80002d32:	ffffe097          	auipc	ra,0xffffe
    80002d36:	cda080e7          	jalr	-806(ra) # 80000a0c <printf>
    register_interrupt(IRQ_S_TIMER, timer_interrupt);
    80002d3a:	00000597          	auipc	a1,0x0
    80002d3e:	ecc58593          	add	a1,a1,-308 # 80002c06 <timer_interrupt>
    80002d42:	4515                	li	a0,5
    80002d44:	fffff097          	auipc	ra,0xfffff
    80002d48:	2ac080e7          	jalr	684(ra) # 80001ff0 <register_interrupt>
    printf("Timer system initialized\n");
    80002d4c:	00002517          	auipc	a0,0x2
    80002d50:	8ec50513          	add	a0,a0,-1812 # 80004638 <etext+0x1638>
    80002d54:	ffffe097          	auipc	ra,0xffffe
    80002d58:	cb8080e7          	jalr	-840(ra) # 80000a0c <printf>
    80002d5c:	0001                	nop
    80002d5e:	60a2                	ld	ra,8(sp)
    80002d60:	6402                	ld	s0,0(sp)
    80002d62:	0141                	add	sp,sp,16
    80002d64:	8082                	ret

0000000080002d66 <test_breakpoint>:
#include "riscv.h"
#include "trap.h"
#include "printf.h"

// ==================== 测试1：断点异常 ====================
static void test_breakpoint(void) {
    80002d66:	1141                	add	sp,sp,-16
    80002d68:	e406                	sd	ra,8(sp)
    80002d6a:	e022                	sd	s0,0(sp)
    80002d6c:	0800                	add	s0,sp,16
    printf("\n--- Test 1: Breakpoint Exception ---\n");
    80002d6e:	00002517          	auipc	a0,0x2
    80002d72:	8ea50513          	add	a0,a0,-1814 # 80004658 <etext+0x1658>
    80002d76:	ffffe097          	auipc	ra,0xffffe
    80002d7a:	c96080e7          	jalr	-874(ra) # 80000a0c <printf>
    printf("About to trigger breakpoint...\n");
    80002d7e:	00002517          	auipc	a0,0x2
    80002d82:	90250513          	add	a0,a0,-1790 # 80004680 <etext+0x1680>
    80002d86:	ffffe097          	auipc	ra,0xffffe
    80002d8a:	c86080e7          	jalr	-890(ra) # 80000a0c <printf>
    
    asm volatile("ebreak");
    80002d8e:	9002                	ebreak
    
    printf("Breakpoint handled successfully!\n");
    80002d90:	00002517          	auipc	a0,0x2
    80002d94:	91050513          	add	a0,a0,-1776 # 800046a0 <etext+0x16a0>
    80002d98:	ffffe097          	auipc	ra,0xffffe
    80002d9c:	c74080e7          	jalr	-908(ra) # 80000a0c <printf>
}
    80002da0:	0001                	nop
    80002da2:	60a2                	ld	ra,8(sp)
    80002da4:	6402                	ld	s0,0(sp)
    80002da6:	0141                	add	sp,sp,16
    80002da8:	8082                	ret

0000000080002daa <test_syscall>:

// ==================== 测试2：系统调用 ====================
static void test_syscall(void) {
    80002daa:	1141                	add	sp,sp,-16
    80002dac:	e406                	sd	ra,8(sp)
    80002dae:	e022                	sd	s0,0(sp)
    80002db0:	0800                	add	s0,sp,16
    printf("\n--- Test 2: System Call (ecall) ---\n");
    80002db2:	00002517          	auipc	a0,0x2
    80002db6:	91650513          	add	a0,a0,-1770 # 800046c8 <etext+0x16c8>
    80002dba:	ffffe097          	auipc	ra,0xffffe
    80002dbe:	c52080e7          	jalr	-942(ra) # 80000a0c <printf>
    printf("About to make a syscall...\n");
    80002dc2:	00002517          	auipc	a0,0x2
    80002dc6:	92e50513          	add	a0,a0,-1746 # 800046f0 <etext+0x16f0>
    80002dca:	ffffe097          	auipc	ra,0xffffe
    80002dce:	c42080e7          	jalr	-958(ra) # 80000a0c <printf>
    
    register uint64 a7 asm("a7") = 42;  // syscall number
    80002dd2:	02a00893          	li	a7,42
    register uint64 a0 asm("a0") = 100; // argument 1
    80002dd6:	06400513          	li	a0,100
    register uint64 a1 asm("a1") = 200; // argument 2
    80002dda:	0c800593          	li	a1,200
    
    asm volatile(
    80002dde:	00000073          	ecall
        : "+r"(a0)
        : "r"(a7), "r"(a1)
        : "memory"
    );
    
    printf("Syscall completed!\n");
    80002de2:	00002517          	auipc	a0,0x2
    80002de6:	92e50513          	add	a0,a0,-1746 # 80004710 <etext+0x1710>
    80002dea:	ffffe097          	auipc	ra,0xffffe
    80002dee:	c22080e7          	jalr	-990(ra) # 80000a0c <printf>
}
    80002df2:	0001                	nop
    80002df4:	60a2                	ld	ra,8(sp)
    80002df6:	6402                	ld	s0,0(sp)
    80002df8:	0141                	add	sp,sp,16
    80002dfa:	8082                	ret

0000000080002dfc <test_exception_handling>:
    printf("This line should not print\n");
}
#endif

// ==================== 主测试函数 ====================
void test_exception_handling(void) {
    80002dfc:	1141                	add	sp,sp,-16
    80002dfe:	e406                	sd	ra,8(sp)
    80002e00:	e022                	sd	s0,0(sp)
    80002e02:	0800                	add	s0,sp,16
    printf("\n");
    80002e04:	00002517          	auipc	a0,0x2
    80002e08:	92450513          	add	a0,a0,-1756 # 80004728 <etext+0x1728>
    80002e0c:	ffffe097          	auipc	ra,0xffffe
    80002e10:	c00080e7          	jalr	-1024(ra) # 80000a0c <printf>
    printf("========================================\n");
    80002e14:	00002517          	auipc	a0,0x2
    80002e18:	91c50513          	add	a0,a0,-1764 # 80004730 <etext+0x1730>
    80002e1c:	ffffe097          	auipc	ra,0xffffe
    80002e20:	bf0080e7          	jalr	-1040(ra) # 80000a0c <printf>
    printf("=== Exception Handling Test Suite ===\n");
    80002e24:	00002517          	auipc	a0,0x2
    80002e28:	93c50513          	add	a0,a0,-1732 # 80004760 <etext+0x1760>
    80002e2c:	ffffe097          	auipc	ra,0xffffe
    80002e30:	be0080e7          	jalr	-1056(ra) # 80000a0c <printf>
    printf("========================================\n");
    80002e34:	00002517          	auipc	a0,0x2
    80002e38:	8fc50513          	add	a0,a0,-1796 # 80004730 <etext+0x1730>
    80002e3c:	ffffe097          	auipc	ra,0xffffe
    80002e40:	bd0080e7          	jalr	-1072(ra) # 80000a0c <printf>
    
    // 测试1：断点（不会panic）
    test_breakpoint();
    80002e44:	00000097          	auipc	ra,0x0
    80002e48:	f22080e7          	jalr	-222(ra) # 80002d66 <test_breakpoint>
    
    // 测试2：系统调用（不会panic）
    test_syscall();
    80002e4c:	00000097          	auipc	ra,0x0
    80002e50:	f5e080e7          	jalr	-162(ra) # 80002daa <test_syscall>
    
    printf("\n=== Safe Tests Completed ===\n");
    80002e54:	00002517          	auipc	a0,0x2
    80002e58:	93450513          	add	a0,a0,-1740 # 80004788 <etext+0x1788>
    80002e5c:	ffffe097          	auipc	ra,0xffffe
    80002e60:	bb0080e7          	jalr	-1104(ra) # 80000a0c <printf>
    printf("\nDangerous tests are disabled by default.\n");
    80002e64:	00002517          	auipc	a0,0x2
    80002e68:	94450513          	add	a0,a0,-1724 # 800047a8 <etext+0x17a8>
    80002e6c:	ffffe097          	auipc	ra,0xffffe
    80002e70:	ba0080e7          	jalr	-1120(ra) # 80000a0c <printf>
    printf("To enable a test, edit exception_test.c and change\n");
    80002e74:	00002517          	auipc	a0,0x2
    80002e78:	96450513          	add	a0,a0,-1692 # 800047d8 <etext+0x17d8>
    80002e7c:	ffffe097          	auipc	ra,0xffffe
    80002e80:	b90080e7          	jalr	-1136(ra) # 80000a0c <printf>
    printf("the corresponding '#if 0' to '#if 1'\n\n");
    80002e84:	00002517          	auipc	a0,0x2
    80002e88:	98c50513          	add	a0,a0,-1652 # 80004810 <etext+0x1810>
    80002e8c:	ffffe097          	auipc	ra,0xffffe
    80002e90:	b80080e7          	jalr	-1152(ra) # 80000a0c <printf>

#if 0  // 改为 1 来启用
    test_misaligned_load();
#endif
    
    printf("=== Exception Tests Completed ===\n");
    80002e94:	00002517          	auipc	a0,0x2
    80002e98:	9a450513          	add	a0,a0,-1628 # 80004838 <etext+0x1838>
    80002e9c:	ffffe097          	auipc	ra,0xffffe
    80002ea0:	b70080e7          	jalr	-1168(ra) # 80000a0c <printf>
    80002ea4:	0001                	nop
    80002ea6:	60a2                	ld	ra,8(sp)
    80002ea8:	6402                	ld	s0,0(sp)
    80002eaa:	0141                	add	sp,sp,16
    80002eac:	8082                	ret
	...
