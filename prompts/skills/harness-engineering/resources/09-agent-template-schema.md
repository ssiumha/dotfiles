# 에이전트 템플릿 스키마 (Agent Template Schema)

`.claude/agents/{name}.md` 파일의 공식 스키마와 실전 결정 가이드.

## Frontmatter 필드

| 필드 | 필수 | 타입 | 기본값 | 설명 |
|------|------|------|--------|------|
| `name` | Yes | string | — | 고유 식별자. lowercase + hyphens (`security-reviewer`) |
| `description` | Yes | string | — | **트리거 결정 기준**. Claude가 이걸 보고 위임 여부를 판단 |
| `tools` | No | string/list | 부모 전체 상속 | 허용 도구 목록. `Read, Glob, Grep, Bash` |
| `disallowedTools` | No | string/list | — | 차단 도구. tools와 함께 쓰면 disallowed가 먼저 적용 |
| `model` | No | string | 부모 모델 상속 | `sonnet`, `opus`, `haiku`, `inherit`, 또는 전체 모델 ID |
| `permissionMode` | No | string | `default` | 6가지 모드 (아래 참조) |
| `maxTurns` | No | number | — | 최대 에이전트 턴 수. 무한루프 방지 |
| `skills` | No | list | — | 시작 시 로드할 스킬. **부모 스킬 상속 안 됨** |
| `mcpServers` | No | list | — | 인라인 정의 또는 기존 서버 이름 참조 |
| `hooks` | No | object | — | 에이전트 전용 lifecycle hooks (PreToolUse, PostToolUse, Stop) |
| `memory` | No | string | — | 영속 메모리: `user`, `project`, `local` |
| `background` | No | boolean | false | true면 항상 백그라운드 실행 |
| `effort` | No | string | — | `low`, `medium`, `high`, `max` (Opus 4.6 전용) |
| `isolation` | No | string | — | `worktree`: 임시 git worktree에서 실행 |
| `color` | No | string | — | UI 표시 색상 |
| `initialPrompt` | No | string | — | `--agent`로 실행 시 자동 첫 턴 |

## Scope 해소 (우선순위 높은 순)

```
1. Managed settings (조직 전체)
2. --agents CLI 플래그 (현재 세션)
3. .claude/agents/ (프로젝트)
4. ~/.claude/agents/ (사용자 전체)
5. Plugin agents/ (플러그인 활성화 범위)
```

**원칙**: 프로젝트 특화 → `.claude/agents/`. 범용 → `~/.claude/agents/`.

## 핵심 결정 트리

### Model 선택

```
오케스트레이션/판단 → opus
구현/수정 → sonnet (기본)
탐색/검색 → haiku (빠르고 저렴)
부모와 동일 → inherit 또는 생략
```

**Model resolution order**: `CLAUDE_CODE_SUBAGENT_MODEL` env > 호출 시 파라미터 > frontmatter `model` > 부모 모델.

**비용 원칙**: 비싼 모델(Opus)은 오케스트레이터에, 싼 모델(Haiku)은 단순 탐색/분류에.

### Permission Mode 선택

| 모드 | 동작 | 적합 용도 |
|------|------|-----------|
| `default` | 표준 권한 확인 (프롬프트) | 대화형 작업 |
| `acceptEdits` | 파일 수정 자동 승인 | 구현 에이전트 |
| `auto` | 백그라운드 분류기가 검토 | 중간 신뢰 자동화 |
| `dontAsk` | 권한 요청 자동 거부 | 읽기 전용 강제 |
| `bypassPermissions` | 권한 확인 건너뜀 | 완전 자율 (주의) |
| `plan` | 읽기 전용 탐색 모드 | 조사/계획 에이전트 |

### Tool 제한 패턴

**읽기 전용**:
```yaml
tools: Read, Glob, Grep, Bash
disallowedTools: Edit, Write, NotebookEdit
```

**구현 전용** (하위 에이전트 스폰 제한):
```yaml
tools: Read, Glob, Grep, Bash, Edit, Write, Agent(helper)
```

**스폰 제한** — `Agent(child1, child2)` 문법으로 생성 가능한 하위 에이전트를 제한:
```yaml
name: coordinator
tools: Agent(worker, researcher), Read, Bash
```

### Memory Scope 선택

| Scope | 저장 위치 | 용도 |
|-------|-----------|------|
| `user` | `~/.claude/agent-memory/{name}/` | 모든 프로젝트에서 학습 (범용 리뷰어) |
| `project` | `.claude/agent-memory/{name}/` | 프로젝트 특화 학습 (VCS 공유 가능) |
| `local` | `.claude/agent-memory-local/{name}/` | 로컬 전용 (VCS 제외) |

**원칙**: 팀 공유 학습 → `project`. 개인 선호 → `user`. 임시/민감 → `local`.

## Hooks in Agent

에이전트 frontmatter에 직접 정의하면 해당 에이전트 활성 시에만 실행:

| Event | 시점 | 용도 |
|-------|------|------|
| `PreToolUse` | 도구 사용 전 | 위험 명령 차단, SQL 읽기 전용 강제 |
| `PostToolUse` | 도구 사용 후 | 결과 검증, 로깅 |
| `Stop` | 에이전트 종료 시 | 산출물 검증, 알림 |

**패턴: DB Query Validator** — Bash 명령에서 읽기 전용 SQL만 허용:
```yaml
hooks:
  PreToolUse:
    - matcher: Bash
      command: "validate-readonly-sql.sh $INPUT"
```
exit code 2 → 실행 차단 + 에러 메시지를 에이전트에 피드백.

**settings.json 측 Hook** (메인 세션에서 서브에이전트 lifecycle 감시):
- `SubagentStart` — 서브에이전트 시작 시
- `SubagentStop` — 서브에이전트 완료 시

## Teammate 호환성

서브에이전트 정의를 Agent Teams의 teammate로 재사용할 수 있지만 **제한 사항**:

| 필드 | Subagent | Teammate |
|------|----------|----------|
| `tools` | 적용 | 적용 |
| `model` | 적용 | 적용 |
| `permissionMode` | 적용 | **리더 설정 상속** (스폰 후 개별 변경 가능) |
| `skills` | 적용 | **무시** |
| `mcpServers` | 적용 | **무시** |

**주의**: frontmatter의 `skills`/`mcpServers` 필드가 무시되는 것이지, 프로젝트 컨텍스트(CLAUDE.md, 프로젝트 MCP 서버)는 teammate에도 정상 로드됨.

→ teammate로도 쓸 에이전트는 frontmatter `skills`/`mcpServers`에 의존하지 않는 시스템 프롬프트를 작성한다.

## 호출 방식

| 방식 | 문법 | 보장 수준 |
|------|------|-----------|
| Natural language | "보안 리뷰 해줘" | Claude가 description 기반 판단 (비보장) |
| @-mention | `@"security-reviewer (agent)" auth 모듈 점검` | 한 작업에 대해 보장 |
| Session-wide | `claude --agent security-reviewer` | 세션 전체 |
| Settings | `"agent": "security-reviewer"` | 프로젝트 전체 |

## 예시

### 읽기 전용 리뷰어

```markdown
---
name: code-reviewer
description: Reviews code for quality, security, and best practices. Use when asked to review code or PRs.
tools: Read, Glob, Grep, Bash
model: sonnet
permissionMode: plan
---

You are a code reviewer. Analyze code and provide specific, actionable feedback.

## Principles
- 보안 취약점 우선 (OWASP Top 10)
- 구체적 파일:라인 참조 필수
- 칭찬과 비판 균형

## Output Format
- **Critical**: 즉시 수정 필요
- **Warning**: 개선 권장
- **Note**: 참고 사항
```

### 구현 에이전트 (하위 스폰 제한)

```markdown
---
name: implementer
description: Implements features based on specs. Use when given a design doc or feature request.
tools: Read, Glob, Grep, Bash, Edit, Write, Agent(test-runner)
model: sonnet
permissionMode: acceptEdits
maxTurns: 50
memory: project
---

You are a feature implementer. Read the spec, implement incrementally, commit often.

## Principles
- 한 번에 하나의 기능
- 테스트 먼저 (test-runner 에이전트로 위임)
- 기존 패턴 따르기

## I/O Protocol
- Input: 설계 문서 경로 또는 요구사항 텍스트
- Output: 구현 코드 + 커밋 + 요약
```

### 비용 최적화 탐색기

```markdown
---
name: codebase-explorer
description: Fast codebase exploration and analysis. Use when searching for patterns, understanding architecture, or gathering context.
model: haiku
permissionMode: dontAsk
effort: low
background: true
---

You are a fast codebase explorer. Find information quickly and return concise summaries.

## Principles
- 결과는 filepath:line 형태로 인용
- 500단어 이내 요약
- 추측 금지 — 못 찾으면 "not found" 보고
```
