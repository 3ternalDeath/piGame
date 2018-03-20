@ This is a SNES driver
@ snesSetup needs to be called once and only once
@ after which Read_SNES can be called as manny times as needed
@ This driver assumes the following:

@		latch = pin 9
@		clock = pin 11
@		data  = pin 10

.section	.text


@ Gets GPIO base address
@ Sets pins 9,11 to Output
@ Sets pin 10 to Input
.global	snesSetup
snesSetup:
	push	{lr}
	
	bl		getGpioPtr
	ldr		r1, =gpioBase
	str		r0, [r1]
	
	mov		r0, #11
	mov		r1, #1
	bl		Init_GPIO
	
	mov		r0, #9
	mov		r1, #1
	bl		Init_GPIO
	
	mov		r0, #10
	mov		r1, #0
	bl		Init_GPIO

	pop		{pc}
	
	
@ Gets user input from SNES Controller
@ returns 12 bits in the least significant bits of r0
@ each bit coresponding to a button, where 1 is pressed and 0 is not pressed
@ 0, 0, ... 0, B, Y, Sel, Srt, Up, Dwn, Lft, Rgt, A, X, BumL, BumR
.global	Read_SNES	
Read_SNES:
	push	{r4, r5, lr}


	// Getting SNES to save state
	mov		r0, #1
	bl		Write_Clock			
	
	mov		r0, #1
	bl		Write_Latch
	
	mov		r0, #12
	bl		delayMicroseconds
	
	mov		r0, #0
	bl		Write_Latch
	
	mov		r4, #0			// r4 - Loop counter
	mov		r5, #0			// r5 - SNES Input
	b		readLoopTest
readLoop:
	lsl		r5, #1			// Sets up r5 to take next input
	add		r5, #1			// Adds #1 to invert hardware signal

	mov		r0, #6				
	bl		delayMicroseconds
	
	mov		r0, #0			// Downshift the clock
	bl		Write_Clock
	
	mov		r0, #6
	bl		delayMicroseconds
	
	bl		Read_Data		// Gets a button state from SNES
	
	eor		r5, r0			// Inverts Hardware Signal
	
	mov		r0, #1
	bl		Write_Clock		// Upshifts the clock
	
	add		r4, #1			// Increment Loop counter
	
readLoopTest:
	cmp		r4, #12			// Loop for the 12 SNES Buttons
	blt		readLoop
	
	mov		r0, r5			// Return the Button values
	
	pop		{r4, r5, pc}
	
	


@ Initializes a GPIO line to a Function
@ r0 = GPIO line number
@ r1 = desired function for GPIO line
Init_GPIO:
	ldr		r3, =gpioBase
	ldr		r2, [r3]
initLoop:
	cmp		r0, #9
	subhi	r0, #10
	addhi	r2, #4
	bhi		initLoop
	
								// Find Left-shift value for bitmask
	add		r0, r0, lsl #1		//r0 * 3
	lsl		r1, r0				// Shift setmask

	mov		r3, #7				// 0b111
	lsl		r3, r0				// Shift clearmask  

	//set function of pin
	ldr		r0, [r2]			// Loads from appropriate GPIO register
	bic		r0, r3				
	orr		r0, r1				
	str		r0, [r2]		
	
	bx		lr
	
	
@ Writes bit to latch
@ r0 = bit to write
Write_Latch:
	push	{lr}
	mov		r1, #9					
	bl		Write_Line
	pop		{pc}
		
		
@ Writes bit to Clock	
@ r0 = bit to write
Write_Clock:
	push	{lr}
	mov		r1, #11					
	bl		Write_Line
	pop		{pc}
	


@ Writes bit to line		
@ r0 = bit to write
@ r1 = line to write to
Write_Line:
	ldr		r2, =gpioBase
	ldr		r2, [r2]
	mov		r3, #1
		
	cmp		r1, #31
	ble		wrtNxt			// Branches if writing to pins 0-31
	
	//	Executes if writing to pins 32+	
	sub		r1, #32			
	lsl		r3, r1
	teq		r0, #0
	streq	r3, [r2, #0x2C]		// Offsets by 44 to reach GPCLR1
	strne	r3, [r2, #0x20]		// Offsets by 32 to reach GPSET1
	
	bx		lr
		
wrtNxt:
	lsl		r3, r1
	teq		r0, #0
	streq	r3, [r2, #0x28]		// Offsets by 40 to reach GPCLR0
	strne	r3, [r2, #0x1C]		// Offsets by 28 to reach GPSET0
		
	bx		lr
	
	
@ Reads bit from Data line	
@ returns bit (0 or 1)
Read_Data:
	ldr		r1, =gpioBase
	ldr		r1, [r1]
	ldr		r2, [r1, #0x34]		// Loads state of GPLEV0
	mov		r0, #0x400			// Mask for reading pin 10
	and		r0, r2
	teq		r0, #0				// return 0 if r0 == 0
	movne	r0, #1				// return 1 if r0 != 0
	bx		lr
	


	

.section	.data
.align	2

.global gpioBase
gpioBase:
	.int	0
