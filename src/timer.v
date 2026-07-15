/*
 * The timer takes care of timing-related events.
 * Three internal clocks are kept to keep track of the how long it's been since the cat slept, ate or played.
 * If the cat sleeps, eats or plays, that respective timer is reset.
 * If a timer runs out, a deplete_battery pulse is sent, and that timer is reset.
 *      Suggestion: if a timer runs out, reset it to a lower value, so it runs out again quicker.
 * The active-low reset resets all timers.
 * If the cat loses a heart or respawns, all timers reset as well. This is signaled through 'reset' as well.
 * Note: the timers could either count up or down, maybe counting down is easier as then each timer has the same 'has depleted' check: timer == 0
 */
module timer (
    input rst_n, clk,                                               // Global active-low reset and clock.
    input is_sleeping, caught_fish, is_playing,                     // Signals to reset/increase the timers/battery.
    output deplete_battery                                          // Signals that the battery has to drop one level.
);

endmodule
