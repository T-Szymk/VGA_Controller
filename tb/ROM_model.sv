/*------------------------------------------------------------------------------
 Title      : ROM Model
 Project    : VGA Controller
--------------------------------------------------------------------------------
 File       : ROM_model.sv
 Author(s)  : Thomas Szymkowiak
 Company    : TUNI
 Created    : 2021-09-21
 Design     : ROM_model
 Platform   : -
 Standard   : VHDL'08
--------------------------------------------------------------------------------
 Description: Parameterised ROM model used to develop VGA memory controller.
--------------------------------------------------------------------------------
 Revisions:
 Date        Version  Author  Description
 2021-09-21  1.0      TZS     Created
------------------------------------------------------------------------------*/
`timescale 1ns / 1ps

module ROM_model #(WIDTH = 8, DEPTH = 16) (
    input  logic clk,
    input  logic rst_n,
    input  logic [$clog2(DEPTH)-1:0] addr_in,
    input  logic rd_en_in,

    output logic [WIDTH-1:0] led_out
  );
    
  logic [WIDTH-1:0] mem [DEPTH-1:0];
    
  always_ff@(posedge clk, negedge rst_n) begin
  
    if (~rst_n) begin
    
      led_out <= '0;  
    
    end else begin
    
      if (rd_en_in) begin

        led_out <= mem[addr_in];

      end  
       
    end
  
  end

endmodule
