LIB   = line_buff_model_lib
FILES = xilinx_sp_BRAM.sv \
        line_buffers.sv \
		line_buff_ctrl.sv \
		frame_buffer.sv \
		top.sv 
TOP   = top

clean:
	rm -rf $(LIB)
	rm -rf modelsim.ini

lib: clean
	vlib $(LIB)
	vmap work $(LIB)

compile: clean lib
	vlog -sv -pedanticerrors $(FILES)

sim: clean lib compile
	vsim -voptargs="+acc" -onfinish stop $(TOP) -do "line_buff.do"