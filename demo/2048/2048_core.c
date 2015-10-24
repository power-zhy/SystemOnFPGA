#include "types.h"
#include "2048_core.h"
#include "random.h"

#define MAX_MERGE 11


uint8 board_status[4][4];
uint32 step_count;

bool block_gen() {
	int8 i, j;
	uint8 count = 0;
	for (i=0; i<4; i++) {
		for (j=0; j<4; j++) {
			if (!board_status[i][j])
				count++;
		}
	}
	if (count == 0)
		return false;
	uint8 selected = random(0, count);
	for (i=0; i<4; i++) {
		for (j=0; j<4; j++) {
			if (!board_status[i][j]) {
				if (!selected) {
					board_status[i][j] = 1;
					return true;
				}
				selected--;
			}
		}
	}
	return false;
}

void game_init(uint32 time) {
	mem_set((int32*)board_status, 0, sizeof(board_status) >> 2);
	rand_init(null, 0, time);
	step_count = 0;
	block_gen();
}

bool line_merge(uint8 line[4]) {
	bool success = false;
	int8 i;
	int8 size = 0;
	for (i=0; i<4; i++) {
		if (line[i])
			line[size++] = line[i];
	}
	for (i=size; i<4; i++) {
		line[i] = 0;
	}
	for (i=0; i<size-1; i++) {
		if (line[i] == line[i+1]) {
			line[i] ++;
			if (line[i] == MAX_MERGE)
				success = true;
			line[i+1] = 0;
			i++;
		}
	}
	size = 0;
	for (i=0; i<4; i++) {
		if (line[i])
			line[size++] = line[i];
	}
	for (i=size; i<4; i++) {
		line[i] = 0;
	}
	return success;
}

uint8 game_step(uint8 step) {
	bool success = false;
	uint8 line[4];
	int8 i, j;
	for (i=0; i<4; i++) {
		switch (step) {
			case STEP_UP:
				for (j=0; j<4; j++)
					line[j] = board_status[j][i];
				success |= line_merge(line);
				for (j=0; j<4; j++)
					board_status[j][i] = line[j];
				break;
			case STEP_DOWN:
				for (j=0; j<4; j++)
					line[j] = board_status[3-j][i];
				success |= line_merge(line);
				for (j=0; j<4; j++)
					board_status[3-j][i] = line[j];
				break;
			case STEP_LEFT:
				for (j=0; j<4; j++)
					line[j] = board_status[i][j];
				success |= line_merge(line);
				for (j=0; j<4; j++)
					board_status[i][j] = line[j];
				break;
			case STEP_RIGHT:
				for (j=0; j<4; j++)
					line[j] = board_status[i][3-j];
				success |= line_merge(line);
				for (j=0; j<4; j++)
					board_status[i][3-j] = line[j];
				break;
		}
	}
	step_count ++;
	bool valid = block_gen();
	if (success)
		return GAME_SUCCESS;
	if (!valid)
		return GAME_FAILED;
	return GAME_CONTINUE;
}

uint8 get_block(uint8 x, uint8 y) {
	return board_status[y][x];
}

uint32 get_step_count() {
	return step_count;
}
