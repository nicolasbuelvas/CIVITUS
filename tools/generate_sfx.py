import wave
import struct
import math
import os

OUTPUT_DIR = "assets/audio"
os.makedirs(OUTPUT_DIR, exist_ok=True)
SAMPLE_RATE = 44100

def write_wav(filename, samples):
    path = os.path.join(OUTPUT_DIR, filename)
    with wave.open(path, 'w') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        for s in samples:
            val = max(-32767, min(32767, int(s * 32767)))
            w.writeframesraw(struct.pack('<h', val))

# 1. Hop / Jump SFX (Paper Pop)
def gen_hop():
    duration = 0.12
    n = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        freq = 300 + (t / duration) * 450 # rising pitch
        env = 1.0 - (t / duration)
        samples.append(math.sin(2 * math.pi * freq * t) * env * 0.7)
    write_wav("sfx_hop.wav", samples)

# 2. Mine / Hit Chime
def gen_mine():
    duration = 0.18
    n = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        freq = 600 + math.sin(t * 80) * 100
        env = math.exp(-t * 18.0)
        s = math.sin(2 * math.pi * freq * t) * env * 0.8
        # Add harmonic
        s += math.sin(2 * math.pi * freq * 2.0 * t) * env * 0.3
        samples.append(s)
    write_wav("sfx_mine.wav", samples)

# 3. Crystal Collected Ding
def gen_collect():
    duration = 0.35
    n = int(SAMPLE_RATE * duration)
    samples = []
    notes = [523.25, 659.25, 783.99, 1046.50] # C5, E5, G5, C6 arpeggio
    note_dur = duration / len(notes)
    for i in range(n):
        t = i / SAMPLE_RATE
        idx = min(int(t / note_dur), len(notes) - 1)
        note_t = t - (idx * note_dur)
        freq = notes[idx]
        env = math.exp(-note_t * 12.0)
        s = math.sin(2 * math.pi * freq * t) * env * 0.75
        samples.append(s)
    write_wav("sfx_collect.wav", samples)

# 4. Rocket Thruster Loop / Burst
def gen_thruster():
    import random
    duration = 0.4
    n = int(SAMPLE_RATE * duration)
    samples = []
    val = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        env = math.sin(math.pi * (t / duration))
        white = (random.random() * 2.0 - 1.0)
        # Low-pass filter for roar
        val += (white - val) * 0.15
        samples.append(val * env * 0.85)
    write_wav("sfx_thruster.wav", samples)

# 5. UI Click
def gen_click():
    duration = 0.05
    n = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = 1.0 - (t / duration)
        samples.append(math.sin(2 * math.pi * 950 * t) * env * 0.6)
    write_wav("sfx_click.wav", samples)

if __name__ == "__main__":
    gen_hop()
    gen_mine()
    gen_collect()
    gen_thruster()
    gen_click()
    print("Audio SFX generated successfully!")
