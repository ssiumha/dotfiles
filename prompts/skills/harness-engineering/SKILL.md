---
name: harness-engineering
description: Audits, improves, and tracks Claude Code agent harness (CLAUDE.md, rules, hooks, skills, agents, settings, memory, architecture, knowledge base). Use when reviewing harness quality, adding constraints/rules/hooks, designing agent teams/orchestration, optimizing agent performance, diagnosing agent misbehavior, setting up harness for a new repository, or managing documentation freshness. Do NOT use for creating new skills (use my-skill-creator) or basic Claude Code setup (use claude-guide).
---

# Harness Engineering

실수하기 어려운 환경을 구조적으로 만들고, 리포지터리를 에이전트의 유일한 기록 시스템으로 만든다.

> 에이전트의 관점에서 실행 중 컨텍스트 내에서 접근할 수 없는 것은 사실상 존재하지 않는다.
> Slack, Google Docs, 사람 머릿속에 있는 지식은 리포지터리에 인코딩되지 않으면 에이전트에게 없는 것이다.

## 방법론의 우선순위

위에서부터 우선 검토하되, 각 레이어는 고유 역할이 있어 동시 적용한다:

1. **불가능하게 만들기** — Hook/PreToolUse가 차단, 커스텀 린터가 거부. 린트 에러 메시지 자체가 에이전트에게 수정 지침을 주입
2. **길을 잃지 않게 하기** — Codebase Map(ARCHITECTURE.md)으로 탐색 제거. CLAUDE.md는 목차(~100줄), 백과사전이 아닌
3. **올바른 길을 쉽게 하기** — Rule + 예시로 정답을 가까이. Why를 설명하면 edge case에서 맥락 판단
4. **잘못된 길을 감지하기** — pre-commit/pre-push, ArchUnit/lint. 커밋 전에 잡기
5. **엔트로피를 수거하기** — 정기 정리(가비지 컬렉션). 품질 등급 추적, 오래된 문서 갱신, 기술 부채 점진 상환

**설계 원칙**: 리포지터리와 코드를 에이전트가 추론할 수 있도록 최적화한다. 에이전트가 검사하고, 검증하며, 직접 수정할 수 있는 형태로 시스템을 끌어올수록 레버리지가 높아진다.

## Harness 구성 요소

### Navigation Layer (길을 잃지 않게)

| 구성 요소 | 역할 | 파일 |
|-----------|------|------|
| **Codebase Map** | 경험 많은 개발자의 정신적 코드 지도 문서화. 모듈 간 관계, 불변식, 횡단 관심사 | `ARCHITECTURE.md`, `.claude/rules/architecture.md` |
| **Knowledge Base** | 설계 문서, 실행 계획, 제품 스펙 — 리포지터리가 기록 시스템 | `docs/` (design-docs, exec-plans, product-specs, references) |

### Instruction Layer (올바른 길을 쉽게)

| 구성 요소 | 역할 | 파일 |
|-----------|------|------|
| **Project Instructions** | 목차 역할. 규약/환경/명령 요약 → 상세는 rules로 | `CLAUDE.md` (~100줄 이하) |
| **Rules** | 개별 컨벤션. Why + 예시 포함 | `.claude/rules/*.md` |
| **Skills** | 반복 패턴의 자동화된 확장 | `.claude/skills/*/SKILL.md` |
| **Memory** | 세션 간 학습 유지 | `MEMORY.md`, memory files |

### Enforcement Layer (실수를 불가능하게 + 감지)

| 구성 요소 | 역할 | 파일 |
|-----------|------|------|
| **Hooks** | 라이프사이클 결정론적 코드 실행 | `settings.json` hooks |
| **Custom Linters** | 아키텍처/취향 강제. 에러 메시지 = 에이전트 수정 지침 | ArchUnit, ESLint, Biome, custom rules |
| **Git Hooks** | 커밋/푸시 전 품질 게이트 | `.githooks/`, pre-commit, pre-push |
| **Permissions** | 도구 접근 제어 | `settings.json` allow/deny |

### Orchestration Layer (협업을 구조화)

| 구성 요소 | 역할 | 파일 |
|-----------|------|------|
| **Agents** | 전문가 페르소나 정의. 역할, 원칙, I/O 프로토콜 | `.claude/agents/{name}.md` |
| **Team Patterns** | 에이전트 간 협업 토폴로지 (Pipeline, Fan-out, Expert Pool 등) | `resources/08-agent-team-patterns.md` |

## Instructions

### 워크플로우 1: Audit (하네스 감사)

**1. 하네스 인벤토리 수집**

Navigation Layer:
- `Read ARCHITECTURE.md` — 코드베이스 지도 존재 여부
- `Glob docs/**/*.md` — 지식 베이스 구조

Instruction Layer:
- `Read CLAUDE.md` — 프로젝트 instructions (분량 확인)
- `Glob .claude/rules/*.md` — 규칙 파일 목록
- `Glob .claude/skills/*/SKILL.md` — 프로젝트 skills
- `Glob .claude/agents/*.md` — 에이전트 정의 파일

Enforcement Layer:
- `Read .claude/settings.json` — hooks, permissions
- 프로젝트 git hooks 확인
- 커스텀 린터/ArchUnit 존재 여부
- 아키텍처 테스트 구성 확인 — 스택별 감지 (`resources/06-arch-test-tools.md` 참조)

**2. 다차원 진단 (7+1)**

각 차원을 0-3으로 평가. 상세 체크리스트: `resources/01-audit-checklist.md`.

| 차원 | 평가 기준 |
|------|-----------|
| **Navigation** | Codebase Map이 있는가, BE↔FE 매핑, 핵심 파일 경로, 도메인 흐름 |
| **Knowledge Base** | docs/가 기록 시스템인가, 설계 문서/스펙/계획이 리포지터리에 있는가 |
| **Instructions** | CLAUDE.md가 목차인가(≤100줄), rules로 분리되었는가, progressive disclosure |
| **Constraints** | 컨벤션이 rules로 명문화, Why 포함, 자동 검증 연동, 아키텍처 테스트 구성 |
| **Enforcement** | hooks/린터로 품질 강제, 린트 에러가 수정 지침을 포함하는가 |
| **Memory** | MEMORY.md 200줄 이내, 중복/obsolete 없음 |
| **Entropy Management** | 문서 신선도 검증, 품질 등급, 정기 정리 프로세스 |
| **Orchestration** (조건부) | agents/ 정의 품질, 팀 토폴로지, 검증 — `.claude/agents/` 존재 시만 |

**3. 감사 보고서 출력**

```
## Harness Audit Report — {project}

### Score: {총점}/21 (또는 /24 — Orchestration 포함 시)

| 차원 | 점수 | 핵심 발견 |
|------|------|-----------|
| Navigation | N/3 | ... |
| ... | | |

### Top 3 개선 포인트
1. [높은 영향 + 낮은 노력] ...
2. ...
3. ...
```

### 워크플로우 2: Setup (새 프로젝트 하네스 구축)

새 리포지터리 또는 하네스가 없는 프로젝트에 적용하는 순서:

**Phase 1 — Navigation** (부트 비용 제거가 최우선)
1. 코드베이스 스캔하여 `ARCHITECTURE.md` 생성 — 상세 가이드: `resources/04-architecture-guide.md`
   - 필수 4섹션: Bird's Eye View → Codemap → Invariants → Cross-Cutting Concerns
   - Codemap이 핵심: "X를 하는 것은 어디?" 질문에 답하는 모듈 간 관계 지도
   - 직접 링크 대신 검색 가능한 심볼 이름 사용
   - 검증: "에이전트가 이것만 읽고 수정 위치를 찾을 수 있는가?"
2. `.claude/rules/architecture.md` 생성 (ARCHITECTURE.md의 핵심 요약 5-10항목, 매 세션 자동 로드)

**Phase 2 — Instructions** (목차 + 핵심 규칙)
3. `CLAUDE.md` 작성 — 목차 역할 (~100줄). ARCHITECTURE.md 참조 포함
4. 핵심 rules 추가 — 가장 자주 위반되는 컨벤션부터 (Why + 예시 필수)

**Phase 2.5 — Orchestration** (반복 멀티스텝 워크플로우가 있는 프로젝트만)
5. 에이전트 팀 설계 — 상세: `resources/08-agent-team-patterns.md`
   - 에이전트 정의: `.claude/agents/{name}.md` (역할, 원칙, I/O 프로토콜)
   - 실행 모드 선택: Agent Teams(2+ 에이전트 협업) vs Sub-agents(일회성)
   - 검증: 트리거 검증(should-trigger / should-NOT-trigger) + 드라이런

**Phase 3 — Enforcement** (실수를 불가능하게)
6. Git hooks 설정 (pre-commit: fmt+lint, pre-push: full check)
7. Claude Code hooks 설정 — 보호 파일 Edit 차단 등
8. Permissions 설정 — 위험 명령 deny, 파괴적 git 명령 ask
9. 아키텍처 테스트 설정 제안 — 스택에 맞는 도구 안내 (`resources/06-arch-test-tools.md` 참조)
   - ARCHITECTURE.md에 불변식이 있으면 해당 불변식을 테스트로 전환
   - CI에 아키텍처 테스트 단계 추가 권장

**Phase 4 — Knowledge Base** (리포지터리를 기록 시스템으로)
10. `docs/` 구조 설계 — 프로젝트 규모에 맞게
11. 기존 외부 문서(Slack, Google Docs)를 리포지터리로 인코딩

### 워크플로우 3: Improve (하네스 개선)

| 유형 | 트리거 | 행동 |
|------|--------|------|
| Codebase Map 갱신 | 새 도메인/패키지 추가됨 | ARCHITECTURE.md + rules/architecture.md 업데이트 |
| Rule 추가 | 컨벤션 반복 위반 관찰 | `.claude/rules/{name}.md` 생성 (Why + 예시) |
| 린트 메시지 최적화 | 린트 실패 후 에이전트가 수정 방법을 모름 | 에러 메시지에 수정 지침 주입 |
| Hook 추가 | 결정론적 강제 필요 | `update-config` skill로 위임 |
| 아키텍처 테스트 도입 | Constraints Score 2 + ARCHITECTURE.md 불변식 존재 | 스택에 맞는 아키텍처 테스트 도구 제안 (`resources/06-arch-test-tools.md`) |
| 불변식 커버리지 확장 | Audit에서 특정 유형 불변식 미비 | `resources/07-invariant-taxonomy.md`로 미커버 유형 식별 후 추가 |
| 에이전트 정의 추가 | 반복되는 전문 역할 패턴 관찰 | `.claude/agents/{name}.md` 생성 (`resources/08-agent-team-patterns.md`) |
| 팀 토폴로지 설계 | 2+ 에이전트 협업 필요 | 6개 팀 패턴에서 선택, 검증 후 적용 |
| 문서 인코딩 | 외부에만 있는 지식 발견 | docs/에 마크다운으로 기록 |
| CLAUDE.md 다이어트 | 100줄 초과 | rules로 분리, 목차만 남기기 |
| Gardening 스킬 생성 | Audit 후 doc-gardening 스킬 부재 | 워크플로우 4 → 4단계 실행 |

**개선 원칙**:
- 한 번에 하나 적용하고 효과 관찰
- "규칙이 부족하면 rule로, rule이 부족하면 코드로" — 문서화 부족 시 규칙 승격, 규칙이 안 지켜지면 린터/hook으로 승격
- 경계만 강제하고 내부는 자율 — 불변 조건(종속성 방향, 네이밍, 파싱 경계)을 기계적으로 강제하되, 구현 방법은 에이전트에게 위임
- 이유를 기록 — rule/commit에 왜 이 변경이 필요한지 명시

### 워크플로우 4: Gardening (엔트로피 관리)

코드베이스는 시간이 지나면 드리프트한다. 정기적으로 정리하지 않으면 나쁜 패턴이 퍼진다.

**1. 문서 신선도 점검**
- ARCHITECTURE.md가 실제 코드와 일치하는가? (새 패키지 누락, 삭제된 패키지 잔존)
- rules가 현재 코드 관행과 일치하는가?
- CLAUDE.md에 오래된 정보가 있는가?

**2. 품질 등급 추적** (선택)
- 도메인별/레이어별 품질 점수를 docs/에 기록
- 시간에 따른 변화 추적

**3. 정리 PR 생성**
- 오래된 문서 갱신
- 사용하지 않는 rule 제거
- 기술 부채 점진 상환 — "매일 조금씩 갚는 것이 한꺼번에 갚는 것보다 낫다"

**4. 프로젝트 전용 Gardening 스킬 생성** (선택)

Level 2+ 프로젝트(ARCHITECTURE.md + rules 존재)에서, `.claude/skills/doc-gardening/SKILL.md`가 없으면 생성을 제안한다. 이미 존재하면 현재 코드와 비교하여 outdated 항목(경로 변경, 수량 변경)을 갱신한다.

**생성 절차**:
1. 프로젝트 스캔 — 아래 항목을 자동 수집
   - ARCHITECTURE.md 구조 (섹션 목록, 테이블 종류)
   - 소스 디렉토리 루트 (패키지 경로, features 경로 등)
   - `.claude/rules/*.md` 목록
   - `docs/` 하위 구조
2. 스킬 생성 — 템플릿(`resources/05-doc-gardening-template.md`)을 기반으로 프로젝트 특화 점검 절차를 SKILL.md에 기록
   - 각 점검 항목에 실제 경로와 현재 수량 하드코딩
   - 100점 기준 감점 방식 보고서 포맷 포함
   - `my-skill-creator` skill이 있으면 위임, 없으면 직접 작성

**점검 항목 (프로젝트에 해당하는 것만 포함)**:

| 조건 | 점검 항목 |
|------|-----------|
| ARCHITECTURE.md 존재 | 패키지/디렉토리 목록 일치 검증 |
| BE↔FE 매핑 테이블 존재 | 매핑 항목 양방향 실존 검증 |
| rules에 파일 경로 참조 | 참조 경로 실존 검증 |
| docs/ 존재 | 링크 유효성 + 신선도(90일) |

### 워크플로우 5: Diagnose (에이전트 오작동 진단)

| 원인 | 진단 | 처방 |
|------|------|------|
| 지식 부재 | 정보가 리포지터리에 없음 (외부에만 존재) | docs/에 인코딩 |
| 규칙 부재 | 해당 컨벤션이 rules에 없음 | Rule 추가 (워크플로우 3) |
| 규칙 모호 | Rule이 있지만 해석이 다양 | Rule 구체화 + 예시 추가 |
| 린트 메시지 부족 | 린트가 실패하지만 에이전트가 수정 방법을 모름 | 에러 메시지에 수정 지침 주입 |
| 규칙 위치 오류 | Rule이 있지만 로드되지 않음 | 파일 경로/계층 확인 |
| 컨텍스트 과부하 | CLAUDE.md가 백과사전화 | 목차로 전환, rules로 분리 |
| 탐색 비용 | Codebase Map 없이 매 세션 Glob/Grep | ARCHITECTURE.md 생성/갱신 |
| 피드백 미반영 | 교정이 다음 세션에서 반복 | memory에 feedback 저장 |
| 에이전트 역할 중복 | 여러 에이전트가 같은 작업을 수행 | Agent 통합 또는 Expert Pool로 전환 |
| 팀 통신 실패 | 에이전트 간 산출물 연결 끊김 | I/O 프로토콜 재정의, 드라이런 검증 |

## Invariant Lifecycle

발견 → 정의 → 강제의 3단계. 단계를 건너뛰지 않는다.

1. **발견**: 장애 역추적, PR 반복 코멘트, absence 스캔 (`resources/07-invariant-taxonomy.md`)
2. **정의**: ARCHITECTURE.md `## Invariants` 에 Why와 함께 기록 (`resources/04-architecture-guide.md`)
3. **강제**: 기계적 검증 구현 (`resources/06-arch-test-tools.md`)
   - 구조 → ArchUnit / eslint-plugin-boundaries
   - 데이터 → 스키마 검증 테스트
   - 보안 → PreToolUse hook + SAST

강제 없는 정의는 드리프트한다. 정의 없는 강제는 "왜"를 모른다.

## 안티패턴

### 하네스 설계

| 문제 | 대안 |
|------|------|
| "하나의 큰 CLAUDE.md"에 모든 것을 넣음 | 목차(~100줄) + rules + docs로 분리. "모든 것이 중요하면 아무것도 중요하지 않다" |
| 위반을 보고 바로 MUST/NEVER rule 추가 | 반복 관찰 후 규칙화, Why를 먼저 기록 |
| Hook으로 모든 것을 강제 | Hook은 안전/품질 게이트에만, 스타일은 rule로 |
| 린트 에러 메시지가 불친절 | 에러 메시지에 수정 방법을 에이전트 지침으로 주입 |
| 프로젝트 A의 harness를 B에 복사 | 각 저장소 맥락에 맞게 감사(워크플로우 1)부터 시작 |
| Rule만 추가하고 효과 미확인 | 모니터링 신호 확인 + 정기 gardening |

### 컨텍스트 낭비

| 문제 | 대안 |
|------|------|
| 코드베이스 지도 없이 매 세션 Glob/Grep | ARCHITECTURE.md + rules/architecture.md |
| 지식이 Slack/Google Docs에만 존재 | 리포지터리 docs/에 인코딩 — "에이전트가 접근 못 하면 없는 것" |
| `/init` 자동생성 CLAUDE.md 방치 | "제거해도 실수 안 하면 삭제" |
| 문서를 한 번 쓰고 방치 | 정기 gardening으로 신선도 유지 |
| Kitchen Sink 세션 | 작업 범위를 좁혀 세션 분리 |

### 에이전트 오케스트레이션

| 문제 | 대안 |
|------|------|
| 모든 작업에 에이전트 팀 적용 | 일회성/통신 불필요 → Sub-agent. 팀은 2+ 에이전트 협업 시만 |
| 에이전트에 역할 없이 도구만 할당 | 역할, 원칙, I/O 프로토콜을 `.claude/agents/`에 명시 |
| 검증 없이 팀 배포 | 트리거 검증 + 드라이런으로 데이터 흐름 확인 후 적용 (`resources/08-agent-team-patterns.md`) |

## Examples

### 새 프로젝트 하네스 구축
User: "이 프로젝트에 하네스 구성해줘"
→ 워크플로우 1: 현재 감사 (대부분 0점)
→ 워크플로우 2: Phase 1(ARCHITECTURE.md) → Phase 2(CLAUDE.md+rules) → Phase 3(hooks) → Phase 4(docs/)

### 에이전트 오작동 진단
User: "에이전트가 자꾸 timezone을 잘못 처리해"
→ 워크플로우 5: rules에서 timezone-convention.md 확인
→ 진단: rule 있지만 예시 부족 → Rule 보강 + 린트 에러 메시지에 수정 지침 추가

### 문서 부패 감지
User: "하네스 점검해줘"
→ 워크플로우 1: 다차원 진단
→ 워크플로우 4: ARCHITECTURE.md에 새 패키지 3개 누락 발견, rules 2개 outdated → 갱신 PR

## Technical Details

- ARCHITECTURE.md 작성 가이드: `resources/04-architecture-guide.md`
- Doc Gardening 스킬 템플릿: `resources/05-doc-gardening-template.md`
- 상세 감사 체크리스트: `resources/01-audit-checklist.md`
- Context Engineering 전략 + CLAUDE.md 작성법 + Level 시스템: `resources/02-context-engineering.md`
- 참고 자료 (출처 + 핵심 인사이트): `resources/03-references.md`
- 아키텍처 테스트 도구 가이드 (언어별 매핑 + 감지 방법): `resources/06-arch-test-tools.md`
- 불변식 분류 체계 + 발견/우선순위: `resources/07-invariant-taxonomy.md`
- 에이전트 팀 패턴 + 정의 구조 + 검증: `resources/08-agent-team-patterns.md`
- Hook/Permission 구성: `update-config` skill 참조
- Skill 생성/갱신: `my-skill-creator` skill 참조
- CLAUDE.md 설계/구조: `claude-guide` skill 참조
