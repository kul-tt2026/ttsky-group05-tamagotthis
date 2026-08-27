# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

# cocotb_vga library needed -- https://github.com/kul-tt2026/cocotb-vga

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from cocotb_vga import VGACapture, TinyVGA, VGA_640x480_60

@cocotb.test()
async def test_vga(dut):
    cocotb.start_soon(Clock(dut.clk, 40, "ns").start())  # ~25 MHz pixel clock
    dut.cat_pos_x.value = 200
    dut.cat_pos_y.value = 200
    dut.fish_pos_x.value = 100              # change position of the fish
    dut.fish_pos_y.value = 100
    dut.is_sleeping.value = 0
    dut.is_playing.value = 0
    dut.is_eating.value = 0                # set it to 0 to make the fish dissappear
    dut.is_dead.value = 1
    dut.show_bang.value = 0
    dut.lives_left.value = 9
    dut.battery_left.value = 7
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 1

    cap = VGACapture(dut.clk, TinyVGA(dut.uo_out), VGA_640x480_60,
                     out_dir="output", name="screen").start()
    frames = await cap.wait_for_frames(1)   # blocks until 2 complete frame
    cap.stop()

    # cap.check_timing(require_frames=2)      # raises VGATimingError on violations
    # cap.save_gif()                          # output/myproject.gif
    # frames[0].assert_matches("golden.png")  # golden-image regression (optional) -- need golden.png for it, not in this repo