`default_nettype none

module palette_eyes (
    input  wire color_index,
    output wire [5:0] rrggbb
);

  reg [5:0] palette[3:0];

  initial begin
    palette[0] = 6'b000000;  // black
    palette[1] = 6'b010101;  // gray
  end

  assign rrggbb = palette[color_index];

endmodule