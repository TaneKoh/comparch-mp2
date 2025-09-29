filename = top
pcf_file = constraints/iceBlinkPico.pcf
SRC_DIR = src
SIM_DIR = sim

# Simulation targets
sim: $(SIM_DIR)/testbench.sv $(SRC_DIR)/$(filename).sv
	iverilog -g2012 -I $(SRC_DIR) -o $(filename)_sim $(SIM_DIR)/testbench.sv
	vvp $(filename)_sim
	gtkwave top.vcd

# Synthesis targets
build: $(SRC_DIR)/$(filename).sv
	yosys -p "synth_ice40 -top $(filename) -json $(filename).json" $(SRC_DIR)/$(filename).sv
	nextpnr-ice40 --up5k --package sg48 --json $(filename).json --pcf $(pcf_file) --asc $(filename).asc
	icepack $(filename).asc $(filename).bin

prog:
	dfu-util --device 1d50:6146 --alt 0 -D $(filename).bin -R

clean:
	rm -rf $(filename).json $(filename).asc $(filename).bin $(filename)_sim top.vcd

.PHONY: sim build prog clean