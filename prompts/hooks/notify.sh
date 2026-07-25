#!/bin/bash
# Notification hook — Claude가 주의를 요할 때(권한 요청 / 60초+ 유휴 대기) macOS 알림.
# stdin: JSON { message, session_id, cwd, transcript_path, ... }
# 매 턴이 아니라 "자리 비운 사이 Claude가 대기"할 때만 발동한다.

command -v osascript >/dev/null 2>&1 || exit 0

input=$(cat)
if command -v jq >/dev/null 2>&1; then
  msg=$(printf '%s' "$input" | jq -r '.message // "주의가 필요합니다"')
  cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
else
  msg="주의가 필요합니다"
  cwd=""
fi
proj="${cwd##*/}"
title="Claude Code${proj:+ · $proj}"

# AppleScript 문자열 안전화 (역슬래시 → 먼저, 그다음 따옴표)
esc() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }

if command -v terminal-notifier >/dev/null 2>&1; then
  terminal-notifier -title "$title" -message "$msg" -sound Ping -group claude-code 2>/dev/null
else
  osascript -e "display notification \"$(esc "$msg")\" with title \"$(esc "$title")\" sound name \"Ping\"" 2>/dev/null
fi
exit 0
