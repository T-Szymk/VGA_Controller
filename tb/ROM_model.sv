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
 2022-04-30  1.1      TZD     Made Read Enable Parameterised
------------------------------------------------------------------------------*/
`timescale 1ns / 1ps

module ROM_model #(
    WIDTH = 8, 
    DEPTH = 16, 
    READ_EN = 1 
  ) (
    input  logic clk,
    input  logic rst_n,
    input  logic [$clog2(DEPTH)-1:0] addr_in,
    input  logic rd_en_in,

    output logic [WIDTH-1:0] dat_out
  );
    
  logic [WIDTH-1:0] mem [DEPTH-1:0];
    
  always_ff@(posedge clk, negedge rst_n) begin
  
    if (~rst_n) begin
    
      dat_out <= '0;  
    
    end else begin
    
    generate // read_enable generation

      if (READ_EN == 1) begin 

        if (rd_en_in) begin
          dat_out <= mem[addr_in];
        end

      end else begin // treats read_en_in as if it is fixed at 1
      
        dat_out <= mem[addr_in];
  
      end

    endgenerate 
  end

endmodule
