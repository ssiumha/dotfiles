---
name: LSP
full_name: Liskov Substitution Principle
category: contract
origin: Barbara Liskov, "Data Abstraction and Hierarchy" (1987)
one_liner: "하위 타입은 상위 타입의 계약을 깨지 않고 대체할 수 있어야 한다"
---

# LSP — Liskov Substitution Principle

## 정의

> "If S is a subtype of T, then objects of type T may be replaced with objects of type S without altering any of the desirable properties of the program."

부모 타입을 사용하는 모든 곳에서 자식 타입으로 교체해도 프로그램이 정상 동작해야 한다. 상속/구현 시 상위 타입이 약속한 계약(precondition, postcondition, invariant)을 그대로 지켜야 한다. → 계약의 정의는 [[DbC]] 참조.

### 계약 보존 규칙

- **Precondition**: 하위 타입이 더 강하게 요구하면 안 된다 (같거나 약해야)
- **Postcondition**: 하위 타입이 더 약하게 보장하면 안 된다 (같거나 강해야)
- **Invariant**: 하위 타입이 상위 타입의 불변 조건을 깨면 안 된다 (강화는 허용, 약화는 금지)

## 핵심 판단

- **"부모 타입 자리에 이 자식을 넣으면 기존 코드가 깨지는가?"** — 깨지면 LSP 위반
- **"상속한 메서드의 동작을 바꾸고 있는가?"** — 시그니처는 같지만 의미가 다르면 위반
- **"instanceof / 타입 체크로 분기하고 있는가?"** — 대체 불가 신호

## 위반 신호

### 기계적 검증 (자동화 가능)

| 신호 | 검증 방법 |
|------|-----------|
| instanceof / typeof 타입 체크 분기 | grep `instanceof\|typeof.*===\|is_instance` |
| 오버라이드에서 예외 추가 | 부모에 없는 예외를 자식이 던짐 |
| 오버라이드에서 빈 구현 / NotImplementedError | grep `NotImplementedError\|throw.*not.implemented\|pass$` |
| 부모 메서드 호출 없이 완전히 다른 동작 | override 메서드에서 super 호출 패턴 확인 |

### 판단 필요 (사람/LLM)

| 신호 | 설명 |
|------|------|
| Rectangle-Square 문제 | 자식이 부모의 setter 동작을 변경 |
| 컬렉션 하위 타입이 add()를 거부 | 부모가 허용하는 연산을 자식이 제한 (precondition 강화) |
| "이 타입일 때만 특별 처리" 패턴 | 대체 불가로 인한 분기 |
| 오버라이드가 부모의 반환 범위를 축소/확대 | postcondition 변경 |

## 스코어링

| 등급 | 기준 |
|------|------|
| **PASS** | instanceof 분기 0, 오버라이드가 부모 계약 유지, 대체 가능 |
| **WARN** | instanceof 분기 1-2개 OR 일부 오버라이드가 동작 미묘하게 변경 |
| **FAIL** | instanceof 분기 다수 OR 오버라이드가 예외 추가/동작 변경 OR NotImplementedError |

## 고전적 위반 사례

```
// Rectangle-Square 문제
class Rectangle {
  setWidth(w)  { this.width = w }
  setHeight(h) { this.height = h }
  area()       { return this.width * this.height }
}

class Square extends Rectangle {
  setWidth(w)  { this.width = w; this.height = w }  // ← postcondition 변경!
  setHeight(h) { this.width = h; this.height = h }
}

// 호출자가 Rectangle 계약을 믿고:
r.setWidth(5); r.setHeight(3);
// Rectangle: area = 15, Square: area = 9 ← 깨짐
```

## 개선 패턴

| 상황 | 적용 |
|------|------|
| 자식이 부모 메서드를 빈 구현으로 오버라이드 | **ISP 적용** — 인터페이스를 분리하여 필요한 것만 구현 |
| instanceof 분기가 늘어남 | **다형성 (Strategy/Visitor)** — 타입 체크 대신 메서드 디스패치 |
| 상속이 is-a 관계가 아님 | **Composition 전환** — 상속 대신 합성 (COI) |
| 부모 계약이 너무 넓어 자식이 못 지킴 | **인터페이스 분리 (ISP)** — 작은 계약으로 분리 |

## 주의

- LSP는 "상속하지 마라"가 아니다. 상속하되 계약을 지키라는 것
- 타입 시스템이 시그니처는 검증하지만 동작(의미론)은 검증 못 한다. 테스트가 필요
- LSP 위반이 보이면 먼저 "이 상속 관계가 맞는가?"를 질문. 종종 COI가 답이다
- TypeScript/Python의 구조적 타입은 명목적 상속 없이도 LSP가 적용된다 — 덕 타이핑에서도 계약은 존재
