// Variant 7: integer cube root, purely combinational implementation.
// Bit-exact match of cube_hw() from 7-cubic.py (11 unrolled stages, s = 30, 27, ..., 0).
module cube_comb (
    input  logic [31:0] x,
    output logic [31:0] y
);
    localparam int N = 11;

    // 40-bit intermediates: b = (3*y*(y+1)+1) << s must never wrap
    logic [39:0] xs [0:N];
    logic [10:0] ys [0:N];

    assign xs[0] = {8'b0, x};
    assign ys[0] = 11'd0;

    genvar i;
    generate
        for (i = 0; i < N; i++) begin : stage
            localparam int S = 30 - 3*i;

            logic [10:0] y2;     // y = 2*y
            logic [39:0] y2w;
            logic [39:0] b;
            logic        ge;

            assign y2  = {ys[i][9:0], 1'b0};
            assign y2w = {29'b0, y2};
            assign b   = ((40'd3 * y2w * (y2w + 40'd1)) + 40'd1) << S;
            assign ge  = (xs[i] >= b);

            assign xs[i+1] = ge ? (xs[i] - b) : xs[i];
            assign ys[i+1] = y2 | {10'b0, ge};   // y2[0] == 0, so "+1" is an OR
        end
    endgenerate

    assign y = {21'b0, ys[N]};
endmodule
