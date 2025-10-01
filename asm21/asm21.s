; asm21.asm - shellcode loader & generator
; Usage:
;   ./asm21 "\x48\x31\xff\x40\xb7\x2a\x48\x31\xc0\xb0\x3c\x0f\x05"
;     -> the program will parse the \xHH bytes, mmap RWX memory, copy and execute them
;
;   ./asm21 Hello
;     -> the program will generate a small shellcode that does write(1, "Hello", 5); exit(0)
;        then it prints that shellcode as an escaped string "\x.."
;
; Assemble & link:
;   nasm -f elf64 asm21.asm -o asm21.o
;   ld asm21.o -o asm21

%define SYS_READ    0
%define SYS_WRITE   1
%define SYS_MMAP    9
%define SYS_EXIT    60

section .bss
    srcbuf   resb 512        ; temporary buffers
    shellbuf resb 4096       ; buffer for parsed/generated shellcode
    outbuf   resb 8192       ; output for escaped string

section .text
    global _start

_start:
    ; argc in [rsp], argv at [rsp+8]...
    mov rdx, [rsp]           ; rdx = argc
    cmp rdx, 2
    jl .no_arg               ; no argument -> exit(1)

    mov rsi, [rsp+16]        ; rsi -> argv[1]
    ; check if first two characters are '\' 'x' -> execution mode
    mov al, byte [rsi]       ; al = first char
    cmp al, '\'
    jne .generate_mode
    mov al, byte [rsi+1]
    cmp al, 'x'
    jne .generate_mode

    ; -----------------------------
    ; Execution mode: parse \xHH sequences into shellbuf
    ; -----------------------------
    xor rcx, rcx             ; rcx = index in arg string
    xor r8, r8               ; r8 = shellbuf length counter

.parse_loop:
    mov bl, byte [rsi + rcx]
    test bl, bl
    jz .parse_done
    cmp bl, '\'
    jne .skip_char
    ; expect "\x"
    cmp byte [rsi + rcx + 1], 'x'
    jne .bad_input
    ; read two hex digits after \x
    mov dl, byte [rsi + rcx + 2]
    call .hex2nibble
    jc .bad_input
    mov dh, al               ; high nibble in dh (we returned value in al)

    mov dl, byte [rsi + rcx + 3]
    call .hex2nibble
    jc .bad_input
    ; combine dh (high) and al (low) -> byte
    shl dh, 4
    or  dh, al
    mov byte [shellbuf + r8], dl
    inc r8
    add rcx, 4
    jmp .parse_loop

.skip_char:
    inc rcx
    jmp .parse_loop

.parse_done:
    ; r8 = number of bytes parsed
    cmp r8, 0
    je .bad_input

    ; allocate RWX memory via mmap
    mov rax, SYS_MMAP
    xor rdi, rdi             ; addr = 0
    mov rsi, r8              ; length = parsed size
    mov rdx, 7               ; prot = PROT_READ | PROT_WRITE | PROT_EXEC = 7
    mov r10, 0x22            ; flags = MAP_PRIVATE | MAP_ANONYMOUS = 0x22
    mov r8, -1               ; fd = -1
    xor r9, r9               ; offset = 0
    syscall
    ; rax = mapped address or -1 on error
    cmp rax, -4095
    jae .mmap_fail

    ; copy shellbuf -> mapped area (rax)
    mov rdi, rax             ; destination
    lea rsi, [shellbuf]      ; source
    mov rcx, r8              ; count bytes
    cld
    rep movsb

    ; jump to shellcode
    ; use call rax to allow return if shellcode returns (but many don't)
    ; ensure proper stack alignment could be required by the shellcode; we trust user shellcode.
    jmp rax

.mmap_fail:
    ; exit(1)
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall

; -----------------------------
; Generation mode: create shellcode for write(1, msg, len); exit(0)
; Template bytes (with placeholders for disp32 and len32):
;  xor rax, rax                  48 31 c0
;  mov rax, 1                    48 c7 c0 01 00 00 00
;  mov rdi, 1                    48 c7 c7 01 00 00 00
;  lea rsi,[rip + disp32]        48 8d 35 xx xx xx xx    ; xx = disp32 to msg from next instr
;  mov rdx, len32                48 c7 c2 LL LL LL LL
;  syscall                       0f 05
;  mov rax,60                    48 c7 c0 3c 00 00 00
;  xor rdi,rdi                   48 31 ff
;  syscall                       0f 05
;  <msg bytes…>
; -----------------------------
.generate_mode:
    ; compute message length
    mov rdi, rsi              ; rdi = argv[1] pointer
    xor rcx, rcx
.find_len:
    mov al, byte [rdi + rcx]
    test al, al
    jz .have_len
    inc rcx
    jmp .find_len
.have_len:
    mov r9, rcx               ; r9 = msg_len

    ; build shellcode into shellbuf
    lea rbx, [shellbuf]
    mov r10, 0

    ; helper: write bytes to shellbuf using mov byte [rbx + idx], imm
    ; We'll fill bytes step by step.

    ; 1) xor rax, rax   (3 bytes) -> 48 31 c0
    mov byte [rbx + r10], 0x48
    inc r10
    mov byte [rbx + r10], 0x31
    inc r10
    mov byte [rbx + r10], 0xc0
    inc r10

    ; 2) mov rax,1 -> 48 c7 c0 01 00 00 00
    mov byte [rbx + r10], 0x48
    inc r10
    mov byte [rbx + r10], 0xc7
    inc r10
    mov byte [rbx + r10], 0xc0
    inc r10
    mov dword [rbx + r10], 1
    add r10, 4

    ; 3) mov rdi,1 -> 48 c7 c7 01 00 00 00
    mov byte [rbx + r10], 0x48
    inc r10
    mov byte [rbx + r10], 0xc7
    inc r10
    mov byte [rbx + r10], 0xc7
    inc r10
    mov dword [rbx + r10], 1
    add r10, 4

    ; 4) lea rsi,[rip + disp32] -> 48 8d 35 xx xx xx xx
    mov byte [rbx + r10], 0x48
    inc r10
    mov byte [rbx + r10], 0x8d
    inc r10
    mov byte [rbx + r10], 0x35
    inc r10
    ; placeholder for disp32 (4 bytes)
    mov dword [rbx + r10], 0
    ; remember where disp32 is to patch later
    mov r12, r10              ; r12 = offset of disp32 within shellbuf
    add r10, 4

    ; 5) mov rdx, len32 -> 48 c7 c2 LL LL LL LL
    mov byte [rbx + r10], 0x48
    inc r10
    mov byte [rbx + r10], 0xc7
    inc r10
    mov byte [rbx + r10], 0xc2
    inc r10
    mov dword [rbx + r10], 0   ; placeholder for len32
    mov r13, r10              ; r13 = offset of len32
    add r10, 4

    ; 6) syscall 0f 05
    mov byte [rbx + r10], 0x0f
    inc r10
    mov byte [rbx + r10], 0x05
    inc r10

    ; 7) mov rax,60 -> 48 c7 c0 3c 00 00 00
    mov byte [rbx + r10], 0x48
    inc r10
    mov byte [rbx + r10], 0xc7
    inc r10
    mov byte [rbx + r10], 0xc0
    inc r10
    mov dword [rbx + r10], 60
    add r10, 4

    ; 8) xor rdi, rdi -> 48 31 ff
    mov byte [rbx + r10], 0x48
    inc r10
    mov byte [rbx + r10], 0x31
    inc r10
    mov byte [rbx + r10], 0xff
    inc r10

    ; 9) syscall 0f 05
    mov byte [rbx + r10], 0x0f
    inc r10
    mov byte [rbx + r10], 0x05
    inc r10

    ; Now append message bytes (no terminating zero)
    mov r14, r10              ; r14 = offset where message starts in shellbuf
    mov r15, 0
.copy_msg:
    cmp r15, r9
    jae .msg_copied
    mov al, byte [rsi + r15]
    mov byte [rbx + r10], al
    inc r10
    inc r15
    jmp .copy_msg
.msg_copied:

    ; patch disp32 (for lea rsi,[rip+disp])
    ; lea is at offset (r12 - 3) : instruction start is (r12 - 3)
    ; the rip after lea is at instr_end = instr_start + 7 -> (r12 - 3) + 7 = r12 + 4
    ; disp = (msg_offset) - instr_end
    ; msg_offset = r14
    ; instr_end = r12 + 4
    ; disp32 = r14 - (r12 + 4)
    ; compute disp32 = r14 - r12 - 4
    mov rax, r14
    sub rax, r12
    sub rax, 4
    mov dword [rbx + r12], eax

    ; patch len32 at r13
    mov eax, edi
    ; we stored msg_len in r9
    mov eax, dword r9         ; careful: r9 may be 64-bit; take lower 32 bits
    mov dword [rbx + r13], eax

    ; total shellcode length is r10
    mov rcx, r10              ; rcx = shellcode length

    ; produce escaped output into outbuf as "\xHH" for each byte
    lea rsi, [shellbuf]
    lea rdi, [outbuf]
    xor r8, r8                ; out index
    xor rbx, rbx              ; i = 0

.output_loop:
    cmp rbx, rcx
    jge .output_done
    mov al, byte [rsi + rbx]
    ; high nibble
    mov ah, al
    shr ah, 4
    call .nibble_to_hex_chars  ; returns two ascii hex chars in dl (low) and dh (high)? we'll implement simply
    ; simpler approach: compute both nibbles and write '\', 'x', hi, lo
    ; write '\' 'x' hi lo
    mov byte [rdi + r8], '\'
    inc r8
    mov byte [rdi + r8], 'x'
    inc r8
    ; high nibble
    mov al, byte [rsi + rbx]
    shr al, 4
    call .hex_to_ascii_store      ; returns char in al -> store
    mov byte [rdi + r8], al
    inc r8
    ; low nibble
    mov al, byte [rsi + rbx]
    and al, 0x0F
    call .hex_to_ascii_store
    mov byte [rdi + r8], al
    inc r8

    inc rbx
    jmp .output_loop

.output_done:
    ; write outbuf[0..r8) to stdout
    mov rax, SYS_WRITE
    mov rdi, 1
    lea rsi, [outbuf]
    mov rdx, r8
    syscall

    ; exit(0)
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

; -----------------------------
; helpers
; -----------------------------
; hex2nibble: convert ASCII hex char in DL (input) to numeric 0..15
; returns value in AL, clear CF on success, set CF on invalid char
; clobbers AH
.hex2nibble:
    push rax
    mov al, dl
    cmp al, '0'
    jb .hbad
    cmp al, '9'
    jle .hnum
    cmp al, 'a'
    jb .Hup
    cmp al, 'f'
    jle .hlow
    cmp al, 'A'
    jb .hbad
    cmp al, 'F'
    ja .hbad
.Hup:
    sub al, 'A'
    add al, 10
    jmp .hdone
.hlow:
    sub al, 'a'
    add al, 10
    jmp .hdone
.hnum:
    sub al, '0'
    jmp .hdone
.hbad:
    pop rax
    stc                     ; set carry to signal error
    ret
.hdone:
    clc
    pop rax
    ret

; convert nibble in AL to ascii hex in AL (0..15 -> '0'..'9','a'..'f')
.hex_to_ascii_store:
    cmp al, 10
    jl .he0
    add al, 'a' - 10
    ret
.he0:
    add al, '0'
    ret

.bad_input:
    ; exit(2)
    mov rax, SYS_EXIT
    mov rdi, 2
    syscall

.no_arg:
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall
