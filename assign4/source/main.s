@ This program prompts user to press a button on the SNES controler
@ and displays the button(s) been pressed

.section	.text

.global	main

main:
	ldr		r0, =creators			// Print the creator's names
	bl		printf
	
	bl		snesSetup				// Set up GPIO pin functions
	
	
prmtLoop:
	ldr		r0, =prompt				// Prompt the user
	bl		printf
	
chkLoop:
	bl		Read_SNES				
	cmp		r0, #0
	beq		chkLoop					// Loops until input is given				
	
	
gotInput:					
	mov		r4, r0					// Determine which button was pressed
									// and print appropriate message
	tst		r4, #0x1
	ldrne	r0, =rgt_str
	blne	printf
	
	tst		r4, #0x2
	ldrne	r0, =lft_str
	blne	printf
	
	tst		r4, #0x4
	ldrne	r0, =butX_str
	blne	printf
	
	tst		r4, #0x8
	ldrne	r0, =butA_str
	blne	printf
	
	tst		r4, #0x10
	ldrne	r0, =padR_str
	blne	printf
	
	tst		r4, #0x20
	ldrne	r0, =padL_str
	blne	printf
	
	tst		r4, #0x40
	ldrne	r0, =padD_str
	blne	printf
	
	tst		r4, #0x80
	ldrne	r0, =padU_str
	blne	printf
	
	tst		r4, #0x200
	ldrne	r0, =sel_str
	blne	printf
	
	tst		r4, #0x400
	ldrne	r0, =butY_str
	blne	printf
	
	tst		r4, #0x800
	ldrne	r0, =butB_str
	blne	printf
	
	tst		r4, #0x100
	ldrne	r0, =term
	blne	printf
	
	ldr		r0, =#0x1D4C0			// Delay for 0.12 seconds
	bl		delayMicroseconds
	
	tst		r4, #0x100
	beq		prmtLoop
	
	mov		r0, #0					// Terminate Program
	mov 	r7, #1
	swi		0
	

.section	.data
creators:
	.string	"Created by: Parva Thaker and Lucas Ramos-Strankman\n\n"

prompt:	.string	"Please press a button...\n\n"
term:	.string	"Program is terminating...\n\n"

butB_str:	.string "You have pressed B\n\n"
butY_str:	.string	"You have pressed Y\n\n"
butA_str:	.string "You have pressed A\n\n"
butX_str:	.string	"You have pressed X\n\n"
padR_str:	.string	"You have pressed Joy-Pad RIGHT\n\n"
padL_str:	.string	"You have pressed Joy-Pad LEFT\n\n"
padU_str:	.string	"You have pressed Joy-Pad UP\n\n"
padD_str:	.string	"You have pressed Joy-Pad DOWN\n\n"
sel_str:	.string	"You have pressed Select\n\n"
lft_str:	.string	"You have pressed Left-Bumper\n\n"
rgt_str:	.string	"You have pressed Right-Bumper\n\n"
