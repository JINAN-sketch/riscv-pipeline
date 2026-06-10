`timescale 1ns/1ps
import pipeline_pkg::*;

module tb_id;

    logic        clk = 0;
    logic        rst;
    always #5 clk = ~clk;

    // IF/ID register input (we drive this manually)
    if_id_t if_id;

    // Writeback (tied off — not testing WB loop yet)
    logic [4:0]  wb_rd       = 5'b0;
    logic [31:0] wb_data     = 32'h0;
    logic        wb_reg_write = 1'b0;

    // ID outputs
    logic        reg_write, alu_src, alu_pc, mem_write, mem_read, branch, jump;
    logic [3:0]  alu_op;
    logic [2:0]  mem_width, imm_sel;
    logic [1:0]  wb_sel;
    logic [31:0] rs1_data, rs2_data, imm, jal_target;
    logic [4:0]  rs1_addr, rs2_addr, rd_addr;

    id_stage u_id (
        .clk          (clk),
        .rst          (rst),
        .if_id        (if_id),
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
        .jal_target   (jal_target)
    );

    task apply_instr(input logic [31:0] instruction, input string name);
        if_id.instr    = instruction;
        if_id.pc       = 32'h00000010;  // arbitrary PC for testing
        if_id.pc_plus4 = 32'h00000014;
        @(posedge clk); #1;
        $display("%-8s | reg_write=%b alu_src=%b alu_op=%04b mem_r=%b mem_w=%b branch=%b jump=%b wb_sel=%02b imm=%08h",
                 name, reg_write, alu_src, alu_op, mem_read, mem_write, branch, jump, wb_sel, imm);
    endtask

    initial begin
        $dumpfile("D:/Project_1/sim/tb_id.vcd");
        $dumpvars(0, tb_id);

        rst = 1;
        if_id.instr    = 32'h0000_0013;
        if_id.pc       = 32'h0;
        if_id.pc_plus4 = 32'h4;
        @(posedge clk); #1;
        @(posedge clk); #1;
        rst = 0;

        $display("\n--- Control signal check ---");

        // ADDI x1, x0, 5  →  I-type, imm=5
        apply_instr(32'h00500093, "ADDI");

        // ADD x3, x1, x2  →  R-type
        apply_instr(32'h002081B3, "ADD");

        // LW x4, 0(x1)    →  Load
        apply_instr(32'h0000A203, "LW");

        // SW x4, 0(x1)    →  Store
        apply_instr(32'h0040A023, "SW");

        // BEQ x1, x2, 8   →  Branch
        apply_instr(32'h00208463, "BEQ");

        // JAL x1, 12      →  Jump
        apply_instr(32'h00C000EF, "JAL");

        // LUI x5, 0x12345 →  U-type
        apply_instr(32'h123452B7, "LUI");

        $display("\n--- done ---");
        $finish;
    end

endmodule