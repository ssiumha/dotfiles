#!/bin/bash
# PreToolUse hook: Bash 명령에서 서버/데몬 직접 실행을 차단하고 overmind 사용을 강제
# Exit 0 = allow, Exit 2 = block

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

[ -z "$COMMAND" ] && exit 0

# overmind 파이프 차단 (양방향: ... | overmind, overmind | ...)
# if echo "$COMMAND" | grep -qE '\|.*overmind\b|overmind\b.*\|'; then
#   echo "Blocked: overmind에 파이프 사용 금지. overmind 명령을 직접 실행하세요" >&2
#   exit 2
# fi

# overmind 명령은 항상 허용
echo "$COMMAND" | grep -qE '^\s*overmind\b' && exit 0

# 프로세스 직접 종료 차단
if echo "$COMMAND" | grep -qE '\b(pkill|killall)\b'; then
  echo "Blocked: 프로세스 직접 종료 금지. overmind stop/restart 사용" >&2
  exit 2
fi

# kill 명령 차단 (kill -0 등 시그널 확인은 허용하지 않음)
if echo "$COMMAND" | grep -qE '\bkill\b'; then
  echo "Blocked: kill 금지. overmind stop/restart 사용" >&2
  exit 2
fi

# 백그라운드 서버 실행 차단 (& 로 끝나는 서버 명령)
if echo "$COMMAND" | grep -qE '(pnpm|npm|yarn|node|python|uvicorn|gunicorn|flask|django|next|vite|tsx)\s.*&\s*$'; then
  echo "Blocked: 백그라운드 서버 실행 금지. Procfile + overmind start 사용" >&2
  exit 2
fi

# nohup, disown 차단
if echo "$COMMAND" | grep -qE '\b(nohup|disown)\b'; then
  echo "Blocked: nohup/disown 금지. Procfile + overmind start 사용" >&2
  exit 2
fi

# 서버 직접 실행 차단 (dev server, start 계열)
# 허용: 테스트, 빌드, 스크립트, REPL, 마이그레이션
if echo "$COMMAND" | grep -qE '\b(pnpm|npm|yarn|bun)\s+(dev|start|serve)\b'; then
  echo "Blocked: 서버 직접 실행 금지. Procfile에 정의 후 overmind start 사용" >&2
  exit 2
fi

# uvicorn, gunicorn 등 WSGI/ASGI 서버 직접 실행 차단
if echo "$COMMAND" | grep -qE '\b(uvicorn|gunicorn|hypercorn|daphne|flask run|manage\.py runserver)\b'; then
  echo "Blocked: 서버 직접 실행 금지. Procfile에 정의 후 overmind start 사용" >&2
  exit 2
fi

# lsof -i + kill 파이프라인 차단
if echo "$COMMAND" | grep -qE 'lsof\s+-i.*\|.*kill'; then
  echo "Blocked: 포트 점유 프로세스 강제 종료 금지. overmind stop && overmind start 사용" >&2
  exit 2
fi

exit 0
