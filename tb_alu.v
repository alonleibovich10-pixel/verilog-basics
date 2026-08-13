//=============================================================================
// tb_alu.v  -  EXHAUSTIVE self-checking testbench
//
// This testbench sweeps the ENTIRE input space:
//     8 operations  x  256 values of a  x  256 values of b  =  524,288 cases
//
// Exhaustive verification is only possible on small designs, but when it is
// possible it is the strongest statement you can make: not "I tested a lot",
// but "there is no untested input".
//
// Expect it to take a few seconds. That is normal.
//=============================================================================

`timescale 1ns / 1ps

module tb_alu;

    localparam N = 8;

    localparam [2:0] OP_ADD = 3'b000,
                     OP_SUB = 3'b001,
                     OP_AND = 3'b010,
                     OP_OR  = 3'b011,
                     OP_XOR = 3'b100,
                     OP_SLT = 3'b101,
                     OP_SLL = 3'b110,
                     OP_SRL = 3'b111;

    reg  [N-1:0] a, b;
    reg  [2:0]   op;

    wire [N-1:0] result;
    wire         zero, negative, carry, overflow;

    // reference model outputs
    reg  [N-1:0] exp_result;
    reg          exp_zero, exp_negative, exp_carry, exp_overflow;

    reg  [N:0]   wide;          // N+1 bits, to capture the carry out
    reg  signed [N-1:0] sa, sb; // signed views of a and b

    integer errors = 0;
    integer checks = 0;
    integer i, j, k;
    integer op_errors [0:7];

    alu #( .N(N) ) dut (
        .a        ( a        ),
        .b        ( b        ),
        .op       ( op       ),
        .result   ( result   ),
        .zero     ( zero     ),
        .negative ( negative ),
        .carry    ( carry    ),
        .overflow ( overflow )
    );


    // -----------------------------------------------------------------
    // Reference model, written independently of the DUT.
    // It uses Verilog's own arithmetic instead of rebuilding the adder,
    // so a bug in the adder cannot hide by appearing in both.
    // -----------------------------------------------------------------
    task compute_expected;
        begin
            sa = a;
            sb = b;

            exp_carry    = 1'b0;
            exp_overflow = 1'b0;

            case (op)
                OP_ADD: begin
                    wide         = {1'b0, a} + {1'b0, b};
                    exp_result   = wide[N-1:0];
                    exp_carry    = wide[N];
                    exp_overflow = (a[N-1] == b[N-1]) && (exp_result[N-1] != a[N-1]);
                end

                OP_SUB: begin
                    wide         = {1'b0, a} + {1'b0, ~b} + 1'b1;
                    exp_result   = wide[N-1:0];
                    exp_carry    = wide[N];
                    exp_overflow = (a[N-1] != b[N-1]) && (exp_result[N-1] != a[N-1]);
                end

                OP_AND: exp_result = a & b;
                OP_OR:  exp_result = a | b;
                OP_XOR: exp_result = a ^ b;

                OP_SLT: exp_result = (sa < sb) ? { {N-1{1'b0}}, 1'b1 } : {N{1'b0}};

                OP_SLL: exp_result = a << b[2:0];
                OP_SRL: exp_result = a >> b[2:0];

                default: exp_result = {N{1'b0}};
            endcase

            exp_zero     = (exp_result == {N{1'b0}});
            exp_negative = exp_result[N-1];
        end
    endtask


    task check;
        begin
            checks = checks + 1;
            compute_expected;

            if (result !== exp_result || zero !== exp_zero ||
                negative !== exp_negative || carry !== exp_carry ||
                overflow !== exp_overflow) begin

                errors = errors + 1;
                op_errors[op] = op_errors[op] + 1;

                if (errors <= 20) begin
                    $display("  FAIL op=%b a=%h b=%h", op, a, b);
                    $display("        got      result=%h z=%b n=%b c=%b v=%b",
                             result, zero, negative, carry, overflow);
                    $display("        expected result=%h z=%b n=%b c=%b v=%b",
                             exp_result, exp_zero, exp_negative, exp_carry, exp_overflow);
                end
            end
        end
    endtask


    initial begin
        $dumpfile("tb_alu.vcd");
        $dumpvars(0, tb_alu);

        for (i = 0; i < 8; i = i + 1) op_errors[i] = 0;

        $display("");
        $display("==========================================");
        $display(" tb_alu  -  exhaustive sweep");
        $display("==========================================");

        // ---------------------------------------------------------------
        // A few directed cases first, so the log is readable if they fail
        // ---------------------------------------------------------------
        op = OP_ADD; a = 8'd0;   b = 8'd0;   #1 check;   // zero flag
        op = OP_ADD; a = 8'd255; b = 8'd1;   #1 check;   // carry out
        op = OP_ADD; a = 8'd127; b = 8'd1;   #1 check;   // signed overflow
        op = OP_SUB; a = 8'd5;   b = 8'd5;   #1 check;   // zero
        op = OP_SUB; a = 8'd0;   b = 8'd1;   #1 check;   // borrow
        op = OP_SUB; a = 8'h80;  b = 8'd1;   #1 check;   // signed overflow
        op = OP_SLT; a = 8'hFF;  b = 8'h01;  #1 check;   // -1 < 1 signed
        op = OP_SLT; a = 8'h01;  b = 8'hFF;  #1 check;   // 1 < -1 is false
        op = OP_SLL; a = 8'h01;  b = 8'd7;   #1 check;   // shift to the top
        op = OP_SRL; a = 8'h80;  b = 8'd7;   #1 check;   // shift to the bottom

        if (errors == 0)
            $display("  ok    10 directed corner cases");
        else
            $display("  FAIL  directed corner cases already failing - see above");

        // ---------------------------------------------------------------
        // Full sweep
        //
        // Waveform dumping is switched off here on purpose: 524288 events
        // would produce a VCD file of hundreds of megabytes. The directed
        // cases above are already captured, and that is what you want to
        // look at in the viewer anyway.
        // ---------------------------------------------------------------
        $dumpoff;
        $display("  sweeping all 8 x 256 x 256 = 524288 input combinations...");

        for (k = 0; k < 8; k = k + 1) begin
            op = k[2:0];
            for (i = 0; i < 256; i = i + 1) begin
                a = i[7:0];
                for (j = 0; j < 256; j = j + 1) begin
                    b = j[7:0];
                    #1 check;
                end
            end
        end

        $display("------------------------------------------");
        if (errors == 0) begin
            $display(" TESTS: %0d PASSED, 0 FAILED   ***  PASS  ***", checks);
        end else begin
            $display(" TESTS: %0d run, %0d FAILED    ***  FAIL  ***", checks, errors);
            $display("");
            $display(" failures per operation:");
            $display("   ADD %0d | SUB %0d | AND %0d | OR %0d",
                     op_errors[0], op_errors[1], op_errors[2], op_errors[3]);
            $display("   XOR %0d | SLT %0d | SLL %0d | SRL %0d",
                     op_errors[4], op_errors[5], op_errors[6], op_errors[7]);
        end
        $display("==========================================");
        $display("");

        $finish;
    end

endmodule
