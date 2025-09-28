# Lab1: RISC-V 最小内核启动

## 项目简介
基于RISC-V架构的最小操作系统内核，实现从硬件上电到交互式命令行环境的完整引导。

## 项目结构
```
lab1/
├── Makefile              # 构建配置
└── kernel/
    ├── kernel.ld         # 内存布局
    ├── entry.S           # 汇编启动
    ├── start.c           # 主逻辑
    ├── uart.c            # 串口驱动
    └── uart.h            # 驱动接口
```
## 功能特性
- ✅ RISC-V 64位内核启动
- ✅ 串口输入输出
- ✅ 交互式回显功能  
- ✅ 自动BSS段清零
- ✅ 最小内存管理

## 快速开始

### 环境要求
```bash
# Ubuntu/Debian 安装
sudo apt install gcc-riscv64-unknown-elf qemu-system-misc make
```

### 编译运行
```bash
make        # 编译内核
make run    # 在QEMU中运行
#make clean  #可选
```

### 退出方式
在QEMU窗口中按 `Ctrl+A`，然后按 `X` 退出模拟器。



## 验证效果
运行后将在终端看到启动信息，可输入文字测试回显功能。
![alt text](../lab1截图.png)
