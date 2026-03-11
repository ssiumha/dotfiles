# Hooks Reference

Claude Code hooks를 설정하고 관리합니다.

## Hook 이벤트

| 이벤트 | 시점 | 용도 |
|--------|------|------|
| `PreToolUse` | 도구 실행 전 | 검증, 경고, 자동 승인 |
| `PostToolUse` | 도구 실행 후 | 포맷팅, 린트, 체크 |
| `UserPromptSubmit` | 프롬프트 제출 시 | 컨텍스트 추가, 검증 |
| `Stop` | 응답 완료 시 | 최종 검증, 정리 |
| `SessionStart` | 세션 시작 시 | 환경 설정 |
| `Notification` | 알림 발생 시 | 알림 처리 |

## 설정 파일 위치

| 위치 | 경로 | 범위 |
|------|------|------|
| 글로벌 | `~/.claude/settings.json` | 모든 프로젝트 |
| 프로젝트 | `.claude/settings.json` | 현재 프로젝트 (커밋) |
| 로컬 | `.claude/settings.local.json` | 현재 프로젝트 (비커밋) |

## 설정 형식

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
            "command": "npx prettier --write \"${file_path}\"",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

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

## Matcher 패턴

| 패턴 | 매칭 |
|------|------|
| `Edit` | Edit만 |
| `Edit\|Write` | Edit 또는 Write |
| `*` | 모든 도구 |
| `mcp__memory__.*` | MCP 도구 |

## 환경 변수

| 변수 | 설명 |
|------|------|
| `$CLAUDE_PROJECT_DIR` | 프로젝트 루트 경로 |
| `$CLAUDE_ENV_FILE` | 환경변수 저장 파일 (SessionStart) |

## Skill-scoped Hooks

SKILL.md frontmatter에 hooks를 정의하여 해당 skill 사용 시에만 활성화됩니다.

### 글로벌 hooks vs 스킬 hooks

| 구분 | 글로벌 hooks | 스킬 hooks |
|------|-------------|-----------|
| 위치 | `.claude/settings.local.json` | SKILL.md frontmatter |
| 범위 | 전체 세션 | 해당 skill 사용 시만 |

### SKILL.md frontmatter 포맷

```yaml
---
name: skill-name
description: ...
hooks:
  Stop:
    - hooks:
        - type: command
          command: "path/to/script.sh"
  PostToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: "path/to/another-script.sh"
          once: true
---
```

### 변수

| 변수 | 설명 |
|------|------|
| `${SKILL_DIR}` | 적용 대상 skill 디렉토리 경로 |
| `${PROJECT_ROOT}` | 프로젝트 루트 |

### 옵션

| 옵션 | 설명 |
|------|------|
| `once: true` | 세션당 1회만 실행 |
| `matcher` | 도구명 정규식 필터 |

## 이벤트별 상세

### PreToolUse
- **시점**: 도구 실행 전
- **용도**: 위험한 작업 차단
- **차단 방법**: stdout으로 JSON 출력 후 exit 2

### PostToolUse
- **시점**: 도구 실행 완료 후
- **용도**: 즉각적 검증/포맷팅
- **주의**: 매 수정마다 실행 (빠른 도구만)

### Stop
- **시점**: skill 처리 완료 시
- **용도**: 전체 검증, 상태 저장, 로깅

## 트러블슈팅

| 문제 | 해결 |
|------|------|
| hook 미실행 | `/skills` 명령으로 인식 확인, frontmatter YAML 문법 검증 |
| 스크립트 오류 | 실행 권한 확인 (`chmod +x`), 경로 확인 |
| 변수 치환 안됨 | `${SKILL_DIR}` 대신 실제 경로로 직접 지정 |
| hooks 변경 미반영 | `/hooks`에서 리뷰 필요 (보안상 자동 미적용) |

## 레시피 목록

| 레시피 | 이벤트 | 용도 |
|--------|--------|------|
| auto-save-state | Stop | 스킬 완료 시 상태 파일에 타임스탬프 추가 |
| post-edit-lint | PostToolUse | 파일 수정 후 자동 lint |
| post-edit-test | PostToolUse | 파일 수정 후 관련 테스트 실행 |
| pre-bash-guard | PreToolUse | 위험한 명령어 차단 |
| on-complete-log | Stop | 스킬 완료 로그 기록 |

레시피 YAML 파일: `recipes/` 디렉토리 참조
