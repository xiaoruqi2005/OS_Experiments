
kernel/kernel.elf:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
.section .text.start
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
    80000014:	0000a297          	auipc	t0,0xa
    80000018:	fec28293          	add	t0,t0,-20 # 8000a000 <panicking>
    la t1, bss_end
    8000001c:	00011317          	auipc	t1,0x11
    80000020:	5cc30313          	add	t1,t1,1484 # 800115e8 <bss_end>

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
    80000040:	00a080e7          	jalr	10(ra) # 80000046 <start>

0000000080000044 <infinite_loop>:
    
    # 无限循环（不应该到达这里）
infinite_loop:
    j infinite_loop
    80000044:	a001                	j	80000044 <infinite_loop>

0000000080000046 <start>:

// 每个hart一个临时栈
__attribute__ ((aligned (16))) char m_stack0[4096];

void start()
{
    80000046:	715d                	add	sp,sp,-80
    80000048:	e486                	sd	ra,72(sp)
    8000004a:	e0a2                	sd	s0,64(sp)
    8000004c:	0880                	add	s0,sp,80
    // 设置mstatus的MPP字段为Supervisor模式
    unsigned long x = r_mstatus();
    8000004e:	300027f3          	csrr	a5,mstatus
    80000052:	fef43423          	sd	a5,-24(s0)
    80000056:	fe843783          	ld	a5,-24(s0)
    8000005a:	fef43023          	sd	a5,-32(s0)
    x &= ~MSTATUS_MPP_MASK;
    8000005e:	fe043703          	ld	a4,-32(s0)
    80000062:	77f9                	lui	a5,0xffffe
    80000064:	7ff78793          	add	a5,a5,2047 # ffffffffffffe7ff <end+0xffffffff7ffec7ff>
    80000068:	8ff9                	and	a5,a5,a4
    8000006a:	fef43023          	sd	a5,-32(s0)
    x |= MSTATUS_MPP_S;
    8000006e:	fe043703          	ld	a4,-32(s0)
    80000072:	6785                	lui	a5,0x1
    80000074:	80078793          	add	a5,a5,-2048 # 800 <_entry-0x7ffff800>
    80000078:	8fd9                	or	a5,a5,a4
    8000007a:	fef43023          	sd	a5,-32(s0)
    w_mstatus(x);
    8000007e:	fe043783          	ld	a5,-32(s0)
    80000082:	30079073          	csrw	mstatus,a5

    // 设置mepc为main函数地址
    w_mepc((uint64)main);
    80000086:	00000797          	auipc	a5,0x0
    8000008a:	5c478793          	add	a5,a5,1476 # 8000064a <main>
    8000008e:	34179073          	csrw	mepc,a5

    // 禁用S模式分页
    w_satp(0);
    80000092:	4781                	li	a5,0
    80000094:	18079073          	csrw	satp,a5

    // 配置中断委托
    w_medeleg(0xffff);
    80000098:	67c1                	lui	a5,0x10
    8000009a:	37fd                	addw	a5,a5,-1 # ffff <_entry-0x7fff0001>
    8000009c:	30279073          	csrw	medeleg,a5
    w_mideleg((1 << IRQ_S_SOFT) | (1 << IRQ_S_TIMER) | (1 << IRQ_S_EXT));
    800000a0:	22200793          	li	a5,546
    800000a4:	30379073          	csrw	mideleg,a5

    // 启用S模式中断
    w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000a8:	104027f3          	csrr	a5,sie
    800000ac:	fcf43c23          	sd	a5,-40(s0)
    800000b0:	fd843783          	ld	a5,-40(s0)
    800000b4:	2227e793          	or	a5,a5,546
    800000b8:	10479073          	csrw	sie,a5

    // 配置PMP
    w_pmpaddr0(0x3fffffffffffffull);
    800000bc:	57fd                	li	a5,-1
    800000be:	83a9                	srl	a5,a5,0xa
    800000c0:	3b079073          	csrw	pmpaddr0,a5
    w_pmpcfg0(0xf);
    800000c4:	47bd                	li	a5,15
    800000c6:	3a079073          	csrw	pmpcfg0,a5

    // 配置M模式时钟中断
    timer_init_hart();
    800000ca:	00003097          	auipc	ra,0x3
    800000ce:	598080e7          	jalr	1432(ra) # 80003662 <timer_init_hart>

    // 设置M模式中断向量
    w_mtvec((uint64)timervec);
    800000d2:	00003797          	auipc	a5,0x3
    800000d6:	51e78793          	add	a5,a5,1310 # 800035f0 <timervec>
    800000da:	30579073          	csrw	mtvec,a5

    // 启用M模式中断
    w_mstatus(r_mstatus() | MSTATUS_MIE);
    800000de:	300027f3          	csrr	a5,mstatus
    800000e2:	fcf43823          	sd	a5,-48(s0)
    800000e6:	fd043783          	ld	a5,-48(s0)
    800000ea:	0087e793          	or	a5,a5,8
    800000ee:	30079073          	csrw	mstatus,a5
    w_mie(r_mie() | MIE_MTIE);
    800000f2:	304027f3          	csrr	a5,mie
    800000f6:	fcf43423          	sd	a5,-56(s0)
    800000fa:	fc843783          	ld	a5,-56(s0)
    800000fe:	0807e793          	or	a5,a5,128
    80000102:	30479073          	csrw	mie,a5

    // 设置hart ID
    int id = r_mhartid();
    80000106:	f14027f3          	csrr	a5,mhartid
    8000010a:	fcf43023          	sd	a5,-64(s0)
    8000010e:	fc043783          	ld	a5,-64(s0)
    80000112:	faf42e23          	sw	a5,-68(s0)
    w_tp(id);
    80000116:	fbc42783          	lw	a5,-68(s0)
    8000011a:	823e                	mv	tp,a5

    // 切换到S模式
    asm volatile("mret");
    8000011c:	30200073          	mret
    80000120:	0001                	nop
    80000122:	60a6                	ld	ra,72(sp)
    80000124:	6406                	ld	s0,64(sp)
    80000126:	6161                	add	sp,sp,80
    80000128:	8082                	ret

000000008000012a <test_getpid>:
extern struct proc proc[];
extern struct proc *initproc;

// ==================== 系统调用测试任务 ====================

void test_getpid(void) {
    8000012a:	1101                	add	sp,sp,-32
    8000012c:	ec06                	sd	ra,24(sp)
    8000012e:	e822                	sd	s0,16(sp)
    80000130:	1000                	add	s0,sp,32
    printf("\n=== Test 1: sys_getpid ===\n");
    80000132:	00006517          	auipc	a0,0x6
    80000136:	fee50513          	add	a0,a0,-18 # 80006120 <userret+0xbc>
    8000013a:	00001097          	auipc	ra,0x1
    8000013e:	aac080e7          	jalr	-1364(ra) # 80000be6 <printf>
    
    register uint64 a7 asm("a7") = SYS_getpid;
    80000142:	4891                	li	a7,4
    register uint64 a0 asm("a0");
    
    asm volatile("ecall" : "=r"(a0) : "r"(a7));
    80000144:	00000073          	ecall
    
    // ⭐ 修复：立即保存返回值到局部变量
    int result = (int)a0;
    80000148:	87aa                	mv	a5,a0
    8000014a:	fef42623          	sw	a5,-20(s0)
    int expected = myproc()->pid;
    8000014e:	00004097          	auipc	ra,0x4
    80000152:	88a080e7          	jalr	-1910(ra) # 800039d8 <myproc>
    80000156:	87aa                	mv	a5,a0
    80000158:	439c                	lw	a5,0(a5)
    8000015a:	fef42423          	sw	a5,-24(s0)
    
    printf("sys_getpid() returned: %d\n", result);
    8000015e:	fec42783          	lw	a5,-20(s0)
    80000162:	85be                	mv	a1,a5
    80000164:	00006517          	auipc	a0,0x6
    80000168:	fdc50513          	add	a0,a0,-36 # 80006140 <userret+0xdc>
    8000016c:	00001097          	auipc	ra,0x1
    80000170:	a7a080e7          	jalr	-1414(ra) # 80000be6 <printf>
    printf("myproc()->pid = %d\n", expected);
    80000174:	fe842783          	lw	a5,-24(s0)
    80000178:	85be                	mv	a1,a5
    8000017a:	00006517          	auipc	a0,0x6
    8000017e:	fe650513          	add	a0,a0,-26 # 80006160 <userret+0xfc>
    80000182:	00001097          	auipc	ra,0x1
    80000186:	a64080e7          	jalr	-1436(ra) # 80000be6 <printf>
    
    if(result == expected) {
    8000018a:	fec42783          	lw	a5,-20(s0)
    8000018e:	873e                	mv	a4,a5
    80000190:	fe842783          	lw	a5,-24(s0)
    80000194:	2701                	sext.w	a4,a4
    80000196:	2781                	sext.w	a5,a5
    80000198:	00f71b63          	bne	a4,a5,800001ae <test_getpid+0x84>
        printf("✓ sys_getpid test PASSED\n");
    8000019c:	00006517          	auipc	a0,0x6
    800001a0:	fdc50513          	add	a0,a0,-36 # 80006178 <userret+0x114>
    800001a4:	00001097          	auipc	ra,0x1
    800001a8:	a42080e7          	jalr	-1470(ra) # 80000be6 <printf>
    } else {
        printf("✗ sys_getpid test FAILED\n");
    }
}
    800001ac:	a809                	j	800001be <test_getpid+0x94>
        printf("✗ sys_getpid test FAILED\n");
    800001ae:	00006517          	auipc	a0,0x6
    800001b2:	fea50513          	add	a0,a0,-22 # 80006198 <userret+0x134>
    800001b6:	00001097          	auipc	ra,0x1
    800001ba:	a30080e7          	jalr	-1488(ra) # 80000be6 <printf>
}
    800001be:	0001                	nop
    800001c0:	60e2                	ld	ra,24(sp)
    800001c2:	6442                	ld	s0,16(sp)
    800001c4:	6105                	add	sp,sp,32
    800001c6:	8082                	ret

00000000800001c8 <test_write>:

void test_write(void) {
    800001c8:	1101                	add	sp,sp,-32
    800001ca:	ec06                	sd	ra,24(sp)
    800001cc:	e822                	sd	s0,16(sp)
    800001ce:	1000                	add	s0,sp,32
    printf("\n=== Test 2: sys_write ===\n");
    800001d0:	00006517          	auipc	a0,0x6
    800001d4:	fe850513          	add	a0,a0,-24 # 800061b8 <userret+0x154>
    800001d8:	00001097          	auipc	ra,0x1
    800001dc:	a0e080e7          	jalr	-1522(ra) # 80000be6 <printf>
    
    char *msg = "Hello from sys_write!\n";
    800001e0:	00006797          	auipc	a5,0x6
    800001e4:	ff878793          	add	a5,a5,-8 # 800061d8 <userret+0x174>
    800001e8:	fef43423          	sd	a5,-24(s0)
    int msg_len = 22;
    800001ec:	47d9                	li	a5,22
    800001ee:	fef42223          	sw	a5,-28(s0)
    
    register uint64 a7 asm("a7") = SYS_write;
    800001f2:	489d                	li	a7,7
    register uint64 a0 asm("a0") = 1;
    800001f4:	4505                	li	a0,1
    register uint64 a1 asm("a1") = (uint64)msg;
    800001f6:	fe843783          	ld	a5,-24(s0)
    800001fa:	85be                	mv	a1,a5
    register uint64 a2 asm("a2") = msg_len;
    800001fc:	fe442783          	lw	a5,-28(s0)
    80000200:	863e                	mv	a2,a5
    
    asm volatile("ecall" : "+r"(a0) : "r"(a7), "r"(a1), "r"(a2));
    80000202:	00000073          	ecall
    
    // ⭐ 修复：立即保存返回值
    int result = (int)a0;
    80000206:	87aa                	mv	a5,a0
    80000208:	fef42023          	sw	a5,-32(s0)
    
    printf("sys_write() returned: %d\n", result);
    8000020c:	fe042783          	lw	a5,-32(s0)
    80000210:	85be                	mv	a1,a5
    80000212:	00006517          	auipc	a0,0x6
    80000216:	fde50513          	add	a0,a0,-34 # 800061f0 <userret+0x18c>
    8000021a:	00001097          	auipc	ra,0x1
    8000021e:	9cc080e7          	jalr	-1588(ra) # 80000be6 <printf>
    
    if(result == msg_len) {
    80000222:	fe042783          	lw	a5,-32(s0)
    80000226:	873e                	mv	a4,a5
    80000228:	fe442783          	lw	a5,-28(s0)
    8000022c:	2701                	sext.w	a4,a4
    8000022e:	2781                	sext.w	a5,a5
    80000230:	00f71b63          	bne	a4,a5,80000246 <test_write+0x7e>
        printf("✓ sys_write test PASSED\n");
    80000234:	00006517          	auipc	a0,0x6
    80000238:	fdc50513          	add	a0,a0,-36 # 80006210 <userret+0x1ac>
    8000023c:	00001097          	auipc	ra,0x1
    80000240:	9aa080e7          	jalr	-1622(ra) # 80000be6 <printf>
    } else {
        printf("✗ sys_write test FAILED\n");
    }
}
    80000244:	a809                	j	80000256 <test_write+0x8e>
        printf("✗ sys_write test FAILED\n");
    80000246:	00006517          	auipc	a0,0x6
    8000024a:	fea50513          	add	a0,a0,-22 # 80006230 <userret+0x1cc>
    8000024e:	00001097          	auipc	ra,0x1
    80000252:	998080e7          	jalr	-1640(ra) # 80000be6 <printf>
}
    80000256:	0001                	nop
    80000258:	60e2                	ld	ra,24(sp)
    8000025a:	6442                	ld	s0,16(sp)
    8000025c:	6105                	add	sp,sp,32
    8000025e:	8082                	ret

0000000080000260 <test_multiple_syscalls>:

void test_multiple_syscalls(void) {
    80000260:	1101                	add	sp,sp,-32
    80000262:	ec06                	sd	ra,24(sp)
    80000264:	e822                	sd	s0,16(sp)
    80000266:	1000                	add	s0,sp,32
    printf("\n=== Test 3: Multiple System Calls ===\n");
    80000268:	00006517          	auipc	a0,0x6
    8000026c:	fe850513          	add	a0,a0,-24 # 80006250 <userret+0x1ec>
    80000270:	00001097          	auipc	ra,0x1
    80000274:	976080e7          	jalr	-1674(ra) # 80000be6 <printf>
    
    for(int i = 0; i < 5; i++) {
    80000278:	fe042623          	sw	zero,-20(s0)
    8000027c:	a825                	j	800002b4 <test_multiple_syscalls+0x54>
        register uint64 a7 asm("a7") = SYS_getpid;
    8000027e:	4891                	li	a7,4
        register uint64 a0 asm("a0");
        
        asm volatile("ecall" : "=r"(a0) : "r"(a7));
    80000280:	00000073          	ecall
        
        // ⭐ 修复：立即保存返回值
        int result = (int)a0;
    80000284:	87aa                	mv	a5,a0
    80000286:	fef42423          	sw	a5,-24(s0)
        
        printf("Call %d: getpid() = %d\n", i+1, result);
    8000028a:	fec42783          	lw	a5,-20(s0)
    8000028e:	2785                	addw	a5,a5,1
    80000290:	2781                	sext.w	a5,a5
    80000292:	fe842703          	lw	a4,-24(s0)
    80000296:	863a                	mv	a2,a4
    80000298:	85be                	mv	a1,a5
    8000029a:	00006517          	auipc	a0,0x6
    8000029e:	fde50513          	add	a0,a0,-34 # 80006278 <userret+0x214>
    800002a2:	00001097          	auipc	ra,0x1
    800002a6:	944080e7          	jalr	-1724(ra) # 80000be6 <printf>
    for(int i = 0; i < 5; i++) {
    800002aa:	fec42783          	lw	a5,-20(s0)
    800002ae:	2785                	addw	a5,a5,1
    800002b0:	fef42623          	sw	a5,-20(s0)
    800002b4:	fec42783          	lw	a5,-20(s0)
    800002b8:	0007871b          	sext.w	a4,a5
    800002bc:	4791                	li	a5,4
    800002be:	fce7d0e3          	bge	a5,a4,8000027e <test_multiple_syscalls+0x1e>
    }
    
    printf("✓ Multiple syscalls test PASSED\n");
    800002c2:	00006517          	auipc	a0,0x6
    800002c6:	fce50513          	add	a0,a0,-50 # 80006290 <userret+0x22c>
    800002ca:	00001097          	auipc	ra,0x1
    800002ce:	91c080e7          	jalr	-1764(ra) # 80000be6 <printf>
}
    800002d2:	0001                	nop
    800002d4:	60e2                	ld	ra,24(sp)
    800002d6:	6442                	ld	s0,16(sp)
    800002d8:	6105                	add	sp,sp,32
    800002da:	8082                	ret

00000000800002dc <test_syscall_parameters>:

void test_syscall_parameters(void) {
    800002dc:	7139                	add	sp,sp,-64
    800002de:	fc06                	sd	ra,56(sp)
    800002e0:	f822                	sd	s0,48(sp)
    800002e2:	0080                	add	s0,sp,64
    printf("\n=== Test 4: System Call Parameters ===\n");
    800002e4:	00006517          	auipc	a0,0x6
    800002e8:	fd450513          	add	a0,a0,-44 # 800062b8 <userret+0x254>
    800002ec:	00001097          	auipc	ra,0x1
    800002f0:	8fa080e7          	jalr	-1798(ra) # 80000be6 <printf>
    
    char msg1[] = "First message\n";
    800002f4:	00006797          	auipc	a5,0x6
    800002f8:	01c78793          	add	a5,a5,28 # 80006310 <userret+0x2ac>
    800002fc:	6398                	ld	a4,0(a5)
    800002fe:	fee43023          	sd	a4,-32(s0)
    80000302:	4798                	lw	a4,8(a5)
    80000304:	fee42423          	sw	a4,-24(s0)
    80000308:	00c7d703          	lhu	a4,12(a5)
    8000030c:	fee41623          	sh	a4,-20(s0)
    80000310:	00e7c783          	lbu	a5,14(a5)
    80000314:	fef40723          	sb	a5,-18(s0)
    char msg2[] = "Second message\n";
    80000318:	00006797          	auipc	a5,0x6
    8000031c:	00878793          	add	a5,a5,8 # 80006320 <userret+0x2bc>
    80000320:	6398                	ld	a4,0(a5)
    80000322:	fce43823          	sd	a4,-48(s0)
    80000326:	679c                	ld	a5,8(a5)
    80000328:	fcf43c23          	sd	a5,-40(s0)
    char msg3[] = "Third message\n";
    8000032c:	00006797          	auipc	a5,0x6
    80000330:	00478793          	add	a5,a5,4 # 80006330 <userret+0x2cc>
    80000334:	6398                	ld	a4,0(a5)
    80000336:	fce43023          	sd	a4,-64(s0)
    8000033a:	4798                	lw	a4,8(a5)
    8000033c:	fce42423          	sw	a4,-56(s0)
    80000340:	00c7d703          	lhu	a4,12(a5)
    80000344:	fce41623          	sh	a4,-52(s0)
    80000348:	00e7c783          	lbu	a5,14(a5)
    8000034c:	fcf40723          	sb	a5,-50(s0)
    
    register uint64 a7 asm("a7") = SYS_write;
    80000350:	489d                	li	a7,7
    register uint64 a0 asm("a0") = 1;
    80000352:	4505                	li	a0,1
    register uint64 a1 asm("a1") = (uint64)msg1;
    80000354:	fe040793          	add	a5,s0,-32
    80000358:	85be                	mv	a1,a5
    register uint64 a2 asm("a2") = 14;
    8000035a:	4639                	li	a2,14
    asm volatile("ecall" : "+r"(a0) : "r"(a7), "r"(a1), "r"(a2));
    8000035c:	00000073          	ecall
    
    a0 = 1;
    80000360:	4505                	li	a0,1
    a1 = (uint64)msg2;
    80000362:	fd040793          	add	a5,s0,-48
    80000366:	85be                	mv	a1,a5
    a2 = 15;
    80000368:	463d                	li	a2,15
    asm volatile("ecall" : "+r"(a0) : "r"(a7), "r"(a1), "r"(a2));
    8000036a:	00000073          	ecall
    
    a0 = 1;
    8000036e:	4505                	li	a0,1
    a1 = (uint64)msg3;
    80000370:	fc040793          	add	a5,s0,-64
    80000374:	85be                	mv	a1,a5
    a2 = 14;
    80000376:	4639                	li	a2,14
    asm volatile("ecall" : "+r"(a0) : "r"(a7), "r"(a1), "r"(a2));
    80000378:	00000073          	ecall
    
    printf("✓ Parameter passing test PASSED\n");
    8000037c:	00006517          	auipc	a0,0x6
    80000380:	f6c50513          	add	a0,a0,-148 # 800062e8 <userret+0x284>
    80000384:	00001097          	auipc	ra,0x1
    80000388:	862080e7          	jalr	-1950(ra) # 80000be6 <printf>
}
    8000038c:	0001                	nop
    8000038e:	70e2                	ld	ra,56(sp)
    80000390:	7442                	ld	s0,48(sp)
    80000392:	6121                	add	sp,sp,64
    80000394:	8082                	ret

0000000080000396 <test_invalid_syscall>:

void test_invalid_syscall(void) {
    80000396:	1101                	add	sp,sp,-32
    80000398:	ec06                	sd	ra,24(sp)
    8000039a:	e822                	sd	s0,16(sp)
    8000039c:	1000                	add	s0,sp,32
    printf("\n=== Test 5: Invalid System Call ===\n");
    8000039e:	00006517          	auipc	a0,0x6
    800003a2:	fa250513          	add	a0,a0,-94 # 80006340 <userret+0x2dc>
    800003a6:	00001097          	auipc	ra,0x1
    800003aa:	840080e7          	jalr	-1984(ra) # 80000be6 <printf>
    
    register uint64 a7 asm("a7") = 999;
    800003ae:	3e700893          	li	a7,999
    register uint64 a0 asm("a0");
    
    asm volatile("ecall" : "=r"(a0) : "r"(a7));
    800003b2:	00000073          	ecall
    
    // ⭐ 修复：立即保存返回值
    int result = (int)a0;
    800003b6:	87aa                	mv	a5,a0
    800003b8:	fef42623          	sw	a5,-20(s0)
    
    printf("Invalid syscall returned: %d\n", result);
    800003bc:	fec42783          	lw	a5,-20(s0)
    800003c0:	85be                	mv	a1,a5
    800003c2:	00006517          	auipc	a0,0x6
    800003c6:	fa650513          	add	a0,a0,-90 # 80006368 <userret+0x304>
    800003ca:	00001097          	auipc	ra,0x1
    800003ce:	81c080e7          	jalr	-2020(ra) # 80000be6 <printf>
    
    if(result == -1) {
    800003d2:	fec42783          	lw	a5,-20(s0)
    800003d6:	0007871b          	sext.w	a4,a5
    800003da:	57fd                	li	a5,-1
    800003dc:	00f71b63          	bne	a4,a5,800003f2 <test_invalid_syscall+0x5c>
        printf("✓ Invalid syscall handling PASSED\n");
    800003e0:	00006517          	auipc	a0,0x6
    800003e4:	fa850513          	add	a0,a0,-88 # 80006388 <userret+0x324>
    800003e8:	00000097          	auipc	ra,0x0
    800003ec:	7fe080e7          	jalr	2046(ra) # 80000be6 <printf>
    } else {
        printf("✗ Invalid syscall handling FAILED\n");
    }
}
    800003f0:	a809                	j	80000402 <test_invalid_syscall+0x6c>
        printf("✗ Invalid syscall handling FAILED\n");
    800003f2:	00006517          	auipc	a0,0x6
    800003f6:	fbe50513          	add	a0,a0,-66 # 800063b0 <userret+0x34c>
    800003fa:	00000097          	auipc	ra,0x0
    800003fe:	7ec080e7          	jalr	2028(ra) # 80000be6 <printf>
}
    80000402:	0001                	nop
    80000404:	60e2                	ld	ra,24(sp)
    80000406:	6442                	ld	s0,16(sp)
    80000408:	6105                	add	sp,sp,32
    8000040a:	8082                	ret

000000008000040c <test_write_edge_cases>:

void test_write_edge_cases(void) {
    8000040c:	7159                	add	sp,sp,-112
    8000040e:	f486                	sd	ra,104(sp)
    80000410:	f0a2                	sd	s0,96(sp)
    80000412:	1880                	add	s0,sp,112
    printf("\n=== Test 6: sys_write Edge Cases ===\n");
    80000414:	00006517          	auipc	a0,0x6
    80000418:	fc450513          	add	a0,a0,-60 # 800063d8 <userret+0x374>
    8000041c:	00000097          	auipc	ra,0x0
    80000420:	7ca080e7          	jalr	1994(ra) # 80000be6 <printf>
    
    char empty[] = "";
    80000424:	fe040023          	sb	zero,-32(s0)
    register uint64 a7 asm("a7") = SYS_write;
    80000428:	489d                	li	a7,7
    register uint64 a0 asm("a0") = 1;
    8000042a:	4505                	li	a0,1
    register uint64 a1 asm("a1") = (uint64)empty;
    8000042c:	fe040793          	add	a5,s0,-32
    80000430:	85be                	mv	a1,a5
    register uint64 a2 asm("a2") = 0;
    80000432:	4601                	li	a2,0
    asm volatile("ecall" : "+r"(a0) : "r"(a7), "r"(a1), "r"(a2));
    80000434:	00000073          	ecall
    int result1 = (int)a0;  // ⭐ 立即保存
    80000438:	87aa                	mv	a5,a0
    8000043a:	fef42623          	sw	a5,-20(s0)
    printf("Empty string write returned: %d\n", result1);
    8000043e:	fec42783          	lw	a5,-20(s0)
    80000442:	85be                	mv	a1,a5
    80000444:	00006517          	auipc	a0,0x6
    80000448:	fbc50513          	add	a0,a0,-68 # 80006400 <userret+0x39c>
    8000044c:	00000097          	auipc	ra,0x0
    80000450:	79a080e7          	jalr	1946(ra) # 80000be6 <printf>
    
    char single[] = "X";
    80000454:	05800793          	li	a5,88
    80000458:	fcf41c23          	sh	a5,-40(s0)
    a0 = 1;
    8000045c:	4505                	li	a0,1
    a1 = (uint64)single;
    8000045e:	fd840793          	add	a5,s0,-40
    80000462:	85be                	mv	a1,a5
    a2 = 1;
    80000464:	4605                	li	a2,1
    asm volatile("ecall" : "+r"(a0) : "r"(a7), "r"(a1), "r"(a2));
    80000466:	00000073          	ecall
    int result2 = (int)a0;  // ⭐ 立即保存
    8000046a:	87aa                	mv	a5,a0
    8000046c:	fef42423          	sw	a5,-24(s0)
    printf("\nSingle char write returned: %d\n", result2);
    80000470:	fe842783          	lw	a5,-24(s0)
    80000474:	85be                	mv	a1,a5
    80000476:	00006517          	auipc	a0,0x6
    8000047a:	fb250513          	add	a0,a0,-78 # 80006428 <userret+0x3c4>
    8000047e:	00000097          	auipc	ra,0x0
    80000482:	768080e7          	jalr	1896(ra) # 80000be6 <printf>
    
    char longstr[] = "This is a longer string to test the write system call functionality!\n";
    80000486:	00006797          	auipc	a5,0x6
    8000048a:	00a78793          	add	a5,a5,10 # 80006490 <userret+0x42c>
    8000048e:	0007be03          	ld	t3,0(a5)
    80000492:	0087b303          	ld	t1,8(a5)
    80000496:	0107b803          	ld	a6,16(a5)
    8000049a:	6f88                	ld	a0,24(a5)
    8000049c:	738c                	ld	a1,32(a5)
    8000049e:	7790                	ld	a2,40(a5)
    800004a0:	7b94                	ld	a3,48(a5)
    800004a2:	7f98                	ld	a4,56(a5)
    800004a4:	f9c43823          	sd	t3,-112(s0)
    800004a8:	f8643c23          	sd	t1,-104(s0)
    800004ac:	fb043023          	sd	a6,-96(s0)
    800004b0:	faa43423          	sd	a0,-88(s0)
    800004b4:	fab43823          	sd	a1,-80(s0)
    800004b8:	fac43c23          	sd	a2,-72(s0)
    800004bc:	fcd43023          	sd	a3,-64(s0)
    800004c0:	fce43423          	sd	a4,-56(s0)
    800004c4:	43b8                	lw	a4,64(a5)
    800004c6:	fce42823          	sw	a4,-48(s0)
    800004ca:	0447d783          	lhu	a5,68(a5)
    800004ce:	fcf41a23          	sh	a5,-44(s0)
    a0 = 1;
    800004d2:	4505                	li	a0,1
    a1 = (uint64)longstr;
    800004d4:	f9040793          	add	a5,s0,-112
    800004d8:	85be                	mv	a1,a5
    a2 = 70;
    800004da:	04600613          	li	a2,70
    asm volatile("ecall" : "+r"(a0) : "r"(a7), "r"(a1), "r"(a2));
    800004de:	00000073          	ecall
    int result3 = (int)a0;  // ⭐ 立即保存
    800004e2:	87aa                	mv	a5,a0
    800004e4:	fef42223          	sw	a5,-28(s0)
    printf("Long string write returned: %d\n", result3);
    800004e8:	fe442783          	lw	a5,-28(s0)
    800004ec:	85be                	mv	a1,a5
    800004ee:	00006517          	auipc	a0,0x6
    800004f2:	f6250513          	add	a0,a0,-158 # 80006450 <userret+0x3ec>
    800004f6:	00000097          	auipc	ra,0x0
    800004fa:	6f0080e7          	jalr	1776(ra) # 80000be6 <printf>
    
    printf("✓ Edge cases test PASSED\n");
    800004fe:	00006517          	auipc	a0,0x6
    80000502:	f7250513          	add	a0,a0,-142 # 80006470 <userret+0x40c>
    80000506:	00000097          	auipc	ra,0x0
    8000050a:	6e0080e7          	jalr	1760(ra) # 80000be6 <printf>
}
    8000050e:	0001                	nop
    80000510:	70a6                	ld	ra,104(sp)
    80000512:	7406                	ld	s0,96(sp)
    80000514:	6165                	add	sp,sp,112
    80000516:	8082                	ret

0000000080000518 <syscall_test_process>:

// ==================== 主测试进程 ====================
void syscall_test_process(void) {
    80000518:	1141                	add	sp,sp,-16
    8000051a:	e406                	sd	ra,8(sp)
    8000051c:	e022                	sd	s0,0(sp)
    8000051e:	0800                	add	s0,sp,16
    printf("\n");
    80000520:	00006517          	auipc	a0,0x6
    80000524:	fb850513          	add	a0,a0,-72 # 800064d8 <userret+0x474>
    80000528:	00000097          	auipc	ra,0x0
    8000052c:	6be080e7          	jalr	1726(ra) # 80000be6 <printf>
    printf("========================================\n");
    80000530:	00006517          	auipc	a0,0x6
    80000534:	fb050513          	add	a0,a0,-80 # 800064e0 <userret+0x47c>
    80000538:	00000097          	auipc	ra,0x0
    8000053c:	6ae080e7          	jalr	1710(ra) # 80000be6 <printf>
    printf("=== System Call Test Process Started ===\n");
    80000540:	00006517          	auipc	a0,0x6
    80000544:	fd050513          	add	a0,a0,-48 # 80006510 <userret+0x4ac>
    80000548:	00000097          	auipc	ra,0x0
    8000054c:	69e080e7          	jalr	1694(ra) # 80000be6 <printf>
    printf("========================================\n");
    80000550:	00006517          	auipc	a0,0x6
    80000554:	f9050513          	add	a0,a0,-112 # 800064e0 <userret+0x47c>
    80000558:	00000097          	auipc	ra,0x0
    8000055c:	68e080e7          	jalr	1678(ra) # 80000be6 <printf>
    printf("PID: %d\n", myproc()->pid);
    80000560:	00003097          	auipc	ra,0x3
    80000564:	478080e7          	jalr	1144(ra) # 800039d8 <myproc>
    80000568:	87aa                	mv	a5,a0
    8000056a:	439c                	lw	a5,0(a5)
    8000056c:	85be                	mv	a1,a5
    8000056e:	00006517          	auipc	a0,0x6
    80000572:	fd250513          	add	a0,a0,-46 # 80006540 <userret+0x4dc>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	670080e7          	jalr	1648(ra) # 80000be6 <printf>
    printf("Name: %s\n", myproc()->name);
    8000057e:	00003097          	auipc	ra,0x3
    80000582:	45a080e7          	jalr	1114(ra) # 800039d8 <myproc>
    80000586:	87aa                	mv	a5,a0
    80000588:	07a1                	add	a5,a5,8
    8000058a:	85be                	mv	a1,a5
    8000058c:	00006517          	auipc	a0,0x6
    80000590:	fc450513          	add	a0,a0,-60 # 80006550 <userret+0x4ec>
    80000594:	00000097          	auipc	ra,0x0
    80000598:	652080e7          	jalr	1618(ra) # 80000be6 <printf>
    printf("\n");
    8000059c:	00006517          	auipc	a0,0x6
    800005a0:	f3c50513          	add	a0,a0,-196 # 800064d8 <userret+0x474>
    800005a4:	00000097          	auipc	ra,0x0
    800005a8:	642080e7          	jalr	1602(ra) # 80000be6 <printf>
    
    test_getpid();
    800005ac:	00000097          	auipc	ra,0x0
    800005b0:	b7e080e7          	jalr	-1154(ra) # 8000012a <test_getpid>
    test_write();
    800005b4:	00000097          	auipc	ra,0x0
    800005b8:	c14080e7          	jalr	-1004(ra) # 800001c8 <test_write>
    test_multiple_syscalls();
    800005bc:	00000097          	auipc	ra,0x0
    800005c0:	ca4080e7          	jalr	-860(ra) # 80000260 <test_multiple_syscalls>
    test_syscall_parameters();
    800005c4:	00000097          	auipc	ra,0x0
    800005c8:	d18080e7          	jalr	-744(ra) # 800002dc <test_syscall_parameters>
    test_invalid_syscall();
    800005cc:	00000097          	auipc	ra,0x0
    800005d0:	dca080e7          	jalr	-566(ra) # 80000396 <test_invalid_syscall>
    test_write_edge_cases();
    800005d4:	00000097          	auipc	ra,0x0
    800005d8:	e38080e7          	jalr	-456(ra) # 8000040c <test_write_edge_cases>
    
    printf("\n");
    800005dc:	00006517          	auipc	a0,0x6
    800005e0:	efc50513          	add	a0,a0,-260 # 800064d8 <userret+0x474>
    800005e4:	00000097          	auipc	ra,0x0
    800005e8:	602080e7          	jalr	1538(ra) # 80000be6 <printf>
    printf("========================================\n");
    800005ec:	00006517          	auipc	a0,0x6
    800005f0:	ef450513          	add	a0,a0,-268 # 800064e0 <userret+0x47c>
    800005f4:	00000097          	auipc	ra,0x0
    800005f8:	5f2080e7          	jalr	1522(ra) # 80000be6 <printf>
    printf("=== All System Call Tests Completed ===\n");
    800005fc:	00006517          	auipc	a0,0x6
    80000600:	f6450513          	add	a0,a0,-156 # 80006560 <userret+0x4fc>
    80000604:	00000097          	auipc	ra,0x0
    80000608:	5e2080e7          	jalr	1506(ra) # 80000be6 <printf>
    printf("========================================\n");
    8000060c:	00006517          	auipc	a0,0x6
    80000610:	ed450513          	add	a0,a0,-300 # 800064e0 <userret+0x47c>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	5d2080e7          	jalr	1490(ra) # 80000be6 <printf>
    printf("\n");
    8000061c:	00006517          	auipc	a0,0x6
    80000620:	ebc50513          	add	a0,a0,-324 # 800064d8 <userret+0x474>
    80000624:	00000097          	auipc	ra,0x0
    80000628:	5c2080e7          	jalr	1474(ra) # 80000be6 <printf>
    
    // ⭐ 修复：测试完成后退出进程
    printf("Process exiting...\n");
    8000062c:	00006517          	auipc	a0,0x6
    80000630:	f6450513          	add	a0,a0,-156 # 80006590 <userret+0x52c>
    80000634:	00000097          	auipc	ra,0x0
    80000638:	5b2080e7          	jalr	1458(ra) # 80000be6 <printf>
    exit_proc(0);
    8000063c:	4501                	li	a0,0
    8000063e:	00004097          	auipc	ra,0x4
    80000642:	bb2080e7          	jalr	-1102(ra) # 800041f0 <exit_proc>
    
    // 不会执行到这里
    for(;;);
    80000646:	0001                	nop
    80000648:	bffd                	j	80000646 <syscall_test_process+0x12e>

000000008000064a <main>:
}

// ==================== 系统主函数 ====================
void main(void) {
    8000064a:	7179                	add	sp,sp,-48
    8000064c:	f406                	sd	ra,40(sp)
    8000064e:	f022                	sd	s0,32(sp)
    80000650:	1800                	add	s0,sp,48
    printf("\n");
    80000652:	00006517          	auipc	a0,0x6
    80000656:	e8650513          	add	a0,a0,-378 # 800064d8 <userret+0x474>
    8000065a:	00000097          	auipc	ra,0x0
    8000065e:	58c080e7          	jalr	1420(ra) # 80000be6 <printf>
    printf("========================================\n");
    80000662:	00006517          	auipc	a0,0x6
    80000666:	e7e50513          	add	a0,a0,-386 # 800064e0 <userret+0x47c>
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	57c080e7          	jalr	1404(ra) # 80000be6 <printf>
    printf("=== RISC-V OS Lab 6: System Calls ===\n");
    80000672:	00006517          	auipc	a0,0x6
    80000676:	f3650513          	add	a0,a0,-202 # 800065a8 <userret+0x544>
    8000067a:	00000097          	auipc	ra,0x0
    8000067e:	56c080e7          	jalr	1388(ra) # 80000be6 <printf>
    printf("========================================\n");
    80000682:	00006517          	auipc	a0,0x6
    80000686:	e5e50513          	add	a0,a0,-418 # 800064e0 <userret+0x47c>
    8000068a:	00000097          	auipc	ra,0x0
    8000068e:	55c080e7          	jalr	1372(ra) # 80000be6 <printf>
    
    printf("\nSystem Information:\n");
    80000692:	00006517          	auipc	a0,0x6
    80000696:	f3e50513          	add	a0,a0,-194 # 800065d0 <userret+0x56c>
    8000069a:	00000097          	auipc	ra,0x0
    8000069e:	54c080e7          	jalr	1356(ra) # 80000be6 <printf>
    printf("  Hart ID:  %d\n", (int)r_tp());
    800006a2:	8792                	mv	a5,tp
    800006a4:	fef43423          	sd	a5,-24(s0)
    800006a8:	fe843783          	ld	a5,-24(s0)
    800006ac:	2781                	sext.w	a5,a5
    800006ae:	85be                	mv	a1,a5
    800006b0:	00006517          	auipc	a0,0x6
    800006b4:	f3850513          	add	a0,a0,-200 # 800065e8 <userret+0x584>
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	52e080e7          	jalr	1326(ra) # 80000be6 <printf>
    printf("  KERNBASE: %p\n", (void*)0x80000000L);
    800006c0:	4785                	li	a5,1
    800006c2:	01f79593          	sll	a1,a5,0x1f
    800006c6:	00006517          	auipc	a0,0x6
    800006ca:	f3250513          	add	a0,a0,-206 # 800065f8 <userret+0x594>
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	518080e7          	jalr	1304(ra) # 80000be6 <printf>
    printf("  PHYSTOP:  %p\n", (void*)0x88000000L);
    800006d6:	47c5                	li	a5,17
    800006d8:	01b79593          	sll	a1,a5,0x1b
    800006dc:	00006517          	auipc	a0,0x6
    800006e0:	f2c50513          	add	a0,a0,-212 # 80006608 <userret+0x5a4>
    800006e4:	00000097          	auipc	ra,0x0
    800006e8:	502080e7          	jalr	1282(ra) # 80000be6 <printf>
    
    printf("\nKernel symbols:\n");
    800006ec:	00006517          	auipc	a0,0x6
    800006f0:	f2c50513          	add	a0,a0,-212 # 80006618 <userret+0x5b4>
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	4f2080e7          	jalr	1266(ra) # 80000be6 <printf>
    printf("  etext: %p\n", etext);
    800006fc:	00006597          	auipc	a1,0x6
    80000700:	90458593          	add	a1,a1,-1788 # 80006000 <etext>
    80000704:	00006517          	auipc	a0,0x6
    80000708:	f2c50513          	add	a0,a0,-212 # 80006630 <userret+0x5cc>
    8000070c:	00000097          	auipc	ra,0x0
    80000710:	4da080e7          	jalr	1242(ra) # 80000be6 <printf>
    printf("  edata: %p\n", edata);
    80000714:	0000a597          	auipc	a1,0xa
    80000718:	8ec58593          	add	a1,a1,-1812 # 8000a000 <panicking>
    8000071c:	00006517          	auipc	a0,0x6
    80000720:	f2450513          	add	a0,a0,-220 # 80006640 <userret+0x5dc>
    80000724:	00000097          	auipc	ra,0x0
    80000728:	4c2080e7          	jalr	1218(ra) # 80000be6 <printf>
    printf("  end:   %p\n", end);
    8000072c:	00012597          	auipc	a1,0x12
    80000730:	8d458593          	add	a1,a1,-1836 # 80012000 <end>
    80000734:	00006517          	auipc	a0,0x6
    80000738:	f1c50513          	add	a0,a0,-228 # 80006650 <userret+0x5ec>
    8000073c:	00000097          	auipc	ra,0x0
    80000740:	4aa080e7          	jalr	1194(ra) # 80000be6 <printf>
    
    printf("\n=== Phase 1: Physical Memory Management ===\n");
    80000744:	00006517          	auipc	a0,0x6
    80000748:	f1c50513          	add	a0,a0,-228 # 80006660 <userret+0x5fc>
    8000074c:	00000097          	auipc	ra,0x0
    80000750:	49a080e7          	jalr	1178(ra) # 80000be6 <printf>
    pmm_init();
    80000754:	00001097          	auipc	ra,0x1
    80000758:	a88080e7          	jalr	-1400(ra) # 800011dc <pmm_init>
    pmm_info();
    8000075c:	00001097          	auipc	ra,0x1
    80000760:	cde080e7          	jalr	-802(ra) # 8000143a <pmm_info>
    
    printf("\n=== Phase 2: Virtual Memory Activation ===\n");
    80000764:	00006517          	auipc	a0,0x6
    80000768:	f2c50513          	add	a0,a0,-212 # 80006690 <userret+0x62c>
    8000076c:	00000097          	auipc	ra,0x0
    80000770:	47a080e7          	jalr	1146(ra) # 80000be6 <printf>
    printf("Current satp: %p\n", (void*)r_satp());
    80000774:	180027f3          	csrr	a5,satp
    80000778:	fef43023          	sd	a5,-32(s0)
    8000077c:	fe043783          	ld	a5,-32(s0)
    80000780:	85be                	mv	a1,a5
    80000782:	00006517          	auipc	a0,0x6
    80000786:	f3e50513          	add	a0,a0,-194 # 800066c0 <userret+0x65c>
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	45c080e7          	jalr	1116(ra) # 80000be6 <printf>
    kvminit();
    80000792:	00001097          	auipc	ra,0x1
    80000796:	18a080e7          	jalr	394(ra) # 8000191c <kvminit>
    kvminithart();
    8000079a:	00001097          	auipc	ra,0x1
    8000079e:	354080e7          	jalr	852(ra) # 80001aee <kvminithart>
    printf("Virtual memory enabled! New satp: %p\n", (void*)r_satp());
    800007a2:	180027f3          	csrr	a5,satp
    800007a6:	fcf43c23          	sd	a5,-40(s0)
    800007aa:	fd843783          	ld	a5,-40(s0)
    800007ae:	85be                	mv	a1,a5
    800007b0:	00006517          	auipc	a0,0x6
    800007b4:	f2850513          	add	a0,a0,-216 # 800066d8 <userret+0x674>
    800007b8:	00000097          	auipc	ra,0x0
    800007bc:	42e080e7          	jalr	1070(ra) # 80000be6 <printf>
    
    printf("\n=== Phase 3: Interrupt System ===\n");
    800007c0:	00006517          	auipc	a0,0x6
    800007c4:	f4050513          	add	a0,a0,-192 # 80006700 <userret+0x69c>
    800007c8:	00000097          	auipc	ra,0x0
    800007cc:	41e080e7          	jalr	1054(ra) # 80000be6 <printf>
    trap_init();
    800007d0:	00002097          	auipc	ra,0x2
    800007d4:	ca2080e7          	jalr	-862(ra) # 80002472 <trap_init>
    
    printf("\n=== Phase 4: Timer System ===\n");
    800007d8:	00006517          	auipc	a0,0x6
    800007dc:	f5050513          	add	a0,a0,-176 # 80006728 <userret+0x6c4>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	406080e7          	jalr	1030(ra) # 80000be6 <printf>
    timer_init();
    800007e8:	00003097          	auipc	ra,0x3
    800007ec:	00a080e7          	jalr	10(ra) # 800037f2 <timer_init>
    
    printf("\n=== Phase 5: Process System ===\n");
    800007f0:	00006517          	auipc	a0,0x6
    800007f4:	f5850513          	add	a0,a0,-168 # 80006748 <userret+0x6e4>
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	3ee080e7          	jalr	1006(ra) # 80000be6 <printf>
    procinit();
    80000800:	00003097          	auipc	ra,0x3
    80000804:	0f6080e7          	jalr	246(ra) # 800038f6 <procinit>
    
    // ==================== Phase 6: 创建用户进程 ====================
    printf("\n=== Phase 6: Creating First User Process ===\n");
    80000808:	00006517          	auipc	a0,0x6
    8000080c:	f6850513          	add	a0,a0,-152 # 80006770 <userret+0x70c>
    80000810:	00000097          	auipc	ra,0x0
    80000814:	3d6080e7          	jalr	982(ra) # 80000be6 <printf>

    int init_pid = userinit();  // ← 改用 userinit
    80000818:	00004097          	auipc	ra,0x4
    8000081c:	b48080e7          	jalr	-1208(ra) # 80004360 <userinit>
    80000820:	87aa                	mv	a5,a0
    80000822:	fcf42a23          	sw	a5,-44(s0)
    if(init_pid < 0) {
    80000826:	fd442783          	lw	a5,-44(s0)
    8000082a:	2781                	sext.w	a5,a5
    8000082c:	0007da63          	bgez	a5,80000840 <main+0x1f6>
        panic("failed to create init process");
    80000830:	00006517          	auipc	a0,0x6
    80000834:	f7050513          	add	a0,a0,-144 # 800067a0 <userret+0x73c>
    80000838:	00000097          	auipc	ra,0x0
    8000083c:	754080e7          	jalr	1876(ra) # 80000f8c <panic>
    }

    printf("First user process created with PID %d\n", init_pid);
    80000840:	fd442783          	lw	a5,-44(s0)
    80000844:	85be                	mv	a1,a5
    80000846:	00006517          	auipc	a0,0x6
    8000084a:	f7a50513          	add	a0,a0,-134 # 800067c0 <userret+0x75c>
    8000084e:	00000097          	auipc	ra,0x0
    80000852:	398080e7          	jalr	920(ra) # 80000be6 <printf>
    printf("This process runs in U-mode (user mode)!\n");
    80000856:	00006517          	auipc	a0,0x6
    8000085a:	f9250513          	add	a0,a0,-110 # 800067e8 <userret+0x784>
    8000085e:	00000097          	auipc	ra,0x0
    80000862:	388080e7          	jalr	904(ra) # 80000be6 <printf>
    printf("\n=== System Ready ===\n");
    80000866:	00006517          	auipc	a0,0x6
    8000086a:	fb250513          	add	a0,a0,-78 # 80006818 <userret+0x7b4>
    8000086e:	00000097          	auipc	ra,0x0
    80000872:	378080e7          	jalr	888(ra) # 80000be6 <printf>
    printf("All subsystems initialized successfully!\n");
    80000876:	00006517          	auipc	a0,0x6
    8000087a:	fba50513          	add	a0,a0,-70 # 80006830 <userret+0x7cc>
    8000087e:	00000097          	auipc	ra,0x0
    80000882:	368080e7          	jalr	872(ra) # 80000be6 <printf>
    printf("- Physical memory manager\n");
    80000886:	00006517          	auipc	a0,0x6
    8000088a:	fda50513          	add	a0,a0,-38 # 80006860 <userret+0x7fc>
    8000088e:	00000097          	auipc	ra,0x0
    80000892:	358080e7          	jalr	856(ra) # 80000be6 <printf>
    printf("- Virtual memory (Sv39)\n");
    80000896:	00006517          	auipc	a0,0x6
    8000089a:	fea50513          	add	a0,a0,-22 # 80006880 <userret+0x81c>
    8000089e:	00000097          	auipc	ra,0x0
    800008a2:	348080e7          	jalr	840(ra) # 80000be6 <printf>
    printf("- Interrupt handling\n");
    800008a6:	00006517          	auipc	a0,0x6
    800008aa:	ffa50513          	add	a0,a0,-6 # 800068a0 <userret+0x83c>
    800008ae:	00000097          	auipc	ra,0x0
    800008b2:	338080e7          	jalr	824(ra) # 80000be6 <printf>
    printf("- Timer interrupts (100ms)\n");
    800008b6:	00006517          	auipc	a0,0x6
    800008ba:	00250513          	add	a0,a0,2 # 800068b8 <userret+0x854>
    800008be:	00000097          	auipc	ra,0x0
    800008c2:	328080e7          	jalr	808(ra) # 80000be6 <printf>
    printf("- Process management\n");
    800008c6:	00006517          	auipc	a0,0x6
    800008ca:	01250513          	add	a0,a0,18 # 800068d8 <userret+0x874>
    800008ce:	00000097          	auipc	ra,0x0
    800008d2:	318080e7          	jalr	792(ra) # 80000be6 <printf>
    printf("- System call interface\n");
    800008d6:	00006517          	auipc	a0,0x6
    800008da:	01a50513          	add	a0,a0,26 # 800068f0 <userret+0x88c>
    800008de:	00000097          	auipc	ra,0x0
    800008e2:	308080e7          	jalr	776(ra) # 80000be6 <printf>
    
    printf("\n========================================\n");
    800008e6:	00006517          	auipc	a0,0x6
    800008ea:	02a50513          	add	a0,a0,42 # 80006910 <userret+0x8ac>
    800008ee:	00000097          	auipc	ra,0x0
    800008f2:	2f8080e7          	jalr	760(ra) # 80000be6 <printf>
    printf("Starting scheduler...\n");
    800008f6:	00006517          	auipc	a0,0x6
    800008fa:	04a50513          	add	a0,a0,74 # 80006940 <userret+0x8dc>
    800008fe:	00000097          	auipc	ra,0x0
    80000902:	2e8080e7          	jalr	744(ra) # 80000be6 <printf>
    printf("The system will now run the test process.\n");
    80000906:	00006517          	auipc	a0,0x6
    8000090a:	05250513          	add	a0,a0,82 # 80006958 <userret+0x8f4>
    8000090e:	00000097          	auipc	ra,0x0
    80000912:	2d8080e7          	jalr	728(ra) # 80000be6 <printf>
    printf("========================================\n\n");
    80000916:	00006517          	auipc	a0,0x6
    8000091a:	07250513          	add	a0,a0,114 # 80006988 <userret+0x924>
    8000091e:	00000097          	auipc	ra,0x0
    80000922:	2c8080e7          	jalr	712(ra) # 80000be6 <printf>
    
    scheduler();
    80000926:	00003097          	auipc	ra,0x3
    8000092a:	54a080e7          	jalr	1354(ra) # 80003e70 <scheduler>

000000008000092e <uartinit>:
/* 外部变量声明 */
extern volatile int panicking;
extern volatile int panicked;

void uartinit(void)
{
    8000092e:	1141                	add	sp,sp,-16
    80000930:	e422                	sd	s0,8(sp)
    80000932:	0800                	add	s0,sp,16
  // 1. 禁用所有中断（简化设计，使用轮询模式）
  WriteReg(IER, 0x00);
    80000934:	100007b7          	lui	a5,0x10000
    80000938:	0785                	add	a5,a5,1 # 10000001 <_entry-0x6fffffff>
    8000093a:	00078023          	sb	zero,0(a5)
   // 2. 设置波特率为38400
  WriteReg(LCR, LCR_BAUD_LATCH);// 进入波特率设置模式
    8000093e:	100007b7          	lui	a5,0x10000
    80000942:	078d                	add	a5,a5,3 # 10000003 <_entry-0x6ffffffd>
    80000944:	f8000713          	li	a4,-128
    80000948:	00e78023          	sb	a4,0(a5)
  WriteReg(0, 0x03);// 低字节
    8000094c:	100007b7          	lui	a5,0x10000
    80000950:	470d                	li	a4,3
    80000952:	00e78023          	sb	a4,0(a5) # 10000000 <_entry-0x70000000>
  WriteReg(1, 0x00);// 高字节
    80000956:	100007b7          	lui	a5,0x10000
    8000095a:	0785                	add	a5,a5,1 # 10000001 <_entry-0x6fffffff>
    8000095c:	00078023          	sb	zero,0(a5)
  // 3. 配置数据格式：8位数据，无校验位
  WriteReg(LCR, LCR_EIGHT_BITS);
    80000960:	100007b7          	lui	a5,0x10000
    80000964:	078d                	add	a5,a5,3 # 10000003 <_entry-0x6ffffffd>
    80000966:	470d                	li	a4,3
    80000968:	00e78023          	sb	a4,0(a5)
  // 4. 启用并清空FIFO缓冲区
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    8000096c:	100007b7          	lui	a5,0x10000
    80000970:	0789                	add	a5,a5,2 # 10000002 <_entry-0x6ffffffe>
    80000972:	471d                	li	a4,7
    80000974:	00e78023          	sb	a4,0(a5)
}
    80000978:	0001                	nop
    8000097a:	6422                	ld	s0,8(sp)
    8000097c:	0141                	add	sp,sp,16
    8000097e:	8082                	ret

0000000080000980 <uartputc_sync>:

/* 同步字符输出 */
void uartputc_sync(int c)
{// 1. 检查系统是否panic
    80000980:	1101                	add	sp,sp,-32
    80000982:	ec22                	sd	s0,24(sp)
    80000984:	1000                	add	s0,sp,32
    80000986:	87aa                	mv	a5,a0
    80000988:	fef42623          	sw	a5,-20(s0)
  if(panicked){
    8000098c:	00009797          	auipc	a5,0x9
    80000990:	67878793          	add	a5,a5,1656 # 8000a004 <panicked>
    80000994:	439c                	lw	a5,0(a5)
    80000996:	2781                	sext.w	a5,a5
    80000998:	c399                	beqz	a5,8000099e <uartputc_sync+0x1e>
    for(;;)// 如果系统崩溃，停止输出
    8000099a:	0001                	nop
    8000099c:	bffd                	j	8000099a <uartputc_sync+0x1a>
      ;
  }
 // 2. 等待发送寄存器空闲
 // 忙等待 - 轮询LSR寄存器的TX_IDLE位
// 这确保上一个字符发送完成后再发送新字符
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000099e:	0001                	nop
    800009a0:	100007b7          	lui	a5,0x10000
    800009a4:	0795                	add	a5,a5,5 # 10000005 <_entry-0x6ffffffb>
    800009a6:	0007c783          	lbu	a5,0(a5)
    800009aa:	0ff7f793          	zext.b	a5,a5
    800009ae:	2781                	sext.w	a5,a5
    800009b0:	0207f793          	and	a5,a5,32
    800009b4:	2781                	sext.w	a5,a5
    800009b6:	d7ed                	beqz	a5,800009a0 <uartputc_sync+0x20>
    ;
  // 3. 将字符写入发送寄存器
  WriteReg(THR, c);
    800009b8:	100007b7          	lui	a5,0x10000
    800009bc:	fec42703          	lw	a4,-20(s0)
    800009c0:	0ff77713          	zext.b	a4,a4
    800009c4:	00e78023          	sb	a4,0(a5) # 10000000 <_entry-0x70000000>
  // 硬件会自动开始发送这个字符
}
    800009c8:	0001                	nop
    800009ca:	6462                	ld	s0,24(sp)
    800009cc:	6105                	add	sp,sp,32
    800009ce:	8082                	ret

00000000800009d0 <uartgetc>:

int uartgetc(void)
{
    800009d0:	1141                	add	sp,sp,-16
    800009d2:	e422                	sd	s0,8(sp)
    800009d4:	0800                	add	s0,sp,16
  // 第1步：检查串口是否有数据可读
  // LSR_RX_READY 位表示"接收缓冲区有数据"
  if(ReadReg(LSR) & LSR_RX_READY) {
    800009d6:	100007b7          	lui	a5,0x10000
    800009da:	0795                	add	a5,a5,5 # 10000005 <_entry-0x6ffffffb>
    800009dc:	0007c783          	lbu	a5,0(a5)
    800009e0:	0ff7f793          	zext.b	a5,a5
    800009e4:	2781                	sext.w	a5,a5
    800009e6:	8b85                	and	a5,a5,1
    800009e8:	2781                	sext.w	a5,a5
    800009ea:	cb89                	beqz	a5,800009fc <uartgetc+0x2c>
    
    // 第2步：如果有数据，从接收寄存器读取一个字符
    // RHR = Receive Holding Register (接收保持寄存器)
    return ReadReg(RHR);
    800009ec:	100007b7          	lui	a5,0x10000
    800009f0:	0007c783          	lbu	a5,0(a5) # 10000000 <_entry-0x70000000>
    800009f4:	0ff7f793          	zext.b	a5,a5
    800009f8:	2781                	sext.w	a5,a5
    800009fa:	a011                	j	800009fe <uartgetc+0x2e>
    
  } else {
    
    // 第3步：如果没有数据，返回-1表示"没有数据"
    return -1;
    800009fc:	57fd                	li	a5,-1
  }
}
    800009fe:	853e                	mv	a0,a5
    80000a00:	6422                	ld	s0,8(sp)
    80000a02:	0141                	add	sp,sp,16
    80000a04:	8082                	ret

0000000080000a06 <consputc>:
// consputc()是一个适配器：
// - 上层(printf)期望简单的字符输出接口
// - 下层(uart)提供硬件特定的接口
// - console层负责适配和转换
void consputc(int c)
{
    80000a06:	1101                	add	sp,sp,-32
    80000a08:	ec06                	sd	ra,24(sp)
    80000a0a:	e822                	sd	s0,16(sp)
    80000a0c:	1000                	add	s0,sp,32
    80000a0e:	87aa                	mv	a5,a0
    80000a10:	fef42623          	sw	a5,-20(s0)
  if(c == BACKSPACE){
    80000a14:	fec42783          	lw	a5,-20(s0)
    80000a18:	0007871b          	sext.w	a4,a5
    80000a1c:	10000793          	li	a5,256
    80000a20:	02f71363          	bne	a4,a5,80000a46 <consputc+0x40>
    // 退格处理：输出 退格-空格-退格 序列
     uartputc_sync('\b');   // 光标后退一位
    80000a24:	4521                	li	a0,8
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	f5a080e7          	jalr	-166(ra) # 80000980 <uartputc_sync>
     uartputc_sync(' ');    // 用空格覆盖字符  
    80000a2e:	02000513          	li	a0,32
    80000a32:	00000097          	auipc	ra,0x0
    80000a36:	f4e080e7          	jalr	-178(ra) # 80000980 <uartputc_sync>
     uartputc_sync('\b');   // 光标再后退一位
    80000a3a:	4521                	li	a0,8
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	f44080e7          	jalr	-188(ra) # 80000980 <uartputc_sync>
  } else {
    // 普通字符直接传递给硬件层
    uartputc_sync(c);
  }
}
    80000a44:	a801                	j	80000a54 <consputc+0x4e>
    uartputc_sync(c);
    80000a46:	fec42783          	lw	a5,-20(s0)
    80000a4a:	853e                	mv	a0,a5
    80000a4c:	00000097          	auipc	ra,0x0
    80000a50:	f34080e7          	jalr	-204(ra) # 80000980 <uartputc_sync>
}
    80000a54:	0001                	nop
    80000a56:	60e2                	ld	ra,24(sp)
    80000a58:	6442                	ld	s0,16(sp)
    80000a5a:	6105                	add	sp,sp,32
    80000a5c:	8082                	ret

0000000080000a5e <consoleinit>:
/* 初始化函数 */
void consoleinit(void)
{
    80000a5e:	1141                	add	sp,sp,-16
    80000a60:	e406                	sd	ra,8(sp)
    80000a62:	e022                	sd	s0,0(sp)
    80000a64:	0800                	add	s0,sp,16
  uartinit();// 先初始化硬件层
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ec8080e7          	jalr	-312(ra) # 8000092e <uartinit>
  printfinit();    // 再初始化printf系统， printf系统依赖硬件工作
    80000a6e:	00000097          	auipc	ra,0x0
    80000a72:	56a080e7          	jalr	1386(ra) # 80000fd8 <printfinit>
}
    80000a76:	0001                	nop
    80000a78:	60a2                	ld	ra,8(sp)
    80000a7a:	6402                	ld	s0,0(sp)
    80000a7c:	0141                	add	sp,sp,16
    80000a7e:	8082                	ret

0000000080000a80 <printint>:
volatile int panicked = 0;// 系统是否已经panic完成，崩溃处理完成

static char digits[] = "0123456789abcdef";// 数字字符映射表

static void printint(long long xx, int base, int sign)
{
    80000a80:	715d                	add	sp,sp,-80
    80000a82:	e486                	sd	ra,72(sp)
    80000a84:	e0a2                	sd	s0,64(sp)
    80000a86:	0880                	add	s0,sp,80
    80000a88:	faa43c23          	sd	a0,-72(s0)
    80000a8c:	87ae                	mv	a5,a1
    80000a8e:	8732                	mv	a4,a2
    80000a90:	faf42a23          	sw	a5,-76(s0)
    80000a94:	87ba                	mv	a5,a4
    80000a96:	faf42823          	sw	a5,-80(s0)
  unsigned long long x;       // 无符号版本的数字
// 关键：x是unsigned类型！
// -(-2147483648) 在unsigned中是安全的

  // 处理负数
  if(sign && (sign = (xx < 0)))
    80000a9a:	fb042783          	lw	a5,-80(s0)
    80000a9e:	2781                	sext.w	a5,a5
    80000aa0:	c39d                	beqz	a5,80000ac6 <printint+0x46>
    80000aa2:	fb843783          	ld	a5,-72(s0)
    80000aa6:	93fd                	srl	a5,a5,0x3f
    80000aa8:	0ff7f793          	zext.b	a5,a5
    80000aac:	faf42823          	sw	a5,-80(s0)
    80000ab0:	fb042783          	lw	a5,-80(s0)
    80000ab4:	2781                	sext.w	a5,a5
    80000ab6:	cb81                	beqz	a5,80000ac6 <printint+0x46>
    x = -xx; // 转为正数处理
    80000ab8:	fb843783          	ld	a5,-72(s0)
    80000abc:	40f007b3          	neg	a5,a5
    80000ac0:	fef43023          	sd	a5,-32(s0)
    80000ac4:	a029                	j	80000ace <printint+0x4e>
  else
    x = xx;
    80000ac6:	fb843783          	ld	a5,-72(s0)
    80000aca:	fef43023          	sd	a5,-32(s0)

//  多位数：提取每一位数字
  i = 0;
    80000ace:	fe042623          	sw	zero,-20(s0)
  do {
    buf[i++] = digits[x % base]; // 取余数，得到最低位
    80000ad2:	fb442783          	lw	a5,-76(s0)
    80000ad6:	fe043703          	ld	a4,-32(s0)
    80000ada:	02f77733          	remu	a4,a4,a5
    80000ade:	fec42783          	lw	a5,-20(s0)
    80000ae2:	0017869b          	addw	a3,a5,1
    80000ae6:	fed42623          	sw	a3,-20(s0)
    80000aea:	00008697          	auipc	a3,0x8
    80000aee:	52668693          	add	a3,a3,1318 # 80009010 <digits>
    80000af2:	9736                	add	a4,a4,a3
    80000af4:	00074703          	lbu	a4,0(a4)
    80000af8:	17c1                	add	a5,a5,-16
    80000afa:	97a2                	add	a5,a5,s0
    80000afc:	fce78c23          	sb	a4,-40(a5)
        // 关键：使用digits数组将数字映射为字符
        // 例如：x=42, base=10
        // 第一次：42 % 10 = 2 → buf[0] = '2'
        // 第二次：4 % 10 = 4 → buf[1] = '4' 
  } while((x /= base) != 0);// 整除，处理下一位
    80000b00:	fb442783          	lw	a5,-76(s0)
    80000b04:	fe043703          	ld	a4,-32(s0)
    80000b08:	02f757b3          	divu	a5,a4,a5
    80000b0c:	fef43023          	sd	a5,-32(s0)
    80000b10:	fe043783          	ld	a5,-32(s0)
    80000b14:	ffdd                	bnez	a5,80000ad2 <printint+0x52>
// 用do while而不是while,确保x=0时也能输出'0'
// 添加负号

  if(sign)
    80000b16:	fb042783          	lw	a5,-80(s0)
    80000b1a:	2781                	sext.w	a5,a5
    80000b1c:	cb95                	beqz	a5,80000b50 <printint+0xd0>
    buf[i++] = '-';
    80000b1e:	fec42783          	lw	a5,-20(s0)
    80000b22:	0017871b          	addw	a4,a5,1
    80000b26:	fee42623          	sw	a4,-20(s0)
    80000b2a:	17c1                	add	a5,a5,-16
    80000b2c:	97a2                	add	a5,a5,s0
    80000b2e:	02d00713          	li	a4,45
    80000b32:	fce78c23          	sb	a4,-40(a5)
// 逆序输出（因为是从低位到高位提取的）
  while(--i >= 0)
    80000b36:	a829                	j	80000b50 <printint+0xd0>
    consputc(buf[i]);
    80000b38:	fec42783          	lw	a5,-20(s0)
    80000b3c:	17c1                	add	a5,a5,-16
    80000b3e:	97a2                	add	a5,a5,s0
    80000b40:	fd87c783          	lbu	a5,-40(a5)
    80000b44:	2781                	sext.w	a5,a5
    80000b46:	853e                	mv	a0,a5
    80000b48:	00000097          	auipc	ra,0x0
    80000b4c:	ebe080e7          	jalr	-322(ra) # 80000a06 <consputc>
  while(--i >= 0)
    80000b50:	fec42783          	lw	a5,-20(s0)
    80000b54:	37fd                	addw	a5,a5,-1
    80000b56:	fef42623          	sw	a5,-20(s0)
    80000b5a:	fec42783          	lw	a5,-20(s0)
    80000b5e:	2781                	sext.w	a5,a5
    80000b60:	fc07dce3          	bgez	a5,80000b38 <printint+0xb8>
}
    80000b64:	0001                	nop
    80000b66:	0001                	nop
    80000b68:	60a6                	ld	ra,72(sp)
    80000b6a:	6406                	ld	s0,64(sp)
    80000b6c:	6161                	add	sp,sp,80
    80000b6e:	8082                	ret

0000000080000b70 <printptr>:




static void printptr(uint64 x)
{
    80000b70:	7179                	add	sp,sp,-48
    80000b72:	f406                	sd	ra,40(sp)
    80000b74:	f022                	sd	s0,32(sp)
    80000b76:	1800                	add	s0,sp,48
    80000b78:	fca43c23          	sd	a0,-40(s0)
  int i;
  
  // 第1步：先输出"0x"前缀，表示这是十六进制地址
  consputc('0');
    80000b7c:	03000513          	li	a0,48
    80000b80:	00000097          	auipc	ra,0x0
    80000b84:	e86080e7          	jalr	-378(ra) # 80000a06 <consputc>
  consputc('x');
    80000b88:	07800513          	li	a0,120
    80000b8c:	00000097          	auipc	ra,0x0
    80000b90:	e7a080e7          	jalr	-390(ra) # 80000a06 <consputc>
  
  // 第2步：循环输出地址的每一位十六进制数字
  // sizeof(uint64) * 2 = 8 * 2 = 16位十六进制数字
  // 64位地址需要16个十六进制字符来表示
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4) {
    80000b94:	fe042623          	sw	zero,-20(s0)
    80000b98:	a81d                	j	80000bce <printptr+0x5e>
    // 每次取出最高4位来输出
    // x >> (sizeof(uint64) * 8 - 4) 就是 x >> 60
    // 这样每次都取最高的4位（一个十六进制数字）
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000b9a:	fd843783          	ld	a5,-40(s0)
    80000b9e:	93f1                	srl	a5,a5,0x3c
    80000ba0:	00008717          	auipc	a4,0x8
    80000ba4:	47070713          	add	a4,a4,1136 # 80009010 <digits>
    80000ba8:	97ba                	add	a5,a5,a4
    80000baa:	0007c783          	lbu	a5,0(a5)
    80000bae:	2781                	sext.w	a5,a5
    80000bb0:	853e                	mv	a0,a5
    80000bb2:	00000097          	auipc	ra,0x0
    80000bb6:	e54080e7          	jalr	-428(ra) # 80000a06 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4) {
    80000bba:	fec42783          	lw	a5,-20(s0)
    80000bbe:	2785                	addw	a5,a5,1
    80000bc0:	fef42623          	sw	a5,-20(s0)
    80000bc4:	fd843783          	ld	a5,-40(s0)
    80000bc8:	0792                	sll	a5,a5,0x4
    80000bca:	fcf43c23          	sd	a5,-40(s0)
    80000bce:	fec42783          	lw	a5,-20(s0)
    80000bd2:	873e                	mv	a4,a5
    80000bd4:	47bd                	li	a5,15
    80000bd6:	fce7f2e3          	bgeu	a5,a4,80000b9a <printptr+0x2a>
    // 然后 x <<= 4，把下一组4位移到最高位
  }
}
    80000bda:	0001                	nop
    80000bdc:	0001                	nop
    80000bde:	70a2                	ld	ra,40(sp)
    80000be0:	7402                	ld	s0,32(sp)
    80000be2:	6145                	add	sp,sp,48
    80000be4:	8082                	ret

0000000080000be6 <printf>:

/* printf() - 格式字符串解析 */
int printf(char *fmt, ...)
{
    80000be6:	7175                	add	sp,sp,-144
    80000be8:	e486                	sd	ra,72(sp)
    80000bea:	e0a2                	sd	s0,64(sp)
    80000bec:	0880                	add	s0,sp,80
    80000bee:	faa43c23          	sd	a0,-72(s0)
    80000bf2:	e40c                	sd	a1,8(s0)
    80000bf4:	e810                	sd	a2,16(s0)
    80000bf6:	ec14                	sd	a3,24(s0)
    80000bf8:	f018                	sd	a4,32(s0)
    80000bfa:	f41c                	sd	a5,40(s0)
    80000bfc:	03043823          	sd	a6,48(s0)
    80000c00:	03143c23          	sd	a7,56(s0)
  va_list ap;                 // 可变参数列表
  int i, cx, c0, c1, c2;      // 字符和索引变量
  char *s;                    // 字符串指针

  va_start(ap, fmt);          // 初始化参数列表
    80000c04:	04040793          	add	a5,s0,64
    80000c08:	faf43823          	sd	a5,-80(s0)
    80000c0c:	fb043783          	ld	a5,-80(s0)
    80000c10:	fc878793          	add	a5,a5,-56
    80000c14:	fcf43423          	sd	a5,-56(s0)
// 主循环：逐字符解析格式字符串
  for(i = 0; (cx = fmt[i] & 0xff) != 0; i++){
    80000c18:	fe042623          	sw	zero,-20(s0)
    80000c1c:	a691                	j	80000f60 <printf+0x37a>
    if(cx != '%'){
    80000c1e:	fd442783          	lw	a5,-44(s0)
    80000c22:	0007871b          	sext.w	a4,a5
    80000c26:	02500793          	li	a5,37
    80000c2a:	00f70a63          	beq	a4,a5,80000c3e <printf+0x58>
      // 普通字符直接输出
      consputc(cx);
    80000c2e:	fd442783          	lw	a5,-44(s0)
    80000c32:	853e                	mv	a0,a5
    80000c34:	00000097          	auipc	ra,0x0
    80000c38:	dd2080e7          	jalr	-558(ra) # 80000a06 <consputc>
      continue;
    80000c3c:	ae29                	j	80000f56 <printf+0x370>
    }
    // 遇到%，开始解析格式符
    i++;
    80000c3e:	fec42783          	lw	a5,-20(s0)
    80000c42:	2785                	addw	a5,a5,1
    80000c44:	fef42623          	sw	a5,-20(s0)
    c0 = fmt[i+0] & 0xff;   // 格式符的第一个字符
    80000c48:	fec42783          	lw	a5,-20(s0)
    80000c4c:	fb843703          	ld	a4,-72(s0)
    80000c50:	97ba                	add	a5,a5,a4
    80000c52:	0007c783          	lbu	a5,0(a5)
    80000c56:	fcf42823          	sw	a5,-48(s0)
    c1 = c2 = 0;
    80000c5a:	fe042223          	sw	zero,-28(s0)
    80000c5e:	fe442783          	lw	a5,-28(s0)
    80000c62:	fef42423          	sw	a5,-24(s0)
    if(c0) c1 = fmt[i+1] & 0xff;  // 可能的第二个字符（如%ld中的d）
    80000c66:	fd042783          	lw	a5,-48(s0)
    80000c6a:	2781                	sext.w	a5,a5
    80000c6c:	cb99                	beqz	a5,80000c82 <printf+0x9c>
    80000c6e:	fec42783          	lw	a5,-20(s0)
    80000c72:	0785                	add	a5,a5,1
    80000c74:	fb843703          	ld	a4,-72(s0)
    80000c78:	97ba                	add	a5,a5,a4
    80000c7a:	0007c783          	lbu	a5,0(a5)
    80000c7e:	fef42423          	sw	a5,-24(s0)
    if(c1) c2 = fmt[i+2] & 0xff;  // 可能的第三个字符（如%lld中的第二个d）
    80000c82:	fe842783          	lw	a5,-24(s0)
    80000c86:	2781                	sext.w	a5,a5
    80000c88:	cb99                	beqz	a5,80000c9e <printf+0xb8>
    80000c8a:	fec42783          	lw	a5,-20(s0)
    80000c8e:	0789                	add	a5,a5,2
    80000c90:	fb843703          	ld	a4,-72(s0)
    80000c94:	97ba                	add	a5,a5,a4
    80000c96:	0007c783          	lbu	a5,0(a5)
    80000c9a:	fef42223          	sw	a5,-28(s0)

    // 格式符处理 - 支持xv6的所有主要格式。普通字符直接输出，遇到%进入格式处理状态
    if(c0 == 'd') { 
    80000c9e:	fd042783          	lw	a5,-48(s0)
    80000ca2:	0007871b          	sext.w	a4,a5
    80000ca6:	06400793          	li	a5,100
    80000caa:	02f71163          	bne	a4,a5,80000ccc <printf+0xe6>
       // %d - 32位有符号整数   
      printint(va_arg(ap, int), 10, 1);
    80000cae:	fc843783          	ld	a5,-56(s0)
    80000cb2:	00878713          	add	a4,a5,8
    80000cb6:	fce43423          	sd	a4,-56(s0)
    80000cba:	439c                	lw	a5,0(a5)
    80000cbc:	4605                	li	a2,1
    80000cbe:	45a9                	li	a1,10
    80000cc0:	853e                	mv	a0,a5
    80000cc2:	00000097          	auipc	ra,0x0
    80000cc6:	dbe080e7          	jalr	-578(ra) # 80000a80 <printint>
    80000cca:	a471                	j	80000f56 <printf+0x370>
    } else if(c0 == 'l' && c1 == 'd'){
    80000ccc:	fd042783          	lw	a5,-48(s0)
    80000cd0:	0007871b          	sext.w	a4,a5
    80000cd4:	06c00793          	li	a5,108
    80000cd8:	02f71e63          	bne	a4,a5,80000d14 <printf+0x12e>
    80000cdc:	fe842783          	lw	a5,-24(s0)
    80000ce0:	0007871b          	sext.w	a4,a5
    80000ce4:	06400793          	li	a5,100
    80000ce8:	02f71663          	bne	a4,a5,80000d14 <printf+0x12e>
      // %ld - 64位有符号整数
      printint(va_arg(ap, uint64), 10, 1);
    80000cec:	fc843783          	ld	a5,-56(s0)
    80000cf0:	00878713          	add	a4,a5,8
    80000cf4:	fce43423          	sd	a4,-56(s0)
    80000cf8:	639c                	ld	a5,0(a5)
    80000cfa:	4605                	li	a2,1
    80000cfc:	45a9                	li	a1,10
    80000cfe:	853e                	mv	a0,a5
    80000d00:	00000097          	auipc	ra,0x0
    80000d04:	d80080e7          	jalr	-640(ra) # 80000a80 <printint>
      i += 1;// 跳过额外的字符
    80000d08:	fec42783          	lw	a5,-20(s0)
    80000d0c:	2785                	addw	a5,a5,1
    80000d0e:	fef42623          	sw	a5,-20(s0)
    80000d12:	a491                	j	80000f56 <printf+0x370>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
    80000d14:	fd042783          	lw	a5,-48(s0)
    80000d18:	0007871b          	sext.w	a4,a5
    80000d1c:	06c00793          	li	a5,108
    80000d20:	04f71663          	bne	a4,a5,80000d6c <printf+0x186>
    80000d24:	fe842783          	lw	a5,-24(s0)
    80000d28:	0007871b          	sext.w	a4,a5
    80000d2c:	06c00793          	li	a5,108
    80000d30:	02f71e63          	bne	a4,a5,80000d6c <printf+0x186>
    80000d34:	fe442783          	lw	a5,-28(s0)
    80000d38:	0007871b          	sext.w	a4,a5
    80000d3c:	06400793          	li	a5,100
    80000d40:	02f71663          	bne	a4,a5,80000d6c <printf+0x186>
      // %lld - 64位有符号整数（与%ld相同，但为兼容性）
      printint(va_arg(ap, uint64), 10, 1);
    80000d44:	fc843783          	ld	a5,-56(s0)
    80000d48:	00878713          	add	a4,a5,8
    80000d4c:	fce43423          	sd	a4,-56(s0)
    80000d50:	639c                	ld	a5,0(a5)
    80000d52:	4605                	li	a2,1
    80000d54:	45a9                	li	a1,10
    80000d56:	853e                	mv	a0,a5
    80000d58:	00000097          	auipc	ra,0x0
    80000d5c:	d28080e7          	jalr	-728(ra) # 80000a80 <printint>
      i += 2;// 跳过额外的字符
    80000d60:	fec42783          	lw	a5,-20(s0)
    80000d64:	2789                	addw	a5,a5,2
    80000d66:	fef42623          	sw	a5,-20(s0)
    80000d6a:	a2f5                	j	80000f56 <printf+0x370>
    } else if(c0 == 'u'){
    80000d6c:	fd042783          	lw	a5,-48(s0)
    80000d70:	0007871b          	sext.w	a4,a5
    80000d74:	07500793          	li	a5,117
    80000d78:	02f71363          	bne	a4,a5,80000d9e <printf+0x1b8>
      // %u - 32位无符号整数
      printint(va_arg(ap, uint32), 10, 0);
    80000d7c:	fc843783          	ld	a5,-56(s0)
    80000d80:	00878713          	add	a4,a5,8
    80000d84:	fce43423          	sd	a4,-56(s0)
    80000d88:	439c                	lw	a5,0(a5)
    80000d8a:	1782                	sll	a5,a5,0x20
    80000d8c:	9381                	srl	a5,a5,0x20
    80000d8e:	4601                	li	a2,0
    80000d90:	45a9                	li	a1,10
    80000d92:	853e                	mv	a0,a5
    80000d94:	00000097          	auipc	ra,0x0
    80000d98:	cec080e7          	jalr	-788(ra) # 80000a80 <printint>
    80000d9c:	aa6d                	j	80000f56 <printf+0x370>
    } else if(c0 == 'l' && c1 == 'u'){
    80000d9e:	fd042783          	lw	a5,-48(s0)
    80000da2:	0007871b          	sext.w	a4,a5
    80000da6:	06c00793          	li	a5,108
    80000daa:	02f71e63          	bne	a4,a5,80000de6 <printf+0x200>
    80000dae:	fe842783          	lw	a5,-24(s0)
    80000db2:	0007871b          	sext.w	a4,a5
    80000db6:	07500793          	li	a5,117
    80000dba:	02f71663          	bne	a4,a5,80000de6 <printf+0x200>
      printint(va_arg(ap, uint64), 10, 0);
    80000dbe:	fc843783          	ld	a5,-56(s0)
    80000dc2:	00878713          	add	a4,a5,8
    80000dc6:	fce43423          	sd	a4,-56(s0)
    80000dca:	639c                	ld	a5,0(a5)
    80000dcc:	4601                	li	a2,0
    80000dce:	45a9                	li	a1,10
    80000dd0:	853e                	mv	a0,a5
    80000dd2:	00000097          	auipc	ra,0x0
    80000dd6:	cae080e7          	jalr	-850(ra) # 80000a80 <printint>
      i += 1;
    80000dda:	fec42783          	lw	a5,-20(s0)
    80000dde:	2785                	addw	a5,a5,1
    80000de0:	fef42623          	sw	a5,-20(s0)
    80000de4:	aa8d                	j	80000f56 <printf+0x370>
    } else if(c0 == 'x'){// %x - 32位十六进制
    80000de6:	fd042783          	lw	a5,-48(s0)
    80000dea:	0007871b          	sext.w	a4,a5
    80000dee:	07800793          	li	a5,120
    80000df2:	02f71363          	bne	a4,a5,80000e18 <printf+0x232>
      printint(va_arg(ap, uint32), 16, 0);
    80000df6:	fc843783          	ld	a5,-56(s0)
    80000dfa:	00878713          	add	a4,a5,8
    80000dfe:	fce43423          	sd	a4,-56(s0)
    80000e02:	439c                	lw	a5,0(a5)
    80000e04:	1782                	sll	a5,a5,0x20
    80000e06:	9381                	srl	a5,a5,0x20
    80000e08:	4601                	li	a2,0
    80000e0a:	45c1                	li	a1,16
    80000e0c:	853e                	mv	a0,a5
    80000e0e:	00000097          	auipc	ra,0x0
    80000e12:	c72080e7          	jalr	-910(ra) # 80000a80 <printint>
    80000e16:	a281                	j	80000f56 <printf+0x370>
    } else if(c0 == 'l' && c1 == 'x'){
    80000e18:	fd042783          	lw	a5,-48(s0)
    80000e1c:	0007871b          	sext.w	a4,a5
    80000e20:	06c00793          	li	a5,108
    80000e24:	02f71e63          	bne	a4,a5,80000e60 <printf+0x27a>
    80000e28:	fe842783          	lw	a5,-24(s0)
    80000e2c:	0007871b          	sext.w	a4,a5
    80000e30:	07800793          	li	a5,120
    80000e34:	02f71663          	bne	a4,a5,80000e60 <printf+0x27a>
      printint(va_arg(ap, uint64), 16, 0);
    80000e38:	fc843783          	ld	a5,-56(s0)
    80000e3c:	00878713          	add	a4,a5,8
    80000e40:	fce43423          	sd	a4,-56(s0)
    80000e44:	639c                	ld	a5,0(a5)
    80000e46:	4601                	li	a2,0
    80000e48:	45c1                	li	a1,16
    80000e4a:	853e                	mv	a0,a5
    80000e4c:	00000097          	auipc	ra,0x0
    80000e50:	c34080e7          	jalr	-972(ra) # 80000a80 <printint>
      i += 1;
    80000e54:	fec42783          	lw	a5,-20(s0)
    80000e58:	2785                	addw	a5,a5,1
    80000e5a:	fef42623          	sw	a5,-20(s0)
    80000e5e:	a8e5                	j	80000f56 <printf+0x370>
    } else if(c0 == 'p'){// %p - 指针地址
    80000e60:	fd042783          	lw	a5,-48(s0)
    80000e64:	0007871b          	sext.w	a4,a5
    80000e68:	07000793          	li	a5,112
    80000e6c:	00f71f63          	bne	a4,a5,80000e8a <printf+0x2a4>
      printptr(va_arg(ap, uint64));
    80000e70:	fc843783          	ld	a5,-56(s0)
    80000e74:	00878713          	add	a4,a5,8
    80000e78:	fce43423          	sd	a4,-56(s0)
    80000e7c:	639c                	ld	a5,0(a5)
    80000e7e:	853e                	mv	a0,a5
    80000e80:	00000097          	auipc	ra,0x0
    80000e84:	cf0080e7          	jalr	-784(ra) # 80000b70 <printptr>
    80000e88:	a0f9                	j	80000f56 <printf+0x370>
    } else if(c0 == 'c'){// %c - 单个字符
    80000e8a:	fd042783          	lw	a5,-48(s0)
    80000e8e:	0007871b          	sext.w	a4,a5
    80000e92:	06300793          	li	a5,99
    80000e96:	02f71063          	bne	a4,a5,80000eb6 <printf+0x2d0>
      consputc(va_arg(ap, uint));
    80000e9a:	fc843783          	ld	a5,-56(s0)
    80000e9e:	00878713          	add	a4,a5,8
    80000ea2:	fce43423          	sd	a4,-56(s0)
    80000ea6:	439c                	lw	a5,0(a5)
    80000ea8:	2781                	sext.w	a5,a5
    80000eaa:	853e                	mv	a0,a5
    80000eac:	00000097          	auipc	ra,0x0
    80000eb0:	b5a080e7          	jalr	-1190(ra) # 80000a06 <consputc>
    80000eb4:	a04d                	j	80000f56 <printf+0x370>
    } else if(c0 == 's'){// %s - 字符串
    80000eb6:	fd042783          	lw	a5,-48(s0)
    80000eba:	0007871b          	sext.w	a4,a5
    80000ebe:	07300793          	li	a5,115
    80000ec2:	04f71a63          	bne	a4,a5,80000f16 <printf+0x330>
      // 第1步：从参数列表中取出字符串指针
      if((s = va_arg(ap, char*)) == 0)// 检查是否为NULL
    80000ec6:	fc843783          	ld	a5,-56(s0)
    80000eca:	00878713          	add	a4,a5,8
    80000ece:	fce43423          	sd	a4,-56(s0)
    80000ed2:	639c                	ld	a5,0(a5)
    80000ed4:	fcf43c23          	sd	a5,-40(s0)
    80000ed8:	fd843783          	ld	a5,-40(s0)
    80000edc:	e79d                	bnez	a5,80000f0a <printf+0x324>
        s = "(null)";// 如果是NULL，替换成安全的字符串
    80000ede:	00006797          	auipc	a5,0x6
    80000ee2:	ada78793          	add	a5,a5,-1318 # 800069b8 <userret+0x954>
    80000ee6:	fcf43c23          	sd	a5,-40(s0)
      // 第2步：逐字符输出
      for(; *s; s++)
    80000eea:	a005                	j	80000f0a <printf+0x324>
        consputc(*s);
    80000eec:	fd843783          	ld	a5,-40(s0)
    80000ef0:	0007c783          	lbu	a5,0(a5)
    80000ef4:	2781                	sext.w	a5,a5
    80000ef6:	853e                	mv	a0,a5
    80000ef8:	00000097          	auipc	ra,0x0
    80000efc:	b0e080e7          	jalr	-1266(ra) # 80000a06 <consputc>
      for(; *s; s++)
    80000f00:	fd843783          	ld	a5,-40(s0)
    80000f04:	0785                	add	a5,a5,1
    80000f06:	fcf43c23          	sd	a5,-40(s0)
    80000f0a:	fd843783          	ld	a5,-40(s0)
    80000f0e:	0007c783          	lbu	a5,0(a5)
    80000f12:	ffe9                	bnez	a5,80000eec <printf+0x306>
    80000f14:	a089                	j	80000f56 <printf+0x370>
    } else if(c0 == '%'){// %% - 输出字面的%
    80000f16:	fd042783          	lw	a5,-48(s0)
    80000f1a:	0007871b          	sext.w	a4,a5
    80000f1e:	02500793          	li	a5,37
    80000f22:	00f71963          	bne	a4,a5,80000f34 <printf+0x34e>
      consputc('%');
    80000f26:	02500513          	li	a0,37
    80000f2a:	00000097          	auipc	ra,0x0
    80000f2e:	adc080e7          	jalr	-1316(ra) # 80000a06 <consputc>
    80000f32:	a015                	j	80000f56 <printf+0x370>
    } else if(c0 == 0){
    80000f34:	fd042783          	lw	a5,-48(s0)
    80000f38:	2781                	sext.w	a5,a5
    80000f3a:	c3b1                	beqz	a5,80000f7e <printf+0x398>
      break;
    } else {// 未知格式符 - 原样输出便于调试
      consputc('%');
    80000f3c:	02500513          	li	a0,37
    80000f40:	00000097          	auipc	ra,0x0
    80000f44:	ac6080e7          	jalr	-1338(ra) # 80000a06 <consputc>
      consputc(c0);
    80000f48:	fd042783          	lw	a5,-48(s0)
    80000f4c:	853e                	mv	a0,a5
    80000f4e:	00000097          	auipc	ra,0x0
    80000f52:	ab8080e7          	jalr	-1352(ra) # 80000a06 <consputc>
  for(i = 0; (cx = fmt[i] & 0xff) != 0; i++){
    80000f56:	fec42783          	lw	a5,-20(s0)
    80000f5a:	2785                	addw	a5,a5,1
    80000f5c:	fef42623          	sw	a5,-20(s0)
    80000f60:	fec42783          	lw	a5,-20(s0)
    80000f64:	fb843703          	ld	a4,-72(s0)
    80000f68:	97ba                	add	a5,a5,a4
    80000f6a:	0007c783          	lbu	a5,0(a5)
    80000f6e:	fcf42a23          	sw	a5,-44(s0)
    80000f72:	fd442783          	lw	a5,-44(s0)
    80000f76:	2781                	sext.w	a5,a5
    80000f78:	ca0793e3          	bnez	a5,80000c1e <printf+0x38>
    80000f7c:	a011                	j	80000f80 <printf+0x39a>
      break;
    80000f7e:	0001                	nop
    }
  }
  va_end(ap);// 清理参数列表

  return 0;
    80000f80:	4781                	li	a5,0
}
    80000f82:	853e                	mv	a0,a5
    80000f84:	60a6                	ld	ra,72(sp)
    80000f86:	6406                	ld	s0,64(sp)
    80000f88:	6149                	add	sp,sp,144
    80000f8a:	8082                	ret

0000000080000f8c <panic>:

void panic(char *s)
{
    80000f8c:	1101                	add	sp,sp,-32
    80000f8e:	ec06                	sd	ra,24(sp)
    80000f90:	e822                	sd	s0,16(sp)
    80000f92:	1000                	add	s0,sp,32
    80000f94:	fea43423          	sd	a0,-24(s0)
  // 第1步：设置全局标志，告诉其他部分"系统要崩溃了"
  panicking = 1;
    80000f98:	00009797          	auipc	a5,0x9
    80000f9c:	06878793          	add	a5,a5,104 # 8000a000 <panicking>
    80000fa0:	4705                	li	a4,1
    80000fa2:	c398                	sw	a4,0(a5)
  
  // 第2步：输出崩溃信息，让程序员知道出了什么问题
  printf("panic: ");        // 固定前缀，表示这是系统崩溃
    80000fa4:	00006517          	auipc	a0,0x6
    80000fa8:	a1c50513          	add	a0,a0,-1508 # 800069c0 <userret+0x95c>
    80000fac:	00000097          	auipc	ra,0x0
    80000fb0:	c3a080e7          	jalr	-966(ra) # 80000be6 <printf>
  printf("%s\n", s);        // 输出具体的错误信息
    80000fb4:	fe843583          	ld	a1,-24(s0)
    80000fb8:	00006517          	auipc	a0,0x6
    80000fbc:	a1050513          	add	a0,a0,-1520 # 800069c8 <userret+0x964>
    80000fc0:	00000097          	auipc	ra,0x0
    80000fc4:	c26080e7          	jalr	-986(ra) # 80000be6 <printf>
  
  // 第3步：标记崩溃处理完成
  // 这时其他部分看到这个标志就知道不要再输出了
  panicked = 1;
    80000fc8:	00009797          	auipc	a5,0x9
    80000fcc:	03c78793          	add	a5,a5,60 # 8000a004 <panicked>
    80000fd0:	4705                	li	a4,1
    80000fd2:	c398                	sw	a4,0(a5)
  
  // 第4步：进入无限循环，让系统停止运行
  for(;;)
    80000fd4:	0001                	nop
    80000fd6:	bffd                	j	80000fd4 <panic+0x48>

0000000080000fd8 <printfinit>:
    ;  // 空循环，CPU在这里永远转圈
}

void printfinit(void)
{
    80000fd8:	1141                	add	sp,sp,-16
    80000fda:	e422                	sd	s0,8(sp)
    80000fdc:	0800                	add	s0,sp,16
  /* 简化版本，不需要锁初始化 */
}
    80000fde:	0001                	nop
    80000fe0:	6422                	ld	s0,8(sp)
    80000fe2:	0141                	add	sp,sp,16
    80000fe4:	8082                	ret

0000000080000fe6 <clear_screen>:
#include "types.h"
#include "defs.h"

/* 清屏函数 */
void clear_screen(void)
{
    80000fe6:	1141                	add	sp,sp,-16
    80000fe8:	e406                	sd	ra,8(sp)
    80000fea:	e022                	sd	s0,0(sp)
    80000fec:	0800                	add	s0,sp,16
  /* 直接输出ANSI转义序列，避免复杂的printf格式化 */
   // 发送ANSI转义序列：ESC[2J ESC[H
  consputc('\033');  /* ESC */
    80000fee:	456d                	li	a0,27
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	a16080e7          	jalr	-1514(ra) # 80000a06 <consputc>
  consputc('[');// 开始ANSI序列
    80000ff8:	05b00513          	li	a0,91
    80000ffc:	00000097          	auipc	ra,0x0
    80001000:	a0a080e7          	jalr	-1526(ra) # 80000a06 <consputc>
  consputc('2');     // 清屏命令参数
    80001004:	03200513          	li	a0,50
    80001008:	00000097          	auipc	ra,0x0
    8000100c:	9fe080e7          	jalr	-1538(ra) # 80000a06 <consputc>
  consputc('J');     /* 清除整个屏幕 */
    80001010:	04a00513          	li	a0,74
    80001014:	00000097          	auipc	ra,0x0
    80001018:	9f2080e7          	jalr	-1550(ra) # 80000a06 <consputc>
  consputc('\033');  /* ESC */
    8000101c:	456d                	li	a0,27
    8000101e:	00000097          	auipc	ra,0x0
    80001022:	9e8080e7          	jalr	-1560(ra) # 80000a06 <consputc>
  consputc('[');
    80001026:	05b00513          	li	a0,91
    8000102a:	00000097          	auipc	ra,0x0
    8000102e:	9dc080e7          	jalr	-1572(ra) # 80000a06 <consputc>
  consputc('H');     /* 光标回到左上角 */
    80001032:	04800513          	li	a0,72
    80001036:	00000097          	auipc	ra,0x0
    8000103a:	9d0080e7          	jalr	-1584(ra) # 80000a06 <consputc>
}
    8000103e:	0001                	nop
    80001040:	60a2                	ld	ra,8(sp)
    80001042:	6402                	ld	s0,0(sp)
    80001044:	0141                	add	sp,sp,16
    80001046:	8082                	ret

0000000080001048 <print_number>:

/* 数字输出辅助函数 */
static void print_number(int num)
{
    80001048:	1101                	add	sp,sp,-32
    8000104a:	ec06                	sd	ra,24(sp)
    8000104c:	e822                	sd	s0,16(sp)
    8000104e:	1000                	add	s0,sp,32
    80001050:	87aa                	mv	a5,a0
    80001052:	fef42623          	sw	a5,-20(s0)
  if(num >= 10) {
    80001056:	fec42783          	lw	a5,-20(s0)
    8000105a:	0007871b          	sext.w	a4,a5
    8000105e:	47a5                	li	a5,9
    80001060:	00e7de63          	bge	a5,a4,8000107c <print_number+0x34>
    print_number(num / 10);// 递归处理高位
    80001064:	fec42783          	lw	a5,-20(s0)
    80001068:	873e                	mv	a4,a5
    8000106a:	47a9                	li	a5,10
    8000106c:	02f747bb          	divw	a5,a4,a5
    80001070:	2781                	sext.w	a5,a5
    80001072:	853e                	mv	a0,a5
    80001074:	00000097          	auipc	ra,0x0
    80001078:	fd4080e7          	jalr	-44(ra) # 80001048 <print_number>
  }
  consputc('0' + (num % 10));// 输出当前位
    8000107c:	fec42783          	lw	a5,-20(s0)
    80001080:	873e                	mv	a4,a5
    80001082:	47a9                	li	a5,10
    80001084:	02f767bb          	remw	a5,a4,a5
    80001088:	2781                	sext.w	a5,a5
    8000108a:	0307879b          	addw	a5,a5,48
    8000108e:	2781                	sext.w	a5,a5
    80001090:	853e                	mv	a0,a5
    80001092:	00000097          	auipc	ra,0x0
    80001096:	974080e7          	jalr	-1676(ra) # 80000a06 <consputc>
}
    8000109a:	0001                	nop
    8000109c:	60e2                	ld	ra,24(sp)
    8000109e:	6442                	ld	s0,16(sp)
    800010a0:	6105                	add	sp,sp,32
    800010a2:	8082                	ret

00000000800010a4 <set_cursor>:
// 5. 返回步骤1，输出 '3'
// 结果：输出 "123"

/* 光标定位函数 */
void set_cursor(int x, int y)
{
    800010a4:	1101                	add	sp,sp,-32
    800010a6:	ec06                	sd	ra,24(sp)
    800010a8:	e822                	sd	s0,16(sp)
    800010aa:	1000                	add	s0,sp,32
    800010ac:	87aa                	mv	a5,a0
    800010ae:	872e                	mv	a4,a1
    800010b0:	fef42623          	sw	a5,-20(s0)
    800010b4:	87ba                	mv	a5,a4
    800010b6:	fef42423          	sw	a5,-24(s0)
  // 发送ANSI序列：ESC[y;xH
  consputc('\033');  /* ESC */
    800010ba:	456d                	li	a0,27
    800010bc:	00000097          	auipc	ra,0x0
    800010c0:	94a080e7          	jalr	-1718(ra) # 80000a06 <consputc>
  consputc('[');
    800010c4:	05b00513          	li	a0,91
    800010c8:	00000097          	auipc	ra,0x0
    800010cc:	93e080e7          	jalr	-1730(ra) # 80000a06 <consputc>
  print_number(y);// 行号
    800010d0:	fe842783          	lw	a5,-24(s0)
    800010d4:	853e                	mv	a0,a5
    800010d6:	00000097          	auipc	ra,0x0
    800010da:	f72080e7          	jalr	-142(ra) # 80001048 <print_number>
  consputc(';');     // 分隔符
    800010de:	03b00513          	li	a0,59
    800010e2:	00000097          	auipc	ra,0x0
    800010e6:	924080e7          	jalr	-1756(ra) # 80000a06 <consputc>
  print_number(x);   // 列号  
    800010ea:	fec42783          	lw	a5,-20(s0)
    800010ee:	853e                	mv	a0,a5
    800010f0:	00000097          	auipc	ra,0x0
    800010f4:	f58080e7          	jalr	-168(ra) # 80001048 <print_number>
  consputc('H');     // 定位命令，移动光标
    800010f8:	04800513          	li	a0,72
    800010fc:	00000097          	auipc	ra,0x0
    80001100:	90a080e7          	jalr	-1782(ra) # 80000a06 <consputc>
}
    80001104:	0001                	nop
    80001106:	60e2                	ld	ra,24(sp)
    80001108:	6442                	ld	s0,16(sp)
    8000110a:	6105                	add	sp,sp,32
    8000110c:	8082                	ret

000000008000110e <memset>:
// 简单的memset实现 
// 用途：页面清零、安全擦除等
/*如果程序错误地访问已释放的页面，会读到全是1的数据
这种异常的数据模式很容易被发现，有助于调试
如果不填充，程序可能读到看似正常的旧数据，bug很难发现*/
void* memset(void *dst, int c, uint n) {
    8000110e:	7179                	add	sp,sp,-48
    80001110:	f422                	sd	s0,40(sp)
    80001112:	1800                	add	s0,sp,48
    80001114:	fca43c23          	sd	a0,-40(s0)
    80001118:	87ae                	mv	a5,a1
    8000111a:	8732                	mv	a4,a2
    8000111c:	fcf42a23          	sw	a5,-44(s0)
    80001120:	87ba                	mv	a5,a4
    80001122:	fcf42823          	sw	a5,-48(s0)
    char *cdst = (char*)dst;
    80001126:	fd843783          	ld	a5,-40(s0)
    8000112a:	fef43023          	sd	a5,-32(s0)
    int i;
    // 逐字节填充，实现简单可靠
    for(i = 0; i < n; i++) {
    8000112e:	fe042623          	sw	zero,-20(s0)
    80001132:	a00d                	j	80001154 <memset+0x46>
        cdst[i] = c;
    80001134:	fec42783          	lw	a5,-20(s0)
    80001138:	fe043703          	ld	a4,-32(s0)
    8000113c:	97ba                	add	a5,a5,a4
    8000113e:	fd442703          	lw	a4,-44(s0)
    80001142:	0ff77713          	zext.b	a4,a4
    80001146:	00e78023          	sb	a4,0(a5)
    for(i = 0; i < n; i++) {
    8000114a:	fec42783          	lw	a5,-20(s0)
    8000114e:	2785                	addw	a5,a5,1
    80001150:	fef42623          	sw	a5,-20(s0)
    80001154:	fec42703          	lw	a4,-20(s0)
    80001158:	fd042783          	lw	a5,-48(s0)
    8000115c:	2781                	sext.w	a5,a5
    8000115e:	fcf76be3          	bltu	a4,a5,80001134 <memset+0x26>
    }
    return dst;
    80001162:	fd843783          	ld	a5,-40(s0)
}
    80001166:	853e                	mv	a0,a5
    80001168:	7422                	ld	s0,40(sp)
    8000116a:	6145                	add	sp,sp,48
    8000116c:	8082                	ret

000000008000116e <memcpy>:
void* memcpy(void *dst, const void *src, uint n) {
    8000116e:	715d                	add	sp,sp,-80
    80001170:	e4a2                	sd	s0,72(sp)
    80001172:	0880                	add	s0,sp,80
    80001174:	fca43423          	sd	a0,-56(s0)
    80001178:	fcb43023          	sd	a1,-64(s0)
    8000117c:	87b2                	mv	a5,a2
    8000117e:	faf42e23          	sw	a5,-68(s0)
    char *cdst = (char*)dst;
    80001182:	fc843783          	ld	a5,-56(s0)
    80001186:	fef43023          	sd	a5,-32(s0)
    const char *csrc = (const char*)src;
    8000118a:	fc043783          	ld	a5,-64(s0)
    8000118e:	fcf43c23          	sd	a5,-40(s0)
    
    // 逐字节复制
    for(uint i = 0; i < n; i++) {
    80001192:	fe042623          	sw	zero,-20(s0)
    80001196:	a025                	j	800011be <memcpy+0x50>
        cdst[i] = csrc[i];
    80001198:	fec46783          	lwu	a5,-20(s0)
    8000119c:	fd843703          	ld	a4,-40(s0)
    800011a0:	973e                	add	a4,a4,a5
    800011a2:	fec46783          	lwu	a5,-20(s0)
    800011a6:	fe043683          	ld	a3,-32(s0)
    800011aa:	97b6                	add	a5,a5,a3
    800011ac:	00074703          	lbu	a4,0(a4)
    800011b0:	00e78023          	sb	a4,0(a5)
    for(uint i = 0; i < n; i++) {
    800011b4:	fec42783          	lw	a5,-20(s0)
    800011b8:	2785                	addw	a5,a5,1
    800011ba:	fef42623          	sw	a5,-20(s0)
    800011be:	fec42783          	lw	a5,-20(s0)
    800011c2:	873e                	mv	a4,a5
    800011c4:	fbc42783          	lw	a5,-68(s0)
    800011c8:	2701                	sext.w	a4,a4
    800011ca:	2781                	sext.w	a5,a5
    800011cc:	fcf766e3          	bltu	a4,a5,80001198 <memcpy+0x2a>
    }
    
    return dst;
    800011d0:	fc843783          	ld	a5,-56(s0)
}
    800011d4:	853e                	mv	a0,a5
    800011d6:	6426                	ld	s0,72(sp)
    800011d8:	6161                	add	sp,sp,80
    800011da:	8082                	ret

00000000800011dc <pmm_init>:
// ==================== 初始化物理内存分配器 ====================
void pmm_init(void) {
    800011dc:	7179                	add	sp,sp,-48
    800011de:	f406                	sd	ra,40(sp)
    800011e0:	f022                	sd	s0,32(sp)
    800011e2:	1800                	add	s0,sp,48
    // 第一步：确定可分配内存范围
    // 内存布局: [内核代码+数据] [可分配区域] [内存结束]
    //          ^end           ^mem_start    ^PHYSTOP
    char *mem_start = (char*)PGROUNDUP((uint64)end);  // 内核结束后的第一个页面边界
    800011e4:	00011717          	auipc	a4,0x11
    800011e8:	e1c70713          	add	a4,a4,-484 # 80012000 <end>
    800011ec:	6785                	lui	a5,0x1
    800011ee:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    800011f0:	973e                	add	a4,a4,a5
    800011f2:	77fd                	lui	a5,0xfffff
    800011f4:	8ff9                	and	a5,a5,a4
    800011f6:	fef43023          	sd	a5,-32(s0)
    char *mem_end = (char*)PHYSTOP;                   // 物理内存结束位置
    800011fa:	47c5                	li	a5,17
    800011fc:	07ee                	sll	a5,a5,0x1b
    800011fe:	fcf43c23          	sd	a5,-40(s0)
    
    // 第二步：初始化管理器状态
    kmem.freelist = 0;      // 空链表
    80001202:	0000d797          	auipc	a5,0xd
    80001206:	dfe78793          	add	a5,a5,-514 # 8000e000 <kmem>
    8000120a:	0007b023          	sd	zero,0(a5)
    kmem.total_pages = 0;   // 计数器清零
    8000120e:	0000d797          	auipc	a5,0xd
    80001212:	df278793          	add	a5,a5,-526 # 8000e000 <kmem>
    80001216:	0007b423          	sd	zero,8(a5)
    kmem.free_pages = 0;
    8000121a:	0000d797          	auipc	a5,0xd
    8000121e:	de678793          	add	a5,a5,-538 # 8000e000 <kmem>
    80001222:	0007b823          	sd	zero,16(a5)
    
    printf("PMM: Initializing memory from %p to %p\n", mem_start, mem_end);
    80001226:	fd843603          	ld	a2,-40(s0)
    8000122a:	fe043583          	ld	a1,-32(s0)
    8000122e:	00005517          	auipc	a0,0x5
    80001232:	7a250513          	add	a0,a0,1954 # 800069d0 <userret+0x96c>
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	9b0080e7          	jalr	-1616(ra) # 80000be6 <printf>
    
    // 第三步：构建空闲页面链表
    // 遍历所有可用页面，逐个加入空闲链表
    char *p;
    for(p = mem_start; p + PGSIZE <= mem_end; p += PGSIZE) {
    8000123e:	fe043783          	ld	a5,-32(s0)
    80001242:	fef43423          	sd	a5,-24(s0)
    80001246:	a089                	j	80001288 <pmm_init+0xac>
        // 为什么要清零？确保页面内容干净，避免信息泄露
        memset(p, 0, PGSIZE);
    80001248:	6605                	lui	a2,0x1
    8000124a:	4581                	li	a1,0
    8000124c:	fe843503          	ld	a0,-24(s0)
    80001250:	00000097          	auipc	ra,0x0
    80001254:	ebe080e7          	jalr	-322(ra) # 8000110e <memset>
        // 调用free_page将页面加入链表，复用释放逻辑
        free_page(p);
    80001258:	fe843503          	ld	a0,-24(s0)
    8000125c:	00000097          	auipc	ra,0x0
    80001260:	0ee080e7          	jalr	238(ra) # 8000134a <free_page>
        kmem.total_pages++;   // 统计总页面数
    80001264:	0000d797          	auipc	a5,0xd
    80001268:	d9c78793          	add	a5,a5,-612 # 8000e000 <kmem>
    8000126c:	679c                	ld	a5,8(a5)
    8000126e:	00178713          	add	a4,a5,1
    80001272:	0000d797          	auipc	a5,0xd
    80001276:	d8e78793          	add	a5,a5,-626 # 8000e000 <kmem>
    8000127a:	e798                	sd	a4,8(a5)
    for(p = mem_start; p + PGSIZE <= mem_end; p += PGSIZE) {
    8000127c:	fe843703          	ld	a4,-24(s0)
    80001280:	6785                	lui	a5,0x1
    80001282:	97ba                	add	a5,a5,a4
    80001284:	fef43423          	sd	a5,-24(s0)
    80001288:	fe843703          	ld	a4,-24(s0)
    8000128c:	6785                	lui	a5,0x1
    8000128e:	97ba                	add	a5,a5,a4
    80001290:	fd843703          	ld	a4,-40(s0)
    80001294:	faf77ae3          	bgeu	a4,a5,80001248 <pmm_init+0x6c>
    }
    
    printf("PMM: Initialized %d pages (%d KB)\n", 
           (int)kmem.total_pages, (int)(kmem.total_pages * PGSIZE) / 1024);
    80001298:	0000d797          	auipc	a5,0xd
    8000129c:	d6878793          	add	a5,a5,-664 # 8000e000 <kmem>
    800012a0:	679c                	ld	a5,8(a5)
    printf("PMM: Initialized %d pages (%d KB)\n", 
    800012a2:	0007869b          	sext.w	a3,a5
           (int)kmem.total_pages, (int)(kmem.total_pages * PGSIZE) / 1024);
    800012a6:	0000d797          	auipc	a5,0xd
    800012aa:	d5a78793          	add	a5,a5,-678 # 8000e000 <kmem>
    800012ae:	679c                	ld	a5,8(a5)
    800012b0:	2781                	sext.w	a5,a5
    800012b2:	00c7979b          	sllw	a5,a5,0xc
    800012b6:	2781                	sext.w	a5,a5
    800012b8:	2781                	sext.w	a5,a5
    printf("PMM: Initialized %d pages (%d KB)\n", 
    800012ba:	41f7d71b          	sraw	a4,a5,0x1f
    800012be:	0167571b          	srlw	a4,a4,0x16
    800012c2:	9fb9                	addw	a5,a5,a4
    800012c4:	40a7d79b          	sraw	a5,a5,0xa
    800012c8:	2781                	sext.w	a5,a5
    800012ca:	863e                	mv	a2,a5
    800012cc:	85b6                	mv	a1,a3
    800012ce:	00005517          	auipc	a0,0x5
    800012d2:	72a50513          	add	a0,a0,1834 # 800069f8 <userret+0x994>
    800012d6:	00000097          	auipc	ra,0x0
    800012da:	910080e7          	jalr	-1776(ra) # 80000be6 <printf>
}
    800012de:	0001                	nop
    800012e0:	70a2                	ld	ra,40(sp)
    800012e2:	7402                	ld	s0,32(sp)
    800012e4:	6145                	add	sp,sp,48
    800012e6:	8082                	ret

00000000800012e8 <alloc_page>:

// ==================== 分配一个物理页面 ====================
// 算法特点：LIFO(后进先出)，最近释放的页面优先被分配
// 时间复杂度：O(1) - 仅涉及链表头操作
void* alloc_page(void) {
    800012e8:	1101                	add	sp,sp,-32
    800012ea:	ec06                	sd	ra,24(sp)
    800012ec:	e822                	sd	s0,16(sp)
    800012ee:	1000                	add	s0,sp,32
    struct run *r;
    
    // 从链表头取出一个空闲页面
    r = kmem.freelist;
    800012f0:	0000d797          	auipc	a5,0xd
    800012f4:	d1078793          	add	a5,a5,-752 # 8000e000 <kmem>
    800012f8:	639c                	ld	a5,0(a5)
    800012fa:	fef43423          	sd	a5,-24(s0)
    if(r) {
    800012fe:	fe843783          	ld	a5,-24(s0)
    80001302:	cf8d                	beqz	a5,8000133c <alloc_page+0x54>
        // 更新链表头指向下一个空闲页面
        kmem.freelist = r->next;
    80001304:	fe843783          	ld	a5,-24(s0)
    80001308:	6398                	ld	a4,0(a5)
    8000130a:	0000d797          	auipc	a5,0xd
    8000130e:	cf678793          	add	a5,a5,-778 # 8000e000 <kmem>
    80001312:	e398                	sd	a4,0(a5)
        kmem.free_pages--;      // 更新空闲页面计数
    80001314:	0000d797          	auipc	a5,0xd
    80001318:	cec78793          	add	a5,a5,-788 # 8000e000 <kmem>
    8000131c:	6b9c                	ld	a5,16(a5)
    8000131e:	fff78713          	add	a4,a5,-1
    80001322:	0000d797          	auipc	a5,0xd
    80001326:	cde78793          	add	a5,a5,-802 # 8000e000 <kmem>
    8000132a:	eb98                	sd	a4,16(a5)
        
        // 安全措施：清零分配的页面，防止信息泄露
        // 确保新分配的页面内容是干净的
        memset((char*)r, 0, PGSIZE);
    8000132c:	6605                	lui	a2,0x1
    8000132e:	4581                	li	a1,0
    80001330:	fe843503          	ld	a0,-24(s0)
    80001334:	00000097          	auipc	ra,0x0
    80001338:	dda080e7          	jalr	-550(ra) # 8000110e <memset>
    }
    // 如果r为NULL，表示内存耗尽，返回NULL
    
    return (void*)r;
    8000133c:	fe843783          	ld	a5,-24(s0)
}
    80001340:	853e                	mv	a0,a5
    80001342:	60e2                	ld	ra,24(sp)
    80001344:	6442                	ld	s0,16(sp)
    80001346:	6105                	add	sp,sp,32
    80001348:	8082                	ret

000000008000134a <free_page>:

// ==================== 释放一个物理页面 ====================  
// 算法特点：将页面插入链表头，实现LIFO释放
// 时间复杂度：O(1) - 仅涉及链表头操作
void free_page(void* pa) {
    8000134a:	7179                	add	sp,sp,-48
    8000134c:	f406                	sd	ra,40(sp)
    8000134e:	f022                	sd	s0,32(sp)
    80001350:	1800                	add	s0,sp,48
    80001352:	fca43c23          	sd	a0,-40(s0)
    struct run *r;
    
    // 第一步：地址有效性检查
    // 检查页面对齐：物理地址必须是4KB的整数倍
    if(((uint64)pa % PGSIZE) != 0)
    80001356:	fd843703          	ld	a4,-40(s0)
    8000135a:	6785                	lui	a5,0x1
    8000135c:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000135e:	8ff9                	and	a5,a5,a4
    80001360:	cb89                	beqz	a5,80001372 <free_page+0x28>
        panic("free_page: not page aligned");
    80001362:	00005517          	auipc	a0,0x5
    80001366:	6be50513          	add	a0,a0,1726 # 80006a20 <userret+0x9bc>
    8000136a:	00000097          	auipc	ra,0x0
    8000136e:	c22080e7          	jalr	-990(ra) # 80000f8c <panic>
    
    // 检查地址范围：必须在可管理的内存范围内
    // 防止释放内核代码/数据区域或超出物理内存的地址
    if((char*)pa < end || (uint64)pa >= PHYSTOP)
    80001372:	fd843703          	ld	a4,-40(s0)
    80001376:	00011797          	auipc	a5,0x11
    8000137a:	c8a78793          	add	a5,a5,-886 # 80012000 <end>
    8000137e:	00f76863          	bltu	a4,a5,8000138e <free_page+0x44>
    80001382:	fd843703          	ld	a4,-40(s0)
    80001386:	47c5                	li	a5,17
    80001388:	07ee                	sll	a5,a5,0x1b
    8000138a:	00f76a63          	bltu	a4,a5,8000139e <free_page+0x54>
        panic("free_page: invalid address");
    8000138e:	00005517          	auipc	a0,0x5
    80001392:	6b250513          	add	a0,a0,1714 # 80006a40 <userret+0x9dc>
    80001396:	00000097          	auipc	ra,0x0
    8000139a:	bf6080e7          	jalr	-1034(ra) # 80000f8c <panic>

     // 检查是否已经释放过.在释放的页面中放置一个特殊的标记，下次释放时检查这个标记。
    uint32 *magic_ptr = (uint32*)pa;
    8000139e:	fd843783          	ld	a5,-40(s0)
    800013a2:	fef43423          	sd	a5,-24(s0)
    if(*magic_ptr == FREE_MAGIC) {
    800013a6:	fe843783          	ld	a5,-24(s0)
    800013aa:	439c                	lw	a5,0(a5)
    800013ac:	873e                	mv	a4,a5
    800013ae:	deadc7b7          	lui	a5,0xdeadc
    800013b2:	eef78793          	add	a5,a5,-273 # ffffffffdeadbeef <end+0xffffffff5eac9eef>
    800013b6:	00f71a63          	bne	a4,a5,800013ca <free_page+0x80>
        panic("free_page: double free detected");
    800013ba:	00005517          	auipc	a0,0x5
    800013be:	6a650513          	add	a0,a0,1702 # 80006a60 <userret+0x9fc>
    800013c2:	00000097          	auipc	ra,0x0
    800013c6:	bca080e7          	jalr	-1078(ra) # 80000f8c <panic>
    }
    
    // 填充魔数而不是全部填1
    *magic_ptr = FREE_MAGIC;
    800013ca:	fe843783          	ld	a5,-24(s0)
    800013ce:	deadc737          	lui	a4,0xdeadc
    800013d2:	eef70713          	add	a4,a4,-273 # ffffffffdeadbeef <end+0xffffffff5eac9eef>
    800013d6:	c398                	sw	a4,0(a5)
    // 第二步：安全擦除页面内容
    // 填充特殊值(1)有助于检测use-after-free错误
    // 如果程序试图使用已释放的页面，会读到异常的数据模式
    // 其余部分仍然填1
    memset((char*)pa + 4, 1, PGSIZE - 4);
    800013d8:	fd843783          	ld	a5,-40(s0)
    800013dc:	00478713          	add	a4,a5,4
    800013e0:	6785                	lui	a5,0x1
    800013e2:	ffc78613          	add	a2,a5,-4 # ffc <_entry-0x7ffff004>
    800013e6:	4585                	li	a1,1
    800013e8:	853a                	mv	a0,a4
    800013ea:	00000097          	auipc	ra,0x0
    800013ee:	d24080e7          	jalr	-732(ra) # 8000110e <memset>
    
    // 第三步：将页面插入空闲链表头部
    r = (struct run*)pa;        // 将页面地址转换为链表节点
    800013f2:	fd843783          	ld	a5,-40(s0)
    800013f6:	fef43023          	sd	a5,-32(s0)
    r->next = kmem.freelist;    // 新节点指向当前链表头
    800013fa:	0000d797          	auipc	a5,0xd
    800013fe:	c0678793          	add	a5,a5,-1018 # 8000e000 <kmem>
    80001402:	6398                	ld	a4,0(a5)
    80001404:	fe043783          	ld	a5,-32(s0)
    80001408:	e398                	sd	a4,0(a5)
    kmem.freelist = r;          // 更新链表头为新节点
    8000140a:	0000d797          	auipc	a5,0xd
    8000140e:	bf678793          	add	a5,a5,-1034 # 8000e000 <kmem>
    80001412:	fe043703          	ld	a4,-32(s0)
    80001416:	e398                	sd	a4,0(a5)
    kmem.free_pages++;          // 更新空闲页面计数
    80001418:	0000d797          	auipc	a5,0xd
    8000141c:	be878793          	add	a5,a5,-1048 # 8000e000 <kmem>
    80001420:	6b9c                	ld	a5,16(a5)
    80001422:	00178713          	add	a4,a5,1
    80001426:	0000d797          	auipc	a5,0xd
    8000142a:	bda78793          	add	a5,a5,-1062 # 8000e000 <kmem>
    8000142e:	eb98                	sd	a4,16(a5)
}
    80001430:	0001                	nop
    80001432:	70a2                	ld	ra,40(sp)
    80001434:	7402                	ld	s0,32(sp)
    80001436:	6145                	add	sp,sp,48
    80001438:	8082                	ret

000000008000143a <pmm_info>:

// ==================== 内存使用信息统计 ====================
// 用途：调试、监控、性能分析
void pmm_info(void) {
    8000143a:	1141                	add	sp,sp,-16
    8000143c:	e406                	sd	ra,8(sp)
    8000143e:	e022                	sd	s0,0(sp)
    80001440:	0800                	add	s0,sp,16
    printf("Memory Info:\n");
    80001442:	00005517          	auipc	a0,0x5
    80001446:	63e50513          	add	a0,a0,1598 # 80006a80 <userret+0xa1c>
    8000144a:	fffff097          	auipc	ra,0xfffff
    8000144e:	79c080e7          	jalr	1948(ra) # 80000be6 <printf>
    printf("  Total pages: %d (%d KB)\n", 
           (int)kmem.total_pages, (int)(kmem.total_pages * PGSIZE) / 1024);
    80001452:	0000d797          	auipc	a5,0xd
    80001456:	bae78793          	add	a5,a5,-1106 # 8000e000 <kmem>
    8000145a:	679c                	ld	a5,8(a5)
    printf("  Total pages: %d (%d KB)\n", 
    8000145c:	0007869b          	sext.w	a3,a5
           (int)kmem.total_pages, (int)(kmem.total_pages * PGSIZE) / 1024);
    80001460:	0000d797          	auipc	a5,0xd
    80001464:	ba078793          	add	a5,a5,-1120 # 8000e000 <kmem>
    80001468:	679c                	ld	a5,8(a5)
    8000146a:	2781                	sext.w	a5,a5
    8000146c:	00c7979b          	sllw	a5,a5,0xc
    80001470:	2781                	sext.w	a5,a5
    80001472:	2781                	sext.w	a5,a5
    printf("  Total pages: %d (%d KB)\n", 
    80001474:	41f7d71b          	sraw	a4,a5,0x1f
    80001478:	0167571b          	srlw	a4,a4,0x16
    8000147c:	9fb9                	addw	a5,a5,a4
    8000147e:	40a7d79b          	sraw	a5,a5,0xa
    80001482:	2781                	sext.w	a5,a5
    80001484:	863e                	mv	a2,a5
    80001486:	85b6                	mv	a1,a3
    80001488:	00005517          	auipc	a0,0x5
    8000148c:	60850513          	add	a0,a0,1544 # 80006a90 <userret+0xa2c>
    80001490:	fffff097          	auipc	ra,0xfffff
    80001494:	756080e7          	jalr	1878(ra) # 80000be6 <printf>
    printf("  Free pages:  %d (%d KB)\n", 
           (int)kmem.free_pages, (int)(kmem.free_pages * PGSIZE) / 1024);
    80001498:	0000d797          	auipc	a5,0xd
    8000149c:	b6878793          	add	a5,a5,-1176 # 8000e000 <kmem>
    800014a0:	6b9c                	ld	a5,16(a5)
    printf("  Free pages:  %d (%d KB)\n", 
    800014a2:	0007869b          	sext.w	a3,a5
           (int)kmem.free_pages, (int)(kmem.free_pages * PGSIZE) / 1024);
    800014a6:	0000d797          	auipc	a5,0xd
    800014aa:	b5a78793          	add	a5,a5,-1190 # 8000e000 <kmem>
    800014ae:	6b9c                	ld	a5,16(a5)
    800014b0:	2781                	sext.w	a5,a5
    800014b2:	00c7979b          	sllw	a5,a5,0xc
    800014b6:	2781                	sext.w	a5,a5
    800014b8:	2781                	sext.w	a5,a5
    printf("  Free pages:  %d (%d KB)\n", 
    800014ba:	41f7d71b          	sraw	a4,a5,0x1f
    800014be:	0167571b          	srlw	a4,a4,0x16
    800014c2:	9fb9                	addw	a5,a5,a4
    800014c4:	40a7d79b          	sraw	a5,a5,0xa
    800014c8:	2781                	sext.w	a5,a5
    800014ca:	863e                	mv	a2,a5
    800014cc:	85b6                	mv	a1,a3
    800014ce:	00005517          	auipc	a0,0x5
    800014d2:	5e250513          	add	a0,a0,1506 # 80006ab0 <userret+0xa4c>
    800014d6:	fffff097          	auipc	ra,0xfffff
    800014da:	710080e7          	jalr	1808(ra) # 80000be6 <printf>
    printf("  Used pages:  %d (%d KB)\n", 
           (int)(kmem.total_pages - kmem.free_pages), 
    800014de:	0000d797          	auipc	a5,0xd
    800014e2:	b2278793          	add	a5,a5,-1246 # 8000e000 <kmem>
    800014e6:	679c                	ld	a5,8(a5)
    800014e8:	0007871b          	sext.w	a4,a5
    800014ec:	0000d797          	auipc	a5,0xd
    800014f0:	b1478793          	add	a5,a5,-1260 # 8000e000 <kmem>
    800014f4:	6b9c                	ld	a5,16(a5)
    800014f6:	2781                	sext.w	a5,a5
    800014f8:	40f707bb          	subw	a5,a4,a5
    800014fc:	2781                	sext.w	a5,a5
    printf("  Used pages:  %d (%d KB)\n", 
    800014fe:	0007869b          	sext.w	a3,a5
           (int)((kmem.total_pages - kmem.free_pages) * PGSIZE) / 1024);
    80001502:	0000d797          	auipc	a5,0xd
    80001506:	afe78793          	add	a5,a5,-1282 # 8000e000 <kmem>
    8000150a:	6798                	ld	a4,8(a5)
    8000150c:	0000d797          	auipc	a5,0xd
    80001510:	af478793          	add	a5,a5,-1292 # 8000e000 <kmem>
    80001514:	6b9c                	ld	a5,16(a5)
    80001516:	40f707b3          	sub	a5,a4,a5
    8000151a:	2781                	sext.w	a5,a5
    8000151c:	00c7979b          	sllw	a5,a5,0xc
    80001520:	2781                	sext.w	a5,a5
    80001522:	2781                	sext.w	a5,a5
    printf("  Used pages:  %d (%d KB)\n", 
    80001524:	41f7d71b          	sraw	a4,a5,0x1f
    80001528:	0167571b          	srlw	a4,a4,0x16
    8000152c:	9fb9                	addw	a5,a5,a4
    8000152e:	40a7d79b          	sraw	a5,a5,0xa
    80001532:	2781                	sext.w	a5,a5
    80001534:	863e                	mv	a2,a5
    80001536:	85b6                	mv	a1,a3
    80001538:	00005517          	auipc	a0,0x5
    8000153c:	59850513          	add	a0,a0,1432 # 80006ad0 <userret+0xa6c>
    80001540:	fffff097          	auipc	ra,0xfffff
    80001544:	6a6080e7          	jalr	1702(ra) # 80000be6 <printf>
}
    80001548:	0001                	nop
    8000154a:	60a2                	ld	ra,8(sp)
    8000154c:	6402                	ld	s0,0(sp)
    8000154e:	0141                	add	sp,sp,16
    80001550:	8082                	ret

0000000080001552 <sfence_vma>:
        a += PGSIZE;
        pa += PGSIZE;
    }
    return 0;
}

    80001552:	1141                	add	sp,sp,-16
    80001554:	e422                	sd	s0,8(sp)
    80001556:	0800                	add	s0,sp,16
// 初始化内核页表
    80001558:	12000073          	sfence.vma
void kvminit(void)
    8000155c:	0001                	nop
    8000155e:	6422                	ld	s0,8(sp)
    80001560:	0141                	add	sp,sp,16
    80001562:	8082                	ret

0000000080001564 <create_pagetable>:
pagetable_t create_pagetable(void) {
    80001564:	1101                	add	sp,sp,-32
    80001566:	ec06                	sd	ra,24(sp)
    80001568:	e822                	sd	s0,16(sp)
    8000156a:	1000                	add	s0,sp,32
    pagetable_t pagetable = (pagetable_t)alloc_page();
    8000156c:	00000097          	auipc	ra,0x0
    80001570:	d7c080e7          	jalr	-644(ra) # 800012e8 <alloc_page>
    80001574:	fea43423          	sd	a0,-24(s0)
    if(pagetable == 0)
    80001578:	fe843783          	ld	a5,-24(s0)
    8000157c:	e399                	bnez	a5,80001582 <create_pagetable+0x1e>
        return 0;
    8000157e:	4781                	li	a5,0
    80001580:	a019                	j	80001586 <create_pagetable+0x22>
    return pagetable;
    80001582:	fe843783          	ld	a5,-24(s0)
}
    80001586:	853e                	mv	a0,a5
    80001588:	60e2                	ld	ra,24(sp)
    8000158a:	6442                	ld	s0,16(sp)
    8000158c:	6105                	add	sp,sp,32
    8000158e:	8082                	ret

0000000080001590 <freewalk>:
static void freewalk(pagetable_t pagetable) {
    80001590:	7139                	add	sp,sp,-64
    80001592:	fc06                	sd	ra,56(sp)
    80001594:	f822                	sd	s0,48(sp)
    80001596:	0080                	add	s0,sp,64
    80001598:	fca43423          	sd	a0,-56(s0)
    for(int i = 0; i < 512; i++) {
    8000159c:	fe042623          	sw	zero,-20(s0)
    800015a0:	a8a1                	j	800015f8 <freewalk+0x68>
        pte_t pte = pagetable[i];
    800015a2:	fec42783          	lw	a5,-20(s0)
    800015a6:	078e                	sll	a5,a5,0x3
    800015a8:	fc843703          	ld	a4,-56(s0)
    800015ac:	97ba                	add	a5,a5,a4
    800015ae:	639c                	ld	a5,0(a5)
    800015b0:	fef43023          	sd	a5,-32(s0)
        if(pte & PTE_V) {
    800015b4:	fe043783          	ld	a5,-32(s0)
    800015b8:	8b85                	and	a5,a5,1
    800015ba:	cb95                	beqz	a5,800015ee <freewalk+0x5e>
            if((pte & (PTE_R|PTE_W|PTE_X)) == 0) {
    800015bc:	fe043783          	ld	a5,-32(s0)
    800015c0:	8bb9                	and	a5,a5,14
    800015c2:	e795                	bnez	a5,800015ee <freewalk+0x5e>
                uint64 child = PTE_PA(pte);
    800015c4:	fe043783          	ld	a5,-32(s0)
    800015c8:	83a9                	srl	a5,a5,0xa
    800015ca:	07b2                	sll	a5,a5,0xc
    800015cc:	fcf43c23          	sd	a5,-40(s0)
                freewalk((pagetable_t)child);
    800015d0:	fd843783          	ld	a5,-40(s0)
    800015d4:	853e                	mv	a0,a5
    800015d6:	00000097          	auipc	ra,0x0
    800015da:	fba080e7          	jalr	-70(ra) # 80001590 <freewalk>
                pagetable[i] = 0;
    800015de:	fec42783          	lw	a5,-20(s0)
    800015e2:	078e                	sll	a5,a5,0x3
    800015e4:	fc843703          	ld	a4,-56(s0)
    800015e8:	97ba                	add	a5,a5,a4
    800015ea:	0007b023          	sd	zero,0(a5)
    for(int i = 0; i < 512; i++) {
    800015ee:	fec42783          	lw	a5,-20(s0)
    800015f2:	2785                	addw	a5,a5,1
    800015f4:	fef42623          	sw	a5,-20(s0)
    800015f8:	fec42783          	lw	a5,-20(s0)
    800015fc:	0007871b          	sext.w	a4,a5
    80001600:	1ff00793          	li	a5,511
    80001604:	f8e7dfe3          	bge	a5,a4,800015a2 <freewalk+0x12>
    free_page((void*)pagetable);
    80001608:	fc843503          	ld	a0,-56(s0)
    8000160c:	00000097          	auipc	ra,0x0
    80001610:	d3e080e7          	jalr	-706(ra) # 8000134a <free_page>
}
    80001614:	0001                	nop
    80001616:	70e2                	ld	ra,56(sp)
    80001618:	7442                	ld	s0,48(sp)
    8000161a:	6121                	add	sp,sp,64
    8000161c:	8082                	ret

000000008000161e <destroy_pagetable>:
void destroy_pagetable(pagetable_t pagetable) {
    8000161e:	1101                	add	sp,sp,-32
    80001620:	ec06                	sd	ra,24(sp)
    80001622:	e822                	sd	s0,16(sp)
    80001624:	1000                	add	s0,sp,32
    80001626:	fea43423          	sd	a0,-24(s0)
    if(pagetable == 0)
    8000162a:	fe843783          	ld	a5,-24(s0)
    8000162e:	cb81                	beqz	a5,8000163e <destroy_pagetable+0x20>
    freewalk(pagetable);
    80001630:	fe843503          	ld	a0,-24(s0)
    80001634:	00000097          	auipc	ra,0x0
    80001638:	f5c080e7          	jalr	-164(ra) # 80001590 <freewalk>
    8000163c:	a011                	j	80001640 <destroy_pagetable+0x22>
        return;
    8000163e:	0001                	nop
}
    80001640:	60e2                	ld	ra,24(sp)
    80001642:	6442                	ld	s0,16(sp)
    80001644:	6105                	add	sp,sp,32
    80001646:	8082                	ret

0000000080001648 <walk_lookup>:
pte_t* walk_lookup(pagetable_t pagetable, uint64 va) {
    80001648:	7179                	add	sp,sp,-48
    8000164a:	f406                	sd	ra,40(sp)
    8000164c:	f022                	sd	s0,32(sp)
    8000164e:	1800                	add	s0,sp,48
    80001650:	fca43c23          	sd	a0,-40(s0)
    80001654:	fcb43823          	sd	a1,-48(s0)
    if(va >= (1L << 39))
    80001658:	fd043703          	ld	a4,-48(s0)
    8000165c:	57fd                	li	a5,-1
    8000165e:	83e5                	srl	a5,a5,0x19
    80001660:	00e7fa63          	bgeu	a5,a4,80001674 <walk_lookup+0x2c>
        panic("walk_lookup: va too large");
    80001664:	00005517          	auipc	a0,0x5
    80001668:	48c50513          	add	a0,a0,1164 # 80006af0 <userret+0xa8c>
    8000166c:	00000097          	auipc	ra,0x0
    80001670:	920080e7          	jalr	-1760(ra) # 80000f8c <panic>
    for(int level = 2; level > 0; level--) {
    80001674:	4789                	li	a5,2
    80001676:	fef42623          	sw	a5,-20(s0)
    8000167a:	a8a1                	j	800016d2 <walk_lookup+0x8a>
        pte_t *pte = &pagetable[PX(level, va)];
    8000167c:	fec42783          	lw	a5,-20(s0)
    80001680:	873e                	mv	a4,a5
    80001682:	87ba                	mv	a5,a4
    80001684:	0037979b          	sllw	a5,a5,0x3
    80001688:	9fb9                	addw	a5,a5,a4
    8000168a:	2781                	sext.w	a5,a5
    8000168c:	27b1                	addw	a5,a5,12
    8000168e:	2781                	sext.w	a5,a5
    80001690:	873e                	mv	a4,a5
    80001692:	fd043783          	ld	a5,-48(s0)
    80001696:	00e7d7b3          	srl	a5,a5,a4
    8000169a:	1ff7f793          	and	a5,a5,511
    8000169e:	078e                	sll	a5,a5,0x3
    800016a0:	fd843703          	ld	a4,-40(s0)
    800016a4:	97ba                	add	a5,a5,a4
    800016a6:	fef43023          	sd	a5,-32(s0)
        if(*pte & PTE_V) {
    800016aa:	fe043783          	ld	a5,-32(s0)
    800016ae:	639c                	ld	a5,0(a5)
    800016b0:	8b85                	and	a5,a5,1
    800016b2:	cb89                	beqz	a5,800016c4 <walk_lookup+0x7c>
            pagetable = (pagetable_t)PTE_PA(*pte);
    800016b4:	fe043783          	ld	a5,-32(s0)
    800016b8:	639c                	ld	a5,0(a5)
    800016ba:	83a9                	srl	a5,a5,0xa
    800016bc:	07b2                	sll	a5,a5,0xc
    800016be:	fcf43c23          	sd	a5,-40(s0)
    800016c2:	a019                	j	800016c8 <walk_lookup+0x80>
            return 0;
    800016c4:	4781                	li	a5,0
    800016c6:	a025                	j	800016ee <walk_lookup+0xa6>
    for(int level = 2; level > 0; level--) {
    800016c8:	fec42783          	lw	a5,-20(s0)
    800016cc:	37fd                	addw	a5,a5,-1
    800016ce:	fef42623          	sw	a5,-20(s0)
    800016d2:	fec42783          	lw	a5,-20(s0)
    800016d6:	2781                	sext.w	a5,a5
    800016d8:	faf042e3          	bgtz	a5,8000167c <walk_lookup+0x34>
    return &pagetable[PX(0, va)];
    800016dc:	fd043783          	ld	a5,-48(s0)
    800016e0:	83b1                	srl	a5,a5,0xc
    800016e2:	1ff7f793          	and	a5,a5,511
    800016e6:	078e                	sll	a5,a5,0x3
    800016e8:	fd843703          	ld	a4,-40(s0)
    800016ec:	97ba                	add	a5,a5,a4
}
    800016ee:	853e                	mv	a0,a5
    800016f0:	70a2                	ld	ra,40(sp)
    800016f2:	7402                	ld	s0,32(sp)
    800016f4:	6145                	add	sp,sp,48
    800016f6:	8082                	ret

00000000800016f8 <walk_create>:
pte_t* walk_create(pagetable_t pagetable, uint64 va) {
    800016f8:	7179                	add	sp,sp,-48
    800016fa:	f406                	sd	ra,40(sp)
    800016fc:	f022                	sd	s0,32(sp)
    800016fe:	1800                	add	s0,sp,48
    80001700:	fca43c23          	sd	a0,-40(s0)
    80001704:	fcb43823          	sd	a1,-48(s0)
    if(va >= (1L << 39))
    80001708:	fd043703          	ld	a4,-48(s0)
    8000170c:	57fd                	li	a5,-1
    8000170e:	83e5                	srl	a5,a5,0x19
    80001710:	00e7fa63          	bgeu	a5,a4,80001724 <walk_create+0x2c>
        panic("walk_create: va too large");
    80001714:	00005517          	auipc	a0,0x5
    80001718:	3fc50513          	add	a0,a0,1020 # 80006b10 <userret+0xaac>
    8000171c:	00000097          	auipc	ra,0x0
    80001720:	870080e7          	jalr	-1936(ra) # 80000f8c <panic>
    for(int level = 2; level > 0; level--) {
    80001724:	4789                	li	a5,2
    80001726:	fef42623          	sw	a5,-20(s0)
    8000172a:	a8b5                	j	800017a6 <walk_create+0xae>
        pte_t *pte = &pagetable[PX(level, va)];
    8000172c:	fec42783          	lw	a5,-20(s0)
    80001730:	873e                	mv	a4,a5
    80001732:	87ba                	mv	a5,a4
    80001734:	0037979b          	sllw	a5,a5,0x3
    80001738:	9fb9                	addw	a5,a5,a4
    8000173a:	2781                	sext.w	a5,a5
    8000173c:	27b1                	addw	a5,a5,12
    8000173e:	2781                	sext.w	a5,a5
    80001740:	873e                	mv	a4,a5
    80001742:	fd043783          	ld	a5,-48(s0)
    80001746:	00e7d7b3          	srl	a5,a5,a4
    8000174a:	1ff7f793          	and	a5,a5,511
    8000174e:	078e                	sll	a5,a5,0x3
    80001750:	fd843703          	ld	a4,-40(s0)
    80001754:	97ba                	add	a5,a5,a4
    80001756:	fef43023          	sd	a5,-32(s0)
        if(*pte & PTE_V) {
    8000175a:	fe043783          	ld	a5,-32(s0)
    8000175e:	639c                	ld	a5,0(a5)
    80001760:	8b85                	and	a5,a5,1
    80001762:	cb89                	beqz	a5,80001774 <walk_create+0x7c>
            pagetable = (pagetable_t)PTE_PA(*pte);
    80001764:	fe043783          	ld	a5,-32(s0)
    80001768:	639c                	ld	a5,0(a5)
    8000176a:	83a9                	srl	a5,a5,0xa
    8000176c:	07b2                	sll	a5,a5,0xc
    8000176e:	fcf43c23          	sd	a5,-40(s0)
    80001772:	a02d                	j	8000179c <walk_create+0xa4>
            pagetable = (pagetable_t)alloc_page();
    80001774:	00000097          	auipc	ra,0x0
    80001778:	b74080e7          	jalr	-1164(ra) # 800012e8 <alloc_page>
    8000177c:	fca43c23          	sd	a0,-40(s0)
            if(pagetable == 0)
    80001780:	fd843783          	ld	a5,-40(s0)
    80001784:	e399                	bnez	a5,8000178a <walk_create+0x92>
                return 0;
    80001786:	4781                	li	a5,0
    80001788:	a82d                	j	800017c2 <walk_create+0xca>
            *pte = PA2PTE(pagetable) | PTE_V;
    8000178a:	fd843783          	ld	a5,-40(s0)
    8000178e:	83b1                	srl	a5,a5,0xc
    80001790:	07aa                	sll	a5,a5,0xa
    80001792:	0017e713          	or	a4,a5,1
    80001796:	fe043783          	ld	a5,-32(s0)
    8000179a:	e398                	sd	a4,0(a5)
    for(int level = 2; level > 0; level--) {
    8000179c:	fec42783          	lw	a5,-20(s0)
    800017a0:	37fd                	addw	a5,a5,-1
    800017a2:	fef42623          	sw	a5,-20(s0)
    800017a6:	fec42783          	lw	a5,-20(s0)
    800017aa:	2781                	sext.w	a5,a5
    800017ac:	f8f040e3          	bgtz	a5,8000172c <walk_create+0x34>
    return &pagetable[PX(0, va)];
    800017b0:	fd043783          	ld	a5,-48(s0)
    800017b4:	83b1                	srl	a5,a5,0xc
    800017b6:	1ff7f793          	and	a5,a5,511
    800017ba:	078e                	sll	a5,a5,0x3
    800017bc:	fd843703          	ld	a4,-40(s0)
    800017c0:	97ba                	add	a5,a5,a4
}
    800017c2:	853e                	mv	a0,a5
    800017c4:	70a2                	ld	ra,40(sp)
    800017c6:	7402                	ld	s0,32(sp)
    800017c8:	6145                	add	sp,sp,48
    800017ca:	8082                	ret

00000000800017cc <map_page>:
int map_page(pagetable_t pagetable, uint64 va, uint64 pa, int perm) {
    800017cc:	7139                	add	sp,sp,-64
    800017ce:	fc06                	sd	ra,56(sp)
    800017d0:	f822                	sd	s0,48(sp)
    800017d2:	0080                	add	s0,sp,64
    800017d4:	fca43c23          	sd	a0,-40(s0)
    800017d8:	fcb43823          	sd	a1,-48(s0)
    800017dc:	fcc43423          	sd	a2,-56(s0)
    800017e0:	87b6                	mv	a5,a3
    800017e2:	fcf42223          	sw	a5,-60(s0)
    if(va % PGSIZE != 0)
    800017e6:	fd043703          	ld	a4,-48(s0)
    800017ea:	6785                	lui	a5,0x1
    800017ec:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    800017ee:	8ff9                	and	a5,a5,a4
    800017f0:	cb89                	beqz	a5,80001802 <map_page+0x36>
        panic("map_page: va not page aligned");
    800017f2:	00005517          	auipc	a0,0x5
    800017f6:	33e50513          	add	a0,a0,830 # 80006b30 <userret+0xacc>
    800017fa:	fffff097          	auipc	ra,0xfffff
    800017fe:	792080e7          	jalr	1938(ra) # 80000f8c <panic>
    if(pa % PGSIZE != 0)
    80001802:	fc843703          	ld	a4,-56(s0)
    80001806:	6785                	lui	a5,0x1
    80001808:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000180a:	8ff9                	and	a5,a5,a4
    8000180c:	cb89                	beqz	a5,8000181e <map_page+0x52>
        panic("map_page: pa not page aligned");
    8000180e:	00005517          	auipc	a0,0x5
    80001812:	34250513          	add	a0,a0,834 # 80006b50 <userret+0xaec>
    80001816:	fffff097          	auipc	ra,0xfffff
    8000181a:	776080e7          	jalr	1910(ra) # 80000f8c <panic>
    pte_t *pte = walk_create(pagetable, va);
    8000181e:	fd043583          	ld	a1,-48(s0)
    80001822:	fd843503          	ld	a0,-40(s0)
    80001826:	00000097          	auipc	ra,0x0
    8000182a:	ed2080e7          	jalr	-302(ra) # 800016f8 <walk_create>
    8000182e:	fea43423          	sd	a0,-24(s0)
    if(pte == 0)
    80001832:	fe843783          	ld	a5,-24(s0)
    80001836:	e399                	bnez	a5,8000183c <map_page+0x70>
        return -1;
    80001838:	57fd                	li	a5,-1
    8000183a:	a825                	j	80001872 <map_page+0xa6>
    if(*pte & PTE_V)
    8000183c:	fe843783          	ld	a5,-24(s0)
    80001840:	639c                	ld	a5,0(a5)
    80001842:	8b85                	and	a5,a5,1
    80001844:	cb89                	beqz	a5,80001856 <map_page+0x8a>
        panic("map_page: page already mapped");
    80001846:	00005517          	auipc	a0,0x5
    8000184a:	32a50513          	add	a0,a0,810 # 80006b70 <userret+0xb0c>
    8000184e:	fffff097          	auipc	ra,0xfffff
    80001852:	73e080e7          	jalr	1854(ra) # 80000f8c <panic>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001856:	fc843783          	ld	a5,-56(s0)
    8000185a:	83b1                	srl	a5,a5,0xc
    8000185c:	00a79713          	sll	a4,a5,0xa
    80001860:	fc442783          	lw	a5,-60(s0)
    80001864:	8fd9                	or	a5,a5,a4
    80001866:	0017e713          	or	a4,a5,1
    8000186a:	fe843783          	ld	a5,-24(s0)
    8000186e:	e398                	sd	a4,0(a5)
    return 0;
    80001870:	4781                	li	a5,0
}
    80001872:	853e                	mv	a0,a5
    80001874:	70e2                	ld	ra,56(sp)
    80001876:	7442                	ld	s0,48(sp)
    80001878:	6121                	add	sp,sp,64
    8000187a:	8082                	ret

000000008000187c <map_region>:
int map_region(pagetable_t pagetable, uint64 va, uint64 pa, uint64 size, int perm) {
    8000187c:	715d                	add	sp,sp,-80
    8000187e:	e486                	sd	ra,72(sp)
    80001880:	e0a2                	sd	s0,64(sp)
    80001882:	0880                	add	s0,sp,80
    80001884:	fca43c23          	sd	a0,-40(s0)
    80001888:	fcb43823          	sd	a1,-48(s0)
    8000188c:	fcc43423          	sd	a2,-56(s0)
    80001890:	fcd43023          	sd	a3,-64(s0)
    80001894:	87ba                	mv	a5,a4
    80001896:	faf42e23          	sw	a5,-68(s0)
    if(size == 0)
    8000189a:	fc043783          	ld	a5,-64(s0)
    8000189e:	e399                	bnez	a5,800018a4 <map_region+0x28>
        return 0;
    800018a0:	4781                	li	a5,0
    800018a2:	a885                	j	80001912 <map_region+0x96>
    a = PGROUNDDOWN(va);
    800018a4:	fd043703          	ld	a4,-48(s0)
    800018a8:	77fd                	lui	a5,0xfffff
    800018aa:	8ff9                	and	a5,a5,a4
    800018ac:	fef43423          	sd	a5,-24(s0)
    last = PGROUNDDOWN(va + size - 1);
    800018b0:	fd043703          	ld	a4,-48(s0)
    800018b4:	fc043783          	ld	a5,-64(s0)
    800018b8:	97ba                	add	a5,a5,a4
    800018ba:	fff78713          	add	a4,a5,-1 # ffffffffffffefff <end+0xffffffff7ffecfff>
    800018be:	77fd                	lui	a5,0xfffff
    800018c0:	8ff9                	and	a5,a5,a4
    800018c2:	fef43023          	sd	a5,-32(s0)
        if(map_page(pagetable, a, pa, perm) != 0)
    800018c6:	fbc42783          	lw	a5,-68(s0)
    800018ca:	86be                	mv	a3,a5
    800018cc:	fc843603          	ld	a2,-56(s0)
    800018d0:	fe843583          	ld	a1,-24(s0)
    800018d4:	fd843503          	ld	a0,-40(s0)
    800018d8:	00000097          	auipc	ra,0x0
    800018dc:	ef4080e7          	jalr	-268(ra) # 800017cc <map_page>
    800018e0:	87aa                	mv	a5,a0
    800018e2:	c399                	beqz	a5,800018e8 <map_region+0x6c>
            return -1;
    800018e4:	57fd                	li	a5,-1
    800018e6:	a035                	j	80001912 <map_region+0x96>
        if(a == last)
    800018e8:	fe843703          	ld	a4,-24(s0)
    800018ec:	fe043783          	ld	a5,-32(s0)
    800018f0:	00f70f63          	beq	a4,a5,8000190e <map_region+0x92>
        a += PGSIZE;
    800018f4:	fe843703          	ld	a4,-24(s0)
    800018f8:	6785                	lui	a5,0x1
    800018fa:	97ba                	add	a5,a5,a4
    800018fc:	fef43423          	sd	a5,-24(s0)
        pa += PGSIZE;
    80001900:	fc843703          	ld	a4,-56(s0)
    80001904:	6785                	lui	a5,0x1
    80001906:	97ba                	add	a5,a5,a4
    80001908:	fcf43423          	sd	a5,-56(s0)
        if(map_page(pagetable, a, pa, perm) != 0)
    8000190c:	bf6d                	j	800018c6 <map_region+0x4a>
            break;
    8000190e:	0001                	nop
    return 0;
    80001910:	4781                	li	a5,0
}
    80001912:	853e                	mv	a0,a5
    80001914:	60a6                	ld	ra,72(sp)
    80001916:	6406                	ld	s0,64(sp)
    80001918:	6161                	add	sp,sp,80
    8000191a:	8082                	ret

000000008000191c <kvminit>:
{
    8000191c:	1141                	add	sp,sp,-16
    8000191e:	e406                	sd	ra,8(sp)
    80001920:	e022                	sd	s0,0(sp)
    80001922:	0800                	add	s0,sp,16
    printf("Setting up kernel page table...\n");
    80001924:	00005517          	auipc	a0,0x5
    80001928:	26c50513          	add	a0,a0,620 # 80006b90 <userret+0xb2c>
    8000192c:	fffff097          	auipc	ra,0xfffff
    80001930:	2ba080e7          	jalr	698(ra) # 80000be6 <printf>
    
    kernel_pagetable = create_pagetable();
    80001934:	00000097          	auipc	ra,0x0
    80001938:	c30080e7          	jalr	-976(ra) # 80001564 <create_pagetable>
    8000193c:	872a                	mv	a4,a0
    8000193e:	00008797          	auipc	a5,0x8
    80001942:	6ca78793          	add	a5,a5,1738 # 8000a008 <kernel_pagetable>
    80001946:	e398                	sd	a4,0(a5)
    if(kernel_pagetable == 0) {
    80001948:	00008797          	auipc	a5,0x8
    8000194c:	6c078793          	add	a5,a5,1728 # 8000a008 <kernel_pagetable>
    80001950:	639c                	ld	a5,0(a5)
    80001952:	eb89                	bnez	a5,80001964 <kvminit+0x48>
        panic("kvminit: create_pagetable");
    80001954:	00005517          	auipc	a0,0x5
    80001958:	26450513          	add	a0,a0,612 # 80006bb8 <userret+0xb54>
    8000195c:	fffff097          	auipc	ra,0xfffff
    80001960:	630080e7          	jalr	1584(ra) # 80000f8c <panic>
    }
    
    // 映射内核代码段
    printf("Mapping kernel text: %p - %p\n", 
    80001964:	00004617          	auipc	a2,0x4
    80001968:	69c60613          	add	a2,a2,1692 # 80006000 <etext>
    8000196c:	4785                	li	a5,1
    8000196e:	01f79593          	sll	a1,a5,0x1f
    80001972:	00005517          	auipc	a0,0x5
    80001976:	26650513          	add	a0,a0,614 # 80006bd8 <userret+0xb74>
    8000197a:	fffff097          	auipc	ra,0xfffff
    8000197e:	26c080e7          	jalr	620(ra) # 80000be6 <printf>
           (void*)KERNBASE, (void*)etext);
    if(map_region(kernel_pagetable, KERNBASE, KERNBASE,
    80001982:	00008797          	auipc	a5,0x8
    80001986:	68678793          	add	a5,a5,1670 # 8000a008 <kernel_pagetable>
    8000198a:	6388                	ld	a0,0(a5)
                  (uint64)etext - KERNBASE, PTE_R | PTE_X) != 0) {
    8000198c:	00004717          	auipc	a4,0x4
    80001990:	67470713          	add	a4,a4,1652 # 80006000 <etext>
    if(map_region(kernel_pagetable, KERNBASE, KERNBASE,
    80001994:	800007b7          	lui	a5,0x80000
    80001998:	97ba                	add	a5,a5,a4
    8000199a:	4729                	li	a4,10
    8000199c:	86be                	mv	a3,a5
    8000199e:	4785                	li	a5,1
    800019a0:	01f79613          	sll	a2,a5,0x1f
    800019a4:	4785                	li	a5,1
    800019a6:	01f79593          	sll	a1,a5,0x1f
    800019aa:	00000097          	auipc	ra,0x0
    800019ae:	ed2080e7          	jalr	-302(ra) # 8000187c <map_region>
    800019b2:	87aa                	mv	a5,a0
    800019b4:	cb89                	beqz	a5,800019c6 <kvminit+0xaa>
        panic("kvminit: map text");
    800019b6:	00005517          	auipc	a0,0x5
    800019ba:	24250513          	add	a0,a0,578 # 80006bf8 <userret+0xb94>
    800019be:	fffff097          	auipc	ra,0xfffff
    800019c2:	5ce080e7          	jalr	1486(ra) # 80000f8c <panic>
    }
    
    // 映射内核数据段和剩余物理内存
    printf("Mapping kernel data: %p - %p\n",
    800019c6:	47c5                	li	a5,17
    800019c8:	01b79613          	sll	a2,a5,0x1b
    800019cc:	00004597          	auipc	a1,0x4
    800019d0:	63458593          	add	a1,a1,1588 # 80006000 <etext>
    800019d4:	00005517          	auipc	a0,0x5
    800019d8:	23c50513          	add	a0,a0,572 # 80006c10 <userret+0xbac>
    800019dc:	fffff097          	auipc	ra,0xfffff
    800019e0:	20a080e7          	jalr	522(ra) # 80000be6 <printf>
           (void*)((uint64)etext), (void*)PHYSTOP);
    if(map_region(kernel_pagetable, (uint64)etext, (uint64)etext,
    800019e4:	00008797          	auipc	a5,0x8
    800019e8:	62478793          	add	a5,a5,1572 # 8000a008 <kernel_pagetable>
    800019ec:	6388                	ld	a0,0(a5)
    800019ee:	00004597          	auipc	a1,0x4
    800019f2:	61258593          	add	a1,a1,1554 # 80006000 <etext>
    800019f6:	00004617          	auipc	a2,0x4
    800019fa:	60a60613          	add	a2,a2,1546 # 80006000 <etext>
                  PHYSTOP - (uint64)etext, PTE_R | PTE_W) != 0) {
    800019fe:	00004797          	auipc	a5,0x4
    80001a02:	60278793          	add	a5,a5,1538 # 80006000 <etext>
    if(map_region(kernel_pagetable, (uint64)etext, (uint64)etext,
    80001a06:	4745                	li	a4,17
    80001a08:	076e                	sll	a4,a4,0x1b
    80001a0a:	40f707b3          	sub	a5,a4,a5
    80001a0e:	4719                	li	a4,6
    80001a10:	86be                	mv	a3,a5
    80001a12:	00000097          	auipc	ra,0x0
    80001a16:	e6a080e7          	jalr	-406(ra) # 8000187c <map_region>
    80001a1a:	87aa                	mv	a5,a0
    80001a1c:	cb89                	beqz	a5,80001a2e <kvminit+0x112>
        panic("kvminit: map data");
    80001a1e:	00005517          	auipc	a0,0x5
    80001a22:	21250513          	add	a0,a0,530 # 80006c30 <userret+0xbcc>
    80001a26:	fffff097          	auipc	ra,0xfffff
    80001a2a:	566080e7          	jalr	1382(ra) # 80000f8c <panic>
    }
    
    // 映射 UART
    printf("Mapping UART: %p\n", (void*)UART0);
    80001a2e:	100005b7          	lui	a1,0x10000
    80001a32:	00005517          	auipc	a0,0x5
    80001a36:	21650513          	add	a0,a0,534 # 80006c48 <userret+0xbe4>
    80001a3a:	fffff097          	auipc	ra,0xfffff
    80001a3e:	1ac080e7          	jalr	428(ra) # 80000be6 <printf>
    if(map_page(kernel_pagetable, UART0, UART0,
    80001a42:	00008797          	auipc	a5,0x8
    80001a46:	5c678793          	add	a5,a5,1478 # 8000a008 <kernel_pagetable>
    80001a4a:	639c                	ld	a5,0(a5)
    80001a4c:	4699                	li	a3,6
    80001a4e:	10000637          	lui	a2,0x10000
    80001a52:	100005b7          	lui	a1,0x10000
    80001a56:	853e                	mv	a0,a5
    80001a58:	00000097          	auipc	ra,0x0
    80001a5c:	d74080e7          	jalr	-652(ra) # 800017cc <map_page>
    80001a60:	87aa                	mv	a5,a0
    80001a62:	cb89                	beqz	a5,80001a74 <kvminit+0x158>
                PTE_R | PTE_W) != 0) {
        panic("kvminit: map uart");
    80001a64:	00005517          	auipc	a0,0x5
    80001a68:	1fc50513          	add	a0,a0,508 # 80006c60 <userret+0xbfc>
    80001a6c:	fffff097          	auipc	ra,0xfffff
    80001a70:	520080e7          	jalr	1312(ra) # 80000f8c <panic>
    }
    
    // 映射 trampoline（关键）
    extern char trampoline[];
    printf("Mapping trampoline: %p -> %p\n", 
    80001a74:	00004617          	auipc	a2,0x4
    80001a78:	58c60613          	add	a2,a2,1420 # 80006000 <etext>
    80001a7c:	040007b7          	lui	a5,0x4000
    80001a80:	17fd                	add	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80001a82:	00c79593          	sll	a1,a5,0xc
    80001a86:	00005517          	auipc	a0,0x5
    80001a8a:	1f250513          	add	a0,a0,498 # 80006c78 <userret+0xc14>
    80001a8e:	fffff097          	auipc	ra,0xfffff
    80001a92:	158080e7          	jalr	344(ra) # 80000be6 <printf>
           (void*)TRAMPOLINE, (void*)trampoline);
    if(map_page(kernel_pagetable, TRAMPOLINE, (uint64)trampoline,
    80001a96:	00008797          	auipc	a5,0x8
    80001a9a:	57278793          	add	a5,a5,1394 # 8000a008 <kernel_pagetable>
    80001a9e:	6398                	ld	a4,0(a5)
    80001aa0:	00004797          	auipc	a5,0x4
    80001aa4:	56078793          	add	a5,a5,1376 # 80006000 <etext>
    80001aa8:	46a9                	li	a3,10
    80001aaa:	863e                	mv	a2,a5
    80001aac:	040007b7          	lui	a5,0x4000
    80001ab0:	17fd                	add	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80001ab2:	00c79593          	sll	a1,a5,0xc
    80001ab6:	853a                	mv	a0,a4
    80001ab8:	00000097          	auipc	ra,0x0
    80001abc:	d14080e7          	jalr	-748(ra) # 800017cc <map_page>
    80001ac0:	87aa                	mv	a5,a0
    80001ac2:	cb89                	beqz	a5,80001ad4 <kvminit+0x1b8>
                PTE_R | PTE_X) != 0) {
        panic("kvminit: map trampoline");
    80001ac4:	00005517          	auipc	a0,0x5
    80001ac8:	1d450513          	add	a0,a0,468 # 80006c98 <userret+0xc34>
    80001acc:	fffff097          	auipc	ra,0xfffff
    80001ad0:	4c0080e7          	jalr	1216(ra) # 80000f8c <panic>
    }
    
    printf("Kernel page table setup complete\n");
    80001ad4:	00005517          	auipc	a0,0x5
    80001ad8:	1dc50513          	add	a0,a0,476 # 80006cb0 <userret+0xc4c>
    80001adc:	fffff097          	auipc	ra,0xfffff
    80001ae0:	10a080e7          	jalr	266(ra) # 80000be6 <printf>
}
    80001ae4:	0001                	nop
    80001ae6:	60a2                	ld	ra,8(sp)
    80001ae8:	6402                	ld	s0,0(sp)
    80001aea:	0141                	add	sp,sp,16
    80001aec:	8082                	ret

0000000080001aee <kvminithart>:

// 激活内核页表
void kvminithart(void) {
    80001aee:	1141                	add	sp,sp,-16
    80001af0:	e406                	sd	ra,8(sp)
    80001af2:	e022                	sd	s0,0(sp)
    80001af4:	0800                	add	s0,sp,16
    w_satp(MAKE_SATP(kernel_pagetable));
    80001af6:	00008797          	auipc	a5,0x8
    80001afa:	51278793          	add	a5,a5,1298 # 8000a008 <kernel_pagetable>
    80001afe:	639c                	ld	a5,0(a5)
    80001b00:	00c7d713          	srl	a4,a5,0xc
    80001b04:	57fd                	li	a5,-1
    80001b06:	17fe                	sll	a5,a5,0x3f
    80001b08:	8fd9                	or	a5,a5,a4
    80001b0a:	18079073          	csrw	satp,a5
    sfence_vma();
    80001b0e:	00000097          	auipc	ra,0x0
    80001b12:	a44080e7          	jalr	-1468(ra) # 80001552 <sfence_vma>
    printf("Virtual memory enabled!\n");
    80001b16:	00005517          	auipc	a0,0x5
    80001b1a:	1c250513          	add	a0,a0,450 # 80006cd8 <userret+0xc74>
    80001b1e:	fffff097          	auipc	ra,0xfffff
    80001b22:	0c8080e7          	jalr	200(ra) # 80000be6 <printf>
}
    80001b26:	0001                	nop
    80001b28:	60a2                	ld	ra,8(sp)
    80001b2a:	6402                	ld	s0,0(sp)
    80001b2c:	0141                	add	sp,sp,16
    80001b2e:	8082                	ret

0000000080001b30 <dump_pagetable>:

// 调试用：打印页表
void dump_pagetable(pagetable_t pagetable, int level) {
    80001b30:	7179                	add	sp,sp,-48
    80001b32:	f406                	sd	ra,40(sp)
    80001b34:	f022                	sd	s0,32(sp)
    80001b36:	1800                	add	s0,sp,48
    80001b38:	fca43c23          	sd	a0,-40(s0)
    80001b3c:	87ae                	mv	a5,a1
    80001b3e:	fcf42a23          	sw	a5,-44(s0)
    if(level > 2) return;
    80001b42:	fd442783          	lw	a5,-44(s0)
    80001b46:	0007871b          	sext.w	a4,a5
    80001b4a:	4789                	li	a5,2
    80001b4c:	10e7c163          	blt	a5,a4,80001c4e <dump_pagetable+0x11e>
    
    printf("Page table at level %d:\n", level);
    80001b50:	fd442783          	lw	a5,-44(s0)
    80001b54:	85be                	mv	a1,a5
    80001b56:	00005517          	auipc	a0,0x5
    80001b5a:	1a250513          	add	a0,a0,418 # 80006cf8 <userret+0xc94>
    80001b5e:	fffff097          	auipc	ra,0xfffff
    80001b62:	088080e7          	jalr	136(ra) # 80000be6 <printf>
    int count = 0;
    80001b66:	fe042623          	sw	zero,-20(s0)
    for(int i = 0; i < 512; i++) {
    80001b6a:	fe042423          	sw	zero,-24(s0)
    80001b6e:	a0f9                	j	80001c3c <dump_pagetable+0x10c>
        pte_t pte = pagetable[i];
    80001b70:	fe842783          	lw	a5,-24(s0)
    80001b74:	078e                	sll	a5,a5,0x3
    80001b76:	fd843703          	ld	a4,-40(s0)
    80001b7a:	97ba                	add	a5,a5,a4
    80001b7c:	639c                	ld	a5,0(a5)
    80001b7e:	fef43023          	sd	a5,-32(s0)
        if(pte & PTE_V) {
    80001b82:	fe043783          	ld	a5,-32(s0)
    80001b86:	8b85                	and	a5,a5,1
    80001b88:	c7cd                	beqz	a5,80001c32 <dump_pagetable+0x102>
            printf("  [%d]: %p", i, (void*)pte);
    80001b8a:	fe043703          	ld	a4,-32(s0)
    80001b8e:	fe842783          	lw	a5,-24(s0)
    80001b92:	863a                	mv	a2,a4
    80001b94:	85be                	mv	a1,a5
    80001b96:	00005517          	auipc	a0,0x5
    80001b9a:	18250513          	add	a0,a0,386 # 80006d18 <userret+0xcb4>
    80001b9e:	fffff097          	auipc	ra,0xfffff
    80001ba2:	048080e7          	jalr	72(ra) # 80000be6 <printf>
            if(pte & PTE_R) printf(" R");
    80001ba6:	fe043783          	ld	a5,-32(s0)
    80001baa:	8b89                	and	a5,a5,2
    80001bac:	cb89                	beqz	a5,80001bbe <dump_pagetable+0x8e>
    80001bae:	00005517          	auipc	a0,0x5
    80001bb2:	17a50513          	add	a0,a0,378 # 80006d28 <userret+0xcc4>
    80001bb6:	fffff097          	auipc	ra,0xfffff
    80001bba:	030080e7          	jalr	48(ra) # 80000be6 <printf>
            if(pte & PTE_W) printf(" W");
    80001bbe:	fe043783          	ld	a5,-32(s0)
    80001bc2:	8b91                	and	a5,a5,4
    80001bc4:	cb89                	beqz	a5,80001bd6 <dump_pagetable+0xa6>
    80001bc6:	00005517          	auipc	a0,0x5
    80001bca:	16a50513          	add	a0,a0,362 # 80006d30 <userret+0xccc>
    80001bce:	fffff097          	auipc	ra,0xfffff
    80001bd2:	018080e7          	jalr	24(ra) # 80000be6 <printf>
            if(pte & PTE_X) printf(" X");
    80001bd6:	fe043783          	ld	a5,-32(s0)
    80001bda:	8ba1                	and	a5,a5,8
    80001bdc:	cb89                	beqz	a5,80001bee <dump_pagetable+0xbe>
    80001bde:	00005517          	auipc	a0,0x5
    80001be2:	15a50513          	add	a0,a0,346 # 80006d38 <userret+0xcd4>
    80001be6:	fffff097          	auipc	ra,0xfffff
    80001bea:	000080e7          	jalr	ra # 80000be6 <printf>
            printf(" -> PA %p\n", (void*)PTE_PA(pte));
    80001bee:	fe043783          	ld	a5,-32(s0)
    80001bf2:	83a9                	srl	a5,a5,0xa
    80001bf4:	07b2                	sll	a5,a5,0xc
    80001bf6:	85be                	mv	a1,a5
    80001bf8:	00005517          	auipc	a0,0x5
    80001bfc:	14850513          	add	a0,a0,328 # 80006d40 <userret+0xcdc>
    80001c00:	fffff097          	auipc	ra,0xfffff
    80001c04:	fe6080e7          	jalr	-26(ra) # 80000be6 <printf>
            count++;
    80001c08:	fec42783          	lw	a5,-20(s0)
    80001c0c:	2785                	addw	a5,a5,1
    80001c0e:	fef42623          	sw	a5,-20(s0)
            if(count > 10) {
    80001c12:	fec42783          	lw	a5,-20(s0)
    80001c16:	0007871b          	sext.w	a4,a5
    80001c1a:	47a9                	li	a5,10
    80001c1c:	00e7db63          	bge	a5,a4,80001c32 <dump_pagetable+0x102>
                printf("  ... (more entries)\n");
    80001c20:	00005517          	auipc	a0,0x5
    80001c24:	13050513          	add	a0,a0,304 # 80006d50 <userret+0xcec>
    80001c28:	fffff097          	auipc	ra,0xfffff
    80001c2c:	fbe080e7          	jalr	-66(ra) # 80000be6 <printf>
                break;
    80001c30:	a005                	j	80001c50 <dump_pagetable+0x120>
    for(int i = 0; i < 512; i++) {
    80001c32:	fe842783          	lw	a5,-24(s0)
    80001c36:	2785                	addw	a5,a5,1
    80001c38:	fef42423          	sw	a5,-24(s0)
    80001c3c:	fe842783          	lw	a5,-24(s0)
    80001c40:	0007871b          	sext.w	a4,a5
    80001c44:	1ff00793          	li	a5,511
    80001c48:	f2e7d4e3          	bge	a5,a4,80001b70 <dump_pagetable+0x40>
    80001c4c:	a011                	j	80001c50 <dump_pagetable+0x120>
    if(level > 2) return;
    80001c4e:	0001                	nop
            }
        }
    }
}
    80001c50:	70a2                	ld	ra,40(sp)
    80001c52:	7402                	ld	s0,32(sp)
    80001c54:	6145                	add	sp,sp,48
    80001c56:	8082                	ret

0000000080001c58 <check_page_permission>:

// 权限检查
int check_page_permission(uint64 addr, int access_type) {
    80001c58:	7179                	add	sp,sp,-48
    80001c5a:	f406                	sd	ra,40(sp)
    80001c5c:	f022                	sd	s0,32(sp)
    80001c5e:	1800                	add	s0,sp,48
    80001c60:	fca43c23          	sd	a0,-40(s0)
    80001c64:	87ae                	mv	a5,a1
    80001c66:	fcf42a23          	sw	a5,-44(s0)
    pte_t *pte = walk_lookup(kernel_pagetable, addr);
    80001c6a:	00008797          	auipc	a5,0x8
    80001c6e:	39e78793          	add	a5,a5,926 # 8000a008 <kernel_pagetable>
    80001c72:	639c                	ld	a5,0(a5)
    80001c74:	fd843583          	ld	a1,-40(s0)
    80001c78:	853e                	mv	a0,a5
    80001c7a:	00000097          	auipc	ra,0x0
    80001c7e:	9ce080e7          	jalr	-1586(ra) # 80001648 <walk_lookup>
    80001c82:	fea43423          	sd	a0,-24(s0)
    
    if(pte == 0 || !(*pte & PTE_V)) {
    80001c86:	fe843783          	ld	a5,-24(s0)
    80001c8a:	c791                	beqz	a5,80001c96 <check_page_permission+0x3e>
    80001c8c:	fe843783          	ld	a5,-24(s0)
    80001c90:	639c                	ld	a5,0(a5)
    80001c92:	8b85                	and	a5,a5,1
    80001c94:	ef91                	bnez	a5,80001cb0 <check_page_permission+0x58>
        printf("Permission check: Address %p not mapped\n", (void*)addr);
    80001c96:	fd843783          	ld	a5,-40(s0)
    80001c9a:	85be                	mv	a1,a5
    80001c9c:	00005517          	auipc	a0,0x5
    80001ca0:	0cc50513          	add	a0,a0,204 # 80006d68 <userret+0xd04>
    80001ca4:	fffff097          	auipc	ra,0xfffff
    80001ca8:	f42080e7          	jalr	-190(ra) # 80000be6 <printf>
        return 0;
    80001cac:	4781                	li	a5,0
    80001cae:	a079                	j	80001d3c <check_page_permission+0xe4>
    }
    
    if((access_type & ACCESS_READ) && !(*pte & PTE_R)) {
    80001cb0:	fd442783          	lw	a5,-44(s0)
    80001cb4:	8b85                	and	a5,a5,1
    80001cb6:	2781                	sext.w	a5,a5
    80001cb8:	c39d                	beqz	a5,80001cde <check_page_permission+0x86>
    80001cba:	fe843783          	ld	a5,-24(s0)
    80001cbe:	639c                	ld	a5,0(a5)
    80001cc0:	8b89                	and	a5,a5,2
    80001cc2:	ef91                	bnez	a5,80001cde <check_page_permission+0x86>
        printf("Permission check: No read permission for %p\n", (void*)addr);
    80001cc4:	fd843783          	ld	a5,-40(s0)
    80001cc8:	85be                	mv	a1,a5
    80001cca:	00005517          	auipc	a0,0x5
    80001cce:	0ce50513          	add	a0,a0,206 # 80006d98 <userret+0xd34>
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	f14080e7          	jalr	-236(ra) # 80000be6 <printf>
        return 0;
    80001cda:	4781                	li	a5,0
    80001cdc:	a085                	j	80001d3c <check_page_permission+0xe4>
    }
    
    if((access_type & ACCESS_WRITE) && !(*pte & PTE_W)) {
    80001cde:	fd442783          	lw	a5,-44(s0)
    80001ce2:	8b89                	and	a5,a5,2
    80001ce4:	2781                	sext.w	a5,a5
    80001ce6:	c39d                	beqz	a5,80001d0c <check_page_permission+0xb4>
    80001ce8:	fe843783          	ld	a5,-24(s0)
    80001cec:	639c                	ld	a5,0(a5)
    80001cee:	8b91                	and	a5,a5,4
    80001cf0:	ef91                	bnez	a5,80001d0c <check_page_permission+0xb4>
        printf("Permission check: No write permission for %p\n", (void*)addr);
    80001cf2:	fd843783          	ld	a5,-40(s0)
    80001cf6:	85be                	mv	a1,a5
    80001cf8:	00005517          	auipc	a0,0x5
    80001cfc:	0d050513          	add	a0,a0,208 # 80006dc8 <userret+0xd64>
    80001d00:	fffff097          	auipc	ra,0xfffff
    80001d04:	ee6080e7          	jalr	-282(ra) # 80000be6 <printf>
        return 0;
    80001d08:	4781                	li	a5,0
    80001d0a:	a80d                	j	80001d3c <check_page_permission+0xe4>
    }
    
    if((access_type & ACCESS_EXEC) && !(*pte & PTE_X)) {
    80001d0c:	fd442783          	lw	a5,-44(s0)
    80001d10:	8b91                	and	a5,a5,4
    80001d12:	2781                	sext.w	a5,a5
    80001d14:	c39d                	beqz	a5,80001d3a <check_page_permission+0xe2>
    80001d16:	fe843783          	ld	a5,-24(s0)
    80001d1a:	639c                	ld	a5,0(a5)
    80001d1c:	8ba1                	and	a5,a5,8
    80001d1e:	ef91                	bnez	a5,80001d3a <check_page_permission+0xe2>
        printf("Permission check: No execute permission for %p\n", (void*)addr);
    80001d20:	fd843783          	ld	a5,-40(s0)
    80001d24:	85be                	mv	a1,a5
    80001d26:	00005517          	auipc	a0,0x5
    80001d2a:	0d250513          	add	a0,a0,210 # 80006df8 <userret+0xd94>
    80001d2e:	fffff097          	auipc	ra,0xfffff
    80001d32:	eb8080e7          	jalr	-328(ra) # 80000be6 <printf>
        return 0;
    80001d36:	4781                	li	a5,0
    80001d38:	a011                	j	80001d3c <check_page_permission+0xe4>
    }
    
    return 1;
    80001d3a:	4785                	li	a5,1
}
    80001d3c:	853e                	mv	a0,a5
    80001d3e:	70a2                	ld	ra,40(sp)
    80001d40:	7402                	ld	s0,32(sp)
    80001d42:	6145                	add	sp,sp,48
    80001d44:	8082                	ret

0000000080001d46 <copyin>:

// ==================== 用户空间拷贝函数 ====================

// 从用户空间拷贝到内核缓冲区
int copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
    80001d46:	715d                	add	sp,sp,-80
    80001d48:	e486                	sd	ra,72(sp)
    80001d4a:	e0a2                	sd	s0,64(sp)
    80001d4c:	0880                	add	s0,sp,80
    80001d4e:	fca43423          	sd	a0,-56(s0)
    80001d52:	fcb43023          	sd	a1,-64(s0)
    80001d56:	fac43c23          	sd	a2,-72(s0)
    80001d5a:	fad43823          	sd	a3,-80(s0)
    while(len > 0){
    80001d5e:	a0e1                	j	80001e26 <copyin+0xe0>
        uint64 va0 = PGROUNDDOWN(srcva);
    80001d60:	fb843703          	ld	a4,-72(s0)
    80001d64:	77fd                	lui	a5,0xfffff
    80001d66:	8ff9                	and	a5,a5,a4
    80001d68:	fef43023          	sd	a5,-32(s0)
        pte_t *pte = walk_lookup(pagetable, va0);
    80001d6c:	fe043583          	ld	a1,-32(s0)
    80001d70:	fc843503          	ld	a0,-56(s0)
    80001d74:	00000097          	auipc	ra,0x0
    80001d78:	8d4080e7          	jalr	-1836(ra) # 80001648 <walk_lookup>
    80001d7c:	fca43c23          	sd	a0,-40(s0)
        if(pte == 0 || (*pte & PTE_V) == 0 || (*pte & PTE_U) == 0)
    80001d80:	fd843783          	ld	a5,-40(s0)
    80001d84:	cb99                	beqz	a5,80001d9a <copyin+0x54>
    80001d86:	fd843783          	ld	a5,-40(s0)
    80001d8a:	639c                	ld	a5,0(a5)
    80001d8c:	8b85                	and	a5,a5,1
    80001d8e:	c791                	beqz	a5,80001d9a <copyin+0x54>
    80001d90:	fd843783          	ld	a5,-40(s0)
    80001d94:	639c                	ld	a5,0(a5)
    80001d96:	8bc1                	and	a5,a5,16
    80001d98:	e399                	bnez	a5,80001d9e <copyin+0x58>
            return -1;
    80001d9a:	57fd                	li	a5,-1
    80001d9c:	a849                	j	80001e2e <copyin+0xe8>
        uint64 pa0 = PTE_PA(*pte);
    80001d9e:	fd843783          	ld	a5,-40(s0)
    80001da2:	639c                	ld	a5,0(a5)
    80001da4:	83a9                	srl	a5,a5,0xa
    80001da6:	07b2                	sll	a5,a5,0xc
    80001da8:	fcf43823          	sd	a5,-48(s0)

        uint64 n = PGSIZE - (srcva - va0);
    80001dac:	fe043703          	ld	a4,-32(s0)
    80001db0:	fb843783          	ld	a5,-72(s0)
    80001db4:	8f1d                	sub	a4,a4,a5
    80001db6:	6785                	lui	a5,0x1
    80001db8:	97ba                	add	a5,a5,a4
    80001dba:	fef43423          	sd	a5,-24(s0)
        if(n > len)
    80001dbe:	fe843703          	ld	a4,-24(s0)
    80001dc2:	fb043783          	ld	a5,-80(s0)
    80001dc6:	00e7f663          	bgeu	a5,a4,80001dd2 <copyin+0x8c>
            n = len;
    80001dca:	fb043783          	ld	a5,-80(s0)
    80001dce:	fef43423          	sd	a5,-24(s0)

        memcpy(dst, (void*)(pa0 + (srcva - va0)), n);
    80001dd2:	fb843703          	ld	a4,-72(s0)
    80001dd6:	fe043783          	ld	a5,-32(s0)
    80001dda:	8f1d                	sub	a4,a4,a5
    80001ddc:	fd043783          	ld	a5,-48(s0)
    80001de0:	97ba                	add	a5,a5,a4
    80001de2:	873e                	mv	a4,a5
    80001de4:	fe843783          	ld	a5,-24(s0)
    80001de8:	2781                	sext.w	a5,a5
    80001dea:	863e                	mv	a2,a5
    80001dec:	85ba                	mv	a1,a4
    80001dee:	fc043503          	ld	a0,-64(s0)
    80001df2:	fffff097          	auipc	ra,0xfffff
    80001df6:	37c080e7          	jalr	892(ra) # 8000116e <memcpy>

        len   -= n;
    80001dfa:	fb043703          	ld	a4,-80(s0)
    80001dfe:	fe843783          	ld	a5,-24(s0)
    80001e02:	40f707b3          	sub	a5,a4,a5
    80001e06:	faf43823          	sd	a5,-80(s0)
        dst   += n;
    80001e0a:	fc043703          	ld	a4,-64(s0)
    80001e0e:	fe843783          	ld	a5,-24(s0)
    80001e12:	97ba                	add	a5,a5,a4
    80001e14:	fcf43023          	sd	a5,-64(s0)
        srcva += n;
    80001e18:	fb843703          	ld	a4,-72(s0)
    80001e1c:	fe843783          	ld	a5,-24(s0)
    80001e20:	97ba                	add	a5,a5,a4
    80001e22:	faf43c23          	sd	a5,-72(s0)
    while(len > 0){
    80001e26:	fb043783          	ld	a5,-80(s0)
    80001e2a:	fb9d                	bnez	a5,80001d60 <copyin+0x1a>
    }
    return 0;
    80001e2c:	4781                	li	a5,0
}
    80001e2e:	853e                	mv	a0,a5
    80001e30:	60a6                	ld	ra,72(sp)
    80001e32:	6406                	ld	s0,64(sp)
    80001e34:	6161                	add	sp,sp,80
    80001e36:	8082                	ret

0000000080001e38 <copyout>:

// 从内核缓冲区拷贝到用户空间
int copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
    80001e38:	715d                	add	sp,sp,-80
    80001e3a:	e486                	sd	ra,72(sp)
    80001e3c:	e0a2                	sd	s0,64(sp)
    80001e3e:	0880                	add	s0,sp,80
    80001e40:	fca43423          	sd	a0,-56(s0)
    80001e44:	fcb43023          	sd	a1,-64(s0)
    80001e48:	fac43c23          	sd	a2,-72(s0)
    80001e4c:	fad43823          	sd	a3,-80(s0)
    while(len > 0){
    80001e50:	a0e1                	j	80001f18 <copyout+0xe0>
        uint64 va0 = PGROUNDDOWN(dstva);
    80001e52:	fc043703          	ld	a4,-64(s0)
    80001e56:	77fd                	lui	a5,0xfffff
    80001e58:	8ff9                	and	a5,a5,a4
    80001e5a:	fef43023          	sd	a5,-32(s0)
        pte_t *pte = walk_lookup(pagetable, va0);
    80001e5e:	fe043583          	ld	a1,-32(s0)
    80001e62:	fc843503          	ld	a0,-56(s0)
    80001e66:	fffff097          	auipc	ra,0xfffff
    80001e6a:	7e2080e7          	jalr	2018(ra) # 80001648 <walk_lookup>
    80001e6e:	fca43c23          	sd	a0,-40(s0)
        if(pte == 0 || (*pte & PTE_V) == 0 || (*pte & PTE_U) == 0)
    80001e72:	fd843783          	ld	a5,-40(s0)
    80001e76:	cb99                	beqz	a5,80001e8c <copyout+0x54>
    80001e78:	fd843783          	ld	a5,-40(s0)
    80001e7c:	639c                	ld	a5,0(a5)
    80001e7e:	8b85                	and	a5,a5,1
    80001e80:	c791                	beqz	a5,80001e8c <copyout+0x54>
    80001e82:	fd843783          	ld	a5,-40(s0)
    80001e86:	639c                	ld	a5,0(a5)
    80001e88:	8bc1                	and	a5,a5,16
    80001e8a:	e399                	bnez	a5,80001e90 <copyout+0x58>
            return -1;
    80001e8c:	57fd                	li	a5,-1
    80001e8e:	a849                	j	80001f20 <copyout+0xe8>
        uint64 pa0 = PTE_PA(*pte);
    80001e90:	fd843783          	ld	a5,-40(s0)
    80001e94:	639c                	ld	a5,0(a5)
    80001e96:	83a9                	srl	a5,a5,0xa
    80001e98:	07b2                	sll	a5,a5,0xc
    80001e9a:	fcf43823          	sd	a5,-48(s0)

        uint64 n = PGSIZE - (dstva - va0);
    80001e9e:	fe043703          	ld	a4,-32(s0)
    80001ea2:	fc043783          	ld	a5,-64(s0)
    80001ea6:	8f1d                	sub	a4,a4,a5
    80001ea8:	6785                	lui	a5,0x1
    80001eaa:	97ba                	add	a5,a5,a4
    80001eac:	fef43423          	sd	a5,-24(s0)
        if(n > len)
    80001eb0:	fe843703          	ld	a4,-24(s0)
    80001eb4:	fb043783          	ld	a5,-80(s0)
    80001eb8:	00e7f663          	bgeu	a5,a4,80001ec4 <copyout+0x8c>
            n = len;
    80001ebc:	fb043783          	ld	a5,-80(s0)
    80001ec0:	fef43423          	sd	a5,-24(s0)

        memcpy((void*)(pa0 + (dstva - va0)), src, n);
    80001ec4:	fc043703          	ld	a4,-64(s0)
    80001ec8:	fe043783          	ld	a5,-32(s0)
    80001ecc:	8f1d                	sub	a4,a4,a5
    80001ece:	fd043783          	ld	a5,-48(s0)
    80001ed2:	97ba                	add	a5,a5,a4
    80001ed4:	873e                	mv	a4,a5
    80001ed6:	fe843783          	ld	a5,-24(s0)
    80001eda:	2781                	sext.w	a5,a5
    80001edc:	863e                	mv	a2,a5
    80001ede:	fb843583          	ld	a1,-72(s0)
    80001ee2:	853a                	mv	a0,a4
    80001ee4:	fffff097          	auipc	ra,0xfffff
    80001ee8:	28a080e7          	jalr	650(ra) # 8000116e <memcpy>

        len   -= n;
    80001eec:	fb043703          	ld	a4,-80(s0)
    80001ef0:	fe843783          	ld	a5,-24(s0)
    80001ef4:	40f707b3          	sub	a5,a4,a5
    80001ef8:	faf43823          	sd	a5,-80(s0)
        src   += n;
    80001efc:	fb843703          	ld	a4,-72(s0)
    80001f00:	fe843783          	ld	a5,-24(s0)
    80001f04:	97ba                	add	a5,a5,a4
    80001f06:	faf43c23          	sd	a5,-72(s0)
        dstva += n;
    80001f0a:	fc043703          	ld	a4,-64(s0)
    80001f0e:	fe843783          	ld	a5,-24(s0)
    80001f12:	97ba                	add	a5,a5,a4
    80001f14:	fcf43023          	sd	a5,-64(s0)
    while(len > 0){
    80001f18:	fb043783          	ld	a5,-80(s0)
    80001f1c:	fb9d                	bnez	a5,80001e52 <copyout+0x1a>
    }
    return 0;
    80001f1e:	4781                	li	a5,0
}
    80001f20:	853e                	mv	a0,a5
    80001f22:	60a6                	ld	ra,72(sp)
    80001f24:	6406                	ld	s0,64(sp)
    80001f26:	6161                	add	sp,sp,80
    80001f28:	8082                	ret

0000000080001f2a <proc_pagetable>:

// ==================== 用户页表管理 ====================

// 为进程创建用户页表
pagetable_t proc_pagetable(struct proc *p)
{
    80001f2a:	7179                	add	sp,sp,-48
    80001f2c:	f406                	sd	ra,40(sp)
    80001f2e:	f022                	sd	s0,32(sp)
    80001f30:	1800                	add	s0,sp,48
    80001f32:	fca43c23          	sd	a0,-40(s0)
    pagetable_t pagetable;
    
    pagetable = create_pagetable();
    80001f36:	fffff097          	auipc	ra,0xfffff
    80001f3a:	62e080e7          	jalr	1582(ra) # 80001564 <create_pagetable>
    80001f3e:	fea43423          	sd	a0,-24(s0)
    if(pagetable == 0)
    80001f42:	fe843783          	ld	a5,-24(s0)
    80001f46:	e399                	bnez	a5,80001f4c <proc_pagetable+0x22>
        return 0;
    80001f48:	4781                	li	a5,0
    80001f4a:	a251                	j	800020ce <proc_pagetable+0x1a4>
    
    // 映射 trampoline
    extern char trampoline[];
    printf("[DEBUG] proc_pagetable: trampoline phys=%p\n", (void*)trampoline);
    80001f4c:	00004597          	auipc	a1,0x4
    80001f50:	0b458593          	add	a1,a1,180 # 80006000 <etext>
    80001f54:	00005517          	auipc	a0,0x5
    80001f58:	ed450513          	add	a0,a0,-300 # 80006e28 <userret+0xdc4>
    80001f5c:	fffff097          	auipc	ra,0xfffff
    80001f60:	c8a080e7          	jalr	-886(ra) # 80000be6 <printf>
    printf("[DEBUG] proc_pagetable: TRAMPOLINE virt=%p\n", (void*)TRAMPOLINE);
    80001f64:	040007b7          	lui	a5,0x4000
    80001f68:	17fd                	add	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80001f6a:	00c79593          	sll	a1,a5,0xc
    80001f6e:	00005517          	auipc	a0,0x5
    80001f72:	eea50513          	add	a0,a0,-278 # 80006e58 <userret+0xdf4>
    80001f76:	fffff097          	auipc	ra,0xfffff
    80001f7a:	c70080e7          	jalr	-912(ra) # 80000be6 <printf>
    
    if(map_page(pagetable, TRAMPOLINE, (uint64)trampoline,
    80001f7e:	00004797          	auipc	a5,0x4
    80001f82:	08278793          	add	a5,a5,130 # 80006000 <etext>
    80001f86:	46a9                	li	a3,10
    80001f88:	863e                	mv	a2,a5
    80001f8a:	040007b7          	lui	a5,0x4000
    80001f8e:	17fd                	add	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80001f90:	00c79593          	sll	a1,a5,0xc
    80001f94:	fe843503          	ld	a0,-24(s0)
    80001f98:	00000097          	auipc	ra,0x0
    80001f9c:	834080e7          	jalr	-1996(ra) # 800017cc <map_page>
    80001fa0:	87aa                	mv	a5,a0
    80001fa2:	c38d                	beqz	a5,80001fc4 <proc_pagetable+0x9a>
                PTE_R | PTE_X) != 0) {
        printf("[ERROR] Failed to map trampoline\n");
    80001fa4:	00005517          	auipc	a0,0x5
    80001fa8:	ee450513          	add	a0,a0,-284 # 80006e88 <userret+0xe24>
    80001fac:	fffff097          	auipc	ra,0xfffff
    80001fb0:	c3a080e7          	jalr	-966(ra) # 80000be6 <printf>
        destroy_pagetable(pagetable);
    80001fb4:	fe843503          	ld	a0,-24(s0)
    80001fb8:	fffff097          	auipc	ra,0xfffff
    80001fbc:	666080e7          	jalr	1638(ra) # 8000161e <destroy_pagetable>
        return 0;
    80001fc0:	4781                	li	a5,0
    80001fc2:	a231                	j	800020ce <proc_pagetable+0x1a4>
    }
    
    // 验证映射是否成功
    pte_t *pte = walk_lookup(pagetable, TRAMPOLINE);
    80001fc4:	040007b7          	lui	a5,0x4000
    80001fc8:	17fd                	add	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80001fca:	00c79593          	sll	a1,a5,0xc
    80001fce:	fe843503          	ld	a0,-24(s0)
    80001fd2:	fffff097          	auipc	ra,0xfffff
    80001fd6:	676080e7          	jalr	1654(ra) # 80001648 <walk_lookup>
    80001fda:	fea43023          	sd	a0,-32(s0)
    if(pte == 0 || (*pte & PTE_V) == 0) {
    80001fde:	fe043783          	ld	a5,-32(s0)
    80001fe2:	c791                	beqz	a5,80001fee <proc_pagetable+0xc4>
    80001fe4:	fe043783          	ld	a5,-32(s0)
    80001fe8:	639c                	ld	a5,0(a5)
    80001fea:	8b85                	and	a5,a5,1
    80001fec:	e38d                	bnez	a5,8000200e <proc_pagetable+0xe4>
        printf("[ERROR] Trampoline not mapped correctly!\n");
    80001fee:	00005517          	auipc	a0,0x5
    80001ff2:	ec250513          	add	a0,a0,-318 # 80006eb0 <userret+0xe4c>
    80001ff6:	fffff097          	auipc	ra,0xfffff
    80001ffa:	bf0080e7          	jalr	-1040(ra) # 80000be6 <printf>
        destroy_pagetable(pagetable);
    80001ffe:	fe843503          	ld	a0,-24(s0)
    80002002:	fffff097          	auipc	ra,0xfffff
    80002006:	61c080e7          	jalr	1564(ra) # 8000161e <destroy_pagetable>
        return 0;
    8000200a:	4781                	li	a5,0
    8000200c:	a0c9                	j	800020ce <proc_pagetable+0x1a4>
    }
    printf("[DEBUG] Trampoline PTE: %p (flags: %s%s%s%s)\n",
           (void*)*pte,
    8000200e:	fe043783          	ld	a5,-32(s0)
    80002012:	639c                	ld	a5,0(a5)
    printf("[DEBUG] Trampoline PTE: %p (flags: %s%s%s%s)\n",
    80002014:	85be                	mv	a1,a5
           (*pte & PTE_V) ? "V" : "-",
    80002016:	fe043783          	ld	a5,-32(s0)
    8000201a:	639c                	ld	a5,0(a5)
    8000201c:	8b85                	and	a5,a5,1
    printf("[DEBUG] Trampoline PTE: %p (flags: %s%s%s%s)\n",
    8000201e:	c791                	beqz	a5,8000202a <proc_pagetable+0x100>
    80002020:	00005617          	auipc	a2,0x5
    80002024:	ec060613          	add	a2,a2,-320 # 80006ee0 <userret+0xe7c>
    80002028:	a029                	j	80002032 <proc_pagetable+0x108>
    8000202a:	00005617          	auipc	a2,0x5
    8000202e:	ebe60613          	add	a2,a2,-322 # 80006ee8 <userret+0xe84>
           (*pte & PTE_R) ? "R" : "-",
    80002032:	fe043783          	ld	a5,-32(s0)
    80002036:	639c                	ld	a5,0(a5)
    80002038:	8b89                	and	a5,a5,2
    printf("[DEBUG] Trampoline PTE: %p (flags: %s%s%s%s)\n",
    8000203a:	c791                	beqz	a5,80002046 <proc_pagetable+0x11c>
    8000203c:	00005697          	auipc	a3,0x5
    80002040:	eb468693          	add	a3,a3,-332 # 80006ef0 <userret+0xe8c>
    80002044:	a029                	j	8000204e <proc_pagetable+0x124>
    80002046:	00005697          	auipc	a3,0x5
    8000204a:	ea268693          	add	a3,a3,-350 # 80006ee8 <userret+0xe84>
           (*pte & PTE_W) ? "W" : "-",
    8000204e:	fe043783          	ld	a5,-32(s0)
    80002052:	639c                	ld	a5,0(a5)
    80002054:	8b91                	and	a5,a5,4
    printf("[DEBUG] Trampoline PTE: %p (flags: %s%s%s%s)\n",
    80002056:	c791                	beqz	a5,80002062 <proc_pagetable+0x138>
    80002058:	00005717          	auipc	a4,0x5
    8000205c:	ea070713          	add	a4,a4,-352 # 80006ef8 <userret+0xe94>
    80002060:	a029                	j	8000206a <proc_pagetable+0x140>
    80002062:	00005717          	auipc	a4,0x5
    80002066:	e8670713          	add	a4,a4,-378 # 80006ee8 <userret+0xe84>
           (*pte & PTE_X) ? "X" : "-");
    8000206a:	fe043783          	ld	a5,-32(s0)
    8000206e:	639c                	ld	a5,0(a5)
    80002070:	8ba1                	and	a5,a5,8
    printf("[DEBUG] Trampoline PTE: %p (flags: %s%s%s%s)\n",
    80002072:	c791                	beqz	a5,8000207e <proc_pagetable+0x154>
    80002074:	00005797          	auipc	a5,0x5
    80002078:	e8c78793          	add	a5,a5,-372 # 80006f00 <userret+0xe9c>
    8000207c:	a029                	j	80002086 <proc_pagetable+0x15c>
    8000207e:	00005797          	auipc	a5,0x5
    80002082:	e6a78793          	add	a5,a5,-406 # 80006ee8 <userret+0xe84>
    80002086:	00005517          	auipc	a0,0x5
    8000208a:	e8250513          	add	a0,a0,-382 # 80006f08 <userret+0xea4>
    8000208e:	fffff097          	auipc	ra,0xfffff
    80002092:	b58080e7          	jalr	-1192(ra) # 80000be6 <printf>
    
    // 映射 trapframe
    if(map_page(pagetable, TRAPFRAME, (uint64)p->trapframe,
    80002096:	fd843783          	ld	a5,-40(s0)
    8000209a:	6bdc                	ld	a5,144(a5)
    8000209c:	4699                	li	a3,6
    8000209e:	863e                	mv	a2,a5
    800020a0:	020007b7          	lui	a5,0x2000
    800020a4:	17fd                	add	a5,a5,-1 # 1ffffff <_entry-0x7e000001>
    800020a6:	00d79593          	sll	a1,a5,0xd
    800020aa:	fe843503          	ld	a0,-24(s0)
    800020ae:	fffff097          	auipc	ra,0xfffff
    800020b2:	71e080e7          	jalr	1822(ra) # 800017cc <map_page>
    800020b6:	87aa                	mv	a5,a0
    800020b8:	cb89                	beqz	a5,800020ca <proc_pagetable+0x1a0>
                PTE_R | PTE_W) != 0) {
        destroy_pagetable(pagetable);
    800020ba:	fe843503          	ld	a0,-24(s0)
    800020be:	fffff097          	auipc	ra,0xfffff
    800020c2:	560080e7          	jalr	1376(ra) # 8000161e <destroy_pagetable>
        return 0;
    800020c6:	4781                	li	a5,0
    800020c8:	a019                	j	800020ce <proc_pagetable+0x1a4>
    }
    
    return pagetable;
    800020ca:	fe843783          	ld	a5,-24(s0)
}
    800020ce:	853e                	mv	a0,a5
    800020d0:	70a2                	ld	ra,40(sp)
    800020d2:	7402                	ld	s0,32(sp)
    800020d4:	6145                	add	sp,sp,48
    800020d6:	8082                	ret

00000000800020d8 <proc_freepagetable>:

// 释放进程的用户页表
void proc_freepagetable(pagetable_t pagetable, uint64 size)
{
    800020d8:	1101                	add	sp,sp,-32
    800020da:	ec06                	sd	ra,24(sp)
    800020dc:	e822                	sd	s0,16(sp)
    800020de:	1000                	add	s0,sp,32
    800020e0:	fea43423          	sd	a0,-24(s0)
    800020e4:	feb43023          	sd	a1,-32(s0)
    
    // 释放用户代码和数据页
    // TODO: 遍历页表释放用户页
    
    // 释放页表本身
    destroy_pagetable(pagetable);
    800020e8:	fe843503          	ld	a0,-24(s0)
    800020ec:	fffff097          	auipc	ra,0xfffff
    800020f0:	532080e7          	jalr	1330(ra) # 8000161e <destroy_pagetable>
}
    800020f4:	0001                	nop
    800020f6:	60e2                	ld	ra,24(sp)
    800020f8:	6442                	ld	s0,16(sp)
    800020fa:	6105                	add	sp,sp,32
    800020fc:	8082                	ret

00000000800020fe <test_multilevel_pagetable>:
#include "mm.h"
#include "defs.h"
#include "riscv.h"

// ==================== 多级页表映射测试 ====================
void test_multilevel_pagetable(void) {
    800020fe:	711d                	add	sp,sp,-96
    80002100:	ec86                	sd	ra,88(sp)
    80002102:	e8a2                	sd	s0,80(sp)
    80002104:	1080                	add	s0,sp,96
    printf("=== Testing Multi-level Page Table ===\n");
    80002106:	00005517          	auipc	a0,0x5
    8000210a:	e3250513          	add	a0,a0,-462 # 80006f38 <userret+0xed4>
    8000210e:	fffff097          	auipc	ra,0xfffff
    80002112:	ad8080e7          	jalr	-1320(ra) # 80000be6 <printf>
    
    pagetable_t pt = create_pagetable();
    80002116:	fffff097          	auipc	ra,0xfffff
    8000211a:	44e080e7          	jalr	1102(ra) # 80001564 <create_pagetable>
    8000211e:	fea43023          	sd	a0,-32(s0)
    if(pt == 0) {
    80002122:	fe043783          	ld	a5,-32(s0)
    80002126:	eb91                	bnez	a5,8000213a <test_multilevel_pagetable+0x3c>
        printf("ERROR: create_pagetable failed\n");
    80002128:	00005517          	auipc	a0,0x5
    8000212c:	e3850513          	add	a0,a0,-456 # 80006f60 <userret+0xefc>
    80002130:	fffff097          	auipc	ra,0xfffff
    80002134:	ab6080e7          	jalr	-1354(ra) # 80000be6 <printf>
    80002138:	aa59                	j	800022ce <test_multilevel_pagetable+0x1d0>
        return;
    }
    
    // 测试地址数组
    uint64 test_vas[] = {
    8000213a:	00005797          	auipc	a5,0x5
    8000213e:	f6e78793          	add	a5,a5,-146 # 800070a8 <userret+0x1044>
    80002142:	6390                	ld	a2,0(a5)
    80002144:	6794                	ld	a3,8(a5)
    80002146:	6b98                	ld	a4,16(a5)
    80002148:	6f9c                	ld	a5,24(a5)
    8000214a:	fac43423          	sd	a2,-88(s0)
    8000214e:	fad43823          	sd	a3,-80(s0)
    80002152:	fae43c23          	sd	a4,-72(s0)
    80002156:	fcf43023          	sd	a5,-64(s0)
        0x200000,       // 2MB
        0x40000000,     // 1GB
        0x7000000000,   // 接近39位限制
    };
    
    for(int i = 0; i < 4; i++) {
    8000215a:	fe042623          	sw	zero,-20(s0)
    8000215e:	a299                	j	800022a4 <test_multilevel_pagetable+0x1a6>
        uint64 va = test_vas[i];
    80002160:	fec42783          	lw	a5,-20(s0)
    80002164:	078e                	sll	a5,a5,0x3
    80002166:	17c1                	add	a5,a5,-16
    80002168:	97a2                	add	a5,a5,s0
    8000216a:	fb87b783          	ld	a5,-72(a5)
    8000216e:	fcf43c23          	sd	a5,-40(s0)
        
        // Sv39地址空间边界检查
        if(va >= (1L << 39)) {
    80002172:	fd843703          	ld	a4,-40(s0)
    80002176:	57fd                	li	a5,-1
    80002178:	83e5                	srl	a5,a5,0x19
    8000217a:	02e7f163          	bgeu	a5,a4,8000219c <test_multilevel_pagetable+0x9e>
            printf("Test %d: VA %p exceeds Sv39 limit, skipping\n", i, (void*)va);
    8000217e:	fd843703          	ld	a4,-40(s0)
    80002182:	fec42783          	lw	a5,-20(s0)
    80002186:	863a                	mv	a2,a4
    80002188:	85be                	mv	a1,a5
    8000218a:	00005517          	auipc	a0,0x5
    8000218e:	df650513          	add	a0,a0,-522 # 80006f80 <userret+0xf1c>
    80002192:	fffff097          	auipc	ra,0xfffff
    80002196:	a54080e7          	jalr	-1452(ra) # 80000be6 <printf>
            continue;
    8000219a:	a201                	j	8000229a <test_multilevel_pagetable+0x19c>
        }
        
        // 分配物理页面
        uint64 pa = (uint64)alloc_page();
    8000219c:	fffff097          	auipc	ra,0xfffff
    800021a0:	14c080e7          	jalr	332(ra) # 800012e8 <alloc_page>
    800021a4:	87aa                	mv	a5,a0
    800021a6:	fcf43823          	sd	a5,-48(s0)
        if(pa == 0) {
    800021aa:	fd043783          	ld	a5,-48(s0)
    800021ae:	ef89                	bnez	a5,800021c8 <test_multilevel_pagetable+0xca>
            printf("ERROR: alloc_page failed for test %d\n", i);
    800021b0:	fec42783          	lw	a5,-20(s0)
    800021b4:	85be                	mv	a1,a5
    800021b6:	00005517          	auipc	a0,0x5
    800021ba:	dfa50513          	add	a0,a0,-518 # 80006fb0 <userret+0xf4c>
    800021be:	fffff097          	auipc	ra,0xfffff
    800021c2:	a28080e7          	jalr	-1496(ra) # 80000be6 <printf>
            continue;
    800021c6:	a8d1                	j	8000229a <test_multilevel_pagetable+0x19c>
        }
        
        printf("Test %d: mapping VA %p to PA %p\n", i, (void*)va, (void*)pa);
    800021c8:	fd843703          	ld	a4,-40(s0)
    800021cc:	fd043683          	ld	a3,-48(s0)
    800021d0:	fec42783          	lw	a5,-20(s0)
    800021d4:	863a                	mv	a2,a4
    800021d6:	85be                	mv	a1,a5
    800021d8:	00005517          	auipc	a0,0x5
    800021dc:	e0050513          	add	a0,a0,-512 # 80006fd8 <userret+0xf74>
    800021e0:	fffff097          	auipc	ra,0xfffff
    800021e4:	a06080e7          	jalr	-1530(ra) # 80000be6 <printf>
        
        // 建立映射
        if(map_page(pt, va, pa, PTE_R | PTE_W | PTE_X) != 0) {
    800021e8:	46b9                	li	a3,14
    800021ea:	fd043603          	ld	a2,-48(s0)
    800021ee:	fd843583          	ld	a1,-40(s0)
    800021f2:	fe043503          	ld	a0,-32(s0)
    800021f6:	fffff097          	auipc	ra,0xfffff
    800021fa:	5d6080e7          	jalr	1494(ra) # 800017cc <map_page>
    800021fe:	87aa                	mv	a5,a0
    80002200:	c785                	beqz	a5,80002228 <test_multilevel_pagetable+0x12a>
            printf("ERROR: map_page failed for test %d\n", i);
    80002202:	fec42783          	lw	a5,-20(s0)
    80002206:	85be                	mv	a1,a5
    80002208:	00005517          	auipc	a0,0x5
    8000220c:	df850513          	add	a0,a0,-520 # 80007000 <userret+0xf9c>
    80002210:	fffff097          	auipc	ra,0xfffff
    80002214:	9d6080e7          	jalr	-1578(ra) # 80000be6 <printf>
            free_page((void*)pa);
    80002218:	fd043783          	ld	a5,-48(s0)
    8000221c:	853e                	mv	a0,a5
    8000221e:	fffff097          	auipc	ra,0xfffff
    80002222:	12c080e7          	jalr	300(ra) # 8000134a <free_page>
            continue;
    80002226:	a895                	j	8000229a <test_multilevel_pagetable+0x19c>
        }
        
        // 验证映射
        pte_t *pte = walk_lookup(pt, va);
    80002228:	fd843583          	ld	a1,-40(s0)
    8000222c:	fe043503          	ld	a0,-32(s0)
    80002230:	fffff097          	auipc	ra,0xfffff
    80002234:	418080e7          	jalr	1048(ra) # 80001648 <walk_lookup>
    80002238:	fca43423          	sd	a0,-56(s0)
        if(pte == 0 || !(*pte & PTE_V) || PTE_PA(*pte) != pa) {
    8000223c:	fc843783          	ld	a5,-56(s0)
    80002240:	cf99                	beqz	a5,8000225e <test_multilevel_pagetable+0x160>
    80002242:	fc843783          	ld	a5,-56(s0)
    80002246:	639c                	ld	a5,0(a5)
    80002248:	8b85                	and	a5,a5,1
    8000224a:	cb91                	beqz	a5,8000225e <test_multilevel_pagetable+0x160>
    8000224c:	fc843783          	ld	a5,-56(s0)
    80002250:	639c                	ld	a5,0(a5)
    80002252:	83a9                	srl	a5,a5,0xa
    80002254:	07b2                	sll	a5,a5,0xc
    80002256:	fd043703          	ld	a4,-48(s0)
    8000225a:	00f70e63          	beq	a4,a5,80002276 <test_multilevel_pagetable+0x178>
            printf("ERROR: mapping verification failed for test %d\n", i);
    8000225e:	fec42783          	lw	a5,-20(s0)
    80002262:	85be                	mv	a1,a5
    80002264:	00005517          	auipc	a0,0x5
    80002268:	dc450513          	add	a0,a0,-572 # 80007028 <userret+0xfc4>
    8000226c:	fffff097          	auipc	ra,0xfffff
    80002270:	97a080e7          	jalr	-1670(ra) # 80000be6 <printf>
    80002274:	a821                	j	8000228c <test_multilevel_pagetable+0x18e>
        } else {
            printf("Test %d: mapping verification PASSED\n", i);
    80002276:	fec42783          	lw	a5,-20(s0)
    8000227a:	85be                	mv	a1,a5
    8000227c:	00005517          	auipc	a0,0x5
    80002280:	ddc50513          	add	a0,a0,-548 # 80007058 <userret+0xff4>
    80002284:	fffff097          	auipc	ra,0xfffff
    80002288:	962080e7          	jalr	-1694(ra) # 80000be6 <printf>
        }
        
        // 清理
        free_page((void*)pa);
    8000228c:	fd043783          	ld	a5,-48(s0)
    80002290:	853e                	mv	a0,a5
    80002292:	fffff097          	auipc	ra,0xfffff
    80002296:	0b8080e7          	jalr	184(ra) # 8000134a <free_page>
    for(int i = 0; i < 4; i++) {
    8000229a:	fec42783          	lw	a5,-20(s0)
    8000229e:	2785                	addw	a5,a5,1
    800022a0:	fef42623          	sw	a5,-20(s0)
    800022a4:	fec42783          	lw	a5,-20(s0)
    800022a8:	0007871b          	sext.w	a4,a5
    800022ac:	478d                	li	a5,3
    800022ae:	eae7d9e3          	bge	a5,a4,80002160 <test_multilevel_pagetable+0x62>
    }
    
    // 清理页表
    destroy_pagetable(pt);
    800022b2:	fe043503          	ld	a0,-32(s0)
    800022b6:	fffff097          	auipc	ra,0xfffff
    800022ba:	368080e7          	jalr	872(ra) # 8000161e <destroy_pagetable>
    printf("Multi-level page table test completed\n\n");
    800022be:	00005517          	auipc	a0,0x5
    800022c2:	dc250513          	add	a0,a0,-574 # 80007080 <userret+0x101c>
    800022c6:	fffff097          	auipc	ra,0xfffff
    800022ca:	920080e7          	jalr	-1760(ra) # 80000be6 <printf>
}
    800022ce:	60e6                	ld	ra,88(sp)
    800022d0:	6446                	ld	s0,80(sp)
    800022d2:	6125                	add	sp,sp,96
    800022d4:	8082                	ret

00000000800022d6 <test_edge_cases>:

// ==================== 边界条件测试 ====================
void test_edge_cases(void) {
    800022d6:	cb010113          	add	sp,sp,-848
    800022da:	34113423          	sd	ra,840(sp)
    800022de:	34813023          	sd	s0,832(sp)
    800022e2:	0e80                	add	s0,sp,848
    printf("=== Testing Edge Cases ===\n");
    800022e4:	00005517          	auipc	a0,0x5
    800022e8:	de450513          	add	a0,a0,-540 # 800070c8 <userret+0x1064>
    800022ec:	fffff097          	auipc	ra,0xfffff
    800022f0:	8fa080e7          	jalr	-1798(ra) # 80000be6 <printf>
    
    // 测试内存耗尽
    printf("Testing memory exhaustion...\n");
    800022f4:	00005517          	auipc	a0,0x5
    800022f8:	df450513          	add	a0,a0,-524 # 800070e8 <userret+0x1084>
    800022fc:	fffff097          	auipc	ra,0xfffff
    80002300:	8ea080e7          	jalr	-1814(ra) # 80000be6 <printf>
    void *pages[100];
    int allocated = 0;
    80002304:	fe042623          	sw	zero,-20(s0)
    
    for(int i = 0; i < 100; i++) {
    80002308:	fe042423          	sw	zero,-24(s0)
    8000230c:	a899                	j	80002362 <test_edge_cases+0x8c>
        pages[i] = alloc_page();
    8000230e:	fffff097          	auipc	ra,0xfffff
    80002312:	fda080e7          	jalr	-38(ra) # 800012e8 <alloc_page>
    80002316:	872a                	mv	a4,a0
    80002318:	fe842783          	lw	a5,-24(s0)
    8000231c:	078e                	sll	a5,a5,0x3
    8000231e:	17c1                	add	a5,a5,-16
    80002320:	97a2                	add	a5,a5,s0
    80002322:	cce7b023          	sd	a4,-832(a5)
        if(pages[i] == 0) {
    80002326:	fe842783          	lw	a5,-24(s0)
    8000232a:	078e                	sll	a5,a5,0x3
    8000232c:	17c1                	add	a5,a5,-16
    8000232e:	97a2                	add	a5,a5,s0
    80002330:	cc07b783          	ld	a5,-832(a5)
    80002334:	ef89                	bnez	a5,8000234e <test_edge_cases+0x78>
            printf("Memory exhausted after %d pages\n", i);
    80002336:	fe842783          	lw	a5,-24(s0)
    8000233a:	85be                	mv	a1,a5
    8000233c:	00005517          	auipc	a0,0x5
    80002340:	dcc50513          	add	a0,a0,-564 # 80007108 <userret+0x10a4>
    80002344:	fffff097          	auipc	ra,0xfffff
    80002348:	8a2080e7          	jalr	-1886(ra) # 80000be6 <printf>
            break;
    8000234c:	a01d                	j	80002372 <test_edge_cases+0x9c>
        }
        allocated++;
    8000234e:	fec42783          	lw	a5,-20(s0)
    80002352:	2785                	addw	a5,a5,1
    80002354:	fef42623          	sw	a5,-20(s0)
    for(int i = 0; i < 100; i++) {
    80002358:	fe842783          	lw	a5,-24(s0)
    8000235c:	2785                	addw	a5,a5,1
    8000235e:	fef42423          	sw	a5,-24(s0)
    80002362:	fe842783          	lw	a5,-24(s0)
    80002366:	0007871b          	sext.w	a4,a5
    8000236a:	06300793          	li	a5,99
    8000236e:	fae7d0e3          	bge	a5,a4,8000230e <test_edge_cases+0x38>
    }
    
    // 释放所有页面
    for(int i = 0; i < allocated; i++) {
    80002372:	fe042223          	sw	zero,-28(s0)
    80002376:	a015                	j	8000239a <test_edge_cases+0xc4>
        free_page(pages[i]);
    80002378:	fe442783          	lw	a5,-28(s0)
    8000237c:	078e                	sll	a5,a5,0x3
    8000237e:	17c1                	add	a5,a5,-16
    80002380:	97a2                	add	a5,a5,s0
    80002382:	cc07b783          	ld	a5,-832(a5)
    80002386:	853e                	mv	a0,a5
    80002388:	fffff097          	auipc	ra,0xfffff
    8000238c:	fc2080e7          	jalr	-62(ra) # 8000134a <free_page>
    for(int i = 0; i < allocated; i++) {
    80002390:	fe442783          	lw	a5,-28(s0)
    80002394:	2785                	addw	a5,a5,1
    80002396:	fef42223          	sw	a5,-28(s0)
    8000239a:	fe442783          	lw	a5,-28(s0)
    8000239e:	873e                	mv	a4,a5
    800023a0:	fec42783          	lw	a5,-20(s0)
    800023a4:	2701                	sext.w	a4,a4
    800023a6:	2781                	sext.w	a5,a5
    800023a8:	fcf748e3          	blt	a4,a5,80002378 <test_edge_cases+0xa2>
    }
    printf("Memory exhaustion test completed\n");
    800023ac:	00005517          	auipc	a0,0x5
    800023b0:	d8450513          	add	a0,a0,-636 # 80007130 <userret+0x10cc>
    800023b4:	fffff097          	auipc	ra,0xfffff
    800023b8:	832080e7          	jalr	-1998(ra) # 80000be6 <printf>
    
    // 测试地址对齐
    printf("Testing address alignment...\n");
    800023bc:	00005517          	auipc	a0,0x5
    800023c0:	d9c50513          	add	a0,a0,-612 # 80007158 <userret+0x10f4>
    800023c4:	fffff097          	auipc	ra,0xfffff
    800023c8:	822080e7          	jalr	-2014(ra) # 80000be6 <printf>
    pagetable_t pt = create_pagetable();
    800023cc:	fffff097          	auipc	ra,0xfffff
    800023d0:	198080e7          	jalr	408(ra) # 80001564 <create_pagetable>
    800023d4:	fca43c23          	sd	a0,-40(s0)
    uint64 pa = (uint64)alloc_page();
    800023d8:	fffff097          	auipc	ra,0xfffff
    800023dc:	f10080e7          	jalr	-240(ra) # 800012e8 <alloc_page>
    800023e0:	87aa                	mv	a5,a0
    800023e2:	fcf43823          	sd	a5,-48(s0)
    
    printf("Address alignment test completed\n");
    800023e6:	00005517          	auipc	a0,0x5
    800023ea:	d9250513          	add	a0,a0,-622 # 80007178 <userret+0x1114>
    800023ee:	ffffe097          	auipc	ra,0xffffe
    800023f2:	7f8080e7          	jalr	2040(ra) # 80000be6 <printf>
    
    // 清理
    free_page((void*)pa);
    800023f6:	fd043783          	ld	a5,-48(s0)
    800023fa:	853e                	mv	a0,a5
    800023fc:	fffff097          	auipc	ra,0xfffff
    80002400:	f4e080e7          	jalr	-178(ra) # 8000134a <free_page>
    destroy_pagetable(pt);
    80002404:	fd843503          	ld	a0,-40(s0)
    80002408:	fffff097          	auipc	ra,0xfffff
    8000240c:	216080e7          	jalr	534(ra) # 8000161e <destroy_pagetable>
    printf("Edge cases test completed\n\n");
    80002410:	00005517          	auipc	a0,0x5
    80002414:	d9050513          	add	a0,a0,-624 # 800071a0 <userret+0x113c>
    80002418:	ffffe097          	auipc	ra,0xffffe
    8000241c:	7ce080e7          	jalr	1998(ra) # 80000be6 <printf>
}
    80002420:	0001                	nop
    80002422:	34813083          	ld	ra,840(sp)
    80002426:	34013403          	ld	s0,832(sp)
    8000242a:	35010113          	add	sp,sp,848
    8000242e:	8082                	ret

0000000080002430 <run_comprehensive_tests>:

// ==================== 综合测试入口 ====================
void run_comprehensive_tests(void) {
    80002430:	1141                	add	sp,sp,-16
    80002432:	e406                	sd	ra,8(sp)
    80002434:	e022                	sd	s0,0(sp)
    80002436:	0800                	add	s0,sp,16
    printf("=== Comprehensive Memory Management Tests ===\n\n");
    80002438:	00005517          	auipc	a0,0x5
    8000243c:	d8850513          	add	a0,a0,-632 # 800071c0 <userret+0x115c>
    80002440:	ffffe097          	auipc	ra,0xffffe
    80002444:	7a6080e7          	jalr	1958(ra) # 80000be6 <printf>
    
    // 按顺序运行测试
    test_multilevel_pagetable();
    80002448:	00000097          	auipc	ra,0x0
    8000244c:	cb6080e7          	jalr	-842(ra) # 800020fe <test_multilevel_pagetable>
    test_edge_cases();
    80002450:	00000097          	auipc	ra,0x0
    80002454:	e86080e7          	jalr	-378(ra) # 800022d6 <test_edge_cases>
    
    printf("All comprehensive tests completed!\n");
    80002458:	00005517          	auipc	a0,0x5
    8000245c:	d9850513          	add	a0,a0,-616 # 800071f0 <userret+0x118c>
    80002460:	ffffe097          	auipc	ra,0xffffe
    80002464:	786080e7          	jalr	1926(ra) # 80000be6 <printf>
    80002468:	0001                	nop
    8000246a:	60a2                	ld	ra,8(sp)
    8000246c:	6402                	ld	s0,0(sp)
    8000246e:	0141                	add	sp,sp,16
    80002470:	8082                	ret

0000000080002472 <trap_init>:

static interrupt_handler_t interrupt_handlers[16] = {0};

// ==================== 初始化中断系统 ====================
void trap_init(void)
{
    80002472:	7179                	add	sp,sp,-48
    80002474:	f406                	sd	ra,40(sp)
    80002476:	f022                	sd	s0,32(sp)
    80002478:	1800                	add	s0,sp,48
    printf("Initializing trap system...\n");
    8000247a:	00005517          	auipc	a0,0x5
    8000247e:	d9e50513          	add	a0,a0,-610 # 80007218 <userret+0x11b4>
    80002482:	ffffe097          	auipc	ra,0xffffe
    80002486:	764080e7          	jalr	1892(ra) # 80000be6 <printf>
    
    for(int i = 0; i < 16; i++) {
    8000248a:	fe042623          	sw	zero,-20(s0)
    8000248e:	a815                	j	800024c2 <trap_init+0x50>
        interrupt_handlers[i] = 0;
    80002490:	0000c717          	auipc	a4,0xc
    80002494:	c1070713          	add	a4,a4,-1008 # 8000e0a0 <interrupt_handlers>
    80002498:	fec42783          	lw	a5,-20(s0)
    8000249c:	078e                	sll	a5,a5,0x3
    8000249e:	97ba                	add	a5,a5,a4
    800024a0:	0007b023          	sd	zero,0(a5)
        interrupt_counts[i] = 0;
    800024a4:	0000c717          	auipc	a4,0xc
    800024a8:	b7470713          	add	a4,a4,-1164 # 8000e018 <interrupt_counts>
    800024ac:	fec42783          	lw	a5,-20(s0)
    800024b0:	078e                	sll	a5,a5,0x3
    800024b2:	97ba                	add	a5,a5,a4
    800024b4:	0007b023          	sd	zero,0(a5)
    for(int i = 0; i < 16; i++) {
    800024b8:	fec42783          	lw	a5,-20(s0)
    800024bc:	2785                	addw	a5,a5,1
    800024be:	fef42623          	sw	a5,-20(s0)
    800024c2:	fec42783          	lw	a5,-20(s0)
    800024c6:	0007871b          	sext.w	a4,a5
    800024ca:	47bd                	li	a5,15
    800024cc:	fce7d2e3          	bge	a5,a4,80002490 <trap_init+0x1e>
    }
    
    // 设置内核态陷阱向量
    w_stvec((uint64)kernelvec);
    800024d0:	00001797          	auipc	a5,0x1
    800024d4:	07078793          	add	a5,a5,112 # 80003540 <kernelvec>
    800024d8:	10579073          	csrw	stvec,a5
    
    printf("Set stvec to %p\n", (void*)kernelvec);
    800024dc:	00001597          	auipc	a1,0x1
    800024e0:	06458593          	add	a1,a1,100 # 80003540 <kernelvec>
    800024e4:	00005517          	auipc	a0,0x5
    800024e8:	d5450513          	add	a0,a0,-684 # 80007238 <userret+0x11d4>
    800024ec:	ffffe097          	auipc	ra,0xffffe
    800024f0:	6fa080e7          	jalr	1786(ra) # 80000be6 <printf>
    
    // 使能中断
    w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800024f4:	104027f3          	csrr	a5,sie
    800024f8:	fef43023          	sd	a5,-32(s0)
    800024fc:	fe043783          	ld	a5,-32(s0)
    80002500:	2227e793          	or	a5,a5,546
    80002504:	10479073          	csrw	sie,a5
    w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002508:	100027f3          	csrr	a5,sstatus
    8000250c:	fcf43c23          	sd	a5,-40(s0)
    80002510:	fd843783          	ld	a5,-40(s0)
    80002514:	0027e793          	or	a5,a5,2
    80002518:	10079073          	csrw	sstatus,a5
    
    printf("Trap system initialized\n");
    8000251c:	00005517          	auipc	a0,0x5
    80002520:	d3450513          	add	a0,a0,-716 # 80007250 <userret+0x11ec>
    80002524:	ffffe097          	auipc	ra,0xffffe
    80002528:	6c2080e7          	jalr	1730(ra) # 80000be6 <printf>
}
    8000252c:	0001                	nop
    8000252e:	70a2                	ld	ra,40(sp)
    80002530:	7402                	ld	s0,32(sp)
    80002532:	6145                	add	sp,sp,48
    80002534:	8082                	ret

0000000080002536 <register_interrupt>:

// ==================== 注册中断处理函数 ====================
void register_interrupt(int irq, interrupt_handler_t handler)
{
    80002536:	1101                	add	sp,sp,-32
    80002538:	ec06                	sd	ra,24(sp)
    8000253a:	e822                	sd	s0,16(sp)
    8000253c:	1000                	add	s0,sp,32
    8000253e:	87aa                	mv	a5,a0
    80002540:	feb43023          	sd	a1,-32(s0)
    80002544:	fef42623          	sw	a5,-20(s0)
    if(irq < 0 || irq >= 16) {
    80002548:	fec42783          	lw	a5,-20(s0)
    8000254c:	2781                	sext.w	a5,a5
    8000254e:	0007c963          	bltz	a5,80002560 <register_interrupt+0x2a>
    80002552:	fec42783          	lw	a5,-20(s0)
    80002556:	0007871b          	sext.w	a4,a5
    8000255a:	47bd                	li	a5,15
    8000255c:	00e7de63          	bge	a5,a4,80002578 <register_interrupt+0x42>
        printf("register_interrupt: invalid IRQ %d\n", irq);
    80002560:	fec42783          	lw	a5,-20(s0)
    80002564:	85be                	mv	a1,a5
    80002566:	00005517          	auipc	a0,0x5
    8000256a:	d0a50513          	add	a0,a0,-758 # 80007270 <userret+0x120c>
    8000256e:	ffffe097          	auipc	ra,0xffffe
    80002572:	678080e7          	jalr	1656(ra) # 80000be6 <printf>
        return;
    80002576:	a03d                	j	800025a4 <register_interrupt+0x6e>
    }
    
    interrupt_handlers[irq] = handler;
    80002578:	0000c717          	auipc	a4,0xc
    8000257c:	b2870713          	add	a4,a4,-1240 # 8000e0a0 <interrupt_handlers>
    80002580:	fec42783          	lw	a5,-20(s0)
    80002584:	078e                	sll	a5,a5,0x3
    80002586:	97ba                	add	a5,a5,a4
    80002588:	fe043703          	ld	a4,-32(s0)
    8000258c:	e398                	sd	a4,0(a5)
    printf("Registered handler for IRQ %d\n", irq);
    8000258e:	fec42783          	lw	a5,-20(s0)
    80002592:	85be                	mv	a1,a5
    80002594:	00005517          	auipc	a0,0x5
    80002598:	d0450513          	add	a0,a0,-764 # 80007298 <userret+0x1234>
    8000259c:	ffffe097          	auipc	ra,0xffffe
    800025a0:	64a080e7          	jalr	1610(ra) # 80000be6 <printf>
}
    800025a4:	60e2                	ld	ra,24(sp)
    800025a6:	6442                	ld	s0,16(sp)
    800025a8:	6105                	add	sp,sp,32
    800025aa:	8082                	ret

00000000800025ac <devintr>:

// ==================== 设备中断处理 ====================
static int devintr(void)
{
    800025ac:	7179                	add	sp,sp,-48
    800025ae:	f406                	sd	ra,40(sp)
    800025b0:	f022                	sd	s0,32(sp)
    800025b2:	1800                	add	s0,sp,48
    uint64 scause = r_scause();
    800025b4:	142027f3          	csrr	a5,scause
    800025b8:	fef43423          	sd	a5,-24(s0)
    800025bc:	fe843783          	ld	a5,-24(s0)
    800025c0:	fef43023          	sd	a5,-32(s0)
    
    if((scause & 0x8000000000000000L) == 0) {
    800025c4:	fe043783          	ld	a5,-32(s0)
    800025c8:	0007c463          	bltz	a5,800025d0 <devintr+0x24>
        return 0;  // 不是中断
    800025cc:	4781                	li	a5,0
    800025ce:	a8d5                	j	800026c2 <devintr+0x116>
    }
    
    scause = scause & 0xff;
    800025d0:	fe043783          	ld	a5,-32(s0)
    800025d4:	0ff7f793          	zext.b	a5,a5
    800025d8:	fef43023          	sd	a5,-32(s0)
    
    if(scause == IRQ_S_TIMER) {
    800025dc:	fe043703          	ld	a4,-32(s0)
    800025e0:	4795                	li	a5,5
    800025e2:	02f71c63          	bne	a4,a5,8000261a <devintr+0x6e>
        interrupt_counts[IRQ_S_TIMER]++;
    800025e6:	0000c797          	auipc	a5,0xc
    800025ea:	a3278793          	add	a5,a5,-1486 # 8000e018 <interrupt_counts>
    800025ee:	779c                	ld	a5,40(a5)
    800025f0:	00178713          	add	a4,a5,1
    800025f4:	0000c797          	auipc	a5,0xc
    800025f8:	a2478793          	add	a5,a5,-1500 # 8000e018 <interrupt_counts>
    800025fc:	f798                	sd	a4,40(a5)
        
        if(interrupt_handlers[IRQ_S_TIMER]) {
    800025fe:	0000c797          	auipc	a5,0xc
    80002602:	aa278793          	add	a5,a5,-1374 # 8000e0a0 <interrupt_handlers>
    80002606:	779c                	ld	a5,40(a5)
    80002608:	c799                	beqz	a5,80002616 <devintr+0x6a>
            interrupt_handlers[IRQ_S_TIMER]();
    8000260a:	0000c797          	auipc	a5,0xc
    8000260e:	a9678793          	add	a5,a5,-1386 # 8000e0a0 <interrupt_handlers>
    80002612:	779c                	ld	a5,40(a5)
    80002614:	9782                	jalr	a5
        }
        
        return 1;
    80002616:	4785                	li	a5,1
    80002618:	a06d                	j	800026c2 <devintr+0x116>
        
    } else if(scause == IRQ_S_SOFT) {
    8000261a:	fe043703          	ld	a4,-32(s0)
    8000261e:	4785                	li	a5,1
    80002620:	06f71163          	bne	a4,a5,80002682 <devintr+0xd6>
        interrupt_counts[IRQ_S_SOFT]++;
    80002624:	0000c797          	auipc	a5,0xc
    80002628:	9f478793          	add	a5,a5,-1548 # 8000e018 <interrupt_counts>
    8000262c:	679c                	ld	a5,8(a5)
    8000262e:	00178713          	add	a4,a5,1
    80002632:	0000c797          	auipc	a5,0xc
    80002636:	9e678793          	add	a5,a5,-1562 # 8000e018 <interrupt_counts>
    8000263a:	e798                	sd	a4,8(a5)
        
        w_sip(r_sip() & ~2);
    8000263c:	144027f3          	csrr	a5,sip
    80002640:	fcf43c23          	sd	a5,-40(s0)
    80002644:	fd843783          	ld	a5,-40(s0)
    80002648:	9bf5                	and	a5,a5,-3
    8000264a:	14479073          	csrw	sip,a5
        
        if(interrupt_handlers[IRQ_S_TIMER]) {
    8000264e:	0000c797          	auipc	a5,0xc
    80002652:	a5278793          	add	a5,a5,-1454 # 8000e0a0 <interrupt_handlers>
    80002656:	779c                	ld	a5,40(a5)
    80002658:	c39d                	beqz	a5,8000267e <devintr+0xd2>
            interrupt_handlers[IRQ_S_TIMER]();
    8000265a:	0000c797          	auipc	a5,0xc
    8000265e:	a4678793          	add	a5,a5,-1466 # 8000e0a0 <interrupt_handlers>
    80002662:	779c                	ld	a5,40(a5)
    80002664:	9782                	jalr	a5
            interrupt_counts[IRQ_S_TIMER]++;
    80002666:	0000c797          	auipc	a5,0xc
    8000266a:	9b278793          	add	a5,a5,-1614 # 8000e018 <interrupt_counts>
    8000266e:	779c                	ld	a5,40(a5)
    80002670:	00178713          	add	a4,a5,1
    80002674:	0000c797          	auipc	a5,0xc
    80002678:	9a478793          	add	a5,a5,-1628 # 8000e018 <interrupt_counts>
    8000267c:	f798                	sd	a4,40(a5)
        }
        
        return 1;
    8000267e:	4785                	li	a5,1
    80002680:	a089                	j	800026c2 <devintr+0x116>
        
    } else if(scause == IRQ_S_EXT) {
    80002682:	fe043703          	ld	a4,-32(s0)
    80002686:	47a5                	li	a5,9
    80002688:	02f71c63          	bne	a4,a5,800026c0 <devintr+0x114>
        interrupt_counts[IRQ_S_EXT]++;
    8000268c:	0000c797          	auipc	a5,0xc
    80002690:	98c78793          	add	a5,a5,-1652 # 8000e018 <interrupt_counts>
    80002694:	67bc                	ld	a5,72(a5)
    80002696:	00178713          	add	a4,a5,1
    8000269a:	0000c797          	auipc	a5,0xc
    8000269e:	97e78793          	add	a5,a5,-1666 # 8000e018 <interrupt_counts>
    800026a2:	e7b8                	sd	a4,72(a5)
        
        if(interrupt_handlers[IRQ_S_EXT]) {
    800026a4:	0000c797          	auipc	a5,0xc
    800026a8:	9fc78793          	add	a5,a5,-1540 # 8000e0a0 <interrupt_handlers>
    800026ac:	67bc                	ld	a5,72(a5)
    800026ae:	c799                	beqz	a5,800026bc <devintr+0x110>
            interrupt_handlers[IRQ_S_EXT]();
    800026b0:	0000c797          	auipc	a5,0xc
    800026b4:	9f078793          	add	a5,a5,-1552 # 8000e0a0 <interrupt_handlers>
    800026b8:	67bc                	ld	a5,72(a5)
    800026ba:	9782                	jalr	a5
        }
        
        return 1;
    800026bc:	4785                	li	a5,1
    800026be:	a011                	j	800026c2 <devintr+0x116>
    }
    
    return 0;
    800026c0:	4781                	li	a5,0
}
    800026c2:	853e                	mv	a0,a5
    800026c4:	70a2                	ld	ra,40(sp)
    800026c6:	7402                	ld	s0,32(sp)
    800026c8:	6145                	add	sp,sp,48
    800026ca:	8082                	ret

00000000800026cc <handle_syscall>:

// ==================== 系统调用处理 ====================
void handle_syscall(struct trapframe *tf) {
    800026cc:	7179                	add	sp,sp,-48
    800026ce:	f406                	sd	ra,40(sp)
    800026d0:	f022                	sd	s0,32(sp)
    800026d2:	1800                	add	s0,sp,48
    800026d4:	fca43c23          	sd	a0,-40(s0)
    struct proc *p = myproc();
    800026d8:	00001097          	auipc	ra,0x1
    800026dc:	300080e7          	jalr	768(ra) # 800039d8 <myproc>
    800026e0:	fea43423          	sd	a0,-24(s0)
    if(p == 0) {
    800026e4:	fe843783          	ld	a5,-24(s0)
    800026e8:	eb89                	bnez	a5,800026fa <handle_syscall+0x2e>
        panic("handle_syscall: no process");
    800026ea:	00005517          	auipc	a0,0x5
    800026ee:	bce50513          	add	a0,a0,-1074 # 800072b8 <userret+0x1254>
    800026f2:	fffff097          	auipc	ra,0xfffff
    800026f6:	89a080e7          	jalr	-1894(ra) # 80000f8c <panic>
    }
    
    // 将中断栈的 trapframe 复制到进程的 trapframe
    if(p->trapframe) {
    800026fa:	fe843783          	ld	a5,-24(s0)
    800026fe:	6bdc                	ld	a5,144(a5)
    80002700:	c385                	beqz	a5,80002720 <handle_syscall+0x54>
        *p->trapframe = *tf;
    80002702:	fe843783          	ld	a5,-24(s0)
    80002706:	6bd8                	ld	a4,144(a5)
    80002708:	fd843783          	ld	a5,-40(s0)
    8000270c:	86be                	mv	a3,a5
    8000270e:	12000793          	li	a5,288
    80002712:	863e                	mv	a2,a5
    80002714:	85b6                	mv	a1,a3
    80002716:	853a                	mv	a0,a4
    80002718:	fffff097          	auipc	ra,0xfffff
    8000271c:	a56080e7          	jalr	-1450(ra) # 8000116e <memcpy>
    }
    
    // 调用系统调用分发器
    extern void syscall(struct trapframe *tf);
    syscall(p->trapframe);
    80002720:	fe843783          	ld	a5,-24(s0)
    80002724:	6bdc                	ld	a5,144(a5)
    80002726:	853e                	mv	a0,a5
    80002728:	00002097          	auipc	ra,0x2
    8000272c:	4d4080e7          	jalr	1236(ra) # 80004bfc <syscall>
    
    // 将修改后的 trapframe 复制回中断栈
    if(p->trapframe) {
    80002730:	fe843783          	ld	a5,-24(s0)
    80002734:	6bdc                	ld	a5,144(a5)
    80002736:	c385                	beqz	a5,80002756 <handle_syscall+0x8a>
        *tf = *p->trapframe;
    80002738:	fe843783          	ld	a5,-24(s0)
    8000273c:	6bdc                	ld	a5,144(a5)
    8000273e:	fd843703          	ld	a4,-40(s0)
    80002742:	86be                	mv	a3,a5
    80002744:	12000793          	li	a5,288
    80002748:	863e                	mv	a2,a5
    8000274a:	85b6                	mv	a1,a3
    8000274c:	853a                	mv	a0,a4
    8000274e:	fffff097          	auipc	ra,0xfffff
    80002752:	a20080e7          	jalr	-1504(ra) # 8000116e <memcpy>
    }
}
    80002756:	0001                	nop
    80002758:	70a2                	ld	ra,40(sp)
    8000275a:	7402                	ld	s0,32(sp)
    8000275c:	6145                	add	sp,sp,48
    8000275e:	8082                	ret

0000000080002760 <handle_instruction_page_fault>:

// ==================== 指令页故障处理 ====================
void handle_instruction_page_fault(struct trapframe *tf) {
    80002760:	7179                	add	sp,sp,-48
    80002762:	f406                	sd	ra,40(sp)
    80002764:	f022                	sd	s0,32(sp)
    80002766:	1800                	add	s0,sp,48
    80002768:	fca43c23          	sd	a0,-40(s0)
    uint64 fault_addr = r_stval();
    8000276c:	143027f3          	csrr	a5,stval
    80002770:	fef43423          	sd	a5,-24(s0)
    80002774:	fe843783          	ld	a5,-24(s0)
    80002778:	fef43023          	sd	a5,-32(s0)
    
    printf("\n=== Instruction Page Fault ===\n");
    8000277c:	00005517          	auipc	a0,0x5
    80002780:	b5c50513          	add	a0,a0,-1188 # 800072d8 <userret+0x1274>
    80002784:	ffffe097          	auipc	ra,0xffffe
    80002788:	462080e7          	jalr	1122(ra) # 80000be6 <printf>
    printf("Fault address: %p\n", (void*)fault_addr);
    8000278c:	fe043783          	ld	a5,-32(s0)
    80002790:	85be                	mv	a1,a5
    80002792:	00005517          	auipc	a0,0x5
    80002796:	b6e50513          	add	a0,a0,-1170 # 80007300 <userret+0x129c>
    8000279a:	ffffe097          	auipc	ra,0xffffe
    8000279e:	44c080e7          	jalr	1100(ra) # 80000be6 <printf>
    printf("PC: %p\n", (void*)tf->sepc);
    800027a2:	fd843783          	ld	a5,-40(s0)
    800027a6:	7ffc                	ld	a5,248(a5)
    800027a8:	85be                	mv	a1,a5
    800027aa:	00005517          	auipc	a0,0x5
    800027ae:	b6e50513          	add	a0,a0,-1170 # 80007318 <userret+0x12b4>
    800027b2:	ffffe097          	auipc	ra,0xffffe
    800027b6:	434080e7          	jalr	1076(ra) # 80000be6 <printf>
    
    if(fault_addr >= KERNBASE) {
    800027ba:	fe043703          	ld	a4,-32(s0)
    800027be:	800007b7          	lui	a5,0x80000
    800027c2:	fff7c793          	not	a5,a5
    800027c6:	00e7fa63          	bgeu	a5,a4,800027da <handle_instruction_page_fault+0x7a>
        panic("Instruction page fault in kernel space");
    800027ca:	00005517          	auipc	a0,0x5
    800027ce:	b5650513          	add	a0,a0,-1194 # 80007320 <userret+0x12bc>
    800027d2:	ffffe097          	auipc	ra,0xffffe
    800027d6:	7ba080e7          	jalr	1978(ra) # 80000f8c <panic>
    }
    
    printf("TODO: Implement demand paging for instruction fault\n");
    800027da:	00005517          	auipc	a0,0x5
    800027de:	b6e50513          	add	a0,a0,-1170 # 80007348 <userret+0x12e4>
    800027e2:	ffffe097          	auipc	ra,0xffffe
    800027e6:	404080e7          	jalr	1028(ra) # 80000be6 <printf>
    panic("Instruction page fault not handled");
    800027ea:	00005517          	auipc	a0,0x5
    800027ee:	b9650513          	add	a0,a0,-1130 # 80007380 <userret+0x131c>
    800027f2:	ffffe097          	auipc	ra,0xffffe
    800027f6:	79a080e7          	jalr	1946(ra) # 80000f8c <panic>
}
    800027fa:	0001                	nop
    800027fc:	70a2                	ld	ra,40(sp)
    800027fe:	7402                	ld	s0,32(sp)
    80002800:	6145                	add	sp,sp,48
    80002802:	8082                	ret

0000000080002804 <handle_load_page_fault>:

// ==================== 加载页故障处理 ====================
void handle_load_page_fault(struct trapframe *tf) {
    80002804:	7179                	add	sp,sp,-48
    80002806:	f406                	sd	ra,40(sp)
    80002808:	f022                	sd	s0,32(sp)
    8000280a:	1800                	add	s0,sp,48
    8000280c:	fca43c23          	sd	a0,-40(s0)
    uint64 fault_addr = r_stval();
    80002810:	143027f3          	csrr	a5,stval
    80002814:	fef43423          	sd	a5,-24(s0)
    80002818:	fe843783          	ld	a5,-24(s0)
    8000281c:	fef43023          	sd	a5,-32(s0)
    
    printf("\n=== Load Page Fault ===\n");
    80002820:	00005517          	auipc	a0,0x5
    80002824:	b8850513          	add	a0,a0,-1144 # 800073a8 <userret+0x1344>
    80002828:	ffffe097          	auipc	ra,0xffffe
    8000282c:	3be080e7          	jalr	958(ra) # 80000be6 <printf>
    printf("Fault address: %p\n", (void*)fault_addr);
    80002830:	fe043783          	ld	a5,-32(s0)
    80002834:	85be                	mv	a1,a5
    80002836:	00005517          	auipc	a0,0x5
    8000283a:	aca50513          	add	a0,a0,-1334 # 80007300 <userret+0x129c>
    8000283e:	ffffe097          	auipc	ra,0xffffe
    80002842:	3a8080e7          	jalr	936(ra) # 80000be6 <printf>
    printf("PC: %p\n", (void*)tf->sepc);
    80002846:	fd843783          	ld	a5,-40(s0)
    8000284a:	7ffc                	ld	a5,248(a5)
    8000284c:	85be                	mv	a1,a5
    8000284e:	00005517          	auipc	a0,0x5
    80002852:	aca50513          	add	a0,a0,-1334 # 80007318 <userret+0x12b4>
    80002856:	ffffe097          	auipc	ra,0xffffe
    8000285a:	390080e7          	jalr	912(ra) # 80000be6 <printf>
    printf("Tried to read from unmapped address\n");
    8000285e:	00005517          	auipc	a0,0x5
    80002862:	b6a50513          	add	a0,a0,-1174 # 800073c8 <userret+0x1364>
    80002866:	ffffe097          	auipc	ra,0xffffe
    8000286a:	380080e7          	jalr	896(ra) # 80000be6 <printf>
    
    panic("Load page fault");
    8000286e:	00005517          	auipc	a0,0x5
    80002872:	b8250513          	add	a0,a0,-1150 # 800073f0 <userret+0x138c>
    80002876:	ffffe097          	auipc	ra,0xffffe
    8000287a:	716080e7          	jalr	1814(ra) # 80000f8c <panic>
}
    8000287e:	0001                	nop
    80002880:	70a2                	ld	ra,40(sp)
    80002882:	7402                	ld	s0,32(sp)
    80002884:	6145                	add	sp,sp,48
    80002886:	8082                	ret

0000000080002888 <handle_store_page_fault>:

// ==================== 存储页故障处理 ====================
void handle_store_page_fault(struct trapframe *tf) {
    80002888:	7179                	add	sp,sp,-48
    8000288a:	f406                	sd	ra,40(sp)
    8000288c:	f022                	sd	s0,32(sp)
    8000288e:	1800                	add	s0,sp,48
    80002890:	fca43c23          	sd	a0,-40(s0)
    uint64 fault_addr = r_stval();
    80002894:	143027f3          	csrr	a5,stval
    80002898:	fef43423          	sd	a5,-24(s0)
    8000289c:	fe843783          	ld	a5,-24(s0)
    800028a0:	fef43023          	sd	a5,-32(s0)
    
    printf("\n=== Store Page Fault ===\n");
    800028a4:	00005517          	auipc	a0,0x5
    800028a8:	b5c50513          	add	a0,a0,-1188 # 80007400 <userret+0x139c>
    800028ac:	ffffe097          	auipc	ra,0xffffe
    800028b0:	33a080e7          	jalr	826(ra) # 80000be6 <printf>
    printf("Fault address: %p\n", (void*)fault_addr);
    800028b4:	fe043783          	ld	a5,-32(s0)
    800028b8:	85be                	mv	a1,a5
    800028ba:	00005517          	auipc	a0,0x5
    800028be:	a4650513          	add	a0,a0,-1466 # 80007300 <userret+0x129c>
    800028c2:	ffffe097          	auipc	ra,0xffffe
    800028c6:	324080e7          	jalr	804(ra) # 80000be6 <printf>
    printf("PC: %p\n", (void*)tf->sepc);
    800028ca:	fd843783          	ld	a5,-40(s0)
    800028ce:	7ffc                	ld	a5,248(a5)
    800028d0:	85be                	mv	a1,a5
    800028d2:	00005517          	auipc	a0,0x5
    800028d6:	a4650513          	add	a0,a0,-1466 # 80007318 <userret+0x12b4>
    800028da:	ffffe097          	auipc	ra,0xffffe
    800028de:	30c080e7          	jalr	780(ra) # 80000be6 <printf>
    printf("Tried to write to unmapped or read-only address\n");
    800028e2:	00005517          	auipc	a0,0x5
    800028e6:	b3e50513          	add	a0,a0,-1218 # 80007420 <userret+0x13bc>
    800028ea:	ffffe097          	auipc	ra,0xffffe
    800028ee:	2fc080e7          	jalr	764(ra) # 80000be6 <printf>
    
    if(fault_addr >= KERNBASE && fault_addr < (uint64)etext) {
    800028f2:	fe043703          	ld	a4,-32(s0)
    800028f6:	800007b7          	lui	a5,0x80000
    800028fa:	fff7c793          	not	a5,a5
    800028fe:	02e7f263          	bgeu	a5,a4,80002922 <handle_store_page_fault+0x9a>
    80002902:	00003797          	auipc	a5,0x3
    80002906:	6fe78793          	add	a5,a5,1790 # 80006000 <etext>
    8000290a:	fe043703          	ld	a4,-32(s0)
    8000290e:	00f77a63          	bgeu	a4,a5,80002922 <handle_store_page_fault+0x9a>
        printf("Attempted to write to read-only kernel text segment!\n");
    80002912:	00005517          	auipc	a0,0x5
    80002916:	b4650513          	add	a0,a0,-1210 # 80007458 <userret+0x13f4>
    8000291a:	ffffe097          	auipc	ra,0xffffe
    8000291e:	2cc080e7          	jalr	716(ra) # 80000be6 <printf>
    }
    
    panic("Store page fault");
    80002922:	00005517          	auipc	a0,0x5
    80002926:	b6e50513          	add	a0,a0,-1170 # 80007490 <userret+0x142c>
    8000292a:	ffffe097          	auipc	ra,0xffffe
    8000292e:	662080e7          	jalr	1634(ra) # 80000f8c <panic>
}
    80002932:	0001                	nop
    80002934:	70a2                	ld	ra,40(sp)
    80002936:	7402                	ld	s0,32(sp)
    80002938:	6145                	add	sp,sp,48
    8000293a:	8082                	ret

000000008000293c <handle_exception>:

// ==================== 统一异常处理入口 ====================
void handle_exception(struct trapframe *tf) {
    8000293c:	7159                	add	sp,sp,-112
    8000293e:	f486                	sd	ra,104(sp)
    80002940:	f0a2                	sd	s0,96(sp)
    80002942:	eca6                	sd	s1,88(sp)
    80002944:	1880                	add	s0,sp,112
    80002946:	f8a43c23          	sd	a0,-104(s0)
    uint64 cause = r_scause();
    8000294a:	142027f3          	csrr	a5,scause
    8000294e:	fcf43c23          	sd	a5,-40(s0)
    80002952:	fd843783          	ld	a5,-40(s0)
    80002956:	fcf43823          	sd	a5,-48(s0)
    
    printf("\n[Exception Handler] cause=%d (%s)\n", 
    8000295a:	fd043783          	ld	a5,-48(s0)
    8000295e:	0007849b          	sext.w	s1,a5
    80002962:	fd043503          	ld	a0,-48(s0)
    80002966:	00001097          	auipc	ra,0x1
    8000296a:	89a080e7          	jalr	-1894(ra) # 80003200 <trap_cause_name>
    8000296e:	87aa                	mv	a5,a0
    80002970:	863e                	mv	a2,a5
    80002972:	85a6                	mv	a1,s1
    80002974:	00005517          	auipc	a0,0x5
    80002978:	b3450513          	add	a0,a0,-1228 # 800074a8 <userret+0x1444>
    8000297c:	ffffe097          	auipc	ra,0xffffe
    80002980:	26a080e7          	jalr	618(ra) # 80000be6 <printf>
           (int)cause, trap_cause_name(cause));
    
    switch(cause) {
    80002984:	fd043703          	ld	a4,-48(s0)
    80002988:	47bd                	li	a5,15
    8000298a:	1ce7e563          	bltu	a5,a4,80002b54 <handle_exception+0x218>
    8000298e:	fd043783          	ld	a5,-48(s0)
    80002992:	00279713          	sll	a4,a5,0x2
    80002996:	00005797          	auipc	a5,0x5
    8000299a:	cde78793          	add	a5,a5,-802 # 80007674 <userret+0x1610>
    8000299e:	97ba                	add	a5,a5,a4
    800029a0:	439c                	lw	a5,0(a5)
    800029a2:	0007871b          	sext.w	a4,a5
    800029a6:	00005797          	auipc	a5,0x5
    800029aa:	cce78793          	add	a5,a5,-818 # 80007674 <userret+0x1610>
    800029ae:	97ba                	add	a5,a5,a4
    800029b0:	8782                	jr	a5
        case CAUSE_USER_ECALL:
        case CAUSE_SUPERVISOR_ECALL:
            handle_syscall(tf);
    800029b2:	f9843503          	ld	a0,-104(s0)
    800029b6:	00000097          	auipc	ra,0x0
    800029ba:	d16080e7          	jalr	-746(ra) # 800026cc <handle_syscall>
            break;
    800029be:	a419                	j	80002bc4 <handle_exception+0x288>
            
        case CAUSE_FETCH_PAGE_FAULT:
            handle_instruction_page_fault(tf);
    800029c0:	f9843503          	ld	a0,-104(s0)
    800029c4:	00000097          	auipc	ra,0x0
    800029c8:	d9c080e7          	jalr	-612(ra) # 80002760 <handle_instruction_page_fault>
            break;
    800029cc:	aae5                	j	80002bc4 <handle_exception+0x288>
            
        case CAUSE_LOAD_PAGE_FAULT:
            handle_load_page_fault(tf);
    800029ce:	f9843503          	ld	a0,-104(s0)
    800029d2:	00000097          	auipc	ra,0x0
    800029d6:	e32080e7          	jalr	-462(ra) # 80002804 <handle_load_page_fault>
            break;
    800029da:	a2ed                	j	80002bc4 <handle_exception+0x288>
            
        case CAUSE_STORE_PAGE_FAULT:
            handle_store_page_fault(tf);
    800029dc:	f9843503          	ld	a0,-104(s0)
    800029e0:	00000097          	auipc	ra,0x0
    800029e4:	ea8080e7          	jalr	-344(ra) # 80002888 <handle_store_page_fault>
            break;
    800029e8:	aaf1                	j	80002bc4 <handle_exception+0x288>
            
        case CAUSE_ILLEGAL_INSTRUCTION:
            printf("\n=== Illegal Instruction ===\n");
    800029ea:	00005517          	auipc	a0,0x5
    800029ee:	ae650513          	add	a0,a0,-1306 # 800074d0 <userret+0x146c>
    800029f2:	ffffe097          	auipc	ra,0xffffe
    800029f6:	1f4080e7          	jalr	500(ra) # 80000be6 <printf>
            printf("PC: %p\n", (void*)tf->sepc);
    800029fa:	f9843783          	ld	a5,-104(s0)
    800029fe:	7ffc                	ld	a5,248(a5)
    80002a00:	85be                	mv	a1,a5
    80002a02:	00005517          	auipc	a0,0x5
    80002a06:	91650513          	add	a0,a0,-1770 # 80007318 <userret+0x12b4>
    80002a0a:	ffffe097          	auipc	ra,0xffffe
    80002a0e:	1dc080e7          	jalr	476(ra) # 80000be6 <printf>
            printf("Instruction value: %p\n", (void*)r_stval());
    80002a12:	143027f3          	csrr	a5,stval
    80002a16:	faf43c23          	sd	a5,-72(s0)
    80002a1a:	fb843783          	ld	a5,-72(s0)
    80002a1e:	85be                	mv	a1,a5
    80002a20:	00005517          	auipc	a0,0x5
    80002a24:	ad050513          	add	a0,a0,-1328 # 800074f0 <userret+0x148c>
    80002a28:	ffffe097          	auipc	ra,0xffffe
    80002a2c:	1be080e7          	jalr	446(ra) # 80000be6 <printf>
            panic("Illegal instruction");
    80002a30:	00005517          	auipc	a0,0x5
    80002a34:	ad850513          	add	a0,a0,-1320 # 80007508 <userret+0x14a4>
    80002a38:	ffffe097          	auipc	ra,0xffffe
    80002a3c:	554080e7          	jalr	1364(ra) # 80000f8c <panic>
            break;
    80002a40:	a251                	j	80002bc4 <handle_exception+0x288>
            
        case CAUSE_BREAKPOINT:
            printf("\n=== Breakpoint ===\n");
    80002a42:	00005517          	auipc	a0,0x5
    80002a46:	ade50513          	add	a0,a0,-1314 # 80007520 <userret+0x14bc>
    80002a4a:	ffffe097          	auipc	ra,0xffffe
    80002a4e:	19c080e7          	jalr	412(ra) # 80000be6 <printf>
            printf("PC: %p\n", (void*)tf->sepc);
    80002a52:	f9843783          	ld	a5,-104(s0)
    80002a56:	7ffc                	ld	a5,248(a5)
    80002a58:	85be                	mv	a1,a5
    80002a5a:	00005517          	auipc	a0,0x5
    80002a5e:	8be50513          	add	a0,a0,-1858 # 80007318 <userret+0x12b4>
    80002a62:	ffffe097          	auipc	ra,0xffffe
    80002a66:	184080e7          	jalr	388(ra) # 80000be6 <printf>
            tf->sepc += 2;
    80002a6a:	f9843783          	ld	a5,-104(s0)
    80002a6e:	7ffc                	ld	a5,248(a5)
    80002a70:	00278713          	add	a4,a5,2
    80002a74:	f9843783          	ld	a5,-104(s0)
    80002a78:	fff8                	sd	a4,248(a5)
            printf("Breakpoint handled, continuing from %p\n", (void*)tf->sepc);
    80002a7a:	f9843783          	ld	a5,-104(s0)
    80002a7e:	7ffc                	ld	a5,248(a5)
    80002a80:	85be                	mv	a1,a5
    80002a82:	00005517          	auipc	a0,0x5
    80002a86:	ab650513          	add	a0,a0,-1354 # 80007538 <userret+0x14d4>
    80002a8a:	ffffe097          	auipc	ra,0xffffe
    80002a8e:	15c080e7          	jalr	348(ra) # 80000be6 <printf>
            break;
    80002a92:	aa0d                	j	80002bc4 <handle_exception+0x288>
            
        case CAUSE_MISALIGNED_FETCH:
            printf("\n=== Misaligned Instruction Fetch ===\n");
    80002a94:	00005517          	auipc	a0,0x5
    80002a98:	acc50513          	add	a0,a0,-1332 # 80007560 <userret+0x14fc>
    80002a9c:	ffffe097          	auipc	ra,0xffffe
    80002aa0:	14a080e7          	jalr	330(ra) # 80000be6 <printf>
            printf("Address: %p\n", (void*)r_stval());
    80002aa4:	143027f3          	csrr	a5,stval
    80002aa8:	faf43823          	sd	a5,-80(s0)
    80002aac:	fb043783          	ld	a5,-80(s0)
    80002ab0:	85be                	mv	a1,a5
    80002ab2:	00005517          	auipc	a0,0x5
    80002ab6:	ad650513          	add	a0,a0,-1322 # 80007588 <userret+0x1524>
    80002aba:	ffffe097          	auipc	ra,0xffffe
    80002abe:	12c080e7          	jalr	300(ra) # 80000be6 <printf>
            panic("Misaligned instruction fetch");
    80002ac2:	00005517          	auipc	a0,0x5
    80002ac6:	ad650513          	add	a0,a0,-1322 # 80007598 <userret+0x1534>
    80002aca:	ffffe097          	auipc	ra,0xffffe
    80002ace:	4c2080e7          	jalr	1218(ra) # 80000f8c <panic>
            break;
    80002ad2:	a8cd                	j	80002bc4 <handle_exception+0x288>
            
        case CAUSE_MISALIGNED_LOAD:
            printf("\n=== Misaligned Load ===\n");
    80002ad4:	00005517          	auipc	a0,0x5
    80002ad8:	ae450513          	add	a0,a0,-1308 # 800075b8 <userret+0x1554>
    80002adc:	ffffe097          	auipc	ra,0xffffe
    80002ae0:	10a080e7          	jalr	266(ra) # 80000be6 <printf>
            printf("Address: %p\n", (void*)r_stval());
    80002ae4:	143027f3          	csrr	a5,stval
    80002ae8:	fcf43023          	sd	a5,-64(s0)
    80002aec:	fc043783          	ld	a5,-64(s0)
    80002af0:	85be                	mv	a1,a5
    80002af2:	00005517          	auipc	a0,0x5
    80002af6:	a9650513          	add	a0,a0,-1386 # 80007588 <userret+0x1524>
    80002afa:	ffffe097          	auipc	ra,0xffffe
    80002afe:	0ec080e7          	jalr	236(ra) # 80000be6 <printf>
            panic("Misaligned load");
    80002b02:	00005517          	auipc	a0,0x5
    80002b06:	ad650513          	add	a0,a0,-1322 # 800075d8 <userret+0x1574>
    80002b0a:	ffffe097          	auipc	ra,0xffffe
    80002b0e:	482080e7          	jalr	1154(ra) # 80000f8c <panic>
            break;
    80002b12:	a84d                	j	80002bc4 <handle_exception+0x288>
            
        case CAUSE_MISALIGNED_STORE:
            printf("\n=== Misaligned Store ===\n");
    80002b14:	00005517          	auipc	a0,0x5
    80002b18:	ad450513          	add	a0,a0,-1324 # 800075e8 <userret+0x1584>
    80002b1c:	ffffe097          	auipc	ra,0xffffe
    80002b20:	0ca080e7          	jalr	202(ra) # 80000be6 <printf>
            printf("Address: %p\n", (void*)r_stval());
    80002b24:	143027f3          	csrr	a5,stval
    80002b28:	fcf43423          	sd	a5,-56(s0)
    80002b2c:	fc843783          	ld	a5,-56(s0)
    80002b30:	85be                	mv	a1,a5
    80002b32:	00005517          	auipc	a0,0x5
    80002b36:	a5650513          	add	a0,a0,-1450 # 80007588 <userret+0x1524>
    80002b3a:	ffffe097          	auipc	ra,0xffffe
    80002b3e:	0ac080e7          	jalr	172(ra) # 80000be6 <printf>
            panic("Misaligned store");
    80002b42:	00005517          	auipc	a0,0x5
    80002b46:	ac650513          	add	a0,a0,-1338 # 80007608 <userret+0x15a4>
    80002b4a:	ffffe097          	auipc	ra,0xffffe
    80002b4e:	442080e7          	jalr	1090(ra) # 80000f8c <panic>
            break;
    80002b52:	a88d                	j	80002bc4 <handle_exception+0x288>
            
        default:
            printf("\n=== Unknown Exception ===\n");
    80002b54:	00005517          	auipc	a0,0x5
    80002b58:	acc50513          	add	a0,a0,-1332 # 80007620 <userret+0x15bc>
    80002b5c:	ffffe097          	auipc	ra,0xffffe
    80002b60:	08a080e7          	jalr	138(ra) # 80000be6 <printf>
            printf("cause: %d\n", (int)cause);
    80002b64:	fd043783          	ld	a5,-48(s0)
    80002b68:	2781                	sext.w	a5,a5
    80002b6a:	85be                	mv	a1,a5
    80002b6c:	00005517          	auipc	a0,0x5
    80002b70:	ad450513          	add	a0,a0,-1324 # 80007640 <userret+0x15dc>
    80002b74:	ffffe097          	auipc	ra,0xffffe
    80002b78:	072080e7          	jalr	114(ra) # 80000be6 <printf>
            printf("PC: %p\n", (void*)tf->sepc);
    80002b7c:	f9843783          	ld	a5,-104(s0)
    80002b80:	7ffc                	ld	a5,248(a5)
    80002b82:	85be                	mv	a1,a5
    80002b84:	00004517          	auipc	a0,0x4
    80002b88:	79450513          	add	a0,a0,1940 # 80007318 <userret+0x12b4>
    80002b8c:	ffffe097          	auipc	ra,0xffffe
    80002b90:	05a080e7          	jalr	90(ra) # 80000be6 <printf>
            printf("stval: %p\n", (void*)r_stval());
    80002b94:	143027f3          	csrr	a5,stval
    80002b98:	faf43423          	sd	a5,-88(s0)
    80002b9c:	fa843783          	ld	a5,-88(s0)
    80002ba0:	85be                	mv	a1,a5
    80002ba2:	00005517          	auipc	a0,0x5
    80002ba6:	aae50513          	add	a0,a0,-1362 # 80007650 <userret+0x15ec>
    80002baa:	ffffe097          	auipc	ra,0xffffe
    80002bae:	03c080e7          	jalr	60(ra) # 80000be6 <printf>
            panic("Unknown exception");
    80002bb2:	00005517          	auipc	a0,0x5
    80002bb6:	aae50513          	add	a0,a0,-1362 # 80007660 <userret+0x15fc>
    80002bba:	ffffe097          	auipc	ra,0xffffe
    80002bbe:	3d2080e7          	jalr	978(ra) # 80000f8c <panic>
    }
}
    80002bc2:	0001                	nop
    80002bc4:	0001                	nop
    80002bc6:	70a6                	ld	ra,104(sp)
    80002bc8:	7406                	ld	s0,96(sp)
    80002bca:	64e6                	ld	s1,88(sp)
    80002bcc:	6165                	add	sp,sp,112
    80002bce:	8082                	ret

0000000080002bd0 <kerneltrap>:

// ==================== 内核态中断/异常处理入口 ====================
void kerneltrap(struct trapframe *tf)
{
    80002bd0:	7139                	add	sp,sp,-64
    80002bd2:	fc06                	sd	ra,56(sp)
    80002bd4:	f822                	sd	s0,48(sp)
    80002bd6:	0080                	add	s0,sp,64
    80002bd8:	fca43423          	sd	a0,-56(s0)
    uint64 sstatus = r_sstatus();
    80002bdc:	100027f3          	csrr	a5,sstatus
    80002be0:	fef43423          	sd	a5,-24(s0)
    80002be4:	fe843783          	ld	a5,-24(s0)
    80002be8:	fef43023          	sd	a5,-32(s0)
    
    if((sstatus & SSTATUS_SPP) == 0) {
    80002bec:	fe043783          	ld	a5,-32(s0)
    80002bf0:	1007f793          	and	a5,a5,256
    80002bf4:	eb89                	bnez	a5,80002c06 <kerneltrap+0x36>
        panic("kerneltrap: not from supervisor mode");
    80002bf6:	00005517          	auipc	a0,0x5
    80002bfa:	ac250513          	add	a0,a0,-1342 # 800076b8 <userret+0x1654>
    80002bfe:	ffffe097          	auipc	ra,0xffffe
    80002c02:	38e080e7          	jalr	910(ra) # 80000f8c <panic>
    }
    
    if(sstatus & SSTATUS_SIE) {
    80002c06:	fe043783          	ld	a5,-32(s0)
    80002c0a:	8b89                	and	a5,a5,2
    80002c0c:	cb89                	beqz	a5,80002c1e <kerneltrap+0x4e>
        panic("kerneltrap: interrupts enabled");
    80002c0e:	00005517          	auipc	a0,0x5
    80002c12:	ad250513          	add	a0,a0,-1326 # 800076e0 <userret+0x167c>
    80002c16:	ffffe097          	auipc	ra,0xffffe
    80002c1a:	376080e7          	jalr	886(ra) # 80000f8c <panic>
    }
    
    int is_device_interrupt = devintr();
    80002c1e:	00000097          	auipc	ra,0x0
    80002c22:	98e080e7          	jalr	-1650(ra) # 800025ac <devintr>
    80002c26:	87aa                	mv	a5,a0
    80002c28:	fcf42e23          	sw	a5,-36(s0)
    
    if(!is_device_interrupt) {
    80002c2c:	fdc42783          	lw	a5,-36(s0)
    80002c30:	2781                	sext.w	a5,a5
    80002c32:	e39d                	bnez	a5,80002c58 <kerneltrap+0x88>
        exception_count++;
    80002c34:	0000b797          	auipc	a5,0xb
    80002c38:	46478793          	add	a5,a5,1124 # 8000e098 <exception_count>
    80002c3c:	639c                	ld	a5,0(a5)
    80002c3e:	00178713          	add	a4,a5,1
    80002c42:	0000b797          	auipc	a5,0xb
    80002c46:	45678793          	add	a5,a5,1110 # 8000e098 <exception_count>
    80002c4a:	e398                	sd	a4,0(a5)
        handle_exception(tf);
    80002c4c:	fc843503          	ld	a0,-56(s0)
    80002c50:	00000097          	auipc	ra,0x0
    80002c54:	cec080e7          	jalr	-788(ra) # 8000293c <handle_exception>
    }
    
    w_sstatus(sstatus);
    80002c58:	fe043783          	ld	a5,-32(s0)
    80002c5c:	10079073          	csrw	sstatus,a5
}
    80002c60:	0001                	nop
    80002c62:	70e2                	ld	ra,56(sp)
    80002c64:	7442                	ld	s0,48(sp)
    80002c66:	6121                	add	sp,sp,64
    80002c68:	8082                	ret

0000000080002c6a <usertrap>:

// ==================== 用户态陷阱处理 ====================

// 处理来自用户态的陷阱
void usertrap(void)
{
    80002c6a:	711d                	add	sp,sp,-96
    80002c6c:	ec86                	sd	ra,88(sp)
    80002c6e:	e8a2                	sd	s0,80(sp)
    80002c70:	1080                	add	s0,sp,96
    // ⭐ 第一时间输出，证明进入了 usertrap
    volatile char *uart = (volatile char*)0x10000000;
    80002c72:	100007b7          	lui	a5,0x10000
    80002c76:	fef43023          	sd	a5,-32(s0)
    uart[0] = '\n';
    80002c7a:	fe043783          	ld	a5,-32(s0)
    80002c7e:	4729                	li	a4,10
    80002c80:	00e78023          	sb	a4,0(a5) # 10000000 <_entry-0x70000000>
    uart[0] = 'U'; uart[0] = 'S'; uart[0] = 'E'; uart[0] = 'R';
    80002c84:	fe043783          	ld	a5,-32(s0)
    80002c88:	05500713          	li	a4,85
    80002c8c:	00e78023          	sb	a4,0(a5)
    80002c90:	fe043783          	ld	a5,-32(s0)
    80002c94:	05300713          	li	a4,83
    80002c98:	00e78023          	sb	a4,0(a5)
    80002c9c:	fe043783          	ld	a5,-32(s0)
    80002ca0:	04500713          	li	a4,69
    80002ca4:	00e78023          	sb	a4,0(a5)
    80002ca8:	fe043783          	ld	a5,-32(s0)
    80002cac:	05200713          	li	a4,82
    80002cb0:	00e78023          	sb	a4,0(a5)
    uart[0] = 'T'; uart[0] = 'R'; uart[0] = 'A'; uart[0] = 'P';
    80002cb4:	fe043783          	ld	a5,-32(s0)
    80002cb8:	05400713          	li	a4,84
    80002cbc:	00e78023          	sb	a4,0(a5)
    80002cc0:	fe043783          	ld	a5,-32(s0)
    80002cc4:	05200713          	li	a4,82
    80002cc8:	00e78023          	sb	a4,0(a5)
    80002ccc:	fe043783          	ld	a5,-32(s0)
    80002cd0:	04100713          	li	a4,65
    80002cd4:	00e78023          	sb	a4,0(a5)
    80002cd8:	fe043783          	ld	a5,-32(s0)
    80002cdc:	05000713          	li	a4,80
    80002ce0:	00e78023          	sb	a4,0(a5)
    uart[0] = '!'; uart[0] = '\n';
    80002ce4:	fe043783          	ld	a5,-32(s0)
    80002ce8:	02100713          	li	a4,33
    80002cec:	00e78023          	sb	a4,0(a5)
    80002cf0:	fe043783          	ld	a5,-32(s0)
    80002cf4:	4729                	li	a4,10
    80002cf6:	00e78023          	sb	a4,0(a5)
    
    struct proc *p = myproc();
    80002cfa:	00001097          	auipc	ra,0x1
    80002cfe:	cde080e7          	jalr	-802(ra) # 800039d8 <myproc>
    80002d02:	fca43c23          	sd	a0,-40(s0)
    
    // 保存 sepc
    p->trapframe->sepc = r_sepc();
    80002d06:	141027f3          	csrr	a5,sepc
    80002d0a:	fcf43823          	sd	a5,-48(s0)
    80002d0e:	fd043703          	ld	a4,-48(s0)
    80002d12:	fd843783          	ld	a5,-40(s0)
    80002d16:	6bdc                	ld	a5,144(a5)
    80002d18:	fff8                	sd	a4,248(a5)
    
    uint64 cause = r_scause();
    80002d1a:	142027f3          	csrr	a5,scause
    80002d1e:	fcf43423          	sd	a5,-56(s0)
    80002d22:	fc843783          	ld	a5,-56(s0)
    80002d26:	fcf43023          	sd	a5,-64(s0)
    
    uart[0] = 'C'; uart[0] = 'A'; uart[0] = 'U'; uart[0] = 'S'; 
    80002d2a:	fe043783          	ld	a5,-32(s0)
    80002d2e:	04300713          	li	a4,67
    80002d32:	00e78023          	sb	a4,0(a5)
    80002d36:	fe043783          	ld	a5,-32(s0)
    80002d3a:	04100713          	li	a4,65
    80002d3e:	00e78023          	sb	a4,0(a5)
    80002d42:	fe043783          	ld	a5,-32(s0)
    80002d46:	05500713          	li	a4,85
    80002d4a:	00e78023          	sb	a4,0(a5)
    80002d4e:	fe043783          	ld	a5,-32(s0)
    80002d52:	05300713          	li	a4,83
    80002d56:	00e78023          	sb	a4,0(a5)
    uart[0] = 'E'; uart[0] = '=';
    80002d5a:	fe043783          	ld	a5,-32(s0)
    80002d5e:	04500713          	li	a4,69
    80002d62:	00e78023          	sb	a4,0(a5)
    80002d66:	fe043783          	ld	a5,-32(s0)
    80002d6a:	03d00713          	li	a4,61
    80002d6e:	00e78023          	sb	a4,0(a5)
    // 输出 cause 的十六进制
    uint64 val = cause;
    80002d72:	fc043783          	ld	a5,-64(s0)
    80002d76:	faf43c23          	sd	a5,-72(s0)
    for(int i = 60; i >= 0; i -= 4) {
    80002d7a:	03c00793          	li	a5,60
    80002d7e:	fef42623          	sw	a5,-20(s0)
    80002d82:	a8a9                	j	80002ddc <usertrap+0x172>
        int digit = (val >> i) & 0xf;
    80002d84:	fec42783          	lw	a5,-20(s0)
    80002d88:	873e                	mv	a4,a5
    80002d8a:	fb843783          	ld	a5,-72(s0)
    80002d8e:	00e7d7b3          	srl	a5,a5,a4
    80002d92:	2781                	sext.w	a5,a5
    80002d94:	8bbd                	and	a5,a5,15
    80002d96:	faf42223          	sw	a5,-92(s0)
        uart[0] = digit < 10 ? '0' + digit : 'a' + digit - 10;
    80002d9a:	fa442783          	lw	a5,-92(s0)
    80002d9e:	0007871b          	sext.w	a4,a5
    80002da2:	47a5                	li	a5,9
    80002da4:	00e7cb63          	blt	a5,a4,80002dba <usertrap+0x150>
    80002da8:	fa442783          	lw	a5,-92(s0)
    80002dac:	0ff7f793          	zext.b	a5,a5
    80002db0:	0307879b          	addw	a5,a5,48
    80002db4:	0ff7f793          	zext.b	a5,a5
    80002db8:	a809                	j	80002dca <usertrap+0x160>
    80002dba:	fa442783          	lw	a5,-92(s0)
    80002dbe:	0ff7f793          	zext.b	a5,a5
    80002dc2:	0577879b          	addw	a5,a5,87
    80002dc6:	0ff7f793          	zext.b	a5,a5
    80002dca:	fe043703          	ld	a4,-32(s0)
    80002dce:	00f70023          	sb	a5,0(a4)
    for(int i = 60; i >= 0; i -= 4) {
    80002dd2:	fec42783          	lw	a5,-20(s0)
    80002dd6:	37f1                	addw	a5,a5,-4
    80002dd8:	fef42623          	sw	a5,-20(s0)
    80002ddc:	fec42783          	lw	a5,-20(s0)
    80002de0:	2781                	sext.w	a5,a5
    80002de2:	fa07d1e3          	bgez	a5,80002d84 <usertrap+0x11a>
    }
    uart[0] = '\n';
    80002de6:	fe043783          	ld	a5,-32(s0)
    80002dea:	4729                	li	a4,10
    80002dec:	00e78023          	sb	a4,0(a5)
    
    if(cause == 8) {  // 用户态 ecall
    80002df0:	fc043703          	ld	a4,-64(s0)
    80002df4:	47a1                	li	a5,8
    80002df6:	0af71463          	bne	a4,a5,80002e9e <usertrap+0x234>
        uart[0] = 'E'; uart[0] = 'C'; uart[0] = 'A'; uart[0] = 'L'; 
    80002dfa:	fe043783          	ld	a5,-32(s0)
    80002dfe:	04500713          	li	a4,69
    80002e02:	00e78023          	sb	a4,0(a5)
    80002e06:	fe043783          	ld	a5,-32(s0)
    80002e0a:	04300713          	li	a4,67
    80002e0e:	00e78023          	sb	a4,0(a5)
    80002e12:	fe043783          	ld	a5,-32(s0)
    80002e16:	04100713          	li	a4,65
    80002e1a:	00e78023          	sb	a4,0(a5)
    80002e1e:	fe043783          	ld	a5,-32(s0)
    80002e22:	04c00713          	li	a4,76
    80002e26:	00e78023          	sb	a4,0(a5)
        uart[0] = 'L'; uart[0] = '\n';
    80002e2a:	fe043783          	ld	a5,-32(s0)
    80002e2e:	04c00713          	li	a4,76
    80002e32:	00e78023          	sb	a4,0(a5)
    80002e36:	fe043783          	ld	a5,-32(s0)
    80002e3a:	4729                	li	a4,10
    80002e3c:	00e78023          	sb	a4,0(a5)
        
        p->trapframe->sepc += 4;
    80002e40:	fd843783          	ld	a5,-40(s0)
    80002e44:	6bdc                	ld	a5,144(a5)
    80002e46:	7ff8                	ld	a4,248(a5)
    80002e48:	fd843783          	ld	a5,-40(s0)
    80002e4c:	6bdc                	ld	a5,144(a5)
    80002e4e:	0711                	add	a4,a4,4
    80002e50:	fff8                	sd	a4,248(a5)
        
        // 调用系统调用处理
        syscall(p->trapframe);
    80002e52:	fd843783          	ld	a5,-40(s0)
    80002e56:	6bdc                	ld	a5,144(a5)
    80002e58:	853e                	mv	a0,a5
    80002e5a:	00002097          	auipc	ra,0x2
    80002e5e:	da2080e7          	jalr	-606(ra) # 80004bfc <syscall>
        
        uart[0] = 'D'; uart[0] = 'O'; uart[0] = 'N'; uart[0] = 'E';
    80002e62:	fe043783          	ld	a5,-32(s0)
    80002e66:	04400713          	li	a4,68
    80002e6a:	00e78023          	sb	a4,0(a5)
    80002e6e:	fe043783          	ld	a5,-32(s0)
    80002e72:	04f00713          	li	a4,79
    80002e76:	00e78023          	sb	a4,0(a5)
    80002e7a:	fe043783          	ld	a5,-32(s0)
    80002e7e:	04e00713          	li	a4,78
    80002e82:	00e78023          	sb	a4,0(a5)
    80002e86:	fe043783          	ld	a5,-32(s0)
    80002e8a:	04500713          	li	a4,69
    80002e8e:	00e78023          	sb	a4,0(a5)
        uart[0] = '\n';
    80002e92:	fe043783          	ld	a5,-32(s0)
    80002e96:	4729                	li	a4,10
    80002e98:	00e78023          	sb	a4,0(a5)
    80002e9c:	a845                	j	80002f4c <usertrap+0x2e2>
    } else {
        uart[0] = 'E'; uart[0] = 'R'; uart[0] = 'R'; uart[0] = '!';
    80002e9e:	fe043783          	ld	a5,-32(s0)
    80002ea2:	04500713          	li	a4,69
    80002ea6:	00e78023          	sb	a4,0(a5)
    80002eaa:	fe043783          	ld	a5,-32(s0)
    80002eae:	05200713          	li	a4,82
    80002eb2:	00e78023          	sb	a4,0(a5)
    80002eb6:	fe043783          	ld	a5,-32(s0)
    80002eba:	05200713          	li	a4,82
    80002ebe:	00e78023          	sb	a4,0(a5)
    80002ec2:	fe043783          	ld	a5,-32(s0)
    80002ec6:	02100713          	li	a4,33
    80002eca:	00e78023          	sb	a4,0(a5)
        uart[0] = '\n';
    80002ece:	fe043783          	ld	a5,-32(s0)
    80002ed2:	4729                	li	a4,10
    80002ed4:	00e78023          	sb	a4,0(a5)
        
        printf("[usertrap] Unexpected trap from PID %d\n", p->pid);
    80002ed8:	fd843783          	ld	a5,-40(s0)
    80002edc:	439c                	lw	a5,0(a5)
    80002ede:	85be                	mv	a1,a5
    80002ee0:	00005517          	auipc	a0,0x5
    80002ee4:	82050513          	add	a0,a0,-2016 # 80007700 <userret+0x169c>
    80002ee8:	ffffe097          	auipc	ra,0xffffe
    80002eec:	cfe080e7          	jalr	-770(ra) # 80000be6 <printf>
        printf("  scause: %p\n", (void*)cause);
    80002ef0:	fc043783          	ld	a5,-64(s0)
    80002ef4:	85be                	mv	a1,a5
    80002ef6:	00005517          	auipc	a0,0x5
    80002efa:	83250513          	add	a0,a0,-1998 # 80007728 <userret+0x16c4>
    80002efe:	ffffe097          	auipc	ra,0xffffe
    80002f02:	ce8080e7          	jalr	-792(ra) # 80000be6 <printf>
        printf("  sepc:   %p\n", (void*)r_sepc());
    80002f06:	141027f3          	csrr	a5,sepc
    80002f0a:	faf43823          	sd	a5,-80(s0)
    80002f0e:	fb043783          	ld	a5,-80(s0)
    80002f12:	85be                	mv	a1,a5
    80002f14:	00005517          	auipc	a0,0x5
    80002f18:	82450513          	add	a0,a0,-2012 # 80007738 <userret+0x16d4>
    80002f1c:	ffffe097          	auipc	ra,0xffffe
    80002f20:	cca080e7          	jalr	-822(ra) # 80000be6 <printf>
        printf("  stval:  %p\n", (void*)r_stval());
    80002f24:	143027f3          	csrr	a5,stval
    80002f28:	faf43423          	sd	a5,-88(s0)
    80002f2c:	fa843783          	ld	a5,-88(s0)
    80002f30:	85be                	mv	a1,a5
    80002f32:	00005517          	auipc	a0,0x5
    80002f36:	81650513          	add	a0,a0,-2026 # 80007748 <userret+0x16e4>
    80002f3a:	ffffe097          	auipc	ra,0xffffe
    80002f3e:	cac080e7          	jalr	-852(ra) # 80000be6 <printf>
        
        exit_proc(-1);
    80002f42:	557d                	li	a0,-1
    80002f44:	00001097          	auipc	ra,0x1
    80002f48:	2ac080e7          	jalr	684(ra) # 800041f0 <exit_proc>
    }
    
    uart[0] = 'R'; uart[0] = 'E'; uart[0] = 'T'; uart[0] = '\n';
    80002f4c:	fe043783          	ld	a5,-32(s0)
    80002f50:	05200713          	li	a4,82
    80002f54:	00e78023          	sb	a4,0(a5)
    80002f58:	fe043783          	ld	a5,-32(s0)
    80002f5c:	04500713          	li	a4,69
    80002f60:	00e78023          	sb	a4,0(a5)
    80002f64:	fe043783          	ld	a5,-32(s0)
    80002f68:	05400713          	li	a4,84
    80002f6c:	00e78023          	sb	a4,0(a5)
    80002f70:	fe043783          	ld	a5,-32(s0)
    80002f74:	4729                	li	a4,10
    80002f76:	00e78023          	sb	a4,0(a5)
    usertrapret();
    80002f7a:	00000097          	auipc	ra,0x0
    80002f7e:	012080e7          	jalr	18(ra) # 80002f8c <usertrapret>
}
    80002f82:	0001                	nop
    80002f84:	60e6                	ld	ra,88(sp)
    80002f86:	6446                	ld	s0,80(sp)
    80002f88:	6125                	add	sp,sp,96
    80002f8a:	8082                	ret

0000000080002f8c <usertrapret>:

// 返回用户态
void usertrapret(void)
{
    80002f8c:	711d                	add	sp,sp,-96
    80002f8e:	ec86                	sd	ra,88(sp)
    80002f90:	e8a2                	sd	s0,80(sp)
    80002f92:	1080                	add	s0,sp,96
    // ⭐ 原始 UART 输出调试
    volatile char *uart = (volatile char*)0x10000000;
    80002f94:	100007b7          	lui	a5,0x10000
    80002f98:	fef43423          	sd	a5,-24(s0)
    uart[0] = 'U'; uart[0] = 'S'; uart[0] = 'E'; uart[0] = 'R';
    80002f9c:	fe843783          	ld	a5,-24(s0)
    80002fa0:	05500713          	li	a4,85
    80002fa4:	00e78023          	sb	a4,0(a5) # 10000000 <_entry-0x70000000>
    80002fa8:	fe843783          	ld	a5,-24(s0)
    80002fac:	05300713          	li	a4,83
    80002fb0:	00e78023          	sb	a4,0(a5)
    80002fb4:	fe843783          	ld	a5,-24(s0)
    80002fb8:	04500713          	li	a4,69
    80002fbc:	00e78023          	sb	a4,0(a5)
    80002fc0:	fe843783          	ld	a5,-24(s0)
    80002fc4:	05200713          	li	a4,82
    80002fc8:	00e78023          	sb	a4,0(a5)
    uart[0] = 'T'; uart[0] = 'R'; uart[0] = 'A'; uart[0] = 'P';
    80002fcc:	fe843783          	ld	a5,-24(s0)
    80002fd0:	05400713          	li	a4,84
    80002fd4:	00e78023          	sb	a4,0(a5)
    80002fd8:	fe843783          	ld	a5,-24(s0)
    80002fdc:	05200713          	li	a4,82
    80002fe0:	00e78023          	sb	a4,0(a5)
    80002fe4:	fe843783          	ld	a5,-24(s0)
    80002fe8:	04100713          	li	a4,65
    80002fec:	00e78023          	sb	a4,0(a5)
    80002ff0:	fe843783          	ld	a5,-24(s0)
    80002ff4:	05000713          	li	a4,80
    80002ff8:	00e78023          	sb	a4,0(a5)
    uart[0] = 'R'; uart[0] = 'E'; uart[0] = 'T'; uart[0] = '\n';
    80002ffc:	fe843783          	ld	a5,-24(s0)
    80003000:	05200713          	li	a4,82
    80003004:	00e78023          	sb	a4,0(a5)
    80003008:	fe843783          	ld	a5,-24(s0)
    8000300c:	04500713          	li	a4,69
    80003010:	00e78023          	sb	a4,0(a5)
    80003014:	fe843783          	ld	a5,-24(s0)
    80003018:	05400713          	li	a4,84
    8000301c:	00e78023          	sb	a4,0(a5)
    80003020:	fe843783          	ld	a5,-24(s0)
    80003024:	4729                	li	a4,10
    80003026:	00e78023          	sb	a4,0(a5)
    
    struct proc *p = myproc();
    8000302a:	00001097          	auipc	ra,0x1
    8000302e:	9ae080e7          	jalr	-1618(ra) # 800039d8 <myproc>
    80003032:	fea43023          	sd	a0,-32(s0)
    
    uart[0] = '1'; uart[0] = '\n';
    80003036:	fe843783          	ld	a5,-24(s0)
    8000303a:	03100713          	li	a4,49
    8000303e:	00e78023          	sb	a4,0(a5)
    80003042:	fe843783          	ld	a5,-24(s0)
    80003046:	4729                	li	a4,10
    80003048:	00e78023          	sb	a4,0(a5)
    
    w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000304c:	100027f3          	csrr	a5,sstatus
    80003050:	fcf43c23          	sd	a5,-40(s0)
    80003054:	fd843783          	ld	a5,-40(s0)
    80003058:	9bf5                	and	a5,a5,-3
    8000305a:	10079073          	csrw	sstatus,a5
    
    uart[0] = '2'; uart[0] = '\n';
    8000305e:	fe843783          	ld	a5,-24(s0)
    80003062:	03200713          	li	a4,50
    80003066:	00e78023          	sb	a4,0(a5)
    8000306a:	fe843783          	ld	a5,-24(s0)
    8000306e:	4729                	li	a4,10
    80003070:	00e78023          	sb	a4,0(a5)
    
    // ⭐ 不需要再声明，已经在 defs.h 中
    uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80003074:	00003717          	auipc	a4,0x3
    80003078:	f8c70713          	add	a4,a4,-116 # 80006000 <etext>
    8000307c:	00003797          	auipc	a5,0x3
    80003080:	f8478793          	add	a5,a5,-124 # 80006000 <etext>
    80003084:	8f1d                	sub	a4,a4,a5
    80003086:	040007b7          	lui	a5,0x4000
    8000308a:	17fd                	add	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    8000308c:	07b2                	sll	a5,a5,0xc
    8000308e:	97ba                	add	a5,a5,a4
    80003090:	fcf43823          	sd	a5,-48(s0)
    w_stvec(trampoline_uservec);
    80003094:	fd043783          	ld	a5,-48(s0)
    80003098:	10579073          	csrw	stvec,a5
    
    uart[0] = '3'; uart[0] = '\n';
    8000309c:	fe843783          	ld	a5,-24(s0)
    800030a0:	03300713          	li	a4,51
    800030a4:	00e78023          	sb	a4,0(a5)
    800030a8:	fe843783          	ld	a5,-24(s0)
    800030ac:	4729                	li	a4,10
    800030ae:	00e78023          	sb	a4,0(a5)
    
    p->trapframe->kernel_satp = r_satp();
    800030b2:	180027f3          	csrr	a5,satp
    800030b6:	fcf43423          	sd	a5,-56(s0)
    800030ba:	fc843703          	ld	a4,-56(s0)
    800030be:	fe043783          	ld	a5,-32(s0)
    800030c2:	6bdc                	ld	a5,144(a5)
    800030c4:	10e7b423          	sd	a4,264(a5)
    p->trapframe->kernel_sp = p->kstack + KSTACK_SIZE;
    800030c8:	fe043783          	ld	a5,-32(s0)
    800030cc:	67d4                	ld	a3,136(a5)
    800030ce:	fe043783          	ld	a5,-32(s0)
    800030d2:	6bdc                	ld	a5,144(a5)
    800030d4:	6705                	lui	a4,0x1
    800030d6:	9736                	add	a4,a4,a3
    800030d8:	10e7b823          	sd	a4,272(a5)
    p->trapframe->kernel_trap = (uint64)usertrap;
    800030dc:	fe043783          	ld	a5,-32(s0)
    800030e0:	6bdc                	ld	a5,144(a5)
    800030e2:	00000717          	auipc	a4,0x0
    800030e6:	b8870713          	add	a4,a4,-1144 # 80002c6a <usertrap>
    800030ea:	10e7bc23          	sd	a4,280(a5)
    
    uart[0] = '4'; uart[0] = '\n';
    800030ee:	fe843783          	ld	a5,-24(s0)
    800030f2:	03400713          	li	a4,52
    800030f6:	00e78023          	sb	a4,0(a5)
    800030fa:	fe843783          	ld	a5,-24(s0)
    800030fe:	4729                	li	a4,10
    80003100:	00e78023          	sb	a4,0(a5)
    
    uint64 x = r_sstatus();
    80003104:	100027f3          	csrr	a5,sstatus
    80003108:	fcf43023          	sd	a5,-64(s0)
    8000310c:	fc043783          	ld	a5,-64(s0)
    80003110:	faf43c23          	sd	a5,-72(s0)
    x &= ~SSTATUS_SPP;
    80003114:	fb843783          	ld	a5,-72(s0)
    80003118:	eff7f793          	and	a5,a5,-257
    8000311c:	faf43c23          	sd	a5,-72(s0)
    x |= SSTATUS_SPIE;
    80003120:	fb843783          	ld	a5,-72(s0)
    80003124:	0207e793          	or	a5,a5,32
    80003128:	faf43c23          	sd	a5,-72(s0)
    w_sstatus(x);
    8000312c:	fb843783          	ld	a5,-72(s0)
    80003130:	10079073          	csrw	sstatus,a5
    
    uart[0] = '5'; uart[0] = '\n';
    80003134:	fe843783          	ld	a5,-24(s0)
    80003138:	03500713          	li	a4,53
    8000313c:	00e78023          	sb	a4,0(a5)
    80003140:	fe843783          	ld	a5,-24(s0)
    80003144:	4729                	li	a4,10
    80003146:	00e78023          	sb	a4,0(a5)
    
    w_sepc(p->trapframe->sepc);
    8000314a:	fe043783          	ld	a5,-32(s0)
    8000314e:	6bdc                	ld	a5,144(a5)
    80003150:	7ffc                	ld	a5,248(a5)
    80003152:	14179073          	csrw	sepc,a5
    
    uart[0] = '6'; uart[0] = '\n';
    80003156:	fe843783          	ld	a5,-24(s0)
    8000315a:	03600713          	li	a4,54
    8000315e:	00e78023          	sb	a4,0(a5)
    80003162:	fe843783          	ld	a5,-24(s0)
    80003166:	4729                	li	a4,10
    80003168:	00e78023          	sb	a4,0(a5)
    
    uint64 satp = MAKE_SATP(p->pagetable);
    8000316c:	fe043783          	ld	a5,-32(s0)
    80003170:	67fc                	ld	a5,200(a5)
    80003172:	00c7d713          	srl	a4,a5,0xc
    80003176:	57fd                	li	a5,-1
    80003178:	17fe                	sll	a5,a5,0x3f
    8000317a:	8fd9                	or	a5,a5,a4
    8000317c:	faf43823          	sd	a5,-80(s0)
    
    uart[0] = '7'; uart[0] = '\n';
    80003180:	fe843783          	ld	a5,-24(s0)
    80003184:	03700713          	li	a4,55
    80003188:	00e78023          	sb	a4,0(a5)
    8000318c:	fe843783          	ld	a5,-24(s0)
    80003190:	4729                	li	a4,10
    80003192:	00e78023          	sb	a4,0(a5)
    
    // ⭐ 不需要再声明
    uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80003196:	00003717          	auipc	a4,0x3
    8000319a:	ece70713          	add	a4,a4,-306 # 80006064 <userret>
    8000319e:	00003797          	auipc	a5,0x3
    800031a2:	e6278793          	add	a5,a5,-414 # 80006000 <etext>
    800031a6:	8f1d                	sub	a4,a4,a5
    800031a8:	040007b7          	lui	a5,0x4000
    800031ac:	17fd                	add	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    800031ae:	07b2                	sll	a5,a5,0xc
    800031b0:	97ba                	add	a5,a5,a4
    800031b2:	faf43423          	sd	a5,-88(s0)
    
    uart[0] = '8'; uart[0] = '\n';
    800031b6:	fe843783          	ld	a5,-24(s0)
    800031ba:	03800713          	li	a4,56
    800031be:	00e78023          	sb	a4,0(a5)
    800031c2:	fe843783          	ld	a5,-24(s0)
    800031c6:	4729                	li	a4,10
    800031c8:	00e78023          	sb	a4,0(a5)
    
    ((void(*)(uint64,uint64))trampoline_userret)(TRAPFRAME, satp);
    800031cc:	fa843783          	ld	a5,-88(s0)
    800031d0:	fb043583          	ld	a1,-80(s0)
    800031d4:	02000737          	lui	a4,0x2000
    800031d8:	177d                	add	a4,a4,-1 # 1ffffff <_entry-0x7e000001>
    800031da:	00d71513          	sll	a0,a4,0xd
    800031de:	9782                	jalr	a5
    
    uart[0] = 'X'; uart[0] = '\n';
    800031e0:	fe843783          	ld	a5,-24(s0)
    800031e4:	05800713          	li	a4,88
    800031e8:	00e78023          	sb	a4,0(a5)
    800031ec:	fe843783          	ld	a5,-24(s0)
    800031f0:	4729                	li	a4,10
    800031f2:	00e78023          	sb	a4,0(a5)
}
    800031f6:	0001                	nop
    800031f8:	60e6                	ld	ra,88(sp)
    800031fa:	6446                	ld	s0,80(sp)
    800031fc:	6125                	add	sp,sp,96
    800031fe:	8082                	ret

0000000080003200 <trap_cause_name>:

// ==================== 辅助函数 ====================
const char* trap_cause_name(uint64 cause)
{
    80003200:	1101                	add	sp,sp,-32
    80003202:	ec22                	sd	s0,24(sp)
    80003204:	1000                	add	s0,sp,32
    80003206:	fea43423          	sd	a0,-24(s0)
    if(cause & 0x8000000000000000L) {
    8000320a:	fe843783          	ld	a5,-24(s0)
    8000320e:	0807d263          	bgez	a5,80003292 <trap_cause_name+0x92>
        cause = cause & 0xff;
    80003212:	fe843783          	ld	a5,-24(s0)
    80003216:	0ff7f793          	zext.b	a5,a5
    8000321a:	fef43423          	sd	a5,-24(s0)
        switch(cause) {
    8000321e:	fe843703          	ld	a4,-24(s0)
    80003222:	47ad                	li	a5,11
    80003224:	06e7e263          	bltu	a5,a4,80003288 <trap_cause_name+0x88>
    80003228:	fe843783          	ld	a5,-24(s0)
    8000322c:	00279713          	sll	a4,a5,0x2
    80003230:	00004797          	auipc	a5,0x4
    80003234:	72878793          	add	a5,a5,1832 # 80007958 <userret+0x18f4>
    80003238:	97ba                	add	a5,a5,a4
    8000323a:	439c                	lw	a5,0(a5)
    8000323c:	0007871b          	sext.w	a4,a5
    80003240:	00004797          	auipc	a5,0x4
    80003244:	71878793          	add	a5,a5,1816 # 80007958 <userret+0x18f4>
    80003248:	97ba                	add	a5,a5,a4
    8000324a:	8782                	jr	a5
            case IRQ_S_SOFT: return "Supervisor software interrupt";
    8000324c:	00004797          	auipc	a5,0x4
    80003250:	50c78793          	add	a5,a5,1292 # 80007758 <userret+0x16f4>
    80003254:	a201                	j	80003354 <trap_cause_name+0x154>
            case IRQ_M_SOFT: return "Machine software interrupt";
    80003256:	00004797          	auipc	a5,0x4
    8000325a:	52278793          	add	a5,a5,1314 # 80007778 <userret+0x1714>
    8000325e:	a8dd                	j	80003354 <trap_cause_name+0x154>
            case IRQ_S_TIMER: return "Supervisor timer interrupt";
    80003260:	00004797          	auipc	a5,0x4
    80003264:	53878793          	add	a5,a5,1336 # 80007798 <userret+0x1734>
    80003268:	a0f5                	j	80003354 <trap_cause_name+0x154>
            case IRQ_M_TIMER: return "Machine timer interrupt";
    8000326a:	00004797          	auipc	a5,0x4
    8000326e:	54e78793          	add	a5,a5,1358 # 800077b8 <userret+0x1754>
    80003272:	a0cd                	j	80003354 <trap_cause_name+0x154>
            case IRQ_S_EXT: return "Supervisor external interrupt";
    80003274:	00004797          	auipc	a5,0x4
    80003278:	55c78793          	add	a5,a5,1372 # 800077d0 <userret+0x176c>
    8000327c:	a8e1                	j	80003354 <trap_cause_name+0x154>
            case IRQ_M_EXT: return "Machine external interrupt";
    8000327e:	00004797          	auipc	a5,0x4
    80003282:	57278793          	add	a5,a5,1394 # 800077f0 <userret+0x178c>
    80003286:	a0f9                	j	80003354 <trap_cause_name+0x154>
            default: return "Unknown interrupt";
    80003288:	00004797          	auipc	a5,0x4
    8000328c:	58878793          	add	a5,a5,1416 # 80007810 <userret+0x17ac>
    80003290:	a0d1                	j	80003354 <trap_cause_name+0x154>
        }
    } else {
        switch(cause) {
    80003292:	fe843703          	ld	a4,-24(s0)
    80003296:	47bd                	li	a5,15
    80003298:	0ae7ea63          	bltu	a5,a4,8000334c <trap_cause_name+0x14c>
    8000329c:	fe843783          	ld	a5,-24(s0)
    800032a0:	00279713          	sll	a4,a5,0x2
    800032a4:	00004797          	auipc	a5,0x4
    800032a8:	6e478793          	add	a5,a5,1764 # 80007988 <userret+0x1924>
    800032ac:	97ba                	add	a5,a5,a4
    800032ae:	439c                	lw	a5,0(a5)
    800032b0:	0007871b          	sext.w	a4,a5
    800032b4:	00004797          	auipc	a5,0x4
    800032b8:	6d478793          	add	a5,a5,1748 # 80007988 <userret+0x1924>
    800032bc:	97ba                	add	a5,a5,a4
    800032be:	8782                	jr	a5
            case CAUSE_MISALIGNED_FETCH: return "Instruction address misaligned";
    800032c0:	00004797          	auipc	a5,0x4
    800032c4:	56878793          	add	a5,a5,1384 # 80007828 <userret+0x17c4>
    800032c8:	a071                	j	80003354 <trap_cause_name+0x154>
            case CAUSE_FETCH_ACCESS: return "Instruction access fault";
    800032ca:	00004797          	auipc	a5,0x4
    800032ce:	57e78793          	add	a5,a5,1406 # 80007848 <userret+0x17e4>
    800032d2:	a049                	j	80003354 <trap_cause_name+0x154>
            case CAUSE_ILLEGAL_INSTRUCTION: return "Illegal instruction";
    800032d4:	00004797          	auipc	a5,0x4
    800032d8:	23478793          	add	a5,a5,564 # 80007508 <userret+0x14a4>
    800032dc:	a8a5                	j	80003354 <trap_cause_name+0x154>
            case CAUSE_BREAKPOINT: return "Breakpoint";
    800032de:	00004797          	auipc	a5,0x4
    800032e2:	58a78793          	add	a5,a5,1418 # 80007868 <userret+0x1804>
    800032e6:	a0bd                	j	80003354 <trap_cause_name+0x154>
            case CAUSE_MISALIGNED_LOAD: return "Load address misaligned";
    800032e8:	00004797          	auipc	a5,0x4
    800032ec:	59078793          	add	a5,a5,1424 # 80007878 <userret+0x1814>
    800032f0:	a095                	j	80003354 <trap_cause_name+0x154>
            case CAUSE_LOAD_ACCESS: return "Load access fault";
    800032f2:	00004797          	auipc	a5,0x4
    800032f6:	59e78793          	add	a5,a5,1438 # 80007890 <userret+0x182c>
    800032fa:	a8a9                	j	80003354 <trap_cause_name+0x154>
            case CAUSE_MISALIGNED_STORE: return "Store address misaligned";
    800032fc:	00004797          	auipc	a5,0x4
    80003300:	5ac78793          	add	a5,a5,1452 # 800078a8 <userret+0x1844>
    80003304:	a881                	j	80003354 <trap_cause_name+0x154>
            case CAUSE_STORE_ACCESS: return "Store access fault";
    80003306:	00004797          	auipc	a5,0x4
    8000330a:	5c278793          	add	a5,a5,1474 # 800078c8 <userret+0x1864>
    8000330e:	a099                	j	80003354 <trap_cause_name+0x154>
            case CAUSE_USER_ECALL: return "Environment call from U-mode";
    80003310:	00004797          	auipc	a5,0x4
    80003314:	5d078793          	add	a5,a5,1488 # 800078e0 <userret+0x187c>
    80003318:	a835                	j	80003354 <trap_cause_name+0x154>
            case CAUSE_SUPERVISOR_ECALL: return "Environment call from S-mode";
    8000331a:	00004797          	auipc	a5,0x4
    8000331e:	5e678793          	add	a5,a5,1510 # 80007900 <userret+0x189c>
    80003322:	a80d                	j	80003354 <trap_cause_name+0x154>
            case CAUSE_MACHINE_ECALL: return "Environment call from M-mode";
    80003324:	00004797          	auipc	a5,0x4
    80003328:	5fc78793          	add	a5,a5,1532 # 80007920 <userret+0x18bc>
    8000332c:	a025                	j	80003354 <trap_cause_name+0x154>
            case CAUSE_FETCH_PAGE_FAULT: return "Instruction page fault";
    8000332e:	00004797          	auipc	a5,0x4
    80003332:	61278793          	add	a5,a5,1554 # 80007940 <userret+0x18dc>
    80003336:	a839                	j	80003354 <trap_cause_name+0x154>
            case CAUSE_LOAD_PAGE_FAULT: return "Load page fault";
    80003338:	00004797          	auipc	a5,0x4
    8000333c:	0b878793          	add	a5,a5,184 # 800073f0 <userret+0x138c>
    80003340:	a811                	j	80003354 <trap_cause_name+0x154>
            case CAUSE_STORE_PAGE_FAULT: return "Store page fault";
    80003342:	00004797          	auipc	a5,0x4
    80003346:	14e78793          	add	a5,a5,334 # 80007490 <userret+0x142c>
    8000334a:	a029                	j	80003354 <trap_cause_name+0x154>
            default: return "Unknown exception";
    8000334c:	00004797          	auipc	a5,0x4
    80003350:	31478793          	add	a5,a5,788 # 80007660 <userret+0x15fc>
        }
    }
}
    80003354:	853e                	mv	a0,a5
    80003356:	6462                	ld	s0,24(sp)
    80003358:	6105                	add	sp,sp,32
    8000335a:	8082                	ret

000000008000335c <dump_trapframe>:

void dump_trapframe(struct trapframe *tf)
{
    8000335c:	1101                	add	sp,sp,-32
    8000335e:	ec06                	sd	ra,24(sp)
    80003360:	e822                	sd	s0,16(sp)
    80003362:	1000                	add	s0,sp,32
    80003364:	fea43423          	sd	a0,-24(s0)
    printf("=== Trapframe Dump ===\n");
    80003368:	00004517          	auipc	a0,0x4
    8000336c:	66050513          	add	a0,a0,1632 # 800079c8 <userret+0x1964>
    80003370:	ffffe097          	auipc	ra,0xffffe
    80003374:	876080e7          	jalr	-1930(ra) # 80000be6 <printf>
    printf("ra:  %p  sp:  %p  gp:  %p  tp:  %p\n",
           (void*)tf->ra, (void*)tf->sp, (void*)tf->gp, (void*)tf->tp);
    80003378:	fe843783          	ld	a5,-24(s0)
    8000337c:	639c                	ld	a5,0(a5)
    printf("ra:  %p  sp:  %p  gp:  %p  tp:  %p\n",
    8000337e:	85be                	mv	a1,a5
           (void*)tf->ra, (void*)tf->sp, (void*)tf->gp, (void*)tf->tp);
    80003380:	fe843783          	ld	a5,-24(s0)
    80003384:	679c                	ld	a5,8(a5)
    printf("ra:  %p  sp:  %p  gp:  %p  tp:  %p\n",
    80003386:	863e                	mv	a2,a5
           (void*)tf->ra, (void*)tf->sp, (void*)tf->gp, (void*)tf->tp);
    80003388:	fe843783          	ld	a5,-24(s0)
    8000338c:	6b9c                	ld	a5,16(a5)
    printf("ra:  %p  sp:  %p  gp:  %p  tp:  %p\n",
    8000338e:	86be                	mv	a3,a5
           (void*)tf->ra, (void*)tf->sp, (void*)tf->gp, (void*)tf->tp);
    80003390:	fe843783          	ld	a5,-24(s0)
    80003394:	6f9c                	ld	a5,24(a5)
    printf("ra:  %p  sp:  %p  gp:  %p  tp:  %p\n",
    80003396:	873e                	mv	a4,a5
    80003398:	00004517          	auipc	a0,0x4
    8000339c:	64850513          	add	a0,a0,1608 # 800079e0 <userret+0x197c>
    800033a0:	ffffe097          	auipc	ra,0xffffe
    800033a4:	846080e7          	jalr	-1978(ra) # 80000be6 <printf>
    printf("t0:  %p  t1:  %p  t2:  %p\n",
           (void*)tf->t0, (void*)tf->t1, (void*)tf->t2);
    800033a8:	fe843783          	ld	a5,-24(s0)
    800033ac:	739c                	ld	a5,32(a5)
    printf("t0:  %p  t1:  %p  t2:  %p\n",
    800033ae:	873e                	mv	a4,a5
           (void*)tf->t0, (void*)tf->t1, (void*)tf->t2);
    800033b0:	fe843783          	ld	a5,-24(s0)
    800033b4:	779c                	ld	a5,40(a5)
    printf("t0:  %p  t1:  %p  t2:  %p\n",
    800033b6:	863e                	mv	a2,a5
           (void*)tf->t0, (void*)tf->t1, (void*)tf->t2);
    800033b8:	fe843783          	ld	a5,-24(s0)
    800033bc:	7b9c                	ld	a5,48(a5)
    printf("t0:  %p  t1:  %p  t2:  %p\n",
    800033be:	86be                	mv	a3,a5
    800033c0:	85ba                	mv	a1,a4
    800033c2:	00004517          	auipc	a0,0x4
    800033c6:	64650513          	add	a0,a0,1606 # 80007a08 <userret+0x19a4>
    800033ca:	ffffe097          	auipc	ra,0xffffe
    800033ce:	81c080e7          	jalr	-2020(ra) # 80000be6 <printf>
    printf("s0:  %p  s1:  %p\n",
           (void*)tf->s0, (void*)tf->s1);
    800033d2:	fe843783          	ld	a5,-24(s0)
    800033d6:	7f9c                	ld	a5,56(a5)
    printf("s0:  %p  s1:  %p\n",
    800033d8:	873e                	mv	a4,a5
           (void*)tf->s0, (void*)tf->s1);
    800033da:	fe843783          	ld	a5,-24(s0)
    800033de:	63bc                	ld	a5,64(a5)
    printf("s0:  %p  s1:  %p\n",
    800033e0:	863e                	mv	a2,a5
    800033e2:	85ba                	mv	a1,a4
    800033e4:	00004517          	auipc	a0,0x4
    800033e8:	64450513          	add	a0,a0,1604 # 80007a28 <userret+0x19c4>
    800033ec:	ffffd097          	auipc	ra,0xffffd
    800033f0:	7fa080e7          	jalr	2042(ra) # 80000be6 <printf>
    printf("a0:  %p  a1:  %p  a2:  %p  a3:  %p\n",
           (void*)tf->a0, (void*)tf->a1, (void*)tf->a2, (void*)tf->a3);
    800033f4:	fe843783          	ld	a5,-24(s0)
    800033f8:	67bc                	ld	a5,72(a5)
    printf("a0:  %p  a1:  %p  a2:  %p  a3:  %p\n",
    800033fa:	85be                	mv	a1,a5
           (void*)tf->a0, (void*)tf->a1, (void*)tf->a2, (void*)tf->a3);
    800033fc:	fe843783          	ld	a5,-24(s0)
    80003400:	6bbc                	ld	a5,80(a5)
    printf("a0:  %p  a1:  %p  a2:  %p  a3:  %p\n",
    80003402:	863e                	mv	a2,a5
           (void*)tf->a0, (void*)tf->a1, (void*)tf->a2, (void*)tf->a3);
    80003404:	fe843783          	ld	a5,-24(s0)
    80003408:	6fbc                	ld	a5,88(a5)
    printf("a0:  %p  a1:  %p  a2:  %p  a3:  %p\n",
    8000340a:	86be                	mv	a3,a5
           (void*)tf->a0, (void*)tf->a1, (void*)tf->a2, (void*)tf->a3);
    8000340c:	fe843783          	ld	a5,-24(s0)
    80003410:	73bc                	ld	a5,96(a5)
    printf("a0:  %p  a1:  %p  a2:  %p  a3:  %p\n",
    80003412:	873e                	mv	a4,a5
    80003414:	00004517          	auipc	a0,0x4
    80003418:	62c50513          	add	a0,a0,1580 # 80007a40 <userret+0x19dc>
    8000341c:	ffffd097          	auipc	ra,0xffffd
    80003420:	7ca080e7          	jalr	1994(ra) # 80000be6 <printf>
    printf("a4:  %p  a5:  %p  a6:  %p  a7:  %p\n",
           (void*)tf->a4, (void*)tf->a5, (void*)tf->a6, (void*)tf->a7);
    80003424:	fe843783          	ld	a5,-24(s0)
    80003428:	77bc                	ld	a5,104(a5)
    printf("a4:  %p  a5:  %p  a6:  %p  a7:  %p\n",
    8000342a:	85be                	mv	a1,a5
           (void*)tf->a4, (void*)tf->a5, (void*)tf->a6, (void*)tf->a7);
    8000342c:	fe843783          	ld	a5,-24(s0)
    80003430:	7bbc                	ld	a5,112(a5)
    printf("a4:  %p  a5:  %p  a6:  %p  a7:  %p\n",
    80003432:	863e                	mv	a2,a5
           (void*)tf->a4, (void*)tf->a5, (void*)tf->a6, (void*)tf->a7);
    80003434:	fe843783          	ld	a5,-24(s0)
    80003438:	7fbc                	ld	a5,120(a5)
    printf("a4:  %p  a5:  %p  a6:  %p  a7:  %p\n",
    8000343a:	86be                	mv	a3,a5
           (void*)tf->a4, (void*)tf->a5, (void*)tf->a6, (void*)tf->a7);
    8000343c:	fe843783          	ld	a5,-24(s0)
    80003440:	63dc                	ld	a5,128(a5)
    printf("a4:  %p  a5:  %p  a6:  %p  a7:  %p\n",
    80003442:	873e                	mv	a4,a5
    80003444:	00004517          	auipc	a0,0x4
    80003448:	62450513          	add	a0,a0,1572 # 80007a68 <userret+0x1a04>
    8000344c:	ffffd097          	auipc	ra,0xffffd
    80003450:	79a080e7          	jalr	1946(ra) # 80000be6 <printf>
    printf("sepc: %p  sstatus: %p\n",
           (void*)tf->sepc, (void*)tf->sstatus);
    80003454:	fe843783          	ld	a5,-24(s0)
    80003458:	7ffc                	ld	a5,248(a5)
    printf("sepc: %p  sstatus: %p\n",
    8000345a:	873e                	mv	a4,a5
           (void*)tf->sepc, (void*)tf->sstatus);
    8000345c:	fe843783          	ld	a5,-24(s0)
    80003460:	1007b783          	ld	a5,256(a5)
    printf("sepc: %p  sstatus: %p\n",
    80003464:	863e                	mv	a2,a5
    80003466:	85ba                	mv	a1,a4
    80003468:	00004517          	auipc	a0,0x4
    8000346c:	62850513          	add	a0,a0,1576 # 80007a90 <userret+0x1a2c>
    80003470:	ffffd097          	auipc	ra,0xffffd
    80003474:	776080e7          	jalr	1910(ra) # 80000be6 <printf>
    printf("===================\n");
    80003478:	00004517          	auipc	a0,0x4
    8000347c:	63050513          	add	a0,a0,1584 # 80007aa8 <userret+0x1a44>
    80003480:	ffffd097          	auipc	ra,0xffffd
    80003484:	766080e7          	jalr	1894(ra) # 80000be6 <printf>
}
    80003488:	0001                	nop
    8000348a:	60e2                	ld	ra,24(sp)
    8000348c:	6442                	ld	s0,16(sp)
    8000348e:	6105                	add	sp,sp,32
    80003490:	8082                	ret

0000000080003492 <print_trap_stats>:

void print_trap_stats(void)
{
    80003492:	1141                	add	sp,sp,-16
    80003494:	e406                	sd	ra,8(sp)
    80003496:	e022                	sd	s0,0(sp)
    80003498:	0800                	add	s0,sp,16
    printf("\n=== Trap Statistics ===\n");
    8000349a:	00004517          	auipc	a0,0x4
    8000349e:	62650513          	add	a0,a0,1574 # 80007ac0 <userret+0x1a5c>
    800034a2:	ffffd097          	auipc	ra,0xffffd
    800034a6:	744080e7          	jalr	1860(ra) # 80000be6 <printf>
    printf("Timer interrupts:    %d\n", (int)interrupt_counts[IRQ_S_TIMER]);
    800034aa:	0000b797          	auipc	a5,0xb
    800034ae:	b6e78793          	add	a5,a5,-1170 # 8000e018 <interrupt_counts>
    800034b2:	779c                	ld	a5,40(a5)
    800034b4:	2781                	sext.w	a5,a5
    800034b6:	85be                	mv	a1,a5
    800034b8:	00004517          	auipc	a0,0x4
    800034bc:	62850513          	add	a0,a0,1576 # 80007ae0 <userret+0x1a7c>
    800034c0:	ffffd097          	auipc	ra,0xffffd
    800034c4:	726080e7          	jalr	1830(ra) # 80000be6 <printf>
    printf("Software interrupts: %d\n", (int)interrupt_counts[IRQ_S_SOFT]);
    800034c8:	0000b797          	auipc	a5,0xb
    800034cc:	b5078793          	add	a5,a5,-1200 # 8000e018 <interrupt_counts>
    800034d0:	679c                	ld	a5,8(a5)
    800034d2:	2781                	sext.w	a5,a5
    800034d4:	85be                	mv	a1,a5
    800034d6:	00004517          	auipc	a0,0x4
    800034da:	62a50513          	add	a0,a0,1578 # 80007b00 <userret+0x1a9c>
    800034de:	ffffd097          	auipc	ra,0xffffd
    800034e2:	708080e7          	jalr	1800(ra) # 80000be6 <printf>
    printf("External interrupts: %d\n", (int)interrupt_counts[IRQ_S_EXT]);
    800034e6:	0000b797          	auipc	a5,0xb
    800034ea:	b3278793          	add	a5,a5,-1230 # 8000e018 <interrupt_counts>
    800034ee:	67bc                	ld	a5,72(a5)
    800034f0:	2781                	sext.w	a5,a5
    800034f2:	85be                	mv	a1,a5
    800034f4:	00004517          	auipc	a0,0x4
    800034f8:	62c50513          	add	a0,a0,1580 # 80007b20 <userret+0x1abc>
    800034fc:	ffffd097          	auipc	ra,0xffffd
    80003500:	6ea080e7          	jalr	1770(ra) # 80000be6 <printf>
    printf("Exceptions:          %d\n", (int)exception_count);
    80003504:	0000b797          	auipc	a5,0xb
    80003508:	b9478793          	add	a5,a5,-1132 # 8000e098 <exception_count>
    8000350c:	639c                	ld	a5,0(a5)
    8000350e:	2781                	sext.w	a5,a5
    80003510:	85be                	mv	a1,a5
    80003512:	00004517          	auipc	a0,0x4
    80003516:	62e50513          	add	a0,a0,1582 # 80007b40 <userret+0x1adc>
    8000351a:	ffffd097          	auipc	ra,0xffffd
    8000351e:	6cc080e7          	jalr	1740(ra) # 80000be6 <printf>
    printf("====================\n");
    80003522:	00004517          	auipc	a0,0x4
    80003526:	63e50513          	add	a0,a0,1598 # 80007b60 <userret+0x1afc>
    8000352a:	ffffd097          	auipc	ra,0xffffd
    8000352e:	6bc080e7          	jalr	1724(ra) # 80000be6 <printf>
    80003532:	0001                	nop
    80003534:	60a2                	ld	ra,8(sp)
    80003536:	6402                	ld	s0,0(sp)
    80003538:	0141                	add	sp,sp,16
    8000353a:	8082                	ret
    8000353c:	0000                	unimp
	...

0000000080003540 <kernelvec>:
.globl kernelvec

.align 4
kernelvec:
    # ========== 分配栈空间 ==========
    addi sp, sp, -264
    80003540:	ef810113          	add	sp,sp,-264

    # ========== 保存所有寄存器（除sp）==========
    sd ra, 0(sp)
    80003544:	e006                	sd	ra,0(sp)
    sd gp, 16(sp)
    80003546:	e80e                	sd	gp,16(sp)
    sd tp, 24(sp)
    80003548:	ec12                	sd	tp,24(sp)
    sd t0, 32(sp)
    8000354a:	f016                	sd	t0,32(sp)
    sd t1, 40(sp)
    8000354c:	f41a                	sd	t1,40(sp)
    sd t2, 48(sp)
    8000354e:	f81e                	sd	t2,48(sp)
    sd s0, 56(sp)
    80003550:	fc22                	sd	s0,56(sp)
    sd s1, 64(sp)
    80003552:	e0a6                	sd	s1,64(sp)
    sd a0, 72(sp)
    80003554:	e4aa                	sd	a0,72(sp)
    sd a1, 80(sp)
    80003556:	e8ae                	sd	a1,80(sp)
    sd a2, 88(sp)
    80003558:	ecb2                	sd	a2,88(sp)
    sd a3, 96(sp)
    8000355a:	f0b6                	sd	a3,96(sp)
    sd a4, 104(sp)
    8000355c:	f4ba                	sd	a4,104(sp)
    sd a5, 112(sp)
    8000355e:	f8be                	sd	a5,112(sp)
    sd a6, 120(sp)
    80003560:	fcc2                	sd	a6,120(sp)
    sd a7, 128(sp)
    80003562:	e146                	sd	a7,128(sp)
    sd s2, 136(sp)
    80003564:	e54a                	sd	s2,136(sp)
    sd s3, 144(sp)
    80003566:	e94e                	sd	s3,144(sp)
    sd s4, 152(sp)
    80003568:	ed52                	sd	s4,152(sp)
    sd s5, 160(sp)
    8000356a:	f156                	sd	s5,160(sp)
    sd s6, 168(sp)
    8000356c:	f55a                	sd	s6,168(sp)
    sd s7, 176(sp)
    8000356e:	f95e                	sd	s7,176(sp)
    sd s8, 184(sp)
    80003570:	fd62                	sd	s8,184(sp)
    sd s9, 192(sp)
    80003572:	e1e6                	sd	s9,192(sp)
    sd s10, 200(sp)
    80003574:	e5ea                	sd	s10,200(sp)
    sd s11, 208(sp)
    80003576:	e9ee                	sd	s11,208(sp)
    sd t3, 216(sp)
    80003578:	edf2                	sd	t3,216(sp)
    sd t4, 224(sp)
    8000357a:	f1f6                	sd	t4,224(sp)
    sd t5, 232(sp)
    8000357c:	f5fa                	sd	t5,232(sp)
    sd t6, 240(sp)
    8000357e:	f9fe                	sd	t6,240(sp)

    # ========== 保存 sepc 和 sstatus ==========
    csrr t0, sepc
    80003580:	141022f3          	csrr	t0,sepc
    sd t0, 248(sp)
    80003584:	fd96                	sd	t0,248(sp)
    
    csrr t1, sstatus
    80003586:	10002373          	csrr	t1,sstatus
    sd t1, 256(sp)
    8000358a:	e21a                	sd	t1,256(sp)

    # ========== 保存原始 sp ==========
    addi t0, sp, 264
    8000358c:	10810293          	add	t0,sp,264
    sd t0, 8(sp)
    80003590:	e416                	sd	t0,8(sp)

    # ========== 关键：把 trapframe 地址作为参数传递 ==========
    # a0 = trapframe 地址（C函数的第一个参数）
    mv a0, sp
    80003592:	850a                	mv	a0,sp
    
    call kerneltrap
    80003594:	fffff097          	auipc	ra,0xfffff
    80003598:	63c080e7          	jalr	1596(ra) # 80002bd0 <kerneltrap>

    # ========== 恢复 sepc 和 sstatus ==========
    ld t0, 248(sp)
    8000359c:	72ee                	ld	t0,248(sp)
    csrw sepc, t0
    8000359e:	14129073          	csrw	sepc,t0
    
    ld t1, 256(sp)
    800035a2:	6312                	ld	t1,256(sp)
    csrw sstatus, t1
    800035a4:	10031073          	csrw	sstatus,t1

    # ========== 恢复所有寄存器 ==========
    ld ra, 0(sp)
    800035a8:	6082                	ld	ra,0(sp)
    ld gp, 16(sp)
    800035aa:	61c2                	ld	gp,16(sp)
    ld tp, 24(sp)
    800035ac:	6262                	ld	tp,24(sp)
    ld t0, 32(sp)
    800035ae:	7282                	ld	t0,32(sp)
    ld t1, 40(sp)
    800035b0:	7322                	ld	t1,40(sp)
    ld t2, 48(sp)
    800035b2:	73c2                	ld	t2,48(sp)
    ld s0, 56(sp)
    800035b4:	7462                	ld	s0,56(sp)
    ld s1, 64(sp)
    800035b6:	6486                	ld	s1,64(sp)
    ld a0, 72(sp)
    800035b8:	6526                	ld	a0,72(sp)
    ld a1, 80(sp)
    800035ba:	65c6                	ld	a1,80(sp)
    ld a2, 88(sp)
    800035bc:	6666                	ld	a2,88(sp)
    ld a3, 96(sp)
    800035be:	7686                	ld	a3,96(sp)
    ld a4, 104(sp)
    800035c0:	7726                	ld	a4,104(sp)
    ld a5, 112(sp)
    800035c2:	77c6                	ld	a5,112(sp)
    ld a6, 120(sp)
    800035c4:	7866                	ld	a6,120(sp)
    ld a7, 128(sp)
    800035c6:	688a                	ld	a7,128(sp)
    ld s2, 136(sp)
    800035c8:	692a                	ld	s2,136(sp)
    ld s3, 144(sp)
    800035ca:	69ca                	ld	s3,144(sp)
    ld s4, 152(sp)
    800035cc:	6a6a                	ld	s4,152(sp)
    ld s5, 160(sp)
    800035ce:	7a8a                	ld	s5,160(sp)
    ld s6, 168(sp)
    800035d0:	7b2a                	ld	s6,168(sp)
    ld s7, 176(sp)
    800035d2:	7bca                	ld	s7,176(sp)
    ld s8, 184(sp)
    800035d4:	7c6a                	ld	s8,184(sp)
    ld s9, 192(sp)
    800035d6:	6c8e                	ld	s9,192(sp)
    ld s10, 200(sp)
    800035d8:	6d2e                	ld	s10,200(sp)
    ld s11, 208(sp)
    800035da:	6dce                	ld	s11,208(sp)
    ld t3, 216(sp)
    800035dc:	6e6e                	ld	t3,216(sp)
    ld t4, 224(sp)
    800035de:	7e8e                	ld	t4,224(sp)
    ld t5, 232(sp)
    800035e0:	7f2e                	ld	t5,232(sp)
    ld t6, 240(sp)
    800035e2:	7fce                	ld	t6,240(sp)

    # ========== 恢复 sp 并返回 ==========
    addi sp, sp, 264
    800035e4:	10810113          	add	sp,sp,264
    800035e8:	10200073          	sret
    800035ec:	00000013          	nop

00000000800035f0 <timervec>:

.globl timervec
.align 4
timervec:
    # 交换 a0 和 mscratch
    csrrw a0, mscratch, a0
    800035f0:	34051573          	csrrw	a0,mscratch,a0
    # 现在 a0 指向 timer_scratch 结构
    
    # 保存寄存器
    sd a1, 24(a0)
    800035f4:	ed0c                	sd	a1,24(a0)
    sd a2, 32(a0)
    800035f6:	f110                	sd	a2,32(a0)
    sd a3, 40(a0)
    800035f8:	f514                	sd	a3,40(a0)
    
    # 读取当前 mtime
    li a1, 0x200bff8
    800035fa:	0200c5b7          	lui	a1,0x200c
    800035fe:	35e1                	addw	a1,a1,-8 # 200bff8 <_entry-0x7dff4008>
    ld a2, 0(a1)
    80003600:	6190                	ld	a2,0(a1)
    
    # 加上时钟间隔
    ld a3, 0(a0)        # 读取 interval
    80003602:	6114                	ld	a3,0(a0)
    add a2, a2, a3      # next_time = mtime + interval
    80003604:	9636                	add	a2,a2,a3
    sd a2, 8(a0)        # 保存 next_time
    80003606:	e510                	sd	a2,8(a0)
    
    # 设置 mtimecmp
    li a1, 0x2004000
    80003608:	020045b7          	lui	a1,0x2004
    sd a2, 0(a1)
    8000360c:	e190                	sd	a2,0(a1)
    
    # 触发 S 模式软件中断
    li a1, 2
    8000360e:	4589                	li	a1,2
    csrw sip, a1
    80003610:	14459073          	csrw	sip,a1
    
    # 恢复寄存器
    ld a3, 40(a0)
    80003614:	7514                	ld	a3,40(a0)
    ld a2, 32(a0)
    80003616:	7110                	ld	a2,32(a0)
    ld a1, 24(a0)
    80003618:	6d0c                	ld	a1,24(a0)
    
    # 恢复 a0
    csrrw a0, mscratch, a0
    8000361a:	34051573          	csrrw	a0,mscratch,a0
    
    8000361e:	30200073          	mret
    80003622:	0001                	nop
    80003624:	00000013          	nop
    80003628:	00000013          	nop
    8000362c:	00000013          	nop

0000000080003630 <read_mtime>:
};

__attribute__ ((aligned (16))) static struct timer_scratch timer_scratch0;

// ==================== 读取 mtime ====================
static inline uint64 read_mtime(void) {
    80003630:	1141                	add	sp,sp,-16
    80003632:	e422                	sd	s0,8(sp)
    80003634:	0800                	add	s0,sp,16
    return *(volatile uint64*)CLINT_MTIME;
    80003636:	0200c7b7          	lui	a5,0x200c
    8000363a:	17e1                	add	a5,a5,-8 # 200bff8 <_entry-0x7dff4008>
    8000363c:	639c                	ld	a5,0(a5)
}
    8000363e:	853e                	mv	a0,a5
    80003640:	6422                	ld	s0,8(sp)
    80003642:	0141                	add	sp,sp,16
    80003644:	8082                	ret

0000000080003646 <write_mtimecmp>:

// ==================== 写入 mtimecmp ====================
static inline void write_mtimecmp(uint64 value) {
    80003646:	1101                	add	sp,sp,-32
    80003648:	ec22                	sd	s0,24(sp)
    8000364a:	1000                	add	s0,sp,32
    8000364c:	fea43423          	sd	a0,-24(s0)
    *(volatile uint64*)CLINT_MTIMECMP = value;
    80003650:	020047b7          	lui	a5,0x2004
    80003654:	fe843703          	ld	a4,-24(s0)
    80003658:	e398                	sd	a4,0(a5)
}
    8000365a:	0001                	nop
    8000365c:	6462                	ld	s0,24(sp)
    8000365e:	6105                	add	sp,sp,32
    80003660:	8082                	ret

0000000080003662 <timer_init_hart>:

// ==================== 初始化时钟（每个hart调用） ====================
void timer_init_hart(void)
{
    80003662:	1101                	add	sp,sp,-32
    80003664:	ec06                	sd	ra,24(sp)
    80003666:	e822                	sd	s0,16(sp)
    80003668:	1000                	add	s0,sp,32
    // 初始化时钟数据区
    timer_scratch0.interval = timer_interval;
    8000366a:	00006797          	auipc	a5,0x6
    8000366e:	99678793          	add	a5,a5,-1642 # 80009000 <timer_interval>
    80003672:	6398                	ld	a4,0(a5)
    80003674:	0000b797          	auipc	a5,0xb
    80003678:	abc78793          	add	a5,a5,-1348 # 8000e130 <timer_scratch0>
    8000367c:	e398                	sd	a4,0(a5)
    timer_scratch0.next_time = 0;
    8000367e:	0000b797          	auipc	a5,0xb
    80003682:	ab278793          	add	a5,a5,-1358 # 8000e130 <timer_scratch0>
    80003686:	0007b423          	sd	zero,8(a5)
    
    // 将数据区地址存入mscratch
    w_mscratch((uint64)&timer_scratch0);
    8000368a:	0000b797          	auipc	a5,0xb
    8000368e:	aa678793          	add	a5,a5,-1370 # 8000e130 <timer_scratch0>
    80003692:	34079073          	csrw	mscratch,a5
    
    // 直接设置第一次时钟中断
    uint64 mtime = read_mtime();
    80003696:	00000097          	auipc	ra,0x0
    8000369a:	f9a080e7          	jalr	-102(ra) # 80003630 <read_mtime>
    8000369e:	fea43423          	sd	a0,-24(s0)
    write_mtimecmp(mtime + timer_interval);
    800036a2:	00006797          	auipc	a5,0x6
    800036a6:	95e78793          	add	a5,a5,-1698 # 80009000 <timer_interval>
    800036aa:	6398                	ld	a4,0(a5)
    800036ac:	fe843783          	ld	a5,-24(s0)
    800036b0:	97ba                	add	a5,a5,a4
    800036b2:	853e                	mv	a0,a5
    800036b4:	00000097          	auipc	ra,0x0
    800036b8:	f92080e7          	jalr	-110(ra) # 80003646 <write_mtimecmp>
}
    800036bc:	0001                	nop
    800036be:	60e2                	ld	ra,24(sp)
    800036c0:	6442                	ld	s0,16(sp)
    800036c2:	6105                	add	sp,sp,32
    800036c4:	8082                	ret

00000000800036c6 <timer_interrupt>:

// ==================== 时钟中断处理函数 ====================
void timer_interrupt(void)
{
    800036c6:	1101                	add	sp,sp,-32
    800036c8:	ec06                	sd	ra,24(sp)
    800036ca:	e822                	sd	s0,16(sp)
    800036cc:	1000                	add	s0,sp,32
    ticks++;
    800036ce:	0000b797          	auipc	a5,0xb
    800036d2:	a5278793          	add	a5,a5,-1454 # 8000e120 <ticks>
    800036d6:	639c                	ld	a5,0(a5)
    800036d8:	00178713          	add	a4,a5,1
    800036dc:	0000b797          	auipc	a5,0xb
    800036e0:	a4478793          	add	a5,a5,-1468 # 8000e120 <ticks>
    800036e4:	e398                	sd	a4,0(a5)
    
    if(ticks % TICKS_PER_SEC == 0) {
    800036e6:	0000b797          	auipc	a5,0xb
    800036ea:	a3a78793          	add	a5,a5,-1478 # 8000e120 <ticks>
    800036ee:	6398                	ld	a4,0(a5)
    800036f0:	47a9                	li	a5,10
    800036f2:	02f777b3          	remu	a5,a4,a5
    800036f6:	e39d                	bnez	a5,8000371c <timer_interrupt+0x56>
        printf("[Timer] System uptime: %d seconds\n", (int)(ticks / TICKS_PER_SEC));
    800036f8:	0000b797          	auipc	a5,0xb
    800036fc:	a2878793          	add	a5,a5,-1496 # 8000e120 <ticks>
    80003700:	6398                	ld	a4,0(a5)
    80003702:	47a9                	li	a5,10
    80003704:	02f757b3          	divu	a5,a4,a5
    80003708:	2781                	sext.w	a5,a5
    8000370a:	85be                	mv	a1,a5
    8000370c:	00004517          	auipc	a0,0x4
    80003710:	46c50513          	add	a0,a0,1132 # 80007b78 <userret+0x1b14>
    80003714:	ffffd097          	auipc	ra,0xffffd
    80003718:	4d2080e7          	jalr	1234(ra) # 80000be6 <printf>
    
    // 获取当前进程
    extern struct proc* myproc(void);
    extern void yield(void);
    
    struct proc *p = myproc();
    8000371c:	00000097          	auipc	ra,0x0
    80003720:	2bc080e7          	jalr	700(ra) # 800039d8 <myproc>
    80003724:	fea43423          	sd	a0,-24(s0)
    if(p != 0) {
    80003728:	fe843783          	ld	a5,-24(s0)
    8000372c:	c795                	beqz	a5,80003758 <timer_interrupt+0x92>
        // 累加运行时间（每个tick都累加）
        p->run_time++;
    8000372e:	fe843783          	ld	a5,-24(s0)
    80003732:	6fdc                	ld	a5,152(a5)
    80003734:	00178713          	add	a4,a5,1
    80003738:	fe843783          	ld	a5,-24(s0)
    8000373c:	efd8                	sd	a4,152(a5)
        
        // 每10个tick抢占一次
        if(ticks % 10 == 0) {
    8000373e:	0000b797          	auipc	a5,0xb
    80003742:	9e278793          	add	a5,a5,-1566 # 8000e120 <ticks>
    80003746:	6398                	ld	a4,0(a5)
    80003748:	47a9                	li	a5,10
    8000374a:	02f777b3          	remu	a5,a4,a5
    8000374e:	e789                	bnez	a5,80003758 <timer_interrupt+0x92>
            yield();
    80003750:	00000097          	auipc	ra,0x0
    80003754:	668080e7          	jalr	1640(ra) # 80003db8 <yield>
        }
    }
}
    80003758:	0001                	nop
    8000375a:	60e2                	ld	ra,24(sp)
    8000375c:	6442                	ld	s0,16(sp)
    8000375e:	6105                	add	sp,sp,32
    80003760:	8082                	ret

0000000080003762 <get_ticks>:

// ==================== 获取系统运行时间 ====================
uint64 get_ticks(void)
{
    80003762:	1141                	add	sp,sp,-16
    80003764:	e422                	sd	s0,8(sp)
    80003766:	0800                	add	s0,sp,16
    return ticks;
    80003768:	0000b797          	auipc	a5,0xb
    8000376c:	9b878793          	add	a5,a5,-1608 # 8000e120 <ticks>
    80003770:	639c                	ld	a5,0(a5)
}
    80003772:	853e                	mv	a0,a5
    80003774:	6422                	ld	s0,8(sp)
    80003776:	0141                	add	sp,sp,16
    80003778:	8082                	ret

000000008000377a <get_uptime_seconds>:

uint64 get_uptime_seconds(void)
{
    8000377a:	1141                	add	sp,sp,-16
    8000377c:	e422                	sd	s0,8(sp)
    8000377e:	0800                	add	s0,sp,16
    return ticks / TICKS_PER_SEC;
    80003780:	0000b797          	auipc	a5,0xb
    80003784:	9a078793          	add	a5,a5,-1632 # 8000e120 <ticks>
    80003788:	6398                	ld	a4,0(a5)
    8000378a:	47a9                	li	a5,10
    8000378c:	02f757b3          	divu	a5,a4,a5
}
    80003790:	853e                	mv	a0,a5
    80003792:	6422                	ld	s0,8(sp)
    80003794:	0141                	add	sp,sp,16
    80003796:	8082                	ret

0000000080003798 <delay_ms>:

// ==================== 简单的忙等待延时 ====================
void delay_ms(uint64 ms)
{
    80003798:	7179                	add	sp,sp,-48
    8000379a:	f422                	sd	s0,40(sp)
    8000379c:	1800                	add	s0,sp,48
    8000379e:	fca43c23          	sd	a0,-40(s0)
    uint64 start = ticks;
    800037a2:	0000b797          	auipc	a5,0xb
    800037a6:	97e78793          	add	a5,a5,-1666 # 8000e120 <ticks>
    800037aa:	639c                	ld	a5,0(a5)
    800037ac:	fef43423          	sd	a5,-24(s0)
    uint64 target_ticks = (ms * TICKS_PER_SEC) / 1000;
    800037b0:	fd843703          	ld	a4,-40(s0)
    800037b4:	87ba                	mv	a5,a4
    800037b6:	078a                	sll	a5,a5,0x2
    800037b8:	97ba                	add	a5,a5,a4
    800037ba:	0786                	sll	a5,a5,0x1
    800037bc:	873e                	mv	a4,a5
    800037be:	3e800793          	li	a5,1000
    800037c2:	02f757b3          	divu	a5,a4,a5
    800037c6:	fef43023          	sd	a5,-32(s0)
    
    while((ticks - start) < target_ticks) {
    800037ca:	a011                	j	800037ce <delay_ms+0x36>
        asm volatile("nop");
    800037cc:	0001                	nop
    while((ticks - start) < target_ticks) {
    800037ce:	0000b797          	auipc	a5,0xb
    800037d2:	95278793          	add	a5,a5,-1710 # 8000e120 <ticks>
    800037d6:	6398                	ld	a4,0(a5)
    800037d8:	fe843783          	ld	a5,-24(s0)
    800037dc:	40f707b3          	sub	a5,a4,a5
    800037e0:	fe043703          	ld	a4,-32(s0)
    800037e4:	fee7e4e3          	bltu	a5,a4,800037cc <delay_ms+0x34>
    }
}
    800037e8:	0001                	nop
    800037ea:	0001                	nop
    800037ec:	7422                	ld	s0,40(sp)
    800037ee:	6145                	add	sp,sp,48
    800037f0:	8082                	ret

00000000800037f2 <timer_init>:

// ==================== 初始化时钟系统 ====================
void timer_init(void)
{
    800037f2:	1141                	add	sp,sp,-16
    800037f4:	e406                	sd	ra,8(sp)
    800037f6:	e022                	sd	s0,0(sp)
    800037f8:	0800                	add	s0,sp,16
    printf("Initializing timer system...\n");
    800037fa:	00004517          	auipc	a0,0x4
    800037fe:	3a650513          	add	a0,a0,934 # 80007ba0 <userret+0x1b3c>
    80003802:	ffffd097          	auipc	ra,0xffffd
    80003806:	3e4080e7          	jalr	996(ra) # 80000be6 <printf>
    printf("Timer frequency: %d Hz\n", (int)TIMER_FREQ);
    8000380a:	009897b7          	lui	a5,0x989
    8000380e:	68078593          	add	a1,a5,1664 # 989680 <_entry-0x7f676980>
    80003812:	00004517          	auipc	a0,0x4
    80003816:	3ae50513          	add	a0,a0,942 # 80007bc0 <userret+0x1b5c>
    8000381a:	ffffd097          	auipc	ra,0xffffd
    8000381e:	3cc080e7          	jalr	972(ra) # 80000be6 <printf>
    printf("Interrupt interval: %d ms\n", (int)TIMER_INTERVAL_MS);
    80003822:	06400593          	li	a1,100
    80003826:	00004517          	auipc	a0,0x4
    8000382a:	3b250513          	add	a0,a0,946 # 80007bd8 <userret+0x1b74>
    8000382e:	ffffd097          	auipc	ra,0xffffd
    80003832:	3b8080e7          	jalr	952(ra) # 80000be6 <printf>
    
    // 注册时钟中断处理函数
    register_interrupt(IRQ_S_TIMER, timer_interrupt);
    80003836:	00000597          	auipc	a1,0x0
    8000383a:	e9058593          	add	a1,a1,-368 # 800036c6 <timer_interrupt>
    8000383e:	4515                	li	a0,5
    80003840:	fffff097          	auipc	ra,0xfffff
    80003844:	cf6080e7          	jalr	-778(ra) # 80002536 <register_interrupt>
    
    printf("Timer system initialized\n");
    80003848:	00004517          	auipc	a0,0x4
    8000384c:	3b050513          	add	a0,a0,944 # 80007bf8 <userret+0x1b94>
    80003850:	ffffd097          	auipc	ra,0xffffd
    80003854:	396080e7          	jalr	918(ra) # 80000be6 <printf>
    80003858:	0001                	nop
    8000385a:	60a2                	ld	ra,8(sp)
    8000385c:	6402                	ld	s0,0(sp)
    8000385e:	0141                	add	sp,sp,16
    80003860:	8082                	ret

0000000080003862 <forkret>:

static uint64 total_switches = 0;

// ==================== forkret - 第一次返回用户态 ====================
void forkret(void)
{
    80003862:	1101                	add	sp,sp,-32
    80003864:	ec06                	sd	ra,24(sp)
    80003866:	e822                	sd	s0,16(sp)
    80003868:	1000                	add	s0,sp,32
    // ⭐ 调试：先测试是否能执行到这里
    // 使用最原始的方式：直接写UART
    volatile char *uart = (volatile char*)0x10000000;
    8000386a:	100007b7          	lui	a5,0x10000
    8000386e:	fef43423          	sd	a5,-24(s0)
    uart[0] = 'F';  // F = Forkret
    80003872:	fe843783          	ld	a5,-24(s0)
    80003876:	04600713          	li	a4,70
    8000387a:	00e78023          	sb	a4,0(a5) # 10000000 <_entry-0x70000000>
    uart[0] = 'O';
    8000387e:	fe843783          	ld	a5,-24(s0)
    80003882:	04f00713          	li	a4,79
    80003886:	00e78023          	sb	a4,0(a5)
    uart[0] = 'R';
    8000388a:	fe843783          	ld	a5,-24(s0)
    8000388e:	05200713          	li	a4,82
    80003892:	00e78023          	sb	a4,0(a5)
    uart[0] = 'K';
    80003896:	fe843783          	ld	a5,-24(s0)
    8000389a:	04b00713          	li	a4,75
    8000389e:	00e78023          	sb	a4,0(a5)
    uart[0] = '\n';
    800038a2:	fe843783          	ld	a5,-24(s0)
    800038a6:	4729                	li	a4,10
    800038a8:	00e78023          	sb	a4,0(a5)
    
    printf("[forkret] Called! PID=%d\n", myproc()->pid);
    800038ac:	00000097          	auipc	ra,0x0
    800038b0:	12c080e7          	jalr	300(ra) # 800039d8 <myproc>
    800038b4:	87aa                	mv	a5,a0
    800038b6:	439c                	lw	a5,0(a5)
    800038b8:	85be                	mv	a1,a5
    800038ba:	00004517          	auipc	a0,0x4
    800038be:	35e50513          	add	a0,a0,862 # 80007c18 <userret+0x1bb4>
    800038c2:	ffffd097          	auipc	ra,0xffffd
    800038c6:	324080e7          	jalr	804(ra) # 80000be6 <printf>
    
    // 测试：先不调用 usertrapret，看能否执行到这里
    printf("[forkret] About to call usertrapret\n");
    800038ca:	00004517          	auipc	a0,0x4
    800038ce:	36e50513          	add	a0,a0,878 # 80007c38 <userret+0x1bd4>
    800038d2:	ffffd097          	auipc	ra,0xffffd
    800038d6:	314080e7          	jalr	788(ra) # 80000be6 <printf>
    
    usertrapret();
    800038da:	fffff097          	auipc	ra,0xfffff
    800038de:	6b2080e7          	jalr	1714(ra) # 80002f8c <usertrapret>
    
    printf("[forkret] ERROR: Should not reach here!\n");
    800038e2:	00004517          	auipc	a0,0x4
    800038e6:	37e50513          	add	a0,a0,894 # 80007c60 <userret+0x1bfc>
    800038ea:	ffffd097          	auipc	ra,0xffffd
    800038ee:	2fc080e7          	jalr	764(ra) # 80000be6 <printf>
    for(;;);
    800038f2:	0001                	nop
    800038f4:	bffd                	j	800038f2 <forkret+0x90>

00000000800038f6 <procinit>:
}

// ==================== 初始化进程系统 ====================
void procinit(void)
{
    800038f6:	1101                	add	sp,sp,-32
    800038f8:	ec06                	sd	ra,24(sp)
    800038fa:	e822                	sd	s0,16(sp)
    800038fc:	1000                	add	s0,sp,32
    printf("Initializing process system...\n");
    800038fe:	00004517          	auipc	a0,0x4
    80003902:	39250513          	add	a0,a0,914 # 80007c90 <userret+0x1c2c>
    80003906:	ffffd097          	auipc	ra,0xffffd
    8000390a:	2e0080e7          	jalr	736(ra) # 80000be6 <printf>
    printf("NPROC = %d\n", NPROC);
    8000390e:	04000593          	li	a1,64
    80003912:	00004517          	auipc	a0,0x4
    80003916:	39e50513          	add	a0,a0,926 # 80007cb0 <userret+0x1c4c>
    8000391a:	ffffd097          	auipc	ra,0xffffd
    8000391e:	2cc080e7          	jalr	716(ra) # 80000be6 <printf>
    
    // ⭐ 使用 memset 代替循环，快得多
    memset(proc, 0, sizeof(proc));
    80003922:	678d                	lui	a5,0x3
    80003924:	40078613          	add	a2,a5,1024 # 3400 <_entry-0x7fffcc00>
    80003928:	4581                	li	a1,0
    8000392a:	0000b517          	auipc	a0,0xb
    8000392e:	83650513          	add	a0,a0,-1994 # 8000e160 <proc>
    80003932:	ffffd097          	auipc	ra,0xffffd
    80003936:	7dc080e7          	jalr	2012(ra) # 8000110e <memset>
    
    // 显式设置所有进程为 UNUSED
    for(int i = 0; i < NPROC; i++) {
    8000393a:	fe042623          	sw	zero,-20(s0)
    8000393e:	a01d                	j	80003964 <procinit+0x6e>
        proc[i].state = UNUSED;
    80003940:	0000b717          	auipc	a4,0xb
    80003944:	82070713          	add	a4,a4,-2016 # 8000e160 <proc>
    80003948:	fec42683          	lw	a3,-20(s0)
    8000394c:	0d000793          	li	a5,208
    80003950:	02f687b3          	mul	a5,a3,a5
    80003954:	97ba                	add	a5,a5,a4
    80003956:	0007a223          	sw	zero,4(a5)
    for(int i = 0; i < NPROC; i++) {
    8000395a:	fec42783          	lw	a5,-20(s0)
    8000395e:	2785                	addw	a5,a5,1
    80003960:	fef42623          	sw	a5,-20(s0)
    80003964:	fec42783          	lw	a5,-20(s0)
    80003968:	0007871b          	sext.w	a4,a5
    8000396c:	03f00793          	li	a5,63
    80003970:	fce7d8e3          	bge	a5,a4,80003940 <procinit+0x4a>
    }
    
    // 初始化 CPU
    cpus[0].proc = 0;
    80003974:	0000e797          	auipc	a5,0xe
    80003978:	bec78793          	add	a5,a5,-1044 # 80011560 <cpus>
    8000397c:	0007b023          	sd	zero,0(a5)
    cpus[0].noff = 0;
    80003980:	0000e797          	auipc	a5,0xe
    80003984:	be078793          	add	a5,a5,-1056 # 80011560 <cpus>
    80003988:	0607ac23          	sw	zero,120(a5)
    cpus[0].intena = 0;
    8000398c:	0000e797          	auipc	a5,0xe
    80003990:	bd478793          	add	a5,a5,-1068 # 80011560 <cpus>
    80003994:	0607ae23          	sw	zero,124(a5)
    
    total_switches = 0;
    80003998:	0000e797          	auipc	a5,0xe
    8000399c:	c4878793          	add	a5,a5,-952 # 800115e0 <total_switches>
    800039a0:	0007b023          	sd	zero,0(a5)
    
    printf("Process system initialized (max %d processes)\n", NPROC);
    800039a4:	04000593          	li	a1,64
    800039a8:	00004517          	auipc	a0,0x4
    800039ac:	31850513          	add	a0,a0,792 # 80007cc0 <userret+0x1c5c>
    800039b0:	ffffd097          	auipc	ra,0xffffd
    800039b4:	236080e7          	jalr	566(ra) # 80000be6 <printf>
}
    800039b8:	0001                	nop
    800039ba:	60e2                	ld	ra,24(sp)
    800039bc:	6442                	ld	s0,16(sp)
    800039be:	6105                	add	sp,sp,32
    800039c0:	8082                	ret

00000000800039c2 <mycpu>:

// ==================== 获取当前CPU ====================
struct cpu* mycpu(void)
{
    800039c2:	1141                	add	sp,sp,-16
    800039c4:	e422                	sd	s0,8(sp)
    800039c6:	0800                	add	s0,sp,16
    return &cpus[0];
    800039c8:	0000e797          	auipc	a5,0xe
    800039cc:	b9878793          	add	a5,a5,-1128 # 80011560 <cpus>
}
    800039d0:	853e                	mv	a0,a5
    800039d2:	6422                	ld	s0,8(sp)
    800039d4:	0141                	add	sp,sp,16
    800039d6:	8082                	ret

00000000800039d8 <myproc>:

// ==================== 获取当前进程 ====================
struct proc* myproc(void)
{
    800039d8:	1101                	add	sp,sp,-32
    800039da:	ec06                	sd	ra,24(sp)
    800039dc:	e822                	sd	s0,16(sp)
    800039de:	1000                	add	s0,sp,32
    push_off();
    800039e0:	00000097          	auipc	ra,0x0
    800039e4:	2e6080e7          	jalr	742(ra) # 80003cc6 <push_off>
    struct cpu *c = mycpu();
    800039e8:	00000097          	auipc	ra,0x0
    800039ec:	fda080e7          	jalr	-38(ra) # 800039c2 <mycpu>
    800039f0:	fea43423          	sd	a0,-24(s0)
    struct proc *p = c->proc;
    800039f4:	fe843783          	ld	a5,-24(s0)
    800039f8:	639c                	ld	a5,0(a5)
    800039fa:	fef43023          	sd	a5,-32(s0)
    pop_off();
    800039fe:	00000097          	auipc	ra,0x0
    80003a02:	32c080e7          	jalr	812(ra) # 80003d2a <pop_off>
    return p;
    80003a06:	fe043783          	ld	a5,-32(s0)
}
    80003a0a:	853e                	mv	a0,a5
    80003a0c:	60e2                	ld	ra,24(sp)
    80003a0e:	6442                	ld	s0,16(sp)
    80003a10:	6105                	add	sp,sp,32
    80003a12:	8082                	ret

0000000080003a14 <alloc_proc>:

// ==================== 分配进程结构 ====================
struct proc* alloc_proc(void)
{
    80003a14:	1101                	add	sp,sp,-32
    80003a16:	ec06                	sd	ra,24(sp)
    80003a18:	e822                	sd	s0,16(sp)
    80003a1a:	1000                	add	s0,sp,32
    struct proc *p;
    
    for(p = proc; p < &proc[NPROC]; p++) {
    80003a1c:	0000a797          	auipc	a5,0xa
    80003a20:	74478793          	add	a5,a5,1860 # 8000e160 <proc>
    80003a24:	fef43423          	sd	a5,-24(s0)
    80003a28:	a819                	j	80003a3e <alloc_proc+0x2a>
        if(p->state == UNUSED) {
    80003a2a:	fe843783          	ld	a5,-24(s0)
    80003a2e:	43dc                	lw	a5,4(a5)
    80003a30:	c38d                	beqz	a5,80003a52 <alloc_proc+0x3e>
    for(p = proc; p < &proc[NPROC]; p++) {
    80003a32:	fe843783          	ld	a5,-24(s0)
    80003a36:	0d078793          	add	a5,a5,208
    80003a3a:	fef43423          	sd	a5,-24(s0)
    80003a3e:	fe843703          	ld	a4,-24(s0)
    80003a42:	0000e797          	auipc	a5,0xe
    80003a46:	b1e78793          	add	a5,a5,-1250 # 80011560 <cpus>
    80003a4a:	fef760e3          	bltu	a4,a5,80003a2a <alloc_proc+0x16>
            goto found;
        }
    }
    return 0;
    80003a4e:	4781                	li	a5,0
    80003a50:	a201                	j	80003b50 <alloc_proc+0x13c>
            goto found;
    80003a52:	0001                	nop
    
found:
    p->pid = nextpid++;
    80003a54:	00005797          	auipc	a5,0x5
    80003a58:	5b478793          	add	a5,a5,1460 # 80009008 <nextpid>
    80003a5c:	439c                	lw	a5,0(a5)
    80003a5e:	0017871b          	addw	a4,a5,1
    80003a62:	0007069b          	sext.w	a3,a4
    80003a66:	00005717          	auipc	a4,0x5
    80003a6a:	5a270713          	add	a4,a4,1442 # 80009008 <nextpid>
    80003a6e:	c314                	sw	a3,0(a4)
    80003a70:	fe843703          	ld	a4,-24(s0)
    80003a74:	c31c                	sw	a5,0(a4)
    p->state = USED;
    80003a76:	fe843783          	ld	a5,-24(s0)
    80003a7a:	4705                	li	a4,1
    80003a7c:	c3d8                	sw	a4,4(a5)
    
    p->kstack = (uint64)alloc_page();
    80003a7e:	ffffe097          	auipc	ra,0xffffe
    80003a82:	86a080e7          	jalr	-1942(ra) # 800012e8 <alloc_page>
    80003a86:	87aa                	mv	a5,a0
    80003a88:	873e                	mv	a4,a5
    80003a8a:	fe843783          	ld	a5,-24(s0)
    80003a8e:	e7d8                	sd	a4,136(a5)
    if(p->kstack == 0) {
    80003a90:	fe843783          	ld	a5,-24(s0)
    80003a94:	67dc                	ld	a5,136(a5)
    80003a96:	e799                	bnez	a5,80003aa4 <alloc_proc+0x90>
        p->state = UNUSED;
    80003a98:	fe843783          	ld	a5,-24(s0)
    80003a9c:	0007a223          	sw	zero,4(a5)
        return 0;
    80003aa0:	4781                	li	a5,0
    80003aa2:	a07d                	j	80003b50 <alloc_proc+0x13c>
    }
    
    p->trapframe = (struct trapframe*)alloc_page();
    80003aa4:	ffffe097          	auipc	ra,0xffffe
    80003aa8:	844080e7          	jalr	-1980(ra) # 800012e8 <alloc_page>
    80003aac:	872a                	mv	a4,a0
    80003aae:	fe843783          	ld	a5,-24(s0)
    80003ab2:	ebd8                	sd	a4,144(a5)
    if(p->trapframe == 0) {
    80003ab4:	fe843783          	ld	a5,-24(s0)
    80003ab8:	6bdc                	ld	a5,144(a5)
    80003aba:	e39d                	bnez	a5,80003ae0 <alloc_proc+0xcc>
        free_page((void*)p->kstack);
    80003abc:	fe843783          	ld	a5,-24(s0)
    80003ac0:	67dc                	ld	a5,136(a5)
    80003ac2:	853e                	mv	a0,a5
    80003ac4:	ffffe097          	auipc	ra,0xffffe
    80003ac8:	886080e7          	jalr	-1914(ra) # 8000134a <free_page>
        p->kstack = 0;
    80003acc:	fe843783          	ld	a5,-24(s0)
    80003ad0:	0807b423          	sd	zero,136(a5)
        p->state = UNUSED;
    80003ad4:	fe843783          	ld	a5,-24(s0)
    80003ad8:	0007a223          	sw	zero,4(a5)
        return 0;
    80003adc:	4781                	li	a5,0
    80003ade:	a88d                	j	80003b50 <alloc_proc+0x13c>
    }
    memset(p->trapframe, 0, sizeof(struct trapframe));
    80003ae0:	fe843783          	ld	a5,-24(s0)
    80003ae4:	6bdc                	ld	a5,144(a5)
    80003ae6:	12000613          	li	a2,288
    80003aea:	4581                	li	a1,0
    80003aec:	853e                	mv	a0,a5
    80003aee:	ffffd097          	auipc	ra,0xffffd
    80003af2:	620080e7          	jalr	1568(ra) # 8000110e <memset>
    
    memset(&p->context, 0, sizeof(p->context));
    80003af6:	fe843783          	ld	a5,-24(s0)
    80003afa:	07e1                	add	a5,a5,24
    80003afc:	07000613          	li	a2,112
    80003b00:	4581                	li	a1,0
    80003b02:	853e                	mv	a0,a5
    80003b04:	ffffd097          	auipc	ra,0xffffd
    80003b08:	60a080e7          	jalr	1546(ra) # 8000110e <memset>
    p->parent = 0;
    80003b0c:	fe843783          	ld	a5,-24(s0)
    80003b10:	0a07b423          	sd	zero,168(a5)
    p->xstate = 0;
    80003b14:	fe843783          	ld	a5,-24(s0)
    80003b18:	0a07a823          	sw	zero,176(a5)
    p->killed = 0;
    80003b1c:	fe843783          	ld	a5,-24(s0)
    80003b20:	0c07a023          	sw	zero,192(a5)
    p->chan = 0;
    80003b24:	fe843783          	ld	a5,-24(s0)
    80003b28:	0a07bc23          	sd	zero,184(a5)
    p->run_time = 0;
    80003b2c:	fe843783          	ld	a5,-24(s0)
    80003b30:	0807bc23          	sd	zero,152(a5)
    p->create_time = get_ticks();
    80003b34:	00000097          	auipc	ra,0x0
    80003b38:	c2e080e7          	jalr	-978(ra) # 80003762 <get_ticks>
    80003b3c:	872a                	mv	a4,a0
    80003b3e:	fe843783          	ld	a5,-24(s0)
    80003b42:	f3d8                	sd	a4,160(a5)
    p->pagetable = 0;
    80003b44:	fe843783          	ld	a5,-24(s0)
    80003b48:	0c07b423          	sd	zero,200(a5)
    
    return p;
    80003b4c:	fe843783          	ld	a5,-24(s0)
}
    80003b50:	853e                	mv	a0,a5
    80003b52:	60e2                	ld	ra,24(sp)
    80003b54:	6442                	ld	s0,16(sp)
    80003b56:	6105                	add	sp,sp,32
    80003b58:	8082                	ret

0000000080003b5a <free_proc>:

// ==================== 释放进程资源 ====================
void free_proc(struct proc *p)
{
    80003b5a:	1101                	add	sp,sp,-32
    80003b5c:	ec06                	sd	ra,24(sp)
    80003b5e:	e822                	sd	s0,16(sp)
    80003b60:	1000                	add	s0,sp,32
    80003b62:	fea43423          	sd	a0,-24(s0)
    if(p->kstack) {
    80003b66:	fe843783          	ld	a5,-24(s0)
    80003b6a:	67dc                	ld	a5,136(a5)
    80003b6c:	cf89                	beqz	a5,80003b86 <free_proc+0x2c>
        free_page((void*)p->kstack);
    80003b6e:	fe843783          	ld	a5,-24(s0)
    80003b72:	67dc                	ld	a5,136(a5)
    80003b74:	853e                	mv	a0,a5
    80003b76:	ffffd097          	auipc	ra,0xffffd
    80003b7a:	7d4080e7          	jalr	2004(ra) # 8000134a <free_page>
        p->kstack = 0;
    80003b7e:	fe843783          	ld	a5,-24(s0)
    80003b82:	0807b423          	sd	zero,136(a5)
    }
    
    if(p->trapframe) {
    80003b86:	fe843783          	ld	a5,-24(s0)
    80003b8a:	6bdc                	ld	a5,144(a5)
    80003b8c:	cf89                	beqz	a5,80003ba6 <free_proc+0x4c>
        free_page((void*)p->trapframe);
    80003b8e:	fe843783          	ld	a5,-24(s0)
    80003b92:	6bdc                	ld	a5,144(a5)
    80003b94:	853e                	mv	a0,a5
    80003b96:	ffffd097          	auipc	ra,0xffffd
    80003b9a:	7b4080e7          	jalr	1972(ra) # 8000134a <free_page>
        p->trapframe = 0;
    80003b9e:	fe843783          	ld	a5,-24(s0)
    80003ba2:	0807b823          	sd	zero,144(a5)
    }
    
    p->pid = 0;
    80003ba6:	fe843783          	ld	a5,-24(s0)
    80003baa:	0007a023          	sw	zero,0(a5)
    p->parent = 0;
    80003bae:	fe843783          	ld	a5,-24(s0)
    80003bb2:	0a07b423          	sd	zero,168(a5)
    p->name[0] = 0;
    80003bb6:	fe843783          	ld	a5,-24(s0)
    80003bba:	00078423          	sb	zero,8(a5)
    p->killed = 0;
    80003bbe:	fe843783          	ld	a5,-24(s0)
    80003bc2:	0c07a023          	sw	zero,192(a5)
    p->xstate = 0;
    80003bc6:	fe843783          	ld	a5,-24(s0)
    80003bca:	0a07a823          	sw	zero,176(a5)
    p->state = UNUSED;
    80003bce:	fe843783          	ld	a5,-24(s0)
    80003bd2:	0007a223          	sw	zero,4(a5)
}
    80003bd6:	0001                	nop
    80003bd8:	60e2                	ld	ra,24(sp)
    80003bda:	6442                	ld	s0,16(sp)
    80003bdc:	6105                	add	sp,sp,32
    80003bde:	8082                	ret

0000000080003be0 <kthread_create>:

// ==================== 创建内核线程 ====================
int kthread_create(void (*fn)(void), char *name)
{
    80003be0:	7179                	add	sp,sp,-48
    80003be2:	f406                	sd	ra,40(sp)
    80003be4:	f022                	sd	s0,32(sp)
    80003be6:	1800                	add	s0,sp,48
    80003be8:	fca43c23          	sd	a0,-40(s0)
    80003bec:	fcb43823          	sd	a1,-48(s0)
    struct proc *p = alloc_proc();
    80003bf0:	00000097          	auipc	ra,0x0
    80003bf4:	e24080e7          	jalr	-476(ra) # 80003a14 <alloc_proc>
    80003bf8:	fea43023          	sd	a0,-32(s0)
    if(p == 0) {
    80003bfc:	fe043783          	ld	a5,-32(s0)
    80003c00:	e399                	bnez	a5,80003c06 <kthread_create+0x26>
        return -1;
    80003c02:	57fd                	li	a5,-1
    80003c04:	a865                	j	80003cbc <kthread_create+0xdc>
    }
    
    int i;
    for(i = 0; name[i] && i < 15; i++) {
    80003c06:	fe042623          	sw	zero,-20(s0)
    80003c0a:	a025                	j	80003c32 <kthread_create+0x52>
        p->name[i] = name[i];
    80003c0c:	fec42783          	lw	a5,-20(s0)
    80003c10:	fd043703          	ld	a4,-48(s0)
    80003c14:	97ba                	add	a5,a5,a4
    80003c16:	0007c703          	lbu	a4,0(a5)
    80003c1a:	fe043683          	ld	a3,-32(s0)
    80003c1e:	fec42783          	lw	a5,-20(s0)
    80003c22:	97b6                	add	a5,a5,a3
    80003c24:	00e78423          	sb	a4,8(a5)
    for(i = 0; name[i] && i < 15; i++) {
    80003c28:	fec42783          	lw	a5,-20(s0)
    80003c2c:	2785                	addw	a5,a5,1
    80003c2e:	fef42623          	sw	a5,-20(s0)
    80003c32:	fec42783          	lw	a5,-20(s0)
    80003c36:	fd043703          	ld	a4,-48(s0)
    80003c3a:	97ba                	add	a5,a5,a4
    80003c3c:	0007c783          	lbu	a5,0(a5)
    80003c40:	cb81                	beqz	a5,80003c50 <kthread_create+0x70>
    80003c42:	fec42783          	lw	a5,-20(s0)
    80003c46:	0007871b          	sext.w	a4,a5
    80003c4a:	47b9                	li	a5,14
    80003c4c:	fce7d0e3          	bge	a5,a4,80003c0c <kthread_create+0x2c>
    }
    p->name[i] = 0;
    80003c50:	fe043703          	ld	a4,-32(s0)
    80003c54:	fec42783          	lw	a5,-20(s0)
    80003c58:	97ba                	add	a5,a5,a4
    80003c5a:	00078423          	sb	zero,8(a5)
    
    memset(&p->context, 0, sizeof(p->context));
    80003c5e:	fe043783          	ld	a5,-32(s0)
    80003c62:	07e1                	add	a5,a5,24
    80003c64:	07000613          	li	a2,112
    80003c68:	4581                	li	a1,0
    80003c6a:	853e                	mv	a0,a5
    80003c6c:	ffffd097          	auipc	ra,0xffffd
    80003c70:	4a2080e7          	jalr	1186(ra) # 8000110e <memset>
    p->context.ra = (uint64)fn;
    80003c74:	fd843703          	ld	a4,-40(s0)
    80003c78:	fe043783          	ld	a5,-32(s0)
    80003c7c:	ef98                	sd	a4,24(a5)
    p->context.sp = p->kstack + KSTACK_SIZE;
    80003c7e:	fe043783          	ld	a5,-32(s0)
    80003c82:	67d8                	ld	a4,136(a5)
    80003c84:	6785                	lui	a5,0x1
    80003c86:	973e                	add	a4,a4,a5
    80003c88:	fe043783          	ld	a5,-32(s0)
    80003c8c:	f398                	sd	a4,32(a5)
    
    p->state = RUNNABLE;
    80003c8e:	fe043783          	ld	a5,-32(s0)
    80003c92:	4709                	li	a4,2
    80003c94:	c3d8                	sw	a4,4(a5)
    
    printf("Created kernel thread: PID=%d, name=%s\n", p->pid, p->name);
    80003c96:	fe043783          	ld	a5,-32(s0)
    80003c9a:	4398                	lw	a4,0(a5)
    80003c9c:	fe043783          	ld	a5,-32(s0)
    80003ca0:	07a1                	add	a5,a5,8 # 1008 <_entry-0x7fffeff8>
    80003ca2:	863e                	mv	a2,a5
    80003ca4:	85ba                	mv	a1,a4
    80003ca6:	00004517          	auipc	a0,0x4
    80003caa:	04a50513          	add	a0,a0,74 # 80007cf0 <userret+0x1c8c>
    80003cae:	ffffd097          	auipc	ra,0xffffd
    80003cb2:	f38080e7          	jalr	-200(ra) # 80000be6 <printf>
    
    return p->pid;
    80003cb6:	fe043783          	ld	a5,-32(s0)
    80003cba:	439c                	lw	a5,0(a5)
}
    80003cbc:	853e                	mv	a0,a5
    80003cbe:	70a2                	ld	ra,40(sp)
    80003cc0:	7402                	ld	s0,32(sp)
    80003cc2:	6145                	add	sp,sp,48
    80003cc4:	8082                	ret

0000000080003cc6 <push_off>:

// ==================== 中断控制 ====================
void push_off(void)
{
    80003cc6:	7179                	add	sp,sp,-48
    80003cc8:	f422                	sd	s0,40(sp)
    80003cca:	1800                	add	s0,sp,48
    int old = r_sstatus() & SSTATUS_SIE;
    80003ccc:	100027f3          	csrr	a5,sstatus
    80003cd0:	fef43423          	sd	a5,-24(s0)
    80003cd4:	fe843783          	ld	a5,-24(s0)
    80003cd8:	2781                	sext.w	a5,a5
    80003cda:	8b89                	and	a5,a5,2
    80003cdc:	fef42223          	sw	a5,-28(s0)
    w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80003ce0:	100027f3          	csrr	a5,sstatus
    80003ce4:	fcf43c23          	sd	a5,-40(s0)
    80003ce8:	fd843783          	ld	a5,-40(s0)
    80003cec:	9bf5                	and	a5,a5,-3
    80003cee:	10079073          	csrw	sstatus,a5
    
    struct cpu *c = &cpus[0];
    80003cf2:	0000e797          	auipc	a5,0xe
    80003cf6:	86e78793          	add	a5,a5,-1938 # 80011560 <cpus>
    80003cfa:	fcf43823          	sd	a5,-48(s0)
    if(c->noff == 0) {
    80003cfe:	fd043783          	ld	a5,-48(s0)
    80003d02:	5fbc                	lw	a5,120(a5)
    80003d04:	e791                	bnez	a5,80003d10 <push_off+0x4a>
        c->intena = old;
    80003d06:	fd043783          	ld	a5,-48(s0)
    80003d0a:	fe442703          	lw	a4,-28(s0)
    80003d0e:	dff8                	sw	a4,124(a5)
    }
    c->noff += 1;
    80003d10:	fd043783          	ld	a5,-48(s0)
    80003d14:	5fbc                	lw	a5,120(a5)
    80003d16:	2785                	addw	a5,a5,1
    80003d18:	0007871b          	sext.w	a4,a5
    80003d1c:	fd043783          	ld	a5,-48(s0)
    80003d20:	dfb8                	sw	a4,120(a5)
}
    80003d22:	0001                	nop
    80003d24:	7422                	ld	s0,40(sp)
    80003d26:	6145                	add	sp,sp,48
    80003d28:	8082                	ret

0000000080003d2a <pop_off>:

void pop_off(void)
{
    80003d2a:	7179                	add	sp,sp,-48
    80003d2c:	f406                	sd	ra,40(sp)
    80003d2e:	f022                	sd	s0,32(sp)
    80003d30:	1800                	add	s0,sp,48
    struct cpu *c = &cpus[0];
    80003d32:	0000e797          	auipc	a5,0xe
    80003d36:	82e78793          	add	a5,a5,-2002 # 80011560 <cpus>
    80003d3a:	fef43423          	sd	a5,-24(s0)
    
    if((r_sstatus() & SSTATUS_SIE) != 0) {
    80003d3e:	100027f3          	csrr	a5,sstatus
    80003d42:	fef43023          	sd	a5,-32(s0)
    80003d46:	fe043783          	ld	a5,-32(s0)
    80003d4a:	8b89                	and	a5,a5,2
    80003d4c:	cb89                	beqz	a5,80003d5e <pop_off+0x34>
        panic("pop_off: interruptible");
    80003d4e:	00004517          	auipc	a0,0x4
    80003d52:	fca50513          	add	a0,a0,-54 # 80007d18 <userret+0x1cb4>
    80003d56:	ffffd097          	auipc	ra,0xffffd
    80003d5a:	236080e7          	jalr	566(ra) # 80000f8c <panic>
    }
    if(c->noff < 1) {
    80003d5e:	fe843783          	ld	a5,-24(s0)
    80003d62:	5fbc                	lw	a5,120(a5)
    80003d64:	00f04a63          	bgtz	a5,80003d78 <pop_off+0x4e>
        panic("pop_off");
    80003d68:	00004517          	auipc	a0,0x4
    80003d6c:	fc850513          	add	a0,a0,-56 # 80007d30 <userret+0x1ccc>
    80003d70:	ffffd097          	auipc	ra,0xffffd
    80003d74:	21c080e7          	jalr	540(ra) # 80000f8c <panic>
    }
    
    c->noff -= 1;
    80003d78:	fe843783          	ld	a5,-24(s0)
    80003d7c:	5fbc                	lw	a5,120(a5)
    80003d7e:	37fd                	addw	a5,a5,-1
    80003d80:	0007871b          	sext.w	a4,a5
    80003d84:	fe843783          	ld	a5,-24(s0)
    80003d88:	dfb8                	sw	a4,120(a5)
    if(c->noff == 0 && c->intena) {
    80003d8a:	fe843783          	ld	a5,-24(s0)
    80003d8e:	5fbc                	lw	a5,120(a5)
    80003d90:	ef99                	bnez	a5,80003dae <pop_off+0x84>
    80003d92:	fe843783          	ld	a5,-24(s0)
    80003d96:	5ffc                	lw	a5,124(a5)
    80003d98:	cb99                	beqz	a5,80003dae <pop_off+0x84>
        w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003d9a:	100027f3          	csrr	a5,sstatus
    80003d9e:	fcf43c23          	sd	a5,-40(s0)
    80003da2:	fd843783          	ld	a5,-40(s0)
    80003da6:	0027e793          	or	a5,a5,2
    80003daa:	10079073          	csrw	sstatus,a5
    }
}
    80003dae:	0001                	nop
    80003db0:	70a2                	ld	ra,40(sp)
    80003db2:	7402                	ld	s0,32(sp)
    80003db4:	6145                	add	sp,sp,48
    80003db6:	8082                	ret

0000000080003db8 <yield>:

// ==================== 主动放弃CPU ====================
void yield(void)
{
    80003db8:	1101                	add	sp,sp,-32
    80003dba:	ec06                	sd	ra,24(sp)
    80003dbc:	e822                	sd	s0,16(sp)
    80003dbe:	1000                	add	s0,sp,32
    struct proc *p = myproc();
    80003dc0:	00000097          	auipc	ra,0x0
    80003dc4:	c18080e7          	jalr	-1000(ra) # 800039d8 <myproc>
    80003dc8:	fea43423          	sd	a0,-24(s0)
    if(p == 0) return;
    80003dcc:	fe843783          	ld	a5,-24(s0)
    80003dd0:	c39d                	beqz	a5,80003df6 <yield+0x3e>
    
    w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80003dd2:	100027f3          	csrr	a5,sstatus
    80003dd6:	fef43023          	sd	a5,-32(s0)
    80003dda:	fe043783          	ld	a5,-32(s0)
    80003dde:	9bf5                	and	a5,a5,-3
    80003de0:	10079073          	csrw	sstatus,a5
    
    p->state = RUNNABLE;
    80003de4:	fe843783          	ld	a5,-24(s0)
    80003de8:	4709                	li	a4,2
    80003dea:	c3d8                	sw	a4,4(a5)
    sched();
    80003dec:	00000097          	auipc	ra,0x0
    80003df0:	014080e7          	jalr	20(ra) # 80003e00 <sched>
    80003df4:	a011                	j	80003df8 <yield+0x40>
    if(p == 0) return;
    80003df6:	0001                	nop
}
    80003df8:	60e2                	ld	ra,24(sp)
    80003dfa:	6442                	ld	s0,16(sp)
    80003dfc:	6105                	add	sp,sp,32
    80003dfe:	8082                	ret

0000000080003e00 <sched>:

// ==================== 切换到调度器 ====================
void sched(void)
{
    80003e00:	7179                	add	sp,sp,-48
    80003e02:	f406                	sd	ra,40(sp)
    80003e04:	f022                	sd	s0,32(sp)
    80003e06:	1800                	add	s0,sp,48
    struct proc *p = myproc();
    80003e08:	00000097          	auipc	ra,0x0
    80003e0c:	bd0080e7          	jalr	-1072(ra) # 800039d8 <myproc>
    80003e10:	fea43423          	sd	a0,-24(s0)
    struct cpu *c = mycpu();
    80003e14:	00000097          	auipc	ra,0x0
    80003e18:	bae080e7          	jalr	-1106(ra) # 800039c2 <mycpu>
    80003e1c:	fea43023          	sd	a0,-32(s0)
    
    int intena = c->intena;
    80003e20:	fe043783          	ld	a5,-32(s0)
    80003e24:	5ffc                	lw	a5,124(a5)
    80003e26:	fcf42e23          	sw	a5,-36(s0)
    total_switches++;
    80003e2a:	0000d797          	auipc	a5,0xd
    80003e2e:	7b678793          	add	a5,a5,1974 # 800115e0 <total_switches>
    80003e32:	639c                	ld	a5,0(a5)
    80003e34:	00178713          	add	a4,a5,1
    80003e38:	0000d797          	auipc	a5,0xd
    80003e3c:	7a878793          	add	a5,a5,1960 # 800115e0 <total_switches>
    80003e40:	e398                	sd	a4,0(a5)
    swtch(&p->context, &c->context);
    80003e42:	fe843783          	ld	a5,-24(s0)
    80003e46:	01878713          	add	a4,a5,24
    80003e4a:	fe043783          	ld	a5,-32(s0)
    80003e4e:	07a1                	add	a5,a5,8
    80003e50:	85be                	mv	a1,a5
    80003e52:	853a                	mv	a0,a4
    80003e54:	00001097          	auipc	ra,0x1
    80003e58:	a76080e7          	jalr	-1418(ra) # 800048ca <swtch>
    c->intena = intena;
    80003e5c:	fe043783          	ld	a5,-32(s0)
    80003e60:	fdc42703          	lw	a4,-36(s0)
    80003e64:	dff8                	sw	a4,124(a5)
}
    80003e66:	0001                	nop
    80003e68:	70a2                	ld	ra,40(sp)
    80003e6a:	7402                	ld	s0,32(sp)
    80003e6c:	6145                	add	sp,sp,48
    80003e6e:	8082                	ret

0000000080003e70 <scheduler>:

// ==================== 调度器主循环（带调试）====================
void scheduler(void)
{
    80003e70:	715d                	add	sp,sp,-80
    80003e72:	e486                	sd	ra,72(sp)
    80003e74:	e0a2                	sd	s0,64(sp)
    80003e76:	0880                	add	s0,sp,80
    struct proc *p;
    struct cpu *c = mycpu();
    80003e78:	00000097          	auipc	ra,0x0
    80003e7c:	b4a080e7          	jalr	-1206(ra) # 800039c2 <mycpu>
    80003e80:	fca43823          	sd	a0,-48(s0)
    
    printf("Scheduler started\n");
    80003e84:	00004517          	auipc	a0,0x4
    80003e88:	eb450513          	add	a0,a0,-332 # 80007d38 <userret+0x1cd4>
    80003e8c:	ffffd097          	auipc	ra,0xffffd
    80003e90:	d5a080e7          	jalr	-678(ra) # 80000be6 <printf>
    
    // ⭐ 调试：先检查是否有 RUNNABLE 进程
    printf("[DEBUG] Checking for runnable processes...\n");
    80003e94:	00004517          	auipc	a0,0x4
    80003e98:	ebc50513          	add	a0,a0,-324 # 80007d50 <userret+0x1cec>
    80003e9c:	ffffd097          	auipc	ra,0xffffd
    80003ea0:	d4a080e7          	jalr	-694(ra) # 80000be6 <printf>
    int count = 0;
    80003ea4:	fe042223          	sw	zero,-28(s0)
    for(p = proc; p < &proc[NPROC]; p++) {
    80003ea8:	0000a797          	auipc	a5,0xa
    80003eac:	2b878793          	add	a5,a5,696 # 8000e160 <proc>
    80003eb0:	fef43423          	sd	a5,-24(s0)
    80003eb4:	a899                	j	80003f0a <scheduler+0x9a>
        if(p->state != UNUSED) {
    80003eb6:	fe843783          	ld	a5,-24(s0)
    80003eba:	43dc                	lw	a5,4(a5)
    80003ebc:	c3a9                	beqz	a5,80003efe <scheduler+0x8e>
            printf("[DEBUG] Process %d: state=%d (%s)\n", 
    80003ebe:	fe843783          	ld	a5,-24(s0)
    80003ec2:	438c                	lw	a1,0(a5)
                   p->pid, p->state, state_names[p->state]);
    80003ec4:	fe843783          	ld	a5,-24(s0)
    80003ec8:	43d0                	lw	a2,4(a5)
    80003eca:	fe843783          	ld	a5,-24(s0)
    80003ece:	43dc                	lw	a5,4(a5)
    80003ed0:	1782                	sll	a5,a5,0x20
    80003ed2:	9381                	srl	a5,a5,0x20
    80003ed4:	00479713          	sll	a4,a5,0x4
    80003ed8:	00005797          	auipc	a5,0x5
    80003edc:	15078793          	add	a5,a5,336 # 80009028 <state_names>
    80003ee0:	97ba                	add	a5,a5,a4
            printf("[DEBUG] Process %d: state=%d (%s)\n", 
    80003ee2:	86be                	mv	a3,a5
    80003ee4:	00004517          	auipc	a0,0x4
    80003ee8:	e9c50513          	add	a0,a0,-356 # 80007d80 <userret+0x1d1c>
    80003eec:	ffffd097          	auipc	ra,0xffffd
    80003ef0:	cfa080e7          	jalr	-774(ra) # 80000be6 <printf>
            count++;
    80003ef4:	fe442783          	lw	a5,-28(s0)
    80003ef8:	2785                	addw	a5,a5,1
    80003efa:	fef42223          	sw	a5,-28(s0)
    for(p = proc; p < &proc[NPROC]; p++) {
    80003efe:	fe843783          	ld	a5,-24(s0)
    80003f02:	0d078793          	add	a5,a5,208
    80003f06:	fef43423          	sd	a5,-24(s0)
    80003f0a:	fe843703          	ld	a4,-24(s0)
    80003f0e:	0000d797          	auipc	a5,0xd
    80003f12:	65278793          	add	a5,a5,1618 # 80011560 <cpus>
    80003f16:	faf760e3          	bltu	a4,a5,80003eb6 <scheduler+0x46>
        }
    }
    printf("[DEBUG] Total %d processes\n", count);
    80003f1a:	fe442783          	lw	a5,-28(s0)
    80003f1e:	85be                	mv	a1,a5
    80003f20:	00004517          	auipc	a0,0x4
    80003f24:	e8850513          	add	a0,a0,-376 # 80007da8 <userret+0x1d44>
    80003f28:	ffffd097          	auipc	ra,0xffffd
    80003f2c:	cbe080e7          	jalr	-834(ra) # 80000be6 <printf>
    
    c->proc = 0;
    80003f30:	fd043783          	ld	a5,-48(s0)
    80003f34:	0007b023          	sd	zero,0(a5)
    
    int loop_count = 0;
    80003f38:	fe042023          	sw	zero,-32(s0)
    for(;;) {
        // ⭐ 调试：记录循环次数
        loop_count++;
    80003f3c:	fe042783          	lw	a5,-32(s0)
    80003f40:	2785                	addw	a5,a5,1
    80003f42:	fef42023          	sw	a5,-32(s0)
        if(loop_count <= 5) {
    80003f46:	fe042783          	lw	a5,-32(s0)
    80003f4a:	0007871b          	sext.w	a4,a5
    80003f4e:	4795                	li	a5,5
    80003f50:	00e7cd63          	blt	a5,a4,80003f6a <scheduler+0xfa>
            printf("[DEBUG] Scheduler loop #%d\n", loop_count);
    80003f54:	fe042783          	lw	a5,-32(s0)
    80003f58:	85be                	mv	a1,a5
    80003f5a:	00004517          	auipc	a0,0x4
    80003f5e:	e6e50513          	add	a0,a0,-402 # 80007dc8 <userret+0x1d64>
    80003f62:	ffffd097          	auipc	ra,0xffffd
    80003f66:	c84080e7          	jalr	-892(ra) # 80000be6 <printf>
        }
        
        w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003f6a:	100027f3          	csrr	a5,sstatus
    80003f6e:	fcf43423          	sd	a5,-56(s0)
    80003f72:	fc843783          	ld	a5,-56(s0)
    80003f76:	0027e793          	or	a5,a5,2
    80003f7a:	10079073          	csrw	sstatus,a5
        
        int has_runnable = 0;
    80003f7e:	fc042e23          	sw	zero,-36(s0)
        for(p = proc; p < &proc[NPROC]; p++) {
    80003f82:	0000a797          	auipc	a5,0xa
    80003f86:	1de78793          	add	a5,a5,478 # 8000e160 <proc>
    80003f8a:	fef43423          	sd	a5,-24(s0)
    80003f8e:	a081                	j	80003fce <scheduler+0x15e>
            if(p->state == RUNNABLE || p->state == RUNNING || p->state == SLEEPING) {
    80003f90:	fe843783          	ld	a5,-24(s0)
    80003f94:	43dc                	lw	a5,4(a5)
    80003f96:	873e                	mv	a4,a5
    80003f98:	4789                	li	a5,2
    80003f9a:	02f70063          	beq	a4,a5,80003fba <scheduler+0x14a>
    80003f9e:	fe843783          	ld	a5,-24(s0)
    80003fa2:	43dc                	lw	a5,4(a5)
    80003fa4:	873e                	mv	a4,a5
    80003fa6:	478d                	li	a5,3
    80003fa8:	00f70963          	beq	a4,a5,80003fba <scheduler+0x14a>
    80003fac:	fe843783          	ld	a5,-24(s0)
    80003fb0:	43dc                	lw	a5,4(a5)
    80003fb2:	873e                	mv	a4,a5
    80003fb4:	4791                	li	a5,4
    80003fb6:	00f71663          	bne	a4,a5,80003fc2 <scheduler+0x152>
                has_runnable = 1;
    80003fba:	4785                	li	a5,1
    80003fbc:	fcf42e23          	sw	a5,-36(s0)
                break;
    80003fc0:	a839                	j	80003fde <scheduler+0x16e>
        for(p = proc; p < &proc[NPROC]; p++) {
    80003fc2:	fe843783          	ld	a5,-24(s0)
    80003fc6:	0d078793          	add	a5,a5,208
    80003fca:	fef43423          	sd	a5,-24(s0)
    80003fce:	fe843703          	ld	a4,-24(s0)
    80003fd2:	0000d797          	auipc	a5,0xd
    80003fd6:	58e78793          	add	a5,a5,1422 # 80011560 <cpus>
    80003fda:	faf76be3          	bltu	a4,a5,80003f90 <scheduler+0x120>
            }
        }
        
        if(!has_runnable) {
    80003fde:	fdc42783          	lw	a5,-36(s0)
    80003fe2:	2781                	sext.w	a5,a5
    80003fe4:	e79d                	bnez	a5,80004012 <scheduler+0x1a2>
            printf("\n=== All Processes Completed ===\n");
    80003fe6:	00004517          	auipc	a0,0x4
    80003fea:	e0250513          	add	a0,a0,-510 # 80007de8 <userret+0x1d84>
    80003fee:	ffffd097          	auipc	ra,0xffffd
    80003ff2:	bf8080e7          	jalr	-1032(ra) # 80000be6 <printf>
            for(;;) {
                w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003ff6:	100027f3          	csrr	a5,sstatus
    80003ffa:	faf43c23          	sd	a5,-72(s0)
    80003ffe:	fb843783          	ld	a5,-72(s0)
    80004002:	0027e793          	or	a5,a5,2
    80004006:	10079073          	csrw	sstatus,a5
                asm volatile("wfi");
    8000400a:	10500073          	wfi
                w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000400e:	0001                	nop
    80004010:	b7dd                	j	80003ff6 <scheduler+0x186>
            }
        }
        
        for(p = proc; p < &proc[NPROC]; p++) {
    80004012:	0000a797          	auipc	a5,0xa
    80004016:	14e78793          	add	a5,a5,334 # 8000e160 <proc>
    8000401a:	fef43423          	sd	a5,-24(s0)
    8000401e:	a8cd                	j	80004110 <scheduler+0x2a0>
            if(p->state != RUNNABLE) {
    80004020:	fe843783          	ld	a5,-24(s0)
    80004024:	43dc                	lw	a5,4(a5)
    80004026:	873e                	mv	a4,a5
    80004028:	4789                	li	a5,2
    8000402a:	0cf71c63          	bne	a4,a5,80004102 <scheduler+0x292>
                continue;
            }
            
            // ⭐ 找到 RUNNABLE 进程
            if(loop_count <= 3) {
    8000402e:	fe042783          	lw	a5,-32(s0)
    80004032:	0007871b          	sext.w	a4,a5
    80004036:	478d                	li	a5,3
    80004038:	04e7c363          	blt	a5,a4,8000407e <scheduler+0x20e>
                printf("[DEBUG] Found RUNNABLE process: PID=%d, name=%s\n", 
    8000403c:	fe843783          	ld	a5,-24(s0)
    80004040:	4398                	lw	a4,0(a5)
                       p->pid, p->name);
    80004042:	fe843783          	ld	a5,-24(s0)
    80004046:	07a1                	add	a5,a5,8
                printf("[DEBUG] Found RUNNABLE process: PID=%d, name=%s\n", 
    80004048:	863e                	mv	a2,a5
    8000404a:	85ba                	mv	a1,a4
    8000404c:	00004517          	auipc	a0,0x4
    80004050:	dc450513          	add	a0,a0,-572 # 80007e10 <userret+0x1dac>
    80004054:	ffffd097          	auipc	ra,0xffffd
    80004058:	b92080e7          	jalr	-1134(ra) # 80000be6 <printf>
                printf("[DEBUG] context.ra=%p, context.sp=%p\n",
                       (void*)p->context.ra, (void*)p->context.sp);
    8000405c:	fe843783          	ld	a5,-24(s0)
    80004060:	6f9c                	ld	a5,24(a5)
                printf("[DEBUG] context.ra=%p, context.sp=%p\n",
    80004062:	873e                	mv	a4,a5
                       (void*)p->context.ra, (void*)p->context.sp);
    80004064:	fe843783          	ld	a5,-24(s0)
    80004068:	739c                	ld	a5,32(a5)
                printf("[DEBUG] context.ra=%p, context.sp=%p\n",
    8000406a:	863e                	mv	a2,a5
    8000406c:	85ba                	mv	a1,a4
    8000406e:	00004517          	auipc	a0,0x4
    80004072:	dda50513          	add	a0,a0,-550 # 80007e48 <userret+0x1de4>
    80004076:	ffffd097          	auipc	ra,0xffffd
    8000407a:	b70080e7          	jalr	-1168(ra) # 80000be6 <printf>
            }
            
            w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000407e:	100027f3          	csrr	a5,sstatus
    80004082:	fcf43023          	sd	a5,-64(s0)
    80004086:	fc043783          	ld	a5,-64(s0)
    8000408a:	9bf5                	and	a5,a5,-3
    8000408c:	10079073          	csrw	sstatus,a5
            
            p->state = RUNNING;
    80004090:	fe843783          	ld	a5,-24(s0)
    80004094:	470d                	li	a4,3
    80004096:	c3d8                	sw	a4,4(a5)
            c->proc = p;
    80004098:	fd043783          	ld	a5,-48(s0)
    8000409c:	fe843703          	ld	a4,-24(s0)
    800040a0:	e398                	sd	a4,0(a5)
            
            if(loop_count <= 3) {
    800040a2:	fe042783          	lw	a5,-32(s0)
    800040a6:	0007871b          	sext.w	a4,a5
    800040aa:	478d                	li	a5,3
    800040ac:	00e7ca63          	blt	a5,a4,800040c0 <scheduler+0x250>
                printf("[DEBUG] About to call swtch...\n");
    800040b0:	00004517          	auipc	a0,0x4
    800040b4:	dc050513          	add	a0,a0,-576 # 80007e70 <userret+0x1e0c>
    800040b8:	ffffd097          	auipc	ra,0xffffd
    800040bc:	b2e080e7          	jalr	-1234(ra) # 80000be6 <printf>
            }
            
            swtch(&c->context, &p->context);
    800040c0:	fd043783          	ld	a5,-48(s0)
    800040c4:	00878713          	add	a4,a5,8
    800040c8:	fe843783          	ld	a5,-24(s0)
    800040cc:	07e1                	add	a5,a5,24
    800040ce:	85be                	mv	a1,a5
    800040d0:	853a                	mv	a0,a4
    800040d2:	00000097          	auipc	ra,0x0
    800040d6:	7f8080e7          	jalr	2040(ra) # 800048ca <swtch>
            
            if(loop_count <= 3) {
    800040da:	fe042783          	lw	a5,-32(s0)
    800040de:	0007871b          	sext.w	a4,a5
    800040e2:	478d                	li	a5,3
    800040e4:	00e7ca63          	blt	a5,a4,800040f8 <scheduler+0x288>
                printf("[DEBUG] Returned from swtch\n");
    800040e8:	00004517          	auipc	a0,0x4
    800040ec:	da850513          	add	a0,a0,-600 # 80007e90 <userret+0x1e2c>
    800040f0:	ffffd097          	auipc	ra,0xffffd
    800040f4:	af6080e7          	jalr	-1290(ra) # 80000be6 <printf>
            }
            
            c->proc = 0;
    800040f8:	fd043783          	ld	a5,-48(s0)
    800040fc:	0007b023          	sd	zero,0(a5)
    80004100:	a011                	j	80004104 <scheduler+0x294>
                continue;
    80004102:	0001                	nop
        for(p = proc; p < &proc[NPROC]; p++) {
    80004104:	fe843783          	ld	a5,-24(s0)
    80004108:	0d078793          	add	a5,a5,208
    8000410c:	fef43423          	sd	a5,-24(s0)
    80004110:	fe843703          	ld	a4,-24(s0)
    80004114:	0000d797          	auipc	a5,0xd
    80004118:	44c78793          	add	a5,a5,1100 # 80011560 <cpus>
    8000411c:	f0f762e3          	bltu	a4,a5,80004020 <scheduler+0x1b0>
    for(;;) {
    80004120:	bd31                	j	80003f3c <scheduler+0xcc>

0000000080004122 <sleep>:
    }
}

// ==================== 睡眠等待 ====================
void sleep(void *chan)
{
    80004122:	7179                	add	sp,sp,-48
    80004124:	f406                	sd	ra,40(sp)
    80004126:	f022                	sd	s0,32(sp)
    80004128:	1800                	add	s0,sp,48
    8000412a:	fca43c23          	sd	a0,-40(s0)
    struct proc *p = myproc();
    8000412e:	00000097          	auipc	ra,0x0
    80004132:	8aa080e7          	jalr	-1878(ra) # 800039d8 <myproc>
    80004136:	fea43423          	sd	a0,-24(s0)
    if(p == 0) {
    8000413a:	fe843783          	ld	a5,-24(s0)
    8000413e:	eb89                	bnez	a5,80004150 <sleep+0x2e>
        panic("sleep: no process");
    80004140:	00004517          	auipc	a0,0x4
    80004144:	d7050513          	add	a0,a0,-656 # 80007eb0 <userret+0x1e4c>
    80004148:	ffffd097          	auipc	ra,0xffffd
    8000414c:	e44080e7          	jalr	-444(ra) # 80000f8c <panic>
    }
    
    w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80004150:	100027f3          	csrr	a5,sstatus
    80004154:	fef43023          	sd	a5,-32(s0)
    80004158:	fe043783          	ld	a5,-32(s0)
    8000415c:	9bf5                	and	a5,a5,-3
    8000415e:	10079073          	csrw	sstatus,a5
    
    p->chan = chan;
    80004162:	fe843783          	ld	a5,-24(s0)
    80004166:	fd843703          	ld	a4,-40(s0)
    8000416a:	ffd8                	sd	a4,184(a5)
    p->state = SLEEPING;
    8000416c:	fe843783          	ld	a5,-24(s0)
    80004170:	4711                	li	a4,4
    80004172:	c3d8                	sw	a4,4(a5)
    
    sched();
    80004174:	00000097          	auipc	ra,0x0
    80004178:	c8c080e7          	jalr	-884(ra) # 80003e00 <sched>
    
    p->chan = 0;
    8000417c:	fe843783          	ld	a5,-24(s0)
    80004180:	0a07bc23          	sd	zero,184(a5)
}
    80004184:	0001                	nop
    80004186:	70a2                	ld	ra,40(sp)
    80004188:	7402                	ld	s0,32(sp)
    8000418a:	6145                	add	sp,sp,48
    8000418c:	8082                	ret

000000008000418e <wakeup>:

// ==================== 唤醒等待进程 ====================
void wakeup(void *chan)
{
    8000418e:	7179                	add	sp,sp,-48
    80004190:	f422                	sd	s0,40(sp)
    80004192:	1800                	add	s0,sp,48
    80004194:	fca43c23          	sd	a0,-40(s0)
    struct proc *p;
    
    for(p = proc; p < &proc[NPROC]; p++) {
    80004198:	0000a797          	auipc	a5,0xa
    8000419c:	fc878793          	add	a5,a5,-56 # 8000e160 <proc>
    800041a0:	fef43423          	sd	a5,-24(s0)
    800041a4:	a80d                	j	800041d6 <wakeup+0x48>
        if(p->state == SLEEPING && p->chan == chan) {
    800041a6:	fe843783          	ld	a5,-24(s0)
    800041aa:	43dc                	lw	a5,4(a5)
    800041ac:	873e                	mv	a4,a5
    800041ae:	4791                	li	a5,4
    800041b0:	00f71d63          	bne	a4,a5,800041ca <wakeup+0x3c>
    800041b4:	fe843783          	ld	a5,-24(s0)
    800041b8:	7fdc                	ld	a5,184(a5)
    800041ba:	fd843703          	ld	a4,-40(s0)
    800041be:	00f71663          	bne	a4,a5,800041ca <wakeup+0x3c>
            p->state = RUNNABLE;
    800041c2:	fe843783          	ld	a5,-24(s0)
    800041c6:	4709                	li	a4,2
    800041c8:	c3d8                	sw	a4,4(a5)
    for(p = proc; p < &proc[NPROC]; p++) {
    800041ca:	fe843783          	ld	a5,-24(s0)
    800041ce:	0d078793          	add	a5,a5,208
    800041d2:	fef43423          	sd	a5,-24(s0)
    800041d6:	fe843703          	ld	a4,-24(s0)
    800041da:	0000d797          	auipc	a5,0xd
    800041de:	38678793          	add	a5,a5,902 # 80011560 <cpus>
    800041e2:	fcf762e3          	bltu	a4,a5,800041a6 <wakeup+0x18>
        }
    }
}
    800041e6:	0001                	nop
    800041e8:	0001                	nop
    800041ea:	7422                	ld	s0,40(sp)
    800041ec:	6145                	add	sp,sp,48
    800041ee:	8082                	ret

00000000800041f0 <exit_proc>:

// ==================== 进程退出 ====================
void exit_proc(int status)
{
    800041f0:	7179                	add	sp,sp,-48
    800041f2:	f406                	sd	ra,40(sp)
    800041f4:	f022                	sd	s0,32(sp)
    800041f6:	1800                	add	s0,sp,48
    800041f8:	87aa                	mv	a5,a0
    800041fa:	fcf42e23          	sw	a5,-36(s0)
    struct proc *p = myproc();
    800041fe:	fffff097          	auipc	ra,0xfffff
    80004202:	7da080e7          	jalr	2010(ra) # 800039d8 <myproc>
    80004206:	fea43423          	sd	a0,-24(s0)
    if(p == 0) {
    8000420a:	fe843783          	ld	a5,-24(s0)
    8000420e:	eb89                	bnez	a5,80004220 <exit_proc+0x30>
        panic("exit: no process");
    80004210:	00004517          	auipc	a0,0x4
    80004214:	cb850513          	add	a0,a0,-840 # 80007ec8 <userret+0x1e64>
    80004218:	ffffd097          	auipc	ra,0xffffd
    8000421c:	d74080e7          	jalr	-652(ra) # 80000f8c <panic>
    }
    
    printf("Process %d (%s) exiting with status %d\n", 
    80004220:	fe843783          	ld	a5,-24(s0)
    80004224:	4398                	lw	a4,0(a5)
           p->pid, p->name, status);
    80004226:	fe843783          	ld	a5,-24(s0)
    8000422a:	07a1                	add	a5,a5,8
    printf("Process %d (%s) exiting with status %d\n", 
    8000422c:	fdc42683          	lw	a3,-36(s0)
    80004230:	863e                	mv	a2,a5
    80004232:	85ba                	mv	a1,a4
    80004234:	00004517          	auipc	a0,0x4
    80004238:	cac50513          	add	a0,a0,-852 # 80007ee0 <userret+0x1e7c>
    8000423c:	ffffd097          	auipc	ra,0xffffd
    80004240:	9aa080e7          	jalr	-1622(ra) # 80000be6 <printf>
    
    w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80004244:	100027f3          	csrr	a5,sstatus
    80004248:	fef43023          	sd	a5,-32(s0)
    8000424c:	fe043783          	ld	a5,-32(s0)
    80004250:	9bf5                	and	a5,a5,-3
    80004252:	10079073          	csrw	sstatus,a5
    
    p->xstate = status;
    80004256:	fe843783          	ld	a5,-24(s0)
    8000425a:	fdc42703          	lw	a4,-36(s0)
    8000425e:	0ae7a823          	sw	a4,176(a5)
    p->state = ZOMBIE;
    80004262:	fe843783          	ld	a5,-24(s0)
    80004266:	4715                	li	a4,5
    80004268:	c3d8                	sw	a4,4(a5)
    
    if(p->parent) {
    8000426a:	fe843783          	ld	a5,-24(s0)
    8000426e:	77dc                	ld	a5,168(a5)
    80004270:	cb89                	beqz	a5,80004282 <exit_proc+0x92>
        wakeup(p->parent);
    80004272:	fe843783          	ld	a5,-24(s0)
    80004276:	77dc                	ld	a5,168(a5)
    80004278:	853e                	mv	a0,a5
    8000427a:	00000097          	auipc	ra,0x0
    8000427e:	f14080e7          	jalr	-236(ra) # 8000418e <wakeup>
    }
    
    sched();
    80004282:	00000097          	auipc	ra,0x0
    80004286:	b7e080e7          	jalr	-1154(ra) # 80003e00 <sched>
    panic("zombie exit");
    8000428a:	00004517          	auipc	a0,0x4
    8000428e:	c7e50513          	add	a0,a0,-898 # 80007f08 <userret+0x1ea4>
    80004292:	ffffd097          	auipc	ra,0xffffd
    80004296:	cfa080e7          	jalr	-774(ra) # 80000f8c <panic>
}
    8000429a:	0001                	nop
    8000429c:	70a2                	ld	ra,40(sp)
    8000429e:	7402                	ld	s0,32(sp)
    800042a0:	6145                	add	sp,sp,48
    800042a2:	8082                	ret

00000000800042a4 <wait_proc>:

// ==================== 等待子进程 ====================
int wait_proc(int *status)
{
    800042a4:	7139                	add	sp,sp,-64
    800042a6:	fc06                	sd	ra,56(sp)
    800042a8:	f822                	sd	s0,48(sp)
    800042aa:	0080                	add	s0,sp,64
    800042ac:	fca43423          	sd	a0,-56(s0)
    struct proc *np;
    int havekids, pid;
    struct proc *p = myproc();
    800042b0:	fffff097          	auipc	ra,0xfffff
    800042b4:	728080e7          	jalr	1832(ra) # 800039d8 <myproc>
    800042b8:	fca43c23          	sd	a0,-40(s0)
    
    for(;;) {
        havekids = 0;
    800042bc:	fe042223          	sw	zero,-28(s0)
        for(np = proc; np < &proc[NPROC]; np++) {
    800042c0:	0000a797          	auipc	a5,0xa
    800042c4:	ea078793          	add	a5,a5,-352 # 8000e160 <proc>
    800042c8:	fef43423          	sd	a5,-24(s0)
    800042cc:	a085                	j	8000432c <wait_proc+0x88>
            if(np->parent == p) {
    800042ce:	fe843783          	ld	a5,-24(s0)
    800042d2:	77dc                	ld	a5,168(a5)
    800042d4:	fd843703          	ld	a4,-40(s0)
    800042d8:	04f71463          	bne	a4,a5,80004320 <wait_proc+0x7c>
                havekids = 1;
    800042dc:	4785                	li	a5,1
    800042de:	fef42223          	sw	a5,-28(s0)
                if(np->state == ZOMBIE) {
    800042e2:	fe843783          	ld	a5,-24(s0)
    800042e6:	43dc                	lw	a5,4(a5)
    800042e8:	873e                	mv	a4,a5
    800042ea:	4795                	li	a5,5
    800042ec:	02f71a63          	bne	a4,a5,80004320 <wait_proc+0x7c>
                    pid = np->pid;
    800042f0:	fe843783          	ld	a5,-24(s0)
    800042f4:	439c                	lw	a5,0(a5)
    800042f6:	fcf42a23          	sw	a5,-44(s0)
                    if(status != 0) {
    800042fa:	fc843783          	ld	a5,-56(s0)
    800042fe:	cb81                	beqz	a5,8000430e <wait_proc+0x6a>
                        *status = np->xstate;
    80004300:	fe843783          	ld	a5,-24(s0)
    80004304:	0b07a703          	lw	a4,176(a5)
    80004308:	fc843783          	ld	a5,-56(s0)
    8000430c:	c398                	sw	a4,0(a5)
                    }
                    free_proc(np);
    8000430e:	fe843503          	ld	a0,-24(s0)
    80004312:	00000097          	auipc	ra,0x0
    80004316:	848080e7          	jalr	-1976(ra) # 80003b5a <free_proc>
                    return pid;
    8000431a:	fd442783          	lw	a5,-44(s0)
    8000431e:	a825                	j	80004356 <wait_proc+0xb2>
        for(np = proc; np < &proc[NPROC]; np++) {
    80004320:	fe843783          	ld	a5,-24(s0)
    80004324:	0d078793          	add	a5,a5,208
    80004328:	fef43423          	sd	a5,-24(s0)
    8000432c:	fe843703          	ld	a4,-24(s0)
    80004330:	0000d797          	auipc	a5,0xd
    80004334:	23078793          	add	a5,a5,560 # 80011560 <cpus>
    80004338:	f8f76be3          	bltu	a4,a5,800042ce <wait_proc+0x2a>
                }
            }
        }
        
        if(!havekids) {
    8000433c:	fe442783          	lw	a5,-28(s0)
    80004340:	2781                	sext.w	a5,a5
    80004342:	e399                	bnez	a5,80004348 <wait_proc+0xa4>
            return -1;
    80004344:	57fd                	li	a5,-1
    80004346:	a801                	j	80004356 <wait_proc+0xb2>
        }
        
        sleep(p);
    80004348:	fd843503          	ld	a0,-40(s0)
    8000434c:	00000097          	auipc	ra,0x0
    80004350:	dd6080e7          	jalr	-554(ra) # 80004122 <sleep>
        havekids = 0;
    80004354:	b7a5                	j	800042bc <wait_proc+0x18>
    }
}
    80004356:	853e                	mv	a0,a5
    80004358:	70e2                	ld	ra,56(sp)
    8000435a:	7442                	ld	s0,48(sp)
    8000435c:	6121                	add	sp,sp,64
    8000435e:	8082                	ret

0000000080004360 <userinit>:
// ==================== 创建第一个用户进程 ====================
extern uint8 initcode[];
extern uint32 initcode_size;

int userinit(void)
{
    80004360:	7139                	add	sp,sp,-64
    80004362:	fc06                	sd	ra,56(sp)
    80004364:	f822                	sd	s0,48(sp)
    80004366:	0080                	add	s0,sp,64
    struct proc *p;
    
    p = alloc_proc();
    80004368:	fffff097          	auipc	ra,0xfffff
    8000436c:	6ac080e7          	jalr	1708(ra) # 80003a14 <alloc_proc>
    80004370:	fea43023          	sd	a0,-32(s0)
    if(p == 0)
    80004374:	fe043783          	ld	a5,-32(s0)
    80004378:	eb89                	bnez	a5,8000438a <userinit+0x2a>
        panic("userinit: no proc");
    8000437a:	00004517          	auipc	a0,0x4
    8000437e:	b9e50513          	add	a0,a0,-1122 # 80007f18 <userret+0x1eb4>
    80004382:	ffffd097          	auipc	ra,0xffffd
    80004386:	c0a080e7          	jalr	-1014(ra) # 80000f8c <panic>
    
    for(int i = 0; "initcode"[i]; i++)
    8000438a:	fe042623          	sw	zero,-20(s0)
    8000438e:	a035                	j	800043ba <userinit+0x5a>
        p->name[i] = "initcode"[i];
    80004390:	00004717          	auipc	a4,0x4
    80004394:	de070713          	add	a4,a4,-544 # 80008170 <userret+0x210c>
    80004398:	fec42783          	lw	a5,-20(s0)
    8000439c:	97ba                	add	a5,a5,a4
    8000439e:	0007c703          	lbu	a4,0(a5)
    800043a2:	fe043683          	ld	a3,-32(s0)
    800043a6:	fec42783          	lw	a5,-20(s0)
    800043aa:	97b6                	add	a5,a5,a3
    800043ac:	00e78423          	sb	a4,8(a5)
    for(int i = 0; "initcode"[i]; i++)
    800043b0:	fec42783          	lw	a5,-20(s0)
    800043b4:	2785                	addw	a5,a5,1
    800043b6:	fef42623          	sw	a5,-20(s0)
    800043ba:	00004717          	auipc	a4,0x4
    800043be:	db670713          	add	a4,a4,-586 # 80008170 <userret+0x210c>
    800043c2:	fec42783          	lw	a5,-20(s0)
    800043c6:	97ba                	add	a5,a5,a4
    800043c8:	0007c783          	lbu	a5,0(a5)
    800043cc:	f3f1                	bnez	a5,80004390 <userinit+0x30>
    
    p->pagetable = proc_pagetable(p);
    800043ce:	fe043503          	ld	a0,-32(s0)
    800043d2:	ffffe097          	auipc	ra,0xffffe
    800043d6:	b58080e7          	jalr	-1192(ra) # 80001f2a <proc_pagetable>
    800043da:	872a                	mv	a4,a0
    800043dc:	fe043783          	ld	a5,-32(s0)
    800043e0:	e7f8                	sd	a4,200(a5)
    if(p->pagetable == 0) {
    800043e2:	fe043783          	ld	a5,-32(s0)
    800043e6:	67fc                	ld	a5,200(a5)
    800043e8:	ef99                	bnez	a5,80004406 <userinit+0xa6>
        free_proc(p);
    800043ea:	fe043503          	ld	a0,-32(s0)
    800043ee:	fffff097          	auipc	ra,0xfffff
    800043f2:	76c080e7          	jalr	1900(ra) # 80003b5a <free_proc>
        panic("userinit: proc_pagetable");
    800043f6:	00004517          	auipc	a0,0x4
    800043fa:	b3a50513          	add	a0,a0,-1222 # 80007f30 <userret+0x1ecc>
    800043fe:	ffffd097          	auipc	ra,0xffffd
    80004402:	b8e080e7          	jalr	-1138(ra) # 80000f8c <panic>
    }
    
    // 分配代码页
    void *code_page = alloc_page();
    80004406:	ffffd097          	auipc	ra,0xffffd
    8000440a:	ee2080e7          	jalr	-286(ra) # 800012e8 <alloc_page>
    8000440e:	fca43c23          	sd	a0,-40(s0)
    if(code_page == 0) {
    80004412:	fd843783          	ld	a5,-40(s0)
    80004416:	eb85                	bnez	a5,80004446 <userinit+0xe6>
        proc_freepagetable(p->pagetable, 0);
    80004418:	fe043783          	ld	a5,-32(s0)
    8000441c:	67fc                	ld	a5,200(a5)
    8000441e:	4581                	li	a1,0
    80004420:	853e                	mv	a0,a5
    80004422:	ffffe097          	auipc	ra,0xffffe
    80004426:	cb6080e7          	jalr	-842(ra) # 800020d8 <proc_freepagetable>
        free_proc(p);
    8000442a:	fe043503          	ld	a0,-32(s0)
    8000442e:	fffff097          	auipc	ra,0xfffff
    80004432:	72c080e7          	jalr	1836(ra) # 80003b5a <free_proc>
        panic("userinit: alloc code page");
    80004436:	00004517          	auipc	a0,0x4
    8000443a:	b1a50513          	add	a0,a0,-1254 # 80007f50 <userret+0x1eec>
    8000443e:	ffffd097          	auipc	ra,0xffffd
    80004442:	b4e080e7          	jalr	-1202(ra) # 80000f8c <panic>
    }
    
    printf("[DEBUG] code_page phys addr: %p\n", code_page);
    80004446:	fd843583          	ld	a1,-40(s0)
    8000444a:	00004517          	auipc	a0,0x4
    8000444e:	b2650513          	add	a0,a0,-1242 # 80007f70 <userret+0x1f0c>
    80004452:	ffffc097          	auipc	ra,0xffffc
    80004456:	794080e7          	jalr	1940(ra) # 80000be6 <printf>
    printf("[DEBUG] initcode_size: %d bytes\n", initcode_size);
    8000445a:	00005797          	auipc	a5,0x5
    8000445e:	bb278793          	add	a5,a5,-1102 # 8000900c <initcode_size>
    80004462:	439c                	lw	a5,0(a5)
    80004464:	85be                	mv	a1,a5
    80004466:	00004517          	auipc	a0,0x4
    8000446a:	b3250513          	add	a0,a0,-1230 # 80007f98 <userret+0x1f34>
    8000446e:	ffffc097          	auipc	ra,0xffffc
    80004472:	778080e7          	jalr	1912(ra) # 80000be6 <printf>
    
    memset(code_page, 0, PGSIZE);
    80004476:	6605                	lui	a2,0x1
    80004478:	4581                	li	a1,0
    8000447a:	fd843503          	ld	a0,-40(s0)
    8000447e:	ffffd097          	auipc	ra,0xffffd
    80004482:	c90080e7          	jalr	-880(ra) # 8000110e <memset>
    memcpy(code_page, initcode, initcode_size);
    80004486:	00005797          	auipc	a5,0x5
    8000448a:	b8678793          	add	a5,a5,-1146 # 8000900c <initcode_size>
    8000448e:	439c                	lw	a5,0(a5)
    80004490:	863e                	mv	a2,a5
    80004492:	00005597          	auipc	a1,0x5
    80004496:	cb658593          	add	a1,a1,-842 # 80009148 <initcode>
    8000449a:	fd843503          	ld	a0,-40(s0)
    8000449e:	ffffd097          	auipc	ra,0xffffd
    800044a2:	cd0080e7          	jalr	-816(ra) # 8000116e <memcpy>
    
    // ⭐ 打印代码内容
    printf("[DEBUG] First 32 bytes of initcode:\n");
    800044a6:	00004517          	auipc	a0,0x4
    800044aa:	b1a50513          	add	a0,a0,-1254 # 80007fc0 <userret+0x1f5c>
    800044ae:	ffffc097          	auipc	ra,0xffffc
    800044b2:	738080e7          	jalr	1848(ra) # 80000be6 <printf>
    for(int i = 0; i < 32 && i < initcode_size; i++) {
    800044b6:	fe042423          	sw	zero,-24(s0)
    800044ba:	a0b9                	j	80004508 <userinit+0x1a8>
        printf("%02x ", ((uint8*)code_page)[i]);
    800044bc:	fe842783          	lw	a5,-24(s0)
    800044c0:	fd843703          	ld	a4,-40(s0)
    800044c4:	97ba                	add	a5,a5,a4
    800044c6:	0007c783          	lbu	a5,0(a5)
    800044ca:	2781                	sext.w	a5,a5
    800044cc:	85be                	mv	a1,a5
    800044ce:	00004517          	auipc	a0,0x4
    800044d2:	b1a50513          	add	a0,a0,-1254 # 80007fe8 <userret+0x1f84>
    800044d6:	ffffc097          	auipc	ra,0xffffc
    800044da:	710080e7          	jalr	1808(ra) # 80000be6 <printf>
        if((i+1) % 16 == 0) printf("\n");
    800044de:	fe842783          	lw	a5,-24(s0)
    800044e2:	2785                	addw	a5,a5,1
    800044e4:	2781                	sext.w	a5,a5
    800044e6:	2781                	sext.w	a5,a5
    800044e8:	8bbd                	and	a5,a5,15
    800044ea:	2781                	sext.w	a5,a5
    800044ec:	eb89                	bnez	a5,800044fe <userinit+0x19e>
    800044ee:	00004517          	auipc	a0,0x4
    800044f2:	b0250513          	add	a0,a0,-1278 # 80007ff0 <userret+0x1f8c>
    800044f6:	ffffc097          	auipc	ra,0xffffc
    800044fa:	6f0080e7          	jalr	1776(ra) # 80000be6 <printf>
    for(int i = 0; i < 32 && i < initcode_size; i++) {
    800044fe:	fe842783          	lw	a5,-24(s0)
    80004502:	2785                	addw	a5,a5,1
    80004504:	fef42423          	sw	a5,-24(s0)
    80004508:	fe842783          	lw	a5,-24(s0)
    8000450c:	0007871b          	sext.w	a4,a5
    80004510:	47fd                	li	a5,31
    80004512:	00e7cb63          	blt	a5,a4,80004528 <userinit+0x1c8>
    80004516:	fe842703          	lw	a4,-24(s0)
    8000451a:	00005797          	auipc	a5,0x5
    8000451e:	af278793          	add	a5,a5,-1294 # 8000900c <initcode_size>
    80004522:	439c                	lw	a5,0(a5)
    80004524:	f8f76ce3          	bltu	a4,a5,800044bc <userinit+0x15c>
    }
    if(initcode_size % 16 != 0) printf("\n");
    80004528:	00005797          	auipc	a5,0x5
    8000452c:	ae478793          	add	a5,a5,-1308 # 8000900c <initcode_size>
    80004530:	439c                	lw	a5,0(a5)
    80004532:	8bbd                	and	a5,a5,15
    80004534:	2781                	sext.w	a5,a5
    80004536:	cb89                	beqz	a5,80004548 <userinit+0x1e8>
    80004538:	00004517          	auipc	a0,0x4
    8000453c:	ab850513          	add	a0,a0,-1352 # 80007ff0 <userret+0x1f8c>
    80004540:	ffffc097          	auipc	ra,0xffffc
    80004544:	6a6080e7          	jalr	1702(ra) # 80000be6 <printf>
    
    // 映射代码页
    printf("[DEBUG] Mapping code page: va=0x0, pa=%p, perm=RWXU\n", code_page);
    80004548:	fd843583          	ld	a1,-40(s0)
    8000454c:	00004517          	auipc	a0,0x4
    80004550:	aac50513          	add	a0,a0,-1364 # 80007ff8 <userret+0x1f94>
    80004554:	ffffc097          	auipc	ra,0xffffc
    80004558:	692080e7          	jalr	1682(ra) # 80000be6 <printf>
    if(map_page(p->pagetable, 0, (uint64)code_page, 
    8000455c:	fe043783          	ld	a5,-32(s0)
    80004560:	67fc                	ld	a5,200(a5)
    80004562:	fd843703          	ld	a4,-40(s0)
    80004566:	46f9                	li	a3,30
    80004568:	863a                	mv	a2,a4
    8000456a:	4581                	li	a1,0
    8000456c:	853e                	mv	a0,a5
    8000456e:	ffffd097          	auipc	ra,0xffffd
    80004572:	25e080e7          	jalr	606(ra) # 800017cc <map_page>
    80004576:	87aa                	mv	a5,a0
    80004578:	cf95                	beqz	a5,800045b4 <userinit+0x254>
                PTE_R | PTE_W | PTE_X | PTE_U) != 0) {
        free_page(code_page);
    8000457a:	fd843503          	ld	a0,-40(s0)
    8000457e:	ffffd097          	auipc	ra,0xffffd
    80004582:	dcc080e7          	jalr	-564(ra) # 8000134a <free_page>
        proc_freepagetable(p->pagetable, 0);
    80004586:	fe043783          	ld	a5,-32(s0)
    8000458a:	67fc                	ld	a5,200(a5)
    8000458c:	4581                	li	a1,0
    8000458e:	853e                	mv	a0,a5
    80004590:	ffffe097          	auipc	ra,0xffffe
    80004594:	b48080e7          	jalr	-1208(ra) # 800020d8 <proc_freepagetable>
        free_proc(p);
    80004598:	fe043503          	ld	a0,-32(s0)
    8000459c:	fffff097          	auipc	ra,0xfffff
    800045a0:	5be080e7          	jalr	1470(ra) # 80003b5a <free_proc>
        panic("userinit: map code page");
    800045a4:	00004517          	auipc	a0,0x4
    800045a8:	a8c50513          	add	a0,a0,-1396 # 80008030 <userret+0x1fcc>
    800045ac:	ffffd097          	auipc	ra,0xffffd
    800045b0:	9e0080e7          	jalr	-1568(ra) # 80000f8c <panic>
    }
    
    // ⭐ 验证映射
    pte_t *pte = walk_lookup(p->pagetable, 0);
    800045b4:	fe043783          	ld	a5,-32(s0)
    800045b8:	67fc                	ld	a5,200(a5)
    800045ba:	4581                	li	a1,0
    800045bc:	853e                	mv	a0,a5
    800045be:	ffffd097          	auipc	ra,0xffffd
    800045c2:	08a080e7          	jalr	138(ra) # 80001648 <walk_lookup>
    800045c6:	fca43823          	sd	a0,-48(s0)
    if(pte == 0 || (*pte & PTE_V) == 0) {
    800045ca:	fd043783          	ld	a5,-48(s0)
    800045ce:	c791                	beqz	a5,800045da <userinit+0x27a>
    800045d0:	fd043783          	ld	a5,-48(s0)
    800045d4:	639c                	ld	a5,0(a5)
    800045d6:	8b85                	and	a5,a5,1
    800045d8:	eb89                	bnez	a5,800045ea <userinit+0x28a>
        panic("userinit: code page not mapped!");
    800045da:	00004517          	auipc	a0,0x4
    800045de:	a6e50513          	add	a0,a0,-1426 # 80008048 <userret+0x1fe4>
    800045e2:	ffffd097          	auipc	ra,0xffffd
    800045e6:	9aa080e7          	jalr	-1622(ra) # 80000f8c <panic>
    }
    printf("[DEBUG] Code page PTE: %p (flags: %s%s%s%s%s)\n",
           (void*)*pte,
    800045ea:	fd043783          	ld	a5,-48(s0)
    800045ee:	639c                	ld	a5,0(a5)
    printf("[DEBUG] Code page PTE: %p (flags: %s%s%s%s%s)\n",
    800045f0:	853e                	mv	a0,a5
           (*pte & PTE_V) ? "V" : "-",
    800045f2:	fd043783          	ld	a5,-48(s0)
    800045f6:	639c                	ld	a5,0(a5)
    800045f8:	8b85                	and	a5,a5,1
    printf("[DEBUG] Code page PTE: %p (flags: %s%s%s%s%s)\n",
    800045fa:	c791                	beqz	a5,80004606 <userinit+0x2a6>
    800045fc:	00004617          	auipc	a2,0x4
    80004600:	a6c60613          	add	a2,a2,-1428 # 80008068 <userret+0x2004>
    80004604:	a029                	j	8000460e <userinit+0x2ae>
    80004606:	00004617          	auipc	a2,0x4
    8000460a:	a6a60613          	add	a2,a2,-1430 # 80008070 <userret+0x200c>
           (*pte & PTE_R) ? "R" : "-",
    8000460e:	fd043783          	ld	a5,-48(s0)
    80004612:	639c                	ld	a5,0(a5)
    80004614:	8b89                	and	a5,a5,2
    printf("[DEBUG] Code page PTE: %p (flags: %s%s%s%s%s)\n",
    80004616:	c791                	beqz	a5,80004622 <userinit+0x2c2>
    80004618:	00004697          	auipc	a3,0x4
    8000461c:	a6068693          	add	a3,a3,-1440 # 80008078 <userret+0x2014>
    80004620:	a029                	j	8000462a <userinit+0x2ca>
    80004622:	00004697          	auipc	a3,0x4
    80004626:	a4e68693          	add	a3,a3,-1458 # 80008070 <userret+0x200c>
           (*pte & PTE_W) ? "W" : "-",
    8000462a:	fd043783          	ld	a5,-48(s0)
    8000462e:	639c                	ld	a5,0(a5)
    80004630:	8b91                	and	a5,a5,4
    printf("[DEBUG] Code page PTE: %p (flags: %s%s%s%s%s)\n",
    80004632:	c791                	beqz	a5,8000463e <userinit+0x2de>
    80004634:	00004717          	auipc	a4,0x4
    80004638:	a4c70713          	add	a4,a4,-1460 # 80008080 <userret+0x201c>
    8000463c:	a029                	j	80004646 <userinit+0x2e6>
    8000463e:	00004717          	auipc	a4,0x4
    80004642:	a3270713          	add	a4,a4,-1486 # 80008070 <userret+0x200c>
           (*pte & PTE_X) ? "X" : "-",
    80004646:	fd043783          	ld	a5,-48(s0)
    8000464a:	639c                	ld	a5,0(a5)
    8000464c:	8ba1                	and	a5,a5,8
    printf("[DEBUG] Code page PTE: %p (flags: %s%s%s%s%s)\n",
    8000464e:	c791                	beqz	a5,8000465a <userinit+0x2fa>
    80004650:	00004797          	auipc	a5,0x4
    80004654:	a3878793          	add	a5,a5,-1480 # 80008088 <userret+0x2024>
    80004658:	a029                	j	80004662 <userinit+0x302>
    8000465a:	00004797          	auipc	a5,0x4
    8000465e:	a1678793          	add	a5,a5,-1514 # 80008070 <userret+0x200c>
           (*pte & PTE_U) ? "U" : "-");
    80004662:	fd043583          	ld	a1,-48(s0)
    80004666:	618c                	ld	a1,0(a1)
    80004668:	89c1                	and	a1,a1,16
    printf("[DEBUG] Code page PTE: %p (flags: %s%s%s%s%s)\n",
    8000466a:	c591                	beqz	a1,80004676 <userinit+0x316>
    8000466c:	00004597          	auipc	a1,0x4
    80004670:	a2458593          	add	a1,a1,-1500 # 80008090 <userret+0x202c>
    80004674:	a029                	j	8000467e <userinit+0x31e>
    80004676:	00004597          	auipc	a1,0x4
    8000467a:	9fa58593          	add	a1,a1,-1542 # 80008070 <userret+0x200c>
    8000467e:	882e                	mv	a6,a1
    80004680:	85aa                	mv	a1,a0
    80004682:	00004517          	auipc	a0,0x4
    80004686:	a1650513          	add	a0,a0,-1514 # 80008098 <userret+0x2034>
    8000468a:	ffffc097          	auipc	ra,0xffffc
    8000468e:	55c080e7          	jalr	1372(ra) # 80000be6 <printf>
    
    // 分配栈页
    void *stack_page = alloc_page();
    80004692:	ffffd097          	auipc	ra,0xffffd
    80004696:	c56080e7          	jalr	-938(ra) # 800012e8 <alloc_page>
    8000469a:	fca43423          	sd	a0,-56(s0)
    if(stack_page == 0) {
    8000469e:	fc843783          	ld	a5,-56(s0)
    800046a2:	eb85                	bnez	a5,800046d2 <userinit+0x372>
        proc_freepagetable(p->pagetable, PGSIZE);
    800046a4:	fe043783          	ld	a5,-32(s0)
    800046a8:	67fc                	ld	a5,200(a5)
    800046aa:	6585                	lui	a1,0x1
    800046ac:	853e                	mv	a0,a5
    800046ae:	ffffe097          	auipc	ra,0xffffe
    800046b2:	a2a080e7          	jalr	-1494(ra) # 800020d8 <proc_freepagetable>
        free_proc(p);
    800046b6:	fe043503          	ld	a0,-32(s0)
    800046ba:	fffff097          	auipc	ra,0xfffff
    800046be:	4a0080e7          	jalr	1184(ra) # 80003b5a <free_proc>
        panic("userinit: alloc stack page");
    800046c2:	00004517          	auipc	a0,0x4
    800046c6:	a0650513          	add	a0,a0,-1530 # 800080c8 <userret+0x2064>
    800046ca:	ffffd097          	auipc	ra,0xffffd
    800046ce:	8c2080e7          	jalr	-1854(ra) # 80000f8c <panic>
    }
    memset(stack_page, 0, PGSIZE);
    800046d2:	6605                	lui	a2,0x1
    800046d4:	4581                	li	a1,0
    800046d6:	fc843503          	ld	a0,-56(s0)
    800046da:	ffffd097          	auipc	ra,0xffffd
    800046de:	a34080e7          	jalr	-1484(ra) # 8000110e <memset>
    
    if(map_page(p->pagetable, USTACK, (uint64)stack_page,
    800046e2:	fe043783          	ld	a5,-32(s0)
    800046e6:	67fc                	ld	a5,200(a5)
    800046e8:	fc843703          	ld	a4,-56(s0)
    800046ec:	46d9                	li	a3,22
    800046ee:	863a                	mv	a2,a4
    800046f0:	6591                	lui	a1,0x4
    800046f2:	853e                	mv	a0,a5
    800046f4:	ffffd097          	auipc	ra,0xffffd
    800046f8:	0d8080e7          	jalr	216(ra) # 800017cc <map_page>
    800046fc:	87aa                	mv	a5,a0
    800046fe:	cf95                	beqz	a5,8000473a <userinit+0x3da>
                PTE_R | PTE_W | PTE_U) != 0) {
        free_page(stack_page);
    80004700:	fc843503          	ld	a0,-56(s0)
    80004704:	ffffd097          	auipc	ra,0xffffd
    80004708:	c46080e7          	jalr	-954(ra) # 8000134a <free_page>
        proc_freepagetable(p->pagetable, PGSIZE);
    8000470c:	fe043783          	ld	a5,-32(s0)
    80004710:	67fc                	ld	a5,200(a5)
    80004712:	6585                	lui	a1,0x1
    80004714:	853e                	mv	a0,a5
    80004716:	ffffe097          	auipc	ra,0xffffe
    8000471a:	9c2080e7          	jalr	-1598(ra) # 800020d8 <proc_freepagetable>
        free_proc(p);
    8000471e:	fe043503          	ld	a0,-32(s0)
    80004722:	fffff097          	auipc	ra,0xfffff
    80004726:	438080e7          	jalr	1080(ra) # 80003b5a <free_proc>
        panic("userinit: map stack page");
    8000472a:	00004517          	auipc	a0,0x4
    8000472e:	9be50513          	add	a0,a0,-1602 # 800080e8 <userret+0x2084>
    80004732:	ffffd097          	auipc	ra,0xffffd
    80004736:	85a080e7          	jalr	-1958(ra) # 80000f8c <panic>
    }
    
    // 设置 trapframe
    memset(p->trapframe, 0, sizeof(struct trapframe));
    8000473a:	fe043783          	ld	a5,-32(s0)
    8000473e:	6bdc                	ld	a5,144(a5)
    80004740:	12000613          	li	a2,288
    80004744:	4581                	li	a1,0
    80004746:	853e                	mv	a0,a5
    80004748:	ffffd097          	auipc	ra,0xffffd
    8000474c:	9c6080e7          	jalr	-1594(ra) # 8000110e <memset>
    p->trapframe->sepc = 0;
    80004750:	fe043783          	ld	a5,-32(s0)
    80004754:	6bdc                	ld	a5,144(a5)
    80004756:	0e07bc23          	sd	zero,248(a5)
    p->trapframe->sp = USTACKTOP;
    8000475a:	fe043783          	ld	a5,-32(s0)
    8000475e:	6bdc                	ld	a5,144(a5)
    80004760:	6715                	lui	a4,0x5
    80004762:	e798                	sd	a4,8(a5)
    
    printf("[DEBUG] trapframe->sepc = %p\n", (void*)p->trapframe->sepc);
    80004764:	fe043783          	ld	a5,-32(s0)
    80004768:	6bdc                	ld	a5,144(a5)
    8000476a:	7ffc                	ld	a5,248(a5)
    8000476c:	85be                	mv	a1,a5
    8000476e:	00004517          	auipc	a0,0x4
    80004772:	99a50513          	add	a0,a0,-1638 # 80008108 <userret+0x20a4>
    80004776:	ffffc097          	auipc	ra,0xffffc
    8000477a:	470080e7          	jalr	1136(ra) # 80000be6 <printf>
    printf("[DEBUG] trapframe->sp = %p\n", (void*)p->trapframe->sp);
    8000477e:	fe043783          	ld	a5,-32(s0)
    80004782:	6bdc                	ld	a5,144(a5)
    80004784:	679c                	ld	a5,8(a5)
    80004786:	85be                	mv	a1,a5
    80004788:	00004517          	auipc	a0,0x4
    8000478c:	9a050513          	add	a0,a0,-1632 # 80008128 <userret+0x20c4>
    80004790:	ffffc097          	auipc	ra,0xffffc
    80004794:	456080e7          	jalr	1110(ra) # 80000be6 <printf>
    
    p->trapframe->sstatus = r_sstatus();
    80004798:	100027f3          	csrr	a5,sstatus
    8000479c:	fcf43023          	sd	a5,-64(s0)
    800047a0:	fc043703          	ld	a4,-64(s0)
    800047a4:	fe043783          	ld	a5,-32(s0)
    800047a8:	6bdc                	ld	a5,144(a5)
    800047aa:	10e7b023          	sd	a4,256(a5)
    p->trapframe->sstatus &= ~SSTATUS_SPP;
    800047ae:	fe043783          	ld	a5,-32(s0)
    800047b2:	6bdc                	ld	a5,144(a5)
    800047b4:	1007b703          	ld	a4,256(a5)
    800047b8:	fe043783          	ld	a5,-32(s0)
    800047bc:	6bdc                	ld	a5,144(a5)
    800047be:	eff77713          	and	a4,a4,-257
    800047c2:	10e7b023          	sd	a4,256(a5)
    p->trapframe->sstatus |= SSTATUS_SPIE;
    800047c6:	fe043783          	ld	a5,-32(s0)
    800047ca:	6bdc                	ld	a5,144(a5)
    800047cc:	1007b703          	ld	a4,256(a5)
    800047d0:	fe043783          	ld	a5,-32(s0)
    800047d4:	6bdc                	ld	a5,144(a5)
    800047d6:	02076713          	or	a4,a4,32
    800047da:	10e7b023          	sd	a4,256(a5)
    
    extern pagetable_t kernel_pagetable;
    p->trapframe->kernel_satp = MAKE_SATP(kernel_pagetable);
    800047de:	00006797          	auipc	a5,0x6
    800047e2:	82a78793          	add	a5,a5,-2006 # 8000a008 <kernel_pagetable>
    800047e6:	639c                	ld	a5,0(a5)
    800047e8:	00c7d693          	srl	a3,a5,0xc
    800047ec:	fe043783          	ld	a5,-32(s0)
    800047f0:	6bdc                	ld	a5,144(a5)
    800047f2:	577d                	li	a4,-1
    800047f4:	177e                	sll	a4,a4,0x3f
    800047f6:	8f55                	or	a4,a4,a3
    800047f8:	10e7b423          	sd	a4,264(a5)
    p->trapframe->kernel_sp = p->kstack + KSTACK_SIZE;
    800047fc:	fe043783          	ld	a5,-32(s0)
    80004800:	67d4                	ld	a3,136(a5)
    80004802:	fe043783          	ld	a5,-32(s0)
    80004806:	6bdc                	ld	a5,144(a5)
    80004808:	6705                	lui	a4,0x1
    8000480a:	9736                	add	a4,a4,a3
    8000480c:	10e7b823          	sd	a4,272(a5)
    p->trapframe->kernel_trap = (uint64)usertrap;
    80004810:	fe043783          	ld	a5,-32(s0)
    80004814:	6bdc                	ld	a5,144(a5)
    80004816:	ffffe717          	auipc	a4,0xffffe
    8000481a:	45470713          	add	a4,a4,1108 # 80002c6a <usertrap>
    8000481e:	10e7bc23          	sd	a4,280(a5)
    
    p->context.ra = (uint64)forkret;
    80004822:	fffff717          	auipc	a4,0xfffff
    80004826:	04070713          	add	a4,a4,64 # 80003862 <forkret>
    8000482a:	fe043783          	ld	a5,-32(s0)
    8000482e:	ef98                	sd	a4,24(a5)
    p->context.sp = p->kstack + KSTACK_SIZE;
    80004830:	fe043783          	ld	a5,-32(s0)
    80004834:	67d8                	ld	a4,136(a5)
    80004836:	6785                	lui	a5,0x1
    80004838:	973e                	add	a4,a4,a5
    8000483a:	fe043783          	ld	a5,-32(s0)
    8000483e:	f398                	sd	a4,32(a5)
    
    p->state = RUNNABLE;
    80004840:	fe043783          	ld	a5,-32(s0)
    80004844:	4709                	li	a4,2
    80004846:	c3d8                	sw	a4,4(a5)
    
    printf("Created first user process: PID=%d\n", p->pid);
    80004848:	fe043783          	ld	a5,-32(s0)
    8000484c:	439c                	lw	a5,0(a5)
    8000484e:	85be                	mv	a1,a5
    80004850:	00004517          	auipc	a0,0x4
    80004854:	8f850513          	add	a0,a0,-1800 # 80008148 <userret+0x20e4>
    80004858:	ffffc097          	auipc	ra,0xffffc
    8000485c:	38e080e7          	jalr	910(ra) # 80000be6 <printf>
    
    return p->pid;
    80004860:	fe043783          	ld	a5,-32(s0)
    80004864:	439c                	lw	a5,0(a5)
}
    80004866:	853e                	mv	a0,a5
    80004868:	70e2                	ld	ra,56(sp)
    8000486a:	7442                	ld	s0,48(sp)
    8000486c:	6121                	add	sp,sp,64
    8000486e:	8082                	ret

0000000080004870 <proc_info>:

// ==================== 辅助函数 ====================
void proc_info(void) { /* ... */ }
    80004870:	1141                	add	sp,sp,-16
    80004872:	e422                	sd	s0,8(sp)
    80004874:	0800                	add	s0,sp,16
    80004876:	0001                	nop
    80004878:	6422                	ld	s0,8(sp)
    8000487a:	0141                	add	sp,sp,16
    8000487c:	8082                	ret

000000008000487e <proc_stats>:
void proc_stats(void) { /* ... */ }
    8000487e:	1141                	add	sp,sp,-16
    80004880:	e422                	sd	s0,8(sp)
    80004882:	0800                	add	s0,sp,16
    80004884:	0001                	nop
    80004886:	6422                	ld	s0,8(sp)
    80004888:	0141                	add	sp,sp,16
    8000488a:	8082                	ret

000000008000488c <state_name>:
const char* state_name(enum procstate s)
{
    8000488c:	1101                	add	sp,sp,-32
    8000488e:	ec22                	sd	s0,24(sp)
    80004890:	1000                	add	s0,sp,32
    80004892:	87aa                	mv	a5,a0
    80004894:	fef42623          	sw	a5,-20(s0)
    if(s >= 0 && s <= 5) {
    80004898:	fec42783          	lw	a5,-20(s0)
    8000489c:	0007871b          	sext.w	a4,a5
    800048a0:	4795                	li	a5,5
    800048a2:	00e7ec63          	bltu	a5,a4,800048ba <state_name+0x2e>
        return state_names[s];
    800048a6:	fec46783          	lwu	a5,-20(s0)
    800048aa:	00479713          	sll	a4,a5,0x4
    800048ae:	00004797          	auipc	a5,0x4
    800048b2:	77a78793          	add	a5,a5,1914 # 80009028 <state_names>
    800048b6:	97ba                	add	a5,a5,a4
    800048b8:	a029                	j	800048c2 <state_name+0x36>
    }
    return state_names[6];
    800048ba:	00004797          	auipc	a5,0x4
    800048be:	7ce78793          	add	a5,a5,1998 # 80009088 <state_names+0x60>
    800048c2:	853e                	mv	a0,a5
    800048c4:	6462                	ld	s0,24(sp)
    800048c6:	6105                	add	sp,sp,32
    800048c8:	8082                	ret

00000000800048ca <swtch>:
# void swtch(struct context *old, struct context *new)

.globl swtch
swtch:
    # 保存旧上下文 (a0 = old)
    sd ra, 0(a0)
    800048ca:	00153023          	sd	ra,0(a0)
    sd sp, 8(a0)
    800048ce:	00253423          	sd	sp,8(a0)
    sd s0, 16(a0)
    800048d2:	e900                	sd	s0,16(a0)
    sd s1, 24(a0)
    800048d4:	ed04                	sd	s1,24(a0)
    sd s2, 32(a0)
    800048d6:	03253023          	sd	s2,32(a0)
    sd s3, 40(a0)
    800048da:	03353423          	sd	s3,40(a0)
    sd s4, 48(a0)
    800048de:	03453823          	sd	s4,48(a0)
    sd s5, 56(a0)
    800048e2:	03553c23          	sd	s5,56(a0)
    sd s6, 64(a0)
    800048e6:	05653023          	sd	s6,64(a0)
    sd s7, 72(a0)
    800048ea:	05753423          	sd	s7,72(a0)
    sd s8, 80(a0)
    800048ee:	05853823          	sd	s8,80(a0)
    sd s9, 88(a0)
    800048f2:	05953c23          	sd	s9,88(a0)
    sd s10, 96(a0)
    800048f6:	07a53023          	sd	s10,96(a0)
    sd s11, 104(a0)
    800048fa:	07b53423          	sd	s11,104(a0)
    
    # 恢复新上下文 (a1 = new)
    ld ra, 0(a1)
    800048fe:	0005b083          	ld	ra,0(a1) # 1000 <_entry-0x7ffff000>
    ld sp, 8(a1)
    80004902:	0085b103          	ld	sp,8(a1)
    ld s0, 16(a1)
    80004906:	6980                	ld	s0,16(a1)
    ld s1, 24(a1)
    80004908:	6d84                	ld	s1,24(a1)
    ld s2, 32(a1)
    8000490a:	0205b903          	ld	s2,32(a1)
    ld s3, 40(a1)
    8000490e:	0285b983          	ld	s3,40(a1)
    ld s4, 48(a1)
    80004912:	0305ba03          	ld	s4,48(a1)
    ld s5, 56(a1)
    80004916:	0385ba83          	ld	s5,56(a1)
    ld s6, 64(a1)
    8000491a:	0405bb03          	ld	s6,64(a1)
    ld s7, 72(a1)
    8000491e:	0485bb83          	ld	s7,72(a1)
    ld s8, 80(a1)
    80004922:	0505bc03          	ld	s8,80(a1)
    ld s9, 88(a1)
    80004926:	0585bc83          	ld	s9,88(a1)
    ld s10, 96(a1)
    8000492a:	0605bd03          	ld	s10,96(a1)
    ld s11, 104(a1)
    8000492e:	0685bd83          	ld	s11,104(a1)
    
    80004932:	8082                	ret

0000000080004934 <argint>:

// ==================== 参数提取函数 ====================

// 获取第n个整数参数
int argint(int n, int *ip)
{
    80004934:	7179                	add	sp,sp,-48
    80004936:	f406                	sd	ra,40(sp)
    80004938:	f022                	sd	s0,32(sp)
    8000493a:	1800                	add	s0,sp,48
    8000493c:	87aa                	mv	a5,a0
    8000493e:	fcb43823          	sd	a1,-48(s0)
    80004942:	fcf42e23          	sw	a5,-36(s0)
    struct proc *p = myproc();
    80004946:	fffff097          	auipc	ra,0xfffff
    8000494a:	092080e7          	jalr	146(ra) # 800039d8 <myproc>
    8000494e:	fea43423          	sd	a0,-24(s0)
    if(p == 0 || p->trapframe == 0)
    80004952:	fe843783          	ld	a5,-24(s0)
    80004956:	c789                	beqz	a5,80004960 <argint+0x2c>
    80004958:	fe843783          	ld	a5,-24(s0)
    8000495c:	6bdc                	ld	a5,144(a5)
    8000495e:	e399                	bnez	a5,80004964 <argint+0x30>
        return -1;
    80004960:	57fd                	li	a5,-1
    80004962:	a0e9                	j	80004a2c <argint+0xf8>
    
    if(n < 0 || n >= 6)
    80004964:	fdc42783          	lw	a5,-36(s0)
    80004968:	2781                	sext.w	a5,a5
    8000496a:	0007c963          	bltz	a5,8000497c <argint+0x48>
    8000496e:	fdc42783          	lw	a5,-36(s0)
    80004972:	0007871b          	sext.w	a4,a5
    80004976:	4795                	li	a5,5
    80004978:	00e7d463          	bge	a5,a4,80004980 <argint+0x4c>
        return -1;
    8000497c:	57fd                	li	a5,-1
    8000497e:	a07d                	j	80004a2c <argint+0xf8>
    
    switch(n) {
    80004980:	fdc42783          	lw	a5,-36(s0)
    80004984:	0007871b          	sext.w	a4,a5
    80004988:	4795                	li	a5,5
    8000498a:	0ae7e063          	bltu	a5,a4,80004a2a <argint+0xf6>
    8000498e:	fdc46783          	lwu	a5,-36(s0)
    80004992:	00279713          	sll	a4,a5,0x2
    80004996:	00004797          	auipc	a5,0x4
    8000499a:	82a78793          	add	a5,a5,-2006 # 800081c0 <userret+0x215c>
    8000499e:	97ba                	add	a5,a5,a4
    800049a0:	439c                	lw	a5,0(a5)
    800049a2:	0007871b          	sext.w	a4,a5
    800049a6:	00004797          	auipc	a5,0x4
    800049aa:	81a78793          	add	a5,a5,-2022 # 800081c0 <userret+0x215c>
    800049ae:	97ba                	add	a5,a5,a4
    800049b0:	8782                	jr	a5
        case 0: *ip = p->trapframe->a0; break;
    800049b2:	fe843783          	ld	a5,-24(s0)
    800049b6:	6bdc                	ld	a5,144(a5)
    800049b8:	67bc                	ld	a5,72(a5)
    800049ba:	0007871b          	sext.w	a4,a5
    800049be:	fd043783          	ld	a5,-48(s0)
    800049c2:	c398                	sw	a4,0(a5)
    800049c4:	a09d                	j	80004a2a <argint+0xf6>
        case 1: *ip = p->trapframe->a1; break;
    800049c6:	fe843783          	ld	a5,-24(s0)
    800049ca:	6bdc                	ld	a5,144(a5)
    800049cc:	6bbc                	ld	a5,80(a5)
    800049ce:	0007871b          	sext.w	a4,a5
    800049d2:	fd043783          	ld	a5,-48(s0)
    800049d6:	c398                	sw	a4,0(a5)
    800049d8:	a889                	j	80004a2a <argint+0xf6>
        case 2: *ip = p->trapframe->a2; break;
    800049da:	fe843783          	ld	a5,-24(s0)
    800049de:	6bdc                	ld	a5,144(a5)
    800049e0:	6fbc                	ld	a5,88(a5)
    800049e2:	0007871b          	sext.w	a4,a5
    800049e6:	fd043783          	ld	a5,-48(s0)
    800049ea:	c398                	sw	a4,0(a5)
    800049ec:	a83d                	j	80004a2a <argint+0xf6>
        case 3: *ip = p->trapframe->a3; break;
    800049ee:	fe843783          	ld	a5,-24(s0)
    800049f2:	6bdc                	ld	a5,144(a5)
    800049f4:	73bc                	ld	a5,96(a5)
    800049f6:	0007871b          	sext.w	a4,a5
    800049fa:	fd043783          	ld	a5,-48(s0)
    800049fe:	c398                	sw	a4,0(a5)
    80004a00:	a02d                	j	80004a2a <argint+0xf6>
        case 4: *ip = p->trapframe->a4; break;
    80004a02:	fe843783          	ld	a5,-24(s0)
    80004a06:	6bdc                	ld	a5,144(a5)
    80004a08:	77bc                	ld	a5,104(a5)
    80004a0a:	0007871b          	sext.w	a4,a5
    80004a0e:	fd043783          	ld	a5,-48(s0)
    80004a12:	c398                	sw	a4,0(a5)
    80004a14:	a819                	j	80004a2a <argint+0xf6>
        case 5: *ip = p->trapframe->a5; break;
    80004a16:	fe843783          	ld	a5,-24(s0)
    80004a1a:	6bdc                	ld	a5,144(a5)
    80004a1c:	7bbc                	ld	a5,112(a5)
    80004a1e:	0007871b          	sext.w	a4,a5
    80004a22:	fd043783          	ld	a5,-48(s0)
    80004a26:	c398                	sw	a4,0(a5)
    80004a28:	0001                	nop
    }
    return 0;
    80004a2a:	4781                	li	a5,0
}
    80004a2c:	853e                	mv	a0,a5
    80004a2e:	70a2                	ld	ra,40(sp)
    80004a30:	7402                	ld	s0,32(sp)
    80004a32:	6145                	add	sp,sp,48
    80004a34:	8082                	ret

0000000080004a36 <argaddr>:

// 获取第n个地址参数
int argaddr(int n, uint64 *ip)
{
    80004a36:	7179                	add	sp,sp,-48
    80004a38:	f406                	sd	ra,40(sp)
    80004a3a:	f022                	sd	s0,32(sp)
    80004a3c:	1800                	add	s0,sp,48
    80004a3e:	87aa                	mv	a5,a0
    80004a40:	fcb43823          	sd	a1,-48(s0)
    80004a44:	fcf42e23          	sw	a5,-36(s0)
    struct proc *p = myproc();
    80004a48:	fffff097          	auipc	ra,0xfffff
    80004a4c:	f90080e7          	jalr	-112(ra) # 800039d8 <myproc>
    80004a50:	fea43423          	sd	a0,-24(s0)
    if(p == 0 || p->trapframe == 0)
    80004a54:	fe843783          	ld	a5,-24(s0)
    80004a58:	c789                	beqz	a5,80004a62 <argaddr+0x2c>
    80004a5a:	fe843783          	ld	a5,-24(s0)
    80004a5e:	6bdc                	ld	a5,144(a5)
    80004a60:	e399                	bnez	a5,80004a66 <argaddr+0x30>
        return -1;
    80004a62:	57fd                	li	a5,-1
    80004a64:	a84d                	j	80004b16 <argaddr+0xe0>
    
    if(n < 0 || n >= 6)
    80004a66:	fdc42783          	lw	a5,-36(s0)
    80004a6a:	2781                	sext.w	a5,a5
    80004a6c:	0007c963          	bltz	a5,80004a7e <argaddr+0x48>
    80004a70:	fdc42783          	lw	a5,-36(s0)
    80004a74:	0007871b          	sext.w	a4,a5
    80004a78:	4795                	li	a5,5
    80004a7a:	00e7d463          	bge	a5,a4,80004a82 <argaddr+0x4c>
        return -1;
    80004a7e:	57fd                	li	a5,-1
    80004a80:	a859                	j	80004b16 <argaddr+0xe0>
    
    switch(n) {
    80004a82:	fdc42783          	lw	a5,-36(s0)
    80004a86:	0007871b          	sext.w	a4,a5
    80004a8a:	4795                	li	a5,5
    80004a8c:	08e7e463          	bltu	a5,a4,80004b14 <argaddr+0xde>
    80004a90:	fdc46783          	lwu	a5,-36(s0)
    80004a94:	00279713          	sll	a4,a5,0x2
    80004a98:	00003797          	auipc	a5,0x3
    80004a9c:	74078793          	add	a5,a5,1856 # 800081d8 <userret+0x2174>
    80004aa0:	97ba                	add	a5,a5,a4
    80004aa2:	439c                	lw	a5,0(a5)
    80004aa4:	0007871b          	sext.w	a4,a5
    80004aa8:	00003797          	auipc	a5,0x3
    80004aac:	73078793          	add	a5,a5,1840 # 800081d8 <userret+0x2174>
    80004ab0:	97ba                	add	a5,a5,a4
    80004ab2:	8782                	jr	a5
        case 0: *ip = p->trapframe->a0; break;
    80004ab4:	fe843783          	ld	a5,-24(s0)
    80004ab8:	6bdc                	ld	a5,144(a5)
    80004aba:	67b8                	ld	a4,72(a5)
    80004abc:	fd043783          	ld	a5,-48(s0)
    80004ac0:	e398                	sd	a4,0(a5)
    80004ac2:	a889                	j	80004b14 <argaddr+0xde>
        case 1: *ip = p->trapframe->a1; break;
    80004ac4:	fe843783          	ld	a5,-24(s0)
    80004ac8:	6bdc                	ld	a5,144(a5)
    80004aca:	6bb8                	ld	a4,80(a5)
    80004acc:	fd043783          	ld	a5,-48(s0)
    80004ad0:	e398                	sd	a4,0(a5)
    80004ad2:	a089                	j	80004b14 <argaddr+0xde>
        case 2: *ip = p->trapframe->a2; break;
    80004ad4:	fe843783          	ld	a5,-24(s0)
    80004ad8:	6bdc                	ld	a5,144(a5)
    80004ada:	6fb8                	ld	a4,88(a5)
    80004adc:	fd043783          	ld	a5,-48(s0)
    80004ae0:	e398                	sd	a4,0(a5)
    80004ae2:	a80d                	j	80004b14 <argaddr+0xde>
        case 3: *ip = p->trapframe->a3; break;
    80004ae4:	fe843783          	ld	a5,-24(s0)
    80004ae8:	6bdc                	ld	a5,144(a5)
    80004aea:	73b8                	ld	a4,96(a5)
    80004aec:	fd043783          	ld	a5,-48(s0)
    80004af0:	e398                	sd	a4,0(a5)
    80004af2:	a00d                	j	80004b14 <argaddr+0xde>
        case 4: *ip = p->trapframe->a4; break;
    80004af4:	fe843783          	ld	a5,-24(s0)
    80004af8:	6bdc                	ld	a5,144(a5)
    80004afa:	77b8                	ld	a4,104(a5)
    80004afc:	fd043783          	ld	a5,-48(s0)
    80004b00:	e398                	sd	a4,0(a5)
    80004b02:	a809                	j	80004b14 <argaddr+0xde>
        case 5: *ip = p->trapframe->a5; break;
    80004b04:	fe843783          	ld	a5,-24(s0)
    80004b08:	6bdc                	ld	a5,144(a5)
    80004b0a:	7bb8                	ld	a4,112(a5)
    80004b0c:	fd043783          	ld	a5,-48(s0)
    80004b10:	e398                	sd	a4,0(a5)
    80004b12:	0001                	nop
    }
    return 0;
    80004b14:	4781                	li	a5,0
}
    80004b16:	853e                	mv	a0,a5
    80004b18:	70a2                	ld	ra,40(sp)
    80004b1a:	7402                	ld	s0,32(sp)
    80004b1c:	6145                	add	sp,sp,48
    80004b1e:	8082                	ret

0000000080004b20 <argstr>:

// 获取第n个字符串参数（使用 copyin 从用户空间安全读取）
int argstr(int n, char *buf, int max)
{
    80004b20:	7139                	add	sp,sp,-64
    80004b22:	fc06                	sd	ra,56(sp)
    80004b24:	f822                	sd	s0,48(sp)
    80004b26:	0080                	add	s0,sp,64
    80004b28:	87aa                	mv	a5,a0
    80004b2a:	fcb43023          	sd	a1,-64(s0)
    80004b2e:	8732                	mv	a4,a2
    80004b30:	fcf42623          	sw	a5,-52(s0)
    80004b34:	87ba                	mv	a5,a4
    80004b36:	fcf42423          	sw	a5,-56(s0)
    uint64 addr;
    if(argaddr(n, &addr) < 0)
    80004b3a:	fd840713          	add	a4,s0,-40
    80004b3e:	fcc42783          	lw	a5,-52(s0)
    80004b42:	85ba                	mv	a1,a4
    80004b44:	853e                	mv	a0,a5
    80004b46:	00000097          	auipc	ra,0x0
    80004b4a:	ef0080e7          	jalr	-272(ra) # 80004a36 <argaddr>
    80004b4e:	87aa                	mv	a5,a0
    80004b50:	0007d463          	bgez	a5,80004b58 <argstr+0x38>
        return -1;
    80004b54:	57fd                	li	a5,-1
    80004b56:	a871                	j	80004bf2 <argstr+0xd2>

    struct proc *p = myproc();
    80004b58:	fffff097          	auipc	ra,0xfffff
    80004b5c:	e80080e7          	jalr	-384(ra) # 800039d8 <myproc>
    80004b60:	fea43023          	sd	a0,-32(s0)
    if(p == 0 || p->pagetable == 0)
    80004b64:	fe043783          	ld	a5,-32(s0)
    80004b68:	c789                	beqz	a5,80004b72 <argstr+0x52>
    80004b6a:	fe043783          	ld	a5,-32(s0)
    80004b6e:	67fc                	ld	a5,200(a5)
    80004b70:	e399                	bnez	a5,80004b76 <argstr+0x56>
        return -1;
    80004b72:	57fd                	li	a5,-1
    80004b74:	a8bd                	j	80004bf2 <argstr+0xd2>

    int i = 0;
    80004b76:	fe042623          	sw	zero,-20(s0)
    while(i + 1 < max) {
    80004b7a:	a891                	j	80004bce <argstr+0xae>
        char c;
        // 每次从用户虚拟地址 addr + i 读一个字节到内核 c
        if(copyin(p->pagetable, &c, addr + i, 1) < 0)
    80004b7c:	fe043783          	ld	a5,-32(s0)
    80004b80:	67e8                	ld	a0,200(a5)
    80004b82:	fec42703          	lw	a4,-20(s0)
    80004b86:	fd843783          	ld	a5,-40(s0)
    80004b8a:	973e                	add	a4,a4,a5
    80004b8c:	fd740793          	add	a5,s0,-41
    80004b90:	4685                	li	a3,1
    80004b92:	863a                	mv	a2,a4
    80004b94:	85be                	mv	a1,a5
    80004b96:	ffffd097          	auipc	ra,0xffffd
    80004b9a:	1b0080e7          	jalr	432(ra) # 80001d46 <copyin>
    80004b9e:	87aa                	mv	a5,a0
    80004ba0:	0007d463          	bgez	a5,80004ba8 <argstr+0x88>
            return -1;
    80004ba4:	57fd                	li	a5,-1
    80004ba6:	a0b1                	j	80004bf2 <argstr+0xd2>
        buf[i++] = c;
    80004ba8:	fec42783          	lw	a5,-20(s0)
    80004bac:	0017871b          	addw	a4,a5,1
    80004bb0:	fee42623          	sw	a4,-20(s0)
    80004bb4:	873e                	mv	a4,a5
    80004bb6:	fc043783          	ld	a5,-64(s0)
    80004bba:	97ba                	add	a5,a5,a4
    80004bbc:	fd744703          	lbu	a4,-41(s0)
    80004bc0:	00e78023          	sb	a4,0(a5)
        if(c == 0) {
    80004bc4:	fd744783          	lbu	a5,-41(s0)
    80004bc8:	e399                	bnez	a5,80004bce <argstr+0xae>
            return 0;   // 成功
    80004bca:	4781                	li	a5,0
    80004bcc:	a01d                	j	80004bf2 <argstr+0xd2>
    while(i + 1 < max) {
    80004bce:	fec42783          	lw	a5,-20(s0)
    80004bd2:	2785                	addw	a5,a5,1
    80004bd4:	0007871b          	sext.w	a4,a5
    80004bd8:	fc842783          	lw	a5,-56(s0)
    80004bdc:	2781                	sext.w	a5,a5
    80004bde:	f8f74fe3          	blt	a4,a5,80004b7c <argstr+0x5c>
        }
    }
    buf[i] = 0;
    80004be2:	fec42783          	lw	a5,-20(s0)
    80004be6:	fc043703          	ld	a4,-64(s0)
    80004bea:	97ba                	add	a5,a5,a4
    80004bec:	00078023          	sb	zero,0(a5)
    return -1;          // 字符串太长
    80004bf0:	57fd                	li	a5,-1
}
    80004bf2:	853e                	mv	a0,a5
    80004bf4:	70e2                	ld	ra,56(sp)
    80004bf6:	7442                	ld	s0,48(sp)
    80004bf8:	6121                	add	sp,sp,64
    80004bfa:	8082                	ret

0000000080004bfc <syscall>:

// ==================== 系统调用分发器 ====================
void syscall(struct trapframe *tf)
{
    80004bfc:	7179                	add	sp,sp,-48
    80004bfe:	f406                	sd	ra,40(sp)
    80004c00:	f022                	sd	s0,32(sp)
    80004c02:	1800                	add	s0,sp,48
    80004c04:	fca43c23          	sd	a0,-40(s0)
    struct proc *p = myproc();
    80004c08:	fffff097          	auipc	ra,0xfffff
    80004c0c:	dd0080e7          	jalr	-560(ra) # 800039d8 <myproc>
    80004c10:	fea43423          	sd	a0,-24(s0)
    if(p == 0) {
    80004c14:	fe843783          	ld	a5,-24(s0)
    80004c18:	eb91                	bnez	a5,80004c2c <syscall+0x30>
        printf("syscall: no process\n");
    80004c1a:	00003517          	auipc	a0,0x3
    80004c1e:	5d650513          	add	a0,a0,1494 # 800081f0 <userret+0x218c>
    80004c22:	ffffc097          	auipc	ra,0xffffc
    80004c26:	fc4080e7          	jalr	-60(ra) # 80000be6 <printf>
        return;
    80004c2a:	a8c1                	j	80004cfa <syscall+0xfe>
    }
    
    int num = tf->a7;
    80004c2c:	fd843783          	ld	a5,-40(s0)
    80004c30:	63dc                	ld	a5,128(a5)
    80004c32:	fef42223          	sw	a5,-28(s0)
    
    // 调试输出
    if(num > 0 && num < sizeof(syscall_names)/sizeof(syscall_names[0]) && syscall_names[num]) {
    80004c36:	fe442783          	lw	a5,-28(s0)
    80004c3a:	2781                	sext.w	a5,a5
    80004c3c:	04f05863          	blez	a5,80004c8c <syscall+0x90>
    80004c40:	fe442783          	lw	a5,-28(s0)
    80004c44:	873e                	mv	a4,a5
    80004c46:	47a9                	li	a5,10
    80004c48:	04e7e263          	bltu	a5,a4,80004c8c <syscall+0x90>
    80004c4c:	00004717          	auipc	a4,0x4
    80004c50:	4a470713          	add	a4,a4,1188 # 800090f0 <syscall_names>
    80004c54:	fe442783          	lw	a5,-28(s0)
    80004c58:	078e                	sll	a5,a5,0x3
    80004c5a:	97ba                	add	a5,a5,a4
    80004c5c:	639c                	ld	a5,0(a5)
    80004c5e:	c79d                	beqz	a5,80004c8c <syscall+0x90>
        printf("[syscall] PID %d: %s\n", p->pid, syscall_names[num]);
    80004c60:	fe843783          	ld	a5,-24(s0)
    80004c64:	4394                	lw	a3,0(a5)
    80004c66:	00004717          	auipc	a4,0x4
    80004c6a:	48a70713          	add	a4,a4,1162 # 800090f0 <syscall_names>
    80004c6e:	fe442783          	lw	a5,-28(s0)
    80004c72:	078e                	sll	a5,a5,0x3
    80004c74:	97ba                	add	a5,a5,a4
    80004c76:	639c                	ld	a5,0(a5)
    80004c78:	863e                	mv	a2,a5
    80004c7a:	85b6                	mv	a1,a3
    80004c7c:	00003517          	auipc	a0,0x3
    80004c80:	58c50513          	add	a0,a0,1420 # 80008208 <userret+0x21a4>
    80004c84:	ffffc097          	auipc	ra,0xffffc
    80004c88:	f62080e7          	jalr	-158(ra) # 80000be6 <printf>
    }
    
    // 检查系统调用号有效性
    if(num > 0 && num < sizeof(syscalls)/sizeof(syscalls[0]) && syscalls[num]) {
    80004c8c:	fe442783          	lw	a5,-28(s0)
    80004c90:	2781                	sext.w	a5,a5
    80004c92:	04f05563          	blez	a5,80004cdc <syscall+0xe0>
    80004c96:	fe442783          	lw	a5,-28(s0)
    80004c9a:	873e                	mv	a4,a5
    80004c9c:	47a9                	li	a5,10
    80004c9e:	02e7ef63          	bltu	a5,a4,80004cdc <syscall+0xe0>
    80004ca2:	00004717          	auipc	a4,0x4
    80004ca6:	3f670713          	add	a4,a4,1014 # 80009098 <syscalls>
    80004caa:	fe442783          	lw	a5,-28(s0)
    80004cae:	078e                	sll	a5,a5,0x3
    80004cb0:	97ba                	add	a5,a5,a4
    80004cb2:	639c                	ld	a5,0(a5)
    80004cb4:	c785                	beqz	a5,80004cdc <syscall+0xe0>
        int ret = syscalls[num]();
    80004cb6:	00004717          	auipc	a4,0x4
    80004cba:	3e270713          	add	a4,a4,994 # 80009098 <syscalls>
    80004cbe:	fe442783          	lw	a5,-28(s0)
    80004cc2:	078e                	sll	a5,a5,0x3
    80004cc4:	97ba                	add	a5,a5,a4
    80004cc6:	639c                	ld	a5,0(a5)
    80004cc8:	9782                	jalr	a5
    80004cca:	87aa                	mv	a5,a0
    80004ccc:	fef42023          	sw	a5,-32(s0)
        tf->a0 = ret;
    80004cd0:	fe042703          	lw	a4,-32(s0)
    80004cd4:	fd843783          	ld	a5,-40(s0)
    80004cd8:	e7b8                	sd	a4,72(a5)
    if(num > 0 && num < sizeof(syscalls)/sizeof(syscalls[0]) && syscalls[num]) {
    80004cda:	a005                	j	80004cfa <syscall+0xfe>
    } else {
        printf("syscall: unknown syscall %d\n", num);
    80004cdc:	fe442783          	lw	a5,-28(s0)
    80004ce0:	85be                	mv	a1,a5
    80004ce2:	00003517          	auipc	a0,0x3
    80004ce6:	53e50513          	add	a0,a0,1342 # 80008220 <userret+0x21bc>
    80004cea:	ffffc097          	auipc	ra,0xffffc
    80004cee:	efc080e7          	jalr	-260(ra) # 80000be6 <printf>
        tf->a0 = -1;
    80004cf2:	fd843783          	ld	a5,-40(s0)
    80004cf6:	577d                	li	a4,-1
    80004cf8:	e7b8                	sd	a4,72(a5)
    }

    // ⭐ 不再在这里修改 sepc，由 usertrap() 负责 sepc += 4
}
    80004cfa:	70a2                	ld	ra,40(sp)
    80004cfc:	7402                	ld	s0,32(sp)
    80004cfe:	6145                	add	sp,sp,48
    80004d00:	8082                	ret

0000000080004d02 <sys_getpid>:
#include "proc.h"
#include "syscall.h"

// ==================== sys_getpid ====================
int sys_getpid(void)
{
    80004d02:	1101                	add	sp,sp,-32
    80004d04:	ec06                	sd	ra,24(sp)
    80004d06:	e822                	sd	s0,16(sp)
    80004d08:	1000                	add	s0,sp,32
    struct proc *p = myproc();
    80004d0a:	fffff097          	auipc	ra,0xfffff
    80004d0e:	cce080e7          	jalr	-818(ra) # 800039d8 <myproc>
    80004d12:	fea43423          	sd	a0,-24(s0)
    if(p == 0)
    80004d16:	fe843783          	ld	a5,-24(s0)
    80004d1a:	e399                	bnez	a5,80004d20 <sys_getpid+0x1e>
        return -1;
    80004d1c:	57fd                	li	a5,-1
    80004d1e:	a021                	j	80004d26 <sys_getpid+0x24>
    return p->pid;
    80004d20:	fe843783          	ld	a5,-24(s0)
    80004d24:	439c                	lw	a5,0(a5)
}
    80004d26:	853e                	mv	a0,a5
    80004d28:	60e2                	ld	ra,24(sp)
    80004d2a:	6442                	ld	s0,16(sp)
    80004d2c:	6105                	add	sp,sp,32
    80004d2e:	8082                	ret

0000000080004d30 <sys_fork>:

// ==================== sys_fork ====================
int sys_fork(void)
{
    80004d30:	1141                	add	sp,sp,-16
    80004d32:	e406                	sd	ra,8(sp)
    80004d34:	e022                	sd	s0,0(sp)
    80004d36:	0800                	add	s0,sp,16
    printf("sys_fork: not implemented yet\n");
    80004d38:	00003517          	auipc	a0,0x3
    80004d3c:	50850513          	add	a0,a0,1288 # 80008240 <userret+0x21dc>
    80004d40:	ffffc097          	auipc	ra,0xffffc
    80004d44:	ea6080e7          	jalr	-346(ra) # 80000be6 <printf>
    return -1;
    80004d48:	57fd                	li	a5,-1
}
    80004d4a:	853e                	mv	a0,a5
    80004d4c:	60a2                	ld	ra,8(sp)
    80004d4e:	6402                	ld	s0,0(sp)
    80004d50:	0141                	add	sp,sp,16
    80004d52:	8082                	ret

0000000080004d54 <sys_exit>:

// ==================== sys_exit ====================
int sys_exit(void)
{
    80004d54:	1101                	add	sp,sp,-32
    80004d56:	ec06                	sd	ra,24(sp)
    80004d58:	e822                	sd	s0,16(sp)
    80004d5a:	1000                	add	s0,sp,32
    int status;
    if(argint(0, &status) < 0)
    80004d5c:	fec40793          	add	a5,s0,-20
    80004d60:	85be                	mv	a1,a5
    80004d62:	4501                	li	a0,0
    80004d64:	00000097          	auipc	ra,0x0
    80004d68:	bd0080e7          	jalr	-1072(ra) # 80004934 <argint>
    80004d6c:	87aa                	mv	a5,a0
    80004d6e:	0007d463          	bgez	a5,80004d76 <sys_exit+0x22>
        return -1;
    80004d72:	57fd                	li	a5,-1
    80004d74:	a809                	j	80004d86 <sys_exit+0x32>
    
    exit_proc(status);
    80004d76:	fec42783          	lw	a5,-20(s0)
    80004d7a:	853e                	mv	a0,a5
    80004d7c:	fffff097          	auipc	ra,0xfffff
    80004d80:	474080e7          	jalr	1140(ra) # 800041f0 <exit_proc>
    return 0;  // 不会到达这里
    80004d84:	4781                	li	a5,0
}
    80004d86:	853e                	mv	a0,a5
    80004d88:	60e2                	ld	ra,24(sp)
    80004d8a:	6442                	ld	s0,16(sp)
    80004d8c:	6105                	add	sp,sp,32
    80004d8e:	8082                	ret

0000000080004d90 <sys_wait>:

// ==================== sys_wait ====================
int sys_wait(void)
{
    80004d90:	1101                	add	sp,sp,-32
    80004d92:	ec06                	sd	ra,24(sp)
    80004d94:	e822                	sd	s0,16(sp)
    80004d96:	1000                	add	s0,sp,32
    uint64 addr;
    if(argaddr(0, &addr) < 0)
    80004d98:	fe040793          	add	a5,s0,-32
    80004d9c:	85be                	mv	a1,a5
    80004d9e:	4501                	li	a0,0
    80004da0:	00000097          	auipc	ra,0x0
    80004da4:	c96080e7          	jalr	-874(ra) # 80004a36 <argaddr>
    80004da8:	87aa                	mv	a5,a0
    80004daa:	0007d463          	bgez	a5,80004db2 <sys_wait+0x22>
        return -1;
    80004dae:	57fd                	li	a5,-1
    80004db0:	a821                	j	80004dc8 <sys_wait+0x38>
    
    int *status = (int*)addr;    // 注意：这里只是传给 wait_proc，真正 copyout 由上层自己控制
    80004db2:	fe043783          	ld	a5,-32(s0)
    80004db6:	fef43423          	sd	a5,-24(s0)
    return wait_proc(status);
    80004dba:	fe843503          	ld	a0,-24(s0)
    80004dbe:	fffff097          	auipc	ra,0xfffff
    80004dc2:	4e6080e7          	jalr	1254(ra) # 800042a4 <wait_proc>
    80004dc6:	87aa                	mv	a5,a0
}
    80004dc8:	853e                	mv	a0,a5
    80004dca:	60e2                	ld	ra,24(sp)
    80004dcc:	6442                	ld	s0,16(sp)
    80004dce:	6105                	add	sp,sp,32
    80004dd0:	8082                	ret

0000000080004dd2 <sys_kill>:

// ==================== sys_kill ====================
int sys_kill(void)
{
    80004dd2:	1101                	add	sp,sp,-32
    80004dd4:	ec06                	sd	ra,24(sp)
    80004dd6:	e822                	sd	s0,16(sp)
    80004dd8:	1000                	add	s0,sp,32
    int pid;
    if(argint(0, &pid) < 0)
    80004dda:	fe440793          	add	a5,s0,-28
    80004dde:	85be                	mv	a1,a5
    80004de0:	4501                	li	a0,0
    80004de2:	00000097          	auipc	ra,0x0
    80004de6:	b52080e7          	jalr	-1198(ra) # 80004934 <argint>
    80004dea:	87aa                	mv	a5,a0
    80004dec:	0007d463          	bgez	a5,80004df4 <sys_kill+0x22>
        return -1;
    80004df0:	57fd                	li	a5,-1
    80004df2:	a085                	j	80004e52 <sys_kill+0x80>
    
    // 遍历进程表查找目标进程
    struct proc *p;
    for(p = proc; p < &proc[NPROC]; p++) {
    80004df4:	00009797          	auipc	a5,0x9
    80004df8:	36c78793          	add	a5,a5,876 # 8000e160 <proc>
    80004dfc:	fef43423          	sd	a5,-24(s0)
    80004e00:	a081                	j	80004e40 <sys_kill+0x6e>
        if(p->pid == pid) {
    80004e02:	fe843783          	ld	a5,-24(s0)
    80004e06:	4398                	lw	a4,0(a5)
    80004e08:	fe442783          	lw	a5,-28(s0)
    80004e0c:	02f71463          	bne	a4,a5,80004e34 <sys_kill+0x62>
            p->killed = 1;
    80004e10:	fe843783          	ld	a5,-24(s0)
    80004e14:	4705                	li	a4,1
    80004e16:	0ce7a023          	sw	a4,192(a5)
            // 如果进程在睡眠，唤醒它
            if(p->state == SLEEPING) {
    80004e1a:	fe843783          	ld	a5,-24(s0)
    80004e1e:	43dc                	lw	a5,4(a5)
    80004e20:	873e                	mv	a4,a5
    80004e22:	4791                	li	a5,4
    80004e24:	00f71663          	bne	a4,a5,80004e30 <sys_kill+0x5e>
                p->state = RUNNABLE;
    80004e28:	fe843783          	ld	a5,-24(s0)
    80004e2c:	4709                	li	a4,2
    80004e2e:	c3d8                	sw	a4,4(a5)
            }
            return 0;
    80004e30:	4781                	li	a5,0
    80004e32:	a005                	j	80004e52 <sys_kill+0x80>
    for(p = proc; p < &proc[NPROC]; p++) {
    80004e34:	fe843783          	ld	a5,-24(s0)
    80004e38:	0d078793          	add	a5,a5,208
    80004e3c:	fef43423          	sd	a5,-24(s0)
    80004e40:	fe843703          	ld	a4,-24(s0)
    80004e44:	0000c797          	auipc	a5,0xc
    80004e48:	71c78793          	add	a5,a5,1820 # 80011560 <cpus>
    80004e4c:	faf76be3          	bltu	a4,a5,80004e02 <sys_kill+0x30>
        }
    }
    return -1;  // 进程不存在
    80004e50:	57fd                	li	a5,-1
}
    80004e52:	853e                	mv	a0,a5
    80004e54:	60e2                	ld	ra,24(sp)
    80004e56:	6442                	ld	s0,16(sp)
    80004e58:	6105                	add	sp,sp,32
    80004e5a:	8082                	ret

0000000080004e5c <sys_write>:

// ==================== sys_write ====================
// fd, buf, count
int sys_write(void)
{
    80004e5c:	bc010113          	add	sp,sp,-1088
    80004e60:	42113c23          	sd	ra,1080(sp)
    80004e64:	42813823          	sd	s0,1072(sp)
    80004e68:	44010413          	add	s0,sp,1088
    int fd;
    uint64 ubuf;   // 用户空间缓冲区虚拟地址
    int count;
    
    // 提取参数：fd, buf, count
    if(argint(0, &fd) < 0 || argaddr(1, &ubuf) < 0 || argint(2, &count) < 0)
    80004e6c:	fdc40793          	add	a5,s0,-36
    80004e70:	85be                	mv	a1,a5
    80004e72:	4501                	li	a0,0
    80004e74:	00000097          	auipc	ra,0x0
    80004e78:	ac0080e7          	jalr	-1344(ra) # 80004934 <argint>
    80004e7c:	87aa                	mv	a5,a0
    80004e7e:	0207c863          	bltz	a5,80004eae <sys_write+0x52>
    80004e82:	fd040793          	add	a5,s0,-48
    80004e86:	85be                	mv	a1,a5
    80004e88:	4505                	li	a0,1
    80004e8a:	00000097          	auipc	ra,0x0
    80004e8e:	bac080e7          	jalr	-1108(ra) # 80004a36 <argaddr>
    80004e92:	87aa                	mv	a5,a0
    80004e94:	0007cd63          	bltz	a5,80004eae <sys_write+0x52>
    80004e98:	fcc40793          	add	a5,s0,-52
    80004e9c:	85be                	mv	a1,a5
    80004e9e:	4509                	li	a0,2
    80004ea0:	00000097          	auipc	ra,0x0
    80004ea4:	a94080e7          	jalr	-1388(ra) # 80004934 <argint>
    80004ea8:	87aa                	mv	a5,a0
    80004eaa:	0007d463          	bgez	a5,80004eb2 <sys_write+0x56>
        return -1;
    80004eae:	57fd                	li	a5,-1
    80004eb0:	a87d                	j	80004f6e <sys_write+0x112>
    
    // 简化版：只支持 fd=1 (stdout)
    if(fd != 1) {
    80004eb2:	fdc42783          	lw	a5,-36(s0)
    80004eb6:	873e                	mv	a4,a5
    80004eb8:	4785                	li	a5,1
    80004eba:	00f70c63          	beq	a4,a5,80004ed2 <sys_write+0x76>
        printf("sys_write: only stdout (fd=1) supported\n");
    80004ebe:	00003517          	auipc	a0,0x3
    80004ec2:	3a250513          	add	a0,a0,930 # 80008260 <userret+0x21fc>
    80004ec6:	ffffc097          	auipc	ra,0xffffc
    80004eca:	d20080e7          	jalr	-736(ra) # 80000be6 <printf>
        return -1;
    80004ece:	57fd                	li	a5,-1
    80004ed0:	a879                	j	80004f6e <sys_write+0x112>
    }
    
    // 检查 count 范围
    if(count < 0 || count > 1024) {
    80004ed2:	fcc42783          	lw	a5,-52(s0)
    80004ed6:	0007c963          	bltz	a5,80004ee8 <sys_write+0x8c>
    80004eda:	fcc42783          	lw	a5,-52(s0)
    80004ede:	873e                	mv	a4,a5
    80004ee0:	40000793          	li	a5,1024
    80004ee4:	00e7d463          	bge	a5,a4,80004eec <sys_write+0x90>
        return -1;
    80004ee8:	57fd                	li	a5,-1
    80004eea:	a051                	j	80004f6e <sys_write+0x112>
    }

    struct proc *p = myproc();
    80004eec:	fffff097          	auipc	ra,0xfffff
    80004ef0:	aec080e7          	jalr	-1300(ra) # 800039d8 <myproc>
    80004ef4:	fea43023          	sd	a0,-32(s0)
    if(p == 0 || p->pagetable == 0)
    80004ef8:	fe043783          	ld	a5,-32(s0)
    80004efc:	c789                	beqz	a5,80004f06 <sys_write+0xaa>
    80004efe:	fe043783          	ld	a5,-32(s0)
    80004f02:	67fc                	ld	a5,200(a5)
    80004f04:	e399                	bnez	a5,80004f0a <sys_write+0xae>
        return -1;
    80004f06:	57fd                	li	a5,-1
    80004f08:	a09d                	j	80004f6e <sys_write+0x112>

    char kbuf[1024];
    // 从用户空间拷贝 count 字节到内核缓冲区
    if(copyin(p->pagetable, kbuf, ubuf, count) < 0)
    80004f0a:	fe043783          	ld	a5,-32(s0)
    80004f0e:	67fc                	ld	a5,200(a5)
    80004f10:	fd043603          	ld	a2,-48(s0)
    80004f14:	fcc42703          	lw	a4,-52(s0)
    80004f18:	86ba                	mv	a3,a4
    80004f1a:	bc840713          	add	a4,s0,-1080
    80004f1e:	85ba                	mv	a1,a4
    80004f20:	853e                	mv	a0,a5
    80004f22:	ffffd097          	auipc	ra,0xffffd
    80004f26:	e24080e7          	jalr	-476(ra) # 80001d46 <copyin>
    80004f2a:	87aa                	mv	a5,a0
    80004f2c:	0007d463          	bgez	a5,80004f34 <sys_write+0xd8>
        return -1;
    80004f30:	57fd                	li	a5,-1
    80004f32:	a835                	j	80004f6e <sys_write+0x112>
    
    // 逐字节输出
    for(int i = 0; i < count; i++) {
    80004f34:	fe042623          	sw	zero,-20(s0)
    80004f38:	a015                	j	80004f5c <sys_write+0x100>
        consputc(kbuf[i]);
    80004f3a:	fec42783          	lw	a5,-20(s0)
    80004f3e:	17c1                	add	a5,a5,-16
    80004f40:	97a2                	add	a5,a5,s0
    80004f42:	bd87c783          	lbu	a5,-1064(a5)
    80004f46:	2781                	sext.w	a5,a5
    80004f48:	853e                	mv	a0,a5
    80004f4a:	ffffc097          	auipc	ra,0xffffc
    80004f4e:	abc080e7          	jalr	-1348(ra) # 80000a06 <consputc>
    for(int i = 0; i < count; i++) {
    80004f52:	fec42783          	lw	a5,-20(s0)
    80004f56:	2785                	addw	a5,a5,1
    80004f58:	fef42623          	sw	a5,-20(s0)
    80004f5c:	fcc42703          	lw	a4,-52(s0)
    80004f60:	fec42783          	lw	a5,-20(s0)
    80004f64:	2781                	sext.w	a5,a5
    80004f66:	fce7cae3          	blt	a5,a4,80004f3a <sys_write+0xde>
    }
    
    return count;
    80004f6a:	fcc42783          	lw	a5,-52(s0)
}
    80004f6e:	853e                	mv	a0,a5
    80004f70:	43813083          	ld	ra,1080(sp)
    80004f74:	43013403          	ld	s0,1072(sp)
    80004f78:	44010113          	add	sp,sp,1088
    80004f7c:	8082                	ret

0000000080004f7e <sys_read>:

// ==================== sys_read ====================
// fd, buf, count
int sys_read(void)
{
    80004f7e:	7139                	add	sp,sp,-64
    80004f80:	fc06                	sd	ra,56(sp)
    80004f82:	f822                	sd	s0,48(sp)
    80004f84:	0080                	add	s0,sp,64
    int fd;
    uint64 ubuf;
    int count;
    
    // 提取参数
    if(argint(0, &fd) < 0 || argaddr(1, &ubuf) < 0 || argint(2, &count) < 0)
    80004f86:	fdc40793          	add	a5,s0,-36
    80004f8a:	85be                	mv	a1,a5
    80004f8c:	4501                	li	a0,0
    80004f8e:	00000097          	auipc	ra,0x0
    80004f92:	9a6080e7          	jalr	-1626(ra) # 80004934 <argint>
    80004f96:	87aa                	mv	a5,a0
    80004f98:	0207c863          	bltz	a5,80004fc8 <sys_read+0x4a>
    80004f9c:	fd040793          	add	a5,s0,-48
    80004fa0:	85be                	mv	a1,a5
    80004fa2:	4505                	li	a0,1
    80004fa4:	00000097          	auipc	ra,0x0
    80004fa8:	a92080e7          	jalr	-1390(ra) # 80004a36 <argaddr>
    80004fac:	87aa                	mv	a5,a0
    80004fae:	0007cd63          	bltz	a5,80004fc8 <sys_read+0x4a>
    80004fb2:	fcc40793          	add	a5,s0,-52
    80004fb6:	85be                	mv	a1,a5
    80004fb8:	4509                	li	a0,2
    80004fba:	00000097          	auipc	ra,0x0
    80004fbe:	97a080e7          	jalr	-1670(ra) # 80004934 <argint>
    80004fc2:	87aa                	mv	a5,a0
    80004fc4:	0007d463          	bgez	a5,80004fcc <sys_read+0x4e>
        return -1;
    80004fc8:	57fd                	li	a5,-1
    80004fca:	a859                	j	80005060 <sys_read+0xe2>
    
    // 简化版：只支持 fd=0 (stdin)
    if(fd != 0) {
    80004fcc:	fdc42783          	lw	a5,-36(s0)
    80004fd0:	cb99                	beqz	a5,80004fe6 <sys_read+0x68>
        printf("sys_read: only stdin (fd=0) supported\n");
    80004fd2:	00003517          	auipc	a0,0x3
    80004fd6:	2be50513          	add	a0,a0,702 # 80008290 <userret+0x222c>
    80004fda:	ffffc097          	auipc	ra,0xffffc
    80004fde:	c0c080e7          	jalr	-1012(ra) # 80000be6 <printf>
        return -1;
    80004fe2:	57fd                	li	a5,-1
    80004fe4:	a8b5                	j	80005060 <sys_read+0xe2>
    }

    if(count <= 0)
    80004fe6:	fcc42783          	lw	a5,-52(s0)
    80004fea:	00f04463          	bgtz	a5,80004ff2 <sys_read+0x74>
        return 0;
    80004fee:	4781                	li	a5,0
    80004ff0:	a885                	j	80005060 <sys_read+0xe2>
    
    // 读取一个字符
    int c = uartgetc();
    80004ff2:	ffffc097          	auipc	ra,0xffffc
    80004ff6:	9de080e7          	jalr	-1570(ra) # 800009d0 <uartgetc>
    80004ffa:	87aa                	mv	a5,a0
    80004ffc:	fef42623          	sw	a5,-20(s0)
    if(c < 0)
    80005000:	fec42783          	lw	a5,-20(s0)
    80005004:	2781                	sext.w	a5,a5
    80005006:	0007d463          	bgez	a5,8000500e <sys_read+0x90>
        return 0;  // 没有输入
    8000500a:	4781                	li	a5,0
    8000500c:	a891                	j	80005060 <sys_read+0xe2>
    
    char ch = (char)c;
    8000500e:	fec42783          	lw	a5,-20(s0)
    80005012:	0ff7f793          	zext.b	a5,a5
    80005016:	fcf405a3          	sb	a5,-53(s0)

    struct proc *p = myproc();
    8000501a:	fffff097          	auipc	ra,0xfffff
    8000501e:	9be080e7          	jalr	-1602(ra) # 800039d8 <myproc>
    80005022:	fea43023          	sd	a0,-32(s0)
    if(p == 0 || p->pagetable == 0)
    80005026:	fe043783          	ld	a5,-32(s0)
    8000502a:	c789                	beqz	a5,80005034 <sys_read+0xb6>
    8000502c:	fe043783          	ld	a5,-32(s0)
    80005030:	67fc                	ld	a5,200(a5)
    80005032:	e399                	bnez	a5,80005038 <sys_read+0xba>
        return -1;
    80005034:	57fd                	li	a5,-1
    80005036:	a02d                	j	80005060 <sys_read+0xe2>

    // 把 1 个字节从内核写回用户缓冲区
    if(copyout(p->pagetable, ubuf, &ch, 1) < 0)
    80005038:	fe043783          	ld	a5,-32(s0)
    8000503c:	67fc                	ld	a5,200(a5)
    8000503e:	fd043703          	ld	a4,-48(s0)
    80005042:	fcb40613          	add	a2,s0,-53
    80005046:	4685                	li	a3,1
    80005048:	85ba                	mv	a1,a4
    8000504a:	853e                	mv	a0,a5
    8000504c:	ffffd097          	auipc	ra,0xffffd
    80005050:	dec080e7          	jalr	-532(ra) # 80001e38 <copyout>
    80005054:	87aa                	mv	a5,a0
    80005056:	0007d463          	bgez	a5,8000505e <sys_read+0xe0>
        return -1;
    8000505a:	57fd                	li	a5,-1
    8000505c:	a011                	j	80005060 <sys_read+0xe2>

    return 1;
    8000505e:	4785                	li	a5,1
}
    80005060:	853e                	mv	a0,a5
    80005062:	70e2                	ld	ra,56(sp)
    80005064:	7442                	ld	s0,48(sp)
    80005066:	6121                	add	sp,sp,64
    80005068:	8082                	ret

000000008000506a <sys_sbrk>:

// ==================== sys_sbrk ====================
int sys_sbrk(void)
{
    8000506a:	1101                	add	sp,sp,-32
    8000506c:	ec06                	sd	ra,24(sp)
    8000506e:	e822                	sd	s0,16(sp)
    80005070:	1000                	add	s0,sp,32
    int n;
    if(argint(0, &n) < 0)
    80005072:	fec40793          	add	a5,s0,-20
    80005076:	85be                	mv	a1,a5
    80005078:	4501                	li	a0,0
    8000507a:	00000097          	auipc	ra,0x0
    8000507e:	8ba080e7          	jalr	-1862(ra) # 80004934 <argint>
    80005082:	87aa                	mv	a5,a0
    80005084:	0007d463          	bgez	a5,8000508c <sys_sbrk+0x22>
        return -1;
    80005088:	57fd                	li	a5,-1
    8000508a:	a811                	j	8000509e <sys_sbrk+0x34>
    
    printf("sys_sbrk: not implemented yet\n");
    8000508c:	00003517          	auipc	a0,0x3
    80005090:	22c50513          	add	a0,a0,556 # 800082b8 <userret+0x2254>
    80005094:	ffffc097          	auipc	ra,0xffffc
    80005098:	b52080e7          	jalr	-1198(ra) # 80000be6 <printf>
    return -1;
    8000509c:	57fd                	li	a5,-1
}
    8000509e:	853e                	mv	a0,a5
    800050a0:	60e2                	ld	ra,24(sp)
    800050a2:	6442                	ld	s0,16(sp)
    800050a4:	6105                	add	sp,sp,32
    800050a6:	8082                	ret
	...

Disassembly of section trampsec:

0000000080006000 <trampoline>:

uservec:
    # 交换 sp 和 sscratch：
    #   sp      <- TRAPFRAME 虚拟地址
    #   sscratch<- 用户 sp
    csrrw sp, sscratch, sp
    80006000:	14011173          	csrrw	sp,sscratch,sp

    # 保存通用寄存器到 TRAPFRAME（和 struct trapframe 完全一致）
    sd ra, 0(sp)
    80006004:	e006                	sd	ra,0(sp)
    sd gp, 16(sp)
    80006006:	e80e                	sd	gp,16(sp)
    sd tp, 24(sp)
    80006008:	ec12                	sd	tp,24(sp)
    sd t0, 32(sp)
    8000600a:	f016                	sd	t0,32(sp)
    sd t1, 40(sp)
    8000600c:	f41a                	sd	t1,40(sp)
    sd t2, 48(sp)
    8000600e:	f81e                	sd	t2,48(sp)
    sd s0, 56(sp)
    80006010:	fc22                	sd	s0,56(sp)
    sd s1, 64(sp)
    80006012:	e0a6                	sd	s1,64(sp)
    sd a0, 72(sp)
    80006014:	e4aa                	sd	a0,72(sp)
    sd a1, 80(sp)
    80006016:	e8ae                	sd	a1,80(sp)
    sd a2, 88(sp)
    80006018:	ecb2                	sd	a2,88(sp)
    sd a3, 96(sp)
    8000601a:	f0b6                	sd	a3,96(sp)
    sd a4, 104(sp)
    8000601c:	f4ba                	sd	a4,104(sp)
    sd a5, 112(sp)
    8000601e:	f8be                	sd	a5,112(sp)
    sd a6, 120(sp)
    80006020:	fcc2                	sd	a6,120(sp)
    sd a7, 128(sp)
    80006022:	e146                	sd	a7,128(sp)
    sd s2, 136(sp)
    80006024:	e54a                	sd	s2,136(sp)
    sd s3, 144(sp)
    80006026:	e94e                	sd	s3,144(sp)
    sd s4, 152(sp)
    80006028:	ed52                	sd	s4,152(sp)
    sd s5, 160(sp)
    8000602a:	f156                	sd	s5,160(sp)
    sd s6, 168(sp)
    8000602c:	f55a                	sd	s6,168(sp)
    sd s7, 176(sp)
    8000602e:	f95e                	sd	s7,176(sp)
    sd s8, 184(sp)
    80006030:	fd62                	sd	s8,184(sp)
    sd s9, 192(sp)
    80006032:	e1e6                	sd	s9,192(sp)
    sd s10, 200(sp)
    80006034:	e5ea                	sd	s10,200(sp)
    sd s11, 208(sp)
    80006036:	e9ee                	sd	s11,208(sp)
    sd t3, 216(sp)
    80006038:	edf2                	sd	t3,216(sp)
    sd t4, 224(sp)
    8000603a:	f1f6                	sd	t4,224(sp)
    sd t5, 232(sp)
    8000603c:	f5fa                	sd	t5,232(sp)
    sd t6, 240(sp)
    8000603e:	f9fe                	sd	t6,240(sp)

    # 保存「原用户 sp」到 trapframe.sp（偏移 8）
    csrr t0, sscratch
    80006040:	140022f3          	csrr	t0,sscratch
    sd t0, 8(sp)
    80006044:	e416                	sd	t0,8(sp)

    # 保存 sepc / sstatus 到 trapframe
    csrr t1, sepc
    80006046:	14102373          	csrr	t1,sepc
    sd t1, 248(sp)
    8000604a:	fd9a                	sd	t1,248(sp)
    csrr t2, sstatus
    8000604c:	100023f3          	csrr	t2,sstatus
    sd t2, 256(sp)
    80006050:	e21e                	sd	t2,256(sp)

    # =====⭐ 关键：在切 satp 之前，从 TRAPFRAME 读出内核信息 =====
    # 264: kernel_satp
    # 272: kernel_sp
    # 280: kernel_trap
    ld t0, 264(sp)      # t0 = kernel_satp
    80006052:	62b2                	ld	t0,264(sp)
    ld t1, 272(sp)      # t1 = kernel_sp
    80006054:	6352                	ld	t1,272(sp)
    ld t2, 280(sp)      # t2 = kernel_trap
    80006056:	63f2                	ld	t2,280(sp)

    # 切换到内核页表
    csrw satp, t0
    80006058:	18029073          	csrw	satp,t0
    sfence.vma zero, zero
    8000605c:	12000073          	sfence.vma

    # 切换到内核栈，跳到 usertrap()
    mv sp, t1
    80006060:	811a                	mv	sp,t1
    jr t2
    80006062:	8382                	jr	t2

0000000080006064 <userret>:
#   a0 = TRAPFRAME 虚拟地址
#   a1 = 用户页表对应的 satp

userret:
    # ⭐ 调试：在还使用内核页表时输出标记（此时 UART 已映射）
    li t0, 0x10000000
    80006064:	100002b7          	lui	t0,0x10000
    li t1, 'U'
    80006068:	05500313          	li	t1,85
    sb t1, 0(t0)
    8000606c:	00628023          	sb	t1,0(t0) # 10000000 <_entry-0x70000000>
    li t1, 'R'
    80006070:	05200313          	li	t1,82
    sb t1, 0(t0)
    80006074:	00628023          	sb	t1,0(t0)
    li t1, 'E'
    80006078:	04500313          	li	t1,69
    sb t1, 0(t0)
    8000607c:	00628023          	sb	t1,0(t0)
    li t1, 'T'
    80006080:	05400313          	li	t1,84
    sb t1, 0(t0)
    80006084:	00628023          	sb	t1,0(t0)
    li t1, '\n'
    80006088:	4329                	li	t1,10
    sb t1, 0(t0)
    8000608a:	00628023          	sb	t1,0(t0)

    # 切换到用户页表
    csrw satp, a1
    8000608e:	18059073          	csrw	satp,a1
    sfence.vma zero, zero
    80006092:	12000073          	sfence.vma

    # ⭐ 切页表后不要再访问 UART（用户页表未映射 UART）

    # 设置 sscratch = TRAPFRAME 虚拟地址
    csrw sscratch, a0
    80006096:	14051073          	csrw	sscratch,a0

    # 恢复 sepc 和 sstatus（从 trapframe）
    ld t0, 248(a0)
    8000609a:	0f853283          	ld	t0,248(a0)
    csrw sepc, t0
    8000609e:	14129073          	csrw	sepc,t0

    ld t0, 256(a0)
    800060a2:	10053283          	ld	t0,256(a0)
    csrw sstatus, t0
    800060a6:	10029073          	csrw	sstatus,t0

    # 恢复通用寄存器（除了 a0 最后再恢复）
    ld ra, 0(a0)
    800060aa:	00053083          	ld	ra,0(a0)
    ld sp, 8(a0)
    800060ae:	00853103          	ld	sp,8(a0)
    ld gp, 16(a0)
    800060b2:	01053183          	ld	gp,16(a0)
    ld tp, 24(a0)
    800060b6:	01853203          	ld	tp,24(a0)
    ld t0, 32(a0)
    800060ba:	02053283          	ld	t0,32(a0)
    ld t1, 40(a0)
    800060be:	02853303          	ld	t1,40(a0)
    ld t2, 48(a0)
    800060c2:	03053383          	ld	t2,48(a0)
    ld s0, 56(a0)
    800060c6:	7d00                	ld	s0,56(a0)
    ld s1, 64(a0)
    800060c8:	6124                	ld	s1,64(a0)
    ld a1, 80(a0)
    800060ca:	692c                	ld	a1,80(a0)
    ld a2, 88(a0)
    800060cc:	6d30                	ld	a2,88(a0)
    ld a3, 96(a0)
    800060ce:	7134                	ld	a3,96(a0)
    ld a4, 104(a0)
    800060d0:	7538                	ld	a4,104(a0)
    ld a5, 112(a0)
    800060d2:	793c                	ld	a5,112(a0)
    ld a6, 120(a0)
    800060d4:	07853803          	ld	a6,120(a0)
    ld a7, 128(a0)
    800060d8:	08053883          	ld	a7,128(a0)
    ld s2, 136(a0)
    800060dc:	08853903          	ld	s2,136(a0)
    ld s3, 144(a0)
    800060e0:	09053983          	ld	s3,144(a0)
    ld s4, 152(a0)
    800060e4:	09853a03          	ld	s4,152(a0)
    ld s5, 160(a0)
    800060e8:	0a053a83          	ld	s5,160(a0)
    ld s6, 168(a0)
    800060ec:	0a853b03          	ld	s6,168(a0)
    ld s7, 176(a0)
    800060f0:	0b053b83          	ld	s7,176(a0)
    ld s8, 184(a0)
    800060f4:	0b853c03          	ld	s8,184(a0)
    ld s9, 192(a0)
    800060f8:	0c053c83          	ld	s9,192(a0)
    ld s10, 200(a0)
    800060fc:	0c853d03          	ld	s10,200(a0)
    ld s11, 208(a0)
    80006100:	0d053d83          	ld	s11,208(a0)
    ld t3, 216(a0)
    80006104:	0d853e03          	ld	t3,216(a0)
    ld t4, 224(a0)
    80006108:	0e053e83          	ld	t4,224(a0)
    ld t5, 232(a0)
    8000610c:	0e853f03          	ld	t5,232(a0)
    ld t6, 240(a0)
    80006110:	0f053f83          	ld	t6,240(a0)

    # 最后恢复 a0（系统调用返回值等）
    ld a0, 72(a0)
    80006114:	6528                	ld	a0,72(a0)

    # sret 回到用户态，PC=sepc，模式=U
    sret
    80006116:	10200073          	sret
    8000611a:	0001                	nop
    8000611c:	00000013          	nop
