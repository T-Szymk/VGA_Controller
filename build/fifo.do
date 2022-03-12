add wave -position insertpoint  \
sim:/sync_fifo_tb/FIFO_WIDTH \
sim:/sync_fifo_tb/FIFO_DEPTH \
sim:/sync_fifo_tb/clk \
sim:/sync_fifo_tb/clr_n \
sim:/sync_fifo_tb/we \
sim:/sync_fifo_tb/rd \
sim:/sync_fifo_tb/empty \
sim:/sync_fifo_tb/full \
sim:/sync_fifo_tb/data_in \
sim:/sync_fifo_tb/data_out \
-divider "DUT"  \
sim:/sync_fifo_tb/i_sync_fifo/FIFO_WIDTH \
sim:/sync_fifo_tb/i_sync_fifo/FIFO_DEPTH \
sim:/sync_fifo_tb/i_sync_fifo/clk \
sim:/sync_fifo_tb/i_sync_fifo/clr_n_in \
sim:/sync_fifo_tb/i_sync_fifo/we_in \
sim:/sync_fifo_tb/i_sync_fifo/rd_in \
sim:/sync_fifo_tb/i_sync_fifo/data_in \
sim:/sync_fifo_tb/i_sync_fifo/empty_out \
sim:/sync_fifo_tb/i_sync_fifo/full_out \
sim:/sync_fifo_tb/i_sync_fifo/data_out \
sim:/sync_fifo_tb/i_sync_fifo/full_s \
sim:/sync_fifo_tb/i_sync_fifo/empty_s \
sim:/sync_fifo_tb/i_sync_fifo/data_out_r \
sim:/sync_fifo_tb/i_sync_fifo/wr_ptr_s \
sim:/sync_fifo_tb/i_sync_fifo/rd_ptr_s \
sim:/sync_fifo_tb/i_sync_fifo/data_cnt_r \
sim:/sync_fifo_tb/i_sync_fifo/fifo_block_r \
-divider "FIFO model" \
sim:/sync_fifo_tb/test_data_out \
sim:/sync_fifo_tb/fifo_model \
sim:/sync_fifo_tb/write_ptr \
sim:/sync_fifo_tb/read_ptr \
sim:/sync_fifo_tb/data_count

set StdArithNoWarnings 1 
run 0 ns 
set StdArithNoWarnings 0

run -all

wave zoom full
config wave -signalnamewidth 1