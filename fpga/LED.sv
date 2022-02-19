module LED #(parameter NUM_SHIFT=8, GLB_HEIGHT, GLB_WIDTH, GLB_FPS, SDRAM_CLK_FREQ)  (
		input					CLK_10M,
		input 				spiClk,
		input					SDRAM_CLK,
		input 				nReset,
		
		input 				MAG2,
		
		output 				ledCmdDone,
		
		output reg 			readReq,
		output reg [23:0] address,
		input 				addressAck,
		input 				readDataValid,
		input [15:0] 		readData,
		
		output				busy,
		
		output  				LAT,
		output 	[NUM_SHIFT-1:0]		SDO,
		output				SCLK
		
	);
	localparam NUM_SIDES = 1;		//1 or 2
	logic initDone;
	
	logic initLat;
	
	logic ledLat;
	logic ledBusy;
	
	logic SDOsingle;
	logic [NUM_SHIFT-1:0] SDOs;
	logic initSCLK;
	logic ledSCLK;

	
	
	assign LAT = !initDone ? initLat : ledLat;
	assign SDO = !initDone ? { NUM_SHIFT{SDOsingle}} : SDOs; 
	assign SCLK = !initDone ? initSCLK : ledSCLK;
	assign busy = !initDone || ledBusy;
	
	
	//CDC ledCmdStart
	reg ledCmdStart_SPI;
	reg ledCmdStart_SDRAM;
	reg ledCmdStart_pipe;
	reg ledCmdStart_last;
	reg ledCmdStart;
	
	always @(posedge spiClk)
		{ ledCmdStart_last, ledCmdStart_SPI, ledCmdStart_pipe } <= { ledCmdStart_SPI, ledCmdStart_pipe, ledCmdStart_SDRAM };
	
	always @(posedge spiClk)
		ledCmdStart <= (!ledCmdStart_last)&&(ledCmdStart_SPI);
	
	reg ledCmdStart_ack;
	reg ledCmdStart_ack_pipe;
	always @(posedge SDRAM_CLK)
		{ ledCmdStart_ack, ledCmdStart_ack_pipe } <= { ledCmdStart_ack_pipe, ledCmdStart_SPI };
	
	//CDC ledCmdStart  end
	
	InitLed #(.NUM_TLC5955(2)) initLed (
		.spiClk,
		.nReset,
		
		.LAT(initLat),
		.SDOsingle,
		.SCLK(initSCLK),
		
		.initDone
	);
	
	logic [$clog2(GLB_WIDTH/NUM_SIDES)-1:0] rdaddress;
	logic [15:0] ledColBuf;
	
	RowBuf rowBufAll(
		.data(readData_d),
		.wraddress(bufAddress),
		.wrclock(SDRAM_CLK),
		.wren(readDataValid && state==1),
		
		.rdaddress(rdaddress),
		.rdclock(spiClk),
		
		.q(ledColBuf)
	);
	
	//assign ledColBufOdd = row % 128 ? 16'h0008 : 16'h4000;
	//assign ledColBufEven = 16'h0;//rowEven % 16 ? 16'h0008 : 16'h4000;
	
	LedCtrl ledCtrl(
		.spiClk(spiClk),
		.nReset(nReset),

		.SDOs,
		.LAT(ledLat),
		.SCLK(ledSCLK),
		
		.cmdStart(ledCmdStart),
		.cmdDone(ledCmdDone),
		.busy(ledBusy),
		
		.ledColBuf,
		.rdaddress
	);
	
	//turn timer
	logic [$clog2(GLB_HEIGHT)-1:0] row;
	logic rowValid;
	logic rowChange;
	logic index;
	reg [7:0] magFilter;
	reg mag;
	always_ff@(posedge CLK_10M) begin
		magFilter <= {magFilter[6:0], MAG2};
		if(magFilter == '1)
			mag <= '1;
		else if(magFilter == '0)
			mag <= '0;
	end
	
	//---------------------------------------------------------------------------------------------
	//SDRAM_CLK
	//---------------------------------------------------------------------------------------------
	
	TurnTimer #(.CLK_FREQ(SDRAM_CLK_FREQ), .FPS(GLB_FPS), .IMG_HEIGHT(GLB_HEIGHT)) turnTimer(
		.clk(SDRAM_CLK),
		.nReset,
		.mag(mag),
		.row,
		.valid(rowValid),
		.index,
		.rowChange,
		.rowChangeAck
	);	
	
	
	
	reg [$clog2(GLB_WIDTH/NUM_SIDES)-1:0] bufAddress;
	reg [15:0] readData_d;
	
	always@(posedge SDRAM_CLK) 
		readData_d <= readData;
	
	reg [15:0] readCnt;
	reg [2:0] state;
	reg [23:0] addressAll;
	reg rowChangeAck;
	
	assign address = addressAll;

	always@(posedge SDRAM_CLK) begin
		if(!nReset) begin
			state <= '0;
			readCnt <= '0;
			readReq <= '0;
			bufAddress <= '0;
			ledCmdStart_SDRAM <= '0;
		end else begin
			case(state)
				0: 
					begin
						rowChangeAck <= '0;
						if(rowChange) begin
							rowChangeAck <= '1;
							addressAll <= (row << $clog2(GLB_WIDTH));
							readCnt <= '0;
							if(row < GLB_HEIGHT) begin
								state <= 1;
								readReq <= '1;
								readCnt <= '0;
								bufAddress <= '0;
							end 
						end
					end
				1:
					begin
						rowChangeAck <= '0;
						if(addressAck)
							addressAll <= addressAll + NUM_SIDES;
							
						if(readDataValid) begin
							readCnt <= readCnt + 1;
							bufAddress <= bufAddress + 1;
							
							if(readCnt == (GLB_WIDTH/NUM_SIDES) - 1) begin
								readReq <= '0;
								state <= NUM_SIDES == 2 ? 2 : 4;
								readCnt <= '0;
								bufAddress <= '0;
							end
						end
					end
				2:
					begin
						state <= 3;
						readReq <= '1;
					end
				3: //since NUM_SIDES is 1 we never enter this state
					begin
						if(readDataValid) begin
							readCnt <= readCnt + 1;
							bufAddress <= bufAddress + 1;
							
							if(readCnt == (GLB_WIDTH/2) - 1) begin
								readReq <= '0;
								state <= 4;
								readCnt <= '0;
							end
						end
					end	
				4:
					begin
						ledCmdStart_SDRAM <= '1;
						if(ledCmdStart_ack && ledBusy) begin
							ledCmdStart_SDRAM <= '0;
							state <= 5;
						end
					end
				5: 
					begin
						if(!ledBusy) begin
							state <= 0;
						end
					end
			endcase 
		end
	end
		
endmodule
