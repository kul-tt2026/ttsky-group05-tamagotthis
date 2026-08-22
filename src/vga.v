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

    localparam DISPLAY_WIDTH = 640;                                         // VGA display width
    localparam DISPLAY_HEIGHT = 480;                                        // VGA display height


    // ------------------------------------------------------------------------------------------------------------------------------
    // ------------------------------------------------ Heart logic -----------------------------------------------------------------
    // ------------------------------------------------------------------------------------------------------------------------------

    localparam MEM_HEART_WIDTH = 15;                                        // Width of the heart in heart.hex
    localparam MEM_HEART_HEIGHT = 14;                                       // Height of the heart in heart.hex

    localparam HEART_WIDTH = MEM_HEART_WIDTH;                               // No stretch factor
    localparam HEART_HEIGHT = MEM_HEART_HEIGHT;

    wire [1:0] heart_pixel_value;
    wire [5:0] heart_color;
    reg [3:0] hearts_on_screen = 4'd9;                                      // number of hearts to be shown on the screen

    reg [1:0] heart[0:MEM_HEART_WIDTH*MEM_HEART_HEIGHT-1];                  // currently 15*14 = 210 pixels --> 8 bit addresses
    initial begin
        $readmemh("../src/data/hart.hex", heart);
    end

    palette_heart heart_palette (
    .color_index(heart_pixel_value),
    .rrggbb(heart_color)
    );

    localparam [9:0] HEART_TOP = 10'd5;
    localparam [9:0] HEART_LEFT0 = 10'd5;
    localparam [9:0] HEART_LEFT1 = 10'd22;
    localparam [9:0] HEART_LEFT2 = 10'd39;
    localparam [9:0] HEART_LEFT3 = 10'd56;
    localparam [9:0] HEART_LEFT4 = 10'd73;
    localparam [9:0] HEART_LEFT5 = 10'd90;
    localparam [9:0] HEART_LEFT6 = 10'd107;
    localparam [9:0] HEART_LEFT7 = 10'd124;
    localparam [9:0] HEART_LEFT8 = 10'd141;

    reg [9:0] heart_x;
    reg heart_pixels;
    integer heart_index;
    wire [9:0] heart_y = pix_y - HEART_TOP;

    function [9:0] heart_left;
        input integer index;
        begin
            case (index)
                0: heart_left = HEART_LEFT0;
                1: heart_left = HEART_LEFT1;
                2: heart_left = HEART_LEFT2;
                3: heart_left = HEART_LEFT3;
                4: heart_left = HEART_LEFT4;
                5: heart_left = HEART_LEFT5;
                6: heart_left = HEART_LEFT6;
                7: heart_left = HEART_LEFT7;
                8: heart_left = HEART_LEFT8;
                default: heart_left = HEART_LEFT8;
            endcase
        end
    endfunction

    always @(*) begin
        heart_pixels = 1'b0;
        heart_x = 10'd0;
        if (pix_y >= HEART_TOP && pix_y < HEART_TOP + HEART_HEIGHT) begin
            for (heart_index = 0; heart_index < hearts_on_screen; heart_index = heart_index + 1) begin
                if (pix_x >= heart_left(heart_index) && pix_x < heart_left(heart_index) + HEART_WIDTH) begin
                    heart_pixels = 1'b1;
                    heart_x = pix_x - heart_left(heart_index);
                end
            end
        end
    end

    wire [7:0] heart_addr = heart_y * MEM_HEART_WIDTH + heart_x;
    
    assign heart_pixel_value = heart[heart_addr];

    always @(posedge is_dead) begin
       hearts_on_screen <= hearts_on_screen - 1;
       // battery_level <= 3'd7;
    end


    // ------------------------------------------------------------------------------------------------------------------------------
    // ------------------------------------------------ Battery logic ---------------------------------------------------------------
    // ------------------------------------------------------------------------------------------------------------------------------

    localparam MEM_BATTERY_WIDTH = 16;                                      // Width of the battery in batt_multicolor.hex
    localparam MEM_BATTERY_HEIGHT = 9;                                     // Height of the battery in batt_multicolor.hex

    localparam BATTERY_STRETCH_EXP = 1;
    localparam BATTERY_STRETCH_FACTOR = 1 << BATTERY_STRETCH_EXP;

    localparam BATTERY_WIDTH = MEM_BATTERY_WIDTH * BATTERY_STRETCH_FACTOR;                           
    localparam BATTERY_HEIGHT = MEM_BATTERY_HEIGHT * BATTERY_STRETCH_FACTOR;

    // decrease battery signaal uit timer nodig
    // + increase battery signaal uit main_controller!
    // batterij resetten als kat doodgaat

    // reg [2:0] battery_level = 3'd7; // 3 bits for battery level (0-7)

    localparam BATTERY_TOP = 10'd5;
    localparam BATTERY_LEFT = 10'd603;

    wire [1:0] batt_pixel_value;
    wire [5:0] batt_color;

    reg [1:0] battery[0:MEM_BATTERY_WIDTH*MEM_BATTERY_HEIGHT-1];                    // currently 16*10 = 160 pixels --> 8 bit addresses
    initial begin
        $readmemh("../src/data/batt_mul_flipped", battery);
    end

    palette_battery batt_palette (
    .color_index(batt_pixel_value),
    .rrggbb(batt_color)
    );

    wire [9:0] batt_x = pix_x - BATTERY_LEFT;                                          
    wire [9:0] batt_y = pix_y - BATTERY_TOP;
    wire batt_pixels = (batt_x < (BATTERY_WIDTH) && batt_y < (BATTERY_HEIGHT));

    wire [7:0] batt_addr = (batt_y >> BATTERY_STRETCH_EXP) * MEM_BATTERY_WIDTH + (batt_x >> BATTERY_STRETCH_EXP);
    
    assign batt_pixel_value = battery[batt_addr];


    // ------------------------------------------------------------------------------------------------------------------------------
    // ------------------------------------------------ Fish logic ------------------------------------------------------------------
    // ------------------------------------------------------------------------------------------------------------------------------

    localparam MEM_FISH_WIDTH = 16;                                         // Width of the fish in fish.hex
    localparam MEM_FISH_HEIGHT = 10;                                        // Height of the fish in fish.hex

    localparam FISH_STRETCH_EXP = 1;
    localparam FISH_STRETCH_FACTOR = 1 << FISH_STRETCH_EXP;

    localparam FISH_WIDTH = MEM_FISH_WIDTH * FISH_STRETCH_FACTOR;                           
    localparam FISH_HEIGHT = MEM_FISH_HEIGHT * FISH_STRETCH_FACTOR;

    // fish position determined by input
    
    wire [1:0] fish_pixel_value;
    wire [5:0] fish_color;

    reg [1:0] fish[0:MEM_FISH_WIDTH*MEM_FISH_HEIGHT-1];                    // currently 16*10 = 160 pixels --> 8 bit addresses
    initial begin
        $readmemh("../src/data/vis.hex", fish);
    end

    palette_fish fish_palette (
    .color_index(fish_pixel_value),
    .rrggbb(fish_color)
    );

    wire [9:0] fish_x = pix_x - fish_pos_x;                                          
    wire [9:0] fish_y = pix_y - fish_pos_y;
    wire fish_pixels = (fish_x < (FISH_WIDTH) && fish_y < (FISH_HEIGHT));

    wire [7:0] fish_addr = (fish_y >> FISH_STRETCH_EXP) * MEM_FISH_WIDTH + (fish_x >> FISH_STRETCH_EXP);
    
    assign fish_pixel_value = fish[fish_addr];

    // ------------------------------------------------------------------------------------------------------------------------------
    // ------------------------------------------------ Cat logic -------------------------------------------------------------------
    // ------------------------------------------------------------------------------------------------------------------------------

    localparam MEM_CAT_WIDTH = 23;                                          // Width of the cat in kat.hex
    localparam MEM_CAT_HEIGHT = 25;                                         // Height of the cat in kat.hex

    localparam CAT_STRETCH_EXP = 1;                                         // 0 = no stretching (i.e. stretch factor 1), 1 = stretch factor 2, 2 = stretch factor 4
    localparam CAT_STRETCH_FACTOR = 1 << CAT_STRETCH_EXP;                   // Calculate the stretch factor based on the exponent

    localparam CAT_WIDTH = MEM_CAT_WIDTH * CAT_STRETCH_FACTOR;              // Width of the cat after stretching
    localparam CAT_HEIGHT = MEM_CAT_HEIGHT * CAT_STRETCH_FACTOR;            // Height of the cat after stretching

    wire [1:0] cat_pixel_value;
    wire [5:0] cat_color;

    reg [1:0] cat[0:MEM_CAT_WIDTH*MEM_CAT_HEIGHT-1];                        // currently 23*25 = 575 pixels --> 10 bit addresses
    initial begin
        $readmemh("../src/data/kat.hex", cat);
    end

    palette_cat cat_palette (
    .color_index(cat_pixel_value),
    .rrggbb(cat_color)
    );

    reg [9:0] cat_left, cat_top;                                            // position of the cat decided by bouncing logic

    wire [9:0] cat_x = pix_x - cat_left;
    wire [9:0] cat_y = pix_y - cat_top;
    wire cat_pixels = cat_x < CAT_WIDTH && cat_y < CAT_HEIGHT;
        // should be fine for stretch factor <= 2, for higher stretch factors, change x[9:6] to x[9:7] etc... (ook bij addr berekening hieronder)

    // addr = (y / stretch_factor) * MEM_CAT_WIDTH + (x / strech_factor) 
    // delen door strech factor (2^CAT_STRETCH_EXP) door te shiften naar rechts met CAT_STRETCH_EXP
    wire [9:0] cat_addr = (cat_y >> CAT_STRETCH_EXP) * MEM_CAT_WIDTH + (cat_x >> CAT_STRETCH_EXP); 

    assign cat_pixel_value = cat[cat_addr];


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
                    R <= cat_color[5:4];
                    G <= cat_color[3:2];
                    B <= cat_color[1:0];
                end else if (heart_pixels) begin
                    R <= heart_color[5:4];
                    G <= heart_color[3:2];
                    B <= heart_color[1:0];
                end else if (fish_pixels) begin
                    R <= fish_color[5:4];
                    G <= fish_color[3:2];
                    B <= fish_color[1:0];
                end else if (batt_pixels) begin
                    R <= batt_color[5:4];
                    G <= batt_color[3:2];
                    B <= batt_color[1:0];
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
