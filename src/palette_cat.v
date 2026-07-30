/* Maps colour indices to RGB values.
 * The cat and fish use a different palette.
 */

module palette_cat (
    input  wire [1:0] color_index,
    output wire [5:0] rrggbb
);

  reg [5:0] palette[3:0];

  initial begin
    palette[0] = 6'b101011;  // background color: light purple
    palette[1] = 6'b000000;  // black
    palette[2] = 6'b010101;  // gray
    palette[3] = 6'b111111;  // white
  end

  assign rrggbb = palette[color_index];

endmodule
