ASM = nasm

%: %.asm
	${ASM} -f bin $<
install: kernel vga
	mount -o loop boot.vfd bootvfd
	cp kernel bootvfd/boot/kernel.bin
	cp vga bootvfd/boot/vga.bin
	umount bootvfd
