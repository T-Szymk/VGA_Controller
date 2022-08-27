/*******************************************************************************
-- Title      : Top module of line controller model
-- Project    : VGA Controller
********************************************************************************
-- File       : top.sv
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2022-08-27
-- Design     : top
-- Platform   : -
-- Standard   : SystemVerilog '17
********************************************************************************
-- Description: Top module for line controller model written in SV
********************************************************************************
-- Revisions:
-- Date        Version  Author  Description
-- 2022-08-27  1.0      TZS     Created
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

  parameter PXL_WIDTH = COLR_PXL_WIDTH;


  // use max value to calculate bit width of counter
  parameter PXL_CTR_WIDTH  = $clog2(PXL_CTR_MAX - 1);
  parameter LN_CTR_WIDTH   = $clog2(LINE_CTR_MAX - 1);

  // set size n of tile (nxn). If not tiling is desired, set to 1. 
  parameter TILE_WIDTH     = 4;
  parameter TILE_PER_LINE  = WIDTH_PX / TILE_WIDTH;
  parameter TILE_CTR_WIDTH = $clog2(TILE_PER_LINE);
  parameter TOTAL_TILES    = (HEIGHT_PX * WIDTH_PX) / (TILE_WIDTH ** 2);

  /* The following items should be considered when selecting the row width:
     1) Whether the number of tiles in a frame line is cleanly divisible by the 
        number of tiles within a row of memory (i.e. tiles_per_line / tiles_per_row
        has no remainder). This is to keep the memory access logic simple.
     2) The memory size of the target. 
     e.g. Xilinx 7-series SDP = < 72bits, and as pixels/tiles are 12-bits wide, 
     ideally reach row would contain 6 tiles. However, this is not a factor of 
     the 160 (number of tiles per line) and so a value of 5 should be used.  */
  parameter TILE_PER_ROW = 5; // tile count per row of memory
  parameter FBUFF_DATA_WIDTH = TILE_PER_ROW * PXL_WIDTH;
  parameter FBUFF_DEPTH      = (TOTAL_TILES / TILE_PER_ROW);
  parameter FBUFF_ADDR_WIDTH = $clog2(FBUFF_DEPTH);

  logic clk;
  logic rstn;
  logic init_done_s;

  wire  [1:0]                buff_fill_done_s;
  wire  [1:0]                buff_fill_req_s;
  wire  [1:0]                buff_sel_s;
  wire  [TILE_CTR_WIDTH-1:0] disp_pxl_id_s;

  logic [PXL_CTR_WIDTH-1:0]  pxl_cntr_s;
  logic [LN_CTR_WIDTH-1:0]   ln_cntr_s;

  wire  [PXL_WIDTH-1:0]        disp_pxl_s;

  wire  [FBUFF_ADDR_WIDTH-1:0] fbuff_addr_s;
  wire                         fbuff_en_s;
  wire  [FBUFF_DATA_WIDTH-1:0] fbuff_data_in_s;
  wire                         fbuff_wen_s;
  wire  [FBUFF_DATA_WIDTH-1:0] fbuff_data_out_s;
  
  wire  [FBUFF_ADDR_WIDTH-1:0] dut_fbuff_addr_s;
  wire                         dut_fbuff_en_s;

  logic [FBUFF_ADDR_WIDTH-1:0] init_fbuff_addr_s;
  logic                        init_fbuff_en_s;
  logic [FBUFF_DATA_WIDTH-1:0] init_fbuff_data_in_s;
  logic                        init_fbuff_wen_s;

  logic [FBUFF_DEPTH-1:0][TILE_PER_ROW-1:0][PXL_WIDTH-1:0] ref_fbuff_array;

  assign rstn = init_done_s; // reset is de-asserted once initialisation is complete
  // mux between init signals and dut signals to allow memory initialisation
  assign fbuff_addr_s    = (init_done_s == 1'b1) ? dut_fbuff_addr_s : init_fbuff_addr_s;
  assign fbuff_en_s      = (init_done_s == 1'b1) ? dut_fbuff_en_s : init_fbuff_en_s;
  assign fbuff_data_in_s = (init_done_s == 1'b1) ? '0 : init_fbuff_data_in_s;
  assign fbuff_wen_s     = (init_done_s == 1'b1) ? '0 : init_fbuff_wen_s;

  line_buff_ctrl #(
    .WIDTH_PX          ( WIDTH_PX          ),          
    .HEIGHT_LNS        ( HEIGHT_PX         ),        
    .H_B_PORCH_MAX_PX  ( H_B_PORCH_MAX_PX  ),  
    .V_B_PORCH_MAX_LNS ( V_B_PORCH_MAX_LNS ), 
    .TILE_WIDTH        ( TILE_WIDTH        ),        
    .PXL_CTR_WIDTH     ( PXL_CTR_WIDTH     ),     
    .LN_CTR_WIDTH      ( LN_CTR_WIDTH      ),      
    .TILE_PER_LINE     ( TILE_PER_LINE     ),      
    .TILE_CTR_WIDTH    ( TILE_CTR_WIDTH    )
  ) i_line_buff_ctrl (
    .clk_i            ( clk              ),
    .rstn_i           ( rstn             ),
    .buff_fill_done_i ( buff_fill_done_s ),
    .pxl_cntr_i       ( pxl_cntr_s       ),
    .ln_cntr_i        ( ln_cntr_s        ),
    .buff_fill_req_o  ( buff_fill_req_s  ),
    .buff_sel_o       ( buff_sel_s       ),
    .disp_pxl_id_o    ( disp_pxl_id_s    )
  );

  line_buffers #(
    .COLR_PXL_WIDTH   ( PXL_WIDTH        ),         
    .TILE_WIDTH       ( TILE_WIDTH       ),     
    .WIDTH_PX         ( WIDTH_PX         ),   
    .FBUFF_ADDR_WIDTH ( FBUFF_ADDR_WIDTH ),           
    .FBUFF_DATA_WIDTH ( FBUFF_DATA_WIDTH ),           
    .FBUFF_DEPTH      ( FBUFF_DEPTH      ),      
    .TILES_PER_ROW    ( TILE_PER_ROW     ),        
    .TILE_PER_LINE    ( TILE_PER_LINE    ),        
    .TILE_CTR_WIDTH   ( TILE_CTR_WIDTH   )
  ) i_line_buffers (
    .clk_i            ( clk              ),  
    .rstn_i           ( rstn             ),   
    .buff_fill_req_i  ( buff_fill_req_s  ),            
    .buff_sel_i       ( buff_sel_s       ),       
    .disp_pxl_id_i    ( disp_pxl_id_s    ),          
    .fbuff_data_i     ( fbuff_data_out_s ),         
    .buff_fill_done_o ( buff_fill_done_s ),             
    .disp_pxl_o       ( disp_pxl_s       ),       
    .fbuff_addr_o     ( dut_fbuff_addr_s ),         
    .fbuff_en_o       ( dut_fbuff_en_s   )      
  );

  frame_buffer #(
    .RAM_WIDTH( FBUFF_DATA_WIDTH ),
    .RAM_DEPTH( FBUFF_DEPTH )
  ) i_frame_buffer (
    .addra ( fbuff_addr_s     ),
    .dina  ( fbuff_data_in_s  ),
    .clka  ( clk              ),
    .wea   ( fbuff_wen_s      ),
    .ena   ( fbuff_en_s       ),
    .douta ( fbuff_data_out_s )
  );

  initial begin
    forever begin
      clk = 0;
      #(CLK_PERIOD/2);
      clk = 1;
      #(CLK_PERIOD/2);
    end
    
  end

  initial begin // initialise FBUFF memory to known test pattern
    
    automatic bit [DEPTH_COLR-1:0] counter = '0;

    init_fbuff_data_in_s = '0;
    init_fbuff_addr_s    = '0;
    init_fbuff_en_s      = '0;
    init_fbuff_wen_s     = '0;
    init_done_s          = '0;
    ref_fbuff_array      = '0; // reference array to be used to verify display pixel values
    
    #(5*CLK_PERIOD);
    $display("%0tns: Initialising frame buffer.", $time);

    init_fbuff_en_s = 1'b1;

    for (int row_id = 0; row_id < FBUFF_DEPTH; row_id++) begin
      for(int tile_idx = 0; tile_idx < TILE_PER_ROW; tile_idx++) begin 
        init_fbuff_data_in_s[(tile_idx * PXL_WIDTH)+:PXL_WIDTH]    = {3{counter}};
        ref_fbuff_array[row_id][tile_idx] = {3{counter}};
      end
        init_fbuff_addr_s = row_id;
        init_fbuff_wen_s  = 1'b1;
        counter++;
        @(posedge clk);
    end
    
    init_fbuff_wen_s  = 1'b0;
    init_fbuff_en_s   = 1'b0;
    init_done_s       = 1'b1;

    @(posedge clk);
    $display("%0tns: Frame buffer initialised.", $time);
  end


  /* LINE AND PIXEL COUNTER GENERATION ****************************************/
  
  always_ff @(posedge clk or negedge rstn) begin 
  
    if (~rstn) begin 

      pxl_cntr_s <= '0; 
      ln_cntr_s  <= '0;

    end else begin
      
      if (pxl_cntr_s == (PXL_CTR_MAX - 1)) begin 
        pxl_cntr_s <= '0;
        if (ln_cntr_s == (LINE_CTR_MAX - 1)) begin 
          ln_cntr_s <= '0;
        end else begin 
          ln_cntr_s <= ln_cntr_s + 1;
        end
      end else begin 
        pxl_cntr_s <= pxl_cntr_s + 1;
      end

    end
  end
  /****************************************************************************/



endmodule