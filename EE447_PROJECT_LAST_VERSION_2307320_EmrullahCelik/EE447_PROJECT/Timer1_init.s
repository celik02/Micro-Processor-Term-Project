; 16/32 Timer Registers
TIMER1_CFG 			EQU 		0x40031000
TIMER1_TAMR 		EQU 		0x40031004
TIMER1_CTL 			EQU 		0x4003100C
TIMER1_IMR 			EQU 		0x40031018
TIMER1_RIS 			EQU 		0x4003101C 		; Timer Interrupt Status
TIMER1_ICR 			EQU 		0x40031024 		; Timer Interrupt Clear
TIMER1_TAILR 		EQU 		0x40031028 		; Timer interval
TIMER1_TAPR 		EQU 		0x40031038 		; Prescaling Divider
TIMER1_TAR 			EQU 		0x40031048 		; Timer register
TIMER1_TAV 			EQU 		0x40031050 		; Timer register	
SYSCTL_RCGCTIMER 	EQU 		0x400FE604 		; GPTM Gate Control
GPIO_PORTF_DATA		EQU 		0x4002507C 		; data address of PF1,2,3
SHINING_LED			EQU			0x20000600
AMPLITUDE			EQU			0x20000610	
AMPLITUDE_THRESH    EQU			0x20000630
FREQ				EQU			0x20000650
	
FREQ_LOW_THRESH		EQU			0x20000660
FREQ_HIGH_THRESH	EQU			0x20000670
	
					AREA 		timer1_code, CODE, READONLY
					THUMB
					EXPORT 		timer1_init
					EXPORT		LED_PWM_SUB
						
LED_PWM_SUB			PROC
					PUSH	{R0-R10, LR}
					
;					LDR		R1, =SHINING_LED
;					LDR		R0, [R1]
;					CMP		R0, #0
;					BNE		TURN_ON_LED
					LDR		R1, =AMPLITUDE
					LDR		R4, [R1]          		; R4 stores the amplitude value
					
					CMP		R4, #100
					MOVHS	R4, #100
					
					LDR		R1, =AMPLITUDE_THRESH
					LDR		R2, [R1]
					CMP		R4, R2
					BLT		turn_off_all_leds
					
					LDR		R1, =FREQ
					LDR		R5, [R1]	;GET LAST FREQUENCY VALUE FROM MEMORY
;----------------------------------------------------------------
					LDR		R1, =GPIO_PORTF_DATA
					LDR		R2, [R1]
					AND		R2, #0xE
					CMP		R2, #0
					BNE		turn_off_all_leds
					
					CMP		r5, #0
					BEQ		turn_off_all_leds
					
					LDR		R1, =FREQ_LOW_THRESH
					LDR		R1, [R1]
					CMP		R5, R1
					BCC		low_thresh
					
					LDR		R1, =FREQ_HIGH_THRESH
					LDR		R1, [R1]
					CMP		R5, R1
					BCC		mid_thresh
					B		high_thresh
				
					;in this part all leds are turned off
turn_off_all_leds	
					LDR		R1, =GPIO_PORTF_DATA
					MOV		R0, #0
					STR		R0, [R1]
					LDR		R1, =TIMER1_TAILR
					MOV		R2, #100
					SUB		R4, R2, R4
					STR		R4,[R1]
					B		exit_sub
				
				
					;change color of leds according to noise freq
low_thresh			MOV		R0, #0x02
					b		change_led
				
mid_thresh			MOV		R0, #0x8
					b		change_led
				
high_thresh			MOV		R0, #0x4

change_led			LDR		R1, =GPIO_PORTF_DATA
					STR		R0, [R1]
					LDR		R1, =TIMER1_TAILR
					STR		R4, [R1]
			
		
;--------------------------------------------------------------
	
exit_sub			LDR		R1, =TIMER1_ICR
					MOV		R0, #0x01
					STR		R0, [R1]

					POP		{R0-R10, LR}					

					BX 		LR
					ENDP
						
;*****************************************************************************************************
timer1_init			PROC
					PUSH		{R0-R6, LR}
					LDR 		R1, =SYSCTL_RCGCTIMER 		; Start Timer0
					LDR 		R0, [R1]
					ORR 		R0, R0, #0x02
					STR 		R0, [R1]
					NOP 									; allow clock to settle
					NOP
					NOP
					LDR			R1, =TIMER1_CTL 			; disable timer during setup 
					LDR 		R0, [R1]
					BIC 		R0, R0, #0x01
					STR 		R0, [R1]
					LDR 		R1, =TIMER1_CFG 			; set 16 bit mode
					MOV 		R0, #0x04
					STR 		R0, [R1]
					
					LDR 		R1, =TIMER1_TAMR
					MOV 		R0, #0x02					; set to periodic, countdown
					STR			R0, [R1]
					
;					LDR			R1, =TIMER1_CTL
;					LDR			R0, [R1]
;					AND			R0, R0, #0x0C 				;edge detection for both
;					STR			R0, [R1]
					
					LDR 		R1, =TIMER1_TAILR 			; initialize match clocks
					LDR 		R0, =0xff
					STR 		R0, [R1]
					
					LDR 		R1, =TIMER1_TAPR
					MOV 		R0, #15 					; prescale so that clk is 1khz
					STR 		R0, [R1] 					; 
					
					LDR 		R1, =TIMER1_IMR 			; enable timeout interrupt
					MOV 		R0, #0x01
					STR 		R0, [R1]
					
					;enable the timer
					LDR			R1, =TIMER1_CTL
					LDR			R0, [R1]
					ORR			R0, R0, #0x03  				;bit0 set to 1->enable
					STR	 		R0, [R1]
					
					LDR		R1, =TIMER1_ICR
					MOV		R0, #0x01
					STR		R0, [R1]
					
					POP			{R0-R6, LR}
					BX			LR
										
					ENDP			
					ALIGN
					END