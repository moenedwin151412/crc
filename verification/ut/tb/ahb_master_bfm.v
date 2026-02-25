//
// ahb_master_bfm.v
//

module ahb_master_bfm (
    // AHB-Lite Interface
    output reg          hsel,
    output reg [31:0]   haddr,
    output reg [1:0]    htrans,
    output reg          hwrite,
    output reg [2:0]    hsize,
    output reg [2:0]    hburst,
    output reg [31:0]   hwdata,
    output reg          hready,
    input  [31:0]   hrdata,
    input           hreadyout,
    input  [1:0]    hresp
);

    // BFM Tasks
    task ahb_write;
        input [31:0] addr;
        input [31:0] data;
        input [2:0] size;
        begin
            @(posedge hclk);
            haddr <= addr;
            hwdata <= data;
            hwrite <= 1'b1;
            htrans <= 2'b10; // NONSEQ
            hsize <= size;
            hburst <= 3'b000; // SINGLE
            hsel <= 1'b1;
            hready <= 1'b1;
            @(posedge hclk);
            while (!hreadyout) begin
                @(posedge hclk);
            end
            hsel <= 1'b0;
            hready <= 1'b0;
        end
    endtask

    task ahb_read;
        input [31:0] addr;
        output [31:0] data;
        input [2:0] size;
        begin
            @(posedge hclk);
            haddr <= addr;
            hwrite <= 1'b0;
            htrans <= 2'b10; // NONSEQ
            hsize <= size;
            hburst <= 3'b000; // SINGLE
            hsel <= 1'b1;
            hready <= 1'b1;
            @(posedge hclk);
            while (!hreadyout) begin
                @(posedge hclk);
            end
            data = hrdata;
            hsel <= 1'b0;
            hready <= 1'b0;
        end
    endtask

    initial begin
        hsel <= 1'b0;
        haddr <= 32'b0;
        htrans <= 2'b0;
        hwrite <= 1'b0;
        hsize <= 3'b0;
        hburst <= 3'b0;
        hwdata <= 32'b0;
        hready <= 1'b0;
    end

endmodule
