//=============================================================================
// tb_sync_fifo.v  -  self-checking testbench with an independent queue model
//
// The reference model here is a real queue kept inside the testbench: its own
// array, its own head and tail, its own counter. It never looks at the DUT's
// flags or pointers, so a bug in the DUT cannot leak into the expected value.
//
// Checked every cycle:
//   - full, empty and count match the model
//   - rd_data is the oldest element still in the queue
//   - a write while full changes nothing
//   - a read while empty changes nothing
//   - count never leaves the range 0..DEPTH
//=============================================================================

`timescale 1ns / 1ps

module tb_sync_fifo;

    localparam WIDTH = 8;
    localparam DEPTH = 8;
    localparam PTR_W = 3;

    reg              clk = 1'b0;
    reg              rst = 1'b0;
    reg              wr_en = 1'b0;
    reg  [WIDTH-1:0] wr_data = 0;
    reg              rd_en = 1'b0;

    wire [WIDTH-1:0] rd_data;
    wire             full, empty;
    wire [PTR_W:0]   count;

    // ---- independent reference queue ----
    reg  [WIDTH-1:0] model [0:DEPTH-1];
    integer m_head  = 0;
    integer m_tail  = 0;
    integer m_count = 0;

    reg     check_on = 1'b0;
    integer errors   = 0;
    integer checks   = 0;
    integer i;
    reg [WIDTH-1:0] got;

    always #5 clk = ~clk;

    sync_fifo #(
        .WIDTH ( WIDTH ),
        .DEPTH ( DEPTH )
    ) dut (
        .clk     ( clk     ),
        .rst     ( rst     ),
        .wr_en   ( wr_en   ),
        .wr_data ( wr_data ),
        .rd_en   ( rd_en   ),
        .rd_data ( rd_data ),
        .full    ( full    ),
        .empty   ( empty   ),
        .count   ( count   )
    );


    // -----------------------------------------------------------------
    // Reference queue, updated on the same clock edge as the DUT.
    // The guards use the MODEL's own count, never the DUT's flags.
    // -----------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            m_head  <= 0;
            m_tail  <= 0;
            m_count <= 0;
        end else begin
            if (wr_en && (m_count < DEPTH) && rd_en && (m_count > 0)) begin
                // simultaneous read and write: occupancy stays the same
                model[m_tail] <= wr_data;
                m_tail  <= (m_tail + 1) % DEPTH;
                m_head  <= (m_head + 1) % DEPTH;
                m_count <= m_count;
            end else if (wr_en && (m_count < DEPTH)) begin
                model[m_tail] <= wr_data;
                m_tail  <= (m_tail + 1) % DEPTH;
                m_count <= m_count + 1;
            end else if (rd_en && (m_count > 0)) begin
                m_head  <= (m_head + 1) % DEPTH;
                m_count <= m_count - 1;
            end
        end
    end


    // -----------------------------------------------------------------
    // Checker
    // -----------------------------------------------------------------
    always @(negedge clk) begin
        #2;
        if (check_on) begin
            checks = checks + 1;

            if (count !== m_count[PTR_W:0]) begin
                $display("  FAIL @%0t  count=%0d, model says %0d", $time, count, m_count);
                errors = errors + 1;
            end

            if (empty !== (m_count == 0)) begin
                $display("  FAIL @%0t  empty=%b but model count=%0d", $time, empty, m_count);
                errors = errors + 1;
            end

            if (full !== (m_count == DEPTH)) begin
                $display("  FAIL @%0t  full=%b but model count=%0d", $time, full, m_count);
                errors = errors + 1;
            end

            if (m_count > 0 && rd_data !== model[m_head]) begin
                $display("  FAIL @%0t  rd_data=%h, oldest element should be %h",
                         $time, rd_data, model[m_head]);
                errors = errors + 1;
            end

            if (m_count < 0 || m_count > DEPTH) begin
                $display("  FAIL @%0t  INVARIANT model count out of range: %0d", $time, m_count);
                errors = errors + 1;
            end
        end
    end


    task do_write;
        input [WIDTH-1:0] d;
        begin
            @(negedge clk);
            wr_en = 1'b1; wr_data = d; rd_en = 1'b0;
            @(negedge clk);
            wr_en = 1'b0;
        end
    endtask

    task do_read;
        begin
            @(negedge clk);
            rd_en = 1'b1; wr_en = 1'b0;
            @(negedge clk);
            rd_en = 1'b0;
        end
    endtask


    initial begin
        $dumpfile("tb_sync_fifo.vcd");
        $dumpvars(0, tb_sync_fifo);

        $display("");
        $display("==========================================");
        $display(" tb_sync_fifo   WIDTH=%0d  DEPTH=%0d", WIDTH, DEPTH);
        $display("==========================================");

        rst = 1'b1; wr_en = 1'b0; rd_en = 1'b0; wr_data = 0;
        @(negedge clk);
        @(negedge clk);
        rst = 1'b0;
        check_on = 1'b1;

        @(negedge clk); #1;
        checks = checks + 1;
        if (empty === 1'b1 && full === 1'b0 && count === 0)
            $display("  ok    after reset: empty=1 full=0 count=0");
        else begin
            $display("  FAIL  after reset empty=%b full=%b count=%0d", empty, full, count);
            errors = errors + 1;
        end

        // -------------------------------------------------------------
        // Fill it completely
        // -------------------------------------------------------------
        $display("  writing 8 values 10..17 to fill the FIFO");
        for (i = 0; i < DEPTH; i = i + 1) begin
            @(negedge clk);
            wr_en = 1'b1;
            wr_data = 8'h10 + i[7:0];
        end
        @(negedge clk);
        wr_en = 1'b0;
        #1;
        checks = checks + 1;
        if (full === 1'b1 && empty === 1'b0 && count === DEPTH)
            $display("  ok    FIFO reports full with count=%0d", count);
        else begin
            $display("  FAIL  after 8 writes full=%b empty=%b count=%0d", full, empty, count);
            errors = errors + 1;
        end

        // -------------------------------------------------------------
        // Try to overflow - must be ignored
        // -------------------------------------------------------------
        $display("  attempting 3 writes while full - they must be ignored");
        for (i = 0; i < 3; i = i + 1) begin
            @(negedge clk);
            wr_en = 1'b1;
            wr_data = 8'hEE;
        end
        @(negedge clk);
        wr_en = 1'b0;
        #1;
        checks = checks + 1;
        if (count === DEPTH)
            $display("  ok    overflow writes had no effect");
        else begin
            $display("  FAIL  count changed to %0d after writing while full", count);
            errors = errors + 1;
        end

        // -------------------------------------------------------------
        // Drain it, checking the order
        // -------------------------------------------------------------
        $display("  reading everything back, checking FIFO order");
        for (i = 0; i < DEPTH; i = i + 1) begin
            @(negedge clk);
            #1 got = rd_data;
            checks = checks + 1;
            if (got !== (8'h10 + i[7:0])) begin
                $display("  FAIL  read %0d returned %h, expected %h", i, got, 8'h10 + i[7:0]);
                errors = errors + 1;
            end
            rd_en = 1'b1;
        end
        @(negedge clk);
        rd_en = 1'b0;
        #1;
        checks = checks + 1;
        if (empty === 1'b1 && count === 0)
            $display("  ok    FIFO drained in order, empty again");
        else begin
            $display("  FAIL  after draining empty=%b count=%0d", empty, count);
            errors = errors + 1;
        end

        // -------------------------------------------------------------
        // Try to underflow - must be ignored
        // -------------------------------------------------------------
        $display("  attempting 3 reads while empty - they must be ignored");
        for (i = 0; i < 3; i = i + 1) begin
            @(negedge clk);
            rd_en = 1'b1;
        end
        @(negedge clk);
        rd_en = 1'b0;
        #1;
        checks = checks + 1;
        if (empty === 1'b1 && count === 0)
            $display("  ok    underflow reads had no effect");
        else begin
            $display("  FAIL  after reading while empty count=%0d", count);
            errors = errors + 1;
        end

        // -------------------------------------------------------------
        // Simultaneous read and write - occupancy must stay constant
        // -------------------------------------------------------------
        $display("  filling halfway, then reading and writing in the same cycle");
        for (i = 0; i < 4; i = i + 1) begin
            @(negedge clk);
            wr_en = 1'b1; wr_data = 8'hA0 + i[7:0];
        end
        @(negedge clk); wr_en = 1'b0;

        for (i = 0; i < 6; i = i + 1) begin
            @(negedge clk);
            wr_en = 1'b1; rd_en = 1'b1; wr_data = 8'hB0 + i[7:0];
        end
        @(negedge clk); wr_en = 1'b0; rd_en = 1'b0;
        #1;
        checks = checks + 1;
        if (count === 4)
            $display("  ok    simultaneous read+write kept occupancy at 4");
        else begin
            $display("  FAIL  occupancy is %0d after simultaneous access, expected 4", count);
            errors = errors + 1;
        end

        // -------------------------------------------------------------
        // Random traffic
        // -------------------------------------------------------------
        $display("  running 800 cycles of random read/write traffic...");
        for (i = 0; i < 800; i = i + 1) begin
            @(negedge clk);
            wr_en   = $random;
            rd_en   = $random;
            wr_data = $random;
        end
        @(negedge clk);
        wr_en = 1'b0; rd_en = 1'b0;

        // -------------------------------------------------------------
        // Reset in the middle
        // -------------------------------------------------------------
        @(negedge clk); rst = 1'b1;
        @(negedge clk); rst = 1'b0;
        @(negedge clk); #1;
        checks = checks + 1;
        if (empty === 1'b1 && count === 0)
            $display("  ok    reset emptied the FIFO");
        else begin
            $display("  FAIL  after reset empty=%b count=%0d", empty, count);
            errors = errors + 1;
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
