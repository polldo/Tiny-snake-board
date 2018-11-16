/*
*	Module name: record.asm
*
*	Module description:
*		EEPROM manipulation to load and store the record of the game. There is also a routine that can be used to print the current score on the screen, given the position in input and assuming that r30 contains the score.
*
*
*	Author: Paolo Calao
*/ 


#ifndef _RECORD_
#define _RECORD_

#include "oled_driver.asm"
#include "oled_buffer_driver.asm"

.equ SCORE_X_1 = 103 

.ESEG
EEPROM_RECORD: .byte 1

.CSEG
INIT_RECORD:
		sbic	EECR, EEPE
		rjmp	INIT_RECORD
		ldi		r30, (0 << EEPM1) + (0 << EEPM0)
		out		EECR, r30
		ldi		r30, low(EEPROM_RECORD)
		out		EEARL, r30
		ldi		r30, high(EEPROM_RECORD)
		out		EEARH, r30
		clr		r30
		out		EEDR, r30
		sbi		EECR, EEMPE
		sbi		EECR, EEPE
		ret

GET_RECORD:
		sbic	EECR, EEPE
		rjmp	GET_RECORD
		ldi		r30, low(EEPROM_RECORD)
		out		EEARL, r30
		ldi		r30, high(EEPROM_RECORD)
		out		EEARH, r30
		sbi		EECR, EERE
		in		r30, EEDR
		ret

UPDATE_RECORD:
		mov		r16, r30
		rcall	GET_RECORD
		cp		r16, r30
		brlo	EXIT_UPDATE_RECORD ;if the score is not a new record don't save it
SAVE_RECORD:
		sbic	EECR, EEPE
		rjmp	SAVE_RECORD
		ldi		r30, (0<<EEPM1)+(0<<EEPM0)
		out		EECR, r30
		ldi		r30, low(EEPROM_RECORD)
		out		EEARL, r30
		ldi		r30, high(EEPROM_RECORD)
		out		EEARH, r30
		out		EEDR, r16
		sbi		EECR, EEMPE
		sbi		EECR, EEPE
EXIT_UPDATE_RECORD:
		ret


 ;input registers: r16 -> x, r17 -> y
;local registers: r9->x, r10-> y, r16->reminder, r17->result, r18, r19, r14:r15 -> temp scores
PRINT_SCORE:
		push	r20
		mov		r9, r16
		mov		r10, r17
		mov		r16, r30
		ldi		r17, 0x00
DIV_1:
		cpi		r16, 10
		brlo	SAVE_SCORE_3
		inc		r17
		subi	r16, 10
		rjmp	DIV_1
SAVE_SCORE_3:
		mov		r15, r16 ;put score3 in r15
		ldi		r16, 0
DIV_2:
		cpi		r17, 10
		brlo	PRINT_SCORES
		inc		r16 ;score1
		subi	r17, 10 ;score2
		rjmp	DIV_2
PRINT_SCORES:
		mov		r14, r17 ;put score2 in r14
		mov		r17, r9
		ldi		r18, 127
		mov		r19, r10
		ldi		r20, 7
		tst		r16
		breq	SCORE_2
		OLED_START_DRAW_CHAR
		subi	r17, -8
		mov		r9, r17
		mov		r17, r16
		subi	r17, -'0'
		rcall	OLED_DRAW_CHAR
SCORE_2:
		mov		r17, r9
		add		r16, r14 
		tst		r16
		breq	SCORE_3
		OLED_START_DRAW_CHAR
		subi	r17, -8
		mov		r9, r17
		mov		r17, r14
		subi	r17, -'0'
		rcall	OLED_DRAW_CHAR
SCORE_3:
		mov		r17, r9
		OLED_START_DRAW_CHAR
		mov		r17, r15
		subi	r17, -'0'
		rcall	OLED_DRAW_CHAR
		pop		r20
		ret

#endif
