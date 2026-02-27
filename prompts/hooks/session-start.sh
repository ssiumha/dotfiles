#!/bin/bash
# SessionStart hook — compaction 후 wip 파일을 Claude 컨텍스트에 주입
# matcher: compact (compaction 직후에만 fire)
# stdout → Claude가 볼 수 있는 컨텍스트로 주입됨
# 공식 문서: https://code.claude.com/docs/en/hooks#sessionstart

if ! command -v jq &>/dev/null; then
  exit 0
fi

INPUT=$(cat)
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')

if [ -z "$TRANSCRIPT" ]; then
  exit 0
fi

PROJECT_DIR=$(echo "$TRANSCRIPT" | grep -oE '.*/\.claude/projects/[^/]+')
if [ -z "$PROJECT_DIR" ]; then
  exit 0
fi
WIP_DIR="$PROJECT_DIR/memory/wip"

if [ ! -d "$WIP_DIR" ]; then
  exit 0
fi

# wip 파일이 있으면 내용을 stdout으로 출력 → Claude 컨텍스트에 주입
WIP_FILES=$(find "$WIP_DIR" -name "*.md" -type f 2>/dev/null)
if [ -z "$WIP_FILES" ]; then
  exit 0
fi

echo "=== WIP 복원 (PreCompact hook이 저장한 작업 상태) ==="
echo ""
for f in $WIP_FILES; do
  NAME=$(basename "$f" .md)
  echo "--- wip/$NAME ---"
  cat "$f"
  echo ""
done
echo "=== 위 WIP 상태를 기반으로 이전 작업을 이어서 진행하세요 ==="

exit 0
