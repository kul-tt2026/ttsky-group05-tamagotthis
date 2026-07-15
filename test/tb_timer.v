`default_nettype none
`timescale 1ns / 1ps

/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/
module tb_timer ();

  // Dump the signals to a FST file. You can view it with gtkwave or surfer.
  initial begin
    $dumpfile("tb.fst");
    $dumpvars(0, tb);
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