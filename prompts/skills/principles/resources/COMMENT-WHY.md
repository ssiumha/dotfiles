---
name: COMMENT-WHY
full_name: "Comments Explain WHY, Not WHAT"
category: process
origin: Steve McConnell "Code Complete" 2/e (2004) Ch.32 → Robert C. Martin "Clean Code" (2008) Ch.4 "Good Comments — Explanation of Intent"
one_liner: "주석은 코드가 답할 수 없는 WHY만 적는다 — WHAT/HOW는 코드 자체로"
---

# COMMENT-WHY — 주석은 WHY를 적는다

## 정의

> "Don't comment bad code — rewrite it." — Brian W. Kernighan & P. J. Plauger, *The Elements of Programming Style* (1974)
>
> "The proper use of comments is to compensate for our failure to express ourselves in code." — Robert C. Martin, *Clean Code*

코드는 **WHAT(무엇을)** 과 **HOW(어떻게)** 를 이미 보여준다. 주석이 그것을 다시 설명하면 중복이고, 코드와 주석이 따로 진화하면 거짓말이 된다. 주석이 가치를 주는 영역은 **코드가 표현 못 하는 WHY** — 의사결정의 배경, 선택하지 않은 대안, 외부 제약, 시간 압박으로 인한 의도된 trade-off, 미래 독자에게 보내는 경고.

[[CHESTERTONS-FENCE]]가 "이유를 모르면 치우지 마라"라면, 이 원칙은 그 짝이다 — **"미래의 누군가가 이유를 알 수 있게 남겨라"**.

## 핵심 판단

- **"이 주석이 코드가 이미 말한 것을 반복하는가?"** — 그러면 삭제 대상
- **"이 주석이 사라지면 미래 독자가 잘못된 판단을 할 가능성이 있는가?"** — 있으면 보존
- **"이 주석이 코드와 함께 갱신되지 않으면 거짓말이 되는가?"** — 그러면 위험 신호 (변경 빈도가 높은 부분에 WHAT 주석은 거짓말로 변함)

## 위반 신호

### 기계적 검증 (자동화 가능)

| 신호 | 검증 방법 |
|------|-----------|
| 코드와 동의어 주석 (`i++ // increment i`) | grep 단순 동의어 패턴 |
| 자동 생성 docstring 그대로 (`@param x x값`) | 빈 의미 docstring 비율 |
| TODO/FIXME에 날짜·이슈 번호 부재 | grep `TODO\|FIXME` 후 컨텍스트 부재 비율 |
| commented-out 코드 (주석 처리된 코드 블록) | grep 주석으로 감싼 코드 패턴 |
| 변경 이력 주석 (`// 2024-03-15: foo 추가`) | git이 할 일을 코드에서 |

### 판단 필요 (사람/LLM)

| 신호 | 설명 |
|------|------|
| 함수명이 명확한데 주석으로 동작 재설명 | 이름을 의심 ([[INTENTION-REVEALING-NAMES]]) |
| 비자명한 비즈니스 규칙에 주석 없음 | WHY 부재 |
| 임시 우회/workaround에 배경 설명 없음 | 미래 독자가 안전하게 제거 못 함 |
| `// 이상하지만 이렇게 해야 함` (이유 없음) | 절반만 남긴 의도 |
| 외부 시스템 버그를 우회하는데 이슈 링크 없음 | 추적 불가 |

## 스코어링

| 등급 | 기준 |
|------|------|
| **PASS** | 비자명한 결정에 WHY 주석 존재, WHAT 주석 거의 없음, TODO에 컨텍스트(날짜/이슈) |
| **WARN** | WHAT 주석이 일부 있으나 거짓말은 안 함, 핵심 결정의 WHY는 기록됨 |
| **FAIL** | 비자명한 우회/임시 코드에 WHY 부재 OR 코드와 모순되는 거짓 주석 OR commented-out 코드 다수 |

## 좋은 주석의 6가지 카테고리 (Clean Code Ch.4)

Robert C. Martin이 "쓸 가치가 있다"고 분류한 주석:

1. **Legal Comments** — 라이선스, 저작권 (강제됨)
2. **Informative Comments** — 정규식 의도, 반환 형식 등 코드로 표현 못 하는 정보
3. **Explanation of Intent** — **WHY** — 왜 이 결정을 내렸는지
4. **Clarification** — 외부 라이브러리/표준 라이브러리 호출의 모호함 해소
5. **Warning of Consequences** — "이 테스트는 30분 걸림", "thread-safe 아님"
6. **TODO Comments** — 미완성 의도 + 컨텍스트(언제, 왜, 누가 이어받을지)

## 개선 패턴

| 상황 | 적용 |
|------|------|
| 코드를 설명하는 WHAT 주석 | **삭제 + 이름 개선** ([[INTENTION-REVEALING-NAMES]]) |
| 임시 우회 / workaround | **WHY 주석 + 이슈 링크 + 제거 조건** |
| 외부 버그를 우회 | **외부 이슈 URL + 재현 조건 + 우회 제거 시점** |
| 비즈니스 규칙이 비자명 | **결정 배경을 주석에 + ADR/스펙 페이지 링크** |
| 성능을 위해 명료성을 포기 | **벤치마크 결과 + 단순한 대안과의 차이 명시** |
| TODO 누적 | **기한 부여** — `TODO(2026-05-01, ISSUE-123)` |

## 코드가 말 못하는 것의 예

```python
# ❌ WHAT — 코드가 이미 말함
i = i + 1  # i를 1 증가

# ❌ 거짓말 — 코드는 7일, 주석은 30일
DEADLINE_DAYS = 7  # 30일 이내 응답 마감

# ✅ WHY — 코드로 표현 불가
# Stripe API가 idempotency key 없이 호출 시 같은 카드를 두 번 청구하는 버그가 있음
# https://github.com/stripe/stripe-node/issues/1234
# 이슈 해결되면 이 wrapper 제거
def charge_with_idempotency(amount, key): ...

# ✅ Warning — 호출자에게 경고
# 이 함수는 thread-safe 아님. 호출자가 lock을 잡아야 함
def update_cache(key, value): ...

# ✅ 의도된 trade-off — 미래 독자가 "왜 이렇게?"라고 묻지 않게
# O(n²)이지만 n≤50 보장되고, 단순함이 우선. 성능 문제 시 KMP로 교체 가능
def find_pattern(text, pattern): ...
```

## 다른 원칙과의 관계

| 원칙 | 관계 |
|------|------|
| [[CHESTERTONS-FENCE]] | "이유 모르면 치우지 마라"의 짝 — "미래의 누군가가 이유를 알 수 있게 남겨라". 두 원칙이 함께 작동해야 의도가 보존됨 |
| [[INTENTION-REVEALING-NAMES]] | 이름이 의도를 드러내면 주석 불필요. 주석을 쓰기 전 이름을 먼저 의심 |
| [[BROKEN-WINDOWS]] | TODO 누적, commented-out 코드 방치는 깨진 유리창. 시스템(lint)이 차단 |
| [[BOY-SCOUT]] | 코드를 떠날 때 거짓 주석/낡은 주석을 정리하라 |

## AI 시대의 추가 가치

코드를 읽는 주체가 사람만이 아니다. AI는 코드의 WHAT/HOW는 잘 추론하지만, **WHY는 역추론하기 어렵다** — 외부 제약, 폐기된 대안, 조직적 압박은 코드에 흔적이 없기 때문. WHY 주석은 사람과 AI 양쪽의 컨텍스트 비용을 줄인다.

## 주의

- "주석을 쓰지 마라"가 아니다. **WHAT/HOW 주석을 쓰지 마라**. WHY는 더 많이 써도 좋다
- 주석은 코드와 함께 갱신해야 한다. 갱신 안 될 것 같은 주석은 안 쓰는 게 낫다 (거짓말 예방)
- 자동 생성 docstring 도구의 기본값은 대부분 WHAT — 의미 없으면 비활성화
- ADR/스펙 페이지 링크는 강력하다. 코드 주석은 짧게, 깊은 배경은 외부 문서로
