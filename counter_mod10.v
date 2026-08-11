//=============================================================================
// counter_mod10.v  -  decade counter (0..9, then wrap to 0)

//=============================================================================

`timescale 1ns / 1ps
`default_nettype none

module counter_mod10 (
    input  wire       clk,
    input  wire       rst,     // reset סינכרוני, פעיל גבוה
    input  wire       en,      // enable
    output reg  [3:0] count,   // 0..9
    output wire       tick     // גבוה כשהמונה עומד להתאפס במחזור הבא
);


    always @(posedge clk) begin
        if (rst)
            count <= 4'd0;
        else if (en) begin
            if (count == 4'd9)
                count <= 4'd0;        // גלישה
            else
                count <= count + 1'b1;
        end
    end
    

    assign tick = en && (count == 4'd9);


endmodule

`default_nettype wire
