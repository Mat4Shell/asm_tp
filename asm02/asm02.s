section .bss
        input resb 6

section .data
        value db "42", 0
        msg db "1337", 0

section .text
global _start

_start:
	mov rax, 0
	mov rdi, 0
	mov rsi, input
	mov rdx, 32
	syscall

        mov al, [value]
        mov bl, [input]
        cmp al, bl
        jne not_42

        mov rax, 1
        mov rdx, 1
        mov rsi, msg
        mov rdx, 4
        syscall

        mov rax, 60
        mov rdi, 0
        syscall

not_42:
        mov rax, 60
        mov rdi, 1
        syscall
