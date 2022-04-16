`timescale 1 ps / 1 ps

module top
	(
		input 	 CLK_10M,
		input	 ENC_ABS_HOME,
		input 	 ENC_360,
		input 	 [2:0][7:0]   HDMI_RGB, //UNCOMMENT TO TEST HDMI
		input    VSYNC,
		input    HSYNC,
		input    PIXCLK, //UNCOMMENT TO TEST HDMI; CHECK PIN
		input    DE, //CHECK PIN
		input    ACTIVE,
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
	logic ENC_SAYS_GO = 1;
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



	led_matrix matrix(
		.CLK(TESTCLK),
		.memory_data((array_in_use ? LED_data_2 : LED_data_1)),
		.SDO,
		.LAT,
		.SCLK,
		.nReset,
		.ENC_SAYS_GO,
		.reading_memory(slice_read_complete)
	);

	reg   wrreq;
	logic	[8:0]  rdusedw;
	reg   [15:0]   HDMI_fifo_Data;
	reg   HDMI_fifo_Enable;
	reg array_in_use;
	assign array_debug = array_in_use;

	logic waitRequest; //generated by SDRAM; tells us when SDRAM is unavailable due to performing a refresh

	reg [1:0] refreshCnt;
	//assign HDMI_fifo_Enable = '1; //(m_state == 1)  && !waitRequest;
	//assign wrreq = 1; //= DE //only read when DE is high
	assign HDMI_fifo_Enable = !buf_empty; //only read from the buffer when it's not empty
	logic buf_empty;

	assign wrreq = (col_counter < 1536) && (row_counter < 360) && DE;
	HDMI_fifo hdmi(
		.data({HDMI_RGB[2][7:3], HDMI_RGB[1][7:2], HDMI_RGB[0][7:3]}), //input //CHANGE TO{HDMI_RGB[2][7:3], HDMI_RGB[1][7:2], HDMI_RGB[0][7:3]} TO TEST HDMI
		
		.wrclk(PIXCLK), //clock rate for writing to FIFO
		.wrreq, //input - high to request to write to the FIFO
		
		.rdclk(SDRAM_CLKn), //CHANGE to SDRAM clock - clock rate for reading
		.rdreq(!buf_empty), //high to request read from FIFO //HDMI_fifo_Enable
		.q(HDMI_fifo_Data), //output
		.rdempty(buf_empty)
		//.rdusedw //8 bit width output (unused?)
	);

	reg [10:0] col_counter;
	reg [8:0] row_counter;
	always_ff@(negedge PIXCLK) begin
		if(!nReset) begin
			col_counter <= 0;
			row_counter <= 0;
		end else begin
			if (VSYNC && (DE == 0)) begin
				row_counter <= 0;
			end else if (HSYNC && DE == 0) begin //we are getting HYSNC and DE is low (sending HSYNC/VSYNC)
				col_counter <= '0;
				row_counter <= row_counter + 1;
			end else begin
				col_counter <= col_counter + 1;
			end
		end
	end

	logic memWriteRequest;
	assign memWriteRequest = (m_state == 1); //waitrequest handled in state machine
	//do we want to have the m_state == 2 in here?
	assign nRead = ((m_state == 3 || m_state == 2) && !waitRequest) ? 1'b0 : 1'b1; //  && readRequestCnt < BURST_SIZE) ? 1'b0 : 1'b1 ;
	reg [15:0] read_LED_data;

	//SDRAM block
	reg [15:0] test_data = 16'b1111111111111111;
	logic out_SDRAM;

	sdram sdram(
		.clk_clk(SDRAM_CLKn),   //SDRAM_CLKn input
		.sys_sdram_pll_0_ref_reset_reset(!nReset), //input
		.sys_sdram_pll_0_sdram_clk_clk(out_SDRAM), //output
		//.reset_reset(!nReset),
		//.sdram_clk_clk(out_SDRAM),
		.new_sdram_controller_0_s1_address(Address),       		//input - address to read or write
		.new_sdram_controller_0_s1_byteenable_n('0),
		.new_sdram_controller_0_s1_chipselect('1),
		.new_sdram_controller_0_s1_writedata(HDMI_fifo_Data),     	//input - HDMI_fifo_Data test_data
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

	//testing ideas: just display what we are writing into SDRAM and what we are reading out
	//the online example projects suggested using 0x08000000 as the base address, but I couldn't
	//find a way to change it

	bit [11:0][7:0][767:0] LED_data_1;
	bit [11:0][7:0][767:0] LED_data_2;
	reg [1439:0][23:0] LED_data_3;
	reg [1439:0][23:0] LED_data_4;
	reg [1439:0][23:0] LED_data_5;
	integer x;
	integer y;
	reg trigger;

	//reg array_in_use;
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
	assign Address = (m_state == 1) ? writeAddress : readAddress; //select read or write addr to send to SDRAM

	reg write_request;
	reg read_request;
	logic read_data_valid;
	logic [10:0] pixel_read_cnt; //fix sizing
	reg [10:0] slice_cnt; //fix sizing
	reg need_new_slice;

	reg trigger_2;
	reg dummy;
	reg leave;

	always_ff@(posedge SDRAM_CLKn) begin //SDRAM_CLKn
		//state machine here for determining when to read and when to write and where
		if (!nReset) begin
				//leave <= 0;
				read_request <= 1; //change back to zero
                readCnt <= '0;
				write_request <= 1;
				m_state <= '0;
				slice_cnt <= '0;
				readAddress <= 24'b0;
				//slice_read_complete <= 0;
				writeAddress <= 24'b0;
				trigger <= 1;
				//submatrix <= 0;
				//driver <= 0;
            end else begin
				
				if(VSYNC) begin //reached end of a frame - move on to next one
					//idk how this make sense if we are cutting out 3 of every four frames
					writeAddress <= 0; //could be written twice in one clock edge? But no errors
				end
				/*
				if(!leave && !SDRAM_WE_N) begin
					writeAddress <= 24'b0;
					readAddress <= 24'b0;
					leave <= 1;
				end
				*/
				
				if((slice_read_complete != dummy) && slice_read_complete) begin
					//to populate the next array
					array_in_use <= !array_in_use;
					read_request <= '1;
					//this gets set back to zero in the state machine after we read a slice
				end
				dummy <= slice_read_complete;
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
							if(!waitRequest) begin //amke sure SDRAM isn't otherwise occupied
								//trigger <= 1;
								writeCnt <= writeCnt + 1;
								if (writeAddress >= 552960) begin
									writeAddress <= '0;
								end else begin
									writeAddress <= writeAddress + 1'b1; //increment addr
								end
								if (writeCnt == WRITE_BURST_SIZE -1 || !write_request) begin
									//once we have full burst or nothing else to write, move on
									trigger <= 1;
									m_state <= 2;
								end
							end
						end
					2: //we get when there's no write request OR just finished write burst
						begin
							if(read_request) begin //read_request
								readCnt <= '0; //for writes and reads?
								//pixel_read_cnt <= '0;
								m_state <= 3;
							end else begin
								m_state <= 0; //no read request - back to start state
							end
						end
					3: //state for reading from SDRAM
						begin
							if(read_data_valid) begin //read_data_valid
								//use two 48 by 24 arrays
								//trigger <= 1;
								readCnt <= readCnt + 1;
								pixel_read_cnt <= pixel_read_cnt + 1;
								readAddress <= readAddress + 1'b1; //address for next clock cycle
								//each read will return a 'full' pixel
								//any reason we'd have to delay a cycle before doing this
								//^I don't think so bc read was high in state 2, and the address was correct
								if (array_in_use == 0) begin
									//as we read it out, make it 24 bits again
									LED_data_2[pixel_read_cnt[10:7]][pixel_read_cnt[6:4]][pixel_read_cnt[3:0]*48 +: 48] <= {read_LED_data[15:11], 11'b000, read_LED_data[10:5], 10'b00, read_LED_data[4:0], 11'b000};
								end else begin
									LED_data_1[pixel_read_cnt[10:7]][pixel_read_cnt[6:4]][pixel_read_cnt[3:0]*48 +: 48] <= {read_LED_data[15:11], 11'b000, read_LED_data[10:5], 10'b00, read_LED_data[4:0], 11'b000};
								end
								if (pixel_read_cnt == 1536) begin 
									//have iterated through all the pixels in a slice
									pixel_read_cnt <= '0;
									slice_cnt <= slice_cnt + 1;
									//slice_read_complete <= 1;
									read_request <= '0; //stop reading till LED tells us to start again
									if (slice_cnt == 360) begin
										//have iterated through an entire frame
										readAddress <= '0;
										slice_cnt <= '0;
									end
									readCnt <= 0;
									m_state <= 0;
								end else begin
									//slice_read_complete <= 0;
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




	// encoder handling
	localparam NUM_CONSEC_ENC = 'd4;
	reg [NUM_CONSEC_ENC-1:0] windowing_zeros = 4'b1111;
	reg [NUM_CONSEC_ENC-1:0] windowing_ones = 4'b0000;
	reg hadOne = 0;
	reg enc_transition;
	always@(posedge CLK_10M) begin //50MHZ_CLOCK
		if (!nReset) begin
			windowing_zeros <= 4'b1111;
			windowing_ones <= 4'b0000;
			hadOne <= 0;
		end else begin
			windowing_zeros <= (windowing_zeros << 1) & ENC_360;
			windowing_ones <= (windowing_ones << 1) & ENC_360;
			if (windowing_zeros^(4'b0000)) begin
				if (hadOne) begin
					enc_transition <= 1;
				end
				hadOne = 0;
			end else if (windowing_ones^(4'b1111)) begin
				if (!hadOne) begin
					enc_transition <= 1;
				end
				hadOne = 1;
			end else if (need_new_slice) begin
				enc_transition <= 0;
			end
		end
	end


endmodule