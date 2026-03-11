#!/bin/bash
# Session sync hook: auto-extract current session to Logseq.
# Fires on UserPromptSubmit, Stop, and SessionEnd.
# stdin: JSON { session_id, transcript_path, cwd, hook_event_name, ... }

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXTRACT="$SCRIPT_DIR/extract-session.py"

if ! command -v jq &>/dev/null; then exit 0; fi

INPUT=$(cat)
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')
HOOK_EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // empty')

if [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then exit 0; fi

# SessionEnd → archived, otherwise → active
STATUS="active"
if [ "$HOOK_EVENT" = "SessionEnd" ]; then
  STATUS="archived"
fi

python3 "$EXTRACT" "$TRANSCRIPT" --min-msgs 3 --status "$STATUS" 2>/dev/null || true

if command -v qmd &>/dev/null; then
  qmd update 2>/dev/null || true
fi

exit 0
