#include "types.h"
#include "random.h"


uint32* pos = 0;
uint32 size = 1 << 20;
uint32* index = 0;

void rand_init(uint32* ram_pos, uint32 ram_size, uint32 time) {
	if (ram_size) {
		pos = ram_pos;
		size = ram_size >> 2;
	}
	time = time >> 4;
	udiv(time, size, &time);
	index = pos + time;
}

uint32 random(uint32 begin, uint32 end) {
	uint32 data = *index;
	index++;
	if (index - pos == size)
		index = pos;
	udiv(data, end-begin, &data);
	return begin + data;
}
