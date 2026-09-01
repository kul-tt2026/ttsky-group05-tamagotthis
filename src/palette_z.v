`default_nettype none

module palette_z (
    input  wire color_index,
    input wire [5:0] background_color,
    output wire [5:0] rrggbb
);

  assign rrggbb = 
      (color_index == 0) ? background_color : 6'b101010;

endmodule