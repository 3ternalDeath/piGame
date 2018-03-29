
////////////////CONFIG////////////////////////

.equ	TOP_LEFT_X,	50
.equ	TOP_LEFT_Y, 50
.equ	PADDLE_SIZE_DEFAULT, 100
.equ	PADDLE_SIZE_POWERUP, 200
.equ	BALL_SIZE, 15
.equ	TILE_SIZE, 32

/////////////////CONFIG ENDS///////////////////

	.equ	topLeftXGame, TOP_LEFT_X
	.equ	topLeftYGame, TOP_LEFT_Y + 50 //for printing score and lives
	.equ	paddleY, (TOP_LEFT_Y + (25*TILE_SIZE)) - 50 //50 is the hight of the paddle

@ Contains the draw functions

.text

//////////////////////////////////////////////////
.global unDrawBall
unDrawBall:
	ldr		r2, =0xFF000000
	b		actualDrawBall
.global drawBall
drawBall:
	// I cant think of a good way to draw it as a ball right now
	@ r0 - x pos relative to game
	@ r1 - y pos relative to game
	
	ldr		r2, =0xFFFFFF
	
actualDrawBall:
	push	{ r4, lr }
	
	mov 	r4, #topLeftXGame
	add		r0, r4
	mov		r4, #topLeftYGame
	add 	r1, r4
	mov		r3, #BALL_SIZE
	bl 		drawSquare
	pop		{ r4, pc }
	
/////////////////////////////////////////////////////
.global unDrawPaddle
unDrawPaddle:
	ldr		r2, =0xFF000000
	b		actualDrawPaddle

.global drawPaddle
drawPaddle:
	@ r0 - x pos relative to game
	ldr		r2, =0xCCBBDD
actualDrawPaddle:	
	push	{ r4-r8, lr }
	
	mov		r5, #topLeftXGame
	add		r0, r5
	
	mov		r1, #paddleY
	
	mov		r3, #PADDLE_SIZE_DEFAULT
	mov		r8, #10	// height counter


	mov 	r4, r0	// x
	mov 	r5, r1	// y
	mov 	r6, r2	// colour
	mov 	r7, r3 	// width

	
	paddle_top:
	
	mov 	r0, r4
	mov 	r1, r5
	mov 	r2, r6
	mov		r3, r7
	
	bl		drawHLine
	
	subs	r8, #1
	addNE	r5, #1
	bNE		paddle_top
	
	pop { r4-r8, pc } 
///////////////////////////////////////////////
.global getTileSize
getTileSize:
	mov		r0, #TILE_SIZE
	bx		lr
////////////////////////////////////////////////////////	
@Deprecated
drawBrick:
	@ r0 - x pos relative to game
	@ r1 - y pos relative to game
	@ r2 - Colour
	@ r3 - width
	@ r4 - length
	push	{ r4-r8, lr }
	
	mov		r5, #topLeftXGame
	add		r0, r5
	mov		r5, #topLeftYGame
	add		r1, r5
	mov		r3, #50
	mov		r4, #25
	bl		drawSquare
	
	pop 	{ r4-r8, pc }
//////////////////////////////////////////////////////////
@Deprecated
drawBack:
	push	{ r4-r8, lr }
	mov		r0, #topLeftXGame		@ x
	mov		r1, #topLeftYGame		@ y	
	ldr		r2, =0x0 			@ Black
	mov		r3, #800			@ width
	mov		r4, #600			@ length
	bl		drawSquare
	
	pop		{ r4-r8, pc }

//////////////////////////////////////////////////////////////
.global drawTile
drawTile:
// r0 = address of tile array
// r1 = element number
// if unsigned == 255 or 254, draw gray
// if unsigned == 0 draw black
// if == 4 draw purple
// if ==3 draw blue
// if == 2 draw red
// if == 1 draw orange-yellow
	
	push	{r4, r5, lr}
	
	ldrb 	r5, [r0, r1]

	mov		r0, r1
	mov		r1, #0
	b 	Tile_FindTest
	
// r0 becomes the nth row
// r1 becomes the nth column

	
Tile_FindTop:
	add		r1, #1
	sub 	r0, #20
Tile_FindTest:
	cmp 	r0, #20
	bGE 	Tile_FindTop
	
	mov		r3, #TILE_SIZE	// Set size of tile to 32 pixels
	mul		r0, r3			// Find the pixel co-ords
	mul		r1, r3			//CAN LSL 5 FOR EFFICIENCY
	
	add		r0, #topLeftXGame			// r1 is y-coord
	add		r1, #topLeftYGame			// r0 is x-coord
	

	
	// Check if tile is a wall
	cmp		r5, #255 
	bEQ		wall
	cmp		r5, #254
	bNE		Tile_next1
	
wall:
	ldr		r2, =0xFF6B6B6B		// Grey
	bl		drawSquare
	b		Tile_end
	
	// Check if tile is a floor
Tile_next1:
	cmp		r5, #0
	bNE		Tile_next2
	
	ldr		r2, =0xFF000000		// Black
	bl		drawSquare
	b		Tile_end

	// Check if brick has 4 strength
Tile_next2:
	cmp		r5, #4
	bNE		Tile_next3
	
	ldr		r2, =0xFF79199C 	// Purple
	bl		drawSquare
	b		Tile_end
	
	
	// Check if brick has 3 strength
Tile_next3:
	cmp		r5, #3
	bNE		Tile_next4
	
	ldr		r2, =0xFF0F15BA		// Blue
	bl		drawSquare
	b		Tile_end
	
	// Check if brick has 2 strength
Tile_next4:
	cmp		r5, #2
	bNE		Tile_next5
	
	ldr		r2, =0xFFCC2D30		// Red
	bl		drawSquare
	b		Tile_end
	
	// Brick has 1 strength
Tile_next5:

	ldr		r2, =0xFFBAAF12
	bl		drawSquare
Tile_end:
	
	pop { r4, r5, pc }

//////////////////////////////////////////////////////////////////////	
	
.global drawSquare	
drawSquare:	
@ r0 - top left x co-ordinate
@ r1 - top left y co-ordinate
@ r2 - colour
@ r3 - Size

	push { r4-r8, lr }
	
	mov 	r4, r0	// x
	mov 	r5, r1	// y
	mov 	r6, r2	// colour
	mov 	r7, r3 	// width
	mov		r8, r3 // height counter
	
	
	box_top:
	
	mov 	r0, r4
	mov 	r1, r5
	mov 	r2, r6
	mov		r3, r7
	
	bl		drawHLine
	
	subs	r8, #1
	addNE	r5, #1
	bNE		box_top
	
	pop { r4-r8, pc } 
////////////////////////////////////////////////////////////////////
.global drawHLine
drawHLine:
@ r0 - x
@ r1 - y
@ r2 - colour
@ r3 - length
	
	push { r4-r7, lr }
	
	mov 	r4, r0	// x
	mov 	r5, r1	// y
	mov 	r6, r2	// colour
	mov 	r7, r3 	// length
	
	lineH_top:
	
	mov 	r0, r4
	mov 	r1, r5
	mov 	r2, r6

	bl DrawPixel
	
	add		r4, #1
	subs	r7, #1
	bNE 	lineH_top
	
	
	pop { r4-r7, pc }
/////////////////////////////////////////////////////////	
.global drawVLine
drawVLine:
@ r0 - x
@ r1 - y
@ r2 - colour
@ r3 - length

	push { r4-r8, lr }
	
	mov 	r4, r0	// x
	mov 	r5, r1	// y
	mov 	r6, r2	// colour
	mov 	r7, r3 	// length
	
	ldr		r0, =frameBufferInfo
	
	ldr		r8, [r0, #4]	// r8 = width
	
	lineV_top:
	
	mov 	r0, r4	// x
	mov 	r1, r5	// y
	mov 	r2, r6	// colour
	mov 	r3, r7 	// length
	
	bl		DrawPixel
	
	subs 	r7, #1
	addNE	r5, #1
	bNE		lineV_top
	pop { r4-r8, pc }

/////////////////////////////////////////////////////
@ Draw Pixel
@  r0 - x
@  r1 - y
@  r2 - colour

.global DrawPixel
DrawPixel:
	push		{r4, r5, r6}

	offset		.req	r4

	ldr		r5, =frameBufferInfo	

	@ offset = (y * width) + x
	
	ldr		r3, [r5, #4]		@ r3 = width
	mul		r1, r3
	add		offset,	r0, r1
	
	@ offset *= 4 (32 bits per pixel/8 = 4 bytes per pixel)
	lsl		offset, #2

	@ store the colour (word) at frame buffer pointer + offset
	ldr		r0, [r5]		@ r0 = frame buffer pointer
	str		r2, [r0, offset]

	pop		{r4, r5, r6}
	bx		lr
////////////////////////////////////////////////////////


.data
.align
.globl frameBufferInfo
frameBufferInfo:
	.int	0		@ frame buffer pointer
	.int	1024		@ screen width
	.int	767		@ screen height
