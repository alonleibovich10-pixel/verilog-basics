//=============================================================================
// tb_dff.v  -  self-checking testbench for the three flip-flops
//
// חדש ביום 3: הטסטבנץ' מייצר **שעון**, ומחזיק **מודל ייחוס** שרץ
// במקביל ל-DUT ומשווה אליו בכל מחזור.
//
// שים לב לתבנית התזמון - היא סטנדרט תעשייתי:
//   - מזינים גירויים ב-negedge (רחוק מהקצה הפעיל)
//   - בודקים גם ב-negedge, אחרי השהיה קטנה
// ככה אף פעם לא נופלים על race בין הגירוי לבין הדגימה.
//=============================================================================

`timescale 1ns / 1ps

module tb_dff;

    reg clk = 1'b0;
    reg rst = 1'b0;
    reg en  = 1'b1;
    reg d   = 1'b0;

    wire q_sync, q_async, q_en;

    // --- מודלי ייחוס ---
    reg ref_sync  = 1'b0;
    reg ref_async = 1'b0;
    reg ref_en    = 1'b0;

    reg check_on  = 1'b0;
    integer errors = 0;
    integer checks = 0;

    // --- שעון 100MHz: מחזור 10ns ---
    always #5 clk = ~clk;

    // --- המודולים שנבדקים ---
    d_ff       u_sync  ( .clk(clk), .rst(rst),           .d(d), .q(q_sync)  );
    d_ff_async u_async ( .clk(clk), .rst(rst),           .d(d), .q(q_async) );
    d_ff_en    u_en    ( .clk(clk), .rst(rst), .en(en),  .d(d), .q(q_en)    );

    // --- מודלי הייחוס: מה *אמור* לקרות ---
    always @(posedge clk) begin
        if (rst) ref_sync <= 1'b0;
        else     ref_sync <= d;
    end

    always @(posedge clk or posedge rst) begin
        if (rst) ref_async <= 1'b0;
        else     ref_async <= d;
    end

    always @(posedge clk) begin
        if (rst)     ref_en <= 1'b0;
        else if (en) ref_en <= d;
    end

    // --- הבודק: רץ בכל negedge, רחוק מהקצה הפעיל ---
    always @(negedge clk) begin
        #2;
        if (check_on) begin
            checks = checks + 1;

            if (q_sync !== ref_sync) begin
                $display("  FAIL @%0t  d_ff (sync rst)   rst=%b d=%b  q=%b  expected=%b",
                         $time, rst, d, q_sync, ref_sync);
                errors = errors + 1;
            end
            if (q_async !== ref_async) begin
                $display("  FAIL @%0t  d_ff_async       rst=%b d=%b  q=%b  expected=%b",
                         $time, rst, d, q_async, ref_async);
                errors = errors + 1;
            end
            if (q_en !== ref_en) begin
                $display("  FAIL @%0t  d_ff_en          rst=%b en=%b d=%b  q=%b  expected=%b",
                         $time, rst, en, d, q_en, ref_en);
                errors = errors + 1;
            end
        end
    end

    integer i;

    initial begin
        $dumpfile("tb_dff.vcd");
        $dumpvars(0, tb_dff);

        $display("");
        $display("==========================================");
        $display(" tb_dff - flip-flops");
        $display("==========================================");

        // ---- 1. reset התחלתי ----
        rst = 1'b1; d = 1'b0; en = 1'b1;
        @(negedge clk);
        @(negedge clk);
        rst = 1'b0;
        check_on = 1'b1;

        // ---- 2. דגימה רגילה: d משתנה, q עוקב מחזור אחרי ----
        @(negedge clk); d = 1'b1;
        @(negedge clk); d = 1'b0;
        @(negedge clk); d = 1'b1;
        @(negedge clk); d = 1'b1;
        @(negedge clk); d = 1'b0;

        // ---- 3. גירויים אקראיים ----
        for (i = 0; i < 40; i = i + 1) begin
            @(negedge clk);
            d = $random;
        end

        // ---- 4. reset סינכרוני: נשאר גבוה על פני קצה שעון ----
        @(negedge clk); d = 1'b1; rst = 1'b1;
        @(negedge clk); rst = 1'b0;

        // ---- 5. *** המבחן המעניין ***  פולס reset קצר בין קצוות ----
        // rst עולה ויורד לגמרי בתוך מחזור, בלי לגעת בקצה עולה של clk.
        //   d_ff (סינכרוני)  -> מתעלם לחלוטין
        //   d_ff_async       -> מתאפס מיידית
        // אם שני המודולים שלך מתנהגים אותו דבר כאן - טעית באחד מהם.
        @(negedge clk); d = 1'b1;
        @(posedge clk);
        #1 rst = 1'b1;      // 1ns אחרי הקצה העולה
        #2 rst = 1'b0;      // ויורד 2ns אחר כך, הרבה לפני הקצה הבא

        @(negedge clk);
        @(negedge clk);

        // ---- 6. בדיקת ה-enable ----
        @(negedge clk); d = 1'b1; en = 1'b1;
        @(negedge clk); d = 1'b0; en = 1'b0;   // מכאן q_en קופא
        @(negedge clk); d = 1'b1;
        @(negedge clk); d = 1'b0;
        @(negedge clk); en = 1'b1;             // ומשתחרר
        @(negedge clk); d = 1'b1;
        @(negedge clk);

        // ---- 7. עוד אקראיות, הפעם גם על en ----
        for (i = 0; i < 40; i = i + 1) begin
            @(negedge clk);
            d  = $random;
            en = $random;
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
