
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
	.equ	valPk,	 	19
	.equ	score, 		20
	.equ	lives, 		24
	.equ	event, 		28
	.equ	bigPad,		29
	.equ	valPkX,		30
	.equ	valPkY,		34
	.equ	numBricks, 	38		//numBricks MUST be right before gameMap
	.equ	gameMap, 	39

////////////////////////////////////////////////////
.global main
main:
	@ ask for frame buffer information
	ldr 	r0, =frameBufferInfo 	@ frame buffer information structure
	bl		initFbInfo
	bl		snesSetup

//MAIN MENUE STUFF HERE
.global Start
Start:
	mov		r0, #60000		// Give it a pause for buttons to reset
	bl 		delayMicroseconds
	bl		GameMenu
	
.global startGame
startGame:
	mov		r0, #60000		// Give it a pause for buttons to reset
	bl 		delayMicroseconds
	bl		initGame
	bl		fullMapDraw
	
mainGameLoop:
	bl		Read_SNES
	tst		r0, #0x100		// If start is pressed go to pause menu
	bEQ		mainGameLoopNext
	blNE 	PauseMenu
	
	cmp	r0, #1				// return to menu screen
	
	bEQ		Start
	
	cmp	r0, #0				// Restart Game
	bEQ		startGame

mainGameLoopNext:	
	
	bl		update
	bl		DrawScore			// Draw Player Score to Screen
	
    mov 	r0, #20000
    bl		delayMicroseconds
    
	b		mainGameLoop
	@ stop
	haltLoop$:
		b	haltLoop$
		
		

	
///////////////////////////////////////////////////////
update:							//called every cycle, basicly game transition
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
	bl		mvValPk
	
				
	//MUST MOVE BALL LAST
	bl		mvBall
	
	pop		{r4, pc}
//////////////////////////////////////////////
mvValPk:												//moves value pack down to paddle levle(if there is one)
	ldr		r0, =gameState
	ldrb	r1, [r0, #valPk]
	cmp		r1, #0
	bxEQ	lr				//insta return
	
ok:	push	{r4-r6, lr}
	
	mov		r4, r0
	
	bl		getPadY
	ldr		r1, [r4, #valPkY]
	add		r1, #14
	
	cmp		r1, r0
	bGE		mvValPkStop
	
	ldr		r5, [r4, #valPkX]
	ldr		r6, [r4, #valPkY]
	
	bl		cordToTile
	
	mov		r1, r0
	sub		r1, #2
	add		r0, r4, #gameMap
	bl		drawTile
	
	bl		getTileSize			// Draw Value Pack Black
	mov		r3, r0
	mov		r0, r5
	mov		r1, r6
	ldr		r2, =#0xff000000
	bl		drawRelSquare
	add		r6, #1
	
	bl		getTileSize			// Draw Value Pack White
	mov		r3, r0
	mov		r0, r5
	mov		r1, r6
	ldr		r2, =#0xffffffff
	bl		drawRelSquare
	
	str		r6, [r4, #valPkY]
	
	
mvValPkStop:
	pop		{r4-r6, pc}

//////////////////////////////////////////
mvBall:							//moving and bouncing of the ball
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
	mov		r8, r1
	cmp		r0, #0
	beq		ballMVMbyGood				//bounces start
										//always b to ball top to get new offsets when bouncing
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
//	mov		r8, r1
	mov		r0, r8
	bl		decrementBrick
	mov		r0, r4
	add		r0, #gameMap
	mov		r1, r8
	bl		drawTile
	bl		bounceVert
	b		ballTop
	
ballMVMbyGood:
	bl		getBallSize
	mov		r8, r0
	ldr		r1, [r4, #ballY]
	add		r1, r7
	add		r8, r1
	bl		getPadY
	cmp		r8, r0
	bLT		ballMVGood
	add		r0, #2
	cmp		r8, r0
	bGT		ballMVGood

	bl		bouncePaddle				//bouncing off paddle
	cmp		r0, #-1
	bNE		ballTop
	
	//TODO: DEATH BY LAVA
	
ballMVGood:	
	ldr		r0, [r4, #ballX]
	ldr		r1, [r4, #ballY]
	add		r0, r6
	add		r1, r7
	str		r0, [r4, #ballX]
	str		r1, [r4, #ballY]			//move done, draw
	bl		drawBall

	
	subs	r5, #1
	bNE		ballTop
	
	
	pop		{r4-r8, pc}
/////////////////////////////////////////////////
bouncePaddle:						//figures out wher ball goes when it hits paddle
	push	{r4-r5, lr}
	ldr		r5, =gameState
	ldr		r1, [r5, #ballX]
	ldr		r2, [r5, #padX]
	ldrb	r3, [r5, #padOff3]
	add		r3, r2
	
	cmp		r1, r2
	bLT		bPadMbyMiss
	cmp		r1, r3
	bGT		bPadMbyMiss
	
	b		bPadHap
	
bPadMbyMiss:
	bl		getBallSize
	add		r1, r0
	cmp		r1, r2
	movLT	r0, #-1
	bLT		bPadMiss
	cmp		r1, r3
	movGT	r0, #-1
	bGT		bPadMiss
	
bPadHap:
	bl		getBallSize
	lsl		r0, #1
	add		r1, r0
	ldr		r2, [r5, #padX]
	ldrb	r3, [r5, #padOff1]
	add		r3, r2
	cmp		r1, r3
	bLE		bPadL
bPadR:
	mov		r3, #3
	strb	r3, [r5, #ballDir]
	ldrb	r4, [r5, #padOff2]
	add		r4, r2
	cmp		r1, r4
	movGT	r3, #45
	movLE	r3, #60
	b		bPadGud
bPadL:
	mov		r3, #4
	strb	r3, [r5, #ballDir]
	ldrb	r4, [r5, #padOff0]
	add		r4, r2
	cmp		r1, r4
	movLT	r3, #45
	movGE	r3, #60

bPadGud:
	strb	r3, [r5, #ballAng]

bPadMiss:
	pop		{r4-r5, pc}
///////////////////////////////////////////
decrementBrick:							//reduce hardness of brick and init value pack stuff
										// Increments the Score Counter
	push	{r4 - r5, lr}
@r0 - tile number
	ldr		r4, =gameState
	
	ldr		r5, [r4, #score]			// Increase Score by 1
	add		r5, #1
	str		r5, [r4, #score]
	
		
	add		r4, #gameMap
	mov		r5, r0
	
	ldrb		r2, [r4, r5]
	//VALUE PACK COMPS
	cmp		r2, #5
	movEQ	r2, #1
	bEQ		decrementValPk
	
	cmp		r2, #9
	movEQ	r2, #2
	bEQ		decrementValPk 
	
	sub		r2, #1
	strb	r2, [r4, r5]

	mov		r0, r4
	mov		r1, r2
	bl		drawTile
	
	bl		clearTopScreen				// Clear the Score Screen
	pop		{r4-r5, pc}


decrementValPk:
	ldrb	r3, [r4, #valPk-gameMap]
	cmp		r3, #0
	bNE		decVPEnd

	strb	r2, [r4, #valPk-gameMap]
	
	mov		r0, r5
	bl		tileToCord
	str		r0, [r4, #valPkX-gameMap]
	str		r1, [r4, #valPkY-gameMap]
	
decVPEnd:
	mov		r0, #0
	strb	r0, [r4, r5]
	mov		r0, r4
	mov		r1, r5
	bl		drawTile
	bl		clearTopScreen				// Clear the Score Screen
	pop		{r4-r5, pc}
//////////////////////////////////////////
checkTileBall:								//figure out what type of tile is directly in its way(only checks one corner)
@ r0 - x									//if goint up/right only check top right corner...
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

								//get movement values for x and y based on direction and angle

getBallOffsets:@returns r0 - x offset, r1 - y offset
@r0 - ball direction
@r1 - ball angle
						//if angle 60, y +- 2 and x +-1
						//if angle 45, x,y +- 2
	mov		r3, #2
	
	cmp		r1, #45
	moveq	r2, #2
	
	cmp		r1, #60
	moveq	r2, #1
	
	
	
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
bounceRev:							//never used... for real
									//sends ball back the way it came
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
bounceVert:							//flips verticle direction of ball
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
bounceHori: 						//flips horizontal direction of ball
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
mvPaddle:								//move paddle 1 pixel at a time speed amt of times
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
checkTilePaddle:	//doesnt do the tile thing
					//checks if paddle will exceed wall boundries
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
.global tileToCord
tileToCord:					//convert from tile number to x-y coords
@ r0 - tile number
	push	{lr}
	mov		r1, r0
	bl		getTileSize
	mov		r2, #0
	b		TTCTest
TTCTop:
	add		r2, #1
	sub 	r1, #20
TTCTest:
	cmp 	r1, #20
	bGT 	TTCTop
	
	bl		getTileSize
	mov		r3, r0
	mul		r0, r1, r3
	mul		r1, r2, r3
	
	pop		{pc}
///////////////////////////////////////////
.global cordToTile			//convert from coords to tile number
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

initGame:					// copy map from file to gameMap
							// Then initialize the State variables
		
		ldr		r0, =map1
		ldr		r1, =gameState
		add		r1, #numBricks
		ldr		r3, [r0], #1	@num bricks
		str		r3, [r1], #1
		
		mov		r2, #125		@500/4
		
GameInitTop:
		ldr		r3, [r0], #4		// Initialize Bricks
		str		r3, [r1], #4
		subs	r2, #1
		bne		GameInitTop
		
										// Initialize Game State Vars
		ldr		r1, =gameState
		mov		r3, #270
		str		r3, [r1, #padX]

		mov		r3, #25
		str		r3, [r1, #padOff0]
	
		mov		r3, #50
		str		r3, [r1, #padOff1]
		
		mov		r3, #75
		str		r3, [r1, #padOff2]
		
		mov		r3, #100
		str		r3, [r1, #padOff3]
		
		mov		r3, #315
		str		r3, [r1, #ballX]
		
		mov		r3, #655
		str		r3, [r1, #ballY]
		
		mov		r3, #2		
		str		r3, [r1, #ballSpd]
		
		mov		r3, #45
		str		r3, [r1, #ballAng]
		
		mov		r3, #3
		str		r3, [r1, #ballDir]
		
		mov		r3, #9
		str		r3, [r1, #lives]
		
		mov		r3, #0
		str		r3, [r1, #valPk]
		mov		r3, #0
		str		r3, [r1, #score]
		mov		r3, #0
		str		r3, [r1, #event]
		str		r3, [r1, #bigPad]
		str		r3, [r1, #valPkX]
		str		r3, [r1, #valPkY]
		str		r3, [r1, #numBricks]
		

		bx		lr
////////////////////////////////////////////////	

	


	
@ Data section
.section .data
.global gameState
gameState:

	.int	0				// paddleX(left most RELITIVE pixil)
	.byte 	0, 0, 0, 0	// paddleoff
	.int 	0				// ballX(top left RELITIVE pixil)
	.int	0				// ballY(top left RELITIVE pixil)
	.byte	0				// ballspeed
	.byte	0				// ballangle
	.byte	0				// balldirection
							@  1 = down right, 2 = down left, 3 = up right, 4 = up left
	.byte	0				// valupack, 0 if inactive, 1 if speed down, 2 if enlarge
	.int	0				// score
	.int	0				// lives
	.byte	0				// event, 0 = normal, 1 = win, 2 = lose
	.byte	0				// bigPaddle, 0 if not, 1 if yes
	.int	0				// valPkX
	.int	0				// valPkY
	.byte	0				// numBricks
	.rept	500				// game map 20*25 tiles
		.byte 0
	.endr

//.equ name, val
//.rept num
//stuff
//.endr
