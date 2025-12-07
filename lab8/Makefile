K=kernel
U=user

# 根据你实际拥有的文件列表生成的 OBJS
OBJS = \
  $K/entry.o \
  $K/console.o \
  $K/printf.o \
  $K/uart.o \
  $K/kalloc.o \
  $K/spinlock.o \
  $K/string.o \
  $K/main.o \
  $K/vm.o \
  $K/proc.o \
  $K/trap.o \
  $K/syscall.o \
  $K/sysproc.o \
  $K/bio.o \
  $K/fs.o \
  $K/log.o \
  $K/sleeplock.o \
  $K/file.o \
  $K/sysfile.o \
  $K/kernelvec.o \
  $K/swtch.o \
  $K/virtio_disk.o \
  $K/test.o

# 工具链前缀
TOOLPREFIX = riscv64-unknown-elf-

CC = $(TOOLPREFIX)gcc
AS = $(TOOLPREFIX)gas
LD = $(TOOLPREFIX)ld
OBJCOPY = $(TOOLPREFIX)objcopy
OBJDUMP = $(TOOLPREFIX)objdump

# 编译选项
CFLAGS = -Wall -Werror -O -fno-omit-frame-pointer -ggdb
CFLAGS += -MD
CFLAGS += -mcmodel=medany
CFLAGS += -ffreestanding -fno-common -nostdlib -mno-relax
CFLAGS += -I.
CFLAGS += $(shell $(CC) -fno-stack-protector -E -x c /dev/null >/dev/null 2>&1 && echo -fno-stack-protector)

# 链接选项
LDFLAGS = -z max-page-size=4096

# 构建内核镜像
$K/kernel: $(OBJS) $K/kernel.ld
	$(LD) $(LDFLAGS) -T $K/kernel.ld -o $K/kernel $(OBJS)
	$(OBJDUMP) -S $K/kernel > $K/kernel.asm
	$(OBJDUMP) -t $K/kernel | sed '1,/SYMBOL TABLE/d; s/ .* / /; /^$$/d' > $K/kernel.sym

# 清理构建产物
clean: 
	rm -f *.o *.d $K/*.o $K/*.d $K/kernel $K/kernel.asm $K/kernel.sym

# QEMU 运行配置
QEMU = qemu-system-riscv64

# QEMU 参数
QEMUOPTS = -machine virt -kernel $K/kernel -m 128M -smp 1 -nographic
QEMUOPTS += -drive file=fs.img,if=none,format=raw,id=x0
QEMUOPTS += -device virtio-blk-device,drive=x0,bus=virtio-mmio-bus.0

qemu: $K/kernel fs.img
	$(QEMU) $(QEMUOPTS)

qemu-gdb: $K/kernel fs.img
	$(QEMU) $(QEMUOPTS) -S -gdb tcp::1234
