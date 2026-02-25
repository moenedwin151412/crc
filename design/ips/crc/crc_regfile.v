//
// crc_regfile.v
//

module crc_regfile (
    input           clk,
    input           rst_n,

    // AHB Interface
    input           wr_en,
    input   [14:0]  addr,
    input   [31:0]  wr_data,
    output  [31:0]  rd_data,

    // Engine Interface
    input           engine_busy,
    input           engine_done,
    input   [63:0]  crc_result,
    input   [31:0]  data_cnt,
    input           raw_data_wr,
    input   [2:0]   raw_data_size,

    // Configuration Outputs
    output  [63:0]  poly_val,
    output  [63:0]  preset_val,
    output  [63:0]  init_xor_val,
    output  [63:0]  out_xor_val,
    output  [1:0]   crc_width,
    output          crc_start,
    output          crc_rst,
    output          poly_rev_in,
    output          poly_rev_out,
    output          done_ie,
    output  [31:0]  data_len,
    output  [3:0]   fixed_poly_sel,
    output          data_len_wr     // Pulse when data_len is written
);

    // Register addresses
    localparam ADDR_CRC_CTRL        = 12'h00;
    localparam ADDR_CRC_STATUS      = 12'h04;
    localparam ADDR_CRC_POLY_CFG    = 12'h08;
    localparam ADDR_CRC_POLY_VAL_L  = 12'h0C;
    localparam ADDR_CRC_POLY_VAL_H  = 12'h10;
    localparam ADDR_CRC_PRESET_L    = 12'h14;
    localparam ADDR_CRC_PRESET_H    = 12'h18;
    localparam ADDR_CRC_INIT_XOR_L  = 12'h1C;
    localparam ADDR_CRC_INIT_XOR_H  = 12'h20;
    localparam ADDR_CRC_OUT_XOR_L   = 12'h24;
    localparam ADDR_CRC_OUT_XOR_H   = 12'h28;
    localparam ADDR_CRC_RESULT_L    = 12'h2C;
    localparam ADDR_CRC_RESULT_H    = 12'h30;
    localparam ADDR_CRC_INT_EN      = 12'h34;
    localparam ADDR_CRC_INT_STATUS  = 12'h38;
    localparam ADDR_CRC_INT_CLR     = 12'h3C;
    localparam ADDR_CRC_DATA_LEN    = 12'h40;
    localparam ADDR_CRC_DATA_CNT    = 12'h44;

    // Registers
    reg [1:0]   crc_width_reg;
    reg         crc_start_reg;
    reg         crc_rst_reg;
    reg [3:0]   fixed_poly_sel_reg;
    reg         poly_rev_in_reg;
    reg         poly_rev_out_reg;
    reg [31:0]  poly_val_l_reg;
    reg [31:0]  poly_val_h_reg;
    reg [31:0]  preset_val_l_reg;
    reg [31:0]  preset_val_h_reg;
    reg [31:0]  init_xor_l_reg;
    reg [31:0]  init_xor_h_reg;
    reg [31:0]  out_xor_l_reg;
    reg [31:0]  out_xor_h_reg;
    reg         done_ie_reg;
    reg [31:0]  data_len_reg;
    reg         done_if_reg;

    // Assign outputs
    assign crc_width = crc_width_reg;
    assign crc_start = crc_start_reg;
    assign crc_rst = crc_rst_reg;
    assign poly_rev_in = poly_rev_in_reg;
    assign poly_rev_out = poly_rev_out_reg;
    assign poly_val = {poly_val_h_reg, poly_val_l_reg};
    assign preset_val = {preset_val_h_reg, preset_val_l_reg};
    assign init_xor_val = {init_xor_h_reg, init_xor_l_reg};
    assign out_xor_val = {out_xor_h_reg, out_xor_l_reg};
    assign done_ie = done_ie_reg;
    assign data_len = data_len_reg;
    assign fixed_poly_sel = fixed_poly_sel_reg;
    
    // Generate pulse when data_len is written (for counter reset)
    assign data_len_wr = wr_en && (addr == ADDR_CRC_DATA_LEN);

    // Read logic
    reg [31:0]  rd_data_reg;
    assign rd_data = rd_data_reg;

    always @(*) begin
        case (addr)
            ADDR_CRC_CTRL:      rd_data_reg = {24'b0, fixed_poly_sel_reg, crc_rst_reg, crc_start_reg, crc_width_reg};
            ADDR_CRC_STATUS:    rd_data_reg = {30'b0, engine_done, engine_busy};
            ADDR_CRC_POLY_CFG:  rd_data_reg = {30'b0, poly_rev_out_reg, poly_rev_in_reg};
            ADDR_CRC_POLY_VAL_L:rd_data_reg = poly_val_l_reg;
            ADDR_CRC_POLY_VAL_H:rd_data_reg = poly_val_h_reg;
            ADDR_CRC_PRESET_L:  rd_data_reg = preset_val_l_reg;
            ADDR_CRC_PRESET_H:  rd_data_reg = preset_val_h_reg;
            ADDR_CRC_INIT_XOR_L:rd_data_reg = init_xor_l_reg;
            ADDR_CRC_INIT_XOR_H:rd_data_reg = init_xor_h_reg;
            ADDR_CRC_OUT_XOR_L: rd_data_reg = out_xor_l_reg;
            ADDR_CRC_OUT_XOR_H: rd_data_reg = out_xor_h_reg;
            ADDR_CRC_RESULT_L:  rd_data_reg = crc_result[31:0];
            ADDR_CRC_RESULT_H:  rd_data_reg = crc_result[63:32];
            ADDR_CRC_INT_EN:    rd_data_reg = {31'b0, done_ie_reg};
            ADDR_CRC_INT_STATUS:rd_data_reg = {31'b0, done_if_reg};
            ADDR_CRC_DATA_LEN:  rd_data_reg = data_len_reg;
            ADDR_CRC_DATA_CNT:  rd_data_reg = data_cnt;
            default:            rd_data_reg = 32'h0;
        endcase
    end

    // Write logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_width_reg <= 2'b10; // CRC32
            crc_start_reg <= 1'b0;
            crc_rst_reg <= 1'b0;
            fixed_poly_sel_reg <= 4'b0;
            poly_rev_in_reg <= 1'b0;
            poly_rev_out_reg <= 1'b0;
            poly_val_l_reg <= 32'h04C11DB7;
            poly_val_h_reg <= 32'h0;
            preset_val_l_reg <= 32'hFFFFFFFF;
            preset_val_h_reg <= 32'hFFFFFFFF;
            init_xor_l_reg <= 32'h0;
            init_xor_h_reg <= 32'h0;
            out_xor_l_reg <= 32'hFFFFFFFF;
            out_xor_h_reg <= 32'hFFFFFFFF;
            done_ie_reg <= 1'b0;
            data_len_reg <= 32'h0;
            done_if_reg <= 1'b0;
        end else begin
            if (wr_en) begin
                case (addr)
                    ADDR_CRC_CTRL: begin
                        crc_width_reg <= wr_data[1:0];
                        crc_start_reg <= wr_data[2];
                        crc_rst_reg   <= wr_data[3];
                        fixed_poly_sel_reg <= wr_data[7:4];
                    end
                    ADDR_CRC_POLY_CFG: begin
                        poly_rev_in_reg <= wr_data[0];
                        poly_rev_out_reg <= wr_data[1];
                    end
                    ADDR_CRC_POLY_VAL_L: poly_val_l_reg <= wr_data;
                    ADDR_CRC_POLY_VAL_H: poly_val_h_reg <= wr_data;
                    ADDR_CRC_PRESET_L:   preset_val_l_reg <= wr_data;
                    ADDR_CRC_PRESET_H:   preset_val_h_reg <= wr_data;
                    ADDR_CRC_INIT_XOR_L: init_xor_l_reg <= wr_data;
                    ADDR_CRC_INIT_XOR_H: init_xor_h_reg <= wr_data;
                    ADDR_CRC_OUT_XOR_L:  out_xor_l_reg <= wr_data;
                    ADDR_CRC_OUT_XOR_H:  out_xor_h_reg <= wr_data;
                    ADDR_CRC_INT_EN:     done_ie_reg <= wr_data[0];
                    ADDR_CRC_INT_STATUS: done_if_reg <= done_if_reg & ~wr_data[0]; // W1C
                    ADDR_CRC_INT_CLR:    if(wr_data[0]) done_if_reg <= 1'b0;
                    ADDR_CRC_DATA_LEN:   data_len_reg <= wr_data;
                endcase
            end else begin
                // Self-clearing bits (only when not writing)
                if (crc_start_reg) crc_start_reg <= 1'b0;
                if (crc_rst_reg) crc_rst_reg <= 1'b0;
            end
            
            if (engine_done) begin
                done_if_reg <= 1'b1;
            end
        end
    end

endmodule
