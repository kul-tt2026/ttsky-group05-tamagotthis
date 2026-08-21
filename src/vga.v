/*
* The VGA module handles what is shown on the VGA screen.
* Note: since different states require different outputs on the screen, it's probably best to create state specific modules and use them in this high-level module.
* Note: use hvsync_generator.v for the timing.
*/

// gebaseerd op vga playground (https://vga-playground.com/?preset=logo) en nyan cat repo (https://github.com/a1k0n/tt08-nyan/blob/main/src/tt_um_a1k0n_nyancat.v)
// it's not such a mess anymore but now it doesn't work...

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

    parameter MEM_HEART_WIDTH = 15;                                         // Width of the heart in heart.hex
    parameter MEM_HEART_HEIGHT = 14;                                        // Height of the heart in heart.hex

    parameter CAT_STRETCH_EXP = 1;                                          // 0 = no stretching (i.e. stretch factor 1), 1 = stretch factor 2, 2 = stretch factor 4
    localparam CAT_STRETCH_FACTOR = 1 << CAT_STRETCH_EXP;                   // Calculate the stretch factor based on the exponent

    localparam CAT_WIDTH = MEM_CAT_WIDTH * CAT_STRETCH_FACTOR;              // Width of the cat after stretching
    localparam CAT_HEIGHT = MEM_CAT_HEIGHT * CAT_STRETCH_FACTOR;            // Height of the cat after stretching

    localparam HEART_WIDTH = 2*MEM_HEART_WIDTH;                             // Heart has stretch factor 2
    localparam HEART_HEIGHT = 2*MEM_HEART_HEIGHT;


    // ------------------------------------------------------------------------------------------------------------------------------
    // ------------------------------------------------ Heart logic -----------------------------------------------------------------
    // ------------------------------------------------------------------------------------------------------------------------------

    wire [1:0] h_pixel_value;
    wire [5:0] h_color;

    reg [1:0] heart[0:MEM_HEART_WIDTH*MEM_HEART_HEIGHT-1];                  // currently 15*14 = 210 pixels --> 8 bit addresses
    initial begin
        $readmemh("../src/data/hart.hex", heart);
    end

    palette_heart h_palette (
    .color_index(h_pixel_value),
    .rrggbb(h_color)
    );

    reg [9:0] h1_l = 10'd600;                                               // static position of the 1st heart                   
    reg [9:0] h1_t = 10'd10;

    wire [9:0] x_h = pix_x - h1_l;                                          
    wire [9:0] y_h = pix_y - h1_t;
    wire heart_pixels = (x_h[9:5] == 0 && x_h[4:0] < (HEART_WIDTH << 1) && y_h[9:5] == 0 && y_h[4:0] < (HEART_HEIGHT << 1));        // << 1 is the same as * 2

    wire [7:0] heart_addr = ({3'b0,y_h[4:0]} >> 1) * MEM_HEART_WIDTH + ({3'b0, x_h[4:0]} >> 1);                                     // >> 1 is the same as / 2
    
    assign h_pixel_value = heart[heart_addr];


    // ------------------------------------------------------------------------------------------------------------------------------
    // ------------------------------------------------ Cat logic -------------------------------------------------------------------
    // ------------------------------------------------------------------------------------------------------------------------------

    wire [1:0] c_pixel_value;
    wire [5:0] c_color;

    reg [1:0] cat[0:MEM_CAT_WIDTH*MEM_CAT_HEIGHT-1];                        // currently 23*25 = 575 pixels --> 10 bit addresses
    initial begin
        $readmemh("../src/data/kat.hex", cat);
    end

    palette_cat c_palette (
    .color_index(c_pixel_value),
    .rrggbb(c_color)
    );

    reg [9:0] cat_left, cat_top;                                            // position of the cat decided by bouncing logic

    wire [9:0] x_c = pix_x - cat_left;
    wire [9:0] y_c = pix_y - cat_top;
    wire cat_pixels = (x_c[9:6] == 0 && x_c[5:0] < (MEM_CAT_WIDTH << CAT_STRETCH_EXP) && y_c[9:6] == 0 && y_c[5:0] < (MEM_CAT_HEIGHT << CAT_STRETCH_EXP));
        // should be fine for stretch factor <= 2, for higher stretch factors, change x[9:6] to x[9:7] etc... (ook bij addr berekening hieronder)

    // addr = (y / stretch_factor) * MEM_CAT_WIDTH + (x / strech_factor) 
    // delen door strech factor (2^CAT_STRETCH_EXP) door te shiften naar rechts met CAT_STRETCH_EXP
    wire [9:0] cat_addr = ({4'b0,y_c[5:0]} >> CAT_STRETCH_EXP) * MEM_CAT_WIDTH + {4'b0, x_c[5:0]} >> CAT_STRETCH_EXP; 

    assign c_pixel_value = cat[cat_addr];


    // ------------------------------------------------ Cat bouncing logic -------------------------------------------------------------------

    reg dir_x, dir_y;
    reg [9:0] prev_y;

    always @(posedge clk) begin
        if (~rst_n) begin
            cat_left <= 200;
            cat_top <= 200;
            dir_y <= 0;
            dir_x <= 1;
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


    // ------------------------------------------------------------------------------------------------------------------------------
    // ------------------------------------------------ RBG output logic ------------------------------------------------------------
    // ------------------------------------------------------------------------------------------------------------------------------

    always @(posedge clk) begin
        if (~rst_n) begin
            R <= 0;
            G <= 0;
            B <= 0;
        end else begin
            R <= 2'b10;                                                     // default output is background c_: light purple
            G <= 2'b10;
            B <= 2'b11;
            if (video_active) begin
                if (cat_pixels) begin
                    R <= c_color[5:4];
                    G <= c_color[3:2];
                    B <= c_color[1:0];
                end else if (heart_pixels) begin
                    R <= h_color[5:4];
                    G <= h_color[3:2];
                    B <= h_color[1:0];
                end
            end
        end

    end



    // ------------------------------------------------------------------------------------------------------------------------------
    // ------------------------------------------------ hvsync generator ------------------------------------------------------------
    // ------------------------------------------------------------------------------------------------------------------------------
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

    assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};
    

endmodule
