			AREA	find_which_, READONLY, CODE
			THUMB
			EXTERN	OutChar
			EXTERN	DELAY100
			EXPORT find_which


find_which	PROC
			;uses existing r1 and r4 values
			PUSH	{R0, R1, R2, R3, R4, R5,LR}
			MOV		R2, #0xE0  ; first row
			STR		R2, [R1]
			BL		delay50
			LDR		R0, [R1]
			AND		R0, #0x0F
			CMP		R0, #0x0F
			MOV		R4, #0     ;R4 will keep the offset for ID
			BCC		found

			MOV		R2, #0xD0   ;second row
			MOV		R4, #4
			STR		R2, [R1]
			BL		delay50
			LDR		R0, [R1]
			AND		R0, #0x0F
			CMP		R0, #0x0F
			
			BCC		found
			
			MOV		R2, #0xB0   ;third row
			STR		R2, [R1]
			BL		delay50
			LDR		R0, [R1]
			AND		R0, #0x0F
			CMP		R0, #0x0F
			MOV		R4, #8
			BCC		found
			
			
			MOV		R2, #0x70   ;fourth row
			STR		R2, [R1]
			BL		delay50
			LDR		R0, [R1]
			AND		R0, #0x0F
			CMP		R0, #0x0F
			MOV		R4, #12
			BCC		found
			BHS		not_found

		
found		CMP		R0, #0x0E
			MOVEQ	R5, #0
			BEQ		id
			
			CMP		R0, #0x0D
			MOVEQ	R5, #1
			BEQ		id

			CMP		R0, #0x0B
			MOVEQ	R5, #2
			BEQ		id
			
			CMP		R0, #0x07
			MOVEQ	R5, #3
			BEQ		id

id			ADD		R5,R5,R4

NotReleased	LDR		R0, [R1]
			AND		R0, #0x0F
			CMP		R0, #0x0F
			BNE		NotReleased
			BL		DELAY100
			LDR		R0, [R1]
			AND		R0, #0x0F
			CMP		R0, #0x0F
			BNE		NotReleased
			
			;convert to ascii
			CMP		R5,#10
			MOV		R6, R5
			BCC		decimal
			BHS		hex
			
decimal		
			ADD		R5,R5,#0x30
			B		the_end
			
hex			ADD		R5, R5, #55
			
			
the_end		BL		OutChar  ;ptint the key ID
			MOV		R5, #44  ; coma
			BL		OutChar  ; print the coma
			
not_found	POP		{R0, R1, R2, R3, R4, R5,LR}
			BX		LR
			ENDP
				
				
delay50		PROC
			PUSH	{R0, LR}
			LDR		R0, =0x100 ;Frequency assumed to be 12MHz
			
loop		SUBS	R0,#1
			NOP
			NOP
			BNE		loop
			
			POP		{R0, LR}
			BX		LR	
			ENDP
			ALIGN
			END