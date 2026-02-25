//
// tb_crc_top.v
//

`timescale 1ns / 1ps

module tb_crc_top;

    // Clock and Reset
    reg hclk = 0;
    reg hreset_n;

    // AHB-Lite Interface
    wire        hsel;
    wire [31:0] haddr;
    wire [1:0]  htrans;
    wire        hwrite;
    wire [2:0]  hsize;
    wire [2:0]  hburst;
    wire [31:0] hwdata;
    wire        hready;
    wire [31:0] hrdata;
    wire        hreadyout;
    wire [1:0]  hresp;

    // Interrupt
    wire        crc_irq;

    // Instantiate DUT
    crc_top u_crc_top (
        .hclk(hclk),
        .hreset_n(hreset_n),
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
        .hresp(hresp),
        .crc_irq(crc_irq)
    );
    
    // AHB Master BFM (will be driven by test case)
    // Signals are connected by name in the test case include file
    
    // Clock generator
    always #5 hclk = ~hclk;

    // Reset generator
    initial begin
        hreset_n = 1'b0;
        #20;
        hreset_n = 1'b1;
    end

    // Simulation control
    initial begin
        // Dump waves
        $dumpfile("tb_crc_top.vcd");
        $dumpvars(0, tb_crc_top);

        // Run test case
        `ifdef TESTCASE
            `include `TESTCASE
        `else
            // Default test case
            `include "verification/ut/tests/test_crc_simple.v"
        `endif
    end

endmodule
