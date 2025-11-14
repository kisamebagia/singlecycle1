module instruction_memory (
    input  logic [12:0] i_addr,   
    output logic [31:0] o_instr
);
    parameter MEM_SIZE = 2048;
    logic [31:0] mem [MEM_SIZE-1:0];

    logic [10:0] word_addr;
    assign word_addr = i_addr[12:2];  // dùng 11 bit [12:2] để chọn 2048 words

    assign o_instr = mem[word_addr];

    initial begin
        $readmemh("D:/bachkhoa/nam4/cautrucmaytinh/tb/single_cycle_testbench/02_test/isa_4b.hex", mem);
		  //$readmemh("D:/NAM TU/HK251/Computer Architecture/assem_Hao/mem_hex.out",mem);
    end
endmodule
