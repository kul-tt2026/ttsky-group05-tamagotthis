import numpy as np
from scipy.io.wavfile import write

# ----------------------------
# Parameters
# ----------------------------

PWM_CLOCK = 25_000_000       # FPGA clock
AUDIO_FS = 44100             # wav sample rate

# Approximate TT Audio PMOD RC filter
R = 1000.0                   # ohms
C = 100e-9                   # farads

tau = R * C

# ----------------------------
# Read PWM
# ----------------------------

print("Loading PWM...")

pwm = np.loadtxt("pwm.txt", dtype=np.float32)

# convert 0/1 -> 0/3.3V
pwm *= 3.3

print(f"{len(pwm):,} PWM samples")

# ----------------------------
# RC low-pass
# ----------------------------

dt = 1 / PWM_CLOCK

alpha = dt / (tau + dt)

filtered = np.empty_like(pwm)

filtered[0] = pwm[0]

for i in range(1, len(pwm)):
    filtered[i] = filtered[i-1] + alpha * (pwm[i] - filtered[i-1])

# ----------------------------
# Downsample
# ----------------------------

step = PWM_CLOCK / AUDIO_FS

indices = (np.arange(int(len(filtered)/step))*step).astype(np.int64)

audio = filtered[indices]

# normalize

audio -= np.mean(audio)

audio /= np.max(np.abs(audio))

audio = (audio * 32767).astype(np.int16)

write("output.wav", AUDIO_FS, audio)

print("Saved output.wav")
