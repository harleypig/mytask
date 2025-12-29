#!/usr/bin/env bash
set -euo pipefail

cmd="$*"

run_with_retry() {
  local description="$1"
  shift
  local attempt=1
  local max_attempts=2
  while (( attempt <= max_attempts )); do
    echo "[cursor hook] (${description}) attempt ${attempt}/${max_attempts}"
    if "$@"; then
      return 0
    fi
    (( attempt++ ))
  done
  return 1
}

fix_cmd=(pre-commit run --all-files --config .pre-commit-config-fix.yaml)
check_cmd=(pre-commit run --all-files --config .pre-commit-config.yaml)

if ! run_with_retry "pre-commit fix" "${fix_cmd[@]}"; then
  cat <<'EOF' >&2
[cursor hook] pre-commit (fix config) failed after two attempts.
[cursor hook] Please review the pre-commit output, address the issues, and retry git commit.
EOF
  exit 1
fi

if ! "${check_cmd[@]}"; then
  cat <<'EOF' >&2
[cursor hook] pre-commit (default config) failed.
[cursor hook] Please review the pre-commit output, address the issues, and retry git commit.
EOF
  exit 1
fi

echo "[cursor hook] pre-commit checks passed; proceeding: git commit ${cmd}"

