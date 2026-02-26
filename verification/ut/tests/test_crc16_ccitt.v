//
// test_crc16_ccitt.v - Test CRC-16 CCITT ( polynomial 0x1021 )
//

`include "verification/ut/tb/ahb_master_bfm.v"

module test_crc16_ccitt;

    ahb_master_bfm bfm (
        .hclk(tb_crc_top.hclk),
        .hsel(tb_crc_top.hsel),
        .haddr(tb_crc_top.haddr),
        .htrans(tb_crc_top.htrans),
        .hwrite(tb_crc_top.hwrite),
        .hsize(tb_crc_top.hsize),
        .hburst(tb_crc_top.hburst),
        .hwdata(tb_crc_top.hwdata),
        .hready(tb_crc_top.hready),
        .hrdata(tb_crc_top.hrdata),
        .hreadyout(tb_crc_top.hreadyout),
        .hresp(tb_crc_top.hresp)
    );

    reg [31:0] result;
    reg [31:0] result_h;

    initial begin
        $display("Starting test_crc16_ccitt...");

        @(posedge tb_crc_top.hreset_n);
        @(posedge tb_crc_top.hclk);

        // Enable interrupt
        bfm.ahb_write(32'h34, 1, 3'b010);

        // Test: CRC-16 CCITT with word writes
        $display("Test: CRC-16 CCITT with word (32-bit) data");
        
        // CRC_CTRL: width=CRC16(01), fixed_poly_sel=3(CCITT)
        bfm.ahb_write(32'h00, 32'h31, 3'b010);
        
        // Set data length = 8 bytes
        bfm.ahb_write(32'h40, 8, 3'b010);
        
        // Start CRC
        bfm.ahb_write(32'h00, 32'h35, 3'b010);
        
        // Write data as words (processed immediately)
        bfm.ahb_write(32'h48, 32'h01020304, 3'b010); // 4 bytes
        bfm.ahb_write(32'h4C, 32'h05060708, 3'b010); // 4 bytes
        
        // Wait for interrupt
        wait (tb_crc_top.crc_irq);
        
        // Read result (should be in low 16 bits)
        bfm.ahb_read(32'h2C, result, 3'b010);
        $display("CRC-16 CCITT result: %h", result[15:0]);
        
        // Clear interrupt
        bfm.ahb_write(32'h3C, 1, 3'b010);

        // Test 2: CRC-16 with custom init XOR
        $display("Test 2: CRC-16 CCITT with custom init XOR");
        
        // Set init XOR value
        bfm.ahb_write(32'h1C, 32'h0000FFFF, 3'b010);
        
        // Set length and start
        bfm.ahb_write(32'h40, 4, 3'b010);
        bfm.ahb_write(32'h00, 32'h35, 3'b010);
        
        // Write data
        bfm.ahb_write(32'h48, 32'h12345678, 3'b010);
        
        wait (tb_crc_top.crc_irq);
        
        bfm.ahb_read(32'h2C, result, 3'b010);
        $display("CRC-16 CCITT with init XOR result: %h", result[15:0]);
        
        bfm.ahb_write(32'h3C, 1, 3'b010);
        
        // Restore default
        bfm.ahb_write(32'h1C, 32'h0, 3'b010);

        $display("TEST PASSED: test_crc16_ccitt completed");
        $finish;
    end

endmodule
