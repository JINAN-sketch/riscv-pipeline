`timescale 1ns/1ps

module riscv_top
    import pipeline_pkg::*;
#(
    parameter MEM_FILE = "D:/Project_1/vectors/instr_mem.hex"
)(
    input logic clk,
    input logic rst
);

    // ── IF stage outputs ─────────────────────────────────────────
    logic [31:0] if_pc_out, if_pc_plus4_out, if_instr_out;

    // ── IF/ID register ───────────────────────────────────────────
    if_id_t if_id_d, if_id_q;
    logic   if_id_write, if_id_flush;

    // ── ID stage outputs ─────────────────────────────────────────
    logic        id_reg_write, id_alu_src, id_alu_pc;
    logic        id_mem_write, id_mem_read, id_branch, id_jump;
    logic [3:0]  id_alu_op;
    logic [2:0]  id_mem_width, id_imm_sel;
    logic [1:0]  id_wb_sel;
    logic [31:0] id_rs1_data, id_rs2_data, id_imm, id_jal_target;
    logic [4:0]  id_rs1_addr, id_rs2_addr, id_rd_addr;
    id_ex_t      id_ex_d;

    // ── ID/EX register ───────────────────────────────────────────
    id_ex_t id_ex_q;
    logic   id_ex_flush;

    // ── EX stage outputs ─────────────────────────────────────────
    logic [31:0] ex_alu_result, ex_rs2_data_out;
    logic [31:0] ex_branch_target, ex_jalr_target;
    logic        ex_branch_taken;
    logic        ex_reg_write, ex_mem_write, ex_mem_read;
    logic [2:0]  ex_mem_width;
    logic [1:0]  ex_wb_sel;
    logic [4:0]  ex_rd_addr;
    logic [31:0] ex_pc_plus4;

    // ── EX/MEM register ──────────────────────────────────────────
    ex_mem_t ex_mem_d, ex_mem_q;
    logic    ex_mem_flush;

    // ── MEM stage outputs ────────────────────────────────────────
    logic [31:0] mem_data_out, mem_alu_result_out, mem_pc_plus4_out;
    logic        mem_reg_write_out;
    logic [1:0]  mem_wb_sel_out;
    logic [4:0]  mem_rd_addr_out;

    // ── MEM/WB register ──────────────────────────────────────────
    mem_wb_t mem_wb_d, mem_wb_q;

    // ── WB stage outputs ─────────────────────────────────────────
    logic [31:0] wb_data;
    logic [4:0]  wb_rd;
    logic        wb_reg_write;

    // ── Forwarding (tied off — Week 3) ───────────────────────────
    logic [1:0]  fwd_a = 2'b00;
    logic [1:0]  fwd_b = 2'b00;
    logic [31:0] fwd_mem_result = 32'h0;
    logic [31:0] fwd_wb_result  = 32'h0;

    // ── Hazard / PC control ──────────────────────────────────────
    // Basic branch/jump redirect — no stall yet
    logic [1:0] pc_sel;
    assign pc_sel      = (ex_branch_taken)          ? 2'b01 :  // taken branch
                         (id_ex_q.jump && !id_ex_q.alu_src) ? 2'b10 :  // JAL
                         (id_ex_q.jump &&  id_ex_q.alu_src) ? 2'b11 :  // JALR
                         2'b00;                                 // sequential

    assign if_id_flush = (ex_branch_taken) ? 1'b1 : 1'b0;
    assign if_id_write = 1'b1;
    assign id_ex_flush = 1'b0;
    assign ex_mem_flush = 1'b0;

    // ── Pack EX outputs into EX/MEM struct ───────────────────────
    assign ex_mem_d.reg_write  = ex_reg_write;
    assign ex_mem_d.mem_write  = ex_mem_write;
    assign ex_mem_d.mem_read   = ex_mem_read;
    assign ex_mem_d.mem_width  = ex_mem_width;
    assign ex_mem_d.wb_sel     = ex_wb_sel;
    assign ex_mem_d.alu_result = ex_alu_result;
    assign ex_mem_d.rs2_data   = ex_rs2_data_out;
    assign ex_mem_d.pc_plus4   = ex_pc_plus4;
    assign ex_mem_d.rd_addr    = ex_rd_addr;

    // ── Pack MEM outputs into MEM/WB struct ──────────────────────
    assign mem_wb_d.reg_write  = mem_reg_write_out;
    assign mem_wb_d.wb_sel     = mem_wb_sel_out;
    assign mem_wb_d.alu_result = mem_alu_result_out;
    assign mem_wb_d.mem_data   = mem_data_out;
    assign mem_wb_d.pc_plus4   = mem_pc_plus4_out;
    assign mem_wb_d.rd_addr    = mem_rd_addr_out;

    // ── Pack IF outputs into IF/ID struct ────────────────────────
    assign if_id_d.pc       = if_pc_out;
    assign if_id_d.pc_plus4 = if_pc_plus4_out;
    assign if_id_d.instr    = if_instr_out;

    // ════════════════════════════════════════════════════════════
    // STAGE INSTANTIATIONS
    // ════════════════════════════════════════════════════════════

    if_stage #(.MEM_FILE(MEM_FILE)) u_if (
        .clk           (clk),
        .rst           (rst),
        .pc_write      (1'b1),
        .pc_sel        (pc_sel),
        .branch_target (ex_branch_target),
        .jal_target    (id_jal_target),
        .jalr_target   (ex_jalr_target),
        .pc_out        (if_pc_out),
        .pc_plus4_out  (if_pc_plus4_out),
        .instr_out     (if_instr_out)
    );

    if_id_reg u_if_id (
        .clk         (clk),
        .rst         (rst),
        .if_id_write (if_id_write),
        .flush       (if_id_flush),
        .d           (if_id_d),
        .q           (if_id_q)
    );

    id_stage u_id (
        .clk          (clk),
        .rst          (rst),
        .if_id        (if_id_q),
        .wb_rd        (wb_rd),
        .wb_data      (wb_data),
        .wb_reg_write (wb_reg_write),
        .reg_write    (id_reg_write),
        .alu_src      (id_alu_src),
        .alu_op       (id_alu_op),
        .alu_pc       (id_alu_pc),
        .mem_write    (id_mem_write),
        .mem_read     (id_mem_read),
        .mem_width    (id_mem_width),
        .wb_sel       (id_wb_sel),
        .branch       (id_branch),
        .jump         (id_jump),
        .imm_sel      (id_imm_sel),
        .rs1_data     (id_rs1_data),
        .rs2_data     (id_rs2_data),
        .imm          (id_imm),
        .rs1_addr     (id_rs1_addr),
        .rs2_addr     (id_rs2_addr),
        .rd_addr      (id_rd_addr),
        .jal_target   (id_jal_target),
        .id_ex_d      (id_ex_d)
    );

    id_ex_reg u_id_ex (
        .clk   (clk),
        .rst   (rst),
        .flush (id_ex_flush),
        .d     (id_ex_d),
        .q     (id_ex_q)
    );

    ex_stage u_ex (
        .id_ex          (id_ex_q),
        .fwd_a          (fwd_a),
        .fwd_b          (fwd_b),
        .fwd_mem_result (fwd_mem_result),
        .fwd_wb_result  (fwd_wb_result),
        .alu_result     (ex_alu_result),
        .rs2_data_out   (ex_rs2_data_out),
        .branch_taken   (ex_branch_taken),
        .branch_target  (ex_branch_target),
        .jalr_target    (ex_jalr_target),
        .reg_write      (ex_reg_write),
        .mem_write      (ex_mem_write),
        .mem_read       (ex_mem_read),
        .mem_width      (ex_mem_width),
        .wb_sel         (ex_wb_sel),
        .rd_addr        (ex_rd_addr),
        .pc_plus4       (ex_pc_plus4)
    );

    ex_mem_reg u_ex_mem (
        .clk   (clk),
        .rst   (rst),
        .flush (ex_mem_flush),
        .d     (ex_mem_d),
        .q     (ex_mem_q)
    );

    mem_stage u_mem (
        .clk            (clk),
        .rst            (rst),
        .ex_mem         (ex_mem_q),
        .mem_data_out   (mem_data_out),
        .alu_result_out (mem_alu_result_out),
        .pc_plus4_out   (mem_pc_plus4_out),
        .reg_write_out  (mem_reg_write_out),
        .wb_sel_out     (mem_wb_sel_out),
        .rd_addr_out    (mem_rd_addr_out)
    );

    mem_wb_reg u_mem_wb (
        .clk (clk),
        .rst (rst),
        .d   (mem_wb_d),
        .q   (mem_wb_q)
    );

    wb_stage u_wb (
        .mem_wb      (mem_wb_q),
        .wb_data     (wb_data),
        .wb_rd       (wb_rd),
        .wb_reg_write(wb_reg_write)
    );

endmodule