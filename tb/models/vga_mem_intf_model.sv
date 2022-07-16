/*------------------------------------------------------------------------------
 Title      : VGA Memory Interface Model
 Project    : VGA Controller
--------------------------------------------------------------------------------
 File       : vga_mem_intf_model.sv
 Author(s)  : Thomas Szymkowiak
 Company    : TUNI
 Created    : 2022-07-01
 Design     : vga_model
 Platform   : -
 Standard   : SystemVerilog '17
--------------------------------------------------------------------------------
 Description: Behavioral model used to prototype the VGA memory interface
--------------------------------------------------------------------------------
 Revisions:
 Date        Version  Author  Description
 2022-07-16  1.0      TZS     Created
------------------------------------------------------------------------------*/

module vga_model;

/* define for monochrome display, comment out for colour and make sure 
pxl_width_c matches in vga_pkg.vhd */
//`define MONO 1
`define USE_SIMULATOR 1

  timeunit 1ns/1ps; 

  import "DPI-C" pure function int client_connect();
  import "DPI-C" pure function int client_send();
  import "DPI-C" pure function int client_close();
  import "DPI-C" pure function int add_pxl_to_client_buff_mono(int r, int g, int b, int pos);
  import "DPI-C" pure function int add_pxl_to_client_buff(int r, int g, int b, int pos);

/******************************************************************************/
/* PARAMETERS                                                                 */
/******************************************************************************/

  parameter SIMULATION_RUNTIME = 1s;

  parameter TOP_CLK_FREQ_HZ   =   100_000_000;
  parameter TOP_CLK_PERIOD_NS = 1_000_000_000 / TOP_CLK_FREQ_HZ;
  parameter PXL_CLK_FREQ_HZ   =    25_000_000;

  // height and width of display area in pixels
  parameter HEIGHT_PX     = 480;
  parameter WIDTH_PX      = 640;
  // number of pixels in each h_sync period
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

   // depth of each colour
  parameter DEPTH_COLR     = 1;
  parameter MONO_PXL_WIDTH = DEPTH_COLR;
  parameter COLR_PXL_WIDTH = DEPTH_COLR * 3;

  // define MONO/COLR encoding
  `ifdef MONO 
    parameter PXL_WIDTH = MONO_PXL_WIDTH;
  `else
    parameter PXL_WIDTH = COLR_PXL_WIDTH;
  `endif
  
  // memory definitions
  parameter PXL_PER_ROW    = 8;
  // BRAM width in bits and depth in rows
  parameter MEM_WIDTH      = PXL_PER_ROW * PXL_WIDTH;
  parameter MEM_DEPTH      = DISP_PXL_MAX / PXL_PER_ROW;
  parameter MEM_ADDR_WIDTH = $clog2(MEM_DEPTH-1);
  
  // use max value to calculate bit width of counter
  parameter PXL_CTR_WIDTH  = $clog2(PXL_CTR_MAX - 1);
  parameter LN_CTR_WIDTH   = $clog2(LINE_CTR_MAX - 1);
  parameter ROW_CTR_WIDTH  = $clog2(PXL_PER_ROW - 1);
  parameter DISP_CTR_WIDTH = $clog2(DISP_PXL_MAX - 1);

  `ifdef MONO
    parameter INIT_FILE = "../../build/RAM_INIT_monochrome.mem";
  `else  
    parameter INIT_FILE = "../../build/RAM_INIT_rgb.mem";
  `endif

/******************************************************************************/
/* VARIABLES AND TYPE DEFINITIONS                                             */
/******************************************************************************/
  
  typedef logic[PXL_WIDTH-1:0] pixel_t;

  logic                     clk_s, clk_px_s;
  logic                     rstn_s, rst_sync_s;
  logic [PXL_CTR_WIDTH-1:0] pxl_ctr_s;
  logic [LN_CTR_WIDTH-1:0]  line_ctr_s;
  logic                     colr_en_s;
  logic                     v_sync_s, h_sync_s;
  logic                     test_switch_s; 
  logic                     blank_s;
  logic                     kill_simulation_s = 0; // will finish simulation once set to 1
  
  pixel_t test_pxl_s, mem_pxl_s, disp_pxl_s;

  logic [MEM_ADDR_WIDTH-1:0] mem_addr_ctr_s;
  logic [ROW_CTR_WIDTH-1:0]  mem_pxl_ctr_s;
  
  // variables used as golden reference
  logic                      blank_golden_s;
  pixel_t                    mem_pxl_golden_s;
  logic [MEM_ADDR_WIDTH-1:0] mem_addr_ctr_golden_s;
  logic [ROW_CTR_WIDTH-1:0]  mem_pxl_ctr_golden_s;

  event mem_ctrl_done;

  bit [MEM_WIDTH-1:0] mem_arr_model [MEM_DEPTH-1:0];

  int position = 0;
  int r_val    = 0;
  int g_val    = 0;
  int b_val    = 0;
  int connect_result = -1;
  int add_pxl_result = -1;
  int send_result    = -1; 
  int close_result   = -1; 

/******************************************************************************/
/* MODULE INSTANCES                                                           */
/******************************************************************************/

  vga_clk_div #(
    .ref_clk_freq_g (TOP_CLK_FREQ_HZ),
    .px_clk_freq_g  (PXL_CLK_FREQ_HZ)
  ) i_vga_clk_div (
    .clk_i      (clk_s),
    .rstn_i     (rstn_s),
    .clk_px_out (clk_px_s)
  );

  rst_sync #(
    .SYNC_STAGES(3)
  ) i_rst_sync (
    .clk_i       (clk_px_s),
    .rstn_i      (rstn_s),
    .sync_rstn_o (rst_sync_s)
  );

  vga_pxl_counter i_vga_pxl_counter (
    .clk_i      (clk_px_s),
    .rstn_i     (rst_sync_s),
    .pxl_ctr_o  (pxl_ctr_s),
    .line_ctr_o (line_ctr_s)
  );

  vga_controller i_vga_controller (
    .clk_i       (clk_px_s),
    .rstn_i      (rst_sync_s),
    .pxl_ctr_i   (pxl_ctr_s),
    .line_ctr_i  (line_ctr_s),
    .colr_en_out (colr_en_s),
    .v_sync_out  (v_sync_s),
    .h_sync_out  (h_sync_s)
  );

  vga_pattern_gen i_vga_pattern_gen (
    .pxl_ctr_i  (pxl_ctr_s),
    .line_ctr_i (line_ctr_s),
    .colr_out   (test_pxl_s)
  );

  vga_colr_mux i_vga_colr_mux (
    .test_colr_i (test_pxl_s),
    .mem_colr_i  (mem_pxl_s),
    .en_i        (test_switch_s),
    .blank_i     (colr_en_s),
    .colr_out    (disp_pxl_s)
  );

/******************************************************************************/
/* MEMORY INITIALISATION                                                      */
/******************************************************************************/
  
  generate
    if (INIT_FILE != "") begin: use_init_file
      initial
        $readmemh(INIT_FILE, mem_arr_model, 0, MEM_DEPTH-1);
    end else begin: init_bram_to_zero
      integer ram_index;
      initial
        for (ram_index = 0; ram_index < MEM_DEPTH; ram_index = ram_index + 1)
          mem_arr_model[ram_index] = {MEM_WIDTH{1'b0}};
    end
  endgenerate

/******************************************************************************/
/* CLOCK/RESET AND IO GENERATION                                              */
/******************************************************************************/
  initial begin 
    clk_s  = 0;
    rstn_s = 0;

    test_switch_s = 0; // 1 = use memory, 0 = use pattern generator
    // release reset 10 cycles after start of simulation
    #(10 * TOP_CLK_PERIOD_NS) rstn_s = 1; 
  end

  always #(TOP_CLK_PERIOD_NS/2) clk_s = ~clk_s;

/******************************************************************************/
/* SIMULATION DRIVING LOGIC                                                   */                                                                             
/******************************************************************************/

  initial begin 
    
    fork
      /*********/
      begin 
        forever begin 
          run_mem_addr_ctrl_model(rst_sync_s, pxl_ctr_s, line_ctr_s, 
                                  mem_addr_ctr_golden_s, mem_pxl_ctr_golden_s);
        end
      end 
       /*********/
      begin
        
        forever begin
           // only run mem_buff once mem_addr_ctrl has run
           @(mem_ctrl_done);
           run_mem_buff_model(rst_sync_s, mem_addr_ctr_golden_s, mem_pxl_ctr_golden_s, 
                              blank_golden_s, mem_pxl_golden_s);
        end
      end
       /*********/
      begin
        // control simulation runtime
        #SIMULATION_RUNTIME;
        $info("[%0tns] Simulation Complete!", $time);
        `ifdef USE_SIMULATOR
          close_result = client_close();
        `endif
        $finish;

      end
       /*********/
    join

  end

/******************************************************************************/
/* MEMORY INTERFACE MODELS                                                    */
/******************************************************************************/
  // read before write BRAM memory model
  task static run_memory_model (
    input  bit [MEM_ADDR_WIDTH-1:0 ] addra,
    input  bit [MEM_WIDTH-1:0]       dina = '0,
    input  bit                       wea = 0,
    input  bit                       ena,
    output bit [MEM_WIDTH-1:0]       douta
  );
    begin 

      if(ena) begin
        douta = vga_model.mem_arr_model[addra];
        if(wea) 
            vga_model.mem_arr_model[addra] = dina; 
      end
      
    end
  endtask

/******************************************************************************/

  // memory address controller model
  task static run_mem_addr_ctrl_model (
    input  bit                      rstn_i,
    input  bit [PXL_CTR_WIDTH-1:0]  pxl_ctr_i,
    input  bit [LN_CTR_WIDTH-1:0]   line_ctr_i,
    inout  bit [MEM_ADDR_WIDTH-1:0] mem_addr_ctr_o,
    inout  bit [ROW_CTR_WIDTH-1:0]  mem_pxl_ctr_o
  );
    begin

      if(!rstn_i) begin
        
        mem_addr_ctr_o = '0; 
        mem_pxl_ctr_o  = '0;
        #1;

      end else begin

        @(posedge vga_model.clk_px_s); 
      
        if((line_ctr_i >= (V_B_PORCH_MAX_LNS)) && 
           (line_ctr_i < V_DISP_MAX_LNS) &&
           (pxl_ctr_i >= (H_B_PORCH_MAX_PX)) &&
           (pxl_ctr_i < H_DISP_MAX_PX)) begin

          if(mem_pxl_ctr_o == (PXL_PER_ROW-1)) begin

            mem_pxl_ctr_o <= '0;

            if(mem_addr_ctr_o == (MEM_DEPTH-1)) begin 
              mem_addr_ctr_o <= '0;
            end else begin 
              mem_addr_ctr_o <= mem_addr_ctr_o + 1;
            end

          end else begin

            mem_pxl_ctr_o <= mem_pxl_ctr_o + 1;

          end

        end
      end
    end
    // event to synchronise execution of mem_buff task
    -> mem_ctrl_done;
  endtask

/******************************************************************************/

  // memory buffer model
  task static run_mem_buff_model (
    input  bit     rstn_i,
    input  bit     [MEM_ADDR_WIDTH-1:0] mem_addr_ctr_i,
    input  bit     [ROW_CTR_WIDTH-1:0]  mem_pxl_ctr_i,
    output bit     disp_blank_o,
    output pixel_t disp_pxl_o
  );
    
    static bit init = 0;
    static bit buff_sel = 0; // 0: A, 1: B
    static bit [MEM_WIDTH-1:0]      buff_A_data, buff_B_data = '0;
    static bit [MEM_ADDR_WIDTH-1:0] buff_A_addr, buff_B_addr = '0;
    static bit [MEM_ADDR_WIDTH-1:0] internal_mem_ctr = '0;

    if(!rstn_i) begin 
      
      init         = 0;
      buff_sel     = 0;
      disp_blank_o = '0;
      disp_pxl_o   = '0;

    end else begin

      // Fill A and then B on first pass
      if(!init) begin 
        
        run_memory_model(internal_mem_ctr, , 0, 1, buff_A_data);
        buff_A_addr = internal_mem_ctr;
        internal_mem_ctr++;
        run_memory_model(internal_mem_ctr, , 0, 1, buff_B_data);
        buff_B_addr = internal_mem_ctr;
        internal_mem_ctr++;

        init = 1;
      
      end else begin
        
        if(!buff_sel) begin
          // if the memory address counter matches the buffer address, display the pixel
          if(buff_A_addr == mem_addr_ctr_i) begin
            disp_pxl_o   = buff_A_data[(mem_pxl_ctr_i*PXL_WIDTH)+:3];
            disp_blank_o = 0;
            
            // once A has been read, fill A and move to read B
            if(mem_pxl_ctr_i == PXL_PER_ROW - 1) begin               
              run_memory_model(internal_mem_ctr, , 0, 1, buff_A_data);
              buff_A_addr = internal_mem_ctr;
              internal_mem_ctr = (internal_mem_ctr == (MEM_DEPTH-1)) ? '0 : internal_mem_ctr + 1;
              buff_sel = ~buff_sel;
            end
          // if the memory address counter does not match the buffer address, blank the pixel
          end else begin 
            $warning("[%0tns] run_mem_buff_model(): Display Address does not match Buffer A Address.\n", $time,
                      "mem_addr_ctr_i = 0x%0h, buff_A_addr = 0x%0h", mem_addr_ctr_i, buff_A_addr);
            disp_pxl_o   = '0;
            disp_blank_o = 1;
          end

        end else begin 
          // if the memory address counter matches the buffer address, display the pixel
          if(buff_B_addr == mem_addr_ctr_i) begin
            disp_pxl_o   = buff_B_data[(mem_pxl_ctr_i*PXL_WIDTH)+:3];

            disp_blank_o = 0;
            
            //once B has been read, fill B and move to read A
            if(mem_pxl_ctr_i == PXL_PER_ROW - 1) begin               
              run_memory_model(internal_mem_ctr, , 0, 1, buff_B_data);
              buff_B_addr = internal_mem_ctr;
              internal_mem_ctr = (internal_mem_ctr == (MEM_DEPTH-1)) ? '0 : internal_mem_ctr + 1;
              buff_sel = ~buff_sel;
            end
          // if the memory address counter does not match the buffer address, blank the pixel
          end else begin 
            $warning("[%0tns] run_mem_buff_model(): Display Address does not match Buffer B Address.\n", $time,
                      "mem_addr_ctr_i = 0x%0h, buff_B_addr = 0x%0h", mem_addr_ctr_i, buff_B_addr);
            disp_pxl_o   = '0;
            disp_blank_o = 1;
          end
        end
      
      end
    end

  endtask

/******************************************************************************/
/* MEMORY INTERFACE MODULES                                                   */
/******************************************************************************/

  /* Memory Address Counter */
  vga_mem_addr_ctrl i_mem_addr_ctrl (
    .clk_i          (clk_px_s),   
    .rstn_i         (rst_sync_s),    
    .pxl_ctr_i      (pxl_ctr_s),       
    .line_ctr_i     (line_ctr_s),        
    .mem_addr_ctr_o (mem_addr_ctr_s),            
    .mem_pxl_ctr_o  (mem_pxl_ctr_s)          
  );

  /* Memory Buffers */
  //mem_buff_sv (
  //  .clk_i           (),
  //  .rstn_i          (), 
  //  .disp_addr_ctr_i (),          
  //  .disp_pxl_ctr_i  (),         
  //  .mem_data_i      (),     
  //  .mem_addr_o      (),     
  //  .disp_blank_o    (),       
  //  .disp_pxl_o      ()    
  //);

  /* Memory Module */
  //xilinx_dp_BRAM_sv #(
  //  .RAM_WIDTH(MEM_WIDTH),
  //  .RAM_DEPTH(MEM_DEPTH),
  //  .INIT_FILE("")
  //) i_xilinx_dp_bram (
  //  .addra (),      
  //  .addrb (),      
  //  .dina  (),     
  //  .dinb  (),     
  //  .clka  (),     
  //  .wea   (),    
  //  .web   (),    
  //  .ena   (),    
  //  .enb   (),    
  //  .douta (),      
  //  .doutb ()  
  //);

/******************************************************************************/
/* DPI Function Management                                                    */
/******************************************************************************/

  initial begin 
    
    `ifdef USE_SIMULATOR
      connect_result = client_connect();
      $info("client_connect() = %d", connect_result);
      if (connect_result != 0) begin 
        $error("client_connect() result = %d", connect_result);
        close_result = client_close();
        $finish;
      end
    `endif

    forever begin 

      @(posedge vga_model.clk_px_s);

      `ifdef USE_SIMULATOR
        // to stop simulator early, force kill_simulation to 1
        if (kill_simulation_s == 1) begin
          $warning("Kill switch engaged...");
          close_result = client_close();
          $finish;
        end

      `endif
      
      if ( (vga_model.line_ctr_s >= V_B_PORCH_MAX_LNS) && (vga_model.line_ctr_s < V_DISP_MAX_LNS) && 
           (vga_model.pxl_ctr_s  >= H_B_PORCH_MAX_PX)  && (vga_model.pxl_ctr_s  < H_DISP_MAX_PX) ) begin 
        
        position = vga_model.pxl_ctr_s - H_B_PORCH_MAX_PX;

        `ifdef USE_SIMULATOR

          `ifdef MONO
            // only 1 bit value used when mono display is desired
            r_val = int'(vga_model.disp_pxl_s);
            g_val = int'(vga_model.disp_pxl_s);
            b_val = int'(vga_model.disp_pxl_s);
            // use the line below for debugging
            //$display("[%0t] DEBUG: calling add_pxl_to_client_buff_mono(r=%d, g=%d, b=%d, pos=%d)", $time, r_val, g_val, b_val, position);
            add_pxl_result = add_pxl_to_client_buff_mono(r_val, g_val, b_val, position);
            
            if (add_pxl_result != 0) begin 
              $error("add_pxl_to_client_buff_mono() result = %d", add_pxl_result);
              close_result = client_close();
              $finish;
            end
          
          `else // MONO
          
            r_val = int'(vga_model.disp_pxl_s[0]);
            g_val = int'(vga_model.disp_pxl_s[1]);
            b_val = int'(vga_model.disp_pxl_s[2]);
            // use the line below for debugging
            //$display("[%0t] DEBUG: calling add_pxl_to_client_buff(r=%d, g=%d, b=%d, pos=%d)", $time, r_val, g_val, b_val, position);
            add_pxl_result = add_pxl_to_client_buff(r_val, g_val, b_val, position);
  
            if (add_pxl_result != 0) begin 
              $error("add_pxl_to_client_buff() result = %d", add_pxl_result);
              close_result = client_close();
              $finish;
            end
          
          `endif // MONO
        `endif // USE_SIMULATOR

      end 
      
      `ifdef USE_SIMULATOR
      
        else if ((vga_model.line_ctr_s >= V_B_PORCH_MAX_LNS) && (vga_model.line_ctr_s < V_DISP_MAX_LNS) && 
                 (vga_model.pxl_ctr_s == H_DISP_MAX_PX)) begin 
          
          //$info("Calling client_send()");
          send_result = client_send();
          if (send_result != 0) begin 
            $warning("client_send() result = %d", send_result);
            close_result = client_close();
            $finish;
          end
        end
      
      `endif

    end
  end

endmodule