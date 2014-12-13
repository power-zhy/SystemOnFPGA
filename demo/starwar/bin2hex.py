def bin2hex(bin_path, hex_path):
	with open(bin_path, "rb") as input, open(hex_path, "w") as output:
		while (True):
			bin = input.read(4)
			if (len(bin) != 4):
				break
			output.write("{:02X}{:02X}{:02X}{:02X}\n".format(bin[3], bin[2], bin[1], bin[0]))

if __name__ == "__main__":
	import sys
	if (len(sys.argv) != 3):
		print("Usage: {} bin_path hex_path".format(sys.argv[0]))
	else:
		bin2hex(sys.argv[1], sys.argv[2])
