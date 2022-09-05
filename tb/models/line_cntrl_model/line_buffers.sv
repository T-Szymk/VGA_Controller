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
-- 2022-09-05  1.1      TZS     Added comments
*******************************************************************************/

/* NOTE: when the term ROW is used, it relates to a row in the FRAME BUFFER 
         memory, when the term LINE is used, it relates to a PIXEL LINE of the 
         frame. */

module line_buffers #(
  parameter COLR_PXL_WIDTH   =   12,
  parameter TILE_WIDTH       =    4,
  parameter WIDTH_PX         =  640,
  parameter FBUFF_ADDR_WIDTH =   12, // log2((((640 / 4) * (480 / 4)) / 5 tiles_per_line) - 1)
  parameter FBUFF_DATA_WIDTH =   60,
  parameter FBUFF_DEPTH      = 3840,
  parameter TILES_PER_ROW    =    5,
  parameter TILE_PER_LINE    = WIDTH_PX / TILE_WIDTH, // tile is 4 pixels wide (640/4)
  parameter TILE_CTR_WIDTH   = $clog2(TILE_PER_LINE)
) (
  input  logic                        clk_i,
  input  logic                        rstn_i,
  input  logic [1:0]                  buff_fill_req_i,
  input  logic [1:0]                  buff_sel_i,
  input  logic [TILE_CTR_WIDTH-1:0]   disp_pxl_id_i,
  input  logic [FBUFF_DATA_WIDTH-1:0] fbuff_data_i,
  output logic [1:0]                  buff_fill_done_o,
  output logic [COLR_PXL_WIDTH-1:0]   disp_pxl_o,
  output logic [FBUFF_ADDR_WIDTH-1:0] fbuff_addr_o,
  output logic                        fbuff_en_o
);

  timeunit 1ns/1ps;

  localparam FBUFF_ROWS_PER_LINE = TILE_PER_LINE / TILES_PER_ROW; 
  localparam READ_COUNTER_WIDTH  = $clog2(FBUFF_ROWS_PER_LINE);
  localparam TILE_COUNTER_WIDTH  = $clog2(TILES_PER_ROW); 

  typedef enum {IDLE, READ_FBUFF, PREP_LBUFF, WRITE_LBUFF} fill_buff_states_t;

  fill_buff_states_t fill_buff_c_state_r;
  
  logic [1:0][TILE_CTR_WIDTH-1:0]  lbuff_addra_s;
  logic [1:0][TILE_CTR_WIDTH-1:0]  lbuff_wr_addra_r;

  wire  [TILE_CTR_WIDTH-1:0]  lbuff_rd_addra_s;

  logic [1:0][COLR_PXL_WIDTH-1:0]  lbuff_dina_s;
  logic [1:0][COLR_PXL_WIDTH-1:0]  lbuff_dina_r;
  logic [1:0]                      lbuff_wea_s;
  logic [1:0]                      lbuff_wea_r;
  logic [1:0]                      lbuff_ena_s;
  logic [1:0][COLR_PXL_WIDTH-1:0]  lbuff_douta_s;

  logic [1:0] fill_in_progress_r;
  logic [1:0] buff_fill_done_r;
  logic       fill_select_r;

  logic [READ_COUNTER_WIDTH-1:0]   fbuff_row_ctr_r;
  logic [TILE_COUNTER_WIDTH-1:0]   lbuff_tile_ctr_r;
  logic [FBUFF_ADDR_WIDTH-1:0]     fbuff_addr_r;
  logic [FBUFF_DATA_WIDTH-1:0]     fbuff_row_r;

  assign fbuff_en_o   = 1'b1;
  assign fbuff_addr_o = fbuff_addr_r;
  
  assign buff_fill_done_o = buff_fill_done_r;

  assign lbuff_ena_s   = 2'b11;
  assign lbuff_wea_s   = lbuff_wea_r;
  assign lbuff_dina_s  = lbuff_dina_r;

  // mux outputs depending buff_sel value
  assign disp_pxl_o = (buff_sel_i[0] == 1'b1) ? lbuff_douta_s[0] : (buff_sel_i[1] == 1'b1) ? lbuff_douta_s[1] : '0;
  assign lbuff_rd_addra_s = disp_pxl_id_i;

  genvar buff_idx;
  generate
    for(buff_idx = 0; buff_idx < 2; buff_idx++) begin
      // mux read logic address signals if buff_sel is set, else mux in the address from the write logic
      assign lbuff_addra_s[buff_idx] = (buff_sel_i[buff_idx] == 1'b1) ? lbuff_rd_addra_s : lbuff_wr_addra_r[buff_idx];

      xilinx_single_port_ram #(
        .RAM_WIDTH ( COLR_PXL_WIDTH ),
        .RAM_DEPTH ( TILE_PER_LINE  ),
        .INIT_FILE ( ""             )
      ) i_buffer_A (
        .addra ( lbuff_addra_s[buff_idx] ),     
        .dina  ( lbuff_dina_s[buff_idx]  ),    
        .clka  ( clk_i                   ),    
        .wea   ( lbuff_wea_s[buff_idx]   ),   
        .ena   ( lbuff_ena_s[buff_idx]   ),
        .douta ( lbuff_douta_s[buff_idx] )   
      );  
    end

  endgenerate

  /*** FILL BUFFER LOGIC ******************************************************/
    always_ff @(posedge clk_i or negedge rstn_i) begin : buff_fill_fsm
      
      if (~rstn_i) begin 
        
        fbuff_row_ctr_r    <= '0;
        lbuff_tile_ctr_r    <= '0;
        lbuff_wr_addra_r    <= '0;
        lbuff_wea_r         <= '0;
        lbuff_dina_r        <= '0;
        fbuff_addr_r        <= '0;
        fbuff_row_r         <= '0;
        buff_fill_done_r    <= '0;
        fill_buff_c_state_r <= IDLE;
     
      end else begin 

        case (fill_buff_c_state_r)
        
          IDLE : begin

            lbuff_wea_r[fill_select_r]      <= '0;    
            lbuff_dina_r[fill_select_r]     <= '0;     
            lbuff_wr_addra_r[fill_select_r] <= '0;      
            buff_fill_done_r[fill_select_r] <= 1'b0;

            if (fill_in_progress_r[fill_select_r] == 1'b1) begin 
              fill_buff_c_state_r <= READ_FBUFF;
            end

          end

          READ_FBUFF : begin 
            /* firstly, read a row from the frame buffer into local registers */
            fbuff_row_r <= fbuff_data_i;

            /* protect frame buffers addresses from overflow */
            if (fbuff_addr_r == (FBUFF_DEPTH - 1)) begin 
              fbuff_addr_r <= '0;
            end else begin 
              fbuff_addr_r <= fbuff_addr_r + 1;
            end
            
            fill_buff_c_state_r <= PREP_LBUFF;
         
          end

          PREP_LBUFF : begin 

            lbuff_wea_r[fill_select_r]      <= 1'b1;
            lbuff_dina_r[fill_select_r]     <= fbuff_row_r[lbuff_tile_ctr_r * COLR_PXL_WIDTH +: COLR_PXL_WIDTH];
            lbuff_wr_addra_r[fill_select_r] <= (fbuff_row_ctr_r * TILES_PER_ROW) + lbuff_tile_ctr_r;
            lbuff_tile_ctr_r                <= lbuff_tile_ctr_r + 1;

            fill_buff_c_state_r <= WRITE_LBUFF;

          end
          
          WRITE_LBUFF : begin 

            buff_fill_done_r[fill_select_r] <= 1'b0;

            /* iterate through each frame buffer row and populate the line buffer,
               one tile at a time. Once the line buffer is full, return to the idle state. */
            if (lbuff_tile_ctr_r == (TILES_PER_ROW - 1)) begin
               
              if (fbuff_row_ctr_r == (FBUFF_ROWS_PER_LINE - 1)) begin // fbuff_row_ctr_r counts fbuff rows in each line

                fbuff_row_ctr_r           <= '0;
                fill_buff_c_state_r        <= IDLE;

              end else begin 

                fbuff_row_ctr_r    <= fbuff_row_ctr_r + 1;
                fill_buff_c_state_r <= READ_FBUFF; 

              end

              lbuff_tile_ctr_r <= '0;

            end else begin 

              lbuff_tile_ctr_r    <= lbuff_tile_ctr_r + 1;
              fill_buff_c_state_r <= WRITE_LBUFF;
            
            end

            lbuff_wea_r[fill_select_r]      <= 1'b1;
            lbuff_dina_r[fill_select_r]     <= fbuff_row_r[lbuff_tile_ctr_r * COLR_PXL_WIDTH +: COLR_PXL_WIDTH];
            lbuff_wr_addra_r[fill_select_r] <= (fbuff_row_ctr_r * TILES_PER_ROW) + lbuff_tile_ctr_r;

            // indicate fill is done, 1 cycle early so that in_progress can be cleared in time
            if (fbuff_row_ctr_r == (FBUFF_ROWS_PER_LINE - 1) && lbuff_tile_ctr_r == (TILES_PER_ROW - 2)) begin
  
              buff_fill_done_r[fill_select_r] <= 1'b1;

            end

          end

          
          default :

            fill_buff_c_state_r <= IDLE;
        
        endcase
        
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

        if (buff_fill_done_r[0] == 1'b1) begin 

          fill_in_progress_r[0] <= 1'b0;
          
        end else if (buff_fill_done_r[1] == 1'b1) begin

          fill_in_progress_r[1] <= 1'b0; 
          
        end

      end
    end
  
  end
  /****************************************************************************/

endmodule