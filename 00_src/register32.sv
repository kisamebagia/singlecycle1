module register32 (
    input  logic        i_clk,   
    input  logic        i_reset_n, 
    input  logic        i_we,     
    input  logic [31:0] i_d,     
    output logic [31:0] o_q       
);
    always_ff @(posedge i_clk or negedge i_reset_n) begin
        if (!i_reset_n)
            o_q <= 32'b0;       
        else if (i_we)
            o_q <= i_d;         
        else
            o_q <= o_q;         
    end
endmodule
