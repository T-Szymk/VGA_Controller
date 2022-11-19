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
  
  parameter INIT_FILE = "";

  parameter SIMULATION_RUNTIME = 100ms;

  parameter PXL_CLK_FREQ_HZ   =    25_000_000;
  parameter PXL_CLK_PERIOD_NS = 1_000_000_000 / PXL_CLK_FREQ_HZ;

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
2) The memory size of the target. e.g. Xilinx 7-series SDP = < 72bits, and as
   pixels/tiles are 12-bits wide, ideally reach row would contain 6 tiles.
   However, this is not a factor of the 160. Additionally, to allow easy
   translation between the processing system AXI bus and the frame buffer, the
   number of tiles should be a power of 2. This is why a value of 4 tiles per
   row of the frame buffer should be used.  
*/
  parameter TILE_PER_ROW     = 4; // tile count per row of memory
  parameter FBUFF_DATA_WIDTH = TILE_PER_ROW * PXL_WIDTH;
  parameter FBUFF_DEPTH      = (TOTAL_TILES / TILE_PER_ROW);
  parameter FBUFF_ADDR_WIDTH = $clog2(FBUFF_DEPTH-1);
  parameter FBUFF_LATENCY    = 1;

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

  logic fbuff_read_req_s;
  logic fbuff_read_rsp_s;
  
  wire  [FBUFF_ADDR_WIDTH-1:0] dut_fbuff_addr_s;

  logic [FBUFF_ADDR_WIDTH-1:0] init_fbuff_addr_s;
  logic                        init_fbuff_en_s;
  logic [FBUFF_DATA_WIDTH-1:0] init_fbuff_data_in_s;
  logic                        init_fbuff_wen_s;

  logic [(HEIGHT_PX/4)-1:0][(WIDTH_PX/4)-1:0][PXL_WIDTH-1:0] ref_fbuff_array; // reference array to be used to verify display pixel values
  logic [PXL_WIDTH-1:0] ref_pixel = '0;

  int ref_tile_val  = 0;
  int ref_line_val  = 0;
  int frame_counter;

  int comparison_fail_count = 0;

  assign rstn = init_done_s; // reset is de-asserted once initialisation is complete
  // mux between init signals and dut signals to allow memory initialisation
  assign fbuff_addr_s    = (init_done_s == 1'b1) ? dut_fbuff_addr_s : init_fbuff_addr_s;
  assign fbuff_en_s      = (init_done_s == 1'b1) ?  1 : init_fbuff_en_s;
  assign fbuff_data_in_s = (init_done_s == 1'b1) ? '0 : init_fbuff_data_in_s;
  assign fbuff_wen_s     = (init_done_s == 1'b1) ? '0 : init_fbuff_wen_s;

  vga_line_buff_ctrl #(
    .width_px_g           ( WIDTH_PX          ),          
    .height_lns_g         ( HEIGHT_PX         ),
    .lbuff_latency_g      ( FBUFF_LATENCY     ),              
    .h_b_porch_max_px_g   ( H_B_PORCH_MAX_PX  ),  
    .v_b_porch_max_lns_g  ( V_B_PORCH_MAX_LNS ), 
    .tile_width_g         ( TILE_WIDTH        ),        
    .pxl_ctr_width_g      ( PXL_CTR_WIDTH     ),     
    .ln_ctr_width_g       ( LN_CTR_WIDTH      ),      
    .tiles_per_line_g     ( TILE_PER_LINE     ),      
    .tile_ctr_width_g     ( TILE_CTR_WIDTH    )
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

  vga_line_buffers #(
    .pxl_width_g        ( PXL_WIDTH        ),         
    .tile_width_g       ( TILE_WIDTH       ),     
    .fbuff_depth_g      ( FBUFF_DEPTH      ),
    .fbuff_addr_width_g ( FBUFF_ADDR_WIDTH ),   
    .fbuff_data_width_g ( FBUFF_DATA_WIDTH ),           
    .tiles_per_row_g    ( TILE_PER_ROW     ),      
    .tile_per_line_g    ( TILE_PER_LINE    ),        
    .lbuff_addr_width_g ( TILE_CTR_WIDTH   )
  ) i_line_buffers (
    .clk_i            ( clk              ),  
    .rstn_i           ( rstn             ),   
    .buff_fill_req_i  ( buff_fill_req_s  ),            
    .buff_sel_i       ( buff_sel_s       ),       
    .disp_pxl_id_i    ( disp_pxl_id_s    ),          
    .fbuff_data_i     ( fbuff_data_out_s ), 
    .fbuff_rd_rsp_i   ( fbuff_read_rsp_s ),        
    .buff_fill_done_o ( buff_fill_done_s ),             
    .disp_pxl_o       ( disp_pxl_s       ),
    .fbuff_rd_req_o   ( fbuff_read_req_s ),
    .fbuff_addra_o    ( dut_fbuff_addr_s )  
  );

  vga_frame_buffer #(
    .fbuff_addr_width_g ( FBUFF_ADDR_WIDTH ),
    .fbuff_data_width_g ( FBUFF_DATA_WIDTH ),
    .fbuff_depth_g      ( FBUFF_DEPTH      ),
    .init_file_g        ( INIT_FILE        )
  ) i_frame_buffer (
    .clk_i    ( clk              ),
    .rstn_i   ( rstn             ),
    .addra_i  ( fbuff_addr_s     ),
    .dina_i   ( fbuff_data_in_s  ),     
    .wea_i    ( fbuff_wen_s      ),   
    .ena_i    ( fbuff_en_s       ),   
    .rd_req_i ( fbuff_read_req_s ),
    .rd_rsp_o ( fbuff_read_rsp_s ),
    .douta_o  ( fbuff_data_out_s )
  );

  /* SIMULATION CLOCK GENERATION **********************************************/
  initial begin

    forever begin

      clk = 0;
      #(PXL_CLK_PERIOD_NS/2);
      clk = 1;
      #(PXL_CLK_PERIOD_NS/2);

      if ($time > SIMULATION_RUNTIME) begin 
        
        $display("Simulation complete.");
        if (comparison_fail_count) 
          $display("Result: FAILED - Fail Count: %d.", comparison_fail_count);
        else 
          $display("Result: PASSED.");
        $finish;
      
      end

    end
  end
  /****************************************************************************/

  /* FBUFF INITIALISATION *****************************************************/
  initial begin // initialise FBUFF memory to known test pattern
    
    automatic bit [DEPTH_COLR-1:0] counter             = '0; // max value == 0xf
    automatic bit                  count_direction     =  1; // 1 = increment
    automatic int                  tile_counter        = '0;
    automatic int                  line_counter        =  0;

    init_fbuff_data_in_s = '0;
    init_fbuff_addr_s    = '0;
    init_fbuff_en_s      = '0;
    init_fbuff_wen_s     = '0;
    init_done_s          = '0;
    ref_fbuff_array      = '0; 

    $timeformat(-9, 3, " ns");
    
    #(5*PXL_CLK_PERIOD_NS);
    $display("[%0t]: Initialising frame buffer.", $time);

    init_fbuff_en_s = 1'b1;
    
    /* initialise fbuff so that each scan line as different data from the 
       previous line and each tile has a different value from the previous tile 
    */
    for (int fbuff_row = 0; fbuff_row < FBUFF_DEPTH; fbuff_row++) begin
      for(int tile = 0; tile < TILE_PER_ROW; tile++) begin 
        
        init_fbuff_data_in_s[(tile * PXL_WIDTH)+:PXL_WIDTH] = {3{counter}};
        ref_fbuff_array[line_counter][tile_counter] = {3{counter}};
        
        // invert count direction once end of line is reached
        if (tile_counter == TILE_PER_LINE - 1) begin 
          
          tile_counter    = 0;
          count_direction = ~count_direction;
          counter         = (count_direction) ? '0 : '1;

          line_counter = (line_counter == ((HEIGHT_PX/4) - 1)) ? 0 : line_counter + 1;

        end else begin

          tile_counter++; 
          counter = (count_direction) ? counter + 1 : counter - 1;

        end

      end
      
      init_fbuff_addr_s = fbuff_row;
      init_fbuff_wen_s  = 1'b1;
       
      @(posedge clk);
      
    end

    init_fbuff_wen_s  = 1'b0;
    init_fbuff_en_s   = 1'b0;
    init_done_s       = 1'b1;

    @(posedge clk);

    $display("[%0t]: Frame buffer initialised.", $time);

  end
  /****************************************************************************/

  /* PIXEL, LINE AND FRAME COUNTER GENERATION *********************************/
  
  always_ff @(posedge clk or negedge rstn) begin 
  
    if (~rstn) begin 

      pxl_cntr_s    <= '0; 
      ln_cntr_s     <= '0;
      frame_counter <= '0;

    end else begin
      
      if (pxl_cntr_s == (PXL_CTR_MAX - 1)) begin 

        pxl_cntr_s <= '0;
        
        if (ln_cntr_s == (LINE_CTR_MAX - 1)) begin 
          
          ln_cntr_s     <= '0;
          frame_counter <= frame_counter + 1; // incr. frame counter for debug purposes
        
        end else begin 
          
          ln_cntr_s <= ln_cntr_s + 1;
        
        end
      
      end else begin 
        
        pxl_cntr_s <= pxl_cntr_s + 1;
      
      end

    end
  end
  /****************************************************************************/

  /* CHECKING OF TEST PATTERN *************************************************/

  initial begin

    forever begin

      /* If pixel counter is greater than minimum and less than max If line
         counter is greater than minimum and less than max subtract minimum 
         pixel counter value from current pixel counter value and divide by 4 
         subtract minimum line counter value from current line counter value and 
         divide by 4 compare output pixel value with reference array Assert 
         values are the same
      */

      @(negedge clk);   

      if( (ln_cntr_s >= V_B_PORCH_MAX_LNS) && 
          (ln_cntr_s < V_DISP_MAX_LNS)     &&
          (pxl_cntr_s >= (H_B_PORCH_MAX_PX)) && 
          (pxl_cntr_s < (H_DISP_MAX_PX)) ) begin 

        ref_tile_val = (pxl_cntr_s - (H_B_PORCH_MAX_PX)) / 4;
        ref_line_val = (ln_cntr_s  - V_B_PORCH_MAX_LNS) / 4;

        ref_pixel = ref_fbuff_array[ref_line_val][ref_tile_val];

        a0_display_pxl : assert (ref_pixel == disp_pxl_s) else
          $error("Displayed pixel != Reference pixel. disp_pxl_s = %x, ref_pixel = %x", disp_pxl_s, ref_pixel);   
        
        if (ref_pixel != disp_pxl_s) begin 
          comparison_fail_count++;
        end 

      end else begin 

        ref_tile_val = '0;
        ref_line_val = '0;

        ref_pixel = '0;
   
      end 
    
    end
  end

  /****************************************************************************/



endmodule