@ Contains code for moving and interacting with the ball, paddle, and value packs

.section .text
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

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
	

	.equ	TILE_SIZE, 32
	.equ	padY, (25*TILE_SIZE) - 100
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

.global mvValPk
mvValPk:					//moves value pack down to paddle levle(if there is one)
	ldr		r0, =gameState
	ldrb	r1, [r0, #valPk]
	cmp		r1, #0
	bxEQ	lr					//	if no value pack is initialized
	
ok:	push	{r4-r7, lr}
	mov		r4, r0				// Store reference to gameState
	
	ldr		r5, [r4, #valPkX]
	ldr		r6, [r4, #valPkY]
	mov		r0, r5
	add		r1, r6, #32			// Find the x-value of the bottom left of the value Pack
	bl		cordToTile				// Find the tile associated with the value pack coords
	mov		r7, r0					// Put tile element number into r7
	
	add		r0, r4, #gameMap
	ldrb	r1, [r0, r7]			// Find value of tile
	cmp		r1, #253
	bNE		mvValPkNext
	
	bl		destroyValPk
	b		mvValPkStop
	
mvValPkNext:	
	mov		r1, r7
	//sub		r1, #2
	add		r0, r4, #gameMap
	bl		drawTile
	
	bl		getTileSize			// Draw Value Pack Black
	mov		r3, r0				// Move Size of tiles to r3
	mov		r0, r5				// move valPack X pos
	mov		r1, r6				// move valPack Y pos
	ldr		r2, =#0xff000000	// Black
	bl		drawRelSquare
	
	add		r6, #1				// Increase the Y value
	
//	Find what kind of value pack it is
	ldrb	r0, [r4, #valPk]
	cmp		r0, #2				// If 1, increase paddle size
	bEQ		paddleSize			// If 2, slow down ball speed
	

	
ballSpeed:

	bl		getTileSize			// Draw Value Pack 
	mov		r3, r0				// Move size of tiles to r3
	mov		r0, r5				// Move valPack X pos 
	mov		r1, r6				// Move valPack Y Pos
	ldr		r2, =#0xFF0F7D25	// Dark Green
	bl		drawRelSquare
	
	str		r6, [r4, #valPkY]
	b		mvValPkStop
	
paddleSize:
	bl		getTileSize			// Draw Value Pack 
	mov		r3, r0				// Move size of tiles to r3
	mov		r0, r5				// Move valPack X pos 
	mov		r1, r6				// Move valPack Y Pos
	ldr		r2, =#0xffff0000	// Red
	bl		drawRelSquare
	
	str		r6, [r4, #valPkY]
	
mvValPkStop:
	pop		{r4-r7, pc}



//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

destroyValPk:					// Erases and resets the value pack
	push	{ r4-r5, lr }
	ldr		r4, =gameState
	
	bl		getTileSize
	mov		r3, r0
	ldr		r0, [r4, #valPkX]
	ldr		r1, [r4, #valPkY]
	ldr		r2, =0xff000000			// Black
	bl		drawRelSquare			// Erase ValuePack
	
	mov		r0, #0					// Reset ValuePack 
	str		r0, [r4, #valPkX]
	str		r0, [r4, #valPkY]
	strb	r0, [r4, #valPk]
	
	pop		{ r4-r5, pc }
	
	
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////


.global mvBall
mvBall:							//moving and bouncing of the ball
	push	{r4-r8, lr}
	ldr		r4, =gameState
	ldrb	r5, [r4, #ballSpd]
	
ballTop:
	ldrb	r0, [r4, #ballDir]
	ldrb	r1, [r4, #ballAng]
	bl		getBallOffsets			// Find ball offsets based on direction and angle
	mov		r6, r0
	mov		r7, r1
	
	ldr		r0, [r4, #ballX]
	ldr		r1, [r4, #ballY]
	bl		unDrawBall				// Cover the old ball position
	
	ldr		r0, [r4, #ballX]
	add		r0, r6
	ldr		r1, [r4, #ballY]
	ldrb	r2, [r4, #ballDir]
	add		r1, r7
	bl		checkTileBall			// Check if the next pixel position to hit will be a tile
	mov		r8, r1
	cmp		r0, #0
	beq		ballMVMbyGood				//bounces start
										//always b to ball top to get new offsets when bouncing
	cmp		r0, #255		//side wall
	bNE		mvBlBnc1
	bl		bounceHori		// reflect in the x
	b		ballTop

mvBlBnc1:	
	cmp		r0, #254		//roof
	bNE		mvBlBnc2
	bl		bounceVert			// reflect in the y
	b		ballTop

mvBlBnc2:	
	cmp		r0, #253		//lava
	bNE		mvBlBnc3
	bl		bounceVert
	bl		loseLife		// Lose a life and reset ball
	b		ballTop

	
mvBlBnc3:
	mov		r8, r1
	mov		r0, r8
	bl		decrementBrick		// Decrease brick strength
	mov		r0, r4
	add		r0, #gameMap
	mov		r1, r8
	bl		drawTile			
	bl		bounceVert			// reflect ball in the y
	b		ballTop
	
ballMVMbyGood:					// Check if the ball move is actually good
	bl		getBallSize
	mov		r8, r0
	ldr		r1, [r4, #ballY]		// Find BallY pos
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
	
	
ballMVGood:	
	ldr		r0, [r4, #ballX]
	ldr		r1, [r4, #ballY]			// Move the ball
	add		r0, r6
	add		r1, r7
	str		r0, [r4, #ballX]
	str		r1, [r4, #ballY]			//move done, draw
	bl		drawBall

	
	subs	r5, #1						// Repeate this speed (r5) times
	bNE		ballTop
	
	
	pop		{r4-r8, pc}

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////


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
	
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

checkTileBall:						//figure out what type of tile is directly in its way(only checks one corner)
@ r0 - x							//if goint up/right only check top right corner...
@ r1 - y
@ r2 - corner # to be checked
	push	{r4-r7, lr}
	mov		r4, r0			// x coord
	mov		r5, r1			// y coord
	mov		r6, r2			// corner #
	ldr		r7, =gameState
	add		r7, #gameMap
	@  1 = down right, 2 = down left, 3 = up right, 4 = up left
	bl		getBallSize
	mov		r3, r0
	
	cmp		r6, #1			// If corner 1
	addEQ	r4, r3				
	addEQ	r5, r3			// add size
	bEQ		checkTBEnd		// Check the tile
	
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
	
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

bouncePaddle:						//figures out where ball goes when it hits paddle
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
	
bPadMbyMiss:			// check if ball will miss
	bl		getBallSize
	add		r1, r0
	cmp		r1, r2
	movLT	r0, #-1
	bLT		bPadMiss
	cmp		r1, r3
	movGT	r0, #-1
	bGT		bPadMiss
	
bPadHap:					//	hit on the inside
	bl		getBallSize
	lsl		r0, #1
	add		r1, r0
	ldr		r2, [r5, #padX]
	ldrb	r3, [r5, #padOff1]		
	add		r3, r2
	cmp		r1, r3
	bLE		bPadL
bPadR:						// hit on the right outside
	mov		r3, #3
	strb	r3, [r5, #ballDir]
	ldrb	r4, [r5, #padOff2]
	add		r4, r2
	cmp		r1, r4
	movGT	r3, #45
	movLE	r3, #60
	b		bPadGud
bPadL:						// hit on the left outside
	mov		r3, #4
	strb	r3, [r5, #ballDir]
	ldrb	r4, [r5, #padOff0]
	add		r4, r2
	cmp		r1, r4
	movLT	r3, #45
	movGE	r3, #60

bPadGud:
	strb	r3, [r5, #ballAng]		// Change angle

bPadMiss:
	pop		{r4-r5, pc}


//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////


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
	
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

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


//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

decrementBrick:							//reduce hardness of brick and init value pack stuff
										// Increments the Score Counter
	push	{r4-r6, lr}
@r0 - tile number
	ldr		r4, =gameState
	mov		r6, r0					// Store tile number in r6
	mov		r0, #2					// increase score by 2
	bl		incScore
	
	        
	ldrb	r5, [r4, #numBricks]		// Decrease Brick Counter
	sub		r5, #1
	strb	r5, [r4, #numBricks]
	
	cmp		r5, #0
	bGT		decBrkNext
	mov		r5, #1					// Set win condition
	strb	r5, [r4, #event]
	
decBrkNext:
	
	add		r4, #gameMap
	mov		r5, r6
	
	ldrb		r2, [r4, r5]				// load value of brick
	
	//VALUE PACK COMPS
	cmp		r2, #5					// if Brick is 5, spawn speed value pack 
	movEQ	r2, #1
	bEQ		decrementValPk
	
	cmp		r2, #9					// if Brick is 9, spawn paddle size value pack
	movEQ	r2, #2
	bEQ		decrementValPk 
	
	sub		r2, #1
	strb	r2, [r4, r5]

	mov		r0, r4
	mov		r1, r2
	bl		drawTile					// Redrawn tile with new given strength
	
	bl		clearTopScreen				// Clear the Score Screen
	pop		{r4-r6, pc}

//////////////////////////////////////////////////////////////////////

decrementValPk:		// Moves the value pack downwards
	ldrb	r3, [r4, #valPk-gameMap]
	cmp		r3, #0
	bNE		decVPEnd

	strb	r2, [r4, #valPk-gameMap]
	
	mov		r0, r5
	bl		tileToCord
	str		r0, [r4, #valPkX-gameMap]		// Story new x and y values
	str		r1, [r4, #valPkY-gameMap]
	
decVPEnd:
	mov		r0, #0
	strb	r0, [r4, r5]
	mov		r0, r4
	mov		r1, r5
	bl		drawTile					// Redraw tile
	bl		clearTopScreen				// Clear the Score Screen
	pop		{r4-r6, pc}


//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

.global mvPaddle
mvPaddle:								//move paddle 1 pixel at a time, speed amt of times
	@ r0 - direction: -1, 0, 1
	@ r1 - speed/amt of loop
	push	{r4-r7, lr}
	cmp		r0, #0
	bEQ		padEnd
	cmp		r1, #0				//insta return conditions
	bLE		padEnd
	
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
	cmp		r0, #-1				//if tile wall return -1
	subeq	r7, #1
	beq		padEnd
	str		r7, [r6, #padX]		// if not a tile wall, store
	b		mvPaddleTest

mvPadLft:
	sub		r7, #1
	mov		r0, r7
	
	bl		checkTilePaddle
	cmp		r0, #-1				//if tile wall return -1
	addeq	r7, #1
	beq		padEnd
	str		r7, [r6, #padX]		// if not a tile wall, store
	
mvPaddleTest:
	subs	r5, #1				// repeat speed (r5) times
	bNE		paddleTop			
	
padEnd:
	bl		checkPadValPk
	pop		{r4-r7, pc}


//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

checkTilePaddle:	
					//checks if paddle will exceed wall boundries
					// returns -1 if invalid move
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

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

checkPadValPk:
// Checks if the paddle has collided with a value pack
//	And activates appropriate value effects
	push	{ r4-r10, lr }
	ldr		r10, =gameState
	
	ldr		r4, [r10, #padX]		// Find Left side of Paddle
	ldrb	r5, [r10, #padOff3]	
	add		r5, r4				// Find right side of Paddle
	
	mov		r6, #padY
	
	ldr		r7, [r10, #valPkX]	// Find left side of value pack
	add		r8, r7, #10			// Find right side of value pack
	
	ldr		r9, [r10, #valPkY]	
	add		r9, #32				// Find bottom of Value Pack
padvaltest:
	cmp		r6, r9
	bGT		noCollision			// See if ValuePack is at correct height
	
	cmp		r5, r7				// See if ValuePack is to the right of the paddle
	bLT		noCollision
	
	cmp		r4, r8				// See if Value pack is to the left of the paddle
	bGT		noCollision
	
// If none of these, collision must have occurred
	bl		valueEffect
	bl 		destroyValPk
	mov		r0, #50
	bl		incScore		// Increase score by 50 and draw on screen
	
	
noCollision:
	pop		{ r4-r10, pc }
	
	
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

valueEffect:					// Activates a valuePacks effects
	push	{ r4-r5, lr }
	ldr		r4, =gameState
	ldrb	r5, [r4, #valPk]	
	
	cmp		r5, #1				// If a valuepack of '1'
	bNE		effectNext
	
	mov		r0, #3					// Set ball Speed to be 3
	strb	r0, [r4, #ballSpd]
	b		effectEnd

effectNext:							// if a valuepack of '2'
	mov		r0, #40
	strb	r0, [r4, #padOff0]		// Set the offsets of the paddle
	mov		r0, #80
	strb	r0, [r4, #padOff1]	
	
	mov		r0, #120
	strb	r0, [r4, #padOff3]	
	mov		r0, #160
	strb	r0, [r4, #padOff3]		
	
									// Make sure the paddle is not outside bounds after growth
	ldr		r0, [r4, #padX]
	add		r0, #160
	cmp		r0, #608
	bLT		pdInBounds				// If the paddle is in bounds, ignore	
	
	mov		r0, #448
	str		r0, [r4, #padX]			// Shift the paddle x coord to be in bounds
pdInBounds:
effectEnd:		
	pop		{ r4-r5, pc }



