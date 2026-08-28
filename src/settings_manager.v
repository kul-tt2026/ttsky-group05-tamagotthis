/*
 * The Settings Managers allow the user to change the settings of the project.
 * The inputs can only be changed when change_settings is high (during the reset stage).
 * Timeline:
 *    - change_settings rising edge: all settings reset to value 0
 *    - change_settings stays high, inputs[i] is pressed (rising edge): the corresponding outputs[i] increases by one, wrapping around if its max value (OPTIONS_COUNT - 1) is reached.
 *    - change_settings falling edge: all settings are locked in and ready to be used by other modules.
 * To have different settings with different OPTIONS_COUNT's, simply create multiple settings_managers
 *
 * Setting i can be found at at indices (i+1)*log2(options_length)-1:i*log2(options_length).
 */
module settings_manager #(parameter integer SETTINGS_COUNT = 1,
                          parameter integer OPTIONS_COUNT = 2)
                         (input rst_n, clk,                                               // Global active-low reset and clock.
                          input change_settings,                                          // Allows the user to change the settings.
                          input [SETTINGS_COUNT-1:0] inputs,                              // Input signals whose rising edges will result in the appropriate setting changing.
                          output [SETTINGS_COUNT*$clog2(OPTIONS_COUNT)-1:0] settings      // Output signals of the settings.
);
    // Used to detect the rst_n falling edge.
    reg change_settings_last_cycle;
    always @(posedge clk) begin
        change_settings_last_cycle <= change_settings;
    end

    // Generate individual settings.
    genvar i;
    generate
        for (i = 0; i < SETTINGS_COUNT; i = i + 1) begin
            reg [$clog2(OPTIONS_COUNT)-1:0] setting;
            reg input_last_cycle;
            always @(posedge clk or negedge rst_n) begin
                if (~rst_n) begin // Global active-low reset.
                    setting <= 0;
                    input_last_cycle <= 0;
                end
                else begin
                    input_last_cycle <= inputs[i];
                    if (change_settings & ~change_settings_last_cycle) begin
                        setting <= 0;
                    end
                    else if (change_settings) begin // Only function when change_settings is high.
                        setting <= inputs[i] && ~input_last_cycle ? setting + 1: setting;
                    end
                end 
            end
            assign settings[(i+1)*$clog2(OPTIONS_COUNT)-1:i*$clog2(OPTIONS_COUNT)] = setting;
        end
    endgenerate

endmodule
