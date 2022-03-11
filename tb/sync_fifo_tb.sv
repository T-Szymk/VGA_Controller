/*------------------------------------------------------------------------------
 Title      : Synchronous FIFO Testbench
 Project    : VGA Controller
--------------------------------------------------------------------------------
 File       : sync_fifo_tb.sv
 Author(s)  : Thomas Szymkowiak
 Company    : TUNI
 Created    : 2022-03-11
 Design     : sync_fifo_tb
 Platform   : -
 Standard   : SystemVerilog
--------------------------------------------------------------------------------
 Description: Testbench to exercise the synchronous FIFO
--------------------------------------------------------------------------------
 Revisions:
 Date        Version  Author  Description
 2022-03-11  1.0      TZS     Created
------------------------------------------------------------------------------*/

module sync_fifo_tb;

  timeunit 1ns/1ps;

  parameter FIFO_WIDTH = 36;
  parameter FIFO_DEPTH = 10;

  bit clk = 0;
  bit clr_n = 0;
  bit we = 0;
  bit rd = 0;
  bit empty;
  bit full;
  bit [FIFO_WIDTH-1:0] data_in;
  bit [FIFO_WIDTH-1:0] data_out;

  always #10 clk = ~clk;

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

endmodule