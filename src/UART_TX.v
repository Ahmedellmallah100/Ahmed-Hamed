`default_nettype none

// Simple 8-N-1 UART transmitter.
// A write pulse starts one frame when the transmitter is idle.
module UART_TX #(
    parameter integer CLKS_PER_BIT = 87  // 10 MHz / 115200 ~= 86.8
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       start,
    input  wire [7:0] data_in,
    output wire       tx,
    output wire       busy
);
    reg       tx_reg;
    reg       busy_reg;
    reg [15:0] clk_count;
    reg [3:0]  bit_count;
    reg [9:0]  shift_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx_reg    <= 1'b1;
            busy_reg  <= 1'b0;
            clk_count <= 16'd0;
            bit_count <= 4'd0;
            shift_reg <= 10'h3FF;
        end else begin
            if (start && !busy_reg) begin
                // {stop, data[7:0], start}; LSB is transmitted first.
                shift_reg <= {1'b1, data_in, 1'b0};
                busy_reg  <= 1'b1;
                clk_count <= 16'd0;
                bit_count <= 4'd0;
                tx_reg    <= 1'b0;
            end else if (busy_reg) begin
                if (clk_count == CLKS_PER_BIT - 1) begin
                    clk_count <= 16'd0;
                    if (bit_count == 4'd9) begin
                        busy_reg <= 1'b0;
                        tx_reg   <= 1'b1;
                    end else begin
                        bit_count <= bit_count + 4'd1;
                        shift_reg <= {1'b1, shift_reg[9:1]};
                        tx_reg    <= shift_reg[1];
                    end
                end else begin
                    clk_count <= clk_count + 16'd1;
                end
            end
        end
    end

    assign tx   = tx_reg;
    assign busy = busy_reg;
endmodule
