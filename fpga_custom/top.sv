	`timescale 1 ps / 1 ps

module top
	(
		input 	CLK_10M,
		input		ENC_ABS_HOME,
		input 	ENC_360,
		input 	HDMI_RGB[2:0][7:0],
		input 	nReset,
		output 	reg LAT,
		output 	reg SCLK,
		output 	GSCLK,
		output 	TESTCLK,
		output  reg SDO[11:0][3:0],
		output	HIELLO
		// output	reg [3:0] STATE_CHECK,

		//////////// SDRAM //////////
		// output		    [12:0]		DRAM_ADDR, //address
		// output		     [1:0]		DRAM_BA, //bank address
		// output		          		DRAM_CAS_N, //column address strobe
		// output		          		DRAM_CKE, //clock enable
		// output		          		DRAM_CLK, //clock
		// output		          		DRAM_CS_N, //chip select
		// inout 		    [15:0]		DRAM_DQ, //SDRAM data
		// output		     [1:0]		DRAM_DQM, //SDRAM byte data mask
		// output		          		DRAM_RAS_N, //row address strobe
		// output		          		DRAM_WE_N //write enable
	);
	
	pll pll(
		.inclk0(CLK_10M),  			//  clk_in.clk
		.c0(GSCLK),     			//   gsclk.clk
		.c1(TESTCLK)    		// sclk_x2.clk // unused
	);
	
	// HDMI hdmi(
	// 	//takes the 24 HDMI_RGB values as input (they also input into top)
	// 	//places the HDMI RGB values into SDRAM
	// 	//we just index through SDRAM and fill it with entire 1440x720 frame
	// 	//once it is fully populated, we switch to populating the other buffer
	// 	//and notify the led driver code that it can start reading from memory
	// );
	
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
	localparam BRIGHTNESS_RED = 16'd30000;
	localparam BRIGHTNESS_GREEN = 16'd0;
	localparam BRIGHTNESS_BLUE = 16'd0;

	integer bit_num = LATCH_SIZE;
	integer daisy_num = NUM_DRIVERS_CHAINED - 1;
	reg [LATCH_SIZE-1:0] control_data = 769'b1100101100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111111111111111111111000000000001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100001010000101000010100;
	
	// raw stream from arduino
	// reg [LATCH_SIZE-1:0] grayscale_data = 769'b0000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111;
	
	// shoving all 1's
	 reg [LATCH_SIZE-1:0] grayscale_data = 769'b0111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111;
	
	// all blue
	//reg [LATCH_SIZE-1:0] grayscale_data = 769'b0111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000;
	
	// all green 
	//reg [LATCH_SIZE-1:0] grayscale_data = 769'b0000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000;
	
	// all red
	//reg [LATCH_SIZE-1:0] grayscale_data = 769'b0000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111;
	
	reg [LATCH_SIZE-1:0] data = 'd0; 
	
	reg init = 1;	// initialize LED driver with control data latch
	reg [31:0] state = 32'd0;
	reg [5:0] dot_corr_r = 6'd127;	// dot correction values for red led driver channels
	reg [5:0] dot_corr_g = 6'd127;	// dot correction values for green led driver channels
	reg [5:0] dot_corr_b = 6'd127;	// dot correction values for blue led driver channels
	reg [2:0] mc_r = 3'd0;	// max current for red
	reg [2:0] mc_g = 3'd0;	// max current for green
	reg [2:0] mc_b = 3'd0;	// max current for blue
	reg [5:0] gbc_r = 6'd127;	// global brightness control for red
	reg [5:0] gbc_g = 6'd127;	// global brightness control for green
	reg [5:0] gbc_b = 6'd127;	// global brightness control for blue
	reg dsprpt = 1'b1; // Auto display repeat mode enable
	reg tmgrst = 1'b0; // Display timing reset mode enable
	reg rfresh = 1'b0; // Auto data refresh mode enable
	reg espwm  = 1'b1; // ES-PWM mode enable
	reg lsdvlt = 1'b1; // LSD detection voltage selection
	integer i = 0;
	integer led_channel = 0;
	integer color_channel = 0;

	// assign STATE_CHECK[3:0] = state[3:0];
	
	always@(posedge TESTCLK) begin
		if (!nReset) begin
			state <= 32'd0; // initialize
			LAT <= '0;
			SCLK <= '0;
			bit_num <= LATCH_SIZE;
			daisy_num <= NUM_DRIVERS_CHAINED-1; 
			init <= 1;
		end else begin
			case (state)
				32'd0:	// re-initialize
					begin
						LAT <= '0;
						SCLK <= '0;
						bit_num <= LATCH_SIZE;
						data[LATCH_SIZE-1:0] <= 0;	
						if (init) begin
							state <= 32'd1;	
						end else begin
							state <= 32'd2;
						end
					end
				32'd1: // update the data with the control data latch 
					begin
						init <= '0;
						
						data[768] <= '1;	// latch select bit

						// Maximum Current (MC) Data Latch
						data[338:336] <= mc_r;		// max red current bits 
						data[341:339] <= mc_g;		// max green current bits 
						data[344:342] <= mc_b;		// max blue current bits 

						// Global Brightness Control (BC) Data Latch
						data[351:345] <= gbc_r;		// global red brightness control bits 
						data[358:352] <= gbc_g;		// global green brightness control bits 
						data[365:359] <= gbc_b;		// global blue brightness control bits 

						// Function Control (FC) Data Latchdsprpt
						data[366] <= dsprpt; // Auto display repeat mode enable bit
						data[367] <= tmgrst; // Display timing reset mode enable bit
						data[368] <= rfresh; // Auto data refresh mode enable bit
						data[369] <= espwm; // ES-PWM mode enable bit
						data[370] <= lsdvlt; // LSD detection voltage selection bit

						// Dot Correction (DC) Data Latch
						for (led_channel=0; led_channel<16; led_channel=led_channel+1) begin   
							data[7*0+3*7*led_channel +: 7] <= dot_corr_r;     // red dot correction
							data[7*1+3*7*led_channel +: 7] <= dot_corr_g;  // green dot correction
							data[7*2+3*7*led_channel +: 7] <= dot_corr_b;     // blue dot correction
						end

						state <= 32'd3;
					end
				32'd2: // update the data with the grayscale data latch
					begin
						data[768] <= '0;	// latch select bit

						for (led_channel=0; led_channel<16; led_channel=led_channel+1) begin   
							data[(16*0+3*16*led_channel) +: 16] <= 16'h0AFF;     // red color brightness
							data[(16*1+3*16*led_channel) +: 16] <= 16'h0;  // green color brightness
							data[(16*2+3*16*led_channel) +: 16] <= 16'h0;     // blue color brightness
						end

						state <= 32'd3;
					end  

				32'd3: // load 
					begin
						SCLK <= '0;
						if (bit_num != '0) begin
							SDO[11][3] <= data[bit_num-1] ;
							SDO[11][2] <= data[bit_num-1] ;
							SDO[11][1] <= data[bit_num-1] ; 
							SDO[11][0] <= data[bit_num-1] ; 
							state <= 32'd10; // initialize, shift in	
						end else begin
							if (daisy_num == '0) begin
								state <= 32'd11; // initialize, latch	
							end else begin 
								daisy_num <= daisy_num -1;
								state <= 32'd0; // reinit
							end

						end
					end
				32'd10: // shift out
					begin
						SCLK <= '1;
						bit_num <= bit_num - 1;
						state <= 32'd3; 
					end
				32'd11: // latch
					begin
						LAT <= '1;
						daisy_num <= NUM_DRIVERS_CHAINED-1; 
						bit_num <= LATCH_SIZE;
						state <= 32'd0; 
					end
					
				default:
					state <= 32'd0;
			endcase
		end
	end
endmodule