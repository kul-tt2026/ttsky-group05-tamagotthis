/*
 * The Settings Managers allow the user to change the settings of the project.
 * The inputs can only be changed when rst_n is low (during the reset stage).
 * Timeline:
 *    - rst_n falling edge: all settings reset to value 0
 *    - rst_n stays low, inputs[i] is pressed (rising edge): the corresponding outputs[i] increases by one, wrapping around if its max value (OPTIONS_COUNT - 1) is reached.
 *    - rst_n rising edge: all settings are locked in and ready to be used by other modules.
 * To have different settings with different OPTIONS_COUNT's, simply create multiple settings_managers
 *
 * Setting i can be found at at indices (i+1)*log2(options_length)-1:i*log2(options_length).
 */
module settings_manager #(parameter integer SETTINGS_COUNT = 1,
                          parameter integer OPTIONS_COUNT = 2)
                         (input rst_n, clk,                                               // Global active-low reset and clock.
                          input [SETTINGS_COUNT-1:0] inputs,                              // Input signals whose rising edges will result in the appropriate setting changing.
                          output [SETTINGS_COUNT*$clog2(OPTIONS_COUNT)-1:0] settings      // Output signals of the settings.
);
    reg rst_n_last_cycle;
    always @(posedge clk) begin
        rst_n_last_cycle <= rst_n;
    end
    genvar i;
    generate
        for (i = 0; i < SETTINGS_COUNT; i = i + 1) begin
            reg [$clog2(OPTIONS_COUNT)-1:0] setting;
            reg input_last_cycle;
            always @(posedge clk) begin
                input_last_cycle <= inputs[i];
                if (~rst_n && rst_n_last_cycle) begin // Reset on falling edge of rst_n.
                    setting <= 0;
                end
                else if (~rst_n) begin // Only function when in the reset state.
                    setting <= inputs[i] && ~input_last_cycle ? setting + 1: setting;
                end
            end
            assign settings[(i+1)*$clog2(OPTIONS_COUNT)-1:i*$clog2(OPTIONS_COUNT)] = setting;
        end
    endgenerate

endmodule
