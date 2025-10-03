; asm15.asm
; ELF x64 binary detection
; Usage: ./asm15 file

section .bss
    header resb 5          ; buffer pour les 5 premiers octets

section .text
    global _start

_start:
    ; Vérifier argc
    mov rbx, [rsp]         ; argc
    cmp rbx, 2
    jl .no_param

    ; argv[1]
    mov rsi, [rsp + 16]

    ; open(file, O_RDONLY)
    mov rax, 2             ; sys_open
    mov rdi, rsi
    xor rsi, rsi           ; flags = O_RDONLY
    xor rdx, rdx           ; mode (inutile ici)
    syscall
    cmp rax, 0
    jl .error_open

    ; rax = fd
    mov rdi, rax
    mov rax, 0             ; sys_read
    mov rsi, header
    mov rdx, 5
    syscall
    cmp rax, 5             ; a-t-on lu 5 octets ?
    jne .not_elf

    ; Vérifier la signature ELF64
    mov al, [header]
    cmp al, 0x7F
    jne .not_elf
    mov al, [header+1]
    cmp al, 'E'
    jne .not_elf
    mov al, [header+2]
    cmp al, 'L'
    jne .not_elf
    mov al, [header+3]
    cmp al, 'F'
    jne .not_elf
    mov al, [header+4]
    cmp al, 2              ; Classe = 2 → 64-bit
    jne .not_elf

    ; C'est bien un ELF x64
    mov rax, 60
    xor rdi, rdi           ; exit(0)
    syscall

.not_elf:
    mov rax, 60
    mov rdi, 1             ; exit(1)
    syscall

.no_param:
    mov rax, 60
    mov rdi, 1             ; exit(2)
    syscall

.error_open:
    mov rax, 60
    mov rdi, 1             ; exit(3)
    syscall
