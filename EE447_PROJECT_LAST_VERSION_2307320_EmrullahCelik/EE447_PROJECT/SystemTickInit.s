STCTRL			EQU		0xE000E010
STRRELOAD		EQU		0xE000E014
STCURRENT		EQU		0xE000E018
SYSPRI3			EQU		0xE000ED20	


				AREA   INIT_SYSTICK_, CODE, READONLY
				THUMB
				EXPORT  INIT_SYSTICK
				EXPORT	systick_subR
				EXTERN	atd_sample
				EXTERN	atd_start
				EXTERN	take_fft

INIT_SYSTICK 	PROC
				PUSH	{R0, R1, LR}
				LDR		R1, =STCTRL
				MOV		R0, #0
				STR		R0, [R1]
				
				LDR		R1, =STRRELOAD
				LDR		R0, =2000
				STR		R0, [R1]
				
				LDR		R1, =STCURRENT
				STR		R0, [R1]
				
				LDR		R1, =SYSPRI3
				MOV		R0, #0x40000000
				STR		R0, [R1]
				
				LDR		R1, =STCTRL
				MOV		R0, #0x00003
				STR		R0, [R1]
				
				
				POP		{R0, R1, LR}
				BX		LR
		
				ENDP
					
systick_subR	PROC
				;samples the ADC modules periodicly
				PUSH	{R4,LR}
				BL		atd_start
				BL		atd_sample
				
				
				LDR		R0, =0x20000800
				LDR		R1, [R0]
				LSL		R3, R1, #2
				SUB		R2, #0x60F
				LSL		R2, #4
				MOV32	R4, #0x0000FFFF
				AND		R2, R4
				STR		R2, [R0, R3]
				
				CMP		R1, #256
				BNE		cont	
				MOVEQ	R1, #0
				BL		take_fft
				
cont			ADDNE	r1, #1
				;BEQ		goto_freq_cal				
				STR		R1, [R0]
				POP		{R4, LR}
				BX		LR
				
				ENDP
				ALIGN
				END