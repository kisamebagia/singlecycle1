module lsu (
  input  logic        i_clk,
  input  logic        i_reset,

  input  logic [31:0] i_lsu_addr,
  input  logic [31:0] i_st_data,
  input  logic        i_lsu_wren,
  input  logic [2:0]  i_func3,

  input  logic [31:0] i_io_sw,

  output logic [6:0]  o_io_hex0,
  output logic [6:0]  o_io_hex1,
  output logic [6:0]  o_io_hex2,
  output logic [6:0]  o_io_hex3,
  output logic [6:0]  o_io_hex4,
  output logic [6:0]  o_io_hex5,
  output logic [6:0]  o_io_hex6,
  output logic [6:0]  o_io_hex7,

  output logic [31:0] o_ld_data,

  output logic [31:0] o_io_ledr,
  output logic [31:0] o_io_ledg,
  output logic [31:0] o_io_lcd
);

  // Internal
  logic        is_ledr, is_ledg, is_hex03, is_hex47, is_lcd, is_sw;
  logic        is_dmem, is_out, is_in;

  logic [15:0] dmem_ptr;
  logic        mem_wren;

  logic        is_sbyte, is_ubyte, is_shb, is_uhb, is_word;
  logic [3:0]  bmask_align, bmask_misalign;

  logic [31:0] dmem;
  logic [31:0] st_wdata, ld_data;

  logic [31:0] ledr_next, ledg_next, lcd_next;
  logic [6:0]  hex0_next, hex1_next, hex2_next, hex3_next;
  logic [6:0]  hex4_next, hex5_next, hex6_next, hex7_next;

  // Decode type
  always_comb begin
    // Default
    is_ubyte = 1'b0; is_sbyte = 1'b0;
    is_uhb   = 1'b0; is_shb   = 1'b0;
    is_word  = 1'b0;
    bmask_align = 4'b0;
    bmask_misalign = 4'b0;

    // Decode funct3
    unique case (i_func3)
      3'b000: is_sbyte = 1'b1; // LB / SB
      3'b001: is_shb   = 1'b1; // LH / SH
      3'b010: is_word  = 1'b1; // LW / SW
      3'b100: is_ubyte = 1'b1; // LBU
      3'b101: is_uhb   = 1'b1; // LHU
      default: ;
    endcase

    // Byte mask (alignment)
    if (is_sbyte || is_ubyte) begin
      unique case (i_lsu_addr[1:0])
        2'b00: bmask_align = 4'b0001;
        2'b01: bmask_align = 4'b0010;
        2'b10: bmask_align = 4'b0100;
        2'b11: bmask_align = 4'b1000;
        default: ;
      endcase
    end 
    else if (is_shb || is_uhb) begin
      unique case (i_lsu_addr[1:0])
        2'b00: bmask_align = 4'b0011;
        2'b01: bmask_align = 4'b0110;
        2'b10: bmask_align = 4'b1100;
        2'b11: begin
          bmask_align    = 4'b1000;
          bmask_misalign = 4'b0001;
        end
        default: ;
      endcase
    end 
    else if (is_word) begin
      unique case (i_lsu_addr[1:0])
        2'b00: bmask_align = 4'b1111;
        2'b01: begin bmask_align = 4'b1110; 
		               bmask_misalign = 4'b0001; 
					end
        2'b10: begin bmask_align = 4'b1100; 
		               bmask_misalign = 4'b0011; 
					end
        2'b11: begin bmask_align = 4'b1000; 
		               bmask_misalign = 4'b0111; 
					end
        default: ;
      endcase
    end
  end

  // Address decode (I/O mapping)
  assign dmem_ptr = i_lsu_addr[15:0];
  assign is_dmem  = ~i_lsu_addr[28];                       // 0x0000_xxxx
  assign is_out   = (i_lsu_addr[28] && ~i_lsu_addr[16]);   // 0x1000_xxxx
  assign is_in    = (i_lsu_addr[28] &&  i_lsu_addr[16]);   // 0x1001_xxxx

  assign is_ledr  = is_out && (~i_lsu_addr[14] && ~i_lsu_addr[13] && ~i_lsu_addr[12]);
  assign is_ledg  = is_out && (~i_lsu_addr[14] && ~i_lsu_addr[13] &&  i_lsu_addr[12]);
  assign is_hex03 = is_out && (~i_lsu_addr[14] &&  i_lsu_addr[13] && ~i_lsu_addr[12]);
  assign is_hex47 = is_out && (~i_lsu_addr[14] &&  i_lsu_addr[13] &&  i_lsu_addr[12]);
  assign is_lcd   = is_out && ( i_lsu_addr[14] && ~i_lsu_addr[13] && ~i_lsu_addr[12]);
  assign is_sw    = is_in  && ( i_lsu_addr[16] && ~i_lsu_addr[13]);

  //data memory
  memory u_memory (
    .i_clk          (i_clk),
    .i_reset        (i_reset),
    .i_func3        (i_func3),
    .i_addr         (dmem_ptr),
    .i_wdata        (st_wdata),
    .i_bmask_align  (bmask_align),
    .i_bmask_misalign(bmask_misalign),
    .i_wren         (mem_wren),
    .o_rdata        (dmem)
  );

  // Data path control
  always_comb begin
    mem_wren  = 1'b0;
    ld_data   = 32'b0;
    st_wdata  = i_st_data;

    ledr_next = o_io_ledr;
    ledg_next = o_io_ledg;
    lcd_next  = o_io_lcd;
    hex0_next = o_io_hex0; hex1_next = o_io_hex1;
    hex2_next = o_io_hex2; hex3_next = o_io_hex3;
    hex4_next = o_io_hex4; hex5_next = o_io_hex5;
    hex6_next = o_io_hex6; hex7_next = o_io_hex7;

    // Data memory
    if (is_dmem) begin
      if (i_lsu_wren) begin
        mem_wren = 1'b1;
        unique case (bmask_align)
          4'b0001, 4'b0010, 4'b0100: st_wdata = {24'b0, i_st_data[7:0]};
          4'b1000: st_wdata = i_st_data;
          4'b0011: st_wdata = {16'b0, i_st_data[15:0]};
          4'b1100: st_wdata = {i_st_data[15:0], 16'b0};
          4'b1111: st_wdata = i_st_data;
          default: mem_wren = 1'b0;
        endcase
      end else begin
        ld_data = dmem;
      end
    end 

    // Peripherals
    else if (i_lsu_wren && is_ledr) begin
      ledr_next = i_st_data;
    end 
    else if (i_lsu_wren && is_ledg) begin
      ledg_next = i_st_data;
    end 
    else if (i_lsu_wren && is_hex03) begin
      unique case (bmask_align)
        4'b0001: hex0_next = i_st_data[6:0];
        4'b0010: hex1_next = i_st_data[6:0];
        4'b0100: hex2_next = i_st_data[6:0];
        4'b1000: hex3_next = i_st_data[6:0];
        4'b1111: begin
          hex0_next = i_st_data[6:0];
          hex1_next = i_st_data[14:8];
          hex2_next = i_st_data[22:16];
          hex3_next = i_st_data[30:24];
        end
        default: begin
          hex0_next = 7'b1111111;
          hex1_next = 7'b1111111;
          hex2_next = 7'b1111111;
          hex3_next = 7'b1111111;
        end
      endcase
    end 
    else if (i_lsu_wren && is_hex47) begin
      unique case (bmask_align)
        4'b0001: hex4_next = i_st_data[6:0];
        4'b0010: hex5_next = i_st_data[6:0];
        4'b0100: hex6_next = i_st_data[6:0];
        4'b1000: hex7_next = i_st_data[6:0];
        4'b1111: begin
          hex4_next = i_st_data[6:0];
          hex5_next = i_st_data[14:8];
          hex6_next = i_st_data[22:16];
          hex7_next = i_st_data[30:24];
        end
        default: begin
          hex4_next = 7'b1111111;
          hex5_next = 7'b1111111;
          hex6_next = 7'b1111111;
          hex7_next = 7'b1111111;
        end
      endcase
    end 
    else if (i_lsu_wren && is_lcd) begin
      lcd_next = i_st_data;
    end 
    else if (!i_lsu_wren && is_sw) begin
      ld_data = i_io_sw;
    end
  end

  // Sequential update
  always_ff @(posedge i_clk or negedge i_reset) begin
    if (!i_reset) begin
      o_io_ledr <= 32'b0;
      o_io_ledg <= 32'b0;
      o_io_lcd  <= 32'b0;
      o_io_hex0 <= 7'b1111111;
      o_io_hex1 <= 7'b1111111;
      o_io_hex2 <= 7'b1111111;
      o_io_hex3 <= 7'b1111111;
      o_io_hex4 <= 7'b1111111;
      o_io_hex5 <= 7'b1111111;
      o_io_hex6 <= 7'b1111111;
      o_io_hex7 <= 7'b1111111;
    end else if (i_lsu_wren) begin
      o_io_ledr <= ledr_next;
      o_io_ledg <= ledg_next;
      o_io_lcd  <= lcd_next;
      o_io_hex0 <= hex0_next;
      o_io_hex1 <= hex1_next;
      o_io_hex2 <= hex2_next;
      o_io_hex3 <= hex3_next;
      o_io_hex4 <= hex4_next;
      o_io_hex5 <= hex5_next;
      o_io_hex6 <= hex6_next;
      o_io_hex7 <= hex7_next;
    end
  end

  // Load output
  always_comb begin
    o_ld_data = ld_data;
  end

endmodule

