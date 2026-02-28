[org 0x7e00]
CLI

MOV AX, 0013h
INT 10h

; Cargar tabla de segmentos
LGDT [gdt_desc]

; Activar flag de modo protegido
MOV EAX, CR0
OR EAX, 1
MOV CR0, EAX

; Salto largo para entrar en 32bits
JMP 0x08:in_pm

[BITS 32]
in_pm:
    CALL clear
    MOV EBX, 0
    MOV ECX, 0
    MOV AH, 50
    MOV AL, 50
    CALL pintar_cuadrado
    JMP $                  


clear:
    MOV EDI, 0xA0000        ; Dirección base de la memoria de video VGA
    MOV AL, 0x00            ; Índice de color (0 = Negro en la paleta estándar)
    MOV ECX, 320 * 200      ; 64,000 bytes totales
    REP STOSB               ; Escribe AL en cada byte desde EDI
    RET
    
; Pinta pixel: X(EBX), Y(ECX)
pintar_pixel:
    PUSH EAX
    PUSH ECX
    PUSH EDI
    
    MOV EDI, 0xA0000
    IMUL EAX, ECX, 320      ; EAX = Y * 320 (No destruimos ECX)
    ADD EAX, EBX            ; EAX = (Y * 320) + X
    MOV BYTE [EDI + EAX], 0x0C
    
    POP EDI
    POP ECX
    POP EAX
    RET

; Pinta cuadrado con parametros
; Posicion: EBX (X), ECX (Y)
; Tamaño: AH (Alto), AL (Ancho)
pintar_cuadrado:
    PUSH EAX            ; Guardamos dimensiones
    PUSH EBX            ; Guardamos X inicial para resetearlo en cada fila
    MOVZX EDX, AL       ; EDX = Ancho (usamos registro limpio para el contador)
    MOVZX ESI, AH       ; ESI = Alto

.fila:
    PUSH EDX            ; Guardamos contador de ancho para la fila actual
    PUSH EBX            ; Guardamos X actual
.columna:
    CALL pintar_pixel
    INC EBX             ; Siguiente pixel en X
    DEC EDX
    JNZ .columna

    POP EBX             ; Restauramos X al inicio de la fila
    POP EDX             ; Restauramos contador de ancho
    INC ECX             ; Siguiente fila en Y
    DEC ESI             ; Decrementamos contador de alto
    JNZ .fila

    POP EBX
    POP EAX
    RET
 

gdt_start:
    dq 0x0                  ; Null descriptor
    dw 0xffff, 0x0000, 0x9a00, 0x00cf ; Code segment (0x08)
    dw 0xffff, 0x0000, 0x9200, 0x00cf ; Data segment (0x10)
gdt_end:
gdt_desc:
    dw gdt_end - gdt_start - 1
    dd gdt_start

times 512 db 0
