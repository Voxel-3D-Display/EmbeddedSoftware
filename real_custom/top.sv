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
		.c1(TESTCLK),    		// sclk_x2.clk // unused
		.c2(SDRAM_CLKn),
		.c3(PIXCLK)
	);

	reg   wrreq;
	logic	[8:0]  rdusedw;
	reg   [15:0]   HDMI_fifo_Data;
	reg   HDMI_fifo_Enable;

	logic waitRequest; //generated by SDRAM; tells us when SDRAM is unavailable due to performing a refresh

	reg [2:0] refreshCnt;
	assign HDMI_fifo_Enable = (m_state == 1)  && !waitRequest;
	assign wrreq = DE && (refreshCnt == 0); //only read in every fourth frame

	HDMI_fifo hdmi(
		.data({HDMI_RGB[2][7:3], HDMI_RGB[1][7:2], HDMI_RGB[0][7:3]}), //input
		
		.wrclk(PIXCLK), //clock rate for writing to FIFO CHNAGE BACK TO PIXCLK!!!!
		.wrreq, //input - high to request to write to the FIFO
		
		.rdclk(SDRAM_CLKn), //CHANGE to SDRAM clock - clock rate for reading
		.rdreq(HDMI_fifo_Enable), //high to request read from FIFO
		.q(HDMI_fifo_Data), //output
		.rdusedw //8 bit width output (unused?)
	);

	//used to update refreshCnt - we only write every 4th frame to the FIFO/SDRAM
	always_ff@(posedge PIXCLK) begin //CHANGE BACK TO PIXCLK!!!!
		if (!nReset) begin
			refreshCnt <= '0;
		end else begin
			if(VSYNC) begin
				if (refreshCnt == 3) begin
					refreshCnt <= 0;
				end else begin
					refreshCnt <= refreshCnt + 1;
				end
			end
		end
	end
	
	logic memWriteRequest;
	assign memWriteRequest = (m_state == 1); //waitrequest handled in state machine
	//do we want to have the m_state == 2 in here?
	assign nRead = ((m_state == 3 || m_state == 2) && !waitRequest) ? 1'b0 : 1'b1; //  && readRequestCnt < BURST_SIZE) ? 1'b0 : 1'b1 ;
	reg [15:0] read_LED_data;

	//SDRAM block
	unsaved sdram(
		.clk_clk(SDRAM_CLKn),   //SDRAM_CLKn
		.reset_reset_n(nReset),
		.new_sdram_controller_0_s1_address(Address),       		//input - address to read or write
		.new_sdram_controller_0_s1_byteenable_n('0),
		.new_sdram_controller_0_s1_chipselect('1),
		.new_sdram_controller_0_s1_writedata(HDMI_fifo_Data),     	//input - 16 bits (one word) to write
		.new_sdram_controller_0_s1_read_n(nRead),        		    //input - read enable
		.new_sdram_controller_0_s1_write_n(!memWriteRequest),  		//input - write enable
		.new_sdram_controller_0_s1_readdata(read_LED_data),     	//output - 16 bits of data 
		.new_sdram_controller_0_s1_readdatavalid(readDataValid), 	//output - tells us if readdata is valid
		.new_sdram_controller_0_s1_waitrequest(waitRequest),   		//output - tells if SDRAM performing periodic refresh
		
		//IO to the external SDRAM chip - we just have to have the right pins
		.new_sdram_controller_0_wire_addr(SDRAM_ADDR),
		.new_sdram_controller_0_wire_ba(SDRAM_BA),
		.new_sdram_controller_0_wire_cas_n(SDRAM_CAS_N),
		.new_sdram_controller_0_wire_cke(SDRAM_CKE),
		.new_sdram_controller_0_wire_cs_n(SDRAM_CS_N),
		.new_sdram_controller_0_wire_dq(SDRAM_DQ),
		.new_sdram_controller_0_wire_dqm(SDRAM_DQM),
		.new_sdram_controller_0_wire_ras_n(nRAS),
		.new_sdram_controller_0_wire_we_n(SDRAM_WE_N)
	);

	//testing ideas: just display what we are writing into SDRAM and what we are reading out
	//the online example projects suggested using 0x08000000 as the base address, but I couldn't
	//find a way to change it

	reg [1339:0][23:0] LED_data_1;
	reg [1339:0][23:0] LED_data_2;
	reg array_in_use;
	reg slice_read_complete;
	//assign read_LED_data = readLedData; //translate to register for indexing?

	localparam WRITE_BURST_SIZE = 8; //write 8 words at once to SDRAM
	localparam READ_BURST_SIZE = 8; //read 8 words at once from SDRAM

	reg [$clog2(WRITE_BURST_SIZE)-1:0] readCnt; //count up to 8 writes 
	reg [$clog2(WRITE_BURST_SIZE)-1:0] writeCnt; //count up to 8 reads
	reg [2:0] m_state;
	reg [23:0] writeAddress;
	reg [23:0] readAddress;
	logic [23:0] Address;
	assign Address = m_state == 1 ? writeAddress : readAddress; //select read or write addr to send to SDRAM

	logic write_request;
	reg read_request;
	logic read_data_valid;
	logic [10:0] pixel_read_cnt; //fix sizing
	reg [10:0] slice_cnt; //fix sizing
	reg need_new_slice;

	always_ff@(posedge SDRAM_CLKn) begin //SDRAM_CLKn
		//state machine here for determining when to read and when to write and where
		if (!nReset) begin
				read_request <= '0;
                readCnt <= '0;
				m_state <= '0;
				slice_cnt <= '0;
				readAddress <= '0;
				slice_read_complete <= 0;
				writeAddress <= 0;
            end else begin
				if(VSYNC) begin //reached end of a frame - move on to next one
					//idk how this make sense if we are cutting out 3 of every four frames
					writeAddress <= 0; //could be written twice in one clock edge? But no errors
				end
				if(need_new_slice) begin //LED state machine puts this high when we can start 
					//to populate the next array
					read_request <= '1;
					//this gets set back to zero in the state machine after we read a slice
				end

				case(m_state)
					0:
						begin
							if(write_request) begin //want to write to sdram
								m_state <= 1;
								writeCnt <= '0;
							end else begin //want to read from sdram
								m_state <= 2;
							end
						end
					1: //state for writing to SDRAM
						begin
							if(!waitRequest) begin //amke sure SDRAM isn't otherwise occupied
								writeCnt <= writeCnt + 1;
								writeAddress <= writeAddress + 1; //increment addr

								if (writeCnt == WRITE_BURST_SIZE -1 || !write_request) begin
									//once we have full burst or nothing else to write, move on
									m_state <= 2;
								end
							end
						end
					2: //we get when there's no write request OR just finished write burst
						begin
							if(read_request) begin
								readCnt <= '0; //for writes and reads?
								//pixel_read_cnt <= '0;
								m_state <= 3;
							end else begin
								m_state <= 0; //no read request - back to start state
							end
						end
					3: //state for reading from SDRAM
						begin
							if(read_data_valid) begin
								readCnt <= readCnt + 1;
								pixel_read_cnt <= pixel_read_cnt + 1;
								readAddress <= readAddress + 1; //address for next clock cycle
								//each read will return a 'full' pixel
								//any reason we'd have to delay a cycle before doing this
								//^I don't think so bc read was high in state 2, and the address was correct
								if (array_in_use == 0) begin
									//as we read it out, make it 24 bits again
									LED_data_2[readAddress] <= {read_LED_data[15:11], 3'b000, read_LED_data[10:5], 2'b00, read_LED_data[4:0], 3'b000};
								end else begin
									LED_data_1[readAddress] <= {read_LED_data[15:11], 3'b000, read_LED_data[10:5], 2'b00, read_LED_data[4:0], 3'b000};
								end
								if (pixel_read_cnt == 1440) begin 
									//have iterated through all the pixels in a slice
									pixel_read_cnt <= '0;
									readAddress <= readAddress + 480; //get to next row (1920-1440)
									slice_cnt <= slice_cnt + 1;
									slice_read_complete <= 1;
									read_request <= '0; //stop reading till LED tells us to start again
									if (slice_cnt == 720) begin
										//have iterated through an entire frame
										readAddress <= '0;
										slice_cnt <= '0;
									end
									m_state <= 0;
								end else begin
									slice_read_complete <= 0;
									//should this be -2 and not -1?
									if(readCnt == READ_BURST_SIZE - 1) begin
										readCnt <= 0;
										m_state <= 0;
									end
								end
							end
							//should we go to a different state next time if the read data was not valid?
						end
					default:
						m_state <= 0;
				endcase
			end
	end

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
						data[LATCH_SIZE-1:0] <= 0;	
						if (init) begin
							state <= 32'd1;	
						end else begin
							//HDMI start
							need_new_slice <= 1; //triggers HDMI to start populating new slice
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

						for (led_channel=0; led_channel<16; led_channel=led_channel+1) begin   
							data[(16*0+3*16*led_channel) +: 16] <= 16'hAFFE;     // red color brightness
							data[(16*1+3*16*led_channel) +: 16] <= 16'h0;  // green color brightness
							data[(16*2+3*16*led_channel) +: 16] <= 16'hAFFE;     // blue color brightness
						end
						//HDMI start
						//does this go here or ar the end of state 1?
						need_new_slice <= 1;
						array_in_use <= !array_in_use;
						//HDMI end
						state <= 32'd3;
					end  

				32'd3: // load 
					begin
						need_new_slice <= 0;
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