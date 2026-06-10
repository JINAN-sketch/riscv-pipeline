`timescale 1ns/1ps

module imm_gen (
    input  logic [31:0] instr,
    input  logic [2:0]  imm_sel, // from control unit
    output logic [31:0] imm
);

    always_comb begin
        case (imm_sel)
            3'b000: // I-type: addi, lw, jalr, etc.
                imm = {{20{instr[31]}}, instr[31:20]};

            3'b001: // S-type: sw, sh, sb
                imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};

            3'b010: // B-type: beq, bne, blt, bge, etc.
                imm = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};

            3'b011: // U-type: lui, auipc
                imm = {instr[31:12], 12'b0};

            3'b100: // J-type: jal
                imm = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};

            default:
                imm = 32'h0;
        endcase
    end

endmodule