/*******************************************************************************
-- Title      : VGA Frame Buffer Wrapper
-- Project    : VGA Controller
********************************************************************************
-- File       : frame_buffer.sv
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2022-08-27
-- Design     : frame_buffer
-- Platform   : -
-- Standard   : SystemVerilog '17
********************************************************************************
-- Description: VGA frame buffer model written in SV
********************************************************************************
-- Revisions:
-- Date        Version  Author  Description
-- 2022-08-27  1.0      TZS     Created
*******************************************************************************/

module frame_buffer #(
  parameter FBUFF_WIDTH = 60, 
  parameter FBUFF_DEPTH = 3840
) (
  input  logic [$clog2(FBUFF_DEPTH-1)-1:0] addra,
  input  logic [FBUFF_WIDTH-1:0]           dina,           
  input  logic                             clka,                           
  input  logic                             wea,                            
  input  logic                             ena,
  output logic [FBUFF_WIDTH-1:0]           douta    
);

  wire [FBUFF_WIDTH-1:0] douta_s;

  assign douta = douta_s;

  xilinx_single_port_ram #(
    .RAM_WIDTH( FBUFF_WIDTH ),
    .RAM_DEPTH( FBUFF_DEPTH ),
    .INIT_FILE( "" )
  ) i_xilinx_sp_ram (
    .addra ( addra ),
    .dina  ( dina  ),
    .clka  ( clka  ),
    .wea   ( wea   ),
    .ena   ( ena   ),
    .douta ( douta_s )
  );

endmodule