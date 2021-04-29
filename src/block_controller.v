`timescale 1ns / 1ps

module block_controller(
	input clk, //this clock must be a slow enough clock to view the changing positions of the objects
	input bright,
	input rst,
	input left, input right,
	input [9:0] hCount, vCount,
	output reg [11:0] rgb,
	output reg [11:0] background
   );
	wire paddle_fill;
	wire background_fill;

	integer i;
	integer j;
	
	//these two values dictate the center of the block, incrementing and decrementing them leads the block to move in certain directions
	reg [9:0] xpos, ypos;
	
	parameter RED   = 12'b1111_0000_0000;
	parameter WHITE = 12'b1111_1111_1111;
	parameter PINK  = 12'b1111_0000_1111;
	parameter BLUE = 12'b0000_0000_1111;
	parameter LIGHT_BLUE  = 12'b0000_1111_1111;
	parameter BRIGHT_GREEN = 12'b0000_1111_0000;
	
/**	Fill grid of blocks
*/	
	// reg [60:0] blocks;
	// 21:12 = x position
	// 11:2 = y position
	// 1 = color (isRed)
	// 0 = has been hit or not
	// ------ 0 = vCount and hCount overlap block area ------- not doing this
	reg [21:0] blocks [0:4][0:11];
	wire blocks_fill [0:4][0:11];

	// each block will be 53 wide, 12 blocks wide, 0px in between each block
	// 25 pixels tall, 5 rows, 0 px in between
	// entire vga monitor pixels:
	// cols aka x pos: starts at 144 ends at 780
	// rows aka y pos: starts at 34px, ends at ~514px
	// but for our block_grid, rows end at 159 px.
	genvar block_i;
	genvar block_j;
	generate
	for(block_i = 0; block_i < 5; block_i = block_i + 1)
	begin			// i represents x pos
		for( block_j = 0; block_j < 12; block_j = block_j + 1)
		begin		// j represents y pos	
			// parameter x_pos = block_i*53 + 144;
			// parameter y_pos = block_j*25 + 34;		
			assign blocks_fill[block_i][block_j] = 
				(vCount >= (block_j*25 + 34)) &&		// top
				(vCount <= (block_j*25 + 59)) &&		// bottom
				(hCount >= (block_i*53 + 144)) &&		// left
				(hCount <= (block_i*53 + 197));			// right
		end
	end
	endgenerate

	/*when outputting the rgb value in an always block like this, make sure to include the if(~bright) statement, as this ensures the monitor 
	will output some data to every pixel and not just the images you are trying to display*/
	always@ (*) begin
    	if(~bright )	//force black if not inside the display area
			rgb = 12'b0000_0000_0000;
		else if (paddle_fill) 
			rgb = RED; 

		// else if (blocks)
		// 	rgb = PINK;
		else if (~background_fill)
		begin
			// if (hCount < 500)
			// 	rgb = BLUE;
			// else
			// 	rgb = PINK;
			for(i = 0; i < 5; i = i + 1)
			begin
				for( j = 0; j < 12; j = j + 1 )
				begin
					// if(blocks_fill[i][j] == 1)	//block is in the grid area
					// begin
						// if(blocks[i][j][0] == 1)// if block has been hit
						// begin
						// 	//set rgb to background
						// 	rgb=WHITE;
						// end
						// else	//block has not been hit
						// begin
						if(blocks[i][j][1] == 1)		// alternating block colors
							rgb=PINK;
						else
							rgb=LIGHT_BLUE;
						
						// end
					// end
					// else	//block is not in grid area
					// 	rgb=WHITE;
				end
			end
		end
		else	// background fill
			rgb = BRIGHT_GREEN;
			
	end
		//the +-5 for the positions give the dimension of the block (i.e. it will be 50x10 pixels), 50 wide, 10 tall
	assign paddle_fill=vCount>=(ypos-5) && vCount<=(ypos+5) && hCount>=(xpos-25) && hCount<=(xpos+25);
	assign background_fill= vCount>=(159);

	always@(posedge clk, posedge rst) 
	begin
		if(rst)
		begin 
			//rough values for center of screen
			background <= WHITE;

			xpos<=450;
			ypos<=500;
			
			for(i = 0; i < 5; i = i + 1)
			begin			// i represents x pos
				for( j = 0; j < 12; j = j + 1 )
				begin: block_init		// j represents y pos			
					// parameter x_pos = block_i*53 + 144;
					// parameter y_pos = block_j*25 + 34;						
					blocks[i][j][21:12] <= i*53 + 144;		// x pos
					blocks[i][j][11:2] <= j*25 + 34;		// y pos
					if ((i % 2) == 0)
						begin
							if ((j % 2) == 0) blocks[i][j][1] <= 1;				// 1 = red
							else blocks[i][j][1] <= 0; 							// 0 = light blue
						end
					else
						begin
							if ((j % 2) == 0) blocks[i][j][1] <= 1;
							else blocks[i][j][1] <= 0;
						end
					blocks[i][j][0] <= 0;		// initialize block to state of being not hit
				end
			end



		end
		else if (clk) begin
		
		/* Note that the top left of the screen does NOT correlate to vCount=0 and hCount=0. The display_controller.v file has the 
			synchronizing pulses for both the horizontal sync and the vertical sync begin at vcount=0 and hcount=0. Recall that after 
			the length of the pulse, there is also a short period called the back porch before the display area begins. So effectively, 
			the top left corner corresponds to (hcount,vcount)~(144,35). Which means with a 640x480 resolution, the bottom right corner 
			corresponds to ~(783,515).  
		*/
			if(right) begin
				xpos<=xpos+2; //change the amount you increment to make the speed faster 
				if(xpos==800) //these are rough values to attempt looping around, you can fine-tune them to make it more accurate- refer to the block comment above
					xpos<=800;		// if wrapping, set to 150
			end
			else if(left) begin
				xpos<=xpos-2;
				if(xpos==150)
					xpos<=150;		// if wrapping, set xpos to 800
			end
			// else if(up) begin
			// 	ypos<=ypos-2;
			// 	if(ypos==34)
			// 		ypos<=514;
			// end
			// else if(down) begin
			// 	ypos<=ypos+2;
			// 	if(ypos==514)
			// 		ypos<=34;
			// end
		end
	end
	
	//the background color reflects the most recent button press
	// always@(posedge clk, posedge rst) begin
	// 	// if(rst)
	// 	background <= 12'b1111_1111_1111;
	// 	// else 
	// 	// 	if(right)
	// 	// 		background <= 12'b1111_1111_0000;		// yellow orange ish
	// 	// 	else if(left)
	// 	// 		background <= 12'b0000_1111_1111;		// light blue
	// 	// 	else if(down)
	// 	// 		background <= 12'b0000_1111_0000;		// bright green
	// 	// 	else if(up)
	// 	// 		background <= 12'b0000_0000_1111;		// royal blue
	// end

	
	
endmodule
