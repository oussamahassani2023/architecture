/*
 * tb.v
 *
 *  Created on: 17.10.2019
 *      Author: Alexander Antonov <antonov.alex.alex@gmail.com>
 *     License: See LICENSE file for details
 */


`timescale 1ns / 1ps

`define HALF_PERIOD			5						//external 100 MHZ
`define DIVIDER_115200		32'd8680
`define DIVIDER_19200		32'd52083
`define DIVIDER_9600		32'd104166
`define DIVIDER_4800		32'd208333
`define DIVIDER_2400		32'd416666


module tb ();
//
logic CLK_100MHZ, RST, rx;
logic [15:0] SW;
logic [15:0] LED;

always #`HALF_PERIOD CLK_100MHZ = ~CLK_100MHZ;

always #1000 SW = SW + 8'h1;
	
NEXYS4_DDR
#(
	.SIM("YES")
) DUT (
	.CLK100MHZ(CLK_100MHZ)
    , .CPU_RESETN(!RST)
    
    , .SW(SW)
    , .LED(LED)

    , .UART_TXD_IN(rx)
    , .UART_RXD_OUT()
);

////reset all////
task RESET_ALL ();
    begin
    CLK_100MHZ = 1'b0;
    RST = 1'b1;
    rx = 1'b1;
    #(`HALF_PERIOD/2);
    RST = 1;
    #(`HALF_PERIOD*6);
    RST = 0;
    while (DUT.srst) WAIT(10);
    end
endtask

////wait////
task WAIT
    (
     input logic [15:0] periods
     );
    begin
    integer i;
    for (i=0; i<periods; i=i+1)
        begin
        #(`HALF_PERIOD*2);
        end
    end
endtask

`define UDM_RX_SIGNAL rx
`define UDM_BLOCK DUT.udm
`include "udm.svh"
udm_driver udm = new();

/////////////////////////
// main test procedure //
localparam CSR_LED_ADDR         = 32'h00000000;
localparam CSR_SW_ADDR          = 32'h00000004;
localparam TESTMEM_ADDR         = 32'h80000000;

localparam CSR_CUBE_X_ADDR      = 32'h10000000;
localparam CSR_CUBE_Y_ADDR      = 32'h20000000;

integer cube_checks = 0;
integer cube_errors = 0;

// check: y^3 <= x < (y+1)^3  (floor cube root), computed on the value read back over UDM
task automatic test_cube(input logic [31:0] xv);
    logic [31:0] got;
    logic [63:0] lo, hi;
    begin
    udm.wr32(CSR_CUBE_X_ADDR, xv);
    udm.rd32(CSR_CUBE_Y_ADDR);
    got = DUT.udm.bus_rdata_bi;
    lo = 64'(got) * 64'(got) * 64'(got);
    hi = (64'(got) + 64'd1) * (64'(got) + 64'd1) * (64'(got) + 64'd1);
    cube_checks = cube_checks + 1;
    if ((lo <= 64'(xv)) && (64'(xv) < hi))
        $display("CUBE OK: x=0x%h y=0x%h", xv, got);
    else
        begin
        cube_errors = cube_errors + 1;
        $display("CUBE ERROR: x=0x%h got=0x%h", xv, got);
        end
    end
endtask

initial
    begin
    logic [31:0] wrdata [];
    integer ARRSIZE=10;
    
	$display ("### SIMULATION STARTED ###");
	
	SW = 8'h30;
	RESET_ALL();
	WAIT(100);

	udm.cfg(`DIVIDER_115200, 2'b00);
	udm.check();
	udm.hreset();
	WAIT(100);
	
	// cube root tests: write x to 0x10000000, read y from 0x20000000
	test_cube(32'd0);
	test_cube(32'd1);
	test_cube(32'd7);
	test_cube(32'd8);
	test_cube(32'd26);
	test_cube(32'd27);
	test_cube(32'd28);
	test_cube(32'd1000);
	test_cube(32'd999999);
	test_cube(32'd1000000);
	test_cube(32'h12345678);
	test_cube(32'h7fffffff);
	test_cube(32'h80000000);
	test_cube(32'hfffffffe);
	test_cube(32'hffffffff);
	for (int k = 0; k < 20; k++) test_cube($urandom);
	$display("CUBE TESTS DONE: %0d checked, %0d errors", cube_checks, cube_errors);

	WAIT(1000);

	$display ("### TEST PROCEDURE FINISHED ###");
	$stop;
    end


endmodule
