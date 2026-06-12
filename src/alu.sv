`timescale 1ns/1ps

module alu(
    input logic [31:0] a,
    input logic [31:0] b,
    input logic [3:0] alu_op, // comes from control unit
    output logic [31:0] result,
    output logic zero   // 1 if result == 0(used for beq,bne)
);
    always_comb begin
        case(alu_op)
            4'b0000: result = a + b;                               // ADD
            4'b0001: result = a - b;                               // SUB
            4'b0010: result = a << b[4:0];                         // SLL
            4'b0011: result = $signed(a) < $signed(b) ? 32'h1 : 32'h0;  // SLT
            4'b0100: result = a < b              ? 32'h1 : 32'h0;  // SLTU
            4'b0101: result = a ^ b;                               // XOR
            4'b0110: result = a >> b[4:0];                         // SRL
            4'b0111: result = $signed(a) >>> b[4:0];               // SRA
            4'b1000: result = a | b;                               // OR
            4'b1001: result = a & b;                               // AND
            4'b1010: result = b;                                   // LUI pass-through
            default: result = 32'h0;
        endcase
        // for shifting we need only 5 bits(b[4:0])-> 2^5 = 32
        //more shifts are redundant 
        assign zero = (result == 32'h0);
    end
endmodule