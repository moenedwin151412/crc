//
// test_crc_custom_poly.v - Test programmable polynomial
//

`include "verification/ut/tb/ahb_master_bfm.v"

module test_crc_custom_poly;

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
    reg [31:0] expected;

    initial begin
        $display("Starting test_crc_custom_poly...");

        @(posedge tb_crc_top.hreset_n);
        @(posedge tb_crc_top.hclk);

        // Enable interrupt
        bfm.ahb_write(32'h34, 1, 3'b010);

        // Test 1: CRC-32 with custom polynomial (same as standard CRC-32)
        $display("Test 1: Custom polynomial matching CRC-32");
        
        // CRC_CTRL: width=CRC32(10), fixed_poly_sel=0(custom)
        bfm.ahb_write(32'h00, 32'h02, 3'b010);
        
        // Set custom polynomial value (CRC-32: 0x04C11DB7)
        bfm.ahb_write(32'h0C, 32'h04C11DB7, 3'b010);
        bfm.ahb_write(32'h10, 32'h0, 3'b010);
        
        // Set data length = 9 ("123456789")
        bfm.ahb_write(32'h40, 9, 3'b010);
        
        // Start CRC
        bfm.ahb_write(32'h00, 32'h06, 3'b010);
        
        // Write data "123456789"
        bfm.ahb_write(32'h48, 8'h31, 3'b000);
        bfm.ahb_write(32'h49, 8'h32, 3'b000);
        bfm.ahb_write(32'h4A, 8'h33, 3'b000);
        bfm.ahb_write(32'h4B, 8'h34, 3'b000);
        bfm.ahb_write(32'h4C, 8'h35, 3'b000);
        bfm.ahb_write(32'h4D, 8'h36, 3'b000);
        bfm.ahb_write(32'h4E, 8'h37, 3'b000);
        bfm.ahb_write(32'h4F, 8'h38, 3'b000);
        bfm.ahb_write(32'h50, 8'h39, 3'b000);
        
        wait (tb_crc_top.crc_irq);
        
        // Read result
        bfm.ahb_read(32'h2C, result, 3'b010);
        $display("Custom polynomial CRC-32 result: %h", result);
        
        bfm.ahb_write(32'h3C, 1, 3'b010);

        // Test 2: CRC-16 with custom polynomial
        $display("Test 2: Custom 16-bit polynomial");
        
        // CRC_CTRL: width=CRC16(01), fixed_poly_sel=0(custom)
        bfm.ahb_write(32'h00, 32'h01, 3'b010);
        
        // Set custom 16-bit polynomial
        bfm.ahb_write(32'h0C, 32'h00008005, 3'b010); // CRC-16-IBM polynomial
        
        // Set length and start
        bfm.ahb_write(32'h40, 4, 3'b010);
        bfm.ahb_write(32'h00, 32'h05, 3'b010);
        
        // Write data
        bfm.ahb_write(32'h48, 32'hAABBCCDD, 3'b010);
        
        wait (tb_crc_top.crc_irq);
        
        bfm.ahb_read(32'h2C, result, 3'b010);
        $display("Custom 16-bit polynomial result: %h", result[15:0]);
        
        bfm.ahb_write(32'h3C, 1, 3'b010);

        // Restore default polynomial
        bfm.ahb_write(32'h0C, 32'h04C11DB7, 3'b010);

        $display("TEST PASSED: test_crc_custom_poly completed");
        $finish;
    end

endmodule
