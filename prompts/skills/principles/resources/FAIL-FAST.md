---
name: FAIL-FAST
full_name: Fail Fast Principle
category: process
origin: Jim Shore, "Fail Fast" (IEEE Software, 2004)
one_liner: "오류를 가능한 한 빨리, 가능한 한 가까운 곳에서 감지한다"
---

# FAIL-FAST — 빠른 실패 원칙

## 정의

> "문제가 발생하면 즉시 멈추고 알려라. 오류를 삼키거나 넘기지 마라."

오류 감지가 늦을수록 디버깅 비용이 기하급수적으로 증가한다.
컴파일 시 잡는 것이 런타임보다 10배 싸고, 런타임이 프로덕션보다 100배 싸다.

## 핵심 판단

- **"이 오류가 어디서 발견되는가?"** — 왼쪽(early)일수록 좋다
- **"오류가 묵인되거나 무시되는 곳이 있는가?"** — 있다면 위반
- **감지 계층**: 타입 < lint < 테스트 < CI < staging < production

## 위반 신호

### 기계적 검증 (자동화 가능)

| 신호 | 검증 방법 |
|------|-----------|
| 빈 catch/except 블록 | grep `catch.*\{\s*\}`, `except:\s*pass` |
| 오류 삼키기 (log만 하고 계속) | grep `catch.*log.*continue\|catch.*console` |
| 검증 없는 외부 입력 사용 | 함수 시작부 검증 부재 확인 |
| `any` 타입 / 타입 무시 | grep `any\|type: ignore\|@ts-ignore\|# noqa` |
| 묵시적 null/undefined 전파 | optional chaining 과다 사용 (`?.` 3단+) |

### 판단 필요 (사람/LLM)

| 신호 | 설명 |
|------|------|
| "일단 넘어가고" 패턴 | 오류를 나중에 처리하겠다는 의도 |
| 기본값으로 오류 숨기기 | 실패 시 빈 배열/null 반환 → 호출자가 모름 |
| 런타임에서야 발견되는 설정 오류 | 시작 시 검증하면 잡을 수 있는 것 |
| 느슨한 타입 시스템 활용 | 컴파일 시 잡을 수 있는 것을 런타임으로 미룸 |
| 에러 메시지 없는 실패 | 무엇이 왜 실패했는지 알 수 없음 |

## 스코어링

| 등급 | 기준 |
|------|------|
| **PASS** | 빈 catch 0, 입력 검증 충분, 타입 안전, 에러 메시지 명확 |
| **WARN** | 빈 catch 1-2개 OR 일부 입력 검증 누락 OR `any`/`ts-ignore` 소수 |
| **FAIL** | 빈 catch 3개+ OR 오류 삼키기 패턴 반복 OR 에러 무시 |

## Fail Fast 계층

오류를 가능한 한 왼쪽에서 잡는다:

```
타입 시스템 → lint → 단위 테스트 → 통합 테스트 → CI → staging → production
   가장 싸다                                                   가장 비싸다
```

| 계층 | 잡을 수 있는 것 | 도구 |
|------|-----------------|------|
| 타입 | null 참조, 인터페이스 불일치 | TypeScript strict, mypy |
| lint | 코딩 규칙, 안티패턴 | ESLint, Ruff |
| 테스트 | 로직 오류, 경계 조건 | Jest, pytest |
| CI | 통합 오류, 회귀 | GitHub Actions |
| 시작 시 | 설정 오류, 의존성 누락 | Config validation |
| 런타임 | 외부 입력, 네트워크 | Input validation |

## 개선 패턴

| 상황 | 적용 |
|------|------|
| 빈 catch 블록 | **재던지기 또는 명시적 처리** |
| 느슨한 타입 | **strict 모드 활성화** (strictNullChecks 등) |
| 런타임 설정 오류 | **시작 시 검증** — 잘못된 설정이면 바로 종료 |
| 기본값으로 숨기기 | **Optional/Result 타입** — 실패를 명시적으로 전파 |
| 에러 메시지 부재 | **구조화된 에러** — what, why, where 포함 |

## 주의

- Fail Fast ≠ Fail Loudly Everywhere. 시스템 경계에서 fail fast, 내부는 타입으로 보장
- 사용자 facing 코드에서는 graceful degradation이 맞을 수 있다. 핵심은 "개발자가 오류를 인지"하는 것
- 재시도 가능한 일시적 오류(네트워크 등)는 fail fast 대상이 아니다 — retry with backoff
