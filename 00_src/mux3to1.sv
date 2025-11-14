module mux3to1 (
    input  logic [31:0] i_d0,   // ALU result
    input  logic [31:0] i_d1,   // Load data
    input  logic [31:0] i_d2,   // PC + 4
    input  logic [1:0]  i_sel,  // wb_sel
    output logic [31:0] o_y     // wb_data
);

    always_comb begin
        unique case (i_sel)
            2'b00: o_y = i_d0;  // ALU result
            2'b01: o_y = i_d1;  // Memory load
            2'b10: o_y = i_d2;  // PC + 4
            default: o_y = 32'b0;
        endcase
    end

endmodule
