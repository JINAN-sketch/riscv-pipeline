`timescale 1ns/1ps

module mac_unit (
    input  logic        clk,
    input  logic        rst,

    // MMIO interface — driven by mem_stage
    input  logic [1:0]  addr,       // 00=A, 01=B, 10=CTRL, 11=RESULT
    input  logic [31:0] wdata,      // write data
    input  logic        we,         // write enable (SW)
    output logic [31:0] rdata       // read data (LW)
);

    // ── Internal registers ───────────────────────────────────────
    logic [31:0] reg_a;
    logic [31:0] reg_b;
    logic [63:0] accumulator;  // 64-bit to hold full multiply results

    // ── Write logic (synchronous) ────────────────────────────────
    always_ff @(posedge clk) begin
        if (rst) begin
            reg_a       <= 32'h0;
            reg_b       <= 32'h0;
            accumulator <= 64'h0;
        end else if (we) begin
            case (addr)
                2'b00: reg_a <= wdata;                                    // write A
                2'b01: reg_b <= wdata;                                    // write B
                2'b10: begin
                    if (wdata == 32'h1)
                        accumulator <= accumulator + (reg_a * reg_b);     // MAC
                    else
                        accumulator <= 64'h0;                              // clear
                end
                2'b11: ; // RESULT is read-only, writes ignored
            endcase
        end
    end

    // ── Read logic (combinational) ───────────────────────────────
    always_comb begin
        case (addr)
            2'b00:   rdata = reg_a;
            2'b01:   rdata = reg_b;
            2'b10:   rdata = 32'h0;            // CTRL register not readable
            2'b11:   rdata = accumulator[31:0]; // return low 32 bits of result
            default: rdata = 32'h0;
        endcase
    end

endmodule