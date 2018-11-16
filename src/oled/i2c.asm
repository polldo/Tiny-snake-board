/*
*	Module name: i2c.asm
*
*	Module description:
*		This module contains DRIVERS that allows the attiny85 mcu to communicate with external peripherals
*		using the I2C protocol. Every pin of the mcu can be used.
*		To properly work with this protocol the INIT_I2C routine should initially be called. Then before sending information through the channel the 
*		starting condition should be sent: to accomplish this task just call I2C_START_CONDITION. Now everything is ready and calling the routine I2C_WRITE_BYTE
*		data can finally be exchanged. At the end of the desired sequence of data, send a stop condition through the I2C_STOP_CONDITION routine.
*
*	Author: Paolo Calao
*/ 

#ifndef _I2C_
#define _I2C_

.equ PIN_SDA = PB0
.equ PIN_SCL = PB2

;First subroutine to call -> sets USI control register, USI status registers and the 2 output pins SDA and SCL
INIT_I2C:	
		push	r16
		;sbi PORTB,PIN_SCL ;pull-up
		;sbi PORTB,PIN_SDA 
		;Set sclk and sda as output
		sbi		DDRB, PIN_SCL
		sbi		DDRB, PIN_SDA
		;The MSB of USIDR is directly connected to a latch that ends in SDA, so to release SDA (to not drive it) the USI Data Register is filled with 1s
		ldi		r16, 0xFF
		out		USIDR, r16
		;Init usi control register and usi status register
		ldi		r16, (0 << USISIE) + (0 << USIOIE) + (1 << USIWM1) + (0 << USIWM0) + (1 << USICS1) + (0 << USICS0) + (1 << USICLK) + (0 << USITC) ;Interrupts disabled.Two-wire mode on. Software clock strobe (USITC) used
		out		USICR, r16
		ldi		r16, 0xF0 ;Usi status register -> clear all flags (first half byte) and set counter to 0 (second half byte)
		out		USISR, r16
		pop		r16
		ret

I2C_START_CONDITION:
		sbi		PORTB, PIN_SCL ;Serial clock high
		cbi		PORTB, PIN_SDA ;Serial data low
		cbi		PORTB, PIN_SCL ;Serial clock low
		sbi		PORTB, PIN_SDA ;Release serial data
		ret

I2C_STOP_CONDITION:
		cbi		PORTB, PIN_SDA
		sbi		PORTB, PIN_SCL
		sbi		PORTB, PIN_SDA
		ret

;Data to be sent has to be written in r16
I2C_WRITE_BYTE:
		push	r16
		out		USIDR, r16 ;Release SDA
		ldi		r16, 0xF0 ;Usi status register -> clear all flags (first half byte) and set counter to 0 (second half byte)
		out		USISR, r16
I2C_WRITE_BIT:
		sbi		USICR, USITC ;Toggle the clock, shift USIDR and increment the USI counter
		sbis	USISR, USIOIF ;Check if an overflow of the 4-bit USI counter occurs. It means that an entire byte has been transmitted (counter is incremented at each clock toggle)
		rjmp	I2C_WRITE_BIT ;If not overflow, toggle again for transmitting the next bit
I2C_READ_ACK:	
		ldi		r16, 0xFF
		out		USIDR, r16 ;Release sda
		sbi		PORTB, PIN_SCL ;Send a clock edge to read the slave's ack
		cbi		PORTB, PIN_SCL
		pop		r16
		ret

#endif
