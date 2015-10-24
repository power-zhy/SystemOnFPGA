def bin2hex(bin_path, dst1_path, dst2_path):
	with open(bin_path, "rb") as src, open(dst1_path, "wb") as dst1, open(dst2_path, "wb") as dst2:
		while (True):
			bin = src.read(4)
			if (len(bin) != 4):
				break
			dst1.write(bin[0:2])
			dst2.write(bin[2:4])

if __name__ == "__main__":
	import sys
	if (len(sys.argv) < 2):
		print("Usage: {} bin_path [dst1_path] [dst2_path]".format(sys.argv[0]))
	src = sys.argv[1]
	if (len(sys.argv) < 4):
		index = src.rfind('.')
		if (index >= 0):
			dst1 = src[:index] + "_1" + src[index:]
			dst2 = src[:index] + "_2" + src[index:]
		else:
			dst1 = src + "_1"
			dst2 = src + "_2"
	else:
		dst1 = sys.argv[2]
		dst2 = sys.argv[3]
	bin2hex(src, dst1, dst2)
	