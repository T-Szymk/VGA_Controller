/*------------------------------------------------------------------------------
 Title      : VGA AXI Memory Slave Testbench
 Project    : VGA Controller
--------------------------------------------------------------------------------
 File       : tb_vga_axi_mem.sv
 Author(s)  : Thomas Szymkowiak
 Company    : TUNI
 Created    : 2022-04-10
 Design     : tb_vga_axi_mem
 Platform   : -
 Standard   : SystemVerilog
--------------------------------------------------------------------------------
 Description: Testbench to exercise AXI master and slave for VGA Controller 
 memory bus
--------------------------------------------------------------------------------
 Revisions:
 Date        Version  Author  Description
 2022-04-10  1.0      TZS     Created
------------------------------------------------------------------------------*/

module tb_vga_axi_mem;

  timeunit 1ns/1ps;

  parameter AXI_ADDR_WIDTH  = 32;
  parameter AXI_DATA_WITH   = 64;

  parameter PXL_CTR_WIDTH = 10;
  parameter LINE_CTR_WIDTH = 10;

  parameter CLOCK_PERIOD_NS = 10;

  logic                      clk       = 0;
  logic                      rst_n     = 0;
  logic [PXL_CTR_WIDTH-1:0]  pxl_ctr;
  logic [LINE_CTR_WIDTH-1:0] line_ctr;
  logic                      ar_rdy;
  logic                      r_valid;
  logic [AXI_ADDR_WIDTH-1:0] ar_addr;
  logic [2:0]                ar_prot;
  logic                      ar_valid;
  logic                      r_rdy;
  logic [AXI_DATA_WITH-1:0]  r_data;
  logic [1:0]                r_resp;
  
  // clock generation
  always #(CLOCK_PERIOD_NS/2) clk = ~clk;

  vga_axi_mem_ctrl #(
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH(AXI_DATA_WITH)
  ) i_vga_axi_mem_ctrl (
    .m_aclk_i(clk),
    .m_arstn_i(rst_n),
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

  vga_axi_mem #(
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH(AXI_DATA_WITH)
  ) i_vga_axi_mem (
    .s_aclk_i(clk),
    .s_arstn_i(rst_n),
    .s_araddr_i(ar_addr),
    .s_arprot_i(ar_prot),
    .s_arvalid_i(ar_valid),
    .s_arrdy_o(ar_rdy),
    .s_rdata_o(r_data),
    .s_rvalid_o(r_valid),
    .s_rrdy_i(r_rdy),
    .s_rresp_o(r_resp)
  );

  initial begin
    
    #(5*CLOCK_PERIOD_NS) rst_n = 1;
    
  end
  
  

endmodule
