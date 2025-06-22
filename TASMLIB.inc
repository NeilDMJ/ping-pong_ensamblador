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
    
    ; Comparar con el c?digo deseado
    cmp al, keycode
    jne no_key
    
    ; Tecla coincide - ejecutar handler
    jmp handler

no_key:
    ; Continuar sin hacer nada
    jmp exit_check
    
exit_check:
ENDM

;--------------------------------------------------------------
; MACRO: COMPARE_FILA
;   Compara una fila de la matriz de palabras con una cadena ingresada
;   Entrada: 
;       n      = número de fila a comparar (entero)
;       cadena = offset de la cadena ingresada por el usuario
;   Salida:
;       AL = 1 si las cadenas son iguales
;       AL = 0 si las cadenas son diferentes
;--------------------------------------------------------------

COMPARE_FILA MACRO n, cadena
    LOCAL comparar, fin, no_igual, espacio, igual

    ; Cargar dirección base de PALABRAS
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
;       etiqueta_buffer = dirección (etiqueta) donde se almacenará la cadena
;       maximo = número máximo de caracteres permitidos
;   Salida:
;       Almacena la cadena ingresada en el buffer, terminada con '$'
;       (Formato compatible con impresión mediante INT 21h AH=09h)
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
;   Limpia un área de memoria (buffer) llenándola con el carácter '$'
;   Entrada:
;       etiqueta = etiqueta (offset) del buffer a limpiar
;       longitud = número de caracteres a llenar con '$'
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
