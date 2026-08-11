//=============================================================================
// tb_shift_reg8.v  -  self-checking testbench for the shift register
//
// שתי אסטרטגיות בדיקה במקביל:
//   1. מודל ייחוס שרץ בכל מחזור ומושווה ל-DUT
//   2. בדיקה מכוונת: מזינים דפוס ידוע ביט-ביט, ואחרי 8 מחזורים
//      מוודאים שהוא הופיע שלם ברגיסטר.
//
// השנייה היא מה שנקרא end-to-end check - היא בודקת את *הכוונה*
// של המודול, לא רק את המימוש שלו.
//=============================================================================

`timescale 1ns / 1ps

module tb_shift_reg8;

    reg        clk = 1'b0;
    reg        rst = 1'b0;
    reg        en  = 1'b1;
    reg        sin = 1'b0;
    wire [7:0] q;
    wire       sout;

    reg  [7:0] ref_q    = 8'b0;
    reg        check_on = 1'b0;
    integer    errors   = 0;
    integer    checks   = 0;
    integer    i;

    localparam [7:0] PATTERN = 8'b1011_0010;

    always #5 clk = ~clk;

    shift_reg8 dut (
        .clk  ( clk  ),
        .rst  ( rst  ),
        .en   ( en   ),
        .sin  ( sin  ),
        .q    ( q    ),
        .sout ( sout )
    );

    // --- מודל ייחוס ---
    always @(posedge clk) begin
        if (rst)     ref_q <= 8'b0;
        else if (en) ref_q <= { ref_q[6:0], sin };
    end

    // --- בודק ---
    always @(negedge clk) begin
        #2;
        if (check_on) begin
            checks = checks + 1;
            if (q !== ref_q) begin
                $display("  FAIL @%0t  rst=%b en=%b sin=%b   q=%b  expected=%b",
                         $time, rst, en, sin, q, ref_q);
                errors = errors + 1;
            end
            if (sout !== ref_q[7]) begin
                $display("  FAIL @%0t  sout=%b  expected=%b (= q[7])",
                         $time, sout, ref_q[7]);
                errors = errors + 1;
            end
        end
    end

    initial begin
        $dumpfile("tb_shift_reg8.vcd");
        $dumpvars(0, tb_shift_reg8);

        $display("");
        $display("==========================================");
        $display(" tb_shift_reg8");
        $display("==========================================");

        // ---- reset ----
        rst = 1'b1; en = 1'b1; sin = 1'b0;
        @(negedge clk);
        @(negedge clk);
        rst = 1'b0;
        check_on = 1'b1;

        @(negedge clk);
        if (q !== 8'b0) begin
            $display("  FAIL  reset did not clear the register: q=%b", q);
            errors = errors + 1;
        end

        // ---- בדיקה מכוונת: להזין 10110010 ביט-ביט, MSB ראשון ----
        $display("  shifting in pattern %b, MSB first...", PATTERN);
        for (i = 7; i >= 0; i = i - 1) begin
            sin = PATTERN[i];
            @(negedge clk);
        end
        #1;
        checks = checks + 1;
        if (q === PATTERN)
            $display("  ok    after 8 clocks the register holds %b", q);
        else begin
            $display("  FAIL  after 8 clocks q=%b, expected %b", q, PATTERN);
            errors = errors + 1;
        end

        // ---- בדיקת enable: הרגיסטר חייב לקפוא ----
        en = 1'b0;
        sin = 1'b1;
        $display("  en=0 for 4 clocks - the register must not move");
        for (i = 0; i < 4; i = i + 1) @(negedge clk);
        #1;
        checks = checks + 1;
        if (q === PATTERN)
            $display("  ok    register held its value while en=0");
        else begin
            $display("  FAIL  register changed while en=0: q=%b", q);
            errors = errors + 1;
        end
        en = 1'b1;

        // ---- גירויים אקראיים ----
        for (i = 0; i < 60; i = i + 1) begin
            @(negedge clk);
            sin = $random;
            en  = $random;
        end

        // ---- reset באמצע פעולה ----
        @(negedge clk); en = 1'b1; rst = 1'b1;
        @(negedge clk); rst = 1'b0;
        #1;
        checks = checks + 1;
        if (q === 8'b0)
            $display("  ok    synchronous reset cleared the register mid-operation");
        else begin
            $display("  FAIL  reset did not clear: q=%b", q);
            errors = errors + 1;
        end

        for (i = 0; i < 20; i = i + 1) begin
            @(negedge clk);
            sin = $random;
        end

        @(negedge clk);
        #3;

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
