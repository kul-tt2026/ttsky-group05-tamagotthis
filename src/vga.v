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
    input reg [9:0] cat_pos_x, fish_pos_x,                                  // The x-positions of the cat and fish.
    input reg [9:0] cat_pos_y, fish_pos_y,                                  // The y-positionsof the cat and fish.
    input is_sleeping, is_playing, is_eating, is_dead, show_bang,           // Signals to determine what has to be shown on the VGA.
    input reg [2:0] battery_left,                                           // Necessary to display the correct battery icon
    input reg [3:0] lives_left,                                             // Necessary to display the correct number of hearts
    output hsync, vsync,                                                    // VGA horizontal and vertical sync signals, going the the VGA PMOD.
    output reg [1:0] R, G, B,                                               // VGA color signals, going to the VGA PMOD.
    output [7:0] uo_out                                                     // ONLY FOR TESTING PURPOSES, needed for vga test, to remove in final version
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

    wire [1:0] heart_pixel_value;                                           // Color palette index for the current pixel.
    wire [5:0] heart_color;                                                 // Resulting color for the current pixel.
    // reg [3:0] hearts_on_screen;                                          // for testing
    localparam MAX_HEARTS = 9;                                              // maximum number of hearts

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
            for (heart_index = 0; heart_index < MAX_HEARTS; heart_index = heart_index + 1) begin                        // heart_index < lives_left not ok cause lives_left is not constant
                if (heart_index < lives_left && pix_x >= heart_left(heart_index) && pix_x < heart_left(heart_index) + HEART_WIDTH) begin
                // if (heart_index < hearts_on_screen && pix_x >= heart_left(heart_index) && pix_x < heart_left(heart_index) + HEART_WIDTH) begin       // for testing
                    heart_pixels = 1'b1;
                    heart_x = pix_x - heart_left(heart_index);
                end
            end
        end
    end

    wire [7:0] heart_addr = heart_y * MEM_HEART_WIDTH + heart_x;
    
    assign heart_pixel_value = heart[heart_addr];


    // ------------------------------------------------------------------------------------------------------------------------------
    // ------------------------------------------------ Battery logic ---------------------------------------------------------------
    // ------------------------------------------------------------------------------------------------------------------------------

    localparam MEM_BATTERY_WIDTH = 16;                                      // Width of the battery in batt_multicolor.hex
    localparam MEM_BATTERY_HEIGHT = 9;                                      // Height of the battery in batt_multicolor.hex

    localparam BATTERY_STRETCH_EXP = 1;
    localparam BATTERY_STRETCH_FACTOR = 1 << BATTERY_STRETCH_EXP;

    localparam BATTERY_WIDTH = MEM_BATTERY_WIDTH * BATTERY_STRETCH_FACTOR;                           
    localparam BATTERY_HEIGHT = MEM_BATTERY_HEIGHT * BATTERY_STRETCH_FACTOR;           

    localparam BATTERY_TOP = 10'd5;
    localparam BATTERY_LEFT = 10'd603;

    // reg [2:0] battery_level;                                              // for testing
    wire [2:0] batt_pixel_value;
    wire [5:0] batt_color;

    reg [2:0] battery[0:MEM_BATTERY_WIDTH*MEM_BATTERY_HEIGHT-1];                    // currently 16*10 = 160 pixels --> 8 bit addresses
    initial begin
        $readmemh("../src/data/battery.hex", battery);
    end

    palette_battery batt_palette (
        .battery_level(battery_left),
        .color_index(batt_pixel_value),
        .rrggbb(batt_color)
    );

    //     palette_battery batt_palette (                                          // for testing
    //     .battery_level(battery_level),
    //     .color_index(batt_pixel_value),
    //     .rrggbb(batt_color)
    // );

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
    wire [5:0] default_cat_color;

    reg [1:0] cat[0:MEM_CAT_WIDTH*MEM_CAT_HEIGHT-1];                        // currently 23*25 = 575 pixels --> 10 bit addresses
    initial begin
        $readmemh("../src/data/kat.hex", cat);
    end

    palette_cat cat_palette (
        .color_index(cat_pixel_value),
        .rrggbb(default_cat_color)
    );

    wire [9:0] cat_x = pix_x - cat_pos_x;
    wire [9:0] cat_y = pix_y - cat_pos_y;
    wire default_cat_pixels = cat_x < CAT_WIDTH && cat_y < CAT_HEIGHT;
        // should be fine for stretch factor <= 2, for higher stretch factors, change x[9:6] to x[9:7] etc... (ook bij addr berekening hieronder)

    // addr = (y / stretch_factor) * MEM_CAT_WIDTH + (x / strech_factor) 
    // delen door strech factor (2^CAT_STRETCH_EXP) door te shiften naar rechts met CAT_STRETCH_EXP
    wire [9:0] cat_addr = (cat_y >> CAT_STRETCH_EXP) * MEM_CAT_WIDTH + (cat_x >> CAT_STRETCH_EXP); 

    assign cat_pixel_value = cat[cat_addr];


    // ------------------------------------------------- Changeable eyes ------------------------------------------------------------

    localparam MEM_EYE_WIDTH = 4;                                          // Width of one cat eye in cat_sleep_eye.hex or cat_dead_eye.hex
    localparam MEM_EYE_HEIGHT = 4;                                         // Height of one cat eye in cat_sleep_eye.hex or cat_dead_eye.hex

    localparam EYE_WIDTH = MEM_EYE_WIDTH * CAT_STRETCH_FACTOR;
    localparam EYE_HEIGHT = MEM_EYE_HEIGHT * CAT_STRETCH_FACTOR;

    wire dead_eye_pixel_value, sleep_eye_pixel_value, eye_pixel_value;
    wire [5:0] eye_color;

    wire is_left_eye = cat_x >= 5 & cat_x <= 8 & cat_y >= 6 & cat_y <= 9;
    wire is_right_eye = cat_x >= 14 & cat_x <= 17 & cat_y >= 6 & cat_y <= 9;
    wire is_eye = is_left_eye | is_right_eye;

    wire [9:0] eye_x = is_left_eye ? cat_x - 5 : cat_x - 14;
    wire [9:0] eye_y = cat_y - 6;

    reg dead_eye[0:MEM_EYE_WIDTH*MEM_EYE_HEIGHT-1];
    reg sleep_eye[0:MEM_EYE_WIDTH*MEM_EYE_HEIGHT-1];
    initial begin
        $readmemh("../src/data/cat_dead_eye.hex", dead_eye);
        $readmemh("../src/data/cat_sleep_eye.hex", sleep_eye);
    end

    wire [9:0] eye_addr = (eye_y >> CAT_STRETCH_EXP) * MEM_EYE_WIDTH + (eye_x >> CAT_STRETCH_EXP); 
    assign dead_eye_pixel_value = dead_eye[eye_addr];
    assign sleep_eye_pixel_value = sleep_eye[eye_addr];
    assign eye_pixel_value = is_dead ? dead_eye_pixel_value : sleep_eye_pixel_value;

    palette_eyes eyes_palette (
        .color_index(eye_pixel_value),
        .rrggbb(eye_color)
    );


    // ------------------------------------------------- Changeable ears ------------------------------------------------------------

    localparam MEM_EAR_WIDTH = 5;                                          // Width of one cat ear in cat_raised_ear.hex
    localparam MEM_EAR_HEIGHT = 8;                                         // Height of one cat ear in cat_raised_ear.hex

    localparam EAR_WIDTH = MEM_EAR_WIDTH * CAT_STRETCH_FACTOR;
    localparam EAR_HEIGHT = MEM_EAR_HEIGHT * CAT_STRETCH_FACTOR;

    wire [1:0] raised_ear_pixel_value;
    wire [5:0] raised_ear_color;

    wire is_raised_ear_left = cat_x >= 0 & cat_x <= 4 & (cat_y >= 0 || cat_y == -1) & cat_y <= 6;
    wire is_raised_ear_right = cat_x >= 18 & cat_x <= 22 & (cat_y >= 0 || cat_y == -1) & cat_y <= 6;
    wire is_raised_ear = is_raised_ear_left | is_raised_ear_right;

    wire [9:0] ear_x = is_raised_ear_left ? cat_x : MEM_EAR_WIDTH - (cat_x - 18) + 1; // Right ear should be mirrorred.
    wire [9:0] ear_y = cat_y + 1;

    reg [1:0] raised_ear[0:MEM_EYE_WIDTH*MEM_EYE_HEIGHT-1];
    initial begin
        $readmemh("../src/data/cat_raised_ear.hex", raised_ear);
    end

    wire [9:0] ear_addr = (ear_y >> CAT_STRETCH_EXP) * MEM_EAR_WIDTH + (ear_x >> CAT_STRETCH_EXP); 
    assign raised_ear_pixel_value = raised_ear[ear_addr];

    // The ears use the same color as the cat.
    palette_cat ears_palette (
        .color_index(raised_ear_pixel_value),
        .rrggbb(raised_ear_color)
    );

    
    // ----------------------------------------------- Combine into one cat ---------------------------------------------------------

    reg [5:0] cat_color;
    always @(*) begin
        // If there is a reason to change the ears, change them.
        // If there is a reason to show 'zzzz', do it.
        if ((is_dead | is_sleeping) & is_eye) begin
            // If there is a reason to change the eyes, change them.
            cat_color = eye_color;
        end else if (is_raised_ear_left) begin
            // If there is a reason to change the ears, change them.
            cat_color = raised_ear_color;
        end else begin
            // Default behavior is to show the default cat.
            cat_color = default_cat_color;
        end
    end
    wire cat_pixels = default_cat_pixels | is_raised_ear_left;

    // ------------------------------------------------------------------------------------------------------------------------------
    // ------------------------------------------------ zzz logic -------------------------------------------------------------------
    // ------------------------------------------------------------------------------------------------------------------------------

    localparam FIRST_Z_X_OFFSET = 32;
    localparam FIRST_Z_Y_OFFSET = -8;
    localparam Z_COUNT = 4;
    localparam INTER_Z_X_OFFSET = 4;
    localparam INTER_Z_Y_OFFSET = 5;
    
    localparam MEM_Z_WIDTH = 4;                                          // Width of the 'z' glyph in z.hex
    localparam MEM_Z_HEIGHT = 5;                                         // Height of the 'z' glyph in z.hex

    localparam Z_STRETCH_EXP = 1;                                         // 0 = no stretching (i.e. stretch factor 1), 1 = stretch factor 2, 2 = stretch factor 4
    localparam Z_STRETCH_FACTOR = 1 << Z_STRETCH_EXP;                   // Calculate the stretch factor based on the exponent

    localparam Z_WIDTH = MEM_Z_WIDTH * Z_STRETCH_FACTOR;
    localparam Z_HEIGHT = MEM_Z_HEIGHT * Z_STRETCH_FACTOR;

    wire z_pixel_value;
    wire [5:0] z_color;

    reg z_registers[0:MEM_Z_WIDTH*MEM_Z_HEIGHT-1];                          // currently 23*25 = 575 pixels --> 10 bit addresses
    initial begin
        $readmemh("../src/data/z.hex", z_registers);
    end

    palette_z z_palette (
        .color_index(z_pixel_value),
        .rrggbb(z_color)
    );

    wire is_z_array[0:Z_COUNT-1];                                           // bit i stores if the current pixel is part of the i'th Z.
    wire is_z_concat[0:Z_COUNT-1];
    wire [9:0] z_x_array[0:Z_COUNT-1];
    wire [9:0] z_y_array[0:Z_COUNT-1];
    genvar i;
    generate
        for (i = 0; i < Z_COUNT; i = i + 1) begin : gen_z_loop
            assign is_z_array[i] = cat_x >= FIRST_Z_X_OFFSET + INTER_Z_X_OFFSET * i
                                    & cat_x <= FIRST_Z_X_OFFSET + INTER_Z_X_OFFSET * i + Z_WIDTH
                                    & cat_y >= FIRST_Z_Y_OFFSET + INTER_Z_Y_OFFSET * i
                                    & cat_y <= FIRST_Z_Y_OFFSET + INTER_Z_Y_OFFSET * i + Z_HEIGHT;
            
            assign is_z_concat[i] = i == 0 ? is_z_array[i] : is_z_array[i] | is_z_concat[i-1];

            assign z_x_array[i] = is_z_array[i] ? cat_x - (FIRST_Z_X_OFFSET + INTER_Z_X_OFFSET * i) : (i == 0 ? 9'b0 : z_x_array[i-1]);
            assign z_y_array[i] = is_z_array[i] ?  cat_y - (FIRST_Z_Y_OFFSET + INTER_Z_Y_OFFSET * i) : (i == 0 ? 9'b0 : z_y_array[i-1]);
        end
    endgenerate


    wire [9:0] z_x = z_x_array[Z_COUNT-1];
    wire [9:0] z_y = z_y_array[Z_COUNT-1];
    wire z_pixels = is_z_concat[Z_COUNT-1]; // Is this pixel in any 'z' glyph?
    
    wire [9:0] z_addr = (z_y >> Z_STRETCH_EXP) * MEM_Z_WIDTH + (z_x >> Z_STRETCH_EXP); 

    assign z_pixel_value = z_registers[z_addr];


    // ------------------------------------------------ Bouncing cat logic ----------------------------------------------------------

    // probably in playing state

    // reg dir_x, dir_y;
    // reg [9:0] prev_y;

    // always @(posedge clk) begin
    //     if (~rst_n) begin
    //         cat_left <= 200;
    //         cat_top <= 200;
    //         dir_y <= 0;
    //         dir_x <= 1;
    //     end else begin
    //         prev_y <= pix_y;
    //         if (pix_y == 0 && prev_y != pix_y) begin
    //             cat_left <= cat_left + (dir_x ? 1 : -1);
    //             cat_top  <= cat_top + (dir_y ? 1 : -1);
    //             if (cat_left - 1 == 0 && !dir_x) begin
    //                 dir_x <= 1;
    //             end
    //             if (cat_left + 1 == DISPLAY_WIDTH - CAT_WIDTH && dir_x) begin
    //                 dir_x <= 0;
    //             end
    //             if (cat_top - 1 == 0 && !dir_y) begin
    //                 dir_y <= 1;
    //             end
    //             if (cat_top + 1 == DISPLAY_HEIGHT - CAT_HEIGHT && dir_y) begin
    //                 dir_y <= 0;
    //             end
    //         end
    //     end
    // end

    // ------------------------------------------------ Walking cat logic -----------------------------------------------------------

    // used in default state
    /*
    reg first_frame = 1;

    reg dir_x, dir_y;
    reg [9:0] prev_y;

    localparam CAT_LEFT_BOUNDARY = 150 ;
    localparam CAT_RIGHT_BOUNDARY = 444;

    localparam CAT_HOR_STEP = 10;
    localparam CAT_VER_STEP = 1;

    always @(posedge clk) begin
        if (~rst_n) begin
            cat_left <= 350;
            cat_top <= 300;
            dir_x <= 1;
            dir_y <= 0;
            prev_y <= 0;
            // battery_level <= 7;          // for testing
            // hearts_on_screen <= 9;
        end else begin

            prev_y <= pix_y;
            // pix_y tracks which horizontal line is being drawn, goes from 479 to 0 at the beginning of a new frame
            // stays 0 for the 640 pixels of the first horizontal line --> check if previous was zero
            if (pix_y == 0 && prev_y != pix_y) begin

                // for testing
                // if (first_frame) begin                                                          // to prevent having 8 hearts and battery level 6/7 in the first frame
                //     first_frame <= 0;                                                           
                // end else begin 
                //     battery_level <= (battery_level == 0) ? 0 : battery_level - 1;              // batterij testen
                //     hearts_on_screen <= (hearts_on_screen == 0) ? 0 : hearts_on_screen - 1;     // hartjes testen
                // end 

                if (cat_left + CAT_HOR_STEP >= CAT_RIGHT_BOUNDARY - CAT_WIDTH && dir_x) begin
                    dir_x <= 0;
                end else if (cat_left - CAT_HOR_STEP <= CAT_LEFT_BOUNDARY && !dir_x) begin
                    dir_x <= 1;
                end

                dir_y <= !dir_y;
                cat_left <= cat_left + (dir_x ? CAT_HOR_STEP : -CAT_HOR_STEP);
                cat_top  <= cat_top + (dir_y ? CAT_VER_STEP : -CAT_VER_STEP);
            end
        end
    end
    */

    // ------------------------------------------------------------------------------------------------------------------------------
    // ------------------------------------------------ RBG output logic ------------------------------------------------------------
    // ------------------------------------------------------------------------------------------------------------------------------

    wire [5:0] BACKGROUND_COLOR= 6'b101011;
    always @(posedge clk) begin
        if (~rst_n) begin
            R <= 0;
            G <= 0;
            B <= 0;
        end else begin
            R <= BACKGROUND_COLOR[5:4];                                                     // default output is background c_: light purple
            G <= BACKGROUND_COLOR[3:2];
            B <= BACKGROUND_COLOR[1:0];
            if (video_active) begin
                // The order of the if statements defines the rendering order.
                // By checking if an appropriate color is not the background color, we do not get rectangles in the background color cutting through items in lower rendering layers.
                if (heart_pixels & heart_color != BACKGROUND_COLOR) begin
                    R <= heart_color[5:4];
                    G <= heart_color[3:2];
                    B <= heart_color[1:0];
                end else if (batt_pixels) begin // Rectangular sprite, should not have any transparent components.
                    R <= batt_color[5:4];
                    G <= batt_color[3:2];
                    B <= batt_color[1:0];
                end else if (z_pixels & is_sleeping & z_color != BACKGROUND_COLOR) begin
                    R <= z_color[5:4];
                    G <= z_color[3:2];
                    B <= z_color[1:0];
                end else if (cat_pixels & cat_color != BACKGROUND_COLOR) begin
                    R <= cat_color[5:4];
                    G <= cat_color[3:2];
                    B <= cat_color[1:0];
                end else if (fish_pixels && is_eating & fish_color != BACKGROUND_COLOR) begin
                    R <= fish_color[5:4];
                    G <= fish_color[3:2];
                    B <= fish_color[1:0];
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