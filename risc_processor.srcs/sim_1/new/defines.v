`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.11.2025 23:37:18
// Design Name: 
// Module Name: defines
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


// Simple RISC-V field defines
`ifndef DEFINES_V
`define DEFINES_V

// Opcodes
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

`endif

