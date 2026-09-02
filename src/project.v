/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

/*
 * This is the main module of the project.
 * It defines the different submodules/blocks and interconnects them. It also provides them with in and outputs.
 */
module tt_um_tamagotchi (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  wire gamepad_pmod_latch = ui_in[4];
  wire gamepad_pmod_clk = ui_in[5];
  wire gamepad_pmod_data = ui_in[6];
  wire gamepad_left;
  wire gamepad_right;
  wire gamepad_up;
  wire gamepad_down;
  wire gamepad_a;
  wire gamepad_b;
  wire gamepad_x;
  wire gamepad_y;
  wire gamepad_select; // Allows you to select certain settings.

  wire [9:0] cat_pos_x, cat_pos_y;
  wire [3:0] lives_left;
  wire [2:0] battery_left;
  wire battery_almost_empty, deplete_battery, fish_caught, is_eating, show_bang, is_dead, is_sleeping, is_playing, is_default_state;
  wire play_bang, play_default, play_dead, play_playing, play_sleeping;
  wire cat_mirrored;

  // vga
  wire [9:0] fish_pos_x, fish_pos_y;
  wire [1:0] R, G, B;
  wire hsync, vsync;
 
  // audio
  wire audio_out;

  gamepad_pmod_single gamepad_pmod (
      // Inputs:
      .clk(clk),
      .rst_n(rst_n),
      .pmod_latch(gamepad_pmod_latch),
      .pmod_clk(gamepad_pmod_clk),
      .pmod_data(gamepad_pmod_data),

      // Outputs:
      .left(gamepad_left),
      .right(gamepad_right),
      .up(gamepad_up),
      .down(gamepad_down),
      .a(gamepad_a),
      .b(gamepad_b),
      .x(gamepad_x),
      .y(gamepad_y),
      .select(gamepad_select)
  );

  // Slow processes: everything is clocked by clk. The slower rates are clock enables ("ticks", one clk
  // cycle wide) derived from vsync, so the whole chip is a single clock domain for timing analysis.
  // (Clocking flops from divider outputs left 120 registers untimed by STA.)
  wire timing_option; // 0: slow timing, 1: fast timing.
  wire [35:0] slow_clocks;              // counts frames (vsync pulses, 60 Hz): bit k toggles every 2^k frames.
  wire tick_main_controller, clk_timer;

  reg vsync_d, slow_clock_1_d;
  always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      vsync_d <= 1'b1;        // vsync is active low and idles high: no spurious frame at reset release.
      slow_clock_1_d <= 1'b0;
    end else begin
      vsync_d <= vsync;
      slow_clock_1_d <= slow_clocks[1];
    end
  end
  wire vsync_rise = vsync & ~vsync_d;                                           // one clk pulse per frame.

  clock_divider #(.DIVIDER_MSB(35)) clock_divider(.rst_n(rst_n),
                                                  .clk(clk),
                                                  .tick(vsync_rise),
                                                  .slow_clocks(slow_clocks));

  assign tick_main_controller = slow_clocks[1] & ~slow_clock_1_d;              // one clk pulse every 4 frames (+- 15Hz).
  assign clk_timer = timing_option ? slow_clocks[7] : slow_clocks[7 + 6]; // level, sampled on tick_main_controller: 4 minutes in slow mode, 4 seconds in fast mode. 
  
  settings_manager #(.SETTINGS_COUNT(1), .OPTIONS_COUNT(2)) settings_manager(.rst_n(rst_n),
                                                                             .clk(clk),
                                                                             .change_settings(gamepad_select),
                                                                             .inputs(gamepad_a),
                                                                             .settings(timing_option));

  timer timer(.rst_n(rst_n),
              .clk(clk),
              .tick(tick_main_controller),
              .slow_clk(clk_timer),
              .is_sleeping(is_sleeping),
              .is_playing(is_playing),
              .caught_fish(fish_caught),
              .deplete_battery(deplete_battery));
 
  main_controller main_controller(
      .rst_n(rst_n),
      .clk(clk),
      .tick(tick_main_controller),
      .slow_clk(clk_timer),
      .left(gamepad_left),
      .right(gamepad_right),
      .up(gamepad_up),
      .down(gamepad_down),
      .A(gamepad_a),
      .B(gamepad_b),
      .X(gamepad_x),
      .Y(gamepad_y),
      .deplete_battery(deplete_battery),
      .fish_caught(fish_caught),
      .cat_pos_x(cat_pos_x),
      .cat_pos_y(cat_pos_y),
      .lives_left(lives_left),
      .battery_left(battery_left),
      .battery_almost_empty(battery_almost_empty),
      .is_eating(is_eating),
      .show_bang(show_bang),
      .is_dead(is_dead),
      .is_sleeping(is_sleeping),
      .is_playing(is_playing),
      .is_default_state(is_default_state),
      .play_bang(play_bang),
      .play_default(play_default),
      .play_dead(play_dead),
      .play_playing(play_playing),
      .play_sleeping(play_sleeping),
      .cat_mirrored(cat_mirrored)
  );

  minigame minigame (
      .rst_n(rst_n),
      .clk(clk),
      .tick(tick_main_controller),
      .clk2(clk),
      .is_eating(is_eating),
      .cat_pos_x(cat_pos_x),
      .cat_pos_y(cat_pos_y),
      .fish_pos_x(fish_pos_x),
      .fish_pos_y(fish_pos_y),
      .fish_caught(fish_caught)
  );

  vga vga(
    .clk(clk),
    .tick(tick_main_controller),
    .rst_n(rst_n),
    .cat_pos_x(cat_pos_x),
    .cat_pos_y(cat_pos_y),
    .fish_pos_x(fish_pos_x),
    .fish_pos_y(fish_pos_y),
    .is_sleeping(is_sleeping),
    .is_playing(is_playing),
    .is_eating(is_eating),
    .is_dead(is_dead),
    .show_bang(show_bang),
    .cat_mirrored(cat_mirrored),
    .battery_left(battery_left),
    .lives_left(lives_left),
    .hsync(hsync),
    .vsync(vsync),
    .R(R),
    .G(G),
    .B(B)
  );

  audio audio(
    .clk(clk),
    .rst_n(rst_n),
    .fish_caught(fish_caught),
    .play_bang(play_bang),
    .play_default(play_default),
    .play_sleeping(play_sleeping),
    .play_dead(play_dead),
    .battery_almost_empty(battery_almost_empty),
    .audio_out(audio_out)
  );
 
  // All output pins must be assigned. If not used, assign to 0.
  // assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]}; -- this caused errors, so it's split up into multiple lines
  assign uo_out[7] = hsync;
  assign uo_out[6] = B[0];
  assign uo_out[5] = G[0];
  assign uo_out[4] = R[0];
  assign uo_out[3] = vsync;
  assign uo_out[2] = B[1];
  assign uo_out[1] = G[1];
  assign uo_out[0] = R[1];


  assign uio_out[6:0] = 7'b0;
  assign uio_out[7] = audio_out;              // the audio pmod is designed to use uio_out[7] (or uio_out[7])
  assign uio_oe = 8'b10000000;                // only uio_out[7] as output

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, ui_in[3:0], ui_in[7], uio_in, 1'b0};
endmodule