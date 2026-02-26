//
// test_crc8_configurable.v - Test CRC-8 with custom polynomial
//

`include "verification/ut/tb/ahb_master_bfm.v"

module test_crc8_configurable;

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

    initial begin
        $display("Starting test_crc8_configurable...");

        @(posedge tb_crc_top.hreset_n);
        @(posedge tb_crc_top.hclk);

        // Enable interrupt
        bfm.ahb_write(32'h34, 1, 3'b010);

        // Configure for CRC-8 with custom polynomial 0x07
        bfm.ahb_write(32'h00, 32'h0, 3'b010);        // CRC_CTRL: width=CRC8, configurable poly
        bfm.ahb_write(32'h0C, 32'h07, 3'b010);       // CRC_POLY_VAL_L = 0x07
        bfm.ahb_write(32'h14, 32'h00, 3'b010);       // CRC_PRESET_L = 0x00
        bfm.ahb_write(32'h24, 32'h00, 3'b010);       // CRC_OUT_XOR_L = 0x00

        // Set data length
        bfm.ahb_write(32'h40, 4, 3'b010);            // CRC_DATA_LEN = 4

        // Start CRC
        bfm.ahb_write(32'h00, 32'h04, 3'b010);

        // Write data
        bfm.ahb_write(32'h48, 8'h01, 3'b000);
        bfm.ahb_write(32'h49, 8'h02, 3'b000);
        bfm.ahb_write(32'h4A, 8'h03, 3'b000);
        bfm.ahb_write(32'h4B, 8'h04, 3'b000);

        wait (tb_crc_top.crc_irq);
        $display("CRC DONE interrupt received.");

        bfm.ahb_read(32'h2C, result, 3'b010); // Read CRC_RESULT_L
        $display("CRC-8 result: %h", result[7:0]);

        bfm.ahb_write(32'h3C, 1, 3'b010); // Clear interrupt

        $display("TEST PASSED: test_crc8_configurable completed");
        $finish;
    end

endmodule
