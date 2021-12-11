

module vga_mem #(
  RAM_WIDTH = 72,
  RAM_DEPTH = 480
) 
(
  input  logic [$clog2(RAM_DEPTH)-1:0] addr_in,
  input  logic re_in,
  output logic [RAM_WIDTH-1:0] data_out
);

  logic [RAM_WIDTH-1:0]tmp_data;
  logic [RAM_DEPTH-1:0][RAM_WIDTH-1:0] ram;

  assign data_out = tmp_data;

  initial begin
    ram[0] = '1;
    for(int idx = 1; idx < RAM_DEPTH; idx++) begin 
      ram[idx] = '0;
    end
  end

  always_comb begin
    if (~re_in) begin
      tmp_data = '0;
    end else begin
      tmp_data = ram[addr_in];
    end
  end

endmodule
