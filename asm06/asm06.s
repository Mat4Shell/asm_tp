section .data
    	msg_format db "%d", 10, 0

section .bss
    	arg1 resq 1
    	arg2 resq 1
    	sum resq 1

section .text
    	global _start

_start:
    	pop rax
    	cmp rax, 3
    	jne error

    	pop rsi
    	pop rax
    	mov [arg1], rax
    	pop rax
    	mov [arg2], rax

    	mov rax, 0
    	mov rcx, 0
convert_arg1:
    	mov rdx, 10
    	mov rbx, [arg1]
    	movzx rbx, byte [rbx + rcx]
    	cmp rbx, 0
    	je end_convert_arg1
    	sub rbx, '0'
    	imul rax, rdx
    	add rax, rbx
    	inc rcx
    	jmp convert_arg1

end_convert_arg1:
    	mov [arg1], rax

    	mov rax, 0
    	mov rcx, 0
convert_arg2:
    	mov rdx, 10
    	mov rbx, [arg2]
    	movzx rbx, byte [rbx + rcx]
    	cmp rbx, 0
    	je end_convert_arg2
    	sub rbx, '0'
    	imul rax, rdx
    	add rax, rbx
    	inc rcx
    	jmp convert_arg2

end_convert_arg2:
    	mov [arg2], rax

    	mov rax, [arg1]
    	add rax, [arg2]
    	mov [sum], rax

	mov rdi, msg_format
    	mov rsi, [sum]
    	mov rax, 0
    	call printf


    	mov rax, 60
    	xor rdi, rdi
    	syscall

error:
    	mov rax, 60
    	xor rdi, rdi
    	syscall

section .text
    	extern printf
