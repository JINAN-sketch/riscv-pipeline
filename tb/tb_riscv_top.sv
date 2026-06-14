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
        check_reg(1, 32'd10,  "x1  ADDI 10");
        check_reg(2, 32'd20,  "x2  ADDI 20");
        check_reg(3, 32'd30,  "x3  ADD  x1+x2");
        check_reg(4, 32'd5,   "x4  ADDI 5");
        check_reg(5, 32'd25,  "x5  SUB  x3-x4");
        check_reg(6, 32'd30,  "x6  LW   mem[0]");

        $display("\n--- done ---");
        $finish;
    end

    // Cycle monitor
    integer cycle = 0;
    always @(posedge clk) begin
    #1;
    cycle <= cycle + 1;
    $display("cyc=%0d | mem_wb: wb_sel=%02b mem_data=%08h alu=%08h wb_data=%08h rd=x%0d",
    cycle,
    u_top.mem_wb_q.wb_sel,
    u_top.mem_wb_q.mem_data,
    u_top.mem_wb_q.alu_result,
    u_top.wb_data,
    u_top.mem_wb_q.rd_addr);
    end

endmodule