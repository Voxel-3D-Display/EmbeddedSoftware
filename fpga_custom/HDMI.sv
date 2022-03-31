//this module will take in the 24 bits from the HDMI decoder and
//determine where to place it in SDRAM

module HDMI (
    input [2:0][7:0] HDMI_RGB,

    input PIXCLK,
    input SDRAM_CLK,
    input readEnable,
    output [12:0] SDRAM_addr //where we want to write data to
    //
);

	reg nReset = 1;
//	reg [12:0] SDRAM_addr; commented out because already declared in the module port declarations
	reg [1:0]  SDRAM_bank;

always_ff@(negedge PIXCLK) begin
	if (!nReset) begin
		SDRAM_addr <= 'd0;
		SDRAM_bank <= 'd0;
	end else begin
		SDRAM_addr <= SDRAM_addr + 1; //??? Are we just incrementing through SDRAM
	end	
end
        

    
endmodule