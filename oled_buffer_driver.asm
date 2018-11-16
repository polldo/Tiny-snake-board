/*
*	Module name: oled_buffer_driver.asm
*
*	Module description:
*		The intent of this module is to allow the programmer to have a buffer of the display content in the sram of the microcontroller. Having a buffer makes thing easier because it permits, instead of sending every change of data immediately to the display,
*		to perform changes on the buffer which at a regular interval can be entirely sent to the display.
*
*	Author: Paolo Calao
*/ 

#ifndef _OLED_BUFFER_DRIVER_
#include "oled_driver.asm"

#define _OLED_BUFFER_DRIVER_
#define _DOUBLE_COLS_

.equ DISPLAY_TABLE_COLS = 64
.equ DISPLAY_TABLE_PAGES = 6 
.equ DISPLAY_TABLE_SIZE = DISPLAY_TABLE_COLS * DISPLAY_TABLE_PAGES
.equ DISPLAY_TABLE_X_START = 0
#ifdef _DOUBLE_COLS_
.equ DISPLAY_TABLE_X_END = DISPLAY_TABLE_X_START + DISPLAY_TABLE_COLS * 2 - 1 ;IFDEF double cols
#else
.equ DISPLAY_TABLE_X_END = DISPLAY_TABLE_X_START + DISPLAY_TABLE_COLS - 1 ;IFNOTDEF double cols
#endif
.equ DISPLAY_TABLE_Y_START = 2
.equ DISPLAY_TABLE_Y_END = DISPLAY_TABLE_Y_START + DISPLAY_TABLE_PAGES - 1

.DSEG
DISPLAY_TABLE: .BYTE (DISPLAY_TABLE_SIZE)

.CSEG
OLED_CLEAR_DISPLAY_TABLE:
		push	r16
		push	zl
		push	zh
		OLED_INIT_DISPLAY_POINTER zh, zl
		ldi		r16, (DISPLAY_TABLE_SIZE - 200) ;In this way 201 is the minimum size for the display table and 455 is the max size
OLED_CLEAR_TABLE_LOOP_1:
		st		z+, r1
		dec		r16
		brne	OLED_CLEAR_TABLE_LOOP_1
		ldi		r16, 200
OLED_CLEAR_TABLE_LOOP_2:
		st		z+, r1
		dec		r16
		brne	OLED_CLEAR_TABLE_LOOP_2
		pop		zh
		pop		zl
		pop		r16
		ret

OLED_SEND_DISPLAY_TABLE:
		push	r16
		push	r17
		push	zl
		push	zh
		OLED_INIT_DISPLAY_POINTER zh, zl
		OLED_SET_ADDRESSES_MACRO DISPLAY_TABLE_X_START, DISPLAY_TABLE_X_END, DISPLAY_TABLE_Y_START, DISPLAY_TABLE_Y_END
		rcall	OLED_SEND_START_DATA
		ldi		r17, (DISPLAY_TABLE_SIZE - 200) ;In this way 201 is the minimum size for the display table and 455 is the max size
OLED_SEND_TABLE_LOOP_1:
		ld		r16,z+
		rcall	I2C_WRITE_BYTE
		#ifdef _DOUBLE_COLS_
		rcall	I2C_WRITE_BYTE ;ifdef double col
		#endif
		dec		r17
		brne	OLED_SEND_TABLE_LOOP_1
		ldi		r17, 200
OLED_SEND_TABLE_LOOP_2:
		ld		r16, z+
		rcall	I2C_WRITE_BYTE
		#ifdef _DOUBLE_COLS_
		rcall	I2C_WRITE_BYTE ;ifdef double col
		#endif	
		dec		r17
		brne	OLED_SEND_TABLE_LOOP_2
		pop		zh
		pop		zl
		pop		r17
		pop		r16
		rcall	I2C_STOP_CONDITION
		ret

#endif
