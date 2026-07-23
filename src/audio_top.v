`default_nettype none

module audio (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n,     // reset_n - low to reset
    input  wire [6:0] state_sound // deze zijn niet perse de states v main maar eerder states voor welk geluid er gemaakt moet worden
);

    // state_sound[0] = play_dead
    // state_sound[1] = battery
    // state_sound[2] = play_sleeping
    // state_sound[3] = fish_caught
    // state_sound[4] = play_bang
    // state_sound[5] = play_default
    // state_sound[6] = play_playing

    // de periodes van de noten die ik nodig heb
    // noten voor play_dead
    localparam si = 18'd202478;        // periode van de klok past 25 000 000/123.47 keer in de periode van si
    localparam lakruis = 18'd214519;
    localparam la = 18'd227273;
    localparam lamol = 18'd240778;

    reg [2:0] state_wompwomp;

    // noten voor batterij: halve toon van la-do-si
    localparam la2 = 18'd28409;
    localparam si2 = 18'd25310;
    localparam do3 = 18'd23889;
    reg [1:0] state_battery;

    // noten voor play_sleeping


    // noten voor fish_caught: sol-mi-do (vierde en vijfde octaaf)
    reg [1:0] state_fish;
    localparam sol4 = 18'd15944;
    localparam mi4 = 18'd18961;
    localparam do5 = 18'd11945;

    // noten voor play_bang

    // instantieer play_note
    reg startsignaal = 0;
    reg [17:0] tune = 0;
    reg [4:0] rythm = 0;
    wire state;
    wire done;
    play_note play_note (
        .clk    (clk),
        .rst_n  (rst_n),
        .startsignaal   (startsignaal),
        .tune   (tune),
        .rythm  (rythm),
        .pwm_wave   (state),
        .done   (done)
    );

    reg [2:0] counter_startsignaal = 0;

    always @(posedge clk) begin

        if (!rst_n)  begin
            counter_startsignaal <= 0;
            startsignaal <= 0;
            rythm <= 0; end
        else begin

        // startsignaal moet na 7 of  klokslagen terug 0 worden
        if (counter_startsignaal >= 7 && startsignaal) begin
            startsignaal <= 0;
            counter_startsignaal <= 0;  end
        else if (startsignaal == 1)
            counter_startsignaal <= counter_startsignaal + 1;

        // geen geluid maken
        if (state_sound == 7'd0)
            startsignaal <= 0;

        // state machine voor play_dead == 1
        case (state_wompwomp)

            3'd0: begin                         // speel si gedurende een halve seconde
                if (state_sound[1]==1 || state_sound[2]==1 || state_sound[3]==1 || state_sound[4]==1 || state_sound[5]==1 || state_sound[6]==1)
                    state_wompwomp <= 3'd0;
                else if (state_sound[0]) begin
                    startsignaal <= 1;
                    tune <= si;
                    rythm <= 5'd5;  
                    state_wompwomp <= 3'd1; end
            end
        
            3'd1: begin                         // lakruis voor een halve seconde
                if (state_sound[1]==1 || state_sound[2]==1 || state_sound[3]==1 || state_sound[4]==1 || state_sound[5]==1 || state_sound[6]==1)
                    state_wompwomp <= 3'd0;
                else if (done && !startsignaal) begin
                    startsignaal <= 1;
                    tune <= lakruis;
                    rythm <= 5'd5;
                    state_wompwomp <= 3'd2;  end
            end

            3'd2: begin
                if (state_sound[1]==1 || state_sound[2]==1 || state_sound[3]==1 || state_sound[4]==1 || state_sound[5]==1 || state_sound[6]==1)
                    state_wompwomp <= 3'd0;
                else if (done && !startsignaal)  begin
                    startsignaal <= 1;
                    tune <= la;
                    rythm <= 5'd5;  
                    state_wompwomp <= 3'd3; end
            end

            3'd3: begin
                if (state_sound[1]==1 || state_sound[2]==1 || state_sound[3]==1 || state_sound[4]==1 || state_sound[5]==1 || state_sound[6]==1)
                    state_wompwomp <= 3'd0;
                else if (done && !startsignaal)   begin
                    startsignaal <= 1;
                    tune <= lamol;
                    rythm <= 5'd31;
                    state_wompwomp <= 3'd0;  end
            end

            default: state_wompwomp <= 3'd0;
        
        endcase

        // state machine for battery == 1
        case (state_battery)

            2'd0: begin
                if (state_sound == 7'b0000010) begin
                    startsignaal <= 1;
                    tune <= la2;
                    rythm <= 5'd5;
                    state_battery <= 2'd1;  end
            end

            2'd1: begin
                if (state_sound[0]==1 || state_sound[2]==1 || state_sound[3]==1 || state_sound[4]==1 || state_sound[5]==1 || state_sound[6]==1)
                    state_battery <= 2'd0;
                else if (done && !startsignaal)   begin
                    startsignaal <= 1;
                    tune <= do3;
                    rythm <= 5'd2;
                    state_battery <= 2'd2;  end
            end

            2'd2: begin
                if (state_sound[0]==1 || state_sound[2]==1 || state_sound[3]==1 || state_sound[4]==1 || state_sound[5]==1 || state_sound[6]==1)
                    state_battery <= 2'd0;
                else if (done && !startsignaal)   begin
                    startsignaal <= 1;
                    tune <= si2;
                    rythm <= 5'd10;
                    state_battery <= 2'd0;  end
            end

            default: state_battery <= 2'd0;

        endcase

        // state machine for fish_caught == 1
        case (state_fish)

            2'd0: begin
                if (state_sound[0]==1 || state_sound[1]==1 || state_sound[2]==1 || state_sound[4]==1 || state_sound[5]==1 || state_sound[6]==1)
                    state_fish <= 2'd0;
                else if (state_sound[3]) begin
                    startsignaal <= 1;
                    tune <= sol4;
                    rythm <= 5'd1;
                    state_fish <= 2'd1; end
            end

            2'd1: begin
                if (state_sound[0]==1 || state_sound[1]==1 || state_sound[2]==1 || state_sound[4]==1 || state_sound[5]==1 || state_sound[6]==1)
                    state_fish <= 2'd0;
                else if (done && !startsignaal) begin
                    startsignaal <= 1;
                    tune <= mi4;
                    rythm <= 5'd1;
                    state_fish <= 2'd2; end
            end

            2'd2: begin
                if (state_sound[0]==1 || state_sound[1]==1 || state_sound[2]==1 || state_sound[4]==1 || state_sound[5]==1 || state_sound[6]==1)
                    state_fish <= 2'd0;
                else if (done && !startsignaal) begin
                    startsignaal <= 1;
                    tune <= do5;
                    rythm <= 5'd2;
                    state_fish <= 2'd0; end
            end

            default: state_fish <= 2'd0;

        endcase

        // state machine voor play_bang == 1
        case (state_bang)

        endcase

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