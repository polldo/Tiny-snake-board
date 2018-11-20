/*
*	Module name: main.asm
*
*	Module description:
*		This is the main module, the entry point of the program, the microcontroller is here firstly initialized. The main loop is here implemented, it represents the application running (in this case a game) and for that reason
*		it calls routines of the 'game.asm' module. It defines the instruction flow being executed.
*
*	Author: Paolo Calao
*/ 

.org 0x0000 ;RESET
		rjmp	INIT
.org 0x0004 ;timer1 ovf
		rjmp	REFRESH_LOOP
.org 0x0005 ;timer0 ovf
		rjmp	READ_BUTTON_PINS

#include "oled_driver.asm"
#include "oled_buffer_driver.asm"
#include "tn85def.inc"
#include "record.asm"
#include "menu.asm"
#include "game.asm"
#include "buttons.asm"
#include "utils.asm"

.equ RIGHT_BTN = PB4
.equ LEFT_BTN = PB3
.equ PIN_DEBUG = PB1
.macro TOGGLE_DEBUG_PIN
		sbi		PINB, PIN_DEBUG
.endmacro

INIT_TIMER_REFRESH:
		;different speeds at 10, 30, 60, 100
		push	r16
		ldi		r16, (1<<CS13);
		out		TCCR1, r16
		in		r16, TIMSK
		sbr		r16, (1<<TOIE1)
		out		TIMSK, r16
		pop		r16
		ret

STOP_TIMER_REFRESH:
		push	r16
		clr		r16
		out		TCCR1, r16
		pop		r16
		ret

INIT_TIMER_NOTE:
		push	r16
		tst		r5
		breq	EXIT_INIT_TIMER_NOTE
		ldi		r16, (1 << COM1A1) + (1 << COM1A0) + (1 << CS12) + (1 << CS11) + (1 << CS10) + (1 << PWM1A) ;pwm mode, prescaler 64 -> pwm freq. depends on OCR1C
		out		TCCR1, r16
		ldi		r16, 34				;OCR1C = 34 -> pwm freq. = 440 Hz
		out		OCR1C, r16
		ldi		r16, 17				;OCR1A = 34/2 -> pwm duty cicle = 50%
		out		OCR1A, r16
		in		r16, TIMSK
		cbr		r16, (1<<TOIE1)
		out		TIMSK, r16
		clr		r16
		out		TCNT1, r16
EXIT_INIT_TIMER_NOTE:
		pop		r16
		ret

STOP_TIMER_NOTE:
		ldi		r16, 0x00
		out		TCCR1, r16
		cbi		PORTB, PB1
		ret

INIT:
		sbi		DDRB, PIN_DEBUG
		cbi		PORTB, PIN_DEBUG
		cbi		DDRB, RIGHT_BTN
		cbi		DDRB, LEFT_BTN
		sbi		PORTB, RIGHT_BTN
		sbi		PORTB, LEFT_BTN
		sei
		clr		r5 ;audio default value. cleared when audio off. set when audio on
INIT_GAME:
		ldi		r16, 0xff
		mov		r11, r16
		rcall	INIT_GAME_SCREEN
		rcall	INIT_SNAKE
	;'blink' the buzzer
		rcall	INIT_TIMER_NOTE
		rcall	SHORT_DELAY
		rcall	STOP_TIMER_NOTE
		;end output notes
		rcall	INIT_TIMER_BUTTONS
LOOP:
		rcall	OLED_SEND_DISPLAY_TABLE
		;INIT_TIMER_BUTTONS ;QUESTO CREA PROBLEMI QUI -> AZZERA R8
		RESUME_TIMER_BUTTONS
	;	STOP_TIMER_NOTE
		rcall	POLL_BUTTONS
		rcall	NEXT_MOVE
		rcall	CHECK_COLLISION
		tst		r11
		brne	GO_LOOP
		rcall	GAME_OVER
		rjmp	INIT_GAME
GO_LOOP:
		rjmp	LOOP

POLL_BUTTONS:
		clr		r19 ;used to exit from the polling loop
		rcall	SET_REFRESH_SPEED
		rcall	INIT_TIMER_REFRESH
POLL_LOOP:
		tst		r19
		brne	EXIT_POLL
		tst		r8
		breq	POLL_LOOP
		or		r31, r8
		clr		r8
		rjmp	POLL_LOOP
EXIT_POLL:
		rcall	STOP_TIMER_REFRESH
		ret

SET_REFRESH_SPEED:
		ldi		r17, 8 ;used to regulate the speed of the refresh
		cpi		r30, 10
		brlo	EXIT_REFRESH_SPEED
		mov		r16, r30
SET_REFRESH_LOOP:
		dec		r17
		subi	r16, 10
		brsh	SET_REFRESH_LOOP
EXIT_REFRESH_SPEED:
		ret

REFRESH_LOOP:
		push	r18
		in		r18, SREG
		dec		r17 ;used to regulate the speed of the refresh (see POLL_BUTTONS routine)
		brne	REFRESH_EXIT
		inc		r19
REFRESH_EXIT:
		out		SREG, r18
		pop		r18
		reti
