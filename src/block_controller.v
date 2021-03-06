`timescale 1ns / 1ps

module block_controller(
	input fastClk,
	input clk, //this clock must be a slow enough clock to view the changing positions of the objects
	input bright,
	input rst,
	input start,
	input left, input right,
	input [9:0] hCount, vCount,
	output reg [11:0] rgb,
	output reg [11:0] background,
	output reg [3:0] score_ones,
	output reg [3:0] score_tens,
	output reg [3:0] lives
   ); 	
	wire paddle_fill;
	wire background_fill;
	wire ball_fill;

	integer i;
	integer j;
	
	//these two values dictate the center of the paddle, incrementing and decrementing them leads the block to move in certain directions
	reg [9:0] paddle_x, paddle_y;
	reg [9:0] ball_x, ball_y;
	
	// colors
	localparam
	RED			= 12'b1111_0000_0000,
	WHITE		= 12'b1111_1111_1111,
	PINK		= 12'b1111_0000_1111,
	BLUE		= 12'b0000_0000_1111,
	LIGHT_BLUE	= 12'b0000_1111_1111,
	BRIGHT_GREEN= 12'b0000_1111_0000,
	BLACK		= 12'b0000_0000_0000,
	PURPLE		= 12'b1000_0010_1111;
	
	// dimensions
	localparam
	LEFT_WALL_X = 245,		// supposed to be 144
	RIGHT_WALL_X = 790,		// maybe 783?
	CEILING_Y = 35,
	FLOOR_Y = 515,
	BOTTOM_OF_GRID_Y = 160,
	BALL_WIDTH = 5,
	BALL_HEIGHT = 5,
	PADDLE_WIDTH = 25,
	PADDLE_HEIGHT = 5;

	integer BLOCK_WIDTH = (RIGHT_WALL_X - LEFT_WALL_X) / 12;
	integer BLOCK_HEIGHT = (BOTTOM_OF_GRID_Y - CEILING_Y) / 5;
	
	// array of blocks:
	// 21:12 = x position
	// 11:2 = y position
	// 1 = color (1 = pink, 0 = blue)
	// 0 = has been hit or not
	reg [21:0] blocks [0:4][0:11];
	wire blocks_fill [0:4][0:11];

	integer ball_x_direction;
	integer ball_y_direction;
	integer ball_speed;
	integer score;


	reg [1:0] flag;			// indicates which phase the game was last in
	reg [2:0] state;
	localparam
	INIT_0 = 3'b000, INIT_1 = 3'b001, PHASE_1 = 3'b010, PHASE_2 = 3'b011, PHASE_3 = 3'b100, WIN = 3'b101, LOSE = 3'b110;

	// for loop to initialize blocks_fill, which keeps track of whether hcount and vcount overlap with each block
	genvar block_i;
	genvar block_j;
	generate
	for(block_i = 0; block_i < 12; block_i = block_i + 1)
	begin														// i represents x pos
		for( block_j = 0; block_j < 5; block_j = block_j + 1)
		begin													// j represents y pos		
			assign blocks_fill[block_j][block_i] = 
				(vCount >= ((block_j*BLOCK_HEIGHT) + CEILING_Y)) &&						// top
				(vCount <= ((block_j*BLOCK_HEIGHT) + CEILING_Y + BLOCK_HEIGHT)) &&		// bottom
				(hCount >= ((block_i* BLOCK_WIDTH) + LEFT_WALL_X)) &&					// left
				(hCount <= ((block_i* BLOCK_WIDTH) + LEFT_WALL_X + BLOCK_WIDTH));		// right
		end
	end
	endgenerate

	/*when outputting the rgb value in an always block like this, make sure to include the if(~bright) statement, as this ensures the monitor 
	will output some data to every pixel and not just the images you are trying to display*/
	always@ (*) begin
    	if(~bright )					//force black if not inside the display area
		begin
			rgb = 12'b0000_0000_0000;
		end
		else if (state == LOSE)
		begin
			rgb = RED;
		end
		else if (state == WIN)
		begin
			rgb = BRIGHT_GREEN;
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
					if(blocks_fill[j][i] == 1)			// hcount and vcount are on top of the block
					begin
						if(blocks[j][i][0] == 1)		// if block has been hit
						begin
							rgb=WHITE;					//set rgb to background
						end
						else							//block has not been hit
						begin
							if(blocks[j][i][1] == 1)	// alternating block colors
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
		else											// background fill (hcount and vcount are below the blocks)
		begin
			rgb = WHITE;
		end
	end
	
	assign paddle_fill=vCount>=(paddle_y-5) && vCount<=(paddle_y+5) && hCount>=(paddle_x-25) && hCount<=(paddle_x+25);
	assign background_fill= vCount>=(BOTTOM_OF_GRID_Y);
	assign ball_fill=vCount>=(ball_y-5) && vCount<=(ball_y+5) && hCount>=(ball_x-5) && hCount<=(ball_x+5);


	always@(posedge clk, posedge rst) 
	begin
		if(rst)
		begin 
			state <= INIT_0;

			score_ones <= 4'bx;
			score_tens <= 4'bx;
			lives <= 4'bx;
			// score_ones <= 0;
			// score_tens <= 0;
			// lives <= 3;

			// paddle
			paddle_x <= 450;
			paddle_y <= 500;

			// ball
			ball_x <= 9'bx;
			ball_y <= 9'bx;

			flag <= 2'bx;
			
			// initialize blocks
			for(i = 0; i < 12; i = i + 1)
			begin																// i represents x pos
				for( j = 0; j < 5; j = j + 1 )
				begin: block_init												// j represents y pos	
					// set block coordinates								
					blocks[j][i][21:12] <= i*BLOCK_WIDTH + LEFT_WALL_X;			// x pos
					blocks[j][i][11:2] <= j*BLOCK_HEIGHT + CEILING_Y;			// y pos

					// set block color
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

		end
		else
		begin

			case(state)
				INIT_0:
				begin
					// data transitions
					score_ones <= 0;
					score_tens <= 0;
					lives <= 3;
					ball_speed <= 0;
					// init direction to southeast (down to the right)
					ball_x_direction <= 1;
					ball_y_direction <= 1;
					ball_x <= 480;
					ball_y <= 200;

					// data transitions
					if (start)
						state <= PHASE_1;
				end

				PHASE_1:
				begin
					// data transitions
					ball_speed <= 1;
					flag <= 0;

					// state transitions
					if (score_tens == 2)
						state <= PHASE_2;
				end

				PHASE_2:
				begin
					// data transitions
					ball_speed <= 2;
					flag <= 1;

					// state transitions
					if (score_tens == 4)
						state <= PHASE_3;
				end

				PHASE_3:
				begin
					// data transitions
					ball_speed <= 3;
					flag <= 1;

					// state transitions
					if (score_tens == 6)
						state <= WIN;
				end

				INIT_1:
				begin
					// data transitions
					ball_speed <= 0;
					ball_x <= 480;
					ball_y <= 200;

					// state transitions
					if (start && (flag == 0))
						state <= PHASE_1;
					else if (start && (flag == 1))
						state <= PHASE_2;
					else if (start && (flag == 2))
						state <= PHASE_3;
				end

				WIN:
				begin
					if (rst)
						state <= INIT_0;
				end

				LOSE:
				begin
					if (rst)
						state <= INIT_0;
				end
		
			endcase
			
		/* Note that the top left of the screen does NOT correlate to vCount=0 and hCount=0. The display_controller.v file has the 
			synchronizing pulses for both the horizontal sync and the vertical sync begin at vcount=0 and hcount=0. Recall that after 
			the length of the pulse, there is also a short period called the back porch before the display area begins. So effectively, 
			the top left corner corresponds to (hcount,vcount)~(144,35). Which means with a 640x480 resolution, the bottom right corner 
			corresponds to ~(783,515).  
		*/
			if(right) begin
				paddle_x<=paddle_x+2; //change the amount you increment to make the speed faster 
				if(paddle_x==800) //these are rough values to attempt looping around, you can fine-tune them to make it more accurate- refer to the block comment above
					paddle_x<=800;		// if wrapping, set to 150
			end
			else if(left) begin
				paddle_x<=paddle_x-2;
				if(paddle_x==150)
					paddle_x<=150;		// if wrapping, set paddle_x to 800
			end

			if (collide_paddle(paddle_x, paddle_y))							// paddle collision
			begin
				ball_y_direction = -ball_y_direction;						// reverse ball's y direction
			end
			else if (ball_x >= RIGHT_WALL_X || ball_x <= LEFT_WALL_X)		// side wall collision
			begin
				ball_x_direction = -ball_x_direction;
			end
			else if (ball_y <= CEILING_Y)									// ceiling collision
			begin
				ball_y_direction = -ball_y_direction;
			end

			if ((ball_y - CEILING_Y) < (BLOCK_HEIGHT*5))		// ball's location is in range of block grid
			begin
				if (~blocks[(ball_y - CEILING_Y)/BLOCK_HEIGHT][(ball_x-LEFT_WALL_X)/BLOCK_WIDTH][0])	//block has not already been hit
				begin
					blocks[(ball_y - CEILING_Y)/BLOCK_HEIGHT][(ball_x-LEFT_WALL_X)/BLOCK_WIDTH][0] <= 1;	// set block to hit
					ball_y_direction <= -ball_y_direction;																	// reverse ball's y direction
				end
			end

			score_ones <= score % 10;
			score_tens <= score / 10;



			if (state == PHASE_1 || state == PHASE_2 || state == PHASE_3)
			begin
				if (ball_y >= FLOOR_Y)
					lives <= lives - 1;

				if ((ball_y >= FLOOR_Y) && (lives > 1))
					state <= INIT_1;
				if ((ball_y >= FLOOR_Y) && (lives <= 1))
					state <= LOSE;
				
				ball_x <= ball_x + ball_x_direction*ball_speed;
				ball_y <= ball_y + ball_y_direction*ball_speed;
			end

		end
	end
	always @ (*)
	begin
		score = 0;
		//increment score if block has been hit
		for (i = 0; i < 5; i = i + 1)
		begin
			for (j = 0; j < 12; j = j + 1)
			begin
				score = score + blocks[i][j][0];
			end

		end
	end


	// ball collision functions

	function collide_block;
		input [9:0] block_x;
		input [9:0] block_y;
		begin
			collide_block = 
				((ball_y - BALL_HEIGHT) <= (block_y + BLOCK_HEIGHT)) &&
				((ball_y + BALL_HEIGHT) >= block_y) &&
				((ball_x + BALL_WIDTH) >= block_x) &&
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
				((ball_y + BALL_HEIGHT) >= paddle_y - PADDLE_HEIGHT) &&
				((ball_x + BALL_WIDTH) >= paddle_x - PADDLE_WIDTH) &&
				((ball_x - BALL_WIDTH) <= paddle_x + PADDLE_WIDTH);
		end
	endfunction
	
	
endmodule
