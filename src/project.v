/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

/*
 * This is the main module of the project.
 * It defines the different submodules/blocks and interconnects them. It also provides them with in and outputs.
 */
module tt_um_tamagotchi (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  wire [1:0] red;
  wire [1:0] green;
  wire [1:0] blue;

  vga vga_inst (
      .rst_n(rst_n),
      .clk(clk),
      .cat_pos_x(10'd0),
      .fish_pos_x(10'd0),
      .cat_pos_y(10'd0),
      .fish_pos_y(10'd0),
      .is_sleeping(1'b0),
      .is_playing(1'b0),
      .is_eating(1'b0),
      .is_dead(1'b0),
      .show_bang(1'b0),
      .hsync(),
      .vsync(),
      .R(red),
      .G(green),
      .B(blue),
      .uo_out(uo_out)
  );

  assign uio_out = 0;
  assign uio_oe  = 0;

  wire _unused = &{ena, ui_in, uio_in, red, green, blue, 1'b0};

endmodule
