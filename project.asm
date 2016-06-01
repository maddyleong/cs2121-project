.include "m2560def.inc"

.equ PATTERN = 0b11110000
.def temp1 = r18

.macro clear				;clears a word in a memory
	ldi YL, low(@0)			;load memory address
	ldi YH, high(@0)
	clr temp1
	st Y+, temp1
	st Y, temp1
.endmacro

.macro do_lcd_command
	ldi r16, @0
	rcall lcd_command
	rcall lcd_wait
.endmacro

.macro do_lcd_data
	ldi r16, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro

.macro initialise_function
	push temp			;save conflict registers
	push YH
	push YL
	push r22
	push r23
	in temp, SREG			;save status register
	push temp
.end macro

.macro finalise_function
	pop temp			;pop status register
	out SREG, temp			
	pop r23
	pop r22
	pop YL
	pop YH
	pop temp
.end macro

.dseg
SecondCounter:
	.byte 2
TempCounter:
	.byte 2

.cseg

.org 0x0000
	jmp SECOND
	jmp DEFAULT			;no handling for IRQ0
	jmp DEFAULT			;no handling for IRQ1
.org OVF0addr
	jmp Time0OVF
	jmp DEFAULT
	
DEFAULT:
	reti
	
;initialise stack pointer	
SECOND:
	ldi temp3, high(RAMEND)
	out SPH, temp3
	ldi temp3, low(RAMEND)
	out SPL, temp3
	
	ser temp3			;set port C as output
	out DDRC, temp3
	
	rjmp main

;interrupt subroutine to Timer0
Timer0OVF:
	in temp3, SREG
	push temp3
	push YH
	push YL
	push r25
	push r24
	
	lds r24, TempCounter
	lds r25, TempCounter+1
	adiw r25:r24, 1
	
	cpi r24, low(7812)		;7812 = 10^6/128
	ldi temp3, high(7812)
	cpc r25, temp3
	brne NotSecond
	clear TempCounter
	
	lds r24, SecondCounter
	lds r25, SecondCounter+1
	adiw r25:r24, 1
	sts SecondCounter, r24
	sts SecondCounter+1, r25
	rjmp EndIF

;store the new value of the temporary counter
NotSecond:
	sts TempCounter, r24
	sts TempCounter, r25
	
EndIF:
	pop r24
	pop r25
	pop YL
	pop YH
	pop temp3
	out SREG, temp3
	reti
	

;start screen
START:
	ldi r16, low(RAMEND)
	out SPL, r16
	ldi r16, high(RAMEND)
	out SPH, r16

	ser r16
	out DDRF, r16
	out DDRA, r16
	clr r16
	out PORTF, r16
	out PORTA, r16

	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_5ms
	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_1ms
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00001000 ; display off?
	do_lcd_command 0b00000001 ; clear display
	do_lcd_command 0b00000110 ; increment, no display shift
	do_lcd_command 0b00001110 ; Cursor on, bar, no blink

	;start screen
	do_lcd_data '2'
	do_lcd_data '1'
	do_lcd_data '2'
	do_lcd_data '1'
	do_lcd_data ' '
	do_lcd_data '1'
	do_lcd_data '6'
	do_lcd_data 's'
	do_lcd_data '1'
	do_lcd_command 0b11000000	;move to next line
	do_lcd_data 'S'
	do_lcd_data 'a'
	do_lcd_data 'f'
	do_lcd_data 'e'
	do_lcd_data ' '
	do_lcd_data 'C'
	do_lcd_data 'r'
	do_lcd_data 'a'
	do_lcd_data 'c'
	do_lcd_data 'k'
	do_lcd_data 'e'
	do_lcd_data 'r'
	



HALT:
	rjmp halt

.equ LCD_RS = 7
.equ LCD_E = 6
.equ LCD_RW = 5
.equ LCD_BE = 4

.macro lcd_set
	sbi PORTA, @0
.endmacro
.macro lcd_clr
	cbi PORTA, @0
.endmacro

; Send a command to the LCD (r16)

lcd_command:
	out PORTF, r16
	rcall sleep_1ms
	lcd_set LCD_E
	rcall sleep_1ms
	lcd_clr LCD_E
	rcall sleep_1ms
	ret

lcd_data:
	out PORTF, r16
	lcd_set LCD_RS
	rcall sleep_1ms
	lcd_set LCD_E
	rcall sleep_1ms
	lcd_clr LCD_E
	rcall sleep_1ms
	lcd_clr LCD_RS
	ret

lcd_wait:
	push r16
	clr r16
	out DDRF, r16
	out PORTF, r16
	lcd_set LCD_RW
lcd_wait_loop:
	rcall sleep_1ms
	lcd_set LCD_E
	rcall sleep_1ms
	in r16, PINF
	lcd_clr LCD_E
	sbrc r16, 7
	rjmp lcd_wait_loop
	lcd_clr LCD_RW
	ser r16
	out DDRF, r16
	pop r16
	ret

.equ F_CPU = 16000000
.equ DELAY_1MS = F_CPU / 4 / 1000 - 4
; 4 cycles per iteration - setup/call-return overhead

sleep_1ms:
	push r24
	push r25
	ldi r25, high(DELAY_1MS)
	ldi r24, low(DELAY_1MS)
delayloop_1ms:
	sbiw r25:r24, 1
	brne delayloop_1ms
	pop r25
	pop r24
	ret

sleep_5ms:
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	ret

sleep_1s:
	clear TempCounter
	clear SecondCounter
	out TCCR0A, temp3
	out TCCR0B, temp3
	ldi temp3, 1<<TOIE0
	sts TIMSK0, temp3
	sei
	
;starting countdown 
LEFT_BUTTON:
	initialise_function
	
	do_lcd_command 0b00010101		;sets cursor to beginning of second line
	do_lcd_data 'S'
	do_lcd_data 't'
	do_lcd_data 'a'
	do_lcd_data 'r'
	do_lcd_data 't'
	do_lcd_data 'i'
	do_lcd_data 'n'
	do_lcd_data 'g'
	do_lcd_data ' '
	do_lcd_data 'i'
	do_lcd_data 'n'
	do_lcd_data ' '
	do_lcd_data '3'
	do_lcd_data '.'
	do_lcd_data '.'
	do_lcd_data '.'
	rcall sleep_1s
	
	do_lcd_command 0b00010101	
	do_lcd_data 'S'
	do_lcd_data 't'
	do_lcd_data 'a'
	do_lcd_data 'r'
	do_lcd_data 't'
	do_lcd_data 'i'
	do_lcd_data 'n'
	do_lcd_data 'g'
	do_lcd_data ' '
	do_lcd_data 'i'
	do_lcd_data 'n'
	do_lcd_data ' '
	do_lcd_data '2'
	do_lcd_data '.'
	do_lcd_data '.'
	do_lcd_data '.'
	rcall sleep_1s
	
	do_lcd_command 0b00010101	
	do_lcd_data 'S'
	do_lcd_data 't'
	do_lcd_data 'a'
	do_lcd_data 'r'
	do_lcd_data 't'
	do_lcd_data 'i'
	do_lcd_data 'n'
	do_lcd_data 'g'
	do_lcd_data ' '
	do_lcd_data 'i'
	do_lcd_data 'n'
	do_lcd_data ' '
	do_lcd_data '1'
	do_lcd_data '.'
	do_lcd_data '.'
	do_lcd_data '.'
	rcall sleep_1s
	
	finalise_function
	reti
	rjmp RESET

;resetting the POT 
RESET:
	
	clr r17 				;set K as input
	sts DDRK, r16
	
	ldi r17,  (3 << REFS0) | (0 << ADLAR) | (0 << MUX0)	;set up POT and ADConverter
	sts ADMUX, r17
	ldi r17, (1 << MUX5)
	sts ADCSRB, r17
	ldi r17, (1 <<ADEN) | (1 << ADSC) | (1 << ADIE) | (5 << ADPS0)	
	sts ADCSRA, r17				;this sets it to auto update
	lds r18, ADCL
	lds r19, ADCH
	
	do_lcd_command 0b00000001		;clear display
	do_lcd_command 0b00000011		;set cursor to top left
	do_lcd_data 'R'
	do_lcd_data 'e'
	do_lcd_data 's'
	do_lcd_data 'e'
	do_lcd_data 't'
	do_lcd_data ' '
	do_lcd_data 'P'
	do_lcd_data 'O'
	do_lcd_data 'T'
	do_lcd_data ' '
	do_lcd_data 't'
	do_lcd_data 'o'
	do_lcd_data ' '
	do_lcd_data '0'
	do_lcd_command 0b11000000
	do_lcd_data 'R'
	do_lcd_data 'e'
	do_lcd_data 'm'
	do_lcd_data 'a'
	do_lcd_data 'i'
	do_lcd_data 'n'
	do_lcd_data 'g'
	do_lcd_data ':'
	do_lcd_data ' '
	do_lcd_data '' ;<-----number of seconds, need to input
	
	cpi ADCL:ADCH, 0 ;if this doesn't work, put ADCH and ADCH into registers and adiw r24:r23,0 or something similar
	brne TIMEOUT
	rcall sleep_1s	
	
	rjmp FIND_POT

;Finding the POT position 
FIND_POT:
	do_lcd_command 0b00000001		;clear display
	do_lcd_command 0b00000011		;set cursor to top left
	do_lcd_data 'F'
	do_lcd_data 'i'
	do_lcd_data 'n'
	do_lcd_data 'd'
	do_lcd_data ' '
	do_lcd_data 'P'
	do_lcd_data 'O'
	do_lcd_data 'T'
	do_lcd_data ' '
	do_lcd_data 'P'
	do_lcd_data 'o'
	do_lcd_data 's'
	do_lcd_command 0b11000000
	do_lcd_data 'R'
	do_lcd_data 'e'
	do_lcd_data 'm'
	do_lcd_data 'a'
	do_lcd_data 'i'
	do_lcd_data 'n'
	do_lcd_data 'g'
	do_lcd_data ':'
	do_lcd_data ' '
	do_lcd_data '' ;<------ time counting down from the previous screen (not reset)
	
	;cpi time, 0
	;breq TIMEOUT
	
	;while within 16 raw adc counts of correct position
	;all leds lit
	;if within 32
	;all leds except top one lit
	;if within 48
	;bottom 8 leds lit
	;else, all leds off

	
;timeout screen	
TIMEOUT:
	do_lcd_command 0b00000001		;clear display
	do_lcd_command 0b00000011		;set cursor to top left
	do_lcd_data 'G'
	do_lcd_data 'a'
	do_lcd_data 'm'
	do_lcd_data 'e'
	do_lcd_data ' '
	do_lcd_data 'o'
	do_lcd_data 'v'
	do_lcd_data 'e'
	do_lcd_data 'r'
	do_lcd_command 0b11000000
	do_lcd_data 'Y'
	do_lcd_data 'o'
	do_lcd_data 'u'
	do_lcd_data ' '
	do_lcd_data 'L'
	do_lcd_data 'o'
	do_lcd_data 's'
	do_lcd_data 'e'
	do_lcd_data '!'
	
	;detect any keypad/push button is pressed
	
	jmp START ;or breq START depending how the above^ code works
	
;game is complete
COMPLETE:
	do_lcd_command 0b00000001		;clear display
	do_lcd_command 0b00000011		;set cursor to top left
	do_lcd_data 'G'
	do_lcd_data 'a'
	do_lcd_data 'm'
	do_lcd_data 'e'
	do_lcd_data ' '
	do_lcd_data 'c'
	do_lcd_data 'o'
	do_lcd_data 'm'
	do_lcd_data 'p'
	do_lcd_data 'l'
	do_lcd_data 'e'
	do_lcd_data 't'
	do_lcd_data 'e'
	do_lcd_command 0b11000000
	do_lcd_data 'Y'
	do_lcd_data 'o'
	do_lcd_data 'u'
	do_lcd_data ' '
	do_lcd_data 'W'
	do_lcd_data 'i'
	do_lcd_data 'n'
	do_lcd_data '!'
	
	;strobe led flashing at a rate of 2Hz
	
	;detect any button is pressed
	
	jmp START ;or breq START depending how the above^ code works

	




