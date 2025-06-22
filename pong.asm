.MODEL SMALL
INCLUDE TASMLIB.inc
.STACK 100h             

.DATA
    ;coordenadas de los paddles
    PADDLE_LEFT_X   dw   40
    PADDLE_LEFT_Y   dw   90
    PADDLE_RIGHT_X  dw   590
    PADDLE_RIGHT_Y  dw   400
    ;limites para los paddles
    PADDLE_TOP      dw   40
    PADDLE_MID      dw   200
    PADDLE_BOTTOM   dw   400

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
    ball_dy         db 1     ; Direcci?n vertical: +1 o -1    
    
    screen_width    dw   640
    ball_x          dw   160
    ball_y          dw   200
    ;mensajes del menu principal
    MSG             DB   "--Ping Pong--", '$'
    one_player      DB   "One player",'$'
    two_player      DB   "Two players",'$'
    salida          DB   "salir(f12)",'$'
    ;eleccion de partida
    saved_game      DB   "Partida guardada",'$'
    new_game        DB   "Nuevo juego",'$'
    ;mensajes de la pantalla de juego
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
    SET_BACKGROUND_COLOR_12H 00h      ;fondo azul
    
menu:
    CALL imprimir_titulo
    CHECK_KEY 0Dh, eleccion    
    JMP menu
    
eleccion:
    call imprimir_menu_sec
    CHECK_KEY 31h, one
    CHECK_KEY 32h, two
    JMP eleccion
one:  
     
    CALL SINGLE_PLAYER_SCREEN
    DRAW_FILLED_BOX  PADDLE_LEFT_X,PADDLE_MID,10,40,0FH
    DRAW_FILLED_BOX  PADDLE_RIGHT_X,PADDLE_MID,10,40,0FH
    CALL DRAW_BALL
two:    
    CALL TWO_PLAYER_SCREEN
    DRAW_FILLED_BOX  PADDLE_LEFT_X,PADDLE_MID,10,40,0FH
    DRAW_FILLED_BOX  PADDLE_RIGHT_X,PADDLE_MID,10,40,0FH
    CALL DRAW_BALL
        
JUEGO:   ;ciclo principal
    
    JMP JUEGO
salir:
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
    
draw_filled_ball PROC

    DRAW_FILLED_BOX box_begin_x, box_begin_y, 7, 7, 0
    CALL draw_circle
    RET
    
draw_filled_ball ENDP


draw_paddle_left PROC

   DRAW_FILLED_BOX  PADDLE_LEFT_X,PADDLE_MID,10,40,0FH

RET
draw_paddle_left ENDP

draw_paddle_right PROC

   DRAW_FILLED_BOX  PADDLE_RIGHT_X,PADDLE_MID,10,40,0FH

RET
draw_paddle_right ENDP

imprimir_menu PROC

    PRINT_STRING 10,20,MSG,6
    PRINT_STRING 14,20,one_player,6
    PRINT_STRING 18,20,two_player,6
    PRINT_STRING 22,20,salida,6

RET
imprimir_menu ENDP

imprimir_menu_sec PROC

    PRINT_STRING 14,20,saved_game,6
    PRINT_STRING 18,20,new_game,6

RET
imprimir_menu_sec ENDP

imprimir_titulo PROC
    ;P
    DRAW_FILLED_BOX 24, 210, 16, 80, 0Ah
    DRAW_FILLED_BOX 56, 210, 16, 48, 0Ah
    DRAW_FILLED_BOX 40, 210, 16, 16, 0Ah
    DRAW_FILLED_BOX 40, 242, 16, 16, 0Ah
    ;I
    DRAW_FILLED_BOX 88, 210, 16, 80, 0Ah
    ;N
    DRAW_FILLED_BOX 120, 210, 16, 80, 0Ah
    DRAW_FILLED_BOX 168, 210, 16, 80, 0Ah
    DRAW_FILLED_BOX 136, 226, 16, 32, 0Ah
    DRAW_FILLED_BOX 152, 258, 16, 16, 0Ah
    ;G
    DRAW_FILLED_BOX 200, 210, 16, 80, 0Ah
    DRAW_FILLED_BOX 216, 210, 48, 16, 0Ah
    DRAW_FILLED_BOX 216, 274, 48, 16, 0Ah
    DRAW_FILLED_BOX 248, 242, 16, 32, 0Ah
    DRAW_FILLED_BOX 232, 242, 16, 16, 0Ah
    ;-
    DRAW_FILLED_BOX 280, 242, 48, 16, 0Ah
    ;P
    DRAW_FILLED_BOX 344, 210, 16, 80, 0Ah
    DRAW_FILLED_BOX 376, 210, 16, 48, 0Ah
    DRAW_FILLED_BOX 360, 210, 16, 16, 0Ah
    DRAW_FILLED_BOX 360, 242, 16, 16, 0Ah
    ;O
    DRAW_FILLED_BOX 408, 210, 16, 80, 0Ah
    DRAW_FILLED_BOX 440, 210, 16, 80, 0Ah
    DRAW_FILLED_BOX 424, 210, 16, 16, 0Ah
    DRAW_FILLED_BOX 424, 274, 16, 16, 0Ah
    ;N
    DRAW_FILLED_BOX 472, 210, 16, 80, 0Ah
    DRAW_FILLED_BOX 520, 210, 16, 80, 0Ah
    DRAW_FILLED_BOX 488, 226, 16, 32, 0Ah
    DRAW_FILLED_BOX 504, 258, 16, 16, 0Ah
    ;G
    DRAW_FILLED_BOX 552, 210, 16, 80, 0Ah
    DRAW_FILLED_BOX 568, 210, 48, 16, 0Ah
    DRAW_FILLED_BOX 568, 274, 48, 16, 0Ah
    DRAW_FILLED_BOX 600, 242, 16, 32, 0Ah
    DRAW_FILLED_BOX 584, 242, 16, 16, 0Ah

RET
imprimir_titulo ENDP

END MAIN
