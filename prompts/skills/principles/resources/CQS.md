---
name: CQS
full_name: Command-Query Separation
category: contract
origin: Bertrand Meyer, "Object-Oriented Software Construction" (1988)
one_liner: "메서드는 상태를 바꾸거나(command) 값을 반환하거나(query), 둘 중 하나만"
---

# CQS — Command-Query Separation

## 정의

> "Asking a question should not change the answer."

모든 메서드는 두 종류 중 하나여야 한다:
- **Command** — 상태를 변경한다. 값을 반환하지 않는다 (void)
- **Query** — 값을 반환한다. 상태를 변경하지 않는다 (부수효과 없음)

하나의 메서드가 둘 다 하면 호출자가 부수효과를 예측할 수 없다.

## 핵심 판단

- **"이 메서드를 두 번 호출하면 결과가 달라지는가?"** — Query라면 달라지면 안 된다
- **"이 메서드가 값을 반환하면서 상태도 바꾸는가?"** — 그렇다면 CQS 위반
- **"이 getter를 호출했더니 뭔가 바뀌었는가?"** — 바뀌면 위반

## 위반 신호

### 기계적 검증 (자동화 가능)

| 신호 | 검증 방법 |
|------|-----------|
| `get*` / `find*` / `is*` 메서드가 상태 변경 | getter 내부에서 `this.` 할당, DB write 확인 |
| 반환값 있는 메서드가 `save` / `delete` / `update` 수행 | 반환 + 부수효과 동시 존재 |
| `pop()`, `next()` 패턴 (읽기 + 제거 동시) | 컬렉션 메서드에서 조회+변경 결합 |

### 판단 필요 (사람/LLM)

| 신호 | 설명 |
|------|------|
| "이 메서드 호출 순서를 바꾸면 결과가 달라짐" | 숨겨진 command 존재 |
| 테스트에서 assertion이 실행 순서에 의존 | query가 순수하지 않음 |
| 캐시 초기화가 getter 안에 숨어 있음 | 조회가 상태를 바꿈 |
| API 호출이 "조회"인데 서버 상태가 바뀜 | GET 요청에 부수효과 |

## 스코어링

| 등급 | 기준 |
|------|------|
| **PASS** | getter/query에 부수효과 없음, command는 void 또는 성공/실패만 반환 |
| **WARN** | 일부 메서드에서 조회+변경 결합하나 의도적 (Builder 패턴 등) |
| **FAIL** | getter가 상태 변경 OR 조회 메서드가 DB write OR 호출 순서 의존성 다수 |

## Command vs Query 구분

```
// Command (상태 변경, 반환 없음)
user.setName("Alice")        // void
cart.addItem(product)         // void
order.cancel()                // void

// Query (값 반환, 부수효과 없음)
user.getName()                // "Alice"
cart.getTotal()               // 15000
order.isCancelled()           // true

// ❌ 위반: 조회 + 변경 동시
stack.pop()                   // 값 반환 + 상태 변경
user.getOrCreate(email)       // 조회 + 생성 가능
iterator.next()               // 값 반환 + 커서 이동
```

## 개선 패턴

| 상황 | 적용 |
|------|------|
| `getOrCreate` 패턴 | **분리** — `find()` (query) + `create()` (command) |
| `pop()` 패턴 | **분리** — `peek()` (query) + `remove()` (command) |
| 반환값 있는 command | **void + 별도 query** 또는 **Result 객체 반환** (상태 변경 결과만) |
| getter 안에서 캐시 갱신 | **Lazy init은 허용** — 관찰 가능한 상태는 변하지 않으므로 CQS 위반 아님 |

## CQS vs CQRS

| | CQS | CQRS |
|--|-----|------|
| 범위 | 메서드 레벨 | 아키텍처 레벨 |
| 핵심 | 하나의 메서드가 command 또는 query | 읽기 모델과 쓰기 모델을 분리 |
| 적용 | 모든 코드 | 복잡한 도메인, 이벤트 소싱 |

## 주의

- Lazy initialization은 CQS 위반이 아니다. 외부에서 관찰 가능한 상태가 변하지 않으므로
- Builder 패턴 (`builder.setX().setY().build()`)은 fluent API를 위한 의도적 예외
- 동시성 환경에서는 "check-then-act"가 필요해 CQS를 지키기 어려운 경우가 있다 (e.g., `compareAndSwap`)
- HTTP에서 GET은 query, POST/PUT/DELETE는 command — REST가 CQS를 프로토콜에 적용한 것
