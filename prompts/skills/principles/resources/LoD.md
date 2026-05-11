---
name: LoD
full_name: Law of Demeter (Principle of Least Knowledge)
category: design
origin: Karl Lieberherr, 1987
one_liner: "직접 친구에게만 말하라 — a.b.c.d() 금지"
---

# LoD — Law of Demeter

## 정의

> "Only talk to your immediate friends."

메서드 M이 호출할 수 있는 대상:
1. M이 속한 객체 자신 (`this`/`self`)
2. M의 파라미터
3. M 안에서 생성한 객체
4. M이 속한 객체의 필드

그 외 — 특히 "친구의 친구"를 통한 호출은 위반.

## 핵심 판단

- **메서드 체이닝이 2단계를 넘는가?** — `a.b.c()` 이상이면 의심
- **내부 구조를 알아야 호출 가능한가?** — 호출자가 피호출자의 내부를 알고 있다면 위반
- **Tell, Don't Ask** — 객체에게 무엇을 하라고 말하지, 내부를 꺼내서 직접 하지 않는다

## 위반 신호

### 기계적 검증 (자동화 가능)

| 신호 | 임계값 | 검증 방법 |
|------|--------|-----------|
| 메서드 체이닝 깊이 | > 2단계 | grep `\.\w+\.\w+\.\w+` (3연속 dot access) |
| getter 후 조작 | 파일당 5회+ | grep `get.*\(\)\.` 패턴 |

### 판단 필요 (사람/LLM)

| 신호 | 설명 |
|------|------|
| Train Wreck 코드 | `order.getCustomer().getAddress().getCity()` |
| 객체 내부 꺼내서 외부에서 조작 | `data = obj.internal; process(data)` — obj에 위임해야 |
| 다른 객체의 필드를 알아야 동작하는 로직 | Feature Envy — 로직이 데이터 주인에게 가야 한다 |

**예외 (위반이 아닌 경우)**:
- Fluent API / Builder 패턴: `builder.setA().setB().build()` — 같은 객체 반환이므로 LoD 위반 아님
- 컬렉션/스트림 연산: `list.filter().map().reduce()` — 데이터 변환 파이프라인
- DTO/Value Object 접근: 순수 데이터 컨테이너에 대한 필드 접근

## 스코어링

| 등급 | 기준 |
|------|------|
| **PASS** | 3단계+ 체이닝 0개, getter 후 조작 거의 없음 |
| **WARN** | 3단계+ 체이닝 1-3개 OR 예외에 해당하지 않는 getter 조작 |
| **FAIL** | 3단계+ 체이닝 4개+ OR Train Wreck 패턴 반복 |

## 개선 패턴

| 상황 | 적용 |
|------|------|
| `a.getB().getC().doX()` | **위임 메서드**: `a.doX()` 추가, 내부에서 체인 처리 |
| getter로 꺼내서 외부 조작 | **Tell Don't Ask**: 조작 로직을 객체 안으로 이동 |
| 여러 객체의 내부를 조합 | **Facade/Mediator**: 조합 로직을 별도 객체로 |

## 주의

- LoD를 극단적으로 적용하면 위임 메서드가 폭발한다. 실용적으로 적용
- 핵심은 "결합도 감소"이지 "점(dot) 수 줄이기"가 아니다
- 같은 추상화 수준의 체이닝은 괜찮다. 추상화 수준을 넘나드는 체이닝이 문제
