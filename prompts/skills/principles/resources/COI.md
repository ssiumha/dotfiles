---
name: COI
full_name: Composition over Inheritance
category: design
origin: Design Patterns (GoF, 1994)
one_liner: "상속보다 합성을 선호한다"
---

# COI — Composition over Inheritance

## 정의

> "Favor object composition over class inheritance."

상속은 강한 결합이다. 부모를 바꾸면 모든 자식이 영향받는다.
합성은 느슨한 결합이다. 부품을 교체하면 된다.

## 핵심 판단

- **"is-a 관계인가, has-a 관계인가?"** — has-a면 합성
- **"부모 클래스의 모든 메서드가 자식에 의미 있는가?"** — 아니면 합성
- **"상속 깊이가 3을 넘는가?"** — 넘으면 거의 확실히 합성이 더 낫다

## 위반 신호

### 기계적 검증 (자동화 가능)

| 신호 | 임계값 | 검증 방법 |
|------|--------|-----------|
| 상속 깊이 | > 2단 | ast-grep, 클래스 계층 분석 |
| 오버라이드에서 super() 미호출 또는 빈 구현 | 1개+ | ast-grep |
| 다중 상속 / mixin 수 | > 2개 | grep `extends.*,\|class.*\(.*,` |
| 프레임워크 강제 상속 외의 상속 | 확인 필요 | 상속 목록 추출 후 분류 |

### 판단 필요 (사람/LLM)

| 신호 | 설명 |
|------|------|
| "부모에 있지만 자식에서 무의미한 메서드" | LSP 위반과 겹침 |
| 부모 변경 시 자식 일부가 깨짐 | Fragile Base Class 문제 |
| "이 기능을 쓰려면 이 클래스를 상속해야 해" | 기능 재사용을 위한 상속 남용 |
| 다이아몬드 문제 | 다중 상속 경로 충돌 |
| 테스트 시 부모 의존성 때문에 mock 복잡 | 상속이 테스트를 어렵게 만듦 |

## 스코어링

| 등급 | 기준 |
|------|------|
| **PASS** | 상속 깊이 ≤2, 모든 상속이 진짜 is-a, 빈 오버라이드 0 |
| **WARN** | 상속 깊이 3 OR 기능 재사용 목적 상속 1-2개 |
| **FAIL** | 상속 깊이 4+ OR Fragile Base Class 문제 OR 다이아몬드 |

## 상속이 적절한 경우

모든 상속이 나쁜 것은 아니다:

| 상황 | 상속 OK |
|------|---------|
| 프레임워크 요구 | Django Model, React Component (레거시) |
| 진짜 is-a + LSP 충족 | `Square extends Shape` (모든 Shape 연산이 유효) |
| Template Method 패턴 | 알고리즘 뼈대 고정, 단계만 변경 |
| 얕은 상속 (1단) | Base → Concrete, 확장 가능성 낮음 |

## 개선 패턴

| 상황 | 적용 |
|------|------|
| 기능 재사용 상속 | **Strategy** — 행동을 별도 객체로, 주입 |
| 기능 추가 상속 | **Decorator** — 기존 객체를 감싸서 확장 |
| 타입 계층 상속 | **Interface + Composition** — 인터페이스 구현 + 위임 |
| mixin 남용 | **Composition** — mixin 대신 주입 가능한 모듈 |
| 테스트 어려운 상속 | **의존성 주입** — 생성자에서 협력자 주입 |

## 주의

- 합성이 항상 상속보다 나은 것은 아니다. 진짜 is-a 관계에서 합성은 불필요한 위임 코드를 만든다
- 언어 특성을 고려: Go는 상속 자체가 없고, Rust는 trait으로 합성, Python은 mixin이 관용적
- "상속을 쓰지 마라"가 아니라 "먼저 합성을 고려하라"
