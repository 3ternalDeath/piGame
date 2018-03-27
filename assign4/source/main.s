
@ Code section
.section .text

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
	.equ	win, 		28
	.equ	lose, 		29
	.equ	numBricks, 	30		//numBricks MUST be right before gameMap
	.equ	gameMap, 	31

.global main
main:
	@ ask for frame buffer information
	ldr 		r0, =frameBufferInfo 	@ frame buffer information structure
	bl		initFbInfo
	bl		snesSetup

//MAIN MENUE STUFF HERE

	bl		initMap
	
	bl		firstMapDraw
	mov		r0, #300
	bl		drawPaddle
	
	mov		r0, #300
	mov		r1, #600
	bl		drawBall
	
mainGameLoop:
	bl		Read_SNES
	ORRs	r0, #0
	blNE		buttonPressedGame
	//b moveball?
	b		mainGameLoop
	@ stop
	haltLoop$:
		b	haltLoop$
		

buttonPressedGame:
	push	{r4, lr}
	
	mov		r4, r0
	
	tst		r0, #0x10
	beq		prsNxt1
	//MOVE PADDLE RIGHT
	
prsNxt1:
	tst		r0, #0x20
	beq		prsNxt2
	//MOVE PADDLE LEFT
	
prsNxt2:
	pop		{r4, pc}


firstMapDraw:
	push { r4, r5, lr }
	ldr		r4, =gameState
	add		r4, #gameMap
	
	mov		r5, #499		// last tile element
	
	//	Draw each tile
first_top:
	mov 	r0, r4
	mov		r1, r5
	bl 		drawTile
	
first_test:	
	subs	r5, #1		// Decrement counter and set flags
	bNE		first_top
	
	mov		r0, r4
	mov		r1, r5
	bl		drawTile	// Draw final tile
	pop	{ r4, r5, lr }
	

initMap:
		ldr		r0, =map1
		ldr		r1, =gameState
		add		r1, #numBricks
		
		ldr		r3, [r0], #1	@num bricks
		str		r3, [r1], #1
		
		mov		r2, #125		@500/4
		
mapInitTop:
		ldr		r3, [r0], #4
		str		r3, [r1], #4
		subs	r2, #1
		bne		mapInitTop

		bx		lr


@ Data section
.section .data
.global gameState
gameState:
//NEED TO INIT SOME OF THESE

	.int	300 			// paddleX(left most RELITIVE pixil)
	.byte 	0, 0, 0, 0 		// paddleoff
	.int 	0				// ballX(top left RELITIVE pixil)
	.int	0				// ballY(top left RELITIVE pixil)
	.byte	1				// ballspeed
	.byte	45				// ballangle
	.byte	1				// balldirection
							@  1 = up right, 2 = up left, 3 = down left, 4 = down right
	.byte	1				// ballanchor, 1 if anchored, 0 if not
	.int	0				// score
	.int	1				// lives
	.byte	0				// win, 1 if won, 0 if not
	.byte	0				// lose, 1 if lost, 0 if not
	.byte	0				// numBricks
	.rept	500				// game map 20*25 tiles
		.byte 0
	.endr

//.equ name, val
//.rept num
//stuff
//.endr
