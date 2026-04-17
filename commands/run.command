#!/bin/bash
set -e
cd "$(dirname "$0")/.."

if [ -f .python_cmd ]; then
    PY="$(cat .python_cmd)"
else
    PY=python3
fi

if [ ! -f "models/digits_mlp.pth" ]; then
    echo "ERROR: model not found. Run commands/setup.command first."
    read -p "Press ENTER to close..." _
    exit 1
fi

"$PY" <<'PYEOF'
import json
nb = json.load(open('scripts/count.ipynb'))
code = '\n'.join(''.join(c['source']) for c in nb['cells'] if c['cell_type']=='code')
exec(compile(code, 'scripts/count.ipynb', 'exec'))
PYEOF
