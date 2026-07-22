# # SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# # SPDX-License-Identifier: Apache-2.0

import cocotb, logging
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, Timer

logger = logging.getLogger("important notes")
logger.warning("These tests assume the default parameters are used, e.g. FISH_WIDTH = FISH_HEIGHT = 16, \nCAT_WIDTH = CAT_HEIGHT = 32 and DEFAULT_X = 120, DEFAULT_Y = 300. \nThey also assume the cat's / fish's position is treated as the coordinate of it's upper left corner.")

@cocotb.test()
async def test_reset(dut):
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    dut.cat_pos_x.value = 100
    dut.cat_pos_y.value = 200

    # Reset
    await RisingEdge(dut.clk) # wait for rising edge, otherwise you say wait 5 cycles and it may end up waiting only 4, due to race condtions
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 1)
    dut.rst_n.value = 1

    # Fish position should be the default position, currently set to (120, 300)
    assert dut.fish_pos_x.value == 120
    assert dut.fish_pos_y.value == 300
    assert dut.fish_caught.value == 0


@cocotb.test()
async def test_fish_not_caught(dut):

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Reset
    await RisingEdge(dut.clk)
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 1)
    dut.rst_n.value = 1

    # After reset: fish position is (120,300)
    await ClockCycles(dut.clk, 5)

    # Case 0: vis duidelijn niet gevangen
    dut.cat_pos_x.value = 50
    dut.cat_pos_y.value = 20

    await Timer(1, unit="ns")                           # have to wait a bit to give time to evaluate new inputs
    assert dut.fish_caught.value == 0

    # Case 1: vis steekt 1 pixel uit langs rechts
    dut.cat_pos_x.value = 103  
    dut.cat_pos_y.value = 300

    await Timer(1, unit="ns")
    assert dut.fish_caught.value == 0

    # Case 2: vis steekt 1 pixel uit langs links
    dut.cat_pos_x.value = 121
    dut.cat_pos_y.value = 300

    await Timer(1, unit="ns")
    assert dut.fish_caught.value == 0

    # Case 3: vis steekt 1 pixel uit langs onder
    dut.cat_pos_x.value = 120
    dut.cat_pos_y.value = 283

    await Timer(1, unit="ns")
    assert dut.fish_caught.value == 0


    # Case 4: vis steekt 1 pixel uit langs boven
    dut.cat_pos_x.value = 120
    dut.cat_pos_y.value = 301

    await Timer(1, unit="ns")
    assert dut.fish_caught.value == 0 


@cocotb.test()
async def test_fish_caught(dut):

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Reset
    await RisingEdge(dut.clk)
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 1)
    dut.rst_n.value = 1

    # After reset: fish position is (120,300)
    await ClockCycles(dut.clk, 5)

    # Case 0: duidelijk gevangen
    dut.cat_pos_x.value = 115
    dut.cat_pos_y.value = 295

    await Timer(1, unit="ns")
    assert dut.fish_caught.value == 1


    # Case 1: vis net binnen grens langs rechts
    dut.cat_pos_x.value = 104 
    dut.cat_pos_y.value = 300

    await Timer(1, unit="ns")
    assert dut.fish_caught.value == 1

    # Case 2: vis net binnen grens langs links
    dut.cat_pos_x.value = 120
    dut.cat_pos_y.value = 300

    await Timer(1, unit="ns")
    assert dut.fish_caught.value == 1

    # Case 3: vis net binnen grens langs onder
    dut.cat_pos_x.value = 120
    dut.cat_pos_y.value = 284

    await Timer(1, unit="ns")
    assert dut.fish_caught.value == 1


    # Case 4: vis binnen grens langs boven
    dut.cat_pos_x.value = 120
    dut.cat_pos_y.value = 300

    await Timer(1, unit="ns")
    assert dut.fish_caught.value == 1


@cocotb.test()
async def test_next_position(dut):

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Reset
    await RisingEdge(dut.clk)               
    # note: can take up to 10 us, so if the simulation ends before that, code after this line never gets executed
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 1)
    dut.rst_n.value = 1
    # After reset: fish position is (120,300)

    await ClockCycles(dut.clk, 50)  # wait some time, 50 * 10 us = 500 us = 0.5 seconds

    # catch the fish
    dut.cat_pos_x.value = 115
    dut.cat_pos_y.value = 295

    await ClockCycles(dut.clk, 1)
    await Timer(1, unit="ns")       # give the signals some time to change

    # a nice random value gets outputted for the fish's position,
    # changing the 50 clockcycles to another number results in another random position
    dut._log.info(f"fish_pos_x: {dut.fish_pos_x.value.to_unsigned()}")
    dut._log.info(f"fish_pos_y: {dut.fish_pos_y.value.to_unsigned()}")

    assert dut.fish_caught.value == 0 