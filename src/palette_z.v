`default_nettype none

module palette_z (
    input  wire color_index,
    output wire [5:0] rrggbb
);

  reg [5:0] palette[3:0];

  initial begin
    palette[0] = 6'b101011;  // background color: pastel purple
    palette[1] = 6'b000000;  // black
  end

  assign rrggbb = palette[color_index];

endmodule