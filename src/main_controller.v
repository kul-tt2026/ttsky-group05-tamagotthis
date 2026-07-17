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
    output reg [9:0] cat_pos_x,                             // The x-position of the cat.
    output reg [9:0] cat_pos_y,                             // The y-position of the cat.
    output reg [3:0] lives_left,                            // The number of lives the cat has left, to be shown on the VGA.
    output reg [3:0] battery_left,                          // The number of battery bars the cat has left, to be shown on the VGA.
    output battery_almost_empty,                            // Signals that the battery is almost empty.
    output is_eating,                                       // Signals that the food minigame is currently active.
    output show_bang, is_dead, is_sleeping, is_playing,     // Signals to the VGA about extra stuff to render and to the timer to affect the battery.
    output is_default_state,                                // Signals to the VGA that the cat is in the default state.
    output play_bang, play_default, play_dead,              // Signals to the audio which sound needs to be played.
    output play_playing, play_sleeping                      // Signals to the audio which sound needs to be played.
);
    // Parameters:
    // Number of cycles the cat is shown as dead between lives.
    parameter DEAD_CYCLES = 30;
    // Number of cycles the bang is shown.
    parameter RESET_CYCLES = 50;
    // Number of pixels the cat moves over per button press in the eating state.
    parameter STEP_SIZE = 1;
    // Number of cycles before the cat moves again, if the button remains pressed. -1 for 'does not move again unless button is pressed again'.
    parameter STEP_INTERVAL = 10;
    // Number of cycles to sleep before the battery increases.
    parameter SLEEP_TIME = 10;
    // Number of cycles to play before the battery increases.
    parameter PLAY_TIME = 10;
    // Number of fish to catch before the battery increases.
    parameter FISH_TO_CATCH = 3;
    
    // min and max x and y positions for the cat.
    parameter MIN_POS_X = 0;
    parameter MAX_POS_X = 100;
    parameter MIN_POS_Y = 0;
    parameter MAX_POS_Y = 200;
    // The location at which the cat spawns.
    parameter START_POS_X = 50;
    parameter START_POS_Y = 100;

    // Number of bits of the general timer.
    parameter TIMER_BITS = 8;

    // General timer.
    // This timer is used for various events, and moves down. in a constant fashion.
    // Set 'set_timer' to 1 to assign the timer a certain value from 'timer_in'.
    reg [TIMER_BITS-1:0] timer;
    reg set_timer;
    reg [TIMER_BITS-1:0] timer_in;

    always @(posedge clk) begin
        if (set_timer) begin 
            timer <= timer_in;
            // set_timer <= 0;
        end
        else timer <= timer - 1;
    end

    // State machine.
    reg [2:0] State;
    localparam Bang = 3'b000;
    localparam Default = 3'b001;
    localparam Eating = 3'b010;
    localparam Sleeping = 3'b011;
    localparam Playing = 3'b100;
    localparam Dead = 3'b101;
    reg [$clog2(FISH_TO_CATCH+1)-1:0] total_fish_caught;

    reg has_moved_left, has_moved_right, has_moved_up, has_moved_down;
    
    always @(posedge clk) begin

        if (~rst_n) begin
            State <= Bang;
            set_timer <= 1;
            timer_in <= RESET_CYCLES;
        end else begin
            if (deplete_battery && State != Bang && State != Dead) begin
                battery_left <= battery_left - 1;
            end

            case(State)
                Bang: begin
                    if (timer == 0) begin
                        State <= Default;
                        cat_pos_x <= START_POS_X;
                        cat_pos_y <= START_POS_Y;
                        lives_left <= 9;
                        battery_left <= 8;
                    end
                end
                Default: begin
                    if (battery_left == 0) begin
                        State <= Dead;
                        lives_left <= lives_left - 1;
                        set_timer <= 1;
                        timer_in <= DEAD_CYCLES;
                    end else if (X == 1) begin
                        State <= Playing;
                        set_timer <= 1;
                        timer_in <= PLAY_TIME;
                    end else if (Y == 1) begin
                        State <= Sleeping;
                        set_timer <= 1;
                        timer_in <= SLEEP_TIME;
                    end else if (A == 1) begin
                        State <= Eating;
                        total_fish_caught <= FISH_TO_CATCH;
                    end
                end
                Eating: begin
                    if (B == 1) begin
                        State <= Default;
                    end

                    // Move buttons.
                    if (left == 1) begin
                        has_moved_left <= 1;
                        has_moved_right <= 0;
                        if ((timer == 0 || ~has_moved_left) && STEP_INTERVAL > 0) begin
                            set_timer <= 1;
                            timer_in <= STEP_INTERVAL;
                            cat_pos_x <= cat_pos_x > MIN_POS_X + STEP_SIZE ? cat_pos_x - STEP_SIZE : MIN_POS_X;
                        end else if (~has_moved_left && STEP_INTERVAL < 0) begin
                            cat_pos_x <= cat_pos_x > MIN_POS_X + STEP_SIZE ? cat_pos_x - STEP_SIZE : MIN_POS_X;
                        end
                    end else if (right == 1) begin 
                        has_moved_left <= 0;
                        has_moved_right <= 1;
                        if ((timer == 0 || ~has_moved_right) && STEP_INTERVAL > 0) begin
                            set_timer <= 1;
                            timer_in <= STEP_INTERVAL;
                            cat_pos_x <= cat_pos_x < MAX_POS_X - STEP_SIZE ? cat_pos_x + STEP_SIZE : MAX_POS_X;
                        end else if (~has_moved_right && STEP_INTERVAL < 0) begin
                            cat_pos_x <= cat_pos_x < MAX_POS_X - STEP_SIZE ? cat_pos_x + STEP_SIZE : MAX_POS_X;
                        end
                    end else begin
                        has_moved_left <= 0;
                        has_moved_right <= 0;
                    end
                    
                    if (down == 1) begin
                        has_moved_up <= 0;
                        has_moved_down <= 1;
                        if ((timer == 0 || ~has_moved_down) && STEP_INTERVAL > 0) begin
                            set_timer <= 1;
                            timer_in <= STEP_INTERVAL;
                            cat_pos_y <= cat_pos_y < MAX_POS_Y - STEP_SIZE ? cat_pos_y + STEP_SIZE : MAX_POS_Y;
                        end else if (~has_moved_down && STEP_INTERVAL < 0) begin
                            cat_pos_y <= cat_pos_y < MAX_POS_Y - STEP_SIZE ? cat_pos_y + STEP_SIZE : MAX_POS_Y;
                        end
                    end else if (up == 1) begin 
                        has_moved_up <= 1;
                        has_moved_down <= 0;
                        if ((timer == 0 || ~has_moved_up) && STEP_INTERVAL > 0) begin
                            set_timer <= 1;
                            timer_in <= STEP_INTERVAL;
                            cat_pos_y <= cat_pos_y > MIN_POS_Y + STEP_SIZE ? cat_pos_y - STEP_SIZE : MIN_POS_Y;
                        end else if (~has_moved_up && STEP_INTERVAL < 0) begin
                            cat_pos_y <= cat_pos_y > MIN_POS_Y + STEP_SIZE ? cat_pos_y - STEP_SIZE : MIN_POS_Y;
                        end
                    end else begin
                        has_moved_up <= 0;
                        has_moved_down <= 0;
                    end

                    // Fish caught.
                    if (fish_caught) begin
                        total_fish_caught <= total_fish_caught - 1;
                        if (total_fish_caught == 1) begin // Since the previous line is a non-blocking assigment, we have to look at what the value will be, not what it is.
                            State <= Default;
                            battery_left <= battery_left == 8 ? 8 : (battery_left + 1);
                        end
                    end
                end
                Sleeping: begin
                    if (battery_left == 0) begin
                        State <= Dead;
                        lives_left <= lives_left - 1;
                        set_timer <= 1;
                        timer_in <= DEAD_CYCLES;
                    end else if (B == 1) begin
                        State <= Default;
                    end else if (timer == 0) begin
                        battery_left <= battery_left == 8 ? 8 : (battery_left + 1);
                        set_timer <= 1;
                        timer_in <= SLEEP_TIME;
                    end
                end
                Playing: begin
                    if (battery_left == 0) begin
                        State <= Dead;
                        lives_left <= lives_left - 1;
                        set_timer <= 1;
                        timer_in <= DEAD_CYCLES;
                    end else if (B == 1) begin
                        State <= Default;
                    end else if (timer == 0) begin
                        battery_left <= battery_left == 8 ? 8 : (battery_left + 1);
                        set_timer <= 1;
                        timer_in <= PLAY_TIME;
                    end
                end
                Dead: begin
                    if (lives_left != 0 && timer == 0) begin
                        State <= Default;
                        battery_left <= 8;
                    end else if (timer == 0) begin
                        State <= Bang;
                        set_timer <= 1;
                        timer_in <= RESET_CYCLES;
                    end
                end
                default: begin
                end
            endcase
        end
    end
    // Additional output logic.
    assign battery_almost_empty = (battery_left == 1);
    assign is_default_state = (State == Default);
    assign is_eating = (State == Eating);
    assign is_playing = (State == Playing);
    assign is_sleeping = (State == Sleeping);
    assign is_dead = (State == Dead);
    assign show_bang = (State == Bang);

    assign play_bang = ~rst_n || (State == Dead && timer == 0);  // If you want the signal to be a quick pulse.
    // assign play_bang = show_bang;  // If you want the signal to stay on while in the bang state.
    assign play_default = (State == Bang && timer == 0) 
                        || (State == Dead && lives_left != 0 && timer == 0)
                        || (State == Playing && B == 1)
                        || (State == Sleeping && B == 1)
                        || (State == Eating && B == 1)
                        || (State == Eating && fish_caught && total_fish_caught == 1);
    // assign play_default = is_default_state;  // If you want the signal to stay on while in the bang state.
    assign play_playing = State == Default && X == 1;  // If you want the signal to be a quick pulse.
    // assign play_playing = is_playing;  // If you want the signal to stay on while in the bang state.
    assign play_sleeping = State == Default && Y == 1;  // If you want the signal to be a quick pulse.
    // assign play_sleeping = is_sleeping;  // If you want the signal to stay on while in the bang state.
    assign play_dead = (State == Default || State == Sleeping || State == Playing) && battery_left == 0;  // If you want the signal to be a quick pulse.
    // assign play_dead = is_dead;  // If you want the signal to stay on while in the bang state.

endmodule
