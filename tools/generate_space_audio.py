import wave
import struct
import math
import random
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

# 1. Atmospheric Space Music Ambient Track (16 seconds loopable)
def gen_space_music():
    duration = 16.0
    n = int(SAMPLE_RATE * duration)
    samples = [0.0] * n

    # Drone chord: C2 (65.41 Hz), G2 (98.00 Hz), Eb3 (155.56 Hz) - Deep space C minor
    chord_freqs = [65.41, 98.00, 155.56, 196.00]
    for i in range(n):
        t = i / SAMPLE_RATE
        # LFO modulation
        lfo = 0.8 + 0.2 * math.sin(2 * math.pi * 0.15 * t)
        val = 0.0
        for f in chord_freqs:
            val += math.sin(2 * math.pi * f * t) * 0.12
            # Add warm harmonics
            val += math.sin(2 * math.pi * f * 2.0 * t) * 0.04
        samples[i] += val * lfo

    # Ethereal glass arpeggio notes (spaced out)
    # C minor pentatonic notes: C4 (261.63), Eb4 (311.13), F4 (349.23), G4 (392.00), Bb4 (466.16), C5 (523.25)
    arp_notes = [261.63, 311.13, 392.00, 466.16, 523.25, 392.00, 311.13, 261.63]
    note_interval = 2.0 # every 2 seconds a bell chime
    for idx, f in enumerate(arp_notes):
        start_t = idx * note_interval
        start_sample = int(start_t * SAMPLE_RATE)
        note_len = int(SAMPLE_RATE * 3.5) # long reverb tail
        for j in range(note_len):
            target_idx = (start_sample + j) % n
            t_note = j / SAMPLE_RATE
            env = math.exp(-t_note * 1.5)
            bell = math.sin(2 * math.pi * f * t_note) * 0.18
            bell += math.sin(2 * math.pi * (f * 2.75) * t_note) * 0.06 # shimmer
            samples[target_idx] += bell * env

    # Soft stereo-like cosmic wind sweep
    for i in range(n):
        t = i / SAMPLE_RATE
        wind_mod = (math.sin(2 * math.pi * 0.08 * t) + 1.0) * 0.5
        noise = (random.random() * 2.0 - 1.0) * 0.03 * wind_mod
        samples[i] += noise

    write_wav("music_space_ambient.wav", samples)

# 2. Hyperdrive Charging / Activation Sound (4 seconds)
def gen_hyperdrive_sfx():
    duration = 4.0
    n = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        # Exponential pitch rise from 80 Hz to 2400 Hz
        freq = 80.0 * math.exp(t * 0.85)
        # Pulsing resonance
        pulse = (math.sin(2 * math.pi * (10.0 + t * 8.0) * t) + 1.0) * 0.5
        env = min(1.0, t * 1.5) * (1.0 - math.exp((t - duration) * 4.0) if t > duration - 0.5 else 1.0)
        s = (math.sin(2 * math.pi * freq * t) * 0.5 + math.sin(2 * math.pi * freq * 1.5 * t) * 0.3) * pulse * env
        samples.append(s)
    write_wav("sfx_hyperdrive_charge.wav", samples)

# 3. Mining Laser Beam Loop (1 second loopable)
def gen_laser_loop():
    duration = 1.0
    n = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        # 120Hz carrier with high frequency harmonics and buzz
        buzz = math.sin(2 * math.pi * 120.0 * t) * 0.3
        buzz += math.sin(2 * math.pi * 240.0 * t) * 0.2
        crackle = (random.random() * 2.0 - 1.0) * 0.15
        samples.append((buzz + crackle) * 0.7)
    write_wav("sfx_laser_loop.wav", samples)

# 4. Airlock Door Open / Close (1.2 seconds)
def gen_airlock():
    duration = 1.2
    n = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        # Pneumatic hiss + heavy metallic thud
        hiss_env = math.exp(-t * 3.5)
        hiss = (random.random() * 2.0 - 1.0) * hiss_env * 0.5
        thud = 0.0
        if t > 0.4:
            thud_t = t - 0.4
            thud = math.sin(2 * math.pi * 75.0 * thud_t) * math.exp(-thud_t * 8.0) * 0.8
        samples.append(hiss + thud)
    write_wav("sfx_airlock.wav", samples)

# 5. Crafting / Wrench Repair Clank (0.4 seconds)
def gen_craft_clank():
    duration = 0.4
    n = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        # Metallic impact
        env = math.exp(-t * 18.0)
        clank = math.sin(2 * math.pi * 880.0 * t) * 0.5
        clank += math.sin(2 * math.pi * 1420.0 * t) * 0.35
        clank += math.sin(2 * math.pi * 2200.0 * t) * 0.15
        samples.append(clank * env)
    write_wav("sfx_craft.wav", samples)

if __name__ == "__main__":
    gen_space_music()
    gen_hyperdrive_sfx()
    gen_laser_loop()
    gen_airlock()
    gen_craft_clank()
    print("Space audio generated successfully!")
