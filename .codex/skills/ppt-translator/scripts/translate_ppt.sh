#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_BIN="$SCRIPT_DIR/.venv/bin/python"

if [ ! -x "$PYTHON_BIN" ]; then
  echo "Missing virtual environment. Run ./bootstrap.sh first." >&2
  exit 1
fi

if [ -f "$SCRIPT_DIR/.env" ]; then
  set -a
  # shellcheck disable=SC1091
  . "$SCRIPT_DIR/.env"
  set +a
fi

cd "$SCRIPT_DIR"
exec "$PYTHON_BIN" "$SCRIPT_DIR/main.py" "$@"
