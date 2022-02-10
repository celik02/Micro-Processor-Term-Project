GPIO_PORTF_DATA		EQU 0x400253FC
TIMER0_TAILR		EQU 0x40030028
GPIO_PORTB_DATA		equ	0x400053FC	
; ADDRESS 0x20000800 onward used for ADC module to store mic samples
; address 0x200007F8 used to store motor rotation direction
; address 0X20004000 used to store ascii values to print them
; address =0x20000400 used to store speed values
; address 0x20000600  used for remembering last led that was on
AMPLITUDE			EQU			0x20000610	
AMPLITUDE_THRESH    EQU			0x20000630
FREQ				EQU			0x20000650
WRITE_LINE			EQU			0x20001600
FREQ_LOW_THRESH		EQU			0x20000660
FREQ_HIGH_THRESH	EQU			0x20000670
KEYPAD_VAL_BUFFER	EQU			0x20001400
KEYPAD_VAL_SIG		EQU			0x20001404
	
MOTOR_DRIVE_SIGNALS	 EQU 0x200007FC   ;(4 bits signals that are send to motor driver)
MOTOR_TURN_DIRECTION EQU 0x200007F8
	
;define strings to print them on LCD
				AREA SomeData, DATA, READONLY
				THUMB
ampVal_title   	DCB			"Amp V:"
				DCB			0x04
ampThres_title  DCB			"Amp T:"
				DCB			0x04
freqVal_title   DCB			"FreqV:"
				DCB			0x04
				
thres1_title   	DCB			"FreqL:"
				DCB			0x04
				
thres2_title   	DCB			"FreqH:"
				DCB			0x04
				
EMPTY_SPACE		DCB			"     "
				DCB			0x04

	

				AREA   main, CODE, READONLY
				THUMB
				EXPORT	__main
				EXPORT	take_fft
				;get all external libraries
				EXTERN  INIT_SYSTICK
				EXTERN	gpio_setup
				EXTERN	atd_setup
				EXTERN	arm_cfft_sR_q15_len256
				EXTERN	arm_cfft_q15
				EXTERN	init_port_c
				EXTERN	PULSE_INIT
				EXTERN  init_port_f
				extern	OutStr
				extern 	OutChar
				extern	__convrt
				extern  My_Timer0A_Handler
				EXTERN	timer1_init
					
				EXTERN	Nokia_Init
				EXTERN	SetXYNokia
				EXTERN	OutStrNokia
				EXTERN	OutCharNokia
				EXTERN	ClearNokia
				extern	find_which
				export 	DELAY100
__main			PROC
				CPSIE 	I
				LDR		R0, =0x20000800
				MOV		R1, #1
				STR		R1, [R0]
				BL		PULSE_INIT
				BL  	gpio_setup
				BL		atd_setup
				BL		INIT_SYSTICK
				BL		init_port_c
				BL		init_port_f
				BL		Nokia_Init
				BL		timer1_init
				
				;set initial turning direction
				LDR		R1, =0x200007F8
				MOV		R0, #0
				STR		R0, [R1]
				
				;set initial low thresh
				LDR		R1, =FREQ_LOW_THRESH
				MOV		R0, #350
				STR		R0, [R1]
				
				;set initial high thresh
				LDR		R1, =FREQ_HIGH_THRESH
				MOV		R0, #700
				STR		R0, [R1]
				
				;set initial amplitude thres
				LDR		R1, =AMPLITUDE_THRESH
				MOV32	R0, #5
				STR		R0, [R1]
				
				;PRINT some strings to LCD
				MOV		R0, #0	;6
				MOV		R1, #0	;1
				BL		SetXYNokia
				LDR		R5, =ampThres_title
				bl		OutStrNokia
				
				MOV		R0, #0	;6
				MOV		R1, #1	;1
				BL		SetXYNokia
				LDR		R5, =ampVal_title
				bl		OutStrNokia
				
				
				MOV		R0, #0	;6
				MOV		R1, #2	;1
				BL		SetXYNokia
				LDR		R5, =thres1_title
				bl		OutStrNokia
				
				
				MOV		R0, #0	;6
				MOV		R1, #3	;1
				BL		SetXYNokia
				LDR		R5, =thres2_title
				bl		OutStrNokia
				
				MOV		R0, #0	;6
				MOV		R1, #4	;1
				BL		SetXYNokia
				LDR		R5, =freqVal_title
				BL		OutStrNokia
				
				;to prevent getting garbage value at reset store 0 at them
				LDR 	R1, =AMPLITUDE
				MOV		R0, #0
				STR		R0, [R1]
				LDR		R1, =FREQ
				STR		R0, [R1]
				LDR		R1, =WRITE_LINE					
				STR		R0, [R1]
				
				;to prevent motor problems after hardware reset
				LDR		R1, =MOTOR_DRIVE_SIGNALS
				MOV		R0, #0x10
				STR		R0, [R1]
				
				LDR		R1, =MOTOR_TURN_DIRECTION
				MOV		R0, #0
				STR		R0, [R1]
				
						
			
				MOV32		R0, 2000000
				
loop
				;when counter reaches 0 then update the display
				SUBS	R0, #1
				BNE		goto_loop
				BL		WRITE_TO_LCD
				MOV32	R0, #2000000
				
				
				;this part is for driving keypad
				LDR		R1, =GPIO_PORTB_DATA   ;get data from PORT
				
				MOV		R2, #0x00
				STR		R2, [R1] ;MAKE ALL OUTPUTS 0
				LDR		R3, [R1] ;GET INPUT
				BL		DELAY100
				LDR		R4, [R1] ;GET INPUT AGAIN
				CMP		R3,R4
				BNE		loop
				BEQ		check_if_p
			
check_if_p		AND		R3, #0x0F
				CMP		R3, #0x0F
				BHS		loop  ;if none of the col input is zero
				BL		find_which
				
				;when a key pressed the code below is executed. 
				;changing the frequency threshold values.
				;R6 keeps the entered number
				;r11 is the MODE FLAG
				;r12 will be the counter
				;C: enter threshold entering mode
				;D: set amplitude threshold
				;E; set low frequency thershold 
				;F; set high frequency threshold
				
				CMP		R11, #8
				BEQ		which_thres_to_set

				CMP		R6, #0xC
				MOVEQ	R11, #0xF			;threshold entering mode
				MOVEQ	R12, #0
				BEQ		goto_loop
				
				CMP		R6, #0xD
				BEQ		set_amp_thresh
				
				CMP		R6, #0xE
				BEQ		set_low_thresh
				
				CMP		R6, #0xF
				BEQ		set_high_thresh
				

				
				
				CMP		R11, #0xf
				BEQ		thres_entering_mode
				BNE		goto_loop
				
				
				

thres_entering_mode	


				PUSH	{r0-r5}
				MOV		R0, #10
				CMP		R12, #0
				MOVEQ	R0, #0

				LDR		R1, =KEYPAD_VAL_BUFFER
				LDR		R2, [R1]
				MLA		R2, R0, R2, R6
				STR		R2, [R1]
				
				ADD		R12, #1
				
				CMP		R12, #3
				MOVEQ	R11, #8 	;FIND WHICH THRESH TO SET

				POP		{r0-r5}
				
which_thres_to_set
				CMP		R6, #0xD
				BEQ		set_amp_thresh
				
				CMP		R6, #0xE
				BEQ		set_low_thresh
				
				CMP		R6, #0xF
				BEQ		set_high_thresh
				
				B 		goto_loop
				
set_amp_thresh
				LDR		R1, =KEYPAD_VAL_BUFFER
				LDR		R2, [R1]
				LDR		R1, =AMPLITUDE_THRESH
				STR		R2, [R1]
				B		clear_regs
				
set_low_thresh
				LDR		R1, =KEYPAD_VAL_BUFFER
				LDR		R2, [R1]
				LDR		R1, =FREQ_LOW_THRESH
				STR		R2, [R1]
				B		clear_regs

set_high_thresh
				LDR		R1, =KEYPAD_VAL_BUFFER
				LDR		R2, [R1]
				LDR		R1, =FREQ_HIGH_THRESH
				STR		R2, [R1]
				B		clear_regs
				
clear_regs		MOV		R11, #0
				MOV		R6, #0
				MOV		R12, #0
				LDR		R1, =KEYPAD_VAL_BUFFER
				STR		R6, [R1]
				
		
goto_loop
	
				B		loop
				
				ENDP
				ALIGN
				
					
					
					
take_fft		PROC
				PUSH	{R0-R10, LR}
				;in this subroutine FFT of the sound samples are taken
				;and dominant frequency with its amplitude is calculated.
				LDR		R0, =arm_cfft_sR_q15_len256
				LDR		R1, =0x20000804
				MOV		R2, #0
				MOV		R3, #1
				BL		arm_cfft_q15
			
				
				LDR		R1, =0x20000804
				
				MOV		R0, #0
				MOV		R4, #0
				MOV		R7, #0x00010000
				
				;find dominant frequency
find_max		LSL		R3, R0, #2
				LDRH	R2, [R1, R3]
				SXTH	R2, R2
				MUL		R6, R2, R2
				
				ADD 	R3, #2
				LDRH	R2, [R1, R3]
;				LSL		R8, R2, #16
;				CMP		R8, #0
;				SUBLT	R2, R7, R2
				SXTH	R2, R2
				MUL		R2, R2, R2
				ADD		R6, R2
				
				
				;HIGHEST magnitude stored in r4, temporary magnitude store in r6
				;index of highest magnitude in r5, current is in r0
				CMP		R6, R4
				MOVGT	R4, R6
				MOVGT	R5, R0				
				CMP		R0, #128
				ADDNE	R0, #1
				BNE		find_max
				
				;store amplitude in memory
				LDR		R8, =AMPLITUDE
				MOV32	R1,#2110000  ; NORMALIZATION
				UDIV	R9,R4,R1
				cmp		r9, #100
				movhs	r9, #100
				STR		R9, [R8]
							
				
				
				;SUB		r5, #128
				MOV		R0, #8
				MUL		R5, R5, R0
				
				;store frequency to memory
				;if frequency is higher than 999 make it 999
				mov32 	r0, #999
				LDR		R8, =FREQ
				CMP		r5, r0
				movhs   r5, r0
				STR		R5, [R8]
				
;				push	{r4, r5}
;				mov		r4, r5
;				LDR		r5, =0X20004000
;				bl		__convrt
;				bl 		OutStr
;				MOV		r5, #0x0a
;				bl		OutChar
;				pop		{r4, r5}
		
				
				;calculate a speed propotional to frequency
				PUSH	{R0, R1, R7}
				MOV32	R7, #142000
				MOV32	R0, #100
				MLS		R7, R5, R0, R7
				LDR		R1, =0x20000400   ;in this address motor speed is stored.
				STR		R7, [R1]				
				POP		{R0, R1, R7}
					
				POP		{R0-R10, LR}
				BX		LR
				ENDP
					
				ALIGN
					
					
DELAY100		PROC
				
				PUSH	{R0, LR}
				LDR		R0, =0x500  ;
				
loop_count		SUBS	R0,#1
				NOP
				NOP
				BNE		loop_count
				
				POP		{R0, LR}
				BX		LR
				ENDP
				ALIGN
					
WRITE_TO_LCD	PROC	
				PUSH	{R0-R6, LR}
				;this subroutine updates the values
				
				;WRITE AMPLITUDE THRESHOLD
				MOV		R0, #44	;6
				MOV		R1, #0	;1
				BL		SetXYNokia
				
				LDR		R5, =EMPTY_SPACE
				BL		OutStrNokia
				
				MOV		R0, #44	;6
				MOV		R1, #0	;1
				BL		SetXYNokia
				LDR		R5, =WRITE_LINE
				LDR		R1, =AMPLITUDE_THRESH
				LDR		R4, [R1]
				STR		R4, [R5]			
				BL		__convrt
				BL		OutStrNokia
				
				;WRITE AMPLITUDE VALUE
				;clear before writing
				LDR		R5, =WRITE_LINE
				MOV		R0, #44	;6
				MOV		R1, #1	;1
				BL		SetXYNokia
				LDR		R5, =EMPTY_SPACE
				BL		OutStrNokia
				
				MOV		R0, #44	;6
				MOV		R1, #1	;1
				BL		SetXYNokia
				
				LDR		R5, =WRITE_LINE
				LDR		R1, =AMPLITUDE
				LDR		R4, [R1]
				BL		__convrt
				BL		OutStrNokia
				
				;WRITE FREQUENCY LOW THRESHOLD
				LDR		R5, =WRITE_LINE
				MOV		R0, #44	;6
				MOV		R1, #2	;1
				BL		SetXYNokia
				LDR		R5, =EMPTY_SPACE
				BL		OutStrNokia
				
				MOV		R0, #44	;6
				MOV		R1, #2	;1
				BL		SetXYNokia
				
				LDR		R5, =WRITE_LINE
				LDR		R1, =FREQ_LOW_THRESH
				LDR		R4, [R1]
				BL		__convrt
				BL		OutStrNokia
				
				;WRITE FREQUENCY HIGH THRESHOLD
				LDR		R5, =WRITE_LINE
				MOV		R0, #44	;6
				MOV		R1, #3	;1
				BL		SetXYNokia
				LDR		R5, =EMPTY_SPACE
				BL		OutStrNokia
				
				MOV		R0, #44	;6
				MOV		R1, #3	;1
				BL		SetXYNokia
				
				LDR		R5, =WRITE_LINE
				LDR		R1, =FREQ_HIGH_THRESH
				LDR		R4, [R1]
				BL		__convrt
				BL		OutStrNokia
				
				
				;WRITE CURRENT FREQUENCY VALUE
				LDR		R5, =WRITE_LINE
				MOV		R0, #44	;6
				MOV		R1, #4	;1
				BL		SetXYNokia
				LDR		R5, =EMPTY_SPACE
				BL		OutStrNokia
				
				MOV		R0, #44	;6
				MOV		R1, #4	;1
				BL		SetXYNokia
				
				LDR		R5, =WRITE_LINE
				LDR		R1, =FREQ
				LDR		R4, [R1]
				BL		__convrt
				BL		OutStrNokia
				
				
				POP		{R0-R6, LR}
				BX		LR

				ENDP
				ALIGN
				END