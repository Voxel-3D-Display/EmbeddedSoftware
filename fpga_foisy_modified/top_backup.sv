`timescale 1 ps / 1 ps

module top (
		input 					CLK_10M,
		input logic          initSTP,
	
		output 					GSCLK,
		output   				LAT,
		output  					SCLK,
		output [3:0]  			SDOs, //changed width 8 to 4
				
		// input  logic			inputTest, // added 2/20/22
		output logic			testPin, // added 2/20/22
		output logic testInitDone
	);
	
	assign SCLK = ledSCLK;
	assign LAT = ledLat;
	
	
//	assign testPin = CLK_10M; // added 2/20/22
	always@(posedge CLK_10M) begin
			testPin <= 1;
	end
	
	localparam BURST_SIZE = 8;
	
	localparam SPI_CLK_FREQ = 40000000;
	
	
	logic [15:0] ledColBuf;
	
	logic initLat;
	logic initSCLK;
	logic nReset;
	logic spiClk;
	logic SDOsingle;
	logic initDone;
	
	localparam NUM_SIDES = 1;		//1 or 2
	logic ledLat;
	logic ledBusy;
	
	localparam NUM_SHIFT = 4;
	//logic [NUM_SHIFT-1:0] SDOs;
	logic ledSCLK;

	InitLed #(.NUM_TLC5955(2)) initLed (	
		// inputs
		.spiClk,
		.nReset,

		//outputs
		.LAT(initLat),
		.SDOsingle,
		.SCLK(initSCLK),
		
		.initDone
	);
	
	always@(posedge CLK_10M) begin
		if(!nReset) begin
				testInitDone <= 0;
		end
		testInitDone <= initDone;
	end
	
	
	reg ledCmdStart;
	reg ledCmdDone;

	LedCtrl ledCtrl(
		.spiClk(spiClk),
		.nReset(nReset),

		.SDOs,
		.LAT(ledLat),
		.SCLK(ledSCLK),
		
		.cmdStart(initDone),
		.cmdDone(ledCmdDone),
		.busy(ledBusy),
		
		.ledColBuf
		// .rdaddress
	);

	Pll pll(
		.clk_in_clk(CLK_10M),  			//  clk_in.clk
		.gsclk_clk(GSCLK),     			//   gsclk.clk
		.sclk_x2_clk(spiClk)    		// sclk_x2.clk
	);
	
			 
	
	Reset reset(
		.clk(CLK_10M),
		.nReset
	);
	
endmodule
