'''
Code Standard:
0x00 - 0x7F: Normal characters to display, the ascii value is X
0x80 - 0xCF: Jump over spaces, the number is X-0x7F
0xD0 - 0xEF: Time delay, the time is X-0xCF (with time unit appropriate of 64ms)
0xF0 - 0xFF: Control
	0xF0 h w: Movie size info (height, weight), should be at the beginning of one frame
	0xF1 r c: Move cursor to (row, column)
	0xFD: New line
	0xFE: New frame
	0xFF: Movie end
	others: Reversed
'''

MOVIE_WIDTH = 68
MOVIE_HEIGHT = 14

import itertools
frames = []
with open("starwar.txt", "r") as infile:
	lines = infile.readlines()
	i = 0
	while (i<len(lines)):
		frames.append(lines[i:i+MOVIE_HEIGHT])
		i += MOVIE_HEIGHT
with open("starwar.dat", "wb") as outfile:
	outfile.write(b"Star Wars Asciimation\n")
	outfile.write(b"www.asciimation.co.nz presents\n")
	outfile.write(b"Ported by zhy@swanspace.org\n")
	contents = [0xFE, 0xF0, MOVIE_HEIGHT, MOVIE_WIDTH]
	outfile.write(bytes(contents))
	ii = 0
	for frame in frames:
		assert (len(frame) <= MOVIE_HEIGHT)
		contents = []
		ii += 1
		delay = int(frame[0])
		for line in frame[1:]:
			line = line.replace('\n', '')
			assert (len(line) <= MOVIE_WIDTH)
			count = 0
			for ch in line:
				if (ch == ' '):
					count += 1
				else:
					if (count == 1):
						contents.append(ord(' '))
					elif (count > 1):
						contents.append(0x7F + count)
					count = 0
					contents.append(ord(ch))
			contents.append(0xFD)
		while (delay > 32):
			contents.append(0xCF + 32)
			delay -= 32
		if (delay > 0):
			contents.append(0xCF + delay)
		contents.append(0xFE)
		outfile.write(bytes(contents))
	contents = [0xFF]
	outfile.write(bytes(contents))
print("Done!", len(frames), "frames converted.")
