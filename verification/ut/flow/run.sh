#!/bin/bash
set -e

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

# Prepare testbench from template
cp verification/ut/tb/tb_crc_top.v.template verification/ut/tb/tb_crc_top.v

# Use printf to avoid backtick interpretation issues
INCLUDE_LINE=$(printf '`include "verification/ut/tests/%s.v"' "$TESTCASE")
sed -i "s|// %%TESTCASE_INCLUDE%%|$INCLUDE_LINE|" verification/ut/tb/tb_crc_top.v

# Replace test module name (testcase files are named test_<name>.v with module test_<name>)
sed -i "s|// %%TESTCASE_MODULE%%|$TESTCASE|" verification/ut/tb/tb_crc_top.v

# Compile sources
iverilog -o crc_sim.vvp -c design/ips/crc/crc.f verification/ut/tb/tb_crc_top.v -s tb_crc_top

# Run simulation
vvp crc_sim.vvp
