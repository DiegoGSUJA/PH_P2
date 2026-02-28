ORG 7C00h ; Dirección donde la BIOS carga el código
CLI ; Ignorar las interrupciones
help:
MOV SI, Prompt
CALL print_string
start:
    CALL start_command
    CALL borrar_buffer
    MOV DI, buffer

loop:
    MOV AH,0
    INT 16h

    ; Teclas especiales
    CMP AH,1
    JZ exit
    CMP AH,1Ch
    JZ enter
    CMP AH, 0Eh
    JZ retorno

    ; Almacenamos en el buffer
    STOSB 

    ; Mostramos caracter y avanzamos cursor
    MOV AH,0eh
    MOV CX,1
    INT 10h

    JMP loop

; Imprime el comienzo de la orden
start_command:
    MOV SI,shell
    CALL print_string
    RET 
    
; Evento cuando se pulsa retorno. Borramos caracter
retorno:
    ; Si DI no ha avanzado no hacemos nada
    CMP DI, buffer
    JE loop
    
    ; Retrocedemos un byte en DI y ponemos a 0
    DEC DI
    MOV BYTE [DI], 0

    ; Retrocedemos cursor
    MOV AH, 0Eh          
    MOV AL, 08h
    INT 10h
    ; Imprimimos un espacio para eliminar el anterior caracter
    MOV AL, ' ' 
    INT 10h
    ; Volvemos a retroceder
    MOV AL, 08h
    INT 10h
    
    JMP loop  

; Evento cuando se pulsa la tecla enter. Busca la instrucción
enter:
    MOV AL,0
    STOSB   

    MOV SI, salto_linea
    CALL print_string

    MOV DI, cmd_4
    CALL cmp_string
    JC help

    MOV DI, cmd_1
    CALL cmp_string
    JC clear

    MOV DI, cmd_2
    CALL cmp_string
    JC cpu_cmd

    MOV DI, cmd_3
    CALL cmp_string
    JC mem

    MOV DI, cmd_5
    CALL cmp_string
    JC bootjmp

    CALL error

; Imprime un mensaje de error y vueve a empezar el bucle
error:
    MOV SI, error_msg
    CALL print_string
    JMP start

; Imprime string apuntado por SI
print_string:
    MOV AH, 0eh
    ; Cargamos caracter [SI] en AL
    LODSB
    ; Si es caracter nulo terminamos
    OR AL, AL
    JZ .done
    ; Imprimios caracter
    INT 10h
    JMP print_string
.done:
    RET

; compara string introducido con almacenado en memoria apuntado por DI
cmp_string:
    MOV SI, buffer
.cmp_loop:
    ; Cargo en AL el caracter n de buffer
    LODSB
    ; Comaparo con AL el apuntado por DI
    SCASB
    ; Si AL != [DI] salimos y ponemos la flag de carro en 0
    JNE .no_igual
    ; Si AL == 0 salimos y ponemos la flag de carro en 1
    OR AL,AL
    JNE .cmp_loop

    STC
    RET
.no_igual:
    CLC
    RET

; Borra el buffer
borrar_buffer:
    MOV BYTE [buffer], 0
    RET

; Limpiar pantalla
clear:
    ; Limpia la pantalla
    MOV AH, 06h
    MOV AL, 0
    MOV BH, 07h
    MOV CX, 0
    MOV DH, 18h
    MOV DL, 4Fh
    INT 10h

    ; Mueve el cursor
    MOV AH, 02h
    MOV DX, 0
    MOV BH, 0
    INT 10h
    JMP start

; Imprime cpu
cpu_cmd:
    ; Pide la informacion de la cpu
    MOV EAX, 0
    CPUID
   
    ; La información que devuelve se almacena en EBX, EDX y ECX, entoces
    ; la metemos en el buffer para despues poder imprimirla
    MOV [buffer], EBX
    MOV [buffer + 4], EDX
    MOV [buffer + 8], ECX
    MOV BYTE [buffer + 12], 0

    ; Mostramos la información
    MOV SI, buffer
    CALL print_string
    MOV SI, salto_linea
    CALL print_string

    JMP start

; Imprime memoria ram disponible
mem:
    ; Pedimos la informacion que se almacenara en AX
    INT 12h
    ; Preparamos los registros para operar
    MOV BX, 10         
    XOR CX, CX        

; dividimos hasta que no queden unidades y vamos almacenando el resto, en este
; caso la unidad, en la pila hasta tener cociente 0
.dividir:
    XOR DX, DX
    DIV BX
    PUSH DX
    INC CX
    TEST AX, AX
    JNZ .dividir
; Vamos imprimiendo las unidades que hemos almacenado en la pila
.mostrar:
    POP AX     
    ADD AL, '0'
    MOV AH, 0Eh
    INT 10h   
    LOOP .mostrar
    
    ; Muestra la unidad
    MOV SI, mem_unit
    CALL print_string
    JMP start

bootjmp:
    MOV [BOOT_DRIVE], DL

; Configurar segmento de destino para la Etapa 2 (0x0000:0x7e00)
    MOV AX, 0
    MOV ES, AX
    MOV BX, 0x7E00

; Leer sector 2 del disco
    MOV AH, 0x02
    MOV AL, 1
    MOV CH, 0
    MOV DH, 0
    MOV CL, 2
    MOV DL, [BOOT_DRIVE]
    INT 0x13     

    JC .disk_error
    
    JMP 0x7E00

.disk_error:
    MOV AH, 0x0E
    MOV AL, 'E'
    INT 0x10
    JMP $

exit:
    HLT



BOOT_DRIVE: db 0
Prompt: db "Bootloader - Gabriel Soria y Diego Gomez", 13, 10,
        db "Comandos: help, clear, cpu, mem, pong", 13, 10, 0
shell: db "$> ",0
salto_linea: db 13, 10, 0
error_msg: db "ERROR: Ese comando no existe",13,10,0
mem_unit: db " KB",13,10,0
cmd_1: db "clear",0
cmd_2: db "cpu",0
cmd_3: db "mem",0
cmd_4: db "help",0
cmd_5: db "pong",0


times 510 - ($ - $$) db 0 ; Rellenar con ceros
dw 0xAA55 ; hasta los dos últimos bytes, firma bootloader


section .bss
buffer: RESB 16
