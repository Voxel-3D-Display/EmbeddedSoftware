	sdram u0 (
		.clk_clk                                 (<connected-to-clk_clk>),                                 //                         clk.clk
		.new_sdram_controller_0_s1_address       (<connected-to-new_sdram_controller_0_s1_address>),       //   new_sdram_controller_0_s1.address
		.new_sdram_controller_0_s1_byteenable_n  (<connected-to-new_sdram_controller_0_s1_byteenable_n>),  //                            .byteenable_n
		.new_sdram_controller_0_s1_chipselect    (<connected-to-new_sdram_controller_0_s1_chipselect>),    //                            .chipselect
		.new_sdram_controller_0_s1_writedata     (<connected-to-new_sdram_controller_0_s1_writedata>),     //                            .writedata
		.new_sdram_controller_0_s1_read_n        (<connected-to-new_sdram_controller_0_s1_read_n>),        //                            .read_n
		.new_sdram_controller_0_s1_write_n       (<connected-to-new_sdram_controller_0_s1_write_n>),       //                            .write_n
		.new_sdram_controller_0_s1_readdata      (<connected-to-new_sdram_controller_0_s1_readdata>),      //                            .readdata
		.new_sdram_controller_0_s1_readdatavalid (<connected-to-new_sdram_controller_0_s1_readdatavalid>), //                            .readdatavalid
		.new_sdram_controller_0_s1_waitrequest   (<connected-to-new_sdram_controller_0_s1_waitrequest>),   //                            .waitrequest
		.new_sdram_controller_0_wire_addr        (<connected-to-new_sdram_controller_0_wire_addr>),        // new_sdram_controller_0_wire.addr
		.new_sdram_controller_0_wire_ba          (<connected-to-new_sdram_controller_0_wire_ba>),          //                            .ba
		.new_sdram_controller_0_wire_cas_n       (<connected-to-new_sdram_controller_0_wire_cas_n>),       //                            .cas_n
		.new_sdram_controller_0_wire_cke         (<connected-to-new_sdram_controller_0_wire_cke>),         //                            .cke
		.new_sdram_controller_0_wire_cs_n        (<connected-to-new_sdram_controller_0_wire_cs_n>),        //                            .cs_n
		.new_sdram_controller_0_wire_dq          (<connected-to-new_sdram_controller_0_wire_dq>),          //                            .dq
		.new_sdram_controller_0_wire_dqm         (<connected-to-new_sdram_controller_0_wire_dqm>),         //                            .dqm
		.new_sdram_controller_0_wire_ras_n       (<connected-to-new_sdram_controller_0_wire_ras_n>),       //                            .ras_n
		.new_sdram_controller_0_wire_we_n        (<connected-to-new_sdram_controller_0_wire_we_n>),        //                            .we_n
		.sys_sdram_pll_0_ref_reset_reset         (<connected-to-sys_sdram_pll_0_ref_reset_reset>),         //   sys_sdram_pll_0_ref_reset.reset
		.sys_sdram_pll_0_sdram_clk_clk           (<connected-to-sys_sdram_pll_0_sdram_clk_clk>)            //   sys_sdram_pll_0_sdram_clk.clk
	);

