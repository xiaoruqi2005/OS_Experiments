#ifndef TYPES_H
#define TYPES_H

typedef unsigned int   uint;      // 32位无符号整数
typedef unsigned short ushort;    // 16位无符号整数  
typedef unsigned char  uchar;     // 8位无符号整数

typedef unsigned char  uint8;     // 明确的8位类型
typedef unsigned short uint16;    // 明确的16位类型
typedef unsigned int   uint32;    // 明确的32位类型
typedef unsigned long  uint64;    // 明确的64位类型（在64位系统上）

#ifndef NULL
#define NULL ((void*)0)
#endif

#endif
