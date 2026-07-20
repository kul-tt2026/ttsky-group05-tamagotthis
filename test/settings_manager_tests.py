# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

async def reset(dut):
    dut.inputs_a.value = 0
    dut.inputs_b.value = 0

    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 1)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1)


async def setup_test(dut):
    dut._log.info("Setting up test.")
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())
    await reset(dut)

    
@cocotb.test()
async def reset_resets_settings_test(dut):
    await setup_test(dut)

    dut._log.info("Changing settings.")
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 1)
    dut.inputs_a.value[0] = 1
    dut.inputs_a.value[2] = 1
    dut.inputs_b.value[1] = 1
    await ClockCycles(dut.clk, 1)
    dut.inputs_a.value[0] = 0
    dut.inputs_a.value[2] = 0
    dut.inputs_b.value[1] = 0
    await ClockCycles(dut.clk, 1)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1)
    dut._log.info("    Settings changed.")

    dut._log.info("Resetting settings.")
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 1)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1)
    assert all([int(dut.outputs_a.value[i]) == 0 for i in range(3)])
    assert all([int(dut.outputs_b.value[i*2-1:(i-1)*2]) == 0 for i in range(2)])
    dut._log.info("    Reset successful.")


@cocotb.test()
async def settings_do_not_change_with_reset_high_test(dut):
    await setup_test(dut)

    dut._log.info("Changing settings while rst_n=1.")
    dut.inputs_a.value[0] = 1
    dut.inputs_a.value[2] = 1
    dut.inputs_b.value[1] = 1
    await ClockCycles(dut.clk, 1)
    dut.inputs_a.value[0] = 0
    dut.inputs_a.value[2] = 0
    dut.inputs_b.value[1] = 0
    await ClockCycles(dut.clk, 1)
    assert all([dut.outputs_a.value[i] == 0 for i in range(3)])
    assert all([dut.outputs_b.value[i*2-1:(i-1)*2] == 0 for i in range(2)])
    dut._log.info("    Success: settings did not change.")


@cocotb.test()
async def change_settings_test(dut):
    await setup_test(dut)

    dut._log.info("Changing settings.")
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 1)
    dut.inputs_a.value[0] = 1
    dut.inputs_a.value[2] = 1
    dut.inputs_b.value[1] = 1
    await ClockCycles(dut.clk, 10)
    dut.inputs_a.value[0] = 0
    dut.inputs_a.value[2] = 0
    dut.inputs_b.value[1] = 0
    await ClockCycles(dut.clk, 1)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1)
    assert dut.outputs_a.value[0] == 0
    assert dut.outputs_a.value[1] == 0
    assert dut.outputs_a.value[2] == 1
    assert int(dut.outputs_b.value[1:0]) == 0
    assert int(dut.outputs_b.value[3:2]) == 1
    dut._log.info("    Settings changed successfully (first time).")

    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 1)
    dut.inputs_a.value[0] = 1
    dut.inputs_a.value[2] = 1
    dut.inputs_b.value[1] = 1
    await ClockCycles(dut.clk, 10)
    dut.inputs_a.value[0] = 0
    dut.inputs_a.value[2] = 0
    dut.inputs_b.value[1] = 0
    await ClockCycles(dut.clk, 1)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1)
    assert dut.outputs_a.value[0] == 0
    assert dut.outputs_a.value[1] == 0
    assert dut.outputs_a.value[2] == 0
    assert int(dut.outputs_b.value[1:0]) == 0
    assert int(dut.outputs_b.value[3:2]) == 2
    dut._log.info("    Settings changed successfully (second time).")

    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 1)
    dut.inputs_a.value[0] = 1
    dut.inputs_a.value[2] = 1
    dut.inputs_b.value[1] = 1
    await ClockCycles(dut.clk, 10)
    dut.inputs_a.value[0] = 0
    dut.inputs_a.value[2] = 0
    dut.inputs_b.value[1] = 0
    await ClockCycles(dut.clk, 1)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1)
    assert dut.outputs_a.value[0] == 1
    assert dut.outputs_a.value[1] == 0
    assert dut.outputs_a.value[2] == 1
    assert int(dut.outputs_b.value[1:0]) == 0
    assert int(dut.outputs_b.value[3:2]) == 3
    dut._log.info("    Settings changed successfully (third time).")

    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 1)
    dut.inputs_a.value[0] = 1
    dut.inputs_a.value[2] = 1
    dut.inputs_b.value[1] = 1
    await ClockCycles(dut.clk, 10)
    dut.inputs_a.value[0] = 0
    dut.inputs_a.value[2] = 0
    dut.inputs_b.value[1] = 0
    await ClockCycles(dut.clk, 1)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1)
    assert dut.outputs_a.value[0] == 0
    assert dut.outputs_a.value[1] == 0
    assert dut.outputs_a.value[2] == 0
    assert int(dut.outputs_b.value[1:0]) == 0
    assert int(dut.outputs_b.value[3:2]) == 0
    dut._log.info("    Settings changed successfully (fourth time).")