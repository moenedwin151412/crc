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

    // Internal state
    localparam S_IDLE = 0;
    localparam S_BUSY = 1;
    reg state;

    reg [63:0] crc_reg;
    reg [31:0] data_cnt_reg;
    reg        is_first_data;

    // Bit reversal function for input data
    function [7:0] reverse_byte;
        input [7:0] data;
        integer i;
        begin
            for (i = 0; i < 8; i = i + 1) begin
                reverse_byte[i] = data[7-i];
            end
        end
    endfunction

    // Process incoming data based on size
    wire [7:0] byte0 = poly_rev_in ? reverse_byte(raw_data_wdata[7:0])   : raw_data_wdata[7:0];
    wire [7:0] byte1 = poly_rev_in ? reverse_byte(raw_data_wdata[15:8])  : raw_data_wdata[15:8];
    wire [7:0] byte2 = poly_rev_in ? reverse_byte(raw_data_wdata[23:16]) : raw_data_wdata[23:16];
    wire [7:0] byte3 = poly_rev_in ? reverse_byte(raw_data_wdata[31:24]) : raw_data_wdata[31:24];

    wire [3:0] bytes_to_process = (raw_data_size == 3'b000) ? 4'd1 :
                                  (raw_data_size == 3'b001) ? 4'd2 :
                                  (raw_data_size == 3'b010) ? 4'd4 : 4'd0;

    // Next CRC value calculation (combinational)
    wire [63:0] crc_next;
    reg  [63:0] temp_crc;
    reg  [7:0]  data_chunk;
    integer i, j;

    always @* begin
        temp_crc = crc_reg;
        
        // Apply initial XOR on the very first data chunk
        if (is_first_data) begin
            temp_crc = crc_reg ^ init_xor_val;
        end

        // Process byte 0
        data_chunk = byte0;
        for (i = 0; i < 8; i = i + 1) begin
            if ((temp_crc >> (crc_width_bits - 1)) ^ data_chunk[7-i]) begin
                temp_crc = (temp_crc << 1) ^ poly_val;
            end else begin
                temp_crc = temp_crc << 1;
            end
        end

        // Process byte 1 if applicable
        if (bytes_to_process > 1) begin
            data_chunk = byte1;
            for (i = 0; i < 8; i = i + 1) begin
                if ((temp_crc >> (crc_width_bits - 1)) ^ data_chunk[7-i]) begin
                    temp_crc = (temp_crc << 1) ^ poly_val;
                end else begin
                    temp_crc = temp_crc << 1;
                end
            end
        end

        // Process byte 2 if applicable
        if (bytes_to_process > 3) begin
            data_chunk = byte2;
            for (i = 0; i < 8; i = i + 1) begin
                if ((temp_crc >> (crc_width_bits - 1)) ^ data_chunk[7-i]) begin
                    temp_crc = (temp_crc << 1) ^ poly_val;
                end else begin
                    temp_crc = temp_crc << 1;
                end
            end
            
            data_chunk = byte3;
            for (i = 0; i < 8; i = i + 1) begin
                if ((temp_crc >> (crc_width_bits - 1)) ^ data_chunk[7-i]) begin
                    temp_crc = (temp_crc << 1) ^ poly_val;
                end else begin
                    temp_crc = temp_crc << 1;
                end
            end
        end
        crc_next = temp_crc;
    end

    // Determine CRC bit width
    wire [5:0] crc_width_bits = (crc_width == 2'b00) ? 8 :
                                (crc_width == 2'b01) ? 16 :
                                (crc_width == 2'b10) ? 32 : 64;

    // Final result processing (output reversal and XOR)
    wire [63:0] reversed_crc;
    genvar k;
    generate
        for (k = 0; k < 64; k = k + 1) begin
            assign reversed_crc[k] = crc_reg[63-k];
        end
    endgenerate

    wire [63:0] final_crc = poly_rev_out ? reversed_crc : crc_reg;

    assign busy = (state == S_BUSY);
    assign done = (state == S_BUSY) && (data_len > 0) && (data_cnt_reg == data_len);
    assign result = final_crc ^ out_xor_val;
    assign data_cnt_out = data_cnt_reg;

    // State machine and register updates
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            crc_reg <= 64'b0;
            data_cnt_reg <= 32'b0;
            is_first_data <= 1'b1;
        end else begin
            if (crc_rst || crc_start) begin
                state <= crc_start ? S_BUSY : S_IDLE;
                crc_reg <= preset_val;
                data_cnt_reg <= 32'b0;
                is_first_data <= 1'b1;
            end else if (state == S_BUSY) begin
                if (raw_data_wr) begin
                    crc_reg <= crc_next;
                    data_cnt_reg <= data_cnt_reg + bytes_to_process;
                    is_first_data <= 1'b0;
                end
                
                if (done) begin
                    // State will transition to IDLE on next start/reset
                end
            end
        end
    end

endmodule
