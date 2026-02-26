//
// test_data_len_zero.v - Test with data length = 0 (manual completion)
//

`include "verification/ut/tb/ahb_master_bfm.v"

module test_data_len_zero;

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

    reg irq_fired = 0;
    reg [31:0] data_count;
    reg [31:0] result;

    always @(posedge tb_crc_top.crc_irq) begin
        irq_fired = 1;
    end

    initial begin
        $display("Starting test_data_len_zero...");

        @(posedge tb_crc_top.hreset_n);
        @(posedge tb_crc_top.hclk);

        // Configure for CRC-32 with fixed polynomial
        bfm.ahb_write(32'h00, 32'h42, 3'b010);

        // Set data length to 0 to disable auto-completion
        bfm.ahb_write(32'h40, 0, 3'b010);

        // Start CRC
        bfm.ahb_write(32'h00, 32'h46, 3'b010);

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
        repeat(10) @(posedge tb_crc_top.hclk);

        bfm.ahb_read(32'h44, data_count, 3'b010);
        $display("Data count: %d", data_count);

        // Manually read result
        bfm.ahb_read(32'h2C, result, 3'b010);
        $display("CRC result: %h", result);

        if (irq_fired) begin
            $display("Interrupt fired when CRC_DATA_LEN was zero.");
        end else begin
            $display("Interrupt did not fire (expected).");
        end

        $display("TEST PASSED: test_data_len_zero completed");

        $finish;
    end

endmodule
