/*
 * Copyright (c) 2024 Jan Kozina
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_8bit_risc_cpu (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

  wire rst = !rst_n;
  wire [7:0] cpu_out;
  wire [7:0] peripheral_out;

  CPU_Core CPU_Core (
    .clk(clk),
    .rst(rst),
    .instruction({ui_in, uio_in}),
    .CPU_out(cpu_out),
    .peripheral_out(peripheral_out)
  );

  // Output is selected by MMIO OUTPUT_MODE: CPU / GPIO / UART / TIMER.
  assign uo_out = peripheral_out;

  // uio pins remain instruction inputs for now.
  assign uio_out = 8'b0;
  assign uio_oe  = 8'b0;

  wire _unused = &{ena, 1'b0};

endmodule
