`timescale 1ns/1ps

module tb_forwarding;

    logic [4:0] id_ex_rs1, id_ex_rs2;
    logic [4:0] ex_mem_rd;
    logic       ex_mem_rw;
    logic [4:0] mem_wb_rd;
    logic       mem_wb_rw;
    logic [1:0] fwd_a, fwd_b;

    forwarding_unit u_fwd (
        .id_ex_rs1_addr   (id_ex_rs1),
        .id_ex_rs2_addr   (id_ex_rs2),
        .ex_mem_rd_addr   (ex_mem_rd),
        .ex_mem_reg_write (ex_mem_rw),
        .mem_wb_rd_addr   (mem_wb_rd),
        .mem_wb_reg_write (mem_wb_rw),
        .fwd_a            (fwd_a),
        .fwd_b            (fwd_b)
    );

    task check(string name, logic [1:0] exp_a, logic [1:0] exp_b);
        #1;
        if (fwd_a !== exp_a || fwd_b !== exp_b)
            $display("FAIL %-20s | fwd_a=%02b (exp %02b)  fwd_b=%02b (exp %02b)", name, fwd_a, exp_a, fwd_b, exp_b);
        else
            $display("PASS %-20s | fwd_a=%02b  fwd_b=%02b", name, fwd_a, fwd_b);
    endtask

    initial begin
        // No hazard — different registers
        id_ex_rs1=5'd1; id_ex_rs2=5'd2; ex_mem_rd=5'd3; ex_mem_rw=1; mem_wb_rd=5'd4; mem_wb_rw=1;
        check("no hazard", 2'b00, 2'b00);

        // EX hazard on rs1 only
        id_ex_rs1=5'd3; id_ex_rs2=5'd2; ex_mem_rd=5'd3; ex_mem_rw=1; mem_wb_rd=5'd4; mem_wb_rw=1;
        check("EX hazard rs1", 2'b01, 2'b00);

        // EX hazard on rs2 only
        id_ex_rs1=5'd1; id_ex_rs2=5'd3; ex_mem_rd=5'd3; ex_mem_rw=1; mem_wb_rd=5'd4; mem_wb_rw=1;
        check("EX hazard rs2", 2'b00, 2'b01);

        // EX hazard on both
        id_ex_rs1=5'd3; id_ex_rs2=5'd3; ex_mem_rd=5'd3; ex_mem_rw=1; mem_wb_rd=5'd4; mem_wb_rw=1;
        check("EX hazard both", 2'b01, 2'b01);

        // MEM hazard on rs1 only (no EX hazard)
        id_ex_rs1=5'd4; id_ex_rs2=5'd2; ex_mem_rd=5'd3; ex_mem_rw=1; mem_wb_rd=5'd4; mem_wb_rw=1;
        check("MEM hazard rs1", 2'b10, 2'b00);

        // EX hazard takes priority over MEM hazard (same target register)
        id_ex_rs1=5'd3; id_ex_rs2=5'd2; ex_mem_rd=5'd3; ex_mem_rw=1; mem_wb_rd=5'd3; mem_wb_rw=1;
        check("EX priority over MEM", 2'b01, 2'b00);

        // x0 never forwarded even if rd matches
        id_ex_rs1=5'd0; id_ex_rs2=5'd2; ex_mem_rd=5'd0; ex_mem_rw=1; mem_wb_rd=5'd4; mem_wb_rw=1;
        check("x0 never forwarded", 2'b00, 2'b00);

        // reg_write=0 means no forward even if rd matches
        id_ex_rs1=5'd3; id_ex_rs2=5'd2; ex_mem_rd=5'd3; ex_mem_rw=0; mem_wb_rd=5'd4; mem_wb_rw=1;
        check("reg_write=0 blocks fwd", 2'b00, 2'b00);

        $display("--- done ---");
        $finish;
    end

endmodule