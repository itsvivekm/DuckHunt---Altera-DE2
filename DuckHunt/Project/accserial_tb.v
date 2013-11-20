// A simulation testbench for the accserial design by Prof. Chow
//
// Version 1.0	November 7 2013
//
// Stuart Byma
//

`timescale 1 ns / 10 ps	// this maps dimensionless Verilog time units into real time units
						// 1ns is the min time delay (#) and 10ps is the
						// minimum time unit that Modelsim will display


module accserial_tb(); // no I/O ports, this is a testbench file

	// signals 
	reg iClk, iResetn, iStart;
	reg [15:0] iNumVal;
	reg [7:0] iStartAddress; 
	wire 	oSO;

	wire [7:0] 	AdderSum;
	wire 	DoneShift, DoneAdd;
	
	// instantiate the DUT - Design Under Test
	top dut(iClk, iResetn, iStartAddress, iNumVal, iStart, oSO); 

	initial begin
		iClk = 0;
		iResetn = 0; // start clk and resetn at 0
		iStart = 0; // set the start control signal to 0
	end

	always #10 iClk = ~iClk; // generate a clock - every 10ns, toggle clock - what's the period and frequency?


	initial begin
		#20 // advance one clock cycle so reset takes effect

		iResetn = 1'b1;  // release reset
		iStartAddress = 8'd0; // set the start address input 
		iNumVal = 16'd5; // set the number of values to add input
		iStart = 1'b1; // start!
		#20
		iStart = 1'b0;

		#3000 // advance 150 cycles

		$stop;  // suspend the simulation, but do not $finish
			    // $finish will try to close Modelsim, and that's annoying
	end
endmodule

	
