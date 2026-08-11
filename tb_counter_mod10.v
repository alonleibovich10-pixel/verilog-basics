//=============================================================================
// tb_counter_mod10.v  -  self-checking testbench for the decade counter
//
// כאן נכנס סוג בדיקה חדש: **תכונה שחייבת להתקיים תמיד** (invariant).
// לא "מה הערך הבא" אלא "המונה לעולם לא יוצא מהטווח 0..9".
//
// זו בדיוק החשיבה שמאחורי assertions, שהם הנושא של שבוע 2.
// כאן אנחנו כותבים אותן ידנית ב-Verilog רגיל.
//=============================================================================

`timescale 1ns / 1ps

module tb_counter_mod10;

    reg        clk = 1'b0;
    reg        rst = 1'b0;
    reg        en  = 1'b1;
    wire [3:0] count;
    wire       tick;

    reg  [3:0] ref_count = 4'd0;
    reg        check_on  = 1'b0;
    integer    errors    = 0;
    integer    checks    = 0;
    integer    ticks_seen = 0;
    integer    i;

    always #5 clk = ~clk;

    counter_mod10 dut (
        .clk   ( clk   ),
        .rst   ( rst   ),
        .en    ( en    ),
        .count ( count ),
        .tick  ( tick  )
    );

    // --- מודל ייחוס ---
    always @(posedge clk) begin
        if (rst)
            ref_count <= 4'd0;
        else if (en) begin
            if (ref_count == 4'd9) ref_count <= 4'd0;
            else                   ref_count <= ref_count + 1'b1;
        end
    end

    // --- בודק ---
    always @(negedge clk) begin
        #2;
        if (check_on) begin
            checks = checks + 1;

            // 1. הערך תואם למודל
            if (count !== ref_count) begin
                $display("  FAIL @%0t  rst=%b en=%b   count=%0d  expected=%0d",
                         $time, rst, en, count, ref_count);
                errors = errors + 1;
            end

            // 2. INVARIANT: לעולם לא מחוץ לטווח
            if (count > 4'd9) begin
                $display("  FAIL @%0t  count=%0d is out of range (max 9)", $time, count);
                errors = errors + 1;
            end

            // 3. tick נכון בדיוק כש-count==9 וגם en
            if (tick !== ((count == 4'd9) && en)) begin
                $display("  FAIL @%0t  tick=%b  count=%0d en=%b  expected tick=%b",
                         $time, tick, count, en, ((count == 4'd9) && en));
                errors = errors + 1;
            end

            if (tick === 1'b1) ticks_seen = ticks_seen + 1;
        end
    end

    initial begin
        $dumpfile("tb_counter_mod10.vcd");
        $dumpvars(0, tb_counter_mod10);

        $display("");
        $display("==========================================");
        $display(" tb_counter_mod10");
        $display("==========================================");

        rst = 1'b1; en = 1'b1;
        @(negedge clk);
        @(negedge clk);
        rst = 1'b0;
        check_on = 1'b1;

        // ---- שלוש גלישות מלאות: 30 מחזורים ----
        $display("  running 3 full wraps (30 clocks)...");
        for (i = 0; i < 30; i = i + 1) @(negedge clk);

        checks = checks + 1;
        if (ticks_seen == 3)
            $display("  ok    saw exactly 3 ticks in 30 clocks");
        else begin
            $display("  FAIL  saw %0d ticks in 30 clocks, expected 3", ticks_seen);
            errors = errors + 1;
        end

        // ---- הקפאה: en=0 למשך 6 מחזורים ----
        @(negedge clk);
        en = 1'b0;
        $display("  freezing with en=0 for 6 clocks...");
        for (i = 0; i < 6; i = i + 1) @(negedge clk);
        en = 1'b1;

        // ---- reset באמצע ספירה ----
        for (i = 0; i < 5; i = i + 1) @(negedge clk);
        @(negedge clk); rst = 1'b1;
        @(negedge clk); rst = 1'b0;
        #1;
        checks = checks + 1;
        if (count === 4'd0)
            $display("  ok    reset returned the counter to 0");
        else begin
            $display("  FAIL  after reset count=%0d, expected 0", count);
            errors = errors + 1;
        end

        // ---- enable אקראי, הרבה מחזורים ----
        for (i = 0; i < 120; i = i + 1) begin
            @(negedge clk);
            en = $random;
        end

        en = 1'b1;
        for (i = 0; i < 25; i = i + 1) @(negedge clk);

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
