#ifndef __2048_H__
#define __2048_H__

#define STEP_UP    1
#define STEP_DOWN  2
#define STEP_LEFT  3
#define STEP_RIGHT 4

#define GAME_CONTINUE 0
#define GAME_SUCCESS  1
#define GAME_FAILED   2

void game_init(uint32 time);
uint8 game_step(uint8 step);
uint8 get_block(uint8 x, uint8 y);
uint32 get_step_count();

#endif
