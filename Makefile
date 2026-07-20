DESIGN_FILE = ./rtl/include/rv32_zbkb_pkg.sv \
			  ./rtl/alu.sv                   \
			  ./rtl/decoder.sv

TB_FILES =    ./tb/alu_tb.sv                 \
			  ./tb/decoder_tb.sv

lint:
	verilator --lint-only -Wall -Wno-TIMESCALEMOD -Wno-IMPORTSTAR ${DESIGN_FILE} ${TB_FILES}

run_tb:
	verilator --binary -j 0 -Wall -Wno-TIMESCALEMOD -Wno-IMPORTSTAR --trace ${DESIGN_FILE} ${TB_FILES} --top-module ${TARGET} && clear && ./obj_dir/V${TARGET}

clean:
	rm -r ./obj_dir
