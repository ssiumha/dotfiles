---
name: strategic-thinking
description: "체계적 의사결정 프레임워크. First Principles, Trade-off 분석, Cognitive Bias 점검"
user-invocable: true
tags: [decision, architecture, trade-off, first-principles, bias]
triggers:
  keywords: [아키텍처 결정, 기술 선택, trade-off, 전략적 판단, 의사결정, 대안 비교, 근본 원인]
---

# Strategic Thinking

복잡한 의사결정을 위한 5단계 구조적 사고 프레임워크.

## When to Use

- 아키텍처 결정 (5+ 파일 영향)
- 기술/라이브러리/프레임워크 선택
- Performance vs Maintainability 트레이드오프
- 리팩토링 범위 결정, Breaking change 검토

단순 버그 수정이나 1-2 파일 변경에는 사용하지 않는다.

## 5-Phase Framework

### Phase 1: Assumption Audit (15%)

숨겨진 가정을 표면화한다.

5가지 질문:
1. 증거 없이 참이라고 가정하는 것은?
2. 이 가정이 틀리면 어떻게 되는가?
3. 이것은 hard constraint인가, 단순 선호인가?
4. 이 가정을 뒷받침하는 근거는?
5. 누가 이 가정을 검증해야 하는가?

가정 분류: Technical(기술 능력/성능/호환성) | Business(사용자/시장/예산) | Team(기술 수준/가용성) | Timeline(납기/의존성)

각 가정에 **confidence**(H/M/L), **risk if wrong**, **validation method** 기록.

### Phase 2: First Principles Decomposition (25%)

복잡성을 관통해 근본 원인을 찾는다.

**Five Whys**: 표면 문제 → 직접 원인 → 근저 원인 → 프로세스 요인 → 근본 원인

**Constraint 분류**:
- Hard: 비협상 (보안, 컴플라이언스, 물리적 한계)
- Soft: 협상 가능 (일정, 기능 범위, 도구)
- Self-imposed: 요구사항으로 위장한 가정

핵심 질문: 이 요청 뒤의 실제 목표는? / 제약이 없다면 해결책은? / 제거할 수 있는 것은?

### Phase 3: Alternative Generation (20%)

조기 수렴을 방지한다.

규칙:
- **최소 3개** 대안 필수
- 비관습적 옵션 1개 이상 포함
- "do nothing"을 baseline으로 포함

대안 유형: Conservative(낮은 리스크, 점진적) | Balanced(중간, 유의미한 개선) | Aggressive(높은 리스크, 혁신적) | Radical(근본 가정에 도전)

창의 기법:
- **Inversion**: 문제를 악화시키는 방법 → 반대로
- **Analogy**: 다른 도메인의 유사 해결법
- **Simplification**: 가장 단순한 해결책

### Phase 4: Trade-off Analysis (25%)

암묵적 트레이드오프를 명시적으로 만든다.

평가 기준 (프로젝트 우선순위에 따라 가중치 배분, 합계 100%):
- Performance: 속도, 처리량, 레이턴시
- Maintainability: 코드 명확성, 팀 친숙도
- Cost: 개발 시간, 복잡도, 학습 곡선
- Risk: 기술 리스크, 롤백 난이도
- Scalability: 성장 수용력, 유연성
- Security: 취약점 표면, 컴플라이언스

**가중 점수법**: 각 옵션을 기준별 1-10 점수 → 가중 합산 → 민감도 확인

문서화: **what we gain** / **what we sacrifice** / **why acceptable** / **mitigation plan**

### Phase 5: Cognitive Bias Check (15%)

사고 품질을 검증한다.

5대 편향:
1. **Anchoring**: 처음 접한 정보에 과도하게 의존
2. **Confirmation**: 기존 믿음을 뒷받침하는 증거만 탐색
3. **Sunk Cost**: 과거 투자 때문에 계속 진행
4. **Availability**: 최근/기억에 남는 사건에 과도한 가중치
5. **Overconfidence**: 자기 판단에 대한 과도한 확신

탐지 질문:
- 내가 처음 생각해서 집착하는 건 아닌가?
- 반대 증거를 적극적으로 찾았는가?
- 과거 투자가 없었어도 이것을 추천하겠는가?
- 무엇이 바뀌면 내 추천을 바꾸겠는가?

완화: **Pre-mortem**(실패 상상) | **Devil's advocate**(자기 반대 논증) | **Outside view**(기저율 확인)

## Quick Decision Matrix

| 상황 | 적용 Phase |
|------|-----------|
| 단순 버그 수정 | 스킵 |
| 기능 추가 | 1, 3, 4 |
| 리팩토링 | 1, 2, 4 |
| 기술 선택 | 전체 |
| 아키텍처 변경 | 전체 + 확장 문서화 |

## Deep Questioning (보충)

복잡한 요구사항 분석 시 6계층 점진적 탐구:
1. **Surface**: 무엇을 원하는가?
2. **Structure**: 어떤 구조/제약이 있는가?
3. **Relationship**: 다른 시스템/결정과 어떻게 연결되는가?
4. **Assumption**: 어떤 전제를 깔고 있는가?
5. **Alternative**: 다른 접근법은?
6. **Validation/Risk**: 어떻게 검증하고, 리스크는?

## See Also

- `/design-first` — 구현 전 점진적 설계 합의
- `/tdd` — 새 기능의 테스트 주도 개발
- `/safe-refactoring` — 기존 코드의 안전한 리팩토링

> Origin: moai-adk foundation-philosopher + foundation-thinking 통합
