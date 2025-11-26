
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
    80000014:	00009297          	auipc	t0,0x9
    80000018:	fec28293          	add	t0,t0,-20 # 80009000 <bss_start>
    la t1, bss_end
    8000001c:	0000f317          	auipc	t1,0xf
    80000020:	3ec30313          	add	t1,t1,1004 # 8000f408 <bss_end>

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
    800001e4:	7ff78793          	add	a5,a5,2047 # ffffffffffffe7ff <kernel_pagetable+0xffffffff7ffee7f7>
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
    8000020a:	00001797          	auipc	a5,0x1
    8000020e:	a2e78793          	add	a5,a5,-1490 # 80000c38 <main>
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
    80000274:	10c080e7          	jalr	268(ra) # 8000337c <timer_init_hart>
    w_mtvec((uint64)timervec);
    80000278:	00003797          	auipc	a5,0x3
    8000027c:	07878793          	add	a5,a5,120 # 800032f0 <timervec>
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

00000000800002e4 <set_parent>:
static int tree_grandchild_pid  = -1;

// ==================== 工具函数：在内核里设置父子关系 ====================
// 由于我们现在用的是内核线程，没有真正的 fork，这里在 main 里手动建立父子关系
static void set_parent(int child_pid, int parent_pid)
{
    800002e4:	7139                	add	sp,sp,-64
    800002e6:	fc06                	sd	ra,56(sp)
    800002e8:	f822                	sd	s0,48(sp)
    800002ea:	0080                	add	s0,sp,64
    800002ec:	87aa                	mv	a5,a0
    800002ee:	872e                	mv	a4,a1
    800002f0:	fcf42623          	sw	a5,-52(s0)
    800002f4:	87ba                	mv	a5,a4
    800002f6:	fcf42423          	sw	a5,-56(s0)
    struct proc *p;
    struct proc *parent = 0;
    800002fa:	fe043023          	sd	zero,-32(s0)
    struct proc *child  = 0;
    800002fe:	fc043c23          	sd	zero,-40(s0)

    for (p = proc; p < &proc[NPROC]; p++) {
    80000302:	0000c797          	auipc	a5,0xc
    80000306:	e7e78793          	add	a5,a5,-386 # 8000c180 <proc>
    8000030a:	fef43423          	sd	a5,-24(s0)
    8000030e:	a83d                	j	8000034c <set_parent+0x68>
        if (p->pid == parent_pid) {
    80000310:	fe843783          	ld	a5,-24(s0)
    80000314:	4398                	lw	a4,0(a5)
    80000316:	fc842783          	lw	a5,-56(s0)
    8000031a:	2781                	sext.w	a5,a5
    8000031c:	00e79663          	bne	a5,a4,80000328 <set_parent+0x44>
            parent = p;
    80000320:	fe843783          	ld	a5,-24(s0)
    80000324:	fef43023          	sd	a5,-32(s0)
        }
        if (p->pid == child_pid) {
    80000328:	fe843783          	ld	a5,-24(s0)
    8000032c:	4398                	lw	a4,0(a5)
    8000032e:	fcc42783          	lw	a5,-52(s0)
    80000332:	2781                	sext.w	a5,a5
    80000334:	00e79663          	bne	a5,a4,80000340 <set_parent+0x5c>
            child = p;
    80000338:	fe843783          	ld	a5,-24(s0)
    8000033c:	fcf43c23          	sd	a5,-40(s0)
    for (p = proc; p < &proc[NPROC]; p++) {
    80000340:	fe843783          	ld	a5,-24(s0)
    80000344:	0c878793          	add	a5,a5,200
    80000348:	fef43423          	sd	a5,-24(s0)
    8000034c:	fe843703          	ld	a4,-24(s0)
    80000350:	0000f797          	auipc	a5,0xf
    80000354:	03078793          	add	a5,a5,48 # 8000f380 <cpus>
    80000358:	faf76ce3          	bltu	a4,a5,80000310 <set_parent+0x2c>
        }
    }

    if (parent && child) {
    8000035c:	fe043783          	ld	a5,-32(s0)
    80000360:	c3a1                	beqz	a5,800003a0 <set_parent+0xbc>
    80000362:	fd843783          	ld	a5,-40(s0)
    80000366:	cf8d                	beqz	a5,800003a0 <set_parent+0xbc>
        child->parent = parent;
    80000368:	fd843783          	ld	a5,-40(s0)
    8000036c:	fe043703          	ld	a4,-32(s0)
    80000370:	f3d8                	sd	a4,160(a5)
        printf("[main] Set parent of PID %d (%s) to PID %d (%s)\n",
    80000372:	fd843783          	ld	a5,-40(s0)
    80000376:	438c                	lw	a1,0(a5)
               child->pid, child->name, parent->pid, parent->name);
    80000378:	fd843783          	ld	a5,-40(s0)
    8000037c:	00878613          	add	a2,a5,8
        printf("[main] Set parent of PID %d (%s) to PID %d (%s)\n",
    80000380:	fe043783          	ld	a5,-32(s0)
    80000384:	4394                	lw	a3,0(a5)
               child->pid, child->name, parent->pid, parent->name);
    80000386:	fe043783          	ld	a5,-32(s0)
    8000038a:	07a1                	add	a5,a5,8
        printf("[main] Set parent of PID %d (%s) to PID %d (%s)\n",
    8000038c:	873e                	mv	a4,a5
    8000038e:	00005517          	auipc	a0,0x5
    80000392:	c7250513          	add	a0,a0,-910 # 80005000 <etext>
    80000396:	00001097          	auipc	ra,0x1
    8000039a:	e5c080e7          	jalr	-420(ra) # 800011f2 <printf>
    8000039e:	a005                	j	800003be <set_parent+0xda>
    } else {
        printf("[main] WARNING: failed to set parent (child=%d parent=%d)\n",
    800003a0:	fc842703          	lw	a4,-56(s0)
    800003a4:	fcc42783          	lw	a5,-52(s0)
    800003a8:	863a                	mv	a2,a4
    800003aa:	85be                	mv	a1,a5
    800003ac:	00005517          	auipc	a0,0x5
    800003b0:	c8c50513          	add	a0,a0,-884 # 80005038 <etext+0x38>
    800003b4:	00001097          	auipc	ra,0x1
    800003b8:	e3e080e7          	jalr	-450(ra) # 800011f2 <printf>
               child_pid, parent_pid);
    }
}
    800003bc:	0001                	nop
    800003be:	0001                	nop
    800003c0:	70e2                	ld	ra,56(sp)
    800003c2:	7442                	ld	s0,48(sp)
    800003c4:	6121                	add	sp,sp,64
    800003c6:	8082                	ret

00000000800003c8 <thread1>:

// ==================== 简单测试线程 ====================

// 线程1：打印数字
void thread1(void)
{
    800003c8:	1101                	add	sp,sp,-32
    800003ca:	ec06                	sd	ra,24(sp)
    800003cc:	e822                	sd	s0,16(sp)
    800003ce:	1000                	add	s0,sp,32
    for(int i = 0; i < 5; i++) {
    800003d0:	fe042623          	sw	zero,-20(s0)
    800003d4:	a02d                	j	800003fe <thread1+0x36>
        printf("[Thread1] Count: %d\n", i);
    800003d6:	fec42783          	lw	a5,-20(s0)
    800003da:	85be                	mv	a1,a5
    800003dc:	00005517          	auipc	a0,0x5
    800003e0:	c9c50513          	add	a0,a0,-868 # 80005078 <etext+0x78>
    800003e4:	00001097          	auipc	ra,0x1
    800003e8:	e0e080e7          	jalr	-498(ra) # 800011f2 <printf>
        yield();  // 主动让出CPU
    800003ec:	00003097          	auipc	ra,0x3
    800003f0:	71a080e7          	jalr	1818(ra) # 80003b06 <yield>
    for(int i = 0; i < 5; i++) {
    800003f4:	fec42783          	lw	a5,-20(s0)
    800003f8:	2785                	addw	a5,a5,1
    800003fa:	fef42623          	sw	a5,-20(s0)
    800003fe:	fec42783          	lw	a5,-20(s0)
    80000402:	0007871b          	sext.w	a4,a5
    80000406:	4791                	li	a5,4
    80000408:	fce7d7e3          	bge	a5,a4,800003d6 <thread1+0xe>
    }
    printf("[Thread1] Finished!\n");
    8000040c:	00005517          	auipc	a0,0x5
    80000410:	c8450513          	add	a0,a0,-892 # 80005090 <etext+0x90>
    80000414:	00001097          	auipc	ra,0x1
    80000418:	dde080e7          	jalr	-546(ra) # 800011f2 <printf>
    exit_proc(0);
    8000041c:	4501                	li	a0,0
    8000041e:	00004097          	auipc	ra,0x4
    80000422:	b78080e7          	jalr	-1160(ra) # 80003f96 <exit_proc>
}
    80000426:	0001                	nop
    80000428:	60e2                	ld	ra,24(sp)
    8000042a:	6442                	ld	s0,16(sp)
    8000042c:	6105                	add	sp,sp,32
    8000042e:	8082                	ret

0000000080000430 <thread2>:

// 线程2：打印字母
void thread2(void)
{
    80000430:	1101                	add	sp,sp,-32
    80000432:	ec06                	sd	ra,24(sp)
    80000434:	e822                	sd	s0,16(sp)
    80000436:	1000                	add	s0,sp,32
    char letters[] = "ABCDE";
    80000438:	444347b7          	lui	a5,0x44434
    8000043c:	24178793          	add	a5,a5,577 # 44434241 <_start-0x3bbcbdbf>
    80000440:	fef42023          	sw	a5,-32(s0)
    80000444:	04500793          	li	a5,69
    80000448:	fef41223          	sh	a5,-28(s0)
    for(int i = 0; i < 5; i++) {
    8000044c:	fe042623          	sw	zero,-20(s0)
    80000450:	a815                	j	80000484 <thread2+0x54>
        printf("[Thread2] Letter: %c\n", letters[i]);
    80000452:	fec42783          	lw	a5,-20(s0)
    80000456:	17c1                	add	a5,a5,-16
    80000458:	97a2                	add	a5,a5,s0
    8000045a:	ff07c783          	lbu	a5,-16(a5)
    8000045e:	2781                	sext.w	a5,a5
    80000460:	85be                	mv	a1,a5
    80000462:	00005517          	auipc	a0,0x5
    80000466:	c4650513          	add	a0,a0,-954 # 800050a8 <etext+0xa8>
    8000046a:	00001097          	auipc	ra,0x1
    8000046e:	d88080e7          	jalr	-632(ra) # 800011f2 <printf>
        yield();
    80000472:	00003097          	auipc	ra,0x3
    80000476:	694080e7          	jalr	1684(ra) # 80003b06 <yield>
    for(int i = 0; i < 5; i++) {
    8000047a:	fec42783          	lw	a5,-20(s0)
    8000047e:	2785                	addw	a5,a5,1
    80000480:	fef42623          	sw	a5,-20(s0)
    80000484:	fec42783          	lw	a5,-20(s0)
    80000488:	0007871b          	sext.w	a4,a5
    8000048c:	4791                	li	a5,4
    8000048e:	fce7d2e3          	bge	a5,a4,80000452 <thread2+0x22>
    }
    printf("[Thread2] Finished!\n");
    80000492:	00005517          	auipc	a0,0x5
    80000496:	c2e50513          	add	a0,a0,-978 # 800050c0 <etext+0xc0>
    8000049a:	00001097          	auipc	ra,0x1
    8000049e:	d58080e7          	jalr	-680(ra) # 800011f2 <printf>
    exit_proc(0);
    800004a2:	4501                	li	a0,0
    800004a4:	00004097          	auipc	ra,0x4
    800004a8:	af2080e7          	jalr	-1294(ra) # 80003f96 <exit_proc>
}
    800004ac:	0001                	nop
    800004ae:	60e2                	ld	ra,24(sp)
    800004b0:	6442                	ld	s0,16(sp)
    800004b2:	6105                	add	sp,sp,32
    800004b4:	8082                	ret

00000000800004b6 <thread3>:

// 线程3：计算密集型
void thread3(void)
{
    800004b6:	1101                	add	sp,sp,-32
    800004b8:	ec06                	sd	ra,24(sp)
    800004ba:	e822                	sd	s0,16(sp)
    800004bc:	1000                	add	s0,sp,32
    for(int i = 0; i < 3; i++) {
    800004be:	fe042623          	sw	zero,-20(s0)
    800004c2:	a0b5                	j	8000052e <thread3+0x78>
        volatile int sum = 0;
    800004c4:	fe042423          	sw	zero,-24(s0)
        for(volatile int j = 0; j < 1000000; j++) {
    800004c8:	fe042223          	sw	zero,-28(s0)
    800004cc:	a01d                	j	800004f2 <thread3+0x3c>
            sum += j;
    800004ce:	fe442783          	lw	a5,-28(s0)
    800004d2:	0007871b          	sext.w	a4,a5
    800004d6:	fe842783          	lw	a5,-24(s0)
    800004da:	2781                	sext.w	a5,a5
    800004dc:	9fb9                	addw	a5,a5,a4
    800004de:	2781                	sext.w	a5,a5
    800004e0:	fef42423          	sw	a5,-24(s0)
        for(volatile int j = 0; j < 1000000; j++) {
    800004e4:	fe442783          	lw	a5,-28(s0)
    800004e8:	2781                	sext.w	a5,a5
    800004ea:	2785                	addw	a5,a5,1
    800004ec:	2781                	sext.w	a5,a5
    800004ee:	fef42223          	sw	a5,-28(s0)
    800004f2:	fe442783          	lw	a5,-28(s0)
    800004f6:	2781                	sext.w	a5,a5
    800004f8:	873e                	mv	a4,a5
    800004fa:	000f47b7          	lui	a5,0xf4
    800004fe:	23f78793          	add	a5,a5,575 # f423f <_start-0x7ff0bdc1>
    80000502:	fce7d6e3          	bge	a5,a4,800004ce <thread3+0x18>
        }
        printf("[Thread3] Iteration %d completed\n", i);
    80000506:	fec42783          	lw	a5,-20(s0)
    8000050a:	85be                	mv	a1,a5
    8000050c:	00005517          	auipc	a0,0x5
    80000510:	bcc50513          	add	a0,a0,-1076 # 800050d8 <etext+0xd8>
    80000514:	00001097          	auipc	ra,0x1
    80000518:	cde080e7          	jalr	-802(ra) # 800011f2 <printf>
        yield();
    8000051c:	00003097          	auipc	ra,0x3
    80000520:	5ea080e7          	jalr	1514(ra) # 80003b06 <yield>
    for(int i = 0; i < 3; i++) {
    80000524:	fec42783          	lw	a5,-20(s0)
    80000528:	2785                	addw	a5,a5,1
    8000052a:	fef42623          	sw	a5,-20(s0)
    8000052e:	fec42783          	lw	a5,-20(s0)
    80000532:	0007871b          	sext.w	a4,a5
    80000536:	4789                	li	a5,2
    80000538:	f8e7d6e3          	bge	a5,a4,800004c4 <thread3+0xe>
    }
    printf("[Thread3] Finished!\n");
    8000053c:	00005517          	auipc	a0,0x5
    80000540:	bc450513          	add	a0,a0,-1084 # 80005100 <etext+0x100>
    80000544:	00001097          	auipc	ra,0x1
    80000548:	cae080e7          	jalr	-850(ra) # 800011f2 <printf>
    exit_proc(0);
    8000054c:	4501                	li	a0,0
    8000054e:	00004097          	auipc	ra,0x4
    80000552:	a48080e7          	jalr	-1464(ra) # 80003f96 <exit_proc>
}
    80000556:	0001                	nop
    80000558:	60e2                	ld	ra,24(sp)
    8000055a:	6442                	ld	s0,16(sp)
    8000055c:	6105                	add	sp,sp,32
    8000055e:	8082                	ret

0000000080000560 <producer_thread>:

// ==================== 同步机制测试：生产者-消费者 ====================

// 生产者线程
void producer_thread(void)
{
    80000560:	1101                	add	sp,sp,-32
    80000562:	ec06                	sd	ra,24(sp)
    80000564:	e822                	sd	s0,16(sp)
    80000566:	1000                	add	s0,sp,32
    printf("[Producer] Started\n");
    80000568:	00005517          	auipc	a0,0x5
    8000056c:	bb050513          	add	a0,a0,-1104 # 80005118 <etext+0x118>
    80000570:	00001097          	auipc	ra,0x1
    80000574:	c82080e7          	jalr	-894(ra) # 800011f2 <printf>
    
    for(int i = 0; i < 10; i++) {
    80000578:	fe042623          	sw	zero,-20(s0)
    8000057c:	a8ed                	j	80000676 <producer_thread+0x116>
        // 等待缓冲区有空间
        while(count >= BUFFER_SIZE) {
            printf("[Producer] Buffer full (count=%d), sleeping...\n", count);
    8000057e:	0000c797          	auipc	a5,0xc
    80000582:	a9678793          	add	a5,a5,-1386 # 8000c014 <count>
    80000586:	439c                	lw	a5,0(a5)
    80000588:	85be                	mv	a1,a5
    8000058a:	00005517          	auipc	a0,0x5
    8000058e:	ba650513          	add	a0,a0,-1114 # 80005130 <etext+0x130>
    80000592:	00001097          	auipc	ra,0x1
    80000596:	c60080e7          	jalr	-928(ra) # 800011f2 <printf>
            sleep(&count);  // 在count通道上睡眠
    8000059a:	0000c517          	auipc	a0,0xc
    8000059e:	a7a50513          	add	a0,a0,-1414 # 8000c014 <count>
    800005a2:	00003097          	auipc	ra,0x3
    800005a6:	7d6080e7          	jalr	2006(ra) # 80003d78 <sleep>
        while(count >= BUFFER_SIZE) {
    800005aa:	0000c797          	auipc	a5,0xc
    800005ae:	a6a78793          	add	a5,a5,-1430 # 8000c014 <count>
    800005b2:	439c                	lw	a5,0(a5)
    800005b4:	873e                	mv	a4,a5
    800005b6:	4791                	li	a5,4
    800005b8:	fce7c3e3          	blt	a5,a4,8000057e <producer_thread+0x1e>
        }
        
        // 生产一个项目
        buffer[count] = i;
    800005bc:	0000c797          	auipc	a5,0xc
    800005c0:	a5878793          	add	a5,a5,-1448 # 8000c014 <count>
    800005c4:	439c                	lw	a5,0(a5)
    800005c6:	0000c717          	auipc	a4,0xc
    800005ca:	a3a70713          	add	a4,a4,-1478 # 8000c000 <buffer>
    800005ce:	078a                	sll	a5,a5,0x2
    800005d0:	97ba                	add	a5,a5,a4
    800005d2:	fec42703          	lw	a4,-20(s0)
    800005d6:	c398                	sw	a4,0(a5)
        count++;
    800005d8:	0000c797          	auipc	a5,0xc
    800005dc:	a3c78793          	add	a5,a5,-1476 # 8000c014 <count>
    800005e0:	439c                	lw	a5,0(a5)
    800005e2:	2785                	addw	a5,a5,1
    800005e4:	0007871b          	sext.w	a4,a5
    800005e8:	0000c797          	auipc	a5,0xc
    800005ec:	a2c78793          	add	a5,a5,-1492 # 8000c014 <count>
    800005f0:	c398                	sw	a4,0(a5)
        produced++;
    800005f2:	0000c797          	auipc	a5,0xc
    800005f6:	a2678793          	add	a5,a5,-1498 # 8000c018 <produced>
    800005fa:	439c                	lw	a5,0(a5)
    800005fc:	2785                	addw	a5,a5,1
    800005fe:	0007871b          	sext.w	a4,a5
    80000602:	0000c797          	auipc	a5,0xc
    80000606:	a1678793          	add	a5,a5,-1514 # 8000c018 <produced>
    8000060a:	c398                	sw	a4,0(a5)
        printf("[Producer] Produced item %d (buffer count=%d)\n", i, count);
    8000060c:	0000c797          	auipc	a5,0xc
    80000610:	a0878793          	add	a5,a5,-1528 # 8000c014 <count>
    80000614:	4398                	lw	a4,0(a5)
    80000616:	fec42783          	lw	a5,-20(s0)
    8000061a:	863a                	mv	a2,a4
    8000061c:	85be                	mv	a1,a5
    8000061e:	00005517          	auipc	a0,0x5
    80000622:	b4250513          	add	a0,a0,-1214 # 80005160 <etext+0x160>
    80000626:	00001097          	auipc	ra,0x1
    8000062a:	bcc080e7          	jalr	-1076(ra) # 800011f2 <printf>
        
        // 唤醒可能在等待的消费者
        wakeup(&count);
    8000062e:	0000c517          	auipc	a0,0xc
    80000632:	9e650513          	add	a0,a0,-1562 # 8000c014 <count>
    80000636:	00003097          	auipc	ra,0x3
    8000063a:	7c6080e7          	jalr	1990(ra) # 80003dfc <wakeup>
        
        // 模拟生产耗时
        for(volatile int j = 0; j < 100000; j++);
    8000063e:	fe042423          	sw	zero,-24(s0)
    80000642:	a801                	j	80000652 <producer_thread+0xf2>
    80000644:	fe842783          	lw	a5,-24(s0)
    80000648:	2781                	sext.w	a5,a5
    8000064a:	2785                	addw	a5,a5,1
    8000064c:	2781                	sext.w	a5,a5
    8000064e:	fef42423          	sw	a5,-24(s0)
    80000652:	fe842783          	lw	a5,-24(s0)
    80000656:	2781                	sext.w	a5,a5
    80000658:	873e                	mv	a4,a5
    8000065a:	67e1                	lui	a5,0x18
    8000065c:	69f78793          	add	a5,a5,1695 # 1869f <_start-0x7ffe7961>
    80000660:	fee7d2e3          	bge	a5,a4,80000644 <producer_thread+0xe4>
        yield();
    80000664:	00003097          	auipc	ra,0x3
    80000668:	4a2080e7          	jalr	1186(ra) # 80003b06 <yield>
    for(int i = 0; i < 10; i++) {
    8000066c:	fec42783          	lw	a5,-20(s0)
    80000670:	2785                	addw	a5,a5,1
    80000672:	fef42623          	sw	a5,-20(s0)
    80000676:	fec42783          	lw	a5,-20(s0)
    8000067a:	0007871b          	sext.w	a4,a5
    8000067e:	47a5                	li	a5,9
    80000680:	f2e7d5e3          	bge	a5,a4,800005aa <producer_thread+0x4a>
    }
    
    printf("[Producer] Finished! Total produced: %d\n", produced);
    80000684:	0000c797          	auipc	a5,0xc
    80000688:	99478793          	add	a5,a5,-1644 # 8000c018 <produced>
    8000068c:	439c                	lw	a5,0(a5)
    8000068e:	85be                	mv	a1,a5
    80000690:	00005517          	auipc	a0,0x5
    80000694:	b0050513          	add	a0,a0,-1280 # 80005190 <etext+0x190>
    80000698:	00001097          	auipc	ra,0x1
    8000069c:	b5a080e7          	jalr	-1190(ra) # 800011f2 <printf>
    exit_proc(0);
    800006a0:	4501                	li	a0,0
    800006a2:	00004097          	auipc	ra,0x4
    800006a6:	8f4080e7          	jalr	-1804(ra) # 80003f96 <exit_proc>
}
    800006aa:	0001                	nop
    800006ac:	60e2                	ld	ra,24(sp)
    800006ae:	6442                	ld	s0,16(sp)
    800006b0:	6105                	add	sp,sp,32
    800006b2:	8082                	ret

00000000800006b4 <consumer_thread>:

// 消费者线程
void consumer_thread(void)
{
    800006b4:	1101                	add	sp,sp,-32
    800006b6:	ec06                	sd	ra,24(sp)
    800006b8:	e822                	sd	s0,16(sp)
    800006ba:	1000                	add	s0,sp,32
    printf("[Consumer] Started\n");
    800006bc:	00005517          	auipc	a0,0x5
    800006c0:	b0450513          	add	a0,a0,-1276 # 800051c0 <etext+0x1c0>
    800006c4:	00001097          	auipc	ra,0x1
    800006c8:	b2e080e7          	jalr	-1234(ra) # 800011f2 <printf>
    
    for(int i = 0; i < 10; i++) {
    800006cc:	fe042623          	sw	zero,-20(s0)
    800006d0:	a8e5                	j	800007c8 <consumer_thread+0x114>
        // 等待缓冲区有数据
        while(count <= 0) {
            printf("[Consumer] Buffer empty (count=%d), sleeping...\n", count);
    800006d2:	0000c797          	auipc	a5,0xc
    800006d6:	94278793          	add	a5,a5,-1726 # 8000c014 <count>
    800006da:	439c                	lw	a5,0(a5)
    800006dc:	85be                	mv	a1,a5
    800006de:	00005517          	auipc	a0,0x5
    800006e2:	afa50513          	add	a0,a0,-1286 # 800051d8 <etext+0x1d8>
    800006e6:	00001097          	auipc	ra,0x1
    800006ea:	b0c080e7          	jalr	-1268(ra) # 800011f2 <printf>
            sleep(&count);  // 在count通道上睡眠
    800006ee:	0000c517          	auipc	a0,0xc
    800006f2:	92650513          	add	a0,a0,-1754 # 8000c014 <count>
    800006f6:	00003097          	auipc	ra,0x3
    800006fa:	682080e7          	jalr	1666(ra) # 80003d78 <sleep>
        while(count <= 0) {
    800006fe:	0000c797          	auipc	a5,0xc
    80000702:	91678793          	add	a5,a5,-1770 # 8000c014 <count>
    80000706:	439c                	lw	a5,0(a5)
    80000708:	fcf055e3          	blez	a5,800006d2 <consumer_thread+0x1e>
        }
        
        // 消费一个项目
        count--;
    8000070c:	0000c797          	auipc	a5,0xc
    80000710:	90878793          	add	a5,a5,-1784 # 8000c014 <count>
    80000714:	439c                	lw	a5,0(a5)
    80000716:	37fd                	addw	a5,a5,-1
    80000718:	0007871b          	sext.w	a4,a5
    8000071c:	0000c797          	auipc	a5,0xc
    80000720:	8f878793          	add	a5,a5,-1800 # 8000c014 <count>
    80000724:	c398                	sw	a4,0(a5)
        int item = buffer[count];
    80000726:	0000c797          	auipc	a5,0xc
    8000072a:	8ee78793          	add	a5,a5,-1810 # 8000c014 <count>
    8000072e:	439c                	lw	a5,0(a5)
    80000730:	0000c717          	auipc	a4,0xc
    80000734:	8d070713          	add	a4,a4,-1840 # 8000c000 <buffer>
    80000738:	078a                	sll	a5,a5,0x2
    8000073a:	97ba                	add	a5,a5,a4
    8000073c:	439c                	lw	a5,0(a5)
    8000073e:	fef42423          	sw	a5,-24(s0)
        consumed++;
    80000742:	0000c797          	auipc	a5,0xc
    80000746:	8da78793          	add	a5,a5,-1830 # 8000c01c <consumed>
    8000074a:	439c                	lw	a5,0(a5)
    8000074c:	2785                	addw	a5,a5,1
    8000074e:	0007871b          	sext.w	a4,a5
    80000752:	0000c797          	auipc	a5,0xc
    80000756:	8ca78793          	add	a5,a5,-1846 # 8000c01c <consumed>
    8000075a:	c398                	sw	a4,0(a5)
        printf("[Consumer] Consumed item %d (buffer count=%d)\n", item, count);
    8000075c:	0000c797          	auipc	a5,0xc
    80000760:	8b878793          	add	a5,a5,-1864 # 8000c014 <count>
    80000764:	4398                	lw	a4,0(a5)
    80000766:	fe842783          	lw	a5,-24(s0)
    8000076a:	863a                	mv	a2,a4
    8000076c:	85be                	mv	a1,a5
    8000076e:	00005517          	auipc	a0,0x5
    80000772:	aa250513          	add	a0,a0,-1374 # 80005210 <etext+0x210>
    80000776:	00001097          	auipc	ra,0x1
    8000077a:	a7c080e7          	jalr	-1412(ra) # 800011f2 <printf>
        
        // 唤醒可能在等待的生产者
        wakeup(&count);
    8000077e:	0000c517          	auipc	a0,0xc
    80000782:	89650513          	add	a0,a0,-1898 # 8000c014 <count>
    80000786:	00003097          	auipc	ra,0x3
    8000078a:	676080e7          	jalr	1654(ra) # 80003dfc <wakeup>
        
        // 模拟消费耗时
        for(volatile int j = 0; j < 150000; j++);
    8000078e:	fe042223          	sw	zero,-28(s0)
    80000792:	a801                	j	800007a2 <consumer_thread+0xee>
    80000794:	fe442783          	lw	a5,-28(s0)
    80000798:	2781                	sext.w	a5,a5
    8000079a:	2785                	addw	a5,a5,1
    8000079c:	2781                	sext.w	a5,a5
    8000079e:	fef42223          	sw	a5,-28(s0)
    800007a2:	fe442783          	lw	a5,-28(s0)
    800007a6:	2781                	sext.w	a5,a5
    800007a8:	873e                	mv	a4,a5
    800007aa:	000257b7          	lui	a5,0x25
    800007ae:	9ef78793          	add	a5,a5,-1553 # 249ef <_start-0x7ffdb611>
    800007b2:	fee7d1e3          	bge	a5,a4,80000794 <consumer_thread+0xe0>
        yield();
    800007b6:	00003097          	auipc	ra,0x3
    800007ba:	350080e7          	jalr	848(ra) # 80003b06 <yield>
    for(int i = 0; i < 10; i++) {
    800007be:	fec42783          	lw	a5,-20(s0)
    800007c2:	2785                	addw	a5,a5,1
    800007c4:	fef42623          	sw	a5,-20(s0)
    800007c8:	fec42783          	lw	a5,-20(s0)
    800007cc:	0007871b          	sext.w	a4,a5
    800007d0:	47a5                	li	a5,9
    800007d2:	f2e7d6e3          	bge	a5,a4,800006fe <consumer_thread+0x4a>
    }
    
    printf("[Consumer] Finished! Total consumed: %d\n", consumed);
    800007d6:	0000c797          	auipc	a5,0xc
    800007da:	84678793          	add	a5,a5,-1978 # 8000c01c <consumed>
    800007de:	439c                	lw	a5,0(a5)
    800007e0:	85be                	mv	a1,a5
    800007e2:	00005517          	auipc	a0,0x5
    800007e6:	a5e50513          	add	a0,a0,-1442 # 80005240 <etext+0x240>
    800007ea:	00001097          	auipc	ra,0x1
    800007ee:	a08080e7          	jalr	-1528(ra) # 800011f2 <printf>
    exit_proc(0);
    800007f2:	4501                	li	a0,0
    800007f4:	00003097          	auipc	ra,0x3
    800007f8:	7a2080e7          	jalr	1954(ra) # 80003f96 <exit_proc>
}
    800007fc:	0001                	nop
    800007fe:	60e2                	ld	ra,24(sp)
    80000800:	6442                	ld	s0,16(sp)
    80000802:	6105                	add	sp,sp,32
    80000804:	8082                	ret

0000000080000806 <background_thread>:

// ==================== 调度器观察用线程 ====================

// 长时间运行的后台线程（保持原来的背景输出）
void background_thread(void)
{
    80000806:	1101                	add	sp,sp,-32
    80000808:	ec06                	sd	ra,24(sp)
    8000080a:	e822                	sd	s0,16(sp)
    8000080c:	1000                	add	s0,sp,32
    printf("[Background] Started\n");
    8000080e:	00005517          	auipc	a0,0x5
    80000812:	a6250513          	add	a0,a0,-1438 # 80005270 <etext+0x270>
    80000816:	00001097          	auipc	ra,0x1
    8000081a:	9dc080e7          	jalr	-1572(ra) # 800011f2 <printf>
    
    for(int i = 0; i < 20; i++) {
    8000081e:	fe042623          	sw	zero,-20(s0)
    80000822:	a089                	j	80000864 <background_thread+0x5e>
        printf("[Background] Tick %d\n", i);
    80000824:	fec42783          	lw	a5,-20(s0)
    80000828:	85be                	mv	a1,a5
    8000082a:	00005517          	auipc	a0,0x5
    8000082e:	a5e50513          	add	a0,a0,-1442 # 80005288 <etext+0x288>
    80000832:	00001097          	auipc	ra,0x1
    80000836:	9c0080e7          	jalr	-1600(ra) # 800011f2 <printf>
        
        // 每5次打印进程信息
        if(i % 5 == 0) {
    8000083a:	fec42783          	lw	a5,-20(s0)
    8000083e:	873e                	mv	a4,a5
    80000840:	4795                	li	a5,5
    80000842:	02f767bb          	remw	a5,a4,a5
    80000846:	2781                	sext.w	a5,a5
    80000848:	e789                	bnez	a5,80000852 <background_thread+0x4c>
            proc_info();
    8000084a:	00004097          	auipc	ra,0x4
    8000084e:	8cc080e7          	jalr	-1844(ra) # 80004116 <proc_info>
        }
        
        yield();
    80000852:	00003097          	auipc	ra,0x3
    80000856:	2b4080e7          	jalr	692(ra) # 80003b06 <yield>
    for(int i = 0; i < 20; i++) {
    8000085a:	fec42783          	lw	a5,-20(s0)
    8000085e:	2785                	addw	a5,a5,1
    80000860:	fef42623          	sw	a5,-20(s0)
    80000864:	fec42783          	lw	a5,-20(s0)
    80000868:	0007871b          	sext.w	a4,a5
    8000086c:	47cd                	li	a5,19
    8000086e:	fae7dbe3          	bge	a5,a4,80000824 <background_thread+0x1e>
    }
    
    printf("[Background] Finished!\n");
    80000872:	00005517          	auipc	a0,0x5
    80000876:	a2e50513          	add	a0,a0,-1490 # 800052a0 <etext+0x2a0>
    8000087a:	00001097          	auipc	ra,0x1
    8000087e:	978080e7          	jalr	-1672(ra) # 800011f2 <printf>
    exit_proc(0);
    80000882:	4501                	li	a0,0
    80000884:	00003097          	auipc	ra,0x3
    80000888:	712080e7          	jalr	1810(ra) # 80003f96 <exit_proc>
}
    8000088c:	0001                	nop
    8000088e:	60e2                	ld	ra,24(sp)
    80000890:	6442                	ld	s0,16(sp)
    80000892:	6105                	add	sp,sp,32
    80000894:	8082                	ret

0000000080000896 <tree_parent_thread>:

// ==================== 进程树演示：父/子/孙线程 ====================

void tree_parent_thread(void)
{
    80000896:	1101                	add	sp,sp,-32
    80000898:	ec06                	sd	ra,24(sp)
    8000089a:	e822                	sd	s0,16(sp)
    8000089c:	1000                	add	s0,sp,32
    printf("[PT-Parent] Started (PID %d)\n", myproc()->pid);
    8000089e:	00003097          	auipc	ra,0x3
    800008a2:	ed2080e7          	jalr	-302(ra) # 80003770 <myproc>
    800008a6:	87aa                	mv	a5,a0
    800008a8:	439c                	lw	a5,0(a5)
    800008aa:	85be                	mv	a1,a5
    800008ac:	00005517          	auipc	a0,0x5
    800008b0:	a0c50513          	add	a0,a0,-1524 # 800052b8 <etext+0x2b8>
    800008b4:	00001097          	auipc	ra,0x1
    800008b8:	93e080e7          	jalr	-1730(ra) # 800011f2 <printf>
    
    for (int i = 0; i < 50; i++) {
    800008bc:	fe042623          	sw	zero,-20(s0)
    800008c0:	a02d                	j	800008ea <tree_parent_thread+0x54>
        printf("[PT-Parent] Tick %d\n", i);
    800008c2:	fec42783          	lw	a5,-20(s0)
    800008c6:	85be                	mv	a1,a5
    800008c8:	00005517          	auipc	a0,0x5
    800008cc:	a1050513          	add	a0,a0,-1520 # 800052d8 <etext+0x2d8>
    800008d0:	00001097          	auipc	ra,0x1
    800008d4:	922080e7          	jalr	-1758(ra) # 800011f2 <printf>
        yield();
    800008d8:	00003097          	auipc	ra,0x3
    800008dc:	22e080e7          	jalr	558(ra) # 80003b06 <yield>
    for (int i = 0; i < 50; i++) {
    800008e0:	fec42783          	lw	a5,-20(s0)
    800008e4:	2785                	addw	a5,a5,1
    800008e6:	fef42623          	sw	a5,-20(s0)
    800008ea:	fec42783          	lw	a5,-20(s0)
    800008ee:	0007871b          	sext.w	a4,a5
    800008f2:	03100793          	li	a5,49
    800008f6:	fce7d6e3          	bge	a5,a4,800008c2 <tree_parent_thread+0x2c>
    }

    // 如果没被kill，会走到这里并正常退出
    printf("[PT-Parent] Finished normally\n");
    800008fa:	00005517          	auipc	a0,0x5
    800008fe:	9f650513          	add	a0,a0,-1546 # 800052f0 <etext+0x2f0>
    80000902:	00001097          	auipc	ra,0x1
    80000906:	8f0080e7          	jalr	-1808(ra) # 800011f2 <printf>
    exit_proc(0);
    8000090a:	4501                	li	a0,0
    8000090c:	00003097          	auipc	ra,0x3
    80000910:	68a080e7          	jalr	1674(ra) # 80003f96 <exit_proc>
}
    80000914:	0001                	nop
    80000916:	60e2                	ld	ra,24(sp)
    80000918:	6442                	ld	s0,16(sp)
    8000091a:	6105                	add	sp,sp,32
    8000091c:	8082                	ret

000000008000091e <tree_child1_thread>:

void tree_child1_thread(void)
{
    8000091e:	7179                	add	sp,sp,-48
    80000920:	f406                	sd	ra,40(sp)
    80000922:	f022                	sd	s0,32(sp)
    80000924:	ec26                	sd	s1,24(sp)
    80000926:	1800                	add	s0,sp,48
    printf("[PT-Child1] Started (PID %d, parent PID %d)\n",
           myproc()->pid,
    80000928:	00003097          	auipc	ra,0x3
    8000092c:	e48080e7          	jalr	-440(ra) # 80003770 <myproc>
    80000930:	87aa                	mv	a5,a0
    printf("[PT-Child1] Started (PID %d, parent PID %d)\n",
    80000932:	4384                	lw	s1,0(a5)
           myproc()->parent ? myproc()->parent->pid : -1);
    80000934:	00003097          	auipc	ra,0x3
    80000938:	e3c080e7          	jalr	-452(ra) # 80003770 <myproc>
    8000093c:	87aa                	mv	a5,a0
    8000093e:	73dc                	ld	a5,160(a5)
    printf("[PT-Child1] Started (PID %d, parent PID %d)\n",
    80000940:	cb89                	beqz	a5,80000952 <tree_child1_thread+0x34>
           myproc()->parent ? myproc()->parent->pid : -1);
    80000942:	00003097          	auipc	ra,0x3
    80000946:	e2e080e7          	jalr	-466(ra) # 80003770 <myproc>
    8000094a:	87aa                	mv	a5,a0
    8000094c:	73dc                	ld	a5,160(a5)
    printf("[PT-Child1] Started (PID %d, parent PID %d)\n",
    8000094e:	439c                	lw	a5,0(a5)
    80000950:	a011                	j	80000954 <tree_child1_thread+0x36>
    80000952:	57fd                	li	a5,-1
    80000954:	863e                	mv	a2,a5
    80000956:	85a6                	mv	a1,s1
    80000958:	00005517          	auipc	a0,0x5
    8000095c:	9b850513          	add	a0,a0,-1608 # 80005310 <etext+0x310>
    80000960:	00001097          	auipc	ra,0x1
    80000964:	892080e7          	jalr	-1902(ra) # 800011f2 <printf>
    
    for (int i = 0; i < 50; i++) {
    80000968:	fc042e23          	sw	zero,-36(s0)
    8000096c:	a02d                	j	80000996 <tree_child1_thread+0x78>
        printf("[PT-Child1] Tick %d\n", i);
    8000096e:	fdc42783          	lw	a5,-36(s0)
    80000972:	85be                	mv	a1,a5
    80000974:	00005517          	auipc	a0,0x5
    80000978:	9cc50513          	add	a0,a0,-1588 # 80005340 <etext+0x340>
    8000097c:	00001097          	auipc	ra,0x1
    80000980:	876080e7          	jalr	-1930(ra) # 800011f2 <printf>
        yield();
    80000984:	00003097          	auipc	ra,0x3
    80000988:	182080e7          	jalr	386(ra) # 80003b06 <yield>
    for (int i = 0; i < 50; i++) {
    8000098c:	fdc42783          	lw	a5,-36(s0)
    80000990:	2785                	addw	a5,a5,1
    80000992:	fcf42e23          	sw	a5,-36(s0)
    80000996:	fdc42783          	lw	a5,-36(s0)
    8000099a:	0007871b          	sext.w	a4,a5
    8000099e:	03100793          	li	a5,49
    800009a2:	fce7d6e3          	bge	a5,a4,8000096e <tree_child1_thread+0x50>
    }

    printf("[PT-Child1] Finished normally\n");
    800009a6:	00005517          	auipc	a0,0x5
    800009aa:	9b250513          	add	a0,a0,-1614 # 80005358 <etext+0x358>
    800009ae:	00001097          	auipc	ra,0x1
    800009b2:	844080e7          	jalr	-1980(ra) # 800011f2 <printf>
    exit_proc(0);
    800009b6:	4501                	li	a0,0
    800009b8:	00003097          	auipc	ra,0x3
    800009bc:	5de080e7          	jalr	1502(ra) # 80003f96 <exit_proc>
}
    800009c0:	0001                	nop
    800009c2:	70a2                	ld	ra,40(sp)
    800009c4:	7402                	ld	s0,32(sp)
    800009c6:	64e2                	ld	s1,24(sp)
    800009c8:	6145                	add	sp,sp,48
    800009ca:	8082                	ret

00000000800009cc <tree_child2_thread>:

void tree_child2_thread(void)
{
    800009cc:	7179                	add	sp,sp,-48
    800009ce:	f406                	sd	ra,40(sp)
    800009d0:	f022                	sd	s0,32(sp)
    800009d2:	ec26                	sd	s1,24(sp)
    800009d4:	1800                	add	s0,sp,48
    printf("[PT-Child2] Started (PID %d, parent PID %d)\n",
           myproc()->pid,
    800009d6:	00003097          	auipc	ra,0x3
    800009da:	d9a080e7          	jalr	-614(ra) # 80003770 <myproc>
    800009de:	87aa                	mv	a5,a0
    printf("[PT-Child2] Started (PID %d, parent PID %d)\n",
    800009e0:	4384                	lw	s1,0(a5)
           myproc()->parent ? myproc()->parent->pid : -1);
    800009e2:	00003097          	auipc	ra,0x3
    800009e6:	d8e080e7          	jalr	-626(ra) # 80003770 <myproc>
    800009ea:	87aa                	mv	a5,a0
    800009ec:	73dc                	ld	a5,160(a5)
    printf("[PT-Child2] Started (PID %d, parent PID %d)\n",
    800009ee:	cb89                	beqz	a5,80000a00 <tree_child2_thread+0x34>
           myproc()->parent ? myproc()->parent->pid : -1);
    800009f0:	00003097          	auipc	ra,0x3
    800009f4:	d80080e7          	jalr	-640(ra) # 80003770 <myproc>
    800009f8:	87aa                	mv	a5,a0
    800009fa:	73dc                	ld	a5,160(a5)
    printf("[PT-Child2] Started (PID %d, parent PID %d)\n",
    800009fc:	439c                	lw	a5,0(a5)
    800009fe:	a011                	j	80000a02 <tree_child2_thread+0x36>
    80000a00:	57fd                	li	a5,-1
    80000a02:	863e                	mv	a2,a5
    80000a04:	85a6                	mv	a1,s1
    80000a06:	00005517          	auipc	a0,0x5
    80000a0a:	97250513          	add	a0,a0,-1678 # 80005378 <etext+0x378>
    80000a0e:	00000097          	auipc	ra,0x0
    80000a12:	7e4080e7          	jalr	2020(ra) # 800011f2 <printf>
    
    for (int i = 0; i < 50; i++) {
    80000a16:	fc042e23          	sw	zero,-36(s0)
    80000a1a:	a02d                	j	80000a44 <tree_child2_thread+0x78>
        printf("[PT-Child2] Tick %d\n", i);
    80000a1c:	fdc42783          	lw	a5,-36(s0)
    80000a20:	85be                	mv	a1,a5
    80000a22:	00005517          	auipc	a0,0x5
    80000a26:	98650513          	add	a0,a0,-1658 # 800053a8 <etext+0x3a8>
    80000a2a:	00000097          	auipc	ra,0x0
    80000a2e:	7c8080e7          	jalr	1992(ra) # 800011f2 <printf>
        yield();
    80000a32:	00003097          	auipc	ra,0x3
    80000a36:	0d4080e7          	jalr	212(ra) # 80003b06 <yield>
    for (int i = 0; i < 50; i++) {
    80000a3a:	fdc42783          	lw	a5,-36(s0)
    80000a3e:	2785                	addw	a5,a5,1
    80000a40:	fcf42e23          	sw	a5,-36(s0)
    80000a44:	fdc42783          	lw	a5,-36(s0)
    80000a48:	0007871b          	sext.w	a4,a5
    80000a4c:	03100793          	li	a5,49
    80000a50:	fce7d6e3          	bge	a5,a4,80000a1c <tree_child2_thread+0x50>
    }

    printf("[PT-Child2] Finished normally\n");
    80000a54:	00005517          	auipc	a0,0x5
    80000a58:	96c50513          	add	a0,a0,-1684 # 800053c0 <etext+0x3c0>
    80000a5c:	00000097          	auipc	ra,0x0
    80000a60:	796080e7          	jalr	1942(ra) # 800011f2 <printf>
    exit_proc(0);
    80000a64:	4501                	li	a0,0
    80000a66:	00003097          	auipc	ra,0x3
    80000a6a:	530080e7          	jalr	1328(ra) # 80003f96 <exit_proc>
}
    80000a6e:	0001                	nop
    80000a70:	70a2                	ld	ra,40(sp)
    80000a72:	7402                	ld	s0,32(sp)
    80000a74:	64e2                	ld	s1,24(sp)
    80000a76:	6145                	add	sp,sp,48
    80000a78:	8082                	ret

0000000080000a7a <tree_grandchild_thread>:

void tree_grandchild_thread(void)
{
    80000a7a:	7179                	add	sp,sp,-48
    80000a7c:	f406                	sd	ra,40(sp)
    80000a7e:	f022                	sd	s0,32(sp)
    80000a80:	ec26                	sd	s1,24(sp)
    80000a82:	1800                	add	s0,sp,48
    printf("[PT-Grandchild] Started (PID %d, parent PID %d)\n",
           myproc()->pid,
    80000a84:	00003097          	auipc	ra,0x3
    80000a88:	cec080e7          	jalr	-788(ra) # 80003770 <myproc>
    80000a8c:	87aa                	mv	a5,a0
    printf("[PT-Grandchild] Started (PID %d, parent PID %d)\n",
    80000a8e:	4384                	lw	s1,0(a5)
           myproc()->parent ? myproc()->parent->pid : -1);
    80000a90:	00003097          	auipc	ra,0x3
    80000a94:	ce0080e7          	jalr	-800(ra) # 80003770 <myproc>
    80000a98:	87aa                	mv	a5,a0
    80000a9a:	73dc                	ld	a5,160(a5)
    printf("[PT-Grandchild] Started (PID %d, parent PID %d)\n",
    80000a9c:	cb89                	beqz	a5,80000aae <tree_grandchild_thread+0x34>
           myproc()->parent ? myproc()->parent->pid : -1);
    80000a9e:	00003097          	auipc	ra,0x3
    80000aa2:	cd2080e7          	jalr	-814(ra) # 80003770 <myproc>
    80000aa6:	87aa                	mv	a5,a0
    80000aa8:	73dc                	ld	a5,160(a5)
    printf("[PT-Grandchild] Started (PID %d, parent PID %d)\n",
    80000aaa:	439c                	lw	a5,0(a5)
    80000aac:	a011                	j	80000ab0 <tree_grandchild_thread+0x36>
    80000aae:	57fd                	li	a5,-1
    80000ab0:	863e                	mv	a2,a5
    80000ab2:	85a6                	mv	a1,s1
    80000ab4:	00005517          	auipc	a0,0x5
    80000ab8:	92c50513          	add	a0,a0,-1748 # 800053e0 <etext+0x3e0>
    80000abc:	00000097          	auipc	ra,0x0
    80000ac0:	736080e7          	jalr	1846(ra) # 800011f2 <printf>
    
    for (int i = 0; i < 50; i++) {
    80000ac4:	fc042e23          	sw	zero,-36(s0)
    80000ac8:	a02d                	j	80000af2 <tree_grandchild_thread+0x78>
        printf("[PT-Grandchild] Tick %d\n", i);
    80000aca:	fdc42783          	lw	a5,-36(s0)
    80000ace:	85be                	mv	a1,a5
    80000ad0:	00005517          	auipc	a0,0x5
    80000ad4:	94850513          	add	a0,a0,-1720 # 80005418 <etext+0x418>
    80000ad8:	00000097          	auipc	ra,0x0
    80000adc:	71a080e7          	jalr	1818(ra) # 800011f2 <printf>
        yield();
    80000ae0:	00003097          	auipc	ra,0x3
    80000ae4:	026080e7          	jalr	38(ra) # 80003b06 <yield>
    for (int i = 0; i < 50; i++) {
    80000ae8:	fdc42783          	lw	a5,-36(s0)
    80000aec:	2785                	addw	a5,a5,1
    80000aee:	fcf42e23          	sw	a5,-36(s0)
    80000af2:	fdc42783          	lw	a5,-36(s0)
    80000af6:	0007871b          	sext.w	a4,a5
    80000afa:	03100793          	li	a5,49
    80000afe:	fce7d6e3          	bge	a5,a4,80000aca <tree_grandchild_thread+0x50>
    }

    printf("[PT-Grandchild] Finished normally\n");
    80000b02:	00005517          	auipc	a0,0x5
    80000b06:	93650513          	add	a0,a0,-1738 # 80005438 <etext+0x438>
    80000b0a:	00000097          	auipc	ra,0x0
    80000b0e:	6e8080e7          	jalr	1768(ra) # 800011f2 <printf>
    exit_proc(0);
    80000b12:	4501                	li	a0,0
    80000b14:	00003097          	auipc	ra,0x3
    80000b18:	482080e7          	jalr	1154(ra) # 80003f96 <exit_proc>
}
    80000b1c:	0001                	nop
    80000b1e:	70a2                	ld	ra,40(sp)
    80000b20:	7402                	ld	s0,32(sp)
    80000b22:	64e2                	ld	s1,24(sp)
    80000b24:	6145                	add	sp,sp,48
    80000b26:	8082                	ret

0000000080000b28 <tree_killer_thread>:

// ==================== 杀手线程：演示 kill_proc 对整棵进程树的效果 ====================

void tree_killer_thread(void)
{
    80000b28:	1101                	add	sp,sp,-32
    80000b2a:	ec06                	sd	ra,24(sp)
    80000b2c:	e822                	sd	s0,16(sp)
    80000b2e:	1000                	add	s0,sp,32
    printf("[PT-Killer] Started\n");
    80000b30:	00005517          	auipc	a0,0x5
    80000b34:	93050513          	add	a0,a0,-1744 # 80005460 <etext+0x460>
    80000b38:	00000097          	auipc	ra,0x0
    80000b3c:	6ba080e7          	jalr	1722(ra) # 800011f2 <printf>
    
    // 不要用 delay_ms 忙等，否则会把CPU一直占住、调度器拿不到机会
    // 这里用多次 yield 的方式“等一会儿”，让父/子/孙都跑一段时间
    for (int i = 0; i < 30; i++) {
    80000b40:	fe042623          	sw	zero,-20(s0)
    80000b44:	a02d                	j	80000b6e <tree_killer_thread+0x46>
        printf("[PT-Killer] waiting... (%d)\n", i);
    80000b46:	fec42783          	lw	a5,-20(s0)
    80000b4a:	85be                	mv	a1,a5
    80000b4c:	00005517          	auipc	a0,0x5
    80000b50:	92c50513          	add	a0,a0,-1748 # 80005478 <etext+0x478>
    80000b54:	00000097          	auipc	ra,0x0
    80000b58:	69e080e7          	jalr	1694(ra) # 800011f2 <printf>
        yield();
    80000b5c:	00003097          	auipc	ra,0x3
    80000b60:	faa080e7          	jalr	-86(ra) # 80003b06 <yield>
    for (int i = 0; i < 30; i++) {
    80000b64:	fec42783          	lw	a5,-20(s0)
    80000b68:	2785                	addw	a5,a5,1
    80000b6a:	fef42623          	sw	a5,-20(s0)
    80000b6e:	fec42783          	lw	a5,-20(s0)
    80000b72:	0007871b          	sext.w	a4,a5
    80000b76:	47f5                	li	a5,29
    80000b78:	fce7d7e3          	bge	a5,a4,80000b46 <tree_killer_thread+0x1e>
    }
    
    if (tree_parent_pid > 0) {
    80000b7c:	00007797          	auipc	a5,0x7
    80000b80:	48478793          	add	a5,a5,1156 # 80008000 <tree_parent_pid>
    80000b84:	439c                	lw	a5,0(a5)
    80000b86:	06f05f63          	blez	a5,80000c04 <tree_killer_thread+0xdc>
        printf("[PT-Killer] Now killing parent PID %d (and all its children)\n",
    80000b8a:	00007797          	auipc	a5,0x7
    80000b8e:	47678793          	add	a5,a5,1142 # 80008000 <tree_parent_pid>
    80000b92:	439c                	lw	a5,0(a5)
    80000b94:	85be                	mv	a1,a5
    80000b96:	00005517          	auipc	a0,0x5
    80000b9a:	90250513          	add	a0,a0,-1790 # 80005498 <etext+0x498>
    80000b9e:	00000097          	auipc	ra,0x0
    80000ba2:	654080e7          	jalr	1620(ra) # 800011f2 <printf>
               tree_parent_pid);
        int r = kill_proc(tree_parent_pid);
    80000ba6:	00007797          	auipc	a5,0x7
    80000baa:	45a78793          	add	a5,a5,1114 # 80008000 <tree_parent_pid>
    80000bae:	439c                	lw	a5,0(a5)
    80000bb0:	853e                	mv	a0,a5
    80000bb2:	00003097          	auipc	ra,0x3
    80000bb6:	33e080e7          	jalr	830(ra) # 80003ef0 <kill_proc>
    80000bba:	87aa                	mv	a5,a0
    80000bbc:	fef42423          	sw	a5,-24(s0)
        if (r == 0) {
    80000bc0:	fe842783          	lw	a5,-24(s0)
    80000bc4:	2781                	sext.w	a5,a5
    80000bc6:	e385                	bnez	a5,80000be6 <tree_killer_thread+0xbe>
            printf("[PT-Killer] kill_proc(%d) succeeded\n", tree_parent_pid);
    80000bc8:	00007797          	auipc	a5,0x7
    80000bcc:	43878793          	add	a5,a5,1080 # 80008000 <tree_parent_pid>
    80000bd0:	439c                	lw	a5,0(a5)
    80000bd2:	85be                	mv	a1,a5
    80000bd4:	00005517          	auipc	a0,0x5
    80000bd8:	90450513          	add	a0,a0,-1788 # 800054d8 <etext+0x4d8>
    80000bdc:	00000097          	auipc	ra,0x0
    80000be0:	616080e7          	jalr	1558(ra) # 800011f2 <printf>
    80000be4:	a805                	j	80000c14 <tree_killer_thread+0xec>
        } else {
            printf("[PT-Killer] kill_proc(%d) FAILED (not found)\n", tree_parent_pid);
    80000be6:	00007797          	auipc	a5,0x7
    80000bea:	41a78793          	add	a5,a5,1050 # 80008000 <tree_parent_pid>
    80000bee:	439c                	lw	a5,0(a5)
    80000bf0:	85be                	mv	a1,a5
    80000bf2:	00005517          	auipc	a0,0x5
    80000bf6:	90e50513          	add	a0,a0,-1778 # 80005500 <etext+0x500>
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	5f8080e7          	jalr	1528(ra) # 800011f2 <printf>
    80000c02:	a809                	j	80000c14 <tree_killer_thread+0xec>
        }
    } else {
        printf("[PT-Killer] No valid tree_parent_pid to kill\n");
    80000c04:	00005517          	auipc	a0,0x5
    80000c08:	92c50513          	add	a0,a0,-1748 # 80005530 <etext+0x530>
    80000c0c:	00000097          	auipc	ra,0x0
    80000c10:	5e6080e7          	jalr	1510(ra) # 800011f2 <printf>
    }
    
    printf("[PT-Killer] Finished\n");
    80000c14:	00005517          	auipc	a0,0x5
    80000c18:	94c50513          	add	a0,a0,-1716 # 80005560 <etext+0x560>
    80000c1c:	00000097          	auipc	ra,0x0
    80000c20:	5d6080e7          	jalr	1494(ra) # 800011f2 <printf>
    exit_proc(0);
    80000c24:	4501                	li	a0,0
    80000c26:	00003097          	auipc	ra,0x3
    80000c2a:	370080e7          	jalr	880(ra) # 80003f96 <exit_proc>
}
    80000c2e:	0001                	nop
    80000c30:	60e2                	ld	ra,24(sp)
    80000c32:	6442                	ld	s0,16(sp)
    80000c34:	6105                	add	sp,sp,32
    80000c36:	8082                	ret

0000000080000c38 <main>:

// ==================== 主函数 ====================
void main(void) {
    80000c38:	1141                	add	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	add	s0,sp,16
    // ========== 初始化控制台 ==========
    consoleinit();
    80000c40:	00000097          	auipc	ra,0x0
    80000c44:	42a080e7          	jalr	1066(ra) # 8000106a <consoleinit>
    clear_screen();
    80000c48:	00001097          	auipc	ra,0x1
    80000c4c:	9aa080e7          	jalr	-1622(ra) # 800015f2 <clear_screen>
    
    printf("=== RISC-V OS Lab 5: Process Management ===\n");
    80000c50:	00005517          	auipc	a0,0x5
    80000c54:	92850513          	add	a0,a0,-1752 # 80005578 <etext+0x578>
    80000c58:	00000097          	auipc	ra,0x0
    80000c5c:	59a080e7          	jalr	1434(ra) # 800011f2 <printf>
    printf("Student Implementation - Full Feature Version (with kill tree demo)\n\n");
    80000c60:	00005517          	auipc	a0,0x5
    80000c64:	94850513          	add	a0,a0,-1720 # 800055a8 <etext+0x5a8>
    80000c68:	00000097          	auipc	ra,0x0
    80000c6c:	58a080e7          	jalr	1418(ra) # 800011f2 <printf>
    
    // ========== 阶段1：系统初始化 ==========
    printf("=== Phase 1: System Initialization ===\n");
    80000c70:	00005517          	auipc	a0,0x5
    80000c74:	98050513          	add	a0,a0,-1664 # 800055f0 <etext+0x5f0>
    80000c78:	00000097          	auipc	ra,0x0
    80000c7c:	57a080e7          	jalr	1402(ra) # 800011f2 <printf>
    
    // 内存管理
    pmm_init();
    80000c80:	00001097          	auipc	ra,0x1
    80000c84:	afa080e7          	jalr	-1286(ra) # 8000177a <pmm_init>
    kvminit();
    80000c88:	00001097          	auipc	ra,0x1
    80000c8c:	24c080e7          	jalr	588(ra) # 80001ed4 <kvminit>
    kvminithart();
    80000c90:	00001097          	auipc	ra,0x1
    80000c94:	3b8080e7          	jalr	952(ra) # 80002048 <kvminithart>
    
    // 中断和时钟
    trap_init();
    80000c98:	00002097          	auipc	ra,0x2
    80000c9c:	a6c080e7          	jalr	-1428(ra) # 80002704 <trap_init>
    timer_init();
    80000ca0:	00003097          	auipc	ra,0x3
    80000ca4:	872080e7          	jalr	-1934(ra) # 80003512 <timer_init>
    
    // 进程系统
    proc_init();
    80000ca8:	00003097          	auipc	ra,0x3
    80000cac:	90e080e7          	jalr	-1778(ra) # 800035b6 <proc_init>
    
    printf("System initialization completed!\n");
    80000cb0:	00005517          	auipc	a0,0x5
    80000cb4:	96850513          	add	a0,a0,-1688 # 80005618 <etext+0x618>
    80000cb8:	00000097          	auipc	ra,0x0
    80000cbc:	53a080e7          	jalr	1338(ra) # 800011f2 <printf>
    
    // ========== 阶段2：基本线程测试 ==========
    printf("\n=== Phase 2: Basic Thread Tests ===\n");
    80000cc0:	00005517          	auipc	a0,0x5
    80000cc4:	98050513          	add	a0,a0,-1664 # 80005640 <etext+0x640>
    80000cc8:	00000097          	auipc	ra,0x0
    80000ccc:	52a080e7          	jalr	1322(ra) # 800011f2 <printf>
    create_kthread(thread1, "Thread-1");
    80000cd0:	00005597          	auipc	a1,0x5
    80000cd4:	99858593          	add	a1,a1,-1640 # 80005668 <etext+0x668>
    80000cd8:	fffff517          	auipc	a0,0xfffff
    80000cdc:	6f050513          	add	a0,a0,1776 # 800003c8 <thread1>
    80000ce0:	00003097          	auipc	ra,0x3
    80000ce4:	c46080e7          	jalr	-954(ra) # 80003926 <create_kthread>
    create_kthread(thread2, "Thread-2");
    80000ce8:	00005597          	auipc	a1,0x5
    80000cec:	99058593          	add	a1,a1,-1648 # 80005678 <etext+0x678>
    80000cf0:	fffff517          	auipc	a0,0xfffff
    80000cf4:	74050513          	add	a0,a0,1856 # 80000430 <thread2>
    80000cf8:	00003097          	auipc	ra,0x3
    80000cfc:	c2e080e7          	jalr	-978(ra) # 80003926 <create_kthread>
    create_kthread(thread3, "Thread-3");
    80000d00:	00005597          	auipc	a1,0x5
    80000d04:	98858593          	add	a1,a1,-1656 # 80005688 <etext+0x688>
    80000d08:	fffff517          	auipc	a0,0xfffff
    80000d0c:	7ae50513          	add	a0,a0,1966 # 800004b6 <thread3>
    80000d10:	00003097          	auipc	ra,0x3
    80000d14:	c16080e7          	jalr	-1002(ra) # 80003926 <create_kthread>
    
    // ========== 阶段3：同步机制测试 ==========
    printf("\n=== Phase 3: Synchronization Test (Producer-Consumer) ===\n");
    80000d18:	00005517          	auipc	a0,0x5
    80000d1c:	98050513          	add	a0,a0,-1664 # 80005698 <etext+0x698>
    80000d20:	00000097          	auipc	ra,0x0
    80000d24:	4d2080e7          	jalr	1234(ra) # 800011f2 <printf>
    printf("Creating producer and consumer threads...\n");
    80000d28:	00005517          	auipc	a0,0x5
    80000d2c:	9b050513          	add	a0,a0,-1616 # 800056d8 <etext+0x6d8>
    80000d30:	00000097          	auipc	ra,0x0
    80000d34:	4c2080e7          	jalr	1218(ra) # 800011f2 <printf>
    create_kthread(producer_thread, "Producer");
    80000d38:	00005597          	auipc	a1,0x5
    80000d3c:	9d058593          	add	a1,a1,-1584 # 80005708 <etext+0x708>
    80000d40:	00000517          	auipc	a0,0x0
    80000d44:	82050513          	add	a0,a0,-2016 # 80000560 <producer_thread>
    80000d48:	00003097          	auipc	ra,0x3
    80000d4c:	bde080e7          	jalr	-1058(ra) # 80003926 <create_kthread>
    create_kthread(consumer_thread, "Consumer");
    80000d50:	00005597          	auipc	a1,0x5
    80000d54:	9c858593          	add	a1,a1,-1592 # 80005718 <etext+0x718>
    80000d58:	00000517          	auipc	a0,0x0
    80000d5c:	95c50513          	add	a0,a0,-1700 # 800006b4 <consumer_thread>
    80000d60:	00003097          	auipc	ra,0x3
    80000d64:	bc6080e7          	jalr	-1082(ra) # 80003926 <create_kthread>
    
    // ========== 阶段4：调度器观察 ==========
    printf("\n=== Phase 4: Scheduler Observation ===\n");
    80000d68:	00005517          	auipc	a0,0x5
    80000d6c:	9c050513          	add	a0,a0,-1600 # 80005728 <etext+0x728>
    80000d70:	00000097          	auipc	ra,0x0
    80000d74:	482080e7          	jalr	1154(ra) # 800011f2 <printf>
    create_kthread(background_thread, "Background");
    80000d78:	00005597          	auipc	a1,0x5
    80000d7c:	9e058593          	add	a1,a1,-1568 # 80005758 <etext+0x758>
    80000d80:	00000517          	auipc	a0,0x0
    80000d84:	a8650513          	add	a0,a0,-1402 # 80000806 <background_thread>
    80000d88:	00003097          	auipc	ra,0x3
    80000d8c:	b9e080e7          	jalr	-1122(ra) # 80003926 <create_kthread>
    
    // ========== 阶段5：进程树 kill 演示 ==========
    printf("\n=== Phase 5: Kill Tree Demo (Parent + Children + Grandchild) ===\n");
    80000d90:	00005517          	auipc	a0,0x5
    80000d94:	9d850513          	add	a0,a0,-1576 # 80005768 <etext+0x768>
    80000d98:	00000097          	auipc	ra,0x0
    80000d9c:	45a080e7          	jalr	1114(ra) # 800011f2 <printf>
    
    tree_parent_pid     = create_kthread(tree_parent_thread,     "PT-Parent");
    80000da0:	00005597          	auipc	a1,0x5
    80000da4:	a1058593          	add	a1,a1,-1520 # 800057b0 <etext+0x7b0>
    80000da8:	00000517          	auipc	a0,0x0
    80000dac:	aee50513          	add	a0,a0,-1298 # 80000896 <tree_parent_thread>
    80000db0:	00003097          	auipc	ra,0x3
    80000db4:	b76080e7          	jalr	-1162(ra) # 80003926 <create_kthread>
    80000db8:	87aa                	mv	a5,a0
    80000dba:	873e                	mv	a4,a5
    80000dbc:	00007797          	auipc	a5,0x7
    80000dc0:	24478793          	add	a5,a5,580 # 80008000 <tree_parent_pid>
    80000dc4:	c398                	sw	a4,0(a5)
    tree_child1_pid     = create_kthread(tree_child1_thread,     "PT-Child1");
    80000dc6:	00005597          	auipc	a1,0x5
    80000dca:	9fa58593          	add	a1,a1,-1542 # 800057c0 <etext+0x7c0>
    80000dce:	00000517          	auipc	a0,0x0
    80000dd2:	b5050513          	add	a0,a0,-1200 # 8000091e <tree_child1_thread>
    80000dd6:	00003097          	auipc	ra,0x3
    80000dda:	b50080e7          	jalr	-1200(ra) # 80003926 <create_kthread>
    80000dde:	87aa                	mv	a5,a0
    80000de0:	873e                	mv	a4,a5
    80000de2:	00007797          	auipc	a5,0x7
    80000de6:	22278793          	add	a5,a5,546 # 80008004 <tree_child1_pid>
    80000dea:	c398                	sw	a4,0(a5)
    tree_child2_pid     = create_kthread(tree_child2_thread,     "PT-Child2");
    80000dec:	00005597          	auipc	a1,0x5
    80000df0:	9e458593          	add	a1,a1,-1564 # 800057d0 <etext+0x7d0>
    80000df4:	00000517          	auipc	a0,0x0
    80000df8:	bd850513          	add	a0,a0,-1064 # 800009cc <tree_child2_thread>
    80000dfc:	00003097          	auipc	ra,0x3
    80000e00:	b2a080e7          	jalr	-1238(ra) # 80003926 <create_kthread>
    80000e04:	87aa                	mv	a5,a0
    80000e06:	873e                	mv	a4,a5
    80000e08:	00007797          	auipc	a5,0x7
    80000e0c:	20078793          	add	a5,a5,512 # 80008008 <tree_child2_pid>
    80000e10:	c398                	sw	a4,0(a5)
    tree_grandchild_pid = create_kthread(tree_grandchild_thread, "PT-Grandchild");
    80000e12:	00005597          	auipc	a1,0x5
    80000e16:	9ce58593          	add	a1,a1,-1586 # 800057e0 <etext+0x7e0>
    80000e1a:	00000517          	auipc	a0,0x0
    80000e1e:	c6050513          	add	a0,a0,-928 # 80000a7a <tree_grandchild_thread>
    80000e22:	00003097          	auipc	ra,0x3
    80000e26:	b04080e7          	jalr	-1276(ra) # 80003926 <create_kthread>
    80000e2a:	87aa                	mv	a5,a0
    80000e2c:	873e                	mv	a4,a5
    80000e2e:	00007797          	auipc	a5,0x7
    80000e32:	1de78793          	add	a5,a5,478 # 8000800c <tree_grandchild_pid>
    80000e36:	c398                	sw	a4,0(a5)
    
    printf("[main] Tree PIDs: parent=%d, child1=%d, child2=%d, grandchild=%d\n",
    80000e38:	00007797          	auipc	a5,0x7
    80000e3c:	1c878793          	add	a5,a5,456 # 80008000 <tree_parent_pid>
    80000e40:	438c                	lw	a1,0(a5)
    80000e42:	00007797          	auipc	a5,0x7
    80000e46:	1c278793          	add	a5,a5,450 # 80008004 <tree_child1_pid>
    80000e4a:	4390                	lw	a2,0(a5)
    80000e4c:	00007797          	auipc	a5,0x7
    80000e50:	1bc78793          	add	a5,a5,444 # 80008008 <tree_child2_pid>
    80000e54:	4394                	lw	a3,0(a5)
    80000e56:	00007797          	auipc	a5,0x7
    80000e5a:	1b678793          	add	a5,a5,438 # 8000800c <tree_grandchild_pid>
    80000e5e:	439c                	lw	a5,0(a5)
    80000e60:	873e                	mv	a4,a5
    80000e62:	00005517          	auipc	a0,0x5
    80000e66:	98e50513          	add	a0,a0,-1650 # 800057f0 <etext+0x7f0>
    80000e6a:	00000097          	auipc	ra,0x0
    80000e6e:	388080e7          	jalr	904(ra) # 800011f2 <printf>
    // 手动设置父子关系：
    // PT-Parent
    //  ├── PT-Child1
    //  │     └── PT-Grandchild
    //  └── PT-Child2
    set_parent(tree_child1_pid,     tree_parent_pid);
    80000e72:	00007797          	auipc	a5,0x7
    80000e76:	19278793          	add	a5,a5,402 # 80008004 <tree_child1_pid>
    80000e7a:	4398                	lw	a4,0(a5)
    80000e7c:	00007797          	auipc	a5,0x7
    80000e80:	18478793          	add	a5,a5,388 # 80008000 <tree_parent_pid>
    80000e84:	439c                	lw	a5,0(a5)
    80000e86:	85be                	mv	a1,a5
    80000e88:	853a                	mv	a0,a4
    80000e8a:	fffff097          	auipc	ra,0xfffff
    80000e8e:	45a080e7          	jalr	1114(ra) # 800002e4 <set_parent>
    set_parent(tree_child2_pid,     tree_parent_pid);
    80000e92:	00007797          	auipc	a5,0x7
    80000e96:	17678793          	add	a5,a5,374 # 80008008 <tree_child2_pid>
    80000e9a:	4398                	lw	a4,0(a5)
    80000e9c:	00007797          	auipc	a5,0x7
    80000ea0:	16478793          	add	a5,a5,356 # 80008000 <tree_parent_pid>
    80000ea4:	439c                	lw	a5,0(a5)
    80000ea6:	85be                	mv	a1,a5
    80000ea8:	853a                	mv	a0,a4
    80000eaa:	fffff097          	auipc	ra,0xfffff
    80000eae:	43a080e7          	jalr	1082(ra) # 800002e4 <set_parent>
    set_parent(tree_grandchild_pid, tree_child1_pid);
    80000eb2:	00007797          	auipc	a5,0x7
    80000eb6:	15a78793          	add	a5,a5,346 # 8000800c <tree_grandchild_pid>
    80000eba:	4398                	lw	a4,0(a5)
    80000ebc:	00007797          	auipc	a5,0x7
    80000ec0:	14878793          	add	a5,a5,328 # 80008004 <tree_child1_pid>
    80000ec4:	439c                	lw	a5,0(a5)
    80000ec6:	85be                	mv	a1,a5
    80000ec8:	853a                	mv	a0,a4
    80000eca:	fffff097          	auipc	ra,0xfffff
    80000ece:	41a080e7          	jalr	1050(ra) # 800002e4 <set_parent>
    
    // 创建杀手线程：过一会儿 kill 整棵树
    create_kthread(tree_killer_thread, "PT-Killer");
    80000ed2:	00005597          	auipc	a1,0x5
    80000ed6:	96658593          	add	a1,a1,-1690 # 80005838 <etext+0x838>
    80000eda:	00000517          	auipc	a0,0x0
    80000ede:	c4e50513          	add	a0,a0,-946 # 80000b28 <tree_killer_thread>
    80000ee2:	00003097          	auipc	ra,0x3
    80000ee6:	a44080e7          	jalr	-1468(ra) # 80003926 <create_kthread>
    
    // ========== 启动调度器 ==========
    printf("\n=== Starting Scheduler ===\n");
    80000eea:	00005517          	auipc	a0,0x5
    80000eee:	95e50513          	add	a0,a0,-1698 # 80005848 <etext+0x848>
    80000ef2:	00000097          	auipc	ra,0x0
    80000ef6:	300080e7          	jalr	768(ra) # 800011f2 <printf>
    printf("Initial process table:\n");
    80000efa:	00005517          	auipc	a0,0x5
    80000efe:	96e50513          	add	a0,a0,-1682 # 80005868 <etext+0x868>
    80000f02:	00000097          	auipc	ra,0x0
    80000f06:	2f0080e7          	jalr	752(ra) # 800011f2 <printf>
    proc_info();
    80000f0a:	00003097          	auipc	ra,0x3
    80000f0e:	20c080e7          	jalr	524(ra) # 80004116 <proc_info>
    
    printf("Entering scheduler...\n");
    80000f12:	00005517          	auipc	a0,0x5
    80000f16:	96e50513          	add	a0,a0,-1682 # 80005880 <etext+0x880>
    80000f1a:	00000097          	auipc	ra,0x0
    80000f1e:	2d8080e7          	jalr	728(ra) # 800011f2 <printf>
    printf("Press Ctrl+A then X to exit QEMU\n\n");
    80000f22:	00005517          	auipc	a0,0x5
    80000f26:	97650513          	add	a0,a0,-1674 # 80005898 <etext+0x898>
    80000f2a:	00000097          	auipc	ra,0x0
    80000f2e:	2c8080e7          	jalr	712(ra) # 800011f2 <printf>
    
    scheduler();  // 永不返回
    80000f32:	00003097          	auipc	ra,0x3
    80000f36:	ca4080e7          	jalr	-860(ra) # 80003bd6 <scheduler>

0000000080000f3a <uartinit>:
/* 外部变量声明 */
extern volatile int panicking;
extern volatile int panicked;

void uartinit(void)
{
    80000f3a:	1141                	add	sp,sp,-16
    80000f3c:	e422                	sd	s0,8(sp)
    80000f3e:	0800                	add	s0,sp,16
  // 1. 禁用所有中断（简化设计，使用轮询模式）
  WriteReg(IER, 0x00);
    80000f40:	100007b7          	lui	a5,0x10000
    80000f44:	0785                	add	a5,a5,1 # 10000001 <_start-0x6fffffff>
    80000f46:	00078023          	sb	zero,0(a5)
   // 2. 设置波特率为38400
  WriteReg(LCR, LCR_BAUD_LATCH);// 进入波特率设置模式
    80000f4a:	100007b7          	lui	a5,0x10000
    80000f4e:	078d                	add	a5,a5,3 # 10000003 <_start-0x6ffffffd>
    80000f50:	f8000713          	li	a4,-128
    80000f54:	00e78023          	sb	a4,0(a5)
  WriteReg(0, 0x03);// 低字节
    80000f58:	100007b7          	lui	a5,0x10000
    80000f5c:	470d                	li	a4,3
    80000f5e:	00e78023          	sb	a4,0(a5) # 10000000 <_start-0x70000000>
  WriteReg(1, 0x00);// 高字节
    80000f62:	100007b7          	lui	a5,0x10000
    80000f66:	0785                	add	a5,a5,1 # 10000001 <_start-0x6fffffff>
    80000f68:	00078023          	sb	zero,0(a5)
  // 3. 配置数据格式：8位数据，无校验位
  WriteReg(LCR, LCR_EIGHT_BITS);
    80000f6c:	100007b7          	lui	a5,0x10000
    80000f70:	078d                	add	a5,a5,3 # 10000003 <_start-0x6ffffffd>
    80000f72:	470d                	li	a4,3
    80000f74:	00e78023          	sb	a4,0(a5)
  // 4. 启用并清空FIFO缓冲区
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000f78:	100007b7          	lui	a5,0x10000
    80000f7c:	0789                	add	a5,a5,2 # 10000002 <_start-0x6ffffffe>
    80000f7e:	471d                	li	a4,7
    80000f80:	00e78023          	sb	a4,0(a5)
}
    80000f84:	0001                	nop
    80000f86:	6422                	ld	s0,8(sp)
    80000f88:	0141                	add	sp,sp,16
    80000f8a:	8082                	ret

0000000080000f8c <uartputc_sync>:

/* 同步字符输出 */
void uartputc_sync(int c)
{// 1. 检查系统是否panic
    80000f8c:	1101                	add	sp,sp,-32
    80000f8e:	ec22                	sd	s0,24(sp)
    80000f90:	1000                	add	s0,sp,32
    80000f92:	87aa                	mv	a5,a0
    80000f94:	fef42623          	sw	a5,-20(s0)
  if(panicked){
    80000f98:	0000f797          	auipc	a5,0xf
    80000f9c:	06c78793          	add	a5,a5,108 # 80010004 <panicked>
    80000fa0:	439c                	lw	a5,0(a5)
    80000fa2:	2781                	sext.w	a5,a5
    80000fa4:	c399                	beqz	a5,80000faa <uartputc_sync+0x1e>
    for(;;)// 如果系统崩溃，停止输出
    80000fa6:	0001                	nop
    80000fa8:	bffd                	j	80000fa6 <uartputc_sync+0x1a>
      ;
  }
 // 2. 等待发送寄存器空闲
 // 忙等待 - 轮询LSR寄存器的TX_IDLE位
// 这确保上一个字符发送完成后再发送新字符
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000faa:	0001                	nop
    80000fac:	100007b7          	lui	a5,0x10000
    80000fb0:	0795                	add	a5,a5,5 # 10000005 <_start-0x6ffffffb>
    80000fb2:	0007c783          	lbu	a5,0(a5)
    80000fb6:	0ff7f793          	zext.b	a5,a5
    80000fba:	2781                	sext.w	a5,a5
    80000fbc:	0207f793          	and	a5,a5,32
    80000fc0:	2781                	sext.w	a5,a5
    80000fc2:	d7ed                	beqz	a5,80000fac <uartputc_sync+0x20>
    ;
  // 3. 将字符写入发送寄存器
  WriteReg(THR, c);
    80000fc4:	100007b7          	lui	a5,0x10000
    80000fc8:	fec42703          	lw	a4,-20(s0)
    80000fcc:	0ff77713          	zext.b	a4,a4
    80000fd0:	00e78023          	sb	a4,0(a5) # 10000000 <_start-0x70000000>
  // 硬件会自动开始发送这个字符
}
    80000fd4:	0001                	nop
    80000fd6:	6462                	ld	s0,24(sp)
    80000fd8:	6105                	add	sp,sp,32
    80000fda:	8082                	ret

0000000080000fdc <uartgetc>:

int uartgetc(void)
{
    80000fdc:	1141                	add	sp,sp,-16
    80000fde:	e422                	sd	s0,8(sp)
    80000fe0:	0800                	add	s0,sp,16
  // 第1步：检查串口是否有数据可读
  // LSR_RX_READY 位表示"接收缓冲区有数据"
  if(ReadReg(LSR) & LSR_RX_READY) {
    80000fe2:	100007b7          	lui	a5,0x10000
    80000fe6:	0795                	add	a5,a5,5 # 10000005 <_start-0x6ffffffb>
    80000fe8:	0007c783          	lbu	a5,0(a5)
    80000fec:	0ff7f793          	zext.b	a5,a5
    80000ff0:	2781                	sext.w	a5,a5
    80000ff2:	8b85                	and	a5,a5,1
    80000ff4:	2781                	sext.w	a5,a5
    80000ff6:	cb89                	beqz	a5,80001008 <uartgetc+0x2c>
    
    // 第2步：如果有数据，从接收寄存器读取一个字符
    // RHR = Receive Holding Register (接收保持寄存器)
    return ReadReg(RHR);
    80000ff8:	100007b7          	lui	a5,0x10000
    80000ffc:	0007c783          	lbu	a5,0(a5) # 10000000 <_start-0x70000000>
    80001000:	0ff7f793          	zext.b	a5,a5
    80001004:	2781                	sext.w	a5,a5
    80001006:	a011                	j	8000100a <uartgetc+0x2e>
    
  } else {
    
    // 第3步：如果没有数据，返回-1表示"没有数据"
    return -1;
    80001008:	57fd                	li	a5,-1
  }
}
    8000100a:	853e                	mv	a0,a5
    8000100c:	6422                	ld	s0,8(sp)
    8000100e:	0141                	add	sp,sp,16
    80001010:	8082                	ret

0000000080001012 <consputc>:
// consputc()是一个适配器：
// - 上层(printf)期望简单的字符输出接口
// - 下层(uart)提供硬件特定的接口
// - console层负责适配和转换
void consputc(int c)
{
    80001012:	1101                	add	sp,sp,-32
    80001014:	ec06                	sd	ra,24(sp)
    80001016:	e822                	sd	s0,16(sp)
    80001018:	1000                	add	s0,sp,32
    8000101a:	87aa                	mv	a5,a0
    8000101c:	fef42623          	sw	a5,-20(s0)
  if(c == BACKSPACE){
    80001020:	fec42783          	lw	a5,-20(s0)
    80001024:	0007871b          	sext.w	a4,a5
    80001028:	10000793          	li	a5,256
    8000102c:	02f71363          	bne	a4,a5,80001052 <consputc+0x40>
    // 退格处理：输出 退格-空格-退格 序列
     uartputc_sync('\b');   // 光标后退一位
    80001030:	4521                	li	a0,8
    80001032:	00000097          	auipc	ra,0x0
    80001036:	f5a080e7          	jalr	-166(ra) # 80000f8c <uartputc_sync>
     uartputc_sync(' ');    // 用空格覆盖字符  
    8000103a:	02000513          	li	a0,32
    8000103e:	00000097          	auipc	ra,0x0
    80001042:	f4e080e7          	jalr	-178(ra) # 80000f8c <uartputc_sync>
     uartputc_sync('\b');   // 光标再后退一位
    80001046:	4521                	li	a0,8
    80001048:	00000097          	auipc	ra,0x0
    8000104c:	f44080e7          	jalr	-188(ra) # 80000f8c <uartputc_sync>
  } else {
    // 普通字符直接传递给硬件层
    uartputc_sync(c);
  }
}
    80001050:	a801                	j	80001060 <consputc+0x4e>
    uartputc_sync(c);
    80001052:	fec42783          	lw	a5,-20(s0)
    80001056:	853e                	mv	a0,a5
    80001058:	00000097          	auipc	ra,0x0
    8000105c:	f34080e7          	jalr	-204(ra) # 80000f8c <uartputc_sync>
}
    80001060:	0001                	nop
    80001062:	60e2                	ld	ra,24(sp)
    80001064:	6442                	ld	s0,16(sp)
    80001066:	6105                	add	sp,sp,32
    80001068:	8082                	ret

000000008000106a <consoleinit>:
/* 初始化函数 */
void consoleinit(void)
{
    8000106a:	1141                	add	sp,sp,-16
    8000106c:	e406                	sd	ra,8(sp)
    8000106e:	e022                	sd	s0,0(sp)
    80001070:	0800                	add	s0,sp,16
  uartinit();// 先初始化硬件层
    80001072:	00000097          	auipc	ra,0x0
    80001076:	ec8080e7          	jalr	-312(ra) # 80000f3a <uartinit>
  printfinit();    // 再初始化printf系统， printf系统依赖硬件工作
    8000107a:	00000097          	auipc	ra,0x0
    8000107e:	56a080e7          	jalr	1386(ra) # 800015e4 <printfinit>
}
    80001082:	0001                	nop
    80001084:	60a2                	ld	ra,8(sp)
    80001086:	6402                	ld	s0,0(sp)
    80001088:	0141                	add	sp,sp,16
    8000108a:	8082                	ret

000000008000108c <printint>:
volatile int panicked = 0;// 系统是否已经panic完成，崩溃处理完成

static char digits[] = "0123456789abcdef";// 数字字符映射表

static void printint(long long xx, int base, int sign)
{
    8000108c:	715d                	add	sp,sp,-80
    8000108e:	e486                	sd	ra,72(sp)
    80001090:	e0a2                	sd	s0,64(sp)
    80001092:	0880                	add	s0,sp,80
    80001094:	faa43c23          	sd	a0,-72(s0)
    80001098:	87ae                	mv	a5,a1
    8000109a:	8732                	mv	a4,a2
    8000109c:	faf42a23          	sw	a5,-76(s0)
    800010a0:	87ba                	mv	a5,a4
    800010a2:	faf42823          	sw	a5,-80(s0)
  unsigned long long x;       // 无符号版本的数字
// 关键：x是unsigned类型！
// -(-2147483648) 在unsigned中是安全的

  // 处理负数
  if(sign && (sign = (xx < 0)))
    800010a6:	fb042783          	lw	a5,-80(s0)
    800010aa:	2781                	sext.w	a5,a5
    800010ac:	c39d                	beqz	a5,800010d2 <printint+0x46>
    800010ae:	fb843783          	ld	a5,-72(s0)
    800010b2:	93fd                	srl	a5,a5,0x3f
    800010b4:	0ff7f793          	zext.b	a5,a5
    800010b8:	faf42823          	sw	a5,-80(s0)
    800010bc:	fb042783          	lw	a5,-80(s0)
    800010c0:	2781                	sext.w	a5,a5
    800010c2:	cb81                	beqz	a5,800010d2 <printint+0x46>
    x = -xx; // 转为正数处理
    800010c4:	fb843783          	ld	a5,-72(s0)
    800010c8:	40f007b3          	neg	a5,a5
    800010cc:	fef43023          	sd	a5,-32(s0)
    800010d0:	a029                	j	800010da <printint+0x4e>
  else
    x = xx;
    800010d2:	fb843783          	ld	a5,-72(s0)
    800010d6:	fef43023          	sd	a5,-32(s0)

//  多位数：提取每一位数字
  i = 0;
    800010da:	fe042623          	sw	zero,-20(s0)
  do {
    buf[i++] = digits[x % base]; // 取余数，得到最低位
    800010de:	fb442783          	lw	a5,-76(s0)
    800010e2:	fe043703          	ld	a4,-32(s0)
    800010e6:	02f77733          	remu	a4,a4,a5
    800010ea:	fec42783          	lw	a5,-20(s0)
    800010ee:	0017869b          	addw	a3,a5,1
    800010f2:	fed42623          	sw	a3,-20(s0)
    800010f6:	00006697          	auipc	a3,0x6
    800010fa:	f0a68693          	add	a3,a3,-246 # 80007000 <digits>
    800010fe:	9736                	add	a4,a4,a3
    80001100:	00074703          	lbu	a4,0(a4)
    80001104:	17c1                	add	a5,a5,-16
    80001106:	97a2                	add	a5,a5,s0
    80001108:	fce78c23          	sb	a4,-40(a5)
        // 关键：使用digits数组将数字映射为字符
        // 例如：x=42, base=10
        // 第一次：42 % 10 = 2 → buf[0] = '2'
        // 第二次：4 % 10 = 4 → buf[1] = '4' 
  } while((x /= base) != 0);// 整除，处理下一位
    8000110c:	fb442783          	lw	a5,-76(s0)
    80001110:	fe043703          	ld	a4,-32(s0)
    80001114:	02f757b3          	divu	a5,a4,a5
    80001118:	fef43023          	sd	a5,-32(s0)
    8000111c:	fe043783          	ld	a5,-32(s0)
    80001120:	ffdd                	bnez	a5,800010de <printint+0x52>
// 用do while而不是while,确保x=0时也能输出'0'
// 添加负号

  if(sign)
    80001122:	fb042783          	lw	a5,-80(s0)
    80001126:	2781                	sext.w	a5,a5
    80001128:	cb95                	beqz	a5,8000115c <printint+0xd0>
    buf[i++] = '-';
    8000112a:	fec42783          	lw	a5,-20(s0)
    8000112e:	0017871b          	addw	a4,a5,1
    80001132:	fee42623          	sw	a4,-20(s0)
    80001136:	17c1                	add	a5,a5,-16
    80001138:	97a2                	add	a5,a5,s0
    8000113a:	02d00713          	li	a4,45
    8000113e:	fce78c23          	sb	a4,-40(a5)
// 逆序输出（因为是从低位到高位提取的）
  while(--i >= 0)
    80001142:	a829                	j	8000115c <printint+0xd0>
    consputc(buf[i]);
    80001144:	fec42783          	lw	a5,-20(s0)
    80001148:	17c1                	add	a5,a5,-16
    8000114a:	97a2                	add	a5,a5,s0
    8000114c:	fd87c783          	lbu	a5,-40(a5)
    80001150:	2781                	sext.w	a5,a5
    80001152:	853e                	mv	a0,a5
    80001154:	00000097          	auipc	ra,0x0
    80001158:	ebe080e7          	jalr	-322(ra) # 80001012 <consputc>
  while(--i >= 0)
    8000115c:	fec42783          	lw	a5,-20(s0)
    80001160:	37fd                	addw	a5,a5,-1
    80001162:	fef42623          	sw	a5,-20(s0)
    80001166:	fec42783          	lw	a5,-20(s0)
    8000116a:	2781                	sext.w	a5,a5
    8000116c:	fc07dce3          	bgez	a5,80001144 <printint+0xb8>
}
    80001170:	0001                	nop
    80001172:	0001                	nop
    80001174:	60a6                	ld	ra,72(sp)
    80001176:	6406                	ld	s0,64(sp)
    80001178:	6161                	add	sp,sp,80
    8000117a:	8082                	ret

000000008000117c <printptr>:




static void printptr(uint64 x)
{
    8000117c:	7179                	add	sp,sp,-48
    8000117e:	f406                	sd	ra,40(sp)
    80001180:	f022                	sd	s0,32(sp)
    80001182:	1800                	add	s0,sp,48
    80001184:	fca43c23          	sd	a0,-40(s0)
  int i;
  
  // 第1步：先输出"0x"前缀，表示这是十六进制地址
  consputc('0');
    80001188:	03000513          	li	a0,48
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	e86080e7          	jalr	-378(ra) # 80001012 <consputc>
  consputc('x');
    80001194:	07800513          	li	a0,120
    80001198:	00000097          	auipc	ra,0x0
    8000119c:	e7a080e7          	jalr	-390(ra) # 80001012 <consputc>
  
  // 第2步：循环输出地址的每一位十六进制数字
  // sizeof(uint64) * 2 = 8 * 2 = 16位十六进制数字
  // 64位地址需要16个十六进制字符来表示
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4) {
    800011a0:	fe042623          	sw	zero,-20(s0)
    800011a4:	a81d                	j	800011da <printptr+0x5e>
    // 每次取出最高4位来输出
    // x >> (sizeof(uint64) * 8 - 4) 就是 x >> 60
    // 这样每次都取最高的4位（一个十六进制数字）
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800011a6:	fd843783          	ld	a5,-40(s0)
    800011aa:	93f1                	srl	a5,a5,0x3c
    800011ac:	00006717          	auipc	a4,0x6
    800011b0:	e5470713          	add	a4,a4,-428 # 80007000 <digits>
    800011b4:	97ba                	add	a5,a5,a4
    800011b6:	0007c783          	lbu	a5,0(a5)
    800011ba:	2781                	sext.w	a5,a5
    800011bc:	853e                	mv	a0,a5
    800011be:	00000097          	auipc	ra,0x0
    800011c2:	e54080e7          	jalr	-428(ra) # 80001012 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4) {
    800011c6:	fec42783          	lw	a5,-20(s0)
    800011ca:	2785                	addw	a5,a5,1
    800011cc:	fef42623          	sw	a5,-20(s0)
    800011d0:	fd843783          	ld	a5,-40(s0)
    800011d4:	0792                	sll	a5,a5,0x4
    800011d6:	fcf43c23          	sd	a5,-40(s0)
    800011da:	fec42783          	lw	a5,-20(s0)
    800011de:	873e                	mv	a4,a5
    800011e0:	47bd                	li	a5,15
    800011e2:	fce7f2e3          	bgeu	a5,a4,800011a6 <printptr+0x2a>
    // 然后 x <<= 4，把下一组4位移到最高位
  }
}
    800011e6:	0001                	nop
    800011e8:	0001                	nop
    800011ea:	70a2                	ld	ra,40(sp)
    800011ec:	7402                	ld	s0,32(sp)
    800011ee:	6145                	add	sp,sp,48
    800011f0:	8082                	ret

00000000800011f2 <printf>:

/* printf() - 格式字符串解析 */
int printf(char *fmt, ...)
{
    800011f2:	7175                	add	sp,sp,-144
    800011f4:	e486                	sd	ra,72(sp)
    800011f6:	e0a2                	sd	s0,64(sp)
    800011f8:	0880                	add	s0,sp,80
    800011fa:	faa43c23          	sd	a0,-72(s0)
    800011fe:	e40c                	sd	a1,8(s0)
    80001200:	e810                	sd	a2,16(s0)
    80001202:	ec14                	sd	a3,24(s0)
    80001204:	f018                	sd	a4,32(s0)
    80001206:	f41c                	sd	a5,40(s0)
    80001208:	03043823          	sd	a6,48(s0)
    8000120c:	03143c23          	sd	a7,56(s0)
  va_list ap;                 // 可变参数列表
  int i, cx, c0, c1, c2;      // 字符和索引变量
  char *s;                    // 字符串指针

  va_start(ap, fmt);          // 初始化参数列表
    80001210:	04040793          	add	a5,s0,64
    80001214:	faf43823          	sd	a5,-80(s0)
    80001218:	fb043783          	ld	a5,-80(s0)
    8000121c:	fc878793          	add	a5,a5,-56
    80001220:	fcf43423          	sd	a5,-56(s0)
// 主循环：逐字符解析格式字符串
  for(i = 0; (cx = fmt[i] & 0xff) != 0; i++){
    80001224:	fe042623          	sw	zero,-20(s0)
    80001228:	a691                	j	8000156c <printf+0x37a>
    if(cx != '%'){
    8000122a:	fd442783          	lw	a5,-44(s0)
    8000122e:	0007871b          	sext.w	a4,a5
    80001232:	02500793          	li	a5,37
    80001236:	00f70a63          	beq	a4,a5,8000124a <printf+0x58>
      // 普通字符直接输出
      consputc(cx);
    8000123a:	fd442783          	lw	a5,-44(s0)
    8000123e:	853e                	mv	a0,a5
    80001240:	00000097          	auipc	ra,0x0
    80001244:	dd2080e7          	jalr	-558(ra) # 80001012 <consputc>
      continue;
    80001248:	ae29                	j	80001562 <printf+0x370>
    }
    // 遇到%，开始解析格式符
    i++;
    8000124a:	fec42783          	lw	a5,-20(s0)
    8000124e:	2785                	addw	a5,a5,1
    80001250:	fef42623          	sw	a5,-20(s0)
    c0 = fmt[i+0] & 0xff;   // 格式符的第一个字符
    80001254:	fec42783          	lw	a5,-20(s0)
    80001258:	fb843703          	ld	a4,-72(s0)
    8000125c:	97ba                	add	a5,a5,a4
    8000125e:	0007c783          	lbu	a5,0(a5)
    80001262:	fcf42823          	sw	a5,-48(s0)
    c1 = c2 = 0;
    80001266:	fe042223          	sw	zero,-28(s0)
    8000126a:	fe442783          	lw	a5,-28(s0)
    8000126e:	fef42423          	sw	a5,-24(s0)
    if(c0) c1 = fmt[i+1] & 0xff;  // 可能的第二个字符（如%ld中的d）
    80001272:	fd042783          	lw	a5,-48(s0)
    80001276:	2781                	sext.w	a5,a5
    80001278:	cb99                	beqz	a5,8000128e <printf+0x9c>
    8000127a:	fec42783          	lw	a5,-20(s0)
    8000127e:	0785                	add	a5,a5,1
    80001280:	fb843703          	ld	a4,-72(s0)
    80001284:	97ba                	add	a5,a5,a4
    80001286:	0007c783          	lbu	a5,0(a5)
    8000128a:	fef42423          	sw	a5,-24(s0)
    if(c1) c2 = fmt[i+2] & 0xff;  // 可能的第三个字符（如%lld中的第二个d）
    8000128e:	fe842783          	lw	a5,-24(s0)
    80001292:	2781                	sext.w	a5,a5
    80001294:	cb99                	beqz	a5,800012aa <printf+0xb8>
    80001296:	fec42783          	lw	a5,-20(s0)
    8000129a:	0789                	add	a5,a5,2
    8000129c:	fb843703          	ld	a4,-72(s0)
    800012a0:	97ba                	add	a5,a5,a4
    800012a2:	0007c783          	lbu	a5,0(a5)
    800012a6:	fef42223          	sw	a5,-28(s0)

    // 格式符处理 - 支持xv6的所有主要格式。普通字符直接输出，遇到%进入格式处理状态
    if(c0 == 'd') { 
    800012aa:	fd042783          	lw	a5,-48(s0)
    800012ae:	0007871b          	sext.w	a4,a5
    800012b2:	06400793          	li	a5,100
    800012b6:	02f71163          	bne	a4,a5,800012d8 <printf+0xe6>
       // %d - 32位有符号整数   
      printint(va_arg(ap, int), 10, 1);
    800012ba:	fc843783          	ld	a5,-56(s0)
    800012be:	00878713          	add	a4,a5,8
    800012c2:	fce43423          	sd	a4,-56(s0)
    800012c6:	439c                	lw	a5,0(a5)
    800012c8:	4605                	li	a2,1
    800012ca:	45a9                	li	a1,10
    800012cc:	853e                	mv	a0,a5
    800012ce:	00000097          	auipc	ra,0x0
    800012d2:	dbe080e7          	jalr	-578(ra) # 8000108c <printint>
    800012d6:	a471                	j	80001562 <printf+0x370>
    } else if(c0 == 'l' && c1 == 'd'){
    800012d8:	fd042783          	lw	a5,-48(s0)
    800012dc:	0007871b          	sext.w	a4,a5
    800012e0:	06c00793          	li	a5,108
    800012e4:	02f71e63          	bne	a4,a5,80001320 <printf+0x12e>
    800012e8:	fe842783          	lw	a5,-24(s0)
    800012ec:	0007871b          	sext.w	a4,a5
    800012f0:	06400793          	li	a5,100
    800012f4:	02f71663          	bne	a4,a5,80001320 <printf+0x12e>
      // %ld - 64位有符号整数
      printint(va_arg(ap, uint64), 10, 1);
    800012f8:	fc843783          	ld	a5,-56(s0)
    800012fc:	00878713          	add	a4,a5,8
    80001300:	fce43423          	sd	a4,-56(s0)
    80001304:	639c                	ld	a5,0(a5)
    80001306:	4605                	li	a2,1
    80001308:	45a9                	li	a1,10
    8000130a:	853e                	mv	a0,a5
    8000130c:	00000097          	auipc	ra,0x0
    80001310:	d80080e7          	jalr	-640(ra) # 8000108c <printint>
      i += 1;// 跳过额外的字符
    80001314:	fec42783          	lw	a5,-20(s0)
    80001318:	2785                	addw	a5,a5,1
    8000131a:	fef42623          	sw	a5,-20(s0)
    8000131e:	a491                	j	80001562 <printf+0x370>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
    80001320:	fd042783          	lw	a5,-48(s0)
    80001324:	0007871b          	sext.w	a4,a5
    80001328:	06c00793          	li	a5,108
    8000132c:	04f71663          	bne	a4,a5,80001378 <printf+0x186>
    80001330:	fe842783          	lw	a5,-24(s0)
    80001334:	0007871b          	sext.w	a4,a5
    80001338:	06c00793          	li	a5,108
    8000133c:	02f71e63          	bne	a4,a5,80001378 <printf+0x186>
    80001340:	fe442783          	lw	a5,-28(s0)
    80001344:	0007871b          	sext.w	a4,a5
    80001348:	06400793          	li	a5,100
    8000134c:	02f71663          	bne	a4,a5,80001378 <printf+0x186>
      // %lld - 64位有符号整数（与%ld相同，但为兼容性）
      printint(va_arg(ap, uint64), 10, 1);
    80001350:	fc843783          	ld	a5,-56(s0)
    80001354:	00878713          	add	a4,a5,8
    80001358:	fce43423          	sd	a4,-56(s0)
    8000135c:	639c                	ld	a5,0(a5)
    8000135e:	4605                	li	a2,1
    80001360:	45a9                	li	a1,10
    80001362:	853e                	mv	a0,a5
    80001364:	00000097          	auipc	ra,0x0
    80001368:	d28080e7          	jalr	-728(ra) # 8000108c <printint>
      i += 2;// 跳过额外的字符
    8000136c:	fec42783          	lw	a5,-20(s0)
    80001370:	2789                	addw	a5,a5,2
    80001372:	fef42623          	sw	a5,-20(s0)
    80001376:	a2f5                	j	80001562 <printf+0x370>
    } else if(c0 == 'u'){
    80001378:	fd042783          	lw	a5,-48(s0)
    8000137c:	0007871b          	sext.w	a4,a5
    80001380:	07500793          	li	a5,117
    80001384:	02f71363          	bne	a4,a5,800013aa <printf+0x1b8>
      // %u - 32位无符号整数
      printint(va_arg(ap, uint32), 10, 0);
    80001388:	fc843783          	ld	a5,-56(s0)
    8000138c:	00878713          	add	a4,a5,8
    80001390:	fce43423          	sd	a4,-56(s0)
    80001394:	439c                	lw	a5,0(a5)
    80001396:	1782                	sll	a5,a5,0x20
    80001398:	9381                	srl	a5,a5,0x20
    8000139a:	4601                	li	a2,0
    8000139c:	45a9                	li	a1,10
    8000139e:	853e                	mv	a0,a5
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	cec080e7          	jalr	-788(ra) # 8000108c <printint>
    800013a8:	aa6d                	j	80001562 <printf+0x370>
    } else if(c0 == 'l' && c1 == 'u'){
    800013aa:	fd042783          	lw	a5,-48(s0)
    800013ae:	0007871b          	sext.w	a4,a5
    800013b2:	06c00793          	li	a5,108
    800013b6:	02f71e63          	bne	a4,a5,800013f2 <printf+0x200>
    800013ba:	fe842783          	lw	a5,-24(s0)
    800013be:	0007871b          	sext.w	a4,a5
    800013c2:	07500793          	li	a5,117
    800013c6:	02f71663          	bne	a4,a5,800013f2 <printf+0x200>
      printint(va_arg(ap, uint64), 10, 0);
    800013ca:	fc843783          	ld	a5,-56(s0)
    800013ce:	00878713          	add	a4,a5,8
    800013d2:	fce43423          	sd	a4,-56(s0)
    800013d6:	639c                	ld	a5,0(a5)
    800013d8:	4601                	li	a2,0
    800013da:	45a9                	li	a1,10
    800013dc:	853e                	mv	a0,a5
    800013de:	00000097          	auipc	ra,0x0
    800013e2:	cae080e7          	jalr	-850(ra) # 8000108c <printint>
      i += 1;
    800013e6:	fec42783          	lw	a5,-20(s0)
    800013ea:	2785                	addw	a5,a5,1
    800013ec:	fef42623          	sw	a5,-20(s0)
    800013f0:	aa8d                	j	80001562 <printf+0x370>
    } else if(c0 == 'x'){// %x - 32位十六进制
    800013f2:	fd042783          	lw	a5,-48(s0)
    800013f6:	0007871b          	sext.w	a4,a5
    800013fa:	07800793          	li	a5,120
    800013fe:	02f71363          	bne	a4,a5,80001424 <printf+0x232>
      printint(va_arg(ap, uint32), 16, 0);
    80001402:	fc843783          	ld	a5,-56(s0)
    80001406:	00878713          	add	a4,a5,8
    8000140a:	fce43423          	sd	a4,-56(s0)
    8000140e:	439c                	lw	a5,0(a5)
    80001410:	1782                	sll	a5,a5,0x20
    80001412:	9381                	srl	a5,a5,0x20
    80001414:	4601                	li	a2,0
    80001416:	45c1                	li	a1,16
    80001418:	853e                	mv	a0,a5
    8000141a:	00000097          	auipc	ra,0x0
    8000141e:	c72080e7          	jalr	-910(ra) # 8000108c <printint>
    80001422:	a281                	j	80001562 <printf+0x370>
    } else if(c0 == 'l' && c1 == 'x'){
    80001424:	fd042783          	lw	a5,-48(s0)
    80001428:	0007871b          	sext.w	a4,a5
    8000142c:	06c00793          	li	a5,108
    80001430:	02f71e63          	bne	a4,a5,8000146c <printf+0x27a>
    80001434:	fe842783          	lw	a5,-24(s0)
    80001438:	0007871b          	sext.w	a4,a5
    8000143c:	07800793          	li	a5,120
    80001440:	02f71663          	bne	a4,a5,8000146c <printf+0x27a>
      printint(va_arg(ap, uint64), 16, 0);
    80001444:	fc843783          	ld	a5,-56(s0)
    80001448:	00878713          	add	a4,a5,8
    8000144c:	fce43423          	sd	a4,-56(s0)
    80001450:	639c                	ld	a5,0(a5)
    80001452:	4601                	li	a2,0
    80001454:	45c1                	li	a1,16
    80001456:	853e                	mv	a0,a5
    80001458:	00000097          	auipc	ra,0x0
    8000145c:	c34080e7          	jalr	-972(ra) # 8000108c <printint>
      i += 1;
    80001460:	fec42783          	lw	a5,-20(s0)
    80001464:	2785                	addw	a5,a5,1
    80001466:	fef42623          	sw	a5,-20(s0)
    8000146a:	a8e5                	j	80001562 <printf+0x370>
    } else if(c0 == 'p'){// %p - 指针地址
    8000146c:	fd042783          	lw	a5,-48(s0)
    80001470:	0007871b          	sext.w	a4,a5
    80001474:	07000793          	li	a5,112
    80001478:	00f71f63          	bne	a4,a5,80001496 <printf+0x2a4>
      printptr(va_arg(ap, uint64));
    8000147c:	fc843783          	ld	a5,-56(s0)
    80001480:	00878713          	add	a4,a5,8
    80001484:	fce43423          	sd	a4,-56(s0)
    80001488:	639c                	ld	a5,0(a5)
    8000148a:	853e                	mv	a0,a5
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	cf0080e7          	jalr	-784(ra) # 8000117c <printptr>
    80001494:	a0f9                	j	80001562 <printf+0x370>
    } else if(c0 == 'c'){// %c - 单个字符
    80001496:	fd042783          	lw	a5,-48(s0)
    8000149a:	0007871b          	sext.w	a4,a5
    8000149e:	06300793          	li	a5,99
    800014a2:	02f71063          	bne	a4,a5,800014c2 <printf+0x2d0>
      consputc(va_arg(ap, uint));
    800014a6:	fc843783          	ld	a5,-56(s0)
    800014aa:	00878713          	add	a4,a5,8
    800014ae:	fce43423          	sd	a4,-56(s0)
    800014b2:	439c                	lw	a5,0(a5)
    800014b4:	2781                	sext.w	a5,a5
    800014b6:	853e                	mv	a0,a5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	b5a080e7          	jalr	-1190(ra) # 80001012 <consputc>
    800014c0:	a04d                	j	80001562 <printf+0x370>
    } else if(c0 == 's'){// %s - 字符串
    800014c2:	fd042783          	lw	a5,-48(s0)
    800014c6:	0007871b          	sext.w	a4,a5
    800014ca:	07300793          	li	a5,115
    800014ce:	04f71a63          	bne	a4,a5,80001522 <printf+0x330>
      // 第1步：从参数列表中取出字符串指针
      if((s = va_arg(ap, char*)) == 0)// 检查是否为NULL
    800014d2:	fc843783          	ld	a5,-56(s0)
    800014d6:	00878713          	add	a4,a5,8
    800014da:	fce43423          	sd	a4,-56(s0)
    800014de:	639c                	ld	a5,0(a5)
    800014e0:	fcf43c23          	sd	a5,-40(s0)
    800014e4:	fd843783          	ld	a5,-40(s0)
    800014e8:	e79d                	bnez	a5,80001516 <printf+0x324>
        s = "(null)";// 如果是NULL，替换成安全的字符串
    800014ea:	00004797          	auipc	a5,0x4
    800014ee:	3d678793          	add	a5,a5,982 # 800058c0 <etext+0x8c0>
    800014f2:	fcf43c23          	sd	a5,-40(s0)
      // 第2步：逐字符输出
      for(; *s; s++)
    800014f6:	a005                	j	80001516 <printf+0x324>
        consputc(*s);
    800014f8:	fd843783          	ld	a5,-40(s0)
    800014fc:	0007c783          	lbu	a5,0(a5)
    80001500:	2781                	sext.w	a5,a5
    80001502:	853e                	mv	a0,a5
    80001504:	00000097          	auipc	ra,0x0
    80001508:	b0e080e7          	jalr	-1266(ra) # 80001012 <consputc>
      for(; *s; s++)
    8000150c:	fd843783          	ld	a5,-40(s0)
    80001510:	0785                	add	a5,a5,1
    80001512:	fcf43c23          	sd	a5,-40(s0)
    80001516:	fd843783          	ld	a5,-40(s0)
    8000151a:	0007c783          	lbu	a5,0(a5)
    8000151e:	ffe9                	bnez	a5,800014f8 <printf+0x306>
    80001520:	a089                	j	80001562 <printf+0x370>
    } else if(c0 == '%'){// %% - 输出字面的%
    80001522:	fd042783          	lw	a5,-48(s0)
    80001526:	0007871b          	sext.w	a4,a5
    8000152a:	02500793          	li	a5,37
    8000152e:	00f71963          	bne	a4,a5,80001540 <printf+0x34e>
      consputc('%');
    80001532:	02500513          	li	a0,37
    80001536:	00000097          	auipc	ra,0x0
    8000153a:	adc080e7          	jalr	-1316(ra) # 80001012 <consputc>
    8000153e:	a015                	j	80001562 <printf+0x370>
    } else if(c0 == 0){
    80001540:	fd042783          	lw	a5,-48(s0)
    80001544:	2781                	sext.w	a5,a5
    80001546:	c3b1                	beqz	a5,8000158a <printf+0x398>
      break;
    } else {// 未知格式符 - 原样输出便于调试
      consputc('%');
    80001548:	02500513          	li	a0,37
    8000154c:	00000097          	auipc	ra,0x0
    80001550:	ac6080e7          	jalr	-1338(ra) # 80001012 <consputc>
      consputc(c0);
    80001554:	fd042783          	lw	a5,-48(s0)
    80001558:	853e                	mv	a0,a5
    8000155a:	00000097          	auipc	ra,0x0
    8000155e:	ab8080e7          	jalr	-1352(ra) # 80001012 <consputc>
  for(i = 0; (cx = fmt[i] & 0xff) != 0; i++){
    80001562:	fec42783          	lw	a5,-20(s0)
    80001566:	2785                	addw	a5,a5,1
    80001568:	fef42623          	sw	a5,-20(s0)
    8000156c:	fec42783          	lw	a5,-20(s0)
    80001570:	fb843703          	ld	a4,-72(s0)
    80001574:	97ba                	add	a5,a5,a4
    80001576:	0007c783          	lbu	a5,0(a5)
    8000157a:	fcf42a23          	sw	a5,-44(s0)
    8000157e:	fd442783          	lw	a5,-44(s0)
    80001582:	2781                	sext.w	a5,a5
    80001584:	ca0793e3          	bnez	a5,8000122a <printf+0x38>
    80001588:	a011                	j	8000158c <printf+0x39a>
      break;
    8000158a:	0001                	nop
    }
  }
  va_end(ap);// 清理参数列表

  return 0;
    8000158c:	4781                	li	a5,0
}
    8000158e:	853e                	mv	a0,a5
    80001590:	60a6                	ld	ra,72(sp)
    80001592:	6406                	ld	s0,64(sp)
    80001594:	6149                	add	sp,sp,144
    80001596:	8082                	ret

0000000080001598 <panic>:

void panic(char *s)
{
    80001598:	1101                	add	sp,sp,-32
    8000159a:	ec06                	sd	ra,24(sp)
    8000159c:	e822                	sd	s0,16(sp)
    8000159e:	1000                	add	s0,sp,32
    800015a0:	fea43423          	sd	a0,-24(s0)
  // 第1步：设置全局标志，告诉其他部分"系统要崩溃了"
  panicking = 1;
    800015a4:	0000f797          	auipc	a5,0xf
    800015a8:	a5c78793          	add	a5,a5,-1444 # 80010000 <panicking>
    800015ac:	4705                	li	a4,1
    800015ae:	c398                	sw	a4,0(a5)
  
  // 第2步：输出崩溃信息，让程序员知道出了什么问题
  printf("panic: ");        // 固定前缀，表示这是系统崩溃
    800015b0:	00004517          	auipc	a0,0x4
    800015b4:	31850513          	add	a0,a0,792 # 800058c8 <etext+0x8c8>
    800015b8:	00000097          	auipc	ra,0x0
    800015bc:	c3a080e7          	jalr	-966(ra) # 800011f2 <printf>
  printf("%s\n", s);        // 输出具体的错误信息
    800015c0:	fe843583          	ld	a1,-24(s0)
    800015c4:	00004517          	auipc	a0,0x4
    800015c8:	30c50513          	add	a0,a0,780 # 800058d0 <etext+0x8d0>
    800015cc:	00000097          	auipc	ra,0x0
    800015d0:	c26080e7          	jalr	-986(ra) # 800011f2 <printf>
  
  // 第3步：标记崩溃处理完成
  // 这时其他部分看到这个标志就知道不要再输出了
  panicked = 1;
    800015d4:	0000f797          	auipc	a5,0xf
    800015d8:	a3078793          	add	a5,a5,-1488 # 80010004 <panicked>
    800015dc:	4705                	li	a4,1
    800015de:	c398                	sw	a4,0(a5)
  
  // 第4步：进入无限循环，让系统停止运行
  for(;;)
    800015e0:	0001                	nop
    800015e2:	bffd                	j	800015e0 <panic+0x48>

00000000800015e4 <printfinit>:
    ;  // 空循环，CPU在这里永远转圈
}

void printfinit(void)
{
    800015e4:	1141                	add	sp,sp,-16
    800015e6:	e422                	sd	s0,8(sp)
    800015e8:	0800                	add	s0,sp,16
  /* 简化版本，不需要锁初始化 */
}
    800015ea:	0001                	nop
    800015ec:	6422                	ld	s0,8(sp)
    800015ee:	0141                	add	sp,sp,16
    800015f0:	8082                	ret

00000000800015f2 <clear_screen>:
#include "types.h"
#include "defs.h"

/* 清屏函数 */
void clear_screen(void)
{
    800015f2:	1141                	add	sp,sp,-16
    800015f4:	e406                	sd	ra,8(sp)
    800015f6:	e022                	sd	s0,0(sp)
    800015f8:	0800                	add	s0,sp,16
  /* 直接输出ANSI转义序列，避免复杂的printf格式化 */
   // 发送ANSI转义序列：ESC[2J ESC[H
  consputc('\033');  /* ESC */
    800015fa:	456d                	li	a0,27
    800015fc:	00000097          	auipc	ra,0x0
    80001600:	a16080e7          	jalr	-1514(ra) # 80001012 <consputc>
  consputc('[');// 开始ANSI序列
    80001604:	05b00513          	li	a0,91
    80001608:	00000097          	auipc	ra,0x0
    8000160c:	a0a080e7          	jalr	-1526(ra) # 80001012 <consputc>
  consputc('2');     // 清屏命令参数
    80001610:	03200513          	li	a0,50
    80001614:	00000097          	auipc	ra,0x0
    80001618:	9fe080e7          	jalr	-1538(ra) # 80001012 <consputc>
  consputc('J');     /* 清除整个屏幕 */
    8000161c:	04a00513          	li	a0,74
    80001620:	00000097          	auipc	ra,0x0
    80001624:	9f2080e7          	jalr	-1550(ra) # 80001012 <consputc>
  consputc('\033');  /* ESC */
    80001628:	456d                	li	a0,27
    8000162a:	00000097          	auipc	ra,0x0
    8000162e:	9e8080e7          	jalr	-1560(ra) # 80001012 <consputc>
  consputc('[');
    80001632:	05b00513          	li	a0,91
    80001636:	00000097          	auipc	ra,0x0
    8000163a:	9dc080e7          	jalr	-1572(ra) # 80001012 <consputc>
  consputc('H');     /* 光标回到左上角 */
    8000163e:	04800513          	li	a0,72
    80001642:	00000097          	auipc	ra,0x0
    80001646:	9d0080e7          	jalr	-1584(ra) # 80001012 <consputc>
}
    8000164a:	0001                	nop
    8000164c:	60a2                	ld	ra,8(sp)
    8000164e:	6402                	ld	s0,0(sp)
    80001650:	0141                	add	sp,sp,16
    80001652:	8082                	ret

0000000080001654 <print_number>:

/* 数字输出辅助函数 */
static void print_number(int num)
{
    80001654:	1101                	add	sp,sp,-32
    80001656:	ec06                	sd	ra,24(sp)
    80001658:	e822                	sd	s0,16(sp)
    8000165a:	1000                	add	s0,sp,32
    8000165c:	87aa                	mv	a5,a0
    8000165e:	fef42623          	sw	a5,-20(s0)
  if(num >= 10) {
    80001662:	fec42783          	lw	a5,-20(s0)
    80001666:	0007871b          	sext.w	a4,a5
    8000166a:	47a5                	li	a5,9
    8000166c:	00e7de63          	bge	a5,a4,80001688 <print_number+0x34>
    print_number(num / 10);// 递归处理高位
    80001670:	fec42783          	lw	a5,-20(s0)
    80001674:	873e                	mv	a4,a5
    80001676:	47a9                	li	a5,10
    80001678:	02f747bb          	divw	a5,a4,a5
    8000167c:	2781                	sext.w	a5,a5
    8000167e:	853e                	mv	a0,a5
    80001680:	00000097          	auipc	ra,0x0
    80001684:	fd4080e7          	jalr	-44(ra) # 80001654 <print_number>
  }
  consputc('0' + (num % 10));// 输出当前位
    80001688:	fec42783          	lw	a5,-20(s0)
    8000168c:	873e                	mv	a4,a5
    8000168e:	47a9                	li	a5,10
    80001690:	02f767bb          	remw	a5,a4,a5
    80001694:	2781                	sext.w	a5,a5
    80001696:	0307879b          	addw	a5,a5,48
    8000169a:	2781                	sext.w	a5,a5
    8000169c:	853e                	mv	a0,a5
    8000169e:	00000097          	auipc	ra,0x0
    800016a2:	974080e7          	jalr	-1676(ra) # 80001012 <consputc>
}
    800016a6:	0001                	nop
    800016a8:	60e2                	ld	ra,24(sp)
    800016aa:	6442                	ld	s0,16(sp)
    800016ac:	6105                	add	sp,sp,32
    800016ae:	8082                	ret

00000000800016b0 <set_cursor>:
// 5. 返回步骤1，输出 '3'
// 结果：输出 "123"

/* 光标定位函数 */
void set_cursor(int x, int y)
{
    800016b0:	1101                	add	sp,sp,-32
    800016b2:	ec06                	sd	ra,24(sp)
    800016b4:	e822                	sd	s0,16(sp)
    800016b6:	1000                	add	s0,sp,32
    800016b8:	87aa                	mv	a5,a0
    800016ba:	872e                	mv	a4,a1
    800016bc:	fef42623          	sw	a5,-20(s0)
    800016c0:	87ba                	mv	a5,a4
    800016c2:	fef42423          	sw	a5,-24(s0)
  // 发送ANSI序列：ESC[y;xH
  consputc('\033');  /* ESC */
    800016c6:	456d                	li	a0,27
    800016c8:	00000097          	auipc	ra,0x0
    800016cc:	94a080e7          	jalr	-1718(ra) # 80001012 <consputc>
  consputc('[');
    800016d0:	05b00513          	li	a0,91
    800016d4:	00000097          	auipc	ra,0x0
    800016d8:	93e080e7          	jalr	-1730(ra) # 80001012 <consputc>
  print_number(y);// 行号
    800016dc:	fe842783          	lw	a5,-24(s0)
    800016e0:	853e                	mv	a0,a5
    800016e2:	00000097          	auipc	ra,0x0
    800016e6:	f72080e7          	jalr	-142(ra) # 80001654 <print_number>
  consputc(';');     // 分隔符
    800016ea:	03b00513          	li	a0,59
    800016ee:	00000097          	auipc	ra,0x0
    800016f2:	924080e7          	jalr	-1756(ra) # 80001012 <consputc>
  print_number(x);   // 列号  
    800016f6:	fec42783          	lw	a5,-20(s0)
    800016fa:	853e                	mv	a0,a5
    800016fc:	00000097          	auipc	ra,0x0
    80001700:	f58080e7          	jalr	-168(ra) # 80001654 <print_number>
  consputc('H');     // 定位命令，移动光标
    80001704:	04800513          	li	a0,72
    80001708:	00000097          	auipc	ra,0x0
    8000170c:	90a080e7          	jalr	-1782(ra) # 80001012 <consputc>
}
    80001710:	0001                	nop
    80001712:	60e2                	ld	ra,24(sp)
    80001714:	6442                	ld	s0,16(sp)
    80001716:	6105                	add	sp,sp,32
    80001718:	8082                	ret

000000008000171a <memset>:
// 简单的memset实现 
// 用途：页面清零、安全擦除等
/*如果程序错误地访问已释放的页面，会读到全是1的数据
这种异常的数据模式很容易被发现，有助于调试
如果不填充，程序可能读到看似正常的旧数据，bug很难发现*/
void* memset(void *dst, int c, uint n) {
    8000171a:	7179                	add	sp,sp,-48
    8000171c:	f422                	sd	s0,40(sp)
    8000171e:	1800                	add	s0,sp,48
    80001720:	fca43c23          	sd	a0,-40(s0)
    80001724:	87ae                	mv	a5,a1
    80001726:	8732                	mv	a4,a2
    80001728:	fcf42a23          	sw	a5,-44(s0)
    8000172c:	87ba                	mv	a5,a4
    8000172e:	fcf42823          	sw	a5,-48(s0)
    char *cdst = (char*)dst;
    80001732:	fd843783          	ld	a5,-40(s0)
    80001736:	fef43023          	sd	a5,-32(s0)
    int i;
    // 逐字节填充，实现简单可靠
    for(i = 0; i < n; i++) {
    8000173a:	fe042623          	sw	zero,-20(s0)
    8000173e:	a00d                	j	80001760 <memset+0x46>
        cdst[i] = c;
    80001740:	fec42783          	lw	a5,-20(s0)
    80001744:	fe043703          	ld	a4,-32(s0)
    80001748:	97ba                	add	a5,a5,a4
    8000174a:	fd442703          	lw	a4,-44(s0)
    8000174e:	0ff77713          	zext.b	a4,a4
    80001752:	00e78023          	sb	a4,0(a5)
    for(i = 0; i < n; i++) {
    80001756:	fec42783          	lw	a5,-20(s0)
    8000175a:	2785                	addw	a5,a5,1
    8000175c:	fef42623          	sw	a5,-20(s0)
    80001760:	fec42703          	lw	a4,-20(s0)
    80001764:	fd042783          	lw	a5,-48(s0)
    80001768:	2781                	sext.w	a5,a5
    8000176a:	fcf76be3          	bltu	a4,a5,80001740 <memset+0x26>
    }
    return dst;
    8000176e:	fd843783          	ld	a5,-40(s0)
}
    80001772:	853e                	mv	a0,a5
    80001774:	7422                	ld	s0,40(sp)
    80001776:	6145                	add	sp,sp,48
    80001778:	8082                	ret

000000008000177a <pmm_init>:

// ==================== 初始化物理内存分配器 ====================
void pmm_init(void) {
    8000177a:	7179                	add	sp,sp,-48
    8000177c:	f406                	sd	ra,40(sp)
    8000177e:	f022                	sd	s0,32(sp)
    80001780:	1800                	add	s0,sp,48
    // 第一步：确定可分配内存范围
    // 内存布局: [内核代码+数据] [可分配区域] [内存结束]
    //          ^end           ^mem_start    ^PHYSTOP
    char *mem_start = (char*)PGROUNDUP((uint64)end);  // 内核结束后的第一个页面边界
    80001782:	0000f717          	auipc	a4,0xf
    80001786:	87e70713          	add	a4,a4,-1922 # 80010000 <panicking>
    8000178a:	6785                	lui	a5,0x1
    8000178c:	17fd                	add	a5,a5,-1 # fff <_start-0x7ffff001>
    8000178e:	973e                	add	a4,a4,a5
    80001790:	77fd                	lui	a5,0xfffff
    80001792:	8ff9                	and	a5,a5,a4
    80001794:	fef43023          	sd	a5,-32(s0)
    char *mem_end = (char*)PHYSTOP;                   // 物理内存结束位置
    80001798:	47c5                	li	a5,17
    8000179a:	07ee                	sll	a5,a5,0x1b
    8000179c:	fcf43c23          	sd	a5,-40(s0)
    
    // 第二步：初始化管理器状态
    kmem.freelist = 0;      // 空链表
    800017a0:	0000b797          	auipc	a5,0xb
    800017a4:	88078793          	add	a5,a5,-1920 # 8000c020 <kmem>
    800017a8:	0007b023          	sd	zero,0(a5)
    kmem.total_pages = 0;   // 计数器清零
    800017ac:	0000b797          	auipc	a5,0xb
    800017b0:	87478793          	add	a5,a5,-1932 # 8000c020 <kmem>
    800017b4:	0007b423          	sd	zero,8(a5)
    kmem.free_pages = 0;
    800017b8:	0000b797          	auipc	a5,0xb
    800017bc:	86878793          	add	a5,a5,-1944 # 8000c020 <kmem>
    800017c0:	0007b823          	sd	zero,16(a5)
    
    printf("PMM: Initializing memory from %p to %p\n", mem_start, mem_end);
    800017c4:	fd843603          	ld	a2,-40(s0)
    800017c8:	fe043583          	ld	a1,-32(s0)
    800017cc:	00004517          	auipc	a0,0x4
    800017d0:	10c50513          	add	a0,a0,268 # 800058d8 <etext+0x8d8>
    800017d4:	00000097          	auipc	ra,0x0
    800017d8:	a1e080e7          	jalr	-1506(ra) # 800011f2 <printf>
    
    // 第三步：构建空闲页面链表
    // 遍历所有可用页面，逐个加入空闲链表
    char *p;
    for(p = mem_start; p + PGSIZE <= mem_end; p += PGSIZE) {
    800017dc:	fe043783          	ld	a5,-32(s0)
    800017e0:	fef43423          	sd	a5,-24(s0)
    800017e4:	a089                	j	80001826 <pmm_init+0xac>
        // 为什么要清零？确保页面内容干净，避免信息泄露
        memset(p, 0, PGSIZE);
    800017e6:	6605                	lui	a2,0x1
    800017e8:	4581                	li	a1,0
    800017ea:	fe843503          	ld	a0,-24(s0)
    800017ee:	00000097          	auipc	ra,0x0
    800017f2:	f2c080e7          	jalr	-212(ra) # 8000171a <memset>
        // 调用free_page将页面加入链表，复用释放逻辑
        free_page(p);
    800017f6:	fe843503          	ld	a0,-24(s0)
    800017fa:	00000097          	auipc	ra,0x0
    800017fe:	0ee080e7          	jalr	238(ra) # 800018e8 <free_page>
        kmem.total_pages++;   // 统计总页面数
    80001802:	0000b797          	auipc	a5,0xb
    80001806:	81e78793          	add	a5,a5,-2018 # 8000c020 <kmem>
    8000180a:	679c                	ld	a5,8(a5)
    8000180c:	00178713          	add	a4,a5,1
    80001810:	0000b797          	auipc	a5,0xb
    80001814:	81078793          	add	a5,a5,-2032 # 8000c020 <kmem>
    80001818:	e798                	sd	a4,8(a5)
    for(p = mem_start; p + PGSIZE <= mem_end; p += PGSIZE) {
    8000181a:	fe843703          	ld	a4,-24(s0)
    8000181e:	6785                	lui	a5,0x1
    80001820:	97ba                	add	a5,a5,a4
    80001822:	fef43423          	sd	a5,-24(s0)
    80001826:	fe843703          	ld	a4,-24(s0)
    8000182a:	6785                	lui	a5,0x1
    8000182c:	97ba                	add	a5,a5,a4
    8000182e:	fd843703          	ld	a4,-40(s0)
    80001832:	faf77ae3          	bgeu	a4,a5,800017e6 <pmm_init+0x6c>
    }
    
    printf("PMM: Initialized %d pages (%d KB)\n", 
           (int)kmem.total_pages, (int)(kmem.total_pages * PGSIZE) / 1024);
    80001836:	0000a797          	auipc	a5,0xa
    8000183a:	7ea78793          	add	a5,a5,2026 # 8000c020 <kmem>
    8000183e:	679c                	ld	a5,8(a5)
    printf("PMM: Initialized %d pages (%d KB)\n", 
    80001840:	0007869b          	sext.w	a3,a5
           (int)kmem.total_pages, (int)(kmem.total_pages * PGSIZE) / 1024);
    80001844:	0000a797          	auipc	a5,0xa
    80001848:	7dc78793          	add	a5,a5,2012 # 8000c020 <kmem>
    8000184c:	679c                	ld	a5,8(a5)
    8000184e:	2781                	sext.w	a5,a5
    80001850:	00c7979b          	sllw	a5,a5,0xc
    80001854:	2781                	sext.w	a5,a5
    80001856:	2781                	sext.w	a5,a5
    printf("PMM: Initialized %d pages (%d KB)\n", 
    80001858:	41f7d71b          	sraw	a4,a5,0x1f
    8000185c:	0167571b          	srlw	a4,a4,0x16
    80001860:	9fb9                	addw	a5,a5,a4
    80001862:	40a7d79b          	sraw	a5,a5,0xa
    80001866:	2781                	sext.w	a5,a5
    80001868:	863e                	mv	a2,a5
    8000186a:	85b6                	mv	a1,a3
    8000186c:	00004517          	auipc	a0,0x4
    80001870:	09450513          	add	a0,a0,148 # 80005900 <etext+0x900>
    80001874:	00000097          	auipc	ra,0x0
    80001878:	97e080e7          	jalr	-1666(ra) # 800011f2 <printf>
}
    8000187c:	0001                	nop
    8000187e:	70a2                	ld	ra,40(sp)
    80001880:	7402                	ld	s0,32(sp)
    80001882:	6145                	add	sp,sp,48
    80001884:	8082                	ret

0000000080001886 <alloc_page>:

// ==================== 分配一个物理页面 ====================
// 算法特点：LIFO(后进先出)，最近释放的页面优先被分配
// 时间复杂度：O(1) - 仅涉及链表头操作
void* alloc_page(void) {
    80001886:	1101                	add	sp,sp,-32
    80001888:	ec06                	sd	ra,24(sp)
    8000188a:	e822                	sd	s0,16(sp)
    8000188c:	1000                	add	s0,sp,32
    struct run *r;
    
    // 从链表头取出一个空闲页面
    r = kmem.freelist;
    8000188e:	0000a797          	auipc	a5,0xa
    80001892:	79278793          	add	a5,a5,1938 # 8000c020 <kmem>
    80001896:	639c                	ld	a5,0(a5)
    80001898:	fef43423          	sd	a5,-24(s0)
    if(r) {
    8000189c:	fe843783          	ld	a5,-24(s0)
    800018a0:	cf8d                	beqz	a5,800018da <alloc_page+0x54>
        // 更新链表头指向下一个空闲页面
        kmem.freelist = r->next;
    800018a2:	fe843783          	ld	a5,-24(s0)
    800018a6:	6398                	ld	a4,0(a5)
    800018a8:	0000a797          	auipc	a5,0xa
    800018ac:	77878793          	add	a5,a5,1912 # 8000c020 <kmem>
    800018b0:	e398                	sd	a4,0(a5)
        kmem.free_pages--;      // 更新空闲页面计数
    800018b2:	0000a797          	auipc	a5,0xa
    800018b6:	76e78793          	add	a5,a5,1902 # 8000c020 <kmem>
    800018ba:	6b9c                	ld	a5,16(a5)
    800018bc:	fff78713          	add	a4,a5,-1
    800018c0:	0000a797          	auipc	a5,0xa
    800018c4:	76078793          	add	a5,a5,1888 # 8000c020 <kmem>
    800018c8:	eb98                	sd	a4,16(a5)
        
        // 安全措施：清零分配的页面，防止信息泄露
        // 确保新分配的页面内容是干净的
        memset((char*)r, 0, PGSIZE);
    800018ca:	6605                	lui	a2,0x1
    800018cc:	4581                	li	a1,0
    800018ce:	fe843503          	ld	a0,-24(s0)
    800018d2:	00000097          	auipc	ra,0x0
    800018d6:	e48080e7          	jalr	-440(ra) # 8000171a <memset>
    }
    // 如果r为NULL，表示内存耗尽，返回NULL
    
    return (void*)r;
    800018da:	fe843783          	ld	a5,-24(s0)
}
    800018de:	853e                	mv	a0,a5
    800018e0:	60e2                	ld	ra,24(sp)
    800018e2:	6442                	ld	s0,16(sp)
    800018e4:	6105                	add	sp,sp,32
    800018e6:	8082                	ret

00000000800018e8 <free_page>:

// ==================== 释放一个物理页面 ====================  
// 算法特点：将页面插入链表头，实现LIFO释放
// 时间复杂度：O(1) - 仅涉及链表头操作
void free_page(void* pa) {
    800018e8:	7179                	add	sp,sp,-48
    800018ea:	f406                	sd	ra,40(sp)
    800018ec:	f022                	sd	s0,32(sp)
    800018ee:	1800                	add	s0,sp,48
    800018f0:	fca43c23          	sd	a0,-40(s0)
    struct run *r;
    
    // 第一步：地址有效性检查
    // 检查页面对齐：物理地址必须是4KB的整数倍
    if(((uint64)pa % PGSIZE) != 0)
    800018f4:	fd843703          	ld	a4,-40(s0)
    800018f8:	6785                	lui	a5,0x1
    800018fa:	17fd                	add	a5,a5,-1 # fff <_start-0x7ffff001>
    800018fc:	8ff9                	and	a5,a5,a4
    800018fe:	cb89                	beqz	a5,80001910 <free_page+0x28>
        panic("free_page: not page aligned");
    80001900:	00004517          	auipc	a0,0x4
    80001904:	02850513          	add	a0,a0,40 # 80005928 <etext+0x928>
    80001908:	00000097          	auipc	ra,0x0
    8000190c:	c90080e7          	jalr	-880(ra) # 80001598 <panic>
    
    // 检查地址范围：必须在可管理的内存范围内
    // 防止释放内核代码/数据区域或超出物理内存的地址
    if((char*)pa < end || (uint64)pa >= PHYSTOP)
    80001910:	fd843703          	ld	a4,-40(s0)
    80001914:	0000e797          	auipc	a5,0xe
    80001918:	6ec78793          	add	a5,a5,1772 # 80010000 <panicking>
    8000191c:	00f76863          	bltu	a4,a5,8000192c <free_page+0x44>
    80001920:	fd843703          	ld	a4,-40(s0)
    80001924:	47c5                	li	a5,17
    80001926:	07ee                	sll	a5,a5,0x1b
    80001928:	00f76a63          	bltu	a4,a5,8000193c <free_page+0x54>
        panic("free_page: invalid address");
    8000192c:	00004517          	auipc	a0,0x4
    80001930:	01c50513          	add	a0,a0,28 # 80005948 <etext+0x948>
    80001934:	00000097          	auipc	ra,0x0
    80001938:	c64080e7          	jalr	-924(ra) # 80001598 <panic>

     // 检查是否已经释放过.在释放的页面中放置一个特殊的标记，下次释放时检查这个标记。
    uint32 *magic_ptr = (uint32*)pa;
    8000193c:	fd843783          	ld	a5,-40(s0)
    80001940:	fef43423          	sd	a5,-24(s0)
    if(*magic_ptr == FREE_MAGIC) {
    80001944:	fe843783          	ld	a5,-24(s0)
    80001948:	439c                	lw	a5,0(a5)
    8000194a:	873e                	mv	a4,a5
    8000194c:	deadc7b7          	lui	a5,0xdeadc
    80001950:	eef78793          	add	a5,a5,-273 # ffffffffdeadbeef <kernel_pagetable+0xffffffff5eacbee7>
    80001954:	00f71a63          	bne	a4,a5,80001968 <free_page+0x80>
        panic("free_page: double free detected");
    80001958:	00004517          	auipc	a0,0x4
    8000195c:	01050513          	add	a0,a0,16 # 80005968 <etext+0x968>
    80001960:	00000097          	auipc	ra,0x0
    80001964:	c38080e7          	jalr	-968(ra) # 80001598 <panic>
    }
    
    // 填充魔数而不是全部填1
    *magic_ptr = FREE_MAGIC;
    80001968:	fe843783          	ld	a5,-24(s0)
    8000196c:	deadc737          	lui	a4,0xdeadc
    80001970:	eef70713          	add	a4,a4,-273 # ffffffffdeadbeef <kernel_pagetable+0xffffffff5eacbee7>
    80001974:	c398                	sw	a4,0(a5)
    // 第二步：安全擦除页面内容
    // 填充特殊值(1)有助于检测use-after-free错误
    // 如果程序试图使用已释放的页面，会读到异常的数据模式
    // 其余部分仍然填1
    memset((char*)pa + 4, 1, PGSIZE - 4);
    80001976:	fd843783          	ld	a5,-40(s0)
    8000197a:	00478713          	add	a4,a5,4
    8000197e:	6785                	lui	a5,0x1
    80001980:	ffc78613          	add	a2,a5,-4 # ffc <_start-0x7ffff004>
    80001984:	4585                	li	a1,1
    80001986:	853a                	mv	a0,a4
    80001988:	00000097          	auipc	ra,0x0
    8000198c:	d92080e7          	jalr	-622(ra) # 8000171a <memset>
    
    // 第三步：将页面插入空闲链表头部
    r = (struct run*)pa;        // 将页面地址转换为链表节点
    80001990:	fd843783          	ld	a5,-40(s0)
    80001994:	fef43023          	sd	a5,-32(s0)
    r->next = kmem.freelist;    // 新节点指向当前链表头
    80001998:	0000a797          	auipc	a5,0xa
    8000199c:	68878793          	add	a5,a5,1672 # 8000c020 <kmem>
    800019a0:	6398                	ld	a4,0(a5)
    800019a2:	fe043783          	ld	a5,-32(s0)
    800019a6:	e398                	sd	a4,0(a5)
    kmem.freelist = r;          // 更新链表头为新节点
    800019a8:	0000a797          	auipc	a5,0xa
    800019ac:	67878793          	add	a5,a5,1656 # 8000c020 <kmem>
    800019b0:	fe043703          	ld	a4,-32(s0)
    800019b4:	e398                	sd	a4,0(a5)
    kmem.free_pages++;          // 更新空闲页面计数
    800019b6:	0000a797          	auipc	a5,0xa
    800019ba:	66a78793          	add	a5,a5,1642 # 8000c020 <kmem>
    800019be:	6b9c                	ld	a5,16(a5)
    800019c0:	00178713          	add	a4,a5,1
    800019c4:	0000a797          	auipc	a5,0xa
    800019c8:	65c78793          	add	a5,a5,1628 # 8000c020 <kmem>
    800019cc:	eb98                	sd	a4,16(a5)
}
    800019ce:	0001                	nop
    800019d0:	70a2                	ld	ra,40(sp)
    800019d2:	7402                	ld	s0,32(sp)
    800019d4:	6145                	add	sp,sp,48
    800019d6:	8082                	ret

00000000800019d8 <pmm_info>:

// ==================== 内存使用信息统计 ====================
// 用途：调试、监控、性能分析
void pmm_info(void) {
    800019d8:	1141                	add	sp,sp,-16
    800019da:	e406                	sd	ra,8(sp)
    800019dc:	e022                	sd	s0,0(sp)
    800019de:	0800                	add	s0,sp,16
    printf("Memory Info:\n");
    800019e0:	00004517          	auipc	a0,0x4
    800019e4:	fa850513          	add	a0,a0,-88 # 80005988 <etext+0x988>
    800019e8:	00000097          	auipc	ra,0x0
    800019ec:	80a080e7          	jalr	-2038(ra) # 800011f2 <printf>
    printf("  Total pages: %d (%d KB)\n", 
           (int)kmem.total_pages, (int)(kmem.total_pages * PGSIZE) / 1024);
    800019f0:	0000a797          	auipc	a5,0xa
    800019f4:	63078793          	add	a5,a5,1584 # 8000c020 <kmem>
    800019f8:	679c                	ld	a5,8(a5)
    printf("  Total pages: %d (%d KB)\n", 
    800019fa:	0007869b          	sext.w	a3,a5
           (int)kmem.total_pages, (int)(kmem.total_pages * PGSIZE) / 1024);
    800019fe:	0000a797          	auipc	a5,0xa
    80001a02:	62278793          	add	a5,a5,1570 # 8000c020 <kmem>
    80001a06:	679c                	ld	a5,8(a5)
    80001a08:	2781                	sext.w	a5,a5
    80001a0a:	00c7979b          	sllw	a5,a5,0xc
    80001a0e:	2781                	sext.w	a5,a5
    80001a10:	2781                	sext.w	a5,a5
    printf("  Total pages: %d (%d KB)\n", 
    80001a12:	41f7d71b          	sraw	a4,a5,0x1f
    80001a16:	0167571b          	srlw	a4,a4,0x16
    80001a1a:	9fb9                	addw	a5,a5,a4
    80001a1c:	40a7d79b          	sraw	a5,a5,0xa
    80001a20:	2781                	sext.w	a5,a5
    80001a22:	863e                	mv	a2,a5
    80001a24:	85b6                	mv	a1,a3
    80001a26:	00004517          	auipc	a0,0x4
    80001a2a:	f7250513          	add	a0,a0,-142 # 80005998 <etext+0x998>
    80001a2e:	fffff097          	auipc	ra,0xfffff
    80001a32:	7c4080e7          	jalr	1988(ra) # 800011f2 <printf>
    printf("  Free pages:  %d (%d KB)\n", 
           (int)kmem.free_pages, (int)(kmem.free_pages * PGSIZE) / 1024);
    80001a36:	0000a797          	auipc	a5,0xa
    80001a3a:	5ea78793          	add	a5,a5,1514 # 8000c020 <kmem>
    80001a3e:	6b9c                	ld	a5,16(a5)
    printf("  Free pages:  %d (%d KB)\n", 
    80001a40:	0007869b          	sext.w	a3,a5
           (int)kmem.free_pages, (int)(kmem.free_pages * PGSIZE) / 1024);
    80001a44:	0000a797          	auipc	a5,0xa
    80001a48:	5dc78793          	add	a5,a5,1500 # 8000c020 <kmem>
    80001a4c:	6b9c                	ld	a5,16(a5)
    80001a4e:	2781                	sext.w	a5,a5
    80001a50:	00c7979b          	sllw	a5,a5,0xc
    80001a54:	2781                	sext.w	a5,a5
    80001a56:	2781                	sext.w	a5,a5
    printf("  Free pages:  %d (%d KB)\n", 
    80001a58:	41f7d71b          	sraw	a4,a5,0x1f
    80001a5c:	0167571b          	srlw	a4,a4,0x16
    80001a60:	9fb9                	addw	a5,a5,a4
    80001a62:	40a7d79b          	sraw	a5,a5,0xa
    80001a66:	2781                	sext.w	a5,a5
    80001a68:	863e                	mv	a2,a5
    80001a6a:	85b6                	mv	a1,a3
    80001a6c:	00004517          	auipc	a0,0x4
    80001a70:	f4c50513          	add	a0,a0,-180 # 800059b8 <etext+0x9b8>
    80001a74:	fffff097          	auipc	ra,0xfffff
    80001a78:	77e080e7          	jalr	1918(ra) # 800011f2 <printf>
    printf("  Used pages:  %d (%d KB)\n", 
           (int)(kmem.total_pages - kmem.free_pages), 
    80001a7c:	0000a797          	auipc	a5,0xa
    80001a80:	5a478793          	add	a5,a5,1444 # 8000c020 <kmem>
    80001a84:	679c                	ld	a5,8(a5)
    80001a86:	0007871b          	sext.w	a4,a5
    80001a8a:	0000a797          	auipc	a5,0xa
    80001a8e:	59678793          	add	a5,a5,1430 # 8000c020 <kmem>
    80001a92:	6b9c                	ld	a5,16(a5)
    80001a94:	2781                	sext.w	a5,a5
    80001a96:	40f707bb          	subw	a5,a4,a5
    80001a9a:	2781                	sext.w	a5,a5
    printf("  Used pages:  %d (%d KB)\n", 
    80001a9c:	0007869b          	sext.w	a3,a5
           (int)((kmem.total_pages - kmem.free_pages) * PGSIZE) / 1024);
    80001aa0:	0000a797          	auipc	a5,0xa
    80001aa4:	58078793          	add	a5,a5,1408 # 8000c020 <kmem>
    80001aa8:	6798                	ld	a4,8(a5)
    80001aaa:	0000a797          	auipc	a5,0xa
    80001aae:	57678793          	add	a5,a5,1398 # 8000c020 <kmem>
    80001ab2:	6b9c                	ld	a5,16(a5)
    80001ab4:	40f707b3          	sub	a5,a4,a5
    80001ab8:	2781                	sext.w	a5,a5
    80001aba:	00c7979b          	sllw	a5,a5,0xc
    80001abe:	2781                	sext.w	a5,a5
    80001ac0:	2781                	sext.w	a5,a5
    printf("  Used pages:  %d (%d KB)\n", 
    80001ac2:	41f7d71b          	sraw	a4,a5,0x1f
    80001ac6:	0167571b          	srlw	a4,a4,0x16
    80001aca:	9fb9                	addw	a5,a5,a4
    80001acc:	40a7d79b          	sraw	a5,a5,0xa
    80001ad0:	2781                	sext.w	a5,a5
    80001ad2:	863e                	mv	a2,a5
    80001ad4:	85b6                	mv	a1,a3
    80001ad6:	00004517          	auipc	a0,0x4
    80001ada:	f0250513          	add	a0,a0,-254 # 800059d8 <etext+0x9d8>
    80001ade:	fffff097          	auipc	ra,0xfffff
    80001ae2:	714080e7          	jalr	1812(ra) # 800011f2 <printf>
}
    80001ae6:	0001                	nop
    80001ae8:	60a2                	ld	ra,8(sp)
    80001aea:	6402                	ld	s0,0(sp)
    80001aec:	0141                	add	sp,sp,16
    80001aee:	8082                	ret

0000000080001af0 <w_satp>:
pagetable_t create_pagetable(void) {
    pagetable_t pagetable = (pagetable_t)alloc_page();
    if(pagetable == 0)
        return 0;
    return pagetable;
}
    80001af0:	1101                	add	sp,sp,-32
    80001af2:	ec22                	sd	s0,24(sp)
    80001af4:	1000                	add	s0,sp,32
    80001af6:	fea43423          	sd	a0,-24(s0)

    80001afa:	fe843783          	ld	a5,-24(s0)
    80001afe:	18079073          	csrw	satp,a5
// 递归释放页表
    80001b02:	0001                	nop
    80001b04:	6462                	ld	s0,24(sp)
    80001b06:	6105                	add	sp,sp,32
    80001b08:	8082                	ret

0000000080001b0a <sfence_vma>:
static void freewalk(pagetable_t pagetable) {
    for(int i = 0; i < 512; i++) {
        pte_t pte = pagetable[i];
    80001b0a:	1141                	add	sp,sp,-16
    80001b0c:	e422                	sd	s0,8(sp)
    80001b0e:	0800                	add	s0,sp,16
        if(pte & PTE_V) {
    80001b10:	12000073          	sfence.vma
            if((pte & (PTE_R|PTE_W|PTE_X)) == 0) {
    80001b14:	0001                	nop
    80001b16:	6422                	ld	s0,8(sp)
    80001b18:	0141                	add	sp,sp,16
    80001b1a:	8082                	ret

0000000080001b1c <create_pagetable>:
pagetable_t create_pagetable(void) {
    80001b1c:	1101                	add	sp,sp,-32
    80001b1e:	ec06                	sd	ra,24(sp)
    80001b20:	e822                	sd	s0,16(sp)
    80001b22:	1000                	add	s0,sp,32
    pagetable_t pagetable = (pagetable_t)alloc_page();
    80001b24:	00000097          	auipc	ra,0x0
    80001b28:	d62080e7          	jalr	-670(ra) # 80001886 <alloc_page>
    80001b2c:	fea43423          	sd	a0,-24(s0)
    if(pagetable == 0)
    80001b30:	fe843783          	ld	a5,-24(s0)
    80001b34:	e399                	bnez	a5,80001b3a <create_pagetable+0x1e>
        return 0;
    80001b36:	4781                	li	a5,0
    80001b38:	a019                	j	80001b3e <create_pagetable+0x22>
    return pagetable;
    80001b3a:	fe843783          	ld	a5,-24(s0)
}
    80001b3e:	853e                	mv	a0,a5
    80001b40:	60e2                	ld	ra,24(sp)
    80001b42:	6442                	ld	s0,16(sp)
    80001b44:	6105                	add	sp,sp,32
    80001b46:	8082                	ret

0000000080001b48 <freewalk>:
static void freewalk(pagetable_t pagetable) {
    80001b48:	7139                	add	sp,sp,-64
    80001b4a:	fc06                	sd	ra,56(sp)
    80001b4c:	f822                	sd	s0,48(sp)
    80001b4e:	0080                	add	s0,sp,64
    80001b50:	fca43423          	sd	a0,-56(s0)
    for(int i = 0; i < 512; i++) {
    80001b54:	fe042623          	sw	zero,-20(s0)
    80001b58:	a8a1                	j	80001bb0 <freewalk+0x68>
        pte_t pte = pagetable[i];
    80001b5a:	fec42783          	lw	a5,-20(s0)
    80001b5e:	078e                	sll	a5,a5,0x3
    80001b60:	fc843703          	ld	a4,-56(s0)
    80001b64:	97ba                	add	a5,a5,a4
    80001b66:	639c                	ld	a5,0(a5)
    80001b68:	fef43023          	sd	a5,-32(s0)
        if(pte & PTE_V) {
    80001b6c:	fe043783          	ld	a5,-32(s0)
    80001b70:	8b85                	and	a5,a5,1
    80001b72:	cb95                	beqz	a5,80001ba6 <freewalk+0x5e>
            if((pte & (PTE_R|PTE_W|PTE_X)) == 0) {
    80001b74:	fe043783          	ld	a5,-32(s0)
    80001b78:	8bb9                	and	a5,a5,14
    80001b7a:	e795                	bnez	a5,80001ba6 <freewalk+0x5e>
                uint64 child = PTE_PA(pte);
    80001b7c:	fe043783          	ld	a5,-32(s0)
    80001b80:	83a9                	srl	a5,a5,0xa
    80001b82:	07b2                	sll	a5,a5,0xc
    80001b84:	fcf43c23          	sd	a5,-40(s0)
                freewalk((pagetable_t)child);
    80001b88:	fd843783          	ld	a5,-40(s0)
    80001b8c:	853e                	mv	a0,a5
    80001b8e:	00000097          	auipc	ra,0x0
    80001b92:	fba080e7          	jalr	-70(ra) # 80001b48 <freewalk>
                pagetable[i] = 0;
    80001b96:	fec42783          	lw	a5,-20(s0)
    80001b9a:	078e                	sll	a5,a5,0x3
    80001b9c:	fc843703          	ld	a4,-56(s0)
    80001ba0:	97ba                	add	a5,a5,a4
    80001ba2:	0007b023          	sd	zero,0(a5)
    for(int i = 0; i < 512; i++) {
    80001ba6:	fec42783          	lw	a5,-20(s0)
    80001baa:	2785                	addw	a5,a5,1
    80001bac:	fef42623          	sw	a5,-20(s0)
    80001bb0:	fec42783          	lw	a5,-20(s0)
    80001bb4:	0007871b          	sext.w	a4,a5
    80001bb8:	1ff00793          	li	a5,511
    80001bbc:	f8e7dfe3          	bge	a5,a4,80001b5a <freewalk+0x12>
            }
        }
    }
    free_page((void*)pagetable);
    80001bc0:	fc843503          	ld	a0,-56(s0)
    80001bc4:	00000097          	auipc	ra,0x0
    80001bc8:	d24080e7          	jalr	-732(ra) # 800018e8 <free_page>
}
    80001bcc:	0001                	nop
    80001bce:	70e2                	ld	ra,56(sp)
    80001bd0:	7442                	ld	s0,48(sp)
    80001bd2:	6121                	add	sp,sp,64
    80001bd4:	8082                	ret

0000000080001bd6 <destroy_pagetable>:

// 销毁页表
void destroy_pagetable(pagetable_t pagetable) {
    80001bd6:	1101                	add	sp,sp,-32
    80001bd8:	ec06                	sd	ra,24(sp)
    80001bda:	e822                	sd	s0,16(sp)
    80001bdc:	1000                	add	s0,sp,32
    80001bde:	fea43423          	sd	a0,-24(s0)
    if(pagetable == 0)
    80001be2:	fe843783          	ld	a5,-24(s0)
    80001be6:	cb81                	beqz	a5,80001bf6 <destroy_pagetable+0x20>
        return;
    freewalk(pagetable);
    80001be8:	fe843503          	ld	a0,-24(s0)
    80001bec:	00000097          	auipc	ra,0x0
    80001bf0:	f5c080e7          	jalr	-164(ra) # 80001b48 <freewalk>
    80001bf4:	a011                	j	80001bf8 <destroy_pagetable+0x22>
        return;
    80001bf6:	0001                	nop
}
    80001bf8:	60e2                	ld	ra,24(sp)
    80001bfa:	6442                	ld	s0,16(sp)
    80001bfc:	6105                	add	sp,sp,32
    80001bfe:	8082                	ret

0000000080001c00 <walk_lookup>:

// 页表遍历 - 查找模式
pte_t* walk_lookup(pagetable_t pagetable, uint64 va) {
    80001c00:	7179                	add	sp,sp,-48
    80001c02:	f406                	sd	ra,40(sp)
    80001c04:	f022                	sd	s0,32(sp)
    80001c06:	1800                	add	s0,sp,48
    80001c08:	fca43c23          	sd	a0,-40(s0)
    80001c0c:	fcb43823          	sd	a1,-48(s0)
    if(va >= (1L << 39))
    80001c10:	fd043703          	ld	a4,-48(s0)
    80001c14:	57fd                	li	a5,-1
    80001c16:	83e5                	srl	a5,a5,0x19
    80001c18:	00e7fa63          	bgeu	a5,a4,80001c2c <walk_lookup+0x2c>
        panic("walk_lookup: va too large");
    80001c1c:	00004517          	auipc	a0,0x4
    80001c20:	ddc50513          	add	a0,a0,-548 # 800059f8 <etext+0x9f8>
    80001c24:	00000097          	auipc	ra,0x0
    80001c28:	974080e7          	jalr	-1676(ra) # 80001598 <panic>
    
    for(int level = 2; level > 0; level--) {
    80001c2c:	4789                	li	a5,2
    80001c2e:	fef42623          	sw	a5,-20(s0)
    80001c32:	a8a1                	j	80001c8a <walk_lookup+0x8a>
        pte_t *pte = &pagetable[PX(level, va)];
    80001c34:	fec42783          	lw	a5,-20(s0)
    80001c38:	873e                	mv	a4,a5
    80001c3a:	87ba                	mv	a5,a4
    80001c3c:	0037979b          	sllw	a5,a5,0x3
    80001c40:	9fb9                	addw	a5,a5,a4
    80001c42:	2781                	sext.w	a5,a5
    80001c44:	27b1                	addw	a5,a5,12
    80001c46:	2781                	sext.w	a5,a5
    80001c48:	873e                	mv	a4,a5
    80001c4a:	fd043783          	ld	a5,-48(s0)
    80001c4e:	00e7d7b3          	srl	a5,a5,a4
    80001c52:	1ff7f793          	and	a5,a5,511
    80001c56:	078e                	sll	a5,a5,0x3
    80001c58:	fd843703          	ld	a4,-40(s0)
    80001c5c:	97ba                	add	a5,a5,a4
    80001c5e:	fef43023          	sd	a5,-32(s0)
        if(*pte & PTE_V) {
    80001c62:	fe043783          	ld	a5,-32(s0)
    80001c66:	639c                	ld	a5,0(a5)
    80001c68:	8b85                	and	a5,a5,1
    80001c6a:	cb89                	beqz	a5,80001c7c <walk_lookup+0x7c>
            pagetable = (pagetable_t)PTE_PA(*pte);
    80001c6c:	fe043783          	ld	a5,-32(s0)
    80001c70:	639c                	ld	a5,0(a5)
    80001c72:	83a9                	srl	a5,a5,0xa
    80001c74:	07b2                	sll	a5,a5,0xc
    80001c76:	fcf43c23          	sd	a5,-40(s0)
    80001c7a:	a019                	j	80001c80 <walk_lookup+0x80>
        } else {
            return 0;
    80001c7c:	4781                	li	a5,0
    80001c7e:	a025                	j	80001ca6 <walk_lookup+0xa6>
    for(int level = 2; level > 0; level--) {
    80001c80:	fec42783          	lw	a5,-20(s0)
    80001c84:	37fd                	addw	a5,a5,-1
    80001c86:	fef42623          	sw	a5,-20(s0)
    80001c8a:	fec42783          	lw	a5,-20(s0)
    80001c8e:	2781                	sext.w	a5,a5
    80001c90:	faf042e3          	bgtz	a5,80001c34 <walk_lookup+0x34>
        }
    }
    return &pagetable[PX(0, va)];
    80001c94:	fd043783          	ld	a5,-48(s0)
    80001c98:	83b1                	srl	a5,a5,0xc
    80001c9a:	1ff7f793          	and	a5,a5,511
    80001c9e:	078e                	sll	a5,a5,0x3
    80001ca0:	fd843703          	ld	a4,-40(s0)
    80001ca4:	97ba                	add	a5,a5,a4
}
    80001ca6:	853e                	mv	a0,a5
    80001ca8:	70a2                	ld	ra,40(sp)
    80001caa:	7402                	ld	s0,32(sp)
    80001cac:	6145                	add	sp,sp,48
    80001cae:	8082                	ret

0000000080001cb0 <walk_create>:

// 页表遍历 - 创建模式
pte_t* walk_create(pagetable_t pagetable, uint64 va) {
    80001cb0:	7179                	add	sp,sp,-48
    80001cb2:	f406                	sd	ra,40(sp)
    80001cb4:	f022                	sd	s0,32(sp)
    80001cb6:	1800                	add	s0,sp,48
    80001cb8:	fca43c23          	sd	a0,-40(s0)
    80001cbc:	fcb43823          	sd	a1,-48(s0)
    if(va >= (1L << 39))
    80001cc0:	fd043703          	ld	a4,-48(s0)
    80001cc4:	57fd                	li	a5,-1
    80001cc6:	83e5                	srl	a5,a5,0x19
    80001cc8:	00e7fa63          	bgeu	a5,a4,80001cdc <walk_create+0x2c>
        panic("walk_create: va too large");
    80001ccc:	00004517          	auipc	a0,0x4
    80001cd0:	d4c50513          	add	a0,a0,-692 # 80005a18 <etext+0xa18>
    80001cd4:	00000097          	auipc	ra,0x0
    80001cd8:	8c4080e7          	jalr	-1852(ra) # 80001598 <panic>
    
    for(int level = 2; level > 0; level--) {
    80001cdc:	4789                	li	a5,2
    80001cde:	fef42623          	sw	a5,-20(s0)
    80001ce2:	a8b5                	j	80001d5e <walk_create+0xae>
        pte_t *pte = &pagetable[PX(level, va)];
    80001ce4:	fec42783          	lw	a5,-20(s0)
    80001ce8:	873e                	mv	a4,a5
    80001cea:	87ba                	mv	a5,a4
    80001cec:	0037979b          	sllw	a5,a5,0x3
    80001cf0:	9fb9                	addw	a5,a5,a4
    80001cf2:	2781                	sext.w	a5,a5
    80001cf4:	27b1                	addw	a5,a5,12
    80001cf6:	2781                	sext.w	a5,a5
    80001cf8:	873e                	mv	a4,a5
    80001cfa:	fd043783          	ld	a5,-48(s0)
    80001cfe:	00e7d7b3          	srl	a5,a5,a4
    80001d02:	1ff7f793          	and	a5,a5,511
    80001d06:	078e                	sll	a5,a5,0x3
    80001d08:	fd843703          	ld	a4,-40(s0)
    80001d0c:	97ba                	add	a5,a5,a4
    80001d0e:	fef43023          	sd	a5,-32(s0)
        if(*pte & PTE_V) {
    80001d12:	fe043783          	ld	a5,-32(s0)
    80001d16:	639c                	ld	a5,0(a5)
    80001d18:	8b85                	and	a5,a5,1
    80001d1a:	cb89                	beqz	a5,80001d2c <walk_create+0x7c>
            pagetable = (pagetable_t)PTE_PA(*pte);
    80001d1c:	fe043783          	ld	a5,-32(s0)
    80001d20:	639c                	ld	a5,0(a5)
    80001d22:	83a9                	srl	a5,a5,0xa
    80001d24:	07b2                	sll	a5,a5,0xc
    80001d26:	fcf43c23          	sd	a5,-40(s0)
    80001d2a:	a02d                	j	80001d54 <walk_create+0xa4>
        } else {
            pagetable = (pagetable_t)alloc_page();
    80001d2c:	00000097          	auipc	ra,0x0
    80001d30:	b5a080e7          	jalr	-1190(ra) # 80001886 <alloc_page>
    80001d34:	fca43c23          	sd	a0,-40(s0)
            if(pagetable == 0)
    80001d38:	fd843783          	ld	a5,-40(s0)
    80001d3c:	e399                	bnez	a5,80001d42 <walk_create+0x92>
                return 0;
    80001d3e:	4781                	li	a5,0
    80001d40:	a82d                	j	80001d7a <walk_create+0xca>
            *pte = PA2PTE(pagetable) | PTE_V;
    80001d42:	fd843783          	ld	a5,-40(s0)
    80001d46:	83b1                	srl	a5,a5,0xc
    80001d48:	07aa                	sll	a5,a5,0xa
    80001d4a:	0017e713          	or	a4,a5,1
    80001d4e:	fe043783          	ld	a5,-32(s0)
    80001d52:	e398                	sd	a4,0(a5)
    for(int level = 2; level > 0; level--) {
    80001d54:	fec42783          	lw	a5,-20(s0)
    80001d58:	37fd                	addw	a5,a5,-1
    80001d5a:	fef42623          	sw	a5,-20(s0)
    80001d5e:	fec42783          	lw	a5,-20(s0)
    80001d62:	2781                	sext.w	a5,a5
    80001d64:	f8f040e3          	bgtz	a5,80001ce4 <walk_create+0x34>
        }
    }
    return &pagetable[PX(0, va)];
    80001d68:	fd043783          	ld	a5,-48(s0)
    80001d6c:	83b1                	srl	a5,a5,0xc
    80001d6e:	1ff7f793          	and	a5,a5,511
    80001d72:	078e                	sll	a5,a5,0x3
    80001d74:	fd843703          	ld	a4,-40(s0)
    80001d78:	97ba                	add	a5,a5,a4
}
    80001d7a:	853e                	mv	a0,a5
    80001d7c:	70a2                	ld	ra,40(sp)
    80001d7e:	7402                	ld	s0,32(sp)
    80001d80:	6145                	add	sp,sp,48
    80001d82:	8082                	ret

0000000080001d84 <map_page>:

// 映射单个页面
int map_page(pagetable_t pagetable, uint64 va, uint64 pa, int perm) {
    80001d84:	7139                	add	sp,sp,-64
    80001d86:	fc06                	sd	ra,56(sp)
    80001d88:	f822                	sd	s0,48(sp)
    80001d8a:	0080                	add	s0,sp,64
    80001d8c:	fca43c23          	sd	a0,-40(s0)
    80001d90:	fcb43823          	sd	a1,-48(s0)
    80001d94:	fcc43423          	sd	a2,-56(s0)
    80001d98:	87b6                	mv	a5,a3
    80001d9a:	fcf42223          	sw	a5,-60(s0)
    if(va % PGSIZE != 0)
    80001d9e:	fd043703          	ld	a4,-48(s0)
    80001da2:	6785                	lui	a5,0x1
    80001da4:	17fd                	add	a5,a5,-1 # fff <_start-0x7ffff001>
    80001da6:	8ff9                	and	a5,a5,a4
    80001da8:	cb89                	beqz	a5,80001dba <map_page+0x36>
        panic("map_page: va not page aligned");
    80001daa:	00004517          	auipc	a0,0x4
    80001dae:	c8e50513          	add	a0,a0,-882 # 80005a38 <etext+0xa38>
    80001db2:	fffff097          	auipc	ra,0xfffff
    80001db6:	7e6080e7          	jalr	2022(ra) # 80001598 <panic>
    if(pa % PGSIZE != 0)
    80001dba:	fc843703          	ld	a4,-56(s0)
    80001dbe:	6785                	lui	a5,0x1
    80001dc0:	17fd                	add	a5,a5,-1 # fff <_start-0x7ffff001>
    80001dc2:	8ff9                	and	a5,a5,a4
    80001dc4:	cb89                	beqz	a5,80001dd6 <map_page+0x52>
        panic("map_page: pa not page aligned");
    80001dc6:	00004517          	auipc	a0,0x4
    80001dca:	c9250513          	add	a0,a0,-878 # 80005a58 <etext+0xa58>
    80001dce:	fffff097          	auipc	ra,0xfffff
    80001dd2:	7ca080e7          	jalr	1994(ra) # 80001598 <panic>
    
    pte_t *pte = walk_create(pagetable, va);
    80001dd6:	fd043583          	ld	a1,-48(s0)
    80001dda:	fd843503          	ld	a0,-40(s0)
    80001dde:	00000097          	auipc	ra,0x0
    80001de2:	ed2080e7          	jalr	-302(ra) # 80001cb0 <walk_create>
    80001de6:	fea43423          	sd	a0,-24(s0)
    if(pte == 0)
    80001dea:	fe843783          	ld	a5,-24(s0)
    80001dee:	e399                	bnez	a5,80001df4 <map_page+0x70>
        return -1;
    80001df0:	57fd                	li	a5,-1
    80001df2:	a825                	j	80001e2a <map_page+0xa6>
    
    if(*pte & PTE_V)
    80001df4:	fe843783          	ld	a5,-24(s0)
    80001df8:	639c                	ld	a5,0(a5)
    80001dfa:	8b85                	and	a5,a5,1
    80001dfc:	cb89                	beqz	a5,80001e0e <map_page+0x8a>
        panic("map_page: page already mapped");
    80001dfe:	00004517          	auipc	a0,0x4
    80001e02:	c7a50513          	add	a0,a0,-902 # 80005a78 <etext+0xa78>
    80001e06:	fffff097          	auipc	ra,0xfffff
    80001e0a:	792080e7          	jalr	1938(ra) # 80001598 <panic>
    
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001e0e:	fc843783          	ld	a5,-56(s0)
    80001e12:	83b1                	srl	a5,a5,0xc
    80001e14:	00a79713          	sll	a4,a5,0xa
    80001e18:	fc442783          	lw	a5,-60(s0)
    80001e1c:	8fd9                	or	a5,a5,a4
    80001e1e:	0017e713          	or	a4,a5,1
    80001e22:	fe843783          	ld	a5,-24(s0)
    80001e26:	e398                	sd	a4,0(a5)
    return 0;
    80001e28:	4781                	li	a5,0
}
    80001e2a:	853e                	mv	a0,a5
    80001e2c:	70e2                	ld	ra,56(sp)
    80001e2e:	7442                	ld	s0,48(sp)
    80001e30:	6121                	add	sp,sp,64
    80001e32:	8082                	ret

0000000080001e34 <map_region>:

// 映射内存区域
int map_region(pagetable_t pagetable, uint64 va, uint64 pa, uint64 size, int perm) {
    80001e34:	715d                	add	sp,sp,-80
    80001e36:	e486                	sd	ra,72(sp)
    80001e38:	e0a2                	sd	s0,64(sp)
    80001e3a:	0880                	add	s0,sp,80
    80001e3c:	fca43c23          	sd	a0,-40(s0)
    80001e40:	fcb43823          	sd	a1,-48(s0)
    80001e44:	fcc43423          	sd	a2,-56(s0)
    80001e48:	fcd43023          	sd	a3,-64(s0)
    80001e4c:	87ba                	mv	a5,a4
    80001e4e:	faf42e23          	sw	a5,-68(s0)
    uint64 a, last;
    
    if(size == 0)
    80001e52:	fc043783          	ld	a5,-64(s0)
    80001e56:	e399                	bnez	a5,80001e5c <map_region+0x28>
        return 0;
    80001e58:	4781                	li	a5,0
    80001e5a:	a885                	j	80001eca <map_region+0x96>
    
    a = PGROUNDDOWN(va);
    80001e5c:	fd043703          	ld	a4,-48(s0)
    80001e60:	77fd                	lui	a5,0xfffff
    80001e62:	8ff9                	and	a5,a5,a4
    80001e64:	fef43423          	sd	a5,-24(s0)
    last = PGROUNDDOWN(va + size - 1);
    80001e68:	fd043703          	ld	a4,-48(s0)
    80001e6c:	fc043783          	ld	a5,-64(s0)
    80001e70:	97ba                	add	a5,a5,a4
    80001e72:	fff78713          	add	a4,a5,-1 # ffffffffffffefff <kernel_pagetable+0xffffffff7ffeeff7>
    80001e76:	77fd                	lui	a5,0xfffff
    80001e78:	8ff9                	and	a5,a5,a4
    80001e7a:	fef43023          	sd	a5,-32(s0)
    
    for(;;) {
        if(map_page(pagetable, a, pa, perm) != 0)
    80001e7e:	fbc42783          	lw	a5,-68(s0)
    80001e82:	86be                	mv	a3,a5
    80001e84:	fc843603          	ld	a2,-56(s0)
    80001e88:	fe843583          	ld	a1,-24(s0)
    80001e8c:	fd843503          	ld	a0,-40(s0)
    80001e90:	00000097          	auipc	ra,0x0
    80001e94:	ef4080e7          	jalr	-268(ra) # 80001d84 <map_page>
    80001e98:	87aa                	mv	a5,a0
    80001e9a:	c399                	beqz	a5,80001ea0 <map_region+0x6c>
            return -1;
    80001e9c:	57fd                	li	a5,-1
    80001e9e:	a035                	j	80001eca <map_region+0x96>
        if(a == last)
    80001ea0:	fe843703          	ld	a4,-24(s0)
    80001ea4:	fe043783          	ld	a5,-32(s0)
    80001ea8:	00f70f63          	beq	a4,a5,80001ec6 <map_region+0x92>
            break;
        a += PGSIZE;
    80001eac:	fe843703          	ld	a4,-24(s0)
    80001eb0:	6785                	lui	a5,0x1
    80001eb2:	97ba                	add	a5,a5,a4
    80001eb4:	fef43423          	sd	a5,-24(s0)
        pa += PGSIZE;
    80001eb8:	fc843703          	ld	a4,-56(s0)
    80001ebc:	6785                	lui	a5,0x1
    80001ebe:	97ba                	add	a5,a5,a4
    80001ec0:	fcf43423          	sd	a5,-56(s0)
        if(map_page(pagetable, a, pa, perm) != 0)
    80001ec4:	bf6d                	j	80001e7e <map_region+0x4a>
            break;
    80001ec6:	0001                	nop
    }
    return 0;
    80001ec8:	4781                	li	a5,0
}
    80001eca:	853e                	mv	a0,a5
    80001ecc:	60a6                	ld	ra,72(sp)
    80001ece:	6406                	ld	s0,64(sp)
    80001ed0:	6161                	add	sp,sp,80
    80001ed2:	8082                	ret

0000000080001ed4 <kvminit>:

// 初始化内核页表
void kvminit(void) {
    80001ed4:	1141                	add	sp,sp,-16
    80001ed6:	e406                	sd	ra,8(sp)
    80001ed8:	e022                	sd	s0,0(sp)
    80001eda:	0800                	add	s0,sp,16
    kernel_pagetable = create_pagetable();
    80001edc:	00000097          	auipc	ra,0x0
    80001ee0:	c40080e7          	jalr	-960(ra) # 80001b1c <create_pagetable>
    80001ee4:	872a                	mv	a4,a0
    80001ee6:	0000e797          	auipc	a5,0xe
    80001eea:	12278793          	add	a5,a5,290 # 80010008 <kernel_pagetable>
    80001eee:	e398                	sd	a4,0(a5)
    if(kernel_pagetable == 0)
    80001ef0:	0000e797          	auipc	a5,0xe
    80001ef4:	11878793          	add	a5,a5,280 # 80010008 <kernel_pagetable>
    80001ef8:	639c                	ld	a5,0(a5)
    80001efa:	eb89                	bnez	a5,80001f0c <kvminit+0x38>
        panic("kvminit: create_pagetable failed");
    80001efc:	00004517          	auipc	a0,0x4
    80001f00:	b9c50513          	add	a0,a0,-1124 # 80005a98 <etext+0xa98>
    80001f04:	fffff097          	auipc	ra,0xfffff
    80001f08:	694080e7          	jalr	1684(ra) # 80001598 <panic>
    
    printf("Setting up kernel page table...\n");
    80001f0c:	00004517          	auipc	a0,0x4
    80001f10:	bb450513          	add	a0,a0,-1100 # 80005ac0 <etext+0xac0>
    80001f14:	fffff097          	auipc	ra,0xfffff
    80001f18:	2de080e7          	jalr	734(ra) # 800011f2 <printf>
    
    // 映射内核代码段
    printf("Mapping kernel text: %p - %p\n", (void*)KERNBASE, etext);
    80001f1c:	00003617          	auipc	a2,0x3
    80001f20:	0e460613          	add	a2,a2,228 # 80005000 <etext>
    80001f24:	4785                	li	a5,1
    80001f26:	01f79593          	sll	a1,a5,0x1f
    80001f2a:	00004517          	auipc	a0,0x4
    80001f2e:	bbe50513          	add	a0,a0,-1090 # 80005ae8 <etext+0xae8>
    80001f32:	fffff097          	auipc	ra,0xfffff
    80001f36:	2c0080e7          	jalr	704(ra) # 800011f2 <printf>
    if(map_region(kernel_pagetable, KERNBASE, KERNBASE, 
    80001f3a:	0000e797          	auipc	a5,0xe
    80001f3e:	0ce78793          	add	a5,a5,206 # 80010008 <kernel_pagetable>
    80001f42:	6388                	ld	a0,0(a5)
                  (uint64)etext - KERNBASE, PTE_R | PTE_X) != 0)
    80001f44:	00003717          	auipc	a4,0x3
    80001f48:	0bc70713          	add	a4,a4,188 # 80005000 <etext>
    if(map_region(kernel_pagetable, KERNBASE, KERNBASE, 
    80001f4c:	800007b7          	lui	a5,0x80000
    80001f50:	97ba                	add	a5,a5,a4
    80001f52:	4729                	li	a4,10
    80001f54:	86be                	mv	a3,a5
    80001f56:	4785                	li	a5,1
    80001f58:	01f79613          	sll	a2,a5,0x1f
    80001f5c:	4785                	li	a5,1
    80001f5e:	01f79593          	sll	a1,a5,0x1f
    80001f62:	00000097          	auipc	ra,0x0
    80001f66:	ed2080e7          	jalr	-302(ra) # 80001e34 <map_region>
    80001f6a:	87aa                	mv	a5,a0
    80001f6c:	cb89                	beqz	a5,80001f7e <kvminit+0xaa>
        panic("kvminit: map kernel text failed");
    80001f6e:	00004517          	auipc	a0,0x4
    80001f72:	b9a50513          	add	a0,a0,-1126 # 80005b08 <etext+0xb08>
    80001f76:	fffff097          	auipc	ra,0xfffff
    80001f7a:	622080e7          	jalr	1570(ra) # 80001598 <panic>
    
    // 映射内核数据段
    printf("Mapping kernel data: %p - %p\n", etext, (void*)PHYSTOP);
    80001f7e:	47c5                	li	a5,17
    80001f80:	01b79613          	sll	a2,a5,0x1b
    80001f84:	00003597          	auipc	a1,0x3
    80001f88:	07c58593          	add	a1,a1,124 # 80005000 <etext>
    80001f8c:	00004517          	auipc	a0,0x4
    80001f90:	b9c50513          	add	a0,a0,-1124 # 80005b28 <etext+0xb28>
    80001f94:	fffff097          	auipc	ra,0xfffff
    80001f98:	25e080e7          	jalr	606(ra) # 800011f2 <printf>
    if(map_region(kernel_pagetable, (uint64)etext, (uint64)etext,
    80001f9c:	0000e797          	auipc	a5,0xe
    80001fa0:	06c78793          	add	a5,a5,108 # 80010008 <kernel_pagetable>
    80001fa4:	6388                	ld	a0,0(a5)
    80001fa6:	00003597          	auipc	a1,0x3
    80001faa:	05a58593          	add	a1,a1,90 # 80005000 <etext>
    80001fae:	00003617          	auipc	a2,0x3
    80001fb2:	05260613          	add	a2,a2,82 # 80005000 <etext>
                  PHYSTOP - (uint64)etext, PTE_R | PTE_W) != 0)
    80001fb6:	00003797          	auipc	a5,0x3
    80001fba:	04a78793          	add	a5,a5,74 # 80005000 <etext>
    if(map_region(kernel_pagetable, (uint64)etext, (uint64)etext,
    80001fbe:	4745                	li	a4,17
    80001fc0:	076e                	sll	a4,a4,0x1b
    80001fc2:	40f707b3          	sub	a5,a4,a5
    80001fc6:	4719                	li	a4,6
    80001fc8:	86be                	mv	a3,a5
    80001fca:	00000097          	auipc	ra,0x0
    80001fce:	e6a080e7          	jalr	-406(ra) # 80001e34 <map_region>
    80001fd2:	87aa                	mv	a5,a0
    80001fd4:	cb89                	beqz	a5,80001fe6 <kvminit+0x112>
        panic("kvminit: map kernel data failed");
    80001fd6:	00004517          	auipc	a0,0x4
    80001fda:	b7250513          	add	a0,a0,-1166 # 80005b48 <etext+0xb48>
    80001fde:	fffff097          	auipc	ra,0xfffff
    80001fe2:	5ba080e7          	jalr	1466(ra) # 80001598 <panic>
    
    // 映射UART设备
    printf("Mapping UART: %p\n", (void*)UART0);
    80001fe6:	100005b7          	lui	a1,0x10000
    80001fea:	00004517          	auipc	a0,0x4
    80001fee:	b7e50513          	add	a0,a0,-1154 # 80005b68 <etext+0xb68>
    80001ff2:	fffff097          	auipc	ra,0xfffff
    80001ff6:	200080e7          	jalr	512(ra) # 800011f2 <printf>
    if(map_region(kernel_pagetable, UART0, UART0, PGSIZE, PTE_R | PTE_W) != 0)
    80001ffa:	0000e797          	auipc	a5,0xe
    80001ffe:	00e78793          	add	a5,a5,14 # 80010008 <kernel_pagetable>
    80002002:	639c                	ld	a5,0(a5)
    80002004:	4719                	li	a4,6
    80002006:	6685                	lui	a3,0x1
    80002008:	10000637          	lui	a2,0x10000
    8000200c:	100005b7          	lui	a1,0x10000
    80002010:	853e                	mv	a0,a5
    80002012:	00000097          	auipc	ra,0x0
    80002016:	e22080e7          	jalr	-478(ra) # 80001e34 <map_region>
    8000201a:	87aa                	mv	a5,a0
    8000201c:	cb89                	beqz	a5,8000202e <kvminit+0x15a>
        panic("kvminit: map UART failed");
    8000201e:	00004517          	auipc	a0,0x4
    80002022:	b6250513          	add	a0,a0,-1182 # 80005b80 <etext+0xb80>
    80002026:	fffff097          	auipc	ra,0xfffff
    8000202a:	572080e7          	jalr	1394(ra) # 80001598 <panic>
    
    printf("Kernel page table setup complete\n");
    8000202e:	00004517          	auipc	a0,0x4
    80002032:	b7250513          	add	a0,a0,-1166 # 80005ba0 <etext+0xba0>
    80002036:	fffff097          	auipc	ra,0xfffff
    8000203a:	1bc080e7          	jalr	444(ra) # 800011f2 <printf>
}
    8000203e:	0001                	nop
    80002040:	60a2                	ld	ra,8(sp)
    80002042:	6402                	ld	s0,0(sp)
    80002044:	0141                	add	sp,sp,16
    80002046:	8082                	ret

0000000080002048 <kvminithart>:

// 激活内核页表
void kvminithart(void) {
    80002048:	1141                	add	sp,sp,-16
    8000204a:	e406                	sd	ra,8(sp)
    8000204c:	e022                	sd	s0,0(sp)
    8000204e:	0800                	add	s0,sp,16
    w_satp(MAKE_SATP(kernel_pagetable));
    80002050:	0000e797          	auipc	a5,0xe
    80002054:	fb878793          	add	a5,a5,-72 # 80010008 <kernel_pagetable>
    80002058:	639c                	ld	a5,0(a5)
    8000205a:	00c7d713          	srl	a4,a5,0xc
    8000205e:	57fd                	li	a5,-1
    80002060:	17fe                	sll	a5,a5,0x3f
    80002062:	8fd9                	or	a5,a5,a4
    80002064:	853e                	mv	a0,a5
    80002066:	00000097          	auipc	ra,0x0
    8000206a:	a8a080e7          	jalr	-1398(ra) # 80001af0 <w_satp>
    sfence_vma();
    8000206e:	00000097          	auipc	ra,0x0
    80002072:	a9c080e7          	jalr	-1380(ra) # 80001b0a <sfence_vma>
    printf("Virtual memory enabled!\n");
    80002076:	00004517          	auipc	a0,0x4
    8000207a:	b5250513          	add	a0,a0,-1198 # 80005bc8 <etext+0xbc8>
    8000207e:	fffff097          	auipc	ra,0xfffff
    80002082:	174080e7          	jalr	372(ra) # 800011f2 <printf>
}
    80002086:	0001                	nop
    80002088:	60a2                	ld	ra,8(sp)
    8000208a:	6402                	ld	s0,0(sp)
    8000208c:	0141                	add	sp,sp,16
    8000208e:	8082                	ret

0000000080002090 <dump_pagetable>:

// 调试用：打印页表
void dump_pagetable(pagetable_t pagetable, int level) {
    80002090:	7179                	add	sp,sp,-48
    80002092:	f406                	sd	ra,40(sp)
    80002094:	f022                	sd	s0,32(sp)
    80002096:	1800                	add	s0,sp,48
    80002098:	fca43c23          	sd	a0,-40(s0)
    8000209c:	87ae                	mv	a5,a1
    8000209e:	fcf42a23          	sw	a5,-44(s0)
    if(level > 2) return;
    800020a2:	fd442783          	lw	a5,-44(s0)
    800020a6:	0007871b          	sext.w	a4,a5
    800020aa:	4789                	li	a5,2
    800020ac:	10e7c163          	blt	a5,a4,800021ae <dump_pagetable+0x11e>
    
    printf("Page table at level %d:\n", level);
    800020b0:	fd442783          	lw	a5,-44(s0)
    800020b4:	85be                	mv	a1,a5
    800020b6:	00004517          	auipc	a0,0x4
    800020ba:	b3250513          	add	a0,a0,-1230 # 80005be8 <etext+0xbe8>
    800020be:	fffff097          	auipc	ra,0xfffff
    800020c2:	134080e7          	jalr	308(ra) # 800011f2 <printf>
    int count = 0;
    800020c6:	fe042623          	sw	zero,-20(s0)
    for(int i = 0; i < 512; i++) {
    800020ca:	fe042423          	sw	zero,-24(s0)
    800020ce:	a0f9                	j	8000219c <dump_pagetable+0x10c>
        pte_t pte = pagetable[i];
    800020d0:	fe842783          	lw	a5,-24(s0)
    800020d4:	078e                	sll	a5,a5,0x3
    800020d6:	fd843703          	ld	a4,-40(s0)
    800020da:	97ba                	add	a5,a5,a4
    800020dc:	639c                	ld	a5,0(a5)
    800020de:	fef43023          	sd	a5,-32(s0)
        if(pte & PTE_V) {
    800020e2:	fe043783          	ld	a5,-32(s0)
    800020e6:	8b85                	and	a5,a5,1
    800020e8:	c7cd                	beqz	a5,80002192 <dump_pagetable+0x102>
            printf("  [%d]: %p", i, (void*)pte);
    800020ea:	fe043703          	ld	a4,-32(s0)
    800020ee:	fe842783          	lw	a5,-24(s0)
    800020f2:	863a                	mv	a2,a4
    800020f4:	85be                	mv	a1,a5
    800020f6:	00004517          	auipc	a0,0x4
    800020fa:	b1250513          	add	a0,a0,-1262 # 80005c08 <etext+0xc08>
    800020fe:	fffff097          	auipc	ra,0xfffff
    80002102:	0f4080e7          	jalr	244(ra) # 800011f2 <printf>
            if(pte & PTE_R) printf(" R");
    80002106:	fe043783          	ld	a5,-32(s0)
    8000210a:	8b89                	and	a5,a5,2
    8000210c:	cb89                	beqz	a5,8000211e <dump_pagetable+0x8e>
    8000210e:	00004517          	auipc	a0,0x4
    80002112:	b0a50513          	add	a0,a0,-1270 # 80005c18 <etext+0xc18>
    80002116:	fffff097          	auipc	ra,0xfffff
    8000211a:	0dc080e7          	jalr	220(ra) # 800011f2 <printf>
            if(pte & PTE_W) printf(" W");
    8000211e:	fe043783          	ld	a5,-32(s0)
    80002122:	8b91                	and	a5,a5,4
    80002124:	cb89                	beqz	a5,80002136 <dump_pagetable+0xa6>
    80002126:	00004517          	auipc	a0,0x4
    8000212a:	afa50513          	add	a0,a0,-1286 # 80005c20 <etext+0xc20>
    8000212e:	fffff097          	auipc	ra,0xfffff
    80002132:	0c4080e7          	jalr	196(ra) # 800011f2 <printf>
            if(pte & PTE_X) printf(" X");
    80002136:	fe043783          	ld	a5,-32(s0)
    8000213a:	8ba1                	and	a5,a5,8
    8000213c:	cb89                	beqz	a5,8000214e <dump_pagetable+0xbe>
    8000213e:	00004517          	auipc	a0,0x4
    80002142:	aea50513          	add	a0,a0,-1302 # 80005c28 <etext+0xc28>
    80002146:	fffff097          	auipc	ra,0xfffff
    8000214a:	0ac080e7          	jalr	172(ra) # 800011f2 <printf>
            printf(" -> PA %p\n", (void*)PTE_PA(pte));
    8000214e:	fe043783          	ld	a5,-32(s0)
    80002152:	83a9                	srl	a5,a5,0xa
    80002154:	07b2                	sll	a5,a5,0xc
    80002156:	85be                	mv	a1,a5
    80002158:	00004517          	auipc	a0,0x4
    8000215c:	ad850513          	add	a0,a0,-1320 # 80005c30 <etext+0xc30>
    80002160:	fffff097          	auipc	ra,0xfffff
    80002164:	092080e7          	jalr	146(ra) # 800011f2 <printf>
            count++;
    80002168:	fec42783          	lw	a5,-20(s0)
    8000216c:	2785                	addw	a5,a5,1
    8000216e:	fef42623          	sw	a5,-20(s0)
            if(count > 10) {
    80002172:	fec42783          	lw	a5,-20(s0)
    80002176:	0007871b          	sext.w	a4,a5
    8000217a:	47a9                	li	a5,10
    8000217c:	00e7db63          	bge	a5,a4,80002192 <dump_pagetable+0x102>
                printf("  ... (more entries)\n");
    80002180:	00004517          	auipc	a0,0x4
    80002184:	ac050513          	add	a0,a0,-1344 # 80005c40 <etext+0xc40>
    80002188:	fffff097          	auipc	ra,0xfffff
    8000218c:	06a080e7          	jalr	106(ra) # 800011f2 <printf>
                break;
    80002190:	a005                	j	800021b0 <dump_pagetable+0x120>
    for(int i = 0; i < 512; i++) {
    80002192:	fe842783          	lw	a5,-24(s0)
    80002196:	2785                	addw	a5,a5,1
    80002198:	fef42423          	sw	a5,-24(s0)
    8000219c:	fe842783          	lw	a5,-24(s0)
    800021a0:	0007871b          	sext.w	a4,a5
    800021a4:	1ff00793          	li	a5,511
    800021a8:	f2e7d4e3          	bge	a5,a4,800020d0 <dump_pagetable+0x40>
    800021ac:	a011                	j	800021b0 <dump_pagetable+0x120>
    if(level > 2) return;
    800021ae:	0001                	nop
            }
        }
    }
}
    800021b0:	70a2                	ld	ra,40(sp)
    800021b2:	7402                	ld	s0,32(sp)
    800021b4:	6145                	add	sp,sp,48
    800021b6:	8082                	ret

00000000800021b8 <check_page_permission>:

// 权限检查
int check_page_permission(uint64 addr, int access_type) {
    800021b8:	7179                	add	sp,sp,-48
    800021ba:	f406                	sd	ra,40(sp)
    800021bc:	f022                	sd	s0,32(sp)
    800021be:	1800                	add	s0,sp,48
    800021c0:	fca43c23          	sd	a0,-40(s0)
    800021c4:	87ae                	mv	a5,a1
    800021c6:	fcf42a23          	sw	a5,-44(s0)
    pte_t *pte = walk_lookup(kernel_pagetable, addr);
    800021ca:	0000e797          	auipc	a5,0xe
    800021ce:	e3e78793          	add	a5,a5,-450 # 80010008 <kernel_pagetable>
    800021d2:	639c                	ld	a5,0(a5)
    800021d4:	fd843583          	ld	a1,-40(s0)
    800021d8:	853e                	mv	a0,a5
    800021da:	00000097          	auipc	ra,0x0
    800021de:	a26080e7          	jalr	-1498(ra) # 80001c00 <walk_lookup>
    800021e2:	fea43423          	sd	a0,-24(s0)
    
    if(pte == 0 || !(*pte & PTE_V)) {
    800021e6:	fe843783          	ld	a5,-24(s0)
    800021ea:	c791                	beqz	a5,800021f6 <check_page_permission+0x3e>
    800021ec:	fe843783          	ld	a5,-24(s0)
    800021f0:	639c                	ld	a5,0(a5)
    800021f2:	8b85                	and	a5,a5,1
    800021f4:	ef91                	bnez	a5,80002210 <check_page_permission+0x58>
        printf("Permission check: Address %p not mapped\n", (void*)addr);
    800021f6:	fd843783          	ld	a5,-40(s0)
    800021fa:	85be                	mv	a1,a5
    800021fc:	00004517          	auipc	a0,0x4
    80002200:	a5c50513          	add	a0,a0,-1444 # 80005c58 <etext+0xc58>
    80002204:	fffff097          	auipc	ra,0xfffff
    80002208:	fee080e7          	jalr	-18(ra) # 800011f2 <printf>
        return 0;
    8000220c:	4781                	li	a5,0
    8000220e:	a079                	j	8000229c <check_page_permission+0xe4>
    }
    
    if((access_type & ACCESS_READ) && !(*pte & PTE_R)) {
    80002210:	fd442783          	lw	a5,-44(s0)
    80002214:	8b85                	and	a5,a5,1
    80002216:	2781                	sext.w	a5,a5
    80002218:	c39d                	beqz	a5,8000223e <check_page_permission+0x86>
    8000221a:	fe843783          	ld	a5,-24(s0)
    8000221e:	639c                	ld	a5,0(a5)
    80002220:	8b89                	and	a5,a5,2
    80002222:	ef91                	bnez	a5,8000223e <check_page_permission+0x86>
        printf("Permission check: No read permission for %p\n", (void*)addr);
    80002224:	fd843783          	ld	a5,-40(s0)
    80002228:	85be                	mv	a1,a5
    8000222a:	00004517          	auipc	a0,0x4
    8000222e:	a5e50513          	add	a0,a0,-1442 # 80005c88 <etext+0xc88>
    80002232:	fffff097          	auipc	ra,0xfffff
    80002236:	fc0080e7          	jalr	-64(ra) # 800011f2 <printf>
        return 0;
    8000223a:	4781                	li	a5,0
    8000223c:	a085                	j	8000229c <check_page_permission+0xe4>
    }
    
    if((access_type & ACCESS_WRITE) && !(*pte & PTE_W)) {
    8000223e:	fd442783          	lw	a5,-44(s0)
    80002242:	8b89                	and	a5,a5,2
    80002244:	2781                	sext.w	a5,a5
    80002246:	c39d                	beqz	a5,8000226c <check_page_permission+0xb4>
    80002248:	fe843783          	ld	a5,-24(s0)
    8000224c:	639c                	ld	a5,0(a5)
    8000224e:	8b91                	and	a5,a5,4
    80002250:	ef91                	bnez	a5,8000226c <check_page_permission+0xb4>
        printf("Permission check: No write permission for %p\n", (void*)addr);
    80002252:	fd843783          	ld	a5,-40(s0)
    80002256:	85be                	mv	a1,a5
    80002258:	00004517          	auipc	a0,0x4
    8000225c:	a6050513          	add	a0,a0,-1440 # 80005cb8 <etext+0xcb8>
    80002260:	fffff097          	auipc	ra,0xfffff
    80002264:	f92080e7          	jalr	-110(ra) # 800011f2 <printf>
        return 0;
    80002268:	4781                	li	a5,0
    8000226a:	a80d                	j	8000229c <check_page_permission+0xe4>
    }
    
    if((access_type & ACCESS_EXEC) && !(*pte & PTE_X)) {
    8000226c:	fd442783          	lw	a5,-44(s0)
    80002270:	8b91                	and	a5,a5,4
    80002272:	2781                	sext.w	a5,a5
    80002274:	c39d                	beqz	a5,8000229a <check_page_permission+0xe2>
    80002276:	fe843783          	ld	a5,-24(s0)
    8000227a:	639c                	ld	a5,0(a5)
    8000227c:	8ba1                	and	a5,a5,8
    8000227e:	ef91                	bnez	a5,8000229a <check_page_permission+0xe2>
        printf("Permission check: No execute permission for %p\n", (void*)addr);
    80002280:	fd843783          	ld	a5,-40(s0)
    80002284:	85be                	mv	a1,a5
    80002286:	00004517          	auipc	a0,0x4
    8000228a:	a6250513          	add	a0,a0,-1438 # 80005ce8 <etext+0xce8>
    8000228e:	fffff097          	auipc	ra,0xfffff
    80002292:	f64080e7          	jalr	-156(ra) # 800011f2 <printf>
        return 0;
    80002296:	4781                	li	a5,0
    80002298:	a011                	j	8000229c <check_page_permission+0xe4>
    }
    
    return 1;
    8000229a:	4785                	li	a5,1
    8000229c:	853e                	mv	a0,a5
    8000229e:	70a2                	ld	ra,40(sp)
    800022a0:	7402                	ld	s0,32(sp)
    800022a2:	6145                	add	sp,sp,48
    800022a4:	8082                	ret

00000000800022a6 <test_multilevel_pagetable>:
#include "mm.h"
#include "defs.h"
#include "riscv.h"

// ==================== 多级页表映射测试 ====================
void test_multilevel_pagetable(void) {
    800022a6:	711d                	add	sp,sp,-96
    800022a8:	ec86                	sd	ra,88(sp)
    800022aa:	e8a2                	sd	s0,80(sp)
    800022ac:	1080                	add	s0,sp,96
    printf("=== Testing Multi-level Page Table ===\n");
    800022ae:	00004517          	auipc	a0,0x4
    800022b2:	a6a50513          	add	a0,a0,-1430 # 80005d18 <etext+0xd18>
    800022b6:	fffff097          	auipc	ra,0xfffff
    800022ba:	f3c080e7          	jalr	-196(ra) # 800011f2 <printf>
    
    pagetable_t pt = create_pagetable();
    800022be:	00000097          	auipc	ra,0x0
    800022c2:	85e080e7          	jalr	-1954(ra) # 80001b1c <create_pagetable>
    800022c6:	fea43023          	sd	a0,-32(s0)
    if(pt == 0) {
    800022ca:	fe043783          	ld	a5,-32(s0)
    800022ce:	eb91                	bnez	a5,800022e2 <test_multilevel_pagetable+0x3c>
        printf("ERROR: create_pagetable failed\n");
    800022d0:	00004517          	auipc	a0,0x4
    800022d4:	a7050513          	add	a0,a0,-1424 # 80005d40 <etext+0xd40>
    800022d8:	fffff097          	auipc	ra,0xfffff
    800022dc:	f1a080e7          	jalr	-230(ra) # 800011f2 <printf>
    800022e0:	aa59                	j	80002476 <test_multilevel_pagetable+0x1d0>
        return;
    }
    
    // 测试地址数组
    uint64 test_vas[] = {
    800022e2:	00004797          	auipc	a5,0x4
    800022e6:	ba678793          	add	a5,a5,-1114 # 80005e88 <etext+0xe88>
    800022ea:	6390                	ld	a2,0(a5)
    800022ec:	6794                	ld	a3,8(a5)
    800022ee:	6b98                	ld	a4,16(a5)
    800022f0:	6f9c                	ld	a5,24(a5)
    800022f2:	fac43423          	sd	a2,-88(s0)
    800022f6:	fad43823          	sd	a3,-80(s0)
    800022fa:	fae43c23          	sd	a4,-72(s0)
    800022fe:	fcf43023          	sd	a5,-64(s0)
        0x200000,       // 2MB
        0x40000000,     // 1GB
        0x7000000000,   // 接近39位限制
    };
    
    for(int i = 0; i < 4; i++) {
    80002302:	fe042623          	sw	zero,-20(s0)
    80002306:	a299                	j	8000244c <test_multilevel_pagetable+0x1a6>
        uint64 va = test_vas[i];
    80002308:	fec42783          	lw	a5,-20(s0)
    8000230c:	078e                	sll	a5,a5,0x3
    8000230e:	17c1                	add	a5,a5,-16
    80002310:	97a2                	add	a5,a5,s0
    80002312:	fb87b783          	ld	a5,-72(a5)
    80002316:	fcf43c23          	sd	a5,-40(s0)
        
        // Sv39地址空间边界检查
        if(va >= (1L << 39)) {
    8000231a:	fd843703          	ld	a4,-40(s0)
    8000231e:	57fd                	li	a5,-1
    80002320:	83e5                	srl	a5,a5,0x19
    80002322:	02e7f163          	bgeu	a5,a4,80002344 <test_multilevel_pagetable+0x9e>
            printf("Test %d: VA %p exceeds Sv39 limit, skipping\n", i, (void*)va);
    80002326:	fd843703          	ld	a4,-40(s0)
    8000232a:	fec42783          	lw	a5,-20(s0)
    8000232e:	863a                	mv	a2,a4
    80002330:	85be                	mv	a1,a5
    80002332:	00004517          	auipc	a0,0x4
    80002336:	a2e50513          	add	a0,a0,-1490 # 80005d60 <etext+0xd60>
    8000233a:	fffff097          	auipc	ra,0xfffff
    8000233e:	eb8080e7          	jalr	-328(ra) # 800011f2 <printf>
            continue;
    80002342:	a201                	j	80002442 <test_multilevel_pagetable+0x19c>
        }
        
        // 分配物理页面
        uint64 pa = (uint64)alloc_page();
    80002344:	fffff097          	auipc	ra,0xfffff
    80002348:	542080e7          	jalr	1346(ra) # 80001886 <alloc_page>
    8000234c:	87aa                	mv	a5,a0
    8000234e:	fcf43823          	sd	a5,-48(s0)
        if(pa == 0) {
    80002352:	fd043783          	ld	a5,-48(s0)
    80002356:	ef89                	bnez	a5,80002370 <test_multilevel_pagetable+0xca>
            printf("ERROR: alloc_page failed for test %d\n", i);
    80002358:	fec42783          	lw	a5,-20(s0)
    8000235c:	85be                	mv	a1,a5
    8000235e:	00004517          	auipc	a0,0x4
    80002362:	a3250513          	add	a0,a0,-1486 # 80005d90 <etext+0xd90>
    80002366:	fffff097          	auipc	ra,0xfffff
    8000236a:	e8c080e7          	jalr	-372(ra) # 800011f2 <printf>
            continue;
    8000236e:	a8d1                	j	80002442 <test_multilevel_pagetable+0x19c>
        }
        
        printf("Test %d: mapping VA %p to PA %p\n", i, (void*)va, (void*)pa);
    80002370:	fd843703          	ld	a4,-40(s0)
    80002374:	fd043683          	ld	a3,-48(s0)
    80002378:	fec42783          	lw	a5,-20(s0)
    8000237c:	863a                	mv	a2,a4
    8000237e:	85be                	mv	a1,a5
    80002380:	00004517          	auipc	a0,0x4
    80002384:	a3850513          	add	a0,a0,-1480 # 80005db8 <etext+0xdb8>
    80002388:	fffff097          	auipc	ra,0xfffff
    8000238c:	e6a080e7          	jalr	-406(ra) # 800011f2 <printf>
        
        // 建立映射
        if(map_page(pt, va, pa, PTE_R | PTE_W | PTE_X) != 0) {
    80002390:	46b9                	li	a3,14
    80002392:	fd043603          	ld	a2,-48(s0)
    80002396:	fd843583          	ld	a1,-40(s0)
    8000239a:	fe043503          	ld	a0,-32(s0)
    8000239e:	00000097          	auipc	ra,0x0
    800023a2:	9e6080e7          	jalr	-1562(ra) # 80001d84 <map_page>
    800023a6:	87aa                	mv	a5,a0
    800023a8:	c785                	beqz	a5,800023d0 <test_multilevel_pagetable+0x12a>
            printf("ERROR: map_page failed for test %d\n", i);
    800023aa:	fec42783          	lw	a5,-20(s0)
    800023ae:	85be                	mv	a1,a5
    800023b0:	00004517          	auipc	a0,0x4
    800023b4:	a3050513          	add	a0,a0,-1488 # 80005de0 <etext+0xde0>
    800023b8:	fffff097          	auipc	ra,0xfffff
    800023bc:	e3a080e7          	jalr	-454(ra) # 800011f2 <printf>
            free_page((void*)pa);
    800023c0:	fd043783          	ld	a5,-48(s0)
    800023c4:	853e                	mv	a0,a5
    800023c6:	fffff097          	auipc	ra,0xfffff
    800023ca:	522080e7          	jalr	1314(ra) # 800018e8 <free_page>
            continue;
    800023ce:	a895                	j	80002442 <test_multilevel_pagetable+0x19c>
        }
        
        // 验证映射
        pte_t *pte = walk_lookup(pt, va);
    800023d0:	fd843583          	ld	a1,-40(s0)
    800023d4:	fe043503          	ld	a0,-32(s0)
    800023d8:	00000097          	auipc	ra,0x0
    800023dc:	828080e7          	jalr	-2008(ra) # 80001c00 <walk_lookup>
    800023e0:	fca43423          	sd	a0,-56(s0)
        if(pte == 0 || !(*pte & PTE_V) || PTE_PA(*pte) != pa) {
    800023e4:	fc843783          	ld	a5,-56(s0)
    800023e8:	cf99                	beqz	a5,80002406 <test_multilevel_pagetable+0x160>
    800023ea:	fc843783          	ld	a5,-56(s0)
    800023ee:	639c                	ld	a5,0(a5)
    800023f0:	8b85                	and	a5,a5,1
    800023f2:	cb91                	beqz	a5,80002406 <test_multilevel_pagetable+0x160>
    800023f4:	fc843783          	ld	a5,-56(s0)
    800023f8:	639c                	ld	a5,0(a5)
    800023fa:	83a9                	srl	a5,a5,0xa
    800023fc:	07b2                	sll	a5,a5,0xc
    800023fe:	fd043703          	ld	a4,-48(s0)
    80002402:	00f70e63          	beq	a4,a5,8000241e <test_multilevel_pagetable+0x178>
            printf("ERROR: mapping verification failed for test %d\n", i);
    80002406:	fec42783          	lw	a5,-20(s0)
    8000240a:	85be                	mv	a1,a5
    8000240c:	00004517          	auipc	a0,0x4
    80002410:	9fc50513          	add	a0,a0,-1540 # 80005e08 <etext+0xe08>
    80002414:	fffff097          	auipc	ra,0xfffff
    80002418:	dde080e7          	jalr	-546(ra) # 800011f2 <printf>
    8000241c:	a821                	j	80002434 <test_multilevel_pagetable+0x18e>
        } else {
            printf("Test %d: mapping verification PASSED\n", i);
    8000241e:	fec42783          	lw	a5,-20(s0)
    80002422:	85be                	mv	a1,a5
    80002424:	00004517          	auipc	a0,0x4
    80002428:	a1450513          	add	a0,a0,-1516 # 80005e38 <etext+0xe38>
    8000242c:	fffff097          	auipc	ra,0xfffff
    80002430:	dc6080e7          	jalr	-570(ra) # 800011f2 <printf>
        }
        
        // 清理
        free_page((void*)pa);
    80002434:	fd043783          	ld	a5,-48(s0)
    80002438:	853e                	mv	a0,a5
    8000243a:	fffff097          	auipc	ra,0xfffff
    8000243e:	4ae080e7          	jalr	1198(ra) # 800018e8 <free_page>
    for(int i = 0; i < 4; i++) {
    80002442:	fec42783          	lw	a5,-20(s0)
    80002446:	2785                	addw	a5,a5,1
    80002448:	fef42623          	sw	a5,-20(s0)
    8000244c:	fec42783          	lw	a5,-20(s0)
    80002450:	0007871b          	sext.w	a4,a5
    80002454:	478d                	li	a5,3
    80002456:	eae7d9e3          	bge	a5,a4,80002308 <test_multilevel_pagetable+0x62>
    }
    
    // 清理页表
    destroy_pagetable(pt);
    8000245a:	fe043503          	ld	a0,-32(s0)
    8000245e:	fffff097          	auipc	ra,0xfffff
    80002462:	778080e7          	jalr	1912(ra) # 80001bd6 <destroy_pagetable>
    printf("Multi-level page table test completed\n\n");
    80002466:	00004517          	auipc	a0,0x4
    8000246a:	9fa50513          	add	a0,a0,-1542 # 80005e60 <etext+0xe60>
    8000246e:	fffff097          	auipc	ra,0xfffff
    80002472:	d84080e7          	jalr	-636(ra) # 800011f2 <printf>
}
    80002476:	60e6                	ld	ra,88(sp)
    80002478:	6446                	ld	s0,80(sp)
    8000247a:	6125                	add	sp,sp,96
    8000247c:	8082                	ret

000000008000247e <test_edge_cases>:

// ==================== 边界条件测试 ====================
void test_edge_cases(void) {
    8000247e:	cb010113          	add	sp,sp,-848
    80002482:	34113423          	sd	ra,840(sp)
    80002486:	34813023          	sd	s0,832(sp)
    8000248a:	0e80                	add	s0,sp,848
    printf("=== Testing Edge Cases ===\n");
    8000248c:	00004517          	auipc	a0,0x4
    80002490:	a1c50513          	add	a0,a0,-1508 # 80005ea8 <etext+0xea8>
    80002494:	fffff097          	auipc	ra,0xfffff
    80002498:	d5e080e7          	jalr	-674(ra) # 800011f2 <printf>
    
    // 测试内存耗尽
    printf("Testing memory exhaustion...\n");
    8000249c:	00004517          	auipc	a0,0x4
    800024a0:	a2c50513          	add	a0,a0,-1492 # 80005ec8 <etext+0xec8>
    800024a4:	fffff097          	auipc	ra,0xfffff
    800024a8:	d4e080e7          	jalr	-690(ra) # 800011f2 <printf>
    void *pages[100];
    int allocated = 0;
    800024ac:	fe042623          	sw	zero,-20(s0)
    
    for(int i = 0; i < 100; i++) {
    800024b0:	fe042423          	sw	zero,-24(s0)
    800024b4:	a899                	j	8000250a <test_edge_cases+0x8c>
        pages[i] = alloc_page();
    800024b6:	fffff097          	auipc	ra,0xfffff
    800024ba:	3d0080e7          	jalr	976(ra) # 80001886 <alloc_page>
    800024be:	872a                	mv	a4,a0
    800024c0:	fe842783          	lw	a5,-24(s0)
    800024c4:	078e                	sll	a5,a5,0x3
    800024c6:	17c1                	add	a5,a5,-16
    800024c8:	97a2                	add	a5,a5,s0
    800024ca:	cce7b023          	sd	a4,-832(a5)
        if(pages[i] == 0) {
    800024ce:	fe842783          	lw	a5,-24(s0)
    800024d2:	078e                	sll	a5,a5,0x3
    800024d4:	17c1                	add	a5,a5,-16
    800024d6:	97a2                	add	a5,a5,s0
    800024d8:	cc07b783          	ld	a5,-832(a5)
    800024dc:	ef89                	bnez	a5,800024f6 <test_edge_cases+0x78>
            printf("Memory exhausted after %d pages\n", i);
    800024de:	fe842783          	lw	a5,-24(s0)
    800024e2:	85be                	mv	a1,a5
    800024e4:	00004517          	auipc	a0,0x4
    800024e8:	a0450513          	add	a0,a0,-1532 # 80005ee8 <etext+0xee8>
    800024ec:	fffff097          	auipc	ra,0xfffff
    800024f0:	d06080e7          	jalr	-762(ra) # 800011f2 <printf>
            break;
    800024f4:	a01d                	j	8000251a <test_edge_cases+0x9c>
        }
        allocated++;
    800024f6:	fec42783          	lw	a5,-20(s0)
    800024fa:	2785                	addw	a5,a5,1
    800024fc:	fef42623          	sw	a5,-20(s0)
    for(int i = 0; i < 100; i++) {
    80002500:	fe842783          	lw	a5,-24(s0)
    80002504:	2785                	addw	a5,a5,1
    80002506:	fef42423          	sw	a5,-24(s0)
    8000250a:	fe842783          	lw	a5,-24(s0)
    8000250e:	0007871b          	sext.w	a4,a5
    80002512:	06300793          	li	a5,99
    80002516:	fae7d0e3          	bge	a5,a4,800024b6 <test_edge_cases+0x38>
    }
    
    // 释放所有页面
    for(int i = 0; i < allocated; i++) {
    8000251a:	fe042223          	sw	zero,-28(s0)
    8000251e:	a015                	j	80002542 <test_edge_cases+0xc4>
        free_page(pages[i]);
    80002520:	fe442783          	lw	a5,-28(s0)
    80002524:	078e                	sll	a5,a5,0x3
    80002526:	17c1                	add	a5,a5,-16
    80002528:	97a2                	add	a5,a5,s0
    8000252a:	cc07b783          	ld	a5,-832(a5)
    8000252e:	853e                	mv	a0,a5
    80002530:	fffff097          	auipc	ra,0xfffff
    80002534:	3b8080e7          	jalr	952(ra) # 800018e8 <free_page>
    for(int i = 0; i < allocated; i++) {
    80002538:	fe442783          	lw	a5,-28(s0)
    8000253c:	2785                	addw	a5,a5,1
    8000253e:	fef42223          	sw	a5,-28(s0)
    80002542:	fe442783          	lw	a5,-28(s0)
    80002546:	873e                	mv	a4,a5
    80002548:	fec42783          	lw	a5,-20(s0)
    8000254c:	2701                	sext.w	a4,a4
    8000254e:	2781                	sext.w	a5,a5
    80002550:	fcf748e3          	blt	a4,a5,80002520 <test_edge_cases+0xa2>
    }
    printf("Memory exhaustion test completed\n");
    80002554:	00004517          	auipc	a0,0x4
    80002558:	9bc50513          	add	a0,a0,-1604 # 80005f10 <etext+0xf10>
    8000255c:	fffff097          	auipc	ra,0xfffff
    80002560:	c96080e7          	jalr	-874(ra) # 800011f2 <printf>
    
    // 测试地址对齐
    printf("Testing address alignment...\n");
    80002564:	00004517          	auipc	a0,0x4
    80002568:	9d450513          	add	a0,a0,-1580 # 80005f38 <etext+0xf38>
    8000256c:	fffff097          	auipc	ra,0xfffff
    80002570:	c86080e7          	jalr	-890(ra) # 800011f2 <printf>
    pagetable_t pt = create_pagetable();
    80002574:	fffff097          	auipc	ra,0xfffff
    80002578:	5a8080e7          	jalr	1448(ra) # 80001b1c <create_pagetable>
    8000257c:	fca43c23          	sd	a0,-40(s0)
    uint64 pa = (uint64)alloc_page();
    80002580:	fffff097          	auipc	ra,0xfffff
    80002584:	306080e7          	jalr	774(ra) # 80001886 <alloc_page>
    80002588:	87aa                	mv	a5,a0
    8000258a:	fcf43823          	sd	a5,-48(s0)
    
    printf("Address alignment test completed\n");
    8000258e:	00004517          	auipc	a0,0x4
    80002592:	9ca50513          	add	a0,a0,-1590 # 80005f58 <etext+0xf58>
    80002596:	fffff097          	auipc	ra,0xfffff
    8000259a:	c5c080e7          	jalr	-932(ra) # 800011f2 <printf>
    
    // 清理
    free_page((void*)pa);
    8000259e:	fd043783          	ld	a5,-48(s0)
    800025a2:	853e                	mv	a0,a5
    800025a4:	fffff097          	auipc	ra,0xfffff
    800025a8:	344080e7          	jalr	836(ra) # 800018e8 <free_page>
    destroy_pagetable(pt);
    800025ac:	fd843503          	ld	a0,-40(s0)
    800025b0:	fffff097          	auipc	ra,0xfffff
    800025b4:	626080e7          	jalr	1574(ra) # 80001bd6 <destroy_pagetable>
    printf("Edge cases test completed\n\n");
    800025b8:	00004517          	auipc	a0,0x4
    800025bc:	9c850513          	add	a0,a0,-1592 # 80005f80 <etext+0xf80>
    800025c0:	fffff097          	auipc	ra,0xfffff
    800025c4:	c32080e7          	jalr	-974(ra) # 800011f2 <printf>
}
    800025c8:	0001                	nop
    800025ca:	34813083          	ld	ra,840(sp)
    800025ce:	34013403          	ld	s0,832(sp)
    800025d2:	35010113          	add	sp,sp,848
    800025d6:	8082                	ret

00000000800025d8 <run_comprehensive_tests>:

// ==================== 综合测试入口 ====================
void run_comprehensive_tests(void) {
    800025d8:	1141                	add	sp,sp,-16
    800025da:	e406                	sd	ra,8(sp)
    800025dc:	e022                	sd	s0,0(sp)
    800025de:	0800                	add	s0,sp,16
    printf("=== Comprehensive Memory Management Tests ===\n\n");
    800025e0:	00004517          	auipc	a0,0x4
    800025e4:	9c050513          	add	a0,a0,-1600 # 80005fa0 <etext+0xfa0>
    800025e8:	fffff097          	auipc	ra,0xfffff
    800025ec:	c0a080e7          	jalr	-1014(ra) # 800011f2 <printf>
    
    // 按顺序运行测试
    test_multilevel_pagetable();
    800025f0:	00000097          	auipc	ra,0x0
    800025f4:	cb6080e7          	jalr	-842(ra) # 800022a6 <test_multilevel_pagetable>
    test_edge_cases();
    800025f8:	00000097          	auipc	ra,0x0
    800025fc:	e86080e7          	jalr	-378(ra) # 8000247e <test_edge_cases>
    
    printf("All comprehensive tests completed!\n");
    80002600:	00004517          	auipc	a0,0x4
    80002604:	9d050513          	add	a0,a0,-1584 # 80005fd0 <etext+0xfd0>
    80002608:	fffff097          	auipc	ra,0xfffff
    8000260c:	bea080e7          	jalr	-1046(ra) # 800011f2 <printf>
    80002610:	0001                	nop
    80002612:	60a2                	ld	ra,8(sp)
    80002614:	6402                	ld	s0,0(sp)
    80002616:	0141                	add	sp,sp,16
    80002618:	8082                	ret

000000008000261a <r_sstatus>:
        printf("register_interrupt: invalid IRQ %d\n", irq);
        return;
    }
    
    interrupt_handlers[irq] = handler;
    printf("Registered handler for IRQ %d\n", irq);
    8000261a:	1101                	add	sp,sp,-32
    8000261c:	ec22                	sd	s0,24(sp)
    8000261e:	1000                	add	s0,sp,32
}

    80002620:	100027f3          	csrr	a5,sstatus
    80002624:	fef43423          	sd	a5,-24(s0)
// ==================== 设备中断处理 ====================
    80002628:	fe843783          	ld	a5,-24(s0)
// 检查并处理设备中断
    8000262c:	853e                	mv	a0,a5
    8000262e:	6462                	ld	s0,24(sp)
    80002630:	6105                	add	sp,sp,32
    80002632:	8082                	ret

0000000080002634 <w_sstatus>:
// 返回值：1=处理了中断，0=没有中断待处理
static int devintr(void)
    80002634:	1101                	add	sp,sp,-32
    80002636:	ec22                	sd	s0,24(sp)
    80002638:	1000                	add	s0,sp,32
    8000263a:	fea43423          	sd	a0,-24(s0)
{
    8000263e:	fe843783          	ld	a5,-24(s0)
    80002642:	10079073          	csrw	sstatus,a5
    uint64 scause = r_scause();
    80002646:	0001                	nop
    80002648:	6462                	ld	s0,24(sp)
    8000264a:	6105                	add	sp,sp,32
    8000264c:	8082                	ret

000000008000264e <r_sie>:
    
    if((scause & 0x8000000000000000L) == 0) {
    8000264e:	1101                	add	sp,sp,-32
    80002650:	ec22                	sd	s0,24(sp)
    80002652:	1000                	add	s0,sp,32
        return 0;
    }
    80002654:	104027f3          	csrr	a5,sie
    80002658:	fef43423          	sd	a5,-24(s0)
    
    8000265c:	fe843783          	ld	a5,-24(s0)
    scause = scause & 0xff;
    80002660:	853e                	mv	a0,a5
    80002662:	6462                	ld	s0,24(sp)
    80002664:	6105                	add	sp,sp,32
    80002666:	8082                	ret

0000000080002668 <w_sie>:
    
    if(scause == IRQ_S_TIMER) {
    80002668:	1101                	add	sp,sp,-32
    8000266a:	ec22                	sd	s0,24(sp)
    8000266c:	1000                	add	s0,sp,32
    8000266e:	fea43423          	sd	a0,-24(s0)
        // 时钟中断处理
    80002672:	fe843783          	ld	a5,-24(s0)
    80002676:	10479073          	csrw	sie,a5
        interrupt_counts[IRQ_S_TIMER]++;
    8000267a:	0001                	nop
    8000267c:	6462                	ld	s0,24(sp)
    8000267e:	6105                	add	sp,sp,32
    80002680:	8082                	ret

0000000080002682 <r_sip>:
        
        if(interrupt_handlers[IRQ_S_TIMER]) {
    80002682:	1101                	add	sp,sp,-32
    80002684:	ec22                	sd	s0,24(sp)
    80002686:	1000                	add	s0,sp,32
            interrupt_handlers[IRQ_S_TIMER]();
        }
    80002688:	144027f3          	csrr	a5,sip
    8000268c:	fef43423          	sd	a5,-24(s0)
        
    80002690:	fe843783          	ld	a5,-24(s0)
        return 1;
    80002694:	853e                	mv	a0,a5
    80002696:	6462                	ld	s0,24(sp)
    80002698:	6105                	add	sp,sp,32
    8000269a:	8082                	ret

000000008000269c <w_sip>:
        
    } else if(scause == IRQ_S_SOFT) {
    8000269c:	1101                	add	sp,sp,-32
    8000269e:	ec22                	sd	s0,24(sp)
    800026a0:	1000                	add	s0,sp,32
    800026a2:	fea43423          	sd	a0,-24(s0)
        // 软件中断处理（来自 M 模式的时钟注入）
    800026a6:	fe843783          	ld	a5,-24(s0)
    800026aa:	14479073          	csrw	sip,a5
        interrupt_counts[IRQ_S_SOFT]++;
    800026ae:	0001                	nop
    800026b0:	6462                	ld	s0,24(sp)
    800026b2:	6105                	add	sp,sp,32
    800026b4:	8082                	ret

00000000800026b6 <r_scause>:
        
        // 清除软件中断标志
    800026b6:	1101                	add	sp,sp,-32
    800026b8:	ec22                	sd	s0,24(sp)
    800026ba:	1000                	add	s0,sp,32
        w_sip(r_sip() & ~2);
        
    800026bc:	142027f3          	csrr	a5,scause
    800026c0:	fef43423          	sd	a5,-24(s0)
        // 这实际上是时钟中断，调用时钟处理函数
    800026c4:	fe843783          	ld	a5,-24(s0)
        if(interrupt_handlers[IRQ_S_TIMER]) {
    800026c8:	853e                	mv	a0,a5
    800026ca:	6462                	ld	s0,24(sp)
    800026cc:	6105                	add	sp,sp,32
    800026ce:	8082                	ret

00000000800026d0 <r_stval>:
    } else if(scause == IRQ_S_EXT) {
        // 外部中断处理
        interrupt_counts[IRQ_S_EXT]++;
        
        if(interrupt_handlers[IRQ_S_EXT]) {
            interrupt_handlers[IRQ_S_EXT]();
    800026d0:	1101                	add	sp,sp,-32
    800026d2:	ec22                	sd	s0,24(sp)
    800026d4:	1000                	add	s0,sp,32
        }
        
    800026d6:	143027f3          	csrr	a5,stval
    800026da:	fef43423          	sd	a5,-24(s0)
        return 1;
    800026de:	fe843783          	ld	a5,-24(s0)
    }
    800026e2:	853e                	mv	a0,a5
    800026e4:	6462                	ld	s0,24(sp)
    800026e6:	6105                	add	sp,sp,32
    800026e8:	8082                	ret

00000000800026ea <w_stvec>:
}
// ==================== 系统调用处理 ====================
void handle_syscall(struct trapframe *tf) {
    printf("\n=== System Call ===\n");
    printf("syscall number: %d (in a7)\n", (int)tf->a7);
    printf("arguments: a0=%p, a1=%p\n", (void*)tf->a0, (void*)tf->a1);
    800026ea:	1101                	add	sp,sp,-32
    800026ec:	ec22                	sd	s0,24(sp)
    800026ee:	1000                	add	s0,sp,32
    800026f0:	fea43423          	sd	a0,-24(s0)
    printf("called from: %p\n", (void*)tf->sepc);
    800026f4:	fe843783          	ld	a5,-24(s0)
    800026f8:	10579073          	csrw	stvec,a5
    
    800026fc:	0001                	nop
    800026fe:	6462                	ld	s0,24(sp)
    80002700:	6105                	add	sp,sp,32
    80002702:	8082                	ret

0000000080002704 <trap_init>:
{
    80002704:	1101                	add	sp,sp,-32
    80002706:	ec06                	sd	ra,24(sp)
    80002708:	e822                	sd	s0,16(sp)
    8000270a:	1000                	add	s0,sp,32
    printf("Initializing trap system...\n");
    8000270c:	00004517          	auipc	a0,0x4
    80002710:	8ec50513          	add	a0,a0,-1812 # 80005ff8 <etext+0xff8>
    80002714:	fffff097          	auipc	ra,0xfffff
    80002718:	ade080e7          	jalr	-1314(ra) # 800011f2 <printf>
    for(int i = 0; i < 16; i++) {
    8000271c:	fe042623          	sw	zero,-20(s0)
    80002720:	a815                	j	80002754 <trap_init+0x50>
        interrupt_handlers[i] = 0;
    80002722:	0000a717          	auipc	a4,0xa
    80002726:	99e70713          	add	a4,a4,-1634 # 8000c0c0 <interrupt_handlers>
    8000272a:	fec42783          	lw	a5,-20(s0)
    8000272e:	078e                	sll	a5,a5,0x3
    80002730:	97ba                	add	a5,a5,a4
    80002732:	0007b023          	sd	zero,0(a5)
        interrupt_counts[i] = 0;
    80002736:	0000a717          	auipc	a4,0xa
    8000273a:	90270713          	add	a4,a4,-1790 # 8000c038 <interrupt_counts>
    8000273e:	fec42783          	lw	a5,-20(s0)
    80002742:	078e                	sll	a5,a5,0x3
    80002744:	97ba                	add	a5,a5,a4
    80002746:	0007b023          	sd	zero,0(a5)
    for(int i = 0; i < 16; i++) {
    8000274a:	fec42783          	lw	a5,-20(s0)
    8000274e:	2785                	addw	a5,a5,1
    80002750:	fef42623          	sw	a5,-20(s0)
    80002754:	fec42783          	lw	a5,-20(s0)
    80002758:	0007871b          	sext.w	a4,a5
    8000275c:	47bd                	li	a5,15
    8000275e:	fce7d2e3          	bge	a5,a4,80002722 <trap_init+0x1e>
    w_stvec((uint64)kernelvec);
    80002762:	00001797          	auipc	a5,0x1
    80002766:	ade78793          	add	a5,a5,-1314 # 80003240 <kernelvec>
    8000276a:	853e                	mv	a0,a5
    8000276c:	00000097          	auipc	ra,0x0
    80002770:	f7e080e7          	jalr	-130(ra) # 800026ea <w_stvec>
    printf("Set stvec to %p\n", (void*)kernelvec);
    80002774:	00001597          	auipc	a1,0x1
    80002778:	acc58593          	add	a1,a1,-1332 # 80003240 <kernelvec>
    8000277c:	00004517          	auipc	a0,0x4
    80002780:	89c50513          	add	a0,a0,-1892 # 80006018 <etext+0x1018>
    80002784:	fffff097          	auipc	ra,0xfffff
    80002788:	a6e080e7          	jalr	-1426(ra) # 800011f2 <printf>
    w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    8000278c:	00000097          	auipc	ra,0x0
    80002790:	ec2080e7          	jalr	-318(ra) # 8000264e <r_sie>
    80002794:	87aa                	mv	a5,a0
    80002796:	2227e793          	or	a5,a5,546
    8000279a:	853e                	mv	a0,a5
    8000279c:	00000097          	auipc	ra,0x0
    800027a0:	ecc080e7          	jalr	-308(ra) # 80002668 <w_sie>
    w_sstatus(r_sstatus() | SSTATUS_SIE);
    800027a4:	00000097          	auipc	ra,0x0
    800027a8:	e76080e7          	jalr	-394(ra) # 8000261a <r_sstatus>
    800027ac:	87aa                	mv	a5,a0
    800027ae:	0027e793          	or	a5,a5,2
    800027b2:	853e                	mv	a0,a5
    800027b4:	00000097          	auipc	ra,0x0
    800027b8:	e80080e7          	jalr	-384(ra) # 80002634 <w_sstatus>
    printf("Trap system initialized\n");
    800027bc:	00004517          	auipc	a0,0x4
    800027c0:	87450513          	add	a0,a0,-1932 # 80006030 <etext+0x1030>
    800027c4:	fffff097          	auipc	ra,0xfffff
    800027c8:	a2e080e7          	jalr	-1490(ra) # 800011f2 <printf>
}
    800027cc:	0001                	nop
    800027ce:	60e2                	ld	ra,24(sp)
    800027d0:	6442                	ld	s0,16(sp)
    800027d2:	6105                	add	sp,sp,32
    800027d4:	8082                	ret

00000000800027d6 <register_interrupt>:
{
    800027d6:	1101                	add	sp,sp,-32
    800027d8:	ec06                	sd	ra,24(sp)
    800027da:	e822                	sd	s0,16(sp)
    800027dc:	1000                	add	s0,sp,32
    800027de:	87aa                	mv	a5,a0
    800027e0:	feb43023          	sd	a1,-32(s0)
    800027e4:	fef42623          	sw	a5,-20(s0)
    if(irq < 0 || irq >= 16) {
    800027e8:	fec42783          	lw	a5,-20(s0)
    800027ec:	2781                	sext.w	a5,a5
    800027ee:	0007c963          	bltz	a5,80002800 <register_interrupt+0x2a>
    800027f2:	fec42783          	lw	a5,-20(s0)
    800027f6:	0007871b          	sext.w	a4,a5
    800027fa:	47bd                	li	a5,15
    800027fc:	00e7de63          	bge	a5,a4,80002818 <register_interrupt+0x42>
        printf("register_interrupt: invalid IRQ %d\n", irq);
    80002800:	fec42783          	lw	a5,-20(s0)
    80002804:	85be                	mv	a1,a5
    80002806:	00004517          	auipc	a0,0x4
    8000280a:	84a50513          	add	a0,a0,-1974 # 80006050 <etext+0x1050>
    8000280e:	fffff097          	auipc	ra,0xfffff
    80002812:	9e4080e7          	jalr	-1564(ra) # 800011f2 <printf>
        return;
    80002816:	a03d                	j	80002844 <register_interrupt+0x6e>
    interrupt_handlers[irq] = handler;
    80002818:	0000a717          	auipc	a4,0xa
    8000281c:	8a870713          	add	a4,a4,-1880 # 8000c0c0 <interrupt_handlers>
    80002820:	fec42783          	lw	a5,-20(s0)
    80002824:	078e                	sll	a5,a5,0x3
    80002826:	97ba                	add	a5,a5,a4
    80002828:	fe043703          	ld	a4,-32(s0)
    8000282c:	e398                	sd	a4,0(a5)
    printf("Registered handler for IRQ %d\n", irq);
    8000282e:	fec42783          	lw	a5,-20(s0)
    80002832:	85be                	mv	a1,a5
    80002834:	00004517          	auipc	a0,0x4
    80002838:	84450513          	add	a0,a0,-1980 # 80006078 <etext+0x1078>
    8000283c:	fffff097          	auipc	ra,0xfffff
    80002840:	9b6080e7          	jalr	-1610(ra) # 800011f2 <printf>
}
    80002844:	60e2                	ld	ra,24(sp)
    80002846:	6442                	ld	s0,16(sp)
    80002848:	6105                	add	sp,sp,32
    8000284a:	8082                	ret

000000008000284c <devintr>:
{
    8000284c:	1101                	add	sp,sp,-32
    8000284e:	ec06                	sd	ra,24(sp)
    80002850:	e822                	sd	s0,16(sp)
    80002852:	1000                	add	s0,sp,32
    uint64 scause = r_scause();
    80002854:	00000097          	auipc	ra,0x0
    80002858:	e62080e7          	jalr	-414(ra) # 800026b6 <r_scause>
    8000285c:	fea43423          	sd	a0,-24(s0)
    if((scause & 0x8000000000000000L) == 0) {
    80002860:	fe843783          	ld	a5,-24(s0)
    80002864:	0007c463          	bltz	a5,8000286c <devintr+0x20>
        return 0;
    80002868:	4781                	li	a5,0
    8000286a:	a8e5                	j	80002962 <devintr+0x116>
    scause = scause & 0xff;
    8000286c:	fe843783          	ld	a5,-24(s0)
    80002870:	0ff7f793          	zext.b	a5,a5
    80002874:	fef43423          	sd	a5,-24(s0)
    if(scause == IRQ_S_TIMER) {
    80002878:	fe843703          	ld	a4,-24(s0)
    8000287c:	4795                	li	a5,5
    8000287e:	02f71c63          	bne	a4,a5,800028b6 <devintr+0x6a>
        interrupt_counts[IRQ_S_TIMER]++;
    80002882:	00009797          	auipc	a5,0x9
    80002886:	7b678793          	add	a5,a5,1974 # 8000c038 <interrupt_counts>
    8000288a:	779c                	ld	a5,40(a5)
    8000288c:	00178713          	add	a4,a5,1
    80002890:	00009797          	auipc	a5,0x9
    80002894:	7a878793          	add	a5,a5,1960 # 8000c038 <interrupt_counts>
    80002898:	f798                	sd	a4,40(a5)
        if(interrupt_handlers[IRQ_S_TIMER]) {
    8000289a:	0000a797          	auipc	a5,0xa
    8000289e:	82678793          	add	a5,a5,-2010 # 8000c0c0 <interrupt_handlers>
    800028a2:	779c                	ld	a5,40(a5)
    800028a4:	c799                	beqz	a5,800028b2 <devintr+0x66>
            interrupt_handlers[IRQ_S_TIMER]();
    800028a6:	0000a797          	auipc	a5,0xa
    800028aa:	81a78793          	add	a5,a5,-2022 # 8000c0c0 <interrupt_handlers>
    800028ae:	779c                	ld	a5,40(a5)
    800028b0:	9782                	jalr	a5
        return 1;
    800028b2:	4785                	li	a5,1
    800028b4:	a07d                	j	80002962 <devintr+0x116>
    } else if(scause == IRQ_S_SOFT) {
    800028b6:	fe843703          	ld	a4,-24(s0)
    800028ba:	4785                	li	a5,1
    800028bc:	06f71363          	bne	a4,a5,80002922 <devintr+0xd6>
        interrupt_counts[IRQ_S_SOFT]++;
    800028c0:	00009797          	auipc	a5,0x9
    800028c4:	77878793          	add	a5,a5,1912 # 8000c038 <interrupt_counts>
    800028c8:	679c                	ld	a5,8(a5)
    800028ca:	00178713          	add	a4,a5,1
    800028ce:	00009797          	auipc	a5,0x9
    800028d2:	76a78793          	add	a5,a5,1898 # 8000c038 <interrupt_counts>
    800028d6:	e798                	sd	a4,8(a5)
        w_sip(r_sip() & ~2);
    800028d8:	00000097          	auipc	ra,0x0
    800028dc:	daa080e7          	jalr	-598(ra) # 80002682 <r_sip>
    800028e0:	87aa                	mv	a5,a0
    800028e2:	9bf5                	and	a5,a5,-3
    800028e4:	853e                	mv	a0,a5
    800028e6:	00000097          	auipc	ra,0x0
    800028ea:	db6080e7          	jalr	-586(ra) # 8000269c <w_sip>
        if(interrupt_handlers[IRQ_S_TIMER]) {
    800028ee:	00009797          	auipc	a5,0x9
    800028f2:	7d278793          	add	a5,a5,2002 # 8000c0c0 <interrupt_handlers>
    800028f6:	779c                	ld	a5,40(a5)
    800028f8:	c39d                	beqz	a5,8000291e <devintr+0xd2>
            interrupt_handlers[IRQ_S_TIMER]();
    800028fa:	00009797          	auipc	a5,0x9
    800028fe:	7c678793          	add	a5,a5,1990 # 8000c0c0 <interrupt_handlers>
    80002902:	779c                	ld	a5,40(a5)
    80002904:	9782                	jalr	a5
            interrupt_counts[IRQ_S_TIMER]++;  // 也统计为时钟中断
    80002906:	00009797          	auipc	a5,0x9
    8000290a:	73278793          	add	a5,a5,1842 # 8000c038 <interrupt_counts>
    8000290e:	779c                	ld	a5,40(a5)
    80002910:	00178713          	add	a4,a5,1
    80002914:	00009797          	auipc	a5,0x9
    80002918:	72478793          	add	a5,a5,1828 # 8000c038 <interrupt_counts>
    8000291c:	f798                	sd	a4,40(a5)
        return 1;
    8000291e:	4785                	li	a5,1
    80002920:	a089                	j	80002962 <devintr+0x116>
    } else if(scause == IRQ_S_EXT) {
    80002922:	fe843703          	ld	a4,-24(s0)
    80002926:	47a5                	li	a5,9
    80002928:	02f71c63          	bne	a4,a5,80002960 <devintr+0x114>
        interrupt_counts[IRQ_S_EXT]++;
    8000292c:	00009797          	auipc	a5,0x9
    80002930:	70c78793          	add	a5,a5,1804 # 8000c038 <interrupt_counts>
    80002934:	67bc                	ld	a5,72(a5)
    80002936:	00178713          	add	a4,a5,1
    8000293a:	00009797          	auipc	a5,0x9
    8000293e:	6fe78793          	add	a5,a5,1790 # 8000c038 <interrupt_counts>
    80002942:	e7b8                	sd	a4,72(a5)
        if(interrupt_handlers[IRQ_S_EXT]) {
    80002944:	00009797          	auipc	a5,0x9
    80002948:	77c78793          	add	a5,a5,1916 # 8000c0c0 <interrupt_handlers>
    8000294c:	67bc                	ld	a5,72(a5)
    8000294e:	c799                	beqz	a5,8000295c <devintr+0x110>
            interrupt_handlers[IRQ_S_EXT]();
    80002950:	00009797          	auipc	a5,0x9
    80002954:	77078793          	add	a5,a5,1904 # 8000c0c0 <interrupt_handlers>
    80002958:	67bc                	ld	a5,72(a5)
    8000295a:	9782                	jalr	a5
        return 1;
    8000295c:	4785                	li	a5,1
    8000295e:	a011                	j	80002962 <devintr+0x116>
    return 0;
    80002960:	4781                	li	a5,0
}
    80002962:	853e                	mv	a0,a5
    80002964:	60e2                	ld	ra,24(sp)
    80002966:	6442                	ld	s0,16(sp)
    80002968:	6105                	add	sp,sp,32
    8000296a:	8082                	ret

000000008000296c <handle_syscall>:
void handle_syscall(struct trapframe *tf) {
    8000296c:	1101                	add	sp,sp,-32
    8000296e:	ec06                	sd	ra,24(sp)
    80002970:	e822                	sd	s0,16(sp)
    80002972:	1000                	add	s0,sp,32
    80002974:	fea43423          	sd	a0,-24(s0)
    printf("\n=== System Call ===\n");
    80002978:	00003517          	auipc	a0,0x3
    8000297c:	72050513          	add	a0,a0,1824 # 80006098 <etext+0x1098>
    80002980:	fffff097          	auipc	ra,0xfffff
    80002984:	872080e7          	jalr	-1934(ra) # 800011f2 <printf>
    printf("syscall number: %d (in a7)\n", (int)tf->a7);
    80002988:	fe843783          	ld	a5,-24(s0)
    8000298c:	63dc                	ld	a5,128(a5)
    8000298e:	2781                	sext.w	a5,a5
    80002990:	85be                	mv	a1,a5
    80002992:	00003517          	auipc	a0,0x3
    80002996:	71e50513          	add	a0,a0,1822 # 800060b0 <etext+0x10b0>
    8000299a:	fffff097          	auipc	ra,0xfffff
    8000299e:	858080e7          	jalr	-1960(ra) # 800011f2 <printf>
    printf("arguments: a0=%p, a1=%p\n", (void*)tf->a0, (void*)tf->a1);
    800029a2:	fe843783          	ld	a5,-24(s0)
    800029a6:	67bc                	ld	a5,72(a5)
    800029a8:	873e                	mv	a4,a5
    800029aa:	fe843783          	ld	a5,-24(s0)
    800029ae:	6bbc                	ld	a5,80(a5)
    800029b0:	863e                	mv	a2,a5
    800029b2:	85ba                	mv	a1,a4
    800029b4:	00003517          	auipc	a0,0x3
    800029b8:	71c50513          	add	a0,a0,1820 # 800060d0 <etext+0x10d0>
    800029bc:	fffff097          	auipc	ra,0xfffff
    800029c0:	836080e7          	jalr	-1994(ra) # 800011f2 <printf>
    printf("called from: %p\n", (void*)tf->sepc);
    800029c4:	fe843783          	ld	a5,-24(s0)
    800029c8:	7ffc                	ld	a5,248(a5)
    800029ca:	85be                	mv	a1,a5
    800029cc:	00003517          	auipc	a0,0x3
    800029d0:	72450513          	add	a0,a0,1828 # 800060f0 <etext+0x10f0>
    800029d4:	fffff097          	auipc	ra,0xfffff
    800029d8:	81e080e7          	jalr	-2018(ra) # 800011f2 <printf>
    // 跳过 ecall 指令（4字节）
    tf->sepc += 4;
    800029dc:	fe843783          	ld	a5,-24(s0)
    800029e0:	7ffc                	ld	a5,248(a5)
    800029e2:	00478713          	add	a4,a5,4
    800029e6:	fe843783          	ld	a5,-24(s0)
    800029ea:	fff8                	sd	a4,248(a5)
    
    printf("System call handled, returning to %p\n", (void*)tf->sepc);
    800029ec:	fe843783          	ld	a5,-24(s0)
    800029f0:	7ffc                	ld	a5,248(a5)
    800029f2:	85be                	mv	a1,a5
    800029f4:	00003517          	auipc	a0,0x3
    800029f8:	71450513          	add	a0,a0,1812 # 80006108 <etext+0x1108>
    800029fc:	ffffe097          	auipc	ra,0xffffe
    80002a00:	7f6080e7          	jalr	2038(ra) # 800011f2 <printf>
}
    80002a04:	0001                	nop
    80002a06:	60e2                	ld	ra,24(sp)
    80002a08:	6442                	ld	s0,16(sp)
    80002a0a:	6105                	add	sp,sp,32
    80002a0c:	8082                	ret

0000000080002a0e <handle_instruction_page_fault>:

// ==================== 指令页故障处理 ====================
void handle_instruction_page_fault(struct trapframe *tf) {
    80002a0e:	7179                	add	sp,sp,-48
    80002a10:	f406                	sd	ra,40(sp)
    80002a12:	f022                	sd	s0,32(sp)
    80002a14:	1800                	add	s0,sp,48
    80002a16:	fca43c23          	sd	a0,-40(s0)
    uint64 fault_addr = r_stval();  // 故障地址
    80002a1a:	00000097          	auipc	ra,0x0
    80002a1e:	cb6080e7          	jalr	-842(ra) # 800026d0 <r_stval>
    80002a22:	fea43423          	sd	a0,-24(s0)
    
    printf("\n=== Instruction Page Fault ===\n");
    80002a26:	00003517          	auipc	a0,0x3
    80002a2a:	70a50513          	add	a0,a0,1802 # 80006130 <etext+0x1130>
    80002a2e:	ffffe097          	auipc	ra,0xffffe
    80002a32:	7c4080e7          	jalr	1988(ra) # 800011f2 <printf>
    printf("Fault address: %p\n", (void*)fault_addr);
    80002a36:	fe843783          	ld	a5,-24(s0)
    80002a3a:	85be                	mv	a1,a5
    80002a3c:	00003517          	auipc	a0,0x3
    80002a40:	71c50513          	add	a0,a0,1820 # 80006158 <etext+0x1158>
    80002a44:	ffffe097          	auipc	ra,0xffffe
    80002a48:	7ae080e7          	jalr	1966(ra) # 800011f2 <printf>
    printf("PC: %p\n", (void*)tf->sepc);
    80002a4c:	fd843783          	ld	a5,-40(s0)
    80002a50:	7ffc                	ld	a5,248(a5)
    80002a52:	85be                	mv	a1,a5
    80002a54:	00003517          	auipc	a0,0x3
    80002a58:	71c50513          	add	a0,a0,1820 # 80006170 <etext+0x1170>
    80002a5c:	ffffe097          	auipc	ra,0xffffe
    80002a60:	796080e7          	jalr	1942(ra) # 800011f2 <printf>
    
    // 简单处理：如果是内核地址，panic
    if(fault_addr >= KERNBASE) {
    80002a64:	fe843703          	ld	a4,-24(s0)
    80002a68:	800007b7          	lui	a5,0x80000
    80002a6c:	fff7c793          	not	a5,a5
    80002a70:	00e7fa63          	bgeu	a5,a4,80002a84 <handle_instruction_page_fault+0x76>
        panic("Instruction page fault in kernel space");
    80002a74:	00003517          	auipc	a0,0x3
    80002a78:	70450513          	add	a0,a0,1796 # 80006178 <etext+0x1178>
    80002a7c:	fffff097          	auipc	ra,0xfffff
    80002a80:	b1c080e7          	jalr	-1252(ra) # 80001598 <panic>
    }
    
    // 这里可以实现按需分页等功能
    printf("TODO: Implement demand paging for instruction fault\n");
    80002a84:	00003517          	auipc	a0,0x3
    80002a88:	71c50513          	add	a0,a0,1820 # 800061a0 <etext+0x11a0>
    80002a8c:	ffffe097          	auipc	ra,0xffffe
    80002a90:	766080e7          	jalr	1894(ra) # 800011f2 <printf>
    panic("Instruction page fault not handled");
    80002a94:	00003517          	auipc	a0,0x3
    80002a98:	74450513          	add	a0,a0,1860 # 800061d8 <etext+0x11d8>
    80002a9c:	fffff097          	auipc	ra,0xfffff
    80002aa0:	afc080e7          	jalr	-1284(ra) # 80001598 <panic>
}
    80002aa4:	0001                	nop
    80002aa6:	70a2                	ld	ra,40(sp)
    80002aa8:	7402                	ld	s0,32(sp)
    80002aaa:	6145                	add	sp,sp,48
    80002aac:	8082                	ret

0000000080002aae <handle_load_page_fault>:

// ==================== 加载页故障处理 ====================
void handle_load_page_fault(struct trapframe *tf) {
    80002aae:	7179                	add	sp,sp,-48
    80002ab0:	f406                	sd	ra,40(sp)
    80002ab2:	f022                	sd	s0,32(sp)
    80002ab4:	1800                	add	s0,sp,48
    80002ab6:	fca43c23          	sd	a0,-40(s0)
    uint64 fault_addr = r_stval();  // 故障地址
    80002aba:	00000097          	auipc	ra,0x0
    80002abe:	c16080e7          	jalr	-1002(ra) # 800026d0 <r_stval>
    80002ac2:	fea43423          	sd	a0,-24(s0)
    
    printf("\n=== Load Page Fault ===\n");
    80002ac6:	00003517          	auipc	a0,0x3
    80002aca:	73a50513          	add	a0,a0,1850 # 80006200 <etext+0x1200>
    80002ace:	ffffe097          	auipc	ra,0xffffe
    80002ad2:	724080e7          	jalr	1828(ra) # 800011f2 <printf>
    printf("Fault address: %p\n", (void*)fault_addr);
    80002ad6:	fe843783          	ld	a5,-24(s0)
    80002ada:	85be                	mv	a1,a5
    80002adc:	00003517          	auipc	a0,0x3
    80002ae0:	67c50513          	add	a0,a0,1660 # 80006158 <etext+0x1158>
    80002ae4:	ffffe097          	auipc	ra,0xffffe
    80002ae8:	70e080e7          	jalr	1806(ra) # 800011f2 <printf>
    printf("PC: %p\n", (void*)tf->sepc);
    80002aec:	fd843783          	ld	a5,-40(s0)
    80002af0:	7ffc                	ld	a5,248(a5)
    80002af2:	85be                	mv	a1,a5
    80002af4:	00003517          	auipc	a0,0x3
    80002af8:	67c50513          	add	a0,a0,1660 # 80006170 <etext+0x1170>
    80002afc:	ffffe097          	auipc	ra,0xffffe
    80002b00:	6f6080e7          	jalr	1782(ra) # 800011f2 <printf>
    printf("Tried to read from unmapped address\n");
    80002b04:	00003517          	auipc	a0,0x3
    80002b08:	71c50513          	add	a0,a0,1820 # 80006220 <etext+0x1220>
    80002b0c:	ffffe097          	auipc	ra,0xffffe
    80002b10:	6e6080e7          	jalr	1766(ra) # 800011f2 <printf>
    
    // 简单处理：panic
    panic("Load page fault");
    80002b14:	00003517          	auipc	a0,0x3
    80002b18:	73450513          	add	a0,a0,1844 # 80006248 <etext+0x1248>
    80002b1c:	fffff097          	auipc	ra,0xfffff
    80002b20:	a7c080e7          	jalr	-1412(ra) # 80001598 <panic>
}
    80002b24:	0001                	nop
    80002b26:	70a2                	ld	ra,40(sp)
    80002b28:	7402                	ld	s0,32(sp)
    80002b2a:	6145                	add	sp,sp,48
    80002b2c:	8082                	ret

0000000080002b2e <handle_store_page_fault>:

// ==================== 存储页故障处理 ====================
void handle_store_page_fault(struct trapframe *tf) {
    80002b2e:	7179                	add	sp,sp,-48
    80002b30:	f406                	sd	ra,40(sp)
    80002b32:	f022                	sd	s0,32(sp)
    80002b34:	1800                	add	s0,sp,48
    80002b36:	fca43c23          	sd	a0,-40(s0)
    uint64 fault_addr = r_stval();  // 故障地址
    80002b3a:	00000097          	auipc	ra,0x0
    80002b3e:	b96080e7          	jalr	-1130(ra) # 800026d0 <r_stval>
    80002b42:	fea43423          	sd	a0,-24(s0)
    
    printf("\n=== Store Page Fault ===\n");
    80002b46:	00003517          	auipc	a0,0x3
    80002b4a:	71250513          	add	a0,a0,1810 # 80006258 <etext+0x1258>
    80002b4e:	ffffe097          	auipc	ra,0xffffe
    80002b52:	6a4080e7          	jalr	1700(ra) # 800011f2 <printf>
    printf("Fault address: %p\n", (void*)fault_addr);
    80002b56:	fe843783          	ld	a5,-24(s0)
    80002b5a:	85be                	mv	a1,a5
    80002b5c:	00003517          	auipc	a0,0x3
    80002b60:	5fc50513          	add	a0,a0,1532 # 80006158 <etext+0x1158>
    80002b64:	ffffe097          	auipc	ra,0xffffe
    80002b68:	68e080e7          	jalr	1678(ra) # 800011f2 <printf>
    printf("PC: %p\n", (void*)tf->sepc);
    80002b6c:	fd843783          	ld	a5,-40(s0)
    80002b70:	7ffc                	ld	a5,248(a5)
    80002b72:	85be                	mv	a1,a5
    80002b74:	00003517          	auipc	a0,0x3
    80002b78:	5fc50513          	add	a0,a0,1532 # 80006170 <etext+0x1170>
    80002b7c:	ffffe097          	auipc	ra,0xffffe
    80002b80:	676080e7          	jalr	1654(ra) # 800011f2 <printf>
    printf("Tried to write to unmapped or read-only address\n");
    80002b84:	00003517          	auipc	a0,0x3
    80002b88:	6f450513          	add	a0,a0,1780 # 80006278 <etext+0x1278>
    80002b8c:	ffffe097          	auipc	ra,0xffffe
    80002b90:	666080e7          	jalr	1638(ra) # 800011f2 <printf>
    
    // 检查是否写入只读代码段
    if(fault_addr >= KERNBASE && fault_addr < (uint64)etext) {
    80002b94:	fe843703          	ld	a4,-24(s0)
    80002b98:	800007b7          	lui	a5,0x80000
    80002b9c:	fff7c793          	not	a5,a5
    80002ba0:	02e7f263          	bgeu	a5,a4,80002bc4 <handle_store_page_fault+0x96>
    80002ba4:	00002797          	auipc	a5,0x2
    80002ba8:	45c78793          	add	a5,a5,1116 # 80005000 <etext>
    80002bac:	fe843703          	ld	a4,-24(s0)
    80002bb0:	00f77a63          	bgeu	a4,a5,80002bc4 <handle_store_page_fault+0x96>
        printf("Attempted to write to read-only kernel text segment!\n");
    80002bb4:	00003517          	auipc	a0,0x3
    80002bb8:	6fc50513          	add	a0,a0,1788 # 800062b0 <etext+0x12b0>
    80002bbc:	ffffe097          	auipc	ra,0xffffe
    80002bc0:	636080e7          	jalr	1590(ra) # 800011f2 <printf>
    }
    
    panic("Store page fault");
    80002bc4:	00003517          	auipc	a0,0x3
    80002bc8:	72450513          	add	a0,a0,1828 # 800062e8 <etext+0x12e8>
    80002bcc:	fffff097          	auipc	ra,0xfffff
    80002bd0:	9cc080e7          	jalr	-1588(ra) # 80001598 <panic>
}
    80002bd4:	0001                	nop
    80002bd6:	70a2                	ld	ra,40(sp)
    80002bd8:	7402                	ld	s0,32(sp)
    80002bda:	6145                	add	sp,sp,48
    80002bdc:	8082                	ret

0000000080002bde <handle_exception>:

// ==================== 统一异常处理入口 ====================
void handle_exception(struct trapframe *tf) {
    80002bde:	7139                	add	sp,sp,-64
    80002be0:	fc06                	sd	ra,56(sp)
    80002be2:	f822                	sd	s0,48(sp)
    80002be4:	f426                	sd	s1,40(sp)
    80002be6:	0080                	add	s0,sp,64
    80002be8:	fca43423          	sd	a0,-56(s0)
    uint64 cause = r_scause();
    80002bec:	00000097          	auipc	ra,0x0
    80002bf0:	aca080e7          	jalr	-1334(ra) # 800026b6 <r_scause>
    80002bf4:	fca43c23          	sd	a0,-40(s0)
    
    printf("\n[Exception Handler] cause=%d (%s)\n", 
    80002bf8:	fd843783          	ld	a5,-40(s0)
    80002bfc:	0007849b          	sext.w	s1,a5
    80002c00:	fd843503          	ld	a0,-40(s0)
    80002c04:	00000097          	auipc	ra,0x0
    80002c08:	2fa080e7          	jalr	762(ra) # 80002efe <trap_cause_name>
    80002c0c:	87aa                	mv	a5,a0
    80002c0e:	863e                	mv	a2,a5
    80002c10:	85a6                	mv	a1,s1
    80002c12:	00003517          	auipc	a0,0x3
    80002c16:	6ee50513          	add	a0,a0,1774 # 80006300 <etext+0x1300>
    80002c1a:	ffffe097          	auipc	ra,0xffffe
    80002c1e:	5d8080e7          	jalr	1496(ra) # 800011f2 <printf>
           (int)cause, trap_cause_name(cause));
    
    switch(cause) {
    80002c22:	fd843703          	ld	a4,-40(s0)
    80002c26:	47bd                	li	a5,15
    80002c28:	1ce7e163          	bltu	a5,a4,80002dea <handle_exception+0x20c>
    80002c2c:	fd843783          	ld	a5,-40(s0)
    80002c30:	00279713          	sll	a4,a5,0x2
    80002c34:	00004797          	auipc	a5,0x4
    80002c38:	89878793          	add	a5,a5,-1896 # 800064cc <etext+0x14cc>
    80002c3c:	97ba                	add	a5,a5,a4
    80002c3e:	439c                	lw	a5,0(a5)
    80002c40:	0007871b          	sext.w	a4,a5
    80002c44:	00004797          	auipc	a5,0x4
    80002c48:	88878793          	add	a5,a5,-1912 # 800064cc <etext+0x14cc>
    80002c4c:	97ba                	add	a5,a5,a4
    80002c4e:	8782                	jr	a5
        case CAUSE_USER_ECALL:           // 8: 用户模式系统调用
        case CAUSE_SUPERVISOR_ECALL:     // 9: 监督模式系统调用
            handle_syscall(tf);
    80002c50:	fc843503          	ld	a0,-56(s0)
    80002c54:	00000097          	auipc	ra,0x0
    80002c58:	d18080e7          	jalr	-744(ra) # 8000296c <handle_syscall>
            break;
    80002c5c:	aaf5                	j	80002e58 <handle_exception+0x27a>
            
        case CAUSE_FETCH_PAGE_FAULT:     // 12: 指令页故障
            handle_instruction_page_fault(tf);
    80002c5e:	fc843503          	ld	a0,-56(s0)
    80002c62:	00000097          	auipc	ra,0x0
    80002c66:	dac080e7          	jalr	-596(ra) # 80002a0e <handle_instruction_page_fault>
            break;
    80002c6a:	a2fd                	j	80002e58 <handle_exception+0x27a>
            
        case CAUSE_LOAD_PAGE_FAULT:      // 13: 加载页故障
            handle_load_page_fault(tf);
    80002c6c:	fc843503          	ld	a0,-56(s0)
    80002c70:	00000097          	auipc	ra,0x0
    80002c74:	e3e080e7          	jalr	-450(ra) # 80002aae <handle_load_page_fault>
            break;
    80002c78:	a2c5                	j	80002e58 <handle_exception+0x27a>
            
        case CAUSE_STORE_PAGE_FAULT:     // 15: 存储页故障
            handle_store_page_fault(tf);
    80002c7a:	fc843503          	ld	a0,-56(s0)
    80002c7e:	00000097          	auipc	ra,0x0
    80002c82:	eb0080e7          	jalr	-336(ra) # 80002b2e <handle_store_page_fault>
            break;
    80002c86:	aac9                	j	80002e58 <handle_exception+0x27a>
            
        case CAUSE_ILLEGAL_INSTRUCTION:  // 2: 非法指令
            printf("\n=== Illegal Instruction ===\n");
    80002c88:	00003517          	auipc	a0,0x3
    80002c8c:	6a050513          	add	a0,a0,1696 # 80006328 <etext+0x1328>
    80002c90:	ffffe097          	auipc	ra,0xffffe
    80002c94:	562080e7          	jalr	1378(ra) # 800011f2 <printf>
            printf("PC: %p\n", (void*)tf->sepc);
    80002c98:	fc843783          	ld	a5,-56(s0)
    80002c9c:	7ffc                	ld	a5,248(a5)
    80002c9e:	85be                	mv	a1,a5
    80002ca0:	00003517          	auipc	a0,0x3
    80002ca4:	4d050513          	add	a0,a0,1232 # 80006170 <etext+0x1170>
    80002ca8:	ffffe097          	auipc	ra,0xffffe
    80002cac:	54a080e7          	jalr	1354(ra) # 800011f2 <printf>
            printf("Instruction value: %p\n", (void*)r_stval());
    80002cb0:	00000097          	auipc	ra,0x0
    80002cb4:	a20080e7          	jalr	-1504(ra) # 800026d0 <r_stval>
    80002cb8:	87aa                	mv	a5,a0
    80002cba:	85be                	mv	a1,a5
    80002cbc:	00003517          	auipc	a0,0x3
    80002cc0:	68c50513          	add	a0,a0,1676 # 80006348 <etext+0x1348>
    80002cc4:	ffffe097          	auipc	ra,0xffffe
    80002cc8:	52e080e7          	jalr	1326(ra) # 800011f2 <printf>
            panic("Illegal instruction");
    80002ccc:	00003517          	auipc	a0,0x3
    80002cd0:	69450513          	add	a0,a0,1684 # 80006360 <etext+0x1360>
    80002cd4:	fffff097          	auipc	ra,0xfffff
    80002cd8:	8c4080e7          	jalr	-1852(ra) # 80001598 <panic>
            break;
    80002cdc:	aab5                	j	80002e58 <handle_exception+0x27a>
            
        case CAUSE_BREAKPOINT:           // 3: 断点
            printf("\n=== Breakpoint ===\n");
    80002cde:	00003517          	auipc	a0,0x3
    80002ce2:	69a50513          	add	a0,a0,1690 # 80006378 <etext+0x1378>
    80002ce6:	ffffe097          	auipc	ra,0xffffe
    80002cea:	50c080e7          	jalr	1292(ra) # 800011f2 <printf>
            printf("PC: %p\n", (void*)tf->sepc);
    80002cee:	fc843783          	ld	a5,-56(s0)
    80002cf2:	7ffc                	ld	a5,248(a5)
    80002cf4:	85be                	mv	a1,a5
    80002cf6:	00003517          	auipc	a0,0x3
    80002cfa:	47a50513          	add	a0,a0,1146 # 80006170 <etext+0x1170>
    80002cfe:	ffffe097          	auipc	ra,0xffffe
    80002d02:	4f4080e7          	jalr	1268(ra) # 800011f2 <printf>
            // 跳过 ebreak 指令（2字节压缩指令）
            tf->sepc += 2;
    80002d06:	fc843783          	ld	a5,-56(s0)
    80002d0a:	7ffc                	ld	a5,248(a5)
    80002d0c:	00278713          	add	a4,a5,2
    80002d10:	fc843783          	ld	a5,-56(s0)
    80002d14:	fff8                	sd	a4,248(a5)
            printf("Breakpoint handled, continuing from %p\n", (void*)tf->sepc);
    80002d16:	fc843783          	ld	a5,-56(s0)
    80002d1a:	7ffc                	ld	a5,248(a5)
    80002d1c:	85be                	mv	a1,a5
    80002d1e:	00003517          	auipc	a0,0x3
    80002d22:	67250513          	add	a0,a0,1650 # 80006390 <etext+0x1390>
    80002d26:	ffffe097          	auipc	ra,0xffffe
    80002d2a:	4cc080e7          	jalr	1228(ra) # 800011f2 <printf>
            break;
    80002d2e:	a22d                	j	80002e58 <handle_exception+0x27a>
            
        case CAUSE_MISALIGNED_FETCH:     // 0: 指令地址未对齐
            printf("\n=== Misaligned Instruction Fetch ===\n");
    80002d30:	00003517          	auipc	a0,0x3
    80002d34:	68850513          	add	a0,a0,1672 # 800063b8 <etext+0x13b8>
    80002d38:	ffffe097          	auipc	ra,0xffffe
    80002d3c:	4ba080e7          	jalr	1210(ra) # 800011f2 <printf>
            printf("Address: %p\n", (void*)r_stval());
    80002d40:	00000097          	auipc	ra,0x0
    80002d44:	990080e7          	jalr	-1648(ra) # 800026d0 <r_stval>
    80002d48:	87aa                	mv	a5,a0
    80002d4a:	85be                	mv	a1,a5
    80002d4c:	00003517          	auipc	a0,0x3
    80002d50:	69450513          	add	a0,a0,1684 # 800063e0 <etext+0x13e0>
    80002d54:	ffffe097          	auipc	ra,0xffffe
    80002d58:	49e080e7          	jalr	1182(ra) # 800011f2 <printf>
            panic("Misaligned instruction fetch");
    80002d5c:	00003517          	auipc	a0,0x3
    80002d60:	69450513          	add	a0,a0,1684 # 800063f0 <etext+0x13f0>
    80002d64:	fffff097          	auipc	ra,0xfffff
    80002d68:	834080e7          	jalr	-1996(ra) # 80001598 <panic>
            break;
    80002d6c:	a0f5                	j	80002e58 <handle_exception+0x27a>
            
        case CAUSE_MISALIGNED_LOAD:      // 4: 加载地址未对齐
            printf("\n=== Misaligned Load ===\n");
    80002d6e:	00003517          	auipc	a0,0x3
    80002d72:	6a250513          	add	a0,a0,1698 # 80006410 <etext+0x1410>
    80002d76:	ffffe097          	auipc	ra,0xffffe
    80002d7a:	47c080e7          	jalr	1148(ra) # 800011f2 <printf>
            printf("Address: %p\n", (void*)r_stval());
    80002d7e:	00000097          	auipc	ra,0x0
    80002d82:	952080e7          	jalr	-1710(ra) # 800026d0 <r_stval>
    80002d86:	87aa                	mv	a5,a0
    80002d88:	85be                	mv	a1,a5
    80002d8a:	00003517          	auipc	a0,0x3
    80002d8e:	65650513          	add	a0,a0,1622 # 800063e0 <etext+0x13e0>
    80002d92:	ffffe097          	auipc	ra,0xffffe
    80002d96:	460080e7          	jalr	1120(ra) # 800011f2 <printf>
            panic("Misaligned load");
    80002d9a:	00003517          	auipc	a0,0x3
    80002d9e:	69650513          	add	a0,a0,1686 # 80006430 <etext+0x1430>
    80002da2:	ffffe097          	auipc	ra,0xffffe
    80002da6:	7f6080e7          	jalr	2038(ra) # 80001598 <panic>
            break;
    80002daa:	a07d                	j	80002e58 <handle_exception+0x27a>
            
        case CAUSE_MISALIGNED_STORE:     // 6: 存储地址未对齐
            printf("\n=== Misaligned Store ===\n");
    80002dac:	00003517          	auipc	a0,0x3
    80002db0:	69450513          	add	a0,a0,1684 # 80006440 <etext+0x1440>
    80002db4:	ffffe097          	auipc	ra,0xffffe
    80002db8:	43e080e7          	jalr	1086(ra) # 800011f2 <printf>
            printf("Address: %p\n", (void*)r_stval());
    80002dbc:	00000097          	auipc	ra,0x0
    80002dc0:	914080e7          	jalr	-1772(ra) # 800026d0 <r_stval>
    80002dc4:	87aa                	mv	a5,a0
    80002dc6:	85be                	mv	a1,a5
    80002dc8:	00003517          	auipc	a0,0x3
    80002dcc:	61850513          	add	a0,a0,1560 # 800063e0 <etext+0x13e0>
    80002dd0:	ffffe097          	auipc	ra,0xffffe
    80002dd4:	422080e7          	jalr	1058(ra) # 800011f2 <printf>
            panic("Misaligned store");
    80002dd8:	00003517          	auipc	a0,0x3
    80002ddc:	68850513          	add	a0,a0,1672 # 80006460 <etext+0x1460>
    80002de0:	ffffe097          	auipc	ra,0xffffe
    80002de4:	7b8080e7          	jalr	1976(ra) # 80001598 <panic>
            break;
    80002de8:	a885                	j	80002e58 <handle_exception+0x27a>
            
        default:
            printf("\n=== Unknown Exception ===\n");
    80002dea:	00003517          	auipc	a0,0x3
    80002dee:	68e50513          	add	a0,a0,1678 # 80006478 <etext+0x1478>
    80002df2:	ffffe097          	auipc	ra,0xffffe
    80002df6:	400080e7          	jalr	1024(ra) # 800011f2 <printf>
            printf("cause: %d\n", (int)cause);
    80002dfa:	fd843783          	ld	a5,-40(s0)
    80002dfe:	2781                	sext.w	a5,a5
    80002e00:	85be                	mv	a1,a5
    80002e02:	00003517          	auipc	a0,0x3
    80002e06:	69650513          	add	a0,a0,1686 # 80006498 <etext+0x1498>
    80002e0a:	ffffe097          	auipc	ra,0xffffe
    80002e0e:	3e8080e7          	jalr	1000(ra) # 800011f2 <printf>
            printf("PC: %p\n", (void*)tf->sepc);
    80002e12:	fc843783          	ld	a5,-56(s0)
    80002e16:	7ffc                	ld	a5,248(a5)
    80002e18:	85be                	mv	a1,a5
    80002e1a:	00003517          	auipc	a0,0x3
    80002e1e:	35650513          	add	a0,a0,854 # 80006170 <etext+0x1170>
    80002e22:	ffffe097          	auipc	ra,0xffffe
    80002e26:	3d0080e7          	jalr	976(ra) # 800011f2 <printf>
            printf("stval: %p\n", (void*)r_stval());
    80002e2a:	00000097          	auipc	ra,0x0
    80002e2e:	8a6080e7          	jalr	-1882(ra) # 800026d0 <r_stval>
    80002e32:	87aa                	mv	a5,a0
    80002e34:	85be                	mv	a1,a5
    80002e36:	00003517          	auipc	a0,0x3
    80002e3a:	67250513          	add	a0,a0,1650 # 800064a8 <etext+0x14a8>
    80002e3e:	ffffe097          	auipc	ra,0xffffe
    80002e42:	3b4080e7          	jalr	948(ra) # 800011f2 <printf>
            panic("Unknown exception");
    80002e46:	00003517          	auipc	a0,0x3
    80002e4a:	67250513          	add	a0,a0,1650 # 800064b8 <etext+0x14b8>
    80002e4e:	ffffe097          	auipc	ra,0xffffe
    80002e52:	74a080e7          	jalr	1866(ra) # 80001598 <panic>
    }
}
    80002e56:	0001                	nop
    80002e58:	0001                	nop
    80002e5a:	70e2                	ld	ra,56(sp)
    80002e5c:	7442                	ld	s0,48(sp)
    80002e5e:	74a2                	ld	s1,40(sp)
    80002e60:	6121                	add	sp,sp,64
    80002e62:	8082                	ret

0000000080002e64 <kerneltrap>:
// ==================== 内核态中断/异常处理入口 ====================
// 从kernelvec.S调用，此时trapframe已保存在内核栈上
// 修改 kerneltrap 函数签名
void kerneltrap(struct trapframe *tf)  // ← 添加参数
{
    80002e64:	7179                	add	sp,sp,-48
    80002e66:	f406                	sd	ra,40(sp)
    80002e68:	f022                	sd	s0,32(sp)
    80002e6a:	1800                	add	s0,sp,48
    80002e6c:	fca43c23          	sd	a0,-40(s0)
    uint64 sstatus = r_sstatus();
    80002e70:	fffff097          	auipc	ra,0xfffff
    80002e74:	7aa080e7          	jalr	1962(ra) # 8000261a <r_sstatus>
    80002e78:	fea43423          	sd	a0,-24(s0)
    
    // 安全检查
    if((sstatus & SSTATUS_SPP) == 0) {
    80002e7c:	fe843783          	ld	a5,-24(s0)
    80002e80:	1007f793          	and	a5,a5,256
    80002e84:	eb89                	bnez	a5,80002e96 <kerneltrap+0x32>
        panic("kerneltrap: not from supervisor mode");
    80002e86:	00003517          	auipc	a0,0x3
    80002e8a:	68a50513          	add	a0,a0,1674 # 80006510 <etext+0x1510>
    80002e8e:	ffffe097          	auipc	ra,0xffffe
    80002e92:	70a080e7          	jalr	1802(ra) # 80001598 <panic>
    }
    
    if(sstatus & SSTATUS_SIE) {
    80002e96:	fe843783          	ld	a5,-24(s0)
    80002e9a:	8b89                	and	a5,a5,2
    80002e9c:	cb89                	beqz	a5,80002eae <kerneltrap+0x4a>
        panic("kerneltrap: interrupts enabled");
    80002e9e:	00003517          	auipc	a0,0x3
    80002ea2:	69a50513          	add	a0,a0,1690 # 80006538 <etext+0x1538>
    80002ea6:	ffffe097          	auipc	ra,0xffffe
    80002eaa:	6f2080e7          	jalr	1778(ra) # 80001598 <panic>
    }
    
    // 处理设备中断
    int is_device_interrupt = devintr();
    80002eae:	00000097          	auipc	ra,0x0
    80002eb2:	99e080e7          	jalr	-1634(ra) # 8000284c <devintr>
    80002eb6:	87aa                	mv	a5,a0
    80002eb8:	fef42223          	sw	a5,-28(s0)
    
    if(!is_device_interrupt) {
    80002ebc:	fe442783          	lw	a5,-28(s0)
    80002ec0:	2781                	sext.w	a5,a5
    80002ec2:	e39d                	bnez	a5,80002ee8 <kerneltrap+0x84>
        // 异常处理
        exception_count++;
    80002ec4:	00009797          	auipc	a5,0x9
    80002ec8:	1f478793          	add	a5,a5,500 # 8000c0b8 <exception_count>
    80002ecc:	639c                	ld	a5,0(a5)
    80002ece:	00178713          	add	a4,a5,1
    80002ed2:	00009797          	auipc	a5,0x9
    80002ed6:	1e678793          	add	a5,a5,486 # 8000c0b8 <exception_count>
    80002eda:	e398                	sd	a4,0(a5)
        
        // 直接使用传入的 trapframe 指针（地址正确！）
        handle_exception(tf);
    80002edc:	fd843503          	ld	a0,-40(s0)
    80002ee0:	00000097          	auipc	ra,0x0
    80002ee4:	cfe080e7          	jalr	-770(ra) # 80002bde <handle_exception>
        
        // 不需要写回sepc，kernelvec会自动从栈上恢复
    }
    
    w_sstatus(sstatus);
    80002ee8:	fe843503          	ld	a0,-24(s0)
    80002eec:	fffff097          	auipc	ra,0xfffff
    80002ef0:	748080e7          	jalr	1864(ra) # 80002634 <w_sstatus>
}
    80002ef4:	0001                	nop
    80002ef6:	70a2                	ld	ra,40(sp)
    80002ef8:	7402                	ld	s0,32(sp)
    80002efa:	6145                	add	sp,sp,48
    80002efc:	8082                	ret

0000000080002efe <trap_cause_name>:
// ==================== 辅助函数：获取异常/中断原因名称 ====================
const char* trap_cause_name(uint64 cause)
{
    80002efe:	1101                	add	sp,sp,-32
    80002f00:	ec22                	sd	s0,24(sp)
    80002f02:	1000                	add	s0,sp,32
    80002f04:	fea43423          	sd	a0,-24(s0)
    // 检查是中断还是异常
    if(cause & 0x8000000000000000L) {
    80002f08:	fe843783          	ld	a5,-24(s0)
    80002f0c:	0807d263          	bgez	a5,80002f90 <trap_cause_name+0x92>
        // 中断
        cause = cause & 0xff;
    80002f10:	fe843783          	ld	a5,-24(s0)
    80002f14:	0ff7f793          	zext.b	a5,a5
    80002f18:	fef43423          	sd	a5,-24(s0)
        switch(cause) {
    80002f1c:	fe843703          	ld	a4,-24(s0)
    80002f20:	47ad                	li	a5,11
    80002f22:	06e7e263          	bltu	a5,a4,80002f86 <trap_cause_name+0x88>
    80002f26:	fe843783          	ld	a5,-24(s0)
    80002f2a:	00279713          	sll	a4,a5,0x2
    80002f2e:	00004797          	auipc	a5,0x4
    80002f32:	82a78793          	add	a5,a5,-2006 # 80006758 <etext+0x1758>
    80002f36:	97ba                	add	a5,a5,a4
    80002f38:	439c                	lw	a5,0(a5)
    80002f3a:	0007871b          	sext.w	a4,a5
    80002f3e:	00004797          	auipc	a5,0x4
    80002f42:	81a78793          	add	a5,a5,-2022 # 80006758 <etext+0x1758>
    80002f46:	97ba                	add	a5,a5,a4
    80002f48:	8782                	jr	a5
            case IRQ_S_SOFT: return "Supervisor software interrupt";
    80002f4a:	00003797          	auipc	a5,0x3
    80002f4e:	60e78793          	add	a5,a5,1550 # 80006558 <etext+0x1558>
    80002f52:	a201                	j	80003052 <trap_cause_name+0x154>
            case IRQ_M_SOFT: return "Machine software interrupt";
    80002f54:	00003797          	auipc	a5,0x3
    80002f58:	62478793          	add	a5,a5,1572 # 80006578 <etext+0x1578>
    80002f5c:	a8dd                	j	80003052 <trap_cause_name+0x154>
            case IRQ_S_TIMER: return "Supervisor timer interrupt";
    80002f5e:	00003797          	auipc	a5,0x3
    80002f62:	63a78793          	add	a5,a5,1594 # 80006598 <etext+0x1598>
    80002f66:	a0f5                	j	80003052 <trap_cause_name+0x154>
            case IRQ_M_TIMER: return "Machine timer interrupt";
    80002f68:	00003797          	auipc	a5,0x3
    80002f6c:	65078793          	add	a5,a5,1616 # 800065b8 <etext+0x15b8>
    80002f70:	a0cd                	j	80003052 <trap_cause_name+0x154>
            case IRQ_S_EXT: return "Supervisor external interrupt";
    80002f72:	00003797          	auipc	a5,0x3
    80002f76:	65e78793          	add	a5,a5,1630 # 800065d0 <etext+0x15d0>
    80002f7a:	a8e1                	j	80003052 <trap_cause_name+0x154>
            case IRQ_M_EXT: return "Machine external interrupt";
    80002f7c:	00003797          	auipc	a5,0x3
    80002f80:	67478793          	add	a5,a5,1652 # 800065f0 <etext+0x15f0>
    80002f84:	a0f9                	j	80003052 <trap_cause_name+0x154>
            default: return "Unknown interrupt";
    80002f86:	00003797          	auipc	a5,0x3
    80002f8a:	68a78793          	add	a5,a5,1674 # 80006610 <etext+0x1610>
    80002f8e:	a0d1                	j	80003052 <trap_cause_name+0x154>
        }
    } else {
        // 异常
        switch(cause) {
    80002f90:	fe843703          	ld	a4,-24(s0)
    80002f94:	47bd                	li	a5,15
    80002f96:	0ae7ea63          	bltu	a5,a4,8000304a <trap_cause_name+0x14c>
    80002f9a:	fe843783          	ld	a5,-24(s0)
    80002f9e:	00279713          	sll	a4,a5,0x2
    80002fa2:	00003797          	auipc	a5,0x3
    80002fa6:	7e678793          	add	a5,a5,2022 # 80006788 <etext+0x1788>
    80002faa:	97ba                	add	a5,a5,a4
    80002fac:	439c                	lw	a5,0(a5)
    80002fae:	0007871b          	sext.w	a4,a5
    80002fb2:	00003797          	auipc	a5,0x3
    80002fb6:	7d678793          	add	a5,a5,2006 # 80006788 <etext+0x1788>
    80002fba:	97ba                	add	a5,a5,a4
    80002fbc:	8782                	jr	a5
            case CAUSE_MISALIGNED_FETCH: return "Instruction address misaligned";
    80002fbe:	00003797          	auipc	a5,0x3
    80002fc2:	66a78793          	add	a5,a5,1642 # 80006628 <etext+0x1628>
    80002fc6:	a071                	j	80003052 <trap_cause_name+0x154>
            case CAUSE_FETCH_ACCESS: return "Instruction access fault";
    80002fc8:	00003797          	auipc	a5,0x3
    80002fcc:	68078793          	add	a5,a5,1664 # 80006648 <etext+0x1648>
    80002fd0:	a049                	j	80003052 <trap_cause_name+0x154>
            case CAUSE_ILLEGAL_INSTRUCTION: return "Illegal instruction";
    80002fd2:	00003797          	auipc	a5,0x3
    80002fd6:	38e78793          	add	a5,a5,910 # 80006360 <etext+0x1360>
    80002fda:	a8a5                	j	80003052 <trap_cause_name+0x154>
            case CAUSE_BREAKPOINT: return "Breakpoint";
    80002fdc:	00003797          	auipc	a5,0x3
    80002fe0:	68c78793          	add	a5,a5,1676 # 80006668 <etext+0x1668>
    80002fe4:	a0bd                	j	80003052 <trap_cause_name+0x154>
            case CAUSE_MISALIGNED_LOAD: return "Load address misaligned";
    80002fe6:	00003797          	auipc	a5,0x3
    80002fea:	69278793          	add	a5,a5,1682 # 80006678 <etext+0x1678>
    80002fee:	a095                	j	80003052 <trap_cause_name+0x154>
            case CAUSE_LOAD_ACCESS: return "Load access fault";
    80002ff0:	00003797          	auipc	a5,0x3
    80002ff4:	6a078793          	add	a5,a5,1696 # 80006690 <etext+0x1690>
    80002ff8:	a8a9                	j	80003052 <trap_cause_name+0x154>
            case CAUSE_MISALIGNED_STORE: return "Store address misaligned";
    80002ffa:	00003797          	auipc	a5,0x3
    80002ffe:	6ae78793          	add	a5,a5,1710 # 800066a8 <etext+0x16a8>
    80003002:	a881                	j	80003052 <trap_cause_name+0x154>
            case CAUSE_STORE_ACCESS: return "Store access fault";
    80003004:	00003797          	auipc	a5,0x3
    80003008:	6c478793          	add	a5,a5,1732 # 800066c8 <etext+0x16c8>
    8000300c:	a099                	j	80003052 <trap_cause_name+0x154>
            case CAUSE_USER_ECALL: return "Environment call from U-mode";
    8000300e:	00003797          	auipc	a5,0x3
    80003012:	6d278793          	add	a5,a5,1746 # 800066e0 <etext+0x16e0>
    80003016:	a835                	j	80003052 <trap_cause_name+0x154>
            case CAUSE_SUPERVISOR_ECALL: return "Environment call from S-mode";
    80003018:	00003797          	auipc	a5,0x3
    8000301c:	6e878793          	add	a5,a5,1768 # 80006700 <etext+0x1700>
    80003020:	a80d                	j	80003052 <trap_cause_name+0x154>
            case CAUSE_MACHINE_ECALL: return "Environment call from M-mode";
    80003022:	00003797          	auipc	a5,0x3
    80003026:	6fe78793          	add	a5,a5,1790 # 80006720 <etext+0x1720>
    8000302a:	a025                	j	80003052 <trap_cause_name+0x154>
            case CAUSE_FETCH_PAGE_FAULT: return "Instruction page fault";
    8000302c:	00003797          	auipc	a5,0x3
    80003030:	71478793          	add	a5,a5,1812 # 80006740 <etext+0x1740>
    80003034:	a839                	j	80003052 <trap_cause_name+0x154>
            case CAUSE_LOAD_PAGE_FAULT: return "Load page fault";
    80003036:	00003797          	auipc	a5,0x3
    8000303a:	21278793          	add	a5,a5,530 # 80006248 <etext+0x1248>
    8000303e:	a811                	j	80003052 <trap_cause_name+0x154>
            case CAUSE_STORE_PAGE_FAULT: return "Store page fault";
    80003040:	00003797          	auipc	a5,0x3
    80003044:	2a878793          	add	a5,a5,680 # 800062e8 <etext+0x12e8>
    80003048:	a029                	j	80003052 <trap_cause_name+0x154>
            default: return "Unknown exception";
    8000304a:	00003797          	auipc	a5,0x3
    8000304e:	46e78793          	add	a5,a5,1134 # 800064b8 <etext+0x14b8>
        }
    }
}
    80003052:	853e                	mv	a0,a5
    80003054:	6462                	ld	s0,24(sp)
    80003056:	6105                	add	sp,sp,32
    80003058:	8082                	ret

000000008000305a <dump_trapframe>:

// ==================== 打印trapframe内容（调试用） ====================
void dump_trapframe(struct trapframe *tf)
{
    8000305a:	1101                	add	sp,sp,-32
    8000305c:	ec06                	sd	ra,24(sp)
    8000305e:	e822                	sd	s0,16(sp)
    80003060:	1000                	add	s0,sp,32
    80003062:	fea43423          	sd	a0,-24(s0)
    printf("=== Trapframe Dump ===\n");
    80003066:	00003517          	auipc	a0,0x3
    8000306a:	76250513          	add	a0,a0,1890 # 800067c8 <etext+0x17c8>
    8000306e:	ffffe097          	auipc	ra,0xffffe
    80003072:	184080e7          	jalr	388(ra) # 800011f2 <printf>
    printf("ra:  %p  sp:  %p  gp:  %p  tp:  %p\n",
           (void*)tf->ra, (void*)tf->sp, (void*)tf->gp, (void*)tf->tp);
    80003076:	fe843783          	ld	a5,-24(s0)
    8000307a:	639c                	ld	a5,0(a5)
    printf("ra:  %p  sp:  %p  gp:  %p  tp:  %p\n",
    8000307c:	85be                	mv	a1,a5
           (void*)tf->ra, (void*)tf->sp, (void*)tf->gp, (void*)tf->tp);
    8000307e:	fe843783          	ld	a5,-24(s0)
    80003082:	679c                	ld	a5,8(a5)
    printf("ra:  %p  sp:  %p  gp:  %p  tp:  %p\n",
    80003084:	863e                	mv	a2,a5
           (void*)tf->ra, (void*)tf->sp, (void*)tf->gp, (void*)tf->tp);
    80003086:	fe843783          	ld	a5,-24(s0)
    8000308a:	6b9c                	ld	a5,16(a5)
    printf("ra:  %p  sp:  %p  gp:  %p  tp:  %p\n",
    8000308c:	86be                	mv	a3,a5
           (void*)tf->ra, (void*)tf->sp, (void*)tf->gp, (void*)tf->tp);
    8000308e:	fe843783          	ld	a5,-24(s0)
    80003092:	6f9c                	ld	a5,24(a5)
    printf("ra:  %p  sp:  %p  gp:  %p  tp:  %p\n",
    80003094:	873e                	mv	a4,a5
    80003096:	00003517          	auipc	a0,0x3
    8000309a:	74a50513          	add	a0,a0,1866 # 800067e0 <etext+0x17e0>
    8000309e:	ffffe097          	auipc	ra,0xffffe
    800030a2:	154080e7          	jalr	340(ra) # 800011f2 <printf>
    printf("t0:  %p  t1:  %p  t2:  %p\n",
           (void*)tf->t0, (void*)tf->t1, (void*)tf->t2);
    800030a6:	fe843783          	ld	a5,-24(s0)
    800030aa:	739c                	ld	a5,32(a5)
    printf("t0:  %p  t1:  %p  t2:  %p\n",
    800030ac:	873e                	mv	a4,a5
           (void*)tf->t0, (void*)tf->t1, (void*)tf->t2);
    800030ae:	fe843783          	ld	a5,-24(s0)
    800030b2:	779c                	ld	a5,40(a5)
    printf("t0:  %p  t1:  %p  t2:  %p\n",
    800030b4:	863e                	mv	a2,a5
           (void*)tf->t0, (void*)tf->t1, (void*)tf->t2);
    800030b6:	fe843783          	ld	a5,-24(s0)
    800030ba:	7b9c                	ld	a5,48(a5)
    printf("t0:  %p  t1:  %p  t2:  %p\n",
    800030bc:	86be                	mv	a3,a5
    800030be:	85ba                	mv	a1,a4
    800030c0:	00003517          	auipc	a0,0x3
    800030c4:	74850513          	add	a0,a0,1864 # 80006808 <etext+0x1808>
    800030c8:	ffffe097          	auipc	ra,0xffffe
    800030cc:	12a080e7          	jalr	298(ra) # 800011f2 <printf>
    printf("s0:  %p  s1:  %p\n",
           (void*)tf->s0, (void*)tf->s1);
    800030d0:	fe843783          	ld	a5,-24(s0)
    800030d4:	7f9c                	ld	a5,56(a5)
    printf("s0:  %p  s1:  %p\n",
    800030d6:	873e                	mv	a4,a5
           (void*)tf->s0, (void*)tf->s1);
    800030d8:	fe843783          	ld	a5,-24(s0)
    800030dc:	63bc                	ld	a5,64(a5)
    printf("s0:  %p  s1:  %p\n",
    800030de:	863e                	mv	a2,a5
    800030e0:	85ba                	mv	a1,a4
    800030e2:	00003517          	auipc	a0,0x3
    800030e6:	74650513          	add	a0,a0,1862 # 80006828 <etext+0x1828>
    800030ea:	ffffe097          	auipc	ra,0xffffe
    800030ee:	108080e7          	jalr	264(ra) # 800011f2 <printf>
    printf("a0:  %p  a1:  %p  a2:  %p  a3:  %p\n",
           (void*)tf->a0, (void*)tf->a1, (void*)tf->a2, (void*)tf->a3);
    800030f2:	fe843783          	ld	a5,-24(s0)
    800030f6:	67bc                	ld	a5,72(a5)
    printf("a0:  %p  a1:  %p  a2:  %p  a3:  %p\n",
    800030f8:	85be                	mv	a1,a5
           (void*)tf->a0, (void*)tf->a1, (void*)tf->a2, (void*)tf->a3);
    800030fa:	fe843783          	ld	a5,-24(s0)
    800030fe:	6bbc                	ld	a5,80(a5)
    printf("a0:  %p  a1:  %p  a2:  %p  a3:  %p\n",
    80003100:	863e                	mv	a2,a5
           (void*)tf->a0, (void*)tf->a1, (void*)tf->a2, (void*)tf->a3);
    80003102:	fe843783          	ld	a5,-24(s0)
    80003106:	6fbc                	ld	a5,88(a5)
    printf("a0:  %p  a1:  %p  a2:  %p  a3:  %p\n",
    80003108:	86be                	mv	a3,a5
           (void*)tf->a0, (void*)tf->a1, (void*)tf->a2, (void*)tf->a3);
    8000310a:	fe843783          	ld	a5,-24(s0)
    8000310e:	73bc                	ld	a5,96(a5)
    printf("a0:  %p  a1:  %p  a2:  %p  a3:  %p\n",
    80003110:	873e                	mv	a4,a5
    80003112:	00003517          	auipc	a0,0x3
    80003116:	72e50513          	add	a0,a0,1838 # 80006840 <etext+0x1840>
    8000311a:	ffffe097          	auipc	ra,0xffffe
    8000311e:	0d8080e7          	jalr	216(ra) # 800011f2 <printf>
    printf("a4:  %p  a5:  %p  a6:  %p  a7:  %p\n",
           (void*)tf->a4, (void*)tf->a5, (void*)tf->a6, (void*)tf->a7);
    80003122:	fe843783          	ld	a5,-24(s0)
    80003126:	77bc                	ld	a5,104(a5)
    printf("a4:  %p  a5:  %p  a6:  %p  a7:  %p\n",
    80003128:	85be                	mv	a1,a5
           (void*)tf->a4, (void*)tf->a5, (void*)tf->a6, (void*)tf->a7);
    8000312a:	fe843783          	ld	a5,-24(s0)
    8000312e:	7bbc                	ld	a5,112(a5)
    printf("a4:  %p  a5:  %p  a6:  %p  a7:  %p\n",
    80003130:	863e                	mv	a2,a5
           (void*)tf->a4, (void*)tf->a5, (void*)tf->a6, (void*)tf->a7);
    80003132:	fe843783          	ld	a5,-24(s0)
    80003136:	7fbc                	ld	a5,120(a5)
    printf("a4:  %p  a5:  %p  a6:  %p  a7:  %p\n",
    80003138:	86be                	mv	a3,a5
           (void*)tf->a4, (void*)tf->a5, (void*)tf->a6, (void*)tf->a7);
    8000313a:	fe843783          	ld	a5,-24(s0)
    8000313e:	63dc                	ld	a5,128(a5)
    printf("a4:  %p  a5:  %p  a6:  %p  a7:  %p\n",
    80003140:	873e                	mv	a4,a5
    80003142:	00003517          	auipc	a0,0x3
    80003146:	72650513          	add	a0,a0,1830 # 80006868 <etext+0x1868>
    8000314a:	ffffe097          	auipc	ra,0xffffe
    8000314e:	0a8080e7          	jalr	168(ra) # 800011f2 <printf>
    printf("sepc: %p  sstatus: %p\n",
           (void*)tf->sepc, (void*)tf->sstatus);
    80003152:	fe843783          	ld	a5,-24(s0)
    80003156:	7ffc                	ld	a5,248(a5)
    printf("sepc: %p  sstatus: %p\n",
    80003158:	873e                	mv	a4,a5
           (void*)tf->sepc, (void*)tf->sstatus);
    8000315a:	fe843783          	ld	a5,-24(s0)
    8000315e:	1007b783          	ld	a5,256(a5)
    printf("sepc: %p  sstatus: %p\n",
    80003162:	863e                	mv	a2,a5
    80003164:	85ba                	mv	a1,a4
    80003166:	00003517          	auipc	a0,0x3
    8000316a:	72a50513          	add	a0,a0,1834 # 80006890 <etext+0x1890>
    8000316e:	ffffe097          	auipc	ra,0xffffe
    80003172:	084080e7          	jalr	132(ra) # 800011f2 <printf>
    printf("===================\n");
    80003176:	00003517          	auipc	a0,0x3
    8000317a:	73250513          	add	a0,a0,1842 # 800068a8 <etext+0x18a8>
    8000317e:	ffffe097          	auipc	ra,0xffffe
    80003182:	074080e7          	jalr	116(ra) # 800011f2 <printf>
}
    80003186:	0001                	nop
    80003188:	60e2                	ld	ra,24(sp)
    8000318a:	6442                	ld	s0,16(sp)
    8000318c:	6105                	add	sp,sp,32
    8000318e:	8082                	ret

0000000080003190 <print_trap_stats>:

// ==================== 中断统计信息 ====================
void print_trap_stats(void)
{
    80003190:	1141                	add	sp,sp,-16
    80003192:	e406                	sd	ra,8(sp)
    80003194:	e022                	sd	s0,0(sp)
    80003196:	0800                	add	s0,sp,16
    printf("\n=== Trap Statistics ===\n");
    80003198:	00003517          	auipc	a0,0x3
    8000319c:	72850513          	add	a0,a0,1832 # 800068c0 <etext+0x18c0>
    800031a0:	ffffe097          	auipc	ra,0xffffe
    800031a4:	052080e7          	jalr	82(ra) # 800011f2 <printf>
    printf("Timer interrupts:    %d\n", (int)interrupt_counts[IRQ_S_TIMER]);
    800031a8:	00009797          	auipc	a5,0x9
    800031ac:	e9078793          	add	a5,a5,-368 # 8000c038 <interrupt_counts>
    800031b0:	779c                	ld	a5,40(a5)
    800031b2:	2781                	sext.w	a5,a5
    800031b4:	85be                	mv	a1,a5
    800031b6:	00003517          	auipc	a0,0x3
    800031ba:	72a50513          	add	a0,a0,1834 # 800068e0 <etext+0x18e0>
    800031be:	ffffe097          	auipc	ra,0xffffe
    800031c2:	034080e7          	jalr	52(ra) # 800011f2 <printf>
    printf("Software interrupts: %d\n", (int)interrupt_counts[IRQ_S_SOFT]);
    800031c6:	00009797          	auipc	a5,0x9
    800031ca:	e7278793          	add	a5,a5,-398 # 8000c038 <interrupt_counts>
    800031ce:	679c                	ld	a5,8(a5)
    800031d0:	2781                	sext.w	a5,a5
    800031d2:	85be                	mv	a1,a5
    800031d4:	00003517          	auipc	a0,0x3
    800031d8:	72c50513          	add	a0,a0,1836 # 80006900 <etext+0x1900>
    800031dc:	ffffe097          	auipc	ra,0xffffe
    800031e0:	016080e7          	jalr	22(ra) # 800011f2 <printf>
    printf("External interrupts: %d\n", (int)interrupt_counts[IRQ_S_EXT]);
    800031e4:	00009797          	auipc	a5,0x9
    800031e8:	e5478793          	add	a5,a5,-428 # 8000c038 <interrupt_counts>
    800031ec:	67bc                	ld	a5,72(a5)
    800031ee:	2781                	sext.w	a5,a5
    800031f0:	85be                	mv	a1,a5
    800031f2:	00003517          	auipc	a0,0x3
    800031f6:	72e50513          	add	a0,a0,1838 # 80006920 <etext+0x1920>
    800031fa:	ffffe097          	auipc	ra,0xffffe
    800031fe:	ff8080e7          	jalr	-8(ra) # 800011f2 <printf>
    printf("Exceptions:          %d\n", (int)exception_count);
    80003202:	00009797          	auipc	a5,0x9
    80003206:	eb678793          	add	a5,a5,-330 # 8000c0b8 <exception_count>
    8000320a:	639c                	ld	a5,0(a5)
    8000320c:	2781                	sext.w	a5,a5
    8000320e:	85be                	mv	a1,a5
    80003210:	00003517          	auipc	a0,0x3
    80003214:	73050513          	add	a0,a0,1840 # 80006940 <etext+0x1940>
    80003218:	ffffe097          	auipc	ra,0xffffe
    8000321c:	fda080e7          	jalr	-38(ra) # 800011f2 <printf>
    printf("====================\n");
    80003220:	00003517          	auipc	a0,0x3
    80003224:	74050513          	add	a0,a0,1856 # 80006960 <etext+0x1960>
    80003228:	ffffe097          	auipc	ra,0xffffe
    8000322c:	fca080e7          	jalr	-54(ra) # 800011f2 <printf>
    80003230:	0001                	nop
    80003232:	60a2                	ld	ra,8(sp)
    80003234:	6402                	ld	s0,0(sp)
    80003236:	0141                	add	sp,sp,16
    80003238:	8082                	ret
    8000323a:	0000                	unimp
    8000323c:	0000                	unimp
	...

0000000080003240 <kernelvec>:
.globl kernelvec

.align 4
kernelvec:
    # ========== 分配栈空间 ==========
    addi sp, sp, -264
    80003240:	ef810113          	add	sp,sp,-264

    # ========== 保存所有寄存器（除sp）==========
    sd ra, 0(sp)
    80003244:	e006                	sd	ra,0(sp)
    sd gp, 16(sp)
    80003246:	e80e                	sd	gp,16(sp)
    sd tp, 24(sp)
    80003248:	ec12                	sd	tp,24(sp)
    sd t0, 32(sp)
    8000324a:	f016                	sd	t0,32(sp)
    sd t1, 40(sp)
    8000324c:	f41a                	sd	t1,40(sp)
    sd t2, 48(sp)
    8000324e:	f81e                	sd	t2,48(sp)
    sd s0, 56(sp)
    80003250:	fc22                	sd	s0,56(sp)
    sd s1, 64(sp)
    80003252:	e0a6                	sd	s1,64(sp)
    sd a0, 72(sp)
    80003254:	e4aa                	sd	a0,72(sp)
    sd a1, 80(sp)
    80003256:	e8ae                	sd	a1,80(sp)
    sd a2, 88(sp)
    80003258:	ecb2                	sd	a2,88(sp)
    sd a3, 96(sp)
    8000325a:	f0b6                	sd	a3,96(sp)
    sd a4, 104(sp)
    8000325c:	f4ba                	sd	a4,104(sp)
    sd a5, 112(sp)
    8000325e:	f8be                	sd	a5,112(sp)
    sd a6, 120(sp)
    80003260:	fcc2                	sd	a6,120(sp)
    sd a7, 128(sp)
    80003262:	e146                	sd	a7,128(sp)
    sd s2, 136(sp)
    80003264:	e54a                	sd	s2,136(sp)
    sd s3, 144(sp)
    80003266:	e94e                	sd	s3,144(sp)
    sd s4, 152(sp)
    80003268:	ed52                	sd	s4,152(sp)
    sd s5, 160(sp)
    8000326a:	f156                	sd	s5,160(sp)
    sd s6, 168(sp)
    8000326c:	f55a                	sd	s6,168(sp)
    sd s7, 176(sp)
    8000326e:	f95e                	sd	s7,176(sp)
    sd s8, 184(sp)
    80003270:	fd62                	sd	s8,184(sp)
    sd s9, 192(sp)
    80003272:	e1e6                	sd	s9,192(sp)
    sd s10, 200(sp)
    80003274:	e5ea                	sd	s10,200(sp)
    sd s11, 208(sp)
    80003276:	e9ee                	sd	s11,208(sp)
    sd t3, 216(sp)
    80003278:	edf2                	sd	t3,216(sp)
    sd t4, 224(sp)
    8000327a:	f1f6                	sd	t4,224(sp)
    sd t5, 232(sp)
    8000327c:	f5fa                	sd	t5,232(sp)
    sd t6, 240(sp)
    8000327e:	f9fe                	sd	t6,240(sp)

    # ========== 保存 sepc 和 sstatus ==========
    csrr t0, sepc
    80003280:	141022f3          	csrr	t0,sepc
    sd t0, 248(sp)
    80003284:	fd96                	sd	t0,248(sp)
    
    csrr t1, sstatus
    80003286:	10002373          	csrr	t1,sstatus
    sd t1, 256(sp)
    8000328a:	e21a                	sd	t1,256(sp)

    # ========== 保存原始 sp ==========
    addi t0, sp, 264
    8000328c:	10810293          	add	t0,sp,264
    sd t0, 8(sp)
    80003290:	e416                	sd	t0,8(sp)

    # ========== 关键：把 trapframe 地址作为参数传递 ==========
    # a0 = trapframe 地址（C函数的第一个参数）
    mv a0, sp
    80003292:	850a                	mv	a0,sp
    
    call kerneltrap
    80003294:	00000097          	auipc	ra,0x0
    80003298:	bd0080e7          	jalr	-1072(ra) # 80002e64 <kerneltrap>

    # ========== 恢复 sepc 和 sstatus ==========
    ld t0, 248(sp)
    8000329c:	72ee                	ld	t0,248(sp)
    csrw sepc, t0
    8000329e:	14129073          	csrw	sepc,t0
    
    ld t1, 256(sp)
    800032a2:	6312                	ld	t1,256(sp)
    csrw sstatus, t1
    800032a4:	10031073          	csrw	sstatus,t1

    # ========== 恢复所有寄存器 ==========
    ld ra, 0(sp)
    800032a8:	6082                	ld	ra,0(sp)
    ld gp, 16(sp)
    800032aa:	61c2                	ld	gp,16(sp)
    ld tp, 24(sp)
    800032ac:	6262                	ld	tp,24(sp)
    ld t0, 32(sp)
    800032ae:	7282                	ld	t0,32(sp)
    ld t1, 40(sp)
    800032b0:	7322                	ld	t1,40(sp)
    ld t2, 48(sp)
    800032b2:	73c2                	ld	t2,48(sp)
    ld s0, 56(sp)
    800032b4:	7462                	ld	s0,56(sp)
    ld s1, 64(sp)
    800032b6:	6486                	ld	s1,64(sp)
    ld a0, 72(sp)
    800032b8:	6526                	ld	a0,72(sp)
    ld a1, 80(sp)
    800032ba:	65c6                	ld	a1,80(sp)
    ld a2, 88(sp)
    800032bc:	6666                	ld	a2,88(sp)
    ld a3, 96(sp)
    800032be:	7686                	ld	a3,96(sp)
    ld a4, 104(sp)
    800032c0:	7726                	ld	a4,104(sp)
    ld a5, 112(sp)
    800032c2:	77c6                	ld	a5,112(sp)
    ld a6, 120(sp)
    800032c4:	7866                	ld	a6,120(sp)
    ld a7, 128(sp)
    800032c6:	688a                	ld	a7,128(sp)
    ld s2, 136(sp)
    800032c8:	692a                	ld	s2,136(sp)
    ld s3, 144(sp)
    800032ca:	69ca                	ld	s3,144(sp)
    ld s4, 152(sp)
    800032cc:	6a6a                	ld	s4,152(sp)
    ld s5, 160(sp)
    800032ce:	7a8a                	ld	s5,160(sp)
    ld s6, 168(sp)
    800032d0:	7b2a                	ld	s6,168(sp)
    ld s7, 176(sp)
    800032d2:	7bca                	ld	s7,176(sp)
    ld s8, 184(sp)
    800032d4:	7c6a                	ld	s8,184(sp)
    ld s9, 192(sp)
    800032d6:	6c8e                	ld	s9,192(sp)
    ld s10, 200(sp)
    800032d8:	6d2e                	ld	s10,200(sp)
    ld s11, 208(sp)
    800032da:	6dce                	ld	s11,208(sp)
    ld t3, 216(sp)
    800032dc:	6e6e                	ld	t3,216(sp)
    ld t4, 224(sp)
    800032de:	7e8e                	ld	t4,224(sp)
    ld t5, 232(sp)
    800032e0:	7f2e                	ld	t5,232(sp)
    ld t6, 240(sp)
    800032e2:	7fce                	ld	t6,240(sp)

    # ========== 恢复 sp 并返回 ==========
    addi sp, sp, 264
    800032e4:	10810113          	add	sp,sp,264
    800032e8:	10200073          	sret
    800032ec:	00000013          	nop

00000000800032f0 <timervec>:

.globl timervec
.align 4
timervec:
    # 交换 a0 和 mscratch
    csrrw a0, mscratch, a0
    800032f0:	34051573          	csrrw	a0,mscratch,a0
    # 现在 a0 指向 timer_scratch 结构
    
    # 保存寄存器
    sd a1, 24(a0)
    800032f4:	ed0c                	sd	a1,24(a0)
    sd a2, 32(a0)
    800032f6:	f110                	sd	a2,32(a0)
    sd a3, 40(a0)
    800032f8:	f514                	sd	a3,40(a0)
    
    # 读取当前 mtime
    li a1, 0x200bff8
    800032fa:	0200c5b7          	lui	a1,0x200c
    800032fe:	35e1                	addw	a1,a1,-8 # 200bff8 <_start-0x7dff4008>
    ld a2, 0(a1)
    80003300:	6190                	ld	a2,0(a1)
    
    # 加上时钟间隔
    ld a3, 0(a0)        # 读取 interval
    80003302:	6114                	ld	a3,0(a0)
    add a2, a2, a3      # next_time = mtime + interval
    80003304:	9636                	add	a2,a2,a3
    sd a2, 8(a0)        # 保存 next_time
    80003306:	e510                	sd	a2,8(a0)
    
    # 设置 mtimecmp
    li a1, 0x2004000
    80003308:	020045b7          	lui	a1,0x2004
    sd a2, 0(a1)
    8000330c:	e190                	sd	a2,0(a1)
    
    # 触发 S 模式软件中断
    li a1, 2
    8000330e:	4589                	li	a1,2
    csrw sip, a1
    80003310:	14459073          	csrw	sip,a1
    
    # 恢复寄存器
    ld a3, 40(a0)
    80003314:	7514                	ld	a3,40(a0)
    ld a2, 32(a0)
    80003316:	7110                	ld	a2,32(a0)
    ld a1, 24(a0)
    80003318:	6d0c                	ld	a1,24(a0)
    
    # 恢复 a0
    csrrw a0, mscratch, a0
    8000331a:	34051573          	csrrw	a0,mscratch,a0
    
    8000331e:	30200073          	mret
    80003322:	0001                	nop
    80003324:	00000013          	nop
    80003328:	00000013          	nop
    8000332c:	00000013          	nop

0000000080003330 <w_mscratch>:
    80003330:	1101                	add	sp,sp,-32
    80003332:	ec22                	sd	s0,24(sp)
    80003334:	1000                	add	s0,sp,32
    80003336:	fea43423          	sd	a0,-24(s0)
    8000333a:	fe843783          	ld	a5,-24(s0)
    8000333e:	34079073          	csrw	mscratch,a5
    80003342:	0001                	nop
    80003344:	6462                	ld	s0,24(sp)
    80003346:	6105                	add	sp,sp,32
    80003348:	8082                	ret

000000008000334a <read_mtime>:
static inline uint64 read_mtime(void) {
    8000334a:	1141                	add	sp,sp,-16
    8000334c:	e422                	sd	s0,8(sp)
    8000334e:	0800                	add	s0,sp,16
    return *(volatile uint64*)CLINT_MTIME;
    80003350:	0200c7b7          	lui	a5,0x200c
    80003354:	17e1                	add	a5,a5,-8 # 200bff8 <_start-0x7dff4008>
    80003356:	639c                	ld	a5,0(a5)
}
    80003358:	853e                	mv	a0,a5
    8000335a:	6422                	ld	s0,8(sp)
    8000335c:	0141                	add	sp,sp,16
    8000335e:	8082                	ret

0000000080003360 <write_mtimecmp>:
static inline void write_mtimecmp(uint64 value) {
    80003360:	1101                	add	sp,sp,-32
    80003362:	ec22                	sd	s0,24(sp)
    80003364:	1000                	add	s0,sp,32
    80003366:	fea43423          	sd	a0,-24(s0)
    *(volatile uint64*)CLINT_MTIMECMP = value;
    8000336a:	020047b7          	lui	a5,0x2004
    8000336e:	fe843703          	ld	a4,-24(s0)
    80003372:	e398                	sd	a4,0(a5)
}
    80003374:	0001                	nop
    80003376:	6462                	ld	s0,24(sp)
    80003378:	6105                	add	sp,sp,32
    8000337a:	8082                	ret

000000008000337c <timer_init_hart>:
{
    8000337c:	1101                	add	sp,sp,-32
    8000337e:	ec06                	sd	ra,24(sp)
    80003380:	e822                	sd	s0,16(sp)
    80003382:	1000                	add	s0,sp,32
    timer_scratch0.interval = timer_interval;
    80003384:	00005797          	auipc	a5,0x5
    80003388:	c8c78793          	add	a5,a5,-884 # 80008010 <timer_interval>
    8000338c:	6398                	ld	a4,0(a5)
    8000338e:	00009797          	auipc	a5,0x9
    80003392:	dc278793          	add	a5,a5,-574 # 8000c150 <timer_scratch0>
    80003396:	e398                	sd	a4,0(a5)
    timer_scratch0.next_time = 0;
    80003398:	00009797          	auipc	a5,0x9
    8000339c:	db878793          	add	a5,a5,-584 # 8000c150 <timer_scratch0>
    800033a0:	0007b423          	sd	zero,8(a5)
    w_mscratch((uint64)&timer_scratch0);
    800033a4:	00009797          	auipc	a5,0x9
    800033a8:	dac78793          	add	a5,a5,-596 # 8000c150 <timer_scratch0>
    800033ac:	853e                	mv	a0,a5
    800033ae:	00000097          	auipc	ra,0x0
    800033b2:	f82080e7          	jalr	-126(ra) # 80003330 <w_mscratch>
    uint64 mtime = read_mtime();
    800033b6:	00000097          	auipc	ra,0x0
    800033ba:	f94080e7          	jalr	-108(ra) # 8000334a <read_mtime>
    800033be:	fea43423          	sd	a0,-24(s0)
    write_mtimecmp(mtime + timer_interval);
    800033c2:	00005797          	auipc	a5,0x5
    800033c6:	c4e78793          	add	a5,a5,-946 # 80008010 <timer_interval>
    800033ca:	6398                	ld	a4,0(a5)
    800033cc:	fe843783          	ld	a5,-24(s0)
    800033d0:	97ba                	add	a5,a5,a4
    800033d2:	853e                	mv	a0,a5
    800033d4:	00000097          	auipc	ra,0x0
    800033d8:	f8c080e7          	jalr	-116(ra) # 80003360 <write_mtimecmp>
}
    800033dc:	0001                	nop
    800033de:	60e2                	ld	ra,24(sp)
    800033e0:	6442                	ld	s0,16(sp)
    800033e2:	6105                	add	sp,sp,32
    800033e4:	8082                	ret

00000000800033e6 <timer_interrupt>:
{
    800033e6:	1101                	add	sp,sp,-32
    800033e8:	ec06                	sd	ra,24(sp)
    800033ea:	e822                	sd	s0,16(sp)
    800033ec:	1000                	add	s0,sp,32
    ticks++;
    800033ee:	00009797          	auipc	a5,0x9
    800033f2:	d5278793          	add	a5,a5,-686 # 8000c140 <ticks>
    800033f6:	639c                	ld	a5,0(a5)
    800033f8:	00178713          	add	a4,a5,1
    800033fc:	00009797          	auipc	a5,0x9
    80003400:	d4478793          	add	a5,a5,-700 # 8000c140 <ticks>
    80003404:	e398                	sd	a4,0(a5)
    if(ticks % TICKS_PER_SEC == 0) {
    80003406:	00009797          	auipc	a5,0x9
    8000340a:	d3a78793          	add	a5,a5,-710 # 8000c140 <ticks>
    8000340e:	6398                	ld	a4,0(a5)
    80003410:	47a9                	li	a5,10
    80003412:	02f777b3          	remu	a5,a4,a5
    80003416:	e39d                	bnez	a5,8000343c <timer_interrupt+0x56>
        printf("[Timer] System uptime: %d seconds\n", (int)(ticks / TICKS_PER_SEC));
    80003418:	00009797          	auipc	a5,0x9
    8000341c:	d2878793          	add	a5,a5,-728 # 8000c140 <ticks>
    80003420:	6398                	ld	a4,0(a5)
    80003422:	47a9                	li	a5,10
    80003424:	02f757b3          	divu	a5,a4,a5
    80003428:	2781                	sext.w	a5,a5
    8000342a:	85be                	mv	a1,a5
    8000342c:	00003517          	auipc	a0,0x3
    80003430:	54c50513          	add	a0,a0,1356 # 80006978 <etext+0x1978>
    80003434:	ffffe097          	auipc	ra,0xffffe
    80003438:	dbe080e7          	jalr	-578(ra) # 800011f2 <printf>
    struct proc *p = myproc();
    8000343c:	00000097          	auipc	ra,0x0
    80003440:	334080e7          	jalr	820(ra) # 80003770 <myproc>
    80003444:	fea43423          	sd	a0,-24(s0)
    if(p != 0) {
    80003448:	fe843783          	ld	a5,-24(s0)
    8000344c:	c795                	beqz	a5,80003478 <timer_interrupt+0x92>
        p->run_time++;
    8000344e:	fe843783          	ld	a5,-24(s0)
    80003452:	6bdc                	ld	a5,144(a5)
    80003454:	00178713          	add	a4,a5,1
    80003458:	fe843783          	ld	a5,-24(s0)
    8000345c:	ebd8                	sd	a4,144(a5)
        if(ticks % 10 == 0) {
    8000345e:	00009797          	auipc	a5,0x9
    80003462:	ce278793          	add	a5,a5,-798 # 8000c140 <ticks>
    80003466:	6398                	ld	a4,0(a5)
    80003468:	47a9                	li	a5,10
    8000346a:	02f777b3          	remu	a5,a4,a5
    8000346e:	e789                	bnez	a5,80003478 <timer_interrupt+0x92>
            yield();
    80003470:	00000097          	auipc	ra,0x0
    80003474:	696080e7          	jalr	1686(ra) # 80003b06 <yield>
}
    80003478:	0001                	nop
    8000347a:	60e2                	ld	ra,24(sp)
    8000347c:	6442                	ld	s0,16(sp)
    8000347e:	6105                	add	sp,sp,32
    80003480:	8082                	ret

0000000080003482 <get_ticks>:
{
    80003482:	1141                	add	sp,sp,-16
    80003484:	e422                	sd	s0,8(sp)
    80003486:	0800                	add	s0,sp,16
    return ticks;
    80003488:	00009797          	auipc	a5,0x9
    8000348c:	cb878793          	add	a5,a5,-840 # 8000c140 <ticks>
    80003490:	639c                	ld	a5,0(a5)
}
    80003492:	853e                	mv	a0,a5
    80003494:	6422                	ld	s0,8(sp)
    80003496:	0141                	add	sp,sp,16
    80003498:	8082                	ret

000000008000349a <get_uptime_seconds>:
{
    8000349a:	1141                	add	sp,sp,-16
    8000349c:	e422                	sd	s0,8(sp)
    8000349e:	0800                	add	s0,sp,16
    return ticks / TICKS_PER_SEC;
    800034a0:	00009797          	auipc	a5,0x9
    800034a4:	ca078793          	add	a5,a5,-864 # 8000c140 <ticks>
    800034a8:	6398                	ld	a4,0(a5)
    800034aa:	47a9                	li	a5,10
    800034ac:	02f757b3          	divu	a5,a4,a5
}
    800034b0:	853e                	mv	a0,a5
    800034b2:	6422                	ld	s0,8(sp)
    800034b4:	0141                	add	sp,sp,16
    800034b6:	8082                	ret

00000000800034b8 <delay_ms>:
{
    800034b8:	7179                	add	sp,sp,-48
    800034ba:	f422                	sd	s0,40(sp)
    800034bc:	1800                	add	s0,sp,48
    800034be:	fca43c23          	sd	a0,-40(s0)
    uint64 start = ticks;
    800034c2:	00009797          	auipc	a5,0x9
    800034c6:	c7e78793          	add	a5,a5,-898 # 8000c140 <ticks>
    800034ca:	639c                	ld	a5,0(a5)
    800034cc:	fef43423          	sd	a5,-24(s0)
    uint64 target_ticks = (ms * TICKS_PER_SEC) / 1000;
    800034d0:	fd843703          	ld	a4,-40(s0)
    800034d4:	87ba                	mv	a5,a4
    800034d6:	078a                	sll	a5,a5,0x2
    800034d8:	97ba                	add	a5,a5,a4
    800034da:	0786                	sll	a5,a5,0x1
    800034dc:	873e                	mv	a4,a5
    800034de:	3e800793          	li	a5,1000
    800034e2:	02f757b3          	divu	a5,a4,a5
    800034e6:	fef43023          	sd	a5,-32(s0)
    while((ticks - start) < target_ticks) {
    800034ea:	a011                	j	800034ee <delay_ms+0x36>
        asm volatile("nop");
    800034ec:	0001                	nop
    while((ticks - start) < target_ticks) {
    800034ee:	00009797          	auipc	a5,0x9
    800034f2:	c5278793          	add	a5,a5,-942 # 8000c140 <ticks>
    800034f6:	6398                	ld	a4,0(a5)
    800034f8:	fe843783          	ld	a5,-24(s0)
    800034fc:	40f707b3          	sub	a5,a4,a5
    80003500:	fe043703          	ld	a4,-32(s0)
    80003504:	fee7e4e3          	bltu	a5,a4,800034ec <delay_ms+0x34>
}
    80003508:	0001                	nop
    8000350a:	0001                	nop
    8000350c:	7422                	ld	s0,40(sp)
    8000350e:	6145                	add	sp,sp,48
    80003510:	8082                	ret

0000000080003512 <timer_init>:
{
    80003512:	1141                	add	sp,sp,-16
    80003514:	e406                	sd	ra,8(sp)
    80003516:	e022                	sd	s0,0(sp)
    80003518:	0800                	add	s0,sp,16
    printf("Initializing timer system...\n");
    8000351a:	00003517          	auipc	a0,0x3
    8000351e:	48650513          	add	a0,a0,1158 # 800069a0 <etext+0x19a0>
    80003522:	ffffe097          	auipc	ra,0xffffe
    80003526:	cd0080e7          	jalr	-816(ra) # 800011f2 <printf>
    printf("Timer frequency: %d Hz\n", (int)TIMER_FREQ);
    8000352a:	009897b7          	lui	a5,0x989
    8000352e:	68078593          	add	a1,a5,1664 # 989680 <_start-0x7f676980>
    80003532:	00003517          	auipc	a0,0x3
    80003536:	48e50513          	add	a0,a0,1166 # 800069c0 <etext+0x19c0>
    8000353a:	ffffe097          	auipc	ra,0xffffe
    8000353e:	cb8080e7          	jalr	-840(ra) # 800011f2 <printf>
    printf("Interrupt interval: %d ms\n", (int)TIMER_INTERVAL_MS);
    80003542:	06400593          	li	a1,100
    80003546:	00003517          	auipc	a0,0x3
    8000354a:	49250513          	add	a0,a0,1170 # 800069d8 <etext+0x19d8>
    8000354e:	ffffe097          	auipc	ra,0xffffe
    80003552:	ca4080e7          	jalr	-860(ra) # 800011f2 <printf>
    register_interrupt(IRQ_S_TIMER, timer_interrupt);
    80003556:	00000597          	auipc	a1,0x0
    8000355a:	e9058593          	add	a1,a1,-368 # 800033e6 <timer_interrupt>
    8000355e:	4515                	li	a0,5
    80003560:	fffff097          	auipc	ra,0xfffff
    80003564:	276080e7          	jalr	630(ra) # 800027d6 <register_interrupt>
    printf("Timer system initialized\n");
    80003568:	00003517          	auipc	a0,0x3
    8000356c:	49050513          	add	a0,a0,1168 # 800069f8 <etext+0x19f8>
    80003570:	ffffe097          	auipc	ra,0xffffe
    80003574:	c82080e7          	jalr	-894(ra) # 800011f2 <printf>
    80003578:	0001                	nop
    8000357a:	60a2                	ld	ra,8(sp)
    8000357c:	6402                	ld	s0,0(sp)
    8000357e:	0141                	add	sp,sp,16
    80003580:	8082                	ret

0000000080003582 <r_sstatus>:
}

// ==================== 获取当前进程 ====================
struct proc* myproc(void)
{
    push_off();
    80003582:	1101                	add	sp,sp,-32
    80003584:	ec22                	sd	s0,24(sp)
    80003586:	1000                	add	s0,sp,32
    struct cpu *c = mycpu();
    struct proc *p = c->proc;
    80003588:	100027f3          	csrr	a5,sstatus
    8000358c:	fef43423          	sd	a5,-24(s0)
    pop_off();
    80003590:	fe843783          	ld	a5,-24(s0)
    return p;
    80003594:	853e                	mv	a0,a5
    80003596:	6462                	ld	s0,24(sp)
    80003598:	6105                	add	sp,sp,32
    8000359a:	8082                	ret

000000008000359c <w_sstatus>:
}

    8000359c:	1101                	add	sp,sp,-32
    8000359e:	ec22                	sd	s0,24(sp)
    800035a0:	1000                	add	s0,sp,32
    800035a2:	fea43423          	sd	a0,-24(s0)
// ==================== 分配进程结构 ====================
    800035a6:	fe843783          	ld	a5,-24(s0)
    800035aa:	10079073          	csrw	sstatus,a5
struct proc* alloc_proc(void)
    800035ae:	0001                	nop
    800035b0:	6462                	ld	s0,24(sp)
    800035b2:	6105                	add	sp,sp,32
    800035b4:	8082                	ret

00000000800035b6 <proc_init>:
{
    800035b6:	1101                	add	sp,sp,-32
    800035b8:	ec06                	sd	ra,24(sp)
    800035ba:	e822                	sd	s0,16(sp)
    800035bc:	1000                	add	s0,sp,32
    printf("Initializing process system...\n");
    800035be:	00003517          	auipc	a0,0x3
    800035c2:	45a50513          	add	a0,a0,1114 # 80006a18 <etext+0x1a18>
    800035c6:	ffffe097          	auipc	ra,0xffffe
    800035ca:	c2c080e7          	jalr	-980(ra) # 800011f2 <printf>
    for(int i = 0; i < NPROC; i++) {
    800035ce:	fe042623          	sw	zero,-20(s0)
    800035d2:	a22d                	j	800036fc <proc_init+0x146>
        proc[i].state = UNUSED;
    800035d4:	00009717          	auipc	a4,0x9
    800035d8:	bac70713          	add	a4,a4,-1108 # 8000c180 <proc>
    800035dc:	fec42683          	lw	a3,-20(s0)
    800035e0:	0c800793          	li	a5,200
    800035e4:	02f687b3          	mul	a5,a3,a5
    800035e8:	97ba                	add	a5,a5,a4
    800035ea:	0007a223          	sw	zero,4(a5)
        proc[i].pid = 0;
    800035ee:	00009717          	auipc	a4,0x9
    800035f2:	b9270713          	add	a4,a4,-1134 # 8000c180 <proc>
    800035f6:	fec42683          	lw	a3,-20(s0)
    800035fa:	0c800793          	li	a5,200
    800035fe:	02f687b3          	mul	a5,a3,a5
    80003602:	97ba                	add	a5,a5,a4
    80003604:	0007a023          	sw	zero,0(a5)
        proc[i].kstack = 0;
    80003608:	00009717          	auipc	a4,0x9
    8000360c:	b7870713          	add	a4,a4,-1160 # 8000c180 <proc>
    80003610:	fec42683          	lw	a3,-20(s0)
    80003614:	0c800793          	li	a5,200
    80003618:	02f687b3          	mul	a5,a3,a5
    8000361c:	97ba                	add	a5,a5,a4
    8000361e:	0807b423          	sd	zero,136(a5)
        proc[i].parent = 0;
    80003622:	00009717          	auipc	a4,0x9
    80003626:	b5e70713          	add	a4,a4,-1186 # 8000c180 <proc>
    8000362a:	fec42683          	lw	a3,-20(s0)
    8000362e:	0c800793          	li	a5,200
    80003632:	02f687b3          	mul	a5,a3,a5
    80003636:	97ba                	add	a5,a5,a4
    80003638:	0a07b023          	sd	zero,160(a5)
        proc[i].name[0] = 0;
    8000363c:	00009717          	auipc	a4,0x9
    80003640:	b4470713          	add	a4,a4,-1212 # 8000c180 <proc>
    80003644:	fec42683          	lw	a3,-20(s0)
    80003648:	0c800793          	li	a5,200
    8000364c:	02f687b3          	mul	a5,a3,a5
    80003650:	97ba                	add	a5,a5,a4
    80003652:	00078423          	sb	zero,8(a5)
        proc[i].killed = 0;
    80003656:	00009717          	auipc	a4,0x9
    8000365a:	b2a70713          	add	a4,a4,-1238 # 8000c180 <proc>
    8000365e:	fec42683          	lw	a3,-20(s0)
    80003662:	0c800793          	li	a5,200
    80003666:	02f687b3          	mul	a5,a3,a5
    8000366a:	97ba                	add	a5,a5,a4
    8000366c:	0a07ac23          	sw	zero,184(a5)
        proc[i].pagetable = 0;
    80003670:	00009717          	auipc	a4,0x9
    80003674:	b1070713          	add	a4,a4,-1264 # 8000c180 <proc>
    80003678:	fec42683          	lw	a3,-20(s0)
    8000367c:	0c800793          	li	a5,200
    80003680:	02f687b3          	mul	a5,a3,a5
    80003684:	97ba                	add	a5,a5,a4
    80003686:	0c07b023          	sd	zero,192(a5)
        proc[i].chan = 0;
    8000368a:	00009717          	auipc	a4,0x9
    8000368e:	af670713          	add	a4,a4,-1290 # 8000c180 <proc>
    80003692:	fec42683          	lw	a3,-20(s0)
    80003696:	0c800793          	li	a5,200
    8000369a:	02f687b3          	mul	a5,a3,a5
    8000369e:	97ba                	add	a5,a5,a4
    800036a0:	0a07b823          	sd	zero,176(a5)
        proc[i].xstate = 0;
    800036a4:	00009717          	auipc	a4,0x9
    800036a8:	adc70713          	add	a4,a4,-1316 # 8000c180 <proc>
    800036ac:	fec42683          	lw	a3,-20(s0)
    800036b0:	0c800793          	li	a5,200
    800036b4:	02f687b3          	mul	a5,a3,a5
    800036b8:	97ba                	add	a5,a5,a4
    800036ba:	0a07a423          	sw	zero,168(a5)
        proc[i].run_time = 0;
    800036be:	00009717          	auipc	a4,0x9
    800036c2:	ac270713          	add	a4,a4,-1342 # 8000c180 <proc>
    800036c6:	fec42683          	lw	a3,-20(s0)
    800036ca:	0c800793          	li	a5,200
    800036ce:	02f687b3          	mul	a5,a3,a5
    800036d2:	97ba                	add	a5,a5,a4
    800036d4:	0807b823          	sd	zero,144(a5)
        proc[i].create_time = 0;
    800036d8:	00009717          	auipc	a4,0x9
    800036dc:	aa870713          	add	a4,a4,-1368 # 8000c180 <proc>
    800036e0:	fec42683          	lw	a3,-20(s0)
    800036e4:	0c800793          	li	a5,200
    800036e8:	02f687b3          	mul	a5,a3,a5
    800036ec:	97ba                	add	a5,a5,a4
    800036ee:	0807bc23          	sd	zero,152(a5)
    for(int i = 0; i < NPROC; i++) {
    800036f2:	fec42783          	lw	a5,-20(s0)
    800036f6:	2785                	addw	a5,a5,1
    800036f8:	fef42623          	sw	a5,-20(s0)
    800036fc:	fec42783          	lw	a5,-20(s0)
    80003700:	0007871b          	sext.w	a4,a5
    80003704:	03f00793          	li	a5,63
    80003708:	ece7d6e3          	bge	a5,a4,800035d4 <proc_init+0x1e>
    cpus[0].proc = 0;
    8000370c:	0000c797          	auipc	a5,0xc
    80003710:	c7478793          	add	a5,a5,-908 # 8000f380 <cpus>
    80003714:	0007b023          	sd	zero,0(a5)
    cpus[0].noff = 0;
    80003718:	0000c797          	auipc	a5,0xc
    8000371c:	c6878793          	add	a5,a5,-920 # 8000f380 <cpus>
    80003720:	0607ac23          	sw	zero,120(a5)
    cpus[0].intena = 0;
    80003724:	0000c797          	auipc	a5,0xc
    80003728:	c5c78793          	add	a5,a5,-932 # 8000f380 <cpus>
    8000372c:	0607ae23          	sw	zero,124(a5)
    total_switches = 0;
    80003730:	0000c797          	auipc	a5,0xc
    80003734:	cd078793          	add	a5,a5,-816 # 8000f400 <total_switches>
    80003738:	0007b023          	sd	zero,0(a5)
    printf("Process system initialized (max %d processes)\n", NPROC);
    8000373c:	04000593          	li	a1,64
    80003740:	00003517          	auipc	a0,0x3
    80003744:	2f850513          	add	a0,a0,760 # 80006a38 <etext+0x1a38>
    80003748:	ffffe097          	auipc	ra,0xffffe
    8000374c:	aaa080e7          	jalr	-1366(ra) # 800011f2 <printf>
}
    80003750:	0001                	nop
    80003752:	60e2                	ld	ra,24(sp)
    80003754:	6442                	ld	s0,16(sp)
    80003756:	6105                	add	sp,sp,32
    80003758:	8082                	ret

000000008000375a <mycpu>:
{
    8000375a:	1141                	add	sp,sp,-16
    8000375c:	e422                	sd	s0,8(sp)
    8000375e:	0800                	add	s0,sp,16
    return &cpus[0];
    80003760:	0000c797          	auipc	a5,0xc
    80003764:	c2078793          	add	a5,a5,-992 # 8000f380 <cpus>
}
    80003768:	853e                	mv	a0,a5
    8000376a:	6422                	ld	s0,8(sp)
    8000376c:	0141                	add	sp,sp,16
    8000376e:	8082                	ret

0000000080003770 <myproc>:
{
    80003770:	1101                	add	sp,sp,-32
    80003772:	ec06                	sd	ra,24(sp)
    80003774:	e822                	sd	s0,16(sp)
    80003776:	1000                	add	s0,sp,32
    push_off();
    80003778:	00000097          	auipc	ra,0x0
    8000377c:	294080e7          	jalr	660(ra) # 80003a0c <push_off>
    struct cpu *c = mycpu();
    80003780:	00000097          	auipc	ra,0x0
    80003784:	fda080e7          	jalr	-38(ra) # 8000375a <mycpu>
    80003788:	fea43423          	sd	a0,-24(s0)
    struct proc *p = c->proc;
    8000378c:	fe843783          	ld	a5,-24(s0)
    80003790:	639c                	ld	a5,0(a5)
    80003792:	fef43023          	sd	a5,-32(s0)
    pop_off();
    80003796:	00000097          	auipc	ra,0x0
    8000379a:	2e0080e7          	jalr	736(ra) # 80003a76 <pop_off>
    return p;
    8000379e:	fe043783          	ld	a5,-32(s0)
}
    800037a2:	853e                	mv	a0,a5
    800037a4:	60e2                	ld	ra,24(sp)
    800037a6:	6442                	ld	s0,16(sp)
    800037a8:	6105                	add	sp,sp,32
    800037aa:	8082                	ret

00000000800037ac <alloc_proc>:
{
    800037ac:	1101                	add	sp,sp,-32
    800037ae:	ec06                	sd	ra,24(sp)
    800037b0:	e822                	sd	s0,16(sp)
    800037b2:	1000                	add	s0,sp,32
    struct proc *p;
    
    for(p = proc; p < &proc[NPROC]; p++) {
    800037b4:	00009797          	auipc	a5,0x9
    800037b8:	9cc78793          	add	a5,a5,-1588 # 8000c180 <proc>
    800037bc:	fef43423          	sd	a5,-24(s0)
    800037c0:	a819                	j	800037d6 <alloc_proc+0x2a>
        if(p->state == UNUSED) {
    800037c2:	fe843783          	ld	a5,-24(s0)
    800037c6:	43dc                	lw	a5,4(a5)
    800037c8:	c38d                	beqz	a5,800037ea <alloc_proc+0x3e>
    for(p = proc; p < &proc[NPROC]; p++) {
    800037ca:	fe843783          	ld	a5,-24(s0)
    800037ce:	0c878793          	add	a5,a5,200
    800037d2:	fef43423          	sd	a5,-24(s0)
    800037d6:	fe843703          	ld	a4,-24(s0)
    800037da:	0000c797          	auipc	a5,0xc
    800037de:	ba678793          	add	a5,a5,-1114 # 8000f380 <cpus>
    800037e2:	fef760e3          	bltu	a4,a5,800037c2 <alloc_proc+0x16>
            goto found;
        }
    }
    return 0;
    800037e6:	4781                	li	a5,0
    800037e8:	a07d                	j	80003896 <alloc_proc+0xea>
            goto found;
    800037ea:	0001                	nop
    
found:
    p->pid = nextpid++;
    800037ec:	00005797          	auipc	a5,0x5
    800037f0:	82c78793          	add	a5,a5,-2004 # 80008018 <nextpid>
    800037f4:	439c                	lw	a5,0(a5)
    800037f6:	0017871b          	addw	a4,a5,1
    800037fa:	0007069b          	sext.w	a3,a4
    800037fe:	00005717          	auipc	a4,0x5
    80003802:	81a70713          	add	a4,a4,-2022 # 80008018 <nextpid>
    80003806:	c314                	sw	a3,0(a4)
    80003808:	fe843703          	ld	a4,-24(s0)
    8000380c:	c31c                	sw	a5,0(a4)
    p->state = USED;
    8000380e:	fe843783          	ld	a5,-24(s0)
    80003812:	4705                	li	a4,1
    80003814:	c3d8                	sw	a4,4(a5)
    
    p->kstack = (uint64)alloc_page();
    80003816:	ffffe097          	auipc	ra,0xffffe
    8000381a:	070080e7          	jalr	112(ra) # 80001886 <alloc_page>
    8000381e:	87aa                	mv	a5,a0
    80003820:	873e                	mv	a4,a5
    80003822:	fe843783          	ld	a5,-24(s0)
    80003826:	e7d8                	sd	a4,136(a5)
    if(p->kstack == 0) {
    80003828:	fe843783          	ld	a5,-24(s0)
    8000382c:	67dc                	ld	a5,136(a5)
    8000382e:	e799                	bnez	a5,8000383c <alloc_proc+0x90>
        p->state = UNUSED;
    80003830:	fe843783          	ld	a5,-24(s0)
    80003834:	0007a223          	sw	zero,4(a5)
        return 0;
    80003838:	4781                	li	a5,0
    8000383a:	a8b1                	j	80003896 <alloc_proc+0xea>
    }
    
    memset(&p->context, 0, sizeof(p->context));
    8000383c:	fe843783          	ld	a5,-24(s0)
    80003840:	07e1                	add	a5,a5,24
    80003842:	07000613          	li	a2,112
    80003846:	4581                	li	a1,0
    80003848:	853e                	mv	a0,a5
    8000384a:	ffffe097          	auipc	ra,0xffffe
    8000384e:	ed0080e7          	jalr	-304(ra) # 8000171a <memset>
    p->parent = 0;        // 当前版本：kernel thread，没有自动父进程
    80003852:	fe843783          	ld	a5,-24(s0)
    80003856:	0a07b023          	sd	zero,160(a5)
    p->xstate = 0;
    8000385a:	fe843783          	ld	a5,-24(s0)
    8000385e:	0a07a423          	sw	zero,168(a5)
    p->killed = 0;
    80003862:	fe843783          	ld	a5,-24(s0)
    80003866:	0a07ac23          	sw	zero,184(a5)
    p->chan = 0;
    8000386a:	fe843783          	ld	a5,-24(s0)
    8000386e:	0a07b823          	sd	zero,176(a5)
    p->run_time = 0;
    80003872:	fe843783          	ld	a5,-24(s0)
    80003876:	0807b823          	sd	zero,144(a5)
    p->create_time = get_ticks();
    8000387a:	00000097          	auipc	ra,0x0
    8000387e:	c08080e7          	jalr	-1016(ra) # 80003482 <get_ticks>
    80003882:	872a                	mv	a4,a0
    80003884:	fe843783          	ld	a5,-24(s0)
    80003888:	efd8                	sd	a4,152(a5)
    p->pagetable = 0;
    8000388a:	fe843783          	ld	a5,-24(s0)
    8000388e:	0c07b023          	sd	zero,192(a5)
    
    return p;
    80003892:	fe843783          	ld	a5,-24(s0)
}
    80003896:	853e                	mv	a0,a5
    80003898:	60e2                	ld	ra,24(sp)
    8000389a:	6442                	ld	s0,16(sp)
    8000389c:	6105                	add	sp,sp,32
    8000389e:	8082                	ret

00000000800038a0 <free_proc>:

// ==================== 释放进程资源 ====================
void free_proc(struct proc *p)
{
    800038a0:	1101                	add	sp,sp,-32
    800038a2:	ec06                	sd	ra,24(sp)
    800038a4:	e822                	sd	s0,16(sp)
    800038a6:	1000                	add	s0,sp,32
    800038a8:	fea43423          	sd	a0,-24(s0)
    if(p->kstack) {
    800038ac:	fe843783          	ld	a5,-24(s0)
    800038b0:	67dc                	ld	a5,136(a5)
    800038b2:	cf89                	beqz	a5,800038cc <free_proc+0x2c>
        free_page((void*)p->kstack);
    800038b4:	fe843783          	ld	a5,-24(s0)
    800038b8:	67dc                	ld	a5,136(a5)
    800038ba:	853e                	mv	a0,a5
    800038bc:	ffffe097          	auipc	ra,0xffffe
    800038c0:	02c080e7          	jalr	44(ra) # 800018e8 <free_page>
        p->kstack = 0;
    800038c4:	fe843783          	ld	a5,-24(s0)
    800038c8:	0807b423          	sd	zero,136(a5)
    }
    
    p->pid = 0;
    800038cc:	fe843783          	ld	a5,-24(s0)
    800038d0:	0007a023          	sw	zero,0(a5)
    p->parent = 0;
    800038d4:	fe843783          	ld	a5,-24(s0)
    800038d8:	0a07b023          	sd	zero,160(a5)
    p->name[0] = 0;
    800038dc:	fe843783          	ld	a5,-24(s0)
    800038e0:	00078423          	sb	zero,8(a5)
    p->killed = 0;
    800038e4:	fe843783          	ld	a5,-24(s0)
    800038e8:	0a07ac23          	sw	zero,184(a5)
    p->xstate = 0;
    800038ec:	fe843783          	ld	a5,-24(s0)
    800038f0:	0a07a423          	sw	zero,168(a5)
    p->chan = 0;
    800038f4:	fe843783          	ld	a5,-24(s0)
    800038f8:	0a07b823          	sd	zero,176(a5)
    p->run_time = 0;
    800038fc:	fe843783          	ld	a5,-24(s0)
    80003900:	0807b823          	sd	zero,144(a5)
    p->create_time = 0;
    80003904:	fe843783          	ld	a5,-24(s0)
    80003908:	0807bc23          	sd	zero,152(a5)
    p->pagetable = 0;
    8000390c:	fe843783          	ld	a5,-24(s0)
    80003910:	0c07b023          	sd	zero,192(a5)
    p->state = UNUSED;
    80003914:	fe843783          	ld	a5,-24(s0)
    80003918:	0007a223          	sw	zero,4(a5)
}
    8000391c:	0001                	nop
    8000391e:	60e2                	ld	ra,24(sp)
    80003920:	6442                	ld	s0,16(sp)
    80003922:	6105                	add	sp,sp,32
    80003924:	8082                	ret

0000000080003926 <create_kthread>:

// ==================== 创建内核线程 ====================
int create_kthread(void (*fn)(void), char *name)
{
    80003926:	7179                	add	sp,sp,-48
    80003928:	f406                	sd	ra,40(sp)
    8000392a:	f022                	sd	s0,32(sp)
    8000392c:	1800                	add	s0,sp,48
    8000392e:	fca43c23          	sd	a0,-40(s0)
    80003932:	fcb43823          	sd	a1,-48(s0)
    struct proc *p = alloc_proc();
    80003936:	00000097          	auipc	ra,0x0
    8000393a:	e76080e7          	jalr	-394(ra) # 800037ac <alloc_proc>
    8000393e:	fea43023          	sd	a0,-32(s0)
    if(p == 0) {
    80003942:	fe043783          	ld	a5,-32(s0)
    80003946:	e399                	bnez	a5,8000394c <create_kthread+0x26>
        return -1;
    80003948:	57fd                	li	a5,-1
    8000394a:	a865                	j	80003a02 <create_kthread+0xdc>
    }
    
    int i;
    for(i = 0; name[i] && i < 15; i++) {
    8000394c:	fe042623          	sw	zero,-20(s0)
    80003950:	a025                	j	80003978 <create_kthread+0x52>
        p->name[i] = name[i];
    80003952:	fec42783          	lw	a5,-20(s0)
    80003956:	fd043703          	ld	a4,-48(s0)
    8000395a:	97ba                	add	a5,a5,a4
    8000395c:	0007c703          	lbu	a4,0(a5)
    80003960:	fe043683          	ld	a3,-32(s0)
    80003964:	fec42783          	lw	a5,-20(s0)
    80003968:	97b6                	add	a5,a5,a3
    8000396a:	00e78423          	sb	a4,8(a5)
    for(i = 0; name[i] && i < 15; i++) {
    8000396e:	fec42783          	lw	a5,-20(s0)
    80003972:	2785                	addw	a5,a5,1
    80003974:	fef42623          	sw	a5,-20(s0)
    80003978:	fec42783          	lw	a5,-20(s0)
    8000397c:	fd043703          	ld	a4,-48(s0)
    80003980:	97ba                	add	a5,a5,a4
    80003982:	0007c783          	lbu	a5,0(a5)
    80003986:	cb81                	beqz	a5,80003996 <create_kthread+0x70>
    80003988:	fec42783          	lw	a5,-20(s0)
    8000398c:	0007871b          	sext.w	a4,a5
    80003990:	47b9                	li	a5,14
    80003992:	fce7d0e3          	bge	a5,a4,80003952 <create_kthread+0x2c>
    }
    p->name[i] = 0;
    80003996:	fe043703          	ld	a4,-32(s0)
    8000399a:	fec42783          	lw	a5,-20(s0)
    8000399e:	97ba                	add	a5,a5,a4
    800039a0:	00078423          	sb	zero,8(a5)
    
    memset(&p->context, 0, sizeof(p->context));
    800039a4:	fe043783          	ld	a5,-32(s0)
    800039a8:	07e1                	add	a5,a5,24
    800039aa:	07000613          	li	a2,112
    800039ae:	4581                	li	a1,0
    800039b0:	853e                	mv	a0,a5
    800039b2:	ffffe097          	auipc	ra,0xffffe
    800039b6:	d68080e7          	jalr	-664(ra) # 8000171a <memset>
    p->context.ra = (uint64)fn;
    800039ba:	fd843703          	ld	a4,-40(s0)
    800039be:	fe043783          	ld	a5,-32(s0)
    800039c2:	ef98                	sd	a4,24(a5)
    p->context.sp = p->kstack + KSTACK_SIZE;
    800039c4:	fe043783          	ld	a5,-32(s0)
    800039c8:	67d8                	ld	a4,136(a5)
    800039ca:	6785                	lui	a5,0x1
    800039cc:	973e                	add	a4,a4,a5
    800039ce:	fe043783          	ld	a5,-32(s0)
    800039d2:	f398                	sd	a4,32(a5)
    
    p->state = RUNNABLE;
    800039d4:	fe043783          	ld	a5,-32(s0)
    800039d8:	4709                	li	a4,2
    800039da:	c3d8                	sw	a4,4(a5)
    
    printf("Created kernel thread: PID=%d, name=%s\n", p->pid, p->name);
    800039dc:	fe043783          	ld	a5,-32(s0)
    800039e0:	4398                	lw	a4,0(a5)
    800039e2:	fe043783          	ld	a5,-32(s0)
    800039e6:	07a1                	add	a5,a5,8 # 1008 <_start-0x7fffeff8>
    800039e8:	863e                	mv	a2,a5
    800039ea:	85ba                	mv	a1,a4
    800039ec:	00003517          	auipc	a0,0x3
    800039f0:	07c50513          	add	a0,a0,124 # 80006a68 <etext+0x1a68>
    800039f4:	ffffd097          	auipc	ra,0xffffd
    800039f8:	7fe080e7          	jalr	2046(ra) # 800011f2 <printf>
    
    return p->pid;
    800039fc:	fe043783          	ld	a5,-32(s0)
    80003a00:	439c                	lw	a5,0(a5)
}
    80003a02:	853e                	mv	a0,a5
    80003a04:	70a2                	ld	ra,40(sp)
    80003a06:	7402                	ld	s0,32(sp)
    80003a08:	6145                	add	sp,sp,48
    80003a0a:	8082                	ret

0000000080003a0c <push_off>:

// ==================== 中断控制 ====================
void push_off(void)
{
    80003a0c:	1101                	add	sp,sp,-32
    80003a0e:	ec06                	sd	ra,24(sp)
    80003a10:	e822                	sd	s0,16(sp)
    80003a12:	1000                	add	s0,sp,32
    int old = r_sstatus() & SSTATUS_SIE;
    80003a14:	00000097          	auipc	ra,0x0
    80003a18:	b6e080e7          	jalr	-1170(ra) # 80003582 <r_sstatus>
    80003a1c:	87aa                	mv	a5,a0
    80003a1e:	2781                	sext.w	a5,a5
    80003a20:	8b89                	and	a5,a5,2
    80003a22:	fef42623          	sw	a5,-20(s0)
    w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80003a26:	00000097          	auipc	ra,0x0
    80003a2a:	b5c080e7          	jalr	-1188(ra) # 80003582 <r_sstatus>
    80003a2e:	87aa                	mv	a5,a0
    80003a30:	9bf5                	and	a5,a5,-3
    80003a32:	853e                	mv	a0,a5
    80003a34:	00000097          	auipc	ra,0x0
    80003a38:	b68080e7          	jalr	-1176(ra) # 8000359c <w_sstatus>
    
    struct cpu *c = &cpus[0];
    80003a3c:	0000c797          	auipc	a5,0xc
    80003a40:	94478793          	add	a5,a5,-1724 # 8000f380 <cpus>
    80003a44:	fef43023          	sd	a5,-32(s0)
    if(c->noff == 0) {
    80003a48:	fe043783          	ld	a5,-32(s0)
    80003a4c:	5fbc                	lw	a5,120(a5)
    80003a4e:	e791                	bnez	a5,80003a5a <push_off+0x4e>
        c->intena = old;
    80003a50:	fe043783          	ld	a5,-32(s0)
    80003a54:	fec42703          	lw	a4,-20(s0)
    80003a58:	dff8                	sw	a4,124(a5)
    }
    c->noff += 1;
    80003a5a:	fe043783          	ld	a5,-32(s0)
    80003a5e:	5fbc                	lw	a5,120(a5)
    80003a60:	2785                	addw	a5,a5,1
    80003a62:	0007871b          	sext.w	a4,a5
    80003a66:	fe043783          	ld	a5,-32(s0)
    80003a6a:	dfb8                	sw	a4,120(a5)
}
    80003a6c:	0001                	nop
    80003a6e:	60e2                	ld	ra,24(sp)
    80003a70:	6442                	ld	s0,16(sp)
    80003a72:	6105                	add	sp,sp,32
    80003a74:	8082                	ret

0000000080003a76 <pop_off>:

void pop_off(void)
{
    80003a76:	1101                	add	sp,sp,-32
    80003a78:	ec06                	sd	ra,24(sp)
    80003a7a:	e822                	sd	s0,16(sp)
    80003a7c:	1000                	add	s0,sp,32
    struct cpu *c = &cpus[0];
    80003a7e:	0000c797          	auipc	a5,0xc
    80003a82:	90278793          	add	a5,a5,-1790 # 8000f380 <cpus>
    80003a86:	fef43423          	sd	a5,-24(s0)
    
    if((r_sstatus() & SSTATUS_SIE) != 0) {
    80003a8a:	00000097          	auipc	ra,0x0
    80003a8e:	af8080e7          	jalr	-1288(ra) # 80003582 <r_sstatus>
    80003a92:	87aa                	mv	a5,a0
    80003a94:	8b89                	and	a5,a5,2
    80003a96:	cb89                	beqz	a5,80003aa8 <pop_off+0x32>
        panic("pop_off: interruptible");
    80003a98:	00003517          	auipc	a0,0x3
    80003a9c:	ff850513          	add	a0,a0,-8 # 80006a90 <etext+0x1a90>
    80003aa0:	ffffe097          	auipc	ra,0xffffe
    80003aa4:	af8080e7          	jalr	-1288(ra) # 80001598 <panic>
    }
    if(c->noff < 1) {
    80003aa8:	fe843783          	ld	a5,-24(s0)
    80003aac:	5fbc                	lw	a5,120(a5)
    80003aae:	00f04a63          	bgtz	a5,80003ac2 <pop_off+0x4c>
        panic("pop_off");
    80003ab2:	00003517          	auipc	a0,0x3
    80003ab6:	ff650513          	add	a0,a0,-10 # 80006aa8 <etext+0x1aa8>
    80003aba:	ffffe097          	auipc	ra,0xffffe
    80003abe:	ade080e7          	jalr	-1314(ra) # 80001598 <panic>
    }
    
    c->noff -= 1;
    80003ac2:	fe843783          	ld	a5,-24(s0)
    80003ac6:	5fbc                	lw	a5,120(a5)
    80003ac8:	37fd                	addw	a5,a5,-1
    80003aca:	0007871b          	sext.w	a4,a5
    80003ace:	fe843783          	ld	a5,-24(s0)
    80003ad2:	dfb8                	sw	a4,120(a5)
    if(c->noff == 0 && c->intena) {
    80003ad4:	fe843783          	ld	a5,-24(s0)
    80003ad8:	5fbc                	lw	a5,120(a5)
    80003ada:	e38d                	bnez	a5,80003afc <pop_off+0x86>
    80003adc:	fe843783          	ld	a5,-24(s0)
    80003ae0:	5ffc                	lw	a5,124(a5)
    80003ae2:	cf89                	beqz	a5,80003afc <pop_off+0x86>
        w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003ae4:	00000097          	auipc	ra,0x0
    80003ae8:	a9e080e7          	jalr	-1378(ra) # 80003582 <r_sstatus>
    80003aec:	87aa                	mv	a5,a0
    80003aee:	0027e793          	or	a5,a5,2
    80003af2:	853e                	mv	a0,a5
    80003af4:	00000097          	auipc	ra,0x0
    80003af8:	aa8080e7          	jalr	-1368(ra) # 8000359c <w_sstatus>
    }
}
    80003afc:	0001                	nop
    80003afe:	60e2                	ld	ra,24(sp)
    80003b00:	6442                	ld	s0,16(sp)
    80003b02:	6105                	add	sp,sp,32
    80003b04:	8082                	ret

0000000080003b06 <yield>:

// ==================== 主动放弃CPU ====================
void yield(void)
{
    80003b06:	1101                	add	sp,sp,-32
    80003b08:	ec06                	sd	ra,24(sp)
    80003b0a:	e822                	sd	s0,16(sp)
    80003b0c:	1000                	add	s0,sp,32
    struct proc *p = myproc();
    80003b0e:	00000097          	auipc	ra,0x0
    80003b12:	c62080e7          	jalr	-926(ra) # 80003770 <myproc>
    80003b16:	fea43423          	sd	a0,-24(s0)
    if(p == 0) return;
    80003b1a:	fe843783          	ld	a5,-24(s0)
    80003b1e:	cf9d                	beqz	a5,80003b5c <yield+0x56>

    // ★ 若当前进程已被kill标记，直接退出（不会返回）
    if(p->killed) {
    80003b20:	fe843783          	ld	a5,-24(s0)
    80003b24:	0b87a783          	lw	a5,184(a5)
    80003b28:	c791                	beqz	a5,80003b34 <yield+0x2e>
        exit_proc(-1);
    80003b2a:	557d                	li	a0,-1
    80003b2c:	00000097          	auipc	ra,0x0
    80003b30:	46a080e7          	jalr	1130(ra) # 80003f96 <exit_proc>
    }
    
    w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80003b34:	00000097          	auipc	ra,0x0
    80003b38:	a4e080e7          	jalr	-1458(ra) # 80003582 <r_sstatus>
    80003b3c:	87aa                	mv	a5,a0
    80003b3e:	9bf5                	and	a5,a5,-3
    80003b40:	853e                	mv	a0,a5
    80003b42:	00000097          	auipc	ra,0x0
    80003b46:	a5a080e7          	jalr	-1446(ra) # 8000359c <w_sstatus>
    
    p->state = RUNNABLE;
    80003b4a:	fe843783          	ld	a5,-24(s0)
    80003b4e:	4709                	li	a4,2
    80003b50:	c3d8                	sw	a4,4(a5)
    sched();
    80003b52:	00000097          	auipc	ra,0x0
    80003b56:	014080e7          	jalr	20(ra) # 80003b66 <sched>
    80003b5a:	a011                	j	80003b5e <yield+0x58>
    if(p == 0) return;
    80003b5c:	0001                	nop
}
    80003b5e:	60e2                	ld	ra,24(sp)
    80003b60:	6442                	ld	s0,16(sp)
    80003b62:	6105                	add	sp,sp,32
    80003b64:	8082                	ret

0000000080003b66 <sched>:

// ==================== 切换到调度器 ====================
void sched(void)
{
    80003b66:	7179                	add	sp,sp,-48
    80003b68:	f406                	sd	ra,40(sp)
    80003b6a:	f022                	sd	s0,32(sp)
    80003b6c:	1800                	add	s0,sp,48
    struct proc *p = myproc();
    80003b6e:	00000097          	auipc	ra,0x0
    80003b72:	c02080e7          	jalr	-1022(ra) # 80003770 <myproc>
    80003b76:	fea43423          	sd	a0,-24(s0)
    struct cpu *c = mycpu();
    80003b7a:	00000097          	auipc	ra,0x0
    80003b7e:	be0080e7          	jalr	-1056(ra) # 8000375a <mycpu>
    80003b82:	fea43023          	sd	a0,-32(s0)
    
    int intena = c->intena;
    80003b86:	fe043783          	ld	a5,-32(s0)
    80003b8a:	5ffc                	lw	a5,124(a5)
    80003b8c:	fcf42e23          	sw	a5,-36(s0)
    total_switches++;  // 统计切换次数
    80003b90:	0000c797          	auipc	a5,0xc
    80003b94:	87078793          	add	a5,a5,-1936 # 8000f400 <total_switches>
    80003b98:	639c                	ld	a5,0(a5)
    80003b9a:	00178713          	add	a4,a5,1
    80003b9e:	0000c797          	auipc	a5,0xc
    80003ba2:	86278793          	add	a5,a5,-1950 # 8000f400 <total_switches>
    80003ba6:	e398                	sd	a4,0(a5)
    swtch(&p->context, &c->context);
    80003ba8:	fe843783          	ld	a5,-24(s0)
    80003bac:	01878713          	add	a4,a5,24
    80003bb0:	fe043783          	ld	a5,-32(s0)
    80003bb4:	07a1                	add	a5,a5,8
    80003bb6:	85be                	mv	a1,a5
    80003bb8:	853a                	mv	a0,a4
    80003bba:	00001097          	auipc	ra,0x1
    80003bbe:	880080e7          	jalr	-1920(ra) # 8000443a <swtch>
    c->intena = intena;
    80003bc2:	fe043783          	ld	a5,-32(s0)
    80003bc6:	fdc42703          	lw	a4,-36(s0)
    80003bca:	dff8                	sw	a4,124(a5)
}
    80003bcc:	0001                	nop
    80003bce:	70a2                	ld	ra,40(sp)
    80003bd0:	7402                	ld	s0,32(sp)
    80003bd2:	6145                	add	sp,sp,48
    80003bd4:	8082                	ret

0000000080003bd6 <scheduler>:

// ==================== 调度器主循环 ====================
void scheduler(void)
{
    80003bd6:	7179                	add	sp,sp,-48
    80003bd8:	f406                	sd	ra,40(sp)
    80003bda:	f022                	sd	s0,32(sp)
    80003bdc:	1800                	add	s0,sp,48
    struct proc *p;
    struct cpu *c = mycpu();
    80003bde:	00000097          	auipc	ra,0x0
    80003be2:	b7c080e7          	jalr	-1156(ra) # 8000375a <mycpu>
    80003be6:	fca43c23          	sd	a0,-40(s0)
    
    printf("Scheduler started\n");
    80003bea:	00003517          	auipc	a0,0x3
    80003bee:	ec650513          	add	a0,a0,-314 # 80006ab0 <etext+0x1ab0>
    80003bf2:	ffffd097          	auipc	ra,0xffffd
    80003bf6:	600080e7          	jalr	1536(ra) # 800011f2 <printf>
    
    c->proc = 0;
    80003bfa:	fd843783          	ld	a5,-40(s0)
    80003bfe:	0007b023          	sd	zero,0(a5)
    
    for(;;) {
        // 开启中断
        w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003c02:	00000097          	auipc	ra,0x0
    80003c06:	980080e7          	jalr	-1664(ra) # 80003582 <r_sstatus>
    80003c0a:	87aa                	mv	a5,a0
    80003c0c:	0027e793          	or	a5,a5,2
    80003c10:	853e                	mv	a0,a5
    80003c12:	00000097          	auipc	ra,0x0
    80003c16:	98a080e7          	jalr	-1654(ra) # 8000359c <w_sstatus>
        
        // 检查是否所有进程都结束
        int has_runnable = 0;
    80003c1a:	fe042223          	sw	zero,-28(s0)
        for(p = proc; p < &proc[NPROC]; p++) {
    80003c1e:	00008797          	auipc	a5,0x8
    80003c22:	56278793          	add	a5,a5,1378 # 8000c180 <proc>
    80003c26:	fef43423          	sd	a5,-24(s0)
    80003c2a:	a081                	j	80003c6a <scheduler+0x94>
            if(p->state == RUNNABLE || p->state == RUNNING || p->state == SLEEPING) {
    80003c2c:	fe843783          	ld	a5,-24(s0)
    80003c30:	43dc                	lw	a5,4(a5)
    80003c32:	873e                	mv	a4,a5
    80003c34:	4789                	li	a5,2
    80003c36:	02f70063          	beq	a4,a5,80003c56 <scheduler+0x80>
    80003c3a:	fe843783          	ld	a5,-24(s0)
    80003c3e:	43dc                	lw	a5,4(a5)
    80003c40:	873e                	mv	a4,a5
    80003c42:	478d                	li	a5,3
    80003c44:	00f70963          	beq	a4,a5,80003c56 <scheduler+0x80>
    80003c48:	fe843783          	ld	a5,-24(s0)
    80003c4c:	43dc                	lw	a5,4(a5)
    80003c4e:	873e                	mv	a4,a5
    80003c50:	4791                	li	a5,4
    80003c52:	00f71663          	bne	a4,a5,80003c5e <scheduler+0x88>
                has_runnable = 1;
    80003c56:	4785                	li	a5,1
    80003c58:	fef42223          	sw	a5,-28(s0)
                break;
    80003c5c:	a839                	j	80003c7a <scheduler+0xa4>
        for(p = proc; p < &proc[NPROC]; p++) {
    80003c5e:	fe843783          	ld	a5,-24(s0)
    80003c62:	0c878793          	add	a5,a5,200
    80003c66:	fef43423          	sd	a5,-24(s0)
    80003c6a:	fe843703          	ld	a4,-24(s0)
    80003c6e:	0000b797          	auipc	a5,0xb
    80003c72:	71278793          	add	a5,a5,1810 # 8000f380 <cpus>
    80003c76:	faf76be3          	bltu	a4,a5,80003c2c <scheduler+0x56>
            }
        }
        
        if(!has_runnable) {
    80003c7a:	fe442783          	lw	a5,-28(s0)
    80003c7e:	2781                	sext.w	a5,a5
    80003c80:	eba5                	bnez	a5,80003cf0 <scheduler+0x11a>
            printf("\n=== All Processes Completed ===\n");
    80003c82:	00003517          	auipc	a0,0x3
    80003c86:	e4650513          	add	a0,a0,-442 # 80006ac8 <etext+0x1ac8>
    80003c8a:	ffffd097          	auipc	ra,0xffffd
    80003c8e:	568080e7          	jalr	1384(ra) # 800011f2 <printf>
            printf("Total context switches: %d\n", (int)total_switches);
    80003c92:	0000b797          	auipc	a5,0xb
    80003c96:	76e78793          	add	a5,a5,1902 # 8000f400 <total_switches>
    80003c9a:	639c                	ld	a5,0(a5)
    80003c9c:	2781                	sext.w	a5,a5
    80003c9e:	85be                	mv	a1,a5
    80003ca0:	00003517          	auipc	a0,0x3
    80003ca4:	e5050513          	add	a0,a0,-432 # 80006af0 <etext+0x1af0>
    80003ca8:	ffffd097          	auipc	ra,0xffffd
    80003cac:	54a080e7          	jalr	1354(ra) # 800011f2 <printf>
            printf("System will continue running (timer interrupts active)\n");
    80003cb0:	00003517          	auipc	a0,0x3
    80003cb4:	e6050513          	add	a0,a0,-416 # 80006b10 <etext+0x1b10>
    80003cb8:	ffffd097          	auipc	ra,0xffffd
    80003cbc:	53a080e7          	jalr	1338(ra) # 800011f2 <printf>
            printf("Press Ctrl+A then X to exit QEMU\n");
    80003cc0:	00003517          	auipc	a0,0x3
    80003cc4:	e8850513          	add	a0,a0,-376 # 80006b48 <etext+0x1b48>
    80003cc8:	ffffd097          	auipc	ra,0xffffd
    80003ccc:	52a080e7          	jalr	1322(ra) # 800011f2 <printf>
            
            // 继续运行，等待中断
            for(;;) {
                w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003cd0:	00000097          	auipc	ra,0x0
    80003cd4:	8b2080e7          	jalr	-1870(ra) # 80003582 <r_sstatus>
    80003cd8:	87aa                	mv	a5,a0
    80003cda:	0027e793          	or	a5,a5,2
    80003cde:	853e                	mv	a0,a5
    80003ce0:	00000097          	auipc	ra,0x0
    80003ce4:	8bc080e7          	jalr	-1860(ra) # 8000359c <w_sstatus>
                asm volatile("wfi");  // 等待中断
    80003ce8:	10500073          	wfi
                w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003cec:	0001                	nop
    80003cee:	b7cd                	j	80003cd0 <scheduler+0xfa>
            }
        }
        
        // 遍历进程表
        for(p = proc; p < &proc[NPROC]; p++) {
    80003cf0:	00008797          	auipc	a5,0x8
    80003cf4:	49078793          	add	a5,a5,1168 # 8000c180 <proc>
    80003cf8:	fef43423          	sd	a5,-24(s0)
    80003cfc:	a0ad                	j	80003d66 <scheduler+0x190>
            if(p->state != RUNNABLE) {
    80003cfe:	fe843783          	ld	a5,-24(s0)
    80003d02:	43dc                	lw	a5,4(a5)
    80003d04:	873e                	mv	a4,a5
    80003d06:	4789                	li	a5,2
    80003d08:	04f71863          	bne	a4,a5,80003d58 <scheduler+0x182>
                continue;
            }
            
            // 切换前关闭中断
            w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80003d0c:	00000097          	auipc	ra,0x0
    80003d10:	876080e7          	jalr	-1930(ra) # 80003582 <r_sstatus>
    80003d14:	87aa                	mv	a5,a0
    80003d16:	9bf5                	and	a5,a5,-3
    80003d18:	853e                	mv	a0,a5
    80003d1a:	00000097          	auipc	ra,0x0
    80003d1e:	882080e7          	jalr	-1918(ra) # 8000359c <w_sstatus>
            
            p->state = RUNNING;
    80003d22:	fe843783          	ld	a5,-24(s0)
    80003d26:	470d                	li	a4,3
    80003d28:	c3d8                	sw	a4,4(a5)
            c->proc = p;
    80003d2a:	fd843783          	ld	a5,-40(s0)
    80003d2e:	fe843703          	ld	a4,-24(s0)
    80003d32:	e398                	sd	a4,0(a5)
            
            swtch(&c->context, &p->context);
    80003d34:	fd843783          	ld	a5,-40(s0)
    80003d38:	00878713          	add	a4,a5,8
    80003d3c:	fe843783          	ld	a5,-24(s0)
    80003d40:	07e1                	add	a5,a5,24
    80003d42:	85be                	mv	a1,a5
    80003d44:	853a                	mv	a0,a4
    80003d46:	00000097          	auipc	ra,0x0
    80003d4a:	6f4080e7          	jalr	1780(ra) # 8000443a <swtch>
            
            c->proc = 0;
    80003d4e:	fd843783          	ld	a5,-40(s0)
    80003d52:	0007b023          	sd	zero,0(a5)
    80003d56:	a011                	j	80003d5a <scheduler+0x184>
                continue;
    80003d58:	0001                	nop
        for(p = proc; p < &proc[NPROC]; p++) {
    80003d5a:	fe843783          	ld	a5,-24(s0)
    80003d5e:	0c878793          	add	a5,a5,200
    80003d62:	fef43423          	sd	a5,-24(s0)
    80003d66:	fe843703          	ld	a4,-24(s0)
    80003d6a:	0000b797          	auipc	a5,0xb
    80003d6e:	61678793          	add	a5,a5,1558 # 8000f380 <cpus>
    80003d72:	f8f766e3          	bltu	a4,a5,80003cfe <scheduler+0x128>
    for(;;) {
    80003d76:	b571                	j	80003c02 <scheduler+0x2c>

0000000080003d78 <sleep>:
    }
}

// ==================== 睡眠等待（支持通道）====================
void sleep(void *chan)
{
    80003d78:	7179                	add	sp,sp,-48
    80003d7a:	f406                	sd	ra,40(sp)
    80003d7c:	f022                	sd	s0,32(sp)
    80003d7e:	1800                	add	s0,sp,48
    80003d80:	fca43c23          	sd	a0,-40(s0)
    struct proc *p = myproc();
    80003d84:	00000097          	auipc	ra,0x0
    80003d88:	9ec080e7          	jalr	-1556(ra) # 80003770 <myproc>
    80003d8c:	fea43423          	sd	a0,-24(s0)
    if(p == 0) {
    80003d90:	fe843783          	ld	a5,-24(s0)
    80003d94:	eb89                	bnez	a5,80003da6 <sleep+0x2e>
        panic("sleep: no process");
    80003d96:	00003517          	auipc	a0,0x3
    80003d9a:	dda50513          	add	a0,a0,-550 # 80006b70 <etext+0x1b70>
    80003d9e:	ffffd097          	auipc	ra,0xffffd
    80003da2:	7fa080e7          	jalr	2042(ra) # 80001598 <panic>
    }
    
    // 关闭中断，保证原子性
    w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80003da6:	fffff097          	auipc	ra,0xfffff
    80003daa:	7dc080e7          	jalr	2012(ra) # 80003582 <r_sstatus>
    80003dae:	87aa                	mv	a5,a0
    80003db0:	9bf5                	and	a5,a5,-3
    80003db2:	853e                	mv	a0,a5
    80003db4:	fffff097          	auipc	ra,0xfffff
    80003db8:	7e8080e7          	jalr	2024(ra) # 8000359c <w_sstatus>
    
    p->chan = chan;
    80003dbc:	fe843783          	ld	a5,-24(s0)
    80003dc0:	fd843703          	ld	a4,-40(s0)
    80003dc4:	fbd8                	sd	a4,176(a5)
    p->state = SLEEPING;
    80003dc6:	fe843783          	ld	a5,-24(s0)
    80003dca:	4711                	li	a4,4
    80003dcc:	c3d8                	sw	a4,4(a5)
    
    sched();  // 切换到调度器
    80003dce:	00000097          	auipc	ra,0x0
    80003dd2:	d98080e7          	jalr	-616(ra) # 80003b66 <sched>
    
    // 被唤醒后继续执行
    p->chan = 0;
    80003dd6:	fe843783          	ld	a5,-24(s0)
    80003dda:	0a07b823          	sd	zero,176(a5)

    // ★ 如果在睡眠期间被kill，醒来后立刻退出
    if(p->killed) {
    80003dde:	fe843783          	ld	a5,-24(s0)
    80003de2:	0b87a783          	lw	a5,184(a5)
    80003de6:	c791                	beqz	a5,80003df2 <sleep+0x7a>
        exit_proc(-1);
    80003de8:	557d                	li	a0,-1
    80003dea:	00000097          	auipc	ra,0x0
    80003dee:	1ac080e7          	jalr	428(ra) # 80003f96 <exit_proc>
    }
}
    80003df2:	0001                	nop
    80003df4:	70a2                	ld	ra,40(sp)
    80003df6:	7402                	ld	s0,32(sp)
    80003df8:	6145                	add	sp,sp,48
    80003dfa:	8082                	ret

0000000080003dfc <wakeup>:

// ==================== 唤醒等待进程 ====================
void wakeup(void *chan)
{
    80003dfc:	7179                	add	sp,sp,-48
    80003dfe:	f422                	sd	s0,40(sp)
    80003e00:	1800                	add	s0,sp,48
    80003e02:	fca43c23          	sd	a0,-40(s0)
    struct proc *p;
    
    for(p = proc; p < &proc[NPROC]; p++) {
    80003e06:	00008797          	auipc	a5,0x8
    80003e0a:	37a78793          	add	a5,a5,890 # 8000c180 <proc>
    80003e0e:	fef43423          	sd	a5,-24(s0)
    80003e12:	a80d                	j	80003e44 <wakeup+0x48>
        if(p->state == SLEEPING && p->chan == chan) {
    80003e14:	fe843783          	ld	a5,-24(s0)
    80003e18:	43dc                	lw	a5,4(a5)
    80003e1a:	873e                	mv	a4,a5
    80003e1c:	4791                	li	a5,4
    80003e1e:	00f71d63          	bne	a4,a5,80003e38 <wakeup+0x3c>
    80003e22:	fe843783          	ld	a5,-24(s0)
    80003e26:	7bdc                	ld	a5,176(a5)
    80003e28:	fd843703          	ld	a4,-40(s0)
    80003e2c:	00f71663          	bne	a4,a5,80003e38 <wakeup+0x3c>
            p->state = RUNNABLE;
    80003e30:	fe843783          	ld	a5,-24(s0)
    80003e34:	4709                	li	a4,2
    80003e36:	c3d8                	sw	a4,4(a5)
    for(p = proc; p < &proc[NPROC]; p++) {
    80003e38:	fe843783          	ld	a5,-24(s0)
    80003e3c:	0c878793          	add	a5,a5,200
    80003e40:	fef43423          	sd	a5,-24(s0)
    80003e44:	fe843703          	ld	a4,-24(s0)
    80003e48:	0000b797          	auipc	a5,0xb
    80003e4c:	53878793          	add	a5,a5,1336 # 8000f380 <cpus>
    80003e50:	fcf762e3          	bltu	a4,a5,80003e14 <wakeup+0x18>
        }
    }
}
    80003e54:	0001                	nop
    80003e56:	0001                	nop
    80003e58:	7422                	ld	s0,40(sp)
    80003e5a:	6145                	add	sp,sp,48
    80003e5c:	8082                	ret

0000000080003e5e <kill_children>:

// ==================== 递归标记并唤醒子进程 ====================
// 当父进程被exit/kill时，调用该函数递归处理整棵子树
static void kill_children(struct proc *parent)
{
    80003e5e:	7179                	add	sp,sp,-48
    80003e60:	f406                	sd	ra,40(sp)
    80003e62:	f022                	sd	s0,32(sp)
    80003e64:	1800                	add	s0,sp,48
    80003e66:	fca43c23          	sd	a0,-40(s0)
    struct proc *p;
    
    for(p = proc; p < &proc[NPROC]; p++) {
    80003e6a:	00008797          	auipc	a5,0x8
    80003e6e:	31678793          	add	a5,a5,790 # 8000c180 <proc>
    80003e72:	fef43423          	sd	a5,-24(s0)
    80003e76:	a8b9                	j	80003ed4 <kill_children+0x76>
        if(p->parent == parent && p->state != UNUSED && p->state != ZOMBIE) {
    80003e78:	fe843783          	ld	a5,-24(s0)
    80003e7c:	73dc                	ld	a5,160(a5)
    80003e7e:	fd843703          	ld	a4,-40(s0)
    80003e82:	04f71363          	bne	a4,a5,80003ec8 <kill_children+0x6a>
    80003e86:	fe843783          	ld	a5,-24(s0)
    80003e8a:	43dc                	lw	a5,4(a5)
    80003e8c:	cf95                	beqz	a5,80003ec8 <kill_children+0x6a>
    80003e8e:	fe843783          	ld	a5,-24(s0)
    80003e92:	43dc                	lw	a5,4(a5)
    80003e94:	873e                	mv	a4,a5
    80003e96:	4795                	li	a5,5
    80003e98:	02f70863          	beq	a4,a5,80003ec8 <kill_children+0x6a>
            p->killed = 1;
    80003e9c:	fe843783          	ld	a5,-24(s0)
    80003ea0:	4705                	li	a4,1
    80003ea2:	0ae7ac23          	sw	a4,184(a5)
            // 如果子进程在睡眠，唤醒它，让它有机会检查 killed 并退出
            if(p->state == SLEEPING) {
    80003ea6:	fe843783          	ld	a5,-24(s0)
    80003eaa:	43dc                	lw	a5,4(a5)
    80003eac:	873e                	mv	a4,a5
    80003eae:	4791                	li	a5,4
    80003eb0:	00f71663          	bne	a4,a5,80003ebc <kill_children+0x5e>
                p->state = RUNNABLE;
    80003eb4:	fe843783          	ld	a5,-24(s0)
    80003eb8:	4709                	li	a4,2
    80003eba:	c3d8                	sw	a4,4(a5)
            }
            // 递归处理孙子/曾孙
            kill_children(p);
    80003ebc:	fe843503          	ld	a0,-24(s0)
    80003ec0:	00000097          	auipc	ra,0x0
    80003ec4:	f9e080e7          	jalr	-98(ra) # 80003e5e <kill_children>
    for(p = proc; p < &proc[NPROC]; p++) {
    80003ec8:	fe843783          	ld	a5,-24(s0)
    80003ecc:	0c878793          	add	a5,a5,200
    80003ed0:	fef43423          	sd	a5,-24(s0)
    80003ed4:	fe843703          	ld	a4,-24(s0)
    80003ed8:	0000b797          	auipc	a5,0xb
    80003edc:	4a878793          	add	a5,a5,1192 # 8000f380 <cpus>
    80003ee0:	f8f76ce3          	bltu	a4,a5,80003e78 <kill_children+0x1a>
        }
    }
}
    80003ee4:	0001                	nop
    80003ee6:	0001                	nop
    80003ee8:	70a2                	ld	ra,40(sp)
    80003eea:	7402                	ld	s0,32(sp)
    80003eec:	6145                	add	sp,sp,48
    80003eee:	8082                	ret

0000000080003ef0 <kill_proc>:

// ==================== 按PID杀死进程（递归杀死子进程树）====================
int kill_proc(int pid)
{
    80003ef0:	7179                	add	sp,sp,-48
    80003ef2:	f406                	sd	ra,40(sp)
    80003ef4:	f022                	sd	s0,32(sp)
    80003ef6:	1800                	add	s0,sp,48
    80003ef8:	87aa                	mv	a5,a0
    80003efa:	fcf42e23          	sw	a5,-36(s0)
    struct proc *p;
    int found = -1;
    80003efe:	57fd                	li	a5,-1
    80003f00:	fef42223          	sw	a5,-28(s0)

    push_off();  // 关闭中断，防止与调度器竞争
    80003f04:	00000097          	auipc	ra,0x0
    80003f08:	b08080e7          	jalr	-1272(ra) # 80003a0c <push_off>

    for(p = proc; p < &proc[NPROC]; p++) {
    80003f0c:	00008797          	auipc	a5,0x8
    80003f10:	27478793          	add	a5,a5,628 # 8000c180 <proc>
    80003f14:	fef43423          	sd	a5,-24(s0)
    80003f18:	a8a1                	j	80003f70 <kill_proc+0x80>
        if(p->pid == pid && p->state != UNUSED) {
    80003f1a:	fe843783          	ld	a5,-24(s0)
    80003f1e:	4398                	lw	a4,0(a5)
    80003f20:	fdc42783          	lw	a5,-36(s0)
    80003f24:	2781                	sext.w	a5,a5
    80003f26:	02e79f63          	bne	a5,a4,80003f64 <kill_proc+0x74>
    80003f2a:	fe843783          	ld	a5,-24(s0)
    80003f2e:	43dc                	lw	a5,4(a5)
    80003f30:	cb95                	beqz	a5,80003f64 <kill_proc+0x74>
            // 标记本进程
            p->killed = 1;
    80003f32:	fe843783          	ld	a5,-24(s0)
    80003f36:	4705                	li	a4,1
    80003f38:	0ae7ac23          	sw	a4,184(a5)
            if(p->state == SLEEPING) {
    80003f3c:	fe843783          	ld	a5,-24(s0)
    80003f40:	43dc                	lw	a5,4(a5)
    80003f42:	873e                	mv	a4,a5
    80003f44:	4791                	li	a5,4
    80003f46:	00f71663          	bne	a4,a5,80003f52 <kill_proc+0x62>
                p->state = RUNNABLE;  // 唤醒以便尽快退出
    80003f4a:	fe843783          	ld	a5,-24(s0)
    80003f4e:	4709                	li	a4,2
    80003f50:	c3d8                	sw	a4,4(a5)
            }

            // 递归标记所有子进程
            kill_children(p);
    80003f52:	fe843503          	ld	a0,-24(s0)
    80003f56:	00000097          	auipc	ra,0x0
    80003f5a:	f08080e7          	jalr	-248(ra) # 80003e5e <kill_children>

            found = 0;
    80003f5e:	fe042223          	sw	zero,-28(s0)
            break;
    80003f62:	a839                	j	80003f80 <kill_proc+0x90>
    for(p = proc; p < &proc[NPROC]; p++) {
    80003f64:	fe843783          	ld	a5,-24(s0)
    80003f68:	0c878793          	add	a5,a5,200
    80003f6c:	fef43423          	sd	a5,-24(s0)
    80003f70:	fe843703          	ld	a4,-24(s0)
    80003f74:	0000b797          	auipc	a5,0xb
    80003f78:	40c78793          	add	a5,a5,1036 # 8000f380 <cpus>
    80003f7c:	f8f76fe3          	bltu	a4,a5,80003f1a <kill_proc+0x2a>
        }
    }

    pop_off();
    80003f80:	00000097          	auipc	ra,0x0
    80003f84:	af6080e7          	jalr	-1290(ra) # 80003a76 <pop_off>

    return found;   // 0=成功，-1=未找到
    80003f88:	fe442783          	lw	a5,-28(s0)
}
    80003f8c:	853e                	mv	a0,a5
    80003f8e:	70a2                	ld	ra,40(sp)
    80003f90:	7402                	ld	s0,32(sp)
    80003f92:	6145                	add	sp,sp,48
    80003f94:	8082                	ret

0000000080003f96 <exit_proc>:

// ==================== 进程退出 ====================
void exit_proc(int status)
{
    80003f96:	7179                	add	sp,sp,-48
    80003f98:	f406                	sd	ra,40(sp)
    80003f9a:	f022                	sd	s0,32(sp)
    80003f9c:	1800                	add	s0,sp,48
    80003f9e:	87aa                	mv	a5,a0
    80003fa0:	fcf42e23          	sw	a5,-36(s0)
    struct proc *p = myproc();
    80003fa4:	fffff097          	auipc	ra,0xfffff
    80003fa8:	7cc080e7          	jalr	1996(ra) # 80003770 <myproc>
    80003fac:	fea43423          	sd	a0,-24(s0)
    if(p == 0) {
    80003fb0:	fe843783          	ld	a5,-24(s0)
    80003fb4:	eb89                	bnez	a5,80003fc6 <exit_proc+0x30>
        panic("exit: no process");
    80003fb6:	00003517          	auipc	a0,0x3
    80003fba:	bd250513          	add	a0,a0,-1070 # 80006b88 <etext+0x1b88>
    80003fbe:	ffffd097          	auipc	ra,0xffffd
    80003fc2:	5da080e7          	jalr	1498(ra) # 80001598 <panic>
    }
    
    printf("Process %d (%s) exiting with status %d\n", 
    80003fc6:	fe843783          	ld	a5,-24(s0)
    80003fca:	4398                	lw	a4,0(a5)
           p->pid, p->name, status);
    80003fcc:	fe843783          	ld	a5,-24(s0)
    80003fd0:	07a1                	add	a5,a5,8
    printf("Process %d (%s) exiting with status %d\n", 
    80003fd2:	fdc42683          	lw	a3,-36(s0)
    80003fd6:	863e                	mv	a2,a5
    80003fd8:	85ba                	mv	a1,a4
    80003fda:	00003517          	auipc	a0,0x3
    80003fde:	bc650513          	add	a0,a0,-1082 # 80006ba0 <etext+0x1ba0>
    80003fe2:	ffffd097          	auipc	ra,0xffffd
    80003fe6:	210080e7          	jalr	528(ra) # 800011f2 <printf>
    
    // 关闭中断，保证对子进程和自身状态修改的原子性
    w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80003fea:	fffff097          	auipc	ra,0xfffff
    80003fee:	598080e7          	jalr	1432(ra) # 80003582 <r_sstatus>
    80003ff2:	87aa                	mv	a5,a0
    80003ff4:	9bf5                	and	a5,a5,-3
    80003ff6:	853e                	mv	a0,a5
    80003ff8:	fffff097          	auipc	ra,0xfffff
    80003ffc:	5a4080e7          	jalr	1444(ra) # 8000359c <w_sstatus>

    // ★ 先处理所有子进程：递归标记并唤醒，让它们也能尽快退出
    kill_children(p);
    80004000:	fe843503          	ld	a0,-24(s0)
    80004004:	00000097          	auipc	ra,0x0
    80004008:	e5a080e7          	jalr	-422(ra) # 80003e5e <kill_children>
    
    p->xstate = status;
    8000400c:	fe843783          	ld	a5,-24(s0)
    80004010:	fdc42703          	lw	a4,-36(s0)
    80004014:	0ae7a423          	sw	a4,168(a5)
    p->state = ZOMBIE;
    80004018:	fe843783          	ld	a5,-24(s0)
    8000401c:	4715                	li	a4,5
    8000401e:	c3d8                	sw	a4,4(a5)
    
    // 唤醒父进程（如果父进程在wait_proc里睡眠）
    if(p->parent) {
    80004020:	fe843783          	ld	a5,-24(s0)
    80004024:	73dc                	ld	a5,160(a5)
    80004026:	cb89                	beqz	a5,80004038 <exit_proc+0xa2>
        wakeup(p->parent);
    80004028:	fe843783          	ld	a5,-24(s0)
    8000402c:	73dc                	ld	a5,160(a5)
    8000402e:	853e                	mv	a0,a5
    80004030:	00000097          	auipc	ra,0x0
    80004034:	dcc080e7          	jalr	-564(ra) # 80003dfc <wakeup>
    }
    
    sched();
    80004038:	00000097          	auipc	ra,0x0
    8000403c:	b2e080e7          	jalr	-1234(ra) # 80003b66 <sched>
    panic("zombie exit");
    80004040:	00003517          	auipc	a0,0x3
    80004044:	b8850513          	add	a0,a0,-1144 # 80006bc8 <etext+0x1bc8>
    80004048:	ffffd097          	auipc	ra,0xffffd
    8000404c:	550080e7          	jalr	1360(ra) # 80001598 <panic>
}
    80004050:	0001                	nop
    80004052:	70a2                	ld	ra,40(sp)
    80004054:	7402                	ld	s0,32(sp)
    80004056:	6145                	add	sp,sp,48
    80004058:	8082                	ret

000000008000405a <wait_proc>:

// ==================== 等待子进程退出 ====================
int wait_proc(int *status)
{
    8000405a:	7139                	add	sp,sp,-64
    8000405c:	fc06                	sd	ra,56(sp)
    8000405e:	f822                	sd	s0,48(sp)
    80004060:	0080                	add	s0,sp,64
    80004062:	fca43423          	sd	a0,-56(s0)
    struct proc *np;
    int havekids, pid;
    struct proc *p = myproc();
    80004066:	fffff097          	auipc	ra,0xfffff
    8000406a:	70a080e7          	jalr	1802(ra) # 80003770 <myproc>
    8000406e:	fca43c23          	sd	a0,-40(s0)
    
    for(;;) {
        havekids = 0;
    80004072:	fe042223          	sw	zero,-28(s0)
        for(np = proc; np < &proc[NPROC]; np++) {
    80004076:	00008797          	auipc	a5,0x8
    8000407a:	10a78793          	add	a5,a5,266 # 8000c180 <proc>
    8000407e:	fef43423          	sd	a5,-24(s0)
    80004082:	a085                	j	800040e2 <wait_proc+0x88>
            if(np->parent == p) {
    80004084:	fe843783          	ld	a5,-24(s0)
    80004088:	73dc                	ld	a5,160(a5)
    8000408a:	fd843703          	ld	a4,-40(s0)
    8000408e:	04f71463          	bne	a4,a5,800040d6 <wait_proc+0x7c>
                havekids = 1;
    80004092:	4785                	li	a5,1
    80004094:	fef42223          	sw	a5,-28(s0)
                if(np->state == ZOMBIE) {
    80004098:	fe843783          	ld	a5,-24(s0)
    8000409c:	43dc                	lw	a5,4(a5)
    8000409e:	873e                	mv	a4,a5
    800040a0:	4795                	li	a5,5
    800040a2:	02f71a63          	bne	a4,a5,800040d6 <wait_proc+0x7c>
                    pid = np->pid;
    800040a6:	fe843783          	ld	a5,-24(s0)
    800040aa:	439c                	lw	a5,0(a5)
    800040ac:	fcf42a23          	sw	a5,-44(s0)
                    if(status != 0) {
    800040b0:	fc843783          	ld	a5,-56(s0)
    800040b4:	cb81                	beqz	a5,800040c4 <wait_proc+0x6a>
                        *status = np->xstate;
    800040b6:	fe843783          	ld	a5,-24(s0)
    800040ba:	0a87a703          	lw	a4,168(a5)
    800040be:	fc843783          	ld	a5,-56(s0)
    800040c2:	c398                	sw	a4,0(a5)
                    }
                    free_proc(np);
    800040c4:	fe843503          	ld	a0,-24(s0)
    800040c8:	fffff097          	auipc	ra,0xfffff
    800040cc:	7d8080e7          	jalr	2008(ra) # 800038a0 <free_proc>
                    return pid;
    800040d0:	fd442783          	lw	a5,-44(s0)
    800040d4:	a825                	j	8000410c <wait_proc+0xb2>
        for(np = proc; np < &proc[NPROC]; np++) {
    800040d6:	fe843783          	ld	a5,-24(s0)
    800040da:	0c878793          	add	a5,a5,200
    800040de:	fef43423          	sd	a5,-24(s0)
    800040e2:	fe843703          	ld	a4,-24(s0)
    800040e6:	0000b797          	auipc	a5,0xb
    800040ea:	29a78793          	add	a5,a5,666 # 8000f380 <cpus>
    800040ee:	f8f76be3          	bltu	a4,a5,80004084 <wait_proc+0x2a>
                }
            }
        }
        
        if(!havekids) {
    800040f2:	fe442783          	lw	a5,-28(s0)
    800040f6:	2781                	sext.w	a5,a5
    800040f8:	e399                	bnez	a5,800040fe <wait_proc+0xa4>
            return -1;
    800040fa:	57fd                	li	a5,-1
    800040fc:	a801                	j	8000410c <wait_proc+0xb2>
        }
        
        sleep(p);
    800040fe:	fd843503          	ld	a0,-40(s0)
    80004102:	00000097          	auipc	ra,0x0
    80004106:	c76080e7          	jalr	-906(ra) # 80003d78 <sleep>
        havekids = 0;
    8000410a:	b7a5                	j	80004072 <wait_proc+0x18>
    }
}
    8000410c:	853e                	mv	a0,a5
    8000410e:	70e2                	ld	ra,56(sp)
    80004110:	7442                	ld	s0,48(sp)
    80004112:	6121                	add	sp,sp,64
    80004114:	8082                	ret

0000000080004116 <proc_info>:

// ==================== 打印进程信息（修复版）====================
void proc_info(void)
{
    80004116:	7139                	add	sp,sp,-64
    80004118:	fc06                	sd	ra,56(sp)
    8000411a:	f822                	sd	s0,48(sp)
    8000411c:	0080                	add	s0,sp,64
    struct proc *p;
    int count = 0;
    8000411e:	fe042223          	sw	zero,-28(s0)
    
    printf("\n=== Process Table ===\n");
    80004122:	00003517          	auipc	a0,0x3
    80004126:	ab650513          	add	a0,a0,-1354 # 80006bd8 <etext+0x1bd8>
    8000412a:	ffffd097          	auipc	ra,0xffffd
    8000412e:	0c8080e7          	jalr	200(ra) # 800011f2 <printf>
    printf("PID  STATE      NAME            RUNTIME\n");
    80004132:	00003517          	auipc	a0,0x3
    80004136:	abe50513          	add	a0,a0,-1346 # 80006bf0 <etext+0x1bf0>
    8000413a:	ffffd097          	auipc	ra,0xffffd
    8000413e:	0b8080e7          	jalr	184(ra) # 800011f2 <printf>
    printf("---  ---------  --------------  -------\n");
    80004142:	00003517          	auipc	a0,0x3
    80004146:	ade50513          	add	a0,a0,-1314 # 80006c20 <etext+0x1c20>
    8000414a:	ffffd097          	auipc	ra,0xffffd
    8000414e:	0a8080e7          	jalr	168(ra) # 800011f2 <printf>
    
    for(p = proc; p < &proc[NPROC]; p++) {
    80004152:	00008797          	auipc	a5,0x8
    80004156:	02e78793          	add	a5,a5,46 # 8000c180 <proc>
    8000415a:	fef43423          	sd	a5,-24(s0)
    8000415e:	a269                	j	800042e8 <proc_info+0x1d2>
        if(p->state != UNUSED) {
    80004160:	fe843783          	ld	a5,-24(s0)
    80004164:	43dc                	lw	a5,4(a5)
    80004166:	16078b63          	beqz	a5,800042dc <proc_info+0x1c6>
            // 打印 PID（3列宽）
            if(p->pid < 10) {
    8000416a:	fe843783          	ld	a5,-24(s0)
    8000416e:	439c                	lw	a5,0(a5)
    80004170:	873e                	mv	a4,a5
    80004172:	47a5                	li	a5,9
    80004174:	00e7cf63          	blt	a5,a4,80004192 <proc_info+0x7c>
                printf("%d    ", p->pid);
    80004178:	fe843783          	ld	a5,-24(s0)
    8000417c:	439c                	lw	a5,0(a5)
    8000417e:	85be                	mv	a1,a5
    80004180:	00003517          	auipc	a0,0x3
    80004184:	ad050513          	add	a0,a0,-1328 # 80006c50 <etext+0x1c50>
    80004188:	ffffd097          	auipc	ra,0xffffd
    8000418c:	06a080e7          	jalr	106(ra) # 800011f2 <printf>
    80004190:	a091                	j	800041d4 <proc_info+0xbe>
            } else if(p->pid < 100) {
    80004192:	fe843783          	ld	a5,-24(s0)
    80004196:	439c                	lw	a5,0(a5)
    80004198:	873e                	mv	a4,a5
    8000419a:	06300793          	li	a5,99
    8000419e:	00e7cf63          	blt	a5,a4,800041bc <proc_info+0xa6>
                printf("%d   ", p->pid);
    800041a2:	fe843783          	ld	a5,-24(s0)
    800041a6:	439c                	lw	a5,0(a5)
    800041a8:	85be                	mv	a1,a5
    800041aa:	00003517          	auipc	a0,0x3
    800041ae:	aae50513          	add	a0,a0,-1362 # 80006c58 <etext+0x1c58>
    800041b2:	ffffd097          	auipc	ra,0xffffd
    800041b6:	040080e7          	jalr	64(ra) # 800011f2 <printf>
    800041ba:	a829                	j	800041d4 <proc_info+0xbe>
            } else {
                printf("%d  ", p->pid);
    800041bc:	fe843783          	ld	a5,-24(s0)
    800041c0:	439c                	lw	a5,0(a5)
    800041c2:	85be                	mv	a1,a5
    800041c4:	00003517          	auipc	a0,0x3
    800041c8:	a9c50513          	add	a0,a0,-1380 # 80006c60 <etext+0x1c60>
    800041cc:	ffffd097          	auipc	ra,0xffffd
    800041d0:	026080e7          	jalr	38(ra) # 800011f2 <printf>
            }
            
            // 打印状态名（11列宽）
            const char *sname = state_name(p->state);
    800041d4:	fe843783          	ld	a5,-24(s0)
    800041d8:	43dc                	lw	a5,4(a5)
    800041da:	853e                	mv	a0,a5
    800041dc:	00000097          	auipc	ra,0x0
    800041e0:	220080e7          	jalr	544(ra) # 800043fc <state_name>
    800041e4:	fca43423          	sd	a0,-56(s0)
            printf("%s", sname);
    800041e8:	fc843583          	ld	a1,-56(s0)
    800041ec:	00003517          	auipc	a0,0x3
    800041f0:	a7c50513          	add	a0,a0,-1412 # 80006c68 <etext+0x1c68>
    800041f4:	ffffd097          	auipc	ra,0xffffd
    800041f8:	ffe080e7          	jalr	-2(ra) # 800011f2 <printf>
            int slen = 0;
    800041fc:	fe042023          	sw	zero,-32(s0)
            while(sname[slen]) slen++;
    80004200:	a031                	j	8000420c <proc_info+0xf6>
    80004202:	fe042783          	lw	a5,-32(s0)
    80004206:	2785                	addw	a5,a5,1
    80004208:	fef42023          	sw	a5,-32(s0)
    8000420c:	fe042783          	lw	a5,-32(s0)
    80004210:	fc843703          	ld	a4,-56(s0)
    80004214:	97ba                	add	a5,a5,a4
    80004216:	0007c783          	lbu	a5,0(a5)
    8000421a:	f7e5                	bnez	a5,80004202 <proc_info+0xec>
            for(int i = slen; i < 11; i++) printf(" ");
    8000421c:	fe042783          	lw	a5,-32(s0)
    80004220:	fcf42e23          	sw	a5,-36(s0)
    80004224:	a831                	j	80004240 <proc_info+0x12a>
    80004226:	00003517          	auipc	a0,0x3
    8000422a:	a4a50513          	add	a0,a0,-1462 # 80006c70 <etext+0x1c70>
    8000422e:	ffffd097          	auipc	ra,0xffffd
    80004232:	fc4080e7          	jalr	-60(ra) # 800011f2 <printf>
    80004236:	fdc42783          	lw	a5,-36(s0)
    8000423a:	2785                	addw	a5,a5,1
    8000423c:	fcf42e23          	sw	a5,-36(s0)
    80004240:	fdc42783          	lw	a5,-36(s0)
    80004244:	0007871b          	sext.w	a4,a5
    80004248:	47a9                	li	a5,10
    8000424a:	fce7dee3          	bge	a5,a4,80004226 <proc_info+0x110>
            
            // 打印进程名（16列宽）
            printf("%s", p->name);
    8000424e:	fe843783          	ld	a5,-24(s0)
    80004252:	07a1                	add	a5,a5,8
    80004254:	85be                	mv	a1,a5
    80004256:	00003517          	auipc	a0,0x3
    8000425a:	a1250513          	add	a0,a0,-1518 # 80006c68 <etext+0x1c68>
    8000425e:	ffffd097          	auipc	ra,0xffffd
    80004262:	f94080e7          	jalr	-108(ra) # 800011f2 <printf>
            int nlen = 0;
    80004266:	fc042c23          	sw	zero,-40(s0)
            while(p->name[nlen]) nlen++;
    8000426a:	a031                	j	80004276 <proc_info+0x160>
    8000426c:	fd842783          	lw	a5,-40(s0)
    80004270:	2785                	addw	a5,a5,1
    80004272:	fcf42c23          	sw	a5,-40(s0)
    80004276:	fe843703          	ld	a4,-24(s0)
    8000427a:	fd842783          	lw	a5,-40(s0)
    8000427e:	97ba                	add	a5,a5,a4
    80004280:	0087c783          	lbu	a5,8(a5)
    80004284:	f7e5                	bnez	a5,8000426c <proc_info+0x156>
            for(int i = nlen; i < 16; i++) printf(" ");
    80004286:	fd842783          	lw	a5,-40(s0)
    8000428a:	fcf42a23          	sw	a5,-44(s0)
    8000428e:	a831                	j	800042aa <proc_info+0x194>
    80004290:	00003517          	auipc	a0,0x3
    80004294:	9e050513          	add	a0,a0,-1568 # 80006c70 <etext+0x1c70>
    80004298:	ffffd097          	auipc	ra,0xffffd
    8000429c:	f5a080e7          	jalr	-166(ra) # 800011f2 <printf>
    800042a0:	fd442783          	lw	a5,-44(s0)
    800042a4:	2785                	addw	a5,a5,1
    800042a6:	fcf42a23          	sw	a5,-44(s0)
    800042aa:	fd442783          	lw	a5,-44(s0)
    800042ae:	0007871b          	sext.w	a4,a5
    800042b2:	47bd                	li	a5,15
    800042b4:	fce7dee3          	bge	a5,a4,80004290 <proc_info+0x17a>
            
            // 打印运行时间
            printf("%d\n", (int)p->run_time);
    800042b8:	fe843783          	ld	a5,-24(s0)
    800042bc:	6bdc                	ld	a5,144(a5)
    800042be:	2781                	sext.w	a5,a5
    800042c0:	85be                	mv	a1,a5
    800042c2:	00003517          	auipc	a0,0x3
    800042c6:	9b650513          	add	a0,a0,-1610 # 80006c78 <etext+0x1c78>
    800042ca:	ffffd097          	auipc	ra,0xffffd
    800042ce:	f28080e7          	jalr	-216(ra) # 800011f2 <printf>
            
            count++;
    800042d2:	fe442783          	lw	a5,-28(s0)
    800042d6:	2785                	addw	a5,a5,1
    800042d8:	fef42223          	sw	a5,-28(s0)
    for(p = proc; p < &proc[NPROC]; p++) {
    800042dc:	fe843783          	ld	a5,-24(s0)
    800042e0:	0c878793          	add	a5,a5,200
    800042e4:	fef43423          	sd	a5,-24(s0)
    800042e8:	fe843703          	ld	a4,-24(s0)
    800042ec:	0000b797          	auipc	a5,0xb
    800042f0:	09478793          	add	a5,a5,148 # 8000f380 <cpus>
    800042f4:	e6f766e3          	bltu	a4,a5,80004160 <proc_info+0x4a>
        }
    }
    
    printf("Total: %d processes, Switches: %d\n", count, (int)total_switches);
    800042f8:	0000b797          	auipc	a5,0xb
    800042fc:	10878793          	add	a5,a5,264 # 8000f400 <total_switches>
    80004300:	639c                	ld	a5,0(a5)
    80004302:	0007871b          	sext.w	a4,a5
    80004306:	fe442783          	lw	a5,-28(s0)
    8000430a:	863a                	mv	a2,a4
    8000430c:	85be                	mv	a1,a5
    8000430e:	00003517          	auipc	a0,0x3
    80004312:	97250513          	add	a0,a0,-1678 # 80006c80 <etext+0x1c80>
    80004316:	ffffd097          	auipc	ra,0xffffd
    8000431a:	edc080e7          	jalr	-292(ra) # 800011f2 <printf>
    printf("====================\n\n");
    8000431e:	00003517          	auipc	a0,0x3
    80004322:	98a50513          	add	a0,a0,-1654 # 80006ca8 <etext+0x1ca8>
    80004326:	ffffd097          	auipc	ra,0xffffd
    8000432a:	ecc080e7          	jalr	-308(ra) # 800011f2 <printf>
}
    8000432e:	0001                	nop
    80004330:	70e2                	ld	ra,56(sp)
    80004332:	7442                	ld	s0,48(sp)
    80004334:	6121                	add	sp,sp,64
    80004336:	8082                	ret

0000000080004338 <proc_stats>:

// ==================== 获取统计信息 ====================
void proc_stats(void)
{
    80004338:	1101                	add	sp,sp,-32
    8000433a:	ec06                	sd	ra,24(sp)
    8000433c:	e822                	sd	s0,16(sp)
    8000433e:	1000                	add	s0,sp,32
    printf("\n=== Process Statistics ===\n");
    80004340:	00003517          	auipc	a0,0x3
    80004344:	98050513          	add	a0,a0,-1664 # 80006cc0 <etext+0x1cc0>
    80004348:	ffffd097          	auipc	ra,0xffffd
    8000434c:	eaa080e7          	jalr	-342(ra) # 800011f2 <printf>
    printf("Total context switches: %d\n", (int)total_switches);
    80004350:	0000b797          	auipc	a5,0xb
    80004354:	0b078793          	add	a5,a5,176 # 8000f400 <total_switches>
    80004358:	639c                	ld	a5,0(a5)
    8000435a:	2781                	sext.w	a5,a5
    8000435c:	85be                	mv	a1,a5
    8000435e:	00002517          	auipc	a0,0x2
    80004362:	79250513          	add	a0,a0,1938 # 80006af0 <etext+0x1af0>
    80004366:	ffffd097          	auipc	ra,0xffffd
    8000436a:	e8c080e7          	jalr	-372(ra) # 800011f2 <printf>
    printf("Active processes: ");
    8000436e:	00003517          	auipc	a0,0x3
    80004372:	97250513          	add	a0,a0,-1678 # 80006ce0 <etext+0x1ce0>
    80004376:	ffffd097          	auipc	ra,0xffffd
    8000437a:	e7c080e7          	jalr	-388(ra) # 800011f2 <printf>
    
    int active = 0;
    8000437e:	fe042623          	sw	zero,-20(s0)
    for(struct proc *p = proc; p < &proc[NPROC]; p++) {
    80004382:	00008797          	auipc	a5,0x8
    80004386:	dfe78793          	add	a5,a5,-514 # 8000c180 <proc>
    8000438a:	fef43023          	sd	a5,-32(s0)
    8000438e:	a03d                	j	800043bc <proc_stats+0x84>
        if(p->state != UNUSED && p->state != ZOMBIE) {
    80004390:	fe043783          	ld	a5,-32(s0)
    80004394:	43dc                	lw	a5,4(a5)
    80004396:	cf89                	beqz	a5,800043b0 <proc_stats+0x78>
    80004398:	fe043783          	ld	a5,-32(s0)
    8000439c:	43dc                	lw	a5,4(a5)
    8000439e:	873e                	mv	a4,a5
    800043a0:	4795                	li	a5,5
    800043a2:	00f70763          	beq	a4,a5,800043b0 <proc_stats+0x78>
            active++;
    800043a6:	fec42783          	lw	a5,-20(s0)
    800043aa:	2785                	addw	a5,a5,1
    800043ac:	fef42623          	sw	a5,-20(s0)
    for(struct proc *p = proc; p < &proc[NPROC]; p++) {
    800043b0:	fe043783          	ld	a5,-32(s0)
    800043b4:	0c878793          	add	a5,a5,200
    800043b8:	fef43023          	sd	a5,-32(s0)
    800043bc:	fe043703          	ld	a4,-32(s0)
    800043c0:	0000b797          	auipc	a5,0xb
    800043c4:	fc078793          	add	a5,a5,-64 # 8000f380 <cpus>
    800043c8:	fcf764e3          	bltu	a4,a5,80004390 <proc_stats+0x58>
        }
    }
    printf("%d\n", active);
    800043cc:	fec42783          	lw	a5,-20(s0)
    800043d0:	85be                	mv	a1,a5
    800043d2:	00003517          	auipc	a0,0x3
    800043d6:	8a650513          	add	a0,a0,-1882 # 80006c78 <etext+0x1c78>
    800043da:	ffffd097          	auipc	ra,0xffffd
    800043de:	e18080e7          	jalr	-488(ra) # 800011f2 <printf>
    printf("========================\n\n");
    800043e2:	00003517          	auipc	a0,0x3
    800043e6:	91650513          	add	a0,a0,-1770 # 80006cf8 <etext+0x1cf8>
    800043ea:	ffffd097          	auipc	ra,0xffffd
    800043ee:	e08080e7          	jalr	-504(ra) # 800011f2 <printf>
}
    800043f2:	0001                	nop
    800043f4:	60e2                	ld	ra,24(sp)
    800043f6:	6442                	ld	s0,16(sp)
    800043f8:	6105                	add	sp,sp,32
    800043fa:	8082                	ret

00000000800043fc <state_name>:

// ==================== 状态名称 ====================
const char* state_name(enum procstate s)
{
    800043fc:	1101                	add	sp,sp,-32
    800043fe:	ec22                	sd	s0,24(sp)
    80004400:	1000                	add	s0,sp,32
    80004402:	87aa                	mv	a5,a0
    80004404:	fef42623          	sw	a5,-20(s0)
    if(s >= 0 && s <= 5) {
    80004408:	fec42783          	lw	a5,-20(s0)
    8000440c:	0007871b          	sext.w	a4,a5
    80004410:	4795                	li	a5,5
    80004412:	00e7ec63          	bltu	a5,a4,8000442a <state_name+0x2e>
        return state_names[s];
    80004416:	fec46783          	lwu	a5,-20(s0)
    8000441a:	00479713          	sll	a4,a5,0x4
    8000441e:	00003797          	auipc	a5,0x3
    80004422:	bfa78793          	add	a5,a5,-1030 # 80007018 <state_names>
    80004426:	97ba                	add	a5,a5,a4
    80004428:	a029                	j	80004432 <state_name+0x36>
    }
    return state_names[6];
    8000442a:	00003797          	auipc	a5,0x3
    8000442e:	c4e78793          	add	a5,a5,-946 # 80007078 <state_names+0x60>
}
    80004432:	853e                	mv	a0,a5
    80004434:	6462                	ld	s0,24(sp)
    80004436:	6105                	add	sp,sp,32
    80004438:	8082                	ret

000000008000443a <swtch>:
# void swtch(struct context *old, struct context *new)

.globl swtch
swtch:
    # 保存旧上下文 (a0 = old)
    sd ra, 0(a0)
    8000443a:	00153023          	sd	ra,0(a0)
    sd sp, 8(a0)
    8000443e:	00253423          	sd	sp,8(a0)
    sd s0, 16(a0)
    80004442:	e900                	sd	s0,16(a0)
    sd s1, 24(a0)
    80004444:	ed04                	sd	s1,24(a0)
    sd s2, 32(a0)
    80004446:	03253023          	sd	s2,32(a0)
    sd s3, 40(a0)
    8000444a:	03353423          	sd	s3,40(a0)
    sd s4, 48(a0)
    8000444e:	03453823          	sd	s4,48(a0)
    sd s5, 56(a0)
    80004452:	03553c23          	sd	s5,56(a0)
    sd s6, 64(a0)
    80004456:	05653023          	sd	s6,64(a0)
    sd s7, 72(a0)
    8000445a:	05753423          	sd	s7,72(a0)
    sd s8, 80(a0)
    8000445e:	05853823          	sd	s8,80(a0)
    sd s9, 88(a0)
    80004462:	05953c23          	sd	s9,88(a0)
    sd s10, 96(a0)
    80004466:	07a53023          	sd	s10,96(a0)
    sd s11, 104(a0)
    8000446a:	07b53423          	sd	s11,104(a0)
    
    # 恢复新上下文 (a1 = new)
    ld ra, 0(a1)
    8000446e:	0005b083          	ld	ra,0(a1)
    ld sp, 8(a1)
    80004472:	0085b103          	ld	sp,8(a1)
    ld s0, 16(a1)
    80004476:	6980                	ld	s0,16(a1)
    ld s1, 24(a1)
    80004478:	6d84                	ld	s1,24(a1)
    ld s2, 32(a1)
    8000447a:	0205b903          	ld	s2,32(a1)
    ld s3, 40(a1)
    8000447e:	0285b983          	ld	s3,40(a1)
    ld s4, 48(a1)
    80004482:	0305ba03          	ld	s4,48(a1)
    ld s5, 56(a1)
    80004486:	0385ba83          	ld	s5,56(a1)
    ld s6, 64(a1)
    8000448a:	0405bb03          	ld	s6,64(a1)
    ld s7, 72(a1)
    8000448e:	0485bb83          	ld	s7,72(a1)
    ld s8, 80(a1)
    80004492:	0505bc03          	ld	s8,80(a1)
    ld s9, 88(a1)
    80004496:	0585bc83          	ld	s9,88(a1)
    ld s10, 96(a1)
    8000449a:	0605bd03          	ld	s10,96(a1)
    ld s11, 104(a1)
    8000449e:	0685bd83          	ld	s11,104(a1)
    
    800044a2:	8082                	ret
	...
