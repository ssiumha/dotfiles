#!/bin/bash
# worker-orchestrator: list 명령어
# Usage: list
# 활성 워커 tmux 세션 목록.

echo "ACTIVE WORKERS"
echo "=============="

# wt- 프리픽스를 가진 tmux 세션만 필터링
SESSIONS=$(tmux list-sessions 2>/dev/null | grep "^wt-" | cut -d: -f1)

if [ -z "$SESSIONS" ]; then
  echo "_활성 워커 없음_"
  echo ""
  echo "💡 워커 생성: /worker-orchestrator spawn {feature} \"{task}\""
  exit 0
fi

echo "$SESSIONS" | while read -r SESSION; do
  FEATURE=${SESSION#wt-}
  WORKTREE=$(git worktree list | grep "_${FEATURE}_" | awk '{print $1}')

  if [ -n "$WORKTREE" ] && [ -f "${WORKTREE}/.worktree.json" ]; then
    TASK=$(jq -r '.worker.task // "-"' "${WORKTREE}/.worktree.json" 2>/dev/null)
  else
    TASK="-"
  fi

  printf "  %s → %s\n" "$SESSION" "$TASK"
done

echo ""
echo "💡 상세 상태: /worker-orchestrator status"
