`default_nettype none

// Plays a note at a given frequency (actually period: tune), for a given duration of time (rythm).
module play_note (
    input  wire       clk,            // clock
    input  wire       rst_n,          // reset_n - low to reset
    input wire        startsignaal,   // One to start playing the tune.
    input wire [18:0] tune,           // Note period (instead of frequency) expressed as a whole number of clk cycles.
    input wire [4:0]  rythm,          // rythm is een getal van 1 tot 31 die zegt hoeveel tiende tellen een toon duurt: 1 toon is max 3,1 s lang
    output wire       pwm_wave,       // Output PWM.
    output wire       done            // One if the note is done, will remain 1 until a new note is started or the module is reset.
);
  // klokperiode van 40 ns dwz 25MHz
  reg [18:0] counter = 0;   // Counter to keep track of how long the current phase has been going on.

  // dingen om de lengte van de noot te regelen
  localparam tenth_second = 28'd2500000;    // 1 seconde heeft 25 000 000 klokperiodes
  // localparam tenth_second = 28'd300;    // Voor simulator: 3Khz.
  reg [7:0] counter_pwm = 0; // Counter to output 1 and 0 at a specified PWM duty cycle.
  localparam period_pwm = 8'd255;    // pwm frequentie ong 98 kHz arbitriar gekozen

  reg [7:0] threshold = 0;  // PWM dutycycle, expressed in number of clk-cycles the state is 1.
  reg [2:0] phase = 0;      // Which phase of the sine wave the note is in.
  reg state;                // Output of the PWM signal (1 or 0).
  reg playing = 0;          // Is a note currently being played?
  reg [27:0] timer = 0;     // gemaakt om aantal seconden bij te houden

  // signaal wanneer de noot gedaan is 
  reg finish = 0;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin // Asynchronous reset.
      state <= 0;
      finish <= 0;
      playing <= 0;
      timer <= 0;
      counter_pwm <= 0;
      counter <= 0;
      threshold <= 0;
      phase <= 0; end
    else begin 
      // Start playing a note: initial state.
      if (!playing && startsignaal) begin
        playing <= 1;
        timer <= 0;
        finish <= 0;
        counter <= 0;
        counter_pwm <= 0;
        threshold <= 0;
        phase <= 0; end

      // While playing a note.
      if (playing) begin
        if (timer >= rythm * tenth_second) begin
          // Note finished: final state.
          timer <= 0;
          playing <= 0;
          finish <= 1;
          counter <= 0;
          counter_pwm <= 0;   end
        else timer <= timer + 1;

        // Sine wave is simulated using PWM, each "length" of a PWM 1 or 0 is defined as a phase.
        if (counter >= tune/8)  begin
          counter <= 0;
          phase <= phase + 1; end
        else counter <= counter + 1;

        if (counter_pwm >= period_pwm)
          counter_pwm <= 0;
        else counter_pwm <= counter_pwm + 1;

        // Sine wave duty cycle lookup table.
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