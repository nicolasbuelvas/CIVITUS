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

    # Deep space C minor drone chord
    chord_freqs = [65.41, 98.00, 155.56, 196.00]
    for i in range(n):
        t = i / SAMPLE_RATE
        lfo = 0.8 + 0.2 * math.sin(2 * math.pi * 0.15 * t)
        val = 0.0
        for f in chord_freqs:
            val += math.sin(2 * math.pi * f * t) * 0.12
            val += math.sin(2 * math.pi * f * 2.0 * t) * 0.04
        samples[i] += val * lfo

    # Ethereal glass chime notes
    arp_notes = [261.63, 311.13, 392.00, 466.16, 523.25, 392.00, 311.13, 261.63]
    note_interval = 2.0
    for idx, f in enumerate(arp_notes):
        start_t = idx * note_interval
        start_sample = int(start_t * SAMPLE_RATE)
        note_len = int(SAMPLE_RATE * 3.5)
        for j in range(note_len):
            target_idx = (start_sample + j) % n
            t_note = j / SAMPLE_RATE
            env = math.exp(-t_note * 1.5)
            bell = math.sin(2 * math.pi * f * t_note) * 0.18
            bell += math.sin(2 * math.pi * (f * 2.75) * t_note) * 0.06
            samples[target_idx] += bell * env

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
        freq = 80.0 * math.exp(t * 0.85)
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
        hiss_env = math.exp(-t * 3.5)
        hiss = (random.random() * 2.0 - 1.0) * hiss_env * 0.5
        thud = 0.0
        if t > 0.4:
            thud_t = t - 0.4
            thud = math.sin(2 * math.pi * 75.0 * thud_t) * math.exp(-thud_t * 8.0) * 0.8
        samples.append(hiss + thud)
    write_wav("sfx_airlock.wav", samples)

# 5. Crafting Clank (0.4 seconds)
def gen_craft_clank():
    duration = 0.4
    n = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 18.0)
        clank = math.sin(2 * math.pi * 880.0 * t) * 0.5
        clank += math.sin(2 * math.pi * 1420.0 * t) * 0.35
        clank += math.sin(2 * math.pi * 2200.0 * t) * 0.15
        samples.append(clank * env)
    write_wav("sfx_craft.wav", samples)

# 6. Jarvis Futuristic HUD Visor Activation (0.8 seconds)
def gen_jarvis_sfx():
    duration = 0.8
    n = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        # Futuristic electronic chirp & high frequency digital scan sweep
        f1 = 900.0 + 1600.0 * (t / duration)
        f2 = 2400.0 + 800.0 * math.sin(t * 30.0)
        env = math.sin(math.pi * (t / duration)) ** 0.5
        beep = (math.sin(2 * math.pi * f1 * t) * 0.4 + math.sin(2 * math.pi * f2 * t) * 0.25) * env
        samples.append(beep)
    write_wav("sfx_jarvis.wav", samples)

# 7. Docking Clamp Lock (0.6 seconds)
def gen_docking_sfx():
    duration = 0.6
    n = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 9.0)
        s = (math.sin(2 * math.pi * 140.0 * t) * 0.6 + math.sin(2 * math.pi * 480.0 * t) * 0.3) * env
        samples.append(s)
    write_wav("sfx_docking.wav", samples)

# 8. Atmospheric Reentry Plasma Rumble (2.0 seconds loopable)
def gen_reentry_sfx():
    duration = 2.0
    n = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        # Deep low frequency rumble + turbulent white noise
        rumble = math.sin(2 * math.pi * 45.0 * t) * 0.3 + math.sin(2 * math.pi * 92.0 * t) * 0.2
        noise = (random.random() * 2.0 - 1.0) * 0.35
        samples.append((rumble + noise) * 0.8)
    write_wav("sfx_reentry.wav", samples)

# 9. Loopable Melodic Space Menu Theme Track (16 seconds loopable)
def gen_menu_music():
    duration = 16.0
    n = int(SAMPLE_RATE * duration)
    samples = [0.0] * n

    # Warm analog pad chords: Ebmaj9 -> Gm7/Bb -> Cm9 -> Abmaj7(#11)
    chords = [
        [77.78, 155.56, 196.00, 233.08, 293.66, 349.23],  # Ebmaj9
        [58.27, 146.83, 174.61, 220.00, 261.63, 293.66],  # Bbmaj7
        [65.41, 130.81, 155.56, 196.00, 233.08, 293.66],  # Cm9
        [51.91, 130.81, 155.56, 196.00, 261.63, 311.13]   # Abmaj7
    ]

    chord_duration = 4.0
    overlap = 1.2
    chord_len = int((chord_duration + overlap) * SAMPLE_RATE)

    for c_idx, chord in enumerate(chords):
        start_time = c_idx * chord_duration
        start_sample = int(start_time * SAMPLE_RATE)
        
        for j in range(chord_len):
            target_idx = (start_sample + j) % n
            t_local = j / SAMPLE_RATE
            t_global = (start_time + t_local)
            
            # Smooth cosine envelope for chord transitions
            if t_local < overlap:
                env = 0.5 * (1.0 - math.cos(math.pi * t_local / overlap))
            elif t_local > chord_duration:
                rel_t = (t_local - chord_duration) / overlap
                env = 0.5 * (1.0 + math.cos(math.pi * rel_t))
            else:
                env = 1.0
                
            lfo_filter = 0.85 + 0.15 * math.sin(2 * math.pi * 0.25 * t_global)
            val = 0.0
            
            for voice_idx, f in enumerate(chord):
                is_bass = (voice_idx == 0)
                amp = 0.048 if not is_bass else 0.075
                detune = 1.0025
                drift = 0.0006 * math.sin(2 * math.pi * 0.12 * t_global + voice_idx)
                
                f1 = f * (1.0 + drift)
                f2 = f * detune * (1.0 - drift)
                
                osc1 = math.sin(2 * math.pi * f1 * t_global)
                osc2 = math.sin(2 * math.pi * f2 * t_global)
                warmth = 0.28 * math.sin(2 * math.pi * (f * 2.0) * t_global)
                
                val += (osc1 + osc2 + warmth) * amp * lfo_filter
                
            samples[target_idx] += val * env

    # Gentle celestial arpeggio melody (32 steps, 0.5s each)
    arp_melody = [
        # Ebmaj9
        311.13, 392.00, 466.16, 587.33, 698.46, 587.33, 466.16, 392.00,
        # Bbmaj7
        293.66, 349.23, 440.00, 523.25, 587.33, 523.25, 440.00, 349.23,
        # Cm9
        261.63, 311.13, 392.00, 466.16, 587.33, 466.16, 392.00, 311.13,
        # Abmaj7
        261.63, 311.13, 392.00, 523.25, 622.25, 587.33, 466.16, 392.00
    ]

    note_step = 0.5
    for idx, freq in enumerate(arp_melody):
        start_t = idx * note_step
        start_sample = int(start_t * SAMPLE_RATE)
        note_samples = int(SAMPLE_RATE * 2.0)
        
        for j in range(note_samples):
            target_idx = (start_sample + j) % n
            t_note = j / SAMPLE_RATE
            
            att = min(1.0, t_note / 0.02)
            env = att * math.exp(-t_note * 2.1)
            
            chime = math.sin(2 * math.pi * freq * t_note) * 0.16
            chime += math.sin(2 * math.pi * (freq * 2.0) * t_note) * 0.05
            chime += math.sin(2 * math.pi * (freq * 3.01) * t_note) * 0.02
            
            samples[target_idx] += chime * env
            
            # Subtle ping-pong shimmer echo
            delay_sample = (start_sample + int(0.25 * SAMPLE_RATE) + j) % n
            samples[delay_sample] += chime * env * 0.28

    # Celestial warmth breathing
    for i in range(n):
        t = i / SAMPLE_RATE
        shimmer = math.sin(2 * math.pi * 0.125 * t) * 0.5 + 0.5
        air = (random.random() * 2.0 - 1.0) * 0.008 * shimmer
        samples[i] += air

    write_wav("music_menu_theme.wav", samples)

if __name__ == "__main__":
    gen_space_music()
    gen_menu_music()
    gen_hyperdrive_sfx()
    gen_laser_loop()
    gen_airlock()
    gen_craft_clank()
    gen_jarvis_sfx()
    gen_docking_sfx()
    gen_reentry_sfx()
    print("Space audio generated successfully!")
