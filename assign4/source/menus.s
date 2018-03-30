.section .text

////////////////////
.global PauseMenu
PauseMenu:
	push { r4, lr }
	mov		r4, #1
	bl		DrawPause
	
	mov		r0, #60000		// Give it a pause for buttons to reset
	bl 		delayMicroseconds
	mov		r0, #60000		
	bl 		delayMicroseconds
PauseTop:

		bl 		Read_SNES
		tst		r0, #0x100
		bNE		PauseEnd		// If start is pressed, exit menu

PauseNext:	
		tst		r0, #0x80		// Pad-Up is pressed
		movNE	r4, #1


		tst		r0, #0x40		// Pad-Down is pressed
		movNE	r4, #0


		mov		r0, r4
		bl		DrawArrow
		mov		r0, r4
		bl		EraseArrow
		
		b 		PauseTop
PauseEnd:
		bl		fullMapDraw
		mov		r0, #60000		// Give it a pause for buttons to reset
	bl 		delayMicroseconds
		mov		r0, #30000
		bl		delayMicroseconds
	pop { r4, pc }
	
	/////////////////////////////////////////////////