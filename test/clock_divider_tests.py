# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles



async def reset(dut):
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 1)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1)


async def setup_test(dut):
    dut._log.info("Starting test.")

    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())
    await reset(dut)



@cocotb.test()
async def reset_test(dut):
    await setup_test(dut)

    dut._log.info("Resetting the 2 bit clock divider.")
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 1)
    dut.rst_n.value = 1
    assert all([dut.output_2_bits.value[i] == 0 for i in range(3)])
    dut._log.info("    Resetting the 2 bit clock divider successful.")

    dut._log.info("Resetting the 4 bit clock divider.")
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 1)
    dut.rst_n.value = 1
    assert all([dut.output_4_bits.value[i] == 0 for i in range(5)])
    dut._log.info("    Resetting the 4 bit clock divider successful.")


@cocotb.test()
async def counter_length_test(dut):
    await setup_test(dut)

    dut._log.info("Checking the 2 bit clock divider length.")
    assert len(dut.output_2_bits.value) == 3
    dut._log.info("    Checking the 2 bit clock divider length. successful")

    dut._log.info("Checking the 4 bit clock divider length.")
    assert len(dut.output_4_bits.value) == 5
    dut._log.info("    Checking the 4 bit clock divider length. successful")


@cocotb.test()
async def counter_values_test(dut):
    await setup_test(dut)

    dut._log.info("Checking the 2 bit clock divider values (including looparound).")
    for i in range(1, 100):
        for j in range(3):
            assert dut.output_2_bits.value[j] == (i >> j) & 1
        await ClockCycles(dut.clk, 1)
    dut._log.info("Checking the 2 bit clock divider values (including looparound) successful.")

    await reset(dut)

    dut._log.info("Checking the 4 bit clock divider values (including looparound).")
    for i in range(1, 100):
        for j in range(5):
            assert dut.output_4_bits.value[j] == (i >> j) & 1
        await ClockCycles(dut.clk, 1)
    dut._log.info("Checking the 4 bit clock divider values (including looparound) successful.")

    

