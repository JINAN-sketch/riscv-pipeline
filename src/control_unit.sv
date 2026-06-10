`timescale 1ns/1ps

module control_unit(
    //instruction - 32 bits
    input logic[31:0] instr,

    output logic reg_write, // 1 means write to rd

    //ALU controls
    output logic alu_src, // Bsel, 0 means rs2, 1 means immediate
    output logic[3:0] alu_op, //ALU operation select, ALUop
    output logic alu_pc, // Asel, 0 means rs1, 1 means pc

    //memory controls
    output logic mem_write, // 1 means write data to memory enabled - store
    output logic mem_read, // 1 means read data form memory enabled - load
    output logic[2:0] mem_width, //width + sign for load/store, func3 passed through

    //writeback
    output logic[1:0] wb_sel,  //00-> mem data, 01-> ALU, 10 -> pc+4

    //PC control
    output logic branch, // 1 means its a branch instruction
    output logic jump, // 1 means this is JAL or JALR

    //immediate type select
    output logic [2:0]  imm_sel     // 000=I, 001=S, 010=B, 011=U, 100=J
);
    //extract feilds
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;

    assign opcode = instr[6:0];
    assign funct3 = instr[14:12];
    assign funct7 = instr[31:25];
    always_comb begin
        // ── Defaults (safe values — no write, no memory, sequential PC) ──
        reg_write = 1'b0;
        alu_src   = 1'b0;
        alu_op    = 4'b0000;  // ADD
        alu_pc    = 1'b0;
        mem_write = 1'b0;
        mem_read  = 1'b0;
        mem_width = funct3;   // pass funct3 through — MEM stage uses it
        wb_sel    = 2'b01;    // default: ALU result
        branch    = 1'b0;
        jump      = 1'b0;
        imm_sel   = 3'b000;   // I-type default
        case(opcode)
            // ── R-type ──────────────────────────────────────────
            7'b0110011: begin
                reg_write = 1'b1;
                alu_src   = 1'b0;   // use rs2
                case (funct3)
                    3'b000: alu_op = funct7[5] ? 4'b0001 : 4'b0000; // SUB / ADD
                    3'b001: alu_op = 4'b0010; // SLL
                    3'b010: alu_op = 4'b0011; // SLT
                    3'b011: alu_op = 4'b0100; // SLTU
                    3'b100: alu_op = 4'b0101; // XOR
                    3'b101: alu_op = funct7[5] ? 4'b0111 : 4'b0110; // SRA / SRL
                    3'b110: alu_op = 4'b1000; // OR
                    3'b111: alu_op = 4'b1001; // AND
                    default: alu_op = 4'b0000;
                endcase
            end
            // ── I-type (arithmetic) ──────────────────────────────
            7'b0010011: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;   // use immediate
                imm_sel   = 3'b000; // I-type immediate
                case (funct3)
                    3'b000: alu_op = 4'b0000; // ADDI
                    3'b001: alu_op = 4'b0010; // SLLI
                    3'b010: alu_op = 4'b0011; // SLTI
                    3'b011: alu_op = 4'b0100; // SLTIU
                    3'b100: alu_op = 4'b0101; // XORI
                    3'b101: alu_op = funct7[5] ? 4'b0111 : 4'b0110; // SRAI / SRLI
                    3'b110: alu_op = 4'b1000; // ORI
                    3'b111: alu_op = 4'b1001; // ANDI
                    default: alu_op = 4'b0000;
                endcase
            end
            // ── Load ─────────────────────────────────────────────
            7'b0000011: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;   // address = rs1 + imm
                alu_op    = 4'b0000; // ADD
                mem_read  = 1'b1;
                imm_sel   = 3'b000; // I-type immediate
                wb_sel    = 2'b00;  // write memory data to rd
            end

            // ── Store ────────────────────────────────────────────
            7'b0100011: begin
                alu_src   = 1'b1;   // address = rs1 + imm
                alu_op    = 4'b0000; // ADD
                mem_write = 1'b1;
                imm_sel   = 3'b001; // S-type immediate
            end

            // ── Branch ───────────────────────────────────────────
            7'b1100011: begin
                alu_src   = 1'b0;   // compare rs1 and rs2
                alu_pc    = 1'b0;
                branch    = 1'b1;
                imm_sel   = 3'b010; // B-type immediate
                // funct3 tells the EX stage which comparison to use
                // BEQ=000 BNE=001 BLT=100 BGE=101 BLTU=110 BGEU=111
            end

            // ── LUI ──────────────────────────────────────────────
            7'b0110111: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 4'b1010; // pass immediate through (LUI)
                imm_sel   = 3'b011; // U-type immediate
            end

            // ── AUIPC ────────────────────────────────────────────
            7'b0010111: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_pc    = 1'b1;   // ALU input A = PC
                alu_op    = 4'b0000; // ADD: PC + (imm << 12)
                imm_sel   = 3'b011; // U-type immediate
            end

            // ── JAL ──────────────────────────────────────────────
            7'b1101111: begin
                reg_write = 1'b1;
                jump      = 1'b1;
                wb_sel    = 2'b10;  // write PC+4 to rd (link address)
                imm_sel   = 3'b100; // J-type immediate
            end

            // ── JALR ─────────────────────────────────────────────
            7'b1100111: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;   // target = rs1 + imm
                alu_op    = 4'b0000; // ADD
                jump      = 1'b1;
                wb_sel    = 2'b10;  // write PC+4 to rd
                imm_sel   = 3'b000; // I-type immediate
            end
        endcase
    end
endmodule