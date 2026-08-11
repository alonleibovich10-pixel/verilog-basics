//=============================================================================
// shift_reg8.v  -  8-bit shift register (serial in, parallel + serial out)

//   לפני:   q = 1 0 1 1 0 0 1 0     sin = 1
//   אחרי:   q = 0 1 1 0 0 1 0 1


//=============================================================================

`timescale 1ns / 1ps
`default_nettype none

module shift_reg8 (
    input  wire       clk,
    input  wire       rst,     // reset סינכרוני, פעיל גבוה
    input  wire       en,      // enable - כשהוא 0, הרגיסטר קופא
    input  wire       sin,     // serial in  - הביט שנכנס מימין
    output reg  [7:0] q,       // parallel out - כל 8 הביטים
    output wire       sout     // serial out - הביט שעומד לצאת
);


    assign sout = q[7];


    always @(posedge clk) begin
        if (rst)
            q <= 8'b0;
        else if (en)
            q <= { q[6:0], sin };
    end


endmodule

`default_nettype wire
