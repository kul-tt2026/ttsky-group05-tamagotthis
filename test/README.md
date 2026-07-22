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
make TOPLEVEL=tb_lfsr COCOTB_TEST_MODULES=lfsr_tests
# note: the lfsr test doesn't run and it says 'Couldn't find root handle tb_lfsr', 
#       just change one of the lfsr signals in tb_all from reg to wire, 
#       e.g.  reg [31:0] seed --> wire [31:0] seed
#       (don't ask why this works)
```

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
