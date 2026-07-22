# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge


@cocotb.test()
async def test_reset(dut):
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Set seed value
    dut.seed.value = (1 << 31) | 1

    # Reset
    await RisingEdge(dut.clk) # wait for rising edge, otherwise you say wait 5 cycles and it may end up waiting only 4, due to race condtions
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 1)
    dut.rst_n.value = 1

    # bits should be set to 0x 8000 0001 --> x = 0b0000000001, y = 0b1000000000
    assert dut.x.value == 0b0000000001
    assert dut.y.value == 0b1000000000

@cocotb.test()
async def test_one_cyle(dut):

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())
    # Set seed value
    dut.seed.value = (1 << 31) | 1

    # Reset
    await RisingEdge(dut.clk)
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 1)
    dut.rst_n.value = 1

    # Sample some x and y values and print them
    await RisingEdge(dut.clk)
    dut._log.info(f"x1 (binary) : {str(dut.x.value)}") # 0000000001
    dut._log.info(f"y1 (binary) : {str(dut.y.value)}") # 1000000000
    x1 = dut.x.value
    y1 = dut.y.value

    await ClockCycles(dut.clk, 1)

    dut._log.info(f"x2 (binary) : {str(dut.x.value)}") # 0000000000
    dut._log.info(f"y2 (binary) : {str(dut.y.value)}") # 1100000000
    x2 = dut.x.value
    y2 = dut.y.value

    assert int(x1) != int(x2)
    assert int(y1) != int(y2)



@cocotb.test()
async def test_multiple_cyles(dut):

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())
    # Set seed value
    dut.seed.value = (1 << 31) | 1

    # Reset
    await RisingEdge(dut.clk)
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 1)
    dut.rst_n.value = 1

    await RisingEdge(dut.clk)
    await ClockCycles(dut.clk, 40)

    dut._log.info(f"x1 (binary) : {str(dut.x.value)} ---- (decimal) : {dut.x.value.to_unsigned()}")
    dut._log.info(f"y1 (binary) : {str(dut.y.value)} ---- (decimal) : {dut.y.value.to_unsigned()}")
    x1 = dut.x.value
    y1 = dut.y.value

    await ClockCycles(dut.clk, 1)
    dut._log.info("Waited 1 clock cycle")

    dut._log.info(f"x2 (binary) : {str(dut.x.value)} ---- (decimal) : {dut.x.value.to_unsigned()}") 
    dut._log.info(f"y2 (binary) : {str(dut.y.value)} ---- (decimal) : {dut.y.value.to_unsigned()}") 
    x2 = dut.x.value
    y2 = dut.y.value

    await ClockCycles(dut.clk, 1)
    dut._log.info("Waited 1 clock cycle")

    dut._log.info(f"x3 (binary) : {str(dut.x.value)} ---- (decimal) : {dut.x.value.to_unsigned()}") 
    dut._log.info(f"y3 (binary) : {str(dut.y.value)} ---- (decimal) : {dut.y.value.to_unsigned()}") 
    x3 = dut.x.value
    y3 = dut.y.value

    assert int(x1) != int(x2) and int(x2) != int(x3)
    assert int(y1) != int(y2) and int(y2) != int(y3)


@cocotb.test()
async def test_different_seed(dut):

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())
    # Set seed value
    dut.seed.value = 1 << 31 | 46841250 # randomly chosen -- gives 10000010110010101011110110100010

    # Reset
    await RisingEdge(dut.clk)
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 1)
    dut.rst_n.value = 1

    dut._log.info("Initial values")
    dut._log.info(f"x1 (binary) : {str(dut.x.value)}") 
    dut._log.info(f"y1 (binary) : {str(dut.y.value)}") 
    x1 = dut.x.value
    y1 = dut.y.value

    assert dut.x.value == 0b0110100010
    assert dut.y.value == 0b1000001011
    
    await RisingEdge(dut.clk)
    await ClockCycles(dut.clk, 1)

    dut._log.info("Values after 1 clock cycle")
    dut._log.info(f"x2 (binary) : {str(dut.x.value)}") # 0000000000
    dut._log.info(f"y2 (binary) : {str(dut.y.value)}") # 1100000000
    x2 = dut.x.value
    y2 = dut.y.value

    assert int(x1) != int(x2)
    assert int(y1) != int(y2)