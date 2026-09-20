import numpy as np
import wave

sample_rate = 44100
duration = 16.0
total_samples = int(sample_rate * duration)

left_audio = np.zeros(total_samples, dtype=np.float32)
right_audio = np.zeros(total_samples, dtype=np.float32)

# ==============================================================================
# 1. PURE MECHANICAL TYPING (0.0s to 6.5s) - PURE SILENCE IN BACKGROUND
# ==============================================================================
num_clicks = 150
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
    n = int(sample_rate * 0.28)
    te = np.linspace(0, 0.28, n)
    buzz = (np.sin(2 * np.pi * 320.0 * te) + np.sin(2 * np.pi * 360.0 * te)) * np.exp(-te * 7.0) * 0.32
    left_audio[idx : idx + n] += buzz
    right_audio[idx : idx + n] += buzz

# Step 1 Enter & Error (6.5s to 8.2s)
add_enter_click(6.6)
add_error_buzz(7.3)

# Step 2 Enter & Error (8.2s to 9.8s)
add_enter_click(8.3)
add_error_buzz(9.0)

# Step 3 Enter & Stream Calculation Riser (9.8s to 11.2s)
add_enter_click(9.9)
idx_inf = int(sample_rate * 10.1)
n_inf = int(sample_rate * 1.1)
t_inf = np.linspace(0, 1.1, n_inf)
freq_sweep = 440.0 * (2600.0 / 440.0) ** (t_inf ** 1.6)
phase_inf = 2 * np.pi * np.cumsum(freq_sweep) / sample_rate
flutter_inf = 0.5 + 0.5 * np.sin(2 * np.pi * 60.0 * t_inf)
data_stream = np.sin(phase_inf) * flutter_inf * (t_inf / 1.1) * 0.40
left_audio[idx_inf : idx_inf + n_inf] += data_stream
right_audio[idx_inf : idx_inf + n_inf] += data_stream

# KERNEL PANIC GLITCH & SYSTEM HALT SHOCK (11.2s to 12.0s)
idx_panic = int(sample_rate * 11.2)
n_panic = int(sample_rate * 0.7)
tp = np.linspace(0, 0.7, n_panic)
glitch = (
    np.random.uniform(-0.5, 0.5, n_panic) * np.exp(-tp * 8.0) * 0.45 +
    np.sin(2 * np.pi * 180.0 * tp) * np.exp(-tp * 5.0) * 0.40 +
    np.sin(2 * np.pi * 60.0 * tp) * 0.25
)
left_audio[idx_panic : idx_panic + n_panic] += glitch
right_audio[idx_panic : idx_panic + n_panic] += glitch

# ==============================================================================
# 2. BLACK HOLE VISTA (12.0s to 14.0s) - EXACTLY 2.0 SECONDS
# ==============================================================================
idx_bh = int(sample_rate * 12.0)
n_bh = int(sample_rate * 2.0)
tb = np.linspace(0, 2.0, n_bh)
bh_env = np.sin(np.pi * np.clip(tb / 2.0, 0, 1)) ** 0.6
bh_drone = (
    0.60 * np.sin(2 * np.pi * 50.0 * tb) +
    0.38 * np.sin(2 * np.pi * 100.0 * tb) +
    0.22 * np.sin(2 * np.pi * 150.0 * tb) +
    0.15 * np.sin(2 * np.pi * 75.0 * tb)
) * bh_env
left_audio[idx_bh : idx_bh + n_bh] += bh_drone * 0.88
right_audio[idx_bh : idx_bh + n_bh] += bh_drone * 0.88

# ==============================================================================
# 3. FAST WINDOW FLIGHT TO SUN & TITLE (14.0s to 16.0s) - EXACTLY 2.0 SECONDS
# ==============================================================================
idx_win = int(sample_rate * 14.0)
n_win = total_samples - idx_win
twin = np.linspace(0, 2.0, n_win)
win_env = np.sin(np.pi * np.clip(twin / 2.0, 0, 1)) ** 0.9

# Fast cinematic forward whoosh & orchestral resolve
title_chord = (
    0.55 * np.sin(2 * np.pi * 73.42 * twin) +
    0.45 * np.sin(2 * np.pi * 110.0 * twin) +
    0.38 * np.sin(2 * np.pi * 146.83 * twin) +
    0.32 * np.sin(2 * np.pi * 174.61 * twin) +
    0.26 * np.sin(2 * np.pi * 220.0 * twin)
) * win_env * 0.92

boom = np.sin(2 * np.pi * 50.0 * twin) * np.exp(-twin * 3.5) * 0.65
left_audio[idx_win : idx_win + n_win] += (title_chord + boom) * 0.85
right_audio[idx_win : idx_win + n_win] += (title_chord + boom) * 0.85

# Normalize
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
