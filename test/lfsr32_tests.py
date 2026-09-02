# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, FallingEdge


@cocotb.test()
async def test_reset(dut):
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Seed is the SEED parameter of the DUT: (1 << 31) | 1

    # Reset
    await RisingEdge(dut.clk) 
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 1)
    dut.rst_n.value = 1

    await ClockCycles(dut.clk, 1)
    await FallingEdge(dut.clk) # sample on falling edge 

    # bits should be set to 0x 8000 0001 on reset, 
    # after one clockcycle, x and y should be the following: x = 0b0000000001, y = 0b1000000000
    assert dut.s1.value == 0b0000000001
    assert dut.s2.value == 0b1000000000

@cocotb.test()
async def test_one_cyle(dut):

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())
    # Seed is the SEED parameter of the DUT: (1 << 31) | 1

    # Reset
    await RisingEdge(dut.clk)
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 1)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1)
    await FallingEdge(dut.clk) # sample on falling edge 

    # Sample some x and y values and print them
    dut._log.info(f"x1 (binary) : {str(dut.s1.value)}") # 0000000001
    dut._log.info(f"y1 (binary) : {str(dut.s2.value)}") # 1000000000
    x1 = dut.s1.value.to_unsigned()
    y1 = dut.s2.value.to_unsigned()

    await ClockCycles(dut.clk, 1, rising=False)         
    # add rising=False, otherwise it just waits for a rising edge, instead of a whole cycle

    dut._log.info(f"x2 (binary) : {str(dut.s1.value)}") # 0000000000
    dut._log.info(f"y2 (binary) : {str(dut.s2.value)}") # 1100000000
    x2 = dut.s1.value.to_unsigned()
    y2 = dut.s2.value.to_unsigned()

    assert x1 != x2
    assert y1 != y2



@cocotb.test()
async def test_multiple_cyles(dut):

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())
    # Seed is the SEED parameter of the DUT: (1 << 31) | 1

    # Reset
    await RisingEdge(dut.clk)
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 1)
    dut.rst_n.value = 1

    # await RisingEdge(dut.clk)
    await ClockCycles(dut.clk, 40)
    await FallingEdge(dut.clk) # sample on falling edge 

    dut._log.info(f"x1 (binary) : {str(dut.s1.value)} ---- (decimal) : {dut.s1.value.to_unsigned()}")
    dut._log.info(f"y1 (binary) : {str(dut.s2.value)} ---- (decimal) : {dut.s2.value.to_unsigned()}")
    x1 = dut.s1.value.to_unsigned()
    y1 = dut.s2.value.to_unsigned()

    await ClockCycles(dut.clk, 1, rising=False)
    dut._log.info("Waited 1 clock cycle")

    dut._log.info(f"x2 (binary) : {str(dut.s1.value)} ---- (decimal) : {dut.s1.value.to_unsigned()}") 
    dut._log.info(f"y2 (binary) : {str(dut.s2.value)} ---- (decimal) : {dut.s2.value.to_unsigned()}") 
    x2 = dut.s1.value.to_unsigned()
    y2 = dut.s2.value.to_unsigned()

    await ClockCycles(dut.clk, 1, rising=False)
    dut._log.info("Waited 1 clock cycle")

    dut._log.info(f"x3 (binary) : {str(dut.s1.value)} ---- (decimal) : {dut.s1.value.to_unsigned()}") 
    dut._log.info(f"y3 (binary) : {str(dut.s2.value)} ---- (decimal) : {dut.s2.value.to_unsigned()}") 
    x3 = dut.s1.value.to_unsigned()
    y3 = dut.s2.value.to_unsigned()

    assert x1 != x2 and x2 != x3
    assert y1 != y2 and y2 != y3


@cocotb.test()
async def test_different_seed(dut):

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())
    # Seed is the SEED parameter of lfsr_dut_alt: 1 << 31 | 46841250 -- gives 10000010110010101011110110100010

    # Reset
    await RisingEdge(dut.clk)
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 1)
    dut.rst_n.value = 1

    await ClockCycles(dut.clk,1)
    await FallingEdge(dut.clk) # sample on falling edge 
    dut._log.info("Initial values")
    dut._log.info(f"x1 (binary) : {str(dut.s1_alt.value)}") 
    dut._log.info(f"y1 (binary) : {str(dut.s2_alt.value)}") 
    x1 = dut.s1_alt.value.to_unsigned()
    y1 = dut.s2_alt.value.to_unsigned()

    assert dut.s1_alt.value == 0b0110100010
    assert dut.s2_alt.value == 0b1000001011
    
    await RisingEdge(dut.clk)
    await ClockCycles(dut.clk, 1)

    dut._log.info("Values after 1 clock cycle")
    dut._log.info(f"x2 (binary) : {str(dut.s1_alt.value)}") # 0000000000
    dut._log.info(f"y2 (binary) : {str(dut.s2_alt.value)}") # 1100000000
    x2 = dut.s1_alt.value.to_unsigned()
    y2 = dut.s2_alt.value.to_unsigned()

    assert x1 != x2
    assert y1 != y2