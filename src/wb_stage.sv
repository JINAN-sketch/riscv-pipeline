`timescale 1ns/1ps

module wb_stage
    import pipeline_pkg::*;
(
    // From MEM/WB register
    input  mem_wb_t     mem_wb,

    // Writeback outputs — fed back to register file in ID stage
    output logic [31:0] wb_data,      // value to write
    output logic [4:0]  wb_rd,        // destination register
    output logic        wb_reg_write  // 1 = perform the write
);

    // wb_sel encoding (set by control_unit):
    //   2'b00 → write memory read data  (load instructions)
    //   2'b01 → write ALU result        (R-type, I-type, AUIPC, LUI)
    //   2'b10 → write PC+4              (JAL, JALR link address)

    always_comb begin
        case (mem_wb.wb_sel)
            2'b00:   wb_data = mem_wb.mem_data;
            2'b01:   wb_data = mem_wb.alu_result;
            2'b10:   wb_data = mem_wb.pc_plus4;
            default: wb_data = mem_wb.alu_result;
        endcase
    end

    assign wb_rd       = mem_wb.rd_addr;
    assign wb_reg_write = mem_wb.reg_write;

endmodule