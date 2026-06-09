`timescale 1ns/1ps
// if_stage.sv
// Stage 1: Instruction Fetch
//
// Maintains the PC, computes PC+4, selects next PC from 4 sources,
// and instantiates instruction memory.
//
// pc_sel encoding:
//   2'b00 → PC+4          (normal sequential fetch)
//   2'b01 → branch_target (taken branch — from EX stage)
//   2'b10 → jal_target    (JAL — from ID stage, only 1-cycle penalty)
//   2'b11 → jalr_target   (JALR — from EX stage)

import pipeline_pkg::*;

module if_stage #(
    parameter MEM_FILE = "D:/Project_1/vectors/instr_mem.hex"
)(
    input logic clk,
    input logic rst,
    //hazard unit controls
    input logic pc_write, // 0 means freeze pc
    input logic [1:0] pc_sel,

    //jump/branch targets
    input logic [31:0] branch_target, //PC + B_IMM from EX
    input logic [31:0] jal_target,  // PC + J-imm, from ID
    input logic [31:0] jalr_target, // rs1 + I-imm, from EX

    // Outputs → IF/ID register inputs
    output logic [31:0] pc_out,
    output logic [31:0] pc_plus4_out,
    output logic [31:0] instr_out
);
    logic [31:0] pc_reg;
    logic [31:0] pc_plus4;
    logic [31:0] pc_next;
    // ── PC+4 (combinational) ──────────────────────────────────────
    assign pc_plus4 = pc_reg +32'd4;
    // ── Next-PC mux (combinational) ──────────────────────────────
    always_comb begin
        case (pc_sel)
            2'b00:   pc_next = pc_plus4;
            2'b01:   pc_next = branch_target;
            2'b10:   pc_next = jal_target;
            2'b11:   pc_next = jalr_target;
            default: pc_next = pc_plus4;
        endcase
    end

    // ── PC register (sequential) ─────────────────────────────────
    always_ff @(posedge clk) begin
        if (rst)       pc_reg <= 32'h0000_0000;
        else if (pc_write) pc_reg <= pc_next;
        // else: hold — stall
    end

    // ── Instruction memory ───────────────────────────────────────
    instr_mem #(.MEM_FILE(MEM_FILE)) u_imem (
        .clk   (clk),
        .rst   (rst),
        .addr  (pc_reg),
        .instr (instr_out)
    );

    // ── Outputs ──────────────────────────────────────────────────
    assign pc_out       = pc_reg;
    assign pc_plus4_out = pc_plus4;
    // instr_out comes directly from u_imem

endmodule