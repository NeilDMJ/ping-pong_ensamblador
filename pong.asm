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
    PADDLE_LEFT_Y   dw   200    ; Posici??n Y inicial centrada
    PADDLE_RIGHT_X  dw   590
    PADDLE_RIGHT_Y  dw   200    ; Posici??n Y inicial centrada
    PADDLE_TOP      dw   38     ; L??mite superior (borde verde interno + margen)
    PADDLE_MID      dw   200
    PADDLE_BOTTOM   dw   442    ; L??mite inferior m??s permisivo (borde verde interno - margen peque??o)
    paddle_speed  dw 8
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
    menu_title      DB   "PING-PONG GAME",'$'
    start_game      DB   "Presiona ENTER para comenzar",'$'
    salida          DB   "Presiona F12 para salir",'$'
    controls        DB   "CONTROLES:",'$'
    player1_ctrl    DB   "Jugador 1: W/S",'$'
    player2_ctrl    DB   "Jugador 2: Flechas",'$'
    game_mode       db   2
    ;mensajes de la pantalla de juego
    score           DB   "score:"," ",'$'
    P1              DB   "P1:",'$'
    P2              DB   "P2:",'$'
    score_P1      dw 0
    score_P2      dw 0
    str_score_P1  db "0000$"   ; Cadena para P1
    str_score_P2  db "0000$"   ; Cadena para P2
    max_score     dw 10         ; Puntuaci??n m??xima para ganar
    
    ;mensajes de pantalla de victoria
    winner_title  DB   "!!! GANADOR !!!",'$'
    player1_wins  DB   "JUGADOR 1 GANA!",'$'
    player2_wins  DB   "JUGADOR 2 GANA!",'$'
    final_score   DB   "Puntuacion Final:",'$'
    play_again    DB   "Presiona ENTER para jugar de nuevo",'$'
    exit_game     DB   "Presiona F12 para salir",'$'
    congratulations DB "FELICITACIONES!",'$'
    exit_message    DB "Gracias por jugar PING-PONG! Presiona cualquier tecla para continuar...",'$'
    
    ;variables para nicknames de jugadores
    player1_nickname DB 9 DUP('$')    ; Nickname jugador 1 
    player2_nickname DB 9 DUP('$')    ; Nickname jugador 2 
    prompt_p1       DB "Ingrese nombre del Jugador 1:", '$'
    prompt_p2       DB "Ingrese nombre del Jugador 2:", '$'
    nickname_title  DB "=== CONFIGURACION DE JUGADORES ===",'$'
    press_enter     DB "Presiona ENTER para continuar...",'$'
    default_p1      DB "PLAYER1",'$'
    default_p2      DB "PLAYER2",'$'
    win_msg         DB " GANA!",'$'
    config_msg      DB "Jugadores configurados:",'$'
    p1_label        DB "Jugador 1: ",'$'
    p2_label        DB "Jugador 2: ",'$'
    
    ;timer
    Time            db   'Tiempo: ', '$'
    str_seg         db   '000$'      ; Cadena para mostrar segundos
    start_secs      DW   10         ; Duracion inicial (segundos)
    current_secs    DW   ?
    prev_sec        DB   ?
    msg_done        DB   'Tiempo agotado!$'
    last_cent       DB   0     ; ultima centesima registrada
    ball_speed      DB   5     ; Velocidad de la bola (cada 5 cent?simas)
    accum_cent      DB   0
    
; ============================================================
; PROGRAMA PRINCIPAL
; ============================================================
.CODE
MAIN PROC
    ; Inicializaci??n del programa
    MOV AX, @data
    MOV DS, AX

    ; Establecer modo gr??fico VGA 640x480x16
    SET_VIDEO_MODE 12h
    SET_BACKGROUND_COLOR_12H 00h

; ============================================================
; PANTALLA DEL MENU PRINCIPAL
; ============================================================
menu:
    ; Dibujar interfaz del menu
    CALL imprimir_titulo
    CALL imprimir_menu
    
menu_loop:
    ; ---- Detecci??n de entrada del men?? usando macro simplificada ----
    SIMPLE_MENU_INPUT_HANDLER
    
    ; Procesar la acci??n detectada
    CMP AH, 1           ; ??ENTER detectado?
    JE iniciar_juego
    
    CMP AH, 2           ; ??F12 detectado?
    JE salir_programa
    
    ; Si no hay entrada v??lida, continuar en el men??
    JMP menu_loop

; ---- Saltos intermedios para evitar errores de rango ----
iniciar_juego:
    JMP nickname_setup_screen

salir_programa:
    JMP salir
    
; ============================================================
; PANTALLA DE CONFIGURACION DE NICKNAMES
; ============================================================
nickname_setup_screen:
    ; Limpiar pantalla y configurar modo
    CLEAR_SCREEN 00h
    SET_VIDEO_MODE 12h
    SET_BACKGROUND_COLOR_12H 00h
    
    ; Limpiar buffer de teclado
    SIMPLE_FLUSH_KEYS
    
    ; Dibujar interfaz de configuraci??n
    CALL DRAW_NICKNAME_INTERFACE
    
    ; Capturar nickname del jugador 1
    CALL CAPTURE_PLAYER1_NICKNAME
    
    ; Actualizar pantalla para jugador 2
    CALL UPDATE_NICKNAME_INTERFACE_P2
    
    ; Capturar nickname del jugador 2
    CALL CAPTURE_PLAYER2_NICKNAME
    
    ; Mostrar confirmaci??n
    CALL SHOW_NICKNAME_CONFIRMATION
    
    ; Proceder al juego
    JMP start_game_directly
    
; ============================================================
; INICIALIZACION DEL JUEGO
; ============================================================
start_game_directly:
    CLEAR_SCREEN 00H
    ; ---- Transici??n r??pida y limpia al modo de juego ----
    SIMPLE_FLUSH_KEYS                   ; Limpiar buffer de teclado
    SIMPLE_FAST_TRANSITION 12h          ; Transici??n suave al modo gr??fico
    
    ; Configurar modo de juego
    MOV game_mode, 2
    
    ; Dibujar interfaz del juego
    CALL TWO_PLAYER_SCREEN  
    
    ; Inicializar timer
    MOV AX, start_secs
    MOV current_secs, AX
    MOV AH, 2Ch
    INT 21h
    MOV prev_sec, DH
    
    ; Mostrar tiempo inicial
    MOV AX, current_secs
    CALL CONVERT_TO_STRING
    PRINT_STRING 1, 65, str_seg, 6
    
    ; Dibujar elementos del juego
    CALL DRAW_GAME_ELEMENTS     ; Procedimiento para dibujar elementos
    
    ; Configurar bola inicial
    CALL INITIALIZE_BALL        ; Procedimiento para inicializar bola
    
    JMP JUEGO           ; Ir al bucle principal del juego

; ============================================================
; BUCLE PRINCIPAL DEL JUEGO
; ============================================================
    
JUEGO:
    ; ---- Manejo del temporizador usando macro ----
    CALL UPDATE_GAME_TIMER
    
    ; Verificar si el tiempo se agoto
    CMP current_secs, 0
    JLE time_up_jump

    ; ---- Detecci??n de controles sin macro para evitar problemas ----
    CALL HANDLE_GAME_INPUT
    
    ; Procesar entrada del juego basado en el resultado
    CMP AH, 1           ; Jugador 1 arriba (W)
    JE move_left_up
    CMP AH, 2           ; Jugador 1 abajo (S)  
    JE move_left_down
    CMP AH, 3           ; Jugador 2 arriba (flecha arriba)
    JE move_right_up
    CMP AH, 4           ; Jugador 2 abajo (flecha abajo)
    JE move_right_down
    CMP AH, 5           ; ESC (pausa/men??)
    JE pause_game
    CMP AH, 59          ; F1 para salir (scan code decimal)
    JE salir
    

    ; ---- Actualizacion de la bola ----
    CALL UPDATE_BALL_POSITION
    CALL CHECK_BALL_COLLISIONS
    CALL DRAW_GAME_STATE
    
    JMP JUEGO

; Saltos intermedios para evitar problemas de rango
time_up_jump:
    JMP time_up_handler

pause_game:
    ; Implementar pausa si se desea
    JMP JUEGO

; ============================================================
; MANEJADORES CERCANOS
; ============================================================
time_up_handler:
    PRINT_STRING 15, 20, msg_done, 0Ch
    MOV AH, 00h
    INT 16h
    JMP salir_jump2

; ============================================================
; CONTROLES DE PADDLES (optimizados con procedimientos)
; ============================================================
move_left_up:
    CALL MOVE_LEFT_PADDLE_UP
    JMP JUEGO

move_left_down:
    CALL MOVE_LEFT_PADDLE_DOWN
    JMP JUEGO

move_right_up:
    CALL MOVE_RIGHT_PADDLE_UP
    JMP JUEGO

move_right_down:
    CALL MOVE_RIGHT_PADDLE_DOWN
    JMP JUEGO

; ============================================================
; SALIDA DEL PROGRAMA
; ============================================================
salir_jump2:
    JMP salir

salir:
    CALL SAFE_EXIT_PROGRAM
MAIN ENDP

; ============================================================
; MANEJADORES DE VICTORIA
; ============================================================
show_player1_victory:
    CLEAR_SCREEN 00H
    SIMPLE_FAST_TRANSITION 12h 
    CALL DRAW_VICTORY_SCREEN
    CALL DRAW_PLAYER1_WINNER
    JMP victory_input_loop

show_player2_victory:
    CLEAR_SCREEN 00H
    SIMPLE_FAST_TRANSITION 12h 
    CALL DRAW_VICTORY_SCREEN
    CALL DRAW_PLAYER2_WINNER
    JMP victory_input_loop

victory_input_loop:
    ; Manejo de entrada en pantalla de victoria con verificaci??n directa
    MOV AH, 01h
    INT 16h
    JZ victory_input_loop   ; Si no hay tecla, seguir esperando
    
    ; Leer tecla
    MOV AH, 00h
    INT 16h
    
    ; Verificar ENTER (0Dh)
    CMP AL, 0Dh
    JE restart_game
    
    ; Verificar F12 (scan code 56h)
    CMP AH, 56h
    JE exit_to_dos
    
    ; Si no es ninguna tecla v??lida, continuar esperando
    JMP victory_input_loop

exit_to_dos:
    ; Salida directa al DOS usando procedimiento unificado
    CALL SAFE_EXIT_PROGRAM

restart_game:
    ; Reiniciar puntuaciones
    MOV score_P1, 0
    MOV score_P2, 0
    
    ; Reiniciar cadenas de puntuaci??n
    LEA DI, str_score_P1
    MOV AX, 0
    CALL CONVERT_SCORE
    LEA DI, str_score_P2
    MOV AX, 0
    CALL CONVERT_SCORE
    
    ; Reiniciar posiciones de paddles al centro
    MOV PADDLE_LEFT_Y, 200
    MOV PADDLE_RIGHT_Y, 200
    
    ; Reiniciar posici??n de la pelota al centro
    MOV ball_x, 320
    MOV ball_y, 210
    MOV ball_dx, 1
    MOV ball_dy, 1
    
    ; Reiniciar timer
    MOV AX, start_secs
    MOV current_secs, AX
    MOV AH, 2Ch
    INT 21h
    MOV prev_sec, DH
    
    ; Limpiar buffer de teclado
    SIMPLE_FLUSH_KEYS
    
    ; Ir a la pantalla de configuraci??n de nicknames
    JMP nickname_setup_screen

; ============================================================
; PROCEDIMIENTOS DEL JUEGO
; ============================================================

TWO_PLAYER_SCREEN PROC
    CLEAR_SCREEN 00H
    ; Dibujar interfaz del juego con posicionamiento correcto
    DRAW_BOX 30,30,580,420,0Fh        ; Marco exterior del juego
    DRAW_BOX 35,35,570,410,0Ah        ; Marco interior verde
    
    ; Informacion del juego en la parte superior
   
    PRINT_STRING 1, 30, Time, 0Ch                 ; Etiqueta de tiempo
    PRINT_STRING 1, 38, str_seg, 0Ch              ; Tiempo
    
    ; Instrucciones en la parte inferior
    PRINT_STRING 28, 25, salida, 0Bh       ; Instrucciones de salida
    
    RET
TWO_PLAYER_SCREEN ENDP

; ============================================================
; PROCEDIMIENTOS GR??FICOS
; ============================================================

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
    PUSH AX
    MOV [color], 0Ch      ; Color rojo
    CALL draw_filled_ball
    POP AX
    RET
DRAW_BALL ENDP
    
draw_filled_ball PROC
    PUSH AX
    DRAW_FILLED_BOX box_begin_x, box_begin_y, 7, 7, [color]
    CALL draw_circle
    POP AX
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

; ============================================================
; PROCEDIMIENTOS DE INTERFAZ
; ============================================================

imprimir_menu PROC
    
    DRAW_FILLED_BOX 80, 250, 480, 180, 00h
    
    ; Marco decorativo principal
    DRAW_BOX 90, 260, 460, 160, 0Fh        ; Marco blanco exterior
    DRAW_FILLED_BOX 95, 265, 450, 150, 01h ; Fondo azul oscuro
    DRAW_BOX 100, 270, 440, 140, 0Eh       ; Marco amarillo interior
    
    
    PRINT_STRING 10, 34, menu_title, 0Fh
    
    ; Instrucciones principales 
    PRINT_STRING 13, 26, start_game, 0Eh    ; Amarillo brillante
    PRINT_STRING 15, 30, salida, 0Ch        ; Rojo brillante
    
    ; Seccion de controles 
    PRINT_STRING 18, 34, controls, 0Ah      ; Verde
    PRINT_STRING 20, 33, player1_ctrl, 0Bh  ; Cyan claro
    PRINT_STRING 21, 33, player2_ctrl, 0Bh  ; Cyan claro
    
    ; Esquinas decorativas 
    DRAW_FILLED_BOX 90, 260, 8, 8, 0Ch      ; Esquina superior izquierda
    DRAW_FILLED_BOX 542, 260, 8, 8, 0Ch     ; Esquina superior derecha
    DRAW_FILLED_BOX 90, 412, 8, 8, 0Ch      ; Esquina inferior izquierda
    DRAW_FILLED_BOX 542, 412, 8, 8, 0Ch     ; Esquina inferior derecha
    
    RET
imprimir_menu ENDP

; ============================================================
; PROCEDIMIENTOS DE PANTALLA DE VICTORIA
; ============================================================

DRAW_VICTORY_SCREEN PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    CLEAR_SCREEN 00H

    ; Marco exterior 
    DRAW_FILLED_BOX 100, 150, 440, 200, 01h ; Fondo azul oscuro
    DRAW_BOX 95, 145, 450, 210, 0Fh         ; Marco blanco exterior grueso
    DRAW_BOX 105, 155, 430, 190, 0Eh        ; Marco dorado interior
    
    ; Decoraciones en las esquinas 
    DRAW_FILLED_BOX 90, 140, 20, 20, 0Ch    ; Esquina superior izquierda roja
    DRAW_FILLED_BOX 530, 140, 20, 20, 0Ch   ; Esquina superior derecha roja
    DRAW_FILLED_BOX 90, 340, 20, 20, 0Ch    ; Esquina inferior izquierda roja
    DRAW_FILLED_BOX 530, 340, 20, 20, 0Ch   ; Esquina inferior derecha roja
    
    ; Bandas decorativas 
    DRAW_FILLED_BOX 110, 160, 420, 6, 0Eh   ; Banda dorada superior
    DRAW_FILLED_BOX 110, 334, 420, 6, 0Eh   ; Banda dorada inferior
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DRAW_VICTORY_SCREEN ENDP

DRAW_PLAYER1_WINNER PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX 
        
    ; Titulo principal centrado perfectamente
    PRINT_STRING 8, 33, winner_title, 0Eh      
    PRINT_STRING 10, 33, congratulations, 0Ch   
    
    ; Anuncio del ganador centrado
    PRINT_STRING 12, 37, player1_nickname, 0Ah      
         
    
    ; Puntuaci??n final centrada
    PRINT_STRING 15, 32, final_score, 0Fh      
    PRINT_STRING 17, 27, player1_nickname, 0Ch               
    PRINT_STRING 17, 35, str_score_P1, 0Ch     
    PRINT_STRING 17, 45, player2_nickname, 0Eh               
    PRINT_STRING 17, 53, str_score_P2, 0Eh     
    
    ; Instrucciones de control centradas
    PRINT_STRING 20, 25, play_again, 0Bh       
    PRINT_STRING 22, 30, exit_game, 0Dh        
    
    POP DX
    POP CX
    POP BX 
    POP AX
    RET
DRAW_PLAYER1_WINNER ENDP

DRAW_PLAYER2_WINNER PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX 
    
    ; Titulo principal centrado perfectamente
    PRINT_STRING 8, 33, winner_title, 0Eh      
    PRINT_STRING 10, 33, congratulations, 0Ch   
    
    ; Anuncio del ganador centrado
    PRINT_STRING 12, 37, player2_nickname, 0Ah      
       
    
    ; Puntuacion final centrada
    PRINT_STRING 16, 32, final_score, 0Fh      
    PRINT_STRING 17, 27, player1_nickname, 0Ch               
    PRINT_STRING 17, 35, str_score_P1, 0Ch     
    PRINT_STRING 17, 45, player2_nickname, 0Eh               
    PRINT_STRING 17, 53, str_score_P2, 0Eh     
    
    ; Instrucciones de control centradas
    PRINT_STRING 20, 25, play_again, 0Bh       ; Cyan
    PRINT_STRING 22, 30, exit_game, 0Dh        ; Magenta
    
    POP DX
    POP CX
    POP BX 
    POP AX
    RET
DRAW_PLAYER2_WINNER ENDP


; ============================================================
; PROCEDIMIENTOS DE CONVERSION
; ============================================================

CONVERT_TO_STRING PROC
    PUSH AX BX CX DX SI DI
    LEA DI, str_seg + 2  ; Fin de cadena ('$')
    MOV SI, DI               ; DI = inicio de cadena

    MOV CX, 3            ; 3 digitos
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


CONVERT_SCORE PROC
    PUSH BX CX DX SI DI
    ADD DI, 3            ; Empezar desde el ultimo d?gito
    MOV CX, 4            ; 4 digitos
    MOV BX, 10
convert_loop_1:
    XOR DX, DX
    DIV BX               ; DX:AX / BX -> AX=cociente, DX=resto
    ADD DL, '0'          ; Convertir a ASCII
    MOV [DI], DL
    DEC DI
    LOOP convert_loop_1
    POP DI SI DX CX BX
    RET
CONVERT_SCORE ENDP

; ============================================================
; PROCEDIMIENTO DEL TITULO
; ============================================================

imprimir_titulo PROC
    
    
    ;P
    DRAW_FILLED_BOX 100, 80, 12, 60, 0Ah
    DRAW_FILLED_BOX 124, 80, 12, 36, 0Ah
    DRAW_FILLED_BOX 112, 80, 12, 12, 0Ah
    DRAW_FILLED_BOX 112, 104, 12, 12, 0Ah
    ;I
    DRAW_FILLED_BOX 148, 80, 12, 60, 0Ah
    ;N
    DRAW_FILLED_BOX 172, 80, 12, 60, 0Ah
    DRAW_FILLED_BOX 208, 80, 12, 60, 0Ah
    DRAW_FILLED_BOX 184, 92, 12, 24, 0Ah
    DRAW_FILLED_BOX 196, 116, 12, 12, 0Ah
    ;G
    DRAW_FILLED_BOX 232, 80, 12, 60, 0Ah
    DRAW_FILLED_BOX 244, 80, 36, 12, 0Ah
    DRAW_FILLED_BOX 244, 128, 36, 12, 0Ah
    DRAW_FILLED_BOX 268, 104, 12, 24, 0Ah
    DRAW_FILLED_BOX 256, 104, 12, 12, 0Ah
    ;-
    DRAW_FILLED_BOX 292, 104, 36, 12, 0Ah
    ;P
    DRAW_FILLED_BOX 340, 80, 12, 60, 0Ah
    DRAW_FILLED_BOX 364, 80, 12, 36, 0Ah
    DRAW_FILLED_BOX 352, 80, 12, 12, 0Ah
    DRAW_FILLED_BOX 352, 104, 12, 12, 0Ah
    ;O
    DRAW_FILLED_BOX 388, 80, 12, 60, 0Ah
    DRAW_FILLED_BOX 412, 80, 12, 60, 0Ah
    DRAW_FILLED_BOX 400, 80, 12, 12, 0Ah
    DRAW_FILLED_BOX 400, 128, 12, 12, 0Ah
    ;N
    DRAW_FILLED_BOX 436, 80, 12, 60, 0Ah
    DRAW_FILLED_BOX 472, 80, 12, 60, 0Ah
    DRAW_FILLED_BOX 448, 92, 12, 24, 0Ah
    DRAW_FILLED_BOX 460, 116, 12, 12, 0Ah
    ;G
    DRAW_FILLED_BOX 496, 80, 12, 60, 0Ah
    DRAW_FILLED_BOX 508, 80, 36, 12, 0Ah
    DRAW_FILLED_BOX 508, 128, 36, 12, 0Ah
    DRAW_FILLED_BOX 532, 104, 12, 24, 0Ah
    DRAW_FILLED_BOX 520, 104, 12, 12, 0Ah
    RET
imprimir_titulo ENDP

; ============================================================
; PROCEDIMIENTOS DE LOGICA DE JUEGO
; ============================================================

UPDATE_GAME_TIMER PROC
    PUSH AX
    PUSH DX
    
    ; Obtener tiempo del sistema directamente
    MOV AH, 2Ch
    INT 21h
    
    ; Verificar cambio de segundo
    CMP DH, prev_sec
    JE no_timer_change
    MOV prev_sec, DH
    DEC current_secs
    
    ; Actualizar display del tiempo
    CMP current_secs, 0
    JLE no_timer_change
    
    MOV AX, current_secs
    CALL CONVERT_TO_STRING
    PRINT_STRING 1, 38, str_seg, 0Ch
    
no_timer_change:
    POP DX
    POP AX
    RET
UPDATE_GAME_TIMER ENDP

INITIALIZE_BALL PROC
    PUSH AX
    
    ; Configurar velocidad inicial 
    MOV ball_dx, 1       ; Velocidad horizontal 
    MOV ball_dy, 1       ; Velocidad vertical
    
    ; Posicion inicial central
    MOV ball_x, 320
    MOV ball_y, 210
    
    ; Dibujar bola inicial
    CALL DRAW_BALL
    
    POP AX
    RET
INITIALIZE_BALL ENDP

DRAW_GAME_ELEMENTS PROC
    PUSH AX
    
    
    DRAW_FILLED_BOX PADDLE_LEFT_X, PADDLE_LEFT_Y, 10, 40, 0FH
    DRAW_FILLED_BOX PADDLE_RIGHT_X, PADDLE_RIGHT_Y, 10, 40, 0FH
    
    POP AX
    RET
DRAW_GAME_ELEMENTS ENDP

UPDATE_BALL_POSITION PROC
    PUSH AX
    
    ; Borrar bola actual
    MOV [color], 0
    CALL draw_filled_ball
    
    ; Actualizar posicion X
    MOV AL, ball_dx
    CBW
    ADD ball_x, AX
    
    ; Actualizar posicion Y  
    MOV AL, ball_dy
    CBW
    ADD ball_y, AX
    
    POP AX
    RET
UPDATE_BALL_POSITION ENDP

CHECK_BALL_COLLISIONS PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    ; Verificar colision con paddle izquierdo
    MOV AX, ball_x
    CMP AX, 55              ; Posicion X del paddle izquierdo + ancho + margen
    JGE check_right_paddle
    
    ; Verificar si la pelota esta en el rango Y del paddle izquierdo
    MOV BX, ball_y
    MOV CX, PADDLE_LEFT_Y
    SUB CX, 5               ; Margen superior
    CMP BX, CX
    JL check_right_paddle   ; Por encima del paddle
    
    MOV CX, PADDLE_LEFT_Y
    ADD CX, 45              ; Altura del paddle + margen inferior
    CMP BX, CX
    JG check_right_paddle   ; Por debajo del paddle
    
    ; Colision detectada con paddle izquierdo
    CMP ball_dx, 0
    JGE check_right_paddle  ; Solo rebotar si va hacia la izquierda
    
    ; Calcular angulo de rebote basado en donde golpea
    CALL CALCULATE_BOUNCE_ANGLE_LEFT
    MOV ball_x, 56          ; Posicionar pelota fuera del paddle
    JMP check_vertical_bounds

check_right_paddle:
    ; Verificar colision con paddle derecho
    MOV AX, ball_x
    CMP AX, 585             ; Posicion X del paddle derecho - margen
    JLE check_score_bounds
    
    ; Verificar si la pelota esta en el rango Y del paddle derecho
    MOV BX, ball_y
    MOV CX, PADDLE_RIGHT_Y
    SUB CX, 5               ; Margen superior
    CMP BX, CX
    JL check_score_bounds   ; Por encima del paddle
    
    MOV CX, PADDLE_RIGHT_Y
    ADD CX, 45              ; Altura del paddle + margen inferior
    CMP BX, CX
    JG check_score_bounds   ; Por debajo del paddle
    
    ; Colision detectada con paddle derecho
    CMP ball_dx, 0
    JLE check_score_bounds  ; Solo rebotar si va hacia la derecha
    
    ; Calcular angulo de rebote basado en d??nde golpea
    CALL CALCULATE_BOUNCE_ANGLE_RIGHT
    MOV ball_x, 584         ; Posicionar pelota fuera del paddle
    JMP check_vertical_bounds

check_score_bounds:
    ; Verificar limites horizontales para puntuacion
    MOV AX, AREA_LEFT
    CMP ball_x, AX
    JL point_for_p2
    
    MOV AX, AREA_RIGHT
    CMP ball_x, AX
    JG point_for_p1
    
check_vertical_bounds:
    ; Verificar limites verticales 
    MOV AX, AREA_TOP
    ADD AX, 5               ; Margen para el radio de la pelota
    CMP ball_y, AX
    JL vertical_bounce
    
    MOV AX, AREA_BOTTOM
    SUB AX, 5               ; Margen para el radio de la pelota
    CMP ball_y, AX
    JG vertical_bounce
    
    JMP collision_end

point_for_p1:
    INC score_P1
    MOV AX, score_P1
    LEA DI, str_score_P1
    CALL CONVERT_SCORE
    
    ; Verificar si P1 gano 
    MOV AX, score_P1
    CMP AX, 10
    JGE player1_victory
    
    CALL RESET_BALL_POSITION
    JMP collision_end

point_for_p2:
    INC score_P2
    MOV AX, score_P2
    LEA DI, str_score_P2
    CALL CONVERT_SCORE
    
    ; Verificar si P2 gano 
    MOV AX, score_P2
    CMP AX, 10
    JGE player2_victory
    
    CALL RESET_BALL_POSITION
    JMP collision_end

; Saltos intermedios para manejar victorias
player1_victory:
    JMP show_player1_victory

player2_victory:
    JMP show_player2_victory

vertical_bounce:
    NEG ball_dy
    ; Asegurar que la pelota esta dentro de los limites
    MOV AX, AREA_TOP
    ADD AX, 6
    CMP ball_y, AX
    JGE check_bottom_bound
    MOV ball_y, AX
    JMP collision_end
    
check_bottom_bound:
    MOV AX, AREA_BOTTOM
    SUB AX, 6
    CMP ball_y, AX
    JLE collision_end
    MOV ball_y, AX

collision_end:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
CHECK_BALL_COLLISIONS ENDP

RESET_BALL_POSITION PROC
    PUSH AX
    PUSH DX
    
    ; Restablecer posicion central
    MOV ball_x, 320
    MOV ball_y, 210
    
    ; Obtener tiempo actual para generar direccion semi-aleatoria
    MOV AH, 2Ch
    INT 21h                 ; DL = centesimas de segundo
    
    ; Usar las centesimas para determinar direccion inicial
    TEST DL, 01h            ; Verificar bit menos significativo
    JZ reset_left
    
    
    MOV ball_dx, 1
    JMP set_vertical_dir
    
reset_left:
    
    MOV ball_dx, -1
    
set_vertical_dir:
    
    TEST DL, 02h
    JZ reset_up
    MOV ball_dy, 1          ; Hacia abajo
    JMP reset_end
    
reset_up:
    MOV ball_dy, -1         ; Hacia arriba
    
reset_end:
    ; Pequena pausa antes de continuar
    MOV CX, 8000h
reset_delay:
    LOOP reset_delay
    
    POP DX
    POP AX
    RET
RESET_BALL_POSITION ENDP

DRAW_GAME_STATE PROC
    PUSH AX
    
    ; Actualizar coordenadas de dibujo de la bola
    MOV AX, ball_x
    MOV center_x, AX
    SUB AX, 3
    MOV box_begin_x, AX
    
    MOV AX, ball_y
    MOV center_y, AX
    SUB AX, 3
    MOV box_begin_y, AX
    
    ; Dibujar bola en nueva posicion
    MOV [color], 0Ch
    CALL draw_filled_ball
    
    ; Actualizar marcadores con nicknames
    PRINT_STRING 1, 12, player1_nickname, 0Eh
    PRINT_STRING 1, 19, str_score_P1, 0Eh
    PRINT_STRING 1, 50, player2_nickname, 0Eh
    PRINT_STRING 1, 57, str_score_P2, 0Eh
    
    POP AX
    RET
DRAW_GAME_STATE ENDP

; ============================================================
; PROCEDIMIENTOS DE CONTROL DE PADDLES
; ============================================================

MOVE_LEFT_PADDLE_UP PROC
    PUSH AX
    
    ; Verificar l??mite superior (borde verde interno)
    MOV AX, PADDLE_TOP
    CMP PADDLE_LEFT_Y, AX
    JLE skip_left_up_move
    
    ; Borrar, mover y redibujar
    DRAW_FILLED_BOX PADDLE_LEFT_X, PADDLE_LEFT_Y, 10, 40, 0
    MOV AX, paddle_speed
    SUB PADDLE_LEFT_Y, AX
    
    
    MOV AX, PADDLE_TOP
    CMP PADDLE_LEFT_Y, AX
    JGE draw_left_paddle_up
    MOV PADDLE_LEFT_Y, AX   
    
draw_left_paddle_up:
    DRAW_FILLED_BOX PADDLE_LEFT_X, PADDLE_LEFT_Y, 10, 40, 0Fh
    
skip_left_up_move:
    POP AX
    RET
MOVE_LEFT_PADDLE_UP ENDP

MOVE_LEFT_PADDLE_DOWN PROC
    PUSH AX
    
    ; Verificar limite inferior 
    MOV AX, PADDLE_BOTTOM
    SUB AX, 40              ; Altura del paddle
    CMP PADDLE_LEFT_Y, AX
    JGE skip_left_down_move
    
    ; Borrar, mover y redibujar
    DRAW_FILLED_BOX PADDLE_LEFT_X, PADDLE_LEFT_Y, 10, 40, 0
    MOV AX, paddle_speed
    ADD PADDLE_LEFT_Y, AX
    
    ; Verificar que no se pase del limite despues del movimiento
    MOV AX, PADDLE_BOTTOM
    SUB AX, 40              ; Altura del paddle
    CMP PADDLE_LEFT_Y, AX
    JLE draw_left_paddle_down
    MOV PADDLE_LEFT_Y, AX   ; Ajustar al limite 
    
draw_left_paddle_down:
    DRAW_FILLED_BOX PADDLE_LEFT_X, PADDLE_LEFT_Y, 10, 40, 0Fh
    
skip_left_down_move:
    POP AX
    RET
MOVE_LEFT_PADDLE_DOWN ENDP

MOVE_RIGHT_PADDLE_UP PROC
    PUSH AX
    
    ; Verificar limite superior 
    MOV AX, PADDLE_TOP
    CMP PADDLE_RIGHT_Y, AX
    JLE skip_right_up_move
    
    ; Borrar, mover y redibujar
    DRAW_FILLED_BOX PADDLE_RIGHT_X, PADDLE_RIGHT_Y, 10, 40, 0
    MOV AX, paddle_speed
    SUB PADDLE_RIGHT_Y, AX
    
    ; Verificar que no se pase del limite despues del movimiento
    MOV AX, PADDLE_TOP
    CMP PADDLE_RIGHT_Y, AX
    JGE draw_right_paddle_up
    MOV PADDLE_RIGHT_Y, AX  ; Ajustar al limite exacto
    
draw_right_paddle_up:
    DRAW_FILLED_BOX PADDLE_RIGHT_X, PADDLE_RIGHT_Y, 10, 40, 0Fh
    
skip_right_up_move:
    POP AX
    RET
MOVE_RIGHT_PADDLE_UP ENDP

MOVE_RIGHT_PADDLE_DOWN PROC
    PUSH AX
    
    ; Verificar limite inferior 
    MOV AX, PADDLE_BOTTOM
    SUB AX, 40              ; Altura del paddle
    CMP PADDLE_RIGHT_Y, AX
    JGE skip_right_down_move
    
    ; Borrar, mover y redibujar
    DRAW_FILLED_BOX PADDLE_RIGHT_X, PADDLE_RIGHT_Y, 10, 40, 0
    MOV AX, paddle_speed
    ADD PADDLE_RIGHT_Y, AX
    
    ; Verificar que no se pase del limite despues del movimiento
    MOV AX, PADDLE_BOTTOM
    SUB AX, 40              ; Altura del paddle
    CMP PADDLE_RIGHT_Y, AX
    JLE draw_right_paddle_down
    MOV PADDLE_RIGHT_Y, AX  ; Ajustar al limite exacto
    
draw_right_paddle_down:
    DRAW_FILLED_BOX PADDLE_RIGHT_X, PADDLE_RIGHT_Y, 10, 40, 0Fh
    
skip_right_down_move:
    POP AX
    RET
MOVE_RIGHT_PADDLE_DOWN ENDP

; ============================================================
; PROCEDIMIENTO DE MANEJO DE ENTRADA
; ============================================================

HANDLE_GAME_INPUT PROC
    PUSH BX
    PUSH CX
    PUSH DX
    
    ; Verificar si hay tecla en el buffer
    MOV AH, 01h
    INT 16h
    JZ no_game_input
    
    ; Leer tecla
    MOV AH, 00h
    INT 16h
    
    ; Verificar teclas WASD
    CMP AL, 'w'
    JE w_key_pressed
    CMP AL, 'W'
    JE w_key_pressed
    CMP AL, 's'
    JE s_key_pressed
    CMP AL, 'S'
    JE s_key_pressed
    
    ; Verificar flechas
    CMP AH, 48h         ; Flecha arriba
    JE up_arrow_pressed
    CMP AH, 50h         ; Flecha abajo
    JE down_arrow_pressed
    
    ; Verificar ESC
    CMP AL, 1Bh
    JE esc_pressed
    
    JMP no_game_input

w_key_pressed:
    MOV AH, 1
    JMP exit_game_input
    
s_key_pressed:
    MOV AH, 2
    JMP exit_game_input
    
up_arrow_pressed:
    MOV AH, 3
    JMP exit_game_input
    
down_arrow_pressed:
    MOV AH, 4
    JMP exit_game_input
    
esc_pressed:
    MOV AH, 5
    JMP exit_game_input

no_game_input:
    MOV AH, 0

exit_game_input:
    POP DX
    POP CX
    POP BX
    RET
HANDLE_GAME_INPUT ENDP

; ============================================================
; PROCEDIMIENTOS DE CALCULO DE ANGULO DE REBOTE
; ============================================================

CALCULATE_BOUNCE_ANGLE_LEFT PROC
    PUSH AX
    PUSH BX
    PUSH CX
    
    ; Calcular posici??n relativa en el paddle 
    MOV AX, ball_y
    SUB AX, PADDLE_LEFT_Y
    
    ; Determinar zona de impacto y ajustar velocidad
    CMP AX, 10              ; Zona superior (rebote hacia arriba)
    JL bounce_up_left
    CMP AX, 30              ; Zona inferior (rebote hacia abajo)
    JG bounce_down_left
    
    ; Zona central - rebote recto
    NEG ball_dx             
    ; Mantener velocidad vertical 
    JMP end_bounce_left
    
bounce_up_left:
    NEG ball_dx             ; Cambiar direccion horizontal
    MOV ball_dy, -1         ; Velocidad vertical hacia arriba 
    JMP end_bounce_left
    
bounce_down_left:
    NEG ball_dx             ; Cambiar direccion horizontal
    MOV ball_dy, 1          ; Velocidad vertical hacia abajo 
    
end_bounce_left:
    POP CX
    POP BX
    POP AX
    RET
CALCULATE_BOUNCE_ANGLE_LEFT ENDP

; ============================================================
; PROCEDIMIENTOS COMPLETADOS DE ANGULO DE REBOTE
; ============================================================



; ============================================================
; PROCEDIMIENTOS DE CONFIGURACION DE NICKNAMES
; ============================================================

DRAW_NICKNAME_INTERFACE PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    ; Limpiar pantalla
    CLEAR_SCREEN 00h
    
    ; Marco principal decorativo
    DRAW_FILLED_BOX 80, 120, 480, 240, 01h  ; Fondo azul oscuro
    DRAW_BOX 75, 115, 490, 250, 0Fh         ; Marco blanco exterior
    DRAW_BOX 85, 125, 470, 230, 0Eh         ; Marco dorado interior
    
    ; Titulo principal
    PRINT_STRING 6, 25, nickname_title, 0Eh
    
    ; Decoraciones esquinas
    DRAW_FILLED_BOX 70, 110, 15, 15, 0Ch    ; Esquina superior izquierda
    DRAW_FILLED_BOX 555, 110, 15, 15, 0Ch   ; Esquina superior derecha
    DRAW_FILLED_BOX 70, 355, 15, 15, 0Ch    ; Esquina inferior izquierda
    DRAW_FILLED_BOX 555, 355, 15, 15, 0Ch   ; Esquina inferior derecha
    
    ; Prompt para jugador 1
    PRINT_STRING 10, 27, prompt_p1, 0Ah
    
    ; L??nea de entrada visual para P1
    DRAW_FILLED_BOX 120, 180, 400, 20, 08h  ; Fondo gris para entrada
    DRAW_BOX 115, 175, 410, 30, 0Fh         ; Marco blanco alrededor
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DRAW_NICKNAME_INTERFACE ENDP

UPDATE_NICKNAME_INTERFACE_P2 PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    ; Limpiar area del prompt anterior
    DRAW_FILLED_BOX 120, 160, 400, 50, 01h
    
    ; Actualizar prompt para jugador 2
    PRINT_STRING 10, 27, prompt_p2, 0Ah
    
    ; Nueva linea de entrada visual para P2
    DRAW_FILLED_BOX 120, 180, 400, 20, 08h  ; Fondo gris para entrada
    DRAW_BOX 115, 175, 410, 30, 0Fh         ; Marco blanco alrededor
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
UPDATE_NICKNAME_INTERFACE_P2 ENDP

CAPTURE_PLAYER1_NICKNAME PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    
    ; Posicionar cursor en el ??rea de entrada
    SET_CURSOR_POS 12, 20
    
    ; Inicializar variables
    LEA SI, player1_nickname
    XOR CX, CX                      ; Contador de caracteres
    
p1_input_loop:
    ; Esperar entrada de tecla
    MOV AH, 00h
    INT 16h
    
    ; Verificar ENTER
    CMP AL, 0Dh
    JE p1_input_done_jump
    
    ; Verificar BACKSPACE
    CMP AL, 08h
    JE p1_backspace
    
    ; Verificar si es un car??cter v??lido (letras, n??meros, espacio)
    CMP AL, 20h
    JL p1_input_loop        ; Ignorar caracteres de control
    CMP AL, 7Eh
    JG p1_input_loop        ; Ignorar caracteres extendidos
    
    ; Verificar l??mite de caracteres (m??ximo 15)
    CMP CX, 15
    JGE p1_input_loop
    
    ; Almacenar car??cter
    MOV [SI], AL
    INC SI
    INC CX
    
    ; Mostrar car??cter en pantalla
    PRINT_CHAR 12, 20, AL, 0Fh
    
    ; Mover cursor
    MOV DL, 20
    ADD DL, CL
    SET_CURSOR_POS 12, DL
    
    JMP p1_input_loop

p1_input_done_jump:
    JMP p1_input_done

p1_backspace:
    ; Verificar que hay caracteres para borrar
    CMP CX, 0
    JE p1_input_loop
    
    ; Retroceder
    DEC SI
    DEC CX
    MOV BYTE PTR [SI], '$'      ; Limpiar car??cter
    
    ; Actualizar pantalla
    MOV DL, 20
    ADD DL, CL
    SET_CURSOR_POS 12, DL
    PRINT_CHAR 12, DL, ' ', 0Fh  ; Borrar car??cter visual
    SET_CURSOR_POS 12, DL
    
    JMP p1_input_loop

p1_input_done:
    ; Terminar cadena
    MOV BYTE PTR [SI], '$'
    
    ; Si no se ingres?? nada, usar nombre por defecto
    CMP CX, 0
    JNE p1_nickname_ready
    
    ; Copiar nombre por defecto
    CALL COPY_DEFAULT_P1
    
p1_nickname_ready:
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
CAPTURE_PLAYER1_NICKNAME ENDP

CAPTURE_PLAYER2_NICKNAME PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    
    ; Posicionar cursor en el ??rea de entrada
    SET_CURSOR_POS 12, 20
    
    ; Inicializar variables
    LEA SI, player2_nickname
    XOR CX, CX                      ; Contador de caracteres
    
p2_input_loop:
    ; Esperar entrada de tecla
    MOV AH, 00h
    INT 16h
    
    ; Verificar ENTER
    CMP AL, 0Dh
    JE p2_input_done_jump
    
    ; Verificar BACKSPACE
    CMP AL, 08h
    JE p2_backspace
    
    ; Verificar si es un car??cter v??lido
    CMP AL, 20h
    JL p2_input_loop
    CMP AL, 7Eh
    JG p2_input_loop
    
    ; Verificar l??mite de caracteres
    CMP CX, 15
    JGE p2_input_loop
    
    ; Almacenar car??cter
    MOV [SI], AL
    INC SI
    INC CX
    
    ; Mostrar car??cter en pantalla
    PRINT_CHAR 12, 20, AL, 0Fh
    
    ; Mover cursor
    MOV DL, 20
    ADD DL, CL
    SET_CURSOR_POS 12, DL
    
    JMP p2_input_loop

p2_input_done_jump:
    JMP p2_input_done

p2_backspace:
    CMP CX, 0
    JE p2_input_loop
    
    DEC SI
    DEC CX
    MOV BYTE PTR [SI], '$'
    
    MOV DL, 20
    ADD DL, CL
    SET_CURSOR_POS 12, DL
    PRINT_CHAR 12, DL, ' ', 0Fh
    SET_CURSOR_POS 12, DL
    
    JMP p2_input_loop

p2_input_done:
    MOV BYTE PTR [SI], '$'
    
    CMP CX, 0
    JNE p2_nickname_ready
    
    CALL COPY_DEFAULT_P2
    
p2_nickname_ready:
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
CAPTURE_PLAYER2_NICKNAME ENDP

COPY_DEFAULT_P1 PROC
    PUSH AX
    PUSH SI
    PUSH DI
    
    LEA SI, default_p1
    LEA DI, player1_nickname
    
copy_p1_loop:
    MOV AL, [SI]
    CMP AL, '$'
    JE copy_p1_done
    MOV [DI], AL
    INC SI
    INC DI
    JMP copy_p1_loop
    
copy_p1_done:
    MOV BYTE PTR [DI], '$'
    
    POP DI
    POP SI
    POP AX
    RET
COPY_DEFAULT_P1 ENDP

COPY_DEFAULT_P2 PROC
    PUSH AX
    PUSH SI
    PUSH DI
    
    LEA SI, default_p2
    LEA DI, player2_nickname
    
copy_p2_loop:
    MOV AL, [SI]
    CMP AL, '$'
    JE copy_p2_done
    MOV [DI], AL
    INC SI
    INC DI
    JMP copy_p2_loop
    
copy_p2_done:
    MOV BYTE PTR [DI], '$'
    
    POP DI
    POP SI
    POP AX
    RET
COPY_DEFAULT_P2 ENDP

SHOW_NICKNAME_CONFIRMATION PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    ; Limpiar area de entrada
    DRAW_FILLED_BOX 100, 220, 440, 80, 01h
    
    ; Mostrar confirmaci??n
    PRINT_STRING 15, 30, config_msg, 0Ah
    PRINT_STRING 17, 20, p1_label, 0Eh
    PRINT_STRING 17, 32, player1_nickname, 0Fh
    PRINT_STRING 19, 20, p2_label, 0Eh  
    PRINT_STRING 19, 32, player2_nickname, 0Fh
    
    PRINT_STRING 22, 27, press_enter, 0Ch
    
    ; Esperar ENTER
confirmation_wait:
    MOV AH, 00h
    INT 16h
    CMP AL, 0Dh
    JNE confirmation_wait
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
SHOW_NICKNAME_CONFIRMATION ENDP

; ============================================================
; PROCEDIMIENTOS COMPLETADOS DE ANGULO DE REBOTE
; ============================================================

CALCULATE_BOUNCE_ANGLE_RIGHT PROC
    PUSH AX
    PUSH BX
    PUSH CX
    
    ; Calcular posicion relativa en el paddle
    MOV AX, ball_y
    SUB AX, PADDLE_RIGHT_Y
    
    ; Determinar zona de impacto y ajustar velocidad
    CMP AX, 10              ; Zona superior (rebote hacia arriba)
    JL bounce_up_right
    CMP AX, 30              ; Zona inferior (rebote hacia abajo)
    JG bounce_down_right
    
    ; Zona central - rebote recto
    NEG ball_dx             
    JMP end_bounce_right
    
bounce_up_right:
    NEG ball_dx             ; Cambiar direccion horizontal
    MOV ball_dy, -1         ; Velocidad vertical hacia arriba
    JMP end_bounce_right
    
bounce_down_right:
    NEG ball_dx             ; Cambiar direccion horizontal
    MOV ball_dy, 1          ; Velocidad vertical hacia abajo
    
end_bounce_right:
    POP CX
    POP BX
    POP AX
    RET
CALCULATE_BOUNCE_ANGLE_RIGHT ENDP

; ============================================================
; PROCEDIMIENTO UNIFICADO DE SALIDA
; ============================================================

SAFE_EXIT_PROGRAM PROC
    PUSH AX
    
    ; Limpiar pantalla y volver a modo texto
    CLEAR_SCREEN 00h
    SET_VIDEO_MODE 03h
    SET_CURSOR_POS 0, 0
    
    ; Mostrar mensaje de despedida
    PRINT_STRING 12, 20, exit_message, 0Eh
    
    ; Esperar tecla
    MOV AH, 00h
    INT 16h
    
    ; Salir al DOS
    MOV AH, 4Ch
    INT 21h
SAFE_EXIT_PROGRAM ENDP

END MAIN