# Sample Testbench for a Tiny Tapeout Project

This is a sample testbench for a Tiny Tapeout project. It uses [cocotb](https://docs.cocotb.org/en/stable/) to drive the DUT and check the outputs.
For more information, check the [Tiny Tapeout website](https://tinytapeout.com/hdl/testing/).

## Setting Up

1. Edit the [Makefile](Makefile) and modify `PROJECT_SOURCES` to point to your Verilog files.
2. Edit [tb.v](tb.v) and replace `tt_um_example` with your module name.

## Running Simulations

### RTL Simulation

```sh
make
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

## VGA Output Verification

This project drives a VGA display through the
[TinyVGA Pmod](https://github.com/mole99/tiny-vga) pinout on `uo_out`. The
[cocotb-vga](../lib/cocotb-vga) library (git submodule) captures the VGA
signals during simulation into PNG frames and an animated GIF, and checks
the sync timing cycle-accurately.

`test.py` contains a `test_vga_frames` test that writes captured frames to
`test/output/`. It is skipped until the design actually produces VGA output;
enable it with:

```sh
VGA_TEST=1 make -B
```

For a complete working example — a color-bar generator in `src/` verified
pixel-exactly through this exact flow — check out the `vga-example` branch.
The library's own tests live in its repo. If the submodule directory is
empty, run `git submodule update --init` first.

## Viewing Waveforms

With [GTKWave](https://gtkwave.sourceforge.net/):

```sh
gtkwave tb.fst tb.gtkw
```

With [Surfer](https://surfer-project.org/):

```sh
surfer tb.fst
```
