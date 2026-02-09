#!/bin/bash
# worker-orchestrator: status 명령어
# Usage: status [feature]
# 워커 상태 확인. feature 없으면 전체 조회.

# 헤더 출력
printf "%-20s %-10s %-10s %s\n" "WORKER" "STATUS" "DURATION" "LAST OUTPUT"
echo "================================================================"

# worktree 목록에서 워커 정보 추출
git worktree list | while read -r line; do
  WORKTREE_PATH=$(echo "$line" | awk '{print $1}')

  # .worktree.json에서 feature 추출
  if [ ! -f "${WORKTREE_PATH}/.worktree.json" ]; then
    continue
  fi

  FEATURE=$(jq -r '.feature // empty' "${WORKTREE_PATH}/.worktree.json" 2>/dev/null)
  [ -z "$FEATURE" ] && continue

  # 특정 feature 필터링
  if [ -n "{feature}" ] && [ "$FEATURE" != "{feature}" ]; then
    continue
  fi

  SESSION="wt-${FEATURE}"

  # tmux 세션 존재 확인
  if ! tmux has-session -t "$SESSION" 2>/dev/null; then
    continue
  fi

  # 상태 파일 확인
  STATUS_FILE="${WORKTREE_PATH}/.worker-status"
  if [ -f "$STATUS_FILE" ]; then
    STATUS=$(cat "$STATUS_FILE")
  else
    STATUS="unknown"
  fi

  # 실행 시간 계산
  STARTED=$(jq -r '.worker.started_at // empty' "${WORKTREE_PATH}/.worktree.json" 2>/dev/null)
  if [ -n "$STARTED" ]; then
    # macOS/Linux 호환 시간 계산
    START_SEC=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$STARTED" +%s 2>/dev/null || date -d "$STARTED" +%s 2>/dev/null || echo 0)
    NOW_SEC=$(date +%s)
    DIFF=$((NOW_SEC - START_SEC))
    DURATION="$((DIFF / 60))m $((DIFF % 60))s"
  else
    DURATION="-"
  fi

  # 최근 출력 (마지막 1줄)
  LAST_OUTPUT=$(tmux capture-pane -t "$SESSION" -p | grep -v "^$" | tail -1 | cut -c1-40)
  [ -z "$LAST_OUTPUT" ] && LAST_OUTPUT="-"

  printf "%-20s %-10s %-10s %s\n" "$SESSION" "$STATUS" "$DURATION" "\"${LAST_OUTPUT}...\""
done
