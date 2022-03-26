/*------------------------------------------------------------------------------
 Title      : SV Interface for AXI
 Project    : VGA Controller
--------------------------------------------------------------------------------
 File       : axi_interface.sv
 Author(s)  : Thomas Szymkowiak
 Company    : TUNI
 Created    : 2022-03-26
 Design     : -
 Platform   : -
 Standard   : SystemVerilog
--------------------------------------------------------------------------------
 Description: Interfaces for use when instantiating AXI components
--------------------------------------------------------------------------------
 Revisions:
 Date        Version  Author  Description
 2022-03-26  1.0      TZS     Created
------------------------------------------------------------------------------*/

interface axi_lite_intf #(
  parameter AXI_ADDR_WIDTH = 32,
  parameter AXI_DATA_WITH  = 64
) (
  input logic a_clk,
  input logic a_resetn
);

  localparam STRB_WIDTH = AXI_DATA_WITH / 8;

  // read address
  logic                      ar_valid;
  logic                      ar_ready;
  logic [AXI_ADDR_WIDTH-1:0] ar_addr;
  logic [2:0]                ar_prot;
  // read data
  logic                      r_valid;
  logic                      r_ready;
  logic [AXI_DATA_WITH-1:0]  r_data;
  logic [1:0]                r_resp;
  // write address
  logic                      aw_valid;
  logic                      aw_ready;
  logic [AXI_ADDR_WIDTH-1:0] aw_addr;
  logic [2:0]                aw_prot;
  // write data
  logic                      w_valid;
  logic                      w_ready;
  logic [AXI_DATA_WITH-1:0]  w_data;
  logic [STRB_WIDTH-1:0]     w_strb;
  // write reponse
  logic                      b_valid;
  logic                      b_ready;
  logic [1:0]                b_resp;

  modport master (
    input  ar_ready,
           r_valid, r_data, r_resp,
           aw_ready, 
           w_ready, w_data,
           b_valid, b_resp,
    output ar_valid, ar_addr, ar_prot,
           r_ready,
           aw_valid, aw_addr, aw_prot,
           w_valid, w_strb,
           b_ready
  );
  modport slave (
    input  ar_valid, ar_addr, ar_prot,
           r_ready,
           aw_valid, aw_addr, aw_prot,
           w_valid, w_strb,
           b_ready,
    output ar_ready,
           r_valid, r_data, r_resp,
           aw_ready, 
           w_ready, w_data,
           b_valid, b_resp
  );

endinterface // axi_lite_intf 