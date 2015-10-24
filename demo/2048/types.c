#include "types.h"


int32 mul(int32 a, int32 b) {
	int32 result = 0;
	int8 i;
	for (i=0; i<32; i++) {
		if (b & 0x1)
			result += a;
		b >>= 1;
		a <<= 1;
	}
	return result;
}
uint32 umul(uint32 a, uint32 b) {
	uint32 result = 0;
	int8 i;
	for (i=0; i<32; i++) {
		if (b & 0x1)
			result += a;
		b >>= 1;
		a <<= 1;
	}
	return result;
}

uint32 udiv(uint32 a, uint32 b, uint32* rem) {
	uint32 result = 0;
	int8 i;
	for (i=31; i>=0; i--) {
		result <<= 1;
		if ((a >> i) >= b) {
			result += 1;
			a -= b << i;
		}
	}
	*rem = a;
	return result;
}

void mem_set(uint32* addr, uint32 value, uint32 count) {
	while (count != 0) {
		*addr = value;
		addr ++;
		count --;
	}
}

void mem_copy(uint32* src, uint32* dst, uint32 count) {
	while (count != 0) {
		*dst = *src;
		src ++;
		dst ++;
		count --;
	}
}
