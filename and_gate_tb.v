module and_gate_tb;


    reg a_tb;
    reg b_tb;
    wire out_tb;


    and_gate uut (
        .a(a_tb),
        .b(b_tb),
        .out(out_tb)
    );


    initial begin

        $dumpfile("and_gate.vcd");
        $dumpvars(0, and_gate_tb);


        a_tb = 0; b_tb = 0; #10;
        a_tb = 0; b_tb = 1; #10;
        a_tb = 1; b_tb = 0; #10;
        a_tb = 1; b_tb = 1; #10;

        $finish; // 
    end

endmodule