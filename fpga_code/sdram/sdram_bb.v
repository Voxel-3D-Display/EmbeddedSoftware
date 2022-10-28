
module sdram (
	clk_clk,
	new_sdram_controller_0_s1_address,
	new_sdram_controller_0_s1_byteenable_n,
	new_sdram_controller_0_s1_chipselect,
	new_sdram_controller_0_s1_writedata,
	new_sdram_controller_0_s1_read_n,
	new_sdram_controller_0_s1_write_n,
	new_sdram_controller_0_s1_readdata,
	new_sdram_controller_0_s1_readdatavalid,
	new_sdram_controller_0_s1_waitrequest,
	new_sdram_controller_0_wire_addr,
	new_sdram_controller_0_wire_ba,
	new_sdram_controller_0_wire_cas_n,
	new_sdram_controller_0_wire_cke,
	new_sdram_controller_0_wire_cs_n,
	new_sdram_controller_0_wire_dq,
	new_sdram_controller_0_wire_dqm,
	new_sdram_controller_0_wire_ras_n,
	new_sdram_controller_0_wire_we_n,
	sys_sdram_pll_0_ref_reset_reset,
	sys_sdram_pll_0_sdram_clk_clk);	

	input		clk_clk;
	input	[23:0]	new_sdram_controller_0_s1_address;
	input	[1:0]	new_sdram_controller_0_s1_byteenable_n;
	input		new_sdram_controller_0_s1_chipselect;
	input	[15:0]	new_sdram_controller_0_s1_writedata;
	input		new_sdram_controller_0_s1_read_n;
	input		new_sdram_controller_0_s1_write_n;
	output	[15:0]	new_sdram_controller_0_s1_readdata;
	output		new_sdram_controller_0_s1_readdatavalid;
	output		new_sdram_controller_0_s1_waitrequest;
	output	[12:0]	new_sdram_controller_0_wire_addr;
	output	[1:0]	new_sdram_controller_0_wire_ba;
	output		new_sdram_controller_0_wire_cas_n;
	output		new_sdram_controller_0_wire_cke;
	output		new_sdram_controller_0_wire_cs_n;
	inout	[15:0]	new_sdram_controller_0_wire_dq;
	output	[1:0]	new_sdram_controller_0_wire_dqm;
	output		new_sdram_controller_0_wire_ras_n;
	output		new_sdram_controller_0_wire_we_n;
	input		sys_sdram_pll_0_ref_reset_reset;
	output		sys_sdram_pll_0_sdram_clk_clk;
endmodule
