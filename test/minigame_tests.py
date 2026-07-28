# # SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# # SPDX-License-Identifier: Apache-2.0

import cocotb, logging
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, FallingEdge, Timer
from cocotb.handle import Force, Release

logger = logging.getLogger("important notes")
logger.warning("These tests assume the default parameters are used, e.g. FISH_WIDTH = FISH_HEIGHT = 16, \nCAT_WIDTH = CAT_HEIGHT = 32 and DEFAULT_X = 120, DEFAULT_Y = 300. \nThey also assume the cat's / fish's position is treated as the coordinate of it's upper left corner.")


"""
Performs a reset
"""
async def reset(dut):

    await RisingEdge(dut.clk)
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 1)
    dut.rst_n.value = 1
    

"""
Performs a standard test setup
"""
async def test_setup(dut):
   # Set the clock period to 10 us (100 kHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    dut.cat_pos_x.value = 0
    dut.cat_pos_y.value = 0

    await reset(dut)

    dut._log.info("Setup done")

    

@cocotb.test()
async def test_reset(dut):
    dut._log.info("Testing synchronous reset")

    dut.cat_pos_x.value = 100
    dut.cat_pos_y.value = 200


    # Set the clock period to 10 us (100 kHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())


    # Synchronous reset
    await RisingEdge(dut.clk)
    dut.rst_n.value = 0

    # Should change almost immediately
    await Timer(10, unit="ns")

    # Fish position should be the default position, currently set to (120, 300)
    assert dut.fish_pos_x.value == 120
    assert dut.fish_pos_y.value == 300
    assert dut.fish_caught.value == 0

    await RisingEdge(dut.clk)
    dut.rst_n.value = 1


    # Asynchronous reset
    dut._log.info("Testing asynchronous reset")

    await RisingEdge(dut.clk)
    # Force the fish's position to change, to be able to see the values be reset, same for fish_caught
    dut.fish_pos_x.value = Force(90)
    dut.fish_pos_y.value = Force(95)
    dut.fish_caught.value = Force(1)
    await RisingEdge(dut.clk)

    await ClockCycles(dut.clk, 5)
    await Timer(2, unit="us")          # in the middle of a cycle

    # Release the value, i.e., let them be changed again
    dut.fish_pos_x.value = Release()
    dut.fish_pos_y.value = Release()
    dut.fish_caught.value = Release()

    dut.rst_n.value = 0
    
    # Should change almost immediately
    await Timer(10, unit="ns")
    
    # Fish position should be the default position, currently set to (120, 300)
    assert dut.fish_pos_x.value == 120
    assert dut.fish_pos_y.value == 300
    assert dut.fish_caught.value == 0  

    dut.rst_n.value = 1  

    

@cocotb.test()
async def test_not_caught1(dut):
    await test_setup(dut)

    # Case 1: vis duidelijn niet gevangen
    # After reset: fish position is (120,300)
    await ClockCycles(dut.clk, 5)
    await RisingEdge(dut.clk)
    dut.cat_pos_x.value = 50
    dut.cat_pos_y.value = 20

    await ClockCycles(dut.clk, 1)                       # need to wait for at least 1 clockcycle if fish_caught is a reg
    await FallingEdge(dut.clk)                          # sample on falling edge
    assert dut.fish_caught.value == 0


@cocotb.test()
async def test_not_caught2(dut):
    await test_setup(dut)

    # Case 2: vis steekt 1 pixel uit langs rechts
    await RisingEdge(dut.clk)                           # change inputs on rising edge
    dut.cat_pos_x.value = 103  
    dut.cat_pos_y.value = 300
    
    await ClockCycles(dut.clk, 1)
    await FallingEdge(dut.clk) 
    assert dut.fish_caught.value == 0

@cocotb.test()
async def test_not_caught3(dut):
    await test_setup(dut)

    # Case 3: vis steekt 1 pixel uit langs links
    await RisingEdge(dut.clk)
    dut.cat_pos_x.value = 121
    dut.cat_pos_y.value = 300
    
    await ClockCycles(dut.clk, 1)
    await FallingEdge(dut.clk)
    assert dut.fish_caught.value == 0


@cocotb.test()
async def test_not_caught4(dut):
    await test_setup(dut)

    # Case 4: vis steekt 1 pixel uit langs onder
    await RisingEdge(dut.clk)
    dut.cat_pos_x.value = 120
    dut.cat_pos_y.value = 283
    
    await ClockCycles(dut.clk, 1)
    await FallingEdge(dut.clk)
    assert dut.fish_caught.value == 0


@cocotb.test()
async def test_not_caught5(dut):
    await test_setup(dut)

    # Case 5: vis steekt 1 pixel uit langs boven
    await RisingEdge(dut.clk)
    dut.cat_pos_x.value = 120
    dut.cat_pos_y.value = 301

    await ClockCycles(dut.clk, 1)
    await FallingEdge(dut.clk)
    assert dut.fish_caught.value == 0 


@cocotb.test()
async def test_caught1(dut):
    await test_setup(dut)

    # After reset: fish position is (120,300)
    # Case 1: duidelijk gevangen
    await RisingEdge(dut.clk)
    dut.cat_pos_x.value = 115
    dut.cat_pos_y.value = 295

    await ClockCycles(dut.clk, 1)
    await FallingEdge(dut.clk)              
    assert dut.fish_caught.value == 1

@cocotb.test()
async def test_caught2(dut):
    await test_setup(dut)

    # Case 2: vis net binnen grens langs rechts
    await RisingEdge(dut.clk)
    dut.cat_pos_x.value = 104 
    dut.cat_pos_y.value = 300

    await ClockCycles(dut.clk, 1)
    await FallingEdge(dut.clk)
    assert dut.fish_caught.value == 1


@cocotb.test()
async def test_caught3(dut):
    await test_setup(dut)

    # Case 3: vis net binnen grens langs links
    await RisingEdge(dut.clk)
    dut.cat_pos_x.value = 120
    dut.cat_pos_y.value = 300
    
    await ClockCycles(dut.clk, 1)
    await FallingEdge(dut.clk)
    assert dut.fish_caught.value == 1

@cocotb.test()
async def test_caught4(dut):
    await test_setup(dut)

    # Case 4: vis net binnen grens langs onder
    await RisingEdge(dut.clk)
    dut.cat_pos_x.value = 120
    dut.cat_pos_y.value = 284

    await ClockCycles(dut.clk, 1)
    await FallingEdge(dut.clk)
    assert dut.fish_caught.value == 1

@cocotb.test()
async def test_caught5(dut):
    await test_setup(dut)

    # Case 5: vis binnen grens langs boven
    await RisingEdge(dut.clk)
    dut.cat_pos_x.value = 120
    dut.cat_pos_y.value = 300

    await ClockCycles(dut.clk, 1)
    await FallingEdge(dut.clk)
    assert dut.fish_caught.value == 1


@cocotb.test()
async def test_next_position(dut):
    await test_setup(dut)

    # After reset: fish position is (120,300)

    await ClockCycles(dut.clk, 50)  # wait some time, 50 * 10 us = 500 us = 0.5 seconds

    # catch the fish
    dut.cat_pos_x.value = 115
    dut.cat_pos_y.value = 295

    await ClockCycles(dut.clk, 1)           # fish_caught goes high and fish's position change in the same cycle
    await FallingEdge(dut.clk)              # give the signals some time to change

    # a nice random value gets outputted for the fish's position,
    # changing the 50 clockcycles to another number results in another random position
    dut._log.info(f"fish_pos_x: {dut.fish_pos_x.value.to_unsigned()}")
    dut._log.info(f"fish_pos_y: {dut.fish_pos_y.value.to_unsigned()}")
    assert dut.fish_caught.value == 1

    await ClockCycles(dut.clk,1, rising=False)
    assert dut.fish_caught.value == 0 