//
// crc_top.v
//

module crc_top (
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
    output  [31:0]  hrdata,
    output          hreadyout,
    output  [1:0]   hresp,

    // Interrupt Interface
    output          crc_irq
);

    // Internal Signals
    wire            reg_wr_en;
    wire    [11:0]  reg_addr;
    wire    [31:0]  reg_wr_data;
    wire    [31:0]  reg_rd_data;
    
    wire            raw_data_wr;
    wire    [31:0]  raw_data_wdata;
    wire    [2:0]   raw_data_size;

    wire    [63:0]  poly_val;
    wire    [63:0]  preset_val;
    wire    [63:0]  init_xor_val;
    wire    [63:0]  out_xor_val;
    wire    [1:0]   crc_width;
    wire            crc_start;
    wire            crc_rst;
    wire            poly_rev_in;
    wire            poly_rev_out;
    wire            done_ie;
    wire    [31:0]  data_len;

    wire            engine_busy;
    wire            engine_done;
    wire    [63:0]  crc_result;
    wire    [31:0]  data_cnt;
    
    wire            int_done;

    // Instantiate crc_ahb_slave
    crc_ahb_slave u_crc_ahb_slave (
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
        .reg_rd_data(reg_rd_data),
        .hrdata(hrdata),
        .hreadyout(hreadyout),
        .hresp(hresp),

        .reg_wr_en(reg_wr_en),
        .reg_addr(reg_addr),
        .reg_wr_data(reg_wr_data),
        .raw_data_wr(raw_data_wr),
        .raw_data_wdata(raw_data_wdata),
        .raw_data_size(raw_data_size)
    );

    // Instantiate crc_regfile
    crc_regfile u_crc_regfile (
        .clk(hclk),
        .rst_n(hreset_n),
        .wr_en(reg_wr_en),
        .addr(reg_addr),
        .wr_data(reg_wr_data),
        .rd_data(reg_rd_data),

        .engine_busy(engine_busy),
        .engine_done(engine_done),
        .crc_result(crc_result),
        .data_cnt(data_cnt),
        .raw_data_wr(raw_data_wr),
        .raw_data_size(raw_data_size),

        .poly_val(poly_val),
        .preset_val(preset_val),
        .init_xor_val(init_xor_val),
        .out_xor_val(out_xor_val),
        .crc_width(crc_width),
        .crc_start(crc_start),
        .crc_rst(crc_rst),
        .poly_rev_in(poly_rev_in),
        .poly_rev_out(poly_rev_out),
        .done_ie(done_ie),
        .data_len(data_len)
    );

    // Instantiate crc_engine
    crc_engine u_crc_engine (
        .clk(hclk),
        .rst_n(hreset_n),

        .poly_val(poly_val),
        .preset_val(preset_val),
        .init_xor_val(init_xor_val),
        .out_xor_val(out_xor_val),
        .crc_width(crc_width),
        .crc_start(crc_start),
        .crc_rst(crc_rst),
        .poly_rev_in(poly_rev_in),
        .poly_rev_out(poly_rev_out),
        .data_len(data_len),
        .raw_data_wr(raw_data_wr),
        .raw_data_wdata(raw_data_wdata),
        .raw_data_size(raw_data_size),

        .busy(engine_busy),
        .done(engine_done),
        .result(crc_result),
        .data_cnt_out(data_cnt)
    );

    // Instantiate crc_int_ctrl
    crc_int_ctrl u_crc_int_ctrl (
        .clk(hclk),
        .rst_n(hreset_n),
        .done_if(engine_done),
        .done_ie(done_ie),
        .crc_irq(crc_irq)
    );

endmodule
