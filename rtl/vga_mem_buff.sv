/*******************************************************************************
-- Title      : VGA Controller - VGA Memory Buffers
-- Project    : VGA Controller
********************************************************************************
-- File       : vga_mem_buff.sv
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2022-07-16
-- Design     : vga_mem_buff
-- Platform   : -
-- Standard   : SystemVerilog '17
********************************************************************************
-- Description: Double buffers used to store pixel data prior to display.
--              ONLY USED FOR PROTOTYPING RTL
********************************************************************************
-- Revisions:
-- Date        Version  Author  Description
-- 2022-07-16  1.0      TZS     Created
*******************************************************************************/                 
module vga_mem_buff #(
  parameter ROW_CTR_WIDTH = 3,
  parameter MEM_DATA_WIDTH = 24,
  parameter MEM_ADDR_WIDTH = 16,
  parameter PXL_WIDTH = 9,
  parameter MAX_PXL_CNT = 7
)(
  input  logic clk_i,
  input  logic rstn_i,
  input  logic [MEM_ADDR_WIDTH-1:0] disp_addr_ctr_i,
  input  logic [ROW_CTR_WIDTH-1:0]  disp_pxl_ctr_i,
  input  logic [MEM_DATA_WIDTH-1:0] mem_data_i,
  output logic [MEM_ADDR_WIDTH-1:0] mem_addr_o,
  output logic                      mem_ren_o,
  output logic                      disp_blank_o,
  output logic [PXL_WIDTH-1:0]      disp_pxl_o 
);

  typedef enum {IDLE, INIT_FIRST_BUFF, READ_BUFF_WRITE_OTHER} state_t;

  state_t c_state;

  logic [1:0] [MEM_DATA_WIDTH-1:0] data_buff_s = '0;

  logic [MEM_ADDR_WIDTH-1:0] mem_addr_ctr_s = '0;
  logic [1:0] buff_filled_s                 = '0;
  logic buff_wr_sel_s                       = '0; // indicates which buffer is selected to 
                                                  // be written while the current pixel row is displayed
  logic buff_rd_sel_s; // indicates which buffer is selected to CURRENTLY be read from

  logic [MEM_ADDR_WIDTH-1:0] mem_addr_s   = '0;
  logic                      mem_ren_s    = '0;
  logic                      disp_blank_s = '0;
  logic [PXL_WIDTH-1:0]      pxl_s;

  always_ff @(posedge clk_i or negedge rstn_i) begin 
  
    if (!rstn_i) begin 
      
      mem_ren_s      <=  1;
      data_buff_s    <= '0;
      mem_addr_ctr_s <= '0;
      buff_filled_s  <= '0;
      buff_wr_sel_s  <= '0;
      
      c_state <= IDLE;

    end else begin 

      mem_ren_s      <= 0;
      data_buff_s    <= data_buff_s;
      mem_addr_ctr_s <= mem_addr_ctr_s;
      buff_filled_s  <= buff_filled_s;
      buff_wr_sel_s  <= buff_wr_sel_s;
      c_state        <= c_state;

      case (c_state) /*********************************************************/

        IDLE : begin // set memory control signals to prepare to fill first buffer
          
          mem_ren_s      <= 1;
          // no address overflow check as memory should be larger than 2 entries
          mem_addr_ctr_s <= mem_addr_ctr_s + 1; 

          c_state    <= INIT_FIRST_BUFF;
        
        end 
          
        INIT_FIRST_BUFF : begin /////////////////

          mem_ren_s                    <= 0;
          data_buff_s[buff_wr_sel_s]   <= mem_data_i;
          buff_filled_s[buff_wr_sel_s] <= 1;
          buff_wr_sel_s                <= 1;

          c_state <= READ_BUFF_WRITE_OTHER;

        end

        READ_BUFF_WRITE_OTHER : begin /////////////////

          // fill buffer that is not being read
          if ((!buff_filled_s[buff_wr_sel_s]) && (disp_pxl_ctr_i != MAX_PXL_CNT)) begin 

            data_buff_s[buff_wr_sel_s]    <= mem_data_i;
            buff_filled_s[buff_wr_sel_s]  <= 1;
            
          
          // set up read to ensure data is ready to fill other buffer
          end else if (disp_pxl_ctr_i == MAX_PXL_CNT-1) begin 

            mem_ren_s      <= 1;
            // ToDo: Add Address overflow checks 
            mem_addr_ctr_s <= mem_addr_ctr_s + 1;

          // swap to read other buffer once last pixel of current buffer has been reached
          end else if (disp_pxl_ctr_i == MAX_PXL_CNT) begin

            buff_wr_sel_s                <= ~buff_wr_sel_s;
            // clear filled flag for buffer that has just been read as it should be treated as being empty
            buff_filled_s[buff_rd_sel_s] <= 0; 

            // remain in this state until reset
          end

        end

        default : begin /////////////////

          c_state <= IDLE;
        
        end

      endcase /****************************************************************/

    end
  
  end
  
  assign buff_rd_sel_s = ~buff_wr_sel_s;

  // TODO: add check to ensure buffer is not empty
  assign pxl_s = data_buff_s[buff_rd_sel_s][(disp_pxl_ctr_i*3)+:3];

  // outputs assignments 
  assign mem_addr_o   = mem_addr_ctr_s; 
  assign mem_ren_o    = mem_ren_s;
  assign disp_blank_o = disp_blank_s; 
  assign disp_pxl_o   = pxl_s; 

endmodule
