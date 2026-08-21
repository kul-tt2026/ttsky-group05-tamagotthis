`default_nettype none

module palette_fish (
    input  wire [1:0] color_index,
    output wire [5:0] rrggbb
);

  reg [5:0] palette[3:0];

  initial begin
    palette[0] = 6'b101110;  // fish background color: pastel blue
    palette[1] = 6'b000000;  // black
    palette[3] = 6'b101011;  // gray
    palette[2] = 6'b111111;  // white
  end

  assign rrggbb = palette[color_index];

endmodule
