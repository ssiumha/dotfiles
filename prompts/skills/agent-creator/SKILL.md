---
name: agent-creator
description: Creates and manages custom Claude Code sub-agents. Use when automating workflows as dedicated agents, delegating recurring tasks, or modifying .claude/agents/ files.
---

# Sub-agent Creator

Claude Code용 커스텀 sub-agent를 생성하고 관리합니다. Sub-agent는 특정 작업에 특화된 AI 어시스턴트로, 독립적인 컨텍스트와 전문화된 역할을 가집니다.

## Key Components

### 파일 위치

| 위치 | 경로 | 용도 |
|------|------|------|
| 프로젝트 | `.claude/agents/{name}.md` | 현재 프로젝트에서만 사용 |
| 전역 | `~/.claude/agents/{name}.md` | 모든 프로젝트에서 사용 |

### 필수 설정

| 필드 | 설명 | 예시 |
|------|------|------|
| `name` | kebab-case 식별자 | `code-reviewer`, `test-runner` |
| `description` | 자동 위임 트리거 조건 | `Use proactively after code changes` |

### 선택 설정

| 필드 | 기본값 | 옵션 |
|------|--------|------|
| `tools` | 모두 상속 | `Read, Grep, Glob, Bash, Edit, Write` |
| `model` | sonnet | `haiku`, `sonnet`, `opus`, `inherit` |
| `permissionMode` | default | `acceptEdits`, `dontAsk`, `bypassPermissions` |
| `skills` | 없음 | 자동 로드할 skill 목록 |

## Creation Process

### 1. 요구사항 수집

AskUserQuestion으로 확인:

**[필수]**
- **목적**: 이 agent가 무엇을 하는가?
- **트리거**: 언제 자동 호출되어야 하는가?

**[선택]**
- **도구 제한**: 읽기만? 수정도?
- **모델**: 빠른 응답(haiku) vs 정밀 분석(sonnet/opus)?

### 2. 기존 agent 확인

중복 방지를 위해 검색:
```bash
Glob ~/.claude/agents/*.md
Glob .claude/agents/*.md
```

유사 agent 발견 시 사용자에게 확인:
- 기존 agent 확장 vs 신규 생성

### 3. 위치 선택

항상 사용자에게 질문:
- [1] 프로젝트: `.claude/agents/{name}.md`
- [2] 전역: `~/.claude/agents/{name}.md`

### 4. 시스템 프롬프트 작성

`templates/subagent-template.md` 기반으로 작성:

1. **역할 정의**: "You are an expert {domain}."
2. **초기 액션**: 호출 시 첫 행동 (1-3개)
3. **책임**: 주요 담당 영역
4. **가이드라인**: 작업 규칙
5. **출력 형식**: 반환할 메시지 구조

### 5. 파일 생성

```bash
Write {위치}/{name}.md
```

## Modification Process

기존 agent 수정 시:

1. **대상 확인**: 기존 agent 파일 Read
2. **수정 유형 파악**:
   - 역할 확장 → Responsibilities 추가
   - 규칙 추가 → Guidelines 추가
   - 출력 변경 → Output Format 수정
   - 설정 변경 → frontmatter 수정
3. **Edit으로 수정**: 기존 구조 유지하며 변경

## Critical Design Principles

### 0. 역할 설계: SRP + OCP

**SRP (Single Responsibility)**: 하나의 agent는 하나의 책임만 갖는다.
- 책임이 둘 이상이면 agent를 나눈다
- "~도 하고 ~도 한다"면 분리 신호

**OCP (Open/Closed)**: 새 능력이 필요하면 기존 agent를 수정하지 말고 새로 만들어 조합한다.
- 기존 agent에 역할을 추가하기보다 새 agent를 만든다
- 기존 agent 확장은 같은 책임의 깊이를 더할 때만 (예: code-reviewer에 DB 호환성 체크 추가)

```
# 좋은 예: 각자 하나의 책임
code-explorer  → 탐색
code-reviewer  → 리뷰
test-verifier  → 테스트 검증

# 나쁜 예: 하나가 여러 책임
code-helper    → 탐색 + 리뷰 + 테스트 + 커밋 정리
```

### 1. description이 핵심

description은 **automatic delegation**의 트리거입니다:

```yaml
# 나쁜 예
description: Code reviewer

# 좋은 예
description: Use PROACTIVELY after code changes (2+ files modified), before commits. Analyzes quality, security, performance.
```

**효과적인 description:**
- "Use proactively" 또는 "MUST BE USED" 포함
- 구체적 트리거 조건 명시
- 키워드 포함 (어떤 요청에 반응할지)

### 2. 시스템 프롬프트 구조

```markdown
{역할 1-2문장}

## Upon Invocation
1. {첫 행동}
2. {두 번째 행동}
3. {세 번째 행동}

## Responsibilities
- {책임 1}
- {책임 2}

## Guidelines
- {규칙 1}
- {규칙 2}

## Output Format
{마크다운 템플릿}
```

### 3. 도구 최소화 (Context Engineering)

**원칙**: 필요한 도구만 허가. 도구가 많을수록 컨텍스트 낭비.

| 용도 | 권장 도구 | 이유 |
|------|----------|------|
| 읽기 전용 분석 | `Read, Grep, Glob` | 수정 불필요 → Write/Edit 제외 |
| 코드 수정 | `Read, Edit, Write, Bash, Grep, Glob` | 최소 필요 집합 |
| 보안 감사 | `Read, Grep, Glob` | 읽기만 + permissionMode: plan |
| 전체 권한 | 생략 (모두 상속) | 정말 필요한 경우만 |

**기본 전략**: 읽기 전용(`Read, Grep, Glob`)으로 시작 → 필요 시 추가

### 4. 모델 선택

| 모델 | 용도 | 비용/속도 |
|------|------|----------|
| `haiku` | 단순 검색, 패턴 매칭, 빠른 검사 | 저비용, 빠름 |
| `sonnet` | 일반 분석, 코드 리뷰, 문서 작성 | 균형 (기본값) |
| `opus` | 복잡한 추론, 아키텍처 분석 | 고비용, 정밀 |
| `inherit` | 부모 agent와 동일 | 상황에 따름 |

### 5. skills 필드

Subagent에 자동 로드할 skill 목록. 상세: [resources/03-skills-field.md](resources/03-skills-field.md)

## Examples

### 새 agent 생성

**User**: "코드 리뷰 agent 만들어줘"

**Flow**:
1. 요구사항 수집
   - 목적: 코드 품질, 보안 검토
   - 트리거: 2개 이상 파일 수정 시
2. 기존 agent 확인 → 중복 없음
3. 위치 선택 → 프로젝트
4. 템플릿 기반 생성
5. `.claude/agents/code-reviewer.md` 작성

### 기존 agent 수정

**User**: "code-reviewer에 성능 검토 추가해줘"

**Flow**:
1. 기존 파일 Read
2. Responsibilities에 성능 항목 추가
3. Guidelines에 성능 관련 규칙 추가
4. Edit으로 수정

## 병렬 Subagent 패턴

### 실행 제약

| 항목 | 설명 |
|------|------|
| 병렬 실행 | ✅ Main agent에서 최대 10개 동시 실행 |
| 중첩 호출 | ❌ Subagent가 다른 subagent 호출 불가 |
| 10개 초과 | 큐잉되어 배치 실행 |
| 토큰 사용 | 3-4배 증가 (각 agent ~20K 오버헤드) |

### 적합한 사용 사례

| 패턴 | 예시 |
|------|------|
| 파일별 분할 | 75개 파일 리팩토링 (파일당 1 agent) |
| 역할별 분할 | PM + UX + Engineer 병렬 분석 |
| 모듈별 분할 | 마이크로서비스별 인시던트 분석 |
| 검증 분할 | style-checker + security-scanner + test-coverage |

### 제안 시점

독립적인 작업이 3개 이상일 때 병렬 subagent를 제안:

```
"이 작업은 독립적인 [N]개 부분으로 나눌 수 있습니다.
병렬 subagent로 진행하면 시간을 단축할 수 있습니다:

1. [agent-a]: 파일 A-M 처리
2. [agent-b]: 파일 N-Z 처리
3. [agent-c]: 테스트 검증

진행할까요? (토큰 사용량 증가 주의)"
```

### 워크플로우

```
Main Agent:
  1. 대상 파일/모듈 목록 수집 (grep/glob)
  2. Task tool로 병렬 subagent 실행 (한 메시지에 여러 Task)
  3. 결과 취합 및 최종 검증
```

## Technical Details

상세 정보는 다음 파일 참조:
- `resources/01-available-tools.md`: 도구 목록 및 권장 조합
- `resources/02-examples.md`: 실제 agent 예시
- `templates/subagent-template.md`: 범용 템플릿
