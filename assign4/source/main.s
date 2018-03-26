
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

	bl		initMap

	bl		drawBack
	
	mov		r0, #20
	mov		r1, #30
	ldr		r2, =0xFFF00FF
	bl		drawBrick
	
	mov		r0, #75
	mov		r1, #30
	ldr		r2, =0xFFF00FFF
	bl		drawBrick

	
	mov		r0, #300
	bl		drawPaddle
	
	mov		r0, #300
	mov		r1, #200
	bl		drawBall
	
	ldr		r0, =gameState
	add		r0, #numBricks
	@ stop
	haltLoop$:
		b	haltLoop$
		

	
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
		
		
		
firstMapDraw:
		push	{r4-r5, lr}
		
		mov		r4, #0
		mov		r5, #0
		
outerTop:
		
		
		pop		{r4-r5, lr}

@ Data section
.section .data
.global gameState
gameState:
//NEED TO INIT SOME OF THESE

	.int	300 			// paddleX
	.byte 	0, 0, 0, 0 		// paddleoff
	.int 	0				// ballX(top left pixil)
	.int	0				// ballY(top left pixil)
	.byte	1				// ballspeed
	.byte	45				// ballangle
	.byte	0				// balldirection
							//  = up right, 2 = up left, 3 = down left, 4 = down right
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
