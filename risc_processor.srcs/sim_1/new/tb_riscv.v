`timescale 1ns/1ps
module tb_riscv;
    reg clk;
    reg reset;

    // instantiate core
    risc_processor core(.clk(clk), .reset(reset));

    // clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz ~ 10ns period; here 10ns period -> 100MHz
    end

    initial begin
        reset = 1;
        #20;
        reset = 0;
        // run some cycles
        #2000;
        $display("Simulation done");
        $finish;
    end

    // optional waveform
    initial begin
        $dumpfile("riscv.vcd");
        $dumpvars(0, tb_riscv);
    end
endmodule
