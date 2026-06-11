`timescale 1ns/1ps

module tb_id_ex
    import pipeline_pkg::*;
(
);
    logic clk = 0;
    logic rst;
    always #5 clk = ~clk;

    // ── IF stage signals ─────────────────────────────────────────
    logic        pc_write    = 1'b1;
    logic [1:0]  pc_sel      = 2'b00;
    logic [31:0] branch_target = 32'h0;
    logic [31:0] jal_target_if = 32'h0;
    logic [31:0] jalr_target   = 32'h0;
    logic [31:0] pc_out, pc_plus4_out, instr_out;

    // ── IF/ID register signals ───────────────────────────────────
    if_id_t if_id_in, if_id_out;
    logic   if_id_write = 1'b1;
    logic   if_id_flush = 1'b0;

    // ── ID stage signals ─────────────────────────────────────────
    logic [4:0]  wb_rd        = 5'b0;
    logic [31:0] wb_data      = 32'h0;
    logic        wb_reg_write = 1'b0;
    logic        reg_write, alu_src, alu_pc, mem_write, mem_read, branch, jump;
    logic [3:0]  alu_op;
    logic [2:0]  mem_width, imm_sel;
    logic [1:0]  wb_sel;
    logic [31:0] rs1_data, rs2_data, imm, jal_target_id;
    logic [4:0]  rs1_addr, rs2_addr, rd_addr;
    id_ex_t      id_ex_d;

    // ── ID/EX register signals ───────────────────────────────────
    id_ex_t      id_ex_q;
    logic        id_ex_flush = 1'b0;

    // ── DUT instantiations ───────────────────────────────────────
    if_stage #(.MEM_FILE("D:/Project_1/vectors/instr_mem.hex")) u_if (
        .clk           (clk),
        .rst           (rst),
        .pc_write      (pc_write),
        .pc_sel        (pc_sel),
        .branch_target (branch_target),
        .jal_target    (jal_target_if),
        .jalr_target   (jalr_target),
        .pc_out        (pc_out),
        .pc_plus4_out  (pc_plus4_out),
        .instr_out     (instr_out)
    );

    assign if_id_in.pc       = pc_out;
    assign if_id_in.pc_plus4 = pc_plus4_out;
    assign if_id_in.instr    = instr_out;

    if_id_reg u_if_id (
        .clk         (clk),
        .rst         (rst),
        .if_id_write (if_id_write),
        .flush       (if_id_flush),
        .d           (if_id_in),
        .q           (if_id_out)
    );

    id_stage u_id (
        .clk          (clk),
        .rst          (rst),
        .if_id        (if_id_out),
        .wb_rd        (wb_rd),
        .wb_data      (wb_data),
        .wb_reg_write (wb_reg_write),
        .reg_write    (reg_write),
        .alu_src      (alu_src),
        .alu_op       (alu_op),
        .alu_pc       (alu_pc),
        .mem_write    (mem_write),
        .mem_read     (mem_read),
        .mem_width    (mem_width),
        .wb_sel       (wb_sel),
        .branch       (branch),
        .jump         (jump),
        .imm_sel      (imm_sel),
        .rs1_data     (rs1_data),
        .rs2_data     (rs2_data),
        .imm          (imm),
        .rs1_addr     (rs1_addr),
        .rs2_addr     (rs2_addr),
        .rd_addr      (rd_addr),
        .jal_target   (jal_target_id),
        .id_ex_d      (id_ex_d)
    );

    id_ex_reg u_id_ex (
        .clk   (clk),
        .rst   (rst),
        .flush (id_ex_flush),
        .d     (id_ex_d),
        .q     (id_ex_q)
    );

    // ── Stimulus ─────────────────────────────────────────────────
    initial begin
        $dumpfile("D:/Project_1/sim/tb_id_ex.vcd");
        $dumpvars(0, tb_id_ex);

        rst = 1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        rst = 0;

        // Run 10 cycles — instructions from instr_mem.hex flow through
        repeat(10) @(posedge clk);

        $display("--- done ---");
        $finish;
    end

    // ── Monitor ──────────────────────────────────────────────────
    integer cycle = 0;
    always @(posedge clk) begin
        #1;
        cycle <= cycle + 1;
        $display("cyc=%0d | IF/ID.instr=%08h | ID: reg_wr=%b alu_src=%b alu_op=%04b mem_r=%b mem_w=%b | ID/EX: reg_wr=%b alu_src=%b alu_op=%04b",
                 cycle,
                 if_id_out.instr,
                 reg_write, alu_src, alu_op, mem_read, mem_write,
                 id_ex_q.reg_write, id_ex_q.alu_src, id_ex_q.alu_op);
    end

endmodule