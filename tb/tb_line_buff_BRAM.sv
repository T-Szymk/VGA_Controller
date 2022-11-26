/*******************************************************************************
-- Title      : Testbench for VGA memory interface
-- Project    : VGA Controller
********************************************************************************
-- File       : tb_vga_memory_intf.sv
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2022-11-19
-- Design     : top
-- Platform   : -
-- Standard   : SystemVerilog '17
********************************************************************************
-- Description: Top module for line controller model written in SV
********************************************************************************
-- Revisions:
-- Date        Version  Author  Description
-- 2022-11-19  1.0      TZS     Created
*******************************************************************************/ 

module tb_vga_memory_intf;

  timeunit 1ns/1ps;

  parameter COLR_PXL_WIDTH   =   12;
  parameter FBUFF_DEPTH      = 4800;
  parameter TILE_WIDTH       =    4;
  parameter WIDTH_PX         =  640;
  parameter TILE_PER_LINE    = WIDTH_PX / TILE_WIDTH; // tile is 4 pixels wide (640/4)
  parameter LBUFF_ADDR_WIDTH = $clog2(TILE_PER_LINE-1);
  parameter FBUFF_ADDR_WIDTH =   12;
  parameter FBUFF_DATA_WIDTH =   60;
  parameter TILES_PER_ROW    =    4;
  parameter TILE_COUNTER_WIDTH  = $clog2(TILES_PER_ROW);

  logic clk = 0;

  logic [1:0][LBUFF_ADDR_WIDTH-1:0] lbuff_addra_s;
  logic [1:0][COLR_PXL_WIDTH-1:0]   lbuff_dina_s;
  logic [1:0]                       lbuff_wea_r;
  logic [1:0]                       lbuff_ena_s;
  logic [1:0][COLR_PXL_WIDTH-1:0]   lbuff_douta_s;

  always #5 clk = ~clk;
  
  genvar buff_idx;
    for(buff_idx = 0; buff_idx < 2; buff_idx++) begin : generate_frame_buffs

      xilinx_sp_BRAM #(
        .RAM_WIDTH ( COLR_PXL_WIDTH   ),
        .RAM_DEPTH ( TILE_PER_LINE    ),
        .INIT_FILE ( ""               )
      ) i_line_buffer (
        .addra ( lbuff_addra_s[buff_idx] ),     
        .dina  ( lbuff_dina_s[buff_idx]  ),    
        .clka  ( clk                     ),    
        .wea   ( lbuff_wea_r[buff_idx]   ),   
        .ena   ( lbuff_ena_s[buff_idx]   ),
        .douta ( lbuff_douta_s[buff_idx] )   
      );  
    end

    initial begin 
    
      lbuff_addra_s = '0;           
      lbuff_dina_s  = '0;          
      lbuff_wea_r   = '0;         
      lbuff_ena_s   = '1;
      
      @(posedge clk);

      lbuff_wea_r = 2'h1;

      for(int row = 1; row <= TILE_PER_LINE; row++) begin 
        @(posedge clk);
        lbuff_addra_s[0] = row;
        lbuff_dina_s[0]  = row;        
      end
      
      @(posedge clk);
      lbuff_wea_r = '0;
      @(posedge clk);

      for(int row = 0; row <= TILE_PER_LINE; row++) begin 
        @(posedge clk);
        lbuff_addra_s[0] = row;       
      end
    
    end 

endmodule