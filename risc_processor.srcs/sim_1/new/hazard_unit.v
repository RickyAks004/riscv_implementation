`timescale 1ns / 1ps
// Detect load-use hazard and stall; simple
module hazard_unit(
    input [4:0] id_rs1,
    input [4:0] id_rs2,
    input [4:0] ex_rd,
    input ex_mem_read,
    output reg stall,
    output reg pc_write,
    output reg if_id_write
);
    always @(*) begin
        // default: no stall
        stall = 0;
        pc_write = 1;
        if_id_write = 1;

        // load-use hazard: if EX is a load and its rd matches ID rs1/rs2, stall one cycle
        if (ex_mem_read && (ex_rd != 0) && ((ex_rd == id_rs1) || (ex_rd == id_rs2))) begin
            stall = 1;
            pc_write = 0;
            if_id_write = 0;
        end
    end
endmodule
