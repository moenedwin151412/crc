//
// test_crc_simple.v
//

`include "verification/ut/tb/ahb_master_bfm.v"

module test_crc_simple;

    // Instantiate BFM
    ahb_master_bfm bfm (
        .hsel(hsel),
        .haddr(haddr),
        .htrans(htrans),
        .hwrite(hwrite),
        .hsize(hsize),
        .hburst(hburst),
        .hwdata(hwdata),
        .hready(hready),
        .hrdata(hrdata),
        .hreadyout(hreadyout),
        .hresp(hresp)
    );

    initial begin
        $display("Starting test_crc_simple...");

        // Configure for CRC-32
        bfm.ahb_write(32'h00, 32'h2, 3'b010); // CRC_CTRL: width=CRC32
        bfm.ahb_write(32'h00, 32'h4 | (4<<4), 3'b010); // CRC_CTRL: fixed poly CRC-32

        // Set data length
        bfm.ahb_write(32'h40, 9, 3'b010); // CRC_DATA_LEN = 9

        // Write data "123456789"
        bfm.ahb_write(32'h48, 8'h31, 3'b000); // '1'
        bfm.ahb_write(32'h49, 8'h32, 3'b000); // '2'
        bfm.ahb_write(32'h4A, 8'h33, 3'b000); // '3'
        bfm.ahb_write(32'h4B, 8'h34, 3'b000); // '4'
        bfm.ahb_write(32'h4C, 8'h35, 3'b000); // '5'
        bfm.ahb_write(32'h4D, 8'h36, 3'b000); // '6'
        bfm.ahb_write(32'h4E, 8'h37, 3'b000); // '7'
        bfm.ahb_write(32'h4F, 8'h38, 3'b000); // '8'
        bfm.ahb_write(32'h50, 8'h39, 3'b000); // '9'

        // Wait for interrupt
        wait (crc_irq);
        $display("CRC DONE interrupt received.");

        // Read result
        reg [31:0] result;
        bfm.ahb_read(32'h2C, result, 3'b010); // CRC_RESULT_L

        // Check result
        if (result === 32'hCBF43926) begin
            $display("TEST PASSED: CRC result matches expected value.");
        end else begin
            $display("TEST FAILED: CRC result %h does not match expected %h", result, 32'hCBF43926);
        end

        // Clear interrupt
        bfm.ahb_write(32'h3C, 1, 3'b010); // CRC_INT_CLR

        $finish;
    end

endmodule
