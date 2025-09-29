section .data
    is_prime db 0  ; Variable pour stocker l'état de la primarité

section .bss
	num resb 6

section .text
    global _start

_start:
    ; Récupérer le nombre en entrée
    mov rax, 0          ; sys_read
    mov rdi, 0          ; file descriptor 0 (stdin)
    mov rsi, num        ; pointeur vers le buffer pour stocker le nombre
    mov rdx, 6          ; longueur maximale du nombre (6 chiffres)
    syscall

    ; Convertir le nombre en entrée en valeur entière
    mov rsi, num        ; pointeur vers la chaîne
    call atoi           ; convertir la chaîne en entier dans rax

    ; Vérifier si le nombre est premier
    mov rbx, 2          ; Initialise le diviseur à 2
check_divisor:
    mov rdx, 0          ; Réinitialise le registre de reste
    mov rdi, rax        ; Charge le nombre à tester
    div rbx             ; Divise rdi par rbx, le reste est dans rdx
    test rdx, rdx       ; Vérifie si le reste est nul
    jz not_prime        ; Si le reste est zéro, le nombre n'est pas premier

    inc rbx             ; Passe au diviseur suivant
    mov rsi, rax        ; Charge à nouveau le nombre à tester
    mov rdi, rbx        ; Charge le diviseur
    cmp rdi, rsi        ; Compare le diviseur avec le nombre
    jz prime            ; Si le diviseur est égal au nombre, le nombre est premier
    cmp rbx, rsi        ; Compare le diviseur avec le nombre
    jg prime            ; Si le diviseur est supérieur au nombre, le nombre est premier
    jmp check_divisor   ; Sinon, continue à chercher un diviseur

not_prime:
    mov byte [is_prime], 1  ; Indique que le nombre n'est pas premier
    jmp exit_program

prime:
    mov byte [is_prime], 0  ; Indique que le nombre est premier
    jmp exit_program

exit_program:
    ; Sortie du programme en affichant 0 si le nombre est premier, sinon 1
    mov rax, 1          ; sys_write
    mov rdi, 1          ; file descriptor 1 (stdout)
    mov rsi, is_prime   ; pointeur vers la variable is_prime
    mov rdx, 1          ; longueur du message (1 byte)
    syscall

    ; Terminer le programme
    mov rax, 60         ; sys_exit
    xor rdi, rdi        ; code de sortie 0 (succès)
    syscall

; Fonction pour convertir une chaîne de caractères en nombre entier
atoi:
    xor rax, rax        ; Initialise le résultat à zéro
next_digit:
    lodsb               ; Charge le prochain caractère dans al, et incrémente rsi
    test al, al         ; Vérifie si nous avons atteint la fin de la chaîne (caractère nul)
    jz done             ; Si oui, nous avons terminé
    sub al, '0'         ; Convertit le caractère ASCII en nombre
    imul rax, rax, 10   ; Multiplie le résultat précédent par 10
    add rax, rdi        ; Ajoute le nouveau chiffre au résultat
    jmp next_digit      ; Traite le prochain chiffre
done:
    ret
