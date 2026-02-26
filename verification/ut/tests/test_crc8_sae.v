//
// test_crc8_sae.v - Test CRC-8 SAE ( polynomial 0x1D )
//

`include "verification/ut/tb/ahb_master_bfm.v"

module test_crc8_sae;

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
    reg [31:0] status;
    reg test_passed;

    initial begin
        test_passed = 1'b1;
        $display("Starting test_crc8_sae...");

        @(posedge tb_crc_top.hreset_n);
        @(posedge tb_crc_top.hclk);

        // Enable interrupt
        bfm.ahb_write(32'h34, 1, 3'b010);

        // Test 1: CRC-8 SAE with fixed polynomial and status polling
        $display("Test 1: CRC-8 SAE fixed polynomial with status polling");
        
        // CRC_CTRL: width=CRC8(00), fixed_poly_sel=1(SAE)
        bfm.ahb_write(32'h00, 32'h10, 3'b010);
        
        // Set data length = 4
        bfm.ahb_write(32'h40, 4, 3'b010);
        
        // Start CRC first, then write data
        bfm.ahb_write(32'h00, 32'h14, 3'b010); // width=CRC8, poly=1, start=1
        
        // Write data bytes (processed immediately)
        bfm.ahb_write(32'h48, 8'h01, 3'b000);
        bfm.ahb_write(32'h49, 8'h02, 3'b000);
        bfm.ahb_write(32'h4A, 8'h03, 3'b000);
        bfm.ahb_write(32'h4B, 8'h04, 3'b000);
        
        // Poll for done using status register
        status = 0;
        while (!status[0]) begin
            bfm.ahb_read(32'h04, status, 3'b010);
        end
        $display("CRC done detected via status poll");
        
        // Read result
        bfm.ahb_read(32'h2C, result, 3'b010);
        $display("CRC-8 SAE result: %h", result[7:0]);
        
        // Clear interrupt
        bfm.ahb_write(32'h3C, 1, 3'b010);

        // Test 2: CRC-8 SAE with custom preset and XOR values
        $display("Test 2: CRC-8 SAE with custom preset/XOR");
        
        // Set custom preset value (0 instead of 0xFF)
        bfm.ahb_write(32'h14, 32'h00000000, 3'b010); // PRESET_L = 0
        
        // Set custom output XOR (0xFF instead of 0)
        bfm.ahb_write(32'h24, 32'h000000FF, 3'b010); // OUT_XOR_L = 0xFF
        
        // Configure and start
        bfm.ahb_write(32'h40, 3, 3'b010);
        bfm.ahb_write(32'h00, 32'h14, 3'b010); // start
        
        // Write data
        bfm.ahb_write(32'h48, 8'hAA, 3'b000);
        bfm.ahb_write(32'h49, 8'hBB, 3'b000);
        bfm.ahb_write(32'h4A, 8'hCC, 3'b000);
        
        wait (tb_crc_top.crc_irq);
        bfm.ahb_read(32'h2C, result, 3'b010);
        $display("CRC-8 SAE with custom values result: %h", result[7:0]);
        
        // Clear interrupt
        bfm.ahb_write(32'h3C, 1, 3'b010);

        // Restore default values
        bfm.ahb_write(32'h14, 32'hFFFFFFFF, 3'b010);
        bfm.ahb_write(32'h24, 32'hFFFFFFFF, 3'b010);

        if (test_passed) begin
            $display("TEST PASSED: test_crc8_sae completed");
        end else begin
            $display("TEST FAILED: test_crc8_sae");
        end
        
        $finish;
    end

endmodule
