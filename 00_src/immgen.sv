module immgen (
    input  logic [31:0] i_instr,
    output logic [31:0] o_imm_data
);

    always_comb begin
        case (i_instr[6:0])
            // I-type: LOAD, OP-IMM, JALR
            7'b0000011, 7'b0010011, 7'b1100111:
                o_imm_data = {{20{i_instr[31]}}, i_instr[31:20]};

            // S-type: STORE
            7'b0100011:
                o_imm_data = {{20{i_instr[31]}}, i_instr[31:25], i_instr[11:7]};

            // B-type: BRANCH
            7'b1100011:
                o_imm_data = {{19{i_instr[31]}}, i_instr[31], i_instr[7], i_instr[30:25], i_instr[11:8], 1'b0};

            // U-type: LUI, AUIPC
            7'b0110111, 7'b0010111:
                o_imm_data = {i_instr[31:12], 12'b0};

            // J-type: JAL
            7'b1101111:
                o_imm_data = {{12{i_instr[31]}}, i_instr[19:12], i_instr[20], i_instr[30:21], 1'b0};

            default:
                o_imm_data = 32'b0;
        endcase
    end
endmodule
