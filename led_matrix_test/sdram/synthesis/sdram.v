// sdram.v

// Generated using ACDS version 19.1 670

`timescale 1 ps / 1 ps
module sdram (
		input  wire        clk_clk,                                 //                         clk.clk
		input  wire [23:0] new_sdram_controller_0_s1_address,       //   new_sdram_controller_0_s1.address
		input  wire [1:0]  new_sdram_controller_0_s1_byteenable_n,  //                            .byteenable_n
		input  wire        new_sdram_controller_0_s1_chipselect,    //                            .chipselect
		input  wire [15:0] new_sdram_controller_0_s1_writedata,     //                            .writedata
		input  wire        new_sdram_controller_0_s1_read_n,        //                            .read_n
		input  wire        new_sdram_controller_0_s1_write_n,       //                            .write_n
		output wire [15:0] new_sdram_controller_0_s1_readdata,      //                            .readdata
		output wire        new_sdram_controller_0_s1_readdatavalid, //                            .readdatavalid
		output wire        new_sdram_controller_0_s1_waitrequest,   //                            .waitrequest
		output wire [12:0] new_sdram_controller_0_wire_addr,        // new_sdram_controller_0_wire.addr
		output wire [1:0]  new_sdram_controller_0_wire_ba,          //                            .ba
		output wire        new_sdram_controller_0_wire_cas_n,       //                            .cas_n
		output wire        new_sdram_controller_0_wire_cke,         //                            .cke
		output wire        new_sdram_controller_0_wire_cs_n,        //                            .cs_n
		inout  wire [15:0] new_sdram_controller_0_wire_dq,          //                            .dq
		output wire [1:0]  new_sdram_controller_0_wire_dqm,         //                            .dqm
		output wire        new_sdram_controller_0_wire_ras_n,       //                            .ras_n
		output wire        new_sdram_controller_0_wire_we_n,        //                            .we_n
		input  wire        sys_sdram_pll_0_ref_reset_reset,         //   sys_sdram_pll_0_ref_reset.reset
		output wire        sys_sdram_pll_0_sdram_clk_clk            //   sys_sdram_pll_0_sdram_clk.clk
	);

	wire    sys_sdram_pll_0_sys_clk_clk;        // sys_sdram_pll_0:sys_clk_clk -> [new_sdram_controller_0:clk, rst_controller:clk]
	wire    rst_controller_reset_out_reset;     // rst_controller:reset_out -> new_sdram_controller_0:reset_n
	wire    sys_sdram_pll_0_reset_source_reset; // sys_sdram_pll_0:reset_source_reset -> rst_controller:reset_in0

	sdram_new_sdram_controller_0 new_sdram_controller_0 (
		.clk            (sys_sdram_pll_0_sys_clk_clk),             //   clk.clk
		.reset_n        (~rst_controller_reset_out_reset),         // reset.reset_n
		.az_addr        (new_sdram_controller_0_s1_address),       //    s1.address
		.az_be_n        (new_sdram_controller_0_s1_byteenable_n),  //      .byteenable_n
		.az_cs          (new_sdram_controller_0_s1_chipselect),    //      .chipselect
		.az_data        (new_sdram_controller_0_s1_writedata),     //      .writedata
		.az_rd_n        (new_sdram_controller_0_s1_read_n),        //      .read_n
		.az_wr_n        (new_sdram_controller_0_s1_write_n),       //      .write_n
		.za_data        (new_sdram_controller_0_s1_readdata),      //      .readdata
		.za_valid       (new_sdram_controller_0_s1_readdatavalid), //      .readdatavalid
		.za_waitrequest (new_sdram_controller_0_s1_waitrequest),   //      .waitrequest
		.zs_addr        (new_sdram_controller_0_wire_addr),        //  wire.export
		.zs_ba          (new_sdram_controller_0_wire_ba),          //      .export
		.zs_cas_n       (new_sdram_controller_0_wire_cas_n),       //      .export
		.zs_cke         (new_sdram_controller_0_wire_cke),         //      .export
		.zs_cs_n        (new_sdram_controller_0_wire_cs_n),        //      .export
		.zs_dq          (new_sdram_controller_0_wire_dq),          //      .export
		.zs_dqm         (new_sdram_controller_0_wire_dqm),         //      .export
		.zs_ras_n       (new_sdram_controller_0_wire_ras_n),       //      .export
		.zs_we_n        (new_sdram_controller_0_wire_we_n)         //      .export
	);

	sdram_sys_sdram_pll_0 sys_sdram_pll_0 (
		.ref_clk_clk        (clk_clk),                            //      ref_clk.clk
		.ref_reset_reset    (sys_sdram_pll_0_ref_reset_reset),    //    ref_reset.reset
		.sys_clk_clk        (sys_sdram_pll_0_sys_clk_clk),        //      sys_clk.clk
		.sdram_clk_clk      (sys_sdram_pll_0_sdram_clk_clk),      //    sdram_clk.clk
		.reset_source_reset (sys_sdram_pll_0_reset_source_reset)  // reset_source.reset
	);

	altera_reset_controller #(
		.NUM_RESET_INPUTS          (1),
		.OUTPUT_RESET_SYNC_EDGES   ("deassert"),
		.SYNC_DEPTH                (2),
		.RESET_REQUEST_PRESENT     (0),
		.RESET_REQ_WAIT_TIME       (1),
		.MIN_RST_ASSERTION_TIME    (3),
		.RESET_REQ_EARLY_DSRT_TIME (1),
		.USE_RESET_REQUEST_IN0     (0),
		.USE_RESET_REQUEST_IN1     (0),
		.USE_RESET_REQUEST_IN2     (0),
		.USE_RESET_REQUEST_IN3     (0),
		.USE_RESET_REQUEST_IN4     (0),
		.USE_RESET_REQUEST_IN5     (0),
		.USE_RESET_REQUEST_IN6     (0),
		.USE_RESET_REQUEST_IN7     (0),
		.USE_RESET_REQUEST_IN8     (0),
		.USE_RESET_REQUEST_IN9     (0),
		.USE_RESET_REQUEST_IN10    (0),
		.USE_RESET_REQUEST_IN11    (0),
		.USE_RESET_REQUEST_IN12    (0),
		.USE_RESET_REQUEST_IN13    (0),
		.USE_RESET_REQUEST_IN14    (0),
		.USE_RESET_REQUEST_IN15    (0),
		.ADAPT_RESET_REQUEST       (0)
	) rst_controller (
		.reset_in0      (sys_sdram_pll_0_reset_source_reset), // reset_in0.reset
		.clk            (sys_sdram_pll_0_sys_clk_clk),        //       clk.clk
		.reset_out      (rst_controller_reset_out_reset),     // reset_out.reset
		.reset_req      (),                                   // (terminated)
		.reset_req_in0  (1'b0),                               // (terminated)
		.reset_in1      (1'b0),                               // (terminated)
		.reset_req_in1  (1'b0),                               // (terminated)
		.reset_in2      (1'b0),                               // (terminated)
		.reset_req_in2  (1'b0),                               // (terminated)
		.reset_in3      (1'b0),                               // (terminated)
		.reset_req_in3  (1'b0),                               // (terminated)
		.reset_in4      (1'b0),                               // (terminated)
		.reset_req_in4  (1'b0),                               // (terminated)
		.reset_in5      (1'b0),                               // (terminated)
		.reset_req_in5  (1'b0),                               // (terminated)
		.reset_in6      (1'b0),                               // (terminated)
		.reset_req_in6  (1'b0),                               // (terminated)
		.reset_in7      (1'b0),                               // (terminated)
		.reset_req_in7  (1'b0),                               // (terminated)
		.reset_in8      (1'b0),                               // (terminated)
		.reset_req_in8  (1'b0),                               // (terminated)
		.reset_in9      (1'b0),                               // (terminated)
		.reset_req_in9  (1'b0),                               // (terminated)
		.reset_in10     (1'b0),                               // (terminated)
		.reset_req_in10 (1'b0),                               // (terminated)
		.reset_in11     (1'b0),                               // (terminated)
		.reset_req_in11 (1'b0),                               // (terminated)
		.reset_in12     (1'b0),                               // (terminated)
		.reset_req_in12 (1'b0),                               // (terminated)
		.reset_in13     (1'b0),                               // (terminated)
		.reset_req_in13 (1'b0),                               // (terminated)
		.reset_in14     (1'b0),                               // (terminated)
		.reset_req_in14 (1'b0),                               // (terminated)
		.reset_in15     (1'b0),                               // (terminated)
		.reset_req_in15 (1'b0)                                // (terminated)
	);

endmodule
