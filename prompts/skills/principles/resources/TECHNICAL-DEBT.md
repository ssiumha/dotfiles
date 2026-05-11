---
name: TECHNICAL-DEBT
full_name: Technical Debt
category: process
origin: Ward Cunningham, OOPSLA '92 experience report "The WyCash Portfolio Management System" (1992) → Martin Fowler bliki "TechnicalDebtQuadrant" (2009)
one_liner: "오늘의 빠른 해결책은 미래의 이자 — 부채를 인지하고 명시한 차입은 건강하다"
---

# TECHNICAL-DEBT — 기술 부채

## 정의

> "Shipping first time code is like going into debt. A little debt speeds development so long as it is paid back promptly with a rewrite. ... The danger occurs when the debt is not repaid. Every minute spent on not-quite-right code counts as interest on that debt." — Ward Cunningham, 1992

코드를 "지금 옳은 방식"으로 짜지 않고 "지금 빠른 방식"으로 짜면, 미래에 이자를 낸다. 이자는 변경 비용 증가, 버그 발생률, 신규 입사자의 학습 시간 등으로 누적된다. **부채 자체는 죄가 아니다 — 인지되지 않은 부채와 갚지 않는 부채가 죄다.**

Ward Cunningham의 원래 비유는 "**의식적이고 신중한** 차입"이었다. Fowler는 이를 2축으로 분류했다 (의도적/무지한 × 신중한/무모한).

## Fowler의 Technical Debt Quadrant

```
                Reckless (무모한)              Prudent (신중한)
              ┌─────────────────────────┬─────────────────────────┐
Deliberate    │ "We don't have time     │ "We must ship now and   │
(의도적)       │  for design"             │  deal with consequences"│
              │  → 만성적 위기           │  → 의식적 부채 (건강)    │
              ├─────────────────────────┼─────────────────────────┤
Inadvertent   │ "What's layering?"      │ "Now we know how we     │
(무지한)       │  → 무지한 누적           │  should have done it"   │
              │                         │  → 학습으로 인식된 부채  │
              └─────────────────────────┴─────────────────────────┘
```

가장 위험한 사분면은 **Reckless × Inadvertent** — 모르고 무모하게 쌓인 부채. 가장 건강한 것은 **Prudent × Deliberate** — 인지된 차입.

## 핵심 판단

- **"이 결정이 부채라는 것을 인지하고 있는가?"** — 인지되지 않은 부채는 갚을 수 없다
- **"부채의 이자율을 추정할 수 있는가?"** — 변경 빈도 높은 영역의 부채가 비싸다
- **"부채를 갚을 트리거가 정의되어 있는가?"** — "나중에"는 갚지 않는다는 뜻

## 위반 신호

### 기계적 검증 (자동화 가능)

| 신호 | 검증 방법 |
|------|-----------|
| TODO/FIXME/HACK에 컨텍스트 부재 | grep 후 날짜/이슈 링크 부재 비율 |
| 코드 hot spot (변경 빈도 × 복잡도) 누적 | git log + 복잡도 측정 |
| `@deprecated` 표시된 채 사용처 다수 | grep 후 사용처 카운트 |
| 임시 우회 (workaround, hack) 키워드 빈도 | grep `hack\|workaround\|temporary\|TEMP` |
| 동일 패턴 중복 (DRY 위반)이 시간에 따라 증가 | 중복 검사 시계열 |

### 판단 필요 (사람/LLM)

| 신호 | 설명 |
|------|------|
| "나중에 고치자"가 6개월 이상 방치 | 부채 영구화 |
| 같은 영역에서 버그가 반복적으로 나옴 | 이자 지급 중 |
| 신규 기능 추가 시 비례 이상의 시간 소요 | 부채의 이자가 비용에 섞임 |
| "이건 원래 그래" 라는 설명이 자주 나옴 | 무지한 부채로 굳음 |
| 부채를 갚는 것에 비즈니스 정당화가 매번 필요 | 부채가 가시화되지 않음 |

## 스코어링

| 등급 | 기준 |
|------|------|
| **PASS** | TODO/FIXME에 컨텍스트(이슈/날짜/조건) 존재, 부채 목록이 가시화됨, 정기 상환 일정 |
| **WARN** | 일부 부채는 추적되나 비공식, hot spot에 의식적 차입이 있으나 상환 미정 |
| **FAIL** | 컨텍스트 없는 TODO 다수 OR 무지한 부채 누적(아무도 모름) OR 부채 상환을 비즈니스 정당화로 매번 막음 |

## 부채를 명시하는 방법

```python
# ❌ 인지되지 않은 부채
def calculate_fee(amount):
    return amount * 0.025  # 왜 2.5%? 누가 정함? 변경 조건?

# ❌ 절반만 인지 — 컨텍스트 부재
def calculate_fee(amount):
    # TODO: 수정 필요
    return amount * 0.025

# ✅ 의식적이고 신중한 차입
def calculate_fee(amount):
    # 부채: 수수료율이 카드사별로 달라야 하는데, MVP라 단일 값으로 시작
    # 갚을 시점: 카드사 다변화 시 (ISSUE-456)
    # 이자: 카드사 추가마다 코드 분기 필요, 현재 ~월 1회 변경 발생
    return amount * 0.025
```

## 갚는 전략

| 부채 종류 | 상환 전략 |
|-----------|-----------|
| 핫스팟의 부채 | **즉시 상환** — 변경 빈도 높은 곳은 이자가 비쌈 ([[BOY-SCOUT]] 적용) |
| 콜드 영역의 부채 | **의식적 보류** — 변경이 거의 없으면 이자가 0에 가까움 |
| 인지되지 않은 부채 | **가시화 먼저** — 부채 인벤토리 작성, 측정 도구 도입 |
| 무모한 부채 누적 | **부채 추가 차단** — CI/lint로 추가 차단 ([[BROKEN-WINDOWS]] 적용) |
| 이자가 폭증하는 부채 | **부채 일정 협상** — 비즈니스에 이자 비용을 가시화하여 시간 확보 |

## 다른 원칙과의 관계

| 원칙 | 관계 |
|------|------|
| [[BROKEN-WINDOWS]] | 짝 — Broken Windows는 "방치 안 됨", Technical Debt은 "의식적 차입은 OK". 무지한 부채는 깨진 유리창 |
| [[CHESTERTONS-FENCE]] | 부채를 갚기 전 "이게 정말 부채인가, 아니면 이유 있는 결정인가?"를 먼저 확인 |
| [[BOY-SCOUT]] | 핫스팟에서 작은 부채를 즉시 상환하는 실천 |
| [[COMMENT-WHY]] | 부채 명시는 WHY 주석의 한 형태 — "왜 이 부채를 졌는지" 기록 |
| [[YAGNI]] | YAGNI를 따르면 의도적 부채가 줄어듦 (불필요한 기능에 부채를 지지 않음) |

## 주의

- "0 부채"는 비현실적이고 비경제적이다. 모든 코드를 항상 완벽하게 짜면 출시가 불가능
- 부채는 **양보다 위치**가 중요. 콜드 영역의 큰 부채보다 핫스팟의 작은 부채가 더 비싸다
- "리팩토링 스프린트"는 종종 실패한다. **변경 빈도 높은 코드를 만질 때 함께 상환**이 더 효과적 (Boy Scout)
- 부채를 갚는 것에 비즈니스 정당화를 요구받으면 **이자를 가시화**하라 — "지난 분기에 X 영역 변경에 평균 Y배 시간 소요"
- 무지한 부채(Inadvertent)는 발견 자체가 어렵다. 코드 리뷰, 페어 프로그래밍, 외부 감사가 발견 수단
