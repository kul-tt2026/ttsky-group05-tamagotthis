`default_nettype none

module play_note (
    input  wire       clk,      // clock
    input  wire       rst_n,     // reset_n - low to reset
    input wire        startsignaal,
    input wire [17:0] tune,
    input wire [4:0]  rythm,       // rythm is een getal van 1 tot 31 die zegt hoeveel tiende tellen een toon duurt: 1 toon is max 3,1 s lang
    output wire       pwm_wave,
    output wire       done
);

  reg [17:0] counter = 0;       // klokperiode van 40 ns dwz 25MHz

  // dingen om de lengte van de noot te regelen
  localparam tenth_second = 28'd2500000;    // 1 seconde heeft 25 000 000 klokperiodes
  reg [7:0] counter_pwm = 0;
  localparam period_pwm = 8'd255;    // pwm frequentie ong 98 kHz arbitriar gekozen

  reg [7:0] threshold = 0;
  reg [2:0] phase = 0;
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
      counter <= 0;
      threshold <= 0;
      phase <= 0; end
    else begin 

      if (!playing && startsignaal) begin
        playing <= 1;
        timer <= 0;
        finish <= 0;
        counter <= 0;
        counter_pwm <= 0;
        threshold <= 0;
        phase <= 0; end

      if (playing) begin
      if (timer >= rythm * tenth_second) begin
        timer <= 0;
        playing <= 0;
        finish <= 1;
        counter <= 0;
        counter_pwm <= 0;   end
      else timer <= timer + 1;

      if (counter >= tune/8)  begin
        counter <= 0;
        phase <= phase + 1; end
      else counter <= counter + 1;

      if (counter_pwm >= period_pwm)
        counter_pwm <= 0;
      else counter_pwm <= counter_pwm + 1;

      case (phase)
        0:  threshold <= period_pwm * 5/100;
        1:  threshold <= period_pwm / 4;
        2:  threshold <= period_pwm / 2;
        3:  threshold <= period_pwm * 8/10;
        4:  threshold <= period_pwm * 95/100;
        5:  threshold <= period_pwm * 8/10;
        6:  threshold <= period_pwm / 2;
        7:  threshold <= period_pwm / 4;
        default: phase <= 0;
      endcase
      
      if (counter_pwm <= threshold)
        state <= 1;
      else state <= 0;
      end
    end
  end

  assign pwm_wave = state;
  assign done = finish;

endmodule