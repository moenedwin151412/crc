#!/bin/bash
set -e

TESTCASE=$1

if [ -z "$TESTCASE" ]; then
    echo "Usage: $0 <testcase_name>"
    echo "Available testcases:"
    ls -1 verification/ut/tests/ | sed 's/\.v//'
    exit 1
fi

# Create tmp folder and test case specific folder
TMP_DIR="tmp/${TESTCASE}"
mkdir -p "${TMP_DIR}"

# Clean up previous run for this test case
rm -f "${TMP_DIR}/crc_sim.vvp"
rm -f "${TMP_DIR}/tb_crc_top.vcd"

# Prepare testbench from template
cp verification/ut/tb/tb_crc_top.v.template "${TMP_DIR}/tb_crc_top.v"

# Use printf to avoid backtick interpretation issues
INCLUDE_LINE=$(printf '`include "verification/ut/tests/%s.v"' "$TESTCASE")
sed -i "s|// %%TESTCASE_INCLUDE%%|$INCLUDE_LINE|" "${TMP_DIR}/tb_crc_top.v"

# Replace test module name (testcase files are named test_<name>.v with module test_<name>)
sed -i "s|// %%TESTCASE_MODULE%%|$TESTCASE|" "${TMP_DIR}/tb_crc_top.v"

# Compile sources (run from project root for file list paths)
iverilog -o "${TMP_DIR}/crc_sim.vvp" -c design/ips/crc/crc.f "${TMP_DIR}/tb_crc_top.v" -s tb_crc_top

# Run simulation in the test case folder
cd "${TMP_DIR}"
vvp crc_sim.vvp
cd - > /dev/null
