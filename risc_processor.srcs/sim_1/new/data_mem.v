`timescale 1ns / 1ps
// Simple data memory (byte-addressable) with word reads/writes (aligned)
module data_mem(
    input clk,
    input mem_write,
    input mem_read,
    input [31:0] addr,
    input [31:0] write_data,
    output reg [31:0] read_data
);
    reg [7:0] dmem [0:4095]; // 4KB
    integer i;
    initial begin
        for (i=0;i<4096;i=i+1) dmem[i]=8'b0;
    end

    always @(posedge clk) begin
        if (mem_write) begin
            // store word (little endian)
            dmem[addr + 0] <= write_data[7:0];
            dmem[addr + 1] <= write_data[15:8];
            dmem[addr + 2] <= write_data[23:16];
            dmem[addr + 3] <= write_data[31:24];
        end
    end

    always @(*) begin
        if (mem_read) begin
            read_data = {dmem[addr+3], dmem[addr+2], dmem[addr+1], dmem[addr+0]};
        end else read_data = 32'b0;
    end
endmodule
