module cube_comb (
    input  logic [31:0] x,
    output logic [31:0] y
);

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
            logic        take;
            logic [31:0] hi_sub;
            logic [25:0] p_next;

            // hi = r >> S, lo = r mod 2^S
            assign hi = r[i] >> S;
            assign lo = r[i] & (32'hFFFFFFFF >> (32 - S));

            // x >= p * 2^S  <=>  hi >= p
            assign take = (hi >= p[i]);

            // narrow subtraction: only hi participates
            assign hi_sub = hi - p[i];

            assign r[i+1] = take ? ((hi_sub << S) | lo)
                                 : r[i];

            assign q[i+1] = take ? {q[i], 1'b1}
                                 : {q[i], 1'b0};

            // p_next = 4*p + take*(6*y + 6) - 6*y - 3
            assign p_next = 26'(4 * p[i])
                          + (take ? 26'(6 * (2 * q[i] + 1)) : 26'd0)
                          - 26'(6 * q[i])
                          - 26'd3;

            assign p[i+1] = p_next[23:0];
        end
    endgenerate

    assign y = {21'd0, q[11]};

endmodule
