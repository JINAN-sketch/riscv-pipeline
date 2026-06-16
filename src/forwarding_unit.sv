`timescale 1ns/1ps

module forwarding_unit
(
    // Source registers of the instruction currently in EX
    input  logic [4:0]  id_ex_rs1_addr,
    input  logic [4:0]  id_ex_rs2_addr,

    // Destination + write-enable of instruction in MEM (EX/MEM register)
    input  logic [4:0]  ex_mem_rd_addr,
    input  logic        ex_mem_reg_write,

    // Destination + write-enable of instruction in WB (MEM/WB register)
    input  logic [4:0]  mem_wb_rd_addr,
    input  logic        mem_wb_reg_write,

    // Forwarding select outputs — feed directly into ex_stage
    output logic [1:0]  fwd_a,
    output logic [1:0]  fwd_b
);

    // fwd encoding: 00 = register file value, 01 = EX/MEM forward, 10 = MEM/WB forward

    always_comb begin
        // ── fwd_a: forwarding for rs1 ──────────────────────────
        if (ex_mem_reg_write && (ex_mem_rd_addr != 5'b0) && (ex_mem_rd_addr == id_ex_rs1_addr))
            fwd_a = 2'b01;
        else if (mem_wb_reg_write && (mem_wb_rd_addr != 5'b0) && (mem_wb_rd_addr == id_ex_rs1_addr))
            fwd_a = 2'b10;
        else
            fwd_a = 2'b00;

        // ── fwd_b: forwarding for rs2 ──────────────────────────
        if (ex_mem_reg_write && (ex_mem_rd_addr != 5'b0) && (ex_mem_rd_addr == id_ex_rs2_addr))
            fwd_b = 2'b01;
        else if (mem_wb_reg_write && (mem_wb_rd_addr != 5'b0) && (mem_wb_rd_addr == id_ex_rs2_addr))
            fwd_b = 2'b10;
        else
            fwd_b = 2'b00;
    end

endmodule