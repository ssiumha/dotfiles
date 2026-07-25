---
name: SELF-DOCUMENTING-CODE
full_name: Self-Documenting Code
category: design
origin: Ward Cunningham·Kent Beck "코드가 곧 설계" → Martin Fowler "Code as Documentation" → Robert C. Martin "Clean Code" (2008)
one_liner: "문서화보다 문서처럼 읽히는 코드가 우선 — 이름·구조·타입이 의도를 말하게"
---

# SELF-DOCUMENTING-CODE — 문서처럼 읽히는 소스코드

## 정의

**문서화보다 더 중요한 것은 문서처럼 읽히는 소스코드다.** 코드 자체(이름·구조·타입·테스트)가 1차 문서이고, 별도 문서·주석은 코드가 **답할 수 없는 것**(WHY, 아키텍처 개요, 외부 제약, 의사결정 배경)만 담는다.

이유는 단순하다 — **외부 문서와 주석은 노후(drift)하지만 코드는 실행되므로 늘 진실이다.** 코드와 문서가 어긋나면 사람은 코드를 믿는다. 그렇다면 진실인 코드가 스스로 읽히게 만드는 것이 문서를 늘리는 것보다 낫다.

## 핵심 판단

- **"이 주석/문서를 이름·구조 개선으로 없앨 수 있는가?"** — 있으면 그 주석은 코드 냄새의 신호다
- **"코드만 읽고 의도(WHY)를 알 수 있는가?"** — 이름이 *무엇을 하는지*를 넘어 *왜 존재하는지*를 드러내는가
- **"이름이 책임을 드러내는가?"** — `UserService`(무한 확장되는 잡동사니)보다 `UserSignUpService`(하는 일이 이름에 박혀 있음). 구체적 이름은 곧 단일 책임의 강제다

## SOLID·다른 원칙과의 연결

구체적 이름은 설계 원칙을 **자연히 강제**한다:

- **SRP** — `UserSignUpService`는 이름이 "가입"으로 좁혀져 있어 결제·조회 로직을 넣으면 이름이 거짓말이 된다. 반면 `UserService`는 무엇이든 받아들여 God class로 자란다. **이름이 책임의 울타리** 역할을 한다
- **ISP** — 역할이 이름에 드러나면 인터페이스가 클라이언트별로 갈라진다 (`SignUpNotifier` vs `PasswordResetNotifier`)
- **UL** — 이름이 도메인 용어와 일치하면 코드가 곧 도메인 문서가 된다

## 위반 신호

### 기계적 검증 (자동화 가능)

| 신호 | 검증 방법 |
|------|-----------|
| WHAT/HOW를 설명하는 주석 | grep 주석 중 `// 이 함수는 ~한다` 류 서술 |
| 단계 구분 주석 (`// 1단계`, `// --- 검증 ---`) | Extract Method 후보 |
| 무의미 접미사 이름 (Service·Manager·Helper·Util·Data·Processor) | grep 접미사 빈도 |
| 죽은 코드 주석 (주석 처리된 코드 블록) | grep 연속 주석 코드 |
| README/문서와 실제 시그니처 불일치 | 문서의 함수명·인자 vs 코드 대조 |

### 판단 필요 (사람/LLM)

| 신호 | 설명 |
|------|------|
| 주석이 없으면 의도를 알 수 없는 코드 | 이름·구조가 의도를 못 담음 |
| 문서에만 존재하는 계약 | "이 값은 null이면 안 됨"이 주석에만, 타입·검증에 없음 |
| 제네릭한 이름의 거대 클래스 | `Manager`·`Service`가 다중 책임 흡수 |
| 매직 넘버·문자열 | 이름 없는 상수가 의미를 숨김 |

## 스코어링

| 등급 | 기준 |
|------|------|
| **PASS** | 이름이 의도·책임을 드러냄, WHAT/HOW 주석 없음, 계약이 타입·검증으로 표현됨 |
| **WARN** | 일부 제네릭 이름/설명 주석이 있으나 핵심 도메인은 코드만으로 읽힘 |
| **FAIL** | 의도를 주석에 의존, `Manager`/`Service` God class, 문서·코드 불일치, 매직 넘버 다수 |

## 개선 패턴

| 상황 | 적용 |
|------|------|
| WHAT/HOW 설명 주석 | **Extract Method** — 주석 문장을 이름 있는 함수로 (`// 유효성 검사` → `validateSignUpRequest()`) |
| 제네릭 이름 클래스 | **Rename + Extract Class** — `UserService` → `UserSignUpService`·`UserProfileQueryService` |
| 문서에만 있는 제약 | **타입·검증으로 이동** — `NonEmptyString`, precondition 검사(DbC) |
| 매직 넘버 | **Extract Constant** — 의도가 담긴 이름 |
| 사용법이 문서에만 | **테스트로 문서화** — 실행되는 예제(SELF-TESTING-CODE) |
| 주석이 WHY를 담음 | 유지 — 이것만이 정당한 주석(COMMENT-WHY) |

## 다른 원칙과의 관계

| 원칙 | 관계 |
|------|------|
| [[INTENTION-REVEALING-NAMES]] | 이 원칙의 어휘 층위 — 이름이 의도를 드러내는 것이 자기설명의 출발 |
| [[COMMENT-WHY]] | 이 원칙의 주석 정책 — WHAT/HOW는 코드로, 주석은 WHY만 |
| [[UL]] | 도메인 용어와 일치하는 이름 → 코드가 곧 도메인 문서 |
| [[SRP]] | 구체적 이름이 책임을 좁혀 SRP를 강제 |
| [[SELF-TESTING-CODE]] | 테스트가 실행되는 사용 예제 = 노후하지 않는 문서 |
| [[POLA]] | 이름대로 동작하면 코드를 읽는 놀라움이 사라진다 |

## 주의

- **문서를 쓰지 말라는 뜻이 아니다.** 코드로 표현할 수 없는 것 — 아키텍처 개요, 의사결정 기록(ADR), 외부 계약·규제, 온보딩 맥락 — 은 여전히 문서가 담는다. 이 원칙은 "**코드로 표현 가능한 것을 문서로 미루지 마라**"이다
- 지나친 이름 길이는 오히려 의도를 흐린다 — `theServiceThatHandlesUserSignUpAndSendsEmail`보다 `UserSignUpService`
- 자기설명적 코드는 **리팩터링을 두려워하지 않는 팀**에서만 유지된다. 이름이 낡으면 즉시 rename (BOY-SCOUT)
- 팀 공유면 원칙과 상충하지 않게 — 코드·주석은 저장소만 보고 읽히는 내용만 담는다
