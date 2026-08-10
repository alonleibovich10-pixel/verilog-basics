`timescale 1ns / 1ps
`default_nettype none

module full_adder (
    input  wire a,
    input  wire b,
    input  wire cin,
    output wire sum,
    output wire cout
);

    assign sum  = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);

endmodule


module ripple_carry_adder #(
    parameter N = 8
)(
    input  wire [N-1:0] a,
    input  wire [N-1:0] b,
    input  wire         cin,
    output wire [N-1:0] sum,
    output wire         cout
);

    wire [N:0] c;

    assign c[0] = cin;

    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : fa_stage
            full_adder u_fa (
                .a    ( a[i]   ),
                .b    ( b[i]   ),
                .cin  ( c[i]   ),
                .sum  ( sum[i] ),
                .cout ( c[i+1] )
            );
        end
    endgenerate

    assign cout = c[N];

endmodule

`default_nettype wire