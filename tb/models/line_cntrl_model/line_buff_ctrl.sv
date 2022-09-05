/*******************************************************************************
-- Title      : VGA Line Buffer Controller
-- Project    : VGA Controller
********************************************************************************
-- File       : line_buff_ctrl.sv
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2022-09-04
-- Design     : line_buff_ctrl
-- Platform   : -
-- Standard   : SystemVerilog '17
********************************************************************************
-- Description: VGA line buffer controller model written in SV.
--
--              A buffer is only written to if it is marked as empty (!full),
--              A buffer is only read from if it is marked as full.
--              This provides interlocking and prevents the line buffers from
--              being read/written at the same time. 
--
--              The limitation of this is that if the write process takes too
--              long (i.e. > an entire line of the frame incl. porch), the 
--              displayed pixels with fall out of sync. However, as this is a 
--              long time, it is not realistic that this would cause an issue.
********************************************************************************
-- Revisions:
-- Date        Version  Author  Description
-- 2022-09-05  1.0      TZS     Created
*******************************************************************************/

module line_buff_ctrl #(
  parameter WIDTH_PX          = 640,
  parameter HEIGHT_LNS        = 480,
  parameter H_B_PORCH_MAX_PX  = 144,
  parameter V_B_PORCH_MAX_LNS =  35,
  parameter TILE_WIDTH        =   4,
  parameter PXL_CTR_WIDTH     = $clog2(800),
  parameter LN_CTR_WIDTH      = $clog2(525),
  parameter TILE_PER_LINE      = WIDTH_PX / TILE_WIDTH, // tile is 4 pixels wide (640/4)
  parameter TILE_CTR_WIDTH    = $clog2(TILE_PER_LINE)
)(
  input  logic                      clk_i,
  input  logic                      rstn_i,
  input  logic [1:0]                buff_fill_done_i,
  input  logic [PXL_CTR_WIDTH-1:0]  pxl_cntr_i,
  input  logic [LN_CTR_WIDTH-1:0]   ln_cntr_i,
  output logic [1:0]                buff_fill_req_o,
  output logic [1:0]                buff_sel_o,
  output logic [TILE_CTR_WIDTH-1:0] disp_pxl_id_o
);

  timeunit 1ns/1ps;

  typedef enum logic [1:0] { READ_BUFF_RESET, 
                             INIT, 
                             READ_BUFF_A, 
                             READ_BUFF_B 
                            } read_buff_states_t;
  typedef enum logic [1:0] { FILL_BUFF_RESET,
                             FILL_A,
                             FILL_B 
                           } fill_buff_states_t;
  
  localparam DISP_START_PX  = H_B_PORCH_MAX_PX - 1; // subtract 1 to counter the 1 cycle latency of a memory buffer operations
  localparam DISP_END_PX    = H_B_PORCH_MAX_PX + WIDTH_PX - 1; 

  localparam DISP_START_LNS = V_B_PORCH_MAX_LNS;
  localparam DISP_END_LNS   = V_B_PORCH_MAX_LNS + HEIGHT_LNS;


  logic last_disp_pixel_s = '0; // pulse which is 1 for a cycle during the final cycle of the last pixel in the display buffer 
  logic counter_en_s      = '0; // register enable used to control display counters

  // used to determine which buffer is used to source display pixel (one-hot encoded)
  logic [1:0] buff_sel_s       = '0;
  // signal used to indicate that line buffer should be filled from frame buffer
  logic [1:0] buff_fill_req_r  = '0;
  logic [1:0] buff_full_r      = '0; 

  logic [TILE_CTR_WIDTH-1:0] disp_pxl_id_r = '0;
  
  logic [$clog2(TILE_WIDTH)-1:0] tile_pxl_cntr_r = '0;
  logic [$clog2(TILE_WIDTH)-1:0] tile_lns_cntr_r = '0;

  read_buff_states_t read_buff_state_r;
  fill_buff_states_t fill_buff_state_r;
  
  assign buff_fill_req_o = buff_fill_req_r;
  assign buff_sel_o      = buff_sel_s; 
  assign disp_pxl_id_o   = disp_pxl_id_r;

  /*** READ FROM BUFF FSM *****************************************************/

  always_ff @(posedge clk_i or negedge rstn_i) begin : read_buff_fsm

    if (~rstn_i) begin

      read_buff_state_r   <= READ_BUFF_RESET;
      buff_sel_s          <= '0;

    end else begin

      case (read_buff_state_r)

        READ_BUFF_RESET : 

          read_buff_state_r <= INIT;
      
        INIT :
          /* only begin reading from buffer A once buffer A has been filled */
          if(buff_full_r[0] == 1'b1) begin 
            read_buff_state_r <= READ_BUFF_A;
            buff_sel_s <= 2'b01;
          end 
        
        READ_BUFF_A :
          /* switch to reading from buffer B once last pixel of buffer A is 
             being displayed and buffer B has been filled */
          if (last_disp_pixel_s == 1 && buff_full_r[1] == 1'b1) begin 
            read_buff_state_r <= READ_BUFF_B;
            buff_sel_s        <= 2'b10;
          end
          
        READ_BUFF_B :
          /* switch to reading from buffer A once last pixel of buffer B is 
             being displayed and buffer A has been filled */
          if (last_disp_pixel_s == 1 && buff_full_r[0] == 1'b1) begin 
            read_buff_state_r <= READ_BUFF_A;
            buff_sel_s        <= 2'b01;
          end

        default : 
          read_buff_state_r <= READ_BUFF_RESET;

      endcase
    end
  end

  /****************************************************************************/

  /*** FILL BUFF FSM **********************************************************/

  always_ff @(posedge clk_i or negedge rstn_i) begin : fill_buff_fsm
  
    if(~rstn_i) begin 
      
      fill_buff_state_r <= FILL_BUFF_RESET;
      buff_fill_req_r   <= '0;

    end else begin
      
      case(fill_buff_state_r)

        FILL_BUFF_RESET : begin 
          fill_buff_state_r <= FILL_A;
          buff_fill_req_r   <= 2'b01; // send fill request pulse
        end
        
        FILL_A : begin

          buff_fill_req_r <= '0;
          
          // If A is full and B is empty (i.e. B has been read from)
          if (buff_full_r == 2'b01) begin 
            fill_buff_state_r <= FILL_B;
            buff_fill_req_r   <= 2'b10;
          end 
          
        end

        FILL_B : begin 

          buff_fill_req_r <= '0;
          
          // If B is full and A is empty (i.e. A has been read from)
          if (buff_full_r == 2'b10) begin 
            fill_buff_state_r <= FILL_A;
            buff_fill_req_r   <= 2'b01;
          end 

        end

        default :
          fill_buff_state_r <= FILL_BUFF_RESET;

      endcase
    end
  end

  /****************************************************************************/

  /*** PIXEL DISPLAY COUNTER LOGIC ********************************************/

  always_ff @(posedge clk_i or negedge rstn_i) begin : disp_cntr_logic
    
    if (~rstn_i) begin 
      
      disp_pxl_id_r     <= '0;
      tile_pxl_cntr_r   <= '0;
      tile_lns_cntr_r   <= '0;

    end else begin
      
      // each pixel is displayed for TILE_WIDTH cycles and each line is repeated TILE_WIDTH times
      if (counter_en_s == 1'b1) begin 

        if (tile_pxl_cntr_r == (TILE_WIDTH - 1)) begin 
          
          tile_pxl_cntr_r <= '0;

          if (disp_pxl_id_r == (TILE_PER_LINE - 1)) begin
            
            disp_pxl_id_r <= '0;

            if(tile_lns_cntr_r == (TILE_WIDTH - 1)) begin
              tile_lns_cntr_r <= '0;
            end else begin 
              tile_lns_cntr_r <=  tile_lns_cntr_r + 1;
            end

          end else begin 
          
            disp_pxl_id_r <= disp_pxl_id_r + 1;
          
          end

        end else begin 
          tile_pxl_cntr_r <= tile_pxl_cntr_r + 1;
        end

      end

    end
  end

  /****************************************************************************/

  /******* BUFFER FULL/EMPTY LOGIC ********************************************/

  genvar buff_idx;
  generate
    for(buff_idx = 0; buff_idx < 2; buff_idx++) begin : gen_buff_full
  
      always_ff @(posedge clk_i or negedge rstn_i) begin : buff_empty_full_logic
      
        if(~rstn_i) begin 
  
          buff_full_r[buff_idx] <= '0;
  
        end else begin
  
          // set buff_full once confirmation received from buffer that fill is complete
          if(buff_fill_done_i[buff_idx] == 1'b1) begin 
            buff_full_r[buff_idx] <= 1'b1;
          end else if(last_disp_pixel_s == 1'b1) begin // if last display pixel signal is active, clear full status of buffer being read
            if(buff_sel_s[buff_idx] == 1'b1) begin 
              buff_full_r[buff_idx] <= 1'b0;
            end
          end
  
        end
      end
    end
  endgenerate

  /****************************************************************************/

  /******* COUNTER ENABLE *****************************************************/

  always_comb begin : comb_counter_en

    if((ln_cntr_i >= DISP_START_LNS) && 
       (ln_cntr_i <  DISP_END_LNS) ) begin 

      if((pxl_cntr_i >= DISP_START_PX) && 
         (pxl_cntr_i < DISP_END_PX) ) begin 

        counter_en_s = 1'b1;

      end else begin
        
        counter_en_s = 1'b0;
      
      end

    end else begin 

      counter_en_s = 1'b0;

    end

  end

  /****************************************************************************/

  /******* LAST PIXEL LOGIC ***************************************************/

  always_comb begin
    
    // during the last cycle of the display pixel of a buffer, set last_disp_pixel to 1
    if ( tile_lns_cntr_r == (TILE_WIDTH - 1) && 
         disp_pxl_id_r   == (TILE_PER_LINE - 1) && 
         tile_pxl_cntr_r == (TILE_WIDTH - 1) ) begin : comb_last_pxl_logic
 
      last_disp_pixel_s = 1'b1;

    end else begin 

      last_disp_pixel_s = 1'b0;
    
    end
    
  end

  /****************************************************************************/

endmodule
