//
// test_crc_bit_reversal.v - Test bit reversal (input and output)
//

`include "verification/ut/tb/ahb_master_bfm.v"

module test_crc_bit_reversal;

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
    reg [31:0] result_no_rev;

    initial begin
        $display("Starting test_crc_bit_reversal...");

        @(posedge tb_crc_top.hreset_n);
        @(posedge tb_crc_top.hclk);

        // Enable interrupt
        bfm.ahb_write(32'h34, 1, 3'b010);

        // Test 1: No reversal (baseline)
        $display("Test 1: No bit reversal (baseline)");
        
        bfm.ahb_write(32'h00, 32'h42, 3'b010); // CRC32, fixed poly
        
        // No bit reversal
        bfm.ahb_write(32'h08, 32'h0, 3'b010);
        
        bfm.ahb_write(32'h40, 4, 3'b010);
        bfm.ahb_write(32'h00, 32'h46, 3'b010);
        
        // Write data
        bfm.ahb_write(32'h48, 32'h01020304, 3'b010);
        
        wait (tb_crc_top.crc_irq);
        
        bfm.ahb_read(32'h2C, result_no_rev, 3'b010);
        $display("Result without reversal: %h", result_no_rev);
        
        bfm.ahb_write(32'h3C, 1, 3'b010);

        // Test 2: Input bit reversal only
        $display("Test 2: Input bit reversal only");
        
        bfm.ahb_write(32'h08, 32'h1, 3'b010); // poly_rev_in=1
        
        bfm.ahb_write(32'h40, 4, 3'b010);
        bfm.ahb_write(32'h00, 32'h46, 3'b010);
        
        // Write data
        bfm.ahb_write(32'h48, 32'h01020304, 3'b010);
        
        wait (tb_crc_top.crc_irq);
        
        bfm.ahb_read(32'h2C, result, 3'b010);
        $display("Result with input reversal: %h", result);
        
        bfm.ahb_write(32'h3C, 1, 3'b010);

        // Test 3: Output bit reversal only
        $display("Test 3: Output bit reversal only");
        
        bfm.ahb_write(32'h08, 32'h2, 3'b010); // poly_rev_out=1
        
        bfm.ahb_write(32'h40, 4, 3'b010);
        bfm.ahb_write(32'h00, 32'h46, 3'b010);
        
        // Write data
        bfm.ahb_write(32'h48, 32'h01020304, 3'b010);
        
        wait (tb_crc_top.crc_irq);
        
        bfm.ahb_read(32'h2C, result, 3'b010);
        $display("Result with output reversal: %h", result);
        
        bfm.ahb_write(32'h3C, 1, 3'b010);

        // Test 4: Both input and output reversal
        $display("Test 4: Both input and output reversal");
        
        bfm.ahb_write(32'h08, 32'h3, 3'b010); // both rev bits set
        
        bfm.ahb_write(32'h40, 4, 3'b010);
        bfm.ahb_write(32'h00, 32'h46, 3'b010);
        
        // Write data
        bfm.ahb_write(32'h48, 32'h01020304, 3'b010);
        
        wait (tb_crc_top.crc_irq);
        
        bfm.ahb_read(32'h2C, result, 3'b010);
        $display("Result with both reversals: %h", result);
        
        bfm.ahb_write(32'h3C, 1, 3'b010);

        // Reset to default
        bfm.ahb_write(32'h08, 32'h0, 3'b010);

        $display("TEST PASSED: test_crc_bit_reversal completed");
        $finish;
    end

endmodule
