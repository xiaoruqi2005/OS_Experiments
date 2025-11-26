# RISC-V OS Makefile - Lab 5 Version (Process Management)

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

# 目标文件（Lab 5版本 - 添加了进程管理相关）
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
	kernel/timervec.o \
	kernel/timer.o \
	kernel/proc.o \
	kernel/swtch.o

# 默认目标
all: kernel.img

# 内核镜像
kernel.img: kernel/kernel.elf
	$(OBJCOPY) kernel/kernel.elf -S -O binary kernel.img

# 内核ELF文件
kernel/kernel.elf: $(OBJS) kernel/kernel.ld
	$(LD) $(LDFLAGS) -T kernel/kernel.ld -o kernel/kernel.elf $(OBJS)
	$(OBJDUMP) -S kernel/kernel.elf > kernel.asm
	$(OBJDUMP) -t kernel/kernel.elf | sed '1,/SYMBOL TABLE/d; s/ .* / /; /^$$/d' > kernel.sym

# 编译规则
kernel/%.o: kernel/%.c include/*.h
	$(CC) $(CFLAGS) -c $< -o $@

kernel/%.o: kernel/%.S
	$(CC) $(CFLAGS) -c $< -o $@

# QEMU运行
QEMUOPTS = -machine virt -bios none -kernel kernel/kernel.elf -m 128M -smp 1 -nographic

qemu: kernel/kernel.elf
	qemu-system-riscv64 $(QEMUOPTS)

# QEMU调试
qemu-gdb: kernel/kernel.elf
	qemu-system-riscv64 $(QEMUOPTS) -S -gdb tcp::1234

# 清理
clean:
	rm -f kernel/*.o kernel/*.elf kernel.img kernel.asm kernel.sym

# 检查工具链
check-tools:
	@echo "Checking RISC-V toolchain..."
	@which $(CC) || (echo "Error: $(CC) not found" && exit 1)
	@which qemu-system-riscv64 || (echo "Error: qemu-system-riscv64 not found" && exit 1)
	@echo "All tools found!"

# 显示进程管理信息（调试用）
info:
	@echo "=== Lab 5: Process Management ==="
	@echo "New files added:"
	@echo "  - kernel/proc.c   (Process management)"
	@echo "  - kernel/swtch.S  (Context switching)"
	@echo "  - include/proc.h  (Process structures)"
	@echo ""
	@echo "Modified files:"
	@echo "  - kernel/main.c   (Added thread tests)"
	@echo "  - kernel/timer.c  (Integrated scheduler)"
	@echo "  - include/defs.h  (Added proc interfaces)"

.PHONY: all clean qemu qemu-gdb check-tools info