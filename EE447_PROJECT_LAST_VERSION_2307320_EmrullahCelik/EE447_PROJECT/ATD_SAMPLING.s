ADC0 		EQU 0x40038000
ADCACTSS 	EQU 0x40038000 ; active sample sequencer
ADCEMUX 	EQU 0x40038014 ; event multiplexer
ADCSSMUX3 	EQU 0x400380A0 ; sample sequence input multiplexer
ADCSSCTL3 	EQU 0x400380A4 ; sample sequence control
ADCPC 		EQU 0x40038FC4 ; Peripheral configuration
; below for sampling
ADCISC 		EQU 0x4003800C ; Interrupt Status and Clear
ADCPSSI 	EQU 0x40038028 ; Process or sample sequence initiate
ADCRIS 		EQU 0x40038004 ; Raw Interrupt Status
ADCSSFIFO3 	EQU 0x400380A8 ; FIFO
	
ADCSSMUX2		EQU 0x40038080 ; sample sequencer input multiplexer
ADCSSCTL2 		EQU 0x40038084 ; sample se quence c o n t r o l
ADCSSFIFO2		EQU 0x40038088

AMPLITUDE_THRESH    EQU			0x20000630  ; instead of 608 make 648 to test
	
			AREA adt_sampling_, CODE, READONLY
			THUMB
			EXPORT	atd_start
			EXPORT	atd_sample
				
atd_start	PROC
			PUSH	{R0, R1}
			LDR		R1, =ADCPSSI
			LDR		R0, [R1]
			ORR		R0, #0x0c	;start SS3
			STR		R0, [R1]
			POP		{R0, R1}
			BX		LR
			ENDP
				
atd_sample	PROC
			;samples the MIC and stores the values in memory
			;also pot is sampled here from FIFO3
			PUSH	{R0, R1,r3,R4}
			LDR		R1, =ADCRIS
wait		LDR		R0, [R1]
			AND		R0, #0x0c   ; 
			CMP		R0, #0x0c   ;when sampling finishes it's equal  
			BNE		wait
			
			
			
			LDR 	R1,=ADCSSFIFO2   
			LDR		R2, [R1]
			
			;store amplitude threshold to memory
			
			
			LDR 	R1,=ADCSSFIFO3   
			LDR		R3, [R1]
			MOV		R4, #39
			UDIV	R3, R4
			CMP		R3, #100
			MOVHI   R3, #100
			CMP		R3, #0
			MOVLS	R3, #0
			
			LDR		R1, =AMPLITUDE_THRESH
			;STR		R3, [R1]
			
			LDR		R1, =ADCISC
			LDR		R0, [R1]
			ORR		R0, #0x0C   ;enale SS3 again for it to continue   
			STR		R0, [R1]  
			
			POP		{R0, R1,r3, R4}
			BX		LR
					
			ENDP
			ALIGN
			END
				