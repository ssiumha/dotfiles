#!/bin/bash
# Batch extract unprocessed sessions to Logseq pages + QMD re-index.
# Usage: recall-index.sh [--days N] [--force] [--dry-run]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOGSEQ_PAGES="$HOME/Documents/logseq/pages"
CLAUDE_PROJECTS="$HOME/.claude/projects"
EXTRACT="$SCRIPT_DIR/extract-session.py"

DAYS=""
FORCE=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --days)   DAYS="$2"; shift 2 ;;
    --force)  FORCE=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    *)        echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# Collect existing session-ids for dedup
declare -A EXISTING_IDS
if [ -d "$LOGSEQ_PAGES" ]; then
  while IFS= read -r line; do
    sid=$(echo "$line" | sed 's/^session-id:: *//')
    EXISTING_IDS["$sid"]=1
  done < <(grep -rh "^session-id::" "$LOGSEQ_PAGES"/session___*.md 2>/dev/null || true)
fi

# Date filter (--days N: only files modified in last N days)
FIND_ARGS=(-name "*.jsonl" -type f)
if [ -n "$DAYS" ]; then
  FIND_ARGS+=(-mtime "-${DAYS}")
fi

TOTAL=0
EXTRACTED=0
SKIPPED=0

echo "=== Recall Index: scanning sessions ==="

find "$CLAUDE_PROJECTS" "${FIND_ARGS[@]}" 2>/dev/null | sort | while IFS= read -r jsonl; do
  TOTAL=$((TOTAL + 1))

  # Quick extract session-id from first few lines
  SID=$(python3 -c "
import json, sys
with open('$jsonl') as f:
    for line in f:
        try:
            obj = json.loads(line)
            sid = obj.get('sessionId', '')
            if sid:
                print(sid[:8])
                sys.exit(0)
        except: pass
" 2>/dev/null || echo "")

  if [ -z "$SID" ]; then
    continue
  fi

  # Skip if already extracted (unless --force)
  if [ "$FORCE" != "true" ] && [ "${EXISTING_IDS[$SID]+exists}" ]; then
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  if [ "$DRY_RUN" = "true" ]; then
    echo "  [dry-run] Would extract: $SID ($jsonl)"
    EXTRACTED=$((EXTRACTED + 1))
  else
    echo "  Extracting: $SID"
    python3 "$EXTRACT" "$jsonl" --min-msgs 3 2>/dev/null || true
    EXTRACTED=$((EXTRACTED + 1))
  fi
done

echo ""
echo "=== Done: extracted=$EXTRACTED, skipped=$SKIPPED ==="

# QMD re-index (skip in dry-run)
if [ "$DRY_RUN" != "true" ] && command -v qmd &>/dev/null; then
  echo ""
  echo "=== Updating QMD index ==="
  qmd update 2>/dev/null || true
  qmd embed 2>/dev/null || true
  echo "=== QMD index updated ==="
fi
