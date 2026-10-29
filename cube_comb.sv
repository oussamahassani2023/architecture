module cube_comb (
    input  logic [31:0] x,
    output logic [31:0] y
);

    // r[i] : remaining value after stage i
    // q[i] : cube-root prefix after stage i
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

            logic       take;
            logic [31:0] sub;
            logic [25:0] p_next;

            // x >= p * 2^S  is equivalent to  (x >> S) >= p
            assign take = (r[i] >> S) >= p[i];

            // p * 2^S, truncated to 32 bits;
            // correct because the subtraction result always fits in 32 bits
            assign sub = p[i] << S;

            assign r[i+1] = take ? (r[i] - sub) : r[i];

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
