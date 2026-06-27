`timescale 1ns/1ps

module mem_stage
    import pipeline_pkg::*;
(
    input  logic        clk,
    input  logic        rst,
    input  ex_mem_t     ex_mem,

    // MAC unit MMIO interface
    output logic [1:0]  mac_addr,
    output logic [31:0] mac_wdata,
    output logic        mac_we,
    input  logic [31:0] mac_rdata,

    // Outputs to MEM/WB register
    output logic [31:0] mem_data_out,
    output logic [31:0] alu_result_out,
    output logic [31:0] pc_plus4_out,
    output logic        reg_write_out,
    output logic [1:0]  wb_sel_out,
    output logic [4:0]  rd_addr_out
);

    // ── Data memory ──────────────────────────────────────────────
    logic [31:0] dmem [0:255];

    // ── MMIO address decode ──────────────────────────────────────
    logic is_mmio;
    assign is_mmio = (ex_mem.alu_result >= 32'h400);

    // ── MAC unit wiring ──────────────────────────────────────────
    assign mac_addr  = ex_mem.alu_result[3:2];
    assign mac_wdata = ex_mem.rs2_data;
    assign mac_we    = ex_mem.mem_write && is_mmio;

    // ── Combinational read ───────────────────────────────────────
    logic [31:0] raw_mem_data;
    assign raw_mem_data = is_mmio ? mac_rdata : dmem[ex_mem.alu_result[9:2]];

    // ── Synchronous write (dmem only) ────────────────────────────
    logic [31:0] dmem_wdata;
    always_ff @(posedge clk) begin
        if (ex_mem.mem_write && !is_mmio) begin
            case (ex_mem.mem_width)
                3'b000: begin
                    dmem_wdata       = dmem[ex_mem.alu_result[9:2]];
                    dmem_wdata[7:0]  = ex_mem.rs2_data[7:0];
                    dmem[ex_mem.alu_result[9:2]] <= dmem_wdata;
                end
                3'b001: begin
                    dmem_wdata        = dmem[ex_mem.alu_result[9:2]];
                    dmem_wdata[15:0]  = ex_mem.rs2_data[15:0];
                    dmem[ex_mem.alu_result[9:2]] <= dmem_wdata;
                end
                default:
                    dmem[ex_mem.alu_result[9:2]] <= ex_mem.rs2_data;
            endcase
        end
    end

    // ── Load sign/zero extension ─────────────────────────────────
    always_comb begin
        case (ex_mem.mem_width)
            3'b000:  mem_data_out = {{24{raw_mem_data[7]}},  raw_mem_data[7:0]};
            3'b001:  mem_data_out = {{16{raw_mem_data[15]}}, raw_mem_data[15:0]};
            3'b010:  mem_data_out = raw_mem_data;
            3'b100:  mem_data_out = {24'h0, raw_mem_data[7:0]};
            3'b101:  mem_data_out = {16'h0, raw_mem_data[15:0]};
            default: mem_data_out = raw_mem_data;
        endcase
    end

    // ── Pass-throughs ─────────────────────────────────────────────
    assign alu_result_out = ex_mem.alu_result;
    assign pc_plus4_out   = ex_mem.pc_plus4;
    assign reg_write_out  = ex_mem.reg_write;
    assign wb_sel_out     = ex_mem.wb_sel;
    assign rd_addr_out    = ex_mem.rd_addr;

endmodule