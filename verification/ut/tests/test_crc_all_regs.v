//
// test_crc_all_regs.v - Test reading all registers
//

`include "verification/ut/tb/ahb_master_bfm.v"

module test_crc_all_regs;

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

    reg [31:0] rd_data;
    reg test_passed;

    task check_read;
        input [31:0] addr;
        input [31:0] expected_mask;
        input [31:0] expected_value;
        input [255:0] name; // String for register name
        begin
            bfm.ahb_read(addr, rd_data, 3'b010);
            if ((rd_data & expected_mask) === expected_value) begin
                $display("  %s: %h (PASS)", name, rd_data);
            end else begin
                $display("  %s: %h, expected %h (FAIL)", name, rd_data, expected_value);
                test_passed = 1'b0;
            end
        end
    endtask

    initial begin
        test_passed = 1'b1;
        $display("Starting test_crc_all_regs...");

        @(posedge tb_crc_top.hreset_n);
        @(posedge tb_crc_top.hclk);

        // Test 1: Read default values after reset
        $display("Test 1: Default register values after reset");
        
        check_read(32'h00, 32'h000000FF, 32'h00000002, "CRC_CTRL");     // width=10(CRC32), poly=0
        check_read(32'h04, 32'h00000003, 32'h00000000, "CRC_STATUS");    // not busy, not done
        check_read(32'h08, 32'h00000003, 32'h00000000, "CRC_POLY_CFG");  // no reversal
        check_read(32'h0C, 32'hFFFFFFFF, 32'h04C11DB7, "CRC_POLY_VAL_L");
        check_read(32'h10, 32'hFFFFFFFF, 32'h00000000, "CRC_POLY_VAL_H");
        check_read(32'h14, 32'hFFFFFFFF, 32'hFFFFFFFF, "CRC_PRESET_L");
        check_read(32'h18, 32'hFFFFFFFF, 32'hFFFFFFFF, "CRC_PRESET_H");
        check_read(32'h1C, 32'hFFFFFFFF, 32'h00000000, "CRC_INIT_XOR_L");
        check_read(32'h20, 32'hFFFFFFFF, 32'h00000000, "CRC_INIT_XOR_H");
        check_read(32'h24, 32'hFFFFFFFF, 32'hFFFFFFFF, "CRC_OUT_XOR_L");
        check_read(32'h28, 32'hFFFFFFFF, 32'hFFFFFFFF, "CRC_OUT_XOR_H");
        check_read(32'h34, 32'h00000001, 32'h00000000, "CRC_INT_EN");
        check_read(32'h38, 32'h00000001, 32'h00000000, "CRC_INT_STATUS");
        check_read(32'h40, 32'hFFFFFFFF, 32'h00000000, "CRC_DATA_LEN");
        check_read(32'h44, 32'hFFFFFFFF, 32'h00000000, "CRC_DATA_CNT");

        // Test 2: Write and read back all writable registers
        $display("Test 2: Write and read back registers");
        
        bfm.ahb_write(32'h00, 32'h00000053, 3'b010); // CRC_CTRL
        check_read(32'h00, 32'h000000FF, 32'h00000053, "CRC_CTRL after write");
        
        bfm.ahb_write(32'h08, 32'h00000003, 3'b010); // CRC_POLY_CFG
        check_read(32'h08, 32'h00000003, 32'h00000003, "CRC_POLY_CFG after write");
        
        bfm.ahb_write(32'h0C, 32'h12345678, 3'b010); // CRC_POLY_VAL_L
        check_read(32'h0C, 32'hFFFFFFFF, 32'h12345678, "CRC_POLY_VAL_L after write");
        
        bfm.ahb_write(32'h10, 32'h9ABCDEF0, 3'b010); // CRC_POLY_VAL_H
        check_read(32'h10, 32'hFFFFFFFF, 32'h9ABCDEF0, "CRC_POLY_VAL_H after write");
        
        bfm.ahb_write(32'h14, 32'h11111111, 3'b010); // CRC_PRESET_L
        check_read(32'h14, 32'hFFFFFFFF, 32'h11111111, "CRC_PRESET_L after write");
        
        bfm.ahb_write(32'h18, 32'h22222222, 3'b010); // CRC_PRESET_H
        check_read(32'h18, 32'hFFFFFFFF, 32'h22222222, "CRC_PRESET_H after write");
        
        bfm.ahb_write(32'h1C, 32'h33333333, 3'b010); // CRC_INIT_XOR_L
        check_read(32'h1C, 32'hFFFFFFFF, 32'h33333333, "CRC_INIT_XOR_L after write");
        
        bfm.ahb_write(32'h20, 32'h44444444, 3'b010); // CRC_INIT_XOR_H
        check_read(32'h20, 32'hFFFFFFFF, 32'h44444444, "CRC_INIT_XOR_H after write");
        
        bfm.ahb_write(32'h24, 32'h55555555, 3'b010); // CRC_OUT_XOR_L
        check_read(32'h24, 32'hFFFFFFFF, 32'h55555555, "CRC_OUT_XOR_L after write");
        
        bfm.ahb_write(32'h28, 32'h66666666, 3'b010); // CRC_OUT_XOR_H
        check_read(32'h28, 32'hFFFFFFFF, 32'h66666666, "CRC_OUT_XOR_H after write");
        
        bfm.ahb_write(32'h34, 32'h00000001, 3'b010); // CRC_INT_EN
        check_read(32'h34, 32'h00000001, 32'h00000001, "CRC_INT_EN after write");
        
        bfm.ahb_write(32'h40, 32'h00001000, 3'b010); // CRC_DATA_LEN
        check_read(32'h40, 32'hFFFFFFFF, 32'h00001000, "CRC_DATA_LEN after write");

        // Test 3: Read result registers after CRC operation
        $display("Test 3: Read result registers after operation");
        
        // Restore default polynomial for predictable results
        bfm.ahb_write(32'h0C, 32'h04C11DB7, 3'b010);
        bfm.ahb_write(32'h10, 32'h0, 3'b010);
        bfm.ahb_write(32'h14, 32'hFFFFFFFF, 3'b010);
        bfm.ahb_write(32'h18, 32'hFFFFFFFF, 3'b010);
        
        bfm.ahb_write(32'h00, 32'h42, 3'b010); // CRC32, poly=4
        bfm.ahb_write(32'h40, 4, 3'b010);
        bfm.ahb_write(32'h00, 32'h46, 3'b010);
        
        // Write data
        bfm.ahb_write(32'h48, 32'h01020304, 3'b010);
        
        wait (tb_crc_top.crc_irq);
        
        bfm.ahb_read(32'h2C, rd_data, 3'b010);
        $display("  CRC_RESULT_L: %h", rd_data);
        bfm.ahb_read(32'h30, rd_data, 3'b010);
        $display("  CRC_RESULT_H: %h", rd_data);
        bfm.ahb_read(32'h44, rd_data, 3'b010);
        $display("  CRC_DATA_CNT: %h (expected: 4)", rd_data);
        bfm.ahb_read(32'h38, rd_data, 3'b010);
        $display("  CRC_INT_STATUS: %h", rd_data);
        
        bfm.ahb_write(32'h3C, 1, 3'b010);

        if (test_passed) begin
            $display("TEST PASSED: test_crc_all_regs completed");
        end else begin
            $display("TEST FAILED: test_crc_all_regs");
        end
        
        $finish;
    end

endmodule
