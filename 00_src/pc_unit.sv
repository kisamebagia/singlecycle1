module pc_unit (
    input  logic        i_clk,
    input  logic        i_reset,      
    input  logic [1:0]  i_pc_sel,     
    input  logic [31:0] i_branch_tgt, 
    input  logic [31:0] i_jalr_tgt,   
    output logic [31:0] o_pc_curr,    
    output logic [31:0] o_pc_next,    
    output logic [31:0] o_pc_plus4    
);

    localparam PC_SEL_PC4   = 2'b00;
    localparam PC_SEL_BRJMP = 2'b01;
    localparam PC_SEL_JALR  = 2'b10;

    // PC Register
    always_ff @(posedge i_clk or negedge i_reset) begin
        if (!i_reset)
            o_pc_curr <= 32'b0;
        else
            o_pc_curr <= o_pc_next;
    end

    logic [31:0] const_4 = 32'd4;
    logic [31:0] carry;

    genvar i;
    generate
        for (i = 0; i < 32; i++) begin : pc_adder
            if (i == 0) begin
                full_adder fa0 (
                    .a   (o_pc_curr[i]),
                    .b   (const_4[i]),
                    .cin (1'b0),
                    .sum (o_pc_plus4[i]),
                    .cout(carry[i])
                );
            end else begin
                full_adder fai (
                    .a   (o_pc_curr[i]),
                    .b   (const_4[i]),
                    .cin (carry[i-1]),
                    .sum (o_pc_plus4[i]),
                    .cout(carry[i])
                );
            end
        end
    endgenerate

    always_comb begin
        unique case (i_pc_sel)
            PC_SEL_PC4:   o_pc_next = o_pc_plus4;
            PC_SEL_BRJMP: o_pc_next = i_branch_tgt;
            PC_SEL_JALR:  o_pc_next = i_jalr_tgt;
            default:      o_pc_next = o_pc_plus4;
        endcase
    end

endmodule
