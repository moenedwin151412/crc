#!/bin/bash

TESTCASE=$1

if [ -z "$TESTCASE" ]; then
    echo "Usage: $0 <testcase_name>"
    echo "Available testcases:"
    ls -1 verification/ut/tests/ | sed 's/\.v//'
    exit 1
fi

# Clean up previous run
rm -f crc_sim.vvp
rm -f tb_crc_top.vcd

# Compile sources
iverilog -o crc_sim.vvp -c design/ips/crc/crc.f verification/ut/tb/tb_crc_top.v -DTESTCASE=\\"$TESTCASE.v\\" -s tb_crc_top

# Run simulation
vvp crc_sim.vvp

# Optional: Open waveform
# gtkwave tb_crc_top.vcd
