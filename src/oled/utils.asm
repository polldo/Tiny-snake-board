/*
*	Module name: utils.asm
*
*	Module description:
*		This module contains some useful routines like delays and simple math.
*
*
*	Author: Paolo Calao
*/ 


 ;math support functions for oled_driver

#ifndef _UTILS_
#define _UTILS_

DELAY:
		push	r16
		push	r17
		push	r18
		ldi		r18, 2
DELAY_3:
		ldi		r17, 0xFF
DELAY_2:
		ldi		r16, 0xFF
DELAY_1:
		dec		r16
		brne	DELAY_1
		dec		r17
		brne	DELAY_2
		dec		r18
		brne	DELAY_3
		pop		r18
		pop		r17
		pop		r16
		ret

SHORT_DELAY:
		push	r16
		push	r17
		ldi		r17, 0xFF
SHORT_DELAY_2:
		ldi		r16, 0xFF
SHORT_DELAY_1:
		dec		r16
		brne	SHORT_DELAY_1
		dec		r17
		brne	SHORT_DELAY_2
		pop		r17
		pop		r16
		ret


 ;input r17 -> mod ; output: r18 -> byte shifted
.macro SHIFT_MOD_SET_MASK
		ldi		r18, 0x01
		tst		r17
SHIFT_MOD_SET_LOOP:
		breq	SHIFT_MOD_SET_END
		lsl		r18
		dec		r17
		rjmp	SHIFT_MOD_SET_LOOP
SHIFT_MOD_SET_END:
.endmacro


;inputs: r17 -> y; outputs: r16 -> y/8, r17 -> y%8
DIV_MOD_8:
		ldi		r16, 0x00
DIV_LOOP:
		cpi		r17, 0x08
		brlo	DIV_END
		subi	r17, 0x08
		inc		r16
		rjmp	DIV_LOOP
DIV_END:
		ret


	;input r17 output: r19:r18
MUL_8:
		ldi		r19, 0x00
		mov		r18, r17
		;mul by 2
		lsl		r19
		sbrc	r18, 7
		sbr		r19, 0x01
		lsl		r18
		;mul by 4
		lsl		r19
		sbrc	r18, 7
		sbr		r19, 0x01
		lsl		r18
		;mul by 8
		lsl		r19
		sbrc	r18, 7
		sbr		r19, 0x01
		lsl		r18
		ret

	;input: r16 -> page , r18 -> columns;  output: r16 -> 0, yl -> low result , yh -> high result
MUL_COLS_PAGE:
		ldi		r18, DISPLAY_TABLE_COLS
MUL_COLS_LOOP:
		tst		r16
		breq	MUL_COLS_END
		dec		r16
		add		yl, r18
		adc		yh, r1
		rjmp	MUL_COLS_LOOP
MUL_COLS_END:
		ret

#endif
