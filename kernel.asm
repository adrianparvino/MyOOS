[BITS 32]

org 0x100000
MBALIGN     equ  1<<0
MEMINFO     equ  1<<1
MKLUDGE     equ  1<<16
FLAGS       equ  MBALIGN | MEMINFO | MKLUDGE
MAGIC       equ  0x1BADB002
CHECKSUM    equ -(MAGIC + FLAGS)

section .text

multiboot:
align 4
	dd MAGIC
	dd FLAGS
	dd CHECKSUM

aout_k:
	dd multiboot
	dd multiboot
	dd _bss
	dd _end
	dd _start

%define BOS 0x100000
;-----------------------------
GDT:
GDT_0:
	dq 0
GDT_1:
	dw 0xffff ;limit 0:15
	dw 0x0000 ;base  0:15
	db 0x00   ;base  16:23
	db 0x9a   ;access
	db 0xcf   ;flag + limit 16:19
	db 0x00   ;base  24:31
GDT_2:
	dw 0xffff ;limit 0:15
	dw 0x0000 ;base  0:15
	db 0x00   ;base  16:23
	db 0x92   ;access
	db 0xcf   ;flag + limit 16:19
	db 0x00   ;base  24:31
IDT:
	times 64 dq ((BOS - $$ + do_nothing) >> 16) << 48 | 0x8e<< 40 | 0x8<<16 | ((BOS - $$ + do_nothing) & 0xffff)
GDTR:
	dw 0x17
	dd GDT
IDTR:
	dw 0x1ff
	dd IDT
;-----------------------------------
_global:
	color db 0x17
	module_list dd 0
;------------------------------------
do_nothing:
	iret
;------------------------------------------
echo:
	pushad

	inc dword [echo_count]

	mov al, 0x20
	out byte 0x20, al
	in byte al, 0x60
	popad
	iret
echo_string_0:
	db "Key pressed yay! \o/ ", 0
echo_count:
	dd 0
;---------------------------------------------
load_keyboard:
	lea eax, [IDT + 0x21*8]
	mov word [eax], (BOS - $$ + echo) & 0xffff
	mov word [eax + 2], 0x8
	mov byte [eax + 4], 0
	mov byte [eax + 5], 0x8e
	mov word [eax + 6], (BOS - $$ + echo) >> 16
	ret
;---------------------------------------------
halt:
	cli
	hlt
;-------------------
run_module:
	push ebp
	mov ebp, esp
	sub esp, 4
	push ebx
	mov ebx, eax
	shr eax, 16
	push eax
	mov eax, [module_list + eax*4]
	mov [esp + 8], eax
	and ebx, 0xffff
	lea eax, [eax + ebx*4 + 4]
	mov eax, [eax]
	pop ebx
	add eax, [module_list + ebx*4]
	pop ebx
	jmp eax
;--------------------------------------------
_start:
allocate_stack:
		mov ecx, [ebx + 44]
		add ecx, [ebx + 48]
		mov edx, [ebx + 48]
		jmp above_1_MB_0
	read_next_0:
		add edx, [edx - 4]
		add edx, 4
	above_1_MB_0:
		cmp dword [edx], 0x10000
		jb read_next_0
	read_next_1:
		mov eax, edx
		add edx, [edx - 4]
		add edx, 4
	check_memory_table_0:
		test dword [edx + 16], 0x1
		jz read_next_0
		cmp dword [edx + 8], 65536
		jne read_next_0
		cmp dword [edx + 12], 0
		jne read_next_0
	found_0:
		mov byte [edx + 16], 0
		mov esp, dword [edx]
		add esp, 65536
allocate_module_table:
	read_next_3:
		add eax, [eax - 4]
		add eax, 4
	check_memory_table_1:
		test dword [eax + 16], 0x1
		jz read_next_3
		cmp dword [eax + 12], 1
		jae found_1
		cmp dword [eax + 8], 65536*4
		jna read_next_3
	found_1:
		sub dword [eax + 8], 65536*4
		jnc else
		sub dword [eax + 12], 1
	else:
		mov eax, [eax]
		add eax, [eax + 8]
		mov dword [module_list], eax
minimum_GDT_IDT_setup:
		lgdt [GDTR]
		lidt [IDTR]
		jmp 0x08:reload
	reload:
		mov ax, 0x10
		mov ds, ax
		mov es, ax
		mov fs, ax
		mov gs, ax
		mov ss, ax

PIC_remap:
		mov al, 0x11
		out byte 0x20, al ;start init sequence
		out byte 0xa0, al
		
		mov al, 0x20

		out byte 0x21, al ;point to offset
		mov al, 0x28
		out byte 0xa1, al

		mov al, 0x4
		out byte 0x21, al ;tell cascade identity
		mov al, 0x2
		out byte 0xa1, al
		
		mov al, 0x01
		out byte 0x21, al
		out byte 0xa1, al

PIC_mask:
		mov al, 0xfd
		out 0x21, al
		mov al, 0xff
		out 0xa1, al

int_setup:
		call load_keyboard
		;sti
load_modules:
	mov ecx, [ebx + 20]
	mov edx, [ebx + 24]
load_loop:
	jecxz temp
	mov eax, [edx]
	push edx
	mov edx, eax
	mov word ax, [eax]
	and eax, 0xffff
	mov [module_list + eax*4], edx
	xor eax, eax
	mov word ax, [edx + 2]
	lea eax, [eax*4 + 4]
	add eax, edx
	call eax
	pop edx
	dec ecx
	jmp load_loop
temp:
	mov al, [hi]
	and al, 0xff
	jz _stop
	push dword eax
	mov eax, 0xb8000000
	call run_module
	jmp temp
_stop:
	hlt
	jmp _stop
hi: db "Hello world!", 0
_bss:
_end:
