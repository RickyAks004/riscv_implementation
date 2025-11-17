# 🚀 5-Stage Pipelined RISC-V Processor (RV32I)
**A fully modular RV32I CPU core implemented in Verilog with pipelining, hazard detection, forwarding, testbenches, and Vivado simulation support.**

---

## 📌 Features
- ✔ **5-Stage Pipeline:** IF → ID → EX → MEM → WB  
- ✔ **Hazard Detection Unit:** Load-use stall detection  
- ✔ **Forwarding Unit:** Resolves EX/MEM and MEM/WB data hazards  
- ✔ **Modular Components:** ALU, Register File, ImmGen, Control Unit, Memories  
- ✔ **Self-Checking Testbench:** Program loading + memory preload + waveform dumping  
- ✔ **Runs on Xilinx Vivado:** Synthesis + simulation compatible  
- ✔ **GTKWave Support:** Auto-generated `.vcd` waveform traces  

---

## 🏗 Project Structure
``` bash
/src
├── alu.v
├── control.v
├── regfile.v
├── imm_gen.v
├── instr_mem.v
├── data_mem.v
├── hazard_unit.v
├── forwarding_unit.v
├── risc_processor.v <-- Top-level Pipelined RV32I Core
/testbench
├── tb_riscv.v <-- Advanced testbench
├── program.hex
├── data.hex

```

🧪 Testbench Overview

The testbench supports:

* 🔹 Automatic program loading (program.hex)
* 🔹 Data memory initialization (data.hex)
* 🔹 Register writeback monitoring
* 🔹 Pipeline stage logging (IF/ID, ID/EX, EX/MEM, MEM/WB)
* 🔹 VCD dump generation for GTKWave

Sample log output
``` bash
PC=00000024 | IF/ID instr=0020A023 | EX/MEM ALU=00000010 | WB rd=5 data=00000010
[RF] x5 <- 00000010
```

🧠 Architecture Diagram

``` bash
           ┌──────────┐
           │  IF Stage │
           └─────┬────┘
                 ▼
           ┌──────────┐
           │  ID Stage │-- Hazard Detection
           └─────┬────┘
                 ▼
           ┌──────────┐
           │  EX Stage │-- ALU + Forwarding
           └─────┬────┘
                 ▼
           ┌──────────┐
           │ MEM Stage │
           └─────┬────┘
                 ▼
           ┌──────────┐
           │ WB Stage  │-- Register File Writeback
           └──────────┘
```

📄 Example Program (program.hex)

``` bash
00000093   // addi x1, x0, 0
00108113   // addi x2, x1, 1
00210193   // addi x3, x2, 2
00318213   // addi x4, x3, 3
```
🗂 Memory Initialization (data.hex)

``` bash
00000000
00000000
00000000
00000000
```

🧩 Future Improvements

* 🔧 Add support for branch prediction
* 🔧 Implement full RV32IM extensions
* 🔧 Replace simple memory with AXI interface
* 🔧 FPGA deployment (Basys3 / Nexys A7)
