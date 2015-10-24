2048 Game Demo
Author: Zhao, Hongyu  <power_zhy@foxmail.com>

Porting the amazing game "2048" to the SOC platform.
Original Author: Gabriele Cirulli  <http://git.io/2048>

Usage:
	1. Write "assets/asset.bin" to BPI Flash with start address 0x0100000
	2. Write "2048.bin" to BPI Flash with start address 0x0
	3. Program the FPGA board with BIT file
	4. Enjoy!

When running:
	Play it with WSAD or ARROW keys
	Ctrl+[1-7]: Change resolution mode
	7-Segment Display: Show current step count
