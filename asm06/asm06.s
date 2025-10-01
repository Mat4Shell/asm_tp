global _start

section .bss
    result resb 20          ; Buffer pour le résultat

section .data 
    newline db 10           ; Nouvelle ligne

section .text
_start:
    ; Charger les paramètres dans rsi (premier argument) et rdi (second argument)
    mov rsi, [rsp + 16]      ; Premier argument
    cmp rsi, 0
    je error

    mov rdi, [rsp + 24]      ; Deuxième argument
    cmp rdi, 0
    je error

    ; Initialiser les registres
    xor rax, rax             ; Effacer rax (pour le premier entier)
    xor rbx, rbx             ; Effacer rbx (pour le deuxième entier)
    xor rcx, rcx             ; Compteur pour les boucles
    xor r11, r11             ; Signe du premier nombre (0 = positif, 1 = négatif)
    xor r12, r12             ; Signe du deuxième nombre

; Convertir le premier argument en entier
convert_to_int:
    movzx r10, byte [rsi + rcx]  ; Charger le caractère actuel
    
    test r10, r10                ; Vérifier si c'est la fin de la chaîne
    jz second_arg
    cmp r10, 10
    je second_arg

    cmp r10, '-'                 ; Vérifier le signe '-'
    je negative_first_arg
   
    cmp r10, '0'
    jb is_letter
    cmp r10, '9'
    ja is_letter 

    sub r10, '0'                 ; Convertir ASCII en entier
    imul rax, rax, 10            ; Décaler à gauche
    add rax, r10                 ; Ajouter le chiffre converti
    inc rcx                      ; Passer au caractère suivant
    jmp convert_to_int

negative_first_arg:
    mov r11, 1                   ; Indiquer que le nombre est négatif
    inc rcx                      ; Passer au caractère suivant
    jmp convert_to_int

second_arg:
    ; Appliquer le signe du premier nombre
    test r11, r11                ; Vérifier le signe du premier nombre
    jz no_neg_first_arg
    neg rax                      ; Rendre le premier nombre négatif

no_neg_first_arg:
    mov rbx, rax                 ; Stocker le premier entier dans rbx
    xor rax, rax                 ; Réinitialiser rax pour le deuxième entier
    xor rcx, rcx                 ; Réinitialiser le compteur
    xor r10, r10                 ; Réinitialiser r10 pour le deuxième argument

; Convertir le deuxième argument en entier
convert_to_int2:
    movzx r10, byte [rdi + rcx]  ; Charger le caractère actuel
    test r10, r10                ; Vérifier si c'est la fin de la chaîne
    jz addition
    cmp r10, 10
    je addition

    cmp r10, '-'                 ; Vérifier le signe '-'
    je negative_second_arg

    cmp r10, '0'
    jb is_letter
    cmp r10, '9'
    ja is_letter 

    sub r10, '0'                 ; Convertir ASCII en entier
    imul rax, rax, 10            ; Décaler à gauche
    add rax, r10                 ; Ajouter le chiffre converti
    inc rcx                      ; Passer au caractère suivant
    jmp convert_to_int2

negative_second_arg:
    mov r12, 1                   ; Indiquer que le nombre est négatif
    inc rcx                      ; Passer au caractère suivant
    jmp convert_to_int2

addition:
    ; Appliquer le signe au deuxième nombre
    test r12, r12                ; Vérifier le signe du deuxième nombre
    jz no_neg_second_arg
    neg rax                      ; Rendre le deuxième nombre négatif

no_neg_second_arg:
    add rax, rbx                 ; Additionner les deux entiers

    ; Préparer pour convertir le résultat en chaîne
print_number:
    mov rbx, rax          ; rbx = valeur
    mov rcx, result + 20  ; pointeur fin buffer
    mov rsi, rcx          ; sauvegarde

    cmp rbx, 0
    jge .convert_digits

    ; nombre négatif → ajouter '-' en premier
    neg rbx               ; rbx = valeur absolue
    dec rcx
    mov byte [rcx], '-'   ; place '-' à gauche
    mov rsi, rcx          ; nouvelle position de départ

.convert_digits:
    cmp rbx, 0
    je .done

.loop:
    xor rdx, rdx
    mov rax, rbx
    mov r8, 10
    div r8                ; rax = quotient, rdx = reste
    add dl, '0'
    dec rcx
    mov [rcx], dl
    mov rbx, rax
    test rbx, rbx
    jnz .loop

.done:
    mov rdx, result + 20
    sub rdx, rcx          ; longueur réelle
    mov rsi, rcx          ; adresse de début
    mov rax, 1
    mov rdi, 1
    syscall

    ; Ajuster rsi pour pointer au début de la chaîne
    ; inc rsi

    ; Afficher la chaîne résultante
    mov rax, 1                   ; syscall: sys_write
    mov rdi, 1   
    lea rsi, [newline]                ; file descriptor: stdout
    mov rdx, 20                  ; Longueur de la chaîne
    syscall

exit:
    xor rax, rax
    xor rdi, rdi
    mov rax, 60                  ; syscall: sys_exit
    syscall

error:
    mov rax, 60
    mov rdi, 1                   ; Code d'erreur pour argument manquant
    syscall

is_letter:
    mov rax, 60
    mov rdi, 2                   ; Code d'erreur pour argument non valide
    syscall