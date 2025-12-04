module mem (
  input  logic        clk, we,
  input  logic [31:0] address, writedata,
  output logic [31:0] readdata);

  logic  [31:0] RAM [0:255];

  // initialize memory with instructions and data
  initial
    $readmemh("./riscv.hex", RAM);


  // regular port (read/write)
  always_ff @(posedge clk)
  begin
    if (we) begin
      

      RAM[address[31:2]] <= writedata;
    end
    readdata <= RAM[address[31:2]];

  end
endmodule