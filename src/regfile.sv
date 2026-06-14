`timescale 1ns/1ps

module regfile(
    input logic clk,
    input logic rst,

    //read ports(combinational)
    input logic [4:0] rs1,
    input logic [4:0] rs2,
    output logic [31:0] rs1_data,
    output logic [31:0] rs2_data,

    //write port(synchronous/posedge clk)
    input logic [4:0] rd,
    input logic [31:0] rd_data,
    input logic reg_write
);
    logic [31:0] regs[0:31]; // 32 registers, each of 32 bit
    integer j;
    initial begin
        for (j = 0; j < 32; j = j + 1)
            regs[j] = 32'h0;
    end

    // ── Synchronous write ────────────────────────────────────────
    // x0 is hardwired to zero — never written
    integer i;
    always_ff @(posedge clk) begin
        if(rst) begin
            for(i=0;i < 32;i++)begin 
                regs[i] <= 32'h0;
            end
        end else if(reg_write && rd != 5'b0) begin
            regs[rd] <= rd_data;
        end
    end

    // ── Asynchronous read ────────────────────────────────────────
    // x0 always reads as zero regardless of what is stored

    assign rs1_data = (rs1 == 5'b0) ? 32'h0 : regs[rs1];
    assign rs2_data = (rs2 == 5'b0) ? 32'h0 : regs[rs2];
endmodule