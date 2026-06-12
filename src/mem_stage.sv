`timescale 1ns/1ps

module mem_stage
    import pipeline_pkg::*;
(
    input  logic        clk,
    input  logic        rst,

    // From EX/MEM register
    input  ex_mem_t     ex_mem,

    // Outputs to MEM/WB register
    output logic [31:0] mem_data_out,   // loaded data (sign/zero extended)
    output logic [31:0] alu_result_out, // pass-through ALU result
    output logic [31:0] pc_plus4_out,   // pass-through link address
    output logic        reg_write_out,
    output logic [1:0]  wb_sel_out,
    output logic [4:0]  rd_addr_out
);

    // ── Data memory — 256 words × 32 bits ───────────────────────
    logic [31:0] dmem [0:255];

    // Synchronous write
    logic [31:0] dmem_wdata;
    logic [7:0]  dmem_waddr;

    always_ff @(posedge clk) begin
        if (ex_mem.mem_write) begin
            dmem_waddr = ex_mem.alu_result[9:2];
            case (ex_mem.mem_width)
                3'b000: begin  // SB
                    dmem_wdata        = dmem[dmem_waddr];
                    dmem_wdata[7:0]   = ex_mem.rs2_data[7:0];
                    dmem[dmem_waddr] <= dmem_wdata;
                end
                3'b001: begin  // SH
                    dmem_wdata        = dmem[dmem_waddr];
                    dmem_wdata[15:0]  = ex_mem.rs2_data[15:0];
                    dmem[dmem_waddr] <= dmem_wdata;
                end
                3'b010: // SW
                    dmem[dmem_waddr] <= ex_mem.rs2_data;
                default: ;
            endcase
        end
    end

    // Synchronous read
    logic [31:0] raw_mem_data;
    always_ff @(posedge clk) begin
        if (rst)
            raw_mem_data <= 32'h0;
        else if (ex_mem.mem_read)
            raw_mem_data <= dmem[ex_mem.alu_result[9:2]];
        else
            raw_mem_data <= 32'h0;
    end

    // ── Load width + sign/zero extension ─────────────────────────
    // Applied combinationally to raw_mem_data after the synchronous read
    always_comb begin
        case (ex_mem.mem_width)
            3'b000: mem_data_out = {{24{raw_mem_data[7]}},  raw_mem_data[7:0]};   // LB
            3'b001: mem_data_out = {{16{raw_mem_data[15]}}, raw_mem_data[15:0]};  // LH
            3'b010: mem_data_out = raw_mem_data;                                   // LW
            3'b100: mem_data_out = {24'h0, raw_mem_data[7:0]};                    // LBU
            3'b101: mem_data_out = {16'h0, raw_mem_data[15:0]};                   // LHU
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