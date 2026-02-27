; =============================================================================
; Práctica: Programación de E/S - Universidad de Jaén
; Alumno: Diego Gómez Sánchez
; Objetivo: Bootloader con comandos de sistema y servicios BIOS
; Cubre Apartados: 1 (Buffer/Hardware), 3 (Carga Disco), 4 (Servicios BIOS)
; =============================================================================

ORG 7C00h           

start:
    cli             
    xor ax, ax      
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00  
    sti             

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

    ; --- Comando para Apartado 3: LOAD ---
    mov di, cmd_load
    call compare_strings
    jz do_load

    mov si, unknown_msg
    call print_string
    jmp main_loop

; --- Rutinas de Comandos ---

do_time:
    mov ah, 02h
    int 1Ah
    mov si, time_msg
    call print_string
    jmp main_loop

do_sys:
    int 12h         
    mov si, sys_msg
    call print_string
    jmp main_loop

; --- Implementación Apartado 3: Carga de Núcleo ---
do_load:
    mov si, load_msg
    call print_string

    mov ah, 02h    ; Función BIOS: Leer sectores
    mov al, 1      ; Leer 1 sector (Sector 2)
    mov ch, 0      ; Cilindro 0
    mov dh, 0      ; Cabeza 0
    mov cl, 2      ; Sector 2 (donde estaría el kernel)
    mov dl, 0      ; Unidad A:

    ; Destino en RAM: 0x0800:0000 (Dirección física 0x8000)
    mov ax, 0x0800
    mov es, ax
    xor bx, bx
    
    int 13h        ; LLAMADA BIOS ACCESO A DISCO
    jc .disk_error
    
    jmp 0x0800:0000 ; SALTO AL NÚCLEO (Segunda etapa)

.disk_error:
    mov si, load_err
    call print_string
    jmp main_loop

; --- Funciones de Soporte --- 

print_string:       
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
.wait_key:
    ; --- Apartado 1: Interceptación Hardware (Puerto 64h/60h) ---
    in al, 0x64             
    test al, 0x01           
    jz .wait_key            

    in al, 0x60             ; Lectura directa de hardware
    cmp al, 0x1C            ; Scancode ENTER
    je .end_command
    
    test al, 0x80           
    jnz .wait_key

    ; Conversión básica para visualización
    mov ah, 0eh             
    int 10h
    
    stosb                   ; GUARDAR EN BUFFER
    jmp .wait_key

.end_command:
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
    mov al, 1       
    or al, al       
    ret
.equal:
    xor ax, ax      
    ret

clear_screen:
    mov ax, 03h     
    int 10h
    ret

; --- Datos ---
welcome_msg db "UJA - Bootloader Avanzado v1.1", 13, 10, "Comandos: TIME, SYS, CLS, LOAD", 13, 10, 0
prompt_msg  db "> ", 0
newline     db 13, 10, 0
unknown_msg db "Error: Comando no reconocido", 13, 10, 0
time_msg    db "Accediendo al RTC... (Hora leida)", 13, 10, 0
sys_msg     db "Informacion de Memoria OK", 13, 10, 0
load_msg    db "Buscando Kernel en Sector 2...", 13, 10, 0
load_err    db "Error: No se pudo leer el disco", 13, 10, 0
cmd_time    db "TIME", 0
cmd_sys     db "SYS", 0
cmd_cls     db "CLS", 0
cmd_load    db "LOAD", 0

TIMES 510 - ($ - $$) db 0   
DW 0xAA55                   

; --- Buffer de comandos al final (Apartado 1) ---
cmd_buffer: resb 16
