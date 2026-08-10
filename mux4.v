`timescale 1ns / 1ps
`default_nettype none      // מכריח הצהרה מפורשת על כל wire - תופס שגיאות הקלדה


module mux2 (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire       sel,
    output wire [7:0] y
);


    assign y = sel ? b : a;

endmodule


module mux4 (
    input  wire [7:0] in0,
    input  wire [7:0] in1,
    input  wire [7:0] in2,
    input  wire [7:0] in3,
    input  wire [1:0] sel,
    output wire [7:0] y
);


    wire [7:0] lo;   // התוצאה של in0/in1
    wire [7:0] hi;   // התוצאה של in2/in3


    // שלב 1, מוקס תחתון: בוחר בין in0 ל-in1
    mux2 u_lo (
        .a   ( in0    ),
        .b   ( in1    ),
        .sel ( sel[0] ),
        .y   ( lo     )
    );

    // שלב 1, מוקס עליון: בוחר בין in2 ל-in3
    mux2 u_hi (
        .a   ( in2    ),
        .b   ( in3    ),
        .sel ( sel[0] ),
        .y   ( hi     )
    );

    // שלב 2: בוחר איזו משתי התוצאות יוצאת החוצה
    mux2 u_out (
        .a   ( lo     ),
        .b   ( hi     ),
        .sel ( sel[1] ),
        .y   ( y      )
    );

endmodule

`default_nettype wire

