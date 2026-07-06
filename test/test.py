# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

"""Example: verifying a VGA design with cocotb-vga (lib/cocotb-vga).

The design under test (src/project.v) renders the cocotb-vga reference
pattern - 8 color bars shifting one position per frame - on the TinyVGA
Pmod pinout, so this test can check every captured pixel against a known
image. For a real design you would keep the capture + check_timing part
and compare against committed golden frames (frame.assert_matches) or
model your design's expected output the same way cocotb_vga.pattern does.

Captured frames, an animated GIF, and (on mismatch) diff images are
written to test/output/.
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

from cocotb_vga import VGA_640x480_60, TinyVGA, VGACapture
from cocotb_vga.pattern import detect_phase, expected_frame


@cocotb.test()
async def test_vga_frames(dut):
    dut._log.info("Start")

    # One clock cycle = one pixel; the simulated period is irrelevant.
    clock = Clock(dut.clk, 40, unit="ns")  # ~25 MHz pixel clock
    cocotb.start_soon(clock.start())

    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    # Capture two complete frames (each is 800x525 = 420k cycles).
    cap = VGACapture(dut.clk, TinyVGA(dut.uo_out), VGA_640x480_60,
                     out_dir="output", name="vga_example").start()
    frames = await cap.wait_for_frames(2)
    cap.stop()

    # Sync periods, pulse widths and alignment, cycle-exact.
    cap.check_timing(require_frames=2)
    cap.save_gif(duration_ms=250)
    dut._log.info("%s", cap.report())

    # The DUT draws the library's reference pattern, so every pixel is
    # known: find which phase frame 0 shows, then require each frame to
    # match exactly and to advance the pattern by one bar per frame.
    phase = detect_phase(frames[0].data, VGA_640x480_60)
    assert phase is not None, \
        "frame 0 is not the expected color-bar pattern; see test/output/"
    for i, frame in enumerate(frames):
        frame.assert_matches(expected_frame(VGA_640x480_60, phase + i),
                             diff_path=f"output/vga_example_diff_{i}.png")
