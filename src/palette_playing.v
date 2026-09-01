`default_nettype none

module palette_playing (
    input  wire [3:0] color_index,
    output wire [5:0] rrggbb
);

    assign rrggbb =
        (color_index == 4'd0) ? 6'b101110 :     // light green
        (color_index == 4'd1) ? 6'b101011 :     // light purple
        (color_index == 4'd2) ? 6'b111010 :     // peach
        (color_index == 4'd3) ? 6'b101111 :     // light blue
        (color_index == 4'd4) ? 6'b111011 :     // light pink
        (color_index == 4'd5) ? 6'b111110 :     // light yellow
        (color_index == 4'd6) ? 6'b011010 :     // teal
        (color_index == 4'd7) ? 6'b100110 :     // a bit darker purple
        (color_index == 4'd8) ? 6'b101001 :     // khaki
        (color_index == 4'd9) ? 6'b100111 :     // another purple
        (color_index == 4'd10) ? 6'b011011 :    // a bit darker blue
        (color_index == 4'd11) ? 6'b110110 :    // a bit darker pink
        (color_index == 4'd12) ? 6'b111001 :    // light orange
        (color_index == 4'd13) ? 6'b011110 :    // turquoise
        (color_index == 4'd14) ? 6'b101101 :    // another green
        6'b101010;                              // gray
endmodule
