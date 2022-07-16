/*******************************************************************************
-- Title      : VGA Controller - Dual Port BRAM
-- Project    : VGA Controller
********************************************************************************
-- File       : xilinx_dp_BRAM.sv
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2022-06-26
-- Design     : xilinx_dp_BRAM
-- Platform   : -
-- Standard   : SystemVerilog '17
********************************************************************************
-- Description: Modified code taken from the true dual port BRAM taken from
--              Xilinx templates.
********************************************************************************
-- Revisions:
-- Date        Version  Author  Description
-- 2022-07-01  1.0      TZS     Created
*******************************************************************************/                 
module xilinx_true_dual_port_read_first_1_clock_ram #(
  parameter RAM_WIDTH = 18,                       // Specify RAM data width
  parameter RAM_DEPTH = 1024,                     // Specify RAM depth (number of entries)
  parameter INIT_FILE = ""                        // Specify name/location of RAM initialization file if using one (leave blank if not)
) (
  input [$clog2(RAM_DEPTH-1)-1:0] addra,  // Port A address bus, width determined from RAM_DEPTH
  input [$clog2(RAM_DEPTH-1)-1:0] addrb,  // Port B address bus, width determined from RAM_DEPTH
  input [RAM_WIDTH-1:0] dina,           // Port A RAM input data
  input [RAM_WIDTH-1:0] dinb,           // Port B RAM input data
  input clka,                           // Clock
  input wea,                            // Port A write enable
  input web,                            // Port B write enable
  input ena,                            // Port A RAM Enable, for additional power savings, disable port when not in use
  input enb,                            // Port B RAM Enable, for additional power savings, disable port when not in use
  output [RAM_WIDTH-1:0] douta,         // Port A RAM output data
  output [RAM_WIDTH-1:0] doutb          // Port B RAM output data
);

  logic [RAM_WIDTH-1:0] BRAM [RAM_DEPTH-1:0];
  logic [RAM_WIDTH-1:0] ram_data_a = {RAM_WIDTH{1'b0}};
  logic [RAM_WIDTH-1:0] ram_data_b = {RAM_WIDTH{1'b0}};

  // The following code either initializes the memory values to a specified file or to all zeros to match hardware
  generate
    if (INIT_FILE != "") begin: use_init_file
      initial
        $readmemb(INIT_FILE, BRAM, 0, RAM_DEPTH-1);
    end else begin: init_bram_to_zero
      integer ram_index;
      initial
        for (ram_index = 0; ram_index < RAM_DEPTH; ram_index = ram_index + 1)
          BRAM[ram_index] = {RAM_WIDTH{1'b0}};
    end
  endgenerate

  always @(posedge clka)
    if (ena) begin
      if (wea)
        BRAM[addra] <= dina;
      ram_data_a <= BRAM[addra];
    end

  always @(posedge clka)
    if (enb) begin
      if (web)
        BRAM[addrb] <= dinb;
      ram_data_b <= BRAM[addrb];
    end

  assign douta = ram_data_a;
  assign doutb = ram_data_b;

endmodule
