`timescale 1 ps / 1 ps

module top
	(
		input 	CLK_10M,
		input		ENC_ABS_HOME,
		input 	ENC_360,
		//input 	[2:0][7:0]   HDMI_RGB, //UNCOMMENT
		input    VSYNC,
		//input    PIXCLK, //UNCOMMENT
		input    DE, //tells us if we are getting an HSYNC/VSYNC rn or normal data
		input 	nReset,
		output 	reg LAT,
		output 	reg SCLK,
		output 	GSCLK,
		output 	TESTCLK,
		output   reg SDO[11:0][3:0],
		output	reg [3:0] STATE_CHECK,

		//////////// SDRAM //////////
		output		    [12:0]		SDRAM_ADDR, //address
		output		     [1:0]		SDRAM_BA, //bank address
		output		          		SDRAM_CAS_N, //column address strobe
		output		          		SDRAM_CKE, //clock enable
		output      		        SDRAM_CLK, //clock
		output		          		SDRAM_CS_N, //chip select
		inout 		    [15:0]		SDRAM_DQ, //SDRAM data
		output		     [1:0]		SDRAM_DQM, //SDRAM byte data mask
		output		          		SDRAM_RAS_N, //row address strobe
		output		          		SDRAM_WE_N //write enable
	);

	//HDMI testing start
	reg [2:0][7:0] HDMI_RGB = 24'b111111111111111111111111;
	//HDMI testing end

	logic SDRAM_CLKn;
	assign SDRAM_CLK = !SDRAM_CLKn;
	logic PIXCLK;

	pll pll(
		.inclk0(CLK_10M),  			//  clk_in.clk
		.c0(GSCLK),     			//   gsclk.clk
		.c1(TESTCLK),    			// sclk_x2.clk // unused
		.c2(SDRAM_CLKn),
		.c3(PIXCLK)
	);

	reg enable_shifter = 0;
	reg load_shifter = 0;
	reg reset_shifter = 0;
//	led_driver_shift_reg shifter (
//		.data(grayscale_data),
//		.clock(TESTCLK),
//		.enable(enable_shifter),
//		.load(load_shifter),
//		.sclr(reset_shifter),
//		.shiftout(SDO[11][3])
//	);
	test shifter1 (
		.data(grayscale_data),
		.clock(TESTCLK),
		.enable(enable_shifter),
		.load(load_shifter),
		.sclr(reset_shifter),
		.shiftout(SDO[11][2])
	);

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
	// reg [LATCH_SIZE-1:0] grayscale_data = 769'b0111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111;
	
	// all blue
	//reg [LATCH_SIZE-1:0] grayscale_data = 769'b0111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000111111111111111100000000000000000000000000000000;
	
	// all green 
	//reg [LATCH_SIZE-1:0] grayscale_data = 769'b0000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000000000000000000011111111111111110000000000000000;
	
	// all red
	// reg [LATCH_SIZE-1:0] grayscale_data = 769'b0000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111000000000000000000000000000000001111111111111111;
	
	// test 010101... repeating
	reg [LATCH_SIZE-1:0] grayscale_data = 769'b0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010;
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
	
	assign SCLK = !TESTCLK & enable_shifter;
	
	always@(posedge TESTCLK) begin
		
		
		// if (!nReset) begin
		if (0) begin
			state <= 32'd0; // initialize
			LAT <= '0;
			bit_num <= LATCH_SIZE;
			daisy_num <= NUM_DRIVERS_CHAINED-1; 
			init <= 1;
		end else begin
			case (state)
			
 //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 //////////////////////////////////////////////////////////////////////////////////////	Prepare data bits	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

				32'd0:	// re-initialize
					begin
						LAT <= '0;
						enable_shifter <= 0;
						load_shifter <= 0;
						daisy_num <= NUM_DRIVERS_CHAINED-1; 
						data[LATCH_SIZE-1:0] <= 0;	
						if (init) begin
							state <= 32'd1;	
						end else begin
							state <= 32'd2;
						end
					end
					
				32'd1: // control data 
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
				32'd2: // grayscale data 
					begin
						data[768] <= '0;	// latch select bit

						for (led_channel=0; led_channel<16; led_channel=led_channel+1) begin   
							data[(16*0+3*16*led_channel) +: 16] <= 16'h5555;     // red color brightness
							data[(16*1+3*16*led_channel) +: 16] <= 16'h5555;  // green color brightness
							data[(16*2+3*16*led_channel) +: 16] <= 16'h5555;     // blue color brightness
						end
						state <= 32'd3;
					end  
					
 //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 //////////////////////////////////////////////////////////////////////////////////////	Shift register states	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

 
				32'd3: // 
					begin
						load_shifter <= 1;
						enable_shifter <= 1;
						state <= 32'd4;						
					end
				32'd4: // 
					begin
						enable_shifter <= 1;
						load_shifter <= 0;
						bit_num <= LATCH_SIZE;
			

						state <= 32'd5;
					end
				32'd5: // 
					begin
						if (enable_shifter == 0) begin
							if (daisy_num == 0) begin
								LAT <= '1;
								
								daisy_num <= NUM_DRIVERS_CHAINED-1; 
								state <= 32'd0; 
							end else begin
								daisy_num <= daisy_num - 1;
								state <= 32'd3;
							end
						end 
					end
				default:
					state <= 32'd0;
			endcase

			
			if (enable_shifter) begin
				if (bit_num == 0) begin
					if (daisy_num == 0) begin
						enable_shifter <= 0;
					end else begin
					end
				end else begin
					bit_num <= bit_num - 1;
				end 
			end
		end
		
		
	end
endmodule