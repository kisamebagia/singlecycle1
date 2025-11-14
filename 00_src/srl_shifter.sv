module srl_shifter (
    input  logic [31:0] data_in,
    input  logic [4:0]  shift_amount,
    output logic [31:0] data_out
);
    logic [31:0] stage1_out, stage2_out, stage3_out, stage4_out;

    assign stage1_out = shift_amount[0] ? {1'b0, data_in[31:1]} : data_in;
    assign stage2_out = shift_amount[1] ? {2'b0, stage1_out[31:2]} : stage1_out;
    assign stage3_out = shift_amount[2] ? {4'b0, stage2_out[31:4]} : stage2_out;
    assign stage4_out = shift_amount[3] ? {8'b0, stage3_out[31:8]} : stage3_out;
    assign data_out   = shift_amount[4] ? {16'b0, stage4_out[31:16]} : stage4_out;
	 
endmodule
