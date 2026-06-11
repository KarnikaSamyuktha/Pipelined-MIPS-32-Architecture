# Pipelined MIPS-32 RISC Processor

## Project Overview
* Designed a MIPS RISC processor in Verilog at the Register Transfer Level (RTL), implementing a functional subset of the instruction set within a 5-stage pipeline.
* Built the hardware data path including a 32-word register file, a 1024-word memory array, an integer ALU, and pipeline registers synchronized by a two-phase clock.
* Wrote control logic for instruction decoding, 16-bit sign-extension, and branch execution, while manually adding dummy instructions in assembly to prevent data hazards.
* Executed the design verification (DV) flow using Icarus Verilog and GTKWave to successfully validate pipeline outputs and monitor register values across multiple testbenches.

## Tools & Technologies
* **Language:** Verilog HDL
* **Methodology:** Register Transfer Level (RTL) Design & Design Verification (DV)
* **Simulation Toolchain:** Icarus Verilog (`iverilog`, `vvp`)
* **Waveform Viewer:** GTKWave

### 5-Stage Pipeline Block 
The core is designed using a structural hardware approach dividing data processing into five distinct, synchronous stages:
1. **Instruction Fetch (IF):** Accesses the 1024-word memory array using the Program Counter (PC) and computes the Next PC (NPC). Handles hardware-level instruction hijacking during taken branches.
2. **Instruction Decode (ID):** Performs parallel dual-register file fetches (with register `R0` hardwired to zero) and extracts immediate values via 16-bit sign-extension logic. Decodes instructions into microarchitectural execution types.
3. **Execute (EX):** Utilizes an integer Arithmetic Logic Unit (ALU) to calculate branch target offsets, generate memory addresses, and perform rapid arithmetic/logical transformations.
4. **Memory Access (MEM):** Interacts with the data memory partition for `LW` (Load Word) and `SW` (Store Word) operations. 
5. **Write Back (WB):** Commits completed ALU results or loaded memory data directly back into the 32×32-bit destination register file.

### Custom Instruction Subset Supported
* **Register-Register ALU (R-Type):** `ADD`, `SUB`, `AND`, `OR`, `SLT`, `MUL`
* **Register-Immediate ALU (I-Type):** `ADDI`, `SUBI`, `SLTI`
* **Memory Reference:** `LW` (Load Word), `SW` (Store Word)
* **Control Flow:** `BEQZ` (Branch if Equal to Zero), `BNEQZ` (Branch if Not Equal to Zero), `HLT` (Halt Execution)
  
### Pipeline Synchronization & Hazard Resolution
* **Two-Phase Clocking:** The pipeline utilizes split-phase clock edges (`clk1` and `clk2`) to execute separate pipeline halves within a single instruction cycle, fundamentally shifting data dependency timing.
* **RAW Hazard Mitigation:** To maintain structural functionality without hardware forwarding logic, Read-After-Write (RAW) data hazards are cleanly bypassed via software-level NOP integration,through manual insertion of non-modifying assembly-level dummy instructions within test program.
