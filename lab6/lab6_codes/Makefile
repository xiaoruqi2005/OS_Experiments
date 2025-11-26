# RISC-V OS Makefile - Lab 6 Version (Fixed clean rule)

# 工具链配置
CROSS_COMPILE = riscv64-unknown-elf-
CC = $(CROSS_COMPILE)gcc
AS = $(CROSS_COMPILE)as
LD = $(CROSS_COMPILE)ld
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump

# 编译选项
CFLAGS = -Wall -Werror -O0 -fno-omit-frame-pointer -ggdb
CFLAGS += -mcmodel=medany -ffreestanding -fno-common -nostdlib
CFLAGS += -mno-relax -fno-stack-protector -fno-pie -no-pie
CFLAGS += -Iinclude

# 链接选项
LDFLAGS = -z max-page-size=4096

# 内核目标文件
OBJS = \
	kernel/entry.o \
	kernel/start.o \
	kernel/main.o \
	kernel/uart.o \
	kernel/console.o \
	kernel/printf.o \
	kernel/screen.o \
	kernel/kalloc.o \
	kernel/vm.o \
	kernel/mm_test.o \
	kernel/trap.o \
	kernel/kernelvec.o \
	kernel/trampoline.o \
	kernel/timervec.o \
	kernel/timer.o \
	kernel/proc.o \
	kernel/swtch.o \
	kernel/syscall.o \
	kernel/sysproc.o \
	kernel/initcode.o

# 默认目标
all: kernel.img

# ==================== 用户代码编译 ====================

user:
	mkdir -p user

user/initcode.o: user/initcode.S | user
	$(CC) $(CFLAGS) -c user/initcode.S -o user/initcode.o

user/initcode.out: user/initcode.o
	$(LD) -N -e _start -Ttext 0 -o user/initcode.out user/initcode.o

user/initcode: user/initcode.out
	$(OBJCOPY) -S -O binary user/initcode.out user/initcode

kernel/initcode.c: user/initcode kernel/initcode_gen.py
	python3 kernel/initcode_gen.py user/initcode kernel/initcode.c

kernel/initcode.o: kernel/initcode.c
	$(CC) $(CFLAGS) -c kernel/initcode.c -o kernel/initcode.o

# ==================== 内核编译 ====================

kernel.img: kernel/kernel.elf
	$(OBJCOPY) kernel/kernel.elf -S -O binary kernel.img

kernel/kernel.elf: $(OBJS) kernel/kernel.ld
	$(LD) $(LDFLAGS) -T kernel/kernel.ld -o kernel/kernel.elf $(OBJS)
	$(OBJDUMP) -S kernel/kernel.elf > kernel.asm
	$(OBJDUMP) -t kernel/kernel.elf | sed '1,/SYMBOL TABLE/d; s/ .* / /; /^$$/d' > kernel.sym

kernel/%.o: kernel/%.c
	$(CC) $(CFLAGS) -c $< -o $@

kernel/%.o: kernel/%.S
	$(CC) $(CFLAGS) -c $< -o $@

# ==================== QEMU 运行 ====================

QEMUOPTS = -machine virt -bios none -kernel kernel/kernel.elf -m 128M -smp 1 -nographic

qemu: kernel/kernel.elf
	qemu-system-riscv64 $(QEMUOPTS)

qemu-gdb: kernel/kernel.elf
	qemu-system-riscv64 $(QEMUOPTS) -S -gdb tcp::1234

# ==================== 清理 ====================
# ⭐ 修复：只删除自动生成的文件，不删除源代码

clean:
	rm -f kernel/*.o kernel/*.elf kernel/initcode.c kernel.img kernel.asm kernel.sym
	rm -f user/*.o user/initcode.out user/initcode

# ==================== 危险操作 ====================
# 如果真的要删除所有东西（包括源代码），使用这个
# 谨慎使用！

distclean: clean
	@echo "WARNING: This will delete ALL generated AND source files!"
	@echo "Press Ctrl+C to cancel, or wait 5 seconds..."
	@sleep 5
	rm -rf kernel/*.c user/*.S

# ==================== 工具检查 ====================

check-tools:
	@echo "Checking RISC-V toolchain..."
	@which $(CC) || (echo "Error: $(CC) not found" && exit 1)
	@which qemu-system-riscv64 || (echo "Error: qemu-system-riscv64 not found" && exit 1)
	@which python3 || (echo "Error: python3 not found" && exit 1)
	@echo "All tools found!"

info:
	@echo "=== Lab 6: System Calls ==="
	@echo "Run: make qemu"

.PHONY: all clean distclean qemu qemu-gdb check-tools info user