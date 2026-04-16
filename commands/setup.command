#!/bin/bash
set -e
cd "$(dirname "$0")/.."

say() { printf '\n== %s ==\n' "$1"; }

say "1/4  Python 3.11 (via pyenv)"
if ! command -v pyenv >/dev/null 2>&1; then
    for c in "$HOME/.pyenv/bin/pyenv" /opt/homebrew/bin/pyenv /usr/local/bin/pyenv; do
        if [ -x "$c" ]; then
            export PATH="$(dirname "$c"):$PATH"
            eval "$($c init -)"
            break
        fi
    done
fi
if ! command -v pyenv >/dev/null 2>&1; then
    echo "ERROR: pyenv not found. Install it first:  brew install pyenv"
    read -p "Press ENTER to close..." _; exit 1
fi
TARGET=$(pyenv versions --bare | grep -E '^3\.11\.' | tail -n1 || true)
if [ -z "$TARGET" ]; then
    TARGET="3.11.9"
    pyenv install --skip-existing "$TARGET"
fi
pyenv local "$TARGET"
PY="$(pyenv which python)"
echo "$PY" > .python_cmd
echo "Python: $PY  ($("$PY" --version))"

say "2/4  Dependencies"
"$PY" -m pip install --upgrade pip --quiet
"$PY" -m pip install --quiet --user \
    "numpy<2" "protobuf<5" \
    "mediapipe==0.10.14" \
    "opencv-python" "torch"
"$PY" -c "import mediapipe, cv2, torch, numpy; print('deps OK')"

say "3/4  Dataset"
if [ -d "data/numbers/0" ] && [ "$(ls -1 data/numbers/0 2>/dev/null | wc -l)" -gt 10 ]; then
    echo "Already in data/numbers."
else
    TMP_CLONE="$(mktemp -d -t sldd.XXXXXX)"
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
    "$PY" <<'PYEOF'
import json
nb = json.load(open('scripts/ingest.ipynb'))
code = '\n'.join(''.join(c['source']) for c in nb['cells'] if c['cell_type']=='code')
exec(compile(code, 'scripts/ingest.ipynb', 'exec'))
PYEOF
else
    echo "Features already extracted."
fi

if [ ! -f "models/digits_mlp.pth" ] && [ -f "models/static_mlp_public.pth" ]; then
    cp models/static_mlp_public.pth models/digits_mlp.pth
fi
if [ ! -f "models/digits_mlp.pth" ]; then
    "$PY" <<'PYEOF'
import json
nb = json.load(open('scripts/train.ipynb'))
code = '\n'.join(''.join(c['source']) for c in nb['cells'] if c['cell_type']=='code')
exec(compile(code, 'scripts/train.ipynb', 'exec'))
PYEOF
else
    echo "Model already trained."
fi

say "Cleanup"
rm -f setup.command run.command install.command fix_mediapipe.command \
      cleanup.command count_to_100.command record_numbers.command \
      run_inference.command setup_digits.command train_from_user.command \
      setup.sh README.md .DS_Store requirements.txt
rm -f scripts/model.py scripts/ingest.py scripts/train.py \
      scripts/count.py scripts/speak_setup.py
rm -rf scripts/__pycache__

for f in models/*; do
    case "$(basename "$f")" in
        digits_mlp.pth) ;;
        *) rm -rf "$f" ;;
    esac
done

for f in data/*; do
    case "$(basename "$f")" in
        hand_poses_public|numbers) ;;
        *) rm -rf "$f" ;;
    esac
done

find audio/uzbek -name '*.mp3' -size 0 -delete 2>/dev/null || true

rm -rf external outputs Dataset .idea

echo ""
echo "================================================================"
echo "  Setup complete. Double-click commands/count.command to use."
echo "================================================================"
read -p "Press ENTER to close..." _
