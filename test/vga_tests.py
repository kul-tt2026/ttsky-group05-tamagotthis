# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from cocotb_vga import VGACapture, TinyVGA, VGA_640x480_60

@cocotb.test()
async def test_vga(dut):
    dut._log.info("in test")
    cocotb.start_soon(Clock(dut.clk, 40, "ns").start())  # ~25 MHz pixel clock
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 1

    cap = VGACapture(dut.clk, TinyVGA(dut.uo_out), VGA_640x480_60,
                     out_dir="output", name="myproject").start()
    frames = await cap.wait_for_frames(1)   # blocks until 1 complete frame
    cap.stop()

    # cap.check_timing(require_frames=2)      # raises VGATimingError on violations
    # cap.save_gif()                          # output/myproject.gif
    # frames[0].assert_matches("golden.png")  # golden-image regression (optional)
    dut._log.info("test complete")