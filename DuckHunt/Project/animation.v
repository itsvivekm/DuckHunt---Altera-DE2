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
	
	// Create the color, x, y and writeEn wires that are inputs to the controller.

	reg [2:0] color;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;
	
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
		defparam VGA.BACKGROUND_IMAGE = "";
			
	// Put your code here. Your code should produce signals x,y,color and writeEn
	// for the VGA controller, in addition to any other functionality your design may require.
	
	
	wire [2:0]Ynext, yCurrent;
	wire [7:0]intialInputX;
	wire [6:0]intialInputY;
	
	
	
	wire start;
	
	reg [7:0]finalX;
	reg [6:0]finalY;
	
	wire [9:0]address;
	
	assign intialInputX = SW[7:0];
	assign intialInputY = SW[14:8];

	always@(enable)
	begin
	if(inputX + 10 <= 159)
		finalX = inputX + 10;
	else
		finalX = 159;
	
	if(inputY + 10 <= 119)
		finalY = inputY + 10;
	else
		finalY = 119;
	end

	
	//DuckROM1	DuckROM1_inst (address, CLOCK_50, color);

	
	NextState stage2(Ynext, yCurrent, CLOCK_50, enable, start, finalX, finalY, x, y);
	flipflop stage3(resetn, yCurrent, Ynext, CLOCK_50);
	changeCoordinate stage4(x, y, yCurrent, CLOCK_50, inputX, inputY, address);
	
	reg enable;
	wire [25:0]CYCLES;
	
	counter_modk C0 (CLOCK_50, 1, CYCLES);
	defparam C0.n = 26;
	defparam C0.k = 50000000;
	 
	reg [7:0]inputX;
	reg [6:0]inputY;
	reg firstTime = 1;
	 
	 parameter movementsPerSec = 35;
		parameter speed = 50000000/movementsPerSec;
	  reg [25:0]currentCYCLE = 0;
	 
	 always @ (posedge CLOCK_50)
	  begin
		if(firstTime == 1)
		begin
			firstTime = 0;
			inputX = intialInputX;
			inputY = intialInputY;
		end
	  	if((CYCLES >= currentCYCLE) && CYCLES <= (currentCYCLE + speed - 5))
			enable = 1;
		else
			enable = 0;
		/*
		if(CYCLES == currentCYCLE)
		begin
			inputX = inputX + 1;
			//inputY = inputY + 1;
			//currentCYCLE = currentCYCLE + speed;
		end
		*/
		if(CYCLES >= (currentCYCLE + speed - 140))
		begin
			color = 3'b000;
			//inputY = inputY + 1;
		end
		else
			color = 3'b011;
		if (CYCLES == (currentCYCLE + speed - 1))
		begin
			currentCYCLE = currentCYCLE + speed;
			inputX = inputX + 1;
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
	inout reg [1:0]yCurrent = D;
	input CLOCK_50;
	input enable;
	output reg start;
	input [7:0]finalX, x;
	input [6:0]finalY, y;
	
	
	parameter [1:0]A = 2'b00,
						B = 2'b01,
						C = 2'b10,
						D = 2'b11;
						
	always@(yCurrent,x,y,enable)
	begin
	case(yCurrent)
		A:
			if(x < finalX && y <= finalY)
				Y=A;
			else if(x >= finalX && y < finalY)
				Y=B;
			else if(y > finalY)
				Y=D;
		B:
			Y=A;
		D:
			if(enable)
			begin
				Y=A;
				start <= 1;
			end
			else
			begin	
				Y=D;
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
	
	parameter [1:0]A = 2'b00,
						B = 2'b01,
						C = 2'b10,
						D = 2'b11;
						
	always@(posedge CLOCK_50)
	begin
	case(yCurrent)
		A:
			begin
			x = x + 1;
			address = address + 1;
			end
		B:	
			begin
			x = inputX;
			y = y + 1;
			address = address + 1;
			end
		D:
			begin
			x = inputX;
			y = inputY;
			address = 0;
			end
		/*
		default:
			begin
			x = inputX;
			y = inputY;
			end
		*/
	endcase
	end
						
endmodule

module counter_modk(clock, reset_n, Q);
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
	