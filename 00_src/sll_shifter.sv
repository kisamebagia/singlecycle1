module sll_shifter (
    input  logic [31:0] data_in,
    input  logic [4:0]  shift_amount,
    output logic [31:0] data_out
);
    logic [31:0] stage1_out, stage2_out, stage3_out, stage4_out;

    assign stage1_out = shift_amount[0] ? {data_in[30:0], 1'b0} : data_in;
    assign stage2_out = shift_amount[1] ? {stage1_out[29:0], 2'b0} : stage1_out;
    assign stage3_out = shift_amount[2] ? {stage2_out[27:0], 4'b0} : stage2_out;
    assign stage4_out = shift_amount[3] ? {stage3_out[23:0], 8'b0} : stage3_out;
    assign data_out   = shift_amount[4] ? {stage4_out[15:0], 16'b0} : stage4_out;
	 
endmodule
