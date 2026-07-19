# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

# This file is used to test the timer implementation independantly.

SLEEP_DEPLETION_TIME = 20
SLEEP_FURTHER_DEPLETION_TIME = 10
PLAY_DEPLETION_TIME = 20
PLAY_FURTHER_DEPLETION_TIME = 10
EAT_DEPLETION_TIME = 20
EAT_FURTHER_DEPLETION_TIME = 10


async def setup_test(dut):
    dut._log.info("Setting up test.")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    dut._log.info("    Setting all inputs to 0.")
    dut.is_sleeping.value = 0
    dut.caught_fish.value = 0
    dut.is_playing.value = 0
    await ClockCycles(dut.clk, 1)
    dut._log.info("    Resetting timer.")
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 1)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1)
    dut._log.info("    Setup complete.")


@cocotb.test()
async def reset_test(dut):
    await setup_test(dut)

    # By repeatedly resetting the timer, there should never be a deplete battery signal.
    for i in range(3):
        for j in range(int(SLEEP_DEPLETION_TIME * 3 /4)):
            await ClockCycles(dut.clk, 1)
            assert dut.deplete_battery.value == 0
        # Reset.
        dut.rst_n.value = 0
        await ClockCycles(dut.clk, 1)
        dut.rst_n.value = 1
        await ClockCycles(dut.clk, 1)


@cocotb.test()
async def deplete_battery_once_no_eating_test(dut):
    await setup_test(dut)
    dut.is_playing.value = 1
    dut.is_sleeping.value = 1

    for j in range(EAT_DEPLETION_TIME - 2):
        await ClockCycles(dut.clk, 1)
        assert dut.deplete_battery.value == 0
    await ClockCycles(dut.clk, 1)
    assert dut.deplete_battery.value == 1
    await ClockCycles(dut.clk, 1)
    assert dut.deplete_battery.value == 0


@cocotb.test()
async def deplete_battery_multiple_no_eating_test(dut):
    await setup_test(dut)
    dut.is_playing.value = 1
    dut.is_sleeping.value = 1

    for j in range(EAT_DEPLETION_TIME - 2):
        await ClockCycles(dut.clk, 1)
        assert dut.deplete_battery.value == 0
    await ClockCycles(dut.clk, 1)
    assert dut.deplete_battery.value == 1
    for i in range(3):
        for j in range(EAT_FURTHER_DEPLETION_TIME):
            await ClockCycles(dut.clk, 1)
            assert dut.deplete_battery.value == 0
        await ClockCycles(dut.clk, 1)
        assert dut.deplete_battery.value == 1


@cocotb.test()
async def deplete_battery_once_eating_reset_test(dut):
    await setup_test(dut)
    dut.is_playing.value = 1
    dut.is_sleeping.value = 1
    
    for j in range(int(EAT_DEPLETION_TIME / 2)):
        await ClockCycles(dut.clk, 1)
        assert dut.deplete_battery.value == 0

    dut.caught_fish.value = 1
    await ClockCycles(dut.clk, 1)
    dut.caught_fish.value = 0
    await ClockCycles(dut.clk, 1)

    for j in range(int(EAT_DEPLETION_TIME / 2)):
        await ClockCycles(dut.clk, 1)
        assert dut.deplete_battery.value == 0


@cocotb.test()
async def deplete_battery_multiple_eating_reset_test(dut):
    await setup_test(dut)
    dut.is_playing.value = 1
    dut.is_sleeping.value = 1
    
    for j in range(EAT_DEPLETION_TIME - 2):
        await ClockCycles(dut.clk, 1)
        assert dut.deplete_battery.value == 0
    await ClockCycles(dut.clk, 1)
    assert dut.deplete_battery.value == 1
    
    for j in range(int(EAT_FURTHER_DEPLETION_TIME / 2)):
        await ClockCycles(dut.clk, 1)
        assert dut.deplete_battery.value == 0

    dut.caught_fish.value = 1
    await ClockCycles(dut.clk, 1)
    dut.caught_fish.value = 0
    await ClockCycles(dut.clk, 1)

    for j in range(int(EAT_DEPLETION_TIME / 2)):
        await ClockCycles(dut.clk, 1)
        assert dut.deplete_battery.value == 0


@cocotb.test()
async def deplete_battery_once_no_sleeping_test(dut):
    await setup_test(dut)
    dut.is_playing.value = 1
    dut.caught_fish.value = 1
    
    for j in range(SLEEP_DEPLETION_TIME - 2):
        await ClockCycles(dut.clk, 1)
        assert dut.deplete_battery.value == 0
    await ClockCycles(dut.clk, 1)
    assert dut.deplete_battery.value == 1
    await ClockCycles(dut.clk, 1)
    assert dut.deplete_battery.value == 0


@cocotb.test()
async def deplete_battery_multiple_no_sleeping_test(dut):
    await setup_test(dut)
    dut.is_playing.value = 1
    dut.caught_fish.value = 1
    
    for j in range(SLEEP_DEPLETION_TIME - 2):
        await ClockCycles(dut.clk, 1)
        assert dut.deplete_battery.value == 0
    await ClockCycles(dut.clk, 1)
    assert dut.deplete_battery.value == 1
    for i in range(3):
        for j in range(SLEEP_FURTHER_DEPLETION_TIME):
            await ClockCycles(dut.clk, 1)
            assert dut.deplete_battery.value == 0
        await ClockCycles(dut.clk, 1)
        assert dut.deplete_battery.value == 1


@cocotb.test()
async def deplete_battery_once_sleeping_reset_test(dut):
    await setup_test(dut)
    dut.is_playing.value = 1
    dut.caught_fish.value = 1

    for j in range(int(SLEEP_DEPLETION_TIME / 2)):
        await ClockCycles(dut.clk, 1)
        assert dut.deplete_battery.value == 0

    dut.is_sleeping.value = 1
    await ClockCycles(dut.clk, 1)
    dut.is_sleeping.value = 0
    await ClockCycles(dut.clk, 1)

    for j in range(int(SLEEP_DEPLETION_TIME / 2)):
        await ClockCycles(dut.clk, 1)
        assert dut.deplete_battery.value == 0


@cocotb.test()
async def deplete_battery_multiple_sleeping_reset_test(dut):
    await setup_test(dut)
    dut.is_playing.value = 1
    dut.caught_fish.value = 1
    
    for j in range(SLEEP_DEPLETION_TIME - 2):
        await ClockCycles(dut.clk, 1)
        assert dut.deplete_battery.value == 0
    await ClockCycles(dut.clk, 1)
    assert dut.deplete_battery.value == 1
    
    for j in range(int(SLEEP_FURTHER_DEPLETION_TIME / 2)):
        await ClockCycles(dut.clk, 1)
        assert dut.deplete_battery.value == 0

    dut.is_sleeping.value = 1
    await ClockCycles(dut.clk, 1)
    dut.is_sleeping.value = 0
    await ClockCycles(dut.clk, 1)

    for j in range(int(SLEEP_DEPLETION_TIME / 2)):
        await ClockCycles(dut.clk, 1)
        assert dut.deplete_battery.value == 0
        

@cocotb.test()
async def deplete_battery_once_no_playing_test(dut):
    await setup_test(dut)
    dut.is_sleeping.value = 1
    dut.caught_fish.value = 1
    
    for j in range(PLAY_DEPLETION_TIME - 2):
        await ClockCycles(dut.clk, 1)
        assert dut.deplete_battery.value == 0
    await ClockCycles(dut.clk, 1)
    assert dut.deplete_battery.value == 1
    await ClockCycles(dut.clk, 1)
    assert dut.deplete_battery.value == 0


@cocotb.test()
async def deplete_battery_multiple_no_playing_test(dut):
    await setup_test(dut)
    dut.is_sleeping.value = 1
    dut.caught_fish.value = 1
    
    for j in range(PLAY_DEPLETION_TIME - 2):
        await ClockCycles(dut.clk, 1)
        assert dut.deplete_battery.value == 0
    await ClockCycles(dut.clk, 1)
    assert dut.deplete_battery.value == 1
    for i in range(3):
        for j in range(PLAY_FURTHER_DEPLETION_TIME):
            await ClockCycles(dut.clk, 1)
            assert dut.deplete_battery.value == 0
        await ClockCycles(dut.clk, 1)
        assert dut.deplete_battery.value == 1
        

@cocotb.test()
async def deplete_battery_once_playing_reset_test(dut):
    await setup_test(dut)
    dut.is_sleeping.value = 1
    dut.caught_fish.value = 1

    for j in range(int(PLAY_DEPLETION_TIME / 2)):
        await ClockCycles(dut.clk, 1)
        assert dut.deplete_battery.value == 0

    dut.is_playing.value = 1
    await ClockCycles(dut.clk, 1)
    dut.is_playing.value = 0
    await ClockCycles(dut.clk, 1)

    for j in range(int(PLAY_DEPLETION_TIME / 2)):
        await ClockCycles(dut.clk, 1)
        assert dut.deplete_battery.value == 0


@cocotb.test()
async def deplete_battery_multiple_playing_reset_test(dut):
    await setup_test(dut)
    dut.is_sleeping.value = 1
    dut.caught_fish.value = 1
    
    for j in range(PLAY_DEPLETION_TIME - 2):
        await ClockCycles(dut.clk, 1)
        assert dut.deplete_battery.value == 0
    await ClockCycles(dut.clk, 1)
    assert dut.deplete_battery.value == 1
    
    for j in range(int(PLAY_FURTHER_DEPLETION_TIME / 2)):
        await ClockCycles(dut.clk, 1)
        assert dut.deplete_battery.value == 0

    dut.is_playing.value = 1
    await ClockCycles(dut.clk, 1)
    dut.is_playing.value = 0
    await ClockCycles(dut.clk, 1)

    for j in range(int(PLAY_DEPLETION_TIME / 2)):
        await ClockCycles(dut.clk, 1)
        assert dut.deplete_battery.value == 0
        
