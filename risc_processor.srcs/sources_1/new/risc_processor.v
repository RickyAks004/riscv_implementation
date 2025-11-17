`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.11.2025 23:35:15
// Design Name: 
// Module Name: risc_processor
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`define OP_R    7'b0110011
`define OP_I    7'b0010011
`define OP_LOAD 7'b0000011
`define OP_STORE 7'b0100011
`define OP_BRANCH 7'b1100011
`define OP_LUI 7'b0110111
`define OP_AUIPC 7'b0010111
`define OP_JAL 7'b1101111
`define OP_JALR 7'b1100111
`define OP_SYSTEM 7'b1110011
module risc_processor(
    input clk,
    input reset
);
    // Program Counter
    reg [31:0] pc;
    wire [31:0] instr_if;

    // Instruction memory
    instr_mem imem(.addr(pc), .instr(instr_if));

    // IF/ID pipeline register
    reg [31:0] if_id_pc;
    reg [31:0] if_id_instr;

    // ID signals
    wire [6:0] id_opcode = if_id_instr[6:0];
    wire [4:0] id_rs1 = if_id_instr[19:15];
    wire [4:0] id_rs2 = if_id_instr[24:20];
    wire [4:0] id_rd  = if_id_instr[11:7];
    wire [2:0] id_funct3 = if_id_instr[14:12];
    wire [6:0] id_funct7 = if_id_instr[31:25];

    // imm gen
    wire [31:0] id_imm_i, id_imm_s, id_imm_b, id_imm_u, id_imm_j;
    imm_gen ig(.instr(if_id_instr), .imm_i(id_imm_i), .imm_s(id_imm_s), .imm_b(id_imm_b), .imm_u(id_imm_u), .imm_j(id_imm_j));

    // control
    wire id_reg_write, id_mem_read, id_mem_write, id_branch, id_mem_to_reg, id_jal, id_jalr;
    wire [1:0] id_alu_src;
    wire [3:0] id_alu_op;
    control_unit cu(.opcode(id_opcode), .funct3(id_funct3), .funct7(id_funct7),
                    .reg_write(id_reg_write), .mem_read(id_mem_read), .mem_write(id_mem_write),
                    .branch(id_branch), .alu_src(id_alu_src), .mem_to_reg(id_mem_to_reg),
                    .alu_op(id_alu_op), .jal(id_jal), .jalr(id_jalr));

    // Register file (single instance with writeback control)
    reg wb_we;
    reg [4:0] wb_wa;
    reg [31:0] wb_wd;
    wire [31:0] rf_rd1, rf_rd2;

    regfile rf(.clk(clk), .we(wb_we), .ra1(id_rs1), .ra2(id_rs2), .wa(wb_wa), .wd(wb_wd), .rd1(rf_rd1), .rd2(rf_rd2));

    // ID/EX pipeline registers
    reg [31:0] id_ex_pc;
    reg [31:0] id_ex_rd1, id_ex_rd2;
    reg [31:0] id_ex_imm;
    reg [4:0] id_ex_rs1, id_ex_rs2, id_ex_rd;
    reg [6:0] id_ex_opcode;
    reg [2:0] id_ex_funct3;
    reg [6:0] id_ex_funct7;
    reg id_ex_reg_write, id_ex_mem_read, id_ex_mem_write, id_ex_branch, id_ex_mem_to_reg, id_ex_jal, id_ex_jalr;
    reg [1:0] id_ex_alu_src;
    reg [3:0] id_ex_alu_op;

    // EX stage signals
    wire [31:0] ex_alu_result;
    wire ex_zero;

    // Forwarding unit inputs
    wire [4:0] ex_rs1 = id_ex_rs1;
    wire [4:0] ex_rs2 = id_ex_rs2;

    // EX/MEM pipeline
    reg [31:0] ex_mem_alu_result;
    reg [31:0] ex_mem_write_data;
    reg [4:0] ex_mem_rd;
    reg ex_mem_reg_write, ex_mem_mem_read, ex_mem_mem_write, ex_mem_mem_to_reg;
    reg [31:0] ex_mem_pc;

    // MEM/WB pipeline
    reg [31:0] mem_wb_read_data;
    reg [31:0] mem_wb_alu_result;
    reg [4:0] mem_wb_rd;
    reg mem_wb_reg_write, mem_wb_mem_to_reg;

    // data memory
    wire [31:0] mem_read_data;
    data_mem dmem(.clk(clk), .mem_write(ex_mem_mem_write), .mem_read(ex_mem_mem_read),
                  .addr(ex_mem_alu_result), .write_data(ex_mem_write_data), .read_data(mem_read_data));

    // Hazard detection unit
    wire stall, pc_write, if_id_write;
    hazard_unit hz(.id_rs1(id_rs1), .id_rs2(id_rs2), .ex_rd(id_ex_rd), .ex_mem_read(id_ex_mem_read), .stall(stall), .pc_write(pc_write), .if_id_write(if_id_write));

    // Forwarding unit
    wire [1:0] forwardA, forwardB;
    forwarding_unit fu(.ex_rs1(ex_rs1), .ex_rs2(ex_rs2),
                       .mem_rd(ex_mem_rd), .mem_reg_write(ex_mem_reg_write),
                       .wb_rd(mem_wb_rd), .wb_reg_write(mem_wb_reg_write),
                       .forwardA(forwardA), .forwardB(forwardB));

    // ALU control and inputs
    // We'll use id_ex_alu_op to select operation; if more refinement needed use funct fields
    reg [3:0] alu_ctrl;
    always @(*) alu_ctrl = id_ex_alu_op;

    // ALU operand A: forwarded or from id_ex_rd1
    reg [31:0] alu_a;
    reg [31:0] alu_b;

    // ALU instance
    alu alu0(.a(alu_a), .b(alu_b), .alu_ctrl(alu_ctrl), .result(ex_alu_result), .zero(ex_zero));

    // PC update logic (simple): PC + 4, branches resolved in EX (compute branch target and take)
    wire [31:0] pc_plus4 = pc + 4;

    // Pipeline registers behavior
    integer i;
    reg [31:0] b_from_reg;
    // Reset and sequential pipeline update
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 0;
            if_id_pc <= 0;
            if_id_instr <= 32'b0;
            // flush pipeline regs
            id_ex_pc <= 0;
            id_ex_rd1 <= 0; id_ex_rd2 <= 0; id_ex_imm <= 0;
            id_ex_rs1 <= 0; id_ex_rs2 <= 0; id_ex_rd <= 0;
            id_ex_opcode <= 0; id_ex_funct3 <= 0; id_ex_funct7 <= 0;
            id_ex_reg_write <= 0; id_ex_mem_read <= 0; id_ex_mem_write <= 0; id_ex_branch <= 0; id_ex_mem_to_reg <= 0;
            id_ex_alu_src <= 0; id_ex_alu_op <= 0; id_ex_jal <= 0; id_ex_jalr <= 0;
            ex_mem_alu_result <= 0; ex_mem_write_data <= 0; ex_mem_rd <= 0;
            ex_mem_reg_write <= 0; ex_mem_mem_read <= 0; ex_mem_mem_write <= 0; ex_mem_mem_to_reg <= 0;
            mem_wb_read_data <= 0; mem_wb_alu_result <= 0; mem_wb_rd <= 0; mem_wb_reg_write <= 0; mem_wb_mem_to_reg <= 0;
            // regfile write control
            wb_we <= 0; wb_wa <= 0; wb_wd <= 0;
        end else begin
            // IF stage - update PC
            if (pc_write) pc <= pc_plus4;

            // IF/ID pipeline (with stall control)
            if (if_id_write) begin
                if_id_pc <= pc;
                if_id_instr <= instr_if;
            end else if (stall) begin
                // keep if_id registers unchanged to stall
                if_id_pc <= if_id_pc;
                if_id_instr <= if_id_instr;
            end

            // ID/EX pipeline update (if stall, insert bubble)
            if (stall) begin
                // insert bubble: clear control signals
                id_ex_pc <= 0;
                id_ex_rd1 <= 0; id_ex_rd2 <= 0; id_ex_imm <= 0;
                id_ex_rs1 <= 0; id_ex_rs2 <= 0; id_ex_rd <= 0;
                id_ex_opcode <= 0; id_ex_funct3 <= 0; id_ex_funct7 <= 0;
                id_ex_reg_write <= 0; id_ex_mem_read <= 0; id_ex_mem_write <= 0; id_ex_branch <= 0; id_ex_mem_to_reg <= 0;
                id_ex_alu_src <= 0; id_ex_alu_op <= 0; id_ex_jal <= 0; id_ex_jalr <= 0;
            end else begin
                id_ex_pc <= if_id_pc;
                id_ex_rd1 <= rf_rd1;
                id_ex_rd2 <= rf_rd2;
                // Choose immediate according to alu_src: we'll store selected imm in id_ex_imm
                case (id_alu_src)
                    2'b00: id_ex_imm <= 32'b0;
                    2'b01: id_ex_imm <= id_imm_i;
                    2'b10: id_ex_imm <= id_imm_s;
                    2'b11: id_ex_imm <= id_imm_u; // used for LUI/AUIPC (approx)
                    default: id_ex_imm <= 32'b0;
                endcase
                id_ex_rs1 <= id_rs1;
                id_ex_rs2 <= id_rs2;
                id_ex_rd <= id_rd;
                id_ex_opcode <= id_opcode;
                id_ex_funct3 <= id_funct3;
                id_ex_funct7 <= id_funct7;
                id_ex_reg_write <= id_reg_write;
                id_ex_mem_read <= id_mem_read;
                id_ex_mem_write <= id_mem_write;
                id_ex_branch <= id_branch;
                id_ex_mem_to_reg <= id_mem_to_reg;
                id_ex_alu_src <= id_alu_src;
                id_ex_alu_op <= id_alu_op;
                id_ex_jal <= id_jal;
                id_ex_jalr <= id_jalr;
            end

            // EX stage: compute ALU inputs with forwarding
            // forwarding mux for A
            case (forwardA)
                2'b00: alu_a <= id_ex_rd1;
                2'b10: alu_a <= ex_mem_alu_result;
                2'b01: alu_a <= (mem_wb_mem_to_reg ? mem_wb_read_data : mem_wb_alu_result);
                default: alu_a <= id_ex_rd1;
            endcase

            // B input depends on alu_src: choose imm or forwarded register data
            case (forwardB)
                2'b00: b_from_reg <= id_ex_rd2;
                2'b10: b_from_reg <= ex_mem_alu_result;
                2'b01: b_from_reg <= (mem_wb_mem_to_reg ? mem_wb_read_data : mem_wb_alu_result);
                default: b_from_reg <= id_ex_rd2;
            endcase

            if (id_ex_alu_src == 2'b00)
                alu_b <= b_from_reg;
            else if (id_ex_alu_src == 2'b01 || id_ex_alu_src == 2'b10)
                alu_b <= id_ex_imm;
            else if (id_ex_alu_src == 2'b11)
                alu_b <= id_ex_imm;

            // EX/MEM pipeline update
            ex_mem_alu_result <= ex_alu_result;
            ex_mem_write_data <= b_from_reg;
            ex_mem_rd <= id_ex_rd;
            ex_mem_reg_write <= id_ex_reg_write;
            ex_mem_mem_read <= id_ex_mem_read;
            ex_mem_mem_write <= id_ex_mem_write;
            ex_mem_mem_to_reg <= id_ex_mem_to_reg;
            ex_mem_pc <= id_ex_pc;

            // MEM stage: data memory access already done combinationally via dmem outputs
            // Capture memory output into pipeline
            mem_wb_read_data <= mem_read_data;
            mem_wb_alu_result <= ex_mem_alu_result;
            mem_wb_rd <= ex_mem_rd;
            mem_wb_reg_write <= ex_mem_reg_write;
            mem_wb_mem_to_reg <= ex_mem_mem_to_reg;

            // WB stage: perform write-back to register file
            wb_we <= mem_wb_reg_write;
            wb_wa <= mem_wb_rd;
            wb_wd <= (mem_wb_mem_to_reg ? mem_wb_read_data : mem_wb_alu_result);
        end
    end
endmodule
