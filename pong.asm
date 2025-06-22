.MODEL SMALL
INCLUDE TASMLIB.inc
.STACK 100h             

.DATA

    MIDDLE_LINE     dw   200
    PADDLE_SIZE     dw   40
    PADDLE_LEFT_X   dw   1
    PADDLE_RIGHT_X  dw   318
    PADDLE_TOP      dw   1
    PADDLE_MID      dw   90
    PADDLE_BOTTOM   dw   187

    BALL_X_R        dw   30
    BALL_X_L        dw   610
    BALL_TOP        dw   40
    BALL_BOTTOM     dw   440

    center_x        dw   36     
    center_y        dw   46
    box_begin_x     dw   33
    box_begin_y     dw   43
    radius          dw   5       
    color           DB   0Ch   

    ball_dx         db 1     ; Direcci?n horizontal: +1 o -1
    ball_dy      db 1     ; Direcci?n vertical: +1 o -1    
    
    screen_width    dw   640
    paddle_right_y  dw   90
    paddle_left_y   dw   90
    ball_x          dw   160
    ball_y          dw   200
    ;color           dw   5
    MSG             DB   "--Ping Pong--", '$'
    salida          DB   "salir(f12)",'$'
    score           DB   "score:"," ",'$'
    P1              DB   "P1:","0000",'$'
    P2              DB   "P2:","0000",'$'
    PA              DB   "PA:","0000",'$'
    Time            DB   "Time:","9999",'$'
    
.CODE
MAIN PROC
    MOV AX, @data
    MOV DS, AX

    SET_VIDEO_MODE 12h
    SET_BACKGROUND_COLOR_12H 1      ;fondo azul
    
    CALL TWO_PLAYER_SCREEN
    CALL DRAW_BALL
    
    WAIT_KEY 07                     ;espera la tecla f12 para salir    
    SET_VIDEO_MODE 12h
    SET_BACKGROUND_COLOR_12H 1      ;vuelve a colocar la pantalla en azul
    
    MOV AH, 4Ch         
    INT 21h
MAIN ENDP

SINGLE_PLAYER_SCREEN PROC

    ;PRINT_STRING 1,31,MSG,6
    DRAW_BOX 10,10,620,460,10
    DRAW_BOX 30,40,580,400,10
    PRINT_STRING 28,4,salida,6
    PRINT_STRING 28,67,Time,6
    PRINT_STRING 1,4,P1,6
    PRINT_STRING 1,69,PA,6
    ret
    
SINGLE_PLAYER_SCREEN ENDP


TWO_PLAYER_SCREEN PROC

    ;PRINT_STRING 1,31,MSG,6
    DRAW_BOX 10,10,620,460,10
    DRAW_BOX 30,40,580,400,10
    PRINT_STRING 28,4,salida,6
    PRINT_STRING 28,67,Time,6
    PRINT_STRING 1,4,P1,6
    PRINT_STRING 1,69,P2,6
    ret
    
TWO_PLAYER_SCREEN ENDP

put_pixel PROC
    PUSH BX 
    MOV AH, 0Ch
    MOV BH, 0
    INT 10h
    POP BX 
    RET
put_pixel ENDP

draw_circle PROC
    XOR SI, SI          ; x = 0
    MOV DI, [radius]    ; y = radio
    MOV BX, 3          ; d = 3 - 2*r
    SUB BX, DI
    SUB BX, DI
circle_loop:
    CALL draw_octants
    CMP BX, 0
    JGE d_positive
    MOV AX, SI
    SHL AX, 2      
    ADD AX, 6      ; Sumar 6 (total = 4*SI + 6)
    ADD BX, AX
    JMP next_step
d_positive:
    DEC DI             ; y--
    MOV AX, SI
    SUB AX, DI         ; x - y
    SHL AX, 2          ; 4*(x - y)
    ADD AX, 10         ; 4*(x - y) + 10
    ADD BX, AX
next_step:
    INC SI             ; x++
    CMP SI, DI
    JLE circle_loop
    RET
draw_circle ENDP

draw_octants PROC
    MOV CX, [center_x]
    ADD CX, SI
    MOV DX, [center_y]
    ADD DX, DI
    MOV AL, [color]
    CALL put_pixel
    MOV CX, [center_x]
    ADD CX, DI
    MOV DX, [center_y]
    ADD DX, SI
    CALL put_pixel
    MOV CX, [center_x]
    SUB CX, SI
    MOV DX, [center_y]
    ADD DX, DI
    CALL put_pixel
    MOV CX, [center_x]
    SUB CX, DI
    MOV DX, [center_y]
    ADD DX, SI
    CALL put_pixel
    MOV CX, [center_x]
    ADD CX, SI
    MOV DX, [center_y]
    SUB DX, DI
    CALL put_pixel
    MOV CX, [center_x]
    ADD CX, DI
    MOV DX, [center_y]
    SUB DX, SI
    CALL put_pixel
    MOV CX, [center_x]
    SUB CX, SI
    MOV DX, [center_y]
    SUB DX, DI
    CALL put_pixel
    MOV CX, [center_x]
    SUB CX, DI
    MOV DX, [center_y]
    SUB DX, SI
    CALL put_pixel
    RET
draw_octants ENDP

DRAW_BALL PROC

MOVEMENT_BALL:
    MOV [color],0

    DRAW_FILLED_BOX box_begin_x, box_begin_y, 7, 7, 0
    CALL draw_circle

    ADD [box_begin_x], 3
    ADD [box_begin_y], 1
    ADD [center_x], 3
    ADD [center_y], 1
    
    MOV [color],0ch

    DRAW_FILLED_BOX box_begin_x, box_begin_y, 7, 7, 0Ch
    CALL draw_circle

    mov cx, 0FFFFh
delay_loop:
    nop
    loop delay_loop

    JMP MOVEMENT_BALL

RET
DRAW_BALL ENDP

; Supuestos: 
;   - box_begin_x, box_begin_y son las coordenadas del cuadro actual de la bola.
;   - ball_dx y ball_dy controlan la direcci?n.
;   - Los bordes son: X = [30, 580], Y = [40, 400]

move_ball_auto PROC
    push ax bx cx dx

    ; 1. Borrar la bola anterior (color fondo)
    mov ax, [box_begin_y]
    mov bx, [box_begin_x]
    mov dl, 0   ; color negro
    call draw_filled_ball

    ; 2. Calcular nueva posici?n
    mov al, [ball_dx]
    cbw
    add [box_begin_x], ax

    mov al, [ball_dy]
    cbw
    add [box_begin_y], ax

    ; 3. Verificar colisi?n con l?mites horizontales
    mov ax, [box_begin_x]
    cmp ax, 36
    jge not_left
    neg [ball_dx]
    mov [box_begin_x], 36
not_left:
    cmp ax, 610
    jle not_right
    neg [ball_dx]
    mov [box_begin_x], 610
not_right:

    ; 4. Verificar colisi?n con l?mites verticales
    mov ax, [box_begin_y]
    cmp ax, 46
    jge not_top
    neg [ball_dy]
    mov [box_begin_y], 46
not_top:
    cmp ax, 440
    jle not_bottom
    neg [ball_dy]
    mov [box_begin_y], 440
not_bottom:

    ; 5. Dibujar bola nueva
    mov ax, [box_begin_y]
    mov bx, [box_begin_x]
    mov dl, 0Ch ; color rojo
    call draw_filled_ball

    ; 6. Retardo simple
    mov cx, 0FFFFh
delay_loop_1:
    nop
    loop delay_loop_1

    pop dx cx bx ax
    ret
    move_ball_auto ENDP
    
draw_filled_ball PROC

DRAW_FILLED_BOX box_begin_x, box_begin_y, 7, 7, 0
    CALL draw_circle

RET
draw_filled_ball ENDP

END MAIN
