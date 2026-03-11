# Hook 레시피 카탈로그

프로젝트에 바로 적용할 수 있는 hooks 설정 모음입니다.

## prettier (TypeScript/JavaScript)

```json
{
  "PostToolUse": [
    {
      "matcher": "Edit|Write",
      "hooks": [{ "type": "command", "command": "npx prettier --write \"${file_path}\"", "timeout": 30 }]
    }
  ]
}
```

## eslint

```json
{
  "PostToolUse": [
    {
      "matcher": "Edit|Write",
      "hooks": [{ "type": "command", "command": "npx eslint --fix \"${file_path}\"", "timeout": 30 }]
    }
  ]
}
```

## ruff (Python)

```json
{
  "PostToolUse": [
    {
      "matcher": "Edit|Write",
      "hooks": [{ "type": "command", "command": "ruff format \"${file_path}\" && ruff check --fix \"${file_path}\"" }]
    }
  ]
}
```

## console.log 체크 (경고만)

```json
{
  "Stop": [
    {
      "hooks": [{ "type": "command", "command": "git diff --cached --name-only | xargs grep -l 'console.log' 2>/dev/null && echo 'console.log detected' || true" }]
    }
  ]
}
```

**차단하려면** (exit 2 사용):
```bash
git diff --cached --name-only | xargs grep -l 'console.log' 2>/dev/null && { echo 'console.log found' >&2; exit 2; } || true
```

## 레시피 포맷 (YAML)

```yaml
name: recipe-name
description: 설명
event: Stop  # PreToolUse | PostToolUse | Stop
matcher: ""  # 도구명 정규식 (선택)
hooks:
  - type: command
    command: "${SKILL_DIR}/scripts/my-script.sh"

# 선택: 스크립트 템플릿
script_template: |
  #!/bin/bash
  echo "Hook executed"
```
