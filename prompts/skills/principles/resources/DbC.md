---
name: DbC
full_name: Design by Contract
category: contract
origin: Bertrand Meyer, "Object-Oriented Software Construction" (1988)
one_liner: "precondition·postcondition·invariant으로 모듈 간 계약을 명시한다"
---

# DbC — Design by Contract

## 정의

> "If you call me with these preconditions satisfied, I promise to deliver a result that satisfies these postconditions."

호출자와 피호출자 사이에 명시적 계약을 건다. 계약은 세 요소로 구성된다:
- **Precondition** — 호출자가 보장해야 하는 입력 조건
- **Postcondition** — 피호출자가 보장해야 하는 결과 조건
- **Invariant** — 연산 전후로 항상 유지되어야 하는 상태

계약 위반 시 책임이 즉시 명확해진다: precondition 위반 = 호출자 잘못, postcondition 위반 = 피호출자 잘못.

### Class Invariant — 객체 단위 불변식

함수 단위 invariant와 달리 class invariant는 **객체의 lifecycle 전체**에 걸쳐 성립해야 한다:
- **언제 성립해야 하나**: 생성자 종료 직후 + 모든 **public** 메서드 진입/종료 시점
- **언제 깨져도 되나**: public 메서드 실행 중간, private 메서드 호출 중 (외부에서 관찰 불가능한 구간)
- **상속 규칙**: subclass는 superclass invariant를 **강화**할 수 있으나 **약화하면 안 된다** → [[LSP]]와 직결

## 핵심 판단

- **"이 함수의 입력 조건이 어디에 명시되어 있는가?"** — 문서/타입/런타임 검증 중 하나는 있어야
- **"이 함수가 보장하는 결과가 무엇인가?"** — 반환 타입 + 부수효과 명세
- **"계약 위반 시 누구 책임인지 즉시 알 수 있는가?"** — 에러 메시지/타입 에러로 구분 가능해야

## 위반 신호

### 기계적 검증 (자동화 가능)

| 신호 | 검증 방법 |
|------|-----------|
| 함수 시작부에 입력 검증 없음 (외부 입력) | 함수 첫 5줄에 assert/validation 부재 확인 |
| 반환 타입이 `any` 또는 지나치게 넓음 | grep `-> any\|: any\|Promise<any>` |
| API 응답에 스키마 검증 없음 | Zod/joi/pydantic 등 validation 부재 |
| 공개 API에 JSDoc/docstring 없음 | 공개 함수에 문서 부재 확인 |

### 판단 필요 (사람/LLM)

| 신호 | 설명 |
|------|------|
| "이 함수에 null 넘기면 어떻게 되지?" | precondition 불명확 |
| 에러 발생 시 호출자/피호출자 책임 불분명 | 계약 경계 불명확 |
| 내부 상태가 외부에서 직접 변경 가능 | invariant 보호 부재 |
| 함수 동작이 암묵적 전역 상태에 의존 | 숨겨진 precondition |

## 스코어링

| 등급 | 기준 |
|------|------|
| **PASS** | 공개 API에 입력 검증 + 반환 타입 명시 + 에러 경계 명확 |
| **WARN** | 일부 함수에서 계약 불명확하나 핵심 경로는 보호됨 |
| **FAIL** | 공개 API에 입력 검증 없음 OR 반환 타입 any OR 에러 책임 불분명 |

## 계약의 세 계층

```
Precondition (호출자 책임)
  → "이 조건을 만족해서 호출하라"
  → 위반 시: 호출자 버그

Postcondition (피호출자 책임)
  → "이 결과를 보장한다"
  → 위반 시: 피호출자 버그

Invariant (양쪽 공동)
  → "이 상태는 항상 유지된다"
  → 위반 시: 설계 결함
```

## 개선 패턴

| 상황 | 적용 |
|------|------|
| 입력 검증이 함수 곳곳에 흩어짐 | **Guard Clause** — 함수 시작부에 precondition 집중 |
| API 응답 형식이 암묵적 | **스키마 검증** — Zod, pydantic, joi 등으로 postcondition 명시 |
| FE-BE 경계 계약이 암묵적 | **스키마 기반 계약 도구 도입** (OpenAPI, tRPC, GraphQL 등) |
| 클래스 상태가 외부에서 깨질 수 있음 | **불변 객체 / private + 검증 setter** — invariant 보호 |
| 에러 시 책임 소재 불명 | **구조화된 에러 타입** — precondition 위반 vs 내부 오류 구분 |

## 주의

- 모든 함수에 계약을 명시할 필요 없다. **시스템 경계**(API, 모듈 공개 인터페이스)에 집중
- 내부 private 함수는 타입 시스템으로 충분한 경우가 많다. 과도한 assert는 노이즈
- Defensive Programming(모든 곳에서 검증)과 DbC(경계에서 계약)는 다르다. DbC가 더 효율적
- precondition을 피호출자가 검증하면 책임이 흐려진다 — 호출자가 보장, 피호출자는 assert로 확인만
