`default_nettype none

module audio (
    input  wire clk,                    // clock
    input  wire rst_n,                  // reset_n - low to reset           
    input fish_caught,                  // Signals that a fish has been caught.
    input play_bang,                    // Prompts a bang sound when the cat is spawned.
    input play_default,                 // Prompts a default sound when the cat is in its default state.
    input play_sleeping,                // Prompts a sleeping sound when the cat is sleeping.
    input play_dead,                    // Prompts a sound when the cat dies.
    input battery_almost_empty,         // Prompts a sound when the battery is almost empty.
    output audio_out                    // Audio output signal that goes to the audio PMOD.
);


    // de periodes van de noten die ik nodig heb
    // noten voor play_dead
    localparam si = 19'd202478;        // periode van de klok past 25 000 000/123.47 keer in de periode van si
    localparam lakruis = 19'd214519;
    localparam la = 19'd227273;
    localparam lamol = 19'd240778;

    reg [2:0] state_wompwomp;

    // noten voor batterij: halve toon van la-do-si
    localparam la2 = 19'd28409;
    localparam si2 = 19'd25310;
    localparam do3 = 19'd23889;
    reg [1:0] state_battery;

    localparam BATTERY_SOUND_REPETITIONS = 5;
    reg [$clog2(BATTERY_SOUND_REPETITIONS+1)-1:0] repetitions_counter;

    // noten voor play_sleeping
    reg [1:0] state_sleeping;
    localparam la4 = 19'd56818;
    localparam mi42 = 19'd75843;
    localparam do4 = 19'd94830;
    localparam la3 = 19'd113636;

    // noten voor fish_caught: sol-mi-do (vierde en vijfde octaaf)
    reg [1:0] state_fish;
    localparam sol4 = 19'd15944;
    localparam mi4 = 19'd18961;
    localparam do5 = 19'd11945;

    // noten voor play_bang
    reg [1:0] state_bang;
    localparam rek = 19'd321419;
    localparam do1 = 19'd382205;
    localparam fak = 19'd270270;

    // noten voor play_default
    reg [1:0] state_default;
    // hergebruik do4 van play_sleeping
    // hergebruik mi42 van play_sleeping
    localparam sol42 = 19'd63776;
    localparam do52 = 19'd47778;

    // instantieer play_note
    reg startsignaal = 0;
    reg [18:0] tune = 0;
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

    always @(posedge clk or negedge rst_n) begin
        // Asynchronous global reset
        if (!rst_n)  begin
            counter_startsignaal <= 0;
            startsignaal <= 0;
            rythm <= 0;
            tune <= si; // Random note.
            state_wompwomp <= 0;
            state_bang <=0;
            state_battery <= 0;
            state_default <= 0;
            state_fish <= 0;
            state_sleeping <= 0;
            repetitions_counter <= BATTERY_SOUND_REPETITIONS; end
        else begin

            // startsignaal moet na 7 klokslagen terug 0 worden
            if (counter_startsignaal >= 7 && startsignaal) begin
                startsignaal <= 0;
                counter_startsignaal <= 0;  end
            else if (startsignaal == 1)
                counter_startsignaal <= counter_startsignaal + 1;

            // geen geluid maken
            if (play_dead==0 && play_bang==0 && fish_caught==0 && (battery_almost_empty==0  || repetitions_counter == 0) && play_sleeping==0 && play_default==0)
                startsignaal <= 0;

            // state machine voor play_dead == 1, does not need to repeat
            case (state_wompwomp)

                3'd0: begin                         // speel si gedurende een halve seconde
                    if ((battery_almost_empty==1 && repetitions_counter != 0) || fish_caught==1 || play_bang==1 || play_sleeping==1 || play_default==1)
                        state_wompwomp <= 3'd0;
                    else if (play_dead) begin
                        startsignaal <= 1;
                        tune <= si;
                        rythm <= 5'd5;  
                        state_wompwomp <= 3'd1; end
                end
            
                3'd1: begin                         // lakruis voor een halve seconde
                    if ((battery_almost_empty==1 && repetitions_counter != 0) || fish_caught==1 || play_bang==1 || play_sleeping==1 || play_default==1)
                        state_wompwomp <= 3'd0;
                    else if (done && !startsignaal) begin
                        startsignaal <= 1;
                        tune <= lakruis;
                        rythm <= 5'd5;
                        state_wompwomp <= 3'd2;  end
                end

                3'd2: begin
                    if ((battery_almost_empty==1 && repetitions_counter != 0) || fish_caught==1 || play_bang==1 || play_sleeping==1 || play_default==1)
                        state_wompwomp <= 3'd0;
                    else if (done && !startsignaal)  begin
                        startsignaal <= 1;
                        tune <= la;
                        rythm <= 5'd5;  
                        state_wompwomp <= 3'd3; end
                end

                3'd3: begin
                    if ((battery_almost_empty==1 && repetitions_counter != 0) || fish_caught==1 || play_bang==1 || play_sleeping==1 || play_default==1)
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
                    if (play_bang==0 && play_dead==0 && battery_almost_empty==1 && play_sleeping==0 && play_default==0 && repetitions_counter != 0) begin
                        startsignaal <= 1;
                        tune <= la2;
                        rythm <= 5'd5;
                        state_battery <= 2'd1;
                        repetitions_counter <= repetitions_counter - 1;  end
                    
                    if (battery_almost_empty == 0) begin
                        repetitions_counter <= BATTERY_SOUND_REPETITIONS;
                    end
                end

                2'd1: begin
                    if (play_dead==1 || fish_caught==1 || play_bang==1 || play_sleeping==1 || play_default==1)
                        state_battery <= 2'd0;
                    else if (done && !startsignaal)   begin
                        startsignaal <= 1;
                        tune <= do3;
                        rythm <= 5'd2;
                        state_battery <= 2'd2;  end
                end

                2'd2: begin
                    if (play_dead==1 || fish_caught==1 || play_bang==1 || play_sleeping==1 || play_default==1)
                        state_battery <= 2'd0;
                    else if (done && !startsignaal)   begin
                        startsignaal <= 1;
                        tune <= si2;
                        rythm <= 5'd10;
                        state_battery <= 2'd3;  end
                end

                2'd3: begin
                    if (play_dead==1 || fish_caught==1 || play_bang==1 || play_sleeping==1 || play_default==1)
                        state_battery <= 2'd0;
                    else if (done && !startsignaal)   begin
                        startsignaal <= 1;
                        tune <= si2;
                        rythm <= 5'd0;
                        state_battery <= 2'd0;  end
                end

                default: state_battery <= 2'd0;

            endcase

            // state machine for fish_caught == 1, does not need to repeat
            case (state_fish)

                2'd0: begin
                    if (play_dead==1 || (battery_almost_empty==1 && repetitions_counter != 0) || play_bang==1 || play_sleeping==1 || play_default==1)
                        state_fish <= 2'd0;
                    else if (fish_caught) begin
                        startsignaal <= 1;
                        tune <= sol4;
                        rythm <= 5'd1;
                        state_fish <= 2'd1; end
                end

                2'd1: begin
                    if (play_dead==1 || (battery_almost_empty==1 && repetitions_counter != 0) || play_bang==1 || play_sleeping==1 || play_default==1)
                        state_fish <= 2'd0;
                    else if (done && !startsignaal) begin
                        startsignaal <= 1;
                        tune <= mi4;
                        rythm <= 5'd1;
                        state_fish <= 2'd2; end
                end

                2'd2: begin
                    if (play_dead==1 || (battery_almost_empty==1 && repetitions_counter != 0) || play_bang==1 || play_sleeping==1 || play_default==1)
                        state_fish <= 2'd0;
                    else if (done && !startsignaal) begin
                        startsignaal <= 1;
                        tune <= do5;
                        rythm <= 5'd2;
                        state_fish <= 2'd0; end
                end

                default: state_fish <= 2'd0;

            endcase

            // state machine voor play_bang == 1, repeats
            case (state_bang)

                2'd0: begin
                    if (play_dead==1 || state_fish==1 || (battery_almost_empty==1 && repetitions_counter != 0) || play_sleeping==1 || play_default==1)
                        state_bang <= 2'd0;
                    else if (play_bang==1) begin
                        startsignaal <= 1;
                        tune <= rek;
                        rythm <= 5'd8;
                        state_bang <= 2'd1; end
                end

                2'd1: begin
                    if (play_dead==1 || state_fish==1 || (battery_almost_empty==1 && repetitions_counter != 0) || play_sleeping==1 || play_default==1)
                        state_bang <= 2'd0;
                    else if (done && !startsignaal) begin
                        startsignaal <= 1;
                        tune <= do1;
                        rythm <= 5'd8;
                        state_bang <= 2'd2; end
                end

                2'd2: begin
                    if (play_dead==1 || state_fish==1 || (battery_almost_empty==1 && repetitions_counter != 0) || play_sleeping==1 || play_default==1)
                        state_bang <= 2'd0;
                    else if (done && !startsignaal) begin
                        startsignaal <= 1;
                        tune <= fak;
                        rythm <= 5'd20;
                        state_bang <= 2'd3; end
                end

                2'd3: begin
                    if (play_dead==1 || state_fish==1 || (battery_almost_empty==1 && repetitions_counter != 0) || play_sleeping==1 || play_default==1)
                        state_bang <= 2'd0;
                    else if (done && !startsignaal) begin
                        startsignaal <= 1;
                        tune <= fak;
                        rythm <= 5'd0;
                        state_bang <= 2'd0; end
                end

                default: state_bang <= 2'd0;

            endcase

            // state machine voor play_sleeping
            case (state_sleeping)

                2'd0: begin
                    if (play_dead==1 || state_fish==1 || (battery_almost_empty==1 && repetitions_counter != 0) || play_bang==1 || play_default==1)
                        state_sleeping <= 2'd0;
                    else if (play_sleeping) begin
                        startsignaal <= 1;
                        tune <= la4;
                        rythm <= 5'd6;
                        state_sleeping <= 2'd1; end
                end

                2'd1: begin
                    if (play_dead==1 || state_fish==1 || (battery_almost_empty==1 && repetitions_counter != 0) || play_bang==1 || play_default==1)
                        state_sleeping <= 2'd0;
                    else if (done && !startsignaal) begin
                        startsignaal <= 1;
                        tune <= mi42;
                        rythm <= 5'd6;
                        state_sleeping <= 2'd2; end
                end

                2'd2: begin
                    if (play_dead==1 || state_fish==1 || (battery_almost_empty==1 && repetitions_counter != 0) || play_bang==1 || play_default==1)
                        state_sleeping <= 2'd0;
                    else if (done && !startsignaal) begin
                        startsignaal <= 1;
                        tune <= do4;
                        rythm <= 5'd6;
                        state_sleeping <= 2'd3; end
                end

                2'd3: begin
                    if (play_dead==1 || state_fish==1 || (battery_almost_empty==1 && repetitions_counter != 0) || play_bang==1 || play_default==1)
                        state_sleeping <= 2'd0;
                    else if (done && !startsignaal) begin
                        startsignaal <= 1;
                        tune <= la3;
                        rythm <= 5'd6;
                        state_sleeping <= 2'd0; end
                end

                default: state_sleeping <= 2'd0;

            endcase

            // state machine voor play_default
            case (state_default)

                2'd0: begin
                    if (play_dead==1 || state_fish==1 || (battery_almost_empty==1 && repetitions_counter != 0) || play_bang==1 || play_sleeping==1)
                        state_default <= 2'd0;
                    else if (play_default) begin
                        startsignaal <= 1;
                        tune <= do4;
                        rythm <= 5'd6;
                        state_default <= 2'd1; end
                end

                2'd1: begin
                    if (play_dead==1 || state_fish==1 || (battery_almost_empty==1 && repetitions_counter != 0) || play_bang==1 || play_sleeping==1)
                        state_default <= 2'd0;
                    else if (done && !startsignaal) begin
                        startsignaal <= 1;
                        tune <= mi42;
                        rythm <= 5'd6;
                        state_default <= 2'd2; end
                end

                2'd2: begin
                    if (play_dead==1 || state_fish==1 || (battery_almost_empty==1 && repetitions_counter != 0) || play_bang==1 || play_sleeping==1)
                        state_default <= 2'd0;
                    else if (done && !startsignaal) begin
                        startsignaal <= 1;
                        tune <= sol42;
                        rythm <= 5'd6;
                        state_default <= 2'd3; end
                end

                2'd3: begin
                    if (play_dead==1 || state_fish==1 || (battery_almost_empty==1 && repetitions_counter != 0) || play_bang==1 || play_sleeping==1)
                        state_default <= 2'd0;
                    else if (done && !startsignaal) begin
                        startsignaal <= 1;
                        tune <= do52;
                        rythm <= 5'd6;
                        state_default <= 2'd0; end
                end

                default: state_default <= 2'd0;
            endcase
        end
    end


  assign audio_out = state;

endmodule