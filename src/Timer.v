`default_nettype none

// 8-bit free-running timer with a programmable enable bit.
module Timer (
    input  wire       clk,
    input  wire       rst,
    input  wire       enable,
    output wire [7:0] count
);
    reg [7:0] count_reg;

    always @(posedge clk or posedge rst) begin
        if (rst)
            count_reg <= 8'd0;
        else if (enable)
            count_reg <= count_reg + 8'd1;
    end

    assign count = count_reg;
endmodule
