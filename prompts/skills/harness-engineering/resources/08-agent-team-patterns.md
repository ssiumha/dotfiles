# 에이전트 팀 패턴 (Agent Team Patterns)

Skill = "How to do" (절차 지식), Agent = "Who does" (전문가 페르소나).
에이전트는 `.claude/agents/{name}.md` 파일로 정의하며, 팀은 오케스트레이션 토폴로지로 구성한다.

## Skill과 Agent의 관계

| | Skill (`.claude/skills/`) | Agent (`.claude/agents/`) |
|--|--------------------------|--------------------------|
| 정체 | 절차 지식 ("How to do") | 전문가 페르소나 ("Who does") |
| 트리거 | 사용자 쿼리 매칭 → 워크플로우 실행 | 팀/서브에이전트에서 명시적 호출 |
| 내용 | 단계별 절차, 도구 사용법, 리소스 | 역할, 원칙, I/O 프로토콜 |
| 예시 | harness-engineering, doc-gardening | security-reviewer, test-writer |
| 관계 | Skill이 Agent를 오케스트레이션 | Agent가 Skill을 참조 가능 |

## 실행 모드 선택

| 기준 | Sub-agent (`Agent` tool) | Agent Team (실험적) |
|------|--------------------------|---------------------|
| 에이전트 수 | 1 (일회성) 또는 병렬 N개 | 2+ |
| 통신 | 결과만 반환 (부모에게) | **peer-to-peer** (Mailbox) + broadcast |
| 수명 | 작업 완료 후 종료 | 세션 내 지속, 자율 조율 |
| 컨텍스트 | 격리 (메인 보호) | 각자 독립 컨텍스트 윈도우 |
| 비용 | 낮음 (요약 반환) | 높음 (각 teammate = 별도 Claude 인스턴스) |
| 제어 | 메인이 전체 관리 | 공유 task list + self-claim |
| 예시 | 코드 탐색, 단발 분석, 병렬 리서치 | 경쟁 가설 디버깅, 크로스레이어 협업, PR 리뷰 팀 |

### 의사결정 트리

```
작업이 자기 완결적인가? (결과만 필요)
├─ Yes → Sub-agent
│   └─ 10+ 파일 탐색 또는 3+ 독립 조각? → 병렬 Sub-agent
└─ No → 에이전트 간 토론/피드백 필요?
    ├─ No → Sub-agent (병렬, 결과만 수집)
    └─ Yes → Agent Team
        └─ 주의: 실험적 기능, 토큰 비용 높음
```

**원칙**: 가장 싼 방법부터. Sub-agent로 충분하면 팀을 구성하지 않는다.

> Sub-agent의 컨텍스트 격리 패턴: `resources/02-context-engineering.md` 참조.
> 에이전트 frontmatter 스키마 상세: `resources/09-agent-template-schema.md` 참조.

## 에이전트 정의 구조

`.claude/agents/{name}.md` 파일. YAML frontmatter + Markdown 시스템 프롬프트.

> 전체 frontmatter 필드와 결정 트리: `resources/09-agent-template-schema.md` 참조.

```markdown
---
name: agent-name
description: "1-2문장 역할 설명 + 트리거 키워드"
tools: Read, Glob, Grep, Bash        # 선택: 생략 시 부모 전체 상속
model: sonnet                         # 선택: opus, haiku, inherit
permissionMode: default               # 선택: 6가지 모드
maxTurns: 30                          # 선택: 무한루프 방지
memory: project                       # 선택: user, project, local
---

# Agent Name — 한 줄 역할 요약

You are a [도메인] [역할] specialist.

## Core Responsibilities
1. 핵심 책임 1
2. 핵심 책임 2

## Working Principles
- 원칙 1 (Why 포함)
- 원칙 2

## I/O Protocol
- Input: [어디서 무엇을 받는가]
- Output: [어디에 무엇을 쓰는가]
- Format: [파일 형식, 구조]

## Error Handling
- [실패 시 행동]
- [타임아웃 시 행동]

## Team Communication (Agent Team 모드 시)
- 수신: [누구로부터 어떤 메시지]
- 발신: [누구에게 어떤 메시지]
- 태스크: [공유 목록에서 요청하는 작업 유형]
```

### 필수 섹션 vs 선택 섹션

| 섹션 | Sub-agent | Agent Team |
|------|-----------|------------|
| Responsibilities | 필수 | 필수 |
| Principles | 필수 | 필수 |
| I/O Protocol | 필수 | 필수 |
| Error Handling | 권장 | 필수 |
| Team Communication | — | 필수 |

> Tool/Permission 제약은 frontmatter에서 선언적으로 처리. 시스템 프롬프트에 중복 기술 불필요.

## 7개 팀 토폴로지

### 1. Pipeline (순차 종속)

```
[분석] → [설계] → [구현] → [검증]
```

- **적합**: 단계별 변환, 각 단계가 이전 출력에 강하게 의존
- **주의**: 병목 = 가장 느린 단계. 단계를 최대한 독립적으로 설계
- **팀 모드**: 순차 의존이 강하면 Sub-agent도 가능. 파이프라인 내 병렬 구간이 있으면 팀 모드

### 2. Fan-out / Fan-in (병렬 독립 후 통합)

```
           ┌→ [Expert A] ─┐
[분배기] ──┼→ [Expert B] ─┼→ [통합기]
           └→ [Expert C] ─┘
```

- **적합**: 동일 입력에 대해 서로 다른 관점/도메인의 분석이 필요
- **주의**: 통합 단계의 품질이 전체 품질을 결정. 산출물 형식 통일 필수
- **팀 모드**: 가장 자연스러운 팀 패턴. 실시간 발견 공유와 교차 검증이 품질을 높임

### 3. Expert Pool (컨텍스트별 전문가 선택)

```
[라우터] → { Expert A | Expert B | Expert C }
```

- **적합**: 입력 유형에 따라 다른 전문가가 필요 (코드 리뷰: 보안/성능/아키텍처)
- **주의**: 라우팅 기준을 명확히 정의. 라우터 분류 정확도가 전체 품질 좌우
- **팀 모드**: 필요한 전문가만 호출하므로 Sub-agent가 더 적합

### 4. Producer-Reviewer (생성-검증)

```
[Producer] ↔ [Reviewer] (반복)
```

- **적합**: 코드 생성+리뷰, 문서 작성+검토 등 품질 보증이 핵심
- **주의**: 무한 루프 방지 — 최대 반복 횟수 제한 (2-3회)
- **팀 모드**: `SendMessage`로 실시간 피드백 교환. 재작업 최소화

**변형: GAN-style (Generator-Evaluator)**

```
[Planner] → [Generator] ↔ [Evaluator] (5-15 반복)
```

- Anthropic 연구(2026.03)에서 검증: 자기 평가 편향(self-evaluation bias) 때문에 **생성자와 평가자를 분리**하는 게 훨씬 효과적
- "독립적 평가자를 회의적으로 튜닝하는 것이 생성자를 자기비판적으로 만드는 것보다 쉽다"
- Planner → 상세 스펙 생성, Generator → 반복 구현, Evaluator → 실제 앱 테스트(Playwright 등)
- 비용 높음 (단독 $9/20분 vs GAN $200/6시간) — 모델 능력 경계 작업에서만 투자 가치
- **모델이 좋아져도 하네스 복잡성은 줄지 않고 이동한다** — 평가자는 난이도 경계에서 필수, 단순 작업에선 과잉
- **Opus 4.6 이후 변화**: 스프린트 분해 구조를 완전 제거해도 2시간+ 일관 작업 가능. Planner+Evaluator는 유지하되, 스프린트별 평가→최종 평가로 전환. 즉 **스캐폴딩은 줄이고 검증은 유지**
- **병목 이동**: 코드 생성 능력이 향상되면서 병목이 생성→**검증(Verification)**으로 이동. Evaluator의 중요성은 모델 능력과 비례하여 증가

### 5. Supervisor (중앙 동적 분배)

```
              ┌→ [Worker A]
[Supervisor] ─┼→ [Worker B]
              └→ [Worker C]
```

- **적합**: 동적 작업 분배, 진행 상황에 따른 우선순위 조정
- **Fan-out과 차이**: Fan-out은 사전 고정 할당, Supervisor는 런타임 동적 조정
- **주의**: Supervisor가 병목이 되지 않도록 충분히 큰 작업 단위 할당
- **팀 모드**: 공유 태스크 목록이 자연스럽게 Supervisor 패턴과 매칭

### 6. Hierarchical Delegation (재귀적 위임)

```
[Coordinator] → [Team Lead A] → [Specialist A1, A2]
              → [Team Lead B] → [Specialist B1, B2]
```

- **적합**: 대규모 작업의 계층적 분해 (풀스택 앱: FE Lead + BE Lead)
- **주의**: 깊이 2레벨까지만. Agent Teams는 중첩 금지 → 1레벨은 팀, 2레벨은 Sub-agent
- **팀 모드**: 팀 재구성 패턴 활용 — 이전 팀 산출물을 `_workspace/`에 저장 후 새 팀 구성

### 7. Advisor (조언자-실행자)

```
[Advisor (Opus)] ──advice──→ [Executor (Sonnet)]
                 ←─result───
```

- **적합**: 판단은 고성능이 필요하지만, 실행은 빠르고 저렴해야 하는 작업
- **구조**: Advisor가 전략/방향/리뷰를 제공, Executor가 실제 구현/탐색을 수행
- **비용**: Opus 단독 대비 **85% 비용 절감**, 성능은 2배+ (Anthropic 공식 패턴, 2026)
- **주의**: Advisor는 짧은 판단만 제공 (컨텍스트 효율). Executor가 막히면 Advisor에 재질의
- **팀 모드**: Sub-agent가 더 적합. Executor를 Sonnet Sub-agent로, Advisor 역할은 메인(Opus)이 수행

**실전 변형**:
- 메인 세션(Opus)이 자연스럽게 Advisor 역할 → Sonnet Sub-agent들이 Executor
- `CLAUDE_CODE_SUBAGENT_MODEL=sonnet`으로 기본 설정하면 자동으로 Advisor 패턴

### 하이브리드 패턴

실제 시나리오는 패턴을 조합한다:

| 조합 | 구조 | 예시 |
|------|------|------|
| Fan-out + Producer-Reviewer | 병렬 생성 → 각각 검증 | 다국어 번역 병렬 → 네이티브 검토 |
| Pipeline + Fan-out | 순차 내 병렬 구간 | 분석(순차) → 구현(병렬) → 통합 테스트(순차) |
| Supervisor + Expert Pool | 감독자가 전문가 동적 호출 | 고객 지원: 분류 → 적합한 전문가 할당 |

## 오케스트레이션 절차

### Agent Team (5단계)

1. **준비** — `_workspace/` 생성, 입력 자료 배치 (`_workspace/00_input/`)
2. **팀 구성** — `TeamCreate`로 에이전트 등록, `TaskCreate`로 작업 등록 (`depends_on`으로 의존성)
3. **작업** — 팀원 자율 조율 (`SendMessage`), 리더가 `TaskGet`으로 모니터링
4. **후속** — 산출물 수집 (`Read`), 통합/검증 로직 실행
5. **정리** — `_workspace/` 산출물 최종 위치로 이동, `TeamDelete`

### Sub-agent (4단계)

1. **준비** — 프롬프트 + 도구 제한 정의
2. **작업** — `Agent` tool로 실행 (병렬: `run_in_background`)
3. **후속** — 결과 수신 (`filepath:line` 형태)
4. **정리** — 메인 컨텍스트에 필요한 결과만 통합

### 산출물 관리 규칙

- 파일 컨벤션: `_workspace/{phase}_{agent}_{artifact}.{ext}`
- 이전 팀 산출물은 `_workspace/`에 보존 (감사 추적)
- 최종 산출물만 프로젝트 디렉토리로 이동

## Agent Teams (실험적)

> `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` 필요. v2.1.32+.

Sub-agent와 달리 **별도 Claude 세션**으로 실행. peer-to-peer 통신, 공유 task list, 자율 조율.

### 아키텍처

| 컴포넌트 | 역할 |
|----------|------|
| **Team Lead** | 메인 세션. 팀 생성, teammate 스폰, 작업 조율 |
| **Teammate** | 독립 Claude 인스턴스. task claim + 자율 실행 |
| **Task List** | 공유 작업 목록. pending → in_progress → completed. 파일 락으로 경쟁 방지 |
| **Mailbox** | message(1:1) + broadcast(1:N) |

### 품질 게이트 Hook

| Hook | 시점 | exit 2 효과 |
|------|------|-------------|
| `TeammateIdle` | teammate가 idle 상태 진입 | 피드백 전송하여 추가 작업 유도 |
| `TaskCreated` | task 생성 시 | task 생성 차단 |
| `TaskCompleted` | task 완료 마킹 시 | 완료 거부 (품질 미달) |

### Teammate와 Subagent 정의 재사용

서브에이전트 정의(`.claude/agents/`)를 teammate로 재사용 가능:
```
Spawn a teammate using the security-reviewer agent type
```

**제한**: `skills`, `mcpServers` 필드는 teammate 모드에서 무시됨. `tools`, `model`은 적용.

### 제한 사항

- 세션 재개 불가 (in-process teammates)
- 중첩 팀 불가 (팀 안에 팀 X)
- 리더 고정 (런타임 변경 불가)
- 한 세션 = 한 팀
- split pane은 tmux/iTerm2 필요

## 검증 방법론

### 트리거 검증

에이전트/스킬의 description이 올바른 상황에서만 활성화되는지 확인:

| 유형 | 목적 | 방법 |
|------|------|------|
| should-trigger | 의도한 쿼리에서 활성화 | 5-10개 예상 쿼리로 테스트 |
| should-NOT-trigger | 의도하지 않은 쿼리에서 비활성화 | 5-10개 유사하지만 다른 쿼리로 테스트 |

### 드라이런

실제 실행 전 데이터 흐름 연결성 확인:

1. 각 에이전트의 입력이 이전 단계의 출력과 연결되는가?
2. `_workspace/` 파일 경로가 일관되는가?
3. 최종 산출물이 기대 위치에 생성되는가?
4. 에러 경로에서 적절한 fallback이 있는가?

## 안티패턴

| 문제 | 대안 |
|------|------|
| Sub-agent로 충분한 작업에 팀 구성 | 실행 모드 선택 기준 참조. 통신 불필요 → Sub-agent |
| 에이전트에 "모든 것"을 할 수 있게 정의 | 역할을 좁게, 도구를 제한적으로 |
| I/O 프로토콜 없이 "알아서 소통" | 입력/출력 파일 경로와 형식을 명시 |
| `_workspace/` 없이 산출물 흩어짐 | `_workspace/`를 산출물 중앙 저장소로 |
| 검증 없이 배포 | 트리거 검증 + 드라이런 필수 |
| 깊이 3+ 계층 | 2레벨까지. 1레벨=팀, 2레벨=Sub-agent |
| 모든 에이전트에 같은 프롬프트 | 각 에이전트에 전문화된 역할과 원칙 부여 |
