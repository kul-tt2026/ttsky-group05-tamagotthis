/*
 * The minigame module handles the food minigame.
 * It determines the position of the fish and checks if the cat has caught it.
 */
module minigame (
    input rst_n, clk,               // Global active-low reset and clock.
    input is_eating,                // Signals that the food minigame is currently active.
    input [9:0] cat_pos_x,          // The x-position of the cat.
    input [9:0] cat_pos_y,          // The y-position of the cat. 
    output [9:0] fish_pos_x,        // The x-position of the fish.
    output [9:0] fish_pos_y,        // The y-position of the fish.
    output fish_caught              // Signals that a fish has been caught.
);

endmodule