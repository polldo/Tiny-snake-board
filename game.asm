/*
*	Module name: game.asm
*
*	Module description:
*		This file contains all the routines concering the application execution. Here the game's logic is implemented.
*		This module is heavily used by the main loop in 'main.asm' module.
*
*
*	Author: Paolo Calao
*/ 

#ifndef _GAME_
#define _GAME_

#include "oled_driver.asm"
#include "oled_buffer_driver.asm"

INIT_SNAKE:
	;tail: r20->x2:r21->y2, r22->x1:r23->y1, head: r24->x2:r25->y2, r26->x1:r27->y1, fruit: r28->x, r29->y, score: r30, control byte: r31
;tail
		ldi		r22, 6
		ldi		r23, 24
		ldi		r20, 5
		ldi		r21, 24
		mov		r16, r22
		mov		r17, r23
		rcall	OLED_SET_PIXEL
		inc		r17
		rcall	OLED_SET_PIXEL
		mov		r16, r20
		mov		r17, r21
		rcall	OLED_SET_PIXEL
		inc		r17
		rcall	OLED_SET_PIXEL
;head
		ldi		r26, 8
		ldi		r27, 24
		ldi		r24, 7
		ldi		r25, 24
		mov		r16, r26
		mov		r17, r27
		rcall	OLED_SET_PIXEL
		inc		r17
		rcall	OLED_SET_PIXEL
		dec		r16
		rcall	OLED_SET_PIXEL
		dec		r17
		rcall	OLED_SET_PIXEL
;fruit
		ldi		r28, 18;10
		ldi		r29, 24;40
		mov		r16, r28
		mov		r17, r29
		rcall	OLED_SET_PIXEL
		inc		r17
		rcall	OLED_SET_PIXEL
INIT_CONTROL_BYTE:
		ldi		r31, 0x04	;start going right
		ret
 
.macro UPDATE_HEAD
		mov		r16, r24
		mov		r17, r25
		rcall	OLED_SET_PIXEL
		inc		r17
		rcall	OLED_SET_PIXEL
		mov		r16, r26
		mov		r17, r27
		rcall	OLED_SET_PIXEL
		inc		r17
		rcall	OLED_SET_PIXEL
.endmacro

.macro DELETE_HEAD
		mov		r16, r24
		mov		r17, r25
		rcall	OLED_CLEAR_PIXEL
		inc		r17
		rcall	OLED_CLEAR_PIXEL
		mov		r16, r26
		mov		r17, r27
		rcall	OLED_CLEAR_PIXEL
		inc		r17
		rcall	OLED_CLEAR_PIXEL
.endmacro

.macro DELETE_TAIL
		mov		r16, r20
		mov		r17, r21
		rcall	OLED_CLEAR_PIXEL
		inc		r17
		rcall	OLED_CLEAR_PIXEL
		mov		r16, r22
		mov		r17, r23
		rcall	OLED_CLEAR_PIXEL
		inc		r17
		rcall	OLED_CLEAR_PIXEL
.endmacro

.macro UPDATE_TAIL
		mov		r16, r22
		mov		r17, r23
		subi	r17, -2
		rcall	OLED_GET_PIXEL
		sbrc	r18, 0
		rjmp	UPDATE_BOTTOM
		subi	r17, 4
		rcall	OLED_GET_PIXEL
		sbrc	r18, 0
		rjmp	UPDATE_TOP
		inc		r16
		subi	r17, -2
		rcall	OLED_GET_PIXEL
		sbrc	r18, 0
		rjmp	UPDATE_RIGHT
UPDATE_LEFT:
		dec		r22
		mov		r20, r22
		mov		r21, r23
		dec		r22
		rjmp	END
UPDATE_RIGHT:
		inc		r22
		mov		r20, r22
		mov		r21, r23
		inc		r22
		rjmp	END
UPDATE_TOP:
		subi	r23, 2
		mov		r20, r22
		mov		r21, r23
		subi	r23, 2
		rjmp	END
UPDATE_BOTTOM:
		subi	r23, -2
		mov		r20, r22
		mov		r21, r23
		subi	r23, -2
END:
.endmacro

.macro NEW_FRUIT
		push	zl
		push	zh
		clr		r1
		clr		r19
SEARCH_AVAILABLE_POSITION:
		ldi		zh, high(FRUIT_POSITIONS * 2)
		ldi		zl, low(FRUIT_POSITIONS * 2)
		in		r18, TCNT0
		andi	r18, 0x1E
		add		zl, r18
		adc		zh, r1
		lpm		r16, z+
		lpm		r17, z
		rcall	OLED_GET_PIXEL
		sbrc	r18, 0
		rjmp	SEARCH_AVAILABLE_POSITION
		mov		r28, r16
		mov		r29, r17
		rcall	OLED_SET_PIXEL
		inc		r17
		rcall	OLED_SET_PIXEL
		pop		zh
		pop		zl
.endmacro

FRUIT_POSITIONS: .db	14, 8, 18, 24, 24, 4, 30, 8, 10, 4, 20, 16, 60, 32, 24, 40, 60, 8, 32, 32, \
						14, 4, 18, 8, 24, 12, 30, 16, 10, 20, 20, 24, 60, 28, 24, 32, 60, 36, 32, 40, \
						6, 32, 16, 24, 20, 4, 8, 8, 4, 44, 26, 16, 50, 32, 54, 40, 38, 8, 36, 32, 12, 44

NEXT_MOVE:
		sbrs	r31, 0
		rjmp	NO_TURN
		sbrc	r31, 1
		rjmp	TURN_RIGHT
TURN_LEFT:
		sbrc	r31, 2
		rjmp	GO_UP
		sbrc	r31, 3
		rjmp	GO_DOWN
		sbrc	r31, 4
		rjmp	GO_RIGHT
		sbrc	r31, 5
		rjmp	GO_LEFT
TURN_RIGHT:
		sbrc	r31, 2
		rjmp	GO_DOWN
		sbrc	r31, 3
		rjmp	GO_UP
		sbrc	r31, 4
		rjmp	GO_LEFT
		sbrc	r31, 5
		rjmp	GO_RIGHT
NO_TURN:
		sbrc	r31, 2
		rjmp	GO_RIGHT
		sbrc	r31, 3
		rjmp	GO_LEFT
		sbrc	r31, 4
		rjmp	GO_DOWN
		sbrc	r31, 5
		rjmp	GO_UP
GO_UP:
		ldi		r31, 0x20
		mov		r24, r26
		mov		r25, r27
		subi	r27, 4
		subi	r25, 2
		rjmp	END_MOVE
GO_DOWN:
		ldi		r31, 0x10
		mov		r24, r26
		mov		r25, r27
		subi	r27, -4
		subi	r25, -2
		rjmp	END_MOVE
GO_LEFT:
		ldi		r31, 0x08
		mov		r24, r26
		mov		r25, r27
		subi	r26, 2
		dec		r24
		rjmp	END_MOVE
GO_RIGHT:
		ldi		r31, 0x04
		mov		r24, r26
		mov		r25, r27
		subi	r26, -2
		inc		r24
END_MOVE:
		ret

;Check collision between the next position of the head (r24:r25:r26:r27) and any obstacle.
CHECK_COLLISION:
		mov		r16, r26
		mov		r17, r27
		rcall	OLED_GET_PIXEL
		mov		r19, r18
		mov		r16, r24
		mov		r17, r25
		rcall	OLED_GET_PIXEL
		or		r18, r19
		sbrc	r18, 0 ;check if there was a collision
		rjmp	COLLISION_FRUIT ;if there was a collision then check if a fruit was envolved
NO_COLLISION:
		;update head
		UPDATE_HEAD
		;delete tail
		DELETE_TAIL
		UPDATE_TAIL
		rjmp	END_COLLISION
COLLISION_FRUIT:
		;check if collided with a fruit
		mov		r16, r26
		eor		r16, r28
		brne	COLLISION_WALL_SNAKE
		mov		r17, r27
		eor		r17, r29
		brne	COLLISION_WALL_SNAKE
		;update head
		UPDATE_HEAD
		;increase score
		inc		r30
		ldi		r16, SCORE_X_1
		ldi		r17, 0
		rcall	PRINT_SCORE
		;new fruit
		NEW_FRUIT
		rcall	INIT_TIMER_NOTE
		rjmp	END_COLLISION
COLLISION_WALL_SNAKE:
		;game over
		UPDATE_HEAD
		clr		r11
END_COLLISION:
		ret


GAME_OVER:
		;save score if it is a new record
		rcall	UPDATE_RECORD
		rcall	OLED_SEND_DISPLAY_TABLE
		rcall	INIT_TIMER_NOTE
		rcall	SHORT_DELAY
		rcall	STOP_TIMER_NOTE
		rcall	SHORT_DELAY
		rcall	INIT_TIMER_NOTE
		rcall	SHORT_DELAY
		rcall	STOP_TIMER_NOTE
		rcall	OLED_CLEAR_DISPLAY_TABLE
		rcall	OLED_SEND_DISPLAY_TABLE
		ldi		r17, 28
		ldi		r18, 127
		ldi		r19, 5
		ldi		r20, 6
		OLED_START_DRAW_CHAR
		DRAW_CHAR 'G'
		DRAW_CHAR 'A'
		DRAW_CHAR 'M'
		DRAW_CHAR 'E'
		DRAW_CHAR ' '
		DRAW_CHAR 'O'
		DRAW_CHAR 'V'
		DRAW_CHAR 'E'
		DRAW_CHAR 'R'
		rcall	DELAY
		rcall	DELAY
		ret

#endif
