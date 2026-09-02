/*
 * The clock-divider counts 'tick' pulses (in the design: one per VGA frame, 60 Hz) and outputs slower square waves.
 * This way, other modules can run on slower rates, without each having to keep a large counter.
 * Please use this clock_divider, it saves us on registers.
 * In order to use a clock, calculate which bit of the output you need:
 *      SLOW_CLOCKS_INDEX = log2(ORIGINAL_FREQUENCY * SLOW_CLOCK_PERIOD) = log2(ORIGINAL_FREQUENCY / SLOW_CLOCK_FREQUENCY)
 * For example: to get an output of 20Hz, SLOW_CLOCKS_INDEX = log2(25.175.000 / 20) = 20.26 so we take bit 20 (0-indexed).
 * Make sure DIVIDER_MSB is the highest needed bit value (0-indexed), In this case, DIVIDER_MSB = 20, unless slower clocks are still needed.
 */
module clock_divider #(parameter integer DIVIDER_MSB = 0)
                      (input rst_n, clk,                                               // Global active-low reset and clock.
                       input tick,                                                     // Clock enable: the counter advances on clk edges where tick is high.
                       output reg [DIVIDER_MSB:0] slow_clocks
);
    // Note: slow_clocks are *not* clocks. Use them as levels (or derive one-cycle ticks from them,
    // see project.v); clocking flops from them would create untimed clock domains in the ASIC flow.
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            slow_clocks <= 0;
        end
        else if (tick) begin
            slow_clocks <= slow_clocks + 1;
        end
    end
endmodule
