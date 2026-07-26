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
    output [1:0] R, G, B                                                    // VGA color signals, going to the VGA PMOD.
);

endmodule
