//=============================================================================
// tb_traffic_light.v  -  protocol + safety checker
//
// הטסטבנץ' הזה שונה מכל הקודמים. הוא לא משווה מול מודל ייחוס -
// הוא בודק שלושה סוגי טענות:
//
//   1. INVARIANTS  - דברים שחייבים להתקיים בכל מחזור, תמיד.
//                    "אסור ששני הכיוונים יהיו ירוקים." זו דרישת בטיחות.
//
//   2. PROTOCOL    - סדר הפאזות: ירוק -> צהוב -> הכיוון השני.
//
//   3. TIMING      - כמה מחזורים כל פאזה נמשכת.
//
// זו בדיוק החשיבה של assertions, שהם הנושא של שבוע 2. כאן אנחנו
// כותבים אותן ידנית ב-Verilog רגיל, וזה יעזור לך להבין למה SVA קיים.
//=============================================================================

`timescale 1ns / 1ps

module tb_traffic_light;

    localparam T_GREEN  = 5;
    localparam T_YELLOW = 2;

    localparam [2:0] RED    = 3'b100,
                     YELLOW = 3'b010,
                     GREEN  = 3'b001;

    reg        clk = 1'b0;
    reg        rst = 1'b0;
    wire [2:0] ns_light, ew_light;

    integer errors = 0;
    integer checks = 0;
    integer i;

    // --- מעקב פאזות ---
    reg  [2:0] prev_ns = 3'b0, prev_ew = 3'b0;
    reg  [2:0] snap_ns, snap_ew;
    integer    phase_len   = 0;
    integer    phase_idx   = 0;
    integer    phases_seen = 0;
    reg        tracking    = 1'b0;

    always #5 clk = ~clk;

    traffic_light #(
        .T_GREEN  ( T_GREEN  ),
        .T_YELLOW ( T_YELLOW )
    ) dut (
        .clk      ( clk      ),
        .rst      ( rst      ),
        .ns_light ( ns_light ),
        .ew_light ( ew_light )
    );

    // ---- הדפוס הצפוי בפאזה p ----
    function [5:0] exp_pat;
        input integer p;
        begin
            case (p % 4)
                0: exp_pat = { GREEN,  RED    };   // NS ירוק
                1: exp_pat = { YELLOW, RED    };   // NS צהוב
                2: exp_pat = { RED,    GREEN  };   // EW ירוק
                3: exp_pat = { RED,    YELLOW };   // EW צהוב
            endcase
        end
    endfunction

    function integer exp_len;
        input integer p;
        begin
            exp_len = ((p % 4) == 0 || (p % 4) == 2) ? T_GREEN : T_YELLOW;
        end
    endfunction

    function integer popcount3;
        input [2:0] v;
        begin
            popcount3 = v[0] + v[1] + v[2];
        end
    endfunction


    // =================================================================
    //  הבודק - רץ בכל negedge
    // =================================================================
    always @(negedge clk) begin
        #2;
        if (!rst) begin
            checks = checks + 1;

            // ---- INVARIANT 1: בכל כיוון בדיוק נורה אחת דלוקה ----
            if (popcount3(ns_light) !== 1) begin
                $display("  FAIL @%0t  INVARIANT  ns_light=%b is not one-hot", $time, ns_light);
                errors = errors + 1;
            end
            if (popcount3(ew_light) !== 1) begin
                $display("  FAIL @%0t  INVARIANT  ew_light=%b is not one-hot", $time, ew_light);
                errors = errors + 1;
            end

            // ---- INVARIANT 2: אסור ששניהם ירוקים ----
            if (ns_light[0] && ew_light[0]) begin
                $display("  FAIL @%0t  SAFETY  both directions GREEN", $time);
                errors = errors + 1;
            end

            // ---- INVARIANT 3: אם אחד לא אדום, השני חייב אדום ----
            if ((ns_light !== RED) && (ew_light !== RED)) begin
                $display("  FAIL @%0t  SAFETY  ns=%b ew=%b - neither is RED",
                         $time, ns_light, ew_light);
                errors = errors + 1;
            end

            // ---- PROTOCOL + TIMING ----
            if (tracking) begin
                if (ns_light === prev_ns && ew_light === prev_ew) begin
                    phase_len = phase_len + 1;
                end else begin
                    if (phase_len !== exp_len(phase_idx)) begin
                        $display("  FAIL  phase %0d lasted %0d cycles, expected %0d",
                                 phase_idx % 4, phase_len, exp_len(phase_idx));
                        errors = errors + 1;
                    end
                    phases_seen = phases_seen + 1;
                    phase_idx   = phase_idx + 1;
                    phase_len   = 1;

                    if ({ns_light, ew_light} !== exp_pat(phase_idx)) begin
                        $display("  FAIL  phase %0d has ns=%b ew=%b, expected %b",
                                 phase_idx % 4, ns_light, ew_light, exp_pat(phase_idx));
                        errors = errors + 1;
                    end
                end
                prev_ns = ns_light;
                prev_ew = ew_light;
            end
        end
    end


    initial begin
        $dumpfile("tb_traffic_light.vcd");
        $dumpvars(0, tb_traffic_light);

        $display("");
        $display("==========================================");
        $display(" tb_traffic_light   T_GREEN=%0d  T_YELLOW=%0d", T_GREEN, T_YELLOW);
        $display("==========================================");

        rst = 1'b1;
        @(negedge clk);
        @(negedge clk);
        rst = 1'b0;

        // ---- אחרי reset: NS ירוק, EW אדום ----
        @(negedge clk); #1;
        checks = checks + 1;
        if (ns_light === GREEN && ew_light === RED)
            $display("  ok    after reset: NS=GREEN, EW=RED");
        else begin
            $display("  FAIL  after reset ns=%b ew=%b, expected 001 / 100",
                     ns_light, ew_light);
            errors = errors + 1;
        end

        // ---- לתת למחזור אחד מלא לעבור, כדי לדלג על הפאזה החלקית ----
        for (i = 0; i < 2 * (T_GREEN + T_YELLOW); i = i + 1) @(negedge clk);

        // ---- להסתנכרן על גבול הפאזה הבא ----
        snap_ns = ns_light;
        snap_ew = ew_light;
        while (ns_light === snap_ns && ew_light === snap_ew) @(negedge clk);
        #3;

        // ---- לזהות באיזו פאזה אנחנו, ולהתחיל למדוד ----
        if      (ns_light === GREEN)  phase_idx = 0;
        else if (ns_light === YELLOW) phase_idx = 1;
        else if (ew_light === GREEN)  phase_idx = 2;
        else                          phase_idx = 3;

        prev_ns     = ns_light;
        prev_ew     = ew_light;
        phase_len   = 1;
        phases_seen = 0;
        tracking    = 1'b1;

        $display("  measuring 3 full cycles from phase %0d ...", phase_idx);

        for (i = 0; i < 3 * 2 * (T_GREEN + T_YELLOW) + 2; i = i + 1)
            @(negedge clk);

        tracking = 1'b0;
        #3;

        checks = checks + 1;
        if (phases_seen >= 11)
            $display("  ok    observed %0d complete phases with correct order and timing",
                     phases_seen);
        else begin
            $display("  FAIL  observed only %0d phases, expected at least 11", phases_seen);
            errors = errors + 1;
        end

        // ---- reset באמצע ריצה ----
        $display("  asserting reset mid-cycle");
        @(negedge clk); rst = 1'b1;
        @(negedge clk); rst = 1'b0;
        @(negedge clk); #1;

        checks = checks + 1;
        if (ns_light === GREEN && ew_light === RED)
            $display("  ok    reset returned the intersection to NS=GREEN");
        else begin
            $display("  FAIL  after mid-run reset ns=%b ew=%b", ns_light, ew_light);
            errors = errors + 1;
        end

        for (i = 0; i < 30; i = i + 1) @(negedge clk);
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
