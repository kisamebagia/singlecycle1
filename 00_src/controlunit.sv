module controlunit (
    input  logic [6:0] i_opcode,
    input  logic [2:0] i_funct3,
    input  logic       i_funct7_bit5,
    input  logic       i_br_less,
    input  logic       i_br_equal,

    output logic [1:0] o_pc_sel,          
    output logic       o_rd_wren,         
    output logic       o_insn_vld,       
    output logic       o_br_un,           // 1 = signed compare, 0 = unsigned
    output logic       o_opa_sel,         // 0=rs1, 1=PC
    output logic       o_opb_sel,         // 0=rs2, 1=imm
    output logic [3:0] o_alu_op,
    output logic       o_mem_wren,
    output logic [1:0] o_wb_sel,
    output logic [2:0] o_imm_type,
    output logic [2:0] o_funct3_to_lsu
);

    // PC select
    localparam PC_SEL_PC4   = 2'b00;
    localparam PC_SEL_BRJMP = 2'b01;
    localparam PC_SEL_JALR  = 2'b10;

    // WB select
    localparam WB_SEL_ALU = 2'b00;
    localparam WB_SEL_MEM = 2'b01;
    localparam WB_SEL_PC4 = 2'b10;

    // Imm types
    localparam IMM_X = 3'b000;
    localparam IMM_I = 3'b001;
    localparam IMM_S = 3'b010;
    localparam IMM_B = 3'b011;
    localparam IMM_U = 3'b100;
    localparam IMM_J = 3'b101;

    // ALU ops
    localparam ALU_ADD    = 4'b0000;
    localparam ALU_SUB    = 4'b0001;
    localparam ALU_SLL    = 4'b0010;
    localparam ALU_SLT    = 4'b0011;
    localparam ALU_SLTU   = 4'b0100;
    localparam ALU_XOR    = 4'b0101;
    localparam ALU_SRL    = 4'b0110;
    localparam ALU_SRA    = 4'b0111;
    localparam ALU_OR     = 4'b1000;
    localparam ALU_AND    = 4'b1001;
    localparam ALU_LUI 	  = 4'b1010;

    always_comb begin
        o_pc_sel        = PC_SEL_PC4;
        o_rd_wren       = 1'b0;
        o_insn_vld      = 1'b0;
        o_br_un         = 1'b0;     
        o_opa_sel       = 1'b0;
        o_opb_sel       = 1'b0;
        o_alu_op        = ALU_ADD;
        o_mem_wren      = 1'b0;
        o_wb_sel        = WB_SEL_ALU;
        o_imm_type      = IMM_X;
        o_funct3_to_lsu = 3'b000;

        unique case (i_opcode)
        7'b0110011: begin // R-type
            o_insn_vld = 1'b1;
            o_rd_wren  = 1'b1;
            o_opb_sel  = 1'b0;
            o_wb_sel   = WB_SEL_ALU;
            unique case (i_funct3)
                3'b000: o_alu_op = (i_funct7_bit5) ? ALU_SUB : ALU_ADD;
                3'b001: o_alu_op = ALU_SLL;
                3'b010: o_alu_op = ALU_SLT;
                3'b011: o_alu_op = ALU_SLTU;
                3'b100: o_alu_op = ALU_XOR;
                3'b101: o_alu_op = (i_funct7_bit5) ? ALU_SRA : ALU_SRL;
                3'b110: o_alu_op = ALU_OR;
                3'b111: o_alu_op = ALU_AND;
                default: o_insn_vld = 1'b0;
            endcase
        end

        7'b0010011: begin // I-type ALU
            o_insn_vld = 1'b1;
            o_rd_wren  = 1'b1;
            o_opb_sel  = 1'b1;
            o_wb_sel   = WB_SEL_ALU;
            o_imm_type = IMM_I;
            unique case (i_funct3)
                3'b000: o_alu_op = ALU_ADD;   // ADDI
                3'b001: o_alu_op = ALU_SLL;   // SLLI
                3'b010: o_alu_op = ALU_SLT;   // SLTI
                3'b011: o_alu_op = ALU_SLTU;  // SLTIU
                3'b100: o_alu_op = ALU_XOR;   // XORI
                3'b101: o_alu_op = (i_funct7_bit5) ? ALU_SRA : ALU_SRL; // SRAI/SRLI
                3'b110: o_alu_op = ALU_OR;    // ORI
                3'b111: o_alu_op = ALU_AND;   // ANDI
                default: o_insn_vld = 1'b0;
            endcase
        end

        7'b0000011: begin // Loads
            o_insn_vld      = 1'b1;
            o_rd_wren       = 1'b1;
            o_opb_sel       = 1'b1;
            o_alu_op        = ALU_ADD;
            o_wb_sel        = WB_SEL_MEM;
            o_imm_type      = IMM_I;
            o_funct3_to_lsu = i_funct3;
        end

        7'b0100011: begin // Stores
            o_insn_vld      = 1'b1;
				o_rd_wren       = 1'b0; 
            o_mem_wren      = 1'b1;
            o_opb_sel       = 1'b1;
            o_alu_op        = ALU_ADD;
            o_imm_type      = IMM_S;
            o_funct3_to_lsu = i_funct3;
        end

        7'b1100011: begin // Branches
            o_insn_vld = 1'b1;
            o_opa_sel  = 1'b1;  // PC
            o_opb_sel  = 1'b1;  // imm
            o_alu_op   = ALU_ADD;
            o_imm_type = IMM_B;

            unique case (i_funct3)
                3'b000: o_pc_sel =  i_br_equal ? PC_SEL_BRJMP : PC_SEL_PC4;   // BEQ
                
					 3'b001: o_pc_sel = ~i_br_equal ? PC_SEL_BRJMP : PC_SEL_PC4;   // BNE

                3'b100: begin // BLT
                    o_br_un  = 1'b1; 
                    o_pc_sel =  i_br_less ? PC_SEL_BRJMP : PC_SEL_PC4;
                end
                3'b101: begin // BGE (signed)
                    o_br_un  = 1'b1;  // 1 = signed
                    o_pc_sel = ~i_br_less ? PC_SEL_BRJMP : PC_SEL_PC4;
                end

                3'b110: begin // BLTU (unsigned)
                    o_br_un  = 1'b0;  // 0 = unsigned
                    o_pc_sel =  i_br_less ? PC_SEL_BRJMP : PC_SEL_PC4;
                end
                3'b111: begin // BGEU (unsigned)
                    o_br_un  = 1'b0;  // 0 = unsigned
                    o_pc_sel = ~i_br_less ? PC_SEL_BRJMP : PC_SEL_PC4;
                end
                default: o_insn_vld = 1'b0;
            endcase
        end

        7'b0110111: begin // LUI
            o_insn_vld = 1'b1;
            o_rd_wren  = 1'b1;
            o_opb_sel  = 1'b1;
            o_alu_op   = ALU_LUI;
            o_wb_sel   = WB_SEL_ALU;
            o_imm_type = IMM_U;
        end

        7'b0010111: begin // AUIPC
            o_insn_vld = 1'b1;
            o_rd_wren  = 1'b1;
            o_opa_sel  = 1'b1;  // PC
            o_opb_sel  = 1'b1;  // imm
            o_alu_op   = ALU_ADD;
            o_wb_sel   = WB_SEL_ALU;
            o_imm_type = IMM_U;
        end

        7'b1101111: begin // JAL
            o_insn_vld = 1'b1;
            o_rd_wren  = 1'b1;
            o_pc_sel   = PC_SEL_BRJMP;
            o_opa_sel  = 1'b1;  // PC
            o_opb_sel  = 1'b1;  // imm
            o_alu_op   = ALU_ADD;
            o_wb_sel   = WB_SEL_PC4;
            o_imm_type = IMM_J;
        end

        7'b1100111: begin // JALR
            o_insn_vld = 1'b1;
            o_rd_wren  = 1'b1;
            o_pc_sel   = PC_SEL_JALR;
            o_opb_sel  = 1'b1;  // imm
            o_alu_op   = ALU_ADD;
            o_wb_sel   = WB_SEL_PC4;
            o_imm_type = IMM_I;
        end

        default: o_insn_vld = 1'b0;
        endcase
    end
endmodule
