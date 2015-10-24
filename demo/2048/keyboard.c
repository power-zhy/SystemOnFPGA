#include "types.h"
#include "keyboard.h"


#define SCAN_BUF_SIZE 64
scancode scan_buf[SCAN_BUF_SIZE];
volatile uint8 scan_buf_ri = 0;
volatile uint8 scan_buf_wi = 0;

#define KEY_BUF_SIZE 16
keycode key_buf[KEY_BUF_SIZE];
volatile uint8 key_buf_ri = 0;
volatile uint8 key_buf_wi = 0;

#define MIN_REPEAT_TIME 50


// scancodes, see http://www.computer-engineering.org/ps2keyboard/scancodes2.html for more details
const uint8 scan2key_table[2][160] = {
	{
		/* 0x00 - 0x07 */ VK_NONE, VK_F9, VK_NONE, VK_F5, VK_F3, VK_F1, VK_F2, VK_F12,
		/* 0x08 - 0x0F */ VK_NONE, VK_F10, VK_F8, VK_F6, VK_F4, VK_TAB, VK_OEM_3, VK_NONE,
		/* 0x10 - 0x17 */ VK_NONE, VK_LMENU, VK_LSHIFT, VK_NONE, VK_LCONTROL, VK_Q, VK_1, VK_NONE,
		/* 0x18 - 0x1F */ VK_NONE, VK_NONE, VK_Z, VK_S, VK_A, VK_W, VK_2, VK_NONE,
		/* 0x20 - 0x27 */ VK_NONE, VK_C, VK_X, VK_D, VK_E, VK_4, VK_3, VK_NONE,
		/* 0x28 - 0x2F */ VK_NONE, VK_SPACE, VK_V, VK_F, VK_T, VK_R, VK_5, VK_NONE,
		/* 0x30 - 0x37 */ VK_NONE, VK_N, VK_B, VK_H, VK_G, VK_Y, VK_6, VK_NONE,
		/* 0x38 - 0x3F */ VK_NONE, VK_NONE, VK_M, VK_J, VK_U, VK_7, VK_8, VK_NONE,
		/* 0x40 - 0x47 */ VK_NONE, VK_OEM_COMMA, VK_K, VK_I, VK_O, VK_0, VK_9, VK_NONE,
		/* 0x48 - 0x4F */ VK_NONE, VK_OEM_PERIOD, VK_OEM_2, VK_L, VK_OEM_1, VK_P, VK_OEM_MINUS, VK_NONE,
		/* 0x50 - 0x57 */ VK_NONE, VK_NONE, VK_OEM_7, VK_NONE, VK_OEM_4, VK_OEM_PLUS, VK_NONE, VK_NONE,
		/* 0x58 - 0x5F */ VK_CAPITAL, VK_RSHIFT, VK_RETURN, VK_OEM_6, VK_NONE, VK_OEM_5, VK_NONE, VK_NONE,
		/* 0x60 - 0x67 */ VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_BACK, VK_NONE,
		/* 0x68 - 0x6F */ VK_NONE, VK_NUMPAD1, VK_NONE, VK_NUMPAD4, VK_NUMPAD7, VK_NONE, VK_NONE, VK_NONE,
		/* 0x70 - 0x77 */ VK_NUMPAD0, VK_DECIMAL, VK_NUMPAD2, VK_NUMPAD5, VK_NUMPAD6, VK_NUMPAD8, VK_ESCAPE, VK_NUMLOCK,
		/* 0x78 - 0x7F */ VK_F11, VK_ADD, VK_NUMPAD3, VK_SUBTRACT, VK_MULTIPLY, VK_NUMPAD9, VK_NONE, VK_NONE,
		/* 0x80 - 0x87 */ VK_NONE, VK_NONE, VK_NONE, VK_F7, VK_NONE, VK_NONE, VK_NONE, VK_NONE,
		/* 0x88 - 0x8F */ VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE,
		/* 0x90 - 0x97 */ VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE,
		/* 0x98 - 0x9F */ VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE
	},
	{
		/* 0x00 - 0x07 */ VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE,
		/* 0x08 - 0x0F */ VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE,
		/* 0x10 - 0x17 */ VK_BROWSER_SEARCH, VK_RMENU, VK_NONE, VK_NONE, VK_RCONTROL, VK_MEDIA_PREV_TRACK, VK_NONE, VK_NONE,
		/* 0x18 - 0x1F */ VK_BROWSER_FAVORITES, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_LWIN,
		/* 0x20 - 0x27 */ VK_BROWSER_REFRESH, VK_VOLUME_DOWN, VK_NONE, VK_VOLUME_MUTE, VK_NONE, VK_NONE, VK_NONE, VK_RWIN,
		/* 0x28 - 0x2F */ VK_BROWSER_STOP, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_APPS,
		/* 0x30 - 0x37 */ VK_BROWSER_FORWARD, VK_NONE, VK_VOLUME_UP, VK_NONE, VK_MEDIA_PLAY_PAUSE, VK_NONE, VK_NONE, VK_NONE,
		/* 0x38 - 0x3F */ VK_BROWSER_BACK, VK_NONE, VK_BROWSER_HOME, VK_MEDIA_STOP, VK_NONE, VK_NONE, VK_NONE, VK_NONE,
		/* 0x40 - 0x47 */ VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE,
		/* 0x48 - 0x4F */ VK_LAUNCH_MAIL, VK_NONE, VK_DIVIDE, VK_NONE, VK_NONE, VK_MEDIA_NEXT_TRACK, VK_NONE, VK_NONE,
		/* 0x50 - 0x57 */ VK_LAUNCH_MEDIA_SELECT, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE,
		/* 0x58 - 0x5F */ VK_NONE, VK_NONE, VK_RETURN, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE,
		/* 0x60 - 0x67 */ VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE,
		/* 0x68 - 0x6F */ VK_NONE, VK_END, VK_NONE, VK_LEFT, VK_HOME, VK_NONE, VK_NONE, VK_NONE,
		/* 0x70 - 0x77 */ VK_INSERT, VK_DELETE, VK_DOWN, VK_NONE, VK_RIGHT, VK_UP, VK_NONE, VK_NONE,
		/* 0x78 - 0x7F */ VK_NONE, VK_NONE, VK_NEXT, VK_NONE, VK_NONE, VK_PRIOR, VK_NONE, VK_NONE,
		/* 0x80 - 0x87 */ VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE,
		/* 0x88 - 0x8F */ VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE,
		/* 0x90 - 0x97 */ VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE,
		/* 0x98 - 0x9F */ VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE, VK_NONE
	}
};

const uint8 key2ascii_table[2][256] = {
	{
		/* 0x00 - 0x0F */ 0, 0, 0, 0, 0, 0, 0, 0,  '\b', '\t', 0, 0, 0, '\n', 0, 0,
		/* 0x10 - 0x1F */ 0, 0, 0, 0, 0, 0, 0, 0,  0, 0, 0, 27, 0, 0, 0, 0,
		/* 0x20 - 0x2F */ ' ', 0, 0, 0, 0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 127, 0,
		/* 0x30 - 0x3F */ '0', '1', '2', '3', '4', '5', '6', '7',  '8', '9', 0, 0, 0, 0, 0, 0,
		/* 0x40 - 0x4F */ 0, 'a', 'b', 'c', 'd', 'e', 'f', 'g',  'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o',
		/* 0x50 - 0x5F */ 'p', 'q', 'r', 's', 't', 'u', 'v', 'w',  'x', 'y', 'z', 0, 0, 0, 0, 0,
		/* 0x60 - 0x6F */ '0', '1', '2', '3', '4', '5', '6', '7',  '8', '9', '*', '+', 0, '-', '.', '/',
		/* 0x70 - 0x7F */ 0, 0, 0, 0, 0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0,
		/* 0x80 - 0x8F */ 0, 0, 0, 0, 0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0,
		/* 0x90 - 0x9F */ 0, 0, 0, 0, 0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0,
		/* 0xA0 - 0xAF */ 0, 0, 0, 0, 0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0,
		/* 0xB0 - 0xBF */ 0, 0, 0, 0, 0, 0, 0, 0,  0, 0, ';', '=', ',', '-', '.', '/',
		/* 0xC0 - 0xCF */ '`', 0, 0, 0, 0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0,
		/* 0xD0 - 0xDF */ 0, 0, 0, 0, 0, 0, 0, 0,  0, 0, 0, '[', '\\', ']', '\'', 0,
		/* 0xE0 - 0xEF */ 0, 0, 0, 0, 0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0,
		/* 0xF0 - 0xFF */ 0, 0, 0, 0, 0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0
	},
	{
		/* 0x00 - 0x0F */ 0, 0, 0, 0, 0, 0, 0, 0,  '\b', '\t', 0, 0, 0, '\n', 0, 0,
		/* 0x10 - 0x1F */ 0, 0, 0, 0, 0, 0, 0, 0,  0, 0, 0, 27, 0, 0, 0, 0,
		/* 0x20 - 0x2F */ ' ', 0, 0, 0, 0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 127, 0,
		/* 0x30 - 0x3F */ ')', '!', '@', '#', '$', '%', '^', '&',  '*', '(', 0, 0, 0, 0, 0, 0,
		/* 0x40 - 0x4F */ 0, 'A', 'B', 'C', 'D', 'E', 'F', 'G',  'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O',
		/* 0x50 - 0x5F */ 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W',  'X', 'Y', 'Z', 0, 0, 0, 0, 0,
		/* 0x60 - 0x6F */ '0', '1', '2', '3', '4', '5', '6', '7',  '8', '9', '*', '+', 0, '-', '.', '/',
		/* 0x70 - 0x7F */ 0, 0, 0, 0, 0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0,
		/* 0x80 - 0x8F */ 0, 0, 0, 0, 0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0,
		/* 0x90 - 0x9F */ 0, 0, 0, 0, 0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0,
		/* 0xA0 - 0xAF */ 0, 0, 0, 0, 0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0,
		/* 0xB0 - 0xBF */ 0, 0, 0, 0, 0, 0, 0, 0,  0, 0, ':', '+', '<', '_', '>', '?',
		/* 0xC0 - 0xCF */ '~', 0, 0, 0, 0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0,
		/* 0xD0 - 0xDF */ 0, 0, 0, 0, 0, 0, 0, 0,  0, 0, 0, '{', '|', '}', '"', 0,
		/* 0xE0 - 0xEF */ 0, 0, 0, 0, 0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0,
		/* 0xF0 - 0xFF */ 0, 0, 0, 0, 0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0
	}
};

bool shift_down = false;
bool ctrl_down = false;
bool alt_down = false;
bool win_down = false;  // WIN combination key not supported

void code_convert() {
	// not supported: PRINT_SCREEN, PAUSE, POWER, SLEEP, WAKE
	static uint8 last_type = 0;
	static uint8 last_code = 0;
	static uint32 last_time = 0;
	while (1) {
		uint8 buf_size = scan_buf_wi + SCAN_BUF_SIZE - scan_buf_ri;
		if (buf_size >= SCAN_BUF_SIZE)
			buf_size -= SCAN_BUF_SIZE;
		if (buf_size == 0)
			return;  // scancode buffer empty
		uint8 next_index = key_buf_wi + 1;
		if (next_index >= KEY_BUF_SIZE)
			next_index -= KEY_BUF_SIZE;
		if (next_index == key_buf_ri)
			return;  // keycode buffer full
		if (scan_buf[scan_buf_ri].scan_code == 0xE1) {
			// skip PAUSE key
			if (buf_size < 8)
				return;
			scan_buf_ri = scan_buf_ri + 8;
			if (scan_buf_ri >= SCAN_BUF_SIZE)
				scan_buf_ri -= SCAN_BUF_SIZE;
		}
		else {
			bool extended = false;
			bool key_up = false;
			uint8 key_code = 0xFF;
			if (scan_buf[scan_buf_ri].scan_code == 0xE0) {
				extended = true;
				scan_buf_ri = scan_buf_ri + 1;
				if (scan_buf_ri >= SCAN_BUF_SIZE)
					scan_buf_ri -= SCAN_BUF_SIZE;
			}
			if (scan_buf[scan_buf_ri].scan_code == 0xF0) {
				key_up = true;
				scan_buf_ri = scan_buf_ri + 1;
				if (scan_buf_ri >= SCAN_BUF_SIZE)
					scan_buf_ri -= SCAN_BUF_SIZE;
			}
			scancode scan = scan_buf[scan_buf_ri];
			if (scan.scan_code < 0xA0) {
				if (key_up != last_type || scan.scan_code != last_code || scan.time - last_time >= MIN_REPEAT_TIME) {
					uint8 code = scan2key_table[extended][scan.scan_code];
					if (code != VK_NONE) {
						// CAPS_LOCK not supported, as LEDs in keyboard are not supported
						uint8 ascii = key2ascii_table[shift_down][code];
						keycode key = {code, ascii, shift_down, ctrl_down, alt_down, key_up, scan.time};
						bool repeat = false;
						if (code == VK_SHIFT || code == VK_LSHIFT || code == VK_RSHIFT) {
							if (shift_down == !key_up)
								repeat = true;
							else
								shift_down = !key_up;
						}
						else if (code == VK_CONTROL || code == VK_LCONTROL || code == VK_RCONTROL) {
							if (ctrl_down == !key_up)
								repeat = true;
							else
								ctrl_down = !key_up;
						}
						else if (code == VK_MENU || code == VK_LMENU || code == VK_RMENU) {
							if (alt_down == !key_up)
								repeat = true;
							else
								alt_down = !key_up;
						}
						else if (code == VK_LWIN || code == VK_RWIN) {
							if (win_down == !key_up)
								repeat = true;
							else
								win_down = !key_up;
						}
						if (!repeat) {
							key_buf[key_buf_wi] = key;
							key_buf_wi = next_index;
						}
					}
					last_code = scan.scan_code;
					last_time = scan.time;
				}
			}
			scan_buf_ri = scan_buf_ri + 1;
			if (scan_buf_ri >= SCAN_BUF_SIZE)
				scan_buf_ri -= SCAN_BUF_SIZE;
		}
	}
}

void scancode_recv(uint8 scan_code, uint32 time) {
	uint8 next_index = scan_buf_wi + 1;
	if (next_index >= SCAN_BUF_SIZE)
		next_index -= SCAN_BUF_SIZE;
	if (next_index == scan_buf_ri)
		return;  // scancode buffer full
	scancode scan = {scan_code, time};
	scan_buf[scan_buf_wi] = scan;
	scan_buf_wi = next_index;
	if (scan_code < 0xA0)
		code_convert();
}

keycode get_key(uint8 type, bool block) {
	while (1) {
		if (key_buf_wi == key_buf_ri) {
			if (!block) {
				keycode key = {VK_NONE, shift_down, ctrl_down, alt_down, false, 0};
				return key;
			}
		}
		else {
			keycode key = key_buf[key_buf_ri];
			key_buf_ri = key_buf_ri + 1;
			if (key_buf_ri >= KEY_BUF_SIZE)
				key_buf_ri -= KEY_BUF_SIZE;
			if (((type & WM_KEYDOWN) && !key.key_up) || ((type & WM_KEYUP) && key.key_up))
				return key;
		}
	}
}

uint8 get_char(bool block) {
	while (1) {
		keycode key = get_key(WM_KEYDOWN, block);
		if (key.ascii)
			return key.ascii;
		else if (!block)
			return 0;
	}
}
