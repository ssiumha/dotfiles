#!/bin/bash
input=$(cat)

# cwd follows cd (worktree), project_dir is session-fixed fallback
CWD=$(echo "$input" | jq -r '.cwd // empty')
DIR=$(echo "$input" | jq -r '.workspace.project_dir')
GIT_DIR="${CWD:-$DIR}"

# Verify git repo, fall back to project_dir
if ! git -C "$GIT_DIR" rev-parse --git-dir >/dev/null 2>&1; then
  GIT_DIR="$DIR"
fi

FOLDER="${GIT_DIR##*/}"
BRANCH=$(git -C "$GIT_DIR" branch --show-current 2>/dev/null)
DIRTY=$(git -C "$GIT_DIR" status --porcelain 2>/dev/null | head -1)
NBSP=$(printf '\xc2\xa0')

# PR (subshell cd for gh context)
PR_JSON=$(cd "$GIT_DIR" && gh pr view --json number,state,statusCheckRollup,url 2>/dev/null)
if [ -n "$PR_JSON" ]; then
  PR_NUM=$(echo "$PR_JSON" | jq -r '.number')
  PR_URL=$(echo "$PR_JSON" | jq -r '.url')
  PR_STATE=$(echo "$PR_JSON" | jq -r '.state')
  # https://github.com/owner/repo/pull/69 → owner/repo
  REPO=$(echo "$PR_URL" | sed 's|https://github.com/||;s|/pull/.*||')
  if [ "$PR_STATE" = "MERGED" ]; then
    SUFFIX="⊕"
  elif [ "$PR_STATE" = "CLOSED" ]; then
    SUFFIX="∅"
  else
    HAS_FAIL=$(echo "$PR_JSON" | jq '[.statusCheckRollup[]?.conclusion] | any(. == "FAILURE")')
    HAS_PENDING=$(echo "$PR_JSON" | jq '[.statusCheckRollup[]?.conclusion] | any(. == null or . == "PENDING")')
    if [ "$HAS_FAIL" = "true" ]; then
      SUFFIX="✗"
    elif [ "$HAS_PENDING" = "true" ]; then
      SUFFIX="⏳"
    else
      SUFFIX="✓"
    fi
  fi
  GH_PR="${REPO}#${PR_NUM}${SUFFIX}"
fi

# CI — latest workflow run for current branch
CI_JSON=$(cd "$GIT_DIR" && gh run list --branch "$BRANCH" --limit 1 --json status,conclusion 2>/dev/null | jq '.[0] // empty')
if [ -n "$CI_JSON" ]; then
  CI_STATUS=$(echo "$CI_JSON" | jq -r '.status')
  CI_CONCLUSION=$(echo "$CI_JSON" | jq -r '.conclusion // empty')
  if [ "$CI_STATUS" = "completed" ]; then
    case "$CI_CONCLUSION" in
      success) GH_CI="✓" ;;
      failure) GH_CI="✗" ;;
      cancelled) GH_CI="∅" ;;
      *) GH_CI="?" ;;
    esac
  else
    GH_CI="⏳"
  fi
fi

# Combine into GH segment: 🐙 gh:owner/repo#123✓ ⏳
GH_INNER=""
[ -n "$GH_PR" ] && GH_INNER="$GH_PR"
[ -n "$GH_CI" ] && GH_INNER="${GH_INNER:+$GH_INNER }$GH_CI"
[ -n "$GH_INNER" ] && GH_FMT="🐙${NBSP}gh:${GH_INNER}"

# Context window usage
CTX_JSON=$(echo "$input" | jq -r '.context_window // empty')
if [ -n "$CTX_JSON" ]; then
  CTX_PCT=$(echo "$CTX_JSON" | jq -r '.used_percentage // empty')
  if [ -n "$CTX_PCT" ]; then
    CTX_FMT="💬 ${CTX_PCT}%"
  fi
fi

# Build segments
LINE1="📁 $FOLDER 🌿 $BRANCH${DIRTY:+*}"
LINE2=""
for seg in "$GH_FMT" "$CTX_FMT"; do
  [ -n "$seg" ] && LINE2="${LINE2:+$LINE2 }$seg"
done

if [ -z "$LINE2" ]; then
  echo "$LINE1"
else
  COLS=$(tput cols 2>/dev/null || stty size </dev/tty 2>/dev/null | cut -d' ' -f2 || echo 80)
  FULL="$LINE1 $LINE2"
  CHAR_W=$(printf '%s' "$FULL" | wc -m | tr -d ' ')
  EMOJI_W=$(printf '%s' "$FULL" | perl -CS -ne 'print scalar(() = /[\x{1F000}-\x{1FFFF}]/g)' 2>/dev/null || echo 0)
  DISPLAY_W=$((CHAR_W + EMOJI_W))

  if [ "$DISPLAY_W" -le "$COLS" ]; then
    echo "$FULL"
  else
    echo "$LINE1"
    echo "$LINE2"
  fi
fi
