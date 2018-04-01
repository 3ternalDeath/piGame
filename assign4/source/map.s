.section .text
//0 = floor
//255 = wall
//254 = roof
//253 = lava
//1 = brick, 1 more hit
//2 = brick, 2 more hits
//3 = brick, 3 more hits
//4 = brick, 4 more hits
//5 = valPk1, 1 more hit
//...
//9 = valPk2, 1 more hit
.global map1
map1:
	.byte	162

	//first line of tiles
	.rept 20 
		.byte 254 
	.endr
	//first line of tiles
	
	//3 lines of emptyness
	.rept	3
		.byte 	255
		.rept 	18
			.byte	0 
		.endr
		.byte	255
	.endr

	//2 lines of HARD bricks
	.rept	2
		.byte 	255
		.byte	12
		.rept 	16
			.byte	4 
		.endr
		.byte	8
		.byte	255
	.endr
	
	//1 line of easy bricks
	.byte 	255
	.rept 	18
		.byte	1 
	.endr
	.byte	255
	
	//2 lines of hard bricks
	.rept	2
		.byte 	255
		.rept 	18
			.byte	3 
		.endr
		.byte	255
	.endr
	
	//4 lines of alternating meh and easy bricks
	.rept	2
		.byte 	255
		.rept 	18
			.byte	2 
		.endr
		.byte	255
		.byte 	255
		.rept 	18
			.byte	1 
		.endr
		.byte	255
	.endr
	
	.byte 	255
		.rept 	18
			.byte	5 
		.endr
		.byte	255
	
	//10 lines of empty
	.rept	10
		.byte 	255
		.rept 	18
			.byte	0 
		.endr
		.byte	255
	.endr
	
	//1 line of death
	.byte	255
	.rept	18
		.byte	253
	.endr
	.byte 255
