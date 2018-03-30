
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

	bl		GameMenu
	bl		initMap
	
	bl		fullMapDraw
	
	
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
	push	{r4-r8, lr}
	ldr		r4, =gameState
	ldrb	r5, [r4, #ballSpd]
	
ballTop:
	ldrb	r0, [r4, #ballDir]
	ldrb	r1, [r4, #ballAng]
	bl		getBallOffsets
	mov		r6, r0
	mov		r7, r1
	
	ldr		r0, [r4, #ballX]
	ldr		r1, [r4, #ballY]
	bl		unDrawBall
	
	ldr		r0, [r4, #ballX]
	add		r0, r6
	ldr		r1, [r4, #ballY]
	ldrb	r2, [r4, #ballDir]
	add		r1, r7
	bl		checkTileBall
	cmp		r0, #0
	beq		ballMVMbyGood
	
	cmp		r0, #255		//side wall
	bNE		mvBlBnc1
	bl		bounceHori
	b		ballTop

mvBlBnc1:	
	cmp		r0, #254		//roof
	bNE		mvBlBnc2
	bl		bounceVert
	b		ballTop

mvBlBnc2:	
	cmp		r0, #253		//lava
	bNE		mvBlBnc3
	bl		bounceVert
	b		ballTop
	//DO STUFFFFF
	
mvBlBnc3:
	mov		r8, r1
	mov		r0, r1
	bl		decrementBrick
	mov		r0, r4
	add		r0, #gameMap
	mov		r1, r8
	bl		drawTile
	bl		bounceVert
	b		ballTop
	
ballMVMbyGood:
	bl		getPadY
	ldr		r1, [r4, #ballY]
	add		r1, r7
	cmp		r1, r0
	bLT		ballMVGood
so:	add		r0, #2
	cmp		r1, r0
	bGT		ballMVGood
	bl		bouncePaddle
	
	
ballMVGood:	
	ldr		r0, [r4, #ballX]
	ldr		r1, [r4, #ballY]
	add		r0, r6
	add		r1, r7
	str		r0, [r4, #ballX]
	str		r1, [r4, #ballY]
	bl		drawBall

	
	subs	r5, #1
	bNE		ballTop
	
	
	pop		{r4-r8, pc}
/////////////////////////////////////////////////
bouncePaddle:
	ldr		r0, =gameState
	ldr		r1, [r0, #ballX]
	ldr		r2, [r0, #padX]
	ldrb	r3, [r0, #padOff3]
	
	cmp		r1, r2
	bLT		bPadMiss
	cmp		r1, r3
	bGT		bPadMiss
	
	ldrb	r2, [r0, #padOff1]
	cmp		r1, r2
	bLE		bPadL
bPadR:
	mov		r3, #3
	strb	r3, [r0, #ballDir]
	ldrb	r2, [r0, #padOff2]
	cmp		r1, r2
	movGT	r3, #45
	movLE	r3, #60
	b		bPadGud
bPadL:
	mov		r3, #4
	strb	r3, [r0, #ballDir]
	ldrb	r2, [r0, #padOff2]
	cmp		r1, r2
	movLT	r3, #45
	movGE	r3, #60

bPadGud:
	strb	r3, [r0, #ballDir]

bPadMiss:
	bx		lr
///////////////////////////////////////////
decrementBrick:
@r0 - tile number
	ldr		r1, =gameState
	add		r1, #gameMap
	
	ldr		r2, [r1, r0]
	//VALUE PACK COMPS
	
	sub		r2, #1
	str		r2, [r1, r0]
	
	cmp		r2, #0
	ldrb	r2, [r1, #(-gameMap + numBricks)]
	subeq	r2, #1
	strb	r2, [r1, #(-gameMap + numBricks)]
	
	bx		lr
////////////////////////////////////////////
checkTileBall:
@ r0 - x
@ r1 - y
@ r2 - corner #
	push	{r4-r7, lr}
	mov		r4, r0
	mov		r5, r1
	mov		r6, r2
	ldr		r7, =gameState
	add		r7, #gameMap
	@  1 = down right, 2 = down left, 3 = up right, 4 = up left
	bl		getBallSize
	mov		r3, r0
	
	cmp		r6, #1
	addEQ	r4, r3
	addEQ	r5, r3
	bEQ		checkTBEnd
	
	cmp		r6, #2
	addEQ	r5, r3
	bEQ		checkTBEnd
	
	cmp		r6, #3
	addEQ	r4, r3
	
	
checkTBEnd:
	mov		r0, r4
	mov		r1, r5
	bl		cordToTile
	mov		r1, r0
	ldrb	r0, [r7, r1]
	
	pop		{r4-r7, pc}
	
/////////////////////////////////////////////

getBallOffsets:@returns r0 - x offset, r1 - y offset
@r0 - ball direction
@r1 - ball angle
						//if angle 60, y +- 2 and x +-1
						//if angle 45, x,y +- 1
	mov		r2, #1
	
	cmp		r1, #45
	moveq	r3, #1
	
	cmp		r1, #60
	moveq	r3, #2
	
	
	
	@  1 = down right, 2 = down left, 3 = up right, 4 = up left
	
	mov		r1, #1
	
	cmp		r0, #2
	moveq	r0, #-1
	moveq	r1, #1
	
	cmp		r0, #3
	moveq	r0, #1
	moveq	r1, #-1
	
	cmp		r0, #4
	moveq	r0, #-1
	moveq	r1, r0
	
	mul		r0, r2
	mul		r1, r3
	
	bx		lr
////////////////////////////////////////////
bounceRev:
	ldr		r0, = gameState
	ldrb		r1, [r0, #ballDir]
	
	cmp		r1, #1
	movLE	r2, #4
	
	cmp		r1, #2
	movEQ	r2, #3
	
	cmp		r1, #3
	movEQ	r2, #2
	
	cmp		r1, #4
	movGE	r2, #1
	
	strb		r2, [r0, #ballDir]
	
	bx		lr
//////////////////////////////////////////////////
bounceVert:
	ldr		r0, = gameState
	ldrb	r1, [r0, #ballDir]
	
	cmp		r1, #1
	movEQ	r2, #3
	
	cmp		r1, #2
	movEQ	r2, #4
	
	cmp		r1, #3
	movEQ	r2, #1
	
	cmp		r1, #4
	movEQ	r2, #2
	
	strb		r2, [r0, #ballDir]
	
	bx		lr
//////////////////////////////////////////////////////
bounceHori: 
	ldr		r0, = gameState
	ldrb	r1, [r0, #ballDir]
	
	@  1 = down right, 2 = down left, 3 = up right, 4 = up left
	
	cmp		r1, #1
	movEQ	r2, #2
	
	cmp		r1, #2
	movEQ	r2, #1
	
	cmp		r1, #3
	movEQ	r2, #4
	
	cmp		r1, #4
	movEQ	r2, #3
	
	strb		r2, [r0, #ballDir]
	
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
checkTilePaddle:
	push	{r4, lr}
	mov		r4, r0
	bl		getTileSize
	
	cmp		r4, r0
	movLE	r0, #-1
	
	mov		r1, r0
	mov		r2, #19
	mul		r1, r2
	
	cmp		r4, r1
	movGE	r0, #-1
	
	pop		{r4, pc}

/////////////////////////////////////////////
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
fullMapDraw:
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

////////////////////
@ Data section
.section .data
.global gameState
gameState:
//NEED TO INIT SOME OF THESE

	.int	270				// paddleX(left most RELITIVE pixil)
	.byte 	25, 50, 75, 100	// paddleoff
	.int 	315				// ballX(top left RELITIVE pixil)
	.int	675				// ballY(top left RELITIVE pixil)
	.byte	1				// ballspeed
	.byte	45				// ballangle
	.byte	3				// balldirection
							@  1 = down right, 2 = down left, 3 = up right, 4 = up left
	.byte	1				// ballanchor, 1 if anchored, 0 if not
	.int	0				// score
	.int	1				// lives
	.byte	0				// event, 0 = normal, 1 = win, 2 = lose
	.byte	0				// lose, 1 if lost, 0 if not
	.byte	0				// numBricks
	.rept	500				// game map 20*25 tiles
		.byte 0
	.endr

//.equ name, val
//.rept num
//stuff
//.endr
