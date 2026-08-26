`default_nettype none

module palette_heart (
    input  wire [1:0] color_index,
    output wire [5:0] rrggbb
);

  reg [5:0] palette[3:0];

  initial begin
    palette[0] = 6'b101011;  // heart background color: same as normal background --> light purple for now
    palette[1] = 6'b000000;  // black
    palette[2] = 6'b111111;  // white
    palette[3] = 6'b110000;  // red
  end

  assign rrggbb = palette[color_index];

endmodule