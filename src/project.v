/*
 * Copyright (c) 2026 Group 05
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

// Example design: 640x480@60 VGA color bars on the TinyVGA Pmod pinout.
//
// Renders the cocotb-vga reference pattern (8 vertical bars, shifting one
// position per frame) so the testbench can verify every captured pixel
// against a known image; see test/test.py.
module tt_um_vga_example (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // pixel clock, nominally 25.175 MHz
    input  wire       rst_n     // reset_n - low to reset
);

  localparam H_ACTIVE = 640, H_FRONT = 16, H_SYNC = 96, H_BACK = 48;
  localparam V_ACTIVE = 480, V_FRONT = 10, V_SYNC = 2, V_BACK = 33;
  localparam H_TOTAL = H_ACTIVE + H_FRONT + H_SYNC + H_BACK;  // 800
  localparam V_TOTAL = V_ACTIVE + V_FRONT + V_SYNC + V_BACK;  // 525
  localparam BAR_WIDTH = H_ACTIVE / 8;  // 80

  reg [9:0] hcnt;
  reg [9:0] vcnt;
  reg [2:0] frame_cnt;  // pattern phase, wraps mod 8
  reg [6:0] bar_pix;    // position inside the current bar (divide-free hcnt/80)
  reg [2:0] bar;        // bar index under the beam, only used while hcnt < H_ACTIVE

  wire line_end = (hcnt == H_TOTAL - 1);

  always @(posedge clk) begin
    if (!rst_n) begin
      hcnt      <= 0;
      vcnt      <= 0;
      frame_cnt <= 0;
      bar_pix   <= 0;
      bar       <= 0;
    end else if (line_end) begin
      hcnt    <= 0;
      bar_pix <= 0;
      bar     <= 0;
      if (vcnt == V_TOTAL - 1) begin
        vcnt      <= 0;
        frame_cnt <= frame_cnt + 1;
      end else begin
        vcnt <= vcnt + 1;
      end
    end else begin
      hcnt <= hcnt + 1;
      if (bar_pix == BAR_WIDTH - 1) begin
        bar_pix <= 0;
        bar     <= bar + 1;
      end else begin
        bar_pix <= bar_pix + 1;
      end
    end
  end

  wire active = (hcnt < H_ACTIVE) && (vcnt < V_ACTIVE);
  wire hs = (hcnt >= H_ACTIVE + H_FRONT) && (hcnt < H_ACTIVE + H_FRONT + H_SYNC);
  wire vs = (vcnt >= V_ACTIVE + V_FRONT) && (vcnt < V_ACTIVE + V_FRONT + V_SYNC);

  wire [2:0] bar_phase = bar + frame_cnt;  // 3-bit add = mod 8

  reg [5:0] rgb;  // {r[1:0], g[1:0], b[1:0]}
  always @* begin
    if (!active) rgb = 6'b00_00_00;
    else
      case (bar_phase)
        3'd0: rgb = 6'b11_11_11;  // white
        3'd1: rgb = 6'b11_11_00;  // yellow
        3'd2: rgb = 6'b00_11_11;  // cyan
        3'd3: rgb = 6'b00_11_00;  // green
        3'd4: rgb = 6'b11_00_11;  // magenta
        3'd5: rgb = 6'b11_00_00;  // red
        3'd6: rgb = 6'b00_00_11;  // blue
        default: rgb = 6'b00_01_01;  // dark teal (distinguishable from blanking)
      endcase
  end

  // Registered outputs on the TinyVGA Pmod pinout; 640x480@60 sync
  // polarity is negative (asserted = low).
  reg [7:0] uo;
  always @(posedge clk) begin
    if (!rst_n) uo <= 8'b1000_1000;  // syncs deasserted, black
    else uo <= {~hs, rgb[0], rgb[2], rgb[4], ~vs, rgb[1], rgb[3], rgb[5]};
  end

  assign uo_out  = uo;
  assign uio_out = 0;
  assign uio_oe  = 0;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, ui_in, uio_in, 1'b0};

endmodule
