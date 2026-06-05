#!/usr/bin/env python3
"""
Casino Music Synthesizer - Generates high-quality casino/poker game music
Produces three tracks:
  1. lobby_ambient.mp3   - Smooth jazz lounge for the lobby
  2. blackjack_music.mp3 - Elegant table music for blackjack
  3. poker_music.mp3     - Tension/cool poker room ambiance
"""

import numpy as np
import struct
import os
import sys

SAMPLE_RATE = 44100

def note_freq(note_name):
    """Convert note name (e.g., 'C4', 'Eb3') to frequency."""
    notes = {'C': 0, 'Db': 1, 'D': 2, 'Eb': 3, 'E': 4, 'F': 5,
             'Gb': 6, 'G': 7, 'Ab': 8, 'A': 9, 'Bb': 10, 'B': 11}
    # Handle sharp notation too
    sharp_map = {'C#': 'Db', 'D#': 'Eb', 'F#': 'Gb', 'G#': 'Ab', 'A#': 'Bb'}
    
    if len(note_name) >= 3 and note_name[1] == '#':
        base = sharp_map.get(note_name[:2], note_name[:2])
        octave = int(note_name[2:])
    elif len(note_name) >= 3 and note_name[1] == 'b':
        base = note_name[:2]
        octave = int(note_name[2:])
    else:
        base = note_name[0]
        octave = int(note_name[1:])
    
    semitone = notes[base]
    midi = (octave + 1) * 12 + semitone
    return 440.0 * (2 ** ((midi - 69) / 12.0))


def soft_piano_tone(freq, duration, volume=0.3):
    """Generate a warm, soft piano-like tone with harmonics."""
    t = np.linspace(0, duration, int(SAMPLE_RATE * duration), endpoint=False)
    
    # Fundamental + harmonics with decreasing amplitude (piano-like)
    signal = np.zeros_like(t)
    harmonics = [1.0, 0.5, 0.25, 0.12, 0.06, 0.03]
    for i, amp in enumerate(harmonics):
        h = i + 1
        # Slight detuning for warmth
        detune = 1.0 + np.random.uniform(-0.001, 0.001)
        signal += amp * np.sin(2 * np.pi * freq * h * detune * t)
    
    # ADSR envelope - soft attack, long sustain, gentle release
    attack = min(0.08, duration * 0.1)
    decay = min(0.15, duration * 0.15)
    release = min(0.3, duration * 0.3)
    sustain_level = 0.6
    
    envelope = np.ones_like(t)
    attack_samples = int(attack * SAMPLE_RATE)
    decay_samples = int(decay * SAMPLE_RATE)
    release_samples = int(release * SAMPLE_RATE)
    
    if attack_samples > 0:
        envelope[:attack_samples] = np.linspace(0, 1, attack_samples)
    if decay_samples > 0:
        start = attack_samples
        end = start + decay_samples
        if end <= len(envelope):
            envelope[start:end] = np.linspace(1, sustain_level, decay_samples)
    if release_samples > 0:
        envelope[-release_samples:] = np.linspace(sustain_level, 0, release_samples)
    
    signal *= envelope * volume
    return signal


def warm_bass_tone(freq, duration, volume=0.35):
    """Generate a warm upright bass tone."""
    t = np.linspace(0, duration, int(SAMPLE_RATE * duration), endpoint=False)
    
    # Fundamental + very mild harmonics (bass is mostly fundamental)
    signal = np.sin(2 * np.pi * freq * t) * 0.7
    signal += np.sin(2 * np.pi * freq * 2 * t) * 0.2
    signal += np.sin(2 * np.pi * freq * 3 * t) * 0.08
    
    # Quick attack, smooth sustain
    attack = min(0.02, duration * 0.05)
    release = min(0.1, duration * 0.2)
    
    envelope = np.ones_like(t)
    attack_samples = int(attack * SAMPLE_RATE)
    release_samples = int(release * SAMPLE_RATE)
    
    if attack_samples > 0:
        envelope[:attack_samples] = np.linspace(0, 1, attack_samples)
    if release_samples > 0:
        envelope[-release_samples:] = np.linspace(1, 0, release_samples)
    
    signal *= envelope * volume
    return signal


def brush_hit(duration=0.15, volume=0.08):
    """Generate a soft brush/cymbal hit (filtered noise)."""
    t = np.linspace(0, duration, int(SAMPLE_RATE * duration), endpoint=False)
    noise = np.random.randn(len(t))
    
    # Bandpass-like filter: attenuate low frequencies
    # Simple approach: high-pass via differentiation + smoothing
    filtered = np.diff(noise, prepend=0) * 0.5 + noise * 0.3
    
    # Quick decay envelope
    envelope = np.exp(-t * 15)
    
    return filtered * envelope * volume


def pad_tone(freq, duration, volume=0.08):
    """Generate an ambient pad/string sound."""
    t = np.linspace(0, duration, int(SAMPLE_RATE * duration), endpoint=False)
    
    # Multiple slightly detuned sine waves for chorus effect
    signal = np.zeros_like(t)
    for detune in [-0.02, -0.01, 0, 0.01, 0.02]:
        f = freq * (1 + detune * 0.01)
        signal += np.sin(2 * np.pi * f * t)
    signal /= 5
    
    # Slow attack, long sustain
    attack = min(0.5, duration * 0.2)
    release = min(0.5, duration * 0.2)
    
    envelope = np.ones_like(t)
    attack_samples = int(attack * SAMPLE_RATE)
    release_samples = int(release * SAMPLE_RATE)
    
    if attack_samples > 0:
        envelope[:attack_samples] = np.linspace(0, 1, attack_samples)
    if release_samples > 0:
        envelope[-release_samples:] = np.linspace(1, 0, release_samples)
    
    signal *= envelope * volume
    return signal


def vibes_tone(freq, duration, volume=0.2):
    """Generate a vibraphone-like tone (sine + tremolo)."""
    t = np.linspace(0, duration, int(SAMPLE_RATE * duration), endpoint=False)
    
    signal = np.sin(2 * np.pi * freq * t)
    signal += 0.3 * np.sin(2 * np.pi * freq * 2 * t)
    signal += 0.1 * np.sin(2 * np.pi * freq * 4 * t)
    
    # Tremolo
    tremolo = 1.0 + 0.15 * np.sin(2 * np.pi * 5.5 * t)
    signal *= tremolo
    
    # Bell-like envelope
    envelope = np.exp(-t * 2.0)
    
    signal *= envelope * volume
    return signal


def mix_to_buffer(samples_list, total_length):
    """Mix multiple (offset, samples) into a single buffer."""
    buf = np.zeros(total_length)
    for offset, samples in samples_list:
        end = offset + len(samples)
        if end > total_length:
            samples = samples[:total_length - offset]
            end = total_length
        if offset >= 0 and offset < total_length:
            buf[offset:end] += samples
    return buf


def normalize_and_limit(signal, target_peak=0.85):
    """Normalize and soft-limit audio."""
    peak = np.max(np.abs(signal))
    if peak > 0:
        signal = signal * (target_peak / peak)
    # Soft clip
    signal = np.tanh(signal * 1.2) * 0.9
    return signal


def write_wav(filename, signal, sample_rate=44100):
    """Write a mono WAV file."""
    signal = normalize_and_limit(signal)
    # Convert to 16-bit PCM
    pcm = (signal * 32767).astype(np.int16)
    
    with open(filename, 'wb') as f:
        # WAV header
        num_samples = len(pcm)
        data_size = num_samples * 2
        f.write(b'RIFF')
        f.write(struct.pack('<I', 36 + data_size))
        f.write(b'WAVE')
        f.write(b'fmt ')
        f.write(struct.pack('<I', 16))  # chunk size
        f.write(struct.pack('<H', 1))   # PCM format
        f.write(struct.pack('<H', 1))   # mono
        f.write(struct.pack('<I', sample_rate))
        f.write(struct.pack('<I', sample_rate * 2))  # byte rate
        f.write(struct.pack('<H', 2))   # block align
        f.write(struct.pack('<H', 16))  # bits per sample
        f.write(b'data')
        f.write(struct.pack('<I', data_size))
        f.write(pcm.tobytes())


def wav_to_mp3_simple(wav_path, mp3_path):
    """Convert WAV to MP3 using ffmpeg or lame, fallback to keeping WAV."""
    import subprocess
    try:
        subprocess.run(['ffmpeg', '-y', '-i', wav_path, '-b:a', '192k', '-ar', '44100', mp3_path],
                      capture_output=True, check=True)
        os.remove(wav_path)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        pass
    try:
        subprocess.run(['lame', '--preset', 'standard', wav_path, mp3_path],
                      capture_output=True, check=True)
        os.remove(wav_path)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        pass
    # Fallback: rename wav as mp3 (audioplayers handles it)
    os.rename(wav_path, mp3_path)
    return False


# ═══════════════════════════════════════════════════════════
# TRACK 1: LOBBY AMBIENT - Smooth Jazz Lounge
# ═══════════════════════════════════════════════════════════
def generate_lobby_music(output_path, duration_sec=45):
    """Generate smooth jazz lounge music for the lobby."""
    print("🎹 Generating Lobby Ambient Music (Smooth Jazz Lounge)...")
    
    total_samples = int(SAMPLE_RATE * duration_sec)
    mix = []
    
    # Jazz chord progression: Dm7 → G7 → Cmaj7 → Am7 (ii-V-I-vi in C)
    # Extended with: Fmaj7 → Bb7 → Em7 → A7
    chord_progression = [
        # (root notes for chord, bass note, duration_beats)
        (['D3', 'F3', 'A3', 'C4'], 'D2', 4),      # Dm7
        (['G3', 'B3', 'D4', 'F4'], 'G2', 4),       # G7
        (['C3', 'E3', 'G3', 'B3'], 'C2', 4),       # Cmaj7
        (['A3', 'C4', 'E4', 'G4'], 'A2', 4),       # Am7
        (['F3', 'A3', 'C4', 'E4'], 'F2', 4),       # Fmaj7
        (['Bb3', 'D4', 'F4', 'Ab4'], 'Bb2', 4),    # Bb7 (borrowed)
        (['E3', 'G3', 'B3', 'D4'], 'E2', 4),       # Em7
        (['A3', 'Db4', 'E4', 'G4'], 'A2', 4),      # A7 (dominant)
    ]
    
    beat_duration = 0.6  # seconds per beat (~100 BPM)
    current_time = 0.0
    
    # Repeat progression to fill duration
    num_repeats = int(duration_sec / (sum(c[2] for c in chord_progression) * beat_duration)) + 1
    
    for rep in range(num_repeats):
        for chord_notes, bass_note, beats in chord_progression:
            chord_dur = beats * beat_duration
            offset = int(current_time * SAMPLE_RATE)
            
            if current_time >= duration_sec:
                break
            
            # Piano chord - arpeggiated slightly
            for i, note in enumerate(chord_notes):
                delay = i * 0.03  # slight arpeggio
                note_offset = offset + int(delay * SAMPLE_RATE)
                tone = soft_piano_tone(note_freq(note), chord_dur - delay, volume=0.15)
                mix.append((note_offset, tone))
            
            # Walking bass line
            bass_freq = note_freq(bass_note)
            for b in range(beats):
                bass_offset = offset + int(b * beat_duration * SAMPLE_RATE)
                # Walk through chord tones
                walk_freqs = [bass_freq, bass_freq * 1.25, bass_freq * 1.5, bass_freq * 1.125]
                bf = walk_freqs[b % len(walk_freqs)]
                bass = warm_bass_tone(bf, beat_duration * 0.85, volume=0.25)
                mix.append((bass_offset, bass))
            
            # Brush pattern (jazz ride cymbal simulation)
            for b in range(beats * 2):
                brush_offset = offset + int(b * beat_duration * 0.5 * SAMPLE_RATE)
                # Swing feel: slightly delay off-beats
                if b % 2 == 1:
                    brush_offset += int(0.05 * SAMPLE_RATE)
                hit = brush_hit(0.12, volume=0.04 + np.random.uniform(0, 0.02))
                mix.append((brush_offset, hit))
            
            # Ambient pad underneath
            pad = pad_tone(note_freq(chord_notes[0]) * 2, chord_dur, volume=0.04)
            mix.append((offset, pad))
            
            current_time += chord_dur
    
    signal = mix_to_buffer(mix, total_samples)
    
    # Add subtle reverb (simple delay-based)
    reverb_delay = int(0.15 * SAMPLE_RATE)
    reverb = np.zeros(total_samples)
    reverb[reverb_delay:] = signal[:-reverb_delay] * 0.2
    reverb_delay2 = int(0.3 * SAMPLE_RATE)
    if reverb_delay2 < total_samples:
        reverb[reverb_delay2:] += signal[:-reverb_delay2] * 0.1
    signal += reverb
    
    # Fade in/out
    fade_in = int(2.0 * SAMPLE_RATE)
    fade_out = int(3.0 * SAMPLE_RATE)
    signal[:fade_in] *= np.linspace(0, 1, fade_in)
    signal[-fade_out:] *= np.linspace(1, 0, fade_out)
    
    wav_path = output_path.replace('.mp3', '.wav')
    write_wav(wav_path, signal)
    wav_to_mp3_simple(wav_path, output_path)
    print(f"  ✅ Saved: {output_path}")


# ═══════════════════════════════════════════════════════════
# TRACK 2: BLACKJACK MUSIC - Elegant Casino Table
# ═══════════════════════════════════════════════════════════
def generate_blackjack_music(output_path, duration_sec=45):
    """Generate elegant, sophisticated casino table music for blackjack."""
    print("🃏 Generating Blackjack Table Music (Elegant Casino)...")
    
    total_samples = int(SAMPLE_RATE * duration_sec)
    mix = []
    
    # More sophisticated jazz progression: Cmaj9 → Dm9 → Em7 → Fmaj7 → G13 → Am9
    chord_progression = [
        (['C3', 'E3', 'G3', 'B3', 'D4'], 'C2', 4),      # Cmaj9
        (['D3', 'F3', 'A3', 'C4', 'E4'], 'D2', 4),       # Dm9
        (['E3', 'G3', 'B3', 'D4'], 'E2', 2),              # Em7
        (['F3', 'A3', 'C4', 'E4'], 'F2', 2),              # Fmaj7
        (['G3', 'B3', 'D4', 'F4', 'E4'], 'G2', 4),       # G13
        (['A3', 'C4', 'E4', 'G4', 'B4'], 'A2', 4),       # Am9
        (['D3', 'Gb3', 'A3', 'C4'], 'D2', 4),             # D7
        (['G3', 'B3', 'D4', 'F4'], 'G2', 4),              # G7
    ]
    
    beat_duration = 0.55  # ~109 BPM - slightly uptempo elegance
    current_time = 0.0
    
    num_repeats = int(duration_sec / (sum(c[2] for c in chord_progression) * beat_duration)) + 1
    
    for rep in range(num_repeats):
        for chord_notes, bass_note, beats in chord_progression:
            chord_dur = beats * beat_duration
            offset = int(current_time * SAMPLE_RATE)
            
            if current_time >= duration_sec:
                break
            
            # Vibraphone chords (elegant casino feel)
            for i, note in enumerate(chord_notes[:3]):
                delay = i * 0.04
                note_offset = offset + int(delay * SAMPLE_RATE)
                tone = vibes_tone(note_freq(note), chord_dur * 0.7, volume=0.12)
                mix.append((note_offset, tone))
            
            # Piano fills on upper extensions
            if len(chord_notes) > 3:
                for i, note in enumerate(chord_notes[3:]):
                    delay = 0.2 + i * 0.1
                    note_offset = offset + int(delay * SAMPLE_RATE)
                    tone = soft_piano_tone(note_freq(note), chord_dur * 0.5, volume=0.1)
                    mix.append((note_offset, tone))
            
            # Walking bass
            bass_freq = note_freq(bass_note)
            for b in range(beats):
                bass_offset = offset + int(b * beat_duration * SAMPLE_RATE)
                # Chromatic walk patterns
                walk_intervals = [1.0, 1.189, 1.335, 1.498]  # root, M3, P4, P5 approximation
                bf = bass_freq * walk_intervals[b % len(walk_intervals)]
                bass = warm_bass_tone(bf, beat_duration * 0.8, volume=0.22)
                mix.append((bass_offset, bass))
            
            # Light brush pattern with ghost notes
            for b in range(beats * 3):
                brush_offset = offset + int(b * beat_duration / 3 * SAMPLE_RATE)
                vol = 0.025 if b % 3 != 0 else 0.045  # ghost notes quieter
                hit = brush_hit(0.1, volume=vol)
                mix.append((brush_offset, hit))
            
            # Subtle string pad
            pad = pad_tone(note_freq(chord_notes[0]) * 2, chord_dur, volume=0.03)
            mix.append((offset, pad))
            
            current_time += chord_dur
    
    signal = mix_to_buffer(mix, total_samples)
    
    # Reverb
    reverb_delay = int(0.12 * SAMPLE_RATE)
    reverb = np.zeros(total_samples)
    reverb[reverb_delay:] = signal[:-reverb_delay] * 0.18
    signal += reverb
    
    # Fade in/out
    fade_in = int(1.5 * SAMPLE_RATE)
    fade_out = int(3.0 * SAMPLE_RATE)
    signal[:fade_in] *= np.linspace(0, 1, fade_in)
    signal[-fade_out:] *= np.linspace(1, 0, fade_out)
    
    wav_path = output_path.replace('.mp3', '.wav')
    write_wav(wav_path, signal)
    wav_to_mp3_simple(wav_path, output_path)
    print(f"  ✅ Saved: {output_path}")


# ═══════════════════════════════════════════════════════════
# TRACK 3: POKER MUSIC - Tension & Cool Atmosphere
# ═══════════════════════════════════════════════════════════
def generate_poker_music(output_path, duration_sec=45):
    """Generate cool, tension-building poker room music."""
    print("♠️  Generating Poker Room Music (Cool Tension)...")
    
    total_samples = int(SAMPLE_RATE * duration_sec)
    mix = []
    
    # Minor key, darker progression: Am7 → Dm7 → E7#9 → Am7 → Fm7 → Bbm7 → E7b9 → Am7
    chord_progression = [
        (['A3', 'C4', 'E4', 'G4'], 'A2', 4),             # Am7
        (['D3', 'F3', 'A3', 'C4'], 'D2', 4),              # Dm7
        (['E3', 'Ab3', 'B3', 'D4', 'G4'], 'E2', 4),       # E7#9 (Hendrix chord)
        (['A3', 'C4', 'E4', 'G4'], 'A2', 4),              # Am7
        (['F3', 'Ab3', 'C4', 'Eb4'], 'F2', 4),            # Fm7 (borrowed)
        (['Bb3', 'Db4', 'F4', 'Ab4'], 'Bb2', 4),          # Bbm7 (tension)
        (['E3', 'Ab3', 'B3', 'D4'], 'E2', 4),             # E7b9
        (['A3', 'C4', 'E4', 'G4', 'B4'], 'A2', 4),        # Am9 (resolve)
    ]
    
    beat_duration = 0.65  # ~92 BPM - slower, more deliberate/tense
    current_time = 0.0
    
    num_repeats = int(duration_sec / (sum(c[2] for c in chord_progression) * beat_duration)) + 1
    
    for rep in range(num_repeats):
        for chord_notes, bass_note, beats in chord_progression:
            chord_dur = beats * beat_duration
            offset = int(current_time * SAMPLE_RATE)
            
            if current_time >= duration_sec:
                break
            
            # Piano - sparse, moody voicings
            # Only play some notes for tension
            selected = chord_notes[:3] if np.random.random() > 0.3 else chord_notes
            for i, note in enumerate(selected):
                delay = i * 0.05
                note_offset = offset + int(delay * SAMPLE_RATE)
                tone = soft_piano_tone(note_freq(note), chord_dur * 0.8, volume=0.13)
                mix.append((note_offset, tone))
            
            # Deep, slow walking bass
            bass_freq = note_freq(bass_note)
            for b in range(beats):
                bass_offset = offset + int(b * beat_duration * SAMPLE_RATE)
                # Darker bass walks - minor intervals
                walk_intervals = [1.0, 1.122, 1.335, 1.498]  # root, m3, P4, P5
                bf = bass_freq * walk_intervals[b % len(walk_intervals)]
                bass = warm_bass_tone(bf, beat_duration * 0.9, volume=0.28)
                mix.append((bass_offset, bass))
            
            # Sparse brush/ride - less frequent for tension
            for b in range(beats):
                brush_offset = offset + int(b * beat_duration * SAMPLE_RATE)
                # Only hit on beats 1 and 3
                if b % 2 == 0:
                    hit = brush_hit(0.15, volume=0.035)
                    mix.append((brush_offset, hit))
                # Ghost note between
                ghost_offset = brush_offset + int(beat_duration * 0.33 * SAMPLE_RATE)
                ghost = brush_hit(0.08, volume=0.015)
                mix.append((ghost_offset, ghost))
            
            # Deeper ambient pad for mood
            pad = pad_tone(note_freq(chord_notes[0]), chord_dur, volume=0.05)
            mix.append((offset, pad))
            
            # Occasional vibes accent (random)
            if np.random.random() > 0.6:
                accent_note = chord_notes[np.random.randint(0, len(chord_notes))]
                accent_delay = np.random.uniform(0.1, chord_dur * 0.5)
                accent_offset = offset + int(accent_delay * SAMPLE_RATE)
                accent = vibes_tone(note_freq(accent_note), 1.5, volume=0.08)
                mix.append((accent_offset, accent))
            
            current_time += chord_dur
    
    signal = mix_to_buffer(mix, total_samples)
    
    # More reverb for atmosphere
    reverb_delay = int(0.2 * SAMPLE_RATE)
    reverb = np.zeros(total_samples)
    reverb[reverb_delay:] = signal[:-reverb_delay] * 0.25
    reverb_delay2 = int(0.4 * SAMPLE_RATE)
    if reverb_delay2 < total_samples:
        reverb[reverb_delay2:] += signal[:-reverb_delay2] * 0.12
    signal += reverb
    
    # Fade in/out
    fade_in = int(2.5 * SAMPLE_RATE)
    fade_out = int(3.5 * SAMPLE_RATE)
    signal[:fade_in] *= np.linspace(0, 1, fade_in)
    signal[-fade_out:] *= np.linspace(1, 0, fade_out)
    
    wav_path = output_path.replace('.mp3', '.wav')
    write_wav(wav_path, signal)
    wav_to_mp3_simple(wav_path, output_path)
    print(f"  ✅ Saved: {output_path}")


def main():
    output_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'assets', 'sounds')
    os.makedirs(output_dir, exist_ok=True)
    
    print("═" * 60)
    print("🎰 CASINO MUSIC SYNTHESIZER")
    print("═" * 60)
    print(f"Output: {output_dir}")
    print()
    
    # Generate all three tracks (45 seconds each for good looping)
    generate_lobby_music(os.path.join(output_dir, 'lobby_ambient.mp3'), duration_sec=45)
    generate_blackjack_music(os.path.join(output_dir, 'blackjack_music.mp3'), duration_sec=45)
    generate_poker_music(os.path.join(output_dir, 'poker_music.mp3'), duration_sec=45)
    
    print()
    print("═" * 60)
    print("🎵 All casino music tracks generated successfully!")
    print("═" * 60)
    print()
    print("Tracks created:")
    print("  🎹 lobby_ambient.mp3   - Smooth jazz lounge (lobby)")
    print("  🃏 blackjack_music.mp3 - Elegant casino table (blackjack)")
    print("  ♠️  poker_music.mp3     - Cool tension atmosphere (poker)")


if __name__ == '__main__':
    main()
