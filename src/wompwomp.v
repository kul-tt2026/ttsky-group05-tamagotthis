`default_nettype none

module wompwomp (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n,     // reset_n - low to reset
    input wire        startsignaal
);

  reg [17:0] counter = 0;       // klokperiode van 40 ns dwz 25MHz
  localparam si = 18'd202478;        // periode van de klok past 25 000 000/123.47 keer in de periode van si
  localparam lakruis = 18'd214519;
  localparam la = 18'd227273;
  localparam lamol = 18'd240778;
  localparam half_second = 26'd12500000;    // 1 seconde heeft 25 000 000 klokperiodes
  reg [7:0] counter_pwm = 0;
  localparam period_pwm = 8'd255;    // pwm frequentie ong 98 kHz arbitriar gekozen

  reg [7:0] threshold = 0;
  localparam threshold_low = 8'd255 * 5/100;
  localparam threshold_high = 8'd255 * 90/100;
  reg [17:0] threshold_switch = si / 2;
  reg [17:0] tune = si;
  reg state;
  reg playing = 0;
  reg [25:0] timer = 0;     // gemaakt om aantal seconden bij te houden

  always @(posedge clk) begin
    if (!rst_n) begin
      state <= 0;
      playing <= 0;
      timer <= 0;
      counter_pwm <= 0;
      counter <= 0; end
    else begin 

      if (!playing && startsignaal) begin
        playing <= 1;
        timer <= 0; end

      if (playing) begin
      if (timer >= 6 * half_second) begin
        timer <= 0;
        playing <= 0;
        threshold_switch <= si / 2;
        tune <= si; end
      else timer <= timer + 1;

      if (counter >= tune)
        counter <= 0;
      else counter <= counter + 1;

      if (timer <= half_second) begin
        tune <= si;
        threshold_switch <= si/2; end
      else if (timer <=  2 * half_second) begin
        tune <= lakruis;
        threshold_switch <= lakruis / 2; end
      else if (timer <= 3 * half_second) begin
        tune <= la;
        threshold_switch <= la / 2; end
      else if (timer <= 4 * half_second) begin
        tune <= lamol;
        threshold_switch <= lamol / 2; end

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

  assign uio_out[7] = state;

  // All output pins must be assigned. If not used, assign to 0.
  assign uo_out = 0;
  assign uio_out[6:0] = 0;
  assign uio_oe = 8'b10000000;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, uio_in[7:4], 1'b0};

endmodule