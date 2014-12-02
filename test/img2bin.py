def img2bin(src, dst):
	from PIL import Image
	img = Image.open(src)
	file = open(dst, 'wb')
	width, height = img.size
	chs = img.split()
	if (len(chs) >= 3):
		chr = chs[0]
		chg = chs[1]
		chb = chs[2]
	else:
		chr = chs[0]
		chg = chs[0]
		chb = chs[0]
	for j in range(height):
		for i in range(width):
			r = (chr.getpixel((i,j)) >> 5) & 0x7
			g = (chg.getpixel((i,j)) >> 5) & 0x7
			b = (chb.getpixel((i,j)) >> 6) & 0x3
			data = (r << 5) | (g << 2) | b
			file.write(bytes([data]))
	img.close()
	file.close()

if __name__ == "__main__":
	import sys
	if (len(sys.argv) < 2):
		print("Usage: {} img_path bin_path".format(sys.argv[0]))
	src = sys.argv[1]
	if (len(sys.argv) < 3):
		index = src.rfind('.')
		if (index >= 0):
			dst = src[:index] + ".bin"
		else:
			dst = src + ".bin"
	else:
		src = sys.argv[2]
	img2bin(src, dst)
	