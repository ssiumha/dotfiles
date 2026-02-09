#!/bin/bash
# worker-orchestrator: spawn 명령어
# Usage: spawn {feature} "{task}"
# 워커 생성. worktree에 Claude 인스턴스 배치.

set -e

FEATURE="{feature}"
TASK="{task}"
SESSION="wt-${FEATURE}"

# 1. worktree 경로 찾기
WORKTREE=$(git worktree list | grep "_${FEATURE}_" | awk '{print $1}')

if [ -z "$WORKTREE" ]; then
  echo "❌ worktree를 찾을 수 없음: ${FEATURE}"
  echo "💡 먼저 worktree를 생성하세요:"
  echo "   /git-worktree add ${FEATURE}"
  exit 1
fi

# 2. 이미 실행 중인 세션 확인
if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "⚠️ 이미 실행 중인 워커: ${SESSION}"
  echo "💡 상태 확인: /worker-orchestrator status ${FEATURE}"
  echo "💡 종료 후 재시작: /worker-orchestrator kill ${FEATURE}"
  exit 1
fi

# 3. tmux 세션 생성
tmux new-session -d -s "$SESSION" -c "$WORKTREE"

# 4. Claude 시작 (--dangerously-skip-permissions)
# WHY: 워커는 자동 실행을 위해 권한 확인 스킵
tmux send-keys -t "$SESSION" 'claude --dangerously-skip-permissions' Enter

# 5. 초기화 대기 (Claude 시작 시간)
sleep 3

# 6. 권한 확인 화면 통과 (Down, Enter로 "Yes, I accept" 선택)
tmux send-keys -t "$SESSION" Down Enter
sleep 2

# 7. 상태 파일 초기화
echo "running" > "${WORKTREE}/.worker-status"

# 8. 작업 지시 전송 (표준 프로토콜)
tmux send-keys -t "$SESSION" "${TASK}

완료되면:
1. 결과를 .worker-result.md 에 저장
2. echo \"done\" > .worker-status
3. \"작업 완료\" 출력

실패 시:
1. 에러 내용을 .worker-result.md 에 저장
2. echo \"failed\" > .worker-status
3. \"작업 실패\" 출력" Enter

# 9. .worktree.json에 worker 정보 추가
if [ -f "${WORKTREE}/.worktree.json" ]; then
  STARTED_AT=$(date -u +"%Y-%m-%dT%H:%M:%S")
  # jq로 worker 필드 추가/업데이트
  jq --arg session "$SESSION" \
     --arg task "$TASK" \
     --arg started "$STARTED_AT" \
     '.worker = {session: $session, task: $task, started_at: $started}' \
     "${WORKTREE}/.worktree.json" > "${WORKTREE}/.worktree.json.tmp"
  mv "${WORKTREE}/.worktree.json.tmp" "${WORKTREE}/.worktree.json"
fi

echo "✅ 워커 생성: ${SESSION}"
echo "📁 worktree: ${WORKTREE}"
echo "📋 작업: ${TASK}"
echo ""
echo "💡 상태 확인: /worker-orchestrator status ${FEATURE}"
echo "💡 결과 수집: /worker-orchestrator collect ${FEATURE}"
