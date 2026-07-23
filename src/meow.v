`default_nettype none

module tt_um_pwm_example (
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    // miauw begint op hoge do

  reg [16:0] counter = 0;       // klokperiode van 40 ns dwz 25MHz
  localparam DO = 17'd95556;    // periode van klok past zo veel keer id periode ve do
  reg [18:0] tone = 0;          // periode van de toonhoogte
  reg [7:0] counter_pwm = 0;
  localparam period_pwm = 8'd255;    // pwm frequentie ong 98 kHz werd arbitriar gekozen

  reg [7:0] threshold = 0;
  localparam threshold_low = 8'd255 * 5/100;
  localparam threshold_high = 8'd255 * 90/100;
  reg [17:0] threshold_switch = 0;
  reg state;

  always @(posedge clk) begin
    if (!rst_n)
      counter <= 0;
    else begin
      if (counter >= DO) begin
        counter <= 0;
        threshold <= 0; end
      else counter <= counter + 1;

      if (counter_pwm >= period_pwm) begin
        counter_pwm <= 0;
        threshold <= threshold + 1; end
      else counter_pwm <= counter_pwm + 1;
      
      if (counter_pwm <= threshold)
        state <= 1;
      else state <= 0;
      end
  end


endmodule
