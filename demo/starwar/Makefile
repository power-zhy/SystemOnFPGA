CC = mips-elf-gcc
CCARGS = -O2 -G0 -EL -fno-builtin
LD = mips-elf-ld
LDARGS = -O2 -EL
OBJCOPY = mips-elf-objcopy
OBJDUMP = mips-elf-objdump

objs = boot.o ascii_player.o

.PHONY: all
all: ascii_player.bin ascii_player.txt

ascii_player.bin: ascii_player.elf
	$(OBJCOPY) -O binary ascii_player.elf ascii_player.bin

ascii_player.txt: ascii_player.elf
	$(OBJDUMP) -S -z ascii_player.elf > ascii_player.txt

ascii_player.elf: boot.lds $(objs)
	$(LD) $(LDARGS) -T boot.lds -o ascii_player.elf $(objs)

boot.o: boot.S
	$(CC) $(CCARGS) -o boot.o -c boot.S
ascii_player.o: ascii_player.c
	$(CC) $(CCARGS) -o ascii_player.o -c ascii_player.c

.PHONY: clean
clean:
	-rm -f *.o ascii_player.elf ascii_player.bin ascii_player.txt
