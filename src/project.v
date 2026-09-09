/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_example (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path
    input  wire       ena,      // always 1 when powered
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // ============================================================
  // 4-Input Perceptron
  //
  // z = w1*x1 + w2*x2 + w3*x3 + w4*x4 + bias
  //
  // prediction = 1 if z >= 0
  // prediction = 0 if z < 0
  // ============================================================

  // ------------------------------------------------------------
  // Inputs
  // ui_in[3:0] = x1, x2, x3, x4
  // ------------------------------------------------------------

  wire x1 = ui_in[0];
  wire x2 = ui_in[1];
  wire x3 = ui_in[2];
  wire x4 = ui_in[3];

  // ------------------------------------------------------------
  // Fixed weights
  // 4-bit signed weights
  // ------------------------------------------------------------

  wire signed [3:0] w1 = 4'sd1;
  wire signed [3:0] w2 = 4'sd1;
  wire signed [3:0] w3 = 4'sd1;
  wire signed [3:0] w4 = 4'sd1;

  // Bias = -2
  wire signed [5:0] bias = -6'sd2;

  // ------------------------------------------------------------
  // Weighted sum
  //
  // Since x is only 0 or 1:
  //
  // x = 0 -> contribution = 0
  // x = 1 -> contribution = weight
  // ------------------------------------------------------------

  wire signed [5:0] p1 = x1 ? w1 : 6'sd0;
  wire signed [5:0] p2 = x2 ? w2 : 6'sd0;
  wire signed [5:0] p3 = x3 ? w3 : 6'sd0;
  wire signed [5:0] p4 = x4 ? w4 : 6'sd0;

  wire signed [5:0] z;

  assign z = p1 + p2 + p3 + p4 + bias;

  // ------------------------------------------------------------
  // Step activation
  // ------------------------------------------------------------

  wire prediction;

  assign prediction = (z >= 0);

  // ------------------------------------------------------------
  // Outputs
  //
  // uo_out[0] = prediction
  // uo_out[6:1] = z
  // uo_out[7] = 0
  // ------------------------------------------------------------

  assign uo_out[0]   = prediction;
  assign uo_out[6:1] = z[5:0];
  assign uo_out[7]   = 1'b0;

  // ------------------------------------------------------------
  // uio pins unused
  // ------------------------------------------------------------

  assign uio_out = 8'b0;
  assign uio_oe  = 8'b0;

  // ------------------------------------------------------------
  // Unused inputs
  // ------------------------------------------------------------

  wire _unused = &{ena, clk, rst_n, uio_in};

endmodule
