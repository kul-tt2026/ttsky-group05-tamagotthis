`default_nettype none

module play_note (
    input  wire       clk,      // clock
    input  wire       rst_n,     // reset_n - low to reset
    input wire        startsignaal,
    input wire [17:0] tune,
    input wire [2:0]  rythm,       // rythm is een getal van 1 tot 7 die zegt hoeveel halve tellen een toon duurt
    output wire       pwm_wave,
    output wire       done
);

  reg [17:0] counter = 0;       // klokperiode van 40 ns dwz 25MHz

  // dingen om de lengte van de noot te regelen
  localparam half_second = 28'd12500000;    // 1 seconde heeft 25 000 000 klokperiodes
  reg [7:0] counter_pwm = 0;
  localparam period_pwm = 8'd255;    // pwm frequentie ong 98 kHz arbitriar gekozen

  reg [7:0] threshold = 0;
  localparam threshold_low = 8'd255 * 5/100;
  localparam threshold_high = 8'd255 * 90/100;
  reg [17:0] threshold_switch = 0;
  reg state;
  reg playing = 0;
  reg [27:0] timer = 0;     // gemaakt om aantal seconden bij te houden

  // signaal wanneer de noot gedaan is 
  reg finish = 0;

  always @(posedge clk) begin
    if (!rst_n) begin
      state <= 0;
      finish <= 0;
      playing <= 0;
      timer <= 0;
      counter_pwm <= 0;
      counter <= 0; end
    else begin 

      if (!playing && startsignaal) begin
        playing <= 1;
        timer <= 0;
        finish <= 0; 
        threshold_switch <= tune >> 1;  end

      if (playing) begin
      if (timer >= rythm * half_second) begin
        timer <= 0;
        playing <= 0;
        threshold_switch <= 0;
        finish <= 1;
        counter <= 0;
        counter_pwm <= 0;  end
      else timer <= timer + 1;

      if (counter >= tune)
        counter <= 0;
      else counter <= counter + 1;

      if (counter <= threshold_switch)
        threshold <= threshold_low;
      else threshold <= threshold_high;

      if (counter_pwm >= period_pwm)
        counter_pwm <= 0;
      else counter_pwm <= counter_pwm + 1;
      
      if (counter_pwm <= threshold)
        state <= 1;
      else state <= 0;
      end

      else state <= 0;
    end
  end

  assign pwm_wave = state;
  assign done = finish;

endmodule