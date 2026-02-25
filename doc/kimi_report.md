# Kimi Design Session Report

**Project**: CRC (Cyclic Redundancy Check) IP Design  
**Session Date**: 2026-02-25  
**Workspace**: `/home/CALTERAH/yshen/sandbox/crc`

---

## 1. Workspace Setup

### 1.1 Initial Directory Structure

User requested the following workspace structure:

```
|--doc
|--design
|  |--ips
|     |--xxx
|--verification
|  |--ut
|     |--flow
|     |--tb
|     |--tests
```

Created all directories using:
```bash
mkdir -p doc design/ips/xxx verification/ut/flow verification/ut/tb verification/ut/tests
```

### 1.2 Folder Renaming

User requested renaming `design/ips/xxx` to `design/ips/crc`:
```bash
mv design/ips/xxx design/ips/crc
```

### 1.3 Git Repository Initialization

Initialized git repository with:
- `.gitignore` file for simulation artifacts (*.vcd, *.vvp, ModelSim, Vivado, etc.)
- `auto_commit.sh` helper script for automated commits
- Initial README files in each directory

**Commits:**
1. `c93719f` - Initial commit: Add workspace structure and .gitignore
2. `726a1c0` - Add workspace directory structure with README files
3. `61eb69a` - Add auto-commit helper script

---

## 2. Feature Requirements Gathering

### 2.1 Source Feature Document

Read feature requirements from `/home/CALTERAH/yshen/sandbox/robot-x/crc_feature.md`:

```
CRC Preset
- The CRC shall support a configurable preset value.

CRC Initial XOR
- The CRC shall support configurable inital XOR for the first raw data.

CRC Output XOR
- The CRC shall support configurable output XOR for the last raw data.

CRC Raw data region 
- The raw data address map shall consist of 32 KiB continuous addresses to enhance DMA transfer performance.

CRC Polynomials
- The CRC shall support fixed polynomials: crc_8_sae(0x1d), crc_8_autosar(0x2f), crc_16_ccitt(0x1021), crc_32(0x04C11DB7), crc_32c93(0xD419CC15).
- Additionally, the CRC shall support configurable polynomials for CRC8, CRC16, CRC32, and CRC64.

CRC interface
- The CRC shall support AHB Lite slave interface for register configuration, data input, and data output.
- The AHB Lite slave shall support byte/halfword/word access, and support burst 4/8/16 for raw data region.
```

### 2.2 Design Clarification Q&A

**Q1: Data Width and Processing**
- Q: What is the data width for raw data input?
- A: 8/16/32, depends on AHB slave

**Q2: Control and Status**
- Q: Is there a start trigger mechanism? Is there a done status? Are interrupts supported? Is there a busy status?
- A: yes yes yes yes (all supported)

**Q3: Reset**
- Q: Reset signal configuration?
- A: active low, synchronous, clear to default value

**Q4: Byte Order**
- Q: Endianness?
- A: little (little-endian)

**Q5: Raw Data Region**
- Q: Access types? Auto-calculate? Back-pressure?
- A: write and read and read value is latest value, auto, back-press by AHB hready

**Q6: Polynomial Configuration**
- Q: Bit width for polynomials? Normal or reflected form?
- A: max 64 bits, normal

**Q7: Input/Output Data**
- Q: Input data format? Final result location?
- A: normal, register

**Q8: Additional Features**
- Q: Support for byte-wise CRC? Multiple contexts?
- A: yes no (byte-wise yes, multiple contexts no)

---

## 3. Design Specification Document

### 3.1 Document Created

File: `doc/crc_design_spec.md`

**Content Overview:**
- Section 1: Overview and key features
- Section 2: Architecture and block diagram
- Section 3: Interface description (AHB-Lite, Interrupt)
- Section 4: Register map with 15+ control/status registers
- Section 5: Functional description and CRC calculation flow
- Section 6: AHB-Lite protocol details
- Section 7: Reset behavior
- Section 8: Interrupt handling
- Section 9: Programming guide with examples
- Section 10: Timing and performance
- Section 11: Verification considerations

### 3.2 Key Design Decisions

| Feature | Decision |
|---------|----------|
| CRC Width | 8/16/32/64-bit configurable via CRC_WIDTH field |
| Fixed Polynomials | 6 supported: CRC-8-SAE, CRC-8-Autosar, CRC-16-CCITT, CRC-32, CRC-32C93 |
| Configurable Poly | Up to 64 bits via CRC_POLY_VAL_H/L registers |
| XOR Operations | Separate initial XOR (CRC_INIT_XOR_*) and output XOR (CRC_OUT_XOR_*) |
| Data Region | 32 KiB at offset 0x40-0x7FFC |
| Access Types | Byte, Halfword, Word with burst support (INCR4/8/16) |
| Interrupt | DONE interrupt when calculation complete |
| Reset | Active-low synchronous, resets to CRC-32 default config |

**Commit:** `ed2b370` - Add CRC detailed design specification document

---

## 4. DONE Interrupt Generation Discussion

### 4.1 Initial Question

User asked: "how to generate done interrupt?"

Kimi proposed options:
1. **Per-Write DONE**: After each AHB write
2. **Burst-Complete DONE**: After detecting end of burst
3. **Explicit Finalization**: Via CRC_FINAL register
4. **Timeout-Based DONE**: After N idle cycles

### 4.2 User's Solution

User proposed: **Adding a data length configuration - when data length matches, generate DONE interrupt.**

### 4.3 Specification Update

Added two new registers:

| Register | Address | Description |
|----------|---------|-------------|
| CRC_DATA_LEN | 0x40 | Expected data length in bytes (R/W). Writing resets internal counter to 0. |
| CRC_DATA_CNT | 0x44 | Number of bytes processed (RO). Auto-increments on each write. |

**DONE Interrupt Logic:**
```
DONE = (CRC_DATA_LEN > 0) && (CRC_DATA_CNT == CRC_DATA_LEN)
```

**Behavior:**
- When `CRC_DATA_LEN = 0`: Auto-completion disabled, no DONE interrupt
- When `CRC_DATA_CNT == CRC_DATA_LEN`: DONE=1, interrupt triggered

**Raw Data Region Update:**
- New base address: 0x48 (shifted to accommodate new registers)
- Size: 32 KiB - 8 bytes

### 4.4 Updated Programming Examples

Added examples for:
- Fixed length CRC calculation (single writes)
- DMA transfer (recommended approach)
- Multiple sequential CRC calculations

**Commit:** `aa46d90` - Update CRC spec: Add data length configuration for auto-completion interrupt

---

## 5. Git Repository Status

### 5.1 Final Commit History

```
aa46d90 Update CRC spec: Add data length configuration for auto-completion interrupt
ed2b370 Add CRC detailed design specification document
61eb69a Add auto-commit helper script
726a1c0 Add workspace directory structure with README files
c93719f Initial commit: Add workspace structure and .gitignore for simulation files
```

### 5.2 Current File Structure

```
.
├── .git/
├── .gitignore
├── auto_commit.sh
├── doc/
│   ├── README.md
│   └── crc_design_spec.md
├── design/
│   └── ips/
│       └── crc/
│           └── README.md
└── verification/
    └── ut/
        ├── flow/
        │   └── README.md
        ├── tb/
        │   └── README.md
        └── tests/
            └── README.md
```

---

## 6. Summary

### 6.1 Completed Tasks

✅ Workspace directory structure setup  
✅ Git repository initialization with .gitignore  
✅ Feature requirements analysis  
✅ Design clarification Q&A  
✅ Detailed design specification document  
✅ Data length configuration feature for DONE interrupt  

### 6.2 Next Steps (Pending)

The following tasks are ready to begin:

1. **RTL Implementation**
   - `design/ips/crc/crc_top.v` - Top-level module
   - `design/ips/crc/crc_ahb_slave.v` - AHB-Lite interface
   - `design/ips/crc/crc_regfile.v` - Register file
   - `design/ips/crc/crc_engine.v` - CRC calculation core
   - `design/ips/crc/crc_int_ctrl.v` - Interrupt controller

2. **Verification Environment**
   - Testbench components in `verification/ut/tb/`
   - Simulation scripts in `verification/ut/flow/`
   - Test cases in `verification/ut/tests/`

3. **Documentation Updates**
   - Update spec if design changes during implementation
   - Add verification plan document

---

## 7. Communication Log

| Time | Action | Details |
|------|--------|---------|
| Initial | Workspace setup | Created directory structure per user spec |
| Initial | Git init | Initialized repo with .gitignore and helper scripts |
| Initial | Read feature file | Read `/home/CALTERAH/yshen/sandbox/robot-x/crc_feature.md` |
| Initial | Q&A session | Clarified 8 design questions with user |
| Initial | Spec creation | Generated `doc/crc_design_spec.md` (500+ lines) |
| Later | DONE interrupt discussion | Proposed options, user selected data length config |
| Later | Spec update | Added CRC_DATA_LEN and CRC_DATA_CNT registers |
| Final | Report generation | Created this communication log |

---

*End of Report*
