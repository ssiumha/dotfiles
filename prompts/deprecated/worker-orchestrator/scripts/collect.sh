#!/bin/bash
# worker-orchestrator: collect 명령어
# Usage: collect [feature]
# 완료된 워커 결과 수집. feature 없으면 모든 done 상태 워커.

echo "# Worker Results"
echo ""
echo "Collected at: $(date)"
echo ""

COLLECTED=0

git worktree list | while read -r line; do
  WORKTREE_PATH=$(echo "$line" | awk '{print $1}')

  if [ ! -f "${WORKTREE_PATH}/.worktree.json" ]; then
    continue
  fi

  FEATURE=$(jq -r '.feature // empty' "${WORKTREE_PATH}/.worktree.json" 2>/dev/null)
  [ -z "$FEATURE" ] && continue

  # 특정 feature 필터링
  if [ -n "{feature}" ] && [ "$FEATURE" != "{feature}" ]; then
    continue
  fi

  # 상태 확인 (done 또는 failed만 수집)
  STATUS_FILE="${WORKTREE_PATH}/.worker-status"
  if [ ! -f "$STATUS_FILE" ]; then
    continue
  fi

  STATUS=$(cat "$STATUS_FILE")
  if [ "$STATUS" != "done" ] && [ "$STATUS" != "failed" ]; then
    # 특정 feature 지정 시 running도 포함
    if [ -z "{feature}" ]; then
      continue
    fi
  fi

  # 결과 파일 확인
  RESULT_FILE="${WORKTREE_PATH}/.worker-result.md"

  echo "---"
  echo ""
  echo "## wt-${FEATURE}"
  echo ""
  echo "**Status**: ${STATUS}"
  echo "**Worktree**: ${WORKTREE_PATH}"
  echo ""

  if [ -f "$RESULT_FILE" ]; then
    cat "$RESULT_FILE"
  else
    echo "_결과 파일 없음_"
  fi

  echo ""
  COLLECTED=$((COLLECTED + 1))
done

if [ "$COLLECTED" -eq 0 ]; then
  echo "_수집할 완료된 워커가 없습니다._"
  echo ""
  echo "💡 상태 확인: /worker-orchestrator status"
fi
