
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
	

	ldr		r1, =gameState		// Check win/lose condition
	ldrb	r2, [r1, #event]
	
	cmp		r2, #2				// If event is 2, show lost screen
	bNE		mainNotLose
	
	ldr		r0, =GameOverImg
	bl		DrawScreen
	b		mainChkLoop

	
mainNotLose:

	cmp		r2, #1				// If event is 2, show lost screen
	bNE		mainNotWin
	
	ldr		r0, =GameWonImg
	bl		DrawScreen
	b		mainChkLoop
	
mainChkLoop:
	bl 		Read_SNES
	cmp		r0, #0
	beq		mainChkLoop		// loop until input is given
	mov		r0, #60000		// Give it a pause for buttons to reset
	bl 		delayMicroseconds
	b		Start

mainNotWin:
    mov 	r0, #17500			// controls game speed
    bl		delayMicroseconds
    
	b		mainGameLoop
	@ stop
	haltLoop$:
		b	haltLoop$
		
		

	
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

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
	
				
	ldr		r1, =gameState
	ldr		r0, [r1, #padX]
	bl		drawPaddle
	//MUST MOVE BALL LAST
	bl		mvBall
	
	pop		{r4, pc}

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

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

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////



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

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

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

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

.global loseLife
loseLife:
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

	mov		r3, #315
	str		r3, [r0, #ballX]
		
	mov		r3, #655
	str		r3, [r0, #ballY]
		
	mov		r3, #2		
	strb		r3, [r0, #ballSpd]
		
	mov		r3, #45
	strb		r3, [r0, #ballAng]
		
	mov		r3, #3
	strb		r3, [r0, #ballDir]
	bl		clearTopScreen
	pop		{ pc }


//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
// Increases score and draws it to screen
.global incScore
incScore:
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
		
		mov		r3, #99
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
		

		bx		lr

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

	


	
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
