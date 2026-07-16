# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

# This file is used to test the main_controller implementation independantly.

async def reset_cat_to_default(dut):
    # Number of cycles the bang takes.
    RESET_CYCLES = 50
    dut._log.info("Resetting cat to default state.")
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    assert_state(dut, state=STATE_BANG)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, RESET_CYCLES)
    assert_state(dut, state=STATE_DEFAULT)
    assert dut.lives_left == 9
    assert dut.battery_left == 8
    assert dut.battery_almost_empty == 0
    dut._log.info("    Reset to default state successful.")


async def setup_test(dut):
    dut._log.info("Starting test.")
    dut.rst_n.value = 1

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await reset_cat_to_default(dut)

STATE_BANG = 1
STATE_DEFAULT = 2
STATE_EATING = 4
STATE_SLEEPING = 8
STATE_PLAYING = 16
STATE_DEAD = 32

def assert_state(dut, state, play_sound=-1):
    # state:
    #  - if one state is selected (state == STATE_BANG for example), it asserts if that is the current state.
    #  - if multiple states are selected (state == STATe_BANG | STATE_DEFAULT for example), it asserts if the current state is part of the selected states.
    # play_sound:
    #  - True: should play sound associated with current states.
    #  - False: should not play sound associated with current states.
    #  - -1 (default): do not care.

    # State checks.
    assert (dut.show_bang.value == 1) ^ ((state & STATE_BANG) != 0)
    assert (dut.is_dead.value == 1) ^ ((state & STATE_DEAD) != 0)
    assert (dut.is_eating.value == 1) ^ ((state & STATE_EATING) != 0)
    assert (dut.is_sleeping.value == 1) ^ ((state & STATE_SLEEPING) != 0)
    assert (dut.is_playing.value == 1) ^ ((state & STATE_PLAYING) != 0)
    assert (dut.is_default_state.value == 1) ^ ((state & STATE_DEFAULT) != 0)
    # Only one state selected at once.
    aggregated_state = dut.show_bang | (dut.is_default_state << 1) | (dut.is_eating << 2) | (dut.is_sleeping << 3) | (dut.is_playing << 4) | (dut.is_dead << 5)
    assert ((aggregated_state - 1) & aggregated_state) == 0

    # Sound checks.
    assert (((dut.play_bang == 1) ^ (play_sound == False)) or play_sound == -1) if dut.show_bang else dut.play_bang == 0
    assert (((dut.play_dead == 1) ^ (play_sound == False)) or play_sound == -1) if dut.is_dead else dut.play_dead == 0
    assert (((dut.play_sleeping == 1) ^ (play_sound == False)) or play_sound == -1) if dut.is_sleeping else dut.play_sleeping == 0
    assert (((dut.play_playing == 1) ^ (play_sound == False)) or play_sound == -1) if dut.is_playing else dut.play_playing == 0
    assert (((dut.play_default == 1) ^ (play_sound == False)) or play_sound == -1) if dut.is_default_state else dut.play_default == 0
        


# This test checks if the rst_n sequence is as expected for the main_controller.
@cocotb.test()
async def reset_test(dut):
    await setup_test(dut)

    # Number of cycles the bang takes.
    RESET_CYCLES = 50

    # Try to get the dut in some random state.
    dut._log.info("Entering some random state.")
    dut.X.value = 1
    dut.left.value = 1
    dut.up.value = 1
    await ClockCycles(dut.clk, 10)
    dut.X.value = 0
    dut.left.value = 0
    dut.up.value = 0
    await ClockCycles(dut.clk, 10)
    dut.deplete_battery = 1
    await ClockCycles(dut.clk, 10)
    dut.deplete_battery = 0
    await ClockCycles(dut.clk, 10)
    dut._log.info("    Random state entered.")

    # rst_n
    dut._log.info("Test Behaviour: rst_n.")
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    # After a rst_n, the tamagotchi starts with a bang.
    dut._log.info("Checking if the tamagotchi starts with a bang.")
    assert_state(dut, state=STATE_BANG, play_sound=True)
    dut._log.info("    Bang successful.")

    # After a little while, the play_bang input should turn off.
    await ClockCycles(dut.clk, 10)
    dut._log.info("Checking if the play_bang output turns off.")
    assert_state(dut, state=STATE_BANG, play_sound=False)
    dut._log.info("    Play_bang turned off successfully.")

    # After a few seconds, the bang stops and the cat is born.
    await ClockCycles(dut.clk, RESET_CYCLES)
    dut._log.info("Checking if the cat is born in default state.")
    assert_state(dut, state=STATE_DEFAULT, play_sound=True)
    dut._log.info("    Cat born successfully.")


# Checks if the cat correctly changes from state to state.
@cocotb.test()
async def state_change_test(dut):
    await setup_test(dut)

    # Default -> playing.
    dut._log.info("Checking Default -> Playing.")
    dut.X.value = 1
    await ClockCycles(dut.clk, 10)
    dut.X.value = 0
    assert_state(dut, state=STATE_PLAYING, play_sound=True)
    #    Pressing the playing button again does not restart the playing state.
    dut._log.info("Checking Playing -> Playing.")
    dut.X.value = 0
    await ClockCycles(dut.clk, 10)
    dut.X.value = 1
    await ClockCycles(dut.clk, 10)
    dut.X.value = 0
    assert_state(dut, state=STATE_PLAYING, play_sound=False)
    #    You cannot go from one state to another directly, without passing through the default state first.
    dut._log.info("Checking Playing -/> <other_states>.")
    dut.Y.value = 1
    await ClockCycles(dut.clk, 10)
    dut.Y.value = 0
    assert_state(dut, state=STATE_PLAYING, play_sound=False)
    dut.A.value = 1
    await ClockCycles(dut.clk, 10)
    dut.A.value = 0
    assert_state(dut, state=STATE_PLAYING, play_sound=False)
    # Go back to the default state.
    dut._log.info("Checking Playing -> Default.")
    dut.B.value = 1
    await ClockCycles(dut.clk, 10)
    dut.B.value = 0
    assert_state(dut, state=STATE_DEFAULT, play_sound=True)

    # Default -> sleeping.
    dut.Y.value = 1
    await ClockCycles(dut.clk, 10)
    dut.Y.value = 0
    assert_state(dut, state=STATE_SLEEPING, play_sound=True)
    #    Pressing the sleeping button again does not restart the sleeping state.
    dut._log.info("Checking Sleeping -> Sleeping.")
    dut.Y.value = 0
    await ClockCycles(dut.clk, 10)
    dut.Y.value = 1
    await ClockCycles(dut.clk, 10)
    dut.Y.value = 0
    assert_state(dut, state=STATE_SLEEPING, play_sound=False)
    #    You cannot go from one state to another directly, without passing through the default state first.
    dut._log.info("Checking Sleeping -/> <other_states>.")
    dut.X.value = 1
    await ClockCycles(dut.clk, 10)
    dut.X.value = 0
    assert_state(dut, state=STATE_SLEEPING, play_sound=False)
    dut.A.value = 1
    await ClockCycles(dut.clk, 10)
    dut.A.value = 0
    assert_state(dut, state=STATE_SLEEPING, play_sound=False)
    # Go back to the default state.
    dut._log.info("Checking Sleeping -> Default.")
    dut.B.value = 1
    await ClockCycles(dut.clk, 10)
    dut.B.value = 0
    assert_state(dut, state=STATE_DEFAULT, play_sound=True)

    # Default -> eating.
    dut.A.value = 1
    await ClockCycles(dut.clk, 10)
    dut.a.value = 0
    assert_state(dut, state=STATE_EATING, play_sound=True)
    #    Pressing the eating button again does not restart the eating state.
    dut._log.info("Checking Eating -> Eating.")
    dut.A.value = 0
    await ClockCycles(dut.clk, 10)
    dut.A.value = 1
    await ClockCycles(dut.clk, 10)
    dut.A.value = 0
    assert_state(dut, state=STATE_EATING, play_sound=False)
    #    You cannot go from one state to another directly, without passing through the default state first.
    dut._log.info("Checking Eating -/> <other_states>.")
    dut.X.value = 1
    await ClockCycles(dut.clk, 10)
    dut.X.value = 0
    assert_state(dut, state=STATE_EATING, play_sound=False)
    dut.Y.value = 1
    await ClockCycles(dut.clk, 10)
    dut.Y.value = 0
    assert_state(dut, state=STATE_EATING, play_sound=False)
    # Go back to the default state.
    dut._log.info("Checking Eating -> Default.")
    dut.B.value = 1
    await ClockCycles(dut.clk, 10)
    dut.B.value = 0
    assert_state(dut, state=STATE_DEFAULT, play_sound=True)


# Check if the controller is at most in one state at a time, and if that state makes sense.
# That is, pressing X + Y should not result in state A or something.
@cocotb.test()
async def max_one_valid_state_test(dut):
    await setup_test(dut)

    dut._log.info("Checking all XYAB combinations.")
    for x in {0, 1}:
        for y in {0, 1}:
            for a in {0, 1}:
                for b in {0, 1}:
                    POSSIBLE_STATE = (STATE_DEFAULT * b) | (STATE_EATING * a) | (STATE_SLEEPING * y) | (STATE_PLAYING * x)
                    await reset_cat_to_default(dut)
                    dut.X.value = x
                    dut.Y.value = y
                    dut.A.value = a
                    dut.B.value = b
                    await ClockCycles(dut.clk, 10)
                    dut.X.value = 0
                    dut.Y.value = 0
                    dut.A.value = 0
                    dut.B.value = 0
                    assert_state(dut, state=POSSIBLE_STATE)


# Check if moving the cat makes sense, in the eating state.
@cocotb.test()
async def move_cat_when_eating_test(dut):
    await setup_test(dut)

    dut._log.info("Going to Eating state.")
    dut.A.value = 1
    await ClockCycles(dut.clk, 10)
    dut.a.value = 0
    assert_state(dut, state=STATE_EATING)
    dut._log.info("    Reached Eating state.")

    # Number of pixels moved per step.
    STEP_SIZE = 1
    # Number of clock cycles before the cat takes another step, if the button is not lifted.
    # -1 for 'no extra steps unless the button is pressed again'.
    STEP_TIME_INTERVAL = 10

    # Move left.
    dut._log.info("Move left.")
    dut._log.info("    Move left once.")
    (pos_x, pos_y) = (dut.cat_pos_x, dut.cat_pos_y)
    dut.left.value = 1
    await ClockCycles(dut.clk, 1)
    dut.left.value = 0
    assert dut.cat_pos_x == pos_x - STEP_SIZE and dut.cat_pos_y == pos_y
    dut._log.info("    Move left multiple times.")
    (pos_x, pos_y) = (dut.cat_pos_x, dut.cat_pos_y)
    if STEP_TIME_INTERVAL > 0:
        dut.left.value = 1
        await ClockCycles(dut.clk, 1 + STEP_TIME_INTERVAL * 5)
        dut.left.value = 0
        assert dut.cat_pos_x == pos_x - 5 * STEP_SIZE and dut.cat_pos_y == pos_y
    dut._log.info("    Move left successful.")

    # Move right.
    dut._log.info("Move right.")
    dut._log.info("    Move right once.")
    (pos_x, pos_y) = (dut.cat_pos_x, dut.cat_pos_y)
    dut.right.value = 1
    await ClockCycles(dut.clk, 1)
    dut.right.value = 0
    assert dut.cat_pos_x == pos_x + STEP_SIZE and dut.cat_pos_y == pos_y
    dut._log.info("    Move right multiple times.")
    (pos_x, pos_y) = (dut.cat_pos_x, dut.cat_pos_y)
    if STEP_TIME_INTERVAL > 0:
        dut.right.value = 1
        await ClockCycles(dut.clk, 1 + STEP_TIME_INTERVAL * 5)
        dut.right.value = 0
        assert dut.cat_pos_x == pos_x + 5 * STEP_SIZE and dut.cat_pos_y == pos_y
    dut._log.info("    Move right successful.")

    # Move up.
    dut._log.info("Move up.")
    dut._log.info("    Move up once.")
    (pos_x, pos_y) = (dut.cat_pos_x, dut.cat_pos_y)
    dut.up.value = 1
    await ClockCycles(dut.clk, 1)
    dut.up.value = 0
    assert dut.cat_pos_x == pos_x and dut.cat_pos_y == pos_y + 1 * STEP_SIZE
    dut._log.info("    Move up multiple times.")
    (pos_x, pos_y) = (dut.cat_pos_x, dut.cat_pos_y)
    if STEP_TIME_INTERVAL > 0:
        dut.up.value = 1
        await ClockCycles(dut.clk, 1 + STEP_TIME_INTERVAL * 5)
        dut.up.value = 0
        assert dut.cat_pos_x == pos_x and dut.cat_pos_y == pos_y + 5 * STEP_SIZE
    dut._log.info("    Move up successful.")

    # Move down.
    dut._log.info("Move down.")
    dut._log.info("    Move down once.")
    (pos_x, pos_y) = (dut.cat_pos_x, dut.cat_pos_y)
    dut.down.value = 1
    await ClockCycles(dut.clk, 1)
    dut.down.value = 0
    assert dut.cat_pos_x == pos_x and dut.cat_pos_y == pos_y - 1 * STEP_SIZE
    dut._log.info("    Move down multiple times.")
    (pos_x, pos_y) = (dut.cat_pos_x, dut.cat_pos_y)
    if STEP_TIME_INTERVAL > 0:
        dut.down.value = 1
        await ClockCycles(dut.clk, 1 + STEP_TIME_INTERVAL * 5)
        dut.down.value = 0
        assert dut.cat_pos_x == pos_x and dut.cat_pos_y == pos_y - 5 * STEP_SIZE
    dut._log.info("    Move down successful.")


# Check if the cat always has an on-screen position in the eating state.
@cocotb.test()
async def valid_position_test(dut):
    await setup_test(dut)

    dut._log.info("Going to Eating state.")
    dut.A.value = 1
    await ClockCycles(dut.clk, 10)
    dut.a.value = 0
    assert_state(dut, state=STATE_EATING)
    dut._log.info("    Reached Eating state.")

    # Number of pixels moved per step.
    STEP_SIZE = 1
    # Number of clock cycles before the cat takes another step, if the button is not lifted.
    # -1 for 'no extra steps unless the button is pressed again'.
    STEP_TIME_INTERVAL = 10
    # Minimum and maximum positions the cat can reach.
    POS_MIN_X, POS_MAX_X, POS_MIN_Y, POS_MAX_Y = 0, 10, 0, 10

    dut._log.info("MIN_X.")
    dut._log.info("    Moving to MIN_X edge.")
    while dut.cat_pos_x > POS_MIN_X:
        dut.left.value = 1
        await ClockCycles(dut.clk, 1)
        dut.left.value = 0
        await ClockCycles(dut.clk, 1)
    dut._log.info("    Reached MIN_X edge, checking boundary.")
    # Check edge by repeatedly pressing the button.
    for i in range(10):
        dut.left.value = 1
        await ClockCycles(dut.clk, 1)
        dut.left.value = 0
        await ClockCycles(dut.clk, 1)
        assert dut.cat_pos_x == POS_MIN_X
    if STEP_TIME_INTERVAL > 0:
        # Check edge by holding the button.
        dut.left.value = 1
        await ClockCycles(dut.clk, STEP_TIME_INTERVAL * 5)
        dut.left.value = 0
        await ClockCycles(dut.clk, 1)
        assert dut.cat_pos_x == POS_MIN_X
    dut._log.info("    MIN_X successful.")

    dut._log.info("MIN_Y.")
    dut._log.info("    Moving to MIN_Y edge.")
    while dut.cat_pos_y > POS_MIN_Y:
        dut.down.value = 1
        await ClockCycles(dut.clk, 1)
        dut.down.value = 0
        await ClockCycles(dut.clk, 1)
    dut._log.info("    Reached MIN_Y edge, checking boundary.")
    # Check edge by repeatedly pressing the button.
    for i in range(10):
        dut.down.value = 1
        await ClockCycles(dut.clk, 1)
        dut.down.value = 0
        await ClockCycles(dut.clk, 1)
        assert dut.cat_pos_y == POS_MIN_Y
    if STEP_TIME_INTERVAL > 0:
        # Check edge by holding the button.
        dut.down.value = 1
        await ClockCycles(dut.clk, STEP_TIME_INTERVAL * 5)
        dut.down.value = 0
        await ClockCycles(dut.clk, 1)
        assert dut.cat_pos_y == POS_MIN_Y
    dut._log.info("    MIN_Y successful.")

    dut._log.info("MAX_X.")
    dut._log.info("    Moving to MAX_X edge.")
    while dut.cat_pos_x < POS_MAX_X:
        dut.right.value = 1
        await ClockCycles(dut.clk, 1)
        dut.right.value = 0
        await ClockCycles(dut.clk, 1)
    dut._log.info("    Reached MAX_X edge, checking boundary.")
    # Check edge by repeatedly pressing the button.
    for i in range(10):
        dut.right.value = 1
        await ClockCycles(dut.clk, 1)
        dut.right.value = 0
        await ClockCycles(dut.clk, 1)
        assert dut.cat_pos_x == POS_MAX_X
    if STEP_TIME_INTERVAL > 0:
        # Check edge by holding the button.
        dut.right.value = 1
        await ClockCycles(dut.clk, STEP_TIME_INTERVAL * 5)
        dut.right.value = 0
        await ClockCycles(dut.clk, 1)
        assert dut.cat_pos_x == POS_MAX_X
    dut._log.info("    MAX_X successful.")

    dut._log.info("MAX_Y.")
    dut._log.info("    Moving to MAX_Y edge.")
    while dut.cat_pos_y < POS_MAX_Y:
        dut.up.value = 1
        await ClockCycles(dut.clk, 1)
        dut.up.value = 0
        await ClockCycles(dut.clk, 1)
    dut._log.info("    Reached MAX_Y edge, checking boundary.")
    # Check edge by repeatedly pressing the button.
    for i in range(10):
        dut.up.value = 1
        await ClockCycles(dut.clk, 1)
        dut.up.value = 0
        await ClockCycles(dut.clk, 1)
        assert dut.cat_pos_y == POS_MAX_Y
    if STEP_TIME_INTERVAL > 0:
        # Check edge by holding the button.
        dut.up.value = 1
        await ClockCycles(dut.clk, STEP_TIME_INTERVAL * 5)
        dut.up.value = 0
        await ClockCycles(dut.clk, 1)
        assert dut.cat_pos_y == POS_MAX_Y
    dut._log.info("    MAX_Y successful.")


# Tests if the battery is correctly depleted if that signals comes in.
# This should work in each state.
@cocotb.test()
async def deplete_battery_test(dut):
    await setup_test(dut)

    dut._log.info("Depleting battery in Default state.")
    for battery in range(7,1,-1):
        dut._log.info(f"   Attempting battery level {battery+1}->{battery}.")
        dut.deplete_battery = 1
        await ClockCycles(dut.clk, 1)
        dut.deplete_battery = 0
        await ClockCycles(dut.clk, 1)
        assert dut.battery_left == battery


# Tests if the battery_almost_empty signal behaves correctly.
@cocotb.test()
async def battery_almost_empty_signal_test(dut):
    await setup_test(dut)
    dut._log.info("Depleting battery in Default state.")
    for battery in range(7,1,-1):
        dut._log.info(f"   Attempting battery level {battery+1}->{battery}.")
        dut.deplete_battery = 1
        await ClockCycles(dut.clk, 1)
        dut.deplete_battery = 0
        await ClockCycles(dut.clk, 1)
        assert dut.battery_left == battery
        assert dut.battery_almost_empty == 1 if battery == 1 else 0


# Tests if a life is correctly lost if the battery is empty.
# This should work in each state.
@cocotb.test()
async def lose_life_test(dut):
    await setup_test(dut)

    # Number of cycles the cat is shown as dead before it is alive again.
    DEAD_CYCLES = 10

    dut._log.info("Depleting battery in Default state till a life is lost.")
    for lives in range(8,1,-1):
        dut._log.info(f"   Attempting life {lives+1}->{lives}.")
        for battery in range(7,0,-1):
            dut.deplete_battery = 1
            await ClockCycles(dut.clk, 1)
            dut.deplete_battery = 0
            await ClockCycles(dut.clk, 1)
        # There is an intermediate phase where the cat is dead/has crossed out eyes.
        assert dut.lives_left == lives and dut.battery_left == 0 and dut.battery_almost_empty == False
        assert_state(dut, STATE_DEAD, True)
        # After that, it comes back to life.
        await ClockCycles(dut.clk, DEAD_CYCLES)
        assert_state(dut, STATE_DEFAULT, True)
        assert dut.battery_left == 8  # Resets battery.
        assert dut.battery_almost_empty == 0


# Tests if a the cat correctly resets if it completely dies.
# This should work in each state.
@cocotb.test()
async def die_test(dut):
    await setup_test(dut)

    # Number of cycles the cat is shown as dead before it is reset.
    DEAD_CYCLES = 30
    # Number of cycles the bang takes.
    RESET_CYCLES = 50

    dut._log.info("Depleting battery in Default state till a life is lost.")
    for lives in range(8,0,-1):
        dut._log.info(f"   Attempting life {lives+1}->{lives}.")
        for battery in range(7,0,-1):
            dut.deplete_battery = 1
            await ClockCycles(dut.clk, 1)
            dut.deplete_battery = 0
            await ClockCycles(dut.clk, 1)
    
    assert dut.lives_left == 0 and dut.battery_left == 0 and dut.battery_almost_empty == False
    assert_state(dut, STATE_DEAD, True)
    await ClockCycles(dut.clk, DEAD_CYCLES)
    assert_state(dut, STATE_BANG, True)
    await ClockCycles(dut.clk, RESET_CYCLES)
    assert_state(dut, STATE_DEFAULT, True)
    assert dut.lives_left == 9
    assert dut.battery_left == 8
    assert dut.battery_almost_empty == 0
