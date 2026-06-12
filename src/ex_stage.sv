`timescale 1ns/1ps

module ex_stage
    import pipeline_pkg::*;
(
    //from ID/EX reg
    input id_ex_t id_ex,

    //forwarding mux selects
    //for this sessions tb, we tie it to 2'b00
    input  logic [1:0]  fwd_a,      // 00=ID/EX rs1, 01=MEM/WB result, 10=WB result
    input  logic [1:0]  fwd_b,      // 00=ID/EX rs2, 01=MEM/WB result, 10=WB result

    // Forwarded values (from MEM and WB stages — Week 3)
    input  logic [31:0] fwd_mem_result,   // value from MEM/WB stage
    input  logic [31:0] fwd_wb_result,    // value from WB stage

    // Outputs to EX/MEM register
    output logic [31:0] alu_result,
    output logic [31:0] rs2_data_out,   // forwarded rs2 — used by store in MEM stage
    output logic        branch_taken,   // 1 = branch condition is true
    output logic [31:0] branch_target,  // PC + B-imm
    output logic [31:0] jalr_target,    // rs1 + I-imm, LSB cleared

    // Pass-through control signals to EX/MEM register
    output logic        reg_write,
    output logic        mem_write,
    output logic        mem_read,
    output logic [2:0]  mem_width,
    output logic [1:0]  wb_sel,
    output logic [4:0]  rd_addr,
    output logic [31:0] pc_plus4
);
    // ── Forwarding muxes ─────────────────────────────────────────
    // These muxes select the correct value for ALU inputs.
    // This week both are tied to 2'b00 so raw register values are used.
    logic [31:0] alu_a, alu_b_pre, alu_b;

    always_comb begin
        case (fwd_a)
            2'b00:   alu_a = id_ex.rs1_data;      // from register file
            2'b01:   alu_a = fwd_mem_result;       // forwarded from MEM/WB
            2'b10:   alu_a = fwd_wb_result;        // forwarded from WB
            default: alu_a = id_ex.rs1_data;
        endcase
    end

    always_comb begin
        case (fwd_b)
            2'b00:   alu_b_pre = id_ex.rs2_data;   // from register file
            2'b01:   alu_b_pre = fwd_mem_result;    // forwarded from MEM/WB
            2'b10:   alu_b_pre = fwd_wb_result;     // forwarded from WB
            default: alu_b_pre = id_ex.rs2_data;
        endcase
    end

    // alu_src mux: 0 = forwarded rs2, 1 = immediate
    assign alu_b = id_ex.alu_src ? id_ex.imm : alu_b_pre;

    // rs2 output uses the forwarded value (before alu_src mux)
    // because store needs the actual rs2 value, not the address immediate
    assign rs2_data_out = alu_b_pre;

    // ── ALU A input select ───────────────────────────────────────
    // alu_pc=1 means use PC as input A (AUIPC)
    logic [31:0] alu_a_final;
    assign alu_a_final = id_ex.alu_pc ? id_ex.pc : alu_a;

    // ── ALU instantiation ────────────────────────────────────────
    logic        zero;

    alu u_alu (
        .a       (alu_a_final),
        .b       (alu_b),
        .alu_op  (id_ex.alu_op),
        .result  (alu_result),
        .zero    (zero)
    );

    // ── Branch condition evaluator ───────────────────────────────
    // Evaluates the branch condition using forwarded rs1 and rs2 values.
    // The ALU computes rs1-rs2 for BEQ/BNE; for BLT/BGE we compare directly.
    always_comb begin
        branch_taken = 1'b0;
        if (id_ex.branch) begin
            case (id_ex.mem_width)   // mem_width carries funct3 for branches
                3'b000: branch_taken = (alu_a == alu_b_pre);                          // BEQ
                3'b001: branch_taken = (alu_a != alu_b_pre);                          // BNE
                3'b100: branch_taken = ($signed(alu_a) <  $signed(alu_b_pre));        // BLT
                3'b101: branch_taken = ($signed(alu_a) >= $signed(alu_b_pre));        // BGE
                3'b110: branch_taken = (alu_a <  alu_b_pre);                          // BLTU
                3'b111: branch_taken = (alu_a >= alu_b_pre);                          // BGEU
                default: branch_taken = 1'b0;
            endcase
        end
    end

    // ── Branch target: PC + sign-extended B-immediate ────────────
    assign branch_target = id_ex.pc + id_ex.imm;

    // ── JALR target: rs1 + I-immediate, LSB cleared ──────────────
    // RISC-V spec requires the LSB of JALR target to be cleared to 0
    // to ensure the target is always 2-byte aligned
    assign jalr_target = (alu_a + id_ex.imm) & 32'hFFFF_FFFE;

    // ── Pass-through control signals ─────────────────────────────
    assign reg_write  = id_ex.reg_write;
    assign mem_write  = id_ex.mem_write;
    assign mem_read   = id_ex.mem_read;
    assign mem_width  = id_ex.mem_width;
    assign wb_sel     = id_ex.wb_sel;
    assign rd_addr    = id_ex.rd_addr;
    assign pc_plus4   = id_ex.pc_plus4;
endmodule