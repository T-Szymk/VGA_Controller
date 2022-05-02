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
 Description: Testbench to exercise the synchronous FIFO. Golden model only used
              to confirm contents of FIFO; status signals are NOT modelled, but 
              they are tested independently.
--------------------------------------------------------------------------------
 Revisions:
 Date        Version  Author  Description
 2022-03-11  1.0      TZS     Created
 2022-05-02  1.1      TZS     Added tests for "almost empty/full" functionality
------------------------------------------------------------------------------*/

module sync_fifo_tb;

  timeunit 1ns/1ps;

  parameter FIFO_WIDTH = 36;
  parameter FIFO_DEPTH = 10;

  parameter CLOCK_PERIOD_NS = 10;
  
  // fifo status encoded
  enum logic [3:0] {NORM         = 4'b0000,
                    EMPTY        = 4'b0001,
                    FULL         = 4'b0010,
                    ALMOST_FULL  = 4'b1000,
                    ALMOST_EMPTY = 4'b0100 } fifo_states_e;

  bit clk = 0;
  bit clr_n = 0;
  bit we = 0;
  bit rd = 0;
  bit empty, full, almost_empty, almost_full;
  bit [FIFO_WIDTH-1:0] data_in;
  bit [FIFO_WIDTH-1:0] data_out;
  bit [FIFO_WIDTH-1:0] test_data_out;

  bit [FIFO_WIDTH-1:0] fifo_model [FIFO_DEPTH-1:0];

  int write_ptr, read_ptr, data_count = 0;


  // clock generation
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
    .al_empty_out(almost_empty),
    .al_full_out(almost_full),
    .data_out(data_out)
  );  


  initial begin

    $timeformat(-9,0,"ns"); // ns resolution
    
    $info("Starting test with FIFO_WIDTH = %0d bits, FIFO_DEPTH = %0d, \
      CLOCK_PERIOD_NS = %0d ns", FIFO_WIDTH, FIFO_DEPTH, CLOCK_PERIOD_NS);
    
    $info("\nClearing FIFO...");
    
    #(2 * CLOCK_PERIOD_NS) clr_n = 1;
    // check initial status values and contents
    check_fifo_vals(fifo_model);
    check_fifo_status(EMPTY);

    $info("\nFilling FIFO...");
    // set write enable
    we = 1;
    // add a value every clock cycle and verify that the FIFO conents are correct
    for(int i = 0; i < FIFO_DEPTH; i++) begin 
      data_in = i;
      @(posedge(clk));
      $display("Wrote val: %0d to position %0d of FIFO model.", i, i);
      @(negedge(clk));
      // check internal values and reported status values
      check_fifo_vals(fifo_model);
      case(i)
        0              : check_fifo_status(ALMOST_EMPTY);
        FIFO_DEPTH - 2 : check_fifo_status(ALMOST_FULL);
        FIFO_DEPTH - 1 : check_fifo_status(FULL);
        default        : check_fifo_status(NORM);
      endcase
  
    end
    
    $info("\nEmptying FIFO...");
    // remove a value every clock cycle and verify that the FIFO conents are correct
    we = 0;
    rd = 1;
    
    for(int i = FIFO_DEPTH - 1; i >= 0; i--) begin 
      test_data_out = data_out;
      @(posedge(clk));
      @(negedge(clk));
      $display("Read val: %0d from position %0d of FIFO model.", data_out, (FIFO_DEPTH-1)-i);
      check_fifo_vals(fifo_model);
      assert(data_out == (FIFO_DEPTH-1-i));
      case(i)
        0              : check_fifo_status(EMPTY);
        1              : check_fifo_status(ALMOST_EMPTY);
        FIFO_DEPTH - 1 : check_fifo_status(ALMOST_FULL);
        default        : check_fifo_status(NORM);
      endcase
    end
    
    
    $info("\nRunning cases when Write Enable + Read Enable are set simultaneously:");

    $info("1. When FIFO is empty...");
    // with read enable still set, add a value and verify FIFO
    we = 1;
    data_in = 'hBEEF;
    
    @(posedge(clk));
    @(negedge(clk));
    check_fifo_vals(fifo_model);
    check_fifo_status(ALMOST_EMPTY);

    $info("2. When FIFO is full...");
    // firstly fill up the FIFO and then set read_enable and verify FIFO
    rd = 0;
    for(int i = 0; i < FIFO_DEPTH-1; i++) begin 
      data_in = 10 + i;
      @(posedge(clk));
    end
    @(negedge(clk));
    check_fifo_vals(fifo_model);
    data_in = 'hBEEF;
    @(posedge(clk));
    @(negedge(clk));
    check_fifo_vals(fifo_model);
    check_fifo_status(FULL);

    // verify FIFO with read/write enable both set on full FIFO
    rd = 1;
    
    @(posedge(clk));
    @(negedge(clk));
    check_fifo_vals(fifo_model);
    check_fifo_status(FULL);
    

    $info("\n*******************************\n",
            "* TEST FINISHED SUCCESSFULLY! *\n",
            "*******************************\n");
    $finish;

  end 

  /***************** Golden Model of fifo *****************/

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
    input bit [FIFO_WIDTH-1:0] fifo_arg [FIFO_DEPTH-1:0]
  );
    for(int idx = 0; idx < FIFO_DEPTH; idx++) begin 
      assert(fifo_arg[idx] == i_sync_fifo.fifo_block_r[idx])
      else $fatal(1, "@%0t: VALUE CHECK FAILED\n \
        FIFO Model : DUT - %0d : %0d", 
        $time, fifo_arg[idx], i_sync_fifo.fifo_block_r[idx]);
    end
  endfunction

  function void check_fifo_status ( logic [3:0] expected_status );
  // encoding bits {almost_full, almost_empty, full, empty}
    assert(expected_status == {almost_full, almost_empty, full, empty})
    else $fatal(1, "@%0t: STATUS CHECK FAILED!\n \
      EXPECTED:  almost_full = 0x%0h, almost_empty = 0x%0h, full = 0x%0h, empty = 0x%0h \n \
      FOUND   :  almost_full = 0x%0h, almost_empty = 0x%0h, full = 0x%0h, empty = 0x%0h", 
      $time, expected_status[3], expected_status[2], expected_status[1], expected_status[0],
      almost_full, almost_empty, full, empty); // WARN: GLOBAL VARIABLES USED

  endfunction



endmodule