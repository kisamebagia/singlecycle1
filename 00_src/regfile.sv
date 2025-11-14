module regfile (
    input  logic        i_clk,       
    input  logic        i_reset,      
    input  logic [4:0]  i_rs1_addr,   
    input  logic [4:0]  i_rs2_addr,   
    input  logic [4:0]  i_rd_addr,    
    input  logic [31:0] i_rd_data,   
    input  logic        i_rd_wren,    
    output logic [31:0] o_rs1_data,   
    output logic [31:0] o_rs2_data    
);

    logic [31:0] dec_out;          // one-hot from decoder
    logic [31:0] reg_out [31:0];   

    decoder5_32 u_decoder (
        .in (i_rd_addr),
        .en (i_rd_wren),
        .y  (dec_out)
    );

    genvar i;
    generate
        for (i = 0; i < 32; i++) begin : gen_reg
            if (i == 0) begin
                assign reg_out[0] = 32'b0;
            end else begin
                register32 u_reg (
                    .i_clk     (i_clk),
                    .i_reset_n (i_reset), // active-low
                    .i_we      (dec_out[i]),
                    .i_d       (i_rd_data),
                    .o_q       (reg_out[i])
                );
            end
        end
    endgenerate

    genvar j;
    generate
        for (j = 0; j < 32; j++) begin : gen_mux_rs1
            mux32_1 u_mux1 (
                .sel (i_rs1_addr),
                .d   ({
                    reg_out[31][j], reg_out[30][j], reg_out[29][j], reg_out[28][j],
                    reg_out[27][j], reg_out[26][j], reg_out[25][j], reg_out[24][j],
                    reg_out[23][j], reg_out[22][j], reg_out[21][j], reg_out[20][j],
                    reg_out[19][j], reg_out[18][j], reg_out[17][j], reg_out[16][j],
                    reg_out[15][j], reg_out[14][j], reg_out[13][j], reg_out[12][j],
                    reg_out[11][j], reg_out[10][j], reg_out[9][j],  reg_out[8][j],
                    reg_out[7][j],  reg_out[6][j],  reg_out[5][j],  reg_out[4][j],
                    reg_out[3][j],  reg_out[2][j],  reg_out[1][j],  reg_out[0][j]
                }),
                .y   (o_rs1_data[j])
            );
        end
    endgenerate
	 
    genvar k;
    generate
        for (k = 0; k < 32; k++) begin : gen_mux_rs2
            mux32_1 u_mux2 (
                .sel (i_rs2_addr),
                .d   ({
                    reg_out[31][k], reg_out[30][k], reg_out[29][k], reg_out[28][k],
                    reg_out[27][k], reg_out[26][k], reg_out[25][k], reg_out[24][k],
                    reg_out[23][k], reg_out[22][k], reg_out[21][k], reg_out[20][k],
                    reg_out[19][k], reg_out[18][k], reg_out[17][k], reg_out[16][k],
                    reg_out[15][k], reg_out[14][k], reg_out[13][k], reg_out[12][k],
                    reg_out[11][k], reg_out[10][k], reg_out[9][k],  reg_out[8][k],
                    reg_out[7][k],  reg_out[6][k],  reg_out[5][k],  reg_out[4][k],
                    reg_out[3][k],  reg_out[2][k],  reg_out[1][k],  reg_out[0][k]
                }),
                .y   (o_rs2_data[k])
            );
        end
    endgenerate

endmodule
