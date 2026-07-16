/*
 * The main controller of the tamagotchi manages input signals, battery levels, etc., and connects with other modules like the minigame and VGA.
 * Features:
 *  - resetting the controller: the cat respawns with a bang, with full battery and 9 lives, in the default state.
 *  - left, right, up and down move the cat.
 *  - X, Y, A and B for going to 'play', 'sleep', 'eat' and 'default' state respectively
 *      Note: can the cat go from one state directly to the next? does it always have to go to default first? does it matter?
 *  - If the controller gets a deplete_battery signal from the timer, it should deplete its battery levels by one, if the battery reaches zero, a heart is lost.
 *  - If all hearts are gone, the cat dies. It respawns with a bang.
 *  - If a fish is caught, the cat plays or the cat sleeps, the battery increases again.
 */
module main_controller (
    input rst_n, clk,                                       // Global active-low reset and clock.
    input left, right, up, down, A, B, X, Y,                // Inputs from the Controller pmod.
    input deplete_battery,                                  // Signals that the battery has to drop one level.
    input fish_caught,                                      // Signals that a fish has been caught.
    output [9:0] cat_pos_x,                                 // The x-position of the cat.
    output [9:0] cat_pos_y,                                 // The y-position of the cat.
    output [3:0] lives_left,                                // The number of lives the cat has left, to be shown on the VGA.
    output [3:0] battery_left,                              // The number of battery bars the cat has left, to be shown on the VGA.
    output battery_almost_empty,                            // Signals that the battery is almost empty.
    output is_eating,                                       // Signals that the food minigame is currently active.
    output show_bang, is_dead, is_sleeping, is_playing,     // Signals to the VGA about extra stuff to render and to the timer to affect the battery.
    output is_default_state,                                // Signals to the VGA that the cat is in the default state.
    output play_bang, play_default, play_dead,              // Signals to the audio which sound needs to be played.
    output play_playing, play_sleeping                      // Signals to the audio which sound needs to be played.
);

endmodule
