#!/bin/bash
set -e
cd "$(dirname "$0")/.."

case "$(uname -s)" in
    Darwin*)              OS=mac ;;
    Linux*)               OS=linux ;;
    MINGW*|MSYS*|CYGWIN*) OS=windows ;;
    *)                    OS=unknown ;;
esac

say() { printf '\n== %s ==\n' "$1"; }

say "1/4  Python 3.11  [$OS]"

PY=""

if [ "$OS" = mac ] || [ "$OS" = linux ]; then
    if ! command -v pyenv >/dev/null 2>&1; then
        for c in "$HOME/.pyenv/bin/pyenv" /opt/homebrew/bin/pyenv /usr/local/bin/pyenv; do
            if [ -x "$c" ]; then
                export PATH="$(dirname "$c"):$PATH"
                eval "$($c init -)"
                break
            fi
        done
    fi
    if command -v pyenv >/dev/null 2>&1; then
        TARGET=$(pyenv versions --bare | grep -E '^3\.11\.' | tail -n1 || true)
        if [ -z "$TARGET" ]; then
            TARGET="3.11.9"
            pyenv install --skip-existing "$TARGET"
        fi
        pyenv local "$TARGET"
        PY="$(pyenv which python)"
    fi
fi

if [ -z "$PY" ]; then
    for cmd in python3.11 python3 python; do
        if command -v "$cmd" >/dev/null 2>&1 && \
           "$cmd" -c "import sys; sys.exit(0 if sys.version_info[:2]==(3,11) else 1)" 2>/dev/null; then
            PY="$cmd"
            break
        fi
    done
fi

if [ -z "$PY" ] && command -v py >/dev/null 2>&1; then
    if py -3.11 -c "import sys; sys.exit(0 if sys.version_info[:2]==(3,11) else 1)" 2>/dev/null; then
        PY="py -3.11"
    fi
fi

if [ -z "$PY" ]; then
    echo ""
    echo "ERROR: Python 3.11 not found."
    case "$OS" in
        mac)     echo "Install it with:  brew install pyenv && pyenv install 3.11.9" ;;
        linux)   echo "Install Python 3.11 via your package manager (apt/dnf/pacman)." ;;
        windows) echo "Install Python 3.11 from https://www.python.org/downloads/release/python-3119/"
                 echo "Tick 'Add python.exe to PATH' during installation." ;;
        *)       echo "Install Python 3.11 from https://www.python.org/downloads/release/python-3119/" ;;
    esac
    read -p "Press ENTER to close..." _; exit 1
fi

# Windows: MediaPipe's C++ resource loader breaks on non-ASCII paths.
# Create a venv at an ASCII-only path so its site-packages avoids Cyrillic etc.
if [ "$OS" = windows ]; then
    VENV="/c/Users/Public/sl_env"
    if [ ! -x "$VENV/Scripts/python.exe" ]; then
        echo "Creating venv at C:\\Users\\Public\\sl_env (ASCII-only path) ..."
        $PY -m venv "$VENV"
    fi
    PY="$VENV/Scripts/python.exe"
    PIP_FLAGS=""
else
    PIP_FLAGS="--user"
fi

echo "$PY" > .python_cmd
echo "Python: $PY  ($($PY --version))"

say "2/4  Dependencies"
$PY -m pip install --upgrade pip --quiet
$PY -m pip install --quiet $PIP_FLAGS \
    "numpy<2" "protobuf<5" \
    "mediapipe==0.10.14" \
    "opencv-python" "torch" \
    "imageio-ffmpeg"
$PY -c "import mediapipe, cv2, torch, numpy, imageio_ffmpeg; print('deps OK')"

say "3/4  Dataset"
if [ -d "data/numbers/0" ] && [ "$(ls -1 data/numbers/0 2>/dev/null | wc -l)" -gt 10 ]; then
    echo "Already in data/numbers."
else
    TMP_CLONE="$(mktemp -d)"
    git clone --depth 1 \
        https://github.com/ardamavi/Sign-Language-Digits-Dataset \
        "$TMP_CLONE/repo"
    mkdir -p data/numbers
    for d in 0 1 2 3 4 5 6 7 8 9; do
        mkdir -p "data/numbers/$d"
        cp -n "$TMP_CLONE/repo/Dataset/$d/"*.* "data/numbers/$d/" 2>/dev/null || true
    done
    rm -rf "$TMP_CLONE"
    echo "Images copied to data/numbers/{0..9}"
fi

say "4/4  Features + model"
if [ ! -f "data/hand_poses_public/X.npy" ]; then
    $PY <<'PYEOF'
import json
nb = json.load(open('scripts/ingest.ipynb'))
code = '\n'.join(''.join(c['source']) for c in nb['cells'] if c['cell_type']=='code')
exec(compile(code, 'scripts/ingest.ipynb', 'exec'))
PYEOF
else
    echo "Features already extracted."
fi

if [ ! -f "models/digits_mlp.pth" ]; then
    $PY <<'PYEOF'
import json
nb = json.load(open('scripts/train.ipynb'))
code = '\n'.join(''.join(c['source']) for c in nb['cells'] if c['cell_type']=='code')
exec(compile(code, 'scripts/train.ipynb', 'exec'))
PYEOF
else
    echo "Model already trained."
fi

find audio/uzbek -name '*.mp3' -size 0 -delete 2>/dev/null || true

echo ""
echo "================================================================"
echo "  Setup complete. Run commands/run.command to start."
echo "================================================================"
read -p "Press ENTER to close..." _
