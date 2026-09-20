import numpy as np
import wave

sample_rate = 44100
duration = 20.0
total_samples = int(sample_rate * duration)

left_audio = np.zeros(total_samples, dtype=np.float32)
right_audio = np.zeros(total_samples, dtype=np.float32)
t = np.linspace(0, duration, total_samples, endpoint=False)

# 1. BEAT 1A: ONLY mechanical typing clicks (0.0s to 5.2s) - PURE SILENCE IN BACKGROUND
# Rapid, rhythmic key clicks for each character
for i in range(120):
    ct = 0.1 + i * 0.042
    if ct > 5.2:
        break
    idx_c = int(sample_rate * ct)
    nc = int(sample_rate * 0.016)
    if idx_c + nc < total_samples:
        tc = np.linspace(0, 0.016, nc)
        fc = 1700.0 + (i % 11) * 140.0
        click = np.sin(2 * np.pi * fc * tc) * np.exp(-tc * 320.0) * 0.22
        # Slight stereo variance like real keyboard hands
        pan = 0.4 + 0.2 * (i % 3)
        left_audio[idx_c : idx_c + nc] += click * pan
        right_audio[idx_c : idx_c + nc] += click * (1.0 - pan)

# 2. BEAT 1B: Terminal open & execution errors + infinite numbers stream (5.5s to 8.5s)
# Terminal open thud
idx_t_open = int(sample_rate * 5.45)
nt_open = int(sample_rate * 0.1)
tt_open = np.linspace(0, 0.1, nt_open)
open_thud = np.sin(2 * np.pi * 120.0 * tt_open) * np.exp(-tt_open * 35.0) * 0.35
left_audio[idx_t_open : idx_t_open + nt_open] += open_thud
right_audio[idx_t_open : idx_t_open + nt_open] += open_thud

# Error buzzer at 6.3s
idx_err = int(sample_rate * 6.3)
n_err = int(sample_rate * 0.4)
te = np.linspace(0, 0.4, n_err)
err_buzz = (np.sin(2 * np.pi * 380.0 * te) + np.sin(2 * np.pi * 410.0 * te)) * np.exp(-te * 6.0) * 0.35
left_audio[idx_err : idx_err + n_err] += err_buzz
right_audio[idx_err : idx_err + n_err] += err_buzz

# Calculation tone & infinite stream data riser (7.2s to 8.5s)
idx_stream = int(sample_rate * 7.2)
n_stream = int(sample_rate * 1.3)
ts = np.linspace(0, 1.3, n_stream)
stream_f = 600.0 * (2400.0 / 600.0) ** (ts ** 1.8)
stream_phase = 2 * np.pi * np.cumsum(stream_f) / sample_rate
stream_sound = np.sin(stream_phase) * (ts ** 1.5) * 0.28
# Data packet flutter
flutter = 0.5 + 0.5 * np.sin(2 * np.pi * 45.0 * ts)
stream_sound *= flutter
left_audio[idx_stream : idx_stream + n_stream] += stream_sound * 0.6
right_audio[idx_stream : idx_stream + n_stream] += stream_sound * 0.6

# 3. BEAT 2: Deep Gravitational Black Hole Drone & Sub-Bass (8.5s to 12.0s)
idx_bh = int(sample_rate * 8.5)
n_bh = int(sample_rate * 3.5)
tb = np.linspace(0, 3.5, n_bh)
bh_drone = (
    0.45 * np.sin(2 * np.pi * 48.0 * tb) +
    0.28 * np.sin(2 * np.pi * 96.0 * tb)
) * np.sin(np.pi * np.clip(tb / 3.5, 0, 1))
left_audio[idx_bh : idx_bh + n_bh] += bh_drone * 0.7
right_audio[idx_bh : idx_bh + n_bh] += bh_drone * 0.7

# 4. BEAT 3: Cockpit Atmosphere & Warm Sunlight Synth (12.0s to 15.5s)
idx_cbn = int(sample_rate * 12.0)
n_cbn = int(sample_rate * 3.5)
tcbn = np.linspace(0, 3.5, n_cbn)
cbn_chord = (
    0.35 * np.sin(2 * np.pi * 87.31 * tcbn) +
    0.30 * np.sin(2 * np.pi * 110.0 * tcbn) +
    0.25 * np.sin(2 * np.pi * 130.81 * tcbn)
) * (np.sin(np.pi * np.clip(tcbn / 3.5, 0, 1)) ** 1.2)
left_audio[idx_cbn : idx_cbn + n_cbn] += cbn_chord * 0.65
right_audio[idx_cbn : idx_cbn + n_cbn] += cbn_chord * 0.65

# 5. BEAT 4: Monumental Orchestral Crescendo & Title Resolve (15.5s to 20.0s)
idx_title = int(sample_rate * 15.5)
n_title = total_samples - idx_title
tt = np.linspace(0, (duration - 15.5), n_title)
env_t = np.sin(np.pi * np.clip(tt / 4.5, 0, 1)) ** 1.3
title_chord = (
    0.50 * np.sin(2 * np.pi * 73.42 * tt) +
    0.42 * np.sin(2 * np.pi * 110.0 * tt) +
    0.36 * np.sin(2 * np.pi * 146.83 * tt) +
    0.30 * np.sin(2 * np.pi * 174.61 * tt) +
    0.25 * np.sin(2 * np.pi * 220.0 * tt)
) * env_t * 0.85
left_audio[idx_title : idx_title + n_title] += title_chord
right_audio[idx_title : idx_title + n_title] += title_chord

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

print(f"[Audio Generator] Created {out_path}")
