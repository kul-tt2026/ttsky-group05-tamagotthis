`default_nettype none

module palette_star (
    input  wire [1:0] color_index,
    input wire [5:0] background_color,
    output wire [5:0] rrggbb
);

  assign rrggbb = 
      (color_index == 0) ? background_color :
      (color_index == 1) ? 6'b111110 :
      6'b111111;

endmodule