`timescale 1ns/1ps
import pipeline_pkg::*;

module tb_riscv_top;

    logic clk = 0;
    logic rst;
    always #5 clk = ~clk;

    riscv_top #(.MEM_FILE("D:/Project_1/vectors/instr_mem.hex")) u_top (
        .clk (clk),
        .rst (rst)
    );

    // Access regfile directly for checking
    task check_reg(input int n, input logic [31:0] expected, input string name);
        logic [31:0] got;
        got = u_top.u_id.u_rf.regs[n];
        if (got !== expected)
            $display("FAIL %s (x%0d) | got=%08h expected=%08h", name, n, got, expected);
        else
            $display("PASS %s (x%0d) = %08h", name, n, got);
    endtask

    initial begin
        $dumpfile("D:/Project_1/sim/tb_riscv_top.vcd");
        $dumpvars(0, tb_riscv_top);

        rst = 1;
        repeat(4) @(posedge clk);
        rst = 0;

        // Short program — 9 instructions — 30 cycles is generous margin
        repeat(30) @(posedge clk);
        #1;

        $display("\n--- Register file check: Test 6 — Compound (load-use + dependent branch) ---");
        check_reg(1, 32'd5, "x1  ADDI 5");
        check_reg(2, 32'd5, "x2  LW   mem[0] (load-use stall feeding the branch)");
        check_reg(3, 32'd0, "x3  ADDI 99 (SKIPPED — must stay 0)");
        check_reg(4, 32'd3, "x4  ADDI 3 (branch target)");

        $display("\n--- done ---");
        $finish;
    end

    // Cycle monitor
    integer cycle = 0;
    always @(posedge clk) begin
        #1;
        cycle <= cycle + 1;
        $display("c%0d | PC=%02h IFID=%08h | IDEX rd=x%0d op=%04b | EXMEM rd=x%0d regw=%b | MEMWB rd=x%0d regw=%b wbdata=%08h | fA=%b fB=%b | brTkn=%b iffl=%b idfl=%b pcw=%b",
            cycle,
            u_top.if_pc_out,
            u_top.if_id_q.instr,
            u_top.id_ex_q.rd_addr,
            u_top.id_ex_q.alu_op,
            u_top.ex_mem_q.rd_addr,
            u_top.ex_mem_q.reg_write,
            u_top.mem_wb_q.rd_addr,
            u_top.mem_wb_q.reg_write,
            u_top.wb_data,
            u_top.fwd_a,
            u_top.fwd_b,
            u_top.ex_branch_taken,
            u_top.if_id_flush,
            u_top.id_ex_flush,
            u_top.pc_write);
    end

endmodule