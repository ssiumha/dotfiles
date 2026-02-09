#!/bin/bash
# worker-orchestrator: kill 명령어
# Usage: kill {feature}
# 워커 종료. tmux 세션 종료 및 정리.

FEATURE="{feature}"
SESSION="wt-${FEATURE}"

# 1. worktree 경로 찾기
WORKTREE=$(git worktree list | grep "_${FEATURE}_" | awk '{print $1}')

# 2. tmux 세션 존재 확인
if ! tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "❌ 실행 중인 워커 없음: ${SESSION}"
  exit 1
fi

# 3. 상태 확인 (running이면 경고)
if [ -n "$WORKTREE" ] && [ -f "${WORKTREE}/.worker-status" ]; then
  STATUS=$(cat "${WORKTREE}/.worker-status")
  if [ "$STATUS" = "running" ]; then
    echo "⚠️ 워커가 아직 작업 중입니다 (status: running)"
    echo "💡 강제 종료하려면 다시 실행하세요"
    echo ""
    echo "최근 출력:"
    tmux capture-pane -t "$SESSION" -p | tail -10
    exit 1
  fi
fi

# 4. tmux 세션 종료
tmux kill-session -t "$SESSION"
echo "✅ 워커 종료: ${SESSION}"

# 5. .worktree.json에서 worker 필드 제거
if [ -n "$WORKTREE" ] && [ -f "${WORKTREE}/.worktree.json" ]; then
  jq 'del(.worker)' "${WORKTREE}/.worktree.json" > "${WORKTREE}/.worktree.json.tmp"
  mv "${WORKTREE}/.worktree.json.tmp" "${WORKTREE}/.worktree.json"
  echo "✅ worker 정보 제거"
fi

# 6. 상태 파일 삭제
if [ -n "$WORKTREE" ] && [ -f "${WORKTREE}/.worker-status" ]; then
  rm "${WORKTREE}/.worker-status"
  echo "✅ 상태 파일 삭제"
fi

echo ""
echo "💡 결과 파일은 유지됩니다: ${WORKTREE}/.worker-result.md"
