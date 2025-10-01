global _start

section .bss
    result resb 64

section .text
_start:
    mov rbx, [rsp]
    cmp rbx, 4
    jl error

    mov rsi, [rsp + 16]
    mov rdx, [rsp + 24]
    mov r8, [rsp + 32]

    mov rdi, rsi
    call str_to_int
    mov r9, rax

    mov rdi, rdx
    call str_to_int
    mov r10, rax

    mov rdi, r8
    call str_to_int
    mov r11, rax

    mov rax, r9
    cmp r10, rax
    jle check_r11
    mov rax, r10

check_r11:
    cmp r11, rax
    jle display_result             ; Si r11 <= rax, rax reste le plus grand
    mov rax, r11                   ; Sinon, r11 devient le plus grand

display_result:
    mov rdi, rax
    call int_to_str

    mov rax, 1
    mov rdi, 1
    mov rsi, result
    mov rdx, 64
    syscall

    mov rax, 60
    mov rdi, 0
    syscall

error:
    mov rax, 60
    mov rdi, 1
    syscall

str_to_int:
    mov rax, 0
    mov rbx, 0
next_digit:
    movzx rcx, byte [rdi]
    test rcx, rcx
    jz end_str_to_int
    sub rcx, '0'
    imul rax, rax, 10
    add rax, rcx
    inc rdi
    jmp next_digit
end_str_to_int:
    ret

int_to_str:
    mov rsi, result
    add rsi, 63
    mov byte [rsi], 0
    mov rdx, 0

convert_digit:
    mov rdx, 0
    mov rbx, rdi
    mov rcx, 10
    div rcx
    add dl, '0'
    dec rsi
    mov byte [rsi], dl
    test rax, rax
    jnz convert_digit
    ret