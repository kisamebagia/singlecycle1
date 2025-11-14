module adder_32bit (
    input  logic [31:0] a, b,
    input  logic        cin,
    output logic [31:0] sum,
    output logic        cout
);
    logic [3:0] c;

    adder_8bit u0 (.a(a[7:0]),   .b(b[7:0]),   .cin(cin),  .sum(sum[7:0]),   .cout(c[0]));
    adder_8bit u1 (.a(a[15:8]),  .b(b[15:8]),  .cin(c[0]), .sum(sum[15:8]),  .cout(c[1]));
    adder_8bit u2 (.a(a[23:16]), .b(b[23:16]), .cin(c[1]), .sum(sum[23:16]), .cout(c[2]));
    adder_8bit u3 (.a(a[31:24]), .b(b[31:24]), .cin(c[2]), .sum(sum[31:24]), .cout(cout));
endmodule
