//
// crc_engine.v
//

module crc_engine (
    input           clk,
    input           rst_n,

    // Configuration
    input   [63:0]  poly_val,
    input   [63:0]  preset_val,
    input   [63:0]  init_xor_val,
    input   [63:0]  out_xor_val,
    input   [1:0]   crc_width,
    input           crc_start,
    input           crc_rst,
    input           poly_rev_in,
    input           poly_rev_out,
    input   [31:0]  data_len,

    // Data Input
    input           raw_data_wr,
    input   [31:0]  raw_data_wdata,
    input   [2:0]   raw_data_size,

    // Status Output
    output          busy,
    output          done,
    output  [63:0]  result,
    output  [31:0]  data_cnt_out
);

    // State machine
    localparam S_IDLE = 0;
    localparam S_BUSY = 1;
    reg state;

    reg [63:0] crc_reg;
    reg [31:0] data_cnt_reg;
    
    wire [63:0] crc_next;

    assign busy = (state == S_BUSY);
    assign done = (state == S_BUSY) && (data_len > 0) && (data_cnt_reg == data_len);
    assign result = crc_reg ^ out_xor_val;
    assign data_cnt_out = data_cnt_reg;
    
    // CRC calculation logic
    // This is a simplified parallel implementation. 
    // A real implementation would be more complex and likely bit-serial.
    
    wire [7:0] data_in;
    assign data_in = raw_data_size == 3'b000 ? raw_data_wdata[7:0] :
                     raw_data_size == 3'b001 ? raw_data_wdata[15:8] : // Assuming little-endian
                                               raw_data_wdata[31:24];

    // Simplified CRC-8 logic for demonstration
    function [7:0] crc8_next(input [7:0] current_crc, input [7:0] data, input [7:0] poly);
        integer i;
        begin
            crc8_next = current_crc ^ data;
            for (i=0; i<8; i=i+1) begin
                if (crc8_next[7])
                    crc8_next = (crc8_next << 1) ^ poly;
                else
                    crc8_next = crc8_next << 1;
            end
        end
    endfunction
    
    wire [7:0] crc8_next_val = crc8_next(crc_reg[7:0], data_in, poly_val[7:0]);
    // Similar functions would be needed for CRC16, CRC32, CRC64

    assign crc_next = crc_width == 2'b00 ? {56'h0, crc8_next_val} :
                      // Placeholder for other widths
                      crc_reg; 

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            crc_reg <= 64'b0;
            data_cnt_reg <= 32'b0;
        end else begin
            case (state)
                S_IDLE: begin
                    if (crc_start) begin
                        crc_reg <= preset_val;
                        data_cnt_reg <= 32'b0;
                        state <= S_BUSY;
                    end
                end
                S_BUSY: begin
                    if (crc_rst) begin
                        state <= S_IDLE;
                    end else if (raw_data_wr) begin
                        crc_reg <= crc_next;
                        data_cnt_reg <= data_cnt_reg + (raw_data_size == 3'b000 ? 1 : (raw_data_size == 3'b001 ? 2 : 4));
                    end
                    
                    if (done) begin
                        state <= S_IDLE;
                    end
                end
            endcase
        end
    end

endmodule
