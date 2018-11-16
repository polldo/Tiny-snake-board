/*/*
POLL_BUTTONS:
	clr r19 ;used to exit from the polling loop
	INIT_TIMER_REFRESH
	clr r16 ;load the values of the pins
	clr r17 ;count right button pressing
	clr r18 ;count left button pressing
POLL_LOOP:
	tst r19
	brne EXIT_POLL
	in r16,PINB
CHECK_RIGHT_PRESSED:
	sbrs r16,RIGHT_BTN
	inc r17
	sbrc r16,RIGHT_BTN
	rjmp RIGHT_NOT_PRESSED
CHECK_LEFT_PRESSED:
	sbrs r16,LEFT_BTN
	inc r18
	sbrc r16,LEFT_BTN
	rjmp LEFT_NOT_PRESSED
	rjmp CHECK_BUTTON_PRESSED
RIGHT_NOT_PRESSED:
	tst r17
	breq CHECK_LEFT_PRESSED
	;dec r17
	clr r17
	rjmp CHECK_LEFT_PRESSED
LEFT_NOT_PRESSED:
	tst r18
	breq CHECK_BUTTON_PRESSED
	;dec r18
	clr r18
CHECK_BUTTON_PRESSED:
	cpi r17,5
	breq RIGHT_PRESSED
	cpi r18,5
	breq LEFT_PRESSED
	rcall DELAY
	rjmp POLL_LOOP
RIGHT_PRESSED:
	ldi r17,0x03
	or r31,r17
	rjmp BUTTON_PRESSED_LOOP
LEFT_PRESSED:
	ldi r18,0x01
	or r31,r18
BUTTON_PRESSED_LOOP:
	tst r19
	brne EXIT_POLL
	rjmp BUTTON_PRESSED_LOOP
EXIT_POLL:
	ret

REFRESH_LOOP:
	inc r19
	STOP_TIMER_REFRESH
	reti


	DELAY:
	push r16
	push r17
;	push r18
;	ldi r18,0x01
;DELAY_3:
	ldi r17,8
DELAY_2:
	ldi r16,0xFF
DELAY_1:
	dec r16
	brne DELAY_1
	dec r17
	brne DELAY_2
;	dec r18
;	brne DELAY_3
;	pop r18
	pop r17
	pop r16
	ret
*/