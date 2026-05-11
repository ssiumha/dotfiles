---
name: UAP
full_name: Uniform Access Principle
category: contract
origin: Bertrand Meyer, "Object-Oriented Software Construction" (1988)
one_liner: "저장된 속성이든 계산된 값이든 호출자에게 동일한 방식으로 접근한다"
---

# UAP — Uniform Access Principle

## 정의

> "All services offered by a module should be available through a uniform notation, which does not betray whether they are implemented through storage or through computation."

호출하는 쪽에서는 값이 미리 저장된 필드인지, 매번 계산하는 메서드인지 알 필요가 없어야 한다. 내부 구현이 바뀌어도 호출 코드는 바뀌지 않는다.

## 핵심 판단

- **"이 값이 필드인지 계산인지 호출자가 알아야 하는가?"** — 알아야 한다면 위반
- **"필드를 메서드로 바꾸면 호출 코드가 변경되는가?"** — 변경되면 위반
- **"getter가 단순 반환 외에 부수효과를 가지는가?"** — 부수효과가 있으면 POLA도 위반

## 위반 신호

### 기계적 검증 (자동화 가능)

| 신호 | 검증 방법 |
|------|-----------|
| 같은 개념이 `.field`와 `.getField()` 혼용 | 네이밍 패턴 일관성 확인 |
| public 필드 직접 접근 + setter 로직 필요 | public 필드에 검증 없는 직접 할당 |
| 계산 메서드와 저장 속성의 접근 방식 불일치 | `user.age` vs `user.getAge()` 혼용 |

### 판단 필요 (사람/LLM)

| 신호 | 설명 |
|------|------|
| 캐싱 도입 시 호출 코드 변경 필요 | 구현 변경이 인터페이스에 누출 |
| "이건 비싼 연산이니까 직접 호출하지 마세요" | 비용이 인터페이스에 노출됨 |
| 필드 → 계산 전환 시 리팩토링 필요 | uniform access 부재 |

## 스코어링

| 등급 | 기준 |
|------|------|
| **PASS** | 속성/계산 접근 방식 일관, 구현 변경 시 호출 코드 불변 |
| **WARN** | 일부 불일치 존재하나 핵심 인터페이스는 일관 |
| **FAIL** | 같은 모듈에서 `.field`와 `.getField()` 혼용 OR 구현 변경이 호출 코드 변경 유발 |

## 언어별 지원

| 언어 | 메커니즘 |
|------|----------|
| Python | `@property` — 메서드를 속성처럼 접근 |
| Kotlin | `val` + custom getter — 필드와 계산 동일 문법 |
| C# | property (`get; set;`) — 필드와 동일 접근 |
| JavaScript/TS | `get` accessor — `obj.value`로 통일 |
| Ruby | `attr_reader` + method — 자연스러운 uniform access |
| Java | UAP 미지원 — `getX()` 컨벤션으로 우회 |

## 개선 패턴

| 상황 | 적용 |
|------|------|
| public 필드에 나중에 검증 추가 필요 | **Property/Getter** — 처음부터 접근자 사용 |
| 필드 → 계산 전환 시 호출 변경 다수 | **Property 래핑** — 기존 인터페이스 유지하며 내부 전환 |
| 비싼 계산을 매번 호출 | **Lazy Initialization / Memoization** — 인터페이스는 유지하며 내부 캐싱 |
| getter에 부수효과 | **Command-Query Separation** — 조회와 변경을 분리 |

## 주의

- UAP는 "getter를 만들어라"가 아니다. 언어가 property를 지원하면 그것을 사용
- Java처럼 UAP를 지원하지 않는 언어에서는 처음부터 `getX()` 컨벤션으로 통일하는 것이 현실적
- 성능이 중요한 경우 비싼 계산을 property로 숨기면 POLA 위반. 이 경우 명시적 메서드가 나을 수 있다
- UAP와 ENCAPSULATION은 상호 보완적. UAP는 접근 방식 통일, ENCAPSULATION은 내부 감추기
