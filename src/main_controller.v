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
    output reg cat_mirrorred,                               // Signals whether the cat image should be mirrorred.
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
    parameter EAT_STEP_SIZE = 1;
    // Number of cycles before the cat moves again, if the button remains pressed. -1 for 'does not move again unless button is pressed again'.
    parameter EAT_STEP_INTERVAL = 10;
    // Number of pixels the cat moves over per button press in the eating state.
    parameter DEFAULT_STEP_SIZE = 1;
    // Number of cycles before the cat moves again, if the button remains pressed. -1 for 'does not move'.
    parameter DEFAULT_STEP_INTERVAL = -1;
    // Number of pixels the cat moves over per button press in the eating state.
    parameter PLAY_STEP_SIZE = 2;
    // Number of cycles before the cat moves again, if the button remains pressed. -1 for 'does not move'.
    parameter PLAY_STEP_INTERVAL = -1;
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
    reg [TIMER_BITS-1:0] timer, timer_in;
    reg set_timer;

    // State machine.
    reg [2:0] State;
    localparam Bang = 3'b000;
    localparam Default = 3'b001;
    localparam Eating = 3'b010;
    localparam Sleeping = 3'b011;
    localparam Playing = 3'b100;
    localparam Dead = 3'b101;
    // Extra variables
    reg [$clog2(FISH_TO_CATCH+1)-1:0] total_fish_caught;
    reg has_moved_left, has_moved_right, has_moved_up, has_moved_down;

    reg next_has_moved_left, next_has_moved_right, next_has_moved_up, next_has_moved_down, next_cat_mirrorred, next_cat_mirrorred_play;
    reg [2:0] next_state;
    reg [3:0] next_lives, next_battery;
    reg [$clog2(FISH_TO_CATCH+1)-1:0] next_total_fish_caught;

    // Movement system.
    reg [9:0] next_cat_pos_x, next_cat_pos_y, next_cat_pos_x_play;

    always @(posedge clk, negedge rst_n) begin
        // Active low reset.
        if (~rst_n) begin
            State <= Bang;
            timer <= RESET_CYCLES;
            cat_mirrorred <= 0;
        end
        else begin
            if (set_timer) begin 
                timer <= timer_in;
            end
            else begin 
                timer <= timer - 1;
            end

            State <= next_state;
            lives_left <= next_lives;
            battery_left <= next_battery;
            total_fish_caught <= next_total_fish_caught;
            cat_mirrorred <= State == Playing ? next_cat_mirrorred_play : next_cat_mirrorred;
            has_moved_left <= next_has_moved_left;
            has_moved_up <= next_has_moved_up;
            has_moved_right <= next_has_moved_right;
            has_moved_down <= next_has_moved_down;
            cat_pos_x <= State == Playing ? next_cat_pos_x_play : next_cat_pos_x;
            cat_pos_y <= next_cat_pos_y;
        end
    end
    
    always @(*) begin
        // Default values:
        set_timer = 0;
        next_state = State;
        next_lives = lives_left;
        next_battery = battery_left;
        next_cat_pos_x = cat_pos_x;
        next_cat_pos_y = cat_pos_y;
        next_cat_mirrorred = cat_mirrorred;
        next_total_fish_caught = total_fish_caught;
        next_has_moved_left = 1'bx;
        next_has_moved_down = 1'bx;
        next_has_moved_right = 1'bx;
        next_has_moved_up = 1'bx;
        timer_in = {TIMER_BITS{1'bx}};
        
        if (deplete_battery && State != Bang && State != Dead) begin
            next_battery = battery_left - 1;
        end

        case(State)
            Bang: begin
                if (timer == 0) begin
                    next_state = Default;
                    next_cat_pos_x = START_POS_X;
                    next_cat_pos_y = START_POS_Y;
                    next_lives = 9;
                    next_battery = 8;
                    if (DEFAULT_STEP_INTERVAL > 0) begin
                        set_timer = 1;
                        timer_in = DEFAULT_STEP_INTERVAL;
                    end
                end
            end
            Default: begin
                if (battery_left == 0) begin
                    next_state = Dead;
                    next_lives = lives_left - 1;
                    set_timer = 1;
                    timer_in = DEAD_CYCLES;
                end else if (X == 1) begin
                    next_state = Playing;
                    set_timer = 1;
                    timer_in = PLAY_TIME;
                end else if (Y == 1) begin
                    next_state = Sleeping;
                    set_timer = 1;
                    timer_in = SLEEP_TIME;
                end else if (A == 1) begin
                    next_state = Eating;
                    next_total_fish_caught = FISH_TO_CATCH;
                end
                if (DEFAULT_STEP_INTERVAL > 0) begin
                    if (timer == 0) begin
                        set_timer = 1;
                        timer_in = DEFAULT_STEP_INTERVAL;
                        if (cat_pos_x == MAX_POS_X) begin
                            next_cat_pos_x = MAX_POS_X - DEFAULT_STEP_SIZE;
                            next_cat_mirrorred = 0;
                        end else if (cat_pos_x == MIN_POS_X) begin
                            next_cat_mirrorred = 1;
                            next_cat_pos_x = MIN_POS_X + DEFAULT_STEP_SIZE;
                        end else if (cat_mirrorred) begin
                            next_cat_pos_x = cat_pos_x + DEFAULT_STEP_SIZE >= MAX_POS_X ? MAX_POS_X : cat_pos_x + DEFAULT_STEP_SIZE;
                        end else begin
                            next_cat_pos_x = cat_pos_x - DEFAULT_STEP_SIZE <= MIN_POS_X ? MIN_POS_X : cat_pos_x - DEFAULT_STEP_SIZE;
                        end
                    end
                end else if (DEFAULT_STEP_INTERVAL == 0) begin
                    if (cat_pos_x == MAX_POS_X) begin
                        next_cat_pos_x = MAX_POS_X - DEFAULT_STEP_SIZE;
                        next_cat_mirrorred = 0;
                    end else if (cat_pos_x == MIN_POS_X) begin
                        next_cat_mirrorred = 1;
                        next_cat_pos_x = MIN_POS_X + DEFAULT_STEP_SIZE;
                    end else if (cat_mirrorred) begin
                        next_cat_pos_x = cat_pos_x + DEFAULT_STEP_SIZE >= MAX_POS_X ? MAX_POS_X : cat_pos_x + DEFAULT_STEP_SIZE;
                    end else begin
                        next_cat_pos_x = cat_pos_x - DEFAULT_STEP_SIZE <= MIN_POS_X ? MIN_POS_X : cat_pos_x - DEFAULT_STEP_SIZE;
                    end
                end
            end
            Eating: begin
                if (B == 1) begin
                    next_state = Default;
                end

                // Move buttons.
                if (left == 1) begin
                    next_cat_mirrorred = 0;
                    next_has_moved_left = 1;
                    next_has_moved_right = 0;
                    if (EAT_STEP_INTERVAL > 0) begin
                        if ((timer == 0 || ~has_moved_left)) begin
                            set_timer = 1;
                            timer_in = EAT_STEP_INTERVAL;
                            next_cat_pos_x = cat_pos_x > MIN_POS_X + EAT_STEP_SIZE ? cat_pos_x - EAT_STEP_SIZE : MIN_POS_X;
                        end
                    end else begin
                        if (~has_moved_left) begin
                            next_cat_pos_x = cat_pos_x > MIN_POS_X + EAT_STEP_SIZE ? cat_pos_x - EAT_STEP_SIZE : MIN_POS_X;
                        end
                    end
                end else if (right == 1) begin
                    next_cat_mirrorred = 1;
                    next_has_moved_left = 0;
                    next_has_moved_right = 1;
                    if (EAT_STEP_INTERVAL > 0) begin
                        if ((timer == 0 || ~has_moved_right)) begin
                            set_timer = 1;
                            timer_in = EAT_STEP_INTERVAL;
                            next_cat_pos_x = cat_pos_x < MAX_POS_X - EAT_STEP_SIZE ? cat_pos_x + EAT_STEP_SIZE : MAX_POS_X;
                        end
                    end else begin
                        if (~has_moved_right) begin
                            next_cat_pos_x = cat_pos_x < MAX_POS_X - EAT_STEP_SIZE ? cat_pos_x + EAT_STEP_SIZE : MAX_POS_X;
                        end
                    end
                end else begin
                    next_has_moved_left = 0;
                    next_has_moved_right = 0;
                end
                
                if (down == 1) begin
                    next_has_moved_up = 0;
                    next_has_moved_down = 1;
                    
                    if (EAT_STEP_INTERVAL > 0) begin
                        if ((timer == 0 || ~has_moved_down)) begin
                            set_timer = 1;
                            timer_in = EAT_STEP_INTERVAL;
                            next_cat_pos_y = cat_pos_y < MAX_POS_Y - EAT_STEP_SIZE ? cat_pos_y + EAT_STEP_SIZE : MAX_POS_Y;
                        end
                    end else begin
                        if (~has_moved_down) begin
                            next_cat_pos_y = cat_pos_y < MAX_POS_Y - EAT_STEP_SIZE ? cat_pos_y + EAT_STEP_SIZE : MAX_POS_Y;
                        end
                    end
                end else if (up == 1) begin 
                    next_has_moved_up = 1;
                    next_has_moved_down = 0;
                    if (EAT_STEP_INTERVAL > 0) begin
                        if ((timer == 0 || ~has_moved_up)) begin
                            set_timer = 1;
                            timer_in = EAT_STEP_INTERVAL;
                            next_cat_pos_y = cat_pos_y > MIN_POS_Y + EAT_STEP_SIZE ? cat_pos_y - EAT_STEP_SIZE : MIN_POS_Y;
                        end
                    end else begin
                        if (~has_moved_up) begin
                            next_cat_pos_y = cat_pos_y > MIN_POS_Y + EAT_STEP_SIZE ? cat_pos_y - EAT_STEP_SIZE : MIN_POS_Y;
                        end
                    end
                end else begin
                    next_has_moved_up = 0;
                    next_has_moved_down = 0;
                end

                // Fish caught.
                if (fish_caught) begin
                    next_total_fish_caught = total_fish_caught - 1;
                    if (next_total_fish_caught == 0) begin
                        next_state = Default;
                        next_battery = battery_left == 8 ? 8 : (battery_left + 1);
                    end
                end
            end
            Sleeping: begin
                if (battery_left == 0) begin
                    next_state = Dead;
                    next_lives = lives_left - 1;
                    set_timer = 1;
                    timer_in = DEAD_CYCLES;
                end else if (B == 1) begin
                    next_state = Default;
                end else if (timer == 0) begin
                    next_battery = battery_left == 8 ? 8 : (battery_left + 1);
                    set_timer = 1;
                    timer_in = SLEEP_TIME;
                end
            end
            Playing: begin
                if (battery_left == 0) begin
                    next_state = Dead;
                    next_lives = lives_left - 1;
                    set_timer = 1;
                    timer_in = DEAD_CYCLES;
                end else if (B == 1) begin
                    next_state = Default;
                end else if (timer == 0) begin
                    next_battery = battery_left == 8 ? 8 : (battery_left + 1);
                    set_timer = 1;
                    timer_in = PLAY_TIME;
                end
            end
            Dead: begin
                if (lives_left != 0 && timer == 0) begin
                    next_state = Default;
                    next_battery = 8;
                end else if (timer == 0) begin
                    next_state = Bang;
                    set_timer = 1;
                    timer_in = RESET_CYCLES;
                end
            end
            default: begin
            end
        endcase
    end
    
    // Cat movement in the Playing state.
    generate 
        if (PLAY_STEP_INTERVAL > 0) begin
            reg [$bits(PLAY_STEP_INTERVAL+1)-1:0] play_step_timer, play_step_timer_in;
            reg set_play_step_timer;
            
            always @(posedge clk) begin
                if (set_play_step_timer) begin 
                    play_step_timer <= play_step_timer_in;
                end
                else begin 
                    play_step_timer <= play_step_timer - 1;
                end
            end
            always @(*) begin
                set_play_step_timer = 0;
                next_cat_mirrorred_play = cat_mirrorred;
                play_step_timer_in = {$bits(PLAY_STEP_INTERVAL+1){1'bx}};

                if ((State == Default && X == 1) || (State == Playing && play_step_timer == 0)) begin
                    set_play_step_timer = 1;
                    play_step_timer_in = PLAY_STEP_INTERVAL;
                    if (cat_pos_x == MAX_POS_X) begin
                        next_cat_pos_x_play = MAX_POS_X - PLAY_STEP_SIZE;
                        next_cat_mirrorred_play = 0;
                    end else if (cat_pos_x == MIN_POS_X) begin
                        next_cat_mirrorred_play = 1;
                        next_cat_pos_x_play = MIN_POS_X + PLAY_STEP_SIZE;
                    end else if (cat_mirrorred) begin
                        next_cat_pos_x_play = cat_pos_x + PLAY_STEP_SIZE >= MAX_POS_X ? MAX_POS_X : cat_pos_x + PLAY_STEP_SIZE;
                    end else begin
                        next_cat_pos_x_play = cat_pos_x - PLAY_STEP_SIZE <= MIN_POS_X ? MIN_POS_X : cat_pos_x - PLAY_STEP_SIZE;
                    end
                end
            end
        end else if (PLAY_STEP_INTERVAL == 0) begin // PLAY_STEP_INTERVAL == 0: movement every tick.
            always @(*) begin
                next_cat_mirrorred_play = cat_mirrorred;

                if ((State == Default && X == 1) || State == Playing) begin
                    if (cat_pos_x == MAX_POS_X) begin
                        next_cat_pos_x_play = MAX_POS_X - PLAY_STEP_SIZE;
                        next_cat_mirrorred_play = 0;
                    end else if (cat_pos_x == MIN_POS_X) begin
                        next_cat_mirrorred_play = 1;
                        next_cat_pos_x_play = MIN_POS_X + PLAY_STEP_SIZE;
                    end else if (cat_mirrorred) begin
                        next_cat_pos_x_play = cat_pos_x + PLAY_STEP_SIZE >= MAX_POS_X ? MAX_POS_X : cat_pos_x + PLAY_STEP_SIZE;
                    end else begin
                        next_cat_pos_x_play = cat_pos_x - PLAY_STEP_SIZE <= MIN_POS_X ? MIN_POS_X : cat_pos_x - PLAY_STEP_SIZE;
                    end
                end
            end
        end else begin // PLAY_STEP_INTERVAL < 0: no movement.
            assign next_cat_pos_x_play = cat_pos_x;
            assign next_cat_mirrorred_play = cat_mirrorred;
        end
    endgenerate

    // Additional output logic.
    assign battery_almost_empty = (battery_left == 1);
    assign is_default_state = (State == Default);
    assign is_eating = (State == Eating);
    assign is_playing = (State == Playing);
    assign is_sleeping = (State == Sleeping);
    assign is_dead = (State == Dead);
    assign show_bang = (State == Bang);

    assign play_bang = (next_state == Bang && State != Bang) || ~rst_n;  // If you want the signal to be a quick pulse.
    // assign play_bang = show_bang;  // If you want the signal to stay on while in the bang state.
    assign play_default = (next_state == Default && State != Default);
    // assign play_default = is_default_state;  // If you want the signal to stay on while in the bang state.
    assign play_playing = (next_state == Playing && State != Playing);  // If you want the signal to be a quick pulse.
    // assign play_playing = is_playing;  // If you want the signal to stay on while in the bang state.
    assign play_sleeping = (next_state == Sleeping && State != Sleeping);  // If you want the signal to be a quick pulse.
    // assign play_sleeping = is_sleeping;  // If you want the signal to stay on while in the bang state.
    assign play_dead = (next_state == Dead && State != Dead);  // If you want the signal to be a quick pulse.
    // assign play_dead = is_dead;  // If you want the signal to stay on while in the bang state.

endmodule