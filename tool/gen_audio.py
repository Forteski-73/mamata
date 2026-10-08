"""Gera os efeitos sonoros e as musicas do Mamata (sintese procedural, sem dependencias).

Uso:  python tool/gen_audio.py
Saida: assets/audio/*.wav
"""
import math
import os
import random
import struct
import wave

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
random.seed(42)


# ---------------------------------------------------------------- osciladores
def osc(kind, phase):
    p = phase % 1.0
    if kind == "sine":
        return math.sin(2 * math.pi * p)
    if kind == "square":
        return 1.0 if p < 0.5 else -1.0
    if kind == "pulse":
        return 1.0 if p < 0.25 else -1.0
    if kind == "saw":
        return 2.0 * p - 1.0
    if kind == "tri":
        return 4.0 * abs(p - 0.5) - 1.0
    if kind == "noise":
        return random.uniform(-1, 1)
    raise ValueError(kind)


def tone(dur, f0, f1=None, kind="square", vol=0.5, attack=0.005, release=0.05,
         vib=0.0, vib_rate=6.0):
    f1 = f0 if f1 is None else f1
    n = int(dur * SR)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / SR
        k = i / max(1, n - 1)
        f = f0 * (f1 / f0) ** k if f0 > 0 and f1 > 0 else f0 + (f1 - f0) * k
        if vib:
            f *= 1 + vib * math.sin(2 * math.pi * vib_rate * t)
        phase += f / SR
        env = 1.0
        if t < attack:
            env = t / attack
        if dur - t < release:
            env *= max(0.0, (dur - t) / release)
        out.append(osc(kind, phase) * vol * env)
    return out


def silence(dur):
    return [0.0] * int(dur * SR)


def mix(*tracks):
    n = max(len(t) for t in tracks)
    out = [0.0] * n
    for tr in tracks:
        for i, v in enumerate(tr):
            out[i] += v
    return out


def concat(*tracks):
    out = []
    for t in tracks:
        out.extend(t)
    return out


def lowpass(samples, a=0.25):
    out, prev = [], 0.0
    for s in samples:
        prev = prev + a * (s - prev)
        out.append(prev)
    return out


def save(name, samples, gain=1.0):
    peak = max(1e-6, max(abs(s) for s in samples))
    norm = min(1.0, 0.89 / peak) * gain
    path = os.path.join(OUT, name)
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = bytearray()
        for s in samples:
            v = max(-1.0, min(1.0, s * norm))
            frames += struct.pack("<h", int(v * 32767))
        w.writeframes(bytes(frames))
    print("ok", name, f"{len(samples) / SR:.2f}s")


def note(n):
    """Converte 'C4', 'F#3', 'Bb5' em Hz."""
    names = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
    semi = names[n[0]]
    i = 1
    if n[i] == "#":
        semi += 1
        i += 1
    elif n[i] == "b":
        semi -= 1
        i += 1
    octave = int(n[i:])
    midi = 12 * (octave + 1) + semi
    return 440.0 * 2 ** ((midi - 69) / 12)


# ---------------------------------------------------------------- efeitos
def sfx():
    save("jump.wav", tone(0.16, 280, 720, "square", 0.35, release=0.06))
    save("double_jump.wav", tone(0.14, 520, 1150, "pulse", 0.3, release=0.06))
    save("coin.wav", concat(tone(0.06, note("B5"), kind="square", vol=0.3, release=0.01),
                            tone(0.16, note("E6"), kind="square", vol=0.3, release=0.12)))
    save("orange.wav", mix(tone(0.28, 400, 1200, "sine", 0.6, vib=0.08, vib_rate=18),
                           tone(0.28, 800, 2400, "tri", 0.15)))
    save("shield.wav", concat(tone(0.12, 900, 300, "tri", 0.5),
                              mix(tone(0.3, note("C5"), kind="square", vol=0.18),
                                  tone(0.3, note("E5"), kind="square", vol=0.18),
                                  tone(0.3, note("G5"), kind="square", vol=0.18))))
    save("hit.wav", mix(lowpass(tone(0.3, 0, kind="noise", vol=0.7, release=0.25), 0.35),
                        tone(0.4, 220, 50, "square", 0.45, release=0.2)))
    save("tax.wav", concat(lowpass(tone(0.05, 0, kind="noise", vol=0.8), 0.5),
                           mix(tone(0.35, note("A6"), kind="sine", vol=0.4, release=0.3),
                               tone(0.35, note("E7"), kind="sine", vol=0.25, release=0.3))))
    save("throw.wav", lowpass(tone(0.14, 0, kind="noise", vol=0.5, release=0.1), 0.15))
    save("powerup.wav", concat(*[tone(0.07, note(n), kind="square", vol=0.3, release=0.02)
                                  for n in ("C5", "E5", "G5", "C6", "E6", "G6")],
                               tone(0.25, note("C7"), kind="square", vol=0.25, release=0.2)))
    save("slide.wav", lowpass(tone(0.22, 0, kind="noise", vol=0.5, release=0.15), 0.08))
    save("click.wav", tone(0.05, 1200, 900, "square", 0.25, release=0.03))
    save("alarm.wav", concat(tone(0.18, 880, kind="saw", vol=0.25),
                             tone(0.18, 660, kind="saw", vol=0.25)))
    save("beep.wav", tone(0.14, note("A5"), kind="square", vol=0.3, release=0.05))
    save("go.wav", tone(0.4, note("A6"), kind="square", vol=0.3, release=0.25))
    sad = concat(*[tone(d, note(n), kind="saw", vol=0.35, vib=0.02 if d > 0.4 else 0.0,
                        vib_rate=5, release=0.08)
                   for n, d in (("G4", 0.32), ("F#4", 0.32), ("F4", 0.32), ("E4", 1.0))])
    save("caught.wav", lowpass(sad, 0.3))
    fan = concat(*[tone(0.11, note(n), kind="square", vol=0.3, release=0.03)
                   for n in ("C5", "E5", "G5", "C6", "G5", "C6")],
                 mix(tone(0.8, note("C6"), kind="square", vol=0.2, release=0.5),
                     tone(0.8, note("E6"), kind="square", vol=0.2, release=0.5),
                     tone(0.8, note("G6"), kind="pulse", vol=0.2, release=0.5)))
    save("level_complete.wav", fan)


# ---------------------------------------------------------------- musica
def drum(kind, dur):
    if kind == "kick":
        return tone(dur, 150, 40, "sine", 0.9, release=dur * 0.8)
    if kind == "snare":
        return lowpass(tone(dur, 0, kind="noise", vol=0.45, release=dur * 0.9), 0.6)
    if kind == "hat":
        return tone(min(dur, 0.04), 0, kind="noise", vol=0.18, release=0.03)
    return silence(dur)


def song(bpm, chords, melody, bass_pattern, drum_pattern, lead="square", bars_rep=1):
    beat = 60.0 / bpm
    step = beat / 4  # semicolcheia
    total_steps = 16 * len(chords) * bars_rep
    n = int(total_steps * step * SR)
    buf = [0.0] * (n + SR)

    def put(at_step, samples):
        start = int(at_step * step * SR)
        for i, v in enumerate(samples):
            if start + i < len(buf):
                buf[start + i] += v

    for rep in range(bars_rep):
        for b, chord in enumerate(chords):
            base = (rep * len(chords) + b) * 16
            root = chord[0]
            # baixo (estilo samba/forró: sincopado)
            for s, off in bass_pattern:
                f = note(root) * (2 ** (off / 12))
                put(base + s, tone(step * 1.6, f, kind="tri", vol=0.45, release=0.04))
            # acordes curtos (pulse)
            for s in (2, 6, 10, 14):
                for nn in chord[1:]:
                    put(base + s, tone(step * 0.9, note(nn), kind="pulse", vol=0.07, release=0.03))
            # bateria
            for s, kind in drum_pattern:
                put(base + s, drum(kind, step * 1.5))
    # melodia (lista de (step, nota, duracao_em_steps))
    mel_len = 16 * len(chords)
    for rep in range(bars_rep):
        for s, nn, d in melody:
            if nn:
                put(rep * mel_len + s, tone(step * d * 0.95, note(nn), kind=lead, vol=0.16,
                                            vib=0.006, vib_rate=5.5, release=0.03))
    return buf[:n]


def music():
    bass = [(0, 0), (3, 7), (6, 12), (8, 0), (11, 7), (14, 10)]
    drums = [(0, "kick"), (4, "snare"), (7, "kick"), (8, "kick"), (12, "snare"), (14, "snare")] + \
            [(i, "hat") for i in range(0, 16, 2)]
    chords = [("C2", "E4", "G4"), ("A1", "C4", "E4"), ("F1", "A4", "C5"), ("G1", "B4", "D5")] * 2
    # melodia marota em C maior (8 compassos)
    mel_bars = [
        [(0, "G5", 2), (2, "E5", 2), (4, "G5", 1), (5, "A5", 1), (6, "G5", 2), (10, "E5", 2), (12, "C5", 4)],
        [(0, "A5", 2), (2, "C6", 2), (4, "B5", 2), (6, "A5", 2), (8, "E5", 4), (12, "G5", 4)],
        [(0, "F5", 2), (2, "A5", 2), (4, "C6", 3), (8, "A5", 2), (10, "F5", 2), (12, "A5", 4)],
        [(0, "G5", 1), (1, "A5", 1), (2, "B5", 2), (4, "D6", 2), (6, "B5", 2), (8, "G5", 6)],
        [(0, "C6", 2), (2, "G5", 2), (4, "E5", 2), (6, "G5", 1), (7, "C6", 1), (8, "E6", 4), (12, "D6", 4)],
        [(0, "C6", 2), (2, "A5", 2), (4, "E5", 2), (6, "A5", 2), (8, "C6", 6)],
        [(0, "A5", 1), (1, "C6", 1), (2, "F6", 2), (4, "E6", 2), (6, "C6", 2), (8, "A5", 4), (12, "F5", 4)],
        [(0, "G5", 2), (2, "B5", 2), (4, "D6", 2), (6, "F6", 2), (8, "E6", 2), (10, "D6", 2), (12, "C6", 4)],
    ]
    melody = [(b * 16 + s, n, d) for b, bar in enumerate(mel_bars) for s, n, d in bar]

    game = song(150, chords, melody, bass, drums, lead="square", bars_rep=2)
    save("music_game.wav", game, gain=0.9)

    menu_melody = [(s, n, d * 1.0) for s, n, d in melody]
    menu = song(112, chords, menu_melody, [(0, 0), (6, 7), (8, 0), (14, 7)],
                [(0, "kick"), (8, "kick"), (4, "hat"), (12, "hat"), (10, "snare")], lead="tri")
    save("music_menu.wav", menu, gain=0.9)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    sfx()
    music()
