"""
sprite_to_hex.py
Zet een PNG sprite om naar een .hex bestand voor gebruik in Verilog ($readmemh)

Kleurindeling (2 bits per pixel):
  0 = transparant
  1 = zwart
  2 = grijs
  3 = wit
"""

from PIL import Image
import numpy as np

# ── Instellingen ──────────────────────────────────────────────
INPUT_FILE  = "kat.png"      # jouw PNG bestand
OUTPUT_FILE = "kat.hex"      # output hex bestand
# ─────────────────────────────────────────────────────────────

def kleur_naar_index(r, g, b, a):
    if a < 10:   return 0  # transparant
    if r < 10:   return 1  # zwart
    if r > 200:  return 3  # wit
    return 2                # grijs

img = Image.open(INPUT_FILE).convert("RGBA")
arr = np.array(img)
breedte, hoogte = img.size

print(f"Sprite: {breedte}×{hoogte} pixels")
print(f"Bits per pixel: 2 (4 kleuren: transparant/zwart/grijs/wit)")
print(f"Totaal: {breedte * hoogte * 2} bits = {breedte * hoogte * 2 / 8:.0f} bytes\n")

with open(OUTPUT_FILE, "w") as f:
    for y in range(hoogte):
        for x in range(breedte):
            r, g, b, a = arr[y, x]
            idx = kleur_naar_index(r, g, b, a)
            f.write(f"{idx}\n")

print(f"Geschreven naar: {OUTPUT_FILE}")
print(f"Gebruik in Verilog:")
print(f'  reg [1:0] sprite [{breedte*hoogte-1}:0];')
print(f'  initial $readmemh("{OUTPUT_FILE}", sprite);')
print(f'  // opzoeken: sprite[y * {breedte} + x]')