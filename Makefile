kernel: kernel.asm
	nasm -f bin kernel.asm
vga:	vga.asm
	nasm -f bin vga.asm
install: kernel vga
	mount -o loop boot.vfd bootvfd
	cp kernel bootvfd/boot/kernel.bin
	cp vga bootvfd/boot/vga.bin
	umount bootvfd
