section .bss
	input resb 6

section .text
   	global _start

_start:
	mov rax, 0
	mov rdi, 0
	mov rsi, input
	mov rdx, 6
	syscall

loop:
	movzx rbx, byt [input + rcx]
	test rbx, rbx
	jz converted

	cmp rbx, 10
	je converted

	cmp rbx, '0'
	jb lettr
	cmp rbx, '9'
	ja lettr

	sub rbx, '0'
	imul rax, rax, 10
	add rax, rbx
	inc rcx
	jmp converted

converted:
	and rax, 1
	jz evnn

outprog:
	mov rax, 60
	mov rdi, 1
	syscall

evnn:
   	mov rax, 60
	mov rdi, 0
	syscall

lettr:
	mov rax, 60
	mov rdi, 2
	syscall