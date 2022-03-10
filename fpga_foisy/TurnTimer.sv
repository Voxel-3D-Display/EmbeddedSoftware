module TurnTimer #(CLK_FREQ, FPS, IMG_HEIGHT) (
		input clk,
		input nReset,
		
		input mag, //the timing sensor input
		
		output reg [$clog2(IMG_HEIGHT)-1:0] row,
		output reg valid,
		output reg index,
		output reg rowChange,
		input rowChangeAck
	);
	
	localparam NUM_MAG = 720;
	reg [$clog2(NUM_MAG)-1 : 0] magIdx;
	
	reg [3:0] i_state;
	//counter incremented by 1 on each SDRAM clock pulse (90MHz)
	reg [$clog2(CLK_FREQ/FPS)*2 -1 : 0] cnt;

	reg error;
	reg [$clog2(CLK_FREQ/IMG_HEIGHT)*2 -1 : 0] step;
	reg [$clog2(CLK_FREQ/IMG_HEIGHT)*2 -1 : 0] nextStep;
	
	reg [$clog2(CLK_FREQ/IMG_HEIGHT)*2 -1 : 0] stepCnt;

	
	reg magChange;
	reg oldMag;
	reg magValid;
	
	reg rowChange1;

	reg signal;
	
	always_ff@(posedge clk) begin
		if(!nReset) begin
			magChange <= '0;
			oldMag <= mag;
			magIdx <= '1;
			magValid <= '0;
		end else begin
			magChange <= '0;
			if (signal) begin
				magIdx <= '1; //reset to one or zero?
			end
			if(oldMag != mag ) begin //waiting for change in sensor input
				magValid <= '1;
				magChange <= '1;
				//this needs to become more presice
				magIdx <= magIdx + 1; //becomes 0 once we hit size of the register
			end
			oldMag <= mag;
		end
	end
	
	always_ff@(posedge clk) begin
		if(!nReset) begin
			rowChange <= '0;
		end else begin
			if(rowChange1 && !rowChange)
				rowChange <= '1;
			else if(rowChangeAck && rowChange)
				rowChange <= '0;
		end
	end
	
	always_ff@(posedge clk) begin
		if(!nReset) begin
			row <= '0;
			stepCnt <= 1;
			index <= '0;
			rowChange1 <= '0;
			signal <= '0;
		end else begin
			if(valid) begin
				index <= '0;
				rowChange1 <= '0;
			
				if( (magChange == '0) && (magIdx == 720)) begin
					signal <= '1;
					stepCnt <= 1;
					row <= 0;
					index <= '1;
					rowChange1 <= '1; 
				end else begin
					stepCnt <= stepCnt + 1;
					signal <= '0;
					
					if(stepCnt >= step) begin
						if(row < IMG_HEIGHT-1) begin
							row <=  row + 1;
							rowChange1 <= '1;
						end else begin
							row <= IMG_HEIGHT-1;
						end
						
						stepCnt <= 1;
						//step <= nextStep;
					end 
				end
			end else begin 
				row <= '0;
				stepCnt <= '0;
			end

		end
	end
	

	always_ff@(posedge clk) begin: TURN_FSM
		if(!nReset) begin
			i_state <= 4'd0;
			cnt <= '0;
			error <= '1;

		end else begin
			case (i_state)
				4'd0:	
					begin
						valid <= '0;
						if(magValid && magChange) begin
							cnt <= 0;
							i_state <= 4'd3;
						end
					end
				
				4'd3:
					begin
						cnt <= cnt + 1'd1;
						
						if(cnt == CLK_FREQ/FPS*2 - 1) begin
							error <= '1;
							i_state <= 4'd0;
						end else if(magChange) begin
					
							cnt <= '0;
							error <= '0;
							
							valid <= '1;
							//old operation gave too much rounding error
							step <= (cnt * NUM_MAG) / IMG_HEIGHT;
							
						end
						
					end
				default:
					i_state <= '0;
			endcase
		end
	end	
endmodule
	