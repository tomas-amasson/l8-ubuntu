module mem (
  input  logic        clk, we,
  input  logic [31:0] address, writedata,
  output logic [31:0] readdata,);

  reg    [31:0] shifted;
  reg    [31:0] old, new_mem;
  reg    [3:0]  mask;  
  logic  [31:0] RAM [0:255];

  // initialize memory with instructions and data
  initial
    $readmemh("../riscv.hex", RAM);

  always @(posedge clk) begin
    case(f3)
    3'b000: begin //sb
      case(address[1:0])
      2'b00: mask = 4'b0001;
      2'b01: mask = 4'b0010;
      2'b10: mask = 4'b0100;
      2'b11: mask = 4'b1000;
      endcase
      shifted = writedata << (8 * address[1:0]);
    end

    3'b001: begin //sh
      case(address[1])
      1'b0: mask = 4'b0011;
      1'b1: mask = 4'b1100;
      endcase
      shifted = writedata << (16 * address[1]);
    end

    3'b010: begin //sw
      mask = 4'b1111; 
      shifted = writedata;
    end
    endcase

      old = RAM[address[31:2]];
      new_mem[7:0] = mask[0] ? shifted[7:0] : old[7:0];
      new_mem[15:8] = mask[1] ? shifted[15:8] : old[15:8];
      new_mem[23:16] = mask[2] ? shifted[23:16] : old[23:16];
      new_mem[31:24] = mask[3] ? shifted[31:24] : old[31:24];

  end



  // regular port (read/write)
  always_ff @(posedge clk)
  begin
    if (we) begin
      

      RAM[address[31:2]] <= new_mem;
    end
    readdata <= RAM[address[31:2]];

  end

  // video port (read only)
  always_ff @(posedge clk)
    videodata <= RAM[videoaddress[31:2]];
endmodule