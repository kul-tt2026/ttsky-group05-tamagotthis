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
    await ClockCycles(dut.clk, RESET_CYCLES + 5)
    assert_state(dut, state=STATE_DEFAULT)
    assert dut.lives_left.value == 9
    assert dut.battery_left.value == 8
    assert dut.battery_almost_empty.value == 0
    dut._log.info("    Reset to default state successful.")


async def setup_test(dut, test_id):
    dut._log.info(f"Starting test, test_id={test_id}.")
    # dut.test_id.value = test_id
    dut.rst_n.value = 1
    dut.A.value = 0
    dut.B.value = 0
    dut.X.value = 0
    dut.Y.value = 0
    dut.up.value = 0
    dut.left.value = 0
    dut.down.value = 0
    dut.right.value = 0
    dut.fish_caught.value = 0
    dut.deplete_battery.value = 0

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
    assert (dut.show_bang.value == 0) if ((state & STATE_BANG) == 0) else True
    assert (dut.is_dead.value == 0) if ((state & STATE_DEAD) == 0) else True
    assert (dut.is_eating.value == 0) if ((state & STATE_EATING) == 0) else True
    assert (dut.is_sleeping.value == 0) if ((state & STATE_SLEEPING) == 0) else True
    assert (dut.is_playing.value == 0) if ((state & STATE_PLAYING) == 0) else True
    assert (dut.is_default_state.value == 0) if ((state & STATE_DEFAULT) == 0) else True
    # Only one state selected at once.
    active_states = (1 if dut.show_bang.value == 1 else 0) + \
                    (1 if dut.is_dead.value == 1 else 0) + \
                    (1 if dut.is_eating.value == 1 else 0) + \
                    (1 if dut.is_sleeping.value == 1 else 0) + \
                    (1 if dut.is_playing.value == 1 else 0) + \
                    (1 if dut.is_default_state.value == 1 else 0)
    assert active_states == 1

    # Sound checks.
    """
    assert (((dut.play_bang.value == 1) ^ (play_sound == False)) or play_sound == -1) if dut.show_bang.value == 1 else dut.play_bang.value == 0
    assert (((dut.play_dead.value == 1) ^ (play_sound == False)) or play_sound == -1) if dut.is_dead.value == 1 else dut.play_dead.value == 0
    assert (((dut.play_sleeping.value == 1) ^ (play_sound == False)) or play_sound == -1) if dut.is_sleeping.value == 1 else dut.play_sleeping.value == 0
    assert (((dut.play_playing.value == 1) ^ (play_sound == False)) or play_sound == -1) if dut.is_playing.value == 1 else dut.play_playing.value == 0
    assert (((dut.play_default.value == 1) ^ (play_sound == False)) or play_sound == -1) if dut.is_default_state.value == 1 else dut.play_default.value == 0
    """
        


# This test checks if the rst_n sequence is as expected for the main_controller.
@cocotb.test()
async def reset_test(dut):
    await setup_test(dut, 1)

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
    dut.deplete_battery.value = 1
    await ClockCycles(dut.clk, 10)
    dut.deplete_battery.value = 0
    await ClockCycles(dut.clk, 10)
    dut._log.info("    Random state entered.")

    # rst_n
    dut._log.info("Test Behaviour: reset.")
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
    assert_state(dut, state=STATE_DEFAULT, play_sound=False)
    dut._log.info("    Cat born successfully.")


# Checks if the cat correctly changes from state to state.
@cocotb.test()
async def state_change_test(dut):
    await setup_test(dut, 2)

    # Default -> playing.
    dut._log.info("Checking Default -> Playing.")
    dut.X.value = 1
    await ClockCycles(dut.clk, 10)
    dut.X.value = 0
    assert_state(dut, state=STATE_PLAYING)
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
    assert_state(dut, state=STATE_DEFAULT)

    # Default -> sleeping.
    dut.Y.value = 1
    await ClockCycles(dut.clk, 10)
    dut.Y.value = 0
    assert_state(dut, state=STATE_SLEEPING)
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
    assert_state(dut, state=STATE_DEFAULT)

    # Default -> eating.
    dut.A.value = 1
    await ClockCycles(dut.clk, 10)
    dut.A.value = 0
    assert_state(dut, state=STATE_EATING)
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
    assert_state(dut, state=STATE_DEFAULT)


# Check if the controller is at most in one state at a time, and if that state makes sense.
# That is, pressing X + Y should not result in state A or something.
@cocotb.test()
async def max_one_valid_state_test(dut):
    await setup_test(dut, 3)

    dut._log.info("Checking all XYAB combinations.")
    for x in {0, 1}:
        for y in {0, 1}:
            for a in {0, 1}:
                for b in {0, 1}:
                    POSSIBLE_STATE = (STATE_DEFAULT * b) | (STATE_EATING * a) | (STATE_SLEEPING * y) | (STATE_PLAYING * x)
                    if (POSSIBLE_STATE == 0):  # The test does not work for POSSIBLE_STATE == 0, in that case, the current state is simply preserved.
                        continue
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
                    # dut._log.info(f"Possible States: {POSSIBLE_STATE}.")
                    assert_state(dut, state=POSSIBLE_STATE)


# Check if moving the cat makes sense, in the eating state.
@cocotb.test()
async def move_cat_when_eating_test(dut):
    await setup_test(dut, 4)

    dut._log.info("Going to Eating state.")
    dut.A.value = 1
    await ClockCycles(dut.clk, 10)
    dut.A.value = 0
    assert_state(dut, state=STATE_EATING)
    dut._log.info("    Reached Eating state.")

    # Number of pixels moved per step.
    STEP_SIZE = 1
    # Number of clock cycles before the cat takes another step, if the button is not lifted.
    # -1 for 'no extra steps unless the button is pressed again'.
    STEP_INTERVAL = 10

    # Move left.
    dut._log.info("Move left.")
    dut._log.info("    Move left once.")
    (pos_x, pos_y) = (int(dut.cat_pos_x.value), int(dut.cat_pos_y.value))
    dut.left.value = 1
    await ClockCycles(dut.clk, 1)
    dut.left.value = 0
    await ClockCycles(dut.clk, 1)
    assert int(dut.cat_pos_x.value) == pos_x - STEP_SIZE and int(dut.cat_pos_y.value) == pos_y
    dut._log.info("    Move left multiple times.")
    (pos_x, pos_y) = (int(dut.cat_pos_x.value), int(dut.cat_pos_y.value))
    if STEP_INTERVAL > 0:
        dut.left.value = 1
        await ClockCycles(dut.clk, 1 + STEP_INTERVAL * 5)
        dut.left.value = 0
        await ClockCycles(dut.clk, 1)
        assert int(dut.cat_pos_x.value) == pos_x - 5 * STEP_SIZE and int(dut.cat_pos_y.value) == pos_y
    dut._log.info("    Move left successful.")

    # Move right.
    dut._log.info("Move right.")
    dut._log.info("    Move right once.")
    (pos_x, pos_y) = (int(dut.cat_pos_x.value), int(dut.cat_pos_y.value))
    dut.right.value = 1
    await ClockCycles(dut.clk, 1)
    dut.right.value = 0
    await ClockCycles(dut.clk, 1)
    assert int(dut.cat_pos_x.value) == pos_x + STEP_SIZE and int(dut.cat_pos_y.value) == pos_y
    dut._log.info("    Move right multiple times.")
    (pos_x, pos_y) = (int(dut.cat_pos_x.value), int(dut.cat_pos_y.value))
    if STEP_INTERVAL > 0:
        dut.right.value = 1
        await ClockCycles(dut.clk, 1 + STEP_INTERVAL * 5)
        dut.right.value = 0
        await ClockCycles(dut.clk, 1)
        assert int(dut.cat_pos_x.value) == pos_x + 5 * STEP_SIZE and int(dut.cat_pos_y.value) == pos_y
    dut._log.info("    Move right successful.")

    # Move up.
    dut._log.info("Move up.")
    dut._log.info("    Move up once.")
    (pos_x, pos_y) = (int(dut.cat_pos_x.value), int(dut.cat_pos_y.value))
    dut.up.value = 1
    await ClockCycles(dut.clk, 1)
    dut.up.value = 0
    await ClockCycles(dut.clk, 1)
    assert int(dut.cat_pos_x.value) == pos_x and int(dut.cat_pos_y.value) == pos_y - 1 * STEP_SIZE
    dut._log.info("    Move up multiple times.")
    (pos_x, pos_y) = (int(dut.cat_pos_x.value), int(dut.cat_pos_y.value))
    if STEP_INTERVAL > 0:
        dut.up.value = 1
        await ClockCycles(dut.clk, 1 + STEP_INTERVAL * 5)
        dut.up.value = 0
        await ClockCycles(dut.clk, 1)
        assert int(dut.cat_pos_x.value) == pos_x and int(dut.cat_pos_y.value) == pos_y - 5 * STEP_SIZE
    dut._log.info("    Move up successful.")

    # Move down.
    dut._log.info("Move down.")
    dut._log.info("    Move down once.")
    (pos_x, pos_y) = (int(dut.cat_pos_x.value), int(dut.cat_pos_y.value))
    dut.down.value = 1
    await ClockCycles(dut.clk, 1)
    dut.down.value = 0
    await ClockCycles(dut.clk, 1)
    assert int(dut.cat_pos_x.value) == pos_x and int(dut.cat_pos_y.value) == pos_y + 1 * STEP_SIZE
    dut._log.info("    Move down multiple times.")
    (pos_x, pos_y) = (int(dut.cat_pos_x.value), int(dut.cat_pos_y.value))
    if STEP_INTERVAL > 0:
        dut.down.value = 1
        await ClockCycles(dut.clk, 1 + STEP_INTERVAL * 5)
        dut.down.value = 0
        await ClockCycles(dut.clk, 1)
        assert int(dut.cat_pos_x.value) == pos_x and int(dut.cat_pos_y.value) == pos_y + 5 * STEP_SIZE
    dut._log.info("    Move down successful.")


# Check if the cat always has an on-screen position in the eating state.
@cocotb.test()
async def valid_position_test(dut):
    await setup_test(dut, 5)

    dut._log.info("Going to Eating state.")
    dut.A.value = 1
    await ClockCycles(dut.clk, 10)
    dut.A.value = 0
    assert_state(dut, state=STATE_EATING)
    dut._log.info("    Reached Eating state.")

    # Number of pixels moved per step.
    STEP_SIZE = 1
    # Number of clock cycles before the cat takes another step, if the button is not lifted.
    # -1 for 'no extra steps unless the button is pressed again'.
    STEP_INTERVAL = 10
    # Minimum and maximum positions the cat can reach.
    POS_MIN_X, POS_MAX_X, POS_MIN_Y, POS_MAX_Y = 0, 100, 0, 200

    dut._log.info("MIN_X.")
    dut._log.info("    Moving to MIN_X edge.")
    while int(dut.cat_pos_x.value) > POS_MIN_X:
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
        assert int(dut.cat_pos_x.value) == POS_MIN_X
    if STEP_INTERVAL > 0:
        # Check edge by holding the button.
        dut.left.value = 1
        await ClockCycles(dut.clk, STEP_INTERVAL * 5)
        dut.left.value = 0
        await ClockCycles(dut.clk, 1)
        assert int(dut.cat_pos_x.value) == POS_MIN_X
    dut._log.info("    MIN_X successful.")

    dut._log.info("MIN_Y.")
    dut._log.info("    Moving to MIN_Y edge.")
    while int(dut.cat_pos_y.value) > POS_MIN_Y:
        dut.up.value = 1
        await ClockCycles(dut.clk, 1)
        dut.up.value = 0
        await ClockCycles(dut.clk, 1)
    dut._log.info("    Reached MIN_Y edge, checking boundary.")
    # Check edge by repeatedly pressing the button.
    for i in range(10):
        dut.up.value = 1
        await ClockCycles(dut.clk, 1)
        dut.up.value = 0
        await ClockCycles(dut.clk, 1)
        assert int(dut.cat_pos_y.value) == POS_MIN_Y
    if STEP_INTERVAL > 0:
        # Check edge by holding the button.
        dut.up.value = 1
        await ClockCycles(dut.clk, STEP_INTERVAL * 5)
        dut.up.value = 0
        await ClockCycles(dut.clk, 1)
        assert int(dut.cat_pos_y.value) == POS_MIN_Y
    dut._log.info("    MIN_Y successful.")

    dut._log.info("MAX_X.")
    dut._log.info("    Moving to MAX_X edge.")
    while int(dut.cat_pos_x.value) < POS_MAX_X:
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
        assert int(dut.cat_pos_x.value) == POS_MAX_X
    if STEP_INTERVAL > 0:
        # Check edge by holding the button.
        dut.right.value = 1
        await ClockCycles(dut.clk, STEP_INTERVAL * 5)
        dut.right.value = 0
        await ClockCycles(dut.clk, 1)
        assert int(dut.cat_pos_x.value) == POS_MAX_X
    dut._log.info("    MAX_X successful.")

    dut._log.info("MAX_Y.")
    dut._log.info("    Moving to MAX_Y edge.")
    while int(dut.cat_pos_y.value) < POS_MAX_Y:
        dut.down.value = 1
        await ClockCycles(dut.clk, 1)
        dut.down.value = 0
        await ClockCycles(dut.clk, 1)
    dut._log.info("    Reached MAX_Y edge, checking boundary.")
    # Check edge by repeatedly pressing the button.
    for i in range(10):
        dut.down.value = 1
        await ClockCycles(dut.clk, 1)
        dut.down.value = 0
        await ClockCycles(dut.clk, 1)
        assert int(dut.cat_pos_y.value) == POS_MAX_Y
    if STEP_INTERVAL > 0:
        # Check edge by holding the button.
        dut.down.value = 1
        await ClockCycles(dut.clk, STEP_INTERVAL * 5)
        dut.down.value = 0
        await ClockCycles(dut.clk, 1)
        assert int(dut.cat_pos_y.value) == POS_MAX_Y
    dut._log.info("    MAX_Y successful.")


# Tests if the battery is correctly depleted if that signals comes in.
# This should work in each state.
@cocotb.test()
async def deplete_battery_test(dut):
    await setup_test(dut, 6)

    dut._log.info("Depleting battery in Default state.")
    for battery in range(7,1,-1):
        dut._log.info(f"   Attempting battery level {battery+1}->{battery}.")
        dut.deplete_battery.value = 1
        await ClockCycles(dut.clk, 1)
        dut.deplete_battery.value = 0
        await ClockCycles(dut.clk, 1)
        assert int(dut.battery_left.value) == battery


# Tests if the battery_almost_empty signal behaves correctly.
@cocotb.test()
async def battery_almost_empty_signal_test(dut):
    await setup_test(dut, 7)
    dut._log.info("Depleting battery in Default state.")
    for battery in range(7,1,-1):
        dut._log.info(f"   Attempting battery level {battery+1}->{battery}.")
        dut.deplete_battery.value = 1
        await ClockCycles(dut.clk, 1)
        dut.deplete_battery.value = 0
        await ClockCycles(dut.clk, 1)
        assert int(dut.battery_left.value) == battery
        assert dut.battery_almost_empty.value == (1 if battery == 1 else 0)


# Tests if a life is correctly lost if the battery is empty.
# This should work in each state.
@cocotb.test()
async def lose_life_test(dut):
    await setup_test(dut, 8)

    # Number of cycles the cat is shown as dead before it is alive again.
    DEAD_CYCLES = 30

    dut._log.info("Depleting battery in Default state till a life is lost.")
    for lives in range(8,1,-1):
        dut._log.info(f"   Attempting life {lives+1}->{lives}.")
        for battery in range(8,0,-1):
            dut.deplete_battery.value = 1
            await ClockCycles(dut.clk, 1)
            dut.deplete_battery.value = 0
            await ClockCycles(dut.clk, 2)
        # There is an intermediate phase where the cat is dead/has crossed out eyes.
        assert int(dut.lives_left.value) == lives and int(dut.battery_left.value) == 0 and dut.battery_almost_empty.value == 0
        assert_state(dut, STATE_DEAD, True)
        # After that, it comes back to life.
        await ClockCycles(dut.clk, DEAD_CYCLES+5)
        assert_state(dut, STATE_DEFAULT)
        assert dut.battery_left.value == 8  # Resets battery.
        assert dut.battery_almost_empty.value == 0


# Tests if a the cat correctly resets if it completely dies.
# This should work in each state.
@cocotb.test()
async def die_test(dut):
    await setup_test(dut, 9)

    # Number of cycles the cat is shown as dead before it is reset.
    DEAD_CYCLES = 30
    # Number of cycles the bang takes.
    RESET_CYCLES = 50

    dut._log.info("Depleting battery in Default state till a life is lost.")
    for lives in range(8,-1,-1):
        dut._log.info(f"   Attempting life {lives+1}->{lives}.")
        for battery in range(8,0,-1):
            dut.deplete_battery.value = 1
            await ClockCycles(dut.clk, 1)
            dut.deplete_battery.value = 0
            await ClockCycles(dut.clk, 2)
        # There is an intermediate phase where the cat is dead/has crossed out eyes.
        assert int(dut.lives_left.value) == lives and int(dut.battery_left.value) == 0 and dut.battery_almost_empty.value == 0
        assert_state(dut, STATE_DEAD, True)
        # After that, it comes back to life.
        if lives != 0:
            await ClockCycles(dut.clk, DEAD_CYCLES+5)
            assert_state(dut, STATE_DEFAULT)
            assert dut.battery_left.value == 8  # Resets battery.
            assert dut.battery_almost_empty.value == 0
    
    assert int(dut.lives_left.value) == 0 and int(dut.battery_left.value) == 0 and dut.battery_almost_empty.value == 0
    assert_state(dut, STATE_DEAD)
    await ClockCycles(dut.clk, DEAD_CYCLES+5)
    assert_state(dut, STATE_BANG, True)
    await ClockCycles(dut.clk, RESET_CYCLES)
    assert_state(dut, STATE_DEFAULT)
    assert dut.lives_left.value == 9
    assert dut.battery_left.value == 8
    assert dut.battery_almost_empty.value == 0


# Tests if the battery of the cat increases if the cat eats, sleeps or plays.
@cocotb.test()
async def increase_battery_test(dut):
    await setup_test(dut, 10)

    # Number of cycles to sleep before the battery increases.
    SLEEP_TIME = 10
    # Number of cycles to play before the battery increases.
    PLAY_TIME = 10
    # Number of fish to catch before the battery increases.
    FISH_TO_CATCH = 3

    dut._log.info("Artifically decreasing battery.")
    for battery in range(8,3,-1):
        dut.deplete_battery.value = 1
        await ClockCycles(dut.clk, 1)
        dut.deplete_battery.value = 0
        await ClockCycles(dut.clk, 1)
    battery = int(dut.battery_left.value)
    
    dut._log.info("Testing battery increase from Sleeping.")
    dut.Y.value = 1
    await ClockCycles(dut.clk, 1)
    dut.Y.value = 0
    await ClockCycles(dut.clk, 1)
    assert_state(dut, STATE_SLEEPING)
    dut._log.info("    Entered Sleeping state successfully.")
    await ClockCycles(dut.clk, SLEEP_TIME+5)
    assert int(dut.battery_left.value) == battery + 1
    battery = int(dut.battery_left.value)
    dut._log.info("    Slept successfully, battery increased.")

    dut._log.info("Testing battery increase from Playing.")
    dut.B.value = 1
    await ClockCycles(dut.clk, 1)
    dut.B.value = 0
    await ClockCycles(dut.clk, 1)
    assert_state(dut, STATE_DEFAULT)
    dut.X.value = 1
    await ClockCycles(dut.clk, 1)
    dut.X.value = 0
    await ClockCycles(dut.clk, 1)
    assert_state(dut, STATE_PLAYING)
    dut._log.info("    Entered Playing state successfully.")
    await ClockCycles(dut.clk, PLAY_TIME + 5)
    assert int(dut.battery_left.value) == battery + 1
    battery = int(dut.battery_left.value)
    dut._log.info("    Played successfully, battery increased.")

    dut._log.info("Testing battery increase from Eating.")
    dut.B.value = 1
    await ClockCycles(dut.clk, 1)
    dut.B.value = 0
    await ClockCycles(dut.clk, 1)
    assert_state(dut, STATE_DEFAULT)
    dut.A.value = 1
    await ClockCycles(dut.clk, 1)
    dut.A.value = 0
    await ClockCycles(dut.clk, 1)
    assert_state(dut, STATE_EATING)
    dut._log.info("    Entered Eating state successfully.")
    for i in range(FISH_TO_CATCH):
        dut.fish_caught.value = 1
        await ClockCycles(dut.clk, 1)
        dut.fish_caught.value = 0
        await ClockCycles(dut.clk, 1)
    assert dut.battery_left.value == battery + 1
    dut._log.info("    Ate successfully, battery increased.")


# Tests if the battery cannot exceed 8 levels.
@cocotb.test()
async def battery_max_test(dut):
    await setup_test(dut, 11)

    # Number of cycles to sleep before the battery increases.
    SLEEP_TIME = 10

    dut._log.info("Entering Sleeping state.")
    dut.Y.value = 1
    await ClockCycles(dut.clk, 1)
    dut.Y.value = 0
    await ClockCycles(dut.clk, 1)
    assert_state(dut, STATE_SLEEPING)
    dut._log.info("    Entered Sleeping state successfully.")

    dut._log.info("Sleeping for a long time.")
    await ClockCycles(dut.clk, SLEEP_TIME * 3)
    await ClockCycles(dut.clk, 5)
    assert dut.battery_left.value == 8
    dut._log.info("    Sleeping for a long time successul, battery levels did not exceed 8.")



