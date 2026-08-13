//=============================================================================
// alu.v  -  parameterized Arithmetic Logic Unit with status flags
//
// Day 5 / Week 1
//
// This is the single most important module of the week. It becomes the
// arithmetic core of the single-cycle CPU in Week 3. Do not throw it away.
//
// It reuses ripple_carry_adder from Day 2 as a sub-module: one adder handles
// both ADD and SUB, because subtraction is addition of the two's complement.
//
//-----------------------------------------------------------------------------
// OPERATION TABLE
//
//   op    name   result                       notes
//   ---------------------------------------------------------------------
//   000   ADD    a + b                        sets carry, overflow
//   001   SUB    a - b                        sets carry, overflow
//   010   AND    a & b
//   011   OR     a | b
//   100   XOR    a ^ b
//   101   SLT    (a < b) ? 1 : 0              signed comparison
//   110   SLL    a << b[2:0]                  shift left logical
//   111   SRL    a >> b[2:0]                  shift right logical
//
//-----------------------------------------------------------------------------
// FLAGS
//
//   zero      result == 0                     valid for every operation
//   negative  result[N-1]                     valid for every operation
//   carry     carry out of the adder          forced to 0 unless ADD or SUB
//   overflow  signed overflow                 forced to 0 unless ADD or SUB
//
//=============================================================================

`timescale 1ns / 1ps
`default_nettype none

module alu #(
    parameter N = 8
)(
    input  wire [N-1:0] a,
    input  wire [N-1:0] b,
    input  wire [2:0]   op,
    output reg  [N-1:0] result,
    output wire         zero,
    output wire         negative,
    output wire         carry,
    output wire         overflow
);

    // ---- operation codes ----
    localparam [2:0] OP_ADD = 3'b000,
                     OP_SUB = 3'b001,
                     OP_AND = 3'b010,
                     OP_OR  = 3'b011,
                     OP_XOR = 3'b100,
                     OP_SLT = 3'b101,
                     OP_SLL = 3'b110,
                     OP_SRL = 3'b111;

    // ---- internal nets ----
    wire            sub_mode;   // 1 when the adder must subtract
    wire [N-1:0]    b_eff;      // b, inverted when subtracting
    wire [N-1:0]    sum;
    wire            cout;
    wire            ovf;
    wire            slt_bit;
    wire            is_arith;


    // =====================================================================

      assign sub_mode = (op == OP_SUB) | (op == OP_SLT);
    //

    // =====================================================================
    // TODO 2  -  two's complement trick
    //
      assign b_eff = b ^ {N{sub_mode}};  // invert b when subtracting;t
    //
    //   a - b  ==  a + (~b) + 1
    //
    // So: invert every bit of b when subtracting, and feed 1 into the
    // adder's carry-in. When adding, pass b through unchanged.
    //
    // Hint: {N{sub_mode}} replicates sub_mode into an N-bit mask.
    //       XOR with all-ones inverts; XOR with all-zeros passes through.
    // =====================================================================


    // =====================================================================

      ripple_carry_adder #( .N(N) ) u_add (
          .a    ( a ),
          .b    ( b_eff ),
          .cin  ( sub_mode ), // 1 when subtracting, 0 when adding
          .sum  ( sum ),
          .cout ( cout )
      );



    // =====================================================================
  
    //
    assign ovf =  a[N-1] == b_eff[N-1] && sum[N-1] != a[N-1];
    //
    // Signed overflow happens when two operands with the SAME sign produce
    // a result with a DIFFERENT sign. Adding two positives cannot give a
    // negative; adding two negatives cannot give a positive.
 
    // =====================================================================

      assign slt_bit = sum[N-1] ^ ovf ; ;
    //
    // After computing a - b:
    //   - with no overflow, a < b  <=>  the result is negative
    //   - with overflow, the sign bit lies, so the answer flips
  
    // This is exactly how MIPS implements slt. Worth remembering - it is a
    // classic interview question.
    // =====================================================================


    // =====================================================================
    //   -  the result multiplexer
    //
      always @(*) begin
          case (op)
              OP_ADD, OP_SUB: result = sum;
              OP_AND:         result = a & b;
              OP_OR:          result = a | b;
              OP_XOR:         result = a ^ b;
              OP_SLT:         result = { {N-1{1'b0}}, slt_bit };
              OP_SLL:         result = a << b[2:0];
              OP_SRL:         result = a >> b[2:0];
              default:        result = {N{1'b0}};
          endcase
      end

    // The shift amount is b[2:0], the low 3 bits. Same idea as the 5-bit
    // shamt field in MIPS for 32-bit words.
    // =====================================================================


    //  the flags
    //
      assign is_arith = (op == OP_ADD) || (op == OP_SUB);
    //
      assign zero     = ~|result ;      // is result all zeros?
      assign negative = result[N-1] ;      // the MSB of result
      assign carry    = is_arith ? cout : 1'b0;
      assign overflow = is_arith ? ovf  : 1'b0;
    //
    // For zero, a reduction operator is the cleanest form:
    //     |result   is 1 if ANY bit is set
    // so NOT of that is "all bits are zero".
    //
    // carry and overflow are meaningless for AND / OR / XOR / shifts, so we
    // force them low instead of leaking whatever the adder happened to do.
    // Defined behaviour beats accidental behaviour.
    // =====================================================================

endmodule

`default_nettype wire
