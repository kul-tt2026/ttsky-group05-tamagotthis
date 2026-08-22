`default_nettype none

module palette_battery (
    input  wire [1:0] color_index,
    output wire [5:0] rrggbb
);

  reg [5:0] palette[3:0];

  initial begin
    palette[0] = 6'b000000;  // black
    palette[1] = 6'b110000;  // red
    palette[2] = 6'b111100;  // yellow
    palette[3] = 6'b001100;  // green
  end

  assign rrggbb = palette[color_index];

endmodule