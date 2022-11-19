/*******************************************************************************
-- Title      : VGA Line Buffers Wrapper
-- Project    : VGA Controller
********************************************************************************
-- File       : line_buffers.sv
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2022-08-27
-- Design     : line_buffers
-- Platform   : -
-- Standard   : SystemVerilog '17
********************************************************************************
-- Description: VGA line buffers model written in SV
********************************************************************************
-- Revisions:
-- Date        Version  Author  Description
-- 2022-08-27  1.0      TZS     Created
-- 2022-09-11  1.1      TZS     Refactored/Optimised FSM design
-- 2022-09-12  1.2      TZS     Added supporting procedural blocks
-- 2022-10-02  1.3      TZS     Remove redundant frame buffer signals
*******************************************************************************/

/* NOTE: when the term ROW is used, it relates to a row in the FRAME BUFFER 
         memory, when the term LINE is used, it relates to a PIXEL LINE of the 
         frame. */

module line_buffers #(
  parameter COLR_PXL_WIDTH   =   12,
  parameter TILE_WIDTH       =    4,
  parameter WIDTH_PX         =  640,
  parameter FBUFF_DEPTH      = 4800,
  parameter FBUFF_ADDR_WIDTH =   12, // log2((((640 / 4) * (480 / 4)) / 5 tiles_per_line) - 1)
  parameter FBUFF_DATA_WIDTH =   60,
  parameter TILES_PER_ROW    =    5,
  parameter TILE_PER_LINE    = WIDTH_PX / TILE_WIDTH, // tile is 4 pixels wide (640/4)
  parameter LBUFF_ADDR_WIDTH = $clog2(TILE_PER_LINE)
) (
  input  logic                        clk_i,
  input  logic                        rstn_i,
  input  logic [1:0]                  buff_fill_req_i,
  input  logic [1:0]                  buff_sel_i,
  input  logic [LBUFF_ADDR_WIDTH-1:0] disp_pxl_id_i,
  input  logic [FBUFF_DATA_WIDTH-1:0] fbuff_data_i,
  input  logic                        fbuff_rd_rsp_i,
  output logic [1:0]                  buff_fill_done_o,
  output logic [COLR_PXL_WIDTH-1:0]   disp_pxl_o,
  output logic                        fbuff_rd_req_o,
  output logic [FBUFF_ADDR_WIDTH-1:0] fbuff_addra_o
);

  timeunit 1ns/1ps;

  localparam TILE_COUNTER_WIDTH  = $clog2(TILES_PER_ROW);

  typedef enum {RESET, IDLE, READ_FBUFF, WRITE_LBUFF, FINISH} fill_lbuff_states_t;

  fill_lbuff_states_t fill_lbuff_c_state_r;

  logic [1:0] fill_in_progress_r;
  logic [1:0] lbuff_fill_done_r;
  logic       fill_select_r;

  logic [1:0][LBUFF_ADDR_WIDTH-1:0] lbuff_addra_s;
  logic [1:0][LBUFF_ADDR_WIDTH-1:0] lbuff_wr_addra_r;
  logic [LBUFF_ADDR_WIDTH-1:0]      lbuff_rd_addra_s;
  logic [1:0][COLR_PXL_WIDTH-1:0]   lbuff_dina_s;
  logic [1:0]                       lbuff_wea_r;
  logic [1:0]                       lbuff_ena_s;
  logic [1:0][COLR_PXL_WIDTH-1:0]   lbuff_douta_s;
  logic                             lbuff_cntr_en_r;
  logic [TILE_COUNTER_WIDTH-1:0]    lbuff_tile_cntr_r;
  
  logic fbuff_rd_req_r;

  logic [COLR_PXL_WIDTH-1:0]   fbuff_pxl_s; 
  logic [FBUFF_ADDR_WIDTH-1:0] fbuff_addra_r; 
  logic [FBUFF_DATA_WIDTH-1:0] fbuff_data_r;
  
  // output assignments
  assign buff_fill_done_o = lbuff_fill_done_r;
  assign fbuff_rd_req_o   = fbuff_rd_req_r;
  assign fbuff_addra_o    = fbuff_addra_r;

  // select pixel within row for write to line buffer
  assign fbuff_pxl_s = fbuff_data_r[lbuff_tile_cntr_r*COLR_PXL_WIDTH +: COLR_PXL_WIDTH];
  // assign tile for write
  always_comb lbuff_dina_s[fill_select_r] = fbuff_pxl_s; 

  // read enable of line buffer is always set
  assign lbuff_ena_s = 2'b11;

  // mux outputs depending buff_sel value
  assign disp_pxl_o       = (buff_sel_i[0] == 1'b1) ? lbuff_douta_s[0] : (buff_sel_i[1] == 1'b1) ? lbuff_douta_s[1] : '0;
  assign lbuff_rd_addra_s = disp_pxl_id_i;

  genvar buff_idx;
    for(buff_idx = 0; buff_idx < 2; buff_idx++) begin : generate_frame_buffs
      // mux read logic address signals if buff_sel is set, else mux in the address from the write logic
      assign lbuff_addra_s[buff_idx] = (buff_sel_i[buff_idx] == 1'b1) ? lbuff_rd_addra_s : lbuff_wr_addra_r[buff_idx];

      xilinx_sp_BRAM #(
        .RAM_WIDTH ( COLR_PXL_WIDTH ),
        .RAM_DEPTH ( TILE_PER_LINE  ),
        .INIT_FILE ( ""             )
      ) i_line_buffer (
        .addra ( lbuff_addra_s[buff_idx] ),     
        .dina  ( lbuff_dina_s[buff_idx]  ),    
        .clka  ( clk_i                   ),    
        .wea   ( lbuff_wea_r[buff_idx]   ),   
        .ena   ( lbuff_ena_s[buff_idx]   ),
        .douta ( lbuff_douta_s[buff_idx] )   
      );  
    end

  /*** FILL BUFFER FSM ********************************************************/
    always_ff @(posedge clk_i or negedge rstn_i) begin : buff_fill_fsm
      
      if (~rstn_i) begin 
        
        lbuff_wea_r          <= '0;
        lbuff_fill_done_r    <= '0;
        lbuff_cntr_en_r      <= '0;
        fbuff_addra_r        <= '0;
        fbuff_rd_req_r       <= '0;
        fbuff_data_r         <= '0;
        fill_lbuff_c_state_r <= RESET;
     
      end else begin 

        fill_lbuff_FSM : case (fill_lbuff_c_state_r) /*-----------------------*/

          RESET : begin /*----------------------------------------------------*/

            fill_lbuff_c_state_r <= IDLE;

          end
          
          IDLE : begin /*-----------------------------------------------------*/
            
            if (fill_in_progress_r != 2'b00) begin
              fbuff_rd_req_r       <= 1'b1;
              fill_lbuff_c_state_r <= READ_FBUFF;
            end

          end 
          
          READ_FBUFF : begin /*-----------------------------------------------*/
            /* Start read from frame buffer and move to writing line buffer once 
               completed */
            fbuff_rd_req_r       <= 1'b0;
            
            if (fbuff_rd_rsp_i == 1'b1) begin 

              // increment frame buffer address ready for next request
              incr_addr : if (fbuff_addra_r == FBUFF_DEPTH-1) begin 
                fbuff_addra_r <= '0;
              end else begin 
                fbuff_addra_r <= fbuff_addra_r + 1;
              end

              fbuff_data_r               <= fbuff_data_i;
              lbuff_cntr_en_r            <= 1'b1;
              lbuff_wea_r[fill_select_r] <= 1'b1;
              fill_lbuff_c_state_r       <= WRITE_LBUFF;
            end
          
          end 
          
          WRITE_LBUFF : begin /*----------------------------------------------*/
            /* Write each tile from frame buffer row into the line buffer. Once
               complete, either perform another frame buffer read or finish 
            */

            if (lbuff_tile_cntr_r == (TILES_PER_ROW - 1)) begin 
              
              lbuff_cntr_en_r            <= 1'b0;
              lbuff_wea_r[fill_select_r] <= 1'b0; // stop writing once at row limit

              if (lbuff_wr_addra_r[fill_select_r] == (TILE_PER_LINE - 1)) begin
                // indicate that the buffer being filled is now full 
                // (only a single buffer should be in progress at any time)
                lbuff_fill_done_r    <= fill_in_progress_r; 
                fill_lbuff_c_state_r <= FINISH;
              end else begin
                fbuff_rd_req_r       <= 1'b1;
                fill_lbuff_c_state_r <= READ_FBUFF;
              end
              

            end
          end 
          
          FINISH : begin /*---------------------------------------------------*/
            /* Clear remaining control states and move to idle as line buffer 
               has been written 
            */
            lbuff_fill_done_r <= '0;
            fill_lbuff_c_state_r <= IDLE;

          end
          
          default : begin /*--------------------------------------------------*/

            fill_lbuff_c_state_r <= RESET;
            
          end
        
        endcase /*------------------------------------------------------------*/
        
      end
    end
  /****************************************************************************/
  
  /*** LINE BUFFER ADDR + TILE COUNTER LOGIC **********************************/
  always_ff @(posedge clk_i or negedge rstn_i) begin : tile_addr_counters

    if (~rstn_i) begin 

      lbuff_wr_addra_r  <= '0;
      lbuff_tile_cntr_r <= '0;
    
    end else begin 

      if (lbuff_cntr_en_r == 1'b1) begin 
        // increment line buffer address counter
        if (lbuff_wr_addra_r[fill_select_r] == (TILE_PER_LINE - 1))
          lbuff_wr_addra_r[fill_select_r] <= '0;
        else 
          lbuff_wr_addra_r[fill_select_r] <= lbuff_wr_addra_r[fill_select_r] + 1;
        // increment tile in row counter
        if (lbuff_tile_cntr_r == (TILES_PER_ROW - 1))
          lbuff_tile_cntr_r <= '0;
        else 
          lbuff_tile_cntr_r <= lbuff_tile_cntr_r + 1;

      end

    end
  end
  /****************************************************************************/

  /*** BUFFER FILL IN PROGRESS + FILL SELECT LOGIC ****************************/
  always_ff @(posedge clk_i or negedge rstn_i) begin : in_progress
    
    if (~rstn_i) begin 
      
      fill_in_progress_r <= '0;
      fill_select_r      <= '0;

    end else begin 
      // prioritise buffer_A. Only one buffer should be filled at a time as 
      // there is a single frame buff memory interface
      if (fill_in_progress_r == 2'b00) begin 

        if (buff_fill_req_i[0] == 1'b1) begin 

          fill_in_progress_r[0] <= 1'b1;
          fill_select_r         <= 1'b0;

        end else if (buff_fill_req_i[1] == 1'b1) begin 

          fill_in_progress_r[1] <= 1'b1;
          fill_select_r         <= 1'b1;

        end

      end else begin
        // TODO: Investigate whether this can be optimised as only one buffer
        // fill should be progressed at any time.
        if (lbuff_fill_done_r[0] == 1'b1) begin 

          fill_in_progress_r[0] <= 1'b0;
          
        end else if (lbuff_fill_done_r[1] == 1'b1) begin

          fill_in_progress_r[1] <= 1'b0; 
          
        end

      end
    end
  
  end
  /****************************************************************************/

endmodule