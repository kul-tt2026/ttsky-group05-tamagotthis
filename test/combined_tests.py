# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
# from cocotb_vga import VGACapture, TinyVGA, VGA_640x480_60 -- commented out to prevent CI errors

# A file to test the entire tamagotchi.

@cocotb.test()
async def test_to_avoid_crashing(dut):
    pass

# Sets the cat somewhere on the screen, puts it in the sleeping state and checks if the output is as expected.
# @cocotb.test()
async def proper_vga_output(dut):
    cocotb.start_soon(Clock(dut.clk, 40, "ns").start())  # ~25 MHz pixel clock

    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.ena.value = 0

    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

    # dut.user_project.main_controller.cat_pos_x.value = 200
    # dut.user_project.main_controller.cat_pos_y.value = 200
    # dut.user_project.main_controller.State.value = 3
    # dut.user_project.main_controller.lives_left.value = 9
    # dut.user_project.main_controller.battery_left.value = 7
    # dut.user_project.main_controller.cat_mirrored.value = 0

    # dut.user_project.main_controller.clk.value = 0
    # await ClockCycles(dut.clk, 2)
    # dut.user_project.main_controller.clk.value = 1
    # await ClockCycles(dut.clk, 2)
    # dut.user_project.main_controller.clk.value = 0
    # await ClockCycles(dut.clk, 2)

    # assert dut.user_project.is_sleeping.value == 1

    # cap = VGACapture(dut.clk, TinyVGA(dut.uo_out), VGA_640x480_60,
    #                  out_dir="output", name="sleeping_expected").start()
    # frames = await cap.wait_for_frames(1)   # blocks until 2 complete frame
    # cap.stop()