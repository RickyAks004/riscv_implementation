`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.11.2025 23:40:33
// Design Name: 
// Module Name: regfile
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


// 32x32 register file, x0 hardwired to 0
module regfile(
    input clk,
    input we,
    input [4:0] ra1,
    input [4:0] ra2,
    input [4:0] wa,
    input [31:0] wd,
    output [31:0] rd1,
    output [31:0] rd2
);
    reg [31:0] regs [0:31];
    integer i;
    initial begin
        for (i=0;i<32;i=i+1) regs[i]=32'b0;
    end

    // read
    assign rd1 = (ra1==0)? 32'b0 : regs[ra1];
    assign rd2 = (ra2==0)? 32'b0 : regs[ra2];

    // write (on posedge)
    always @(posedge clk) begin
        if (we && wa != 0) regs[wa] <= wd;
    end
endmodule

