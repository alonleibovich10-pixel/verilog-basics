//=============================================================================
// tb_decoder3to8.v  -  exhaustive self-checking testbench
//
// שים לב: כאן הבדיקה היא *ממצה* (exhaustive) - 16 קומבינציות בלבד
// (2 ערכי en כפול 8 ערכי sel), אז אפשר לבדוק את כולן.
//
// זו תובנה אמיתית מעולם ה-verification: כשמרחב הקלט קטן - בודקים הכל
// ואין מה לדבר. כשהוא גדול (כמו ALU של 32 ביט) - עוברים לאקראיות
// מכוונת ולכיסוי. זה בדיוק מה שתעשה בשבוע 2.
//=============================================================================

`timescale 1ns / 1ps

module tb_decoder3to8;

    reg  [2:0] sel;
    reg        en;
    wire [7:0] y;

    reg  [7:0] expected;
    integer    errors;
    integer    checks;
    integer    i;

    decoder3to8 dut (
        .sel ( sel ),
        .en  ( en  ),
        .y   ( y   )
    );

    task check;
        begin
            checks = checks + 1;

            if (en === 1'b0)
                expected = 8'b0000_0000;
            else
                expected = 8'b0000_0001 << sel;

            if (y !== expected) begin
                $display("  FAIL  en=%b sel=%b   y=%b  expected=%b",
                         en, sel, y, expected);
                errors = errors + 1;
            end else begin
                $display("  ok    en=%b sel=%b   y=%b", en, sel, y);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_decoder3to8.vcd");
        $dumpvars(0, tb_decoder3to8);

        errors = 0;
        checks = 0;

        $display("");
        $display("==========================================");
        $display(" tb_decoder3to8 - exhaustive test");
        $display("==========================================");

        // כל 16 הקומבינציות
        en = 1'b0;
        for (i = 0; i < 8; i = i + 1) begin
            sel = i[2:0];
            #5 check;
            #5;
        end

        en = 1'b1;
        for (i = 0; i < 8; i = i + 1) begin
            sel = i[2:0];
            #5 check;
            #5;
        end

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
