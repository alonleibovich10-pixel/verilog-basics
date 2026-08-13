//=============================================================================
// sync_fifo.v  -  synchronous FIFO (circular buffer) with full/empty flags
//
// Day 5 / Week 1
//
// A FIFO is a queue in hardware. One side writes, the other side reads, and
// data comes out in the order it went in. It is the standard way to connect
// two blocks that do not run at the same rate.
//
//-----------------------------------------------------------------------------
// HOW IT WORKS
//
// A block of memory plus two pointers moving around it in a circle:
//
//        wr_ptr                    rd_ptr
//          |                         |
//          v                         v
//   +----+----+----+----+----+----+----+----+
//   |    | D3 | D2 | D1 |    |    |    |    |
//   +----+----+----+----+----+----+----+----+
//     0    1    2    3    4    5    6    7
//
//   write -> store at wr_ptr, then wr_ptr++
//   read  -> return mem[rd_ptr], then rd_ptr++
//   both pointers wrap around at DEPTH
//
//-----------------------------------------------------------------------------
// THE CORE PROBLEM
//
// Empty means wr_ptr == rd_ptr.
// Full also means wr_ptr == rd_ptr, because the write pointer lapped the
// read pointer exactly once.
//
// Same condition, opposite meaning. This is THE classic FIFO interview
// question.
//
// THE FIX: make both pointers one bit wider than they need to be.
//
//   equal low bits + equal MSB       -> EMPTY
//   equal low bits + different MSB   -> FULL   (wr lapped rd)
//
// The extra bit counts laps. It never addresses memory.
//
//=============================================================================

`timescale 1ns / 1ps
`default_nettype none

module sync_fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 8,                 // must be a power of two
    parameter PTR_W = $clog2(DEPTH)      // 3 when DEPTH is 8 - do not override
)(
    input  wire             clk,
    input  wire             rst,     // synchronous, active high

    input  wire             wr_en,   // request a write
    input  wire [WIDTH-1:0] wr_data,

    input  wire             rd_en,   // request a read
    output wire [WIDTH-1:0] rd_data,

    output wire             full,
    output wire             empty,
    output wire [PTR_W:0]   count    // how many entries are stored
);

    // storage
    reg [WIDTH-1:0] mem [0:DEPTH-1];

    // pointers are PTR_W+1 bits wide: PTR_W address bits plus one lap bit
    reg [PTR_W:0]   wr_ptr;
    reg [PTR_W:0]   rd_ptr;


    // =====================================================================

      assign empty = ( wr_ptr[PTR_W:0] == rd_ptr[PTR_W:0] );
    //
   
    // =====================================================================
    //  full
    //
      assign full = ( wr_ptr[PTR_W]     != rd_ptr[PTR_W]     ) &&
                    ( wr_ptr[PTR_W-1:0] == rd_ptr[PTR_W-1:0] );
    
    // Same address, different lap. The writer is exactly one full loop
    // ahead of the reader.

    // =====================================================================
    //  -  count
    //
      assign count = wr_ptr - rd_ptr;
    //

    // =====================================================================
    //  read data
    //
      assign rd_data = mem[rd_ptr[PTR_W-1:0]];
    //
    // Address memory with the LOW bits of rd_ptr only. The lap bit is not
    // an address.
    //

    // =====================================================================
    //  the pointers and the memory write
    //
      always @(posedge clk) begin
          if (rst) begin
              wr_ptr <= 0;
              rd_ptr <= 0;
          end else begin
              if (wr_en && !full) begin
                  mem[wr_ptr[PTR_W-1:0]] <= wr_data;
                  wr_ptr <= wr_ptr + 1'b1;
              end
              if (rd_en && !empty) begin
                  rd_ptr <= rd_ptr + 1'b1;
              end
          end
      end
    //
    // Two independent if statements, NOT if/else. A read and a write in the
    // same cycle is legal and common - that is how a FIFO sustains
    // throughput while staying at a constant occupancy.
    //
    // The guards "&& !full" and "&& !empty" are the safety net: a write to
    // a full FIFO silently does nothing instead of destroying data, and a
    // read from an empty FIFO does not advance the pointer past valid data.
    // =====================================================================

endmodule

`default_nettype wire
