OUTPUT_FORMAT("elf32-littlemips", "elf32-bigmips", "elf32-littlemips")
OUTPUT_ARCH(mips)
ENTRY(entry)
SECTIONS {
	. = 0xFF000000;
	.text : AT(0x0) {
		*(.text)
	}
	.rodata : {
		*(.rodata*)
	}
	PROVIDE (_realloc = ALIGN(4));
	. = 0x00000000;
	PROVIDE (_data = .);
	.data : AT((SIZEOF(.text)+SIZEOF(.rodata)+3) & ~(3)) {
		*(.data)
		*(.sdata)
	}
	PROVIDE (_edata = .);
	PROVIDE (_bss = .);
	.bss : AT((SIZEOF(.text)+SIZEOF(.rodata)+SIZEOF(.data)+7) & ~(3)) {
		*(.bss)
		*(.sbss)
	}
	PROVIDE (_ebss = .);
}