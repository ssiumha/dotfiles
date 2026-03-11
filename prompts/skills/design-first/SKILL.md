---
name: design-first
description: 구현 전 점진적 설계 합의 (범위→구조→상호작용→계약→구현). Use when scope is unclear for multi-component work, new feature domain with undefined boundaries, or system integration requiring architectural decisions. 설계 먼저, 구조 설계, 범위 정의. Do NOT use for single-component changes, scope-clear tasks, or when a plan already exists (use plan-review instead). Skip for simple utilities — just code directly.
argument-hint: "[design topic]"
user-invocable: true
---

# Design First

구현 전 점진적 설계 합의. 한 번에 한 차원만 논의하고, 승인 후 다음 Phase로 진행.

> "The purpose of software design is to manage complexity" — John Ousterhout

핵심 철학:
- **Whiteboard before Keyboard**: 코드 생성 전 설계 합의
- **한 번에 한 차원만**: 범위·아키텍처·통신·계약을 동시에 평가하지 않음
- **게이트 리뷰**: 각 Phase 사용자 승인 후 다음 진행
- **복잡도 캘리브레이션**: 모든 작업이 5단계를 다 거칠 필요 없음

## Instructions

### 복원 (Compaction / 세션 재개 시)

`.claude/designs/{feature}/` 디렉토리를 확인한다:
1. `phase-N-*.md` 파일이 존재하면 해당 Phase까지 완료로 판단
2. 마지막 완료 Phase의 파일을 Read하여 합의 내용 복원
3. 다음 Phase부터 재개 (A. 탐색부터)

---

### Phase 0: 복잡도 판단 (시작점 결정)

요청을 분석하여 시작 Phase를 결정하고 제안한다.

| 복잡도 | 시작 Phase | 예시 |
|--------|------------|------|
| 단순 (유틸 함수, 단일 파일) | **스킵** — 그냥 코드 작성 | `formatDate()` 추가 |
| 단일 컴포넌트 변경 | **Phase 2** (Components) 또는 **Phase 3** (Interactions) | 내부 구조 변경→P2, 외부 연결 추가→P3 |
| 다중 컴포넌트 | **Phase 1** (Capabilities) | 새 기능 도메인 |
| 시스템 통합 / 외부 연동 | **Phase 1**부터 (Phase 3에서 통신 프로토콜·에러 전파 심화) | API 게이트웨이, 메시지 큐 |

요청을 분석한 뒤 AskUserQuestion으로 시작 Phase를 제안한다:

```
요청을 분석한 결과, [복잡도 수준]으로 판단됩니다.
Phase N ([이름])부터 시작하겠습니다. 동의하시나요?

1. 동의 (Recommended)
2. Phase N부터 시작 (더 상세히/간단히)
3. 설계 스킵, 바로 구현
```

단일 컴포넌트인 경우, 내부 구조 변경(Phase 2)인지 외부 연결 추가(Phase 3)인지를 추가로 확인한다.

---

### Phase 1: Capabilities (범위 정의)

**목적**: 시스템이 **무엇을** 하는지 합의한다. **어떻게**는 아직 논의하지 않는다.

#### 1-A. 탐색 (Explore subagent)

Explore subagent를 스폰하여 아래를 탐색한다:

- 관련 기존 기능 탐색 (Grep: 관련 키워드)
- 유사 기능 구현 패턴 (Glob: 디렉토리 구조)
- 비기능 요구사항 단서 (설정 파일, 인프라 코드)

프롬프트 입력: 설계 주제 + 프로젝트 경로
출력 형식:
```
### 기존 관련 기능
- {기능}: {위치} - {설명}
### 패턴
- {패턴명}: {예시 파일}
### 비기능 단서
- {항목}: {근거}
```

#### 1-B. 합의 (Main context)

탐색 결과를 기반으로 Capabilities 산출물을 정리한다:

- 핵심 기능 목록 정의 (동사 중심: "~한다")
- v1 범위 확정: 포함 / 제외 / 미정(defer) 분류
- 성공 기준 정의 (측정 가능한 형태)
- 비기능 요구사항 식별 (성능, 보안, 확장성)

`.claude/designs/{feature}/phase-1-capabilities.md`에 저장한다.

출력 형식:
```markdown
## Capabilities

### 포함 (v1)
- [ ] 기능 A: ...
- [ ] 기능 B: ...

### 제외 (명시적)
- 기능 C: 이유 ...

### 성공 기준
- 기준 1: ...
```

#### 1-C. 게이트 리뷰

Red Flags:
- "모든 것을 다 한다" — 범위가 없는 것과 같다
- 기능 목록이 10개 초과 — v1 범위 축소 필요
- "어떻게" 논의가 끼어듦 — Phase 2로 미룬다

사용자에게 Capabilities 요약을 보여주고 승인을 받는다. 승인 후 Phase 2로 진행.

---

### Phase 2: Components (구성요소)

**목적**: Phase 1의 기능을 구현할 **부품**을 식별한다.

#### 2-A. 탐색 (Explore subagent)

Explore subagent를 스폰하여 아래를 탐색한다:

- 재사용 가능한 기존 모듈/클래스/서비스 (Grep, Glob)
- 기존 디렉토리 구조와 네이밍 컨벤션 (Glob)
- 유사 기능의 컴포넌트 구성 패턴 (Read 샘플)

프롬프트 입력: 설계 주제 + Phase 1 합의 요약
출력 형식:
```
### 재사용 후보
- {모듈}: {위치} - {책임} - {재사용 가능 범위}
### 디렉토리 컨벤션
- {패턴}: {예시}
### 참고 구현
- {파일}: {관련 패턴 설명}
```

#### 2-B. 합의 (Main context)

탐색 결과를 기반으로 Components 산출물을 정리한다:

- 필요한 모듈/클래스/서비스 식별
- 각 컴포넌트의 단일 책임 정의
- 불필요한 추상화 거부 (YAGNI)

`.claude/designs/{feature}/phase-2-components.md`에 저장한다.

출력 형식:
```markdown
## Components

| 컴포넌트 | 책임 | 신규/기존 | 위치 |
|----------|------|-----------|------|
| A | ... | 신규 | src/... |
| B | ... | 기존 재사용 | src/... |
```

#### 2-C. 게이트 리뷰

Red Flags:
- 하나의 컴포넌트가 3개 이상의 책임 — 분리 필요
- 기존 코드와 중복되는 신규 컴포넌트 — 재사용 검토
- "혹시 나중에 필요할" 컴포넌트 — YAGNI 위반

사용자에게 Components 요약을 보여주고 승인을 받는다. 승인 후 Phase 3로 진행.

---

### Phase 3: Interactions (상호작용)

**목적**: 컴포넌트 간 **데이터 흐름과 통신 방식**을 정의한다.

#### 3-A. 탐색 (Explore subagent)

Explore subagent를 스폰하여 아래를 탐색한다:

- 기존 호출 흐름 패턴 (Grep: import/함수 호출 추적)
- 에러 전파 패턴 (Grep: try/catch, throw, Error 클래스)
- 동기/비동기 패턴 (Grep: async/await, callback, Promise)
- 의존성 방향 (import 그래프)

프롬프트 입력: 설계 주제 + Phase 2 합의 요약 (컴포넌트 목록)
출력 형식:
```
### 호출 흐름
- {시나리오}: {흐름 설명}
### 에러 패턴
- {패턴}: {예시 파일}
### 동기/비동기
- {영역}: {방식} - {근거}
```

#### 3-B. 합의 (Main context)

탐색 결과를 기반으로 Interactions 산출물을 정리한다:

- 주요 시나리오별 호출 흐름 (happy path)
- 에러 전파 경로 (failure path)
- 데이터 흐름 방향 (단방향/양방향)
- 동기/비동기 결정
- 의존성 방향 확인 (순환 의존 방지)

`.claude/designs/{feature}/phase-3-interactions.md`에 저장한다.

출력 형식:
```markdown
## Interactions

### 시나리오 1: [이름]
A → B: 요청 (데이터)
B → C: 위임 (변환된 데이터)
C → B: 결과
B → A: 응답

### 에러 경로
C 실패 → B: fallback 처리 → A: 에러 응답
```

#### 3-C. 게이트 리뷰

Red Flags:
- 순환 의존 (A→B→C→A) — 구조 재설계 필요
- 하나의 컴포넌트가 5개 이상과 직접 통신 — 중재자 패턴 검토
- 에러 경로 미정의 — 실패 시나리오 필수

사용자에게 Interactions 요약을 보여주고 승인을 받는다. 승인 후 Phase 4로 진행.

---

### Phase 4: Contracts (계약)

**목적**: 구현에 필요한 **인터페이스와 타입**을 확정한다.

#### 4-A. 탐색 (Explore subagent)

Explore subagent를 스폰하여 아래를 탐색한다:

- 기존 인터페이스/타입 패턴 (Grep: interface, type, class)
- 동일 이름 충돌 확인 (Grep: 타입명/함수명)
- 기존 테스트 패턴 (Glob: *test*, *spec*)
- 에러 타입 컨벤션 (Grep: Error, Exception 패턴)

프롬프트 입력: 설계 주제 + Phase 2-3 합의 요약
출력 형식:
```
### 기존 타입/인터페이스
- {타입}: {위치} - {용도}
### 이름 충돌
- {이름}: {충돌 위치} (있으면)
### 테스트 패턴
- {패턴}: {예시 파일}
### 에러 컨벤션
- {패턴}: {예시}
```

#### 4-B. 합의 (Main context)

탐색 결과를 기반으로 Contracts 산출물을 정리한다:

- 함수 시그니처 / 메서드 정의
- 입출력 타입 / 스키마
- 에러 타입 정의
- TDD 시작점 수준의 테스트 케이스 목록

`.claude/designs/{feature}/phase-4-contracts.md`에 저장한다.

출력 형식:
```markdown
## Contracts

### ComponentA
- `doSomething(input: InputType): OutputType`
- `handleError(err: ErrorType): Recovery`

### 타입 정의
- `InputType`: { field1: string, field2: number }
- `OutputType`: { result: boolean, data?: string[] }

### 테스트 케이스
- [ ] 정상 입력 → 기대 출력
- [ ] 빈 입력 → 에러 반환
- [ ] 경계값 → 올바른 처리
```

#### 4-C. 게이트 리뷰

Red Flags:
- `any` 타입 남용 — 구체적 타입 필요
- 에러 타입 미정의 — 호출자가 에러를 처리할 수 없음
- 테스트 케이스 0개 — 계약이 검증 불가

사용자에게 Contracts 요약을 보여주고 승인을 받는다. 승인 후 Phase 5로 진행.

---

### Phase 5: Implementation (구현 전환)

**목적**: Phase 1-4 합의를 요약하고 구현으로 전환한다.

수행 항목:
1. **설계 합의 요약**: Phase 1-4에서 확정된 내용을 한 곳에 정리
2. **구현 전환 선택**: AskUserQuestion으로 다음 단계를 결정

```
설계 합의가 완료되었습니다. 다음 단계를 선택하세요:
1. plan-review로 검증 후 구현 (Recommended)
2. 바로 구현 시작
3. 설계 문서로 저장 (.claude/designs/)
```

**plan-review 연동 시**: 설계 합의 요약을 계획으로 변환하여 `/plan-review`에 전달.
**바로 구현 시**: 설계 합의 요약을 TaskCreate로 태스크화하고 순차 실행한다.
**설계 문서 저장 시**: `.claude/designs/{feature-name}.md`에 Phase 1-4 합의 내용을 저장한다.

Red Flags:
- 설계 합의 없이 바로 구현 선택 — Phase 1-4를 거친 이유가 없어짐
- 설계 문서만 저장하고 구현 미진행 — 합의의 유효기간이 지나면 재검토 필요

---

## 중요 원칙

1. **한 Phase씩만**: 현재 Phase가 승인되지 않으면 다음으로 넘어가지 않는다
2. **되돌아갈 수 있다**: 하위 Phase에서 상위 Phase의 결정을 수정해야 한다면, 사유를 설명하고 해당 Phase로 되돌아가 재승인 후 다시 진행한다
3. **코드베이스 기반**: 기존 코드를 확인(Grep, Glob, Read)한 뒤 설계한다. 추측하지 않는다
4. **과설계 방지**: 현재 필요한 최소한만 설계한다. "나중에 필요할 수도"는 제외한다
5. **설계 ≠ 문서**: 이 skill의 목적은 문서 생성이 아니라 **합의**다. 출력은 합의의 기록일 뿐이다

---

## Examples

### Example 1: 다중 컴포넌트 — 알림 시스템

```
User: /design-first 알림 시스템 설계
```

**Phase 0**: 복잡도 판단 → 다중 컴포넌트 → Phase 1부터 시작

**Phase 1 (Capabilities)**:
- 포함: 이메일 알림, 인앱 알림, 알림 설정 관리
- 제외: SMS (v2), 푸시 알림 (v2)
- 성공 기준: 알림 발송 후 3초 이내 도달

→ 사용자 승인 → Phase 2로

**Phase 2 (Components)**:
- NotificationService (신규) — 발송 오케스트레이션
- EmailAdapter (신규) — 이메일 전송
- NotificationStore (기존 DB 모듈 확장) — 알림 저장/조회
- UserPreference (기존) — 사용자 설정 재사용

→ 사용자 승인 → Phase 3으로

**Phase 3 (Interactions)**:
- 트리거 → NotificationService → UserPreference 확인 → EmailAdapter 발송 + NotificationStore 저장

→ 사용자 승인 → Phase 4로

**Phase 4 (Contracts)**: 시그니처, 타입, 테스트 케이스 정의

→ 사용자 승인 → Phase 5로

**Phase 5**: 설계 요약 → `/plan-review`로 검증 후 구현

### Example 2: 단일 컴포넌트 — 캐시 레이어 추가 (외부 연결 → Phase 3)

```
User: /design-first API 응답 캐시 추가
```

**Phase 0**: 복잡도 판단 → 단일 컴포넌트, 외부 연결 추가 → Phase 3부터 시작

**Phase 3 (Interactions)**:
- 요청 → CacheMiddleware → 캐시 히트? → 반환 : API 호출 → 캐시 저장 → 반환
- TTL 만료 → 캐시 무효화

→ 사용자 승인 → Phase 4로

**Phase 4 (Contracts)**: 캐시 키 전략, TTL 설정, 타입 정의

→ 사용자 승인 → Phase 5로

**Phase 5**: 설계 요약 → 바로 구현 (단순하므로)

### Example 2b: 단일 컴포넌트 — 모듈 내부 리팩터링 (내부 구조 → Phase 2)

```
User: /design-first UserService 책임 분리
```

**Phase 0**: 복잡도 판단 → 단일 컴포넌트, 내부 구조 변경 → Phase 2부터 시작

**Phase 2 (Components)**:
- UserService → UserAuthService (인증) + UserProfileService (프로필)
- 기존 UserRepository 재사용

→ 사용자 승인 → Phase 3으로

**Phase 3 (Interactions)**: 분리된 서비스 간 호출 흐름 정의

→ 사용자 승인 → Phase 4로

**Phase 4 (Contracts)**: 시그니처, 타입 정의 → Phase 5로

### Example 3: 복잡도 스킵

```
User: /design-first formatDate 유틸 함수
```

**Phase 0**: 복잡도 판단 → 단순 유틸 → 설계 불필요

"단일 유틸 함수는 설계 없이 바로 구현하는 것이 효율적입니다. 바로 코드를 작성할까요?"

---

## 연동

```
design-first (설계 합의)  ← 현재 skill
  → plan-review (계획 검증)
    → 실행
      → reflect (사후 회고)
```

| Skill | 관계 | 설명 |
|-------|------|------|
| `plan-review` | 후행 | 설계 완료 후 실행 계획 검증에 사용 |
| `reflect` | 사후 | 구현 후 설계 대비 결과 회고 |
