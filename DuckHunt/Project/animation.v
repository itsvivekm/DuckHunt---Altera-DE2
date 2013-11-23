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
	assign resetn = KEY[0];
	
	
	
	//Declaring Ports
	
	wire [2:0] color;
	wire [2:0]DuckColor;
	wire [2:0]colorBackground;
	wire [2:0]colorTarget;
	
	
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
	assign kill = KEY[3];
	
	
	reg [7:0]finalX;
	reg [6:0]finalY;
	
	wire [9:0]address;
	wire [14:0]addressBackground;
	
	assign intialInputX = SW[7:0];
	assign intialInputY = SW[14:8];
	
	wire up, down, left, right;
	assign down = SW[0];
	assign up = SW[1];
	assign right = SW[2];
	assign left = SW[3];
	
	
	
	
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
		defparam VGA.BACKGROUND_IMAGE = "background2";
			
	// Put your code here. Your code should produce signals x,y,color and writeEn
	// for the VGA controller, in addition to any other functionality your design may require.
	
	wire [2:0]colorBackgroundDUCK;
	wire [3:0]ID;
	
	reg [7:0]sizeX = 34;
	reg [6:0]sizeY = 23;
	
	reg [7:0]duckSizeX = 34;
	reg [6:0]duckSizeY = 23;
	
	reg [7:0]targetSizeX = 10;
	reg [6:0]targetSizeY = 09;
	
	always@(enable)
	begin
		if(ID == 1 || ID == 2)
		begin
			sizeX = duckSizeX;
			sizeY = duckSizeY;
			if(inputX + sizeX <= 159)
				finalX = inputX + sizeX - 2;
			else
				finalX = 159;
			
			if(inputY + sizeY <= 119)
				finalY = inputY + sizeY;
			else
				finalY = 119;
		end
		else if(ID == 3)
		begin
			sizeX = targetSizeX;
			sizeY = targetSizeY;
			if(inputX + sizeX <= 159)
				finalX = inputX + sizeX - 2;
			else
				finalX = 159;
			
			if(inputY + sizeY <= 119)
				finalY = inputY + sizeY;
			else
				finalY = 119;
		end
	end
	
	DuckROM1	DuckROM1_inst (address + 2, CLOCK_50, DuckColor);
	BackgroundROM	BackgroundROM_inst (addressBackground /*160*y+x*/, CLOCK_50, colorBackground);
	TargetROM	TargetROM_inst (address + 2, CLOCK_50, colorTarget);
	
	
	
	moveInstances stage5(inputX, inputY, DuckColor, colorBackground, color, colorTarget, CLOCK_50, enable, up, down, left, right, ID, sizeX, sizeY, kill);
	//defparam stage5.sizeX = sizeX;
	//defparam stage5.sizeY = sizeY;
	
	NextState stage2(Ynext, yCurrent, CLOCK_50, enable, start, finalX, finalY, x, y);
	flipflop stage3(resetn, yCurrent, Ynext, CLOCK_50);
	changeCoordinate stage4(x, y, yCurrent, CLOCK_50, inputX, inputY, address, addressBackground, finalX, finalY);
	
	
endmodule


module moveInstances(inputX, inputY, DuckColor, colorBackground, color, colorTarget, CLOCK_50, enable, up, down, left, right, ID, sizeX, sizeY, kill);
	
	input [7:0]sizeX;
	input [6:0]sizeY;
	
	input up, down, left, right;
	
	input kill;
	
	output reg [7:0]inputX;
	output reg [6:0]inputY;
	
	input [2:0]DuckColor, colorBackground, colorTarget;
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
	 
	output reg [3:0]ID;
	 
	//Duck 1 declaration
	parameter Duck_1_initialInputX = 0;
	parameter Duck_1_initialInputY = 0;
	
	reg [7:0]Duck_1_inputX;
	reg [6:0]Duck_1_inputY;
	
	reg Duck_1_alive = 1;
	
	//Duck 2 declaration
	parameter Duck_2_initialInputX = 0;
	parameter [6:0]Duck_2_initialInputY = 90;
	
	reg [7:0]Duck_2_inputX;
	reg [6:0]Duck_2_inputY;
	
	//Target declaration
	parameter Target_initialInputX = 75;
	parameter [6:0]Target_initialInputY = 55;
	
	reg [7:0]Target_inputX;
	reg [6:0]Target_inputY;
	
	reg Duck_2_alive = 1;
	
	reg enterAgain;
	//sreg reverseErase = 0;
	
	wire [25:0]eraseCount = sizeX * sizeY + 100;
	parameter movementsPerSec = 48;
	parameter speed = 50000000/movementsPerSec * objectCount;
	reg [25:0]currentCYCLE = 0;
	 
	 always @ (posedge CLOCK_50)
	  begin
		if(firstTime == 1)
		begin
			firstTime = 0;
			Duck_1_inputX = Duck_1_initialInputX;
			Duck_1_inputY = Duck_1_initialInputY;
			Duck_2_inputX = Duck_2_initialInputX;
			Duck_2_inputY = Duck_2_initialInputY;
			Target_inputX = Target_initialInputX;
			Target_inputY = Target_initialInputY; 
			
			
			enterAgain = 1;
			ID = 1;
			inputX = Duck_1_initialInputX;
			inputY = Duck_1_initialInputY;
		end
		if((CYCLES >= currentCYCLE && CYCLES <= currentCYCLE + 1) || (CYCLES >= currentCYCLE + eraseCount && CYCLES <= currentCYCLE + eraseCount + 1))
			enable = 1;
		else
			enable = 0;
		
		resetCYCLE = 0;
		
		if(ID == 1 && Duck_1_alive == 1)
			if(Target_inputX + 5 >= Duck_1_inputX && Target_inputX + 5 <= Duck_1_inputX  + 34)
				if(Target_inputY + 5 >= Duck_1_inputY && Target_inputY + 5 <= Duck_1_inputY  + 23)
					if(kill == 1)
						Duck_1_alive = 0;
		if(ID == 2 && Duck_2_alive == 1)
			if(Target_inputX + 5 >= Duck_2_inputX && Target_inputX + 5 <= Duck_2_inputX  + 34)
				if(Target_inputY + 5 >= Duck_2_inputY && Target_inputY + 5 <= Duck_2_inputY  + 23)
					if(kill == 1)
						Duck_2_alive = 0;
		
		
		if(ID == 1 && Duck_1_alive == 0)
			begin
				enable = 0;
				resetCYCLE = 1;
				ID = 2;
			end
		if(ID == 2 && Duck_2_alive == 0)
		begin	
			enable = 0;
			resetCYCLE = 1;
			if(Duck_2_alive == 1)
				ID = 2;
			else
				ID = 3;
		end
		
		
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
				inputX = Target_inputX;
				inputY = Target_inputY;
			end
		end
		
		
		
	
		
		
		if(CYCLES == currentCYCLE + eraseCount)
		begin	
			if(ID == 1  && Duck_1_alive == 1)
			begin
				//ID = 2;
				Duck_1_inputX = Duck_1_inputX  + 1;
				inputX = Duck_1_inputX;
				inputY = Duck_1_inputY;
			end
			
			else if(ID == 2  && Duck_2_alive == 1)
			begin
				//ID = 3;
				Duck_2_inputX = Duck_2_inputX  + 1;
				Duck_2_inputY = Duck_2_inputY;
				inputX = Duck_2_inputX;
				inputY = Duck_2_inputY;
			end
			else if(ID == 3)
			begin
				//ID = 1;
				
				if(left == 1 && Target_inputX > 0)
				begin
					Target_inputX = Target_inputX - 1;
					//reverseErase = 1;
				end
				else if(right == 1 && Target_inputX < 159 - 10)
				begin	
					Target_inputX = Target_inputX + 1;
					//reverseErase = 0;
				end
				if(up == 1 && Target_inputY > 0)
				begin
					Target_inputY = Target_inputY - 1;
					//reverseErase = 1;
				end
				else if(down == 1 && Target_inputY < 119 - 9)
				begin
					Target_inputY = Target_inputY + 1;
					//reverseErase = 0;
				end
				
				inputX = Target_inputX;
				inputY = Target_inputY;
			end
		end
		
		if(CYCLES < (currentCYCLE + eraseCount))
		begin
			color = colorBackground;
		end
		else if(CYCLES >= currentCYCLE + eraseCount)
			

			if((ID == 1 || ID == 2) && inputX >= 159 - sizeX)
			begin
				//enable = 0;
				color = colorBackground;
			end
			
			else if((ID == 1 || ID == 2) && DuckColor == 3'b001)
				color = colorBackground;
			else if(ID == 1 || ID == 2)
				color = DuckColor;
			else if(ID == 3)
				color = colorTarget;
		
			
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
				ID = 1;
			end
		end

			
			
			
			/*
			if(ID == 1)
			begin
				ID = 2;
				Duck_1_inputX  = Duck_1_inputX  + 1;
				inputX = Duck_1_inputX;
				inputY = Duck_1_inputY;
			end
			
			else if(ID == 2)
			begin
				ID = 3;
				Duck_2_inputX  = Duck_2_inputX  + 1;
				//Duck_2_inputY  = Duck_2_inputY  + 1;
				inputX = Duck_2_inputX;
				inputY = Duck_2_inputY;
			end
			else if(ID == 3)
			begin
				ID = 1;
				
				if(left == 1 && Target_inputX > 0)
				begin
					Target_inputX = Target_inputX - 1;
					reverseErase = 1;
				end
				else if(right == 1 && Target_inputX < 159 - 34)
				begin	
					Target_inputX = Target_inputX + 1;
					reverseErase = 0;
				end
				if(up == 1 && Target_inputY > 0)
				begin
					Target_inputY = Target_inputY - 1;
					reverseErase = 1;
				end
				else if(down == 1 && Target_inputY < 119 - 23)
				begin
					Target_inputY = Target_inputY + 1;
					reverseErase = 0;
				end
				
				inputX = Target_inputX;
				inputY = Target_inputY;
			end
			*/
	
		if(CYCLES == 49999999)
			currentCYCLE = 0;
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
			if(x == inputX + finalX - inputX && y < inputY + finalY - inputY)
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
	