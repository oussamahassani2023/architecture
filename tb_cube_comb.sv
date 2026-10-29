`timescale 1ns / 1ps
// Self-checking testbench. Independent check: y^3 <= x < (y+1)^3 (floor cube root).
module tb_cube_comb;
    logic [31:0] x;
    logic [31:0] y;
    int errors = 0;
    int checks = 0;

    cube_comb dut (.x(x), .y(y));

    task automatic check(input logic [31:0] xv);
        logic [63:0] lo, hi;
        x = xv;
        #1;
        lo = 64'(y) * 64'(y) * 64'(y);
        hi = (64'(y) + 64'd1) * (64'(y) + 64'd1) * (64'(y) + 64'd1);
        checks++;
        if (!(lo <= 64'(xv) && 64'(xv) < hi)) begin
            errors++;
            $display("ERROR! x=0x%h y=0x%h", xv, y);
        end
    endtask

    initial begin
        // directed
        check(32'd0); check(32'd1); check(32'd7); check(32'd8); check(32'd9);
        check(32'd26); check(32'd27); check(32'd28);
        check(32'hFFFF_FFFF); check(32'hFFFF_FFFE); check(32'h8000_0000);

        // all perfect cubes and their neighbours (n^3 <= 2^32-1 -> n <= 1625)
        for (int n = 0; n <= 1625; n++) begin
            check(n*n*n - 1);
            check(n*n*n);
            check(n*n*n + 1);
        end

        // random
        for (int k = 0; k < 100000; k++) check($urandom);

        if (errors == 0) $display("PASSED: %0d checks, no errors", checks);
        else             $display("FAILED: %0d errors of %0d checks", errors, checks);
        $finish;
    end
endmodule
