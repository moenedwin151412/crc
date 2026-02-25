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

    // Write task - AHB-Lite single transfer
    task ahb_write;
        input [31:0] addr;
        input [31:0] data;
        input [2:0] size;
        begin
            // Address phase: Setup at negedge, sampled at posedge
            @(negedge hclk);
            haddr = addr;
            hwrite = 1'b1;
            htrans = 2'b10;  // NONSEQ
            hsize = size;
            hburst = 3'b000; // SINGLE
            hsel = 1'b1;
            hready = 1'b1;
            
            // Wait for posedge (address phase sampled)
            @(posedge hclk);
            
            // Data phase: Setup write data
            @(negedge hclk);
            hwdata = data;
            
            // Wait for slave ready (data phase complete)
            // Use @(posedge hclk) and check hreadyout
            while (!hreadyout) begin
                @(posedge hclk);
            end
            
            // Transfer complete - immediately end at negedge
            // This ensures transfer_active is only high for one cycle
            @(negedge hclk);
            hsel = 1'b0;
            hready = 1'b0;
            htrans = 2'b00;  // IDLE
            hwrite = 1'b0;
        end
    endtask

    // Read task - AHB-Lite single transfer
    task ahb_read;
        input [31:0] addr;
        output [31:0] data;
        input [2:0] size;
        begin
            // Address phase
            @(negedge hclk);
            haddr = addr;
            hwrite = 1'b0;
            htrans = 2'b10;  // NONSEQ
            hsize = size;
            hburst = 3'b000; // SINGLE
            hsel = 1'b1;
            hready = 1'b1;
            
            // Wait for posedge (address sampled)
            @(posedge hclk);
            
            // Wait for data phase complete
            while (!hreadyout) begin
                @(posedge hclk);
            end
            
            // Capture data at negedge (after hreadyout is stable)
            @(negedge hclk);
            data = hrdata;
            
            // End transfer
            hsel = 1'b0;
            hready = 1'b0;
            htrans = 2'b00;  // IDLE
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
