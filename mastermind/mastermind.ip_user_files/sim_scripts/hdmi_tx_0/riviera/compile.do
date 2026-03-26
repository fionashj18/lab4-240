transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

vlib work
vlib riviera/xpm
vlib riviera/xil_defaultlib

vmap xpm riviera/xpm
vmap xil_defaultlib riviera/xil_defaultlib

vlog -work xpm  -incr -l xpm -l xil_defaultlib \
"/afs/ece.cmu.edu/support/xilinx/xilinx.release/Vivado-2024.2/Vivado/2024.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \

vcom -work xpm -93  -incr \
"/afs/ece.cmu.edu/support/xilinx/xilinx.release/Vivado-2024.2/Vivado/2024.2/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work xil_defaultlib  -incr -v2k5 -l xpm -l xil_defaultlib \
"../../../../mastermind.gen/sources_1/ip/hdmi_tx_0/hdl/encode.v" \
"../../../../mastermind.gen/sources_1/ip/hdmi_tx_0/hdl/serdes_10_to_1.v" \
"../../../../mastermind.gen/sources_1/ip/hdmi_tx_0/hdl/srldelay.v" \
"../../../../mastermind.gen/sources_1/ip/hdmi_tx_0/hdl/hdmi_tx_v1_0.v" \
"../../../../mastermind.gen/sources_1/ip/hdmi_tx_0/sim/hdmi_tx_0.v" \

vlog -work xil_defaultlib \
"glbl.v"

