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
    // u_top.u_id.u_rf.regs[n]
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

        // Run enough cycles for all instructions to complete
        // 32 instructions × 1 cycle + 5 pipeline stages = ~40 cycles
        repeat(60) @(posedge clk);
        #1;

        $display("\n--- Register file check ---");
        check_reg(1, 32'd10, "x1  ADDI 10");
        check_reg(2, 32'd20, "x2  ADDI 20");
        check_reg(3, 32'd30, "x3  ADD  x1+x2");
        check_reg(4, 32'd20, "x4  SUB  x3-x1");
        check_reg(5, 32'd30, "x5  LW   mem[0]");
        check_reg(6, 32'd50, "x6  ADD  x5+x4");
        check_reg(7, 32'd0,  "x7  SKIPPED (branch taken)");
        check_reg(8, 32'd7,  "x8  ADDI 7 (branch target)");

        $display("\n--- done ---");
        $finish;
    end

    // Cycle monitor — PC/instruction phase-alignment tracer
    integer cycle = 0;
    always @(posedge clk) begin
        #1;
        cycle <= cycle + 1;
        $display("c%0d | pc_reg=%08h instr_out=%08h || if_id.pc=%08h if_id.instr=%08h || id_ex.pc=%08h id_ex.imm=%08h id_ex.branch=%b || br_target=%08h brTkn=%b",
            cycle,
            u_top.if_pc_out,        // pc_reg as currently wired (pc_out)
            u_top.if_instr_out,     // instruction coming out of instr_mem this cycle
            u_top.if_id_q.instr,    // what IF/ID actually latched
            u_top.if_id_q.pc,       // the PC tag IF/ID latched alongside it
            u_top.id_ex_q.pc,       // PC tag after ID/EX latches it
            u_top.id_ex_q.imm,
            u_top.id_ex_q.branch,
            u_top.ex_branch_target,
            u_top.ex_branch_taken);
    end
    

endmodule