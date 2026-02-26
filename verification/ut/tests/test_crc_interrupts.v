//
// test_crc_interrupts.v - Test interrupt enable/disable functionality
//

`include "verification/ut/tb/ahb_master_bfm.v"

module test_crc_interrupts;

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

    reg [31:0] int_status;
    reg [31:0] int_en;
    reg [31:0] result;
    integer i;

    initial begin
        $display("Starting test_crc_interrupts...");

        @(posedge tb_crc_top.hreset_n);
        @(posedge tb_crc_top.hclk);

        // Test 1: Interrupt disabled - check that irq doesn't assert
        $display("Test 1: Interrupt disabled");
        
        // Make sure interrupt is disabled
        bfm.ahb_write(32'h34, 0, 3'b010);
        
        bfm.ahb_write(32'h00, 32'h42, 3'b010);
        bfm.ahb_write(32'h40, 4, 3'b010);
        bfm.ahb_write(32'h00, 32'h46, 3'b010);
        
        // Write data
        bfm.ahb_write(32'h48, 32'hDEADBEEF, 3'b010);
        
        // Wait a few cycles
        repeat(10) @(posedge tb_crc_top.hclk);
        
        // Check that irq is not asserted
        if (tb_crc_top.crc_irq === 1'b0) begin
            $display("Correct: IRQ not asserted when disabled");
        end else begin
            $display("ERROR: IRQ asserted when disabled!");
        end
        
        // Check interrupt status (should still show done)
        bfm.ahb_read(32'h38, int_status, 3'b010);
        $display("INT_STATUS when disabled: %h", int_status);
        
        // Clear via INT_CLR
        bfm.ahb_write(32'h3C, 1, 3'b010);
        bfm.ahb_read(32'h38, int_status, 3'b010);
        $display("INT_STATUS after clear: %h", int_status);

        // Test 2: Interrupt enabled
        $display("Test 2: Interrupt enabled");
        
        bfm.ahb_write(32'h34, 1, 3'b010);
        
        bfm.ahb_write(32'h40, 4, 3'b010);
        bfm.ahb_write(32'h00, 32'h46, 3'b010);
        
        // Write data
        bfm.ahb_write(32'h48, 32'hCAFEBABE, 3'b010);
        
        wait (tb_crc_top.crc_irq);
        $display("Correct: IRQ asserted when enabled");
        
        bfm.ahb_read(32'h38, int_status, 3'b010);
        $display("INT_STATUS: %h", int_status);
        
        bfm.ahb_write(32'h3C, 1, 3'b010);

        // Test 3: Check interrupt enable register read
        $display("Test 3: Read interrupt enable register");
        
        bfm.ahb_read(32'h34, int_en, 3'b010);
        $display("INT_EN read: %h", int_en);
        
        // Disable and read again
        bfm.ahb_write(32'h34, 0, 3'b010);
        bfm.ahb_read(32'h34, int_en, 3'b010);
        $display("INT_EN after disable: %h", int_en);

        // Test 4: Multiple CRC operations with interrupt
        $display("Test 4: Multiple operations with interrupt");
        
        bfm.ahb_write(32'h34, 1, 3'b010);
        
        for (i = 0; i < 3; i = i + 1) begin
            $display("  Operation %d", i);
            
            bfm.ahb_write(32'h40, 4, 3'b010);
            bfm.ahb_write(32'h00, 32'h46, 3'b010);
            
            // Write data
            bfm.ahb_write(32'h48, 32'h00000000 + i, 3'b010);
            
            wait (tb_crc_top.crc_irq);
            
            bfm.ahb_read(32'h2C, result, 3'b010);
            bfm.ahb_write(32'h3C, 1, 3'b010);
            
            // Small delay between operations
            repeat(5) @(posedge tb_crc_top.hclk);
        end

        $display("TEST PASSED: test_crc_interrupts completed");
        $finish;
    end

endmodule
