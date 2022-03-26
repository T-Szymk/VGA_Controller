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
    ar_rdy = 1;
    @()
  
  end

endmodule