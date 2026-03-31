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

NBSP=$(printf '\xc2\xa0')

# Worktree detection — use structured JSON fields when available
WT_NAME=$(echo "$input" | jq -r '.worktree.name // empty')
WT_ORIG=$(echo "$input" | jq -r '.worktree.original_branch // empty')

if [ -n "$WT_NAME" ]; then
  FOLDER="${WT_NAME}${WT_ORIG:+ (from ${WT_ORIG})}"
else
  FOLDER="${GIT_DIR##*/}"
fi

BRANCH=$(git -C "$GIT_DIR" branch --show-current 2>/dev/null)
DIRTY=$(git -C "$GIT_DIR" status --porcelain 2>/dev/null | head -1)

# Background fetch + cache (60s TTL)
REPO_HASH=$(printf '%s' "$GIT_DIR" | md5 2>/dev/null || printf '%s' "$GIT_DIR" | md5sum 2>/dev/null | cut -d' ' -f1)
FETCH_CACHE="/tmp/claude-statusline-fetch-${REPO_HASH}"
NOW=$(date +%s)
LAST_FETCH=$(cat "$FETCH_CACHE" 2>/dev/null || echo 0)
if [ $((NOW - LAST_FETCH)) -ge 60 ]; then
  echo "$NOW" > "$FETCH_CACHE"
  git -C "$GIT_DIR" fetch --quiet 2>/dev/null &
fi

# Ahead/behind upstream
AB_FMT=""
AHEAD_BEHIND=$(git -C "$GIT_DIR" rev-list --left-right --count HEAD...@{upstream} 2>/dev/null)
if [ -n "$AHEAD_BEHIND" ]; then
  AHEAD=$(echo "$AHEAD_BEHIND" | cut -f1)
  BEHIND=$(echo "$AHEAD_BEHIND" | cut -f2)
  if [ "$AHEAD" -gt 0 ] && [ "$BEHIND" -gt 0 ]; then
    AB_FMT="↑${AHEAD}↓${BEHIND}"
  elif [ "$AHEAD" -gt 0 ]; then
    AB_FMT="↑${AHEAD}"
  elif [ "$BEHIND" -gt 0 ]; then
    AB_FMT="↓${BEHIND}"
  else
    AB_FMT="≡"
  fi
fi

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

# Rate limit (5h window) — progress bar
RL_PCT=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
if [ -n "$RL_PCT" ]; then
  RL_INT=${RL_PCT%.*}
  RL_FILLED=$((RL_INT / 10))
  RL_EMPTY=$((10 - RL_FILLED))
  RL_BAR=$(printf '█%.0s' $(seq 1 $RL_FILLED 2>/dev/null) ; printf '░%.0s' $(seq 1 $RL_EMPTY 2>/dev/null))
  RL_RESET=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
  if [ -n "$RL_RESET" ]; then
    RL_LEFT=$((RL_RESET - NOW))
    if [ "$RL_LEFT" -gt 0 ]; then
      RL_H=$((RL_LEFT / 3600))
      RL_M=$(( (RL_LEFT % 3600) / 60 ))
      RL_TIME="${RL_H}h${RL_M}m"
    else
      RL_TIME="reset"
    fi
    RL_FMT="⚡${RL_BAR}${NBSP}${RL_INT}%${NBSP}(${RL_TIME})"
  else
    RL_FMT="⚡${RL_BAR}${NBSP}${RL_INT}%"
  fi
fi

# Context window usage
CTX_PCT=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$CTX_PCT" ]; then
  CTX_FMT="💬${NBSP}${CTX_PCT}%"
fi

# Build segments
LINE1="📁 $FOLDER 🌿 $BRANCH${DIRTY:+*}${AB_FMT}"
LINE2=""
for seg in "$GH_FMT" "$RL_FMT" "$CTX_FMT"; do
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
