`timescale 1 ps / 1 ps

module top
	(
		input 	 CLK_10M,
		input	 	ENC_ABS_HOME,
		input 	 ENC_360,
		input 	 [2:0][7:0]   HDMI_RGB, //UNCOMMENT TO TEST HDMI
		input    logic VSYNC,
		input    logic HSYNC,
		input    logic PIXCLK, //UNCOMMENT TO TEST HDMI; CHECK PIN
		input    logic DE, //CHECK PIN
		input    logic ACTIVE,
		input 	nReset,
		output 	wire LAT,
		output 	wire SCLK,
		output 	reg GSCLK,
		output 	TESTCLK,
		output   bit [11:0][3:0] SDO,

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

		//output                      array_debug,
		//output        [15:0]        led_debug,
		//output                      valid_debug,
		//output         [15:0]       fifo_out,
		//output         [1:0]        refresh,
		//output                      empty
	);
	
	
	//HDMI testing start
	reg [15:0] HDMI_RGB_t;
	//HDMI testing end

	//assign led_debug = read_LED_data; // HDMI_RGB_t; //CHANGE TO HDMI_RGB to see what HDMI is inputting
	//assign valid_debug = read_data_valid;
	//assign fifo_out = HDMI_fifo_Data;
	reg ENC_SAID_GO = 0; // NEW FOR ENCODER HANDLING // represents [last, next]
    // logic ENC_SAYS_GO = 0; // OLD WITH TESTCLK
	//assign pix = pixel_read_cnt[0];
	//assign refresh = refreshCnt;
	//assign empty = buf_empty;

	logic SDRAM_CLKn;
	assign SDRAM_CLK = !SDRAM_CLKn;
	//logic PIXCLK;

	pll pll(
		.inclk0(CLK_10M),  			//  clk_in.clk
		.c0(GSCLK),     			//   gsclk.clk
		.c1(TESTCLK),    			// sclk_x2.clk // unused
		.c2(SDRAM_CLKn),            //25MHz
		//.c3(PIXCLK)                 //12.5MHz
	);


	/*
	led_matrix matrix(
		.CLK(TESTCLK),
//		.memory_data((array_in_use ? LED_data_2 : LED_data_1)),
		.memory_data(LED_data_2),
		.SDO,
		.LAT,
		.SCLK,
		.nReset,
		.ENC_SAYS_GO,
		.reading_memory(need_new_LED_data)
	);
	*/

	logic   wrreq;
	logic	[8:0]  rdusedw;
	logic   [15:0]   HDMI_fifo_Data;
	reg   [15:0]   testing_HDMI_fifo_Data;
	reg   HDMI_fifo_Enable;
	reg array_in_use;
	assign array_debug = array_in_use;

	logic waitRequest; //generated by SDRAM; tells us when SDRAM is unavailable due to performing a refresh
	logic buf_empty;
	logic [10:0] cur_buf_size; //cur number words stored in fifo
	logic write_full; //should NEVER be high - indicates FIFO is full
	logic [15:0] hdmi_stuff;
	assign hdmi_stuff = {HDMI_RGB[2][7:3], HDMI_RGB[1][7:2], HDMI_RGB[0][7:3]};

	assign HDMI_fifo_Enable = (m_state == 1)  && !waitRequest && !buf_empty;
	assign wrreq = DE && (col_counter < 12'd768) && (row_counter < 12'd720); // && 
	/*
	reg [2:0][7:0] fake_HDMI;
	reg [5:0] hehe_counter;
	always_ff@(negedge PIXCLK) begin //pos or neg edge???
		if (!nReset) begin
			fake_HDMI <= 24'h00FF00;
			hehe_counter <= '0;
		end else begin
			if (hehe_counter == 47) begin
				hehe_counter <= '0;
				fake_HDMI <= ~fake_HDMI;
			end else begin
				hehe_counter <= hehe_counter + 1;
			end
			
		end
	end
	*/
	
	logic[39:0] hdmi_fifo_output;
	HDMI_fifo hdmi(
		.data({HDMI_RGB[0][7:3], HDMI_RGB[1][7:2], HDMI_RGB[2][7:3], new_writeAddress}), //(col_counter < 12'd768) ? 16'b0000011111100000 : 16'b1111100000000000), //input //CHANGE TO{HDMI_RGB[2][7:3], HDMI_RGB[1][7:2], HDMI_RGB[0][7:3]} TO TEST HDMI
		//{HDMI_RGB[2][7:3], HDMI_RGB[1][7:2], HDMI_RGB[0][7:3]})
		.wrclk(!PIXCLK), //clock rate for writing to FIFO
		.wrreq(wrreq), //input - high to request to write to the FIFO
		
		.rdclk(SDRAM_CLKn), //CHANGE to SDRAM clock - clock rate for reading
		.rdreq(HDMI_fifo_Enable), //high to request read from FIFO //!buf_empty
		.q(hdmi_fifo_output), //output
		.rdempty(buf_empty),
		.rdusedw(cur_buf_size), //8 bit width output (unused?)
		.wrfull(write_full)
	);
	
	assign HDMI_fifo_Data = hdmi_fifo_output[39:24];
	assign test_write_address = hdmi_fifo_output[23:0];

	//what if we made an address fifo???
	logic addr_buf_empty;
	logic [10:0] addr_cur_buf_size; //cur number words stored in fifo
	logic addr_write_full; //should NEVER be high - indicates FIFO is full
	reg [23:0] new_writeAddress;
	logic [23:0] test_write_address;

//	addr_fifo addresses(
//		.data(new_writeAddress), //input
//		
//		.wrclk(!PIXCLK), //clock rate for writing to FIFO
//		.wrreq(wrreq), //input - high to request to write to the FIFO
//		
//		.rdclk(SDRAM_CLKn), //CHANGE to SDRAM clock - clock rate for reading
//		.rdreq(HDMI_fifo_Enable), //high to request read from FIFO //!buf_empty
//		.q(test_write_address), //output
//		.rdempty(addr_buf_empty),
//		.rdusedw(addr_cur_buf_size), //11 bit width output (unused?)
//		.wrfull(addr_write_full)
//	);
//	
	reg first;

	always_ff@(negedge PIXCLK) begin //pos or neg edge???
		if (!nReset) begin
			new_writeAddress <= '0;
			first <= '0;
		end else if (!VSYNC && !DE) begin
			new_writeAddress <= '0;
			first <= '1;
		end else if(DE) begin
			new_writeAddress <= new_writeAddress + 1;
		end
	end


	logic [11:0] col_counter;
	logic [11:0] row_counter;
	reg HSYNC_prev;
	reg VSYNC_prev;

	always_ff@(negedge PIXCLK) begin
		if(!nReset) begin
			testing_HDMI_fifo_Data <= '0;
		end else begin
			testing_HDMI_fifo_Data <= testing_HDMI_fifo_Data + 1;
		end
	end

	always_ff@(negedge PIXCLK) begin //does this need to be a posedge?
		if(!nReset) begin
			col_counter <= 0;
		end else begin
			if (DE == 0) begin //we are getting HYSNC and DE is low (sending HSYNC/!VSYNC)
				col_counter <= 0;
			end else begin
				col_counter <= col_counter + 1;
			end
		end
	end

	// always_ff@(negedge PIXCLK) begin
	// 	if(!nReset) begin
	// 		row_counter <= '0;
	// 		HSYNC_prev <= 0;
	// 	end else begin
	// 		if (!VSYNC_prev == '1 && !VSYNC == '0) begin
	// 			row_counter <= '0; // Possibly make -1 based off of timings
	// 		end
	// 		if (HSYNC_prev == )

	// 		if (!VSYNC && (DE == 0)) begin
	// 			row_counter <= '0;
	// 		end else if((DE == 0) && (HSYNC != HSYNC_prev)) begin
	// 			row_counter <= row_counter + 1;
	// 		end
	// 		HSYNC_prev <= HSYNC;
	// 		!VSYNC_prev <= !VSYNC;
	// 	end
	// end

	always_ff@(negedge DE or negedge VSYNC) begin
		if (!VSYNC) begin
			row_counter <= 0;
		end else begin
			row_counter <= row_counter + 1;
		end
	end 

	logic memWriteRequest;
	assign memWriteRequest = (m_state == 1); //waitrequest handled in state machine
	//do we want to have the m_state == 2 in here?
	reg [3:0] read_counter;
	assign nRead = ((m_state == 3) && !waitRequest) ? 1'b0 : 1'b1; //  && readRequestCnt < BURST_SIZE) ? 1'b0 : 1'b1 ; //|| m_state == 2 // (read_counter < READ_BURST_SIZE)
	reg [15:0] read_LED_data;

	//SDRAM block
	reg [3:0] test_switch;
	reg [15:0] test_data = 16'b1111111111111111;
	logic out_SDRAM;
	
	reg [23:0] test_addr;
	logic nRead_test;
	logic nWrite_test;
	assign nRead_test = (test_switch[3] || waitRequest);
	assign nWrite_test = (!test_switch[3] || waitRequest);

	sdram sdram(
		.clk_clk(SDRAM_CLKn),   //SDRAM_CLKn input
		.sys_sdram_pll_0_ref_reset_reset(nReset), //input
		.sys_sdram_pll_0_sdram_clk_clk(out_SDRAM), //output
		//.reset_reset(!nReset),
		//.sdram_clk_clk(out_SDRAM),
		.new_sdram_controller_0_s1_address(Address),       		//input - address to read or write
		.new_sdram_controller_0_s1_byteenable_n('0),
		.new_sdram_controller_0_s1_chipselect('1),
		.new_sdram_controller_0_s1_writedata(hdmi_fifo_output[39:24]),     	//input - HDMI_fifo_Data //Address[15:0]
		.new_sdram_controller_0_s1_read_n(nRead),        		    //input - read enable
		.new_sdram_controller_0_s1_write_n(!memWriteRequest),  		//input - write enable
		.new_sdram_controller_0_s1_readdata(read_LED_data),     	//output - 16 bits of data 
		.new_sdram_controller_0_s1_readdatavalid(read_data_valid), 	//output - tells us if readdata is valid
		.new_sdram_controller_0_s1_waitrequest(waitRequest),   		//output - tells if SDRAM performing periodic refresh
		
		//IO to the external SDRAM chip - we just have to have the right pins
		.new_sdram_controller_0_wire_addr(SDRAM_ADDR),
		.new_sdram_controller_0_wire_ba(SDRAM_BA),
		.new_sdram_controller_0_wire_cas_n(SDRAM_CAS_N),
		.new_sdram_controller_0_wire_cke(SDRAM_CKE),
		.new_sdram_controller_0_wire_cs_n(SDRAM_CS_N),
		.new_sdram_controller_0_wire_dq(SDRAM_DQ),
		.new_sdram_controller_0_wire_dqm(SDRAM_DQM),
		.new_sdram_controller_0_wire_ras_n(SDRAM_RAS_N),
		.new_sdram_controller_0_wire_we_n(SDRAM_WE_N)
	);
	/*
	reg [2:0] test_state;

	always_ff@(posedge CLK_10M) begin //SDRAM_CLKn
//		if (((!nRead_test && read_data_valid) || !nWrite_test) && !waitRequest) begin
//		if (((!nRead_test && read_data_valid) || (!nWrite_test && !read_data_valid)) && !waitRequest) begin
		if (!nRead_test || !nWrite_test) begin
			test_switch <= test_switch + 1;
		end
//		if (!nWrite_test) begin
//					test_switch <= test_switch + 1;
//				end
//		case(test_state)
//			0: begin
//				if(!nRead_test) begin
//					test_state <= 1;
//				end
//				end
//			1:	begin
//				if(read_data_valid) begin
//					test_state <= 2;
//				end
//				end
//			2:	begin
//				if(!read_data_valid) begin
//					test_switch <= test_switch + 1;
//					test_state <= 0;
//				end
//				end
//			default:
//				test_state <= 0;
//			endcase
//		
		test_addr[23:3] <= '0;
		test_addr[2:0] <= test_switch[2:0];
		test_data[15:3] <= '0;
		test_data[2:0] <= test_switch[2:0];
	end
	*/
	
	//the online example projects suggested using 0x08000000 as the base address, but I couldn't
	//find a way to change it

	bit [47:0][47:0] LED_data_1; //[11:0][7:0][767:0];
	bit [47:0][47:0] LED_data_2; //[11:0][7:0][767:0];
	reg trigger;

	reg need_new_LED_data;
	//assign read_LED_data = readLedData; //translate to register for indexing?

	localparam WRITE_BURST_SIZE = 8; //write 8 words at once to SDRAM
	localparam READ_BURST_SIZE = 8; //read 8 words at once from SDRAM

	reg [$clog2(READ_BURST_SIZE)-1:0] readCnt; //count up to 8 writes 
	reg [5:0] writeCnt; //count up to 8 reads
	reg [2:0] m_state;
	reg [23:0] writeAddress;
	reg [23:0] readAddress;
	logic [23:0] Address;
	assign Address = (m_state == 1) ? test_write_address : readAddress; //select read or write addr to send to SDRAM

	reg read_request;
	logic read_data_valid;
	logic [19:0] pixel_read_cnt; //fix sizing
	reg [10:0] slice_cnt; //fix sizing
	reg [10:0] new_slice_cnt; //fix sizing
	reg need_new_slice;

	reg trigger_2;
	reg dummy;
	reg [5:0] SDO_count;

	logic write_request;
	assign write_request = !buf_empty; //is staying high past last address
	//reg [23:0] led_base;
	reg [1:0] new_counter;
	
	reg [1:0] start_counter;
	

	always_ff@(posedge SDRAM_CLKn) begin //SDRAM_CLKn
		//state machine here for determining when to read and when to write and where
		if (!nReset) begin
				read_request <= 0; //change back to zero
            readCnt <= '0;
				m_state <= '0;
				readAddress <= 24'b0;
				//writeAddress <= 24'b0;
				read_counter <= '0;
				trigger <= 1;
				SDO_count <= '0;
				new_counter <= '0;
				start_counter <= '0;
            end else begin
				/*
				if(!VSYNC && !DE) begin //reached end of a frame - move on to next one
					writeAddress <= '0;
				end
				*/
				
				
				if((need_new_LED_data != dummy) && need_new_LED_data) begin
					//have to get this signal before the first ever read from SDRAM
					//make sure SDRAM is always ahead of the LEDs
					// array_in_use <= !array_in_use;
					read_request <= '1;
					readAddress <= need_new_LED_base;
					//this gets set back to zero in the state machine after we read a slice
				end
				dummy <= need_new_LED_data;
				trigger_2 <= 1;

				case(m_state)
					0: //state to decide if we should write or read SDRAM
						begin
							if(write_request) begin //want to write to sdram //write_request
								m_state <= 1;
								writeCnt <= '0;
							end else begin //want to read from sdram
								m_state <= 2;
							end
						end
					1: //state for writing to SDRAM
						begin
							if(!waitRequest) begin //make sure SDRAM isn't otherwise occupied
								writeCnt <= writeCnt + 1;
								//if (writeAddress < 24'd552959) begin //1536 x 360 = 552960 - wait for a full frame of data  //DO WE WANNA UNCOMMENT THIS?
								//writeAddress <= writeAddress + 1; //increment addr
								//end else begin
								//	writeAddress <= '0;
								//end
								if (writeCnt ==  WRITE_BURST_SIZE-1 || !write_request) begin //|| !write_request
									//once we have full burst or nothing else to write, move on
									trigger <= 1;
									m_state <= 2;
								end
							end
						end
					2: //we get when there's no write request OR just finished write burst
						begin
							if(read_request) begin //read_request, plus buffer has enough // && (cur_buf_size > 7)
								readCnt <= '0;
								read_counter <= '0;
								start_counter <= 0;
								m_state <= 3; // 3
							end else begin
								m_state <= 0; //no read request - back to start state
							end
						end
//					4: //sending addresses in burst before read_data_valid
//						begin 
//							
//							
//							if(!read_data_valid) begin
//								m_state <= 0;
//							end
//						end
					3: //state for reading from SDRAM
						begin
							if(!nRead) begin
								read_counter <= read_counter + 1;
							end
							/*
							if (new_counter == 3) begin
								new_counter <= '0;
							end else begin
								new_counter <= new_counter + 1;
							end
							*/
							if(readAddress - need_new_LED_base < 6'd48 && !waitRequest) begin
								readAddress <= readAddress + 1;
							end
							
							if(SDO_count == 6'd48) begin
								SDO_count <= '0;
								read_request <= '0;
								readCnt <= '0;
								m_state <= '0;
							end else begin
								if(read_data_valid) begin //read_data_valid
									readCnt <= readCnt + 1;
									/*
									if (pixel_read_cnt < 20'd552690) begin  //I UNCOMMENTED THIS
										pixel_read_cnt <= pixel_read_cnt + 1;
										readAddress <= readAddress + 1; //address for next clock cycle
									end else begin
										pixel_read_cnt <= '0;
										readAddress <= '0;
									end
									*/
									//any reason we'd have to delay a cycle before doing this
									//^I don't think so bc read was high in state 2, and the address was correct

									if (SDO_count < 6'd48) begin
										if (LED_latch_in_use == '0) begin
											LED_data_2[SDO_count] <= {read_LED_data[15:11], 11'b0, read_LED_data[10:5], 10'b0, read_LED_data[4:0], 11'b0};
										end else begin
											LED_data_1[SDO_count] <= {read_LED_data[15:11], 11'b0, read_LED_data[10:5], 10'b0, read_LED_data[4:0], 11'b0};
										end
										SDO_count <= SDO_count + 1;
										//if(readCnt == READ_BURST_SIZE-2) begin //OUR BURST SIZE IS 48, 2 is CAS?
										//	readCnt <= '0;
										//	m_state <= '0;
										//end
									end else begin
										SDO_count <= '0;
										read_request <= '0;
										readCnt <= '0;
										m_state <= '0;
										//notify the LED matrix we want to switch arrays
									end
									/*
									if (pixel_read_cnt == 1535) begin 
										//have iterated through all the pixels in a slice
										pixel_read_cnt <= '0;
										slice_cnt <= slice_cnt + 1;
										if (slice_cnt == 359) begin
											//have iterated through an entire frame
											readAddress <= '0;
											slice_cnt <= '0;
										end
										readCnt <= 0;
										m_state <= 0;
									end else begin
									*/
										//should this be -2 and not -1?
									//end
								end
							//should we go to a different state next time if the read data was not valid?
							end
						end

						
					default:
						m_state <= 0;
				endcase
			end
	end


	// encoder handling
	localparam NUM_CONSEC_ENC = 'd100; // was 4
	reg [NUM_CONSEC_ENC-1:0] windowing_360;
	reg [NUM_CONSEC_ENC-1:0] windowing_home;
	reg enc_transition = 0; // both home and each transition... in case they aren't synchronous
	reg hadOne_home;
	reg hadOne_360;
	reg last_enc_said_go;
	always@(posedge CLK_10M) begin //50MHZ_CLOCK
		if (!nReset) begin
			windowing_360 <= 100'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
			windowing_home <= 100'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
			new_slice_cnt <= '0;
			hadOne_home <= 0;
			hadOne_360 <= 0;
           enc_transition <= 0;
           last_enc_said_go <= 0;
		end else begin

           // ignoring 360 upper limit on slice count for now
           // resetting on 360 would reset pretty soon after at home-- would be glitchy

           // update windowing for debouncing
			windowing_360 <= (windowing_360 << 1) | ENC_360;
			windowing_home <= (windowing_home << 1) | ENC_ABS_HOME;

           // encoder home
           if (windowing_home == 100'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000) begin // || new_slice_cnt == 'd359) begin
               // don't send encoder_transition on rising edge
					hadOne_home = 0;
           end else if (windowing_home == 100'b1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111) begin
               if (!hadOne_home) begin // || new_slice_cnt == 'd359) begin
                   enc_transition <= 1;
					new_slice_cnt <= 0;
               end
               hadOne_home = 1;
           end

           // encoder transition
           if (windowing_360 == 100'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000) begin
               if (hadOne_360) begin // falling edge transition
                   enc_transition <= 1;
					if (new_slice_cnt < 'd359) begin // max 360 slices
	                    new_slice_cnt <= new_slice_cnt + 1;
					end
	            end
               hadOne_360 = 0;
           end else if (windowing_360 == 100'b1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111) begin
               if (!hadOne_360) begin // rising edge transition
                   enc_transition <= 1;
                   if (new_slice_cnt < 'd359) begin // max 360 slices
	                    new_slice_cnt <= new_slice_cnt + 1;
					end
               end
               hadOne_360 = 1;
           end

           // resetting transitions (prepping for next)
           if (last_enc_said_go != ENC_SAID_GO) begin
               // wait till led state sees transition
               enc_transition <= 0;
               last_enc_said_go <= ENC_SAID_GO;
           end

		end
	end

localparam LATCH_SIZE = 'd769;
	localparam NUM_DRIVERS_CHAINED = 'd2;

	bit [768:0] init_data;
	reg init = 1;	// initialize LED driver with control data latch
	reg [31:0] state = 32'd0;
	reg [9:0] bit_num = LATCH_SIZE;	// bit counter for 769 bit latch
	integer daisy_num = NUM_DRIVERS_CHAINED - 1;	// counter for the driver in the daisy-chain
	
	integer i = 0;	// for-loop counter
	integer n = 0;	// for-loop counter
	integer led_channel = 0;

	reg LED_latch_in_use = '0;

	// Control Data Latch Values
	reg [6:0] dot_corr_r = 7'd127;	// dot correction values for red led driver channels
	reg [6:0] dot_corr_g = 7'd127;	// dot correction values for green led driver channels
	reg [6:0] dot_corr_b = 7'd127;	// dot correction values for blue led driver channels
	reg [2:0] mc_r = 3'd0;	// max current for red
	reg [2:0] mc_g = 3'd0;	// max current for green
	reg [2:0] mc_b = 3'd0;	// max current for blue
	reg [6:0] gbc_r = 7'd20;	// global brightness control for red
	reg [6:0] gbc_g = 7'd20;	// global brightness control for green
	reg [6:0] gbc_b = 7'd20;	// global brightness control for blue
	reg dsprpt = 1'b1; // Auto display repeat mode enable
	reg tmgrst = 1'b1; // Display timing reset mode enable
	reg rfresh = 1'b0; // Auto data refresh mode enable
	reg espwm  = 1'b1; // ES-PWM mode enable
	reg lsdvlt = 1'b1; // LSD detection voltage selection
	bit [47:0][47:0] LED_data_1_test; //[11:0][7:0][767:0];
	bit [47:0][47:0] LED_data_2_test; //[11:0][7:0][767:0];
	bit [47:0][47:0] LED_data_3_test; //[11:0][7:0][767:0];


// // replaced with encoder handling
// reg [11:0] counter_t;
// always@(negedge TESTCLK) begin
// 	counter_t <= counter_t + 1;
// 	if (counter_t == '0) begin
// 		enc_transition <= 1;
//		slice_cnt <= slice_cnt + 1;
// 	end else begin
// 		enc_transition <= 0;
// 	end
// end

reg [23:0] need_new_LED_base;
reg [1:0] delay_counter;

always@(posedge TESTCLK) begin
		if (!nReset) begin
			state <= 32'd0; 
			LAT <= '0;
			SCLK <= '0;
			bit_num <= LATCH_SIZE;
			daisy_num <= NUM_DRIVERS_CHAINED-1; 
			init <= 1;
			need_new_LED_base <= // SET TO SECOND PIXEL
			need_new_LED_data <= 0;
			LED_latch_in_use <= '0;
			slice_cnt <= '0; // OLD WITH TESTCLK
			delay_counter <= '0;
		end else begin
			case (state)
				32'd0:	// Re-init variables
					begin
						LAT <= '0;
						SCLK <= '0;	
						//LED_latch_in_use <= '0;
						need_new_LED_data <= 0;
						bit_num <= LATCH_SIZE; // 769
						// data[767:0] <= 768'd0;	
						delay_counter <= '0;
						if (init) begin
							state <= 32'd1;	
						end else begin
							state <= 32'd8;
						end
					end
				32'd1: // Init: Set init_data
					begin
						// Control Data Latch Bits
						init_data[768] <= 1'b1;
						init_data[767:760] <= 8'h96; 

						// Maximum Current (MC) Data Latch
						init_data[338:336] <= mc_r;		// max red current bits 
						init_data[341:339] <= mc_g;		// max green current bits 
						init_data[344:342] <= mc_b;		// max blue current bits 

						// Global Brightness Control (BC) Data Latch
						init_data[351:345] <= gbc_r;		// global red brightness control bits 
						init_data[358:352] <= gbc_g;		// global green brightness control bits 
						init_data[365:359] <= gbc_b;		// global blue brightness control bits 

						// Dot Correction (DC) Data Latch
						for (led_channel=0; led_channel<16; led_channel=led_channel+1) begin   
							init_data[7*0+3*7*led_channel +: 7] <= dot_corr_r;     // red dot correction
							init_data[7*1+3*7*led_channel +: 7] <= dot_corr_g;  // green dot correction
							init_data[7*2+3*7*led_channel +: 7] <= dot_corr_b;     // blue dot correction
						end

						// Function Control (FC) Data Latch
						init_data[366] <= dsprpt; // Auto display repeat mode enable bit
						init_data[367] <= tmgrst; // Display timing reset mode enable bit
						init_data[368] <= rfresh; // Auto data refresh mode enable bit
						init_data[369] <= espwm; // ES-PWM mode enable bit
						init_data[370] <= lsdvlt; // LSD detection voltage selection bit

						for (i = 0; i < 48; i++) begin
							LED_data_1_test[i] <= 48'hFFFF00000000;
							LED_data_2_test[i] <= 48'h0000FFFF0000;
							LED_data_3_test[i] <= 48'h00000000FFFF;
						end
						
						state <= 32'd2;
					end
				32'd2: // Init: Set SDO lines to shift out init_data
					begin
						SCLK <= '0;
						if (bit_num != 'd0)	begin 	// continue shifting out bits		 
							for (i = 0; i < 12; i++) begin
								for (n = 0; n < 4; n++) begin
									//if (i != 1) begin // Artificially skip drivers
										SDO[i][n] <= init_data[bit_num - 1];
									//end
								end
							end
							state <= 32'd3;
						end else begin		// if all bits have been shifted out
							if (daisy_num != '0) begin
								daisy_num <= daisy_num - 1;
								state <= 32'd0; 
							end else begin 
								state <= 32'd11;
							end
						end
					end
				32'd3: // Init: Raise Clock and decrement bit_num.
					begin
						SCLK <= '1;
						bit_num <= bit_num - 1;
						state <= 32'd2; 
					end
				
				32'd8: // GS Data (regular op): Set SDO lines to shift out data.
					begin 
						SCLK <= '0;
						if (bit_num == LATCH_SIZE) begin
							for (i = 0; i < 12; i++) begin
								for (n = 0; n < 4; n++) begin
									//if (i != 1) begin // Artificially skip drivers
										SDO[i][n] <= '0; // Set control bit flag
									//end
								end
							end
							state <= 'd9;
						end else if (bit_num != '0) begin 
							for (i = 0; i < 12; i++) begin
								for (n = 0; n < 4; n++) begin
										if (LED_latch_in_use == '0) begin
											SDO[i][n] <= LED_data_1[i*4 + n][(bit_num-1) % 48];
										end else begin
											SDO[i][n] <= LED_data_2[i*4 + n][(bit_num-1) % 48];
										end
									//end
								end
							end
							state <= 32'd9;
						end else begin 
							if (daisy_num != '0) begin
								daisy_num <= daisy_num - 1;
								state <= 32'd0; 
							end else begin 
								state <= 32'd11;
							end
						end
					end

				32'd9: // GS Data (regular op): Raise Clock and decrement bit_num.
					begin
					
						if ((bit_num-1) % 48 == 'b0 && bit_num != LATCH_SIZE && bit_num != '0) begin
							delay_counter <= delay_counter + 1;
//								if (delay_counter == 2'b11) begin
							// if (((bit_num-1) == 'b0) && (daisy_num == 'b0) && (slice_cnt == 'd359)) begin
							// 	need_new_LED_base <= 'd0;
							// end else if (((bit_num-1) == '0) && (daisy_num == 'b1)) begin
							// 	need_new_LED_base <= 'd1280*('d2*slice_cnt + 'd1);
							// end else if (((bit_num-1) == '0) && (daisy_num == 'b0)) begin
							// 	need_new_LED_base <= 'd1280*('d2*(slice_cnt + 'd1));
							LED_latch_in_use <= !LED_latch_in_use;
						
							if ((bit_num-1) == 'd48 && daisy_num == 'b0 && slice_cnt == 'd359) begin
								need_new_LED_base <= 'd0;
							end else if ((bit_num-1) == 'd0 && daisy_num == 'b0 && slice_cnt == 'd359) begin
								need_new_LED_base <= 'd48;
							end else if ((bit_num-1) == 'd0 && daisy_num == 'b1) begin
								need_new_LED_base <= 'd1280*('d2*slice_cnt + 'd1) + 'd48;
							end else if ((bit_num-1) == 'd0 && daisy_num == 'b0) begin
								need_new_LED_base <= 'd1280*('d2*(slice_cnt + 'd1)) + 'd48;
							end else if ((bit_num-1) == 'd48 && daisy_num == 'b1) begin
								need_new_LED_base <= 'd1280*('d2*slice_cnt + 'd1);
							end else if ((bit_num-1) == 'd48 && daisy_num == 'b0) begin
								need_new_LED_base <= 'd1280*('d2*(slice_cnt + 'd1));
							end else begin
								need_new_LED_base <= 'd1280*('d2*slice_cnt + ('d1 - daisy_num)) + 'd48*('d17 - (bit_num-1)/48);
//									need_new_LED_base <= 'd48*(('d16 - (bit_num-1)/48 + 'd16*(('d1 - daisy_num) + 'd2*slice_cnt)));
							end
							need_new_LED_data <= '1;
						end else begin 
							need_new_LED_data <= '0;
						end
						SCLK <= '1;
						bit_num <= bit_num - 1;
						state <= 32'd8;
					end

				32'd11: // latch 
					begin
						// proceed only if initializing or when encoder says go
						if (init) begin
							init <= '0;
							LAT <= '1;
							daisy_num <= NUM_DRIVERS_CHAINED-1; 
							state <= 32'd0;
						// end else if (ENC_SAYS_GO) begin // OLD WITH TESTCLK
						// 	LAT <= '1;
						// 	daisy_num <= NUM_DRIVERS_CHAINED-1; 
						// 	if (slice_cnt == 'd359) begin
						// 		slice_cnt <= 0;
						// 	end else begin
						// 		slice_cnt <= slice_cnt + 1;
						// 	end
						// 	state <= 32'd0;
						end else if (enc_transition) begin // NEW FOR ENCODER HANDLING
							LAT <= '1;
							daisy_num <= NUM_DRIVERS_CHAINED-1;
							ENC_SAID_GO <= !ENC_SAID_GO;
							slice_cnt <= new_slice_cnt;
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

endmodule