#!/usr/bin/env python3
# 将编译后的用户代码转换为C数组

import sys

def main():
    if len(sys.argv) != 3:
        print("Usage: initcode_gen.py input.bin output.c")
        sys.exit(1)
    
    with open(sys.argv[1], 'rb') as f:
        data = f.read()
    
    with open(sys.argv[2], 'w') as f:
        f.write('// Auto-generated - do not edit\n')
        f.write('#include "types.h"\n\n')
        f.write('// User init code\n')
        f.write('uint8 initcode[] = {\n')
        
        for i, byte in enumerate(data):
            if i % 12 == 0:
                f.write('  ')
            f.write(f'0x{byte:02x},')
            if i % 12 == 11:
                f.write('\n')
            else:
                f.write(' ')
        
        if len(data) % 12 != 0:
            f.write('\n')
        
        f.write('};\n')
        f.write(f'uint32 initcode_size = {len(data)};\n')

if __name__ == '__main__':
    main()