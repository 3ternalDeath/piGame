
.section .text
//////////// OffSets /////////////////////////////
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
////////////// OffSets  ///////////////////////////
.global movePaddle
movePaddle:
// @r0 direction moved
// 1 - Left
// 2 - Right
// 0 - Stay in Place
	
	ldr		r1, =gameState
	ldr		r2, [r1, #padX]
	ldr		r3, [r1, #padOff3]	// Right edge

	cmp		r0, #1
	bGT		PaddleRight
	bNE		PaddleEnd
PaddleLeft:
	
	sub		r2, #1
	str		r2, [r1, #padX]
PaddleRight:
	add		r2, #1
	str		r2, [r1, #padX]
PaddleEnd:

	bx		lr

