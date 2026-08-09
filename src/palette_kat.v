/*
 * Copyright (c) 2024 Tiny Tapeout LTD
 * SPDX-License-Identifier: Apache-2.0
 * Author: Uri Shaked
 */

`default_nettype none

module palette_kat (
    input  wire [1:0] color_index,
    output wire [5:0] rrggbb
);

  reg [5:0] palette[3:0];

  initial begin
    palette[0] = 6'b101011;  // background color of the little square: light purple
    palette[1] = 6'b000000;  // black
    palette[3] = 6'b010101;  // gray
    palette[2] = 6'b111111;  // white
  end

  assign rrggbb = palette[color_index];

endmodule