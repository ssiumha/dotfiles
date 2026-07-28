---
name: PARSE-DONT-VALIDATE
full_name: Parse, Don't Validate
category: contract
origin: Yaron Minsky "Make illegal states unrepresentable" (2011) → Alexis King "Parse, don't validate" (2019)
one_liner: "검사 결과를 버리지 말고 타입에 남겨라 — 불법 상태를 표현조차 불가능하게"
---

# PARSE-DONT-VALIDATE — 검증하지 말고 파싱하라

## 정의

**validate는 정보를 버리고, parse는 정보를 타입에 보존한다.**

```
validate(input) -> void | boolean     검사 후 입력을 그대로 흘려보냄
                                       → 검사했다는 사실이 타입에 안 남음
                                       → 하류에서 또 검사하거나 "여긴 안전할 거야"로 가정

parse(input)    -> Refined | Error    검사에 성공하면 더 좁은 타입을 반환
                                       → 그 타입을 가진 값은 이미 검사된 값
                                       → 하류는 재검사할 이유가 없음
```

핵심은 **검사 시점과 사용 시점 사이에서 지식이 증발하지 않게** 하는 것이다. `validateNonEmpty(list)`를 통과한 뒤에도 `list[0]`이 안전한지는 타입이 모른다. 그래서 하류에서 옵셔널 체이닝, non-null 단언, 방어적 재검사가 번식한다. `parseNonEmpty(list): NonEmptyList`는 그 지식을 반환 타입에 담으므로 하류가 그냥 `head`를 쓸 수 있다.

> "Use a data structure that makes illegal states unrepresentable." — Yaron Minsky

## 자기설명 관점

이 원칙은 [[SELF-DOCUMENTING-CODE]]의 **타입 층위**다. 문서·주석에만 있던 제약을 타입으로 옮긴다:

| 문서/주석에 있던 것 | 타입으로 옮긴 형태 |
|---|---|
| "이 문자열은 이메일 형식이어야 함" | `Email` (생성자가 파싱 함수뿐) |
| "빈 배열을 넘기면 안 됨" | `NonEmptyList<T>` |
| "user_id와 order_id를 헷갈리지 말 것" | branded `UserId` / `OrderId` — 서로 대입 불가 |
| "status가 draft면 published_at은 null" | 판별 union (`{status:'draft'} \| {status:'published', publishedAt: Date}`) |
| "이 값은 검증 후에만 저장소로 보낼 것" | `RawInput` → `ValidatedInput` 단방향 변환 |

문서는 노후하지만 타입은 컴파일러가 매번 다시 확인한다.

## 핵심 판단

- **"이 검사를 통과했다는 사실이 타입에 남는가?"** — 안 남으면 validate, 남으면 parse
- **"같은 조건을 두 곳 이상에서 검사하는가?"** — 재검사 = 첫 검사가 정보를 버렸다는 증거
- **"이 타입으로 표현 가능한 값 중 실제로는 불법인 것이 있는가?"** — 있으면 타입이 너무 넓다
- **"파싱 경계가 어디인가?"** — 경계가 불명확하면 검증이 코드 전역에 흩어진다

## 위반 신호

### 기계적 검증 (자동화 가능)

| 신호 | 검증 방법 |
|------|-----------|
| non-null 단언·강제 캐스팅 빈도 | TS: `!\.`, `as ` / Kotlin: `!!` / Rust: `.unwrap()` / Python: `cast(` 카운트 |
| 도메인 식별자가 원시 타입 | `id: string`, `userId: str`, `Long id` 시그니처 카운트 |
| 같은 검증 함수가 여러 호출부에서 반복 | `validate\w+\|isValid\w+\|check\w+` 호출 지점 수 |
| `void`·`boolean` 반환 검증 함수 | 반환 타입이 값이 아닌 검증 함수 |
| 검증 후에도 옵셔널로 남는 필드 | 검증 통과 경로에서 `?.`·`if x is None` 재확인 |
| 스키마가 경계가 아닌 내부에서 호출됨 | zod/pydantic 호출 위치가 핸들러 밖에 분포 |

### 판단 필요 (사람/LLM)

| 신호 | 설명 |
|------|------|
| "여기까지 왔으면 null 아닐 거야" | 타입이 아니라 개발자 기억에 의존 |
| 불법 조합이 타입상 표현 가능 | boolean 플래그 2개로 3가지 상태를 표현 (4번째 조합이 불법) |
| 파싱 없이 원시 타입이 도메인 깊숙이 흐름 | 경계에서 정제하지 않음 |
| 인자 순서를 바꿔도 컴파일됨 | `transfer(fromId, toId)` 둘 다 `string` |
| 검증 실패를 예외로만 처리 | 실패 사례가 타입에 안 나타남 |

## 스코어링

| 등급 | 기준 |
|------|------|
| **PASS** | 외부 입력이 경계에서 1회 파싱되어 정제 타입이 됨, 도메인 식별자가 구분되는 타입, 불법 조합이 타입상 표현 불가, 하류에 재검증 없음 |
| **WARN** | 경계 파싱은 있으나 일부 원시 타입이 도메인으로 흐름, non-null 단언 소수 |
| **FAIL** | 검증이 코드 전역에 흩어짐 OR 도메인 식별자가 전부 원시 타입 OR 재검증·강제 캐스팅 다수 OR 불법 조합이 흔히 표현 가능 |

## 파싱 경계 — 어디서 한 번 하는가

```
외부 세계                경계 (파싱 1회)              도메인 코어
─────────                ──────────────              ──────────
HTTP body                                            SignUpCommand
CLI argv        ──────►  parse / decode     ──────►  Email
env var                  실패 시 즉시 거부            NonEmptyList<Item>
DB row                   (Fail Fast)                  UserId
큐 메시지                                             (원시 타입 없음)
```

- 경계는 **입구 한 곳** — 핸들러·컨트롤러·CLI 파서·리포지토리 매퍼
- 코어는 정제 타입만 다루므로 검증 코드가 없다
- 경계 밖으로 나갈 때(응답·저장)만 다시 원시 형태로 직렬화

이 형태가 [[FAIL-FAST]]의 구조적 실현이다 — 잘못된 입력이 도메인에 진입하지 못한다.

## 언어별 수단

| 언어 | 정제 타입 | 판별 union | 스키마 파싱 |
|------|-----------|-----------|-------------|
| TypeScript | branded type (`string & {__brand:'Email'}`) | discriminated union + `never` 소진 검사 | zod, ArkType, valibot |
| Python | `NewType`, frozen dataclass | `Literal` + `match` | pydantic, attrs + validators |
| Kotlin/Java | value class / record + private 생성자 | sealed interface | 생성자에서 파싱 |
| Rust | newtype + private 필드 | enum | serde + `TryFrom` |
| Go | 별도 named type + 생성자 함수 | 인터페이스 + 타입 스위치 | 생성자에서 검증 후 반환 |

**공통 조건**: 정제 타입의 생성 경로가 파싱 함수 **하나뿐**이어야 한다. 생성자가 공개되어 있으면 우회가 가능해 보장이 무너진다 ([[ENCAPSULATION]]).

## 개선 패턴

| 상황 | 적용 |
|------|------|
| `validateX(input): void` 후 그대로 사용 | **반환 타입을 좁힌다** — `parseX(input): X` |
| 도메인 식별자가 전부 `string` | **branded/newtype 도입** — 인자 순서 실수를 컴파일 에러로 |
| boolean 플래그 조합으로 상태 표현 | **판별 union / sealed 계층** — 불법 조합을 표현 불가로 |
| 검증이 서비스 곳곳에 흩어짐 | **경계로 이동** — 핸들러 진입점에서 1회 파싱 |
| 검증 통과 후에도 옵셔널 | **검증 전/후 타입 분리** — `RawUser` → `ValidatedUser` |
| 파싱 실패를 예외로만 표현 | **Result/Either 반환** — 실패가 타입에 나타나게 |
| 제약이 주석에만 존재 | 주석을 지우고 **타입 또는 파싱 함수로 이동** ([[COMMENT-WHY]]) |

## 다른 원칙과의 관계

| 원칙 | 관계 |
|------|------|
| [[DbC]] | DbC는 **런타임** 계약(precondition assert), 이 원칙은 **타입 층위** 계약. 타입으로 표현되면 precondition 자체가 불필요해진다 — 상보 관계 |
| [[SELF-DOCUMENTING-CODE]] | 이 원칙은 그 타입 층위. 문서에만 있던 제약을 타입으로 옮기는 구체적 수단 |
| [[FAIL-FAST]] | 경계에서 파싱 실패 시 즉시 거부 — Fail Fast의 구조적 실현 |
| [[POLA]] | 타입이 좁으면 함수가 무엇을 받는지 놀라움이 없다 |
| [[ENCAPSULATION]] | 정제 타입은 생성 경로를 파싱 함수로 좁혀야 보장이 성립 |
| [[LSP]] | 정제 타입 계층에서 하위 타입이 제약을 약화하면 보장이 깨진다 |
| [[EXECUTABLE-DOCUMENTATION]] | 타입은 컴파일러가 검사하는 문서 — 실행되는 문서의 가장 이른 층위 |
| [[INTENTION-REVEALING-NAMES]] | `Email`·`UserId` 같은 정제 타입 이름이 곧 도메인 어휘 ([[UL]]) |

## 잘못된 통념 교정

| 통념 | 실제 |
|------|------|
| "런타임 검증이 있으면 타입은 넓어도 된다" | 검증 결과가 타입에 안 남으면 하류가 그 사실을 모른다 — 재검증·단언이 번식 |
| "타입을 좁히면 유연성이 준다" | 줄어드는 것은 **불법 상태**의 표현력이다. 합법 상태는 그대로 |
| "동적 언어에서는 불가능" | Python `NewType`·pydantic, Ruby 값 객체 등으로 같은 구조를 만들 수 있다 |
| "branded type은 보일러플레이트" | 파서 1개 + 타입 1줄. 대신 하류 전체에서 검사가 사라진다 |

## 주의

- **모든 원시 타입을 감싸라는 뜻이 아니다.** 혼동 위험이 있거나(식별자) 제약이 있는(이메일, 금액) 값에 적용한다. 반복 횟수 같은 값까지 감싸면 노이즈 ([[YAGNI]])
- 정제 타입이 늘면 경계에서의 변환 코드도 는다. 경계가 얇게 유지되는지 확인
- 외부 스키마(DB, API)가 넓은 타입을 강제하는 경우가 있다 — 그 경계에서 파싱하고, 코어는 정제 타입만 쓰면 된다
- 파싱 실패 메시지가 빈약하면 디버깅이 어려워진다. 실패에 어떤 필드가 왜 실패했는지 담을 것
