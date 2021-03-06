// Pll.v

// Generated using ACDS version 18.1 646

`timescale 1 ps / 1 ps
module Pll (
		input  wire  clk_in_clk,    //    clk_in.clk
		input  wire  clk_rst_reset, //   clk_rst.reset
		output wire  gsclk_clk,     //     gsclk.clk
		output wire  sclk_x2_clk,   //   sclk_x2.clk
		output wire  sdram_clk_clk  // sdram_clk.clk
	);

	Pll_altpll_0 altpll_0 (
		.clk       (clk_in_clk),    //       inclk_interface.clk
		.reset     (clk_rst_reset), // inclk_interface_reset.reset
		.read      (),              //             pll_slave.read
		.write     (),              //                      .write
		.address   (),              //                      .address
		.readdata  (),              //                      .readdata
		.writedata (),              //                      .writedata
		.c0        (sdram_clk_clk), //                    c0.clk
		.c1        (sclk_x2_clk),   //                    c1.clk
		.c2        (gsclk_clk)      //                    c2.clk
	);

endmodule
