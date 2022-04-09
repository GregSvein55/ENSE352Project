; ENSE 352 Final Project
;
; File: WhackaMole.s
; Class: ENSE 352
; Date: Nov. 20, 2021
; Programmer: Gregory Sveinbjornson
; Description: Source code for ENSE352 Whack-A-Mole program on the ARM Cortex M3


;M3 microcontroller.
	PRESERVE8
	THUMB

;Initial Main Stack Pointer Value
INITIAL_MSP 	EQU 0x20001000
	
;Port A	
GPIOA_CRL 		EQU 0x40010800
GPIOA_ODR 		EQU 0x4001080C  
GPIOA_IDR 		EQU 0x40010808  
GPIOA_CRH 		EQU 0x40010804  

;Port B
GPIOB_CRL 		EQU 0x40010C00
GPIOB_ODR 		EQU 0x40010C0C
GPIOB_IDR 		EQU 0x40010C08
GPIOB_CRH 		EQU 0x40011004
	
;Clock Registers
RCC_APB2ENR 	EQU 0x40021018
		
;Delay Timer
PRELIM_WAIT 	EQU 0x50000
START_WAIT 		EQU 0x100000
REACT_TIME		EQU 0x70005
END_WAIT		EQU 0x100000
SHOW_SCORE		EQU 0x5000000

;Random number generator
;A * X + C
RND_A			EQU 1664525
RND_C			EQU 1013904223

		
;Number of blinks
NUM_BLINKS		EQU 0xF

;Vector Table Mapped to Address 0 at Reset, Linker requires __Vectors to be exported
	AREA RESET, DATA, READONLY
	EXPORT 	__Vectors

__Vectors 	DCD INITIAL_MSP ; stack pointer value when stack is empty
			DCD Reset_Handler ; reset vector

;My program, Linker requires Reset_Handler and it must be exported
	AREA MYCODE, CODE, READONLY
	ENTRY

	EXPORT Reset_Handler
		
Reset_Handler  PROC 

	BL ClockInit
	BL SetIO		;;UC1 - System Startup
Loop
	BL WAIT		;;UC2 - Wait for Player
	BL GAME_START
	B Loop
	
	ENDP

	ALIGN
ClockInit PROC
	
	LDR R6, =RCC_APB2ENR
	MOV R0, #0xC
	STR R0, [R6]
	
	BX LR
	ENDP

	ALIGN
SetIO PROC

	;;Enable Port A
	
	LDR R6, =GPIOA_CRL
	LDR R0, [R6]
	LDR R2,	=0x00030033
	ORR R0, R0, R2
	
	LDR R2, =0xFFF3FF33
	AND R0, R0, R2
	
	STR R0, [R6]

	;;Enable Port B
	
	LDR R6, =GPIOB_CRL
	LDR R0, [R6]
	LDR R2,	=0x00000003
	ORR R0, R0, R2
	
	LDR R2, =0xFFFFFFF3
	AND R0, R0, R2
	
	STR R0, [R6]
	
	BX LR
	ENDP
	
	ALIGN
	
WAIT PROC
	
	LDR R6, =GPIOA_ODR   ;;Port A Address
	LDR R7, =GPIOB_ODR   ;;Port B Address
	LDR R8, =GPIOB_IDR	 ;;Button Port
	LDR R3, =0x0 		 ;;for turning off LED in opposite port
	
	LDR R0, =0x1
	STR R0, [R6]
	STR R3, [R7]
	
	LDR R10, =0x0   ;; SEED RND counter
	
waitForButton

	;;Toggle LEDs
	
	LDR R5, =PRELIM_WAIT   ;;Delay value	
	
delay_LED1     			  ;delay LED 
	CMP R5, #0
	SUBNE R5, R5, #1
	ADD R10, #1
	BNE delay_LED1

	LDR R1, [R6]
	LDR R2, [R7]
	
	CMP R1, #1
	MOVEQ R3, #2
	MOVEQ R4, #0
	BEQ toggleLED

	CMP R1, #2
	MOVEQ R3, #16
	MOVEQ R4, #0
	BEQ toggleLED
	
	CMP R1, #16
	MOVEQ R3, #0
	MOVEQ R4, #1
	BEQ toggleLED
	
	CMP R2, #1
	MOVEQ R3, #1
	MOVEQ R4, #0
	BEQ toggleLED

;Polling Buttons;
;
;		Register Functions:
;		R0 - address for GPIOA
;		R1 - address for GPIOB
;		R2 - read from GPIO
;		R3 - store from Port A
;		R4 - store from Port B
;		R5 - store result of AND


toggleLED
	STR R3, [R6]
	STR R4, [R7]

	LDR R0, =GPIOB_IDR
	LDR R2, [R0]
	LDR R1, =0xFFFF
	
	EOR R2, R1
	LDR R1, =0x350 
	AND R2, R1 
	
	CMP R2, #0
	BGT startButtonPressed
	
	b waitForButton

startButtonPressed
	LDR R6, =GPIOA_ODR   ;Port A Address
	LDR R7, =GPIOB_ODR   ;Port B Address
	
	PUSH {R6, R7}
	LDR R1, =0x0
	
	STR R1, [R6]
	STR R1, [R7]
	LDR R5, =START_WAIT
	
delay_Start   ;delay LED On
	CMP R5, #0
	SUBNE R5, R5, #1
	BNE delay_Start
	
	BX LR
	ENDP
	ALIGN

; Random LED Selection
;		
;		Register Functions:
;		R0 Score Counter
;		R1 Round Counter
;		R2 ReactTime
;		R3, R4 Store LED codes
;		R5 BTN input mask
;		R6,R7,R8  store port addresses
; 		R9 - modulus function
;		R10 - old seed
;		R11, R12 - store A and C for rnd
;		
; 		const RND_A and RND_C
;  		A * X + C

GAME_START PROC
 
	POP {R6, R7}
	PUSH {R10}
	
	MOV R9, #0
	MOV R0, #0
	MOV R1, #15
	
	LDR R2, =REACT_TIME
chooseLED
	LDR R5, =START_WAIT
	
pause
	CMP R5, #0
	SUBNE R5, R5, #1
	BNE pause
	
	POP {R10}
	LDR R11, =RND_A
	LDR R12, =RND_C
	
	MUL R10, R10, R11
	ADD R10, R10, R12
	PUSH {R10}
	
	LSR R10, #28
	AND R10, #0x00000003


; Perform Modulus 4 to get random LED
;
;		Copy R10 to R9 so we can save original Value
;		Store #4 in register udiv to store quotient
;		Multiply orginal by modulus
;		Subtract difference for remainder


	MOV R9, R10
	MOV R11, #4                    	      
	UDIV R9, R9, R11  
	MUL R9, R11  
	SUBS R9, R10, R9 


;	Turn on Random LED
;   Use value in R10
;	Value ranges from 0-3
;	corresponds to LED number
;	store btn num in R5	
	
	MOV R3, #0
	MOV R4, #0
	STR R3, [R6]
	STR R4, [R7]
	
; LED 1
	CMP R9, #0
	MOVEQ R3, #1
	MOVEQ R5, #0x10
	BEQ RND_ON

; LED 2
	CMP R9, #1
	MOVEQ R3, #2
	MOVEQ R5, #0x40
	BEQ RND_ON

; LED 3
	CMP R9, #2
	MOVEQ R3, #16
	MOVEQ R5, #0x100
	BEQ RND_ON
	
; LED 4
	CMP R9, #3
	MOVEQ R4, #1
	MOVEQ R5, #0x200
	BEQ RND_ON

RND_ON
	STR R3, [R6]
	STR R4, [R7]
	MOV R9, R2
	
wait_for_whack
	
;   Check if button was pressed
	
	LDR R12, [R8]
	LDR R11, =0xFFFF
	EOR R12, R11
	MOV R11, R5   
	AND R12, R11 
	
	CMP R12, #0
	BGT hitButton
	
	CMP R9, #0
	SUBNE R9, R9, #1
	BNE wait_for_whack
	b newLED
	
hitButton
	ADD R0, #1
	SUB R2, #0x5000
newLED
	MOV R3, #0x0
	MOV R4, #0x0
	STR R3, [R6]
	STR R4, [R7]
	SUB R1, #1
	CMP R1, #0
	BEQ endGame
	b chooseLED
	
endGame
	MOV R3, #0x13
	MOV R4, #0x1
	STR R3, [R6]
	STR R4, [R7]
	LDR R5, =END_WAIT
pauseEndGame
	CMP R5, #0
	SUBNE R5, R5, #1
	BNE pauseEndGame
	
	LDR R5, =SHOW_SCORE
	CMP R0, #0
	MOVEQ R3, #0
	MOVEQ R4, #0
	
	CMP R0, #1
	MOVEQ R3, #0x0
	MOVEQ R4, #0x1
	
	CMP R0, #2
	MOVEQ R3, #0x10
	MOVEQ R4, #0x0
	
	CMP R0, #3
	MOVEQ R3, #0x10
	MOVEQ R4, #0x1
	
	CMP R0, #4
	MOVEQ R3, #0x2
	MOVEQ R4, #0x0
	
	CMP R0, #5
	MOVEQ R3, #0x2
	MOVEQ R4, #0x1
	
	CMP R0, #6
	MOVEQ R3, #0x3
	MOVEQ R4, #0x0
	
	CMP R0, #7
	MOVEQ R3, #0x3
	MOVEQ R4, #0x1
	
	CMP R0, #8
	MOVEQ R3, #0x10
	MOVEQ R4, #0x0
	
	CMP R0, #9
	MOVEQ R3, #0x10
	MOVEQ R4, #0x1
	
	CMP R0, #10
	MOVEQ R3, #0x11
	MOVEQ R4, #0x0
	
	CMP R0, #11
	MOVEQ R3, #0x11
	MOVEQ R4, #0x1
	
	CMP R0, #12
	MOVEQ R3, #0x2
	MOVEQ R4, #0x0
	
	CMP R0, #13
	MOVEQ R3, #0x2
	MOVEQ R4, #0x1
	
	CMP R0, #14
	MOVEQ R3, #0x13
	MOVEQ R4, #0x0
	
	CMP R0, #15
	MOVEQ R3, #0x13
	MOVEQ R4, #0x1
	
	STR R3, [R6]
	STR R4, [R7]
	
showScore
	CMP R5, #0
	SUBNE R5, R5, #1
	BNE showScore
	BX LR
	ENDP
	ALIGN
		
	END