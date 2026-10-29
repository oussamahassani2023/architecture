module cube_comb (
    input  logic [31:0] x,
    output logic [31:0] y
);

    // r[i] : scaled remainder
    // q[i] : cube-root prefix
    // p[i] : 3*q^2 + 3*q + 1

    logic [31:0] r [11:0];
    logic [10:0] q [11:0];
    logic [23:0] p [11:0];

    assign r[0] = x;
    assign q[0] = 11'd0;
    assign p[0] = 24'd1;

    genvar i;
    generate
        for (i = 0; i < 11; i++) begin : stage
            localparam int S = 30 - 3*i;

            logic [31:0] hi;
            logic [31:0] lo;
            logic [23:0] p2;
            logic        take;
            logic [31:0] hi_sub;
            logic [25:0] p_next;

            assign hi = r[i] >> S;
            assign lo = r[i] & (32'hFFFFFFFF >> (32 - S));

            // p for doubled prefix: 3*(2y)^2 + 3*(2y) + 1
            assign p2 = 24'(4 * p[i]) - 24'(6 * q[i]) - 24'd3;

            // correct threshold for this stage
            assign take = (hi >= p2);

            assign hi_sub = hi - p2;

            assign r[i+1] = take ? ((hi_sub << S) | lo)
                                 : r[i];

            assign q[i+1] = take ? {q[i], 1'b1}
                                 : {q[i], 1'b0};

            // p for 2y+1 = p2 + 12y + 6
            assign p_next = 26'(p2)
                          + (take ? 26'(12 * q[i] + 6) : 26'd0);

            assign p[i+1] = p_next[23:0];
        end
    endgenerate

    assign y = {21'd0, q[11]};

endmodule
