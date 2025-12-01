# RISC-V OS Makefile (Lab 7 Version)

# 为了方便路径引用，定义简写
K = kernel
U = user

# 工具链配置
CROSS_COMPILE = riscv64-unknown-elf-
CC = $(CROSS_COMPILE)gcc
AS = $(CROSS_COMPILE)as
LD = $(CROSS_COMPILE)ld
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump

# 编译选项
CFLAGS = -Wall -Werror -O -fno-omit-frame-pointer -ggdb
CFLAGS += -mcmodel=medany -ffreestanding -fno-common -nostdlib
CFLAGS += -mno-relax -fno-stack-protector -fno-pie -no-pie
CFLAGS += -Iinclude

# 链接选项
LDFLAGS = -z max-page-size=4096

# ==================== (修改) 内核目标文件 ====================
# 在原有的基础上，增加了文件系统相关的模块
OBJS = \
	$K/entry.o \
	$K/start.o \
	$K/main.o \
	$K/uart.o \
	$K/console.o \
	$K/printf.o \
	$K/screen.o \
	$K/kalloc.o \
	$K/vm.o \
	$K/trap.o \
	$K/kernelvec.o \
	$K/trampoline.o \
	$K/timervec.o \
	$K/timer.o \
	$K/proc.o \
	$K/swtch.o \
	$K/syscall.o \
	$K/sysproc.o \
	$K/initcode.o \
	$K/string.o \
	$K/bio.o \
	$K/fs.o \
	$K/log.o \
	$K/file.o \
	$K/sysfile.o \
	$K/pipe.o \
	$K/plic.o \
	$K/virtio_disk.o \
	$K/sleeplock.o

# 默认目标
all: kernel.img fs.img

# ==================== (新增) 用户库与程序编译 ====================

# 用户态基础库 (所有用户程序都需要链接这些)
ULIB = $U/ulib.o $U/usys.o $U/printf.o $U/umalloc.o

# 生成系统调用汇编存根 (usys.S)
$U/usys.S : $U/usys.pl
	perl $U/usys.pl > $U/usys.S

# 编译 usys.S
$U/usys.o : $U/usys.S
	$(CC) $(CFLAGS) -c -o $U/usys.o $U/usys.S

# 将会被放入文件系统镜像的用户程序列表
# 注意：_前缀是 xv6 的习惯，表示这是编译好的二进制文件
UPROGS=\
	$U/_init\
	$U/_sh\
	$U/_cat\
	$U/_echo\
	$U/_grep\
	$U/_ls\
	$U/_mkdir\
	$U/_rm\
	$U/_wc\
	$U/_fs_test\

# 通用规则：编译用户程序 (链接 ULIB)
# 例如：编译 _fs_test 需要 fs_test.o 和 ULIB
_%: %.o $(ULIB)
	$(LD) $(LDFLAGS) -N -e main -Ttext 0 -o $@ $^
	$(OBJCOPY) -S -O binary $@ $@

# 单独编译 .o 文件
$U/%.o: $U/%.c
	$(CC) $(CFLAGS) -c -o $@ $<

# ==================== initcode (引导程序) ====================
# initcode 是嵌入内核的一小段代码，用于启动第一个进程(/init)
# 这部分逻辑保持不变，用于生成 kernel/initcode.o

$U/initcode.o: $U/initcode.S
	$(CC) $(CFLAGS) -c $U/initcode.S -o $U/initcode.o

$U/initcode.out: $U/initcode.o
	$(LD) $(LDFLAGS) -N -e start -Ttext 0 -o $U/initcode.out $U/initcode.o

$U/initcode: $U/initcode.out
	$(OBJCOPY) -S -O binary $U/initcode.out $U/initcode

$K/initcode.c: $U/initcode $K/initcode_gen.py
	python3 $K/initcode_gen.py $U/initcode $K/initcode.c

$K/initcode.o: $K/initcode.c
	$(CC) $(CFLAGS) -c $K/initcode.c -o $K/initcode.o

# ==================== (新增) 文件系统镜像制作 ====================

# 1. 编译 mkfs 工具 (在宿主机上运行，所以用 gcc 而不是 riscv64-gcc)
mkfs/mkfs: mkfs/mkfs.c
	gcc -Werror -Wall -Iinclude -o mkfs/mkfs mkfs/mkfs.c

# 2. 制作 fs.img
# 将 README 和 UPROGS 中的程序打包进镜像
fs.img: mkfs/mkfs README $(UPROGS)
	mkfs/mkfs fs.img README $(UPROGS)

# ==================== 内核编译 ====================

kernel.img: $K/kernel.elf
	$(OBJCOPY) $K/kernel.elf -S -O binary kernel.img

$K/kernel.elf: $(OBJS) $K/kernel.ld
	$(LD) $(LDFLAGS) -T $K/kernel.ld -o $K/kernel.elf $(OBJS)
	$(OBJDUMP) -S $K/kernel.elf > kernel.asm
	$(OBJDUMP) -t $K/kernel.elf | sed '1,/SYMBOL TABLE/d; s/ .* / /; /^$$/d' > kernel.sym

$K/%.o: $K/%.c
	$(CC) $(CFLAGS) -c $< -o $@

$K/%.o: $K/%.S
	$(CC) $(CFLAGS) -c $< -o $@

# ==================== (修改) QEMU 运行 ====================

# 增加了挂载磁盘的参数 (-drive 和 -device)
QEMUOPTS = -machine virt -bios none -kernel $K/kernel.elf -m 128M -smp 1 -nographic
QEMUOPTS += -drive file=fs.img,if=none,format=raw,id=x0
QEMUOPTS += -device virtio-blk-device,drive=x0,bus=virtio-mmio-bus.0

qemu: $K/kernel.elf fs.img
	qemu-system-riscv64 $(QEMUOPTS)

qemu-gdb: $K/kernel.elf fs.img
	qemu-system-riscv64 $(QEMUOPTS) -S -gdb tcp::1234

# ==================== 清理 ====================

clean:
	rm -f $K/*.o $K/*.elf $K/initcode.c kernel.img kernel.asm kernel.sym
	rm -f $U/*.o $U/*.out $U/usys.S $U/_* rm -f mkfs/mkfs fs.img

# ==================== 工具检查 ====================

check-tools:
	@echo "Checking RISC-V toolchain..."
	@which $(CC) || (echo "Error: $(CC) not found" && exit 1)
	@which qemu-system-riscv64 || (echo "Error: qemu-system-riscv64 not found" && exit 1)
	@which python3 || (echo "Error: python3 not found" && exit 1)
	@echo "All tools found!"

.PHONY: all clean qemu qemu-gdb check-tools
