ORG 7C00h           ; La BIOS nos carga aquí 
CLI                 ; Desactiva interrupciones para estar tranquilos [cite: 201]

MOV SI, Prompt      ; Apuntamos al texto
MOV AH, 0eh         ; Función BIOS para imprimir carácter
loop:
    LODSB           ; Carga un carácter de [SI] en AL e incrementa SI [cite: 202]
    OR AL, AL       ; ¿Es el final de la cadena (0)?
    JZ exit         ; Si es 0, terminamos de imprimir
    INT 10h         ; Llamada a BIOS para pintar el carácter
    JMP loop
exit:
    HLT             ; Detiene la CPU [cite: 202]

Prompt: db "ProgHardSO 1.0", 13, 10, 0 ; El mensaje a mostrar [cite: 203]

times 510 - ($ - $$) db 0 ; Rellena con ceros hasta el byte 510 [cite: 203]
dw 0xAA55                 ; Firma obligatoria de arranque (bytes 511 y 512) [cite: 203]
