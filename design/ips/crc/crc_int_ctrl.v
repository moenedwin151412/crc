//
// crc_int_ctrl.v
//

module crc_int_ctrl (
    input           clk,
    input           rst_n,

    // Interrupt sources
    input           done_if,
    input           done_ie,

    // Interrupt output
    output          crc_irq
);

    reg crc_irq_reg;
    assign crc_irq = crc_irq_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_irq_reg <= 1'b0;
        end else begin
            if (done_if && done_ie) begin
                crc_irq_reg <= 1'b1;
            end else begin
                crc_irq_reg <= 1'b0;
            end
        end
    end

endmodule
