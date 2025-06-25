.MODEL SMALL
INCLUDE TASMLIB.inc
.STACK 100h             

.DATA
    AREA_TOP        dw   47   ; L?mite superior (Y m?nimo)
    AREA_BOTTOM     dw   430  ; L?mite inferior (Y m?ximo)
    AREA_LEFT       dw   37   ; L?mite izquierdo (X m?nimo)
    AREA_RIGHT      dw   600  ; L?mite derecho (X m?ximo)
    ;coordenadas de los paddles
    PADDLE_LEFT_X   dw   40
    PADDLE_LEFT_Y   dw   90
    PADDLE_RIGHT_X  dw   590
    PADDLE_RIGHT_Y  dw   400
    PADDLE_TOP      dw   40
    PADDLE_MID      dw   200
    PADDLE_BOTTOM   dw   400
    ;ball posicion y limites
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
    ball_dx         db   1     ; Direccion horizontal: +1 o -1
    ball_dy         db   1     ; Direccion vertical: +1 o -1    
    
    screen_width    dw   640
    ball_x          dw   160
    ball_y          dw   200
    ;mensajes del menu principal
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
    ;timer
    Time            db   'Tiempo: ', '$'
    str_seg         db   '000$'      ; Cadena para mostrar segundos
    start_secs      DW   180         ; Duracion inicial (segundos)
    current_secs    DW   ?
    prev_sec        DB   ?
    msg_done        DB   'Tiempo agotado!$'
    last_cent       DB   0     ; ultima centesima registrada
    ball_speed      DB   5     ; Velocidad de la bola (cada 5 cent?simas)
    accum_cent      DB   0
    
.CODE
MAIN PROC
    MOV AX, @data
    MOV DS, AX

    SET_VIDEO_MODE 12h
    SET_BACKGROUND_COLOR_12H 00h      ;fondo negro
    
menu:
    CALL imprimir_titulo
    CHECK_KEY 0Dh, eleccion    
    JMP menu
eleccion:
    DRAW_FILLED_BOX 24, 210, 600, 80, 00h
    call imprimir_menu
eleccion_1:
    CHECK_KEY 31h, one
    CHECK_KEY 32h, two
    CHECK_KEY 86h, menu
    JMP eleccion_1
one:   
    
    CALL SINGLE_PLAYER_SCREEN 
    MOV AX, start_secs
    MOV current_secs, AX
    MOV AH, 2Ch
    INT 21h
    MOV prev_sec, DH
    ; Mostrar tiempo inicial
    MOV AX, current_secs
    CALL CONVERT_TO_STRING
    PRINT_STRING 28, 72, str_seg, 6  
    DRAW_FILLED_BOX  250,100,100,250,00H
    DRAW_FILLED_BOX  PADDLE_LEFT_X,PADDLE_MID,10,40,0FH
    DRAW_FILLED_BOX  PADDLE_RIGHT_X,PADDLE_MID,10,40,0FH
    MOV ball_dx, 2       ; Velocidad horizontal
    MOV ball_dy, 1       ; Velocidad vertical
    CALL DRAW_BALL       ; Dibujar bola inicial
    JMP JUEGO
two:    
    CALL TWO_PLAYER_SCREEN  
    MOV AX, start_secs
    MOV current_secs, AX
    MOV AH, 2Ch
    INT 21h
    MOV prev_sec, DH
    ; Mostrar tiempo inicial
    MOV AX, current_secs
    CALL CONVERT_TO_STRING
    PRINT_STRING 28, 72, str_seg, 6
    DRAW_FILLED_BOX  250,100,100,250,00H
    DRAW_FILLED_BOX  PADDLE_LEFT_X,PADDLE_MID,10,40,0FH
    DRAW_FILLED_BOX  PADDLE_RIGHT_X,PADDLE_MID,10,40,0FH
    MOV ball_dx, 3       ; Velocidad horizontal
    MOV ball_dy, 1       ; Velocidad vertical
    CALL DRAW_BALL       ; Dibujar bola inicial
    JMP JUEGO
    
JUEGO:
    MOV AH, 2Ch
    INT 21h

; Manejo de segundos
    CMP DH, prev_sec
    JE no_sec_change
    MOV prev_sec, DH
    DEC current_secs

    ; Comprobar si el tiempo se agoto
    CMP current_secs, 0
    JG update_timer_display
; Tiempo agotado
    PRINT_STRING 15, 35, msg_done, 6
    WAIT_KEY 0
    JMP salir

update_timer_display:
    ; Convertir y mostrar el tiempo
    MOV AX, current_secs
    CALL CONVERT_TO_STRING
    PRINT_STRING 28, 72, str_seg, 6

no_sec_change:   ;ciclo principal
    PRINT_STRING 1,4,P1,6
    PRINT_STRING 1,69,PA,6
    MOV [color], 0       ; Color negro (borrar)
    CALL draw_filled_ball
    
    ; Actualizar posici?n X (con extensi?n de signo correcta)
    MOV AL, ball_dx      ; Cargar direcci?n X en AL
    CBW                  ; Extender signo de AL a AX
    ADD ball_x, AX       ; Mover la bola en X
    
    ; Actualizar posici?n Y (con extensi?n de signo correcta)
    MOV AL, ball_dy      ; Cargar direcci?n Y en AL
    CBW                  ; Extender signo de AL a AX
    ADD ball_y, AX       ; Mover la bola en Y
    
    ; Verificar l?mites horizontales (X)
    MOV AX, AREA_LEFT
    CMP ball_x, AX
    JL invertir_x_L        ; Si X < l?mite izquierdo, invertir direcci?n X
    
    MOV AX, AREA_RIGHT
    CMP ball_x, AX
    JG invertir_x_R        ; Si X > l?mite derecho, invertir direcci?n X
    
    ; Verificar l?mites verticales (Y)
    MOV AX, AREA_TOP
    CMP ball_y, AX
    JL invertir_y        ; Si Y < l?mite superior, invertir direcci?n Y
    
    MOV AX, AREA_BOTTOM
    CMP ball_y, AX
    JG invertir_y        ; Si Y > l?mite inferior, invertir direcci?n Y
    
    JMP actualizar_dibujo
    
invertir_x_L:
    NEG ball_dx          ; Invertir direcci?n horizontal
    INC [P1+6]
    MOV ball_x, 320      
    MOV ball_y, 210
    WAIT_KEY 0DH    
    JMP actualizar_dibujo
    
invertir_x_R:
    NEG ball_dx          ; Invertir direcci?n horizontal
    INC [P2+6]
    INC [PA+6]
    MOV ball_x, 320      
    MOV ball_y, 210
    WAIT_KEY 0DH
    JMP actualizar_dibujo
    
invertir_y:
    NEG ball_dy          ; Invertir direcci?n vertical
    
actualizar_dibujo:
    ; Actualizar coordenadas de dibujo
    MOV AX, ball_x
    MOV center_x, AX
    SUB AX, 3
    MOV box_begin_x, AX
    
    MOV AX, ball_y
    MOV center_y, AX
    SUB AX, 3
    MOV box_begin_y, AX
    
    MOV [color], 0Ch     ; Color rojo (dibujar)
    CALL draw_filled_ball
    JMP JUEGO
salir:
    WAIT_KEY 07                     ;espera la tecla f12 para salir    
    SET_VIDEO_MODE 12h
    SET_BACKGROUND_COLOR_12H 0      ;vuelve a colocar la pantalla en negro
    
    MOV AH, 4Ch         
    INT 21h
MAIN ENDP

SINGLE_PLAYER_SCREEN PROC

    ;PRINT_STRING 1,31,MSG,6
    DRAW_BOX 10,10,620,460,10
    DRAW_BOX 30,40,580,400,10
    PRINT_STRING 28,4,salida,6
    PRINT_STRING 28,63,Time,6
    PRINT_STRING 28,72,str_seg,6
    PRINT_STRING 1,4,P1,6
    PRINT_STRING 1,69,PA,6
    ret
    
SINGLE_PLAYER_SCREEN ENDP


TWO_PLAYER_SCREEN PROC

    ;PRINT_STRING 1,31,MSG,6
    DRAW_BOX 10,10,620,460,10
    DRAW_BOX 30,40,580,400,10
    PRINT_STRING 28,4,salida,6
    PRINT_STRING 28,63,Time,6
    PRINT_STRING 28,72,str_seg,6
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
    MOV [color], 0Ch      ; Color rojo
    CALL draw_filled_ball
    RET
DRAW_BALL ENDP
    
draw_filled_ball PROC
    DRAW_FILLED_BOX box_begin_x, box_begin_y, 7, 7, [color]
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

    PRINT_STRING 7 ,33,one_player,6
    PRINT_STRING 14,32,two_player,6
    PRINT_STRING 21,33,salida,6

RET
imprimir_menu ENDP

imprimir_menu_sec PROC

    PRINT_STRING 14,20,saved_game,6
    PRINT_STRING 18,20,new_game,6

RET
imprimir_menu_sec ENDP

detectar_colision PROC ;top 40, bottom 440

    ;invertir la velocidad que llega al limite

RET
detectar_colision ENDP

CONVERT_TO_STRING PROC
    PUSH AX BX CX DX SI DI
    LEA DI, str_seg + 2  ; Fin de cadena ('$')
    MOV SI, DI               ; DI = inicio de cadena

    MOV CX, 3            ; 3 d?gitos
    MOV BX, 10           ; Divisor
convert_loop:
    XOR DX, DX           ; Limpiar DX
    DIV BX               ; AX = AX/10, DX = resto
    ADD DL, '0'          ; Convertir d?gito a ASCII
    MOV [DI], DL         ; Almacenar car?cter
    DEC DI
    LOOP convert_loop

    POP DI SI DX CX BX AX
    RET
CONVERT_TO_STRING ENDP

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
