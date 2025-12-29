#!/usr/bin/env bash
set -euo pipefail

allow() {
    printf '%s' '{"continue": true, "permission": "allow"}'
}

deny() {
    printf '%s' '{"continue": false, "permission": "deny", "agentMessage": ' "'$*'}"
}

cursor_hook() {
    printf '[cursor hook] %s\n' "$@"
}

run_with_retry() {
  local description="$1"
  shift
  local attempt=1
  local max_attempts=2
  while (( attempt <= max_attempts )); do
    cursor_hook "(${description}) attempt ${attempt}/${max_attempts}"
    if "$@"; then
      return 0
    fi
    (( attempt++ ))
  done
  return 1
}

precommit() {
  local fix_cmd=(pre-commit run --all-files --config .pre-commit-config-fix.yaml)
  local check_cmd=(pre-commit run --all-files --config .pre-commit-config.yaml)

  if ! run_with_retry "pre-commit fix" "${fix_cmd[@]}"; then
    cursor_hook "pre-commit (fix config) failed after two attempts."
    cursor_hook "Please review the pre-commit output, address the issues, and retry git commit."
    exit 1
  fi

  if ! "${check_cmd[@]}"; then
    echo "[cursor hook] pre-commit (default config) failed."
    echo "[cursor hook] Please review the pre-commit output, address the issues, and retry git commit."
    exit 1
  fi
}

cmd=$(jq -r '.command' <<< "$PAYLOAD")

func=
[[ "$cmd" =~ ^git\ commit\ .* ]] && func="precommit"

case "$func" in
  precommit)
    precommit
    allow
    ;;
  *)
    allow
    ;;
esac