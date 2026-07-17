`default_nettype none

module audio (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    // de periodes van de noten die ik nodig heb
    // noten voor play_dead
    localparam si = 18'd202478;        // periode van de klok past 25 000 000/123.47 keer in de periode van si
    localparam lakruis = 18'd214519;
    localparam la = 18'd227273;
    localparam lamol = 18'd240778;

    // noten voor play_sleeping


    // instantieer play_note
    play_note play_note (
        .clk    (clk),
        .rst_n  (rst_n),
        .startsignaal   (startsignaal),
        .tune   (tune),
        .rythm  (rythm),
        .pwm_wave   (state)
    );
    reg startsignaal = 0;
    reg [17:0] tune = 0;
    reg [2:0] rythm = 0;
    reg state;

    always @(posedge clk) begin

        // if play_dead == 1: speel het geluid voor dood
        

    end


  assign uio_out[7] = state;

  // All output pins must be assigned. If not used, assign to 0.
  assign uo_out = 0;
  assign uio_out[6:0] = 0;
  assign uio_oe = 8'b10000000;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, uio_in[7:4], 1'b0};

endmodule