; asm08.asm
; Sum of integers below N
; Usage: ./asm08 N
; Example: ./asm08 5 -> prints 10

section .bss
    buf resb 32

section .text
    global _start

_start:
    ; argc in [rsp]
    mov rdi, [rsp]          ; argc
    cmp rdi, 2
    jne bad_input

    ; argv[1] -> [rsp+16]
    mov rsi, [rsp+16]       ; argv[1]
    mov rdi, rsi

    ; convertir string -> entier (base 10)
    xor rbx, rbx            ; valeur finale
.convert_loop:
    mov al, [rsi]
    cmp al, 0
    je .done_convert
    cmp al, '0'
    jb bad_input
    cmp al, '9'
    ja bad_input
    sub al, '0'
    imul rbx, rbx, 10
    add rbx, rax
    inc rsi
    jmp .convert_loop

.done_convert:
    ; RBX = N
    cmp rbx, 1
    jb .print_zero   ; si N <= 0 → somme = 0

    ; somme = (N-1)*N/2
    mov rax, rbx
    dec rax          ; rax = N-1
    imul rax, rbx    ; rax = (N-1)*N
    shr rax, 1       ; divisé par 2

    jmp .print_result

.print_zero:
    xor rax, rax

.print_result:
    ; convertir RAX en string
    mov rcx, buf + 31
    mov rbx, 10
    mov byte [rcx], 10    ; newline
    dec rcx
    cmp rax, 0
    jne .convert_digit
    mov byte [rcx], '0'
    dec rcx
    jmp .done_number

.convert_digit:
    xor rdx, rdx          ; important avant div !
.repeat_div:
    div rbx               ; divise rdx:rax par rbx
    add dl, '0'
    mov [rcx], dl
    dec rcx
    test rax, rax
    jnz .repeat_div

.done_number:
    inc rcx
    mov rdx, buf+32
    sub rdx, rcx
    mov rsi, rcx
    mov rax, 1
    mov rdi, 1
    syscall

    ; exit(0)
    mov rax, 60
    xor rdi, rdi
    syscall

bad_input:
    mov rax, 60
    mov rdi, 1
    syscall
