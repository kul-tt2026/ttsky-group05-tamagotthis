`default_nettype none

module palette_eyes (
    input  wire color_index,
    output wire [5:0] rrggbb
);

  assign rrggbb = 
      (color_index == 0) ? 6'b010101 : 6'b000000;

endmodule