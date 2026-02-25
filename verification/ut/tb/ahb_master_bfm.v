//
// ahb_master_bfm.v - AHB Master Bus Functional Model
//

module ahb_master_bfm (
    hclk,
    hsel,
    haddr,
    htrans,
    hwrite,
    hsize,
    hburst,
    hwdata,
    hready,
    hrdata,
    hreadyout,
    hresp
);
    // Clock input
    input hclk;
    
    // Outputs
    output hsel;
    output [31:0] haddr;
    output [1:0] htrans;
    output hwrite;
    output [2:0] hsize;
    output [2:0] hburst;
    output [31:0] hwdata;
    output hready;
    
    // Inputs
    input [31:0] hrdata;
    input hreadyout;
    input [1:0] hresp;

    // Reg declarations
    reg hsel;
    reg [31:0] haddr;
    reg [1:0] htrans;
    reg hwrite;
    reg [2:0] hsize;
    reg [2:0] hburst;
    reg [31:0] hwdata;
    reg hready;

    // Write task
    task ahb_write;
        input [31:0] addr;
        input [31:0] data;
        input [2:0] size;
        begin
            // Setup address phase signals - use blocking assignments
            // to ensure they take effect immediately
            @(negedge hclk);
            #1;  // Small delay to ensure ordering
            haddr = addr;
            hwrite = 1'b1;
            htrans = 2'b10;
            hsize = size;
            hburst = 3'b000;
            hsel = 1'b1;
            hready = 1'b1;
            
            // Wait for clock edge
            @(posedge hclk);
            
            // Setup data
            @(negedge hclk);
            #1;
            hwdata = data;
            
            // Wait for slave ready
            while (!hreadyout) begin
                @(posedge hclk);
            end
            
            // End transfer
            @(negedge hclk);
            #1;
            hsel = 1'b0;
            hready = 1'b0;
            htrans = 2'b00;
        end
    endtask

    // Read task
    task ahb_read;
        input [31:0] addr;
        output [31:0] data;
        input [2:0] size;
        begin
            // Setup address phase
            @(negedge hclk);
            #1;
            haddr = addr;
            hwrite = 1'b0;
            htrans = 2'b10;
            hsize = size;
            hburst = 3'b000;
            hsel = 1'b1;
            hready = 1'b1;
            
            // Wait for clock edge
            @(posedge hclk);
            
            // Wait for slave ready
            while (!hreadyout) begin
                @(posedge hclk);
            end
            
            // Capture read data
            @(negedge hclk);
            #1;
            data = hrdata;
            
            // End transfer
            hsel = 1'b0;
            hready = 1'b0;
            htrans = 2'b00;
        end
    endtask

    // Initial block
    initial begin
        hsel = 1'b0;
        haddr = 32'b0;
        htrans = 2'b0;
        hwrite = 1'b0;
        hsize = 3'b0;
        hburst = 3'b0;
        hwdata = 32'b0;
        hready = 1'b0;
    end

endmodule
