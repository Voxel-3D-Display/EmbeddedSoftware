`timescale 10 ps / 10 ps
module top (

		output   reg	clk
		
	);
	localparam IMG_HEIGHT = 1024;
	reg nReset;
	logic [$clog2(IMG_HEIGHT)-1:0] row;
	logic [$clog2(IMG_HEIGHT)-1:0] rowEven;
	logic valid;
	logic index;
	logic rowChange;

	reg mag;
	initial #0 begin
		mag=0;
    		clk=0;
		nReset=1;
    		#30 nReset=0;
		#50 nReset=1;
  	end

  	always begin
    		#10 clk=!clk;
  	end

	always begin
		#625000 mag=!mag;
	end

	TurnTimer #(.CLK_FREQ(50000000), .FPS(10), .IMG_HEIGHT(IMG_HEIGHT)) turnTimer(
		.clk,
		.nReset,

		.mag,

		.row,
		.rowEven,
		.valid,
		.index,
		.rowChange
	);
	
endmodule

