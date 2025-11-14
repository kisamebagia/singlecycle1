module brc
(
	input 	logic [31:0] i_rs1_data,
	input 	logic [31:0] i_rs2_data,
	input 	logic 		 i_br_un,		// 1 = signed compare
	output 	logic 		 o_br_less,
	output 	logic 		 o_br_equal
);

	logic Less_un, Less_si;

	// unsigned comparator
	comp32 inst1 (
		.A(i_rs1_data),
		.B(i_rs2_data),
		.Less(Less_un),
		.Equal(o_br_equal)
	);

	// signed comparator
	comp32 inst2 (
		.A(i_rs1_data),
		.B(i_rs2_data),
		.Less(Less_si),
		.Equal()
	);

	always_comb begin
		if (i_br_un) begin
			// signed compare (BLT/BGE)
			o_br_less = (i_rs1_data[31] & ~i_rs2_data[31]) | 
			            (~i_rs1_data[31] & ~i_rs2_data[31] & Less_si) | 
			            (i_rs1_data[31] & i_rs2_data[31] & Less_si);
		end else begin
			// unsigned compare (BLTU/BGEU)
			o_br_less = Less_un;
		end
	end

endmodule

