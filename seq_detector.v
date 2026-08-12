//=============================================================================
// seq_detector.v  -  "1011" sequence detector, Moore and Mealy side by side

//=============================================================================

`timescale 1ns / 1ps
`default_nettype none


//=============================================================================
module seq_detector_moore (
    input  wire clk,
    input  wire rst,        // reset סינכרוני, פעיל גבוה
    input  wire in,         // ביט אחד בכל מחזור
    output wire detected    // גבוה למחזור אחד כשזוהה 1011
);


    localparam [2:0] S0    = 3'd0,   // עוד לא ראיתי כלום שימושי
                     S1    = 3'd1,   // ראיתי "1"
                     S10   = 3'd2,   // ראיתי "10"
                     S101  = 3'd3,   // ראיתי "101"
                     S1011 = 3'd4;   // ראיתי "1011"  <- זיהוי!

    reg [2:0] state, next_state;


    // ------------------------------------------------------------------

    always @(posedge clk) begin
        if (rst) state <= S0;
        else     state <= next_state;
    end



    always @(*) begin
        case (state)
            S0:     next_state = in ? S1    : S0;
            S1:     next_state = in ? S1    : S10;
            S10:    next_state = in ? S101  : S0;
            S101: next_state = in ? S1011 : S10;   
            S1011:  next_state = in ? S1    : S10;
            default: next_state = S0;
        endcase
    end
    
    assign detected = (state == S1011);

endmodule



//=============================================================================
module seq_detector_mealy (
    input  wire clk,
    input  wire rst,
    input  wire in,
    output wire detected
);

    localparam [1:0] S0   = 2'd0,
                     S1   = 2'd1,
                     S10  = 2'd2,
                     S101 = 2'd3;

    reg [1:0] state, next_state;



    always @(posedge clk) begin
        if (rst) state <= S0;
        else     state <= next_state;
    end



    always @(*) begin
        case (state)
            S0:      next_state = in ? S1   : S0;
            S1:      next_state = in ? S1   : S10;
            S10:     next_state = in ? S101 : S0;
            S101:    next_state = in ? S1   : S10;  
            default: next_state = S0;
        endcase
    end


    assign detected = (state == S101) && in;

endmodule

`default_nettype wire
