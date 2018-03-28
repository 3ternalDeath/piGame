
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
	.equ	event, 		28
	.equ	lose, 		29
	.equ	numBricks, 	30		//numBricks MUST be right before gameMap
	.equ	gameMap, 	31

////////////////////////////////////////////////////
.global main
main:
	@ ask for frame buffer information
	ldr 	r0, =frameBufferInfo 	@ frame buffer information structure
	bl		initFbInfo
	bl		snesSetup

//MAIN MENUE STUFF HERE

	bl		initMap
	
	bl		firstMapDraw
	
	
mainGameLoop:
	bl		Read_SNES
	ORRs	r0, #0
	
	bl		update
  
    
    mov 	r0, #8000
    bl		delayMicroseconds
    
	b		mainGameLoop
	@ stop
	haltLoop$:
		b	haltLoop$
		
///////////////////////////////////////////////////////
update:
	push	{r4, lr}
	
	mov		r4, r0
	mov		r0, #0
	
	tst		r4, #0x8		//A
	moveq	r1, #4			//speed 1
	movne	r2, #5			//speed 2

	tst		r4, #0x10		//RIGHT
	movne	r0, #1
	
	tst		r4, #0x20		//LEFT
	movne	r0, #-1
	
							//left and right are mutually exclusive due to
							//construction of snes
	//MUST MOVE PADDLE FIRST
	bl		mvPaddle		
	//OTHER MOVES
	
				
	//MUST MOVE BALL LAST
	bl		mvBall
	
	pop		{r4, pc}
//////////////////////////////////////////////
mvBall:
	
	bx		lr
/////////////////////////////////////////////
bounceRev:
	ldr		r0, = gameState
	ldr		r1, [r0, #ballDir]
	
	cmp		r1, #1
	movLE	r2, #3
	
	cmp		r1, #2
	movEQ	r2, #4
	
	cmp		r1, #3
	movEQ	r2, #1
	
	cmp		r1, #4
	movGE	r2, #2
	
	str		r2, [r0, #ballDir]
	
	bx		lr
//////////////////////////////////////////////////
bounceVert:
	ldr		r0, = gameState
	ldr		r1, [r0, #ballDir]
	
	cmp		r1, #1
	movLE	r2, #4
	
	cmp		r1, #2
	movEQ	r2, #3
	
	cmp		r1, #3
	movEQ	r2, #2
	
	cmp		r1, #4
	movGE	r2, #1
	
	str		r2, [r0, #ballDir]
	
	bx		lr
//////////////////////////////////////////////////////
bounceHori: @1 = up right, 2 = up left, 3 = down left, 4 = down right
	ldr		r0, = gameState
	ldr		r1, [r0, #ballDir]
	
	cmp		r1, #1
	movLE	r2, #2
	
	cmp		r1, #2
	movEQ	r2, #1
	
	cmp		r1, #3
	movEQ	r2, #4
	
	cmp		r1, #4
	movGE	r2, #3
	
	str		r2, [r0, #ballDir]
	
	bx		lr
	
/////////////////////////////////////////////////
mvPaddle:
	@ r0 - direction: -1, 0, 1
	@ r1 - speed/amt of loop
	cmp		r0, #0
	bxeq	lr
	cmp		r1, #0				//insta return conditions
	bxle	lr
	
	push	{r4-r7, lr}
	mov		r4, r0
	mov		r5, r1
	
	ldr		r6, =gameState
	ldr		r0, [r6, #padX]
	bl		unDrawPaddle
	
paddleTop:
	
	ldr		r7, [r6, #padX]		//Left edge
	
	cmp		r4, #0
	blt		mvPadLft
mvPadRgt:
	ldrb	r0, [r6, #padOff3]
	add		r7, #1
	add		r0, r7				//Right edge +1
	
	bl		checkTilePaddle
	cmp		r0, #-1			//if tile wall
	subeq	r7, #1
	beq		mvPadRet
	str		r7, [r6, #padX]		// if not
	b		mvPaddleTest

mvPadLft:
	sub		r7, #1
	mov		r0, r7
	
	bl		checkTilePaddle
	cmp		r0, #-1			//if tile wall
	addeq	r7, #1
	beq		mvPadRet
	str		r7, [r6, #padX]
	
mvPaddleTest:
	subs	r5, #1
	bNE		paddleTop
	
mvPadRet:
	mov		r0, r7
	bl		drawPaddle
	pop		{r4-r7, pc}
////////////////////////////////////////////////////
.global cordToTile
cordToTile:
@ r0 -x
@ r1 -y
	
	lsr		r0, #5
	lsr		r1, #5
	mov		r3, #20
	mul		r1, r3
	add		r0, r1
	bx		lr
/////////////////////////////////////////
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
	
	sub		r4, #gameMap
	ldr		r0, [r4, #padX]
	bl		drawPaddle
	
	ldr		r0, [r4, #ballX]
	ldr		r1, [r4, #ballY]
	bl		drawBall
	
	pop	{ r4, r5, lr }
	
///////////////////////////////////////////////////////
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
////////////////////////////////////////////////	


@ Data section
.section .data
.global gameState
gameState:
//NEED TO INIT SOME OF THESE

	.int	350				// paddleX(left most RELITIVE pixil)
	.byte 	25, 50, 75, 100	// paddleoff
	.int 	300				// ballX(top left RELITIVE pixil)
	.int	600				// ballY(top left RELITIVE pixil)
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
