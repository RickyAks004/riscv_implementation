`timescale 1ns / 1ps
// Simple instruction memory, word addressed by PC>>2, size 1024 words (4KB)
module instr_mem(
    input [31:0] addr,
    output [31:0] instr
);
    reg [31:0] imem [0:1023];
    initial begin
        // read instruction memory file (hex). Provide program.mem in project.
        $readmemh("program.mem", imem);
    end
    assign instr = imem[addr[11:2]]; // word addressed
endmodule
