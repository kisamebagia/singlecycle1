module mux32_1 (
    input  logic [4:0]  sel,   // select
    input  logic [31:0] d,     // 32 input bits
    output logic        y      // output
);
    always_comb begin
        case (sel)
            5'd0:  y = d[0];
            5'd1:  y = d[1];
            5'd2:  y = d[2];
            5'd3:  y = d[3];
            5'd4:  y = d[4];
            5'd5:  y = d[5];
            5'd6:  y = d[6];
            5'd7:  y = d[7];
            5'd8:  y = d[8];
            5'd9:  y = d[9];
            5'd10: y = d[10];
            5'd11: y = d[11];
            5'd12: y = d[12];
            5'd13: y = d[13];
            5'd14: y = d[14];
            5'd15: y = d[15];
            5'd16: y = d[16];
            5'd17: y = d[17];
            5'd18: y = d[18];
            5'd19: y = d[19];
            5'd20: y = d[20];
            5'd21: y = d[21];
            5'd22: y = d[22];
            5'd23: y = d[23];
            5'd24: y = d[24];
            5'd25: y = d[25];
            5'd26: y = d[26];
            5'd27: y = d[27];
            5'd28: y = d[28];
            5'd29: y = d[29];
            5'd30: y = d[30];
            5'd31: y = d[31];
            default: y = 1'b0;
        endcase
    end
endmodule
