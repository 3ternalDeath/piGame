
@ Code section
.section .text


.equ	TOP_LEFT_X,	50
.equ	TOP_LEFT_Y, 100

@ Draw the specified character to the location with size
@ with respect to the game
.global DrawChar
DrawChar:
@	r0 - x pos
@	r1 - y pos
@	r2 - ascii character
@ 	r3 - size


	push		{r4-r8, fp, lr}
	
	chAdr	.req	r4
	px		.req	r5
	py		.req	r6
	row		.req	r7
	mask		.req	r8
	
	.equ 	alloc, 17
	.equ	xoff, 0
	.equ	yoff, -4 
	.equ	charoff, -8
	.equ	sizeoff, -16
	
	mov 	fp, sp
	sub 	sp, #alloc
	
	add		r0, #TOP_LEFT_X
	add		r1, #TOP_LEFT_Y
	
	str		r0, [fp, #xoff]
	str		r1, [fp, #yoff]
	str		r2, [fp, #charoff]
	str		r3, [fp, #sizeoff]

	ldr		chAdr, =font		@ load the address of the font map
	ldr		r0, [fp, #charoff]		@ load the character into r0
	add		chAdr,	r0, lsl #4	@ char address = font base + (char * 16)

	ldr		py, [fp, #yoff]		@ init the Y coordinate (pixel coordinate)

charLoop$:
	ldr		px, [fp, #xoff]		@ init the X coordinate

	mov		mask, #0x01		@ set the bitmask to 1 in the LSB
	
	ldrb		row, [chAdr], #1	@ load the row byte, post increment chAdr

rowLoop$:
	tst		row,	mask		@ test row byte against the bitmask
	beq		noPixel$

	mov		r0, px
	mov		r1, py
	mov		r2, #0x00FF0000		@ red
	ldr		r3, [fp, #sizeoff]
	bl		drawSquare		@ draw red pixel at (px, py)

noPixel$:
	ldr		r0, [fp, #sizeoff]			@ increment x coordinate by size
	add		px, r0
	lsl		mask, #1		@ shift bitmask left by 1

	tst		mask,	#0x100		@ test if the bitmask has shifted 8 times (test 9th bit)
	beq		rowLoop$
	
	ldr		r0, [fp, #sizeoff]			@ increment y coordinate by the size
	add		py, r0
	
	tst		chAdr, #0xF
	bne		charLoop$		@ loop back to charLoop$, unless address evenly divisibly by 16 (ie: at the next char)

	.unreq	chAdr
	.unreq	px
	.unreq	py
	.unreq	row
	.unreq	mask
test:
	add 	sp, #alloc
	pop		{r4-r8, fp, pc}

////////////////////////////////////////////////////

.global DrawScreen
DrawScreen:
@	r0 - Address of screen to print
	push { r4-r11, lr }
	
	mov	r11, r0
	mov r4, #TOP_LEFT_X
	mov	r5, #TOP_LEFT_Y
	
	mov	r0, #640		// Width of img
	add	r6, r4, r0		
	mov	r0, #800		// Height of img
	add	r7, r5, r0		
	mov r8, #0
	
	mov r9, r4
	mov r10, r5
ScreenLine$:
	ldr	r2, [r11, r8, lsl #2]
	mov	r0, r9
	mov r1, r10
	bl DrawPixel
	
	add	r9, #1
	add	r8, #1
ScreenLineTest$:
	cmp	r9, r6
	bLT ScreenLine$

	add r10, #1
	cmp r10, r7
	movLE r9, r4
	bLT  ScreenLine$
	
	pop	{ r4-r11, pc }

////////////////////////////////////////////////////

.global DrawPause
DrawPause:
@	r0 - Address of screen to print
	push { r4-r10, lr }
	
	mov r4, #TOP_LEFT_X + 45
	mov	r5, #TOP_LEFT_Y + 240
	
	mov	r0, #550		// Width of img
	add	r6, r4, r0		
	mov	r0, #450		// Height of img
	add	r7, r5, r0		
	mov r8, #0
	
	mov r9, r4
	mov r10, r5
PauseLine$:
	ldr		r0, =PauseMenuImg
	ldr	r2, [r0, r8, lsl #2]
	mov	r0, r9
	mov r1, r10
	bl DrawPixel
	
	add	r9, #1
	add	r8, #1
PauseLineTest$:
	cmp	r9, r6
	bLT PauseLine$

	add r10, #1
	cmp r10, r7
	movLE r9, r4
	bLT  PauseLine$
	
	pop	{ r4-r10, pc }
	
/////////////////////
.global EraseArrow
EraseArrow:
@ r0 - 0 Erases at quit, 1 erases at Start
	push { r4-r10, lr }
	
	mov r4, #TOP_LEFT_X
	add r4, #100
	mov	r5, #TOP_LEFT_Y
	
	cmp r0, #1
	bEQ	ErpointQuit
	
	mov r0, #370
	add	r5, r0
	b 	ErpointNext
ErpointQuit:
	mov r0, #515
	add	r5, r0
ErpointNext:
	
	mov	r0, #70		// Width of img
	add	r6, r4, r0		
	mov	r0, #45		// Height of img
	add	r7, r5, r0		
	mov r8, #0
	
	mov r9, r4
	mov r10, r5
ErArrowLine$:
	ldr	r2, =0x3AE067
	mov	r0, r9
	mov r1, r10
	bl DrawPixel
	
	add	r9, #1
	add	r8, #1
ErArrowLineTest$:

	cmp	r9, r6
	bLT ErArrowLine$

	add r10, #1
	cmp r10, r7
	movLE r9, r4
	bLT  ErArrowLine$
	pop	{ r4-r10, pc }


////////////////////////////////////////////
.global DrawArrow
DrawArrow:
@ r0 - 0 points to Start, 1 points to quit
	push { r4-r10, lr }
	
	mov r4, #TOP_LEFT_X
	add r4, #100
	mov	r5, #TOP_LEFT_Y
	
	cmp r0, #1
	bNE	pointQuit
	mov r0, #370
	add	r5, r0
	b 	pointNext
pointQuit:
	mov r0, #515
	add	r5, r0
pointNext:
	
	mov	r0, #70		// Width of img
	add	r6, r4, r0		
	mov	r0, #45		// Height of img
	add	r7, r5, r0		
	mov r8, #0
	
	mov r9, r4
	mov r10, r5
ArrowLine$:
	ldr r0, =arrowImg
	ldr	r2, [r0, r8, lsl #2]
	mov	r0, r9
	mov r1, r10
	bl DrawPixel
	
	add	r9, #1
	add	r8, #1
ArrowLineTest$:

	cmp	r9, r6
	bLT ArrowLine$

	add r10, #1
	cmp r10, r7
	movLE r9, r4
	bLT  ArrowLine$
	pop	{ r4-r10, pc }

/////////////////////
@ Data section
.section .data

.align 4
font:		.incbin	"font.bin"
