section .data
    	value db "42", 0
    	msg db "1337", 0

section .bss
    	arg1 resq 1
    	size_arg1 resq 1

section .text
    	global _start

_start:
    	pop rax
    	cmp rax, 2
    	jne error

    	pop rsi
    	pop rax
   	mov [arg1], rax

    	mov rcx, 0
size1:
    	mov rax, [arg1]
    	cmp byte [rax + rcx], 0
    	je end_size1
    	inc rcx
    	jmp size1

end_size1:
    	mov [size_arg1], rcx

    	mov rax, 0
    	mov rcx, 0
convert_loop:
    	mov rdx, 10
    	mov rbx, [arg1]
    	movzx rbx, byte [rbx + rcx]
    	cmp rbx, 0
    	je end_convert
    	sub rbx, '0'
   	imul rax, rdx
 	add rax, rbx
	inc rcx
 	jmp convert_loop

end_convert:
	cmp rax, 42
	je is_42
	mov rax, 1
	jmp end_prog

is_42:
    	mov rax, 1
    	mov rdi, 1
    	mov rsi, msg
    	mov rdx, 4
    	syscall

    	mov rax, 60
	mov rdi, 0
    	syscall

end_prog:
	mov rax, 1
	mov rdi, 1
	mov rsi, msg
	mov rdx, 4
	syscall

	mov rax, 60
	mov rdi, 1
	syscall

error:
	mov rax, 60
	xor rdi, rdi
	syscall
