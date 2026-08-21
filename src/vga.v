/*
* The VGA module handles what is shown on the VGA screen.
* Note: since different states require different outputs on the screen, it's probably best to create state specific modules and use them in this high-level module.
* Note: use hvsync_generator.v for the timing.
*/

// gebaseerd op vga playground (https://vga-playground.com/?preset=logo) en nyan cat repo (https://github.com/a1k0n/tt08-nyan/blob/main/src/tt_um_a1k0n_nyancat.v)

`default_nettype none

module vga (
    input rst_n, clk,                                                       // Global active-low reset and clock.
    input [9:0] cat_pos_x, fish_pos_x,                                      // The x-positions of the cat and fish.
    input [9:0] cat_pos_y, fish_pos_y,                                      // The y-positionsof the cat and fish.
    input is_sleeping, is_playing, is_eating, is_dead, show_bang,           // Signals to determine what has to be shown on the VGA.
    output hsync, vsync,                                                    // VGA horizontal and vertical sync signals, going the the VGA PMOD.
    output reg [1:0] R, G, B,                                               // VGA color signals, going to the VGA PMOD.
    output [7:0] uo_out
);

    parameter DISPLAY_WIDTH = 640;                                          // VGA display width
    parameter DISPLAY_HEIGHT = 480;                                         // VGA display height

    parameter MEM_CAT_WIDTH = 23;                                           // Width of the cat in kat.hex
    parameter MEM_CAT_HEIGHT = 25;                                          // Height of the cat in kat.hex

    parameter STRETCH_EXPONENT = 1;                                         // 0 = no stretching (i.e. stretch factor 1), 1 = stretch factor 2, 2 = stretch factor 4
    localparam STRETCH_FACTOR = 1 << STRETCH_EXPONENT;                      // Calculate the stretch factor based on the exponent

    localparam CAT_WIDTH = MEM_CAT_WIDTH * STRETCH_FACTOR;                  // Width of the cat after stretching
    localparam CAT_HEIGHT = MEM_CAT_HEIGHT * STRETCH_FACTOR;                // Height of the cat after stretching

    // used in hvsync
    wire video_active;
    wire [9:0] pix_x;
    wire [9:0] pix_y;

    // initial cat position
    reg [9:0] cat_left, cat_top;

    // for bouncing logic
    reg dir_x, dir_y;
    reg [9:0] prev_y;
    reg [1:0] color_index;

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
    reg [1:0] cat[0:MEM_CAT_WIDTH*MEM_CAT_HEIGHT-1];
    initial begin
        $readmemh("../src/data/kat.hex", cat);
    end

    // for static cat position
    // reg [9:0] cat_left = 10'd200;                       
    // reg [9:0] cat_top = 10'd200;


    wire [9:0] x = pix_x - cat_left;
    wire [9:0] y = pix_y - cat_top;
    wire logo_pixels = (x[9:6] == 0 && x[5:0] < (MEM_CAT_WIDTH << STRETCH_EXPONENT) && y[9:6] == 0 && y[5:0] < (MEM_CAT_HEIGHT << STRETCH_EXPONENT));
            // should be fine for stretch factor <= 2, for higher stretch factors, change x[9:6] to x[9:7] etc... (ook bij addr berekening hieronder)

    // addr = (y / stretch_factor) * MEM_CAT_WIDTH + (x / strech_factor) 
    // delen door strech factor (2^STRETCH_EXPONENT) door te shiften naar rechts met STRETCH_EXPONENT
    wire [9:0] kat_addr = ({4'b0,y[5:0]} >> STRETCH_EXPONENT) * MEM_CAT_WIDTH + {4'b0, x[5:0]} >> STRETCH_EXPONENT; 
    wire [1:0] pixel_value = cat[kat_addr];
    wire [5:0] color;

    palette_kat palette (
    .color_index(pixel_value),
    .rrggbb(color)
  );

    assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

    // RGB output logic
    always @(posedge clk) begin
        if (~rst_n) begin
            R <= 0;
            G <= 0;
            B <= 0;
        end else begin
            R <= 2'b10;           // default output is background color: light purple
            G <= 2'b10;
            B <= 2'b11;
            if (video_active && logo_pixels) begin
                R <= color[5:4];
                G <= color[3:2];
                B <= color[1:0];
            end
        end

    end

    // Bouncing logic
    always @(posedge clk) begin
        if (~rst_n) begin
            cat_left <= 200;
            cat_top <= 200;
            dir_y <= 0;
            dir_x <= 1;
            color_index <= 0;
        end else begin
            prev_y <= pix_y;
            if (pix_y == 0 && prev_y != pix_y) begin
                cat_left <= cat_left + (dir_x ? 1 : -1);
                cat_top  <= cat_top + (dir_y ? 1 : -1);
                if (cat_left - 1 == 0 && !dir_x) begin
                    dir_x <= 1;
                end
                if (cat_left + 1 == DISPLAY_WIDTH - CAT_WIDTH && dir_x) begin
                    dir_x <= 0;
                end
                if (cat_top - 1 == 0 && !dir_y) begin
                    dir_y <= 1;
                end
                if (cat_top + 1 == DISPLAY_HEIGHT - CAT_HEIGHT && dir_y) begin
                    dir_y <= 0;
                end
            end
        end
    end
    

endmodule
