# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import os
import time
from threading import Thread

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

from flask import Flask, render_template
from flask_socketio import SocketIO

app = Flask(__name__)
socketio = SocketIO(app)

keys = {}

@app.route("/")
def index():
    return render_template("index.html")

@socketio.on("key")
def on_key(data):
    keys[data["key"]] = data["pressed"]

@app.route("/state")
def state():
    return keys

def run_webserver():
    socketio.run(app, host="0.0.0.0", port=5000)

FPS = 24
FRAME_TIME = 1.0 / FPS
SIMULATION_FREQUENCY = 3_000


async def setup_simulation(dut):
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

    # Set the clock period to 10 us (25 MHz)
    clock = Clock(dut.clk, int(1_000_000 / SIMULATION_FREQUENCY), unit="ns")
    cocotb.start_soon(clock.start())

    await ClockCycles(dut.clk, 1)
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 1)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1)


def clear_console():
    os.system('cls' if os.name == 'nt' else 'clear')

def print_stats(stats: dict):
    SPACING = 32

    for key, value in stats.items():
        print(f"{key}{" "*(SPACING-len(key))}: {value}")

def is_pressed(key: str):
    return key in keys.keys() and keys[key]


# This file is used to test the tamagotchi in a real-time simulation.
# This test checks if the rst_n sequence is as expected for the main_controller.
@cocotb.test()
async def simulation(dut):
    await setup_simulation(dut)
    
    Thread(target=run_webserver, daemon=True).start()

    while not is_pressed('Escape'):
        start_of_frame = time.perf_counter()

        # Inputs.
        dut.left.value =is_pressed('ArrowLeft')
        dut.right.value = is_pressed('ArrowRight')
        dut.up.value = is_pressed('ArrowUp')
        dut.down.value = is_pressed('ArrowDown')
        dut.A.value = is_pressed('a')
        dut.B.value = is_pressed('b')
        dut.X.value = is_pressed('x')
        dut.Y.value = is_pressed('y')
        
        dut.fish_caught.value = is_pressed('f')
        dut.rst_n.value = not is_pressed('r')

        # Outputs.
        stats = dict()
        stats["pos_x"] = str(dut.cat_pos_x.value)
        stats["pos_y"] = str(dut.cat_pos_y.value)
        stats["lives"] = str(dut.lives_left.value)
        stats["battery"] = str(dut.battery_left.value)
        stats["state"] = "BANG" if dut.show_bang.value == 1 else \
                         "DEFAULT" if dut.is_default_state.value == 1 else \
                         "PLAYING" if dut.is_playing.value == 1 else \
                         "EATING" if dut.is_eating.value == 1 else \
                         "SLEEPING" if dut.is_sleeping.value == 1 else \
                         "DEAD" if dut.is_dead.value == 1 else \
                         "<UNKNOWN_STATE>"
        # stats["keys"] = str(keys)
        clear_console()
        print_stats(stats)

        # Advance Simulation.
        await ClockCycles(dut.clk, int(SIMULATION_FREQUENCY/24))
        
        # Stabilise FPS.
        frame_time = time.perf_counter() - start_of_frame
        if frame_time > FRAME_TIME:
            print("FRAMERATE COULD NOT KEEP UP")
        time.sleep(max(0, FRAME_TIME - frame_time))