//
// test_crc8_configurable.v
//

`include "verification/ut/tb/ahb_master_bfm.v"

module test_crc8_configurable;

    ahb_master_bfm bfm (
        .hsel(hsel), .haddr(haddr), .htrans(htrans), .hwrite(hwrite), .hsize(hsize),
        .hburst(hburst), .hwdata(hwdata), .hready(hready), .hrdata(hrdata),
        .hreadyout(hreadyout), .hresp(hresp)
    );

    reg [31:0] result;

    initial begin
        $display("Starting test_crc8_configurable...");

        // Configure for CRC-8 with custom polynomial 0x07
        bfm.ahb_write(32'h00, 32'h0, 3'b010);        // CRC_CTRL: width=CRC8, configurable poly
        bfm.ahb_write(32'h0C, 32'h07, 3'b010);       // CRC_POLY_VAL_L = 0x07
        bfm.ahb_write(32'h14, 32'h00, 3'b010);       // CRC_PRESET_L = 0x00
        bfm.ahb_write(32'h24, 32'h00, 3'b010);       // CRC_OUT_XOR_L = 0x00

        // Set data length
        bfm.ahb_write(32'h40, 4, 3'b010);            // CRC_DATA_LEN = 4

        // Write data
        bfm.ahb_write(32'h48, 8'h01, 3'b000);
        bfm.ahb_write(32'h49, 8'h02, 3'b000);
        bfm.ahb_write(32'h4A, 8'h03, 3'b000);
        bfm.ahb_write(32'h4B, 8'h04, 3'b000);

        wait (crc_irq);
        $display("CRC DONE interrupt received.");

        bfm.ahb_read(32'h2C, result, 3'b010); // Read CRC_RESULT_L

        if (result[7:0] === 8'hA1) begin
            $display("TEST PASSED: CRC-8 result matches expected value.");
        end else begin
            $display("TEST FAILED: CRC-8 result %h does not match expected %h", result[7:0], 8'hA1);
        end

        bfm.ahb_write(32'h3C, 1, 3'b010); // Clear interrupt
        $finish;
    end

endmodule
