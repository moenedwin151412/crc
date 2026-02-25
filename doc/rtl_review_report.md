# RTL Design Review Report

**Date:** 2026-02-25  
**Project:** CRC IP Design  
**Review Type:** Design Spec vs RTL Comparison

---

## Summary

This report documents discrepancies found between the design specification (`crc_design_spec.md`) and the RTL implementation.

---

## Critical Issues (Functional)

### 1. ~~Missing: CRC_DATA_LEN Write Resets Data Counter~~ ✅ FIXED

**Location:** `crc_regfile.v`, `crc_engine.v`  
**Spec Reference:** Section 4.1 (CRC_DATA_LEN register description)

**Status:** Fixed in commit aa4a7d4

**Fix Description:**
Added `data_len_wr` output from `crc_regfile` that pulses when `CRC_DATA_LEN` is written. This signal is connected to `crc_engine` which resets `data_cnt_reg` on the pulse.

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

### 3. ~~AHB Slave Timing Issues~~ ✅ FIXED

**Location:** `crc_ahb_slave.v`  
**Spec Reference:** Section 6.3

**Status:** Fixed in commit 7b1693b

**Original Issues:**
1. `raw_data_wr` was pulsing multiple times per AHB transfer, causing data counter to increment by 2 per byte
2. `hready_reg` was set to 0 then immediately 1 in same cycle

**Fix Description:**
Rewrote AHB slave with proper 2-cycle transfer handling:
- Cycle 1: Latch address and control signals
- Cycle 2: Generate single-cycle pulse for data phase
- This ensures each AHB transfer generates exactly one `raw_data_wr` pulse

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

### ~~Data Counter Incrementing by 2~~ ✅ FIXED
**Status:** Fixed in commit 7b1693b

During simulation testing, the `data_cnt_reg` was observed to increment by 2 for single byte writes instead of by 1.

**Root Cause:** The AHB slave's `raw_data_wr` signal was pulsing multiple times per AHB transfer due to improper transfer detection logic.

**Fix:** Rewrote AHB slave with proper 2-cycle transfer handling to ensure single-cycle pulses.

---

## Recommendations

### ✅ Completed
1. ~~Implement data counter reset on CRC_DATA_LEN write~~
2. ~~Fix AHB slave timing issues~~
3. ~~Fix crc_start self-clearing race condition~~

### Priority 1 (Must Fix)
1. Implement sticky interrupt logic - interrupt should stay high until software clears

### Priority 2 (Should Fix)
2. Add burst type validation with error response
3. Implement raw data read functionality

### Priority 3 (Nice to Have)
4. Fix address width consistency in localparams

---

## Conclusion

The RTL has been updated to fix the critical issues:
- ✅ Data counter reset on CRC_DATA_LEN write
- ✅ AHB slave timing fixed (single-cycle pulses)
- ✅ CRC_START race condition fixed

Remaining issues to address:
- Sticky interrupt logic (currently level-sensitive)
- Burst type validation
- Raw data read functionality

The design is now ready for further verification testing.

---
*End of Report*
