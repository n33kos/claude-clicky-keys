#!/usr/bin/env python3
"""Generate animalese-style babble as a WAV file.

Synthesizes Animal Crossing-style speech from random letter sequences using
a base sound library (animalese.wav). Each letter maps to a pre-recorded
sound segment that is pitch-shifted and concatenated.

Based on https://github.com/Acedio/animalese.js

Usage: animalese.py [output_path] [--pitch PITCH] [--length LENGTH]

Environment variables (override CLI args):
    CLICKY_ANIMALESE_PITCH  - Pitch multiplier (default: 1.0)
    CLICKY_ANIMALESE_LENGTH - Number of syllables to generate (default: 40)
"""

import os
import sys
import wave
import struct
import random
import math

SAMPLE_RATE = 44100
LIBRARY_SAMPLES_PER_LETTER = 6615    # 0.15s at 44100 Hz
OUTPUT_SAMPLES_PER_LETTER = 3307     # 0.075s at 44100 Hz
SILENCE_VALUE = 127                  # 8-bit unsigned PCM midpoint

def load_library(wav_path):
    """Load the animalese base sound library as a list of unsigned 8-bit samples."""
    with wave.open(wav_path, 'rb') as w:
        raw = w.readframes(w.getnframes())
    return list(raw)

def synthesize(library, text, pitch=1.0):
    """Synthesize animalese audio from text.

    Args:
        library: List of unsigned 8-bit samples from the base WAV.
        text: String to synthesize (only A-Z mapped, others produce silence).
        pitch: Pitch multiplier (0.2-2.0). Higher = faster/higher pitch.

    Returns:
        List of unsigned 8-bit sample values.
    """
    output = []
    for ch in text.upper():
        if 'A' <= ch <= 'Z':
            letter_index = ord(ch) - ord('A')
            lib_start = letter_index * LIBRARY_SAMPLES_PER_LETTER
            for i in range(OUTPUT_SAMPLES_PER_LETTER):
                src_index = lib_start + int(i * pitch)
                if src_index < len(library):
                    # Add small random offset for natural variation
                    sample = library[src_index]
                else:
                    sample = SILENCE_VALUE
                output.append(sample)
        else:
            # Non-alphabetic characters produce a short silence
            output.extend([SILENCE_VALUE] * (OUTPUT_SAMPLES_PER_LETTER // 2))
    return output

def generate_random_text(length=40):
    """Generate random babble text with word-like structure."""
    vowels = 'aeiou'
    consonants = 'bcdfghjklmnpqrstvwxyz'
    text = []
    word_len = 0
    target_word_len = random.randint(2, 6)
    # Some words start with vowels (~30% of the time)
    start_with_vowel = random.random() < 0.3

    for _ in range(length):
        if word_len >= target_word_len:
            text.append(' ')
            word_len = 0
            target_word_len = random.randint(2, 6)
            start_with_vowel = random.random() < 0.3
        # Alternate consonant-vowel for natural-sounding babble
        use_vowel = (word_len % 2 == 0) == start_with_vowel
        if use_vowel:
            text.append(random.choice(vowels))
        else:
            text.append(random.choice(consonants))
        word_len += 1

    return ''.join(text)

def write_wav(path, samples, sample_rate=SAMPLE_RATE):
    """Write unsigned 8-bit mono WAV file."""
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(1)
        w.setframerate(sample_rate)
        w.writeframes(bytes(samples))

def main():
    # Determine paths
    script_dir = os.path.dirname(os.path.abspath(__file__))
    plugin_dir = os.environ.get('CLAUDE_PLUGIN_ROOT', os.path.dirname(script_dir))
    library_path = os.path.join(plugin_dir, 'sounds', 'animalese.wav')

    # Output path: first CLI arg or default
    output_path = sys.argv[1] if len(sys.argv) > 1 else '/tmp/claude-clicky-keys/animalese-generated.wav'

    # Ensure output directory exists
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    # Configuration from env vars (with validation)
    try:
        pitch = float(os.environ.get('CLICKY_ANIMALESE_PITCH', '1.0'))
    except ValueError:
        pitch = 1.0
    pitch = max(0.2, min(2.0, pitch))

    try:
        length = int(os.environ.get('CLICKY_ANIMALESE_LENGTH', '40'))
    except ValueError:
        length = 40
    length = max(10, min(200, length))

    # Load library
    if not os.path.exists(library_path):
        print(f"Error: Library file not found: {library_path}", file=sys.stderr)
        sys.exit(1)

    library = load_library(library_path)

    # Generate random babble text
    text = generate_random_text(length)

    # Synthesize
    samples = synthesize(library, text, pitch=pitch)

    # Write output
    write_wav(output_path, samples)
    print(output_path)

if __name__ == '__main__':
    main()
