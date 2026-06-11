module test_example1;
    reg clk1, clk2;
    integer k;
    mips CPU (clk1, clk2);

    initial begin
        clk1 = 0; clk2 = 0;
        repeat (20) begin #5 clk1 = 1; #5 clk1 = 0; #5 clk2 = 1; #5 clk2 = 0; end
    end

    initial
    begin
        // Initialize registers: CPU.Reg[0]=0, CPU.Reg[1]=1, ..., CPU.Reg[30]=30
        for (k=0; k<31; k++)
            CPU.Reg[k] = k;

        // Load instructions into memory
        CPU.Mem[0] = 32'h2801000a;    // ADDI   R1, R0, 10
        CPU.Mem[1] = 32'h28020014;    // ADDI   R2, R0, 20
        CPU.Mem[2] = 32'h28030019;    // ADDI   R3, R0, 25
        CPU.Mem[3] = 32'h0ce77800;    // OR     R7, R7, R7  -- dummy instr.
        CPU.Mem[4] = 32'h0ce77800;    // OR     R7, R7, R7  -- dummy instr.
        CPU.Mem[5] = 32'h00222000;    // ADD    R4, R1, R2
        CPU.Mem[6] = 32'h0ce77800;    // OR     R7, R7, R7  -- dummy instr.
        CPU.Mem[7] = 32'h00832800;    // ADD    R5, R4, R3
        CPU.Mem[8] = 32'hfc000000;   // HLT
        
        CPU.halted = 0;
        CPU.PC = 0;
        CPU.taken_branch = 0;
        
        #280;
        // Wait for 280 time units for the program to finish running
        // Print out the final values of the registers using a display loop
        for (k=0; k<6; k++)
            $display("R%1d = %2d", k, CPU.Reg[k]);
    end

    initial begin
        // Waveform Addition for GTKWave [1]
        $dumpfile("mips_ex1.vcd");
        $dumpvars(0, test_example1);

        #300 $finish;
    end
endmodule
