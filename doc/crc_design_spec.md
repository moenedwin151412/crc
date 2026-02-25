# CRC Design Specification

## Document Information

| Item | Description |
|------|-------------|
| Module Name | CRC (Cyclic Redundancy Check) |
| Version | 1.0 |
| Date | 2026-02-25 |

---

## 1. Overview

This document specifies the design of the CRC (Cyclic Redundancy Check) IP module. The CRC module provides hardware-accelerated CRC calculation with configurable polynomials, initial values, and XOR operations. It interfaces via AHB-Lite slave for register access and data transfer.

### 1.1 Key Features

- Supports CRC8, CRC16, CRC32, and CRC64 calculation
- Configurable polynomial (up to 64 bits)
- Configurable preset/initial value
- Configurable initial XOR and output XOR
- Fixed polynomial support for common standards
- 32 KiB raw data region for DMA-friendly operation
- AHB-Lite slave interface with byte/halfword/word access
- Burst support (INCR4/INCR8/INCR16) for raw data region
- Interrupt support for calculation complete

---

## 2. Architecture

### 2.1 Block Diagram

```
                    +------------------+
    AHB-Lite    --> |                  |
    Interface       |   Register File  | <-- Preset, XOR, Poly config
                    |                  |
                    +--------+---------+
                             |
                    +--------v---------+
    Raw Data        |                  |
    (32 KiB)    --> |   CRC Engine     | --> CRC Result
                    |                  |
                    +------------------+
                             |
                    +--------v---------+
                    |   Interrupt      | --> IRQ
                    |   Controller     |
                    +------------------+
```

### 2.2 Module Hierarchy

```
crc_top
├── crc_ahb_slave      # AHB-Lite interface, register decoding
├── crc_regfile        # Configuration registers
├── crc_engine         # CRC calculation core
│   ├── crc_datapath   # Polynomial division logic
│   └── crc_ctrl       # Engine control FSM
└── crc_int_ctrl       # Interrupt control
```

---

## 3. Interface Description

### 3.1 AHB-Lite Slave Interface

| Signal | Direction | Width | Description |
|--------|-----------|-------|-------------|
| hclk | input | 1 | System clock |
| hreset_n | input | 1 | Active-low synchronous reset |
| hsel | input | 1 | Slave select |
| haddr | input | [31:0] | Address bus |
| htrans | input | [1:0] | Transfer type |
| hwrite | input | 1 | Write enable (1=write, 0=read) |
| hsize | input | [2:0] | Transfer size (0=byte, 1=halfword, 2=word) |
| hburst | input | [2:0] | Burst type |
| hwdata | input | [31:0] | Write data |
| hready | input | 1 | Transfer ready from master |
| hrdata | output | [31:0] | Read data |
| hreadyout | output | 1 | Transfer ready from slave |
| hresp | output | [1:0] | Transfer response (OKAY=0, ERROR=1) |

### 3.2 Interrupt Interface

| Signal | Direction | Width | Description |
|--------|-----------|-------|-------------|
| crc_irq | output | 1 | CRC calculation complete interrupt |

---

## 4. Register Map

Base Address: Configurable (example: 0x4000_0000)

| Address Offset | Register Name | Access | Description |
|----------------|---------------|--------|-------------|
| 0x00 | CRC_CTRL | R/W | Control Register |
| 0x04 | CRC_STATUS | R/W | Status Register |
| 0x08 | CRC_POLY_CFG | R/W | Polynomial Configuration |
| 0x0C | CRC_POLY_VAL_L | R/W | Polynomial Value Low [31:0] |
| 0x10 | CRC_POLY_VAL_H | R/W | Polynomial Value High [63:32] |
| 0x14 | CRC_PRESET_L | R/W | Preset Value Low [31:0] |
| 0x18 | CRC_PRESET_H | R/W | Preset Value High [63:32] |
| 0x1C | CRC_INIT_XOR_L | R/W | Initial XOR Low [31:0] |
| 0x20 | CRC_INIT_XOR_H | R/W | Initial XOR High [63:32] |
| 0x24 | CRC_OUT_XOR_L | R/W | Output XOR Low [31:0] |
| 0x28 | CRC_OUT_XOR_H | R/W | Output XOR High [63:32] |
| 0x2C | CRC_RESULT_L | RO | CRC Result Low [31:0] |
| 0x30 | CRC_RESULT_H | RO | CRC Result High [63:32] |
| 0x34 | CRC_INT_EN | R/W | Interrupt Enable |
| 0x38 | CRC_INT_STATUS | R/W1C | Interrupt Status |
| 0x3C | CRC_INT_CLR | WO | Interrupt Clear |
| 0x40 - 0x7FFC | CRC_RAW_DATA | R/W | Raw Data Region (32 KiB) |

### 4.1 Register Detail

#### CRC_CTRL (0x00)

| Bit | Field | Access | Reset | Description |
|-----|-------|--------|-------|-------------|
| [1:0] | CRC_WIDTH | R/W | 2'b10 | CRC width: 00=CRC8, 01=CRC16, 10=CRC32, 11=CRC64 |
| [2] | CRC_START | R/SC | 1'b0 | Start calculation (self-clearing) |
| [3] | CRC_RST | R/SC | 1'b0 | Reset CRC engine (self-clearing) |
| [7:4] | FIXED_POLY_SEL | R/W | 4'b0000 | Fixed polynomial select (0=use configurable) |
| [31:8] | Reserved | R | 32'h0 | Reserved |

**Fixed Polynomial Select Encoding:**
| Value | Polynomial | Description |
|-------|------------|-------------|
| 0x0 | Configurable | Use CRC_POLY_VAL_* registers |
| 0x1 | 0x1D | CRC-8-SAE |
| 0x2 | 0x2F | CRC-8-Autosar |
| 0x3 | 0x1021 | CRC-16-CCITT |
| 0x4 | 0x04C11DB7 | CRC-32 |
| 0x5 | 0xD419CC15 | CRC-32C93 |

#### CRC_STATUS (0x04)

| Bit | Field | Access | Reset | Description |
|-----|-------|--------|-------|-------------|
| [0] | BUSY | R | 1'b0 | CRC engine busy |
| [1] | DONE | R | 1'b0 | CRC calculation done |
| [31:2] | Reserved | R | 30'b0 | Reserved |

#### CRC_POLY_CFG (0x08)

| Bit | Field | Access | Reset | Description |
|-----|-------|--------|-------|-------------|
| [0] | POLY_REV_IN | R/W | 1'b0 | 1=Reverse input data bits |
| [1] | POLY_REV_OUT | R/W | 1'b0 | 1=Reverse output CRC bits |
| [31:2] | Reserved | R | 30'b0 | Reserved |

#### CRC_POLY_VAL_L (0x0C)

Polynomial value [31:0] for configurable mode.

#### CRC_POLY_VAL_H (0x10)

Polynomial value [63:32] for configurable mode. Only used when CRC_WIDTH = 2'b11 (CRC64).

#### CRC_PRESET_L (0x14)

Preset/initial value [31:0]. Loaded into CRC at start of calculation.

#### CRC_PRESET_H (0x18)

Preset/initial value [63:32]. Only used when CRC_WIDTH = 2'b11 (CRC64).

#### CRC_INIT_XOR_L (0x1C)

Initial XOR value [31:0]. Applied to first data byte(s).

#### CRC_INIT_XOR_H (0x20)

Initial XOR value [63:32]. Only used when CRC_WIDTH = 2'b11 (CRC64).

#### CRC_OUT_XOR_L (0x24)

Output XOR value [31:0]. Applied to final CRC result.

#### CRC_OUT_XOR_H (0x28)

Output XOR value [63:32]. Only used when CRC_WIDTH = 2'b11 (CRC64).

#### CRC_RESULT_L (0x2C)

CRC result [31:0]. Valid when DONE=1.

#### CRC_RESULT_H (0x30)

CRC result [63:32]. Only valid when CRC_WIDTH = 2'b11 (CRC64) and DONE=1.

#### CRC_INT_EN (0x34)

| Bit | Field | Access | Reset | Description |
|-----|-------|--------|-------|-------------|
| [0] | DONE_IE | R/W | 1'b0 | Enable DONE interrupt |
| [31:1] | Reserved | R | 31'b0 | Reserved |

#### CRC_INT_STATUS (0x38)

| Bit | Field | Access | Reset | Description |
|-----|-------|--------|-------|-------------|
| [0] | DONE_IF | R/W1C | 1'b0 | DONE interrupt flag |
| [31:1] | Reserved | R | 31'b0 | Reserved |

#### CRC_INT_CLR (0x3C)

| Bit | Field | Access | Reset | Description |
|-----|-------|--------|-------|-------------|
| [0] | DONE_IC | WO | 1'b0 | Write 1 to clear DONE interrupt |
| [31:1] | Reserved | R | 31'b0 | Reserved |

#### CRC_RAW_DATA (0x40 - 0x7FFC)

32 KiB raw data region for DMA transfer. Writing to this region automatically triggers CRC calculation with the written data.

- Address range: 0x40 to 0x7FFC
- Access: Byte, Halfword, Word
- Burst: INCR4, INCR8, INCR16 supported
- Read: Returns latest written value

---

## 5. Functional Description

### 5.1 CRC Calculation Flow

```
1. Configure CRC parameters
   - Select CRC width (CRC_CTRL.CRC_WIDTH)
   - Select polynomial (fixed or configurable)
   - Set preset value (CRC_PRESET_*)
   - Set initial XOR (CRC_INIT_XOR_*)
   - Set output XOR (CRC_OUT_XOR_*)

2. Write data to CRC_RAW_DATA region
   - Each write triggers automatic CRC calculation
   - Data is processed in the order written

3. Poll for completion or wait for interrupt
   - Check CRC_STATUS.DONE or wait for crc_irq
   - Read result from CRC_RESULT_*
```

### 5.2 Data Processing

The CRC engine processes data in little-endian byte order. For multi-byte writes:

- **Byte write (HSIZE=0)**: Process 1 byte
- **Halfword write (HSIZE=1)**: Process 2 bytes, LSB first
- **Word write (HSIZE=2)**: Process 4 bytes, byte0 → byte1 → byte2 → byte3

### 5.3 CRC Algorithm

The CRC calculation follows the standard polynomial division:

```
For each data byte:
    crc = crc ^ (data_byte << (CRC_WIDTH - 8))
    for bit = 0 to 7:
        if crc[MSB] == 1:
            crc = (crc << 1) ^ polynomial
        else:
            crc = crc << 1
```

**Initial Value Handling:**
1. Load CRC with preset value
2. XOR first data byte(s) with initial XOR value (if configured)

**Output Value Handling:**
1. After all data processed, XOR result with output XOR value (if configured)

### 5.4 Fixed Polynomials

When using fixed polynomial mode, the following polynomials are supported:

| Name | Width | Polynomial | Value |
|------|-------|------------|-------|
| CRC-8-SAE | 8 | x^8 + x^4 + x^3 + x^2 + 1 | 0x1D |
| CRC-8-Autosar | 8 | x^8 + x^5 + x^3 + x^2 + x + 1 | 0x2F |
| CRC-16-CCITT | 16 | x^16 + x^12 + x^5 + 1 | 0x1021 |
| CRC-32 | 32 | x^32 + x^26 + x^23 + ... + x^2 + x + 1 | 0x04C11DB7 |
| CRC-32C93 | 32 | Custom | 0xD419CC15 |

---

## 6. AHB-Lite Protocol

### 6.1 Supported Transfers

| HSIZE | Description |
|-------|-------------|
| 3'b000 | Byte (8-bit) |
| 3'b001 | Halfword (16-bit) |
| 3'b010 | Word (32-bit) |

### 6.2 Burst Support (Raw Data Region Only)

| HBURST | Description |
|--------|-------------|
| 3'b000 | Single |
| 3'b001 | INCR (undefined length) |
| 3'b011 | INCR4 (4-beat incrementing) |
| 3'b101 | INCR8 (8-beat incrementing) |
| 3'b111 | INCR16 (16-beat incrementing) |

Note: WRAP bursts and fixed-length non-incrementing bursts are not supported for the raw data region.

### 6.3 Wait States

The module may insert wait states (HREADYOUT=0) under the following conditions:
- CRC engine busy processing previous data
- Register access collision

### 6.4 Error Response

HRESP=ERROR (2'b01) is returned for:
- Access to reserved/undefined addresses
- Unsupported burst types

---

## 7. Reset Behavior

Upon assertion of HRESET_N (active-low, synchronous):

1. All configuration registers reset to default values
2. CRC engine is reset to idle state
3. CRC result registers cleared to 0
4. Interrupt status cleared

**Default Reset Values:**

| Register | Reset Value |
|----------|-------------|
| CRC_CTRL | 32'h0000_0002 (CRC32 width) |
| CRC_STATUS | 32'h0000_0000 |
| CRC_POLY_VAL_L | 32'h04C11DB7 (CRC-32 poly) |
| CRC_POLY_VAL_H | 32'h0000_0000 |
| CRC_PRESET_L | 32'hFFFFFFFF |
| CRC_PRESET_H | 32'hFFFFFFFF |
| CRC_INIT_XOR_L | 32'h0000_0000 |
| CRC_INIT_XOR_H | 32'h0000_0000 |
| CRC_OUT_XOR_L | 32'hFFFFFFFF |
| CRC_OUT_XOR_H | 32'hFFFFFFFF |
| CRC_RESULT_L | 32'h0000_0000 |
| CRC_RESULT_H | 32'h0000_0000 |
| CRC_INT_EN | 32'h0000_0000 |
| CRC_INT_STATUS | 32'h0000_0000 |

---

## 8. Interrupt Handling

### 8.1 Interrupt Sources

| Source | Condition |
|--------|-----------|
| DONE | CRC calculation completed |

### 8.2 Interrupt Handling Procedure

1. Enable interrupt: Write 1 to CRC_INT_EN.DONE_IE
2. Wait for crc_irq assertion
3. Read CRC_RESULT_* to get final CRC value
4. Clear interrupt: Write 1 to CRC_INT_CLR.DONE_IC (or write 1 to CRC_INT_STATUS.DONE_IF)

---

## 9. Programming Guide

### 9.1 Basic CRC Calculation Example

```c
// Configure for CRC-32
CRC_CTRL = 0x2;                    // Select CRC32 width
CRC_CTRL |= (0x4 << 4);            // Select fixed CRC-32 polynomial

// Configure parameters (using defaults)
// CRC_PRESET_L = 0xFFFFFFFF;      // Preset value (default)
// CRC_OUT_XOR_L = 0xFFFFFFFF;     // Output XOR (default)

// Enable interrupt
CRC_INT_EN = 0x1;

// Write data to raw data region
CRC_RAW_DATA[0] = 0x31;            // '1'
CRC_RAW_DATA[1] = 0x32;            // '2'
CRC_RAW_DATA[2] = 0x33;            // '3'
CRC_RAW_DATA[3] = 0x34;            // '4'
CRC_RAW_DATA[4] = 0x35;            // '5'
CRC_RAW_DATA[5] = 0x36;            // '6'
CRC_RAW_DATA[6] = 0x37;            // '7'
CRC_RAW_DATA[7] = 0x38;            // '8'
CRC_RAW_DATA[8] = 0x39;            // '9'

// Wait for completion
while (!(CRC_INT_STATUS & 0x1));

// Read result
uint32_t crc_result = CRC_RESULT_L;

// Clear interrupt
CRC_INT_CLR = 0x1;
```

### 9.2 DMA Transfer Example

```c
// Configure CRC
CRC_CTRL = 0x2;                    // Select CRC32

// Configure DMA to transfer data to CRC_RAW_DATA base address
// DMA supports burst transfers (INCR4/8/16)
DMA_CONFIG.src = data_buffer;
DMA_CONFIG.dst = CRC_RAW_DATA_BASE;
DMA_CONFIG.burst = INCR16;

// Start DMA
dma_start();

// Wait for CRC interrupt
wait_for_crc_irq();

// Read result
uint32_t crc_result = CRC_RESULT_L;
```

### 9.3 Configurable Polynomial Example

```c
// Configure for CRC-8 with custom polynomial
CRC_CTRL = 0x0;                    // Select CRC8 width
CRC_CTRL |= (0x0 << 4);            // Use configurable polynomial

// Set custom polynomial: x^8 + x^2 + x + 1 = 0x07
CRC_POLY_VAL_L = 0x07;

// Set preset value
CRC_PRESET_L = 0x00;

// Set output XOR
CRC_OUT_XOR_L = 0x00;

// Write data and read result as in basic example
```

---

## 10. Timing and Performance

### 10.1 Throughput

| Data Width | Cycles per Byte | Throughput @100MHz |
|------------|-----------------|-------------------|
| 8-bit | 1 | 100 MB/s |
| 16-bit | 0.5 | 200 MB/s |
| 32-bit | 0.25 | 400 MB/s |

### 10.2 Latency

| Operation | Latency (cycles) |
|-----------|------------------|
| Register read | 1 |
| Register write | 1 |
| Raw data write to CRC update | 1 |
| Final result available | 1 after last data |
| Interrupt generation | 1 after DONE |

---

## 11. Verification Considerations

### 11.1 Test Coverage

- All CRC widths (8/16/32/64)
- All fixed polynomials
- Configurable polynomial functionality
- Initial XOR and output XOR operations
- Preset value functionality
- Byte/halfword/word accesses
- Burst transfers (INCR4/8/16)
- Interrupt handling
- Reset behavior
- Error response for invalid addresses

### 11.2 Reference Model

A software reference model (e.g., Python or C) should be used to verify CRC calculation results.

---

## Appendix A: Revision History

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| 1.0 | 2026-02-25 | - | Initial release |
