//=============================================================================
// tb_mux4.v  -  self-checking testbench for mux4
//
// ה-TB הזה כתוב לך מראש. אל תשנה אותו - הוא הבוחן שלך.
// (בשבוע 2 תכתוב כאלה בעצמך, וזה יהיה הנושא המרכזי של השבוע.)
//
// "Self-checking" = ה-TB יודע לבד מה התשובה הנכונה, משווה, וסופר שגיאות.
// זה ההבדל בין TB של סטודנט (מסתכל על גלים בעיניים) לבין TB של מהנדס.
//=============================================================================

`timescale 1ns / 1ps

module tb_mux4;

    // --- אותות שמזינים את ה-DUT (Device Under Test) ---
    reg  [7:0] in0, in1, in2, in3;
    reg  [1:0] sel;
    wire [7:0] y;

    // --- ניהול הבדיקה ---
    reg  [7:0] expected;
    integer    errors;
    integer    checks;
    integer    i, j;

    // --- המודול שנבדק ---
    mux4 dut (
        .in0 ( in0 ),
        .in1 ( in1 ),
        .in2 ( in2 ),
        .in3 ( in3 ),
        .sel ( sel ),
        .y   ( y   )
    );

    // --- משימת הבדיקה: מחשבת את התשובה הנכונה ומשווה ---
    task check;
        begin
            checks = checks + 1;
            case (sel)
                2'd0: expected = in0;
                2'd1: expected = in1;
                2'd2: expected = in2;
                2'd3: expected = in3;
            endcase

            // !== ולא != : האופרטור הזה משווה גם X ו-Z.
            // אם שכחת לחבר משהו, y יהיה X, ו-!= היה מחזיר X (לא "שקר").
            if (y !== expected) begin
                $display("  FAIL  sel=%0d  in=(%h %h %h %h)  y=%h  expected=%h",
                         sel, in0, in1, in2, in3, y, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("tb_mux4.vcd");
        $dumpvars(0, tb_mux4);

        errors = 0;
        checks = 0;

        $display("");
        $display("==========================================");
        $display(" tb_mux4 - starting");
        $display("==========================================");

        // ---- בדיקה 1: וקטורים מכוונים, סורקים את כל ערכי sel ----
        in0 = 8'hA1; in1 = 8'hB2; in2 = 8'hC3; in3 = 8'hD4;
        for (i = 0; i < 4; i = i + 1) begin
            sel = i[1:0];
            #5 check;
            #5;
        end

        // ---- בדיקה 2: 100 וקטורים אקראיים ----
        for (j = 0; j < 25; j = j + 1) begin
            in0 = $random;
            in1 = $random;
            in2 = $random;
            in3 = $random;
            for (i = 0; i < 4; i = i + 1) begin
                sel = i[1:0];
                #5 check;
                #5;
            end
        end

        // ---- סיכום ----
        $display("------------------------------------------");
        if (errors == 0)
            $display(" TESTS: %0d PASSED, 0 FAILED   ***  PASS  ***", checks);
        else
            $display(" TESTS: %0d run, %0d FAILED    ***  FAIL  ***", checks, errors);
        $display("==========================================");
        $display("");

        $finish;
    end

endmodule
