# Sign Language 0–9 → Uzbek Voice

Real-time webcam recognition of Turkish Sign Language (TİD) digits 0–9, spoken aloud in Uzbek.

## Pipeline

1. **MediaPipe Hands** extracts 21 3D landmarks per frame.
2. Landmarks are normalized (centered on wrist, scaled by palm size) into a 63-D feature.
3. A small PyTorch MLP (63 → 128 → 128 → 10) classifies the digit.
4. When a digit stays stable for `STABLE_FRAMES` frames, the matching Uzbek mp3 plays via `afplay`.

## Setup

```bash
# First time — installs pyenv Python 3.11, deps, dataset, features, model
./commands/setup.command
```

Requirements: macOS, `pyenv` (`brew install pyenv`), a working webcam.

## Run

```bash
./commands/run.command
```

Press `q` to quit. Hold a digit steady until the ring fills — it speaks, then waits for you to drop your hand before it can fire again.

## Audio

Drop your own `0.mp3`…`9.mp3` files into `audio/uzbek/`. Missing files fall back silently.

## Layout

```
scripts/
  ingest.ipynb      # extract features from data/numbers/
  train.ipynb       # train the MLP
  count.ipynb       # live webcam inference + UI
commands/
  setup.command     # one-shot environment + data + training
  run.command       # launch count.ipynb
models/
  digits_mlp.pth    # trained weights
audio/uzbek/        # your 0-9 mp3s
```

## Dataset

[ardamavi/Sign-Language-Digits-Dataset](https://github.com/ardamavi/Sign-Language-Digits-Dataset) — Turkish Sign Language digits (2062 images). Cloned automatically by setup.
