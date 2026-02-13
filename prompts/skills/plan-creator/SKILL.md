---
name: plan-creator
description: Creates dependency-based task execution plans with parallel orchestration. Use when planning complex tasks, breaking down work into steps, 계획 수립, 3+ tasks with dependencies, unclear execution order, or parallel work identification needed.
---

# Plan Creator

의존성 그래프 기반 실행 계획 수립. **계획만 생성**하고 실행은 사용자 또는 다른 도구에 위임.

## Quick Reference

```
/plan-creator [작업 설명]    # 계획 수립 (WHY → PLAN → 완료)
/plan-creator --visualize   # 기존 계획 다이어그램 재생성
```

## 핵심 철학

1. **Why First**: Task 분해 전 목표/완료조건 명확화
2. **의존성 명시**: blockedBy로 실행 순서 자동 결정
3. **병렬 그룹 식별**: 동시 실행 가능한 task 그룹화
4. **Planning Only**: 계획 수립에 집중, 실행은 위임

## Instructions

### Phase 1: WHY (요구사항 명확화)

**목표**: Task 분해 전 성공 기준 확정

1. **복잡도 판단**
   - 단순 (3줄 이하, 명확): 필수 질문 2개만
   - 복잡 (3줄+, 모호함): 도메인별 질문 활용

2. **필수 수집 항목**
   - **목표**: 이 작업으로 달성하려는 것
   - **완료 조건**: "이게 되면 성공" (측정 가능하게)

3. **선택 수집 항목** (복잡한 경우만)
   - 우선순위, 제약 조건
   - 도메인별 상세 질문: `resources/questions/{domain}.md`

4. **✓ WHY 검증** (Phase 전환 전 필수)
   - [ ] 목표가 구체적인가? (모호한 표현 없음)
   - [ ] 완료 조건이 측정 가능한가? ("테스트 통과" ✅, "잘 동작" ❌)
   - [ ] 범위가 명확한가? (포함/제외 구분)

   **통과 시**: Phase 2로 전환
   **실패 시**: 추가 질문으로 명확화

### Phase 2: PLAN (작업 분해 + 실행 계획)

**목표**: 목표 달성을 위한 task 분해 및 의존성 분석

1. **Task 도출**
   - 완료 조건에서 역산
   - 각 task는 독립적으로 검증 가능
   - 이름은 동사로 시작

2. **Skill 매핑** (system-reminder의 available skills 참조)
   - 각 task에 적용할 skill을 탐색하여 `skills:` 필드에 기록
   - system-reminder에 로드된 skill 목록에서 description 기반으로 매칭
   - 매칭 skill이 없으면 생략 (빈 배열)
   - 실행 시 `/skill-name`으로 호출하는 가이드 역할

3. **각 Task 작성 시 ✓ Task 검증** (매 task마다)
   - [ ] `why`: 이 task가 필요한 이유
   - [ ] `verify`: 완료 확인 방법 (측정 가능하게)
   - [ ] `blockedBy`: 논리적인가? (실제 선행 필요한 task만)
   - [ ] `skills`: 매칭 skill이 적절한가?
   - [ ] `risk`: 적절한가?
   - [ ] `docs`: 문서 갱신 필요 여부 (선택)

   **통과 시**: 다음 task 작성
   **실패 시**: 해당 task 수정

3. **병렬 그룹 계산**
   - blockedBy 없는 task들 → Group 1 (동시 시작)
   - Group 1 task에만 의존하는 task들 → Group 2
   - 반복하여 모든 task 그룹화
   - **크리티컬 패스**: 가장 긴 의존 체인
   - **커밋 포인트**: 각 그룹 완료 + 검증 후 커밋

4. **✓ PLAN 전체 검증** (출력물 생성 전 필수)
   - [ ] 모든 task에 `why`가 있는가?
   - [ ] 순환 의존성이 없는가? (A→B→C→A ❌)
   - [ ] 완료 조건의 모든 항목이 task로 커버되는가?
   - [ ] 병렬 그룹이 논리적인가?
   - [ ] 크리티컬 패스가 식별되었는가?

   **통과 시**: 출력물 생성
   **실패 시**: task 수정/추가

5. **출력물 생성**
   - `plans/{name}.yaml`: Task 정의
   - `plans/{name}.md`: 다이어그램 + 설명

### 완료: GUIDANCE (실행 안내)

계획 수립 후 제공하는 정보:

```
📋 계획 완료: {name}
📄 저장됨: plans/{name}.yaml

실행 플로우:
  Group 1: [task-1, task-3] → ✓ 검증 → 커밋
  Group 2: [task-2] → /tdd-practices → /review-security → ✓ 검증 → 커밋
  Group 3: [task-4] → /lint-audit → ✓ 검증 → 커밋 (최종)

크리티컬 패스: task-1 → task-2 → task-4
⚠️ 리스크: task-2 (medium)
```

## 중요 원칙

1. **Why 없는 Task 금지**: 모든 task에 이유 필수
2. **순환 의존성 금지**: A→B→C→A 불가
3. **측정 가능한 완료 조건**: "잘 동작함" ❌ → "테스트 통과" ✅
4. **계획과 실행 분리**: 아래 책임 범위 참조

## 책임 범위

**✅ plan-creator 담당**:
- WHY 수집 (목표, 완료 조건)
- Task 분해 및 의존성 분석
- 검증 항목 제시 (체크리스트)
- PLAN 문서 생성 (.yaml/.md)

**❌ 실행은 사용자/다른 도구**:
- Task 실행
- 검증 수행 (사용자 확인)
- 커밋 실행
- 문서 갱신

## 파일 위치

```
plans/
├── {name}.yaml     # Task 정의 (blockedBy, why, risk)
└── {name}.md       # Mermaid 다이어그램 + 설명
```

## Examples

### 단순 요청

```
User: /plan-creator REST API 만들기

=== WHY ===
확인이 필요합니다:
1. 목표가 무엇인가요?
2. 완료 조건은?

User: 할일 CRUD API, 테스트 통과하면 완료

=== PLAN ===
tasks:
  - id: schema
    title: "DB 스키마 설계"
    why: "데이터 구조 정의 필요"
    skills: []
    risk: low

  - id: api
    title: "API 라우트 구현"
    why: "CRUD 기능 핵심"
    blockedBy: [schema]
    skills: [review-security]
    risk: medium

  - id: test
    title: "테스트 작성"
    why: "완료 조건 충족"
    blockedBy: [api]
    skills: [tdd-practices]
    risk: low

=== GUIDANCE ===
📋 계획 완료: todo-api
실행 플로우:
  Group 1: [schema] → ✓ 검증 → 커밋
  Group 2: [api] → /review-security → ✓ 검증 → 커밋
  Group 3: [test] → /tdd-practices → ✓ 검증 → 커밋 (최종)
크리티컬 패스: schema → api → test
```

### 병렬 작업 식별

```
User: /plan-creator 마이크로서비스 분리

=== PLAN ===
tasks:
  - id: define-boundaries
    title: "서비스 경계 정의"
    skills: [ddd-design-docs]
    blockedBy: []

  - id: setup-user-service
    title: "User 서비스 설정"
    blockedBy: [define-boundaries]
    skills: [devops-docker]

  - id: setup-order-service
    title: "Order 서비스 설정"
    blockedBy: [define-boundaries]
    skills: [devops-docker]

  - id: setup-gateway
    title: "API Gateway 설정"
    blockedBy: [setup-user-service, setup-order-service]
    skills: [review-security]

=== GUIDANCE ===
실행 플로우:
  Group 1: [define-boundaries] → /ddd-design-docs → ✓ 검증 → 커밋
  Group 2: [setup-user-service, setup-order-service] → /devops-docker → ✓ 검증 → 커밋 (동시 가능!)
  Group 3: [setup-gateway] → /review-security → ✓ 검증 → 커밋 (최종)
```

## Technical Details

상세 리소스:
- `resources/verification-flow.md`: 검증 플로우 상세 예시
- `resources/questions/`: 도메인별 질문 템플릿
- `templates/plan.yaml`: YAML 템플릿
- `templates/plan.md`: Markdown 템플릿
