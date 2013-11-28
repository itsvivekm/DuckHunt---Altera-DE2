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
		VGA_B,   						//	VGA Blue[9:0]
		PS2_CLK,
		PS2_DAT,
		HEX7, HEX6, HEX5, HEX4, HEX3, HEX2
		,GPIO_0
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
	inout PS2_CLK;
	inout PS2_DAT;
	input [3:0]GPIO_0;
	
	output [0:6]HEX7, HEX6, HEX5, HEX4, HEX3, HEX2;
	
	wire resetn;
	assign resetn = ~SW[10];
	
	
	
	//Declaring Ports
	
	wire [2:0] color;
	wire [2:0]DuckColor;
	wire [2:0]colorBackground;
	wire [2:0]colorTarget;
	wire [2:0]colorFallingDuck;
	wire [2:0]colorEnd;	
	
	
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
	
	wire [7:0]last_data_received;
	wire	ps2_key_pressed;
	
	
	PS2_Demo keyboard(CLOCK_50, KEY, PS2_CLK, PS2_DAT, last_data_received, ps2_key_pressed);
	
	DuckROM1	DuckROM1_inst (address + 2, CLOCK_50, DuckColor);
	BackgroundROM	BackgroundROM_inst (addressBackground /*160*y+x*/, CLOCK_50, colorBackground);
	TargetROM	TargetROM_inst (address + 2, CLOCK_50, colorTarget);
	FallingDuckROM	FallingDuckROM_inst (address + 2, CLOCK_50, colorFallingDuck);
	EndGameROM	EndGameROM_inst (addressBackground, CLOCK_50, colorEnd);


	
	wire startTimer, stopTimer;
	
	moveInstances stage5(inputX, inputY, DuckColor, colorBackground, color, colorTarget, colorFallingDuck, colorEnd, CLOCK_50, KEY, SW, enable, sizeX, sizeY, finalX, finalY, startGame, last_data_received, ps2_key_pressed, startTimer, stopTimer, GPIO_0);
	
	NextState stage2(Ynext, yCurrent, CLOCK_50, enable, start, finalX, finalY, x, y);
	flipflop stage3(resetn, yCurrent, Ynext, CLOCK_50);
	changeCoordinate stage4(x, y, yCurrent, CLOCK_50, inputX, inputY, address, addressBackground, finalX, finalY);
	timer timerInstance(CLOCK_50, KEY, HEX7, HEX6, HEX5, HEX4, HEX3, HEX2, startTimer, stopTimer);
	
endmodule


module moveInstances(inputX, inputY, DuckColor, colorBackground, color, colorTarget, colorFallingDuck, colorEnd, CLOCK_50, KEY, SW, enable, sizeX, sizeY, finalX, finalY, startGame, last_data_received, ps2_key_pressed, startTimer, stopTimer, GPIO_0);
	
	reg up = 0, down = 0, left = 0, right = 0, kill = 0;
	input startGame;
	input [3:0]KEY;
	input [16:0]SW;
	
	input [3:0]GPIO_0;
	
	wire toggle;
	assign toggle = SW[16];
	
	wire toggleKEYsensor;
	assign toggleKEYsensor = SW[15];
	
	input [7:0]last_data_received;
	input ps2_key_pressed;
	
	always@(last_data_received, ps2_key_pressed)
	begin
	if(toggle == 0)
	begin
		up = 0;
		down = 0;
		left = 0;
		right = 0;
		
		if(last_data_received == 'b00011101)
		begin
			up = 1;
		end
		else if(last_data_received == 'b00011011)
		begin	
			down = 1;
		end
		else if(last_data_received == 'b00011100)
		begin
			left = 1;
		end
		else if(last_data_received == 'b00100011)
		begin
			right = 1;
		end
		
		if(last_data_received == 'b00101001)
		begin
			if(ps2_key_pressed == 1)
				kill = 1;
			else
				kill = 0;
		end
	end
	else
	begin
		
		//up = GPIO_0[2];
		//left = GPIO_0[1];
		//right = GPIO_0[0];
		if(toggleKEYsensor == 1)
		begin
		up = GPIO_0[1];
		down = GPIO_0[0];
		left = GPIO_0[2];
		right = GPIO_0[3];
		kill = ~KEY[0];
		end
		else
		begin
			up = ~KEY[0];
			down = ~KEY[1];
			left = ~KEY[2];
			right = ~KEY[3];
			kill = SW[0];
		end
	end
	end
	
	
	output reg [7:0]inputX;
	output reg [6:0]inputY;
	
	input [2:0]DuckColor, colorBackground, colorTarget, colorFallingDuck, colorEnd;
	output reg [2:0]color;
	
	input CLOCK_50;
	output reg enable, startTimer = 0, stopTimer = 0;
	
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
	parameter [6:0]Duck_2_initialInputY = 80;
	
	reg [7:0]Duck_2_inputX;
	reg [6:0]Duck_2_inputY;
	
	reg Duck_2_alive = 1;
	reg Duck_2_falling = 0;
	reg Duck_2_dead = 0;
	
	//Duck 3 declaration
	
	parameter Duck_3_initialInputX = 0;
	parameter [6:0]Duck_3_initialInputY = 30;
	
	reg [7:0]Duck_3_inputX;
	reg [6:0]Duck_3_inputY;
	
	reg Duck_3_alive = 0;
	reg Duck_3_falling = 0;
	reg Duck_3_dead = 1;
	
	
	//Duck 4 declaration
	
	parameter Duck_4_initialInputX = 0;
	parameter [6:0]Duck_4_initialInputY = 10;
	
	reg [7:0]Duck_4_inputX;
	reg [6:0]Duck_4_inputY;
	
	reg Duck_4_alive = 0;
	reg Duck_4_falling = 0;
	reg Duck_4_dead = 1;
	reg Duck_4_gone = 0;
	
	//Duck 5 declaration
	
	parameter Duck_5_initialInputX = 0;
	parameter [6:0]Duck_5_initialInputY = 90;
	
	reg [7:0]Duck_5_inputX;
	reg [6:0]Duck_5_inputY;
	
	reg Duck_5_alive = 0;
	reg Duck_5_falling = 0;
	reg Duck_5_dead = 1;
	reg Duck_5_gone = 0;
	
	
	//Duck 6 declaration
	
	parameter Duck_6_initialInputX = 0;
	parameter [6:0]Duck_6_initialInputY = 0;
	
	reg [7:0]Duck_6_inputX;
	reg [6:0]Duck_6_inputY;
	
	reg Duck_6_alive = 0;
	reg Duck_6_falling = 0;
	reg Duck_6_dead = 1;
	reg Duck_6_gone = 0;
	reg Duck_6_move1 = 0;
	reg Duck_6_move2 = 0;
	reg Duck_6_move3 = 0;
	reg Duck_6_move4 = 0;
	
	
	//Target declaration
	parameter Target_initialInputX = 75;
	parameter [6:0]Target_initialInputY = 55;
	
	reg [7:0]Target_inputX;
	reg [6:0]Target_inputY;
	
	reg proceed = 0;
	reg endGame = 0;
	
	
	//EndGame declaration
	parameter End_initialInputX = 0;
	parameter [6:0]End_initialInputY = 0;
	
	reg [7:0]End_inputX;
	reg [6:0]End_inputY;
	
	
	
	
	
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
		
		else if(proceed == 1)
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
			
			Duck_4_inputX = Duck_4_initialInputX;
			Duck_4_inputY = Duck_4_initialInputY;
			
			Duck_5_inputX = Duck_5_initialInputX;
			Duck_5_inputY = Duck_5_initialInputY;
			
			Duck_6_inputX = Duck_6_initialInputX;
			Duck_6_inputY = Duck_6_initialInputY;
			
			Duck_6_inputX = Duck_6_initialInputX;
			Duck_6_inputY = Duck_6_initialInputY;
			
			End_inputX = End_initialInputX;
			End_inputY = End_initialInputY;
	
			
			ID = 1;
			inputX = Duck_1_initialInputX;
			inputY = Duck_1_initialInputY;
		end
		
		
		if((CYCLES >= currentCYCLE && CYCLES <= currentCYCLE + 1) || (CYCLES >= currentCYCLE + eraseCount && CYCLES <= currentCYCLE + eraseCount + 1))
			enable = 1;
		else
			enable = 0;
		
		resetCYCLE = 0;
		startTimer = 1;
			
		
		
		
		
		
		//Kill computation
		
		//Duck 1
		if(ID == 1 && Duck_1_alive == 1)
			if(Target_inputX + 6 >= Duck_1_inputX && Target_inputX + 6 <= Duck_1_inputX  + 34)
				if(Target_inputY + 6 >= Duck_1_inputY && Target_inputY + 6 <= Duck_1_inputY  + 23)
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
			inputX = Duck_2_inputX;
			inputY = Duck_2_inputY;
		end
		
		
		//Duck 2
		if(ID == 2 && Duck_2_alive == 1)
			if(Target_inputX + 6 >= Duck_2_inputX && Target_inputX + 6 <= Duck_2_inputX  + 34)
				if(Target_inputY + 6 >= Duck_2_inputY && Target_inputY + 6 <= Duck_2_inputY  + 23)
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
			ID = 3;
			inputX = Duck_3_inputX;
			inputY = Duck_3_inputY;
		end
		
		
		//Duck 3
		if(ID == 3 && Duck_3_alive == 1)
			if(Target_inputX + 6 >= Duck_3_inputX && Target_inputX + 6 <= Duck_3_inputX  + 34)
				if(Target_inputY + 6 >= Duck_3_inputY && Target_inputY + 6 <= Duck_3_inputY  + 23)
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
			ID = 4;
			inputX = Duck_4_inputX;
			inputY = Duck_4_inputY;
		end
	
	
		//Instantiation for Duck 4 and Duck 5
		if(Duck_1_alive == 0 && Duck_2_alive == 0 && Duck_3_alive == 0 && Duck_4_alive == 0 && Duck_4_gone == 0 && Duck_5_alive == 0 && Duck_5_gone == 0)
		begin
			Duck_4_alive = 1;
			Duck_4_dead = 0;
			Duck_5_alive = 1;
			Duck_5_dead = 0;
		end
	
		//Duck 4
		if(ID == 4 && Duck_4_alive == 1)
			if(Target_inputX + 6 >= Duck_4_inputX && Target_inputX + 6 <= Duck_4_inputX  + 34)
				if(Target_inputY + 6 >= Duck_4_inputY && Target_inputY + 6 <= Duck_4_inputY  + 23)
					if(kill == 1 && Duck_4_inputX < 159 - 34)
					begin
						Duck_4_alive = 0;
						Duck_4_falling = 1;
						Duck_4_gone = 1;
					end
		if(ID == 4 && Duck_4_falling == 1)
			if(inputY > 159 - 34)
			begin
				Duck_4_falling = 0;
				Duck_4_dead = 1;
			end
		if(ID == 4 && Duck_4_dead == 1)
		begin
			enable = 0;
			resetCYCLE = 1;
			ID = 5;
			inputX = Duck_5_inputX;
			inputY = Duck_5_inputY;
		end
		
		//Duck 5
		if(ID == 5 && Duck_5_alive == 1)
			if(Target_inputX + 6 >= Duck_5_inputX && Target_inputX + 6 <= Duck_5_inputX  + 34)
				if(Target_inputY + 6 >= Duck_5_inputY && Target_inputY + 6 <= Duck_5_inputY  + 23)
					if(kill == 1 && Duck_5_inputX < 159 - 34)
					begin
						Duck_5_alive = 0;
						Duck_5_falling = 1;
						Duck_5_gone = 1;
					end
		if(ID == 5 && Duck_5_falling == 1)
			if(inputY > 159 - 34)
			begin
				Duck_5_falling = 0;
				Duck_5_dead = 1;
			end
		if(ID == 5 && Duck_5_dead == 1)
		begin
			enable = 0;
			resetCYCLE = 1;
			ID = 6;
			inputX = Duck_6_inputX;
			inputY = Duck_6_inputY;
		end
		
		
		//Instantiation for Duck 6
		if(Duck_1_dead == 1 && Duck_2_dead == 1 && Duck_3_dead == 1 && Duck_4_dead == 1 && Duck_5_dead == 1 && Duck_6_gone == 0)
		begin
			Duck_6_alive = 1;
			Duck_6_dead = 0;
		end
	
		
		//Duck 6
		if(ID == 6 && Duck_6_alive == 1)
			if(Target_inputX + 6 >= Duck_6_inputX && Target_inputX + 6 <= Duck_6_inputX  + 34)
				if(Target_inputY + 6 >= Duck_6_inputY && Target_inputY + 6 <= Duck_6_inputY  + 23)
					if(kill == 1 && Duck_6_inputX < 159 - 34)
					begin
						Duck_6_alive = 0;
						Duck_6_falling = 1;
						Duck_6_gone = 1;
					end
		if(ID == 6 && Duck_6_falling == 1)
			if(inputY > 159 - 34)
			begin
				Duck_6_falling = 0;
				Duck_6_dead = 1;
				stopTimer = 1;
				ID = 7;
			end
		if(ID == 6 && Duck_6_dead == 1)
		begin
			enable = 0;
			resetCYCLE = 1;
			ID = 0;
			inputX = Target_inputX;
			inputY = Target_inputY;
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
			else if(ID == 4)
			begin
				inputX = Duck_4_inputX;
				inputY = Duck_4_inputY;
			end
			else if(ID == 5)
			begin
				inputX = Duck_5_inputX;
				inputY = Duck_5_inputY;
			end
			else if(ID == 6)
			begin
				inputX = Duck_6_inputX;
				inputY = Duck_6_inputY;
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
					if(Duck_3_inputX <= 30)
						Duck_3_inputX = Duck_3_inputX  + 1;
					else if(Duck_3_inputY <= 45 && Duck_2_alive == 1)
					begin
						Duck_3_inputX = Duck_3_inputX  + 1;
						Duck_3_inputY = Duck_3_inputY + 1;
					end
					else if(Duck_3_inputY <= 80 && Duck_2_alive == 0)
					begin
						Duck_3_inputX = Duck_3_inputX  + 1;
						Duck_3_inputY = Duck_3_inputY + 1;
					end
					else if(Duck_3_inputX <= 155)
						Duck_3_inputX = Duck_3_inputX  + 1;
					else
					begin
						Duck_3_inputX = Duck_3_initialInputX;
						Duck_3_inputY = Duck_3_initialInputY;
					end
				end
					
				else if(Duck_3_falling)
				begin
					Duck_3_inputY = Duck_3_inputY  + 1;
				end
				
				inputX = Duck_3_inputX;
				inputY = Duck_3_inputY;
			end
			
			
			//Duck 4
			else if(ID == 4)
			begin
				if(Duck_4_alive == 1)
				begin
					if(Duck_4_inputX <= 100)
						Duck_4_inputX = Duck_4_inputX  + 1;
					else if(Duck_4_inputY <= 80)
					begin
						Duck_4_inputY = Duck_4_inputY + 1;
					end
					else if(Duck_4_inputX <= 159)
						Duck_4_inputX = Duck_4_inputX  + 1;
					else
					begin
						Duck_4_inputX = Duck_4_initialInputX;
						Duck_4_inputY = Duck_4_initialInputY;
					end
				end
					
				else if(Duck_4_falling)
				begin
					Duck_4_inputY = Duck_4_inputY  + 1;
				end
				
				inputX = Duck_4_inputX;
				inputY = Duck_4_inputY;
			end
			
			//Duck 5
			else if(ID == 5)
			begin
				if(Duck_5_alive == 1)
				begin
					if(Duck_5_inputX <= 50)
						Duck_5_inputX = Duck_5_inputX  + 1;
					else if(Duck_5_inputY >= 30)
					begin
						Duck_5_inputY = Duck_5_inputY - 1;
					end
					else if(Duck_5_inputX <= 159)
						Duck_5_inputX = Duck_5_inputX  + 1;
					else
					begin	
						Duck_5_inputX = Duck_5_initialInputX;
						Duck_5_inputY = Duck_5_initialInputY;
					end
				end
					
				else if(Duck_5_falling)
				begin
					Duck_5_inputY = Duck_5_inputY  + 1;
				end
				
				inputX = Duck_5_inputX;
				inputY = Duck_5_inputY;
			end
			
			//Duck 6
			else if(ID == 6)
			begin
				if(Duck_6_alive == 1)
				begin
				
					if(Duck_6_inputX <= 1 && Duck_6_inputY <= 90 && Duck_6_move1 == 0)
						Duck_6_inputY = Duck_6_inputY  + 1;
					else if(Duck_6_inputX <= 1 && Duck_6_inputY >= 5 && Duck_6_move2 == 0)
					begin
						Duck_6_move1 = 1;
						Duck_6_inputY = Duck_6_inputY - 2;
					end
					else if(Duck_6_inputX <= 60)
					begin
						Duck_6_move2 = 1;
						Duck_6_inputX = Duck_6_inputX  + 3;
					end
					else if(Duck_6_inputX <= 70 && Duck_6_inputY <= 55)
						Duck_6_inputY = Duck_6_inputY  + 2;
					else if(Duck_6_inputX <= 100 && Duck_6_inputY <= 60)
						Duck_6_inputX = Duck_6_inputX  + 3;
					else if(Duck_6_inputX <= 110 && Duck_6_inputY >= 10)
						Duck_6_inputY = Duck_6_inputY - 1;
					else if(Duck_6_inputX <= 155)
						Duck_6_inputX = Duck_6_inputX + 1;
					else
					begin
						Duck_6_move1 = 0;
						Duck_6_move2 = 0;
						Duck_6_inputX = Duck_6_initialInputX;
						Duck_6_inputY = Duck_6_initialInputY;
					end
				end
					
				else if(Duck_6_falling)
				begin
					Duck_6_inputY = Duck_6_inputY  + 1;
				end
				
				inputX = Duck_6_inputX;
				inputY = Duck_6_inputY;
			end
			
			
			//Target cursor
			else if(ID == 0)
			begin
				
				if(left == 1 && Target_inputX > 0)
				begin
					Target_inputX = Target_inputX - 1;
				end
				else if(right == 1 && Target_inputX < 159 - 12)
				begin	
					Target_inputX = Target_inputX + 1;
				end
				if(up == 1 && Target_inputY > 0)
				begin
					Target_inputY = Target_inputY - 1;
				end
				else if(down == 1 && Target_inputY < 119 - 11)
				begin
					Target_inputY = Target_inputY + 1;
				end
				
				inputX = Target_inputX;
				inputY = Target_inputY;
			end
			
			//EndGame
			else if(ID == 7)
			begin
				inputX = End_inputX;
				inputY = End_inputY;
			end
			
			
		end
		
		
		//Color computation
		
		if(CYCLES < (currentCYCLE + eraseCount))
		begin
			if(ID == 7)
				color = colorEnd;
			else
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
			
			
			//Duck 4
			if(ID == 4)
			begin
				if(inputX >= 159 - sizeX)
				begin
					color = colorBackground;
				end
				else if(Duck_4_alive == 1)
				begin
					if(DuckColor == 3'b001)
						color = colorBackground;
					else
						color = DuckColor;
				end
				else if(Duck_4_alive == 0 && Duck_4_falling == 1)
				begin
					if(colorFallingDuck == 3'b001)
						color = colorBackground;
					else
						color = colorFallingDuck;
				end
			end
			
			
			//Duck 5
			if(ID == 5)
			begin
				if(inputX >= 159 - sizeX)
				begin
					color = colorBackground;
				end
				else if(Duck_5_alive == 1)
				begin
					if(DuckColor == 3'b001)
						color = colorBackground;
					else
						color = DuckColor;
				end
				else if(Duck_5_alive == 0 && Duck_5_falling == 1)
				begin
					if(colorFallingDuck == 3'b001)
						color = colorBackground;
					else
						color = colorFallingDuck;
				end
			end
			
			//Duck 6
			if(ID == 6)
			begin
				if(inputX >= 159 - sizeX)
				begin
					color = colorBackground;
				end
				else if(Duck_6_alive == 1)
				begin
					if(DuckColor == 3'b001)
						color = colorBackground;
					else
						color = DuckColor;
				end
				else if(Duck_6_alive == 0 && Duck_6_falling == 1)
				begin
					if(colorFallingDuck == 3'b001)
						color = colorBackground;
					else
						color = colorFallingDuck;
				end
			end
			
			//Target cursor
			if(ID == 0)
			begin
				if(colorTarget == 3'b001)
					color = colorBackground;
				else
					color = colorTarget;
			end
			
			if(ID == 7)
				color = colorEnd;
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
				ID = 4;
			end
			else if(ID == 4)
			begin
				ID = 5;
			end
			else if(ID == 5)
			begin
				ID = 6;
			end
			else if(ID == 6)
			begin
				if(Duck_6_dead == 1 && Duck_5_dead == 1)
					ID = 7;
				else
					ID = 0;
			end
			else if(ID == 0)
			begin
				ID = 1;
			end
			else if(ID == 7)
				ID = 7;
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
	
	reg [7:0]targetSizeX = 12;
	reg [6:0]targetSizeY = 11;
	
	reg [7:0]fallingDuckSizeX = 34;
	reg [6:0]fallingDuckSizeY = 30;
	
	always@(enable)
	begin
		if(proceed == 0)
		begin
			sizeX = backgroundSizeX;
			sizeY = backgroundSizeY;
		end
		else if(ID == 7)
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
		
		else if(ID == 4)
		begin
			sizeX = duckSizeX;
			sizeY = duckSizeY;
		
			if(Duck_4_falling == 1)
			begin
				sizeX = fallingDuckSizeX;
				sizeY = fallingDuckSizeY;
			end
		end
		
		else if(ID == 5)
		begin
			sizeX = duckSizeX;
			sizeY = duckSizeY;
		
			if(Duck_5_falling == 1)
			begin
				sizeX = fallingDuckSizeX;
				sizeY = fallingDuckSizeY;
			end
		end
		
		else if(ID == 6)
		begin
			sizeX = duckSizeX;
			sizeY = duckSizeY;
		
			if(Duck_6_falling == 1)
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

module PS2_Demo (
	// Inputs
	CLOCK_50,
	KEY,

	// Bidirectionals
	PS2_CLK,
	PS2_DAT,
	
	// Outputs
	last_data_received, 
	ps2_key_pressed
);

/*****************************************************************************
 *                           Parameter Declarations                          *
 *****************************************************************************/


/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/

// Inputs
input				CLOCK_50;
input		[3:0]	KEY;

// Bidirectionals
inout				PS2_CLK;
inout				PS2_DAT;

/*****************************************************************************
 *                 Internal Wires and Registers Declarations                 *
 *****************************************************************************/

// Internal Wires
wire		[7:0]	ps2_key_data;
output				ps2_key_pressed;

// Internal Registers
 output reg	[7:0]	last_data_received;

// State Machine Registers

/*****************************************************************************
 *                         Finite State Machine(s)                           *
 *****************************************************************************/


/*****************************************************************************
 *                             Sequential Logic                              *
 *****************************************************************************/

always @(posedge CLOCK_50)
begin
	if (KEY[0] == 1'b0)
		last_data_received <= 8'h00;
	else if (ps2_key_pressed == 1'b1)
		last_data_received <= ps2_key_data;
end

/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/

PS2_Controller PS2 (
	// Inputs
	.CLOCK_50				(CLOCK_50),
	.reset				(~KEY[0]),

	// Bidirectionals
	.PS2_CLK			(PS2_CLK),
 	.PS2_DAT			(PS2_DAT),

	// Outputs
	.received_data		(ps2_key_data),
	.received_data_en	(ps2_key_pressed)
);

endmodule

module timer (CLOCK_50, KEY, HEX7, HEX6, HEX5, HEX4, HEX3, HEX2, startTimer, stopTimer);
  input CLOCK_50;
  input [3:0] KEY;
  output [0:6] HEX7, HEX6, HEX5, HEX4, HEX3, HEX2;
  wire [25:0] PERSEC;
  wire [31:0] PERMIN;
  wire [37:0] PERHOUR;
  wire [5:0] SECONDS, MINUTES;
  wire [4:0] HOURS;
  
  input startTimer, stopTimer;
  
  reg sec, min, hour;
  counter_modk C0 (CLOCK_50, stopTimer, startTimer, PERSEC);
  defparam C0.n = 26;
  defparam C0.k = 50000000;
  counter_modk C1 (CLOCK_50, stopTimer, startTimer, PERMIN);
  defparam C1.n = 32;
  defparam C1.k = 3000000000;
  counter_modk C2 (CLOCK_50, stopTimer, startTimer, PERHOUR);
  defparam C2.n = 38;
  defparam C2.k = 180000000000;
  counter_modk C3 (sec, stopTimer, startTimer, SECONDS);
  defparam C3.n = 6;
  defparam C3.k = 60;
  counter_modk C4 (min, stopTimer, startTimer, MINUTES);
  defparam C4.n = 6;
  defparam C4.k = 60;
  counter_modk C5 (hour, stopTimer, startTimer, HOURS);
  defparam C5.n = 5;
  defparam C5.k = 24;
  always @ (negedge CLOCK_50) begin
    if (PERSEC == 49999999)
      sec = 1;
    else
      sec = 0;
    if (PERMIN == 2999999999)
      min = 1;
    else
      min = 0;
    if (PERHOUR == 179999999999)
      hour = 1;
    else
      hour = 0;
  end
  twodigit_b2d_ssd D7 (HOURS, HEX7, HEX6);
  twodigit_b2d_ssd D5 (MINUTES, HEX5, HEX4);
  twodigit_b2d_ssd D3 (SECONDS, HEX3, HEX2);
  assign HEX1 = 7'b1111111;
  assign HEX0 = 7'b1111111;
endmodule
module b2d_ssd (X, SSD);
  input [3:0] X;
  output reg [0:6] SSD;
  always begin
    case(X)
      0:SSD=7'b0000001;
      1:SSD=7'b1001111;
      2:SSD=7'b0010010;
      3:SSD=7'b0000110;
      4:SSD=7'b1001100;
      5:SSD=7'b0100100;
      6:SSD=7'b0100000;
      7:SSD=7'b0001111;
      8:SSD=7'b0000000;
      9:SSD=7'b0001100;
    endcase
  end
endmodule
module twodigit_b2d_ssd (X, SSD1, SSD0);
  input [6:0] X;
  output [0:6] SSD1, SSD0;
  reg [3:0] ONES, TENS;
  always begin
    ONES = X % 10;
    TENS = (X - ONES) / 10;
  end
  b2d_ssd B1 (TENS, SSD1);
  b2d_ssd B0 (ONES, SSD0);
endmodule

module counter(clock, reset_n, Q);
  parameter n = 4;
  input clock, reset_n;
  output [n-1:0] Q;
  reg [n-1:0] Q;
  always @(posedge clock or negedge reset_n)
  begin
    if (reset_n)
      Q <= 'd0;
    else
      Q <= Q + 1'b1;
  end
endmodule
	
	
module counter_modk(clock, stop, start, Q);
  parameter n = 4;
  parameter k = 16;
  input clock, stop, start;
  output [n-1:0] Q;
  reg [n-1:0] Q;
  always @(posedge clock)
  begin
    if (stop)
      Q <= 'd0;
    else if (start)
	 begin
      Q <= Q + 1'b1;
      if (Q == k-1)
        Q <= 'd0;
    end
  end
endmodule
	