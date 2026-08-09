module mux2_tb;

    reg a_tb;
    reg b_tb;
    reg sel_tb;
    wire out_tb;

    // חיבור המודול
    mux2 uut (
        .a(a_tb),
        .b(b_tb),
        .sel(sel_tb),
        .out(out_tb)
    );

    initial begin
        // יצירת קובץ גלים
        $dumpfile("mux2.vcd");
        $dumpvars(0, mux2_tb);

        // מקרי בדיקה
        // נבדוק ש-a עובר כש-sel=0
        sel_tb = 0; a_tb = 0; b_tb = 1; #10;
        sel_tb = 0; a_tb = 1; b_tb = 0; #10;
        
        // נבדוק ש-b עובר כש-sel=1
        sel_tb = 1; a_tb = 0; b_tb = 1; #10;
        sel_tb = 1; a_tb = 1; b_tb = 0; #10;

        $finish;
    end

endmodule