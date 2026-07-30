/*
* The VGA module handles what is shown on the VGA screen.
* Note: since different states require different outputs on the screen, it's probably best to create state specific modules and use them in this high-level module.
* Note: use hvsync_generator.v for the timing.
*/

module vga (
    input rst_n, clk,                                                       // Global active-low reset and clock.
    input [9:0] cat_pos_x, fish_pos_x,                                      // The x-positions of the cat and fish.
    input [9:0] cat_pos_y, fish_pos_y,                                      // The y-positionsof the cat and fish.
    input is_sleeping, is_playing, is_eating, is_dead, show_bang,           // Signals to determine what has to be shown on the VGA.
    output hsync, vsync,                                                    // VGA horizontal and vertical sync signals, going the the VGA PMOD.
    output reg [1:0] R, G, B                                                // VGA color signals, going to the VGA PMOD.
);

    // NIET GETEST
    // gebaseerd op vga playground (https://vga-playground.com/?preset=logo) en nyan cat repo (https://github.com/a1k0n/tt08-nyan/blob/main/src/tt_um_a1k0n_nyancat.v)
    // default_cat.hex was generated using imageconverttohex.py + done in vscode on my laptop, since it required some extra libraries
    // the cat came out a bit weird so there's something wrong in the converting script

    // instantiate hvsync module
    wire video_active;
    wire [9:0] pix_x;
    wire [9:0] pix_y;

    hvsync_generator hvsync_gen(
    .clk(clk),
    .reset(~rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .hpos(pix_x),
    .vpos(pix_y)
  );

    // read cat to memory
    reg [1:0] default_cat[0:1023];
    initial begin
        $readmemh("../data/default_cat.hex", default_cat);
    end


    // actual displaying logic
    reg [9:0] cat_left = 10'd200;                       // in reality cat_left = cat_pos_x
    reg [9:0] cat_top = 10'd200;


    wire [9:0] x = pix_x - cat_left;
    wire [9:0] y = pix_y - cat_top;
    wire logo_pixels = (x[9:5] == 0 && y[9:5] == 0);    // True when x is 0..31 AND y is 0..31 (a 32x32 bounding box)


    wire [9:0] kat_addr = {y[4:0], x[4:0]};
    wire [1:0] pixel_value = default_cat[kat_addr];
    wire [5:0] color;

    palette_cat palette (
    .color_index(pixel_value),
    .rrggbb(color)
  );


    // RGB output logic
    always @(posedge clk) begin
        if (~rst_n) begin
            R <= 0;
            G <= 0;
            B <= 0;
        end else begin
            R <= 2'b10;           // default output is background color
            G <= 2'b10;
            B <= 2'b11;
            if (video_active && logo_pixels) begin
                R <= color[5:4];
                G <= color[3:2];
                B <= color[1:0];
            end
        end
    end

endmodule
