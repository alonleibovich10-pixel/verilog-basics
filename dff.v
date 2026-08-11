//=============================================================================
// dff.v  -  D flip-flops: synchronous vs asynchronous reset

//=============================================================================

`timescale 1ns / 1ps
`default_nettype none

//-----------------------------------------------------------------------------
// d_ff  :  D flip-flop with SYNCHRONOUS reset

//-----------------------------------------------------------------------------
module d_ff (
    input  wire clk,
    input  wire rst,
    input  wire d,
    output reg  q
);


    always @(posedge clk) begin
        if (rst)
            q <= 1'b0;
        else
            q <= d;
    end


endmodule


//-----------------------------------------------------------------------------
// d_ff_async  :  D flip-flop with ASYNCHRONOUS reset
//-----------------------------------------------------------------------------
module d_ff_async (
    input  wire clk,
    input  wire rst,
    input  wire d,
    output reg  q
);


    always @(posedge clk or posedge rst) begin
        if (rst)
            q <= 1'b0;
        else
            q <= d;
    end



endmodule


//-----------------------------------------------------------------------------
// d_ff_en  :  D flip-flop with clock enable

//-----------------------------------------------------------------------------
module d_ff_en (
    input  wire clk,
    input  wire rst,
    input  wire en,
    input  wire d,
    output reg  q
);

    
    always @(posedge clk) begin
        if (rst)      q <= 1'b0;
        else if (en)  q <= d;

    end


endmodule

`default_nettype wire
