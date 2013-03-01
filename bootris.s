%define HEIGHT 22
KEYBOARD_INTERRUPT EQU 9
TIMER_INTERRUPT EQU 8

TIMER_MOD EQU 0

STACK_SEGMENT EQU 09000h	; Top of conventional memory
STACK_SIZE EQU 0ffffh		; 64K - 1 bytes of stack

ORG 0x7C00

block_L: db 0x17,0
		 db 0x22,0x30
		 db 0x71,0
		 db 0x30,0x22

; initialize the stack
cli
push word 0
pop ds
mov [4 * KEYBOARD_INTERRUPT], word keyboard_interrupt
mov [4 * KEYBOARD_INTERRUPT + 2], cs
mov [4 * TIMER_INTERRUPT], word timer_interrupt
mov [4 * TIMER_INTERRUPT + 2], cs
mov sp, STACK_SEGMENT
mov ss, sp
mov sp, STACK_SIZE
push cs
pop ds
; and jump to the main code
jmp 0x0000:start

title: dw 'TETRIS'
world1: times 32 db 205

start:
	mov word [counter], 0
	mov byte [timer_mod], 100
	call BiosClearScreen
	mov ax, title
	mov dh,0
	mov dl,37
	mov cx,6
	call puts
	call draw_boarder
	mov word [next_obj],block_L
	
	;start game
	sti
	hlt

do_new_object:
	mov word ax, [next_obj]
	mov word [current_obj], ax
	mov byte [obj_height],0
	mov byte [offset],0
	mov byte [rotation],0
	ret

draw_boarder:
	mov dh, 1
	mov dl,24
	mov cx, 32
	mov ax, world1
	call puts
	add dh, HEIGHT
	call puts
	
	dec dh
	.loop: 
		mov dl, 23
		mov ax, 0x0200
		xor bx, bx
		int 0x10
		mov cx, 1
		mov ah, 0x0A
		mov al, 186
		int 0x10
		mov dl, 56
		mov ax, 0x0200
		xor bx, bx
		int 0x10
		mov cx, 1
		mov ah, 0x0A
		mov al, 186
		int 0x10
		dec dh
		
		cmp dh, 1
		jnz .loop
	ret

puts:
	pusha
	mov bp, ax
	mov ax, 0x1300
	mov bx, 7
	int 0x10
	popa
	ret
	
do_game_tick:
	call draw_boarder
	ret

keyboard_interrupt:
	; save our registers!
	pusha
	in al, 60h
	; Ignore codes with high bit set
	test al, 80h
	jnz EOI
	; Read the ASCII code from the table
	mov cx, 1
	mov ah, 0x0A
	int 0x10
	jmp EOI

timer_interrupt:
	pusha
	mov ax, [counter]
	or ax, ax
	jnz .end
	; we hit zero! Do the game tick...
	call do_game_tick
	mov word [counter], 10
	mov cx, 1
	mov ah, 0x0A
	int 0x10
	.end:
	dec word [counter]
	; fall through
EOI:
	mov al, 20h
	out 20h, al
	popa
	iret

BiosClearScreen:
	pusha
	mov ax,0x0600   ; clear the "window"
	xor cx, cx
	mov dx,0x184f   ; to (24,79)
	mov bh,0x07     ; keep light grey display
	int 0x10
	popa
	ret

; last two bytes must be 55 AA
times 510-($-$$) db 0
db 0x55
db 0xAA

absolute 0x7e00
counter: resw 1
timer_mod: resb 1
arena: times HEIGHT resw 1
current_obj: resw 1
next_obj: resw 1
obj_height: resb 1
offset: resb 1
rotation: resb 1
