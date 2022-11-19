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
-- 2022-10-16  1.1      TZS     Add read req/rsp signals
-- 2022-10-30  1.2      TZS     Added init file parameter
*******************************************************************************/

module frame_buffer #(
  parameter FBUFF_ADDR_WIDTH = 12,
  parameter FBUFF_WIDTH      = 60, 
  parameter FBUFF_DEPTH      = 3840,
  parameter INIT_FILE        = ""
) (
  input  logic                        clk_i,
  input  logic                        rstn_i,
  input  logic [FBUFF_ADDR_WIDTH-1:0] addra_i,
  input  logic [FBUFF_WIDTH-1:0]      dina_i,
  input  logic                        wea_i,
  input  logic                        ena_i,
  input  logic                        rd_req_i,
  output logic                        rd_rsp_o,
  output logic [FBUFF_WIDTH-1:0]      douta    
);

  typedef enum logic [1:0] { RESET, IDLE, READ_REQ, READ_RSP } mem_state_t;

  mem_state_t mem_state_r;

  logic                   rd_rsp_r;
  logic [FBUFF_WIDTH-1:0] douta_s;

  assign rd_rsp_o = rd_rsp_r;
  assign douta    = douta_s;
  

  always_ff @(posedge clk_i or negedge rstn_i) begin
    
    if (~rstn_i) begin 
      
      mem_state_r <= RESET;
      rd_rsp_r    <= '0;
    
    end else begin 
      
      mem_state_r <= mem_state_r;
      
      case(mem_state_r)
        
      RESET : begin 
        mem_state_r <= IDLE;
      end
      
      IDLE  : begin 
        if (rd_req_i == 1'b1) begin 
          mem_state_r <= READ_REQ;
        end
      end
      
      READ_REQ : begin   
        rd_rsp_r    <= 1'b1;
        mem_state_r <= READ_RSP;
      end  
      
      READ_RSP : begin 
        // data ready for read during this state
        rd_rsp_r    <= '0;
        mem_state_r <= IDLE;
      end 
      
      default : begin 
        mem_state_r <= IDLE;
      end
  
      endcase
    end
  end

  xilinx_sp_BRAM #(
    .RAM_WIDTH( FBUFF_WIDTH ),
    .RAM_DEPTH( FBUFF_DEPTH ),
    .INIT_FILE( INIT_FILE )
  ) i_xilinx_sp_ram (
    .addra ( addra_i ),
    .dina  ( dina_i  ),
    .clka  ( clk_i   ),
    .wea   ( wea_i   ),
    .ena   ( ena_i   ),
    .douta ( douta_s )
  );

endmodule