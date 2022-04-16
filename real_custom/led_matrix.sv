`timescale 1 ps / 1 ps


module led_matrix
	(
		input 	CLK,
		input 	nReset,

		// Encoder
		input	ENC_SAYS_GO,
		
		// LED Driver 
		output 	bit [11:0][3:0] SDO,
		output 	reg LAT,
		output 	reg SCLK,

		// SDRAM 
		input   bit [73727:0] memory_data, //[11:0][7:0][767:0],
		output	reading_memory

	);
	
	localparam LATCH_SIZE = 'd769;
	localparam NUM_DRIVERS_CHAINED = 'd2;

	bit [767:0] data;
	reg init = 1;	// initialize LED driver with control data latch
	reg [31:0] state = 32'd0;
	integer bit_num = LATCH_SIZE;	// bit counter for 769 bit latch
	integer daisy_num = NUM_DRIVERS_CHAINED - 1;	// counter for the driver in the daisy-chain
	
	integer i = 0;	// for-loop counter
	integer n = 0;	// for-loop counter
	integer led_channel = 0;
	integer color_channel = 0;

	// Control Data Latch Values
	reg [6:0] dot_corr_r = 7'd127;	// dot correction values for red led driver channels
	reg [6:0] dot_corr_g = 7'd127;	// dot correction values for green led driver channels
	reg [6:0] dot_corr_b = 7'd127;	// dot correction values for blue led driver channels
	reg [2:0] mc_r = 3'd0;	// max current for red
	reg [2:0] mc_g = 3'd0;	// max current for green
	reg [2:0] mc_b = 3'd0;	// max current for blue
	reg [6:0] gbc_r = 7'd127;	// global brightness control for red
	reg [6:0] gbc_g = 7'd127;	// global brightness control for green
	reg [6:0] gbc_b = 7'd127;	// global brightness control for blue
	reg dsprpt = 1'b1; // Auto display repeat mode enable
	reg tmgrst = 1'b1; // Display timing reset mode enable
	reg rfresh = 1'b0; // Auto data refresh mode enable
	reg espwm  = 1'b1; // ES-PWM mode enable
	reg lsdvlt = 1'b1; // LSD detection voltage selection

	
	/*
	always@(posedge CLK) begin
		if (!nReset) begin
			state <= 32'd0; 
			LAT <= '0;
			SCLK <= '0;
			bit_num <= LATCH_SIZE;
			daisy_num <= NUM_DRIVERS_CHAINED-1; 
			init <= 1;
			reading_memory <= 0;
		end else begin
			case (state)
				32'd0:	// initialize 
					begin
						LAT <= '0;
						SCLK <= '0;			
						reading_memory <= 0;
						bit_num <= LATCH_SIZE;
						data[767:0] <= 768'd0;	
						if (init) begin
							state <= 32'd1;	
						end else begin
							state <= 32'd2;
						end
					end
				32'd1: // update the data with the control data latch 
					begin
						// Control Data Latch Bits
						data[767:760] <= 8'h96; 

						// Maximum Current (MC) Data Latch
						data[338:336] <= mc_r;		// max red current bits 
						data[341:339] <= mc_g;		// max green current bits 
						data[344:342] <= mc_b;		// max blue current bits 

						// Global Brightness Control (BC) Data Latch
						data[351:345] <= gbc_r;		// global red brightness control bits 
						data[358:352] <= gbc_g;		// global green brightness control bits 
						data[365:359] <= gbc_b;		// global blue brightness control bits 

						// Dot Correction (DC) Data Latch
						for (led_channel=0; led_channel<16; led_channel=led_channel+1) begin   
							data[7*0+3*7*led_channel +: 7] <= dot_corr_r;     // red dot correction
							data[7*1+3*7*led_channel +: 7] <= dot_corr_g;  // green dot correction
							data[7*2+3*7*led_channel +: 7] <= dot_corr_b;     // blue dot correction
						end

						// Function Control (FC) Data Latch
						data[366] <= dsprpt; // Auto display repeat mode enable bit
						data[367] <= tmgrst; // Display timing reset mode enable bit
						data[368] <= rfresh; // Auto data refresh mode enable bit
						data[369] <= espwm; // ES-PWM mode enable bit
						data[370] <= lsdvlt; // LSD detection voltage selection bit
						
						state <= 32'd3;
					end
				32'd2: // update the data with the grayscale data latch 			// read from memory
					begin
						reading_memory <= 1;
						
						if (daisy_num == 1) begin 
							for (led_channel=0; led_channel<16; led_channel=led_channel+1) begin  
								data[(16*0+3*16*led_channel) +: 16] <= 16'h8001;     // red color brightness
								data[(16*1+3*16*led_channel) +: 16] <= 16'h0;  // green color brightness
								data[(16*2+3*16*led_channel) +: 16] <= 16'h0;     // blue color brightness
							end
						end else if (daisy_num == 0) begin
							for (led_channel=0; led_channel<16; led_channel=led_channel+1) begin   
								data[(16*0+3*16*led_channel) +: 16] <= 16'h0;     // red color brightness
								data[(16*1+3*16*led_channel) +: 16] <= 16'h8001;  // green color brightness
								data[(16*2+3*16*led_channel) +: 16] <= 16'h0;     // blue color brightness
							end
						end
						
						
						
						state <= 32'd3;
					end  
					
				32'd3: // prepare data to be shifted out
					begin
						SCLK <= '0;
						reading_memory <= 0;
						
						if (bit_num != 'd0)	begin 	// continue shifting out bits	
								for (i=0; i<12; i=i+1) begin
									for (n=0; n<4; n=n+1) begin
										
										if (i != 1) begin
											if (bit_num == LATCH_SIZE) begin	// control bit (768)	
												if (init) begin
													SDO[i][n] <= 1; // set control bit to 1 to change control data latch
												end else begin
													SDO[i][n] <= 0; // set control bit to 0 to change grayscale data latch
												end
											end else begin		// bits 767:0
												// SDO[i][n] <= memory_data[i][n][bit_num-1];
												SDO[i][n] <= data[bit_num-1];
											end
										end
									end
								end
								state <= 32'd10;

						end else begin		// if all bits have been shifted out
							if (daisy_num == '0) begin
								state <= 32'd11; 
							end else begin 
								daisy_num <= daisy_num - 1;
								state <= 32'd0; 
							end
						end
					end

				32'd10: // shift out one bit 
					begin
						SCLK <= '1;
						bit_num <= bit_num - 1;
						state <= 32'd3; 
					end
					
				32'd11: // latch 
					begin
						// proceed only if initializing or when encoder says go
						if (init) begin
							init <= '0;
							LAT <= '1;
							daisy_num <= NUM_DRIVERS_CHAINED-1; 
							state <= 32'd0;
						end else if (ENC_SAYS_GO) begin
							LAT <= '1;
							daisy_num <= NUM_DRIVERS_CHAINED-1; 
							state <= 32'd0;
						end else begin
							state <= 32'd11;
						end 
					end
					
				default:
					state <= 32'd0;
			endcase
		end
	end
	*/
endmodule