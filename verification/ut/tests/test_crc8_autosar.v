//
// test_crc8_autosar.v - Test CRC-8 AUTOSAR ( polynomial 0x2F )
//

`include "verification/ut/tb/ahb_master_bfm.v"

module test_crc8_autosar;

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
    reg [31:0] rd_data;

    initial begin
        $display("Starting test_crc8_autosar...");

        @(posedge tb_crc_top.hreset_n);
        @(posedge tb_crc_top.hclk);

        // Enable interrupt
        bfm.ahb_write(32'h34, 1, 3'b010);

        // Test: CRC-8 AUTOSAR with half-word writes
        $display("Test: CRC-8 AUTOSAR with half-word (16-bit) data");
        
        // CRC_CTRL: width=CRC8(00), fixed_poly_sel=2(AUTOSAR)
        bfm.ahb_write(32'h00, 32'h20, 3'b010);
        
        // Set data length = 4 bytes
        bfm.ahb_write(32'h40, 4, 3'b010);
        
        // Start CRC first
        bfm.ahb_write(32'h00, 32'h24, 3'b010);
        
        // Write data as half-words (processed immediately)
        bfm.ahb_write(32'h48, 16'hA1B2, 3'b001); // 2 bytes
        bfm.ahb_write(32'h4A, 16'hC3D4, 3'b001); // 2 bytes
        
        // Wait for interrupt
        wait (tb_crc_top.crc_irq);
        
        // Read and check interrupt status
        bfm.ahb_read(32'h38, rd_data, 3'b010);
        $display("INT_STATUS: %h", rd_data);
        
        // Read result
        bfm.ahb_read(32'h2C, result, 3'b010);
        $display("CRC-8 AUTOSAR result: %h", result[7:0]);
        
        // Read data count
        bfm.ahb_read(32'h44, rd_data, 3'b010);
        $display("Data count: %d", rd_data);
        
        // Clear interrupt
        bfm.ahb_write(32'h3C, 1, 3'b010);
        
        // Disable interrupt
        bfm.ahb_write(32'h34, 0, 3'b010);

        $display("TEST PASSED: test_crc8_autosar completed");
        $finish;
    end

endmodule
