//=============================================================================
// tb_seq_detector.v  -  self-checking testbench for both FSM styles
//
// מודל הייחוס כאן שונה מכל מה שהיה עד עכשיו: במקום לשכפל את מכונת
// המצבים, הוא פשוט **זוכר את ארבעת הביטים האחרונים** בשיפט רגיסטר
// ומשווה אותם ל-1011.
//
// זו נקודה מתודולוגית חשובה: מודל ייחוס טוב מתאר את **הכוונה**,
// לא את המימוש. אילו הייתי משכפל את ה-FSM, טעות בדיאגרמת המצבים
// הייתה מופיעה בשניהם והבדיקה לא הייתה תופסת אותה.
//=============================================================================

`timescale 1ns / 1ps

module tb_seq_detector;

    reg  clk = 1'b0;
    reg  rst = 1'b0;
    reg  in  = 1'b0;

    wire det_moore, det_mealy;

    // מודל ייחוס: ארבעת הביטים האחרונים שנדגמו
    reg  [3:0] hist     = 4'b0;
    reg        check_on = 1'b0;

    integer errors = 0;
    integer checks = 0;
    integer moore_hits = 0;
    integer mealy_hits = 0;
    integer i;

    localparam [3:0] PATTERN = 4'b1011;

    always #5 clk = ~clk;

    seq_detector_moore u_moore (
        .clk(clk), .rst(rst), .in(in), .detected(det_moore)
    );

    seq_detector_mealy u_mealy (
        .clk(clk), .rst(rst), .in(in), .detected(det_mealy)
    );

    // --- מודל הייחוס: מתעדכן באותו קצה כמו המכונות ---
    always @(posedge clk) begin
        if (rst) hist <= 4'b0;
        else     hist <= { hist[2:0], in };
    end

    // --- הבודק ---
    always @(negedge clk) begin
        #2;
        if (check_on) begin
            checks = checks + 1;

            // Moore: הפלט משקף את ארבעת הביטים שכבר נדגמו
            if (det_moore !== (hist == PATTERN)) begin
                $display("  FAIL @%0t  MOORE  hist=%b in=%b  detected=%b  expected=%b",
                         $time, hist, in, det_moore, (hist == PATTERN));
                errors = errors + 1;
            end

            // Mealy: הפלט משקף את שלושת הביטים שנדגמו + הקלט הנוכחי
            if (det_mealy !== ({hist[2:0], in} == PATTERN)) begin
                $display("  FAIL @%0t  MEALY  hist=%b in=%b  detected=%b  expected=%b",
                         $time, hist, in, det_mealy, ({hist[2:0], in} == PATTERN));
                errors = errors + 1;
            end

            if (det_moore === 1'b1) moore_hits = moore_hits + 1;
            if (det_mealy === 1'b1) mealy_hits = mealy_hits + 1;
        end
    end

    // --- עזר: להזין ביט אחד ---
    task drive_bit;
        input b;
        begin
            @(negedge clk);
            in = b;
        end
    endtask

    initial begin
        $dumpfile("tb_seq_detector.vcd");
        $dumpvars(0, tb_seq_detector);

        $display("");
        $display("==========================================");
        $display(" tb_seq_detector  -  Moore vs Mealy");
        $display("==========================================");

        rst = 1'b1; in = 1'b0;
        @(negedge clk);
        @(negedge clk);
        rst = 1'b0;
        check_on = 1'b1;

        // ---------------------------------------------------------------
        // בדיקה מכוונת: הרצף 1011011011
        // מכיל שלוש התאמות חופפות - בביטים 0-3, 3-6, 6-9
        // ---------------------------------------------------------------
        $display("  driving 1011011011  (3 overlapping matches expected)");
        moore_hits = 0;
        mealy_hits = 0;

        drive_bit(1); drive_bit(0); drive_bit(1); drive_bit(1);
        drive_bit(0); drive_bit(1); drive_bit(1);
        drive_bit(0); drive_bit(1); drive_bit(1);

        // מחזור נוסף כדי ש-Moore יספיק להוציא את הזיהוי האחרון
        drive_bit(0);
        @(negedge clk); #3;

        checks = checks + 1;
        if (moore_hits == 3)
            $display("  ok    Moore detected 3 overlapping matches");
        else begin
            $display("  FAIL  Moore detected %0d matches, expected 3", moore_hits);
            errors = errors + 1;
        end

        checks = checks + 1;
        if (mealy_hits == 3)
            $display("  ok    Mealy detected 3 overlapping matches");
        else begin
            $display("  FAIL  Mealy detected %0d matches, expected 3", mealy_hits);
            errors = errors + 1;
        end

        // ---------------------------------------------------------------
        // מקרי קצה מכוונים
        // ---------------------------------------------------------------
        $display("  driving near-misses: 1010, 0011, 1111, 1101");
        drive_bit(1); drive_bit(0); drive_bit(1); drive_bit(0);
        drive_bit(0); drive_bit(0); drive_bit(1); drive_bit(1);
        drive_bit(1); drive_bit(1); drive_bit(1); drive_bit(1);
        drive_bit(1); drive_bit(1); drive_bit(0); drive_bit(1);

        // ---------------------------------------------------------------
        // reset באמצע רצף חלקי - המכונה חייבת לחזור להתחלה
        // ---------------------------------------------------------------
        $display("  reset in the middle of a partial match");
        drive_bit(1); drive_bit(0); drive_bit(1);   // אנחנו ב-S101
        @(negedge clk); rst = 1'b1;
        @(negedge clk); rst = 1'b0;
        drive_bit(1);   // אילו ה-reset לא עבד, זה היה נחשב זיהוי

        // ---------------------------------------------------------------
        // 400 ביטים אקראיים
        // ---------------------------------------------------------------
        $display("  driving 400 random bits...");
        for (i = 0; i < 400; i = i + 1) begin
            drive_bit($random);
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
