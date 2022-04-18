/*------------------------------------------------------------------------------
 Title      : VGA AXI4-Lite Master Controller Testbench
 Project    : VGA Controller
--------------------------------------------------------------------------------
 File       : tb_vga_axi_lite_master.sv
 Author(s)  : Thomas Szymkowiak
 Company    : TUNI
 Created    : 2022-04-10
 Design     : tb_vga_axi_lite_master
 Platform   : -
 Standard   : SystemVerilog
--------------------------------------------------------------------------------
 Description: Testbench to exercise AXI4-Lite master for VGA Controller memory 
              bus
--------------------------------------------------------------------------------
 Revisions:
 Date        Version  Author  Description
 2022-04-10  1.0      TZS     Created
 2022-04-18  1.1      TZS     Updated naming and signals to match AXI master.
------------------------------------------------------------------------------*/

module tb_vga_axi_lite_master;

  timeunit 1ns/1ps;

  parameter AXI_ADDR_WIDTH  = 32;
  parameter AXI_DATA_WITH   = 64;

  parameter PXL_CTR_WIDTH = 10;
  parameter LINE_CTR_WIDTH = 10;

  parameter CLOCK_PERIOD_NS = 10;

  logic                      clk       = 0;
  logic                      rst_n     = 0;
  logic                      req_data  = 1;
  logic [AXI_ADDR_WIDTH-1:0] addr_r    = '0;
  logic                      ar_rdy;
  logic                      r_valid;
  logic [AXI_ADDR_WIDTH-1:0] ar_addr;
  logic [2:0]                ar_prot;
  logic                      ar_valid;
  logic                      r_rdy;
  logic [AXI_DATA_WITH-1:0]  r_data    = '0;
  logic [1:0]                r_resp    = '0;

  logic                      ar_rdy_r  = 0;
  logic                      r_valid_r = 0;

  typedef enum {RESET, IDLE, RCV_ADDR, SEND_DATA} state_t; 

  state_t c_state, n_state;
  
  // clock generation
  always #(CLOCK_PERIOD_NS/2) clk = ~clk;

  vga_axi_lite_master #(
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH(AXI_DATA_WITH)
  ) i_vga_axi_lite_master (
    .req_data_i(req_data),
    .addr_i(addr_r),
    .m_aclk_i(clk),
    .m_arstn_i(rst_n),
    .m_araddr_o(ar_addr),
    .m_arprot_o(ar_prot),
    .m_arvalid_o(ar_valid),
    .m_arrdy_i(ar_rdy),
    .m_rdata_i(r_data),
    .m_rvalid_i(r_valid),
    .m_rrdy_o(r_rdy),
    .m_rresp_i(r_resp)
  );

  initial begin
    
    #(5*CLOCK_PERIOD_NS) rst_n = 1;
    
  end
  
  /***** FSM Block 1 : Synchronous current state assignment *****/

  always_ff @(posedge clk or negedge rst_n) begin : sync_c_state 

    if (~rst_n) begin
      c_state <= RESET;
    end else begin
      c_state <= n_state;
    end 

  end

  /***** FSM Block 2 : Combinational next state assignment *****/

  always_comb begin : comb_n_state

    n_state = c_state; // default assignments

    case (c_state)
      
      RESET: 
        n_state = IDLE;

      IDLE: 
        n_state = RCV_ADDR;        

      RCV_ADDR: begin
        if(ar_rdy == 1 && ar_valid == 1)
          n_state = SEND_DATA;
        else
          n_state = RCV_ADDR;
      end

      SEND_DATA: begin 
        if(r_rdy == 1 && r_valid == 1)
          n_state = IDLE;
        else
          n_state = SEND_DATA;
      end

      default:
        n_state = RESET;
    endcase
    
  end

  /***** FSM Block 3 : Synchronous output assignment  *****/

  always_ff @(posedge clk or negedge rst_n) begin : sync_output
  
    if(~rst_n) begin 
      ar_rdy_r  <= 1'b0;
      r_valid_r <= 1'b0;
      r_data    <= '0; 
      addr_r    <= '0;
    end else begin
    
      ar_rdy_r  <= 0;
      r_valid_r <= 0;

      case(n_state) 
        
        RESET: begin
          r_data    <= '0;
        end
        
        IDLE: begin 
          ar_rdy_r  <= 0;
        end

        RCV_ADDR: begin
          ar_rdy_r <= 1;
          addr_r++;
        end
          
        SEND_DATA: begin
          r_valid_r <= 1;
          r_data++;
        end

        default: begin
          ar_rdy_r  <= 1'b0;
          r_valid_r <= 1'b1;
          r_data    <= '0;
        end
      endcase

    end

  end

  assign r_valid = r_valid_r;
  assign ar_rdy  = ar_rdy_r;

endmodule
