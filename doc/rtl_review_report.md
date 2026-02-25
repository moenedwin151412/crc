# RTL Design Review Report

**Date:** 2026-02-25  
**Project:** CRC IP Design  
**Review Type:** Design Spec vs RTL Comparison

---

## Summary

This report documents discrepancies found between the design specification (`crc_design_spec.md`) and the RTL implementation.

---

## Critical Issues (Functional)

### 1. Missing: CRC_DATA_LEN Write Resets Data Counter

**Location:** `crc_regfile.v`, `crc_engine.v`  
**Spec Reference:** Section 4.1 (CRC_DATA_LEN register description)

**Description:**
The specification states that "Writing to this register also resets the internal data counter to 0". This feature is required for proper DMA operation where a new transfer length is programmed.

**Current Implementation:**
- `data_cnt_reg` in `crc_engine.v` only resets on `crc_start` or `crc_rst`
- No connection between `data_len_reg` write and `data_cnt_reg` reset

**Required Fix:**
Add logic to reset `data_cnt_reg` when `CRC_DATA_LEN` register is written.

---

### 2. Interrupt Logic May Miss Pulses

**Location:** `crc_int_ctrl.v`  
**Spec Reference:** Section 8.1

**Description:**
The current interrupt logic is purely combinatorial/level-sensitive:
```verilog
assign crc_irq = done_if && done_ie;
```
Or the registered version that clears immediately when `done_if` clears.

If `done_if` is a pulse that gets cleared by a register read or other event, the interrupt output may not be captured properly by the system.

**Recommended Fix:**
Make the interrupt sticky - once triggered, it stays active until explicitly cleared by software (via `CRC_INT_CLR`).

---

### 3. AHB Slave Never Inserts Wait States

**Location:** `crc_ahb_slave.v` lines 69-86  
**Spec Reference:** Section 6.3

**Description:**
The wait state logic has a bug where `hready_reg` is set to 0 and then immediately to 1 in the same clock cycle:

```verilog
if (transfer_active) begin
    hready_reg <= 1'b0;  // Try to insert wait
    ... // processing
    hready_reg <= 1'b1;  // Immediately remove wait
end
```

This means the slave never actually inserts wait states, which could cause issues if the master expects proper protocol adherence.

**Recommended Fix:**
Implement proper state machine for wait state insertion.

---

## Medium Issues (Features Not Implemented)

### 4. Raw Data Read Returns Zero

**Location:** `crc_ahb_slave.v` lines 77-80  
**Spec Reference:** Section 5.2

**Description:**
Reading from the `CRC_RAW_DATA` region returns hardcoded `32'h0`. The spec mentions reads should return the "latest written value".

**Note:** This may be acceptable if the raw data region is write-only, but the spec describes it as R/W.

---

### 5. No Burst Type Validation

**Location:** `crc_ahb_slave.v`  
**Spec Reference:** Section 6.2, 6.4

**Description:**
The `hburst` input is not used. The spec requires:
- Support for INCR4/8/16
- Error response for WRAP and fixed-length bursts

Currently, all burst types are accepted without validation.

---

## Minor Issues

### 6. Address Width Mismatch in Localparams

**Location:** `crc_regfile.v` lines 39-56  
**Description:**
Local parameters use 12-bit width but the address input is 15-bit. This is functionally correct but inconsistent.

---

## Simulation Observations

### Data Counter Incrementing by 2
During simulation testing, the `data_cnt_reg` was observed to increment by 2 for single byte writes instead of by 1. This suggests:
- `raw_data_wr` may be sampled twice per transaction
- Or the AHB slave timing creates a longer pulse than expected

**Investigation needed:** Review the timing relationship between `transfer_active` and the clock edge where `data_cnt_reg` is updated.

---

## Recommendations

### Priority 1 (Must Fix)
1. Implement data counter reset on CRC_DATA_LEN write
2. Fix AHB slave wait state logic

### Priority 2 (Should Fix)
3. Implement sticky interrupt logic
4. Add burst type validation with error response

### Priority 3 (Nice to Have)
5. Implement raw data read functionality
6. Fix address width consistency in localparams

---

## Conclusion

The RTL implements the core CRC functionality but has several gaps compared to the specification:
- Missing register side-effect (data counter reset)
- AHB protocol implementation issues
- Incomplete feature implementation (burst validation, raw data read)

The design should be updated to address Priority 1 issues before verification proceeds further.

---
*End of Report*
