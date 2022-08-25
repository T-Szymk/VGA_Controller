/*******************************************************************************
-- Title      : Top module of line controller model
-- Project    : VGA Controller
********************************************************************************
-- File       : top.sv
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2022-08-25
-- Design     : top
-- Platform   : -
-- Standard   : SystemVerilog '17
********************************************************************************
-- Description: Top module for line controller model written in SV
********************************************************************************
-- Revisions:
-- Date        Version  Author  Description
-- 2022-08-25  1.0      TZS     Created
*******************************************************************************/ 

module top;

  timeunit 1ns/1ps;

  parameter SIMULATION_RUNTIME = 1us;
  parameter CLK_PERIOD         = 40ns;

  parameter TOP_CLK_FREQ_HZ   =   100_000_000;
  parameter TOP_CLK_PERIOD_NS = 1_000_000_000 / TOP_CLK_FREQ_HZ;
  parameter PXL_CLK_FREQ_HZ   =    25_000_000;

  // height and width of display area in pixels
  parameter HEIGHT_PX     = 480;
  parameter WIDTH_PX      = 640;
  // number of pixels in each h_sync period
  parameter H_SYNC_PX     = 96;
  // number of pixels in each horiz. back porch period
  parameter H_B_PORCH_PX  = 48;
  // number of pixels in each horiz. front porch period
  parameter H_F_PORCH_PX  = 16;
  // number of lines in each v_sync period
  parameter V_SYNC_LNS    = 2;
  // number of lines in each vert. back porch period
  parameter V_B_PORCH_LNS = 33;
  // number of lines in each vert. front porch period
  parameter V_F_PORCH_LNS = 10;
  // counter max and associated valueswidths
  parameter PXL_CTR_MAX   = H_F_PORCH_PX + WIDTH_PX + 
                            H_B_PORCH_PX + H_SYNC_PX;
  parameter LINE_CTR_MAX  = V_F_PORCH_LNS + HEIGHT_PX + 
                            V_B_PORCH_LNS + V_SYNC_LNS;
  
  parameter V_SYNC_MAX_LNS    = V_SYNC_LNS;
  parameter V_B_PORCH_MAX_LNS = V_SYNC_MAX_LNS + V_B_PORCH_LNS;
  parameter V_DISP_MAX_LNS    = V_B_PORCH_MAX_LNS + HEIGHT_PX;
  parameter V_F_PORCH_MAX_LNS = V_DISP_MAX_LNS + V_F_PORCH_LNS;
  parameter H_SYNC_MAX_PX     = H_SYNC_PX;
  parameter H_B_PORCH_MAX_PX  = H_SYNC_MAX_PX + H_B_PORCH_PX;
  parameter H_DISP_MAX_PX     = H_B_PORCH_MAX_PX + WIDTH_PX;
  parameter H_F_PORCH_MAX_PX  = H_DISP_MAX_PX + H_F_PORCH_PX;
  
  parameter DISP_PXL_MAX      = HEIGHT_PX * WIDTH_PX;

   // depth of each colour
  parameter DEPTH_COLR     = 4;
  parameter MONO_PXL_WIDTH = DEPTH_COLR;
  parameter COLR_PXL_WIDTH = DEPTH_COLR * 3;

  // define MONO/COLR encoding
  `ifdef MONO 
    parameter PXL_WIDTH = MONO_PXL_WIDTH;
  `else
    parameter PXL_WIDTH = COLR_PXL_WIDTH;
  `endif

  // use max value to calculate bit width of counter
  parameter PXL_CTR_WIDTH  = $clog2(PXL_CTR_MAX - 1);
  parameter LN_CTR_WIDTH   = $clog2(LINE_CTR_MAX - 1);

  // set size n of tile (nxn). If not tiling is desired, set to 1. 
  parameter TILE_WIDTH     = 4;
  parameter TILE_PER_LINE   = PXL_CTR_MAX / TILE_WIDTH;
  parameter TILE_CTR_WIDTH = $clog2(TILE_PER_LINE);

  parameter TILE_PER_ROW = 5; // tile count per row of memory

  parameter BUFF_READ_DELAY_CYCLES = 2 * ((640 / TILE_WIDTH) / TILE_PER_ROW); // simulate delay of reading memory, 2 cycles per row

  logic clk  = '0;
  logic rstn = '0;

  logic [1:0]                buff_fill_done_to_DUT = '0;
  logic [PXL_CTR_WIDTH-1:0]  pxl_cntr_to_DUT = '0;
  logic [LN_CTR_WIDTH-1:0]   ln_cntr_to_DUT = '0;
  logic [1:0]                DUT_to_buff_fill_req;
  logic [1:0]                DUT_to_buff_sel;
  logic [TILE_CTR_WIDTH-1:0] DUT_to_disp_pxl_id;

  line_buff_ctrl #(
  .WIDTH_PX          ( WIDTH_PX          ),          
  .HEIGHT_LNS        ( HEIGHT_PX         ),        
  .H_B_PORCH_MAX_PX  ( H_B_PORCH_MAX_PX  ),  
  .V_B_PORCH_MAX_LNS ( V_B_PORCH_MAX_LNS ), 
  .TILE_WIDTH        ( TILE_WIDTH        ),        
  .PXL_CTR_WIDTH     ( PXL_CTR_WIDTH     ),     
  .LN_CTR_WIDTH      ( LN_CTR_WIDTH      ),      
  .TILE_PER_LINE      ( TILE_PER_LINE      ),      
  .TILE_CTR_WIDTH    ( TILE_CTR_WIDTH    )
  ) i_dut (
  .clk_i            ( clk                   ),
  .rstn_i           ( rstn                  ),
  .buff_fill_done_i ( buff_fill_done_to_DUT ),
  .pxl_cntr_i       ( pxl_cntr_to_DUT       ),
  .ln_cntr_i        ( ln_cntr_to_DUT        ),
  .buff_fill_req_o  ( DUT_to_buff_fill_req  ),
  .buff_sel_o       ( DUT_to_buff_sel       ),
  .disp_pxl_id_o    ( DUT_to_disp_pxl_id    )
);

  initial begin
    forever begin
      clk = 0;
      #(CLK_PERIOD/2);
      clk = 1;
      #(CLK_PERIOD/2);
    end
    
  end

  initial begin 
    #(5*CLK_PERIOD) rstn = 1;
  end


  /* LINE AND PIXEL COUNTER GENERATION ****************************************/
  
  always_ff @(posedge clk or negedge rstn) begin 
  
    if (~rstn) begin 

      pxl_cntr_to_DUT <= '0; 
      ln_cntr_to_DUT  <= '0;

    end else begin
      
      if (pxl_cntr_to_DUT == (WIDTH_PX - 1)) begin 
        pxl_cntr_to_DUT <= '0;
        if (ln_cntr_to_DUT == (HEIGHT_PX - 1)) begin 
          ln_cntr_to_DUT <= '0;
        end else begin 
          ln_cntr_to_DUT <= ln_cntr_to_DUT + 1;
        end
      end else begin 
        pxl_cntr_to_DUT <= pxl_cntr_to_DUT + 1;
      end

    end
  end
  /****************************************************************************/

  /* simulate memory buff response ********************************************/

  genvar buff_idx;
  generate
    for(buff_idx = 0; buff_idx < 2; buff_idx++) begin 
      initial begin 
        forever begin 
          @(posedge DUT_to_buff_fill_req[buff_idx]) begin
            if (DUT_to_buff_fill_req[buff_idx] == 1) begin 
              #(BUFF_READ_DELAY_CYCLES * CLK_PERIOD);
              buff_fill_done_to_DUT[buff_idx] = 1;
              #CLK_PERIOD;
              buff_fill_done_to_DUT[buff_idx] = 0;
            end 
          end
        end
      end
    end
  endgenerate

  /****************************************************************************/

endmodule