module comp32 (
    input  logic [31:0] A,
    input  logic [31:0] B,
    output logic Less,
    output logic Equal
);
    logic L1, L2, L3, L4;
    logic E1, E2, E3;

    comp8 inst1 (.Equ(1'b1), .A(A[31:24]), .B(B[31:24]), .Less(L1), .Equal(E1));
    comp8 inst2 (.Equ(E1),   .A(A[23:16]), .B(B[23:16]), .Less(L2), .Equal(E2));
    comp8 inst3 (.Equ(E2),   .A(A[15:8]),  .B(B[15:8]),  .Less(L3), .Equal(E3));
    comp8 inst4 (.Equ(E3),   .A(A[7:0]),   .B(B[7:0]),   .Less(L4), .Equal(Equal));

    assign Less = L1 | (E1 & L2) | (E1 & E2 & L3) | (E1 & E2 & E3 & L4);
endmodule


