`timescale 1ns / 1ps
// Determine forwarding to EX stage operands
module forwarding_unit(
    input [4:0] ex_rs1,
    input [4:0] ex_rs2,
    input [4:0] mem_rd,
    input mem_reg_write,
    input [4:0] wb_rd,
    input wb_reg_write,
    output reg [1:0] forwardA, // 00 = from reg, 10 = from MEM, 01 = from WB
    output reg [1:0] forwardB
);
    always @(*) begin
        // default
        forwardA = 2'b00;
        forwardB = 2'b00;

        // EX hazard: MEM stage
        if (mem_reg_write && (mem_rd != 0) && (mem_rd == ex_rs1)) forwardA = 2'b10;
        if (mem_reg_write && (mem_rd != 0) && (mem_rd == ex_rs2)) forwardB = 2'b10;

        // WB hazard: WB stage
        if (wb_reg_write && (wb_rd != 0) && !(mem_reg_write && (mem_rd != 0) && (mem_rd == ex_rs1)) && (wb_rd == ex_rs1)) forwardA = 2'b01;
        if (wb_reg_write && (wb_rd != 0) && !(mem_reg_write && (mem_rd != 0) && (mem_rd == ex_rs2)) && (wb_rd == ex_rs2)) forwardB = 2'b01;
    end
endmodule
