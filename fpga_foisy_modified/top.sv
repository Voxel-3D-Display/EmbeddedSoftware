`timescale 1 ps / 1 ps

module top
	(
		input 	CLK_10M,
		output 	[3:0] SDOs, // output for 4 channels
		output 	reg LAT,
		output 	reg SCLK,
		output 	GSCLK
	);
	
	Pll pll(
		.clk_in_clk(CLK_10M),  			//  clk_in.clk
		.gsclk_clk(GSCLK),     			//   gsclk.clk
		.sclk_x2_clk(spiClk)    		// sclk_x2.clk
	);
	
	// Reset reset(
	// 	.clk(CLK_10M),
	// 	.nReset
	// );
		
	localparam LATCH_SIZE = 'd769;
	integer bit_num = LATCH_SIZE;
	reg [LATCH_SIZE-1:0] control_data = 769'b1100101100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111111111111111111111000000000001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100;
	// reg [LATCH_SIZE-1:0] control_data = 'b1100101100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111111111111111111111000000000001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100;
	
	// raw stream from arduino
	reg [LATCH_SIZE-1:0] grayscale_data = 769'b0000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111;
	
	// shoving 1's
	// reg [LATCH_SIZE-1:0] grayscale_data = 769'b0111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111;
	reg [3:0] state = 4'd0;
	reg [30:0] iterations = 'd10;
	
	always@(posedge CLK_10M) begin
		// if (!nReset) begin
		// 	state <= 4'd0; // initialize
		// 	LAT <= '0;
		// 	SCLK <= '0;
		// 	bit_num <= LATCH_SIZE;
		// end else begin
			case (state)
				4'd9: // reset iterations
					begin
						iterations <= 'd10;
						state <= 4'd0;
					end
				4'd0: // initialize, load (begin)
					begin
						SCLK <= '0;
						if (bit_num != '0) begin
							SDOs[0] <= (control_data >> (bit_num-1)) & 1'b1; // control_data[bit_num-1];
							SDOs[1] <= (control_data >> (bit_num-1)) & 1'b1; // control_data[bit_num-1];
							SDOs[2] <= (control_data >> (bit_num-1)) & 1'b1; // control_data[bit_num-1];
							SDOs[3] <= (control_data >> (bit_num-1)) & 1'b1; // control_data[bit_num-1];
							state <= 4'd1; // initialize, shift in
						end else begin
							state <= 4'd2; // initialize, latch
						end
					end
				4'd1: // initialize, shift in
					begin
						bit_num <= bit_num - 1;
						SCLK <= '1;
						state <= 4'd0; // initialize, load
					end
				4'd2: // initialize, latch (end)
					begin
						LAT <= '1;
						bit_num <= LATCH_SIZE;
						state <= 4'd3; // grayscale, reinit
					end
				4'd3: // grayscale, reinit (begin)
					begin
						LAT <= '0;
						SCLK <= '0;
						bit_num <= LATCH_SIZE;
						// reset state to push control latches again after 50e6 iteratins
						if (iterations == '0) begin
							state <= 4'd9;
						end else begin
							iterations <= iterations - 1;
							state <= 4'd4; // 4'd8
						end
					end
				
				// 4'd8: // grayscale, load 0's
				// 	begin
				// 		SCLK <= 0;
				// 		SDOs[0] <= 0;
				// 		SDOs[1] <= 0;
				// 		SDOs[2] <= 0;
				// 		SDOs[3] <= 0;
				// 		state <= 4'd5; // grayscale, shift in
				// 	end
				4'd4: // grayscale, load
					begin
						SCLK <= 0;
						if (bit_num != 0) begin
							SDOs[0] <= grayscale_data[bit_num-1];
							SDOs[1] <= grayscale_data[bit_num-1];
							SDOs[2] <= grayscale_data[bit_num-1];
							SDOs[3] <= grayscale_data[bit_num-1];
							state <= 4'd5; // grayscale, shift in
						end else begin
							state <= 4'd6; // grayscale, latch
						end
					end

				// 4'd4: // grayscale, load 1's
				// 	begin
				// 		SCLK <= 0;
				// 		if (bit_num != 0) begin // offset by 1 for MSB 0
				// 			SDOs[0] <= 1;
				// 			SDOs[1] <= 1;
				// 			SDOs[2] <= 1;
				// 			SDOs[3] <= 1;
				// 			state <= 4'd5; // grayscale, shift
				// 		end else begin
				// 			state <= 4'd6; // grayscale, latch
				// 		end
				// 	end
				
				4'd5: // grayscale, shift in
					begin
						bit_num = bit_num - 1;
						SCLK <= '1;
						state <= 4'd4; // grayscale, load
					end
				4'd6: // grayscale, latch (end)
					begin
						LAT <= '1;
						bit_num <= LATCH_SIZE;
						state <= 4'd3; // grayscale, reinit
					end
				// 4'd7: // hold loop, turn off LEDs
				// 	begin
				// 		LAT <= '1; // should not wipe shift register
				// 		state <= 4'd7;
				// 	end
				default:
					state <= 4'd9;
			endcase
		// end
	end
endmodule