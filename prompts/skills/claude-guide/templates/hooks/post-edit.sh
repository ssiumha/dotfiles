#!/usr/bin/env bash
# PostToolUse hook for Edit/Write
# Install: .claude/hooks/post-edit.sh

set -euo pipefail

# 입력에서 파일 경로 추출
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

[[ -z "$FILE_PATH" ]] && exit 0
[[ ! -f "$FILE_PATH" ]] && exit 0

# 제외 패턴
[[ "$FILE_PATH" == *"/vendor/"* ]] && exit 0
[[ "$FILE_PATH" == *"/node_modules/"* ]] && exit 0
[[ "$FILE_PATH" == *".generated."* ]] && exit 0
[[ "$FILE_PATH" == *".min."* ]] && exit 0

# 확장자별 linter 실행
case "$FILE_PATH" in
  *.ts|*.tsx|*.js|*.jsx)
    # Biome 우선, 없으면 ESLint
    if command -v biome &>/dev/null; then
      biome check --write "$FILE_PATH" 2>/dev/null || true
    elif [[ -f "node_modules/.bin/eslint" ]]; then
      npx eslint --fix "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
  *.py)
    # Ruff 우선, 없으면 Black
    if command -v ruff &>/dev/null; then
      ruff check --fix "$FILE_PATH" 2>/dev/null || true
      ruff format "$FILE_PATH" 2>/dev/null || true
    elif command -v black &>/dev/null; then
      black "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
  *.rb)
    if command -v rubocop &>/dev/null; then
      rubocop -A "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
  *.go)
    if command -v gofmt &>/dev/null; then
      gofmt -w "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
  *.rs)
    if command -v rustfmt &>/dev/null; then
      rustfmt "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
esac

exit 0
