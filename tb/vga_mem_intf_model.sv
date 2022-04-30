/*------------------------------------------------------------------------------
 Title      : VGA Memory Interface Model
 Project    : VGA Controller
--------------------------------------------------------------------------------
 File       : vga_mem_intf_model.sv
 Author(s)  : Thomas Szymkowiak
 Company    : TUNI
 Created    : 2022-04-30
 Design     : vga_mem_intf_model
 Platform   : -
 Standard   : VHDL'08
--------------------------------------------------------------------------------
 Description: Behavioral model used to prototype the VGA memory interface
--------------------------------------------------------------------------------
 Revisions:
 Date        Version  Author  Description
 2022-04-30  1.0      TZS     Created
------------------------------------------------------------------------------*/

program vga_mem_intf_model;

  parameter HEIGHT_PX     = 480;
  parameter WIDTH_PX      = 640;
  // depth of each colour
  parameter DEPTH_COLR    = 3;
  // number of pixels in each v_sync period
  parameter H_SYNC_PX     = 96;
  // number of pixels in each horiz. back porch period
  parameter H_B_PORCH_PX  = 48;
  // number of pixels in each horiz. front porch period
  parameter H_F_PORCH_PX  = 16;
  // number of lines in each v_sync period
  parameter V_SYNC_LNS    = 2;
  // number of lines in each vert. back porch period
  parameter V_B_PORCH_LNS = 33;
  // number of lines in each vert. front porch period
  parameter V_F_PORCH_LNS = 10;
  // counter max and associated valueswidths
  parameter PXL_CTR_MAX   = H_F_PORCH_PX + WIDTH_PX + 
                              H_B_PORCH_PX + H_SYNC_PX;
  parameter LINE_CTR_MAX  = V_F_PORCH_LNS + HEIGHT_PX + 
                              V_B_PORCH_LNS + V_SYNC_LNS;
  // use max value to calculate bit width of counter
  parameter PXL_CTR_WIDTH  = $clog2(PXL_CTR_MAX - 1);
  parameter LN_CTR_WIDTH   = $clog2(LINE_CTR_MAX - 1);

/**********************************/

  bit clk, rst_n, clr_n, we, rd = 0;

  bit [PXL_CTR_WIDTH-1:0] pxl_ctr = '0;
  bit [LN_CTR_WIDTH-1:0]  ln_ctr  = '0;
  bit [DEPTH_COLR-1:0]    colr    = '0;

/**********************************/

  sync_fifo #(
    .FIFO_WIDTH(FIFO_WIDTH),
    .FIFO_DEPTH(FIFO_DEPTH)
  ) i_sync_fifo (
    .clk(clk),
    .clr_n_in(clr_n),
    .we_in(we),
    .rd_in(rd),
    .data_in(data_in),
    .empty_out(empty),
    .full_out(full),
    .data_out(data_out)
  );

  sync_fifo #(
    .FIFO_WIDTH(FIFO_WIDTH),
    .FIFO_DEPTH(FIFO_DEPTH)
  ) i_sync_fifo (
    .clk(clk),
    .clr_n_in(clr_n),
    .we_in(we),
    .rd_in(rd),
    .data_in(data_in),
    .empty_out(empty),
    .full_out(full),
    .data_out(data_out)
  );  

  ROM_model #(
    .WIDTH(),
    .DEPTH(),
    .READ_EN()
  ) i_ROM_model (
    .clk(clk),
    .rst_n(rst_n),
    .addr_in(),
    .rd_en_in(),
    .dat_out()
  );

endprogram