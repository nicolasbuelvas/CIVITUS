import numpy as np
import wave

sample_rate = 44100
duration = 25.0
total_samples = int(sample_rate * duration)

left_audio = np.zeros(total_samples, dtype=np.float32)
right_audio = np.zeros(total_samples, dtype=np.float32)

# ==============================================================================
# 1. PURE TYPING SOUND (0.0s to 6.5s) - LONGEST BEAT (12.0s total code/terminal)
# ==============================================================================
num_clicks = 145
typing_start = 0.15
typing_end = 6.35
click_times = np.linspace(typing_start, typing_end, num_clicks)

for i, ct in enumerate(click_times):
    jitter = ((i * 17) % 7 - 3) * 0.003
    t_actual = ct + jitter
    idx = int(sample_rate * t_actual)
    click_len = int(sample_rate * 0.018)
    if idx + click_len < total_samples:
        tc = np.linspace(0, 0.018, click_len)
        fc = 1650.0 + ((i * 31) % 9) * 120.0
        click = (np.sin(2 * np.pi * fc * tc) * 0.7 + np.sin(2 * np.pi * (fc * 0.45) * tc) * 0.3) * np.exp(-tc * 290.0) * 0.22
        pan = 0.35 + 0.3 * ((i % 5) / 4.0)
        left_audio[idx : idx + click_len] += click * pan
        right_audio[idx : idx + click_len] += click * (1.0 - pan)

def add_enter_click(t_pos):
    idx = int(sample_rate * t_pos)
    n = int(sample_rate * 0.025)
    tt = np.linspace(0, 0.025, n)
    pop = (np.sin(2 * np.pi * 500.0 * tt) + np.sin(2 * np.pi * 160.0 * tt) * 0.8) * np.exp(-tt * 85.0) * 0.38
    left_audio[idx : idx + n] += pop
    right_audio[idx : idx + n] += pop

def add_error_buzz(t_pos):
    idx = int(sample_rate * t_pos)
    n = int(sample_rate * 0.35)
    te = np.linspace(0, 0.35, n)
    buzz = (np.sin(2 * np.pi * 320.0 * te) + np.sin(2 * np.pi * 360.0 * te)) * np.exp(-te * 6.0) * 0.30
    left_audio[idx : idx + n] += buzz
    right_audio[idx : idx + n] += buzz

# Part 1 Enter & Error (6.6s to 8.2s)
add_enter_click(6.6)
add_error_buzz(7.3)

# Part 2 Enter & Error (8.3s to 9.8s)
add_enter_click(8.3)
add_error_buzz(9.0)

# Part 3 Enter & Stream Calculation Riser (9.9s to 12.0s)
add_enter_click(9.9)
idx_inf = int(sample_rate * 10.2)
n_inf = int(sample_rate * 1.8)
t_inf = np.linspace(0, 1.8, n_inf)
freq_sweep = 440.0 * (2600.0 / 440.0) ** (t_inf ** 1.6)
phase_inf = 2 * np.pi * np.cumsum(freq_sweep) / sample_rate
flutter_inf = 0.5 + 0.5 * np.sin(2 * np.pi * 60.0 * t_inf)
data_stream = np.sin(phase_inf) * flutter_inf * (t_inf / 1.8) * 0.38
left_audio[idx_inf : idx_inf + n_inf] += data_stream
right_audio[idx_inf : idx_inf + n_inf] += data_stream

# Cut/Glitch transient when switching to black hole (12.0s)
idx_glitch = int(sample_rate * 11.98)
n_glitch = int(sample_rate * 0.05)
t_g = np.linspace(0, 0.05, n_glitch)
g_sound = np.random.uniform(-0.4, 0.4, n_glitch) * np.exp(-t_g * 60.0)
left_audio[idx_glitch : idx_glitch + n_glitch] += g_sound
right_audio[idx_glitch : idx_glitch + n_glitch] += g_sound

# ==============================================================================
# 2. BLACK HOLE VISTA (12.0s to 19.5s) - SECOND LONGEST (7.5s)
# ==============================================================================
idx_bh = int(sample_rate * 12.0)
n_bh = int(sample_rate * 7.5)
tb = np.linspace(0, 7.5, n_bh)
bh_env = np.sin(np.pi * np.clip(tb / 7.5, 0, 1)) ** 0.8
bh_drone = (
    0.50 * np.sin(2 * np.pi * 48.0 * tb) +
    0.32 * np.sin(2 * np.pi * 96.0 * tb) +
    0.18 * np.sin(2 * np.pi * 144.0 * tb) +
    0.12 * np.sin(2 * np.pi * 64.0 * tb)
) * bh_env
left_audio[idx_bh : idx_bh + n_bh] += bh_drone * 0.75
right_audio[idx_bh : idx_bh + n_bh] += bh_drone * 0.75

# ==============================================================================
# 3. CABIN & WINDOW SUN APPROACH (19.5s to 25.0s) - SHORTEST & ULTRA SMOOTH (5.5s)
# ==============================================================================
# Warm cockpit ambient pad (19.5s to 22.0s)
idx_cbn = int(sample_rate * 19.5)
n_cbn = int(sample_rate * 3.5)
tcbn = np.linspace(0, 3.5, n_cbn)
cbn_chord = (
    0.35 * np.sin(2 * np.pi * 87.31 * tcbn) +
    0.30 * np.sin(2 * np.pi * 110.0 * tcbn) +
    0.25 * np.sin(2 * np.pi * 130.81 * tcbn)
) * (np.sin(np.pi * np.clip(tcbn / 3.5, 0, 1)) ** 1.1)
left_audio[idx_cbn : idx_cbn + n_cbn] += cbn_chord * 0.65
right_audio[idx_cbn : idx_cbn + n_cbn] += cbn_chord * 0.65

# Orchestral Crescendo & Title Resolve (21.5s to 25.0s)
idx_title = int(sample_rate * 21.5)
n_title = total_samples - idx_title
tt = np.linspace(0, (duration - 21.5), n_title)
env_t = np.sin(np.pi * np.clip(tt / 3.5, 0, 1)) ** 1.2
title_chord = (
    0.50 * np.sin(2 * np.pi * 73.42 * tt) +
    0.42 * np.sin(2 * np.pi * 110.0 * tt) +
    0.36 * np.sin(2 * np.pi * 146.83 * tt) +
    0.30 * np.sin(2 * np.pi * 174.61 * tt) +
    0.24 * np.sin(2 * np.pi * 220.0 * tt)
) * env_t * 0.88
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
