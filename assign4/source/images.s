
@ Code section
.section .text


.equ	TOP_LEFT_X,	100
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

@ Data section
.section .data

.align 4
font:		.incbin	"font.bin"
