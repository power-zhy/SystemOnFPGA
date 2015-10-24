#ifndef __RANDOM_H__
#define __RANDOM_H__

void rand_init(uint32* ram_pos, uint32 ram_size, uint32 time);
uint32 random(uint32 begin, uint32 end);  // [begin, end)

#endif
