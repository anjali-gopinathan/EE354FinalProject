`timescale 1ns / 1ps

module block_controller(
	input fastClk,
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
	wire ball_fill;

	integer i;
	integer j;
	
	//these two values dictate the center of the block, incrementing and decrementing them leads the block to move in certain directions
	reg [9:0] xpos, ypos;
	reg [9:0] ball_x, ball_y;
	
	localparam
	RED			= 12'b1111_0000_0000,
	WHITE		= 12'b1111_1111_1111,
	PINK		= 12'b1111_0000_1111,
	BLUE		= 12'b0000_0000_1111,
	LIGHT_BLUE	= 12'b0000_1111_1111,
	BRIGHT_GREEN= 12'b0000_1111_0000,
	BLACK		= 12'b0000_0000_0000,
	PURPLE		= 12'b1000_0010_1111;
	
	localparam
	LEFT_WALL_X = 190,		// supposed to be 144
	RIGHT_WALL_X = 790,		// maybe 783?
	CEILING_Y = 35,
	FLOOR_Y = 515,
	BOTTOM_OF_GRID_Y = 160,
	BALL_WIDTH = 5,
	BALL_HEIGHT = 5,
	PADDLE_WIDTH = 25,
	PADDLE_HEIGHT = 5;

	integer BLOCK_WIDTH = (RIGHT_WALL_X - LEFT_WALL_X) / 12;		// 53 ish
	integer BLOCK_HEIGHT = (BOTTOM_OF_GRID_Y - CEILING_Y) / 5;		// 25 ish
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
	for(block_i = 0; block_i < 12; block_i = block_i + 1)
	begin			// i represents x pos
		for( block_j = 0; block_j < 5; block_j = block_j + 1)
		begin		// j represents y pos	
			// parameter x_pos = block_i*53 + 144;
			// parameter y_pos = block_j*25 + 34;		
			assign blocks_fill[block_j][block_i] = 
				(vCount >= ((block_j*BLOCK_HEIGHT) + CEILING_Y)) &&		// top
				(vCount <= ((block_j*BLOCK_HEIGHT) + CEILING_Y + BLOCK_HEIGHT)) &&		// bottom
				(hCount >= ((block_i* BLOCK_WIDTH) + LEFT_WALL_X)) &&		// left
				(hCount <= ((block_i* BLOCK_WIDTH) + LEFT_WALL_X + BLOCK_WIDTH));			// right
		end
	end
	endgenerate

	/*when outputting the rgb value in an always block like this, make sure to include the if(~bright) statement, as this ensures the monitor 
	will output some data to every pixel and not just the images you are trying to display*/
	always@ (*) begin
    	if(~bright )	//force black if not inside the display area
		begin
			rgb = 12'b0000_0000_0000;
		end
		else if (paddle_fill) 
		begin
			rgb = RED;
		end
		else if (ball_fill)
		begin
			rgb = PURPLE;
		end
		else if (~background_fill)
		begin
			for(i = 0; i < 12; i = i + 1)
			begin
				for( j = 0; j < 5; j = j + 1 )
				begin
					if(blocks_fill[j][i] == 1)	// hcount and vcount are on top of the block
					begin
						if(blocks[j][i][0] == 1)// if block has been hit
						begin
							//set rgb to background
							rgb=WHITE;
						end
						else	//block has not been hit
						begin
							if(blocks[j][i][1] == 1)		// alternating block colors
							begin
								rgb=PINK;
							end
							else
							begin
								rgb=BLUE;
							end
						end
					end
				end
			end
		end
		else	// background fill (hcount and vcount are below the blocks)
			rgb = BRIGHT_GREEN;
			
	end
		//the +-5 for the positions give the dimension of the block (i.e. it will be 50x10 pixels), 50 wide, 10 tall
	assign paddle_fill=vCount>=(ypos-5) && vCount<=(ypos+5) && hCount>=(xpos-25) && hCount<=(xpos+25);
	assign background_fill= vCount>=(BOTTOM_OF_GRID_Y);
<<<<<<< HEAD
	assign ball_fill=vCount>=(ball_y-5) && vCount<=(ball_y+5) && hCount>=(ball_x-25) && hCount<=(ball_x+25);
=======
	assign ball_fill=vCount>=(ball_y-5) && vCount<=(ball_y+5) && hCount>=(ball_x-5) && hCount<=(ball_x+5);
>>>>>>> 5eedb18642b3b4f660fb9048c4e5739a752ed584

	integer ball_x_vel;
	integer ball_y_vel;

	always@(posedge clk, posedge rst) 
	begin
		if(rst)
		begin 
			//rough values for center of screen
			background <= WHITE;

			xpos<=450;
			ypos<=500;

			ball_x<=450;		//later want to randomize this position
			ball_y<=480;
			
			for(i = 0; i < 12; i = i + 1)
			begin			// i represents x pos
				for( j = 0; j < 5; j = j + 1 )
				begin: block_init		// j represents y pos			
					// parameter x_pos = block_i*53 + 144;
					// parameter y_pos = block_j*25 + 34;						
					blocks[j][i][21:12] <= i*BLOCK_WIDTH + LEFT_WALL_X;		// x pos
					blocks[j][i][11:2] <= j*BLOCK_HEIGHT + CEILING_Y;		// y pos
					if ((i % 2) == 0)
						begin
							if ((j % 2) == 0) blocks[j][i][1] <= 0;				// 1 = pink
							else blocks[j][i][1] <= 1; 							// 0 = blue
						end
					else
						begin
							if ((j % 2) == 0) blocks[j][i][1] <= 1;
							else blocks[j][i][1] <= 0;
						end
					blocks[j][i][0] <= 0;		// initialize block to state of being not hit
				end
			end

			// initialize ball to go Southeast 
			ball_x_vel <= 2;
			ball_y_vel <= 2;

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
				if(xpos==RIGHT_WALL_X) //these are rough values to attempt looping around, you can fine-tune them to make it more accurate- refer to the block comment above
					xpos<=RIGHT_WALL_X;		// if wrapping, set to 150
			end
			else if(left) begin
				xpos<=xpos-2;
				if(xpos==LEFT_WALL_X)
					xpos<=LEFT_WALL_X;		// if wrapping, set xpos to 800
			end

			// paddle collision
			if (collide_paddle(x_pos, y_pos))
			begin
				ball_y_vel = -ball_y_vel;		// reverse ball's y velocity
			end
			// block collisions
			else
			begin
				for(i = 0; i < 12; i = i + 1)
				begin
					for(j = 0; j < 5; j = j + 1)
					begin
						if (collide_block(blocks[j][i][21:12], blocks[j][i][11:2]))
						begin
							if (~blocks[j][i][0])			// block has not already been hit
							begin
								blocks[j][i][0] = 1;		// set block to hit
								ball_y_vel = -ball_y_vel;	// reverse ball's y velocity
							end
						end
					end
				end

			ball_x <= ball_x + (ball_x_vel);
			ball_y <= ball_y + (ball_y_vel);
			
		end
	end

	// ball collision functions

	function collide_block;
		input [9:0] block_x;
		input [9:0] block_y;
		begin
			collide_block = 
				((ball_y - BALL_HEIGHT) <= (block_y + BLOCK_HEIGHT)) ||
				((ball_y + BALL_HEIGHT) >= block_y) ||
				((ball_x + BALL_WIDTH) >= block_x) ||
				((ball_x - BALL_WIDTH) <= block_x + BLOCK_WIDTH);
		end
	endfunction

	// x_pos and y_pos are global variables for paddle position,
	// but we need to pass them in anyways because functions require inputs
	function collide_paddle;
		input [9:0] paddle_x;
		input [9:0] paddle_y;
		begin
			collide_paddle = 
				((ball_y - BALL_HEIGHT) <= (paddle_y + PADDLE_HEIGHT)) ||
				((ball_y + BALL_HEIGHT) >= paddle_y - PADDLE_HEIGHT) ||
				((ball_x + BALL_WIDTH) >= paddle_x - PADDLE_WIDTH) ||
				((ball_x - BALL_WIDTH) <= paddle_x + PADDLE_WIDTH);
		end
	endfunction
	
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
