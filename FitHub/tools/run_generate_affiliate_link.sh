#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$ROOT_DIR")"
VENV_DIR="$PROJECT_DIR/tools/venv"
PYTHON_BIN="$VENV_DIR/bin/python"

if [[ ! -x "$PYTHON_BIN" ]]; then
  echo "Virtual environment not found at $VENV_DIR" >&2
  echo "Create it with: python3 -m venv tools/venv" >&2
  exit 1
fi

cd "$PROJECT_DIR"
"$PYTHON_BIN" -m tools.affiliate_link_generator.main "$@"



