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
 2022-07-01  1.0      TZS     Created
------------------------------------------------------------------------------*/

module vga_model;

//`define MONO 1 // define for monochrome display, comment out for colour 

timeunit 1ns/1ps;

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
  logic                     test_switch_s, blank_s;
  
  pixel_t test_pxl_s, mem_pxl_s, disp_pxl_s;

  logic [MEM_ADDR_WIDTH-1:0] mem_addr_ctr_s;
  logic [ROW_CTR_WIDTH-1:0]  mem_pxl_ctr_s;

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
/* CLOCK AND RESET GENERATION                                                 */
/******************************************************************************/

  always #(TOP_CLK_PERIOD_NS/2) clk_s = ~clk_s;
  // release reset 10 cycles after start of simulation
  assign #(10 * TOP_CLK_PERIOD_NS) rstn_s = 1; 

/******************************************************************************/
/* SIMULATION DRIVING LOGIC                                                   */                                                                             
/******************************************************************************/

  initial begin 
    
    fork
      /*********/
      begin 
        forever begin 
          run_mem_addr_ctrl_model(rst_sync_s, pxl_ctr_s, line_ctr_s, 
                                  mem_addr_ctr_s, mem_pxl_ctr_s);
        end
      end 
       /*********/
      begin
        
        forever begin
           run_mem_buff_model(rst_sync_s, mem_addr_ctr_s, mem_pxl_ctr_s, 
                              blank_s, mem_pxl_s);
        end
      end
       /*********/
      begin
        
        // control simulation runtime
        #SIMULATION_RUNTIME;
        $info("[%0tns] Simulation Complete!", $time);
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

      static bit [MEM_DEPTH-1:0][MEM_WIDTH-1:0] mem_arr_model = '0;

      if(ena) begin
        douta = mem_arr_model[addra];
        if(wea) 
            mem_arr_model[addra] = dina; 
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
      
        if((line_ctr_i > (V_B_PORCH_MAX_LNS)) && 
           (line_ctr_i < V_DISP_MAX_LNS) &&
           (pxl_ctr_i > (H_B_PORCH_MAX_PX-1)) &&
           (pxl_ctr_i < H_DISP_MAX_PX)) begin

          if(mem_pxl_ctr_o == (PXL_PER_ROW-1)) begin

            mem_pxl_ctr_o = '0;

            if(mem_addr_ctr_o == (MEM_DEPTH-1)) begin 
              mem_addr_ctr_o = '0;
            end else begin 
              mem_addr_ctr_o++;
            end

          end else begin

            mem_pxl_ctr_o++;

          end

        end
      end
    end
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
      #1;
    end else begin

      @(posedge vga_model.clk_px_s); 

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
          if(buff_A_addr == mem_addr_ctr_i) begin
            disp_pxl_o   = buff_A_data[(mem_pxl_ctr_i*PXL_WIDTH)+:3];
            disp_blank_o = 0;
            
            // once A has been read, fill A and move to read B
            if(mem_addr_ctr_i == DISP_PXL_MAX - 1) begin               
              run_memory_model(internal_mem_ctr, , 0, 1, buff_A_data);
              buff_A_addr = internal_mem_ctr;
              internal_mem_ctr++;
              buff_sel = ~buff_sel;
            end

          end else begin 
            $warning("[%0tns] run_mem_buff_model(): Display Address does not match Buffer A Address.\n",
                      "mem_addr_ctr_i = 0x%0h, buff_A_addr = 0x%0h", $time, mem_addr_ctr_i, buff_A_addr);
            disp_pxl_o   = '0;
            disp_blank_o = 1;
          end

        end else begin 
          if(buff_B_addr == mem_addr_ctr_i) begin
            disp_pxl_o   = buff_B_data[(mem_pxl_ctr_i*PXL_WIDTH)+:3];
            disp_blank_o = 0;
            
            //once B has been read, fill B and move to read A
            if(mem_addr_ctr_i == DISP_PXL_MAX - 1) begin               
              run_memory_model(internal_mem_ctr, , 0, 1, buff_B_data);
              buff_B_addr = internal_mem_ctr;
              internal_mem_ctr++;
              buff_sel = ~buff_sel;
            end

          end else begin 
            $warning("[%0tns] run_mem_buff_model(): Display Address does not match Buffer B Address.\n",
                      "mem_addr_ctr_i = 0x%0h, buff_B_addr = 0x%0h", $time, mem_addr_ctr_i, buff_B_addr);
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
  //mem_addr_ctrl_sv (
  //  .clk_i          (),   
  //  .rstn_i         (),    
  //  .pxl_ctr_i      (),       
  //  .line_ctr_i     (),        
  //  .mem_addr_ctr_o (),            
  //  .mem_pxl_ctr_o  ()          
  //);

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

endmodule