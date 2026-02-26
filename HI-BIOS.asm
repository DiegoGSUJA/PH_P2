ORG 100h            ; Formato .COM

loop:
    MOV AH, 0       ; Servicio BIOS: Leer pulsación de tecla
    INT 16h         ; Llama a la interrupción de teclado 

    CMP AL, 27      ; ¿Es la tecla ESC (código ASCII 27)? 
    JZ exit         ; Si es ESC, salimos del bucle 

    MOV AH, 0ah     ; Servicio BIOS: Mostrar carácter en pantalla 
    MOV CX, 1       ; Escribir el carácter 1 vez 
    INT 10h         ; Llama a la interrupción de vídeo 

    JMP loop        ; Repetir para la siguiente tecla 

exit:
    MOV AH, 4Ch     ; Servicio DOS: Finalizar programa 
    INT 21h         ; Volver al terminal
