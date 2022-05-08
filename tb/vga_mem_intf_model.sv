/*------------------------------------------------------------------------------
 Title      : VGA Memory Interface Model
 Project    : VGA Controller
--------------------------------------------------------------------------------
 File       : vga_mem_intf_model.sv
 Author(s)  : Thomas Szymkowiak
 Company    : TUNI
 Created    : 2022-05-08
 Design     : vga_mem_intf_model
 Platform   : -
 Standard   : VHDL'08
--------------------------------------------------------------------------------
 Description: Behavioral model used to prototype the VGA memory interface
--------------------------------------------------------------------------------
 Revisions:
 Date        Version  Author  Description
 2022-05-08  1.0      TZS     Created
------------------------------------------------------------------------------*/

// forward declarations
typedef class FIFOModel;
typedef class BRAMModel;
typedef class InterfaceModel;

// main modelling module
module vga_mem_intf_model;

  timeunit 1ns/1ps;

  parameter CLK_PERIOD_NS = 10;
  parameter SIMULATION_RUNTIME = 1ms;
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
  parameter MEM_ADDR_WIDTH  = $clog2(MEM_DEPTH - 1); 

  parameter ADDR_FIFO_WIDTH = MEM_ADDR_WIDTH;
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
  bit [MEM_ADDR_WIDTH-1:0] mem_addr_ctr  = '0; 

  bit [MEM_ADDR_WIDTH-1:0] fifo_mem_addr_ctr  = '0;

  bit [MEM_ADDR_WIDTH-1:0] addr_buff_0    = '0;
  bit [MEM_ADDR_WIDTH-1:0] addr_buff_1    = '0;

  bit [PXL_PER_ROW-1:0] [DEPTH_COLR-1:0] display_buff_0 = '0;
  bit [PXL_PER_ROW-1:0] [DEPTH_COLR-1:0] display_buff_1 = '0;

  bit [DEPTH_COLR-1:0] display_out = '0;                     

/**********************************/

  InterfaceModel #(.DATA_FIFO_WIDTH(DATA_FIFO_WIDTH),.ADDR_FIFO_WIDTH(ADDR_FIFO_WIDTH),
                   .DATA_FIFO_DEPTH(DATA_FIFO_DEPTH),.ADDR_FIFO_DEPTH(ADDR_FIFO_DEPTH),
                   .MEM_WIDTH(MEM_WIDTH),.MEM_ADDR_WIDTH(MEM_ADDR_WIDTH),
                   .DEPTH_COLR(DEPTH_COLR), .PXL_PER_ROW(PXL_PER_ROW)) intf_model;
  
  // clock generation
  initial
    forever #(CLK_PERIOD_NS/2) clk <= ~clk;

  // test bench block
  initial begin 

    $timeformat(-9, 0, "ns");

    intf_model = new();

    fork
      
      begin 
        intf_model.run_interface(clk, mem_data_ctr,
                                 addr_buff_0, addr_buff_1, 
                                 display_buff_0, display_buff_1);
      end
  
      begin
        // control simulation runtime
        #SIMULATION_RUNTIME;
        $finish;
      end
  
    join
    
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

  // process to choose what should be displayed
  always_comb begin

    if(intf_model.buff_sel) begin // if buff 1 is selected
      // display data in data buffer if address in the addr buffer matches the counter
      if(mem_addr_ctr == addr_buff_1) begin 
        display_out = display_buff_1[(mem_data_ctr*DEPTH_COLR)+:3]; // extract display pixels from array
      end else begin
        display_out = '0;
      end
    end else begin // if buff 0 is selected
      if(mem_addr_ctr == addr_buff_0) begin 
        display_out = display_buff_0[(mem_data_ctr*DEPTH_COLR)+:3];
      end else begin
        display_out = '0;
      end
    end
    
  end

endmodule

/**********************************/

class InterfaceModel #(
  parameter DATA_FIFO_WIDTH = 48,
  parameter ADDR_FIFO_WIDTH = 13,
  parameter DATA_FIFO_DEPTH = 10,
  parameter ADDR_FIFO_DEPTH = 10,
  parameter MEM_WIDTH = 48,
  parameter MEM_ADDR_WIDTH = 13,
  parameter DEPTH_COLR = 3,
  parameter PXL_PER_ROW
);

  localparam MEM_DATA_CTR_WIDTH = $clog2(MEM_WIDTH/DEPTH_COLR);
  
  FIFOModel #(.WIDTH(DATA_FIFO_WIDTH), .DEPTH(DATA_FIFO_DEPTH)) fifo_data_model;
  FIFOModel #(.WIDTH(ADDR_FIFO_WIDTH), .DEPTH(ADDR_FIFO_DEPTH)) fifo_addr_model;
  BRAMModel #(.DATA_WIDTH(MEM_WIDTH), .ADDR_WIDTH(MEM_ADDR_WIDTH), .DEPTH_COLR(DEPTH_COLR)) ram_model;

  bit [MEM_WIDTH-1:0]       tmp_data = '0;
  bit [MEM_ADDR_WIDTH-1: 0] fifo_addr_counter = '0;
  bit buff_sel = 0, 
      buff_0_init = 0;

  function new();
    $display("@%0t: Created FIFOModel instance with data_fifo_width: %0d and depth: %0d\n", 
              $time, DATA_FIFO_WIDTH, DATA_FIFO_DEPTH, 
              "\taddr_fifo_width: %0d and depth: %0d\n",ADDR_FIFO_WIDTH, ADDR_FIFO_DEPTH,
              "\tmem width: %0d, addr width: %0d and colour depth: %0d", MEM_WIDTH, MEM_ADDR_WIDTH,DEPTH_COLR);
     fifo_data_model = new();
     fifo_addr_model = new();
     ram_model       = new();
  endfunction

  task run_interface(ref bit clk,
                     ref bit [MEM_DATA_CTR_WIDTH-1:0] mem_data_ctr,
                     ref bit [ADDR_FIFO_WIDTH-1:0] addr_buff_0,
                     ref bit [ADDR_FIFO_WIDTH-1:0] addr_buff_1,
                     ref bit [MEM_WIDTH-1:0] display_buff_0,
                     ref bit [MEM_WIDTH-1:0] display_buff_1                     
                    );
    
    $display("@%0t: Running interface...", $time);
    
    fork 
      begin
        forever begin
          @(negedge clk); // synchronise execution (evaluate conditions on the negedge)
          // fill the FIFO as long as it is not full
          if(!fifo_data_model.full) begin
            ram_model.read_val(clk, fifo_addr_counter, tmp_data);
            fifo_data_model.write_val(clk, tmp_data);
            fifo_addr_model.write_val(clk, fifo_addr_counter);
            fifo_addr_counter++;
          end
        end
      end 
      begin
        forever begin
           @(negedge clk); // synchronise execution (evaluate conditions on the negedge)
           if(!buff_0_init) begin // if buffers have not been initialised yet
             if(!fifo_data_model.empty) begin  // once FIFO has a value, read into the buffer
               fifo_data_model.read_val(clk, display_buff_0);
               fifo_addr_model.read_val(clk, addr_buff_0);
               buff_0_init    = 1;
               $display("@%0t: Initialised Buffer 0. Data: 0x%0h, Addr: 0x%0h", $time, display_buff_0, addr_buff_0);
             end
           end else begin
             // if reading last pixel of the memory line and FIFO is empty
             if((mem_data_ctr == PXL_PER_ROW-2) && !fifo_data_model.empty) begin 
               // if currently reading from buffer 1, read a new value into buffer 0
               if(buff_sel) begin 
                 fifo_data_model.read_val(clk, display_buff_0);
                 fifo_addr_model.read_val(clk, addr_buff_0);
                 $display("@%0t: Wrote Buffer 0. Data: 0x%0h, Addr: 0x%0h", $time, display_buff_0, addr_buff_0);
                 // if currently reading from buffer 0, read a new value into buffer 1
               end else begin  
                 fifo_data_model.read_val(clk, display_buff_1);
                 fifo_addr_model.read_val(clk, addr_buff_1);
                 $display("@%0t: Wrote Buffer 1. Data: 0x%0h, Addr: 0x%0h", $time, display_buff_1, addr_buff_1);
               end
               buff_sel = ~buff_sel; // swap selected display buffer
             end 
           end
        end 
      end
    join

  endtask;

endclass;

/**********************************/

class FIFOModel #(
  parameter WIDTH = 10,
  parameter DEPTH = 10
);

  function new();
    $display("@%0t: Created FIFOModel instance with width: %0d and depth: %0d", 
             $time, WIDTH, DEPTH);
  endfunction

  int width    = WIDTH;
  int depth    = DEPTH;
  bit full     = 0;
  bit al_full  = 0;
  bit empty    = 1;
  bit al_empty = 0;

  logic [WIDTH-1:0] fifo [$:DEPTH-1]; // fifo modelled using queue

  // write a value and update status attribute(s)
  task write_val(ref bit clk, input bit [WIDTH-1:0] val);
    @(posedge clk);

    if(!full)
      fifo.push_front(val);

    if(empty) begin
      empty = 0;
      al_empty = 1;
    end else if(al_empty)
      al_empty = 0;

    if(al_full) begin
      full = 1;
      al_full  = 0;
    end else if(fifo.size() == (depth - 2))
      al_full = 1;
  endtask

  // read a value and update status attribute(s)
  task read_val(ref bit clk, ref bit [WIDTH-1:0] read_val);
    
    @(posedge clk);

    if(full) begin
      full    = 0;
      al_full = 1;
    end else if(al_full)
      al_full = 0;

    if(al_empty) begin
        empty  = 1;
        al_empty = 0;
    end else if(fifo.size == 2)
      al_empty = 1;

    read_val = fifo.pop_back();

  endtask

endclass

/**********************************/

class BRAMModel #(
  parameter DATA_WIDTH = 48,
  parameter ADDR_WIDTH = 16,
  parameter DEPTH_COLR = 3
);
  localparam DEPTH = int'($pow(2, ADDR_WIDTH));
  logic [DEPTH-1:0] [DATA_WIDTH-1:0] ram;

  function new();
    $display("@%0t: Created BRAMModel instance with width: %0d and depth: %0d", 
             $time, DATA_WIDTH, DEPTH);
    // populate RAM with initial values (each line is populated with its own address)
    for(int addr = 0; addr < DEPTH; addr++) begin 
      ram[addr] = addr;
    end
  endfunction 
  
  // read a value from memory synchronously
  task read_val(ref    bit   clk,
                input  logic [ADDR_WIDTH-1:0] addr, 
                output logic [DATA_WIDTH-1:0] data
  );
    @(posedge clk);
    data = ram[addr];
    //$display("@%0t: \tread value 0x%0h from ram_model address 0x%0h", $time, data, addr);
  endtask

  // write a value to memory synchronously
  task write_val(ref   bit   clk,
                 input logic [DATA_WIDTH-1:0] data, 
                 input logic [ADDR_WIDTH-1:0] addr
  );
    @(posedge clk);
    ram[addr] = data;
    //$display("@%0t: \twrote value 0x%0h from ram_model address 0x%0h", $time, data, addr);
  endtask

endclass

/**********************************/