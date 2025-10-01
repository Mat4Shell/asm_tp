global _start
_start:

section .data
	msg db "1337", 10

section .bss
        input resb 6

section .text
	
	mov rax, [rsp]
	cmp rax, 2
	jl not_42

	mov rdi, [rsp + 16]

	mov al, byte [rdi]
	cmp al, '4'
	jne not_42

 	mov al, byte [rdi + 1]
 	cmp al, '2'
 	jne not_42

 	mov al, byte [rdi + 2]
 	cmp al, 0
 	jne not_42

	xor rax, rax
	xor rdi, rdi
 	xor rsi, rsi    

 	mov rax, 1
	mov rdi, 1
	mov rsi, msg
	mov rdx, 10
	syscall

	mov rax, 60
	mov rdi, 0
	syscall

not_42:
 	xor rax, rax
    	xor rdi, rdi    

   	mov rax, 60
    	mov rdi, 1
    	syscall