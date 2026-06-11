module test_example2;
    reg clk1, clk2;
    integer k;
    mips CPU (clk1, clk2);

    initial begin
        clk1 = 0; clk2 = 0;
        repeat (50) begin #5 clk1 = 1; #5 clk1 = 0; #5 clk2 = 1; #5 clk2 = 0; end
    end

    initial begin
       for (k=0; k<31; k=k+1)
            CPU.Reg[k] = k;

        CPU.Mem[0]   = 32'h28010078;    // ADDI   R1,R0,120
        CPU.Mem[1]   = 32'h0c631800;    // OR     R3,R3,R3  -- dummy instr.
        CPU.Mem[2]   = 32'h20220000;    // LW     R2,0(R1)
        CPU.Mem[3]   = 32'h0c631800;    // OR     R3,R3,R3  -- dummy instr.
        CPU.Mem[4]   = 32'h2842002d;    // ADDI   R2,R2,45
        CPU.Mem[5]   = 32'h0c631800;    // OR     R3,R3,R3  -- dummy instr.
        CPU.Mem[6]   = 32'h24220001;    // SW     R2,1(R1)
        CPU.Mem[7]   = 32'hfc000000;   // HLT

        CPU.Mem[120] = 85;
        CPU.PC = 0; CPU.halted = 0; CPU.taken_branch = 0;
        #500 $display ("Mem[120]: %4d \nMem[121]: %4d",CPU.Mem[120], CPU.Mem[121]); // expected [85,130]
    end

    initial begin
        $dumpfile("mips_ex2.vcd");
        $dumpvars(0, test_example2);

        #600 $finish;
    end
endmodule
