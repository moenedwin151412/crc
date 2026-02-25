//
// test_crc16_ccitt.v
//

`include "verification/ut/tb/ahb_master_bfm.v"

module test_crc16_ccitt;

    ahb_master_bfm bfm (
        .hsel(hsel), .haddr(haddr), .htrans(htrans), .hwrite(hwrite), .hsize(hsize),
        .hburst(hburst), .hwdata(hwdata), .hready(hready), .hrdata(hrdata),
        .hreadyout(hreadyout), .hresp(hresp)
    );

    initial begin
        $display("Starting test_crc16_ccitt...");

        // Configure for CRC-16-CCITT
        bfm.ahb_write(32'h00, 32'h1, 3'b010);      // CRC_CTRL: width=CRC16
        bfm.ahb_write(32'h00, 32'h1 | (3<<4), 3'b010); // CRC_CTRL: fixed poly CRC-16-CCITT

        // Set data length
        bfm.ahb_write(32'h40, 9, 3'b010);          // CRC_DATA_LEN = 9

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

        wait (crc_irq);
        $display("CRC DONE interrupt received.");

        reg [31:0] result;
        bfm.ahb_read(32'h2C, result, 3'b010); // Read CRC_RESULT_L

        if (result[15:0] === 16'h29B1) begin
            $display("TEST PASSED: CRC-16 result matches expected value.");
        end else begin
            $display("TEST FAILED: CRC-16 result %h does not match expected %h", result[15:0], 16'h29B1);
        end

        bfm.ahb_write(32'h3C, 1, 3'b010); // Clear interrupt
        $finish;
    end

endmodule
