module decoder5_32 (
    input  logic [4:0]  in,    
    input  logic        en,  
    output logic [31:0] y      // one-hot output
);
    always_comb begin
        y[0]  = en & (in == 5'd0);
        y[1]  = en & (in == 5'd1);
        y[2]  = en & (in == 5'd2);
        y[3]  = en & (in == 5'd3);
        y[4]  = en & (in == 5'd4);
        y[5]  = en & (in == 5'd5);
        y[6]  = en & (in == 5'd6);
        y[7]  = en & (in == 5'd7);
        y[8]  = en & (in == 5'd8);
        y[9]  = en & (in == 5'd9);
        y[10] = en & (in == 5'd10);
        y[11] = en & (in == 5'd11);
        y[12] = en & (in == 5'd12);
        y[13] = en & (in == 5'd13);
        y[14] = en & (in == 5'd14);
        y[15] = en & (in == 5'd15);
        y[16] = en & (in == 5'd16);
        y[17] = en & (in == 5'd17);
        y[18] = en & (in == 5'd18);
        y[19] = en & (in == 5'd19);
        y[20] = en & (in == 5'd20);
        y[21] = en & (in == 5'd21);
        y[22] = en & (in == 5'd22);
        y[23] = en & (in == 5'd23);
        y[24] = en & (in == 5'd24);
        y[25] = en & (in == 5'd25);
        y[26] = en & (in == 5'd26);
        y[27] = en & (in == 5'd27);
        y[28] = en & (in == 5'd28);
        y[29] = en & (in == 5'd29);
        y[30] = en & (in == 5'd30);
        y[31] = en & (in == 5'd31);
    end
endmodule
