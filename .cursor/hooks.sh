#!/usr/bin/env bash
set -euo pipefail

PAYLOAD=$(cat)
export PAYLOAD
event=$(jq -r '.hook_event_name' <<< "$PAYLOAD")

case "$event" in
    "beforeShellExecution") scripts/beforeShellExecution.sh ;;
    *)
        echo "Unknown event: $event"
        exit 1
esac