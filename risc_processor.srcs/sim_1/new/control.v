`timescale 1ns / 1ps
`include "defines.v"
module control_unit(
    input [6:0] opcode,
    input [2:0] funct3,
    input [6:0] funct7,
    output reg reg_write,
    output reg mem_read,
    output reg mem_write,
    output reg branch,
    output reg [1:0] alu_src, // 0 = reg, 1 = imm (I), 2 = imm (S), 3 = imm (U/J)
    output reg mem_to_reg,
    output reg [3:0] alu_op, // internal ALU control better resolved in ALU control
    output reg jal,
    output reg jalr
);
    always @(*) begin
        // defaults
        reg_write = 0;
        mem_read = 0;
        mem_write = 0;
        branch = 0;
        alu_src = 0;
        mem_to_reg = 0;
        alu_op = 4'b0000;
        jal = 0;
        jalr = 0;

        case (opcode)
            `OP_R: begin
                reg_write = 1;
                alu_src = 0;
                // determine ALU op from funct3/funct7 later in ALU control unit, but we'll approximate
                // We'll pass full funct fields to EX stage; for simplicity map to add/sub/slt/and/or
                if (funct3 == 3'b000 && funct7 == 7'b0100000) alu_op = 4'b0001; // SUB
                else if (funct3 == 3'b000) alu_op = 4'b0000; // ADD
                else if (funct3 == 3'b010) alu_op = 4'b0010; // SLT
                else if (funct3 == 3'b111) alu_op = 4'b0100; // AND
                else if (funct3 == 3'b110) alu_op = 4'b0101; // OR
                else if (funct3 == 3'b100) alu_op = 4'b0110; // XOR
                else if (funct3 == 3'b001) alu_op = 4'b0111; // SLL
                else if (funct3 == 3'b101 && funct7 == 7'b0100000) alu_op = 4'b1001; // SRA
                else if (funct3 == 3'b101) alu_op = 4'b1000; // SRL
            end
            `OP_I: begin
                reg_write = 1;
                alu_src = 1;
                // approximate: ADDI and other immediate ops
                if (funct3 == 3'b000) alu_op = 4'b0000; // ADDI
                else if (funct3 == 3'b010) alu_op = 4'b0010; // SLTI
                else if (funct3 == 3'b111) alu_op = 4'b0100; // ANDI
                else if (funct3 == 3'b110) alu_op = 4'b0101; // ORI
            end
            `OP_LOAD: begin
                reg_write = 1;
                mem_read = 1;
                mem_to_reg = 1;
                alu_src = 1;
                alu_op = 4'b0000; // ADD for address calc
            end
            `OP_STORE: begin
                mem_write = 1;
                alu_src = 2; // S-type immediate
                alu_op = 4'b0000; // ADD for address calc
            end
            `OP_BRANCH: begin
                branch = 1;
                alu_src = 0;
                alu_op = 4'b0001; // SUB to compare
            end
            `OP_LUI: begin
                reg_write = 1;
                alu_src = 3;
                alu_op = 4'b0000;
            end
            `OP_AUIPC: begin
                reg_write = 1;
                alu_src = 3;
                alu_op = 4'b0000;
            end
            `OP_JAL: begin
                reg_write = 1;
                jal = 1;
                alu_src = 0;
            end
            `OP_JALR: begin
                reg_write = 1;
                jalr = 1;
                alu_src = 1;
            end
            default: begin end
        endcase
    end
endmodule
