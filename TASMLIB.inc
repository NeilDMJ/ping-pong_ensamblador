; TASMLIB.INC - Biblioteca de macros para modo grafico 8086
; =====================================================

;--------------------------------------------------------------
; MACRO: SET_VIDEO_MODE
;   Establece el modo de video
;   Entrada: AL = Modo de video
;--------------------------------------------------------------
SET_VIDEO_MODE MACRO mode
    mov ah,00h
    mov al,mode
    int 10h
ENDM

;--------------------------------------------------------------
; MACRO: SET_BACKGROUND_COLOR_12H
;   Establece el color de fondo en modo 12h (640x480)
;   Entrada: color = numero de color (0-15)
;--------------------------------------------------------------
SET_BACKGROUND_COLOR_12H MACRO color
    push ax
    push bx
    push cx
    push dx

    mov ah,0Bh
    mov bh,00h
    mov bl,color
    int 10h

    pop dx
    pop cx
    pop bx
    pop ax
ENDM

;--------------------------------------------------------------
; MACRO: DRAW_HORIZONTAL_LINE
;   Dibuja una linea horizontal
;   Entrada: 
;       x1 = coordenada X inicial
;       y = coordenada Y
;       length = longitud de la linea
;       col = color
;--------------------------------------------------------------
DRAW_HORIZONTAL_LINE MACRO x1, y, length, col
    LOCAL hl_loop
    push ax
    push cx
    push dx
    push si

    mov cx, x1
    mov dx, y
    mov al, col
    mov ah,0Ch

    mov si, length
hl_loop:
    int 10h
    inc cx
    dec si
    jnz hl_loop

    pop si
    pop dx
    pop cx
    pop ax
ENDM

;--------------------------------------------------------------
; MACRO: DRAW_VERTICAL_LINE
;   Dibuja una linea vertical
;   Entrada: 
;       x = coordenada X
;       y1 = coordenada Y inicial
;       length = longitud de la linea
;       col = color
;--------------------------------------------------------------
DRAW_VERTICAL_LINE MACRO x, y1, length, col
    LOCAL vl_loop
    push ax
    push cx
    push dx
    push si

    mov cx, x
    mov dx, y1
    mov al, col
    mov ah,0Ch

    mov si, length
vl_loop:
    int 10h
    inc dx
    dec si
    jnz vl_loop

    pop si
    pop dx
    pop cx
    pop ax
ENDM

;--------------------------------------------------------------
; MACRO: DRAW_BOX
;   Dibuja un rectangulo
;   Entrada: 
;       x = coordenada X superior izquierda
;       y = coordenada Y superior izquierda
;       width = ancho
;       height = alto
;       col = color
;--------------------------------------------------------------
DRAW_BOX MACRO x, y, width, height, col
    ; Lado superior
    DRAW_HORIZONTAL_LINE x, y, width, col

    ; Lado inferior
    mov ax, y
    add ax, height
    dec ax
    DRAW_HORIZONTAL_LINE x, ax, width, col

    ; Lado izquierdo
    DRAW_VERTICAL_LINE x, y, height, col

    ; Lado derecho
    mov ax, x
    add ax, width
    dec ax
    DRAW_VERTICAL_LINE ax, y, height, col
ENDM

;--------------------------------------------------------------
; MACRO: DRAW_FILLED_BOX
;   Dibuja un rectangulo relleno
;   Entrada: 
;       x = coordenada X superior izquierda
;       y = coordenada Y superior izquierda
;       width = ancho
;       height = alto
;       col = color
;--------------------------------------------------------------
DRAW_FILLED_BOX MACRO x, y, width, height, col
    LOCAL y_loop, x_loop
    push ax
    push cx
    push dx
    push si
    push di

    mov cx, x
    mov dx, y
    mov al, col
    mov ah,0Ch

    mov di, height
y_loop:
    push di
    mov di, width
    mov cx, x
x_loop:
    int 10h
    inc cx
    dec di
    jnz x_loop

    inc dx
    pop di
    dec di
    jnz y_loop

    pop di
    pop si
    pop dx
    pop cx
    pop ax
ENDM

;--------------------------------------------------------------
; MACRO: PRINT_STRING
;   Imprime una cadena en modo grafico usando BIOS
;   Entrada:
;       row = fila (0-29)
;       col = columna (0-79)
;       msg = offset del mensaje
;       color = atributo de color
;--------------------------------------------------------------
PRINT_STRING MACRO row, col, msg, color
    push ax
    push bx
    push dx
    
    ; Posicionar cursor
    mov ah,02h
    mov bh,00h
    mov dh,row
    mov dl,col
    int 10h

    ; Configurar color y escribir
    mov ah,09h
    mov bl,color
    mov dx, OFFSET msg
    int 21h

    pop dx
    pop bx
    pop ax
ENDM

; -------------------------------------------------------------
; PRINT_CHAR:
;   Dibuja un solo caracter en modo texto/BIOS (INT 10h).
;
; Par?metros:
;   row   
;   col   = columna (0?79)
;   ch    = el car?cter ASCII a imprimir (p. ej. 'A', 'B', 0x31, etc.)
;   color = atributo de color (bit alto = fondo, bit bajo = primer plano)
;-------------------------------------------------------------
PRINT_CHAR MACRO row, col, char, color
    push  ax
    push  bx
    push  cx    ; usaremos CX como registro de respaldo (opcional)

    ; 1) Posicionar cursor de texto en (row, col):
    mov   ah, 02h
    mov   bh, 0          ; pagina de video 0
    mov   dh, row
    mov   dl, col
    int   10h

    ; 2) Escribir el car?cter con INT 10h AH=0Eh:
    mov   ah, 0Eh
    mov   al, char         ; AL = ASCII del car?cter
    mov   bl, color      ; BL = atributo (color)
    mov   bh, 0          ; p?gina de video 0
    int   10h

    pop   cx
    pop   bx
    pop   ax
ENDM

;--------------------------------------------------------------
; MACRO: DRAW_BUTTON
;   Dibuja un bot?n con texto
;   Entrada:
;       x, y = posici?n en p?xeles
;       width, height = tama?o en p?xeles
;       btn_color = color de relleno del bot?n
;       text_row, text_col = fila/columna (modo texto)
;       text = offset del texto
;       text_color = color del texto
;--------------------------------------------------------------
DRAW_BUTTON MACRO x, y, width, height, btn_color, text_row, text_col, text, text_color
    ; Fondo del bot?n
    DRAW_FILLED_BOX x, y, width, height, btn_color
    ; Borde blanco
    DRAW_BOX x, y, width, height, 15
    ; Texto en modo texto
    PRINT_STRING text_row, text_col, text, text_color
ENDM

;--------------------------------------------------------------
; MACRO: CLEAR_SCREEN
;   Limpia la pantalla completa con un color
;   Entrada: color = color de fondo
;--------------------------------------------------------------
CLEAR_SCREEN MACRO color
    push ax
    push bx
    push cx
    push dx

    mov ax,0600h
    mov bh,color
    mov cx,0000h
    mov dx,184Fh
    int 10h

    pop dx
    pop cx
    pop bx
    pop ax
ENDM

;--------------------------------------------------------------
; MACRO: WAIT_KEY
;   Espera hasta que se presione una tecla
;   Salida: AH = scan code, AL = ASCII
;--------------------------------------------------------------
WAIT_KEY MACRO
    mov ah,00h
    int 16h
ENDM

;--------------------------------------------------------------
; MACRO: SET_CURSOR_POS
;   Establece la posicion del cursor (modo texto)
;   Entrada: DH = fila, DL = columna
;--------------------------------------------------------------
SET_CURSOR_POS MACRO row, col
    push ax
    push bx

    mov ah,02h
    mov bh,00h
    mov dh,row
    mov dl,col
    int 10h

    pop bx
    pop ax
ENDM

;--------------------------------------------------------------
; MACRO: CHECK_KEY
;   Verifica si se ha presionado una tecla especifica
;   Entrada:
;       keycode = codigo ASCII de la tecla a verificar
;       handler = etiqueta a la que saltar si se presiona
;--------------------------------------------------------------
CHECK_KEY MACRO keycode, handler
    LOCAL no_key, exit_check
    
    ; Verificar si hay tecla disponible
    mov ah, 01h
    int 16h
    jz no_key
    
    ; Leer tecla sin remover del buffer
    mov ah, 00h
    int 16h
    
    ; Comparar con el c??digo deseado
    cmp al, keycode
    jne no_key
    
    ; Si coincide, saltar al handler
    jmp handler

no_key:
    ; Continuar con la ejecuci??n
    
exit_check:
ENDM

;--------------------------------------------------------------
; MACRO: COMPARE_FILA
;   Compara una fila de la matriz de palabras con una cadena ingresada
;   Entrada: 
;       n      = n??mero de fila a comparar (entero)
;       cadena = offset de la cadena ingresada por el usuario
;   Salida:
;       AL = 1 si las cadenas son iguales
;       AL = 0 si las cadenas son diferentes
;--------------------------------------------------------------

COMPARE_FILA MACRO n, cadena
    LOCAL comparar, fin, no_igual, espacio, igual

    ; Cargar direcci??n base de PALABRAS
    mov si, OFFSET PALABRAS
    mov ax, n
    mov bx, 8            ; Cambiado de 7 a 8 (longitud correcta de cada fila)
    mul bx               ; AX = n * 8
    add si, ax           ; SI apunta al inicio de la fila n

    mov di, OFFSET cadena

comparar:
    mov al, [si]
    mov ah, [di]

    ; Si ambos terminan, son iguales
    cmp al, ' '
    je espacio
    cmp ah, '$'
    je espacio

    cmp al, ah
    jne no_igual

    inc si
    inc di
    jmp comparar

espacio:
    ; Verificar que ambos terminaron al mismo tiempo
    cmp al, ' '
    jne no_igual
    cmp ah, '$'
    jne no_igual

igual:
    
    mov al, 1        ; iguales
    jmp fin

no_igual:
    
    mov al, 0        ; diferentes

fin:
ENDM   


;--------------------------------------------------------------
; MACRO: LEER_CADENA_ENTER
;   Lee una cadena desde el teclado hasta presionar ENTER
;   Entrada: 
;       etiqueta_buffer = direcci??n (etiqueta) donde se almacenar?? la cadena
;       maximo = n??mero m??ximo de caracteres permitidos
;   Salida:
;       Almacena la cadena ingresada en el buffer, terminada con '$'
;       (Formato compatible con impresi??n mediante INT 21h AH=09h)
;--------------------------------------------------------------

LEER_CADENA_ENTER MACRO etiqueta_buffer, maximo
    LOCAL leer_loop, fin_lectura

    push ax
    push bx
    push cx
    push dx
    push si

    mov si, OFFSET etiqueta_buffer ; SI apunta al buffer
    xor cx, cx                     ; CX cuenta caracteres

leer_loop:
    mov ah, 01h
    int 21h                        ; Leer caracter en AL

    cmp al, 13                     ; ?ENTER?
    je fin_lectura

    mov [si], al                  ; Guardar AL en [SI]
    inc si
    inc cx
    cmp cx, maximo
    jb leer_loop                  ; Si a?n no alcanza el m?ximo, repetir

fin_lectura:
    mov byte ptr [si], '$'        ; Terminar cadena con '$'

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
ENDM

;--------------------------------------------------------------
; MACRO: LIMPIAR_BUFFER
;   Limpia un ??rea de memoria (buffer) llen??ndola con el car??cter '$'
;   Entrada:
;       etiqueta = etiqueta (offset) del buffer a limpiar
;       longitud = n??mero de caracteres a llenar con '$'
;   Salida:
;       Llena el buffer indicado con caracteres '$'
;--------------------------------------------------------------

LIMPIAR_BUFFER MACRO etiqueta, longitud
    LOCAL limpiar_loop

    push ax
    push di
    push cx

    lea di, etiqueta       
    mov cx, longitud       
    mov al, '$'              

limpiar_loop:
    stosb                  
    loop limpiar_loop

    pop cx
    pop di
    pop ax
ENDM

;--------------------------------------------------------------
; MACRO: GET_SYSTEM_TIME
;   Obtiene el tiempo del sistema
;   Salida: CH=hora, CL=minutos, DH=segundos, DL=cent??simas
;--------------------------------------------------------------
GET_SYSTEM_TIME MACRO
    push ax
    mov ah, 2Ch
    int 21h
    pop ax
ENDM

;--------------------------------------------------------------
; MACRO: CHECK_KEY_BUFFER
;   Verifica si hay una tecla en el buffer sin leerla
;   Salida: ZF=1 si no hay tecla, ZF=0 si hay tecla disponible
;--------------------------------------------------------------
CHECK_KEY_BUFFER MACRO
    push ax
    mov ah, 01h
    int 16h
    pop ax
ENDM

;--------------------------------------------------------------
; MACRO: READ_KEY_SCAN
;   Lee una tecla del buffer del teclado
;   Salida: AL=ASCII, AH=scan code
;--------------------------------------------------------------
READ_KEY_SCAN MACRO
    mov ah, 00h
    int 16h
ENDM

;--------------------------------------------------------------
; MACRO: FLUSH_KEY_BUFFER
;   Limpia el buffer del teclado
;--------------------------------------------------------------
FLUSH_KEY_BUFFER MACRO
    LOCAL flush_loop, buffer_empty
flush_loop:
    mov ah, 01h
    int 16h
    jz buffer_empty
    mov ah, 00h
    int 16h
    jmp flush_loop
buffer_empty:
ENDM

;--------------------------------------------------------------
; MACRO: DETECT_ENTER
;   Detecta espec??ficamente la tecla ENTER
;   Salida: CF=1 si es ENTER, CF=0 si no es ENTER
;--------------------------------------------------------------
DETECT_ENTER MACRO
    LOCAL not_enter, is_enter
    cmp al, 0Dh
    jne not_enter
is_enter:
    stc                 ; CF=1
    jmp %%exit_detect
not_enter:
    clc                 ; CF=0
%%exit_detect:
ENDM

;--------------------------------------------------------------
; MACRO: DETECT_F12
;   Detecta espec??ficamente la tecla F12
;   Salida: CF=1 si es F12, CF=0 si no es F12
;--------------------------------------------------------------
DETECT_F12 MACRO
    LOCAL not_f12, is_f12
    cmp ah, 58h         ; Scan code de F12
    jne not_f12
is_f12:
    stc                 ; CF=1
    jmp %%exit_f12
not_f12:
    clc                 ; CF=0
%%exit_f12:
ENDM

;--------------------------------------------------------------
; MACRO: DETECT_WASD
;   Detecta las teclas W, A, S, D (may??sculas y min??sculas)
;   Salida: 
;       AL='W' o 'w' -> AH=1
;       AL='A' o 'a' -> AH=2  
;       AL='S' o 's' -> AH=3
;       AL='D' o 'd' -> AH=4
;       Otra tecla   -> AH=0
;--------------------------------------------------------------
DETECT_WASD MACRO
    LOCAL check_w, check_a, check_s, check_d, not_wasd
    
    ; Verificar W/w
check_w:
    cmp al, 'W'
    je w_detected
    cmp al, 'w'
    je w_detected
    jmp check_a
w_detected:
    mov ah, 1
    jmp %%exit_wasd

    ; Verificar A/a
check_a:
    cmp al, 'A'
    je a_detected
    cmp al, 'a'
    je a_detected
    jmp check_s
a_detected:
    mov ah, 2
    jmp %%exit_wasd

    ; Verificar S/s
check_s:
    cmp al, 'S'
    je s_detected
    cmp al, 's'
    je s_detected
    jmp check_d
s_detected:
    mov ah, 3
    jmp %%exit_wasd

    ; Verificar D/d
check_d:
    cmp al, 'D'
    je d_detected
    cmp al, 'd'
    je d_detected
    jmp not_wasd
d_detected:
    mov ah, 4
    jmp %%exit_wasd

not_wasd:
    mov ah, 0
%%exit_wasd:
ENDM

;--------------------------------------------------------------
; MACRO: DETECT_ARROWS
;   Detecta las teclas de flecha
;   Salida: 
;       Flecha arriba  -> AH=1
;       Flecha abajo   -> AH=2
;       Flecha izq     -> AH=3
;       Flecha der     -> AH=4
;       Otra tecla     -> AH=0
;--------------------------------------------------------------
DETECT_ARROWS MACRO
    LOCAL check_up, check_down, check_left, check_right, not_arrow
    
    ; Verificar flecha arriba
check_up:
    cmp ah, 48h
    jne check_down
    mov ah, 1
    jmp %%exit_arrows

    ; Verificar flecha abajo
check_down:
    cmp ah, 50h
    jne check_left
    mov ah, 2
    jmp %%exit_arrows

    ; Verificar flecha izquierda
check_left:
    cmp ah, 4Bh
    jne check_right
    mov ah, 3
    jmp %%exit_arrows

    ; Verificar flecha derecha
check_right:
    cmp ah, 4Dh
    jne not_arrow
    mov ah, 4
    jmp %%exit_arrows

not_arrow:
    mov ah, 0
%%exit_arrows:
ENDM

;--------------------------------------------------------------
; MACRO: SIMPLE_FAST_TRANSITION
;   Transici??n simplificada sin bucles complejos
;   Entrada: new_mode = nuevo modo de video
;--------------------------------------------------------------
SIMPLE_FAST_TRANSITION MACRO new_mode
    push ax
    SET_VIDEO_MODE new_mode
    SET_BACKGROUND_COLOR_12H 00h
    pop ax
ENDM

;--------------------------------------------------------------
; MACRO: SIMPLE_FLUSH_KEYS
;   Limpieza simplificada del buffer
;--------------------------------------------------------------
SIMPLE_FLUSH_KEYS MACRO
    LOCAL flush_start, buffer_clean
    push ax
flush_start:
    mov ah, 01h
    int 16h
    jz buffer_clean
    mov ah, 00h
    int 16h
    jmp flush_start
buffer_clean:
    pop ax
ENDM

;--------------------------------------------------------------
; MACRO: SIMPLE_SAFE_EXIT
;   Salida segura simplificada al modo texto
;--------------------------------------------------------------
SIMPLE_SAFE_EXIT MACRO
    push ax
    SIMPLE_FLUSH_KEYS
    SET_VIDEO_MODE 03h
    SET_CURSOR_POS 0, 0
    pop ax
ENDM

;--------------------------------------------------------------
; MACRO: GAME_INPUT_HANDLER
;   Maneja la entrada del juego de forma optimizada
;   Salida: AL=c??digo de tecla, AH=tipo de control
;   AH=0: Sin entrada v??lida
;   AH=1: Jugador 1 arriba (W)
;   AH=2: Jugador 1 abajo (S)  
;   AH=3: Jugador 2 arriba (flecha arriba)
;   AH=4: Jugador 2 abajo (flecha abajo)
;   AH=5: Pausa/Menu (ESC)
;--------------------------------------------------------------
GAME_INPUT_HANDLER MACRO
    LOCAL no_input, check_wasd_keys, check_arrow_keys, check_esc
    
    CHECK_KEY_BUFFER
    jz no_input
    
    READ_KEY_SCAN
    
    ; Verificar teclas WASD
check_wasd_keys:
    DETECT_WASD
    cmp ah, 1           ; W detectada
    je player1_up
    cmp ah, 3           ; S detectada  
    je player1_down
    jmp check_arrow_keys

player1_up:
    mov ah, 1
    jmp %%exit_input
    
player1_down:
    mov ah, 2
    jmp %%exit_input

    ; Verificar flechas
check_arrow_keys:
    DETECT_ARROWS
    cmp ah, 1           ; Flecha arriba
    je player2_up
    cmp ah, 2           ; Flecha abajo
    je player2_down
    jmp check_esc

player2_up:
    mov ah, 3
    jmp %%exit_input
    
player2_down:
    mov ah, 4
    jmp %%exit_input

    ; Verificar ESC
check_esc:
    cmp al, 1Bh         ; ESC
    jne no_input
    mov ah, 5
    jmp %%exit_input

no_input:
    mov ah, 0
%%exit_input:
ENDM

;--------------------------------------------------------------
; MACRO: SIMPLE_MENU_INPUT_HANDLER  
;   Versi??n simplificada para evitar problemas de saltos largos
;   Salida: AH=acci??n detectada
;   AH=0: Sin entrada v??lida
;   AH=1: ENTER (iniciar juego)
;   AH=2: F12 (salir)
;--------------------------------------------------------------
SIMPLE_MENU_INPUT_HANDLER MACRO
    LOCAL no_input, enter_key, f12_key, exit_simple
    push bx
    push cx
    
    ; Verificar si hay tecla
    mov ah, 01h
    int 16h
    jz no_input
    
    ; Leer tecla
    mov ah, 00h
    int 16h
    
    ; Verificar ENTER
    cmp al, 0Dh
    je enter_key
    
    ; Verificar F12
    cmp ah, '9'
    je f12_key
    
    ; Sin entrada v??lida
no_input:
    mov ah, 0
    jmp exit_simple
    
enter_key:
    mov ah, 1
    jmp exit_simple
    
f12_key:
    mov ah, 2
    jmp exit_simple
    
exit_simple:
    pop cx
    pop bx
ENDM