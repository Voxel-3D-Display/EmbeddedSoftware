`timescale 1 ps / 1 ps

module top
	(
		input 	CLK_10M,
		input		ENC_ABS_HOME,
		input 	ENC_360,
		input 	HDMI_RGB[2:0][7:0],
		output 	reg LAT,
		output 	reg SCLK,
		output 	GSCLK,
		output   SDO[11:0][3:0]

		//////////// SDRAM //////////
		output		    [12:0]		DRAM_ADDR, //address
		output		     [1:0]		DRAM_BA, //bank address
		output		          		DRAM_CAS_N, //column address strobe
		output		          		DRAM_CKE, //clock enable
		output		          		DRAM_CLK, //clock
		output		          		DRAM_CS_N, //chip select
		inout 		    [15:0]		DRAM_DQ, //SDRAM data
		output		     [1:0]		DRAM_DQM, //SDRAM byte data mask
		output		          		DRAM_RAS_N, //row address strobe
		output		          		DRAM_WE_N, //write enable
	);
	
	Pll pll(
		.clk_in_clk(CLK_10M),  			//  clk_in.clk
		.gsclk_clk(GSCLK),     			//   gsclk.clk
		.sclk_x2_clk(spiClk)    		// sclk_x2.clk // unused
	);
	
	HDMI hdmi(
		//takes the 24 HDMI_RGB values as input (they also input into top)
		//places the HDMI RGB values into SDRAM
		//we just index through SDRAM and fill it with entire 1440x720 frame
		//once it is fully populated, we switch to populating the other buffer
		//and notify the led driver code that it can start reading from memory
	);
	
	//Reading from and writing to SDRAM
	//there are 4 banks available to us
	//can we populate one bank with data while reading data from another bank
	
	
	// HDMI
	//takes in 24 bit value from HDMI decoder
	//places this information in a latch/reg to send to LED CTL
	//recieve 1440 RGB values sets for one update
	//12 by 4 by 30 by 3 array that stores the values 
	//LED CTL can assemble a length 769 bitstream from this

	// state: when finish data upload. turn off sclk
	
	//MatrixLocation
	//the spot in the matrix corresponds to the LED that the HDMI data is for

	// Reset reset(
	// 	.clk(CLK_10M),
	// 	.nReset
	// );
	
	localparam LATCH_SIZE = 'd769;
	localparam NUM_DRIVERS_CHAINED = 'd2;

	integer bit_num = LATCH_SIZE - 1;
	integer daisy_num = NUM_DRIVERS_CHAINED - 1;
	// reg [LATCH_SIZE-1:0] control_data = 769'b1100101100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111111111111111111111000000000001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100;
	// reg [LATCH_SIZE-1:0] control_data = 'b1100101100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111111111111111111111000000000001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100;
	
	// raw stream from arduino
	// reg [LATCH_SIZE-1:0] grayscale_data = 769'b0000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111;
	
	// shoving all 1's
	// reg [LATCH_SIZE-1:0] grayscale_data = 769'b0111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111;
	
	// all blue
	//reg [LATCH_SIZE-1:0] grayscale_data = 769'b0111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000;
	
	// all green 
	//reg [LATCH_SIZE-1:0] grayscale_data = 769'b0000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000;
	
	// all red
	 //reg [LATCH_SIZE-1:0] grayscale_data = 769'b0000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111;
	reg [15:0] PLACEHOLDER = 16'd63000;
	
	reg [LATCH_SIZE-1:0] data = 0; 
	
	reg init = 1'b1;	// initialize LED driver with control data latch
	reg [3:0] state = 4'd0;
	reg [30:0] iterations = 'd10;
	reg [5:0] dot_corr = 6'd127;	// dot correction values for all led driver channels
	reg [2:0] mc_r = 3'd0;	// max current for red
	reg [2:0] mc_g = 3'd0;	// max current for green
	reg [2:0] mc_b = 3'd0;	// max current for blue
	reg [5:0] bc_r = 6'd127;	// global brightness control for red
	reg [5:0] bc_g = 6'd127;	// global brightness control for green
	reg [5:0] bc_b = 6'd127;	// global brightness control for blue
	reg dsprpt = 1'b1; // Auto display repeat mode enable
	reg tmgrst = 1'b1; // Display timing reset mode enable
	reg rfresh = 1'b1; // Auto data refresh mode enable
	reg espwm  = 1'b1; // ES-PWM mode enable
	reg lsdvlt = 1'b1; // LSD detection voltage selection
	integer i = 0;
	integer led_channel = 0;
	integer color_channel = 0;
	reg nReset = 1;


	always@(posedge CLK_10M) begin
		if (!nReset) begin
			state <= 4'd0; // initialize
			LAT <= '0;
			SCLK <= '0;
			bit_num <= LATCH_SIZE-1;
			init <= 1;
		end else begin
			case (state)
				4'd0: //reset all data bits to 0
					begin
						LAT <= '0;
						SCLK <= '0;
						bit_num <= LATCH_SIZE-1;
						daisy_num <= NUM_DRIVERS_CHAINED - 1; 
						data[LATCH_SIZE-1:0] <= 0;
						if (init) begin
							state <= 4'd1;	
						end else begin
							state <= 4'd2;
						end
					end
				4'd1: // update the data with the control data latch 
					begin
						data[768] <= '1;	// latch select bit

						// Maximum Current (MC) Data Latch
						data[338:336] <= mc_r;		// max red current bits 
						data[341:339] <= mc_g;		// max green current bits 
						data[344:342] <= mc_b;		// max blue current bits 

						// Global Brightness Control (BC) Data Latch
						data[351:345] <= bc_r;		// global red brightness control bits 
						data[358:352] <= bc_g;		// global green brightness control bits 
						data[365:359] <= bc_b;		// global blue brightness control bits 

						// Function Control (FC) Data Latchdsprpt
						data[366] <= dsprpt; // Auto display repeat mode enable bit
						data[367] <= tmgrst; // Display timing reset mode enable bit
						data[368] <= rfresh; // Auto data refresh mode enable bit
						data[369] <= espwm; // ES-PWM mode enable bit
						data[370] <= lsdvlt; // LSD detection voltage selection bit

						// Dot Correction (DC) Data Latch
						for (i=0; i<48; i=i+1) begin   
							data[i*7+6 -: 7] <= dot_corr;	// dot correction bits (335-0)
						end


						state <= 4'd3;
					end
				4'd2: // update the data with the grayscale data latch
					begin
						data[768] <= '0;	// latch select bit

						for (led_channel=0; led_channel<16; led_channel=led_channel+1) begin   
							for (color_channel=0; color_channel<3; color_channel=color_channel+1) begin
								// color channels
								// case 0 = red
								// case 1 = green
								// case 2 = blue
								case (color_channel) 
									'd0: 
										begin
											if (daisy_num = 1) 
												data[15+16*color_channel+48*led_channel -: 16] <= 0;
											else if (daisy_num = 0) 
												data[15+16*color_channel+48*led_channel -: 16] <= 0;
										end
									'd1: 
										begin
											if (daisy_num = 1) 
												data[15+16*color_channel+48*led_channel -: 16] <= 0;
											else if (daisy_num = 0) 
												data[15+16*color_channel+48*led_channel -: 16] <= 0;
										end
									'd2:
										begin
											if (daisy_num = 1) 
												data[15+16*color_channel+48*led_channel -: 16] <= 65335;
											else if (daisy_num = 0) 
												data[15+16*color_channel+48*led_channel -: 16] <= 65335;
										end
								endcase
								// data[15+16*color_channel+48*led_channel -: 16] <= PLACEHOLDER;	// dot correction bits (335-0)
							end
						end
						
						state <= 4'd3;
					end
				4'd3:	// set SCLK low and put data on lines for a bit
					begin
						SCLK <= '0;
						SDO[11][3] <= data[bit_num];
						SDO[11][2] <= data[bit_num];
						SDO[11][1] <= data[bit_num];
						SDO[11][0] <= data[bit_num];
						state <= 4'd4;
					end
				4'd4:	// set SCLK high to shift out a bit 
					begin	
						SCLK <= '1;
						bit_num <= bit_num - 1;
						state <= 4'd5;
					end
				4'd5:
					begin
						SCLK <= '0;
						if (bit_num < 0) begin	// proceed to latch if next bit is out of range	
							state <= 4'd6;						
							daisy_num <= daisy_num-1;
						end else begin	// proceed to shift next bit into shift register
							state <= 4'd3;
						end
					end
				4'd6:	// latch the LED driver
					begin
						if (daisy_num < 0) begin
							LAT <= '1;						
							// daisy_num <= NUM_DRIVERS_CHAINED - 1;	
							init <= 0;	
						end
						// bit_num <= LATCH_SIZE - 1;
						state <= 4'd0;
					end
				
			endcase

		end
	end 
	// 	// if (!nReset) begin
	// 	// 	state <= 4'd0; // initialize
	// 	// 	LAT <= '0;
	// 	// 	SCLK <= '0;
	// 	// 	bit_num <= LATCH_SIZE;
	// 	// end else begin
	// 		case (state)
	// 			4'd9: // reset iterations
	// 				begin
	// 					iterations <= 'd10;
	// 					state <= 4'd0;
	// 				end
	// 			4'd0: // initialize, load (begin)
	// 				begin
	// 					SCLK <= '0;
	// 					if (bit_num != '0) begin							
	// 						SDO[11][3] <= (control_data >> (bit_num-1)) & 1'b1; // control_data[bit_num-1];
	// 						SDO[11][2] <= (control_data >> (bit_num-1)) & 1'b1; // control_data[bit_num-1];
	// 						SDO[11][1] <= (control_data >> (bit_num-1)) & 1'b1; // control_data[bit_num-1];
	// 						SDO[11][0] <= (control_data >> (bit_num-1)) & 1'b1; // control_data[bit_num-1];
	// 						state <= 4'd1; // initialize, shift in
	// 					end else begin
	// 						state <= 4'd2; // initialize, latch
	// 					end
	// 				end
	// 			4'd1: // initialize, shift in
	// 				begin
	// 					bit_num <= bit_num - 1;
	// 					SCLK <= '1;
	// 					state <= 4'd0; // initialize, load
	// 				end
	// 			4'd2: // initialize, latch (end)
	// 				begin
	// 					LAT <= '1;
	// 					bit_num <= LATCH_SIZE;
	// 					state <= 4'd3; // grayscale, reinit
	// 				end
	// 			4'd3: // grayscale, reinit (begin)
	// 				begin
	// 					LAT <= '0;
	// 					SCLK <= '0;
	// 					bit_num <= LATCH_SIZE;
	// 					// reset state to push control latches again after 50e6 iteratins
	// 					if (iterations == '0) begin
	// 						state <= 4'd9;
	// 					end else begin
	// 						iterations <= iterations - 1;
	// 						state <= 4'd4; // 4'd8
	// 					end
	// 				end
				
	// 			// 4'd8: // grayscale, load 0's
	// 			// 	begin
	// 			// 		SCLK <= 0;
	// 			// 		SDO[0] <= 0;
	// 			// 		SDO[1] <= 0;
	// 			// 		SDO[2] <= 0;
	// 			// 		SDO[3] <= 0;
	// 			// 		state <= 4'd5; // grayscale, shift in
	// 			// 	end
	// 			4'd4: // grayscale, load
	// 				begin
	// 					SCLK <= 0;
	// 					if (bit_num != 0) begin
	// 						SDO[11][3] <= grayscale_data[bit_num-1];
	// 						SDO[11][2] <= grayscale_data[bit_num-1];
	// 						SDO[11][1] <= grayscale_data[bit_num-1];
	// 						SDO[11][0] <= grayscale_data[bit_num-1];
	// 						state <= 4'd5; // grayscale, shift in
	// 					end else begin
	// 						state <= 4'd6; // grayscale, latch
	// 					end
	// 				end

	// 			// 4'd4: // grayscale, load 1's
	// 			// 	begin
	// 			// 		SCLK <= 0;
	// 			// 		if (bit_num != 0) begin // offset by 1 for MSB 0
	// 			// 			SDO[0] <= 1;
	// 			// 			SDO[1] <= 1;
	// 			// 			SDO[2] <= 1;
	// 			// 			SDO[3] <= 1;
	// 			// 			state <= 4'd5; // grayscale, shift
	// 			// 		end else begin
	// 			// 			state <= 4'd6; // grayscale, latch
	// 			// 		end
	// 			// 	end
				
	// 			4'd5: // grayscale, shift in
	// 				begin
	// 					bit_num = bit_num - 1;
	// 					SCLK <= '1;
	// 					state <= 4'd4; // grayscale, load
	// 				end
	// 			4'd6: // grayscale, latch (end)
	// 				begin
	// 					LAT <= '1;
	// 					bit_num <= LATCH_SIZE;
	// 					state <= 4'd3; // grayscale, reinit
	// 				end
	// 			// 4'd7: // hold loop, turn off LEDs
	// 			// 	begin
	// 			// 		LAT <= '1; // should not wipe shift register
	// 			// 		state <= 4'd7;
	// 			// 	end
	// 			default:
	// 				state <= 4'd9;
	// 		endcase
	// 	// end
	// end
endmodule