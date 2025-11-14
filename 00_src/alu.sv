module alu (
    input  logic [31:0] i_op_a,
    input  logic [31:0] i_op_b,
    input  logic [3:0]  i_alu_op,
    output logic [31:0] o_alu_data
);

    //OP CODE
    parameter OP_ADD   = 4'b0000;
    parameter OP_SUB   = 4'b0001;
    parameter OP_SLL   = 4'b0010;
    parameter OP_SLT   = 4'b0011; 
    parameter OP_SLTU  = 4'b0100;
    parameter OP_XOR   = 4'b0101; 
    parameter OP_SRL   = 4'b0110; 
    parameter OP_SRA   = 4'b0111; 
    parameter OP_OR    = 4'b1000; 
    parameter OP_AND   = 4'b1001; 
    parameter OP_LUI   = 4'b1010; // Load Upper Immediate

    //BỘ CỘNG / TRỪ
    logic [31:0] adder_b;
    logic        adder_cin;
    logic [31:0] adder_result;
    logic        adder_cout;

    // SUB / SLT / SLTU
    logic is_subtract;
    assign is_subtract = (i_alu_op == OP_SUB) | (i_alu_op == OP_SLT) | (i_alu_op == OP_SLTU);

    assign adder_b   = is_subtract ? ~i_op_b : i_op_b;
    assign adder_cin = is_subtract ? 1'b1    : 1'b0;

    //adder_32bit
    adder_32bit u_adder (
        .a   (i_op_a),
        .b   (adder_b),
        .cin (adder_cin),
        .sum (adder_result),
        .cout(adder_cout)
    );

    //LOGIC BITWISE
    logic [31:0] logic_result;
    always_comb begin
        case (i_alu_op)
            OP_XOR: logic_result = i_op_a ^ i_op_b;
            OP_OR:  logic_result = i_op_a | i_op_b;
            OP_AND: logic_result = i_op_a & i_op_b;
            default: logic_result = 32'b0;
        endcase
    end

    //SHIFTER
    logic [31:0] sll_result, srl_result, sra_result, shift_result;
    logic [4:0]  shift_amount;
    assign shift_amount = i_op_b[4:0];

    sll_shifter sll_unit (.data_in(i_op_a), .shift_amount(shift_amount), .data_out(sll_result));
    srl_shifter srl_unit (.data_in(i_op_a), .shift_amount(shift_amount), .data_out(srl_result));
    sra_shifter sra_unit (.data_in(i_op_a), .shift_amount(shift_amount), .data_out(sra_result));

    always_comb begin
        case (i_alu_op)
            OP_SLL: shift_result = sll_result;
            OP_SRL: shift_result = srl_result;
            OP_SRA: shift_result = sra_result;
            default: shift_result = 32'b0;
        endcase
    end

    //SLT, SLTU
    logic sign_a, sign_b, sign_res;
    assign sign_a  = i_op_a[31];
    assign sign_b  = i_op_b[31];
    assign sign_res = adder_result[31];

    logic less_s, less_u;
    assign less_s = (sign_a & ~sign_b) | (~(sign_a ^ sign_b) & sign_res); // signed
    assign less_u = ~adder_cout; // unsigned borrow

    logic [31:0] cmp_result;
    always_comb begin
        case (i_alu_op)
            OP_SLT:  cmp_result = {31'b0, less_s};
            OP_SLTU: cmp_result = {31'b0, less_u};
            default: cmp_result = 32'b0;
        endcase
    end

    always_comb begin
        case (i_alu_op)
            OP_ADD, OP_SUB:   o_alu_data = adder_result;
            OP_SLT, OP_SLTU:  o_alu_data = cmp_result;
            OP_XOR, OP_OR,
            OP_AND:           o_alu_data = logic_result;
            OP_SLL, OP_SRL,
            OP_SRA:           o_alu_data = shift_result;
            OP_LUI:           o_alu_data = i_op_b;   // LUI
            default:          o_alu_data = 32'h00000000;
        endcase
    end

endmodule
