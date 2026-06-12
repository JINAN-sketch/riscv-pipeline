`timescale 1ns/1ps

module tb_alu;

    logic [31:0] a, b;
    logic [3:0]  alu_op;
    logic [31:0] result;
    logic        zero;

    alu u_alu (.a(a), .b(b), .alu_op(alu_op), .result(result), .zero(zero));

    task check(
        input logic [31:0] ta, tb_val,
        input logic [3:0]  op,
        input logic [31:0] expected,
        input string       name
    );
        a = ta; b = tb_val; alu_op = op;
        #1;
        if (result !== expected)
            $display("FAIL %-6s | a=%08h b=%08h | got=%08h expected=%08h", name, ta, tb_val, result, expected);
        else
            $display("PASS %-6s | result=%08h zero=%b", name, result, zero);
    endtask

    initial begin
        $display("--- ALU test ---");

        // ADD
        check(32'h5, 32'h3,  4'b0000, 32'h8,          "ADD");
        // SUB
        check(32'h5, 32'h3,  4'b0001, 32'h2,          "SUB");
        // SLL
        check(32'h1, 32'h4,  4'b0010, 32'h10,         "SLL");
        // SLT signed: -1 < 1 = true
        check(32'hFFFFFFFF, 32'h1, 4'b0011, 32'h1,    "SLT");
        // SLTU unsigned: 0xFFFFFFFF > 1 = false
        check(32'hFFFFFFFF, 32'h1, 4'b0100, 32'h0,    "SLTU");
        // XOR
        check(32'hF0F0F0F0, 32'h0F0F0F0F, 4'b0101, 32'hFFFFFFFF, "XOR");
        // SRL
        check(32'h80000000, 32'h1, 4'b0110, 32'h40000000, "SRL");
        // SRA — sign bit should replicate
        check(32'h80000000, 32'h1, 4'b0111, 32'hC0000000, "SRA");
        // OR
        check(32'hF0F0F0F0, 32'h0F0F0F0F, 4'b1000, 32'hFFFFFFFF, "OR");
        // AND
        check(32'hFFFFFFFF, 32'h0F0F0F0F, 4'b1001, 32'h0F0F0F0F, "AND");
        // LUI pass-through
        check(32'h0, 32'h12345000, 4'b1010, 32'h12345000, "LUI");
        // zero flag
        check(32'h5, 32'h5, 4'b0001, 32'h0, "ZERO");

        $display("--- done ---");
        $finish;
    end

endmodule