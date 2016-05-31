.include "m2560def.inc"


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

.org 0
	jmp START

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
	



halt:
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

;
; Send a command to the LCD (r16)
;

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
	;insert 1 second delay
	
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
	;insert 1 second delay

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
	;insert 1 second delay
	
	finalise_function
	reti
	rjmp RESET

;resetting the POT 
RESET:
	ldi temp1, (3 << REFS0) | (0 << ADLAR) | (0 << MUX0)
	sts ADMUX, temp1
	ldi temp2, (1 << MUX5)
	sts ADCSRB, temp2
	ldi temp3, (1 <<ADEN) | (1 << ADSC) | (1 << ADIE) | (5 << ADPS0)
	
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
	
	cpi ADCH:ADCL, 0
	brne TIMEOUT
	;insert 1 second delay	
	
	rjmp FIND_POT

;Finding the POT position 
FIND_POT:
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

	
;timeout screen	
TIMEOUT:
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
	
	rjmp START ;or breq START depending how the above^ code works
	
	
	




