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

  // -------------------------------------- game + main controller -----------------------------------
  
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

 
  wire deplete_battery = ui_in[7];
  wire fish_caught = ui_in[3];

  wire [9:0] cat_pos_x, cat_pos_y;
  reg [3:0] lives_left;
  reg [2:0] battery_left;
  wire battery_almost_empty, is_eating, show_bang, is_dead, is_sleeping, is_playing, is_default_state;
  wire play_bang, play_default, play_dead, play_playing, play_sleeping;
 

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
      .start(),
      .select(),
      .l(),
      .r(),
      .is_present()
  );



  main_controller main_controller(
      .rst_n(rst_n),
      .clk(clk),
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
      .play_sleeping(play_sleeping)
  );

  // -------------------------------------------- VGA -----------------------------------------------
  wire [1:0] red;
  wire [1:0] green;
  wire [1:0] blue;

  wire hsync, vsync;

  vga vga_inst (
      .rst_n(rst_n),
      .clk(clk),
      .cat_pos_x(10'd0),
      .fish_pos_x(10'd100),
      .cat_pos_y(10'd0),
      .fish_pos_y(10'd100),
      .is_sleeping(1'b0),
      .is_playing(1'b0),
      .is_eating(1'b0),
      .is_dead(1'b0),
      .show_bang(1'b0),
      .lives_left(lives_left),
      .battery_left(battery_left),
      .hsync(hsync),
      .vsync(vsync),
      .R(red),
      .G(green),
      .B(blue),
      .uo_out(uo_out)
  );

  assign uio_out = 0;
  assign uio_oe  = 0;

  wire _unused = &{ena, ui_in, uio_in, red, green, blue, 1'b0};

endmodule
