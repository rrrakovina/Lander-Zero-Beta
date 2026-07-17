import os
import math
import struct
import wave
import random

def generate_wav(filename, duration, sample_rate, wave_func):
    num_samples = int(duration * sample_rate)
    with wave.open(filename, 'wb') as wav_file:
        wav_file.setnchannels(1)  # Mono
        wav_file.setsampwidth(2) # 16-bit
        wav_file.setframerate(sample_rate)
        
        for i in range(num_samples):
            t = i / sample_rate
            value = wave_func(t, i)
            # Clip value to 16-bit range
            value = max(-1.0, min(1.0, value))
            int_value = int(value * 32767)
            wav_file.writeframes(struct.pack('<h', int_value))

def generate_assets():
    out_dir = "../assets/audio"
    os.makedirs(out_dir, exist_ok=True)
    sample_rate = 22050

    # 1. thrust.wav: Low rumble/noise
    def thrust_func(t, i):
        # Sine waves mix + small random noise
        wave1 = math.sin(2 * math.pi * 60 * t)
        wave2 = math.sin(2 * math.pi * 110 * t)
        noise = random.uniform(-0.3, 0.3)
        return (wave1 * 0.4 + wave2 * 0.3 + noise * 0.3) * 0.5

    # 2. coin.wav: High pitch ding
    def coin_func(t, i):
        # Freq starts at 900Hz and goes up to 1400Hz
        freq = 900 + 500 * (t / 0.15)
        env = math.exp(-6 * t)  # decay
        return math.sin(2 * math.pi * freq * t) * env * 0.8

    # 3. collision.wav: Low rumbling explosion/crash
    def collision_func(t, i):
        # White noise with low pass decay
        noise = random.uniform(-1.0, 1.0)
        env = math.exp(-8 * t)
        rumble = math.sin(2 * math.pi * 50 * t) * 0.5
        return (noise * 0.6 + rumble * 0.4) * env * 0.9

    # 4. dock.wav: short mechanical lock sound (two short pulses)
    def dock_func(t, i):
        if t < 0.05:
            return math.sin(2 * math.pi * 500 * t) * 0.7
        elif 0.05 <= t < 0.07:
            return 0.0
        else:
            t2 = t - 0.07
            return math.sin(2 * math.pi * 750 * t2) * 0.7 * math.exp(-15 * t2)

    # 5. victory.wav: ascending major chord arpeggio
    def victory_func(t, i):
        # 0 to 0.25s: C5 (523Hz)
        # 0.25 to 0.5s: E5 (659Hz)
        # 0.5 to 0.75s: G5 (784Hz)
        # 0.75 to 1.5s: C6 (1046Hz) with decay
        if t < 0.25:
            return math.sin(2 * math.pi * 523 * t) * 0.5
        elif t < 0.5:
            return math.sin(2 * math.pi * 659 * t) * 0.5
        elif t < 0.75:
            return math.sin(2 * math.pi * 784 * t) * 0.5
        else:
            t2 = t - 0.75
            return math.sin(2 * math.pi * 1046 * t2) * 0.5 * math.exp(-2 * t2)

    # 6. defeat.wav: sad descending tone
    def defeat_func(t, i):
        # Frequency slides from 350Hz down to 100Hz
        freq = 350 - 250 * (t / 1.0)
        env = math.exp(-1.5 * t)
        return math.sin(2 * math.pi * freq * t) * env * 0.6

    # 7. bg_music.wav: repetitive synth loop
    def bg_music_func(t, i):
        # simple arpeggiator/lfo ambient drone
        # chord notes: Am (220, 261, 329Hz), F (174, 220, 261Hz) changing every 4 seconds
        t_loop = t % 8.0
        if t_loop < 4.0:
            # Am
            f1, f2, f3 = 110.0, 220.0, 329.63
        else:
            # F
            f1, f2, f3 = 87.31, 174.61, 261.63
        
        # slow sweep lfo
        lfo = 0.5 + 0.3 * math.sin(2 * math.pi * 0.25 * t)
        
        wave1 = math.sin(2 * math.pi * f1 * t)
        wave2 = math.sin(2 * math.pi * f2 * t)
        wave3 = math.sin(2 * math.pi * f3 * t)
        
        return (wave1 * 0.5 + wave2 * 0.3 + wave3 * 0.2) * lfo * 0.4

    generate_wav(os.path.join(out_dir, "thrust.wav"), 1.0, sample_rate, thrust_func)
    generate_wav(os.path.join(out_dir, "coin.wav"), 0.15, sample_rate, coin_func)
    generate_wav(os.path.join(out_dir, "collision.wav"), 0.8, sample_rate, collision_func)
    generate_wav(os.path.join(out_dir, "dock.wav"), 0.15, sample_rate, dock_func)
    generate_wav(os.path.join(out_dir, "victory.wav"), 1.5, sample_rate, victory_func)
    generate_wav(os.path.join(out_dir, "defeat.wav"), 1.2, sample_rate, defeat_func)
    generate_wav(os.path.join(out_dir, "bg_music.wav"), 8.0, sample_rate, bg_music_func)
    
    print("Audio assets generated successfully!")

if __name__ == "__main__":
    generate_assets()
