import numpy as np
import wave

sample_rate = 44100
duration = 18.5
total_samples = int(sample_rate * duration)

left_audio = np.zeros(total_samples, dtype=np.float32)
right_audio = np.zeros(total_samples, dtype=np.float32)

# ==============================================================================
# 1. PURE TYPING SOUND (0.0s to 5.8s) - ABSOLUTE SILENCE IN BACKGROUND
# ==============================================================================
# Rhythmic, crisp mechanical keyboard clicks matching each typed letter
num_clicks = 135
typing_start = 0.12
typing_end = 5.75
click_times = np.linspace(typing_start, typing_end, num_clicks)

for i, ct in enumerate(click_times):
    # Slight micro-timing jitter like real typing
    jitter = ((i * 17) % 7 - 3) * 0.003
    t_actual = ct + jitter
    idx = int(sample_rate * t_actual)
    click_len = int(sample_rate * 0.018)
    if idx + click_len < total_samples:
        tc = np.linspace(0, 0.018, click_len)
        # Resonant key frequency with pleasant mechanical tactile pop
        fc = 1650.0 + ((i * 31) % 9) * 120.0
        click = (np.sin(2 * np.pi * fc * tc) * 0.7 + np.sin(2 * np.pi * (fc * 0.45) * tc) * 0.3) * np.exp(-tc * 290.0) * 0.22
        # Slight stereo spread across keyboard width
        pan = 0.35 + 0.3 * ((i % 5) / 4.0)
        left_audio[idx : idx + click_len] += click * pan
        right_audio[idx : idx + click_len] += click * (1.0 - pan)

# ==============================================================================
# 2. TERMINAL OPEN & SCRIPT EXECUTION (5.8s to 10.5s)
# ==============================================================================
# Terminal window open sound (clean modern UI pop)
idx_topen = int(sample_rate * 5.85)
nt_open = int(sample_rate * 0.08)
t_op = np.linspace(0, 0.08, nt_open)
ui_pop = np.sin(2 * np.pi * 320.0 * t_op) * np.exp(-t_op * 45.0) * 0.35
left_audio[idx_topen : idx_topen + nt_open] += ui_pop
right_audio[idx_topen : idx_topen + nt_open] += ui_pop

# Enter key press to run script
idx_enter = int(sample_rate * 6.25)
n_ent = int(sample_rate * 0.03)
t_ent = np.linspace(0, 0.03, n_ent)
enter_pop = (np.sin(2 * np.pi * 550.0 * t_ent) + np.sin(2 * np.pi * 180.0 * t_ent) * 0.8) * np.exp(-t_ent * 80.0) * 0.4
left_audio[idx_enter : idx_enter + n_ent] += enter_pop
right_audio[idx_enter : idx_enter + n_ent] += enter_pop

# Error buzzer 1 (6.8s)
idx_e1 = int(sample_rate * 6.8)
n_e1 = int(sample_rate * 0.32)
te1 = np.linspace(0, 0.32, n_e1)
b1 = (np.sin(2 * np.pi * 340.0 * te1) + np.sin(2 * np.pi * 370.0 * te1)) * np.exp(-te1 * 6.5) * 0.28
left_audio[idx_e1 : idx_e1 + n_e1] += b1
right_audio[idx_e1 : idx_e1 + n_e1] += b1

# Error buzzer 2 (7.4s)
idx_e2 = int(sample_rate * 7.4)
n_e2 = int(sample_rate * 0.32)
te2 = np.linspace(0, 0.32, n_e2)
b2 = (np.sin(2 * np.pi * 320.0 * te2) + np.sin(2 * np.pi * 350.0 * te2)) * np.exp(-te2 * 6.5) * 0.30
left_audio[idx_e2 : idx_e2 + n_e2] += b2
right_audio[idx_e2 : idx_e2 + n_e2] += b2

# Error buzzer 3 (8.0s)
idx_e3 = int(sample_rate * 8.0)
n_e3 = int(sample_rate * 0.32)
te3 = np.linspace(0, 0.32, n_e3)
b3 = (np.sin(2 * np.pi * 300.0 * te3) + np.sin(2 * np.pi * 330.0 * te3)) * np.exp(-te3 * 6.5) * 0.32
left_audio[idx_e3 : idx_e3 + n_e3] += b3
right_audio[idx_e3 : idx_e3 + n_e3] += b3

# Infinite number stream calculation riser (8.6s to 10.5s)
idx_inf = int(sample_rate * 8.6)
n_inf = int(sample_rate * 1.9)
t_inf = np.linspace(0, 1.9, n_inf)
freq_sweep = 440.0 * (2600.0 / 440.0) ** (t_inf ** 1.6)
phase_inf = 2 * np.pi * np.cumsum(freq_sweep) / sample_rate
# Rapid high-speed digital pulse flutter (simulating endless digits flooding the stream)
flutter_inf = 0.5 + 0.5 * np.sin(2 * np.pi * 60.0 * t_inf)
data_stream = np.sin(phase_inf) * flutter_inf * (t_inf / 1.9) * 0.38
left_audio[idx_inf : idx_inf + n_inf] += data_stream
right_audio[idx_inf : idx_inf + n_inf] += data_stream

# Cut/Glitch transient when switching to the other view (10.5s)
idx_glitch = int(sample_rate * 10.48)
n_glitch = int(sample_rate * 0.05)
t_g = np.linspace(0, 0.05, n_glitch)
g_sound = np.random.uniform(-0.4, 0.4, n_glitch) * np.exp(-t_g * 60.0)
left_audio[idx_glitch : idx_glitch + n_glitch] += g_sound
right_audio[idx_glitch : idx_glitch + n_glitch] += g_sound

# ==============================================================================
# 3. OTHER VIEW: BLACK HOLE VISTA (10.5s to 13.0s)
# ==============================================================================
# Gravitational Sub-Bass & Event Horizon Drone
idx_bh = int(sample_rate * 10.5)
n_bh = int(sample_rate * 2.8)
tb = np.linspace(0, 2.8, n_bh)
bh_drone = (
    0.48 * np.sin(2 * np.pi * 48.0 * tb) +
    0.28 * np.sin(2 * np.pi * 96.0 * tb) +
    0.15 * np.sin(2 * np.pi * 144.0 * tb)
) * np.sin(np.pi * np.clip(tb / 2.8, 0, 1))
left_audio[idx_bh : idx_bh + n_bh] += bh_drone * 0.72
right_audio[idx_bh : idx_bh + n_bh] += bh_drone * 0.72

# ==============================================================================
# 4. INSIDE CABIN LOOKING AT SUN (13.0s to 15.5s)
# ==============================================================================
# Warm cockpit ambient synth pad & solar radiance
idx_cbn = int(sample_rate * 13.0)
n_cbn = int(sample_rate * 2.8)
tcbn = np.linspace(0, 2.8, n_cbn)
cbn_chord = (
    0.35 * np.sin(2 * np.pi * 87.31 * tcbn) +
    0.30 * np.sin(2 * np.pi * 110.0 * tcbn) +
    0.25 * np.sin(2 * np.pi * 130.81 * tcbn)
) * (np.sin(np.pi * np.clip(tcbn / 2.8, 0, 1)) ** 1.2)
left_audio[idx_cbn : idx_cbn + n_cbn] += cbn_chord * 0.65
right_audio[idx_cbn : idx_cbn + n_cbn] += cbn_chord * 0.65

# ==============================================================================
# 5. SUN ISOLATION & TITLE CRESCENDO (15.5s to 18.5s)
# ==============================================================================
idx_title = int(sample_rate * 15.5)
n_title = total_samples - idx_title
tt = np.linspace(0, (duration - 15.5), n_title)
env_t = np.sin(np.pi * np.clip(tt / 3.0, 0, 1)) ** 1.3
title_chord = (
    0.50 * np.sin(2 * np.pi * 73.42 * tt) +
    0.42 * np.sin(2 * np.pi * 110.0 * tt) +
    0.36 * np.sin(2 * np.pi * 146.83 * tt) +
    0.30 * np.sin(2 * np.pi * 174.61 * tt) +
    0.24 * np.sin(2 * np.pi * 220.0 * tt)
) * env_t * 0.85
left_audio[idx_title : idx_title + n_title] += title_chord
right_audio[idx_title : idx_title + n_title] += title_chord

# Normalize mix
max_val = max(np.max(np.abs(left_audio)), np.max(np.abs(right_audio)))
if max_val > 0:
    left_audio = (left_audio / max_val) * 0.88
    right_audio = (right_audio / max_val) * 0.88

out_path = "assets/audio/pure_typing_intro_soundtrack.wav"
with wave.open(out_path, "wb") as wf:
    wf.setnchannels(2)
    wf.setsampwidth(2)
    wf.setframerate(sample_rate)
    interleaved = np.empty((total_samples * 2,), dtype=np.int16)
    interleaved[0::2] = (left_audio * 32767.0).astype(np.int16)
    interleaved[1::2] = (right_audio * 32767.0).astype(np.int16)
    wf.writeframes(interleaved.tobytes())

print(f"[Authentic Intro Audio] Generated {out_path} ({duration}s)")
