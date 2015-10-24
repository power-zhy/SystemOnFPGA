CC = mips-elf-gcc
CCARGS = -O2 -G0 -EL -fno-builtin
LD = mips-elf-ld
LDARGS = -O2 -EL
OBJCOPY = mips-elf-objcopy
OBJDUMP = mips-elf-objdump

objs = boot.o types.o random.o keyboard.o 2048_core.o 2048.o

.PHONY: all
all: 2048.bin 2048.txt

2048.bin: 2048.elf
	$(OBJCOPY) -O binary 2048.elf 2048.bin

2048.txt: 2048.elf
	$(OBJDUMP) -S -z 2048.elf > 2048.txt

2048.elf: boot.lds $(objs)
	$(LD) $(LDARGS) -T boot.lds -o 2048.elf $(objs)

boot.o: boot.S
	$(CC) $(CCARGS) -o boot.o -c boot.S
types.o: types.c types.h
	$(CC) $(CCARGS) -o types.o -c types.c
random.o: random.c random.h types.h
	$(CC) $(CCARGS) -o random.o -c random.c
keyboard.o: keyboard.c keyboard.h types.h
	$(CC) $(CCARGS) -o keyboard.o -c keyboard.c
2048_core.o: 2048_core.c 2048_core.h types.h random.h
	$(CC) $(CCARGS) -o 2048_core.o -c 2048_core.c
2048.o: 2048.c types.h random.h keyboard.h 2048_core.h
	$(CC) $(CCARGS) -o 2048.o -c 2048.c

.PHONY: clean
clean:
	-rm -f *.o 2048.elf 2048.bin 2048.txt
