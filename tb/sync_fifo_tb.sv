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

  parameter CLOCK_PERIOD_NS = 10;

  bit clk = 0;
  bit clr_n = 0;
  bit we = 0;
  bit rd = 0;
  bit empty;
  bit full;
  bit [FIFO_WIDTH-1:0] data_in;
  bit [FIFO_WIDTH-1:0] data_out;
  bit [FIFO_WIDTH-1:0] test_data_out;

  bit [FIFO_WIDTH-1:0] fifo_model [FIFO_DEPTH-1:0];

  int write_ptr, read_ptr, data_count = 0;

  always #(CLOCK_PERIOD_NS/2) clk = ~clk;

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


  initial begin
    $display("Starting test with FIFO_WIDTH = %0d bits, FIFO_DEPTH = %0d, CLOCK_PERIOD_NS = %0d ns", FIFO_WIDTH, FIFO_DEPTH, CLOCK_PERIOD_NS);
    $display("\nClearing FIFO...");
    #(2 * CLOCK_PERIOD_NS) clr_n = 1;
    check_fifo_vals(fifo_model, 1);

    assert (full == 0);
    assert (empty == 1);

    $display("\nFilling FIFO...");
    we = 1;
    for(int i = 0; i < FIFO_DEPTH; i++) begin 
      data_in = i;
      @(posedge(clk));
      $display("Wrote val: %0d to position %0d of FIFO model.", i, i);
      @(negedge(clk));
      check_fifo_vals(fifo_model, 0);
      assert (empty == 0);
    end
    
    assert (full == 1);
    
    $display("\nEmptying FIFO...");
    we = 0;
    rd = 1;
    for(int i = FIFO_DEPTH - 1; i >= 0; i--) begin 
      test_data_out = data_out;
      @(posedge(clk));
      @(negedge(clk));
      $display("Read val: %0d from position %0d of FIFO model.", data_out, (FIFO_DEPTH-1)-i);
      check_fifo_vals(fifo_model, 0);
      assert(data_out == (FIFO_DEPTH-1)-i && full == 0);
    end
    
    assert (empty == 1) else $error("empty is not asserted when expected");
    
    $display("\nTesting operation when we + rd are set...");

    $display("... when empty");
    we = 1;
    data_in = 'hBEEF;
    @(posedge(clk));
    @(negedge(clk));
    check_fifo_vals(fifo_model, 0);
    assert(full == 0 && empty == 0);

    $display("... when full");
    rd = 0;
    for(int i = 0; i < FIFO_DEPTH-1; i++) begin 
      data_in = 10 + i;
      @(posedge(clk));
    end
    @(negedge(clk));
    check_fifo_vals(fifo_model, 0);
    data_in = 'hBEEF;
    @(posedge(clk));
    @(negedge(clk));
    check_fifo_vals(fifo_model, 0);
    assert(full == 1 && empty == 0);

    $finish;

  end 

  /* Model of fifo */
  always @(posedge clk or negedge clr_n) begin 


    if(clr_n == 0) begin 
      clear_fifo_model(fifo_model);
    end else begin

      if (we == 1 && data_count != FIFO_DEPTH && rd == 0) begin
        
        fifo_model[write_ptr] = data_in;
        
        if(write_ptr == FIFO_DEPTH-1) begin
          write_ptr = 0;
        end else begin 
          write_ptr++;
        end

        data_count++;

      end else if (rd == 1 && data_count != 0 && we == 0) begin
        
        test_data_out = fifo_model[read_ptr];

        if(read_ptr == FIFO_DEPTH-1) begin
          read_ptr = 0;
        end else begin 
          read_ptr++;
        end

        data_count--;

      end else if (rd == 1 && we == 1) begin 
        if (data_count == 0) begin 
            fifo_model[write_ptr] = data_in;
        
          if(write_ptr == FIFO_DEPTH-1) begin
            write_ptr = 0;
          end else begin 
            write_ptr++;
          end
          
          data_count++;
        end else begin 
          test_data_out = fifo_model[read_ptr];
          fifo_model[write_ptr] = data_in;

          if(read_ptr == FIFO_DEPTH-1) begin
            read_ptr = 0;
          end else begin 
            read_ptr++;
          end

          if(write_ptr == FIFO_DEPTH-1) begin
            write_ptr = 0;
          end else begin 
            write_ptr++;
          end

        end
      end
    end  
  end
  
  /* Clear FIFO struct so every value is 0 */
  function void clear_fifo_model (
    input bit [FIFO_WIDTH-1:0] fifo_arg [FIFO_DEPTH-1:0]
  );
    for(int idx = 0; idx < FIFO_DEPTH; idx++) begin 
      fifo_arg[idx] = '0;
    end
  endfunction
  
  /* Performs comparison of vlaues contained within DUT FIFO against golden model. 
     Second argument can be used as a flag to control whether to print vals */
  function void check_fifo_vals(
    input bit [FIFO_WIDTH-1:0] fifo_arg [FIFO_DEPTH-1:0],
    input bit print
  );
    if(print == 1) $display("Comparing DUT FIFO against TB Model...");
    for(int idx = 0; idx < FIFO_DEPTH; idx++) begin 
      assert(fifo_arg[idx] == i_sync_fifo.fifo_block_r[idx]);
      if(print == 1) $display("FIFO Model : DUT - %0d : %0d", fifo_arg[idx], i_sync_fifo.fifo_block_r[idx]);
    end
  endfunction

endmodule