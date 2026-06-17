`timescale 1ns/1ps

module hazard_unit (
    // Load-use detection — instruction currently in ID/EX
    input  logic        id_ex_mem_read,   // is the EX-stage instruction a load?
    input  logic [4:0]  id_ex_rd_addr,    // its destination register

    // Instruction currently in ID (about to enter ID/EX)
    input  logic [4:0]  if_id_rs1_addr,
    input  logic [4:0]  if_id_rs2_addr,

    // Branch outcome from EX stage
    input  logic        branch_taken,

    // Outputs — control PC, IF/ID, ID/EX
    output logic        pc_write,      // 0 = freeze PC (stall)
    output logic        if_id_write,   // 0 = freeze IF/ID (stall)
    output logic        if_id_flush,   // 1 = squash IF/ID (branch taken)
    output logic        id_ex_flush    // 1 = insert bubble into ID/EX (stall OR branch taken)
);

    logic load_use_hazard;

    // ── Load-use hazard detection ──────────────────────────────────
    // True when: instruction in EX is a load, its destination is not x0,
    // and the instruction currently in ID reads that same register.
    assign load_use_hazard = id_ex_mem_read &&
                              (id_ex_rd_addr != 5'b0) &&
                              ((id_ex_rd_addr == if_id_rs1_addr) ||
                               (id_ex_rd_addr == if_id_rs2_addr));

    always_comb begin
        if (load_use_hazard) begin
            // Stall: freeze PC and IF/ID for one cycle, bubble ID/EX
            pc_write    = 1'b0;
            if_id_write = 1'b0;
            if_id_flush = 1'b0;
            id_ex_flush = 1'b1;
        end else if (branch_taken) begin
            // Branch misprediction: squash the wrongly-fetched instruction in IF/ID
            pc_write    = 1'b1;
            if_id_write = 1'b1;
            if_id_flush = 1'b1;
            id_ex_flush = 1'b1;
        end else begin
            // Normal operation
            pc_write    = 1'b1;
            if_id_write = 1'b1;
            if_id_flush = 1'b0;
            id_ex_flush = 1'b0;
        end
    end

endmodule