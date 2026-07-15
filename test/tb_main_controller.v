`default_nettype none
`timescale 1ns / 1ps

/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/
module tb_main_controller ();

  // Dump the signals to a FST file. You can view it with gtkwave or surfer.
  initial begin
    $dumpfile("tb.fst");
    $dumpvars(0, tb);
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
