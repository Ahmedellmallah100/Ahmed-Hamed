`default_nettype none

// Simple memory-mapped peripheral block.
// MMIO space: 0x10 - 0x1F
//   0x10 UART TX   write: transmit byte, read bit0: busy
//   0x11 GPIO OUT  read/write
//   0x12 TIMER CTL read/write bit0: enable
//   0x13 TIMER CNT read-only
//   0x14 OUT MODE  read/write: 00 CPU, 01 GPIO, 10 UART, 11 TIMER
//   0x15 GPIO IN  reserved for future external input
module Peripheral_Block (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] address,
    input  wire       mem_write,
    input  wire       mem_read,
    input  wire [7:0] write_data,
    input  wire       uart_busy,
    input  wire [7:0] timer_count,
    output wire       uart_start,
    output reg        timer_enable,
    output reg  [7:0] gpio_out,
    output reg  [1:0] output_mode,
    output wire [7:0] read_data,
    output wire       is_mmio
);
    localparam ADDR_UART_TX   = 8'h10;
    localparam ADDR_GPIO_OUT  = 8'h11;
    localparam ADDR_TIMER_CTL = 8'h12;
    localparam ADDR_TIMER_CNT = 8'h13;
    localparam ADDR_OUT_MODE  = 8'h14;
    localparam ADDR_GPIO_IN   = 8'h15;

    assign is_mmio    = (address[7:4] == 4'h1);
    assign uart_start = mem_write && (address == ADDR_UART_TX);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            timer_enable <= 1'b0;
            gpio_out     <= 8'h00;
            output_mode  <= 2'b00;
        end else if (mem_write) begin
            case (address)
                ADDR_GPIO_OUT:  gpio_out     <= write_data;
                ADDR_TIMER_CTL: timer_enable <= write_data[0];
                ADDR_OUT_MODE:  output_mode  <= write_data[1:0];
                default: ;
            endcase
        end
    end

    reg [7:0] read_mux;
    always @(*) begin
        case (address)
            ADDR_UART_TX:   read_mux = {7'b0, uart_busy};
            ADDR_GPIO_OUT:  read_mux = gpio_out;
            ADDR_TIMER_CTL: read_mux = {7'b0, timer_enable};
            ADDR_TIMER_CNT: read_mux = timer_count;
            ADDR_OUT_MODE:  read_mux = {6'b0, output_mode};
            ADDR_GPIO_IN:   read_mux = 8'h00;
            default:        read_mux = 8'h00;
        endcase
    end

    assign read_data = mem_read ? read_mux : 8'h00;
endmodule
