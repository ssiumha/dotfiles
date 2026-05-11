---
name: TDA
full_name: Tell, Don't Ask
category: design
origin: Andy Hunt & Dave Thomas, "The Pragmatic Programmer" (1999)
one_liner: "객체에게 상태를 물어서 판단하지 말고, 해야 할 일을 시켜라"
---

# TDA — Tell, Don't Ask

## 정의

> "Don't ask an object for its data to do something; tell the object to do it for you."

객체의 상태를 꺼내서 외부에서 판단하는 대신, 객체에게 행동을 요청한다. 데이터와 그 데이터를 다루는 로직이 같은 곳에 있어야 한다.

## 핵심 판단

- **"이 객체의 상태를 꺼내서 외부에서 if/switch 하고 있는가?"** — 있으면 위반
- **"로직이 데이터가 있는 곳이 아니라 호출하는 곳에 있는가?"** — 있으면 위반
- **"getter를 호출한 뒤 바로 비즈니스 로직이 따라오는가?"** — 따라오면 의심

## 위반 신호

### 기계적 검증 (자동화 가능)

| 신호 | 검증 방법 |
|------|-----------|
| getter 호출 직후 조건 분기 | `if (obj.getX())` 패턴 빈도 |
| 한 객체의 getter를 3개+ 연속 호출 | 같은 객체의 get 연속 호출 패턴 |
| 외부에서 객체 상태 조합하여 계산 | `obj.getA() * obj.getB()` 패턴 |

### 판단 필요 (사람/LLM)

| 신호 | 설명 |
|------|------|
| "Feature Envy" — 메서드가 자기 클래스보다 다른 클래스 데이터를 더 많이 사용 | 로직이 잘못된 곳에 있음 |
| DTO/VO를 비즈니스 로직에서 직접 분해 | 도메인 객체가 빈혈 모델 |
| 서비스 레이어가 엔티티의 getter로 가득 | 도메인 로직이 서비스에 유출 |
| 뷰/컨트롤러가 모델 상태를 꺼내서 판단 | 프레젠테이션 레이어가 도메인 로직 수행 |

## 스코어링

| 등급 | 기준 |
|------|------|
| **PASS** | 비즈니스 로직이 도메인 객체 내부에 위치, getter 후 분기 패턴 드묾 |
| **WARN** | 일부 서비스에서 getter + 분기 패턴, 핵심 도메인은 캡슐화됨 |
| **FAIL** | Feature Envy 다수 OR 빈혈 모델 + 서비스에 로직 집중 OR getter 체인 후 판단 반복 |

## Ask vs Tell 비교

```
// ❌ Ask: 상태를 꺼내서 외부에서 판단
if (account.getBalance() >= amount) {
  account.setBalance(account.getBalance() - amount)
  // 여기서 또 다른 검증...
}

// ✅ Tell: 객체에게 행동을 요청
account.withdraw(amount)
// 검증, 상태 변경, 이벤트 발행 모두 account 내부에서
```

```
// ❌ Ask: getter 연쇄 + 외부 계산
const price = item.getPrice()
const qty = item.getQuantity()
const discount = item.getDiscount()
const total = price * qty * (1 - discount)

// ✅ Tell: 계산을 객체에게 위임
const total = item.calculateTotal()
```

## 개선 패턴

| 상황 | 적용 |
|------|------|
| getter + if/switch 외부 분기 | **Move Method** — 분기 로직을 객체 내부로 이동 |
| 여러 getter로 외부 계산 | **Extract Method → Move** — 계산을 데이터 소유 객체로 |
| 빈혈 모델 + Fat Service | **도메인 모델 강화** — 행동을 엔티티로 이동 |
| 상태 기반 다형성 필요 | **State / Strategy 패턴** — 조건 분기를 객체 구조로 |

## LoD와의 관계

| | LoD | TDA |
|--|-----|-----|
| 초점 | **누구와** 대화하는가 (범위) | **어떻게** 대화하는가 (방식) |
| 규칙 | 직접 친구에게만 말하라 | 물어보지 말고 시켜라 |
| 위반 | `a.getB().getC().doX()` | `if (a.getX()) { ... }` |
| 보완 | TDA를 지키면 LoD도 자연히 지켜짐 | LoD를 지켜도 TDA 위반 가능 |

## 주의

- TDA는 "getter를 없애라"가 아니다. 뷰/직렬화/로깅 등을 위해 getter는 필요. 문제는 **비즈니스 로직**이 getter에 의존하는 것
- DTO/VO는 데이터 전달 목적이므로 TDA 대상이 아니다. 도메인 객체에 적용
- 과도하게 적용하면 객체가 비대해진다. SRP와 균형을 맞춘다
- 함수형 프로그래밍에서는 데이터와 행동이 분리되므로 TDA가 직접 적용되지 않는다. 대신 파이프라인 / 트랜스포머 패턴으로 대체
