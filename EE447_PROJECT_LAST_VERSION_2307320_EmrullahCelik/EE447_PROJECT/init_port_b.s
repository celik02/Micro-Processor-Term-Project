;PORT C
GPIO_PORTC_DATA		EQU		0x400063FC
GPIO_PORTC_DIR		EQU		0x40006400
GPIO_PORTC_AFSEL	EQU		0x40006420
GPIO_PORTC_PUR		EQU		0x40006510
GPIO_PORTC_PDR	 	EQU		0x40006514
GPIO_PORTC_DEN	 	EQU		0x4000651C
GPIO_PORTC_AMSEL 	EQU		0x40006528
RCGCGPIO			EQU		0x400FE608
;PORT F
GPIO_PORTF_DATA		EQU 	0x4002507C ; data address of PF1,2,3
GPIO_PORTF_DIR		EQU 	0x40025400
GPIO_PORTF_AFSEL 	EQU 	0x40025420
GPIO_PORTF_DEN 		EQU 	0x4002551C
GPIO_PORTF_AMSEL	EQU 	0x40025528
GPIO_PORTF_LOCK		EQU		0x40025520
GPIO_PORTF_OCR		EQU		0x40025524
GPIO_PORTF_PCTL		EQU		0x4002552C
GPIO_PORTF_PUL		EQU		0x40025510
;TO enable interrupt
GPIO_PORTF_ICR		EQU		0x4002541C
NVIC_EN0			EQU 	0xE000E100	
GPIO_PORTF_INE		EQU		0x000000B8
GPIO_PORTF_IMR		EQU		0x40025410

NVIC_PRI7			EQU     0xE000E41C
	
MOTOR_TURN_DIRECTION EQU 0x200007F8

;Modules in this file
;init_port_b
;init_port_f
;SwitchHandler

;priority of portF changed so that it does not prevents motor from rotating. Otherwise
;when switch was hold pressed, motor was not rotating.
;after dropping the interrupt priotity of gpio_port_f the problem solved.
				AREA 		init_portb, CODE, READONLY
				THUMB
				EXPORT  	init_port_c
				EXPORT		init_port_f
				export		SwitchHandler
	
				
SwitchHandler	PROC
				;this is an interrupt  service subroutine (ISR). When interrupt occurs on portF this subroutine
				;will be called.
				;This subroutine changes motor's rotation direction
				PUSH	{LR}
	
read_again		LDR		R1, =GPIO_PORTF_DATA
				LDR		R0, [R1]
				BL		DELAY100
				LDR		R2, [R1]
				CMP		R2, R0
				BNE		read_again
				
				
				AND		R2, #0x11
				CMP		R2, #0x01
				BEQ		cw_turn
				CMP		R2, #0x10
				BEQ		ccw_turn
				bne		goto

cw_turn			LDR		R2, [R1]
				AND		R2, #0x11
				CMP		R2, #0x11
				BNE		cw_turn
				MOV		R0, #0
				B		store_mem
				
ccw_turn		LDR		R2, [R1]
				AND		R2, #0x11
				CMP		R2, #0x11
				BNE		ccw_turn
				MOV		R0, #0xFF
				
store_mem		LDR		R1, =MOTOR_TURN_DIRECTION  ;motor rotation direction
				STR		R0, [R1]
goto				
				;clear the interrupts invoked by pin0 and pin4 to enable further interrupts
				LDR		R1, =GPIO_PORTF_ICR
				MOV		R0, #0x11
				STR		R0, [R1]
	
				POP		{LR}
				BX 		LR
				ENDP
					
					
init_port_c		PROC
				PUSH	{R0, R1, LR}
				LDR		R1, =RCGCGPIO ;initialize the clock
				LDR		R0, [R1]
				ORR		R0, R0, #0x3F
				STR		R0, [R1]
				
				NOP
				NOP
				NOP
				
				LDR 	R1, =GPIO_PORTC_DIR ;SET THE DIRECTION BITS
				LDR		R0, [R1]
				ORR		R0, R0, #0xF0
				STR		R0, [R1]
				
				LDR		R1, =GPIO_PORTC_AFSEL ;set alternate function off
				LDR		R0, [R1]
				AND		R0, #0x00
				STR		R0,[R1]
				
				LDR		R1, =GPIO_PORTC_DEN
				MOV		R0, #0xFF
				STR		R0, [R1]
				LDR		R1, =GPIO_PORTC_AMSEL
				MOV		R0, #0
				STR		R0, [R1]
				
				LDR		R1, =GPIO_PORTC_PUR
				MOV		R0, #0x00
				STR		R0, [R1]
				
				LDR		R1, =GPIO_PORTC_DATA
				POP     {R0, R1, LR}
				BX		LR
				ENDP
				ALIGN
				
init_port_f		PROC
				
				PUSH		{R0-R2, LR}
				LDR			R1, =GPIO_PORTF_LOCK  ;to unclock PF0
				LDR			R0, =0x4C4F434B
				STR			R0, [R1]
				
				LDR			R1, =GPIO_PORTF_OCR
				LDR			R0, =0x3F
				STR			R0, [R1]
				
				LDR			R1, =GPIO_PORTF_LOCK  ;to unclock PF0
				LDR			R0, =0x4C4F434B
				STR			R0, [R1]
				
				LDR			R1,=GPIO_PORTF_DIR
				LDR			R0,[R1]
				BIC			R0,#0xff
				ORR			R0,#0x0E		;MAKE PF1,2,3 OUTPUT and PF0,4 as INPUT
				STR			R0,[R1]		
				
				LDR			R1,=GPIO_PORTF_AFSEL
				LDR			R0,[R1]
				BIC			R0,#0xFF	
				STR			R0,[R1]	
				
				LDR			R1,=GPIO_PORTF_PCTL
				MOV			R0, #0
				STR			R0, [R1]

				LDR			R1,=GPIO_PORTF_DEN
				LDR			R0,[R1]
				ORR			R0,#0xFF		;DISABLE DEN
				STR			R0,[R1]	
				
				LDR			R1,=GPIO_PORTF_AMSEL
				LDR			R0,[R1]
				BIC			R0,#0xFF		
				STR			R0,[R1]		
				
				LDR			R1, =GPIO_PORTF_PUL
				LDR			R0, =0x10
				STR			R0, [R1]
				
				
				
				LDR			R1, =GPIO_PORTF_DATA
				LDR			R0, =0xF8
				STR			R0, [R1]
				
				
				;just enable interrupt from pin0 and pin4 since switches are on
				;that pins
				LDR			R1, =GPIO_PORTF_IMR
				MOV			R0, #0x11
				STR			R0, [R1]
				
				;SET interrupt priority, so that motor does not halts during handling
				LDR			R1, =NVIC_PRI7
				LDR			R0, [R1]
				MOV32		R2, #0x00f00000
				ORR			R0, R2
				STR			R0, [R1]
				
				POP			{R0-R2, LR}
				BX			LR
				ENDP
				ALIGN
				
DELAY100		PROC
				
				PUSH	{R0, LR}
				LDR		R0, =0x10  ;
				
loop_count		SUBS	R0,#1
				NOP
				NOP
				BNE		loop_count
				
				POP		{R0, LR}
				BX		LR
				ENDP
				ALIGN
				END