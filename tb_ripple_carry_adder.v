//=============================================================================
// tb_ripple_carry_adder.v  -  self-checking testbench, 8-bit instance
//
// אסטרטגיית הבדיקה כאן היא מה שנקרא "reference model comparison":
// אנחנו לא בונים את המחבר פעם שנייה בטסטבנץ' - אנחנו נותנים לסימולטור
// לחשב a+b+cin באריתמטיקה שלו, ומשווים.
//
// זה בדיוק העיקרון של scoreboard ב-UVM, ותכתוב עליו את שבוע 2.
//=============================================================================

`timescale 1ns / 1ps

module tb_ripple_carry_adder;

    localparam N = 8;

    reg  [N-1:0] a;
    reg  [N-1:0] b;
    reg          cin;
    wire [N-1:0] sum;
    wire         cout;

    reg  [N:0]   expected;      // N+1 ביט: מכיל גם את הנשא היוצא
    wire [N:0]   actual;

    integer      errors;
    integer      checks;
    integer      i;

    ripple_carry_adder #( .N(N) ) dut (
        .a    ( a    ),
        .b    ( b    ),
        .cin  ( cin  ),
        .sum  ( sum  ),
        .cout ( cout )
    );

    // שרשור: {cout, sum} הוא בעצם התוצאה המלאה של 9 ביט
    assign actual = {cout, sum};

    task check;
        begin
            checks = checks + 1;

            // הרחבה ל-N+1 ביט לפני החיבור, אחרת התוצאה נחתכת
            expected = {1'b0, a} + {1'b0, b} + cin;

            if (actual !== expected) begin
                $display("  FAIL  a=%0d b=%0d cin=%0d  ->  got %0d (cout=%b sum=%0d), expected %0d",
                         a, b, cin, actual, cout, sum, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("tb_ripple_carry_adder.vcd");
        $dumpvars(0, tb_ripple_carry_adder);

        errors = 0;
        checks = 0;

        $display("");
        $display("==========================================");
        $display(" tb_ripple_carry_adder (N=%0d)", N);
        $display("==========================================");

        // ---- מקרי קצה מכוונים ----
        // אלה המקרים שמהנדס verification מוסיף *ידנית*, כי אקראיות
        // כמעט לעולם לא תפגע בהם. שווה לזכור למשפט בראיון.
        a = 8'h00; b = 8'h00; cin = 1'b0; #5 check; #5;   // אפס
        a = 8'hFF; b = 8'h00; cin = 1'b0; #5 check; #5;   // מקסימום + אפס
        a = 8'hFF; b = 8'h01; cin = 1'b0; #5 check; #5;   // גלישה בדיוק
        a = 8'hFF; b = 8'hFF; cin = 1'b1; #5 check; #5;   // גלישה מקסימלית
        a = 8'h0F; b = 8'h01; cin = 1'b0; #5 check; #5;   // carry דרך ניבל
        a = 8'h7F; b = 8'h01; cin = 1'b0; #5 check; #5;   // מעבר סימן ב-2's comp
        a = 8'h00; b = 8'h00; cin = 1'b1; #5 check; #5;   // רק cin
        a = 8'hAA; b = 8'h55; cin = 1'b0; #5 check; #5;   // דפוס משלים
        a = 8'hAA; b = 8'h55; cin = 1'b1; #5 check; #5;   // ואותו דבר עם cin

        // ---- 500 וקטורים אקראיים ----
        for (i = 0; i < 500; i = i + 1) begin
            a   = $random;
            b   = $random;
            cin = $random;
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
