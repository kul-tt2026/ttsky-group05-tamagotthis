# Makefile

# Defaults
SIM             ?= icarus
FST             ?= -fst
TOPLEVEL_LANG   ?= verilog
SRC_DIR         = $(PWD)/../src
PROJECT_SOURCES = project.v game_controller.v main_controller.v timer.v clock_divider.v settings_manager.v audio.v vga.v minigame.v lfsr32.v hvsync_generator.v palette_cat.v play_note.v

ifneq ($(GATES),yes)

# RTL simulation
SIM_BUILD        = sim_build/rtl/$(TOPLEVEL)
VERILOG_SOURCES += $(addprefix $(SRC_DIR)/,$(PROJECT_SOURCES))

else

# Gate level simulation
SIM_BUILD        = sim_build/gl
PDK_PATH        := $(shell find $(PDK_ROOT) -maxdepth 5 -type d -name $(PDK) 2>/dev/null | head -1)

COMPILE_ARGS += -DGL_TEST
COMPILE_ARGS += -DFUNCTIONAL
COMPILE_ARGS += -DUSE_POWER_PINS
COMPILE_ARGS += -DSIM
COMPILE_ARGS += -DUNIT_DELAY=\#1

VERILOG_SOURCES += $(PDK_PATH)/libs.ref/sky130_fd_sc_hd/verilog/primitives.v
VERILOG_SOURCES += $(PDK_PATH)/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v
VERILOG_SOURCES += $(PWD)/gate_level_netlist.v

endif

# Testbench
VERILOG_SOURCES += $(PWD)/tb_all.v

# Defaults
TOPLEVEL ?= tb_all
COCOTB_TEST_MODULES ?= combined_tests

# Testbench / Cocotb test module pairs
TEST_PAIRS := \
	tb_all:combined_tests \
	tb_timer:timer_tests \
	tb_main_controller:main_controller_tests \
	tb_audio:audio_tests \
	tb_vga:vga_tests \
	tb_minigame:minigame_tests \
	tb_clock_divider:clock_divider_tests \
	tb_settings_manager:settings_manager_tests \
	tb_lfsr32:lfsr32_tests

# ------------------------------------------------------------
# Default target
# ------------------------------------------------------------

.PHONY: all
all: sim

# ------------------------------------------------------------
# Run every test pair
# ------------------------------------------------------------

.PHONY: all_tests
all_tests:
	@set -e; \
	for pair in $(TEST_PAIRS); do \
		toplevel=$${pair%%:*}; \
		test_module=$${pair##*:}; \
		echo ""; \
		echo "========================================"; \
		echo "Running $$toplevel / $$test_module"; \
		echo "========================================"; \
		$(MAKE) --no-print-directory sim \
			TOPLEVEL=$$toplevel \
			COCOTB_TEST_MODULES=$$test_module; \
	done

# ------------------------------------------------------------
# Cocotb
# ------------------------------------------------------------

include $(shell cocotb-config --makefiles)/Makefile.sim

# ------------------------------------------------------------
# Clean
# ------------------------------------------------------------

.PHONY: clean
clean::
	rm -rf sim_build/ __pycache__/ results.xml tb_audio.fst all_sounds.wav