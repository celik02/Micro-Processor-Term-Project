

ascii_c   	EQU			0x30
endOfTran	EQU			0x04 
FREQ		EQU			0x2000060C
Write_Line	EQU			0x20001200



			AREA		CONVRT, READONLY, CODE
			THUMB
			EXPORT 		__convrt
			
				
__convrt	PROC
			PUSH		{R0, R1, R2, R3, R4, R5}
			MOV			R2, #10
			LDR			R0,=endOfTran  
			PUSH		{R0}
			MOV 		R3, R4  
			
		
loop		UDIV		R3, R3, R2     ; R3 keeps the division result
			MLS			R1, R2, R3, R4 ; R1 keeps the LSB of the num
			ADD			R1, #ascii_c   ;Add the offset to make it ascii formatted
			PUSH		{R1}		   
			MOV			R4, R3
			CMP			R4, #0			;if number is 0 finish "loop"
			BNE			loop
			
loop_prnt	POP			{R1}			;get each digit back from stack
			CMP 		R1, R0   		;Compare if end of line sign is came
			BEQ			finish
			
			STRB		R1, [R5], #1	;store to memory, increment mem address by 1
			B			loop_prnt
			
			
finish		STR			R0, [R5]		;store the end of line in the end of the number

			POP			{R0, R1, R2, R3, R4, R5}			;restore starting address of the number
			
			BX			LR
			
			ENDP
				
			END