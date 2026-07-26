# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

# This file is used to test the main_controller implementation independantly.

# This is an example test.
# It does not specify any expected behavior, so it will fail.
# This test simply demonstrates the syntax of a test.
@cocotb.test()
async def example_timer_test(dut):
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.reset.value = 0
    await ClockCycles(dut.clk, 10)
    dut.reset.value = 1

    dut._log.info("Test project behavior")

    # Set the input values you want to test
    dut.left.value = 1

    # Wait for one clock cycle to see the output values
    await ClockCycles(dut.clk, 100)

    # The following assersion is just an example of how to check the output values.
    # Change it to match the actual expected output of your module:
    assert dut.battery_left.value == 1
