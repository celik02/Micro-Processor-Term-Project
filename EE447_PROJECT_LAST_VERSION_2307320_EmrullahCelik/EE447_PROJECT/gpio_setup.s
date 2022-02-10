GPIO_PORTE_DATA 	EQU 0x400243FC ; data address to all pins
GPIO_PORTE_DIR 		EQU 0x40024400
GPIO_PORTE_AFSEL 	EQU 0x40024420
GPIO_PORTE_DEN 		EQU 0x4002451C
GPIO_PORTE_PUR 		EQU 0x40024510
GPIO_PORTE_AMSEL 	EQU 0x40024528 ; Analog Mode select
GPIO_PORTE_PCTL 	EQU 0x4002452C ; alternate function select
SYSCTL_RCGCGPIO 	EQU 0x400FE608 ;clock
	
	
;portC configuration for keypad driver
GPIO_PORTB_DATA	 EQU	0x400053FC
GPIO_PORTB_DIR	 EQU	0x40005400
GPIO_PORTB_AFSEL EQU	0x40005420
GPIO_PORTB_PUR	 EQU	0x40005510
GPIO_PORTB_PDR	 EQU	0x40005514
GPIO_PORTB_DEN	 EQU	0x4000551C
GPIO_PORTB_AMSEL EQU	0x40005528
RCGCGPIO		 EQU	0x400FE608
	
	
					AREA    gpio_stup_, CODE, READONLY
					THUMB
					EXPORT	gpio_setup
			
gpio_setup			PROC
					PUSH	{R0, R1}
					LDR		R1, =SYSCTL_RCGCGPIO
					LDR		R0, [R1]
					ORR		R0, #0x3F  ;enable all ports
					STR		R0, [R1]
					
					NOP
					NOP
					NOP
					
					LDR		R1, =GPIO_PORTE_AFSEL
					LDR		R0, [R1]
					ORR		R0, #0x0F	;enable alternate function for Pin E3 and PE2
					STR		R0, [R1]
					
					LDR		R1, =GPIO_PORTE_DIR
					LDR		R0, [R1]
					BIC		R0, #0x0F  ;set PE3 as input and PE2
					STR		R0, [R1]
					
					LDR		R1, =GPIO_PORTE_DEN
					LDR		R0, [R1]
					BIC		R0, #0x0F  ;disable digital mode for PE3 and PE2
					STR		R0, [R1]
					
					LDR		R1, =GPIO_PORTE_AMSEL
					LDR		R0, [R1]
					ORR		R0, #0x0F
					STR		R0, [R1]
					
					
					;init portB for keypad
					LDR 	R1, =GPIO_PORTB_DIR ;SET THE DIRECTION BITS
					LDR		R0, [R1]
					ORR		R0, R0, #0xF0
					STR		R0, [R1]
					
					LDR		R1, =GPIO_PORTB_AFSEL ;set alternate function off
					LDR		R0, [R1]
					AND		R0, #0x00
					STR		R0,[R1]
					
					LDR		R1, =GPIO_PORTB_DEN
					MOV		R0, #0xFF
					STR		R0, [R1]
					LDR		R1, =GPIO_PORTB_AMSEL
					MOV		R0, #0
					STR		R0, [R1]
					
					LDR		R1, =GPIO_PORTB_PUR
					MOV		R0, #0x0F    ;pull inputs to VCC
					STR		R0, [R1]
					
					
					POP		{R0, R1}
					BX		LR
					
					ALIGN
					ENDP
					END