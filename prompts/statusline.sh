#!/bin/bash

# ── 셀프테스트: bash statusline.sh --test ──────────────────────────────
# fixture JSON을 stdin으로 재귀 실행. cwd가 비-repo(/tmp)라 git/gh는 빈 값 →
# 출력이 결정적. ANSI를 벗겨 위치·제목·줄수·임계 구조를 검증한다.
if [ "$1" = "--test" ]; then
  BASE='"cwd":"/tmp","workspace":{"project_dir":"/tmp"}'
  strip() { sed $'s/\033\\[[0-9;]*m//g'; }
  pass=0; fail=0
  # check <desc> <json조각> <포함must> <미포함must> [비어있지않은_줄수]
  check() {
    local desc="$1" json="$2" want="$3" notwant="$4" lines="$5" out plain n ok=1
    out=$(printf '%s' "{$json,$BASE}" | bash "$0")
    plain=$(printf '%s' "$out" | strip)
    n=$(printf '%s\n' "$plain" | grep -c .)
    [ -n "$want" ]    && ! printf '%s' "$plain" | grep -qF "$want"    && ok=0
    [ -n "$notwant" ] &&   printf '%s' "$plain" | grep -qF "$notwant" && ok=0
    [ -n "$lines" ]   && [ "$n" != "$lines" ] && ok=0
    if [ "$ok" = 1 ]; then pass=$((pass+1)); else
      fail=$((fail+1)); printf 'FAIL  %-32s got(%s줄): %s\n' "$desc" "$n" "$plain"
    fi
  }

  check "base=main 생략" \
    '"session_name":"t","worktree":{"name":"wt","original_branch":"main"}' \
    "/wt" "<main" 1
  check "base 비-기본 표시" \
    '"session_name":"t","worktree":{"name":"wt","original_branch":"release/1.2"}' \
    "<release/1.2" "" 1
  check "제목 없으면 위치만 1줄" \
    '"worktree":{"name":"wt","original_branch":"main"}' \
    "wt" "" 1
  check "gh 없고 사용량 있으면 2줄" \
    '"session_name":"t","rate_limits":{"five_hour":{"used_percentage":80}}' \
    "rate 80%" "" 2
  check "rate 임계(70) 미만 숨김" \
    '"session_name":"t","rate_limits":{"five_hour":{"used_percentage":60}}' \
    "" "rate" 1
  check "ctx 임계(60) 이상 표시" \
    '"session_name":"t","context_window":{"used_percentage":65}' \
    "ctx 65%" "" 2
  check "ctx 임계 미만 숨김" \
    '"session_name":"t","context_window":{"used_percentage":55}' \
    "" "ctx" 1
  check "긴 제목 전체 출력(절단 안 함)" \
    '"session_name":"가나다라마바사아자차카타파하가나다라마바사아자차카타파하가나다라마바사아자차카타파하"' \
    "카타파하" "..." 1
  check "주간 limit 항상 표시" \
    '"session_name":"t","rate_limits":{"seven_day":{"used_percentage":41}}' \
    "wk 41%" "" 2
  check "주간 리셋 요일 화살표" \
    '"session_name":"t","rate_limits":{"seven_day":{"used_percentage":50,"resets_at":1893456000}}' \
    "wk 50% →" "" 2

  printf '%d passed, %d failed\n' "$pass" "$fail"
  [ "$fail" -eq 0 ]; exit
fi

input=$(cat)

# ANSI 256색 배경 pill 헬퍼 (vim airline 스타일: 세그먼트를 딱 붙여 연속 바로).
# pill <bg> <fg> <text> → " text "(양옆 1칸 bg 패딩). 세그먼트 경계는 색 변화로만 구분.
ESC=$(printf '\033')
RST="${ESC}[0m"
pill() { printf '%s[48;5;%s;38;5;%sm %s %s' "$ESC" "$1" "$2" "$3" "$RST"; }

# cwd follows cd (worktree), project_dir is session-fixed fallback
CWD=$(echo "$input" | jq -r '.cwd // empty')
DIR=$(echo "$input" | jq -r '.workspace.project_dir')
GIT_DIR="${CWD:-$DIR}"

# Verify git repo, fall back to project_dir
if ! git -C "$GIT_DIR" rev-parse --git-dir >/dev/null 2>&1; then
  GIT_DIR="$DIR"
fi

# Worktree detection — use structured JSON fields when available
WT_NAME=$(echo "$input" | jq -r '.worktree.name // empty')
WT_ORIG=$(echo "$input" | jq -r '.worktree.original_branch // empty')

# 프로젝트 루트 복원 — worktree 경로(<루트>/.claude/worktrees/<wt>)면 루트로 되돌린다
PROJ_ROOT="$GIT_DIR"
case "$GIT_DIR" in
  */.claude/worktrees/*)
    PROJ_ROOT="${GIT_DIR%%/.claude/worktrees/*}"
    # JSON worktree 필드가 없어도 경로에서 worktree명 복원
    if [ -z "$WT_NAME" ]; then
      WT_NAME="${GIT_DIR#*/.claude/worktrees/}"
      WT_NAME="${WT_NAME%%/*}"
    fi
    ;;
esac

# 표시명: ~/pj/ 상대경로 > ghq는 repo명만 > ~ 상대경로 > basename
case "$PROJ_ROOT" in
  "$HOME"/pj/*) PROJ_NAME="${PROJ_ROOT#"$HOME"/pj/}" ;;
  "$HOME"/ghq/*) PROJ_NAME="${PROJ_ROOT##*/}" ;;
  "$HOME"/*)    PROJ_NAME="${PROJ_ROOT#"$HOME"/}" ;;
  *)            PROJ_NAME="${PROJ_ROOT##*/}" ;;
esac

# (위치 세그먼트는 STATE 확정 후 아래에서 색과 함께 조립)

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

# Ahead/behind upstream — 어긋날 때만 표시. ahead=+N, behind=-N
AB_FMT=""
AHEAD_BEHIND=$(git -C "$GIT_DIR" rev-list --left-right --count HEAD...@{upstream} 2>/dev/null)
if [ -n "$AHEAD_BEHIND" ]; then
  AHEAD=$(echo "$AHEAD_BEHIND" | cut -f1)
  BEHIND=$(echo "$AHEAD_BEHIND" | cut -f2)
  [ "$AHEAD" -gt 0 ] && AB_FMT="+${AHEAD}"
  [ "$BEHIND" -gt 0 ] && AB_FMT="${AB_FMT}-${BEHIND}"
fi

STATE="${DIRTY:+*}${AB_FMT}"

# 위치 세그먼트 조립 (teal bg 위 인라인 색):
#   프로젝트=일반, 워크트리=bold(현재 위치 강조), 베이스=main/master면 생략(노이즈),
#   비-기본 베이스/브랜치=dim, 상태(*·+/-)=연노랑.
#   브랜치가 worktree 자동 네이밍(worktree-<name>)이면 워크트리명과 중복이라 생략.
# 위치 세그먼트 조립 (teal bg 위 인라인 색):
#   프로젝트=일반, 워크트리=bold(현재 위치 강조), 베이스=main/master면 생략, 비-기본=dim, 상태=연노랑
LOC="${ESC}[22;38;5;255m${PROJ_NAME}"
if [ -n "$WT_NAME" ]; then
  LOC="${LOC}/${ESC}[1m${WT_NAME}${ESC}[22m"
  case "$WT_ORIG" in
    ""|main|master) ;;                                  # 기본 베이스는 표시 안 함
    *) LOC="${LOC}${ESC}[38;5;250m<${WT_ORIG}" ;;
  esac
fi
if [ -n "$BRANCH" ] && [ "$BRANCH" != "worktree-${WT_NAME}" ]; then
  LOC="${LOC}${ESC}[38;5;250m @${BRANCH}"
fi
[ -n "$STATE" ] && LOC="${LOC}${ESC}[38;5;222m${STATE}"

# Session title — statusline 입력의 session_name (v2.1.196+)
# custom name(--name//rename) > AI 생성 서술형 제목. 둘 다 없으면(derived 슬러그만) 필드 자체가 없어 생략됨
TITLE=$(echo "$input" | jq -r '.session_name // empty')
# 절단하지 않는다 — 길면 터미널이 소프트랩. 정보 손실 없이 라인 끝까지 출력.

# PR (subshell cd for gh context)
PR_JSON=$(cd "$GIT_DIR" && gh pr view --json number,state,statusCheckRollup,url 2>/dev/null)
if [ -n "$PR_JSON" ]; then
  PR_NUM=$(echo "$PR_JSON" | jq -r '.number')
  PR_URL=$(echo "$PR_JSON" | jq -r '.url')
  PR_STATE=$(echo "$PR_JSON" | jq -r '.state')
  # https://github.com/owner/repo/pull/69 → owner/repo
  REPO=$(echo "$PR_URL" | sed 's|https://github.com/||;s|/pull/.*||')
  if [ "$PR_STATE" = "MERGED" ]; then
    PR_WORD="merged"
  elif [ "$PR_STATE" = "CLOSED" ]; then
    PR_WORD="closed"
  else
    HAS_FAIL=$(echo "$PR_JSON" | jq '[.statusCheckRollup[]?.conclusion] | any(. == "FAILURE")')
    HAS_PENDING=$(echo "$PR_JSON" | jq '[.statusCheckRollup[]?.conclusion] | any(. == null or . == "PENDING")')
    if [ "$HAS_FAIL" = "true" ]; then
      PR_WORD="fail"
    elif [ "$HAS_PENDING" = "true" ]; then
      PR_WORD="..."
    else
      PR_WORD="ok"
    fi
  fi
  GH_PR="${REPO}#${PR_NUM} ${PR_WORD}"
fi

# CI — latest workflow run for current branch
CI_JSON=$(cd "$GIT_DIR" && gh run list --branch "$BRANCH" --limit 1 --json status,conclusion 2>/dev/null | jq '.[0] // empty')
if [ -n "$CI_JSON" ]; then
  CI_STATUS=$(echo "$CI_JSON" | jq -r '.status')
  CI_CONCLUSION=$(echo "$CI_JSON" | jq -r '.conclusion // empty')
  if [ "$CI_STATUS" = "completed" ]; then
    case "$CI_CONCLUSION" in
      success) GH_CI="ci:ok" ;;
      failure) GH_CI="ci:fail" ;;
      cancelled) GH_CI="ci:cancel" ;;
      *) GH_CI="ci:?" ;;
    esac
  else
    GH_CI="ci:..."
  fi
fi

# gh 세그먼트 텍스트 + 상태별 배경색 (fail>pending>merged>closed>ok)
GH_INNER=""
[ -n "$GH_PR" ] && GH_INNER="$GH_PR"
[ -n "$GH_CI" ] && GH_INNER="${GH_INNER:+$GH_INNER }$GH_CI"
GH_BG=""
if [ -n "$GH_INNER" ]; then
  case "$GH_INNER" in
    *fail*)   GH_BG=124 ;;  # red
    *...*)    GH_BG=136 ;;  # yellow (pending)
    *merged*) GH_BG=91 ;;   # purple
    *closed*) GH_BG=240 ;;  # gray
    *)        GH_BG=28 ;;   # green
  esac
fi

# 사용량 — 임계 초과 시에만. bg 심각도별. rate/ctx는 서로 다른 색조라 붙여도 경계가 보임
RL_TEXT=""
RL_PCT=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
if [ -n "$RL_PCT" ] && [ "${RL_PCT%.*}" -ge 70 ]; then
  RL_TIME=""
  RL_RESET=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
  if [ -n "$RL_RESET" ]; then
    RL_LEFT=$((RL_RESET - NOW))
    [ "$RL_LEFT" -gt 0 ] && RL_TIME="(-$((RL_LEFT / 3600))h$(( (RL_LEFT % 3600) / 60 ))m)"
  fi
  RL_TEXT="rate ${RL_PCT%.*}%${RL_TIME:+ ${RL_TIME}}"
  [ "${RL_PCT%.*}" -ge 90 ] && RL_BG=124 || RL_BG=130  # red / dark-orange
fi

CTX_TEXT=""
CTX_PCT=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$CTX_PCT" ] && [ "${CTX_PCT%.*}" -ge 60 ]; then
  CTX_TEXT="ctx ${CTX_PCT%.*}%"
  [ "${CTX_PCT%.*}" -ge 80 ] && CTX_BG=160 || CTX_BG=94   # bright-red / olive
fi

# 주간(7일) limit — 있으면 항상 표시(예산 추적). 리셋 요일(→월)로 남은 정도 직관화
WK_TEXT=""
WK_PCT=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
if [ -n "$WK_PCT" ]; then
  WK_DAY=""
  WK_RESET=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
  if [ -n "$WK_RESET" ]; then
    WK_DOW=$(date -r "$WK_RESET" +%u 2>/dev/null)   # 1=월 .. 7=일
    KDAYS=(월 화 수 목 금 토 일)
    [ -n "$WK_DOW" ] && WK_DAY=" →${KDAYS[WK_DOW-1]}"
  fi
  WK_TEXT="wk ${WK_PCT%.*}%${WK_DAY}"
  if [ "${WK_PCT%.*}" -ge 90 ]; then WK_BG=124        # red
  elif [ "${WK_PCT%.*}" -ge 70 ]; then WK_BG=130      # orange
  else WK_BG=24; fi                                   # blue (정보)
fi

# 1줄 = 위치 + 제목 (정체성). 2줄 = gh + 사용량 (뒤따르는 상태) — 있을 때만.
LINE1="${ESC}[48;5;31m ${LOC} ${RST}"
[ -n "$TITLE" ] && LINE1="${LINE1}$(pill 238 251 "$TITLE")"

LINE2=""
[ -n "$GH_INNER" ] && LINE2=$(pill "$GH_BG" 231 "gh:$GH_INNER")
[ -n "$RL_TEXT" ]  && LINE2="${LINE2}$(pill "$RL_BG" 231 "$RL_TEXT")"
[ -n "$CTX_TEXT" ] && LINE2="${LINE2}$(pill "$CTX_BG" 231 "$CTX_TEXT")"
[ -n "$WK_TEXT" ]  && LINE2="${LINE2}$(pill "$WK_BG" 231 "$WK_TEXT")"

echo "$LINE1"
[ -n "$LINE2" ] && echo "$LINE2"
exit 0
