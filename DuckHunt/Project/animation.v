// Etch-and-sketch

module animation
	(
		CLOCK_50,						//	On Board 50 MHz
		KEY,							//	Push Button[3:0]
		SW,								//	DPDT Switch[17:0]
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK,						//	VGA BLANK
		VGA_SYNC,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input				CLOCK_50;				//	50 MHz
	input	   [3:0]	KEY;					//	Button[3:0]
	input	  [17:0]	SW;						//	Switches[0:0]
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK;				//	VGA BLANK
	output			VGA_SYNC;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	wire resetn;
	assign resetn = ~SW[1];
	
	
	
	//Declaring Ports
	
	wire [2:0] color;
	wire [2:0]DuckColor;
	wire [2:0]colorBackground;
	wire [2:0]colorTarget;
	wire [2:0]colorFallingDuck;
	
	
	wire [7:0] x;
	wire [6:0] y;
	wire [2:0]Ynext, yCurrent;
	wire [7:0]intialInputX;
	wire [6:0]intialInputY;
	
	wire start;
	wire enable;
	
	wire [7:0]inputX;
	wire [6:0]inputY;
	
	wire kill;
	assign kill = SW[0];
	
	wire [9:0]address;
	wire [14:0]addressBackground;
	
	assign intialInputX = SW[7:0];
	assign intialInputY = SW[14:8];
	
	wire up, down, left, right;
	assign up = ~KEY[0];
	assign down = ~KEY[1];
	assign right = ~KEY[2];
	assign left = ~KEY[3];
	
	wire startGame;
	assign startGame = SW[17];
	
	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(color),
			.x(x),
			.y(y),
			.plot(start),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK),
			.VGA_SYNC(VGA_SYNC),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "Welcome1";
			
	// Put your code here. Your code should produce signals x,y,color and writeEn
	// for the VGA controller, in addition to any other functionality your design may require.
	
	wire [2:0]colorBackgroundDUCK;
	
	wire [7:0]sizeX, finalX;
	wire [6:0]sizeY, finalY;
	
	
	DuckROM1	DuckROM1_inst (address + 2, CLOCK_50, DuckColor);
	BackgroundROM	BackgroundROM_inst (addressBackground /*160*y+x*/, CLOCK_50, colorBackground);
	TargetROM	TargetROM_inst (address + 2, CLOCK_50, colorTarget);
	FallingDuckROM	FallingDuckROM_inst (address + 2, CLOCK_50, colorFallingDuck);

	
	moveInstances stage5(inputX, inputY, DuckColor, colorBackground, color, colorTarget, colorFallingDuck, CLOCK_50, enable, up, down, left, right, sizeX, sizeY, kill, finalX, finalY, startGame);
	
	NextState stage2(Ynext, yCurrent, CLOCK_50, enable, start, finalX, finalY, x, y);
	flipflop stage3(resetn, yCurrent, Ynext, CLOCK_50);
	changeCoordinate stage4(x, y, yCurrent, CLOCK_50, inputX, inputY, address, addressBackground, finalX, finalY);
	
	
endmodule


module moveInstances(inputX, inputY, DuckColor, colorBackground, color, colorTarget, colorFallingDuck, CLOCK_50, enable, up, down, left, right, sizeX, sizeY, kill, finalX, finalY, startGame);
	
	input up, down, left, right;
	input kill, startGame;
	
	output reg [7:0]inputX;
	output reg [6:0]inputY;
	
	input [2:0]DuckColor, colorBackground, colorTarget, colorFallingDuck;
	output reg [2:0]color;
	
	input CLOCK_50;
	output reg enable;
	
	reg resetCYCLE;
	
	parameter objectCount = 1;
	
	wire [25:0]CYCLES;
	
	main_clock C0 (CLOCK_50, 1, CYCLES, currentCYCLE, resetCYCLE);
	defparam C0.n = 26;
	defparam C0.k = 50000000;
	 
	reg firstTime = 1;
	 
	reg [3:0]ID;
	 
	//Duck 1 declaration
	parameter Duck_1_initialInputX = 0;
	parameter Duck_1_initialInputY = 0;
	
	reg [7:0]Duck_1_inputX;
	reg [6:0]Duck_1_inputY;
	
	reg Duck_1_alive = 1;
	reg Duck_1_falling = 0;
	reg Duck_1_dead = 0;
	
	
	//Duck 2 declaration
	parameter Duck_2_initialInputX = 0;
	parameter [6:0]Duck_2_initialInputY = 60;
	
	reg [7:0]Duck_2_inputX;
	reg [6:0]Duck_2_inputY;
	
	reg Duck_2_alive = 1;
	reg Duck_2_falling = 0;
	reg Duck_2_dead = 0;
	
	//Duck 3 declaration
	
	parameter Duck_3_initialInputX = 0;
	parameter [6:0]Duck_3_initialInputY = 0;
	
	reg [7:0]Duck_3_inputX;
	reg [6:0]Duck_3_inputY;
	
	reg Duck_3_alive = 0;
	reg Duck_3_falling = 0;
	reg Duck_3_dead = 1;
	
	
	//Target declaration
	parameter Target_initialInputX = 75;
	parameter [6:0]Target_initialInputY = 55;
	
	reg [7:0]Target_inputX;
	reg [6:0]Target_inputY;
	
	reg proceed = 0;
	
	wire [25:0]eraseCount = sizeX * sizeY + 100;
	parameter movementsPerSec = 48;
	parameter speed = 50000000/movementsPerSec * objectCount;
	reg [25:0]currentCYCLE = 0;
	 
	 
	 
	 always @ (posedge CLOCK_50)
	  begin
		if(startGame == 1 && proceed == 0)
		begin
			if(CYCLES <= 1)
			begin
			inputX = 0;
			inputY = 0;
			enable = 1;
			end
			else
				enable = 0;
			
			color = colorBackground;
			
			if(CYCLES == 20000)
			begin
				enable = 0;
				proceed = 1;
				resetCYCLE = 1;
			end
		end
		if(proceed == 1)
		begin
		if(firstTime == 1)
		begin
			firstTime = 0;
			proceed = 0;
			
			Target_inputX = Target_initialInputX;
			Target_inputY = Target_initialInputY; 
			
			Duck_1_inputX = Duck_1_initialInputX;
			Duck_1_inputY = Duck_1_initialInputY;
			
			Duck_2_inputX = Duck_2_initialInputX;
			Duck_2_inputY = Duck_2_initialInputY;
			
			Duck_3_inputX = Duck_3_initialInputX;
			Duck_3_inputY = Duck_3_initialInputY;
			
			ID = 1;
			inputX = Duck_1_initialInputX;
			inputY = Duck_1_initialInputY;
		end
		if((CYCLES >= currentCYCLE && CYCLES <= currentCYCLE + 1) || (CYCLES >= currentCYCLE + eraseCount && CYCLES <= currentCYCLE + eraseCount + 1))
			enable = 1;
		else
			enable = 0;
		
		resetCYCLE = 0;
		
		
		//Kill computation
		
		//Duck 1
		if(ID == 1 && Duck_1_alive == 1)
			if(Target_inputX + 5 >= Duck_1_inputX && Target_inputX + 5 <= Duck_1_inputX  + 34)
				if(Target_inputY + 5 >= Duck_1_inputY && Target_inputY + 5 <= Duck_1_inputY  + 23)
					if(kill == 1 && Duck_1_inputX < 159 - 34)
					begin
						Duck_1_alive = 0;
						Duck_1_falling = 1;
						
						//Instantiating third duck
						Duck_3_alive = 1;
						Duck_3_dead = 0;
					end
		if(ID == 1 && Duck_1_falling == 1)
			if(inputY > 159 - 34)
			begin
				Duck_1_falling = 0;
				Duck_1_dead = 1;
			end
		if(ID == 1 && Duck_1_dead == 1)
		begin
			enable = 0;
			resetCYCLE = 1;
			ID = 2;
		end
		
		
		//Duck 2
		if(ID == 2 && Duck_2_alive == 1)
			if(Target_inputX + 5 >= Duck_2_inputX && Target_inputX + 5 <= Duck_2_inputX  + 34)
				if(Target_inputY + 5 >= Duck_2_inputY && Target_inputY + 5 <= Duck_2_inputY  + 23)
					if(kill == 1 && Duck_2_inputX < 159 - 34)
					begin
						Duck_2_alive = 0;
						Duck_2_falling = 1;
					end
		if(ID == 2 && Duck_2_falling == 1)
			if(inputY > 159 - 34)
			begin
				Duck_2_falling = 0;
				Duck_2_dead = 1;
			end
		if(ID == 2 && Duck_2_dead == 1)
		begin
			enable = 0;
			resetCYCLE = 1;
			ID = 0;
		end
		
		
		//Duck 3
		if(ID == 3 && Duck_3_alive == 1)
			if(Target_inputX + 5 >= Duck_3_inputX && Target_inputX + 5 <= Duck_3_inputX  + 34)
				if(Target_inputY + 5 >= Duck_3_inputY && Target_inputY + 5 <= Duck_3_inputY  + 23)
					if(kill == 1 && Duck_3_inputX < 159 - 34)
					begin
						Duck_3_alive = 0;
						Duck_3_falling = 1;
					end
		if(ID == 3 && Duck_3_falling == 1)
			if(inputY > 159 - 34)
			begin
				Duck_3_falling = 0;
				Duck_3_dead = 1;
			end
		if(ID == 3 && Duck_3_dead == 1)
		begin
			enable = 0;
			resetCYCLE = 1;
			ID = 0;
		end
	
	
		//Erase computation
	
		if(CYCLES == currentCYCLE)
		begin
			if(ID == 1)
			begin
				inputX = Duck_1_inputX;
				inputY = Duck_1_inputY;
			end
			else if(ID == 2)
			begin
				inputX = Duck_2_inputX;
				inputY = Duck_2_inputY;
			end
			else if(ID == 3)
			begin
				inputX = Duck_3_inputX;
				inputY = Duck_3_inputY;
			end
			else if(ID == 0)
			begin
				inputX = Target_inputX;
				inputY = Target_inputY;
			end
		end
		
		
		
		//Move computation
		
		if(CYCLES == currentCYCLE + eraseCount)
		begin	
		
			//Duck 1
			if(ID == 1)
			begin
				if(Duck_1_alive == 1)
				begin
					Duck_1_inputX = Duck_1_inputX  + 1;
				end
				else if(Duck_1_falling)
				begin
					Duck_1_inputY = Duck_1_inputY  + 1;
				end
				
				inputX = Duck_1_inputX;
				inputY = Duck_1_inputY;
			
			end
			
			//Duck 2
			else if(ID == 2)
			begin
				if(Duck_2_alive == 1)
				begin
					Duck_2_inputX = Duck_2_inputX  + 1;
				end
				else if(Duck_2_falling)
				begin
					Duck_2_inputY = Duck_2_inputY  + 1;
				end
				
				inputX = Duck_2_inputX;
				inputY = Duck_2_inputY;
			end
			
			//Duck 3
			else if(ID == 3)
			begin
				if(Duck_3_alive == 1)
				begin
					Duck_3_inputX = Duck_3_inputX  + 1;
				end
				else if(Duck_3_falling)
				begin
					Duck_3_inputY = Duck_3_inputY  + 1;
				end
				
				inputX = Duck_3_inputX;
				inputY = Duck_3_inputY;
			end
			
			
			//Target cursor
			else if(ID == 0)
			begin
				
				if(left == 1 && Target_inputX > 0)
				begin
					Target_inputX = Target_inputX - 1;
				end
				else if(right == 1 && Target_inputX < 159 - 10)
				begin	
					Target_inputX = Target_inputX + 1;
				end
				if(up == 1 && Target_inputY > 0)
				begin
					Target_inputY = Target_inputY - 1;
				end
				else if(down == 1 && Target_inputY < 119 - 9)
				begin
					Target_inputY = Target_inputY + 1;
				end
				
				inputX = Target_inputX;
				inputY = Target_inputY;
			end
		end
		
		
		//Color computation
		
		if(CYCLES < (currentCYCLE + eraseCount))
		begin
			color = colorBackground;
		end
		else if(CYCLES >= currentCYCLE + eraseCount)
		begin	

			//Duck 1
			if(ID == 1)
			begin
				if(inputX >= 159 - sizeX)
				begin
					color = colorBackground;
				end
				else if(Duck_1_alive == 1)
				begin
					if(DuckColor == 3'b001)
						color = colorBackground;
					else
						color = DuckColor;
				end
				else if(Duck_1_alive == 0 && Duck_1_falling == 1)
				begin
					if(colorFallingDuck == 3'b001)
						color = colorBackground;
					else
						color = colorFallingDuck;
				end
			end
				
			//Duck2
			if(ID == 2)
			begin
				if(inputX >= 159 - sizeX)
				begin
					color = colorBackground;
				end
				else if(Duck_2_alive == 1)
				begin
					if(DuckColor == 3'b001)
						color = colorBackground;
					else
						color = DuckColor;
				end
				else if(Duck_2_alive == 0 && Duck_2_falling == 1)
				begin
					if(colorFallingDuck == 3'b001)
						color = colorBackground;
					else
						color = colorFallingDuck;
				end
			end
			
			
			//Duck 3
			if(ID == 3)
			begin
				if(inputX >= 159 - sizeX)
				begin
					color = colorBackground;
				end
				else if(Duck_3_alive == 1)
				begin
					if(DuckColor == 3'b001)
						color = colorBackground;
					else
						color = DuckColor;
				end
				else if(Duck_3_alive == 0 && Duck_3_falling == 1)
				begin
					if(colorFallingDuck == 3'b001)
						color = colorBackground;
					else
						color = colorFallingDuck;
				end
			end
			
			
			//Target cursor
			if(ID == 0)
				color = colorTarget;
		end
			
		//Toggle objects computation
		
		if (CYCLES == (currentCYCLE + speed - 1))
		begin
			currentCYCLE = currentCYCLE + speed;
			
			if(ID == 1)
			begin
				ID = 2;
			end
			else if(ID == 2)
			begin
				ID = 3;
			end
			else if(ID == 3)
			begin
				ID = 0;
			end
			else if(ID == 0)
			begin
				ID = 1;
			end
		end

			
		//CYCLE counter reset computation
			
		if(CYCLES == 49999999)
			currentCYCLE = 0;
	end
	end
	
	
	//Final coordinates and size computation
	
	output reg [7:0]finalX;
	output reg [6:0]finalY;
	
	output reg [7:0]sizeX = 34;
	output reg [6:0]sizeY = 23;
	
	reg [7:0]backgroundSizeX = 160;
	reg [6:0]backgroundSizeY = 119;
	
	reg [7:0]duckSizeX = 34;
	reg [6:0]duckSizeY = 23;
	
	reg [7:0]targetSizeX = 10;
	reg [6:0]targetSizeY = 09;
	
	reg [7:0]fallingDuckSizeX = 34;
	reg [6:0]fallingDuckSizeY = 30;
	
	always@(enable)
	begin
		if(proceed == 0)
		begin
			sizeX = backgroundSizeX;
			sizeY = backgroundSizeY;
		end
		else if(ID == 1)
		begin
			sizeX = duckSizeX;
			sizeY = duckSizeY;
	
			if(Duck_1_falling == 1)
			begin
				sizeX = fallingDuckSizeX;
				sizeY = fallingDuckSizeY;
			end
		end
		else if(ID == 2)
		begin
			sizeX = duckSizeX;
			sizeY = duckSizeY;
		
			if(Duck_2_falling == 1)
			begin
				sizeX = fallingDuckSizeX;
				sizeY = fallingDuckSizeY;
			end
		end
		else if(ID == 3)
		begin
			sizeX = duckSizeX;
			sizeY = duckSizeY;
		
			if(Duck_3_falling == 1)
			begin
				sizeX = fallingDuckSizeX;
				sizeY = fallingDuckSizeY;
			end
		end
		
		else if(ID == 0)
		begin
			sizeX = targetSizeX;
			sizeY = targetSizeY;
		end
		
		if(inputX + sizeX <= 159)
			finalX = inputX + sizeX - 2;
		else
			finalX = 159;
		
		if(inputY + sizeY <= 119)
			finalY = inputY + sizeY;
		else
			finalY = 119;
	end
		
			
	
endmodule


module flipflop(reset, y, Y, CLOCK_50);
	input reset, CLOCK_50;
	output reg [2:0]y;
	input [2:0]Y;
	parameter [1:0]A = 'b00;
	
	always@(posedge CLOCK_50)
	begin
		if(!reset)
			y<=A;
		else
			y<=Y;
	end
endmodule

	
module NextState(Y, yCurrent, CLOCK_50, enable, start, finalX, finalY, x, y);
	output reg [1:0]Y;
	inout reg [1:0]yCurrent;
	input CLOCK_50;
	input enable;
	output reg start;
	input [7:0]finalX, x;
	input [6:0]finalY, y;
	
	
	parameter [1:0]MOVE_X = 2'b00,
						MOVE_Y = 2'b01,
						DELAY = 2'b10,
						IDLE = 2'b11;
	
	reg counter = 1;
	
	always@(yCurrent,x,y,enable)
	begin
	case(yCurrent)
		MOVE_X:
			if(x < finalX && y <= finalY)
				Y=MOVE_X;
			else if(x >= finalX && y < finalY)
				Y=MOVE_Y;
			else if(y > finalY)
				Y=IDLE;
		MOVE_Y:
			Y=MOVE_X;
		DELAY: 
			begin
				Y=MOVE_X;
			end
		IDLE:
			if(enable)
			begin
				Y=DELAY;
				start <= 1;
			end
			else
			begin	
				Y=IDLE;
				start <= 0;
			end
	endcase
	end
						
endmodule


module changeCoordinate(x, y, yCurrent, CLOCK_50, inputX, inputY, address, addressBackground, finalX, finalY);
	input [7:0]inputX, finalX;
	input [6:0]inputY, finalY;
	output reg [7:0]x;
	output reg [6:0]y;
	input [1:0]yCurrent;
	input CLOCK_50;
	output reg [9:0]address;
	output reg [14:0]addressBackground;
	
	parameter [1:0]MOVE_X = 2'b00,
						MOVE_Y = 2'b01,
						DELAY = 2'b10,
						IDLE = 2'b11;
						
	always@(posedge CLOCK_50)
	begin
	case(yCurrent)
		MOVE_X:
			begin
			x = x + 1;
			address = address + 1;
			//address = 34*(y-inputY)+ x-inputX;
			if(x == finalX && y < finalY)
				addressBackground = 160*(y+1) + inputX - 1;
			else 
				addressBackground = 160*(y) + x + 1;
			end
		MOVE_Y:	
			begin
			x = inputX;
			y = y + 1;
			addressBackground = 160*(y) + x + 1;
			address = address + 1;
			//address = 34*(y-inputY)+ x-inputX;
			end
		IDLE:
			begin
			x = inputX;
			y = inputY;
			addressBackground = 160*y + x;
			address = 0;
			end
			endcase
	end
	
endmodule

module main_clock(clock, reset_n, CYCLES, currentCYCLE, resetCYCLE);
  parameter n = 4;
  parameter k = 16;
  input clock, reset_n, resetCYCLE;
  output [n-1:0] CYCLES;
  input [n-1:0]currentCYCLE;
  reg [n-1:0] CYCLES;
  always @(posedge clock or negedge reset_n)
  begin
    if (~reset_n)
      CYCLES <= 'd0;
	else if(resetCYCLE)
		CYCLES <= currentCYCLE;
    else begin
      CYCLES <= CYCLES + 1'b1;
      if (CYCLES == k-1)
        CYCLES <= 'd0;
    end
  end
endmodule
	