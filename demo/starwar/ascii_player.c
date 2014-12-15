#define DATA_ADDR		0xFF100000
#define DATA_RANGE		0x00100000
#define VRAM_ADDR		0x00100000
#define VRAM_RANGE		0x00010000
#define VGA_ADDR		0xFFFF0100
#define BOARD_ADDR		0xFFFF0200
#define KEYBOARD_ADDR	0xFFFF0300
#define SPI_ADDR		0xFFFF0500
#define UART_ADDR		0xFFFF0600


typedef unsigned char uint8;
typedef signed char int8;
typedef unsigned short uint16;
typedef signed short int16;
typedef unsigned int uint32;
typedef signed int int32;


void bootup();
void exception();

uint32 frame_count = 0;
uint8* file_index = 0;
uint32 movie_width = 0;
uint32 movie_height = 0;

uint32 screen_width = 0;
uint32 screen_height = 0;
uint32 screen_range = 0;
uint32 blank_top = 0;
uint32 blank_left = 0;
uint32 row_num = 0;
uint32 col_num = 0;

uint32 ctrl_vga_mode = 0;
uint32 ctrl_play_back = 0;
uint32 ctrl_play_speed = 0;  // 6 for normal, 2 for fast, 7 for slow


/*volatile int32 mul(int32 value, int32 count) {
	int32 result = 0;
	if (count < 0) {
		value = -value;
		count = -count;
	}
	while (count) {
		result += value;
		count --;
	}
	return result;
}*/

#define T(o,a,b,i) (b&(1<<i)) && (o+=(a<<i))
int32 mul(int32 a, int32 b) {
	int32 result = 0;
	T(result, a, b, 0);
	T(result, a, b, 1);
	T(result, a, b, 2);
	T(result, a, b, 3);
	T(result, a, b, 4);
	T(result, a, b, 5);
	T(result, a, b, 6);
	T(result, a, b, 7);
	T(result, a, b, 8);
	T(result, a, b, 9);
	T(result, a, b, 10);
	T(result, a, b, 11);
	T(result, a, b, 12);
	T(result, a, b, 13);
	T(result, a, b, 14);
	T(result, a, b, 15);
	T(result, a, b, 16);
	T(result, a, b, 17);
	T(result, a, b, 18);
	T(result, a, b, 19);
	T(result, a, b, 20);
	T(result, a, b, 21);
	T(result, a, b, 22);
	T(result, a, b, 23);
	T(result, a, b, 24);
	T(result, a, b, 25);
	T(result, a, b, 26);
	T(result, a, b, 27);
	T(result, a, b, 28);
	T(result, a, b, 29);
	T(result, a, b, 30);
	T(result, a, b, 31);
	return result;
}

void mem_set(int32* addr, int32 value, uint32 count) {
	while (count != 0) {
		*addr = value;
		addr ++;
		count --;
	}
}

void mem_copy(int32* src, int32* dst, uint32 count) {
	while (count != 0) {
		*dst = *src;
		src ++;
		dst ++;
		count --;
	}
}

void update_position() {
	uint32 dw = screen_width - movie_width;
	uint32 dh = screen_height - movie_height;
	blank_left = (dw <= 0) ? 0 : (dw>>1);
	blank_top = (dh <= 0) ? 0 : (dh>>1);
}

void init_vga(uint32 mode, uint32 addr) {
	volatile uint32* config = (uint32*)VGA_ADDR;
	if (mode & 0xFFFFFFF8)
		mode = 0;
	mode &= 0x7;
	switch (mode) {
		case 1:
		case 2:
		case 3:
			screen_width = 80;
			screen_height = 30;
			screen_range = 80*30;
			break;
		case 4:
		case 5:
		case 6:
			screen_width = 100;
			screen_height = 38;
			screen_range = 100*38;
			break;
		case 7:
			screen_width = 128;
			screen_height = 48;
			screen_range = 128*48;
			break;
		default:
			screen_width = 0;
			screen_height = 0;
			screen_range = 0;
			break;
	}
	mem_set((int32*)addr, 0x07200720, screen_range>>1);
	config[1] = addr;
	config[0] = mode;  // text mode
	config[2] = 0;
	config[3] = 0;
}

void disp_num(uint16 number) {
	volatile uint32* config = (uint32*)BOARD_ADDR;
	uint32 data = number << 16;
	data += 0x0000F000;
	config[1] = data;
}

int32 find_frame(uint32 backward) {
	while (1) {
		if (*file_index == 0xFE)
			return 1;
		if (backward) {
			if (file_index == (uint8*)DATA_ADDR)
				return 0;
			file_index --;
		}
		else {
			if (file_index == (uint8*)(DATA_ADDR + DATA_RANGE - 1))
				return 0;
			file_index ++;
		}
	}
}

int32 render(uint16* frame_base) {
	uint16* row_base = frame_base + mul(screen_width, row_num);
	uint16* col_curr = row_base + col_num;
	while (1) {
		uint8 data = *file_index;
		if (data < 0x80) {  // normal character
			if (col_num < screen_width && row_num < screen_height) {
				*col_curr = 0x0700 | data;
				col_curr ++;
				col_num ++;
			}
		}
		else if (data >= 0xF0) {  // control
			if (data == 0xF0) {  // movie size info
				movie_height = *(file_index+1);
				movie_width = *(file_index+2);
				update_position();
				row_base = frame_base + mul(screen_width, row_num);
				col_curr = row_base + col_num;
				file_index += 2;
			}
			else if (data == 0xF1) {  // move cursor
				row_num = *(file_index+1) + blank_top;
				col_num = *(file_index+2) + blank_left;
				row_base = frame_base + mul(screen_width, row_num);
				col_curr = row_base + col_num;
				file_index += 2;
			}
			else if (data == 0xFD) {  // new line
				row_num ++;
				col_num = blank_left;
				row_base += screen_width;
				col_curr = row_base + col_num;
			}
			else if (data == 0xFE) {  // new frame
				return 0;
			}
			else if (data == 0xFF) {  // movie end
				return 1;
			}
		}
		else {
			data -= 0x7f;
			if (data <= 80) {  // jump over
				col_curr += data;
				col_num += data;
			}
			else {  // time delay
				return 80 - data;
			}
		}
		file_index ++;
	}
}

int32 sleep(uint32 value) {
	volatile uint32* vga_config = (uint32*)VGA_ADDR;
	volatile uint32* board_config = (uint32*)BOARD_ADDR;
	vga_config[1] = VRAM_ADDR + VRAM_RANGE;
	mem_copy((int32*)(VRAM_ADDR + VRAM_RANGE), (int32*)VRAM_ADDR, screen_range>>1);
	vga_config[1] = VRAM_ADDR;
	value = (value<<ctrl_play_speed) - 1;
	__asm__ ("mtc0 %0, $7": : "r"(value));
	__asm__ ("mtc0 %0, $5": : "r"(1<<0));
	uint32 data = 0;
	while (1) {
		// check board input
		data = board_config[0];
		ctrl_play_back = (data & 0x800) ? 1 : 0;
		ctrl_play_speed = (data & 0xC00) ? 2 : ((data & 0x200) ? 7 : 6);
		if ((data & 0x100) && ((data & 0xF) != ctrl_vga_mode)) {
			vga_config[1] = VRAM_ADDR + VRAM_RANGE;
			init_vga(data & 0xF, VRAM_ADDR);
			update_position();
			ctrl_vga_mode = data & 0xF;
			__asm__ ("mtc0 %0, $7": : "r"(0));
			__asm__ ("mtc0 %0, $5": : "r"(1<<0));
			return 1;
		}
		// check timer
		__asm__ __volatile__ ("mfc0 %0, $5": "=r"(data));
		if (data & (1<<0)) {
			__asm__ ("mtc0 %0, $7": : "r"(0));
			__asm__ ("mtc0 %0, $5": : "r"(1<<0));
			return 0;
		}
	}
}

int32 paly_movie() {
	file_index = (uint8*)DATA_ADDR;
	frame_count = 0;
	movie_width = 0;
	movie_height = 0;
	blank_top = 0;
	blank_left = 0;
	row_num = 0;
	col_num = 0;
	if (!find_frame(0))
		return -2;
	int32 state = 0;
	while (1) {
		if (state == 0) {
			mem_set((int32*)(VRAM_ADDR + VRAM_RANGE), 0x07200720, screen_range>>1);
			row_num = blank_top;
			col_num = blank_left;
			if (ctrl_play_back) {
				file_index --;
				if (!find_frame(1))
					return -1;
				file_index --;
				if (!find_frame(1))
					return -1;
				frame_count -= 2;
			}
		}
		file_index ++;
		state = render((uint16*)(VRAM_ADDR + VRAM_RANGE));
		if (state == 0) {
			frame_count ++;
			disp_num(frame_count);
		}
		else if (state > 0) {
			return 0;
		}
		else if (state < 0) {
			if (sleep(-state)) {
				if (!find_frame(1))
					return -1;
				state = 0;
			}
		}
		if ((int)file_index >= DATA_ADDR+DATA_RANGE)
			return -2;
	}
}

void bootup() {
	disp_num(0);
	init_vga(1, VRAM_ADDR);
	ctrl_vga_mode = 1;
	while (1) {
		paly_movie();
		sleep(1);
	}
}

void exception(){
	while (1);
}
