import numpy as np
import wave

sample_rate = 44100
duration = 17.0
total_samples = int(sample_rate * duration)

left_audio = np.zeros(total_samples, dtype=np.float32)
right_audio = np.zeros(total_samples, dtype=np.float32)

# ==============================================================================
# 1. PURE MECHANICAL TYPING (0.0s to 5.5s) - ABSOLUTE SILENCE IN BACKGROUND
# ==============================================================================
num_clicks = 130
typing_start = 0.15
typing_end = 5.35
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
    n = int(sample_rate * 0.30)
    te = np.linspace(0, 0.30, n)
    buzz = (np.sin(2 * np.pi * 320.0 * te) + np.sin(2 * np.pi * 360.0 * te)) * np.exp(-te * 7.0) * 0.32
    left_audio[idx : idx + n] += buzz
    right_audio[idx : idx + n] += buzz

# Execution start (5.6s)
add_enter_click(5.6)

# Error 1 (6.4s)
add_error_buzz(6.4)

# Error 2 (7.5s)
add_error_buzz(7.5)

# Distance stream riser (8.6s to 11.0s)
idx_inf = int(sample_rate * 8.8)
n_inf = int(sample_rate * 2.2)
t_inf = np.linspace(0, 2.2, n_inf)
freq_sweep = 440.0 * (2600.0 / 440.0) ** (t_inf ** 1.6)
phase_inf = 2 * np.pi * np.cumsum(freq_sweep) / sample_rate
flutter_inf = 0.5 + 0.5 * np.sin(2 * np.pi * 60.0 * t_inf)
data_stream = np.sin(phase_inf) * flutter_inf * (t_inf / 2.2) * 0.38
left_audio[idx_inf : idx_inf + n_inf] += data_stream
right_audio[idx_inf : idx_inf + n_inf] += data_stream

# Transient to Black Hole (11.0s)
idx_glitch = int(sample_rate * 10.98)
n_glitch = int(sample_rate * 0.05)
t_g = np.linspace(0, 0.05, n_glitch)
g_sound = np.random.uniform(-0.4, 0.4, n_glitch) * np.exp(-t_g * 60.0)
left_audio[idx_glitch : idx_glitch + n_glitch] += g_sound
right_audio[idx_glitch : idx_glitch + n_glitch] += g_sound

# ==============================================================================
# 2. BLACK HOLE VISTA (11.0s to 13.0s) - EXACTLY 2.0 SECONDS
# ==============================================================================
idx_bh = int(sample_rate * 11.0)
n_bh = int(sample_rate * 2.0)
tb = np.linspace(0, 2.0, n_bh)
bh_env = np.sin(np.pi * np.clip(tb / 2.0, 0, 1)) ** 0.6
bh_drone = (
    0.60 * np.sin(2 * np.pi * 50.0 * tb) +
    0.38 * np.sin(2 * np.pi * 100.0 * tb) +
    0.22 * np.sin(2 * np.pi * 150.0 * tb)
) * bh_env
left_audio[idx_bh : idx_bh + n_bh] += bh_drone * 0.88
right_audio[idx_bh : idx_bh + n_bh] += bh_drone * 0.88

# ==============================================================================
# 3. FAST WINDOW FLIGHT (13.0s to 15.0s, 2.0s) & TITLE HIT (15.0s to 17.0s, 2.0s)
# ==============================================================================
# 3A: Window flight whoosh (13.0s to 15.0s)
idx_flight = int(sample_rate * 13.0)
n_flight = int(sample_rate * 2.0)
tfl = np.linspace(0, 2.0, n_flight)
flight_whoosh = (
    np.sin(2 * np.pi * 65.0 * tfl) * 0.45 +
    np.sin(2 * np.pi * 130.0 * tfl) * 0.25
) * np.sin(np.pi * np.clip(tfl / 2.0, 0, 1)) * 0.85
left_audio[idx_flight : idx_flight + n_flight] += flight_whoosh
right_audio[idx_flight : idx_flight + n_flight] += flight_whoosh

# 3B: Title Impact & Orchestral Sustained Resolve (15.0s to 17.0s)
idx_title = int(sample_rate * 15.0)
n_title = total_samples - idx_title
tti = np.linspace(0, 2.0, n_title)
title_env = np.sin(np.pi * np.clip(tti / 2.0, 0, 1)) ** 0.85

title_chord = (
    0.55 * np.sin(2 * np.pi * 73.42 * tti) +
    0.45 * np.sin(2 * np.pi * 110.0 * tti) +
    0.38 * np.sin(2 * np.pi * 146.83 * tti) +
    0.32 * np.sin(2 * np.pi * 174.61 * tti) +
    0.26 * np.sin(2 * np.pi * 220.0 * tti)
) * title_env * 0.95

title_boom = np.sin(2 * np.pi * 48.0 * tti) * np.exp(-tti * 3.0) * 0.75
left_audio[idx_title : idx_title + n_title] += (title_chord + title_boom) * 0.90
right_audio[idx_title : idx_title + n_title] += (title_chord + title_boom) * 0.90

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
