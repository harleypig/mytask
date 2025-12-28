#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || (cd "$SCRIPT_DIR/.." && pwd))"

# Load local env (perl lib, PATH, etc.)
source "$PROJECT_ROOT/scripts/local-env.sh"

# Ensure project libs are first
export PERL5LIB="$PROJECT_ROOT/lib:$PROJECT_ROOT/t/lib:${PERL5LIB:-}"

MODE="format"
if [[ "${1:-}" == "--check" ]]; then
  MODE="check"
  shift
fi

if [[ "$MODE" == "check" ]]; then
  for f in "$@"; do
    perltidy --standard-output "$f" >/dev/null
  done
else
  for f in "$@"; do
    perltidy --nostandard-output --backup-and-modify-in-place --standard-error-output --backup-file-extension=/ "$f"
  done
fi
