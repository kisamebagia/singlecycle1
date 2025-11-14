module memory (
  input  logic        i_clk,
  input  logic        i_reset,
  input  logic [2:0]  i_func3,
  input  logic [15:0] i_addr,
  input  logic [31:0] i_wdata,
  input  logic [3:0]  i_bmask_align,
  input  logic [3:0]  i_bmask_misalign,
  input  logic        i_wren,
  output logic [31:0] o_rdata
);

  // Internal
  logic [31:0] mem [0:99];          // 2 KiB = 512 words
  logic [31:0] mem_st_align;
  logic [31:0] mem_st_misalign;
  logic [31:0] mem_ld_align;
  logic [31:0] mem_ld_misalign;
  logic [31:0] mem_addr;
  logic [31:0] mem_addr_plus1;
  logic [31:0] one = 32'd1;

  // Load/store type decode
  logic is_sbyte, is_ubyte, is_shb, is_uhb, is_word;
  
  // Decode load/store type
  always_comb begin
    is_ubyte = 1'b0;
    is_sbyte = 1'b0;
    is_uhb   = 1'b0;
    is_shb   = 1'b0;
    is_word  = 1'b0;
    unique case (i_func3)
      3'b000: is_sbyte = 1'b1; // LB
      3'b001: is_shb   = 1'b1; // LH
      3'b010: is_word  = 1'b1; // LW
      3'b100: is_ubyte = 1'b1; // LBU
      3'b101: is_uhb   = 1'b1; // LHU
      default: ;
    endcase
  end

  // Address mapping (word addressing)
  assign mem_addr = {23'b0, i_addr[10:2]};

  logic [31:0] sum;
  logic [31:0] carry;

  full_adder fa0 (
    .a   (mem_addr[0]),
    .b   (one[0]),
    .cin (1'b0),
    .sum (sum[0]),
    .cout(carry[0])
  );

  genvar k;
  generate
    for (k = 1; k < 32; k++) begin : gen_fa
      full_adder fa (
        .a   (mem_addr[k]),
        .b   (one[k]),
        .cin (carry[k-1]),
        .sum (sum[k]),
        .cout(carry[k])
      );
    end
  endgenerate

  assign mem_addr_plus1 = sum;

  // Asynchronous read
  assign mem_ld_align    = mem[mem_addr];
  assign mem_ld_misalign = mem[mem_addr_plus1];

  // Store data preparation (mask alignment)
  always_comb begin
    unique case (i_bmask_align)
      4'b0001: mem_st_align = {24'b0, i_wdata[7:0]};
      4'b0010: mem_st_align = {16'b0, i_wdata[7:0], 8'b0};
      4'b0100: mem_st_align = {8'b0,  i_wdata[7:0], 16'b0};
      4'b1000: mem_st_align = {i_wdata[7:0], 24'b0};
      4'b0011: mem_st_align = {16'b0, i_wdata[15:0]};
      4'b1100: mem_st_align = {i_wdata[15:0], 16'b0};
      4'b1110: mem_st_align = {i_wdata[23:0], 8'b0};
      4'b1111: mem_st_align = i_wdata;
      default: mem_st_align = 32'b0;
    endcase

    unique case (i_bmask_misalign)
      4'b0000: mem_st_misalign = 32'b0;
      4'b0001: mem_st_misalign = (i_bmask_align[2]) ? 
                                  {24'b0, i_wdata[31:24]} :
                                  {24'b0, i_wdata[15:8]};
      4'b0011: mem_st_misalign = {16'b0, i_wdata[31:16]};
      4'b0111: mem_st_misalign = {8'b0 , i_wdata[31:8]};
      default: mem_st_misalign = 32'b0;
    endcase
  end

  // Synchronous write
  always_ff @(posedge i_clk or negedge i_reset) begin
    if (!i_reset) begin
      for (int j = 0; j < 100; j++)
        mem[j] <= 32'b0;
    end else if (i_wren) begin
      if (i_bmask_align[0]) mem[mem_addr][7:0]   <= mem_st_align[7:0];
      if (i_bmask_align[1]) mem[mem_addr][15:8]  <= mem_st_align[15:8];
      if (i_bmask_align[2]) mem[mem_addr][23:16] <= mem_st_align[23:16];
      if (i_bmask_align[3]) mem[mem_addr][31:24] <= mem_st_align[31:24];
      if (i_bmask_misalign[0]) mem[mem_addr_plus1][7:0]   <= mem_st_misalign[7:0];
      if (i_bmask_misalign[1]) mem[mem_addr_plus1][15:8]  <= mem_st_misalign[15:8];
      if (i_bmask_misalign[2]) mem[mem_addr_plus1][23:16] <= mem_st_misalign[23:16];
      if (i_bmask_misalign[3]) mem[mem_addr_plus1][31:24] <= mem_st_misalign[31:24];
    end
  end

  // Load data (asynchronous)
  always_comb begin
    o_rdata = 32'b0;

    // LW
    if (is_word) begin
      unique case (i_addr[1:0])
        2'b00: o_rdata = mem_ld_align;
        2'b01: o_rdata = {mem_ld_misalign[7:0], mem_ld_align[31:8]};
        2'b10: o_rdata = {mem_ld_misalign[15:0], mem_ld_align[31:16]};
        2'b11: o_rdata = {mem_ld_misalign[23:0], mem_ld_align[31:24]};
        default: ;
      endcase
    end

    // LH
    if (is_shb) begin
      unique case (i_addr[1:0])
        2'b00: o_rdata = {{16{mem_ld_align[15]}}, mem_ld_align[15:0]};
        2'b01: o_rdata = {{16{mem_ld_align[23]}}, mem_ld_align[23:8]};
        2'b10: o_rdata = {{16{mem_ld_align[31]}}, mem_ld_align[31:16]};
        2'b11: o_rdata = {{16{mem_ld_misalign[7]}}, mem_ld_misalign[7:0], mem_ld_align[31:24]};
        default: ;
      endcase
    end

    // LHU
    if (is_uhb) begin
      unique case (i_addr[1:0])
        2'b00: o_rdata = {16'b0, mem_ld_align[15:0]};
        2'b01: o_rdata = {16'b0, mem_ld_align[23:8]};
        2'b10: o_rdata = {16'b0, mem_ld_align[31:16]};
        2'b11: o_rdata = {16'b0, mem_ld_misalign[7:0], mem_ld_align[31:24]};
        default: ;
      endcase
    end

    // LB
    if (is_sbyte) begin
      unique case (i_addr[1:0])
        2'b00: o_rdata = {{24{mem_ld_align[7]}},  mem_ld_align[7:0]};
        2'b01: o_rdata = {{24{mem_ld_align[15]}}, mem_ld_align[15:8]};
        2'b10: o_rdata = {{24{mem_ld_align[23]}}, mem_ld_align[23:16]};
        2'b11: o_rdata = {{24{mem_ld_align[31]}}, mem_ld_align[31:24]};
        default: ;
      endcase
    end

    // LBU
    if (is_ubyte) begin
      unique case (i_addr[1:0])
        2'b00: o_rdata = {24'b0, mem_ld_align[7:0]};
        2'b01: o_rdata = {24'b0, mem_ld_align[15:8]};
        2'b10: o_rdata = {24'b0, mem_ld_align[23:16]};
        2'b11: o_rdata = {24'b0, mem_ld_align[31:24]};
        default: ;
      endcase
    end
  end
endmodule
