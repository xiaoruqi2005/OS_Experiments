# 极简内核编译配置
K=kernel

# 最小内核所需的目标文件
OBJS = \
  $K/entry.o \
  $K/start.o \
  $K/main.o \
  $K/uart.o \
  $K/printf.o \
  $K/string.o \
  $K/kalloc.o \
  $K/vm.o

# 工具链前缀（自动检测）
ifndef TOOLPREFIX
TOOLPREFIX := $(shell if riscv64-unknown-elf-objdump -i 2>&1 | grep 'elf64-big' >/dev/null 2>&1; \
	then echo 'riscv64-unknown-elf-'; \
	elif riscv64-linux-gnu-objdump -i 2>&1 | grep 'elf64-big' >/dev/null 2>&1; \
	then echo 'riscv64-linux-gnu-'; \
	else echo ""; fi)
endif

# QEMU命令
QEMU = qemu-system-riscv64

# 编译工具
CC = $(TOOLPREFIX)gcc
LD = $(TOOLPREFIX)ld
OBJCOPY = $(TOOLPREFIX)objcopy
OBJDUMP = $(TOOLPREFIX)objdump

# 编译选项
CFLAGS = -Wall -O -fno-omit-frame-pointer -ggdb
CFLAGS += -MD
CFLAGS += -mcmodel=medany
CFLAGS += -ffreestanding -fno-common -nostdlib
CFLAGS += -I.
CFLAGS += -fno-stack-protector

# 链接选项
LDFLAGS = -z max-page-size=4096

# 主要目标：生成内核可执行文件
$K/kernel: $(OBJS) $K/kernel.ld
	$(LD) $(LDFLAGS) -T $K/kernel.ld -o $K/kernel $(OBJS)
	$(OBJDUMP) -S $K/kernel > $K/kernel.asm
	$(OBJDUMP) -t $K/kernel | sed '1,/SYMBOL TABLE/d; s/ .* / /; /^$$/d' > $K/kernel.sym
	@echo "=== 内核编译完成 ==="

# 汇编文件编译规则
$K/%.o: $K/%.S
	$(CC) -g -c -o $@ $<

# C文件编译规则
$K/%.o: $K/%.c
	$(CC) $(CFLAGS) -c -o $@ $<

# QEMU运行配置
QEMUOPTS = -machine virt -bios none -kernel $K/kernel -m 128M -nographic

# 运行内核
run: $K/kernel
	$(QEMU) $(QEMUOPTS)

# 清理生成文件
clean:
	rm -f $K/*.o $K/*.d $K/*.asm $K/*.sym $K/kernel

# 包含依赖文件
-include $K/*.d

.PHONY: all run clean
