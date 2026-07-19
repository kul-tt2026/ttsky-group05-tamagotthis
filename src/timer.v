/*
 * The timer takes care of timing-related events.
 * Three internal clocks are kept to keep track of the how long it's been since the cat slept, ate or played.
 * If the cat sleeps, eats or plays, that respective timer is reset.
 * If a timer runs out, a deplete_battery pulse is sent, and that timer is reset.
 *      Suggestion: if a timer runs out, reset it to a lower value, so it runs out again quicker.
 * The active-low reset resets all timers.
 * If the cat loses a heart or respawns, all timers reset as well. This is signaled through 'rst_n' as well.
 * Note: the timers could either count up or down, maybe counting down is easier as then each timer has the same 'has depleted' check: timer == 0
 */
module timer (
    input rst_n, clk,                                               // Global active-low reset and clock.
    input is_sleeping, caught_fish, is_playing,                     // Signals to reset/increase the timers/battery.
    output deplete_battery                                          // Signals that the battery has to drop one level.
);

    parameter CLOCK_BITS = 8;

    // The depletion times represent the number of clock cycles that need to pass before a deplete_battery because of lack of sleep, food or play respectively.
    // If a reset signal (for example: is_sleeping) comes in in the meantime, the corresponding timer is reset to its corresponding DEPLETION_TIME.
    // If a depletion timer hits zero, a deplete_battery pulse is sent and the timer is reset to its corresponding FURTHER_DEPLETION_TIME.
    parameter SLEEP_DEPLETION_TIME = 20;
    parameter SLEEP_FURTHER_DEPLETION_TIME = 10;
    parameter EAT_DEPLETION_TIME = 20;
    parameter EAT_FURTHER_DEPLETION_TIME = 10;
    parameter PLAY_DEPLETION_TIME = 20;
    parameter PLAY_FURTHER_DEPLETION_TIME = 10;

    reg [CLOCK_BITS-1:0] sleep_clk, eat_clk, play_clk;

    always @(posedge clk or rst_n) begin // Asynchronous reset.
        if (~rst_n) begin
            sleep_clk <= SLEEP_DEPLETION_TIME;
            eat_clk <= EAT_DEPLETION_TIME;
            play_clk <= PLAY_DEPLETION_TIME;
        end
        else begin // posedge clk.
            sleep_clk <= is_sleeping    ? SLEEP_DEPLETION_TIME :
                         sleep_clk == 0 ? SLEEP_FURTHER_DEPLETION_TIME :
                                          sleep_clk - 1;
            eat_clk   <= caught_fish    ? EAT_DEPLETION_TIME :
                         eat_clk == 0   ? EAT_FURTHER_DEPLETION_TIME :
                                          eat_clk - 1;
            play_clk  <= is_playing     ? PLAY_DEPLETION_TIME :
                         play_clk == 0  ? PLAY_FURTHER_DEPLETION_TIME :
                                          play_clk - 1;
        end
    end

    assign deplete_battery = sleep_clk == 0 || eat_clk == 0 || play_clk == 0;

endmodule
