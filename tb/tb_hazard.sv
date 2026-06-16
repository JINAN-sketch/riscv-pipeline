`timescale 1ns/1ps

module tb_hazard;

    logic        id_ex_mem_read;
    logic [4:0]  id_ex_rd_addr;
    logic [4:0]  if_id_rs1_addr, if_id_rs2_addr;
    logic        branch_taken;
    logic        pc_write, if_id_write, if_id_flush, id_ex_flush;

    hazard_unit u_haz (
        .id_ex_mem_read (id_ex_mem_read),
        .id_ex_rd_addr  (id_ex_rd_addr),
        .if_id_rs1_addr (if_id_rs1_addr),
        .if_id_rs2_addr (if_id_rs2_addr),
        .branch_taken   (branch_taken),
        .pc_write       (pc_write),
        .if_id_write    (if_id_write),
        .if_id_flush    (if_id_flush),
        .id_ex_flush    (id_ex_flush)
    );

    task check(string name, logic exp_pcw, logic exp_ifidw, logic exp_ifidf, logic exp_idexf);
        #1;
        if (pc_write!==exp_pcw || if_id_write!==exp_ifidw || if_id_flush!==exp_ifidf || id_ex_flush!==exp_idexf)
            $display("FAIL %-20s | pcw=%b ifidw=%b ifidf=%b idexf=%b (expected %b %b %b %b)",
                name, pc_write, if_id_write, if_id_flush, id_ex_flush, exp_pcw, exp_ifidw, exp_ifidf, exp_idexf);
        else
            $display("PASS %-20s | pcw=%b ifidw=%b ifidf=%b idexf=%b", name, pc_write, if_id_write, if_id_flush, id_ex_flush);
    endtask

    initial begin
        // Normal operation — no hazard
        id_ex_mem_read=0; id_ex_rd_addr=5'd0; if_id_rs1_addr=5'd1; if_id_rs2_addr=5'd2; branch_taken=0;
        check("normal", 1, 1, 0, 0);

        // Load-use hazard on rs1
        id_ex_mem_read=1; id_ex_rd_addr=5'd1; if_id_rs1_addr=5'd1; if_id_rs2_addr=5'd2; branch_taken=0;
        check("load-use rs1", 0, 0, 0, 1);

        // Load-use hazard on rs2
        id_ex_mem_read=1; id_ex_rd_addr=5'd2; if_id_rs1_addr=5'd1; if_id_rs2_addr=5'd2; branch_taken=0;
        check("load-use rs2", 0, 0, 0, 1);

        // Load but no dependency — no stall
        id_ex_mem_read=1; id_ex_rd_addr=5'd9; if_id_rs1_addr=5'd1; if_id_rs2_addr=5'd2; branch_taken=0;
        check("load no dependency", 1, 1, 0, 0);

        // Load writing to x0 — never stalls
        id_ex_mem_read=1; id_ex_rd_addr=5'd0; if_id_rs1_addr=5'd0; if_id_rs2_addr=5'd0; branch_taken=0;
        check("load to x0 no stall", 1, 1, 0, 0);

        // Branch taken — flush IF/ID
        id_ex_mem_read=0; id_ex_rd_addr=5'd0; if_id_rs1_addr=5'd1; if_id_rs2_addr=5'd2; branch_taken=1;
        check("branch taken", 1, 1, 1, 0);

        $display("--- done ---");
        $finish;
    end

endmodule