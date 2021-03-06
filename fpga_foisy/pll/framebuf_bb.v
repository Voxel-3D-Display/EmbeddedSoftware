
module FrameBuf (
	mem_s1_address,
	mem_s1_clken,
	mem_s1_chipselect,
	mem_s1_write,
	mem_s1_readdata,
	mem_s1_writedata,
	mem_s1_byteenable,
	mem_s2_address,
	mem_s2_chipselect,
	mem_s2_clken,
	mem_s2_write,
	mem_s2_readdata,
	mem_s2_writedata,
	mem_s2_byteenable,
	mem_clk_clk,
	mem_rst_reset);	

	input	[12:0]	mem_s1_address;
	input		mem_s1_clken;
	input		mem_s1_chipselect;
	input		mem_s1_write;
	output	[15:0]	mem_s1_readdata;
	input	[15:0]	mem_s1_writedata;
	input	[1:0]	mem_s1_byteenable;
	input	[12:0]	mem_s2_address;
	input		mem_s2_chipselect;
	input		mem_s2_clken;
	input		mem_s2_write;
	output	[15:0]	mem_s2_readdata;
	input	[15:0]	mem_s2_writedata;
	input	[1:0]	mem_s2_byteenable;
	input		mem_clk_clk;
	input		mem_rst_reset;
endmodule
