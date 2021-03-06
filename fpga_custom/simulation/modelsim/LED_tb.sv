`timescale 1 ps / 1 ps
module Led_tb #(parameter NUM_SHIFT=4)(

		output   reg	clk,
		
		output ledCmdDone,
		output busy,
		output [NUM_SHIFT-1:0] SDO,
		output LAT,
		output SCLK
	);

	reg nReset;
	initial #0 begin

    	clk=0;
		nReset=1;
    #30 nReset=0;
	#50 nReset=1;
  	end

  	always begin
    	#10 clk=!clk;
  	end

	reg ledCmdStart;
	reg [3:0] m_state;
	reg [7:0] cnt;
	reg [15:0] ledCol;
	reg wren;
	reg [6:0]		wraddress;
	reg wrclock;
	
	always_ff@(posedge clk) begin 
		if(!nReset) begin
			m_state <= '0;
			cnt <= '0;
			wren <= '1;
			ledCmdStart <= '0;
		end else begin
			case (m_state)
				4'd0:	
					begin
						ledCol <= cnt;
						wraddress <= cnt;
						wrclock <=0;
						m_state <= 4'd1;
					end
				4'd1:
					begin
						wrclock <=1;
						m_state <= 4'd2;
					end
				4'd2:
					begin
						wrclock <=0;
						
						cnt <= cnt + 1;
						m_state <= (cnt==127) ? 4'd3 : 4'd0;
					end
				4'd3:
					begin
						if(!busy) begin
							ledCmdStart <= '1;
							m_state <= 4'd4;
						end
					end
				4'd4:
					begin
						ledCmdStart <= '0;
					end
			endcase
		end
	end
	
	
	LED #(.NUM_SHIFT(4)) led(
		.spiClk(clk),
		.nReset,
		
		.ledCmdStart,
		.ledCmdDone,
		
		.ledCol,
		.wraddress,
		.wrclock,
		.wren,
		
		.busy,
		
		.LAT,
		.SDO,
		.SCLK
		
	);
	
	
	
	
endmodule


