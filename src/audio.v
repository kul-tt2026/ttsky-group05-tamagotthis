/*
 * The audio module handles the audio output for the Tamagotchi.
 * It generates sounds based on signals it receives from the main_controller.
 */
module audio (
    input rst_n, clk,                   // Global active-low reset and clock.              
    input fish_caught,                  // Signals that a fish has been caught.
    input play_bang,                    // Prompts a bang sound when the cat is spawned.
    input play_default,                 // Prompts a default sound when the cat is in its default state.
    input play_sleeping,                // Prompts a sleeping sound when the cat is sleeping.
    input play_playing,           // Prompts a playing sound when the cat is playing, e.g. every time the cat catches the ball.
    input play_dead,                    // Prompts a sound when the cat dies.
    output audio_out                    // Audio output signal that goes to the audio PMOD.
);

endmodule