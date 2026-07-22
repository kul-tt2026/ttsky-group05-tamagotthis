# Sample Testbench for a Tiny Tapeout Project

This is a sample testbench for a Tiny Tapeout project. It uses [cocotb](https://docs.cocotb.org/en/stable/) to drive the DUT and check the outputs.
For more information, check the [Tiny Tapeout website](https://tinytapeout.com/hdl/testing/).

## Setting Up

1. Edit the [Makefile](Makefile) and modify `PROJECT_SOURCES` to point to your Verilog files.
2. Edit [tb.v](tb.v) and replace `tt_um_example` with your module name.

## Running Simulations

### RTL Simulation

In order to run the tests, first, make sure the current working directory is the test folder:
```sh
cd test
```
To run the tests of the entire project:
```sh
make
```
To test a single module:
```sh
make TOPLEVEL=tb_timer COCOTB_TEST_MODULES=timer_tests
make TOPLEVEL=tb_main_controller COCOTB_TEST_MODULES=main_controller_tests
make TOPLEVEL=tb_audio COCOTB_TEST_MODULES=audio_tests
make TOPLEVEL=tb_vga COCOTB_TEST_MODULES=vga_tests
make TOPLEVEL=tb_minigame COCOTB_TEST_MODULES=minigame_tests
make TOPLEVEL=tb_clock_divider COCOTB_TEST_MODULES=clock_divider_tests
make TOPLEVEL=tb_settings_manager COCOTB_TEST_MODULES=settings_manager_tests
```
To test the tamagotchi in a simulated environment:
```sh
PYTHONPATH=$PWD/simulator:$PYTHONPATH make TOPLEVEL=tb_simulator COCOTB_TEST_MODULES=simulator 
```
In the bottom right of your screen, a message will pop up that 'port 5000 has been opened', press 'Open in browser'.
Now you can give keyboard inputs in the browser window, while seeing the results in your terminal.
In order to add anything to this simulation, have a look at tb_simulator() in tb_all.v, and the test/simulator folder, together with an AI agent (that's how I made it).
Once visuals and audio are implemented, it might be beneficial to show these outputs in the browser too, I strongly suggest implementing this with an AI agent.
Currently, you can use the arrow keys to move the cat, the a, b, x and y keys as they are defined in the architecture, r to reset and f to catch a fish. Esc quits the simulation.

### Gate-Level Simulation

First, harden your project and copy `../runs/wokwi/results/final/verilog/gl/{your_module_name}.v` to `gate_level_netlist.v`. Then run:

```sh
make GATES=yes
```

### VCD Waveform Format

By default, waveforms are saved in FST format. To use VCD format instead, edit `tb.v` to use `$dumpfile("tb.vcd");` and run:

```sh
make FST=
```

### Cleaning Build Artifacts

To remove all generated files (`sim_build/`, `__pycache__/`, `results.xml`, `tb.fst`):

```sh
make clean
```

## Viewing Waveforms

With [GTKWave](https://gtkwave.sourceforge.net/):

```sh
gtkwave tb.fst tb.gtkw
```

With [Surfer](https://surfer-project.org/):

```sh
surfer tb.fst
```
