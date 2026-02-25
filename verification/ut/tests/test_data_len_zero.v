//
// test_data_len_zero.v
//

`include "verification/ut/tb/ahb_master_bfm.v"

module test_data_len_zero;

    ahb_master_bfm bfm (
        .hsel(hsel), .haddr(haddr), .htrans(htrans), .hwrite(hwrite), .hsize(hsize),
        .hburst(hburst), .hwdata(hwdata), .hready(hready), .hrdata(hrdata),
        .hreadyout(hreadyout), .hresp(hresp)
    );

    reg irq_fired = 0;
    reg [31:0] data_count;
    reg [31:0] result;

    always @(posedge crc_irq) begin
        irq_fired = 1;
    end

    initial begin
        $display("Starting test_data_len_zero...");

        // Configure for CRC-32
        bfm.ahb_write(32'h00, 32'h2, 3'b010);
        bfm.ahb_write(32'h00, 32'h2 | (4<<4), 3'b010);

        // Set data length to 0 to disable auto-completion
        bfm.ahb_write(32'h40, 0, 3'b010);

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

        // Wait a few cycles to ensure all data is processed
        #50;

        bfm.ahb_read(32'h44, data_count, 3'b010);
        if (data_count !== 9) begin
            $display("TEST FAILED: Data count is %d, expected 9.", data_count);
        end

        // Manually read result
        bfm.ahb_read(32'h2C, result, 3'b010);

        if (irq_fired) begin
            $display("TEST FAILED: Interrupt fired when CRC_DATA_LEN was zero.");
        end else if (result === 32'hCBF43926) begin
            $display("TEST PASSED: CRC result is correct and interrupt did not fire.");
        end else begin
            $display("TEST FAILED: CRC result %h does not match expected %h", result, 32'hCBF43926);
        end

        $finish;
    end

endmodule
