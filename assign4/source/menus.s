.section .text

/////////////////////////////////////
.equ	TOP_LEFT_X,	50
.equ	TOP_LEFT_Y, 50
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
/////////////////////////

.global PauseMenu
PauseMenu:
	push { r4, lr }
	mov		r4, #1
	bl		DrawPause
	
	mov		r0, #60000		// Give it a pause for buttons to reset
	bl 		delayMicroseconds
	mov		r0, #60000		
	bl 		delayMicroseconds
PauseTop:

		bl 		Read_SNES
		tst		r0, #0x100
		bNE		PauseEnd		// If start is pressed, exit menu

PauseNext:	
		tst		r0, #0x80		// Pad-Up is pressed
		movNE	r4, #1


		tst		r0, #0x40		// Pad-Down is pressed
		movNE	r4, #0


		mov		r0, r4
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
	pop { r4, pc }
	
////////////////////////////////////////////////	
.global GameMenu
GameMenu:
		push { r4, lr }
		ldr		r0, =menuImg
		bl		DrawScreen
		mov		r4, #0
		bl		DrawArrow
MenuChkLoop:
		bl Read_SNES
		cmp		r0, #0
		beq		MenuChkLoop		// loop until input is given
GameMenuLoop:

		tst		r0, #0x8		// But-A
		bEQ		MenuNext
		
		cmpNE	r4, #1
		bEQ		MenuEnd
MenuNext:	
		tst 	r0,	#0x80 		// Pad-Up
		movNE 	r4, #1
		
		tst r0, 	#0x40		// Pad-Down
		movNE		r4, #0
		
		mov 	r0, r4
		bl		DrawArrow
		mov		r0, r4
		bl		EraseArrow
		b 		MenuChkLoop

MenuEnd:	
		pop { r4, pc }

	/////////////////////////////////////////////////
	


		
		
