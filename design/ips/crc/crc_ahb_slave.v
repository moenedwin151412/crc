//
// crc_ahb_slave.v - AHB-Lite Slave Interface
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

    // Transfer detection with single-cycle pulse
    // Use edge detection to ensure only one pulse per transfer
    reg        transfer_d;
    reg        transfer_dd;
    wire       transfer_start = hsel && htrans[1] && hready;
    
    // Two-cycle delayed pulse - this gives one cycle for address, one for data
    always @(posedge hclk or negedge hreset_n) begin
        if (!hreset_n) begin
            transfer_d <= 1'b0;
            transfer_dd <= 1'b0;
        end else begin
            transfer_d <= transfer_start;
            transfer_dd <= transfer_d;
        end
    end
    
    // Pulse is active when previous cycle had transfer but current doesn't
    // This creates a single-cycle pulse at the end of the transfer
    wire       data_phase_pulse = transfer_d && !transfer_dd;

    // Latched address and control signals (captured when transfer starts)
    reg [14:0] addr_reg;
    reg        hwrite_reg;
    reg [2:0]  hsize_reg;
    reg        addr_is_reg_reg;
    reg        addr_is_raw_reg;
    
    always @(posedge hclk or negedge hreset_n) begin
        if (!hreset_n) begin
            addr_reg <= 15'b0;
            hwrite_reg <= 1'b0;
            hsize_reg <= 3'b0;
            addr_is_reg_reg <= 1'b0;
            addr_is_raw_reg <= 1'b0;
        end else if (transfer_start && !transfer_d) begin
            // Latch on first cycle of transfer
            addr_reg <= haddr[14:0];
            hwrite_reg <= hwrite;
            hsize_reg <= hsize;
            addr_is_reg_reg <= addr_is_reg;
            addr_is_raw_reg <= addr_is_raw;
        end
    end

    // Outputs
    assign hreadyout = 1'b1;  // Never insert wait states
    assign hresp = 2'b00;     // Always OKAY
    
    // For reads, use latched address
    assign hrdata = (data_phase_pulse && !hwrite_reg && addr_is_reg_reg) ? reg_rd_data : 32'h0;
    
    // Register interface
    assign reg_addr = addr_reg;
    assign reg_wr_data = hwdata;
    assign reg_wr_en = data_phase_pulse && hwrite_reg && addr_is_reg_reg;
    
    // Raw data interface
    assign raw_data_wr = data_phase_pulse && hwrite_reg && addr_is_raw_reg;
    assign raw_data_wdata = hwdata;
    assign raw_data_size = hsize_reg;

endmodule
