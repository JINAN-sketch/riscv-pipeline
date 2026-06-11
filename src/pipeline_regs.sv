`timescale 1ns/1ps
// pipeline_regs.sv
// Package + all pipeline register modules.
// This week: pipeline_pkg (IF/ID struct) + if_id_reg module.
// ID/EX, EX/MEM, MEM/WB added in Week 2.

// ================================================================
// Package — import this in every module that touches a pipeline reg
// Usage: import pipeline_pkg::*;
// ================================================================
package pipeline_pkg;
    typedef struct packed{
        logic [31:0] pc; //pc for this instr
        logic [31:0] pc_plus4; //pc+4 or for link address
        logic [31:0] instr; //raw 32 bit instr
    } if_id_t;

    // ID/EX payload — travels from Decode to Execute
    typedef struct packed {
        // Control signals
        logic        reg_write;
        logic        alu_src;
        logic [3:0]  alu_op;
        logic        alu_pc;
        logic        mem_write;
        logic        mem_read;
        logic [2:0]  mem_width;
        logic [1:0]  wb_sel;
        logic        branch;
        logic        jump;

        // Data
        logic [31:0] pc;
        logic [31:0] pc_plus4;
        logic [31:0] rs1_data;
        logic [31:0] rs2_data;
        logic [31:0] imm;

        // Register addresses (needed by forwarding unit in Week 3)
        logic [4:0]  rs1_addr;
        logic [4:0]  rs2_addr;
        logic [4:0]  rd_addr;
    } id_ex_t;
endpackage

// ================================================================
// IF/ID pipeline register
// ================================================================


import pipeline_pkg::*;

module if_id_reg(
    input logic clk,
    input logic rst,
    input logic if_id_write, // 1 means latch nirmally, 0 means stall
    input logic flush, // 1 means insert NOP(branch misprediction)
    input if_id_t d,
    output if_id_t q
);
    // Canonical RISC-V NOP: ADDI x0, x0, 0
    localparam logic [31:0] NOP = 32'h0000_0013;
    //localparam means the value cant be changed from outside the module

    always_ff @(posedge clk) begin
        if(rst || flush)begin
            q.pc <= 32'h0;
            q.pc_plus4 <= 32'h0;
            q.instr <= NOP;
        end
        else if(if_id_write) begin
            q <= d;
        end
        //else: hold/stall, dont flush or write
    end
endmodule



// ================================================================
// ID/EX pipeline register
// ================================================================
module id_ex_reg (
    input  logic    clk,
    input  logic    rst,
    input  logic    flush,    // 1 = insert bubble (branch/load-use)
    input  id_ex_t  d,
    output id_ex_t  q
);

    always_ff @(posedge clk) begin
        if (rst || flush) begin
            // Zero everything — all control signals go to safe 0
            q <= '0;
        end else begin
            q <= d;
        end
    end

endmodule