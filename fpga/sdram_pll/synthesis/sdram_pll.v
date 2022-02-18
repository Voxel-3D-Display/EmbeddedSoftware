// sdram_pll.v

// Generated using ACDS version 18.1 625

`timescale 1 ps / 1 ps
module sdram_pll (
		output wire        pll_c1_clk,             //      pll_c1.clk
		input  wire        pll_inclk_clk,          //   pll_inclk.clk
		input  wire        pll_reset_reset,        //   pll_reset.reset
		output wire        pll_sdram_clk,          //   pll_sdram.clk
		input  wire        sdram_reset_reset_n,    // sdram_reset.reset_n
		input  wire [21:0] sdram_s1_address,       //    sdram_s1.address
		input  wire [1:0]  sdram_s1_byteenable_n,  //            .byteenable_n
		input  wire        sdram_s1_chipselect,    //            .chipselect
		input  wire [15:0] sdram_s1_writedata,     //            .writedata
		input  wire        sdram_s1_read_n,        //            .read_n
		input  wire        sdram_s1_write_n,       //            .write_n
		output wire [15:0] sdram_s1_readdata,      //            .readdata
		output wire        sdram_s1_readdatavalid, //            .readdatavalid
		output wire        sdram_s1_waitrequest,   //            .waitrequest
		output wire [11:0] sdram_wire_addr,        //  sdram_wire.addr
		output wire [1:0]  sdram_wire_ba,          //            .ba
		output wire        sdram_wire_cas_n,       //            .cas_n
		output wire        sdram_wire_cke,         //            .cke
		output wire        sdram_wire_cs_n,        //            .cs_n
		inout  wire [15:0] sdram_wire_dq,          //            .dq
		output wire [1:0]  sdram_wire_dqm,         //            .dqm
		output wire        sdram_wire_ras_n,       //            .ras_n
		output wire        sdram_wire_we_n         //            .we_n
	);

	wire    pll_c0_clk; // pll:c0 -> sdram:clk

	sdram_pll_pll pll (
		.clk                (pll_inclk_clk),   //       inclk_interface.clk
		.reset              (pll_reset_reset), // inclk_interface_reset.reset
		.read               (),                //             pll_slave.read
		.write              (),                //                      .write
		.address            (),                //                      .address
		.readdata           (),                //                      .readdata
		.writedata          (),                //                      .writedata
		.c0                 (pll_c0_clk),      //                    c0.clk
		.c1                 (pll_c1_clk),      //                    c1.clk
		.c2                 (pll_sdram_clk),   //                    c2.clk
		.scandone           (),                //           (terminated)
		.scandataout        (),                //           (terminated)
		.areset             (1'b0),            //           (terminated)
		.locked             (),                //           (terminated)
		.phasedone          (),                //           (terminated)
		.phasecounterselect (4'b0000),         //           (terminated)
		.phaseupdown        (1'b0),            //           (terminated)
		.phasestep          (1'b0),            //           (terminated)
		.scanclk            (1'b0),            //           (terminated)
		.scanclkena         (1'b0),            //           (terminated)
		.scandata           (1'b0),            //           (terminated)
		.configupdate       (1'b0)             //           (terminated)
	);

	sdram_pll_sdram sdram (
		.clk            (pll_c0_clk),             //   clk.clk
		.reset_n        (sdram_reset_reset_n),    // reset.reset_n
		.az_addr        (sdram_s1_address),       //    s1.address
		.az_be_n        (sdram_s1_byteenable_n),  //      .byteenable_n
		.az_cs          (sdram_s1_chipselect),    //      .chipselect
		.az_data        (sdram_s1_writedata),     //      .writedata
		.az_rd_n        (sdram_s1_read_n),        //      .read_n
		.az_wr_n        (sdram_s1_write_n),       //      .write_n
		.za_data        (sdram_s1_readdata),      //      .readdata
		.za_valid       (sdram_s1_readdatavalid), //      .readdatavalid
		.za_waitrequest (sdram_s1_waitrequest),   //      .waitrequest
		.zs_addr        (sdram_wire_addr),        //  wire.export
		.zs_ba          (sdram_wire_ba),          //      .export
		.zs_cas_n       (sdram_wire_cas_n),       //      .export
		.zs_cke         (sdram_wire_cke),         //      .export
		.zs_cs_n        (sdram_wire_cs_n),        //      .export
		.zs_dq          (sdram_wire_dq),          //      .export
		.zs_dqm         (sdram_wire_dqm),         //      .export
		.zs_ras_n       (sdram_wire_ras_n),       //      .export
		.zs_we_n        (sdram_wire_we_n)         //      .export
	);

endmodule