#ifndef __TYPES_H__
#define __TYPES_H__

typedef unsigned char uint8;
typedef signed char int8;
typedef unsigned short uint16;
typedef signed short int16;
typedef unsigned int uint32;
typedef signed int int32;

typedef unsigned char bool;
#define false 0
#define true 1
#define null 0

int32 mul(int32 a, int32 b);
void mem_set(uint32* addr, uint32 value, uint32 count);
void mem_copy(uint32* src, uint32* dst, uint32 count);

#endif
