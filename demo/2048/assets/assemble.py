origs = ["0", "2", "4", "8", "16", "32", "64", "128", "256", "512", "1024", "2048"]
format = "bmp"
width = 80
height = 80

from PIL import Image
with open("asset.bin", "wb") as result:
	count = 0
	for index, orig in enumerate(origs):
		name = orig + "." + format
		with Image.open(name) as img:
			assert(img.size == (width, height))
			for y in range(width):
				for x in range(height):
					pixel = img.getpixel((x, y))
					pixel = ((pixel[0]&0xE0) | ((pixel[1]&0xE0)>>3) | ((pixel[2]&0xC0)>>6))
					count += result.write(bytes([pixel]))
	print("Total size:", count);
