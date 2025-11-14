module singlecycle (
    input  logic        i_clk,
    input  logic        i_reset,    

    // Debug
    output logic [31:0] o_pc_debug,
    output logic        o_insn_vld,

    // I/O (Memory-mapped)
    input  logic [31:0] i_io_sw,
    output logic [31:0] o_io_ledr,
    output logic [31:0] o_io_ledg,
    output logic [6:0]  o_io_hex0, o_io_hex1, o_io_hex2, o_io_hex3,
    output logic [6:0]  o_io_hex4, o_io_hex5, o_io_hex6, o_io_hex7,
    output logic [31:0] o_io_lcd
);

    // Internal signals
    logic [31:0] pc_current, pc_next, pc_plus4;
    logic [31:0] instr;
    logic [4:0]  rs1_addr, rs2_addr, rd_addr;
    logic [31:0] rs1_data, rs2_data, wb_data;
    logic [31:0] imm_data;
    logic [31:0] alu_operand_a, alu_operand_b, alu_result;
    logic [31:0] ld_data;
    logic        br_less, br_equal;

    // Control signals
    logic [1:0]  pc_sel;
    logic        rd_wren;
    logic        br_un;
    logic        opa_sel;
    logic        opb_sel;
    logic [3:0]  alu_op;
    logic        mem_wren;
    logic [1:0]  wb_sel;
    logic [2:0]  funct3_to_lsu;
    logic [2:0]  imm_type;
    logic        insn_vld_internal;

    // Constants
    localparam WB_SEL_ALU = 2'b00;
    localparam WB_SEL_MEM = 2'b01;
    localparam WB_SEL_PC4 = 2'b10;

    // PC Unit
    pc_unit u_pc (
        .i_clk        (i_clk),
        .i_reset      (i_reset),
        .i_pc_sel     (pc_sel),
        .i_branch_tgt (alu_result),
        .i_jalr_tgt   ({alu_result[31:1], 1'b0}),
        .o_pc_curr    (pc_current),
        .o_pc_next    (pc_next),
        .o_pc_plus4   (pc_plus4)
    );

    assign o_pc_debug = pc_current;

    // Instruction Memory
    instruction_memory imem (
        .i_addr  (pc_current[12:0]),
        .o_instr (instr)
    );

    // Decode
    assign rs1_addr = instr[19:15];
    assign rs2_addr = instr[24:20];
    assign rd_addr  = instr[11:7];

    logic [6:0] opcode;
    logic [2:0] funct3;
    logic       funct7_bit5;

    assign opcode      = instr[6:0];
    assign funct3      = instr[14:12];
    assign funct7_bit5 = instr[30];
	 
    controlunit u_ctrl (
        .i_opcode       (opcode),
        .i_funct3       (funct3),
        .i_funct7_bit5  (funct7_bit5),
        .i_br_less      (br_less),
        .i_br_equal     (br_equal),
        .o_pc_sel       (pc_sel),
        .o_rd_wren      (rd_wren),
        .o_insn_vld     (insn_vld_internal),
        .o_br_un        (br_un),
        .o_opa_sel      (opa_sel),
        .o_opb_sel      (opb_sel),
        .o_alu_op       (alu_op),
        .o_mem_wren     (mem_wren),
        .o_wb_sel       (wb_sel),
        .o_imm_type     (imm_type),
        .o_funct3_to_lsu(funct3_to_lsu)
    );

    regfile u_regfile (
        .i_clk      (i_clk),
        .i_reset    (i_reset),
        .i_rs1_addr (rs1_addr),
        .o_rs1_data (rs1_data),
        .i_rs2_addr (rs2_addr),
        .o_rs2_data (rs2_data),
        .i_rd_addr  (rd_addr),
        .i_rd_data  (wb_data),
        .i_rd_wren  (rd_wren)
    );

    immgen u_immgen (
        .i_instr   (instr),
        .o_imm_data(imm_data)
    );

    brc u_brc (
        .i_rs1_data (rs1_data),
        .i_rs2_data (rs2_data),
        .i_br_un    (br_un),
        .o_br_less  (br_less),
        .o_br_equal (br_equal)
    );

    assign alu_operand_a = (opa_sel == 1'b0) ? rs1_data   : pc_current;
    assign alu_operand_b = (opb_sel == 1'b0) ? rs2_data   : imm_data;

    alu u_alu (
        .i_op_a    (alu_operand_a),
        .i_op_b    (alu_operand_b),
        .i_alu_op  (alu_op),
        .o_alu_data(alu_result)
    );

    lsu u_lsu (
        .i_clk       (i_clk),
        .i_reset     (i_reset),
        .i_lsu_addr  (alu_result),
        .i_st_data   (rs2_data),
        .i_lsu_wren  (mem_wren),
        .i_func3    (funct3_to_lsu),
        .o_ld_data   (ld_data),

        // I/O
        .o_io_ledr   (o_io_ledr),
        .o_io_ledg   (o_io_ledg),
        .i_io_sw     (i_io_sw),
        .o_io_hex0   (o_io_hex0),
        .o_io_hex1   (o_io_hex1),
        .o_io_hex2   (o_io_hex2),
        .o_io_hex3   (o_io_hex3),
        .o_io_hex4   (o_io_hex4),
        .o_io_hex5   (o_io_hex5),
        .o_io_hex6   (o_io_hex6),
        .o_io_hex7   (o_io_hex7),
        .o_io_lcd    (o_io_lcd)
    );

    // Writeback Multiplexer (3-to-1)
    mux3to1 u_wb_mux (
        .i_d0  (alu_result),  // 00: ALU
        .i_d1  (ld_data),     // 01: MEM
        .i_d2  (pc_plus4),    // 10: PC+4
        .i_sel (wb_sel),
        .o_y   (wb_data)
    );

    assign o_insn_vld = insn_vld_internal;

endmodule
