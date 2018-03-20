
@ Code section
.section .text

.global main
main:
	@ ask for frame buffer information
	ldr 		r0, =frameBufferInfo 	@ frame buffer information structure
	bl		initFbInfo

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
	
	@ stop
	haltLoop$:
		b	haltLoop$
		

	
	
	




@ Data section
.section .data
.global pixelMap
pixelMap:



