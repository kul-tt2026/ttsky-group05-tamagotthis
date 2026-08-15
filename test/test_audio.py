import cocotb
from cocotb.triggers import RisingEdge, Timer
import numpy as np
from scipy.io.wavfile import write


# ============================================================
# PARAMETERS
# ============================================================

CLK_FREQ = 25_000_000

# The Verilog testbench produces one sample every 256 clocks.
PWM_PERIOD = 256

SAMPLE_SOURCE_FS = CLK_FREQ / PWM_PERIOD
# = 97,656.25 samples per second

AUDIO_FS = 44_100


# ============================================================
# APPROXIMATE RC LOW-PASS FILTER
# ============================================================

R = 1000.0
C = 100e-9

tau = R * C

dt = 1.0 / SAMPLE_SOURCE_FS

alpha = dt / (tau + dt)


# ============================================================
# CLEAR ALL SOUND INPUTS
# ============================================================

def clear_sounds(dut):

    dut.fish_caught.value = 0
    dut.play_bang.value = 0
    dut.play_default.value = 0
    dut.play_sleeping.value = 0
    dut.play_dead.value = 0
    dut.battery_almost_empty.value = 0


# ============================================================
# RECORD AUDIO
#
# Cocotb waits for sample_valid, which occurs once every
# 256 system clocks.
#
# We do NOT wait for every 25 MHz clock.
# ============================================================

async def record_audio(
    dut,
    duration,
    audio,
    filter_state,
    resample_state
):

    number_of_samples = int(
        duration * SAMPLE_SOURCE_FS
    )

    filtered = filter_state[0]

    for _ in range(number_of_samples):

        # Wait for one averaged PWM sample.
        while True:

            await RisingEdge(dut.clk)

            if int(dut.sample_valid.value):
                break

        # ----------------------------------------------------
        # Convert 8-bit duty cycle to voltage.
        #
        # 0   -> 0.0 V
        # 255 -> 3.3 V
        # ----------------------------------------------------

        duty = int(dut.audio_sample.value)

        voltage = 3.3 * duty / 255.0

        # ----------------------------------------------------
        # RC low-pass filter
        # ----------------------------------------------------

        filtered += alpha * (
            voltage - filtered
        )

        # ----------------------------------------------------
        # Resample from approximately 97.656 kHz to 44.1 kHz.
        #
        # Fractional accumulator avoids assuming that the
        # sample rates divide evenly.
        # ----------------------------------------------------

        resample_state[0] += AUDIO_FS

        if resample_state[0] >= SAMPLE_SOURCE_FS:

            resample_state[0] -= SAMPLE_SOURCE_FS

            audio.append(filtered)

    filter_state[0] = filtered


# ============================================================
# SILENCE
# ============================================================

async def silence(
    dut,
    duration,
    audio,
    filter_state,
    resample_state
):

    clear_sounds(dut)

    await record_audio(
        dut,
        duration,
        audio,
        filter_state,
        resample_state
    )


# ============================================================
# PLAY ONE SOUND
# ============================================================

async def play_sound(
    dut,
    name,
    signal,
    duration,
    audio,
    filter_state,
    resample_state
):

    dut._log.info("--------------------------------")
    dut._log.info(f"Playing {name}")
    dut._log.info("--------------------------------")

    # Ensure every sound is off first.
    clear_sounds(dut)

    # Start requested sound.
    signal.value = 1

    # Record it.
    await record_audio(
        dut,
        duration,
        audio,
        filter_state,
        resample_state
    )

    # Stop requested sound.
    signal.value = 0


# ============================================================
# MAIN TEST
# ============================================================

@cocotb.test()
async def test_all_sounds(dut):

    # --------------------------------------------------------
    # Wait for the Verilog reset sequence.
    # --------------------------------------------------------

    await Timer(1, unit="ns")

    while int(dut.rst_n.value) == 0:
        await RisingEdge(dut.clk)

    # Give the DUT a few clocks after reset.
    for _ in range(20):
        await RisingEdge(dut.clk)

    clear_sounds(dut)

    dut._log.info("Reset complete")

    # --------------------------------------------------------
    # Audio storage
    # --------------------------------------------------------

    audio = []

    # Current RC filter output voltage.
    filter_state = [0.0]

    # Fractional accumulator for resampling.
    resample_state = [0.0]


    # ========================================================
    # 1. PLAY DEAD
    # ========================================================

    await play_sound(
        dut,
        "PLAY_DEAD",
        dut.play_dead,
        5.0,
        audio,
        filter_state,
        resample_state
    )

    await silence(
        dut,
        0.25,
        audio,
        filter_state,
        resample_state
    )


    # ========================================================
    # 2. BATTERY ALMOST EMPTY
    # ========================================================

    await play_sound(
        dut,
        "BATTERY_ALMOST_EMPTY",
        dut.battery_almost_empty,
        2.0,
        audio,
        filter_state,
        resample_state
    )

    await silence(
        dut,
        0.25,
        audio,
        filter_state,
        resample_state
    )


    # ========================================================
    # 3. FISH CAUGHT
    # ========================================================

    await play_sound(
        dut,
        "FISH_CAUGHT",
        dut.fish_caught,
        1.0,
        audio,
        filter_state,
        resample_state
    )

    await silence(
        dut,
        0.25,
        audio,
        filter_state,
        resample_state
    )


    # ========================================================
    # 4. PLAY BANG
    # ========================================================

    await play_sound(
        dut,
        "PLAY_BANG",
        dut.play_bang,
        4.0,
        audio,
        filter_state,
        resample_state
    )

    await silence(
        dut,
        0.25,
        audio,
        filter_state,
        resample_state
    )


    # ========================================================
    # 5. PLAY SLEEPING
    # ========================================================

    await play_sound(
        dut,
        "PLAY_SLEEPING",
        dut.play_sleeping,
        3.0,
        audio,
        filter_state,
        resample_state
    )

    await silence(
        dut,
        0.25,
        audio,
        filter_state,
        resample_state
    )


    # ========================================================
    # 6. PLAY DEFAULT
    # ========================================================

    await play_sound(
        dut,
        "PLAY_DEFAULT",
        dut.play_default,
        3.0,
        audio,
        filter_state,
        resample_state
    )

    await silence(
        dut,
        0.25,
        audio,
        filter_state,
        resample_state
    )


    # ========================================================
    # CONVERT TO NUMPY
    # ========================================================

    audio = np.asarray(
        audio,
        dtype=np.float32
    )

    dut._log.info(
        f"Generated {len(audio):,} audio samples"
    )


    # ========================================================
    # REMOVE DC OFFSET
    # ========================================================

    if len(audio) > 0:
        audio -= np.mean(audio)


    # ========================================================
    # NORMALIZE
    # ========================================================

    maximum = np.max(np.abs(audio))

    if maximum > 0:
        audio /= maximum


    # ========================================================
    # CONVERT TO 16-BIT PCM
    # ========================================================

    audio = (
        audio * 32767
    ).astype(np.int16)


    # ========================================================
    # WRITE WAV FILE
    # ========================================================

    write(
        "all_sounds.wav",
        AUDIO_FS,
        audio
    )

    dut._log.info("--------------------------------")
    dut._log.info("Saved all_sounds.wav")
    dut._log.info("--------------------------------")