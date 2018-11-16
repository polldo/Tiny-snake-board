/*
*	Module name: buttons.asm
*
*	Module description:
*		Here there are routines used to read the value of the buttons. A timer is used to debounce the input and r8 will contain the value read (00000001 if left button was the last pressed; 00000010 if right button was the last pressed).
*
*
*	Author: Paolo Calao
*/ 
 
#ifndef _BUTTONS_
#define _BUTTONS_

.equ DEBOUNCE_VALUE = 40
 
INIT_TIMER_BUTTONS: ;used to debounce inputs
		push	r16
		clr		r2 ;count for right_btn
		clr		r3 ;count for left_btn
		clr		r4 ;used as a flag
		clr		r8 ;00 -> no press; 01 -> left press; 11 -> right press
		ldi		r16, DEBOUNCE_VALUE
		mov		r7, r16 ;up value
		ldi		r16, (1<<CS01) ;activate timer 0 with prescaler = clock/8
		out		TCCR0B, r16
		in		r16, TIMSK
		sbr		r16, (1<<TOIE0) ;activate timer 0 interrupts
		out		TIMSK, r16
		pop		r16
		ret

;USE R4 (see timer0 ovf isr)
.macro RESUME_TIMER_BUTTONS
		clr		r4
.endmacro

;use r4 to neglect the effects of the timer without stopping it
.macro STOP_TIMER_BUTTONS
		com		r4 ;inverts r4 -> from 0x00 to 0xFF
.endmacro


;r4 reserved to this function -> it's flagged if a button has been pressed and not already read; it's cleared if any button pressed was already read
READ_BUTTON_PINS:
		push	r16
		push	r18
		in		r18, SREG ;save status and registers 
		tst		r4
		brne	TIMER0_END
		in		r16, PINB
		sbrs	r16, RIGHT_BTN
		inc		r2
		sbrs	r16, LEFT_BTN
		inc		r3
		sbrc	r16, RIGHT_BTN
		clr		r2
		sbrc	r16, LEFT_BTN
		clr		r3
		cp		r3, r7
		breq	LEFT_PRESSED
		cp		r2, r7
		brne	TIMER0_END
RIGHT_PRESSED:
		clr		r2
		ldi		r16, 0x03
		mov		r8, r16
		STOP_TIMER_BUTTONS ;-> flagging r4
		rjmp	TIMER0_END
LEFT_PRESSED:
		clr		r3
		ldi		r16, 0x01
		mov		r8, r16
		STOP_TIMER_BUTTONS
TIMER0_END:
		out		SREG, r18
		pop		r18
		pop		r16
		reti

#endif
