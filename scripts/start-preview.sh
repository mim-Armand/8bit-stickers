#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
python3 scripts/build-preview.py
echo '8 bit art Studio: http://127.0.0.1:8787/prototype/'
exec python3 -m http.server 8787 --bind 127.0.0.1
