# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

# A file to test the entire tamagotchi.

@cocotb.test()
async def test_to_avoid_errors(dut):
    # This test does nothing, but simply makes cocotb not crash.
    pass