---
name: hooks-setup
description: Configures Claude Code hooks for projects and skills. Use when setting up lint, test, or format hooks in .claude/ directory, or applying hook recipes to skills via SKILL.md frontmatter.
---

# Hooks Setup

Claude Code hooks를 설정하고 관리합니다.

## Hook 개요

| 이벤트 | 시점 | 용도 |
|--------|------|------|
| `PreToolUse` | 도구 실행 전 | 검증, 경고, 자동 승인 |
| `PostToolUse` | 도구 실행 후 | 포맷팅, 린트, 체크 |
| `UserPromptSubmit` | 프롬프트 제출 시 | 컨텍스트 추가, 검증 |
| `Stop` | 응답 완료 시 | 최종 검증, 정리 |
| `SessionStart` | 세션 시작 시 | 환경 설정 |
| `Notification` | 알림 발생 시 | 알림 처리 |

## Instructions

### 워크플로우 1: 프로젝트에 hooks 설정

1. **프로젝트 분석**

   ```bash
   # 언어/프레임워크 감지
   Read package.json      # Node.js
   Read pyproject.toml    # Python
   Read go.mod            # Go
   ```

2. **적합한 레시피 선택**

   | 프로젝트 | 권장 레시피 |
   |----------|-------------|
   | TypeScript/JavaScript | prettier, eslint, console-log-check |
   | Python | ruff, mypy |
   | Go | gofmt, golint |

3. **설정 파일 생성**

   `.claude/settings.json`:

   ```json
   {
     "hooks": {
       "PostToolUse": [
         {
           "matcher": "Edit|Write",
           "hooks": [
             {
               "type": "command",
               "command": "npx prettier --write \"${file_path}\""
             }
           ]
         }
       ]
     }
   }
   ```

4. **완료 안내**

   ```
   ✅ Hooks 설정 완료: .claude/settings.json
   /hooks 명령어로 확인 가능
   ```

### 워크플로우 2: 기존 hooks 수정

1. **현재 설정 확인**
   ```bash
   Read .claude/settings.json
   ```

2. **Edit으로 수정**

## 설정 파일 위치

| 위치 | 경로 | 범위 |
|------|------|------|
| 글로벌 | `~/.claude/settings.json` | 모든 프로젝트 |
| 프로젝트 | `.claude/settings.json` | 현재 프로젝트 (커밋) |
| 로컬 | `.claude/settings.local.json` | 현재 프로젝트 (비커밋) |

## Hook 레시피

### prettier (TypeScript/JavaScript)

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

### eslint

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

### ruff (Python)

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

### console.log 체크 (경고만 - exit 0, 차단 안함)

```json
{
  "Stop": [
    {
      "hooks": [{ "type": "command", "command": "git diff --cached --name-only | xargs grep -l 'console.log' 2>/dev/null && echo '⚠️ console.log detected' || true" }]
    }
  ]
}
```

**차단하려면** (exit 2 사용):
```bash
git diff --cached --name-only | xargs grep -l 'console.log' 2>/dev/null && { echo 'console.log found' >&2; exit 2; } || true
```

## 환경 변수

| 변수 | 설명 |
|------|------|
| `$CLAUDE_PROJECT_DIR` | 프로젝트 루트 경로 |
| `$CLAUDE_ENV_FILE` | 환경변수 저장 파일 (SessionStart) |

## Hook 출력 제어

| Exit Code | 동작 |
|-----------|------|
| 0 | 성공 (stdout → verbose 모드 표시) |
| 2 | 블로킹 (stderr → 에러, 도구 차단) |
| 기타 | 비블로킹 에러 |

### JSON 제어 (PreToolUse)

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow|deny|ask",
    "permissionDecisionReason": "이유"
  }
}
```

## 중요 원칙

1. **프로젝트별 설정 우선**: `.claude/settings.json` 사용
2. **timeout 설정**: 장시간 명령어는 timeout 명시
3. **경로 인용**: 공백 포함 경로 대비 따옴표 사용

## Examples

### TypeScript 프로젝트
User: `/hooks-setup` → 분석 → prettier + eslint 설정

### Python 프로젝트
User: `/hooks-setup python` → ruff 레시피 적용

### 커스텀 hook
User: "Stop 시 테스트 실행 hook" → Stop hook 설정

## Technical Details

### Matcher 패턴

| 패턴 | 매칭 |
|------|------|
| `Edit` | Edit만 |
| `Edit\|Write` | Edit 또는 Write |
| `*` | 모든 도구 |
| `mcp__memory__.*` | MCP 도구 |

### 변경 적용

hooks 변경 후 `/hooks`에서 리뷰 필요 (보안상 자동 미적용)
