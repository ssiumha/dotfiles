#!/bin/bash
# worker-orchestrator: kill-all 명령어
# Usage: kill-all [--force]
# 모든 워커 일괄 종료.

FORCE="${FORCE:-false}"

SESSIONS=$(tmux list-sessions 2>/dev/null | grep "^wt-" | cut -d: -f1)

if [ -z "$SESSIONS" ]; then
  echo "✅ 종료할 워커 없음"
  exit 0
fi

# running 상태 확인 (--force 없으면)
if [ "$FORCE" != "true" ]; then
  RUNNING_COUNT=0
  # WHY: while read는 subshell에서 실행되므로 for 루프 사용
  for SESSION in $SESSIONS; do
    FEATURE=${SESSION#wt-}
    WORKTREE=$(git worktree list | grep "_${FEATURE}_" | awk '{print $1}')
    if [ -n "$WORKTREE" ] && [ -f "${WORKTREE}/.worker-status" ]; then
      STATUS=$(cat "${WORKTREE}/.worker-status")
      [ "$STATUS" = "running" ] && RUNNING_COUNT=$((RUNNING_COUNT + 1))
    fi
  done

  if [ "$RUNNING_COUNT" -gt 0 ]; then
    echo "⚠️ ${RUNNING_COUNT}개 워커가 아직 작업 중입니다"
    echo "💡 강제 종료: /worker-orchestrator kill-all --force"
    exit 1
  fi
fi

# 일괄 종료
for SESSION in $SESSIONS; do
  tmux kill-session -t "$SESSION" 2>/dev/null
  echo "✅ 종료: ${SESSION}"
done

echo ""
echo "✅ 모든 워커 종료 완료"
