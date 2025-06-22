Assume cs:code
Assume ds:data
Assume ss:stk
data segment 

;==========CONSTANTES DEL JUEGO=======

MIDDLE_LINE dw      200
PADDLE_SIZE dw      40
PADDLE_LEFT_X dw    1
PADDLE_RIGHT_X dw   318
PADDLE_TOP dw       1
PADDLE_MID dw       90
PADDLE_BOTTOM dw    187

BALL_MID_X dw       160
BALL_MID_Y dw       100
BALL_TOP dw     1
BALL_BOTTOM dw      199

screen_width    dw  320
paddle_right_y dw   90
paddle_left_y dw 90
ball_x dw 160
ball_y dw 100
ball_dx dw  1
ball_dy dw  1
MSG     DB  "--Ping Pong--", '$'

data ends

stk segment stack use16
;Stack size and the top of the stack defined in the stack segment
dw 100 dup(?)   ;no nescesario
stacktop:
stk ends

code segment
begin:
mov ax,data
mov ds,ax
mov ax,stk
mov ss,ax
mov sp, offset stacktop

; main program
start:
    ; set up VGA mode 13h
    call setup_vga
    
    ; set up start game menu
    
    ; process game selections
    
    ; clear the screen
    
    mov ah, 9
    mov dx, offset MSG
    int 21h
    
    game_loop:
    ; call game to handle drawing and movement
    call game
    
    ; continue game if "q" or "e" has not been pressed
    mov ah, 1h
    xor al,al
    int 16h
    cmp AL, "e"
    je  game_exit
    cmp AL, "q"
    je game_exit
    
    jmp game_loop

    game_exit:
    
    exit:
    MOV AH, 00H ; Set video mode
    MOV AL, 03H ; Mode 03h
    INT 10H ; Enter 80x25x16 mode
    ; exit game now
    MOV AH, 4Ch
    INT 21H

; subroutines

setup_vga:
    push ax bx cx dx

    mov ax, 0A000h
    mov es, ax
    mov ah, 00h
    mov al, 13h
    int 10h
    
    xor al, al
    mov dx, 3c8h
    out dx, al

    inc dx
    mov al, 11
    out dx, al
    out dx, al
    out dx, al
    
    

    pop dx cx bx ax
ret

game:
    PUSH AX BX CX DX
    
    ;wait for vsync
    vsync_active:
    MOV DX, 03DAh    ;input status port for checking retrace
    IN  AL, DX
    TEST AL, 8
    JNZ vsync_active    ; Bit 3 on signifies activity
    vsync_retrace:
    IN  AL, DX
    TEST AL, 8
    JZ vsync_retrace    ; Bit 3 off signifies retrace
    
    ; clear old ball
    mov ax, [ball_y]
    mov bx, [ball_x]
    call clear_ball
        
    ; move ball vertical
    add ax, [ball_dy]
        
    ; bounce vertical
    cmp ax, [BALL_TOP]
    jne ball_not_top
    neg [ball_dy]
    ball_not_top:
    cmp ax, [BALL_BOTTOM]
    jne ball_not_bottom
    neg [ball_dy]
    ball_not_bottom:
        
    ; move ball horizontal
    add bx, [ball_dx]
        
    ; update ball info
    mov [ball_x], bx
    mov [ball_y], ax
        
    ; get ball info
    mov ax, [ball_y]
    mov cx, [ball_x]
        
    ; check for right paddle collision / goal
    mov bx, [paddle_right_y]
    mov dx, [PADDLE_RIGHT_X]
    call collide_paddle
    
    ; check for left paddle collision / goal
    mov bx, [paddle_left_y]
    mov dx, [PADDLE_LEFT_X]
    call collide_paddle
        
    ; update ball info
    mov [ball_y],ax
    mov [ball_x],cx
    
    ; check for game type

    call move_left_paddle_player
    call move_right_paddle_player
        
        mov ax, [ball_y]
        mov bx, [ball_x]
        mov dl, 55
        call draw_ball

        ; draw right paddle
        mov ax, [paddle_right_y]
        mov bx, [PADDLE_RIGHT_X]
        mov dl, 15
        call    draw_paddle
        
        ; draw right paddle
        mov ax, [paddle_left_y]
        mov bx, [PADDLE_LEFT_X]
        mov dl, 15
        call    draw_paddle
        
        ;draw middle line
        mov ax, 1
        mov bx, 150
        mov dl, 15
        call draw_line
        
    pop dx cx bx ax
ret

; #############################################################################     
; put_pixel     
;       
; Draws a single pixel on the screen at (bx,ax) with colour dl 
; (registers preserved)     
;       
; ############################################################################# 


    
put_pixel:
    PUSH AX BX DX
    MUL [screen_width]
    ADD BX, AX
    POP DX
    MOV ES:[BX], DL
    POP BX AX
RET
    
; draw_ball
; draws the game ball 
draw_ball:
    push ax bx
    call put_pixel
    inc ax
    call put_pixel
    dec ax
    inc bx
    call put_pixel
    inc ax
    call put_pixel
    
    pop bx ax
ret

;clear_ball
clear_ball:
    push ax bx
    xor dl, dl
    call put_pixel
    inc ax
    call put_pixel
    dec ax
    inc bx
    call put_pixel
    inc ax
    call put_pixel
    pop bx ax
ret

move_right_paddle_player:
    push ax bx cx dx
    mov bx, [paddle_right_y]
    ; get shift registers
    MOV AH,02h
    INT 16h
    ;AND AL, 00001001b
    ; test for CTRL
    cmp al, 8h
    jne no_alt
    inc bx ; move paddle down
    no_alt:
    ; test for LEFT SHIFT
    cmp al, 1h
    jne no_r_shift
    dec bx ; move paddle up
    no_r_shift:
    call clamp_paddle
    mov [paddle_right_y],bx
    pop dx cx bx ax
ret

move_left_paddle_player:
push ax bx cx dx
    mov bx, [paddle_left_y]
        ; get shift registers
        MOV AH,02h
        INT 16h
        ;AND AL, 's'
        ; test for ALT
        cmp al, 4h
        jne no_ctrl
        inc bx ; move paddle down
        no_ctrl:
        ; test for RIGHT SHIFT
        cmp al, 2h
        jne no_l_shift
        dec bx ; move paddle up
        no_l_shift:
        call clamp_paddle
        mov [paddle_left_y],bx
        pop dx cx bx ax
ret

; draw_paddle
; draws a paddle (position: bx,ax colour: dl)
draw_paddle:
    MOV CX, [PADDLE_SIZE]
    draw_paddle_loop:
        call    put_pixel
        inc ax
        loop    draw_paddle_loop
    xor dl, dl ; dl = 0
    call    put_pixel
    MOV CX, [PADDLE_SIZE]
    ADD CX, 1
    SUB AX, CX
    call    put_pixel
    ret

; clamp_paddle
;   clamps bx to [PADDLE_TOP,PADDLE_BOTTOM]
clamp_paddle:
    PUSH AX
    MOV AX, [PADDLE_TOP]
    DEC AX
    CMP BX, AX
    JNE not_top
    MOV BX, [PADDLE_TOP]
    not_top:
    MOV AX, [PADDLE_BOTTOM]
    INC AX
    CMP BX, AX
    JNE not_bottom
    MOV BX, [PADDLE_BOTTOM]
    not_bottom:
    POP AX
    RET

; collide_paddle
;   collides paddle with ball
;   ax = ball_y
;   bx = paddle_y
;   cx = ball_x
;   dx = PADDLE_X
collide_paddle:
    cmp cx, dx
    jne collide_end
    cmp ax,bx
    js new_ball
    push bx
    add bx, [PADDLE_SIZE]
    cmp ax,bx
    pop bx
    jns new_ball
    neg [ball_dx]
    jmp collide_end
    
    new_ball:
    ; "randomize" ball_x
    add al, 97
    and ax, 127
    push bx
    mov bx, [BALL_MID_Y]
    sub bx, 64
    add ax, bx
    pop bx
    mov cx, [BALL_MID_X]
    ; don't bother resetting ball_dx/dy
    ; just send ball to player who just lost
    collide_end:
ret

draw_line:
    MOV CX, [MIDDLE_LINE]
    draw_line_loop:
        call    put_pixel
        inc ax
        loop    draw_line_loop
    xor dl, dl ; dl = 0
    call    put_pixel
    MOV CX, [PADDLE_SIZE]
    ADD CX, 1
    SUB AX, CX
    call    put_pixel
    ret

; Code End
code ends
end begin