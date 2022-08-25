/*******************************************************************************
-- Title      : VGA Line Buffers Wrapper
-- Project    : VGA Controller
********************************************************************************
-- File       : line_buffers.sv
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2022-08-25
-- Design     : line_buffers
-- Platform   : -
-- Standard   : SystemVerilog '17
********************************************************************************
-- Description: VGA line buffers model written in SV
********************************************************************************
-- Revisions:
-- Date        Version  Author  Description
-- 2022-08-25  1.0      TZS     Created
*******************************************************************************/

module line_buffers #(
  parameter COLR_PXL_WIDTH  =  12,
  parameter TILE_WIDTH      =   4,
  parameter WIDTH_PX        = 640,
  parameter TILE_PER_LINE   = WIDTH_PX / TILE_WIDTH, // tile is 4 pixels wide (640/4)
  parameter TILE_CTR_WIDTH  = $clog2(TILE_PER_LINE)
) (
  input  logic                      clk_i,
  input  logic                      rstn_i,
  input  logic [1:0]                buff_fill_req_i,
  input  logic [1:0]                buff_sel_i,
  input  logic [TILE_CTR_WIDTH-1:0] disp_pxl_id_i,
  output logic [1:0]                buff_fill_done_o,
  output logic [COLR_PXL_WIDTH-1:0] disp_pxl_o
);

  localparam BUFF_ADDR_WIDTH = $clog2(TILE_PER_LINE-1);

  logic rst_s;

  logic [1:0][BUFF_ADDR_WIDTH-1:0] addra_s;
  logic [1:0][COLR_PXL_WIDTH-1:0]  dina_s;
  logic [1:0]                      wea_s;
  logic [1:0]                      ena_s;
  logic [1:0][COLR_PXL_WIDTH-1:0]  douta_s;

  logic [1:0] fill_in_progress_r;
  logic [1:0] buff_fill_done_r;

  assign rst_s = ~rstn_i;

  genvar buff_idx;
  generate
    for(buff_idx = 0; buff_idx < 2; buff_idx++) begin
      xilinx_single_port_ram #(
        .RAM_WIDTH (COLR_PXL_WIDTH),
        .RAM_DEPTH (TILE_PER_LINE),
        .INIT_FILE ("")
      ) i_buffer_A (
        .addra (addra_s[buff_idx]),     
        .dina  (dina_s[buff_idx]),    
        .clka  (clk_i),    
        .wea   (wea_s[buff_idx]),   
        .ena   (ena_s[buff_idx]),   
        .rst   (rst_s),   
        .douta (douta_s[buff_idx])   
      );  
    end
  endgenerate

  // set buffer fill in progress flag
  always_ff @(posedge clk_i or negedge rstn_i) begin : in_progress
    
    if (~rstn_i) begin 
      fill_in_progress_r <= '0;
    end else begin 
      // prioritise buffer_A
      if (fill_in_progress_r == 2'b00) begin 
        if (buff_fill_req_i[0] == 1'b1) begin 
          fill_in_progress_r[0] <= 1'b1;
        end else if (buff_fill_req_i[1] == 1'b1) begin 
          fill_in_progress_r[1] <= 1'b1;
        end
      end else begin
        if (buff_fill_done_r[0] == 1'b1) begin 
          fill_in_progress_r[0] <= 1'b0; 
        end else if (buff_fill_done_r[1] == 1'b1) begin
          fill_in_progress_r[1] <= 1'b0; 
        end
      end
    end
  
  end


endmodule