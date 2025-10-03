; asm16.asm
; Binary patcher: remplace "1337" par "H4CK" dans le fichier donné en argument
; Usage:
;   nasm -f elf64 asm16.asm -o asm16.o
;   ld asm16.o -o asm16
;   ./asm16 asm01
; Après patch, ./asm01 devrait afficher "H4CK" au lieu de "1337"
;
; Exit codes:
;  0 -> patch réussi
;  1 -> param manquant / pattern non trouvé / fichier trop petit
;  2 -> open échoué
;  3 -> mmap / autre erreur (conservateur)
;
; Notes:
;  - recherche binaire sur 4 octets (little-endian)
;  - "1337" => bytes 0x31 0x33 0x33 0x37 => dword LE 0x37333331
;  - "H4CK" => bytes 0x48 0x34 0x43 0x4B => dword LE 0x4B433448

section .text
    global _start

_start:
    ; vérifier argc
    mov rax, [rsp]         ; argc
    cmp rax, 2
    jl .no_param

    ; argv[1]
    mov rdi, [rsp + 16]    ; rdi = pointer filename

    ; open(filename, O_RDWR)
    mov rax, 2             ; sys_open
    mov rsi, 2             ; flags = O_RDWR
    xor rdx, rdx           ; mode not needed
    syscall
    cmp rax, 0
    jl .open_failed
    mov r12, rax           ; r12 = fd

    ; lseek(fd, 0, SEEK_END) -> get file size
    mov rax, 8             ; sys_lseek
    mov rdi, r12           ; fd
    xor rsi, rsi           ; offset = 0
    mov rdx, 2             ; SEEK_END
    syscall
    cmp rax, 4
    jb .too_small          ; size < 4 -> impossible de contenir "1337"
    mov r13, rax           ; r13 = size

    ; mmap(NULL, size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0)
    mov rax, 9             ; sys_mmap
    xor rdi, rdi           ; addr = NULL
    mov rsi, r13           ; length = size
    mov rdx, 3             ; prot = PROT_READ|PROT_WRITE (1|2)
    mov r10, 1             ; flags = MAP_SHARED
    mov r8, r12            ; fd
    xor r9, r9             ; offset = 0
    syscall
    ; check for error: mmap returns -errno in rax if <0 and > -4096
    cmp rax, 0
    jl .mmap_failed
    mov rbx, rax           ; rbx = mapped address (base pointer)

    ; prepare search bounds
    mov rcx, 0             ; index = 0
    mov rdx, r13           ; rdx = size
    sub rdx, 4             ; last index to check (inclusive)
    ; value to search: "1337" as little-endian dword = 0x37333331
    mov r9d, 0x37333331

.search_loop:
    cmp rcx, rdx
    ja  .not_found         ; ran past end (no match)

    ; load 4 bytes at mapped + rcx into eax
    mov eax, dword [rbx + rcx]
    cmp eax, r9d
    jne .next_i

    ; match found -> write "H4CK" dword little-endian = 0x4B433448
    mov dword [rbx + rcx], 0x4B433448

    ; optionally msync could be called, but MAP_SHARED write suffices in most cases
    ; success -> exit 0
    mov rax, 60
    xor rdi, rdi
    syscall

.next_i:
    inc rcx
    jmp .search_loop

; ---------- error paths ----------
.not_found:
    ; pattern not found
    mov rax, 60
    mov rdi, 1
    syscall

.too_small:
    mov rax, 60
    mov rdi, 1
    syscall

.open_failed:
    mov rax, 60
    mov rdi, 1
    syscall

.mmap_failed:
    mov rax, 60
    mov rdi, 1
    syscall

.no_param:
    mov rax, 60
    mov rdi, 1
    syscall
