#define DATA_ADDR		0xFF100000
#define DATA_RANGE		0x00100000
#define VRAM_ADDR		0x00100000
#define VRAM_RANGE		0x00100000
#define VGA_ADDR		0xFFFF0100
#define BOARD_ADDR		0xFFFF0200
#define KEYBOARD_ADDR	0xFFFF0300
#define SPI_ADDR		0xFFFF0500
#define UART_ADDR		0xFFFF0600

#include "types.h"
#include "random.h"
#include "keyboard.h"
#include "2048_core.h"

#define BLOCK_WIDTH  80
#define BLOCK_HEIGHT 80
#define BLOCK_RANGE  BLOCK_WIDTH * BLOCK_HEIGHT


void bootup();
void exception();

uint32 screen_width = 0;
uint32 screen_height = 0;
uint32 screen_range = 0;
uint32 board_width = BLOCK_WIDTH * 4;
uint32 board_height = BLOCK_HEIGHT * 4;
uint32 blank_top = 0;
uint32 blank_left = 0;

uint32 ms_count = 0;

void int_init() {
	__asm__ ("mtc0 %0, $7": : "r"(20));
	uint32 mask = 1 << 31;
	mask |= 1 << 0;  // timer
	mask |= 1 << 3;  // keyboard
	__asm__ ("mtc0 %0, $4": : "r"(mask));
}

void int_timer() {
	ms_count += 20;
}

void int_keyboard() {
	volatile uint32* keyboard = (uint32*)KEYBOARD_ADDR;
	if (keyboard[0] & (1<<2))
		scancode_recv(keyboard[3], ms_count);
}

void int_dispatch() {
	uint32 ints;
	__asm__ ("mfc0 %0, $5": "=r"(ints));
	if (ints & (1<<0)) {  // timer
		__asm__ ("mtc0 %0, $5": : "r"(1<<0));
		int_timer();
	}
	if (ints & (1<<3)) {  // keyboard
		__asm__ ("mtc0 %0, $5": : "r"(1<<3));
		int_keyboard();
	}
}

void disp_num(uint32 number) {
	volatile uint32* config = (uint32*)BOARD_ADDR;
	config[6] = number;
	config[7] = 0x0000FF00;
}

void init_vga(uint32 mode, uint32 addr) {
	volatile uint32* config = (uint32*)VGA_ADDR;
	if (mode & 0x7FFFFFF8)
		mode = 0;
	mode &= 0x7;
	switch (mode) {
		case 1:
		case 2:
		case 3:
			screen_width = 640;
			screen_height = 480;
			screen_range = 640 * 480;
			break;
		case 4:
		case 5:
		case 6:
			screen_width = 800;
			screen_height = 600;
			screen_range = 800 * 600;
			break;
		default:
			screen_width = 0;
			screen_height = 0;
			screen_range = 0;
			break;
	}
	mode |= (1 << 31);
	blank_left = (screen_width < board_width) ? 0 : (screen_width - board_width) >> 1;
	blank_top = (screen_height < board_height) ? 0 : (screen_height - board_height) >> 1;
	mem_set((uint32*)addr, 0, screen_range>>2);
	config[1] = addr;
	config[0] = mode;  // graphic mode
	config[2] = 0;
	config[3] = 0;
}


void draw_board(bool all) {
	static uint8 board_status[4][4];
	uint8 x, y, dx, dy;
	for (y=0; y<4; y++) {
		for (x=0; x<4; x++) {
			uint8 status = get_block(x, y);
			if (all || board_status[y][x] != status) {
				uint32* vram = (uint32*)(VRAM_ADDR + umul(blank_top + umul(BLOCK_HEIGHT, y), screen_width) + blank_left + umul(BLOCK_WIDTH, x));
				uint32* asset = (uint32*)(DATA_ADDR + umul(BLOCK_RANGE, status));
				for (dy=0; dy<BLOCK_HEIGHT; dy++) {
					for (dx=0; dx<(BLOCK_WIDTH>>2); dx++) {
						*vram = *asset;
						vram++;
						asset++;
					}
					vram += (screen_width - BLOCK_WIDTH) >> 2;
				}
				board_status[y][x] = status;
			}
		}
	}
}

void draw_border(uint8 color) {
	uint32 data = (color << 24) | (color << 16) | (color << 8) | color;
	uint32 lx = blank_left - 8;
	uint32 rx = blank_left + board_width + 8;
	uint32 ly = blank_top - 8;
	uint32 ry = blank_top + board_height + 8;
	int y;
	uint8* vram = (uint8*)(VRAM_ADDR + umul(ly - 8, screen_width) + lx - 8);
	for (y=0; y<16; y++) {
		mem_set((uint32*)vram, data, (rx - lx + 16) >> 2);
		vram += screen_width;
	}
	for (y=0; y<ry-ly-16; y++) {
		mem_set((uint32*)vram, data, 16 >> 2);
		mem_set((uint32*)(vram + board_width + 16), data, 16 >> 2);
		vram += screen_width;
	}
	for (y=0; y<16; y++) {
		mem_set((uint32*)vram, data, (rx - lx + 16) >> 2);
		vram += screen_width;
	}
}

void game_loop() {
	while (1) {
		game_init(ms_count);
		draw_board(true);
		draw_border(0xFF);
		disp_num(get_step_count());
		uint8 result = 0;
		while (1) {
			keycode key = get_key(WM_KEYUP, true);
			uint8 step = 0;
			switch (key.key_code) {
				case VK_W:
				case VK_UP:
					step = STEP_UP;
					break;
				case VK_S:
				case VK_DOWN:
					step = STEP_DOWN;
					break;
				case VK_A:
				case VK_LEFT:
					step = STEP_LEFT;
					break;
				case VK_D:
				case VK_RIGHT:
					step = STEP_RIGHT;
					break;
				case VK_0:
				case VK_1:
				case VK_2:
				case VK_3:
				case VK_4:
				case VK_5:
				case VK_6:
					if (key.ctrl_down) {
						init_vga(key.key_code - VK_0, VRAM_ADDR);
						draw_board(true);
						if (result == GAME_SUCCESS)
							draw_border(0x7C);
						else if (result == GAME_FAILED)
							draw_border(0xEC);
						else
							draw_border(0xFF);
					}
					break;
			}
			if (result) {
				if (key.key_code == VK_RETURN)
					break;
			}
			else if (step) {
				result = game_step(step);
				draw_board(false);
				if (result == GAME_SUCCESS)
					draw_border(0x7C);
				else if (result == GAME_FAILED)
					draw_border(0xEC);
				disp_num(get_step_count());
			}
		}
	}
}

void bootup() {
	disp_num(0);
	init_vga(1, VRAM_ADDR);
	int_init();
	rand_init((uint32*)0x00200000, 0x00200000, 0);  // use uninitialized ram for random source
	game_loop();
}

void exception(){
	int_dispatch();
}
