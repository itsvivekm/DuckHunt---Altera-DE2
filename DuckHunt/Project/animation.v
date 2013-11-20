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
	//assign enable = ~KEY[1];
	
	
	//Declaring Ports
	
	wire [2:0] color;
	wire [2:0]DuckColor;
	wire [2:0]colorBackground;
	wire [7:0] x;
	wire [6:0] y;
	wire [2:0]Ynext, yCurrent;
	wire [7:0]intialInputX;
	wire [6:0]intialInputY;
	
	wire start;
	wire enable;
	
	wire [7:0]inputX;
	wire [6:0]inputY;
	
	
	reg [7:0]finalX;
	reg [6:0]finalY;
	
	wire [9:0]address;
	wire [14:0]addressBackground;
	
	assign intialInputX = SW[7:0];
	assign intialInputY = SW[14:8];
	//assign color = SW[17:15];
	
	
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
	
	BackgroundROM	BackgroundROM_inst (160*y+x, CLOCK_50, colorBackground);
	
	parameter sizeX = 34;
	parameter sizeY = 23;
	

	always@(enable)
	begin
	if(inputX + sizeX <= 159)
		finalX = inputX + sizeX - 2;
	else
		finalX = 159;
	
	if(inputY + sizeY <= 119)
		finalY = inputY + sizeY;
	else
		finalY = 119;
	end

	
	DuckROM1	DuckROM1_inst (address + 2, CLOCK_50, DuckColor);

	
	moveInstances stage5(inputX, inputY, DuckColor, colorBackground, color, CLOCK_50, enable);
	defparam stage5.sizeX = sizeX;
	defparam stage5.sizeY = sizeY;
	
	NextState stage2(Ynext, yCurrent, CLOCK_50, enable, start, finalX, finalY, x, y);
	flipflop stage3(resetn, yCurrent, Ynext, CLOCK_50);
	changeCoordinate stage4(x, y, yCurrent, CLOCK_50, inputX, inputY, address);
	
	
endmodule


module moveInstances(inputX, inputY, DuckColor, colorBackground, color, CLOCK_50, enable);
	
	parameter sizeX;
	parameter sizeY;
	
	
	
	output reg [7:0]inputX;
	output reg [6:0]inputY;
	
	input [2:0]DuckColor, colorBackground;
	output reg [2:0]color;
	
	input CLOCK_50;
	output reg enable;
	
	
	parameter objectCount = 1;
	
	wire [25:0]CYCLES;
	
	main_clock C0 (CLOCK_50, 1, CYCLES);
	defparam C0.n = 26;
	defparam C0.k = 50000000;
	 
	reg firstTime = 1;
	 
	 reg [3:0]ID;
	 
	//Duck 1 declaration
	parameter Duck_1_initialInputX = 0;
	parameter Duck_1_initialInputY = 0;
	
	reg [7:0]Duck_1_inputX;
	reg [6:0]Duck_1_inputY;
	
	
	//Duck 2 declaration
	parameter Duck_2_initialInputX = 0;
	parameter [6:0]Duck_2_initialInputY = 60;
	
	reg [7:0]Duck_2_inputX;
	reg [6:0]Duck_2_inputY;
	
	 
	parameter eraseCount = sizeX * sizeY + 100;
	parameter movementsPerSec = 32;
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
			
			ID = 1;
			inputX = Duck_1_initialInputX;
			inputY = Duck_1_initialInputY;
		end
		if((CYCLES >= currentCYCLE) && CYCLES <= (currentCYCLE + eraseCount + 5))
			enable = 1;
		else
			enable = 0;
		
		/*
		if(CYCLES == currentCYCLE + 1)
			if(ID == 1)
				inputX = Duck_1_inputX - 1;
			else if(ID == 2)
				inputX = Duck_2_inputX - 1;
		else if(CYCLES == currentCYCLE + eraseCount + 1)
			if(ID == 1)
			begin
				//ID = 2;
				inputX = Duck_1_inputX + 1;
			end
			else if(ID == 2)
			begin
				//ID = 1;
				inputX = Duck_2_inputX + 3;
			end
		*/

		if(CYCLES <= (currentCYCLE + eraseCount))
		begin
			color = colorBackground;
		end
		else if(DuckColor == 3'b001)
			color = colorBackground;
		else
			color = DuckColor;
		
			
		
		if(CYCLES >= currentCYCLE + eraseCount)
			if(inputX >= 159 - sizeX)
			begin
				//enable = 0;
				color = colorBackground;
			end
			
		if (CYCLES == (currentCYCLE + speed - 1))
		begin
			currentCYCLE = currentCYCLE + speed;
			
			if(ID == 1)
			begin
				ID = 2;
				Duck_1_inputX  = Duck_1_inputX  + 1;
				inputX = Duck_1_inputX;
				inputY = Duck_1_inputY;
			end
			
			else if(ID == 2)
			begin
				ID = 1;
				Duck_2_inputX  = Duck_2_inputX  + 1;
				//Duck_2_inputY  = Duck_2_inputY  + 1;
				inputX = Duck_2_inputX;
				inputY = Duck_2_inputY;
			end
		end
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
	inout reg [1:0]yCurrent = IDLE;
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


module changeCoordinate(x, y, yCurrent, CLOCK_50, inputX, inputY, address);
	input [7:0]inputX;
	input [6:0]inputY;
	output reg [7:0]x;
	output reg [6:0]y;
	input [1:0]yCurrent;
	input CLOCK_50;
	output reg [9:0]address;
	
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
			end
		MOVE_Y:	
			begin
			x = inputX;
			y = y + 1;
			address = address + 1;
			end
		IDLE:
			begin
			x = inputX;
			y = inputY;
			address = 0;
			end
			endcase
	end
	
endmodule

module main_clock(clock, reset_n, Q);
  parameter n = 4;
  parameter k = 16;
  input clock, reset_n;
  output [n-1:0] Q;
  reg [n-1:0] Q;
  always @(posedge clock or negedge reset_n)
  begin
    if (~reset_n)
      Q <= 'd0;
    else begin
      Q <= Q + 1'b1;
      if (Q == k-1)
        Q <= 'd0;
    end
  end
endmodule
	