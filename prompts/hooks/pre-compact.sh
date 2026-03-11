#!/bin/bash
# PreCompact hook — compaction 직전에 cwd를 wip 파일에 기록
# stdin: JSON { session_id, transcript_path, cwd, trigger, custom_instructions, ... }
# 공식 문서: https://code.claude.com/docs/en/hooks#precompact

if ! command -v jq &>/dev/null; then
  echo "PreCompact: jq not found, skipping" >&2
  exit 0
fi

INPUT=$(cat)
IFS=$'\t' read -r CWD SESSION_ID TRANSCRIPT TRIGGER <<< \
  "$(echo "$INPUT" | jq -r '[.cwd, .session_id, .transcript_path, .trigger] | @tsv')"

if [ -z "$CWD" ] || [ -z "$TRANSCRIPT" ] || [ "$TRANSCRIPT" = "null" ]; then
  echo "PreCompact: cwd or transcript_path missing, skipping" >&2
  exit 0
fi

# transcript_path에서 프로젝트 디렉토리 유도
# 구조: ~/.claude/projects/<project-slug>/<session-uuid>.jsonl
PROJECT_DIR=$(echo "$TRANSCRIPT" | grep -oE '.*/\.claude/projects/[^/]+')
if [ -z "$PROJECT_DIR" ]; then
  echo "PreCompact: cannot derive project dir from transcript_path, skipping" >&2
  exit 0
fi
WIP_DIR="$PROJECT_DIR/memory/wip"

# cwd에서 worktree 이름 유도
#   /foo/wt/cov-service      → cov-service
#   /foo/wt/cov-service/src  → cov-service (첫 세그먼트만)
#   /foo/main                → main
#   /foo/dots                → dots
if [[ "$CWD" == */wt/* ]]; then
  AFTER_WT="${CWD##*/wt/}"
  NAME="${AFTER_WT%%/*}"
else
  NAME=$(basename "$CWD")
fi

mkdir -p "$WIP_DIR"
WIP_FILE="$WIP_DIR/$NAME.md"

# 이미 Claude가 flush한 파일이 있으면 덮어쓰지 않음
# cwd 헤더만 없으면 상단에 추가
if [ -f "$WIP_FILE" ]; then
  if ! grep -q "^## cwd" "$WIP_FILE"; then
    TEMP=$(mktemp)
    {
      echo "## cwd"
      echo "$CWD"
      echo ""
      cat "$WIP_FILE"
    } > "$TEMP"
    mv "$TEMP" "$WIP_FILE"
  fi
else
  cat > "$WIP_FILE" << EOF
# WIP: (auto — PreCompact hook)

## cwd
$CWD

## session
- trigger: $TRIGGER
- timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)
- session_id: ${SESSION_ID:0:8}
EOF
fi

exit 0
