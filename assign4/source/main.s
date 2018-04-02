
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

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

.global main
main:					// Initialize the snes and framebuffer
	@ ask for frame buffer information
	ldr 	r0, =frameBufferInfo 	@ frame buffer information structure
	bl		initFbInfo
	bl		snesSetup


.global Start
Start:						// Start with the Game Menu
	mov		r0, #60000		// Give it a pause for buttons to reset
	bl 		delayMicroseconds
	bl		GameMenu
	
.global startGame
startGame:					// Initialize the Game
	mov		r0, #60000		// Give it a pause for buttons to reset
	bl 		delayMicroseconds
	bl		initGame		// Set initial game values
	bl		fullMapDraw		// Draw Game
	
mainGameLoop:
	bl		Read_SNES
	tst		r0, #0x100			// If start is pressed go to pause menu
	bEQ		mainGameLoopNext
	blNE 	PauseMenu			// If start is pressed return a value if a selection is chosen in the pause menu
								
	cmp	r0, #1					// return to menu screen
	
	bEQ		Start				// Return to Menu
	
	cmp	r0, #0					// Restart Game
	bEQ		startGame

mainGameLoopNext:	
	
	bl		update				// Update Ball, Paddle, and Value packs
	bl		DrawScore			// Draw Player Score to Screen
	

	ldr		r1, =gameState		// Check win/lose condition
	ldrb	r2, [r1, #event]
	
	cmp		r2, #2				// If event is 2, show lost screen
	bNE		mainNotLose
	
	ldr		r0, =GameOverImg
	bl		DrawScreen
	b		mainChkLoop

mainNotLose:

	cmp		r2, #1				// If event is 1, show win screen
	bNE		mainNotWin
	
	ldr		r0, =GameWonImg
	bl		DrawScreen
	b		mainChkLoop			
	
mainChkLoop:
	bl 		Read_SNES
	cmp		r0, #0					// Once a button is pressed, return to menu screen
	beq		mainChkLoop				// loop until input is given
	mov		r0, #60000				// Give it a pause for buttons to reset
	bl 		delayMicroseconds
	b		Start

mainNotWin:
    mov 	r0, #11000				// controls game speed
    bl		delayMicroseconds
    
	b		mainGameLoop
	@ stop
	haltLoop$:
		b	haltLoop$
		
		

	
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

update:							//called every cycle, basicly the game transition
	push	{r4, lr}
	
	mov		r4, r0
	mov		r0, #0
	
	tst		r4, #0x8		// A
	moveq	r1, #4			// speed 1		// The paddle speed if A is not held
	movne	r2, #5			// speed 2		// The paddle speed if A is held

	tst		r4, #0x10		//RIGHT			// Test for d-pad right
	movne	r0, #1
	
	tst		r4, #0x20		//LEFT			// Test for d-pad left
	movne	r0, #-1
	
							//left and right are mutually exclusive due to
							//construction of snes
	//MUST MOVE PADDLE FIRST
	bl		mvPaddle		// Update paddle pos
	
	
	//OTHER MOVES
	bl		mvValPk			//	If value pack is active, update
	

	//MUST MOVE BALL LAST
	bl		mvBall
	
					
	ldr		r1, =gameState
	ldr		r0, [r1, #padX]
	bl		drawPaddle		// Draw Paddle to screen (so it is overtop of the ball and valuepacks)
	pop		{r4, pc}

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////


.global tileToCord
tileToCord:					// Finds coords for the top left corner for a given tile 
@ r0 - tile number

	push	{lr}
	mov		r1, r0
	bl		getTileSize		
	mov		r2, #0
	b		TTCTest			// Go to test 
	
TTCTop:
	add		r2, #1
	sub 	r1, #20
TTCTest:
	cmp 	r1, #20
	bGT 	TTCTop			// If Tile number is over 20 (the num of cols) loop
	
	bl		getTileSize
	mov		r3, r0
	mul		r0, r1, r3		// mul by the tile size to get proper coords
	mul		r1, r2, r3
	
	pop		{pc}

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

.global cordToTile			// Finds the tile who contains the given coords
cordToTile:
@ r0 -x
@ r1 -y
	
	
	lsr		r0, #5
	lsr		r1, #5
	mov		r3, #20
	mul		r1, r3
	add		r0, r1
	bx		lr

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

.global loseLife
loseLife:						// Decrements life counter
								// Sets event to lose if lives == 0
	push	{ lr }
	ldr		r0, =gameState
	ldr		r1, [r0, #lives]
	sub		r1, #1				// Lose one life
	str		r1, [r0, #lives]
	
	cmp		r1, #0				// Check if you have no more lives
	bGT		lifeNext
	mov		r1, #2				// Set event to 2	
	strb	r1, [r0, #event]	// meaning event is in loss condition
	
lifeNext:			

	bl		initBall			// Reinitialize the ball to starting position and speed
	bl		clearTopScreen		// clear the score and life screen
	pop		{ pc }


//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

.global incScore
incScore:							// Increases score by the given amount and draws it to screen
@ r0 - amount to increase score by
	push	{ r4-r5, lr }
	mov		r4, r0
	ldr		r0, =gameState
	ldr		r1, [r0, #score]
	add		r4, r1				// Calculate new score
	
	str		r4, [r0, #score]	// Store score
	
	bl		clearTopScreen
	bl		DrawScore
	pop		{ r4-r5, pc }
	

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

initGame:					// copy map from file to gameMap
							// Then initialize the State variables
		
		ldr		r0, =map1
		ldr		r1, =gameState
		add		r1, #numBricks
		ldrb		r3, [r0], #1	@num bricks
initGameTest:
		strb		r3, [r1], #1
		
		mov		r2, #125		@500/4
		
GameInitTop:
		push		{lr}
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
		
		mov		r3, #5					// Player starts with 5 lives
		str		r3, [r1, #lives]
		
		mov		r3, #0
		str		r3, [r1, #valPk]
		mov		r3, #0					// There is no active value pack
		str		r3, [r1, #score]
		mov		r3, #0					// Start with 0 score
		str		r3, [r1, #event]
		str		r3, [r1, #bigPad]
		str		r3, [r1, #valPkX]
		str		r3, [r1, #valPkY]
		
		bl initBall				// initialize ball values
		pop		{pc}

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

.global initBall
initBall:
// Set ball it its initial position
	ldr		r0, =gameState
	mov		r3, #315
	str		r3, [r0, #ballX]
		
	mov		r3, #635
	str		r3, [r0, #ballY]
		
	mov		r3, #4
	strb	r3, [r0, #ballSpd]
		
	mov		r3, #45
	strb	r3, [r0, #ballAng]
		
	mov		r3, #3
	strb	r3, [r0, #ballDir]

	bx 	lr

	
@ Data section
.section .data
.global gameState
gameState:

	.int	0				// paddleX(left most RELATIVE pixil)
	.byte 	0, 0, 0, 0		// paddleoffsets
	.int 	0				// ballX(top left RELATIVE pixil)
	.int	0				// ballY(top left RELATIVE pixil)
	.byte	0				// ballspeed
	.byte	0				// ballangle
	.byte	0				// balldirection
							@  1 = down right, 2 = down left, 3 = up right, 4 = up left
	.byte	0				// valupack, 0 if inactive, If 1 speed down, if 2 paddle size inc.
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
