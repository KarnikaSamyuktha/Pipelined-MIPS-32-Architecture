module test_example3;
    reg clk1, clk2;
    integer k;
    mips CPU (clk1, clk2);

    initial begin
        clk1 = 0; clk2 = 0;
        repeat (50) begin #5 clk1 = 1; #5 clk1 = 0; #5 clk2 = 1; #5 clk2 = 0; end
    end

    initial begin
        for (k=0;k<31;k=k+1)
            CPU.Reg[k]=k;

        CPU.Mem[0]  = 32'h280a00c8;    // ADDI   R10,R0,200
        CPU.Mem[1]  = 32'h28020001;    // ADDI   R2,R0,1
        CPU.Mem[2]  = 32'h0e94a000;    // OR     R20,R20,R20 -- dummy instr.
        CPU.Mem[3]  = 32'h21430000;    // LW     R3,0(R10)
        CPU.Mem[4]  = 32'h0e94a000;    // OR     R20,R20,R20 -- dummy instr.
        CPU.Mem[5]  = 32'h14431000;    // Loop:  MUL    R2,R2,R3
        CPU.Mem[6]  = 32'h2c630001;    // SUBI   R3,R3,1
        CPU.Mem[7]  = 32'h0e94a000;    // OR     R20,R20,R20 -- dummy instr.
        CPU.Mem[8]  = 32'h3460fffc;    // BNEQZ  R3,Loop (i.e. -4 offset)
        CPU.Mem[9]  = 32'h2542fffe;    // SW     R2,-2(R10)
        CPU.Mem[10] = 32'hfc000000;   // HLT
        /*While BNEQZ is being decoded in the pipeline, the IF Stage has already advanced the program counter. 
        Therefore, IF_ID_NPC (which becomes ID_EX_NPC) is already equal to 9
        target address= 5 =ID_EX_NPC + Offset => Offset=-4 */

        CPU.Mem[200] = 7; 
        CPU.PC = 0; CPU.halted = 0; CPU.taken_branch = 0;

        #2000 $display ("Mem[200] = %2d \nMem[198] = %6d",CPU.Mem[200],CPU.Mem[198]);// expected [7,5040]
    end

    initial begin
        $dumpfile("mips_ex3.vcd");
        $dumpvars(0, test_example3);
        $monitor ("R2: %6d",CPU.Reg[2]);
        #3000 $finish;
    end
endmodule
