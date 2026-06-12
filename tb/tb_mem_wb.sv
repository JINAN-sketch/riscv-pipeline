`timescale 1ns/1ps

module tb_mem_wb
    import pipeline_pkg::*;
();
    logic clk = 0;
    logic rst;
    always #5 clk = ~clk;

    // ── EX/MEM register input (driven manually) ──────────────────
    ex_mem_t ex_mem_d, ex_mem_q;
    logic    ex_mem_flush = 1'b0;

    ex_mem_reg u_ex_mem (
        .clk   (clk),
        .rst   (rst),
        .flush (ex_mem_flush),
        .d     (ex_mem_d),
        .q     (ex_mem_q)
    );

    // ── MEM stage ────────────────────────────────────────────────
    logic [31:0] mem_data_out, alu_result_out, pc_plus4_out;
    logic        reg_write_out;
    logic [1:0]  wb_sel_out;
    logic [4:0]  rd_addr_out;

    mem_stage u_mem (
        .clk           (clk),
        .rst           (rst),
        .ex_mem        (ex_mem_q),
        .mem_data_out  (mem_data_out),
        .alu_result_out(alu_result_out),
        .pc_plus4_out  (pc_plus4_out),
        .reg_write_out (reg_write_out),
        .wb_sel_out    (wb_sel_out),
        .rd_addr_out   (rd_addr_out)
    );

    // ── MEM/WB register ──────────────────────────────────────────
    mem_wb_t mem_wb_d, mem_wb_q;

    always_comb begin
        mem_wb_d.reg_write  = reg_write_out;
        mem_wb_d.wb_sel     = wb_sel_out;
        mem_wb_d.alu_result = alu_result_out;
        mem_wb_d.mem_data   = mem_data_out;
        mem_wb_d.pc_plus4   = pc_plus4_out;
        mem_wb_d.rd_addr    = rd_addr_out;
    end

    mem_wb_reg u_mem_wb (
        .clk (clk),
        .rst (rst),
        .d   (mem_wb_d),
        .q   (mem_wb_q)
    );

    // ── WB stage ─────────────────────────────────────────────────
    logic [31:0] wb_data;
    logic [4:0]  wb_rd;
    logic        wb_reg_write;

    wb_stage u_wb (
        .mem_wb      (mem_wb_q),
        .wb_data     (wb_data),
        .wb_rd       (wb_rd),
        .wb_reg_write(wb_reg_write)
    );

    // ── Helper task ───────────────────────────────────────────────
    task drive_store(
        input logic [31:0] addr,
        input logic [31:0] data,
        input logic [2:0]  width
    );
        ex_mem_d.mem_write  = 1'b1;
        ex_mem_d.mem_read   = 1'b0;
        ex_mem_d.alu_result = addr;
        ex_mem_d.rs2_data   = data;
        ex_mem_d.mem_width  = width;
        ex_mem_d.reg_write  = 1'b0;
        ex_mem_d.wb_sel     = 2'b01;
        ex_mem_d.pc_plus4   = 32'h0;
        ex_mem_d.rd_addr    = 5'b0;
        @(posedge clk); #1;
        ex_mem_d.mem_write  = 1'b0;
    endtask

    task drive_load(
        input logic [31:0] addr,
        input logic [2:0]  width,
        input logic [4:0]  rd
    );
        ex_mem_d.mem_read   = 1'b1;
        ex_mem_d.mem_write  = 1'b0;
        ex_mem_d.alu_result = addr;
        ex_mem_d.mem_width  = width;
        ex_mem_d.reg_write  = 1'b1;
        ex_mem_d.wb_sel     = 2'b00;
        ex_mem_d.rs2_data   = 32'h0;
        ex_mem_d.pc_plus4   = 32'h0;
        ex_mem_d.rd_addr    = rd;
        @(posedge clk); #1;
        @(posedge clk); #1;
        ex_mem_d.mem_read   = 1'b0;
        // wait one more cycle for mem read + MEM/WB latch
        @(posedge clk); #1;
        $display("LOAD width=%03b rd=x%0d | mem_data=%08h wb_data=%08h wb_reg_write=%b",
                 width, rd, mem_data_out, wb_data, wb_reg_write);
    endtask

    // ── Stimulus ──────────────────────────────────────────────────
    initial begin
        $dumpfile("D:/Project_1/sim/tb_mem_wb.vcd");
        $dumpvars(0, tb_mem_wb);

        // zero out ex_mem_d
        ex_mem_d = '0;

        rst = 1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        rst = 0;

        $display("--- MEM/WB test ---");

        // Store 0xDEADBEEF as full word at address 0
        drive_store(32'h0, 32'hDEADBEEF, 3'b010);  // SW

        // Store 0xABCD as halfword at address 4
        drive_store(32'h4, 32'hABCD, 3'b001);       // SH

        // Store 0x42 as byte at address 8
        drive_store(32'h8, 32'h42, 3'b000);         // SB

        @(posedge clk); #1; // let stores settle

        // Load word — expect 0xDEADBEEF
        drive_load(32'h0, 3'b010, 5'd1);   // LW  x1

        // Load halfword signed — expect sign-extended 0xBEEF → 0xFFFFBEEF
        drive_load(32'h0, 3'b001, 5'd2);   // LH  x2

        // Load halfword unsigned — expect zero-extended 0xBEEF → 0x0000BEEF
        drive_load(32'h0, 3'b101, 5'd3);   // LHU x3

        // Load byte signed — expect sign-extended 0xEF → 0xFFFFFFEF
        drive_load(32'h0, 3'b000, 5'd4);   // LB  x4

        // Load byte unsigned — expect 0xEF → 0x000000EF
        drive_load(32'h0, 3'b100, 5'd5);   // LBU x5

        $display("--- done ---");
        $finish;
    end

endmodule