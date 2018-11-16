/*
*	Module name: oled_driver.asm
*
*	Module description:
*		Drivers to connect the attiny85 mcu to an ssd1306 oled display through the i2c protocol.
*		This file is divided in 2 main parts: 
*		- Firstly there are low level routines that should be used to init the display and to send commands or data. (INIT_OLED, OLED_SEND_COMMAND, OLED_SEND_SINGLE_DATA et similia).
*		- The other routines exploit the ones just mentioned to actually draw something on the screen. There is for example a routine to clear the display (OLED_CLEAR_DISPLAY) and another one to turn on a pixel (OLED_SET_PIXEL).
*			Names for these routines are self-explanatory.
*
*
*	Author: Paolo Calao
*/ 

#ifndef _OLED_DRIVER_
#define _OLED_DRIVER_

#include "i2c.asm"
#include "font.asm"
#include "utils.asm"

.equ INIT_COMMANDS_SIZE = 27;28
;command sequence needed to correctly initialize the oled screen
;Attention: display is initialize in OFF mode so that it can be cleared before its use
INIT_COMMANDS: .db 0xAE, 0x20, 0x00, 0xB0, 0xC8, 0x00, \
				  0x10, 0x40, 0x81, 0x3F, 0xA1, 0xA6, 0xA8, 0x3F, \
				  0xA4, 0xD3, 0x00, 0xD5, 0xF0, 0xD9, 0x22, 0xDA, 0x12, \
				  0xDB, 0x20, 0x8D, 0x14;, 0xAF

INIT_OLED:
		push	r16
		push	r17
		push	zh
		push	zl
		rcall	INIT_I2C
		ldi		zh, high(INIT_COMMANDS * 2) ;z points to the first command
		ldi		zl, low(INIT_COMMANDS * 2)
		ldi		r17, INIT_COMMANDS_SIZE
OLED_LOOP_COMMANDS: ;All the init commands are sent through this loop
		lpm		r16, z+
		rcall	OLED_SEND_COMMAND
		dec		r17		;Terminates the loop when the last command of the init has been executed 
		brne	OLED_LOOP_COMMANDS
		pop		zl
		pop		zh
		pop		r17
		pop		r16
		ret

;Data to be sent has to be written in r16
OLED_SEND_COMMAND:
		push	r16
		rcall	I2C_START_CONDITION
		ldi		r16, 0x78	;Send the address of the oled chip
		rcall	I2C_WRITE_BYTE
		ldi		r16, 0x00	;Control data indicates that the next byte is a command
		rcall	I2C_WRITE_BYTE
		pop		r16			;Command
		rcall	I2C_WRITE_BYTE
		rcall	I2C_STOP_CONDITION
		ret

;Data to be sent has to be written in r16
OLED_SEND_SINGLE_DATA:
		push	r16
		rcall	I2C_START_CONDITION
		ldi		r16, 0x78	;Send the address of the oled chip
		rcall	I2C_WRITE_BYTE
		ldi		r16, 0x40	;Control data indicates that the next byte is a byte
		rcall	I2C_WRITE_BYTE
		pop		r16
		rcall	I2C_WRITE_BYTE
		rcall	I2C_STOP_CONDITION
		ret

OLED_SEND_START_DATA:
		push	r16
		rcall	I2C_START_CONDITION
		ldi		r16, 0x78	;Send the address of the oled chip
		rcall	I2C_WRITE_BYTE
		ldi		r16, 0x40
		rcall	I2C_WRITE_BYTE
		pop		r16
		ret

;COLUMN'S AND PAGE'S ADDRESSES HAVE TO BE PUT INTO REGISTERS R17, R18, R19, R20
OLED_SET_ADDRESSES:
		push	r16
		ldi		r16, 0x21 ;Set column address
		rcall	OLED_SEND_COMMAND
		mov		r16, r17 ;Set column start address
		rcall	OLED_SEND_COMMAND
		mov		r16, r18 ;Set column end address
		rcall	OLED_SEND_COMMAND
		ldi		r16, 0x22 ;Set page address
		rcall	OLED_SEND_COMMAND
		mov		r16, r19 ;Set page start address
		rcall	OLED_SEND_COMMAND
		mov		r16, r20 ;Set page end address
		rcall	OLED_SEND_COMMAND
		pop		r16
		ret

;alternative to the OLED_SET_ADDRESSES subroutine, this has less overhead but it requires more program space if is used by many subroutines
;only r16 is needed and it has to be saved by the subroutine before using this macro.
.macro OLED_SET_ADDRESSES_MACRO
		ldi		r16, 0x21 ;Set column address
		rcall	OLED_SEND_COMMAND
		ldi		r16, @0
		rcall	OLED_SEND_COMMAND
		ldi		r16, @1
		rcall	OLED_SEND_COMMAND
		ldi		r16, 0x22 ;Set page address
		rcall	OLED_SEND_COMMAND
		ldi		r16, @2
		rcall	OLED_SEND_COMMAND
		ldi		r16, @3
		rcall	OLED_SEND_COMMAND
.endmacro

;Makes the register z pointing to the display table in ram
.macro OLED_INIT_DISPLAY_POINTER
		ldi		@0, high(DISPLAY_TABLE)
		ldi		@1, low(DISPLAY_TABLE)
.endmacro


OLED_CLEAR_DISPLAY:
		push	r16
		push	r17
		push	r18
		OLED_SET_ADDRESSES_MACRO 0, 127, 0, 7
		rcall	OLED_SEND_START_DATA
		clr		r16
		ldi		r18, 5
OLED_CLEAR_LOOP_1:
		ldi		r17, 0xFF
OLED_CLEAR_LOOP_2:
		rcall	I2C_WRITE_BYTE
		dec		r17
		brne	OLED_CLEAR_LOOP_2
		dec		r18
		brne	OLED_CLEAR_LOOP_1
		rcall	I2C_STOP_CONDITION
		pop		r18
		pop		r17
		pop		r16
		ret

OLED_DISPLAY_ON:
		push	r16
		ldi		r16, 0xAF
		rcall	OLED_SEND_COMMAND
		pop		r16
		ret

OLED_DISPLAY_OFF:
		push	r16
		ldi		r16, 0xAE
		rcall	OLED_SEND_COMMAND
		pop		r16
		ret


;inputs: r16 -> x, r17 -> y
;x absolute addresses go from DISPLAY_TABLE_X_START to DISPLAY_TABLE_X_END
;x relative addresses go from 0 to DISPLAY_TABLE_COLS - 1
;y absolute addresses go from DISPLAY_TABLE_Y_START to DISPLAY_TABLE_Y_END
;y relative addresses go from 0 to DISPLAY_TABLE_PAGES * 8 - 1
OLED_SET_PIXEL: 
		push	r16
		push	r17 
		push	r18
		push	yl
		push	yh
		OLED_INIT_DISPLAY_POINTER yh, yl
		add		yl, r16
		adc		yh, r1
		;r16 -> free, r17 -> y, r18 -> free, Y(yl, yh) -> col offset
		rcall	DIV_MOD_8
		;r16 -> y/8, r17 -> y mod 8, r18 -> free, Y(yl, yh) -> col offset
		rcall	MUL_COLS_PAGE
		;r16 -> x, r17 -> y mod 8, r18 -> n_of_columns (no more needed -> free), Y(yl, yh) -> byte address
		SHIFT_MOD_SET_MASK
		;r17 -> 0, r18 -> mask
		ld		r17, y
		or		r17, r18
		st		y, r17
		pop		yh
		pop		yl
		pop		r18
		pop		r17
		pop		r16
		ret

;ATTENTION: this subroutine changes the values of the input registers. To avoid that just push and pop them.
;inputs: r16 -> x, r17 -> y
OLED_CLEAR_PIXEL:  
		push	r16
		push	r17
		push	r18
		push	yl
		push	yh
		OLED_INIT_DISPLAY_POINTER yh, yl
		add		yl, r16
		adc		yh, r1
		;r16 -> free, r17 -> y, r18 -> free, Y(yl, yh) -> col offset
		rcall	DIV_MOD_8
		;r16 -> y/8, r17 -> y mod 8, r18 -> free, Y(yl, yh) -> col offset
		rcall	MUL_COLS_PAGE
		;r16 -> x, r17 -> y mod 8, r18 -> n_of_columns (no more needed -> free), Y(yl, yh) -> byte address
		SHIFT_MOD_SET_MASK
		com		r18
		;r17 -> 0, r18 -> mask
		ld		r17, y
		and		r17, r18
		st		y, r17
		pop		yh
		pop		yl
		pop		r18
		pop		r17
		pop		r16
		ret

;ATTENTION: this subroutine changes the values of the input registers. To avoid that just push and pop them
;inputs: r16 -> x, r17 -> y	; outputs: r18 -> 0000000X, X is the value of the pixel just extracted		ALTERNATIVE: use T flag
OLED_GET_PIXEL:
		push	r16
		push	r17
		push	yl
		push	yh
		OLED_INIT_DISPLAY_POINTER yh, yl
		add		yl, r16
		adc		yh, r1
		;r16 -> free, r17 -> y, r18 -> free, Y(yl, yh) -> col offset
		rcall	DIV_MOD_8
		;r16 -> y/8, r17 -> y mod 8, r18 -> free, Y(yl, yh) -> col offset
		rcall	MUL_COLS_PAGE
		;r16 -> x, r17 -> y mod 8, r18 -> n_of_columns (no more needed -> free), Y(yl, yh) -> byte address
		SHIFT_MOD_SET_MASK
		;r17 -> 0, r18 -> mask
		ld		r17, y
		and		r17, r18
		ldi		r18, 0
		breq	OLED_GET_PIXEL_END
		ldi		r18, 0x01
OLED_GET_PIXEL_END:
		pop		yh
		pop		yl
		pop		r17
		pop		r16
		ret



;inputs: r17->x_start, r18-> x_end, r19->page_start, r20->page_end, Z(zl, zh)->address of the bitmap
OLED_DRAW_BMP:
		push	r16
		push	r19
		push	r21
		mov		r21, r17
		rcall	OLED_SET_ADDRESSES
		rcall	OLED_SEND_START_DATA
OLED_DRAW_BMP_LOOP_Y:
		mov		r17, r21
OLED_DRAW_BMP_LOOP_X:
		lpm		r16, z+
		rcall	I2C_WRITE_BYTE
		inc		r17
		cp		r18, r17
		brsh	OLED_DRAW_BMP_LOOP_X
		inc		r19 
		cp		r20, r19
		brsh	OLED_DRAW_BMP_LOOP_Y
		rcall	I2C_STOP_CONDITION
		mov		r17, r21
		pop		r21
		pop		r19
		pop		r16
		ret

;input: r17->x_start, r18->x_end, r19->page_start, r20->page_end
.macro OLED_START_DRAW_CHAR
		rcall	OLED_SET_ADDRESSES
.endmacro

;input: r17->char
OLED_DRAW_CHAR:
		push	r16 ;used to send data to the oled
		push	r18
		push	r19
		push	r20 ;used for the loop. Indicates how many bytes are contained in a char 
		push	zl
		push	zh
		ldi		r20, 8
		ldi		zl, low(FONT*2) ;points to the font 
		ldi		zh, high(FONT*2)
		rcall	MUL_8
		add		zl, r18 ;points to the char font
		adc		zh, r19
		rcall	OLED_SEND_START_DATA
OLED_CHAR_LOOP:
		lpm		r16, z+ ;read the char's bytes
		rcall	I2C_WRITE_BYTE
		dec		r20
		brne	OLED_CHAR_LOOP
		rcall	I2C_STOP_CONDITION
		pop		zh
		pop		zl
		pop		r20
		pop		r19
		pop		r18
		pop		r16
		ret



;inputs: r17->x_start, r18-> x_end, r19->page, r20->byte to draw considering y offset
OLED_DRAW_HORIZONTAL_LINE:
		push	r16
		mov		r16, r20
		mov		r20, r19
		rcall	OLED_SET_ADDRESSES
		ldi		r20, 128 ;total columns
		rcall	OLED_SEND_START_DATA
OLED_HORIZ_LINE_LOOP:
		rcall	I2C_WRITE_BYTE
		dec		r20
		brne	OLED_HORIZ_LINE_LOOP
		rcall	I2C_STOP_CONDITION
		mov		r20, r16
		pop		r16
		ret

;inputs: r17->x, r19->page_start, r20->page_end
OLED_DRAW_VERTICAL_LINE:
		push	r16
		push	r18
		mov		r18, r17
		rcall	OLED_SET_ADDRESSES
		ldi		r16, 0xFF
		ldi		r18, 8 ;total pages
		rcall	OLED_SEND_START_DATA
OLED_VERT_LINE_LOOP:
		rcall	I2C_WRITE_BYTE
		dec		r18
		brne	OLED_VERT_LINE_LOOP
		rcall	I2C_STOP_CONDITION
		pop		r18
		pop		r16
		ret

 #endif
