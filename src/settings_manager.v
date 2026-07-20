/*
 * The Settings Managers allow the user to change the settings of the project.
 * The inputs can only be changed when rst_n is low (during the reset stage).
 * Timeline:
 *    - rst_n falling edge: all settings reset to value 0
 *    - rst_n stays low, inputs[i] is pressed (rising edge): the corresponding outputs[i] increases by one, wrapping around if its max value (OPTIONS_COUNT - 1) is reached.
 *    - rst_n rising edge: all settings are locked in and ready to be used by other modules.
 * To have different settings with different OPTIONS_COUNT's, simply create multiple settings_managers
 */
module settings_manager #(parameter integer SETTINGS_COUNT = 1,
                                  parameter integer OPTIONS_COUNT = 2)
                      (input rst_n, clk,                                               // Global active-low reset and clock.
                       input inputs[SETTINGS_COUNT],                                   // Input signals whose rising edges will result in the appropriate setting changing.
                       output [$clog2(OPTIONS_COUNT)-1:0] settings[SETTINGS_COUNT]      // Output signals of the settings.
);

endmodule
