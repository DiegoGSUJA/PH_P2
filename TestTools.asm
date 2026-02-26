ORG 100h            ; Formato .COM de DOS
MOV AL, 'X'         ; Carácter a escribir
MOV BL, 1fh         ; Atributo: blanco sobre azul
MOV CX, 2000        ; Cantidad de veces (llena la pantalla 80x25)
MOV AH, 9h          ; Función BIOS: escribir carácter/atributo
INT 10h             ; Llamada a la interrupción de vídeo
MOV AH, 4Ch         ; Función DOS: Salir al sistema
INT 21h             ; Llamada al DOS
