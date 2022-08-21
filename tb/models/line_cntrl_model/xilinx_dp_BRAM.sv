/*******************************************************************************
-- Title      : VGA Controller - Single Port BRAM
-- Project    : VGA Controller
********************************************************************************
-- File       : xilinx_dp_BRAM.sv
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2022-06-26
-- Design     : xilinx_single_port_ram
-- Platform   : -
-- Standard   : SystemVerilog '17
********************************************************************************
-- Description: Modified code taken from the single port BRAM taken from
--              Xilinx templates.(To become a dual port RAM in future)
********************************************************************************
-- Revisions:
-- Date        Version  Author  Description
-- 2022-07-01  1.0      TZS     Created
-- 2022-07-22  1.1      TZS     Modified to single port RAM
*******************************************************************************/                 
module xilinx_single_port_ram #(
  parameter RAM_WIDTH = 18,                       // Specify RAM data width
  parameter RAM_DEPTH = 1024,                     // Specify RAM depth (number of entries)
  parameter INIT_FILE = "/home/tom/Development/VGA_Controller/supporting_apps/mem_file_gen/mem_file.mem" // Specify name/location of RAM initialization file if using one (leave blank if not)
) (
  input  logic [$clog2(RAM_DEPTH-1)-1:0] addra,  // Port A address bus, width determined from RAM_DEPTH
  input  logic [RAM_WIDTH-1:0] dina,           // Port A RAM input data
  input  logic clka,                           // Clock
  input  logic wea,                            // Port A write enable
  input  logic ena,                            // Port A RAM Enable, for additional power savings, disable port when not in use
  input  logic rst,
  output logic [RAM_WIDTH-1:0] douta          // Port A RAM output data
);

  logic [RAM_WIDTH-1:0] BRAM [RAM_DEPTH-1:0];

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

  always @(posedge clka) begin
    if (ena) begin
      if (wea)
        BRAM[addra] <= dina;
      if (rst)
        douta <= 0;
      else 
        douta <= BRAM[addra];
    end
  end

endmodule
