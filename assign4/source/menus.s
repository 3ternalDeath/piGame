@ Contains code to operate menus

.section .text


//////////// - CONFIG - ///////////
.equ	TOP_LEFT_X,	50
.equ	TOP_LEFT_Y, 100
.equ	PADDLE_SIZE_DEFAULT, 100
.equ	PADDLE_SIZE_POWERUP, 200
.equ	BALL_SIZE, 15
.equ	TILE_SIZE, 32

	.equ	padX, 		0
	.equ	padOff0, 	4
	.equ	padOff1, 	5
	.equ	padOff2, 	6
	.equ	padOff3, 	7
	.equ	ballX, 		8
	.equ	ballY, 		12
	.equ	ballSpd, 	16
	.equ	ballAng, 	17
	.equ	ballDir, 	18
	.equ	ballAnc, 	19
	.equ	score, 		20
	.equ	lives, 		24
	.equ	event, 		28
	.equ	lose, 		29
	.equ	numBricks, 	30		//numBricks MUST be right before gameMap
	.equ	gameMap, 	31
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

.global PauseMenu
PauseMenu:
	// Returns -1 if continue, 0 if restart, 1 if quit 
	push { r4, r5, lr }
	mov		r4, #1
	mov		r5, #-1
	bl		DrawPause
	
	mov		r0, #60000		// Give it a pause for buttons to reset
	bl 		delayMicroseconds
	mov		r0, #60000		
	bl 		delayMicroseconds
PauseTop:

		bl 		Read_SNES
		tst		r0, #0x100
		bNE		PauseEnd		// If start is pressed, exit menu
		
		tst		r0, #0x8		// The A button is pressed
		bEQ		PauseNext1		// Skip if A is not pressed
		
		cmp		r4, #1
		bNE		PauseNext
		mov		r5, #0			// Restart was selected
		b		PauseEnd
	
PauseNext:	
		cmp		r4, #0
		bNE		PauseNext1
		mov		r5, #1			// Quit was selected
		b		PauseEnd
PauseNext1:	
		tst		r0, #0x80		// Pad-Up is pressed
		movNE	r4, #1


		tst		r0, #0x40		// Pad-Down is pressed
		movNE	r4, #0


		mov		r0, r4			// Draw pointer arrow
		bl		DrawArrow
		mov		r0, r4
		bl		EraseArrow
		
		b 		PauseTop
PauseEnd:
		bl		fullMapDraw
		mov		r0, #60000		// Give it a pause for buttons to reset
		bl 		delayMicroseconds
		mov		r0, #30000
		bl		delayMicroseconds
		
		mov		r0, r5
	pop { r4, r5, pc }
	


//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
.global GameMenu
GameMenu:
		push { r4, lr }
		mov		r0, #60000		// Give it a pause for buttons to reset
		bl 		delayMicroseconds
		mov		r4, #0
		ldr		r0, =menuImg
		bl		DrawScreen
		bl		DrawArrow

MenuChkLoop:
		bl Read_SNES
		cmp		r0, #0
		beq		MenuChkLoop		// loop until input is given
GameMenuLoop:

		tst		r0, #0x8		// But-A
		bEQ		MenuNext		// If it is not A, skip these tests
		
		cmp		r4, #1
		bEQ		MenuEnd
		
		cmp		r4, #0
		blEQ	QuitScreen		// Draw Screen Black
		
			haltLoop$:			// Loop forever
		b	haltLoop$
		
		
		
MenuNext:	
		tst 	r0,	#0x80 		// Pad-Up
		movNE 	r4, #1
		
		tst 	r0, #0x40		// Pad-Down
		movNE	r4, #0

		mov 	r0, r4
		bl		DrawArrow		// Draw the Arrow
		mov		r0, r4
		bl		EraseArrow		// Erase the old Arrow
		b 		MenuChkLoop

MenuEnd:	
		pop { r4, pc }
		
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
.global QuitScreen
QuitScreen:
	push	{r4-r7, lr}

	mov		r4, #640
	add		r4, #TOP_LEFT_X			// Find final pixel x
	
	mov		r5, #900
	add		r5, #TOP_LEFT_Y			// Find final pixel y
	
	mov		r6, #TOP_LEFT_X
	mov		r7, #TOP_LEFT_Y
	
QuitTop:
	mov 	r0, r6
	mov		r1, r7
	ldr		r2, =0xFF000000  	// Black
	bl		DrawPixel
	
	add		r6, #1
	cmp		r6, r4				// Check if Draw has reached the right of the screen
	bLT		QuitTop
	
	mov		r6, #TOP_LEFT_X
	add		r7, #1
	cmp		r7, r5				// Check if Draw has reached the bottom of the screen
	bLT		QuitTop

	pop		{r4-r7, pc}

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

		
		
