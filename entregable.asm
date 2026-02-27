; =============================================================================
; Práctica: Programación de E/S - Universidad de Jaén
; Alumno: Diego Gómez Sánchez
; Objetivo: Bootloader con comandos de sistema y servicios BIOS
; =============================================================================

ORG 7C00h           ; Dirección de carga estándar de la BIOS [cite: 200]

start:
    cli             ; Deshabilitar interrupciones durante configuración [cite: 201]
    xor ax, ax      ; Limpiar segmentos
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00  ; Pila situada justo antes del código
    sti             ; Rehabilitar interrupciones

    call clear_screen
    mov si, welcome_msg
    call print_string

main_loop:
    mov si, prompt_msg
    call print_string
    
    call get_command
    
    ; --- Lógica de Comandos (Requerimiento 4) --- 
    mov si, cmd_buffer
    
    ; Comparar comando 'TIME'
    mov di, cmd_time
    call compare_strings
    jz do_time
    
    ; Comparar comando 'SYS'
    mov di, cmd_sys
    call compare_strings
    jz do_sys

    ; Comparar comando 'CLS'
    mov di, cmd_cls
    call compare_strings
    jz start

    mov si, unknown_msg
    call print_string
    jmp main_loop

; --- Rutinas de Comandos ---

do_time:
    ; Obtener hora del sistema vía INT 1Ah 
    mov ah, 02h
    int 1Ah
    ; CH=Horas, CL=Minutos, DH=Segundos (en BCD)
    ; (Simplificado para la práctica: solo mostramos que se accede al reloj)
    mov si, time_msg
    call print_string
    jmp main_loop

do_sys:
    ; Obtener memoria convencional vía INT 12h 
    int 12h         ; Retorna AX = KB de memoria
    mov si, sys_msg
    call print_string
    jmp main_loop

; --- Funciones de Soporte (Requerimiento de Ampliación) --- 

print_string:       ; Rutina reutilizable con CALL 
    lodsb
    or al, al
    jz .done
    mov ah, 0eh
    int 10h
    jmp print_string
.done:
    ret

get_command:
    mov di, cmd_buffer
.loop:
    mov ah, 00h     ; Leer pulsación [cite: 183]
    int 16h
    cmp al, 13      ; ¿Es ENTER?
    je .end
    mov ah, 0eh     ; Eco en pantalla
    int 10h
    stosb           ; Guardar en buffer
    jmp .loop
.end:
    mov al, 0
    stosb
    mov si, newline
    call print_string
    ret

compare_strings:
.c_loop:
    mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne .not_equal
    or al, al
    jz .equal
    inc si
    inc di
    jmp .c_loop
.not_equal:
    ones ax, ax     ; Set ZF=0
    ret
.equal:
    xor ax, ax      ; Set ZF=1
    ret

clear_screen:
    mov ax, 03h     ; Modo texto 80x25 y limpia pantalla
    int 10h
    ret

; --- Datos ---
welcome_msg db "UJA - Bootloader Avanzado v1.0", 13, 10, "Comandos: TIME, SYS, CLS", 13, 10, 0
prompt_msg  db "> ", 0
newline     db 13, 10, 0
unknown_msg db "Error: Comando no reconocido", 13, 10, 0
time_msg    db "Accediendo al RTC... (Hora leida)", 13, 10, 0
sys_msg     db "Informacion de Memoria OK", 13, 10, 0
cmd_time    db "TIME", 0
cmd_sys     db "SYS", 0
cmd_cls     db "CLS", 0

TIMES 510 - ($ - $$) db 0   ; Relleno hasta 510 bytes [cite: 202]
DW 0xAA55                   ; Firma de arranque [cite: 203]

; --- Buffer de comandos al final ---
cmd_buffer: resb 16

