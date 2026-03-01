[ORG 0x7E00]
[BITS 16]

inicio_real:
    CLI

    ; Entramos en modo video
    MOV AX, 0x0013
    INT 0x10

    ; Cargamos la GDT definida
    LGDT [gdt_desc]

    ; Ponemos a 1 el bit para activar el modo protegido en el registro de control
    MOV EAX, CR0
    OR EAX, 1
    MOV CR0, EAX

    ; Damos un salto largo para limpiar la cola de ejecucion y actualizar
    ; el registro CS
    JMP 0x08:in_pm_32

; -----------------------------------------------------------------------------
[BITS 32]
in_pm_32:
    ; Movemos los punteros a la region configurada por el GDT
    MOV AX, 0x10
    MOV DS, AX
    MOV ES, AX
    MOV FS, AX
    MOV GS, AX
    MOV SS, AX
    MOV ESP, 0x90000

    ; CONFIGURAR IDT (TECLADO)
    MOV EAX, irq1_keyboard_handler
    MOV EDI, idt_start + (33 * 8)
    MOV WORD [EDI], AX
    MOV WORD [EDI + 2], 0x08
    MOV BYTE [EDI + 4], 0x00
    MOV BYTE [EDI + 5], 0x8E
    SHR EAX, 16
    MOV WORD [EDI + 6], AX

    CALL remap_pic
    LIDT [idt_descriptor]
    STI

bucle_principal:
    CALL wait_vblank       
    
    ; Espera ocupada para realentizar la ejecución
    INC WORD [frame_count]
    CMP WORD [frame_count], 10000
    JL .no_dibujar
    MOV WORD [frame_count], 0

    MOV BYTE [color], 0x00
    CALL pintar_escena
    ; --- MOVIMIENTO JUGADOR 1 ---
    MOV ECX, [j1_y]
    CMP BYTE [teclas_estado + 0x11], 1 ; W
    JNE .check_s
    CMP ECX, 0
    JLE .check_s
    SUB ECX, VEL_PALA
    CMP ECX, 0
    JGE .no_negative_j1
    XOR ECX, ECX

.no_negative_j1:
.check_s:
    CMP BYTE [teclas_estado + 0x1F], 1 ; S
    JNE .update_j1
    CMP ECX, 170 << 8
    JGE .update_j1
    ADD ECX, VEL_PALA
.update_j1:
    MOV [j1_y], ECX

    ; --- MOVIMIENTO JUGADOR 2 ---
    MOV ECX, [j2_y]
    CMP BYTE [teclas_estado + 0x48], 1 ; Arriba
    JNE .check_down
    CMP ECX, 0
    JLE .check_down
    SUB ECX, VEL_PALA
    CMP ECX, 0
    JGE .no_negative_j2
    XOR ECX, ECX

.no_negative_j2:
.check_down:
    CMP BYTE [teclas_estado + 0x50], 1 ; Abajo
    JNE .update_j2
    CMP ECX, 170 << 8
    JGE .update_j2
    ADD ECX, VEL_PALA
.update_j2:
    MOV [j2_y], ECX

    CALL mover_pelota

    MOV BYTE [color], 0x0F
    CALL pintar_escena

.no_dibujar:
    JMP bucle_principal

pintar_escena:
; Pala 1
    MOV EBX, 10
    MOV ECX, [j1_y]
    SHR ECX, 8
    CALL pintar_pala

    ; Pala 2
    MOV EBX, 305
    MOV ECX, [j2_y]
    SHR ECX, 8
    CALL pintar_pala

    ; Pelota
    MOV EBX, [ball_x]
    SHR EBX, 8
    MOV ECX, [ball_y]
    SHR ECX, 8
    CALL pintar_pelota
    RET

; --- SINCRONIZACIÓN ---
wait_vblank:
    push edx
    push eax
    mov dx, 0x3DA
.esperar_que_termine:
    in al, dx
    test al, 8
    jnz .esperar_que_termine  ; Si ya está en retrace, espera a que salga
.esperar_que_empiece:
    in al, dx
    test al, 8
    jz .esperar_que_empiece   ; Ahora espera a que empiece uno nuevo
    pop eax
    pop edx
    ret

; --- LÓGICA ---
mover_pelota:
    MOV EAX, [ball_x]
    MOV EBX, [ball_y]
    ADD EAX, [ball_dx]
    ADD EBX, [ball_dy]

    ; Rebote Pared Superior (Y <= 0)
    CMP EBX, 0
    JG .check_inf
    MOV DWORD [ball_dy], VEL_BOLA_Y
.check_inf:
    ; Rebote Pared Inferior (Y >= 196)
    CMP EBX, 196 << 8
    JL .colision_palas
    MOV DWORD [ball_dy], -VEL_BOLA_Y

.colision_palas:
    ; Colisión Pala Izquierda (X == 15 píxeles)
    MOV EDX, EAX
    SHR EDX, 8     
    CMP EDX, 15
    JNE .col_pala_der
    MOV EDI, [j1_y] 
    CMP EBX, EDI
    JL .col_pala_der
    ADD EDI, 30 << 8
    CMP EBX, EDI
    JG .col_pala_der
    MOV DWORD [ball_dx], VEL_BOLA_X

.col_pala_der:
    ; Colisión Pala Derecha (X == 305 píxeles)
    MOV EDX, EAX
    SHR EDX, 8
    CMP EDX, 300 
    JNE .check_fuera
    MOV EDI, [j2_y]
    CMP EBX, EDI
    JL .check_fuera
    ADD EDI, 30 << 8
    CMP EBX, EDI
    JG .check_fuera
    MOV DWORD [ball_dx], -VEL_BOLA_X

.check_fuera:
    CMP EAX, 0
    JL .reset_ball
    CMP EAX, 320 << 8
    JG .reset_ball
    JMP .final_move

.reset_ball:
    MOV EAX, 160 << 8
    MOV EBX, 100 << 8
    NEG DWORD [ball_dx]

.final_move:
    MOV [ball_x], EAX
    MOV [ball_y], EBX
    RET

pintar_pala:
    MOV AH, 30
    MOV AL, 5
    JMP pintar_forma

pintar_pelota:
    MOV AH, 4
    MOV AL, 4

; Pinta una forma
; Posicion: x(EBX), y(ECX)
; Tamaño: h(AH), w(AL)
pintar_forma:
.fila:
    PUSH EAX
    PUSH EBX
    MOVZX EDX, AL
.columna:
    PUSH EAX
    MOV EAX, ECX
    IMUL EAX, 320
    ADD EAX, EBX
    CMP EAX, 64000
    JAE .skip_pixel
    PUSH EBX
    MOV EBX, [color]
    MOV BYTE [0xA0000 + EAX], BL  
    POP EBX
.skip_pixel:
    POP EAX
    INC EBX
    DEC EDX
    JNZ .columna
    POP EBX
    POP EAX
    INC ECX
    DEC AH
    JNZ .fila
    RET

irq1_keyboard_handler:
    PUSHAD
    IN AL, 0x60
    MOVZX EBX, AL
    AND EBX, 0x7F
    TEST AL, 0x80
    JNZ .suelta
    MOV BYTE [teclas_estado + EBX], 1
    JMP .final
.suelta:
    MOV BYTE [teclas_estado + EBX], 0
.final:
    MOV AL, 0x20
    OUT 0x20, AL
    POPAD
    IRETD

remap_pic:
    MOV AL, 0x11
    OUT 0x20, AL
    OUT 0xA0, AL
    MOV AL, 0x20
    OUT 0x21, AL
    MOV AL, 0x28
    OUT 0xA1, AL
    MOV AL, 0x04
    OUT 0x21, AL
    MOV AL, 0x02
    OUT 0xA1, AL
    MOV AL, 0x01
    OUT 0x21, AL
    OUT 0xA1, AL
    MOV AL, 0xFD
    OUT 0x21, AL
    MOV AL, 0xFF
    OUT 0xA1, AL
    RET

SECTION .DATA
VEL_PALA   EQU 250 ; Velocidad de movimiento palas (Punto fijo)
VEL_BOLA_X EQU 250  ; Velocidad horizontal bola
VEL_BOLA_Y EQU 125   ; Velocidad vertical bola

ALIGN 4
j1_y: dd 85 << 8
j2_y: dd 85 << 8

ball_x:  dd 160 << 8
ball_y:  dd 100 << 8
ball_dx: dd VEL_BOLA_X
ball_dy: dd VEL_BOLA_Y

color: db 0x00
frame_count: dd 0

teclas_estado TIMES 256 DB 0

ALIGN 8
gdt_start:
    DQ 0x0
    ; Region de datos
    DW 0xFFFF, 0x0000, 0x9A00, 0x00CF
    ; Region de instrucciones
    DW 0xFFFF, 0x0000, 0x9200, 0x00CF
gdt_end:

gdt_desc:
    DW gdt_end - gdt_start - 1
    DD gdt_start

ALIGN 8
idt_start:
    TIMES 256 DQ 0
idt_end:

idt_descriptor:
    DW idt_end - idt_start - 1
    DD idt_start

TIMES 4096 - ($ - $$) DB 0
