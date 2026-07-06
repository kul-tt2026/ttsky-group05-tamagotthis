# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import os

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    dut._log.info("Test project behavior")

    # Set the input values you want to test
    dut.ui_in.value = 20
    dut.uio_in.value = 30

    # Wait for one clock cycle to see the output values
    await ClockCycles(dut.clk, 1)

    # The following assersion is just an example of how to check the output values.
    # Change it to match the actual expected output of your module:
    assert dut.uo_out.value == 50

    # Keep testing the module by changing the input values, waiting for
    # one or more clock cycles, and asserting the expected output values.


# Captures VGA frames from uo_out (TinyVGA Pmod pinout) into test/output/ as
# PNGs plus an animated GIF, and checks the sync timing cycle-accurately.
# Enable with `VGA_TEST=1 make -B` once the design drives VGA on uo_out
# (or remove the skip once the template test above is retired).
# A complete working example lives on the `vga-example` branch.
@cocotb.test(skip=os.environ.get("VGA_TEST", "") != "1")
async def test_vga_frames(dut):
    from cocotb_vga import VGA_640x480_60, TinyVGA, VGACapture

    dut._log.info("Start VGA capture test")

    # One sim clock cycle = one pixel; the real period doesn't matter.
    clock = Clock(dut.clk, 40, unit="ns")  # ~25 MHz pixel clock
    cocotb.start_soon(clock.start())

    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    cap = VGACapture(dut.clk, TinyVGA(dut.uo_out), VGA_640x480_60,
                     out_dir="output", name="tamagotthis").start()
    frames = await cap.wait_for_frames(2)
    cap.stop()

    cap.check_timing(require_frames=2)
    cap.save_gif(duration_ms=100)
    dut._log.info("%s", cap.report())

    # Once you have a known-good frame, commit it and enable golden-image
    # regression:
    # frames[0].assert_matches("golden_frame0.png",
    #                          diff_path="output/golden_diff.png")
    assert frames
