//
// test_crc32c.v - Test CRC-32C (Castagnoli) ( polynomial 0x1EDC6F41 )
//

`include "verification/ut/tb/ahb_master_bfm.v"

module test_crc32c;

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

    initial begin
        $display("Starting test_crc32c...");

        @(posedge tb_crc_top.hreset_n);
        @(posedge tb_crc_top.hclk);

        // Enable interrupt
        bfm.ahb_write(32'h34, 1, 3'b010);

        // Test: CRC-32C with mixed data sizes
        $display("Test: CRC-32C with mixed data sizes");
        
        // CRC_CTRL: width=CRC32(10), fixed_poly_sel=5(CRC-32C)
        bfm.ahb_write(32'h00, 32'h52, 3'b010);
        
        // Set data length = 8 bytes
        bfm.ahb_write(32'h40, 8, 3'b010);
        
        // Start CRC
        bfm.ahb_write(32'h00, 32'h56, 3'b010);
        
        // Write mixed data sizes (processed immediately)
        bfm.ahb_write(32'h48, 8'hAA, 3'b000);        // byte
        bfm.ahb_write(32'h49, 16'hBBCC, 3'b001);     // half-word
        bfm.ahb_write(32'h4B, 8'hDD, 3'b000);        // byte
        bfm.ahb_write(32'h4C, 32'hEEFF0011, 3'b010); // word
        
        // Wait for interrupt
        wait (tb_crc_top.crc_irq);
        
        // Read result
        bfm.ahb_read(32'h2C, result, 3'b010);
        $display("CRC-32C result: %h", result);
        
        // Clear interrupt
        bfm.ahb_write(32'h3C, 1, 3'b010);

        // Test 2: Check busy status during operation
        $display("Test 2: Check busy status");
        
        // Check status before start
        bfm.ahb_read(32'h04, status, 3'b010);
        $display("Status before start: %h (busy=%b, done=%b)", status, status[1], status[0]);
        
        bfm.ahb_write(32'h40, 4, 3'b010);
        bfm.ahb_write(32'h00, 32'h56, 3'b010);
        
        // Check status after start
        bfm.ahb_read(32'h04, status, 3'b010);
        $display("Status after start: %h (busy=%b, done=%b)", status, status[1], status[0]);
        
        // Write data
        bfm.ahb_write(32'h48, 32'h12345678, 3'b010);
        
        wait (tb_crc_top.crc_irq);
        
        // Check status after done
        bfm.ahb_read(32'h04, status, 3'b010);
        $display("Status after done: %h (busy=%b, done=%b)", status, status[1], status[0]);
        
        bfm.ahb_write(32'h3C, 1, 3'b010);

        $display("TEST PASSED: test_crc32c completed");
        $finish;
    end

endmodule
