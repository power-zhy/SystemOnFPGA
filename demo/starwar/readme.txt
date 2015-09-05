Star Wars Asciimation Demo
Author: Zhao, Hongyu  <power_zhy@foxmail.com>

Porting the amazing ASCII movie "STARWAR" to the SOC platform.
Original Author: Simon Jansen  <www.asciimation.co.nz>

Usage:
	1. Write "starwar.dat" to BPI Flash with start address 0x0100000
	2. Write "ascii_palyer.bin" to BPI Flash with start address 0x0
	3. Program the FPGA board with BIT file
	4. Enjoy!

When running:
	BTNRST(Sword) or BTNC(Nexys3): Restart
	SW[11](Sword) or BTNL(Nexys3): Fast Rewind
	SW[10](Sword) or BTNR(Nexys3): Fast Forward
	SW[09](Sword) or BTNU(Nexys3): Half Play Speed
	SW[08](Sword) or BTND(Nexys3): Set the VGA's resolution by Switch[3:0]
	Switch[7]: System Pause (entering debug mode, see debug.txt for more detail)
	7-Segment Display: Show current frame number


Extra - ASCII Player's coding standard:
	For code X:
	0x00 - 0x7F: Normal characters to display, the ASCII value is X
	0x80 - 0xCF: Jump over spaces, the number is X-0x7F
	0xD0 - 0xEF: Time delay, the time is X-0xCF (with time unit appropriate of 64ms)
	0xF0 - 0xFF: Control
		0xF0 h w: Movie size info (height, weight), should be at the beginning of one frame
		0xF1 r c: Move cursor to (row, column)
		0xFD: New line
		0xFE: New frame
		0xFF: Movie end
		others: Reversed, should not be used
