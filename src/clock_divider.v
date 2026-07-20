/*
 * The clock-divider takes in the 25.175 MHz clock, and outputs clocks at slower tick rates.
 * This way, other modules can run on slower clocks, without each having to keep a large counter.
 * Please use this clock_divider, it saves us on registers.
 * In order to use a clock, calculate how which bit of the output you need:
 *      SLOW_CLOCKS_INDEX = log2(ORIGINAL_FREQUENCY * SLOW_CLOCK_PERIOD) = log2(ORIGINAL_FREQUENCY / SLOW_CLOCK_FREQUENCY)
 * For example: to get an output of 20Hz, SLOW_CLOCKS_INDEX = log2(25.175.000 / 20) = 20.26 so we take bit 20 (0-indexed).
 * Make sure DIVIDER_MSB is the highest needed bit value (0-indexed), In this case, DIVIDER_MSB = 20, unless slower clocks are still needed.
 */
module clock_divider #(parameter integer DIVIDER_MSB = 0)
                      (input rst_n, clk,                                               // Global active-low reset and clock.
                       output reg slow_clocks[DIVIDER_MSB]
);

endmodule
