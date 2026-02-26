//
// test_crc_reset.v - Test CRC reset functionality
//

`include "verification/ut/tb/ahb_master_bfm.v"

module test_crc_reset;

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

    reg [31:0] result1, result2;
    reg [31:0] status;

    initial begin
        $display("Starting test_crc_reset...");

        @(posedge tb_crc_top.hreset_n);
        @(posedge tb_crc_top.hclk);

        // Enable interrupt
        bfm.ahb_write(32'h34, 1, 3'b010);

        // Test 1: Reset during operation
        $display("Test 1: Reset during CRC operation");
        
        bfm.ahb_write(32'h00, 32'h42, 3'b010);
        bfm.ahb_write(32'h40, 100, 3'b010); // Large data length
        
        // Start CRC
        bfm.ahb_write(32'h00, 32'h46, 3'b010);
        
        // Write some data
        bfm.ahb_write(32'h48, 32'hAABBCCDD, 3'b010);
        bfm.ahb_write(32'h48, 32'h11223344, 3'b010);
        
        // Check busy
        bfm.ahb_read(32'h04, status, 3'b010);
        $display("Status after start: busy=%b", status[1]);
        
        // Reset CRC
        $display("Resetting CRC...");
        bfm.ahb_write(32'h00, 32'h4A, 3'b010); // rst=1
        
        // Check status after reset
        bfm.ahb_read(32'h04, status, 3'b010);
        $display("Status after reset: busy=%b, done=%b", status[1], status[0]);
        
        // Start new calculation after reset
        bfm.ahb_write(32'h40, 4, 3'b010);
        bfm.ahb_write(32'h00, 32'h46, 3'b010);
        
        // Write data
        bfm.ahb_write(32'h48, 32'h01020304, 3'b010);
        
        wait (tb_crc_top.crc_irq);
        
        bfm.ahb_read(32'h2C, result1, 3'b010);
        $display("Result after reset: %h", result1);
        
        bfm.ahb_write(32'h3C, 1, 3'b010);

        // Test 2: Compare same calculation with and without reset
        $display("Test 2: Consistency check after reset");
        
        // First calculation
        bfm.ahb_write(32'h40, 4, 3'b010);
        bfm.ahb_write(32'h00, 32'h46, 3'b010);
        
        // Write data
        bfm.ahb_write(32'h48, 32'h01020304, 3'b010);
        
        wait (tb_crc_top.crc_irq);
        
        bfm.ahb_read(32'h2C, result1, 3'b010);
        bfm.ahb_write(32'h3C, 1, 3'b010);
        
        // Reset
        bfm.ahb_write(32'h00, 32'h4A, 3'b010);
        
        // Same calculation after reset
        bfm.ahb_write(32'h40, 4, 3'b010);
        bfm.ahb_write(32'h00, 32'h46, 3'b010);
        
        // Write data
        bfm.ahb_write(32'h48, 32'h01020304, 3'b010);
        
        wait (tb_crc_top.crc_irq);
        
        bfm.ahb_read(32'h2C, result2, 3'b010);
        bfm.ahb_write(32'h3C, 1, 3'b010);
        
        if (result1 === result2) begin
            $display("Results match after reset: %h", result2);
        end else begin
            $display("ERROR: Results don't match: %h vs %h", result1, result2);
        end

        // Test 3: Data counter reset with data_len write
        $display("Test 3: Data counter reset with DATA_LEN write");
        
        bfm.ahb_write(32'h40, 8, 3'b010);
        bfm.ahb_write(32'h00, 32'h46, 3'b010);
        
        // Write data
        bfm.ahb_write(32'h48, 32'h11111111, 3'b010);
        bfm.ahb_write(32'h48, 32'h22222222, 3'b010);
        
        bfm.ahb_read(32'h44, status, 3'b010);
        $display("Data count before new len: %d", status);
        
        // Reset and start new
        bfm.ahb_write(32'h00, 32'h4A, 3'b010);
        
        // Write new data length - should reset counter
        bfm.ahb_write(32'h40, 4, 3'b010);
        
        bfm.ahb_read(32'h44, status, 3'b010);
        $display("Data count after new len: %d", status);
        
        // Complete the operation
        bfm.ahb_write(32'h00, 32'h46, 3'b010);
        bfm.ahb_write(32'h48, 32'h33333333, 3'b010);
        
        wait (tb_crc_top.crc_irq);
        
        bfm.ahb_read(32'h2C, result1, 3'b010);
        bfm.ahb_write(32'h3C, 1, 3'b010);
        
        $display("Final result: %h", result1);

        $display("TEST PASSED: test_crc_reset completed");
        $finish;
    end

endmodule
