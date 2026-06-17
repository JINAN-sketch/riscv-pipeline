`timescale 1ns/1ps
// instr_mem.sv
// Synchronous instruction ROM — 256 words × 32 bits (1 KB)
// Vivado infers this as BRAM (synchronous read).
// Output appears one cycle after address is presented.

module instr_mem #(
    parameter MEM_FILE = "D:/Project_1/vectors/instr_mem.hex"
)(
    input logic clk,
    input logic rst,
    input  logic        freeze,
    input logic [31:0] addr,  //byte addressed with 256 words so we only use [9:2]
    output logic [31:0] instr
);
    logic [31:0] mem [0:255];

    initial $readmemh(MEM_FILE, mem);

    always_ff @(posedge clk) begin
    if (rst)
        instr <= 32'h0000_0013;   // NOP on reset
    else if (!freeze)
        instr <= mem[addr[9:2]];  // only advance when not frozen
    // else: hold current instr during stall
    end
endmodule
