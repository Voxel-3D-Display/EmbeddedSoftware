module LedCtrl #(parameter NUM_SHIFT_CHANNEL = 4) 
	(
		input spiClk,
		input nReset,
		
		input cmdStart,
		output reg cmdDone,
		output reg busy,
		
		input [15:0] ledColBuf,
		output [6:0] rdaddress,
		
		output [(NUM_SHIFT_CHANNEL * 2) -1:0] SDOs,
		output reg LAT,
		output reg SCLK
	
	);


	reg [3:0] m_state;
	reg [4:0] cnt;
	reg [$clog2(NUM_SHIFT_CHANNEL)-1:0] hi;
	reg [5:0] shiftCnt;

	logic [15:0] rLut[0:31] = '{
		16'd0,    16'd0,    16'd4,    16'd18,   16'd51,   16'd110,  16'd209,  16'd359,
		16'd572,  16'd864,  16'd1249, 16'd1744, 16'd2365, 16'd3130, 16'd4057, 16'd5164,
		16'd6473, 16'd8003, 16'd9776, 16'd11813,16'd14136,16'd16768,16'd19733,16'd23054,
		16'd26758,16'd30867,16'd35409,16'd40409,16'd45894,16'd51892,16'd58429,16'd65535  
	};
	
	logic [15:0] gLut[0:63] = '{
		16'd0,    16'd0,    16'd0,    16'd2,    16'd4,    16'd9,    16'd17,   16'd30,
		16'd48,   16'd72,   16'd104,  16'd146,  16'd198,  16'd262,  16'd339,  16'd432,
		16'd541,  16'd669,  16'd817,  16'd987,  16'd1181, 16'd1401, 16'd1649, 16'd1927,
		16'd2236, 16'd2580, 16'd2959, 16'd3377, 16'd3836, 16'd4337, 16'd4883, 16'd5477,
		16'd6121, 16'd6817, 16'd7568, 16'd8376, 16'd9244, 16'd10174,16'd11169,16'd12232,
		16'd13366,16'd14572,16'd15855,16'd17216,16'd18658,16'd20185,16'd21799,16'd23503,
		16'd25300,16'd27194,16'd29186,16'd31281,16'd33481,16'd35789,16'd38208,16'd40743,
		16'd43395,16'd46168,16'd49066,16'd52091,16'd55247,16'd58538,16'd61966,16'd65535 
	};
	
	logic [15:0] bLut[0:31] = '{
		16'd0,    16'd0,    16'd4,    16'd18,   16'd51,   16'd110,  16'd209,  16'd359,
		16'd572,  16'd864,  16'd1249, 16'd1744, 16'd2365, 16'd3130, 16'd4057, 16'd5164,
		16'd6473, 16'd8003, 16'd9776, 16'd11813,16'd14136,16'd16768,16'd19733,16'd23054,
		16'd26758,16'd30867,16'd35409,16'd40409,16'd45894,16'd51892,16'd58429,16'd65535 
	};
	
	assign rdaddress = {hi, cnt};
	reg [NUM_SHIFT_CHANNEL-1:0] load;
	reg [NUM_SHIFT_CHANNEL-1:0] shiftClk;
	logic [NUM_SHIFT_CHANNEL-1:0] shiftoutAll;
	logic [NUM_SHIFT_CHANNEL * 2 -1 : 0] shiftout;
	logic [47:0] dataAll;
	
	
	// dataAll is a 48 bit number consisting of red, green, and blue brightnesses that will be shifted into the LED shift register
	// assign dataAll = {bLut[ledColBuf[4:0]], gLut[ledColBuf[10:5]], rLut[ledColBuf[15:11]]};
	assign dataAll = {bLut[5'b11111], gLut[6'b111111], rLut[5'b11111]};	// for testing
	
	//assign dataEven = { 16'd0, 16'd0, 16'd5164};
	//assign dataOdd =  { 16'd5164, 16'd0, 16'd0};
	LedShift ledShiftAll[NUM_SHIFT_CHANNEL-1:0] (	
		.clock(shiftClk),
		.data(dataAll),
		.load,
		.shiftout(shiftoutAll)
	);
	
	assign shiftout = {shiftoutAll};
	
	assign SDOs = (m_state == 4'd0 || m_state == 4'd5) ? '0 : shiftout;	//TODO: parameterize
	
	always_ff@(posedge spiClk) begin 
		if(!nReset) begin
			m_state <= 4'd0;
			LAT <= '0;
			SCLK <= '0;
			cmdDone <= '0;
			busy <= '0;
			hi <= '0;
			shiftClk <= '0;
			load <= '0;

		end else begin	//load data into shift registers
			case (m_state)
				4'd0:		// either idle, or begin loading data if cmdStart is given
					begin
						cmdDone <= '0;
						busy <= '0;
						SCLK <= '0;
						if(cmdStart) begin
							begin
								busy <= '1;
								
								m_state <= 4'd1;
								cnt <= '0;
								hi <= '0;
								//send latch select bit
								SCLK <= '1;
							end
						end
					end
				4'd1:		// set SCLK low
					begin
						m_state <= 4'd10;
						SCLK <= '0;

					end
				4'd10:		// wait a little bit for some reason
					begin
						m_state <= 4'd2;
					end
				4'd2:		// load all bits of one LED color trio (r, g, and b) into LED shift register in parallel
					begin
						load[NUM_SHIFT_CHANNEL-1 - hi] <= '1;
						shiftClk[NUM_SHIFT_CHANNEL-1 - hi] <= '1;
						m_state <=  4'd9;
					end
				4'd9:		// for next shift channel, repeat starting at state 1. else go to next state
					begin
						load <= '0;
						shiftClk <= '0;
						hi <= hi + 1;
						if(hi == NUM_SHIFT_CHANNEL-1) begin
							m_state <=  4'd3;
							shiftCnt <= '0;
						end else begin
							m_state <=  4'd1;
						end
					end
				4'd8:
					begin
						m_state <=  4'd3;
					end
					
				4'd3:		// send data out serially from shift register
					begin
						shiftClk <= '0;
						SCLK <= '1;
						m_state <= 4'd4;
					end
				4'd4:		// send data out serially from shift register until all 48 bits have been sent out
					begin
						SCLK <= '0;
						shiftClk <= '1;
						shiftCnt <= shiftCnt + 1;
						if(shiftCnt == 47) begin
							m_state <= 4'd5;
						end else begin
							m_state <= 4'd3;
						end
					end
				4'd5:		// send out data until all data for 48 LEDs (16 color triplets) have been sent out, then latch the data into the TLC5955 register
					begin
						cnt<=cnt + 1;			// increment the triplet pair being sent
						shiftClk <= '0;
						if(cnt==15) begin		//insert a 0 latch select bit at TLC5955 boundary // check if data for 16 color triplets (all 48 pins) for the first TLC5955 have been sent
							SCLK <= '1;
							m_state <= 4'd1;
						end else if(cnt==31) begin		// // check if data for 16 color triplets (all 48 pins) for the second TLC5955 have been sent
							LAT <= '1;
							m_state <= 4'd6;
						end else begin
							m_state <= 4'd1;
						end
						
					end
					
				4'd6:
					begin
						m_state <= 4'd7;
					end
				4'd7:		// finished updating LEDs
					begin
						LAT <= '0;
						cmdDone <= '1;
						m_state <= 4'd0;
					end
	
				default:
					m_state <= 4'd0;
			endcase
		end
	end
	
endmodule
