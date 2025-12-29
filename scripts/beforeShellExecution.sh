#!/usr/bin/env bash
set -euo pipefail

allow() {
  jq -n '{"continue": true, "permission": "allow"}'
  exit 0
}

deny() {
  jq -n --arg msg "$*" '{
    "continue": false,
    "permission": "deny",
    "agentMessage": $msg
  }'
  exit 0
}

run_with_retry() {
  local description="$1"
  shift
  local attempt=1
  local max_attempts=2
  while (( attempt <= max_attempts )); do
    if "$@"; then
      return 0
    fi
    (( attempt++ ))
  done
  deny "(${description}) failed after ${max_attempts} attempts."
}

precommit() {
  local fix_cmd=(pre-commit run --all-files --config .pre-commit-config-fix.yaml)
  local check_cmd=(pre-commit run --all-files --config .pre-commit-config.yaml)

  if ! run_with_retry "pre-commit fix" "${fix_cmd[@]}"; then
    deny "pre-commit (fix config) failed after two attempts. Please review the pre-commit output, address the issues, and retry git commit."
  fi

  if ! "${check_cmd[@]}"; then
    deny "pre-commit (default config) failed. Please review the pre-commit output, address the issues, and retry git commit."
  fi

  allow
}

cmd=$(jq -r '.command' <<< "$PAYLOAD")

func=
[[ "$cmd" =~ ^git\ commit\ .* ]] && func="precommit"

case "$func" in
  precommit) precommit ;;
esac

allow