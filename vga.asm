[BITS 32]

org 0

section .text

id: dw 0xb800
size: dw 2
dd print_char 
dd move_cursor
boot:
	ret
print_char:
	push ebx

	mov dword eax, [ebp + 8]
	mov ebx, [ebp - 4]
	mov word bx, [ebx + index]
	and ebx, 0xffff
	mov ah, 0x17
	mov word [0xb8000 + ebx*2], ax
	
	mov ebx, [ebp - 4]
	inc word [ebx + index]

	pop ebx
	add esp, 4
	pop ebp
	ret
move_cursor:
	push ebx

	mov dword eax, [ebp + 8]
	mov ebx, [ebp - 4]
	mov word [ebx + index], ax

	pop ebx
	add esp, 4
	pop ebp
	ret
global_variables:
	index dw 0
