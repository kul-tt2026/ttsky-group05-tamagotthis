`default_nettype none
`timescale 1ns / 1ps

module tb_audio;

    // =========================================================
    // CLOCK / RESET
    // =========================================================

    reg clk;
    reg rst_n;

    // =========================================================
    // SIX SOUND INPUTS
    // =========================================================

    reg fish_caught;
    reg play_bang;
    reg play_default;
    reg play_sleeping;
    reg play_dead;
    reg battery_almost_empty;

    // =========================================================
    // AUDIO OUTPUT
    // =========================================================

    wire audio_out;

    // =========================================================
    // PWM MONITOR
    //
    // One sample is produced every 256 clock cycles.
    //
    // pwm_high_count = number of HIGH clocks during one PWM
    // period.
    //
    // pwm_sample_valid pulses HIGH for one clock when a complete
    // PWM period has been measured.
    // =========================================================

    reg [7:0] pwm_clock_count;
    reg [8:0] pwm_high_count;
    reg       pwm_sample_valid;

    // =========================================================
    // CLOCK
    // =========================================================

    initial clk = 0;

    always #20 clk = ~clk;   // 25 MHz

    // =========================================================
    // RESET
    // =========================================================

    initial begin
        rst_n = 0;
        #200;
        rst_n = 1;
    end

    // =========================================================
    // INITIAL INPUT VALUES
    // =========================================================

    initial begin
        fish_caught          = 0;
        play_bang            = 0;
        play_default         = 0;
        play_sleeping        = 0;
        play_dead            = 0;
        battery_almost_empty = 0;
    end

    // =========================================================
    // DUT
    //
    // This assumes your audio module has these ports:
    //
    // input clk
    // input rst_n
    // input fish_caught
    // input play_bang
    // input play_default
    // input play_sleeping
    // input play_dead
    // input battery_almost_empty
    // output audio_out
    // =========================================================

    audio dut (
        .clk                  (clk),
        .rst_n                (rst_n),

        .fish_caught          (fish_caught),
        .play_bang            (play_bang),
        .play_default         (play_default),
        .play_sleeping        (play_sleeping),
        .play_dead            (play_dead),
        .battery_almost_empty (battery_almost_empty),

        .audio_out            (audio_out)
    );

    // =========================================================
    // PWM DUTY-CYCLE MEASUREMENT
    // =========================================================

    always @(posedge clk) begin

        if (!rst_n) begin

            pwm_clock_count <= 0;
            pwm_high_count <= 0;
            pwm_sample_valid <= 0;

        end else begin

            pwm_sample_valid <= 0;

            // Count HIGH cycles in the current PWM period
            if (audio_out)
                pwm_high_count <= pwm_high_count + 1;

            // After 256 clocks, publish one sample
            if (pwm_clock_count == 8'd255) begin

                pwm_sample_valid <= 1;

                // Start next PWM measurement period
                pwm_clock_count <= 0;
                pwm_high_count <= 0;

            end else begin

                pwm_clock_count <= pwm_clock_count + 1;

            end
        end
    end

    // =========================================================
    // OPTIONAL WAVEFORM DUMP
    //
    // Comment this entire block out if simulation is still slow.
    // =========================================================

    initial begin
        $dumpfile("tb_audio.fst");

        $dumpvars(0, tb_audio.clk);
        $dumpvars(0, tb_audio.rst_n);

        $dumpvars(0, tb_audio.audio_out);

        $dumpvars(0, tb_audio.fish_caught);
        $dumpvars(0, tb_audio.play_bang);
        $dumpvars(0, tb_audio.play_default);
        $dumpvars(0, tb_audio.play_sleeping);
        $dumpvars(0, tb_audio.play_dead);
        $dumpvars(0, tb_audio.battery_almost_empty);

        $dumpvars(0, tb_audio.pwm_high_count);
        $dumpvars(0, tb_audio.pwm_sample_valid);
    end

endmodule