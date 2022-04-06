/*------------------------------------------------------------------------------
 Title      : VGA AXI Memory Controller Testbench
 Project    : VGA Controller
--------------------------------------------------------------------------------
 File       : tb_vga_axi_mem_ctrl.sv
 Author(s)  : Thomas Szymkowiak
 Company    : TUNI
 Created    : 2022-03-26
 Design     : tb_vga_axi_mem_ctrl
 Platform   : -
 Standard   : SystemVerilog
--------------------------------------------------------------------------------
 Description: Testbench to exercise AXI master for VGA Controller memory bus
--------------------------------------------------------------------------------
 Revisions:
 Date        Version  Author  Description
 2022-03-26  1.0      TZS     Created
------------------------------------------------------------------------------*/

module tb_vga_axi_mem_ctrl;

  timeunit 1ns/1ps;

  parameter AXI_ADDR_WIDTH  = 32;
  parameter AXI_DATA_WITH   = 64;

  parameter CLOCK_PERIOD_NS = 10;

  logic                      clk      = 0;
  logic                      rst_n    = 0;
  logic                      pxl_ctr  = 0;
  logic                      line_ctr = 0;
  logic                      ar_rdy   = 0;
  logic                      r_valid  = 0;
  logic [AXI_ADDR_WIDTH-1:0] ar_addr;
  logic [2:0]                ar_prot;
  logic                      ar_valid;
  logic                      r_rdy;
  logic [AXI_DATA_WITH-1:0]  r_data   = '0;
  logic [1:0]                r_resp   = '0;

  typedef enum {RESET, IDLE, WAIT4RDY, SEND_DATA} state_t; 

  state_t c_state, n_state;
  
  // clock generation
  always #(CLOCK_PERIOD_NS/2) clk = ~clk;

  vga_axi_mem_ctrl #(
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .AXI_DATA_WITH(AXI_DATA_WITH)
  ) i_vga_axi_mem_ctrl (
    .clk(clk),
    .rst_n(rst_n),
    .pxl_ctr_i(pxl_ctr),
    .line_ctr_i(line_ctr),
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

    n_state = RESET; // default assignments

    case (c_state)
      
      RESET: 
        n_state = IDLE;

      IDLE: 
        if(ar_rdy == 1 && ar_valid == 1)
          n_state = WAIT4RDY;
        else
          n_state = IDLE;

      WAIT4RDY: 
        n_state = r_rdy ? SEND_DATA : WAIT4RDY;
      
      SEND_DATA: 
        if(r_rdy == 1 && r_valid == 1)
          n_state = IDLE;
        else
          n_state = SEND_DATA;

      default:
        n_state = RESET;
    endcase
    
  end

  /***** FSM Block 3 : Synchronous output assignment  *****/

  always_ff @(posedge clk or negedge rst_n) begin : sync_output


  end

endmodule