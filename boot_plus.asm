; =====================================================================
; PRÁCTICA PROGRAMACIÓN HARDWARE - UNIVERSIDAD DE JAÉN
; BOOTLOADER AMPLIADO (PROPUESTA PERSONAL)
; Funcionalidades: Rutina CALL, Prompt interactivo, Eco y Comando Clear
; =====================================================================

ORG 7C00h           ; Dirección de carga estándar de la BIOS [cite: 15, 200]

start:
    ; Configuración inicial
    CLI             ; Deshabilitar interrupciones durante el inicio [cite: 201]
    XOR AX, AX      ; Limpiar registros de segmento
    MOV DS, AX
    MOV ES, AX
    
    ; 1. Mostrar mensaje de bienvenida usando nuestra rutina CALL 
    MOV SI, msg_welcome
    CALL print_string

main_loop:
    ; 2. Mostrar el indicador de sistema (prompt) 
    MOV SI, prompt
    CALL print_string

input_loop:
    ; 3. Leer pulsación de teclado (Servicio BIOS 00h de INT 16h) [cite: 183]
    MOV AH, 00h
    INT 16h

    ; 4. Lógica de comandos
    CMP AL, 0Dh     ; ¿Es la tecla INTRO?
    JE next_line    ; Saltar de línea si es Intro

    CMP AL, 'c'     ; ¿Comando 'c' (minúscula)? 
    JE clear_screen
    CMP AL, 'C'     ; ¿Comando 'C' (mayúscula)? 
    JE clear_screen

    ; 5. Eco de teclado: Mostrar el carácter pulsado (Servicio 0Eh de INT 10h) [cite: 201]
    MOV AH, 0Eh
    INT 10h
    JMP input_loop

next_line:
    MOV SI, newline
    CALL print_string
    JMP main_loop   ; Reiniciar el bucle con un nuevo prompt

clear_screen:
    ; Función para borrar pantalla mediante reinicio de modo de vídeo 
    MOV AX, 0003h   ; Modo texto 80x25
    INT 10h
    JMP start       ; Volver al inicio para mostrar bienvenida de nuevo

; =====================================================================
; RUTINA: print_string
; Descripción: Imprime una cadena terminada en 0 (ASCIIZ) 
; Entrada: SI apunta a la cadena
; =====================================================================
print_string:
    MOV AH, 0Eh     ; Función teletipo de la BIOS [cite: 201]
.repeat:
    LODSB           ; Carga carácter en AL e incrementa SI [cite: 202]
    OR AL, AL       ; ¿Es el fin de la cadena (byte 0)? [cite: 202]
    JZ .done
    INT 10h         ; Llamada a vídeo BIOS [cite: 202]
    JMP .repeat
.done:
    RET             ; Retorno de la subrutina 

; =====================================================================
; DATOS Y FIRMA DE ARRANQUE
; =====================================================================
msg_welcome db "SISTEMA OPERATIVO PROG-HARD v2.0", 13, 10, "Comando: 'C' para borrar", 13, 10, 0
prompt      db "> ", 0
newline     db 13, 10, 0

times 510 - ($ - $$) db 0 ; Relleno de ceros hasta el byte 510 [cite: 15, 203]
dw 0xAA55                 ; Firma de arranque obligatoria (55 AA) [cite: 15, 203]
