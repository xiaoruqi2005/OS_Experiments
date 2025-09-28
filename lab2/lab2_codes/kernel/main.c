// main.c 
#include "printf.h"
#include "uart.h"

// 测试状态控制
static int test_phase = 0;

// 基础功能测试
void test_basic_functionality(void) {
    printf_color(COLOR_CYAN, "\n=== 基础功能测试 ===\n");
    printf("Testing integer: %d\n", 42);
    printf("Testing negative: %d\n", -123);
    printf("Testing zero: %d\n", 0);
    printf("Testing hex: 0x%x\n", 0xABC);
    printf("Testing string: %s\n", "Hello");
    printf("Testing char: %c\n", 'X');
    printf("Testing percent: %%\n");
}

// 边界值测试
void test_edge_cases(void) {
    printf_color(COLOR_CYAN, "\n=== 边界值测试 ===\n");
    printf("INT_MAX: %d\n", 2147483647);
    printf("INT_MIN: %d\n", -2147483648);
    printf("NULL string: %s\n", (char*)0);
    printf("Empty string: %s\n", "");
}

// 颜色输出测试
void test_color_output(void) {
    printf_color(COLOR_CYAN, "\n=== 颜色输出测试 ===\n");
    
    printf_color(COLOR_RED, "红色文本 \n");
    printf_color(COLOR_GREEN, "绿色文本 \n");
    printf_color(COLOR_YELLOW, "黄色文本 \n");
    printf_color(COLOR_BLUE, "蓝色文本 \n");
    printf_color(COLOR_MAGENTA, "紫色文本 \n");
    printf_color(COLOR_CYAN, "青色文本 \n");
    printf_color(COLOR_WHITE, "白色文本 \n");
}

// 光标定位测试
void test_cursor_positioning(void) {
    printf_color(COLOR_CYAN, "\n=== 光标定位测试 ===\n");
    
    
    // 定位到第7行
    goto_xy(0, 6);
    printf_color(COLOR_GREEN, "|这是第7行开头的位置\n");
    
    // 定位到第9行第10列
    goto_xy(10, 8);
    printf_color(COLOR_BLUE, "|这是第9行第10列（一个汉字算两列）\n");
    
}

// 清行测试
void test_clearline_functions(void) {
    printf_color(COLOR_CYAN, "\n=== 清行测试 ===\n");
    
    printf("这是将被清除的一行\n");
    printf("这是将被保留的一行\n\n");
    printf("按回车键清除...\n");
    
    wait_for_enter(0);
    
    // 清除"第a行"
    goto_xy(0, 4);
    clear_line();
    
    //回到原位
    goto_xy(0, 7);
    wait_for_enter(1);
}

// 运行下一个测试
void run_next_test(void) {
    clear_screen();
    printf_color(COLOR_YELLOW, "测试阶段: %d/5\n\n", test_phase + 1);
    
    switch (test_phase) {
        case 0:
            test_basic_functionality();
            break;
        case 1:
            test_edge_cases();
            break;
        case 2:
            test_color_output();
            break;
        case 3:
            test_cursor_positioning();
            break;
        case 4:
            test_clearline_functions();
            break;
        default:
            return;
    }
    
    test_phase++;
}

void main() {
    // 初始化
    clear_screen();
    printf_color(COLOR_GREEN, "====== OS lab2功能演示 ======\n\n");
    printf_color(COLOR_CYAN, "本演示包含5个测试阶段，按回车键逐步执行\n");
    // 等待开始
    wait_for_enter(1);
    
    // 执行所有测试阶段
    while (test_phase < 5) {
        run_next_test();
        if (test_phase < 5) {
            wait_for_enter(1);
        }
    }
    
    // 结束信息
    clear_screen();
    printf_color(COLOR_GREEN, "\n\n====== 所有测试完成 ======\n");
    printf("演示功能包括:\n");
    printf_color(COLOR_CYAN, "• 格式化输出 (printf)\n");
    printf_color(COLOR_CYAN, "• 清屏功能（每次测试展示的开始都进行一次清屏）\n");
    printf_color(COLOR_CYAN, "• 颜色文本输出\n");
    printf_color(COLOR_CYAN, "• 光标精确定位\n");
    printf_color(COLOR_CYAN, "• 清行功能\n\n");
    

    // 空闲循环
    while (1);
}
