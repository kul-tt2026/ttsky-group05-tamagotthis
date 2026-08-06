`ifndef HVSYNC_GENERATOR_H          // prevent multiple inclusions of this file     
`define HVSYNC_GENERATOR_H

// 
// code copied from https://vga-playground.com 

/*
Video sync generator, used to drive a VGA monitor.
Timing from: https://en.wikipedia.org/wiki/Video_Graphics_Array
To use:
- Wire the hsync and vsync signals to top level outputs
- Add a 3-bit (or more) "rgb" output to the top level
*/


module hvsync_generator (
    input wire clk,
    input wire reset,
    output reg hsync,
    output reg vsync,
    output wire display_on,
    output reg [9:0] hpos,
    output reg [9:0] vpos
);

  // Horizontal constants (640x480 @ 60Hz standard)
  parameter H_DISPLAY    = 640;
  parameter H_FRONT      = 16;
  parameter H_SYNC       = 96;
  parameter H_BACK       = 48;
  
  // Vertical constants
  parameter V_DISPLAY    = 480;
  parameter V_BOTTOM     = 10;
  parameter V_SYNC       = 2;
  parameter V_TOP        = 33;

  // Derived constants
  parameter H_SYNC_START = H_DISPLAY + H_FRONT;                 // 656
  parameter H_SYNC_END   = H_DISPLAY + H_FRONT + H_SYNC - 1;    // 751
  parameter H_MAX        = H_DISPLAY + H_FRONT + H_SYNC + H_BACK - 1; // 799

  parameter V_SYNC_START = V_DISPLAY + V_BOTTOM;                // 490
  parameter V_SYNC_END   = V_DISPLAY + V_BOTTOM + V_SYNC - 1;   // 491
  parameter V_MAX        = V_DISPLAY + V_BOTTOM + V_SYNC + V_TOP - 1; // 524

  wire hmaxxed = (hpos == H_MAX);
  wire vmaxxed = (vpos == V_MAX);

  // Horizontal position counter & sync
  always @(posedge clk) begin
    if (reset) begin
      hpos  <= 10'd0;
      hsync <= 1'b1;
    end else begin
      if (hmaxxed)
        hpos <= 10'd0;
      else
        hpos <= hpos + 1'b1;

      // Active-low sync pulse during sync interval
      hsync <= ~((hpos >= H_SYNC_START) && (hpos <= H_SYNC_END));
    end
  end

  // Vertical position counter & sync
  always @(posedge clk) begin
    if (reset) begin
      vpos  <= 10'd0;
      vsync <= 1'b1;
    end else begin
      if (hmaxxed) begin
        if (vmaxxed)
          vpos <= 10'd0;
        else
          vpos <= vpos + 1'b1;
      end

      // Active-low sync pulse during sync interval
      vsync <= ~((vpos >= V_SYNC_START) && (vpos <= V_SYNC_END));
    end
  end

  // Active display area indicator
  assign display_on = (hpos < H_DISPLAY) && (vpos < V_DISPLAY);

endmodule

`endif
