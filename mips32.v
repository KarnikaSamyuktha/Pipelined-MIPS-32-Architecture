module mips (input clk1, clk2);
    // Program Counter and Pipeline Latches
    reg [31:0] PC, IF_ID_IR, IF_ID_NPC;
    reg [31:0] ID_EX_IR, ID_EX_NPC, ID_EX_A, ID_EX_B, ID_EX_IMM;
    reg [2:0]  ID_EX_type, EX_MEM_type, MEM_WB_type;
    reg [31:0] EX_MEM_IR, EX_MEM_ALUOUT, EX_MEM_B;
    reg        EX_MEM_cond;
    reg [31:0] MEM_WB_IR, MEM_WB_ALUOUT, MEM_WB_LMD;

    // Register Bank and Memory
    reg [31:0] Reg [0:31];      // 32 registers of 32 bits 
    reg [31:0] Mem [0:1023];    // 1024 words of 32 bits 

    // Instruction Type Parameters 
    parameter RR_ALU = 3'b000, RM_ALU = 3'b001, LOAD = 3'b010, 
              STORE = 3'b011, BRANCH = 3'b100, HALT = 3'b101;

    // Opcode Parameters
    parameter ADD = 6'h0, SUB = 6'h1, AND = 6'h2, OR = 6'h3, 
              SLT = 6'h4, MUL = 6'h5, HLT = 6'h3f, LW = 6'h8, 
              SW = 6'h9, ADDI = 6'ha, SUBI = 6'hb, SLTI = 6'hc, 
              BNEQZ = 6'hd, BEQZ = 6'he;

    reg halted, taken_branch; // Control flags

    // --- IF Stage (Clock 1) --- 
    always @(posedge clk1) begin
        if (halted == 0) begin
            if (((EX_MEM_IR[31:26] == BEQZ) && (EX_MEM_cond == 1)) ||
                ((EX_MEM_IR[31:26] == BNEQZ) && (EX_MEM_cond == 0))) begin
                IF_ID_IR     <= #2 Mem[EX_MEM_ALUOUT];
                taken_branch <= #2 1'b1;
                IF_ID_NPC    <= #2 EX_MEM_ALUOUT + 1;
                PC           <= #2 EX_MEM_ALUOUT + 1;
            end else begin
                IF_ID_IR     <= #2 Mem[PC];
                IF_ID_NPC    <= #2 PC + 1;
                PC           <= #2 PC + 1;
            end
        end
    end

    // --- ID Stage (Clock 2) --- 
    always @(posedge clk2) begin
        if (halted == 0) begin
            // Register Fetch with R0 hardwired to 0 
            ID_EX_A <= #2 (IF_ID_IR[25:21] == 0) ? 0 : Reg[IF_ID_IR[25:21]];
            ID_EX_B <= #2 (IF_ID_IR[20:16] == 0) ? 0 : Reg[IF_ID_IR[20:16]];

            ID_EX_NPC <= #2 IF_ID_NPC;
            ID_EX_IR  <= #2 IF_ID_IR;
            // Sign Extension 
            ID_EX_IMM <= #2 {{16{IF_ID_IR[15]}}, IF_ID_IR[15:0]};

            // Type Decoding 
            case (IF_ID_IR[31:26])
                ADD, SUB, AND, OR, SLT, MUL: ID_EX_type <= #2 RR_ALU;
                ADDI, SUBI, SLTI:            ID_EX_type <= #2 RM_ALU;
                LW:                          ID_EX_type <= #2 LOAD;
                SW:                          ID_EX_type <= #2 STORE;
                BNEQZ, BEQZ:                 ID_EX_type <= #2 BRANCH;
                HLT:                         ID_EX_type <= #2 HALT;
                default:                     ID_EX_type <= #2 HALT;
            endcase
        end
    end

    // --- EX Stage (Clock 1) --- 
    always @(posedge clk1) begin
        if (halted == 0) begin
            EX_MEM_type  <= #2 ID_EX_type;
            EX_MEM_IR    <= #2 ID_EX_IR;
            //taken_branch <= #2 1'b0;

            case (ID_EX_type)
                RR_ALU: begin
                    case (ID_EX_IR[31:26])
                        ADD: EX_MEM_ALUOUT <= #2 ID_EX_A + ID_EX_B;
                        SUB: EX_MEM_ALUOUT <= #2 ID_EX_A - ID_EX_B;
                        AND: EX_MEM_ALUOUT <= #2 ID_EX_A & ID_EX_B;
                        OR:  EX_MEM_ALUOUT <= #2 ID_EX_A | ID_EX_B;
                        SLT: EX_MEM_ALUOUT <= #2 ID_EX_A < ID_EX_B;
                        MUL: EX_MEM_ALUOUT <= #2 ID_EX_A * ID_EX_B;
                        default: EX_MEM_ALUOUT <= #2 32'hxxxxxxxx;
                    endcase
                end
                RM_ALU: begin
                    case (ID_EX_IR[31:26])
                        ADDI: EX_MEM_ALUOUT <= #2 ID_EX_A + ID_EX_IMM;
                        SUBI: EX_MEM_ALUOUT <= #2 ID_EX_A - ID_EX_IMM;
                        SLTI: EX_MEM_ALUOUT <= #2 ID_EX_A < ID_EX_IMM;
                        default: EX_MEM_ALUOUT <= #2 32'hxxxxxxxx;
                    endcase
                end
                LOAD, STORE: begin
                    EX_MEM_ALUOUT <= #2 ID_EX_A + ID_EX_IMM;
                    EX_MEM_B      <= #2 ID_EX_B;
                end
                BRANCH: begin
                    EX_MEM_ALUOUT <= #2 ID_EX_NPC + ID_EX_IMM;
                    EX_MEM_cond   <= #2 (ID_EX_A == 0);
                end
            endcase
        end
    end

    // --- MEM Stage (Clock 2) --- 
    always @(posedge clk2) begin
        if (halted == 0) begin
            MEM_WB_type <= #2 EX_MEM_type;
            MEM_WB_IR   <= #2 EX_MEM_IR;
            taken_branch <= #2 1'b0;
            /* By resetting it to 0 during clk2, 
            you are telling the CPU: "The branch layout adjustment is finished. 
            Go back to executing regular instructions normally." */

            case (EX_MEM_type)
                RR_ALU, RM_ALU: MEM_WB_ALUOUT <= #2 EX_MEM_ALUOUT;
                LOAD:           MEM_WB_LMD    <= #2 Mem[EX_MEM_ALUOUT];
                STORE:          if (taken_branch == 0) 
                                   Mem[EX_MEM_ALUOUT] <= #2 EX_MEM_B;
            endcase
        end
    end

    // --- WB Stage (Clock 1) --- 
    always @(posedge clk1) begin
        if (taken_branch == 0) begin
            case (MEM_WB_type)
                RR_ALU: Reg[MEM_WB_IR[15:11]] <= #2 MEM_WB_ALUOUT; // RD
                RM_ALU: Reg[MEM_WB_IR[20:16]] <= #2 MEM_WB_ALUOUT; // RT
                LOAD:   Reg[MEM_WB_IR[20:16]] <= #2 MEM_WB_LMD;    // RT
                HALT:   halted <= #2 1'b1;
            endcase
        end
    end
endmodule

