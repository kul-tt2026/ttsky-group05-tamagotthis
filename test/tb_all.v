`default_nettype none
`timescale 1ns / 1ps

/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/
module tb_all ();

  // Dump the signals to a FST file. You can view it with gtkwave or surfer.
  initial begin
    $dumpfile("tb_all.fst");
    $dumpvars(0, tb_all);
    #1;
  end

  // Wire up the inputs and outputs:
  reg clk;
  reg rst_n;
  reg ena;
  reg [7:0] ui_in;
  reg [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;
`ifdef GL_TEST
  wire VPWR = 1'b1;
  wire VGND = 1'b0;
`endif

  // Replace tt_um_example with your module name:
  tt_um_tamagotchi user_project (

      // Include power ports for the Gate Level test:
`ifdef GL_TEST
      .VPWR(VPWR),
      .VGND(VGND),
`endif

      .ui_in  (ui_in),    // Dedicated inputs
      .uo_out (uo_out),   // Dedicated outputs
      .uio_in (uio_in),   // IOs: Input path
      .uio_out(uio_out),  // IOs: Output path
      .uio_oe (uio_oe),   // IOs: Enable path (active high: 0=input, 1=output)
      .ena    (ena),      // enable - goes high when design is selected
      .clk    (clk),      // clock
      .rst_n  (rst_n)     // not reset
  );

endmodule

module tb_main_controller ();

  // Dump the signals to a FST file. You can view it with gtkwave or surfer.
  initial begin
    $dumpfile("tb_main_controller.fst");
    $dumpvars(0, tb_main_controller);
    #1;
  end

  // Wire up the inputs and outputs:
  reg reset, clk;
  reg left, right, up, down, A, B, X, Y;
  reg is_sleeping, fish_caught, is_playing, is_dead, is_eating, show_bang, deplete_battery;
  reg [9:0] cat_pos_x;
  reg [8:0] cat_pos_y;
  reg [3:0] lives_left, battery_left;

  // Replace tt_um_example with your module name:
  main_controller main_controller_dut (
      .reset(reset),
      .clk(clk),
      .left(left),
      .right(right),
      .up(up),
      .down(down),
      .A(A),
      .B(B),
      .X(X),
      .Y(Y),
      .is_sleeping(is_sleeping),
      .fish_caught(fish_caught),
      .is_playing(is_playing),
      .is_dead(is_dead),
      .is_eating(is_eating),
      .show_bang(show_bang),
      .deplete_battery(deplete_battery),
      .cat_pos_x(cat_pos_x),
      .cat_pos_y(cat_pos_y),
      .lives_left(lives_left),
      .battery_left(battery_left)
  );
  
endmodule

module tb_timer ();

  // Dump the signals to a FST file. You can view it with gtkwave or surfer.
  initial begin
    $dumpfile("tb_timer.fst");
    $dumpvars(0, tb_timer);
    #1;
  end

  // Wire up the inputs and outputs:
  reg clk;
  reg reset;
  reg is_sleeping, caught_fish, is_playing;
  wire deplete_battery;

  // Replace tt_um_example with your module name:
  timer timer_dut (
      .reset(reset),
      .clk(clk),
      .is_sleeping(is_sleeping),
      .caught_fish(caught_fish),
      .is_playing(is_playing),
      .deplete_battery(deplete_battery)
  );

endmodule