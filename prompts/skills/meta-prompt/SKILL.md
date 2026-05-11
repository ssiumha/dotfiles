---
name: meta-prompt
description: 신호(기사/관찰/아이디어/문제)를 글로벌 하네스(~/.claude/ 전체)로 흡수. 추출→대조→Gap→적용→흡수율 측정. Use when 외부 기사 참조, "이게 문제야", "이걸 개선하자", "이 패턴을 반영해", 하네스 메타 개선, 스킬 진화, 글로벌 룰 개선. Do NOT use for 프로젝트 레벨 하네스 (use harness-engineering).
argument-hint: "[URL or topic]"
user-invocable: true
---

# Meta-Prompt — 글로벌 하네스 진화 루프

신호를 받아 글로벌 도구 인프라를 진화시키는 메타 프로세스.

> "프로젝트 하네스를 강화하는 것은 harness-engineering. 
> 그 harness-engineering 자체를 포함한 모든 도구를 진화시키는 것이 meta-prompt."

핵심 루프:
```
신호 → 추출 → 대조 → Gap → 적용 → 흡수율 측정
```

## 범위

| | harness-engineering | meta-prompt |
|---|---|---|
| **대상** | 현재 저장소 (.claude/, CLAUDE.md) | ~/.claude/ 전체 (skills, global rules, hooks, memory, settings) |
| **트리거** | "이 프로젝트 하네스 점검해" | "이 기사 봐" / "이게 문제야" / "이걸 개선하자" |
| **결과** | 프로젝트 레벨 개선 | 글로벌 도구 인프라 진화 |

## Instructions

### 복원 (Compaction / 세션 재개 시)

`.claude/meta-prompt/` 디렉토리를 확인한다:
1. `{signal-slug}/` 디렉토리가 있으면 진행 중인 흡수 작업으로 판단
2. 가장 최근 디렉토리의 Phase 파일을 Read하여 진행 상태 복원
3. 다음 미완료 Phase부터 재개

---

### Phase 0: 신호 분류 (Signal Triage) — REQUIRED

#### 0-A. 신호 유형 판별

| 유형 | 트리거 패턴 | 조사 방법 |
|------|------------|-----------|
| 외부 레퍼런스 | URL 포함, "이거 봐", "이 기사" | WebFetch → 인사이트 추출 |
| 사용자 관찰 | "문제가 생겼다", "이게 안 돼", "이래서 문제야" | /recall + 현행 탐색 |
| 사용자 아이디어 | "이걸 개선하자", "~하면 어떨까", "~를 만들자" | 관련 스킬/룰 탐색 |
| 에이전트 오작동 | "Claude가 자꾸 ~해", F1-F6 패턴 | harness-engineering Diagnose 참조 |

#### 0-B. 영향 범위 판단

| 범위 | 기준 | 조사 깊이 |
|------|------|-----------|
| 단일 스킬 | 특정 스킬 1개 개선 | 해당 스킬 SKILL.md만 |
| 다중 스킬 | 패턴이 여러 스킬에 적용 | 관련 스킬 전수 스캔 |
| 글로벌 인프라 | rules/hooks/settings 변경 | settings.json + rules/ 전체 |
| 메타 구조 | 스킬 설계 패턴 자체 변경 | 전 스킬 구조 대조 |

#### 0-C. 게이트 리뷰

AskUserQuestion으로 분류 결과를 확인한다:

```
신호 유형: {유형}
영향 범위: {범위}
조사 대상: {구체적 스킬/룰/훅 목록}

이 방향으로 진행할까요?
```

Red Flags:
- 신호가 모호하여 유형 판별 불가 → 사용자에게 구체화 요청
- 영향 범위가 "메타 구조"인데 신호가 약함 → 과잉 대응 경고

---

### Phase 1: 추출 (Extract) — REQUIRED

신호에서 **actionable 인사이트**를 추출하고 구조화한다.

#### 1-A. 신호 소화

| 신호 유형 | 소화 방법 |
|-----------|-----------|
| 외부 레퍼런스 | WebFetch → 전문 읽기 → 핵심 주장/방법론/체크리스트 추출 |
| 사용자 관찰 | /recall로 관련 세션 검색 → 패턴 식별 |
| 사용자 아이디어 | 관련 기존 구현 탐색 (Glob, Grep) → 현행 대비 차이 식별 |
| 에이전트 오작동 | resilience-catalog (F1-F6) 대조 → 해당 실패 모드 식별 |

#### 1-B. 인사이트 구조화

각 인사이트를 아래 형태로 정리:

```markdown
| # | 인사이트 | 유형 | 적용 가능성 |
|---|----------|------|------------|
| 1 | {구체적 설명} | 패턴/안티패턴/도구/원칙 | 높음/중간/낮음 |
| 2 | ... | ... | ... |
```

유형 분류:
- **패턴**: 따라야 할 구조/프로세스
- **안티패턴**: 피해야 할 것
- **도구**: 새 도구/기법/훅
- **원칙**: 상위 가이드라인

Red Flags:
- 인사이트 0개 → "신호에서 actionable 내용을 찾지 못했습니다" — 조기 종료
- 인사이트 10개+ → 우선순위 매기고 상위 5개만 이번 세션에서 처리 제안

---

### Phase 2: 대조 (Compare) — REQUIRED

Phase 1 인사이트를 현재 글로벌 하네스와 1:1 매핑한다.

#### 2-A. 현행 탐색

Explore Agent로 탐색:

```
- ~/dots/prompts/skills/*/SKILL.md — 스킬 목록 + 구조
- ~/dots/prompts/rules/*.md — 글로벌 룰
- ~/.claude/CLAUDE.md — 글로벌 instructions
- ~/.claude/settings.json — hooks, permissions
- ~/.claude/projects/*/memory/MEMORY.md — 메모리 인덱스
```

#### 2-B. 매핑 테이블

| # | 인사이트 | 현재 상태 | 커버 | 위치 |
|---|----------|-----------|------|------|
| 1 | {인사이트} | {구체적 현행} | COVERED / PARTIAL / MISSING | {파일 경로} |
| 2 | ... | ... | ... | ... |

**기존 커버율** = COVERED 수 / 전체 인사이트 수 × 100%

---

### Phase 3: Gap + 적용 (Apply) — REQUIRED

#### 3-A. 적용 계획

PARTIAL/MISSING 항목에 대해:

```markdown
| # | Gap | 적용 대상 | 적용 방식 | 규모 |
|---|-----|-----------|-----------|------|
| 1 | {Gap 설명} | {스킬/룰/훅} | 수정/신규 | S/M/L |
```

#### 3-B. 게이트 리뷰

AskUserQuestion으로 적용 계획을 승인받는다:

```
## 적용 계획
{테이블}

전체: N건 (S:x, M:y, L:z)

1. 전체 적용
2. 선택 적용 (번호 지정)
3. 여기서 종료 (Gap만 기록)
```

#### 3-C. 실행

승인된 항목을 적용한다. 적용 시 기존 도구 활용:
- 스킬 수정 → 직접 Edit
- 스킬 신규 → my-skill-creator 참조
- 훅/설정 → update-config 스킬 위임
- 프로젝트 하네스 → harness-engineering 위임

---

### Phase 4: 측정 (Measure) — REQUIRED

흡수 보고서를 출력한다:

```markdown
## 흡수 보고서

### 신호
- 유형: {외부 레퍼런스 / 관찰 / 아이디어 / 오작동}
- 소스: {URL / 사용자 발언 요약}

### 정량 지표
| 지표 | 값 |
|------|-----|
| 추출 인사이트 | N개 |
| 기존 커버 | X개 ({X/N}%) |
| 적용 가능 | Y개 |
| 실제 적용 | Z개 |
| **흡수율** | **{Z/Y}%** |

### 변경 파일
- {파일}: {변경 요약}

### 미적용 (Backlog)
- {인사이트}: {사유}
```

---

## 연동

```
meta-prompt (글로벌 하네스 진화)  ← 이 스킬
  ├── harness-engineering (프로젝트 하네스 — 위임)
  ├── my-skill-creator (스킬 신규 생성 — 위임)
  ├── update-config (hooks/settings 변경 — 위임)
  └── recall (이전 세션/지식 참조)
```

| Skill | 관계 | 설명 |
|-------|------|------|
| `harness-engineering` | 하위 도구 | 프로젝트 레벨 하네스 변경은 위임 |
| `my-skill-creator` | 하위 도구 | 스킬 신규 생성 시 위임 |
| `update-config` | 하위 도구 | hooks/settings 변경 시 위임 |
| `recall` | 탐색 | 이전 세션/관찰 패턴 검색 |
| `design-first` | 대상 | 개선 대상이 될 수 있는 스킬 |

## Examples

### Example 1: 외부 기사 흡수

```
User: https://news.hada.io/topic?id=28538 이거 읽고 반영해
```

Phase 0: 외부 레퍼런스 / 다중 스킬 영향
Phase 1: 6가지 실패 모드 + 워크플로우 패턴 추출 (인사이트 8개)
Phase 2: 4개 MISSING, 2개 PARTIAL, 2개 COVERED (커버율 25%)
Phase 3: resilience-catalog 신규 + SKILL.md 5곳 수정 (적용 6건)
Phase 4: 흡수율 6/6 = 100%

### Example 2: 사용자 관찰

```
User: 견적내자를 자주 쓰는데 스킬로 정리하고 싶어
```

Phase 0: 사용자 아이디어 / 단일 스킬 영향
Phase 1: /recall → 세션 6건에서 견적 패턴 추출 (인사이트 4개)
Phase 2: design-first에 견적 Phase 없음 (커버율 0%)
Phase 3: Phase 0 견적 통합 + Examples 갱신 (적용 2건)
Phase 4: 흡수율 2/2 = 100%

### Example 3: 에이전트 오작동

```
User: Claude가 자꾸 테스트를 마음대로 고쳐
```

Phase 0: 에이전트 오작동 (F4) / 글로벌 인프라 영향
Phase 1: F4 테스트 임의 수정 패턴 확인 (인사이트 3개)
Phase 2: test 파일 보호 Hook 없음, Rule 없음 (커버율 0%)
Phase 3: PreEdit test nudge hook + anti-patterns rule (적용 2건)
Phase 4: 흡수율 2/3 = 67% (1건은 프로젝트별 커스텀 필요 → backlog)
