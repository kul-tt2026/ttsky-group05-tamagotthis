`default_nettype none

module palette_heart (
    input  wire [1:0] color_index,
    input  wire [5:0] background_color,
    output wire [5:0] rrggbb
);

    assign rrggbb =
        (color_index == 2'd0) ? background_color :
        (color_index == 2'd1) ? 6'b000000 :  // black
        (color_index == 2'd2) ? 6'b111111 :  // white
                                6'b110000;    // red

endmodule