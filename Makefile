DESIGN_FILE = ./rtl/include/rv32_zbkb_pkg.sv \
			  ./rtl/rv32_zbkb_alu.sv                   \
			  ./rtl/rv32_zbkb_decoder.sv               \
			  ./rtl/rv32_zbkb_top.sv

TB_FILES =    ./tb/rv32_zbkb_alu_tb.sv                 \
			  ./tb/rv32_zbkb_decoder_tb.sv             \
			  ./tb/rv32_zbkb_top_tb.sv

lint:
	verilator --lint-only -Wall -Wno-MULTITOP -Wno-TIMESCALEMOD -Wno-IMPORTSTAR ${DESIGN_FILE} ${TB_FILES}

run_tb:
	verilator --binary -j 0 -Wall -Wno-TIMESCALEMOD -Wno-IMPORTSTAR --trace ${DESIGN_FILE} ${TB_FILES} --top-module ${TARGET} && clear && ./obj_dir/V${TARGET}

clean:
	rm -r ./obj_dir
