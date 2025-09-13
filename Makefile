filename = top
pcf_file = constraints/iceBlinkPico.pcf
# calls the main file name top and means that it reads and creates top.asc, top.bin, top.json, etc.
# also makes sure that it can read the pcf file for pin constraints correctly (navigates to correct pins)

build:
	yosys -p "synth_ice40 -top $(filename) -json $(filename).json" src/$(filename).sv
# yosys synthesis
	nextpnr-ice40 --up5k --package sg48 --json $(filename).json --pcf $(pcf_file) --asc $(filename).asc
# navigates the board	
	icepack $(filename).asc $(filename).bin
# packs directions onto the FPGA

prog:
	dfu-util --device 1d50:6146 --alt 0 -D $(filename).bin -R
# runs the program

clean:
	rm -rf $(filename).json $(filename).asc $(filename).bin
# removing and cleaning files, run it by doing make clean