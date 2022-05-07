/*------------------------------------------------------------------------------
 Title      : VGA Memory Interface Model
 Project    : VGA Controller
--------------------------------------------------------------------------------
 File       : vga_mem_intf_model.sv
 Author(s)  : Thomas Szymkowiak
 Company    : TUNI
 Created    : 2022-05-07
 Design     : vga_mem_intf_model
 Platform   : -
 Standard   : VHDL'08
--------------------------------------------------------------------------------
 Description: Behavioral model used to prototype the VGA memory interface
--------------------------------------------------------------------------------
 Revisions:
 Date        Version  Author  Description
 2022-05-07  1.0      TZS     Created
------------------------------------------------------------------------------*/

// forward declarations
typedef class FIFOModel;
typedef class BRAMModel;

// main modelling module
module vga_mem_intf_model;

  timeunit 1ns/1ps;

  parameter CLK_PERIOD_NS = 10;
  // depth of each colour
  parameter DEPTH_COLR    = 3;
  // BRAM width in bits and depth in rows
  parameter MEM_WIDTH     = 48;
  parameter MEM_DEPTH     = 6400;
  // count of how many pixels are in each line of memory
  parameter PXL_PER_ROW   = MEM_WIDTH / DEPTH_COLR; 
  // height and width of display area in pixels
  parameter HEIGHT_PX     = 480;
  parameter WIDTH_PX      = 640;
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

  parameter V_SYNC_MAX_LNS    = V_SYNC_LNS;
  parameter V_B_PORCH_MAX_LNS = V_SYNC_MAX_LNS + V_B_PORCH_LNS;
  parameter V_DISP_MAX_LNS    = V_B_PORCH_MAX_LNS + HEIGHT_PX;
  parameter V_F_PORCH_MAX_LNS = V_DISP_MAX_LNS + V_F_PORCH_LNS;
  parameter H_SYNC_MAX_PX     = H_SYNC_PX;
  parameter H_B_PORCH_MAX_PX  = H_SYNC_MAX_PX + H_B_PORCH_PX;
  parameter H_DISP_MAX_PX     = H_B_PORCH_MAX_PX + WIDTH_PX;
  parameter H_F_PORCH_MAX_PX  = H_DISP_MAX_PX + H_F_PORCH_PX;

  parameter DISP_PXL_MAX      = HEIGHT_PX * WIDTH_PX;

  // use max value to calculate bit width of counter
  parameter PXL_CTR_WIDTH  = $clog2(PXL_CTR_MAX - 1);
  parameter LN_CTR_WIDTH   = $clog2(LINE_CTR_MAX - 1);
  parameter DISP_PXL_WIDTH = $clog2(DISP_PXL_MAX - 1);

  parameter MEM_DATA_CTR_WIDTH  = $clog2(PXL_PER_ROW - 1);
  parameter MEM_ADDR_CTR_WIDTH  = $clog2(MEM_DEPTH - 1); 

  parameter ADDR_FIFO_WIDTH = $clog2(MEM_DEPTH - 1);
  parameter DATA_FIFO_WIDTH = MEM_WIDTH; 

  parameter ADDR_FIFO_DEPTH = 10;
  parameter DATA_FIFO_DEPTH = 10;



/**********************************/

  bit [PXL_CTR_WIDTH-1:0]  pxl_ctr  = '0;
  bit [LN_CTR_WIDTH-1:0]   ln_ctr   = '0;
  bit [DISP_PXL_WIDTH-1:0] disp_ctr = '0;
  bit [DEPTH_COLR-1:0]     colr     = '0;
  bit clk = 0;

  bit [MEM_DATA_CTR_WIDTH-1:0] mem_data_ctr  = '0;
  bit [MEM_ADDR_CTR_WIDTH-1:0] mem_addr_ctr  = '0; 

/**********************************/

  initial
    forever #(CLK_PERIOD_NS/2) clk <= ~clk;

  logic [ADDR_FIFO_WIDTH-1:0] test_val = {(ADDR_FIFO_WIDTH){4'hA}}, test_val_1 = '0;
  
  FIFOModel #(.WIDTH(DATA_FIFO_WIDTH), .DEPTH(DATA_FIFO_WIDTH)) fifo_data_model;
  FIFOModel #(.WIDTH(ADDR_FIFO_WIDTH), .DEPTH(ADDR_FIFO_WIDTH)) fifo_addr_model;
  BRAMModel #(.DATA_WIDTH(MEM_WIDTH), .ADDR_WIDTH(MEM_DEPTH)) ram_model;

  initial begin 

    fifo_data_model = new();
    fifo_addr_model = new();
    ram_model  = new();

    #1s;
    
    $finish;
  
  end

  // continuously count through pixels and lines
  always_ff @(posedge clk) begin : global_pxl_counter

    if(pxl_ctr == PXL_CTR_MAX-1) begin

        pxl_ctr = 0;

        if (ln_ctr == LINE_CTR_MAX - 1) begin
          ln_ctr = 0;
        end else begin
          ln_ctr++;
        end

    end else begin

        pxl_ctr++;

    end

  end : global_pxl_counter

  // counter for display pixels and current memory address
  always_ff @(posedge clk) begin : display_pxl_counter
    
    if (ln_ctr > (V_B_PORCH_MAX_LNS - 1) && ln_ctr < V_DISP_MAX_LNS) begin 
      if(pxl_ctr > (H_B_PORCH_MAX_PX - 1) && pxl_ctr < H_DISP_MAX_PX) begin 
        
        // one dimensional display pxl counters
        if(disp_ctr == (DISP_PXL_MAX - 1)) begin 
          disp_ctr <= '0;
        end else begin 
          disp_ctr++;
        end

        // counter to determine the location in the currently held memory line corresponds to the pixel being displayed
        if(mem_data_ctr == PXL_PER_ROW - 1) begin 
          mem_data_ctr <= '0;
          // counter to determine which memory line corresponds to the currently displayed pixel
          mem_addr_ctr = (mem_addr_ctr == (MEM_DEPTH - 1)) ? '0 : mem_addr_ctr + 1;
        end else begin 
          mem_data_ctr++;
        end

      end
    end

  end 


endmodule

/**********************************/

/**********************************/

class FIFOModel #(
  parameter WIDTH = 10,
  parameter DEPTH = 10
);

  function new();
    $display("@%0t: Created FIFOModel instance with width: %0d and depth: %0d", 
             $time, WIDTH, DEPTH);
  endfunction

  int width  = WIDTH;
  int depth  = DEPTH;
  bit full   = 0;
  bit empty  = 1;

  logic [WIDTH-1:0] fifo [$:DEPTH-1]; // fifo modelled using queue

  // write a value and update status attribute(s)
  function void write_val(input logic [WIDTH-1:0] val);
    if(empty)
        empty = 0;
    if(fifo.size() == (depth - 1))
        full = 1;
    fifo.push_front(val);
  endfunction

  // read a value and update status attribute(s)
  function logic [WIDTH-1:0] read_val();
    if(full) 
        full = 0;
    if(fifo.size == 1)
        empty = 1;
    return fifo.pop_back();
  endfunction

endclass

/**********************************/

class BRAMModel #(
  parameter DATA_WIDTH = 48,
  parameter ADDR_WIDTH = 16
);
  localparam DEPTH = int'($pow(2, ADDR_WIDTH));
  logic [DEPTH-1:0] [DATA_WIDTH-1:0] ram;

  function new();
    $display("@%0t: Created BRAMModel instance with width: %0d and depth: %0d", 
             $time, DATA_WIDTH, DEPTH);
    ram = '0;
  endfunction 
  
  // read a value from memory synchronously
  task read_val(ref    bit   clk,
                input  logic [ADDR_WIDTH-1:0] addr, 
                output logic [DATA_WIDTH-1:0] data
  );
    @(posedge clk);
    data = ram[addr];
  endtask

  // write a value to memory synchronously
  task write_val(ref   bit   clk,
                 input logic [DATA_WIDTH-1:0] data, 
                 input logic [ADDR_WIDTH-1:0] addr
  );
    @(posedge clk);
    ram[addr] = data;
  endtask

endclass

/**********************************/