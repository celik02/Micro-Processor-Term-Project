


			AREA	digital_to, CODE, READONLY
			THUMB
			EXPORT	digital_to_bcd
				
digital_to_bcd	PROC
				PUSH	{R0, R1,R2,  R3}
				
				LDR		R1, =3300
				LDR		R0, =4095
				MUL		R2, R1
				SDIV	R2, R0
				
				; X.YZ, r6, r7, r8 will be used respectively for each digit	and r9 will keep the sign of the number
				CMP		R2, #0
				BGE		pozitif
				BLT		negatif
				
negatif			MOV		R9, #1
				MVN    	R3, R2
				MOV		R2, R3
				ADD		R2, #1
				B		goto

pozitif			MOV		R9, #0
goto			LDR		R1, =1000
				UDIV	R6, R2, R1    ; R6 = R2/R1
				MLS		R3, R6, R1, R2  ; R3 = R2-R6*R1
				
				LDR		R1, =100  
				UDIV	R7, R3, R1
				
				MLS 	R3, R7, R1, R3  ; R3 = R3-R7*R1
				LDR		R1, =10
				UDIV	R8, R3, R1
				
				
				POP		{R0, R1, R2, R3}
				ENDP
				END
