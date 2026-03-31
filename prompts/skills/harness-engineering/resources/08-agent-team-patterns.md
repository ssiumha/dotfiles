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

| 기준 | Sub-agent (`Agent` tool) | Agent Team (`TeamCreate` + `SendMessage`) |
|------|--------------------------|-------------------------------------------|
| 에이전트 수 | 1 (일회성) | 2+ |
| 통신 | 불필요 (결과만 반환) | 상호 통신 필요 |
| 수명 | 작업 완료 후 종료 | 세션 내 지속 |
| 컨텍스트 | 격리 (메인 보호) | 공유 `_workspace/` |
| 예시 | 코드 탐색, 문서 검색, 단발 분석 | 코드 리뷰+테스트, 설계+구현, 분석+보고서 |

### 의사결정 트리

```
2+ 에이전트 필요?
├─ No → Sub-agent
└─ Yes → 에이전트 간 통신 필요?
    ├─ No → Sub-agent (병렬 실행, 결과만 수집)
    └─ Yes → Agent Team
```

**원칙**: 2+ 에이전트 협업이 필요하면 Agent Team이 기본값. Sub-agent 선택 시 "에이전트 간 통신이 정말 불필요한가?" 자문.

> Sub-agent의 컨텍스트 격리 패턴: `resources/02-context-engineering.md` 참조.

## 에이전트 정의 구조

`.claude/agents/{name}.md` 파일:

```markdown
---
name: agent-name
description: "1-2문장 역할 설명 + 트리거 키워드"
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

## Tool Constraints
- 허용: [사용 가능 도구 목록]
- 금지: [사용 불가 도구 목록]

## Error Handling
- [실패 시 행동]
- [타임아웃 시 행동]

## Team Communication (팀 모드 시)
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
| Tool Constraints | 권장 | 필수 |
| Error Handling | 권장 | 필수 |
| Team Communication | — | 필수 |

## 6개 팀 토폴로지

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
