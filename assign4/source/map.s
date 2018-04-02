@ Contains the data for the map

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
	
						//4 lines of emptyness
	.rept	4
		.byte 	255
		.rept 	18
			.byte	0 
		.endr
		.byte	255
	.endr
	
	
						// 1 lines medium bricks

	.byte 	255
	.rept 	18
		.byte	2 
	.endr
	.byte	255

						//1 lines of hard bricks
		.byte 	255
		.rept 	18
			.byte	3 
		.endr
		.byte	255
						// 1 line of empty
	.byte 	255
		.rept 	18
			.byte	0
		.endr
		.byte	255
	
						// l 1ines medium bricks

	.byte 	255
	.rept 	18
		.byte	2 
	.endr
	.byte	255
	
						// 1 line of easy bricks
	.byte 	255
		.rept 	18
			.byte	1 
		.endr
		.byte	255
		
						//	1 line of easy valuepack bricks
	.byte 	255
		.rept 	9
			.byte	5
			.byte	9 
		.endr
	.byte	255
	
	//13 lines of empty
	.rept	13
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
