//
// crc_ahb_slave.v
//

module crc_ahb_slave (
    // AHB-Lite Interface
    input           hclk,
    input           hreset_n,
    input           hsel,
    input   [31:0]  haddr,
    input   [1:0]   htrans,
    input           hwrite,
    input   [2:0]   hsize,
    input   [2:0]   hburst,
    input   [31:0]  hwdata,
    input           hready,
    input   [31:0]  reg_rd_data,
    output  [31:0]  hrdata,
    output          hreadyout,
    output  [1:0]   hresp,

    // Register File Interface
    output          reg_wr_en,
    output  [14:0]  reg_addr,
    output  [31:0]  reg_wr_data,

    // Raw Data Interface
    output          raw_data_wr,
    output  [31:0]  raw_data_wdata,
    output  [2:0]   raw_data_size
);

    // Address decoding
    localparam ADDR_REG_BASE = 12'h000;
    localparam ADDR_REG_END  = 12'h044;
    localparam ADDR_RAW_BASE = 12'h048;
    localparam ADDR_RAW_END  = 15'h7FFC;

    wire    addr_is_reg = (haddr[14:0] >= ADDR_REG_BASE) && (haddr[14:0] <= ADDR_REG_END);
    wire    addr_is_raw = (haddr[14:0] >= ADDR_RAW_BASE) && (haddr[14:0] <= ADDR_RAW_END);

    // Transfer state
    reg     hready_reg;
    reg [1:0] hresp_reg;
    reg [31:0] hrdata_reg;

    wire    transfer_active = hsel && htrans[1] && hready;

    assign hreadyout = hready_reg;
    assign hresp = hresp_reg;
    assign hrdata = hrdata_reg;

    // Register access logic
    assign reg_addr = haddr[14:0];
    assign reg_wr_data = hwdata;
    assign reg_wr_en = transfer_active && hwrite && addr_is_reg;

    // Raw data access logic
    assign raw_data_wr = transfer_active && hwrite && addr_is_raw;
    assign raw_data_wdata = hwdata;
    assign raw_data_size = hsize;

    always @(posedge hclk or negedge hreset_n) begin
        if (!hreset_n) begin
            hready_reg <= 1'b1;
            hresp_reg  <= 2'b0;
            hrdata_reg <= 32'b0;
        end else begin
            if (transfer_active) begin
                hready_reg <= 1'b0;
                if (addr_is_reg) begin
                    if (!hwrite) begin
                        hrdata_reg <= reg_rd_data;
                    end
                    hresp_reg <= 2'b0; // OKAY
                end else if (addr_is_raw) begin
                    if (!hwrite) begin
                        // Reading from raw data region returns latest written value
                        // This should be implemented in the regfile
                        hrdata_reg <= 32'h0;
                    end
                    hresp_reg <= 2'b0; // OKAY
                end else begin
                    hresp_reg <= 2'b1; // ERROR
                end
                hready_reg <= 1'b1;
            end else begin
                // No transfer, de-assert response
                hresp_reg <= 2'b0;
            end
        end
    end

endmodule
