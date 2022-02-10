;LABEL DIRECTIVE VALUE COMMENT
ADC0 			EQU 0x40038000 ; ADC0 base address
ADCACTSS 		EQU 0x40038000 ; active sample sequencer
ADCEMUX 		EQU 0x40038014 ; e ven t m ul ti pl e x e r
ADCSSMUX3		EQU 0x400380A0 ; sample sequencer input multiplexer
ADCSSCTL3 		EQU 0x400380A4 ; sample se quence c o n t r o l
ADCPC 			EQU 0x40038FC4 ; P e ri p h e r al C o n fi g u r a ti o n
	
ADCSSMUX2		EQU 0x40038080 ; sample sequencer input multiplexer
ADCSSCTL2 		EQU 0x40038084 ; sample se quence c o n t r o l

SYSCTL_RCGCADC 	EQU 0x400FE638
PRADC 			EQU 0x400FEA38
;LABEL        	DIRECTIVE VALUE COMMENT
				AREA 		routine , READONLY, CODE
				THUMB
				EXPORT 		atd_setup
;LABEL 			DIRECTIVE VALUE COMMENT
atd_setup	    PUSH 		{R0 , R1}
				;enable the clock
				LDR 		R1,=SYSCTL_RCGCADC
				LDR 		R0, [R1]
				ORR 		R0, R0, #0x01 ; enable ADC0 module
				STR 		R0, [R1]
				;let the peripheral get ready
				LDR 		R1, =PRADC
wait 			LDR 		R0, [R1]
				AND 		R0, #0x00000001 ; mask bit 0 , adc0 peripheral ready bit
				CMP 		R0, #1
				BNE 		wait
				;disable sample sequencer 3
				LDR 		R1,=ADCACTSS
				LDR 		R0, [R1]
				BIC 		R0, #0x08 ; disable sample sequencer 3
				STR 		R0, [R1]
				;choose triggering event
				LDR 		R1, =ADCEMUX ; triggering via software
				LDR 		R0, [R1]
				BIC 		R0, #0x0000F000 ; clear bits 15:12
				STR 		R0, [R1]
				;choose which channel to use
				LDR 		R1, =ADCSSMUX3; iinput select of SS3
				LDR 		R0, [R1]
				BIC 		R0, #0x0000000F ; clear first input area
				ORR 		R0, #0x00000001 ; select IN1 as input , 0 written to first input area
				STR 		R0, [R1]
				;enable setting RIS bits and stop after 1 sampling
				LDR 		R1, =ADCSSCTL3
				LDR 		R0, [R1]
				ORR 		R0, #0x04 ; set IE0 to 1 , for flags in RIS , i.e. interrupt enable
				ORR 		R0, #0x02 ; set END0 to 1 , to stop sampling after this sample
				STR 		R0, [R1]
				;specify sampling rate
				LDR 		R1, =ADCPC
				LDR 		R0, [R1]
				BIC 		R0, #0x0F ; first clear
				ORR 		R0, #0x01 ; set bits 3:0 to 1 for 125 ksps
				STR 		R0, [R1]
				
				LDR 		R1, =ADCACTSS
				LDR 		R0, [R1]
				ORR 		R0, #0x08 ; enable sequencer 3
				STR			R0, [R1]

;***********************************************************new

				LDR 		R1,=ADCACTSS
				LDR 		R0, [R1]
				BIC 		R0, #0x04 ; disable sample sequencer 3
				STR 		R0, [R1]
				;choose triggering event
				LDR 		R1, =ADCEMUX ; triggering via software
				LDR 		R0, [R1]
				BIC 		R0, #0x00000F00 ; clear bits 11:8
				STR 		R0, [R1]
				;choose which channel to use
				LDR 		R1, =ADCSSMUX2; iinput select of SS3
				LDR 		R0, [R1]
				BIC 		R0, #0x000000FF ; clear first input area
				ORR 		R0, #0x00000010 ; select IN0 and IN1 as input , 0 written to first input area
				STR 		R0, [R1]
				;enable setting RIS bits and stop after 1 sampling
				LDR 		R1, =ADCSSCTL2
				LDR 		R0, [R1]
				ORR 		R0, #0x044 ; set IE0 to 1 , for flags in RIS , i.e. interrupt enable
				ORR 		R0, #0x020 ; set END0 to 1 , to stop sampling after this sample
				STR 		R0, [R1]
				;specify sampling rate
				LDR 		R1, =ADCPC
				LDR 		R0, [R1]
				BIC 		R0, #0x0F ; first clear
				ORR 		R0, #0x01 ; set bits 3:0 to 1 for 125 ksps
				STR 		R0, [R1]
				
				LDR 		R1, =ADCACTSS
				LDR 		R0, [R1]
				ORR 		R0, #0x04 ; enable sequencer 2
				STR			R0, [R1]


;***********************************************************new
				POP 		{R0, R1}
				BX 			LR
				ALIGN
				END
