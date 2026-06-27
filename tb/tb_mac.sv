`timescale 1ns/1ps

module tb_mac;

    logic        clk = 0;
    logic        rst;
    logic [1:0]  addr;
    logic [31:0] wdata;
    logic        we;
    logic [31:0] rdata;

    always #5 clk = ~clk;

    mac_unit u_mac (
        .clk   (clk),
        .rst   (rst),
        .addr  (addr),
        .wdata (wdata),
        .we    (we),
        .rdata (rdata)
    );

    // Helper — single register write
    task write_reg(input logic [1:0] a, input logic [31:0] d);
        @(posedge clk); #1;
        addr  = a;
        wdata = d;
        we    = 1;
        @(posedge clk); #1;
        we    = 0;
    endtask

    // Helper — single register read
    task read_reg(input logic [1:0] a, output logic [31:0] d);
        addr = a;
        we   = 0;
        #1;
        d = rdata;
    endtask

    task check(string name, logic [31:0] got, logic [31:0] expected);
        if (got !== expected)
            $display("FAIL %s | got=%08h expected=%08h", name, got, expected);
        else
            $display("PASS %s | result=%08h", name, got);
    endtask

    logic [31:0] result;

    initial begin
        rst = 1; addr = 0; wdata = 0; we = 0;
        repeat(4) @(posedge clk);
        rst = 0;

        // ── Test 1: single MAC — 3 × 4 = 12 ──────────────────────
        write_reg(2'b00, 32'd3);   // A = 3
        write_reg(2'b01, 32'd4);   // B = 4
        write_reg(2'b10, 32'd1);   // CTRL = 1 (trigger)
        read_reg(2'b11, result);
        check("3 x 4 = 12", result, 32'd12);

        // ── Test 2: accumulate — 3×4 + 5×6 = 12 + 30 = 42 ───────
        write_reg(2'b00, 32'd5);   // A = 5
        write_reg(2'b01, 32'd6);   // B = 6
        write_reg(2'b10, 32'd1);   // CTRL = 1 (accumulate)
        read_reg(2'b11, result);
        check("3x4 + 5x6 = 42", result, 32'd42);

        // ── Test 3: clear then fresh multiply — 7 × 8 = 56 ───────
        write_reg(2'b10, 32'd0);   // CTRL = 0 (clear)
        read_reg(2'b11, result);
        check("clear = 0", result, 32'd0);

        write_reg(2'b00, 32'd7);   // A = 7
        write_reg(2'b01, 32'd8);   // B = 8
        write_reg(2'b10, 32'd1);   // CTRL = 1 (trigger)
        read_reg(2'b11, result);
        check("7 x 8 = 56", result, 32'd56);

        // ── Test 4: dot product [1,2,3] · [4,5,6] = 4+10+18 = 32 ─
        write_reg(2'b10, 32'd0);   // clear first
        write_reg(2'b00, 32'd1); write_reg(2'b01, 32'd4); write_reg(2'b10, 32'd1);
        write_reg(2'b00, 32'd2); write_reg(2'b01, 32'd5); write_reg(2'b10, 32'd1);
        write_reg(2'b00, 32'd3); write_reg(2'b01, 32'd6); write_reg(2'b10, 32'd1);
        read_reg(2'b11, result);
        check("[1,2,3]·[4,5,6] = 32", result, 32'd32);

        $display("--- done ---");
        $finish;
    end

endmodule