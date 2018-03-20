
@ Contains the draw functions

.text


.global drawBall
drawBall:
	// I cant think of a good way to draw it as a ball right now
	@ r0 - x pos relative to game
	@ r1 - y pos relative to game
	
	push	{ r4-r8, lr }
	
	mov 	r5, #1100
	add		r0, r5
	add 	r1, #100
	ldr		r2, =0xFFFFFF
	mov		r3, #20
	mov		r4, #20
	bl 		drawBox
	pop		{ r4-r8, pc }
	

.global drawPaddle
drawPaddle:
	@ r0 - x pos relative to game
	
	push	{ r4-r8, lr }
	
	mov		r5, #1100
	add		r0, r5
	
	mov		r1, #600
	ldr		r2, =0xCCBBDD
	mov		r3, #125
	mov		r4, #20
	bl		drawBox
	
	pop		{ r4-r8, pc }
	
.global drawBrick
drawBrick:
	@ r0 - x pos relative to game
	@ r1 - y pos relative to game
	@ r2 - Colour
	@ r3 - width
	@ r4 - length
	push	{ r4-r8, lr }
	
	mov		r5, #1100
	add		r0, r5
	add		r1, r1, #100
	mov		r3, #50
	mov		r4, #25
	bl		drawBox
	
	pop 	{ r4-r8, pc }

.global drawBack
drawBack:
	push	{ r4-r8, lr }
	mov		r0, #1100		@ x
	mov		r1, #100		@ y	
	ldr		r2, =0x0 		@ Black
	mov		r3, #800		@ width
	mov		r4, #600		@ length
	bl		drawBox
	
	pop		{ r4-r8, pc }


	

	
	
.global drawBox	
drawBox:	
@ r0 - top left x co-ordinate
@ r1 - top left y co-ordinate
@ r2 - colour
@ r3 - Width
@ r4 - Length
	
	push { r5-r8, lr }
	
	mov		r8, r4	// height counter
	mov 	r4, r0	// x
	mov 	r5, r1	// y
	mov 	r6, r2	// colour
	mov 	r7, r3 	// width
	
	
	box_top:
	
	mov 	r0, r4
	mov 	r1, r5
	mov 	r2, r6
	mov		r3, r7
	
	bl		drawHLine
	
	subs	r8, #1
	addNE	r5, #1
	bNE		box_top
	
	pop { r5-r8, pc }

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



.data
.align
.globl frameBufferInfo
frameBufferInfo:
	.int	0		@ frame buffer pointer
	.int	1024		@ screen width
	.int	767		@ screen height
