`timescale 1 ps / 1 ps


module led_matrix
	(
		TLC5955 led_drivers[11:0][3:0], 
		input 	CLK,
		input	ENC_SAYS_GO,
		input    DE, //tells us if we are getting an HSYNC/VSYNC rn or normal data
		input 	nReset,
		input   reg LED_data[11:0][3:0][47:0],
		output 	reg LAT,
		output 	reg SCLK,
		output 	GSCLK,
		output 	TESTCLK,
		output	reg [3:0] STATE_CHECK,

	);

	reg [1439:0][23:0] LED_data_1;
	reg [1439:0][23:0] LED_data_2;
	reg [1439:0][23:0] LED_data_3;
	integer x;
	integer y;
	
	reg array_in_use;
	reg slice_read_complete;
	//assign read_LED_data = readLedData; //translate to register for indexing?

	logic write_request;
	reg read_request;
	logic read_data_valid;
	logic [10:0] pixel_read_cnt; //fix sizing
	reg [10:0] slice_cnt; //fix sizing
	reg need_new_slice;


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
	
	always@(posedge TESTCLK) begin
		if (!nReset) begin
			state <= 32'd0; // initialize
			LAT <= '0;
			SCLK <= '0;
			bit_num <= LATCH_SIZE;
			daisy_num <= NUM_DRIVERS_CHAINED-1; 
			init <= 1;
			//HDMI start
			need_new_slice <= 0; //don't need slice on start up; control bits first
			array_in_use <= 0;
			//HDMI end
		end else begin
			case (state)
				32'd0:	// re-initialize
					begin
						LAT <= '0;
						SCLK <= '0;
						bit_num <= LATCH_SIZE;
						data[0][0] <= 769'd0;
						data[0][1] <= 769'd0;
						data[0][2] <= 769'd0;
						data[0][3] <= 769'd0;
						data[1][0] <= 769'd0;
						data[1][1] <= 769'd0;
						data[1][2] <= 769'd0;
						data[1][3] <= 769'd0;
						data[2][0] <= 769'd0;
						data[2][1] <= 769'd0;
						data[2][2] <= 769'd0;
						data[2][3] <= 769'd0;
						data[3][0] <= 769'd0;
						data[3][1] <= 769'd0;
						data[3][2] <= 769'd0;
						data[3][3] <= 769'd0;
						data[4][0] <= 769'd0;
						data[4][1] <= 769'd0;
						data[4][2] <= 769'd0;
						data[4][3] <= 769'd0;
						data[5][0] <= 769'd0;
						data[5][1] <= 769'd0;
						data[5][2] <= 769'd0;
						data[5][3] <= 769'd0;
						data[6][0] <= 769'd0;
						data[6][1] <= 769'd0;
						data[6][2] <= 769'd0;
						data[6][3] <= 769'd0;
						data[7][0] <= 769'd0;
						data[7][1] <= 769'd0;
						data[7][2] <= 769'd0;
						data[7][3] <= 769'd0;
						data[8][0] <= 769'd0;
						data[8][1] <= 769'd0;
						data[8][2] <= 769'd0;
						data[8][3] <= 769'd0;
						data[9][0] <= 769'd0;
						data[9][1] <= 769'd0;
						data[9][2] <= 769'd0;
						data[9][3] <= 769'd0;
						data[10][0] <= 769'd0;
						data[10][1] <= 769'd0;
						data[10][2] <= 769'd0;
						data[10][3] <= 769'd0;
						data[11][0] <= 769'd0;
						data[11][1] <= 769'd0;
						data[11][2] <= 769'd0;
						data[11][3] <= 769'd0;
						if (init) begin
							state <= 32'd1;	
						end else begin
							//HDMI start
							need_new_slice <= enc_transition; //triggers HDMI to start populating new slice
							array_in_use <= !array_in_use;
							//HDMI end
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

						// for (led_channel=0; led_channel<16; led_channel=led_channel+1) begin   
						// 	data[(16*0+3*16*led_channel) +: 16] <= 16'h8000;     // red color brightness
						// 	data[(16*1+3*16*led_channel) +: 16] <= 16'h8000;  // green color brightness
						// 	data[(16*2+3*16*led_channel) +: 16] <= 16'h8000;     // blue color brightness
						// end

						
						if (daisy_num == 1) begin		// furthest led driver (last in daisy chain)
							data[0][0][0+:LATCH_SIZE-1] <= hdmi_data[0+:16];
							data[0][1][0+:LATCH_SIZE-1] <= hdmi_data[32+:16];
							data[0][2][0+:LATCH_SIZE-1] <= hdmi_data[64+:16];
							data[0][3][0+:LATCH_SIZE-1] <= hdmi_data[96+:16];
							data[1][0][0+:LATCH_SIZE-1] <= hdmi_data[120+:16];
							data[1][1][0+:LATCH_SIZE-1] <= hdmi_data[152+:16];
							data[1][2][0+:LATCH_SIZE-1] <= hdmi_data[184+:16];
							data[1][3][0+:LATCH_SIZE-1] <= hdmi_data[216+:16];
							data[2][0][0+:LATCH_SIZE-1] <= hdmi_data[240+:16];
							data[2][1][0+:LATCH_SIZE-1] <= hdmi_data[272+:16];
							data[2][2][0+:LATCH_SIZE-1] <= hdmi_data[304+:16];
							data[2][3][0+:LATCH_SIZE-1] <= hdmi_data[336+:16];
							data[3][0][0+:LATCH_SIZE-1] <= hdmi_data[360+:16];
							data[3][1][0+:LATCH_SIZE-1] <= hdmi_data[392+:16];
							data[3][2][0+:LATCH_SIZE-1] <= hdmi_data[424+:16];
							data[3][3][0+:LATCH_SIZE-1] <= hdmi_data[456+:16];
							data[4][0][0+:LATCH_SIZE-1] <= hdmi_data[480+:16];
							data[4][1][0+:LATCH_SIZE-1] <= hdmi_data[512+:16];
							data[4][2][0+:LATCH_SIZE-1] <= hdmi_data[544+:16];
							data[4][3][0+:LATCH_SIZE-1] <= hdmi_data[576+:16];
							data[5][0][0+:LATCH_SIZE-1] <= hdmi_data[600+:16];
							data[5][1][0+:LATCH_SIZE-1] <= hdmi_data[632+:16];
							data[5][2][0+:LATCH_SIZE-1] <= hdmi_data[664+:16];
							data[5][3][0+:LATCH_SIZE-1] <= hdmi_data[696+:16];
							data[6][0][0+:LATCH_SIZE-1] <= hdmi_data[720+:16];
							data[6][1][0+:LATCH_SIZE-1] <= hdmi_data[752+:16];
							data[6][2][0+:LATCH_SIZE-1] <= hdmi_data[784+:16];
							data[6][3][0+:LATCH_SIZE-1] <= hdmi_data[816+:16];
							data[7][0][0+:LATCH_SIZE-1] <= hdmi_data[840+:16];
							data[7][1][0+:LATCH_SIZE-1] <= hdmi_data[872+:16];
							data[7][2][0+:LATCH_SIZE-1] <= hdmi_data[904+:16];
							data[7][3][0+:LATCH_SIZE-1] <= hdmi_data[936+:16];
							data[8][0][0+:LATCH_SIZE-1] <= hdmi_data[960+:16];
							data[8][1][0+:LATCH_SIZE-1] <= hdmi_data[992+:16];
							data[8][2][0+:LATCH_SIZE-1] <= hdmi_data[1024+:16];
							data[8][3][0+:LATCH_SIZE-1] <= hdmi_data[1056+:16];
							data[9][0][0+:LATCH_SIZE-1] <= hdmi_data[1080+:16];
							data[9][1][0+:LATCH_SIZE-1] <= hdmi_data[1112+:16];
							data[9][2][0+:LATCH_SIZE-1] <= hdmi_data[1144+:16];
							data[9][3][0+:LATCH_SIZE-1] <= hdmi_data[1176+:16];
							data[10][0][0+:LATCH_SIZE-1] <= hdmi_data[1200+:16];
							data[10][1][0+:LATCH_SIZE-1] <= hdmi_data[1232+:16];
							data[10][2][0+:LATCH_SIZE-1] <= hdmi_data[1264+:16];
							data[10][3][0+:LATCH_SIZE-1] <= hdmi_data[1296+:16];
							data[11][0][0+:LATCH_SIZE-1] <= hdmi_data[1320+:16];
							data[11][1][0+:LATCH_SIZE-1] <= hdmi_data[1352+:16];
							data[11][2][0+:LATCH_SIZE-1] <= hdmi_data[1384+:16];
							data[11][3][0+:LATCH_SIZE-1] <= hdmi_data[1416+:16];
						end else if (daisy_num == 0) begin		// closest led driver (first in daisy chain)
							data[0][0][0+:LATCH_SIZE-1] <= hdmi_data[15+:16];
							data[0][1][0+:LATCH_SIZE-1] <= hdmi_data[47+:16];
							data[0][2][0+:LATCH_SIZE-1] <= hdmi_data[79+:16];
							data[0][3][0+:LATCH_SIZE-1] <= hdmi_data[111+:16];
							data[1][0][0+:LATCH_SIZE-1] <= hdmi_data[135+:16];
							data[1][1][0+:LATCH_SIZE-1] <= hdmi_data[167+:16];
							data[1][2][0+:LATCH_SIZE-1] <= hdmi_data[199+:16];
							data[1][3][0+:LATCH_SIZE-1] <= hdmi_data[231+:16];
							data[2][0][0+:LATCH_SIZE-1] <= hdmi_data[255+:16];
							data[2][1][0+:LATCH_SIZE-1] <= hdmi_data[287+:16];
							data[2][2][0+:LATCH_SIZE-1] <= hdmi_data[319+:16];
							data[2][3][0+:LATCH_SIZE-1] <= hdmi_data[351+:16];
							data[3][0][0+:LATCH_SIZE-1] <= hdmi_data[375+:16];
							data[3][1][0+:LATCH_SIZE-1] <= hdmi_data[407+:16];
							data[3][2][0+:LATCH_SIZE-1] <= hdmi_data[439+:16];
							data[3][3][0+:LATCH_SIZE-1] <= hdmi_data[471+:16];
							data[4][0][0+:LATCH_SIZE-1] <= hdmi_data[495+:16];
							data[4][1][0+:LATCH_SIZE-1] <= hdmi_data[527+:16];
							data[4][2][0+:LATCH_SIZE-1] <= hdmi_data[559+:16];
							data[4][3][0+:LATCH_SIZE-1] <= hdmi_data[591+:16];
							data[5][0][0+:LATCH_SIZE-1] <= hdmi_data[615+:16];
							data[5][1][0+:LATCH_SIZE-1] <= hdmi_data[647+:16];
							data[5][2][0+:LATCH_SIZE-1] <= hdmi_data[679+:16];
							data[5][3][0+:LATCH_SIZE-1] <= hdmi_data[711+:16];
							data[6][0][0+:LATCH_SIZE-1] <= hdmi_data[735+:16];
							data[6][1][0+:LATCH_SIZE-1] <= hdmi_data[767+:16];
							data[6][2][0+:LATCH_SIZE-1] <= hdmi_data[799+:16];
							data[6][3][0+:LATCH_SIZE-1] <= hdmi_data[831+:16];
							data[7][0][0+:LATCH_SIZE-1] <= hdmi_data[855+:16];
							data[7][1][0+:LATCH_SIZE-1] <= hdmi_data[887+:16];
							data[7][2][0+:LATCH_SIZE-1] <= hdmi_data[919+:16];
							data[7][3][0+:LATCH_SIZE-1] <= hdmi_data[951+:16];
							data[8][0][0+:LATCH_SIZE-1] <= hdmi_data[975+:16];
							data[8][1][0+:LATCH_SIZE-1] <= hdmi_data[1007+:16];
							data[8][2][0+:LATCH_SIZE-1] <= hdmi_data[1039+:16];
							data[8][3][0+:LATCH_SIZE-1] <= hdmi_data[1071+:16];
							data[9][0][0+:LATCH_SIZE-1] <= hdmi_data[1095+:16];
							data[9][1][0+:LATCH_SIZE-1] <= hdmi_data[1127+:16];
							data[9][2][0+:LATCH_SIZE-1] <= hdmi_data[1159+:16];
							data[9][3][0+:LATCH_SIZE-1] <= hdmi_data[1191+:16];
							data[10][0][0+:LATCH_SIZE-1] <= hdmi_data[1215+:16];
							data[10][1][0+:LATCH_SIZE-1] <= hdmi_data[1247+:16];
							data[10][2][0+:LATCH_SIZE-1] <= hdmi_data[1279+:16];
							data[10][3][0+:LATCH_SIZE-1] <= hdmi_data[1311+:16];
							data[11][0][0+:LATCH_SIZE-1] <= hdmi_data[1335+:16];
							data[11][1][0+:LATCH_SIZE-1] <= hdmi_data[1367+:16];
							data[11][2][0+:LATCH_SIZE-1] <= hdmi_data[1399+:16];
							data[11][3][0+:LATCH_SIZE-1] <= hdmi_data[1431+:16];
						end
						state <= 32'd3;
					end  

				32'd3: // load 
					begin
						SCLK <= '0;
						if (bit_num != '0) begin
							//HDMI start
							//might be easier to make LED_data_1/2 into [48][30][24] arrays instead of current [1440][24]
							//current indexing into LED_data is random/not correct
							/*
							if (init) begin 
								SDO[11][3] <= data[bit_num-1] ;
								SDO[11][2] <= data[bit_num-1] ;
								SDO[11][1] <= data[bit_num-1] ; 
								SDO[11][0] <= data[bit_num-1] ; 
							end else if (array_in_use == 0) begin
								SDO[11][3] = LED_data_1[0][0];
								SDO[11][2] = LED_data_1[1][0];
								SDO[11][1] = LED_data_1[2][0];
								SDO[11][0] = LED_data_1[3][0];
							end else begin
								SDO[11][3] = LED_data_2[0][0];
								SDO[11][2] = LED_data_2[1][0];
								SDO[11][1] = LED_data_2[2][0];
								SDO[11][0] = LED_data_2[3][0];
							end
							*/
							//HDMI end
							//HDMI code above would replace nexct 4 lines
							
							SDO[0][0] <= data[0][0][bit_num-1];
							SDO[0][1] <= data[0][1][bit_num-1];
							SDO[0][2] <= data[0][2][bit_num-1];
							SDO[0][3] <= data[0][3][bit_num-1];
							SDO[1][0] <= data[1][0][bit_num-1];
							SDO[1][1] <= data[1][1][bit_num-1];
							SDO[1][2] <= data[1][2][bit_num-1];
							SDO[1][3] <= data[1][3][bit_num-1];
							SDO[2][0] <= data[2][0][bit_num-1];
							SDO[2][1] <= data[2][1][bit_num-1];
							SDO[2][2] <= data[2][2][bit_num-1];
							SDO[2][3] <= data[2][3][bit_num-1];
							SDO[3][0] <= data[3][0][bit_num-1];
							SDO[3][1] <= data[3][1][bit_num-1];
							SDO[3][2] <= data[3][2][bit_num-1];
							SDO[3][3] <= data[3][3][bit_num-1];
							SDO[4][0] <= data[4][0][bit_num-1];
							SDO[4][1] <= data[4][1][bit_num-1];
							SDO[4][2] <= data[4][2][bit_num-1];
							SDO[4][3] <= data[4][3][bit_num-1];
							SDO[5][0] <= data[5][0][bit_num-1];
							SDO[5][1] <= data[5][1][bit_num-1];
							SDO[5][2] <= data[5][2][bit_num-1];
							SDO[5][3] <= data[5][3][bit_num-1];
							SDO[6][0] <= data[6][0][bit_num-1];
							SDO[6][1] <= data[6][1][bit_num-1];
							SDO[6][2] <= data[6][2][bit_num-1];
							SDO[6][3] <= data[6][3][bit_num-1];
							SDO[7][0] <= data[7][0][bit_num-1];
							SDO[7][1] <= data[7][1][bit_num-1];
							SDO[7][2] <= data[7][2][bit_num-1];
							SDO[7][3] <= data[7][3][bit_num-1];
							SDO[8][0] <= data[8][0][bit_num-1];
							SDO[8][1] <= data[8][1][bit_num-1];
							SDO[8][2] <= data[8][2][bit_num-1];
							SDO[8][3] <= data[8][3][bit_num-1];
							SDO[9][0] <= data[9][0][bit_num-1];
							SDO[9][1] <= data[9][1][bit_num-1];
							SDO[9][2] <= data[9][2][bit_num-1];
							SDO[9][3] <= data[9][3][bit_num-1];
							SDO[10][0] <= data[10][0][bit_num-1];
							SDO[10][1] <= data[10][1][bit_num-1];
							SDO[10][2] <= data[10][2][bit_num-1];
							SDO[10][3] <= data[10][3][bit_num-1];
							SDO[11][0] <= data[11][0][bit_num-1];
							SDO[11][1] <= data[11][1][bit_num-1];
							SDO[11][2] <= data[11][2][bit_num-1];
							SDO[11][3] <= data[11][3][bit_num-1];
							
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