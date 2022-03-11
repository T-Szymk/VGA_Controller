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
sim:/sync_fifo_tb/i_sync_fifo/fifo_block_r

set StdArithNoWarnings 1 
run 0 ns 
set StdArithNoWarnings 0

run 200 ns
force -freeze sim:/sync_fifo_tb/clr_n 1'h1 0
run 200 ns
force -freeze sim:/sync_fifo_tb/we 1'h1 0
run 200 ns
force -freeze sim:/sync_fifo_tb/rd 1'h1 0
force -freeze sim:/sync_fifo_tb/data_in 36'hAAAAAAAAA 0
run 200 ns
force -freeze sim:/sync_fifo_tb/we 1'h0 0
run 200 ns

wave zoom full
config wave -signalnamewidth 1