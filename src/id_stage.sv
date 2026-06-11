`timescale 1ns/1ps

module id_stage 
    import pipeline_pkg::*;
(
    input  logic        clk,
    input  logic        rst,

    // From IF/ID register
    input  if_id_t      if_id,

    // Writeback input (from WB stage — register file write port)
    input  logic [4:0]  wb_rd,
    input  logic [31:0] wb_data,
    input  logic        wb_reg_write,

    // Control signals out (to ID/EX register next session)
    output logic        reg_write,
    output logic        alu_src,
    output logic [3:0]  alu_op,
    output logic        alu_pc,
    output logic        mem_write,
    output logic        mem_read,
    output logic [2:0]  mem_width,
    output logic [1:0]  wb_sel,
    output logic        branch,
    output logic        jump,
    output logic [2:0]  imm_sel,

    // Data out (to ID/EX register)
    output logic [31:0] rs1_data,
    output logic [31:0] rs2_data,
    output logic [31:0] imm,
    output logic [4:0]  rs1_addr,
    output logic [4:0]  rs2_addr,
    output logic [4:0]  rd_addr,

    // JAL target (computable here in ID)
    output logic [31:0] jal_target,

    // Packed struct output — drives ID/EX register directly
    output id_ex_t      id_ex_d
);

    // Extract register addresses from instruction
    assign rs1_addr = if_id.instr[19:15];
    assign rs2_addr = if_id.instr[24:20];
    assign rd_addr  = if_id.instr[11:7];

    // ── Register file ────────────────────────────────────────────
    regfile u_rf (
        .clk       (clk),
        .rst       (rst),
        .rs1       (rs1_addr),
        .rs2       (rs2_addr),
        .rs1_data  (rs1_data),
        .rs2_data  (rs2_data),
        .rd        (wb_rd),
        .rd_data   (wb_data),
        .reg_write (wb_reg_write)
    );

    // ── Control unit ─────────────────────────────────────────────
    control_unit u_cu (
        .instr     (if_id.instr),
        .reg_write (reg_write),
        .alu_src   (alu_src),
        .alu_op    (alu_op),
        .alu_pc    (alu_pc),
        .mem_write (mem_write),
        .mem_read  (mem_read),
        .mem_width (mem_width),
        .wb_sel    (wb_sel),
        .branch    (branch),
        .jump      (jump),
        .imm_sel   (imm_sel)
    );

    // ── Immediate generator ──────────────────────────────────────
    imm_gen u_ig (
        .instr   (if_id.instr),
        .imm_sel (imm_sel),
        .imm     (imm)
    );

    // ── JAL target: PC + J-immediate ─────────────────────────────
    // JAL target is PC-relative and uses only the J-type immediate.
    // We can compute it here in ID, saving one pipeline cycle vs EX.
    assign jal_target = if_id.pc + imm;
    // Note: this is only valid when imm_sel = J-type (JAL opcode).
    // The IF stage only uses jal_target when pc_sel = 2'b10,
    // which the hazard unit sets only on a JAL instruction.

    // ── Pack outputs into ID/EX struct ───────────────────────────
    assign id_ex_d.reg_write = reg_write;
    assign id_ex_d.alu_src   = alu_src;
    assign id_ex_d.alu_op    = alu_op;
    assign id_ex_d.alu_pc    = alu_pc;
    assign id_ex_d.mem_write = mem_write;
    assign id_ex_d.mem_read  = mem_read;
    assign id_ex_d.mem_width = mem_width;
    assign id_ex_d.wb_sel    = wb_sel;
    assign id_ex_d.branch    = branch;
    assign id_ex_d.jump      = jump;
    assign id_ex_d.pc        = if_id.pc;
    assign id_ex_d.pc_plus4  = if_id.pc_plus4;
    assign id_ex_d.rs1_data  = rs1_data;
    assign id_ex_d.rs2_data  = rs2_data;
    assign id_ex_d.imm       = imm;
    assign id_ex_d.rs1_addr  = rs1_addr;
    assign id_ex_d.rs2_addr  = rs2_addr;
    assign id_ex_d.rd_addr   = rd_addr;

endmodule