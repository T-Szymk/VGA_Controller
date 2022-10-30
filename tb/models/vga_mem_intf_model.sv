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
 2022-07-22  1.1      TZS     Updated model to handle resets
 2022-08-06  1.2      TZS     Added tiling to model and refactored mem_buff
------------------------------------------------------------------------------*/

module vga_model;

/* define for monochrome display, comment out for colour and make sure 
pxl_width_c matches in vga_pkg.vhd */
//`define MONO 1
`define USE_SIMULATOR 1

  timeunit 1ns/1ps; 

  import "DPI-C" pure function int client_connect();
  import "DPI-C" pure function int client_send_reset();
  import "DPI-C" pure function int client_send_data();
  import "DPI-C" pure function int client_close();
  import "DPI-C" pure function int add_pxl_to_client_buff_mono(int r, int g, int b, int pos);
  import "DPI-C" pure function int add_pxl_to_client_buff(int r, int g, int b, int pos);

/******************************************************************************/
/* PARAMETERS                                                                 */
/******************************************************************************/

  `ifdef MONO
    parameter INIT_FILE = "../../build/RAM_INIT_monochrome.mem";
  `else  
    parameter INIT_FILE = "../../supporting_apps/mem_file_gen/pulla.mem";
  `endif

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
  parameter DEPTH_COLR     = 4;
  parameter MONO_PXL_WIDTH = DEPTH_COLR;
  parameter COLR_PXL_WIDTH = DEPTH_COLR * 3;

  // define MONO/COLR encoding
  `ifdef MONO 
    parameter PXL_WIDTH = MONO_PXL_WIDTH;
  `else
    parameter PXL_WIDTH = COLR_PXL_WIDTH;
  `endif

  // set size n of tile (nxn). If not tiling is desired, set to 1. 
  parameter TILE_WIDTH     = 4;
  parameter TILE_SHIFT     = $clog2(TILE_WIDTH);
  parameter TILE_PER_LINE  = WIDTH_PX / TILE_WIDTH;
  parameter TILE_CTR_WIDTH = $clog2(TILE_PER_LINE);

  // use max value to calculate bit width of counter
  parameter PXL_CTR_WIDTH  = $clog2(PXL_CTR_MAX - 1);
  parameter LN_CTR_WIDTH   = $clog2(LINE_CTR_MAX - 1);

  // memory definitions
  parameter TILE_PER_ROW = 4;
  
  // BRAM width in bits
  parameter FBUFF_DATA_WIDTH  = TILE_PER_ROW * PXL_WIDTH;
  parameter ROW_CTR_WIDTH     = $clog2(TILE_PER_ROW - 1);
  // BRAM width in bits and depth in rows after tiling has been applied.
  parameter FBUFF_DEPTH      = (DISP_PXL_MAX / (TILE_PER_ROW * TILE_WIDTH * TILE_WIDTH));
  parameter FBUFF_ADDR_WIDTH = $clog2(FBUFF_DEPTH-1);

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
  logic                     kill_simulation_s = 0; // will finish simulation once set to 1
  
  wire [1:0]                   buff_fill_done_s, buff_fill_req_s, buff_sel_s;
  wire                         fbuff_read_req_s, fbuff_read_rsp_s;
  wire [TILE_CTR_WIDTH-1:0]    disp_pxl_id_s;
  wire [FBUFF_DATA_WIDTH-1:0]  fbuff_data_out_s;
  wire [FBUFF_ADDR_WIDTH-1:0]  dut_fbuff_addr_s;

  pixel_t test_pxl_s, mem_pxl_s, disp_pxl_s;
  
  // variables used as golden reference
  logic   disp_active_golden_s;
  pixel_t mem_pxl_golden_s;

  bit [FBUFF_DATA_WIDTH-1:0] mem_arr_model [FBUFF_DEPTH-1:0];

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
    .mem_colr_i  (mem_pxl_s), // (mem_pxl_golden_s),
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
        $readmemb(INIT_FILE, mem_arr_model, 0, FBUFF_DEPTH-1);
    end else begin: init_bram_to_zero
      integer ram_index;
      initial
        for (ram_index = 0; ram_index < FBUFF_DEPTH; ram_index = ram_index + 1)
          mem_arr_model[ram_index] = {FBUFF_DATA_WIDTH{1'b0}};
    end
  endgenerate

/******************************************************************************/
/* CLOCK/RESET AND IO GENERATION                                              */
/******************************************************************************/
  initial begin 
    clk_s  = 0;
    rstn_s = 0;

    test_switch_s = 1; // 1 = use memory, 0 = use pattern generator
    // release reset 10 cycles after start of simulation
    #(10 * TOP_CLK_PERIOD_NS) rstn_s = 1; 
  end

  always #(TOP_CLK_PERIOD_NS/2) clk_s = ~clk_s;

/******************************************************************************/
/* SIMULATION DRIVING LOGIC                                                   */                                                                             
/******************************************************************************/

  initial begin 
    
    fork
      begin
        
        forever begin
          @(posedge vga_model.clk_px_s);

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
    input  bit [FBUFF_ADDR_WIDTH-1:0 ] addra,
    input  bit [FBUFF_DATA_WIDTH-1:0]       dina = '0,
    input  bit                       wea = 0,
    input  bit                       ena,
    output bit [FBUFF_DATA_WIDTH-1:0]       douta
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
  task automatic run_line_buff_ctrl_model (

  );
    begin



    end
  endtask

/******************************************************************************/

  // memory buffer model
  task automatic run_mem_buff_model (
  );
    
    begin 
    end

  endtask

/******************************************************************************/

function automatic bit [FBUFF_ADDR_WIDTH-1:0] get_mem_addr(
  input bit [PXL_CTR_WIDTH-1:0] pxl_val_i,
  input bit [LN_CTR_WIDTH-1:0]  line_val_i
);

  bit [PXL_CTR_WIDTH-TILE_SHIFT-1:0] tiled_pxl_val = pxl_val_i[PXL_CTR_WIDTH-1:TILE_SHIFT];
  bit [LN_CTR_WIDTH-TILE_SHIFT-1:0]  tiled_ln_val  = line_val_i[LN_CTR_WIDTH-1:TILE_SHIFT];

  get_mem_addr = (tiled_pxl_val + ((WIDTH_PX/TILE_WIDTH) * tiled_ln_val)) / TILE_PER_ROW;

endfunction

/******************************************************************************/
/* MEMORY INTERFACE MODULES                                                   */
/******************************************************************************/

  line_buff_ctrl #(
    .WIDTH_PX          ( WIDTH_PX          ),          
    .HEIGHT_LNS        ( HEIGHT_PX         ),        
    .H_B_PORCH_MAX_PX  ( H_B_PORCH_MAX_PX  ),  
    .V_B_PORCH_MAX_LNS ( V_B_PORCH_MAX_LNS ), 
    .TILE_WIDTH        ( TILE_WIDTH        ),        
    .PXL_CTR_WIDTH     ( PXL_CTR_WIDTH     ),     
    .LN_CTR_WIDTH      ( LN_CTR_WIDTH      ),      
    .TILE_PER_LINE     ( TILE_PER_LINE     ),      
    .TILE_CTR_WIDTH    ( TILE_CTR_WIDTH    )
  ) i_line_buff_ctrl (
    .clk_i            ( clk_px_s         ),
    .rstn_i           ( rst_sync_s       ),
    .buff_fill_done_i ( buff_fill_done_s ),
    .pxl_cntr_i       ( pxl_ctr_s        ),
    .ln_cntr_i        ( line_ctr_s       ),
    .buff_fill_req_o  ( buff_fill_req_s  ),
    .buff_sel_o       ( buff_sel_s       ),
    .disp_pxl_id_o    ( disp_pxl_id_s    )
  );

  line_buffers #(
    .COLR_PXL_WIDTH   ( PXL_WIDTH        ),         
    .TILE_WIDTH       ( TILE_WIDTH       ),     
    .WIDTH_PX         ( WIDTH_PX         ),
    .FBUFF_DEPTH      ( FBUFF_DEPTH      ),   
    .FBUFF_ADDR_WIDTH ( FBUFF_ADDR_WIDTH ),           
    .FBUFF_DATA_WIDTH ( FBUFF_DATA_WIDTH ),      
    .TILES_PER_ROW    ( TILE_PER_ROW     ),        
    .TILE_PER_LINE    ( TILE_PER_LINE    )
  ) i_line_buffers (
    .clk_i            ( clk_px_s         ),  
    .rstn_i           ( rst_sync_s       ),   
    .buff_fill_req_i  ( buff_fill_req_s  ),            
    .buff_sel_i       ( buff_sel_s       ),       
    .disp_pxl_id_i    ( disp_pxl_id_s    ),          
    .fbuff_data_i     ( fbuff_data_out_s ), 
    .fbuff_rd_rsp_i   ( fbuff_read_rsp_s ),        
    .buff_fill_done_o ( buff_fill_done_s ),             
    .disp_pxl_o       ( mem_pxl_s        ),
    .fbuff_rd_req_o   ( fbuff_read_req_s ),
    .fbuff_addra_o    ( dut_fbuff_addr_s )  
  );

    frame_buffer #(
    .FBUFF_ADDR_WIDTH ( FBUFF_ADDR_WIDTH ),
    .FBUFF_WIDTH      ( FBUFF_DATA_WIDTH ),
    .FBUFF_DEPTH      ( FBUFF_DEPTH      ),
    .INIT_FILE        ( INIT_FILE        )
  ) i_frame_buffer (
    .clk_i    ( clk_px_s         ),
    .rstn_i   ( rst_sync_s       ),
    .addra_i  ( dut_fbuff_addr_s ),
    .dina_i   ( '0               ),     
    .wea_i    ( 1'b0             ),   
    .ena_i    ( 1'b1             ),   
    .rd_req_i ( fbuff_read_req_s ),
    .rd_rsp_o ( fbuff_read_rsp_s ),
    .douta    ( fbuff_data_out_s )
  );

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

      @(posedge vga_model.clk_px_s or negedge vga_model.rstn_s);
    
      // If reset is asserted and the Simulator is in use, send reset string to 
      // server to indicate the screen should be cleared.

      if (!vga_model.rstn_s) begin
        
        `ifdef USE_SIMULATOR

          send_result = client_send_reset();
          
          if (send_result != 0) begin 
            $warning("client_send_reset() result = %d", send_result);
            close_result = client_close();
            $finish;
          end
        `endif // USE_SIMULATOR

          #1; // prevent infinite looping

      end else begin 

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
            
              r_val = int'(vga_model.disp_pxl_s[0*DEPTH_COLR+:DEPTH_COLR]);
              g_val = int'(vga_model.disp_pxl_s[1*DEPTH_COLR+:DEPTH_COLR]);
              b_val = int'(vga_model.disp_pxl_s[2*DEPTH_COLR+:DEPTH_COLR]);
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
            
            //$info("Calling client_send_data()");
            send_result = client_send_data();
            if (send_result != 0) begin 
              $warning("client_send_data() result = %d", send_result);
              close_result = client_close();
              $finish;
            end
          end
        
        `endif

      end
    end
  end

endmodule