`timescale 1ns/1ps
// tb_if.sv
// Tests if_stage + if_id_reg together.
// Checks: PC increments by 4, IF/ID register lags instr_out by 1 cycle.

`timescale 1ns/1ps
import pipeline_pkg::*;

module tb_if;

    logic        clk = 0;
    logic        rst;
    logic        pc_write, flush, if_id_write;
    logic [1:0]  pc_sel;
    logic [31:0] branch_target, jal_target, jalr_target;
    logic [31:0] pc_out, pc_plus4_out, instr_out;
    if_id_t      if_id_in, if_id_out;

    always #5 clk = ~clk;   // 100 MHz

    // ── DUT: IF stage ────────────────────────────────────────────
    if_stage #(.MEM_FILE("D:/Project_1/vectors/instr_mem.hex")) u_if (
        .clk           (clk),
        .rst           (rst),
        .pc_write      (pc_write),
        .pc_sel        (pc_sel),
        .branch_target (branch_target),
        .jal_target    (jal_target),
        .jalr_target   (jalr_target),
        .pc_out        (pc_out),
        .pc_plus4_out  (pc_plus4_out),
        .instr_out     (instr_out)
    );

    // ── Wire IF outputs into IF/ID struct ────────────────────────
    assign if_id_in.pc       = pc_out;
    assign if_id_in.pc_plus4 = pc_plus4_out;
    assign if_id_in.instr    = instr_out;

    // ── DUT: IF/ID register ──────────────────────────────────────
    if_id_reg u_if_id (
        .clk         (clk),
        .rst         (rst),
        .if_id_write (if_id_write),
        .flush       (flush),
        .d           (if_id_in),
        .q           (if_id_out)
    );

    // ── Stimulus ─────────────────────────────────────────────────
    initial begin
        $dumpfile("D:/Project_1/sim/tb_if.vcd");
        $dumpvars(0, tb_if);
        rst = 1;
        pc_sel        = 2'b00;
        pc_write      = 1'b1;
        if_id_write   = 1'b1;
        flush         = 1'b0;
        branch_target = 32'h0;
        jal_target    = 32'h0;
        jalr_target   = 32'h0;

        @(posedge clk); #1;
        @(posedge clk); #1;
        rst = 0;

        repeat(12) @(posedge clk);

        $display("--- done ---");
        $finish;
    end

    // ── Monitor ──────────────────────────────────────────────────
    integer cycle = 0;
    always @(posedge clk) begin
        #1;
        cycle <= cycle + 1;
        $display("cyc=%0d | PC=%08h  instr_raw=%08h | IF/ID.pc=%08h  IF/ID.instr=%08h",
                 cycle, pc_out, instr_out, if_id_out.pc, if_id_out.instr);
    end

    // ── PC increment assertion ────────────────────────────────────
    logic [31:0] prev_pc;
    always_ff @(posedge clk) prev_pc <= pc_out;

    always @(posedge clk) begin
        #1;
        if (!rst && pc_write && pc_sel == 2'b00) begin
            if (cycle > 1 && pc_out !== prev_pc + 32'd4)
                $display("FAIL cyc=%0d: PC jumped from %08h to %08h",
                         cycle, prev_pc, pc_out);
        end
    end

endmodule